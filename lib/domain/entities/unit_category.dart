import 'unit_def.dart';

class UnitCategory {
  const UnitCategory({
    required this.id,
    required this.name,
    required this.group,
    required this.iconKey,
    required this.units,
    this.note,
    this.defaultFromIndex = 0,
    this.defaultToIndex = 1,
    this.minBase,
    this.minBaseMessage,
  });

  final String id;
  final String name;
  final String group;
  final String iconKey;
  final List<UnitDef> units;
  final String? note;
  final int defaultFromIndex;
  final int defaultToIndex;

  /// Smallest allowed value in the base unit, for example absolute zero.
  final double? minBase;
  final String? minBaseMessage;
}
