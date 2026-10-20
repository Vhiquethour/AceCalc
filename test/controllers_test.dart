import 'package:eng_calc/core/utils/decimal_parser.dart';
import 'package:eng_calc/core/utils/number_formatter.dart';
import 'package:eng_calc/data/units/static_unit_repository.dart';
import 'package:eng_calc/domain/formulas/formula_catalogue.dart';
import 'package:eng_calc/domain/repositories/settings_repository.dart';
import 'package:eng_calc/presentation/controllers/converter_controller.dart';
import 'package:eng_calc/presentation/controllers/formula_controller.dart';
import 'package:eng_calc/presentation/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings implements SettingsRepository {
  AppThemeMode stored = AppThemeMode.dark;

  @override
  Future<AppThemeMode> loadThemeMode() async => stored;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async => stored = mode;
}

void main() {
  group('number formatting and parsing', () {
    test('format', () {
      expect(NumberFormatter.format(1234.5678), '1234.57');
      expect(NumberFormatter.format(100), '100');
      expect(NumberFormatter.format(0), '0');
      expect(NumberFormatter.format(0.1 + 0.2), '0.3');
      expect(NumberFormatter.format(0.000123456), '0.000123456');
      expect(NumberFormatter.format(1e-5), '1e-5');
      expect(NumberFormatter.format(1.5e10), '1.5e10');
      expect(NumberFormatter.format(-2.5), '-2.5');
      expect(NumberFormatter.format(double.nan), '—');
    });

    test('parse', () {
      expect(DecimalParser.tryParse('1,5'), 1.5);
      expect(DecimalParser.tryParse(' 2 '), 2);
      expect(DecimalParser.tryParse('1e3'), 1000);
      expect(DecimalParser.tryParse('abc'), isNull);
      expect(DecimalParser.tryParse(''), isNull);
    });
  });

  group('ConverterController', () {
    final pressure = StaticUnitRepository().byId('pressure');

    test('converts and swaps', () {
      final controller = ConverterController(pressure);
      controller.setInput('2');
      expect(controller.result, closeTo(29.0075, 1e-3));
      controller.swap();
      expect(controller.from.id, 'psi');
      expect(controller.to.id, 'bar');
    });

    test('reports invalid input', () {
      final controller = ConverterController(pressure);
      controller.setInput('abc');
      expect(controller.message, isNotNull);
      expect(controller.result, isNull);
      controller.setInput('');
      expect(controller.message, isNull);
    });

    test('rejects temperatures below absolute zero', () {
      final controller = ConverterController(StaticUnitRepository().byId('temperature'));
      controller.setInput('-300');
      expect(controller.message, isNotNull);
      controller.setInput('-40');
      expect(controller.message, isNull);
    });

    test('lists every other unit', () {
      final controller = ConverterController(pressure);
      controller.setInput('1');
      expect(controller.allConversions.length, pressure.units.length - 1);
    });
  });

  group('FormulaController', () {
    test('moves from pending to success to error', () {
      final controller = FormulaController(FormulaCatalogue.byId('ohms_law'));
      expect(controller.outcome.status, OutcomeStatus.pending);
      controller.setText('i', '2');
      controller.setText('r', '6');
      expect(controller.outcome.status, OutcomeStatus.success);
      expect(controller.outcome.result!.values['v'], 12);
      controller.setText('r', 'abc');
      expect(controller.outcome.status, OutcomeStatus.error);
    });

    test('switching mode keeps shared inputs', () {
      final controller = FormulaController(FormulaCatalogue.byId('ohms_law'));
      controller.setText('r', '6');
      controller.selectMode(1);
      expect(controller.textFor('r'), '6');
      controller.setText('v', '12');
      expect(controller.outcome.result!.values['i'], closeTo(2, 1e-9));
    });

    test('defaults and choices are loaded', () {
      final controller = FormulaController(FormulaCatalogue.byId('three_phase_power'));
      expect(controller.textFor('v'), '400');
      final rates = FormulaController(FormulaCatalogue.byId('incident_rates'));
      expect(rates.choiceFor('k'), 200000);
    });

    test('optional inputs may stay empty', () {
      final controller = FormulaController(FormulaCatalogue.byId('synchronous_speed'));
      expect(controller.outcome.status, OutcomeStatus.success);
      expect(controller.outcome.result!.values.containsKey('slip'), isFalse);
    });

    test('validation errors become messages', () {
      final controller = FormulaController(FormulaCatalogue.byId('ohms_law'));
      controller.selectMode(1);
      controller.setText('v', '12');
      controller.setText('r', '0');
      expect(controller.outcome.status, OutcomeStatus.error);
      expect(controller.outcome.message, contains('Resistance'));
    });
  });

  group('ThemeController', () {
    test('defaults to dark and saves the choice', () async {
      final settings = _FakeSettings();
      final controller = ThemeController(settings);
      await controller.load();
      expect(controller.mode, ThemeMode.dark);
      await controller.select(AppThemeMode.light);
      expect(controller.mode, ThemeMode.light);
      expect(settings.stored, AppThemeMode.light);
      await controller.select(AppThemeMode.system);
      expect(controller.mode, ThemeMode.system);
    });
  });
}
