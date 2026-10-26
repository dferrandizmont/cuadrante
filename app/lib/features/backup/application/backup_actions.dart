import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../schedule/domain/civil_date.dart';
import '../data/platform_backup_channel.dart';
import '../domain/backup_codec.dart';
import '../domain/backup_store.dart';
import '../domain/icloud_errors.dart';
import '../domain/restore_summary.dart';
import 'backup_models.dart';
import 'backup_providers.dart';
import 'backup_service.dart';
import 'restore_coordinator.dart';

/// What the backup screens do, in one place so the widgets only call and
/// show. Every restore goes through `RestoreCoordinator.restoreAndReload`.
class BackupActions {
  BackupActions(this._ref);

  final Ref _ref;

  Future<BackupTools> get _tools => _ref.read(backupToolsProvider.future);

  /// "Hacer copia ahora". Throws if the copy could not be stored (the runner
  /// has recorded and reported it).
  Future<BackupEntry> backupNow() async {
    try {
      return await _ref.read(autoBackupRunnerProvider).backupNow();
    } finally {
      _ref.invalidate(backupCopiesProvider);
    }
  }

  /// "Exportar archivo": the current data as a `.cuadrante`, checked by
  /// reading it back, handed to the share sheet.
  Future<void> exportFile() async {
    final tools = await _tools;
    final bytes = await tools.service.exportBytes();
    await tools.service.decodeFile(bytes, codec: tools.codec);
    await _ref.read(backupSharerProvider)(
      bytes,
      exportFileName(_ref.read(clockProvider)()),
    );
  }

  /// "Guardar en el móvil": the same file as [exportFile] (same bytes, same
  /// name, read back first), written where the user picks in the system's
  /// save dialog. Throws if it could not be written; a closed dialog is
  /// [BackupSaveOutcome.cancelled], not an error.
  Future<BackupSaveOutcome> saveFile() async {
    final tools = await _tools;
    final bytes = await tools.service.exportBytes();
    await tools.service.decodeFile(bytes, codec: tools.codec);
    return _ref.read(backupFileSaverProvider)(
      bytes,
      exportFileName(_ref.read(clockProvider)()),
    );
  }

  /// "Probar restauración" on the newest copy of the app; `null` when there
  /// is none yet.
  Future<RestoreVerification?> verifyLatest() async {
    final tools = await _tools;
    return tools.service.verifyLatest(
      today: CivilDate.fromDateTime(_ref.read(clockProvider)()),
    );
  }

  /// Reads [bytes] (nothing is written): throws a `BackupException` if they
  /// are not a usable backup.
  Future<PendingRestore> inspect(Uint8List bytes) async =>
      (await _tools).service.inspect(bytes);

  /// Replaces the current data with [pending] and brings every screen back in
  /// step. Throws a [RestoreFailure]: with `dataReplaced == false` nothing
  /// changed.
  Future<void> restore(PendingRestore pending) async {
    final tools = await _tools;
    final base = RestoreCoordinator.fromRef(_ref, tools.service);
    var replaced = false;
    final coordinator = RestoreCoordinator(
      runExclusive: base.runExclusive,
      restore: (pending) async {
        await base.restore(pending);
        replaced = true;
      },
      reloadSchedule: base.reloadSchedule,
      reloadHolidays: base.reloadHolidays,
      reloadCalendars: base.reloadCalendars,
      reloadPostNight: base.reloadPostNight,
      resyncAlarms: base.resyncAlarms,
      resyncWidget: base.resyncWidget,
      markOnboardingDone: base.markOnboardingDone,
      reloadOnboardingTip: base.reloadOnboardingTip,
    );
    try {
      await coordinator.restoreAndReload(pending);
    } catch (error) {
      throw RestoreFailure(dataReplaced: replaced, cause: error);
    } finally {
      _ref.invalidate(backupCopiesProvider);
      // The switch of the automatic copies travels in the backup too.
      _ref.invalidate(autoBackupEnabledProvider);
    }
  }

  /// The newest copy made right before a restore, or `null`.
  Future<BackupCopy?> latestSafetyCopy() async {
    final entry = await (await _tools).safetyStore.latest();
    return entry == null ? null : BackupCopy(BackupCopyKind.safety, entry);
  }

  /// A request to preview a stored copy.
  BackupImportRequest requestFor(BackupCopy copy) => BackupImportRequest(
    origin: copy.kind == BackupCopyKind.safety
        ? BackupImportOrigin.safetyCopy
        : BackupImportOrigin.localCopy,
    copyDate: copy.entry.modifiedAt,
    load: () async => IncomingFile.bytes(await (await _tools).read(copy)),
  );

  /// A request to preview a copy found in iCloud ([BackupTools.cloudCopies]).
  /// Never a direct restore: the file is an external one (it travels through
  /// the same decoder in an isolate, the same preview, the same `pre-restore`
  /// copy and the same confirmation as a file the user picked). Its date comes
  /// from the file name and can be false.
  BackupImportRequest requestForCloud(BackupEntry entry) => BackupImportRequest(
    origin: BackupImportOrigin.cloudCopy,
    copyDate: entry.modifiedAt,
    load: () async {
      if (entry.sizeBytes > BackupCodec.maxFileBytes) {
        return const IncomingFile.problem(IncomingFileProblem.tooLarge);
      }
      try {
        return IncomingFile.bytes(await (await _tools).readCloud(entry));
      } on ICloudException {
        return const IncomingFile.problem(IncomingFileProblem.unreadable);
      }
    },
  );
}

final backupActionsProvider = Provider<BackupActions>(BackupActions.new);
