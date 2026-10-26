import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

/// Glyphs of the holidays screen, picked like `AppIcons` (SF-Symbols-style on
/// iOS and macOS, Material Symbols rounded elsewhere). Kept here so the
/// screens that grow `AppIcons` in parallel do not collide with it.
class HolidaysIcons {
  const HolidaysIcons._();

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static IconData _pick(IconData apple, IconData material) =>
      _apple ? apple : material;

  /// The autonomous community.
  static IconData get region => _pick(CupertinoIcons.map, Symbols.map_rounded);

  /// The municipality.
  static IconData get municipality =>
      _pick(CupertinoIcons.location, Symbols.location_city_rounded);

  /// Search field.
  static IconData get search =>
      _pick(CupertinoIcons.search, Symbols.search_rounded);

  /// Remove a holiday of your own.
  static IconData get delete =>
      _pick(CupertinoIcons.trash, Symbols.delete_rounded);

  /// A hint (the status line when something is still missing).
  static IconData get info => _pick(CupertinoIcons.info, Symbols.info_rounded);
}
