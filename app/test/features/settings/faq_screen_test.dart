import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/features/settings/presentation/faq_screen.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// The header row of a question (the tile itself also covers its answer).
Finder _header(String id) =>
    find.descendant(of: _key('faq-$id'), matching: find.byType(ListTile));

void main() {
  setUpAll(initializeLocale);

  for (final language in ['es', 'ca', 'gl', 'eu', 'en']) {
    test('$language: iOS FAQ contain no Android instructions', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      final apple = faqEntries(l10n, platform: TargetPlatform.iOS);
      final android = faqEntries(l10n, platform: TargetPlatform.android);
      for (final entry in apple) {
        expect(entry.question.toLowerCase(), isNot(contains('android')));
        expect(entry.answer.toLowerCase(), isNot(contains('android')));
        expect(entry.answer.trim(), isNotEmpty);
      }
      final alarms = apple.singleWhere((e) => e.id == 'alarms');
      expect(alarms.question, l10n.faqAlarmsQIos);
      expect(alarms.question, isNot(l10n.faqAlarmsQ));
      expect(
        android.singleWhere((e) => e.id == 'alarms').question,
        l10n.faqAlarmsQ,
      );
      expect(
        apple.singleWhere((e) => e.id == 'widget').answer,
        contains(l10n.widgetAddManualIos),
      );
      for (final id in ['alarms', 'widget']) {
        expect(
          android.singleWhere((e) => e.id == id).answer.toLowerCase(),
          contains('android'),
        );
      }
    });
  }

  testWidgets('the iOS screen selects its platform FAQ', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light().copyWith(platform: TargetPlatform.iOS),
          home: const FaqScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('es'));
    expect(find.text(l10n.faqAlarmsQIos), findsOneWidget);
    expect(find.text(l10n.faqAlarmsQ), findsNothing);
    await tester.ensureVisible(_header('alarms'));
    await tester.tap(_header('alarms'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.faqAlarmsAIos.split('\n\n').last), findsOneWidget);
    expect(find.textContaining('En Android'), findsNothing);
  });

  group('the questions', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('es'));
    });

    test('are the twelve topics of the help, in order', () {
      final entries = faqEntries(l10n, platform: TargetPlatform.android);
      expect(entries.map((e) => e.id), [
        'paint',
        'pattern',
        'double',
        'post-night',
        'notes',
        'alarms',
        'holidays',
        'widget',
        'backup',
        'import',
        'calendars',
        'summary',
      ]);
    });

    test('the widget answer names all three sizes', () {
      final answer = faqEntries(
        l10n,
        platform: TargetPlatform.android,
      ).singleWhere((e) => e.id == 'widget').answer;
      expect(answer, contains('pequeño'));
      expect(answer, contains('mediano'));
      expect(answer, contains('grande: el mes entero'));
    });

    test('every one has a question and an answer, no emojis, no placeholders '
        'left', () {
      final emoji = RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
        unicode: true,
      );
      for (final e in faqEntries(l10n, platform: TargetPlatform.android)) {
        expect(e.question.trim(), endsWith('?'), reason: e.id);
        expect(e.answer.trim().length, greaterThan(80), reason: e.id);
        for (final text in [e.question, e.answer]) {
          expect(emoji.hasMatch(text), isFalse, reason: e.id);
          expect(text, isNot(contains('{')), reason: e.id);
          expect(text, isNot(contains('}')), reason: e.id);
        }
      }
    });

    test('cover what was asked for', () {
      String answer(String id) => faqEntries(
        l10n,
        platform: TargetPlatform.android,
      ).firstWhere((e) => e.id == id).answer;
      expect(answer('pattern'), contains('desfase'));
      expect(answer('double'), contains('Doblar'));
      expect(answer('post-night'), contains('Saliente'));
      expect(answer('alarms'), contains('Alarmas y recordatorios'));
      expect(answer('holidays'), contains('Festivo propio'));
      expect(answer('widget'), contains('medianoche'));
      expect(answer('backup'), contains('cambiar de dispositivo'));
      expect(answer('import'), contains('.ics'));
      expect(answer('calendars'), contains('Comparar calendarios'));
      expect(answer('summary'), contains('estimación'));
    });

    test('the paragraphs of an answer split on a blank line', () {
      final paint = faqEntries(l10n, platform: TargetPlatform.android).first;
      expect(paint.paragraphs, hasLength(2));
      expect(paint.paragraphs.first, startsWith('Pulsa «Pintar»'));
    });
  });

  group('the screen', () {
    // A variant restores the platform before Flutter checks its invariants;
    // a group tearDown runs too late for that check.
    final android = TargetPlatformVariant.only(TargetPlatform.android);

    testWidgets('Ajustes › Ayuda has the row, which opens the questions', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: const Size(390, 2000));
      await app.openSettings();
      expect(_key('settings-faq'), findsOneWidget);
      expect(find.text('Preguntas frecuentes'), findsOneWidget);
      // The contact and version rows are still there.
      expect(_key('settings-help'), findsOneWidget);
      expect(find.text('Ayuda y contacto'), findsOneWidget);
      expect(_key('settings-about'), findsOneWidget);

      await tester.tap(_key('settings-faq'));
      await tester.pumpAndSettle();
      expect(find.byType(FaqScreen), findsOneWidget);
      expect(find.text('Preguntas frecuentes'), findsOneWidget);
      expect(find.text('¿Cómo pinto el mes?'), findsOneWidget);
    }, variant: android);

    testWidgets('the route /ajustes/ayuda opens it', (tester) async {
      final app = await AppUnderTest.pump(tester);
      app.container.read(routerProvider).go(AppRoutes.settingsFaq);
      await tester.pumpAndSettle();
      expect(find.byType(FaqScreen), findsOneWidget);
      expect(AppRoutes.settingsFaq, '/ajustes/ayuda');
    }, variant: android);

    testWidgets('an item opens to its answer and closes again', (tester) async {
      final app = await AppUnderTest.pump(tester, size: const Size(390, 2000));
      app.container.read(routerProvider).go(AppRoutes.settingsFaq);
      await tester.pumpAndSettle();

      // Closed: the answer is not built.
      expect(_key('faq-pattern-answer-0'), findsNothing);
      await tester.tap(_header('pattern'));
      await tester.pumpAndSettle();
      expect(_key('faq-pattern-answer-0'), findsOneWidget);
      expect(_key('faq-pattern-answer-1'), findsOneWidget);
      expect(
        find.textContaining('El desfase es el punto del ciclo'),
        findsOneWidget,
      );

      // Several can be open at the same time.
      await tester.tap(_header('widget'));
      await tester.pumpAndSettle();
      expect(_key('faq-pattern-answer-0'), findsOneWidget);
      expect(find.textContaining('cambia de día a medianoche'), findsOneWidget);

      await tester.tap(_header('pattern'));
      await tester.pumpAndSettle();
      expect(_key('faq-pattern-answer-0'), findsNothing);
      expect(find.textContaining('cambia de día a medianoche'), findsOneWidget);
    }, variant: android);

    testWidgets('every question can be opened and shows its text', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: const Size(390, 2000));
      app.container.read(routerProvider).go(AppRoutes.settingsFaq);
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      for (final entry in faqEntries(l10n, platform: TargetPlatform.android)) {
        final tile = _key('faq-${entry.id}');
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        for (var i = 0; i < entry.paragraphs.length; i++) {
          expect(
            _key('faq-${entry.id}-answer-$i'),
            findsOneWidget,
            reason: entry.id,
          );
        }
        expect(tester.takeException(), isNull, reason: entry.id);
      }
    }, variant: android);

    testWidgets('the contact info stays reachable from the questions', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: const Size(390, 2000));
      app.container.read(routerProvider).go(AppRoutes.settingsFaq);
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('faq-contact'));
      await tester.tap(_key('faq-contact'));
      await tester.pumpAndSettle();
      expect(find.text('turnly@mainshai.com'), findsOneWidget);
      expect(_key('help-copy-email'), findsOneWidget);
      expect(_key('help-copy-version'), findsOneWidget);
    }, variant: android);

    for (final (size, scale) in [
      (const Size(320, 568), 1.6),
      (const Size(390, 844), 1.0),
      (const Size(844, 390), 1.0),
    ]) {
      testWidgets('fits ${size.width.toInt()}x${size.height.toInt()} '
          'x$scale with every item open', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final app = await AppUnderTest.pump(tester, size: size);
        app.container.read(routerProvider).go(AppRoutes.settingsFaq);
        await tester.pumpAndSettle();
        final l10n = await AppLocalizations.delegate.load(const Locale('es'));
        for (final entry in faqEntries(
          l10n,
          platform: TargetPlatform.android,
        )) {
          final tile = _key('faq-${entry.id}');
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          await tester.tap(tile);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: entry.id);
        }
      }, variant: android);
    }
  });
}
