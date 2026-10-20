import '../../domain/entities/unit_category.dart';
import 'unit_helpers.dart';

final List<UnitCategory> fluidCategories = [
  UnitCategory(
    id: 'flow',
    name: 'Volumetric flow',
    group: 'Fluids',
    iconKey: 'flow',
    defaultFromIndex: 2,
    defaultToIndex: 4,
    units: [
      linearUnit('ls', 'Litre per second', 'L/s', 1),
      linearUnit('lmin', 'Litre per minute', 'L/min', 1 / 60),
      linearUnit('m3h', 'Cubic metre per hour', 'm³/h', 1000 / 3600),
      linearUnit('m3s', 'Cubic metre per second', 'm³/s', 1000),
      linearUnit('gpm', 'US gallon per minute', 'gpm', 3.785411784 / 60),
      linearUnit('bpd', 'Barrel per day', 'bbl/day', 158.987294928 / 86400),
      linearUnit('cfm', 'Cubic foot per minute', 'CFM', 28.316846592 / 60),
    ],
  ),
  UnitCategory(
    id: 'massflow',
    name: 'Mass flow',
    group: 'Fluids',
    iconKey: 'massflow',
    defaultFromIndex: 1,
    defaultToIndex: 3,
    units: [
      linearUnit('kgs', 'Kilogram per second', 'kg/s', 1),
      linearUnit('kgh', 'Kilogram per hour', 'kg/h', 1 / 3600),
      linearUnit('th', 'Tonne per hour', 't/h', 1000 / 3600),
      linearUnit('lbh', 'Pound per hour', 'lb/h', 0.45359237 / 3600),
    ],
  ),
  UnitCategory(
    id: 'viscosity',
    name: 'Dynamic viscosity',
    group: 'Fluids',
    iconKey: 'viscosity',
    defaultFromIndex: 0,
    defaultToIndex: 1,
    note: 'One centipoise (cP) equals one millipascal second (mPa·s).',
    units: [
      linearUnit('pas', 'Pascal second', 'Pa·s', 1),
      linearUnit('cp', 'Centipoise', 'cP', 0.001),
      linearUnit('poise', 'Poise', 'P', 0.1),
    ],
  ),
  UnitCategory(
    id: 'kinematic',
    name: 'Kinematic viscosity',
    group: 'Fluids',
    iconKey: 'viscosity',
    defaultFromIndex: 0,
    defaultToIndex: 1,
    units: [
      linearUnit('m2s', 'Square metre per second', 'm²/s', 1),
      linearUnit('cst', 'Centistokes', 'cSt', 1e-6),
      linearUnit('st', 'Stokes', 'St', 1e-4),
    ],
  ),
];
