import 'dart:math' as math;

import '../../domain/entities/unit_category.dart';
import '../../domain/entities/unit_def.dart';
import 'unit_helpers.dart';

/// Conductor area in mm² from an AWG number (AWG 0000 is −3).
double _awgToArea(double awg) {
  final diameter = 0.127 * math.pow(92, (36 - awg) / 39);
  return math.pi / 4 * diameter * diameter;
}

double _areaToAwg(double area) {
  if (area <= 0) return double.nan;
  final diameter = math.sqrt(4 * area / math.pi);
  return 36 - 39 * math.log(diameter / 0.127) / math.log(92);
}

final List<UnitCategory> electricalCategories = [
  UnitCategory(
    id: 'voltage',
    name: 'Voltage',
    group: 'Electrical',
    iconKey: 'voltage',
    defaultFromIndex: 2,
    defaultToIndex: 1,
    units: [
      linearUnit('uv', 'Microvolt', 'µV', 1e-6),
      linearUnit('mv', 'Millivolt', 'mV', 0.001),
      linearUnit('v', 'Volt', 'V', 1),
      linearUnit('kv', 'Kilovolt', 'kV', 1000),
    ],
  ),
  UnitCategory(
    id: 'current',
    name: 'Current',
    group: 'Electrical',
    iconKey: 'current',
    defaultFromIndex: 2,
    defaultToIndex: 1,
    units: [
      linearUnit('ua', 'Microampere', 'µA', 1e-6),
      linearUnit('ma', 'Milliampere', 'mA', 0.001),
      linearUnit('a', 'Ampere', 'A', 1),
      linearUnit('ka', 'Kiloampere', 'kA', 1000),
    ],
  ),
  UnitCategory(
    id: 'resistance',
    name: 'Resistance',
    group: 'Electrical',
    iconKey: 'resistance',
    defaultFromIndex: 2,
    defaultToIndex: 1,
    units: [
      linearUnit('mohm', 'Milliohm', 'mΩ', 0.001),
      linearUnit('ohm', 'Ohm', 'Ω', 1),
      linearUnit('kohm', 'Kilohm', 'kΩ', 1000),
      linearUnit('megohm', 'Megohm', 'MΩ', 1e6),
    ],
  ),
  UnitCategory(
    id: 'capacitance',
    name: 'Capacitance',
    group: 'Electrical',
    iconKey: 'capacitance',
    defaultFromIndex: 2,
    defaultToIndex: 1,
    units: [
      linearUnit('pf', 'Picofarad', 'pF', 1e-12),
      linearUnit('nf', 'Nanofarad', 'nF', 1e-9),
      linearUnit('uf', 'Microfarad', 'µF', 1e-6),
      linearUnit('mf', 'Millifarad', 'mF', 1e-3),
      linearUnit('f', 'Farad', 'F', 1),
    ],
  ),
  UnitCategory(
    id: 'inductance',
    name: 'Inductance',
    group: 'Electrical',
    iconKey: 'inductance',
    defaultFromIndex: 1,
    defaultToIndex: 0,
    units: [
      linearUnit('uh', 'Microhenry', 'µH', 1e-6),
      linearUnit('mh', 'Millihenry', 'mH', 1e-3),
      linearUnit('h', 'Henry', 'H', 1),
    ],
  ),
  UnitCategory(
    id: 'charge',
    name: 'Battery charge',
    group: 'Electrical',
    iconKey: 'charge',
    defaultFromIndex: 1,
    defaultToIndex: 0,
    units: [
      linearUnit('mah', 'Milliampere hour', 'mAh', 1),
      linearUnit('ah', 'Ampere hour', 'Ah', 1000),
      linearUnit('c', 'Coulomb', 'C', 1 / 3.6),
    ],
  ),
  UnitCategory(
    id: 'wire',
    name: 'Wire size',
    group: 'Electrical',
    iconKey: 'wire',
    defaultFromIndex: 1,
    defaultToIndex: 0,
    note: 'Conductor cross-section area. AWG 0000 is entered as −3, '
        '000 as −2 and 00 as −1. Smaller AWG numbers mean thicker wire.',
    units: [
      linearUnit('mm2', 'Square millimetre', 'mm²', 1),
      UnitDef(
        id: 'awg',
        name: 'American wire gauge',
        symbol: 'AWG',
        toBase: _awgToArea,
        fromBase: _areaToAwg,
      ),
      linearUnit('kcmil', 'Thousand circular mils', 'kcmil', 0.5067075),
    ],
  ),
];
