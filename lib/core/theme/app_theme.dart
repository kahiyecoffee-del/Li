import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds light, dark and high-contrast themes from the design tokens.
abstract final class AppTheme {
  static ThemeData light({bool highContrast = false}) => _build(
    brightness: Brightness.light,
    accent: Palette.accent,
    bg: Palette.lightBg,
    surface: Palette.lightSurface,
    surfaceAlt: Palette.lightSurfaceAlt,
    text: Palette.lightText,
    muted: highContrast ? Palette.lightText : Palette.lightTextMuted,
    border: highContrast ? Palette.lightText : Palette.lightBorder,
    semantic: highContrast
        ? SemanticColors.light.copyWith(muted: Palette.lightText, border: Palette.lightText)
        : SemanticColors.light,
  );

  static ThemeData dark({bool highContrast = false}) => _build(
    brightness: Brightness.dark,
    accent: Palette.accentDark,
    bg: highContrast ? Colors.black : Palette.darkBg,
    surface: Palette.darkSurface,
    surfaceAlt: Palette.darkSurfaceAlt,
    text: Palette.darkText,
    muted: highContrast ? Palette.darkText : Palette.darkTextMuted,
    border: highContrast ? Palette.darkText : Palette.darkBorder,
    semantic: highContrast
        ? SemanticColors.dark.copyWith(muted: Palette.darkText, border: Palette.darkText)
        : SemanticColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color accent,
    required Color bg,
    required Color surface,
    required Color surfaceAlt,
    required Color text,
    required Color muted,
    required Color border,
    required SemanticColors semantic,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness).copyWith(
      primary: accent,
      onPrimary: isDark ? Palette.darkBg : Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      surfaceContainerHighest: surfaceAlt,
      surfaceContainerHigh: surfaceAlt,
      surfaceContainer: surface,
      surfaceContainerLow: surface,
      outline: border,
      outlineVariant: border,
      error: semantic.negative,
    );

    // Large, confident type scale (system font for global script coverage).
    final base = Typography.material2021(platform: TargetPlatform.android).black;
    final textTheme = (isDark ? Typography.material2021().white : base)
        .copyWith(
          displaySmall: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.1),
          headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2),
          headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleLarge: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
          bodyMedium: const TextStyle(fontSize: 15, height: 1.45),
          bodySmall: const TextStyle(fontSize: 13, height: 1.4),
          labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
        )
        .apply(bodyColor: text, displayColor: text);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      extensions: [semantic],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: text,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: border, width: isDark ? 1 : 0.6),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.14),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? accent : muted),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 52), shape: shape, textStyle: textTheme.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: shape,
          side: BorderSide(color: border),
          foregroundColor: text,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, kMinTouchTarget), textStyle: textTheme.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: muted),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
        side: BorderSide(color: border),
        backgroundColor: surface,
        selectedColor: accent.withValues(alpha: 0.16),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        iconColor: muted,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, kMinTouchTarget)),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent, linearTrackColor: surfaceAlt),
    );
  }
}
