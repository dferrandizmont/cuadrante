import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/format/text_measure.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/icons/selection_icons.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/schedule_controller.dart';
import '../domain/range_editing.dart';
import 'shift_badge.dart';
import 'shift_format.dart';

/// The sheets of the selection actions. Each one only *asks*: it returns what
/// the user chose (or `null` when dismissed) and the caller edits the
/// schedule, so every action stays ONE undo step.

/// Palette sheet for «Poner turno…» / «Doblar con…»: the id of the shift
/// chosen, or `null`.
Future<String?> showShiftPickerSheet(
  BuildContext context, {
  required String title,
  required String help,
}) => showAppSheet<String>(
  context: context,
  padded: true,
  builder: (_) => _ShiftPickerSheet(title: title, help: help),
);

class _ShiftPickerSheet extends ConsumerWidget {
  const _ShiftPickerSheet({required this.title, required this.help});

  final String title;
  final String help;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.type;
    final colors = context.colors;
    final palette = ref.watch(
      scheduleControllerProvider.select((s) => s.palette),
    );
    // Names wrap between words (two lines are fine), so a tile is as wide as
    // the longest word of any name: «Libre disposición» and «Guardia 24 h»
    // used to be cut with an ellipsis, and at x2.0 «Noche» and «Noche 12 h»
    // both read «Noc…» (H-T04-6).
    final caption = type.caption;
    final tileWidth = palette.fold<double>(
      _ShiftTile.minWidth,
      (widest, shift) => math.max(
        widest,
        longestWordWidth(context, shift.name, caption) + 2 * Sp.xs,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: type.headline)),
        const SizedBox(height: Sp.xs),
        Text(help, style: type.meta.copyWith(color: colors.textMuted)),
        const SizedBox(height: Sp.m),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            for (final shift in palette)
              _ShiftTile(
                key: ValueKey('pick-shift-${shift.id}'),
                shift: shift,
                width: tileWidth,
                onTap: () => Navigator.pop(context, shift.id),
              ),
          ],
        ),
      ],
    );
  }
}

/// A shift of the palette as a badge with its name below.
class _ShiftTile extends StatelessWidget {
  const _ShiftTile({
    super.key,
    required this.shift,
    required this.width,
    required this.onTap,
  });

  final ShiftType shift;
  final double width;
  final VoidCallback onTap;

  static const double minWidth = Disc.l + 2 * Sp.m;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: shift.spoken(l10n, format),
      onTap: onTap,
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: Rad.inputRadius),
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Sp.xs),
              ShiftBadge(shift: shift),
              const SizedBox(height: Sp.xs),
              Text(
                shift.name,
                textAlign: TextAlign.center,
                style: context.type.caption.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
              const SizedBox(height: Sp.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Nota…»: the text for every chosen day. Returns the text (never blank), the
/// empty string for «Quitar notas», or `null` when dismissed.
Future<String?> showSelectionNoteSheet(BuildContext context) =>
    showAppSheet<String>(
      context: context,
      padded: true,
      builder: (_) => const _NoteSheet(),
    );

class _NoteSheet extends StatefulWidget {
  const _NoteSheet();

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.selectionNoteTitle, style: context.type.headline),
        ),
        const SizedBox(height: Sp.m),
        TextField(
          key: const ValueKey('selection-note-field'),
          controller: _text,
          autofocus: true,
          minLines: 2,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.selectionNoteHint),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Sp.l),
        PrimaryButton(
          key: const ValueKey('selection-note-save'),
          label: l10n.selectionNoteSave,
          icon: AppIcons.note,
          onPressed: _text.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _text.text.trim()),
        ),
        const SizedBox(height: Sp.s),
        SecondaryButton(
          key: const ValueKey('selection-note-remove'),
          label: l10n.selectionNoteRemove,
          icon: AppIcons.erase,
          onPressed: () => Navigator.pop(context, ''),
        ),
      ],
    );
  }
}

/// Confirmation of «Pegar»: where the block starts and, when the copied days
/// have notes, the «Incluir notas» switch (off). With [notesMove] (a cut clip
/// whose notes are really off the source, see [pasteMovesAnnotations]) there is
/// no switch: its notes travel and the sheet says so. Returns whether to
/// include the notes, or `null` when cancelled.
Future<bool?> showPasteSheet(
  BuildContext context, {
  required DayClipboard clip,
  required CivilDate start,
  bool notesMove = false,
}) => showAppSheet<bool>(
  context: context,
  padded: true,
  builder: (_) => _PasteSheet(clip: clip, start: start, notesMove: notesMove),
);

class _PasteSheet extends StatefulWidget {
  const _PasteSheet({
    required this.clip,
    required this.start,
    required this.notesMove,
  });

  final DayClipboard clip;
  final CivilDate start;
  final bool notesMove;

  @override
  State<_PasteSheet> createState() => _PasteSheetState();
}

class _PasteSheetState extends State<_PasteSheet> {
  bool _notes = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final format = AppDateFormat.of(context);
    final start = widget.start;
    final date = format.longDate(DateTime(start.year, start.month, start.day));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.selectionPasteTitle, style: type.headline),
        ),
        const SizedBox(height: Sp.s),
        Text(
          l10n.selectionPasteSummary(widget.clip.length, date),
          key: const ValueKey('paste-summary'),
          style: type.body,
        ),
        // The block keeps its gaps: say the last day it reaches, which can be
        // days past the start (H-T04-8).
        if (widget.clip.span > 1) ...[
          const SizedBox(height: Sp.xs),
          Text(
            _reach(l10n, format, start, widget.clip.pasteEnd(start)),
            key: const ValueKey('paste-reach'),
            style: type.body,
          ),
        ],
        const SizedBox(height: Sp.xs),
        Text(
          l10n.selectionPasteReplaces,
          style: type.meta.copyWith(color: colors.textMuted),
        ),
        if (widget.clip.hasNotes && widget.notesMove) ...[
          const SizedBox(height: Sp.s),
          Text(
            l10n.selectionCutNotesMove,
            key: const ValueKey('paste-cut-notes'),
            style: type.meta.copyWith(color: colors.textMuted),
          ),
        ] else if (widget.clip.hasNotes) ...[
          const SizedBox(height: Sp.s),
          SwitchListTile(
            key: const ValueKey('paste-notes'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.selectionIncludeNotes),
            subtitle: Text(l10n.selectionIncludeNotesHelp),
            value: _notes,
            onChanged: (value) => setState(() => _notes = value),
          ),
        ],
        const SizedBox(height: Sp.l),
        PrimaryButton(
          key: const ValueKey('paste-confirm'),
          label: l10n.selectionPasteConfirm,
          icon: SelectionIcons.paste,
          onPressed: () => Navigator.pop(context, _notes || widget.notesMove),
        ),
        const SizedBox(height: Sp.s),
        SecondaryButton(
          key: const ValueKey('paste-cancel'),
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// «Se pegará del lun 3 al dom 9 de noviembre.»; when the block crosses a
/// month, each end carries its month («del mar 27 de octubre al mar 3 de
/// noviembre»).
String _reach(
  AppLocalizations l10n,
  AppDateFormat format,
  CivilDate start,
  CivilDate end,
) {
  DateTime date(CivilDate d) => DateTime(d.year, d.month, d.day);
  String withMonth(CivilDate d) =>
      '${format.weekdayDay(date(d))} de ${format.monthName(date(d))}';
  final sameMonth = start.year == end.year && start.month == end.month;
  return l10n.selectionPasteReach(
    sameMonth ? format.weekdayDay(date(start)) : withMonth(start),
    withMonth(end),
  );
}

/// What «Repetir…» asks for.
class RepeatChoice {
  const RepeatChoice({required this.times, required this.includeNotes});

  final int times;
  final bool includeNotes;
}

/// «Repetir…»: how many times (1–52), with a live preview of the days it
/// changes and where it ends. Returns the choice or `null` when cancelled.
Future<RepeatChoice?> showRepeatSheet(
  BuildContext context, {
  required DayClipboard block,
}) => showAppSheet<RepeatChoice>(
  context: context,
  padded: true,
  builder: (_) => _RepeatSheet(block: block),
);

class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({required this.block});

  final DayClipboard block;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  int _times = 1;
  bool _notes = false;

  void _set(int times) =>
      setState(() => _times = times.clamp(1, maxRepeatTimes));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final format = AppDateFormat.of(context);
    final block = widget.block;
    final end = block.repeatEnd(_times);
    final preview = l10n.selectionRepeatPreview(
      block.length * _times,
      format.longDate(DateTime(end.year, end.month, end.day)),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.selectionRepeatTitle, style: type.headline),
        ),
        const SizedBox(height: Sp.m),
        Row(
          children: [
            IconButton(
              key: const ValueKey('repeat-less'),
              tooltip: l10n.selectionRepeatLess,
              icon: Icon(AppIcons.arrowDown),
              onPressed: _times > 1 ? () => _set(_times - 1) : null,
            ),
            Expanded(
              child: Text(
                l10n.selectionRepeatTimes(_times),
                key: const ValueKey('repeat-times'),
                textAlign: TextAlign.center,
                style: AppTypography.tabular(type.headline),
              ),
            ),
            IconButton(
              key: const ValueKey('repeat-more'),
              tooltip: l10n.selectionRepeatMore,
              icon: Icon(AppIcons.arrowUp),
              onPressed: _times < maxRepeatTimes
                  ? () => _set(_times + 1)
                  : null,
            ),
          ],
        ),
        Slider(
          key: const ValueKey('repeat-slider'),
          min: 1,
          max: maxRepeatTimes.toDouble(),
          divisions: maxRepeatTimes - 1,
          label: '$_times',
          value: _times.toDouble(),
          semanticFormatterCallback: (v) =>
              l10n.selectionRepeatTimes(v.round()),
          onChanged: (value) => _set(value.round()),
        ),
        Text(
          preview,
          key: const ValueKey('repeat-preview'),
          style: type.meta.copyWith(color: colors.textMuted),
        ),
        if (block.hasNotes) ...[
          const SizedBox(height: Sp.s),
          SwitchListTile(
            key: const ValueKey('repeat-notes'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.selectionIncludeNotes),
            subtitle: Text(l10n.selectionIncludeNotesHelp),
            value: _notes,
            onChanged: (value) => setState(() => _notes = value),
          ),
        ],
        const SizedBox(height: Sp.l),
        PrimaryButton(
          key: const ValueKey('repeat-confirm'),
          label: l10n.selectionRepeatConfirm,
          icon: AppIcons.pattern,
          onPressed: () => Navigator.pop(
            context,
            RepeatChoice(times: _times, includeNotes: _notes),
          ),
        ),
        const SizedBox(height: Sp.s),
        SecondaryButton(
          key: const ValueKey('repeat-cancel'),
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
