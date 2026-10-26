import 'dart:typed_data';

import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/import/application/import_wizard.dart';
import 'package:cuadrante/features/import/data/import_file_picker.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/import/domain/import_plan.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/settings/data/preferences_repository.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:cuadrante/features/shift_types/domain/free_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';
import 'import_ui_support.dart';
import 'lrhsoft_support.dart';

const _nov9 = CivilDate(2026, 11, 9);
const _nov10 = CivilDate(2026, 11, 10);
const _nov14 = CivilDate(2026, 11, 14);
const _nov16 = CivilDate(2026, 11, 16);
const _nov17 = CivilDate(2026, 11, 17);
const _nov19 = CivilDate(2026, 11, 19);
const _nov21 = CivilDate(2026, 11, 21);
const _nov25 = CivilDate(2026, 11, 25);

/// A small calendar like the one of the real sample: a Mañana over the demo
/// rotation, a Noche with a note (HTML with entities), a Libre, a split
/// shift, a guard, a day with two shifts and a day with only a note. One row
/// is garbage (month 13).
Uint8List _shifter({bool withInvalidRow = false}) => buildShifter(
  types: sampleTypes,
  days: [
    ShifterDay(shifterDate(2026, 11, 9), t1: 7),
    ShifterDay(
      shifterDate(2026, 11, 10),
      t1: 5,
      note:
          '<p dir="ltr">Cambio con Marta&#44; me devuelve el turno '
          '&#8211; revisi&#243;n</p>',
    ),
    ShifterDay(shifterDate(2026, 11, 14), t1: 3),
    ShifterDay(shifterDate(2026, 11, 16), t1: 4),
    ShifterDay(shifterDate(2026, 11, 17), t1: 8),
    ShifterDay(shifterDate(2026, 11, 19), t1: 7, t2: 6),
    ShifterDay(
      shifterDate(2026, 11, 21),
      note: 'Solo una nota<br>en dos líneas',
    ),
    if (withInvalidRow) const ShifterDay(20261331, t1: 7),
  ],
);

PickedImportFile _file({bool withInvalidRow = false}) => PickedImportFile.bytes(
  'copia.Shifter',
  _shifter(withInvalidRow: withInvalidRow),
);

/// Three days, one of them with two shifts: like the real sample, whose
/// 19-nov has a «Mañana» and a «Tarde».
Uint8List _shifterWithTwoShifts() => buildShifter(
  types: sampleTypes,
  days: [
    ShifterDay(shifterDate(2026, 11, 9), t1: 7),
    ShifterDay(shifterDate(2026, 11, 10), t1: 5),
    ShifterDay(shifterDate(2026, 11, 19), t1: 7, t2: 6),
  ],
);

String ids(AppUnderTest app, CivilDate d) =>
    app.schedule.schedule.resolve(d).shiftIds.join('+');

String? noteOf(AppUnderTest app, CivilDate d) =>
    app.schedule.schedule.entries[d]?.note;

ImportWizardState wizardOf(AppUnderTest app) =>
    app.container.read(importWizardProvider);

/// Source, range and titles: the preview is next.
Future<void> _toPreview(WidgetTester tester) async {
  await tapKey(tester, 'import-source-lrhsoft');
  await tapKey(tester, 'import-next'); // range -> titles
  await tapKey(tester, 'import-next'); // titles -> preview
}

void main() {
  setUpAll(initializeLocale);

  group('the LRHSoft backup through the whole pipeline', () {
    testWidgets('mapping, new types, preview, import, notes, undo', (
      tester,
    ) async {
      final picker = FakePicker()..next = _file();
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      final before = app.schedule.schedule;
      final typesBefore = before.shiftTypes.length;

      // The new source is there, and the old advice is gone.
      expect(byKey('import-source-lrhsoft'), findsOneWidget);
      expect(
        find.text('Copia de LRHSoft (Calendario de Turnos)'),
        findsOneWidget,
      );
      expect(
        find.text('El archivo .Shifter de tu copia local'),
        findsOneWidget,
      );
      expect(find.textContaining('Google Calendar'), findsNothing);
      expect(
        find.textContaining('Copia de seguridad › Copia local'),
        findsOneWidget,
      );

      await tapKey(tester, 'import-source-lrhsoft');
      expect(picker.asked, [ImportFileKind.lrhsoft]);
      expect(stepOf(tester), 'Paso 2 de 4');
      expect(find.text('Archivo: copia.Shifter'), findsOneWidget);
      expect(find.text('La copia trae 7 días.'), findsOneWidget);
      // The dates of the file, month counted from 0 and all: 9 to 21 Nov.
      expect(find.text('9 nov 2026'), findsOneWidget);
      expect(find.text('21 nov 2026'), findsOneWidget);

      await tapKey(tester, 'import-next');
      expect(stepOf(tester), 'Paso 3 de 4');
      // 9 Nov, 10, 14, 16, 17, 19 (x2): 7 shifts in 6 titles.
      expect(find.textContaining('7 días en 6 títulos'), findsOneWidget);
      // What you already have is suggested...
      for (final key in ['manana', 'tarde', 'noche', 'libre']) {
        expect(byKey('import-suggested-$key'), findsOneWidget, reason: key);
      }
      final mappings = wizardOf(app).mappings;
      expect(mappings['manana'], isA<MapToType>());
      expect((mappings['libre']! as MapToType).typeId, 'rest');
      // ...and what you do not have starts as a new type, not as «Ignorar».
      final partido = mappings['partido']! as CreateType;
      final guardia = mappings['guardia medica']! as CreateType;
      expect(partido.draft.name, 'Partido');
      expect(partido.draft.code, 'MA');
      expect(partido.draft.segment2StartMinute, 16 * 60);
      expect(guardia.draft.code, 'GM');
      expect(
        guardia.draft.colorValue,
        FreeColor.normalize(-15002524 & 0xFFFFFFFF),
      );
      expect(find.text('Nuevo: Partido'), findsOneWidget);

      await tapKey(tester, 'import-next');
      expect(stepOf(tester), 'Paso 4 de 4');
      expect(find.text('Se crearán 2 tipos de turno nuevos.'), findsOneWidget);
      expect(find.text('Se añadirán 2 notas.'), findsOneWidget);
      expect(
        find.text(
          'No se traen las alarmas, los dibujos, las fotos ni las horas extra.',
        ),
        findsOneWidget,
      );

      await tapKey(tester, 'import-apply');
      await flush(app);

      // Shifts.
      expect(ids(app, _nov9), 'morning');
      expect(ids(app, _nov10), 'night');
      expect(ids(app, _nov14), 'rest');
      expect(ids(app, _nov19), 'morning+afternoon');
      final partidoType = app.schedule.schedule.shiftTypes.firstWhere(
        (t) => t.name == 'Partido',
      );
      expect(ids(app, _nov16), partidoType.id);
      expect(partidoType.code, 'MA');
      expect(partidoType.hasSegment2, isTrue);
      expect(partidoType.segment2StartMinute, 16 * 60);
      expect(partidoType.segment2EndMinute, 20 * 60);
      expect(
        partidoType.colorValue,
        FreeColor.normalize(-1983764 & 0xFFFFFFFF),
      );
      final guardType = app.schedule.schedule.shiftTypes.firstWhere(
        (t) => t.name == 'Guardia Médica',
      );
      expect(guardType.hasSegment2, isFalse, reason: 'times without the flag');
      expect((guardType.startMinute, guardType.endMinute), (480, 1200));
      expect(ids(app, _nov17), guardType.id);
      expect(app.schedule.schedule.shiftTypes, hasLength(typesBefore + 2));

      // Notes: decoded, and on a day with no shift too.
      expect(
        noteOf(app, _nov10),
        'Cambio con Marta, me devuelve el turno – revisión',
      );
      expect(noteOf(app, _nov21), 'Solo una nota\nen dos líneas');
      expect(ids(app, _nov21), before.resolve(_nov21).shiftIds.join('+'));

      // What the snack bar says, with its undo.
      expect(find.textContaining('Se han importado'), findsOneWidget);
      expect(find.textContaining('2 tipos de turno nuevos'), findsOneWidget);
      expect(find.textContaining('No se traen las alarmas'), findsOneWidget);

      // One undo takes the days and the notes back.
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(app.schedule.schedule.entries, before.entries);
      expect(noteOf(app, _nov10), isNull);
      expect(app.schedule.canUndo, isFalse, reason: 'a single step');
      await flush(app);
    });

    testWidgets('a day with two shifts counts once (H-T22-14)', (tester) async {
      final picker = FakePicker()
        ..next = PickedImportFile.bytes(
          'copia.Shifter',
          _shifterWithTwoShifts(),
        );
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-lrhsoft');
      // The step before says how many days the copy has...
      expect(find.text('La copia trae 3 días.'), findsOneWidget);
      await tapKey(tester, 'import-next');
      // ...and the next one says the same: the 19th has two shifts, but it
      // is one day (four shifts would not be days).
      expect(find.textContaining('3 días en 3 títulos'), findsOneWidget);
      expect(find.textContaining('4 días'), findsNothing);
    });

    testWidgets(
      'importing the same file twice writes nothing the second time',
      (tester) async {
        final picker = FakePicker()..next = _file();
        final app = await openImport(
          tester,
          phone: FakeDeviceCalendar(),
          picker: picker,
        );
        await _toPreview(tester);
        await tapKey(tester, 'import-apply');
        await flush(app);
        final entries = app.schedule.schedule.entries;
        final types = app.schedule.schedule.shiftTypes;
        expect(noteOf(app, _nov10), isNotNull);

        // Again, the same file (the notice of the first import is out of the way).
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
            .clearSnackBars();
        await tester.pumpAndSettle();
        await app.openSettings();
        await tapKey(tester, 'settings-import');
        await tapKey(tester, 'import-source-lrhsoft');
        await tapKey(tester, 'import-next');
        // The types the first import created are now YOUR types: matched by
        // name, not created again.
        final mappings = wizardOf(app).mappings;
        expect(mappings['partido'], isA<MapToType>());
        expect(mappings['guardia medica'], isA<MapToType>());
        expect(byKey('import-suggested-partido'), findsOneWidget);
        await tapKey(tester, 'import-next');

        expect(
          find.text('Con estas elecciones no cambia ningún día.'),
          findsOneWidget,
        );
        expect(find.textContaining('tipo'), findsNothing);
        expect(find.textContaining('nota'), findsNothing);
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
          reason: 'nothing to write',
        );
        expect(app.schedule.schedule.entries, entries);
        expect(app.schedule.schedule.shiftTypes, types);
        expect(
          noteOf(app, _nov10),
          isNot(contains('\n')),
          reason: 'no 2nd copy',
        );
      },
    );

    testWidgets('invalid rows are counted and said, nothing else is lost', (
      tester,
    ) async {
      final picker = FakePicker()..next = _file(withInvalidRow: true);
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      await tapKey(tester, 'import-source-lrhsoft');
      await tapKey(tester, 'import-next');
      expect(find.text('1 fila no válida ignorada.'), findsOneWidget);
      await tapKey(tester, 'import-next');
      expect(find.text('1 fila no válida ignorada.'), findsOneWidget);
      await tapKey(tester, 'import-apply');
      await flush(app);
      expect(ids(app, _nov9), 'morning');
      expect(find.textContaining('1 fila no válida ignorada.'), findsOneWidget);
    });

    testWidgets('you can ignore a type and pick another range', (tester) async {
      final picker = FakePicker()..next = _file();
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      await tapKey(tester, 'import-source-lrhsoft');
      app.container
          .read(importWizardProvider.notifier)
          .setRange(const ImportRange(_nov9, _nov14));
      await tester.pumpAndSettle();
      await tapKey(tester, 'import-next');
      // Only 9, 10 and 14 Nov: three titles.
      expect(find.textContaining('3 días en 3 títulos'), findsOneWidget);
      await tapKey(tester, 'import-next');
      await tapKey(tester, 'import-apply');
      await flush(app);
      expect(ids(app, _nov9), 'morning');
      expect(ids(app, _nov16), isNot(contains('new')));
      expect(noteOf(app, _nov21), isNull, reason: 'outside the range');
      expect(noteOf(app, _nov10), isNotNull);
    });
  });

  group('the undo of the import (H-T22-8)', () {
    testWidgets('takes the shift types the import created away too', (
      tester,
    ) async {
      final picker = FakePicker()..next = _file();
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      final before = app.schedule.schedule;
      final paletteBefore = app.schedule.palette;
      await _toPreview(tester);
      await tapKey(tester, 'import-apply');
      await flush(app);
      expect(
        app.schedule.schedule.shiftTypes.map((t) => t.name),
        containsAll(['Partido', 'Guardia Médica']),
        reason: 'the import created them',
      );

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      await flush(app);

      // The days and the notes are gone...
      expect(app.schedule.schedule.entries, before.entries);
      expect(noteOf(app, _nov10), isNull);
      // ...and so are the types the import created: in the schedule, in the
      // palette and in the database.
      expect(app.schedule.schedule.shiftTypes, before.shiftTypes);
      expect(app.schedule.palette, paletteBefore);
      final stored = await app.real(
        () => ScheduleRepository(
          app.database,
          now: () => harnessNow,
        ).load('main'),
      );
      expect(stored.schedule.shiftTypes, before.shiftTypes);
    });

    testWidgets('a type that another calendar uses stays, and is said', (
      tester,
    ) async {
      final picker = FakePicker()..next = _file();
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      await _toPreview(tester);
      await tapKey(tester, 'import-apply');
      await flush(app);
      final partido = app.schedule.schedule.shiftTypes.firstWhere(
        (t) => t.name == 'Partido',
      );

      // Another calendar paints a day with the type the import created (the
      // shift types are shared by every calendar).
      final other = await app.real(() => addSecondCalendar(app.database));
      await app.real(
        () => ScheduleRepository(app.database, now: () => harnessNow).apply(
          other,
          ScheduleChange(
            patch: EntriesPatch({
              _nov25: EntryChange(
                null,
                DayEntry(date: _nov25, shiftTypeIds: [partido.id]),
              ),
            }),
          ),
        ),
      );

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      await flush(app);

      // The days of the import are gone, but the type stays: the other
      // calendar uses it.
      expect(noteOf(app, _nov10), isNull);
      expect(
        app.schedule.schedule.shiftTypes.map((t) => t.name),
        contains('Partido'),
      );
      expect(
        find.textContaining('Se queda el tipo «Partido»'),
        findsOneWidget,
        reason: 'the notice says which type stays',
      );
    });

    testWidgets('a day painted with a new type keeps it', (tester) async {
      final picker = FakePicker()..next = _file();
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      await _toPreview(tester);
      await tapKey(tester, 'import-apply');
      await flush(app);
      final partido = app.schedule.schedule.shiftTypes.firstWhere(
        (t) => t.name == 'Partido',
      );

      // The user paints a day with the type the import created.
      app.container
          .read(scheduleControllerProvider.notifier)
          .setDayShifts(_nov25, [partido.id]);
      await flush(app);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      await flush(app);

      // The type is still there (something uses it), and the import was not
      // undone: it was not the last thing done any more.
      expect(
        app.schedule.schedule.shiftTypes.map((t) => t.name),
        contains('Partido'),
      );
      expect(ids(app, _nov25), partido.id);
      expect(noteOf(app, _nov10), isNotNull);
      expect(
        find.textContaining('Se ha deshecho la importación'),
        findsNothing,
        reason: 'nothing was undone, so nothing is said',
      );
    });
  });

  group('files that are not what the button says', () {
    testWidgets('a .Shifter chosen as a CSV is read as an LRHSoft backup', (
      tester,
    ) async {
      final picker = FakePicker()..next = _file();
      final app = await openImport(
        tester,
        phone: FakeDeviceCalendar(),
        picker: picker,
      );
      await tapKey(tester, 'import-source-csv');
      expect(picker.asked, [ImportFileKind.csv]);
      expect(wizardOf(app).source, ImportSourceKind.lrhsoftFile);
      expect(stepOf(tester), 'Paso 2 de 4');
    });

    testWidgets('a .Shifter that is not a backup says so', (tester) async {
      final picker = FakePicker()
        ..next = fileOf('roto.Shifter', 'esto no es una base de datos');
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-lrhsoft');
      expect(
        find.textContaining('no parece una copia de LRHSoft'),
        findsOneWidget,
      );
      // Back to the choice, nothing half-done.
      expect(find.text('¿De dónde vienen tus turnos?'), findsOneWidget);
    });

    testWidgets('a text file chosen as a LRHSoft backup says so, not as a CSV', (
      tester,
    ) async {
      final picker = FakePicker()
        ..next = fileOf('turnos.txt', 'fecha;turno\n01/10/2026;Mañana');
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-lrhsoft');
      // The LRHSoft source never blames a CSV (H-T22-11).
      expect(
        find.textContaining('no parece una copia de LRHSoft'),
        findsOneWidget,
      );
      expect(find.textContaining('columna de fechas'), findsNothing);
      // Back to the choice, nothing half-done.
      expect(find.text('¿De dónde vienen tus turnos?'), findsOneWidget);
    });

    testWidgets('a file the system named «.bin» is shown as the LRHSoft copy', (
      tester,
    ) async {
      final picker = FakePicker()
        ..next = PickedImportFile.bytes(
          'Shifter_backup_Unnamed_20260923_17h09m16s.bin',
          _shifter(),
        );
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-lrhsoft');
      // Android calls every file whose type it does not know «.bin»: the app
      // does not repeat that made-up name (H-T22-10).
      expect(find.text('Copia de LRHSoft'), findsOneWidget);
      expect(find.textContaining('.bin'), findsNothing);
    });

    testWidgets('a SQLite file of another app says so', (tester) async {
      final picker = FakePicker()
        ..next = PickedImportFile.bytes(
          'otra.sqlite',
          buildShifter(build: (db) => db.execute('CREATE TABLE otra (a)')),
        );
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-lrhsoft');
      expect(
        find.textContaining('no parece una copia de LRHSoft'),
        findsOneWidget,
      );
    });

    testWidgets('a backup with no days says there is nothing to import', (
      tester,
    ) async {
      final picker = FakePicker()
        ..next = PickedImportFile.bytes(
          'vacia.Shifter',
          buildShifter(types: sampleTypes),
        );
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-lrhsoft');
      expect(find.text('No hay eventos en esas fechas.'), findsOneWidget);
    });

    testWidgets('a binary file says which files are accepted', (tester) async {
      final picker = FakePicker()
        ..next = PickedImportFile.bytes(
          'foto.png',
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 13, 0, 0]),
        );
      await openImport(tester, phone: FakeDeviceCalendar(), picker: picker);
      await tapKey(tester, 'import-source-csv');
      expect(
        find.textContaining('.csv, .ics y la copia .Shifter de LRHSoft'),
        findsOneWidget,
      );
    });
  });

  group('the file the system hands to the app', () {
    test('kind: by the name, or by the SQLite header', () {
      expect(_file().kind, ImportFileKind.lrhsoft);
      expect(
        PickedImportFile.bytes('x.SHIFTER', Uint8List(4)).kind,
        ImportFileKind.lrhsoft,
      );
      expect(
        PickedImportFile.bytes('sin-extension', _shifter()).kind,
        ImportFileKind.lrhsoft,
      );
      expect(fileOf('a.csv', 'a;b').kind, ImportFileKind.csv);
      expect(fileOf('a.ics', 'BEGIN:VCALENDAR').kind, ImportFileKind.ics);
    });

    test('the name the user recognises: the made-up one is dropped', () {
      expect(_file().realName, 'copia.Shifter');
      expect(
        PickedImportFile.bytes('copia.bin', Uint8List(4)).realName,
        isNull,
      );
      expect(
        PickedImportFile.bytes('  turnos.csv  ', Uint8List(4)).realName,
        'turnos.csv',
      );
    });
  });

  group('in Basque', () {
    testWidgets('the example dates are not mixed up (H-T22-15)', (
      tester,
    ) async {
      final picker = FakePicker()..next = _file();
      await AppUnderTest.pump(
        tester,
        size: importTestSize,
        overrides: importOverrides(phone: FakeDeviceCalendar(), picker: picker),
        prepare: (db) => PreferencesRepository(db).setLanguage(AppLanguage.eu),
      );
      // The settings button has no key, and its tooltip is in Basque.
      await tester.tap(find.byTooltip('Ireki ezarpenak'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'settings-import');
      await tapKey(tester, 'import-source-lrhsoft');
      await tapKey(tester, 'import-next');
      // The Basque short date has a comma of its own («urr 9, al»), so the
      // examples are separated with a middle dot and not with a comma.
      final meta = tester
          .widget<Text>(
            find.descendant(
              of: byKey('import-group-manana'),
              matching: find.textContaining('adib.'),
            ),
          )
          .data!;
      final examples = meta.split('adib. ').last;
      expect(' · '.allMatches(examples).length, 1);
      expect(', '.allMatches(examples).length, 2);
    });
  });

  group('layout', () {
    testWidgets('every step fits 320 dp at text scale 2.0', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final picker = FakePicker()..next = _file(withInvalidRow: true);
      final app = await AppUnderTest.pump(
        tester,
        size: const Size(320, 1800),
        overrides: importOverrides(phone: FakeDeviceCalendar(), picker: picker),
      );
      await app.openSettings();
      await tapKey(tester, 'settings-import');
      expect(tester.takeException(), isNull, reason: 'source');
      expect(byKey('import-source-lrhsoft'), findsOneWidget);

      await tapKey(tester, 'import-source-lrhsoft');
      expect(tester.takeException(), isNull, reason: 'range');
      await tapKey(tester, 'import-next');
      expect(tester.takeException(), isNull, reason: 'titles');
      expect(find.text('1 fila no válida ignorada.'), findsOneWidget);
      await tapKey(tester, 'import-next');
      expect(tester.takeException(), isNull, reason: 'preview');
      expect(byKey('import-preview-not-imported'), findsOneWidget);
      expect(byKey('import-preview-notes'), findsOneWidget);
      expect(byKey('import-preview-invalid-rows'), findsOneWidget);
    });

    testWidgets('and in the dark', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final picker = FakePicker()..next = _file();
      final app = await AppUnderTest.pump(
        tester,
        size: const Size(320, 1800),
        platformBrightness: Brightness.dark,
        overrides: importOverrides(phone: FakeDeviceCalendar(), picker: picker),
      );
      await app.openSettings();
      await tapKey(tester, 'settings-import');
      await _toPreview(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
