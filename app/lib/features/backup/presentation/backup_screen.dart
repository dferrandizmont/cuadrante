import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/diagnostics/crash_reporting.dart' show redactError;
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/auto_backup_runner.dart';
import '../application/backup_actions.dart';
import '../application/backup_models.dart';
import '../application/backup_providers.dart';
import '../data/platform_backup_channel.dart';
import '../domain/restore_summary.dart';
import 'backup_copy_list.dart';
import 'backup_format.dart';
import 'verification_result_card.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Ajustes › Copia de seguridad (`/ajustes/copia`): how safe the schedule is
/// (when and where the last copy is, honest warnings), the buttons to copy,
/// export, import and test, and the list of copies with "Restaurar esta".
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

/// The result of "Probar restauración" to show under its row.
sealed class _Check {
  const _Check();
}

class _Checking extends _Check {
  const _Checking();
}

class _CheckResult extends _Check {
  const _CheckResult(this.verification);

  /// `null`: there is no copy to test yet.
  final RestoreVerification? verification;
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _backingUp = false;
  _Check? _check;

  BackupActions get _actions => ref.read(backupActionsProvider);

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(content: Text(message)));
  }

  void _report(Object error, StackTrace stack) {
    ref
        .read(crashReporterProvider)
        .record(redactError(error), stack, fatal: false);
  }

  Future<void> _backupNow() async {
    final l10n = context.l10n;
    setState(() => _backingUp = true);
    try {
      await _actions.backupNow();
      if (mounted) _snack(l10n.backupUiBackupDone);
    } catch (_) {
      // The runner has recorded and reported it; the status card shows it.
      if (mounted) _snack(l10n.backupUiBackupFailed);
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _export() async {
    final l10n = context.l10n;
    try {
      await _actions.exportFile();
    } catch (error, stack) {
      _report(error, stack);
      if (mounted) _snack(l10n.backupUiExportFailed);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    try {
      final outcome = await _actions.saveFile();
      if (outcome == BackupSaveOutcome.saved && mounted) {
        _snack(l10n.backupUiSaveDone);
      }
    } catch (error, stack) {
      _report(error, stack);
      if (mounted) _snack(l10n.backupUiSaveFailed);
    }
  }

  Future<void> _import() async {
    final l10n = context.l10n;
    final IncomingFile? picked;
    try {
      picked = await ref.read(backupFilePickerProvider)();
    } catch (error, stack) {
      _report(error, stack);
      if (mounted) _snack(l10n.backupUiErrorUnreadable);
      return;
    }
    if (picked == null || !mounted) return;
    await context.push(
      AppRoutes.settingsBackupImport,
      extra: BackupImportRequest(
        origin: BackupImportOrigin.pickedFile,
        load: () async => picked!,
      ),
    );
  }

  Future<void> _verify() async {
    setState(() => _check = const _Checking());
    RestoreVerification? result;
    try {
      result = await _actions.verifyLatest();
    } catch (error, stack) {
      _report(error, stack);
      result = VerificationFailed(error);
    }
    if (mounted) setState(() => _check = _CheckResult(result));
  }

  Future<void> _restoreCopy(BackupCopy copy) => context.push(
    AppRoutes.settingsBackupImport,
    extra: _actions.requestFor(copy),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // A copy that finished (or a restore) changes the list.
    ref.listen<AutoBackupStatus>(autoBackupStatusProvider, (previous, next) {
      if (previous?.running == true && !next.running) {
        ref.invalidate(backupCopiesProvider);
      }
    });
    final copies = ref.watch(backupCopiesProvider);

    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(l10n.settingsBackupTitle),
      ),
      body: PageBody(
        child: SingleChildScrollView(
          // Room under the last row for a SnackBar («Copia hecha»), which would
          // otherwise sit on top of the last «Restaurar esta» with no way to
          // scroll it clear.
          padding: EdgeInsets.fromLTRB(
            Sp.page,
            Sp.s,
            Sp.page,
            MediaQuery.textScalerOf(context).scale(Sp.x4 * 2) +
                MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copies.when(
                data: (list) => _StatusSection(
                  latest: list
                      .where((c) => c.kind == BackupCopyKind.local)
                      .firstOrNull,
                  onRetry: _backingUp ? null : _backupNow,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(Sp.x3),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => ErrorState(
                  compact: true,
                  onRetry: () => ref.invalidate(backupCopiesProvider),
                ),
              ),
              const SizedBox(height: Sp.l),
              PrimaryButton(
                key: const ValueKey('backup-now'),
                label: l10n.backupUiBackupNow,
                icon: BackupIcons.save,
                loading: _backingUp,
                onPressed: _backupNow,
              ),
              const SizedBox(height: Sp.section),
              const _AutoSwitch(),
              const SizedBox(height: Sp.section),
              SettingsSection(
                title: l10n.backupUiSectionFile,
                children: [
                  SettingsRow(
                    key: const ValueKey('backup-export'),
                    icon: AppIcons.share,
                    title: l10n.backupUiExport,
                    subtitle: BackupIcons.apple
                        ? l10n.backupUiExportSubtitleIos
                        : l10n.backupUiExportSubtitle,
                    onTap: _export,
                  ),
                  if (ref.watch(backupSaveSupportedProvider))
                    SettingsRow(
                      key: const ValueKey('backup-save'),
                      icon: BackupIcons.saveToPhone,
                      title: l10n.backupUiSave,
                      subtitle: l10n.backupUiSaveSubtitle,
                      onTap: _save,
                    ),
                  SettingsRow(
                    key: const ValueKey('backup-import'),
                    icon: BackupIcons.importFile,
                    title: l10n.backupUiImport,
                    subtitle: l10n.backupUiImportSubtitle,
                    onTap: _import,
                  ),
                ],
              ),
              const SizedBox(height: Sp.section),
              SettingsSection(
                title: l10n.backupUiSectionCheck,
                children: [
                  SettingsRow(
                    key: const ValueKey('backup-verify'),
                    icon: BackupIcons.verify,
                    title: l10n.backupUiVerify,
                    subtitle: l10n.backupUiVerifySubtitle,
                    onTap: _check is _Checking ? null : _verify,
                  ),
                ],
              ),
              if (_check != null) ...[
                const SizedBox(height: Sp.m),
                _CheckView(check: _check!),
              ],
              const SizedBox(height: Sp.section),
              _CopiesSection(copies: copies, onRestore: _restoreCopy),
            ],
          ),
        ),
      ),
    );
  }
}

/// The status card, the failure line and the system backup line.
class _StatusSection extends ConsumerWidget {
  const _StatusSection({required this.latest, required this.onRetry});

  /// The newest copy of the app on the phone, or `null` if there is none.
  final BackupCopy? latest;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final status = ref.watch(autoBackupStatusProvider);
    final system =
        ref.watch(systemBackupStateProvider).value ??
        SystemBackupState.notApplicable;
    final now = ref.watch(clockProvider)();
    final latestAt = latest?.entry.modifiedAt;

    final String? progress = status.running
        ? l10n.backupUiStatusRunning
        : status.pending
        ? pendingCopyMessage(l10n, status, now)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          key: const ValueKey('backup-status'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: Disc.l,
                      height: Disc.l,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: latest == null
                            ? colors.dangerContainer
                            : colors.successContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        latest == null ? BackupIcons.warning : AppIcons.check,
                        size: IconSize.base,
                        color: latest == null ? colors.danger : colors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.m),
                  Expanded(
                    child: latest == null
                        ? Text(
                            l10n.backupUiStatusNoneTitle,
                            key: const ValueKey('backup-status-title'),
                            style: type.bodyStrong,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.backupUiStatusLast.toUpperCase(),
                                style: type.label.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                              Text(
                                sentenceCase(backupWhen(l10n, latestAt!, now)),
                                key: const ValueKey('backup-status-title'),
                                style: type.bodyStrong,
                              ),
                              Text(
                                l10n.backupUiStatusWhere,
                                key: const ValueKey('backup-status-where'),
                                style: type.body.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              if (latest == null) ...[
                const SizedBox(height: Sp.s),
                Text(
                  l10n.backupUiStatusNoneBody,
                  style: type.body.copyWith(color: colors.textSecondary),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: Sp.s),
                Text(
                  progress,
                  key: const ValueKey('backup-status-progress'),
                  style: type.meta.copyWith(color: colors.textMuted),
                ),
              ],
              if (system != SystemBackupState.notApplicable) ...[
                const SizedBox(height: Sp.m),
                Text(
                  switch (system) {
                    SystemBackupState.on => l10n.backupUiSystemOn,
                    SystemBackupState.off => l10n.backupUiSystemOff,
                    _ => l10n.backupUiSystemUnknown,
                  },
                  key: const ValueKey('backup-system'),
                  style: type.meta.copyWith(color: colors.textSecondary),
                ),
              ],
              const SizedBox(height: Sp.m),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: Sp.hair),
                    child: Icon(
                      BackupIcons.warning,
                      size: IconSize.inline,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(width: Sp.s),
                  Expanded(
                    child: Text(
                      BackupIcons.apple
                          ? l10n.backupUiWarningIos
                          : l10n.backupUiWarning,
                      key: const ValueKey('backup-warning'),
                      style: type.meta.copyWith(color: colors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (status.failing) ...[
          const SizedBox(height: Sp.card),
          AppCallout(
            icon: BackupIcons.warning,
            tone: TonePair(colors.dangerContainer, colors.danger),
            titleKey: const ValueKey('backup-failed-title'),
            title: l10n.backupUiStatusFailedTitle,
            message: _failureMessage(l10n, status, latestAt, now),
            primaryKey: const ValueKey('backup-failed-retry'),
            primaryLabel: l10n.backupUiRetry,
            onPrimary: onRetry,
          ),
        ],
      ],
    );
  }

  String _failureMessage(
    AppLocalizations l10n,
    AutoBackupStatus status,
    DateTime? latestAt,
    DateTime now,
  ) {
    final when = backupWhen(l10n, status.lastFailureAt ?? now, now);
    final story = latestAt == null
        ? l10n.backupUiStatusFailedNoGood(when)
        : l10n.backupUiStatusFailedWithGood(
            when,
            backupWhen(l10n, latestAt, now),
          );
    return '$story ${backupFailureReason(l10n, status.lastError)}';
  }
}

class _AutoSwitch extends ConsumerWidget {
  const _AutoSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(autoBackupEnabledProvider).value ?? true;
    return SettingsSection(
      children: [
        SettingsSwitchRow(
          key: const ValueKey('backup-auto-row'),
          icon: BackupIcons.auto,
          title: l10n.backupUiAutoTitle,
          subtitle: enabled ? l10n.backupUiAutoOn : l10n.backupUiAutoOff,
          value: enabled,
          switchKey: const ValueKey('backup-auto-switch'),
          onChanged: (value) => saveSetting(
            context,
            () => ref.read(autoBackupEnabledProvider.notifier).set(value),
          ),
        ),
      ],
    );
  }
}

/// The outcome of "Probar restauración" (or its progress) under its row.
class _CheckView extends StatelessWidget {
  const _CheckView({required this.check});

  final _Check check;

  @override
  Widget build(BuildContext context) => switch (check) {
    _Checking() => AppCallout(
      key: VerificationResultCard.cardKey,
      icon: BackupIcons.verify,
      title: context.l10n.backupUiVerifyRunning,
    ),
    _CheckResult(:final verification) => VerificationResultCard(
      result: verification,
    ),
  };
}

class _CopiesSection extends ConsumerWidget {
  const _CopiesSection({required this.copies, required this.onRestore});

  final AsyncValue<List<BackupCopy>> copies;
  final Future<void> Function(BackupCopy copy) onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final now = ref.watch(clockProvider)();
    final list = copies.value;
    if (list == null) return const SizedBox.shrink();

    if (list.isEmpty) {
      return SettingsSection(
        title: l10n.backupUiSectionCopies,
        children: [
          Padding(
            padding: const EdgeInsets.all(Sp.l),
            child: Text(
              l10n.backupUiCopiesEmpty,
              key: const ValueKey('backup-copies-empty'),
              style: context.type.body.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      );
    }
    return BackupCopyList(copies: list, now: now, onRestore: onRestore);
  }
}
