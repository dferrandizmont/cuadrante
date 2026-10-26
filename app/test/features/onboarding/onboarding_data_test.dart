import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/onboarding/data/onboarding_repository.dart';
import 'package:cuadrante/features/onboarding/domain/profession.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';
import 'onboarding_support.dart';

/// The seeded database of a first launch (no demo data), bootstrapped like
/// `main` does.
Future<AppDatabase> _freshDatabase({bool demo = false}) async {
  final db = openMemoryDatabase();
  await bootstrapApp(
    config: AppConfig(useDemoData: demo),
    database: db,
    now: () => onboardingNow,
  );
  return db;
}

Future<OnboardingStatus> _status(
  AppDatabase db, {
  bool demo = false,
  bool force = false,
}) => OnboardingRepository(db).resolve(demo: demo, force: force);

Future<Map<String, String>> _settings(AppDatabase db) async => {
  for (final row in await db.select(db.settings).get()) row.key: row.value,
};

void main() {
  setUpAll(initializeLocale);

  group('when the flow is shown (upgrade path)', () {
    test('a first launch with an empty calendar shows it', () async {
      final db = await _freshDatabase();
      addTearDown(db.close);
      expect(await _status(db), const OnboardingStatus(needed: true));
      // Looking is not marking: it is still pending.
      expect((await _settings(db)).containsKey('onboarding.done'), isFalse);
    });

    test('someone who upgrades with a rotation never sees it', () async {
      final db = await _freshDatabase();
      addTearDown(db.close);
      await ScheduleRepository(db, now: () => onboardingNow).apply(
        mainCalendarId,
        ScheduleChange(
          runsAfter: [
            PatternRun(
              id: 'run-1',
              patternId: '12h',
              startDate: onboardingToday,
              seq: 1,
            ),
          ],
        ),
      );
      expect(await _status(db), OnboardingStatus.none);
      // Marked done: deleting everything later does not bring it back.
      expect((await _settings(db))['onboarding.done'], 'true');
      await db.delete(db.patternRuns).go();
      expect(await _status(db), OnboardingStatus.none);
    });

    test('a day edited by hand is data too', () async {
      final db = await _freshDatabase();
      addTearDown(db.close);
      await ScheduleRepository(db, now: () => onboardingNow).apply(
        mainCalendarId,
        ScheduleChange(
          patch: EntriesPatch({
            onboardingToday: EntryChange(
              null,
              DayEntry(date: onboardingToday, shiftTypeIds: const ['night']),
            ),
          }),
        ),
      );
      expect(await _status(db), OnboardingStatus.none);
    });

    test('data in another calendar counts', () async {
      final db = await _freshDatabase();
      addTearDown(db.close);
      final other = (await CalendarsRepository(
        db,
        now: () => onboardingNow,
      ).create(name: 'Pareja', colorValue: 0xFF30A46C)).id;
      await ScheduleRepository(db, now: () => onboardingNow).apply(
        other,
        ScheduleChange(
          patch: EntriesPatch({
            onboardingToday: EntryChange(
              null,
              DayEntry(date: onboardingToday, shiftTypeIds: const ['night']),
            ),
          }),
        ),
      );
      expect(await _status(db), OnboardingStatus.none);
    });

    group('configuration without runs or days (an upgrade from 0.3.x)', () {
      Future<void> expectSkipped(
        Future<void> Function(AppDatabase db) configure,
      ) async {
        final db = await _freshDatabase();
        addTearDown(db.close);
        await configure(db);
        expect(await _status(db), OnboardingStatus.none);
        expect((await _settings(db))['onboarding.done'], 'true');
      }

      test('a shift type edited after it was created', () async {
        await expectSkipped(
          (db) => db.customStatement(
            "UPDATE shift_types SET updated_at = created_at + 1000 WHERE id = 'night'",
          ),
        );
      });

      test('a place chosen for the holidays', () async {
        await expectSkipped(
          (db) => db.customStatement(
            "INSERT INTO settings (key, value) VALUES ('holidays.region', '\"ES-CT\"')",
          ),
        );
      });

      test('alarms switched on', () async {
        await expectSkipped(
          (db) => db.customStatement(
            "INSERT INTO settings (key, value) VALUES ('alarms', "
            "'{\"enabled\":true,\"horizonDays\":14,\"types\":{}}')",
          ),
        );
      });

      test('more than one calendar', () async {
        await expectSkipped(
          (db) => CalendarsRepository(
            db,
            now: () => onboardingNow,
          ).create(name: 'Pareja', colorValue: 0xFF30A46C),
        );
      });

      test(
        'alarms present but off, and no region: still a first launch',
        () async {
          final db = await _freshDatabase();
          addTearDown(db.close);
          await db.customStatement(
            "INSERT INTO settings (key, value) VALUES ('alarms', "
            "'{\"enabled\":false,\"horizonDays\":14,\"types\":{}}')",
          );
          await db.customStatement(
            "INSERT INTO settings (key, value) VALUES ('holidays.region', 'null')",
          );
          expect(await _status(db), const OnboardingStatus(needed: true));
        },
      );
    });

    test('a build with demo data skips it, unless forced', () async {
      final db = await _freshDatabase(demo: true);
      addTearDown(db.close);
      expect(await _status(db, demo: true), OnboardingStatus.none);
      expect(
        await _status(db, demo: true, force: true),
        const OnboardingStatus(needed: true),
      );
      // Even an empty database in a demo build skips it.
      final empty = await _freshDatabase();
      addTearDown(empty.close);
      expect(await _status(empty, demo: true), OnboardingStatus.none);
    });

    test('forced ignores the data, not the "done" mark', () async {
      final db = await _freshDatabase(demo: true);
      addTearDown(db.close);
      final repository = OnboardingRepository(db);
      expect(
        await repository.resolve(demo: true, force: true),
        const OnboardingStatus(needed: true),
      );
      await repository.markDone();
      expect(
        await repository.resolve(demo: true, force: true),
        OnboardingStatus.none,
      );
    });

    test('done once, never again; the tip is remembered apart', () async {
      final db = await _freshDatabase();
      addTearDown(db.close);
      final repository = OnboardingRepository(db);
      await repository.markDone(tip: true);
      expect(await _status(db), const OnboardingStatus(tipPending: true));
      await repository.setTipPending(false);
      expect(await _status(db), OnboardingStatus.none);
    });

    test('bootstrapApp hands the decision to main', () async {
      final db = openMemoryDatabase();
      addTearDown(db.close);
      final boot = await bootstrapApp(
        config: const AppConfig(useDemoData: false),
        database: db,
        now: () => onboardingNow,
      );
      expect(boot.onboarding.needed, isTrue);

      final demo = openMemoryDatabase();
      addTearDown(demo.close);
      final demoBoot = await bootstrapApp(
        config: const AppConfig(useDemoData: true),
        database: demo,
        now: () => onboardingNow,
      );
      expect(demoBoot.onboarding.needed, isFalse);

      final forced = await bootstrapApp(
        config: const AppConfig(useDemoData: true, forceOnboarding: true),
        database: demo,
        now: () => onboardingNow,
      );
      expect(forced.onboarding.needed, isTrue);
    });

    test('an unreadable database means "do not show", never a crash', () async {
      final db = await _freshDatabase();
      addTearDown(db.close);
      await db.customStatement('DROP TABLE settings');
      expect(await _status(db), OnboardingStatus.none);
    });
  });

  group('profession -> shift types', () {
    test('every profession is stored and read back by name', () {
      for (final p in Profession.values) {
        expect(Profession.fromStored(p.stored), p);
      }
      expect(Profession.fromStored('astronaut'), isNull);
      expect(Profession.fromStored(null), isNull);
    });

    test('the hours of each profession, on the seeded types', () async {
      final db = await _freshDatabase();
      addTearDown(db.close);
      final seeded = (await ScheduleRepository(
        db,
        now: () => onboardingNow,
      ).load(mainCalendarId)).schedule;

      // (profession) -> id -> start-end, in hours.
      const expected = {
        Profession.nursing: {
          'morning': (8, 15),
          'afternoon': (15, 22),
          'night': (22, 8),
        },
        Profession.medicine: {'morning': (8, 15)},
        Profession.police: {
          'morning': (7, 15),
          'afternoon': (15, 23),
          'night': (23, 7),
        },
        Profession.hospitality: {'morning': (8, 16), 'afternoon': (16, 0)},
        Profession.firefighters: <String, (int, int)>{},
        Profession.industry: <String, (int, int)>{},
        Profession.security: <String, (int, int)>{},
        Profession.other: <String, (int, int)>{},
      };
      for (final profession in Profession.values) {
        final changed = {
          for (final t in professionShiftTypes(seeded, profession))
            t.id: (t.startMinute! ~/ 60, t.endMinute! ~/ 60),
        };
        expect(changed, expected[profession], reason: profession.name);
      }

      // The standard palette already is the one of these jobs.
      expect(seeded.shiftTypeById('guard24')!.durationMinutes, 24 * 60);
      expect(seeded.shiftTypeById('morning')!.compactTimeRangeForTest, '06–14');
    });

    test('a type the person already edited is left alone', () async {
      final db = await _freshDatabase();
      addTearDown(db.close);
      final seeded = (await ScheduleRepository(
        db,
        now: () => onboardingNow,
      ).load(mainCalendarId)).schedule;
      final edited = seeded.copyWith(
        shiftTypes: [
          for (final t in seeded.shiftTypes)
            if (t.id == 'morning')
              t.copyWith(startMinute: 5 * 60, endMinute: 13 * 60)
            else if (t.id == 'afternoon')
              t
            else
              t,
        ]..removeWhere((t) => t.id == 'night'),
      );
      final changed = {
        for (final t in professionShiftTypes(edited, Profession.nursing))
          t.id: t,
      };
      expect(changed.keys, ['afternoon'], reason: 'morning edited, night gone');
    });

    test('the palette order puts the job first, with no duplicates', () async {
      final db = await _freshDatabase();
      addTearDown(db.close);
      final seeded = (await ScheduleRepository(
        db,
        now: () => onboardingNow,
      ).load(mainCalendarId));
      for (final profession in Profession.values) {
        final order = professionPaletteOrder(seeded.palette, profession);
        expect(order.toSet(), hasLength(order.length), reason: profession.name);
        expect(order.toSet(), {
          for (final t in seeded.palette) t.id,
        }, reason: '${profession.name}: same types, none added or lost');
        for (final (i, id) in profession.paletteFirst.indexed) {
          expect(order[i], id, reason: '${profession.name} #$i');
        }
      }
      expect(professionPaletteOrder(seeded.palette, Profession.other), [
        for (final t in seeded.palette) t.id,
      ], reason: 'other leaves the palette as it is');
    });

    test('every preset a profession offers exists in the catalogue', () {
      final ids = {for (final p in patternPresets) p.id};
      for (final profession in Profession.values) {
        expect(
          profession.presetIds.toSet(),
          hasLength(profession.presetIds.length),
          reason: profession.name,
        );
        expect(ids.containsAll(profession.presetIds), isTrue);
        for (final key in profession.paletteFirst) {
          expect(shiftTemplates.any((t) => t.key == key), isTrue, reason: key);
        }
      }
    });
  });

  group('the flow writes through the existing paths', () {
    testWidgets('nursing: hours changed once, no type duplicated, stored', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      final before = app.schedule.shiftTypes.length;
      final ids = [for (final t in app.schedule.shiftTypes) t.id];

      await app.tap(key('onboarding-profession-nursing'));
      await app.tap(key('onboarding-next'));
      await app.tap(key('onboarding-skip')); // place
      await app.tap(key('onboarding-skip')); // rotation
      await app.tap(key('onboarding-next')); // import -> writes
      await app.flushWrites();

      // In memory, the palette of the paint bar and the engine.
      final types = app.schedule.shiftTypes;
      expect(types, hasLength(before));
      expect(types.map((t) => t.id).toSet(), ids.toSet());
      expect({for (final t in types) t.code}, hasLength(types.length));
      final state = app.schedule;
      expect(state.shiftTypeById('morning')!.compactTimeRangeForTest, '08–15');
      expect(
        state.shiftTypeById('afternoon')!.compactTimeRangeForTest,
        '15–22',
      );
      expect(state.shiftTypeById('night')!.compactTimeRangeForTest, '22–08');
      expect(state.shiftTypeById('guard24')!.compactTimeRangeForTest, '08–08');

      // And in the database: same count, same ids, new hours, new order.
      final rows = await app.real(
        () => app.database
            .customSelect(
              'SELECT id, start_minute, end_minute FROM shift_types '
              'ORDER BY sort_order',
            )
            .get(),
      );
      expect(rows, hasLength(before));
      expect(
        [for (final r in rows) r.read<String>('id')].take(7),
        Profession.nursing.paletteFirst,
      );
      final byId = {for (final r in rows) r.read<String>('id'): r};
      expect(byId['morning']!.read<int>('start_minute'), 8 * 60);
      expect(byId['night']!.read<int>('end_minute'), 8 * 60);
      expect(
        (await app.real(
          () => OnboardingRepository(app.database).loadProfile(),
        )),
        Profession.nursing,
      );
    });

    testWidgets('the rotation applied equals what the engine gives', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      final start = onboardingToday.addDays(3);

      await app.tap(key('onboarding-profession-nursing'));
      await app.tap(key('onboarding-next'));
      await app.tap(key('onboarding-skip'));
      await app.tap(key('onboarding-pattern-correturnos'));
      await app.tap(key('onboarding-next'));
      await tester.tap(key('onboarding-start-date'));
      await tester.pumpAndSettle();
      final dialog = find.byType(DatePickerDialog);
      await tester.tap(find.descendant(of: dialog, matching: find.text('22')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: dialog, matching: find.byType(TextButton)).last,
      );
      await tester.pumpAndSettle();
      await app.tap(key('onboarding-offset-6'));
      await app.tap(key('onboarding-next'));
      await app.tap(key('onboarding-next')); // import -> writes
      await app.flushWrites();

      // The same request through the engine on the schedule as it was.
      final seeded = (await app.real(
        () => ScheduleRepository(
          app.database,
          now: () => onboardingNow,
        ).load(mainCalendarId),
      )).schedule;
      final pattern = seeded.patternById('correturnos')!;
      final expected = seeded.apply(
        seeded.applyPattern(pattern.id, start, stepOffset: 6, seq: 1),
      );
      final from = onboardingToday.addDays(-7);
      List<String> days(Schedule s) => [
        for (final d in s.resolveRange(from, from.addDays(120)))
          '${d.date.toIso()}|${d.shiftIds.join('+')}',
      ];
      expect(days(app.schedule), days(expected));
      expect(app.schedule.runs, hasLength(1));
      final run = app.schedule.runs.single;
      expect(run.patternId, 'correturnos');
      expect(run.startDate, start);
      expect(run.stepOffset, 6);
      expect(run.endDate, isNull);
      // Day 7 of the cycle (index 6) is the second rest day, then the
      // five afternoons.
      expect(idsOn(app.schedule, start), 'rest');
      expect(idsOn(app.schedule, start.addDays(1)), 'afternoon');
      expect(idsOn(app.schedule, start.addDays(5)), 'afternoon');
      expect(idsOn(app.schedule, start.addDays(6)), 'rest');
      // Nothing before the start: the days before are still empty.
      expect(idsOn(app.schedule, onboardingToday), '');
    });
  });

  group('the month it lands on', () {
    testWidgets('is already painted with the rotation from today', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-profession-firefighters'));
      await app.tap(key('onboarding-next'));
      await app.tap(key('onboarding-skip'));
      await app.tap(key('onboarding-pattern-24x72'));
      await app.tap(key('onboarding-next'));
      await app.tap(key('onboarding-next'));
      await app.tap(key('onboarding-next'));
      await app.tap(key('onboarding-next'));
      expect(find.byType(MonthScreen), findsOneWidget);
      // 24 x 72 from today: G on the 19th and the 23rd, rest between.
      expect(
        find.descendant(of: key('day-2026-10-19'), matching: find.text('G')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: key('day-2026-10-23'), matching: find.text('G')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: key('day-2026-10-20'), matching: find.text('L')),
        findsOneWidget,
      );
    });
  });
}

extension on ShiftType {
  /// "08–15" (hours only, to keep the table of the test short).
  String get compactTimeRangeForTest {
    String two(int minute) => (minute ~/ 60).toString().padLeft(2, '0');
    return '${two(startMinute!)}–${two(endMinute!)}';
  }
}
