import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/page_body.dart';
import '../../alarms/application/alarm_providers.dart';
import '../../alarms/data/alarm_sounds.dart' show AlarmSoundChoice;
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/shift_type_draft.dart';
import 'shift_code_formatter.dart';
import 'shift_color_grid.dart';
import 'shift_color_picker.dart';
import 'shift_icon_picker.dart';
import 'shift_type_preview.dart';
import 'shift_type_times_section.dart';

/// Form of one shift type (`turnos-spec.md`, "Ajustes > Mis turnos"): code,
/// name, colour with a live preview in light and dark, category, times, and
/// for worked shifts the unpaid break, night override and hourly rate. A new
/// shift when [shiftTypeId] is null, otherwise the stored one is edited.
class ShiftTypeFormScreen extends ConsumerStatefulWidget {
  const ShiftTypeFormScreen({super.key, this.shiftTypeId});

  final String? shiftTypeId;

  @override
  ConsumerState<ShiftTypeFormScreen> createState() =>
      _ShiftTypeFormScreenState();
}

class _ShiftTypeFormScreenState extends ConsumerState<ShiftTypeFormScreen> {
  late final ShiftType? _editing;
  late final bool _missing;
  late ShiftTypeDraft _draft;

  // The draft as the form opened: leaving with anything else asks first.
  late final ShiftTypeDraft _initial;

  final _code = TextEditingController();
  final _name = TextEditingController();
  final _unpaidBreak = TextEditingController();
  final _rate = TextEditingController();
  final _fixedPlus = TextEditingController();
  final _codeFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _breakFocus = FocusNode();
  final _rateFocus = FocusNode();
  final _fixedPlusFocus = FocusNode();

  // The suggested code follows the name until the user types a code.
  bool _codeTouched = false;
  bool _showErrors = false;

  // Display name of the chosen alarm sound and whether it is gone (read from
  // the phone, so it arrives a moment after the form opens).
  String? _soundTitle;
  bool _soundMissing = false;

  /// The system picker is open: the row is off until it answers (or fails).
  bool _pickingSound = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(scheduleControllerProvider);
    final id = widget.shiftTypeId;
    _editing = id == null ? null : state.schedule.shiftTypeById(id);
    _missing = id != null && _editing == null;
    if (_editing != null) {
      _draft = ShiftTypeDraft.fromShiftType(_editing);
      _codeTouched = true;
    } else {
      _draft = ShiftTypeDraft(colorValue: _firstUnusedColor(state.palette));
    }
    _initial = _draft;
    _code.text = _draft.code;
    _name.text = _draft.name;
    _unpaidBreak.text = _draft.unpaidBreakText;
    _rate.text = _draft.rateText;
    _fixedPlus.text = _draft.fixedPlusText;
    _loadSoundInfo();
  }

  /// Reads the name of the stored sound and whether it can still be played.
  Future<void> _loadSoundInfo() async {
    final uri = _draft.alarmSound;
    final sounds = ref.read(alarmSoundsProvider);
    if (uri == null || !sounds.supported) return;
    final title = await sounds.title(uri);
    final available = await sounds.isAvailable(uri);
    if (!mounted || _draft.alarmSound != uri) return;
    setState(() {
      _soundTitle = title;
      _soundMissing = !available;
    });
  }

  Future<void> _pickSound() async {
    if (_pickingSound) return;
    setState(() => _pickingSound = true);
    AlarmSoundChoice? choice;
    try {
      choice = await ref
          .read(alarmSoundsProvider)
          .pick(current: _draft.alarmSound);
    } catch (_) {
      // The picker failed (the Activity went away, no picker on this phone):
      // the same as going back, and the row must not stay off.
      choice = null;
    } finally {
      if (mounted) setState(() => _pickingSound = false);
    }
    if (choice == null || !mounted) return;
    final picked = choice;
    setState(() {
      _soundTitle = picked.uri == null ? null : picked.title;
      _soundMissing = false;
      _draft = picked.uri == null
          ? _draft.copyWith(clearAlarmSound: true)
          : _draft.copyWith(alarmSound: picked.uri);
    });
  }

  void _resetSound() => setState(() {
    _soundTitle = null;
    _soundMissing = false;
    _draft = _draft.copyWith(clearAlarmSound: true);
  });

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _unpaidBreak.dispose();
    _rate.dispose();
    _fixedPlus.dispose();
    _codeFocus.dispose();
    _nameFocus.dispose();
    _breakFocus.dispose();
    _rateFocus.dispose();
    _fixedPlusFocus.dispose();
    super.dispose();
  }

  /// The first colour of the grid no shift of the palette wears yet.
  static int _firstUnusedColor(List<ShiftType> palette) {
    final used = {for (final t in palette) t.colorValue};
    for (final c in ShiftPalette.editorChoices) {
      if (!used.contains(c.toARGB32())) return c.toARGB32();
    }
    return ShiftPalette.editorChoices.first.toARGB32();
  }

  List<ShiftType> _others(List<ShiftType> palette) => [
    for (final t in palette)
      if (t.id != _editing?.id) t,
  ];

  void _update(ShiftTypeDraft draft) => setState(() => _draft = draft);

  /// «Partido 09–13 / 17–21»: the times of [splitShiftTemplate], and its name
  /// (with the code that follows) when the name is still empty.
  void _useSplitTemplate(List<ShiftType> palette) {
    final t = splitShiftTemplate;
    _update(
      _draft.copyWith(
        hasTimes: true,
        startMinute: t.startMinute,
        endMinute: t.endMinute,
        segment2StartMinute: t.segment2StartMinute,
        segment2DurationMinutes: t.segment2DurationMinutes,
      ),
    );
    if (_name.text.trim().isEmpty) {
      _name.text = t.name;
      _onName(t.name, palette);
    }
  }

  void _onName(String text, List<ShiftType> palette) {
    var draft = _draft.copyWith(name: text);
    if (!_codeTouched) {
      final code = suggestShiftCode(text, [
        for (final t in _others(palette)) t.code,
      ]);
      _code.text = code;
      draft = draft.copyWith(code: code);
    }
    _update(draft);
  }

  /// Picks one of the four times: the start or the end of the first segment,
  /// or of the second one ([second], a split shift).
  Future<void> _pickTime({required bool start, bool second = false}) async {
    final current = second
        ? (start ? _draft.segment2StartMinute : _draft.segment2EndMinute) ?? 0
        : (start ? _draft.startMinute : _draft.endMinute);
    final l10n = context.l10n;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: second
          ? (start
                ? l10n.shiftTypesPickSecondStart
                : l10n.shiftTypesPickSecondEnd)
          : (start ? l10n.shiftTypesPickStart : l10n.shiftTypesPickEnd),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final minute = picked.hour * 60 + picked.minute;
    if (second) {
      // The end is a clock time; the draft keeps start + duration, so the end
      // is applied against the (possibly new) start.
      _update(
        start
            ? _draft.copyWith(
                segment2StartMinute: minute,
                // Keep the same end: the duration follows the new start.
                segment2EndMinute: _draft.segment2EndMinute,
              )
            : _draft.copyWith(segment2EndMinute: minute),
      );
      return;
    }
    _update(
      start
          ? _draft.copyWith(startMinute: minute)
          : _draft.copyWith(endMinute: minute),
    );
  }

  /// «Más colores…»: any colour, with the preview of the cell inside.
  Future<void> _pickFreeColor() async {
    final picked = await showShiftColorPicker(
      context,
      shift: _previewShift,
      initial: _draft.colorValue,
    );
    if (picked == null || !mounted) return;
    _update(_draft.copyWith(colorValue: picked));
  }

  bool get _dirty => _draft != _initial;

  /// Back with changes not saved: asks before throwing them away (H-T05-1).
  Future<void> _confirmDiscard() async {
    // A picker/dialog owns Back while it covers the editor (H-T23-4).
    // Ignore any blocked-pop notification delivered to the underlying page.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    final discard = await showConfirmDialog(
      context,
      title: l10n.shiftTypesDiscardTitle,
      body: l10n.shiftTypesDiscardBody,
      confirmLabel: l10n.shiftTypesDiscardConfirm,
      cancelLabel: l10n.shiftTypesDiscardKeep,
      destructive: true,
      scrollable: true,
      confirmKey: const ValueKey('shift-discard-confirm'),
    );
    if (!discard || !mounted) return;
    _leave();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.shiftTypes);
    }
  }

  void _save(List<ShiftType> palette) {
    final problems = _draft.validate(others: _others(palette));
    setState(() => _showErrors = true);
    if (problems.isNotEmpty) {
      final first = ShiftTypeField.values.firstWhere(problems.containsKey);
      switch (first) {
        case ShiftTypeField.code:
          _codeFocus.requestFocus();
        case ShiftTypeField.name:
          _nameFocus.requestFocus();
        case ShiftTypeField.unpaidBreak:
          _breakFocus.requestFocus();
        case ShiftTypeField.rate:
          _rateFocus.requestFocus();
        case ShiftTypeField.fixedPlus:
          _fixedPlusFocus.requestFocus();
        case ShiftTypeField.segment2:
          // The message sits right under the times: nothing to focus.
          break;
      }
      return;
    }
    final id = _editing?.id ?? const Uuid().v4();
    ref
        .read(scheduleControllerProvider.notifier)
        .saveShiftType(_draft.toShiftType(id));
    // Saved: nothing left to lose (and `pop` does not go through PopScope).
    _leave();
  }

  String? _errorText(
    Map<ShiftTypeField, ShiftTypeProblem> problems,
    ShiftTypeField field, {
    bool always = false,
  }) {
    final problem = problems[field];
    if ((!_showErrors && !always) || problem == null) return null;
    final l10n = context.l10n;
    return switch (problem.issue) {
      ShiftTypeIssue.codeEmpty => l10n.shiftTypesErrorCodeEmpty,
      ShiftTypeIssue.codeTooLong => l10n.shiftTypesErrorCodeTooLong,
      ShiftTypeIssue.codeTaken => l10n.shiftTypesErrorCodeTaken(
        problem.other ?? '',
      ),
      ShiftTypeIssue.nameEmpty => l10n.shiftTypesErrorNameEmpty,
      ShiftTypeIssue.breakTooLong => l10n.shiftTypesErrorBreak,
      ShiftTypeIssue.rateInvalid => l10n.shiftTypesErrorRate,
      ShiftTypeIssue.segment2Incomplete => l10n.shiftTypesErrorSplitIncomplete,
      ShiftTypeIssue.segment2StartOutOfRange => l10n.shiftTypesErrorSplitStart,
      ShiftTypeIssue.segment2DurationOutOfRange =>
        l10n.shiftTypesErrorSplitDuration,
      ShiftTypeIssue.segment2NotAfterFirst => l10n.shiftTypesErrorSplitNotAfter,
      ShiftTypeIssue.segment2TooLong => l10n.shiftTypesErrorSplitTooLong,
    };
  }

  /// A shift for the preview (a placeholder code while none is typed).
  ShiftType get _previewShift => ShiftType(
    id: _editing?.id ?? 'preview',
    // Whole characters only: the code may not fit while it is being fixed.
    code: fitShiftCode(_draft.code),
    name: _draft.name,
    colorValue: _draft.colorValue,
    category: _draft.category,
    startMinute: _draft.hasTimes ? _draft.startMinute : null,
    endMinute: _draft.hasTimes ? _draft.endMinute : null,
    segment2StartMinute: _draft.segment2Fits
        ? _draft.segment2StartMinute
        : null,
    segment2DurationMinutes: _draft.segment2Fits
        ? _draft.segment2DurationMinutes
        : null,
    icon: _draft.icon,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_missing) {
      return Scaffold(
        appBar: ContentAppBar.adaptive(
          context,
          title: Text(l10n.shiftTypesEditTitle),
        ),
        body: PageBody(
          child: EmptyState(
            icon: AppIcons.error,
            title: l10n.shiftTypesNotFound,
            message: l10n.shiftTypesNotFoundMessage,
          ),
        ),
      );
    }

    final palette = ref.watch(
      scheduleControllerProvider.select((s) => s.palette),
    );
    final problems = _draft.validate(others: _others(palette));
    final isNew = _editing == null;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: _scaffold(context, palette, problems, isNew),
    );
  }

  Widget _scaffold(
    BuildContext context,
    List<ShiftType> palette,
    Map<ShiftTypeField, ShiftTypeProblem> problems,
    bool isNew,
  ) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(isNew ? l10n.shiftTypesNewTitle : l10n.shiftTypesEditTitle),
      ),
      body: PageBody(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            Sp.page,
            Sp.s,
            Sp.page,
            Sp.section + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: l10n.shiftTypesNameLabel,
                child: TextField(
                  key: const ValueKey('shift-name'),
                  controller: _name,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(maxShiftNameLength),
                  ],
                  decoration: InputDecoration(
                    errorText: _errorText(problems, ShiftTypeField.name),
                  ),
                  onChanged: (text) => _onName(text, palette),
                ),
              ),
              const SizedBox(height: Sp.xl),
              LabeledField(
                label: l10n.shiftTypesCodeLabel,
                helper: l10n.shiftTypesCodeHelper,
                child: TextField(
                  key: const ValueKey('shift-code'),
                  controller: _code,
                  focusNode: _codeFocus,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  inputFormatters: const [ShiftCodeFormatter()],
                  decoration: InputDecoration(
                    errorText: _errorText(problems, ShiftTypeField.code),
                  ),
                  onChanged: (text) {
                    _codeTouched = true;
                    _update(_draft.copyWith(code: text));
                  },
                ),
              ),
              const SizedBox(height: Sp.section),
              // The preview sits right above the colours it reacts to.
              LabeledField(
                label: l10n.shiftTypesPreviewLabel,
                child: ShiftTypePreview(shift: _previewShift),
              ),
              const SizedBox(height: Sp.xl),
              LabeledField(
                label: l10n.shiftTypesColorLabel,
                child: ShiftColorGrid(
                  selected: _draft.colorValue,
                  onChanged: (value) =>
                      _update(_draft.copyWith(colorValue: value)),
                  onMore: _pickFreeColor,
                ),
              ),
              const SizedBox(height: Sp.section),
              LabeledField(
                label: l10n.shiftTypesCategoryLabel,
                child: Wrap(
                  spacing: Sp.s,
                  runSpacing: Sp.s,
                  children: [
                    for (final (key, category, label) in [
                      ('work', ShiftCategory.work, l10n.shiftTypesCategoryWork),
                      ('rest', ShiftCategory.rest, l10n.shiftTypesCategoryRest),
                      (
                        'absence',
                        ShiftCategory.absence,
                        l10n.shiftTypesCategoryAbsence,
                      ),
                    ])
                      ChoicePill(
                        key: ValueKey('category-$key'),
                        label: label,
                        selected: _draft.category == category,
                        onTap: () =>
                            _update(_draft.copyWith(category: category)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.section),
              ShiftIconField(
                selected: _draft.icon,
                onChanged: (icon) => _update(
                  icon == null
                      ? _draft.copyWith(clearIcon: true)
                      : _draft.copyWith(icon: icon),
                ),
              ),
              const SizedBox(height: Sp.section),
              ShiftTypeTimesSection(
                draft: _draft,
                onNoTimes: (noTimes) =>
                    _update(_draft.copyWith(hasTimes: !noTimes)),
                onPickStart: () => _pickTime(start: true),
                onPickEnd: () => _pickTime(start: false),
                onUseSplitTemplate: isNew
                    ? () => _useSplitTemplate(palette)
                    : null,
                onSplit: (split) => _update(
                  split
                      ? _draft.withSplit()
                      : _draft.copyWith(clearSegment2: true),
                ),
                onPickSecondStart: () => _pickTime(start: true, second: true),
                onPickSecondEnd: () => _pickTime(start: false, second: true),
                splitError: _errorText(
                  problems,
                  ShiftTypeField.segment2,
                  always: true,
                ),
              ),
              if (_draft.paySectionApplies) ...[
                const SizedBox(height: Sp.section),
                LabeledField(
                  label: l10n.shiftTypesBreakLabel,
                  helper: _breakHelper(),
                  child: TextField(
                    key: const ValueKey('shift-break'),
                    controller: _unpaidBreak,
                    focusNode: _breakFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      // The unit shows before anything is typed (H-T05-5):
                      // the suffix alone only appears with text.
                      hintText: l10n.shiftTypesBreakHint,
                      suffixText: l10n.shiftTypesBreakUnit,
                      errorText: _errorText(
                        problems,
                        ShiftTypeField.unpaidBreak,
                      ),
                    ),
                    onChanged: (text) =>
                        _update(_draft.copyWith(unpaidBreakText: text)),
                  ),
                ),
                const SizedBox(height: Sp.xl),
                LabeledField(
                  label: l10n.shiftTypesNightLabel,
                  helper: l10n.shiftTypesNightHelper,
                  child: Wrap(
                    spacing: Sp.s,
                    runSpacing: Sp.s,
                    children: [
                      for (final (key, value, label)
                          in <(String, bool?, String)>[
                            ('auto', null, l10n.shiftTypesNightAuto),
                            ('always', true, l10n.shiftTypesNightAlways),
                            ('never', false, l10n.shiftTypesNightNever),
                          ])
                        ChoicePill(
                          key: ValueKey('night-$key'),
                          label: label,
                          selected: _draft.nightOverride == value,
                          onTap: () => _update(
                            value == null
                                ? _draft.copyWith(clearNightOverride: true)
                                : _draft.copyWith(nightOverride: value),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.xl),
                LabeledField(
                  label: l10n.shiftTypesRateLabel,
                  helper: l10n.shiftTypesRateHelper,
                  child: TextField(
                    key: const ValueKey('shift-rate'),
                    controller: _rate,
                    focusNode: _rateFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: InputDecoration(
                      hintText: l10n.shiftTypesRateHint,
                      suffixText: l10n.shiftTypesRateUnit,
                      errorText: _errorText(problems, ShiftTypeField.rate),
                      errorMaxLines: 3,
                    ),
                    onChanged: (text) =>
                        _update(_draft.copyWith(rateText: text)),
                  ),
                ),
              ],
              if (_draft.fixedPlusApplies) ...[
                const SizedBox(height: Sp.xl),
                LabeledField(
                  label: l10n.shiftTypesFixedPlusLabel,
                  helper: l10n.shiftTypesFixedPlusHelper,
                  child: TextField(
                    key: const ValueKey('shift-fixed-plus'),
                    controller: _fixedPlus,
                    focusNode: _fixedPlusFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: InputDecoration(
                      hintText: l10n.shiftTypesFixedPlusHint,
                      suffixText: l10n.shiftTypesFixedPlusUnit,
                      errorText: _errorText(problems, ShiftTypeField.fixedPlus),
                      errorMaxLines: 3,
                    ),
                    onChanged: (text) =>
                        _update(_draft.copyWith(fixedPlusText: text)),
                  ),
                ),
              ],
              if (_draft.alarmSectionApplies &&
                  ref.watch(alarmSoundsProvider).supported) ...[
                const SizedBox(height: Sp.section),
                _SoundSection(
                  uri: _draft.alarmSound,
                  title: _soundTitle,
                  missing: _soundMissing,
                  onPick: _pickingSound ? null : _pickSound,
                  onReset: _resetSound,
                ),
              ],
              const SizedBox(height: Sp.section),
              PrimaryButton(
                key: const ValueKey('shift-save'),
                label: l10n.save,
                onPressed: () => _save(palette),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Se pagan 7 h 30 min" while the break makes sense.
  String _breakHelper() {
    final l10n = context.l10n;
    final unpaid = _draft.unpaidBreakMinutes;
    final paid = unpaid == null ? null : _draft.scheduledMinutes - unpaid;
    if (paid == null || paid <= 0) return l10n.shiftTypesBreakHelper;
    return l10n.shiftTypesPaidHelper(durationText(l10n, paid));
  }
}

/// «Alarma» section of the form: the sound this shift's alarms ring with
/// (docs/alarmas.md). The button opens the phone's sound picker and shows the
/// current choice; a sound that has gone says so and rings the default one.
class _SoundSection extends StatelessWidget {
  const _SoundSection({
    required this.uri,
    required this.title,
    required this.missing,
    required this.onPick,
    required this.onReset,
  });

  final String? uri;
  final String? title;
  final bool missing;
  final VoidCallback? onPick;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String value;
    if (uri == null) {
      value = l10n.shiftTypesSoundDefault;
    } else if (missing) {
      value = l10n.shiftTypesSoundMissing;
    } else {
      value = title ?? l10n.shiftTypesSoundCustom;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: Sp.s),
            child: Text(
              l10n.shiftTypesAlarmSection.toUpperCase(),
              style: context.type.label.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ),
        ),
        LabeledField(
          label: l10n.shiftTypesSoundLabel,
          helper: l10n.shiftTypesSoundHelper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SecondaryButton(
                key: const ValueKey('shift-sound'),
                icon: AppIcons.sound,
                label: value,
                onPressed: onPick,
              ),
              if (uri != null) ...[
                const SizedBox(height: Sp.s),
                SecondaryButton(
                  key: const ValueKey('shift-sound-reset'),
                  icon: AppIcons.undo,
                  label: l10n.shiftTypesSoundReset,
                  expand: false,
                  onPressed: onReset,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
