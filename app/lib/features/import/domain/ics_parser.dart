import '../../schedule/domain/schedule_domain.dart';
import 'import_models.dart';
import 'recurrence.dart';

/// Most `VEVENT`s one file may hold; the rest is skipped (and counted).
const int maxIcsEvents = 50000;

/// Deepest `BEGIN` nesting the reader follows. A real file has two or three
/// levels (`VCALENDAR` > `VEVENT` > `VALARM`); deeper `BEGIN`s are ignored as
/// unknown.
const int maxIcsNesting = 32;

/// Longest `DURATION` read, in days. Longer is hostile (or a typo) and the
/// event is skipped.
const int maxIcsDurationDays = 366;

/// Steps (across all the rules of a file) spent working out the last day of a
/// file. When they run out the remaining rules count by their first day.
const int _spanBudgetSteps = 2000000;

/// A date, or a date and time, as an iCalendar property gives it.
class IcsTime {
  const IcsTime(this.date, {this.minute, this.zone});

  final CivilDate date;

  /// Minutes since 00:00; `null` for a `VALUE=DATE` (all-day) value.
  final int? minute;

  /// `null` = floating (the phone's own time), `'UTC'` for a trailing `Z`,
  /// otherwise the `TZID`.
  final String? zone;

  bool get allDay => minute == null;

  @override
  bool operator ==(Object other) =>
      other is IcsTime &&
      other.date == date &&
      other.minute == minute &&
      other.zone == zone;

  @override
  int get hashCode => Object.hash(date, minute, zone);

  @override
  String toString() => 'IcsTime(${date.toIso()} $minute $zone)';
}

/// One `VEVENT` as the file says it, before any recurrence is expanded.
class IcsEvent {
  const IcsEvent({
    required this.uid,
    required this.summary,
    required this.start,
    this.end,
    this.duration,
    this.rule,
    this.hasUnsupportedRule = false,
    this.exceptions = const [],
    this.recurrenceId,
    this.cancelled = false,
  });

  final String uid;
  final String summary;
  final IcsTime start;
  final IcsTime? end;

  /// `DURATION`, in minutes, when there is no `DTEND`.
  final int? duration;
  final RecurrenceRule? rule;

  /// The file has an `RRULE` this import cannot expand: the event counts once.
  final bool hasUnsupportedRule;

  /// `EXDATE` values.
  final List<IcsTime> exceptions;

  /// `RECURRENCE-ID`: this event replaces one occurrence of a series.
  final IcsTime? recurrenceId;
  final bool cancelled;

  /// Days an all-day event covers: from `DTEND` (exclusive) or, without it,
  /// from `DURATION`; one day when neither says; never more than
  /// [maxAllDaySpanDays].
  int get allDaySpanDays {
    final e = end;
    final int days;
    if (e != null) {
      days = e.date.differenceInDays(start.date);
    } else if (duration != null) {
      days = duration! ~/ 1440;
    } else {
      days = 1;
    }
    return days < 1 ? 1 : (days > maxAllDaySpanDays ? maxAllDaySpanDays : days);
  }
}

/// What reading an `.ics` gave.
///
/// [firstDate], [lastDate] and [hasOpenEndedRules] are worked out when the
/// document is made, which happens in the background isolate that reads the
/// file: the screen only reads the fields and never expands a rule.
class IcsDocument {
  IcsDocument({
    required this.events,
    this.skippedEvents = 0,
    this.unsupportedRules = 0,
  }) : firstDate = _firstDateOf(events),
       lastDate = _lastDateOf(events),
       hasOpenEndedRules = events.any(
         (e) =>
             e.rule != null && e.rule!.until == null && e.rule!.count == null,
       );

  final List<IcsEvent> events;

  /// `VEVENT`s left out: no usable `DTSTART`, a `DURATION` over
  /// [maxIcsDurationDays], or past [maxIcsEvents].
  final int skippedEvents;

  /// Events whose `RRULE` was not understood (they count once).
  final int unsupportedRules;

  /// Earliest start of any event, `null` when there is none.
  final CivilDate? firstDate;

  /// Latest day the file mentions: the last day of a one-off event, the last
  /// day of a series that ends (`UNTIL`, or `COUNT` worked out), the start of
  /// an open-ended series. `null` when there is no event.
  final CivilDate? lastDate;

  /// Some series has neither `UNTIL` nor `COUNT`: it goes on for ever, so only
  /// the range the user chooses cuts it.
  final bool hasOpenEndedRules;

  static CivilDate? _firstDateOf(List<IcsEvent> events) {
    CivilDate? first;
    for (final e in events) {
      if (first == null || e.start.date.isBefore(first)) first = e.start.date;
    }
    return first;
  }

  static CivilDate? _lastDateOf(List<IcsEvent> events) {
    CivilDate? last;
    final budget = StepBudget(_spanBudgetSteps);
    for (final e in events) {
      final day = _lastDayOf(e, budget);
      if (last == null || day.isAfter(last)) last = day;
    }
    return last;
  }

  static CivilDate _lastDayOf(IcsEvent e, StepBudget budget) {
    final rule = e.rule;
    final start = e.start.date;
    // The days one occurrence covers after its first (an all-day end is
    // exclusive).
    final tail = e.start.allDay ? e.allDaySpanDays - 1 : 0;
    if (rule == null) {
      if (e.start.allDay) return start.addDays(tail);
      final end = e.end?.date;
      return end == null || !end.isAfter(start) ? start : end;
    }
    if (rule.until != null) return rule.until!.addDays(tail);
    if (rule.count == null) return start;
    var last = start;
    for (final d in rule.datesBetween(
      start,
      start,
      start.addDays(3650),
      budget: budget,
    )) {
      last = d;
    }
    return last.addDays(tail);
  }
}

/// Reads iCalendar (RFC 5545) text. Tolerant by design: a line or an event it
/// cannot understand is skipped, never an exception. Throws [ImportException]
/// only when the text is not an iCalendar file at all.
///
/// Understood: line folding, `\n \, \; \\` escapes, `VEVENT` with `DTSTART`
/// and `DTEND` / `DURATION` (`VALUE=DATE`, local `...T...`, `...Z` and
/// `TZID=`), `SUMMARY`, `UID`, `STATUS:CANCELLED`, `RRULE`, `EXDATE` and
/// `RECURRENCE-ID`. `VTODO`, `VJOURNAL`, `VALARM`, `VTIMEZONE` and everything
/// else are ignored.
IcsDocument parseIcs(String text) {
  var source = text;
  if (source.startsWith('﻿')) source = source.substring(1);
  if (!RegExp(r'BEGIN:VCALENDAR', caseSensitive: false).hasMatch(source)) {
    throw const ImportException(ImportProblem.notCalendarFile);
  }

  final events = <IcsEvent>[];
  var skipped = 0;
  var unsupported = 0;
  final stack = <String>[];
  // How many of each kind are open.
  final open = <String, int>{};
  _EventBuilder? builder;

  for (final raw in _unfold(source)) {
    final line = _ContentLine.parse(raw);
    if (line == null) continue;
    switch (line.name) {
      case 'BEGIN':
        final kind = line.value.trim().toUpperCase();
        // Too deep: ignored, as if it were a kind nobody knows.
        if (stack.length >= maxIcsNesting) continue;
        stack.add(kind);
        open[kind] = (open[kind] ?? 0) + 1;
        if (kind == 'VEVENT') builder = _EventBuilder();
      case 'END':
        final kind = line.value.trim().toUpperCase();
        // A kind that is not open is dropped without looking at the stack.
        if ((open[kind] ?? 0) == 0) continue;
        // Closes [kind] and anything left open inside it. Every entry is
        // popped once, so the whole file stays linear.
        while (stack.isNotEmpty) {
          final top = stack.removeLast();
          open[top] = open[top]! - 1;
          if (top == kind) break;
        }
        if (kind == 'VEVENT' && builder != null) {
          final b = builder;
          builder = null;
          if (events.length >= maxIcsEvents) {
            skipped++;
            continue;
          }
          final event = b.build();
          if (event == null) {
            skipped++;
          } else {
            if (event.hasUnsupportedRule) unsupported++;
            events.add(event);
          }
        }
      default:
        // Only the properties of the VEVENT itself: those of a VALARM, a
        // VTIMEZONE or a VTODO inside it are deeper in the stack.
        if (builder != null && stack.isNotEmpty && stack.last == 'VEVENT') {
          builder.add(line);
        }
    }
  }
  return IcsDocument(
    events: events,
    skippedEvents: skipped,
    unsupportedRules: unsupported,
  );
}

/// Joins folded lines (a line starting with a space or a tab continues the
/// previous one) and splits on CRLF, LF or CR.
Iterable<String> _unfold(String text) sync* {
  final lines = text.split(RegExp(r'\r\n|\n|\r'));
  final current = StringBuffer();
  var open = false;
  for (final line in lines) {
    if (line.isNotEmpty && (line.startsWith(' ') || line.startsWith('\t'))) {
      if (open) {
        current.write(line.substring(1));
      } else {
        current.write(line.substring(1));
        open = true;
      }
      continue;
    }
    if (open) yield current.toString();
    current.clear();
    current.write(line);
    open = true;
  }
  if (open) yield current.toString();
}

/// `NAME;PARAM=value;PARAM="a:b":text`.
class _ContentLine {
  _ContentLine(this.name, this.params, this.value);

  final String name;
  final Map<String, String> params;
  final String value;

  static _ContentLine? parse(String line) {
    if (line.isEmpty) return null;
    var inQuote = false;
    var colon = -1;
    for (var i = 0; i < line.length; i++) {
      final c = line.codeUnitAt(i);
      if (c == 0x22) {
        inQuote = !inQuote;
      } else if (c == 0x3A && !inQuote) {
        colon = i;
        break;
      }
    }
    if (colon <= 0) return null;
    final head = line.substring(0, colon);
    final value = line.substring(colon + 1);

    final pieces = <String>[];
    var start = 0;
    inQuote = false;
    for (var i = 0; i < head.length; i++) {
      final c = head.codeUnitAt(i);
      if (c == 0x22) {
        inQuote = !inQuote;
      } else if (c == 0x3B && !inQuote) {
        pieces.add(head.substring(start, i));
        start = i + 1;
      }
    }
    pieces.add(head.substring(start));
    final name = pieces.first.trim().toUpperCase();
    if (name.isEmpty) return null;
    final params = <String, String>{};
    for (final piece in pieces.skip(1)) {
      final eq = piece.indexOf('=');
      if (eq <= 0) continue;
      var v = piece.substring(eq + 1).trim();
      if (v.length >= 2 && v.startsWith('"') && v.endsWith('"')) {
        v = v.substring(1, v.length - 1);
      }
      params[piece.substring(0, eq).trim().toUpperCase()] = v;
    }
    return _ContentLine(name, params, value);
  }
}

class _EventBuilder {
  String uid = '';
  String summary = '';
  IcsTime? start;
  IcsTime? end;
  int? duration;
  bool durationTooLong = false;
  RecurrenceRule? rule;
  bool sawRule = false;
  final exceptions = <IcsTime>[];
  IcsTime? recurrenceId;
  bool cancelled = false;

  void add(_ContentLine line) {
    switch (line.name) {
      case 'UID':
        uid = line.value.trim();
      case 'SUMMARY':
        summary = unescapeIcsText(line.value).trim();
      case 'DTSTART':
        start = parseIcsTime(line.value, line.params);
      case 'DTEND':
        end = parseIcsTime(line.value, line.params);
      case 'DURATION':
        final minutes = _parseDuration(line.value);
        if (minutes != null && minutes > maxIcsDurationDays * 1440) {
          durationTooLong = true;
        } else {
          duration = minutes;
        }
      case 'RRULE':
        sawRule = true;
        rule = RecurrenceRule.parse(line.value);
      case 'EXDATE':
        for (final piece in line.value.split(',')) {
          final t = parseIcsTime(piece, line.params);
          if (t != null) exceptions.add(t);
        }
      case 'RECURRENCE-ID':
        recurrenceId = parseIcsTime(line.value, line.params);
      case 'STATUS':
        cancelled = line.value.trim().toUpperCase() == 'CANCELLED';
    }
  }

  IcsEvent? build() {
    final s = start;
    if (s == null || durationTooLong) return null;
    return IcsEvent(
      uid: uid,
      summary: summary,
      start: s,
      end: end,
      duration: duration,
      rule: rule,
      hasUnsupportedRule: sawRule && rule == null,
      exceptions: exceptions,
      recurrenceId: recurrenceId,
      cancelled: cancelled,
    );
  }
}

/// Undoes the text escapes of iCalendar: `\n` and `\N` (new line), `\,`,
/// `\;` and `\\`. Any other backslash is kept.
String unescapeIcsText(String text) {
  if (!text.contains(r'\')) return text;
  final out = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == r'\' && i + 1 < text.length) {
      final next = text[i + 1];
      switch (next) {
        case 'n' || 'N':
          out.write('\n');
          i++;
          continue;
        case ',' || ';' || r'\':
          out.write(next);
          i++;
          continue;
      }
    }
    out.write(c);
  }
  return out.toString();
}

final RegExp _dateTimePattern = RegExp(
  r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$',
  caseSensitive: false,
);

/// A `DATE` (`20261019`) or `DATE-TIME` (`20261019T080000`, with `Z` or with
/// `TZID` among [params]). `null` when it is not a valid date or time.
IcsTime? parseIcsTime(String value, Map<String, String> params) {
  final match = _dateTimePattern.firstMatch(value.trim());
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1) return null;
  if (day > CivilDate(year, month, 1).daysInMonth) return null;
  final date = CivilDate(year, month, day);

  final hourText = match.group(4);
  final isDate = hourText == null || params['VALUE']?.toUpperCase() == 'DATE';
  if (isDate) return IcsTime(date);

  final hour = int.parse(hourText);
  final minute = int.parse(match.group(5)!);
  if (hour > 23 || minute > 59) return null;
  final utc = match.group(7) != null;
  final tzid = params['TZID']?.trim();
  return IcsTime(
    date,
    minute: hour * 60 + minute,
    zone: utc
        ? 'UTC'
        : (tzid == null || tzid.isEmpty)
        ? null
        : tzid,
  );
}

/// `P1D`, `PT8H`, `P1DT2H30M`, `P2W` in minutes. `null` for a negative or
/// malformed value. A part of more than six digits counts as ten million, far
/// over any limit, so the sum can never overflow.
int? _parseDuration(String value) {
  final match = RegExp(
    r'^\+?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;
  int part(int i) {
    final text = match.group(i);
    if (text == null) return 0;
    if (text.length > 6) return 10000000;
    return int.parse(text);
  }

  return part(1) * 7 * 1440 + part(2) * 1440 + part(3) * 60 + part(4);
}
