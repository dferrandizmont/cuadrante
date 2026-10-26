import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  setUpAll(initializeLocale);

  const oct12 = CivilDate(2026, 10, 12); // holiday
  const oct19 = CivilDate(2026, 10, 19); // today, night
  const oct20 = CivilDate(2026, 10, 20); // night, with a note
  const oct21 = CivilDate(2026, 10, 21); // morning + afternoon
  const oct22 = CivilDate(2026, 10, 22); // cleared
  const oct23 = CivilDate(2026, 10, 23); // night
  const oct24 = CivilDate(2026, 10, 24); // rest

  Future<void> tapChip(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(InkWell, label);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  Finder inCell(CivilDate d, Finder matching) =>
      find.descendant(of: cell(d), matching: matching);

  group('month view', () {
    testWidgets(
      'the Pintar button never covers a day, also over the system nav bar',
      (tester) async {
        // Android gesture bar: the body runs under it, the button above it.
        tester.view.viewPadding = const FakeViewPadding(bottom: 48 * 3);
        tester.view.padding = const FakeViewPadding(bottom: 48 * 3);
        addTearDown(tester.view.resetViewPadding);
        addTearDown(tester.view.resetPadding);
        await pumpCalendar(tester);
        final lastDay = cell(CivilDate(2026, 11, 8));
        await tester.scrollUntilVisible(
          lastDay,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pumpAndSettle();
        final fab = tester.getRect(find.byType(FloatingActionButton));
        final day = tester.getRect(lastDay);
        expect(day.bottom, lessThanOrEqualTo(fab.top + 0.01));
      },
    );

    testWidgets('header shows the date and the card of tonight', (
      tester,
    ) async {
      await pumpCalendar(tester);
      // 12:00 on Monday: the night shift starts at 22:00.
      expect(dateLineText(tester), anyOf('Lunes, 19 de octubre', 'Lun 19 oct'));
      expect(find.text('ESTA NOCHE'), findsOneWidget);
      expect(find.text('Noche'), findsOneWidget);
      expect(find.text('22:00–06:00'), findsOneWidget);
      expect(find.text('Empieza en 10 h'), findsOneWidget);
      expect(find.text('Mañana (mar 20): turno de Noche'), findsOneWidget);
      // The badge carries the code, like the cell of the day.
      expect(find.text('N'), findsWidgets);
    });

    testWidgets('a free day shows the next shift instead', (tester) async {
      await pumpCalendar(tester);
      final controller = containerOf(tester)
          .read(scheduleControllerProvider.notifier);
      controller.beginStroke(const PaintTool.erase());
      controller.paintDay(oct19);
      controller.paintDay(oct20);
      controller.endStroke();
      await tester.pumpAndSettle();

      expect(find.text('HOY LIBRE'), findsOneWidget);
      expect(find.text('Libre'), findsWidgets);
      // Next shift: Wednesday's morning, 06:00 (42 h away).
      expect(find.text('Próximo: Mañana, mié 06:00'), findsOneWidget);
      expect(find.text('Empieza en 1 d 18 h'), findsOneWidget);
      expect(find.text('Mañana (mar 20): sin turno'), findsOneWidget);
    });

    testWidgets('the card reads as one sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCalendar(tester);
      expect(
        find.bySemanticsLabel(
          'esta noche, Noche, 22:00–06:00, Empieza en 10 h, '
          'Mañana (mar 20): turno de Noche',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('title, weekday header Monday first, 6 x 7 cells', (
      tester,
    ) async {
      await pumpCalendar(tester);
      expect(find.text('Octubre'), findsOneWidget);
      final letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
      for (final l in letters) {
        expect(find.text(l), findsWidgets);
      }
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('day-'),
        ),
        findsNWidgets(42),
      );
      // October 2026 starts on a Thursday: the grid opens on Mon 28 Sep.
      expect(cell(const CivilDate(2026, 9, 28)), findsOneWidget);
      expect(cell(const CivilDate(2026, 11, 8)), findsOneWidget);
    });

    testWidgets('cells carry code and time, not only colour', (tester) async {
      await pumpCalendar(tester);
      expect(inCell(oct19, find.text('N')), findsOneWidget);
      expect(inCell(oct19, find.text('22–06')), findsOneWidget);
      // Doubled day: both shifts.
      expect(inCell(oct21, find.text('M')), findsOneWidget);
      expect(inCell(oct21, find.text('T')), findsOneWidget);
      // Cleared day: only the number.
      expect(inCell(oct22, find.text('22')), findsOneWidget);
      expect(inCell(oct22, find.text('N')), findsNothing);
      // Libre has a code and no time.
      expect(inCell(oct24, find.text('L')), findsOneWidget);
      expect(inCell(oct24, find.textContaining('–')), findsNothing);
      // Note -> clip icon.
      expect(inCell(oct20, find.byType(Icon)), findsOneWidget);
      expect(inCell(oct19, find.byType(Icon)), findsNothing);
    });

    testWidgets('holidays are marked: label, dot and number', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCalendar(tester);

      expect(
        find.bySemanticsLabel(RegExp('festivo: Fiesta Nacional de España')),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(cell(oct12)).label,
        contains('lunes 12 de octubre'),
      );
      expect(find.byKey(const ValueKey('holiday-dot-2026-10-12')), findsOne);
      // Nov 1 2026 is a Sunday, so it is no official holiday. One the user
      // adds by hand shows in the October grid (neighbouring month) too.
      expect(
        find.byKey(const ValueKey('holiday-dot-2026-11-01')),
        findsNothing,
      );
      await tester.runAsync(
        () =>
            containerOf(tester)
                .read(holidayControllerProvider.notifier)
                .addUserHoliday(date: CivilDate(2026, 11, 1), name: 'Patrón'),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('holiday-dot-2026-11-01')),
        findsOneWidget,
      );
      // An ordinary day is not.
      expect(
        tester.getSemantics(cell(oct23)).label,
        isNot(contains('festivo')),
      );
      handle.dispose();
    });

    testWidgets('semantics describe the day in Spanish', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCalendar(tester);

      expect(
        tester.getSemantics(cell(oct19)).label,
        'lunes 19 de octubre, hoy, Noche de 22:00 a 06:00',
      );
      expect(
        tester.getSemantics(cell(oct20)).label,
        'martes 20 de octubre, Noche de 22:00 a 06:00, con nota',
      );
      expect(
        tester.getSemantics(cell(oct21)).label,
        'miércoles 21 de octubre, '
        'Mañana de 06:00 a 14:00 y Tarde de 14:00 a 22:00',
      );
      expect(
        tester.getSemantics(cell(oct22)).label,
        'jueves 22 de octubre, sin turno',
      );
      expect(
        tester.getSemantics(cell(oct24)).label,
        'sábado 24 de octubre, Libre',
      );
      handle.dispose();
    });

    testWidgets('month navigation: arrows, Hoy and swipe', (tester) async {
      await pumpCalendar(tester);

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Noviembre'), findsOneWidget);
      // November's grid opens on Mon 26 Oct.
      expect(cell(const CivilDate(2026, 10, 26)), findsOneWidget);

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Septiembre'), findsOneWidget);

      await tester.tap(find.text('Hoy').last);
      await tester.pumpAndSettle();
      expect(find.text('Octubre'), findsOneWidget);

      await tester.fling(cell(oct12), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Noviembre'), findsOneWidget);

      await tester.fling(
        cell(const CivilDate(2026, 11, 12)),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Octubre'), findsOneWidget);

      // December -> January rolls the year.
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Enero 2027'), findsOneWidget);
    });

    testWidgets('tapping a day opens the day detail', (tester) async {
      await pumpCalendar(tester);

      await tester.tap(cell(oct12));
      await tester.pumpAndSettle();
      expect(find.text('Festivo: Fiesta Nacional de España'), findsOneWidget);
      expect(find.text('Lunes, 12 de octubre'), findsOneWidget);

      // The sheet can fill the screen, so there is no scrim to tap: close it.
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Lunes, 12 de octubre'), findsNothing);

      await tester.tap(cell(oct20));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('22:00–06:00'),
        ),
        findsOneWidget,
      );
      expect(find.text('Cambio con Marta si sale el turno'), findsOneWidget);

      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(cell(oct22));
      await tester.pumpAndSettle();
      expect(find.text('Este día no tiene turno.'), findsOneWidget);
    });

    testWidgets('survives large text and dark mode', (tester) async {
      await pumpCalendar(
        tester,
        textScale: 1.3,
        brightness: Brightness.dark,
        size: const Size(360, 640),
      );
      expect(tester.takeException(), isNull);
      await revealCell(tester, oct19);
      expect(cell(oct19), findsOneWidget);

      await enterPaintMode(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Listo'), findsOneWidget);
    });
  });

  group('layout holds on any screen', () {
    const sizes = [
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(844, 390),
      Size(768, 1024),
    ];
    for (final size in sizes) {
      for (final scale in [1.0, 1.6]) {
        for (final brightness in Brightness.values) {
          testWidgets('${size.width.toInt()}x${size.height.toInt()} '
              'x$scale ${brightness.name}, also painting', (tester) async {
            await pumpCalendar(
              tester,
              size: size,
              textScale: scale,
              brightness: brightness,
            );
            expect(tester.takeException(), isNull);
            // A tight screen scrolls instead of squeezing the grid.
            await tester.scrollUntilVisible(
              cell(oct19),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            expect(cell(oct19), findsOneWidget);
            expect(tester.takeException(), isNull);
            await enterPaintMode(tester);
            expect(tester.takeException(), isNull);
            expect(find.text('Listo'), findsOneWidget);
          });
        }
      }
    }
  });

  group('paint mode', () {
    testWidgets('FAB toggles the bar; Listo leaves', (tester) async {
      await pumpCalendar(tester);
      expect(find.text('Listo'), findsNothing);

      await enterPaintMode(tester);
      expect(find.text('Listo'), findsOneWidget);
      expect(find.text('Pintar'), findsNothing);
      // The paint header takes the place of the date and the card.
      expect(find.text('PINTANDO'), findsOneWidget);
      expect(find.text('ESTA NOCHE'), findsNothing);
      expect(dateLine, findsNothing);

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(find.text('Listo'), findsNothing);
      expect(find.text('Pintar'), findsOneWidget);
      expect(find.text('ESTA NOCHE'), findsOneWidget);
    });

    testWidgets('bar has a chip per shift, eraser, Doblar, undo and redo', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);

      for (final name in ['Mañana', 'Tarde', 'Noche', 'Libre', 'Saliente']) {
        expect(find.widgetWithText(InkWell, name), findsOneWidget);
      }
      expect(find.text('Borrar'), findsOneWidget);
      expect(find.text('Doblar'), findsOneWidget);
      IconButton button(String key) =>
          tester.widget<IconButton>(find.byKey(ValueKey(key)));
      expect(button('undo').onPressed, isNull);
      expect(button('redo').onPressed, isNull);
    });

    testWidgets('a tap paints the day with the selected shift', (tester) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);

      await tester.tap(cell(oct24));
      await tester.pumpAndSettle();

      expect(idsOn(scheduleOf(tester), oct24), 'morning');
      expect(inCell(oct24, find.text('M')), findsOneWidget);
      expect(inCell(oct24, find.text('06–14')), findsOneWidget);
      // No sheet in paint mode.
      expect(find.text('Sábado, 24 de octubre'), findsNothing);
    });

    testWidgets('selecting another chip changes the brush', (tester) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);

      await tapChip(tester, 'Tarde');
      await tester.tap(cell(oct24));
      await tester.pumpAndSettle();

      expect(idsOn(scheduleOf(tester), oct24), 'afternoon');
    });

    testWidgets('dragging across 3 cells paints 3 days; one Undo restores', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      expect(idsOn(scheduleOf(tester), oct22), '');
      expect(idsOn(scheduleOf(tester), oct23), 'night');
      expect(idsOn(scheduleOf(tester), oct24), 'rest');

      final gesture = await tester.startGesture(tester.getCenter(cell(oct22)));
      await gesture.moveTo(tester.getCenter(cell(oct23)));
      await tester.pump();
      // Live preview while the finger is down.
      expect(idsOn(scheduleOf(tester), oct23), 'morning');
      await gesture.moveTo(tester.getCenter(cell(oct24)));
      await gesture.up();
      await tester.pumpAndSettle();

      final painted = scheduleOf(tester);
      expect(idsOn(painted, oct22), 'morning');
      expect(idsOn(painted, oct23), 'morning');
      expect(idsOn(painted, oct24), 'morning');
      // The rest of the week is untouched.
      expect(idsOn(painted, oct21), 'morning+afternoon');

      await tester.tap(find.byTooltip('Deshacer'));
      await tester.pumpAndSettle();
      final restored = scheduleOf(tester);
      expect(idsOn(restored, oct22), '');
      expect(idsOn(restored, oct23), 'night');
      expect(idsOn(restored, oct24), 'rest');

      // Redo brings the stroke back in one step too.
      await tester.tap(find.byTooltip('Rehacer'));
      await tester.pumpAndSettle();
      expect(idsOn(scheduleOf(tester), oct22), 'morning');
      expect(idsOn(scheduleOf(tester), oct24), 'morning');
    });

    testWidgets('a fast drag in one jump does not skip the cells between', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);

      // Single move event from Mon 19 to Fri 23: crosses 20, 21 and 22.
      final gesture = await tester.startGesture(tester.getCenter(cell(oct19)));
      await gesture.moveTo(tester.getCenter(cell(oct23)));
      await gesture.up();
      await tester.pumpAndSettle();

      for (var d = 19; d <= 23; d++) {
        expect(
          idsOn(scheduleOf(tester), CivilDate(2026, 10, d)),
          'morning',
          reason: 'day $d',
        );
      }
    });

    testWidgets('dragging skips the grey days of the neighbouring months', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);

      const oct31 = CivilDate(2026, 10, 31);
      const nov1 = CivilDate(2026, 11, 1);
      const nov2 = CivilDate(2026, 11, 2);
      await tester.ensureVisible(cell(nov2));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(cell(oct31)));
      await gesture.moveTo(tester.getCenter(cell(nov2)));
      await gesture.up();
      await tester.pumpAndSettle();

      // The stroke stays in the month that is being edited (H-T24-12): the
      // day of October is painted and the grey ones are not.
      expect(idsOn(scheduleOf(tester), oct31), 'morning');
      expect(idsOn(scheduleOf(tester), nov1), isNot('morning'));
      expect(idsOn(scheduleOf(tester), nov2), isNot('morning'));
    });

    testWidgets('swiping does not change month while painting', (tester) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);

      await tester.fling(cell(oct12), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Octubre'), findsOneWidget);
      // The drag painted instead.
      expect(idsOn(scheduleOf(tester), oct12), 'morning');
    });

    testWidgets('"Doblar" adds the shift to the day', (tester) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);

      await tester.tap(find.widgetWithText(InkWell, 'Tarde'));
      await tapChip(tester, 'Doblar');
      await tester.tap(cell(oct23)); // night
      await tester.pumpAndSettle();

      expect(idsOn(scheduleOf(tester), oct23), 'night+afternoon');
      expect(inCell(oct23, find.text('N')), findsOneWidget);
      expect(inCell(oct23, find.text('T')), findsOneWidget);
    });

    testWidgets('the eraser empties a day', (tester) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);

      await tapChip(tester, 'Borrar');
      await tester.tap(cell(oct19));
      await tester.pumpAndSettle();

      expect(scheduleOf(tester).resolve(oct19).isEmpty, isTrue);
      expect(find.text('HOY LIBRE'), findsNothing); // hidden while painting
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(find.text('HOY LIBRE'), findsOneWidget);
    });
  });
}
