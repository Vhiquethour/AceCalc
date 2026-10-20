import 'dart:math' as math;

import '../entities/formula_def.dart';

const double standardGravity = 9.80665;

FormulaInput numIn(
  String key,
  String label,
  String unit, {
  double? def,
  bool optional = false,
  String? hint,
}) {
  return FormulaInput(
    key: key,
    label: label,
    unit: unit,
    defaultValue: def,
    optional: optional,
    hint: hint,
  );
}

FormulaInput choiceIn(
  String key,
  String label,
  List<FormulaChoice> choices, {
  double? def,
}) {
  return FormulaInput(
    key: key,
    label: label,
    choices: choices,
    defaultValue: def ?? choices.first.value,
  );
}

FormulaOutput numOut(String key, String label, [String unit = '']) {
  return FormulaOutput(key: key, label: label, unit: unit);
}

FormulaResult res(
  Map<String, double> values, [
  List<String> messages = const [],
]) {
  return FormulaResult(values, messages: messages);
}

void requirePositive(double x, String name) {
  if (!(x > 0)) throw FormulaException('$name must be greater than zero.');
}

void requireNonNegative(double x, String name) {
  if (!(x >= 0)) throw FormulaException('$name cannot be negative.');
}

void requireRange(double x, String name, double min, double max) {
  if (!(x >= min && x <= max)) {
    throw FormulaException('$name must be between ${_plain(min)} and ${_plain(max)}.');
  }
}

String _plain(double x) =>
    x == x.roundToDouble() ? x.toStringAsFixed(0) : x.toString();

double log10(double x) => math.log(x) / math.ln10;

double degToRad(double degrees) => degrees * math.pi / 180;

double radToDeg(double radians) => radians * 180 / math.pi;

/// Returns the values for [keys] that the user supplied, in order.
List<double> present(Map<String, double> v, List<String> keys) {
  return [
    for (final key in keys)
      if (v[key] != null) v[key]!,
  ];
}

/// Reads rows made of two linked inputs. A row with only one value throws.
List<List<double>> pairs(Map<String, double> v, List<List<String>> keys) {
  final rows = <List<double>>[];
  for (var index = 0; index < keys.length; index++) {
    final a = v[keys[index][0]];
    final b = v[keys[index][1]];
    if (a == null && b == null) continue;
    if (a == null || b == null) {
      throw FormulaException('Enter both values for row ${index + 1}.');
    }
    rows.add([a, b]);
  }
  return rows;
}
