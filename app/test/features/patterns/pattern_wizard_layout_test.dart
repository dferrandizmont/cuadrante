import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import '../calendar/harness.dart';

// QA campaign, T06: the pattern wizard broke words at x2.0 on 320 dp
// («Correturno / s», «Atr / ás», H-T06-3); the builder's row of shifts was cut
// at the edge (H-T06-5) and «Varios turnos en un día» was not explained
// (H-T06-4).

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _openWizard(
  WidgetTester tester, {
  required Size size,
  required double scale,
}) async {
  await pumpCalendar(tester, size: size, textScale: scale);
  await enterPaintMode(tester);
  await tester.tap(_key('paint-pattern'));
  await tester.pumpAndSettle();
  expect(find.text('Aplicar patrón'), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// Whole screen, scrolled to the top and then down to the end: nothing
/// breaks inside a word.
Future<void> _expectWholeWords(WidgetTester tester, String where) async {
  final scrollable = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(0);
  for (var i = 0; i < 30; i++) {
    await tester.pump();
    expect(brokenParagraphs(tester), isEmpty, reason: '$where (scroll $i)');
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(
      (position.pixels + 300).clamp(0, position.maxScrollExtent).toDouble(),
    );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      final size = Size(width, width < 400 ? 640 : 892);
      final where = '$width dp, text $scale';

      testWidgets('$where: step 1 (the patterns)', (tester) async {
        await _openWizard(tester, size: size, scale: scale);
        await _expectWholeWords(tester, 'paso 1, $where');
        expect(tester.takeException(), isNull);
      });

      testWidgets('$where: steps 2 and 3, with «Atrás» and the main button', (
        tester,
      ) async {
        await _openWizard(tester, size: size, scale: scale);
        await _tap(tester, 'pattern-card-correturnos');
        await _tap(tester, 'pattern-next');
        expect(_key('pattern-back'), findsOneWidget);
        await _expectWholeWords(tester, 'paso 2, $where');
        await _tap(tester, 'pattern-next');
        expect(_key('pattern-apply'), findsOneWidget);
        await _expectWholeWords(tester, 'paso 3, $where');
        expect(tester.takeException(), isNull);
      });

      testWidgets('$where: «Crear el mío»', (tester) async {
        await _openWizard(tester, size: size, scale: scale);
        await _tap(tester, 'pattern-create-own');
        await _tap(tester, 'builder-same-day');
        await _tap(tester, 'builder-add-morning');
        await _tap(tester, 'builder-add-night');
        await _expectWholeWords(tester, 'crear el mío, $where');

        // Every shift is there to tap, inside the screen (H-T06-5).
        final pucks = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('builder-add-'),
        );
        expect(pucks, findsAtLeastNWidgets(8));
        for (final element in pucks.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.left, greaterThanOrEqualTo(0), reason: '$rect');
          expect(rect.right, lessThanOrEqualTo(width + 0.01), reason: '$rect');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('H-T06-3: the buttons of the wizard', () {
    testWidgets('x2.0 on 320 dp: «Siguiente» on top, «Atrás» under it, both '
        'full width', (tester) async {
      await _openWizard(tester, size: const Size(320, 640), scale: 2.0);
      await _tap(tester, 'pattern-card-correturnos');
      await _tap(tester, 'pattern-next');
      final back = tester.getRect(_key('pattern-back'));
      final next = tester.getRect(_key('pattern-next'));
      expect(next.bottom, lessThanOrEqualTo(back.top));
      expect(back.width, closeTo(next.width, 0.5));
    });

    testWidgets('x1.0 on 412 dp: side by side, «Siguiente» wider', (
      tester,
    ) async {
      await _openWizard(tester, size: const Size(412, 892), scale: 1.0);
      await _tap(tester, 'pattern-card-correturnos');
      await _tap(tester, 'pattern-next');
      final back = tester.getRect(_key('pattern-back'));
      final next = tester.getRect(_key('pattern-next'));
      expect(back.right, lessThan(next.left));
      expect(back.top, closeTo(next.top, 0.5));
      expect(next.width, greaterThan(back.width));
    });
  });

  group('H-T06-4: «Varios turnos en un día» says what it does', () {
    testWidgets('on, the builder explains that taps join the last day', (
      tester,
    ) async {
      await _openWizard(tester, size: const Size(390, 844), scale: 1.0);
      await _tap(tester, 'pattern-create-own');
      expect(_key('builder-same-day-hint'), findsNothing);
      await _tap(tester, 'builder-add-morning');
      await _tap(tester, 'builder-same-day');
      expect(_key('builder-same-day-hint'), findsOneWidget);
      expect(find.textContaining('último día'), findsOneWidget);
      // And that is what it does: the next tap joins day 1, no new day.
      await _tap(tester, 'builder-add-night');
      expect(_key('builder-step-0'), findsOneWidget);
      expect(_key('builder-step-1'), findsNothing);
      expect(find.text('1 día'), findsOneWidget);
    });
  });
}
