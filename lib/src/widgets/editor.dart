import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../l10n_ext.dart';

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
Future<String?> editText(
  BuildContext context, {
  required String title,
  String? subtitle,
  String initial = '',
  bool multiline = true,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _TextEditorScreen(
        title: title,
        subtitle: subtitle,
        initial: initial,
        multiline: multiline,
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
  });

  final String title;
  final String? subtitle;
  final String initial;
  final bool multiline;

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: widget.multiline ? null : 1,
            expands: widget.multiline,
            textAlignVertical: TextAlignVertical.top,
            keyboardType:
                widget.multiline ? TextInputType.multiline : TextInputType.text,
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
  });

  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final T? selected;
  final bool allowNone;

  @override
  State<_PickerScreen<T>> createState() => _PickerScreenState<T>();
}

class _PickerScreenState<T> extends State<_PickerScreen<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? widget.items
        : [
            for (final item in widget.items)
              if (widget.labelOf(item).toLowerCase().contains(query)) item,
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
                for (final item in matches)
                  _Choice(
                    label: widget.labelOf(item),
                    isSelected: item == widget.selected,
                    onTap: () =>
                        Navigator.of(context).pop(PickerResult<T>(item)),
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
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
