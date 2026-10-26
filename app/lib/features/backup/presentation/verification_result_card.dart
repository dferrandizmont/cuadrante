import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../schedule/domain/civil_date.dart';
import '../domain/restore_summary.dart';
import 'backup_format.dart';

/// The outcome of "Probar restauración" (`BackupRepository.verifyRestore`) in
/// words, for the backup screen:
/// - passed: "La copia está completa: N días comprobados", plus whether it is
///   the same as what the phone holds now or older (and from which day);
/// - mismatch: a real fault of the restore, with the first differing day;
/// - failed: the file could not be read, or the dry run itself failed;
/// - `null`: there is no copy to test yet.
class VerificationResultCard extends StatelessWidget {
  const VerificationResultCard({super.key, required this.result});

  final RestoreVerification? result;

  /// Key of the card (tests).
  static const ValueKey<String> cardKey = ValueKey('backup-verify-result');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final danger = TonePair(colors.dangerContainer, colors.danger);
    String day(CivilDate d) => backupDay(l10n, d);

    return switch (result) {
      null => AppCallout(
        key: cardKey,
        icon: BackupIcons.warning,
        title: l10n.backupUiVerifyNone,
      ),
      final VerificationPassed passed => AppCallout(
        key: cardKey,
        icon: AppIcons.check,
        tone: TonePair(colors.successContainer, colors.success),
        title: l10n.backupUiVerifyOk(passed.fingerprint.dayCount),
        message: passed.matchesLive
            ? l10n.backupUiVerifySame
            : passed.firstDayDifferingFromLive == null
            ? l10n.backupUiVerifyOlderNoDay
            : l10n.backupUiVerifyOlder(day(passed.firstDayDifferingFromLive!)),
      ),
      final VerificationMismatch mismatch => AppCallout(
        key: cardKey,
        icon: BackupIcons.warning,
        tone: danger,
        title: mismatch.firstDifferingDay == null
            ? l10n.backupUiVerifyMismatchNoDay
            : l10n.backupUiVerifyMismatch(day(mismatch.firstDifferingDay!)),
      ),
      VerificationFailed(:final error) => AppCallout(
        key: cardKey,
        icon: BackupIcons.warning,
        tone: danger,
        title: l10n.backupUiVerifyError(backupErrorMessage(l10n, error)),
      ),
    };
  }
}
