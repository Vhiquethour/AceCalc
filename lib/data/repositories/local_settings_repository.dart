import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  static const String _themeKey = 'theme_mode';

  @override
  Future<AppThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_themeKey);
      for (final mode in AppThemeMode.values) {
        if (mode.name == name) return mode;
      }
    } catch (_) {
      // Fall back to the default if storage is unavailable.
    }
    return AppThemeMode.dark;
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}
