import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:cuadrante/features/shift_types/presentation/shift_type_form_screen.dart';
import 'package:cuadrante/core/l10n/l10n.dart';
import 'package:cuadrante/core/widgets/labeled_field.dart';
import 'package:flutter/rendering.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import '../calendar/harness.dart';
import 'shift_types_screen_test.dart';

Finder _key(String key) => find.byKey(ValueKey(key));
const _draft = ShiftTypeDraft(code: 'X', name: 'Extra');

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await loadRoboto(), isTrue);
  });

  test('fixed plus accepts cents, zero, upper limit and an empty value', () {
    for (final entry in {
      '30,29': 3029,
      '0': 0,
      '9999.99': 999999,
      '': null,
    }.entries) {
      final draft = _draft.copyWith(fixedPlusText: entry.key);
      expect(draft.validate(), isEmpty);
      expect(draft.toShiftType('x').fixedPlusCents, entry.value);
    }
  });

  test(
    'fixed plus rejects negatives, excess decimals and amounts above limit',
    () {
      for (final text in ['-1', '1,001', '10000', 'abc']) {
        expect(
          _draft.copyWith(fixedPlusText: text).validate(),
          contains(ShiftTypeField.fixedPlus),
        );
      }
    },
  );

  test('a fixed plus applies without hours, but not to rest or absence', () {
    final noTimes = _draft.copyWith(hasTimes: false, fixedPlusText: '30');
    expect(noTimes.validate(), isEmpty);
    expect(noTimes.toShiftType('x').fixedPlusCents, 3000);
    for (final category in [ShiftCategory.rest, ShiftCategory.absence]) {
      final ignored = noTimes.copyWith(
        category: category,
        fixedPlusText: 'bad',
      );
      expect(ignored.validate(), isEmpty);
      expect(ignored.toShiftType('x').fixedPlusCents, isNull);
    }
  });

  test(
    'editing keeps and clears a stored plus and participates in dirty state',
    () {
      final stored = _draft.copyWith(fixedPlusText: '30,29').toShiftType('x');
      final draft = ShiftTypeDraft.fromShiftType(stored);
      expect(draft.fixedPlusText, '30,29');
      expect(draft.toShiftType('x'), stored);
      expect(draft.copyWith(), draft);
      expect(draft.copyWith().hashCode, draft.hashCode);
      expect(draft.copyWith(fixedPlusText: ''), isNot(draft));
      expect(
        draft.copyWith(fixedPlusText: '').toShiftType('x').fixedPlusCents,
        isNull,
      );
    },
  );

  testWidgets('comma money is saved, reopens and can be cleared', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await openShiftTypes(tester);
    await openNewShift(tester);
    await typeInto(tester, 'shift-name', 'Plus nocturno');
    await typeInto(tester, 'shift-rate', '12,50');
    await typeInto(tester, 'shift-fixed-plus', '30,29');
    await save(tester);
    final created = stateOf(tester).palette.last;
    expect(created.fixedPlusCents, 3029);
    expect(created.hourlyRateCents, 1250);
    expect((await storedSnapshot(tester)).palette.last.fixedPlusCents, 3029);
    await tester.scrollUntilVisible(
      _key('shift-row-${created.id}'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapKey(tester, 'shift-row-${created.id}');
    expect(
      tester.widget<TextField>(_key('shift-fixed-plus')).controller!.text,
      '30,29',
    );
    await typeInto(tester, 'shift-fixed-plus', '');
    await save(tester);
    expect(stateOf(tester).palette.last.fixedPlusCents, isNull);
    expect((await storedSnapshot(tester)).palette.last.fixedPlusCents, isNull);
  });

  testWidgets(
    'invalid fixed plus blocks save and remains editable without times',
    (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Plus');
      await typeInto(tester, 'shift-fixed-plus', '10000');
      await save(tester);
      expect(_key('shift-save'), findsOneWidget);
      expect(
        find.text('Escribe un importe válido, por ejemplo 12,50'),
        findsOneWidget,
      );
      await tapKey(tester, 'shift-no-times');
      expect(_key('shift-rate'), findsNothing);
      expect(_key('shift-fixed-plus'), findsOneWidget);
      await typeInto(tester, 'shift-fixed-plus', '30');
      await save(tester);
      expect(stateOf(tester).palette.last.fixedPlusCents, 3000);
      expect(stateOf(tester).palette.last.hasTimes, isFalse);
    },
  );

  for (final language in AppLanguage.values.where(
    (l) => l != AppLanguage.system,
  )) {
    testWidgets(
      '320 dp, text 2.0: money fields and errors fit in ${language.name}',
      (tester) async {
        await pumpCalendar(
          tester,
          size: const Size(320, 800),
          textScale: 2.0,
          overrides: [
            initialPreferencesProvider.overrideWithValue(
              Preferences(language: language),
            ),
          ],
        );
        appContainer(tester).read(routerProvider).go(AppRoutes.shiftTypeNew);
        await tester.pumpAndSettle();
        await typeInto(tester, 'shift-name', 'Plus');
        for (final key in ['shift-rate', 'shift-fixed-plus']) {
          await typeInto(tester, key, '10000');
          expect(tester.takeException(), isNull, reason: key);
        }
        await save(tester);
        final l10n = tester.element(find.byType(ShiftTypeFormScreen)).l10n;
        expect(find.text(l10n.shiftTypesErrorRate), findsNWidgets(2));
        for (final key in ['shift-rate', 'shift-fixed-plus']) {
          final field = find
              .ancestor(of: _key(key), matching: find.byType(LabeledField))
              .first;
          await tester.ensureVisible(field);
          await tester.pumpAndSettle();
          final rect = tester.getRect(field);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
          for (final element
              in find
                  .descendant(of: field, matching: find.byType(RichText))
                  .evaluate()) {
            final paragraph = element.renderObject! as RenderParagraph;
            // Entered values and the optional hint/suffix may intentionally
            // be hidden by the editable; all labels, helpers and errors fit.
            if (paragraph.text.toPlainText() == '10000') continue;
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: paragraph.text.toPlainText(),
            );
            expect(
              wrapsOnlyBetweenWords(paragraph),
              isTrue,
              reason: paragraph.text.toPlainText(),
            );
          }
          expect(tester.takeException(), isNull, reason: key);
        }
        await reveal(tester, 'shift-save');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
