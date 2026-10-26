import 'dart:convert';
import 'dart:io';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/data/backup_repository.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/backup_task_runner.dart';
import 'package:cuadrante/features/backup/domain/canonical_json.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

export '../../support/test_storage.dart' show makeTempDir, openMemoryDatabase;

/// Version string used in the tests.
const testAppVersion = '1.0.0-test';

/// Inserts [data] straight into the tables, without going through the code
/// under test, plus the holidays that must **not** travel in a backup.
Future<void> seedDatabase(
  AppDatabase db,
  BackupData data, {
  bool withDerivedHolidays = false,
}) async {
  await db.batch((b) {
    // The fresh database already has `main`: the data decides the calendars.
    b.deleteAll(db.calendars);
    b.insertAll(db.calendars, [
      for (final c in data.calendars)
        CalendarsCompanion.insert(
          id: c.id,
          name: c.name,
          colorValue: c.colorValue,
          sortOrder: c.sortOrder,
          archived: Value(c.archived),
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
        ),
    ]);
    b.insertAll(db.shiftTypes, [
      for (final t in data.shiftTypes)
        ShiftTypesCompanion.insert(
          id: t.id,
          code: t.code,
          name: t.name,
          colorValue: t.colorValue,
          category: t.category,
          startMinute: Value(t.startMinute),
          endMinute: Value(t.endMinute),
          paidMinutes: Value(t.paidMinutes),
          nightOverride: Value(t.nightOverride),
          hourlyRateCents: Value(t.hourlyRateCents),
          fixedPlusCents: Value(t.fixedPlusCents),
          icon: Value(t.icon?.key),
          alarmSound: Value(t.alarmSound),
          segment2StartMinute: Value(t.segment2StartMinute),
          segment2DurationMinutes: Value(t.segment2DurationMinutes),
          sortOrder: t.sortOrder,
          archived: Value(t.archived),
          createdAt: t.createdAt,
          updatedAt: t.updatedAt,
        ),
    ]);
    for (final pattern in data.patterns) {
      b.insert(
        db.patterns,
        PatternsCompanion.insert(
          id: pattern.id,
          name: pattern.name,
          steps: pattern.steps,
          createdAt: pattern.createdAt,
          updatedAt: pattern.updatedAt,
        ),
      );
    }
    for (final r in data.patternRuns) {
      b.insert(
        db.patternRuns,
        PatternRunsCompanion.insert(
          id: r.id,
          calendarId: r.calendarId,
          patternId: r.patternId,
          startDate: r.startDate,
          endDate: Value(r.endDate),
          stepOffset: Value(r.stepOffset),
          seq: r.seq,
          createdAt: r.createdAt,
        ),
      );
    }
    for (final e in data.dayEntries) {
      b.insert(
        db.dayEntries,
        DayEntriesCompanion.insert(
          calendarId: e.calendarId,
          date: e.date,
          shiftTypeIds: Value(e.shiftTypeIds),
          note: Value(e.note),
          noteReminderMinute: Value(e.noteReminderMinute),
          overtimeMinutes: Value(e.overtimeMinutes),
          earlyLeaveMinutes: Value(e.earlyLeaveMinutes),
          updatedAt: e.updatedAt,
        ),
      );
    }
    for (final h in data.holidays) {
      b.insert(
        db.holidays,
        HolidaysCompanion.insert(
          date: h.date.toIso(),
          scope: h.scope,
          name: h.name,
          regionCode: Value(h.regionCode),
          municipalityCode: Value(h.municipalityCode),
          source: 'user',
        ),
      );
    }
    if (withDerivedHolidays) {
      b.insert(
        db.holidays,
        HolidaysCompanion.insert(
          date: '2026-01-01',
          scope: 'national',
          name: 'Año Nuevo',
          source: 'bundled',
        ),
      );
      b.insert(
        db.holidays,
        HolidaysCompanion.insert(
          date: '2026-10-09',
          scope: 'regional',
          name: 'Día de la Comunidad Valenciana',
          regionCode: const Value('ES-VC'),
          source: 'remote',
        ),
      );
    }
    for (final a in data.absenceBalances) {
      b.insert(
        db.absenceBalances,
        AbsenceBalancesCompanion.insert(
          year: a.year,
          type: a.type,
          allowedDays: a.allowedDays,
        ),
      );
    }
    for (final s in data.settings.entries) {
      b.insert(
        db.settings,
        SettingsCompanion.insert(key: s.key, value: s.value),
      );
    }
  });
}

/// Every column of every table as raw rows, in a stable order, so two
/// databases can be compared without going through the backup code. Includes
/// the timestamps; leaves out only the auto-increment `holidays.id`.
Future<Map<String, List<Map<String, Object?>>>> dumpAllTables(
  AppDatabase db,
) async {
  Future<List<Map<String, Object?>>> rows(String sql) async => [
    for (final row in await db.customSelect(sql).get()) row.data,
  ];
  return {
    'calendars': await rows('SELECT * FROM calendars ORDER BY id'),
    'shift_types': await rows('SELECT * FROM shift_types ORDER BY id'),
    'patterns': await rows('SELECT * FROM patterns ORDER BY rowid'),
    'pattern_runs': await rows('SELECT * FROM pattern_runs ORDER BY seq'),
    'day_entries': await rows(
      'SELECT * FROM day_entries ORDER BY calendar_id, date',
    ),
    'holidays': await rows(
      'SELECT date, scope, name, region_code, municipality_code, source '
      'FROM holidays ORDER BY source, date, name',
    ),
    'absence_balances': await rows(
      'SELECT * FROM absence_balances ORDER BY year, type',
    ),
    'settings': await rows('SELECT * FROM settings ORDER BY key'),
  };
}

/// A repository over [db] with a fixed clock, writing safety copies into
/// [safetyDirectory].
BackupRepository makeRepository(
  AppDatabase db,
  Directory safetyDirectory, {
  DateTime Function()? now,
  AppDatabase Function()? openScratchDatabase,
}) => BackupRepository(
  db,
  safetyDirectory: safetyDirectory,
  appVersion: testAppVersion,
  now: now ?? () => DateTime.utc(2026, 11, 10, 9),
  openScratchDatabase: openScratchDatabase,
  runner: runOnThisIsolate,
);

/// File names in [directory], sorted (empty if it does not exist).
List<String> fileNames(Directory directory) => directory.existsSync()
    ? ([for (final f in directory.listSync()) p.basename(f.path)]..sort())
    : <String>[];

/// A `.cuadrante` made by hand from an envelope [map] (gzip of its canonical
/// JSON), for files the real codec would never write.
Uint8List gzipEnvelope(Map<String, Object?> map) => Uint8List.fromList(
  GZipCodec(level: 9).encode(utf8.encode(canonicalJson(map))),
);

/// The decompressed envelope of a `.cuadrante`.
Map<String, Object?> readEnvelope(Uint8List bytes) =>
    jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, Object?>;
