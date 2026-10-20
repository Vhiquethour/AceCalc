import 'dart:math' as math;

import '../entities/formula_def.dart';
import 'formula_helpers.dart';

final List<FormulaDef> mechanicalFormulas = [
  FormulaDef(
    id: 'force_weight',
    title: 'Force and weight',
    pack: FormulaPack.mechanical,
    formula: 'F = m × a      W = m × g',
    summary: "Newton's second law and the weight of a mass.",
    modes: [
      FormulaMode(
        label: 'Force',
        inputs: [numIn('m', 'Mass', 'kg'), numIn('a', 'Acceleration', 'm/s²')],
        outputs: [numOut('f', 'Force', 'N'), numOut('lbf', 'Force', 'lbf')],
        compute: (v) {
          final force = v['m']! * v['a']!;
          return res({'f': force, 'lbf': force / 4.4482216152605});
        },
      ),
      FormulaMode(
        label: 'Weight',
        inputs: [
          numIn('m', 'Mass', 'kg'),
          numIn('g', 'Gravity', 'm/s²', def: standardGravity),
        ],
        outputs: [numOut('w', 'Weight', 'N'), numOut('lbf', 'Weight', 'lbf')],
        compute: (v) {
          requirePositive(v['g']!, 'Gravity');
          final weight = v['m']! * v['g']!;
          return res({'w': weight, 'lbf': weight / 4.4482216152605});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'torque_power',
    title: 'Torque, power and speed',
    pack: FormulaPack.mechanical,
    formula: 'P (kW) = T (N·m) × rpm / 9549.3',
    summary: 'Solve for power, torque or shaft speed.',
    modes: [
      FormulaMode(
        label: 'Power',
        inputs: [numIn('t', 'Torque', 'N·m'), numIn('n', 'Speed', 'rpm')],
        outputs: [numOut('p', 'Power', 'kW'), numOut('hp', 'Power', 'hp')],
        compute: (v) {
          requireNonNegative(v['n']!, 'Speed');
          final kw = v['t']! * v['n']! * 2 * math.pi / 60 / 1000;
          return res({'p': kw, 'hp': kw / 0.74569987158227});
        },
      ),
      FormulaMode(
        label: 'Torque',
        inputs: [numIn('p', 'Power', 'kW'), numIn('n', 'Speed', 'rpm')],
        outputs: [numOut('t', 'Torque', 'N·m')],
        compute: (v) {
          requirePositive(v['n']!, 'Speed');
          return res({'t': v['p']! * 1000 * 60 / (2 * math.pi * v['n']!)});
        },
      ),
      FormulaMode(
        label: 'Speed',
        inputs: [numIn('p', 'Power', 'kW'), numIn('t', 'Torque', 'N·m')],
        outputs: [numOut('n', 'Speed', 'rpm')],
        compute: (v) {
          requirePositive(v['t']!, 'Torque');
          return res({'n': v['p']! * 1000 * 60 / (2 * math.pi * v['t']!)});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'synchronous_speed',
    title: 'Motor synchronous speed and slip',
    pack: FormulaPack.mechanical,
    formula: 'Ns = 120 × f / poles      Slip = (Ns − N) / Ns',
    summary: 'Synchronous speed of an AC motor, and slip if the rotor speed is known.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('f', 'Supply frequency', 'Hz', def: 50),
          numIn('poles', 'Number of poles', '', def: 4),
          numIn('n', 'Rotor speed', 'rpm', optional: true),
        ],
        outputs: [numOut('ns', 'Synchronous speed', 'rpm'), numOut('slip', 'Slip', '%')],
        compute: (v) {
          requirePositive(v['f']!, 'Frequency');
          final poles = v['poles']!.roundToDouble();
          if (poles < 2 || poles % 2 != 0) {
            throw const FormulaException('The number of poles must be an even number of 2 or more.');
          }
          final synchronous = 120 * v['f']! / poles;
          final values = <String, double>{'ns': synchronous};
          final rotor = v['n'];
          if (rotor != null) {
            requireNonNegative(rotor, 'Rotor speed');
            values['slip'] = (synchronous - rotor) / synchronous * 100;
          }
          return res(values);
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'motor_efficiency',
    title: 'Motor efficiency',
    pack: FormulaPack.mechanical,
    formula: 'η = output power / input power',
    summary: 'Efficiency, or the input power needed for a given shaft output.',
    modes: [
      FormulaMode(
        label: 'Efficiency',
        inputs: [numIn('pout', 'Output (shaft) power', 'kW'), numIn('pin', 'Input power', 'kW')],
        outputs: [numOut('eta', 'Efficiency', '%'), numOut('loss', 'Losses', 'kW')],
        compute: (v) {
          requirePositive(v['pin']!, 'Input power');
          requireNonNegative(v['pout']!, 'Output power');
          if (v['pout']! > v['pin']!) {
            throw const FormulaException('Output power cannot exceed input power.');
          }
          return res({
            'eta': v['pout']! / v['pin']! * 100,
            'loss': v['pin']! - v['pout']!,
          });
        },
      ),
      FormulaMode(
        label: 'Input power',
        inputs: [numIn('pout', 'Output (shaft) power', 'kW'), numIn('eta', 'Efficiency', '%', def: 90)],
        outputs: [numOut('pin', 'Input power', 'kW'), numOut('loss', 'Losses', 'kW')],
        compute: (v) {
          requireNonNegative(v['pout']!, 'Output power');
          requireRange(v['eta']!, 'Efficiency', 1, 100);
          final input = v['pout']! / (v['eta']! / 100);
          return res({'pin': input, 'loss': input - v['pout']!});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'kinetic_potential',
    title: 'Kinetic and potential energy',
    pack: FormulaPack.mechanical,
    formula: 'KE = ½ × m × v²      PE = m × g × h',
    summary: 'Energy of a moving or raised mass.',
    modes: [
      FormulaMode(
        label: 'Kinetic',
        inputs: [numIn('m', 'Mass', 'kg'), numIn('v', 'Velocity', 'm/s')],
        outputs: [numOut('ke', 'Kinetic energy', 'J'), numOut('kj', 'Kinetic energy', 'kJ')],
        compute: (v) {
          requireNonNegative(v['m']!, 'Mass');
          final energy = 0.5 * v['m']! * v['v']! * v['v']!;
          return res({'ke': energy, 'kj': energy / 1000});
        },
      ),
      FormulaMode(
        label: 'Potential',
        inputs: [
          numIn('m', 'Mass', 'kg'),
          numIn('h', 'Height', 'm'),
          numIn('g', 'Gravity', 'm/s²', def: standardGravity),
        ],
        outputs: [numOut('pe', 'Potential energy', 'J'), numOut('kj', 'Potential energy', 'kJ')],
        compute: (v) {
          requireNonNegative(v['m']!, 'Mass');
          requirePositive(v['g']!, 'Gravity');
          final energy = v['m']! * v['g']! * v['h']!;
          return res({'pe': energy, 'kj': energy / 1000});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'stress_safety_factor',
    title: 'Stress and factor of safety',
    pack: FormulaPack.mechanical,
    formula: 'σ = F / A      Factor of safety = yield strength / σ',
    summary: 'Direct stress in a member, and the factor of safety if the yield strength is known.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('f', 'Force', 'N'),
          numIn('a', 'Cross-section area', 'mm²'),
          numIn('yield', 'Yield strength', 'MPa', optional: true),
        ],
        outputs: [numOut('sigma', 'Stress', 'MPa'), numOut('fos', 'Factor of safety')],
        compute: (v) {
          requirePositive(v['a']!, 'Area');
          final stress = v['f']! / v['a']!;
          final values = <String, double>{'sigma': stress};
          final messages = <String>[];
          final yieldStrength = v['yield'];
          if (yieldStrength != null) {
            requirePositive(yieldStrength, 'Yield strength');
            if (stress.abs() > 0) {
              final factor = yieldStrength / stress.abs();
              values['fos'] = factor;
              if (factor < 1) messages.add('The stress exceeds the yield strength.');
            }
          }
          return res(values, messages);
        },
      ),
    ],
    notes: ['One newton per square millimetre is one megapascal. Direct (axial) stress only.'],
  ),
  FormulaDef(
    id: 'gear_pulley_ratio',
    title: 'Gear and pulley ratio',
    pack: FormulaPack.mechanical,
    formula: 'Ratio = driven / driver      Output rpm = input rpm / ratio',
    summary: 'Speed and ideal torque change across a gear or pulley pair.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('driver', 'Driver teeth or diameter', ''),
          numIn('driven', 'Driven teeth or diameter', ''),
          numIn('rpm', 'Input speed', 'rpm'),
        ],
        outputs: [
          numOut('ratio', 'Ratio (driven : driver)'),
          numOut('out', 'Output speed', 'rpm'),
          numOut('torque', 'Ideal torque multiplier'),
        ],
        compute: (v) {
          requirePositive(v['driver']!, 'Driver size');
          requirePositive(v['driven']!, 'Driven size');
          requireNonNegative(v['rpm']!, 'Input speed');
          final ratio = v['driven']! / v['driver']!;
          return res({'ratio': ratio, 'out': v['rpm']! / ratio, 'torque': ratio});
        },
      ),
    ],
    notes: ['Ideal values with no losses. Real torque is lower because of friction.'],
  ),
  FormulaDef(
    id: 'thermal_expansion',
    title: 'Thermal expansion',
    pack: FormulaPack.mechanical,
    formula: 'ΔL = α × L × ΔT',
    summary: 'Change in length of a bar or pipe when its temperature changes.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('alpha', 'Expansion coefficient α', '× 10⁻⁶ per K', def: 12),
          numIn('l', 'Original length', 'm'),
          numIn('dt', 'Temperature change', 'K'),
        ],
        outputs: [numOut('dl', 'Change in length', 'mm'), numOut('new', 'New length', 'm')],
        compute: (v) {
          requireNonNegative(v['l']!, 'Length');
          final change = v['alpha']! * 1e-6 * v['l']! * v['dt']!;
          return res({'dl': change * 1000, 'new': v['l']! + change});
        },
      ),
    ],
    notes: ['Typical α: carbon steel about 12, stainless steel about 17, aluminium about 23 (× 10⁻⁶ per K).'],
  ),
  FormulaDef(
    id: 'sensible_heat',
    title: 'Heat required (sensible heat)',
    pack: FormulaPack.mechanical,
    formula: 'Q = m × c × ΔT',
    summary: 'Heat needed to change the temperature of a mass.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('m', 'Mass', 'kg'),
          numIn('c', 'Specific heat', 'kJ/(kg·K)', def: 4.186),
          numIn('dt', 'Temperature change', 'K'),
        ],
        outputs: [numOut('q', 'Heat', 'kJ'), numOut('kwh', 'Heat', 'kWh')],
        compute: (v) {
          requireNonNegative(v['m']!, 'Mass');
          requireNonNegative(v['c']!, 'Specific heat');
          final heat = v['m']! * v['c']! * v['dt']!;
          return res({'q': heat, 'kwh': heat / 3600});
        },
      ),
    ],
    notes: ['The default specific heat is for liquid water. No phase change is included.'],
  ),
];
