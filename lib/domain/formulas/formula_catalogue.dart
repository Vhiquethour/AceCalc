import '../entities/formula_def.dart';
import 'electrical_formulas.dart';
import 'fluid_formulas.dart';
import 'general_formulas.dart';
import 'mechanical_formulas.dart';
import 'safety_formulas.dart';
import 'solar_formulas.dart';

abstract final class FormulaCatalogue {
  static final List<FormulaDef> all = [
    ...electricalFormulas,
    ...mechanicalFormulas,
    ...fluidFormulas,
    ...safetyFormulas,
    ...solarFormulas,
    ...generalFormulas,
  ];

  static const List<FormulaPack> packOrder = [
    FormulaPack.electrical,
    FormulaPack.mechanical,
    FormulaPack.fluids,
    FormulaPack.safety,
    FormulaPack.solar,
    FormulaPack.general,
  ];

  static List<FormulaDef> inPack(FormulaPack pack) =>
      all.where((f) => f.pack == pack).toList();

  static FormulaDef byId(String id) => all.firstWhere((f) => f.id == id);
}
