// The CHECKs of start/end minute name the column being declared (the idiom
// from the Drift docs).
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../features/schedule/domain/shift_type.dart';
import 'converters.dart';

/// Schema v4 (see docs/datos.md). Calendar dates are ISO text, timestamps are
/// milliseconds since the epoch (UTC), id lists are JSON text.
///
/// The row classes are called `*Row` so they never collide with the engine
/// models (`ShiftType`, `Pattern`...) or with `dart:core`.

@DataClassName('ShiftTypeRow')
class ShiftTypes extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();
  TextColumn get category => textEnum<ShiftCategory>()();
  IntColumn get startMinute =>
      integer().nullable().check(startMinute.isBetweenValues(0, 1439))();
  IntColumn get endMinute =>
      integer().nullable().check(endMinute.isBetweenValues(0, 1439))();
  IntColumn get paidMinutes => integer().nullable()();
  BoolColumn get nightOverride => boolean().nullable()();

  /// Hourly rate in cents (no floating point). Added in schema v2.
  IntColumn get hourlyRateCents => integer().nullable()();

  /// Fixed payment per worked shift, in cents. Added in schema v4.
  IntColumn get fixedPlusCents => integer().nullable().check(
    fixedPlusCents.isBetweenValues(0, maxFixedPlusCents),
  )();

  /// Key of the icon (`ShiftIcon.key`), or NULL. Plain text on purpose: a key
  /// this build does not know reads as no icon instead of failing. Added in
  /// schema v3.
  TextColumn get icon => text().nullable()();

  /// Opaque id of the system sound the alarm of this type uses; NULL = the
  /// default of the channel. Added in schema v3.
  TextColumn get alarmSound => text().nullable().check(
    alarmSound.isNull() | alarmSound.equals('').not(),
  )();

  /// Second segment of a split shift: clock minute where it starts and how
  /// long it lasts. Both or none, and only on a shift with times (CHECKs
  /// below). That it fits after the first segment within 24 h is checked by
  /// the domain (`checkSegment2`). Added in schema v3.
  IntColumn get segment2StartMinute => integer().nullable()();
  IntColumn get segment2DurationMinutes => integer().nullable()();
  IntColumn get sortOrder => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK ((start_minute IS NULL) = (end_minute IS NULL))',
    'CHECK ((segment2_start_minute IS NULL) = '
        '(segment2_duration_minutes IS NULL))',
    'CHECK (segment2_start_minute IS NULL OR start_minute IS NOT NULL)',
    'CHECK (segment2_start_minute IS NULL OR '
        'segment2_start_minute BETWEEN 0 AND 1439)',
    'CHECK (segment2_duration_minutes IS NULL OR '
        'segment2_duration_minutes BETWEEN 1 AND 1440)',
  ];
}

@DataClassName('PatternRow')
class Patterns extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// JSON `[[id, ...], ...]`, at least one step.
  TextColumn get steps => text().map(const StepsConverter())();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  List<String> get customConstraints => ["CHECK (steps <> '[]')"];
}

/// A schedule the user keeps (second job, partner...). Shift types and
/// patterns are shared by all of them; runs and days belong to one. Added in
/// schema v2; the migration (and a fresh install) creates `main`.
@DataClassName('CalendarRow')
class Calendars extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();
  IntColumn get sortOrder => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DataClassName('PatternRunRow')
class PatternRuns extends Table {
  TextColumn get id => text()();

  /// Calendar the run belongs to (schema v2).
  TextColumn get calendarId => text().references(Calendars, #id)();
  TextColumn get patternId => text().references(Patterns, #id)();
  TextColumn get startDate => text().map(const CivilDateConverter())();
  TextColumn get endDate => text().map(const CivilDateConverter()).nullable()();
  IntColumn get stepOffset => integer().withDefault(const Constant(0))();
  IntColumn get seq => integer().unique()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (end_date IS NULL OR end_date >= start_date)',
  ];
}

@DataClassName('DayEntryRow')
class DayEntries extends Table {
  /// Calendar the day belongs to (schema v2: the key is calendar + date).
  TextColumn get calendarId => text().references(Calendars, #id)();
  TextColumn get date => text().map(const CivilDateConverter())();

  /// JSON list. NULL = does not replace the pattern; `[]` = empty day. A row
  /// exists only if the day holds something (override, note, reminder,
  /// overtime or early leave).
  TextColumn get shiftTypeIds =>
      text().map(const StringListConverter()).nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get updatedAt => integer()();

  /// Minute of this civil day (0-1439) at which the note rings. Added in
  /// schema v3.
  IntColumn get noteReminderMinute =>
      integer().nullable().check(noteReminderMinute.isBetweenValues(0, 1439))();

  /// Extra minutes worked this day (>= 0). Added in schema v3.
  IntColumn get overtimeMinutes =>
      integer().nullable().check(overtimeMinutes.isBiggerOrEqualValue(0))();

  /// Minutes left before the end of the shift (>= 0). Added in schema v3.
  IntColumn get earlyLeaveMinutes =>
      integer().nullable().check(earlyLeaveMinutes.isBiggerOrEqualValue(0))();

  @override
  Set<Column<Object>>? get primaryKey => {calendarId, date};
}

@DataClassName('HolidayRow')
@TableIndex(name: 'idx_holidays_date', columns: {#date})
class Holidays extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// ISO `YYYY-MM-DD`.
  TextColumn get date => text()();

  /// `national` / `regional` / `local`.
  TextColumn get scope => text()();
  TextColumn get name => text()();
  TextColumn get regionCode => text().nullable()();
  TextColumn get municipalityCode => text().nullable()();

  /// `bundled` / `remote` / `user`.
  TextColumn get source => text()();
}

@DataClassName('AbsenceBalanceRow')
class AbsenceBalances extends Table {
  IntColumn get year => integer()();
  TextColumn get type => text()();
  RealColumn get allowedDays => real()();

  @override
  Set<Column<Object>>? get primaryKey => {year, type};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();

  /// JSON.
  TextColumn get value => text()();

  @override
  Set<Column<Object>>? get primaryKey => {key};
}
