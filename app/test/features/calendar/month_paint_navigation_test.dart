import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/support/month_navigation.dart';
import '../../support/real_font.dart';
import '../../support/test_storage.dart';
import 'harness.dart';

void main() {
  setUpAll(initializeLocale);

  testWidgets('Q07: the shared arrows still reveal normal month navigation', (
    tester,
  ) async {
    expect(await tester.runAsync(loadRoboto), isTrue);
    addTearDown(() => AppTypography.debugFamily = null);
    await pumpCalendar(tester, size: const Size(320, 915));
    await tapMonthArrow(tester, next: true);
    final container = containerOf(tester);
    expect(container.read(visibleMonthProvider), const CivilDate(2026, 11, 1));
    expect(find.text('Noviembre'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    await tapMonthArrow(tester, next: false);
    expect(container.read(visibleMonthProvider), const CivilDate(2026, 10, 1));
    expect(find.text('Octubre'), findsOneWidget);
    expect(find.text('Hoy'), findsNothing);
    expect(container.read(paintControllerProvider).active, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final width in [412.0, 320.0]) {
    testWidgets('Q05 at ${width}x915: recover month arrows after erase/undo '
        'through the paint scroll controls', (tester) async {
      expect(await tester.runAsync(loadRoboto), isTrue);
      addTearDown(() => AppTypography.debugFamily = null);
      await pumpCalendar(tester, size: Size(width, 915));
      // Match the edge-to-edge phone's status and navigation safe areas.
      tester.view.padding = const FakeViewPadding(top: 72, bottom: 72);
      tester.view.viewPadding = const FakeViewPadding(top: 72, bottom: 72);
      addTearDown(() {
        tester.view.resetPadding();
        tester.view.resetViewPadding();
      });
      await tester.pumpAndSettle();
      await enterPaintMode(tester);
      final container = containerOf(tester);
      final controller = container.read(scheduleControllerProvider.notifier);
      final repository = container.read(scheduleRepositoryProvider);
      final original = scheduleOf(tester);
      const october29 = CivilDate(2026, 10, 29);

      Future<void> tapRevealed(Finder target) async {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<Schedule> stored() async {
        await tester.runAsync(() => controller.pendingWrites);
        return (await tester.runAsync(() => repository.load('main')))!.schedule;
      }

      await tapRevealed(find.byKey(const ValueKey('tool-eraser')));
      await tapRevealed(cell(october29));
      expect(idsOn(scheduleOf(tester), october29), '');
      expect((await stored()).entries[october29]!.shiftTypeIds, isEmpty);
      await tapRevealed(find.byKey(const ValueKey('undo')));
      expect(idsOn(scheduleOf(tester), october29), 'morning');
      expectSameSchedule(await stored(), original);

      // This is Q05's former failure: revealing a low cell scrolls the
      // navigation sliver out of the onstage tree. A finder cannot reveal it.
      expect(find.byTooltip('Mes anterior'), findsNothing);
      final up = find.byKey(const ValueKey('paint-scroll-up'));
      expect(up.hitTestable(), findsOneWidget);
      expect(tester.getSize(up).width, greaterThanOrEqualTo(Sp.touch));
      expect(tester.getSize(up).height, greaterThanOrEqualTo(Sp.touch));

      for (var month = 9; month >= 6; month--) {
        await tapMonthArrow(tester, next: false);
        expect(container.read(visibleMonthProvider), CivilDate(2026, month, 1));
        expect(container.read(paintControllerProvider).active, isTrue);
        expect(container.read(paintControllerProvider).erasing, isTrue);
        final previous = find.byTooltip('Mes anterior');
        expect(previous.hitTestable(), findsOneWidget);
        expect(tester.getSize(previous).width, greaterThanOrEqualTo(Sp.touch));
        expect(tester.getSize(previous).height, greaterThanOrEqualTo(Sp.touch));
        expectSameSchedule(scheduleOf(tester), original);
      }
      const june10 = CivilDate(2026, 6, 10);
      await tapRevealed(cell(june10));
      expect(idsOn(scheduleOf(tester), june10), '');
      expectSameSchedule(await stored(), original);
      expect(container.read(scheduleControllerProvider).canUndo, isFalse);

      // The same recovery works towards the next month, without another edit.
      await tapMonthArrow(tester, next: true);
      expect(container.read(visibleMonthProvider), const CivilDate(2026, 7, 1));
      expectSameSchedule(await stored(), original);
      expect(tester.takeException(), isNull);
    });
  }
}
