import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/unit_category.dart';
import '../../domain/repositories/unit_repository.dart';
import '../widgets/app_card.dart';
import '../widgets/category_icons.dart';
import '../widgets/section_header.dart';
import 'converter_screen.dart';

class ConvertTab extends StatefulWidget {
  const ConvertTab({super.key, required this.unitRepository});

  final UnitRepository unitRepository;

  @override
  State<ConvertTab> createState() => _ConvertTabState();
}

class _ConvertTabState extends State<ConvertTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
          hintText: 'Search unit categories',
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
    for (final group in widget.unitRepository.groups) {
      final categories = widget.unitRepository
          .inGroup(group)
          .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
          .toList();
      if (categories.isEmpty) continue;
      shown += categories.length;
      children.add(SectionHeader(title: group));
      children.add(_CategoryGrid(categories: categories));
    }

    if (shown == 0) {
      children.add(const EmptyNotice(message: 'No categories match your search.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: children,
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<UnitCategory> categories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final width = constraints.maxWidth;
        final columns = width > 700 ? 4 : (width > 480 ? 3 : 2);
        final tileWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final category in categories)
              SizedBox(
                width: tileWidth,
                child: _CategoryTile(category: category),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final UnitCategory category;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ConverterScreen(category: category),
          ),
        );
      },
      child: Row(
        children: [
          Icon(CategoryIcons.forKey(category.iconKey), size: 22, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
