import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/schedule_domain.dart';

/// A [ShiftType] plus what the data layer adds to it: its position in the
/// palette and whether it was "deleted" (archived). The engine model stays
/// as it is; past days keep resolving archived types.
class ShiftTypeRecord {
  const ShiftTypeRecord({
    required this.type,
    required this.sortOrder,
    this.archived = false,
  });

  final ShiftType type;
  final int sortOrder;
  final bool archived;

  @override
  bool operator ==(Object other) =>
      other is ShiftTypeRecord &&
      other.type == type &&
      other.sortOrder == sortOrder &&
      other.archived == archived;

  @override
  int get hashCode => Object.hash(type, sortOrder, archived);

  @override
  String toString() => 'ShiftTypeRecord($type, #$sortOrder, $archived)';
}

// Row -> model.

extension ShiftTypeRowMapper on ShiftTypeRow {
  /// Whether the stored second segment is one the domain accepts. The
  /// database already guarantees both-or-none and the ranges; a combination
  /// that does not fit in 24 h (only possible through a bug or a hand-edited
  /// file) reads as no second segment, so a bad row never breaks the app.
  bool get segment2Valid =>
      segment2StartMinute != null &&
      segment2DurationMinutes != null &&
      checkSegment2(
            startMinute: startMinute,
            endMinute: endMinute,
            segment2StartMinute: segment2StartMinute,
            segment2DurationMinutes: segment2DurationMinutes,
          ) ==
          null;

  ShiftTypeRecord toRecord() => ShiftTypeRecord(
    type: ShiftType(
      id: id,
      code: code,
      name: name,
      colorValue: colorValue,
      category: category,
      startMinute: startMinute,
      endMinute: endMinute,
      paidMinutes: paidMinutes,
      nightOverride: nightOverride,
      hourlyRateCents: hourlyRateCents,
      fixedPlusCents: fixedPlusCents,
      icon: ShiftIcon.fromKey(icon),
      alarmSound: alarmSound == null || alarmSound!.isEmpty ? null : alarmSound,
      segment2StartMinute: segment2Valid ? segment2StartMinute : null,
      segment2DurationMinutes: segment2Valid ? segment2DurationMinutes : null,
    ),
    sortOrder: sortOrder,
    archived: archived,
  );
}

extension PatternRowMapper on PatternRow {
  Pattern toPattern() => Pattern(id: id, name: name, steps: steps);
}

extension PatternRunRowMapper on PatternRunRow {
  PatternRun toRun() => PatternRun(
    id: id,
    patternId: patternId,
    startDate: startDate,
    endDate: endDate,
    stepOffset: stepOffset,
    seq: seq,
  );
}

extension DayEntryRowMapper on DayEntryRow {
  /// A value the domain refuses (a reminder outside the day, negative
  /// minutes: the CHECKs of the table already stop them) reads as none.
  /// More than [maxDayExtraMinutes] of overtime or early leave (a crafted
  /// backup written before the limit existed) is cut to it.
  DayEntry toEntry() => DayEntry(
    date: date,
    shiftTypeIds: shiftTypeIds,
    note: note,
    noteReminderMinute:
        noteReminderMinute != null &&
            DayEntry.isReminderMinute(noteReminderMinute!)
        ? noteReminderMinute
        : null,
    overtimeMinutes: overtimeMinutes != null && overtimeMinutes! >= 0
        ? overtimeMinutes!.clamp(0, maxDayExtraMinutes)
        : null,
    earlyLeaveMinutes: earlyLeaveMinutes != null && earlyLeaveMinutes! >= 0
        ? earlyLeaveMinutes!.clamp(0, maxDayExtraMinutes)
        : null,
  );
}

// Model -> companion. `createdAt` / `updatedAt` are milliseconds since the
// epoch (UTC).

extension ShiftTypeRecordMapper on ShiftTypeRecord {
  ShiftTypesCompanion toCompanion({
    required int createdAt,
    required int updatedAt,
  }) => ShiftTypesCompanion.insert(
    id: type.id,
    code: type.code,
    name: type.name,
    colorValue: type.colorValue,
    category: type.category,
    startMinute: Value(type.startMinute),
    endMinute: Value(type.endMinute),
    paidMinutes: Value(type.paidMinutes),
    nightOverride: Value(type.nightOverride),
    hourlyRateCents: Value(type.hourlyRateCents),
    fixedPlusCents: Value(type.fixedPlusCents),
    icon: Value(type.icon?.key),
    alarmSound: Value(type.alarmSound),
    segment2StartMinute: Value(type.segment2StartMinute),
    segment2DurationMinutes: Value(type.segment2DurationMinutes),
    sortOrder: sortOrder,
    archived: Value(archived),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension PatternMapper on Pattern {
  PatternsCompanion toCompanion({
    required int createdAt,
    required int updatedAt,
  }) => PatternsCompanion.insert(
    id: id,
    name: name,
    steps: steps,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension PatternRunMapper on PatternRun {
  PatternRunsCompanion toCompanion({
    required String calendarId,
    required int createdAt,
  }) => PatternRunsCompanion.insert(
    id: id,
    calendarId: calendarId,
    patternId: patternId,
    startDate: startDate,
    endDate: Value(endDate),
    stepOffset: Value(stepOffset),
    seq: seq,
    createdAt: createdAt,
  );
}

extension DayEntryMapper on DayEntry {
  DayEntriesCompanion toCompanion({
    required String calendarId,
    required int updatedAt,
  }) => DayEntriesCompanion.insert(
    calendarId: calendarId,
    date: date,
    shiftTypeIds: Value(shiftTypeIds),
    note: Value(note),
    noteReminderMinute: Value(noteReminderMinute),
    overtimeMinutes: Value(overtimeMinutes),
    earlyLeaveMinutes: Value(earlyLeaveMinutes),
    updatedAt: updatedAt,
  );
}
