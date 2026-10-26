import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

/// The glyphs of the import and export screens, picked like `AppIcons`:
/// SF-Symbols-style on iOS and macOS, Material Symbols rounded elsewhere.
/// Kept in this feature so the screens built in parallel do not collide on
/// the shared icon files.
class ImportIcons {
  const ImportIcons._();

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static IconData _pick(IconData apple, IconData material) =>
      _apple ? apple : material;

  /// Import (the settings row).
  static IconData get importData =>
      _pick(CupertinoIcons.arrow_down_doc, Symbols.download_rounded);

  /// Export (the settings row).
  static IconData get exportData =>
      _pick(CupertinoIcons.arrow_up_doc, Symbols.upload_rounded);

  /// An `.ics` file.
  static IconData get icsFile =>
      _pick(CupertinoIcons.doc_text, Symbols.description_rounded);

  /// A CSV file.
  static IconData get csvFile =>
      _pick(CupertinoIcons.table, Symbols.table_chart_rounded);

  /// The backup of another shift app (LRHSoft `.Shifter`).
  static IconData get backupFile =>
      _pick(CupertinoIcons.archivebox, Symbols.archive_rounded);

  /// A calendar of the phone that is selected / not selected.
  static IconData get lock => _pick(CupertinoIcons.lock, Symbols.lock_rounded);

  /// Opens the date picker.
  static IconData get pickDate =>
      _pick(CupertinoIcons.calendar_today, Symbols.event_rounded);
}
