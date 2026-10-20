typedef UnitTransform = double Function(double value);

/// One unit inside a category.
///
/// Linear units use [factor] (value in the category base unit per one of this
/// unit). Units with offsets or curves, such as Celsius, AWG or API gravity,
/// supply [toBase] and [fromBase] instead.
class UnitDef {
  const UnitDef({
    required this.id,
    required this.name,
    required this.symbol,
    this.factor = 1,
    this.toBase,
    this.fromBase,
  });

  final String id;
  final String name;
  final String symbol;
  final double factor;
  final UnitTransform? toBase;
  final UnitTransform? fromBase;

  bool get isLinear => toBase == null && fromBase == null;

  double convertToBase(double value) {
    final transform = toBase;
    return transform != null ? transform(value) : value * factor;
  }

  double convertFromBase(double base) {
    final transform = fromBase;
    return transform != null ? transform(base) : base / factor;
  }
}
