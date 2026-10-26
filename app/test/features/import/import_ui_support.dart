import 'dart:convert';
import 'dart:typed_data';

import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar_export/application/device_calendar_providers.dart';
import 'package:cuadrante/features/import/application/import_providers.dart';
import 'package:cuadrante/features/import/data/import_file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';

/// Tall enough for the settings screen without scrolling.
const Size importTestSize = Size(390, 1800);

Finder byKey(String key) => find.byKey(ValueKey(key));

/// What the file picker hands back in a test: set [next] before tapping.
class FakePicker {
  PickedImportFile? next;
  final List<ImportFileKind> asked = [];

  Future<PickedImportFile?> call(ImportFileKind kind) async {
    asked.add(kind);
    return next;
  }
}

PickedImportFile fileOf(String name, String text) =>
    PickedImportFile.bytes(name, Uint8List.fromList(utf8.encode(text)));

/// The overrides every import test needs: the fake phone calendar, the fake
/// picker, inline "isolates", Madrid as the phone zone and ids `new-1`...
List<Override> importOverrides({
  required FakeDeviceCalendar phone,
  required FakePicker picker,
  ImportRunner? runner,
}) {
  var ids = 0;
  return [
    deviceCalendarApiProvider.overrideWithValue(phone),
    importFilePickerProvider.overrideWithValue(picker.call),
    importRunnerProvider.overrideWithValue(
      runner ?? <T>(T Function() computation) async => computation(),
    ),
    importTimeZoneProvider.overrideWithValue(() async => 'Europe/Madrid'),
    importIdGeneratorProvider.overrideWithValue(() => 'new-${++ids}'),
  ];
}

/// The app opened on the import screen (Ajustes › Importar turnos).
Future<AppUnderTest> openImport(
  WidgetTester tester, {
  required FakeDeviceCalendar phone,
  required FakePicker picker,
  ImportRunner? runner,
  List<Override> overrides = const [],
}) async {
  final app = await AppUnderTest.pump(
    tester,
    size: importTestSize,
    overrides: [
      ...importOverrides(phone: phone, picker: picker, runner: runner),
      ...overrides,
    ],
  );
  await app.openSettings();
  await tester.tap(byKey('settings-import'));
  await tester.pumpAndSettle();
  return app;
}

/// Taps [finder] (scrolled into view first) and settles.
Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = byKey(key);
  expect(finder, findsOneWidget, reason: key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Waits for the writes of the editor to reach the database.
Future<void> flush(AppUnderTest app) => app.real(
  () => app.container.read(scheduleControllerProvider.notifier).pendingWrites,
);

String stepOf(WidgetTester tester) =>
    (tester.widget(byKey('import-step-of')) as Text).data!;

/// A phone with one calendar of shifts, for the wizard tests.
///
/// Around the demo rotation of the harness (Noche 9-13 Nov, Libre 14-15 Nov):
/// - «Mañana» 06:00-14:00 on 9 and 10 Nov (over the rotation: a conflict);
/// - «Libre» all day on 14 and 15 Nov (the same as the rotation);
/// - «Refuerzo» 09:00-17:00 on 20 to 23 Nov (no shift type of that name);
/// - «Cita médico» once on 24 Nov;
/// - one «Mañana» outside the default range.
FakeDeviceCalendar phoneWithShifts() {
  final phone = FakeDeviceCalendar();
  final id = phone.addCalendar(
    'Turnos',
    account: 'yo@example.com',
    color: 0xFF1C7ED6,
  );
  phone.addCalendar('Cumpleaños', account: 'yo@example.com', readOnly: true);
  phone.addCalendar('Oculto', hidden: true);
  for (final day in [9, 10]) {
    phone.addSimpleEvent(
      id,
      'Mañana',
      DateTime(2026, 11, day, 6),
      DateTime(2026, 11, day, 14),
    );
  }
  for (final day in [14, 15]) {
    phone.addSimpleEvent(
      id,
      'Libre',
      DateTime(2026, 11, day),
      DateTime(2026, 11, day + 1),
      allDay: true,
    );
  }
  for (final day in [20, 21, 22, 23]) {
    phone.addSimpleEvent(
      id,
      'Refuerzo',
      DateTime(2026, 11, day, 9),
      DateTime(2026, 11, day, 17),
    );
  }
  phone.addSimpleEvent(
    id,
    'Cita médico',
    DateTime(2026, 11, 24, 10),
    DateTime(2026, 11, 24, 11),
  );
  phone.addSimpleEvent(
    id,
    'Mañana',
    DateTime(2030, 1, 7, 6),
    DateTime(2030, 1, 7, 14),
  );
  return phone;
}
