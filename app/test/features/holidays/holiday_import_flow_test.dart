import 'dart:async';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendar_export/domain/device_calendar_api.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/holidays/presentation/holiday_import_screen.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_device_calendar.dart';
import 'holiday_import_ui_support.dart';

class _DelayedCalendar extends FakeDeviceCalendar {
  final result = Completer<List<DeviceEvent>>();

  @override
  Future<List<DeviceEvent>> events(
    DateTime start,
    DateTime end, {
    List<String>? calendarIds,
  }) => result.future;
}

void _allDay(
  FakeDeviceCalendar phone,
  String calendar,
  String name,
  int day, {
  int year = 2026,
  int month = 10,
  int days = 1,
}) {
  phone.addSimpleEvent(
    calendar,
    name,
    DateTime(year, month, day),
    DateTime(year, month, day + days),
    allDay: true,
  );
}

void main() {
  setUpAll(initializeLocale);

  testWidgets('opening explains access without asking; an empty selection '
      'cannot read; hidden calendars are omitted and read-only ones work', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final visible = phone.addCalendar('Festivos', readOnly: true);
    final hidden = phone.addCalendar('Oculto', hidden: true);
    await openHolidayImport(tester, phone);
    expect(phone.requests, 0);
    expect(phone.eventListings, 0);
    expect(importNextEnabled(tester), isFalse);
    expect(importKey('holiday-import-calendar-$visible'), findsOneWidget);
    expect(importKey('holiday-import-calendar-$hidden'), findsNothing);
    await importTap(tester, 'holiday-import-calendar-$visible');
    expect(importNextEnabled(tester), isTrue);
    await importTap(tester, 'holiday-import-calendar-$visible');
    expect(importNextEnabled(tester), isFalse);
    await importTap(tester, 'holiday-import-back');
    expect(phone.createdEvents, 0);
    expect(phone.deletedEvents, 0);
  });

  testWidgets('only selected calendars and all-day events reach the preview; '
      'the range spans the clock year and the next', (tester) async {
    final phone = FakeDeviceCalendar();
    final first = phone.addCalendar('Locales', readOnly: true);
    final second = phone.addCalendar('Empresa');
    final other = phone.addCalendar('Personal');
    _allDay(phone, first, 'Fiesta de enero', 2, month: 1);
    _allDay(phone, second, 'Fiesta de diciembre', 30, year: 2027, month: 12);
    _allDay(phone, other, 'Calendario sin seleccionar', 20);
    _allDay(phone, first, 'Año fuera de rango', 20, year: 2028);
    phone.addSimpleEvent(
      first,
      'Cita con hora',
      DateTime(2026, 10, 22, 9),
      DateTime(2026, 10, 22, 10),
    );
    final app = await openHolidayImport(tester, phone);
    await holidayPreview(tester, [first, second]);
    expect(find.text('Fiesta de enero'), findsOneWidget);
    expect(find.text('Fiesta de diciembre'), findsOneWidget);
    expect(find.text('Calendario sin seleccionar'), findsNothing);
    expect(find.text('Año fuera de rango'), findsNothing);
    expect(find.text('Cita con hora'), findsNothing);
    expect(
      tester.widget<Text>(importKey('holiday-import-ignored')).data,
      contains('1'),
    );
    expect(await importedRows(app), isEmpty, reason: 'preview writes nothing');
    await importTap(tester, 'holiday-import-back');
    await importTap(tester, 'holiday-import-back');
    expect(
      tester
          .widget<CheckboxListTile>(importKey('holiday-import-calendar-$first'))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            importKey('holiday-import-calendar-$second'),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<CheckboxListTile>(importKey('holiday-import-calendar-$other'))
          .value,
      isFalse,
    );
  });

  testWidgets('preview keeps existing official and personal holidays; apply '
      'persists only new days and repeated imports cannot duplicate them', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Festivos');
    _allDay(phone, id, 'No sustituir el oficial', 1, month: 1);
    _allDay(phone, id, 'No sustituir el personal', 20);
    _allDay(phone, id, 'Fiesta nueva', 21);
    final app = await openHolidayImport(
      tester,
      phone,
      prepare: (repo) => repo.addUserHoliday(
        date: const CivilDate(2026, 10, 20),
        name: 'Mi fiesta anterior',
      ),
    );
    await holidayPreview(tester, [id]);
    expect(find.text('No sustituir el oficial'), findsOneWidget);
    expect(find.text('No sustituir el personal'), findsOneWidget);
    expect(find.byKey(const ValueKey('holiday-import-row-2')), findsOneWidget);
    expect((await importedRows(app)).single.name, 'Mi fiesta anterior');
    await importTap(tester, 'holiday-import-next');
    expect(find.byType(HolidayImportScreen), findsNothing);
    final rows = await importedRows(app);
    expect(rows.map((e) => e.name), ['Mi fiesta anterior', 'Fiesta nueva']);
    expect(
      app.container
          .read(holidaysProvider)[const CivilDate(2026, 1, 1)]
          ?.isUserAdded,
      isFalse,
    );
    expect(find.byType(SnackBarAction), findsOneWidget);

    await importTap(tester, 'holidays-import');
    await holidayPreview(tester, [id]);
    expect(importNextEnabled(tester), isFalse);
    expect(await importedRows(app), hasLength(2));
    expect(phone.createdEvents, 0);
    expect(phone.deletedEvents, 0);
    expect(phone.createdCalendars, 0);
  });

  testWidgets('undo removes only this run and preserves later edits', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Festivos');
    _allDay(phone, id, 'Fiesta importada', 21);
    _allDay(phone, id, 'Fiesta para editar', 22);
    final app = await openHolidayImport(
      tester,
      phone,
      prepare: (repo) => repo.addUserHoliday(
        date: const CivilDate(2026, 10, 20),
        name: 'Anterior',
      ),
    );
    await holidayPreview(tester, [id]);
    await importTap(tester, 'holiday-import-next');
    await app.real(
      () => app.container
          .read(holidayControllerProvider.notifier)
          .addUserHoliday(date: const CivilDate(2026, 10, 22), name: 'Editada'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle();
    expect((await importedRows(app)).map((e) => e.name), [
      'Anterior',
      'Editada',
    ]);
  });

  testWidgets('long names are clipped to 60 and a long event to 31 days', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Festivos');
    _allDay(phone, id, 'a' * 80, 20);
    _allDay(phone, id, 'Celebración larga', 1, month: 2, days: 45);
    final app = await openHolidayImport(tester, phone);
    await holidayPreview(tester, [id]);
    await importTap(tester, 'holiday-import-next');
    final rows = await importedRows(app);
    expect(rows.where((e) => e.name == 'Celebración larga'), hasLength(31));
    expect(
      rows.singleWhere((e) => e.date == const CivilDate(2026, 10, 20)).name,
      'a' * 60,
    );
  });

  testWidgets('canceling the preview leaves the database untouched', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Festivos');
    _allDay(phone, id, 'Fiesta', 21);
    final app = await openHolidayImport(tester, phone);
    await holidayPreview(tester, [id]);
    for (var i = 0; i < 3; i++) {
      await importTap(tester, 'holiday-import-back');
    }
    expect(find.byType(HolidayImportScreen), findsNothing);
    expect(await importedRows(app), isEmpty);
  });

  testWidgets('first Android refusal remains requestable; second is blocked '
      'and settings plus recheck restores access', (tester) async {
    final phone = FakeDeviceCalendar(
      access: CalendarAccess.notDetermined,
      onRequest: CalendarAccess.denied,
      retryableDenials: 1,
    );
    phone.addCalendar('Festivos');
    await openHolidayImport(tester, phone);
    expect(phone.requests, 0);
    expect(phone.calendarListings, 0);
    await importTap(tester, 'calendar-permission-allow');
    expect(importKey('calendar-permission-allow'), findsOneWidget);
    expect(importKey('calendar-permission-settings'), findsNothing);
    expect(find.textContaining('No has dado el permiso'), findsOneWidget);
    await importTap(tester, 'calendar-permission-allow');
    expect(phone.requests, 2);
    expect(importKey('calendar-permission-denied'), findsOneWidget);
    await importTap(tester, 'calendar-permission-settings');
    expect(phone.settingsOpened, 1);
    phone.setAccess(CalendarAccess.granted);
    await importTap(tester, 'calendar-permission-recheck');
    expect(importKey('holiday-import-calendar-cal-1'), findsOneWidget);
  });

  testWidgets('iOS refusal is definitive after the first request', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar(
      access: CalendarAccess.notDetermined,
      onRequest: CalendarAccess.denied,
    );
    await openHolidayImport(tester, phone);
    await importTap(tester, 'calendar-permission-allow');
    expect(importKey('calendar-permission-denied'), findsOneWidget);
    expect(importKey('calendar-permission-allow'), findsNothing);
    expect(phone.requests, 1);
  });

  testWidgets('write-only access asks for full access', (tester) async {
    final phone = FakeDeviceCalendar(access: CalendarAccess.writeOnly);
    phone.addCalendar('Festivos');
    await openHolidayImport(tester, phone);
    expect(importKey('calendar-permission-write-only'), findsOneWidget);
    await importTap(tester, 'calendar-permission-allow');
    expect(importKey('holiday-import-calendar-cal-1'), findsOneWidget);
    expect(phone.requests, 1);
  });

  testWidgets('restricted access has no request button', (tester) async {
    final phone = FakeDeviceCalendar(access: CalendarAccess.restricted);
    await openHolidayImport(tester, phone);
    expect(importKey('calendar-permission-restricted'), findsOneWidget);
    expect(importKey('calendar-permission-allow'), findsNothing);
    expect(phone.requests, 0);
    expect(importNextEnabled(tester), isFalse);
  });

  testWidgets('a failed read stays on range and can be retried', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Festivos');
    _allDay(phone, id, 'Fiesta', 21);
    await openHolidayImport(tester, phone);
    await importTap(tester, 'holiday-import-calendar-$id');
    await importTap(tester, 'holiday-import-next');
    phone.failNext = CalendarApiError.failed;
    await importTap(tester, 'holiday-import-next');
    expect(importKey('holiday-import-step-1'), findsOneWidget);
    expect(
      find.text('No se han podido leer los eventos. Prueba otra vez.'),
      findsOneWidget,
    );
    await importTap(tester, 'holiday-import-next');
    expect(importKey('holiday-import-step-2'), findsOneWidget);
    expect(find.text('Fiesta'), findsOneWidget);
  });

  testWidgets('a revoked permission returns to the permission flow', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Festivos');
    await openHolidayImport(tester, phone);
    await importTap(tester, 'holiday-import-calendar-$id');
    await importTap(tester, 'holiday-import-next');
    phone.setAccess(CalendarAccess.denied);
    await importTap(tester, 'holiday-import-next');
    expect(importKey('holiday-import-step-0'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(importKey('calendar-permission-denied'), findsOneWidget);
    expect(importNextEnabled(tester), isFalse);
  });

  testWidgets('late device read completion after disposal is ignored', (
    tester,
  ) async {
    final phone = _DelayedCalendar();
    final id = phone.addCalendar('Festivos');
    await openHolidayImport(tester, phone);
    await importTap(tester, 'holiday-import-calendar-$id');
    await importTap(tester, 'holiday-import-next');
    await tester.tap(importKey('holiday-import-next'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    phone.result.complete(const []);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
