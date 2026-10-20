enum FormulaPack { electrical, mechanical, fluids, safety, solar, general }

extension FormulaPackLabel on FormulaPack {
  String get label {
    switch (this) {
      case FormulaPack.electrical:
        return 'Electrical';
      case FormulaPack.mechanical:
        return 'Motors and mechanical';
      case FormulaPack.fluids:
        return 'Fluids and oil and gas';
      case FormulaPack.safety:
        return 'Health and safety';
      case FormulaPack.solar:
        return 'Solar and embedded';
      case FormulaPack.general:
        return 'General';
    }
  }
}

class FormulaChoice {
  const FormulaChoice(this.label, this.value);

  final String label;
  final double value;
}

class FormulaInput {
  const FormulaInput({
    required this.key,
    required this.label,
    this.unit = '',
    this.defaultValue,
    this.optional = false,
    this.hint,
    this.choices = const [],
  });

  final String key;
  final String label;
  final String unit;
  final double? defaultValue;
  final bool optional;
  final String? hint;
  final List<FormulaChoice> choices;

  bool get isChoice => choices.isNotEmpty;
}

class FormulaOutput {
  const FormulaOutput({
    required this.key,
    required this.label,
    this.unit = '',
  });

  final String key;
  final String label;
  final String unit;
}

class FormulaResult {
  const FormulaResult(this.values, {this.messages = const []});

  final Map<String, double> values;
  final List<String> messages;
}

/// Thrown by a formula when the inputs cannot give a valid answer.
class FormulaException implements Exception {
  const FormulaException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef FormulaCompute = FormulaResult Function(Map<String, double> input);

/// One way of using a formula, such as "solve for voltage".
class FormulaMode {
  const FormulaMode({
    required this.label,
    required this.inputs,
    required this.outputs,
    required this.compute,
  });

  final String label;
  final List<FormulaInput> inputs;
  final List<FormulaOutput> outputs;
  final FormulaCompute compute;
}

class FormulaDef {
  const FormulaDef({
    required this.id,
    required this.title,
    required this.pack,
    required this.formula,
    required this.modes,
    this.summary = '',
    this.notes = const [],
  });

  final String id;
  final String title;
  final FormulaPack pack;
  final String formula;
  final String summary;
  final List<FormulaMode> modes;
  final List<String> notes;
}
