import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/features/calendar/application/month_presentation.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/month_presentation_control.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';

class _FixedSchedule extends ScheduleController {
  _FixedSchedule(this.schedule);
  final Schedule schedule;
  @override
  ScheduleState build() => ScheduleState(schedule: schedule);
}

void main() {
  setUpAll(() async {
    await initializeLocale();
    expect(await loadRoboto(), isTrue);
  });

  const month = CivilDate(2026, 10, 1);
  for (final weeks in [false, true]) {
    for (final width in [
      320.0,
      360.0,
      363.0,
      364.0,
      365.0,
      387.0,
      388.0,
      389.0,
      412.0,
      549.0,
      840.0,
    ]) {
      testWidgets(
        '$width dp, weeks=$weeks: exact 48 dp boundary, recommendation never selects',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 700);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          for (final scale in [1.0, 1.3, 1.5, 2.0]) {
            final container = ProviderContainer(
              overrides: [
                clockProvider.overrideWithValue(() => DateTime(2026, 10, 19)),
                scheduleControllerProvider.overrideWith(
                  () => _FixedSchedule(Schedule()),
                ),
                initialPreferencesProvider.overrideWithValue(
                  Preferences.defaults.copyWith(weekNumbers: weeks),
                ),
              ],
            );
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  locale: const Locale('es'),
                  theme: AppTheme.light(),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: const Scaffold(body: MonthPresentationControl()),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final expected =
                (width - 28 - (weeks ? 24 : 0)) / 7 < 48 || scale >= 1.5;
            expect(
              find.byKey(const ValueKey('month-list-recommendation')),
              expected ? findsOneWidget : findsNothing,
            );
            expect(
              container.read(monthPresentationProvider),
              MonthPresentation.grid,
            );
            for (final presentation in ['grid', 'list']) {
              final control = find.byKey(
                ValueKey('month-presentation-$presentation'),
              );
              expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
              expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
            }
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            container.dispose();
          }
        },
      );
    }
  }

  testWidgets(
    'measured WWW/split times and multiple shifts recommend the list on a wide panel',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 700);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final shift = ShiftType(
        id: 'w',
        code: 'WWW',
        name: 'Turno',
        colorValue: ShiftPalette.morning.toARGB32(),
        category: ShiftCategory.work,
        startMinute: 570,
        endMinute: 780,
        segment2StartMinute: 1035,
        segment2DurationMinutes: 225,
      );
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 19)),
          initialPreferencesProvider.overrideWithValue(Preferences.defaults),
          scheduleControllerProvider.overrideWith(
            () => _FixedSchedule(
              Schedule(
                shiftTypes: [shift],
                entries: {
                  month: const DayEntry(date: month, shiftTypeIds: ['w']),
                },
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('es'),
            theme: AppTheme.light(),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: MonthPresentationControl()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('month-list-recommendation')),
        findsOneWidget,
      );
      expect(container.read(monthPresentationProvider), MonthPresentation.grid);
    },
  );
}
