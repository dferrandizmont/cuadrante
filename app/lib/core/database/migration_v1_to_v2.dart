import 'package:drift/drift.dart';

import 'app_database.steps.dart';

/// Schema v1 -> v2 (docs/datos.md, "Esquema v2"): several calendars and the
/// hourly rate of a shift type.
///
/// 1. `calendars` is created with the calendar `main` ("Mi cuadrante").
/// 2. `shift_types.hourly_rate_cents` is added (NULL for every row).
/// 3. `pattern_runs` and `day_entries` are rebuilt with `calendar_id`, every
///    existing row going to `main`; `day_entries` changes its key from
///    (`date`) to (`calendar_id`, `date`).
///
/// Zero data loss is the requirement, so the whole step runs in **one
/// transaction** (a failure rolls everything back and the file stays on v1,
/// to be tried again) and ends by checking, still inside it, that no row was
/// lost or left without its calendar. Those checks throw, which is the
/// rollback.
///
/// The values written here are literals on purpose: a migration that already
/// shipped must never change when a constant elsewhere does. The test
/// `calendars_test` pins them to the constants the app uses.
///
/// [now] fixes the timestamps of `main`; [afterRebuild] runs once the tables
/// are rebuilt and before the checks (tests make it throw to prove the
/// rollback).
Future<void> migrateFrom1To2(
  Migrator m,
  Schema2 schema, {
  DateTime Function()? now,
  Future<void> Function()? afterRebuild,
}) async {
  final db = m.database;
  final stamp = (now ?? DateTime.now)().toUtc().millisecondsSinceEpoch;

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');

  await db.transaction(() async {
    final types = await count('shift_types');
    final runs = await count('pattern_runs');
    final entries = await count('day_entries');

    await m.createTable(schema.calendars);
    await db.customStatement(
      'INSERT INTO calendars (id, name, color_value, sort_order, archived, '
      'created_at, updated_at) VALUES (?, ?, ?, 0, 0, ?, ?)',
      ['main', 'Mi cuadrante', 0xFF4B4FD1, stamp, stamp],
    );

    await m.addColumn(schema.shiftTypes, schema.shiftTypes.hourlyRateCents);

    await m.alterTable(
      TableMigration(
        schema.patternRuns,
        columnTransformer: {
          schema.patternRuns.calendarId: const Constant<String>('main'),
        },
        newColumns: [schema.patternRuns.calendarId],
      ),
    );
    await m.alterTable(
      TableMigration(
        schema.dayEntries,
        columnTransformer: {
          schema.dayEntries.calendarId: const Constant<String>('main'),
        },
        newColumns: [schema.dayEntries.calendarId],
      ),
    );

    await afterRebuild?.call();

    // Nothing lost, everything attached to `main`.
    final after = {
      'shift_types': await count('shift_types'),
      'pattern_runs': await count('pattern_runs'),
      'day_entries': await count('day_entries'),
    };
    final before = {
      'shift_types': types,
      'pattern_runs': runs,
      'day_entries': entries,
    };
    for (final table in before.keys) {
      if (before[table] != after[table]) {
        throw StateError(
          'Migration v1 -> v2 would change the rows of $table '
          '(${before[table]} -> ${after[table]}); rolled back',
        );
      }
    }
    for (final table in ['pattern_runs', 'day_entries']) {
      final orphans = await count(
        "$table WHERE calendar_id <> 'main' OR calendar_id IS NULL",
      );
      if (orphans != 0) {
        throw StateError('Migration v1 -> v2 left rows of $table off `main`');
      }
    }
  });
}
