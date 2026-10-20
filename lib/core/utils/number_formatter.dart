import 'dart:math' as math;

abstract final class NumberFormatter {
  /// Formats [value] to [sigFigs] significant figures.
  ///
  /// Very large and very small numbers use a short scientific form.
  static String format(double value, {int sigFigs = 6}) {
    if (value.isNaN) return '—';
    if (value.isInfinite) return value.isNegative ? '-∞' : '∞';
    if (value == 0) return '0';

    final size = value.abs();
    if (size >= 1e9 || size < 1e-4) {
      return _scientific(value, sigFigs);
    }

    final magnitude = (math.log(size) / math.ln10).floor();
    final decimals = math.max(0, sigFigs - 1 - magnitude);
    return _trim(value.toStringAsFixed(decimals));
  }

  static String _scientific(double value, int sigFigs) {
    final text = value.toStringAsExponential(sigFigs - 1);
    final parts = text.split('e');
    final mantissa = _trim(parts[0]);
    final exponent = int.parse(parts[1].replaceFirst('+', ''));
    return '${mantissa}e$exponent';
  }

  static String _trim(String text) {
    if (!text.contains('.')) return text;
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
