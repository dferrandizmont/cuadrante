import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../patterns/application/pattern_start_pick.dart';
import '../../schedule/domain/civil_date.dart';
import '../application/month_presentation.dart';
import '../application/paint_controller.dart';
import '../application/schedule_controller.dart';
import '../application/selection_controller.dart';
import '../application/visible_month.dart';
import 'day_detail_sheet.dart';

/// Tap/keyboard activation has exactly the same meaning in both presentations.
void activateMonthDay(BuildContext context, WidgetRef ref, CivilDate date) {
  ref.read(monthDayFocusProvider.notifier).remember(date);
  if (consumePatternStartPick(context, ref, date)) return;
  if (ref.read(selectionControllerProvider).active) {
    ref.read(selectionControllerProvider.notifier).toggle(date);
    unawaited(HapticFeedback.selectionClick().catchError((Object _) {}));
  } else if (ref.read(paintControllerProvider).active) {
    final month = ref.read(visibleMonthProvider);
    if (date.year != month.year || date.month != month.month) return;
    final controller = ref.read(scheduleControllerProvider.notifier);
    controller.beginStroke(ref.read(paintControllerProvider).tool);
    if (controller.paintDay(date)) {
      unawaited(HapticFeedback.selectionClick().catchError((Object _) {}));
    }
    controller.endStroke();
  } else {
    unawaited(openDayOnMonth(context, ref, date: date));
  }
}
