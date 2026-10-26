import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/settings_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/labeled_field.dart';
import '../application/calendars_controller.dart';
import '../domain/calendar.dart';
import 'calendar_dot.dart';
import 'calendar_messages.dart';

/// Opens the sheet to create a calendar, or to edit [calendar]: name,
/// colour, "use for widget and alarms" and archive.
Future<void> showCalendarEditor(BuildContext context, {Calendar? calendar}) =>
    showAppSheet<void>(
      context: context,
      padded: true,
      builder: (_) => CalendarEditor(calendar: calendar),
    );

/// Longest name a calendar can have in the editor.
const int kCalendarNameMaxLength = 40;

/// The colours offered for a calendar: the hues of the shift palette.
const List<Color> kCalendarColors = ShiftPalette.defaults;

class CalendarEditor extends ConsumerStatefulWidget {
  const CalendarEditor({super.key, this.calendar});

  /// The calendar being edited; `null` creates a new one.
  final Calendar? calendar;

  @override
  ConsumerState<CalendarEditor> createState() => _CalendarEditorState();
}

class _CalendarEditorState extends ConsumerState<CalendarEditor> {
  late final TextEditingController _name;
  late int _colorValue;
  String? _error;
  bool _busy = false;

  Calendar? get _calendar => widget.calendar;
  bool get _creating => _calendar == null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _calendar?.name ?? '');
    _colorValue = _calendar?.colorValue ?? _firstFreeColor();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// A new calendar starts on a colour no other calendar uses, when there is
  /// one.
  int _firstFreeColor() {
    final used = {
      for (final c
          in ref.read(calendarsControllerProvider).value?.calendars ??
              const <Calendar>[])
        c.colorValue,
    };
    for (final color in kCalendarColors) {
      if (!used.contains(color.toARGB32())) return color.toARGB32();
    }
    return kCalendarColors.first.toARGB32();
  }

  CalendarsController get _controller =>
      ref.read(calendarsControllerProvider.notifier);

  /// Runs [action] with the buttons locked; a refusal or a failure becomes the
  /// message under the form instead of closing the sheet.
  Future<void> _run(Future<void> Function() action) async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = calendarErrorMessage(l10n, error);
        });
      }
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.calendarsNameRequired);
      return;
    }
    final calendar = _calendar;
    await _run(() async {
      if (calendar == null) {
        await _controller.create(name: name, colorValue: _colorValue);
        return;
      }
      if (name != calendar.name) await _controller.rename(calendar.id, name);
      if (_colorValue != calendar.colorValue) {
        await _controller.recolor(calendar.id, _colorValue);
      }
    });
  }

  Future<void> _makePrimary(Calendar calendar) =>
      _run(() => _controller.setPrimary(calendar.id));

  Future<void> _archive(Calendar calendar) async {
    final l10n = context.l10n;
    final state = ref.read(calendarsControllerProvider).value;
    final calendars = state?.calendars ?? const <Calendar>[];
    // The last calendar is refused by the repository with its own message, so
    // there is nothing to confirm in that case.
    if (calendars.length > 1) {
      // Archiving the calendar the widget and the alarms follow hands them to
      // the first one left (the repository's rule): say which (H-T07-2).
      final heir = state?.primaryId == calendar.id
          ? calendars.firstWhere((c) => c.id != calendar.id)
          : null;
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.calendarsArchiveTitle(calendar.name),
        body: heir == null
            ? l10n.calendarsArchiveBody
            : '${l10n.calendarsArchiveBody}\n\n'
                  '${l10n.calendarsArchivePrimaryNote(heir.name)}',
        confirmLabel: l10n.calendarsArchive,
        destructive: true,
        confirmKey: const ValueKey('calendar-archive-confirm'),
      );
      if (!confirmed || !mounted) return;
    }
    await _run(() => _controller.archive(calendar.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final calendar = _calendar;
    final primaryId = ref.watch(
      calendarsControllerProvider.select((s) => s.value?.primaryId),
    );
    final options = [
      for (final color in kCalendarColors) color.toARGB32(),
      // A colour that came from elsewhere (a restored backup) stays pickable.
      if (calendar != null &&
          !kCalendarColors.any((c) => c.toARGB32() == calendar.colorValue))
        calendar.colorValue,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.l),
          child: Semantics(
            header: true,
            child: Text(
              _creating ? l10n.calendarsNewTitle : l10n.calendarsEditTitle,
              style: type.headline,
            ),
          ),
        ),
        LabeledField(
          label: l10n.calendarsNameLabel,
          child: TextField(
            key: const ValueKey('calendar-name-field'),
            controller: _name,
            autofocus: _creating,
            enabled: !_busy,
            maxLength: kCalendarNameMaxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: l10n.calendarsNameHint,
              counterText: '',
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
          ),
        ),
        const SizedBox(height: Sp.l),
        LabeledField(
          label: l10n.calendarsColorLabel,
          child: Wrap(
            spacing: Sp.s,
            runSpacing: Sp.s,
            children: [
              for (var i = 0; i < options.length; i++)
                _ColorChoice(
                  key: ValueKey('calendar-color-$i'),
                  colorValue: options[i],
                  label: l10n.calendarsColorOption(i + 1),
                  selected: options[i] == _colorValue,
                  onTap: _busy
                      ? null
                      : () => setState(() => _colorValue = options[i]),
                ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: Sp.m),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              key: const ValueKey('calendar-editor-error'),
              style: type.body.copyWith(color: colors.danger),
            ),
          ),
        ],
        const SizedBox(height: Sp.xl),
        PrimaryButton(
          key: const ValueKey('calendar-save'),
          label: _creating ? l10n.calendarsCreate : l10n.save,
          loading: _busy,
          onPressed: _busy ? null : _save,
        ),
        if (calendar != null) ...[
          const SizedBox(height: Sp.l),
          if (primaryId != calendar.id) ...[
            SecondaryButton(
              key: const ValueKey('calendar-make-primary'),
              label: l10n.calendarsMakePrimary,
              onPressed: _busy ? null : () => _makePrimary(calendar),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Sp.xs, bottom: Sp.s),
              child: Text(
                l10n.calendarsPrimaryHelp,
                style: type.meta.copyWith(color: colors.textMuted),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('calendar-archive'),
              style: TextButton.styleFrom(foregroundColor: colors.danger),
              onPressed: _busy ? null : () => _archive(calendar),
              icon: Icon(SettingsIcons.archive, size: IconSize.button),
              label: Text(l10n.calendarsArchive),
            ),
          ),
        ],
      ],
    );
  }
}

/// One round colour of the picker: a 48 dp touch target around a 28 dp dot,
/// with the selection ring around it (a shape, so the choice never relies on
/// colour alone) and `selected` in the semantics.
class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    super.key,
    required this.colorValue,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int colorValue;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const double _dot = Disc.s;
  static const double _outer = _dot + 2 * (Sp.selectionGap + Sp.selectionRing);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: Sp.touch,
          child: Center(
            child: Container(
              width: _outer,
              height: _outer,
              padding: const EdgeInsets.all(Sp.selectionGap),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? colors.todayRing : Colors.transparent,
                  width: Sp.selectionRing,
                ),
              ),
              child: CalendarDot(colorValue: colorValue, size: _dot),
            ),
          ),
        ),
      ),
    );
  }
}
