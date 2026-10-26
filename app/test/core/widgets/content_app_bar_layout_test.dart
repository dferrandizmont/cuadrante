import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/core/widgets/content_app_bar.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';

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
      for (final faq in [true, false]) {
        testWidgets('$language ${faq ? 'FAQ' : 'compare'} $size text 2', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final l10n = lookupAppLocalizations(Locale(language));
          final title = faq ? l10n.settingsFaqTitle : l10n.compareTitle;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        appBar: ContentAppBar.adaptive(
                          context,
                          title: Text(title, key: const ValueKey('title')),
                          actions: faq
                              ? null
                              : [
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.swap_horiz),
                                  ),
                                ],
                        ),
                        body: const SizedBox(key: ValueKey('body')),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();

          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byKey(const ValueKey('title')),
              matching: find.byType(RichText),
            ),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraphLines(paragraph).length, inInclusiveRange(1, 2));
          expect(wrapsOnlyBetweenWords(paragraph), isTrue);
          expect(paragraph.textScaler.scale(21), 42);
          expect(paragraph.text.style!.fontSize, 21);
          final bar = tester.getRect(find.byType(AppBar));
          final text = tester.getRect(find.byKey(const ValueKey('title')));
          expect(text.top, greaterThanOrEqualTo(bar.top));
          expect(text.bottom, lessThanOrEqualTo(bar.bottom));
          expect(
            tester.getTopLeft(find.byKey(const ValueKey('body'))).dy,
            greaterThanOrEqualTo(bar.bottom),
          );
          if (size.width == 320) {
            expect(bar.height, greaterThan(ContentAppBar.height));
          }
          expect(find.byType(BackButton), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
