import 'package:flutter/material.dart';

/// Shopify-style page change: the two pages cross-fade in place with only a
/// short nudge, so the black header dissolves instead of sliding away.
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
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut);

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
          child: FadeTransition(opacity: enter, child: child),
        ),
      ),
    );
  }
}
