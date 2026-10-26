import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart' show IconData;
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../schedule/domain/civil_date.dart';
import '../application/auto_backup_runner.dart' show AutoBackupStatus;
import '../data/platform_backup_channel.dart';
import '../domain/backup_errors.dart';

/// Glyphs of the backup screens, picked like `AppIcons` (SF-style on Apple,
/// Material Symbols rounded elsewhere). Kept here so the shared icon files
/// stay untouched.
class BackupIcons {
  const BackupIcons._();

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static IconData _pick(IconData apple, IconData material) =>
      _apple ? apple : material;

  /// Make a copy now.
  static IconData get save =>
      _pick(CupertinoIcons.arrow_down_doc, Symbols.save_rounded);

  /// Save the file to a folder of the phone.
  static IconData get saveToPhone =>
      _pick(CupertinoIcons.arrow_down_to_line, Symbols.download_rounded);
  static IconData get importFile =>
      _pick(CupertinoIcons.folder, Symbols.file_open_rounded);
  static IconData get verify =>
      _pick(CupertinoIcons.checkmark_shield, Symbols.verified_user_rounded);
  static IconData get restore =>
      _pick(CupertinoIcons.arrow_counterclockwise, Symbols.history_rounded);
  static IconData get warning =>
      _pick(CupertinoIcons.exclamationmark_triangle, Symbols.warning_rounded);
  static IconData get auto =>
      _pick(CupertinoIcons.arrow_2_circlepath, Symbols.autorenew_rounded);
}

/// "hoy a las 18:20", "ayer a las 18:20", "el jue 23 oct a las 18:20" (with
/// the year when it is not the current one). [at] is shown in local time.
String backupWhen(AppLocalizations l10n, DateTime at, DateTime now) {
  final fmt = AppDateFormat(l10n.localeName);
  final local = at.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final time = fmt.time(local);
  final diff = today.difference(day).inDays;
  if (diff == 0) return l10n.backupUiWhenToday(time);
  if (diff == 1) return l10n.backupUiWhenYesterday(time);
  final date = local.year == now.year
      ? fmt.shortDate(local)
      : '${fmt.shortDate(local)} ${local.year}';
  return l10n.backupUiWhenDate(date, time);
}

/// What the status card says while changes wait for their copy, and it must
/// be true: the automatic copy comes 10 s after the last change but never
/// sooner than 15 min after the previous one (`AutoBackupPolicy`), so the
/// card tells the expected time instead of promising «unos segundos»
/// (H-T13-1).
String pendingCopyMessage(
  AppLocalizations l10n,
  AutoBackupStatus status,
  DateTime now,
) {
  final due = status.dueAt;
  if (due == null) return l10n.backupUiStatusPendingLater;
  if (due.difference(now) < const Duration(minutes: 1)) {
    return l10n.backupUiStatusPending;
  }
  return l10n.backupUiStatusPendingAt(
    AppDateFormat(l10n.localeName).time(due.toLocal()),
  );
}

/// The first letter in capitals, for a [backupWhen] that starts a sentence.
String sentenceCase(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// "12 KB" / "1,3 MB".
String backupSize(int bytes, String locale) {
  if (bytes < 1024 * 1024) {
    final kb = (bytes / 1024).ceil().clamp(1, 1023);
    return '$kb KB';
  }
  return '${NumberFormat('0.0', locale).format(bytes / (1024 * 1024))} MB';
}

/// "23 oct 2026".
String backupDay(AppLocalizations l10n, CivilDate day) =>
    AppDateFormat(l10n.localeName)
        .dayMonthYear(DateTime(day.year, day.month, day.day));

/// Why a file could not be used, in words for the user. Anything that is not
/// a [BackupException] (or a known problem) is "could not read".
String backupErrorMessage(AppLocalizations l10n, Object error) {
  return switch (error) {
    NewerFormatVersion() => l10n.backupUiErrorNewer,
    NotACuadranteFile() => l10n.backupUiErrorNotOurs,
    CorruptBackup() => l10n.backupUiErrorCorrupt,
    IncomingFileProblem.tooLarge => l10n.backupUiErrorTooLarge,
    _ => l10n.backupUiErrorUnreadable,
  };
}

/// Why a copy could not be written.
String backupFailureReason(AppLocalizations l10n, Object? error) {
  if (error is FileSystemException && error.osError?.errorCode == 28) {
    return l10n.backupUiFailDiskFull; // ENOSPC
  }
  return l10n.backupUiFailGeneric;
}
