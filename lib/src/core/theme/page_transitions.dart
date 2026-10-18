import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Shopify-style page change: the two pages cross-fade in place with only a
/// short nudge, so the black header dissolves instead of sliding away — plus
/// the iOS swipe-from-the-left-edge back gesture, which a custom builder would
/// otherwise lose (Flutter's detector is private to
/// [CupertinoPageTransitionsBuilder]).
class RiseUpPageTransitionsBuilder extends PageTransitionsBuilder {
  const RiseUpPageTransitionsBuilder();

  // ponytail: short + fast is what reads as smooth; travel, not duration, was
  // what made the old version feel heavy.
  static const _travel = 0.04; // fraction of screen height

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Mid-drag the motion must follow the finger, so the curves are dropped.
    final dragging = route?.popGestureInProgress ?? false;
    final enter = dragging
        ? animation
        : CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
    final exit = dragging
        ? secondaryAnimation
        : CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut);

    return SlideTransition(
      // The page underneath drifts up a hair and fades out behind the new one.
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -_travel * 0.6),
      ).animate(exit),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(exit),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, _travel),
            end: Offset.zero,
          ).animate(enter),
          child: FadeTransition(
            opacity: enter,
            child: route == null ? child : _EdgeBackGesture(route: route, child: child),
          ),
        ),
      ),
    );
  }
}

/// Left-edge drag that drives the route's own transition controller backwards
/// and pops at the end — a condensed copy of Flutter's private
/// `_CupertinoBackGestureDetector`, kept because the real one cannot be reused
/// outside a Cupertino transition.
class _EdgeBackGesture<T> extends StatefulWidget {
  const _EdgeBackGesture({required this.route, required this.child});

  final PageRoute<T> route;
  final Widget child;

  @override
  State<_EdgeBackGesture<T>> createState() => _EdgeBackGestureState<T>();
}

class _EdgeBackGestureState<T> extends State<_EdgeBackGesture<T>> {
  static const _edgeWidth = 20.0;
  static const _minFlingVelocity = 1.0; // screen widths per second
  static const _settle = Duration(milliseconds: 350);
  static const _curve = Curves.fastEaseInToSlowEaseOut;

  late final HorizontalDragGestureRecognizer _recognizer =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _onStart
        ..onUpdate = _onUpdate
        ..onEnd = _onEnd
        ..onCancel = () => _onEnd(null);

  /// Non-null only between drag start and drag end.
  AnimationController? _dragging;

  AnimationController? get _controller =>
      // ignore: invalid_use_of_protected_member
      widget.route.controller;

  NavigatorState? get _navigator => widget.route.navigator;

  @override
  void dispose() {
    _recognizer.dispose();
    if (_dragging != null) {
      // Disposed mid-drag: the navigator would stay stuck in gesture mode.
      final navigator = _navigator;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator?.mounted ?? false) navigator!.didStopUserGesture();
      });
      _dragging = null;
    }
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent e) {
    if (widget.route.popGestureEnabled && _controller != null) {
      _recognizer.addPointer(e);
    }
  }

  double _logical(double v) =>
      Directionality.of(context) == TextDirection.rtl ? -v : v;

  void _onStart(DragStartDetails _) {
    _dragging = _controller;
    _navigator?.didStartUserGesture();
  }

  void _onUpdate(DragUpdateDetails d) {
    final c = _dragging;
    if (c == null) return;
    c.value -= _logical(d.primaryDelta! / context.size!.width);
  }

  void _onEnd(DragEndDetails? d) {
    final c = _dragging;
    _dragging = null;
    if (c == null) return;

    final velocity = d == null
        ? 0.0
        : _logical(d.velocity.pixelsPerSecond.dx / context.size!.width);
    final isCurrent = widget.route.isCurrent;

    final bool back;
    if (!isCurrent) {
      // Popped programmatically mid-drag: finish whichever way the stack went.
      back = widget.route.isActive;
    } else if (velocity.abs() >= _minFlingVelocity) {
      back = velocity <= 0;
    } else {
      back = c.value > 0.5;
    }

    if (back) {
      c.animateTo(1.0, duration: _settle, curve: _curve);
    } else {
      if (isCurrent) _navigator?.pop();
      // The pop may have finished inline, with nothing left to animate.
      if (c.isAnimating) {
        c.animateBack(0.0, duration: _settle, curve: _curve);
      }
    }

    if (c.isAnimating) {
      // Hold the gesture flag until the fling lands, so the curves above don't
      // snap back in mid-flight.
      void onStatus(AnimationStatus _) {
        _navigator?.didStopUserGesture();
        c.removeStatusListener(onStatus);
      }

      c.addStatusListener(onStatus);
    } else {
      _navigator?.didStopUserGesture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          // Wider where a notch eats into the edge, as iOS does.
          width: math.max(MediaQuery.paddingOf(context).left, _edgeWidth),
          child: Listener(
            onPointerDown: _onPointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}
