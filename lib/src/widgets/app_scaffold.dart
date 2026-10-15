import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/tokens.dart';

/// The frame every tab shares: a large page name on the app's own background,
/// and the screen's content in a rounded sheet below it.
///
/// The header carries the page name and nothing else — which page you are on
/// is the one thing that changes up there, so it is the one thing it says. The
/// store's own identity belongs on Home, which passes [titleWidget] instead.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.onTitleTap,
    required this.body,
    this.floatingActionButton,
  }) : assert(
          title != null || titleWidget != null,
          'A screen needs a page name, or its own widget in place of one.',
        );

  final String? title;

  /// Replaces the page name outright — Home uses it for the store's logo and
  /// name, the way the web admin shows the store it is managing.
  final Widget? titleWidget;

  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  /// When set, the page name gets a chevron and opens this — the switcher
  /// between sections that live under one tab, the way the catalog's
  /// categories and brands sit behind Products. It is handed the title's own
  /// context so the menu can drop from the title rather than from the page.
  final void Function(BuildContext titleContext)? onTitleTap;

  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      // `overlay` is the palette's dark plate — navy-950 in light, black in
      // dark — and `onOverlay` is the light ink that goes on it. Using that
      // pair rather than a literal black keeps the header themed, and gives
      // the sheet below something to round against.
      backgroundColor: c.overlay,
      appBar: AppBar(
        backgroundColor: c.overlay,
        foregroundColor: c.onOverlay,
        // The band behind the status bar is dark now, so its clock and icons
        // have to be drawn light.
        systemOverlayStyle: SystemUiOverlayStyle.light,
        // No divider: the sheet's top corners already separate the header from
        // the content, and a line as well would be one edge too many.
        shape: const Border(),
        toolbarHeight: 60,
        titleSpacing: leading == null ? 20 : 8,
        centerTitle: centerTitle,
        leading: leading,
        leadingWidth: leading == null ? null : 60,
        title: titleWidget ?? _PageTitle(title: title!, onTap: onTitleTap),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // Clipped, so a list scrolling under the top corners is cut by them
        // rather than painting over them.
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.onTap});

  final String title;
  final void Function(BuildContext titleContext)? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final text = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: c.onOverlay,
      ),
    );

    if (onTap == null) return text;

    return InkWell(
      onTap: () => onTap!(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: text),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 22, color: c.onOverlay),
          ],
        ),
      ),
    );
  }
}
