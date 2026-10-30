import 'dart:async';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/backup/application/backup_actions.dart';
import 'package:cuadrante/features/backup/application/backup_models.dart';
import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/backup_files.dart'
    show backupStamp;
import 'package:cuadrante/features/backup/data/icloud_backup_store.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import 'backup_test_support.dart';
import 'backup_ui_support.dart';
import 'golden_dataset_v2.dart';

/// Importing a `.turnly` (a file, one handed over by another app, a copy of
/// the phone): the preview, the confirmation, the blocking progress, the
/// result, the safety copy, and the files that must be refused without
/// touching a thing (R4, R6, R7).
void main() {
  setUpAll(initializeLocale);

  Finder key(String k) => find.byKey(ValueKey(k));

  final golden = BackupUiHarness.fileOf(buildGoldenBackupDataV2());

  /// All the rows of every table, to compare "before" and "after".
  Future<Map<String, List<Map<String, Object?>>>> dump(AppUnderTest app) =>
      app.real(() => dumpAllTables(app.database));

  /// The fingerprint of what the phone holds (entities and 730 days of every
  /// calendar).
  Future<String> digest(AppUnderTest app, BackupUiHarness h) async {
    final data = await app.real(
      () => makeRepository(app.database, h.backups).readAll(),
    );
    final window = defaultFingerprintWindow(harnessToday);
    return scheduleFingerprint(data, from: window.from, to: window.to).digest;
  }

  String digestOf(Uint8List bytes) {
    final data = const BackupCodec().decode(bytes).data;
    final window = defaultFingerprintWindow(harnessToday);
    return scheduleFingerprint(data, from: window.from, to: window.to).digest;
  }

  /// "Importar archivo" with [bytes] as what the picker returns.
  Future<void> importFile(
    WidgetTester tester,
    BackupUiHarness h,
    Uint8List bytes,
  ) async {
    h.picked = IncomingFile.bytes(bytes);
    await tapIo(
      tester,
      key('backup-import'),
      until: find.byWidgetPredicate(
        (w) =>
            w.key == const ValueKey('restore-preview') ||
            w.key == const ValueKey('restore-unusable'),
      ),
    );
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.ensureVisible(key('restore-confirm'));
    await tester.pump();
    await tester.tap(key('restore-confirm'));
    await pumpIo(tester, until: key('restore-done'), reason: 'the result');
  }

  group('the preview', () {
    testWidgets('shows what the file brings and what it replaces', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final before = await dump(app);

      await importFile(tester, h, golden);

      expect(textOf(tester, key('restore-origin')), 'ARCHIVO QUE HAS ELEGIDO');
      expect(
        textOf(tester, key('restore-saved')),
        startsWith('Guardada el mar 10 nov a las '),
      );
      // The file: 3 calendars (one archived), shift types, rotations...
      expect(textOf(tester, key('restore-calendars')), '3');
      expect(
        textOf(tester, key('restore-calendars-detail')),
        'Hospital, Pareja, Segundo trabajo (antiguo) (archivado)',
      );
      final data = const BackupCodec().decode(golden).data;
      expect(textOf(tester, key('restore-days')), '${data.dayEntries.length}');
      expect(textOf(tester, key('restore-runs')), '${data.patternRuns.length}');
      expect(textOf(tester, key('restore-types')), '${data.shiftTypes.length}');
      // What the phone has now sits next to it.
      expect(find.text('Ahora: 1'), findsWidgets); // calendars, rotations
      // The range of dates, and the honest sentence about replacing.
      expect(find.textContaining('Del '), findsOneWidget);
      expect(
        textOf(tester, key('restore-replace-notice')),
        'Esto sustituye lo que tienes ahora; antes guardamos una copia.',
      );
      expect(find.text('Sustituir lo que tengo'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      // Looking is not restoring.
      expect(await dump(app), before);
      expect(h.filesStartingWith('pre-restore'), isEmpty);
    });

    testWidgets('"Cancelar" goes back and changes nothing', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final before = await dump(app);
      await importFile(tester, h, golden);

      await tester.ensureVisible(key('restore-cancel'));
      await tester.pump();
      await tester.tap(key('restore-cancel'));
      await pumpIo(tester, until: key('backup-status'));

      expect(await dump(app), before);
      expect(h.filesStartingWith('pre-restore'), isEmpty);
    });

    testWidgets('a cancelled file picker does nothing', (tester) async {
      final h = BackupUiHarness(tester);
      await h.open();
      h.picked = null;
      await tapIo(tester, key('backup-import'));
      expect(key('backup-status'), findsOneWidget);
      expect(key('restore-preview'), findsNothing);
    });
  });

  group('importing', () {
    testWidgets('confirming restores the file, reloads and shows the '
        'calendar (R4)', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final originalDigest = await digest(app, h);
      await importFile(tester, h, golden);

      await confirm(tester);

      // The data is the file's, down to the 730 resolved days of every
      // calendar...
      expect(await digest(app, h), digestOf(golden));
      expect(await digest(app, h), isNot(originalDigest));
      // ...the editor holds it in memory too (the restore reloaded it)...
      final names = [
        for (final c
            in await app
                .real(() => makeRepository(app.database, h.backups).readAll())
                .then((d) => d.calendars))
          c.name,
      ];
      expect(
        names,
        unorderedEquals(['Hospital', 'Pareja', 'Segundo trabajo (antiguo)']),
      );
      // ...and a safety copy of what was there is on disk.
      expect(h.filesStartingWith('pre-restore-'), hasLength(1));

      // The result says so and offers the calendar and the way back.
      expect(find.text('Listo, tu cuadrante está restaurado'), findsOneWidget);
      expect(find.text('Volver a como estaba'), findsOneWidget);
      await tester.tap(find.text('Ver mi calendario'));
      await pumpIo(tester, until: find.text('Pareja'), reason: 'calendar pill');
      // The calendar the file had on screen is the one shown ("Pareja").
      expect(find.text('Pareja'), findsWidgets);
      expect(
        app.container.read(scheduleControllerProvider).calendarId,
        'cal-pareja',
      );
    });

    testWidgets('export, wipe, import: the same fingerprint (R4)', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final original = await digest(app, h);

      await tapIo(tester, key('backup-export'));
      expect(h.shared, hasLength(1));
      final exported = h.shared.single;
      expect(exported.fileName, 'turnly-2026-10-19-120000.turnly');
      expect(digestOf(exported.bytes), original);

      // The phone loses its rotation behind the app's back.
      await app.real(
        () => app.database.customStatement('DELETE FROM pattern_runs'),
      );
      await app.real(
        app.container.read(scheduleControllerProvider.notifier).reload,
      );
      expect(await digest(app, h), isNot(original));

      await importFile(tester, h, exported.bytes);
      await confirm(tester);
      expect(await digest(app, h), original);
    });

    testWidgets('a file another app hands over opens the preview by itself', (
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
      expect(
        textOf(tester, key('restore-origin')),
        'ARCHIVO RECIBIDO DE OTRA APP',
      );
      expect(
        app.container.read(routerProvider).state.uri.path,
        AppRoutes.settingsBackupImport,
      );
      // It is only a preview: nothing is restored until the user confirms.
      expect(h.filesStartingWith('pre-restore'), isEmpty);
    });

    testWidgets('a file that arrives while the app is open does the same', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      await AppUnderTest.pump(tester, overrides: h.overrides);
      expect(key('restore-preview'), findsNothing);

      h.channel.incoming = IncomingFile.bytes(golden);
      h.channel.listener!();
      await pumpIo(tester, until: key('restore-preview'));
      expect(
        textOf(tester, key('restore-origin')),
        'ARCHIVO RECIBIDO DE OTRA APP',
      );
    });

    testWidgets('a shared file that was too big or unreadable is refused', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      h.channel.incoming = const IncomingFile.problem(
        IncomingFileProblem.tooLarge,
      );
      await AppUnderTest.pump(
        tester,
        overrides: h.overrides,
        expectMonth: false,
      );
      await pumpIo(tester, until: key('restore-unusable'));
      expect(
        find.text(
          'Este archivo es demasiado grande para ser una copia de Turnly.',
        ),
        findsOneWidget,
      );
    });
  });

  group('refused files leave the data untouched (R6, R7)', () {
    final wrong = <String, (Uint8List, String)>{
      'a newer version (R6)': (
        gzipEnvelope({
          'format': 'cuadrante',
          'schemaVersion': 4,
          'appVersion': '9.9.9',
          'exportedAt': '2030-01-01T00:00:00Z',
          'data': {'calendars': <Object?>[]},
          'checksum': 'blake3:nothing',
        }),
        'Este archivo es de una versión más nueva de Turnly: actualiza la '
            'app.',
      ),
      'a truncated copy (R7)': (
        Uint8List.sublistView(golden, 0, golden.length ~/ 2),
        'El archivo está dañado o incompleto y no se puede usar.',
      ),
      'a copy with a changed byte (R7)': (
        Uint8List.fromList(golden)..[golden.length ~/ 2] ^= 0xFF,
        'El archivo está dañado o incompleto y no se puede usar.',
      ),
      'a file that is not a backup': (
        Uint8List.fromList(List<int>.generate(64, (i) => i)),
        'Este archivo no es una copia de Turnly.',
      ),
      'an empty file': (
        Uint8List(0),
        'Este archivo no es una copia de Turnly.',
      ),
    };

    for (final MapEntry(key: name, value: (bytes, message)) in wrong.entries) {
      testWidgets(name, (tester) async {
        final h = BackupUiHarness(tester);
        final app = await h.open();
        final before = await dump(app);
        final originalDigest = await digest(app, h);

        await importFile(tester, h, bytes);

        expect(key('restore-unusable'), findsOneWidget);
        expect(find.text(message), findsOneWidget);
        expect(
          find.text('No hemos cambiado nada: tus datos siguen como estaban.'),
          findsOneWidget,
        );
        // Nothing to confirm.
        expect(key('restore-confirm'), findsNothing);
        expect(await dump(app), before);
        expect(await digest(app, h), originalDigest);
        expect(
          h.filesStartingWith('pre-restore'),
          isEmpty,
          reason: 'no restore started, so no safety copy either',
        );

        // "Volver" is back on the copies.
        await tester.tap(find.text('Volver'));
        await pumpIo(tester, until: key('backup-status'));
      });
    }

    testWidgets('a file the picker could not read', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final before = await dump(app);
      h.picked = const IncomingFile.problem(IncomingFileProblem.unreadable);
      await tapIo(tester, key('backup-import'), until: key('restore-unusable'));
      expect(find.text('No se ha podido leer el archivo.'), findsOneWidget);
      expect(await dump(app), before);
    });

    testWidgets('the screen without a file goes back to the copies', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      app.container.read(routerProvider).go(AppRoutes.settingsBackupImport);
      await pumpIo(tester);
      expect(key('backup-status'), findsOneWidget);
    });
  });

  group('the safety copy', () {
    testWidgets('is listed after a restore, and restoring it brings the '
        'previous data back', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final before = await dump(app);
      final originalDigest = await digest(app, h);

      await importFile(tester, h, golden);
      await confirm(tester);
      expect(await digest(app, h), digestOf(golden));

      // Back on the copies, the safety copy is there.
      app.container.read(routerProvider).go(AppRoutes.settingsBackup);
      await pumpIo(tester, until: find.textContaining('Antes de restaurar'));
      final safety = h.filesStartingWith('pre-restore-').single;
      expect(key('backup-copy-$safety'), findsOneWidget);
      expect(
        find.descendant(
          of: key('backup-copy-$safety'),
          matching: find.textContaining('Antes de restaurar'),
        ),
        findsOneWidget,
      );

      // "Restaurar esta" goes through the same preview.
      await tapIo(
        tester,
        key('backup-restore-$safety'),
        until: key('restore-preview'),
      );
      expect(
        textOf(tester, key('restore-origin')),
        'COPIA DE JUSTO ANTES DE RESTAURAR',
      );
      await confirm(tester);

      expect(await digest(app, h), originalDigest);
      // Everything is back, but for the device's own first-use flag: a
      // restore marks the first use as done (it is not part of any backup).
      final after = await dump(app);
      Map<String, List<Map<String, Object?>>> withoutDeviceFlags(
        Map<String, List<Map<String, Object?>>> d,
      ) => {
        ...d,
        'settings': [
          for (final row in d['settings']!)
            if (!(row['key']! as String).startsWith('onboarding.')) row,
        ],
      };
      expect(withoutDeviceFlags(after), withoutDeviceFlags(before));
      expect(
        after['settings']!.where((r) => r['key'] == 'onboarding.done'),
        hasLength(1),
      );
      // Undoing the restore made its own safety copy (of the golden data).
      expect(h.filesStartingWith('pre-restore-'), hasLength(2));
    });

    testWidgets('"Volver a como estaba" is one tap from the result', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final originalDigest = await digest(app, h);

      await importFile(tester, h, golden);
      await confirm(tester);
      expect(await digest(app, h), digestOf(golden));

      await tester.tap(find.text('Volver a como estaba'));
      await pumpIo(tester, until: key('restore-preview'));
      expect(
        textOf(tester, key('restore-origin')),
        'COPIA DE JUSTO ANTES DE RESTAURAR',
      );
      // The preview that replaced the first one did not switch the tapjacking
      // guard off under itself.
      expect(h.channel.protection, [true]);
      await confirm(tester);
      expect(await digest(app, h), originalDigest);
      expect(h.channel.protection, [true]);
    });

    testWidgets('a copy of the phone is restorable with "Restaurar esta"', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final originalDigest = await digest(app, h);
      await tapIo(
        tester,
        key('backup-now'),
        until: find.textContaining('Copia del dispositivo'),
      );

      // Change the data (a rotation less), then go back to the copy.
      await app.real(
        () => app.database.customStatement('DELETE FROM pattern_runs'),
      );
      expect(await digest(app, h), isNot(originalDigest));

      final copy = h.filesStartingWith('turnly-').single;
      await tapIo(
        tester,
        key('backup-restore-$copy'),
        until: key('restore-preview'),
      );
      expect(
        textOf(tester, key('restore-origin')),
        'COPIA DE ESTE DISPOSITIVO',
      );
      await confirm(tester);
      expect(await digest(app, h), originalDigest);
    });
  });

  group('a copy from iCloud is an external file (M3)', () {
    testWidgets('goes through the normal preview, the safety copy and the '
        'confirmation, never straight to restore', (tester) async {
      final h = BackupUiHarness(tester);
      final name =
          'turnly-${backupStamp(harnessNow.subtract(const Duration(days: 1)))}'
          '.turnly';
      final files = <String, Uint8List>{name: golden};
      const channel = MethodChannel(ICloudBackupStore.channelName);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'list':
            return [
              for (final e in files.entries)
                {'id': e.key, 'name': e.key, 'sizeBytes': e.value.length},
            ];
          case 'read':
            return files[(call.arguments as Map)['id']];
        }
        throw MissingPluginException(call.method);
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final app = await h.open(
        extraOverrides: [
          iCloudBackupStoreProvider.overrideWithValue(
            ICloudBackupStore(channel: channel, now: () => harnessNow),
          ),
        ],
      );
      final originalDigest = await digest(app, h);
      final tools = await app.real(
        () => app.container.read(backupToolsProvider.future),
      );
      final entry = (await app.real(tools.cloudCopies)).single;
      final request = app.container
          .read(backupActionsProvider)
          .requestForCloud(entry);
      expect(request.origin, BackupImportOrigin.cloudCopy);

      app.container
          .read(routerProvider)
          .push(AppRoutes.settingsBackupImport, extra: request);
      await pumpIo(tester, until: key('restore-preview'));
      expect(textOf(tester, key('restore-origin')), 'COPIA EN ICLOUD');
      // Looking is not restoring.
      expect(await digest(app, h), originalDigest);
      expect(h.filesStartingWith('pre-restore'), isEmpty);

      await confirm(tester);
      expect(await digest(app, h), digestOf(golden));
      expect(h.filesStartingWith('pre-restore-'), hasLength(1));
    });

    testWidgets('a file of iCloud that is not a backup ends in the same '
        '"unusable" screen as any file, data untouched', (tester) async {
      final h = BackupUiHarness(tester);
      final name =
          'turnly-${backupStamp(harnessNow.subtract(const Duration(days: 1)))}'
          '.turnly';
      const channel = MethodChannel(ICloudBackupStore.channelName);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'list':
            return [
              {'id': name, 'name': name, 'sizeBytes': 9},
            ];
          case 'read':
            return Uint8List.fromList(List.filled(9, 7));
        }
        throw MissingPluginException(call.method);
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final app = await h.open(
        extraOverrides: [
          iCloudBackupStoreProvider.overrideWithValue(
            ICloudBackupStore(channel: channel, now: () => harnessNow),
          ),
        ],
      );
      final before = await dump(app);
      final tools = await app.real(
        () => app.container.read(backupToolsProvider.future),
      );
      final entry = (await app.real(tools.cloudCopies)).single;
      app.container
          .read(routerProvider)
          .push(
            AppRoutes.settingsBackupImport,
            extra: app.container
                .read(backupActionsProvider)
                .requestForCloud(entry),
          );
      await pumpIo(tester, until: key('restore-unusable'));
      expect(await dump(app), before);
      expect(h.filesStartingWith('pre-restore'), isEmpty);
    });
  });

  group('while it restores', () {
    testWidgets('the screen is blocked and "atrás" does nothing', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final gate = Completer<void>();
      await h.open(
        extraOverrides: [
          backupActionsProvider.overrideWith((ref) => _SlowActions(ref, gate)),
        ],
      );
      await importFile(tester, h, golden);

      await tester.ensureVisible(key('restore-confirm'));
      await tester.pump();
      await tester.tap(key('restore-confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(key('restore-progress'), findsOneWidget);
      expect(find.text('Restaurando tu cuadrante…'), findsOneWidget);
      expect(find.text('No cierres la app.'), findsOneWidget);

      // The system back gesture is swallowed...
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(key('restore-progress'), findsOneWidget);
      // ...and the buttons under the barrier cannot be reached.
      await tester.tap(key('restore-cancel'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(key('restore-progress'), findsOneWidget);

      gate.complete();
      await pumpIo(tester, until: key('restore-done'));
      expect(key('restore-progress'), findsNothing);
    });

    testWidgets('a restore that fails says nothing changed', (tester) async {
      final h = BackupUiHarness(tester);
      await h.open(
        extraOverrides: [
          backupActionsProvider.overrideWith(
            (ref) => _FailingActions(
              ref,
              const RestoreFailure(dataReplaced: false, cause: 'boom'),
            ),
          ),
        ],
      );
      await importFile(tester, h, golden);
      await tester.ensureVisible(key('restore-confirm'));
      await tester.pump();
      await tester.tap(key('restore-confirm'));
      await pumpIo(tester, until: key('restore-failed'));
      expect(
        find.text('No se ha podido restaurar. Tus datos siguen como estaban.'),
        findsOneWidget,
      );
      expect(key('restore-progress'), findsNothing);
    });

    testWidgets('data restored but the screens not refreshed asks to reopen', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      await h.open(
        extraOverrides: [
          backupActionsProvider.overrideWith(
            (ref) => _FailingActions(
              ref,
              const RestoreFailure(dataReplaced: true, cause: 'reload'),
            ),
          ),
        ],
      );
      await importFile(tester, h, golden);
      await tester.ensureVisible(key('restore-confirm'));
      await tester.pump();
      await tester.tap(key('restore-confirm'));
      await pumpIo(tester, until: key('restore-failed'));
      expect(
        find.textContaining('Hemos restaurado tus datos, pero la pantalla'),
        findsOneWidget,
      );
    });
  });
}

/// A restore that waits for [gate] before it starts.
class _SlowActions extends BackupActions {
  _SlowActions(super.ref, this.gate);

  final Completer<void> gate;

  @override
  Future<void> restore(PendingRestore pending) async {
    await gate.future;
    return super.restore(pending);
  }
}

/// A restore that fails with [failure].
class _FailingActions extends BackupActions {
  _FailingActions(super.ref, this.failure);

  final RestoreFailure failure;

  @override
  Future<void> restore(PendingRestore pending) async => throw failure;
}
