import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../holidays/domain/holiday.dart';
import '../../holidays/presentation/holiday_names.dart';
import '../../schedule/domain/schedule_domain.dart';
import 'holiday_label.dart';
import 'shift_format.dart';
import 'shift_icon_glyph.dart';

/// Horizontal room the cell keeps free for its own marks: the border of a
/// chosen day ([Sp.selectedBorder], the thickest one the cell draws) is
/// painted **over** the content of the cell, so the code, the icon and the
/// time are laid out inside it and the border never covers them
/// (H-T04-4).
///
/// The thickest border is reserved always, not only when the day is chosen:
/// the code of a cell does not change size when it is chosen, and the
/// content of a cell never moves under the finger.
const double cellContentInset = Sp.selectedBorder;

/// Spoken description of a day: "lunes 12 de octubre, hoy, Noche de 22:00 a
/// 06:00, festivo: Fiesta Nacional de España, con nota".
String daySemanticsLabel(
  BuildContext context, {
  required ResolvedDay day,
  required Holiday? holiday,
  required bool isToday,
  bool selected = false,
}) {
  final l10n = context.l10n;
  final format = AppDateFormat.of(context);
  final date = day.date;
  final parts = <String>[
    format.weekdayDayMonth(DateTime(date.year, date.month, date.day)),
    if (isToday) l10n.daySemanticsToday,
    // Chosen in selection mode: said in the label, not only shown (H-T04-4).
    if (selected) l10n.selectionCellSelected,
    if (day.shifts.isEmpty)
      l10n.daySemanticsNoShift
    else
      day.shifts
          .map((s) => s.spoken(l10n, format))
          .reduce((a, b) => l10n.daySemanticsAnd(a, b)),
    if (holiday != null) holidaySpoken(l10n, holidayDisplayName(l10n, holiday)),
    if (day.note != null && day.note!.isNotEmpty) l10n.daySemanticsNote,
    if (day.overtimeMinutes > 0)
      l10n.daySemanticsOvertime(durationText(l10n, day.overtimeMinutes)),
    if (day.earlyLeaveMinutes > 0)
      l10n.daySemanticsEarlyLeave(durationText(l10n, day.earlyLeaveMinutes)),
  ];
  return parts.join(', ');
}

/// One day of the month grid (`docs/diseno.md`, "Celda del día"): a soft
/// tint of the shift on `surface`, the day number top-left, the code in the
/// shift's ink with its compact time, and a 6 dp bottom bar in the shift
/// colour (equal segments with several shifts, whose codes stack). A holiday
/// turns the number red and adds a dot, a note adds a clip, today gets an
/// inner ring and a bolder number. Never colour alone: code and time are
/// always there (the time is the first thing to go when space is tight, and
/// a split shift that does not fit shows the start of its first range).
///
/// A shift with an icon (docs/paridad.md, A8) shows it BEFORE the code, but
/// only when icon and code fit side by side in the cell without shrinking the
/// code (see [shiftIconFitsInCell]); otherwise, and always on a day with
/// several shifts, the cell shows the code alone. A day with overtime or early
/// leave carries a small plus at the top right, opposite the day number and
/// before the note clip and the holiday dot (the semantics label says the
/// minutes). It sits in the row of the number, which the band of the code and
/// time never enters, so it can not cover them.
///
/// While a paint stroke runs, [painted] cells fill with the shift's disc and
/// a ring in its bar colour.
///
/// A day chosen in selection mode gets a thick border in the selection colour
/// and a slightly darker background (the disc of the shift): the shape tells
/// it apart from the ring of today and from the open day, and nothing is
/// drawn over the code or the time (H-T04-4).
class DayCell extends StatefulWidget {
  const DayCell({
    super.key,
    required this.day,
    required this.holiday,
    required this.inMonth,
    required this.isToday,
    this.painted = false,
    this.selected = false,
    this.focused = false,
    this.onTap,
    this.onLongPress,
    this.focusNode,
    this.onMoveFocus,
  });

  final ResolvedDay day;
  final Holiday? holiday;

  /// False for the days of the neighbouring months shown to fill the grid.
  final bool inMonth;
  final bool isToday;

  /// The finger has touched this day in the stroke in progress.
  final bool painted;

  /// Chosen in selection mode: a thick border and a slightly darker
  /// background (not colour alone).
  final bool selected;

  /// The day open in the right pane of the two-pane month: a ring in the
  /// selection colour (no darker background: it is not a choice of days).
  final bool focused;

  /// Accessibility tap and long press. Pointer taps and drags go through the
  /// grid's single gesture layer, not through the cell.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;

  /// Grid-relative arrow movement: one day horizontally, one week vertically.
  final ValueChanged<int>? onMoveFocus;

  static const double _noteIconSize = 11;
  static const double _dotSize = 6;
  static const double _extrasIconSize = 11;

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell> {
  bool _keyboardFocused = false;

  @override
  void initState() {
    super.initState();
    // A month change recreates the date-keyed cell but keeps its positional
    // node. Attaching an already focused node need not emit onFocusChange.
    _keyboardFocused = widget.focusNode?.hasFocus ?? false;
  }

  @override
  void didUpdateWidget(covariant DayCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _keyboardFocused = widget.focusNode?.hasFocus ?? false;
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) widget.onTap?.call();
      return KeyEventResult.handled;
    }
    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp => -7,
      LogicalKeyboardKey.arrowDown => 7,
      _ => null,
    };
    if (delta != null && widget.onMoveFocus != null) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        widget.onMoveFocus!(delta);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final DayCell(
      :day,
      :holiday,
      :inMonth,
      :isToday,
      :painted,
      :selected,
      :focused,
      :onTap,
      :onLongPress,
    ) = widget;
    final colors = context.colors;
    final type = context.type;
    final scaler = MediaQuery.textScalerOf(context);
    final brightness = colors.brightness;
    final swatches = [
      for (final s in day.shifts) s.swatch(brightness, outOfMonth: !inMonth),
    ];
    final multi = swatches.length > 1;
    final lead = swatches.isEmpty
        ? ShiftSwatch.none(brightness, outOfMonth: !inMonth)
        : swatches.first;
    final hasNote = day.note != null && day.note!.isNotEmpty;
    final radius = Rad.cellRadius;

    // The background of the cell: the tint of the shift, its disc (a bit
    // darker) when the day is chosen or being painted, and `surfaceRaised`
    // for a day without shift. The ink of the shift keeps its contrast on
    // the disc, so the code never loses readability.
    final background = swatches.isEmpty
        ? (painted || (selected && inMonth) ? colors.surfaceRaised : lead.tint)
        : (painted || (selected && inMonth) ? lead.disc : lead.tint);

    final numberColor = lead.legible(
      holiday != null
          ? colors.holiday
          : inMonth
          ? colors.textSecondary
          : colors.textMuted,
      background: background,
    );
    final secondaryColor = lead.legible(
      colors.textMuted,
      background: background,
    );

    // Room kept free at the top of the first band for the day number.
    final numberReserve = textHeight(type.cellDay, scaler) + Sp.xs + Sp.hair;

    // Dark mode selects in amber, light mode in the accent (docs/diseno.md).
    final selectColor = colors.isDark ? colors.highlight : colors.accent;

    final ringColor = selected || focused
        ? selectColor
        : painted
        ? (swatches.isEmpty ? colors.borderStrong : lead.bar)
        : isToday
        ? colors.todayRing
        : null;

    // The chosen day has a thick border (the shape tells it apart from the
    // ring of today and from the open day); the other rings keep their
    // stroke.
    final ringWidth = selected
        ? Sp.selectedBorder
        : focused
        ? Sp.selectionRing
        : Sp.ring;

    final body = ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (swatches.isEmpty)
            ColoredBox(color: background)
          else
            Column(
              children: [
                for (var i = 0; i < swatches.length; i++)
                  Expanded(
                    child: _ShiftBand(
                      shift: day.shifts[i],
                      swatch: swatches[i],
                      painted: painted,
                      selected: selected && inMonth,
                      compact: multi,
                      topReserve: i == 0 ? numberReserve : 0,
                      bottomReserve: i == swatches.length - 1 ? Sp.bar : 0,
                    ),
                  ),
              ],
            ),
          if (swatches.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: Sp.bar,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in swatches)
                    Expanded(child: ColoredBox(color: s.bar)),
                ],
              ),
            ),
          Positioned(
            top: Sp.xs,
            left: Sp.s,
            right: Sp.xs,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${day.date.day}',
                  maxLines: 1,
                  style: type.cellDay.copyWith(
                    color: numberColor,
                    // Today is not marked by the ring colour alone: its
                    // number is the boldest.
                    fontWeight: isToday ? FontWeight.w900 : null,
                  ),
                ),
              ),
            ),
          ),
          // Everything that marks the day sits in one row at the top right,
          // opposite the day number: overtime / early-leave plus, note clip
          // and holiday dot. The first band keeps room for the number row, so
          // none of them can ever land on the code or the time.
          if (holiday != null || hasNote || day.hasExtras)
            Positioned.fill(
              child: _DayMarks(
                date: day.date,
                extras: day.hasExtras,
                note: hasNote,
                holiday: holiday != null,
                isToday: isToday,
                color: secondaryColor,
                dotColor: colors.holiday,
              ),
            ),
          if (ringColor != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  // The mark of a chosen day: the border, not a badge over
                  // the code or the time (H-T04-4).
                  key: selected
                      ? ValueKey('selected-mark-${day.date.toIso()}')
                      : null,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: ringColor, width: ringWidth),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final paddedBody = Padding(
      padding: const EdgeInsets.all(Sp.cellGap / 2),
      child: body,
    );
    final semantics = Semantics(
      container: true,
      button: true,
      selected: selected || focused,
      focusable: onTap != null,
      focused: _keyboardFocused,
      excludeSemantics: true,
      label: daySemanticsLabel(
        context,
        day: day,
        holiday: holiday,
        isToday: isToday,
        selected: selected,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      child: _keyboardFocused
          ? DecoratedBox(
              key: ValueKey('keyboard-focus-${day.date.toIso()}'),
              // Outside the existing day/selection ring; no layout changes.
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: colors.accent, width: Sp.ring),
              ),
              child: paddedBody,
            )
          : paddedBody,
    );
    if (onTap == null) return semantics;
    return Focus(
      focusNode: widget.focusNode,
      includeSemantics: false,
      onFocusChange: (value) => setState(() => _keyboardFocused = value),
      onKeyEvent: _onKeyEvent,
      child: semantics,
    );
  }
}

/// The height of a cell that has room for the time under the code (the code
/// and the time lines, the row of the day number, the bottom bar and the gap
/// between cells), at the user's text size, up to [limit] dp: the two-pane
/// month keeps its rows at least this tall and scrolls instead (a landscape
/// phone), so a cell is never only a code.
///
/// The lines are measured, not estimated (see [textHeight]): the space
/// reserved for a line is the space it really takes, so the content of the
/// cell never overflows it.
///
/// The limit grows with the text (80 dp at the normal size), so the code of
/// the cell can grow too instead of being squeezed (H-T18-5).
double dayCellHeightWithTime(BuildContext context, {double? limit}) {
  final type = context.type;
  final scaler = MediaQuery.textScalerOf(context);
  final height =
      textHeight(type.cellDay, scaler) +
      Sp.xs +
      Sp.hair +
      textHeight(type.cellCode, scaler) +
      textHeight(type.cellTime, scaler) +
      Sp.bar +
      Sp.cellGap;
  final max = limit ?? 80 * scaler.scale(1);
  return height.clamp(0, max);
}

/// Equal-height bands each keep their own code and time. The first also
/// reserves the day number, the last the bar, so the tallest band determines
/// the common height (including when a timed shift follows an untimed one).
double dayCellHeightForShifts(BuildContext context, List<ShiftType> shifts) {
  if (shifts.length < 2) return dayCellHeightWithTime(context);
  final type = context.type;
  final scaler = MediaQuery.textScalerOf(context);
  final number = textHeight(type.cellDay, scaler) + Sp.xs + Sp.hair;
  var bandHeight = 0.0;
  for (var i = 0; i < shifts.length; i++) {
    final height =
        textHeight(type.cellCodeMulti, scaler) +
        (shifts[i].hasTimes ? textHeight(type.cellTime, scaler) : 0) +
        (i == 0 ? number : 0) +
        (i == shifts.length - 1 ? Sp.bar : 0);
    bandHeight = math.max(bandHeight, height);
  }
  return math.max(
    dayCellHeightWithTime(context),
    bandHeight * shifts.length + Sp.cellGap,
  );
}

/// The marks of a day, in one row at the top right (opposite the day number):
/// the plus of overtime / early leave, the clip of the note and the dot of a
/// holiday, right to left. The first band of the cell keeps that row free, so
/// they can never land on the code or the time. In a cramped cell (a 320 dp
/// phone, large text, several marks) the row shrinks to what the number
/// leaves, down to 60 % of its size, rather than leave the cell.
class _DayMarks extends StatelessWidget {
  const _DayMarks({
    required this.date,
    required this.extras,
    required this.note,
    required this.holiday,
    required this.isToday,
    required this.color,
    required this.dotColor,
  });

  final CivilDate date;
  final bool extras;
  final bool note;
  final bool holiday;
  final bool isToday;
  final Color color;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final numberStyle = context.type.cellDay.copyWith(
      fontWeight: isToday ? FontWeight.w900 : null,
    );
    final painter = TextPainter(
      text: TextSpan(text: '${date.day}', style: numberStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final numberWidth = painter.width;
    painter.dispose();

    final widths = [
      if (extras) DayCell._extrasIconSize,
      if (note) DayCell._noteIconSize,
      if (holiday) DayCell._dotSize,
    ];
    final natural =
        widths.fold<double>(0, (a, b) => a + b) + (widths.length - 1) * Sp.xs;
    final inset = holiday ? Sp.s : Sp.xs;

    return LayoutBuilder(
      builder: (context, box) {
        // Number: 8 dp from the left edge, then a gap before the marks.
        final free = box.maxWidth - inset - Sp.s - numberWidth - Sp.xs;
        final width = math
            .max(free, natural * 0.6)
            .clamp(0.0, box.maxWidth - inset);
        return Padding(
          padding: EdgeInsets.only(top: Sp.xs + Sp.hair, right: inset),
          child: Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: width,
              height: DayCell._noteIconSize,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: DayCell._noteIconSize,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (extras)
                        Icon(
                          AppIcons.extras,
                          key: ValueKey('extras-mark-${date.toIso()}'),
                          size: DayCell._extrasIconSize,
                          color: color,
                        ),
                      if (extras && (note || holiday))
                        const SizedBox(width: Sp.xs),
                      if (note)
                        Icon(
                          AppIcons.note,
                          size: DayCell._noteIconSize,
                          color: color,
                        ),
                      if (note && holiday) const SizedBox(width: Sp.xs),
                      if (holiday)
                        DecoratedBox(
                          key: ValueKey('holiday-dot-${date.toIso()}'),
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(
                            dimension: DayCell._dotSize,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One shift's share of the cell: its tint, code and time.
///
/// The code grows with the user's text, up to what fits the cell (by its
/// width and by the room the time leaves): with large text it reads as big
/// as the cell allows instead of shrinking to a speck (H-T18-5). The time is
/// always there: the grid gives the rows the height it needs (see
/// [dayCellHeightWithTime]) and the screen scrolls when they do not fit.
class _ShiftBand extends StatelessWidget {
  const _ShiftBand({
    required this.shift,
    required this.swatch,
    required this.painted,
    required this.selected,
    required this.compact,
    required this.topReserve,
    required this.bottomReserve,
  });

  final ShiftType shift;
  final ShiftSwatch swatch;
  final bool painted;

  /// The day is chosen: the band is a bit darker (the disc of the shift).
  final bool selected;

  /// Several shifts share the cell: smaller code and no icon.
  final bool compact;

  /// Space kept free at the top (day number) and bottom (bar).
  final double topReserve;
  final double bottomReserve;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final scaler = MediaQuery.textScalerOf(context);
    final codeStyle = compact ? type.cellCodeMulti : type.cellCode;
    final icon = compact ? null : shift.icon;
    final background = painted || selected ? swatch.disc : swatch.tint;
    final ink = swatch.legible(swatch.ink, background: background);
    final timeColor = swatch.legible(
      context.colors.textMuted,
      background: background,
    );

    return ColoredBox(
      color: background,
      child: Padding(
        padding: EdgeInsets.only(top: topReserve, bottom: bottomReserve),
        child: LayoutBuilder(
          builder: (context, box) {
            final timeStyle = type.cellTime;
            // The room of the content of the cell: it keeps the width of its
            // own thickest border free, so the border of a chosen day never
            // covers the code, the icon or the time.
            final room = box.maxWidth - 2 * cellContentInset;
            // The time of the cell: the whole range of the shift when it
            // fits, the start of the shift when it does not. At least the
            // start is always there (H-T18-6).
            final time = cellTimeInCell(
              shift: shift,
              style: timeStyle,
              scaler: scaler,
              width: box.maxWidth,
            );
            // The time keeps its line whatever happens: the cell is never
            // only a code («nunca solo color»).
            final timeLine = time == null
                ? 0.0
                : textHeight(timeStyle.copyWith(fontSize: time.size), scaler);
            // The code grows with the user's text, up to what fits the cell.
            final size = cellCodeSize(
              code: shift.code,
              style: codeStyle,
              scaler: scaler,
              width: box.maxWidth,
              height: box.maxHeight - timeLine,
            );
            final sizedCodeStyle = codeStyle.copyWith(
              fontSize: size,
              color: ink,
            );
            final codeText = Text(
              shift.code,
              maxLines: 1,
              style: sizedCodeStyle,
            );
            // Even the minimum can be wider than a narrow cell (e.g. WWW
            // at text x2). Fit that code alone, preserving the time's size.
            final Widget code =
                textWidth(shift.code, sizedCodeStyle, scaler) > room
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: cellContentInset,
                    ),
                    child: FittedBox(fit: BoxFit.scaleDown, child: codeText),
                  )
                : codeText;
            // The icon never stands taller than the code it precedes, and it
            // is only measured when the shift has one.
            final double iconSize = icon == null
                ? 0
                : math.min(
                    scaler.scale(cellIconSize),
                    textHeight(sizedCodeStyle, scaler),
                  );
            final showIcon =
                icon != null &&
                shiftIconFitsInCell(
                  code: shift.code,
                  codeStyle: sizedCodeStyle,
                  scaler: scaler,
                  width: box.maxWidth,
                  iconSize: iconSize,
                );
            final column = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShiftIconGlyph(
                        key: const ValueKey('cell-icon'),
                        icon: icon,
                        size: iconSize,
                        color: ink,
                      ),
                      const SizedBox(width: Sp.hair),
                      code,
                    ],
                  )
                else
                  code,
                if (time != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time.text,
                          maxLines: 1,
                          softWrap: false,
                          style: timeStyle.copyWith(
                            fontSize: time.size,
                            color: timeColor,
                          ),
                        ),
                        // The shift has two segments and the cell does not say
                        // when the second one starts: a dot says it (H-T23-1).
                        if (time.twoSegments) ...[
                          const SizedBox(width: Sp.hair),
                          Container(
                            key: const ValueKey('cell-two-segments'),
                            width: Sp.cellSegmentDot,
                            height: Sp.cellSegmentDot,
                            decoration: BoxDecoration(
                              color: ink,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
            // The grid reserves these lines. A long time must never scale
            // the code with it: only the time representation adapts.
            return Center(
              // Small previews may still need fitting; the month reserves enough
              // height for every band's code and time before reaching here.
              child:
                  compact &&
                      box.maxHeight <
                          textHeight(sizedCodeStyle, scaler) + timeLine
                  ? FittedBox(fit: BoxFit.scaleDown, child: column)
                  : column,
            );
          },
        ),
      ),
    );
  }
}

/// The height of a line of [style] at the user's text scale: the real height
/// of the text, not the nominal one (the engine rounds the line up to a whole
/// pixel, and the font's own leading can add more), so the space reserved for
/// a line is the space the line really takes.
///
/// The glyphs do not change the height of the line, so a digit is enough to
/// measure it.
///
/// The measures are cached by style and scale (see [_textHeights]): the
/// grid measures the same styles in every cell, and the answer is always the
/// same.
double textHeight(TextStyle style, TextScaler scaler) {
  final key = (style, scaler);
  final cached = _textHeights.remove(key);
  if (cached != null) {
    _textHeights[key] = cached;
    return cached;
  }
  final painter = TextPainter(
    text: TextSpan(text: '0', style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final height = painter.height;
  painter.dispose();
  _rememberMeasure(_textHeights, key, height);
  return height;
}

/// Heights and widths already measured, by style (and text, for the widths)
/// and text scale. The styles of the design are few and measured over and
/// over; the size a code is fitted to is different in every cell, so the
/// cache keeps only the last [_textMeasureCacheSize] measures.
final LinkedHashMap<Object, double> _textHeights = LinkedHashMap();
final LinkedHashMap<Object, double> _textWidths = LinkedHashMap();

/// How many measures are kept. The styles of the design are measured in
/// every cell of the grid, so they stay in the cache; the fitted sizes, one
/// per cell, are the ones that fall out.
const int _textMeasureCacheSize = 256;

/// Read-only cache keys, oldest first, for verifying the bounded LRU policy.
@visibleForTesting
({List<Object> heights, List<Object> widths}) get debugCellMeasureKeys => (
  heights: List.unmodifiable(_textHeights.keys),
  widths: List.unmodifiable(_textWidths.keys),
);

@visibleForTesting
void debugClearCellMeasures() {
  _textHeights.clear();
  _textWidths.clear();
}

/// Remembers a measure and drops the oldest ones when the cache is full.
void _rememberMeasure(
  LinkedHashMap<Object, double> cache,
  Object key,
  double value,
) {
  cache[key] = value;
  while (cache.length > _textMeasureCacheSize) {
    cache.remove(cache.keys.first);
  }
}

/// The time of a cell: the whole range of the shift ("22–06") when it fits
/// in the width of the cell, the start of the shift ("22") when it does not.
/// At least the start is always there, in small: the cell is never only a
/// code (H-T18-6, «nunca solo color»).
///
/// A split shift says the start of each range ("09/17") when its two full
/// ranges do not fit, and keeps the start alone ("09") with the dot of the
/// two segments when even that does not fit (H-T23-1).
///
/// The size is the one of [style] (the user's text), down to [minSize] when
/// the width of the cell asks for it. Null when the shift has no schedule.
({String text, double size, bool twoSegments})? cellTimeInCell({
  required ShiftType shift,
  required TextStyle style,
  required TextScaler scaler,
  required double width,
  double minSize = AppTypography.cellTimeMinSize,
}) {
  final base = style.fontSize!;
  // The room of the cell: the width of its own thickest border is kept
  // free, so the border of a chosen day never covers the text.
  final room = width - 2 * cellContentInset;
  final full = shift.compactTimeRange;
  if (full == null) return null;

  /// The size at which [text] fits in the room of the cell.
  double sizeThatFits(String text, double available) {
    final measured = textWidth(text, style, scaler);
    return measured <= 0 ? base : base * available / measured;
  }

  /// Whether [text] fits in the room of the cell at [minSize].
  bool fitsAtMin(String text, double available) =>
      textWidth(text, style.copyWith(fontSize: minSize), scaler) <= available;

  ({String text, double size}) pick(String text, double available) =>
      (text: text, size: sizeThatFits(text, available).clamp(minSize, base));

  if (fitsAtMin(full, room)) {
    final picked = pick(full, room);
    return (text: picked.text, size: picked.size, twoSegments: false);
  }
  final starts = shift.compactSplitStarts;
  if (starts != null && fitsAtMin(starts, room)) {
    final picked = pick(starts, room);
    return (text: picked.text, size: picked.size, twoSegments: false);
  }
  final startRoom =
      room - (shift.hasSegment2 ? Sp.hair + Sp.cellSegmentDot : 0);
  final start = shift.compactStart ?? full;
  // Minutes stay visible when they fit. In a narrow cell keep the hour
  // (09 for 09:30); the exact start and both segments remain in the detail
  // and the cell's spoken label.
  final compactStart = start.split(':').first;
  final picked = pick(
    fitsAtMin(start, startRoom) ? start : compactStart,
    startRoom,
  );
  return (text: picked.text, size: picked.size, twoSegments: shift.hasSegment2);
}

/// The size (dp, before the user's text scale) at which the code of a cell
/// is drawn: the size of [style], but never bigger than what fits the cell
/// — by its [width] and by the [height] it has left — and never smaller than
/// [minSize], so the code always reads (H-T18-5).
///
/// The width is measured with the user's text scale, like the rest of the
/// cell, and keeps the width of the cell's own border free (see
/// [cellContentInset]): the code is drawn inside the border of a chosen day.
/// The height is the room the line of the code has, and it is the *real*
/// height of the line that counts (see [textHeight]): a cell shorter than the
/// one the month grid reserves (the picture that is shared, the small
/// preview) gets a smaller code instead of an overflow.
double cellCodeSize({
  required String code,
  required TextStyle style,
  required TextScaler scaler,
  required double width,
  required double height,
  double minSize = AppTypography.cellCodeMinSize,
}) {
  final base = style.fontSize!;
  // By width: the code as it would be drawn, measured with the user's text.
  // The room of the cell keeps the width of its own thickest border free.
  final measured = textWidth(code, style, scaler);
  final byWidth = measured <= 0
      ? base
      : base *
            (width - 2 * cellContentInset).clamp(0, double.infinity) /
            measured;
  final floor = math.min(minSize, base);
  var size = math.min(base, byWidth);
  // By height: the line of the code must fit in what is left.
  var line = textHeight(style.copyWith(fontSize: size), scaler);
  for (var i = 0; i < 8 && line > height && size > floor; i++) {
    size = line <= 0 ? floor : math.max(floor, size * height / line - 0.05);
    line = textHeight(style.copyWith(fontSize: size), scaler);
  }
  return size.clamp(floor, base);
}

/// The width of [text] in [style] with the user's text scale.
///
/// The measures are cached (see [textHeight]): the same code is measured in
/// every cell of the grid.
double textWidth(String text, TextStyle style, TextScaler scaler) {
  final key = (text, style, scaler);
  final cached = _textWidths.remove(key);
  if (cached != null) {
    _textWidths[key] = cached;
    return cached;
  }
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  _rememberMeasure(_textWidths, key, width);
  return width;
}

/// Size (dp, before text scaling) of the icon beside the code in a cell.
const double cellIconSize = 12;

/// The rule that decides whether a cell [width] draws the icon before the
/// code: only when icon + gap + the code at its own size fit inside the
/// border of the cell (the thickest one, [cellContentInset] at each side)
/// with a margin of [Sp.hair] / 2 at each side, so the icon never makes the
/// code smaller and the border never covers it.
/// Measured with the user's text scale. On a 320 dp phone (cells of about
/// 42 dp, since the grid keeps the same page padding as the cards) a
/// single letter shows its icon at normal text size and not with larger text;
/// a code of 2 or 3 characters keeps the code alone until the cell is wide
/// (tablets, landscape).
bool shiftIconFitsInCell({
  required String code,
  required TextStyle codeStyle,
  required TextScaler scaler,
  required double width,
  double? iconSize,
}) {
  final needed =
      textWidth(code, codeStyle, scaler) +
      Sp.hair +
      (iconSize ?? scaler.scale(cellIconSize));
  return needed <= width - 2 * cellContentInset - Sp.hair;
}
