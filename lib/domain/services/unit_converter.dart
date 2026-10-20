import '../entities/unit_def.dart';

abstract final class UnitConverter {
  /// Converts [value] from one unit to another through the category base unit.
  static double convert(double value, UnitDef from, UnitDef to) {
    final base = from.convertToBase(value);
    return to.convertFromBase(base);
  }
}
