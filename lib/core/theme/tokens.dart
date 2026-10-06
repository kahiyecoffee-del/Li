import 'package:flutter/material.dart';

/// Design tokens — Dayly "earth" palette: moss, terracotta, sand, ochre and
/// espresso on warm linen. One moss accent drives actions; each life area
/// has a muted earthy tint (see [Accent]) so screens stay calm and premium.
abstract final class Palette {
  // Brand: moss (light) / sage (dark). White on moss passes WCAG AA.
  static const accent = Color(0xFF4A6B52);
  static const accentDark = Color(0xFFA8C4A2);
  static const terracotta = Color(0xFFC0673F);
  static const ochre = Color(0xFFD29D45);
  static const sand = Color(0xFFE4D3B8);
  static const secondary = terracotta;
  static const sun = ochre;

  // Light neutrals (linen)
  static const lightBg = Color(0xFFF5F0E8);
  static const lightSurface = Color(0xFFFFFDFA);
  static const lightSurfaceAlt = Color(0xFFEDE5D8);
  static const lightText = Color(0xFF2A231E);
  static const lightTextMuted = Color(0xFF7B6F64);
  static const lightBorder = Color(0xFFE5DACA);

  // Dark neutrals (espresso)
  static const darkBg = Color(0xFF14110F);
  static const darkSurface = Color(0xFF1E1A17);
  static const darkSurfaceAlt = Color(0xFF29231F);
  static const darkText = Color(0xFFF2EBE2);
  static const darkTextMuted = Color(0xFFB2A699);
  static const darkBorder = Color(0xFF342D27);

  // Semantic (earth-tuned)
  static const positive = Color(0xFF5B8A5A);
  static const positiveDark = Color(0xFF9CC79A);
  static const warning = Color(0xFFC98A2E);
  static const warningDark = Color(0xFFE2B262);
  static const negative = Color(0xFFB8503A);
  static const negativeDark = Color(0xFFE38B74);
}

/// Per-area accent colors (icons, chips, charts) — muted earth tones.
enum Accent {
  score(Color(0xFFC9973F)),
  goals(Color(0xFFC0673F)),
  plan(Color(0xFF5D7C96)),
  money(Color(0xFF5B8A5A)),
  food(Color(0xFFB7794F)),
  wellbeing(Color(0xFF8A7AA0)),
  insight(Color(0xFFB06A66)),
  news(Color(0xFF4F8784)),
  ai(Color(0xFF4A6B52));

  const Accent(this.color);

  final Color color;

  /// Soft background tint for icon chips/tiles, adapted to brightness.
  Color tint(Brightness b) => color.withValues(alpha: b == Brightness.dark ? 0.20 : 0.12);
}

abstract final class Gradients {
  /// Light hero wash: linen → sage → sand (dark text on top).
  static const meadow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE9E4D4), Color(0xFFE1E6D6), Color(0xFFF1E3CC)],
  );
  static const meadowDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF26261F), Color(0xFF232821), Color(0xFF2E2620)],
  );

  /// Deep moss for primary promos (white text on top).
  static const forest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34503D), Color(0xFF4A6B52), Color(0xFF6E8A68)],
  );

  /// Sweep used by progress rings.
  static const ring = SweepGradient(
    startAngle: -1.5708,
    endAngle: 4.7124,
    colors: [Color(0xFFD29D45), Color(0xFFC0673F), Color(0xFF4A6B52), Color(0xFFD29D45)],
  );
}

/// Soft, layered shadows (never harsh outlines).
abstract final class Shadows {
  static List<BoxShadow> soft(Brightness b) => b == Brightness.dark
      ? const []
      : [
          BoxShadow(color: const Color(0xFF3B2A1E).withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(
            color: const Color(0xFF3B2A1E).withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ];
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
  static const md = 16.0;
  static const lg = 24.0;
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
