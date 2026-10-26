import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/button_row.dart';
import '../../../core/widgets/buttons.dart';
import '../../calendar/presentation/shift_format.dart';
import '../domain/shift_type_draft.dart';

/// "Sin horario" switch, the two time buttons and what they add up to.
class ShiftTypeTimesSection extends StatelessWidget {
  const ShiftTypeTimesSection({
    super.key,
    required this.draft,
    required this.onNoTimes,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onSplit,
    required this.onUseSplitTemplate,
    required this.onPickSecondStart,
    required this.onPickSecondEnd,
    required this.splitError,
    this.keyPrefix = 'shift',
  });

  final String keyPrefix;
  final ShiftTypeDraft draft;
  final ValueChanged<bool> onNoTimes;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  /// The «Turno partido» switch.
  final ValueChanged<bool> onSplit;

  /// Fills the times with «Partido 09–13 / 17–21»; `null` (no button) when
  /// an existing shift type is being edited.
  final VoidCallback? onUseSplitTemplate;
  final VoidCallback onPickSecondStart;
  final VoidCallback onPickSecondEnd;

  /// What is wrong with the second segment (shown once the user tried to
  /// save), or null.
  final String? splitError;

  /// «Empieza 08:00» / «Termina 16:00»: side by side while each label's
  /// words fit, one under the other when they do not (H-T05-2: «Empi / eza
  /// 17:0 / 0» at x2.0 on 320 dp).
  Widget _timeButtons(
    AppLocalizations l10n, {
    required String startKey,
    required String start,
    required VoidCallback onStart,
    required String endKey,
    required String end,
    required VoidCallback onEnd,
  }) => AdaptiveButtonRow(
    items: [
      ButtonRowItem(
        label: start,
        hasIcon: true,
        child: SecondaryButton(
          key: ValueKey(startKey),
          icon: AppIcons.schedule,
          label: start,
          onPressed: onStart,
        ),
      ),
      ButtonRowItem(
        label: end,
        hasIcon: true,
        child: SecondaryButton(
          key: ValueKey(endKey),
          icon: AppIcons.schedule,
          label: end,
          onPressed: onEnd,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    String clock(int minute) =>
        format.time(DateTime(2000, 1, 1, minute ~/ 60, minute % 60));

    final String? summary;
    if (!draft.hasTimes) {
      summary = null;
    } else if (draft.isTwentyFourHours) {
      summary = l10n.shiftTypesTwentyFourHours;
    } else {
      final duration = durationText(l10n, draft.durationMinutes);
      summary = draft.segment2Fits
          ? l10n.shiftTypesSplitSummary(
              duration,
              durationText(l10n, draft.segment2DurationMinutes!),
              durationText(l10n, draft.scheduledMinutes),
            )
          : draft.endsNextDay
          ? l10n.shiftTypesEndsNextDay(duration)
          : l10n.shiftTypesDuration(duration);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.s),
          child: Text(l10n.shiftTypesTimesLabel, style: context.type.meta),
        ),
        SwitchListTile(
          key: ValueKey('$keyPrefix-no-times'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.shiftTypesNoTimes),
          value: !draft.hasTimes,
          onChanged: onNoTimes,
        ),
        if (draft.hasTimes) ...[
          const SizedBox(height: Sp.s),
          _timeButtons(
            l10n,
            startKey: '$keyPrefix-start',
            start: l10n.shiftTypesStarts(clock(draft.startMinute)),
            onStart: onPickStart,
            endKey: '$keyPrefix-end',
            end: l10n.shiftTypesEnds(clock(draft.endMinute)),
            onEnd: onPickEnd,
          ),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.only(top: Sp.s, bottom: Sp.s),
              child: Text(
                summary,
                key: ValueKey('$keyPrefix-times-summary'),
                style: context.type.meta,
              ),
            ),
          SwitchListTile(
            key: ValueKey('$keyPrefix-split'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.shiftTypesSplitLabel),
            subtitle: Text(l10n.shiftTypesSplitHelper),
            value: draft.isSplit,
            onChanged: onSplit,
          ),
          if (!draft.isSplit && onUseSplitTemplate != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SecondaryButton(
                key: ValueKey('$keyPrefix-split-template'),
                icon: AppIcons.schedule,
                label: l10n.shiftTypesSplitTemplate,
                expand: false,
                onPressed: onUseSplitTemplate,
              ),
            ),
          if (draft.isSplit) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s),
              child: Text(
                l10n.shiftTypesSplitSecondTitle,
                style: context.type.meta,
              ),
            ),
            _timeButtons(
              l10n,
              startKey: '$keyPrefix-start2',
              start: l10n.shiftTypesStarts(clock(draft.segment2StartMinute!)),
              onStart: onPickSecondStart,
              endKey: '$keyPrefix-end2',
              end: l10n.shiftTypesEnds(clock(draft.segment2EndMinute ?? 0)),
              onEnd: onPickSecondEnd,
            ),
            if (splitError != null)
              Padding(
                padding: const EdgeInsets.only(top: Sp.s),
                child: Text(
                  splitError!,
                  key: ValueKey('$keyPrefix-split-error'),
                  style: context.type.meta.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }
}
