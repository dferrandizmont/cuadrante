import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar_export/application/export_controller.dart';
import 'package:cuadrante/features/calendar_export/domain/device_calendar_api.dart';
import 'package:cuadrante/features/calendar_export/domain/export_events.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';
import '../import/import_ui_support.dart';

Future<AppUnderTest> openExport(
  WidgetTester tester,
  FakeDeviceCalendar phone,
) async {
  final app = await AppUnderTest.pump(
    tester,
    size: importTestSize,
    overrides: importOverrides(phone: phone, picker: FakePicker()),
  );
  await app.openSettings();
  await tester.tap(byKey('settings-export-calendar'));
  await tester.pumpAndSettle();
  return app;
}

ExportState stateOf(AppUnderTest app) =>
    app.container.read(exportControllerProvider);

void main() {
  setUpAll(initializeLocale);

  testWidgets('opens on the calendars, with «Turnly» to be created', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    phone.addCalendar('Personal', account: 'yo@example.com');
    phone.addCalendar('Festivos', readOnly: true);
    await openExport(tester, phone);
    // The title is short (it did not fit a 320 dp phone, H-T14-2); the row of
    // Ajustes keeps the long name.
    expect(find.text('Exportar turnos'), findsOneWidget);
    expect(
      find.text('Se exportan los turnos de «Mi cuadrante».'),
      findsOneWidget,
    );
    expect(byKey('export-calendar-new'), findsOneWidget);
    expect(find.text('Crear el calendario «Turnly»'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('yo@example.com'), findsOneWidget);
    expect(find.text('Festivos'), findsNothing, reason: 'read-only');
    // Next three months from today (19 Oct 2026).
    expect(find.text('19 oct 2026'), findsOneWidget);
    expect(find.text('18 ene 2027'), findsOneWidget);
    expect(phone.requests, 0);
  });

  testWidgets('an existing «Turnly» is chosen by default', (tester) async {
    final phone = FakeDeviceCalendar();
    phone.addCalendar('Cuadrante');
    final id = phone.addCalendar('Turnly');
    phone.addCalendar('Personal');
    final app = await openExport(tester, phone);
    expect(stateOf(app).targetId, id);
  });

  testWidgets('the «Cuadrante» calendar from before the rename is still found', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Cuadrante');
    phone.addCalendar('Personal');
    final app = await openExport(tester, phone);
    expect(stateOf(app).targetId, id);
  });

  testWidgets('exports, then a second export changes nothing', (tester) async {
    final phone = FakeDeviceCalendar();
    final app = await openExport(tester, phone);

    final planned = stateOf(app).plan!;
    expect(planned.toCreate, isNotEmpty);
    expect(planned.toDelete, isEmpty);
    await tapKey(tester, 'export-start');

    expect(phone.createdCalendars, 1);
    final id = phone.allCalendars.single.id;
    final first = phone.eventsOf(id).length;
    expect(first, planned.toCreate.length);
    expect(first, greaterThan(0));
    expect(byKey('export-result'), findsOneWidget);
    expect(find.text('Exportación hecha'), findsOneWidget);
    expect(
      find.text('Se ha creado el calendario «Turnly».'),
      findsOneWidget,
    );
    expect(
      find.text(first == 1 ? '1 evento añadido' : '$first eventos añadidos'),
      findsOneWidget,
    );
    // Every event carries the tag of this calendar.
    for (final e in phone.eventsOf(id)) {
      expect(ExportTag.parse(e.description)?.calendarId, 'main');
    }

    // The same calendar is now the target, and there is nothing to do.
    expect(stateOf(app).targetId, id);
    expect(
      find.text('Todo está al día: no hay nada que cambiar.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: byKey('export-start'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('a re-export after a change replaces, never duplicates', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final app = await openExport(tester, phone);
    await tapKey(tester, 'export-start');
    final id = phone.allCalendars.single.id;
    final first = phone.eventsOf(id).length;

    // The day after tomorrow becomes a Vacaciones (no hours: all-day). It is
    // an absence, so it only goes to the calendar when the user asks.
    final day = const CivilDate(2026, 10, 21);
    app.container.read(scheduleControllerProvider.notifier).setDayShifts(
      day,
      const ['vacation'],
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'export-include-absences-switch');
    expect(stateOf(app).includeAbsences, isTrue);
    expect(stateOf(app).plan!.toDelete, isNotEmpty);
    await tapKey(tester, 'export-start');

    final events = phone.eventsOf(id);
    // The old copy of that day is gone, the new one is there once.
    final onDay = [
      for (final e in events)
        if (ExportTag.parse(e.description)?.date == day) e,
    ];
    expect(onDay, hasLength(1));
    expect(onDay.single.title, 'Vacaciones · V');
    expect(onDay.single.allDay, isTrue);
    expect(events.length, lessThanOrEqualTo(first + 1));
    final tags = events.map((e) => e.description).toList();
    expect(tags.toSet().length, tags.length, reason: 'no duplicated tags');
    expect(find.textContaining('sustituido'), findsOneWidget);
  });

  testWidgets('the days off can be included and the count follows', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final app = await openExport(tester, phone);
    final without = stateOf(app).plan!.toCreate.length;
    await tapKey(tester, 'export-include-rest-switch');
    expect(stateOf(app).includeRest, isTrue);
    expect(stateOf(app).plan!.toCreate.length, greaterThan(without));
  });

  testWidgets('the range can be changed and is cut to a year', (tester) async {
    final phone = FakeDeviceCalendar();
    final app = await openExport(tester, phone);
    app.container
        .read(exportControllerProvider.notifier)
        .setRange(const CivilDate(2026, 10, 19), const CivilDate(2029, 1, 1));
    await tester.pumpAndSettle();
    expect(
      stateOf(app).to.differenceInDays(stateOf(app).from) + 1,
      maxExportDays,
    );
    expect(byKey('export-clamped'), findsOneWidget);
    // A reversed range is ignored.
    app.container
        .read(exportControllerProvider.notifier)
        .setRange(const CivilDate(2027, 1, 1), const CivilDate(2026, 1, 1));
    expect(stateOf(app).from, const CivilDate(2026, 10, 19));
  });

  testWidgets('exporting into an existing calendar', (tester) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Personal');
    phone.addSimpleEvent(
      id,
      'Dentista',
      DateTime(2026, 10, 20, 9),
      DateTime(2026, 10, 20, 10),
    );
    await openExport(tester, phone);
    await tapKey(tester, 'export-calendar-$id');
    await tapKey(tester, 'export-start');
    expect(phone.createdCalendars, 0);
    expect(
      phone.eventsOf(id).where((e) => e.title == 'Dentista'),
      hasLength(1),
    );
    expect(phone.eventsOf(id).length, greaterThan(1));
  });

  testWidgets('events that fail to be written are reported', (tester) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Personal');
    phone.failCreatingTitles.add('Noche · N');
    await openExport(tester, phone);
    await tapKey(tester, 'export-calendar-$id');
    await tapKey(tester, 'export-start');
    expect(byKey('export-result-failed'), findsOneWidget);
    expect(find.textContaining('Vuelve a exportar'), findsOneWidget);
  });

  testWidgets('fits a narrow phone with large text, light and dark', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final phone = FakeDeviceCalendar();
      phone.addCalendar(
        'Personal con un nombre muy largo',
        account: 'una.cuenta.larga@example.com',
      );
      final app = await AppUnderTest.pump(
        tester,
        size: const Size(320, 1800),
        platformBrightness: brightness,
        overrides: importOverrides(phone: phone, picker: FakePicker()),
      );
      await app.openSettings();
      await tapKey(tester, 'settings-export-calendar');
      expect(tester.takeException(), isNull, reason: 'options');
      await tapKey(tester, 'export-start');
      expect(tester.takeException(), isNull, reason: 'result');
      expect(byKey('export-result'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  group('permission', () {
    testWidgets('never asked: says why, asks only on the button', (
      tester,
    ) async {
      final phone = FakeDeviceCalendar(access: CalendarAccess.notDetermined);
      await openExport(tester, phone);
      expect(byKey('calendar-permission-needed'), findsOneWidget);
      expect(find.textContaining('solo cuando tú exportas'), findsOneWidget);
      expect(phone.requests, 0);
      expect(byKey('export-calendar-new'), findsNothing);
      await tapKey(tester, 'calendar-permission-allow');
      expect(phone.requests, 1);
      expect(byKey('export-calendar-new'), findsOneWidget);
    });

    testWidgets('refused: the card sends to the settings', (tester) async {
      final phone = FakeDeviceCalendar(
        access: CalendarAccess.notDetermined,
        onRequest: CalendarAccess.denied,
      );
      await openExport(tester, phone);
      await tapKey(tester, 'calendar-permission-allow');
      expect(byKey('calendar-permission-denied'), findsOneWidget);
      await tapKey(tester, 'calendar-permission-settings');
      expect(phone.settingsOpened, 1);
      phone.setAccess(CalendarAccess.granted);
      await tapKey(tester, 'calendar-permission-recheck');
      expect(byKey('export-calendar-new'), findsOneWidget);
    });

    testWidgets('H-T14-6 Android: the first «No permitir» can be asked again, '
        'the second sends to the settings', (tester) async {
      final phone = FakeDeviceCalendar(
        access: CalendarAccess.notDetermined,
        onRequest: CalendarAccess.denied,
        retryableDenials: 1,
      );
      await openExport(tester, phone);
      await tapKey(tester, 'calendar-permission-allow');
      expect(phone.requests, 1);
      // Not blocked: the card still has «Permitir acceso» and says what
      // happened; no «Abrir ajustes» yet.
      expect(byKey('calendar-permission-denied'), findsNothing);
      expect(byKey('calendar-permission-needed'), findsOneWidget);
      expect(byKey('calendar-permission-allow'), findsOneWidget);
      expect(byKey('calendar-permission-settings'), findsNothing);
      expect(find.textContaining('No has dado el permiso'), findsOneWidget);

      // Asked again and refused again: now it really is blocked.
      await tapKey(tester, 'calendar-permission-allow');
      expect(phone.requests, 2);
      expect(byKey('calendar-permission-denied'), findsOneWidget);
      expect(byKey('calendar-permission-allow'), findsNothing);
      expect(byKey('calendar-permission-settings'), findsOneWidget);
    });

    testWidgets('H-T14-6 Android: allowing the second time works', (
      tester,
    ) async {
      final phone = FakeDeviceCalendar(
        access: CalendarAccess.notDetermined,
        onRequest: CalendarAccess.denied,
        retryableDenials: 1,
      );
      await openExport(tester, phone);
      await tapKey(tester, 'calendar-permission-allow');
      phone.setAccess(CalendarAccess.granted);
      await tapKey(tester, 'calendar-permission-allow');
      expect(byKey('export-calendar-new'), findsOneWidget);
    });

    testWidgets('restricted and add-only are told apart', (tester) async {
      final restricted = FakeDeviceCalendar(access: CalendarAccess.restricted);
      await openExport(tester, restricted);
      expect(byKey('calendar-permission-restricted'), findsOneWidget);
      expect(byKey('calendar-permission-allow'), findsNothing);
    });

    testWidgets('add-only access cannot replace events: asks for more', (
      tester,
    ) async {
      final phone = FakeDeviceCalendar(
        access: CalendarAccess.writeOnly,
        onRequest: CalendarAccess.granted,
      );
      await openExport(tester, phone);
      expect(byKey('calendar-permission-write-only'), findsOneWidget);
      await tapKey(tester, 'calendar-permission-allow');
      expect(byKey('export-calendar-new'), findsOneWidget);
    });

    testWidgets('the permission going away while exporting is a message', (
      tester,
    ) async {
      final phone = FakeDeviceCalendar();
      await openExport(tester, phone);
      phone.setAccess(CalendarAccess.denied);
      await tapKey(tester, 'export-start');
      // The screen goes back to the permission card.
      expect(byKey('calendar-permission-denied'), findsOneWidget);
      expect(phone.createdEvents, 0);
    });
  });
}
