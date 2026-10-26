import '../../schedule/domain/civil_date.dart';

/// Longest name the manual editor and holiday imports keep, in graphemes.
const int maxHolidayNameLength = 60;

enum HolidayScope { national, regional, local }

/// Where a stored holiday row comes from (the `source` column of `holidays`).
enum HolidaySource { bundled, remote, user }

/// A public holiday on a calendar day, as the calendar shows it.
class Holiday {
  const Holiday({
    required this.date,
    required this.name,
    required this.scope,
    this.source = HolidaySource.bundled,
  });

  final CivilDate date;
  final String name;

  /// Kept for the UI: national, regional or local (a holiday the user added
  /// by hand is `local` with [HolidaySource.user]).
  final HolidayScope scope;
  final HolidaySource source;

  bool get isUserAdded => source == HolidaySource.user;

  @override
  bool operator ==(Object other) =>
      other is Holiday &&
      other.date == date &&
      other.name == name &&
      other.scope == scope &&
      other.source == source;

  @override
  int get hashCode => Object.hash(date, name, scope, source);

  @override
  String toString() => 'Holiday($date, $name, ${scope.name}, ${source.name})';
}
