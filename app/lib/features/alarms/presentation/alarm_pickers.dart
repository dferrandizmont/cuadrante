import 'package:flutter/cupertino.dart'
    show CupertinoTimerPicker, CupertinoTimerPickerMode;
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../calendar/presentation/shift_format.dart';
import '../domain/alarm_settings.dart';

/// Leads offered in the list, in minutes; anything else is "Personalizado".
const List<int> alarmLeadPresets = [30, 60, 90, 120];

/// Value of the "Personalizado" option of the lead list.
const int _customLead = -1;

/// "Al empezar" / "30 min" / "1 h 30 min".
String alarmLeadText(AppLocalizations l10n, int minutes) =>
    minutes <= 0 ? l10n.alarmsBeforeAtStart : durationText(l10n, minutes);

/// Asks how long before the shift the alarm rings: the presets, or a custom
/// duration with a picker. Null when dismissed.
Future<int?> pickAlarmLead(BuildContext context, {required int current}) async {
  final l10n = context.l10n;
  final custom = !alarmLeadPresets.contains(current);
  final picked = await showChoiceSheet<int>(
    context: context,
    title: l10n.alarmsBeforeSheetTitle,
    selected: custom ? _customLead : current,
    options: [
      for (final m in alarmLeadPresets) ChoiceOption(m, alarmLeadText(l10n, m)),
      ChoiceOption(
        _customLead,
        custom
            ? '${l10n.alarmsBeforeCustom} · ${alarmLeadText(l10n, current)}'
            : l10n.alarmsBeforeCustom,
      ),
    ],
  );
  if (picked == null || !context.mounted) return null;
  if (picked != _customLead) return picked;
  return showAppSheet<int>(
    context: context,
    padded: true,
    builder: (_) => _CustomLeadSheet(initial: current),
  );
}

/// Hours and minutes wheel (a `CupertinoTimerPicker`, which looks the same on
/// every platform and has no Material equivalent) with an "Aceptar" button.
class _CustomLeadSheet extends StatefulWidget {
  const _CustomLeadSheet({required this.initial});

  final int initial;

  @override
  State<_CustomLeadSheet> createState() => _CustomLeadSheetState();
}

class _CustomLeadSheetState extends State<_CustomLeadSheet> {
  late int _minutes = widget.initial.clamp(
    0,
    AlarmTypeSettings.maxMinutesBefore,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.alarmsBeforeCustomTitle, style: type.headline),
        ),
        const SizedBox(height: Sp.xs),
        Text(l10n.alarmsBeforeCustomHelp, style: type.meta),
        const SizedBox(height: Sp.m),
        SizedBox(
          height: 180,
          child: CupertinoTimerPicker(
            key: const ValueKey('alarms-lead-picker'),
            mode: CupertinoTimerPickerMode.hm,
            initialTimerDuration: Duration(minutes: _minutes),
            onTimerDurationChanged: (d) => _minutes = d.inMinutes,
          ),
        ),
        const SizedBox(height: Sp.m),
        PrimaryButton(
          key: const ValueKey('alarms-lead-apply'),
          label: l10n.alarmsBeforeCustomApply,
          onPressed: () => Navigator.pop(context, _minutes),
        ),
      ],
    );
  }
}

/// Asks for the time of day of the day-before reminder (24 h clock). Returns
/// minutes after midnight, or null when dismissed.
Future<int?> pickDayBeforeTime(BuildContext context, {required int current}) =>
    pickMinuteOfDay(
      context,
      current: current,
      help: context.l10n.alarmsDayBeforeTimeTitle,
    );

/// A time of day on a 24 h clock with the Material picker; [help] is the
/// title. Returns minutes after midnight, or null when dismissed.
Future<int?> pickMinuteOfDay(
  BuildContext context, {
  required int current,
  required String help,
}) async {
  final picked = await showTimePicker(
    context: context,
    helpText: help,
    initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  return picked == null ? null : picked.hour * 60 + picked.minute;
}

/// Asks for the custom text of the notification. Returns the new text (empty
/// = back to the default one), or null when dismissed.
Future<String?> pickAlarmLabel(
  BuildContext context, {
  required String? current,
}) => showAppSheet<String>(
  context: context,
  padded: true,
  builder: (_) => _LabelSheet(initial: current ?? ''),
);

class _LabelSheet extends StatefulWidget {
  const _LabelSheet({required this.initial});

  final String initial;

  @override
  State<_LabelSheet> createState() => _LabelSheetState();
}

class _LabelSheetState extends State<_LabelSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.alarmsLabelTitle, style: type.headline),
        ),
        const SizedBox(height: Sp.m),
        TextField(
          key: const ValueKey('alarms-label-field'),
          controller: _text,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: l10n.alarmsLabelHint),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        const SizedBox(height: Sp.m),
        PrimaryButton(
          key: const ValueKey('alarms-label-apply'),
          label: l10n.alarmsLabelApply,
          onPressed: () => Navigator.pop(context, _text.text),
        ),
        const SizedBox(height: Sp.s),
        SecondaryButton(
          key: const ValueKey('alarms-label-reset'),
          label: l10n.alarmsLabelReset,
          onPressed: () => Navigator.pop(context, ''),
        ),
      ],
    );
  }
}
