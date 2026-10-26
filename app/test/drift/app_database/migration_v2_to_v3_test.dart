import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/app_database.steps.dart';
import 'package:cuadrante/core/database/migration_v1_to_v2.dart';
import 'package:cuadrante/core/database/migration_v2_to_v3.dart';
import 'package:cuadrante/core/database/migration_v3_to_v4.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/v1_database.dart';
import '../../support/v2_database.dart';
import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v4.dart' as v4;

/// The second real migration (docs/datos.md, "Esquema v3"): users have v2
/// (0.3.0 – 0.5.0) installed and nothing they stored may be lost. These tests
/// run the real step on a v2 database filled with what those releases could
/// hold, and check every column of every row and the 730 days the engine
/// resolves in each calendar before and after; and the whole chain from v1.
///
/// (`migration_test.dart` next to this file is generated and checks the
/// schema only; this one checks the data.)
class _FailingMigrationDatabase extends AppDatabase {
  _FailingMigrationDatabase(super.e);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: migrateFrom1To2,
      from2To3: (m, schema) => migrateFrom2To3(
        m,
        schema,
        afterRebuild: () async => throw StateError('boom after the rebuild'),
      ),
      from3To4: migrateFrom3To4,
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  const calendarIds = ['main', 'pareja', 'viejo'];

  /// A v2 database filled with the fixture, and what it held.
  Future<
    ({InitializedSchema schema, Map<String, List<Map<String, Object?>>> before})
  >
  seededV2() async {
    final schema = await verifier.schemaAt(2);
    final oldDb = v2.DatabaseAtV2(schema.newConnection());
    await seedV2(oldDb);
    final before = await dumpV2Columns(oldDb);
    await oldDb.close();
    return (schema: schema, before: before);
  }

  Future<List<String>> columnsOf(GeneratedDatabase db, String table) async => [
    for (final r in await db.customSelect("PRAGMA table_info('$table')").get())
      r.read<String>('name'),
  ];

  test('the fixture is what the migration has to preserve', () async {
    final (:schema, :before) = await seededV2();
    addTearDown(schema.rawDatabase.close);
    expect(before['calendars'], hasLength(3));
    expect(before['shift_types'], hasLength(8));
    expect(
      before['shift_types']!.where((t) => t['hourly_rate_cents'] != null),
      hasLength(5),
      reason: 'some types have a rate, some do not',
    );
    expect(before['patterns'], hasLength(2));
    expect(before['pattern_runs'], hasLength(4));
    expect(before['day_entries'], hasLength(11));
    expect(
      {for (final e in before['day_entries']!) e['calendar_id']},
      {'main', 'pareja', 'viejo'},
    );
    final ids = [for (final e in before['day_entries']!) e['shift_type_ids']];
    expect(ids, contains('["morning","night"]'), reason: 'two shifts');
    expect(ids, contains('[]'), reason: 'an empty day');
    expect(ids, contains(null), reason: 'a note without override');
    expect(before['holidays'], hasLength(4));
    expect(before['absence_balances'], hasLength(2));
    expect(before['settings'], hasLength(8));
    // The fixture shows real days, not empty calendars.
    for (final id in ['main', 'pareja']) {
      final days = v2ResolvedDays(scheduleFromV2Rows(before, id));
      expect(days, hasLength(730));
      expect(days.toSet().length, greaterThan(5), reason: id);
    }
  });

  test('v2 -> v4: every row and value is kept, the new columns are empty and '
      'the 730 days of every calendar resolve exactly as before', () async {
    final (:schema, :before) = await seededV2();
    final daysBefore = {
      for (final id in calendarIds)
        id: v2ResolvedDays(scheduleFromV2Rows(before, id)),
    };

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);

    // Every column of every v2 table, row by row (holiday ids included).
    expect(await dumpV2Columns(db), before);

    // The new columns exist and hold nothing.
    expect(
      await columnsOf(db, 'day_entries'),
      containsAll([
        'note_reminder_minute',
        'overtime_minutes',
        'early_leave_minutes',
      ]),
    );
    expect(
      await columnsOf(db, 'shift_types'),
      containsAll([
        'icon',
        'alarm_sound',
        'segment2_start_minute',
        'segment2_duration_minutes',
      ]),
    );
    final stray = await db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM day_entries WHERE note_reminder_minute IS '
          'NOT NULL OR overtime_minutes IS NOT NULL OR early_leave_minutes '
          'IS NOT NULL) AS d, '
          '(SELECT COUNT(*) FROM shift_types WHERE icon IS NOT NULL OR '
          'alarm_sound IS NOT NULL OR segment2_start_minute IS NOT NULL OR '
          'segment2_duration_minutes IS NOT NULL) AS t',
        )
        .getSingle();
    expect(stray.read<int>('d'), 0);
    expect(stray.read<int>('t'), 0);

    // What each calendar shows is what v2 showed.
    final repository = ScheduleRepository(db);
    for (final id in calendarIds) {
      final loaded = await repository.load(id);
      expect(v2ResolvedDays(loaded.schedule), daysBefore[id], reason: id);
      expect(
        loaded.schedule.entries,
        scheduleFromV2Rows(before, id).entries,
        reason: id,
      );
      expect(
        loaded.schedule.runs,
        scheduleFromV2Rows(before, id).runs,
        reason: id,
      );
      // The app reads the palette by `sort_order`, the dump by id.
      int byId(ShiftType a, ShiftType b) => a.id.compareTo(b.id);
      expect(
        loaded.schedule.shiftTypes.toList()..sort(byId),
        scheduleFromV2Rows(before, id).shiftTypes.toList()..sort(byId),
        reason: 'hourly rates and everything else',
      );
    }
    final main = await repository.load('main');
    expect(main.schedule.resolve(const CivilDate(2026, 1, 5)).shiftIds, [
      'old',
    ]);
    expect(main.palette.map((t) => t.id), isNot(contains('old')));

    // Nothing dangling, and the file says it is v4.
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    await db.close();
    expect(
      schema.rawDatabase.select('PRAGMA user_version').single.values.single,
      4,
    );
    schema.rawDatabase.close();
  });

  test('the same check with the generated schema classes '
      '(testWithDataIntegrity)', () async {
    final reference = await seededV2();
    addTearDown(reference.schema.rawDatabase.close);

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 4,
      createOld: v2.DatabaseAtV2.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) => seedV2InBatch(batch),
      validateItems: (newDb) async {
        expect(await dumpV2Columns(newDb), reference.before);
        final types = await newDb.select(newDb.shiftTypes).get();
        expect(types, hasLength(8));
        expect({for (final t in types) t.icon}, {null});
        expect({for (final t in types) t.alarmSound}, {null});
        expect({for (final t in types) t.segment2StartMinute}, {null});
        final entries = await newDb.select(newDb.dayEntries).get();
        expect(entries, hasLength(11));
        expect({for (final e in entries) e.noteReminderMinute}, {null});
        expect({for (final e in entries) e.overtimeMinutes}, {null});
        expect({for (final e in entries) e.earlyLeaveMinutes}, {null});
      },
    );
  });

  test('an empty v2 database migrates too', () async {
    final schema = await verifier.schemaAt(2);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);
    expect(await db.select(db.shiftTypes).get(), isEmpty);
    expect(await db.select(db.dayEntries).get(), isEmpty);
    await db.close();
  });

  test(
    'v1 -> v4 in one go, with real data: nothing lost along the chain',
    () async {
      final schema = await verifier.schemaAt(1);
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await seedV1(oldDb);
      final before = await dumpV1Columns(oldDb);
      await oldDb.close();
      final daysBefore = v1ResolvedDays(scheduleFromV1Rows(before));

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 4);

      expect(await dumpV1Columns(db), before);
      final calendars = await db.select(db.calendars).get();
      expect([for (final c in calendars) c.id], ['main']);
      final loaded = await ScheduleRepository(db).load('main');
      expect(v1ResolvedDays(loaded.schedule), daysBefore);
      expect(loaded.schedule.entries, hasLength(8));
      expect(loaded.schedule.runs, hasLength(3));
      expect(
        loaded.schedule.shiftTypes.every(
          (t) =>
              t.hourlyRateCents == null &&
              t.icon == null &&
              t.alarmSound == null &&
              !t.hasSegment2,
        ),
        isTrue,
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      await db.close();
      expect(
        schema.rawDatabase.select('PRAGMA user_version').single.values.single,
        4,
      );
      schema.rawDatabase.close();
    },
  );

  test('v1 -> v4 with the generated schema classes '
      '(testWithDataIntegrity)', () async {
    final reference = await verifier.schemaAt(1);
    final refDb = v1.DatabaseAtV1(reference.newConnection());
    await seedV1(refDb);
    final before = await dumpV1Columns(refDb);
    await refDb.close();
    addTearDown(reference.rawDatabase.close);

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 4,
      createOld: v1.DatabaseAtV1.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) => seedV1InBatch(batch),
      validateItems: (newDb) async {
        expect(await dumpV1Columns(newDb), before);
        expect(await newDb.select(newDb.dayEntries).get(), hasLength(8));
      },
    );
  });

  test('a step that fails rolls everything back; the next start migrates '
      'the untouched v2 data', () async {
    final (:schema, :before) = await seededV2();
    final daysBefore = {
      for (final id in calendarIds)
        id: v2ResolvedDays(scheduleFromV2Rows(before, id)),
    };

    final failing = _FailingMigrationDatabase(schema.newConnection());
    await expectLater(
      failing.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
    await failing.close();

    // The file is exactly the v2 file it was: schema, data and version.
    final raw = schema.rawDatabase;
    expect(raw.select('PRAGMA user_version').single.values.single, 2);
    final tables = [
      for (final r in raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        r['name'],
    ];
    expect(tables, isNot(contains('tmp_for_copy_shift_types')));
    expect(tables, isNot(contains('tmp_for_copy_day_entries')));
    final entryColumns = [
      for (final r in raw.select("PRAGMA table_info('day_entries')")) r['name'],
    ];
    expect(entryColumns, isNot(contains('overtime_minutes')));
    expect(entryColumns, isNot(contains('note_reminder_minute')));
    final typeColumns = [
      for (final r in raw.select("PRAGMA table_info('shift_types')")) r['name'],
    ];
    expect(typeColumns, isNot(contains('icon')));
    expect(typeColumns, isNot(contains('segment2_start_minute')));
    final stillV2 = v2.DatabaseAtV2(schema.newConnection());
    expect(await dumpV2Columns(stillV2), before);
    await stillV2.close();

    // Next start: the real step runs on that data and keeps all of it.
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);
    expect(await dumpV2Columns(db), before);
    final repository = ScheduleRepository(db);
    for (final id in calendarIds) {
      expect(
        v2ResolvedDays((await repository.load(id)).schedule),
        daysBefore[id],
        reason: id,
      );
    }
    await db.close();
  });

  test('a chain that fails in its last step never leaves lost data; the '
      'next start finishes it', () async {
    final schema = await verifier.schemaAt(1);
    final oldDb = v1.DatabaseAtV1(schema.newConnection());
    await seedV1(oldDb);
    final before = await dumpV1Columns(oldDb);
    await oldDb.close();

    final failing = _FailingMigrationDatabase(schema.newConnection());
    await expectLater(
      failing.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
    await failing.close();

    // Whether the file stayed on v1 or reached v2, every v1 column is there.
    final raw = schema.rawDatabase;
    final version = raw.select('PRAGMA user_version').single.values.single;
    expect(version, anyOf(1, 2));
    // (Each step commits on its own: the file may well sit on v2.)
    final GeneratedDatabase partial = version == 2
        ? v2.DatabaseAtV2(schema.newConnection())
        : v1.DatabaseAtV1(schema.newConnection());
    expect(await dumpV1Columns(partial), before);
    await partial.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);
    expect(await dumpV1Columns(db), before);
    await db.close();
  });

  test('the migrated file has the CHECKs of a new one', () async {
    final (:schema, before: _) = await seededV2();
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);

    Future<void> day(String column, Object value) => db.customStatement(
      'INSERT INTO day_entries (calendar_id, date, $column, updated_at) '
      "VALUES ('main', '2030-01-01', ?, 0)",
      [value],
    );
    await expectLater(day('note_reminder_minute', 1440), throwsA(anything));
    await expectLater(day('overtime_minutes', -1), throwsA(anything));
    await expectLater(day('early_leave_minutes', -1), throwsA(anything));
    await day('note_reminder_minute', 1439);

    Future<void> type(Object? seg2Start, Object? seg2Duration) =>
        db.customStatement(
          'INSERT INTO shift_types (id, code, name, color_value, category, '
          'start_minute, end_minute, segment2_start_minute, '
          'segment2_duration_minutes, sort_order, created_at, updated_at) '
          "VALUES (?, 'P', 'P', 1, 'work', 480, 720, ?, ?, 99, 0, 0)",
          ['t${seg2Start}x$seg2Duration', seg2Start, seg2Duration],
        );
    await expectLater(type(960, null), throwsA(anything));
    await expectLater(type(null, 240), throwsA(anything));
    await expectLater(type(1440, 240), throwsA(anything));
    await expectLater(type(960, 0), throwsA(anything));
    await type(960, 240);
    await db.close();
  });

  test(
    'after migrating, the app writes and reads the new fields as usual',
    () async {
      final (:schema, :before) = await seededV2();
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 4);
      final repository = ScheduleRepository(db);

      // A shift type with everything v3 adds, and an old one edited.
      const split = ShiftType(
        id: 'partido',
        code: 'P',
        name: 'Partido',
        colorValue: 0xFF112233,
        category: ShiftCategory.work,
        startMinute: 480,
        endMinute: 720,
        icon: ShiftIcon.sun,
        alarmSound: 'content://media/internal/audio/media/42',
        segment2StartMinute: 960,
        segment2DurationMinutes: 240,
      );
      await repository.saveShiftType(split);
      final loadedMain = await repository.load('main');
      expect(loadedMain.schedule.shiftTypeById('partido'), split);
      expect(loadedMain.palette.map((t) => t.id), contains('partido'));
      // The old types are untouched.
      expect(loadedMain.schedule.shiftTypeById('night')!.hourlyRateCents, 1575);

      // An invalid second segment never reaches the file.
      await expectLater(
        repository.saveShiftType(
          split.copyWith(id: 'mal', segment2StartMinute: 700),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        (await repository.load('main')).schedule.shiftTypeById('mal'),
        isNull,
      );

      // Days: a reminder-only day exists; the same date in another calendar
      // is independent; an emptied one is deleted.
      const day = CivilDate(2026, 11, 3);
      final annotated = DayEntry(
        date: day,
        noteReminderMinute: 450,
        overtimeMinutes: 90,
        earlyLeaveMinutes: 15,
      );
      await repository.apply(
        'main',
        ScheduleChange(
          patch: EntriesPatch({day: EntryChange(null, annotated)}),
        ),
      );
      const partner = (id: 'pareja');
      await repository.apply(
        partner.id,
        ScheduleChange(
          patch: EntriesPatch({
            day: EntryChange(null, DayEntry(date: day, overtimeMinutes: 5)),
          }),
        ),
      );
      expect((await repository.load('main')).schedule.entries[day], annotated);
      expect(
        (await repository.load(partner.id))
            .schedule
            .entries[day]!
            .overtimeMinutes,
        5,
      );
      // The v2 days of main did not move.
      expect(
        (await repository.load('main')).schedule.entries.length,
        scheduleFromV2Rows(before, 'main').entries.length + 1,
      );

      // Taking everything away deletes the row.
      await repository.apply(
        'main',
        ScheduleChange(
          patch: EntriesPatch({
            day: EntryChange(
              annotated,
              DayEntry(date: day, overtimeMinutes: 0),
            ),
          }),
        ),
      );
      expect((await repository.load('main')).schedule.entries[day], isNull);
      await db.close();
    },
  );

  test('a fresh database and a migrated one have the same schema', () async {
    final (:schema, before: _) = await seededV2();
    final migrated = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(migrated, 4);
    final fresh = AppDatabase(NativeDatabase.memory());
    await verifier.migrateAndValidate(fresh, 4);
    for (final table in ['day_entries', 'shift_types']) {
      expect(
        (await columnsOf(migrated, table)).toSet(),
        (await columnsOf(fresh, table)).toSet(),
        reason: table,
      );
    }
    await migrated.close();
    await fresh.close();
  });
}
