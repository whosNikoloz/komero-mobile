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

class _PullToPreviewState extends State<PullToPreview> {
  static const _threshold = 72.0;

  double _pull = 0;
  bool _opening = false;

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

    if (n is OverscrollNotification && n.overscroll < 0) {
      _warmUp();
      setState(() => _pull = (_pull - n.overscroll).clamp(0.0, _threshold * 1.5));
    } else if (n is ScrollUpdateNotification && n.metrics.pixels > 0 && _pull > 0) {
      setState(() => _pull = 0);
    } else if (n is ScrollEndNotification && _pull > 0) {
      final open = _pull >= _threshold;
      setState(() => _pull = 0);
      if (open) _open();
    }
    return false;
  }

  Future<void> _open() async {
    _warmUp();
    _opening = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PreviewScreen(controller: _web!, url: widget.url),
      ),
    );
    _opening = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final progress = (_pull / _threshold).clamp(0.0, 1.0);

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        children: [
          // The hint lives behind the content and is uncovered by the pull.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _threshold,
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
            offset: Offset(0, _pull),
            child: widget.child,
          ),
        ],
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
