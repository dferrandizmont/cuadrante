import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar_export/application/export_controller.dart';
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

  testWidgets('absences are off by default and the switch says where they go', (
    tester,
  ) async {
    final app = await openExport(tester, FakeDeviceCalendar());
    expect(byKey('export-include-absences'), findsOneWidget);
    expect(stateOf(app).includeAbsences, isFalse);
    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('export-include-absences-switch')),
          )
          .value,
      isFalse,
    );
    expect(find.text('Incluir ausencias'), findsOneWidget);
    expect(
      find.textContaining('a la cuenta con la que se sincronice'),
      findsOneWidget,
    );
  });

  testWidgets('a sick leave is not planned until the switch is on', (
    tester,
  ) async {
    final app = await openExport(tester, FakeDeviceCalendar());
    // 21 Oct becomes a vacation (an absence) in the active calendar.
    app.container.read(scheduleControllerProvider.notifier).setDayShifts(
      const CivilDate(2026, 10, 21),
      const ['vacation'],
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'export-include-rest-switch');
    await tapKey(tester, 'export-include-rest-switch');
    bool planHasVacation() =>
        stateOf(app).plan!.toCreate.any((e) => e.shiftTypeId == 'vacation');
    expect(planHasVacation(), isFalse);
    await tapKey(tester, 'export-include-absences-switch');
    expect(stateOf(app).includeAbsences, isTrue);
    expect(planHasVacation(), isTrue);
  });

  testWidgets('a synced calendar says where the shifts will show up', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final google = phone.addCalendar(
      'Personal',
      account: 'yo@example.com',
      accountType: 'com.google',
    );
    final local = phone.addCalendar(
      'En el móvil',
      account: 'local',
      accountType: 'local',
    );
    await openExport(tester, phone);
    // «Crear el calendario» (nothing chosen yet): no line.
    expect(byKey('export-synced'), findsNothing);

    await tapKey(tester, 'export-calendar-$google');
    expect(byKey('export-synced'), findsOneWidget);
    expect(
      find.text(
        'Este calendario se sincroniza con yo@example.com: '
        'tus turnos se verán allí.',
      ),
      findsOneWidget,
    );

    await tapKey(tester, 'export-calendar-$local');
    expect(byKey('export-synced'), findsNothing);
  });

  testWidgets('a synced calendar without an account name still warns', (
    tester,
  ) async {
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Trabajo', accountType: 'exchange');
    await openExport(tester, phone);
    await tapKey(tester, 'export-calendar-$id');
    expect(
      find.text(
        'Este calendario se sincroniza con una cuenta: '
        'tus turnos se verán allí.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a range of exactly a year is not «recortado»', (tester) async {
    final app = await openExport(tester, FakeDeviceCalendar());
    final notifier = app.container.read(exportControllerProvider.notifier);
    const from = CivilDate(2026, 10, 19);
    notifier.setRange(from, from.addDays(maxExportDays - 1));
    await tester.pumpAndSettle();
    expect(stateOf(app).rangeCut, isFalse);
    expect(byKey('export-clamped'), findsNothing);

    notifier.setRange(from, from.addDays(maxExportDays));
    await tester.pumpAndSettle();
    expect(stateOf(app).rangeCut, isTrue);
    expect(byKey('export-clamped'), findsOneWidget);
  });
}
