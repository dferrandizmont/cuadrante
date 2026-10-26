import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onboarding_support.dart';

/// The target of the specification: a nurse finishes the first use in under
/// a minute. A real stopwatch cannot say that in a widget test, so the budget
/// is counted in taps: each one is given a generous few seconds of reading
/// and aiming, plus the time the app itself takes to answer (the fake clock
/// of the test, animations included).
const _secondsPerTap = 4;
const _maxTaps = 12;

void main() {
  setUpAll(initializeLocale);

  testWidgets('a nurse finishes in at most 12 taps (simulated < 60 s)', (
    tester,
  ) async {
    final app = await FirstLaunch.open(tester);
    final appTime = Stopwatch()..start();
    final fakeStart = tester.binding.clock.now();

    await app.tap(key('onboarding-profession-nursing')); // 1
    await app.tap(key('onboarding-next')); // 2
    await app.tap(key('onboarding-region')); // 3
    await app.tap(find.text('Comunidad de Madrid')); // 4
    await app.tap(key('onboarding-next')); // 5
    await app.tap(key('onboarding-pattern-12h')); // 6
    await app.tap(key('onboarding-next')); // 7
    await app.tap(key('onboarding-offset-1')); // 8: the night of the cycle
    await app.tap(key('onboarding-next')); // 9
    await app.tap(key('onboarding-next')); // 10: "Continuar" (writes)
    await app.tap(key('onboarding-next')); // 11: "Ver mi calendario"

    expect(find.byType(MonthScreen), findsOneWidget);
    await app.flushWrites();
    expect(idsOn(app.schedule, onboardingToday), 'night12');

    final appSeconds = tester.binding.clock.now().difference(fakeStart);
    final simulated = app.taps * _secondsPerTap + appSeconds.inSeconds;
    // ignore: avoid_print
    print(
      'primer uso: ${app.taps} toques, ${appTime.elapsedMilliseconds} ms '
      'reales, ${appSeconds.inMilliseconds} ms de reloj simulado, '
      '$simulated s en total simulados',
    );
    expect(app.taps, lessThanOrEqualTo(_maxTaps));
    expect(simulated, lessThan(60));
  });

  testWidgets('every step fits a small phone with large text', (tester) async {
    final app = await FirstLaunch.open(
      tester,
      size: const Size(320, 568),
      textScale: 1.8,
    );
    // Any overflow or build error fails the test by itself.
    await app.tap(key('onboarding-profession-hospitality'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-region'));
    await app.tap(find.text('Illes Balears'));
    await app.tap(key('onboarding-municipality'));
    await tester.enterText(key('onboarding-municipality-search'), 'palma');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Palma').first);
    await tester.pumpAndSettle();
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-pattern-5x2'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-next'));
    expect(app.title, 'Listo');
    await app.tap(key('onboarding-next'));
    expect(find.byType(MonthScreen), findsOneWidget);
  });
}
