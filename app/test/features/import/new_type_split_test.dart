import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/core/l10n/l10n.dart';
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/features/import/presentation/new_type_sheet.dart';
import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import '../shift_types/shift_types_screen_test.dart' show setTime, tapKey;

const _split = ShiftTypeDraft(
  code: 'P',
  name: 'Partido',
  startMinute: 10 * 60,
  endMinute: 14 * 60,
  segment2StartMinute: 16 * 60,
  segment2DurationMinutes: 4 * 60,
);
Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _open(
  WidgetTester tester, {
  required ValueChanged<ShiftTypeDraft?> onResult,
  double scale = 1,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 800) * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearAllTestValues();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => onResult(
              await showNewTypeSheet(
                context: context,
                draft: _split,
                taken: const [],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue);
  });

  testWidgets(
    'H-T22-16: imported split type shows both segments and saves edits',
    (tester) async {
      ShiftTypeDraft? result;
      await _open(tester, onResult: (draft) => result = draft);
      expect(
        tester.widget<SwitchListTile>(_key('import-new-split')).value,
        isTrue,
      );
      for (final time in [
        'Empieza 10:00',
        'Termina 14:00',
        'Empieza 16:00',
        'Termina 20:00',
      ]) {
        expect(find.text(time), findsOneWidget);
      }
      await setTime(tester, 'import-new-start2', 17, 0);
      await setTime(tester, 'import-new-end2', 21, 30);
      await tapKey(tester, 'import-new-save');
      expect(result, isNotNull);
      final type = result!.toShiftType('p');
      expect(type.startMinute, 600);
      expect(type.endMinute, 840);
      expect(type.segment2StartMinute, 1020);
      expect(type.segment2DurationMinutes, 270);
      expect(type.scheduledMinutes, 510);
    },
  );

  testWidgets(
    'import split editor rejects invalid segments and can remove the split',
    (tester) async {
      ShiftTypeDraft? result;
      await _open(tester, onResult: (draft) => result = draft);
      await setTime(tester, 'import-new-start2', 14, 0);
      expect(_key('import-new-split-error'), findsOneWidget);
      await tapKey(tester, 'import-new-save');
      expect(result, isNull);
      expect(_key('import-new-save'), findsOneWidget);
      await tapKey(tester, 'import-new-split');
      expect(_key('import-new-start2'), findsNothing);
      await tapKey(tester, 'import-new-save');
      expect(result!.toShiftType('p').hasSegment2, isFalse);
    },
  );

  testWidgets(
    '320 dp, text 2.0: imported split editor exposes all four time buttons',
    (tester) async {
      await _open(tester, onResult: (_) {}, scale: 2, width: 320);
      for (final key in [
        'import-new-start',
        'import-new-end',
        'import-new-start2',
        'import-new-end2',
        'import-new-save',
      ]) {
        await tester.ensureVisible(_key(key));
        await tester.pumpAndSettle();
        final rect = tester.getRect(_key(key));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(320), reason: key);
        expect(rect.height, greaterThanOrEqualTo(48), reason: key);
        for (final element
            in find
                .descendant(of: _key(key), matching: find.byType(RichText))
                .evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(paragraph.didExceedMaxLines, isFalse, reason: key);
          expect(wrapsOnlyBetweenWords(paragraph), isTrue, reason: key);
        }
        expect(tester.takeException(), isNull, reason: key);
      }
    },
  );
}
