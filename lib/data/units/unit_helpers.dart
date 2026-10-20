import '../../domain/entities/unit_def.dart';

/// Builds a linear unit. [factor] is the number of base units in one of this
/// unit, for example 0.3048 for a foot when the base unit is the metre.
UnitDef linearUnit(String id, String name, String symbol, double factor) {
  return UnitDef(id: id, name: name, symbol: symbol, factor: factor);
}
