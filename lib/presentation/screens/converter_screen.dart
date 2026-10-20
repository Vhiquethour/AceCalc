import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/number_formatter.dart';
import '../../domain/entities/unit_category.dart';
import '../controllers/converter_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/number_field.dart';
import '../widgets/section_header.dart';
import '../widgets/unit_picker.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, required this.category});

  final UnitCategory category;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late final ConverterController _controller;
  late final TextEditingController _inputField;

  @override
  void initState() {
    super.initState();
    _controller = ConverterController(widget.category);
    _inputField = TextEditingController(text: _controller.input);
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputField.dispose();
    super.dispose();
  }

  void _copy(double? result) {
    final messenger = ScaffoldMessenger.of(context);
    if (result == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Nothing to copy yet')));
      return;
    }
    Clipboard.setData(ClipboardData(text: NumberFormatter.format(result)));
    messenger.showSnackBar(const SnackBar(content: Text('Result copied')));
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final result = _controller.result;
          final message = _controller.message;
          final reference = _controller.referenceValue;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From', style: TextStyle(fontSize: 12, color: palette.muted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NumberField(
                            controller: _inputField,
                            label: 'Value',
                            onChanged: _controller.setInput,
                          ),
                        ),
                        const SizedBox(width: 10),
                        UnitPicker(
                          units: category.units,
                          selected: _controller.from,
                          onSelected: _controller.setFrom,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Center(
                child: IconButton.filled(
                  tooltip: 'Swap units',
                  icon: const Icon(Icons.swap_vert),
                  onPressed: _controller.swap,
                ),
              ),
              AppCard(
                highlight: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To', style: TextStyle(fontSize: 12, color: palette.muted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            result == null ? '—' : NumberFormatter.format(result),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        UnitPicker(
                          units: category.units,
                          selected: _controller.to,
                          onSelected: _controller.setTo,
                        ),
                      ],
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(message, style: TextStyle(color: scheme.error)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reference == null
                          ? ''
                          : '1 ${_controller.from.symbol} = '
                              '${NumberFormatter.format(reference)} ${_controller.to.symbol}',
                      style: TextStyle(color: palette.muted),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _copy(result),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy result'),
                  ),
                ],
              ),
              if (category.note != null) ...[
                const SizedBox(height: 8),
                DisclaimerNote(text: category.note!),
              ],
              const SectionHeader(title: 'All units'),
              _AllUnits(controller: _controller),
            ],
          );
        },
      ),
    );
  }
}

class _AllUnits extends StatelessWidget {
  const _AllUnits({required this.controller});

  final ConverterController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rows = controller.allConversions;

    if (rows.isEmpty) {
      return Text(
        'Enter a value to see every unit.',
        style: TextStyle(color: palette.muted),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].key.name,
                      style: TextStyle(fontSize: 14, color: palette.muted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SelectableText(
                    '${NumberFormatter.format(rows[i].value)} ${rows[i].key.symbol}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
