import '../../domain/entities/unit_category.dart';
import '../../domain/repositories/unit_repository.dart';
import 'basic_units.dart';
import 'electrical_units.dart';
import 'fluid_units.dart';
import 'mechanical_units.dart';
import 'other_units.dart';

class StaticUnitRepository implements UnitRepository {
  StaticUnitRepository()
      : _categories = [
          ...basicCategories,
          ...mechanicalCategories,
          ...fluidCategories,
          ...electricalCategories,
          ...otherCategories,
        ];

  final List<UnitCategory> _categories;

  @override
  List<String> get groups =>
      const ['Basics', 'Mechanical', 'Fluids', 'Electrical', 'Other'];

  @override
  List<UnitCategory> get categories => List.unmodifiable(_categories);

  @override
  List<UnitCategory> inGroup(String group) =>
      _categories.where((c) => c.group == group).toList();

  @override
  UnitCategory byId(String id) => _categories.firstWhere((c) => c.id == id);
}
