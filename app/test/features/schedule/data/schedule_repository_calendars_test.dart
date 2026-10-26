import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/sample_data.dart';
import '../../../support/test_storage.dart';

/// The schedule of each calendar (docs/datos.md, "Esquema v2"): shift types
/// and patterns are common, runs and days belong to one calendar, and a
/// write to one never touches another.
void main() {
  late AppDatabase db;
  late ScheduleRepository repo;
  late CalendarsRepository calendars;
  late String a; // main
  late String b;

  const d1 = CivilDate(2026, 10, 19);
  const d2 = CivilDate(2026, 10, 20);

  ScheduleChange paintDays(Map<CivilDate, DayEntry> days) => ScheduleChange(
    patch: EntriesPatch({
      for (final e in days.entries) e.key: EntryChange(null, e.value),
    }),
  );

  DayEntry shifts(CivilDate d, List<String> ids, {String? note}) =>
      DayEntry(date: d, shiftTypeIds: ids, note: note);

  setUp(() async {
    db = openMemoryDatabase();
    repo = ScheduleRepository(db, now: () => DateTime.utc(2026, 10, 19));
    calendars = CalendarsRepository(db);
    for (final r in sampleShiftTypes) {
      await repo.saveShiftType(r.type, sortOrder: r.sortOrder);
    }
    for (final p in samplePatterns) {
      await repo.savePattern(p);
    }
    a = 'main';
    b = (await calendars.create(name: 'Pareja', colorValue: 1)).id;
  });
  tearDown(() => db.close());

  group('load', () {
    test('shift types and patterns are common to every calendar', () async {
      final one = await repo.load(a);
      final two = await repo.load(b);
      expect(one.schedule.shiftTypes, two.schedule.shiftTypes);
      expect(one.schedule.patterns, two.schedule.patterns);
      expect(one.palette, two.palette);
      expect(one.schedule.shiftTypes, hasLength(sampleShiftTypes.length));
      expect(one.calendarId, a);
      expect(two.calendarId, b);
    });

    test('runs and days are those of the calendar asked for', () async {
      await repo.apply(
        a,
        ScheduleChange(
          patch: paintDays({
            d1: shifts(d1, ['morning']),
          }).patch,
          runsAfter: [sampleRuns[0]],
        ),
      );
      await repo.apply(
        b,
        ScheduleChange(
          patch: paintDays({
            d2: shifts(d2, ['night'], note: 'b'),
          }).patch,
          runsAfter: [sampleRuns[1]],
        ),
      );

      final one = (await repo.load(a)).schedule;
      final two = (await repo.load(b)).schedule;
      expect(one.runs, [sampleRuns[0]]);
      expect(two.runs, [sampleRuns[1]]);
      expect(one.entries.keys, [d1]);
      expect(two.entries.keys, [d2]);
      expect(one.resolve(d2).shiftIds, isNot(['night']));
    });

    test('an unknown calendar loads as empty', () async {
      final ghost = (await repo.load('ghost')).schedule;
      expect(ghost.runs, isEmpty);
      expect(ghost.entries, isEmpty);
      expect(ghost.shiftTypes, isNotEmpty);
    });
  });

  group('apply writes only to its calendar', () {
    test('the same date has an independent day in each calendar', () async {
      await repo.apply(
        a,
        paintDays({
          d1: shifts(d1, ['morning']),
        }),
      );
      await repo.apply(
        b,
        paintDays({
          d1: shifts(d1, ['night'], note: 'b'),
        }),
      );

      expect((await repo.load(a)).schedule.entries[d1]!.shiftTypeIds, [
        'morning',
      ]);
      expect((await repo.load(b)).schedule.entries[d1]!.shiftTypeIds, [
        'night',
      ]);

      // Changing it in one leaves the other as it was.
      await repo.apply(
        b,
        ScheduleChange(
          patch: EntriesPatch({
            d1: EntryChange(
              shifts(d1, ['night'], note: 'b'),
              shifts(d1, ['rest']),
            ),
          }),
        ),
      );
      expect((await repo.load(a)).schedule.entries[d1]!.shiftTypeIds, [
        'morning',
      ]);
      expect((await repo.load(b)).schedule.entries[d1]!.shiftTypeIds, ['rest']);
    });

    test(
      'deleting a day in one calendar keeps the same day in the other',
      () async {
        await repo.apply(
          a,
          paintDays({
            d1: shifts(d1, ['morning']),
          }),
        );
        await repo.apply(
          b,
          paintDays({
            d1: shifts(d1, ['night']),
          }),
        );

        await repo.apply(
          a,
          ScheduleChange(
            patch: EntriesPatch({
              d1: EntryChange(shifts(d1, ['morning']), null),
            }),
          ),
        );

        expect((await repo.load(a)).schedule.entries, isEmpty);
        expect((await repo.load(b)).schedule.entries.keys, [d1]);
      },
    );

    test('replacing the runs of one calendar leaves the other ones', () async {
      await repo.apply(a, ScheduleChange(runsAfter: [sampleRuns[0]]));
      await repo.apply(b, ScheduleChange(runsAfter: [sampleRuns[1]]));

      // `runsAfter: []` empties calendar a only.
      await repo.apply(a, const ScheduleChange(runsAfter: []));
      expect((await repo.load(a)).schedule.runs, isEmpty);
      expect((await repo.load(b)).schedule.runs, [sampleRuns[1]]);

      // Cutting the run of b does not touch a (here: still empty).
      final cut = sampleRuns[1].copyWith(
        endDate: sampleRuns[1].startDate.addDays(2),
      );
      await repo.apply(b, ScheduleChange(runsAfter: [cut]));
      expect((await repo.load(b)).schedule.runs, [cut]);
      expect((await repo.load(a)).schedule.runs, isEmpty);
    });

    test(
      'undo (the inverse change) is also confined to its calendar',
      () async {
        final change = ScheduleChange(
          patch: paintDays({
            d1: shifts(d1, ['morning']),
          }).patch,
          runsBefore: const [],
          runsAfter: [sampleRuns[0]],
        );
        await repo.apply(
          b,
          paintDays({
            d1: shifts(d1, ['night']),
          }),
        );
        await repo.apply(a, change);
        await repo.apply(a, change.inverse());

        final one = (await repo.load(a)).schedule;
        expect(one.entries, isEmpty);
        expect(one.runs, isEmpty);
        expect((await repo.load(b)).schedule.entries.keys, [d1]);
      },
    );

    test('a write to an unknown calendar fails and writes nothing', () async {
      await expectLater(
        repo.apply(
          'ghost',
          ScheduleChange(
            patch: paintDays({
              d1: shifts(d1, ['morning']),
            }).patch,
            runsAfter: [sampleRuns[0]],
          ),
        ),
        throwsA(anything),
      );
      expect(await db.select(db.dayEntries).get(), isEmpty);
      expect(await db.select(db.patternRuns).get(), isEmpty);
    });

    test(
      'a run id that belongs to another calendar is refused, atomically',
      () async {
        await repo.apply(a, ScheduleChange(runsAfter: [sampleRuns[0]]));

        await expectLater(
          repo.apply(
            b,
            ScheduleChange(
              patch: paintDays({
                d2: shifts(d2, ['night']),
              }).patch,
              runsAfter: [sampleRuns[0].copyWith(seq: 99)],
            ),
          ),
          throwsA(isA<StateError>()),
        );

        expect((await repo.load(a)).schedule.runs, [sampleRuns[0]]);
        expect((await repo.load(b)).schedule.runs, isEmpty);
        expect(
          (await repo.load(b)).schedule.entries,
          isEmpty,
          reason: 'rolled back',
        );
      },
    );
  });

  group('seq is unique across calendars', () {
    test('the same seq in two calendars is refused', () async {
      await repo.apply(a, ScheduleChange(runsAfter: [sampleRuns[0]]));
      final clash = PatternRun(
        id: 'other-run',
        patternId: 'cycle',
        startDate: d1,
        seq: sampleRuns[0].seq,
      );
      await expectLater(
        repo.apply(b, ScheduleChange(runsAfter: [clash])),
        throwsA(anything),
      );
      expect((await repo.load(b)).schedule.runs, isEmpty);
    });

    test('nextRunSeq looks at every calendar', () async {
      expect(await repo.nextRunSeq(), 1);
      await repo.apply(a, ScheduleChange(runsAfter: [sampleRuns[0]])); // seq 1
      await repo.apply(b, ScheduleChange(runsAfter: [sampleRuns[1]])); // seq 2
      expect(await repo.nextRunSeq(), 3);
    });

    test('applyPattern with that seq works in either calendar', () async {
      await repo.apply(a, ScheduleChange(runsAfter: [sampleRuns[0]])); // seq 1
      final schedule = (await repo.load(b)).schedule; // no runs: local max 0
      expect(schedule.runs, isEmpty);

      // Without help the new run would take seq 1 and id run-1: the clash.
      final clashing = schedule.applyPattern('cycle', d1);
      expect(clashing.runsAfter!.single.seq, 1);
      await expectLater(repo.apply(b, clashing), throwsA(anything));

      final change = schedule.applyPattern(
        'cycle',
        d1,
        seq: await repo.nextRunSeq(),
      );
      await repo.apply(b, change);
      final run = (await repo.load(b)).schedule.runs.single;
      expect(run.seq, 2);
      expect(run.id, 'run-2');
      expect((await repo.load(a)).schedule.runs, [sampleRuns[0]]);
    });
  });

  group('the hourly rate', () {
    test('is kept by saveShiftType and read by load', () async {
      final loaded = (await repo.load(a)).schedule.shiftTypes;
      expect(loaded.firstWhere((t) => t.id == 'morning').hourlyRateCents, 1250);
      expect(loaded.firstWhere((t) => t.id == 'night').hourlyRateCents, isNull);

      final morning = loaded.firstWhere((t) => t.id == 'morning');
      await repo.saveShiftType(morning.copyWith(hourlyRateCents: 1400));
      await repo.saveShiftType(
        loaded
            .firstWhere((t) => t.id == 'guard')
            .copyWith(clearHourlyRate: true),
      );
      final after = (await repo.load(b)).schedule.shiftTypes;
      expect(after.firstWhere((t) => t.id == 'morning').hourlyRateCents, 1400);
      expect(after.firstWhere((t) => t.id == 'guard').hourlyRateCents, isNull);
    });
  });
}
