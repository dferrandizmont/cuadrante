import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/presentation/compare_screen.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/settings/data/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// October 2026 in the demo data: "Mi cuadrante" works on 19 days (20 shifts)
/// and "Pareja" (see `addSecondCalendar`) only has a vacation day on the 19th,
/// so the days free in both are the 12 days "Mi cuadrante" does not work.
const _oct19 = CivilDate(2026, 10, 19); // Noche | Vacaciones
const _oct21 = CivilDate(2026, 10, 21); // Mañana + Tarde | nothing
const _oct22 = CivilDate(2026, 10, 22); // cleared by hand | nothing
const _oct24 = CivilDate(2026, 10, 24); // Libre | nothing
const _oct27 = CivilDate(2026, 10, 27); // Vacaciones | nothing

void main() {
  setUpAll(initializeLocale);

  Future<AppUnderTest> open(
    WidgetTester tester, {
    Future<void> Function(AppDatabase db)? prepare,
    Size size = const Size(390, 844),
    String location = AppRoutes.compare,
  }) async {
    final app = await AppUnderTest.pump(
      tester,
      size: size,
      prepare: (db) async {
        await addSecondCalendar(db);
        if (prepare != null) await prepare(db);
      },
    );
    app.container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
    return app;
  }

  String text(WidgetTester tester, String key) =>
      tester.widget<Text>(_key(key)).data!;

  Finder inBand(String band, CivilDate date, String code) => find.descendant(
    of: _key('compare-$band-${date.toIso()}'),
    matching: find.text(code),
  );

  group('the screen', () {
    testWidgets('opens on the calendar on screen and the next one', (
      tester,
    ) async {
      await open(tester);
      expect(find.byType(CompareScreen), findsOneWidget);
      expect(find.text('Comparar calendarios'), findsWidgets);
      expect(
        find.descendant(
          of: _key('compare-first'),
          matching: find.text('Mi cuadrante'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _key('compare-second'),
          matching: find.text('Pareja'),
        ),
        findsOneWidget,
      );
      expect(text(tester, 'compare-month'), 'Octubre 2026');
    });

    testWidgets('shows the shifts of both calendars in every day', (
      tester,
    ) async {
      await open(tester);
      // 19 October: Noche for the first, Vacaciones for the second.
      expect(inBand('a', _oct19, 'N'), findsOneWidget);
      expect(inBand('b', _oct19, 'V'), findsOneWidget);
      // 21 October: Mañana + Tarde, and nothing (a dash) for the second.
      expect(inBand('a', _oct21, 'M+T'), findsOneWidget);
      expect(inBand('b', _oct21, '–'), findsOneWidget);
      // 24 October: Libre (a rest shift) is shown, not hidden.
      expect(inBand('a', _oct24, 'L'), findsOneWidget);
    });

    testWidgets('marks the days free in both and counts them', (tester) async {
      await open(tester);
      expect(text(tester, 'compare-count'), '12 días libres en común este mes');
      // Free in both: a rest day, a day cleared by hand, a vacation day.
      for (final date in [_oct22, _oct24, _oct27]) {
        expect(_key('compare-free-${date.toIso()}'), findsOneWidget);
      }
      // Busy in the first (a Noche, a double day), or vacation in the second
      // does not help: the first works.
      for (final date in [_oct19, _oct21]) {
        expect(_key('compare-free-${date.toIso()}'), findsNothing);
      }
      // The mark is a check, not just a colour.
      expect(
        find.descendant(
          of: _key('compare-free-${_oct22.toIso()}'),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
      );
    });

    testWidgets('lists the dates of the free days', (tester) async {
      await open(tester);
      final pills = find.descendant(
        of: _key('compare-free-list'),
        matching: find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(
                'compare-free-date-',
              ),
        ),
      );
      expect(pills, findsNWidgets(12));
      expect(_key('compare-free-date-2026-10-22'), findsOneWidget);
      expect(_key('compare-free-date-2026-10-19'), findsNothing);
      expect(find.text('jue 22 oct'), findsOneWidget);
      expect(find.text('vie 23 oct'), findsNothing, reason: 'a Noche');
    });

    testWidgets('the days of the neighbouring months are never marked', (
      tester,
    ) async {
      await open(tester);
      // 28 September is on the grid (Monday-first) and free in both.
      expect(_key('compare-day-2026-09-28'), findsOneWidget);
      expect(_key('compare-free-2026-09-28'), findsNothing);
    });
  });

  group('month navigation', () {
    testWidgets('the arrows change the month and the figures', (tester) async {
      await open(tester);
      await tester.tap(_key('compare-next'));
      await tester.pumpAndSettle();
      expect(text(tester, 'compare-month'), 'Noviembre 2026');
      final november = text(tester, 'compare-count');
      expect(november, endsWith('días libres en común este mes'));
      expect(november, isNot('12 días libres en común este mes'));
      await tester.tap(_key('compare-previous'));
      await tester.pumpAndSettle();
      await tester.tap(_key('compare-previous'));
      await tester.pumpAndSettle();
      expect(text(tester, 'compare-month'), 'Septiembre 2026');
    });

    testWidgets('a swipe changes the month too', (tester) async {
      await open(tester);
      await tester.fling(
        _key('compare-grid'),
        const Offset(-400, 0),
        1500,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(text(tester, 'compare-month'), 'Noviembre 2026');
      await tester.fling(
        _key('compare-grid'),
        const Offset(400, 0),
        1500,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(text(tester, 'compare-month'), 'Octubre 2026');
    });

    testWidgets('the link chooses the month and the calendars', (tester) async {
      final app = await open(tester);
      final second = (await app.real(
        () => CalendarsRepository(app.database).list(),
      )).last.id;
      app.container
          .read(routerProvider)
          .go('${AppRoutes.compare}?mes=2026-11&a=$second&b=main');
      await tester.pumpAndSettle();
      expect(text(tester, 'compare-month'), 'Noviembre 2026');
      expect(
        find.descendant(
          of: _key('compare-first'),
          matching: find.text('Pareja'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _key('compare-second'),
          matching: find.text('Mi cuadrante'),
        ),
        findsOneWidget,
      );
      // A bad month falls back to the current one.
      app.container.read(routerProvider).go('${AppRoutes.compare}?mes=nope');
      await tester.pumpAndSettle();
      expect(text(tester, 'compare-month'), 'Octubre 2026');
    });
  });

  group('choosing the calendars', () {
    testWidgets('a third calendar can take the second place', (tester) async {
      late String third;
      final app = await open(
        tester,
        prepare: (db) async {
          third = (await CalendarsRepository(
            db,
          ).create(name: 'Hijo', colorValue: 0xFF1C7ED6)).id;
        },
      );
      expect(third, isNotEmpty);
      await tester.tap(_key('compare-second'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Hijo'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _key('compare-second'),
          matching: find.text('Hijo'),
        ),
        findsOneWidget,
      );
      // "Hijo" is empty: every day is free for it, so the free days of the
      // first calendar are all in common.
      expect(text(tester, 'compare-count'), '12 días libres en común este mes');
      // Nothing was switched.
      expect(app.schedule.calendarId, 'main');
    });

    testWidgets('choosing the one the other place has swaps them', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(_key('compare-first'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Pareja'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _key('compare-first'),
          matching: find.text('Pareja'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _key('compare-second'),
          matching: find.text('Mi cuadrante'),
        ),
        findsOneWidget,
      );
      // Bands follow: the first band is now the second calendar's.
      expect(inBand('a', _oct19, 'V'), findsOneWidget);
      expect(inBand('b', _oct19, 'N'), findsOneWidget);
    });

    testWidgets('the calendar on screen can be the second place', (
      tester,
    ) async {
      final app = await open(tester);
      // Put "Pareja" on screen: it becomes the first place by default.
      await app.container
          .read(scheduleControllerProvider.notifier)
          .switchCalendar(
            (await app.real(() => CalendarsRepository(app.database).list()))
                .last
                .id,
          );
      await tester.pumpAndSettle();
      app.container.read(routerProvider).go('/comparar?x=1');
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _key('compare-first'),
          matching: find.text('Pareja'),
        ),
        findsOneWidget,
      );
      // The next after the last wraps to the first calendar.
      expect(
        find.descendant(
          of: _key('compare-second'),
          matching: find.text('Mi cuadrante'),
        ),
        findsOneWidget,
      );
    });
  });

  group('with fewer than two calendars', () {
    testWidgets('says what is needed and goes to create one', (tester) async {
      final app = await AppUnderTest.pump(tester);
      app.container.read(routerProvider).go(AppRoutes.compare);
      await tester.pumpAndSettle();
      expect(_key('compare-need-two'), findsOneWidget);
      expect(find.text('Necesitas dos calendarios'), findsOneWidget);
      await tester.tap(find.text('Nuevo calendario'));
      await tester.pumpAndSettle();
      expect(_key('calendars-add'), findsOneWidget);
    });
  });

  group('the way in', () {
    testWidgets('Ajustes › Calendarios has the button only with two or more', (
      tester,
    ) async {
      final one = await AppUnderTest.pump(tester);
      await one.openCalendars();
      expect(_key('calendars-compare'), findsNothing);
    });

    testWidgets('Ajustes › Calendarios › Comparar calendarios', (tester) async {
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) async => addSecondCalendar(db),
      );
      await app.openCalendars();
      await tester.ensureVisible(_key('calendars-compare'));
      await tester.tap(_key('calendars-compare'));
      await tester.pumpAndSettle();
      expect(find.byType(CompareScreen), findsOneWidget);
    });

    testWidgets('the calendar switcher of the month has the same entry', (
      tester,
    ) async {
      await AppUnderTest.pump(
        tester,
        prepare: (db) async => addSecondCalendar(db),
      );
      await tester.tap(_key('calendar-switcher'));
      await tester.pumpAndSettle();
      expect(_key('calendar-switcher-compare'), findsOneWidget);
      await tester.tap(_key('calendar-switcher-compare'));
      await tester.pumpAndSettle();
      expect(find.byType(CompareScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('settings that apply', () {
    testWidgets('weeks start on Sunday when the user chose it', (tester) async {
      await open(
        tester,
        prepare: (db) => PreferencesRepository(db).setWeekStart(7),
      );
      final order = <MapEntry<double, int>>[
        for (var weekday = 1; weekday <= 7; weekday++)
          MapEntry(
            tester.getCenter(_key('compare-weekday-$weekday')).dx,
            weekday,
          ),
      ]..sort((a, b) => a.key.compareTo(b.key));
      expect([for (final e in order) e.value], [7, 1, 2, 3, 4, 5, 6]);
      // The first cell of the grid is Sunday 27 September.
      expect(_key('compare-day-2026-09-27'), findsOneWidget);
      final first = tester.getCenter(_key('compare-day-2026-09-27'));
      final second = tester.getCenter(_key('compare-day-2026-09-28'));
      expect(first.dx, lessThan(second.dx));
      expect(first.dy, second.dy);
    });
  });

  group('it is read-only', () {
    testWidgets('nothing is written and the calendar on screen stays', (
      tester,
    ) async {
      final app = await open(tester);
      final before = await app.real(
        () => app.database.customSelect('SELECT * FROM day_entries').get(),
      );
      await tester.tap(_key('compare-next'));
      await tester.pumpAndSettle();
      await tester.tap(_key('compare-second'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      final after = await app.real(
        () => app.database.customSelect('SELECT * FROM day_entries').get(),
      );
      expect(after.length, before.length);
      expect(app.schedule.calendarId, 'main');
      expect(app.schedule.canUndo, isFalse);
    });
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.6),
    (const Size(390, 844), 1.0),
    (const Size(768, 1024), 1.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('fits ${size.width.toInt()}x${size.height.toInt()} '
        'x$scale without overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      await open(tester, size: size);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _key('compare-summary'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(_key('compare-free-list'), findsOneWidget);
    });
  }
}
