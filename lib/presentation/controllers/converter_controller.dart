import 'package:flutter/foundation.dart';

import '../../core/utils/decimal_parser.dart';
import '../../domain/entities/unit_category.dart';
import '../../domain/entities/unit_def.dart';
import '../../domain/services/unit_converter.dart';

class ConverterController extends ChangeNotifier {
  ConverterController(this.category)
      : _from = category.units[category.defaultFromIndex],
        _to = category.units[category.defaultToIndex];

  final UnitCategory category;
  UnitDef _from;
  UnitDef _to;
  String _input = '1';

  UnitDef get from => _from;
  UnitDef get to => _to;
  String get input => _input;

  double? get _inputValue => DecimalParser.tryParse(_input);

  /// A problem with the current input, or null when the input is fine or empty.
  String? get message {
    if (_input.trim().isEmpty) return null;
    final value = _inputValue;
    if (value == null) return 'Enter a valid number.';
    final converted = UnitConverter.convert(value, _from, _to);
    if (converted.isNaN || converted.isInfinite) {
      return 'That value is not valid for these units.';
    }
    final minimum = category.minBase;
    if (minimum != null && _from.convertToBase(value) < minimum - 1e-9) {
      return category.minBaseMessage ?? 'That value is out of range.';
    }
    return null;
  }

  double? get result {
    final value = _inputValue;
    if (value == null || message != null) return null;
    return UnitConverter.convert(value, _from, _to);
  }

  /// What one unit of the "from" unit equals in the "to" unit.
  double? get referenceValue {
    final converted = UnitConverter.convert(1, _from, _to);
    if (converted.isNaN || converted.isInfinite) return null;
    return converted;
  }

  /// The input expressed in every other unit of the category.
  List<MapEntry<UnitDef, double>> get allConversions {
    final value = _inputValue;
    if (value == null || message != null) return const [];
    final rows = <MapEntry<UnitDef, double>>[];
    for (final unit in category.units) {
      if (unit == _from) continue;
      final converted = UnitConverter.convert(value, _from, unit);
      if (converted.isNaN || converted.isInfinite) continue;
      rows.add(MapEntry(unit, converted));
    }
    return rows;
  }

  void setInput(String text) {
    _input = text;
    notifyListeners();
  }

  void setFrom(UnitDef unit) {
    _from = unit;
    notifyListeners();
  }

  void setTo(UnitDef unit) {
    _to = unit;
    notifyListeners();
  }

  void swap() {
    final previousFrom = _from;
    _from = _to;
    _to = previousFrom;
    notifyListeners();
  }
}
