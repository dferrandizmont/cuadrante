import 'dart:async';
import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/data/export_cache.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/presentation/restore_preview_screen.dart';
import 'package:cuadrante/features/onboarding/application/onboarding_providers.dart';
import 'package:cuadrante/features/onboarding/data/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../support/app_harness.dart';
import 'backup_test_support.dart';
import 'backup_ui_support.dart';
import 'golden_dataset_v2.dart';

/// What the host does with files other apps hand over: one preview at a time,
/// opened at once, never reading on the UI's time.
void main() {
  setUpAll(initializeLocale);

  Finder key(String k) => find.byKey(ValueKey(k));

  final golden = BackupUiHarness.fileOf(buildGoldenBackupDataV2());

  int stack(AppUnderTest app) => app.container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .matches
      .length;

  int previews() => find.byType(RestorePreviewScreen).evaluate().length;

  group('the preview opens at once', () {
    testWidgets('showing "Leyendo el archivo…" while the platform reads, with '
        'Back available', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await AppUnderTest.pump(tester, overrides: h.overrides);
      // The loader spins for ever, so the file arrives after start-up (a
      // spinner on screen at start would stop the harness from settling).
      h.channel
        ..incoming = IncomingFile.bytes(golden)
        ..gate = Completer<void>(); // a read that does not come back
      h.channel.listener!();
      await pumpIo(tester, until: key('restore-reading'));

      expect(find.text('Leyendo el archivo…'), findsOneWidget);
      expect(h.channel.takes, 1);
      final onTop = stack(app);

      // Back works while it waits.
      await tester.tap(find.byType(BackButton).last);
      await pumpIo(tester);
      expect(previews(), 0);
      expect(stack(app), onTop - 1);

      // The read finally ends: nothing breaks, nothing opens again.
      h.channel.gate!.complete();
      await pumpIo(tester);
      expect(previews(), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('and shows the preview when the read ends', (tester) async {
      final h = BackupUiHarness(tester);
      await AppUnderTest.pump(tester, overrides: h.overrides);
      h.channel
        ..incoming = IncomingFile.bytes(golden)
        ..gate = Completer<void>();
      h.channel.listener!();
      await pumpIo(tester, until: key('restore-reading'));
      h.channel.gate!.complete();
      await pumpIo(tester, until: key('restore-preview'));
      expect(key('restore-reading'), findsNothing);
    });

    testWidgets('and says so when the platform gives nothing back', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      h.channel.incoming = IncomingFile.bytes(golden);
      final app = await AppUnderTest.pump(
        tester,
        overrides: h.overrides,
        expectMonth: false,
      );
      await pumpIo(tester, until: key('restore-preview'));
      // Another file is announced, but there is nothing to take by the time
      // the screen asks: it ends as unreadable, it does not hang.
      h.channel.incoming = IncomingFile.bytes(golden);
      h.channel.listener!();
      h.channel.incoming = null;
      await pumpIo(tester, until: key('restore-unusable'));
      expect(previews(), 1);
      expect(stack(app), greaterThan(1));
    });

    testWidgets('no file, no screen, no read', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await AppUnderTest.pump(tester, overrides: h.overrides);
      await pumpIo(tester);
      expect(previews(), 0);
      expect(h.channel.takes, 0);
      expect(stack(app), 1);
    });
  });

  group('never two previews', () {
    testWidgets('files delivered one after another replace the preview', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      h.channel.incoming = IncomingFile.bytes(golden);
      final app = await AppUnderTest.pump(
        tester,
        overrides: h.overrides,
        expectMonth: false,
      );
      await pumpIo(tester, until: key('restore-preview'));
      final depth = stack(app);

      for (var i = 0; i < 4; i++) {
        h.channel.incoming = IncomingFile.bytes(golden);
        h.channel.listener!();
        await pumpIo(tester, until: key('restore-preview'));
        expect(previews(), 1, reason: 'delivery $i');
        expect(stack(app), depth, reason: 'delivery $i');
      }

      // One Back leaves the preview: there was only ever one.
      await tester.tap(find.byType(BackButton).last);
      await pumpIo(tester);
      expect(previews(), 0);
      expect(stack(app), depth - 1);
    });

    testWidgets('a burst in the same frame opens one preview', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await AppUnderTest.pump(tester, overrides: h.overrides);
      final depth = stack(app);

      h.channel.incoming = IncomingFile.bytes(golden);
      for (var i = 0; i < 6; i++) {
        h.channel.listener!();
      }
      await pumpIo(tester, until: key('restore-preview'));
      await pumpIo(tester);

      expect(previews(), 1);
      expect(stack(app), depth + 1);
      expect(h.channel.takes, 1, reason: 'one file, read once');
    });

    testWidgets('a file that arrives while the data is being replaced is '
        'dropped, not swapped in', (tester) async {
      final h = BackupUiHarness(tester);
      h.channel.incoming = IncomingFile.bytes(golden);
      final app = await AppUnderTest.pump(
        tester,
        overrides: h.overrides,
        expectMonth: false,
      );
      await pumpIo(tester, until: key('restore-preview'));
      final depth = stack(app);

      app.container.read(restoreInProgressProvider.notifier).set(true);
      h.channel.incoming = IncomingFile.bytes(golden);
      final takesBefore = h.channel.takes;
      h.channel.listener!();
      await pumpIo(tester);

      expect(h.channel.discards, 1);
      expect(h.channel.takes, takesBefore, reason: 'never read');
      expect(previews(), 1);
      expect(stack(app), depth);
      expect(key('restore-preview'), findsOneWidget);
    });
  });

  group('during the first-use flow', () {
    testWidgets('a file waits, and opens when the flow ends', (tester) async {
      final h = BackupUiHarness(tester);
      h.channel.incoming = IncomingFile.bytes(golden);
      final app = await AppUnderTest.pump(
        tester,
        overrides: [
          ...h.overrides,
          initialOnboardingProvider.overrideWithValue(
            const OnboardingStatus(needed: true),
          ),
        ],
        expectMonth: false,
      );
      await pumpIo(tester);
      expect(
        app.container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation,
        AppRoutes.onboarding,
      );
      expect(previews(), 0, reason: 'not over the first-use flow');
      expect(h.channel.takes, 0, reason: 'still pending, not read');
      expect(h.channel.discards, 0);

      // The flow ends: the file opens.
      app.container.read(routerProvider).go(AppRoutes.home);
      await pumpIo(tester, until: key('restore-preview'));
      expect(previews(), 1);
      expect(h.channel.takes, 1);
    });

    testWidgets('one that arrives during the flow waits as well', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final app = await AppUnderTest.pump(
        tester,
        overrides: [
          ...h.overrides,
          initialOnboardingProvider.overrideWithValue(
            const OnboardingStatus(needed: true),
          ),
        ],
        expectMonth: false,
      );
      h.channel.incoming = IncomingFile.bytes(golden);
      h.channel.listener!();
      await pumpIo(tester);
      expect(previews(), 0);
      expect(h.channel.takes, 0);

      app.container.read(routerProvider).go(AppRoutes.home);
      await pumpIo(tester, until: key('restore-preview'));
      expect(previews(), 1);
    });
  });

  group('the tapjacking guard of the preview', () {
    testWidgets('stays on when a delivery replaces the preview, and goes off '
        'only after the last one is gone', (tester) async {
      final h = BackupUiHarness(tester);
      h.channel.incoming = IncomingFile.bytes(golden);
      await AppUnderTest.pump(
        tester,
        overrides: h.overrides,
        expectMonth: false,
      );
      await pumpIo(tester, until: key('restore-preview'));
      expect(h.channel.protection, [true]);

      for (var i = 0; i < 3; i++) {
        h.channel.incoming = IncomingFile.bytes(golden);
        h.channel.listener!();
        await pumpIo(tester, until: key('restore-preview'));
        expect(h.channel.protection.last, isTrue, reason: 'delivery $i');
        expect(h.channel.protection, [true], reason: 'delivery $i');
      }

      await tester.tap(find.byType(BackButton).last);
      await pumpIo(tester);
      expect(previews(), 0);
      expect(h.channel.protection, [true, false]);
    });
  });

  testWidgets('the export folder is emptied when the app starts', (
    tester,
  ) async {
    final h = BackupUiHarness(tester);
    final cacheRoot = makeTempDir('host-export-cache');
    final leftover = File(
      p.join(cacheRoot.path, ExportCache.folderName, 'old.cuadrante'),
    )..createSync(recursive: true);
    leftover.writeAsBytesSync([1, 2, 3]);

    await AppUnderTest.pump(
      tester,
      overrides: [
        ...h.overrides,
        exportCacheProvider.overrideWith((ref) async => ExportCache(cacheRoot)),
      ],
    );
    await pumpIo(tester);

    expect(leftover.existsSync(), isFalse);
  });
}
