import '../../../core/format/text_fold.dart';
import '../../holidays/domain/holiday.dart';
import '../../schedule/domain/schedule_domain.dart';
import 'agenda_dates.dart';

/// One day of the agenda: its shifts, its note and the holiday the person
/// added by hand (public holidays are not listed: they are in the calendar).
class AgendaItem {
  const AgendaItem({
    required this.date,
    required this.shifts,
    this.note,
    this.reminderMinute,
    this.ownHoliday,
  });

  final CivilDate date;
  final List<ShiftType> shifts;

  /// Never blank.
  final String? note;

  /// Minute of the day at which the note rings as a reminder (A1), or null.
  /// Only meaningful with a [note]: the agenda lists notes.
  final int? reminderMinute;
  final Holiday? ownHoliday;
}

/// What a search found.
class AgendaSearchResult {
  const AgendaSearchResult({
    required this.items,
    required this.truncated,
    this.dateItem,
  });

  /// The day the query names when it is a date («15/10», «15 oct»), shown
  /// before [items] whether or not it has anything on it; never also in
  /// [items].
  final AgendaItem? dateItem;

  /// Upcoming days first (soonest first), then the past ones (latest first).
  final List<AgendaItem> items;

  /// More days matched than [items] holds.
  final bool truncated;
}

/// How many days «Turnos» lists, today included.
const int agendaShiftDays = 60;

/// How many results a search keeps.
const int agendaSearchLimit = 200;

/// Days either side of today whose rotation shifts a search looks at. Notes
/// and days changed by hand are searched in ALL time, whatever this says.
const int agendaSearchWindowDays = 366;

String? _noteOf(DayEntry? entry) {
  final note = entry?.note?.trim();
  return note == null || note.isEmpty ? null : note;
}

Map<CivilDate, Holiday> _ownHolidays(Iterable<Holiday> holidays) => {
  for (final h in holidays)
    if (h.isUserAdded) h.date: h,
};

AgendaItem _item(Schedule schedule, CivilDate date, Holiday? ownHoliday) {
  final day = schedule.resolve(date);
  return AgendaItem(
    date: date,
    shifts: day.shifts,
    note: _noteOf(schedule.entries[date]),
    reminderMinute: schedule.entries[date]?.noteReminderMinute,
    ownHoliday: ownHoliday,
  );
}

/// [date] as an agenda row: its shifts, note and own holiday (if any).
AgendaItem agendaItemOn(
  Schedule schedule,
  Iterable<Holiday> holidays,
  CivilDate date,
) => _item(schedule, date, _ownHolidays(holidays)[date]);

/// EVERY day of the next [days] days, [today] included (so the last one is
/// `today + days - 1`), soonest first, with its shifts, note and own
/// holiday. A day without shifts is in the list too (the agenda writes
/// «Libre» on it).
List<AgendaItem> upcomingShiftDays(
  Schedule schedule,
  Iterable<Holiday> holidays,
  CivilDate today, {
  int days = agendaShiftDays,
}) {
  final own = _ownHolidays(holidays);
  return [
    for (var i = 0; i < days; i++)
      _item(schedule, today.addDays(i), own[today.addDays(i)]),
  ];
}

/// The days from [today] on (today included) that have a note or an own
/// holiday, soonest first.
List<AgendaItem> upcomingAgenda(
  Schedule schedule,
  Iterable<Holiday> holidays,
  CivilDate today,
) {
  final own = _ownHolidays(holidays);
  final dates = <CivilDate>{
    for (final entry in schedule.entries.entries)
      if (_noteOf(entry.value) != null && !entry.key.isBefore(today)) entry.key,
    for (final date in own.keys)
      if (!date.isBefore(today)) date,
  }.toList()..sort();
  return [for (final date in dates) _item(schedule, date, own[date])];
}

/// Days that match [query], accent- and case-insensitively: every word of it
/// has to appear in the note, in the name of one of the day's shifts or in
/// the name of its own holiday, or, for an own holiday, the word «festivo» (also in the plural).
/// Emojis match as they are.
///
/// Notes, own holidays and days changed by hand are searched in all time;
/// the shifts the rotation gives only within [agendaSearchWindowDays] of
/// [today] (they repeat for ever). An empty query finds nothing.
///
/// With [months] (see [agendaMonthLookup]) a query that is a date («15/10»,
/// «15 octubre») also gives that day as [AgendaSearchResult.dateItem], even
/// if nothing is on it; the text matches follow.
AgendaSearchResult searchAgenda(
  Schedule schedule,
  Iterable<Holiday> holidays,
  String query,
  CivilDate today, {
  int limit = agendaSearchLimit,
  int windowDays = agendaSearchWindowDays,
  AgendaMonthLookup? months,
  String holidayKeywords = '',
}) {
  final words = foldSpanish(query)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return const AgendaSearchResult(items: [], truncated: false);
  }

  final own = _ownHolidays(holidays);
  final named = months == null
      ? null
      : parseAgendaDate(query, today, months: months);
  final dateItem = named == null ? null : _item(schedule, named, own[named]);
  final foldedNames = {
    for (final type in schedule.shiftTypes) type.id: foldSpanish(type.name),
  };
  final dates = <CivilDate>{
    ...schedule.entries.keys,
    ...own.keys,
    for (var i = -windowDays; i <= windowDays; i++) today.addDays(i),
  };

  final matches = <AgendaItem>[];
  for (final date in dates) {
    if (date == named) continue;
    final item = _item(schedule, date, own[date]);
    if (item.note == null && item.shifts.isEmpty && item.ownHoliday == null) {
      continue;
    }
    final haystack = [
      if (item.note != null) foldSpanish(item.note!),
      for (final shift in item.shifts) ?foldedNames[shift.id],
      if (item.ownHoliday != null) ...[
        foldSpanish(item.ownHoliday!.name),
        foldSpanish(holidayKeywords),
      ],
    ].join('\n');
    if (words.every(haystack.contains)) matches.add(item);
  }

  matches.sort((a, b) {
    final aPast = a.date.isBefore(today);
    final bPast = b.date.isBefore(today);
    if (aPast != bPast) return aPast ? 1 : -1;
    return aPast ? b.date.compareTo(a.date) : a.date.compareTo(b.date);
  });
  return AgendaSearchResult(
    dateItem: dateItem,
    items: matches.take(limit).toList(),
    truncated: matches.length > limit,
  );
}

/// [items] split into runs of the same month, keeping their order.
List<({int year, int month, List<AgendaItem> items})> groupByMonth(
  List<AgendaItem> items,
) {
  final groups = <({int year, int month, List<AgendaItem> items})>[];
  for (final item in items) {
    final last = groups.isEmpty ? null : groups.last;
    if (last != null &&
        last.year == item.date.year &&
        last.month == item.date.month) {
      last.items.add(item);
    } else {
      groups.add((year: item.date.year, month: item.date.month, items: [item]));
    }
  }
  return groups;
}
