import 'dart:math' as math;

import '../../domain/entities/unit_category.dart';
import '../../domain/entities/unit_def.dart';
import 'unit_helpers.dart';

/// Density of water at 60 °F in kg/m³, the reference used for specific
/// gravity and API gravity.
const double _waterDensity = 999.016;

double _apiToDensity(double api) {
  final denominator = api + 131.5;
  if (denominator <= 0) return double.nan;
  return 141.5 / denominator * _waterDensity;
}

double _densityToApi(double density) {
  if (density <= 0) return double.nan;
  return 141.5 / (density / _waterDensity) - 131.5;
}

final List<UnitCategory> basicCategories = [
  UnitCategory(
    id: 'length',
    name: 'Length',
    group: 'Basics',
    iconKey: 'length',
    defaultFromIndex: 3,
    defaultToIndex: 6,
    units: [
      linearUnit('um', 'Micrometre', 'µm', 1e-6),
      linearUnit('mm', 'Millimetre', 'mm', 0.001),
      linearUnit('cm', 'Centimetre', 'cm', 0.01),
      linearUnit('m', 'Metre', 'm', 1),
      linearUnit('km', 'Kilometre', 'km', 1000),
      linearUnit('in', 'Inch', 'in', 0.0254),
      linearUnit('ft', 'Foot', 'ft', 0.3048),
      linearUnit('yd', 'Yard', 'yd', 0.9144),
      linearUnit('mi', 'Mile', 'mi', 1609.344),
      linearUnit('nmi', 'Nautical mile', 'nmi', 1852),
    ],
  ),
  UnitCategory(
    id: 'area',
    name: 'Area',
    group: 'Basics',
    iconKey: 'area',
    defaultFromIndex: 2,
    defaultToIndex: 5,
    units: [
      linearUnit('mm2', 'Square millimetre', 'mm²', 1e-6),
      linearUnit('cm2', 'Square centimetre', 'cm²', 1e-4),
      linearUnit('m2', 'Square metre', 'm²', 1),
      linearUnit('km2', 'Square kilometre', 'km²', 1e6),
      linearUnit('in2', 'Square inch', 'in²', 0.00064516),
      linearUnit('ft2', 'Square foot', 'ft²', 0.09290304),
      linearUnit('yd2', 'Square yard', 'yd²', 0.83612736),
      linearUnit('acre', 'Acre', 'acre', 4046.8564224),
      linearUnit('ha', 'Hectare', 'ha', 10000),
    ],
  ),
  UnitCategory(
    id: 'volume',
    name: 'Volume',
    group: 'Basics',
    iconKey: 'volume',
    defaultFromIndex: 1,
    defaultToIndex: 5,
    note: 'US and imperial gallons are different units. '
        'One oil barrel is 42 US gallons.',
    units: [
      linearUnit('ml', 'Millilitre', 'mL', 0.001),
      linearUnit('l', 'Litre', 'L', 1),
      linearUnit('m3', 'Cubic metre', 'm³', 1000),
      linearUnit('in3', 'Cubic inch', 'in³', 0.016387064),
      linearUnit('ft3', 'Cubic foot', 'ft³', 28.316846592),
      linearUnit('galus', 'US gallon', 'gal (US)', 3.785411784),
      linearUnit('galuk', 'Imperial gallon', 'gal (UK)', 4.54609),
      linearUnit('qtus', 'US quart', 'qt (US)', 0.946352946),
      linearUnit('flozus', 'US fluid ounce', 'fl oz (US)', 0.0295735295625),
      linearUnit('bbl', 'Oil barrel', 'bbl', 158.987294928),
    ],
  ),
  UnitCategory(
    id: 'mass',
    name: 'Mass',
    group: 'Basics',
    iconKey: 'mass',
    defaultFromIndex: 2,
    defaultToIndex: 4,
    note: 'The tonne (1000 kg), short ton (2000 lb) and long ton (2240 lb) '
        'are three different units.',
    units: [
      linearUnit('mg', 'Milligram', 'mg', 1e-6),
      linearUnit('g', 'Gram', 'g', 0.001),
      linearUnit('kg', 'Kilogram', 'kg', 1),
      linearUnit('t', 'Tonne', 't', 1000),
      linearUnit('lb', 'Pound', 'lb', 0.45359237),
      linearUnit('oz', 'Ounce', 'oz', 0.028349523125),
      linearUnit('ston', 'Short ton (US)', 'short ton', 907.18474),
      linearUnit('lton', 'Long ton (UK)', 'long ton', 1016.0469088),
    ],
  ),
  UnitCategory(
    id: 'density',
    name: 'Density',
    group: 'Basics',
    iconKey: 'density',
    defaultFromIndex: 0,
    defaultToIndex: 2,
    note: 'Specific gravity uses water at 60 °F (999.016 kg/m³) as the '
        'reference. API gravity is 141.5 / SG − 131.5.',
    units: [
      linearUnit('kgm3', 'Kilogram per cubic metre', 'kg/m³', 1),
      linearUnit('gcm3', 'Gram per cubic centimetre', 'g/cm³', 1000),
      linearUnit('lbft3', 'Pound per cubic foot', 'lb/ft³', 16.01846337),
      linearUnit('lbgal', 'Pound per US gallon', 'lb/gal', 119.826427),
      linearUnit('sg', 'Specific gravity (60 °F)', 'SG', _waterDensity),
      UnitDef(
        id: 'api',
        name: 'API gravity',
        symbol: '°API',
        toBase: _apiToDensity,
        fromBase: _densityToApi,
      ),
    ],
  ),
  UnitCategory(
    id: 'temperature',
    name: 'Temperature',
    group: 'Basics',
    iconKey: 'temperature',
    defaultFromIndex: 0,
    defaultToIndex: 1,
    minBase: 0,
    minBaseMessage: 'That value is below absolute zero.',
    note: 'Celsius and Fahrenheit use offsets, so these conversions are not '
        'simple multipliers. Use the Kelvin or Rankine scale for '
        'temperature differences.',
    units: [
      UnitDef(
        id: 'c',
        name: 'Celsius',
        symbol: '°C',
        toBase: (v) => v + 273.15,
        fromBase: (k) => k - 273.15,
      ),
      UnitDef(
        id: 'f',
        name: 'Fahrenheit',
        symbol: '°F',
        toBase: (v) => (v - 32) * 5 / 9 + 273.15,
        fromBase: (k) => (k - 273.15) * 9 / 5 + 32,
      ),
      linearUnit('k', 'Kelvin', 'K', 1),
      linearUnit('r', 'Rankine', '°R', 5 / 9),
    ],
  ),
  UnitCategory(
    id: 'time',
    name: 'Time',
    group: 'Basics',
    iconKey: 'time',
    defaultFromIndex: 3,
    defaultToIndex: 2,
    units: [
      linearUnit('ms', 'Millisecond', 'ms', 0.001),
      linearUnit('s', 'Second', 's', 1),
      linearUnit('min', 'Minute', 'min', 60),
      linearUnit('h', 'Hour', 'h', 3600),
      linearUnit('day', 'Day', 'day', 86400),
      linearUnit('week', 'Week', 'week', 604800),
    ],
  ),
  UnitCategory(
    id: 'angle',
    name: 'Angle',
    group: 'Basics',
    iconKey: 'angle',
    defaultFromIndex: 0,
    defaultToIndex: 1,
    units: [
      linearUnit('deg', 'Degree', '°', math.pi / 180),
      linearUnit('rad', 'Radian', 'rad', 1),
      linearUnit('arcmin', 'Arcminute', '′', math.pi / 10800),
      linearUnit('rev', 'Revolution', 'rev', 2 * math.pi),
    ],
  ),
];
