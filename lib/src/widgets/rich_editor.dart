import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/net/api_client.dart';
import '../core/rich_text.dart';
import '../core/theme/tokens.dart';
import '../data/repositories.dart';
import '../l10n_ext.dart';
import 'common.dart';
import 'sheet.dart';

/// Opens the description editor on [initialHtml] and returns the HTML the
/// operator left behind, or null if they backed out.
///
/// The same markup the web admin's editor reads and writes, so a description
/// can be started on a laptop and finished on a phone: text with bold, italic
/// and bulleted lists, pictures, and embedded video.
Future<String?> editRichText(
  BuildContext context, {
  required String title,
  String? subtitle,
  String initialHtml = '',
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _RichEditorScreen(
        title: title,
        subtitle: subtitle,
        initialHtml: initialHtml,
      ),
    ),
  );
}

/// A text field that paints its own marks: `**bold**` really is bold while it
/// is being typed, and the asterisks sit behind it in the muted colour.
///
/// This is the whole trick that lets a plain [TextField] stand in for a
/// rich-text editor. The marks stay in the text — they are what gets saved as
/// `<strong>` — but nobody has to read them as punctuation.
class MarkupEditingController extends TextEditingController {
  MarkupEditingController({super.text});

  /// The colour the marks themselves are drawn in. Set from the build method,
  /// because a controller is created before there is a theme to ask.
  Color? markColor;

  static final _marks = RegExp(
    '${boldMark.pattern}|${italicMark.pattern}',
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final faded = base.copyWith(color: markColor ?? base.color);
    final spans = <TextSpan>[];
    var cursor = 0;

    for (final m in _marks.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start), style: base));
      }

      final bold = m[1] != null;
      final mark = bold ? '**' : '_';
      final inner = m[1] ?? m[2]!;

      spans.add(TextSpan(text: mark, style: faded));
      spans.add(
        TextSpan(
          text: inner,
          style: bold
              ? base.copyWith(fontWeight: FontWeight.w700)
              : base.copyWith(fontStyle: FontStyle.italic),
        ),
      );
      spans.add(TextSpan(text: mark, style: faded));

      cursor = m.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }

    return TextSpan(style: base, children: spans);
  }
}

/// One row of the editor: a paragraph being typed, or a piece of media sitting
/// between paragraphs.
class _Row {
  _Row.text(String text)
      : controller = MarkupEditingController(text: text),
        focus = FocusNode(),
        media = null;

  _Row.media(DescriptionBlock this.media)
      : controller = null,
        focus = null;

  final MarkupEditingController? controller;
  final FocusNode? focus;
  final DescriptionBlock? media;

  bool get isText => media == null;

  void dispose() {
    controller?.dispose();
    focus?.dispose();
  }
}

class _RichEditorScreen extends ConsumerStatefulWidget {
  const _RichEditorScreen({
    required this.title,
    required this.subtitle,
    required this.initialHtml,
  });

  final String title;
  final String? subtitle;
  final String initialHtml;

  @override
  ConsumerState<_RichEditorScreen> createState() => _RichEditorScreenState();
}

class _RichEditorScreenState extends ConsumerState<_RichEditorScreen> {
  late final List<_Row> _rows;

  /// The paragraph the toolbar acts on, and where new media lands. Tracked by
  /// focus, so it is always the one the operator was last typing in.
  int _active = 0;

  bool _uploading = false;

  @override
  void initState() {
    super.initState();

    final blocks = htmlToBlocks(widget.initialHtml);

    _rows = [
      for (final block in blocks)
        if (block case TextBlock(:final text)) _Row.text(text) else _Row.media(block),
    ];

    // Always something to type in, and always a paragraph after the last
    // picture — otherwise a description that ends in media has no way to grow.
    if (_rows.isEmpty || !_rows.last.isText) _rows.add(_Row.text(''));

    for (final (i, row) in _rows.indexed) {
      row.focus?.addListener(() {
        if (row.focus!.hasFocus) _active = i;
      });
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }

    super.dispose();
  }

  // ── text marks ────────────────────────────────────────────────

  MarkupEditingController? get _activeController =>
      _active < _rows.length ? _rows[_active].controller : null;

  /// Wraps the selection in [mark], or opens an empty pair with the caret
  /// inside it when nothing is selected. Tapping it again on text that already
  /// carries the mark takes it off, so the button is a toggle rather than a way
  /// to stack marks.
  void _wrap(String mark) {
    final controller = _activeController;

    if (controller == null) return;

    final text = controller.text;
    final sel = controller.selection;

    if (!sel.isValid) return;

    final start = sel.start;
    final end = sel.end;
    final selected = text.substring(start, end);
    final before = text.substring(0, start);
    final after = text.substring(end);

    // Marks just outside the selection: what you get by selecting the word
    // inside **bold** and tapping bold again.
    if (before.endsWith(mark) && after.startsWith(mark)) {
      _set(
        controller,
        text: before.substring(0, before.length - mark.length) +
            selected +
            after.substring(mark.length),
        start: start - mark.length,
        end: end - mark.length,
      );

      return;
    }

    // Marks inside the selection: what you get by selecting **bold** whole.
    if (selected.length > 2 * mark.length &&
        selected.startsWith(mark) &&
        selected.endsWith(mark)) {
      final inner = selected.substring(mark.length, selected.length - mark.length);

      _set(controller, text: before + inner + after, start: start, end: start + inner.length);

      return;
    }

    _set(
      controller,
      text: '$before$mark$selected$mark$after',
      start: start + mark.length,
      end: start + mark.length + selected.length,
    );
  }

  /// Puts "- " in front of every line the selection touches, or takes it off
  /// every line when they all already have it.
  void _bullets() {
    final controller = _activeController;

    if (controller == null) return;

    final text = controller.text;
    final sel = controller.selection;

    if (!sel.isValid) return;

    // Grow the range to whole lines: a bullet belongs to a line, not to the
    // three characters the operator happened to have selected.
    final lineStart = text.lastIndexOf('\n', sel.start == 0 ? 0 : sel.start - 1) + 1;
    final nextBreak = text.indexOf('\n', sel.end);
    final lineEnd = nextBreak == -1 ? text.length : nextBreak;

    final lines = text.substring(lineStart, lineEnd).split('\n');
    final marked = lines.every((line) => line.trimLeft().startsWith('- '));

    final next = lines
        .map(
          (line) => marked
              ? line.replaceFirst(RegExp(r'^\s*-\s'), '')
              : (line.trim().isEmpty ? line : '- $line'),
        )
        .join('\n');

    _set(
      controller,
      text: text.replaceRange(lineStart, lineEnd, next),
      start: lineStart,
      end: lineStart + next.length,
    );
  }

  void _set(
    TextEditingController controller, {
    required String text,
    required int start,
    required int end,
  }) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: start, extentOffset: end),
    );
  }

  // ── media ─────────────────────────────────────────────────────

  /// Media goes in after the paragraph that has focus, with a fresh paragraph
  /// behind it — the operator's next thought has somewhere to go.
  void _insertMedia(DescriptionBlock block) {
    final at = (_active + 1).clamp(0, _rows.length);
    final paragraph = _Row.text('');
    final paragraphIndex = at + 1;

    paragraph.focus!.addListener(() {
      if (paragraph.focus!.hasFocus) {
        _active = _rows.indexOf(paragraph);
      }
    });

    setState(() {
      _rows.insertAll(at, [_Row.media(block), paragraph]);
      _active = paragraphIndex;
    });
  }

  Future<void> _addPhoto() async {
    final l = context.l;

    final fromCamera = await showKomeroSheet<bool>(
      context,
      title: l.addPhoto,
      builder: (sheetContext) => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.takePhoto),
            onTap: () => Navigator.of(sheetContext).pop(true),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.chooseFromLibrary),
            onTap: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );

    if (fromCamera == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      // A description image is shown at content width; a phone camera's full
      // frame is several megabytes of detail nobody will see.
      maxWidth: 2000,
      imageQuality: 85,
    );

    if (picked == null || !mounted) return;

    setState(() => _uploading = true);

    try {
      final url = await ref.read(mediaRepositoryProvider).upload(
            await MultipartFile.fromFile(picked.path, filename: picked.name),
            folder: 'descriptions',
          );

      if (!mounted) return;

      _insertMedia(ImageBlock(url));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : context.l.somethingWentWrong,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addVideo() async {
    final l = context.l;
    final link = await _askForLink(context);

    if (link == null || !mounted) return;

    final embed = youtubeEmbedUrl(link);
    final uri = Uri.tryParse(link.trim());

    // Anything that is not YouTube is taken as a player URL as given — plenty
    // of hosts hand out an embed link — but it still has to be a URL.
    if (embed == null && (uri == null || !uri.isScheme('https'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invalidVideoLink)),
      );

      return;
    }

    _insertMedia(VideoBlock(embed ?? link.trim()));
  }

  Future<String?> _askForLink(BuildContext context) {
    final l = context.l;
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.addVideo),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l.videoLink,
            hintText: l.videoLinkHint,
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l.done),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _removeAt(int index) {
    setState(() {
      _rows.removeAt(index).dispose();

      if (_rows.isEmpty || !_rows.last.isText) _rows.add(_Row.text(''));

      _active = _active.clamp(0, _rows.length - 1);
    });
  }

  void _move(int index, int by) {
    final to = index + by;

    if (to < 0 || to >= _rows.length) return;

    setState(() {
      final row = _rows.removeAt(index);

      _rows.insert(to, row);
      _active = _rows.indexWhere((r) => r.isText);
    });
  }

  // ── result ────────────────────────────────────────────────────

  String _html() => blocksToHtml([
        for (final row in _rows)
          if (row.media case final media?)
            media
          else if (row.controller!.text.trim().isNotEmpty)
            TextBlock(row.controller!.text.trim()),
      ]);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return Scaffold(
      backgroundColor: c.card,
      appBar: AppBar(
        backgroundColor: c.card,
        shape: const Border(),
        centerTitle: true,
        leading: IconButton(
          // Close, not back: this is a sheet over the product, and leaving it
          // discards rather than navigates.
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text),
            ),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_html()),
            child: Text(l.done),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_uploading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _rows.length,
                itemBuilder: (context, i) {
                  final row = _rows[i];

                  if (row.media case final media?) {
                    return _MediaRow(
                      block: media,
                      onRemove: () => _removeAt(i),
                      onUp: i == 0 ? null : () => _move(i, -1),
                      onDown: i == _rows.length - 1 ? null : () => _move(i, 1),
                    );
                  }

                  row.controller!.markColor = c.textDisabled;

                  return TextField(
                    controller: row.controller,
                    focusNode: row.focus,
                    // The first paragraph of a new description is where the
                    // cursor belongs; anywhere else the operator chose to tap.
                    autofocus: i == 0 && _rows.length == 1,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(fontSize: 15, height: 1.45, color: c.text),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      hintText: i == 0 ? widget.title : null,
                      hintStyle: TextStyle(fontSize: 15, color: c.textDisabled),
                    ),
                  );
                },
              ),
            ),
            // The bar sits at the bottom of the body, which puts it directly
            // above the keyboard — in reach of the thumb that is typing,
            // rather than up by the title.
            _FormatBar(
              onBold: () => _wrap('**'),
              onItalic: () => _wrap('_'),
              onBullets: _bullets,
              onPhoto: _uploading ? null : _addPhoto,
              onVideo: _uploading ? null : _addVideo,
            ),
          ],
        ),
      ),
    );
  }
}

/// A picture or a video in the flow of the text, with the three things that
/// can be done to it. Not resizable and not alignable: those are decisions for
/// a mouse and a wide screen, and the storefront lays description media out at
/// content width anyway.
class _MediaRow extends StatelessWidget {
  const _MediaRow({
    required this.block,
    required this.onRemove,
    required this.onUp,
    required this.onDown,
  });

  final DescriptionBlock block;
  final VoidCallback onRemove;
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: switch (block) {
              ImageBlock(:final url) => CachedNetworkImage(
                  imageUrl: absoluteImageUrl(url) ?? url,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _Placeholder(
                    icon: Icons.broken_image_outlined,
                    label: l.photos,
                  ),
                  placeholder: (_, _) => const _Placeholder(icon: Icons.image_outlined),
                ),
              // An embedded player is not worth a webview inside an editor:
              // the row says a video sits here and which one, and the
              // storefront plays it.
              VideoBlock(:final embedUrl) => _Placeholder(
                  icon: Icons.play_circle_outline,
                  label: embedUrl,
                ),
              TextBlock() => const SizedBox.shrink(),
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                onPressed: onUp,
                tooltip: l.moveUp,
                icon: const Icon(Icons.arrow_upward, size: 18),
                color: c.textMuted,
              ),
              IconButton(
                onPressed: onDown,
                tooltip: l.moveDown,
                icon: const Icon(Icons.arrow_downward, size: 18),
                color: c.textMuted,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRemove();
                },
                tooltip: l.delete,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: c.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, this.label});

  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      height: 150,
      color: c.surfaceHover,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: c.textMuted),
          if (label != null) ...[
            const SizedBox(height: 8),
            Text(
              label!,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// What a description is actually made of: emphasis, a list, a picture, a
/// video. No headings, colours or alignment — those are decisions for a wide
/// screen, and each one is another tag to carry and another round trip to get
/// wrong.
class _FormatBar extends StatelessWidget {
  const _FormatBar({
    required this.onBold,
    required this.onItalic,
    required this.onBullets,
    required this.onPhoto,
    required this.onVideo,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onBullets;
  final VoidCallback? onPhoto;
  final VoidCallback? onVideo;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _FormatButton(icon: Icons.format_bold, label: l.formatBold, onTap: onBold),
          _FormatButton(icon: Icons.format_italic, label: l.formatItalic, onTap: onItalic),
          _FormatButton(
            icon: Icons.format_list_bulleted,
            label: l.formatBulletList,
            onTap: onBullets,
          ),
          const Spacer(),
          _FormatButton(icon: Icons.image_outlined, label: l.addPhoto, onTap: onPhoto),
          _FormatButton(
            icon: Icons.videocam_outlined,
            label: l.addVideo,
            onTap: onVideo,
          ),
        ],
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      color: context.c.textSecondary,
      tooltip: label,
    );
  }
}
