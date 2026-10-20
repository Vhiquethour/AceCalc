import 'package:flutter/material.dart';

import 'core/constants/app_info.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/unit_repository.dart';
import 'presentation/controllers/theme_controller.dart';
import 'presentation/screens/home_screen.dart';

class EngCalcApp extends StatelessWidget {
  const EngCalcApp({
    super.key,
    required this.themeController,
    required this.unitRepository,
  });

  final ThemeController themeController;
  final UnitRepository unitRepository;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: AppInfo.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.mode,
          home: HomeScreen(
            themeController: themeController,
            unitRepository: unitRepository,
          ),
        );
      },
    );
  }
}
