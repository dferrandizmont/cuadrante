import 'dart:io';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_opener.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../../support/test_storage.dart';

/// The constraints of docs/datos.md, exercised with plain SQL so they hold
/// whatever the Dart code does.
void main() {
  late AppDatabase db;

  setUp(() => db = openMemoryDatabase());
  tearDown(() => db.close());

  Future<void> sql(String statement, [List<Object?> args = const []]) =>
      db.customStatement(statement, args);

  Future<void> insertType({
    String id = 't',
    Object? start,
    Object? end,
    String category = 'work',
  }) => sql(
    'INSERT INTO shift_types (id, code, name, color_value, category, '
    'start_minute, end_minute, sort_order, created_at, updated_at) '
    "VALUES (?, 'M', 'Mañana', 1, ?, ?, ?, 0, 0, 0)",
    [id, category, start, end],
  );

  Future<void> insertPattern([String id = 'p', String steps = '[["t"]]']) =>
      sql(
        'INSERT INTO patterns (id, name, steps, created_at, updated_at) '
        "VALUES (?, 'P', ?, 0, 0)",
        [id, steps],
      );

  Future<void> insertRun({
    String id = 'r',
    String pattern = 'p',
    String start = '2026-10-01',
    String? end,
    int seq = 1,
  }) => sql(
    'INSERT INTO pattern_runs (id, calendar_id, pattern_id, start_date, '
    "end_date, seq, created_at) VALUES (?, 'main', ?, ?, ?, ?, 0)",
    [id, pattern, start, end, seq],
  );

  group('shift_types', () {
    test('start and end minute: both or none, 0..1439', () async {
      await insertType(id: 'none');
      await insertType(id: 'both', start: 0, end: 1439);
      await insertType(id: 'night', start: 1320, end: 360);

      await expectLater(insertType(id: 'a', start: 60), throwsA(anything));
      await expectLater(insertType(id: 'b', end: 60), throwsA(anything));
      await expectLater(
        insertType(id: 'c', start: -1, end: 60),
        throwsA(anything),
      );
      await expectLater(
        insertType(id: 'd', start: 60, end: 1440),
        throwsA(anything),
      );
    });

    test('hourly_rate_cents is optional', () async {
      await insertType(id: 'plain');
      await sql(
        'INSERT INTO shift_types (id, code, name, color_value, category, '
        'hourly_rate_cents, sort_order, created_at, updated_at) '
        "VALUES ('paid', 'P', 'Con precio', 1, 'work', 1250, 1, 0, 0)",
      );
      final rows = await db
          .customSelect('SELECT id, hourly_rate_cents AS r FROM shift_types')
          .get();
      expect(
        {for (final r in rows) r.read<String>('id'): r.read<int?>('r')},
        {'plain': null, 'paid': 1250},
      );
    });

    test(
      'icon and alarm_sound are optional text; the sound is never empty',
      () async {
        await insertType(id: 'plain');
        await sql(
          'INSERT INTO shift_types (id, code, name, color_value, category, '
          'icon, alarm_sound, sort_order, created_at, updated_at) '
          "VALUES ('rich', 'R', 'Con icono', 1, 'work', 'moon', "
          "'content://media/internal/audio/media/42', 1, 0, 0)",
        );
        final rows = await db
            .customSelect('SELECT id, icon, alarm_sound FROM shift_types')
            .get();
        expect(
          {
            for (final r in rows)
              r.read<String>('id'): (
                r.read<String?>('icon'),
                r.read<String?>('alarm_sound'),
              ),
          },
          {
            'plain': (null, null),
            'rich': ('moon', 'content://media/internal/audio/media/42'),
          },
        );
        await expectLater(
          sql(
            'INSERT INTO shift_types (id, code, name, color_value, category, '
            'alarm_sound, sort_order, created_at, updated_at) '
            "VALUES ('x', 'X', 'x', 1, 'work', '', 2, 0, 0)",
          ),
          throwsA(anything),
        );
      },
    );

    Future<void> insertSplit(
      String id, {
      Object? start = 480,
      Object? end = 720,
      Object? seg2Start,
      Object? seg2Duration,
    }) => sql(
      'INSERT INTO shift_types (id, code, name, color_value, category, '
      'start_minute, end_minute, segment2_start_minute, '
      'segment2_duration_minutes, sort_order, created_at, updated_at) '
      "VALUES (?, 'P', 'Partido', 1, 'work', ?, ?, ?, ?, 0, 0, 0)",
      [id, start, end, seg2Start, seg2Duration],
    );

    test('second segment: both or none, in range, only with times', () async {
      await insertSplit('none');
      await insertSplit('split', seg2Start: 960, seg2Duration: 240);
      await insertSplit('edge', seg2Start: 0, seg2Duration: 1);
      await insertSplit('long', seg2Start: 1439, seg2Duration: 1440);

      await expectLater(
        insertSplit('a', seg2Start: 960),
        throwsA(anything),
        reason: 'start without duration',
      );
      await expectLater(
        insertSplit('b', seg2Duration: 240),
        throwsA(anything),
        reason: 'duration without start',
      );
      await expectLater(
        insertSplit('c', seg2Start: 1440, seg2Duration: 60),
        throwsA(anything),
      );
      await expectLater(
        insertSplit('d', seg2Start: -1, seg2Duration: 60),
        throwsA(anything),
      );
      await expectLater(
        insertSplit('e', seg2Start: 960, seg2Duration: 0),
        throwsA(anything),
      );
      await expectLater(
        insertSplit('f', seg2Start: 960, seg2Duration: 1441),
        throwsA(anything),
      );
      await expectLater(
        insertSplit(
          'g',
          start: null,
          end: null,
          seg2Start: 960,
          seg2Duration: 60,
        ),
        throwsA(anything),
        reason: 'a shift without times has no second segment',
      );
    });

    test('archived defaults to false, ids are unique', () async {
      await insertType();
      final rows = await db
          .customSelect('SELECT archived FROM shift_types')
          .get();
      expect(rows.single.read<bool>('archived'), isFalse);
      await expectLater(insertType(), throwsA(anything));
    });
  });

  group('calendars', () {
    test('a new database has the calendar main and nothing else', () async {
      final rows = await db.customSelect('SELECT * FROM calendars').get();
      expect(rows, hasLength(1));
      final main = rows.single;
      expect(main.read<String>('id'), mainCalendarId);
      expect(main.read<String>('name'), mainCalendarName);
      expect(main.read<int>('color_value'), mainCalendarColor);
      expect(main.read<int>('sort_order'), 0);
      expect(main.read<bool>('archived'), isFalse);
    });

    test('ids are unique and archived defaults to false', () async {
      await sql(
        "INSERT INTO calendars (id, name, color_value, sort_order, created_at, updated_at) VALUES ('b', 'B', 1, 1, 0, 0)",
      );
      await expectLater(
        sql(
          "INSERT INTO calendars (id, name, color_value, sort_order, created_at, updated_at) VALUES ('b', 'C', 1, 2, 0, 0)",
        ),
        throwsA(anything),
      );
      final rows = await db
          .customSelect("SELECT archived FROM calendars WHERE id = 'b'")
          .get();
      expect(rows.single.read<bool>('archived'), isFalse);
    });

    test(
      'a calendar with runs or days cannot be deleted by accident',
      () async {
        await insertPattern();
        await insertRun();
        await expectLater(
          sql("DELETE FROM calendars WHERE id = 'main'"),
          throwsA(anything),
        );
      },
    );
  });

  group('patterns and runs', () {
    test('a pattern needs at least one step', () async {
      await insertPattern();
      await expectLater(insertPattern('q', '[]'), throwsA(anything));
    });

    test('a run needs an existing pattern (foreign keys are on)', () async {
      await expectLater(insertRun(pattern: 'ghost'), throwsA(anything));
      await insertPattern();
      await insertRun();
    });

    test('end date cannot precede the start date', () async {
      await insertPattern();
      await insertRun(id: 'same', start: '2026-10-01', end: '2026-10-01');
      await insertRun(id: 'open', seq: 2);
      await expectLater(
        insertRun(id: 'bad', seq: 3, start: '2026-10-05', end: '2026-10-04'),
        throwsA(anything),
      );
    });

    test('a run needs an existing calendar (foreign keys are on)', () async {
      await insertPattern();
      await expectLater(
        sql(
          'INSERT INTO pattern_runs (id, calendar_id, pattern_id, start_date, '
          "seq, created_at) VALUES ('r', 'ghost', 'p', '2026-10-01', 1, 0)",
        ),
        throwsA(anything),
      );
    });

    test('seq stays unique across calendars', () async {
      await insertPattern();
      await sql(
        "INSERT INTO calendars (id, name, color_value, sort_order, created_at, updated_at) VALUES ('other', 'Otro', 1, 1, 0, 0)",
      );
      await insertRun();
      await expectLater(
        sql(
          'INSERT INTO pattern_runs (id, calendar_id, pattern_id, start_date, '
          "seq, created_at) VALUES ('r2', 'other', 'p', '2026-10-01', 1, 0)",
        ),
        throwsA(anything),
      );
    });

    test('seq is unique, step_offset defaults to 0', () async {
      await insertPattern();
      await insertRun();
      await expectLater(insertRun(id: 'r2'), throwsA(anything));
      final rows = await db
          .customSelect('SELECT step_offset FROM pattern_runs')
          .get();
      expect(rows.single.read<int>('step_offset'), 0);
    });

    test('dates sort correctly as text', () async {
      await insertPattern();
      await insertRun(id: 'a', start: '2026-12-01', seq: 1);
      await insertRun(id: 'b', start: '2026-02-15', seq: 2);
      await insertRun(id: 'c', start: '2027-01-01', seq: 3);
      final rows = await db
          .customSelect('SELECT id FROM pattern_runs ORDER BY start_date')
          .get();
      expect([for (final r in rows) r.read<String>('id')], ['b', 'a', 'c']);
    });
  });

  group('day_entries, holidays, balances, settings', () {
    test('day_entries has one row per calendar and date', () async {
      await sql(
        "INSERT INTO calendars (id, name, color_value, sort_order, created_at, updated_at) VALUES ('other', 'Otro', 1, 1, 0, 0)",
      );
      await sql(
        "INSERT INTO day_entries (calendar_id, date, note, updated_at) VALUES ('main', '2026-10-19', 'a', 0)",
      );
      // The same date in another calendar is another row.
      await sql(
        "INSERT INTO day_entries (calendar_id, date, note, updated_at) VALUES ('other', '2026-10-19', 'b', 0)",
      );
      await expectLater(
        sql(
          "INSERT INTO day_entries (calendar_id, date, note, updated_at) VALUES ('main', '2026-10-19', 'c', 0)",
        ),
        throwsA(anything),
      );
    });

    test('a day may hold a reminder, overtime and early leave', () async {
      await sql(
        'INSERT INTO day_entries (calendar_id, date, note, '
        'note_reminder_minute, overtime_minutes, early_leave_minutes, '
        "updated_at) VALUES ('main', '2026-10-19', 'a', 0, 0, 0, 0)",
      );
      await sql(
        'INSERT INTO day_entries (calendar_id, date, note_reminder_minute, '
        'overtime_minutes, early_leave_minutes, updated_at) VALUES '
        "('main', '2026-10-20', 1439, 90, 15, 0)",
      );
      await sql(
        'INSERT INTO day_entries (calendar_id, date, updated_at) VALUES '
        "('main', '2026-10-21', 0)",
      );
      final rows = await db
          .customSelect(
            'SELECT date, note_reminder_minute AS r, overtime_minutes AS o, '
            'early_leave_minutes AS e FROM day_entries ORDER BY date',
          )
          .get();
      expect(
        [
          for (final r in rows)
            (r.read<int?>('r'), r.read<int?>('o'), r.read<int?>('e')),
        ],
        [(0, 0, 0), (1439, 90, 15), (null, null, null)],
      );
    });

    test(
      'the reminder is a minute of the day; minutes are not negative',
      () async {
        Future<void> day(String column, Object value) => sql(
          'INSERT INTO day_entries (calendar_id, date, $column, updated_at) '
          "VALUES ('main', '2026-10-19', ?, 0)",
          [value],
        );
        await expectLater(day('note_reminder_minute', 1440), throwsA(anything));
        await expectLater(day('note_reminder_minute', -1), throwsA(anything));
        await expectLater(day('overtime_minutes', -1), throwsA(anything));
        await expectLater(day('early_leave_minutes', -1), throwsA(anything));
      },
    );

    test('a day needs an existing calendar (foreign keys are on)', () async {
      await expectLater(
        sql(
          "INSERT INTO day_entries (calendar_id, date, note, updated_at) VALUES ('ghost', '2026-10-19', 'a', 0)",
        ),
        throwsA(anything),
      );
      await expectLater(
        sql(
          "INSERT INTO day_entries (date, note, updated_at) VALUES ('2026-10-19', 'a', 0)",
        ),
        throwsA(anything),
        reason: 'calendar_id is NOT NULL',
      );
    });

    test('holidays have an auto id and an index by date', () async {
      await sql(
        "INSERT INTO holidays (date, scope, name, source) VALUES ('2026-12-25', 'national', 'Navidad', 'bundled')",
      );
      await sql(
        "INSERT INTO holidays (date, scope, name, source) VALUES ('2026-12-25', 'local', 'Otro', 'user')",
      );
      final ids = await db.customSelect('SELECT id FROM holidays').get();
      expect([for (final r in ids) r.read<int>('id')], [1, 2]);
      final indexes = await db
          .customSelect("PRAGMA index_list('holidays')")
          .get();
      expect([
        for (final r in indexes) r.read<String>('name'),
      ], contains('idx_holidays_date'));
    });

    test('absence_balances are keyed by year and type', () async {
      await sql(
        "INSERT INTO absence_balances (year, type, allowed_days) VALUES (2026, 'vacation', 22.5)",
      );
      await sql(
        "INSERT INTO absence_balances (year, type, allowed_days) VALUES (2026, 'personal', 6)",
      );
      await expectLater(
        sql(
          "INSERT INTO absence_balances (year, type, allowed_days) VALUES (2026, 'vacation', 1)",
        ),
        throwsA(anything),
      );
    });

    test('settings are key / JSON value', () async {
      await sql(
        "INSERT INTO settings (key, value) VALUES ('region', '\"ES-MD\"')",
      );
      await expectLater(
        sql("INSERT INTO settings (key, value) VALUES ('region', '1')"),
        throwsA(anything),
      );
    });
  });

  test('schema version 4 is what the file records', () async {
    final dir = makeTempDir('version');
    final file = File(p.join(dir.path, databaseFileName));
    final onDisk = await openAppDatabase(directory: dir);
    await onDisk.customSelect('SELECT 1').get(); // forces open and create
    await onDisk.close();

    final raw = sqlite3.open(file.path, mode: OpenMode.readOnly);
    addTearDown(raw.close);
    expect(
      raw.select('PRAGMA user_version').single.values.single,
      AppDatabase.latestSchemaVersion,
    );
    expect(AppDatabase.latestSchemaVersion, 4);
    // A fresh install needs no backup.
    expect(
      Directory(p.join(dir.path, backupsDirectoryName)).existsSync(),
      isFalse,
    );
  });
}
