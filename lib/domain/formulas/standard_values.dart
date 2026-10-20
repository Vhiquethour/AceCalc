import 'dart:math' as math;

abstract final class StandardValues {
  static const List<double> e12 = [
    1.0, 1.2, 1.5, 1.8, 2.2, 2.7, 3.3, 3.9, 4.7, 5.6, 6.8, 8.2, //
  ];

  /// Smallest E12 resistor value that is at least [value].
  static double nextE12(double value) {
    if (!(value > 0)) return double.nan;
    final decade = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
    final mantissa = value / decade;
    for (final step in e12) {
      if (step >= mantissa - 1e-9) return step * decade;
    }
    return 10 * decade;
  }
}
