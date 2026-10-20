import '../../domain/entities/unit_category.dart';
import 'unit_helpers.dart';

final List<UnitCategory> otherCategories = [
  UnitCategory(
    id: 'conductivity',
    name: 'Thermal conductivity',
    group: 'Other',
    iconKey: 'conductivity',
    defaultFromIndex: 0,
    defaultToIndex: 1,
    units: [
      linearUnit('wmk', 'Watt per metre kelvin', 'W/(m·K)', 1),
      linearUnit('btuhftf', 'BTU per hour foot °F', 'BTU/(h·ft·°F)', 1.730735),
      linearUnit('btuinhft2f', 'BTU inch per hour ft² °F', 'BTU·in/(h·ft²·°F)', 0.1442279),
    ],
  ),
  UnitCategory(
    id: 'specificheat',
    name: 'Specific heat',
    group: 'Other',
    iconKey: 'specificheat',
    defaultFromIndex: 0,
    defaultToIndex: 2,
    units: [
      linearUnit('kjkgk', 'Kilojoule per kilogram kelvin', 'kJ/(kg·K)', 1),
      linearUnit('jkgk', 'Joule per kilogram kelvin', 'J/(kg·K)', 0.001),
      linearUnit('btulbf', 'BTU per pound °F', 'BTU/(lb·°F)', 4.1868),
    ],
  ),
  UnitCategory(
    id: 'illuminance',
    name: 'Illuminance',
    group: 'Other',
    iconKey: 'illuminance',
    defaultFromIndex: 0,
    defaultToIndex: 1,
    units: [
      linearUnit('lux', 'Lux', 'lx', 1),
      linearUnit('fc', 'Foot-candle', 'fc', 10.7639104),
    ],
  ),
  UnitCategory(
    id: 'concentration',
    name: 'Concentration',
    group: 'Other',
    iconKey: 'concentration',
    defaultFromIndex: 1,
    defaultToIndex: 2,
    note: 'Milligram per litre and gram per litre are treated as ppm and '
        '1000 ppm, which holds for dilute water solutions only. To convert '
        'gas ppm to mg/m³, use the gas conversion formula in the Health and '
        'safety pack.',
    units: [
      linearUnit('ppb', 'Parts per billion', 'ppb', 0.001),
      linearUnit('ppm', 'Parts per million', 'ppm', 1),
      linearUnit('pct', 'Per cent', '%', 10000),
      linearUnit('mgl', 'Milligram per litre (water)', 'mg/L', 1),
      linearUnit('gl', 'Gram per litre (water)', 'g/L', 1000),
    ],
  ),
];
