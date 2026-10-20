import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/unit_def.dart';

class UnitPicker extends StatelessWidget {
  const UnitPicker({
    super.key,
    required this.units,
    required this.selected,
    required this.onSelected,
  });

  final List<UnitDef> units;
  final UnitDef selected;
  final ValueChanged<UnitDef> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return PopupMenuButton<UnitDef>(
      tooltip: 'Choose unit',
      initialValue: selected,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final unit in units)
          PopupMenuItem<UnitDef>(
            value: unit,
            child: Text('${unit.symbol}   ${unit.name}'),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: palette.chip,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.symbol,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 22),
          ],
        ),
      ),
    );
  }
}
