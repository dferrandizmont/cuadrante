import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/onboarding/application/onboarding_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import 'harness.dart';

/// H-T18-6 (design item 3): the tip of the month screen took four lines and
/// the cells of the month were shorter for it, so the time of the shift did
/// not fit. Now the tip of the month screen is one line (it wraps with large
/// text, it is never cut) and the rows of the grid keep the height they need
/// for the code and the time of every day.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  Finder tip() => find.byKey(const ValueKey('onboarding-tip'));
  Finder tipText() => find.descendant(
    of: tip(),
    matching: find.text('Elige un turno y arrastra.'),
  );

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    required double scale,
  }) async {
    await pumpCalendar(tester, size: size, textScale: scale);
    containerOf(tester).read(onboardingTipProvider.notifier).show();
    await tester.pumpAndSettle();
  }

  testWidgets('320 dp, text 1.0: the tip is one line', (tester) async {
    await pump(tester, size: const Size(320, 640), scale: 1.0);

    expect(tip(), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(tipText());
    expect(
      paragraphLines(paragraph).length,
      1,
      reason: 'the tip is one line with the normal text',
    );
    // One line of text and the cross: the tip is barely taller than the
    // touch target of the cross.
    expect(tester.getRect(tip()).height, lessThanOrEqualTo(64));
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp, text 2.0: the tip wraps but it is never cut', (
    tester,
  ) async {
    await pump(tester, size: const Size(320, 640), scale: 2.0);

    expect(tip(), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(tipText());
    final lines = paragraphLines(paragraph);
    expect(lines, isNotEmpty);
    expect(
      lines.join(' ').replaceAll(' ', ''),
      'Eligeunturnoyarrastra.',
      reason: 'the whole text is there, line by line',
    );
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'the tip is never cut',
    );
    // The tip wraps, but it does not eat the space of the schedule: the
    // cells keep their code and their time.
    await revealCell(tester, const CivilDate(2026, 10, 19));
    final cell = find.byKey(const ValueKey('day-2026-10-19'));
    expect(find.descendant(of: cell, matching: find.text('N')), findsOneWidget);
    expect(
      find.descendant(of: cell, matching: find.textContaining('22')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the cross closes the tip', (tester) async {
    await pump(tester, size: const Size(320, 640), scale: 1.0);
    expect(tip(), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-tip-close')));
    await tester.pumpAndSettle();
    expect(tip(), findsNothing);
  });

  testWidgets('the tip of the wide screen keeps the whole advice', (
    tester,
  ) async {
    await pumpCalendar(tester, size: const Size(1280, 800));
    containerOf(tester).read(onboardingTipProvider.notifier).show();
    await tester.pumpAndSettle();

    // The day pane of the wide screen keeps the whole tip (the title, what it
    // explains and the button to close it).
    expect(find.text('Pinta tu mes en un momento'), findsOneWidget);
    expect(find.textContaining('botón Patrón'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-tip-dismiss')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
