import '../../schedule/domain/civil_date.dart';
import 'holiday.dart';

/// One stored holiday row: a date that applies to everybody, to one region or
/// to one municipality. `HolidayCalendar` decides which of them a person
/// sees.
///
/// - National, `regionCode == null`: applies everywhere.
/// - National with a `regionCode`: a national holiday that region keeps
///   (`origin: national-optional` in the Mochila files: Epiphany, Holy
///   Thursday, All Saints moved to Monday...).
/// - Regional: only in that region.
/// - Local: only in that municipality (INE code).
/// - User: added by hand, applies whatever the chosen place is.
class HolidayEntry {
  const HolidayEntry({
    required this.date,
    required this.scope,
    required this.name,
    this.regionCode,
    this.municipalityCode,
    this.source = HolidaySource.bundled,
  });

  final CivilDate date;
  final HolidayScope scope;
  final String name;

  /// `ES-CT` or null.
  final String? regionCode;

  /// INE code, five digits, or null.
  final String? municipalityCode;
  final HolidaySource source;

  Holiday toHoliday() =>
      Holiday(date: date, name: name, scope: scope, source: source);

  @override
  bool operator ==(Object other) =>
      other is HolidayEntry &&
      other.date == date &&
      other.scope == scope &&
      other.name == name &&
      other.regionCode == regionCode &&
      other.municipalityCode == municipalityCode &&
      other.source == source;

  @override
  int get hashCode =>
      Object.hash(date, scope, name, regionCode, municipalityCode, source);

  @override
  String toString() =>
      'HolidayEntry($date, ${scope.name}, $name, $regionCode, '
      '$municipalityCode, ${source.name})';
}
