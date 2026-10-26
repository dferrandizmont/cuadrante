import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';
import 'parity_color.dart';
import 'parity_compare.dart';
import 'parity_cut.dart';
import 'parity_help.dart';
import 'parity_summary.dart';

// Paridad gratis con la app líder (0.6.0, docs/paridad.md A4, A5, A7, A10,
// A11 y A13), Q85-Q92.
//
// Demo data around Monday 19 Oct 2026 (see `selection.dart`).

/// Scenarios Q85-Q92, registered in `registry.dart`.
final List<QaScenario> parityScenarios = [
  qaManyCalendars, // Q85
  ...compareScenarios, // Q86, Q87
  ...rangeSummaryScenarios, // Q88
  ...freeColorScenarios, // Q89
  qaCutDays, // Q90
  ...faqScenarios, // Q91
  qaCutAndPaste, // Q92
];

Finder _k(String key) => find.byKey(ValueKey(key));

Future<void> _back(WidgetTester t) =>
    t.tapAndSettle(find.byType(BackButton).last, reason: 'flecha atrás');

Future<void> _openCalendars(WidgetTester t) async {
  await t.tapAndSettle(find.byTooltip('Abrir ajustes'), reason: 'Ajustes');
  await t.tapAndSettle(_k('settings-calendars'));
}

// ---- Q85 -------------------------------------------------------------------

/// Q85.
const qaManyCalendars = QaScenario(
  'Q85',
  'Crear más de diez calendarios',
  _manyCalendars,
);

Future<void> _manyCalendars(QaContext qa) async {
  final t = qa.tester;
  // Start with ten calendars to exercise creation beyond the old boundary.
  final app = await QaApp.open(
    qa,
    prepare: (storage) async {
      final calendars = CalendarsRepository(storage.database);
      for (var i = 1; i <= 9; i++) {
        await calendars.create(name: 'Extra $i', colorValue: 0xFF30A46C);
      }
    },
  );

  await _openCalendars(t);
  for (final name in ['Undécimo', 'Duodécimo']) {
    await t.tapAndSettle(_k('calendars-add'));
    await t.enterText(_k('calendar-name-field'), name);
    await t.pump();
    await t.tapAndSettle(_k('calendar-color-1'));
    await t.tapAndSettle(_k('calendar-save'));
    expect(find.text(name), findsOneWidget);
  }
  final stored = await app.query('SELECT id FROM calendars WHERE archived = 0');
  expect(stored, hasLength(12));
  await qa.shot('doce');

  // Recovery also works while more than ten calendars are active.
  final archived = stored.last['id']! as String;
  await t.tapAndSettle(_k('calendar-row-$archived'));
  await t.tapAndSettle(_k('calendar-archive'));
  await t.tapAndSettle(_k('calendar-archive-confirm'));
  await t.tapAndSettle(_k('calendars-archived-toggle'));
  await t.tapAndSettle(_k('calendar-restore-$archived'));
  expect(
    await app.query('SELECT id FROM calendars WHERE archived = 0'),
    hasLength(12),
  );
  expect(_k('calendars-archived'), findsNothing);
  await _back(t);
  await _back(t);
}
