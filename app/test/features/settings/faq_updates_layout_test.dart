import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/settings/presentation/faq_screen.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/real_font.dart';
import '../../support/text_lines.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue);
  });

  for (final language in ['es', 'ca', 'gl', 'eu', 'en']) {
    test('updated help covers the four features in $language', () {
      final l10n = lookupAppLocalizations(Locale(language));
      expect(l10n.faqImportA, contains('.Shifter'));
      expect(l10n.faqImportA, contains('LRHSoft'));
      expect(l10n.faqNotesA, contains(l10n.agendaModeShifts));
      expect(l10n.faqNotesA, contains('15/10'));
      expect(l10n.faqHolidaysA.split('\n\n'), hasLength(2));
      expect(l10n.faqSummaryA.split('\n\n'), hasLength(3));
      expect(faqEntries(l10n), hasLength(12));
    });

    for (final size in [
      const Size(320, 640),
      const Size(1280, 800),
      const Size(915, 412),
    ]) {
      testWidgets('updated answers fit $language $size at text 2', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        final app = await AppUnderTest.pump(tester, size: size);
        tester.platformDispatcher.localesTestValue = [Locale(language)];
        app.container.read(routerProvider).go(AppRoutes.settingsFaq);
        await tester.pumpAndSettle();

        for (final id in ['notes', 'holidays', 'backup', 'import', 'summary']) {
          final tile = find.byKey(ValueKey('faq-$id'));
          final header = find.descendant(
            of: tile,
            matching: find.byType(ListTile),
          );
          await tester.ensureVisible(header);
          await tester.pumpAndSettle();
          await tester.tap(header);
          await tester.pumpAndSettle();
          final texts = find.descendant(
            of: tile,
            matching: find.byType(RichText),
          );
          for (final element in texts.evaluate()) {
            final paragraph = element.renderObject! as RenderParagraph;
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: '$id: ${paragraph.text.toPlainText()}',
            );
            expect(
              wrapsOnlyBetweenWords(paragraph),
              isTrue,
              reason: '$id: ${paragraphLines(paragraph)}',
            );
          }
          expect(tester.takeException(), isNull, reason: id);
          // Keep the next question reachable even on a short landscape screen.
          await tester.ensureVisible(header);
          await tester.pumpAndSettle();
          await tester.tap(header);
          await tester.pumpAndSettle();
        }
      });
    }
  }
}
