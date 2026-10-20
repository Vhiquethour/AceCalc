import 'package:flutter/material.dart';

/// Extra colours that sit beside the Material colour scheme.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.card,
    required this.chip,
    required this.muted,
    required this.border,
    required this.warning,
    required this.success,
  });

  final Color card;
  final Color chip;
  final Color muted;
  final Color border;
  final Color warning;
  final Color success;

  @override
  AppPalette copyWith({
    Color? card,
    Color? chip,
    Color? muted,
    Color? border,
    Color? warning,
    Color? success,
  }) {
    return AppPalette(
      card: card ?? this.card,
      chip: chip ?? this.chip,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      warning: warning ?? this.warning,
      success: success ?? this.success,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      card: Color.lerp(card, other.card, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
