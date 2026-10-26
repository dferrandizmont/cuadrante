import 'dart:ui' show Brightness;

import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/shift_swatch.dart';
import '../../schedule/domain/schedule_domain.dart';

DateTime _clock(int minute) =>
    DateTime(2000, 1, 1, (minute ~/ 60) % 24, minute % 60);

String _two(int n) => n.toString().padLeft(2, '0');

String _compact(int minute) {
  final h = (minute ~/ 60) % 24;
  final m = minute % 60;
  return m == 0 ? _two(h) : '${_two(h)}:${_two(m)}';
}

String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

extension ShiftTypeFormat on ShiftType {
  /// Bar, tint, disc and ink of this shift in [brightness] (derived from the
  /// stored colour at paint time). [outOfMonth] is the variant of the days
  /// of the neighbouring months.
  ShiftSwatch swatch(Brightness brightness, {bool outOfMonth = false}) =>
      ShiftSwatch.forColor(colorValue, brightness, outOfMonth: outOfMonth);

  /// 24 h range "22:00–06:00", or null for shifts without schedule. A split
  /// shift (A12) gives both ranges: "09:00–13:00 · 17:00–21:00".
  String? timeRange(AppDateFormat format) {
    if (!hasTimes) return null;
    final first = format.timeRange(_clock(startMinute!), _clock(endMinute!));
    if (!hasSegment2) return first;
    final second = format.timeRange(
      _clock(segment2StartMinute!),
      _clock(segment2EndMinute!),
    );
    return '$first · $second';
  }

  /// Cell form "22–06" (minutes only when they are not :00: "07:30–15"), or
  /// null for shifts without schedule. A split shift gives both ranges
  /// joined by a slash: "09–13/17–21" (the cell only shows it when it fits).
  String? get compactTimeRange => _compactRanges('/');

  /// The start of the first range in the cell form: "09" (or "09:30" when
  /// the minutes are not :00), or null for shifts without schedule. It is
  /// what the cell says of a split shift whose two ranges do not fit: the
  /// cell always has a code and a time (H-T22-9).
  String? get compactStart => hasTimes ? _compact(startMinute!) : null;

  /// The start of each range of a split shift in the cell form: "09/17", or
  /// null for a shift with a single range. It is what the cell says of a
  /// split shift whose two full ranges do not fit: the cell tells that the
  /// shift has two segments without shrinking the code (H-T23-1).
  String? get compactSplitStarts {
    if (!hasTimes || !hasSegment2) return null;
    return '${_compact(startMinute!)}/${_compact(segment2StartMinute!)}';
  }

  /// Like [compactTimeRange], but a split shift's ranges are joined by
  /// " · " ("09–13 · 17–21"), as the widget and its lock screen line show
  /// them.
  String? get compactTimeLabel => _compactRanges(' · ');

  String? _compactRanges(String separator) {
    if (!hasTimes) return null;
    final first = '${_compact(startMinute!)}–${_compact(endMinute!)}';
    if (!hasSegment2) return first;
    return '$first$separator${_compact(segment2StartMinute!)}–'
        '${_compact(segment2EndMinute!)}';
  }

  /// "Noche 22:00–06:00", or just the name when it has no schedule.
  String nameWithTimes(AppLocalizations l10n, AppDateFormat format) {
    final times = timeRange(format);
    return times == null ? name : l10n.calendarShiftWithTimes(name, times);
  }

  /// Spoken form: "Noche de 22:00 a 06:00" ("Partido de 09:00 a 13:00 y de
  /// 17:00 a 21:00" for a split shift).
  String spoken(AppLocalizations l10n, AppDateFormat format) {
    if (!hasTimes) return name;
    final start = format.time(_clock(startMinute!));
    final end = format.time(_clock(endMinute!));
    if (!hasSegment2) return l10n.daySemanticsShift(name, start, end);
    return l10n.daySemanticsShiftSplit(
      name,
      start,
      end,
      format.time(_clock(segment2StartMinute!)),
      format.time(_clock(segment2EndMinute!)),
    );
  }
}

/// "Noche 22:00–06:00 + Tarde 14:00–22:00", or "Sin turno".
String shiftsLine(
  AppLocalizations l10n,
  AppDateFormat format,
  List<ShiftType> shifts,
) => shifts.isEmpty
    ? l10n.calendarNoShift
    : shifts.map((s) => s.nameWithTimes(l10n, format)).join(' + ');

/// "3 h 40 min", "40 min", "2 h", "1 d 8 h" (minutes are dropped from a day
/// on). [minutes] is a whole number of minutes, at least 1.
String durationText(AppLocalizations l10n, int minutes) {
  final days = minutes ~/ 1440;
  final hours = (minutes % 1440) ~/ 60;
  final rest = minutes % 60;
  if (days > 0) {
    return hours == 0
        ? l10n.durationDays(days)
        : l10n.durationDaysHours(days, hours);
  }
  if (hours > 0) {
    return rest == 0
        ? l10n.durationHours(hours)
        : l10n.durationHoursMinutes(hours, rest);
  }
  return l10n.durationMinutes(minutes);
}
