import 'package:flutter/material.dart';

/// Page transition: the new page fades in while gliding up a few pixels and
/// settling from 97% scale; the old page gently fades back. Short, soft and
/// consistent on Android and iOS.
class SoftRisePageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftRisePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) return child;
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final exit = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.85).animate(exit),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.035), end: Offset.zero).animate(enter),
          child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(enter), child: child),
        ),
      ),
    );
  }
}
