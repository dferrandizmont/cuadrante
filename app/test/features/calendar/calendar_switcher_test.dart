import 'dart:async';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/calendar_switcher.dart';
import 'package:cuadrante/features/calendars/application/calendars_controller.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/presentation/calendars_screen.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  setUpAll(initializeLocale);

  final pill = find.byKey(const ValueKey('calendar-switcher'));

  testWidgets('Q87: the selector appears after asynchronous calendar loading '
      'and still opens Compare', (tester) async {
    final loaded = Completer<void>();
    await AppUnderTest.pump(
      tester,
      prepare: (db) async => addSecondCalendar(db),
      overrides: [
        calendarsControllerProvider.overrideWith(
          () => _DelayedCalendarsController(loaded.future),
        ),
      ],
    );
    expect(pill, findsNothing, reason: 'settled frames do not finish disk I/O');
    loaded.complete();
    await tester.pumpAndSettle();
    expect(pill, findsOneWidget);
    await tester.tap(pill);
    await tester.pumpAndSettle();
    final compare = find.byKey(const ValueKey('calendar-switcher-compare'));
    expect(compare, findsOneWidget);
    await tester.tap(compare);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('compare-month')), findsOneWidget);
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(pill);
    await tester.pumpAndSettle();
  }

  Future<String> activeStored(AppUnderTest app) =>
      app.real(() => CalendarsRepository(app.database).activeId());

  testWidgets('with one calendar there is no pill', (tester) async {
    await AppUnderTest.pump(tester);
    expect(pill, findsNothing);
    expect(find.byType(CalendarSwitcher), findsOneWidget);
  });

  testWidgets('with two calendars the pill names the one on screen', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(
      tester,
      prepare: (db) async {
        await addSecondCalendar(db);
      },
    );
    expect(pill, findsOneWidget);
    expect(
      find.descendant(of: pill, matching: find.text('Mi cuadrante')),
      findsOneWidget,
    );
    expect(app.schedule.calendarId, 'main');
    // It sits in the date line, next to the settings button.
    expect(
      tester.getCenter(pill).dy,
      closeTo(tester.getCenter(find.byTooltip('Abrir ajustes')).dy, 1),
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('month-date'))).data,
      anyOf('Lunes, 19 de octubre', 'Lun 19 oct'),
    );
    // Touch target of at least 48 dp.
    expect(tester.getSize(pill).height, greaterThanOrEqualTo(48));
  });

  testWidgets('the sheet lists the calendars and marks the active one', (
    tester,
  ) async {
    await AppUnderTest.pump(
      tester,
      prepare: (db) async {
        await addSecondCalendar(db);
      },
    );
    await openSheet(tester);

    expect(find.text('Cambiar de calendario'), findsOneWidget);
    expect(find.byKey(const ValueKey('switch-calendar-main')), findsOneWidget);
    final other = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('switch-calendar-cal-'),
    );
    expect(other, findsOneWidget);
    expect(find.text('Gestionar calendarios'), findsOneWidget);
    // The check is on the active one only.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('switch-calendar-main')),
        matching: find.byType(Icon),
      ),
      findsOneWidget, // the check; the dot is not an Icon
    );
    expect(
      find.descendant(of: other, matching: find.byType(Icon)),
      findsNothing,
    );
  });

  testWidgets('switching shows the other calendar in the grid and the card', (
    tester,
  ) async {
    late String second;
    final app = await AppUnderTest.pump(
      tester,
      prepare: (db) async => second = await addSecondCalendar(db),
    );
    // `main`: Noche tonight.
    expect(inDayCell(harnessToday, find.text('N')), findsOneWidget);
    expect(find.text('ESTA NOCHE'), findsOneWidget);

    await openSheet(tester);
    await tester.tap(find.byKey(ValueKey('switch-calendar-$second')));
    await tester.pumpAndSettle();

    // The sheet closes and the screen follows the other calendar.
    expect(find.byType(BottomSheet), findsNothing);
    expect(app.schedule.calendarId, second);
    expect(
      find.descendant(of: pill, matching: find.text('Pareja')),
      findsOneWidget,
    );
    expect(inDayCell(harnessToday, find.text('V')), findsOneWidget);
    expect(inDayCell(harnessToday, find.text('N')), findsNothing);
    expect(find.text('ESTA NOCHE'), findsNothing);
    expect(await activeStored(app), second);
    // Days without an entry of their own are empty in the new calendar.
    final tomorrow = harnessToday.addDays(1);
    expect(
      app.schedule.schedule.resolve(tomorrow).shiftIds,
      isEmpty,
      reason: 'the other calendar has no rotation',
    );

    // And back.
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('switch-calendar-main')));
    await tester.pumpAndSettle();
    expect(app.schedule.calendarId, 'main');
    expect(inDayCell(harnessToday, find.text('N')), findsOneWidget);
    expect(find.text('ESTA NOCHE'), findsOneWidget);
    expect(await activeStored(app), 'main');
  });

  testWidgets('painting after a switch writes to that calendar only', (
    tester,
  ) async {
    late String second;
    final app = await AppUnderTest.pump(
      tester,
      prepare: (db) async => second = await addSecondCalendar(db),
    );
    final mainBefore = await app.real(
      () => ScheduleRepository(app.database).load('main'),
    );

    await openSheet(tester);
    await tester.tap(find.byKey(ValueKey('switch-calendar-$second')));
    await tester.pumpAndSettle();

    const day = CivilDate(2026, 10, 22);
    await tester.tap(find.text('Pintar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tool-afternoon')));
    await tester.pumpAndSettle();
    await tester.tap(dayCell(day));
    await tester.pumpAndSettle();
    expect(inDayCell(day, find.text('T')), findsOneWidget);
    await app.real(
      () =>
          app.container.read(scheduleControllerProvider.notifier).pendingWrites,
    );

    final secondStored = await app.real(
      () => ScheduleRepository(app.database).load(second),
    );
    final mainAfter = await app.real(
      () => ScheduleRepository(app.database).load('main'),
    );
    expect(secondStored.schedule.entries[day]?.shiftTypeIds, ['afternoon']);
    expect(mainAfter.schedule.entries, mainBefore.schedule.entries);
    expect(mainAfter.schedule.runs, mainBefore.schedule.runs);
  });

  testWidgets('"Gestionar calendarios" opens the calendars screen', (
    tester,
  ) async {
    await AppUnderTest.pump(
      tester,
      prepare: (db) async {
        await addSecondCalendar(db);
      },
    );
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('calendar-switcher-manage')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarsScreen), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('creating the second calendar makes the pill appear', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(tester);
    expect(pill, findsNothing);
    await app.openCalendars();
    await tester.tap(find.byKey(const ValueKey('calendars-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('calendar-name-field')),
      'Pareja',
    );
    await tester.tap(find.byKey(const ValueKey('calendar-save')));
    await tester.pumpAndSettle();
    await app.back();
    await app.back();
    expect(pill, findsOneWidget);
    expect(
      find.descendant(of: pill, matching: find.text('Pareja')),
      findsNothing,
      reason: 'creating a calendar does not switch to it',
    );
    expect(
      find.descendant(of: pill, matching: find.text('Mi cuadrante')),
      findsOneWidget,
    );
  });

  testWidgets('archiving down to one calendar hides the pill again', (
    tester,
  ) async {
    late String second;
    final app = await AppUnderTest.pump(
      tester,
      prepare: (db) async => second = await addSecondCalendar(db),
    );
    expect(pill, findsOneWidget);
    await app.real(
      () => app.container
          .read(calendarsControllerProvider.notifier)
          .archive(second),
    );
    await tester.pumpAndSettle();
    expect(pill, findsNothing);
  });

  testWidgets('a long name is cut, also with large text on a narrow phone', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await AppUnderTest.pump(
      tester,
      size: const Size(320, 700),
      prepare: (db) async {
        await addSecondCalendar(
          db,
          name: 'Segundo trabajo en el hospital comarcal',
        );
        final calendars = CalendarsRepository(db);
        await calendars.rename(
          'main',
          'Mi cuadrante del turno de noche en urgencias',
        );
      },
    );
    expect(pill, findsOneWidget);
    expect(
      tester.getSize(pill).width,
      lessThanOrEqualTo(CalendarSwitcher.maxWidth),
    );
    expect(tester.takeException(), isNull);
    await openSheet(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme and light both draw the pill without errors', (
    tester,
  ) async {
    await AppUnderTest.pump(
      tester,
      platformBrightness: Brightness.dark,
      prepare: (db) async {
        await addSecondCalendar(db);
      },
    );
    expect(pill, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DelayedCalendarsController extends CalendarsController {
  _DelayedCalendarsController(this.loaded);
  final Future<void> loaded;

  @override
  Future<CalendarsState> build() async {
    await loaded;
    return super.build();
  }
}
