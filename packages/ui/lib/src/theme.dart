import 'package:flutter/material.dart';

import 'flora.dart';

abstract final class UtocisteTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(seedColor: Flora.leaf).copyWith(
      primary: Flora.leafDeep,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD8EBC4),
      onPrimaryContainer: const Color(0xFF1C3309),
      secondary: Flora.sage,
      onSecondary: const Color(0xFF1C3309),
      secondaryContainer: const Color(0xFFE4EFD6),
      onSecondaryContainer: const Color(0xFF2B4317),
      tertiary: Flora.rose,
      onTertiary: const Color(0xFF3D1230),
      tertiaryContainer: Flora.blossom,
      onTertiaryContainer: const Color(0xFF3D1230),
      surface: Flora.petal,
      onSurface: Flora.ink,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFDF2F9),
      surfaceContainer: const Color(0xFFFAE8F4),
      surfaceContainerHigh: Flora.blush,
      surfaceContainerHighest: const Color(0xFFF0CBE6),
      outlineVariant: const Color(0xFFE8CFE0),
    ),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(seedColor: Flora.leaf, brightness: Brightness.dark).copyWith(
      primary: Flora.sage,
      onPrimary: const Color(0xFF1C3309),
      secondary: const Color(0xFFB8D19B),
      tertiary: Flora.blossom,
      onTertiary: const Color(0xFF3D1230),
      tertiaryContainer: const Color(0xFF6A2F59),
      onTertiaryContainer: Flora.blush,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 48), shape: rounded),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48), shape: rounded),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: rounded)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        shape: rounded,
        selectedColor: scheme.onTertiaryContainer,
        selectedTileColor: scheme.tertiaryContainer,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        selectedColor: scheme.tertiaryContainer,
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
