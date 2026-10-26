import 'dart:convert';

import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/drift.dart';

import 'v1_database.dart' show v1Today;

/// "Today" of the version 2 fixtures (the same as version 1's).
const v2Today = v1Today;

/// What a 0.3.0 – 0.5.0 install could hold, as plain SQL against the
/// **version 2** schema (so it does not depend on any code that changed): the
/// calendar `main` and two more (one archived), shift types with and without
/// an hourly rate (all categories, a night that crosses midnight, a 24 h
/// guard, no-times, paid minutes, an archived one), two patterns, runs in
/// two calendars (one cut, one with a step offset), day exceptions in three
/// calendars (two shifts, `[]`, note only, override + note, an archived type
/// in the past, emoji and line breaks, **the same date in two calendars**),
/// user and derived holidays, absence balances and settings (the active and
/// primary calendar among them).
final List<(String, List<Object?>)> v2SeedStatements = [
  for (final c in [
    // id, name, color, sort_order, archived, created_at, updated_at
    ['main', 'Mi cuadrante', 0xFF4B4FD1, 0, 0, 1760000000000, 1760000100000],
    ['pareja', 'Pareja 💙', 0xFFE5484D, 1, 0, 1760000200000, 1760000300000],
    [
      'viejo',
      'Trabajo anterior',
      0xFF64748B,
      2,
      1,
      1760000400000,
      1760000500000,
    ],
  ])
    (
      'INSERT INTO calendars (id, name, color_value, sort_order, archived, '
          'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      c,
    ),
  for (final t in [
    // id, code, name, color, category, start, end, paid, night, rate, order,
    // archived
    [
      'morning', 'M', 'Mañana', 0xFFF5A524, 'work', 360, 840, null, null, //
      1250, 0, 0,
    ],
    [
      'afternoon', 'T', 'Tarde', 0xFFF06A3F, 'work', 840, 1320, null, null, //
      1250, 1, 0,
    ],
    [
      'night', 'N', 'Noche', 0xFF4B4FD1, 'work', 1320, 360, 450, 1, //
      1575, 2, 0,
    ],
    [
      'rest', 'L', 'Libre', 0xFFE4E4E7, 'rest', null, null, null, null, //
      null, 3, 0,
    ],
    [
      'vacation', 'V', 'Vacaciones', 0xFF2BB673, 'absence', null, null, //
      null, null, null, 4, 0,
    ],
    [
      'guard', 'G', 'Guardia 24 h', 0xFFE5484D, 'work', 480, 480, null, 0, //
      2000, 5, 0,
    ],
    [
      'flex', 'F', 'Flexible', 0xFF8B5CF6, 'work', null, null, 420, 1, //
      1100, 6, 0,
    ],
    [
      'old', 'X', 'Turno antiguo', 0xFF64748B, 'work', 540, 1020, null, //
      null, null, 7, 1,
    ],
  ])
    (
      'INSERT INTO shift_types (id, code, name, color_value, category, '
          'start_minute, end_minute, paid_minutes, night_override, '
          'hourly_rate_cents, sort_order, archived, created_at, updated_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [...t, 1760000000000 + (t[10]! as int), 1760000500000 + (t[10]! as int)],
    ),
  // Deliberately not in id order: patterns keep their insertion order.
  (
    'INSERT INTO patterns (id, name, steps, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
    [
      'p-turni',
      'Turnicidad',
      '[["morning"],["morning","afternoon"],["afternoon"],["night"],["night"],'
          '[],["rest"],["rest"]]',
      1760001000000,
      1760001500000,
    ],
  ),
  (
    'INSERT INTO patterns (id, name, steps, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
    [
      'p-mananas',
      'Mañanas',
      '[["morning"],["morning"],["morning"],["morning"],["morning"],[],[]]',
      1760002000000,
      1760002500000,
    ],
  ),
  for (final r in [
    // id, calendar, pattern, start, end, offset, seq, created
    [
      'run-1',
      'main',
      'p-turni',
      '2025-11-03',
      '2026-09-13',
      0,
      1,
      1760003000000,
    ],
    ['run-2', 'main', 'p-mananas', '2026-09-14', null, 3, 2, 1760003100000],
    [
      'run-3',
      'main',
      'p-turni',
      '2027-02-01',
      '2027-03-31',
      2,
      3,
      1760003200000,
    ],
    ['run-4', 'pareja', 'p-mananas', '2026-01-05', null, 0, 4, 1760003300000],
  ])
    (
      'INSERT INTO pattern_runs (id, calendar_id, pattern_id, start_date, '
          'end_date, step_offset, seq, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      r,
    ),
  for (final e in [
    // calendar, date, shift_type_ids (JSON or null), note, updated_at
    ['main', '2026-10-19', '["morning","night"]', null, 1760004000000],
    ['main', '2026-10-20', '[]', null, 1760004100000],
    ['main', '2026-10-21', null, 'Cambio con Marta', 1760004200000],
    ['main', '2026-10-22', '["vacation"]', 'Viaje a Cádiz', 1760004300000],
    ['main', '2026-01-05', '["old"]', null, 1760004400000],
    [
      'main',
      '2026-12-24',
      '["night"]',
      'Nochebuena 🎄\nLlevar el turrón 🙏\r\n"comillas" y \\ barra',
      1760004500000,
    ],
    ['main', '2027-02-14', '["guard","flex"]', null, 1760004600000],
    ['main', '2025-12-31', '["rest"]', 'Fin de año', 1760004700000],
    // The same dates in another calendar.
    ['pareja', '2026-10-19', '["rest"]', 'Cena a las 21:00', 1760004800000],
    ['pareja', '2026-10-21', null, 'Aniversario', 1760004900000],
    ['viejo', '2026-03-02', '["afternoon"]', null, 1760005000000],
  ])
    (
      'INSERT INTO day_entries (calendar_id, date, shift_type_ids, note, '
          'updated_at) VALUES (?, ?, ?, ?, ?)',
      e,
    ),
  for (final h in [
    ['2026-12-25', 'national', 'Navidad', null, null, 'bundled'],
    [
      '2026-10-09',
      'regional',
      'Día de la Comunidad Valenciana',
      'ES-VC',
      null,
      'remote',
    ],
    ['2026-09-08', 'local', 'Fiesta del barrio 🎆', 'ES-VC', '46250', 'user'],
    ['2027-05-15', 'local', 'San Isidro', 'ES-MD', '28079', 'user'],
  ])
    (
      'INSERT INTO holidays (date, scope, name, region_code, '
          'municipality_code, source) VALUES (?, ?, ?, ?, ?, ?)',
      h,
    ),
  for (final b in [
    [2026, 'vacation', 22.0],
    [2026, 'personal', 6.5],
  ])
    (
      'INSERT INTO absence_balances (year, type, allowed_days) '
          'VALUES (?, ?, ?)',
      b,
    ),
  for (final s in [
    ['holidays.region', '"ES-VC"'],
    ['holidays.municipality', '"46250"'],
    [
      'alarms',
      '{"enabled":true,"leadMinutes":45,"shifts":["morning","night"]}',
    ],
    ['holidays.bundleVersion', '"2026.2"'],
    ['calendars.active', '"pareja"'],
    ['calendars.primary', '"main"'],
    ['appearance.themeMode', '"dark"'],
    ['postNight.auto', 'true'],
  ])
    ('INSERT INTO settings (key, value) VALUES (?, ?)', s),
];

/// Writes the version 2 fixture into [db] (any database on the version 2
/// schema).
Future<void> seedV2(GeneratedDatabase db) async {
  for (final (sql, args) in v2SeedStatements) {
    await db.customStatement(sql, args);
  }
}

/// The same fixture as a batch (for `testWithDataIntegrity`).
void seedV2InBatch(Batch batch) {
  for (final (sql, args) in v2SeedStatements) {
    batch.customStatement(sql, args);
  }
}

/// Every column the version 2 schema has, of every table, as raw rows in a
/// stable order. Works on a version 2 **and** on a later database (which has
/// more columns, left out here), so what was stored before a migration can be
/// compared with what is there after it.
Future<Map<String, List<Map<String, Object?>>>> dumpV2Columns(
  GeneratedDatabase db,
) async {
  Future<List<Map<String, Object?>>> rows(String sql) async => [
    for (final row in await db.customSelect(sql).get()) row.data,
  ];
  return {
    'calendars': await rows(
      'SELECT id, name, color_value, sort_order, archived, created_at, '
      'updated_at FROM calendars ORDER BY id',
    ),
    'shift_types': await rows(
      'SELECT id, code, name, color_value, category, start_minute, '
      'end_minute, paid_minutes, night_override, hourly_rate_cents, '
      'sort_order, archived, created_at, updated_at FROM shift_types '
      'ORDER BY id',
    ),
    'patterns': await rows(
      'SELECT id, name, steps, created_at, updated_at FROM patterns '
      'ORDER BY rowid',
    ),
    'pattern_runs': await rows(
      'SELECT id, calendar_id, pattern_id, start_date, end_date, step_offset, '
      'seq, created_at FROM pattern_runs ORDER BY seq',
    ),
    'day_entries': await rows(
      'SELECT calendar_id, date, shift_type_ids, note, updated_at '
      'FROM day_entries ORDER BY calendar_id, date',
    ),
    'holidays': await rows(
      'SELECT id, date, scope, name, region_code, municipality_code, source '
      'FROM holidays ORDER BY id',
    ),
    'absence_balances': await rows(
      'SELECT year, type, allowed_days FROM absence_balances '
      'ORDER BY year, type',
    ),
    'settings': await rows('SELECT key, value FROM settings ORDER BY key'),
  };
}

/// The engine's view of calendar [calendarId] in [dump] (a result of
/// [dumpV2Columns]), built by hand from the raw rows so it knows nothing of
/// the code that reads the database: what the app showed before the upgrade.
Schedule scheduleFromV2Rows(
  Map<String, List<Map<String, Object?>>> dump,
  String calendarId,
) {
  int? intOrNull(Object? v) => v as int?;
  return Schedule(
    shiftTypes: [
      for (final r in dump['shift_types']!)
        ShiftType(
          id: r['id']! as String,
          code: r['code']! as String,
          name: r['name']! as String,
          colorValue: r['color_value']! as int,
          category: ShiftCategory.values.byName(r['category']! as String),
          startMinute: intOrNull(r['start_minute']),
          endMinute: intOrNull(r['end_minute']),
          paidMinutes: intOrNull(r['paid_minutes']),
          nightOverride: r['night_override'] == null
              ? null
              : r['night_override'] == 1,
          hourlyRateCents: intOrNull(r['hourly_rate_cents']),
        ),
    ],
    patterns: [
      for (final r in dump['patterns']!)
        Pattern(
          id: r['id']! as String,
          name: r['name']! as String,
          steps: [
            for (final step in jsonDecode(r['steps']! as String) as List)
              (step as List).cast<String>(),
          ],
        ),
    ],
    runs: [
      for (final r in dump['pattern_runs']!)
        if (r['calendar_id'] == calendarId)
          PatternRun(
            id: r['id']! as String,
            patternId: r['pattern_id']! as String,
            startDate: CivilDate.parse(r['start_date']! as String),
            endDate: r['end_date'] == null
                ? null
                : CivilDate.parse(r['end_date']! as String),
            stepOffset: r['step_offset']! as int,
            seq: r['seq']! as int,
          ),
    ],
    entries: {
      for (final r in dump['day_entries']!)
        if (r['calendar_id'] == calendarId)
          CivilDate.parse(r['date']! as String): DayEntry(
            date: CivilDate.parse(r['date']! as String),
            shiftTypeIds: r['shift_type_ids'] == null
                ? null
                : (jsonDecode(r['shift_type_ids']! as String) as List)
                      .cast<String>(),
            note: r['note'] as String?,
          ),
    },
  );
}

/// The 730 resolved days of [schedule] around [v2Today], one canonical line
/// per day: what a fingerprint compares.
List<String> v2ResolvedDays(Schedule schedule) {
  final window = defaultFingerprintWindow(v2Today);
  return resolvedDayLines(schedule, from: window.from, to: window.to);
}
