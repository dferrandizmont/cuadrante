import 'package:cuadrante/features/calendar_export/application/device_calendar_providers.dart';
import 'package:cuadrante/features/holidays/data/holiday_repository.dart';
import 'package:cuadrante/features/holidays/domain/holiday_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';

Finder importKey(String key) => find.byKey(ValueKey(key));

Future<void> importTap(WidgetTester tester, String key) async {
  final finder = importKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<AppUnderTest> openHolidayImport(
  WidgetTester tester,
  FakeDeviceCalendar phone, {
  Size size = const Size(390, 1800),
  Brightness brightness = Brightness.light,
  Future<void> Function(HolidayRepository repository)? prepare,
  Future<void> Function()? beforeImport,
}) async {
  final app = await AppUnderTest.pump(
    tester,
    size: size,
    platformBrightness: brightness,
    prepare: prepare == null ? null : (db) => prepare(HolidayRepository(db)),
    overrides: [deviceCalendarApiProvider.overrideWithValue(phone)],
  );
  await app.openSettings();
  await importTap(tester, 'settings-holidays');
  await beforeImport?.call();
  await importTap(tester, 'holidays-import');
  return app;
}

Future<void> holidayPreview(WidgetTester tester, List<String> calendars) async {
  for (final id in calendars) {
    await importTap(tester, 'holiday-import-calendar-$id');
  }
  await importTap(tester, 'holiday-import-next');
  expect(importKey('holiday-import-step-1'), findsOneWidget);
  await importTap(tester, 'holiday-import-next');
  expect(importKey('holiday-import-step-2'), findsOneWidget);
}

Future<List<HolidayEntry>> importedRows(AppUnderTest app) =>
    app.real(() => HolidayRepository(app.database).userHolidays());

bool importNextEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(
          find.descendant(
            of: importKey('holiday-import-next'),
            matching: find.byType(FilledButton),
          ),
        )
        .onPressed !=
    null;
