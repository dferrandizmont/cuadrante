import '../../schedule/domain/schedule_domain.dart';

/// Most source events one import reads. More than this is cut (the oldest
/// first, by date) and the wizard says so: a calendar this big is almost
/// never all shifts, and the wizard has to stay responsive.
const int maxImportEvents = 5000;

/// Most single days an import produces from those events (a multi-day
/// all-day event gives one per day).
const int maxImportOccurrences = 20000;

/// Largest file (`.ics` or CSV) the import reads.
const int maxImportFileBytes = 5 * 1024 * 1024;

/// Largest LRHSoft backup (`.Shifter`, a SQLite database) the import opens.
/// Bigger than [maxImportFileBytes] because the file also holds the photos
/// and drawings of the days, which the import does not read.
const int maxLrhsoftFileBytes = 50 * 1024 * 1024;

/// Most day rows and most shift types an LRHSoft backup may hold. More is
/// refused as too complex (20 000 days are 54 years).
const int maxLrhsoftDays = 20000;
const int maxLrhsoftShiftTypes = 500;

/// Longest day note kept from an LRHSoft backup, in UTF-16 units.
const int maxImportNoteLength = 2000;

/// How long the wizard waits for one background job (reading a file, working
/// out its days) before it gives up and shows
/// [ImportProblem.tooComplex]. An isolate cannot be stopped from outside, so
/// the job may keep running a while; the wizard just stops waiting.
const Duration importWorkTimeout = Duration(seconds: 30);

/// Longest range the wizard accepts, in days (five years).
const int maxImportRangeDays = 1830;

/// One all-day event is never expanded to more days than this.
const int maxAllDaySpanDays = 366;

/// Longest title kept: a hostile file with a title of megabytes would
/// otherwise reach the screen as one huge line of text.
const int maxImportTitleLength = 120;

/// [title] cut to [maxImportTitleLength] UTF-16 units, never inside a
/// surrogate pair.
String clipTitle(String title) {
  if (title.length <= maxImportTitleLength) return title;
  var end = maxImportTitleLength;
  final last = title.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end--;
  return title.substring(0, end);
}

/// Why an import stopped. The wizard shows a Spanish message per problem;
/// nothing here carries text from the source (no names, no titles).
enum ImportProblem {
  /// The calendar permission was refused (or not given yet).
  permissionDenied,

  /// The system does not let this app use calendars (parental controls, a
  /// work profile).
  permissionRestricted,

  /// The phone has no calendar provider, or it failed.
  calendarUnavailable,

  /// The calendar could not be read.
  readFailed,

  /// The file is bigger than [maxImportFileBytes].
  fileTooLarge,

  /// The file could not be opened or read.
  fileUnreadable,

  /// The text is not an iCalendar file.
  notCalendarFile,

  /// A CSV with no usable text, or with no column that looks like dates.
  notCsv,

  /// A SQLite file (or a `.Shifter`) that is not an LRHSoft backup: it is
  /// damaged, or lacks the `dias` / `tablaTurnos` tables.
  notLrhsoftFile,

  /// Readable, but no event in it falls on a day inside the range.
  noEvents,

  /// Reading took longer than [importWorkTimeout]: the file is too big or too
  /// tangled for this phone.
  tooComplex,

  /// Anything unexpected while reading (never shown raw).
  unknown,
}

/// A typed failure of an import step. Parsers throw this and nothing else.
class ImportException implements Exception {
  const ImportException(this.problem);

  final ImportProblem problem;

  @override
  String toString() => 'ImportException(${problem.name})';
}

/// The days an import looks at, both ends included.
class ImportRange {
  const ImportRange(this.from, this.to);

  /// The default of the wizard: the last 12 months and the next 6, counted
  /// from [today].
  factory ImportRange.around(CivilDate today) =>
      ImportRange(_shiftMonths(today, -12), _shiftMonths(today, 6).addDays(-1));

  final CivilDate from;
  final CivilDate to;

  bool get isValid => !to.isBefore(from);

  /// Number of days, both ends included.
  int get days => to.differenceInDays(from) + 1;

  bool contains(CivilDate d) => !d.isBefore(from) && !d.isAfter(to);

  /// The range cut down to at most [maxImportRangeDays] (keeps the end).
  ImportRange clamped() => days <= maxImportRangeDays
      ? this
      : ImportRange(to.addDays(-(maxImportRangeDays - 1)), to);

  /// The range cut down to at most [maxImportRangeDays], keeping the start
  /// (for a file that begins in the future).
  ImportRange clampedKeepingStart() => days <= maxImportRangeDays
      ? this
      : ImportRange(from, from.addDays(maxImportRangeDays - 1));

  ImportRange copyWith({CivilDate? from, CivilDate? to}) =>
      ImportRange(from ?? this.from, to ?? this.to);

  @override
  bool operator ==(Object other) =>
      other is ImportRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'ImportRange(${from.toIso()}..${to.toIso()})';
}

/// [date] moved by [months], keeping the day (cut to the end of a shorter
/// month).
CivilDate _shiftMonths(CivilDate date, int months) {
  final index = date.year * 12 + (date.month - 1) + months;
  final year = index ~/ 12;
  final month = index % 12 + 1;
  final last = CivilDate(year, month, 1).daysInMonth;
  return CivilDate(year, month, date.day > last ? last : date.day);
}

/// [date] moved by whole [months] (public for the export range).
CivilDate addMonths(CivilDate date, int months) => _shiftMonths(date, months);

/// One event as its source gives it, in the phone's wall-clock time.
///
/// - All-day ([allDay]): from [startDate] up to **but not including**
///   [endDate]; `endDate <= startDate` means a single day. No minutes.
/// - Timed: starts on [startDate] at [startMinute] (0..1439); [endDate] and
///   [endMinute] are optional (no end given). The event belongs to the day it
///   starts, also when it crosses midnight.
class RawEvent {
  const RawEvent({
    required this.title,
    required this.startDate,
    this.startMinute,
    this.endDate,
    this.endMinute,
    this.allDay = false,
    this.colorValue,
  });

  final String title;
  final CivilDate startDate;
  final int? startMinute;
  final CivilDate? endDate;
  final int? endMinute;
  final bool allDay;

  /// ARGB colour the source gives the event (a device calendar's colour).
  final int? colorValue;
}

/// One event on one day: what the wizard groups and maps.
class EventOccurrence {
  const EventOccurrence({
    required this.title,
    required this.date,
    this.startMinute,
    this.endMinute,
    this.allDay = false,
    this.colorValue,
    this.segment2StartMinute,
    this.segment2EndMinute,
    this.codeHint,
  });

  final String title;
  final CivilDate date;

  /// Minutes since 00:00 of [date]; `null` for all-day events.
  final int? startMinute;

  /// End as a time of day (it is on the next day when `<= startMinute`);
  /// `null` for all-day events and for events with no end.
  final int? endMinute;
  final bool allDay;
  final int? colorValue;

  /// Second segment of a split shift (clock minutes), only from sources that
  /// know shift types (an LRHSoft backup). Both set or both `null`.
  final int? segment2StartMinute;
  final int? segment2EndMinute;

  /// The short code the source uses for this shift («Mor.»), used to
  /// suggest the code of a new type.
  final String? codeHint;

  bool get hasTimes => !allDay && startMinute != null;
}

/// What cutting [RawEvent]s down to days gave.
class Expansion {
  const Expansion(this.occurrences, {this.truncated = false});

  final List<EventOccurrence> occurrences;

  /// More was there than [maxImportEvents] / [maxImportOccurrences]: the
  /// list holds the earliest ones.
  final bool truncated;
}

/// Cuts [events] into single days inside [range].
///
/// Only events that touch the range count towards the limits. All-day events
/// give one occurrence per day (never more than [maxAllDaySpanDays] per
/// event); timed events give one on the day they start, whatever their
/// length. At most [eventLimit] events are read (the earliest by start date)
/// and [occurrenceLimit] days come out; either cut sets [Expansion.truncated].
Expansion expandEvents(
  Iterable<RawEvent> events,
  ImportRange range, {
  int eventLimit = maxImportEvents,
  int occurrenceLimit = maxImportOccurrences,
}) {
  final inRange = <RawEvent>[];
  for (final e in events) {
    if (e.allDay) {
      final last = _lastDay(e);
      if (!last.isBefore(range.from) && !e.startDate.isAfter(range.to)) {
        inRange.add(e);
      }
    } else if (e.startMinute != null && range.contains(e.startDate)) {
      inRange.add(e);
    }
  }
  var truncated = false;
  inRange.sort((a, b) => a.startDate.compareTo(b.startDate));
  final read = inRange.length > eventLimit
      ? inRange.sublist(0, eventLimit)
      : inRange;
  if (read.length < inRange.length) truncated = true;

  final out = <EventOccurrence>[];
  for (final e in read) {
    if (e.allDay) {
      var day = e.startDate.isBefore(range.from) ? range.from : e.startDate;
      final last = _lastDay(e);
      final end = last.isAfter(range.to) ? range.to : last;
      for (; !day.isAfter(end); day = day.addDays(1)) {
        out.add(
          EventOccurrence(
            title: clipTitle(e.title),
            date: day,
            allDay: true,
            colorValue: e.colorValue,
          ),
        );
      }
    } else {
      out.add(
        EventOccurrence(
          title: clipTitle(e.title),
          date: e.startDate,
          startMinute: e.startMinute,
          endMinute: e.endMinute,
          colorValue: e.colorValue,
        ),
      );
    }
  }
  out.sort(_byDate);
  if (out.length > occurrenceLimit) {
    return Expansion(out.sublist(0, occurrenceLimit), truncated: true);
  }
  return Expansion(out, truncated: truncated);
}

/// Last day an all-day event covers (never more than [maxAllDaySpanDays]
/// after its first).
CivilDate _lastDay(RawEvent e) {
  final last = e.endDate != null && e.endDate!.isAfter(e.startDate)
      ? e.endDate!.addDays(-1)
      : e.startDate;
  return last.differenceInDays(e.startDate) + 1 > maxAllDaySpanDays
      ? e.startDate.addDays(maxAllDaySpanDays - 1)
      : last;
}

int _byDate(EventOccurrence a, EventOccurrence b) {
  final byDate = a.date.compareTo(b.date);
  if (byDate != 0) return byDate;
  return (a.startMinute ?? -1).compareTo(b.startMinute ?? -1);
}
