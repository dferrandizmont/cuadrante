import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/application/schedule_controller.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/month_summary.dart';
import '../domain/summary_range.dart';

/// The holiday dates of the chosen place, as the summary needs them.
final summaryHolidaysProvider = Provider<Set<CivilDate>>(
  (ref) => ref.watch(holidaysProvider.select((h) => h.keys.toSet())),
);

/// The summary of a month (first day of the month) of the ACTIVE calendar.
/// It follows the schedule and the holidays: painting a day or choosing
/// another calendar updates it.
final monthSummaryProvider = Provider.autoDispose
    .family<MonthSummary, CivilDate>((ref, month) {
      final schedule = ref.watch(
        scheduleControllerProvider.select((s) => s.schedule),
      );
      return summarizeMonth(
        schedule,
        month,
        holidays: ref.watch(summaryHolidaysProvider),
      );
    });

/// The summary of any period of up to 366 days of the ACTIVE calendar
/// (`docs/paridad.md` A7): the same aggregate as [monthSummaryProvider].
final rangeSummaryProvider = Provider.autoDispose
    .family<MonthSummary, SummaryRange>((ref, range) {
      final schedule = ref.watch(
        scheduleControllerProvider.select((s) => s.schedule),
      );
      return summarizeRange(
        schedule,
        range.from,
        range.to,
        holidays: ref.watch(summaryHolidaysProvider),
      );
    });

/// The twelve months of a year of the ACTIVE calendar.
final yearTotalsProvider = Provider.autoDispose.family<YearTotals, int>((
  ref,
  year,
) {
  final schedule = ref.watch(
    scheduleControllerProvider.select((s) => s.schedule),
  );
  return summarizeYearTotals(
    schedule,
    year,
    holidays: ref.watch(summaryHolidaysProvider),
  );
});
