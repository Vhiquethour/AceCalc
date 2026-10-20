import 'package:flutter/painting.dart';

/// Midnight blue palette (default theme).
abstract final class DarkColors {
  static const Color screen = Color(0xFF0B1220);
  static const Color card = Color(0xFF141C2E);
  static const Color chip = Color(0xFF1F2A44);
  static const Color text = Color(0xFFE2E8F0);
  static const Color muted = Color(0xFF94A3B8);
  static const Color accent = Color(0xFF38BDF8);
  static const Color onAccent = Color(0xFF04283D);
  static const Color border = Color(0xFF263250);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color success = Color(0xFF4ADE80);
}

/// Clean light palette (optional theme).
abstract final class LightColors {
  static const Color screen = Color(0xFFF4F6F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color chip = Color(0xFFE6EBF0);
  static const Color text = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color accent = Color(0xFF1D4ED8);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD8DEE5);
  static const Color error = Color(0xFFB91C1C);
  static const Color warning = Color(0xFFB45309);
  static const Color success = Color(0xFF15803D);
}
