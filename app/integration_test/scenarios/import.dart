import 'dart:convert';
import 'dart:typed_data';

import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/calendar_export/domain/export_events.dart';
import 'package:cuadrante/features/import/application/import_providers.dart';
import 'package:cuadrante/features/import/data/import_file_picker.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart' as dcp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Scenarios Q70 to Q74: import from an `.ics`, a CSV and the phone calendar,
/// and the one-off export to the phone calendar (release 0.5.0,
/// docs/importar.md). The file picker is the only fake: it opens a system
/// screen a test cannot drive. The phone calendar is the real one of the
/// emulator, through the plugin; `run_android.sh` grants READ_CALENDAR and
/// WRITE_CALENDAR (the scenarios cannot answer the system question), and the
/// scenarios create and delete their own local calendars. The registry lists
/// [importScenarios].
final List<QaScenario> importScenarios = [
  qaImportIcs, // Q70
  qaImportCsv, // Q71
  qaExportTwice, // Q72
  qaImportPhoneCalendar, // Q73
  qaImportBadFileAndConflicts, // Q74
];

// The demo rotation (Monday 19 October 2026): Tarde 2-6 Nov, Libre 7-8 Nov,
// Noche 9-13 Nov, Libre 14-15 Nov.
const _nov2 = CivilDate(2026, 11, 2);
const _nov3 = CivilDate(2026, 11, 3);
const _nov4 = CivilDate(2026, 11, 4);
const _nov5 = CivilDate(2026, 11, 5);
const _nov6 = CivilDate(2026, 11, 6);
const _nov7 = CivilDate(2026, 11, 7);
const _nov9 = CivilDate(2026, 11, 9);

/// Three Mañana (a daily series), a Noche with a time zone, and a Libre that
/// the rotation already has.
const _icsFixture =
    'BEGIN:VCALENDAR\r\n'
    'VERSION:2.0\r\n'
    'PRODID:-//cuadrante-qa//ES\r\n'
    'BEGIN:VEVENT\r\n'
    'UID:qa-manana\r\n'
    'DTSTART:20261103T060000\r\n'
    'DTEND:20261103T140000\r\n'
    'RRULE:FREQ=DAILY;COUNT=3\r\n'
    'SUMMARY:Mañana\r\n'
    'BEGIN:VALARM\r\n'
    'ACTION:DISPLAY\r\n'
    'TRIGGER:-PT30M\r\n'
    'SUMMARY:No soy un turno\r\n'
    'END:VALARM\r\n'
    'END:VEVENT\r\n'
    'BEGIN:VEVENT\r\n'
    'UID:qa-noche\r\n'
    'DTSTART;TZID=Europe/Madrid:20261106T220000\r\n'
    'DTEND;TZID=Europe/Madrid:20261107T060000\r\n'
    'SUMMARY:Noche\r\n'
    'END:VEVENT\r\n'
    'BEGIN:VEVENT\r\n'
    'UID:qa-libre\r\n'
    'DTSTART;VALUE=DATE:20261107\r\n'
    'DTEND;VALUE=DATE:20261109\r\n'
    'SUMMARY:Libre\r\n'
    'END:VEVENT\r\n'
    'END:VCALENDAR\r\n';

const _csvFixture =
    'Fecha;Turno;Inicio;Fin\n'
    '03/11/2026;Mañana;06:00;14:00\n'
    '04/11/2026;Mañana;06:00;14:00\n'
    '05/11/2026;Noche;22:00;06:00\n'
    'no es una fecha;Tarde;14:00;22:00\n';

PickedImportFile _file(String name, String text) =>
    PickedImportFile.bytes(name, Uint8List.fromList(utf8.encode(text)));

List<Override> _overrides(PickedImportFile? file) => [
  importFilePickerProvider.overrideWithValue((kind) async => file),
  // The fixtures talk in Madrid time whatever zone the emulator is in.
  importTimeZoneProvider.overrideWithValue(() async => 'Europe/Madrid'),
];

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _openImport(WidgetTester t) async {
  await t.tapAndSettle(find.byTooltip('Abrir ajustes'), reason: 'Ajustes');
  await t.tapAndSettle(_key('settings-import'), reason: 'Importar turnos');
  expect(find.text('¿De dónde vienen tus turnos?'), findsOneWidget);
}

Future<void> _openExport(WidgetTester t) async {
  await t.tapAndSettle(find.byTooltip('Abrir ajustes'), reason: 'Ajustes');
  await t.tapAndSettle(
    _key('settings-export-calendar'),
    reason: 'Exportar al calendario',
  );
  await t.waitFor(_key('export-calendar-new'), reason: 'pantalla Exportar');
}

Future<void> _home(WidgetTester t) async {
  for (var i = 0; i < 4 && find.byType(BackButton).evaluate().isNotEmpty; i++) {
    await t.tapAndSettle(find.byType(BackButton).last, reason: 'flecha atrás');
  }
  expect(find.byType(MonthScreen), findsOneWidget);
}

Future<void> _dismissSnackBars(WidgetTester t) async {
  final messenger = find.byType(ScaffoldMessenger);
  if (messenger.evaluate().isEmpty) return;
  t.state<ScaffoldMessengerState>(messenger.first).hideCurrentSnackBar();
  await t.settle();
}

/// Goes through the steps after the source until the preview, tapping
/// «Siguiente» [times] times and waiting for the next title each time.
Future<void> _next(WidgetTester t, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await t.tapAndSettle(_key('import-next'), reason: 'Siguiente');
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

String _compact(CivilDate d) => '${d.year}${_two(d.month)}${_two(d.day)}';

// ---- Q70 -------------------------------------------------------------------

/// Q70.
const qaImportIcs = QaScenario(
  'Q70',
  'Importar un .ics: el mes pintado coincide con lo esperado',
  _importIcs,
);

Future<void> _importIcs(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(
    qa,
    overrides: _overrides(_file('turnos.ics', _icsFixture)),
  );
  final rowsBefore = await app.storedDayCount();
  final dumpBefore = await app.dumpSchedule();
  expect(idsOn(app.schedule, _nov3), 'afternoon');

  await _openImport(t);
  await t.tapAndSettle(_key('import-source-ics'), reason: 'Archivo .ics');
  await t.waitFor(_key('import-file-events'), reason: 'el archivo leído');
  expect(find.text('El archivo trae 3 eventos.'), findsOneWidget);
  await qa.shot('rango');
  await _next(t); // reads the series
  await t.waitFor(_key('import-group-manana'), reason: 'títulos agrupados');
  // The titles are recognised by name, and the alarm inside the event is not
  // taken for a shift.
  expect(_key('import-suggested-manana'), findsOneWidget);
  expect(_key('import-suggested-noche'), findsOneWidget);
  expect(_key('import-suggested-libre'), findsOneWidget);
  expect(find.text('No soy un turno'), findsNothing);
  await qa.shot('titulos');
  await _next(t);
  await t.waitFor(_key('import-apply'), reason: 'vista previa');
  await qa.shot('vista_previa');
  await t.tapAndSettle(_key('import-apply'), reason: 'Importar');
  await _dismissSnackBars(t);
  await _home(t);

  // The month shown is the one of the first imported day: November.
  expect(idsOn(app.schedule, _nov3), 'morning');
  expect(inCell(_nov3, find.text('M')), findsOneWidget);
  expect(inCell(_nov4, find.text('M')), findsOneWidget);
  expect(inCell(_nov5, find.text('M')), findsOneWidget);
  expect(inCell(_nov6, find.text('N')), findsOneWidget);
  // Left alone: the day before the file, and the Libre the rotation has.
  expect(inCell(_nov2, find.text('T')), findsOneWidget);
  expect(inCell(_nov7, find.text('L')), findsOneWidget);
  await qa.shot('mes_importado');

  // Stored: 4 days written (the Libre was already so).
  await app.flushWrites();
  for (final d in [_nov3, _nov4, _nov5, _nov6]) {
    expect(await app.storedDay(d), isNotNull, reason: 'fila de $d');
  }
  expect(await app.storedDayCount(), rowsBefore + 4);

  // The whole import is ONE undo step.
  expect(app.scheduleState.canUndo, isTrue);
  app.scheduleController.undo();
  await t.settle();
  await app.flushWrites();
  expect(await app.dumpSchedule(), dumpBefore, reason: 'un solo deshacer');
  expect(app.scheduleState.canUndo, isFalse);
  qa.expectNoFlutterErrors();
}

// ---- Q71 -------------------------------------------------------------------

/// Q71.
const qaImportCsv = QaScenario(
  'Q71',
  'Importar un CSV: columnas, títulos y días',
  _importCsv,
);

Future<void> _importCsv(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(
    qa,
    overrides: _overrides(_file('turnos.csv', _csvFixture)),
  );
  final dumpBefore = await app.dumpSchedule();

  await _openImport(t);
  await t.tapAndSettle(_key('import-source-csv'), reason: 'Archivo CSV');
  await t.waitFor(_key('import-csv-preview'), reason: 'columnas del CSV');
  expect(find.text('¿Qué es cada columna?'), findsOneWidget);
  expect(find.text('03/11/2026'), findsOneWidget);
  await qa.shot('columnas');
  await _next(t);
  await t.waitFor(_key('import-group-manana'), reason: 'títulos agrupados');
  // 3 valid days; the row without a date is counted, not imported.
  expect(find.textContaining('3 días en 2 títulos'), findsOneWidget);
  expect(_key('import-skipped-rows'), findsOneWidget);
  await qa.shot('titulos');
  await _next(t);
  await t.waitFor(_key('import-apply'), reason: 'vista previa');
  await t.tapAndSettle(_key('import-apply'), reason: 'Importar');
  await _dismissSnackBars(t);
  await _home(t);

  expect(idsOn(app.schedule, _nov3), 'morning');
  expect(idsOn(app.schedule, _nov4), 'morning');
  expect(idsOn(app.schedule, _nov5), 'night');
  expect(idsOn(app.schedule, _nov6), 'afternoon', reason: 'sin tocar');
  expect(inCell(_nov5, find.text('N')), findsOneWidget);
  await qa.shot('mes_importado');

  // The whole import is ONE undo step (the history does not survive a
  // restart, so this goes first)...
  app.scheduleController.undo();
  await t.settle();
  await app.flushWrites();
  expect(await app.dumpSchedule(), dumpBefore, reason: 'un solo deshacer');
  app.scheduleController.redo();
  await t.settle();

  // ...and it survives closing and opening the app.
  await app.flushWrites();
  await app.restart();
  expect(idsOn(app.schedule, _nov5), 'night');
  qa.expectNoFlutterErrors();
}

// ---- Q72 -------------------------------------------------------------------

/// Q72.
const qaExportTwice = QaScenario(
  'Q72',
  'Exportar al calendario del móvil y volver a exportar: sin duplicados',
  _exportTwice,
  timeout: Duration(minutes: 5),
);

final dcp.DeviceCalendar _plugin = dcp.DeviceCalendar.instance;

/// Fails with a clear message when the QA run did not grant the permission.
Future<void> _requireCalendarAccess(QaContext qa) async {
  final status = (await qa.tester.runAsync(_plugin.hasPermissions))!;
  if (status != dcp.CalendarPermissionStatus.granted) {
    throw TestFailure(
      'Falta el permiso del calendario (estado: ${status.name}). '
      '`tool/qa/run_android.sh` lo concede con `adb shell pm grant`; si el '
      'escenario se ejecuta de otra forma, concede READ_CALENDAR y '
      'WRITE_CALENDAR a la app.',
    );
  }
}

/// Removes the calendars called [name] (left by an earlier run) now and when
/// the scenario ends.
Future<void> _cleanCalendars(QaContext qa, String name) async {
  Future<void> clean() async {
    final calendars = await _plugin.listCalendars();
    for (final c in calendars) {
      if (c.name == name) {
        try {
          await _plugin.deleteCalendar(c.id);
        } catch (_) {
          // Not ours to delete (a read-only account): leave it.
        }
      }
    }
  }

  await qa.tester.runAsync(clean);
  addTearDown(() async {
    try {
      await qa.tester.runAsync(clean);
    } catch (_) {
      // The binding may already be gone.
    }
  });
}

/// The events of the calendar called [name] that Cuadrante exported, by their
/// tag: `tag -> title`.
Future<Map<String, String>> _exported(QaContext qa, String name) async {
  return (await qa.tester.runAsync(() async {
    final calendars = (await _plugin.listCalendars())
        .where((c) => c.name == name)
        .toList();
    final out = <String, String>{};
    for (final c in calendars) {
      final events = await _plugin.listEvents(
        DateTime(2026, 10, 1),
        DateTime(2027, 3, 1),
        calendarIds: [c.id],
      );
      for (final e in events) {
        final tag = ExportTag.parse(e.description);
        if (tag != null) out[tag.key] = e.title;
      }
    }
    return out;
  }))!;
}

Future<void> _exportTwice(QaContext qa) async {
  final t = qa.tester;
  await _requireCalendarAccess(qa);
  await _cleanCalendars(qa, 'Cuadrante');
  final app = await QaApp.open(qa);

  await _openExport(t);
  expect(find.text('Crear el calendario «Cuadrante»'), findsOneWidget);
  await qa.shot('opciones');
  await t.tapAndSettle(_key('export-start'), reason: 'Exportar');
  await t.waitFor(_key('export-result'), reason: 'resultado de la exportación');
  expect(find.text('Se ha creado el calendario «Cuadrante».'), findsOneWidget);
  await qa.shot('exportado');

  final first = await _exported(qa, 'Cuadrante');
  expect(first, isNotEmpty, reason: 'eventos en el calendario del móvil');
  // Every event carries the tag of the active calendar and one of today's
  // shifts is there (Noche on the 19th).
  expect(first.keys.every((k) => k.startsWith('cuadrante:v1:main:')), isTrue);
  expect(first['cuadrante:v1:main:2026-10-19:night:0'], 'Noche · N');
  // The new plan reads the phone calendar again (±366 days, to catch moved
  // events), so it can take a moment.
  await t.waitFor(
    find.text('Todo está al día: no hay nada que cambiar.'),
    reason: 'plan vacío tras exportar',
  );

  // Exporting again with nothing changed: the button waits, nothing is added.
  await _home(t);
  await _openExport(t);
  await t.waitFor(
    find.text('Todo está al día: no hay nada que cambiar.'),
    reason: 'plan sin cambios',
  );
  expect((await _exported(qa, 'Cuadrante')).length, first.length);

  // One day changes (Mañana on 30 Oct becomes Tarde): re-exporting REPLACES
  // that event, it does not add one.
  await _home(t);
  app.scheduleController.setDayShifts(const CivilDate(2026, 10, 30), const [
    'afternoon',
  ]);
  await t.settle();
  await _openExport(t);
  await t.waitFor(
    find.textContaining('Se sustituirá 1 evento'),
    reason: 'un evento por sustituir',
  );
  await t.tapAndSettle(_key('export-start'), reason: 'Exportar otra vez');
  await t.waitFor(_key('export-result-replaced'), reason: 'evento sustituido');
  final second = await _exported(qa, 'Cuadrante');
  expect(second.length, first.length, reason: 'mismo número de eventos');
  expect(second['cuadrante:v1:main:2026-10-30:afternoon:0'], 'Tarde · T');
  expect(second['cuadrante:v1:main:2026-10-30:morning:0'], isNull);
  await qa.shot('reexportado');
  qa.expectNoFlutterErrors();
}

// ---- Q73 -------------------------------------------------------------------

/// Q73.
const qaImportPhoneCalendar = QaScenario(
  'Q73',
  'Importar desde el calendario del móvil',
  _importPhoneCalendar,
  timeout: Duration(minutes: 5),
);

Future<void> _importPhoneCalendar(QaContext qa) async {
  final t = qa.tester;
  await _requireCalendarAccess(qa);
  const calendarName = 'QA turnos importados';
  await _cleanCalendars(qa, calendarName);

  // A local calendar with the history of another app: three Mañana, one
  // all-day Libre of two days, and an appointment.
  await t.runAsync(() async {
    final id = await _plugin.createCalendar(
      name: calendarName,
      platformOptions: const dcp.CreateCalendarOptionsAndroid(
        accountName: 'QA',
      ),
    );
    for (final d in [_nov3, _nov4, _nov5]) {
      await _plugin.createEvent(
        calendarId: id,
        title: 'Mañana',
        startDate: DateTime(d.year, d.month, d.day, 6),
        endDate: DateTime(d.year, d.month, d.day, 14),
      );
    }
    await _plugin.createEvent(
      calendarId: id,
      title: 'Libre',
      startDate: DateTime(2026, 11, 14),
      endDate: DateTime(2026, 11, 16),
      isAllDay: true,
    );
    await _plugin.createEvent(
      calendarId: id,
      title: 'Cita con el médico',
      startDate: DateTime(2026, 11, 10, 10),
      endDate: DateTime(2026, 11, 10, 11),
    );
  });

  final app = await QaApp.open(qa, overrides: _overrides(null));
  final dumpBefore = await app.dumpSchedule();

  await _openImport(t);
  await t.tapAndSettle(_key('import-source-device'), reason: 'Calendario');
  await t.waitFor(find.text(calendarName), reason: 'lista de calendarios');
  expect(find.text('QA'), findsWidgets, reason: 'la cuenta del calendario');
  await qa.shot('calendarios');
  await t.tapAndSettle(find.text(calendarName), reason: 'marcar calendario');
  await _next(t); // range
  await t.waitFor(_key('import-range-from'), reason: 'fechas');
  await _next(t); // read events
  await t.waitFor(_key('import-group-manana'), reason: 'títulos agrupados');
  expect(_key('import-group-cita con el medico'), findsOneWidget);
  expect(_key('import-suggested-manana'), findsOneWidget);
  expect(_key('import-suggested-libre'), findsOneWidget);
  await qa.shot('titulos');
  await _next(t);
  await t.waitFor(_key('import-apply'), reason: 'vista previa');
  await t.tapAndSettle(_key('import-apply'), reason: 'Importar');
  await _dismissSnackBars(t);
  await _home(t);

  expect(idsOn(app.schedule, _nov3), 'morning');
  expect(idsOn(app.schedule, _nov5), 'morning');
  expect(idsOn(app.schedule, _nov9), 'night', reason: 'sin tocar');
  expect(idsOn(app.schedule, const CivilDate(2026, 11, 10)), 'night');
  await qa.shot('mes_importado');

  app.scheduleController.undo();
  await t.settle();
  await app.flushWrites();
  expect(await app.dumpSchedule(), dumpBefore, reason: 'un solo deshacer');
  qa.expectNoFlutterErrors();
}

// ---- Q74 -------------------------------------------------------------------

/// Q74.
const qaImportBadFileAndConflicts = QaScenario(
  'Q74',
  'Importar: archivo estropeado y días que ya tienen turno',
  _importBadFileAndConflicts,
);

Future<void> _importBadFileAndConflicts(QaContext qa) async {
  final t = qa.tester;
  // The file under the picker changes between the two attempts.
  var next = _file('roto.ics', 'esto no es un calendario, ni de lejos');
  final app = await QaApp.open(
    qa,
    overrides: [
      importFilePickerProvider.overrideWithValue((kind) async => next),
      importTimeZoneProvider.overrideWithValue(() async => 'Europe/Madrid'),
    ],
  );
  final dumpBefore = await app.dumpSchedule();

  // A file that is not a calendar: a message, nothing is touched.
  await _openImport(t);
  await t.tapAndSettle(_key('import-source-ics'), reason: 'Archivo .ics');
  await t.waitFor(
    find.text('Ese archivo no parece un calendario .ics.'),
    reason: 'mensaje de archivo estropeado',
  );
  expect(_key('import-source-ics'), findsOneWidget);
  expect(await app.dumpSchedule(), dumpBefore);
  await qa.shot('archivo_roto');

  // A binary file: also a message.
  next = PickedImportFile.bytes(
    'imagen.ics',
    Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 13, 0, 0]),
  );
  await t.tapAndSettle(_key('import-source-ics'), reason: 'Archivo .ics');
  await t.waitFor(
    find.textContaining('No hemos podido abrir ese archivo.'),
    reason: 'mensaje de archivo ilegible',
  );

  // A good file whose days already have a shift: Mañana over the rotation's
  // Noche on 9-10 Nov.
  next = _file(
    'turnos.ics',
    'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nUID:a\r\n'
        'DTSTART;VALUE=DATE:${_compact(_nov9)}\r\n'
        'DTEND;VALUE=DATE:${_compact(const CivilDate(2026, 11, 11))}\r\n'
        'SUMMARY:Mañana\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n',
  );
  await t.tapAndSettle(_key('import-source-ics'), reason: 'Archivo .ics');
  await t.waitFor(_key('import-file-events'), reason: 'el archivo leído');
  await _next(t, times: 2);
  await t.waitFor(_key('import-conflicts'), reason: 'días con turno');
  expect(find.text('2 días ya tienen turno'), findsOneWidget);
  await qa.shot('conflictos');

  // «Mantener lo mío»: nothing to write.
  await t.tapAndSettle(_key('import-conflict-keep'), reason: 'Mantener lo mío');
  expect(
    find.text('Con estas elecciones no cambia ningún día.'),
    findsOneWidget,
  );
  expect(idsOn(app.schedule, _nov9), 'night');

  // «Sustituir»: the two days change, and one undo brings them back.
  await t.tapAndSettle(_key('import-conflict-replace'), reason: 'Sustituir');
  await t.tapAndSettle(_key('import-apply'), reason: 'Importar');
  await _dismissSnackBars(t);
  await _home(t);
  expect(idsOn(app.schedule, _nov9), 'morning');
  expect(idsOn(app.schedule, const CivilDate(2026, 11, 10)), 'morning');
  app.scheduleController.undo();
  await t.settle();
  await app.flushWrites();
  expect(await app.dumpSchedule(), dumpBefore);
  qa.expectNoFlutterErrors();
}
