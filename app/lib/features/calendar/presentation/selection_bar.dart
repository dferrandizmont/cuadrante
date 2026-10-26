import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/text_measure.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/icons/selection_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/schedule_controller.dart';
import '../application/selection_controller.dart';
import '../domain/range_editing.dart';
import 'history_feedback.dart';
import 'selection_sheets.dart';

/// Header of selection mode: «SELECCIÓN» and a line that says how to choose.
class SelectionHeader extends StatelessWidget {
  const SelectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    // With very large text the hint is three lines that push the calendar
    // off a small phone (H-T04-3): the header keeps its word and the hint
    // stays for screen readers.
    final compact = textScaleOf(context) >= kCompactTextScale;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          header: true,
          container: true,
          label: compact
              ? '${l10n.selectionHeader}. ${l10n.selectionHint}'
              : null,
          excludeSemantics: compact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectionHeader.toUpperCase(),
                style: type.label.copyWith(color: colors.accentText),
              ),
              if (!compact)
                Text(
                  l10n.selectionHint,
                  style: type.meta.copyWith(color: colors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom bar of selection mode (design B, like the paint sheet): how many
/// days are chosen, undo / redo, «Cancelar», and one round tool per action.
/// Every action is ONE undo step of the schedule.
class SelectionBar extends ConsumerWidget {
  const SelectionBar({super.key, this.card = false});

  /// In the pane of the two-pane month: a rounded card with the margin of the
  /// other cards of the pane, not a bar stuck to the bottom of the screen.
  final bool card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final selection = ref.watch(selectionControllerProvider);
    final history = ref.watch(scheduleControllerProvider);
    final clip = ref.watch(dayClipboardProvider);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final has = !selection.isEmpty;

    final actions = _SelectionActions(context, ref);

    ButtonStyle roundStyle() => IconButton.styleFrom(
      fixedSize: const Size.square(Disc.round),
      backgroundColor: colors.surfaceRaised,
      disabledBackgroundColor: colors.surfaceRaised,
      foregroundColor: colors.textPrimary,
      disabledForegroundColor: colors.textMuted,
      shape: const CircleBorder(),
    );

    return Semantics(
      container: true,
      label: l10n.selectionBarLabel,
      child: DecoratedBox(
        key: const ValueKey('selection-bar'),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: card
              ? const BorderRadius.all(Radius.circular(Rad.sheet))
              : const BorderRadius.vertical(top: Radius.circular(Rad.sheet)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Sp.maxContentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.page, Sp.m, Sp.s, 0),
                    child: _CountRow(
                      count: l10n.selectionCount(selection.count),
                      buttons: [
                        IconButton(
                          key: const ValueKey('undo'),
                          tooltip: l10n.undo,
                          style: roundStyle(),
                          icon: Icon(AppIcons.undo),
                          onPressed: history.canUndo
                              ? () => undoWithFeedback(context, controller)
                              : null,
                        ),
                        IconButton(
                          key: const ValueKey('redo'),
                          tooltip: l10n.redo,
                          style: roundStyle(),
                          icon: Icon(AppIcons.redo),
                          onPressed: history.canRedo
                              ? () => redoWithFeedback(context, controller)
                              : null,
                        ),
                        IconButton(
                          key: const ValueKey('selection-cancel'),
                          tooltip: l10n.selectionCancel,
                          style: roundStyle(),
                          icon: Icon(AppIcons.close),
                          onPressed: ref
                              .read(selectionControllerProvider.notifier)
                              .exit,
                        ),
                      ],
                    ),
                  ),
                  _ActionTools(
                    grid: card,
                    tools: [
                      _Tool(
                        'selection-set',
                        l10n.selectionSetShift,
                        AppIcons.paint,
                        has ? actions.setShift : null,
                      ),
                      _Tool(
                        'selection-double',
                        l10n.selectionDouble,
                        AppIcons.add,
                        has ? actions.doubleShift : null,
                      ),
                      _Tool(
                        'selection-clear',
                        l10n.selectionClear,
                        AppIcons.erase,
                        has ? actions.clear : null,
                      ),
                      _Tool(
                        'selection-reset',
                        l10n.selectionReset,
                        AppIcons.undo,
                        has ? actions.reset : null,
                      ),
                      _Tool(
                        'selection-copy',
                        l10n.selectionCopy,
                        AppIcons.copy,
                        has ? actions.copy : null,
                      ),
                      _Tool(
                        'selection-cut',
                        l10n.selectionCut,
                        SelectionIcons.cut,
                        has ? actions.cut : null,
                      ),
                      _Tool(
                        'selection-paste',
                        l10n.selectionPaste,
                        SelectionIcons.paste,
                        has && clip != null ? () => actions.paste(clip) : null,
                      ),
                      _Tool(
                        'selection-repeat',
                        l10n.selectionRepeat,
                        AppIcons.pattern,
                        has ? actions.repeat : null,
                      ),
                      _Tool(
                        'selection-note',
                        l10n.selectionNote,
                        AppIcons.note,
                        has ? actions.note : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The flows behind the bar's tools. Each edits the schedule through ONE
/// controller call and tells the user, with «Deshacer» while it is still the
/// latest thing done.
class _SelectionActions {
  _SelectionActions(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  ScheduleController get _schedule =>
      ref.read(scheduleControllerProvider.notifier);
  SelectionController get _selection =>
      ref.read(selectionControllerProvider.notifier);
  List<CivilDate> get _days => ref.read(selectionControllerProvider).sorted;

  /// Snack bar for [step]: «Deshacer» undoes it only while it is the latest
  /// step; `null` means nothing changed.
  void _report(ScheduleChange? step, String message) {
    final l10n = context.l10n;
    final schedule = _schedule;
    final feedbackContext = ScaffoldMessenger.of(context).context;
    showTrackedSnackBar(
      ref,
      context,
      content: Text(step == null ? l10n.selectionNothingChanged : message),
      action: step == null
          ? null
          : SnackBarAction(
              label: l10n.undo,
              onPressed: () =>
                  undoWithFeedback(feedbackContext, schedule, step: step),
            ),
    );
  }

  Future<void> setShift() async {
    final l10n = context.l10n;
    final days = _days;
    final id = await showShiftPickerSheet(
      context,
      title: l10n.selectionSetShiftTitle,
      help: l10n.selectionSetShiftHelp,
    );
    if (id == null || !context.mounted) return;
    _report(
      _schedule.setShiftOnDays(days, id),
      l10n.selectionChanged(days.length),
    );
  }

  Future<void> doubleShift() async {
    final l10n = context.l10n;
    final days = _days;
    final id = await showShiftPickerSheet(
      context,
      title: l10n.selectionDoubleTitle,
      help: l10n.selectionDoubleHelp,
    );
    if (id == null || !context.mounted) return;
    _report(
      _schedule.doubleShiftOnDays(days, id),
      l10n.selectionChanged(days.length),
    );
  }

  void clear() {
    final days = _days;
    _report(
      _schedule.clearDays(days),
      context.l10n.selectionChanged(days.length),
    );
  }

  void reset() {
    final days = _days;
    _report(
      _schedule.resetDaysToPattern(days),
      context.l10n.selectionChanged(days.length),
    );
  }

  /// Copies the chosen days and clears the choice (the mode stays), so the
  /// next tap picks the day the block is pasted on.
  void copy() {
    final days = _days;
    final clip = DayClipboard.capture(
      ref.read(scheduleControllerProvider).schedule,
      days,
      sourceCalendarId: ref.read(scheduleControllerProvider).calendarId,
    );
    ref.read(dayClipboardProvider.notifier).set(clip);
    _selection.clear();
    showTrackedSnackBar(
      ref,
      context,
      content: Text(context.l10n.selectionCopied(clip.length)),
    );
  }

  /// Copies the chosen days and clears them: ONE undo step; undoing brings
  /// the days back and the copy stays on the clipboard.
  void cut() {
    final result = _selection.cut();
    if (result == null) return;
    final l10n = context.l10n;
    final schedule = _schedule;
    final feedbackContext = ScaffoldMessenger.of(context).context;
    final step = result.step;
    showTrackedSnackBar(
      ref,
      context,
      content: Text(l10n.selectionCutDone(result.clip.length)),
      action: step == null
          ? null
          : SnackBarAction(
              label: l10n.undo,
              onPressed: () =>
                  undoWithFeedback(feedbackContext, schedule, step: step),
            ),
    );
  }

  Future<void> paste(DayClipboard clip) async {
    final start = ref.read(selectionControllerProvider).first;
    if (start == null) return;
    final includeNotes = await showPasteSheet(
      context,
      clip: clip,
      start: start,
      notesMove: pasteMovesAnnotations(clip),
    );
    if (includeNotes == null || !context.mounted) return;
    final step = _schedule.pasteDays(clip, start, includeNotes: includeNotes);
    if (step != null) ref.read(dayClipboardProvider.notifier).pasted(clip);
    _report(step, context.l10n.selectionPasted(clip.length));
  }

  Future<void> repeat() async {
    final days = _days;
    final block = DayClipboard.capture(
      ref.read(scheduleControllerProvider).schedule,
      days,
      sourceCalendarId: ref.read(scheduleControllerProvider).calendarId,
    );
    final choice = await showRepeatSheet(context, block: block);
    if (choice == null || !context.mounted) return;
    _report(
      _schedule.repeatDays(
        days,
        choice.times,
        includeNotes: choice.includeNotes,
      ),
      context.l10n.selectionRepeated(choice.times),
    );
  }

  Future<void> note() async {
    final days = _days;
    final text = await showSelectionNoteSheet(context);
    if (text == null || !context.mounted) return;
    _report(
      _schedule.setNoteOnDays(days, text),
      context.l10n.selectionChanged(days.length),
    );
  }
}

/// «3 días» and the undo / redo / cancel buttons. The count goes beside the
/// buttons when its longest word fits there, else above them: at x2.0 on a
/// 320 dp phone «Ningún día» next to three round buttons was cut with an
/// ellipsis.
class _CountRow extends StatelessWidget {
  const _CountRow({required this.count, required this.buttons});

  final String count;
  final List<Widget> buttons;

  static const double _buttonsWidth =
      3 * Disc.round + 2 * Sp.s; // three discs and the gaps between them

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.tabular(context.type.headline);
    final text = Semantics(
      liveRegion: true,
      child: Text(count, key: const ValueKey('selection-count'), style: style),
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: Sp.s),
          buttons[i],
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        final word = longestWordWidth(context, count, style);
        final beside = word + Sp.s <= box.maxWidth - _buttonsWidth;
        if (beside) {
          return Row(
            children: [
              Expanded(child: text),
              row,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: Sp.s),
              child: text,
            ),
            Align(alignment: Alignment.centerRight, child: row),
          ],
        );
      },
    );
  }
}

/// One tool of the bar.
class _Tool {
  const _Tool(this.key, this.label, this.icon, this.onTap);

  final String key;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

/// In the pane the tools wrap into rows with complete visible labels. On a
/// portrait phone they scroll sideways. Every tool is as wide as the longest word
/// of any label needs, so no label breaks inside a word however large the
/// text is, and all the round buttons sit on one line; with very large text
/// the labels give way to the tooltip (see [kCompactTextScale]).
class _ActionTools extends StatelessWidget {
  const _ActionTools({required this.tools, required this.grid});

  final bool grid;

  final List<_Tool> tools;

  @override
  Widget build(BuildContext context) {
    final compact = textScaleOf(context) >= kCompactTextScale;
    final style = context.type.caption;
    final minWidth = Disc.round + 2 * Sp.s;
    final width = compact
        ? Disc.round + Sp.s
        : tools.fold<double>(
            minWidth,
            (widest, tool) => math.max(
              widest,
              longestWordWidth(context, tool.label, style) + 2 * Sp.xs,
            ),
          );
    if (grid) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, Sp.l),
        child: LayoutBuilder(
          builder: (context, box) {
            final minimum = tools.fold<double>(
              Disc.round,
              (widest, tool) => math.max(
                widest,
                longestWordWidth(context, tool.label, style) + 2 * Sp.xs,
              ),
            );
            // Two rows at normal text size; grow downward as text needs
            // wider tiles, preserving complete labels and touch targets.
            final columns = math.min(
              5,
              math.max(1, (box.maxWidth / minimum).floor()),
            );
            final tileWidth = box.maxWidth / columns;
            return Wrap(
              key: const ValueKey('selection-tools-grid'),
              runSpacing: Sp.s,
              children: [
                for (final tool in tools)
                  _ActionTool(tool: tool, width: tileWidth, showLabel: true),
              ],
            );
          },
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        Sp.page - Sp.s,
        Sp.xs,
        Sp.page - Sp.s,
        Sp.m,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final tool in tools)
            _ActionTool(tool: tool, width: width, showLabel: !compact),
        ],
      ),
    );
  }
}

/// A round 48 dp tool with its name below (or as tooltip when [showLabel] is
/// off); greyed out when it has no action.
class _ActionTool extends StatelessWidget {
  const _ActionTool({
    required this.tool,
    required this.width,
    required this.showLabel,
  });

  final _Tool tool;
  final double width;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onTap = tool.onTap;
    final enabled = onTap != null;
    Widget content = SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Sp.xs),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: Disc.round,
              child: Icon(tool.icon, color: colors.textPrimary),
            ),
          ),
          const SizedBox(height: Sp.xs),
          if (showLabel)
            Text(
              tool.label,
              textAlign: TextAlign.center,
              style: context.type.caption.copyWith(color: colors.textPrimary),
            ),
          const SizedBox(height: Sp.xs),
        ],
      ),
    );
    if (!showLabel) content = Tooltip(message: tool.label, child: content);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      label: tool.label,
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(
          key: ValueKey(tool.key),
          customBorder: RoundedRectangleBorder(borderRadius: Rad.inputRadius),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}
