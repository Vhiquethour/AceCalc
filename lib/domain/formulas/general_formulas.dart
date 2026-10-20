import 'dart:math' as math;

import '../entities/formula_def.dart';
import 'formula_helpers.dart';

const String _unitNote = 'Use the same length unit for every input. Areas and volumes are in that unit squared and cubed.';

final List<FormulaDef> generalFormulas = [
  FormulaDef(
    id: 'circle',
    title: 'Circle',
    pack: FormulaPack.general,
    formula: 'A = π × d² / 4      C = π × d',
    summary: 'Area and circumference from the diameter.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [numIn('d', 'Diameter', '')],
        outputs: [numOut('a', 'Area'), numOut('c', 'Circumference'), numOut('r', 'Radius')],
        compute: (v) {
          requireNonNegative(v['d']!, 'Diameter');
          return res({
            'a': math.pi * v['d']! * v['d']! / 4,
            'c': math.pi * v['d']!,
            'r': v['d']! / 2,
          });
        },
      ),
    ],
    notes: [_unitNote],
  ),
  FormulaDef(
    id: 'cylinder',
    title: 'Cylinder',
    pack: FormulaPack.general,
    formula: 'V = π × d² × h / 4',
    summary: 'Volume and surface areas of a cylinder.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [numIn('d', 'Diameter', ''), numIn('h', 'Height', '')],
        outputs: [
          numOut('vol', 'Volume'),
          numOut('side', 'Side area'),
          numOut('total', 'Total surface area'),
        ],
        compute: (v) {
          requireNonNegative(v['d']!, 'Diameter');
          requireNonNegative(v['h']!, 'Height');
          final end = math.pi * v['d']! * v['d']! / 4;
          final side = math.pi * v['d']! * v['h']!;
          return res({'vol': end * v['h']!, 'side': side, 'total': side + 2 * end});
        },
      ),
    ],
    notes: [_unitNote],
  ),
  FormulaDef(
    id: 'sphere',
    title: 'Sphere',
    pack: FormulaPack.general,
    formula: 'V = π × d³ / 6      A = π × d²',
    summary: 'Volume and surface area from the diameter.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [numIn('d', 'Diameter', '')],
        outputs: [numOut('vol', 'Volume'), numOut('area', 'Surface area')],
        compute: (v) {
          requireNonNegative(v['d']!, 'Diameter');
          return res({
            'vol': math.pi * v['d']! * v['d']! * v['d']! / 6,
            'area': math.pi * v['d']! * v['d']!,
          });
        },
      ),
    ],
    notes: [_unitNote],
  ),
  FormulaDef(
    id: 'box',
    title: 'Rectangular box',
    pack: FormulaPack.general,
    formula: 'V = L × W × H',
    summary: 'Volume and surface area of a box.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [numIn('l', 'Length', ''), numIn('w', 'Width', ''), numIn('h', 'Height', '')],
        outputs: [numOut('vol', 'Volume'), numOut('area', 'Surface area'), numOut('base', 'Base area')],
        compute: (v) {
          requireNonNegative(v['l']!, 'Length');
          requireNonNegative(v['w']!, 'Width');
          requireNonNegative(v['h']!, 'Height');
          return res({
            'vol': v['l']! * v['w']! * v['h']!,
            'area': 2 * (v['l']! * v['w']! + v['l']! * v['h']! + v['w']! * v['h']!),
            'base': v['l']! * v['w']!,
          });
        },
      ),
    ],
    notes: [_unitNote],
  ),
  FormulaDef(
    id: 'cone',
    title: 'Cone',
    pack: FormulaPack.general,
    formula: 'V = π × r² × h / 3',
    summary: 'Volume, slant height and surface areas of a cone.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [numIn('d', 'Base diameter', ''), numIn('h', 'Height', '')],
        outputs: [
          numOut('vol', 'Volume'),
          numOut('slant', 'Slant height'),
          numOut('side', 'Side area'),
          numOut('total', 'Total surface area'),
        ],
        compute: (v) {
          requireNonNegative(v['d']!, 'Diameter');
          requireNonNegative(v['h']!, 'Height');
          final r = v['d']! / 2;
          final slant = math.sqrt(r * r + v['h']! * v['h']!);
          final side = math.pi * r * slant;
          return res({
            'vol': math.pi * r * r * v['h']! / 3,
            'slant': slant,
            'side': side,
            'total': side + math.pi * r * r,
          });
        },
      ),
    ],
    notes: [_unitNote],
  ),
  FormulaDef(
    id: 'percentage_change',
    title: 'Percentage change',
    pack: FormulaPack.general,
    formula: 'Change (%) = (new − old) / old × 100',
    summary: 'Change between two values, or a value after a percentage change.',
    modes: [
      FormulaMode(
        label: 'Change',
        inputs: [numIn('old', 'Old value', ''), numIn('new', 'New value', '')],
        outputs: [numOut('pct', 'Change', '%'), numOut('diff', 'Difference'), numOut('ratio', 'Ratio (new / old)')],
        compute: (v) {
          if (v['old']! == 0) throw const FormulaException('The old value cannot be zero.');
          return res({
            'pct': (v['new']! - v['old']!) / v['old']! * 100,
            'diff': v['new']! - v['old']!,
            'ratio': v['new']! / v['old']!,
          });
        },
      ),
      FormulaMode(
        label: 'Apply a percentage',
        inputs: [numIn('value', 'Starting value', ''), numIn('pct', 'Change', '%')],
        outputs: [numOut('result', 'New value')],
        compute: (v) => res({'result': v['value']! * (1 + v['pct']! / 100)}),
      ),
    ],
  ),
  FormulaDef(
    id: 'pythagoras',
    title: 'Right-angled triangle',
    pack: FormulaPack.general,
    formula: 'c² = a² + b²',
    summary: 'Find the hypotenuse or a missing side.',
    modes: [
      FormulaMode(
        label: 'Hypotenuse',
        inputs: [numIn('a', 'Side a', ''), numIn('b', 'Side b', '')],
        outputs: [numOut('c', 'Hypotenuse c'), numOut('angle', 'Angle opposite a', '°')],
        compute: (v) {
          requirePositive(v['a']!, 'Side a');
          requirePositive(v['b']!, 'Side b');
          return res({
            'c': math.sqrt(v['a']! * v['a']! + v['b']! * v['b']!),
            'angle': radToDeg(math.atan(v['a']! / v['b']!)),
          });
        },
      ),
      FormulaMode(
        label: 'Missing side',
        inputs: [numIn('c', 'Hypotenuse c', ''), numIn('a', 'Known side a', '')],
        outputs: [numOut('b', 'Missing side b')],
        compute: (v) {
          requirePositive(v['a']!, 'Side a');
          if (!(v['c']! > v['a']!)) {
            throw const FormulaException('The hypotenuse must be longer than the known side.');
          }
          return res({'b': math.sqrt(v['c']! * v['c']! - v['a']! * v['a']!)});
        },
      ),
    ],
  ),
  FormulaDef(
    id: 'simple_payback',
    title: 'Simple payback',
    pack: FormulaPack.general,
    formula: 'Payback (years) = cost / annual saving',
    summary: 'How long a saving takes to repay an investment.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [numIn('cost', 'Investment cost', ''), numIn('saving', 'Saving per year', '')],
        outputs: [
          numOut('years', 'Payback period', 'years'),
          numOut('months', 'Payback period', 'months'),
          numOut('roi', 'Annual return', '%'),
        ],
        compute: (v) {
          requirePositive(v['cost']!, 'Cost');
          requirePositive(v['saving']!, 'Annual saving');
          final years = v['cost']! / v['saving']!;
          return res({
            'years': years,
            'months': years * 12,
            'roi': v['saving']! / v['cost']! * 100,
          });
        },
      ),
    ],
    notes: ['Ignores interest, inflation and equipment life.'],
  ),
];
