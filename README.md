  # AceCalc

An offline Android app, built with Flutter and Dart, that combines a unit converter with a library of engineering formulas. It is organised in layers (domain, data, presentation) so the calculation logic has no dependency on the user interface and can be tested on its own.

## What it does

- **Unit converter**: 30 categories and about 160 units, grouped as Basics, Mechanical, Fluids, Electrical and Other. Each screen shows the result as you type, a swap button, a copy button and the value in every other unit.
- **Formula library**: 65 formulas in six packs, each with its equation, the inputs and units, the results, and notes on assumptions.
  - Electrical (12): Ohm's law, three-phase power, cable voltage drop, battery runtime and more.
  - Motors and mechanical (9): torque and power, synchronous speed and slip, stress, gears.
  - Fluids and oil and gas (12): hydrostatic and drilling pressure, Reynolds number, head loss, pump power, API gravity, tank volume.
  - Health and safety (19): incident rates, noise dose, gas ppm and mg/m³, heat stress, risk matrix, sling angle, NIOSH lifting equation.
  - Solar and embedded (5): array and battery sizing, LED resistor, ADC voltage, PWM.
  - General (8): geometry, percentages, right-angled triangles, payback.
- **Themes**: midnight blue (dark) by default, a clean light theme as an option, or follow the system. The choice is saved.

## Structure

```
lib/
  main.dart                      entry point
  app.dart                       MaterialApp and theme wiring
  core/                          theme, constants, number formatting and parsing
  domain/                        pure Dart, no Flutter imports
    entities/                    UnitDef, UnitCategory, FormulaDef
    services/unit_converter.dart conversion through a base unit
    formulas/                    one file per pack, plus the catalogue
    repositories/                interfaces only
  data/
    units/                       unit tables per group, and the unit repository
    repositories/                saved settings (shared_preferences)
  presentation/
    controllers/                 ChangeNotifier state for theme, converter, formulas
    screens/                     home, converter, formula, settings
    widgets/                     shared cards, fields, pickers
test/                            unit, formula and controller tests
```

## How it works

**Conversion.** Every linear unit stores one factor to the base unit of its category, so adding a unit takes one line of data. Converting is `value × fromFactor ÷ toFactor`. Temperature, AWG and API gravity are not linear, so those units supply their own `toBase` and `fromBase` functions.

**Formulas.** A formula is data plus a function: its inputs, outputs and modes (for example "solve for voltage" or "solve for current"), and a `compute` function that returns values and messages. Invalid input throws a `FormulaException` that the screen shows as a plain message. One generic screen displays every formula, so adding a formula does not need any new interface code.

## Accuracy and limits

- Unit factors use exact or standard definitions (for example 1 in = 0.0254 m and 1 bbl = 42 US gal). Check any factor you rely on against NIST before using it professionally.
- Exposure limits, WBGT limits, NIOSH frequency and coupling multipliers, and gas LEL values are **not built in**. The app asks you to enter them from your own regulation or datasheet, so it never applies an outdated table.
- The risk matrix bands (5, 10 and 17) are only defaults and can be changed on screen.
- Results are for guidance only. Verify them against the applicable standard and a competent assessment, especially for safety-critical work.