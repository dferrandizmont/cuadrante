import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/data/schedule_mappers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/sample_data.dart';
import '../../../support/test_storage.dart';

final _now = DateTime.utc(2026, 10, 19, 12);
const _today = CivilDate(2026, 10, 19);

void main() {
  late AppDatabase db;
  late ScheduleRepository repo;
  var clock = _now;

  setUp(() {
    clock = _now;
    db = openMemoryDatabase();
    repo = ScheduleRepository(db, now: () => clock);
  });
  tearDown(() => db.close());

  /// A database with the sample shift types, patterns and runs (no days).
  Future<void> seedSample() async {
    for (final r in sampleShiftTypes) {
      await repo.saveShiftType(r.type, sortOrder: r.sortOrder);
      if (r.archived) await repo.archiveShiftType(r.type.id);
    }
    for (final p in samplePatterns) {
      await repo.savePattern(p);
    }
  }

  Future<List<Object?>> column(String sql, String name) async => [
    for (final row in await db.customSelect(sql).get()) row.data[name],
  ];

  group('load', () {
    test('an empty database loads an empty schedule', () async {
      final snap = await repo.load(mainCalendarId);
      expect(snap.schedule.shiftTypes, isEmpty);
      expect(snap.schedule.runs, isEmpty);
      expect(snap.schedule.entries, isEmpty);
      expect(snap.palette, isEmpty);
      expect(await repo.isEmpty(), isTrue);
    });

    test('types in sort order, archived ones in the schedule only', () async {
      await seedSample();
      final snap = await repo.load(mainCalendarId);
      expect(snap.schedule.shiftTypes.map((t) => t.id), [
        'morning',
        'night',
        'guard',
        'rest',
        'vacation',
        'old',
      ]);
      expect(snap.palette.map((t) => t.id), [
        'morning',
        'night',
        'guard',
        'rest',
        'vacation',
      ]);
      expect(snap.schedule.patterns, samplePatterns);
      expect(await repo.isEmpty(), isFalse);
    });

    test('past days keep resolving an archived type', () async {
      await seedSample();
      await repo.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            _today.addDays(-40): EntryChange(
              null,
              DayEntry(date: _today.addDays(-40), shiftTypeIds: const ['old']),
            ),
          }),
        ),
      );
      final snap = await repo.load(mainCalendarId);
      final day = snap.schedule.resolve(_today.addDays(-40));
      expect(day.shiftIds, ['old']);
      expect(snap.palette.map((t) => t.id), isNot(contains('old')));
    });
  });

  group('apply', () {
    setUp(seedSample);

    test('a day that already had an unknown id can still be edited', () async {
      // Old data the engine ignores: only ids a change adds must exist.
      final old = DayEntry(
        date: _today,
        shiftTypeIds: const ['morning', 'gone'],
      );
      await db
          .into(db.dayEntries)
          .insert(old.toCompanion(calendarId: mainCalendarId, updatedAt: 0));
      await repo.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            _today: EntryChange(old, old.copyWith(note: 'Nota nueva')),
          }),
        ),
      );
      final rows = await db.select(db.dayEntries).get();
      expect(rows.single.note, 'Nota nueva');
    });

    test(
      'unknown shift ids reject the whole patch without losing data',
      () async {
        await repo.apply(
          mainCalendarId,
          ScheduleChange(
            patch: EntriesPatch({
              _today: EntryChange(
                null,
                DayEntry(date: _today, note: 'Conservar'),
              ),
            }),
          ),
        );
        final before = await dumpTables(db);
        await expectLater(
          repo.apply(
            mainCalendarId,
            ScheduleChange(
              patch: EntriesPatch({
                _today: EntryChange(
                  null,
                  DayEntry(date: _today, note: 'Cambiar'),
                ),
                _today.addDays(1): EntryChange(
                  null,
                  DayEntry(
                    date: _today.addDays(1),
                    shiftTypeIds: const ['morning', 'missing'],
                  ),
                ),
              }),
            ),
          ),
          throwsStateError,
        );
        expect(await dumpTables(db), before);
      },
    );

    test('writes, updates and deletes day rows', () async {
      final d1 = _today;
      final d2 = _today.addDays(1);
      await repo.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            d1: EntryChange(
              null,
              DayEntry(date: d1, shiftTypeIds: const ['morning', 'night']),
            ),
            d2: EntryChange(null, DayEntry(date: d2, note: 'nota')),
          }),
        ),
      );
      var entries = (await repo.load(mainCalendarId)).schedule.entries;
      expect(entries.keys.toSet(), {d1, d2});
      expect(entries[d1]!.shiftTypeIds, ['morning', 'night']);
      expect(entries[d2]!.shiftTypeIds, isNull);

      // Update d1, delete d2.
      await repo.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            d1: EntryChange(
              entries[d1],
              DayEntry(date: d1, shiftTypeIds: const []),
            ),
            d2: EntryChange(entries[d2], null),
          }),
        ),
      );
      entries = (await repo.load(mainCalendarId)).schedule.entries;
      expect(entries.keys, [d1]);
      expect(entries[d1]!.shiftTypeIds, isEmpty);
    });

    test('an entry with nothing to store deletes the row', () async {
      await repo.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            _today: EntryChange(
              null,
              DayEntry(date: _today, shiftTypeIds: const ['rest']),
            ),
          }),
        ),
      );
      expect(
        await column('SELECT date FROM day_entries', 'date'),
        hasLength(1),
      );
      await repo.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            _today: EntryChange(null, DayEntry(date: _today, note: '')),
          }),
        ),
      );
      expect(await column('SELECT date FROM day_entries', 'date'), isEmpty);
    });

    test(
      'a paint stroke then its inverse leaves the database identical',
      () async {
        // Rotation + a few overrides, as in the demo.
        await repo.apply(
          mainCalendarId,
          ScheduleChange(
            patch: EntriesPatch({
              _today: EntryChange(
                null,
                DayEntry(
                  date: _today,
                  shiftTypeIds: const ['morning', 'night'],
                ),
              ),
              _today.addDays(1): EntryChange(
                null,
                DayEntry(date: _today.addDays(1), note: 'Cambio con Marta'),
              ),
            }),
            runsAfter: sampleRuns,
          ),
        );
        final before = await dumpTables(db);
        final schedule = (await repo.load(mainCalendarId)).schedule;

        final days = [for (var i = -2; i < 6; i++) _today.addDays(i)];
        for (final tool in [
          const PaintTool.replace('guard'),
          const PaintTool.add('rest'),
          const PaintTool.erase(),
        ]) {
          final patch = schedule.paint(tool, days);
          expect(patch.isEmpty, isFalse);
          final change = ScheduleChange(patch: patch);
          await repo.apply(mainCalendarId, change);
          expect(
            (await repo.load(mainCalendarId)).schedule.entries,
            patch.applyTo(schedule.entries),
          );
          await repo.apply(mainCalendarId, change.inverse());
          expect(await dumpTables(db), before, reason: '${tool.mode}');
          expect(
            (await repo.load(mainCalendarId)).schedule.entries,
            schedule.entries,
          );
        }
      },
    );

    test('runsAfter makes pattern_runs equal to the list', () async {
      await repo.apply(mainCalendarId, ScheduleChange(runsAfter: sampleRuns));
      expect((await repo.load(mainCalendarId)).schedule.runs, sampleRuns);

      // Drop run-2, change run-3, add run-4.
      final replaced = [
        sampleRuns[0].copyWith(endDate: _today.addDays(-1)),
        sampleRuns[2].copyWith(clearEndDate: true, stepOffset: 1),
        PatternRun(
          id: 'run-4',
          patternId: 'single',
          startDate: _today.addDays(50),
          seq: 4,
        ),
      ];
      await repo.apply(mainCalendarId, ScheduleChange(runsAfter: replaced));
      expect((await repo.load(mainCalendarId)).schedule.runs, replaced);
      expect(await column('SELECT id FROM pattern_runs', 'id'), hasLength(3));

      // Empty list removes every run.
      await repo.apply(mainCalendarId, const ScheduleChange(runsAfter: []));
      expect((await repo.load(mainCalendarId)).schedule.runs, isEmpty);
    });

    test('runsAfter null leaves the runs alone', () async {
      await repo.apply(mainCalendarId, ScheduleChange(runsAfter: sampleRuns));
      await repo.apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            _today: EntryChange(null, DayEntry(date: _today, note: 'x')),
          }),
        ),
      );
      expect((await repo.load(mainCalendarId)).schedule.runs, sampleRuns);
    });

    test(
      'applyPattern and its inverse round trip through the database',
      () async {
        await repo.apply(
          mainCalendarId,
          ScheduleChange(
            patch: EntriesPatch({
              _today.addDays(3): EntryChange(
                null,
                DayEntry(
                  date: _today.addDays(3),
                  shiftTypeIds: const ['vacation'],
                  note: 'viaje',
                ),
              ),
              _today.addDays(4): EntryChange(
                null,
                DayEntry(date: _today.addDays(4), shiftTypeIds: const ['rest']),
              ),
            }),
            runsAfter: sampleRuns,
          ),
        );
        final before = await dumpTables(db);
        final schedule = (await repo.load(mainCalendarId)).schedule;

        // Open-ended: cuts run-1, deletes the runs that start later.
        final open = schedule.applyPattern(
          'single',
          _today.addDays(1),
          clearOverrides: true,
        );
        await repo.apply(mainCalendarId, open);
        final afterOpen = (await repo.load(mainCalendarId)).schedule;
        expect(afterOpen.runs.map((r) => r.id), ['run-1', 'run-4']);
        expect(afterOpen.runs.first.endDate, _today);
        // The note survived, the shift overrides in range are gone.
        expect(afterOpen.entries[_today.addDays(3)]!.shiftTypeIds, isNull);
        expect(afterOpen.entries[_today.addDays(3)]!.note, 'viaje');
        expect(afterOpen.entries.containsKey(_today.addDays(4)), isFalse);

        await repo.apply(mainCalendarId, open.inverse());
        expect(await dumpTables(db), before);

        // Bounded: keeps the others and adds a run with an end.
        final bounded = schedule.applyPattern(
          'single',
          _today.addDays(5),
          until: _today.addDays(6),
        );
        await repo.apply(mainCalendarId, bounded);
        final afterBounded = (await repo.load(mainCalendarId)).schedule;
        expect(afterBounded.runs, bounded.runsAfter);
        await repo.apply(mainCalendarId, bounded.inverse());
        expect(await dumpTables(db), before);
      },
    );

    test('runs keep their creation time when rewritten', () async {
      await repo.apply(
        mainCalendarId,
        ScheduleChange(runsAfter: [sampleRuns[0]]),
      );
      clock = _now.add(const Duration(hours: 1));
      await repo.apply(
        mainCalendarId,
        ScheduleChange(
          runsAfter: [
            sampleRuns[0].copyWith(endDate: _today),
            sampleRuns[1],
          ],
        ),
      );
      final created = await column(
        'SELECT created_at FROM pattern_runs ORDER BY seq',
        'created_at',
      );
      expect(created, [
        _now.millisecondsSinceEpoch,
        clock.millisecondsSinceEpoch,
      ]);
    });

    test('is atomic: a failure writes nothing', () async {
      final bad = ScheduleChange(
        patch: EntriesPatch({
          _today: EntryChange(
            null,
            DayEntry(date: _today, shiftTypeIds: const ['morning']),
          ),
        }),
        runsAfter: [
          PatternRun(
            id: 'ghost',
            patternId: 'does-not-exist', // foreign key violation
            startDate: _today,
            seq: 1,
          ),
        ],
      );
      await expectLater(repo.apply(mainCalendarId, bad), throwsA(anything));
      expect(await column('SELECT date FROM day_entries', 'date'), isEmpty);
      expect(await column('SELECT id FROM pattern_runs', 'id'), isEmpty);
    });
  });

  group('shift types and patterns', () {
    test(
      'a new type goes last; saving again keeps position and flags',
      () async {
        await seedSample();
        const extra = ShiftType(
          id: 'extra',
          code: 'E',
          name: 'Extra',
          colorValue: 0xFF123456,
          category: ShiftCategory.work,
          startMinute: 600,
          endMinute: 700,
        );
        await repo.saveShiftType(extra);
        var snap = await repo.load(mainCalendarId);
        expect(snap.schedule.shiftTypes.last.id, 'extra');

        clock = _now.add(const Duration(days: 1));
        await repo.archiveShiftType('extra');
        await repo.saveShiftType(extra.copyWith(name: 'Extra renombrado'));
        snap = await repo.load(mainCalendarId);
        expect(snap.schedule.shiftTypes.last.name, 'Extra renombrado');
        // Still archived and in the same place.
        expect(snap.palette.map((t) => t.id), isNot(contains('extra')));
        final created = await column(
          "SELECT created_at, updated_at FROM shift_types WHERE id = 'extra'",
          'created_at',
        );
        expect(created.single, _now.millisecondsSinceEpoch);
        final updated = await column(
          "SELECT updated_at FROM shift_types WHERE id = 'extra'",
          'updated_at',
        );
        expect(updated.single, clock.millisecondsSinceEpoch);
      },
    );

    test('archiving an unknown id does nothing', () async {
      await seedSample();
      await repo.archiveShiftType('nope');
      expect((await repo.load(mainCalendarId)).palette, hasLength(5));
    });

    test('savePattern upserts and keeps the order', () async {
      await seedSample();
      await repo.savePattern(
        const Pattern(
          id: 'cycle',
          name: 'Renombrado',
          steps: [
            ['rest'],
          ],
        ),
      );
      final patterns = (await repo.load(mainCalendarId)).schedule.patterns;
      expect(patterns.map((p) => p.id), ['cycle', 'single']);
      expect(patterns.first.name, 'Renombrado');
      expect(patterns.first.steps, [
        ['rest'],
      ]);
    });

    test('a pattern needs at least one step', () async {
      await expectLater(
        repo.savePattern(const Pattern(id: 'x', name: 'x', steps: [])),
        throwsArgumentError,
      );
    });
  });
}
