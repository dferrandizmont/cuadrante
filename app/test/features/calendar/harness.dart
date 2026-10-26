import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';
import '../../support/spanish_phone.dart';

/// Monday 19 October 2026, midday.
final fixedNow = DateTime(2026, 10, 19, 12);
const fixedToday = CivilDate(2026, 10, 19);

/// Pumps the whole app on a phone-sized surface with a fixed clock.
Future<void> pumpCalendar(
  WidgetTester tester, {
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
  Size size = const Size(390, 844),
  // The language of the phone: the app follows it (Ajustes › Idioma ›
  // Sistema). Spanish by default.
  Locale? locale,
  // Replaces the fixed clock (a test that moves time, or sets another hour).
  // The demo data is still seeded around [fixedNow].
  DateTime Function()? clock,
  // Extra overrides (a repository that fails, a recording crash reporter...).
  List<Override> overrides = const [],
  // Runs against the seeded database before the app starts (archive a shift
  // type, store a note...); the app then loads what is stored.
  Future<void> Function(ScheduleRepository repository)? prepare,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  if (locale == null) {
    useSpanishPhone(tester);
  } else {
    tester.platformDispatcher.localesTestValue = [locale];
    tester.platformDispatcher.localeTestValue = locale;
    addTearDown(() {
      tester.platformDispatcher.clearLocalesTestValue();
      tester.platformDispatcher.clearLocaleTestValue();
    });
  }
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearAllTestValues();
  });
  var storage = await openTestStorage(tester, now: fixedNow);
  if (prepare != null) {
    await tester.runAsync(() => prepare(storage.repository));
    storage = (await tester.runAsync(storage.withReloadedSnapshot))!;
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storage.overrides,
        clockProvider.overrideWithValue(clock ?? () => fixedNow),
        ...overrides,
      ],
      child: const CuadranteApp(),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MonthScreen)));

Schedule scheduleOf(WidgetTester tester) =>
    containerOf(tester).read(scheduleControllerProvider).schedule;

/// Shift ids of [date] joined with `+` (`''` when empty).
String idsOn(Schedule schedule, CivilDate date) =>
    schedule.resolve(date).shiftIds.join('+');

PaintController paintOf(WidgetTester tester) =>
    containerOf(tester).read(paintControllerProvider.notifier);

/// The date line of the header: the long form ("Lunes, 19 de octubre") or,
/// when that does not fit, the short one ("Lun 19 oct"). The test font is as
/// wide as it is tall, so which one shows depends on the screen.
Finder get dateLine => find.byKey(const ValueKey('month-date'));

String dateLineText(WidgetTester tester) => tester.widget<Text>(dateLine).data!;

/// Scrolls the month screen until the cell of [date] is on screen. On a small
/// screen with large text the top (date, card, tip) pushes the lower rows out
/// of the build range, so a plain `ensureVisible` has nothing to find.
Future<void> revealCell(WidgetTester tester, CivilDate date) =>
    revealOnMonth(tester, cell(date));

/// Same for any widget of the month screen: drags the screen up until
/// [finder] has been built, then brings it into view.
Future<void> revealOnMonth(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Finder cell(CivilDate date) => find.byKey(ValueKey('day-${date.toIso()}'));

Future<void> enterPaintMode(WidgetTester tester) async {
  await tester.tap(find.text('Pintar'));
  await tester.pumpAndSettle();
}
