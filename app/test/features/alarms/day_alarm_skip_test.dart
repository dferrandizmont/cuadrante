import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/data/alarm_settings_repository.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

// Demo data around Monday 19 Oct 2026, 12:00: Noche 19-23, Libre 24-25,
// Mañana 26-30.
const _oct20 = CivilDate(2026, 10, 20);
const _oct24 = CivilDate(2026, 10, 24);

const _nightOn = AlarmSettings(
  enabled: true,
  byShiftType: {'night': AlarmTypeSettings(enabled: true)},
);

Finder get _skip => find.byKey(const ValueKey('day-alarm-skip-switch'));

void main() {
  setUpAll(initializeLocale);

  late FakeAlarmScheduler scheduler;
  setUp(() => scheduler = FakeAlarmScheduler());

  Future<AppUnderTest> pumpApp(
    WidgetTester tester, {
    AlarmSettings settings = AlarmSettings.disabled,
    Future<void> Function()? beforeOpen,
    String? extraSql,
  }) async {
    final app = await AppUnderTest.pump(
      tester,
      size: const Size(390, 1200),
      prepare: (db) async {
        await AlarmSettingsRepository(db).save(settings);
        if (extraSql != null) await db.customStatement(extraSql);
      },
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    // Let the first sync (at start) finish.
    await tester.pumpAndSettle();
    return app;
  }

  Future<void> openDay(WidgetTester tester, CivilDate date) async {
    await tester.ensureVisible(dayCell(date));
    await tester.pumpAndSettle();
    await tester.tap(dayCell(date));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  }

  Future<AlarmSettings> stored(AppUnderTest app) =>
      app.real(() => AlarmSettingsRepository(app.database).load());

  testWidgets('alarms off: the day detail has no such row', (tester) async {
    await pumpApp(tester);
    await openDay(tester, _oct20);
    expect(_skip, findsNothing);
  });

  testWidgets('a day with an alarm shift: toggling skips it and resyncs', (
    tester,
  ) async {
    final app = await pumpApp(tester, settings: _nightOn);
    // Every night of the demo rings: 19 to 23 October.
    expect(
      scheduler.scheduled.map((a) => a.shiftDate),
      contains(_oct20),
      reason: 'before skipping',
    );
    final before = scheduler.scheduled.length;

    await openDay(tester, _oct20);
    expect(_skip, findsOneWidget);
    expect(find.text('Sin alarma este día'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(_skip).value, isFalse);

    await tester.ensureVisible(_skip);
    await tester.tap(_skip);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(_skip).value, isTrue);
    expect((await stored(app)).skippedDates, {_oct20});
    // Exactly the alarm of that day is gone, the rest is untouched.
    expect(
      scheduler.scheduled.map((a) => a.shiftDate),
      isNot(contains(_oct20)),
    );
    expect(scheduler.scheduled.length, before - 1);

    // Closing and reopening the sheet keeps it.
    await closeSheet(tester);
    await openDay(tester, _oct20);
    expect(tester.widget<SwitchListTile>(_skip).value, isTrue);

    await tester.ensureVisible(_skip);
    await tester.tap(_skip);
    await tester.pumpAndSettle();
    expect((await stored(app)).skippedDates, isEmpty);
    expect(scheduler.scheduled.map((a) => a.shiftDate), contains(_oct20));
    expect(scheduler.scheduled.length, before);
  });

  testWidgets('skipping also drops the reminder the evening before', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      settings: _nightOn.withShiftType(
        'night',
        const AlarmTypeSettings(enabled: true, dayBefore: true),
      ),
    );
    final before = scheduler.scheduled.where((a) => a.shiftDate == _oct20);
    expect(before, hasLength(2), reason: 'alarm + reminder of the 20th');

    await openDay(tester, _oct20);
    await tester.ensureVisible(_skip);
    await tester.tap(_skip);
    await tester.pumpAndSettle();
    expect(
      scheduler.scheduled.where((a) => a.shiftDate == _oct20),
      isEmpty,
      reason: 'neither alarm nor reminder',
    );
    expect((await stored(app)).skippedDates, {_oct20});
  });

  testWidgets('a day without an alarm shift has no row', (tester) async {
    await pumpApp(tester, settings: _nightOn);
    await openDay(tester, _oct24); // Libre
    expect(_skip, findsNothing);
  });

  testWidgets('a type with its alarm off has no row', (tester) async {
    await pumpApp(
      tester,
      settings: const AlarmSettings(
        enabled: true,
        byShiftType: {'morning': AlarmTypeSettings(enabled: true)},
      ),
    );
    await openDay(tester, _oct20); // Noche, only Mañana rings
    expect(_skip, findsNothing);
  });

  testWidgets('an absence with times and its switch on has no row (it never '
      'rings)', (tester) async {
    await pumpApp(
      tester,
      settings: _nightOn,
      // Noche became an absence: it has times and its switch, but the planner
      // never rings an absence.
      extraSql:
          "UPDATE shift_types SET category = 'absence' WHERE id = 'night'",
    );
    await openDay(tester, _oct20);
    expect(_skip, findsNothing);
  });

  testWidgets('a skipped day keeps the switch even if its shift changed', (
    tester,
  ) async {
    await pumpApp(
      tester,
      settings: _nightOn.withSkipped(_oct24, skipped: true),
    );
    await openDay(tester, _oct24); // Libre now, but it was skipped
    expect(_skip, findsOneWidget);
    expect(tester.widget<SwitchListTile>(_skip).value, isTrue);
  });

  testWidgets('on a calendar that is not the primary one: no row', (
    tester,
  ) async {
    await AppUnderTest.pump(
      tester,
      size: const Size(390, 1200),
      prepare: (db) async {
        await AlarmSettingsRepository(db).save(_nightOn);
        // On screen: the second calendar; the primary one stays "main".
        await CalendarsRepository(db).setActive(await addSecondCalendar(db));
      },
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
    );
    await openDay(tester, _oct20);
    expect(_skip, findsNothing);
  });
}
