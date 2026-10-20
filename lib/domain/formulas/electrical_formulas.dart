import 'dart:math' as math;

import '../entities/formula_def.dart';
import 'formula_helpers.dart';

List<FormulaInput> _resistorInputs() => [
      numIn('r1', 'Resistor 1', 'Ω'),
      numIn('r2', 'Resistor 2', 'Ω'),
      numIn('r3', 'Resistor 3', 'Ω', optional: true),
      numIn('r4', 'Resistor 4', 'Ω', optional: true),
    ];

List<FormulaInput> _capacitorInputs() => [
      numIn('c1', 'Capacitor 1', 'µF'),
      numIn('c2', 'Capacitor 2', 'µF'),
      numIn('c3', 'Capacitor 3', 'µF', optional: true),
      numIn('c4', 'Capacitor 4', 'µF', optional: true),
    ];

List<FormulaInput> _cableInputs(String supplyKey, double supply) => [
      numIn('i', 'Load current', 'A'),
      numIn('l', 'Cable length (one way)', 'm'),
      numIn('a', 'Conductor area', 'mm²'),
      numIn('rho', 'Resistivity', 'Ω·mm²/m', def: 0.0175),
      numIn(supplyKey, 'Supply voltage', 'V', def: supply),
    ];

FormulaResult _cableDrop(Map<String, double> v, double factor, String supplyKey) {
  final current = v['i']!;
  final length = v['l']!;
  final area = v['a']!;
  final rho = v['rho']!;
  final supply = v[supplyKey]!;
  requireNonNegative(current, 'Current');
  requireNonNegative(length, 'Length');
  requirePositive(area, 'Conductor area');
  requirePositive(rho, 'Resistivity');
  requirePositive(supply, 'Supply voltage');
  final drop = factor * current * length * rho / area;
  return res({
    'vd': drop,
    'pct': drop / supply * 100,
    'vend': supply - drop,
  });
}

final List<FormulaDef> electricalFormulas = [
  FormulaDef(
    id: 'ohms_law',
    title: "Ohm's law and power",
    pack: FormulaPack.electrical,
    formula: 'V = I × R      P = V × I',
    summary: 'Solve for voltage, current or resistance. Power is shown too.',
    modes: [
      FormulaMode(
        label: 'Voltage',
        inputs: [numIn('i', 'Current', 'A'), numIn('r', 'Resistance', 'Ω')],
        outputs: [numOut('v', 'Voltage', 'V'), numOut('p', 'Power', 'W')],
        compute: (v) {
          final volts = v['i']! * v['r']!;
          return res({'v': volts, 'p': volts * v['i']!});
        },
      ),
      FormulaMode(
        label: 'Current',
        inputs: [numIn('v', 'Voltage', 'V'), numIn('r', 'Resistance', 'Ω')],
        outputs: [numOut('i', 'Current', 'A'), numOut('p', 'Power', 'W')],
        compute: (v) {
          requirePositive(v['r']!, 'Resistance');
          final amps = v['v']! / v['r']!;
          return res({'i': amps, 'p': v['v']! * amps});
        },
      ),
      FormulaMode(
        label: 'Resistance',
        inputs: [numIn('v', 'Voltage', 'V'), numIn('i', 'Current', 'A')],
        outputs: [numOut('r', 'Resistance', 'Ω'), numOut('p', 'Power', 'W')],
        compute: (v) {
          if (v['i']! == 0) throw const FormulaException('Current cannot be zero.');
          return res({'r': v['v']! / v['i']!, 'p': v['v']! * v['i']!});
        },
      ),
    ],
    notes: [
      'Power can also be written P = I² × R or P = V² / R.',
      'Valid for DC circuits and for AC circuits with a purely resistive load.',
    ],
  ),
  FormulaDef(
    id: 'three_phase_power',
    title: 'Three-phase power',
    pack: FormulaPack.electrical,
    formula: 'P = √3 × V × I × cos φ',
    summary: 'Real, apparent and reactive power for a balanced load.',
    modes: [
      FormulaMode(
        label: 'Power',
        inputs: [
          numIn('v', 'Line-to-line voltage', 'V', def: 400),
          numIn('i', 'Line current', 'A'),
          numIn('pf', 'Power factor (cos φ)', '', def: 0.85),
        ],
        outputs: [
          numOut('p', 'Real power', 'kW'),
          numOut('s', 'Apparent power', 'kVA'),
          numOut('q', 'Reactive power', 'kvar'),
        ],
        compute: (v) {
          requirePositive(v['v']!, 'Voltage');
          requireNonNegative(v['i']!, 'Current');
          requireRange(v['pf']!, 'Power factor', 0, 1);
          final s = math.sqrt(3) * v['v']! * v['i']! / 1000;
          final p = s * v['pf']!;
          final q = math.sqrt(math.max(0, s * s - p * p));
          return res({'p': p, 's': s, 'q': q});
        },
      ),
      FormulaMode(
        label: 'Current',
        inputs: [
          numIn('p', 'Real power', 'kW'),
          numIn('v', 'Line-to-line voltage', 'V', def: 400),
          numIn('pf', 'Power factor (cos φ)', '', def: 0.85),
        ],
        outputs: [numOut('i', 'Line current', 'A'), numOut('s', 'Apparent power', 'kVA')],
        compute: (v) {
          requireNonNegative(v['p']!, 'Power');
          requirePositive(v['v']!, 'Voltage');
          if (!(v['pf']! > 0 && v['pf']! <= 1)) {
            throw const FormulaException('Power factor must be above 0 and at most 1.');
          }
          final amps = v['p']! * 1000 / (math.sqrt(3) * v['v']! * v['pf']!);
          return res({'i': amps, 's': v['p']! / v['pf']!});
        },
      ),
    ],
    notes: ['Assumes a balanced three-phase load. V is the line-to-line voltage.'],
  ),
  FormulaDef(
    id: 'single_phase_power',
    title: 'Single-phase AC power',
    pack: FormulaPack.electrical,
    formula: 'P = V × I × cos φ',
    summary: 'Real, apparent and reactive power for a single-phase load.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('v', 'Voltage', 'V', def: 230),
          numIn('i', 'Current', 'A'),
          numIn('pf', 'Power factor (cos φ)', '', def: 0.9),
        ],
        outputs: [
          numOut('p', 'Real power', 'W'),
          numOut('s', 'Apparent power', 'VA'),
          numOut('q', 'Reactive power', 'var'),
        ],
        compute: (v) {
          requirePositive(v['v']!, 'Voltage');
          requireNonNegative(v['i']!, 'Current');
          requireRange(v['pf']!, 'Power factor', 0, 1);
          final s = v['v']! * v['i']!;
          final p = s * v['pf']!;
          return res({'p': p, 's': s, 'q': math.sqrt(math.max(0, s * s - p * p))});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'resistors',
    title: 'Resistors in series and parallel',
    pack: FormulaPack.electrical,
    formula: 'Series: R = R1 + R2 + …      Parallel: 1/R = 1/R1 + 1/R2 + …',
    summary: 'Combine two to four resistors.',
    modes: [
      FormulaMode(
        label: 'Series',
        inputs: _resistorInputs(),
        outputs: [numOut('r', 'Total resistance', 'Ω')],
        compute: (v) {
          final values = present(v, ['r1', 'r2', 'r3', 'r4']);
          for (final x in values) {
            requireNonNegative(x, 'Resistance');
          }
          return res({'r': values.fold(0.0, (sum, x) => sum + x)});
        },
      ),
      FormulaMode(
        label: 'Parallel',
        inputs: _resistorInputs(),
        outputs: [numOut('r', 'Total resistance', 'Ω')],
        compute: (v) {
          final values = present(v, ['r1', 'r2', 'r3', 'r4']);
          for (final x in values) {
            requirePositive(x, 'Resistance');
          }
          return res({'r': 1 / values.fold(0.0, (sum, x) => sum + 1 / x)});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'capacitors',
    title: 'Capacitors in series and parallel',
    pack: FormulaPack.electrical,
    formula: 'Parallel: C = C1 + C2 + …      Series: 1/C = 1/C1 + 1/C2 + …',
    summary: 'Combine two to four capacitors.',
    modes: [
      FormulaMode(
        label: 'Parallel',
        inputs: _capacitorInputs(),
        outputs: [numOut('c', 'Total capacitance', 'µF')],
        compute: (v) {
          final values = present(v, ['c1', 'c2', 'c3', 'c4']);
          for (final x in values) {
            requireNonNegative(x, 'Capacitance');
          }
          return res({'c': values.fold(0.0, (sum, x) => sum + x)});
        },
      ),
      FormulaMode(
        label: 'Series',
        inputs: _capacitorInputs(),
        outputs: [numOut('c', 'Total capacitance', 'µF')],
        compute: (v) {
          final values = present(v, ['c1', 'c2', 'c3', 'c4']);
          for (final x in values) {
            requirePositive(x, 'Capacitance');
          }
          return res({'c': 1 / values.fold(0.0, (sum, x) => sum + 1 / x)});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'cable_voltage_drop',
    title: 'Cable voltage drop',
    pack: FormulaPack.electrical,
    formula: 'Vd = k × I × L × ρ / A      k = 2 (single-phase, DC), √3 (three-phase)',
    summary: 'Resistive voltage drop along a cable.',
    modes: [
      FormulaMode(
        label: 'Single-phase or DC',
        inputs: _cableInputs('vs1', 230),
        outputs: [
          numOut('vd', 'Voltage drop', 'V'),
          numOut('pct', 'Drop as share of supply', '%'),
          numOut('vend', 'Voltage at the load', 'V'),
        ],
        compute: (v) => _cableDrop(v, 2, 'vs1'),
      ),
      FormulaMode(
        label: 'Three-phase',
        inputs: _cableInputs('vs3', 400),
        outputs: [
          numOut('vd', 'Voltage drop', 'V'),
          numOut('pct', 'Drop as share of supply', '%'),
          numOut('vend', 'Voltage at the load', 'V'),
        ],
        compute: (v) => _cableDrop(v, math.sqrt(3), 'vs3'),
      ),
    ],
    notes: [
      'Resistive drop only. Reactance is ignored, which matters for large conductors.',
      'Copper is about 0.0172 Ω·mm²/m at 20 °C and aluminium about 0.0282. Hot conductors have higher resistivity.',
      'Compare the result with the limit in your wiring rules.',
    ],
  ),
  FormulaDef(
    id: 'voltage_divider',
    title: 'Voltage divider',
    pack: FormulaPack.electrical,
    formula: 'Vout = Vin × R2 / (R1 + R2)',
    summary: 'Output voltage of two resistors, such as a sensor scaling circuit.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('vin', 'Input voltage', 'V'),
          numIn('r1', 'R1 (top)', 'kΩ'),
          numIn('r2', 'R2 (bottom)', 'kΩ'),
        ],
        outputs: [numOut('vout', 'Output voltage', 'V'), numOut('i', 'Divider current', 'mA')],
        compute: (v) {
          requireNonNegative(v['r1']!, 'R1');
          requireNonNegative(v['r2']!, 'R2');
          final total = v['r1']! + v['r2']!;
          requirePositive(total, 'The total resistance');
          return res({'vout': v['vin']! * v['r2']! / total, 'i': v['vin']! / total});
        },
      ),
    ],
    notes: ['Assumes no load on the output. A connected load changes the result.'],
  ),
  FormulaDef(
    id: 'reactance_resonance',
    title: 'Reactance and resonance',
    pack: FormulaPack.electrical,
    formula: 'Xc = 1 / (2πfC)    XL = 2πfL    f0 = 1 / (2π√(LC))',
    summary: 'Capacitive and inductive reactance, and resonant frequency.',
    modes: [
      FormulaMode(
        label: 'Capacitive',
        inputs: [numIn('f', 'Frequency', 'Hz', def: 50), numIn('c', 'Capacitance', 'µF')],
        outputs: [numOut('xc', 'Capacitive reactance', 'Ω')],
        compute: (v) {
          requirePositive(v['f']!, 'Frequency');
          requirePositive(v['c']!, 'Capacitance');
          return res({'xc': 1 / (2 * math.pi * v['f']! * v['c']! * 1e-6)});
        },
      ),
      FormulaMode(
        label: 'Inductive',
        inputs: [numIn('f', 'Frequency', 'Hz', def: 50), numIn('l', 'Inductance', 'mH')],
        outputs: [numOut('xl', 'Inductive reactance', 'Ω')],
        compute: (v) {
          requireNonNegative(v['f']!, 'Frequency');
          requireNonNegative(v['l']!, 'Inductance');
          return res({'xl': 2 * math.pi * v['f']! * v['l']! * 1e-3});
        },
      ),
      FormulaMode(
        label: 'Resonance',
        inputs: [numIn('l', 'Inductance', 'mH'), numIn('c', 'Capacitance', 'µF')],
        outputs: [numOut('f0', 'Resonant frequency', 'Hz')],
        compute: (v) {
          requirePositive(v['l']!, 'Inductance');
          requirePositive(v['c']!, 'Capacitance');
          return res({'f0': 1 / (2 * math.pi * math.sqrt(v['l']! * 1e-3 * v['c']! * 1e-6))});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'rc_time_constant',
    title: 'RC time constant',
    pack: FormulaPack.electrical,
    formula: 'τ = R × C      fc = 1 / (2πRC)',
    summary: 'Charging time and cut-off frequency of an RC circuit.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [numIn('r', 'Resistance', 'Ω'), numIn('c', 'Capacitance', 'µF')],
        outputs: [
          numOut('tau', 'Time constant τ', 'ms'),
          numOut('five', 'Time to reach 99.3 % (5τ)', 'ms'),
          numOut('fc', 'Cut-off frequency', 'Hz'),
        ],
        compute: (v) {
          requirePositive(v['r']!, 'Resistance');
          requirePositive(v['c']!, 'Capacitance');
          final seconds = v['r']! * v['c']! * 1e-6;
          return res({
            'tau': seconds * 1000,
            'five': seconds * 5000,
            'fc': 1 / (2 * math.pi * seconds),
          });
        },
      ),
    ],
    notes: ['After one time constant a charging capacitor reaches about 63.2 % of the supply voltage.'],
  ),
  FormulaDef(
    id: 'battery_runtime',
    title: 'Battery runtime',
    pack: FormulaPack.electrical,
    formula: 'Runtime = Ah × V × DoD × η / load',
    summary: 'How long a battery can supply a constant load.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('ah', 'Battery capacity', 'Ah'),
          numIn('v', 'Battery voltage', 'V', def: 12),
          numIn('dod', 'Usable depth of discharge', '%', def: 80),
          numIn('eff', 'System efficiency', '%', def: 90),
          numIn('load', 'Load', 'W'),
        ],
        outputs: [numOut('wh', 'Usable energy', 'Wh'), numOut('h', 'Runtime', 'h')],
        compute: (v) {
          requirePositive(v['ah']!, 'Capacity');
          requirePositive(v['v']!, 'Voltage');
          requireRange(v['dod']!, 'Depth of discharge', 1, 100);
          requireRange(v['eff']!, 'Efficiency', 1, 100);
          requirePositive(v['load']!, 'Load');
          final usable = v['ah']! * v['v']! * v['dod']! / 100 * v['eff']! / 100;
          return res({'wh': usable, 'h': usable / v['load']!});
        },
      ),
    ],
    notes: ['Real capacity falls with high discharge rates, low temperature and age.'],
  ),
  FormulaDef(
    id: 'battery_charge_time',
    title: 'Battery charge time and C-rate',
    pack: FormulaPack.electrical,
    formula: 'Time = Ah × charge needed / (I × η)      C-rate = I / Ah',
    summary: 'Estimated charging time and the charge rate.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('ah', 'Battery capacity', 'Ah'),
          numIn('i', 'Charge current', 'A'),
          numIn('eff', 'Charging efficiency', '%', def: 85),
          numIn('need', 'Charge needed', '% of capacity', def: 100),
        ],
        outputs: [numOut('h', 'Charge time', 'h'), numOut('c', 'C-rate', 'C')],
        compute: (v) {
          requirePositive(v['ah']!, 'Capacity');
          requirePositive(v['i']!, 'Charge current');
          requireRange(v['eff']!, 'Efficiency', 1, 100);
          requireRange(v['need']!, 'Charge needed', 0, 100);
          final hours = v['ah']! * v['need']! / 100 / (v['i']! * v['eff']! / 100);
          return res({'h': hours, 'c': v['i']! / v['ah']!});
        },
      ),
    ],
    notes: ['Charging slows near full charge. Follow the battery maker\'s limits.'],
  ),
  FormulaDef(
    id: 'energy_cost',
    title: 'Energy cost',
    pack: FormulaPack.electrical,
    formula: 'Cost = kW × hours × days × tariff',
    summary: 'Energy use and cost of a load over time.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('kw', 'Power', 'kW'),
          numIn('hours', 'Hours per day', 'h', def: 8),
          numIn('days', 'Days', 'days', def: 30),
          numIn('tariff', 'Tariff', 'per kWh'),
        ],
        outputs: [numOut('kwh', 'Energy', 'kWh'), numOut('cost', 'Cost', 'in tariff currency')],
        compute: (v) {
          requireNonNegative(v['kw']!, 'Power');
          requireRange(v['hours']!, 'Hours per day', 0, 24);
          requireNonNegative(v['days']!, 'Days');
          requireNonNegative(v['tariff']!, 'Tariff');
          final energy = v['kw']! * v['hours']! * v['days']!;
          return res({'kwh': energy, 'cost': energy * v['tariff']!});
        },
      ),
    ],
  ),
];
