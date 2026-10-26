import 'dart:convert';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/alarms/application/alarm_providers.dart'
    show alarmSystemProvider;
import 'package:cuadrante/features/alarms/data/alarm_system.dart';
import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/calendar/presentation/day_detail_sheet.dart';
import 'package:cuadrante/features/calendars/application/calendars_controller.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/widget/application/widget_providers.dart';
import 'package:cuadrante/features/widget/data/widget_publisher.dart';
import 'package:cuadrante/features/widget/domain/widget_links.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../backup/backup_ui_support.dart';
import '../backup/golden_dataset_v2.dart';

/// First day and today's big text of the last published snapshot.
({String firstDate, String zone, String big}) _last(
  FakeWidgetPublisher publisher,
) {
  final j = jsonDecode(publisher.published.last) as Map<String, Object?>;
  final days = (j['days']! as List).cast<Map<String, Object?>>();
  final small = days.first['small']! as Map<String, Object?>;
  return (
    firstDate: j['firstDate']! as String,
    zone: j['timeZone']! as String,
    big: small['big']! as String,
  );
}

String location(AppUnderTest app) => app.container
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .last
    .matchedLocation;

void main() {
  late FakeWidgetPublisher publisher;
  late DateTime now;
  late String zone;

  setUp(() {
    publisher = FakeWidgetPublisher();
    now = harnessNow;
    zone = 'Europe/Madrid';
  });

  List<Override> overrides() => [
    widgetPublisherProvider.overrideWithValue(publisher),
    widgetTimeZoneProvider.overrideWithValue(() async => zone),
  ];

  testWidgets('publishes at start: today first, in the device zone', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(
      tester,
      overrides: overrides(),
      clock: () => now,
    );
    expect(publisher.published, hasLength(1));
    final last = _last(publisher);
    expect(last.firstDate, '2026-10-19');
    expect(last.zone, 'Europe/Madrid');
    expect(
      WidgetSnapshotHeader.tryParse(publisher.published.last)?.version,
      kWidgetSnapshotVersion,
    );
    // The big text is the code of the shift the schedule gives for today.
    final shift = app.schedule.schedule.resolve(harnessToday).shifts.single;
    expect(last.big, shift.code);
  });

  testWidgets('the month grids follow the first day of the week', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(
      tester,
      overrides: overrides(),
      clock: () => now,
    );
    Map<String, Object?> last() =>
        jsonDecode(publisher.published.last) as Map<String, Object?>;
    expect(last()['weekdayHeaders'], ['L', 'M', 'X', 'J', 'V', 'S', 'D']);

    await app.container.read(preferencesProvider.notifier).setWeekStart(7);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(publisher.published, hasLength(2));
    expect(last()['weekdayHeaders'], ['D', 'L', 'M', 'X', 'J', 'V', 'S']);
    final firstCell =
        ((last()['months']! as List).first as Map)['cells'] as List;
    expect((firstCell.first as Map)['date'], '2026-09-27'); // a Sunday
  });

  testWidgets('resume reloads the timelines without republishing', (
    tester,
  ) async {
    await AppUnderTest.pump(tester, overrides: overrides(), clock: () => now);
    final reloads = publisher.reloadCount;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(publisher.published, hasLength(1), reason: 'nothing changed');
    expect(publisher.reloadCount, reloads + 1);
  });

  testWidgets('a resume on another day republishes with that day first', (
    tester,
  ) async {
    await AppUnderTest.pump(tester, overrides: overrides(), clock: () => now);
    now = DateTime(2026, 10, 21, 7);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(publisher.published, hasLength(2));
    expect(_last(publisher).firstDate, '2026-10-21');
  });

  testWidgets('republishes at local midnight while the app is open', (
    tester,
  ) async {
    await AppUnderTest.pump(tester, overrides: overrides(), clock: () => now);
    expect(publisher.published, hasLength(1));

    // Midday now; the clock passes midnight 12 hours later.
    now = DateTime(2026, 10, 20, 0, 0, 5);
    await tester.pump(const Duration(hours: 12, seconds: 10));
    await tester.pump();
    expect(publisher.published, hasLength(2));
    expect(_last(publisher).firstDate, '2026-10-20');
  });

  testWidgets('a date changed by hand is picked up within a minute', (
    tester,
  ) async {
    await AppUnderTest.pump(tester, overrides: overrides(), clock: () => now);
    now = DateTime(2026, 11, 3, 12);
    await tester.pump(const Duration(minutes: 1, seconds: 1));
    await tester.pump();
    expect(publisher.published, hasLength(2));
    expect(_last(publisher).firstDate, '2026-11-03');
  });

  testWidgets('a time zone change republishes with the new zone', (
    tester,
  ) async {
    await AppUnderTest.pump(tester, overrides: overrides(), clock: () => now);
    // UTC has another name and offset than the machine zone (the tests run
    // with TZ=Europe/Madrid), which is how the host notices the change.
    now = harnessNow.toUtc();
    zone = 'Atlantic/Canary';
    final reloads = publisher.reloadCount;
    await tester.pump(const Duration(minutes: 1, seconds: 1));
    await tester.pump();
    expect(publisher.published, hasLength(2));
    expect(_last(publisher).zone, 'Atlantic/Canary');
    expect(publisher.reloadCount, greaterThan(reloads));
  });

  testWidgets('the system notice of a zone change republishes at once, '
      'without waiting for the minute watch (H-T11-4)', (tester) async {
    final system = FakeAlarmSystem();
    await AppUnderTest.pump(
      tester,
      overrides: [
        ...overrides(),
        alarmSystemProvider.overrideWithValue(system),
      ],
      clock: () => now,
    );
    zone = 'Atlantic/Canary';
    expect(publisher.published, hasLength(1));
    system.emit(ClockChange.timezone);
    await tester.pump();
    await tester.pump();
    expect(publisher.published, hasLength(2));
    expect(_last(publisher).zone, 'Atlantic/Canary');
  });

  testWidgets('a schedule edit republishes after the debounce', (tester) async {
    final app = await AppUnderTest.pump(
      tester,
      overrides: overrides(),
      clock: () => now,
    );
    expect(publisher.published, hasLength(1));
    final before = publisher.published.last;

    final notifier = app.container.read(scheduleControllerProvider.notifier);
    notifier.beginStroke(const PaintTool.replace('vacation'));
    notifier.paintDay(harnessToday);
    notifier.endStroke();
    await tester.pump(const Duration(milliseconds: 500));
    expect(publisher.published, hasLength(1), reason: 'inside the debounce');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(publisher.published, hasLength(2));
    expect(publisher.published.last, isNot(before));
    expect(_last(publisher).big, 'V');
    await app.real(() => notifier.pendingWrites);
  });

  group('primary calendar', () {
    late String secondId;

    Future<void> prepare(AppDatabase database) async {
      final calendars = CalendarsRepository(database);
      // The second calendar has a vacation today; it is the one on screen,
      // the first (main) stays the primary one.
      secondId = await addSecondCalendar(database);
      await calendars.setActive(secondId);
    }

    testWidgets('publishes the primary calendar, not the one on screen', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        overrides: overrides(),
        clock: () => now,
        prepare: prepare,
      );
      // On screen: the second calendar, with the vacation day.
      expect(app.schedule.schedule.resolve(harnessToday).shiftIds, [
        'vacation',
      ]);
      final mainShift = (await app.real(
        () async => CalendarsRepository(app.database).primaryId(),
      ));
      expect(mainShift, isNot(secondId));
      // The widget got the main calendar's shift for today, not the vacation.
      expect(_last(publisher).big, isNot('V'));
      expect(_last(publisher).big, isNotEmpty);
    });

    testWidgets('making another calendar primary republishes', (tester) async {
      final app = await AppUnderTest.pump(
        tester,
        overrides: overrides(),
        clock: () => now,
        prepare: prepare,
      );
      final before = _last(publisher).big;
      expect(publisher.published, hasLength(1));
      // Let the calendars list load, then change the primary calendar (inside
      // fake time, so the debounce timer is the test's).
      await tester.pump();
      await app.container
          .read(calendarsControllerProvider.notifier)
          .setPrimary(secondId);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(publisher.published, hasLength(2));
      expect(before, isNot('V'));
      expect(_last(publisher).big, 'V');
    });
  });

  group('taps on the widget', () {
    testWidgets('a day link opens that day', (tester) async {
      final app = await AppUnderTest.pump(
        tester,
        overrides: overrides(),
        clock: () => now,
      );
      const day = CivilDate(2026, 11, 4);
      publisher.tapsController.add(widgetDayLink(day));
      await tester.pumpAndSettle();
      expect(app.container.read(visibleMonthProvider), day.firstDayOfMonth);
      expect(find.byType(DayDetailSheet), findsOneWidget);
    });

    testWidgets('a month link shows that month and opens no day sheet', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        overrides: overrides(),
        clock: () => now,
      );
      await app.openSettings();
      publisher.tapsController.add(
        widgetMonthLink(const CivilDate(2026, 12, 1)),
      );
      await tester.pumpAndSettle();
      expect(location(app), AppRoutes.home);
      expect(
        app.container.read(visibleMonthProvider),
        const CivilDate(2026, 12, 1),
      );
      expect(find.byType(DayDetailSheet), findsNothing);
    });

    testWidgets('the link that started the app opens its day', (tester) async {
      publisher.launchUri = widgetDayLink(const CivilDate(2026, 10, 21));
      await AppUnderTest.pump(tester, overrides: overrides(), clock: () => now);
      await tester.pumpAndSettle();
      expect(find.byType(DayDetailSheet), findsOneWidget);
    });

    testWidgets('a tap while on Ajustes opens the day over the calendar', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        overrides: overrides(),
        clock: () => now,
      );
      await app.openSettings();
      expect(find.text('Ajustes'), findsWidgets);
      publisher.tapsController.add(widgetDayLink(const CivilDate(2026, 11, 4)));
      await tester.pumpAndSettle();
      expect(location(app), AppRoutes.home);
      expect(find.byType(DayDetailSheet), findsOneWidget);
    });

    testWidgets('a second tap replaces the open sheet, never stacks', (
      tester,
    ) async {
      await AppUnderTest.pump(tester, overrides: overrides(), clock: () => now);
      publisher.tapsController.add(widgetDayLink(const CivilDate(2026, 11, 4)));
      await tester.pumpAndSettle();
      expect(find.byType(DayDetailSheet), findsOneWidget);

      publisher.tapsController.add(widgetDayLink(const CivilDate(2026, 11, 5)));
      await tester.pumpAndSettle();
      final sheet = tester.widget<DayDetailSheet>(find.byType(DayDetailSheet));
      expect(find.byType(DayDetailSheet), findsOneWidget);
      expect(sheet.date, const CivilDate(2026, 11, 5));
    });

    testWidgets('a tap during the restore preview does nothing', (
      tester,
    ) async {
      final harness = BackupUiHarness(tester);
      harness.channel.incoming = IncomingFile.bytes(
        BackupUiHarness.fileOf(buildGoldenBackupDataV2()),
      );
      final app = await AppUnderTest.pump(
        tester,
        overrides: [...overrides(), ...harness.overrides],
        clock: () => now,
        expectMonth: false,
      );
      await pumpIo(
        tester,
        until: find.byKey(const ValueKey('restore-preview')),
      );
      publisher.tapsController.add(widgetDayLink(const CivilDate(2026, 11, 4)));
      await tester.pumpAndSettle();
      expect(find.byType(DayDetailSheet), findsNothing);
      expect(location(app), AppRoutes.settingsBackupImport);
      expect(find.byKey(const ValueKey('restore-preview')), findsOneWidget);
    });

    testWidgets('a tap while a restore is replacing the data does nothing', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        overrides: overrides(),
        clock: () => now,
      );
      await app.openSettings();
      app.container.read(restoreInProgressProvider.notifier).set(true);
      publisher.tapsController.add(widgetDayLink(const CivilDate(2026, 11, 4)));
      await tester.pumpAndSettle();
      expect(find.byType(DayDetailSheet), findsNothing);
      expect(location(app), AppRoutes.settings);
    });

    testWidgets('links that are not ours do nothing', (tester) async {
      await AppUnderTest.pump(tester, overrides: overrides(), clock: () => now);
      publisher.tapsController.add(Uri.parse('https://example.com/day/1'));
      await tester.pumpAndSettle();
      expect(find.byType(DayDetailSheet), findsNothing);
    });
  });
}
