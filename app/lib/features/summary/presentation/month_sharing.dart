import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/application/preferences_controller.dart';
import '../../year/application/year_providers.dart';
import 'month_image.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Hands a PNG to the system share sheet. It is the year view's sharer (it
/// writes the file to the cache folder and opens `share_plus`), under its
/// own name so a test can tell the month's share from the year's.
final monthImageSharerProvider = Provider<YearImageSharer>(
  (ref) => ref.watch(yearImageSharerProvider),
);

/// "Compartir el mes como imagen": draws the month of the ACTIVE calendar
/// (week start of the preferences, holidays of the chosen place) and shares
/// it. The state is true while it works, so a second tap does nothing.
class MonthSharing extends Notifier<bool> {
  @override
  bool build() => false;

  /// Whether the image reached the share sheet. [month] is any day of the
  /// month to share.
  Future<bool> share(CivilDate month, AppLocalizations l10n) async {
    if (state) return true;
    state = true;
    try {
      final first = month.firstDayOfMonth;
      final png = await renderMonthImage(
        month: first,
        schedule: ref.read(scheduleControllerProvider).schedule,
        holidays: ref.read(holidaysProvider),
        weekStart: ref.read(preferencesProvider).weekStart,
        locale: Locale(l10n.localeName),
      );
      final name =
          'cuadrante-${first.year}-${first.month.toString().padLeft(2, '0')}.png';
      final label = AppDateFormat(l10n.localeName)
          .monthYear(DateTime(first.year, first.month));
      await ref.read(monthImageSharerProvider)(
        png,
        name,
        l10n.shareMonthSubject(label),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final monthSharingProvider = NotifierProvider<MonthSharing, bool>(
  MonthSharing.new,
);

/// Shares [month] and tells the user when it fails. Used by the month screen
/// and by the summary.
Future<void> shareMonthImage(
  BuildContext context,
  WidgetRef ref,
  CivilDate month,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await ref.read(monthSharingProvider.notifier).share(month, l10n);
  if (!ok) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(content: Text(l10n.shareMonthFailed)));
  }
}
