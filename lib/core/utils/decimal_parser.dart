abstract final class DecimalParser {
  /// Parses user input. A comma is treated as the decimal separator.
  static double? tryParse(String input) {
    final cleaned = input.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value.isNaN || value.isInfinite) return null;
    return value;
  }
}
