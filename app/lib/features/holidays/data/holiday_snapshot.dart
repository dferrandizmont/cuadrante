import '../domain/holiday.dart';
import '../domain/holiday_calendar.dart';
import '../domain/holiday_entry.dart';
import '../domain/holiday_place.dart';
import '../../schedule/domain/civil_date.dart';

/// The chosen place and the stored rows that can apply to it (national, the
/// region's, the municipality's and the user's own), loaded in one go.
class HolidaySnapshot {
  HolidaySnapshot({
    required this.place,
    required Iterable<HolidayEntry> entries,
  }) : entries = List.unmodifiable(entries);

  /// Nothing loaded yet: no place, no holidays.
  static final HolidaySnapshot empty = HolidaySnapshot(
    place: HolidayPlace.none,
    entries: const [],
  );

  final HolidayPlace place;
  final List<HolidayEntry> entries;

  late final HolidayCalendar calendar = HolidayCalendar(
    entries,
    regionCode: place.regionCode,
    municipalityCode: place.municipalityCode,
  );

  /// One holiday per day, for every year stored.
  late final Map<CivilDate, Holiday> byDay = calendar.all();
}
