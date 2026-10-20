enum AppThemeMode { dark, light, system }

abstract interface class SettingsRepository {
  Future<AppThemeMode> loadThemeMode();
  Future<void> saveThemeMode(AppThemeMode mode);
}
