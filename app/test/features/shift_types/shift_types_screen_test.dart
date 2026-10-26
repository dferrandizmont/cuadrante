import 'package:cuadrante/core/format/text_wrap.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/core/widgets/buttons.dart';
import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_snapshot.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/shift_types/presentation/shift_type_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';

// The month screen is offstage once a route is pushed on top of it, so the
// container is found from the app itself.
ProviderContainer appContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

ScheduleState stateOf(WidgetTester tester) =>
    appContainer(tester).read(scheduleControllerProvider);

ScheduleController controllerOf(WidgetTester tester) =>
    appContainer(tester).read(scheduleControllerProvider.notifier);

List<String> paletteIds(WidgetTester tester) => [
  for (final t in stateOf(tester).palette) t.id,
];

/// What is stored, once every queued write has finished.
Future<ScheduleSnapshot> storedSnapshot(WidgetTester tester) async {
  final container = appContainer(tester);
  return (await tester.runAsync(() async {
    await container.read(scheduleControllerProvider.notifier).pendingWrites;
    return container.read(scheduleRepositoryProvider).load(mainCalendarId);
  }))!;
}

Finder _key(String key) => find.byKey(ValueKey(key));

TextEditingController? _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(_key(key)).controller;

/// Settings -> Mis turnos, through the visible controls.
Future<void> openShiftTypes(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Abrir ajustes'));
  await tester.pumpAndSettle();
  await tester.tap(_key('settings-shifts'));
  await tester.pumpAndSettle();
}

Future<void> openNewShift(WidgetTester tester) async {
  await tester.ensureVisible(_key('shift-new'));
  await tester.tap(_key('shift-new'));
  await tester.pumpAndSettle();
}

/// Scrolls the form until [key] is on screen.
Future<void> reveal(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pump();
}

Future<void> typeInto(WidgetTester tester, String key, String text) async {
  await reveal(tester, key);
  await tester.enterText(_key(key), text);
  await tester.pump();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await reveal(tester, key);
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// Sets a time with the 24 h picker, in its text entry mode.
Future<void> setTime(
  WidgetTester tester,
  String button,
  int hour,
  int minute,
) async {
  await tapKey(tester, button);
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();
  final fields = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );
  expect(fields, findsNWidgets(2));
  await tester.enterText(fields.at(0), '$hour');
  await tester.enterText(fields.at(1), '$minute');
  await tester.tap(
    find.byWidgetPredicate(
      (w) => w is Text && w.data?.toLowerCase() == 'aceptar',
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) => tapKey(tester, 'shift-save');

void main() {
  group('the list', () {
    testWidgets('settings opens "Mis turnos" with the palette in order', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      final ids = paletteIds(tester);
      expect(ids, isNotEmpty);
      // The list is lazy: the rows on screen are in palette order.
      final tops = [
        for (final id in ids)
          if (_key('shift-row-$id').evaluate().isNotEmpty)
            tester.getTopLeft(_key('shift-row-$id')).dy,
      ];
      expect(tops.length, greaterThan(5));
      expect(tops, orderedEquals([...tops]..sort()));
      expect(find.text('Nuevo turno'), findsOneWidget);
    });

    testWidgets('a row shows times, category and the hourly rate', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        prepare: (repository) async {
          await repository.saveShiftType(
            const ShiftType(
              id: 'morning',
              code: 'M',
              name: 'Mañana',
              colorValue: 0xFFF5A524,
              category: ShiftCategory.work,
              startMinute: 360,
              endMinute: 840,
              hourlyRateCents: 1250,
            ),
          );
        },
      );
      await openShiftTypes(tester);
      expect(
        find.textContaining(keepTimeRangesTogether('06:00–14:00 · Trabajo · 12,50')),
        findsOneWidget,
      );
      expect(find.text('Sin horario · Descanso'), findsNWidgets(2));
    });

    testWidgets('the paint bar ends with "Editar turnos"', (tester) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      await tester.ensureVisible(_key('tool-edit-types'));
      await tester.tap(_key('tool-edit-types'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo turno'), findsOneWidget);
      expect(_key('shift-list'), findsOneWidget);
    });

    testWidgets('dragging the handle reorders the palette and saves it', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      final before = paletteIds(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(_key('shift-handle-${before.first}')),
      );
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      final after = paletteIds(tester);
      expect(after, isNot(before));
      expect(after.toSet(), before.toSet());
      expect(after.indexOf(before.first), greaterThan(0));
      // The list shows the new order too.
      expect(
        tester.getTopLeft(_key('shift-row-${after.first}')).dy,
        lessThan(tester.getTopLeft(_key('shift-row-${after[1]}')).dy),
      );
      final stored = await storedSnapshot(tester);
      expect([for (final t in stored.palette) t.id], after);
    });

    testWidgets('archiving asks first; days that used it keep showing it', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);

      await tester.tap(_key('shift-archive-rest'));
      await tester.pumpAndSettle();
      expect(find.text('¿Archivar «Libre»?'), findsOneWidget);

      // Cancel: nothing happens.
      await tester.tap(_key('confirm-cancel'));
      await tester.pumpAndSettle();
      expect(_key('shift-row-rest'), findsOneWidget);

      await tester.tap(_key('shift-archive-rest'));
      await tester.pumpAndSettle();
      await tester.tap(_key('confirm-ok'));
      await tester.pumpAndSettle();
      expect(_key('shift-row-rest'), findsNothing);

      final state = stateOf(tester);
      expect(state.palette.any((t) => t.id == 'rest'), isFalse);
      expect(state.schedule.shiftTypeById('rest'), isNotNull);
      final stored = await storedSnapshot(tester);
      expect(stored.palette.any((t) => t.id == 'rest'), isFalse);

      // Back on the month the Libre days (24 Oct) still show their code.
      appContainer(tester).read(routerProvider).pop();
      await tester.pumpAndSettle();
      appContainer(tester).read(routerProvider).pop();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: cell(const CivilDate(2026, 10, 24)),
          matching: find.text('L'),
        ),
        findsOneWidget,
      );
      await enterPaintMode(tester);
      expect(_key('tool-rest'), findsNothing);
      expect(_key('tool-morning'), findsOneWidget);
    });

    testWidgets('archiving the shift being painted changes the brush', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      paintOf(tester).selectShift('afternoon');
      await tester.pump();
      controllerOf(tester).archiveShiftType('afternoon');
      await tester.pump();
      final paint = appContainer(tester).read(paintControllerProvider);
      expect(paint.shiftTypeId, isNot('afternoon'));
      expect(paint.shiftTypeId, isNotNull);
    });
  });

  group('the form', () {
    testWidgets('empty form: saving shows the messages in Spanish and saves '
        'nothing', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      final count = stateOf(tester).palette.length;
      await openNewShift(tester);

      await save(tester);
      expect(find.text('Pon un nombre al turno'), findsOneWidget);
      expect(
        find.text('Escribe un código de 1 a 3 caracteres'),
        findsOneWidget,
      );
      // Still on the form, palette unchanged.
      expect(_key('shift-save'), findsOneWidget);
      expect(stateOf(tester).palette.length, count);
    });

    testWidgets('the code is suggested from the name and must be unique', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);

      await typeInto(tester, 'shift-name', 'refuerzo');
      expect(_text(tester, 'shift-code')?.text, 'R');
      // Mañana already uses M: the suggestion skips it.
      await typeInto(tester, 'shift-name', 'Media jornada');
      expect(_text(tester, 'shift-code')?.text, 'ME');

      // Typing a code by hand stops the suggestion, and a taken one fails.
      await typeInto(tester, 'shift-code', 'm');
      await typeInto(tester, 'shift-name', 'Media jornada larga');
      expect(_text(tester, 'shift-code')?.text, 'm');
      await save(tester);
      expect(find.text('Este código ya lo usa «Mañana»'), findsOneWidget);
    });

    testWidgets('the code is capped at three characters', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-code', 'ABCDE');
      expect(_text(tester, 'shift-code')?.text, 'ABC');
    });

    testWidgets('emojis and spaces never get into the code; letters, digits '
        'and + / - do', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-code', '🙂🙂');
      expect(_text(tester, 'shift-code')?.text, '');
      await typeInto(tester, 'shift-code', 'A🙂 B🙂C');
      expect(_text(tester, 'shift-code')?.text, 'ABC');
      await typeInto(tester, 'shift-code', '+/1');
      expect(_text(tester, 'shift-code')?.text, '+/1');
      await typeInto(tester, 'shift-code', 'ÁÉÍÓ');
      expect(_text(tester, 'shift-code')?.text, 'ÁÉÍ');
      // The preview never breaks on what is typed.
      expect(tester.takeException(), isNull);
    });

    testWidgets('saves a new shift: hourly rate "12,50" is 1250 cents', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);

      await typeInto(tester, 'shift-name', 'Refuerzo');
      await typeInto(tester, 'shift-rate', '12,50');
      await save(tester);

      // Back on the list, the new shift is last.
      expect(_key('shift-list'), findsOneWidget);
      final created = stateOf(tester).palette.last;
      expect(created.name, 'Refuerzo');
      expect(created.code, 'R');
      expect(created.hourlyRateCents, 1250);
      expect(created.category, ShiftCategory.work);
      expect(created.startMinute, 480);
      expect(created.endMinute, 960);

      // And it is stored.
      final stored = (await storedSnapshot(tester)).palette.last;
      expect(stored, created);
      expect(stored.hourlyRateCents, 1250);
    });

    testWidgets('the rate takes a dot and whole euros, and refuses nonsense', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Prueba');

      await typeInto(tester, 'shift-rate', '12,555');
      await save(tester);
      expect(
        find.text('Escribe un importe válido, por ejemplo 12,50'),
        findsOneWidget,
      );

      // Letters never get into the field.
      await typeInto(tester, 'shift-rate', 'abc9');
      expect(_text(tester, 'shift-rate')?.text, '9');

      await typeInto(tester, 'shift-rate', '9.5');
      await save(tester);
      expect(stateOf(tester).palette.last.hourlyRateCents, 950);
    });

    testWidgets('a time-less shift hides the times and the pay section', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      expect(_key('shift-start'), findsOneWidget);
      expect(_key('shift-rate'), findsOneWidget);

      await tapKey(tester, 'shift-no-times');
      expect(_key('shift-start'), findsNothing);
      expect(_key('shift-rate'), findsNothing);

      await typeInto(tester, 'shift-name', 'Festivo local');
      await tapKey(tester, 'category-absence');
      await save(tester);
      final created = stateOf(tester).palette.last;
      expect(created.hasTimes, isFalse);
      expect(created.category, ShiftCategory.absence);
      expect(created.hourlyRateCents, isNull);
    });

    testWidgets('a rest shift has no pay section', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await tapKey(tester, 'category-rest');
      expect(_key('shift-rate'), findsNothing);
      expect(_key('shift-break'), findsNothing);
      await tapKey(tester, 'category-work');
      expect(_key('shift-rate'), findsOneWidget);
    });
  });

  group('times', () {
    testWidgets('a shift that crosses midnight says it ends the next day', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      expect(find.text('Empieza 08:00'), findsOneWidget);
      expect(find.text('Dura 8 h'), findsOneWidget);

      await setTime(tester, 'shift-start', 22, 0);
      await setTime(tester, 'shift-end', 6, 0);
      expect(find.text('Empieza 22:00'), findsOneWidget);
      expect(find.text('Termina 06:00'), findsOneWidget);
      expect(find.text('Termina al día siguiente · dura 8 h'), findsOneWidget);

      await typeInto(tester, 'shift-name', 'Noche corta');
      await save(tester);
      final created = stateOf(tester).palette.last;
      expect(created.startMinute, 22 * 60);
      expect(created.endMinute, 6 * 60);
      expect(created.crossesMidnight, isTrue);
      expect(created.durationMinutes, 480);
    });

    testWidgets('08:00 to 08:00 is a 24 hour shift', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);

      await setTime(tester, 'shift-end', 8, 0);
      expect(find.text('Empieza 08:00'), findsOneWidget);
      expect(find.text('Termina 08:00'), findsOneWidget);
      expect(
        find.text('Dura 24 h: termina al día siguiente a la misma hora'),
        findsOneWidget,
      );

      await typeInto(tester, 'shift-name', 'Guardia');
      await save(tester);
      final created = stateOf(tester).palette.last;
      expect(created.startMinute, 480);
      expect(created.endMinute, 480);
      expect(created.durationMinutes, 1440);
    });

    testWidgets('the unpaid break sets the paid minutes', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Partido');

      await typeInto(tester, 'shift-break', '30');
      expect(find.text('Se pagan 7 h 30 min'), findsOneWidget);
      await typeInto(tester, 'shift-break', '480');
      await save(tester);
      expect(
        find.text('El descanso tiene que ser menor que la duración del turno'),
        findsOneWidget,
      );

      await typeInto(tester, 'shift-break', '30');
      await save(tester);
      expect(stateOf(tester).palette.last.paidMinutes, 450);
    });

    testWidgets('night override: always', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Nocturno');
      await tapKey(tester, 'night-always');
      await save(tester);
      expect(stateOf(tester).palette.last.nightOverride, isTrue);
    });
  });

  group('editing', () {
    testWidgets('opens the stored values, saves them and keeps the undo of '
        'painting', (tester) async {
      await pumpCalendar(tester);
      // Paint something first: it must still be undoable afterwards.
      const day = CivilDate(2026, 10, 24);
      await enterPaintMode(tester);
      paintOf(tester).selectShift('guard24');
      await tester.tap(cell(day));
      await tester.pumpAndSettle();
      expect(idsOn(stateOf(tester).schedule, day), 'guard24');
      await tester.ensureVisible(_key('tool-edit-types'));
      await tester.tap(_key('tool-edit-types'));
      await tester.pumpAndSettle();

      await tester.tap(_key('shift-row-night'));
      await tester.pumpAndSettle();
      expect(_text(tester, 'shift-name')?.text, 'Noche');
      expect(_text(tester, 'shift-code')?.text, 'N');
      expect(find.text('Termina al día siguiente · dura 8 h'), findsOneWidget);

      await typeInto(tester, 'shift-name', 'Noche larga');
      await typeInto(tester, 'shift-rate', '15');
      await tapKey(tester, 'shift-color-${0xFFD6336C.toRadixString(16)}');
      await save(tester);

      final state = stateOf(tester);
      final night = state.schedule.shiftTypeById('night')!;
      expect(night.name, 'Noche larga');
      expect(night.hourlyRateCents, 1500);
      expect(night.colorValue, 0xFFD6336C);
      expect(night.startMinute, 22 * 60, reason: 'times untouched');
      expect(state.canUndo, isTrue, reason: 'painting is still undoable');
      final stored = await storedSnapshot(tester);
      expect(stored.schedule.shiftTypeById('night'), night);

      // Undo reverts the painting, not the shift type.
      controllerOf(tester).undo();
      await tester.pump();
      expect(idsOn(stateOf(tester).schedule, day), 'rest');
      expect(
        stateOf(tester).schedule.shiftTypeById('night')?.name,
        'Noche larga',
      );
    });

    testWidgets('editing a shift keeps its own code valid', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await tester.tap(_key('shift-row-morning'));
      await tester.pumpAndSettle();
      await save(tester);
      expect(find.text('Este código ya lo usa «Mañana»'), findsNothing);
      expect(_key('shift-list'), findsOneWidget);
    });

    testWidgets('an unknown shift shows a message instead of a form', (
      tester,
    ) async {
      await pumpCalendar(tester);
      appContainer(tester)
          .read(routerProvider)
          .push(AppRoutes.shiftTypeEdit('no-existe'));
      await tester.pumpAndSettle();
      expect(find.text('No encontramos este turno'), findsOneWidget);
    });
  });

  group('colour preview', () {
    testWidgets('shows the shift as a day cell in light and in dark', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Prueba');
      await typeInto(tester, 'shift-code', 'PR');

      for (final key in ['preview-light', 'preview-dark']) {
        final cellFinder = find.descendant(
          of: _key(key),
          matching: find.byType(DayCell),
        );
        expect(cellFinder, findsOneWidget, reason: key);
        expect(
          find.descendant(of: cellFinder, matching: find.text('PR')),
          findsOneWidget,
          reason: key,
        );
        // The times of the draft are on the cell too.
        expect(
          find.descendant(of: cellFinder, matching: find.text('08–16')),
          findsOneWidget,
          reason: key,
        );
      }
    });

    testWidgets('the contrast under each preview is at least 4.5 for every '
        'colour of the grid', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Prueba');

      for (final color in ShiftPalette.editorChoices) {
        final value = color.toARGB32();
        final key = 'shift-color-${value.toRadixString(16)}';
        await tapKey(tester, key);
        for (final (previewKey, brightness) in [
          ('preview-light', Brightness.light),
          ('preview-dark', Brightness.dark),
        ]) {
          final swatch = ShiftSwatch.forColor(value, brightness);
          expect(
            contrastRatio(swatch.ink, swatch.tint),
            greaterThanOrEqualTo(kTextContrast),
            reason: '$key ${brightness.name} on the tint',
          );
          expect(
            contrastRatio(swatch.ink, swatch.disc),
            greaterThanOrEqualTo(kTextContrast),
            reason: '$key ${brightness.name} on the disc',
          );
          // What the screen prints is that same ratio.
          final shown = find.descendant(
            of: _key(previewKey),
            matching: find.textContaining('Contraste '),
          );
          expect(shown, findsOneWidget);
          final text = tester.widget<Text>(shown).data!;
          final printed = double.parse(
            text
                .replaceFirst('Contraste ', '')
                .replaceFirst(':1', '')
                .replaceAll(',', '.'),
          );
          expect(
            printed,
            greaterThanOrEqualTo(kTextContrast),
            reason: '$key $text',
          );
          expect(printed, closeTo(shiftInkContrast(value, brightness), 0.06));
        }
      }
    });

    testWidgets('the preview follows the colour that is picked', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Prueba');

      const pink = 0xFFD6336C;
      await tapKey(tester, 'shift-color-${pink.toRadixString(16)}');
      for (final (key, brightness) in [
        ('preview-light', Brightness.light),
        ('preview-dark', Brightness.dark),
      ]) {
        final code = find.descendant(
          of: find.descendant(of: _key(key), matching: find.byType(DayCell)),
          matching: find.text('P'),
        );
        expect(
          tester.widget<Text>(code).style!.color,
          ShiftSwatch.forColor(pink, brightness).ink,
          reason: key,
        );
      }
    });

    testWidgets('«Más colores…» opens the picker: hex, sliders, live preview '
        'and the colour is saved', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Prueba');

      await tapKey(tester, 'shift-color-more');
      expect(find.text('Elige tu color'), findsOneWidget);
      // The preview is inside the sheet too (two sets of light / dark cells).
      expect(_key('preview-light'), findsNWidgets(2));

      // A typed hex moves the sliders and the preview of the sheet.
      const teal = 0xFF1C9AB5;
      await tester.enterText(_key('color-hex'), '#1C9AB5');
      await tester.pump();
      final slider = tester.widget<Slider>(_key('color-hue'));
      expect(slider.value, closeTo(190, 3));
      for (final (key, brightness) in [
        ('preview-light', Brightness.light),
        ('preview-dark', Brightness.dark),
      ]) {
        final code = find.descendant(
          of: find
              .descendant(of: _key(key).last, matching: find.byType(DayCell))
              .last,
          matching: find.text('P'),
        );
        expect(
          tester.widget<Text>(code).style!.color,
          ShiftSwatch.forColor(teal, brightness).ink,
          reason: key,
        );
      }

      // Moving a slider rewrites the hex text.
      final hexBefore = _text(tester, 'color-hex')!.text;
      await tester.drag(_key('color-lightness'), const Offset(60, 0));
      await tester.pump();
      expect(_text(tester, 'color-hex')!.text, isNot(hexBefore));
      expect(_text(tester, 'color-hex')!.text, matches(r'^#[0-9A-F]{6}$'));

      // Back to the typed colour and use it.
      await tester.enterText(_key('color-hex'), '1c9ab5');
      await tester.pump();
      await tester.tap(_key('color-use'));
      await tester.pumpAndSettle();
      expect(find.text('Elige tu color'), findsNothing);
      // The editor now shows the colour as the current one, outside the grid.
      expect(_key('shift-color-current'), findsOneWidget);

      await save(tester);
      final saved = stateOf(tester).palette.last;
      expect(saved.name, 'Prueba');
      expect(saved.colorValue, teal);
      final stored = await storedSnapshot(tester);
      expect(stored.schedule.shiftTypeById(saved.id)!.colorValue, teal);
    });

    testWidgets('a bad hex disables «Usar este color» and says why', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await tapKey(tester, 'shift-color-more');

      await tester.enterText(_key('color-hex'), '#12');
      await tester.pump();
      expect(find.textContaining('Escribe 6 cifras'), findsOneWidget);
      expect(tester.widget<PrimaryButton>(_key('color-use')).onPressed, isNull);

      await tester.enterText(_key('color-hex'), '#123ABC');
      await tester.pump();
      expect(find.textContaining('Escribe 6 cifras'), findsNothing);
      expect(
        tester.widget<PrimaryButton>(_key('color-use')).onPressed,
        isNotNull,
      );
    });

    testWidgets('cancelling the picker keeps the colour; the current swatch '
        'reopens it', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await tapKey(tester, 'shift-color-more');
      await tester.enterText(_key('color-hex'), '#1C9AB5');
      await tester.pump();
      await tester.tap(_key('color-use'));
      await tester.pumpAndSettle();

      await tapKey(tester, 'shift-color-current');
      expect(find.text('Elige tu color'), findsOneWidget);
      expect(_text(tester, 'color-hex')!.text, '#1C9AB5');
      await tester.enterText(_key('color-hex'), '#FF0000');
      await tester.pump();
      await tester.tap(_key('color-cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Elige tu color'), findsNothing);

      // Still the teal one.
      await tapKey(tester, 'shift-color-current');
      expect(_text(tester, 'color-hex')!.text, '#1C9AB5');
    });

    testWidgets('the grid has the 8 defaults and 16 extra colours', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      expect(ShiftPalette.editorChoices, hasLength(24));
      for (final color in ShiftPalette.editorChoices) {
        expect(
          _key('shift-color-${color.toARGB32().toRadixString(16)}'),
          findsOneWidget,
        );
      }
    });
  });
}
