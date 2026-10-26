import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// H-T18-7: the title of the month is a button (it opens the year): it is
/// 48 dp tall to the touch, also with big text, and says so.
void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('the month title is 48 dp tall and a button (text x$scale)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCalendar(tester, textScale: scale);

      final title = find.byKey(const ValueKey('month-title'));
      expect(tester.getSize(title).height, greaterThanOrEqualTo(48));

      final node = tester.getSemantics(
        find.bySemanticsLabel('Octubre, elegir mes'),
      );
      expect(node.label, 'Octubre, elegir mes');
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  }
}
