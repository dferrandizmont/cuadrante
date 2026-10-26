import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

/// The glyphs of the 0.6.0 «Paridad» features (free colour, comparing
/// calendars, date ranges, frequently asked questions), picked the same way as
/// [AppIcons] (`app_icons.dart`): SF-Symbols-style on iOS and macOS, Material
/// Symbols rounded elsewhere. Kept in its own file, like `SelectionIcons`, so
/// branches that grow `AppIcons` in parallel do not collide with it.
class ParityIcons {
  const ParityIcons._();

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static IconData _pick(IconData apple, IconData material) =>
      _apple ? apple : material;

  /// «Más colores…».
  static IconData get palette =>
      _pick(CupertinoIcons.paintbrush, Symbols.palette_rounded);

  /// «Comparar calendarios».
  static IconData get compare =>
      _pick(CupertinoIcons.person_2, Symbols.compare_arrows_rounded);

  /// «Intercambiar» the two calendars being compared.
  static IconData get swap =>
      _pick(CupertinoIcons.arrow_up_arrow_down, Symbols.swap_vert_rounded);

  /// A date range («Fechas…»).
  static IconData get dateRange =>
      _pick(CupertinoIcons.calendar, Symbols.date_range_rounded);

  /// «Preguntas frecuentes».
  static IconData get faq =>
      _pick(CupertinoIcons.question_circle, Symbols.quiz_rounded);
}
