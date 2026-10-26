import 'dart:async';
import 'dart:typed_data';

import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/import/application/import_wizard.dart';
import 'package:cuadrante/features/import/data/import_file_picker.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';
import 'import_ui_support.dart';

/// Weekly «Mañana» on Mondays and Tuesdays (six times from 9 Nov), «Libre»
/// all day on 14-16 Nov and one «Noche» at 21:00Z (22:00 in Madrid).
const _ics = '''BEGIN:VCALENDAR\r
VERSION:2.0\r
PRODID:-//prueba//ES\r
BEGIN:VEVENT\r
UID:semanal\r
DTSTART;TZID=Europe/Madrid:20261109T060000\r
DTEND;TZID=Europe/Madrid:20261109T140000\r
RRULE:FREQ=WEEKLY;BYDAY=MO,TU;COUNT=6\r
SUMMARY:Mañana\r
BEGIN:VALARM\r
ACTION:DISPLAY\r
SUMMARY:No soy un turno\r
TRIGGER:-PT1H\r
END:VALARM\r
END:VEVENT\r
BEGIN:VEVENT\r
UID:libre\r
DTSTART;VALUE=DATE:20261114\r
DTEND;VALUE=DATE:20261117\r
SUMMARY:Libre\r
END:VEVENT\r
BEGIN:VEVENT\r
UID:noche\r
DTSTART:20261120T210000Z\r
DTEND:20261121T050000Z\r
SUMMARY:Noche\r
END:VEVENT\r
BEGIN:VTODO\r
UID:tarea\r
DTSTART;VALUE=DATE:20261101\r
SUMMARY:Una tarea\r
END:VTODO\r
END:VCALENDAR\r
''';

const _csv = '''Fecha;Turno;Inicio;Fin
09/11/2026;Mañana;06:00;14:00
10/11/2026;Mañana;06:00;14:00
11/11/2026;Tarde;14:00;22:00
mal;Tarde;14:00;22:00
12/11/2026;;;
14/11/2026;Libre;;
''';

const _nov9 = CivilDate(2026, 11, 9);
const _nov14 = CivilDate(2026, 11, 14);
const _nov20 = CivilDate(2026, 11, 20);

String ids(AppUnderTest app, CivilDate d) =>
    app.schedule.schedule.resolve(d).shiftIds.join('+');

ImportWizardState wizardOf(AppUnderTest app) =>
    app.container.read(importWizardProvider);

void main() {
  setUpAll(initializeLocale);

  group('.ics', () {
    testWidgets('picks the file, expands the series and imports', (
      tester,
    ) async {
      final picker = FakePicker()..next = fileOf('turnos.ics', _ics);
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );

      await tapKey(tester, 'import-source-ics');
      expect(picker.asked, [ImportFileKind.ics]);
      expect(stepOf(tester), 'Paso 2 de 4');
      expect(find.text('Archivo: turnos.ics'), findsOneWidget);
      expect(find.text('El archivo trae 3 eventos.'), findsOneWidget);
      // The range is the days the file mentions.
      expect(find.text('9 nov 2026'), findsOneWidget);
      expect(find.text('24 nov 2026'), findsOneWidget);

      await tapKey(tester, 'import-next');
      expect(stepOf(tester), 'Paso 3 de 4');
      // 6 Mañana + 3 Libre + 1 Noche (10 eventos) en 9 días: el 16 tiene un
      // «Libre» y un «Mañana»; el VALARM y el VTODO no son eventos.
      expect(find.textContaining('9 días en 3 títulos'), findsOneWidget);
      expect(byKey('import-suggested-manana'), findsOneWidget);
      expect(byKey('import-suggested-libre'), findsOneWidget);
      expect(byKey('import-suggested-noche'), findsOneWidget);
      expect(find.text('No soy un turno'), findsNothing);
      expect(find.text('Una tarea'), findsNothing);

      await tapKey(tester, 'import-next');
      expect(stepOf(tester), 'Paso 4 de 4');
      await tapKey(tester, 'import-apply');
      await flush(app);

      expect(ids(app, _nov9), 'morning');
      expect(ids(app, const CivilDate(2026, 11, 10)), 'morning');
      expect(ids(app, const CivilDate(2026, 11, 23)), 'morning');
      expect(ids(app, _nov14), 'rest');
      // A Monday that is also a «Libre» day: both, all-day first.
      expect(ids(app, const CivilDate(2026, 11, 16)), 'rest+morning');
      // Noche at 22:00 Madrid on the 20th, whatever the zone of the file.
      expect(ids(app, _nov20), 'night');
    });

    testWidgets('a narrower range leaves events out', (tester) async {
      final picker = FakePicker()..next = fileOf('turnos.ics', _ics);
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      await tapKey(tester, 'import-source-ics');
      app.container
          .read(importWizardProvider.notifier)
          .setRange(
            const ImportRange(CivilDate(2026, 11, 9), CivilDate(2026, 11, 12)),
          );
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      expect(find.textContaining('2 días en 1 título'), findsOneWidget);
    });

    testWidgets(
      'a file that is not a calendar is a message and the choice stays',
      (tester) async {
        final picker = FakePicker()..next = fileOf('cosa.ics', 'hola,esto,no');
        await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
        await tapKey(tester, 'import-source-ics');
        expect(
          find.text('Ese archivo no parece un calendario .ics.'),
          findsOneWidget,
        );
        expect(byKey('import-source-ics'), findsOneWidget);
      },
    );

    testWidgets('a calendar with no events says so', (tester) async {
      final picker = FakePicker()
        ..next = fileOf(
          'vacio.ics',
          'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nEND:VCALENDAR\r\n',
        );
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-ics');
      expect(find.text('No hay eventos en esas fechas.'), findsOneWidget);
    });

    testWidgets('a file over 5 MB is refused with a message', (tester) async {
      final picker = FakePicker()
        ..next = const PickedImportFile.problem(ImportProblem.fileTooLarge);
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-ics');
      expect(
        find.text(
          'El archivo pesa más de 5 MB. Al exportarlo, elige menos fechas.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('bytes the picker could not read are a message', (
      tester,
    ) async {
      final picker = FakePicker()
        ..next = PickedImportFile.bytes(
          'raro.ics',
          Uint8List.fromList([0, 1, 2, 3, 0, 0]),
        );
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-ics');
      // H-T22-3: it says which files are accepted.
      expect(
        find.textContaining(
          'Aceptamos .csv, .ics y la copia .Shifter de LRHSoft.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('cancelling the picker changes nothing', (tester) async {
      final picker = FakePicker();
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-ics');
      expect(picker.asked, [ImportFileKind.ics]);
      expect(find.text('¿De dónde vienen tus turnos?'), findsOneWidget);
      expect(find.textContaining('no parece'), findsNothing);
    });
  });

  group('CSV', () {
    testWidgets('columns are guessed, previewed and can be changed', (
      tester,
    ) async {
      final picker = FakePicker()..next = fileOf('turnos.csv', _csv);
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      await tapKey(tester, 'import-source-csv');
      expect(picker.asked, [ImportFileKind.csv]);
      expect(stepOf(tester), 'Paso 2 de 4');
      expect(find.text('¿Qué es cada columna?'), findsOneWidget);
      expect(byKey('import-csv-preview'), findsOneWidget);
      // The header row and the first data row.
      expect(find.text('Fecha'), findsWidgets);
      expect(find.text('09/11/2026'), findsOneWidget);
      final columns = wizardOf(app).columns!;
      expect(
        (columns.date, columns.title, columns.start, columns.end),
        (0, 1, 2, 3),
      );

      // Drop the end time: the shift is then known by its start only.
      await tapKey(tester, 'import-column-end');
      await tester.tap(find.text('Ninguna'));
      await tester.pumpAndSettle();
      expect(wizardOf(app).columns!.end, isNull);
      expect(find.text('Ninguna'), findsOneWidget);
    });

    testWidgets('titles to shifts, bad rows counted, then the import', (
      tester,
    ) async {
      final picker = FakePicker()..next = fileOf('turnos.csv', _csv);
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      await tapKey(tester, 'import-source-csv');
      await tapKey(tester, 'import-next');
      expect(stepOf(tester), 'Paso 3 de 4');
      // 2 Mañana + 1 Tarde + 1 Libre; two rows have no valid date or title.
      expect(find.textContaining('4 días en 3 títulos'), findsOneWidget);
      expect(find.textContaining('2 filas se han saltado'), findsOneWidget);
      expect(find.textContaining('la línea 5'), findsOneWidget);
      expect(byKey('import-suggested-manana'), findsOneWidget);
      expect(byKey('import-suggested-tarde'), findsOneWidget);

      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-apply');
      await flush(app);
      expect(ids(app, _nov9), 'morning');
      expect(ids(app, const CivilDate(2026, 11, 11)), 'afternoon');
      expect(ids(app, _nov14), 'rest');
    });

    testWidgets('the columns step fits a narrow phone with large text', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final picker = FakePicker()..next = fileOf('turnos.csv', _csv);
      final app = await AppUnderTest.pump(
        tester,
        size: const Size(320, 1800),
        overrides: importOverrides(phone: FakeDeviceCalendar(), picker: picker),
      );
      await app.openSettings();
      await tapKey(tester, 'settings-import');
      await tapKey(tester, 'import-source-csv');
      expect(tester.takeException(), isNull, reason: 'columns');
      await tapKey(tester, 'import-column-start');
      expect(tester.takeException(), isNull, reason: 'column sheet');
    });

    testWidgets('a CSV with no date column is a message', (tester) async {
      final picker = FakePicker()..next = fileOf('x.csv', 'a,b\nc,d\ne,f\n');
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-csv');
      expect(
        find.text('No hemos encontrado una columna de fechas en ese CSV.'),
        findsOneWidget,
      );
    });

    testWidgets('the header switch re-reads the first row', (tester) async {
      final picker = FakePicker()
        ..next = fileOf('x.csv', '09/11/2026,M\n10/11/2026,T\n');
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      await tapKey(tester, 'import-source-csv');
      expect(wizardOf(app).csv!.hasHeader, isFalse);
      await tapKey(tester, 'import-csv-header-switch');
      expect(wizardOf(app).csv!.hasHeader, isTrue);
    });
  });

  group('a file handed to the app', () {
    testWidgets('the route opens the wizard already reading it', (
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
      // What the system share does: the route with the file as `extra`.
      final context = tester.element(find.byType(Scaffold).first);
      unawaited(
        GoRouter.of(context)
            .push(AppRoutes.settingsImport, extra: fileOf('turnos.ics', _ics)),
      );
      await tester.pumpAndSettle();
      expect(stepOf(tester), 'Paso 2 de 4');
      expect(find.text('Archivo: turnos.ics'), findsOneWidget);
      expect(wizardOf(app).source, ImportSourceKind.icsFile);
    });

    testWidgets('kind comes from the name, or from the first bytes', (
      tester,
    ) async {
      expect(fileOf('a.ICS', '').kind, ImportFileKind.ics);
      expect(fileOf('a.csv', '').kind, ImportFileKind.csv);
      expect(fileOf('a.txt', '').kind, ImportFileKind.csv);
      expect(fileOf('descarga', 'BEGIN:VCALENDAR\n').kind, ImportFileKind.ics);
      expect(fileOf('descarga', 'fecha,turno').kind, ImportFileKind.csv);
    });
  });
}
