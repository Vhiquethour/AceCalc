import 'package:flutter/material.dart';

import '../../domain/repositories/settings_repository.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._repository);

  final SettingsRepository _repository;
  AppThemeMode _selected = AppThemeMode.dark;

  AppThemeMode get selected => _selected;

  ThemeMode get mode {
    switch (_selected) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    _selected = await _repository.loadThemeMode();
    notifyListeners();
  }

  Future<void> select(AppThemeMode mode) async {
    if (mode == _selected) return;
    _selected = mode;
    notifyListeners();
    await _repository.saveThemeMode(mode);
  }
}
