import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_opener.dart';
import 'package:cuadrante/features/schedule/data/demo_schedule.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/data/schedule_seeding.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_storage.dart';

const _today = CivilDate(2026, 10, 19);
final _now = DateTime(2026, 10, 19, 12);

void main() {
  late AppDatabase db;
  late ScheduleRepository repo;

  setUp(() {
    db = openMemoryDatabase();
    repo = ScheduleRepository(db, now: () => _now);
  });
  tearDown(() => db.close());

  test(
    'an empty database gets the templates and the presets, no days',
    () async {
      expect(await seedIfEmpty(repo, demo: false, today: _today), isTrue);
      final schedule = (await repo.load(mainCalendarId)).schedule;

      expect(schedule.shiftTypes.map((t) => t.id), [
        for (final t in shiftTemplates) t.key,
      ]);
      expect(schedule.shiftTypes, [
        for (final t in shiftTemplates) t.toShiftType(t.key),
      ]);
      final ids = {for (final t in shiftTemplates) t.key: t.key};
      expect(schedule.patterns, [
        for (final p in patternPresets) p.materialize(ids),
      ]);
      expect(schedule.runs, isEmpty);
      expect(schedule.entries, isEmpty);
    },
  );

  test('sort_order follows the order of the template table', () async {
    await seedIfEmpty(repo, demo: false, today: _today);
    final rows = await db
        .customSelect(
          'SELECT id, sort_order FROM shift_types ORDER BY sort_order',
        )
        .get();
    expect(
      [for (final r in rows) r.data['sort_order']],
      [for (var i = 0; i < shiftTemplates.length; i++) i],
    );
    expect(rows.first.data['id'], shiftTemplates.first.key);
  });

  test('every seeded type is in the palette', () async {
    await seedIfEmpty(repo, demo: false, today: _today);
    final snap = await repo.load(mainCalendarId);
    expect(snap.palette, snap.schedule.shiftTypes);
  });

  test(
    'demo data adds the rotation and the days of buildDemoSchedule',
    () async {
      await seedIfEmpty(repo, demo: true, today: _today);
      final schedule = (await repo.load(mainCalendarId)).schedule;
      final demo = buildDemoSchedule(_today);
      expectSameSchedule(schedule, demo);
      expect(schedule.runs, hasLength(1));
      expect(schedule.entries, hasLength(5));
    },
  );

  test('a second seed does nothing, with or without demo', () async {
    await seedIfEmpty(repo, demo: false, today: _today);
    final before = await dumpTables(db);

    expect(await seedIfEmpty(repo, demo: false, today: _today), isFalse);
    expect(await seedIfEmpty(repo, demo: true, today: _today), isFalse);
    expect(await dumpTables(db), before);
    expect((await repo.load(mainCalendarId)).schedule.runs, isEmpty);
  });

  test('never overwrites data already there', () async {
    await seedIfEmpty(repo, demo: true, today: _today);
    // The user renames a type and repaints a day.
    final morning = shiftTemplates.first.toShiftType('morning');
    await repo.saveShiftType(morning.copyWith(name: 'Mi mañana'));
    await repo.apply(
      mainCalendarId,
      ScheduleChange(
        patch: EntriesPatch({
          _today.addDays(2): EntryChange(
            buildDemoSchedule(_today).entries[_today.addDays(2)],
            DayEntry(date: _today.addDays(2), shiftTypeIds: const ['night']),
          ),
        }),
      ),
    );
    final before = await dumpTables(db);

    await seedIfEmpty(repo, demo: true, today: _today.addDays(100));
    expect(await dumpTables(db), before);
    final schedule = (await repo.load(mainCalendarId)).schedule;
    expect(schedule.shiftTypeById('morning')!.name, 'Mi mañana');
    expect(schedule.entries[_today.addDays(2)]!.shiftTypeIds, ['night']);
  });

  test('a database that only has data of its own is not seeded', () async {
    await repo.saveShiftType(
      const ShiftType(
        id: 'mine',
        code: 'Z',
        name: 'Mio',
        colorValue: 0xFF000000,
        category: ShiftCategory.rest,
      ),
    );
    expect(await seedIfEmpty(repo, demo: true, today: _today), isFalse);
    expect(
      (await repo.load(mainCalendarId)).schedule.shiftTypes.map((t) => t.id),
      ['mine'],
    );
  });

  group('bootstrapApp', () {
    test(
      'seeds, loads and, on the next open of the file, seeds nothing',
      () async {
        final dir = makeTempDir('bootstrap');

        var database = await openAppDatabase(directory: dir, now: () => _now);
        var boot = await bootstrapApp(
          config: const AppConfig(useDemoData: true),
          database: database,
          now: () => _now,
        );
        expect(boot.schedule.schedule.runs, hasLength(1));
        expect(boot.schedule.palette, hasLength(shiftTemplates.length));
        // The user repaints a day, then closes the app.
        final repository = ScheduleRepository(database, now: () => _now);
        final change = ScheduleChange(
          patch: boot.schedule.schedule.paint(
            const PaintTool.replace('guard24'),
            [_today.addDays(5)],
          ),
        );
        await repository.apply(mainCalendarId, change);
        final saved = (await repository.load(mainCalendarId)).schedule;
        await database.close();

        // Next launch, even with another "today": nothing is seeded again.
        database = await openAppDatabase(directory: dir, now: () => _now);
        addTearDown(database.close);
        boot = await bootstrapApp(
          config: const AppConfig(useDemoData: true),
          database: database,
          now: () => _now.add(const Duration(days: 30)),
        );
        expectSameSchedule(boot.schedule.schedule, saved);
      },
    );

    test('without demo data only templates and presets are seeded', () async {
      final boot = await bootstrapApp(
        config: const AppConfig(useDemoData: false),
        database: db,
        now: () => _now,
      );
      expect(boot.schedule.schedule.runs, isEmpty);
      expect(boot.schedule.schedule.entries, isEmpty);
      expect(boot.schedule.schedule.patterns, isNotEmpty);
    });
  });
}
