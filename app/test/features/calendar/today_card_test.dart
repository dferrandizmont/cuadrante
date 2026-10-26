import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/app_colors.dart';
import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  setUpAll(initializeLocale);

  const oct19 = CivilDate(2026, 10, 19); // today, night
  const oct20 = CivilDate(2026, 10, 20); // night
  const oct21 = CivilDate(2026, 10, 21); // morning + afternoon
  const oct22 = CivilDate(2026, 10, 22); // cleared
  const oct23 = CivilDate(2026, 10, 23); // night
  const oct24 = CivilDate(2026, 10, 24); // rest

  group('the card of today', () {
    testWidgets('counts down to the start: 18:20 -> 3 h 40 min', (
      tester,
    ) async {
      await pumpCalendar(tester, clock: () => DateTime(2026, 10, 19, 18, 20));
      expect(find.text('ESTA NOCHE'), findsOneWidget);
      expect(find.text('Empieza en 3 h 40 min'), findsOneWidget);
    });

    testWidgets('a shift in progress is AHORA with its end', (tester) async {
      await pumpCalendar(tester, clock: () => DateTime(2026, 10, 19, 23));
      expect(find.text('AHORA'), findsOneWidget);
      expect(find.text('Noche'), findsOneWidget);
      expect(find.text('Hasta las 06:00'), findsOneWidget);
      expect(find.text('Termina en 7 h'), findsOneWidget);
    });

    testWidgets('after midnight the night shift of yesterday still counts', (
      tester,
    ) async {
      await pumpCalendar(tester, clock: () => DateTime(2026, 10, 20, 3, 15));
      expect(find.text('AHORA'), findsOneWidget);
      expect(find.text('Hasta las 06:00'), findsOneWidget);
      expect(find.text('Termina en 2 h 45 min'), findsOneWidget);
      // Today's own night shift, in one line.
      expect(find.text('+ Noche 22:00–06:00'), findsOneWidget);
      // The date line follows the clock.
      expect(
        dateLineText(tester),
        anyOf('Martes, 20 de octubre', 'Mar 20 oct'),
      );
    });

    testWidgets('a shift before 20:00 is HOY, the others go in one line', (
      tester,
    ) async {
      await pumpCalendar(tester, clock: () => DateTime(2026, 10, 21, 5));
      final controller = containerOf(tester)
          .read(scheduleControllerProvider.notifier);
      controller.beginStroke(const PaintTool.erase());
      controller.paintDay(oct20);
      controller.endStroke();
      await tester.pumpAndSettle();

      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('Mañana'), findsWidgets);
      expect(find.text('06:00–14:00'), findsOneWidget);
      expect(find.text('+ Tarde 14:00–22:00'), findsOneWidget);
      expect(find.text('Empieza en 1 h'), findsOneWidget);
    });

    testWidgets('a free day shows the next shift and its countdown', (
      tester,
    ) async {
      await pumpCalendar(tester, clock: () => DateTime(2026, 10, 22, 10));
      expect(find.text('HOY LIBRE'), findsOneWidget);
      expect(find.text('Próximo: Noche, vie 22:00'), findsOneWidget);
      expect(find.text('Empieza en 1 d 12 h'), findsOneWidget);
      // The date tells "mañana" (the next day) from a shift called Mañana.
      expect(find.text('Mañana (vie 23): turno de Noche'), findsOneWidget);
    });

    testWidgets('a day of Mañana does not read "Mañana: Mañana"', (
      tester,
    ) async {
      // Wednesday 21 is Mañana + Tarde; Tuesday's card looks at it.
      await pumpCalendar(tester, clock: () => DateTime(2026, 10, 20, 10));
      expect(find.text('Mañana: Mañana'), findsNothing);
      expect(
        find.text('Mañana (mié 21): turno de Mañana + Tarde'),
        findsOneWidget,
      );
    });

    testWidgets('after the shift ends it says so, and gives the next', (
      tester,
    ) async {
      // Tuesday 20 is a night shift in the demo data; 21 is the morning.
      // Make 20 a Tarde so that at 22:30 it is over.
      await pumpCalendar(
        tester,
        clock: () => DateTime(2026, 10, 20, 22, 30),
        prepare: (repository) async {
          await repository.apply(
            'main',
            ScheduleChange(
              patch: EntriesPatch({
                oct20: EntryChange(
                  null,
                  DayEntry(date: oct20, shiftTypeIds: const ['afternoon']),
                ),
              }),
            ),
          );
        },
      );
      expect(find.text('HOY LIBRE'), findsNothing);
      expect(find.text('HOY TERMINADO'), findsOneWidget);
      expect(find.text('Tarde'), findsWidgets);
      expect(find.text('Terminó a las 22:00'), findsOneWidget);
      expect(find.text('Próximo: Mañana, mié 06:00'), findsOneWidget);
      expect(find.text('Empieza en 7 h 30 min'), findsOneWidget);
    });

    testWidgets('the countdown refreshes every minute, nothing else moves', (
      tester,
    ) async {
      var now = DateTime(2026, 10, 19, 18, 20);
      await pumpCalendar(tester, clock: () => now);
      expect(find.text('Empieza en 3 h 40 min'), findsOneWidget);

      // Half a minute later: same minute, same text.
      now = DateTime(2026, 10, 19, 18, 20, 30);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Empieza en 3 h 40 min'), findsOneWidget);

      now = DateTime(2026, 10, 19, 18, 21, 1);
      await tester.pump(const Duration(seconds: 31));
      await tester.pump();
      expect(find.text('Empieza en 3 h 39 min'), findsOneWidget);
      expect(find.text('Empieza en 3 h 40 min'), findsNothing);

      // The next minute, again.
      now = DateTime(2026, 10, 19, 18, 22);
      await tester.pump(const Duration(minutes: 1));
      await tester.pump();
      expect(find.text('Empieza en 3 h 38 min'), findsOneWidget);
    });

    testWidgets('survives large text in a narrow dark screen', (tester) async {
      await pumpCalendar(
        tester,
        textScale: 1.6,
        brightness: Brightness.dark,
        size: const Size(320, 640),
        clock: () => DateTime(2026, 10, 19, 18, 20),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Empieza en 3 h 40 min'), findsOneWidget);
    });
  });

  group('day cell', () {
    Finder boxes(CivilDate d, Color color) => find.descendant(
      of: cell(d),
      matching: find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == color,
      ),
    );

    ShiftSwatch swatchOf(Color c, {bool outOfMonth = false}) =>
        ShiftSwatch.forColor(
          c.toARGB32(),
          Brightness.light,
          outOfMonth: outOfMonth,
        );

    testWidgets('tint of the shift and a bar in its colour', (tester) async {
      await pumpCalendar(tester);
      final night = swatchOf(ShiftPalette.night);
      expect(boxes(oct19, night.tint), findsOneWidget);
      expect(boxes(oct19, night.bar), findsOneWidget);
      // The bar is 6 dp tall.
      final bar = tester.getSize(boxes(oct19, night.bar));
      expect(bar.height, 6);
      // Cleared day: only the surface, no bar.
      expect(boxes(oct22, AppColors.light.surface), findsOneWidget);
      expect(
        find.descendant(
          of: cell(oct22),
          matching: find.byWidgetPredicate(
            (w) => w is ColoredBox && w.color == night.bar,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('two shifts: stacked tints and a bar in equal segments', (
      tester,
    ) async {
      await pumpCalendar(tester);
      final morning = swatchOf(ShiftPalette.morning);
      final afternoon = swatchOf(ShiftPalette.afternoon);
      expect(boxes(oct21, morning.tint), findsOneWidget);
      expect(boxes(oct21, afternoon.tint), findsOneWidget);
      final m = tester.getSize(boxes(oct21, morning.bar));
      final a = tester.getSize(boxes(oct21, afternoon.bar));
      expect(m.height, 6);
      expect(m.width, closeTo(a.width, 0.01));
    });

    testWidgets('Libre is neutral', (tester) async {
      await pumpCalendar(tester);
      final rest = swatchOf(ShiftPalette.rest);
      expect(boxes(oct24, rest.tint), findsOneWidget);
      expect(boxes(oct24, AppColors.light.borderStrong), findsOneWidget);
    });

    testWidgets('days of other months: muted background, softer bar', (
      tester,
    ) async {
      await pumpCalendar(tester);
      const sep28 = CivilDate(2026, 9, 28);
      final day = scheduleOf(tester).resolve(sep28);
      expect(day.shifts, isNotEmpty);
      final dim = ShiftSwatch.forColor(
        day.shifts.first.colorValue,
        Brightness.light,
        outOfMonth: true,
      );
      expect(boxes(sep28, AppColors.light.surfaceMuted), findsOneWidget);
      expect(boxes(sep28, dim.bar), findsOneWidget);
    });

    testWidgets('today has an inner ring, other days do not', (tester) async {
      await pumpCalendar(tester);
      Finder ring(CivilDate d) => find.descendant(
        of: cell(d),
        matching: find.byWidgetPredicate((w) {
          if (w is! DecoratedBox) return false;
          final decoration = w.decoration;
          if (decoration is! BoxDecoration) return false;
          final border = decoration.border;
          return border is Border &&
              border.top.color == AppColors.light.todayRing &&
              border.top.width == 2;
        }),
      );
      expect(ring(oct19), findsOneWidget);
      expect(ring(oct20), findsNothing);
    });

    testWidgets('cells in the stroke fill with the disc and a ring in the bar '
        'colour until the finger lifts', (tester) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      final morning = swatchOf(ShiftPalette.morning);

      Finder ring(CivilDate d) => find.descendant(
        of: cell(d),
        matching: find.byWidgetPredicate((w) {
          if (w is! DecoratedBox) return false;
          final decoration = w.decoration;
          if (decoration is! BoxDecoration) return false;
          final border = decoration.border;
          return border is Border && border.top.color == morning.bar;
        }),
      );

      final gesture = await tester.startGesture(tester.getCenter(cell(oct22)));
      await gesture.moveTo(tester.getCenter(cell(oct23)));
      await tester.pump();
      expect(boxes(oct22, morning.disc), findsOneWidget);
      expect(boxes(oct23, morning.disc), findsOneWidget);
      expect(ring(oct22), findsOneWidget);
      expect(ring(oct23), findsOneWidget);
      // Untouched days keep their look.
      expect(boxes(oct24, morning.disc), findsNothing);
      expect(ring(oct24), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(boxes(oct22, morning.disc), findsNothing);
      expect(boxes(oct22, morning.tint), findsOneWidget);
      expect(ring(oct22), findsNothing);
    });
  });

  group('paint tools', () {
    testWidgets('header names the shift and its hours; pucks show disc + ink', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      expect(find.text('PINTANDO'), findsOneWidget);
      expect(find.text('Mañana · 06:00–14:00'), findsOneWidget);

      await tester.tap(find.widgetWithText(InkWell, 'Tarde'));
      await tester.pumpAndSettle();
      expect(find.text('Tarde · 14:00–22:00'), findsOneWidget);

      await tester.tap(find.widgetWithText(InkWell, 'Borrar'));
      await tester.pumpAndSettle();
      expect(find.text('Borrar'), findsNWidgets(2)); // header + puck

      // A puck is a 54 dp circle in the disc colour.
      final disc = ShiftSwatch.forColor(
        ShiftPalette.night.toARGB32(),
        Brightness.light,
      ).disc;
      final puck = find.descendant(
        of: find.byKey(const ValueKey('tool-night')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == disc &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(puck, findsOneWidget);
      expect(tester.getSize(puck), const Size.square(54));
    });

    testWidgets('the selected puck is ringed and its name is bold', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      Finder ring(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byWidgetPredicate((w) {
          if (w is! DecoratedBox) return false;
          final decoration = w.decoration;
          if (decoration is! BoxDecoration) return false;
          final border = decoration.border;
          return border is Border &&
              border.top.color == AppColors.light.todayRing &&
              border.top.width == 2.5;
        }),
      );
      expect(ring('tool-morning'), findsOneWidget);
      expect(ring('tool-afternoon'), findsNothing);

      await tester.tap(find.widgetWithText(InkWell, 'Tarde'));
      await tester.pumpAndSettle();
      expect(ring('tool-morning'), findsNothing);
      expect(ring('tool-afternoon'), findsOneWidget);
    });

    testWidgets('Doblar toggles and undo / redo are round 48 dp buttons', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Doblar'));
      await tester.pumpAndSettle();
      expect(
        containerOf(tester).read(paintControllerProvider).doubling,
        isTrue,
      );
      expect(tester.getSize(find.byKey(const ValueKey('undo'))).width, 48);
      expect(tester.getSize(find.byKey(const ValueKey('redo'))).height, 48);
    });
  });
}
