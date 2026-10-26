import 'dart:async';

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
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../application/backup_actions.dart';
import '../application/backup_models.dart';
import '../application/backup_providers.dart';
import '../application/backup_service.dart';
import '../data/platform_backup_channel.dart';
import '../domain/backup_errors.dart';
import 'backup_format.dart';

/// What the preview screen is doing.
enum _Phase { reading, ready, restoring, done, unusable, failed }

/// Shows what a `.cuadrante` (a file the user picked, one another app opened
/// with Cuadrante, or a copy of the phone) would restore, and replaces the
/// current data only when the user confirms. Nothing is written before that;
/// an unusable file ends here with a clear message and the data untouched.
class RestorePreviewScreen extends ConsumerStatefulWidget {
  const RestorePreviewScreen({super.key, required this.request});

  final BackupImportRequest request;

  @override
  ConsumerState<RestorePreviewScreen> createState() =>
      _RestorePreviewScreenState();
}

class _RestorePreviewScreenState extends ConsumerState<RestorePreviewScreen> {
  _Phase _phase = _Phase.reading;
  PendingRestore? _pending;

  /// Why the file is unusable ([BackupException], an `IncomingFileProblem` or
  /// an I/O error).
  Object? _problem;
  RestoreFailure? _failure;
  bool _hasSafetyCopy = false;

  /// Who handed the file over (informational), when the system said.
  String? _sender;

  late final PreviewProtectionGuard _guard;

  BackupActions get _actions => ref.read(backupActionsProvider);

  @override
  void initState() {
    super.initState();
    // Tapjacking guard for as long as the preview (and its confirm button) is
    // on screen: another app's overlay must not pass a tap through.
    // Reference-counted: a preview that replaces this one builds before this
    // one is disposed, and the guard must stay on across the swap.
    _guard = ref.read(previewProtectionGuardProvider)..acquire();
    _read();
  }

  @override
  void dispose() {
    _guard.release();
    super.dispose();
  }

  Future<void> _read() async {
    try {
      final file = await widget.request.load();
      final problem = file.problem;
      if (problem != null) {
        _fail(problem);
        return;
      }
      // The user may have left while the file was being read.
      if (!mounted) return;
      _sender = file.sender;
      final pending = await _actions.inspect(file.bytes!);
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _phase = _Phase.ready;
      });
    } on BackupException catch (error) {
      _fail(error);
    } catch (error, stack) {
      ref
          .read(crashReporterProvider)
          .record(redactError(error), stack, fatal: false);
      _fail(error);
    }
  }

  void _fail(Object problem) {
    if (!mounted) return;
    setState(() {
      _problem = problem;
      _phase = _Phase.unusable;
    });
  }

  Future<void> _confirm() async {
    final pending = _pending;
    if (pending == null || _phase != _Phase.ready) return;
    setState(() => _phase = _Phase.restoring);
    // Held before the awaits: the screen cannot be replaced meanwhile.
    final inProgress = ref.read(restoreInProgressProvider.notifier)..set(true);
    try {
      await _actions.restore(pending);
      BackupCopy? safety;
      try {
        safety = await _actions.latestSafetyCopy();
      } catch (_) {
        // Only the "volver a como estaba" shortcut depends on it; the copy is
        // still in the list of copies.
      }
      if (!mounted) return;
      setState(() {
        _hasSafetyCopy = safety != null;
        _phase = _Phase.done;
      });
    } on RestoreFailure catch (failure, stack) {
      ref
          .read(crashReporterProvider)
          .record(redactError(failure.cause), stack, fatal: false);
      if (!mounted) return;
      setState(() {
        _failure = failure;
        _phase = _Phase.failed;
      });
    } finally {
      inProgress.set(false);
    }
  }

  Future<void> _undo() async {
    final safety = await _actions.latestSafetyCopy();
    if (safety == null || !mounted) return;
    context.pushReplacement(
      AppRoutes.settingsBackupImport,
      extra: _actions.requestFor(safety),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final restoring = _phase == _Phase.restoring;
    return PopScope(
      // Not while the data is being replaced.
      canPop: !restoring,
      child: Scaffold(
        appBar: ContentAppBar.adaptive(
          context,
          title: Text(l10n.backupUiPreviewTitle),
        ),
        body: Stack(
          children: [
            PageBody(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Sp.page,
                  Sp.s,
                  Sp.page,
                  Sp.x3,
                ),
                child: _content(context),
              ),
            ),
            if (restoring) const _RestoringOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    switch (_phase) {
      case _Phase.reading:
        return Padding(
          key: const ValueKey('restore-reading'),
          padding: const EdgeInsets.all(Sp.x4),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Sp.l),
              Text(l10n.backupUiPreviewReading),
            ],
          ),
        );
      case _Phase.ready:
      case _Phase.restoring:
        return _Preview(
          request: widget.request,
          pending: _pending!,
          sender: _sender,
          onConfirm: _phase == _Phase.ready ? _confirm : null,
          onCancel: () => context.pop(),
        );
      case _Phase.unusable:
        return _Centered(
          child: EmptyState(
            key: const ValueKey('restore-unusable'),
            icon: AppIcons.error,
            title: backupErrorMessage(l10n, _problem!),
            message: l10n.backupUiErrorUntouched,
            actionLabel: l10n.backupUiBack,
            onAction: () => context.pop(),
            primaryAction: true,
          ),
        );
      case _Phase.failed:
        final reload = _failure?.dataReplaced ?? false;
        return _Centered(
          child: EmptyState(
            key: const ValueKey('restore-failed'),
            icon: AppIcons.error,
            title: reload
                ? l10n.backupUiErrorRestoreReload
                : l10n.backupUiErrorRestoreFailed,
            actionLabel: l10n.backupUiBack,
            onAction: () => context.pop(),
            primaryAction: true,
          ),
        );
      case _Phase.done:
        return _Centered(
          child: EmptyState(
            key: const ValueKey('restore-done'),
            icon: AppIcons.check,
            title: l10n.backupUiDoneTitle,
            message: l10n.backupUiDoneBody,
            actionLabel: l10n.backupUiDoneView,
            primaryAction: true,
            onAction: () => context.go(AppRoutes.home),
            secondaryLabel: _hasSafetyCopy ? l10n.backupUiDoneUndo : null,
            onSecondary: _hasSafetyCopy ? _undo : null,
          ),
        );
    }
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Sp.x4),
    child: child,
  );
}

/// Blocks the screen while the restore runs.
class _RestoringOverlay extends StatelessWidget {
  const _RestoringOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    return Positioned.fill(
      key: const ValueKey('restore-progress'),
      child: Stack(
        children: [
          ModalBarrier(color: colors.scrim, dismissible: false),
          Center(
            child: Semantics(
              liveRegion: true,
              child: AppCard(
                padding: const EdgeInsets.all(Sp.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: Sp.l),
                    Text(l10n.backupUiRestoring, style: type.bodyStrong),
                    const SizedBox(height: Sp.xs),
                    Text(
                      l10n.backupUiRestoringHint,
                      style: type.body.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The contents of the file next to what the phone holds now, and the
/// confirmation.
class _Preview extends ConsumerWidget {
  const _Preview({
    required this.request,
    required this.pending,
    required this.sender,
    required this.onConfirm,
    required this.onCancel,
  });

  final BackupImportRequest request;
  final PendingRestore pending;
  final String? sender;
  final VoidCallback? onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final now = ref.watch(clockProvider)();
    final file = pending.file;
    final incoming = pending.summary.incoming;
    final current = pending.summary.current;
    final summary = pending.summary;

    // In the order of the app; the archived ones last, and marked.
    final sorted = [...file.data.calendars]
      ..sort((a, b) {
        if (a.archived != b.archived) return a.archived ? 1 : -1;
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    final calendars = [
      for (final c in sorted)
        c.archived ? l10n.backupUiPreviewArchived(c.name) : c.name,
    ];

    final origin = switch (request.origin) {
      BackupImportOrigin.pickedFile => l10n.backupUiOriginFile,
      BackupImportOrigin.sharedFile => l10n.backupUiOriginShared,
      BackupImportOrigin.localCopy => l10n.backupUiOriginLocal,
      BackupImportOrigin.safetyCopy => l10n.backupUiOriginSafety,
      BackupImportOrigin.cloudCopy => l10n.backupUiOriginCloud,
    };
    final String range;
    if (summary.firstDate == null || summary.lastDate == null) {
      range = l10n.backupUiPreviewRangeNone;
    } else {
      final from = backupDay(l10n, summary.firstDate!);
      final to = backupDay(l10n, summary.lastDate!);
      range = summary.hasOpenEndedRun
          ? l10n.backupUiPreviewRangeOpen(from, to)
          : l10n.backupUiPreviewRangeValue(from, to);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          key: const ValueKey('restore-preview'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                origin.toUpperCase(),
                key: const ValueKey('restore-origin'),
                style: type.label.copyWith(color: colors.textMuted),
              ),
              if (sender != null) ...[
                const SizedBox(height: Sp.xs),
                Text(
                  l10n.backupUiPreviewSender(sender!),
                  key: const ValueKey('restore-sender'),
                  style: type.body.copyWith(color: colors.textSecondary),
                ),
                Text(
                  l10n.backupUiPreviewSenderHint,
                  key: const ValueKey('restore-sender-hint'),
                  style: type.meta.copyWith(color: colors.textMuted),
                ),
              ],
              const SizedBox(height: Sp.xs),
              Text(
                l10n.backupUiPreviewSaved(
                  backupWhen(l10n, file.exportedAt, now),
                ),
                key: const ValueKey('restore-saved'),
                style: type.bodyStrong,
              ),
              const SizedBox(height: Sp.l),
              Text(
                l10n.backupUiPreviewContains.toUpperCase(),
                style: type.label.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: Sp.s),
              _Fact(
                label: l10n.backupUiPreviewCalendars,
                valueKey: 'restore-calendars',
                value: '${incoming.calendars}',
                detail: calendars.join(', '),
                now: l10n.backupUiPreviewNow('${current.calendars}'),
              ),
              _Fact(
                label: l10n.backupUiPreviewDays,
                valueKey: 'restore-days',
                value: '${incoming.dayEntries}',
                now: l10n.backupUiPreviewNow('${current.dayEntries}'),
              ),
              _Fact(
                label: l10n.backupUiPreviewRuns,
                valueKey: 'restore-runs',
                value: '${incoming.patternRuns}',
                now: l10n.backupUiPreviewNow('${current.patternRuns}'),
              ),
              _Fact(
                label: l10n.backupUiPreviewTypes,
                valueKey: 'restore-types',
                value: '${incoming.shiftTypes}',
                now: l10n.backupUiPreviewNow('${current.shiftTypes}'),
              ),
              _Fact(
                label: l10n.backupUiPreviewRange,
                valueKey: 'restore-range',
                detail: range,
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.card),
        AppCallout(
          icon: BackupIcons.warning,
          tone: TonePair(colors.dangerContainer, colors.danger),
          titleKey: const ValueKey('restore-replace-notice'),
          title: l10n.backupUiPreviewReplace,
        ),
        if (summary.turnsOffAutoBackup || summary.turnsOffAlarms) ...[
          const SizedBox(height: Sp.card),
          AppCallout(
            icon: BackupIcons.warning,
            tone: TonePair(colors.dangerContainer, colors.danger),
            titleKey: const ValueKey('restore-turns-off'),
            title: l10n.backupUiPreviewTurnsOffTitle,
            message: [
              if (summary.turnsOffAutoBackup) l10n.backupUiPreviewTurnsOffAuto,
              if (summary.turnsOffAlarms) l10n.backupUiPreviewTurnsOffAlarms,
            ].join('\n'),
          ),
        ],
        const SizedBox(height: Sp.xxl),
        PrimaryButton(
          key: const ValueKey('restore-confirm'),
          label: l10n.backupUiPreviewConfirm,
          icon: BackupIcons.restore,
          onPressed: onConfirm,
        ),
        const SizedBox(height: Sp.s),
        SecondaryButton(
          key: const ValueKey('restore-cancel'),
          label: l10n.backupUiPreviewCancel,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

/// One line of the contents: label, what the file has, what the phone has.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.valueKey,
    this.value,
    this.detail,
    this.now,
  });

  final String label;
  final String valueKey;
  final String? value;
  final String? detail;
  final String? now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: type.body),
                if (detail != null && detail!.isNotEmpty)
                  Text(
                    detail!,
                    key: ValueKey('$valueKey-detail'),
                    style: type.meta.copyWith(color: colors.textSecondary),
                  ),
                if (now != null)
                  Text(
                    now!,
                    style: type.meta.copyWith(color: colors.textMuted),
                  ),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: Sp.m),
            Text(
              value!,
              key: ValueKey(valueKey),
              style: type.bodyStrong.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
