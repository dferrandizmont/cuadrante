import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import 'backup_ui_support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue);
  });

  for (final language in ['es', 'ca', 'gl', 'eu', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(1280, 800),
      const Size(915, 412),
    ]) {
      testWidgets('device backup texts fit $language $size at text 2', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        final h = BackupUiHarness(tester);
        await h.open(size: size);
        tester.platformDispatcher.localesTestValue = [Locale(language)];
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(Locale(language));

        for (final value in [
          l10n.backupUiStatusNoneBody,
          l10n.backupUiWarning,
          l10n.backupUiSectionCopies.toUpperCase(),
          l10n.backupUiSave,
        ]) {
          final text = find.text(value);
          expect(text, findsOneWidget);
          await tester.ensureVisible(text);
          await tester.pump();
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: text, matching: find.byType(RichText)),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: value);
          expect(
            wrapsOnlyBetweenWords(paragraph),
            isTrue,
            reason: paragraphLines(paragraph).join(' | '),
          );
          expect(tester.takeException(), isNull);
        }

        // Persist a real local backup, then inspect the longer device label.
        await tapIo(
          tester,
          find.byKey(const ValueKey('backup-now')),
          until: find.textContaining(l10n.backupUiCopyLocal),
        );
        final label = find.textContaining(l10n.backupUiCopyLocal).first;
        await tester.ensureVisible(label);
        await tester.pump();
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: label, matching: find.byType(RichText)),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
