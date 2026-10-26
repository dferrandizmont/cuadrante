import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/calendar/application/open_day.dart';
import 'package:cuadrante/features/calendar/application/selection_controller.dart';
import 'package:cuadrante/features/calendar/presentation/paint_bar.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import 'harness.dart';

Finder key(String value) => find.byKey(ValueKey(value));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue);
  });

  for (final size in [const Size(915, 412), const Size(1280, 800)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('paint uses the free pane at $size, text $scale', (
        tester,
      ) async {
        await pumpCalendar(tester, size: size, textScale: scale);
        await enterPaintMode(tester);
        expect(tester.takeException(), isNull);
        final pane = tester.getRect(key('pane-paint'));
        final palette = tester.getRect(find.byType(PaintBar));
        expect(palette.left - pane.left, closeTo(Sp.l, 0.1));
        expect(pane.right - palette.right, closeTo(Sp.l, 0.1));
        expect(palette.bottom, closeTo(pane.bottom - Sp.l, 0.1));
        expect(palette.top, lessThan(pane.center.dy));
        final scroll = tester.widget<SingleChildScrollView>(
          key('paint-tools-scroll'),
        );
        expect(scroll.scrollDirection, Axis.vertical);
        expect(
          tester.getRect(key('undo')).bottom,
          lessThanOrEqualTo(size.height),
        );
        await tester.ensureVisible(key('tool-edit-types'));
        await tester.pumpAndSettle();
        expect(key('tool-edit-types').hitTestable(), findsOneWidget);
        expect(find.text('Listo').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('open day has one date and Today at $size, text $scale', (
        tester,
      ) async {
        await pumpCalendar(tester, size: size, textScale: scale);
        containerOf(tester)
            .read(openDayProvider.notifier)
            .open(const CivilDate(2026, 10, 21));
        await tester.pumpAndSettle();
        expect(
          dateLineText(tester),
          anyOf('Miércoles, 21 de octubre', 'Mié 21 oct'),
        );
        expect(find.text('Lunes, 19 de octubre'), findsNothing);
        expect(
          find.text('Miércoles, 21 de octubre').evaluate().length,
          lessThanOrEqualTo(1),
        );
        expect(key('pane-today-button').hitTestable(), findsOneWidget);
        await tester.tap(key('pane-today-button'));
        await tester.pumpAndSettle();
        expect(containerOf(tester).read(openDayProvider), isNull);
        expect(key('pane-today'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('selection labels wrap in pane at $size, text $scale', (
        tester,
      ) async {
        await pumpCalendar(tester, size: size, textScale: scale);
        containerOf(tester).read(selectionControllerProvider.notifier).enter();
        await tester.pumpAndSettle();
        expect(key('selection-tools-grid'), findsOneWidget);
        final set = tester.getRect(key('selection-set'));
        final note = tester.getRect(key('selection-note'));
        expect(note.top, greaterThan(set.top));
        for (final label in ['Poner turno', 'Doblar con']) {
          final text = find.textContaining(label).last;
          expect(text, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(text);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraph.textScaler.scale(12), closeTo(12 * scale, 0.1));
        }
        await tester.ensureVisible(key('selection-note'));
        await tester.pumpAndSettle();
        expect(key('selection-note').hitTestable(), findsOneWidget);
        expect(
          tester.getSize(key('selection-note')).height,
          greaterThanOrEqualTo(Sp.touch),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('320 dp text 2 retains compact phone paint and selection', (
    tester,
  ) async {
    await pumpCalendar(tester, size: const Size(320, 640), textScale: 2);
    await enterPaintMode(tester);
    expect(key('pane-paint'), findsNothing);
    expect(
      tester.getSize(key('paint-tools-scroll')).height,
      lessThanOrEqualTo(160),
    );
    expect(tester.takeException(), isNull);
    paintOf(tester).exit();
    containerOf(tester).read(selectionControllerProvider.notifier).enter();
    await tester.pumpAndSettle();
    expect(key('selection-tools-grid'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
