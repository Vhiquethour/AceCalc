import 'package:eng_calc/data/units/static_unit_repository.dart';
import 'package:eng_calc/domain/entities/unit_category.dart';
import 'package:eng_calc/domain/entities/unit_def.dart';
import 'package:eng_calc/domain/services/unit_converter.dart';
import 'package:flutter_test/flutter_test.dart';

UnitDef _unit(UnitCategory category, String id) =>
    category.units.firstWhere((u) => u.id == id);

double _convert(String category, String from, String to, double value) {
  final found = StaticUnitRepository().byId(category);
  return UnitConverter.convert(value, _unit(found, from), _unit(found, to));
}

void main() {
  group('known conversions', () {
    test('pressure', () {
      expect(_convert('pressure', 'bar', 'psi', 1), closeTo(14.5038, 1e-3));
      expect(_convert('pressure', 'atm', 'kpa', 1), closeTo(101.325, 1e-9));
    });

    test('temperature', () {
      expect(_convert('temperature', 'c', 'f', 0), closeTo(32, 1e-9));
      expect(_convert('temperature', 'c', 'f', 100), closeTo(212, 1e-9));
      expect(_convert('temperature', 'f', 'c', -40), closeTo(-40, 1e-9));
      expect(_convert('temperature', 'k', 'c', 0), closeTo(-273.15, 1e-9));
      expect(_convert('temperature', 'c', 'r', 0), closeTo(491.67, 1e-9));
    });

    test('volume', () {
      expect(_convert('volume', 'bbl', 'l', 1), closeTo(158.987, 1e-3));
      expect(_convert('volume', 'bbl', 'galus', 1), closeTo(42, 1e-6));
      expect(_convert('volume', 'galus', 'l', 1), closeTo(3.785411784, 1e-9));
    });

    test('energy and power', () {
      expect(_convert('energy', 'kwh', 'btu', 1), closeTo(3412.14, 0.01));
      expect(_convert('power', 'hp', 'w', 1), closeTo(745.7, 0.01));
      expect(_convert('power', 'tr', 'btuh', 1), closeTo(12000, 0.5));
    });

    test('length, flow and rotation', () {
      expect(_convert('length', 'mi', 'm', 1), closeTo(1609.344, 1e-9));
      expect(_convert('flow', 'm3h', 'gpm', 1), closeTo(4.40287, 1e-3));
      expect(_convert('rotation', 'rpm', 'rads', 60), closeTo(6.283185, 1e-5));
    });

    test('wire size and API gravity', () {
      expect(_convert('wire', 'awg', 'mm2', 10), closeTo(5.26, 0.01));
      expect(_convert('wire', 'mm2', 'awg', 5.261155), closeTo(10, 1e-3));
      expect(_convert('density', 'api', 'sg', 10), closeTo(1.0, 1e-9));
    });

    test('concentration', () {
      expect(_convert('concentration', 'pct', 'ppm', 1), closeTo(10000, 1e-9));
    });
  });

  group('round trips', () {
    test('every unit returns to its starting value', () {
      for (final category in StaticUnitRepository().categories) {
        for (final from in category.units) {
          for (final to in category.units) {
            const start = 12.34;
            final there = UnitConverter.convert(start, from, to);
            final back = UnitConverter.convert(there, to, from);
            expect(
              back,
              closeTo(start, 1e-9),
              reason: '${category.id}: ${from.id} to ${to.id}',
            );
          }
        }
      }
    });
  });

  group('catalogue integrity', () {
    final repository = StaticUnitRepository();

    test('category ids are unique', () {
      final ids = repository.categories.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('unit ids are unique inside each category', () {
      for (final category in repository.categories) {
        final ids = category.units.map((u) => u.id).toList();
        expect(ids.toSet().length, ids.length, reason: category.id);
      }
    });

    test('default indexes are valid and groups are known', () {
      for (final category in repository.categories) {
        expect(category.defaultFromIndex, lessThan(category.units.length));
        expect(category.defaultToIndex, lessThan(category.units.length));
        expect(category.units.length, greaterThanOrEqualTo(2));
        expect(repository.groups, contains(category.group), reason: category.id);
      }
    });

    test('linear units have positive factors', () {
      for (final category in repository.categories) {
        for (final unit in category.units) {
          if (unit.isLinear) {
            expect(unit.factor, greaterThan(0), reason: '${category.id}/${unit.id}');
          }
        }
      }
    });
  });
}
