import '../../schedule/domain/presets.dart';

/// Id of the calendar every database has from schema v2 on: the one the v1
/// data is attached to, and the default for `calendars.active` and
/// `calendars.primary` (docs/datos.md, "Esquema v2").
const String mainCalendarId = 'main';

/// Name given to [mainCalendarId] when it is created (user-visible; the user
/// can rename it).
const String mainCalendarName = 'Mi cuadrante';

/// The name [mainCalendarId] gets when a NEW install creates it: the one in
/// the app's language (`CatalogTexts`), «Mi cuadrante» in Spanish or when
/// the language is not known yet. Calendars that already exist, and the ones
/// an upgrade or a restore brings, keep their name.
String newMainCalendarName() =>
    catalogTexts.mainCalendarName ?? mainCalendarName;

/// Colour of [mainCalendarId]: indigo, the "night" shift colour (ARGB).
const int mainCalendarColor = 0xFF4B4FD1;

/// A schedule the user keeps (second job, partner...). Shift types and
/// patterns are shared by all calendars; runs and days belong to one.
class Calendar {
  const Calendar({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.sortOrder,
    this.archived = false,
  });

  final String id;
  final String name;

  /// ARGB.
  final int colorValue;
  final int sortOrder;

  /// "Deleting" a calendar archives it: its rotations and days stay stored.
  final bool archived;

  Calendar copyWith({
    String? name,
    int? colorValue,
    int? sortOrder,
    bool? archived,
  }) => Calendar(
    id: id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
  );

  @override
  bool operator ==(Object other) =>
      other is Calendar &&
      other.id == id &&
      other.name == name &&
      other.colorValue == colorValue &&
      other.sortOrder == sortOrder &&
      other.archived == archived;

  @override
  int get hashCode => Object.hash(id, name, colorValue, sortOrder, archived);

  @override
  String toString() => 'Calendar($id, $name${archived ? ', archived' : ''})';
}

/// Why a calendar operation was refused. Typed so the UI can explain it.
sealed class CalendarException implements Exception {
  const CalendarException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The only calendar left cannot be archived: the app always has one.
class LastCalendarCannotBeArchived extends CalendarException {
  const LastCalendarCannotBeArchived()
    : super('The last calendar cannot be archived');
}

/// No such calendar, or it is archived where an active one is needed.
class CalendarNotFound extends CalendarException {
  const CalendarNotFound(String id) : super('No active calendar "$id"');
}
