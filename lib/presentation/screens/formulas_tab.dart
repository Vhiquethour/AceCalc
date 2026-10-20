import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/formula_def.dart';
import '../../domain/formulas/formula_catalogue.dart';
import '../widgets/app_card.dart';
import '../widgets/category_icons.dart';
import '../widgets/section_header.dart';
import 'formula_screen.dart';

class FormulasTab extends StatefulWidget {
  const FormulasTab({super.key});

  @override
  State<FormulasTab> createState() => _FormulasTabState();
}

class _FormulasTabState extends State<FormulasTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(FormulaDef formula, String query) {
    if (query.isEmpty) return true;
    return formula.title.toLowerCase().contains(query) ||
        formula.summary.toLowerCase().contains(query) ||
        formula.formula.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final query = _query.trim().toLowerCase();
    final radius = BorderRadius.circular(12);

    final children = <Widget>[
      TextField(
        controller: _search,
        onChanged: (text) => setState(() => _query = text),
        decoration: InputDecoration(
          hintText: 'Search formulas',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          filled: true,
          fillColor: palette.card,
          border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        ),
      ),
    ];

    var shown = 0;
    for (final pack in FormulaCatalogue.packOrder) {
      final formulas = FormulaCatalogue.inPack(pack).where((f) => _matches(f, query)).toList();
      if (formulas.isEmpty) continue;
      shown += formulas.length;
      children.add(
        SectionHeader(
          title: pack.label,
          icon: CategoryIcons.forPack(pack),
          trailing: '${formulas.length}',
        ),
      );
      for (final formula in formulas) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FormulaTile(formula: formula),
          ),
        );
      }
    }

    if (shown == 0) {
      children.add(const EmptyNotice(message: 'No formulas match your search.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: children,
    );
  }
}

class _FormulaTile extends StatelessWidget {
  const _FormulaTile({required this.formula});

  final FormulaDef formula;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => FormulaScreen(formula: formula)),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formula.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                if (formula.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    formula.summary,
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: palette.muted),
        ],
      ),
    );
  }
}
