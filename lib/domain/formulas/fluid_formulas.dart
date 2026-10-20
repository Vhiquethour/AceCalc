import 'dart:math' as math;

import '../entities/formula_def.dart';
import 'formula_helpers.dart';

const double _barrelM3 = 0.158987294928;
const double _usGallonsPerM3 = 264.172052358;
const double _psiToKpa = 6.894757293168;

/// Pipe or tank area in m² from a diameter in mm.
double _circleAreaFromMm(double diameterMm) {
  final d = diameterMm / 1000;
  return math.pi / 4 * d * d;
}

Map<String, double> _volumes(double m3) {
  return {
    'm3': m3,
    'l': m3 * 1000,
    'bbl': m3 / _barrelM3,
    'gal': m3 * _usGallonsPerM3,
  };
}

List<FormulaOutput> _volumeOutputs() => [
      numOut('m3', 'Volume', 'm³'),
      numOut('l', 'Volume', 'L'),
      numOut('bbl', 'Volume', 'bbl'),
      numOut('gal', 'Volume', 'US gal'),
    ];

final List<FormulaDef> fluidFormulas = [
  FormulaDef(
    id: 'hydrostatic_pressure',
    title: 'Hydrostatic pressure',
    pack: FormulaPack.fluids,
    formula: 'P = ρ × g × h',
    summary: 'Pressure at the bottom of a liquid column.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('rho', 'Fluid density', 'kg/m³', def: 1000),
          numIn('h', 'Height of column', 'm'),
          numIn('g', 'Gravity', 'm/s²', def: standardGravity),
        ],
        outputs: [
          numOut('kpa', 'Pressure', 'kPa'),
          numOut('bar', 'Pressure', 'bar'),
          numOut('psi', 'Pressure', 'psi'),
        ],
        compute: (v) {
          requirePositive(v['rho']!, 'Density');
          requirePositive(v['g']!, 'Gravity');
          final kpa = v['rho']! * v['g']! * v['h']! / 1000;
          return res({'kpa': kpa, 'bar': kpa / 100, 'psi': kpa / _psiToKpa});
        },
      ),
    ],
    notes: ['This is gauge pressure from the liquid only. Add surface pressure for absolute pressure.'],
  ),
  FormulaDef(
    id: 'drilling_hydrostatic',
    title: 'Drilling mud hydrostatic pressure',
    pack: FormulaPack.fluids,
    formula: 'P (psi) = 0.052 × mud weight (ppg) × TVD (ft)',
    summary: 'Oilfield units: pressure from mud weight and true vertical depth.',
    modes: [
      FormulaMode(
        label: 'Pressure',
        inputs: [numIn('mw', 'Mud weight', 'ppg'), numIn('tvd', 'True vertical depth', 'ft')],
        outputs: [
          numOut('psi', 'Hydrostatic pressure', 'psi'),
          numOut('grad', 'Pressure gradient', 'psi/ft'),
          numOut('kpa', 'Hydrostatic pressure', 'kPa'),
        ],
        compute: (v) {
          requirePositive(v['mw']!, 'Mud weight');
          requireNonNegative(v['tvd']!, 'Depth');
          final psi = 0.052 * v['mw']! * v['tvd']!;
          return res({'psi': psi, 'grad': 0.052 * v['mw']!, 'kpa': psi * _psiToKpa});
        },
      ),
      FormulaMode(
        label: 'Equivalent mud weight',
        inputs: [numIn('psi', 'Pressure', 'psi'), numIn('tvd', 'True vertical depth', 'ft')],
        outputs: [numOut('mw', 'Equivalent mud weight', 'ppg')],
        compute: (v) {
          requirePositive(v['tvd']!, 'Depth');
          return res({'mw': v['psi']! / (0.052 * v['tvd']!)});
        },
      ),
    ],
    notes: ['The constant 0.052 converts ppg and feet to psi. Use true vertical depth, not measured depth.'],
  ),
  FormulaDef(
    id: 'flow_velocity',
    title: 'Flow rate and velocity in a pipe',
    pack: FormulaPack.fluids,
    formula: 'Q = A × v',
    summary: 'Link flow rate, velocity and pipe inside diameter.',
    modes: [
      FormulaMode(
        label: 'Velocity',
        inputs: [numIn('q', 'Flow rate', 'm³/h'), numIn('d', 'Inside diameter', 'mm')],
        outputs: [numOut('v', 'Velocity', 'm/s'), numOut('area', 'Flow area', 'cm²')],
        compute: (v) {
          requireNonNegative(v['q']!, 'Flow rate');
          requirePositive(v['d']!, 'Diameter');
          final area = _circleAreaFromMm(v['d']!);
          return res({'v': v['q']! / 3600 / area, 'area': area * 1e4});
        },
      ),
      FormulaMode(
        label: 'Flow rate',
        inputs: [numIn('v', 'Velocity', 'm/s'), numIn('d', 'Inside diameter', 'mm')],
        outputs: [numOut('q', 'Flow rate', 'm³/h'), numOut('ls', 'Flow rate', 'L/s')],
        compute: (v) {
          requireNonNegative(v['v']!, 'Velocity');
          requirePositive(v['d']!, 'Diameter');
          final flow = v['v']! * _circleAreaFromMm(v['d']!);
          return res({'q': flow * 3600, 'ls': flow * 1000});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'reynolds_number',
    title: 'Reynolds number',
    pack: FormulaPack.fluids,
    formula: 'Re = ρ × v × D / μ',
    summary: 'Flow regime in a pipe.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('rho', 'Fluid density', 'kg/m³', def: 1000),
          numIn('v', 'Velocity', 'm/s'),
          numIn('d', 'Inside diameter', 'mm'),
          numIn('mu', 'Dynamic viscosity', 'cP', def: 1),
        ],
        outputs: [numOut('re', 'Reynolds number')],
        compute: (v) {
          requirePositive(v['rho']!, 'Density');
          requirePositive(v['d']!, 'Diameter');
          requirePositive(v['mu']!, 'Viscosity');
          final re = v['rho']! * v['v']!.abs() * (v['d']! / 1000) / (v['mu']! / 1000);
          final String regime;
          if (re < 2300) {
            regime = 'Laminar flow (Re below about 2300).';
          } else if (re < 4000) {
            regime = 'Transitional flow (Re about 2300 to 4000).';
          } else {
            regime = 'Turbulent flow (Re above about 4000).';
          }
          return res({'re': re}, [regime]);
        },
      ),
    ],
    notes: ['Water at 20 °C has a dynamic viscosity of about 1 cP.'],
  ),
  FormulaDef(
    id: 'friction_factor',
    title: 'Friction factor (Swamee–Jain)',
    pack: FormulaPack.fluids,
    formula: 'f = 0.25 / [log10(ε/(3.7D) + 5.74/Re^0.9)]²',
    summary: 'Darcy friction factor for turbulent flow. Laminar flow uses f = 64 / Re.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('re', 'Reynolds number', ''),
          numIn('eps', 'Pipe roughness ε', 'mm', def: 0.045),
          numIn('d', 'Inside diameter', 'mm'),
        ],
        outputs: [numOut('f', 'Darcy friction factor')],
        compute: (v) {
          final re = v['re']!;
          requirePositive(re, 'Reynolds number');
          requireNonNegative(v['eps']!, 'Roughness');
          requirePositive(v['d']!, 'Diameter');
          if (re < 2300) {
            return res(
              {'f': 64 / re},
              ['Laminar flow: f = 64 / Re. Roughness has no effect.'],
            );
          }
          final relative = v['eps']! / v['d']!;
          final term = relative / 3.7 + 5.74 / math.pow(re, 0.9);
          final f = 0.25 / math.pow(log10(term), 2);
          final messages = <String>[];
          if (re < 5000 || re > 1e8 || relative < 1e-6 || relative > 1e-2) {
            messages.add(
              'Outside the range where Swamee–Jain is accurate '
              '(5000 ≤ Re ≤ 10⁸ and 10⁻⁶ ≤ ε/D ≤ 10⁻²).',
            );
          }
          return res({'f': f}, messages);
        },
      ),
    ],
    notes: ['Commercial steel pipe is about 0.045 mm rough. Drawn tubing is about 0.0015 mm.'],
  ),
  FormulaDef(
    id: 'head_loss',
    title: 'Pipe head loss (Darcy–Weisbach)',
    pack: FormulaPack.fluids,
    formula: 'hf = f × (L / D) × v² / (2g)',
    summary: 'Friction loss along a straight pipe.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('f', 'Friction factor', ''),
          numIn('l', 'Pipe length', 'm'),
          numIn('d', 'Inside diameter', 'mm'),
          numIn('v', 'Velocity', 'm/s'),
          numIn('rho', 'Fluid density', 'kg/m³', def: 1000),
        ],
        outputs: [numOut('hf', 'Head loss', 'm'), numOut('dp', 'Pressure drop', 'kPa')],
        compute: (v) {
          requireNonNegative(v['f']!, 'Friction factor');
          requireNonNegative(v['l']!, 'Length');
          requirePositive(v['d']!, 'Diameter');
          requirePositive(v['rho']!, 'Density');
          final head = v['f']! * (v['l']! / (v['d']! / 1000)) * v['v']! * v['v']! / (2 * standardGravity);
          return res({'hf': head, 'dp': v['rho']! * standardGravity * head / 1000});
        },
      ),
    ],
    notes: ['Straight pipe only. Add fittings and valves separately with loss coefficients.'],
  ),
  FormulaDef(
    id: 'pump_power',
    title: 'Pump power',
    pack: FormulaPack.fluids,
    formula: 'P = ρ × g × Q × H / η',
    summary: 'Hydraulic and shaft power needed for a pump duty.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('rho', 'Fluid density', 'kg/m³', def: 1000),
          numIn('q', 'Flow rate', 'm³/h'),
          numIn('h', 'Total head', 'm'),
          numIn('eta', 'Pump efficiency', '%', def: 65),
        ],
        outputs: [numOut('hyd', 'Hydraulic power', 'kW'), numOut('shaft', 'Shaft power', 'kW')],
        compute: (v) {
          requirePositive(v['rho']!, 'Density');
          requireNonNegative(v['q']!, 'Flow rate');
          requireNonNegative(v['h']!, 'Head');
          requireRange(v['eta']!, 'Efficiency', 1, 100);
          final hydraulic = v['rho']! * standardGravity * (v['q']! / 3600) * v['h']! / 1000;
          return res({'hyd': hydraulic, 'shaft': hydraulic / (v['eta']! / 100)});
        },
      ),
    ],
    notes: ['Add a margin for the motor. Motor efficiency and service factor are not included.'],
  ),
  FormulaDef(
    id: 'api_gravity',
    title: 'API gravity and specific gravity',
    pack: FormulaPack.fluids,
    formula: '°API = 141.5 / SG − 131.5',
    summary: 'Convert between specific gravity (60 °F) and API gravity.',
    modes: [
      FormulaMode(
        label: 'API from SG',
        inputs: [numIn('sg', 'Specific gravity (60/60 °F)', '')],
        outputs: [numOut('api', 'API gravity', '°API'), numOut('rho', 'Density', 'kg/m³')],
        compute: (v) {
          requirePositive(v['sg']!, 'Specific gravity');
          return res({'api': 141.5 / v['sg']! - 131.5, 'rho': v['sg']! * 999.016});
        },
      ),
      FormulaMode(
        label: 'SG from API',
        inputs: [numIn('api', 'API gravity', '°API')],
        outputs: [numOut('sg', 'Specific gravity', ''), numOut('rho', 'Density', 'kg/m³')],
        compute: (v) {
          if (!(v['api']! > -131.5)) {
            throw const FormulaException('API gravity must be above −131.5.');
          }
          final sg = 141.5 / (v['api']! + 131.5);
          return res({'sg': sg, 'rho': sg * 999.016});
        },
      ),
    ],
    notes: ['Water is 10 °API. Light crude is above about 31 °API and heavy crude below about 22 °API.'],
  ),
  FormulaDef(
    id: 'tank_volume',
    title: 'Tank volume',
    pack: FormulaPack.fluids,
    formula: 'Vertical: V = π/4 × D² × h      Horizontal: V = segment area × L',
    summary: 'Liquid volume in a vertical or horizontal cylindrical tank.',
    modes: [
      FormulaMode(
        label: 'Vertical',
        inputs: [
          numIn('d', 'Tank diameter', 'm'),
          numIn('level', 'Liquid level', 'm'),
          numIn('height', 'Tank height', 'm', optional: true),
        ],
        outputs: [..._volumeOutputs(), numOut('pct', 'Tank fill', '%')],
        compute: (v) {
          requirePositive(v['d']!, 'Diameter');
          requireNonNegative(v['level']!, 'Liquid level');
          final volume = math.pi / 4 * v['d']! * v['d']! * v['level']!;
          final values = _volumes(volume);
          final messages = <String>[];
          final height = v['height'];
          if (height != null) {
            requirePositive(height, 'Tank height');
            values['pct'] = v['level']! / height * 100;
            if (v['level']! > height) messages.add('The liquid level is above the tank height.');
          }
          return res(values, messages);
        },
      ),
      FormulaMode(
        label: 'Horizontal',
        inputs: [
          numIn('d', 'Tank diameter', 'm'),
          numIn('len', 'Tank length', 'm'),
          numIn('fill', 'Liquid height', 'm'),
        ],
        outputs: [..._volumeOutputs(), numOut('pct', 'Tank fill', '%')],
        compute: (v) {
          final d = v['d']!;
          final h = v['fill']!;
          requirePositive(d, 'Diameter');
          requirePositive(v['len']!, 'Length');
          requireRange(h, 'Liquid height', 0, d);
          final r = d / 2;
          final ratio = ((r - h) / r).clamp(-1.0, 1.0);
          final segment = r * r * math.acos(ratio) - (r - h) * math.sqrt(math.max(0.0, 2 * r * h - h * h));
          final volume = segment * v['len']!;
          final total = math.pi * r * r * v['len']!;
          final values = _volumes(volume);
          values['pct'] = volume / total * 100;
          return res(values);
        },
      ),
    ],
    notes: ['Flat ends only. Dished or domed heads add volume that is not included.'],
  ),
  FormulaDef(
    id: 'gas_law',
    title: 'Gas law',
    pack: FormulaPack.fluids,
    formula: 'P1·V1 / T1 = P2·V2 / T2      P·V = n·R·T',
    summary: 'Gas volume at new conditions, or the amount of gas in a volume.',
    modes: [
      FormulaMode(
        label: 'Combined gas law',
        inputs: [
          numIn('p1', 'Initial pressure (absolute)', 'kPa'),
          numIn('v1', 'Initial volume', 'm³'),
          numIn('t1', 'Initial temperature', '°C'),
          numIn('p2', 'Final pressure (absolute)', 'kPa', def: 101.325),
          numIn('t2', 'Final temperature', '°C', def: 15),
        ],
        outputs: [numOut('v2', 'Final volume', 'm³')],
        compute: (v) {
          requirePositive(v['p1']!, 'Initial pressure');
          requirePositive(v['p2']!, 'Final pressure');
          requireNonNegative(v['v1']!, 'Initial volume');
          final t1 = v['t1']! + 273.15;
          final t2 = v['t2']! + 273.15;
          requirePositive(t1, 'Initial temperature in kelvin');
          requirePositive(t2, 'Final temperature in kelvin');
          return res({'v2': v['p1']! * v['v1']! * t2 / (t1 * v['p2']!)});
        },
      ),
      FormulaMode(
        label: 'Amount of gas',
        inputs: [
          numIn('p', 'Pressure (absolute)', 'kPa', def: 101.325),
          numIn('vol', 'Volume', 'm³'),
          numIn('t', 'Temperature', '°C', def: 25),
        ],
        outputs: [numOut('n', 'Amount of gas', 'mol'), numOut('kmol', 'Amount of gas', 'kmol')],
        compute: (v) {
          requirePositive(v['p']!, 'Pressure');
          requireNonNegative(v['vol']!, 'Volume');
          final kelvin = v['t']! + 273.15;
          requirePositive(kelvin, 'Temperature in kelvin');
          final moles = v['p']! * 1000 * v['vol']! / (8.314462618 * kelvin);
          return res({'n': moles, 'kmol': moles / 1000});
        },
      ),
    ],
    notes: ['Use absolute pressure, not gauge pressure. Ideal gas behaviour is assumed.'],
  ),
  FormulaDef(
    id: 'hvac_sensible',
    title: 'HVAC sensible heat load',
    pack: FormulaPack.fluids,
    formula: 'Q (BTU/h) = 1.08 × CFM × ΔT (°F)',
    summary: 'Heat carried by an air stream.',
    modes: [
      FormulaMode(
        label: 'Imperial',
        inputs: [numIn('cfm', 'Airflow', 'CFM'), numIn('dt', 'Temperature difference', '°F')],
        outputs: [
          numOut('btuh', 'Heat load', 'BTU/h'),
          numOut('kw', 'Heat load', 'kW'),
          numOut('tr', 'Heat load', 'TR'),
        ],
        compute: (v) {
          requireNonNegative(v['cfm']!, 'Airflow');
          final load = 1.08 * v['cfm']! * v['dt']!;
          return res({'btuh': load, 'kw': load * 0.00029307107, 'tr': load / 12000});
        },
      ),
      FormulaMode(
        label: 'Metric',
        inputs: [numIn('flow', 'Airflow', 'm³/s'), numIn('dt', 'Temperature difference', 'K')],
        outputs: [numOut('kw', 'Heat load', 'kW'), numOut('btuh', 'Heat load', 'BTU/h')],
        compute: (v) {
          requireNonNegative(v['flow']!, 'Airflow');
          final kw = 1.2 * 1.006 * v['flow']! * v['dt']!;
          return res({'kw': kw, 'btuh': kw / 0.00029307107});
        },
      ),
    ],
    notes: ['Sensible heat only, for standard air. Latent (moisture) load is not included.'],
  ),
  FormulaDef(
    id: 'pipe_volume',
    title: 'Pipe volume',
    pack: FormulaPack.fluids,
    formula: 'V = π/4 × D² × L',
    summary: 'Internal volume of a pipe run.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [numIn('d', 'Inside diameter', 'mm'), numIn('l', 'Pipe length', 'm')],
        outputs: [..._volumeOutputs(), numOut('perm', 'Volume per metre', 'L/m')],
        compute: (v) {
          requirePositive(v['d']!, 'Diameter');
          requireNonNegative(v['l']!, 'Length');
          final area = _circleAreaFromMm(v['d']!);
          final values = _volumes(area * v['l']!);
          values['perm'] = area * 1000;
          return res(values);
        },
      ),
    ],
  ),
];
