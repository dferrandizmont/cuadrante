import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'test_storage.dart';
import 'spanish_phone.dart';

/// Monday 19 October 2026, midday: the fixed "now" of these tests.
final DateTime harnessNow = DateTime(2026, 10, 19, 12);
const CivilDate harnessToday = CivilDate(2026, 10, 19);

/// The whole app on a phone-sized surface, on an in-memory database seeded
/// like `bootstrapApp` does (demo data around [harnessNow]).
///
/// [prepare] runs against the database before the app starts, with real
/// async (create a second calendar, store a preference...); the app then
/// loads the calendar that is stored as active.
class AppUnderTest {
  AppUnderTest._(this.tester, this.storage);

  final WidgetTester tester;
  final TestStorage storage;

  AppDatabase get database => storage.database;

  ProviderContainer get container =>
      ProviderScope.containerOf(tester.element(find.byType(CuadranteApp)));

  /// The theme in use right now.
  ThemeData get theme => Theme.of(tester.element(find.byType(Scaffold).first));

  ScheduleState get schedule => container.read(scheduleControllerProvider);

  /// Runs [action] outside fake time (database work).
  Future<T> real<T>(Future<T> Function() action) async =>
      (await tester.runAsync(action)) as T;

  /// The back arrow of the app bar.
  Future<void> back() async {
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
  }

  /// Opens the Settings screen from the month screen.
  Future<void> openSettings() async {
    await tester.tap(find.byTooltip('Abrir ajustes'));
    await tester.pumpAndSettle();
  }

  /// Settings -> Calendarios.
  Future<void> openCalendars() async {
    await openSettings();
    await tester.tap(find.byKey(const ValueKey('settings-calendars')));
    await tester.pumpAndSettle();
  }

  static Future<AppUnderTest> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    Brightness platformBrightness = Brightness.light,
    Future<void> Function(AppDatabase database)? prepare,
    List<Override> overrides = const [],
    // Replaces the fixed clock (a test that moves time).
    DateTime Function()? clock,
    // False when [overrides] replace the router with another start screen.
    bool expectMonth = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.platformBrightnessTestValue = platformBrightness;
    useSpanishPhone(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearAllTestValues();
    });
    final storage = await openTestStorage(tester, now: harnessNow);
    if (prepare != null) {
      await tester.runAsync(() => prepare(storage.database));
    }
    final snapshot = (await tester.runAsync(() async {
      final calendars = CalendarsRepository(storage.database);
      return ScheduleRepository(
        storage.database,
        now: () => harnessNow,
      ).load(await calendars.activeId());
    }))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(storage.database),
          initialScheduleProvider.overrideWithValue(snapshot),
          clockProvider.overrideWithValue(clock ?? () => harnessNow),
          ...overrides,
        ],
        child: const CuadranteApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (expectMonth) expect(find.byType(MonthScreen), findsOneWidget);
    return AppUnderTest._(tester, storage);
  }
}

/// A second calendar called [name] with a rotation and a day of its own, so
/// its grid looks different from `main`'s. Returns its id.
Future<String> addSecondCalendar(
  AppDatabase database, {
  String name = 'Pareja',
  int colorValue = 0xFF30A46C,
}) async {
  final calendars = CalendarsRepository(database);
  final id = (await calendars.create(name: name, colorValue: colorValue)).id;
  await ScheduleRepository(database, now: () => harnessNow).apply(
    id,
    ScheduleChange(
      patch: EntriesPatch({
        harnessToday: EntryChange(
          null,
          DayEntry(date: harnessToday, shiftTypeIds: const ['vacation']),
        ),
      }),
    ),
  );
  return id;
}

/// Finder of the month-grid cell of [date].
Finder dayCell(CivilDate date) => find.byKey(ValueKey('day-${date.toIso()}'));

/// [matching] inside the cell of [date].
Finder inDayCell(CivilDate date, Finder matching) =>
    find.descendant(of: dayCell(date), matching: matching);
