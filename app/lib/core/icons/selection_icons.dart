import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

/// The glyphs of range editing (selection mode) and of the agenda, picked
/// the same way as [AppIcons] (`app_icons.dart`): SF-Symbols-style on iOS and
/// macOS, Material Symbols rounded elsewhere. Kept in its own file so the
/// branches that grow `AppIcons` in parallel do not collide with it; fold
/// these into `AppIcons` whenever convenient.
class SelectionIcons {
  const SelectionIcons._();

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static IconData _pick(IconData apple, IconData material) =>
      _apple ? apple : material;

  /// «Cortar».
  static IconData get cut =>
      _pick(CupertinoIcons.scissors, Symbols.content_cut_rounded);

  /// «Pegar».
  static IconData get paste =>
      _pick(CupertinoIcons.doc_on_clipboard, Symbols.content_paste_rounded);

  /// The check on a chosen day.
  static IconData get selected =>
      _pick(CupertinoIcons.checkmark_circle_fill, Symbols.check_circle_rounded);

  /// The agenda of notes (button of the month header).
  static IconData get agenda =>
      _pick(CupertinoIcons.list_bullet, Symbols.event_note_rounded);

  static IconData get search =>
      _pick(CupertinoIcons.search, Symbols.search_rounded);

  /// «Mis rotaciones» (the patterns running on the calendar).
  static IconData get rotations =>
      _pick(CupertinoIcons.rectangle_stack, Symbols.layers_rounded);

  /// «Terminar aquí».
  static IconData get endRun =>
      _pick(CupertinoIcons.stop_circle, Symbols.stop_circle_rounded);
}
