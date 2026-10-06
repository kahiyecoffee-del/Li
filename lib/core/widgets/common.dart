import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../theme/tokens.dart';

/// Rounded surface used for every Home/Money card.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.lg),
    this.semanticLabel,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    return semanticLabel == null ? card : Semantics(label: semanticLabel, button: onTap != null, child: card);
  }
}

/// Small uppercase label + optional trailing action, above a card's content.
class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: context.semantic.muted),
      const SizedBox(width: Space.sm),
      Expanded(
        child: Text(
          title.toUpperCase(),
          style: context.text.labelSmall?.copyWith(color: context.semantic.muted, letterSpacing: 1.0),
        ),
      ),
      ?trailing,
    ],
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
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.xxl, horizontal: Space.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: context.semantic.muted),
        const SizedBox(height: Space.md),
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
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: '${(value.clamp(0, 1) * 100).round()}%',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: height, color: color),
    ),
  );
}

/// Circular score gauge.
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (score ?? 0) / 100),
                duration: Motion.normal * 3,
                curve: Motion.curve,
                builder: (_, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: stroke,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: context.semantic.surfaceAlt,
                ),
              ),
            ),
            ExcludeSemantics(
              child: Text(
                score?.toString() ?? '–',
                style: context.text.headlineMedium?.copyWith(
                  fontSize: size * 0.32,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
