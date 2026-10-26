import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/drift.dart';

import 'v2_database.dart';

/// A real v3 install: three calendars, all the v2 entities, split shifts,
/// icons, sounds, reminders, overtime and early leave.
Future<void> seedV3(GeneratedDatabase db) async {
  await seedV2(db);
  await db.customStatement(
    'UPDATE shift_types SET start_minute = 480, end_minute = 720, '
    'segment2_start_minute = 960, segment2_duration_minutes = 240, '
    "icon = 'sun', alarm_sound = 'content://media/internal/audio/media/42' "
    "WHERE id = 'morning'",
  );
  await db.customStatement(
    "UPDATE shift_types SET icon = 'moon' WHERE id IN ('night', 'old')",
  );
  await db.customStatement(
    'UPDATE day_entries SET note_reminder_minute = 450, '
    'overtime_minutes = 90, early_leave_minutes = 15 '
    "WHERE calendar_id = 'main' AND date = '2026-10-19'",
  );
  await db.customStatement(
    'UPDATE day_entries SET note_reminder_minute = 1260, '
    'overtime_minutes = 0, early_leave_minutes = 0 '
    "WHERE calendar_id = 'pareja' AND date = '2026-10-19'",
  );
}

/// Every v3 column, deliberately excluding any later additions.
Future<Map<String, List<Map<String, Object?>>>> dumpV3Columns(
  GeneratedDatabase db,
) async {
  final before = await dumpV2Columns(db);
  for (final table in ['shift_types', 'day_entries']) {
    final columns = table == 'shift_types'
        ? 'id, code, name, color_value, category, start_minute, end_minute, '
              'paid_minutes, night_override, hourly_rate_cents, icon, '
              'alarm_sound, segment2_start_minute, segment2_duration_minutes, '
              'sort_order, archived, created_at, updated_at'
        : 'calendar_id, date, shift_type_ids, note, note_reminder_minute, '
              'overtime_minutes, early_leave_minutes, updated_at';
    final order = table == 'shift_types' ? 'id' : 'calendar_id, date';
    before[table] = [
      for (final row
          in await db
              .customSelect('SELECT $columns FROM $table ORDER BY $order')
              .get())
        row.data,
    ];
  }
  return before;
}

/// Independent reconstruction of what v3 showed, including annotations.
Schedule scheduleFromV3Rows(
  Map<String, List<Map<String, Object?>>> dump,
  String calendarId,
) {
  final base = scheduleFromV2Rows(dump, calendarId);
  return Schedule(
    shiftTypes: [
      for (final type in base.shiftTypes)
        for (final row in dump['shift_types']!)
          if (row['id'] == type.id)
            type.copyWith(
              icon: ShiftIcon.fromKey(row['icon'] as String?),
              alarmSound: row['alarm_sound'] as String?,
              segment2StartMinute: row['segment2_start_minute'] as int?,
              segment2DurationMinutes: row['segment2_duration_minutes'] as int?,
            ),
    ],
    patterns: base.patterns,
    runs: base.runs,
    entries: {
      for (final row in dump['day_entries']!)
        if (row['calendar_id'] == calendarId)
          CivilDate.parse(row['date']! as String): base
              .entries[CivilDate.parse(row['date']! as String)]!
              .copyWith(
                noteReminderMinute: row['note_reminder_minute'] as int?,
                overtimeMinutes: row['overtime_minutes'] as int?,
                earlyLeaveMinutes: row['early_leave_minutes'] as int?,
              ),
    },
  );
}
