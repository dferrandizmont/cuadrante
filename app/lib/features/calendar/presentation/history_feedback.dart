import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../../core/l10n/l10n.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/schedule_controller.dart';

void announceHistoryResult(
  BuildContext context,
  bool changed, {
  bool redo = false,
}) {
  if (!context.mounted) return;
  final l10n = context.l10n;
  final message = redo
      ? (changed ? l10n.historyRedone : l10n.historyNothingToRedo)
      : (changed ? l10n.historyUndone : l10n.historyNothingToUndo);
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}

void undoWithFeedback(
  BuildContext context,
  ScheduleController controller, {
  ScheduleChange? step,
}) {
  final changed = step == null
      ? controller.undo()
      : controller.undoIfLast(step);
  announceHistoryResult(context, changed);
}

void redoWithFeedback(BuildContext context, ScheduleController controller) {
  announceHistoryResult(context, controller.redo(), redo: true);
}
