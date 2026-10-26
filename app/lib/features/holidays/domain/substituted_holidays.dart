import '../../schedule/domain/civil_date.dart';
import 'holiday.dart';
import 'holiday_entry.dart';
import 'spanish_regions.dart';

/// A replaceable national holiday that the chosen region does not apply.
class SubstitutedHoliday {
  const SubstitutedHoliday(this.date, this.name);

  final CivilDate date;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is SubstitutedHoliday && other.date == date && other.name == name;

  @override
  int get hashCode => Object.hash(date, name);

  @override
  String toString() => 'SubstitutedHoliday($date, $name)';
}

/// The replaceable national days of [year] that [regionCode] does not apply.
///
/// [regionalNational] is every national row some region keeps (the
/// `national-optional` rows of all regions). A region "replaces" a day by
/// simply not listing it (docs/festivos.md), so a day is substituted when
/// some region keeps it and [regionCode] has no such row on that date. With
/// no region nothing is substituted (the person has not chosen yet). Dates
/// that several regions name differently ("Lunes siguiente al Día de la
/// Constitución" / "... Española") take the name most regions use.
List<SubstitutedHoliday> substitutedNationalDays({
  required Iterable<HolidayEntry> regionalNational,
  required String? regionCode,
  required int year,
}) {
  final region = normalizeRegionCode(regionCode);
  if (region == null) return const [];
  final kept = <CivilDate>{};
  final names = <CivilDate, Map<String, int>>{};
  for (final e in regionalNational) {
    if (e.scope != HolidayScope.national ||
        e.regionCode == null ||
        e.source == HolidaySource.user ||
        e.date.year != year) {
      continue;
    }
    if (e.regionCode == region) kept.add(e.date);
    final byName = names.putIfAbsent(e.date, () => {});
    byName[e.name] = (byName[e.name] ?? 0) + 1;
  }
  final out = <SubstitutedHoliday>[];
  for (final MapEntry(key: date, value: byName) in names.entries) {
    if (kept.contains(date)) continue;
    final ranked = byName.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    out.add(SubstitutedHoliday(date, ranked.first.key));
  }
  return out..sort((a, b) => a.date.compareTo(b.date));
}
