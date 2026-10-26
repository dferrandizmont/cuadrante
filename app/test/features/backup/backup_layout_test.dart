import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import 'backup_ui_support.dart';
import 'golden_dataset_v2.dart';

/// The backup screens on a narrow phone with big text and in the dark theme:
/// nothing overflows or gets cut, and every button can still be reached.
void main() {
  setUpAll(initializeLocale);

  Finder key(String k) => find.byKey(ValueKey(k));

  for (final (name, width, scale, brightness) in [
    ('narrow phone', 320.0, 1.0, Brightness.light),
    ('text x1.3', 360.0, 1.3, Brightness.light),
    ('text x2.0, dark', 360.0, 2.0, Brightness.dark),
  ]) {
    testWidgets('the screen and the preview fit: $name', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      final h = BackupUiHarness(tester);
      h.channel.system = SystemBackupState.off;
      final app = await AppUnderTest.pump(
        tester,
        size: Size(width, 900),
        platformBrightness: brightness,
        overrides: h.overrides,
      );

      void noErrors(String where) {
        expect(tester.takeException(), isNull, reason: where);
      }

      await app.openSettings();
      await tapIo(tester, key('settings-backup'), until: key('backup-status'));
      noErrors('copies screen, no copy yet');

      // A copy, a failed one after it, and a result of "Probar restauración".
      await tapIo(
        tester,
        key('backup-now'),
        until: find.textContaining('Copia del dispositivo'),
      );
      final firstCopy = h.filesStartingWith('cuadrante-').single;
      final blockedCopy = firstCopy.replaceFirst('.cuadrante', '-2.cuadrante');
      Directory('${h.backups.path}${Platform.pathSeparator}$blockedCopy')
          .createSync();
      app.container.read(autoBackupRunnerProvider).noteChange();
      await tester.pump(const Duration(minutes: 15));
      await pumpIo(tester, until: key('backup-failed-title'));
      await tapIo(
        tester,
        key('backup-verify'),
        until: key('backup-verify-result'),
      );
      await pumpIo(tester);
      noErrors('copies screen with a failure and a verification');

      // The preview of a bigger file.
      h.picked = IncomingFile.bytes(
        BackupUiHarness.fileOf(buildGoldenBackupDataV2()),
      );
      await tapIo(tester, key('backup-import'), until: key('restore-preview'));
      await tester.ensureVisible(key('restore-confirm'));
      await tester.pump();
      noErrors('preview');
      expect(
        tester.getRect(key('restore-confirm')).right,
        lessThanOrEqualTo(width),
      );
      await pumpIo(tester);
    });
  }

  testWidgets('the «Copia hecha» SnackBar never covers the last «Restaurar '
      'esta»', (tester) async {
    final h = BackupUiHarness(tester);
    final app = await AppUnderTest.pump(
      tester,
      size: const Size(390, 560),
      overrides: h.overrides,
    );
    await app.openSettings();
    await tapIo(tester, key('settings-backup'), until: key('backup-status'));
    final restores = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey &&
          (w.key! as ValueKey).value.toString().startsWith('backup-restore-'),
    );
    // Two copies, so the list is the longest thing on the screen.
    for (var i = 0; i < 2; i++) {
      await tapIo(tester, key('backup-now'), until: find.byType(SnackBar));
      if (i == 0) await tester.pump(const Duration(seconds: 8));
    }
    await pumpIo(tester, until: restores);
    expect(find.byType(SnackBar), findsOneWidget);

    expect(restores, findsWidgets);
    final last = restores.last;
    await tester.ensureVisible(last);
    // The scroll view can bring it above the SnackBar: it ends clear of it.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();
    final snack = tester.getRect(find.byType(SnackBar));
    final button = tester.getRect(last);
    expect(
      button.bottom,
      lessThanOrEqualTo(snack.top),
      reason: 'the button ($button) is tappable above the SnackBar ($snack)',
    );
    await pumpIo(tester);
  });
}
