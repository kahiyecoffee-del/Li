import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lio, the Dayly mascot. Each mood is a separate transparent artwork in
/// `assets/mascot/`.
enum MascotMood { happy, curious, loving, sleepy, excited, thoughtful, front, heart }

class Mascot extends StatefulWidget {
  const Mascot({super.key, this.mood = MascotMood.front, this.size = 120, this.float = true, this.semanticLabel});

  final MascotMood mood;

  /// Height in logical pixels.
  final double size;

  /// Gently bobs a few times after appearing (never loops forever, so it
  /// stays battery friendly and tests can settle).
  final bool float;
  final String? semanticLabel;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (widget.float && !reduce && !_c.isAnimating && _c.value == 0) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/mascot/${widget.mood.name}.webp',
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: widget.semanticLabel,
      excludeFromSemantics: widget.semanticLabel == null,
      // Entrance: pop in softly.
      frameBuilder: (_, child, frame, sync) => sync
          ? child
          : AnimatedScale(
              scale: frame == null ? 0.85 : 1,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 260),
                child: child,
              ),
            ),
      errorBuilder: (_, _, _) => SizedBox(height: widget.size, width: widget.size * 0.9),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        // Three soft bobs that ease out.
        final t = _c.value;
        final dy = math.sin(t * math.pi * 6) * (1 - t) * widget.size * 0.035;
        return Transform.translate(offset: Offset(0, -dy.abs()), child: child);
      },
      child: image,
    );
  }
}
