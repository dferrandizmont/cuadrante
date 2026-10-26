import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/icons/app_icons.dart';
import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/data/alarm_settings_repository.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/core/widgets/value_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../backup/backup_ui_support.dart';

/// On a real phone the values of the settings rows («Mi cuadrante»,
/// «Lunes», «Catalunya»...) floated in the middle of the row with their
/// chevron, off the column of chevrons of the rows without a value: the
/// title was `Expanded` and the value `Flexible`, both flex 1.
void main() {
  setUpAll(initializeLocale);

  // Tall enough for the whole screen without scrolling.
  const tall = Size(390, 2400);

  /// Value texts of the rows (one line, ellipsized, right-aligned) and the
  /// chevrons of the rows, as they are laid out on screen.
  List<Rect> chevrons(WidgetTester tester) => [
    for (final element
        in find
            .byWidgetPredicate(
              (w) => w is Icon && w.icon == AppIcons.chevronRight,
            )
            .evaluate())
      tester.getRect(find.byElementPredicate((e) => e == element)),
  ];

  List<(String, Rect)> values(WidgetTester tester) => [
    for (final element
        in find
            .descendant(
              of: find.byType(ValueRowValue),
              matching: find.byType(Text),
            )
            .evaluate())
      (
        (element.widget as Text).data ?? '',
        tester.getRect(find.byElementPredicate((e) => e == element)),
      ),
  ];

  /// Every chevron of the screen is at the same x, and each value ends just
  /// before the chevron of its row (the one it shares a line with).
  void expectFlush(WidgetTester tester, {required String where}) {
    final marks = chevrons(tester);
    expect(marks, isNotEmpty, reason: '$where: rows with a chevron');
    for (final mark in marks) {
      expect(
        mark.right,
        closeTo(marks.first.right, 0.5),
        reason: '$where: every chevron at the same x',
      );
    }
    for (final (text, box) in values(tester)) {
      final mark = marks.where(
        (m) => m.center.dy >= box.top && m.center.dy <= box.bottom,
      );
      if (mark.isEmpty) {
        // Stacked under its title (H-T11-6): the test font is twice as wide
        // as a real one, so long rows stack here. The value must still stay
        // clear of the column of chevrons.
        final row = marks.reduce(
          (a, b) =>
              (a.center.dy - box.center.dy).abs() <
                  (b.center.dy - box.center.dy).abs()
              ? a
              : b,
        );
        expect(
          box.right,
          lessThanOrEqualTo(row.left),
          reason: '$where: stacked «$text» clear of its chevron',
        );
        continue;
      }
      expect(mark, hasLength(1), reason: '$where: «$text» has its chevron');
      expect(
        box.right,
        closeTo(mark.single.left - Sp.xs, 0.5),
        reason: '$where: «$text» ends just before its chevron',
      );
    }
  }

  testWidgets('Settings: every chevron is at the same x, values flush', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(tester, size: tall);
    await app.openSettings();

    // Rows with a value («Mi cuadrante», «Sistema», «Lunes»...) and rows
    // without one («Mis turnos») are both there.
    final shown = {for (final (text, _) in values(tester)) text};
    expect(shown, containsAll(['Mi cuadrante', 'Sistema (claro)', 'Lunes']));
    expect(find.text('Mis turnos'), findsOneWidget);

    expectFlush(tester, where: 'Ajustes');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Alarmas: value rows are flush right', (tester) async {
    final app = await AppUnderTest.pump(
      tester,
      size: tall,
      overrides: [
        alarmSchedulerProvider.overrideWithValue(FakeAlarmScheduler()),
      ],
      prepare: (db) => AlarmSettingsRepository(db).save(
        const AlarmSettings(
          enabled: true,
          byShiftType: {'night': AlarmTypeSettings(enabled: true)},
        ),
      ),
    );
    app.container.read(routerProvider).go(AppRoutes.settingsAlarms);
    await tester.pumpAndSettle();
    expect(values(tester), isNotEmpty);
    expectFlush(tester, where: 'Alarmas');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Copia de seguridad: rows with a chevron are flush right', (
    tester,
  ) async {
    await BackupUiHarness(tester).open();
    expectFlush(tester, where: 'Copia de seguridad');
    expect(tester.takeException(), isNull);
  });

  for (final entry in {
    'Calendarios': AppRoutes.settingsCalendars,
    'Festivos': AppRoutes.settingsHolidays,
    'Importar': AppRoutes.settingsImport,
    'Exportar': AppRoutes.settingsExport,
  }.entries) {
    testWidgets('${entry.key}: rows with a chevron are flush right', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      app.container.read(routerProvider).go(entry.value);
      await tester.pumpAndSettle();
      // A screen without value rows has nothing to check.
      if (chevrons(tester).isNotEmpty) {
        expectFlush(tester, where: entry.key);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 412.0]) {
    testWidgets('Settings at $width dp with large text: no overflow', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      final app = await AppUnderTest.pump(tester, size: Size(width, 2400));
      await app.openSettings();
      expectFlush(tester, where: 'Ajustes $width');
      expect(tester.takeException(), isNull);
    });
  }
}
