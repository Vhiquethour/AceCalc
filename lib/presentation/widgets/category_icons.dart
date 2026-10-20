import 'package:flutter/material.dart';

import '../../domain/entities/formula_def.dart';

abstract final class CategoryIcons {
  static IconData forKey(String key) {
    switch (key) {
      case 'length':
        return Icons.straighten;
      case 'area':
        return Icons.crop_square;
      case 'volume':
        return Icons.view_in_ar;
      case 'mass':
        return Icons.scale;
      case 'density':
        return Icons.grain;
      case 'temperature':
        return Icons.thermostat;
      case 'time':
        return Icons.schedule;
      case 'angle':
        return Icons.architecture;
      case 'pressure':
        return Icons.speed;
      case 'force':
        return Icons.north_east;
      case 'torque':
        return Icons.rotate_right;
      case 'energy':
        return Icons.battery_charging_full;
      case 'power':
        return Icons.bolt;
      case 'velocity':
        return Icons.fast_forward;
      case 'rotation':
        return Icons.autorenew;
      case 'flow':
        return Icons.water_drop;
      case 'massflow':
        return Icons.waves;
      case 'viscosity':
        return Icons.opacity;
      case 'voltage':
        return Icons.electric_bolt;
      case 'current':
        return Icons.flash_on;
      case 'resistance':
        return Icons.settings_input_component;
      case 'capacitance':
        return Icons.battery_full;
      case 'inductance':
        return Icons.all_inclusive;
      case 'charge':
        return Icons.battery_charging_full;
      case 'wire':
        return Icons.cable;
      case 'conductivity':
        return Icons.device_thermostat;
      case 'specificheat':
        return Icons.whatshot;
      case 'illuminance':
        return Icons.light_mode;
      case 'concentration':
        return Icons.science;
      default:
        return Icons.calculate;
    }
  }

  static IconData forPack(FormulaPack pack) {
    switch (pack) {
      case FormulaPack.electrical:
        return Icons.bolt;
      case FormulaPack.mechanical:
        return Icons.settings;
      case FormulaPack.fluids:
        return Icons.water_drop;
      case FormulaPack.safety:
        return Icons.health_and_safety;
      case FormulaPack.solar:
        return Icons.wb_sunny;
      case FormulaPack.general:
        return Icons.functions;
    }
  }
}
