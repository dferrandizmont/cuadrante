import '../../schedule/domain/schedule_domain.dart';

/// Most steps one rule takes while looking for dates: a malformed or hostile
/// rule can never loop for long.
const int _maxRuleSteps = 200000;

/// Most weekday entries a `BYDAY` may keep once repeated ones are dropped
/// (a plain week has 7; with ordinals 11 per weekday is already far more than
/// any real calendar writes).
const int maxByDayEntries = 77;

/// Most distinct `BYMONTHDAY` entries (-31..-1 and 1..31).
const int maxByMonthDayEntries = 62;

/// Most distinct `BYMONTH` entries.
const int maxByMonthEntries = 12;

/// Longest list of any `BY...` part read at all, repeated entries included:
/// anything longer is hostile, and is refused before it is worked through.
const int _maxRawListItems = 1000;

/// A pool of rule steps shared by many rules: when it runs dry every rule
/// stops, so a file of thousands of rules is bounded as a whole and not only
/// rule by rule.
class StepBudget {
  StepBudget(this.remaining);

  int remaining;

  bool get exhausted => remaining <= 0;

  /// Spends one step; `false` when there is none left.
  bool take() {
    if (remaining <= 0) return false;
    remaining--;
    return true;
  }
}

enum RecurrenceFrequency { daily, weekly, monthly }

/// A `BYDAY` entry: a weekday (1 = Monday ... 7 = Sunday) with an optional
/// ordinal (`1MO` = the first Monday of the month, `-1FR` = the last Friday).
class WeekdayRule {
  const WeekdayRule(this.weekday, [this.ordinal]);

  final int weekday;
  final int? ordinal;

  @override
  bool operator ==(Object other) =>
      other is WeekdayRule &&
      other.weekday == weekday &&
      other.ordinal == ordinal;

  @override
  int get hashCode => Object.hash(weekday, ordinal);
}

/// The part of an iCalendar `RRULE` this import understands: `FREQ` DAILY,
/// WEEKLY and MONTHLY with `INTERVAL`, `COUNT`, `UNTIL`, `BYDAY`,
/// `BYMONTHDAY`, `BYMONTH` and `WKST`.
class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.count,
    this.until,
    this.byDay = const [],
    this.byMonthDay = const [],
    this.byMonth = const [],
    this.weekStart = DateTime.monday,
  });

  final RecurrenceFrequency frequency;
  final int interval;
  final int? count;

  /// Last day (included), taken from the date part of `UNTIL`.
  final CivilDate? until;
  final List<WeekdayRule> byDay;
  final List<int> byMonthDay;
  final List<int> byMonth;
  final int weekStart;

  /// Reads the value of an `RRULE` property (`FREQ=WEEKLY;BYDAY=MO,TU`).
  /// Returns `null` when the rule cannot be expanded here (another frequency,
  /// `BYSETPOS`, no `FREQ`, a bad number): the event then counts once, on its
  /// first day.
  static RecurrenceRule? parse(String value) {
    final parts = <String, String>{};
    for (final piece in value.split(';')) {
      final eq = piece.indexOf('=');
      if (eq <= 0) continue;
      parts[piece.substring(0, eq).trim().toUpperCase()] = piece
          .substring(eq + 1)
          .trim();
    }
    final frequency = switch (parts['FREQ']?.toUpperCase()) {
      'DAILY' => RecurrenceFrequency.daily,
      'WEEKLY' => RecurrenceFrequency.weekly,
      'MONTHLY' => RecurrenceFrequency.monthly,
      _ => null,
    };
    if (frequency == null) return null;
    // Parts that change which days the rule gives and that are not supported.
    const unsupported = ['BYSETPOS', 'BYWEEKNO', 'BYYEARDAY'];
    if (unsupported.any(parts.containsKey)) return null;

    var interval = 1;
    if (parts.containsKey('INTERVAL')) {
      final n = int.tryParse(parts['INTERVAL']!);
      // 1000 is far past anything real (every 1000 weeks) and keeps the date
      // arithmetic of a hostile file inside what DateTime can hold.
      if (n == null || n < 1 || n > 1000) return null;
      interval = n;
    }
    int? count;
    if (parts.containsKey('COUNT')) {
      count = int.tryParse(parts['COUNT']!);
      if (count == null || count < 1) return null;
    }
    CivilDate? until;
    if (parts.containsKey('UNTIL')) {
      until = _parseUntil(parts['UNTIL']!);
      if (until == null) return null;
    }

    // The lists are read as sets: a repeated entry changes nothing, and a
    // list longer than any real calendar writes makes the rule invalid (the
    // event then counts once and is reported).
    final byDay = <WeekdayRule>{};
    if (parts.containsKey('BYDAY')) {
      final raws = parts['BYDAY']!.split(',');
      if (raws.length > _maxRawListItems) return null;
      for (final raw in raws) {
        final rule = _parseWeekday(raw.trim().toUpperCase());
        if (rule == null) return null;
        byDay.add(rule);
      }
      if (byDay.length > maxByDayEntries) return null;
    }
    final byMonthDay = <int>{};
    if (parts.containsKey('BYMONTHDAY')) {
      final raws = parts['BYMONTHDAY']!.split(',');
      if (raws.length > _maxRawListItems) return null;
      for (final raw in raws) {
        final n = int.tryParse(raw.trim());
        if (n == null || n == 0 || n < -31 || n > 31) return null;
        byMonthDay.add(n);
      }
      if (byMonthDay.length > maxByMonthDayEntries) return null;
    }
    final byMonth = <int>{};
    if (parts.containsKey('BYMONTH')) {
      final raws = parts['BYMONTH']!.split(',');
      if (raws.length > _maxRawListItems) return null;
      for (final raw in raws) {
        final n = int.tryParse(raw.trim());
        if (n == null || n < 1 || n > 12) return null;
        byMonth.add(n);
      }
      if (byMonth.length > maxByMonthEntries) return null;
    }
    var weekStart = DateTime.monday;
    if (parts.containsKey('WKST')) {
      final w = _weekdays[parts['WKST']!.toUpperCase()];
      if (w == null) return null;
      weekStart = w;
    }
    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      count: count,
      until: until,
      byDay: byDay.toList(),
      byMonthDay: byMonthDay.toList(),
      byMonth: byMonth.toList(),
      weekStart: weekStart,
    );
  }

  /// The days of the rule that fall in `[from, to]`, in order, for an event
  /// whose first day is [start]. `COUNT` counts from [start], so it is honoured
  /// even when the window begins later. Never more than a bounded number of
  /// steps.
  ///
  /// With a [budget], every step also draws from it and the dates stop when it
  /// is empty (the caller reads [StepBudget.exhausted]).
  Iterable<CivilDate> datesBetween(
    CivilDate start,
    CivilDate from,
    CivilDate to, {
    StepBudget? budget,
  }) => switch (frequency) {
    RecurrenceFrequency.daily => _daily(start, from, to, budget),
    RecurrenceFrequency.weekly => _weekly(start, from, to, budget),
    RecurrenceFrequency.monthly => _monthly(start, from, to, budget),
  };

  bool _past(CivilDate d, CivilDate to) =>
      d.isAfter(to) || (until != null && d.isAfter(until!));

  Iterable<CivilDate> _daily(
    CivilDate start,
    CivilDate from,
    CivilDate to,
    StepBudget? budget,
  ) sync* {
    var emitted = 0;
    var k = 0;
    if (count == null) {
      final gap = from.differenceInDays(start);
      if (gap > 0) k = gap ~/ interval;
    }
    for (var steps = 0; steps < _maxRuleSteps; steps++, k++) {
      if (budget != null && !budget.take()) return;
      final d = start.addDays(k * interval);
      if (_past(d, to)) return;
      if (byMonth.isNotEmpty && !byMonth.contains(d.month)) continue;
      if (byDay.isNotEmpty && !byDay.any((b) => b.weekday == d.weekday)) {
        continue;
      }
      if (count != null && emitted >= count!) return;
      emitted++;
      if (!d.isBefore(from)) yield d;
    }
  }

  Iterable<CivilDate> _weekly(
    CivilDate start,
    CivilDate from,
    CivilDate to,
    StepBudget? budget,
  ) sync* {
    final weekdays = {
      for (final b in byDay) b.weekday,
      if (byDay.isEmpty) start.weekday,
    }.toList();
    // Offsets from the first day of the week (WKST), in order.
    final offsets = [for (final w in weekdays) (w - weekStart + 7) % 7]..sort();
    final firstWeek = start.addDays(-((start.weekday - weekStart + 7) % 7));
    var emitted = 0;
    var k = 0;
    if (count == null) {
      final weeks = from.differenceInDays(firstWeek) ~/ 7;
      if (weeks > 0) k = weeks ~/ interval;
    }
    for (var steps = 0; steps < _maxRuleSteps; steps++, k++) {
      if (budget != null && !budget.take()) return;
      final week = firstWeek.addDays(7 * interval * k);
      if (_past(week, to)) return;
      for (final offset in offsets) {
        final d = week.addDays(offset);
        if (d.isBefore(start)) continue;
        if (_past(d, to)) return;
        if (byMonth.isNotEmpty && !byMonth.contains(d.month)) continue;
        if (count != null && emitted >= count!) return;
        emitted++;
        if (!d.isBefore(from)) yield d;
      }
    }
  }

  Iterable<CivilDate> _monthly(
    CivilDate start,
    CivilDate from,
    CivilDate to,
    StepBudget? budget,
  ) sync* {
    final firstIndex = start.year * 12 + start.month - 1;
    var emitted = 0;
    var k = 0;
    if (count == null) {
      final gap = from.year * 12 + from.month - 1 - firstIndex;
      if (gap > 0) k = gap ~/ interval;
    }
    for (var steps = 0; steps < _maxRuleSteps; steps++, k++) {
      if (budget != null && !budget.take()) return;
      final index = firstIndex + k * interval;
      final first = CivilDate(index ~/ 12, index % 12 + 1, 1);
      if (_past(first, to)) return;
      if (byMonth.isNotEmpty && !byMonth.contains(first.month)) continue;
      for (final d in _monthDays(first, start)) {
        if (d.isBefore(start)) continue;
        if (_past(d, to)) return;
        if (count != null && emitted >= count!) return;
        emitted++;
        if (!d.isBefore(from)) yield d;
      }
    }
  }

  /// The days of the month of [first] the rule picks, in order.
  List<CivilDate> _monthDays(CivilDate first, CivilDate start) {
    final length = first.daysInMonth;
    final days = <int>{};
    if (byMonthDay.isNotEmpty) {
      for (final n in byMonthDay) {
        final day = n > 0 ? n : length + n + 1;
        if (day >= 1 && day <= length) days.add(day);
      }
    }
    if (byDay.isNotEmpty) {
      // Days of the month per weekday, worked out once per month (not once
      // per BYDAY entry).
      final perWeekday = <int, List<int>>{};
      List<int> matching(int weekday) => perWeekday.putIfAbsent(weekday, () {
        final firstDay = (weekday - first.weekday + 7) % 7 + 1;
        return [for (var d = firstDay; d <= length; d += 7) d];
      });
      final byWeekday = <int>{};
      for (final rule in byDay) {
        final inMonth = matching(rule.weekday);
        final ordinal = rule.ordinal;
        if (ordinal == null) {
          byWeekday.addAll(inMonth);
        } else {
          final i = ordinal > 0 ? ordinal - 1 : inMonth.length + ordinal;
          if (i >= 0 && i < inMonth.length) byWeekday.add(inMonth[i]);
        }
      }
      if (byMonthDay.isEmpty) {
        days.addAll(byWeekday);
      } else {
        days.retainAll(byWeekday);
      }
    }
    if (byMonthDay.isEmpty && byDay.isEmpty && start.day <= length) {
      days.add(start.day);
    }
    return [for (final d in days.toList()..sort()) first.addDays(d - 1)];
  }
}

const Map<String, int> _weekdays = {
  'MO': DateTime.monday,
  'TU': DateTime.tuesday,
  'WE': DateTime.wednesday,
  'TH': DateTime.thursday,
  'FR': DateTime.friday,
  'SA': DateTime.saturday,
  'SU': DateTime.sunday,
};

WeekdayRule? _parseWeekday(String text) {
  final match = RegExp(r'^([+-]?\d{1,2})?([A-Z]{2})$').firstMatch(text);
  if (match == null) return null;
  final weekday = _weekdays[match.group(2)];
  if (weekday == null) return null;
  final raw = match.group(1);
  if (raw == null) return WeekdayRule(weekday);
  final ordinal = int.tryParse(raw);
  if (ordinal == null || ordinal == 0 || ordinal.abs() > 53) return null;
  return WeekdayRule(weekday, ordinal);
}

/// `20261231`, `20261231T225959Z` or `20261231T235959` -> its date part.
CivilDate? _parseUntil(String text) {
  final match = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T\d{6}Z?)?$')
      .firstMatch(text.toUpperCase());
  if (match == null) return null;
  final y = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  final d = int.parse(match.group(3)!);
  if (m < 1 || m > 12 || d < 1) return null;
  if (d > CivilDate(y, m, 1).daysInMonth) return null;
  return CivilDate(y, m, d);
}
