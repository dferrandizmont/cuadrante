import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_ui_support.dart';

/// H-T13-3: «Guardar en el dispositivo» next to «Exportar archivo». The system's
/// save dialog is a fake here; the Android side (`DocumentSaver`) is plain
/// platform code that cannot run in a widget test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeLocale);

  Finder key(String k) => find.byKey(ValueKey(k));

  group('the screen', () {
    testWidgets('writes the same file «Exportar archivo» hands to the share '
        'sheet', (tester) async {
      final h = BackupUiHarness(tester);
      await h.open();

      await tapIo(tester, key('backup-export'));
      await tapIo(tester, key('backup-save'), until: find.byType(SnackBar));

      expect(h.saved, hasLength(1));
      final exported = h.shared.single;
      final saved = h.saved.single;
      expect(saved.fileName, exported.fileName);
      expect(saved.fileName, 'turnly-2026-10-19-120000.turnly');
      expect(saved.bytes, exported.bytes, reason: 'same bytes as the export');
      // And it is a real backup.
      expect(
        const BackupCodec()
            .decode(saved.bytes)
            .data
            .calendars
            .map((c) => c.name),
        ['Mi cuadrante'],
      );
      expect(find.text('Archivo guardado'), findsOneWidget);
      // Saving writes nothing in the folder of the app's own copies.
      expect(h.files, isEmpty);
    });

    testWidgets('closing the dialog does nothing: no message, no error', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      h.saveOutcome = BackupSaveOutcome.cancelled;
      await h.open();

      await tapIo(tester, key('backup-save'));
      await pumpIo(tester);

      expect(h.saved, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a place that refuses the file says so clearly', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      h.saveImpl = (bytes, name) async => throw PlatformException(
        code: 'unwritable',
        message: 'The place refused the file',
      );
      await h.open();

      await tapIo(tester, key('backup-save'), until: find.byType(SnackBar));

      expect(
        find.textContaining('No se ha podido guardar el archivo'),
        findsOneWidget,
      );
      expect(find.text('Archivo guardado'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('it sits right under «Exportar archivo»', (tester) async {
      final h = BackupUiHarness(tester);
      await h.open();
      expect(find.text('Guardar en el dispositivo'), findsOneWidget);
      expect(
        tester.getTopLeft(key('backup-save')).dy,
        greaterThan(tester.getBottomLeft(key('backup-export')).dy - 1),
      );
      expect(
        tester.getTopLeft(key('backup-import')).dy,
        greaterThan(tester.getBottomLeft(key('backup-save')).dy - 1),
      );
    });

    testWidgets('a phone without the system dialog (iOS) does not show it', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      h.saveSupported = false;
      await h.open();
      expect(key('backup-save'), findsNothing);
      expect(key('backup-export'), findsOneWidget);
    });
  });

  group('saveWithSystemDialog (the channel)', () {
    const channel = MethodChannel('test/backup-save');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];

    tearDown(() {
      calls.clear();
      messenger.setMockMethodCallHandler(channel, null);
    });

    void reply(Future<Object?> Function(MethodCall call) handler) =>
        messenger.setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          return handler(call);
        });

    test('sends the name and the bytes; «saved» is saved', () async {
      reply((_) async => 'saved');
      final bytes = Uint8List.fromList([1, 2, 3]);
      final outcome = await saveWithSystemDialog(
        bytes,
        'turnly-2026-10-19-120000.turnly',
        channel,
      );
      expect(outcome, BackupSaveOutcome.saved);
      expect(calls.single.method, 'saveDocument');
      final args = calls.single.arguments as Map<Object?, Object?>;
      expect(args['fileName'], 'turnly-2026-10-19-120000.turnly');
      expect(args['bytes'], bytes);
    });

    test('«cancelled» (or nothing) is a cancelled dialog', () async {
      reply((_) async => 'cancelled');
      expect(
        await saveWithSystemDialog(Uint8List(1), 'x.turnly', channel),
        BackupSaveOutcome.cancelled,
      );
      reply((_) async => null);
      expect(
        await saveWithSystemDialog(Uint8List(1), 'x.turnly', channel),
        BackupSaveOutcome.cancelled,
      );
    });

    test('a failure of the platform reaches the caller', () async {
      reply((_) async => throw PlatformException(code: 'unwritable'));
      await expectLater(
        saveWithSystemDialog(Uint8List(1), 'x.turnly', channel),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
