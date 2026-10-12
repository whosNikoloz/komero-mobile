import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../l10n_ext.dart';

/// Mobile-first modal. Everything that would be a centre dialog on desktop is
/// a bottom sheet here, because on a phone that is the reachable half of the
/// screen and the half the keyboard does not cover.
///
/// Handles the four things every hand-rolled sheet got slightly wrong:
///  * a drag handle and dismissible barrier, so it behaves like the OS,
///  * the keyboard inset, so a focused field is never hidden,
///  * the bottom safe area, so actions clear the home indicator,
///  * a scrollable body with the actions pinned, so a long sheet still works
///    on a short screen.
Future<T?> showKomeroSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget Function(BuildContext context) builder,
  List<Widget> actions = const [],
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    useSafeArea: true,
    builder: (context) => _KomeroSheet(
      title: title,
      subtitle: subtitle,
      actions: actions,
      child: Builder(builder: builder),
    ),
  );
}

class _KomeroSheet extends StatelessWidget {
  const _KomeroSheet({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final media = MediaQuery.of(context);

    return Padding(
      // The keyboard inset belongs on the whole sheet, not on the body, so the
      // pinned actions ride above the keyboard too.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        // Never taller than most of the screen — the barrier has to stay
        // visible, or the sheet reads as a full page that cannot be dismissed.
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(fontSize: 13, color: c.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: child,
              ),
            ),
            if (actions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      // Full-width stacked actions: thumb-reachable, and they
                      // never truncate a Georgian or Russian label the way a
                      // side-by-side dialog button pair does.
                      SizedBox(width: double.infinity, child: actions[i]),
                    ],
                  ],
                ),
              )
            else
              SizedBox(height: 20 + media.padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.c.borderStrong,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// Yes/no confirmation as a sheet instead of an AlertDialog.
/// Returns true only when the operator picks the confirming action.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l = context.l;

  final result = await showKomeroSheet<bool>(
    context,
    title: title,
    builder: (context) => message == null
        ? const SizedBox.shrink()
        : Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: context.c.textSecondary,
            ),
          ),
    actions: [
      Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: context.c.error,
                  foregroundColor: context.c.primaryForeground,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ),
      Builder(
        builder: (context) => OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
      ),
    ],
  );

  return result ?? false;
}

/// Single free-text prompt as a sheet. Returns null when dismissed, and the
/// trimmed text otherwise.
Future<String?> promptSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String? message,
  int maxLines = 3,
  bool destructive = false,
}) async {
  final controller = TextEditingController();
  final l = context.l;

  try {
    return await showKomeroSheet<String>(
      context,
      title: title,
      subtitle: message,
      builder: (context) => TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: context.c.error,
                    foregroundColor: context.c.primaryForeground,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ),
        Builder(
          builder: (context) => OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
        ),
      ],
    );
  } finally {
    controller.dispose();
  }
}
