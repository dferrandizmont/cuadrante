import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/selection_controller.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

// Demo data around Monday 19 Oct 2026 (see range_edit_controller_test.dart):
// Noche 19-23 (20 note only, 21 Mañana + Tarde, 22 empty), Libre 24-25,
// Mañana 26-30 (27-28 Vacaciones), Libre 31 Oct-1 Nov, Tarde from 2 Nov.
const oct19 = CivilDate(2026, 10, 19);
const oct20 = CivilDate(2026, 10, 20);
const oct21 = CivilDate(2026, 10, 21);
const oct22 = CivilDate(2026, 10, 22);
const oct23 = CivilDate(2026, 10, 23);
const oct24 = CivilDate(2026, 10, 24);
const oct25 = CivilDate(2026, 10, 25);
const oct26 = CivilDate(2026, 10, 26);
const oct27 = CivilDate(2026, 10, 27);
const oct30 = CivilDate(2026, 10, 30);
const nov2 = CivilDate(2026, 11, 2);
const nov9 = CivilDate(2026, 11, 9);

Finder _key(String key) => find.byKey(ValueKey(key));

SelectionState _selection(WidgetTester tester) =>
    containerOf(tester).read(selectionControllerProvider);

Set<CivilDate> _chosen(WidgetTester tester) => _selection(tester).days;

Set<CivilDate> _range(CivilDate from, CivilDate to) => {
  for (var d = from; !d.isAfter(to); d = d.addDays(1)) d,
};

/// Long press on [from] and, with the finger still down, drag to [to].
Future<void> longPressDrag(
  WidgetTester tester,
  CivilDate from,
  CivilDate to,
) async {
  final gesture = await tester.startGesture(tester.getCenter(cell(from)));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  final target = tester.getCenter(cell(to));
  final start = tester.getCenter(cell(from));
  const steps = 6;
  for (var s = 1; s <= steps; s++) {
    await gesture.moveTo(Offset.lerp(start, target, s / steps)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> longPress(WidgetTester tester, CivilDate day) async {
  await revealCell(tester, day);
  await tester.longPress(cell(day));
  await tester.pumpAndSettle();
}

Future<void> tapDay(WidgetTester tester, CivilDate day) async {
  await revealCell(tester, day);
  await tester.tap(cell(day));
  await tester.pumpAndSettle();
}

Future<void> tapTool(WidgetTester tester, String key) async {
  // The tools scroll sideways: reveal the one asked for first.
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

String _ids(WidgetTester tester, CivilDate d) => idsOn(scheduleOf(tester), d);

void main() {
  setUpAll(initializeLocale);

  group('gestures', () {
    testWidgets('a long press starts selection with that day chosen', (
      tester,
    ) async {
      await pumpCalendar(tester);
      expect(_key('selection-bar'), findsNothing);
      expect(find.text('Pintar'), findsOneWidget);

      await longPress(tester, oct21);

      expect(_selection(tester).active, isTrue);
      expect(_chosen(tester), {oct21});
      expect(_key('selection-bar'), findsOneWidget);
      expect(find.text('1 día'), findsOneWidget);
      expect(_key('selected-mark-2026-10-21'), findsOneWidget);
      // No day detail, no Pintar button while selecting.
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Pintar'), findsNothing);
      expect(find.text('SELECCIÓN'), findsOneWidget);
    });

    testWidgets('a tap toggles days and never opens the detail', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await longPress(tester, oct21);

      await tapDay(tester, oct23);
      await tapDay(tester, oct25);
      expect(_chosen(tester), {oct21, oct23, oct25});
      expect(find.text('3 días'), findsOneWidget);

      await tapDay(tester, oct23);
      expect(_chosen(tester), {oct21, oct25});
      expect(find.text('2 días'), findsOneWidget);
      expect(_key('selected-mark-2026-10-23'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);

      // Deselecting the last ones leaves the mode on, with nothing chosen.
      await tapDay(tester, oct21);
      await tapDay(tester, oct25);
      expect(_selection(tester).active, isTrue);
      expect(find.text('Ningún día'), findsOneWidget);
    });

    testWidgets('dragging after the long press extends a linear range, '
        'and back shrinks it', (tester) async {
      await pumpCalendar(tester);
      final gesture = await tester.startGesture(tester.getCenter(cell(oct22)));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      expect(_chosen(tester), {oct22});

      // Down a row: Thursday 22nd to Tuesday 27th, in date order.
      await gesture.moveTo(tester.getCenter(cell(oct27)));
      await tester.pump();
      expect(_chosen(tester), _range(oct22, oct27));
      // The bar waits for the finger to come up (cells must not move).
      expect(_key('selection-bar'), findsNothing);

      // Back past the start: the range follows the finger on the other side.
      await gesture.moveTo(tester.getCenter(cell(oct20)));
      await tester.pump();
      expect(_chosen(tester), _range(oct20, oct22));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_chosen(tester), _range(oct20, oct22));
      expect(_selection(tester).active, isTrue);
    });

    testWidgets('a drag keeps the days chosen before it', (tester) async {
      await pumpCalendar(tester);
      await longPress(tester, oct19);
      await longPressDrag(tester, oct23, oct25);
      expect(_chosen(tester), {oct19, ..._range(oct23, oct25)});
    });

    testWidgets('the selection survives changing month with the arrows', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await longPress(tester, oct30);
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Noviembre'), findsOneWidget);
      expect(_key('selection-bar'), findsOneWidget);

      await tapDay(tester, nov2);
      expect(_chosen(tester), {oct30, nov2});
      expect(find.text('2 días'), findsOneWidget);
      // October's 30th is also drawn in November's grid: still marked.
      expect(_key('selected-mark-2026-10-30'), findsOneWidget);

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      expect(_chosen(tester), {oct30, nov2});
      expect(_key('selected-mark-2026-10-30'), findsOneWidget);
    });

    testWidgets('a horizontal swipe still changes month in selection mode', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await longPress(tester, oct21);
      await tester.fling(cell(oct21), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Noviembre'), findsOneWidget);
      expect(_chosen(tester), {oct21}, reason: 'a swipe does not select');
    });

    testWidgets('paint mode and selection mode exclude each other', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await longPress(tester, oct21);
      expect(_selection(tester).active, isTrue);

      // Paint mode is not reachable from the bar (no FAB) but code can.
      paintOf(tester).enter();
      await tester.pumpAndSettle();
      expect(_selection(tester).active, isFalse);
      expect(_key('selection-bar'), findsNothing);
      expect(find.text('Listo'), findsOneWidget);

      // Long press in paint mode is not selection.
      await tester.longPress(cell(oct22));
      await tester.pumpAndSettle();
      expect(_selection(tester).active, isFalse);

      paintOf(tester).exit();
      await tester.pumpAndSettle();
      await longPress(tester, oct21);
      expect(containerOf(tester).read(paintControllerProvider).active, isFalse);
    });

    testWidgets('Cancelar and the system back button leave the mode', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await longPress(tester, oct21);
      await tapTool(tester, 'selection-cancel');
      expect(_selection(tester).active, isFalse);
      expect(_selection(tester).days, isEmpty);
      expect(find.text('Pintar'), findsOneWidget);
      expect(find.text('SELECCIÓN'), findsNothing);

      await longPress(tester, oct21);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_selection(tester).active, isFalse);
    });

    testWidgets('survives large text, a small screen and the dark theme', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        textScale: 1.6,
        brightness: Brightness.dark,
        size: const Size(320, 568),
      );
      await tester.scrollUntilVisible(
        cell(oct21),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(cell(oct21));
      await tester.pumpAndSettle();
      await longPress(tester, oct21);
      expect(tester.takeException(), isNull);
      expect(_key('selection-bar'), findsOneWidget);
      expect(_key('selected-mark-2026-10-21'), findsOneWidget);
    });
  });

  group('actions: each is ONE undo step', () {
    /// Selects [from]..[to] with a long press and a drag.
    Future<void> selectRange(
      WidgetTester tester,
      CivilDate from,
      CivilDate to,
    ) async {
      await longPressDrag(tester, from, to);
      expect(_chosen(tester), _range(from, to));
    }

    Future<void> undoFromBar(WidgetTester tester) async {
      await tester.tap(_key('undo'));
      await tester.pumpAndSettle();
    }

    testWidgets('Poner turno… sets the shift on the week; undo gives it '
        'back', (tester) async {
      await pumpCalendar(tester);
      final before = scheduleOf(tester);
      await selectRange(tester, oct24, oct30);

      await tapTool(tester, 'selection-set');
      expect(_key('pick-shift-afternoon'), findsOneWidget);
      await tester.tap(_key('pick-shift-afternoon'));
      await tester.pumpAndSettle();

      for (final d in _range(oct24, oct30)) {
        expect(_ids(tester, d), 'afternoon', reason: '$d');
      }
      expect(find.text('7 días cambiados'), findsOneWidget);
      // The selection stays, to chain another action.
      expect(_chosen(tester), _range(oct24, oct30));

      await undoFromBar(tester);
      for (final d in _range(oct24, oct30)) {
        expect(_ids(tester, d), idsOn(before, d), reason: '$d');
      }
      expect(scheduleOf(tester).entries, before.entries);
      expect(
        containerOf(tester).read(scheduleControllerProvider).canUndo,
        isFalse,
      );
    });

    testWidgets('Doblar con… adds the shift to each day', (tester) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct24, oct26);
      await tapTool(tester, 'selection-double');
      await tester.tap(_key('pick-shift-night'));
      await tester.pumpAndSettle();
      expect(_ids(tester, oct24), 'rest+night');
      expect(_ids(tester, oct26), 'morning+night');
      await undoFromBar(tester);
      expect(_ids(tester, oct24), 'rest');
    });

    testWidgets('Borrar and Volver al patrón', (tester) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct21);
      await tapTool(tester, 'selection-clear');
      for (final d in _range(oct19, oct21)) {
        expect(_ids(tester, d), '', reason: '$d');
      }
      // The note of the 20th survives the eraser.
      expect(scheduleOf(tester).entries[oct20]?.note, isNotNull);

      await tapTool(tester, 'selection-reset');
      for (final d in _range(oct19, oct21)) {
        expect(_ids(tester, d), 'night', reason: '$d');
      }
      expect(scheduleOf(tester).entries[oct21], isNull);
      await undoFromBar(tester);
      expect(_ids(tester, oct19), '');
      await undoFromBar(tester);
      expect(_ids(tester, oct21), 'morning+afternoon');
    });

    testWidgets('Nota… writes the same note on all and Quitar notas '
        'removes them', (tester) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct23, oct25);
      await tapTool(tester, 'selection-note');
      await tester.enterText(_key('selection-note-field'), 'Curso de PRL');
      await tester.pump();
      await tester.tap(_key('selection-note-save'));
      await tester.pumpAndSettle();
      for (final d in _range(oct23, oct25)) {
        expect(scheduleOf(tester).entries[d]?.note, 'Curso de PRL');
      }
      expect(_ids(tester, oct23), 'night', reason: 'shifts untouched');

      await tapTool(tester, 'selection-note');
      await tester.tap(_key('selection-note-remove'));
      await tester.pumpAndSettle();
      for (final d in _range(oct23, oct25)) {
        expect(scheduleOf(tester).entries[d], isNull);
      }
    });

    testWidgets('Copiar then Pegar on another Monday, across months', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct25);

      // Nothing copied yet: Pegar is disabled.
      final paste = tester.widget<InkWell>(_key('selection-paste'));
      expect(paste.onTap, isNull);

      await tapTool(tester, 'selection-copy');
      expect(find.textContaining('7 días copiados'), findsOneWidget);
      expect(_selection(tester).active, isTrue);
      expect(_chosen(tester), isEmpty, reason: 'ready to pick the target');
      expect(tester.widget<InkWell>(_key('selection-paste')).onTap, isNull);

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      await tapDay(tester, nov9);
      expect(tester.widget<InkWell>(_key('selection-paste')).onTap, isNotNull);

      final before = scheduleOf(tester);
      await tapTool(tester, 'selection-paste');
      expect(_key('paste-summary'), findsOneWidget);
      expect(
        tester.widget<Text>(_key('paste-summary')).data,
        'Se pegan 7 días a partir del lunes, 9 de noviembre.',
      );
      // The copied days include a note: the switch is offered, off.
      expect(tester.widget<SwitchListTile>(_key('paste-notes')).value, isFalse);
      await tester.tap(_key('paste-confirm'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 7; i++) {
        expect(
          _ids(tester, nov9.addDays(i)),
          idsOn(before, oct19.addDays(i)),
          reason: 'offset $i',
        );
      }
      expect(scheduleOf(tester).entries[nov9.addDays(1)], isNull);
      expect(find.text('7 días pegados'), findsOneWidget);

      await undoFromBar(tester);
      expect(scheduleOf(tester).entries, before.entries);
    });

    testWidgets('Pegar with Incluir notas brings the notes along', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct25);
      await tapTool(tester, 'selection-copy');
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      await tapDay(tester, nov9);
      await tapTool(tester, 'selection-paste');
      await tester.tap(_key('paste-notes'));
      await tester.pumpAndSettle();
      await tester.tap(_key('paste-confirm'));
      await tester.pumpAndSettle();
      expect(
        scheduleOf(tester).entries[nov9.addDays(1)]?.note,
        'Cambio con Marta si sale el turno',
      );
    });

    testWidgets('Pegar after Cortar has no Incluir notas: the notes move with '
        'the days and say so', (tester) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct25);
      expect(
        scheduleOf(tester).entries[oct19.addDays(1)]?.note,
        'Cambio con Marta si sale el turno',
      );
      await tapTool(tester, 'selection-cut');
      expect(scheduleOf(tester).entries[oct19.addDays(1)]?.note, isNull);

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      await tapDay(tester, nov9);
      await tapTool(tester, 'selection-paste');
      expect(_key('paste-notes'), findsNothing);
      expect(
        find.text('Al cortar, las notas se mueven con los días.'),
        findsOneWidget,
      );
      await tester.tap(_key('paste-confirm'));
      await tester.pumpAndSettle();
      expect(
        scheduleOf(tester).entries[nov9.addDays(1)]?.note,
        'Cambio con Marta si sale el turno',
        reason: 'not lost',
      );
    });

    testWidgets(
      'Cortar, Pegar, Pegar elsewhere: the note is not duplicated and '
      'the second paste offers Incluir notas',
      (tester) async {
        const note = 'Cambio con Marta si sale el turno';
        const nov16 = CivilDate(2026, 11, 16);
        int notes() =>
            scheduleOf(tester).entries.values
                .where((e) => e.note == note)
                .length;
        await pumpCalendar(tester);
        await selectRange(tester, oct19, oct25);
        await tapTool(tester, 'selection-cut');
        expect(notes(), 0);

        await tester.tap(find.byTooltip('Mes siguiente'));
        await tester.pumpAndSettle();
        await tapDay(tester, nov9);
        await tapTool(tester, 'selection-paste');
        expect(_key('paste-notes'), findsNothing);
        await tester.tap(_key('paste-confirm'));
        await tester.pumpAndSettle();
        expect(scheduleOf(tester).entries[nov9.addDays(1)]?.note, note);
        expect(notes(), 1);

        await tapDay(tester, nov16);
        await tapTool(tester, 'selection-paste');
        expect(_key('paste-notes'), findsOneWidget);
        expect(
          tester.widget<SwitchListTile>(_key('paste-notes')).value,
          isFalse,
        );
        await tester.tap(_key('paste-confirm'));
        await tester.pumpAndSettle();
        expect(scheduleOf(tester).entries[nov16.addDays(1)]?.note, isNull);
        expect(notes(), 1, reason: 'the note travelled once');
      },
    );

    testWidgets('Cortar, Deshacer, Pegar: the note is not duplicated and Pegar '
        'offers Incluir notas', (tester) async {
      const note = 'Cambio con Marta si sale el turno';
      int notes() =>
          scheduleOf(tester).entries.values.where((e) => e.note == note).length;
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct25);
      await tapTool(tester, 'selection-cut');
      await undoFromBar(tester);
      expect(notes(), 1);

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      await tapDay(tester, nov9);
      await tapTool(tester, 'selection-paste');
      expect(_key('paste-notes'), findsOneWidget);
      await tester.tap(_key('paste-confirm'));
      await tester.pumpAndSettle();
      expect(scheduleOf(tester).entries[nov9.addDays(1)]?.note, isNull);
      expect(notes(), 1);
    });

    testWidgets('a copy still offers the Incluir notas choice', (tester) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct25);
      await tapTool(tester, 'selection-copy');
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      await tapDay(tester, nov9);
      await tapTool(tester, 'selection-paste');
      expect(_key('paste-notes'), findsOneWidget);
      expect(
        find.text('Al cortar, las notas se mueven con los días.'),
        findsNothing,
      );
    });

    testWidgets('Cortar copies and clears; ONE undo brings the days back, the '
        'clipboard stays', (tester) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct25);
      final before = scheduleOf(tester);

      await tapTool(tester, 'selection-cut');
      expect(find.textContaining('7 días cortados'), findsOneWidget);
      expect(_selection(tester).active, isTrue);
      expect(_chosen(tester), isEmpty, reason: 'ready to pick the target');
      for (var i = 0; i < 7; i++) {
        expect(_ids(tester, oct19.addDays(i)), '', reason: 'offset $i');
      }

      // Pegar works on another Monday and gives back what was cut.
      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      await tapDay(tester, nov9);
      expect(tester.widget<InkWell>(_key('selection-paste')).onTap, isNotNull);
      await tapTool(tester, 'selection-paste');
      await tester.tap(_key('paste-confirm'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 7; i++) {
        expect(
          _ids(tester, nov9.addDays(i)),
          idsOn(before, oct19.addDays(i)),
          reason: 'offset $i',
        );
      }

      // Undo the paste, then the cut: ONE step each.
      await undoFromBar(tester);
      await undoFromBar(tester);
      expect(scheduleOf(tester).entries, before.entries);
      expect(
        tester.widget<InkWell>(_key('selection-paste')).onTap,
        isNotNull,
        reason: 'the clipboard keeps the cut days',
      );
    });

    testWidgets('Cortar from the snack bar: Deshacer restores the days', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct20);
      final before = scheduleOf(tester);
      await tapTool(tester, 'selection-cut');
      expect(find.text('Deshacer'), findsWidgets);
      await tester.tap(find.widgetWithText(SnackBarAction, 'Deshacer'));
      await tester.pumpAndSettle();
      expect(scheduleOf(tester).entries, before.entries);
    });

    testWidgets('Cortar is off until something is chosen', (tester) async {
      await pumpCalendar(tester);
      await longPress(tester, oct19);
      expect(tester.widget<InkWell>(_key('selection-cut')).onTap, isNotNull);
      await tapDay(tester, oct19);
      expect(
        tester.widget<InkWell>(_key('selection-cut')).onTap,
        isNull,
        reason: 'nothing chosen',
      );
    });

    testWidgets('the clipboard outlives the mode', (tester) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct21);
      await tapTool(tester, 'selection-copy');
      await tapTool(tester, 'selection-cancel');
      // The "copied" notice sits over the lower rows (the card above is a
      // line taller now): let it go.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await longPress(tester, oct26);
      expect(tester.widget<InkWell>(_key('selection-paste')).onTap, isNotNull);
    });

    testWidgets('Repetir… with a preview; 4 times is ONE undo step', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct25);
      final before = scheduleOf(tester);

      await tapTool(tester, 'selection-repeat');
      expect(find.text('1 vez'), findsOneWidget);
      expect(
        tester.widget<Text>(_key('repeat-preview')).data,
        'Cambia 7 días más, hasta el domingo, 1 de noviembre.',
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(_key('repeat-more'));
        await tester.pump();
      }
      expect(find.text('4 veces'), findsOneWidget);
      expect(
        tester.widget<Text>(_key('repeat-preview')).data,
        'Cambia 28 días más, hasta el domingo, 22 de noviembre.',
      );
      await tester.tap(_key('repeat-confirm'));
      await tester.pumpAndSettle();

      for (var k = 1; k <= 4; k++) {
        for (var i = 0; i < 7; i++) {
          expect(
            _ids(tester, oct19.addDays(7 * k + i)),
            idsOn(before, oct19.addDays(i)),
            reason: 'copy $k offset $i',
          );
        }
      }
      expect(find.text('Repetido 4 veces'), findsOneWidget);

      await undoFromBar(tester);
      expect(scheduleOf(tester).entries, before.entries);
      expect(
        containerOf(tester).read(scheduleControllerProvider).canUndo,
        isFalse,
      );
    });

    testWidgets('the repeat picker goes from 1 to 52', (tester) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct19, oct20);
      await tapTool(tester, 'selection-repeat');
      expect(tester.widget<IconButton>(_key('repeat-less')).onPressed, isNull);
      await tester.drag(_key('repeat-slider'), const Offset(2000, 0));
      await tester.pump();
      expect(find.text('52 veces'), findsOneWidget);
      expect(tester.widget<IconButton>(_key('repeat-more')).onPressed, isNull);
      await tester.tap(_key('repeat-cancel'));
      await tester.pumpAndSettle();
      expect(_ids(tester, oct21), 'morning+afternoon', reason: 'cancelled');
    });

    testWidgets('actions are disabled with nothing chosen', (tester) async {
      await pumpCalendar(tester);
      await longPress(tester, oct21);
      await tapDay(tester, oct21);
      for (final key in [
        'selection-set',
        'selection-double',
        'selection-clear',
        'selection-reset',
        'selection-copy',
        'selection-repeat',
        'selection-note',
      ]) {
        expect(tester.widget<InkWell>(_key(key)).onTap, isNull, reason: key);
      }
    });

    testWidgets('the Deshacer of the snack bar undoes only its own step', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await selectRange(tester, oct24, oct25);
      await tapTool(tester, 'selection-clear');
      expect(_ids(tester, oct24), '');
      await tester.tap(find.widgetWithText(SnackBarAction, 'Deshacer'));
      await tester.pumpAndSettle();
      expect(_ids(tester, oct24), 'rest');
    });
  });
}
