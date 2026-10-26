import '../../schedule/domain/civil_date.dart';
import 'holiday.dart';
import 'holiday_entry.dart';
import 'spanish_regions.dart';

/// The holidays a person sees, from the loaded rows and the place they chose.
///
/// Semantics copied from Mochila's `officialCalendar`
/// (`backend/src/calendars/official.ts`):
/// - National file: everybody gets it.
/// - Regional file of the chosen region: its `origin: regional` rows are
///   regional holidays; its `origin: national-optional` rows are national
///   holidays that region keeps. A national day the region did not keep (Holy
///   Thursday in Catalunya) is simply not in its file, which is how a region
///   "replaces" a replaceable national day.
/// - Local holidays only appear with a chosen region **and** municipality,
///   and only those stored for that municipality in that region.
/// - Output order: date, then national < regional < local, then name.
///
/// On top of that, for the month grid: one holiday per day, the most specific
/// wins (local > regional > national), and a holiday the user added by hand
/// wins over everything.
class HolidayCalendar {
  HolidayCalendar(
    Iterable<HolidayEntry> entries, {
    String? regionCode,
    this.municipalityCode,
  }) : regionCode = normalizeRegionCode(regionCode),
       _entries = List.unmodifiable(entries);

  /// A calendar with no rows: nothing is a holiday.
  static final HolidayCalendar empty = HolidayCalendar(const []);

  /// Chosen region (`ES-CT`) or null: only the national holidays then.
  final String? regionCode;

  /// Chosen municipality (INE code) or null.
  final String? municipalityCode;
  final List<HolidayEntry> _entries;

  bool _applies(HolidayEntry e) {
    if (e.source == HolidaySource.user) return true;
    final region = regionCode;
    switch (e.scope) {
      case HolidayScope.national:
        // No region: the national file. A region: its kept national days.
        return e.regionCode == null ||
            (region != null && e.regionCode == region);
      case HolidayScope.regional:
        return region != null && e.regionCode == region;
      case HolidayScope.local:
        return region != null &&
            municipalityCode != null &&
            e.regionCode == region &&
            e.municipalityCode == municipalityCode;
    }
  }

  bool _inRange(HolidayEntry e, CivilDate from, CivilDate to) =>
      !e.date.isBefore(from) && !e.date.isAfter(to);

  /// Every holiday that applies between [from] and [to] (inclusive), in the
  /// order of `officialCalendar`. A day can appear more than once (a local
  /// holiday on a regional one).
  List<Holiday> list(CivilDate from, CivilDate to) {
    final out = [
      for (final e in _entries)
        if (_inRange(e, from, to) && _applies(e)) e,
    ]..sort(_byDateScopeName);
    return [for (final e in out) e.toHoliday()];
  }

  /// One holiday per day between [from] and [to]: user > local > regional >
  /// national (and, at equal scope, a remote row over a bundled one).
  Map<CivilDate, Holiday> between(CivilDate from, CivilDate to) {
    final best = <CivilDate, HolidayEntry>{};
    for (final e in _entries) {
      if (!_inRange(e, from, to) || !_applies(e)) continue;
      final current = best[e.date];
      if (current == null || _rank(e, current) > 0) best[e.date] = e;
    }
    final dates = best.keys.toList()..sort();
    return {for (final date in dates) date: best[date]!.toHoliday()};
  }

  /// Every day with a holiday in the loaded data.
  Map<CivilDate, Holiday> all() =>
      between(const CivilDate(1, 1, 1), const CivilDate(9999, 12, 31));

  Holiday? on(CivilDate date) => between(date, date)[date];

  static int _scopeOrder(HolidayEntry e) => switch (e.scope) {
    HolidayScope.national => 0,
    HolidayScope.regional => 1,
    HolidayScope.local => 2,
  };

  static int _sourceOrder(HolidayEntry e) => switch (e.source) {
    HolidaySource.bundled => 0,
    HolidaySource.remote => 1,
    HolidaySource.user => 2,
  };

  static int _byDateScopeName(HolidayEntry a, HolidayEntry b) {
    final d = a.date.compareTo(b.date);
    if (d != 0) return d;
    final s = _scopeOrder(a).compareTo(_scopeOrder(b));
    return s != 0 ? s : a.name.compareTo(b.name);
  }

  /// Positive when [a] should be shown instead of [b] (same day).
  static int _rank(HolidayEntry a, HolidayEntry b) {
    final user = (a.source == HolidaySource.user ? 1 : 0).compareTo(
      b.source == HolidaySource.user ? 1 : 0,
    );
    if (user != 0) return user;
    final scope = _scopeOrder(a).compareTo(_scopeOrder(b));
    if (scope != 0) return scope;
    final source = _sourceOrder(a).compareTo(_sourceOrder(b));
    if (source != 0) return source;
    // Deterministic whatever the row order: the name that sorts first.
    return b.name.compareTo(a.name);
  }
}
