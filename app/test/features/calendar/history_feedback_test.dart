import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/selection_controller.dart';
import 'package:cuadrante/features/calendar/presentation/history_feedback.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  setUpAll(initializeLocale);
  for (final selection in [false, true]) {
    testWidgets(
      '${selection ? 'selection' : 'paint'} announces undo and redo outcomes',
      (tester) async {
        final messages = <String>[];
        tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              (message) async {
                final event = message! as Map;
                if (event['type'] == 'announce') {
                  messages.add((event['data'] as Map)['message'] as String);
                }
                return null;
              },
            );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger
              .setMockDecodedMessageHandler<Object?>(
                SystemChannels.accessibility,
                null,
              ),
        );
        await pumpCalendar(tester);
        final container = containerOf(tester);
        if (selection) {
          container.read(selectionControllerProvider.notifier).enter();
          await tester.pumpAndSettle();
        } else {
          await enterPaintMode(tester);
        }
        final controller = container.read(scheduleControllerProvider.notifier);
        controller.setDayShifts(const CivilDate(2026, 10, 19), const [
          'morning',
        ]);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('undo')));
        await tester.pumpAndSettle();
        expect(messages.last, 'Cambio deshecho');
        expect(
          idsOn(
            container.read(scheduleControllerProvider).schedule,
            const CivilDate(2026, 10, 19),
          ),
          'night',
        );
        await tester.tap(find.byKey(const ValueKey('redo')));
        await tester.pumpAndSettle();
        expect(messages.last, 'Cambio rehecho');
        expect(
          idsOn(
            container.read(scheduleControllerProvider).schedule,
            const CivilDate(2026, 10, 19),
          ),
          'morning',
        );
      },
    );
  }

  testWidgets(
    'a snackbar undo announces no change when another step is newer',
    (tester) async {
      final messages = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            final event = message! as Map;
            if (event['type'] == 'announce') {
              messages.add((event['data'] as Map)['message'] as String);
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      await pumpCalendar(tester);
      final container = containerOf(tester);
      final selection = container.read(selectionControllerProvider.notifier);
      selection.begin(const CivilDate(2026, 10, 19));
      selection.endDrag();
      await tester.pumpAndSettle();
      final clear = find.byKey(const ValueKey('selection-clear'));
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      final controller = container.read(scheduleControllerProvider.notifier);
      controller.setDayShifts(const CivilDate(2026, 10, 20), const ['morning']);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SnackBarAction, 'Deshacer'));
      await tester.pumpAndSettle();
      expect(messages.last, 'Nada que deshacer');
      expect(
        idsOn(
          container.read(scheduleControllerProvider).schedule,
          const CivilDate(2026, 10, 20),
        ),
        'morning',
      );

      // The same feedback helper also reports an empty redo history.
      final context = tester.element(
        find.byKey(const ValueKey('selection-bar')),
      );
      redoWithFeedback(context, controller);
      await tester.pump();
      expect(messages.last, 'Nada que rehacer');
    },
  );
  for (final tool in ['selection-clear', 'selection-cut']) {
    testWidgets('$tool undo announces success after leaving selection mode', (
      tester,
    ) async {
      final messages = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            final event = message! as Map;
            if (event['type'] == 'announce') {
              messages.add((event['data'] as Map)['message'] as String);
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      await pumpCalendar(tester);
      final selection = containerOf(tester)
          .read(selectionControllerProvider.notifier);
      selection.begin(const CivilDate(2026, 10, 19));
      selection.endDrag();
      await tester.pumpAndSettle();
      final action = find.byKey(ValueKey(tool));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      selection.exit();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SnackBarAction, 'Deshacer'));
      await tester.pumpAndSettle();
      expect(messages.last, 'Cambio deshecho');
      expect(idsOn(scheduleOf(tester), const CivilDate(2026, 10, 19)), 'night');
    });
  }
}
