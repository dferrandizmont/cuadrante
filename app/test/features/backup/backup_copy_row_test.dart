import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../support/real_font.dart';
import 'backup_ui_support.dart';
import 'golden_dataset_v2.dart';

/// «Copias en este dispositivo» (user report from the phone): «Restaurar esta» was
/// on a line of its own, flush right, far from the text of its copy. Now it is
/// the trailing action of the row, centred on the two lines of text and at the
/// x of the chevrons of the other rows; where it does not fit beside the text
/// (big text, narrow phone) it goes under it, with its text on the title's x.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  const copyNames = [
    // Today (the fake clock is 19 Oct 2026, 12:00 in Madrid).
    'cuadrante-20261019-100000.cuadrante',
    // A long date: it decides whether the whole list can go beside the button.
    'cuadrante-20260908-153000.cuadrante',
    'pre-restore-20261017-203000.cuadrante',
  ];

  Finder inRow(String id, Finder what) => find.descendant(
    of: find.byKey(ValueKey('backup-copy-$id')),
    matching: what,
  );

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('«Restaurar esta» at $width dp, text $scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final h = BackupUiHarness(tester);
        h.backups.createSync(recursive: true);
        final bytes = BackupUiHarness.fileOf(buildGoldenBackupDataV2());
        for (final name in copyNames) {
          File(p.join(h.backups.path, name)).writeAsBytesSync(bytes);
        }
        await h.open(size: Size(width, 4000));
        expect(tester.takeException(), isNull);

        // The x where the trailing elements of the other rows end.
        final chevron = tester.getRect(
          find
              .descendant(
                of: find.byKey(const ValueKey('backup-import')),
                matching: find.byIcon(AppIcons.chevronRight),
              )
              .first,
        );

        final modes = <bool>{};
        for (final name in copyNames) {
          final id = name;
          final row = tester.getRect(find.byKey(ValueKey('backup-copy-$id')));
          final label = tester.getRect(inRow(id, find.text('Restaurar esta')));
          final texts = inRow(id, find.byType(Text));
          final title = tester.getRect(texts.first);
          final meta = tester.getRect(
            inRow(id, find.textContaining(' · ')).first,
          );

          final beside = label.center.dy < meta.bottom;
          modes.add(beside);
          if (beside) {
            // Same row, centred on it, and its text ends where the chevrons do.
            expect(
              label.center.dy,
              closeTo(row.center.dy, 1),
              reason: '$id: centred on the row',
            );
            expect(
              label.right,
              closeTo(chevron.right, 0.5),
              reason: '$id: on the chevron column',
            );
            expect(
              label.left,
              greaterThanOrEqualTo(meta.right - 0.5),
              reason: '$id: not over the text',
            );
          } else {
            // Under the text, on the x of the title; never far right.
            expect(
              label.left,
              closeTo(title.left, 0.5),
              reason: '$id: on title',
            );
            expect(label.top, greaterThanOrEqualTo(meta.bottom - 0.5));
            expect(label.bottom, lessThanOrEqualTo(row.bottom + 0.5));
          }
          expect(
            label.right,
            lessThanOrEqualTo(width),
            reason: '$id: on screen',
          );
          expect(label.left, greaterThanOrEqualTo(0));
        }
        // The list looks the same in every row.
        expect(modes, hasLength(1), reason: 'all rows beside or all under');
        // And the answer is the expected one at the extremes (the test is not
        // vacuous): roomy phone with normal text beside, huge text under.
        if (width == 412 && scale == 1.0) expect(modes.single, isTrue);
        if (scale == 2.0) expect(modes.single, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('«Restaurar esta» still restores (beside and under)', (
    tester,
  ) async {
    final h = BackupUiHarness(tester);
    h.backups.createSync(recursive: true);
    File(p.join(h.backups.path, copyNames.first))
        .writeAsBytesSync(BackupUiHarness.fileOf(buildGoldenBackupDataV2()));
    await h.open(size: const Size(412, 1800));
    await tester.tap(find.byKey(ValueKey('backup-restore-${copyNames.first}')));
    await pumpIo(tester, until: find.byKey(const ValueKey('restore-preview')));
    expect(find.byKey(const ValueKey('restore-preview')), findsOneWidget);
  });
}
