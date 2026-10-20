import 'package:eng_calc/domain/entities/formula_def.dart';
import 'package:eng_calc/domain/formulas/formula_catalogue.dart';
import 'package:eng_calc/domain/formulas/standard_values.dart';
import 'package:flutter_test/flutter_test.dart';

FormulaResult _run(String id, int mode, Map<String, double> input) {
  return FormulaCatalogue.byId(id).modes[mode].compute(input);
}

double _value(FormulaResult result, String key) {
  final value = result.values[key];
  expect(value, isNotNull, reason: 'missing output "$key"');
  return value!;
}

Map<String, double> _defaults(FormulaMode mode, {required bool optional}) {
  final values = <String, double>{};
  for (final input in mode.inputs) {
    if (input.isChoice) {
      values[input.key] = input.defaultValue ?? input.choices.first.value;
    } else if (!input.optional || optional) {
      values[input.key] = input.defaultValue ?? 2.0;
    }
  }
  return values;
}

void main() {
  group('catalogue integrity', () {
    test('formula ids are unique and every formula has a mode', () {
      final ids = FormulaCatalogue.all.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final formula in FormulaCatalogue.all) {
        expect(formula.modes, isNotEmpty, reason: formula.id);
        expect(formula.title, isNotEmpty, reason: formula.id);
      }
    });

    test('every pack has formulas', () {
      for (final pack in FormulaPack.values) {
        expect(FormulaCatalogue.inPack(pack), isNotEmpty, reason: pack.name);
      }
    });

    test('input keys are unique inside each mode', () {
      for (final formula in FormulaCatalogue.all) {
        for (final mode in formula.modes) {
          final keys = mode.inputs.map((i) => i.key).toList();
          expect(keys.toSet().length, keys.length, reason: '${formula.id}/${mode.label}');
        }
      }
    });

    test('compute only throws FormulaException and returns declared outputs', () {
      for (final formula in FormulaCatalogue.all) {
        for (final mode in formula.modes) {
          final declared = mode.outputs.map((o) => o.key).toSet();
          for (final optional in [false, true]) {
            try {
              final result = mode.compute(_defaults(mode, optional: optional));
              for (final key in result.values.keys) {
                expect(
                  declared,
                  contains(key),
                  reason: '${formula.id}/${mode.label} returned undeclared "$key"',
                );
              }
            } on FormulaException {
              // A clear validation message is acceptable.
            }
          }
        }
      }
    });
  });

  group('electrical', () {
    test("Ohm's law", () {
      final volts = _run('ohms_law', 0, {'i': 2, 'r': 6});
      expect(_value(volts, 'v'), closeTo(12, 1e-9));
      expect(_value(volts, 'p'), closeTo(24, 1e-9));
      expect(_value(_run('ohms_law', 1, {'v': 12, 'r': 6}), 'i'), closeTo(2, 1e-9));
      expect(_value(_run('ohms_law', 2, {'v': 12, 'i': 2}), 'r'), closeTo(6, 1e-9));
    });

    test('three-phase power', () {
      final result = _run('three_phase_power', 0, {'v': 400, 'i': 10, 'pf': 0.8});
      expect(_value(result, 'p'), closeTo(5.5426, 1e-3));
      expect(_value(result, 's'), closeTo(6.9282, 1e-3));
    });

    test('series and parallel', () {
      expect(_value(_run('resistors', 0, {'r1': 100, 'r2': 200, 'r3': 300}), 'r'), closeTo(600, 1e-9));
      expect(_value(_run('resistors', 1, {'r1': 100, 'r2': 100}), 'r'), closeTo(50, 1e-9));
      expect(_value(_run('capacitors', 0, {'c1': 10, 'c2': 10}), 'c'), closeTo(20, 1e-9));
      expect(_value(_run('capacitors', 1, {'c1': 10, 'c2': 10}), 'c'), closeTo(5, 1e-9));
    });

    test('cable voltage drop', () {
      final result = _run('cable_voltage_drop', 0, {
        'i': 10, 'l': 50, 'a': 2.5, 'rho': 0.0175, 'vs1': 230,
      });
      expect(_value(result, 'vd'), closeTo(7.0, 1e-9));
      expect(_value(result, 'pct'), closeTo(3.0435, 1e-3));
    });

    test('divider, reactance and RC', () {
      expect(_value(_run('voltage_divider', 0, {'vin': 10, 'r1': 10, 'r2': 10}), 'vout'), closeTo(5, 1e-9));
      expect(_value(_run('reactance_resonance', 0, {'f': 50, 'c': 100}), 'xc'), closeTo(31.83, 0.01));
      expect(_value(_run('reactance_resonance', 2, {'l': 10, 'c': 10}), 'f0'), closeTo(503.29, 0.01));
      expect(_value(_run('rc_time_constant', 0, {'r': 1000, 'c': 10}), 'tau'), closeTo(10, 1e-9));
    });

    test('battery and energy', () {
      final runtime = _run('battery_runtime', 0, {
        'ah': 100, 'v': 12, 'dod': 80, 'eff': 90, 'load': 100,
      });
      expect(_value(runtime, 'h'), closeTo(8.64, 1e-9));
      final charge = _run('battery_charge_time', 0, {
        'ah': 100, 'i': 10, 'eff': 85, 'need': 100,
      });
      expect(_value(charge, 'h'), closeTo(11.7647, 1e-3));
      expect(_value(charge, 'c'), closeTo(0.1, 1e-9));
      final cost = _run('energy_cost', 0, {'kw': 2, 'hours': 8, 'days': 30, 'tariff': 50});
      expect(_value(cost, 'kwh'), closeTo(480, 1e-9));
      expect(_value(cost, 'cost'), closeTo(24000, 1e-9));
    });

    test('invalid input gives a clear exception', () {
      expect(() => _run('ohms_law', 1, {'v': 12, 'r': 0}), throwsA(isA<FormulaException>()));
      expect(
        () => _run('three_phase_power', 0, {'v': 400, 'i': 10, 'pf': 1.5}),
        throwsA(isA<FormulaException>()),
      );
    });
  });

  group('mechanical', () {
    test('torque, power and speed', () {
      expect(_value(_run('torque_power', 0, {'t': 100, 'n': 1500}), 'p'), closeTo(15.708, 1e-3));
      expect(_value(_run('torque_power', 1, {'p': 15.70796, 'n': 1500}), 't'), closeTo(100, 0.01));
    });

    test('motor speed, stress, gears, expansion and heat', () {
      final motor = _run('synchronous_speed', 0, {'f': 50, 'poles': 4, 'n': 1450});
      expect(_value(motor, 'ns'), closeTo(1500, 1e-9));
      expect(_value(motor, 'slip'), closeTo(3.3333, 1e-3));
      final stress = _run('stress_safety_factor', 0, {'f': 10000, 'a': 100, 'yield': 250});
      expect(_value(stress, 'sigma'), closeTo(100, 1e-9));
      expect(_value(stress, 'fos'), closeTo(2.5, 1e-9));
      final gear = _run('gear_pulley_ratio', 0, {'driver': 20, 'driven': 40, 'rpm': 1000});
      expect(_value(gear, 'ratio'), closeTo(2, 1e-9));
      expect(_value(gear, 'out'), closeTo(500, 1e-9));
      expect(_value(_run('thermal_expansion', 0, {'alpha': 12, 'l': 10, 'dt': 50}), 'dl'), closeTo(6, 1e-9));
      expect(_value(_run('sensible_heat', 0, {'m': 100, 'c': 4.186, 'dt': 10}), 'q'), closeTo(4186, 1e-6));
    });
  });

  group('fluids', () {
    test('pressure', () {
      final result = _run('hydrostatic_pressure', 0, {'rho': 1000, 'h': 10, 'g': 9.80665});
      expect(_value(result, 'kpa'), closeTo(98.0665, 1e-6));
      expect(_value(result, 'psi'), closeTo(14.2233, 1e-3));
      expect(_value(_run('drilling_hydrostatic', 0, {'mw': 10, 'tvd': 10000}), 'psi'), closeTo(5200, 1e-9));
      expect(_value(_run('drilling_hydrostatic', 1, {'psi': 5200, 'tvd': 10000}), 'mw'), closeTo(10, 1e-9));
    });

    test('flow, Reynolds, friction, head loss and pump', () {
      expect(_value(_run('flow_velocity', 0, {'q': 36, 'd': 100}), 'v'), closeTo(1.2732, 1e-3));
      final reynolds = _run('reynolds_number', 0, {'rho': 1000, 'v': 1, 'd': 100, 'mu': 1});
      expect(_value(reynolds, 're'), closeTo(100000, 1e-6));
      expect(reynolds.messages.first, contains('Turbulent'));
      expect(_value(_run('friction_factor', 0, {'re': 1e5, 'eps': 0.045, 'd': 100}), 'f'), closeTo(0.02020, 1e-4));
      expect(_value(_run('friction_factor', 0, {'re': 1000, 'eps': 0.045, 'd': 100}), 'f'), closeTo(0.064, 1e-9));
      expect(
        _value(_run('head_loss', 0, {'f': 0.02, 'l': 100, 'd': 100, 'v': 2, 'rho': 1000}), 'hf'),
        closeTo(4.0789, 1e-3),
      );
      final pump = _run('pump_power', 0, {'rho': 1000, 'q': 36, 'h': 20, 'eta': 65});
      expect(_value(pump, 'hyd'), closeTo(1.9613, 1e-3));
      expect(_value(pump, 'shaft'), closeTo(3.0174, 1e-3));
    });

    test('API gravity, tanks and gas', () {
      expect(_value(_run('api_gravity', 0, {'sg': 1}), 'api'), closeTo(10, 1e-9));
      expect(_value(_run('api_gravity', 1, {'api': 10}), 'sg'), closeTo(1, 1e-9));
      final half = _run('tank_volume', 1, {'d': 2, 'len': 5, 'fill': 1});
      expect(_value(half, 'm3'), closeTo(7.854, 1e-3));
      expect(_value(half, 'pct'), closeTo(50, 1e-6));
      final full = _run('tank_volume', 1, {'d': 2, 'len': 5, 'fill': 2});
      expect(_value(full, 'pct'), closeTo(100, 1e-6));
      expect(_value(_run('tank_volume', 0, {'d': 2, 'level': 3}), 'm3'), closeTo(9.4248, 1e-3));
      expect(
        _value(_run('gas_law', 0, {'p1': 200, 'v1': 1, 't1': 25, 'p2': 100, 't2': 25}), 'v2'),
        closeTo(2, 1e-9),
      );
      expect(
        _value(_run('gas_law', 1, {'p': 101.325, 'vol': 0.024465403697, 't': 25}), 'n'),
        closeTo(1, 1e-6),
      );
      expect(_value(_run('hvac_sensible', 0, {'cfm': 1000, 'dt': 20}), 'btuh'), closeTo(21600, 1e-6));
      expect(_value(_run('pipe_volume', 0, {'d': 100, 'l': 10}), 'm3'), closeTo(0.07854, 1e-5));
    });
  });

  group('health and safety', () {
    test('incident rates and hours', () {
      final rates = _run('incident_rates', 0, {
        'rec': 2, 'lti': 1, 'hours': 1000000, 'k': 200000,
      });
      expect(_value(rates, 'trir'), closeTo(0.4, 1e-9));
      expect(_value(rates, 'ltifr'), closeTo(0.2, 1e-9));
      expect(_value(_run('hours_worked', 0, {'people': 10, 'hrs': 8, 'days': 20}), 'hours'), closeTo(1600, 1e-9));
    });

    test('noise', () {
      expect(_value(_run('noise_combine', 0, {'l1': 90, 'l2': 90}), 'l'), closeTo(93.01, 0.01));
      expect(_value(_run('noise_permitted_time', 0, {'l': 88, 'std': 1}), 't'), closeTo(4, 1e-9));
      expect(_value(_run('noise_permitted_time', 0, {'l': 95, 'std': 2}), 't'), closeTo(4, 1e-9));
      final single = _run('noise_dose', 0, {'l1': 90, 'h1': 8, 'std': 2});
      expect(_value(single, 'dose'), closeTo(100, 1e-6));
      expect(_value(single, 'twa'), closeTo(90, 1e-6));
      final mixed = _run('noise_dose', 0, {'l1': 95, 'h1': 4, 'l2': 90, 'h2': 4, 'std': 2});
      expect(_value(mixed, 'dose'), closeTo(150, 1e-6));
      expect(_value(_run('noise_distance', 0, {'l1': 90, 'r1': 1, 'r2': 2}), 'l2'), closeTo(83.98, 0.01));
      expect(_value(_run('hearing_protection', 0, {'twa': 95, 'nrr': 27}), 'prot'), closeTo(85, 1e-9));
    });

    test('gas, exposure and ventilation', () {
      final mg = _run('gas_ppm_mg', 0, {'ppm': 10, 'mm': 28.01, 't': 25, 'p': 101.325});
      expect(_value(mg, 'mg'), closeTo(11.4488, 1e-3));
      expect(_value(mg, 'vm'), closeTo(24.4654, 1e-3));
      expect(_value(_run('gas_ppm_mg', 1, {'mg': 11.4488, 'mm': 28.01, 't': 25, 'p': 101.325}), 'ppm'), closeTo(10, 1e-3));
      expect(_value(_run('twa_exposure', 0, {'c1': 100, 't1': 4}), 'twa'), closeTo(50, 1e-9));
      final mixture = _run('mixture_index', 0, {'c1': 50, 'lim1': 100, 'c2': 30, 'lim2': 60});
      expect(_value(mixture, 'index'), closeTo(1.0, 1e-9));
      final rooms = _run('ventilation_ach', 0, {'len': 5, 'wid': 4, 'hgt': 3, 'q': 600});
      expect(_value(rooms, 'ach'), closeTo(10, 1e-9));
      expect(_value(_run('ventilation_ach', 1, {'len': 5, 'wid': 4, 'hgt': 3, 'ach': 6}), 'q'), closeTo(360, 1e-9));
    });

    test('heat stress and risk', () {
      expect(_value(_run('wbgt', 0, {'tnwb': 25, 'tg': 40, 'tdb': 30, 'loc': 1}), 'wbgt'), closeTo(28.5, 1e-9));
      expect(_value(_run('wbgt', 0, {'tnwb': 25, 'tg': 40, 'tdb': 30, 'loc': 2}), 'wbgt'), closeTo(29.5, 1e-9));
      final limited = _run('wbgt', 0, {'tnwb': 25, 'tg': 40, 'tdb': 30, 'loc': 1, 'limit': 26});
      expect(limited.messages, isNotEmpty);
      final risk = _run('risk_matrix', 0, {
        'l': 3, 's': 4, 'medium': 5, 'high': 10, 'extreme': 17,
      });
      expect(_value(risk, 'score'), closeTo(12, 1e-9));
      expect(risk.messages.first, contains('High'));
      expect(
        () => _run('risk_matrix', 0, {'l': 3, 's': 4, 'medium': 10, 'high': 5, 'extreme': 17}),
        throwsA(isA<FormulaException>()),
      );
    });

    test('lifting, access and confined space', () {
      final sling = _run('sling_angle', 0, {'load': 1000, 'legs': 2, 'angle': 60});
      expect(_value(sling, 'tension'), closeTo(577.35, 0.01));
      expect(_value(sling, 'factor'), closeTo(1.1547, 1e-3));
      final shallow = _run('sling_angle', 0, {'load': 1000, 'legs': 2, 'angle': 30});
      expect(shallow.messages, isNotEmpty);
      expect(
        _value(_run('fall_clearance', 0, {'lanyard': 2, 'decel': 1, 'attach': 1.5, 'margin': 1}), 'total'),
        closeTo(5.5, 1e-9),
      );
      final ladder = _run('ladder_angle', 0, {'h': 4});
      expect(_value(ladder, 'rec'), closeTo(1, 1e-9));
      expect(_value(ladder, 'length'), closeTo(4.1231, 1e-3));
      expect(_value(ladder, 'angle'), closeTo(75.96, 0.01));
      expect(_value(_run('lel_percent', 0, {'c': 2.5, 'lel': 5}), 'pct'), closeTo(50, 1e-9));
      expect(_value(_run('lel_percent', 1, {'ppm': 25000, 'lel': 5}), 'pct'), closeTo(50, 1e-9));
      final purge = _run('purge_time', 0, {'vol': 100, 'q': 500, 'c0': 100, 'c': 1, 'k': 1});
      expect(_value(purge, 'h'), closeTo(0.92103, 1e-4));
      final lift = _run('niosh_lifting', 0, {
        'h': 25, 'v': 75, 'd': 25, 'a': 0, 'fm': 1, 'cmult': 1, 'load': 10,
      });
      expect(_value(lift, 'rwl'), closeTo(23, 1e-9));
      expect(_value(lift, 'li'), closeTo(0.4348, 1e-3));
    });
  });

  group('solar and embedded', () {
    test('sizing', () {
      final array = _run('solar_array_size', 0, {'wh': 5000, 'psh': 5, 'eff': 75, 'panel': 400});
      expect(_value(array, 'w'), closeTo(1333.33, 0.01));
      expect(_value(array, 'n'), closeTo(4, 1e-9));
      final bank = _run('battery_bank_size', 0, {'wh': 5000, 'days': 1, 'dod': 80, 'eff': 90, 'vs': 24});
      expect(_value(bank, 'ah'), closeTo(289.35, 0.01));
    });

    test('LED resistor, ADC and PWM', () {
      final led = _run('led_resistor', 0, {'vs': 5, 'vf': 2, 'i': 10});
      expect(_value(led, 'r'), closeTo(300, 1e-9));
      expect(_value(led, 'std'), closeTo(330, 1e-9));
      expect(_value(led, 'p'), closeTo(30, 1e-9));
      expect(_value(_run('adc_voltage', 0, {'reading': 2048, 'bits': 12, 'vref': 3.3}), 'v'), closeTo(1.6504, 1e-3));
      final pwm = _run('pwm_average', 0, {'duty': 25, 'vhigh': 3.3, 'freq': 1000});
      expect(_value(pwm, 'vavg'), closeTo(0.825, 1e-9));
      expect(_value(pwm, 'on'), closeTo(250, 1e-9));
      expect(_value(pwm, 'period'), closeTo(1000, 1e-9));
    });

    test('E12 series', () {
      expect(StandardValues.nextE12(300), closeTo(330, 1e-9));
      expect(StandardValues.nextE12(330), closeTo(330, 1e-9));
      expect(StandardValues.nextE12(1001), closeTo(1200, 1e-9));
      expect(StandardValues.nextE12(95), closeTo(100, 1e-9));
      expect(StandardValues.nextE12(0.5), closeTo(0.56, 1e-9));
    });
  });

  group('general', () {
    test('geometry', () {
      final circle = _run('circle', 0, {'d': 10});
      expect(_value(circle, 'a'), closeTo(78.5398, 1e-3));
      expect(_value(circle, 'c'), closeTo(31.4159, 1e-3));
      expect(_value(_run('cylinder', 0, {'d': 2, 'h': 5}), 'vol'), closeTo(15.708, 1e-3));
      expect(_value(_run('sphere', 0, {'d': 2}), 'vol'), closeTo(4.18879, 1e-4));
      final box = _run('box', 0, {'l': 2, 'w': 3, 'h': 4});
      expect(_value(box, 'vol'), closeTo(24, 1e-9));
      expect(_value(box, 'area'), closeTo(52, 1e-9));
      final cone = _run('cone', 0, {'d': 6, 'h': 4});
      expect(_value(cone, 'slant'), closeTo(5, 1e-9));
      expect(_value(cone, 'vol'), closeTo(37.699, 1e-3));
    });

    test('percentages, triangles and payback', () {
      expect(_value(_run('percentage_change', 0, {'old': 80, 'new': 100}), 'pct'), closeTo(25, 1e-9));
      expect(_value(_run('percentage_change', 1, {'value': 200, 'pct': 10}), 'result'), closeTo(220, 1e-9));
      expect(_value(_run('pythagoras', 0, {'a': 3, 'b': 4}), 'c'), closeTo(5, 1e-9));
      expect(_value(_run('pythagoras', 1, {'c': 5, 'a': 3}), 'b'), closeTo(4, 1e-9));
      final payback = _run('simple_payback', 0, {'cost': 1000, 'saving': 250});
      expect(_value(payback, 'years'), closeTo(4, 1e-9));
      expect(_value(payback, 'months'), closeTo(48, 1e-9));
      expect(_value(payback, 'roi'), closeTo(25, 1e-9));
    });
  });
}
