import '../../schedule/domain/schedule_domain.dart';
import 'device_calendar_api.dart';

/// Start of the line every exported event carries in its description. A
/// re-export finds its own events by it (and only by it), so it replaces them
/// instead of adding a second copy. Never change it: events written by an
/// older version would stop being recognised.
const String exportTagPrefix = 'cuadrante:v1';

/// First line of the description of every exported event. An event is only
/// ours when its description starts with exactly this line **and** has the tag
/// as a line of its own (see [ExportTag.parse]). Never change it, for the same
/// reason as [exportTagPrefix].
const String exportMarkerLine = 'Creado con Cuadrante';

/// How far from the exported dates a re-export looks for its own events: an
/// event the user dragged to another day is still found by its tag.
const int exportSearchMarginDays = 366;

/// Most days one export covers (a year).
const int maxExportDays = 366;

/// Added to the `n` of the tag of the **second segment** of a split shift
/// (A12), so that its event never shares a tag with the first segment's or
/// with another shift's of the same day (a day never holds that many shifts).
/// Tags written before split shifts existed keep their meaning: the first
/// segment (and every other shift) uses its position in the day, as always.
const int exportSecondSegmentIndexOffset = 100;

/// One shift of one day, as an event of the phone's calendar. A split shift
/// gives two (one per segment).
class ExportEvent {
  const ExportEvent({
    required this.calendarId,
    required this.date,
    required this.shiftTypeId,
    required this.index,
    required this.title,
    required this.start,
    required this.end,
    required this.allDay,
    this.segment = 0,
  });

  /// The Cuadrante calendar (not the phone's) the shift comes from.
  final String calendarId;
  final CivilDate date;
  final String shiftTypeId;

  /// Position of the shift in its day (a day can hold several).
  final int index;

  /// 0, or 1 for the second segment of a split shift.
  final int segment;

  /// «Mañana · M».
  final String title;

  /// Local wall-clock time; for an all-day event, midnight of [date].
  final DateTime start;

  /// For an all-day event, midnight of the next day (exclusive).
  final DateTime end;
  final bool allDay;

  /// What identifies this event across exports: the tag.
  String get tag => exportTag(
    calendarId,
    date,
    shiftTypeId,
    segment == 0 ? index : index + exportSecondSegmentIndexOffset,
  );

  /// The description written to the phone: one human line and the tag.
  String get description => '$exportMarkerLine\n$tag';

  /// Same shift on the phone: the title and the moments agree (all-day events
  /// only by their day, as platforms disagree on the end).
  bool matches(DeviceEvent e) {
    if (e.title != title || e.allDay != allDay) return false;
    if (allDay) {
      return e.start.year == start.year &&
          e.start.month == start.month &&
          e.start.day == start.day;
    }
    return e.start == start && e.end == end;
  }
}

/// `cuadrante:v1:<calendar>:<yyyy-MM-dd>:<shift type>:<n>`. The calendar and
/// the shift type go through `Uri.encodeComponent`, so an id with a colon or a
/// blank (a hand-edited backup) still makes a tag that parses back; the ids
/// Cuadrante makes (letters, digits, `-`, `_`) are written as they are.
String exportTag(String calendarId, CivilDate date, String typeId, int index) =>
    '$exportTagPrefix:${Uri.encodeComponent(calendarId)}:${date.toIso()}:'
    '${Uri.encodeComponent(typeId)}:$index';

final RegExp _tagLine = RegExp(
  '^${RegExp.escape(exportTagPrefix)}'
  r':([^:\s]+):(\d{4}-\d{2}-\d{2}):([^:\s]+):(\d+)$',
);

String _decodeId(String text) {
  try {
    return Uri.decodeComponent(text);
  } catch (_) {
    return text;
  }
}

/// What the tag in an event description says.
class ExportTag {
  const ExportTag(this.calendarId, this.date, this.typeId, this.index);

  final String calendarId;
  final CivilDate date;
  final String typeId;
  final int index;

  /// The tag in [description], or `null` when the event is not ours.
  ///
  /// Strict, because a match means the event may be deleted: the first line
  /// of the description must be exactly [exportMarkerLine] and the tag must
  /// be a whole line of its own. A tag quoted inside other text, or on an
  /// event whose description starts with anything else, is not ours.
  static ExportTag? parse(String? description) {
    if (description == null) return null;
    final lines = description.split(RegExp(r'\r\n|\n|\r'));
    if (lines.length < 2 || lines.first != exportMarkerLine) return null;
    for (final line in lines.skip(1)) {
      final match = _tagLine.firstMatch(line);
      if (match == null) continue;
      try {
        return ExportTag(
          _decodeId(match.group(1)!),
          CivilDate.parse(match.group(2)!),
          _decodeId(match.group(3)!),
          int.parse(match.group(4)!),
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String get key => exportTag(calendarId, date, typeId, index);
}

/// The events [schedule] gives from [from] to [to] (both included), one per
/// shift (two for a split shift, one per segment). Shifts of category rest
/// («Libre», «Saliente») are left out unless
/// [includeRest], and absences (vacations, sick leave...) unless
/// [includeAbsences]: the phone's calendar may be synced to an account, and a
/// sick leave must not travel there unless the user says so. Shifts with hours are timed events (a night shift ends on
/// the next day); the others are all-day. The range is cut to
/// [maxExportDays].
List<ExportEvent> buildExportEvents(
  Schedule schedule, {
  required String calendarId,
  required CivilDate from,
  required CivilDate to,
  bool includeRest = false,
  bool includeAbsences = false,
}) {
  final out = <ExportEvent>[];
  if (to.isBefore(from)) return out;
  final last = to.differenceInDays(from) + 1 > maxExportDays
      ? from.addDays(maxExportDays - 1)
      : to;
  for (final day in schedule.resolveRange(from, last)) {
    for (final (index, shift) in day.shifts.indexed) {
      if (shift.category == ShiftCategory.rest && !includeRest) continue;
      if (shift.category == ShiftCategory.absence && !includeAbsences) continue;
      final d = day.date;
      final title = '${shift.name} · ${shift.code}';
      if (shift.hasTimes) {
        final start = shift.startMinute!;
        final end = shift.endMinute!;
        // A split shift (A12) is two events, one per segment, in the order
        // of the day. Wall-clock times: a segment that begins or ends after
        // midnight lands on the next day.
        final segments = ShiftOccurrence.allOf(d, shift);
        if (segments.length == 1) {
          out.add(
            ExportEvent(
              calendarId: calendarId,
              date: d,
              shiftTypeId: shift.id,
              index: index,
              title: title,
              start: DateTime(d.year, d.month, d.day, start ~/ 60, start % 60),
              end: DateTime(
                d.year,
                d.month,
                d.day + (shift.crossesMidnight ? 1 : 0),
                end ~/ 60,
                end % 60,
              ),
              allDay: false,
            ),
          );
        } else {
          for (final o in segments) {
            out.add(
              ExportEvent(
                calendarId: calendarId,
                date: d,
                shiftTypeId: shift.id,
                index: index,
                segment: o.segment,
                title: title,
                start: DateTime(d.year, d.month, d.day, 0, o.startMinuteAbs),
                end: DateTime(d.year, d.month, d.day, 0, o.endMinuteAbs),
                allDay: false,
              ),
            );
          }
        }
      } else {
        out.add(
          ExportEvent(
            calendarId: calendarId,
            date: d,
            shiftTypeId: shift.id,
            index: index,
            title: title,
            start: DateTime(d.year, d.month, d.day),
            end: DateTime(d.year, d.month, d.day + 1),
            allDay: true,
          ),
        );
      }
    }
  }
  return out;
}

/// What a (re-)export has to do on the phone.
class ExportPlan {
  const ExportPlan({
    required this.toCreate,
    required this.toDelete,
    required this.unchanged,
  });

  final List<ExportEvent> toCreate;

  /// Events of a previous export that are out of date or repeated.
  final List<DeviceEvent> toDelete;

  /// Events already on the phone exactly as they should be.
  final int unchanged;

  bool get isNoop => toCreate.isEmpty && toDelete.isEmpty;

  /// Tells whether an event of [toDelete] is **replaced**: the export writes
  /// something for the same day (the shift changed). One that is not is only
  /// [removed]: nothing takes its place (the days off or the absences were
  /// switched off, or the day is empty now).
  bool Function(DeviceEvent event) get isReplaced {
    final days = {for (final e in toCreate) e.date};
    return (event) {
      final tag = ExportTag.parse(event.description);
      return tag != null && days.contains(tag.date);
    };
  }

  /// Of [toDelete], the events that are replaced (see [isReplaced]).
  int get replaced => toDelete.where(isReplaced).length;

  /// Events of a previous export that are deleted and not written again.
  int get removed => toDelete.length - replaced;
}

/// Compares what should be on the phone ([desired]) with what is
/// ([existing], the events of the target calendar around the range).
///
/// Only events of the phone calendar [deviceCalendarId] that carry our tag
/// for [calendarId] and a tag day inside `[from, to]` are ever deleted: the
/// user's own events, other calendars' exports, events of other phone
/// calendars and exported days outside the range are never touched. The tag's
/// day is the only criterion, not the day the event sits on now: an event the
/// user dragged to another date is still replaced. An event
/// that is already right stays (no churn), one that changed is deleted and
/// created again, a repeated one is deleted: running an export twice leaves
/// exactly the same events.
ExportPlan planExport({
  required List<ExportEvent> desired,
  required Iterable<DeviceEvent> existing,
  required String deviceCalendarId,
  required String calendarId,
  required CivilDate from,
  required CivilDate to,
}) {
  final byKey = <String, ExportEvent>{for (final e in desired) e.tag: e};
  final taken = <String>{};
  final toDelete = <DeviceEvent>[];
  var unchanged = 0;
  for (final event in existing) {
    if (event.calendarId != deviceCalendarId) continue;
    final tag = ExportTag.parse(event.description);
    if (tag == null ||
        tag.calendarId != calendarId ||
        tag.date.isBefore(from) ||
        tag.date.isAfter(to)) {
      continue;
    }
    final wanted = byKey[tag.key];
    if (wanted != null && !taken.contains(tag.key) && wanted.matches(event)) {
      taken.add(tag.key);
      unchanged++;
    } else {
      toDelete.add(event);
    }
  }
  return ExportPlan(
    toCreate: [
      for (final e in desired)
        if (!taken.contains(e.tag)) e,
    ],
    toDelete: toDelete,
    unchanged: unchanged,
  );
}
