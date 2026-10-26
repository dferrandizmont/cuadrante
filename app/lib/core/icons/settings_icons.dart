import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

/// The glyphs of the Settings and calendar-management screens, picked the
/// same way as [AppIcons] (`app_icons.dart`): SF-Symbols-style on iOS and
/// macOS, Material Symbols rounded elsewhere. Kept in its own file so the
/// screens that grow `AppIcons` in parallel do not collide with it; fold
/// these into `AppIcons` whenever convenient.
class SettingsIcons {
  const SettingsIcons._();

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static IconData _pick(IconData apple, IconData material) =>
      _apple ? apple : material;

  /// "Mis turnos".
  static IconData get shifts =>
      _pick(CupertinoIcons.clock, Symbols.schedule_rounded);

  /// Theme (light / dark).
  static IconData get theme =>
      _pick(CupertinoIcons.circle_lefthalf_fill, Symbols.contrast_rounded);

  /// First day of the week.
  static IconData get weekStart =>
      _pick(CupertinoIcons.calendar_today, Symbols.today_rounded);

  /// Week numbers.
  static IconData get weekNumbers =>
      _pick(CupertinoIcons.number, Symbols.tag_rounded);

  /// "Idioma".
  static IconData get language =>
      _pick(CupertinoIcons.globe, Symbols.language_rounded);

  static IconData get holidays =>
      _pick(CupertinoIcons.flag, Symbols.flag_rounded);
  static IconData get alarms =>
      _pick(CupertinoIcons.alarm, Symbols.alarm_rounded);

  /// "Copia de seguridad".
  static IconData get backup =>
      _pick(CupertinoIcons.shield, Symbols.shield_rounded);

  /// "Añadir widget".
  static IconData get widget =>
      _pick(CupertinoIcons.square_grid_2x2, Symbols.widgets_rounded);
  static IconData get help =>
      _pick(CupertinoIcons.question_circle, Symbols.help_rounded);
  static IconData get privacy =>
      _pick(CupertinoIcons.hand_raised, Symbols.privacy_tip_rounded);
  static IconData get about => _pick(CupertinoIcons.info, Symbols.info_rounded);

  /// Opens a menu or a sheet (the calendar pill).
  static IconData get expand =>
      _pick(CupertinoIcons.chevron_down, Symbols.expand_more_rounded);
  static IconData get archive =>
      _pick(CupertinoIcons.archivebox, Symbols.archive_rounded);
  static IconData get copy =>
      _pick(CupertinoIcons.doc_on_doc, Symbols.content_copy_rounded);
}
