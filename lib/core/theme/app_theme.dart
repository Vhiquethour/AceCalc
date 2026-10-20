import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    return _build(
      brightness: Brightness.dark,
      screen: DarkColors.screen,
      text: DarkColors.text,
      accent: DarkColors.accent,
      onAccent: DarkColors.onAccent,
      error: DarkColors.error,
      palette: const AppPalette(
        card: DarkColors.card,
        chip: DarkColors.chip,
        muted: DarkColors.muted,
        border: DarkColors.border,
        warning: DarkColors.warning,
        success: DarkColors.success,
      ),
    );
  }

  static ThemeData light() {
    return _build(
      brightness: Brightness.light,
      screen: LightColors.screen,
      text: LightColors.text,
      accent: LightColors.accent,
      onAccent: LightColors.onAccent,
      error: LightColors.error,
      palette: const AppPalette(
        card: LightColors.card,
        chip: LightColors.chip,
        muted: LightColors.muted,
        border: LightColors.border,
        warning: LightColors.warning,
        success: LightColors.success,
      ),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color screen,
    required Color text,
    required Color accent,
    required Color onAccent,
    required Color error,
    required AppPalette palette,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: accent,
      onPrimaryContainer: onAccent,
      secondary: accent,
      onSecondary: onAccent,
      secondaryContainer: palette.chip,
      onSecondaryContainer: text,
      error: error,
      onError: onAccent,
      surface: screen,
      onSurface: text,
      onSurfaceVariant: palette.muted,
      surfaceContainer: palette.card,
      surfaceContainerHighest: palette.chip,
      outline: palette.border,
      outlineVariant: palette.border,
    );

    final baseText = ThemeData(brightness: brightness).textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: screen,
      textTheme: baseText.apply(bodyColor: text, displayColor: text),
      appBarTheme: AppBarTheme(
        backgroundColor: screen,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.card,
        indicatorColor: palette.chip,
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: palette.card),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 0.7),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }
}
