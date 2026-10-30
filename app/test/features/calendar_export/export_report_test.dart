import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/calendar_export/data/calendar_exporter.dart';
import 'package:cuadrante/features/calendar_export/domain/device_calendar_api.dart';
import 'package:cuadrante/features/calendar_export/domain/export_events.dart';
import 'package:cuadrante/features/calendar_export/presentation/export_texts.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/l10n/app_localizations_es.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_device_calendar.dart';
import '../../support/real_font.dart';
import '../import/import_ui_support.dart';
import 'export_screen_test.dart' show openExport, stateOf;

ExportEvent _event(
  int d, {
  String title = 'Noche · N',
  String type = 'night',
}) => ExportEvent(
  calendarId: 'main',
  date: CivilDate(2026, 11, d),
  shiftTypeId: type,
  index: 0,
  title: title,
  start: DateTime(2026, 11, d, 22),
  end: DateTime(2026, 11, d + 1, 6),
  allDay: false,
);

DeviceEvent _onPhone(ExportEvent e, {String? title}) => DeviceEvent(
  instanceId: 'i-${e.tag}',
  calendarId: 'cal',
  title: title ?? e.title,
  start: e.start,
  end: e.end,
  description: e.description,
);

ExportPlan _plan(List<ExportEvent> desired, List<DeviceEvent> existing) =>
    planExport(
      desired: desired,
      existing: existing,
      deviceCalendarId: 'cal',
      calendarId: 'main',
      from: const CivilDate(2026, 11, 1),
      to: const CivilDate(2026, 11, 30),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
  });

  final l10n = AppLocalizationsEs();

  group('H-T14-3: what the plan says (sustituirán / quitarán)', () {
    test('only new events: «Se añadirán»', () {
      final lines = exportPlanLines(l10n, _plan([_event(3), _event(4)], []));
      expect(lines.map((l) => l.key), ['add']);
      expect(lines.single.text, 'Se añadirán 2 eventos.');
    });

    test(
      'events that are only deleted say «quitarán», never «sustituirán»',
      () {
        // The days off were switched off: 3 events of the last export are
        // still on the phone and nothing is written in their place.
        final old = [_event(3), _event(4), _event(5)];
        final lines = exportPlanLines(
          l10n,
          _plan([], [for (final e in old) _onPhone(e)]),
        );
        expect(lines.map((l) => l.key), ['remove']);
        expect(
          lines.single.text,
          'Se quitarán 3 eventos de una exportación anterior.',
        );
        expect(lines.map((l) => l.text).join(' '), isNot(contains('sustitu')));
      },
    );

    test('one event is «quitará» in the singular', () {
      final lines = exportPlanLines(l10n, _plan([], [_onPhone(_event(3))]));
      expect(
        lines.single.text,
        'Se quitará 1 evento de una exportación anterior.',
      );
    });

    test('a changed shift is replaced: «sustituirán»', () {
      final lines = exportPlanLines(
        l10n,
        _plan([_event(3)], [_onPhone(_event(3), title: 'Otro título')]),
      );
      expect(lines.map((l) => l.key), ['add', 'replace']);
      expect(lines.last.text, contains('Se sustituirá 1 evento'));
      expect(lines.map((l) => l.key), isNot(contains('remove')));
    });

    test('another shift on the same day replaces the old one', () {
      // Noche on the 3rd became Mañana: different tag, same day.
      final lines = exportPlanLines(
        l10n,
        _plan(
          [_event(3, title: 'Mañana · M', type: 'morning')],
          [_onPhone(_event(3))],
        ),
      );
      expect(lines.map((l) => l.key), ['add', 'replace']);
    });

    test('both at once when the plan replaces some and removes others', () {
      final lines = exportPlanLines(
        l10n,
        _plan(
          [_event(3)],
          [
            _onPhone(_event(3), title: 'Otro título'), // written again
            _onPhone(_event(4)), // no longer wanted
            _onPhone(_event(5)), // no longer wanted
          ],
        ),
      );
      final byKey = {for (final l in lines) l.key: l.text};
      expect(byKey['replace'], startsWith('Se sustituirá 1 evento'));
      expect(byKey['remove'], startsWith('Se quitarán 2 eventos'));
      expect(byKey['add'], 'Se añadirá 1 evento.');
    });

    test('nothing to do, and no shifts', () {
      final same = _plan([_event(3)], [_onPhone(_event(3))]);
      expect(exportPlanLines(l10n, same).map((l) => l.key), ['nothing']);
      expect(exportPlanLines(l10n, _plan([], [])).map((l) => l.key), ['none']);
    });

    test('the counts of the plan', () {
      final plan = _plan(
        [_event(3)],
        [_onPhone(_event(3), title: 'x'), _onPhone(_event(4))],
      );
      expect(plan.replaced, 1);
      expect(plan.removed, 1);
    });

    test('the result says «sustituidos» and «quitados» apart', () {
      const removedOnly = ExportResult(
        deviceCalendarId: 'cal',
        created: 0,
        removed: 20,
        unchanged: 72,
        failed: 0,
        calendarCreated: false,
      );
      final only = exportResultLines(l10n, removedOnly);
      expect(only.map((l) => l.text), [
        '20 eventos quitados',
        '72 eventos ya estaban al día',
      ]);

      const mixed = ExportResult(
        deviceCalendarId: 'cal',
        created: 5,
        removed: 7,
        replaced: 5,
        unchanged: 0,
        failed: 0,
        calendarCreated: false,
      );
      expect(exportResultLines(l10n, mixed).map((l) => l.text), [
        '5 eventos añadidos',
        '5 eventos anteriores sustituidos',
        '2 eventos quitados',
      ]);

      const fresh = ExportResult(
        deviceCalendarId: 'cal',
        created: 30,
        removed: 0,
        unchanged: 0,
        failed: 0,
        calendarCreated: true,
      );
      expect(exportResultLines(l10n, fresh).map((l) => l.text), [
        'Se ha creado el calendario «Turnly».',
        '30 eventos añadidos',
      ]);
    });
  });

  group('H-T14-3 on the screen: switching the days off', () {
    testWidgets('exporting with days off, then without, says «quitarán» and '
        '«quitados»', (tester) async {
      final phone = FakeDeviceCalendar();
      final app = await openExport(tester, phone);
      await tapKey(tester, 'export-include-rest-switch');
      await tapKey(tester, 'export-start');
      final written = phone.allEvents.length;
      expect(written, greaterThan(0));

      // Without the days off, the rest events must go and nothing replaces
      // them.
      await tapKey(tester, 'export-include-rest-switch');
      final plan = stateOf(app).plan!;
      expect(plan.toCreate, isEmpty);
      expect(plan.toDelete, isNotEmpty);
      expect(byKey('export-plan-remove'), findsOneWidget);
      expect(
        find.textContaining('Se quitarán ${plan.toDelete.length} eventos'),
        findsOneWidget,
      );
      expect(find.textContaining('sustituir'), findsNothing);
      expect(byKey('export-plan-replace'), findsNothing);

      await tapKey(tester, 'export-start');
      expect(
        find.text('${plan.toDelete.length} eventos quitados'),
        findsOneWidget,
      );
      expect(find.textContaining('sustituido'), findsNothing);
      expect(find.textContaining('0 eventos añadidos'), findsNothing);
      expect(phone.allEvents.length, written - plan.toDelete.length);
    });
  });

  group('H-T14-4: the result is brought into view', () {
    testWidgets('after «Exportar» the card is on screen, not below the fold', (
      tester,
    ) async {
      const height = 640.0;
      final phone = FakeDeviceCalendar();
      phone.addCalendar('Personal', account: 'yo@example.com');
      final app = await AppUnderTest.pump(
        tester,
        size: const Size(390, height),
        overrides: importOverrides(phone: phone, picker: FakePicker()),
      );
      await app.openSettings();
      await tester.ensureVisible(byKey('settings-export-calendar'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('settings-export-calendar'));
      await tester.pumpAndSettle();

      await tapKey(tester, 'export-start');
      await tester.pumpAndSettle();

      final result = tester.getRect(byKey('export-result'));
      expect(result.top, greaterThanOrEqualTo(0));
      expect(result.bottom, lessThanOrEqualTo(height));
      // And it really was far down: the screen had to scroll to show it.
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scroll.position.pixels, greaterThan(0));
    });
  });

  group('H-T14-2: the title of the screen', () {
    setUpAll(() async {
      expect(await loadRoboto(), isTrue, reason: 'Roboto from the SDK');
    });

    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('is whole at $width dp, text $scale', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final app = await AppUnderTest.pump(
            tester,
            size: Size(width, 900),
            overrides: importOverrides(
              phone: FakeDeviceCalendar(),
              picker: FakePicker(),
            ),
          );
          await app.openSettings();
          await tester.ensureVisible(byKey('settings-export-calendar'));
          await tester.pumpAndSettle();
          await tester.tap(byKey('settings-export-calendar'));
          await tester.pumpAndSettle();

          final title = find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Exportar turnos'),
          );
          expect(title, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(title);
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: 'the title is cut with an ellipsis',
          );
          // Same family as «Importar turnos», which always fitted.
          expect(tester.getRect(title).right, lessThanOrEqualTo(width));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
