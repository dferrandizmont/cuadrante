import 'package:cuadrante/core/l10n/l10n.dart';
import 'package:cuadrante/core/theme/theme_context.dart';
import 'package:cuadrante/features/shift_types/presentation/shift_color_grid.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';
import 'shift_types_screen_test.dart' show openNewShift, openShiftTypes;

/// H-T18-4: the colours of the shift editor are read with a name, not as
/// «Color 2 de 24».
void main() {
  testWidgets('every colour of the grid has its own name', (tester) async {
    await pumpCalendar(tester);
    await openShiftTypes(tester);
    await openNewShift(tester);
    final l10n = tester.element(find.byType(ShiftColorGrid)).l10n;

    final names = shiftColorNames(l10n);
    expect(names, hasLength(ShiftPalette.editorChoices.length));
    expect(names.toSet(), hasLength(names.length), reason: 'names repeat');
    for (final name in names) {
      expect(name.trim(), isNotEmpty);
      expect(name, isNot(startsWith('Color ')));
    }
  });

  testWidgets('the swatches are announced «Nombre, N de 24»', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCalendar(tester);
    await openShiftTypes(tester);
    await openNewShift(tester);

    for (final label in [
      'Naranja, 1 de 24',
      'Coral, 2 de 24',
      'Índigo, 3 de 24',
      'Grafito, 24 de 24',
    ]) {
      await tester.ensureVisible(find.bySemanticsLabel(label));
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expect(find.bySemanticsLabel(RegExp(r'^Color \d+ de')), findsNothing);
    handle.dispose();
  });
}
