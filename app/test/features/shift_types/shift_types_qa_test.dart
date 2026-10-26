import 'package:cuadrante/core/format/text_wrap.dart';
import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import '../calendar/harness.dart';
import 'shift_types_screen_test.dart'
    show
        openNewShift,
        openShiftTypes,
        paletteIds,
        save,
        storedSnapshot,
        tapKey,
        typeInto;

// QA campaign, T05 (Mis turnos): leaving the form lost the changes without
// asking (H-T05-1), words and numbers broke at x2.0 on 320 dp (H-T05-2), an
// archived shift type could not be recovered (H-T05-3), a few details of the
// form (H-T05-5, H-T05-7, H-T05-8).

Finder _key(String key) => find.byKey(ValueKey(key));

/// The back arrow of the app bar.
Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await tester.pumpAndSettle();
}

/// A shift with two segments, like the «Refuerzo» of the QA session.
const _refuerzo = ShiftType(
  id: 'refuerzo',
  code: 'RFX',
  name: 'Refuerzo',
  colorValue: 0xFF00AA55,
  category: ShiftCategory.work,
  startMinute: 8 * 60,
  endMinute: 16 * 60,
  segment2StartMinute: 17 * 60,
  segment2DurationMinutes: 4 * 60,
);

/// Scrolls the list of shift types until [key] is built and on screen (the
/// list builds its rows lazily).
Future<void> revealRow(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    _key(key),
    200,
    scrollable: find.descendant(
      of: _key('shift-list'),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every paragraph on screen: no word and no number is split between two
/// lines.
void expectWholeWords(WidgetTester tester, {required String where}) {
  final broken = <String>[];
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    if (!wrapsOnlyBetweenWords(paragraph)) {
      broken.add(paragraphLines(paragraph).join(' | '));
    }
  }
  expect(broken, isEmpty, reason: '$where: words split between lines');
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  group('H-T05-1: leaving the form asks before dropping changes', () {
    testWidgets('Nuevo turno: back with a name typed asks; «Seguir editando» '
        'keeps everything', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Refuerzo');

      await _back(tester);
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);
      expect(find.text('Seguir editando'), findsOneWidget);
      expect(find.text('Descartar'), findsOneWidget);

      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsNothing);
      expect(_key('shift-name'), findsOneWidget);
      expect(tester.widget<TextField>(_key('shift-name')).controller!.text,
          'Refuerzo');
    });

    testWidgets('«Descartar» leaves and nothing is saved', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      final before = paletteIds(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Refuerzo');

      await _back(tester);
      await tester.pumpAndSettle();
      await tester.tap(_key('shift-discard-confirm'));
      await tester.pumpAndSettle();

      expect(_key('shift-list'), findsOneWidget);
      expect(paletteIds(tester), before);
    });

    testWidgets('the system back button (and gesture) asks too', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await tapKey(tester, 'category-rest');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    });

    testWidgets('a form nobody touched leaves without asking', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await _back(tester);
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsNothing);
      expect(_key('shift-list'), findsOneWidget);
    });

    testWidgets('undoing the change by hand leaves without asking', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'A');
      await typeInto(tester, 'shift-name', '');
      // The code that followed the name went back too.
      await typeInto(tester, 'shift-code', '');
      await _back(tester);
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsNothing);
    });

    testWidgets('editing a stored shift: asks once it differs; saving leaves '
        'without asking', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await tester.tap(_key('shift-row-night'));
      await tester.pumpAndSettle();
      // Opened and left untouched: no question.
      await _back(tester);
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsNothing);

      await tester.tap(_key('shift-row-night'));
      await tester.pumpAndSettle();
      await typeInto(tester, 'shift-name', 'Noche larga');
      await _back(tester);
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);
      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();

      await save(tester);
      expect(find.text('¿Descartar los cambios?'), findsNothing);
      expect(_key('shift-list'), findsOneWidget);
      expect(find.text('Noche larga'), findsOneWidget);
    });
  });

  group('H-T05-3: archived shift types come back', () {
    Future<void> archive(WidgetTester tester, String id) async {
      await tester.ensureVisible(_key('shift-archive-$id'));
      await tester.tap(_key('shift-archive-$id'));
      await tester.pumpAndSettle();
      await tester.tap(_key('confirm-ok'));
      await tester.pumpAndSettle();
    }

    testWidgets('«Archivados (1)» is collapsed; open, «Recuperar» puts the '
        'shift back where it was', (tester) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await openShiftTypes(tester);
      final before = paletteIds(tester);
      expect(_key('shift-archived'), findsNothing);
      // Not the first nor the last one: its place has to come back.
      const id = 'afternoon';
      expect(before.indexOf(id), inInclusiveRange(1, before.length - 2));

      await archive(tester, id);
      expect(paletteIds(tester), isNot(contains(id)));
      expect(find.text('Archivados (1)'), findsOneWidget);
      expect(_key('shift-archived-row-$id'), findsNothing, reason: 'collapsed');

      await tester.tap(_key('shift-archived-toggle'));
      await tester.pumpAndSettle();
      expect(_key('shift-archived-row-$id'), findsOneWidget);

      await tester.tap(_key('shift-restore-$id'));
      await tester.pumpAndSettle();
      expect(paletteIds(tester), before, reason: 'same place');
      expect(_key('shift-archived'), findsNothing);
      expect(_key('shift-row-$id'), findsOneWidget);
      expect(find.textContaining('recuperado'), findsOneWidget);

      // Stored, too.
      final stored = await storedSnapshot(tester);
      expect([for (final t in stored.palette) t.id], before);
    });

    testWidgets('«Deshacer» of the notice archives it again', (tester) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await openShiftTypes(tester);
      const id = 'afternoon';
      await archive(tester, id);
      await tester.tap(_key('shift-archived-toggle'));
      await tester.pumpAndSettle();
      await tester.tap(_key('shift-restore-$id'));
      await tester.pumpAndSettle();
      expect(paletteIds(tester), contains(id));

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(paletteIds(tester), isNot(contains(id)));
      expect(find.text('Archivados (1)'), findsOneWidget);
      final stored = await storedSnapshot(tester);
      expect([for (final t in stored.palette) t.id], isNot(contains(id)));
    });

    testWidgets('with every shift archived the list is the way back', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await openShiftTypes(tester);
      for (final id in paletteIds(tester)) {
        await archive(tester, id);
      }
      expect(paletteIds(tester), isEmpty);
      expect(find.text('No tienes turnos'), findsNothing);
      expect(find.textContaining('Archivados ('), findsOneWidget);
      expect(_key('shift-new'), findsOneWidget);
    });

    for (final width in [320.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$width dp, text $scale: the section breaks no word', (
          tester,
        ) async {
          await pumpCalendar(
            tester,
            size: Size(width, 900),
            textScale: scale,
            prepare: (repository) => repository.saveShiftType(_refuerzo),
          );
          await openShiftTypes(tester);
          await revealRow(tester, 'shift-archive-refuerzo');
          await tester.tap(_key('shift-archive-refuerzo'));
          await tester.pumpAndSettle();
          await tester.tap(_key('confirm-ok'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(_key('shift-archived-toggle'));
          await tester.tap(_key('shift-archived-toggle'));
          await tester.pumpAndSettle();
          expect(_key('shift-restore-refuerzo'), findsOneWidget);
          expectWholeWords(tester, where: 'Archivados $width/$scale');
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('H-T05-2 / H-T05-8: the list and the form at the QA sizes', () {
    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('$width dp, text $scale: «Mis turnos»', (tester) async {
          await pumpCalendar(
            tester,
            size: Size(width, 900),
            textScale: scale,
            prepare: (repository) => repository.saveShiftType(_refuerzo),
          );
          await openShiftTypes(tester);
          await revealRow(tester, 'shift-row-refuerzo');
          expectWholeWords(tester, where: 'Mis turnos $width/$scale');
          expect(tester.takeException(), isNull);
          // The two round buttons stay reachable (inside the row, 48 dp).
          for (final key in ['shift-archive-refuerzo', 'shift-handle-refuerzo']) {
            await tester.ensureVisible(_key(key));
            final rect = tester.getRect(_key(key));
            expect(rect.left, greaterThanOrEqualTo(0), reason: key);
            expect(rect.right, lessThanOrEqualTo(width), reason: key);
          }
        });

        testWidgets('$width dp, text $scale: «Editar turno» with two segments',
            (tester) async {
          await pumpCalendar(
            tester,
            size: Size(width, 900),
            textScale: scale,
            prepare: (repository) => repository.saveShiftType(_refuerzo),
          );
          await openShiftTypes(tester);
          await revealRow(tester, 'shift-row-refuerzo');
          await tester.tap(_key('shift-row-refuerzo'));
          await tester.pumpAndSettle();
          expect(_key('shift-start2'), findsOneWidget);
          expectWholeWords(tester, where: 'Editar turno $width/$scale');

          // Walk down the form: the lazy parts get built and checked too.
          final scroll = tester.state<ScrollableState>(
            find.byType(Scrollable).first,
          );
          for (var i = 0; i < 12; i++) {
            expectWholeWords(tester, where: 'Editar turno $width/$scale #$i');
            await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
            await tester.pumpAndSettle();
            if (scroll.position.pixels >= scroll.position.maxScrollExtent) {
              break;
            }
          }
          expectWholeWords(tester, where: 'Editar turno $width/$scale (end)');
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('x2.0 on 320 dp: the time buttons stack, one under the other',
        (tester) async {
      await pumpCalendar(
        tester,
        size: const Size(320, 900),
        textScale: 2.0,
        prepare: (repository) => repository.saveShiftType(_refuerzo),
      );
      await openShiftTypes(tester);
      await revealRow(tester, 'shift-row-refuerzo');
      await tester.tap(_key('shift-row-refuerzo'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('shift-start'));
      final start = tester.getRect(_key('shift-start'));
      final end = tester.getRect(_key('shift-end'));
      expect(end.top, greaterThanOrEqualTo(start.bottom));
      expect(start.width, closeTo(end.width, 0.5));
    });

    testWidgets('x1.0 on 412 dp: they stay side by side', (tester) async {
      await pumpCalendar(
        tester,
        size: const Size(412, 900),
        prepare: (repository) => repository.saveShiftType(_refuerzo),
      );
      await openShiftTypes(tester);
      await revealRow(tester, 'shift-row-refuerzo');
      await tester.tap(_key('shift-row-refuerzo'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('shift-start'));
      final start = tester.getRect(_key('shift-start'));
      final end = tester.getRect(_key('shift-end'));
      expect(end.left, greaterThan(start.right));
      expect(end.top, closeTo(start.top, 0.5));
    });
  });

  testWidgets('H-T05-8: a shift with two segments gives its times a line of '
      'their own; one with a single range stays on one line', (tester) async {
    await pumpCalendar(
      tester,
      size: const Size(412, 900),
      prepare: (repository) => repository.saveShiftType(_refuerzo),
    );
    await openShiftTypes(tester);
    List<String> lines(String key) {
      final text = find.descendant(
        of: _key(key),
        matching: find.textContaining('Trabajo'),
      );
      return paragraphLines(tester.renderObject<RenderParagraph>(text.first));
    }

    expect(lines('shift-row-morning'), [
      keepTimeRangesTogether('06:00–14:00 · Trabajo'),
    ]);
    await revealRow(tester, 'shift-row-refuerzo');
    expect(lines('shift-row-refuerzo'), [
      keepTimeRangesTogether('08:00–16:00 · 17:00–21:00'),
      'Trabajo',
    ]);
  });

  testWidgets('H-T05-6: the chosen icon has a mark you can see, on that '
      'tile only', (tester) async {
    await pumpCalendar(tester, size: const Size(390, 1400));
    await openShiftTypes(tester);
    await openNewShift(tester);
    await tapKey(tester, 'shift-icon');
    // Nothing chosen yet: «Sin icono» carries it.
    expect(_key('shift-icon-selected-mark'), findsOneWidget);
    expect(
      find.descendant(
        of: _key('shift-icon-none'),
        matching: _key('shift-icon-selected-mark'),
      ),
      findsOneWidget,
    );
    final size = tester.getSize(_key('shift-icon-selected-mark'));
    expect(size.shortestSide, greaterThanOrEqualTo(18));

    await tapKey(tester, 'shift-icon-hospital');
    await tapKey(tester, 'shift-icon');
    expect(
      find.descendant(
        of: _key('shift-icon-hospital'),
        matching: _key('shift-icon-selected-mark'),
      ),
      findsOneWidget,
    );
    expect(_key('shift-icon-selected-mark'), findsOneWidget);
  });

  group('H-T05-5 / H-T05-7: units and spacing in the form', () {
    testWidgets('the break hint and empty rate are clear before typing', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await openShiftTypes(tester);
      await openNewShift(tester);
      await tester.ensureVisible(_key('shift-break'));
      await tester.pump();
      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('Sin precio'), findsOneWidget);
      await typeInto(tester, 'shift-rate', '12');
      expect(find.text('€/h'), findsOneWidget);
    });

    testWidgets('«Dura 8 h» does not touch the «Turno partido» title', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(390, 1400));
      await openShiftTypes(tester);
      await openNewShift(tester);
      await tester.ensureVisible(_key('shift-times-summary'));
      await tester.pump();
      final summary = tester.getRect(_key('shift-times-summary'));
      final title = tester.getRect(find.text('Turno partido'));
      expect(
        title.top - summary.bottom,
        greaterThanOrEqualTo(8),
        reason: 'the summary ($summary) leaves room above «Turno partido»',
      );
    });
  });
}
