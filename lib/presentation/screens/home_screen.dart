import 'package:flutter/material.dart';

import '../../core/constants/app_info.dart';
import '../../domain/repositories/unit_repository.dart';
import '../controllers/theme_controller.dart';
import 'convert_tab.dart';
import 'formulas_tab.dart';
import 'settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.themeController,
    required this.unitRepository,
  });

  final ThemeController themeController;
  final UnitRepository unitRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.name),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune),
            onPressed: () => showSettingsSheet(context, widget.themeController),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          ConvertTab(unitRepository: widget.unitRepository),
          const FormulasTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Convert'),
          NavigationDestination(icon: Icon(Icons.functions), label: 'Formulas'),
        ],
      ),
    );
  }
}
