import 'package:flutter/foundation.dart';

import '../../core/utils/decimal_parser.dart';
import '../../core/utils/number_formatter.dart';
import '../../domain/entities/formula_def.dart';

enum OutcomeStatus { pending, error, success }

class FormulaOutcome {
  const FormulaOutcome._(this.status, {this.result, this.message});

  const FormulaOutcome.pending() : this._(OutcomeStatus.pending);

  const FormulaOutcome.error(String message)
      : this._(OutcomeStatus.error, message: message);

  const FormulaOutcome.success(FormulaResult result)
      : this._(OutcomeStatus.success, result: result);

  final OutcomeStatus status;
  final FormulaResult? result;
  final String? message;
}

class FormulaController extends ChangeNotifier {
  FormulaController(this.formula) {
    for (final mode in formula.modes) {
      for (final input in mode.inputs) {
        if (input.isChoice) {
          _choices.putIfAbsent(
            input.key,
            () => input.defaultValue ?? input.choices.first.value,
          );
        } else {
          final defaultValue = input.defaultValue;
          _texts.putIfAbsent(
            input.key,
            () => defaultValue == null
                ? ''
                : NumberFormatter.format(defaultValue, sigFigs: 8),
          );
        }
      }
    }
  }

  final FormulaDef formula;
  final Map<String, String> _texts = {};
  final Map<String, double> _choices = {};
  int _modeIndex = 0;

  int get modeIndex => _modeIndex;
  FormulaMode get mode => formula.modes[_modeIndex];

  String textFor(String key) => _texts[key] ?? '';

  double choiceFor(String key) => _choices[key] ?? 0;

  void selectMode(int index) {
    if (index == _modeIndex) return;
    _modeIndex = index;
    notifyListeners();
  }

  void setText(String key, String text) {
    _texts[key] = text;
    notifyListeners();
  }

  void setChoice(String key, double value) {
    _choices[key] = value;
    notifyListeners();
  }

  FormulaOutcome get outcome {
    final values = <String, double>{};
    for (final input in mode.inputs) {
      if (input.isChoice) {
        values[input.key] = choiceFor(input.key);
        continue;
      }
      final text = textFor(input.key);
      if (text.trim().isEmpty) {
        if (input.optional) continue;
        return const FormulaOutcome.pending();
      }
      final parsed = DecimalParser.tryParse(text);
      if (parsed == null) {
        return FormulaOutcome.error('Enter a valid number for "${input.label}".');
      }
      values[input.key] = parsed;
    }

    try {
      final result = mode.compute(values);
      for (final value in result.values.values) {
        if (value.isNaN || value.isInfinite) {
          return const FormulaOutcome.error(
            'The result is not a finite number. Check the inputs.',
          );
        }
      }
      return FormulaOutcome.success(result);
    } on FormulaException catch (error) {
      return FormulaOutcome.error(error.message);
    } catch (_) {
      return const FormulaOutcome.error('These values could not be calculated.');
    }
  }
}
