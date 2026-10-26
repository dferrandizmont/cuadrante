import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import 'app_database.steps.dart';

/// Schema v2 -> v3 (docs/datos.md, "Esquema v3"): what the paridad release
/// (0.6.0) attaches to days and shift types.
///
/// 1. `day_entries` gets `note_reminder_minute`, `overtime_minutes` and
///    `early_leave_minutes`, all NULL (columns added in place).
/// 2. `shift_types` is rebuilt with `icon`, `alarm_sound`,
///    `segment2_start_minute` and `segment2_duration_minutes`, all NULL. It
///    is rebuilt rather than altered because the second-segment rules are
///    table CHECKs, which `ALTER TABLE ... ADD COLUMN` cannot add.
///
/// Zero data loss is the requirement, so the whole step runs in **one
/// transaction** (a failure rolls everything back and the file stays on v2,
/// to be tried again) and ends by checking, still inside it, that every row of
/// every table is where it was with every value it had, and that the new
/// columns hold nothing yet. Those checks throw, which is the rollback.
///
/// [afterRebuild] runs once the tables are changed and before the checks
/// (tests make it throw to prove the rollback).
Future<void> migrateFrom2To3(
  Migrator m,
  Schema3 schema, {
  Future<void> Function()? afterRebuild,
}) async {
  final db = m.database;

  // Every column the v2 schema had, in a stable order: what must still be
  // there, value for value, afterwards.
  const v2Rows = <String, String>{
    'calendars':
        'SELECT id, name, color_value, sort_order, archived, created_at, '
        'updated_at FROM calendars ORDER BY id',
    'shift_types':
        'SELECT id, code, name, color_value, category, start_minute, '
        'end_minute, paid_minutes, night_override, hourly_rate_cents, '
        'sort_order, archived, created_at, updated_at FROM shift_types '
        'ORDER BY id',
    'patterns':
        'SELECT id, name, steps, created_at, updated_at FROM patterns '
        'ORDER BY rowid',
    'pattern_runs':
        'SELECT id, calendar_id, pattern_id, start_date, end_date, '
        'step_offset, seq, created_at FROM pattern_runs ORDER BY seq',
    'day_entries':
        'SELECT calendar_id, date, shift_type_ids, note, updated_at '
        'FROM day_entries ORDER BY calendar_id, date',
    'holidays':
        'SELECT id, date, scope, name, region_code, municipality_code, '
        'source FROM holidays ORDER BY id',
    'absence_balances':
        'SELECT year, type, allowed_days FROM absence_balances '
        'ORDER BY year, type',
    'settings': 'SELECT key, value FROM settings ORDER BY key',
  };

  Future<Map<String, List<Map<String, Object?>>>> dump() async => {
    for (final MapEntry(key: table, value: sql) in v2Rows.entries)
      table: [for (final row in await db.customSelect(sql).get()) row.data],
  };

  Future<int> count(String sql) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $sql').getSingle())
          .read<int>('n');

  await db.transaction(() async {
    final before = await dump();

    await m.addColumn(schema.dayEntries, schema.dayEntries.noteReminderMinute);
    await m.addColumn(schema.dayEntries, schema.dayEntries.overtimeMinutes);
    await m.addColumn(schema.dayEntries, schema.dayEntries.earlyLeaveMinutes);

    await m.alterTable(
      TableMigration(
        schema.shiftTypes,
        newColumns: [
          schema.shiftTypes.icon,
          schema.shiftTypes.alarmSound,
          schema.shiftTypes.segment2StartMinute,
          schema.shiftTypes.segment2DurationMinutes,
        ],
      ),
    );

    await afterRebuild?.call();

    // Nothing lost, nothing changed.
    final after = await dump();
    const equality = DeepCollectionEquality();
    for (final table in before.keys) {
      if (before[table]!.length != after[table]!.length) {
        throw StateError(
          'Migration v2 -> v3 would change the rows of $table '
          '(${before[table]!.length} -> ${after[table]!.length}); rolled back',
        );
      }
      if (!equality.equals(before[table], after[table])) {
        throw StateError(
          'Migration v2 -> v3 would change the values of $table; rolled back',
        );
      }
    }

    // The new columns start empty: nothing the user did not write.
    final stray =
        await count(
          'day_entries WHERE note_reminder_minute IS NOT NULL '
          'OR overtime_minutes IS NOT NULL OR early_leave_minutes IS NOT NULL',
        ) +
        await count(
          'shift_types WHERE icon IS NOT NULL OR alarm_sound IS NOT NULL '
          'OR segment2_start_minute IS NOT NULL '
          'OR segment2_duration_minutes IS NOT NULL',
        );
    if (stray != 0) {
      throw StateError('Migration v2 -> v3 left values in the new columns');
    }
  });
}
