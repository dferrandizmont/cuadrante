import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/widgets/adaptive.dart';
import 'package:cuadrante/features/calendar/application/open_day.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart';
import 'package:cuadrante/features/calendar/presentation/day_detail_sheet.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../onboarding/onboarding_support.dart' show FirstLaunch;
import 'harness.dart';

/// The two-pane month of wide screens (`docs/diseno.md`, «Pantallas anchas»):
/// when the panes appear, what each one holds, and that the open day, the
/// month, a note being typed and paint mode survive a rotation.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  // Demo data around Monday 19 Oct 2026: 20 Noche, 21 Mañana + Tarde (by
  // hand), 22 empty, 24 Libre, 26 Mañana.
  const oct20 = CivilDate(2026, 10, 20);
  const oct21 = CivilDate(2026, 10, 21);
  const oct22 = CivilDate(2026, 10, 22);
  const oct24 = CivilDate(2026, 10, 24);

  const phonePortrait = Size(412, 915);
  const phoneLandscape = Size(915, 412);
  const tabletLandscape = Size(1280, 800);
  const tabletPortrait = Size(800, 1280);

  Finder key(String k) => find.byKey(ValueKey(k));
  Finder inCell(CivilDate d, Finder matching) =>
      find.descendant(of: cell(d), matching: matching);
  final panes = key('pane-divider');
  final paneDetail = key('day-pane-close');
  final paneToday = key('pane-today');
  final sheet = find.byType(BottomSheet);

  /// Turns the window (a rotation) and lets the layout settle.
  Future<void> resize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * 3;
    await tester.pumpAndSettle();
  }

  Future<void> tapDay(WidgetTester tester, CivilDate date) async {
    await tester.ensureVisible(cell(date));
    await tester.pumpAndSettle();
    await tester.tap(cell(date));
    await tester.pumpAndSettle();
  }

  bool focused(WidgetTester tester, CivilDate date) =>
      tester.widget<DayCell>(cell(date)).focused;

  group('the breakpoint', () {
    test('two panes from 840 dp, or from 600 dp in landscape', () {
      bool split(double w, double h) => Adaptive.useSplit(Size(w, h));
      // Phones in portrait and the Pixel Tablet in portrait: one column.
      expect(split(412, 915), isFalse);
      expect(split(800, 1280), isFalse);
      expect(split(839, 1280), isFalse);
      // Expanded width: two panes whatever the orientation.
      expect(split(840, 1280), isTrue);
      expect(split(1024, 1366), isTrue);
      // Landscape from 600 dp: a landscape phone and a tablet.
      expect(split(915, 412), isTrue);
      expect(split(1280, 800), isTrue);
      expect(split(600, 400), isTrue);
      expect(split(599, 400), isFalse);
      // A square window is not landscape.
      expect(split(700, 700), isFalse);
      expect(split(700, 699), isTrue);
    });

    for (final (name, size, two) in [
      ('phone portrait', phonePortrait, false),
      ('phone landscape', phoneLandscape, true),
      ('tablet landscape', tabletLandscape, true),
      ('tablet portrait', tabletPortrait, false),
    ]) {
      testWidgets('$name ${size.width}x${size.height}: '
          '${two ? 'two panes' : 'one column'}', (tester) async {
        await pumpCalendar(tester, size: size);
        expect(panes, two ? findsOneWidget : findsNothing);
        // The "today" card and the next days are in the pane, or above the
        // month in one column.
        expect(find.text('ESTA NOCHE'), findsOneWidget);
        expect(key('upcoming-days'), two ? findsOneWidget : findsNothing);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    }

    testWidgets('the keyboard does not turn a portrait tablet into two panes', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletPortrait);
      tester.view.viewInsets = const FakeViewPadding(bottom: 1500);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(panes, findsNothing);
    });
  });

  group('layout without overflow', () {
    for (final size in [
      phonePortrait,
      phoneLandscape,
      tabletLandscape,
      tabletPortrait,
    ]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('${size.width}x${size.height}, text $scale: the month, '
            'a day, paint and selection', (tester) async {
          await pumpCalendar(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);

          // A day (a sheet or the pane).
          await tapDay(tester, oct21);
          expect(tester.takeException(), isNull);
          expect(
            find.text('Miércoles, 21 de octubre'),
            findsOneWidget,
            reason: 'the day shows its date',
          );
          // Leave it.
          if (sheet.evaluate().isNotEmpty) {
            await tester.tapAt(const Offset(10, 10));
          } else {
            await tester.tap(paneDetail);
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Paint mode: every row of the month can be reached.
          await enterPaintMode(tester);
          expect(tester.takeException(), isNull);
          final last = cell(const CivilDate(2026, 11, 8));
          final beforeNavigation = scheduleOf(tester);
          final viewport = find.byKey(const ValueKey('month-scroll'));
          for (
            var i = 0;
            i < 20 &&
                (last.hitTestable().evaluate().isEmpty ||
                    tester.getRect(last).bottom >
                        tester.getRect(viewport).bottom + 0.5);
            i++
          ) {
            await tester.tap(key('paint-scroll-down'));
            await tester.pumpAndSettle();
          }
          expect(last.hitTestable(), findsOneWidget);
          expect(
            tester.getRect(last).bottom,
            lessThanOrEqualTo(tester.getRect(viewport).bottom + 0.5),
            reason: 'paint navigation exposes the full last row',
          );
          expect(scheduleOf(tester), same(beforeNavigation));
          await tester.tap(find.text('Listo'));
          await tester.pumpAndSettle();

          // Selection mode.
          await revealCell(tester, oct24);
          await tester.longPress(cell(oct24));
          await tester.pumpAndSettle();
          expect(key('selection-bar'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('the left pane: the month', () {
    testWidgets('a landscape phone keeps the time under the code', (
      tester,
    ) async {
      await pumpCalendar(tester, size: phoneLandscape);
      expect(inCell(oct20, find.text('22–06')), findsOneWidget);
      expect(inCell(oct20, find.text('N')), findsOneWidget);
      // The month does not fit the 412 dp of height: it scrolls instead of
      // squeezing the cells.
      expect(
        tester.getSize(cell(oct20)).height,
        greaterThanOrEqualTo(dayCellHeightWithTime(tester.element(panes))),
      );
    });

    testWidgets('a tablet in landscape: the month fills the height', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletLandscape);
      // Six rows on screen, no scrolling needed.
      final last = tester.getRect(cell(const CivilDate(2026, 11, 8)));
      expect(last.bottom, lessThanOrEqualTo(tabletLandscape.height));
      expect(tester.getSize(cell(oct20)).width, greaterThan(100));
    });

    testWidgets('the right pane is as wide as a phone, up to 440 dp', (
      tester,
    ) async {
      await pumpCalendar(tester, size: phoneLandscape);
      final phone = tester.getSize(find.byType(FloatingActionButton)).width;
      expect(phone, greaterThan(0));
      expect(
        tester.getRect(key('pane-divider')).left,
        closeTo(phoneLandscape.width - 366, 1),
      );
      await resize(tester, tabletLandscape);
      expect(
        tester.getRect(key('pane-divider')).left,
        closeTo(tabletLandscape.width - 440, 1),
      );
    });
  });

  group('the right pane: today and the next days', () {
    testWidgets('the card, then the next 7 days with code, hours and notes', (
      tester,
    ) async {
      await pumpCalendar(tester, size: phoneLandscape);
      expect(paneToday, findsOneWidget);
      expect(find.text('ESTA NOCHE'), findsOneWidget);
      // Tomorrow to the 26th: seven rows.
      for (var d = 20; d <= 26; d++) {
        expect(key('upcoming-2026-10-$d'), findsOneWidget, reason: 'day $d');
      }
      expect(key('upcoming-2026-10-19'), findsNothing);
      expect(key('upcoming-2026-10-27'), findsNothing);
      final row21 = find.descendant(
        of: key('upcoming-2026-10-21'),
        matching: find.byType(Text),
      );
      final texts = [for (final t in row21.evaluate()) (t.widget as Text)];
      final all = texts
          .map((t) => t.data ?? t.textSpan!.toPlainText())
          .join('|');
      expect(all, contains('Mañana'));
      expect(all, contains('Tarde'));
      expect(all, contains('06:00–14:00'));
      // Day 20 has a note: its row says so.
      expect(
        find.descendant(
          of: key('upcoming-2026-10-20'),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
      );
      // No day open: nothing ringed in the grid.
      expect(focused(tester, oct21), isFalse);
    });

    testWidgets('a tap on a row opens that day in the pane', (tester) async {
      await pumpCalendar(tester, size: phoneLandscape);
      await tester.ensureVisible(key('upcoming-2026-10-21'));
      await tester.pumpAndSettle();
      await tester.tap(key('upcoming-2026-10-21'));
      await tester.pumpAndSettle();
      expect(paneDetail, findsOneWidget);
      expect(find.text('Miércoles, 21 de octubre'), findsOneWidget);
      expect(focused(tester, oct21), isTrue);
    });
  });

  group('the right pane: the day', () {
    testWidgets('a tap on a day shows it in the pane, ringed, no sheet', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletLandscape);
      await tapDay(tester, oct21);
      expect(sheet, findsNothing);
      expect(paneDetail, findsOneWidget);
      expect(paneToday, findsNothing);
      expect(find.text('Miércoles, 21 de octubre'), findsOneWidget);
      expect(key('day-shift-0'), findsOneWidget);
      expect(key('day-note'), findsOneWidget);
      expect(key('day-duplicate'), findsOneWidget);
      expect(focused(tester, oct21), isTrue);
      expect(focused(tester, oct22), isFalse);

      // Another day takes the ring and the pane.
      await tapDay(tester, oct22);
      expect(find.text('Jueves, 22 de octubre'), findsOneWidget);
      expect(focused(tester, oct22), isTrue);
      expect(focused(tester, oct21), isFalse);
    });

    testWidgets('the close button goes back to today', (tester) async {
      await pumpCalendar(tester, size: tabletLandscape);
      await tapDay(tester, oct21);
      await tester.tap(paneDetail);
      await tester.pumpAndSettle();
      expect(paneDetail, findsNothing);
      expect(paneToday, findsOneWidget);
      expect(focused(tester, oct21), isFalse);
    });

    testWidgets('the system back button closes the day, not the app', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletLandscape);
      await tapDay(tester, oct21);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(paneDetail, findsNothing);
      expect(paneToday, findsOneWidget);
    });

    testWidgets('adding a shift in the pane changes the grid; ONE undo', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletLandscape);
      await tapDay(tester, oct24);
      expect(idsOn(scheduleOf(tester), oct24), 'rest');
      await tester.ensureVisible(key('day-add-morning'));
      await tester.tap(key('day-add-morning'));
      await tester.pumpAndSettle();

      expect(idsOn(scheduleOf(tester), oct24), 'rest+morning');
      expect(inCell(oct24, find.text('M')), findsOneWidget);
      // The pane follows the change too.
      expect(key('day-shift-1'), findsOneWidget);

      containerOf(tester).read(scheduleControllerProvider.notifier).undo();
      await tester.pumpAndSettle();
      expect(idsOn(scheduleOf(tester), oct24), 'rest');
    });

    testWidgets('a note typed in the pane is saved with ONE undo step', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletLandscape);
      await tapDay(tester, oct22);
      await tester.ensureVisible(key('day-note'));
      await tester.enterText(key('day-note'), 'Cambio con Marta');
      await tester.pump();
      // Moving to another day saves it.
      await tapDay(tester, oct21);
      await tester.pumpAndSettle();
      expect(
        scheduleOf(tester).entries[oct22]?.note,
        'Cambio con Marta',
        reason: 'the note is written when the pane moves on',
      );

      containerOf(tester).read(scheduleControllerProvider.notifier).undo();
      await tester.pumpAndSettle();
      expect(scheduleOf(tester).entries[oct22]?.note, isNull);
    });

    testWidgets('«Borrar día» clears the day and goes back to today', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletLandscape);
      await tapDay(tester, oct21);
      await tester.ensureVisible(key('day-clear'));
      await tester.tap(key('day-clear'));
      await tester.pumpAndSettle();
      expect(idsOn(scheduleOf(tester), oct21), '');
      expect(paneDetail, findsNothing);
      expect(paneToday, findsOneWidget);
      expect(find.text('Día borrado'), findsWidgets);
    });
  });

  group('rotating', () {
    testWidgets('the open day and the month survive, as a sheet in portrait', (
      tester,
    ) async {
      await pumpCalendar(tester, size: phoneLandscape);
      // Next month, then a day of it.
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      const nov4 = CivilDate(2026, 11, 4);
      await tapDay(tester, nov4);
      expect(paneDetail, findsOneWidget);
      expect(find.text('Miércoles, 4 de noviembre'), findsOneWidget);

      await resize(tester, phonePortrait);
      expect(panes, findsNothing);
      expect(sheet, findsOneWidget);
      expect(
        tester.widget<DayDetailSheet>(find.byType(DayDetailSheet)).date,
        nov4,
      );
      expect(find.text('Miércoles, 4 de noviembre'), findsOneWidget);
      expect(
        containerOf(tester).read(visibleMonthProvider),
        const CivilDate(2026, 11, 1),
      );

      await resize(tester, phoneLandscape);
      expect(sheet, findsNothing);
      expect(panes, findsOneWidget);
      expect(paneDetail, findsOneWidget);
      expect(find.text('Miércoles, 4 de noviembre'), findsOneWidget);
      expect(containerOf(tester).read(openDayProvider), nov4);
      expect(
        containerOf(tester).read(visibleMonthProvider),
        const CivilDate(2026, 11, 1),
      );
      expect(focused(tester, nov4), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a sheet closed by the user in portrait stays closed', (
      tester,
    ) async {
      await pumpCalendar(tester, size: phonePortrait);
      await revealCell(tester, oct21);
      await tester.tap(cell(oct21));
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(containerOf(tester).read(openDayProvider), oct21);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(containerOf(tester).read(openDayProvider), isNull);

      await resize(tester, phoneLandscape);
      expect(paneToday, findsOneWidget);
      expect(paneDetail, findsNothing);
    });

    testWidgets('a note being typed goes through both rotations', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletLandscape);
      await tapDay(tester, oct22);
      await tester.ensureVisible(key('day-note'));
      await tester.enterText(key('day-note'), 'Llevar la tarjeta');
      await tester.pump();

      await resize(tester, tabletPortrait);
      expect(sheet, findsOneWidget);
      expect(
        tester.widget<TextField>(key('day-note')).controller!.text,
        'Llevar la tarjeta',
      );
      // Typed on in the sheet.
      await tester.enterText(key('day-note'), 'Llevar la tarjeta y el DNI');
      await tester.pump();

      await resize(tester, tabletLandscape);
      expect(sheet, findsNothing);
      expect(
        tester.widget<TextField>(key('day-note')).controller!.text,
        'Llevar la tarjeta y el DNI',
      );
      // Saved when the day is left, once.
      await tester.tap(paneDetail);
      await tester.pumpAndSettle();
      expect(
        scheduleOf(tester).entries[oct22]?.note,
        'Llevar la tarjeta y el DNI',
      );
      // Each face saved what it had when the window turned: two steps.
      final schedule = containerOf(tester)
          .read(scheduleControllerProvider.notifier);
      schedule.undo();
      await tester.pumpAndSettle();
      expect(scheduleOf(tester).entries[oct22]?.note, 'Llevar la tarjeta');
      schedule.undo();
      await tester.pumpAndSettle();
      expect(scheduleOf(tester).entries[oct22]?.note, isNull);
    });

    testWidgets('paint mode survives, with its brush', (tester) async {
      await pumpCalendar(tester, size: phoneLandscape);
      await enterPaintMode(tester);
      await tester.tap(key('tool-afternoon'));
      await tester.pumpAndSettle();

      await resize(tester, phonePortrait);
      expect(find.text('Listo'), findsOneWidget);
      await revealCell(tester, oct24);
      await tester.tap(cell(oct24));
      await tester.pumpAndSettle();
      expect(idsOn(scheduleOf(tester), oct24), 'afternoon');

      await resize(tester, phoneLandscape);
      expect(find.text('Listo'), findsOneWidget);
      expect(key('tool-afternoon'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('paint mode in two panes', () {
    testWidgets('the tools are in the pane; paint, undo, redo, done', (
      tester,
    ) async {
      await pumpCalendar(tester, size: phoneLandscape);
      await enterPaintMode(tester);
      // Header and tools in the pane, none of the today view.
      expect(find.text('PINTANDO'), findsOneWidget);
      expect(find.text('ESTA NOCHE'), findsNothing);
      expect(key('upcoming-days'), findsNothing);
      expect(
        tester.getRect(key('paint-done')).left,
        greaterThan(tester.getRect(key('pane-divider')).left),
      );
      expect(
        tester.getRect(key('tool-morning')).left,
        greaterThan(tester.getRect(key('pane-divider')).left),
      );

      await tester.ensureVisible(cell(oct24));
      await tester.pumpAndSettle();
      await tester.tap(cell(oct24));
      await tester.pumpAndSettle();
      expect(idsOn(scheduleOf(tester), oct24), 'morning');

      await tester.tap(find.byTooltip('Deshacer'));
      await tester.pumpAndSettle();
      expect(idsOn(scheduleOf(tester), oct24), 'rest');
      await tester.tap(find.byTooltip('Rehacer'));
      await tester.pumpAndSettle();
      expect(idsOn(scheduleOf(tester), oct24), 'morning');

      // A drag paints (ONE stroke).
      final gesture = await tester.startGesture(tester.getCenter(cell(oct22)));
      await gesture.moveTo(tester.getCenter(cell(oct24)));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(idsOn(scheduleOf(tester), oct22), 'morning');

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(find.text('PINTANDO'), findsNothing);
      expect(paneToday, findsOneWidget);
    });

    testWidgets('a day open in the pane is closed when painting starts', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletLandscape);
      await tapDay(tester, oct21);
      await enterPaintMode(tester);
      expect(paneDetail, findsNothing);
      expect(containerOf(tester).read(openDayProvider), isNull);
      expect(focused(tester, oct21), isFalse);
    });

    testWidgets('selection mode: the bar is in the pane and acts', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletLandscape);
      await tester.longPress(cell(oct24));
      await tester.pumpAndSettle();
      expect(key('selection-bar'), findsOneWidget);
      expect(
        tester.getRect(key('selection-bar')).left,
        greaterThan(tester.getRect(key('pane-divider')).left),
      );
      // A tap chooses another day instead of opening it.
      await tester.tap(cell(oct22));
      await tester.pumpAndSettle();
      expect(paneDetail, findsNothing);
      expect(find.text('2 días'), findsOneWidget);
      await tester.tap(key('selection-cancel'));
      await tester.pumpAndSettle();
      expect(key('selection-bar'), findsNothing);
      expect(paneToday, findsOneWidget);
    });
  });

  group('other screens on wide windows', () {
    testWidgets('Ajustes keeps its content in a centred column', (
      tester,
    ) async {
      final app = await AppUnderTestShim.open(tester, tabletLandscape);
      await app.openSettings();
      final rows = find.byKey(const ValueKey('settings-calendars'));
      final width = tester.getSize(rows).width;
      expect(width, lessThanOrEqualTo(640));
      expect(tester.getCenter(rows).dx, closeTo(tabletLandscape.width / 2, 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a day sheet is not full width on a portrait tablet', (
      tester,
    ) async {
      await pumpCalendar(tester, size: tabletPortrait);
      await tester.tap(cell(oct21));
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(
        tester.getSize(find.byType(DayDetailSheet)).width,
        lessThanOrEqualTo(640),
      );
    });
  });

  group('first use in landscape', () {
    for (final scale in [1.0, 1.3]) {
      testWidgets('915x412, text $scale: it scrolls and «Siguiente» is '
          'reachable', (tester) async {
        final app = await FirstLaunch.open(
          tester,
          size: phoneLandscape,
          textScale: scale,
        );
        final next = find.byKey(const ValueKey('onboarding-next'));
        for (var step = 0; step < 2; step++) {
          expect(tester.getRect(next).bottom, lessThanOrEqualTo(412.5));
          expect(tester.getRect(next).top, greaterThan(0));
          if (step == 0) {
            await app.tap(
              find.byKey(const ValueKey('onboarding-profession-nursing')),
            );
          }
          await app.tap(next);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}

/// The whole app on [size], for screens other than the month.
class AppUnderTestShim {
  AppUnderTestShim._(this.tester);

  final WidgetTester tester;

  static Future<AppUnderTestShim> open(WidgetTester tester, Size size) async {
    await pumpCalendar(tester, size: size);
    return AppUnderTestShim._(tester);
  }

  Future<void> openSettings() async {
    await tester.tap(find.byTooltip('Abrir ajustes'));
    await tester.pumpAndSettle();
  }
}
