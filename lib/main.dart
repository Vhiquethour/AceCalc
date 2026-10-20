import 'package:flutter/widgets.dart';

import 'app.dart';
import 'data/repositories/local_settings_repository.dart';
import 'data/units/static_unit_repository.dart';
import 'presentation/controllers/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController(LocalSettingsRepository());
  await themeController.load();

  runApp(
    EngCalcApp(
      themeController: themeController,
      unitRepository: StaticUnitRepository(),
    ),
  );
}
