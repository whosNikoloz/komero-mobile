import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../l10n_ext.dart';
import '../models/product.dart';

/// One line of an editor: what the field is, what it currently holds, and a
/// chevron into the screen that changes it.
///
/// A long value belongs on its own screen, not in a box three lines tall
/// wedged into a form — the row says what is there, and the editor gets the
/// whole display to work in.
class EditorRow extends StatelessWidget {
  const EditorRow({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.icon,
  });

  /// What the field is called. Shown small above a filled value, and as the
  /// whole row when there is nothing in it yet.
  final String label;

  /// The current contents, or null when the field is empty.
  final String? value;

  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final filled = value != null && value!.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              // An empty field offers to be filled; a filled one just names
              // itself.
              icon ?? (filled ? Icons.edit_outlined : Icons.add_circle_outline),
              size: 20,
              color: filled ? c.textMuted : c.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: filled
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: c.text,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      label,
                      style: TextStyle(fontSize: 15, color: c.textMuted),
                    ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: c.textDisabled),
          ],
        ),
      ),
    );
  }
}

/// Opens a full screen for one piece of text and returns what was typed, or
/// null if it was dismissed. The whole display, so a description can be
/// written and read without scrolling a five-line box.
///
/// [formatting] adds the bold / italic / list bar above the keyboard, for the
/// fields the storefront renders as markup. It writes the marks
/// `core/rich_text.dart` converts, so the operator formats by selecting text
/// and tapping a button and never sees a tag.
Future<String?> editText(
  BuildContext context, {
  required String title,
  String? subtitle,
  String initial = '',
  bool multiline = true,
  bool formatting = false,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _TextEditorScreen(
        title: title,
        subtitle: subtitle,
        initial: initial,
        multiline: multiline,
        formatting: formatting,
      ),
    ),
  );
}

class _TextEditorScreen extends StatefulWidget {
  const _TextEditorScreen({
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.multiline,
    required this.formatting,
  });

  final String title;
  final String? subtitle;
  final String initial;
  final bool multiline;
  final bool formatting;

  @override
  State<_TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<_TextEditorScreen> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Wraps the selection in [mark], or opens an empty pair with the caret
  /// inside it when nothing is selected — the two things a bold button has to
  /// do. Tapping it again on text that already carries the mark takes it off,
  /// so the button is a toggle rather than a way to stack marks.
  void _wrap(String mark) {
    final text = _controller.text;
    final sel = _controller.selection;

    if (!sel.isValid) return;

    final start = sel.start;
    final end = sel.end;
    final selected = text.substring(start, end);
    final before = text.substring(0, start);
    final after = text.substring(end);

    // Marks just outside the selection: what you get by selecting the word
    // inside **bold** and tapping bold again.
    if (before.endsWith(mark) && after.startsWith(mark)) {
      _replace(
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

      _replace(text: before + inner + after, start: start, end: start + inner.length);

      return;
    }

    _replace(
      text: '$before$mark$selected$mark$after',
      start: start + mark.length,
      end: start + mark.length + selected.length,
    );
  }

  /// Puts "- " in front of every line the selection touches, or takes it off
  /// every line when they all already have it.
  void _bullets() {
    final text = _controller.text;
    final sel = _controller.selection;

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

    _replace(
      text: text.replaceRange(lineStart, lineEnd, next),
      start: lineStart,
      end: lineStart + next.length,
    );
  }

  void _replace({required String text, required int start, required int end}) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: start, extentOffset: end),
    );
  }

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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
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
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: Text(l.done),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: widget.multiline ? null : 1,
                  expands: widget.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: widget.multiline
                      ? TextInputType.multiline
                      : TextInputType.text,
                  style: TextStyle(fontSize: 15, height: 1.45, color: c.text),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            // The bar sits at the bottom of the body, which puts it directly
            // above the keyboard — in reach of the thumb that is typing,
            // rather than up by the title.
            if (widget.formatting)
              _FormatBar(
                onBold: () => _wrap('**'),
                onItalic: () => _wrap('_'),
                onBullets: _bullets,
              ),
          ],
        ),
      ),
    );
  }
}

/// Bold, italic and list, for the fields the storefront renders as markup.
///
/// Three buttons and no more. A phone description is a paragraph, a couple of
/// emphasised words and a list of specs — headings, colours and alignment were
/// never going to be used from a phone, and each one is another tag to carry
/// and another round trip to get wrong.
class _FormatBar extends StatelessWidget {
  const _FormatBar({
    required this.onBold,
    required this.onItalic,
    required this.onBullets,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onBullets;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _FormatButton(icon: Icons.format_bold, label: l.formatBold, onTap: onBold),
          _FormatButton(
            icon: Icons.format_italic,
            label: l.formatItalic,
            onTap: onItalic,
          ),
          _FormatButton(
            icon: Icons.format_list_bulleted,
            label: l.formatBulletList,
            onTap: onBullets,
          ),
        ],
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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

/// One choice out of a list, on its own screen with a search box — a catalog
/// of a few hundred categories is not something to hunt through in a dropdown
/// that opens over the keyboard.
///
/// Returns the chosen value, `null` if dismissed, and [PickerResult.none] when
/// the operator deliberately clears the field.
Future<PickerResult<T>?> pickOne<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) labelOf,
  T? selected,
  bool allowNone = true,
  String? Function(T)? idOf,
  String? Function(T)? parentOf,
}) {
  return Navigator.of(context).push<PickerResult<T>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PickerScreen<T>(
        title: title,
        items: items,
        labelOf: labelOf,
        selected: selected,
        allowNone: allowNone,
        idOf: idOf,
        parentOf: parentOf,
      ),
    ),
  );
}

/// Wraps the choice so that "cleared the field" and "backed out" stay
/// different answers — both of which a bare `T?` would flatten into null.
@immutable
class PickerResult<T> {
  const PickerResult(this.value);

  static const none = PickerResult<Never>._none();

  const PickerResult._none() : value = null;

  final T? value;
}

class _PickerScreen<T> extends StatefulWidget {
  const _PickerScreen({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.selected,
    required this.allowNone,
    this.idOf,
    this.parentOf,
  });

  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final T? selected;
  final bool allowNone;

  /// Supply both to get a tree: children are listed under their parent and
  /// indented. Without them the list stays flat.
  final String? Function(T)? idOf;
  final String? Function(T)? parentOf;

  @override
  State<_PickerScreen<T>> createState() => _PickerScreenState<T>();
}

class _PickerScreenState<T> extends State<_PickerScreen<T>> {
  String _query = '';

  List<({T item, int depth})> _ordered() {
    final idOf = widget.idOf;
    final parentOf = widget.parentOf;

    if (idOf == null || parentOf == null) {
      return [for (final item in widget.items) (item: item, depth: 0)];
    }

    return orderAsTree(widget.items, idOf: idOf, parentOf: parentOf);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final query = _query.trim().toLowerCase();
    // Searching flattens the tree, otherwise a match whose parent does not
    // match would be unreachable.
    final matches = query.isEmpty
        ? _ordered()
        : [
            for (final item in widget.items)
              if (widget.labelOf(item).toLowerCase().contains(query))
                (item: item, depth: 0),
          ];

    return Scaffold(
      backgroundColor: c.card,
      appBar: AppBar(
        backgroundColor: c.card,
        shape: const Border(),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.text,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (widget.allowNone && query.isEmpty)
                  _Choice(
                    label: l.noneSelected,
                    isSelected: widget.selected == null,
                    muted: true,
                    onTap: () =>
                        Navigator.of(context).pop(const PickerResult<Never>._none()),
                  ),
                for (final row in matches)
                  _Choice(
                    label: widget.labelOf(row.item),
                    depth: row.depth,
                    isSelected: row.item == widget.selected,
                    onTap: () =>
                        Navigator.of(context).pop(PickerResult<T>(row.item)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.muted = false,
    this.depth = 0,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool muted;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 + depth * 18, 14, 16, 14),
        child: Row(
          children: [
            if (depth > 0) ...[
              Icon(Icons.subdirectory_arrow_right, size: 14, color: c.textMuted),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: muted ? c.textMuted : c.text,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, size: 20, color: c.primary),
          ],
        ),
      ),
    );
  }
}
