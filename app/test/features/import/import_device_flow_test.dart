import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/calendar_export/domain/device_calendar_api.dart';
import 'package:cuadrante/features/import/application/import_wizard.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';

import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;

import 'import_ui_support.dart';

const _nov9 = CivilDate(2026, 11, 9);
const _nov10 = CivilDate(2026, 11, 10);
const _nov14 = CivilDate(2026, 11, 14);
const _nov20 = CivilDate(2026, 11, 20);

String ids(AppUnderTest app, CivilDate d) =>
    app.schedule.schedule.resolve(d).shiftIds.join('+');

ImportWizardState wizardOf(AppUnderTest app) =>
    app.container.read(importWizardProvider);

void main() {
  setUpAll(initializeLocale);

  group('entry points', () {
    testWidgets('Ajustes has «Importar y exportar» with both rows', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        size: importTestSize,
        overrides: importOverrides(
          phone: FakeDeviceCalendar(),
          picker: FakePicker(),
        ),
      );
      await app.openSettings();
      expect(find.text('IMPORTAR Y EXPORTAR'), findsOneWidget);
      expect(byKey('settings-import'), findsOneWidget);
      expect(byKey('settings-export-calendar'), findsOneWidget);
      expect(find.text('Importar turnos'), findsOneWidget);
      expect(find.text('Exportar turnos'), findsOneWidget);
    });

    testWidgets('the import opens on the choice of source', (tester) async {
      await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: FakePicker(),
      );
      expect(find.text('¿De dónde vienen tus turnos?'), findsOneWidget);
      expect(byKey('import-source-device'), findsOneWidget);
      expect(byKey('import-source-ics'), findsOneWidget);
      expect(byKey('import-source-csv'), findsOneWidget);
      expect(byKey('import-source-lrhsoft'), findsOneWidget);
      expect(find.text('¿Vienes de LRHSoft o Supershift?'), findsOneWidget);
      // No permission asked just by opening it.
      expect(find.byKey(const ValueKey('import-next')), findsNothing);
    });
  });

  group('phone calendar', () {
    testWidgets(
      'calendars, dates, titles and preview end in ONE undoable import',
      (tester) async {
        final phone = phoneWithShifts();
        final app = await openImport(
          tester,
          phone: phone,
          picker: FakePicker(),
        );
        final before = app.schedule.schedule;

        // Step 1 -> 2: the permission is already granted: the calendars show
        // with their account; hidden ones do not.
        await tapKey(tester, 'import-source-device');
        expect(phone.requests, 0, reason: 'nothing was asked');
        expect(stepOf(tester), 'Paso 2 de 5');
        expect(find.text('Elige los calendarios'), findsOneWidget);
        expect(find.text('Turnos'), findsOneWidget);
        expect(find.text('yo@example.com'), findsOneWidget);
        expect(find.text('yo@example.com · Solo lectura'), findsOneWidget);
        expect(find.text('Oculto'), findsNothing);
        // Next waits for a calendar.
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await tester.tap(byKey('import-calendar-cal-1'));
        await tester.pumpAndSettle();

        // Step 3: the range, last 12 months and next 6 by default.
        final calendarId = phone.allCalendars.first.id;
        expect(wizardOf(app).selectedCalendars, {calendarId});
        expect(calendarId, 'cal-1');
        await tapKey(tester, 'import-next');
        expect(stepOf(tester), 'Paso 3 de 5');
        expect(find.text('¿De qué fechas?'), findsOneWidget);
        expect(find.text('19 oct 2025'), findsOneWidget);
        expect(find.text('18 abr 2027'), findsOneWidget);

        // Step 4: titles grouped; the two that match a type are suggested.
        await tapKey(tester, 'import-next');
        expect(stepOf(tester), 'Paso 4 de 5');
        expect(
          find.text('¿A qué turno corresponde cada título?'),
          findsOneWidget,
        );
        expect(
          find.textContaining('9 días en 4 títulos'),
          findsOneWidget,
          reason: 'the event of 2030 is out of range',
        );
        expect(byKey('import-group-manana'), findsOneWidget);
        expect(byKey('import-group-libre'), findsOneWidget);
        expect(byKey('import-group-refuerzo'), findsOneWidget);
        expect(byKey('import-group-cita medico'), findsOneWidget);
        expect(byKey('import-suggested-manana'), findsOneWidget);
        expect(byKey('import-suggested-libre'), findsOneWidget);
        expect(byKey('import-suggested-refuerzo'), findsNothing);
        final mapping = wizardOf(app).mappings;
        expect(mapping['manana'].toString(), contains('MapToType'));

        // Step 5: the preview and the conflicts.
        await tapKey(tester, 'import-next');
        expect(stepOf(tester), 'Paso 5 de 5');
        expect(find.text('Así quedará'), findsOneWidget);
        expect(find.text('Se importa en «Mi cuadrante».'), findsOneWidget);
        expect(find.text('Se escribirá 1 día.'), findsNothing);
        // Mañana over two nights is a conflict; Libre equals the rotation.
        expect(find.text('2 días ya tienen turno'), findsOneWidget);
        expect(find.text('2 días ya estaban igual.'), findsOneWidget);
        expect(byKey('import-conflict-replace'), findsOneWidget);
        expect(byKey('import-conflict-keep'), findsOneWidget);
        expect(find.text('Se escribirán 2 días.'), findsOneWidget);
        expect(byKey('import-preview-2026-11-09'), findsOneWidget);

        // Apply: ONE step.
        await tapKey(tester, 'import-apply');
        expect(ids(app, _nov9), 'morning');
        expect(ids(app, _nov10), 'morning');
        expect(ids(app, _nov14), 'rest');
        expect(find.text('Se han importado 2 días.'), findsOneWidget);
        expect(app.schedule.canUndo, isTrue);
        // H-T14-7: it lands on the calendar, on the first month imported
        // (the demo month is October), not back on Ajustes.
        expect(
          app.container.read(routerProvider).state.uri.path,
          AppRoutes.home,
        );
        expect(
          app.container.read(visibleMonthProvider),
          const CivilDate(2026, 11, 1),
        );
        expect(byKey('import-step-of'), findsNothing);
        expect(byKey('settings-import'), findsNothing);
        expect(find.text('Deshacer'), findsOneWidget);
        await flush(app);

        // The snack bar undoes everything in one go.
        await tester.tap(find.text('Deshacer'));
        await tester.pumpAndSettle();
        expect(app.schedule.schedule.entries, before.entries);
        expect(app.schedule.canUndo, isFalse, reason: 'a single step');
        await flush(app);
      },
    );

    testWidgets('«Mantener lo mío» keeps the busy days', (tester) async {
      final app = await openImport(
        tester,
        phone: phoneWithShifts(),
        picker: FakePicker(),
      );
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-next');

      await tapKey(tester, 'import-conflict-keep');
      expect(find.text('Se escribirán 0 días.'), findsNothing);
      expect(
        find.text('Con estas elecciones no cambia ningún día.'),
        findsOneWidget,
      );
      // Nothing to write: the button waits.
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: byKey('import-apply'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await tapKey(tester, 'import-conflict-replace');
      expect(find.text('Se escribirán 2 días.'), findsOneWidget);
      expect(ids(app, _nov9), 'night', reason: 'nothing applied yet');
    });

    testWidgets('a new type is prefilled, edited and created with the import', (
      tester,
    ) async {
      final app = await openImport(
        tester,
        phone: phoneWithShifts(),
        picker: FakePicker(),
      );
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-next');

      // «Refuerzo» -> new type.
      await tapKey(tester, 'import-map-refuerzo');
      await tapKey(tester, 'import-pick-new');
      expect(find.text('Tipo de turno nuevo'), findsOneWidget);
      expect(
        tester.widget<TextField>(byKey('import-new-name')).controller!.text,
        'Refuerzo',
      );
      expect(
        tester.widget<TextField>(byKey('import-new-code')).controller!.text,
        'R',
      );
      expect(find.text('Empieza 09:00'), findsOneWidget);
      expect(find.text('Termina 17:00'), findsOneWidget);
      await tester.enterText(byKey('import-new-name'), 'Refuerzo tarde');
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-new-save');
      expect(find.text('Nuevo: Refuerzo tarde'), findsOneWidget);

      await tapKey(tester, 'import-next');
      expect(find.text('Se creará 1 tipo de turno nuevo.'), findsOneWidget);
      await tapKey(tester, 'import-apply');
      await flush(app);

      final created = app.schedule.schedule.shiftTypeById('new-1')!;
      expect(created.name, 'Refuerzo tarde');
      expect(created.code, 'R');
      expect(created.startMinute, 9 * 60);
      expect(created.endMinute, 17 * 60);
      for (var d = 20; d <= 23; d++) {
        expect(ids(app, CivilDate(2026, 11, d)), 'new-1');
      }
      expect(app.schedule.palette.map((t) => t.id), contains('new-1'));
      // Stored: the type and the days.
      final types = await app.real(
        () => app.database
            .customSelect("SELECT code FROM shift_types WHERE id = 'new-1'")
            .get(),
      );
      expect(types.single.read<String>('code'), 'R');
      final stored = await app.real(
        () => app.database
            .customSelect(
              "SELECT COUNT(*) AS n FROM day_entries WHERE shift_type_ids = '[\"new-1\"]'",
            )
            .get(),
      );
      expect(stored.single.read<int>('n'), 4);

      // One undo takes the days back (the type stays, as for any type).
      app.container.read(scheduleControllerProvider.notifier).undo();
      expect(ids(app, _nov20), isNot('new-1'));
    });

    testWidgets('a code that is taken is refused in the new type sheet', (
      tester,
    ) async {
      await openImport(tester, phone: phoneWithShifts(), picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-map-refuerzo');
      await tapKey(tester, 'import-pick-new');
      await tester.enterText(byKey('import-new-code'), 'M');
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-new-save');
      expect(find.textContaining('Este código ya lo usa'), findsOneWidget);
      expect(find.text('Tipo de turno nuevo'), findsOneWidget);
    });

    testWidgets('«Ignorar» and picking an existing shift', (tester) async {
      final app = await openImport(
        tester,
        phone: phoneWithShifts(),
        picker: FakePicker(),
      );
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-next');

      // «Refuerzo» -> Tarde (an existing type).
      await tapKey(tester, 'import-map-refuerzo');
      await tapKey(tester, 'import-pick-afternoon');
      expect(wizardOf(app).mappings['refuerzo'], isA<Object>());
      // «Mañana» -> ignore: its suggestion mark goes away.
      await tapKey(tester, 'import-map-manana');
      await tapKey(tester, 'import-pick-ignore');
      expect(byKey('import-suggested-manana'), findsNothing);

      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-apply');
      expect(ids(app, _nov20), 'afternoon');
      expect(ids(app, _nov9), 'night', reason: 'Mañana was ignored');
    });

    testWidgets('nothing chosen: Siguiente waits', (tester) async {
      final app = await openImport(
        tester,
        phone: phoneWithShifts(),
        picker: FakePicker(),
      );
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-next');
      for (final key in ['manana', 'libre']) {
        await tapKey(tester, 'import-map-$key');
        await tapKey(tester, 'import-pick-ignore');
      }
      expect(
        find.text('Elige al menos un título para importar.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(wizardOf(app).canContinueFromMapping, isFalse);
    });

    testWidgets('Atrás goes back a step and keeps the choices', (tester) async {
      final app = await openImport(
        tester,
        phone: phoneWithShifts(),
        picker: FakePicker(),
      );
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-map-manana');
      await tapKey(tester, 'import-pick-ignore');
      await tapKey(tester, 'import-back');
      expect(stepOf(tester), 'Paso 3 de 5');
      await tapKey(tester, 'import-next');
      expect(wizardOf(app).mappings['manana'].toString(), contains('Ignore'));
    });

    testWidgets('a range with no events says so and stays', (tester) async {
      final phone = FakeDeviceCalendar();
      phone.addCalendar('Vacío');
      await openImport(tester, phone: phone, picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-next');
      expect(stepOf(tester), 'Paso 3 de 5');
      expect(find.text('No hay eventos en esas fechas.'), findsOneWidget);
    });

    testWidgets('more than 5000 events: the first ones and a message', (
      tester,
    ) async {
      final phone = FakeDeviceCalendar();
      final id = phone.addCalendar('Gigante');
      for (var i = 0; i < 5100; i++) {
        phone.addSimpleEvent(
          id,
          'Mañana',
          DateTime(2026, 1, 1 + i % 300, 6),
          DateTime(2026, 1, 1 + i % 300, 14),
        );
      }
      final app = await openImport(tester, phone: phone, picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-next');
      expect(byKey('import-truncated'), findsOneWidget);
      expect(find.textContaining('Hay más de 5000 eventos'), findsOneWidget);
      expect(wizardOf(app).occurrences.length, 5000);
    });

    testWidgets('a failure reading the calendar is a message, not a crash', (
      tester,
    ) async {
      final phone = phoneWithShifts();
      await openImport(tester, phone: phone, picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      phone.failNext = CalendarApiError.failed;
      await tapKey(tester, 'import-next');
      expect(stepOf(tester), 'Paso 3 de 5');
      expect(
        find.text('No se han podido leer los eventos. Prueba otra vez.'),
        findsOneWidget,
      );
      // And it can be tried again.
      await tapKey(tester, 'import-next');
      expect(stepOf(tester), 'Paso 4 de 5');
    });

    testWidgets('the range can be changed with the date pickers', (
      tester,
    ) async {
      final app = await openImport(
        tester,
        phone: phoneWithShifts(),
        picker: FakePicker(),
      );
      await tapKey(tester, 'import-source-device');
      await tester.tap(byKey('import-calendar-cal-1'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-range-to');
      // The picker opens on the current end; pick another day of that month.
      await tester.tap(find.text('30'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(wizardOf(app).range.to, const CivilDate(2027, 4, 30));
      await tapKey(tester, 'import-range-default');
      expect(wizardOf(app).range.to, const CivilDate(2027, 4, 18));
    });
  });

  group('layout', () {
    testWidgets(
      'every step fits a narrow phone with large text, light and dark',
      (tester) async {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          tester.platformDispatcher.textScaleFactorTestValue = 1.8;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final app = await AppUnderTest.pump(
            tester,
            size: const Size(320, 1800),
            platformBrightness: brightness,
            overrides: importOverrides(
              phone: phoneWithShifts(),
              picker: FakePicker(),
            ),
          );
          await app.openSettings();
          await tapKey(tester, 'settings-import');
          expect(tester.takeException(), isNull, reason: 'source');

          await tapKey(tester, 'import-source-device');
          expect(tester.takeException(), isNull, reason: 'calendars');
          await tester.tap(byKey('import-calendar-cal-1'));
          await tester.pumpAndSettle();
          await tapKey(tester, 'import-next');
          expect(tester.takeException(), isNull, reason: 'range');
          await tapKey(tester, 'import-next');
          expect(tester.takeException(), isNull, reason: 'mapping');
          await tapKey(tester, 'import-map-refuerzo');
          expect(tester.takeException(), isNull, reason: 'pick sheet');
          await tapKey(tester, 'import-pick-new');
          expect(tester.takeException(), isNull, reason: 'new type sheet');
          await tapKey(tester, 'import-new-save');
          await tapKey(tester, 'import-next');
          expect(tester.takeException(), isNull, reason: 'preview');
          // Leave the app for the next theme.
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  });

  group('permission', () {
    testWidgets('never asked: why, and nothing happens until the button', (
      tester,
    ) async {
      final phone = phoneWithShifts();
      final fresh = FakeDeviceCalendar(
        access: CalendarAccess.notDetermined,
        calendars: phone.allCalendars,
      );
      await openImport(tester, phone: fresh, picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      expect(byKey('calendar-permission-needed'), findsOneWidget);
      expect(find.text('Falta el permiso del calendario'), findsOneWidget);
      expect(fresh.requests, 0);
      expect(fresh.calendarListings, 0);
      await tapKey(tester, 'calendar-permission-allow');
      expect(fresh.requests, 1);
      expect(find.text('Turnos'), findsOneWidget);
    });

    testWidgets('refused: how to turn it on, settings and check again', (
      tester,
    ) async {
      final phone = FakeDeviceCalendar(
        access: CalendarAccess.notDetermined,
        onRequest: CalendarAccess.denied,
      );
      phone.addCalendar('Turnos');
      await openImport(tester, phone: phone, picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      await tapKey(tester, 'calendar-permission-allow');
      expect(byKey('calendar-permission-denied'), findsOneWidget);
      expect(
        find.text('El acceso al calendario está desactivado'),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);

      await tapKey(tester, 'calendar-permission-settings');
      expect(phone.settingsOpened, 1);

      // The user grants it in the system settings and comes back.
      phone.setAccess(CalendarAccess.granted);
      await tapKey(tester, 'calendar-permission-recheck');
      expect(find.text('Turnos'), findsOneWidget);
    });

    testWidgets('H-T14-6 Android: the first «No permitir» can be asked again, '
        'the second sends to the settings', (tester) async {
      final phone = FakeDeviceCalendar(
        access: CalendarAccess.notDetermined,
        onRequest: CalendarAccess.denied,
        retryableDenials: 1,
      );
      phone.addCalendar('Turnos');
      await openImport(tester, phone: phone, picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      await tapKey(tester, 'calendar-permission-allow');
      expect(byKey('calendar-permission-denied'), findsNothing);
      expect(byKey('calendar-permission-allow'), findsOneWidget);
      expect(byKey('calendar-permission-settings'), findsNothing);
      expect(find.textContaining('No has dado el permiso'), findsOneWidget);

      await tapKey(tester, 'calendar-permission-allow');
      expect(phone.requests, 2);
      expect(byKey('calendar-permission-denied'), findsOneWidget);
      expect(byKey('calendar-permission-allow'), findsNothing);
      expect(byKey('calendar-permission-settings'), findsOneWidget);
    });

    testWidgets('restricted by the system: says so, no buttons', (
      tester,
    ) async {
      final phone = FakeDeviceCalendar(access: CalendarAccess.restricted);
      await openImport(tester, phone: phone, picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      expect(byKey('calendar-permission-restricted'), findsOneWidget);
      expect(byKey('calendar-permission-allow'), findsNothing);
      expect(phone.requests, 0);
    });

    testWidgets('add-only access (iOS 17) asks for full access again', (
      tester,
    ) async {
      final phone = FakeDeviceCalendar(
        access: CalendarAccess.writeOnly,
        onRequest: CalendarAccess.granted,
      );
      phone.addCalendar('Turnos');
      await openImport(tester, phone: phone, picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      expect(byKey('calendar-permission-write-only'), findsOneWidget);
      await tapKey(tester, 'calendar-permission-allow');
      expect(find.text('Turnos'), findsOneWidget);
    });

    testWidgets('the permission going away is a message with a retry', (
      tester,
    ) async {
      final phone = FakeDeviceCalendar();
      phone.failNext = CalendarApiError.permissionDenied;
      await openImport(tester, phone: phone, picker: FakePicker());
      await tapKey(tester, 'import-source-device');
      expect(
        find.text('Sin el permiso no podemos leer tus calendarios.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Turnos'), findsNothing, reason: 'no calendars at all');
      expect(find.text('No hay calendarios en este móvil.'), findsOneWidget);
    });
  });
}
