import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/shift_types/presentation/shift_color_picker.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';
import 'shift_types_screen_test.dart' show openShiftTypes, openNewShift;

void main() {
  setUpAll(initializeLocale);

  testWidgets(
    'name and code have one accessible label on the editable control',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      for (final (key, label) in [
        ('shift-name', 'Nombre'),
        ('shift-code', 'Código'),
      ]) {
        final field = find.byKey(ValueKey(key));
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        final node = tester.getSemantics(field);
        expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
        expect(node.label, label);
        expect(
          tester.semantics.simulatedAccessibilityTraversal().where(
            (n) => n.label == label,
          ),
          hasLength(1),
        );
      }
      handle.dispose();
    },
  );

  testWidgets(
    'hex and color sliders expose names, values and adjustment actions once',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ShiftColorPickerSheet(
                shift: ShiftType(
                  id: 'test',
                  code: 'T',
                  name: 'Tarde',
                  colorValue: 0xffdd6633,
                  category: ShiftCategory.work,
                ),
                initial: 0xffdd6633,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShiftColorPickerSheet)),
      );
      for (final (key, label) in [
        ('color-hue', l10n.shiftTypesColorHue),
        ('color-saturation', l10n.shiftTypesColorSaturation),
        ('color-lightness', l10n.shiftTypesColorLightness),
      ]) {
        final slider = find.byKey(ValueKey(key));
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        final node = tester.getSemantics(slider);
        expect(node.label, label);
        expect(node.getSemanticsData().value, isNotEmpty);
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.increase),
          isTrue,
        );
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.decrease),
          isTrue,
        );
        expect(
          tester.semantics.simulatedAccessibilityTraversal().where(
            (n) => n.label == label,
          ),
          hasLength(1),
        );
      }
      final hue = find.byKey(const ValueKey('color-hue'));
      await tester.ensureVisible(hue);
      await tester.pumpAndSettle();
      final oldValue = tester.getSemantics(hue).getSemanticsData().value;
      tester.semantics.performAction(
        find.semantics.byLabel(l10n.shiftTypesColorHue),
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(hue).getSemanticsData().value,
        isNot(oldValue),
      );
      expect(tester.takeException(), isNull);
      final hex = find.byKey(const ValueKey('color-hex'));
      await tester.ensureVisible(hex);
      await tester.pumpAndSettle();
      final node = tester.getSemantics(hex);
      expect(node.label, l10n.shiftTypesColorHexLabel);
      expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
      expect(
        tester.semantics.simulatedAccessibilityTraversal().where(
          (n) => n.label == l10n.shiftTypesColorHexLabel,
        ),
        hasLength(1),
      );
      handle.dispose();
    },
  );
}
