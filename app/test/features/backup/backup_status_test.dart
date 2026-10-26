import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/presentation/backup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../support/app_harness.dart';
import 'backup_ui_support.dart';

/// The status card of Ajustes > Copia de seguridad in each state: no copy
/// yet, a recent one, an old one, a failed automatic copy.
void main() {
  setUpAll(initializeLocale);

  Finder key(String k) => find.byKey(ValueKey(k));

  testWidgets('the settings row opens the screen (no more "Próximamente")', (
    tester,
  ) async {
    final h = BackupUiHarness(tester);
    final app = await AppUnderTest.pump(
      tester,
      size: const Size(390, 1800),
      overrides: h.overrides,
    );
    await app.openSettings();
    final row = key('settings-backup');
    expect(
      find.descendant(of: row, matching: find.text('Próximamente')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.text('Automática, exportar e importar'),
      ),
      findsOneWidget,
    );
    await tester.tap(row);
    await pumpIo(tester, until: find.byType(BackupScreen));
    expect(find.text('Copia de seguridad'), findsWidgets);
    expect(
      app.container.read(routerProvider).state.uri.path,
      AppRoutes.settingsBackup,
    );
  });

  group('no copy yet', () {
    testWidgets('says so, warns, and offers the copy', (tester) async {
      final h = BackupUiHarness(tester);
      await h.open();

      expect(
        textOf(tester, key('backup-status-title')),
        'Todavía no hay ninguna copia',
      );
      expect(find.textContaining('se pierde tu cuadrante'), findsOneWidget);
      expect(
        find.textContaining('Si desinstalas la app sin otra copia, se pierde'),
        findsOneWidget,
      );
      expect(key('backup-copies-empty'), findsOneWidget);
      expect(key('backup-failed-title'), findsNothing);
      expect(find.text('Hacer copia ahora'), findsOneWidget);
      expect(find.text('Exportar archivo'), findsOneWidget);
      expect(find.text('Importar archivo'), findsOneWidget);
      expect(find.text('Probar restauración'), findsOneWidget);
      expect(h.files, isEmpty);
    });
  });

  group('a copy', () {
    testWidgets('"Hacer copia ahora" writes it and the card shows when and '
        'where', (tester) async {
      final h = BackupUiHarness(tester);
      await h.open();

      await tapIo(
        tester,
        key('backup-now'),
        until: find.text('Hoy a las 12:00'),
      );

      expect(textOf(tester, key('backup-status-title')), 'Hoy a las 12:00');
      expect(textOf(tester, key('backup-status-where')), 'En este dispositivo');
      expect(find.text('Copia hecha'), findsOneWidget); // the snack bar
      expect(key('backup-failed-title'), findsNothing);
      // One file on disk, and it is a real backup of the data.
      final names = h.filesStartingWith('cuadrante-');
      expect(names, hasLength(1));
      expect(names.single, endsWith('.cuadrante'));
      final bytes = File(p.join(h.backups.path, names.single))
          .readAsBytesSync();
      final file = const BackupCodec().decode(bytes);
      expect(file.data.calendars.map((c) => c.name), ['Mi cuadrante']);
      // ...and it is in the list.
      expect(find.textContaining('Copia del dispositivo · '), findsOneWidget);
      expect(find.text('Restaurar esta'), findsOneWidget);
      expect(key('backup-copies-empty'), findsNothing);
    });

    testWidgets('an older copy is shown as such ("Ayer a las…")', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final tools = await tester.runAsync(
        () => app.container.read(backupToolsProvider.future),
      );
      await tester.runAsync(() async {
        final bytes = await tools!.service.exportBytes();
        await tools.autoStore.save(
          bytes,
          at: harnessNow.subtract(const Duration(days: 1)),
        );
      });
      app.container.invalidate(backupCopiesProvider);
      await pumpIo(tester, until: find.text('Ayer a las 12:00'));
      expect(textOf(tester, key('backup-status-title')), 'Ayer a las 12:00');
    });
  });

  group('system backup line', () {
    for (final (state, text) in [
      (SystemBackupState.on, 'Copia del sistema de Android: activada'),
      (
        SystemBackupState.off,
        'Copia del sistema de Android: desactivada. Actívala en los ajustes '
            'de Android para tener otra copia.',
      ),
      (
        SystemBackupState.unknown,
        'Copia del sistema de Android: no podemos comprobarla desde la app. '
            'Mira en los ajustes de Android que esté activada.',
      ),
    ]) {
      testWidgets('$state', (tester) async {
        final h = BackupUiHarness(tester);
        h.channel.system = state;
        await h.open();
        await pumpIo(tester, until: key('backup-system'));
        expect(textOf(tester, key('backup-system')), text);
      });
    }

    testWidgets('not shown where there is no system backup', (tester) async {
      final h = BackupUiHarness(tester);
      await h.open();
      await pumpIo(tester);
      expect(key('backup-system'), findsNothing);
    });
  });

  group('a failed automatic copy', () {
    // The folder of copies is a FILE: nothing can be written there.
    Future<void> block(BackupUiHarness h) async {
      h.root.createSync(recursive: true);
      File(h.backups.path).writeAsStringSync('in the way');
    }

    void unblock(BackupUiHarness h) => File(h.backups.path).deleteSync();

    testWidgets('shows a status line with when it failed and that there is '
        'no good copy', (tester) async {
      final h = BackupUiHarness(tester);
      await block(h);
      final app = await h.open();

      // The user edits something; ten seconds later the copy fails.
      app.container.read(autoBackupRunnerProvider).noteChange();
      await tester.pump(const Duration(seconds: 10));
      await pumpIo(tester, until: key('backup-failed-title'));

      expect(
        textOf(tester, key('backup-failed-title')),
        'La última copia automática ha fallado',
      );
      expect(
        find.textContaining(
          'Lo intentamos hoy a las 12:00 y no se pudo guardar. Todavía no '
          'tienes ninguna copia buena.',
        ),
        findsOneWidget,
      );
      expect(
        textOf(tester, key('backup-status-title')),
        'Todavía no hay ninguna copia',
      );
      expect(app.container.read(autoBackupStatusProvider).failing, isTrue);
    });

    testWidgets('"Reintentar" works once the problem is gone, and the line '
        'goes away', (tester) async {
      final h = BackupUiHarness(tester);
      await block(h);
      final app = await h.open();
      app.container.read(autoBackupRunnerProvider).noteChange();
      await tester.pump(const Duration(seconds: 10));
      await pumpIo(tester, until: key('backup-failed-title'));

      unblock(h);
      await tapIo(
        tester,
        key('backup-failed-retry'),
        until: find.text('Hoy a las 12:00'),
      );
      expect(key('backup-failed-title'), findsNothing);
      expect(textOf(tester, key('backup-status-title')), 'Hoy a las 12:00');
      expect(h.filesStartingWith('cuadrante-'), hasLength(1));
    });

    testWidgets('mentions the last good copy when there is one', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      await tapIo(
        tester,
        key('backup-now'),
        until: find.text('Hoy a las 12:00'),
      );

      // The next copy cannot be written: a folder sits where its file goes
      // (the clock is fixed, so the second copy of the second is "-2").
      final firstCopy = h.filesStartingWith('cuadrante-').single;
      final blockedCopy = firstCopy.replaceFirst('.cuadrante', '-2.cuadrante');
      Directory(p.join(h.backups.path, blockedCopy)).createSync();
      app.container.read(autoBackupRunnerProvider).noteChange();
      // The first copy was a moment ago: the spacing makes it wait 15 min.
      await tester.pump(const Duration(minutes: 15));
      await pumpIo(tester, until: key('backup-failed-title'));

      expect(
        find.textContaining(
          'Lo intentamos hoy a las 12:00 y no se pudo guardar. Tu última '
          'copia buena es de hoy a las 12:00.',
        ),
        findsOneWidget,
      );
      // The good copy is still the one on the card.
      expect(textOf(tester, key('backup-status-title')), 'Hoy a las 12:00');
    });

    testWidgets('a failing "Hacer copia ahora" says so and keeps the data', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      await block(h);
      await h.open();
      await tapIo(
        tester,
        key('backup-now'),
        until: find.text(
          'No se ha podido hacer la copia. Tus datos siguen como estaban.',
        ),
      );
      expect(key('backup-failed-title'), findsOneWidget);
    });
  });
}
