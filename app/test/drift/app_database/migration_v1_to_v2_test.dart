import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/app_database.steps.dart';
import 'package:cuadrante/core/database/migration_v1_to_v2.dart';
import 'package:cuadrante/core/database/migration_v2_to_v3.dart';
import 'package:cuadrante/core/database/migration_v3_to_v4.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/v1_database.dart';
import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v4.dart' as v4;

/// The first real migration (docs/datos.md, "Esquema v2"): users have v1
/// installed and nothing they stored may be lost. These tests run the real
/// step on a v1 database filled with what the 0.1.0 / 0.2.0 releases could
/// hold, and check every row, the calendar it ends up in and the 730 days the
/// engine resolves before and after.
///
/// (`migration_test.dart` next to this file is generated and checks the
/// schema only; this one checks the data.)
class _FailingMigrationDatabase extends AppDatabase {
  _FailingMigrationDatabase(super.e);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) => migrateFrom1To2(
        m,
        schema,
        afterRebuild: () async => throw StateError('boom after the rebuild'),
      ),
      from2To3: migrateFrom2To3,
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

  /// A v1 database filled with the fixture, and what it held.
  Future<
    ({InitializedSchema schema, Map<String, List<Map<String, Object?>>> before})
  >
  seededV1() async {
    final schema = await verifier.schemaAt(1);
    final oldDb = v1.DatabaseAtV1(schema.newConnection());
    await seedV1(oldDb);
    final before = await dumpV1Columns(oldDb);
    await oldDb.close();
    return (schema: schema, before: before);
  }

  test('the fixture is what the migration has to preserve', () async {
    final (:schema, :before) = await seededV1();
    addTearDown(schema.rawDatabase.close);
    expect(before['shift_types'], hasLength(8));
    expect(before['patterns'], hasLength(2));
    expect(before['pattern_runs'], hasLength(3));
    expect(before['pattern_runs']!.where((r) => r['end_date'] != null), [
      isNotEmpty,
      isNotEmpty,
    ], reason: 'one run is cut, one is bounded');
    expect(before['day_entries'], hasLength(8));
    final ids = [for (final e in before['day_entries']!) e['shift_type_ids']];
    expect(ids, contains('["morning","night"]'), reason: 'two shifts');
    expect(ids, contains('[]'), reason: 'an empty day');
    expect(ids, contains(null), reason: 'a note without override');
    expect(before['holidays'], hasLength(4));
    expect(before['absence_balances'], hasLength(2));
    expect(before['settings'], hasLength(4));
    // The fixture shows real days, not an empty calendar.
    final days = v1ResolvedDays(scheduleFromV1Rows(before));
    expect(days, hasLength(730));
    expect(days.toSet().length, greaterThan(10));
  });

  test('v1 -> v2: every row is kept, attached to main, and the 730 days '
      'resolve exactly as before', () async {
    final (:schema, :before) = await seededV1();
    final daysBefore = v1ResolvedDays(scheduleFromV1Rows(before));

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);

    // Every column of every v1 table, row by row (holiday ids included).
    expect(await dumpV1Columns(db), before);

    // The calendar, and everything attached to it.
    final calendars = await db.customSelect('SELECT * FROM calendars').get();
    expect(calendars, hasLength(1));
    final main = calendars.single;
    expect(main.read<String>('id'), 'main');
    expect(main.read<String>('name'), 'Mi cuadrante');
    expect(main.read<int>('color_value'), 0xFF4B4FD1);
    expect(main.read<int>('sort_order'), 0);
    expect(main.read<bool>('archived'), isFalse);
    expect(main.read<int>('created_at'), main.read<int>('updated_at'));

    final runCalendars = await db
        .customSelect('SELECT DISTINCT calendar_id AS c FROM pattern_runs')
        .get();
    expect([for (final r in runCalendars) r.read<String>('c')], ['main']);
    final entryCalendars = await db
        .customSelect('SELECT DISTINCT calendar_id AS c FROM day_entries')
        .get();
    expect([for (final r in entryCalendars) r.read<String>('c')], ['main']);
    final rates = await db
        .customSelect('SELECT hourly_rate_cents AS r FROM shift_types')
        .get();
    expect(rates.map((r) => r.read<int?>('r')).toSet(), {null});

    // What the calendar shows is what v1 showed: the same 730 days.
    final loaded = await ScheduleRepository(db).load('main');
    expect(v1ResolvedDays(loaded.schedule), daysBefore);
    expect(loaded.schedule.runs, hasLength(3));
    expect(loaded.schedule.entries, hasLength(8));
    // The archived type still resolves a past day; it is not in the palette.
    expect(loaded.schedule.resolve(const CivilDate(2026, 1, 5)).shiftIds, [
      'old',
    ]);
    expect(loaded.palette.map((t) => t.id), isNot(contains('old')));

    // Nothing dangling, and the file says it is v4 (the app always goes to
    // the newest version; the v2 step is the one checked here).
    final broken = await db.customSelect('PRAGMA foreign_key_check').get();
    expect(broken, isEmpty);
    await db.close();
    expect(
      schema.rawDatabase.select('PRAGMA user_version').single.values.single,
      4,
    );
    schema.rawDatabase.close();
  });

  test('the same check with the generated schema classes '
      '(testWithDataIntegrity)', () async {
    final reference = await seededV1();
    addTearDown(reference.schema.rawDatabase.close);

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 4,
      createOld: v1.DatabaseAtV1.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) => seedV1InBatch(batch),
      validateItems: (newDb) async {
        expect(await dumpV1Columns(newDb), reference.before);
        final calendars = await newDb.select(newDb.calendars).get();
        expect([for (final c in calendars) c.id], ['main']);
        final runs = await newDb.select(newDb.patternRuns).get();
        expect({for (final r in runs) r.calendarId}, {'main'});
        final entries = await newDb.select(newDb.dayEntries).get();
        expect(entries, hasLength(8));
        expect({for (final e in entries) e.calendarId}, {'main'});
      },
    );
  });

  test(
    'the calendar the migration creates is the one a new file has',
    () async {
      final (:schema, before: _) = await seededV1();
      final migrated = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(migrated, 4);
      // A new install: the app creates the file with `onCreate`.
      final fresh = AppDatabase(NativeDatabase.memory());
      Future<Map<String, Object?>> main(AppDatabase db) async {
        final row =
            (await db
                    .customSelect(
                      'SELECT id, name, color_value, sort_order, archived '
                      'FROM calendars',
                    )
                    .get())
                .single;
        return row.data;
      }

      // The migration writes literals, the app writes the constants: they must
      // agree.
      expect(await main(migrated), await main(fresh));
      expect(await main(migrated), {
        'id': mainCalendarId,
        'name': mainCalendarName,
        'color_value': mainCalendarColor,
        'sort_order': 0,
        'archived': 0,
      });
      await migrated.close();
      await fresh.close();
    },
  );

  test('an empty v1 database migrates too', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);
    expect(await db.select(db.calendars).get(), hasLength(1));
    expect(await db.select(db.patternRuns).get(), isEmpty);
    expect(await db.select(db.dayEntries).get(), isEmpty);
    expect(await db.select(db.shiftTypes).get(), isEmpty);
    await db.close();
  });

  test('a step that fails rolls everything back; the next start migrates '
      'the untouched v1 data', () async {
    final (:schema, :before) = await seededV1();
    final daysBefore = v1ResolvedDays(scheduleFromV1Rows(before));

    final failing = _FailingMigrationDatabase(schema.newConnection());
    await expectLater(
      failing.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
    await failing.close();

    // The file is exactly the v1 file it was: schema, data and version.
    final raw = schema.rawDatabase;
    expect(raw.select('PRAGMA user_version').single.values.single, 1);
    final tables = [
      for (final r in raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        r['name'],
    ];
    expect(tables, isNot(contains('calendars')));
    expect(tables, isNot(contains('tmp_for_copy_pattern_runs')));
    expect(tables, isNot(contains('tmp_for_copy_day_entries')));
    final runColumns = [
      for (final r in raw.select("PRAGMA table_info('pattern_runs')"))
        r['name'],
    ];
    expect(runColumns, isNot(contains('calendar_id')));
    final hasRate = [
      for (final r in raw.select("PRAGMA table_info('shift_types')")) r['name'],
    ];
    expect(hasRate, isNot(contains('hourly_rate_cents')));
    final stillV1 = v1.DatabaseAtV1(schema.newConnection());
    expect(await dumpV1Columns(stillV1), before);
    await stillV1.close();

    // Next start: the real step runs on that data and keeps all of it.
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);
    expect(await dumpV1Columns(db), before);
    final loaded = await ScheduleRepository(db).load('main');
    expect(v1ResolvedDays(loaded.schedule), daysBefore);
    await db.close();
  });

  test(
    'after migrating, the app writes to several calendars as usual',
    () async {
      final (:schema, :before) = await seededV1();
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 4);

      final calendars = CalendarsRepository(db);
      final partner = await calendars.create(name: 'Pareja', colorValue: 1);
      final schedules = ScheduleRepository(db);

      // The same date the main calendar already has an exception on.
      const day = CivilDate(2026, 10, 19);
      await schedules.apply(
        partner.id,
        ScheduleChange(
          patch: EntriesPatch({
            day: EntryChange(null, DayEntry(date: day, shiftTypeIds: ['rest'])),
          }),
        ),
      );

      final main = await schedules.load('main');
      final other = await schedules.load(partner.id);
      expect(main.schedule.resolve(day).shiftIds, ['morning', 'night']);
      expect(other.schedule.resolve(day).shiftIds, ['rest']);
      expect(other.schedule.runs, isEmpty);
      // Main did not move.
      final v1Schedule = scheduleFromV1Rows(before);
      expect(main.schedule.entries, v1Schedule.entries);
      expect(main.schedule.runs, v1Schedule.runs);
      expect(v1ResolvedDays(main.schedule), v1ResolvedDays(v1Schedule));
      await db.close();
    },
  );
}
