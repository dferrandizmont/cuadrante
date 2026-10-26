import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart' show Color;

import '../../../core/theme/shift_swatch.dart';
import '../../../core/theme/shift_palette.dart';
import '../../calendar/application/week_layout.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../holidays/domain/holiday.dart';
import '../../schedule/domain/schedule_domain.dart';
import 'widget_snapshot.dart';
import 'widget_strings.dart';

/// Builds the widget snapshot: [days] consecutive civil days from [today],
/// with everything the native side shows already composed (no logic in
/// Swift). Pure: the same inputs always give the same snapshot.
///
/// - [schedule] is the only source of "which shift is it" (overrides, then
///   rotation).
/// - [holidays] by day (`holidaysProvider`).
/// - [today] comes from the app clock, never from `DateTime.now()`.
/// - [timeZone] is the IANA id the timeline's midnights belong to; it is only
///   recorded (civil dates carry no zone, so DST can never skip or repeat a
///   day).
/// - [strings] are the localized texts (their weekday lists are Monday first).
/// - [weekStart] is the first day of the week of the month grids, like
///   [DateTime.weekday]: 1 (Monday, the default) or 7 (Sunday). The grids start
///   on the last such day on or before the 1st and `weekdayHeaders` follow
///   the same order.
/// - [generatedAt] defaults to the current instant (pass it in tests).
WidgetSnapshot buildWidgetSnapshot({
  required Schedule schedule,
  required Map<CivilDate, Holiday> holidays,
  required CivilDate today,
  required String timeZone,
  required WidgetStrings strings,
  int days = kWidgetDays,
  int weekStart = DateTime.monday,
  DateTime? generatedAt,
}) {
  assert(days >= 1, 'a timeline needs at least one day');
  assert(
    weekStart == DateTime.monday || weekStart == DateTime.sunday,
    'the week starts on Monday (1) or Sunday (7)',
  );
  assert(strings.isValid, 'weekday lists need 7 items and monthNames 12');
  return _Builder(
    schedule: schedule,
    holidays: holidays,
    strings: strings,
    weekStart: weekStart,
  ).build(
    today: today,
    timeZone: timeZone,
    days: days,
    generatedAt: (generatedAt ?? DateTime.now()).toUtc(),
  );
}

class _Builder {
  _Builder({
    required this.schedule,
    required this.holidays,
    required this.strings,
    required this.weekStart,
  });

  final Schedule schedule;
  final Map<CivilDate, Holiday> holidays;
  final WidgetStrings strings;
  final int weekStart;

  final _resolved = <CivilDate, ResolvedDay>{};
  final _descriptions = <String, String>{};
  final _absenceDescriptions = <String, String>{};
  final _styleIndex = <int, int>{};
  final _styles = <WidgetStyle>[];
  final _monthIndex = <String, int>{};
  final _months = <WidgetMonth>[];

  ResolvedDay _day(CivilDate d) => _resolved.putIfAbsent(d, () {
    final day = schedule.resolve(d);
    _descriptions[d.toIso()] = strings.describe(d, day, holidays[d]?.name);
    if (day.shifts.any((s) => s.category == ShiftCategory.absence)) {
      _absenceDescriptions[d.toIso()] = strings.describe(
        d,
        day,
        holidays[d]?.name,
        redactAbsence: true,
      );
    }
    return day;
  });

  WidgetSnapshot build({
    required CivilDate today,
    required String timeZone,
    required int days,
    required DateTime generatedAt,
  }) {
    final out = [for (var i = 0; i < days; i++) _buildDay(today.addDays(i))];
    final start = today.addDays(1 - today.weekday);
    final end = today.addDays(days - 1 + kWidgetUpcomingDays - 1);
    final displayDays = [
      for (var i = 0; i <= end.differenceInDays(start); i++)
        _displayDay(start.addDays(i)),
    ];
    return WidgetSnapshot(
      generatedAt: generatedAt,
      timeZone: timeZone,
      locale: strings.locale,
      firstDate: today.toIso(),
      lastDate: today.addDays(days - 1).toIso(),
      staleTitle: strings.staleTitle,
      staleBody: strings.staleBody,
      weekdayHeaders: [
        for (final weekday in weekdayOrder(weekStart))
          strings.weekdayHeaders[weekday - 1],
      ],
      styles: _styles,
      months: _months,
      days: out,
      noShift: strings.noShift,
      displayDays: displayDays,
      descriptions: WidgetDescriptions(
        today: strings.todayLabel,
        days: _descriptions,
        absences: _absenceDescriptions,
      ),
    );
  }

  WidgetDay _buildDay(CivilDate date) {
    final day = _day(date);
    final holiday = holidays[date];
    final shifts = day.shifts;
    final month = _monthFor(date);
    final weekdayShort = strings.weekdaysShort[date.weekday - 1];
    final tomorrow = _tomorrowLine(date.addDays(1));
    final single = shifts.length == 1;

    return WidgetDay(
      date: date.toIso(),
      weekday: date.weekday,
      weekdayShort: weekdayShort,
      dayOfMonth: date.day,
      dateLabel: '$weekdayShort ${date.day}',
      isHoliday: holiday != null,
      holidayName: holiday?.name,
      hasNote: _hasNote(day),
      shifts: [for (final s in shifts) _shift(s)],
      small: WidgetSmall(
        big: shifts.isEmpty ? strings.noShift : _codes(shifts),
        isEmpty: shifts.isEmpty,
        detail: shifts.isEmpty ? null : _detail(shifts, single),
        tomorrow: tomorrow,
      ),
      medium: WidgetMedium(
        cells: [
          for (var i = 0; i < kWidgetStripDays; i++)
            _stripCell(date.addDays(i), isToday: i == 0),
        ],
      ),
      large: WidgetLarge(
        month: month.index,
        todayCell: date.differenceInDays(month.gridStart),
      ),
      lock: WidgetLock(
        inline: shifts.isEmpty ? strings.noShift : _inline(shifts),
        circular: shifts.isEmpty
            ? strings.emptyCircular
            : single
            ? shifts.first.code
            : '${shifts.first.code}+',
        rectangular: [
          shifts.isEmpty
              ? strings.noShift
              : '${_codes(shifts)} · ${_detail(shifts, single)}',
          tomorrow,
        ],
      ),
    );
  }

  bool _hasNote(ResolvedDay day) => day.note != null && day.note!.isNotEmpty;

  WidgetDisplayDay _displayDay(CivilDate date) {
    final day = _day(date);
    final weekday = strings.weekdaysShort[date.weekday - 1];
    return WidgetDisplayDay(
      date: date.toIso(),
      weekdayShort: weekday,
      dayOfMonth: date.day,
      dateLabel: '$weekday ${date.day}',
      isHoliday: holidays.containsKey(date),
      hasNote:
          !day.shifts.any((s) => s.category == ShiftCategory.absence) &&
          _hasNote(day),
      shifts: [
        for (final shift in day.shifts) _shift(shift, redactAbsence: true),
      ],
    );
  }

  // --- Text composition ----------------------------------------------------

  /// "N", "M+T".
  String _codes(List<ShiftType> shifts) => shifts.map((s) => s.code).join('+');

  /// A single shift: its time label, else its name. Several: the compact
  /// times (else the names) joined with " + ".
  String _detail(List<ShiftType> shifts, bool single) => single
      ? (_timeLabel(shifts.first) ?? shifts.first.name)
      : shifts.map((s) => s.compactTimeLabel ?? s.name).join(' + ');

  /// "N · 22:00" (start of the first shift) or just the codes when the first
  /// shift has no schedule.
  String _inline(List<ShiftType> shifts) {
    final start = shifts.first.startMinute;
    return start == null
        ? _codes(shifts)
        : '${_codes(shifts)} · ${_hhmm(start)}';
  }

  /// "Mañana: T 14–22", "Mañana: M 06–14 + T 14–22", "Mañana: Sin turno".
  String _tomorrowLine(CivilDate date) {
    final shifts = _day(date).shifts;
    final text = shifts.isEmpty
        ? strings.noShift
        : shifts
              .map(
                (s) => s.compactTimeLabel == null
                    ? s.code
                    : '${s.code} ${s.compactTimeLabel}',
              )
              .join(' + ');
    return '${strings.tomorrow}: $text';
  }

  // --- Colours -------------------------------------------------------------

  WidgetShift _shift(ShiftType s, {bool redactAbsence = false}) {
    final redacted = redactAbsence && s.category == ShiftCategory.absence;
    final color = redacted ? ShiftPalette.rest.toARGB32() : s.colorValue;
    final light = ShiftSwatch.forColor(color, Brightness.light);
    final dark = ShiftSwatch.forColor(color, Brightness.dark);
    return WidgetShift(
      code: redacted ? strings.absence : s.code,
      name: redacted ? strings.absence : s.name,
      timeLabel: redacted ? null : _timeLabel(s),
      compactTime: redacted ? null : s.compactTimeLabel,
      category: s.category.name,
      barLight: _argb(light.bar),
      tintLight: _argb(light.tint),
      inkLight: _argb(light.ink),
      discLight: _argb(light.disc),
      barDark: _argb(dark.bar),
      tintDark: _argb(dark.tint),
      inkDark: _argb(dark.ink),
      discDark: _argb(dark.disc),
    );
  }

  /// Index of the style of [colorValue] in the shared table (created on first
  /// use, so the order is that of first appearance).
  int _style(int colorValue) => _styleIndex.putIfAbsent(colorValue, () {
    ShiftSwatch swatch(Brightness b, {bool outOfMonth = false}) =>
        ShiftSwatch.forColor(colorValue, b, outOfMonth: outOfMonth);
    final light = swatch(Brightness.light);
    final dark = swatch(Brightness.dark);
    final dimLight = swatch(Brightness.light, outOfMonth: true);
    final dimDark = swatch(Brightness.dark, outOfMonth: true);
    _styles.add(
      WidgetStyle(
        barLight: _argb(light.bar),
        tintLight: _argb(light.tint),
        inkLight: _argb(light.ink),
        discLight: _argb(light.disc),
        barDark: _argb(dark.bar),
        tintDark: _argb(dark.tint),
        inkDark: _argb(dark.ink),
        discDark: _argb(dark.disc),
        dimBarLight: _argb(dimLight.bar),
        dimTintLight: _argb(dimLight.tint),
        dimInkLight: _argb(dimLight.ink),
        dimDiscLight: _argb(dimLight.disc),
        dimBarDark: _argb(dimDark.bar),
        dimTintDark: _argb(dimDark.tint),
        dimInkDark: _argb(dimDark.ink),
        dimDiscDark: _argb(dimDark.disc),
      ),
    );
    return _styles.length - 1;
  });

  List<WidgetBand> _bands(ResolvedDay day) => [
    for (final s in day.shifts)
      WidgetBand(code: s.code, style: _style(s.colorValue)),
  ];

  // --- Strips and grids ----------------------------------------------------

  WidgetStripCell _stripCell(CivilDate date, {required bool isToday}) {
    final day = _day(date);
    return WidgetStripCell(
      date: date.toIso(),
      weekdayShort: strings.weekdaysShort[date.weekday - 1],
      dayOfMonth: date.day,
      isToday: isToday,
      isHoliday: holidays.containsKey(date),
      hasNote: _hasNote(day),
      bands: _bands(day),
    );
  }

  ({int index, CivilDate gridStart}) _monthFor(CivilDate date) {
    final first = date.firstDayOfMonth;
    final gridStart = monthGridStart(first, weekStart);
    final key =
        '${first.year.toString().padLeft(4, '0')}-'
        '${first.month.toString().padLeft(2, '0')}';
    final existing = _monthIndex[key];
    if (existing != null) return (index: existing, gridStart: gridStart);

    final cells = [
      for (var i = 0; i < kWidgetMonthCells; i++)
        _monthCell(gridStart.addDays(i), first),
    ];
    final name = strings.monthNames[first.month - 1];
    _months.add(
      WidgetMonth(
        key: key,
        title: '${capitalize(name)} ${first.year}',
        cells: cells,
      ),
    );
    return (index: _monthIndex[key] = _months.length - 1, gridStart: gridStart);
  }

  WidgetMonthCell _monthCell(CivilDate date, CivilDate monthStart) {
    final day = _day(date);
    return WidgetMonthCell(
      date: date.toIso(),
      dayOfMonth: date.day,
      inMonth: date.year == monthStart.year && date.month == monthStart.month,
      isHoliday: holidays.containsKey(date),
      hasNote: _hasNote(day),
      bands: _bands(day),
    );
  }
}

int _argb(Color c) => c.toARGB32();

String _two(int n) => n.toString().padLeft(2, '0');

/// "22:00" (24 h clock; 1440 wraps to 00:00 like the app does).
String _hhmm(int minute) => '${_two((minute ~/ 60) % 24)}:${_two(minute % 60)}';

/// "22:00–06:00", or null for a shift without schedule. A split shift (A12)
/// gives its compact ranges, "09–13 · 17–21": two full ranges would not fit
/// the widget's line.
String? _timeLabel(ShiftType s) => s.hasSegment2
    ? s.compactTimeLabel
    : s.hasTimes
    ? '${_hhmm(s.startMinute!)}–${_hhmm(s.endMinute!)}'
    : null;
