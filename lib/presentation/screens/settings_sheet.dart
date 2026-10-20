import 'package:flutter/material.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_palette.dart';
import '../../domain/repositories/settings_repository.dart';
import '../controllers/theme_controller.dart';
import '../widgets/section_header.dart';

Future<void> showSettingsSheet(BuildContext context, ThemeController controller) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _SettingsSheet(controller: controller),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode),
                      ),
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.phone_android),
                      ),
                    ],
                    selected: {controller.selected},
                    onSelectionChanged: (selection) => controller.select(selection.first),
                  ),
                ),
                const SectionHeader(title: 'About'),
                Text(
                  '${AppInfo.name} ${AppInfo.version}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  AppInfo.disclaimer,
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
