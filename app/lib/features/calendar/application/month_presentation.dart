import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schedule/domain/civil_date.dart';

enum MonthPresentation { grid, list }

/// Session preference: survives month/calendar navigation and rotation.
class MonthPresentationController extends Notifier<MonthPresentation> {
  @override
  MonthPresentation build() => MonthPresentation.grid;

  void choose(MonthPresentation value) => state = value;
}

final monthPresentationProvider =
    NotifierProvider<MonthPresentationController, MonthPresentation>(
      MonthPresentationController.new,
    );

/// The last day used by either presentation, plus an explicit focus request.
/// Merely rebuilding or moving the focus never announces a presentation change.
class MonthDayFocus extends Notifier<({CivilDate? date, int request})> {
  @override
  ({CivilDate? date, int request}) build() => (date: null, request: 0);

  void remember(CivilDate date) => state = (date: date, request: state.request);

  void request(CivilDate date) =>
      state = (date: date, request: state.request + 1);
}

final monthDayFocusProvider =
    NotifierProvider<MonthDayFocus, ({CivilDate? date, int request})>(
      MonthDayFocus.new,
    );
