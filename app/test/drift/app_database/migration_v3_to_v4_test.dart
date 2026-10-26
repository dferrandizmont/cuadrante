import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/app_database.steps.dart';
import 'package:cuadrante/core/database/migration_v1_to_v2.dart';
import 'package:cuadrante/core/database/migration_v2_to_v3.dart';
import 'package:cuadrante/core/database/migration_v3_to_v4.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/v2_database.dart';
import '../../support/v3_database.dart';
import 'generated/schema.dart';
import 'generated/schema_v3.dart' as v3;

class _FailingMigrationDatabase extends AppDatabase {
  _FailingMigrationDatabase(super.e);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: migrateFrom1To2,
      from2To3: migrateFrom2To3,
      from3To4: (m, schema) => migrateFrom3To4(
        m,
        schema,
        afterAdd: () async => throw StateError('failure after adding plus'),
      ),
    ),
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  Future<
    ({InitializedSchema schema, Map<String, List<Map<String, Object?>>> before})
  >
  seededV3() async {
    final schema = await verifier.schemaAt(3);
    addTearDown(schema.rawDatabase.close);
    final old = v3.DatabaseAtV3(schema.newConnection());
    await seedV3(old);
    final before = await dumpV3Columns(old);
    await old.close();
    return (schema: schema, before: before);
  }

  test(
    'v3 to v4 preserves every value and 730 resolved days per calendar',
    () async {
      final (:schema, :before) = await seededV3();
      expect(before['calendars'], hasLength(3));
      expect(before['patterns'], hasLength(2));
      expect(
        before['shift_types']!.where((r) => r['archived'] == 1),
        isNotEmpty,
      );
      expect(
        before['shift_types']!.where((r) => r['segment2_start_minute'] != null),
        isNotEmpty,
      );
      expect(
        before['day_entries']!.where((r) => r['note_reminder_minute'] != null),
        hasLength(2),
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 4);
      expect(await dumpV3Columns(db), before);
      final types = await db.select(db.shiftTypes).get();
      expect(types, hasLength(8));
      expect(types.every((t) => t.fixedPlusCents == null), isTrue);
      for (final id in ['main', 'pareja', 'viejo']) {
        final loaded = await ScheduleRepository(db).load(id);
        final prior = scheduleFromV3Rows(before, id);
        expect(
          v2ResolvedDays(loaded.schedule),
          v2ResolvedDays(prior),
          reason: id,
        );
        expect(v2ResolvedDays(loaded.schedule), hasLength(730));
        expect(loaded.schedule.entries, prior.entries, reason: id);
        expect(
          loaded.schedule.shiftTypes,
          unorderedEquals(prior.shiftTypes),
          reason: id,
        );
      }
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      expect(
        schema.rawDatabase.select('PRAGMA user_version').single.values.single,
        4,
      );
    },
  );

  test('migrated shift types persist a plus, zero and removal; CHECK rejects invalid cents', () async {
    final (:schema, before: _) = await seededV3();
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);
    final repo = ScheduleRepository(db);
    final night = (await repo.load('main')).schedule.shiftTypeById('night')!;
    for (final cents in [3000, 0, 999999]) {
      await repo.saveShiftType(night.copyWith(fixedPlusCents: cents));
      expect(
        (await repo.load('main')).schedule
            .shiftTypeById('night')!
            .fixedPlusCents,
        cents,
      );
    }
    for (final cents in [-1, 1000000]) {
      await expectLater(
        db.customStatement(
          "UPDATE shift_types SET fixed_plus_cents = ? WHERE id = 'night'",
          [cents],
        ),
        throwsA(anything),
      );
    }
    await repo.saveShiftType(night.copyWith(clearFixedPlus: true));
    expect(
      (await repo.load('main')).schedule.shiftTypeById('night')!.fixedPlusCents,
      isNull,
    );
  });

  test(
    'failure rolls back the added column and all v3 data; next start retries',
    () async {
      final (:schema, :before) = await seededV3();
      final failing = _FailingMigrationDatabase(schema.newConnection());
      await expectLater(
        failing.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>()),
      );
      await failing.close();
      expect(
        schema.rawDatabase.select('PRAGMA user_version').single.values.single,
        3,
      );
      expect([
        for (final row in schema.rawDatabase.select(
          "PRAGMA table_info('shift_types')",
        ))
          row['name'],
      ], isNot(contains('fixed_plus_cents')));
      final old = v3.DatabaseAtV3(schema.newConnection());
      expect(await dumpV3Columns(old), before);
      await old.close();
      final retried = AppDatabase(schema.newConnection());
      addTearDown(retried.close);
      await verifier.migrateAndValidate(retried, 4);
      expect(await dumpV3Columns(retried), before);
    },
  );
}
