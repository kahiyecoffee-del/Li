import 'package:flutter/material.dart';

/// Design tokens — "Dayly" sunrise palette: warm, cheerful, still calm.
/// One coral accent drives actions; each life area gets a soft pastel tint
/// (see [Accents]) so screens feel friendly without visual noise.
abstract final class Palette {
  // Brand accent (sunrise coral) and its dark-mode counterpart.
  static const accent = Color(0xFFFF6B4A);
  static const accentDark = Color(0xFFFF8A6E);
  static const secondary = Color(0xFF7C5CFF);
  static const sun = Color(0xFFFFB703);

  // Light neutrals (warm)
  static const lightBg = Color(0xFFFFF8F3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFFFEFE7);
  static const lightText = Color(0xFF231C2E);
  static const lightTextMuted = Color(0xFF6F6680);
  static const lightBorder = Color(0xFFF3E3DA);

  // Dark neutrals (deep plum)
  static const darkBg = Color(0xFF14111D);
  static const darkSurface = Color(0xFF1E1A2B);
  static const darkSurfaceAlt = Color(0xFF29243A);
  static const darkText = Color(0xFFF7F3FF);
  static const darkTextMuted = Color(0xFFB7AFCB);
  static const darkBorder = Color(0xFF332D47);

  // Semantic
  static const positive = Color(0xFF10B981);
  static const positiveDark = Color(0xFF34D399);
  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFFBBF24);
  static const negative = Color(0xFFEF4444);
  static const negativeDark = Color(0xFFF87171);
}

/// Per-area accent colors (icon bubbles, chips, charts).
enum Accent {
  score(Color(0xFFFFB703)),
  goals(Color(0xFFFF6B4A)),
  plan(Color(0xFF3B82F6)),
  money(Color(0xFF10B981)),
  food(Color(0xFFFF8A4C)),
  wellbeing(Color(0xFF8B5CF6)),
  insight(Color(0xFFEC4899)),
  news(Color(0xFF0EA5E9)),
  ai(Color(0xFF7C5CFF));

  const Accent(this.color);

  final Color color;

  /// Soft background tint for bubbles/tiles, adapted to brightness.
  Color tint(Brightness b) => color.withValues(alpha: b == Brightness.dark ? 0.22 : 0.13);
}

/// Sunrise gradient used for hero headers (kept subtle, never on text-heavy areas).
abstract final class Gradients {
  static const sunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B4A), Color(0xFFFF9F45), Color(0xFFFFC857)],
  );
  static const dusk = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D4AFF), Color(0xFFB45CFF), Color(0xFFFF7A9A)],
  );
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
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 26.0;
  static const pill = 999.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);
  static const curve = Curves.easeOutCubic;
  static const bounce = Curves.easeOutBack;

  /// Honors the OS "reduce motion" setting.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : d;
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
