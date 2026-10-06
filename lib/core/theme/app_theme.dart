import 'package:flutter/material.dart';

import 'tokens.dart';
import 'transitions.dart';

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
      secondary: Palette.secondary,
      tertiary: Palette.sun,
      primaryContainer: Color.alphaBlend(accent.withValues(alpha: isDark ? 0.24 : 0.14), surface),
      onPrimaryContainer: isDark ? text : Palette.accent,
      secondaryContainer: Color.alphaBlend(accent.withValues(alpha: isDark ? 0.24 : 0.14), surface),
      onSecondaryContainer: isDark ? text : Palette.accent,
      tertiaryContainer: Color.alphaBlend(Palette.ochre.withValues(alpha: 0.18), surface),
      onTertiaryContainer: text,
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

    // Editorial pairing: Fraunces (serif) for display/headlines, Plus
    // Jakarta Sans for everything else. Both cover Latin Extended (TR).
    const serif = 'Fraunces';
    final base = Typography.material2021(platform: TargetPlatform.android).black;
    final textTheme = (isDark ? Typography.material2021().white : base)
        .copyWith(
          displaySmall: const TextStyle(
            fontFamily: serif,
            fontSize: 38,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
            height: 1.1,
          ),
          headlineMedium: const TextStyle(
            fontFamily: serif,
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
            height: 1.15,
          ),
          headlineSmall: const TextStyle(
            fontFamily: serif,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.2,
          ),
          titleLarge: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1),
          titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
          bodyMedium: const TextStyle(fontSize: 15, height: 1.5),
          bodySmall: const TextStyle(fontSize: 13, height: 1.45),
          labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0),
          labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        )
        .apply(bodyColor: text, displayColor: text, fontFamily: 'Jakarta');
    // apply() overrides fontFamily everywhere; restore the serif headings.
    final tt = textTheme.copyWith(
      displaySmall: textTheme.displaySmall?.copyWith(fontFamily: serif),
      headlineMedium: textTheme.headlineMedium?.copyWith(fontFamily: serif),
      headlineSmall: textTheme.headlineSmall?.copyWith(fontFamily: serif),
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Jakarta',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SoftRisePageTransitionsBuilder(),
          TargetPlatform.iOS: SoftRisePageTransitionsBuilder(),
          TargetPlatform.macOS: SoftRisePageTransitionsBuilder(),
          TargetPlatform.linux: SoftRisePageTransitionsBuilder(),
          TargetPlatform.windows: SoftRisePageTransitionsBuilder(),
          TargetPlatform.fuchsia: SoftRisePageTransitionsBuilder(),
        },
      ),
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: tt,
      extensions: [semantic],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,
        centerTitle: false,
        titleTextStyle: tt.headlineSmall?.copyWith(fontSize: 22),
        foregroundColor: text,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: isDark ? BorderSide(color: border) : BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.18),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(tt.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? accent : muted),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 54), shape: shape, textStyle: tt.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: shape,
          side: BorderSide(color: border),
          foregroundColor: text,
          textStyle: tt.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, kMinTouchTarget), textStyle: tt.labelLarge),
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
        side: BorderSide.none,
        backgroundColor: surfaceAlt,
        selectedColor: accent.withValues(alpha: 0.18),
        labelStyle: tt.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: isDark ? Palette.darkBg : Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md + 2)),
        extendedTextStyle: tt.labelLarge,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : muted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent : surfaceAlt),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent, linearTrackColor: surfaceAlt),
    );
  }
}
