import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/core/widgets/adaptive.dart';
import 'package:cuadrante/core/widgets/app_snack_bar.dart';
import 'package:cuadrante/features/calendar/application/open_day.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/calendar/presentation/paint_bar.dart';
import 'package:cuadrante/features/onboarding/application/onboarding_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import 'harness.dart';
import 'selection_mode_test.dart' show longPress, tapTool;

const _phone = Size(412, 915);
const _landscape = Size(915, 412);
const _tablet = Size(1280, 800);
const _day = CivilDate(2026, 10, 21);

Finder _key(String value) => find.byKey(ValueKey(value));

Finder get _fab => find.byType(FloatingActionButton);

Finder get _noticeSurface => find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

Future<void> _openDay(WidgetTester tester) async {
  await revealCell(tester, _day);
  await tester.tap(cell(_day));
  await tester.pumpAndSettle();
}

/// Put the control at the bottom of its actual scroll viewport: trailing
/// padding alone used to allow this position to lie behind the paint button.
Future<void> _atBottom(WidgetTester tester, Finder control) async {
  await Scrollable.ensureVisible(tester.element(control), alignment: 1);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  testWidgets('H-T24-6: wide notices are compact outside the calendar too', (
    tester,
  ) async {
    await pumpCalendar(tester, size: _tablet, textScale: 2);
    await tester.tap(find.byTooltip('Abrir ajustes'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).last);
    ScaffoldMessenger.of(context).showSnackBar(
      appSnackBar(context: context, content: const Text('Ajustes guardados')),
    );
    await tester.pumpAndSettle();
    final notice = tester.getRect(_noticeSurface);
    expect(notice.width, closeTo(Sp.snackBarMaxWidth, 0.01));
    expect(notice.center.dx, closeTo(_tablet.width / 2, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('H-T24-6: a visible notice follows rotation and the tools', (
    tester,
  ) async {
    await pumpCalendar(tester, size: _tablet, textScale: 2);
    await longPress(tester, _day);
    await tapTool(tester, 'selection-clear');
    for (final size in [_phone, _landscape, _tablet]) {
      tester.view.physicalSize = size * 3;
      await tester.pumpAndSettle();
      final notice = tester.getRect(_noticeSurface);
      final bar = tester.getRect(_key('selection-bar'));
      expect(notice.overlaps(bar), isFalse);
      expect(notice.width, lessThanOrEqualTo(Sp.snackBarMaxWidth));
      if (Adaptive.useSplit(size)) {
        expect(
          notice.right,
          lessThanOrEqualTo(tester.getRect(_key('pane-divider')).left),
        );
      } else {
        expect(notice.left, closeTo(Sp.l, 0.01));
        expect(notice.width, closeTo(size.width - 2 * Sp.l, 0.01));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('H-T24-6: safe area keeps the notice beside the day pane', (
    tester,
  ) async {
    await pumpCalendar(tester, size: _landscape, textScale: 2);
    tester.view.padding = const FakeViewPadding(right: 48 * 3);
    tester.view.viewPadding = const FakeViewPadding(right: 48 * 3);
    addTearDown(() {
      tester.view.resetPadding();
      tester.view.resetViewPadding();
    });
    await tester.pumpAndSettle();
    await longPress(tester, _day);
    await tapTool(tester, 'selection-clear');
    final notice = tester.getRect(_noticeSurface);
    final bar = tester.getRect(_key('selection-bar'));
    final divider = tester.getRect(_key('pane-divider'));
    expect(notice.right, lessThanOrEqualTo(divider.left));
    expect(notice.overlaps(bar), isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final size in [_tablet, _landscape, _phone]) {
    for (final scale in [1.0, 2.0]) {
      final label = '${size.width}x${size.height}, text $scale';

      testWidgets('H-T24-3: keyboard hides Pintar, $label', (tester) async {
        await pumpCalendar(tester, size: size, textScale: scale);
        expect(_fab, findsOneWidget);
        final before = tester.getRect(_fab);
        await _openDay(tester);
        final note = _key('day-note');
        await tester.ensureVisible(note);
        await tester.pumpAndSettle();
        await tester.tap(note);
        await tester.pumpAndSettle();

        final keyboard = size == _landscape ? 100.0 : 280.0;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(_fab, findsNothing, reason: 'no paint button over the note');
        await tester.ensureVisible(note);
        await tester.pumpAndSettle();
        final rect = tester.getRect(note);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height - keyboard + 1));
        await tester.enterText(note, 'Nota con teclado');
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(note).controller!.text,
          'Nota con teclado',
        );

        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(_fab, findsOneWidget);
        expect(tester.getRect(_fab), before);
        expect(tester.takeException(), isNull);
      });

      if (Adaptive.useSplit(size)) {
        testWidgets('H-T24-4: all day controls clear Pintar, $label', (
          tester,
        ) async {
          await pumpCalendar(
            tester,
            size: size,
            textScale: scale,
            prepare: (repository) => repository.saveShiftType(_night12),
          );
          await _openDay(tester);
          final viewport = _key('day-pane-scroll');
          final fab = tester.getRect(_fab);
          expect(tester.getRect(viewport).bottom, lessThanOrEqualTo(fab.top));
          for (final id in [
            'day-overtime-more',
            'day-early-more',
            'day-add-night12',
          ]) {
            final control = _key(id);
            await _atBottom(tester, control);
            final rect = tester.getRect(control);
            expect(rect.overlaps(fab), isFalse, reason: '$id: $rect / $fab');
            expect(rect.bottom, lessThanOrEqualTo(fab.top + 1));
            expect(control.hitTestable(), findsOneWidget);
          }

          // The tip belongs to the other scrolling view of the same pane.
          containerOf(tester).read(openDayProvider.notifier).close();
          containerOf(tester).read(onboardingTipProvider.notifier).show();
          await tester.pumpAndSettle();
          final understood = _key('onboarding-tip-dismiss');
          for (var i = 0; i < 20 && understood.evaluate().isEmpty; i++) {
            await tester.drag(_key('pane-today'), const Offset(0, -150));
            await tester.pumpAndSettle();
          }
          await _atBottom(tester, understood);
          final rect = tester.getRect(understood);
          expect(rect.overlaps(fab), isFalse);
          expect(rect.bottom, lessThanOrEqualTo(fab.top + 1));
          expect(understood.hitTestable(), findsOneWidget);
          await tester.tap(understood);
          await tester.pumpAndSettle();
          expect(_key('onboarding-tip'), findsNothing);
          expect(tester.takeException(), isNull);
        });
      } else {
        testWidgets('H-T24-4: portrait phone keeps its FAB placement, $label', (
          tester,
        ) async {
          await pumpCalendar(tester, size: size, textScale: scale);
          final fab = tester.getRect(_fab);
          expect(fab.right, closeTo(size.width - Sp.l, 0.01));
          expect(fab.bottom, closeTo(size.height - Sp.l, 0.01));
          expect(fab.height, Sp.fabHeight);
        });
      }

      for (final painting in [false, true]) {
        testWidgets('H-T24-6: ${painting ? 'paint' : 'selection'} tools '
            'clear the notice, $label', (tester) async {
          await pumpCalendar(tester, size: size, textScale: scale);
          var undone = false;
          if (painting) {
            await enterPaintMode(tester);
            final context = tester.element(find.byType(MonthScreen));
            ScaffoldMessenger.of(context).showSnackBar(
              appSnackBar(
                context: context,
                content: const Text('Turno cambiado'),
                action: SnackBarAction(
                  label: 'Deshacer',
                  onPressed: () => undone = true,
                ),
              ),
            );
            await tester.pumpAndSettle();
          } else {
            await longPress(tester, _day);
            await tapTool(tester, 'selection-clear');
          }
          final notice = tester.getRect(_noticeSurface);
          final bar = tester.getRect(
            painting ? find.byType(PaintBar) : _key('selection-bar'),
          );
          expect(notice.overlaps(bar), isFalse, reason: '$notice / $bar');
          final undo = find.byType(SnackBarAction);
          expect(tester.getRect(undo).overlaps(bar), isFalse);
          expect(undo.hitTestable(), findsOneWidget);
          expect(notice.top, greaterThanOrEqualTo(0));
          expect(notice.bottom, lessThanOrEqualTo(size.height));
          if (Adaptive.useSplit(size)) {
            expect(notice.width, lessThanOrEqualTo(Sp.snackBarMaxWidth));
            expect(
              notice.right,
              lessThanOrEqualTo(tester.getRect(_key('pane-divider')).left),
            );
          } else {
            expect(notice.left, closeTo(Sp.l, 0.01));
            expect(notice.width, closeTo(size.width - 2 * Sp.l, 0.01));
            expect(notice.bottom, lessThanOrEqualTo(bar.top));
          }
          await tester.tap(undo);
          await tester.pumpAndSettle();
          if (painting) {
            expect(undone, isTrue);
          } else {
            expect(idsOn(scheduleOf(tester), _day), 'morning+afternoon');
          }
          expect(find.byType(SnackBar), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

const _night12 = ShiftType(
  id: 'night12',
  name: 'Noche 12 h',
  code: 'N12',
  colorValue: 0xFF4B4FD1,
  category: ShiftCategory.work,
  startMinute: 20 * 60,
  endMinute: 8 * 60,
);
