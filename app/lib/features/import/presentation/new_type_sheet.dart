import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../shift_types/domain/shift_type_draft.dart';
import '../../shift_types/presentation/shift_code_formatter.dart';
import '../../shift_types/presentation/shift_color_grid.dart';
import '../../shift_types/presentation/shift_type_preview.dart';
import '../../shift_types/presentation/shift_type_times_section.dart';

/// Opens the sheet to edit the shift type an import will create. Returns the
/// draft the user accepted, or `null` when they dismissed it.
///
/// [taken] are the shift types whose code the new one must not repeat.
Future<ShiftTypeDraft?> showNewTypeSheet({
  required BuildContext context,
  required ShiftTypeDraft draft,
  required List<ShiftType> taken,
}) => showAppSheet<ShiftTypeDraft>(
  context: context,
  padded: true,
  builder: (_) => NewTypeForm(initial: draft, taken: taken),
);

/// The part of the shift type form an import needs: name, code, colour,
/// category and hours (the editor of «Mis turnos» has the pay options).
class NewTypeForm extends StatefulWidget {
  const NewTypeForm({super.key, required this.initial, required this.taken});

  final ShiftTypeDraft initial;
  final List<ShiftType> taken;

  @override
  State<NewTypeForm> createState() => _NewTypeFormState();
}

class _NewTypeFormState extends State<NewTypeForm> {
  late ShiftTypeDraft _draft = widget.initial;
  late final _name = TextEditingController(text: widget.initial.name);
  late final _code = TextEditingController(text: widget.initial.code);
  bool _codeTouched = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _update(ShiftTypeDraft draft) => setState(() => _draft = draft);

  void _onName(String text) {
    var next = _draft.copyWith(name: text);
    if (!_codeTouched) {
      final code = suggestShiftCode(text, [
        for (final t in widget.taken) t.code,
      ]);
      _code.text = code;
      next = next.copyWith(code: code);
    }
    _update(next);
  }

  Future<void> _pickTime({required bool start, bool second = false}) async {
    final current = second
        ? (start ? _draft.segment2StartMinute : _draft.segment2EndMinute) ?? 0
        : (start ? _draft.startMinute : _draft.endMinute);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: second
          ? (start
                ? context.l10n.shiftTypesPickSecondStart
                : context.l10n.shiftTypesPickSecondEnd)
          : (start
                ? context.l10n.shiftTypesPickStart
                : context.l10n.shiftTypesPickEnd),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final minute = picked.hour * 60 + picked.minute;
    if (second) {
      _update(
        start
            ? _draft.copyWith(
                segment2StartMinute: minute,
                segment2EndMinute: _draft.segment2EndMinute,
              )
            : _draft.copyWith(segment2EndMinute: minute),
      );
    } else {
      _update(
        start
            ? _draft.copyWith(startMinute: minute)
            : _draft.copyWith(endMinute: minute),
      );
    }
  }

  String? _error(
    Map<ShiftTypeField, ShiftTypeProblem> problems,
    ShiftTypeField f,
  ) {
    final problem = problems[f];
    if ((!_showErrors && f != ShiftTypeField.segment2) || problem == null) {
      return null;
    }
    final l10n = context.l10n;
    return switch (problem.issue) {
      ShiftTypeIssue.codeEmpty => l10n.shiftTypesErrorCodeEmpty,
      ShiftTypeIssue.codeTooLong => l10n.shiftTypesErrorCodeTooLong,
      ShiftTypeIssue.codeTaken => l10n.shiftTypesErrorCodeTaken(
        problem.other ?? '',
      ),
      ShiftTypeIssue.nameEmpty => l10n.shiftTypesErrorNameEmpty,
      ShiftTypeIssue.segment2Incomplete => l10n.shiftTypesErrorSplitIncomplete,
      ShiftTypeIssue.segment2StartOutOfRange => l10n.shiftTypesErrorSplitStart,
      ShiftTypeIssue.segment2DurationOutOfRange =>
        l10n.shiftTypesErrorSplitDuration,
      ShiftTypeIssue.segment2NotAfterFirst => l10n.shiftTypesErrorSplitNotAfter,
      ShiftTypeIssue.segment2TooLong => l10n.shiftTypesErrorSplitTooLong,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final problems = _draft.validate(others: widget.taken);
    // The pay options are not part of this form: only the fields it has.
    final shown = {
      for (final f in [
        ShiftTypeField.code,
        ShiftTypeField.name,
        ShiftTypeField.segment2,
      ])
        if (problems.containsKey(f)) f: problems[f]!,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.m),
          child: Semantics(
            header: true,
            child: Text(l10n.importNewTypeTitle, style: context.type.headline),
          ),
        ),
        LabeledField(
          label: l10n.shiftTypesNameLabel,
          child: TextField(
            key: const ValueKey('import-new-name'),
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              LengthLimitingTextInputFormatter(maxShiftNameLength),
            ],
            decoration: InputDecoration(
              errorText: _error(shown, ShiftTypeField.name),
            ),
            onChanged: _onName,
          ),
        ),
        const SizedBox(height: Sp.xl),
        LabeledField(
          label: l10n.shiftTypesCodeLabel,
          helper: l10n.shiftTypesCodeHelper,
          child: TextField(
            key: const ValueKey('import-new-code'),
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            inputFormatters: const [ShiftCodeFormatter()],
            decoration: InputDecoration(
              errorText: _error(shown, ShiftTypeField.code),
            ),
            onChanged: (text) {
              _codeTouched = true;
              _update(_draft.copyWith(code: text));
            },
          ),
        ),
        const SizedBox(height: Sp.xl),
        LabeledField(
          label: l10n.shiftTypesPreviewLabel,
          child: ShiftTypePreview(
            shift: ShiftType(
              id: 'preview',
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
            ),
          ),
        ),
        const SizedBox(height: Sp.xl),
        LabeledField(
          label: l10n.shiftTypesColorLabel,
          child: ShiftColorGrid(
            selected: _draft.colorValue,
            onChanged: (value) => _update(_draft.copyWith(colorValue: value)),
          ),
        ),
        const SizedBox(height: Sp.xl),
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
                  key: ValueKey('import-new-category-$key'),
                  label: label,
                  selected: _draft.category == category,
                  onTap: () => _update(_draft.copyWith(category: category)),
                ),
            ],
          ),
        ),
        const SizedBox(height: Sp.xl),
        ShiftTypeTimesSection(
          keyPrefix: 'import-new',
          draft: _draft,
          onNoTimes: (noTimes) => _update(_draft.copyWith(hasTimes: !noTimes)),
          onPickStart: () => _pickTime(start: true),
          onPickEnd: () => _pickTime(start: false),
          onSplit: (split) => _update(
            split ? _draft.withSplit() : _draft.copyWith(clearSegment2: true),
          ),
          onUseSplitTemplate: null,
          onPickSecondStart: () => _pickTime(start: true, second: true),
          onPickSecondEnd: () => _pickTime(start: false, second: true),
          splitError: _error(shown, ShiftTypeField.segment2),
        ),
        const SizedBox(height: Sp.section),
        PrimaryButton(
          key: const ValueKey('import-new-save'),
          label: l10n.importNewTypeUse,
          onPressed: () {
            setState(() => _showErrors = true);
            if (shown.isNotEmpty) return;
            Navigator.of(context).pop(_draft);
          },
        ),
      ],
    );
  }
}
