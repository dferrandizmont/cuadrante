import 'package:cuadrante/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

// Preguntas frecuentes (docs/paridad.md A13), Q91.

/// Scenarios of this file, listed by `parity.dart`.
final List<QaScenario> faqScenarios = [
  qaFaq, // Q91
];

Finder _k(String key) => find.byKey(ValueKey(key));

/// The header row of a question (the tile also covers its open answer).
Finder _header(String id) =>
    find.descendant(of: _k('faq-$id'), matching: find.byType(ListTile));

/// Q91.
const qaFaq = QaScenario(
  'Q91',
  'Preguntas frecuentes en Ajustes › Ayuda',
  _faq,
);

Future<void> _faq(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final config = app.container.read(appConfigProvider);

  await t.tapAndSettle(find.byTooltip('Abrir ajustes'));
  // The Ayuda section is at the bottom: the contact and version rows are
  // still there next to the questions.
  await t.ensureVisible(_k('settings-about'));
  await t.settle();
  expect(find.text('Preguntas frecuentes'), findsOneWidget);
  expect(find.text('Ayuda y contacto'), findsOneWidget);
  expect(_k('settings-about'), findsOneWidget);
  await qa.shot('ajustes');

  await t.tapAndSettle(_k('settings-faq'));
  expect(find.text('¿Cómo pinto el mes?'), findsOneWidget);
  expect(_k('faq-paint-answer-0'), findsNothing, reason: 'cerradas');
  await qa.shot('lista');

  // Open two: they stay open together.
  await t.tapAndSettle(_header('paint'));
  expect(
    find.textContaining('Pulsa «Pintar» en el calendario'),
    findsOneWidget,
  );
  await t.tapAndSettle(_header('alarms'));
  expect(find.textContaining('Alarmas y recordatorios'), findsWidgets);
  expect(_k('faq-paint-answer-0'), findsOneWidget);
  await qa.shot('abiertas');

  // The twelve topics are all there and open without errors.
  for (final id in [
    'pattern',
    'double',
    'post-night',
    'notes',
    'holidays',
    'widget',
    'backup',
    'import',
    'calendars',
    'summary',
  ]) {
    await t.tapAndSettle(_header(id), reason: 'pregunta $id');
    expect(_k('faq-$id-answer-0'), findsOneWidget, reason: id);
  }
  qa.expectNoFlutterErrors('preguntas');

  // The contact sheet is one tap away (at the end of the lazy list).
  await t.scrollUntilVisible(
    _k('faq-contact'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await t.tapAndSettle(_k('faq-contact'));
  expect(
    find.text(
      config.supportEmail.isEmpty
          ? 'Todavía no tenemos correo de soporte. Mientras tanto, mira las '
                'preguntas frecuentes y, si algo no va bien, ten a mano la '
                'versión que usas.'
          : '¿Dudas o algo no va bien? Cuéntanos qué te pasa y qué versión usas.',
    ),
    findsOneWidget,
  );
  final version = config.appVersion.isEmpty
      ? 'Versión de desarrollo'
      : 'Versión ${config.appVersion}';
  expect(find.text('Cuadrante · $version'), findsOneWidget);
  expect(_k('help-copy-version'), findsOneWidget);
  expect(
    _k('help-no-email'),
    config.supportEmail.isEmpty ? findsOneWidget : findsNothing,
  );
  expect(
    _k('help-copy-email'),
    config.supportEmail.isEmpty ? findsNothing : findsOneWidget,
  );
}
