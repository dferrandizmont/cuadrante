import 'dart:async';

import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/import/application/import_providers.dart';
import 'package:cuadrante/features/import/application/import_wizard.dart';
import 'package:cuadrante/features/import/domain/csv_parser.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';
import 'import_ui_support.dart';

/// The heavy parts of the import go through the background runner (never the
/// UI isolate), wait for it only so long, and the CSV screens stay small
/// whatever the file holds.

const _csv = '''Fecha;Turno;Inicio;Fin
09/11/2026;Mañana;06:00;14:00
10/11/2026;Mañana;06:00;14:00
11/11/2026;Tarde;14:00;22:00
''';

ImportWizardState wizardOf(AppUnderTest app) =>
    app.container.read(importWizardProvider);

void main() {
  setUpAll(initializeLocale);

  testWidgets('a CSV goes through the runner at every heavy step', (
    tester,
  ) async {
    var calls = 0;
    final picker = FakePicker()..next = fileOf('turnos.csv', _csv);
    final app = await openImport(
      tester,
      phone: FakeDeviceCalendar(),
      picker: picker,
      runner: <T>(T Function() job) async {
        calls++;
        return job();
      },
    );
    await tapKey(tester, 'import-source-csv');
    // Reading the file and guessing its columns: one job.
    expect(calls, 1);
    await tapKey(tester, 'import-csv-header-switch');
    // Guessing again after the header changed.
    expect(calls, 2);
    expect(wizardOf(app).csv!.hasHeader, isFalse);
    await tapKey(tester, 'import-csv-header-switch');
    expect(calls, 3);
    await tapKey(tester, 'import-next');
    // Reading the rows and grouping them.
    expect(calls, 5);
    expect(stepOf(tester), 'Paso 3 de 4');
  });

  testWidgets('a phone calendar expands and groups through the runner', (
    tester,
  ) async {
    var calls = 0;
    final picker = FakePicker();
    final app = await openImport(
      tester,
      phone: phoneWithShifts(),
      picker: picker,
      runner: <T>(T Function() job) async {
        calls++;
        return job();
      },
    );
    await tapKey(tester, 'import-source-device');
    final turnos = wizardOf(app).calendars
        .firstWhere((c) => c.name == 'Turnos');
    await tapKey(tester, 'import-calendar-${turnos.id}');
    await tapKey(tester, 'import-next');
    expect(calls, 0);
    await tapKey(tester, 'import-next');
    // Expanding the events and grouping the days.
    expect(calls, 2);
    expect(stepOf(tester), 'Paso 4 de 5');
  });

  testWidgets('a job that never ends gives up with a message', (tester) async {
    final picker = FakePicker()..next = fileOf('turnos.csv', _csv);
    final app = await openImport(
      tester,
      phone: FakeDeviceCalendar(),
      picker: picker,
      runner: <T>(T Function() job) => Completer<T>().future,
      overrides: [
        importTimeoutProvider.overrideWithValue(const Duration(seconds: 2)),
      ],
    );
    await tester.tap(byKey('import-source-csv'));
    await tester.pump();
    expect(wizardOf(app).busy, isTrue);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(wizardOf(app).busy, isFalse);
    expect(wizardOf(app).problem, ImportProblem.tooComplex);
    expect(
      find.textContaining('demasiado grande o complicado'),
      findsOneWidget,
    );
  });

  testWidgets('a file with hundreds of long columns keeps the screen small', (
    tester,
  ) async {
    final long = 'z' * 400;
    final head = [
      'Fecha',
      'Turno',
      for (var i = 0; i < 400; i++) 'Columna $i $long',
    ].join(';');
    final row = ['09/11/2026', 'Mañana', for (var i = 0; i < 400; i++) long];
    final text = '$head\n${row.join(';')}\n${row.join(';')}\n';
    final picker = FakePicker()..next = fileOf('ancho.csv', text);
    final app = await openImport(
      tester,
      phone: FakeDeviceCalendar(),
      picker: picker,
    );
    await tapKey(tester, 'import-source-csv');
    expect(tester.takeException(), isNull);
    expect(wizardOf(app).csv!.columnCount, maxCsvColumns);

    // The preview holds a header and two rows of at most 50 cells, each one
    // line cut with an ellipsis.
    final cells = tester
        .widgetList<Text>(
          // The cells of the table (the hint under it is not a cell).
          find.descendant(
            of: find.descendant(
              of: byKey('import-csv-preview'),
              matching: find.byType(Table),
            ),
            matching: find.byType(Text),
          ),
        )
        .toList();
    expect(cells.length, lessThanOrEqualTo(maxCsvColumns * 3));
    for (final cell in cells) {
      expect(cell.maxLines, 1);
      expect(cell.overflow, TextOverflow.ellipsis);
      expect(cell.data!.length, lessThanOrEqualTo(maxImportTitleLength));
    }
    // No cell is wider than its cap.
    final widest = cells
        .map((c) => tester.getSize(find.byWidget(c)).width)
        .reduce((a, b) => a > b ? a : b);
    expect(widest, lessThanOrEqualTo(160));
  });

  testWidgets('the column picker never has more than 50 columns', (
    tester,
  ) async {
    final head = ['Fecha', 'Turno', for (var i = 0; i < 300; i++) 'C$i'];
    final row = ['09/11/2026', 'Mañana', for (var i = 0; i < 300; i++) 'x'];
    final picker = FakePicker()
      ..next = fileOf('ancho.csv', '${head.join(';')}\n${row.join(';')}\n');
    final app = await openImport(
      tester,
      phone: FakeDeviceCalendar(),
      picker: picker,
    );
    await tapKey(tester, 'import-source-csv');
    await tapKey(tester, 'import-column-start');
    // «Ninguna» plus the 50 columns that are kept, numbered «n: nombre».
    expect(wizardOf(app).csv!.columnCount, 50);
    expect(find.textContaining('50: '), findsWidgets);
    expect(find.text('51: C49'), findsNothing);
    expect(find.text('52: C50'), findsNothing);
  });

  testWidgets('one column cannot be two roles in the screen either', (
    tester,
  ) async {
    final picker = FakePicker()..next = fileOf('turnos.csv', _csv);
    final app = await openImport(
      tester,
      phone: FakeDeviceCalendar(),
      picker: picker,
    );
    await tapKey(tester, 'import-source-csv');
    // End takes the column of the start: the start lets it go.
    await tapKey(tester, 'import-column-end');
    await tester.tap(find.text('3: Inicio').last);
    await tester.pumpAndSettle();
    final columns = wizardOf(app).columns!;
    expect(columns.end, 2);
    expect(columns.start, isNull);
  });
}
