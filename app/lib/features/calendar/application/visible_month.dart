import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../schedule/domain/schedule_domain.dart';

/// First day of the month shown by the calendar.
class VisibleMonth extends Notifier<CivilDate> {
  @override
  CivilDate build() => _currentMonth();

  void next() => state = state.addDays(state.daysInMonth);

  void previous() => state = state.addDays(-1).firstDayOfMonth;

  void today() => state = _currentMonth();

  /// Shows the month of [date] (the year view and the pattern wizard).
  void goTo(CivilDate date) => state = date.firstDayOfMonth;

  CivilDate _currentMonth() =>
      CivilDate.fromDateTime(ref.read(clockProvider)()).firstDayOfMonth;
}

final visibleMonthProvider = NotifierProvider<VisibleMonth, CivilDate>(
  VisibleMonth.new,
);
