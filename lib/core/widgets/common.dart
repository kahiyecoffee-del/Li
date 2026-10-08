import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/labels.dart';
import '../theme/tokens.dart';
import 'mascot.dart';

/// Rounded surface used for every Home/Money card: soft layered shadow,
/// no outline, and a subtle press-in when tappable.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.lg + 2),
    this.semanticLabel,
    this.color,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final Color? color;
  final Gradient? gradient;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final radius = BorderRadius.circular(Radii.lg);
    final card = AnimatedScale(
      scale: _down ? 0.975 : 1,
      duration: Motion.fast,
      curve: Motion.curve,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.gradient == null ? (widget.color ?? context.colors.surface) : null,
          gradient: widget.gradient,
          borderRadius: radius,
          boxShadow: widget.gradient == null ? Shadows.soft(b) : null,
          // A hairline edge instead of a heavy outline: crisp on ivory and night.
          border: Border.all(
            color: context.semantic.border.withValues(alpha: b == Brightness.dark ? 1 : 0.7),
            width: 0.8,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    widget.onTap!();
                  },
            onHighlightChanged: _set,
            splashFactory: NoSplash.splashFactory,
            highlightColor: context.colors.onSurface.withValues(alpha: 0.03),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
    return widget.semanticLabel == null
        ? card
        : Semantics(label: widget.semanticLabel, button: widget.onTap != null, child: card);
  }
}

/// Card title row: small tinted icon, sentence-case title, optional trailing.
class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.icon, required this.title, this.trailing, this.accent});

  final IconData icon;
  final String title;
  final Widget? trailing;
  final Accent? accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconBubble(icon: icon, accent: accent ?? Accent.ai, size: 30),
      const SizedBox(width: Space.sm + 2),
      Expanded(
        child: Text(title, style: context.text.titleSmall?.copyWith(color: context.semantic.muted)),
      ),
      ?trailing,
    ],
  );
}

/// Softly tinted rounded square holding an earth-toned icon.
class IconBubble extends StatelessWidget {
  const IconBubble({super.key, required this.icon, required this.accent, this.size = 40});

  final IconData icon;
  final Accent accent;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: accent.tint(Theme.of(context).brightness),
      borderRadius: BorderRadius.circular(size * 0.32),
    ),
    child: Icon(icon, size: size * 0.56, color: accent.color),
  );
}

/// Fades and slides its child in once, after [delay]. Used for staggered
/// card entrances; renders immediately when reduce-motion is on.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 0.06});

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  // The delay is folded into the curve (no timers), so tests settle cleanly.
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + Motion.slow);
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Interval(widget.delay.inMilliseconds / _c.duration!.inMilliseconds, 1, curve: Motion.curve),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: SlideTransition(
      position: Tween(begin: Offset(0, widget.offset), end: Offset.zero).animate(_a),
      child: widget.child,
    ),
  );
}

/// Counts up to [value] when it changes.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, required this.format, this.style});

  final int value;
  final String Function(int) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: Motion.of(context, Motion.slow * 2),
    curve: Motion.curve,
    builder: (_, v, _) =>
        Text(format(v.round()), style: style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
  );
}

/// Soft gradient banner for screen tops.
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.child, this.gradient, this.padding = const EdgeInsets.all(Space.xl)});

  final Widget child;

  /// Defaults to the light meadow gradient (dark text on top).
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: gradient ?? (Theme.of(context).brightness == Brightness.dark ? Gradients.meadowDark : Gradients.meadow),
      borderRadius: BorderRadius.circular(Radii.xl),
      border: Border.all(
        color: Colors.white.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.6),
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(color: Palette.accent.withValues(alpha: 0.10), blurRadius: 40, offset: const Offset(0, 18)),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.eyebrow});

  final String text;
  final Widget? trailing;

  /// Small uppercase line above the title (e.g. a count or a date).
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.xs, Space.xl + 4, Space.xs, Space.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 4)],
                Text(text, style: context.text.headlineSmall?.copyWith(fontSize: 20, letterSpacing: -0.3)),
              ],
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Small, tracked uppercase label (Turkish-aware) used above titles.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    context.upper(text),
    style: context.text.labelSmall?.copyWith(
      color: color ?? context.semantic.muted,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w600,
      fontSize: 11,
    ),
  );
}

/// Soft, static pools of light behind the top of a screen: the "premium
/// paper" feel without images or motion cost.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({super.key, required this.child, this.height = 420});
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: height,
        child: IgnorePointer(
          child: CustomPaint(painter: _AmbientPainter(Gradients.ambient(Theme.of(context).brightness))),
        ),
      ),
      child,
    ],
  );
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.colors);
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset c, double r, Color color) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(rect),
      );
    }

    blob(Offset(size.width * 0.15, size.height * 0.12), size.width * 0.75, colors[0]);
    blob(Offset(size.width * 0.95, size.height * 0.05), size.width * 0.6, colors[1]);
    blob(Offset(size.width * 0.7, size.height * 0.75), size.width * 0.55, colors[2]);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.colors != colors;
}

/// Thin progress ring that sweeps to [value] (0–1) with [child] inside.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 72, this.stroke = 6, this.child, this.color});
  final double value;
  final double size;
  final double stroke;
  final Widget? child;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: Motion.of(context, const Duration(milliseconds: 900)),
      curve: Motion.emphasized,
      builder: (_, v, c) => CustomPaint(
        painter: _SweepRingPainter(
          v,
          stroke,
          track: context.semantic.border,
          color: color ?? context.colors.primary,
          tip: Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold,
        ),
        child: Center(child: c),
      ),
      child: child,
    ),
  );
}

class _SweepRingPainter extends CustomPainter {
  _SweepRingPainter(this.value, this.stroke, {required this.track, required this.color, required this.tip});
  final double value, stroke;
  final Color track, color, tip;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      6.2832,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value <= 0) return;
    canvas.drawArc(
      r,
      -1.5708,
      6.2832 * value,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -1.5708,
          endAngle: -1.5708 + 6.2832 * value,
          colors: [color, Color.lerp(color, tip, 0.6)!],
          transform: const GradientRotation(-1.5708),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_SweepRingPainter old) => old.value != value || old.color != color || old.track != track;
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action, this.mood});

  final IconData icon;
  final String message;
  final Widget? action;

  /// Which Lio artwork to show; defaults to the curious pose.
  final MascotMood? mood;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.xxl, horizontal: Space.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Mascot(mood: mood ?? MascotMood.curious, size: 110),
        const SizedBox(height: Space.lg),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: context.semantic.muted),
        ),
        if (action != null) ...[const SizedBox(height: Space.lg), action!],
      ],
    ),
  );
}

/// Friendly error with retry; never shows raw exception text.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_outlined,
    mood: MascotMood.thoughtful,
    message: context.l10n.failure(error),
    action: onRetry == null ? null : OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(label: context.l10n.loading, child: const CircularProgressIndicator()),
  );
}

/// Thin, rounded progress bar with an accessible value.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color, this.height = 8, this.label});

  final double value;
  final Color? color;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.primary;
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: '${(v * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(color: context.semantic.surfaceAlt, borderRadius: BorderRadius.circular(Radii.pill)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.pill),
              gradient: LinearGradient(colors: [c.withValues(alpha: 0.7), c]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular score gauge with a soft gradient arc.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 96, this.stroke = 9});

  final int? score;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final color = score == null ? context.semantic.muted : context.semantic.forScore(score!);
    return Semantics(
      label: context.l10n.lifeScore,
      value: score == null ? '-' : context.l10n.outOf100(score!),
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (score ?? 0) / 100),
          duration: Motion.of(context, Motion.slow * 2),
          curve: Motion.curve,
          builder: (_, v, _) => CustomPaint(
            painter: _RingPainter(value: v, color: color, track: context.semantic.surfaceAlt, stroke: stroke),
            child: Center(
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score == null ? '–' : '${(v * 100).round()}',
                      style: context.text.headlineMedium?.copyWith(
                        fontSize: size * 0.31,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (size >= 90)
                      Text('/100', style: context.text.labelSmall?.copyWith(color: context.semantic.muted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track, required this.stroke});

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      6.2832,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value <= 0) return;
    final sweep = 6.2832 * value;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: sweep < 0.01 ? 0.01 : sweep,
        colors: [color.withValues(alpha: 0.45), color],
        transform: const GradientRotation(-1.5708),
      ).createShader(rect);
    canvas.drawArc(r, -1.5708, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Material(
      color: context.semantic.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.page, vertical: Space.sm),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 16, color: context.semantic.muted),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(context.l10n.offlineBanner, style: context.text.bodySmall)),
          ],
        ),
      ),
    ),
  );
}

class PremiumPill extends StatelessWidget {
  const PremiumPill({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.colors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Text(context.l10n.premium, style: context.text.labelSmall?.copyWith(color: context.colors.primary)),
  );
}

/// Page scaffold padding helper for scrollable screens.
/// The standard scrolling page: soft ambient light at the top and sections
/// that arrive one after another (the Dayly look on every screen).
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children, this.padding, this.controller, this.animate = true});

  final List<Widget> children;
  final EdgeInsets? padding;
  final ScrollController? controller;

  /// Staggered entrance for the children (off for long, data-heavy lists).
  final bool animate;

  @override
  Widget build(BuildContext context) => AmbientBackdrop(
    child: ListView(
      controller: controller,
      padding: padding ?? const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 120),
      children: animate && children.length <= 40 ? staggered(children) : children,
    ),
  );
}

void showSnack(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final l = context.l10n;
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: c.semantic.negative) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel ?? l.confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Wraps each child in a [FadeSlideIn] with a short, growing delay so a
/// screen's sections arrive one after another (respects reduce-motion).
List<Widget> staggered(List<Widget> children) => [
  for (final (i, c) in children.indexed) FadeSlideIn(delay: Motion.stagger(i), offset: 0.04, child: c),
];
