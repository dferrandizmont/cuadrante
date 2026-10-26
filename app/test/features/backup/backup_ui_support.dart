import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart'
    show runOnThisIsolate;
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../support/app_harness.dart';
import '../../support/test_storage.dart';

/// The channel to the platform, by hand: the file the system "opened" the app
/// with, the Auto Backup answer, and the way to deliver a file while the app
/// runs.
class FakeBackupChannel implements PlatformBackupChannel {
  FakeBackupChannel({
    this.incoming,
    this.system = SystemBackupState.notApplicable,
  });

  IncomingFile? incoming;
  SystemBackupState system;
  void Function()? listener;

  /// How many times Dart asked for the bytes.
  int takes = 0;

  /// How many pending files Dart dropped without reading.
  int discards = 0;

  /// Holds [takeIncomingFile] until completed: a read that is slow or stuck.
  Completer<void>? gate;

  @override
  Future<bool> hasIncomingFile() async => incoming != null;

  @override
  Future<void> discardIncomingFile() async {
    discards++;
    incoming = null;
  }

  @override
  Future<IncomingFile?> takeIncomingFile() async {
    takes++;
    final pending = gate;
    if (pending != null) await pending.future;
    final file = incoming;
    incoming = null;
    return file;
  }

  @override
  void onIncomingFile(void Function()? listener) => this.listener = listener;

  @override
  Future<SystemBackupState> systemBackupState() async => system;

  /// Every change of the tapjacking guard, in order.
  final List<bool> protection = [];

  @override
  Future<void> setPreviewProtection({required bool enabled}) async =>
      protection.add(enabled);
}

/// What the backup screens need around them: a scratch folder for the copies,
/// the share sheet and the file picker as fakes.
class BackupUiHarness {
  BackupUiHarness(this.tester)
    : root = makeTempDir('backup-ui'),
      channel = FakeBackupChannel();

  final WidgetTester tester;
  final Directory root;
  final FakeBackupChannel channel;

  /// Every file handed to the share sheet.
  final List<({Uint8List bytes, String fileName})> shared = [];

  /// Every file written with «Guardar en el dispositivo».
  final List<({Uint8List bytes, String fileName})> saved = [];

  /// What the save dialog answers.
  BackupSaveOutcome saveOutcome = BackupSaveOutcome.saved;

  /// Replace the save dialog (to make it fail).
  Future<void> Function(Uint8List bytes, String fileName)? saveImpl;

  /// Whether the phone has «Guardar en el dispositivo» (Android).
  bool saveSupported = true;

  /// What "Importar archivo" gets from the picker (`null`: cancelled).
  IncomingFile? picked;

  /// Replace the share sheet / the picker (to make them fail).
  Future<void> Function(Uint8List bytes, String fileName)? shareImpl;
  Future<IncomingFile?> Function()? pickImpl;

  Directory get backups => Directory(p.join(root.path, 'backups'));

  /// File names in the folder of copies.
  List<String> get files => backups.existsSync()
      ? ([for (final f in backups.listSync()) p.basename(f.path)]..sort())
      : <String>[];

  List<String> filesStartingWith(String prefix) => [
    for (final name in files)
      if (name.startsWith(prefix)) name,
  ];

  List<Override> get overrides => [
    // The fake clock of widget tests cannot wait on an isolate.
    backupTaskRunnerProvider.overrideWithValue(runOnThisIsolate),
    backupDirectoryProvider.overrideWith((ref) async => backups),
    backupSharerProvider.overrideWithValue((bytes, fileName) async {
      final impl = shareImpl;
      if (impl != null) return impl(bytes, fileName);
      shared.add((bytes: bytes, fileName: fileName));
    }),
    backupSaveSupportedProvider.overrideWithValue(saveSupported),
    backupFileSaverProvider.overrideWithValue((bytes, fileName) async {
      final impl = saveImpl;
      if (impl != null) await impl(bytes, fileName);
      if (saveOutcome == BackupSaveOutcome.saved) {
        saved.add((bytes: bytes, fileName: fileName));
      }
      return saveOutcome;
    }),
    backupFilePickerProvider.overrideWithValue(() async {
      final impl = pickImpl;
      return impl != null ? impl() : picked;
    }),
    platformBackupChannelProvider.overrideWithValue(channel),
  ];

  /// Settings > Copia de seguridad.
  Future<AppUnderTest> open({
    List<Override> extraOverrides = const [],
    Size size = const Size(390, 1800),
    Future<void> Function(AppDatabase database)? prepare,
  }) async {
    final app = await AppUnderTest.pump(
      tester,
      size: size,
      overrides: [...overrides, ...extraOverrides],
      prepare: prepare,
    );
    await app.openSettings();
    await tester.ensureVisible(find.byKey(const ValueKey('settings-backup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-backup')));
    await pumpIo(tester, until: find.byKey(const ValueKey('backup-status')));
    return app;
  }

  /// A `.cuadrante` of [data].
  static Uint8List fileOf(BackupData data) => const BackupCodec().encode(
    data,
    appVersion: 'test',
    exportedAt: DateTime.utc(2026, 11, 10, 9, 30),
  );
}

/// Lets real I/O (files, the database) finish and the frames that follow:
/// pumps with real pauses between until [until] shows up (or, without it,
/// for a few rounds).
Future<void> pumpIo(
  WidgetTester tester, {
  Finder? until,
  String? reason,
  int rounds = 150,
}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (until == null) {
      if (i >= 3) return;
    } else if (until.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for ${reason ?? until}');
}

/// Taps [finder] (scrolling it into view first) and lets the I/O it starts
/// finish.
Future<void> tapIo(WidgetTester tester, Finder finder, {Finder? until}) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await pumpIo(tester, until: until);
}

String? textOf(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).data;
