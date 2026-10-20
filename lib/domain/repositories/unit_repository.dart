import '../entities/unit_category.dart';

abstract interface class UnitRepository {
  List<String> get groups;
  List<UnitCategory> get categories;
  List<UnitCategory> inGroup(String group);
  UnitCategory byId(String id);
}
