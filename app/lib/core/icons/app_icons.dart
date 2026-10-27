import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

/// The app icon set: SF-Symbols-style glyphs (CupertinoIcons) on iOS and
/// macOS, Material Symbols rounded elsewhere (turnos-spec.md section 4).
///
/// Widgets never reference `Icons.*`, `CupertinoIcons.*` or `Symbols.*`
/// directly; they ask for an [AppIcons] entry, so a platform swap lives here.
/// Getters (not constants) because the platform is read at call time, which
/// also lets tests override `debugDefaultTargetPlatformOverride`.
class AppIcons {
  const AppIcons._();

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static IconData _pick(IconData apple, IconData material) =>
      _apple ? apple : material;

  static IconData get today =>
      _pick(CupertinoIcons.calendar_today, Symbols.today_rounded);
  static IconData get calendar =>
      _pick(CupertinoIcons.calendar, Symbols.calendar_month_rounded);

  /// "Pintar" (paint mode).
  static IconData get paint =>
      _pick(CupertinoIcons.paintbrush, Symbols.brush_rounded);
  static IconData get undo =>
      _pick(CupertinoIcons.arrow_uturn_left, Symbols.undo_rounded);
  static IconData get redo =>
      _pick(CupertinoIcons.arrow_uturn_right, Symbols.redo_rounded);
  static IconData get close =>
      _pick(CupertinoIcons.xmark, Symbols.close_rounded);
  static IconData get settings =>
      _pick(CupertinoIcons.gear, Symbols.settings_rounded);
  static IconData get chevronLeft =>
      _pick(CupertinoIcons.chevron_left, Symbols.chevron_left_rounded);
  static IconData get chevronRight =>
      _pick(CupertinoIcons.chevron_right, Symbols.chevron_right_rounded);

  /// Day note / attachment (paperclip).
  static IconData get note =>
      _pick(CupertinoIcons.paperclip, Symbols.attach_file_rounded);
  static IconData get add => _pick(CupertinoIcons.add, Symbols.add_rounded);

  /// Clear a day (eraser).
  static IconData get erase =>
      _pick(CupertinoIcons.delete_left, Symbols.ink_eraser_rounded);
  static IconData get check =>
      _pick(CupertinoIcons.checkmark, Symbols.check_rounded);
  static IconData get more =>
      _pick(CupertinoIcons.ellipsis, Symbols.more_horiz_rounded);
  static IconData get back =>
      _pick(CupertinoIcons.back, Symbols.arrow_back_rounded);
  static IconData get error =>
      _pick(CupertinoIcons.exclamationmark_circle, Symbols.error_rounded);

  // ---- Shift types editor and day detail ----------------------------------

  static IconData get edit =>
      _pick(CupertinoIcons.pencil, Symbols.edit_rounded);
  static IconData get archive =>
      _pick(CupertinoIcons.archivebox, Symbols.archive_rounded);
  static IconData get dragHandle =>
      _pick(CupertinoIcons.line_horizontal_3, Symbols.drag_handle_rounded);
  static IconData get arrowUp =>
      _pick(CupertinoIcons.arrow_up, Symbols.arrow_upward_rounded);
  static IconData get arrowDown =>
      _pick(CupertinoIcons.arrow_down, Symbols.arrow_downward_rounded);
  static IconData get remove =>
      _pick(CupertinoIcons.minus_circle, Symbols.remove_circle_rounded);
  static IconData get copy =>
      _pick(CupertinoIcons.doc_on_doc, Symbols.content_copy_rounded);
  static IconData get schedule =>
      _pick(CupertinoIcons.clock, Symbols.schedule_rounded);

  /// Share sheet (the annual view as an image).
  static IconData get share =>
      _pick(CupertinoIcons.share, Symbols.ios_share_rounded);

  /// The annual view (12 months).
  static IconData get yearView => _pick(
    CupertinoIcons.square_grid_3x2,
    Symbols.calendar_view_month_rounded,
  );

  /// The month as a grid of day cells (the presentation switch).
  static IconData get gridView =>
      _pick(CupertinoIcons.square_grid_2x2, Symbols.grid_view_rounded);

  /// The month as a list of days (the presentation switch).
  static IconData get listView =>
      _pick(CupertinoIcons.list_bullet, Symbols.view_agenda_rounded);

  /// The monthly summary (hours and estimated pay).
  static IconData get summary =>
      _pick(CupertinoIcons.chart_bar, Symbols.bar_chart_rounded);

  /// The pattern wizard (a repeating cycle).
  static IconData get pattern =>
      _pick(CupertinoIcons.arrow_2_circlepath, Symbols.repeat_rounded);

  // ---- Shift type icons (docs/paridad.md, A8) ------------------------------
  // One per `ShiftIcon` key (shift_icon.dart). The mapping from the key is in
  // `calendar/presentation/shift_icon_glyph.dart`.
  static IconData get shiftSun =>
      _pick(CupertinoIcons.sun_max, Symbols.wb_sunny_rounded);
  static IconData get shiftMoon =>
      _pick(CupertinoIcons.moon, Symbols.nightlight_rounded);
  static IconData get shiftSunrise =>
      _pick(CupertinoIcons.sunrise, Symbols.wb_twilight_rounded);
  static IconData get shiftHospital =>
      _pick(CupertinoIcons.building_2_fill, Symbols.local_hospital_rounded);
  static IconData get shiftAmbulance =>
      _pick(CupertinoIcons.plus_app, Symbols.emergency_rounded);
  static IconData get shiftPolice =>
      _pick(CupertinoIcons.shield, Symbols.local_police_rounded);
  static IconData get shiftFire =>
      _pick(CupertinoIcons.flame, Symbols.local_fire_department_rounded);
  static IconData get shiftFactory =>
      _pick(CupertinoIcons.gear_alt, Symbols.factory_rounded);
  static IconData get shiftTruck =>
      _pick(CupertinoIcons.cube_box, Symbols.local_shipping_rounded);
  static IconData get shiftPlane =>
      _pick(CupertinoIcons.airplane, Symbols.flight_rounded);
  static IconData get shiftSchool =>
      _pick(CupertinoIcons.person_3, Symbols.school_rounded);
  static IconData get shiftHome =>
      _pick(CupertinoIcons.house, Symbols.home_rounded);
  static IconData get shiftBeach =>
      _pick(CupertinoIcons.umbrella, Symbols.beach_access_rounded);
  static IconData get shiftBed =>
      _pick(CupertinoIcons.bed_double, Symbols.bed_rounded);
  static IconData get shiftStar =>
      _pick(CupertinoIcons.star, Symbols.star_rounded);
  static IconData get shiftHeart =>
      _pick(CupertinoIcons.heart, Symbols.favorite_rounded);
  static IconData get shiftCoffee =>
      _pick(CupertinoIcons.drop, Symbols.local_cafe_rounded);
  static IconData get shiftBook =>
      _pick(CupertinoIcons.book, Symbols.menu_book_rounded);
  static IconData get shiftMoney =>
      _pick(CupertinoIcons.money_euro_circle, Symbols.payments_rounded);
  static IconData get shiftAlert =>
      _pick(CupertinoIcons.exclamationmark_triangle, Symbols.warning_rounded);
  static IconData get shiftPhone =>
      _pick(CupertinoIcons.phone, Symbols.call_rounded);
  static IconData get shiftCar =>
      _pick(CupertinoIcons.car, Symbols.directions_car_rounded);
  static IconData get shiftTrain =>
      _pick(CupertinoIcons.train_style_one, Symbols.train_rounded);
  static IconData get shiftBus =>
      _pick(CupertinoIcons.bus, Symbols.directions_bus_rounded);
  static IconData get shiftShop =>
      _pick(CupertinoIcons.cart, Symbols.storefront_rounded);
  static IconData get shiftTool =>
      _pick(CupertinoIcons.wrench, Symbols.build_rounded);
  static IconData get shiftBaby =>
      _pick(CupertinoIcons.smiley, Symbols.child_care_rounded);
  static IconData get shiftSport =>
      _pick(CupertinoIcons.sportscourt, Symbols.sports_soccer_rounded);
  static IconData get shiftParty =>
      _pick(CupertinoIcons.sparkles, Symbols.celebration_rounded);
  static IconData get shiftMedical =>
      _pick(CupertinoIcons.bandage, Symbols.medical_services_rounded);

  /// «Sin icono» in the icon picker.
  static IconData get noIcon =>
      _pick(CupertinoIcons.nosign, Symbols.block_rounded);

  /// Marker of a day with overtime or early leave (a small plus).
  static IconData get extras =>
      _pick(CupertinoIcons.plus_circle_fill, Symbols.add_circle_rounded);

  /// A stepper going down by one step.
  static IconData get minus =>
      _pick(CupertinoIcons.minus, Symbols.remove_rounded);

  /// A reminder / alarm (bell).
  static IconData get bell =>
      _pick(CupertinoIcons.bell, Symbols.notifications_rounded);

  /// The sound of an alarm (speaker).
  static IconData get sound =>
      _pick(CupertinoIcons.speaker_2, Symbols.volume_up_rounded);
}
