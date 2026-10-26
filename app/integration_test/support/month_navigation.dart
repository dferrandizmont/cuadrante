import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Changes month through reachable controls, including after painting a low row.
/// The paint viewport cannot be dragged: use its up button to recover the
/// navigation, which a sliver can have removed from the onstage widget tree.
Future<void> tapMonthArrow(WidgetTester tester, {required bool next}) async {
  Future<void> settle() => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 8),
  );
  final arrow = find.byTooltip(next ? 'Mes siguiente' : 'Mes anterior');
  final up = find.byKey(const ValueKey('paint-scroll-up'));
  for (
    var attempt = 0;
    attempt < 30 && arrow.hitTestable().evaluate().isEmpty;
    attempt++
  ) {
    if (up.hitTestable().evaluate().isEmpty) break;
    await tester.tap(up);
    await settle();
  }
  // Outside paint mode the viewport scrolls normally. Keep the same explicit
  // reveal as tapAndSettle, but never use it to bypass the paint controls.
  if (up.evaluate().isEmpty && arrow.evaluate().isNotEmpty) {
    await tester.ensureVisible(arrow);
    await settle();
  }
  if (arrow.hitTestable().evaluate().isEmpty) {
    throw TestFailure(
      'No se puede alcanzar ${next ? "Mes siguiente" : "Mes anterior"} '
      'con los controles del mes.',
    );
  }
  await tester.tap(arrow);
  await settle();
}
