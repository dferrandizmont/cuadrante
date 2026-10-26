import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/calendar_export/application/export_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';
import '../import/import_ui_support.dart';

void main() {
  setUpAll(initializeLocale);
  for (final reduced in [false, true]) {
    testWidgets('export scroll respects disableAnimations=$reduced', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final app = await AppUnderTest.pump(
        tester,
        size: const Size(390, 720),
        overrides: importOverrides(
          phone: FakeDeviceCalendar(),
          picker: FakePicker(),
        ),
      );
      await app.openSettings();
      await tapKey(tester, 'settings-export-calendar');
      final start = find.byKey(const ValueKey('export-start'));
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      final result = find.byKey(const ValueKey('export-result'));
      for (var i = 0; i < 100 && result.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(result, findsOneWidget);
      expect(app.container.read(exportControllerProvider).result, isNotNull);
      final scroll = Scrollable.of(tester.element(result)).position;
      expect(scroll.activity is DrivenScrollActivity, !reduced);
      if (reduced) {
        final after = scroll.pixels;
        await tester.pump(const Duration(milliseconds: 50));
        expect(scroll.pixels, after, reason: 'the jump has already finished');
        final rect = tester.getRect(result);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(720));
      }
      await tester.pumpAndSettle();
    });
  }
}
