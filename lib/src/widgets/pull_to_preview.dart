import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/theme/tokens.dart';
import '../l10n_ext.dart';

/// Wraps a scrollable editor so that over-pulling it at the top opens the live
/// storefront page in a web view, Shopify-style: a hint slides out of the top
/// edge while pulling, and letting go past the threshold opens the preview.
class PullToPreview extends StatefulWidget {
  const PullToPreview({
    super.key,
    required this.url,
    required this.child,
    this.enabled = true,
  });

  /// Storefront URL to show. Null-safe callers pass an empty string to disable.
  final String url;
  final Widget child;
  final bool enabled;

  @override
  State<PullToPreview> createState() => _PullToPreviewState();
}

/// Distance the editor must be pulled down before letting go opens the
/// preview, and the furthest the hint will follow the finger.
const pullThreshold = 72.0;
const maxPull = pullThreshold * 1.5;

/// One scroll notification folded into the pull state — pure, so the gesture
/// is testable without a platform web view behind it.
///
/// Two platform shapes to cover: clamping physics (Android) holds the offset
/// at 0 and reports `overscroll`, while bouncing physics (iOS) reports no
/// overscroll at all and simply lets the offset go negative.
///
/// `release` is read off `dragDetails`, which only the drag phase carries. It
/// cannot come from `ScrollEndNotification` or a `ScrollDirection.idle`
/// `UserScrollNotification`: on iOS both of those arrive after the bounce has
/// already sprung back to 0, with the pull long erased.
@visibleForTesting
({double pull, bool bouncing, bool release, bool open}) pullStep(
  ScrollNotification n,
  double pull,
) {
  final dragging = switch (n) {
    OverscrollNotification(:final dragDetails) => dragDetails != null,
    ScrollUpdateNotification(:final dragDetails) => dragDetails != null,
    _ => false,
  };

  if (!dragging) {
    return (pull: 0, bouncing: false, release: pull > 0, open: pull >= pullThreshold);
  }

  if (n.metrics.pixels < 0) {
    return (pull: -n.metrics.pixels, bouncing: true, release: false, open: false);
  }
  if (n is OverscrollNotification && n.overscroll < 0) {
    return (pull: pull - n.overscroll, bouncing: false, release: false, open: false);
  }
  return (pull: 0, bouncing: false, release: false, open: false);
}

class _PullToPreviewState extends State<PullToPreview> {
  double _pull = 0;
  bool _opening = false;

  /// True when the platform's own physics already slid the content down for us
  /// (iOS bounce), so the hint must not be translated a second time.
  bool _bouncing = false;

  /// Built and told to load the moment the pull starts, so the page is usually
  /// painted by the time the finger lifts — the trick that makes Shopify's
  /// preview feel instant. Kept alive afterwards, so re-opening costs nothing.
  WebViewController? _web;

  void _warmUp() {
    if (_web != null || widget.url.isEmpty) return;

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _onNotification(ScrollNotification n) {
    if (!widget.enabled || widget.url.isEmpty || _opening) return false;
    if (n.metrics.axis != Axis.vertical) return false;

    final step = pullStep(n, _pull);
    if (step.pull > 0) _warmUp();
    _set(step.pull, step.bouncing);
    if (step.release && step.open) _open();
    return false;
  }

  void _set(double pull, bool bouncing) {
    final next = pull.clamp(0.0, maxPull);
    if (next == _pull && bouncing == _bouncing) return;
    setState(() {
      _pull = next;
      _bouncing = bouncing;
    });
  }

  Future<void> _open() async {
    _warmUp();
    _opening = true;
    await Navigator.of(context).push(
      _PreviewRoute(
        builder: (_) => _PreviewScreen(controller: _web!, url: widget.url),
      ),
    );
    _opening = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final progress = (_pull / pullThreshold).clamp(0.0, 1.0);

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        children: [
          // The hint lives behind the content and is uncovered by the pull.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: pullThreshold,
            child: Opacity(
              opacity: progress,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      progress == 1 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l.pullToPreview,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, _bouncing ? 0 : _pull),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// The preview arrives the way Shopify's does: a rounded card sliding down
/// from the top edge over the editor, which stays put underneath instead of
/// playing its own exit. Pushed with the app's default route the whole thing
/// was a 220ms cross-fade, which reads as a jump cut.
class _PreviewRoute<T> extends PageRouteBuilder<T> {
  _PreviewRoute({required WidgetBuilder builder})
      : super(
          // See-through while sliding, so the editor shows above the card.
          // ponytail: it also keeps the editor painting underneath once the
          // preview has landed — make it opaque on arrival if that ever shows
          // up in a frame profile.
          opaque: false,
          pageBuilder: (context, _, _) => builder(context),
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: _slideDown,
        );

  // The editor would otherwise fade out under a card it is supposed to stay
  // visible behind.
  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  static Widget _slideDown(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fast out of the gate, long settle — the iOS sheet feel, and the reason a
    // plain easeOut looks cheap next to it.
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.fastEaseInToSlowEaseOut,
      reverseCurve: Curves.fastEaseInToSlowEaseOut.flipped,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(curve),
      child: AnimatedBuilder(
        animation: curve,
        // The corners and the shadow only exist while the card is in flight;
        // at rest it is an ordinary full-bleed page.
        builder: (context, child) {
          final lift = 1 - curve.value;
          if (lift == 0) return child!;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28 * lift),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18 * lift),
                  blurRadius: 24,
                  offset: Offset(0, 8 * lift),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28 * lift),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
}

class _PreviewScreen extends StatefulWidget {
  const _PreviewScreen({required this.controller, required this.url});

  final WebViewController controller;
  final String url;

  @override
  State<_PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<_PreviewScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ),
    );
    // A page that finished loading during the pull fires no further callback.
    widget.controller.getTitle().then((title) {
      if (mounted && title != null && title.isNotEmpty) {
        setState(() => _loading = false);
      }
    });
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await widget.controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.preview),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: widget.controller),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
      // Tapping the bar drops back into the editor, the way Shopify does it.
      bottomNavigationBar: InkWell(
        onTap: () => Navigator.of(context).pop(),
        // Rounded top, shadow above it: the bar reads as a sheet the preview
        // slides under rather than as a strip welded to the bottom. The
        // decoration wraps the SafeArea so the surface still runs to the
        // screen edge behind the home indicator.
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                color: c.overlay.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l.edit, style: TextStyle(color: c.text)),
                  Icon(Icons.keyboard_arrow_up, color: c.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
