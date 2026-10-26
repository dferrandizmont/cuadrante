import 'package:flutter/widgets.dart' show StringCharacters;

import '../../../core/format/text_fold.dart';
import '../../import/domain/import_models.dart';
import '../../schedule/domain/civil_date.dart';
import 'holiday.dart';
import 'holiday_calendar.dart';

/// One source event can supply at most this many consecutive holiday days.
const int maxHolidayImportSpanDays = 31;

/// The existing import title limit also bounds unusually large Unicode
/// graphemes (one visible character can contain thousands of combining marks).
String clipHolidayImportName(String name) =>
    clipTitle(name.trim()).characters.take(maxHolidayNameLength).toString();

/// One day shown in the preview. A skipped day never replaces a holiday.
class HolidayImportRow {
  const HolidayImportRow({
    required this.date,
    required this.name,
    this.skipped = false,
  });

  final CivilDate date;
  final String name;
  final bool skipped;
}

/// The pure preview of importing a calendar as personal holidays.
class HolidayImportPlan {
  HolidayImportPlan({
    required Iterable<HolidayImportRow> rows,
    required this.ignoredTimed,
    required this.cappedEvents,
  }) : rows = List.unmodifiable(rows);

  final List<HolidayImportRow> rows;
  final int ignoredTimed;
  final int cappedEvents;

  List<HolidayImportRow> get toAdd => [
    for (final row in rows)
      if (!row.skipped) row,
  ];
}

/// Keeps all-day events only, with an exclusive end and a cap counted from
/// their original start (before intersecting [range]). Duplicate names on a
/// day are folded like Spanish search; any existing holiday or earlier
/// preview row on that date makes a row skipped, irrespective of its name.
HolidayImportPlan buildHolidayImportPlan(
  Iterable<RawEvent> events,
  ImportRange range,
  HolidayCalendar existing, {
  required String fallbackName,
}) {
  final fallback = fallbackName.trim();
  if (fallback.isEmpty) {
    throw ArgumentError.value(
      fallbackName,
      'fallbackName',
      'must not be empty',
    );
  }
  final unique = <(CivilDate, String), HolidayImportRow>{};
  var ignoredTimed = 0;
  var cappedEvents = 0;
  if (range.isValid) {
    for (final event in events) {
      if (!event.allDay) {
        final end = event.endDate;
        final last = end != null && end.isAfter(event.startDate)
            ? (event.endMinute == 0 ? end.addDays(-1) : end)
            : event.startDate;
        if (!event.startDate.isAfter(range.to) && !last.isBefore(range.from)) {
          ignoredTimed++;
        }
        continue;
      }
      final start = event.startDate;
      final end = event.endDate;
      final span = end != null && end.isAfter(start)
          ? end.differenceInDays(start)
          : 1;
      final originalLast = start.addDays(span - 1);
      if (start.isAfter(range.to) || originalLast.isBefore(range.from)) {
        continue;
      }
      if (span > maxHolidayImportSpanDays) cappedEvents++;
      final cappedLast = start.addDays(
        (span > maxHolidayImportSpanDays ? maxHolidayImportSpanDays : span) - 1,
      );
      final last = cappedLast.isAfter(range.to) ? range.to : cappedLast;
      final trimmed = event.title.trim();
      final name = clipHolidayImportName(trimmed.isEmpty ? fallback : trimmed);
      final folded = foldSpanish(name);
      for (
        var date = start.isBefore(range.from) ? range.from : start;
        !date.isAfter(last);
        date = date.addDays(1)
      ) {
        final key = (date, folded);
        final previous = unique[key];
        if (previous == null || name.compareTo(previous.name) < 0) {
          unique[key] = HolidayImportRow(date: date, name: name);
        }
      }
    }
  }
  final candidates = [
    for (final entry in unique.entries) (entry.value, entry.key.$2),
  ];
  candidates.sort((a, b) {
    final date = a.$1.date.compareTo(b.$1.date);
    if (date != 0) return date;
    final folded = a.$2.compareTo(b.$2);
    return folded != 0 ? folded : a.$1.name.compareTo(b.$1.name);
  });
  final occupied = existing.between(range.from, range.to).keys.toSet();
  final rows = <HolidayImportRow>[];
  for (final (candidate, _) in candidates) {
    rows.add(
      HolidayImportRow(
        date: candidate.date,
        name: candidate.name,
        skipped: !occupied.add(candidate.date),
      ),
    );
  }
  return HolidayImportPlan(
    rows: rows,
    ignoredTimed: ignoredTimed,
    cappedEvents: cappedEvents,
  );
}
