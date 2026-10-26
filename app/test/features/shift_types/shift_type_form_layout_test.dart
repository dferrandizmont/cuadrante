import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_sounds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';
import 'shift_types_screen_test.dart'
    show openNewShift, openShiftTypes, tapKey, typeInto;

// The shift type editor holds, one below the other, the free colour picker
// («Más colores…»), the icon field and the «Alarma» section with the sound
// (0.6.0 integration). At 320 dp wide and text x1.3 they must not overflow, in
// the order colour -> category -> icon -> times -> alarm.

Finder _key(String key) => find.byKey(ValueKey(key));

double _top(WidgetTester tester, String key) => tester.getTopLeft(_key(key)).dy;

void main() {
  testWidgets('320 dp, text x1.3: colour, icon and sound fit, in order, and '
      'their sheets open without overflow', (tester) async {
    await pumpCalendar(
      tester,
      size: const Size(320, 640),
      textScale: 1.3,
      overrides: [
        alarmSoundsProvider.overrideWithValue(
          FakeAlarmSounds(titles: {'content://media/1': 'Un sonido muy largo'}),
        ),
      ],
    );
    await openShiftTypes(tester);
    await openNewShift(tester);
    expect(tester.takeException(), isNull);
    await typeInto(tester, 'shift-name', 'Turno con nombre largo');
    await typeInto(tester, 'shift-code', 'T');

    // Every control is reachable and none overflows on the way.
    final tops = <String, double>{};
    for (final key in [
      'shift-color-more',
      'category-work',
      'shift-icon',
      'shift-sound',
      'shift-save',
    ]) {
      await tester.ensureVisible(_key(key));
      await tester.pumpAndSettle();
      expect(_key(key), findsOneWidget, reason: key);
      expect(tester.takeException(), isNull, reason: key);
      // Position in the scrollable, independent of the scroll offset.
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      tops[key] = _top(tester, key) + scroll.position.pixels;
    }
    expect(tops['shift-color-more']!, lessThan(tops['category-work']!));
    expect(tops['category-work']!, lessThan(tops['shift-icon']!));
    expect(tops['shift-icon']!, lessThan(tops['shift-sound']!));
    expect(tops['shift-sound']!, lessThan(tops['shift-save']!));

    // Targets of 48 dp or more, and inside the 320 dp of the screen.
    for (final key in ['shift-color-more', 'shift-icon', 'shift-sound']) {
      await tester.ensureVisible(_key(key));
      await tester.pumpAndSettle();
      final rect = tester.getRect(_key(key));
      expect(rect.height, greaterThanOrEqualTo(48), reason: key);
      expect(rect.left, greaterThanOrEqualTo(0), reason: key);
      expect(rect.right, lessThanOrEqualTo(320), reason: key);
    }

    // The free colour sheet.
    await tapKey(tester, 'shift-color-more');
    expect(find.text('Elige tu color'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(_key('color-hex'), '#1C9AB5');
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(_key('color-use'));
    await tester.pumpAndSettle();
    await tester.tap(_key('color-use'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tu color'), findsNothing);

    // The icon grid.
    await tapKey(tester, 'shift-icon');
    expect(_key('shift-icon-grid'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tapKey(tester, 'shift-icon-bus');
    expect(tester.takeException(), isNull);
  });
}
