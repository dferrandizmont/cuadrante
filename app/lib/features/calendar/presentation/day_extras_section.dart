import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../summary/presentation/summary_format.dart';
import '../application/schedule_controller.dart';

/// «Horas extra / Salí antes» of the day detail (docs/paridad.md, A6): two
/// optional durations, in steps of [step] minutes. They are written to the
/// day when the user stops tapping ([settle]) or the sheet closes, so a run of
/// taps is ONE undo step; 0 clears the value. The summary adds the overtime to
/// the hours worked and subtracts the early leave (docs/motor-de-turnos.md).
class DayExtrasSection extends ConsumerStatefulWidget {
  const DayExtrasSection({super.key, required this.date});

  final CivilDate date;

  /// Minutes added or removed by each tap.
  static const int step = 15;

  /// Quiet time after the last tap before the value is written.
  static const Duration settle = Duration(milliseconds: 600);

  @override
  ConsumerState<DayExtrasSection> createState() => DayExtrasSectionState();
}

class DayExtrasSectionState extends ConsumerState<DayExtrasSection> {
  late final ScheduleController _schedule;
  Timer? _timer;

  // What the user has set and is not written yet.
  int? _pendingOvertime;
  int? _pendingEarlyLeave;

  CivilDate get _date => widget.date;

  @override
  void initState() {
    super.initState();
    _schedule = ref.read(scheduleControllerProvider.notifier);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_pendingOvertime != null || _pendingEarlyLeave != null) {
      final date = _date;
      final overtime = _pendingOvertime;
      final earlyLeave = _pendingEarlyLeave;
      final schedule = _schedule;
      // The tree is locked while it is being disposed.
      scheduleMicrotask(
        () => schedule.setDayExtras(
          date,
          overtimeMinutes: overtime,
          earlyLeaveMinutes: earlyLeave,
        ),
      );
    }
    super.dispose();
  }

  void _commit() {
    _timer?.cancel();
    final overtime = _pendingOvertime;
    final earlyLeave = _pendingEarlyLeave;
    if (overtime == null && earlyLeave == null) return;
    _pendingOvertime = null;
    _pendingEarlyLeave = null;
    _schedule.setDayExtras(
      _date,
      overtimeMinutes: overtime,
      earlyLeaveMinutes: earlyLeave,
    );
  }

  /// Finish the debounce before a parent action snapshots or clears the day.
  /// Once cleared, disposal must never reinsert the previous draft.
  void commitPending() => _commit();

  void _change({required bool overtime, required int by, required int now}) {
    final next = (now + by).clamp(0, maxDayExtraMinutes);
    setState(() {
      if (overtime) {
        _pendingOvertime = next;
      } else {
        _pendingEarlyLeave = next;
      }
    });
    _timer?.cancel();
    _timer = Timer(DayExtrasSection.settle, _commit);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final entry = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule.entries[_date]),
    );
    final overtime = _pendingOvertime ?? entry?.overtimeMinutes ?? 0;
    final earlyLeave = _pendingEarlyLeave ?? entry?.earlyLeaveMinutes ?? 0;

    return Column(
      key: const ValueKey('day-extras'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Sp.l),
        Semantics(
          header: true,
          child: Text(
            l10n.dayExtrasTitle.toUpperCase(),
            style: type.label.copyWith(color: colors.textMuted),
          ),
        ),
        const SizedBox(height: Sp.xs),
        _ExtrasRow(
          id: 'overtime',
          label: l10n.dayExtrasOvertime,
          minutes: overtime,
          onChange: (by) => _change(overtime: true, by: by, now: overtime),
        ),
        _ExtrasRow(
          id: 'early',
          label: l10n.dayExtrasEarlyLeave,
          minutes: earlyLeave,
          onChange: (by) => _change(overtime: false, by: by, now: earlyLeave),
        ),
        Text(l10n.dayExtrasHelper, style: type.meta),
      ],
    );
  }
}

/// One label with a «-», its value and a «+».
class _ExtrasRow extends StatelessWidget {
  const _ExtrasRow({
    required this.id,
    required this.label,
    required this.minutes,
    required this.onChange,
  });

  final String id;
  final String label;
  final int minutes;
  final ValueChanged<int> onChange;

  /// Room for «1 h 45 min» at the normal text size.
  static const double _valueWidth = Sp.x4 + Sp.x3 + Sp.s;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final value = minutes == 0
        ? l10n.dayExtrasNone
        : formatHours(l10n, minutes);
    final stepper = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: ValueKey('day-$id-less'),
          tooltip: l10n.dayExtrasLess(label),
          icon: Icon(AppIcons.minus),
          onPressed: minutes == 0
              ? null
              : () => onChange(-DayExtrasSection.step),
        ),
        Flexible(
          child: Semantics(
            container: true,
            liveRegion: true,
            label: l10n.dayExtrasValue(label, value),
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _valueWidth),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  key: ValueKey('day-$id-value'),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: AppTypography.tabular(
                    type.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          key: ValueKey('day-$id-more'),
          tooltip: l10n.dayExtrasMore(label),
          icon: Icon(AppIcons.add),
          onPressed: minutes >= maxDayExtraMinutes
              ? null
              : () => onChange(DayExtrasSection.step),
        ),
      ],
    );
    // With big text the label gets its own line instead of being squeezed.
    final stacked = MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.2;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Sp.s),
            child: Text(label, style: type.body),
          ),
          Align(alignment: Alignment.centerLeft, child: stepper),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: Text(label, style: type.body)),
        stepper,
      ],
    );
  }
}
