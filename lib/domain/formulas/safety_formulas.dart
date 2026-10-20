import 'dart:math' as math;

import '../entities/formula_def.dart';
import 'formula_helpers.dart';

const List<FormulaChoice> _noiseStandards = [
  FormulaChoice('NIOSH (85 dBA, 3 dB)', 1),
  FormulaChoice('OSHA (90 dBA, 5 dB)', 2),
];

/// Returns the criterion level and exchange rate for a standard code.
List<double> _noiseCriterion(double code) => code == 2 ? [90, 5] : [85, 3];

String _rating(double score, double medium, double high, double extreme) {
  if (score >= extreme) return 'Extreme';
  if (score >= high) return 'High';
  if (score >= medium) return 'Medium';
  return 'Low';
}

List<FormulaInput> _noiseRows() {
  return [
    for (var i = 1; i <= 4; i++) ...[
      numIn('l$i', 'Exposure $i: sound level', 'dBA', optional: i > 1),
      numIn('h$i', 'Exposure $i: duration', 'h', optional: i > 1),
    ],
  ];
}

final List<FormulaDef> safetyFormulas = [
  FormulaDef(
    id: 'incident_rates',
    title: 'Incident rates (TRIR, LTIFR)',
    pack: FormulaPack.safety,
    formula: 'Rate = incidents × K / hours worked',
    summary: 'Recordable, lost-time and severity rates.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('rec', 'Recordable incidents', ''),
          numIn('lti', 'Lost-time injuries', ''),
          numIn('days', 'Lost days', 'days', optional: true),
          numIn('hours', 'Hours worked', 'h'),
          choiceIn('k', 'Rate basis (K)', const [
            FormulaChoice('200,000 hours (OSHA)', 200000),
            FormulaChoice('1,000,000 hours (IOGP)', 1000000),
          ]),
        ],
        outputs: [
          numOut('trir', 'Total recordable incident rate'),
          numOut('ltifr', 'Lost-time injury frequency rate'),
          numOut('sev', 'Severity rate'),
        ],
        compute: (v) {
          requirePositive(v['hours']!, 'Hours worked');
          requireNonNegative(v['rec']!, 'Recordable incidents');
          requireNonNegative(v['lti']!, 'Lost-time injuries');
          final k = v['k']!;
          final values = <String, double>{
            'trir': v['rec']! * k / v['hours']!,
            'ltifr': v['lti']! * k / v['hours']!,
          };
          final lostDays = v['days'];
          if (lostDays != null) {
            requireNonNegative(lostDays, 'Lost days');
            values['sev'] = lostDays * k / v['hours']!;
          }
          return res(values);
        },
      ),
    ],
    notes: [
      'Companies use different bases. Compare rates only when they use the same one.',
      'Definitions of recordable and lost-time incidents follow your own reporting procedure.',
    ],
  ),
  FormulaDef(
    id: 'hours_worked',
    title: 'Hours worked estimate',
    pack: FormulaPack.safety,
    formula: 'Hours = people × hours per day × days',
    summary: 'Estimate the exposure hours used in incident rates.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('people', 'Number of workers', ''),
          numIn('hrs', 'Hours per worker per day', 'h', def: 8),
          numIn('days', 'Working days', 'days'),
        ],
        outputs: [numOut('hours', 'Total hours worked', 'h')],
        compute: (v) {
          requireNonNegative(v['people']!, 'Workers');
          requireRange(v['hrs']!, 'Hours per day', 0, 24);
          requireNonNegative(v['days']!, 'Days');
          return res({'hours': v['people']! * v['hrs']! * v['days']!});
        },
      ),
    ],
    notes: ['Use actual timesheet hours where you have them. Include overtime and contractors.'],
  ),
  FormulaDef(
    id: 'noise_combine',
    title: 'Combine noise levels',
    pack: FormulaPack.safety,
    formula: 'L = 10 × log10(Σ 10^(Li / 10))',
    summary: 'Total sound level from several sources.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('l1', 'Source 1', 'dB'),
          numIn('l2', 'Source 2', 'dB'),
          numIn('l3', 'Source 3', 'dB', optional: true),
          numIn('l4', 'Source 4', 'dB', optional: true),
        ],
        outputs: [numOut('l', 'Combined level', 'dB')],
        compute: (v) {
          final levels = present(v, ['l1', 'l2', 'l3', 'l4']);
          final total = levels.fold(0.0, (sum, l) => sum + math.pow(10, l / 10));
          return res(
            {'l': 10 * log10(total)},
            ['Two equal sources give about 3 dB more than one.'],
          );
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'noise_permitted_time',
    title: 'Permitted noise exposure time',
    pack: FormulaPack.safety,
    formula: 'T = 8 / 2^((L − criterion) / exchange rate)',
    summary: 'Hours allowed at a steady level under the chosen standard.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('l', 'Sound level', 'dBA'),
          choiceIn('std', 'Standard', _noiseStandards),
        ],
        outputs: [numOut('t', 'Permitted time', 'h'), numOut('min', 'Permitted time', 'min')],
        compute: (v) {
          final std = _noiseCriterion(v['std']!);
          final hours = 8 / math.pow(2, (v['l']! - std[0]) / std[1]);
          return res({'t': hours, 'min': hours * 60});
        },
      ),
    ],
    notes: [
      'NIOSH uses 85 dBA with a 3 dB exchange rate. OSHA uses 90 dBA with a 5 dB exchange rate.',
      'Use the standard that applies to your site.',
    ],
  ),
  FormulaDef(
    id: 'noise_dose',
    title: 'Noise dose and TWA',
    pack: FormulaPack.safety,
    formula: 'Dose = 100 × Σ(C / T)      TWA = criterion + (exchange / log10 2) × log10(Dose / 100)',
    summary: 'Daily dose and 8-hour time-weighted average for up to four exposures.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          ..._noiseRows(),
          choiceIn('std', 'Standard', _noiseStandards),
        ],
        outputs: [numOut('dose', 'Noise dose', '%'), numOut('twa', '8-hour TWA', 'dBA')],
        compute: (v) {
          final std = _noiseCriterion(v['std']!);
          final rows = pairs(v, [
            ['l1', 'h1'],
            ['l2', 'h2'],
            ['l3', 'h3'],
            ['l4', 'h4'],
          ]);
          var dose = 0.0;
          for (final row in rows) {
            requireNonNegative(row[1], 'Duration');
            final allowed = 8 / math.pow(2, (row[0] - std[0]) / std[1]);
            dose += 100 * row[1] / allowed;
          }
          if (!(dose > 0)) {
            throw const FormulaException('Enter at least one duration above zero.');
          }
          final twa = std[0] + (std[1] / log10(2)) * log10(dose / 100);
          final messages = <String>[
            if (dose > 100) 'The dose is above 100 % of the criterion.',
          ];
          return res({'dose': dose, 'twa': twa}, messages);
        },
      ),
    ],
    notes: [
      'All entered levels are included. Some procedures ignore levels below a threshold.',
    ],
  ),
  FormulaDef(
    id: 'noise_distance',
    title: 'Noise level at a distance',
    pack: FormulaPack.safety,
    formula: 'L2 = L1 − 20 × log10(r2 / r1)',
    summary: 'Level from a point source in free field.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('l1', 'Known level', 'dB'),
          numIn('r1', 'Distance of known level', 'm'),
          numIn('r2', 'New distance', 'm'),
        ],
        outputs: [numOut('l2', 'Level at new distance', 'dB')],
        compute: (v) {
          requirePositive(v['r1']!, 'Known distance');
          requirePositive(v['r2']!, 'New distance');
          return res({'l2': v['l1']! - 20 * log10(v['r2']! / v['r1']!)});
        },
      ),
    ],
    notes: ['Free field with no reflections. Indoors and near walls the level falls more slowly.'],
  ),
  FormulaDef(
    id: 'hearing_protection',
    title: 'Hearing protection estimate',
    pack: FormulaPack.safety,
    formula: 'Exposure = TWA − (NRR − 7) / 2',
    summary: 'Rough protected exposure for an A-weighted TWA.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [numIn('twa', 'Unprotected TWA', 'dBA'), numIn('nrr', 'Noise reduction rating (NRR)', 'dB')],
        outputs: [numOut('prot', 'Estimated protected exposure', 'dBA'), numOut('red', 'Estimated reduction', 'dB')],
        compute: (v) {
          requireNonNegative(v['nrr']!, 'NRR');
          final reduction = math.max(0.0, (v['nrr']! - 7) / 2);
          return res(
            {'prot': v['twa']! - reduction, 'red': reduction},
            ['A rough estimate. Real attenuation depends on fit and use.'],
          );
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'gas_ppm_mg',
    title: 'Gas ppm and mg/m³',
    pack: FormulaPack.safety,
    formula: 'mg/m³ = ppm × M / Vm      Vm = R × T / P',
    summary: 'Convert gas concentration using the molar mass and conditions.',
    modes: [
      FormulaMode(
        label: 'ppm to mg/m³',
        inputs: [
          numIn('ppm', 'Concentration', 'ppm'),
          numIn('mm', 'Molar mass', 'g/mol'),
          numIn('t', 'Temperature', '°C', def: 25),
          numIn('p', 'Pressure', 'kPa', def: 101.325),
        ],
        outputs: [numOut('mg', 'Concentration', 'mg/m³'), numOut('vm', 'Molar volume used', 'L/mol')],
        compute: (v) {
          final vm = _molarVolume(v);
          return res({'mg': v['ppm']! * v['mm']! / vm, 'vm': vm});
        },
      ),
      FormulaMode(
        label: 'mg/m³ to ppm',
        inputs: [
          numIn('mg', 'Concentration', 'mg/m³'),
          numIn('mm', 'Molar mass', 'g/mol'),
          numIn('t', 'Temperature', '°C', def: 25),
          numIn('p', 'Pressure', 'kPa', def: 101.325),
        ],
        outputs: [numOut('ppm', 'Concentration', 'ppm'), numOut('vm', 'Molar volume used', 'L/mol')],
        compute: (v) {
          final vm = _molarVolume(v);
          return res({'ppm': v['mg']! * vm / v['mm']!, 'vm': vm});
        },
      ),
    ],
    notes: [
      'Molar masses (g/mol): H₂S 34.08, CO 28.01, CO₂ 44.01, CH₄ 16.04, NH₃ 17.03, SO₂ 64.07, benzene 78.11.',
      'At 25 °C and 101.325 kPa the molar volume is 24.465 L/mol. Some references round it to 24.45.',
    ],
  ),
  FormulaDef(
    id: 'twa_exposure',
    title: 'Time-weighted average exposure',
    pack: FormulaPack.safety,
    formula: 'TWA = Σ(C × t) / 8',
    summary: 'Eight-hour average of up to four exposures, compared with a limit you enter.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          ..._concentrationRows(),
          numIn('limit', 'Exposure limit', 'same unit', optional: true),
        ],
        outputs: [
          numOut('twa', '8-hour TWA'),
          numOut('hours', 'Listed hours', 'h'),
          numOut('pct', 'Share of limit', '%'),
        ],
        compute: (v) {
          final rows = pairs(v, [
            ['c1', 't1'],
            ['c2', 't2'],
            ['c3', 't3'],
            ['c4', 't4'],
          ]);
          var sum = 0.0;
          var hours = 0.0;
          for (final row in rows) {
            requireNonNegative(row[0], 'Concentration');
            requireNonNegative(row[1], 'Duration');
            sum += row[0] * row[1];
            hours += row[1];
          }
          final twa = sum / 8;
          final values = <String, double>{'twa': twa, 'hours': hours};
          final messages = <String>[];
          if (hours > 8) {
            messages.add('The listed durations total more than 8 hours. Check the data.');
          }
          final limit = v['limit'];
          if (limit != null) {
            requirePositive(limit, 'Exposure limit');
            values['pct'] = twa / limit * 100;
            if (twa > limit) messages.add('The TWA is above the limit you entered.');
          }
          return res(values, messages);
        },
      ),
    ],
    notes: [
      'Time that is not listed counts as zero exposure.',
      'Enter the limit from your regulation or occupational exposure list.',
    ],
  ),
  FormulaDef(
    id: 'mixture_index',
    title: 'Exposure to a mixture',
    pack: FormulaPack.safety,
    formula: 'Index = C1/L1 + C2/L2 + …',
    summary: 'Combined effect of substances that act on the same body system.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          for (var i = 1; i <= 4; i++) ...[
            numIn('c$i', 'Substance $i: concentration', '', optional: i > 2),
            numIn('lim$i', 'Substance $i: limit', 'same unit', optional: i > 2),
          ],
        ],
        outputs: [numOut('index', 'Combined index')],
        compute: (v) {
          final rows = pairs(v, [
            ['c1', 'lim1'],
            ['c2', 'lim2'],
            ['c3', 'lim3'],
            ['c4', 'lim4'],
          ]);
          var index = 0.0;
          for (final row in rows) {
            requireNonNegative(row[0], 'Concentration');
            requirePositive(row[1], 'Limit');
            index += row[0] / row[1];
          }
          return res({'index': index}, [
            index > 1
                ? 'The combined limit is exceeded (index above 1).'
                : 'Below the combined limit (index at or under 1).',
          ]);
        },
      ),
    ],
    notes: ['Assumes the effects are additive. Check this for the substances involved.'],
  ),
  FormulaDef(
    id: 'ventilation_ach',
    title: 'Ventilation air changes',
    pack: FormulaPack.safety,
    formula: 'ACH = airflow / room volume',
    summary: 'Air changes per hour, or the airflow needed for a target.',
    modes: [
      FormulaMode(
        label: 'Air changes',
        inputs: [..._roomInputs(), numIn('q', 'Airflow', 'm³/h')],
        outputs: [numOut('vol', 'Room volume', 'm³'), numOut('ach', 'Air changes', 'per hour')],
        compute: (v) {
          final volume = _roomVolume(v);
          requireNonNegative(v['q']!, 'Airflow');
          return res({'vol': volume, 'ach': v['q']! / volume});
        },
      ),
      FormulaMode(
        label: 'Required airflow',
        inputs: [..._roomInputs(), numIn('ach', 'Target air changes', 'per hour')],
        outputs: [
          numOut('q', 'Required airflow', 'm³/h'),
          numOut('ls', 'Required airflow', 'L/s'),
          numOut('cfm', 'Required airflow', 'CFM'),
        ],
        compute: (v) {
          final volume = _roomVolume(v);
          requireNonNegative(v['ach']!, 'Air changes');
          final flow = v['ach']! * volume;
          return res({'q': flow, 'ls': flow / 3.6, 'cfm': flow / 1.699010796});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'wbgt',
    title: 'Heat stress (WBGT)',
    pack: FormulaPack.safety,
    formula: 'Outdoors in sun: 0.7 Tnwb + 0.2 Tg + 0.1 Tdb      Indoors: 0.7 Tnwb + 0.3 Tg',
    summary: 'Wet-bulb globe temperature, compared with a limit you enter.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('tnwb', 'Natural wet-bulb temperature', '°C'),
          numIn('tg', 'Globe temperature', '°C'),
          numIn('tdb', 'Dry-bulb temperature', '°C'),
          choiceIn('loc', 'Conditions', const [
            FormulaChoice('Outdoors with sun', 1),
            FormulaChoice('Indoors or no sun', 2),
          ]),
          numIn('limit', 'Reference limit', '°C WBGT', optional: true),
        ],
        outputs: [numOut('wbgt', 'WBGT', '°C'), numOut('margin', 'Margin to limit', '°C')],
        compute: (v) {
          final outdoors = v['loc']! == 1;
          final wbgt = outdoors
              ? 0.7 * v['tnwb']! + 0.2 * v['tg']! + 0.1 * v['tdb']!
              : 0.7 * v['tnwb']! + 0.3 * v['tg']!;
          final values = <String, double>{'wbgt': wbgt};
          final messages = <String>[];
          if (v['tnwb']! > v['tdb']!) {
            messages.add('Natural wet-bulb is normally at or below dry-bulb. Check the readings.');
          }
          final limit = v['limit'];
          if (limit != null) {
            values['margin'] = limit - wbgt;
            if (wbgt > limit) {
              messages.add('The WBGT is above the limit you entered. Review work-rest cycles, water, shade and other controls.');
            }
          }
          return res(values, messages);
        },
      ),
    ],
    notes: [
      'Limits depend on work rate and acclimatisation. Take the reference limit from ACGIH, NIOSH or your site procedure.',
    ],
  ),
  FormulaDef(
    id: 'risk_matrix',
    title: 'Risk matrix (5 × 5)',
    pack: FormulaPack.safety,
    formula: 'Risk score = likelihood × severity',
    summary: 'Inherent and residual risk with band limits you can change.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('l', 'Likelihood (1 to 5)', ''),
          numIn('s', 'Severity (1 to 5)', ''),
          numIn('medium', 'Medium band starts at', '', def: 5),
          numIn('high', 'High band starts at', '', def: 10),
          numIn('extreme', 'Extreme band starts at', '', def: 17),
          numIn('rl', 'Likelihood after controls', '', optional: true),
          numIn('rs', 'Severity after controls', '', optional: true),
        ],
        outputs: [numOut('score', 'Risk score'), numOut('residual', 'Residual risk score')],
        compute: (v) {
          final medium = v['medium']!;
          final high = v['high']!;
          final extreme = v['extreme']!;
          if (!(medium < high && high < extreme)) {
            throw const FormulaException('Band limits must increase: medium, then high, then extreme.');
          }
          requireRange(v['l']!, 'Likelihood', 1, 5);
          requireRange(v['s']!, 'Severity', 1, 5);
          final score = v['l']!.roundToDouble() * v['s']!.roundToDouble();
          final values = <String, double>{'score': score};
          final messages = <String>[
            'Inherent risk: ${_rating(score, medium, high, extreme)} (score ${score.toStringAsFixed(0)}).',
          ];
          final rl = v['rl'];
          final rs = v['rs'];
          if (rl != null || rs != null) {
            if (rl == null || rs == null) {
              throw const FormulaException('Enter both likelihood and severity after controls.');
            }
            requireRange(rl, 'Likelihood after controls', 1, 5);
            requireRange(rs, 'Severity after controls', 1, 5);
            final residual = rl.roundToDouble() * rs.roundToDouble();
            values['residual'] = residual;
            messages.add('Residual risk: ${_rating(residual, medium, high, extreme)} (score ${residual.toStringAsFixed(0)}).');
          }
          return res(values, messages);
        },
      ),
    ],
    notes: [
      'The default bands (5, 10 and 17) are only a starting point. Use the bands in your own risk procedure.',
      'Reduce risk in order: eliminate, substitute, engineering controls, administrative controls, then PPE.',
    ],
  ),
  FormulaDef(
    id: 'sling_angle',
    title: 'Sling angle and leg load',
    pack: FormulaPack.safety,
    formula: 'Tension per leg = load / (legs × sin θ)',
    summary: 'How the sling angle increases the load on each leg.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('load', 'Load mass', 'kg'),
          numIn('legs', 'Number of legs carrying the load', '', def: 2),
          numIn('angle', 'Angle from horizontal', '°', def: 60),
        ],
        outputs: [
          numOut('tension', 'Tension per leg', 'kgf'),
          numOut('kn', 'Tension per leg', 'kN'),
          numOut('factor', 'Load multiplier per leg'),
        ],
        compute: (v) {
          requirePositive(v['load']!, 'Load');
          final legs = v['legs']!.roundToDouble();
          if (legs < 1) throw const FormulaException('At least one leg must carry the load.');
          final angle = v['angle']!;
          if (!(angle > 0 && angle <= 90)) {
            throw const FormulaException('The angle must be above 0° and at most 90°.');
          }
          final sine = math.sin(degToRad(angle));
          final tension = v['load']! / (legs * sine);
          final messages = <String>[
            if (angle < 45)
              'Angles below 45° sharply increase the load on each leg. Many procedures avoid them.',
          ];
          return res(
            {'tension': tension, 'kn': tension * standardGravity / 1000, 'factor': 1 / sine},
            messages,
          );
        },
      ),
    ],
    notes: [
      'Assumes equal sharing between legs. With three or four legs, many procedures count only two as carrying the load.',
      'Check the result against the working load limit of the sling and fittings.',
    ],
  ),
  FormulaDef(
    id: 'fall_clearance',
    title: 'Fall clearance distance',
    pack: FormulaPack.safety,
    formula: 'Clearance = lanyard + deceleration + attachment height + margin',
    summary: 'Free space needed below the anchor point.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('lanyard', 'Lanyard length (with connectors)', 'm'),
          numIn('decel', 'Deceleration distance', 'm'),
          numIn('attach', 'Harness attachment height above feet', 'm', def: 1.5),
          numIn('margin', 'Safety margin', 'm', def: 1),
        ],
        outputs: [numOut('total', 'Required clearance', 'm')],
        compute: (v) {
          for (final key in ['lanyard', 'decel', 'attach', 'margin']) {
            requireNonNegative(v[key]!, 'Each distance');
          }
          return res({'total': v['lanyard']! + v['decel']! + v['attach']! + v['margin']!});
        },
      ),
    ],
    notes: [
      'Take the lanyard and deceleration values from the equipment datasheet.',
      'This does not cover swing falls or anchor height above the harness.',
    ],
  ),
  FormulaDef(
    id: 'ladder_angle',
    title: 'Ladder setup (1 in 4 rule)',
    pack: FormulaPack.safety,
    formula: 'Base distance = support height / 4',
    summary: 'Base distance, ladder length and angle.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('h', 'Height of the support point', 'm'),
          numIn('base', 'Measured base distance', 'm', optional: true),
        ],
        outputs: [
          numOut('rec', 'Recommended base distance', 'm'),
          numOut('length', 'Minimum ladder length', 'm'),
          numOut('angle', 'Ladder angle from horizontal', '°'),
        ],
        compute: (v) {
          requirePositive(v['h']!, 'Height');
          final height = v['h']!;
          final recommended = height / 4;
          final measured = v['base'];
          if (measured != null) requirePositive(measured, 'Base distance');
          final base = measured ?? recommended;
          return res({
            'rec': recommended,
            'length': math.sqrt(height * height + base * base),
            'angle': radToDeg(math.atan(height / base)),
          });
        },
      ),
    ],
    notes: [
      'The 1 in 4 rule gives an angle of about 76°.',
      'A ladder used to reach a landing normally extends about 1 m above it. Add that to the length.',
    ],
  ),
  FormulaDef(
    id: 'lel_percent',
    title: 'Flammable gas (% LEL)',
    pack: FormulaPack.safety,
    formula: '% LEL = concentration / LEL × 100',
    summary: 'Gas reading as a share of the lower explosive limit.',
    modes: [
      FormulaMode(
        label: 'From % by volume',
        inputs: [numIn('c', 'Gas concentration', '% by volume'), numIn('lel', 'LEL of the gas', '% by volume')],
        outputs: [numOut('pct', 'Share of LEL', '% LEL'), numOut('lelppm', 'LEL expressed as', 'ppm')],
        compute: (v) {
          requireNonNegative(v['c']!, 'Concentration');
          requirePositive(v['lel']!, 'LEL');
          return _lelResult(v['c']! / v['lel']! * 100, v['lel']!);
        },
      ),
      FormulaMode(
        label: 'From ppm',
        inputs: [numIn('ppm', 'Gas concentration', 'ppm'), numIn('lel', 'LEL of the gas', '% by volume')],
        outputs: [numOut('pct', 'Share of LEL', '% LEL'), numOut('lelppm', 'LEL expressed as', 'ppm')],
        compute: (v) {
          requireNonNegative(v['ppm']!, 'Concentration');
          requirePositive(v['lel']!, 'LEL');
          return _lelResult(v['ppm']! / (v['lel']! * 10000) * 100, v['lel']!);
        },
      ),
    ],
    notes: [
      'Enter the LEL for the gas from its safety data sheet. Methane is about 5 % by volume.',
      'Set alarm levels in line with your site gas-testing procedure.',
    ],
  ),
  FormulaDef(
    id: 'purge_time',
    title: 'Confined space purge time',
    pack: FormulaPack.safety,
    formula: 't = K × (V / Q) × ln(C0 / C)',
    summary: 'Time to dilute a contaminant by ventilation.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('vol', 'Space volume', 'm³'),
          numIn('q', 'Fresh airflow', 'm³/h'),
          numIn('c0', 'Starting concentration', '% or ppm'),
          numIn('c', 'Target concentration', 'same unit'),
          numIn('k', 'Mixing factor (1 = ideal)', '', def: 1),
        ],
        outputs: [
          numOut('h', 'Purge time', 'h'),
          numOut('min', 'Purge time', 'min'),
          numOut('ach', 'Air changes in that time'),
        ],
        compute: (v) {
          requirePositive(v['vol']!, 'Volume');
          requirePositive(v['q']!, 'Airflow');
          requirePositive(v['c']!, 'Target concentration');
          if (!(v['c0']! > v['c']!)) {
            throw const FormulaException('The starting concentration must be above the target.');
          }
          if (!(v['k']! >= 1)) {
            throw const FormulaException('The mixing factor must be 1 or more.');
          }
          final hours = v['k']! * v['vol']! / v['q']! * math.log(v['c0']! / v['c']!);
          return res({'h': hours, 'min': hours * 60, 'ach': hours * v['q']! / v['vol']!});
        },
      ),
    ],
    notes: [
      'Assumes the air mixes well. Real spaces mix imperfectly, so mixing factors of about 3 to 10 are often used.',
      'Confirm the result with gas testing before entry. This is not a substitute for a permit and test.',
    ],
  ),
  FormulaDef(
    id: 'niosh_lifting',
    title: 'NIOSH lifting equation',
    pack: FormulaPack.safety,
    formula: 'RWL = 23 kg × HM × VM × DM × AM × FM × CM      LI = load / RWL',
    summary: 'Recommended weight limit and lifting index for a two-handed lift.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('h', 'Horizontal distance of hands', 'cm', def: 25),
          numIn('v', 'Vertical height of hands at start', 'cm', def: 75),
          numIn('d', 'Vertical travel distance', 'cm', def: 25),
          numIn('a', 'Asymmetry angle', '°', def: 0),
          numIn('fm', 'Frequency multiplier (FM)', '0 to 1', def: 1),
          numIn('cmult', 'Coupling multiplier (CM)', '0 to 1', def: 1),
          numIn('load', 'Load to be lifted', 'kg'),
        ],
        outputs: [numOut('rwl', 'Recommended weight limit', 'kg'), numOut('li', 'Lifting index')],
        compute: (v) {
          final h = v['h']!;
          final vert = v['v']!;
          final d = v['d']!;
          final a = v['a']!;
          requireNonNegative(h, 'Horizontal distance');
          requireNonNegative(vert, 'Vertical height');
          requireNonNegative(d, 'Travel distance');
          requireRange(a, 'Asymmetry angle', 0, 180);
          requireRange(v['fm']!, 'Frequency multiplier', 0, 1);
          requireRange(v['cmult']!, 'Coupling multiplier', 0, 1);
          requirePositive(v['load']!, 'Load');
          final hm = h <= 25 ? 1.0 : (h > 63 ? 0.0 : 25 / h);
          final vm = vert > 175 ? 0.0 : 1 - 0.003 * (vert - 75).abs();
          final dm = d <= 25 ? 1.0 : (d > 175 ? 0.0 : 0.82 + 4.5 / d);
          final am = a > 135 ? 0.0 : 1 - 0.0032 * a;
          final rwl = 23 * hm * vm * dm * am * v['fm']! * v['cmult']!;
          final values = <String, double>{'rwl': rwl};
          final messages = <String>[];
          if (rwl > 0) {
            final index = v['load']! / rwl;
            values['li'] = index;
            if (index > 1) {
              messages.add('A lifting index above 1 means increased risk for some workers.');
            }
          } else {
            messages.add('The lift is outside the limits of the equation, so the recommended limit is zero.');
          }
          return res(values, messages);
        },
      ),
    ],
    notes: [
      'Take FM and CM from the NIOSH tables (they depend on lift frequency, duration and grip).',
      'Applies to smooth two-handed lifts of a stable load. It does not cover one-handed, seated or kneeling lifts.',
    ],
  ),
];

List<FormulaInput> _concentrationRows() {
  return [
    for (var i = 1; i <= 4; i++) ...[
      numIn('c$i', 'Exposure $i: concentration', 'any unit', optional: i > 1),
      numIn('t$i', 'Exposure $i: duration', 'h', optional: i > 1),
    ],
  ];
}

List<FormulaInput> _roomInputs() => [
      numIn('len', 'Room length', 'm'),
      numIn('wid', 'Room width', 'm'),
      numIn('hgt', 'Room height', 'm'),
    ];

double _roomVolume(Map<String, double> v) {
  requirePositive(v['len']!, 'Length');
  requirePositive(v['wid']!, 'Width');
  requirePositive(v['hgt']!, 'Height');
  return v['len']! * v['wid']! * v['hgt']!;
}

double _molarVolume(Map<String, double> v) {
  requirePositive(v['mm']!, 'Molar mass');
  requirePositive(v['p']!, 'Pressure');
  final kelvin = v['t']! + 273.15;
  requirePositive(kelvin, 'Temperature in kelvin');
  return 8.314462618 * kelvin / v['p']!;
}

FormulaResult _lelResult(double percent, double lelVolumePercent) {
  return res(
    {'pct': percent, 'lelppm': lelVolumePercent * 10000},
    [
      if (percent >= 100)
        'At or above the LEL. Treat the atmosphere as flammable and follow your gas-testing procedure.',
    ],
  );
}
