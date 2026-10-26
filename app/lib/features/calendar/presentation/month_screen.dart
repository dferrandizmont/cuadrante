import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/icons/selection_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/adaptive.dart';
import '../../../core/widgets/page_body.dart';
import '../../patterns/presentation/pattern_pick_banner.dart';
import '../../schedule/domain/civil_date.dart';
import '../../summary/presentation/month_sharing.dart';
import '../application/open_day.dart';
import '../application/month_presentation.dart';
import '../application/paint_controller.dart';
import '../application/schedule_controller.dart';
import '../application/selection_controller.dart';
import '../application/visible_month.dart';
import '../application/week_layout.dart';
import '../../settings/application/preferences_controller.dart';
import 'calendar_switcher.dart';
import 'day_cell.dart';
import 'day_detail_sheet.dart';
import 'day_pane.dart';
import 'month_grid.dart';
import 'month_list.dart';
import 'month_presentation_control.dart';
import 'month_tip.dart';
import 'paint_bar.dart';
import 'selection_bar.dart';
import 'shift_format.dart';
import 'today_card.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Home (`docs/diseno.md`): the date and settings, the "today" card, the month
/// title with its arrows, the weekday row and the month grid; paint mode swaps
/// the top for its header and puts the tools sheet at the bottom (floating
/// "Pintar" button otherwise).
///
/// On wide screens ([Adaptive.useSplit]: a landscape phone, a tablet) the same
/// screen has two panes (`docs/diseno.md`, «Pantallas anchas»): the month on
/// the left, with the whole height for the grid, and on the right the date and
/// buttons, then the "today" card with the next days, the detail of the chosen
/// day, or the tools of paint / selection mode.
class MonthScreen extends ConsumerStatefulWidget {
  const MonthScreen({super.key});

  /// Room under the grid for the floating button (56 dp + margin).
  static const double _fabClearance = Sp.fabClearance;

  /// Side padding of the grid. The cells keep `Sp.cellGap / 2` of their own
  /// inside, so their visible edge lands at `Sp.l` from the screen edge: the
  /// same page padding as the header, the "today" card and the month row.
  static const double _gridInset = Sp.l - Sp.cellGap / 2;

  /// The right pane is this share of the width, within [_paneMin] and
  /// [_paneMax] dp: 366 dp on a 915 dp landscape phone (as wide as a phone in
  /// portrait, which is what its content was made for), 440 dp on a tablet.
  static const double _paneShare = 0.4;
  static const double _paneMin = 300;
  static const double _paneMax = 440;

  @override
  ConsumerState<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends ConsumerState<MonthScreen> {
  final _monthScrollController = ScrollController();
  double? _gridMinHeight;
  (CivilDate, int, bool)? _gridLayout;

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  void _scrollPaintGrid(bool down) {
    if (!_monthScrollController.hasClients) return;
    final position = _monthScrollController.position;
    // Keep overlap between pages. On a viewport barely taller than one row,
    // still advance a touch target rather than creeping a few pixels per tap.
    final step = math.max(
      Sp.touch,
      position.viewportDimension - dayCellHeightWithTime(context),
    );
    final target = (position.pixels + (down ? step : -step)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final duration = Motion.of(context, Motion.state);
    if (duration == Duration.zero) {
      _monthScrollController.jumpTo(target);
    } else {
      unawaited(
        _monthScrollController.animateTo(
          target,
          duration: duration,
          curve: Motion.curve,
        ),
      );
    }
  }

  /// Whether the last build had two panes: a change to one column (a rotation
  /// to portrait) brings the open day back as a sheet.
  bool? _wasSplit;

  void _followLayout(bool split) {
    final was = _wasSplit;
    _wasSplit = split;
    if (was != true || split) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final date = ref.read(openDayProvider);
      // Only if nothing is on top of the month (another screen, a sheet).
      if (date == null || ModalRoute.of(context)?.isCurrent != true) return;
      unawaited(showDayDetail(context, date: date, followsLayout: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final painting = ref.watch(paintControllerProvider.select((p) => p.active));
    final selecting = ref.watch(
      selectionControllerProvider.select((s) => s.settled),
    );
    // Both modes put their own header on top and their own bar at the bottom.
    final editing = painting || selecting;
    final split = Adaptive.useSplit(MediaQuery.sizeOf(context));
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final windowWidth = MediaQuery.sizeOf(context).width;
    final splitWidth = math.min(windowWidth, Adaptive.splitMaxWidth);
    final paneWidth = (splitWidth * MonthScreen._paneShare).clamp(
      MonthScreen._paneMin,
      MonthScreen._paneMax,
    );
    _followLayout(split);
    final dayOpen = ref.watch(openDayProvider.select((d) => d != null));

    // A failed save: the controller has already reloaded what is stored.
    ref.listen(scheduleControllerProvider.select((s) => s.saveErrors), (
      previous,
      next,
    ) {
      if (next > (previous ?? 0)) {
        showTrackedSnackBar(ref, context, content: Text(l10n.saveFailed));
      }
    });
    // A notice (the «N días cambiados · Deshacer» of the selection bar) floats
    // over the bottom of the grid: while it is up the screen can scroll the
    // last row clear of it (H-T04-1).
    final noticeRoom = ref.watch(snackBarCoverProvider);

    final Widget body;
    if (split) {
      body = LayoutBuilder(
        builder: (context, box) {
          final width = math.min(box.maxWidth, Adaptive.splitMaxWidth);
          final pane = (width * MonthScreen._paneShare).clamp(
            MonthScreen._paneMin,
            MonthScreen._paneMax,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: Row(
                children: [
                  // The month has the whole height: the date, the card and
                  // the tools live in the pane.
                  Expanded(
                    child: _monthScroll(
                      top: const [_MonthNavigation(), _WeekdayRow()],
                      painting: painting,
                      bottomRoom: 0,
                      noticeRoom: noticeRoom,
                      ringOpenDay: true,
                      minCellHeight: dayCellHeightWithTime(context),
                    ),
                  ),
                  VerticalDivider(
                    key: const ValueKey('pane-divider'),
                    width: 1,
                    thickness: 1,
                    color: colors.border,
                  ),
                  SizedBox(
                    width: pane,
                    child: DayPane(
                      header: const _DateHeader(),
                      // The floating button sits over this pane.
                      bottomRoom:
                          (keyboardUp ? 0 : MonthScreen._fabClearance) +
                          MediaQuery.viewPaddingOf(context).bottom,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      body = PageBody(
        child: Column(
          children: [
            // Fixed in paint mode, so "Listo" is always within reach.
            if (painting) const PaintHeader(),
            if (painting) const PatternPickBanner(),
            if (selecting) const SelectionHeader(),
            Expanded(
              child: _monthScroll(
                top: [
                  if (!editing) ...const [
                    _DateHeader(),
                    TodayCard(),
                    MonthTipCard(),
                  ],
                  const _MonthNavigation(),
                  const _WeekdayRow(),
                ],
                painting: painting,
                // The body runs under the system navigation bar
                // (SafeArea bottom: false) while the button floats above it,
                // so its inset counts too.
                bottomRoom: editing
                    ? 0.0
                    : MonthScreen._fabClearance +
                          MediaQuery.viewPaddingOf(context).bottom,
                noticeRoom: noticeRoom,
                // The rows of the grid are tall enough for the code and its
                // time at the user's text size: the code grows with the text
                // and the time is never hidden (the screen scrolls when they
                // do not fit).
                minCellHeight: dayCellHeightWithTime(context),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      // The system back button leaves selection mode before anything else,
      // then closes the day open in the pane.
      canPop:
          !ref.watch(selectionControllerProvider.select((s) => s.active)) &&
          !(split && dayOpen),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (ref.read(selectionControllerProvider).active) {
          ref.read(selectionControllerProvider.notifier).exit();
        } else {
          ref.read(openDayProvider.notifier).close();
        }
      },
      child: AppSnackBarLayout(
        // Notices stay beside the tools, including when the pane scrolls.
        endInset: split ? paneWidth + (windowWidth - splitWidth) / 2 : 0,
        child: Scaffold(
          body: SafeArea(bottom: false, child: body),
          floatingActionButton: editing || keyboardUp
              ? null
              : FloatingActionButton.extended(
                  // No matching FAB on another route. Scaffold can keep an
                  // outgoing copy while the keyboard hides/shows this one;
                  // neither copy should participate in Hero transitions.
                  heroTag: null,
                  onPressed: ref.read(paintControllerProvider.notifier).toggle,
                  icon: Icon(AppIcons.paint, color: colors.highlight),
                  label: Text(l10n.paintFab),
                ),
          // With two panes the tools are in the right pane.
          bottomNavigationBar: split
              ? null
              : painting
              ? const PaintBar()
              : selecting
              ? const SelectionBar()
              : null,
        ),
      ),
    );
  }

  /// The [top] (rows above the grid) and the grid, in a screen that scrolls
  /// when its parts do not fit: the grid takes the rest of the height, but
  /// never less than [MonthGrid.minHeight] (large text, small screens, a
  /// landscape phone), and then the whole screen scrolls instead of squeezing
  /// the cells. [bottomRoom] is kept free under the grid (the floating
  /// button).
  Widget _monthScroll({
    required List<Widget> top,
    required bool painting,
    required double bottomRoom,
    required double? noticeRoom,
    bool ringOpenDay = false,
    double minCellHeight = MonthGrid.defaultMinCellHeight,
  }) {
    final listing =
        ref.watch(monthPresentationProvider) == MonthPresentation.list;
    var minGridHeight = minCellHeight * 6;
    if (!listing) {
      final month = ref.watch(visibleMonthProvider);
      final weekStart = ref.watch(
        preferencesProvider.select((p) => p.weekStart),
      );
      final start = monthGridStart(month, weekStart);
      final layout = (month, weekStart, ringOpenDay);
      if (_gridLayout != layout) {
        _gridLayout = layout;
        _gridMinHeight = null;
      }
      final (schedule, strokeEmpty) = ref.watch(
        scheduleControllerProvider.select(
          (s) => (s.schedule, s.strokeDays.isEmpty),
        ),
      );
      // Keep the outer scroll extent stable too: shrinking it can move the
      // grid under the finger or replace its gesture layer with a scroller.
      if (!painting || strokeEmpty || _gridMinHeight == null) {
        _gridMinHeight = monthGridMinimumRowHeights(
          context,
          schedule.resolveRange(start, start.addDays(41)),
          minCellHeight: minCellHeight,
        ).reduce((a, b) => a + b);
      }
      minGridHeight = _gridMinHeight!;
    }
    final scroll = CustomScrollView(
      controller: _monthScrollController,
      key: const ValueKey('month-scroll'),
      scrollCacheExtent: const ScrollCacheExtent.pixels(Sp.maxContentWidth * 2),
      // Dragging a day always paints. The separate buttons below move the
      // viewport while painting, including when navigation takes two lines.
      physics: painting && !listing
          ? const NeverScrollableScrollPhysics()
          : null,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              for (final child in top)
                if (!listing || child is! _WeekdayRow) ...[child],
            ],
          ),
        ),
        if (listing) ...[
          const SliverToBoxAdapter(child: MonthList()),
          SliverToBoxAdapter(child: SizedBox(height: bottomRoom)),
        ] else
          SliverLayoutBuilder(
            builder: (context, box) {
              final rest =
                  box.viewportMainAxisExtent - box.precedingScrollExtent;
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: math.max(minGridHeight + bottomRoom, rest),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      MonthScreen._gridInset,
                      0,
                      MonthScreen._gridInset,
                      bottomRoom,
                    ),
                    child: MonthGrid(
                      ringOpenDay: ringOpenDay,
                      minCellHeight: minCellHeight,
                    ),
                  ),
                ),
              );
            },
          ),
        if (noticeRoom != null)
          SliverToBoxAdapter(
            child: SizedBox(
              key: const ValueKey('notice-clearance'),
              height: noticeRoom,
            ),
          ),
      ],
    );
    return Column(
      // Keep the month's Scrollable first for existing scroll actions.
      // Semantic sort keys retain the visual reading order.
      verticalDirection: VerticalDirection.up,
      children: <Widget>[
        Semantics(
          sortKey: const OrdinalSortKey(0),
          child: const MonthPresentationControl(),
        ),
        Expanded(
          child: Semantics(sortKey: const OrdinalSortKey(1), child: scroll),
        ),
        SafeArea(
          top: false,
          // In portrait the tools sheet already reserves the system inset.
          bottom: Adaptive.useSplit(MediaQuery.sizeOf(context)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Expanded(child: MonthSelectDaysControl()),
              if (painting && !listing)
                IconButton(
                  key: const ValueKey('paint-scroll-up'),
                  tooltip: context.l10n.paintScrollUp,
                  icon: Icon(AppIcons.arrowUp),
                  onPressed: () => _scrollPaintGrid(false),
                ),
              if (painting && !listing)
                IconButton(
                  key: const ValueKey('paint-scroll-down'),
                  tooltip: context.l10n.paintScrollDown,
                  icon: Icon(AppIcons.arrowDown),
                  onPressed: () => _scrollPaintGrid(true),
                ),
            ],
          ),
        ),
      ].reversed.toList(),
    );
  }
}

/// "Lunes, 19 de octubre" and the settings button.
class _DateHeader extends ConsumerWidget {
  const _DateHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(minuteClockProvider);
    final open = Adaptive.useSplit(MediaQuery.sizeOf(context))
        ? ref.watch(openDayProvider)
        : null;
    final displayedDate = open == null
        ? now
        : DateTime(open.year, open.month, open.day);
    final sharing = ref.watch(monthSharingProvider);

    // The three buttons are 48 dp each with a 24 dp glyph, so a 4 dp inset puts
    // the glyph of the last one at `Sp.l` from the edge, flush with the
    // "today" card and the grid below.
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.xs, Sp.xs, 0),
      child: LayoutBuilder(
        builder: (context, box) => Column(
          children: [
            if (open != null)
              Row(
                children: [
                  Expanded(child: _DateText(now: displayedDate)),
                  TextButton(
                    key: const ValueKey('pane-today-button'),
                    onPressed: () {
                      ref.read(openDayProvider.notifier).close();
                      ref.read(visibleMonthProvider.notifier).today();
                    },
                    child: Text(context.l10n.calendarToday),
                  ),
                ],
              ),
            Row(
              children: [
                // Takes whatever the switcher and the buttons leave, so they stay
                // pinned to the trailing edge (a `Flexible` switcher next to an
                // `Expanded` date would split the free space in two and leave a
                // hole before the buttons).
                if (open == null) Expanded(child: _DateText(now: now)),
                if (open != null) const Spacer(),
                // Hidden with one calendar. With two its name is ellipsized, and
                // it never takes more than 55 % of what the buttons leave, so the
                // date and the switcher fit on a 320 dp phone with large text.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.max(
                      0,
                      (box.maxWidth - _buttonsWidth) * 0.55,
                    ),
                  ),
                  child: const CalendarSwitcher(),
                ),
                ..._buttons(context, ref, sharing),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Share, agenda and settings: three touch targets, flush right.
  static const double _buttonsWidth = 3 * Sp.touch;

  List<Widget> _buttons(BuildContext context, WidgetRef ref, bool sharing) {
    final l10n = context.l10n;
    final colors = context.colors;
    return [
      IconButton(
        key: const ValueKey('share-month'),
        tooltip: l10n.shareMonthTooltip,
        icon: Icon(AppIcons.share, color: colors.textMuted),
        onPressed: sharing
            ? null
            : () =>
                  shareMonthImage(context, ref, ref.read(visibleMonthProvider)),
      ),
      IconButton(
        key: const ValueKey('open-agenda'),
        tooltip: l10n.agendaOpenTooltip,
        icon: Icon(SelectionIcons.agenda, color: colors.textMuted),
        onPressed: () => context.push(AppRoutes.agenda),
      ),
      IconButton(
        tooltip: l10n.settingsOpenTooltip,
        icon: Icon(AppIcons.settings, color: colors.textMuted),
        onPressed: () => context.push(AppRoutes.settings),
      ),
    ];
  }
}

/// "Martes, 20 de octubre", or "Mar 20 oct" when the long form does not fit
/// on one line (large text, narrow phones). Never cut with an ellipsis or in
/// the middle of a word: if even the short form is too wide it wraps between
/// words.
class _DateText extends StatelessWidget {
  const _DateText({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final format = AppDateFormat.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style = context.type.body.copyWith(
      fontWeight: FontWeight.w600,
      color: context.colors.textMuted,
    );
    final long = capitalize(format.longDate(now));
    final short = capitalize(format.shortDate(now));
    return LayoutBuilder(
      builder: (context, box) {
        bool fits(String text) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width <= box.maxWidth;
        }

        final text = fits(long) ? long : short;
        return Text(
          text,
          key: const ValueKey('month-date'),
          style: style,
          // The short form can still be wider than a very squeezed row: it
          // wraps at its spaces instead of losing letters.
          maxLines: 3,
        );
      },
    );
  }
}

/// The month ("Octubre", with the year when it is not the current one),
/// previous / next arrows and, away from the current month, "Hoy".
class _MonthNavigation extends ConsumerWidget {
  const _MonthNavigation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    final month = ref.watch(visibleMonthProvider);
    final controller = ref.read(visibleMonthProvider.notifier);
    final now = ref.watch(minuteClockProvider);
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final date = DateTime(month.year, month.month);
    final monthName = capitalize(format.monthName(date));
    final year = '${month.year}';
    final hasYear = month.year != now.year;
    final title = hasYear ? capitalize(format.monthYear(date)) : monthName;

    // The controls of the month row: the year and the summary, then "Hoy"
    // and the two arrows. They are one row when they fit; when they do not
    // (the English "Today" at 320 dp with a big text) they go on two rows,
    // in the same reading order, and none of them loses its touch target.
    final Widget? todayButton = isCurrentMonth
        ? null
        : TextButton(
            onPressed: controller.today,
            child: Text(l10n.calendarToday),
          );
    final secondary = <Widget>[
      IconButton(
        key: const ValueKey('open-year'),
        tooltip: l10n.yearOpenTooltip,
        icon: Icon(AppIcons.yearView),
        onPressed: () => context.push(AppRoutes.year),
      ),
      IconButton(
        key: const ValueKey('open-summary'),
        tooltip: l10n.summaryOpenTooltip,
        icon: Icon(AppIcons.summary),
        onPressed: () => context.push(AppRoutes.summaryFor(month)),
      ),
    ];
    final arrows = <Widget>[
      IconButton(
        tooltip: l10n.calendarPreviousMonth,
        icon: Icon(AppIcons.chevronLeft),
        onPressed: controller.previous,
      ),
      IconButton(
        tooltip: l10n.calendarNextMonth,
        icon: Icon(AppIcons.chevronRight),
        onPressed: controller.next,
      ),
    ];
    final primary = <Widget>[?todayButton, ...arrows];

    return Padding(
      // Like the date row: 4 dp of inset puts the glyph of the last 48 dp button
      // (the 24 dp arrow) at `Sp.l` from the edge, flush with the settings
      // gear above, the cards and the grid.
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.xs, 0),
      child: LayoutBuilder(
        builder: (context, box) {
          final scaler = MediaQuery.textScalerOf(context);
          final style = context.type.title;
          // The width the title needs on one line, at the reading size: it is
          // never shrunk, it goes to two lines or the buttons go below.
          final needed = textWidth(title, style, scaler);
          final monthNeeded = textWidth(monthName, style, scaler);
          // The width the controls need: the four icon buttons (48 dp each)
          // and the "Hoy" one, which is as wide as its text.
          final todayWidth = _todayWidth(
            context,
            l10n,
            scaler,
            withToday: !isCurrentMonth,
          );
          final secondaryWidth = secondary.length * Sp.touch;
          final primaryWidth = todayWidth + arrows.length * Sp.touch;
          final room = box.maxWidth - secondaryWidth - primaryWidth;
          // One line next to the buttons; the month and the year on two lines
          // when they do not fit; the buttons below when even the month does
          // not fit (H-T18-7, punto 5 de docs/propuestas-diseno.md).
          final oneRow = needed <= room;
          final twoLines = !oneRow && monthNeeded <= room;

          // The rows of the controls: one row when they fit, two when they
          // do not (the year and the summary above, "Hoy" and the arrows
          // below, in the same reading order).
          final List<List<Widget>> rows;
          if (secondaryWidth + primaryWidth <= box.maxWidth) {
            rows = [
              [...secondary, ...primary],
            ];
          } else if (primaryWidth <= box.maxWidth) {
            rows = [secondary, primary];
          } else {
            // Not even "Hoy" with the arrows fits: three rows.
            rows = [
              secondary,
              if (todayButton != null) [todayButton],
              arrows,
            ];
          }

          final Widget titleText;
          if (oneRow) {
            titleText = _fitted(Text(title, style: style));
          } else if (twoLines) {
            titleText = _MonthTitleLines(
              monthName: monthName,
              year: hasYear ? year : null,
              style: style,
            );
          } else if (needed <= box.maxWidth) {
            // The buttons go below: the title has the whole width.
            titleText = _fitted(Text(title, style: style));
          } else {
            titleText = _MonthTitleLines(
              monthName: monthName,
              year: hasYear ? year : null,
              style: style,
              shrink: true,
            );
          }

          final titleWidget = Semantics(
            header: true,
            button: true,
            // «Octubre, elegir mes»: it is a button, not just a heading
            // (H-T18-7). Tapping the month opens the whole year.
            label: l10n.calendarPickMonth(title),
            excludeSemantics: true,
            onTap: () => context.push(AppRoutes.year),
            child: InkWell(
              key: const ValueKey('month-title'),
              borderRadius: Rad.chipSmallRadius,
              onTap: () => context.push(AppRoutes.year),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Sp.touch),
                child: titleText,
              ),
            ),
          );

          if (oneRow || twoLines) {
            // The controls are one row here: the title and they fit.
            return Row(
              children: [
                Expanded(child: titleWidget),
                ...rows.first,
              ],
            );
          }
          // The title needs the whole width: the controls go below it, in one
          // row or in two when they do not fit.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: Sp.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final row in rows)
                      Row(mainAxisSize: MainAxisSize.min, children: row),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The width of the «Hoy» button: its label and the padding of the theme,
/// never less than the minimum width of a button.
double _todayWidth(
  BuildContext context,
  AppLocalizations l10n,
  TextScaler scaler, {
  required bool withToday,
}) {
  if (!withToday) return 0;
  return math.max(
    Sp.touch + Sp.l,
    textWidth(l10n.calendarToday, context.type.button, scaler) + 2 * Sp.l,
  );
}

/// The title of the month on two lines: the month and the year, at the
/// reading size (never shrunk, never cut). [shrink] is the last resort, for
/// a month name that does not fit even on a line of its own.
class _MonthTitleLines extends StatelessWidget {
  const _MonthTitleLines({
    required this.monthName,
    required this.year,
    required this.style,
    this.shrink = false,
  });

  final String monthName;
  final String? year;
  final TextStyle style;
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    final month = Text(monthName, maxLines: 1, style: style);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shrink) _fitted(month) else month,
        if (year != null) Text(year!, maxLines: 1, style: style),
      ],
    );
  }
}

/// [child] as it is drawn, but never wider than the room it has: the last
/// resort of a title that does not fit, so the text is never cut.
Widget _fitted(Widget child) => FittedBox(
  fit: BoxFit.scaleDown,
  alignment: Alignment.centerLeft,
  child: child,
);

/// L M X J V S D (Monday first) or D L M X J V S (Sunday first, by
/// preference), with room for the column of week numbers when it is on.
class _WeekdayRow extends ConsumerWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    final weekStart = ref.watch(preferencesProvider.select((p) => p.weekStart));
    final weekNumbers = ref.watch(
      preferencesProvider.select((p) => p.weekNumbers),
    );
    // Indexed by DateTime.weekday - 1.
    final initials = [
      l10n.calendarWeekdayMon,
      l10n.calendarWeekdayTue,
      l10n.calendarWeekdayWed,
      l10n.calendarWeekdayThu,
      l10n.calendarWeekdayFri,
      l10n.calendarWeekdaySat,
      l10n.calendarWeekdaySun,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MonthScreen._gridInset + Sp.cellGap / 2,
        Sp.xs,
        MonthScreen._gridInset + Sp.cellGap / 2,
        0,
      ),
      child: Row(
        children: [
          if (weekNumbers) const SizedBox(width: MonthGrid.weekNumberWidth),
          for (final weekday in weekdayOrder(weekStart))
            Expanded(
              key: ValueKey('weekday-$weekday'),
              child: Semantics(
                label: format.weekdayLong(
                  // 5 Jan 2026 is a Monday.
                  DateTime(2026, 1, 4 + weekday),
                ),
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Sp.xs),
                  child: Center(
                    child: Text(
                      initials[weekday - 1],
                      style: context.type.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
