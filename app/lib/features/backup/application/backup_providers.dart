import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart'
    show ResultSetImplementation, TableUpdateQuery;
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_opener.dart' show backupsDirectoryName;
import '../../../core/database/database_provider.dart';
import '../../../core/diagnostics/crash_reporting.dart' show redactError;
import '../../../core/providers.dart';
import '../data/backup_repository.dart';
import '../data/backup_settings_repository.dart';
import '../data/export_cache.dart';
import '../data/icloud_backup_store.dart';
import '../data/local_file_backup_store.dart';
import '../data/platform_backup_channel.dart';
import '../domain/auto_backup_policy.dart';
import '../domain/backup_codec.dart';
import '../domain/backup_retention.dart';
import '../domain/backup_store.dart';
import '../domain/icloud_errors.dart';
import 'auto_backup_runner.dart';
import 'backup_models.dart';
import 'backup_service.dart';

// ---- where things live --------------------------------------------------

/// Whether the copies are replicated to iCloud Drive at all. **`false` until
/// question 13 of `docs/preguntas.md` is answered** (the replica would carry
/// every shift and absence, sick leave included, to a folder visible in Files
/// on every device of the Apple ID, not end-to-end encrypted without Advanced
/// Data Protection). While it is `false`, [iCloudBackupStoreProvider] gives
/// `null` whatever the user's switch says, so registering the Swift channel
/// activates nothing. Turn it on only with the answer to question 13 (option
/// (a): the mirrored bytes must be a re-encode of `BackupData` without health
/// absences, never the local bytes) and the "Copia en iCloud" switch in
/// Ajustes.
const bool kICloudReplica = false;

/// `<Application Support>/backups`: the automatic copies, the safety copies
/// of the restores and the pre-migration database copies. Tests override it
/// with a temporary folder. (On Android Application Support is `files/`, which
/// the system backup includes: docs/copia-de-seguridad.md.)
final backupDirectoryProvider = FutureProvider<Directory>((ref) async {
  final support = await getApplicationSupportDirectory();
  return Directory(p.join(support.path, backupsDirectoryName));
});

/// The files of the copies and the operations on them.
class BackupTools {
  BackupTools({
    required this.directory,
    required this.service,
    required this.autoStore,
    required this.safetyStore,
    this.cloudStore,
    this.cloudEnabled = _cloudOff,
    this.codec = const BackupCodec(),
  });

  static Future<bool> _cloudOff() async => false;

  final Directory directory;
  final BackupService service;

  /// `cuadrante-<stamp>.cuadrante`: the copies of the app, with the retention
  /// policy. Always on the phone, and always the first place: a copy exists
  /// here before it is sent anywhere.
  final LocalFileBackupStore autoStore;

  /// `pre-restore-<stamp>.cuadrante`: written by `BackupRepository.restore`.
  /// Local only, never in iCloud.
  final LocalFileBackupStore safetyStore;

  /// The second place of the app's copies: the iCloud container, on iOS only
  /// and only with the user's opt-in (`null` otherwise). Each good local copy
  /// is mirrored to it while [cloudEnabled] says yes; see [backupAndVerify].
  final ICloudBackupStore? cloudStore;

  /// Whether the "Copia en iCloud" switch is on **right now**: asked again
  /// before every mirror, so switching it off stops the very next copy. The
  /// default is off: a store alone never sends anything to iCloud.
  final Future<bool> Function() cloudEnabled;
  final BackupCodec codec;

  /// Why the last mirror to iCloud failed, or `null` when it worked or there
  /// was nothing to do (no iCloud store, nothing copied yet). The backup
  /// screen shows it with the date of the last good copy (matrix row R8).
  ICloudException? cloudError;

  /// The copies in iCloud, newest first; empty when there is no iCloud or it
  /// cannot be asked. After a reinstall or on a new iPhone this is where
  /// "Restaurar" finds the copy (matrix row R1).
  Future<List<BackupEntry>> cloudCopies() async =>
      await cloudStore?.list() ?? const [];

  /// The bytes of a copy in iCloud ([cloudCopies]).
  Future<Uint8List> readCloud(BackupEntry entry) async {
    final cloud = cloudStore;
    if (cloud == null) throw const ICloudUnavailable();
    return cloud.read(entry);
  }

  /// Every copy on the phone, newest first.
  Future<List<BackupCopy>> copies() async {
    final local = await autoStore.list();
    final safety = await safetyStore.list();
    return [
      for (final e in local)
        BackupCopy(
          BackupCopyKind.local,
          e,
          appVersion: await _versionOf(autoStore, 'local', e),
        ),
      for (final e in safety)
        BackupCopy(
          BackupCopyKind.safety,
          e,
          appVersion: await _versionOf(safetyStore, 'safety', e),
        ),
    ]..sort((a, b) => b.entry.modifiedAt.compareTo(a.entry.modifiedAt));
  }

  /// Version of the app that wrote each copy, by file (a copy never changes
  /// once written, so it is read once): `null` is cached too.
  final Map<String, String?> _versions = {};

  Future<String?> _versionOf(
    LocalFileBackupStore store,
    String kind,
    BackupEntry entry,
  ) async {
    final key = '$kind/${entry.id}/${entry.sizeBytes}';
    if (_versions.containsKey(key)) return _versions[key];
    String? version;
    try {
      version = BackupCodec.peekAppVersion(
        await store.readHead(entry, BackupCodec.peekCompressedBytes),
      );
    } catch (_) {
      // Unreadable now: the copy is listed without a version.
      version = null;
    }
    return _versions[key] = version;
  }

  Future<Uint8List> read(BackupCopy copy) => switch (copy.kind) {
    BackupCopyKind.local => autoStore.read(copy.entry),
    BackupCopyKind.safety => safetyStore.read(copy.entry),
  };

  /// Takes a copy and reads it back from disk: a file that cannot be decoded
  /// again is deleted and reported as a failure, so a bad copy never looks
  /// like a good one.
  ///
  /// A copy that verifies is then mirrored to iCloud when there is an iCloud
  /// store ([cloudStore]) and the user has the switch on ([cloudEnabled]):
  /// best effort. iCloud off, full or slow never fails
  /// the backup (the copy is already on the phone); it is left in
  /// [cloudError].
  Future<BackupEntry> backupAndVerify() async {
    final entry = await service.backupNow();
    final Uint8List bytes;
    try {
      bytes = await autoStore.read(entry);
      await service.decodeFile(bytes, codec: codec);
    } catch (_) {
      try {
        await autoStore.delete(entry);
      } catch (_) {
        // Nothing more can be done with it.
      }
      rethrow;
    }
    // Only now that the new copy is known to be good do the old ones go.
    try {
      await autoStore.prune();
    } catch (_) {
      // Left for the next copy; the new one is saved.
    }
    await _mirrorToCloud(entry, bytes);
    return entry;
  }

  Future<void> _mirrorToCloud(BackupEntry entry, Uint8List bytes) async {
    final cloud = cloudStore;
    if (cloud == null) return;
    // The switch is read again for every copy: off means this one stays on
    // the phone. A switch that cannot be read counts as off.
    try {
      if (!await cloudEnabled()) return;
    } catch (_) {
      return;
    }
    try {
      // The same moment as the local copy, so both places name it alike.
      await cloud.save(bytes, at: entry.modifiedAt);
      cloudError = null;
    } on ICloudException catch (e) {
      cloudError = e;
      return;
    } catch (e) {
      cloudError = ICloudFailed('$e');
      return;
    }
    try {
      await cloud.prune();
    } catch (_) {
      // Old copies stay until the next time; the new one is saved.
    }
  }
}

/// The version written into the copies ("dev" in a development build).
String backupAppVersion(String configured) =>
    configured.isEmpty ? 'dev' : configured;

/// Where a file being previewed is decoded: an isolate in the app. Widget
/// tests (fake clock) override it with `runOnThisIsolate`.
final backupTaskRunnerProvider = Provider<BackupTaskRunner>(
  (ref) => runInBackgroundIsolate,
);

/// Whether this build may replicate to iCloud at all. Always `false` until
/// `kICloudReplica` is switched on; tests override it (a `const` cannot change).
final iCloudReplicaBuiltInProvider = Provider<bool>((ref) => kICloudReplica);

/// Whether the phone runs iOS (the only system with an iCloud container).
/// Tests override it.
final iCloudPlatformProvider = Provider<bool>((ref) => Platform.isIOS);

/// The "Copia en iCloud" switch of Ajustes (off unless the user turned it on).
/// There is no UI for it yet (docs/copia-de-seguridad.md, "Dónde va iCloud").
class CloudBackupEnabled extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      BackupSettingsRepository(ref.watch(appDatabaseProvider)).loadCloud();

  Future<void> set(bool value) async {
    await BackupSettingsRepository(ref.read(appDatabaseProvider))
        .saveCloud(value);
    state = AsyncData(value);
  }
}

final cloudBackupEnabledProvider =
    AsyncNotifierProvider<CloudBackupEnabled, bool>(CloudBackupEnabled.new);

/// The iCloud container as a second place for the app's copies: iOS only, and
/// only when this build has the replica ([kICloudReplica]) **and** the user
/// turned "Copia en iCloud" on (`null` otherwise: Android, desktop, tests,
/// which override it with a fake channel). It keeps what the local copies keep
/// (`BackupRetention`). Until the Swift channel exists (Mac phase) every call
/// says "iCloud no disponible" and nothing changes.
final iCloudBackupStoreProvider = Provider<ICloudBackupStore?>((ref) {
  if (!ref.watch(iCloudReplicaBuiltInProvider)) return null;
  if (!ref.watch(iCloudPlatformProvider)) return null;
  if (!(ref.watch(cloudBackupEnabledProvider).value ?? false)) return null;
  final clock = ref.watch(clockProvider);
  const retention = BackupRetention();
  return ICloudBackupStore(
    retain: (entries) => retention.idsToKeep(entries, now: clock()),
    pruneOnSave: false,
    now: clock,
  );
});

final backupToolsProvider = FutureProvider<BackupTools>((ref) async {
  final directory = await ref.watch(backupDirectoryProvider.future);
  final db = ref.watch(appDatabaseProvider);
  final clock = ref.watch(clockProvider);
  final version = backupAppVersion(ref.watch(appConfigProvider).appVersion);
  const retention = BackupRetention();
  final autoStore = LocalFileBackupStore(
    directory,
    retain: (entries) => retention.idsToKeep(entries, now: clock()),
    pruneOnSave: false,
  );
  return BackupTools(
    directory: directory,
    autoStore: autoStore,
    cloudStore: ref.watch(iCloudBackupStoreProvider),
    cloudEnabled: () => BackupSettingsRepository(db).loadCloud(),
    safetyStore: LocalFileBackupStore(directory, prefix: 'pre-restore'),
    service: BackupService(
      repository: BackupRepository(
        db,
        safetyDirectory: directory,
        appVersion: version,
        runner: ref.watch(backupTaskRunnerProvider),
        now: clock,
      ),
      store: autoStore,
      appVersion: version,
      runner: ref.watch(backupTaskRunnerProvider),
      now: clock,
    ),
  );
});

/// Every copy on the phone, newest first. Invalidate it after anything that
/// adds or removes a copy.
final backupCopiesProvider = FutureProvider.autoDispose<List<BackupCopy>>(
  (ref) async => (await ref.watch(backupToolsProvider.future)).copies(),
);

// ---- automatic copies ---------------------------------------------------

/// The timing rules of the automatic copies. Integration tests shorten them.
final autoBackupPolicyProvider = Provider<AutoBackupPolicy>(
  (ref) => const AutoBackupPolicy(),
);

/// The "Copias automáticas" switch (on unless the user turned it off).
class AutoBackupEnabled extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      BackupSettingsRepository(ref.watch(appDatabaseProvider)).loadAuto();

  Future<void> set(bool value) async {
    await BackupSettingsRepository(ref.read(appDatabaseProvider))
        .saveAuto(value);
    state = AsyncData(value);
  }
}

final autoBackupEnabledProvider =
    AsyncNotifierProvider<AutoBackupEnabled, bool>(AutoBackupEnabled.new);

class AutoBackupStatusNotifier extends Notifier<AutoBackupStatus> {
  @override
  AutoBackupStatus build() => const AutoBackupStatus();

  // ignore: use_setters_to_change_properties
  void publish(AutoBackupStatus status) => state = status;
}

/// How the automatic copies are going (this session).
final autoBackupStatusProvider =
    NotifierProvider<AutoBackupStatusNotifier, AutoBackupStatus>(
      AutoBackupStatusNotifier.new,
    );

/// Watches the user's tables and takes a copy after changes. The host keeps it
/// alive for the whole life of the app; it needs nothing from the UI.
final autoBackupRunnerProvider = Provider<AutoBackupRunner>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final reporter = ref.watch(crashReporterProvider);
  final runner = AutoBackupRunner(
    policy: ref.watch(autoBackupPolicyProvider),
    now: ref.watch(clockProvider),
    perform: () async =>
        (await ref.read(backupToolsProvider.future)).backupAndVerify(),
    onStatus: (status) =>
        ref.read(autoBackupStatusProvider.notifier).publish(status),
    onFailure: (error, stack) => unawaited(
      reporter
          .record(redactError(error), stack, fatal: false)
          .catchError((_) {}),
    ),
  );
  final changes = db
      .tableUpdates(TableUpdateQuery.onAllTables(_userTables(db)))
      .listen((_) => runner.noteChange());
  ref.listen<AsyncValue<bool>>(autoBackupEnabledProvider, (_, next) {
    runner.enabled = next.value ?? true;
  }, fireImmediately: true);
  ref.onDispose(() {
    unawaited(changes.cancel());
    runner.dispose();
  });
  return runner;
});

/// Every table whose rows a backup carries (holidays: the user's own; the
/// derived ones change rarely and cost one cheap copy).
List<ResultSetImplementation<dynamic, dynamic>> _userTables(AppDatabase db) => [
  db.calendars,
  db.shiftTypes,
  db.patterns,
  db.patternRuns,
  db.dayEntries,
  db.holidays,
  db.absenceBalances,
  db.settings,
];

// ---- the platform -------------------------------------------------------

/// `true` while a restore is replacing the data: the host then leaves a file
/// that arrives alone instead of swapping the preview under it.
class RestoreInProgress extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;
}

final restoreInProgressProvider = NotifierProvider<RestoreInProgress, bool>(
  RestoreInProgress.new,
);

final platformBackupChannelProvider = Provider<PlatformBackupChannel>(
  (ref) => defaultPlatformBackupChannel(),
);

/// The tapjacking guard of the restore preview, reference-counted so that a
/// preview replacing another never leaves it off.
final previewProtectionGuardProvider = Provider<PreviewProtectionGuard>(
  (ref) => PreviewProtectionGuard(ref.watch(platformBackupChannelProvider)),
);

/// Whether the phone's own backup is on (see [SystemBackupState]).
final systemBackupStateProvider = FutureProvider.autoDispose<SystemBackupState>(
  (ref) => ref.watch(platformBackupChannelProvider).systemBackupState(),
);

/// Hands an exported file to the system share sheet (WhatsApp, Drive, mail).
/// Tests override it.
typedef BackupSharer = Future<void> Function(Uint8List bytes, String fileName);

/// Writes an exported file where the user chooses with the system's save
/// dialog. Tests override it.
typedef BackupFileSaver = Future<BackupSaveOutcome> Function(
  Uint8List bytes,
  String fileName,
);

final backupFileSaverProvider = Provider<BackupFileSaver>(
  (ref) => saveWithSystemDialog,
);

/// Whether this phone has «Guardar en el móvil»: Android only. On iOS the
/// share sheet already offers «Guardar en Archivos»; the native save dialog
/// (`UIDocumentPickerViewController` for exporting) is a Mac-phase task, see
/// docs/mac-ios.md. Tests override it.
final backupSaveSupportedProvider = Provider<bool>((ref) => Platform.isAndroid);

/// The cache folder for exported files (`<cache>/export/`), see
/// [ExportCache]. Tests override it with a temporary folder.
final exportCacheProvider = FutureProvider<ExportCache>(
  (ref) async => ExportCache(await getTemporaryDirectory()),
);

/// Empties the export folder: files of an earlier export that nobody deleted.
/// Reading it once at start (the host does) runs it. Never fails.
final exportCacheSweepProvider = FutureProvider<void>((ref) async {
  try {
    await (await ref.watch(exportCacheProvider.future)).sweep();
  } catch (_) {
    // Housekeeping only.
  }
});

/// Opens the system share sheet for an exported file. Tests override it.
typedef ExportFileSender = Future<void> Function(File file);

Future<void> _shareWithSystem(File file) => SharePlus.instance.share(
  ShareParams(files: [XFile(file.path, mimeType: 'application/octet-stream')]),
);

final exportFileSenderProvider = Provider<ExportFileSender>(
  (ref) => _shareWithSystem,
);

/// Writes the file to `<cache>/export/`, opens the share sheet and deletes
/// the file once it has returned. Nothing leaves the phone unless the user
/// picks where it goes. Always through the one [exportCacheProvider] instance:
/// a second export cancels the delayed delete of the first.
final backupSharerProvider = Provider<BackupSharer>(
  (ref) => (bytes, fileName) async {
    final cache = await ref.read(exportCacheProvider.future);
    await cache.share(bytes, fileName, ref.read(exportFileSenderProvider));
  },
);

/// Asks the user for a file. `null` when they cancel. Tests override it.
typedef BackupFilePicker = Future<IncomingFile?> Function();

/// The system file picker. On Android no type filter is passed: the
/// extension `.cuadrante` has no MIME type there, and a filter could hide the
/// very file the user wants; the content is validated anyway. On iOS the
/// picker only takes type identifiers (extensions alone make it throw): any
/// data file, for the same reason; the app's own type (`app.cuadrante.backup`,
/// declared in Info.plist) is one of them.
Future<IncomingFile?> pickBackupFile() async {
  final groups = Platform.isAndroid
      ? const <XTypeGroup>[]
      : Platform.isIOS
      ? const [
          XTypeGroup(
            label: 'Cuadrante',
            uniformTypeIdentifiers: ['public.data'],
          ),
        ]
      : const [
          XTypeGroup(label: 'Cuadrante', extensions: ['cuadrante']),
        ];
  final file = await openFile(acceptedTypeGroups: groups);
  if (file == null) return null;
  try {
    if (await file.length() > BackupCodec.maxFileBytes) {
      return const IncomingFile.problem(IncomingFileProblem.tooLarge);
    }
    return IncomingFile.bytes(await file.readAsBytes());
  } catch (_) {
    return const IncomingFile.problem(IncomingFileProblem.unreadable);
  }
}

final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => pickBackupFile,
);
