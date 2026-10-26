import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/adaptive.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/open_day.dart';
import 'day_detail_body.dart';

/// Opens the detail of [date] (`turnos-spec.md`, screen 4) in a bottom sheet:
/// its shifts (add, remove, reorder, "volver al patrón"), the note, the user's
/// own holiday and the shortcuts to copy or clear the day. Every edit is ONE
/// undoable step of the schedule, so undo / redo in paint mode reverts it.
///
/// This is the modal way, for any screen (the agenda uses it). The month
/// screen uses [openDayOnMonth], which on wide screens shows the day in its
/// right pane instead.
Future<void> showDayDetail(
  BuildContext context, {
  required CivilDate date,
  bool followsLayout = false,
}) => showAppSheet<void>(
  context: context,
  // The sheet lays itself out: a fixed header (dragging it closes the
  // sheet), a scrolling body and a row of chips that bleeds to the edges.
  builder: (_) => DayDetailSheet(date: date, followsLayout: followsLayout),
);

/// A day chosen on the month screen (a tap on the grid, a widget link): in
/// the right pane when the screen has two panes, otherwise in the sheet. Either
/// way [openDayProvider] says which day is open, so a rotation can move it
/// from one to the other.
Future<void> openDayOnMonth(
  BuildContext context,
  WidgetRef ref, {
  required CivilDate date,
}) async {
  ref.read(openDayProvider.notifier).open(date);
  if (Adaptive.useSplit(MediaQuery.sizeOf(context))) return;
  await showDayDetail(context, date: date, followsLayout: true);
}

/// [DayDetailBody] in a bottom sheet.
///
/// With [followsLayout] (opened from the month screen) the sheet gives its day
/// to the right pane when the window becomes wide (a rotation), and its
/// closing closes the open day.
class DayDetailSheet extends ConsumerStatefulWidget {
  const DayDetailSheet({
    super.key,
    required this.date,
    this.followsLayout = false,
  });

  final CivilDate date;
  final bool followsLayout;

  @override
  ConsumerState<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends ConsumerState<DayDetailSheet> {
  final _body = GlobalKey<DayDetailBodyState>();
  late final OpenDay _openDay;
  bool _handedToPane = false;

  @override
  void initState() {
    super.initState();
    _openDay = ref.read(openDayProvider.notifier);
  }

  @override
  void dispose() {
    // Dismissed by the user (scrim, drag, back, «Borrar día»): that day is no
    // longer open. Not when the sheet left because the pane took the day over.
    if (widget.followsLayout && !_handedToPane) {
      final date = widget.date;
      final openDay = _openDay;
      scheduleMicrotask(() => openDay.closeIf(date));
    }
    super.dispose();
  }

  void _handToPane(NavigatorState navigator, ModalRoute<dynamic>? route) {
    if (!mounted || route == null || !route.isCurrent) return;
    // What is typed goes to the schedule now: the pane starts from the same
    // text, and the old field must not write over what is typed there next.
    _body.currentState?.commitPending();
    // The pane shows this day (a stale close of an earlier sheet of the same
    // day may have emptied it).
    _openDay.open(widget.date);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    if (widget.followsLayout &&
        !_handedToPane &&
        Adaptive.useSplit(MediaQuery.sizeOf(context))) {
      _handedToPane = true;
      final route = ModalRoute.of(context);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handToPane(navigator, route),
      );
    }
    return DayDetailBody(key: _body, date: widget.date, onClose: navigator.pop);
  }
}
