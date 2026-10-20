import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/number_formatter.dart';
import '../../domain/entities/formula_def.dart';
import 'app_card.dart';

class ResultsCard extends StatelessWidget {
  const ResultsCard({super.key, required this.outputs, required this.result});

  final List<FormulaOutput> outputs;
  final FormulaResult result;

  String _copyText() {
    final lines = <String>[];
    for (final output in outputs) {
      final value = result.values[output.key];
      if (value == null) continue;
      final unit = output.unit.isEmpty ? '' : ' ${output.unit}';
      lines.add('${output.label}: ${NumberFormatter.format(value)}$unit');
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = Theme.of(context).colorScheme.primary;
    final rows = <Widget>[];
    var first = true;

    for (final output in outputs) {
      final value = result.values[output.key];
      if (value == null) continue;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: first ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(output.label, style: TextStyle(fontSize: 12, color: palette.muted)),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 6,
                children: [
                  SelectableText(
                    NumberFormatter.format(value),
                    style: TextStyle(
                      fontSize: first ? 30 : 22,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                  if (output.unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        output.unit,
                        style: TextStyle(fontSize: 15, color: palette.muted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
      first = false;
    }

    for (final message in result.messages) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: palette.warning),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
            ],
          ),
        ),
      );
    }

    rows.add(
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _copyText()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Results copied')),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy results'),
        ),
      ),
    );

    return AppCard(
      highlight: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }
}
