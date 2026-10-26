import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import 'onboarding_support.dart';

/// H-T01-6: with text at 2.0 or in landscape the top bar (back, dots,
/// «Saltar») and the title left a card and a half of the list. There the bar
/// scrolls away with the step, so the list gets the screen. With text at 2.0
/// «Siguiente» goes with them, at the end of the content: fixed, it still
/// left only 1.5 cards between two bars on a 320 dp phone.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  final scroll = find.byType(SingleChildScrollView).first;

  bool barScrolls() => find
      .descendant(of: scroll, matching: key('onboarding-dots'))
      .evaluate()
      .isNotEmpty;

  bool nextScrolls() => find
      .descendant(of: scroll, matching: key('onboarding-next'))
      .evaluate()
      .isNotEmpty;

  testWidgets('a normal phone keeps the bar and «Siguiente» fixed', (
    tester,
  ) async {
    await FirstLaunch.open(tester, size: const Size(390, 844));
    expect(barScrolls(), isFalse);
    expect(nextScrolls(), isFalse);
    expect(
      tester.getRect(key('onboarding-next')).top,
      greaterThanOrEqualTo(tester.getRect(scroll).bottom),
    );
  });

  for (final (name, size, scale) in [
    ('text 2.0 at 320 dp', const Size(320, 640), 2.0),
    ('text 2.0 at 412 dp', const Size(412, 892), 2.0),
    ('landscape', const Size(800, 360), 1.0),
  ]) {
    testWidgets('$name: the bar scrolls away and the list gets the room', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester, size: size, textScale: scale);
      expect(barScrolls(), isTrue);

      // The scroll view starts at the top of the screen (the bar is inside
      // it). Landscape keeps «Siguiente» fixed under it; with big text it is
      // inside, at the end of the content, and the list gets the whole
      // screen.
      final viewport = tester.getRect(scroll);
      expect(viewport.top, lessThan(8));
      if (scale >= 1.5) {
        expect(nextScrolls(), isTrue);
        expect(viewport.bottom, greaterThan(size.height - 8));
        expect(
          tester.getRect(key('onboarding-next')).top,
          greaterThan(size.height / 2),
          reason: 'under the cards, not fixed over them',
        );
      } else {
        expect(nextScrolls(), isFalse);
        expect(
          tester.getRect(key('onboarding-next')).top,
          greaterThanOrEqualTo(viewport.bottom),
        );
      }
      expect(tester.takeException(), isNull);

      // The bar is reachable at the top, and gone after scrolling the list.
      expect(tester.getRect(key('onboarding-skip')).top, greaterThan(0));
      await tester.drag(scroll, Offset(0, -size.height));
      await tester.pumpAndSettle();
      expect(tester.getRect(key('onboarding-skip')).bottom, lessThan(0));

      // And it still works: pick a job and go on from where the list is
      // («Siguiente» is reached by scrolling when it is inside).
      await app.tap(key('onboarding-profession-nursing'));
      await app.tap(key('onboarding-next'));
      expect(app.title, '¿Dónde trabajas?');
      expect(barScrolls(), isTrue);
    });
  }

  group('H-T01-6 on every width and text size', () {
    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('$width dp, text $scale: «Siguiente» is fixed below '
            '2.0 and reachable at the end of the content at 2.0', (
          tester,
        ) async {
          final app = await FirstLaunch.open(
            tester,
            size: Size(width, 760),
            textScale: scale,
          );
          for (var step = 0; step < 2; step++) {
            expect(nextScrolls(), scale >= 1.5, reason: 'step $step');
            final next = key('onboarding-next');
            if (scale < 1.5) {
              // Fixed: always on screen, under the list.
              expect(tester.getRect(next).bottom, lessThanOrEqualTo(760));
              expect(
                tester.getRect(next).top,
                greaterThanOrEqualTo(tester.getRect(scroll).bottom),
              );
            } else {
              // Inside: scroll to the end and it is on screen, under the
              // last card.
              await tester.drag(scroll, const Offset(0, -3000));
              await tester.pumpAndSettle();
              final rect = tester.getRect(next);
              expect(rect.bottom, lessThanOrEqualTo(760 + 0.5));
              expect(rect.top, greaterThan(0));
            }
            if (step == 0) {
              await app.tap(key('onboarding-profession-nursing'));
            }
            await app.tap(key('onboarding-next'));
          }
          expect(app.title, isNotEmpty);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
