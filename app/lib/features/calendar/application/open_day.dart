import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schedule/domain/schedule_domain.dart';
import 'paint_controller.dart';
import 'schedule_controller.dart';
import 'selection_controller.dart';

/// The day whose detail is open: in the right pane of the two-pane month
/// (wide screens), or in the sheet that follows the layout on a phone. `null`
/// = nothing open (the pane shows the "today" card and the next days).
///
/// It lives here and not in a widget so it survives a rotation: the pane and
/// the sheet are two faces of the same state (`docs/diseno.md`, «Pantallas
/// anchas»). Paint and selection mode own the right pane, and a different
/// calendar has different days, so each of them closes the day.
class OpenDay extends Notifier<CivilDate?> {
  @override
  CivilDate? build() {
    ref.listen(paintControllerProvider.select((p) => p.active), (_, painting) {
      if (painting) state = null;
    });
    ref.listen(selectionControllerProvider.select((s) => s.active), (_, on) {
      if (on) state = null;
    });
    ref.listen(scheduleControllerProvider.select((s) => s.calendarId), (_, _) {
      state = null;
    });
    return null;
  }

  void open(CivilDate date) => state = date;

  void close() => state = null;

  /// Closes the day only if it is still [date] (a sheet that was dismissed
  /// after the user had already moved on to another day).
  void closeIf(CivilDate date) {
    if (!ref.mounted) return;
    if (state == date) state = null;
  }
}

final openDayProvider = NotifierProvider<OpenDay, CivilDate?>(OpenDay.new);

/// The note being typed in the detail of [OpenDay], kept while the same day
/// changes face (sheet <-> pane on a rotation) so the text in the field is
/// not lost between the old field and the new one. The field writes it on
/// every keystroke and clears it when the note is saved.
class NoteDraft {
  const NoteDraft(this.date, this.text);

  final CivilDate date;
  final String text;
}

class NoteDraftController extends Notifier<NoteDraft?> {
  @override
  NoteDraft? build() => null;

  void set(CivilDate date, String text) => state = NoteDraft(date, text);

  /// The note of [date] has been saved (or abandoned).
  void clear(CivilDate date) {
    if (!ref.mounted) return;
    if (state?.date == date) state = null;
  }
}

final noteDraftProvider = NotifierProvider<NoteDraftController, NoteDraft?>(
  NoteDraftController.new,
);
