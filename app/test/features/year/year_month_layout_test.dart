import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/format/app_date_format.dart';
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/core/widgets/page_body.dart';
import 'package:cuadrante/features/calendar/presentation/shift_format.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/year/presentation/year_image.dart';
import 'package:cuadrante/features/year/presentation/year_month.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../schedule/domain/fixtures.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue);
  });
  for (final language in ['es', 'ca', 'gl', 'eu', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(640, 1000),
      const Size(1280, 800),
      const Size(915, 412),
    ]) {
      testWidgets('annual months $language $size text 2', (tester) async {
        final width = size.width > 640 ? 640.0 : size.width;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
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
            home: Scaffold(
              body: PageBody(
                child: SingleChildScrollView(
                  child: YearImageBody(
                    width: width,
                    year: 2026,
                    schedule: presetSchedule('6x4', jan1),
                    holidays: const {},
                    today: const CivilDate(2026, 10, 25),
                    weekStart: 1,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final format = AppDateFormat(language);
        var abbreviations = 0;
        for (var month = 1; month <= 12; month++) {
          final tile = find.byKey(ValueKey('year-month-$month'));
          final label = find.descendant(
            of: tile,
            matching: find.byKey(const ValueKey('year-month-title')),
          );
          expect(label, findsOneWidget);
          final text = tester.widget<Text>(label);
          final date = DateTime(2026, month);
          final full = capitalize(format.monthName(date));
          expect(text.data, anyOf(full, format.monthShort(date)));
          if (text.data != full) abbreviations++;
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: label, matching: find.byType(RichText)),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraph.textScaler.scale(text.style!.fontSize!), 24);
          expect(
            tester.getSize(label).width,
            lessThanOrEqualTo(tester.widget<YearMonth>(tile).width),
          );
          final semantics = tester.widget<Semantics>(
            find.descendant(of: tile, matching: find.byType(Semantics)).first,
          );
          expect(semantics.properties.label, startsWith('$full 2026:'));
        }
        if (width == 320) expect(abbreviations, greaterThan(0));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
