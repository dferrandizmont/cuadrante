import 'package:cuadrante/features/shift_types/presentation/shift_type_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../calendar/harness.dart';
import 'shift_types_screen_test.dart'
    show openNewShift, openShiftTypes, stateOf, tapKey, typeInto;

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await loadRoboto(), isTrue);
  });

  testWidgets('H-T23-4: Back in a time dialog with keyboard only closes it', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await openShiftTypes(tester);
    await tapKey(tester, 'shift-row-morning');
    await typeInto(tester, 'shift-name', 'Mañana editada');
    final editorRoute = ModalRoute.of(
      tester.element(find.byType(ShiftTypeFormScreen)),
    )!;
    await tapKey(tester, 'shift-start');
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, '07');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    // A blocked-pop notification for the covered editor must not open a
    // second dialog. The actual system Back belongs to the time picker.
    editorRoute.onPopInvokedWithResult(false, null);
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsNothing);
    await tester.binding.handlePopRoute();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(find.text('¿Descartar los cambios?'), findsNothing);
    expect(find.byType(ShiftTypeFormScreen), findsOneWidget);
    expect(find.text('Empieza 06:00'), findsOneWidget);
    expect(
      tester.widget<TextField>(_key('shift-name')).controller!.text,
      'Mañana editada',
    );
    expect(stateOf(tester).schedule.shiftTypeById('morning')!.name, 'Mañana');

    // Once the picker is gone, Back still protects the dirty draft.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await tester.tap(_key('confirm-cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(ShiftTypeFormScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final picker in ['shift-color-more', 'shift-icon']) {
    testWidgets('H-T23-4: Back closes $picker without discarding the draft', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Refuerzo');
      final editorRoute = ModalRoute.of(
        tester.element(find.byType(ShiftTypeFormScreen)),
      )!;
      await tapKey(tester, picker);
      expect(editorRoute.isCurrent, isFalse);
      editorRoute.onPopInvokedWithResult(false, null);
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar los cambios?'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(editorRoute.isCurrent, isTrue);
      expect(find.text('¿Descartar los cambios?'), findsNothing);
      expect(
        tester.widget<TextField>(_key('shift-name')).controller!.text,
        'Refuerzo',
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final confirm in [false, true]) {
    testWidgets(
      'H-T23-4: discard ${confirm ? 'confirm' : 'cancel'} stays reachable '
      'at 320 dp, text 2.0 with keyboard inset',
      (tester) async {
        await pumpCalendar(tester, size: const Size(320, 640), textScale: 2.0);
        await openShiftTypes(tester);
        await openNewShift(tester);
        await typeInto(tester, 'shift-name', 'Refuerzo');
        final name = tester.widget<TextField>(_key('shift-name'));
        expect(name.focusNode!.hasFocus, isTrue);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(name.focusNode!.hasFocus, isFalse);
        expect(find.text('¿Descartar los cambios?'), findsOneWidget);
        expect(
          tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
          isTrue,
        );
        final button = _key(
          confirm ? 'shift-discard-confirm' : 'confirm-cancel',
        );
        expect(button.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(button);
        expect(bounds.bottom, lessThanOrEqualTo(640 - 300));
        await tester.tap(button);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(find.text('¿Descartar los cambios?'), findsNothing);
        if (confirm) {
          expect(_key('shift-list'), findsOneWidget);
          expect(
            stateOf(tester).palette.any((s) => s.name == 'Refuerzo'),
            isFalse,
          );
        } else {
          expect(find.byType(ShiftTypeFormScreen), findsOneWidget);
          expect(
            tester.widget<TextField>(_key('shift-name')).controller!.text,
            'Refuerzo',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
