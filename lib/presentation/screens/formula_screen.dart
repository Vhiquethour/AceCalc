import 'package:flutter/material.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_palette.dart';
import '../../domain/entities/formula_def.dart';
import '../controllers/formula_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/number_field.dart';
import '../widgets/results_card.dart';
import '../widgets/section_header.dart';

class FormulaScreen extends StatefulWidget {
  const FormulaScreen({super.key, required this.formula});

  final FormulaDef formula;

  @override
  State<FormulaScreen> createState() => _FormulaScreenState();
}

class _FormulaScreenState extends State<FormulaScreen> {
  late final FormulaController _controller;
  final Map<String, TextEditingController> _fields = {};

  @override
  void initState() {
    super.initState();
    _controller = FormulaController(widget.formula);
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  TextEditingController _fieldFor(String key) {
    return _fields.putIfAbsent(
      key,
      () => TextEditingController(text: _controller.textFor(key)),
    );
  }

  Widget _chips<T>({
    required List<String> labels,
    required bool Function(int index) isSelected,
    required void Function(int index) onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
            label: Text(labels[i]),
            selected: isSelected(i),
            showCheckmark: false,
            selectedColor: scheme.primary,
            backgroundColor: palette.chip,
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: isSelected(i) ? scheme.onPrimary : scheme.onSurface,
            ),
            onSelected: (_) => onSelected(i),
          ),
      ],
    );
  }

  Widget _buildInput(FormulaInput input) {
    final palette = context.palette;

    if (input.isChoice) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(input.label, style: TextStyle(fontSize: 12, color: palette.muted)),
            const SizedBox(height: 6),
            _chips<double>(
              labels: [for (final choice in input.choices) choice.label],
              isSelected: (i) => _controller.choiceFor(input.key) == input.choices[i].value,
              onSelected: (i) => _controller.setChoice(input.key, input.choices[i].value),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NumberField(
        key: ValueKey('${_controller.modeIndex}-${input.key}'),
        controller: _fieldFor(input.key),
        label: input.optional ? '${input.label} (optional)' : input.label,
        suffix: input.unit.isEmpty ? null : input.unit,
        hint: input.hint,
        onChanged: (text) => _controller.setText(input.key, text),
      ),
    );
  }

  Widget _buildOutcome(FormulaOutcome outcome, FormulaMode mode) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;

    switch (outcome.status) {
      case OutcomeStatus.pending:
        return AppCard(
          child: Text(
            'Enter the values above to see the result.',
            style: TextStyle(color: palette.muted),
          ),
        );
      case OutcomeStatus.error:
        return AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 20, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(outcome.message ?? '', style: TextStyle(color: scheme.error)),
              ),
            ],
          ),
        );
      case OutcomeStatus.success:
        return ResultsCard(outputs: mode.outputs, result: outcome.result!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formula = widget.formula;
    final palette = context.palette;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(formula.title)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final mode = _controller.mode;
          final outcome = _controller.outcome;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formula.formula,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: accent,
                      ),
                    ),
                    if (formula.summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(formula.summary, style: TextStyle(color: palette.muted)),
                    ],
                  ],
                ),
              ),
              if (formula.modes.length > 1) ...[
                const SizedBox(height: 12),
                _chips<int>(
                  labels: [for (final m in formula.modes) m.label],
                  isSelected: (i) => i == _controller.modeIndex,
                  onSelected: _controller.selectMode,
                ),
              ],
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final input in mode.inputs) _buildInput(input)],
                ),
              ),
              const SizedBox(height: 12),
              _buildOutcome(outcome, mode),
              if (formula.notes.isNotEmpty) ...[
                const SectionHeader(title: 'Notes'),
                for (final note in formula.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: TextStyle(color: palette.muted)),
                        Expanded(
                          child: Text(note, style: TextStyle(color: palette.muted)),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              const DisclaimerNote(text: AppInfo.disclaimer),
            ],
          );
        },
      ),
    );
  }
}
