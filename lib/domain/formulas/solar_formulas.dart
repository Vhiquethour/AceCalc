import 'dart:math' as math;

import '../entities/formula_def.dart';
import 'formula_helpers.dart';
import 'standard_values.dart';

final List<FormulaDef> solarFormulas = [
  FormulaDef(
    id: 'solar_array_size',
    title: 'Solar array size',
    pack: FormulaPack.solar,
    formula: 'Array (W) = daily energy / (peak sun hours × system efficiency)',
    summary: 'Panel capacity needed to cover a daily energy demand.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('wh', 'Daily energy use', 'Wh'),
          numIn('psh', 'Peak sun hours per day', 'h', def: 5),
          numIn('eff', 'System efficiency', '%', def: 75),
          numIn('panel', 'Panel rating', 'W', def: 400),
        ],
        outputs: [numOut('w', 'Array size', 'W'), numOut('n', 'Number of panels')],
        compute: (v) {
          requireNonNegative(v['wh']!, 'Daily energy');
          requirePositive(v['psh']!, 'Peak sun hours');
          requireRange(v['eff']!, 'Efficiency', 1, 100);
          requirePositive(v['panel']!, 'Panel rating');
          final array = v['wh']! / (v['psh']! * v['eff']! / 100);
          return res({'w': array, 'n': (array / v['panel']!).ceilToDouble()});
        },
      ),
    ],
    notes: [
      'Efficiency covers wiring, controller, battery and inverter losses, dirt and heat.',
      'Peak sun hours depend on location and season. Use the worst month for off-grid systems.',
    ],
  ),
  FormulaDef(
    id: 'battery_bank_size',
    title: 'Battery bank size',
    pack: FormulaPack.solar,
    formula: 'Ah = daily energy × days of autonomy / (DoD × η × system voltage)',
    summary: 'Battery capacity for a daily demand and days of backup.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('wh', 'Daily energy use', 'Wh'),
          numIn('days', 'Days of autonomy', 'days', def: 1),
          numIn('dod', 'Usable depth of discharge', '%', def: 80),
          numIn('eff', 'Battery and inverter efficiency', '%', def: 90),
          numIn('vs', 'System voltage', 'V', def: 24),
        ],
        outputs: [numOut('ah', 'Battery capacity', 'Ah'), numOut('wh', 'Nominal energy', 'Wh')],
        compute: (v) {
          requireNonNegative(v['wh']!, 'Daily energy');
          requirePositive(v['days']!, 'Days of autonomy');
          requireRange(v['dod']!, 'Depth of discharge', 1, 100);
          requireRange(v['eff']!, 'Efficiency', 1, 100);
          requirePositive(v['vs']!, 'System voltage');
          final ah = v['wh']! * v['days']! / (v['dod']! / 100 * v['eff']! / 100 * v['vs']!);
          return res({'ah': ah, 'wh': ah * v['vs']!});
        },
      ),
    ],
    notes: ['Lead-acid batteries usually allow a lower depth of discharge than lithium.'],
  ),
  FormulaDef(
    id: 'led_resistor',
    title: 'LED series resistor',
    pack: FormulaPack.solar,
    formula: 'R = (Vs − Vf) / I',
    summary: 'Current-limiting resistor for an LED, with the next E12 value.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('vs', 'Supply voltage', 'V', def: 5),
          numIn('vf', 'LED forward voltage', 'V', def: 2),
          numIn('i', 'LED current', 'mA', def: 10),
        ],
        outputs: [
          numOut('r', 'Calculated resistance', 'Ω'),
          numOut('std', 'Next E12 value up', 'Ω'),
          numOut('p', 'Resistor power', 'mW'),
        ],
        compute: (v) {
          requirePositive(v['i']!, 'LED current');
          if (!(v['vs']! > v['vf']!)) {
            throw const FormulaException('The supply voltage must be above the LED forward voltage.');
          }
          final drop = v['vs']! - v['vf']!;
          final resistance = drop / (v['i']! / 1000);
          return res({
            'r': resistance,
            'std': StandardValues.nextE12(resistance),
            'p': drop * v['i']!,
          });
        },
      ),
    ],
    notes: [
      'Round up to the next standard value so the current is not above the target.',
      'Typical forward voltage is about 2 V for red and 3 V for blue or white LEDs.',
    ],
  ),
  FormulaDef(
    id: 'adc_voltage',
    title: 'ADC reading to voltage',
    pack: FormulaPack.solar,
    formula: 'V = reading × Vref / (2^bits − 1)',
    summary: 'Convert a raw microcontroller ADC value to volts.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('reading', 'ADC reading', 'counts'),
          numIn('bits', 'Resolution', 'bits', def: 12),
          numIn('vref', 'Reference voltage', 'V', def: 3.3),
        ],
        outputs: [numOut('v', 'Voltage', 'V'), numOut('step', 'Step size', 'mV')],
        compute: (v) {
          final bits = v['bits']!.roundToDouble();
          requireRange(bits, 'Resolution', 1, 32);
          requirePositive(v['vref']!, 'Reference voltage');
          final maximum = math.pow(2, bits) - 1;
          requireRange(v['reading']!, 'Reading', 0, maximum.toDouble());
          final step = v['vref']! / maximum;
          return res({'v': v['reading']! * step, 'step': step * 1000});
        },
      ),
    ],
    notes: ['ESP32 ADCs are not linear near the ends of their range. Calibrate if accuracy matters.'],
  ),
  FormulaDef(
    id: 'pwm_average',
    title: 'PWM average voltage',
    pack: FormulaPack.solar,
    formula: 'Vavg = duty × Vhigh',
    summary: 'Average output of a PWM signal, and the on-time if the frequency is known.',
    modes: [
      FormulaMode(
        label: 'Calculate',
        inputs: [
          numIn('duty', 'Duty cycle', '%', def: 50),
          numIn('vhigh', 'High level', 'V', def: 3.3),
          numIn('freq', 'Frequency', 'Hz', optional: true),
        ],
        outputs: [
          numOut('vavg', 'Average voltage', 'V'),
          numOut('on', 'On time', 'µs'),
          numOut('period', 'Period', 'µs'),
        ],
        compute: (v) {
          requireRange(v['duty']!, 'Duty cycle', 0, 100);
          final values = <String, double>{'vavg': v['duty']! / 100 * v['vhigh']!};
          final frequency = v['freq'];
          if (frequency != null) {
            requirePositive(frequency, 'Frequency');
            final period = 1e6 / frequency;
            values['period'] = period;
            values['on'] = period * v['duty']! / 100;
          }
          return res(values);
        },
      ),
    ],
    notes: ['The average only applies after filtering. A motor or LED sees the pulses unless it is filtered.'],
  ),
];
