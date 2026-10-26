import 'package:cuadrante/core/format/text_wrap.dart';
import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/patterns/application/post_night_provider.dart';
import 'package:cuadrante/features/patterns/domain/pattern_application.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../calendar/harness.dart';

const _oct24 = CivilDate(2026, 10, 24);
const _oct26 = CivilDate(2026, 10, 26);
const _oct29 = CivilDate(2026, 10, 29);

/// The provider container, also while another screen is on top of the month.
ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(CuadranteApp)));

Schedule _schedule(WidgetTester tester) =>
    _container(tester).read(scheduleControllerProvider).schedule;

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _longPress(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.longPress(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Paint mode, then the "Patrón" button of its header.
Future<void> _openWizard(WidgetTester tester) async {
  await pumpCalendar(tester);
  await enterPaintMode(tester);
  await tester.tap(_key('paint-pattern'));
  await tester.pumpAndSettle();
  expect(find.text('Aplicar patrón'), findsOneWidget);
}

String _stepTitle(WidgetTester tester) =>
    (tester.widget(_key('pattern-step-title')) as Text).data!;

/// Codes drawn in the preview cell of [date], in order.
List<String> _previewCodes(WidgetTester tester, CivilDate date) {
  final cell = _key('preview-${date.toIso()}');
  final texts = find.descendant(of: cell, matching: find.byType(Text));
  return [for (final e in texts.evaluate()) (e.widget as Text).data!];
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    // The real font (Roboto): the preview cells are narrow and the test font,
    // twice as wide, would not fit the whole time range in them.
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  group('step 1: the choice', () {
    testWidgets('cards grouped by profession, each with its chips and length', (
      tester,
    ) async {
      await _openWizard(tester);
      expect(find.text('Paso 1 de 3'), findsOneWidget);
      expect(_stepTitle(tester), 'Elige un patrón');
      expect(find.text('CREAR EL MÍO'), findsNothing);
      expect(_key('pattern-create-own'), findsOneWidget);

      for (final group in [
        'SANIDAD',
        'POLICÍA Y GUARDIA CIVIL',
        'BOMBEROS',
        'INDUSTRIA',
        'SEGURIDAD',
      ]) {
        await tester.scrollUntilVisible(
          find.text(group),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(group), findsOneWidget);
      }
      for (final id in patternPresets.map((p) => p.id)) {
        expect(_key('pattern-card-$id'), findsOneWidget, reason: id);
      }
      // A card: name, "28 días" and its sequence as chips with code.
      final dupont = _key('pattern-card-dupont');
      await tester.scrollUntilVisible(
        dupont,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(of: dupont, matching: find.text('DuPont')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dupont, matching: find.text('28 días')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dupont, matching: find.text('N12')),
        findsNWidgets(7),
      );
      // Next stays off until something is picked.
      final next = tester.widget<FilledButton>(
        find.descendant(
          of: _key('pattern-next'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(next.onPressed, isNull);
    });
  });

  group('the whole flow', () {
    testWidgets(
      'preset, start, day of the cycle, preview equals the engine, apply, undo',
      (tester) async {
        await _openWizard(tester);
        final before = _schedule(tester).runs;

        // 1: 24 x 72.
        await _tap(tester, _key('pattern-card-24x72'));
        await _tap(tester, _key('pattern-next'));
        expect(find.text('Paso 2 de 3'), findsOneWidget);

        // 2: start on Monday 26 October through the date picker.
        await _tap(tester, _key('pattern-start-date'));
        await tester.tap(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('26'),
          ),
        );
        await tester.pumpAndSettle();
        // The dialog's confirm button is its last text button.
        await tester.tap(
          find
              .descendant(
                of: find.byType(DatePickerDialog),
                matching: find.byType(TextButton),
              )
              .last,
        );
        await tester.pumpAndSettle();
        expect(find.text('Lunes 26 de octubre 2026'), findsOneWidget);

        // Today is the second day of the cycle (a Libre).
        expect(
          find.text(keepTimeRangesTogether('Ese día te toca: Guardia 24 h 08:00–08:00')),
          findsOneWidget,
        );
        await _tap(tester, _key('offset-1'));
        expect(find.text('Ese día te toca: Libre'), findsOneWidget);

        // The preview is the engine's result for exactly these choices.
        final request = PatternRequest(
          pattern: _schedule(tester).patternById('24x72')!,
          from: _oct26,
          stepOffset: 1,
        );
        final expected = planPatternApplication(
          _schedule(tester),
          request,
          seq: 99,
        ).schedule;
        await tester.scrollUntilVisible(
          _key('preview-2026-10-31'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        for (var i = 0; i < 12; i++) {
          final day = _oct26.addDays(i);
          final codes = expected.resolve(day).shifts.map((s) => s.code);
          expect(
            _previewCodes(tester, day),
            containsAll(codes),
            reason: '$day',
          );
        }
        // Libre, Libre, Libre, then a guard on Thursday 29.
        expect(_previewCodes(tester, _oct26), contains('L'));
        expect(_previewCodes(tester, _oct29), contains('G'));
        // Nothing has changed yet.
        expect(_schedule(tester).runs, before);

        // 3: no end, respect my days (the defaults), apply.
        await _tap(tester, _key('pattern-next'));
        expect(find.text('Paso 3 de 3'), findsOneWidget);
        await _tap(tester, _key('pattern-apply'));

        // Back on the month screen, still painting, with an undo offer.
        expect(find.text('Aplicar patrón'), findsNothing);
        expect(find.text('Listo'), findsOneWidget);
        expect(find.text('Patrón aplicado'), findsOneWidget);
        final schedule = _schedule(tester);
        expect(idsOn(schedule, _oct29), 'guard24');
        expect(idsOn(schedule, _oct26), 'rest');
        expect(schedule.runs, hasLength(before.length + 1));
        final added = schedule.runs.firstWhere((r) => r.patternId == '24x72');
        expect(added.stepOffset, 1);
        expect(added.startDate, _oct26);
        expect(added.endDate, isNull);
        expect(
          schedule.runs.firstWhere((r) => r.id == before.single.id).endDate,
          _oct26.addDays(-1),
        );
        expect(find.text('G'), findsWidgets);

        // ONE undo gives the runs back exactly.
        await tester.tap(_key('undo'));
        await tester.pumpAndSettle();
        expect(_schedule(tester).runs, before);
        expect(idsOn(_schedule(tester), _oct29), 'morning');
        expect(
          _container(tester).read(scheduleControllerProvider).canUndo,
          isFalse,
        );
      },
    );

    testWidgets('"Deshacer" in the snack bar undoes the whole application', (
      tester,
    ) async {
      await _openWizard(tester);
      final before = _schedule(tester).runs;
      await _tap(tester, _key('pattern-card-6x4'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-apply'));
      expect(_schedule(tester).runs, hasLength(before.length + 1));

      await tester.tap(find.text('Deshacer').last);
      await tester.pumpAndSettle();
      expect(_schedule(tester).runs, before);
    });

    testWidgets('"Deshacer" in the snack bar leaves a later stroke alone', (
      tester,
    ) async {
      await _openWizard(tester);
      final before = _schedule(tester).runs;
      await _tap(tester, _key('pattern-card-6x4'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-apply'));
      expect(_schedule(tester).runs, hasLength(before.length + 1));

      // A paint stroke right after: it is now the last step.
      final controller = _container(tester)
          .read(scheduleControllerProvider.notifier);
      controller
        ..beginStroke(const PaintTool.replace('guard24'))
        ..paintDay(_oct24)
        ..endStroke();
      await tester.pump();
      expect(idsOn(_schedule(tester), _oct24), 'guard24');

      await tester.tap(find.text('Deshacer').last);
      await tester.pumpAndSettle();
      expect(idsOn(_schedule(tester), _oct24), 'guard24');
      expect(_schedule(tester).runs, hasLength(before.length + 1));
    });

    testWidgets('until a date, replacing my days, with the preview following', (
      tester,
    ) async {
      await _openWizard(tester);
      final wed21 = const CivilDate(2026, 10, 21); // hand-made Mañana + Tarde
      expect(idsOn(_schedule(tester), wed21), 'morning+afternoon');

      await _tap(tester, _key('pattern-card-5x2'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-next'));

      // Step 3: "Hasta una fecha" shows the date; "Sin fin" is the default.
      expect(_key('pattern-until-date'), findsNothing);
      await _tap(tester, _key('pattern-end-until'));
      expect(_key('pattern-until-date'), findsOneWidget);
      // Respect is on by default: the preview keeps the double shift.
      expect(_previewCodes(tester, wed21), containsAll(['M', 'T']));
      await _tap(tester, _key('pattern-replace-overrides'));
      expect(_previewCodes(tester, wed21), unorderedEquals(['21', 'M', '06–14']));

      await _tap(tester, _key('pattern-apply'));
      final s = _schedule(tester);
      expect(idsOn(s, wed21), 'morning', reason: 'my change was replaced');
      final run = s.runs.firstWhere((r) => r.patternId == '5x2');
      expect(run.startDate, fixedToday);
      expect(run.endDate, fixedToday.addDays(89));
    });

    testWidgets('back goes one step; the choice and dates are kept', (
      tester,
    ) async {
      await _openWizard(tester);
      await _tap(tester, _key('pattern-card-4x4'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('offset-3'));
      await _tap(tester, _key('pattern-back'));
      expect(find.text('Paso 1 de 3'), findsOneWidget);
      await _tap(tester, _key('pattern-next'));
      expect(
        find.text(keepTimeRangesTogether('Ese día te toca: Día 12 h 08:00–20:00')),
        findsOneWidget,
      );
    });

    testWidgets('a pattern that needs a missing type creates it on apply', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        prepare: (repository) async {
          // The user removed the 12 h types and the Continental pattern.
          await repository.archiveShiftType('night12');
        },
      );
      await enterPaintMode(tester);
      await tester.tap(_key('paint-pattern'));
      await tester.pumpAndSettle();
      await _tap(tester, _key('pattern-card-dupont'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-apply'));
      expect(idsOn(_schedule(tester), fixedToday), 'night12');
      expect(find.text('N12'), findsWidgets);
    });
  });

  group('my own sequence', () {
    testWidgets('built with taps, several shifts per day, saved and applied', (
      tester,
    ) async {
      await _openWizard(tester);
      await _tap(tester, _key('pattern-create-own'));
      expect(_key('builder-name'), findsOneWidget);
      expect(
        find.text('Toca los turnos de abajo para ir añadiendo días.'),
        findsOneWidget,
      );
      // Nothing to continue with yet.
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: _key('pattern-next'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );

      await _tap(tester, _key('builder-add-morning'));
      await _tap(tester, _key('builder-add-morning'));
      await _tap(tester, _key('builder-add-night'));
      expect(find.text('3 días'), findsOneWidget);
      // "Varios turnos en un día": the Tarde joins the Noche.
      await _tap(tester, _key('builder-same-day'));
      await _tap(tester, _key('builder-add-afternoon'));
      expect(find.text('3 días'), findsOneWidget);
      await _tap(tester, _key('builder-same-day'));
      await _tap(tester, _key('builder-add-rest'));
      expect(find.text('4 días'), findsOneWidget);

      // Remove the last (the Libre), then the Tarde of the third day.
      await _tap(tester, _key('builder-remove-last'));
      expect(find.text('3 días'), findsOneWidget);
      await _tap(tester, _key('builder-remove-last'));
      expect(find.text('3 días'), findsOneWidget);
      await _tap(tester, _key('builder-remove-last'));
      expect(find.text('2 días'), findsOneWidget);
      // Clear and start again.
      await _tap(tester, _key('builder-clear'));
      expect(find.text('0 días'), findsOneWidget);
      await _tap(tester, _key('builder-add-night'));
      await _tap(tester, _key('builder-same-day'));
      await _tap(tester, _key('builder-add-afternoon'));
      await _tap(tester, _key('builder-same-day'));
      await _tap(tester, _key('builder-add-rest'));
      await _tap(tester, _key('builder-add-rest'));

      await tester.enterText(_key('builder-name'), 'Doblo noches');
      await tester.pumpAndSettle();

      await _tap(tester, _key('pattern-next'));
      // Step 2 offers this sequence's days.
      expect(_key('offset-0'), findsOneWidget);
      expect(_key('offset-2'), findsOneWidget);
      expect(_key('offset-3'), findsNothing);
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-apply'));

      final s = _schedule(tester);
      final pattern = s.patterns.firstWhere((p) => p.name == 'Doblo noches');
      expect(pattern.steps, [
        ['night', 'afternoon'],
        ['rest'],
        ['rest'],
      ]);
      expect(pattern.id, startsWith('custom-'));
      expect(idsOn(s, fixedToday), 'night+afternoon');
      expect(idsOn(s, fixedToday.addDays(1)), 'rest');
      expect(idsOn(s, fixedToday.addDays(6)), 'night+afternoon');

      // It is stored: the next wizard lists it under "Mis patrones".
      await tester.pumpAndSettle();
      await tester.tap(_key('paint-pattern'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('MIS PATRONES'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_key('pattern-card-${pattern.id}'), findsOneWidget);
      expect(find.text('Doblo noches'), findsWidgets);
    });

    testWidgets('an unnamed sequence is called "Mi patrón"', (tester) async {
      await _openWizard(tester);
      await _tap(tester, _key('pattern-create-own'));
      await _tap(tester, _key('builder-add-morning'));
      await _tap(tester, _key('builder-add-rest'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-apply'));
      expect(
        _schedule(tester).patterns.map((p) => p.name),
        contains('Mi patrón'),
      );
    });

    testWidgets('back from the builder returns to the list', (tester) async {
      await _openWizard(tester);
      await _tap(tester, _key('pattern-create-own'));
      await _tap(tester, _key('builder-back'));
      expect(_key('pattern-create-own'), findsOneWidget);
    });
  });

  group('"aplicar patrón desde este día"', () {
    testWidgets('long press a puck, tap the day: the wizard opens there', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      final before = _schedule(tester);

      await _longPress(tester, _key('tool-guard24'));
      await tester.pumpAndSettle();
      expect(_key('pattern-pick-banner'), findsOneWidget);
      expect(find.text('Toca el día en que empieza el patrón'), findsOneWidget);
      // The puck is the brush now.
      expect(
        _container(tester).read(paintControllerProvider).shiftTypeId,
        'guard24',
      );

      await _tap(tester, cell(_oct24));

      // Wizard at step 1 with that day, and 24 x 72 (starts with a guard) first.
      expect(find.text('Aplicar patrón'), findsOneWidget);
      expect(find.text('Paso 1 de 3'), findsOneWidget);
      expect(find.text('Desde el sábado 24 de octubre'), findsOneWidget);
      expect(find.text('EMPIEZAN POR GUARDIA 24 H'), findsOneWidget);
      final typical = tester.getTopLeft(_key('pattern-card-24x72'));
      final other = tester.getTopLeft(_key('pattern-card-correturnos'));
      expect(typical.dy, lessThan(other.dy));
      // The tap did not paint the day.
      expect(_schedule(tester).entries, before.entries);

      // Step 2 starts on the tapped day.
      await _tap(tester, _key('pattern-card-24x72'));
      await _tap(tester, _key('pattern-next'));
      expect(find.text('Sábado 24 de octubre 2026'), findsOneWidget);
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-apply'));
      expect(idsOn(_schedule(tester), _oct24), 'guard24');
      expect(idsOn(_schedule(tester), _oct24.addDays(8)), 'guard24');
      // The pick is over: the next tap paints again.
      expect(_key('pattern-pick-banner'), findsNothing);
      await _tap(tester, _key('tool-rest'));
      await tester.tap(cell(_oct24));
      await tester.pumpAndSettle();
      expect(idsOn(_schedule(tester), _oct24), 'rest');
    });

    testWidgets(
      'when no preset starts with the shift, the ones that include it',
      (tester) async {
        await pumpCalendar(tester);
        await enterPaintMode(tester);
        await _longPress(tester, _key('tool-night'));
        await tester.pumpAndSettle();
        await _tap(tester, cell(_oct24));
        expect(find.text('INCLUYEN NOCHE'), findsOneWidget);
        final first = tester.getTopLeft(_key('pattern-card-correturnos'));
        final later = tester.getTopLeft(_key('pattern-card-24x72'));
        expect(first.dy, lessThan(later.dy));
      },
    );

    testWidgets('Cancelar drops the pick; leaving paint mode too', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      await _longPress(tester, _key('tool-night'));
      await tester.pumpAndSettle();
      await tester.tap(_key('pattern-pick-cancel'));
      await tester.pumpAndSettle();
      expect(_key('pattern-pick-banner'), findsNothing);
      await tester.tap(cell(_oct24));
      await tester.pumpAndSettle();
      expect(find.text('Aplicar patrón'), findsNothing);
      expect(idsOn(_schedule(tester), _oct24), 'night');

      await _longPress(tester, _key('tool-morning'));
      await tester.pumpAndSettle();
      expect(_key('pattern-pick-banner'), findsOneWidget);
      await tester.tap(_key('paint-done'));
      await tester.pumpAndSettle();
      await enterPaintMode(tester);
      expect(_key('pattern-pick-banner'), findsNothing);
    });

    testWidgets('the eraser opens the same flow without a shift hint', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await enterPaintMode(tester);
      await _longPress(tester, _key('tool-eraser'));
      await tester.pumpAndSettle();
      await _tap(tester, cell(_oct24));
      expect(find.text('Desde el sábado 24 de octubre'), findsOneWidget);
      expect(find.textContaining('EMPIEZAN POR'), findsNothing);
      expect(find.textContaining('INCLUYEN'), findsNothing);
    });
  });

  group('Saliente automático in the preview', () {
    testWidgets('the preview shows the saliente days the apply will add', (
      tester,
    ) async {
      await _openWizard(tester);
      await tester.runAsync(
        () => _container(tester).read(postNightAutoProvider.notifier).set(true),
      );
      await _tap(tester, _key('pattern-card-24x72'));
      await _tap(tester, _key('pattern-next'));
      await _tap(tester, _key('pattern-next'));
      expect(_key('pattern-preview-post-night'), findsOneWidget);
      // Today (19 Oct) is the guard; the 20th is the saliente.
      expect(_previewCodes(tester, fixedToday), contains('G'));
      expect(_previewCodes(tester, fixedToday.addDays(1)), contains('S'));
      await _tap(tester, _key('pattern-apply'));
      expect(idsOn(_schedule(tester), fixedToday.addDays(1)), 'postNight');
      await tester.tap(_key('undo'));
      await tester.pumpAndSettle();
      expect(idsOn(_schedule(tester), fixedToday.addDays(1)), 'night');
    });
  });
}
