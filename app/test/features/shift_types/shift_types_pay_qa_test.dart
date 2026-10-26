import 'package:cuadrante/core/format/text_wrap.dart';
import 'package:cuadrante/core/l10n/l10n.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import '../calendar/harness.dart';
import 'shift_types_screen_test.dart'
    show
        appContainer,
        openNewShift,
        openShiftTypes,
        reveal,
        save,
        stateOf,
        storedSnapshot,
        tapKey,
        typeInto;
import 'shift_types_qa_test.dart' show revealRow;

Finder _key(String key) => find.byKey(ValueKey(key));

ShiftType _morning({int? rate, int? plus}) => ShiftType(
  id: 'morning',
  code: 'M',
  name: 'Mañana',
  colorValue: 0xFFF5A524,
  category: ShiftCategory.work,
  startMinute: 360,
  endMinute: 840,
  hourlyRateCents: rate,
  fixedPlusCents: plus,
);

String _rowText(WidgetTester tester, String rowKey) => tester
    .widgetList<Text>(
      find.descendant(of: _key(rowKey), matching: find.byType(Text)),
    )
    .map((text) => text.data ?? '')
    .join(' ')
    .replaceAll(noBreakSpace, ' ');

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  group('H-T23-2: fixed plus in the shift list', () {
    for (final (rate, plus, expected) in <(int?, int?, String)>[
      (1200, 3000, '12,00 €/h · +30,00 € por turno'),
      (1200, null, '12,00 €/h'),
      (null, 3000, 'Trabajo · +30,00 € por turno'),
      (null, 0, 'Trabajo · +0,00 € por turno'),
    ]) {
      testWidgets('rate $rate, plus $plus: only configured amounts appear', (
        tester,
      ) async {
        await pumpCalendar(
          tester,
          prepare: (repository) =>
              repository.saveShiftType(_morning(rate: rate, plus: plus)),
        );
        await openShiftTypes(tester);
        final text = _rowText(tester, 'shift-row-morning');
        expect(text, contains(expected));
        if (plus == null) expect(text, isNot(contains('por turno')));
        if (rate == null) expect(text, isNot(contains('€/h')));
      });
    }

    testWidgets('an unset plus adds no amount or separator', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      final text = _rowText(tester, 'shift-row-morning');
      expect(
        text,
        'M Mañana ${keepTimeRangesTogether('06:00–14:00 · Trabajo')}',
      );
    });

    testWidgets('an archived shift shows the same price and plus', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        prepare: (repository) =>
            repository.saveShiftType(_morning(rate: 1200, plus: 3000)),
      );
      await openShiftTypes(tester);
      await tapKey(tester, 'shift-archive-morning');
      await tester.tap(_key('confirm-ok'));
      await tester.pumpAndSettle();
      await revealRow(tester, 'shift-archived-toggle');
      await tester.tap(_key('shift-archived-toggle'));
      await tester.pumpAndSettle();
      expect(
        _rowText(tester, 'shift-archived-row-morning'),
        contains('12,00 €/h · +30,00 € por turno'),
      );
    });

    for (final language in AppLanguage.values.where(
      (language) => language != AppLanguage.system,
    )) {
      testWidgets('320 dp, text 2.0: price and plus fit in ${language.name}', (
        tester,
      ) async {
        await pumpCalendar(
          tester,
          size: const Size(320, 900),
          textScale: 2.0,
          overrides: [
            initialPreferencesProvider.overrideWithValue(
              Preferences(language: language),
            ),
          ],
          prepare: (repository) =>
              repository.saveShiftType(_morning(rate: 1200, plus: 3000)),
        );
        appContainer(tester).read(routerProvider).go(AppRoutes.shiftTypes);
        await tester.pumpAndSettle();
        final row = _key('shift-row-morning');
        final l10n = tester.element(row).l10n;
        final amount = switch (language) {
          AppLanguage.en => '€30.00',
          _ => '30,00 €',
        };
        expect(
          _rowText(tester, 'shift-row-morning'),
          contains(l10n.shiftTypesFixedPlusPerShift(amount)),
        );
        for (final element
            in find
                .descendant(of: row, matching: find.byType(RichText))
                .evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(
            wrapsOnlyBetweenWords(paragraph),
            isTrue,
            reason: paragraphLines(paragraph).join(' | '),
          );
        }
        final rect = tester.getRect(row);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('H-T23-3: empty money fields are unambiguous', () {
    for (final (language, rateHint, plusHint) in [
      (AppLanguage.es, 'Sin precio', 'Sin plus'),
      (AppLanguage.ca, 'Sense preu', 'Sense plus'),
      (AppLanguage.gl, 'Sen prezo', 'Sen plus'),
      (AppLanguage.eu, 'Preziorik gabe', 'Osagarririk gabe'),
      (AppLanguage.en, 'No rate', 'No allowance'),
    ]) {
      testWidgets('320 dp, text 2.0, ${language.name}: empty hints save no '
          'implicit amounts', (tester) async {
        await pumpCalendar(
          tester,
          size: const Size(320, 900),
          textScale: 2.0,
          overrides: [
            initialPreferencesProvider.overrideWithValue(
              Preferences(language: language),
            ),
          ],
        );
        appContainer(tester).read(routerProvider).go(AppRoutes.shiftTypes);
        await tester.pumpAndSettle();
        await openNewShift(tester);
        for (final (key, hint) in [
          ('shift-rate', rateHint),
          ('shift-fixed-plus', plusHint),
        ]) {
          await reveal(tester, key);
          final field = tester.widget<TextField>(_key(key));
          expect(field.controller!.text, isEmpty);
          expect(field.decoration!.hintText, hint);
          expect(find.text(hint), findsOneWidget);
          final hintParagraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.text(hint),
              matching: find.byType(RichText),
            ),
          );
          expect(hintParagraph.didExceedMaxLines, isFalse, reason: hint);
        }
        await typeInto(tester, 'shift-name', 'Refuerzo');
        await save(tester);
        final saved = stateOf(tester).palette.last;
        expect(saved.hourlyRateCents, isNull);
        expect(saved.fixedPlusCents, isNull);
        final stored = (await storedSnapshot(tester)).palette.last;
        expect(stored.hourlyRateCents, isNull);
        expect(stored.fixedPlusCents, isNull);
      });
    }
  });
}
