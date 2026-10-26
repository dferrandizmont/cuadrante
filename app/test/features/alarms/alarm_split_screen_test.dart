import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/data/alarm_settings_repository.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/presentation/alarms_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// «Avisar también antes del segundo tramo» in Ajustes › Alarmas (A12).
void main() {
  setUpAll(initializeLocale);

  const tall = Size(390, 1800);
  late FakeAlarmScheduler scheduler;

  setUp(() => scheduler = FakeAlarmScheduler());

  Future<AppUnderTest> openAlarms(WidgetTester tester) async {
    scheduler.permission = AlarmPermission.granted;
    final app = await AppUnderTest.pump(
      tester,
      size: tall,
      overrides: [alarmSchedulerProvider.overrideWithValue(scheduler)],
      // Mañana becomes a split shift: 09:00-13:00 and 17:00-21:00.
      prepare: (db) => db.customStatement(
        'UPDATE shift_types SET start_minute = 540, end_minute = 780, '
        'segment2_start_minute = 1020, segment2_duration_minutes = 240 '
        "WHERE id = 'morning'",
      ),
    );
    await app.openSettings();
    await tester.ensureVisible(_key('settings-alarms'));
    await tester.tap(_key('settings-alarms'));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmsSettingsScreen), findsOneWidget);
    return app;
  }

  Future<void> tapAndSettle(WidgetTester tester, String key) async {
    await tester.ensureVisible(_key(key));
    await tester.pumpAndSettle();
    await tester.tap(_key(key));
    await tester.pumpAndSettle();
  }

  Future<AlarmSettings> stored(AppUnderTest app) =>
      app.real(() => AlarmSettingsRepository(app.database).load());

  testWidgets('only a split type shows the switch, on by default; it is '
      'stored', (tester) async {
    final app = await openAlarms(tester);
    await tapAndSettle(tester, 'alarms-master-switch');
    await tapAndSettle(tester, 'alarms-type-switch-morning');
    await tapAndSettle(tester, 'alarms-type-switch-afternoon');

    expect(_key('alarms-second-switch-morning'), findsOneWidget);
    expect(find.text('Avisar también antes del segundo tramo'), findsOneWidget);
    expect(
      tester.widget<Switch>(_key('alarms-second-switch-morning')).value,
      isTrue,
    );
    // The afternoon shift is a normal one: nothing to ask.
    expect(_key('alarms-second-switch-afternoon'), findsNothing);
    // The time line of the type shows both ranges.
    expect(find.text('09:00–13:00 · 17:00–21:00'), findsOneWidget);

    await tapAndSettle(tester, 'alarms-second-switch-morning');
    expect(
      tester.widget<Switch>(_key('alarms-second-switch-morning')).value,
      isFalse,
    );
    final settings = await stored(app);
    expect(settings.forShiftType('morning').secondSegment, isFalse);
    expect(settings.forShiftType('morning').enabled, isTrue);

    await tapAndSettle(tester, 'alarms-second-switch-morning');
    expect((await stored(app)).forShiftType('morning').secondSegment, isTrue);
  });
}
