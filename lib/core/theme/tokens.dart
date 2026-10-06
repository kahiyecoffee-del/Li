import 'package:flutter/material.dart';

/// Design tokens. Premium, calm, finance-grade palette: one accent, neutral
/// surfaces, semantic colors used sparingly.
abstract final class Palette {
  // Brand accent (deep indigo-blue) and its dark-mode counterpart.
  static const accent = Color(0xFF3D5AFE);
  static const accentDark = Color(0xFF8C9EFF);

  // Light neutrals
  static const lightBg = Color(0xFFF6F7F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFEEF0F4);
  static const lightText = Color(0xFF0F1222);
  static const lightTextMuted = Color(0xFF5A6075);
  static const lightBorder = Color(0xFFE2E5EC);

  // Dark neutrals
  static const darkBg = Color(0xFF0B0D14);
  static const darkSurface = Color(0xFF151824);
  static const darkSurfaceAlt = Color(0xFF1D2130);
  static const darkText = Color(0xFFF2F3F7);
  static const darkTextMuted = Color(0xFFA3A9BC);
  static const darkBorder = Color(0xFF262B3B);

  // Semantic
  static const positive = Color(0xFF12A150);
  static const positiveDark = Color(0xFF4ADE80);
  static const warning = Color(0xFFD97706);
  static const warningDark = Color(0xFFFBBF24);
  static const negative = Color(0xFFDC2626);
  static const negativeDark = Color(0xFFF87171);
}

abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Horizontal page gutter.
  static const page = 20.0;
}

abstract final class Radii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const pill = 999.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const curve = Curves.easeOutCubic;
}

/// Minimum touch target (Material guideline is 48dp; spec requires ≥ 44dp).
const kMinTouchTarget = 48.0;

/// Semantic colors resolved for the current brightness.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.positive,
    required this.warning,
    required this.negative,
    required this.muted,
    required this.border,
    required this.surfaceAlt,
  });

  final Color positive;
  final Color warning;
  final Color negative;
  final Color muted;
  final Color border;
  final Color surfaceAlt;

  static const light = SemanticColors(
    positive: Palette.positive,
    warning: Palette.warning,
    negative: Palette.negative,
    muted: Palette.lightTextMuted,
    border: Palette.lightBorder,
    surfaceAlt: Palette.lightSurfaceAlt,
  );

  static const dark = SemanticColors(
    positive: Palette.positiveDark,
    warning: Palette.warningDark,
    negative: Palette.negativeDark,
    muted: Palette.darkTextMuted,
    border: Palette.darkBorder,
    surfaceAlt: Palette.darkSurfaceAlt,
  );

  /// Color for a 0–100 score.
  Color forScore(int score) => score >= 75 ? positive : (score >= 50 ? warning : negative);

  @override
  SemanticColors copyWith({
    Color? positive,
    Color? warning,
    Color? negative,
    Color? muted,
    Color? border,
    Color? surfaceAlt,
  }) => SemanticColors(
    positive: positive ?? this.positive,
    warning: warning ?? this.warning,
    negative: negative ?? this.negative,
    muted: muted ?? this.muted,
    border: border ?? this.border,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
  );

  @override
  SemanticColors lerp(SemanticColors? other, double t) {
    if (other == null) return this;
    return SemanticColors(
      positive: Color.lerp(positive, other.positive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
    );
  }
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  SemanticColors get semantic => Theme.of(this).extension<SemanticColors>()!;
}
