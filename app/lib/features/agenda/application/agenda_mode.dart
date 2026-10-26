import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the agenda (`/agenda`) lists when nothing is being searched.
enum AgendaMode {
  /// The days with a note or an own holiday (the default).
  notes,

  /// Every one of the next days with its shifts, days off included.
  shifts,
}

/// The mode the person picked. Kept in memory for the session only: it is
/// not stored, so the app starts on [AgendaMode.notes] again.
final agendaModeProvider = NotifierProvider<AgendaModeNotifier, AgendaMode>(
  AgendaModeNotifier.new,
);

class AgendaModeNotifier extends Notifier<AgendaMode> {
  @override
  AgendaMode build() => AgendaMode.notes;

  void select(AgendaMode mode) => state = mode;
}
