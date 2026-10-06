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
          boxShadow: Shadows.soft(b),
          border: b == Brightness.dark ? Border.all(color: context.semantic.border) : null,
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
      borderRadius: BorderRadius.circular(Radii.lg),
      boxShadow: [
        BoxShadow(color: Palette.accent.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 10)),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.xs, Space.xl, Space.xs, Space.sm),
    child: Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(text, style: context.text.titleMedium)),
        ),
        ?trailing,
      ],
    ),
  );
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
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children, this.padding, this.controller});

  final List<Widget> children;
  final EdgeInsets? padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => ListView(
    controller: controller,
    padding: padding ?? const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 120),
    children: children,
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
