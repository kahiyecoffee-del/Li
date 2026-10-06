import 'package:flutter/material.dart';

/// Design tokens — Dayly palette, taken from Lio the mascot: leaf green,
/// mint, cream, peach and sun. One green accent drives actions; each life area gets a soft pastel tint
/// (see [Accents]) so screens feel friendly without visual noise.
abstract final class Palette {
  // Brand (Lio's leaf green) and its dark-mode counterpart. The darker
  // shade keeps white button labels readable (WCAG AA for large text).
  static const accent = Color(0xFF2E8B5E);
  static const accentDark = Color(0xFF7FD4A5);
  static const leaf = Color(0xFF4CAF7D);
  static const mint = Color(0xFFA7DB95);
  static const secondary = Color(0xFFFF9B8A); // peach
  static const sun = Color(0xFFFFD166);

  // Light neutrals (warm cream)
  static const lightBg = Color(0xFFF8F5EC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFEEF5E9);
  static const lightText = Color(0xFF1F2B24);
  static const lightTextMuted = Color(0xFF66736B);
  static const lightBorder = Color(0xFFE6E8DC);

  // Dark neutrals (deep forest)
  static const darkBg = Color(0xFF101814);
  static const darkSurface = Color(0xFF18231D);
  static const darkSurfaceAlt = Color(0xFF223028);
  static const darkText = Color(0xFFF1F7F2);
  static const darkTextMuted = Color(0xFFA9BCB0);
  static const darkBorder = Color(0xFF2C3B32);

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
  score(Color(0xFFF2B53A)),
  goals(Color(0xFFFF8A7A)),
  plan(Color(0xFF3B82F6)),
  money(Color(0xFF3FAE7A)),
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

/// Brand gradients. [meadow] is light (dark text on top); [forest] is
/// deep (white text on top).
abstract final class Gradients {
  static const meadow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDDF1D8), Color(0xFFEFF7E2), Color(0xFFFFF1D2)],
  );
  static const meadowDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F3A2C), Color(0xFF243A2A), Color(0xFF3A3524)],
  );
  static const forest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F6E4A), Color(0xFF2E8B5E), Color(0xFF4CAF7D)],
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
