import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/features/calendar/application/month_presentation.dart';
import 'package:cuadrante/features/calendar/application/open_day.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/application/selection_controller.dart';
import 'package:cuadrante/features/calendar/application/visible_month.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart';
import 'package:cuadrante/features/calendar/presentation/month_list.dart';
import 'package:cuadrante/features/calendar/presentation/month_presentation_control.dart';
import 'package:cuadrante/features/patterns/application/pattern_start_pick.dart';
import 'package:cuadrante/features/patterns/presentation/pattern_wizard_screen.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';
import '../../support/app_harness.dart' as full;
import 'harness.dart';
import 'rendered_cell_text.dart';
import '../../support/real_font.dart';

const _day = CivilDate(2026, 10, 19);
Finder _key(String key) => find.byKey(ValueKey(key));
Finder _row(CivilDate day) => _key('list-day-${day.toIso()}');

Future<void> _choose(WidgetTester tester, String presentation) async {
  await tester.ensureVisible(_key('month-presentation-$presentation'));
  await tester.pumpAndSettle();
  await tester.tap(_key('month-presentation-$presentation'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, CivilDate day, bool list) async {
  final target = list ? _row(day) : cell(day);
  await revealOnMonth(tester, target);
  // A list row can be taller than the viewport. Tap its date at the top.
  await tester.tapAt(tester.getTopLeft(target) + const Offset(30, 25));
  await tester.pumpAndSettle();
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();
  @override
  double scale(double fontSize) => fontSize * (fontSize >= 18 ? 2 : 1.5);
  @override
  double get textScaleFactor => 2;
}

void main() {
  setUpAll(() async {
    await initializeLocale();
    expect(
      await loadRoboto(),
      isTrue,
      reason: 'acceptance requires the real Android font',
    );
  });

  final shifts = [
    ShiftType(
      id: 'm',
      code: 'M',
      name: 'Mañana',
      colorValue: ShiftPalette.morning.toARGB32(),
      category: ShiftCategory.work,
      startMinute: 360,
      endMinute: 840,
    ),
    ShiftType(
      id: 'p',
      code: 'PPT',
      name: 'Partido',
      colorValue: ShiftPalette.afternoon.toARGB32(),
      category: ShiftCategory.work,
      startMinute: 570,
      endMinute: 780,
      segment2StartMinute: 1035,
      segment2DurationMinutes: 225,
    ),
    ShiftType(
      id: 'w',
      code: 'WWW',
      name: 'Noche',
      colorValue: ShiftPalette.night.toARGB32(),
      category: ShiftCategory.work,
      startMinute: 1335,
      endMinute: 375,
    ),
  ];
  final fixture = Schedule(
    shiftTypes: shifts,
    entries: {
      _day: const DayEntry(
        date: _day,
        shiftTypeIds: ['m', 'p', 'w'],
        note: 'Nota completa',
        overtimeMinutes: 75,
        earlyLeaveMinutes: 15,
      ),
    },
  ).resolve(_day);

  for (final locale in ['es', 'ca', 'gl', 'eu', 'en']) {
    for (final scale in [1.0, 1.3, 1.5, 2.0, -1.0]) {
      testWidgets(
        '$locale ×$scale: effective code/time size and complete glyphs',
        (tester) async {
          final focus = FocusNode();
          addTearDown(focus.dispose);
          for (final width in [320.0, 360.0, 412.0, 549.0, 840.0]) {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 4000);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light(),
                locale: Locale(locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: scale == -1
                        ? const _NonlinearScaler()
                        : TextScaler.linear(scale),
                  ),
                  child: child!,
                ),
                home: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(Sp.l),
                    child: MonthListDay(
                      day: fixture,
                      holiday: const Holiday(
                        date: _day,
                        name: 'Fiesta',
                        scope: HolidayScope.national,
                      ),
                      additionalHolidays: const [
                        Holiday(
                          date: _day,
                          name: 'Mi fiesta',
                          scope: HolidayScope.local,
                          source: HolidaySource.user,
                        ),
                      ],
                      isToday: true,
                      selected: true,
                      selectionActive: true,
                      opened: false,
                      focusNode: focus,
                      onMove: (_) {},
                      onFocus: () {},
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            for (final text in [
              'M',
              'PPT',
              'WWW',
              '06:00–14:00',
              '09:30–13:00',
              '17:15–21:00',
              '22:15–06:15',
            ]) {
              final finder = find.text(text);
              expectUnscaledCellText(tester, finder);
              final paragraph = tester.renderObject<RenderParagraph>(finder);
              final widget = tester.widget<Text>(finder);
              final base = text.length <= 3 ? 19.0 : 15.0;
              expect(widget.style!.fontSize, base);
              expect(
                paragraph.textScaler.scale(base),
                closeTo(
                  base * (scale == -1 ? (base >= 18 ? 2 : 1.5) : scale),
                  .001,
                ),
              );
              // Check actual glyph boxes, not just the Text or overflow warnings.
              final boxes = paragraph.getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: text.length),
              );
              expect(boxes, isNotEmpty);
              for (final box in boxes) {
                expect(box.left, greaterThanOrEqualTo(-.01));
                expect(
                  box.right,
                  lessThanOrEqualTo(paragraph.size.width + .01),
                );
                expect(
                  box.bottom,
                  lessThanOrEqualTo(paragraph.size.height + .01),
                );
              }
            }
            expect(find.byType(FittedBox), findsNothing);
            expect(find.textContaining('Mi fiesta'), findsOneWidget);
            expect(find.textContaining('Fiesta'), findsOneWidget);
            expect(
              find.text(
                AppLocalizations.of(tester.element(find.byType(MonthListDay)))
                    .daySemanticsNote,
              ),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  for (final size in [
    const Size(320, 844),
    const Size(360, 844),
    const Size(412, 915),
    const Size(915, 412),
    const Size(1280, 800),
  ]) {
    for (final weeks in [false, true]) {
      testWidgets(
        '$size weeks=$weeks: target geometry, all days, editing and rotation',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await pumpCalendar(tester, size: size, textScale: 2);
            final container = containerOf(tester);
            container.read(preferencesProvider.notifier).setWeekNumbers(weeks);
            await tester.pumpAndSettle();
            for (final mode in ['grid', 'list']) {
              final control = _key('month-presentation-$mode');
              final rect = tester.getRect(control);
              expect(rect.width, greaterThanOrEqualTo(48));
              expect(rect.height, greaterThanOrEqualTo(48));
              final node = tester.getSemantics(control);
              expect(node.rect.width, greaterThanOrEqualTo(48));
              expect(node.rect.height, greaterThanOrEqualTo(48));
            }
            await _choose(tester, 'list');
            expect(find.byType(MonthListDay), findsNWidgets(31));
            final l10n = AppLocalizations.of(
              tester.element(find.byType(MonthList)),
            );
            expect(
              find.descendant(
                of: _row(const CivilDate(2026, 10, 22)),
                matching: find.text(l10n.calendarNoShift),
              ),
              findsOneWidget,
            );
            expect(_row(const CivilDate(2026, 9, 30)), findsNothing);
            expect(_row(const CivilDate(2026, 11, 1)), findsNothing);
            await tester.ensureVisible(_key('month-select-days'));
            await tester.pumpAndSettle();
            await tester.tap(_key('month-select-days'));
            await tester.pumpAndSettle();
            await _tap(tester, _day, true);
            await _tap(tester, _day.addDays(1), true);
            expect(container.read(selectionControllerProvider).days, {
              _day,
              _day.addDays(1),
            });
            final original = scheduleOf(tester);
            await _choose(tester, 'grid');
            await _choose(tester, 'list');
            tester.view.physicalSize = Size(size.height, size.width) * 3;
            await tester.pumpAndSettle();
            expect(container.read(selectionControllerProvider).days, {
              _day,
              _day.addDays(1),
            });
            expect(
              container.read(monthPresentationProvider),
              MonthPresentation.list,
            );
            expectSameSchedule(scheduleOf(tester), original);
            await revealOnMonth(tester, _row(const CivilDate(2026, 10, 31)));
            expect(
              _row(const CivilDate(2026, 10, 31)).hitTestable(),
              findsOneWidget,
            );
            final node = tester.getSemantics(
              _key('list-day-target-2026-10-31'),
            );
            expect(node.rect.height, greaterThanOrEqualTo(48));
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.tap),
              isTrue,
            );
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets('switching to the list leaves today clear of the Pintar button', (
    tester,
  ) async {
    await pumpCalendar(tester);
    await _choose(tester, 'list');
    final today = tester.getRect(
      find.byWidgetPredicate((w) => w is MonthListDay && w.isToday),
    );
    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(
      today.bottom <= fab.top || today.top >= fab.bottom,
      isTrue,
      reason: 'today $today, Pintar $fab',
    );
  });

  testWidgets(
    'Sunday groups, week numbers and past/future navigation use the same month',
    (tester) async {
      await pumpCalendar(tester);
      final container = containerOf(tester);
      container.read(preferencesProvider.notifier).setWeekStart(7);
      container.read(preferencesProvider.notifier).setWeekNumbers(true);
      await _choose(tester, 'list');
      expect(_key('list-week-2026-09-27'), findsOneWidget);
      expect(_key('list-week-2026-10-25'), findsOneWidget);
      expect(_key('list-week-2026-09-28'), findsNothing);
      container
          .read(visibleMonthProvider.notifier)
          .goTo(const CivilDate(2028, 2, 1));
      await tester.pumpAndSettle();
      expect(find.byType(MonthListDay), findsNWidgets(29));
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: _key('month-scroll'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await revealOnMonth(tester, find.byTooltip('Mes anterior'));
      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.pumpAndSettle();
      expect(container.read(visibleMonthProvider), const CivilDate(2028, 1, 1));
      expect(find.byType(MonthListDay), findsNWidgets(31));
      await revealOnMonth(tester, find.text('Hoy').first);
      await tester.tap(find.text('Hoy').first);
      await tester.pumpAndSettle();
      expect(
        container.read(visibleMonthProvider),
        const CivilDate(2026, 10, 1),
      );
      expect(container.read(monthPresentationProvider), MonthPresentation.list);
    },
  );

  testWidgets(
    'grid/list tap painting, doubling, erasing and every undo step match',
    (tester) async {
      final results = <List<Schedule>>[];
      for (final listing in [false, true]) {
        await pumpCalendar(tester, size: const Size(1280, 1000));
        if (listing) {
          await _choose(tester, 'list');
        }
        final container = containerOf(tester);
        final controller = container.read(scheduleControllerProvider.notifier);
        final history = <Schedule>[scheduleOf(tester)];
        await enterPaintMode(tester);
        paintOf(tester).selectShift('morning');
        await _tap(tester, _day, listing);
        history.add(scheduleOf(tester));
        paintOf(tester).selectShift('afternoon');
        paintOf(tester).toggleDoubling();
        await _tap(tester, _day, listing);
        history.add(scheduleOf(tester));
        paintOf(tester).selectEraser();
        await _tap(tester, _day.addDays(1), listing);
        history.add(scheduleOf(tester));
        for (var i = 2; i >= 0; i--) {
          expect(controller.undo(), isTrue);
          expectSameSchedule(scheduleOf(tester), history[i]);
        }
        expect(container.read(scheduleControllerProvider).canUndo, isFalse);
        for (var i = 1; i <= 3; i++) {
          expect(controller.redo(), isTrue);
          expectSameSchedule(scheduleOf(tester), history[i]);
        }
        expect(container.read(scheduleControllerProvider).canRedo, isFalse);
        results.add(history);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < results.first.length; i++) {
        expectSameSchedule(results.first[i], results.last[i]);
      }
    },
  );

  testWidgets(
    'drag scrolls while painting without writing or adding undo history',
    (tester) async {
      await pumpCalendar(tester, size: const Size(320, 844));
      await _choose(tester, 'list');
      await enterPaintMode(tester);
      await revealOnMonth(tester, _row(_day));
      final before = scheduleOf(tester);
      final controller = containerOf(tester).read(scheduleControllerProvider);
      final scroll = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: _key('month-scroll'),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      final offset = scroll.pixels;
      await tester.dragFrom(
        tester.getTopLeft(_row(_day)) + const Offset(50, 25),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(scroll.pixels, greaterThan(offset));
      expectSameSchedule(scheduleOf(tester), before);
      expect(
        containerOf(tester).read(scheduleControllerProvider).canUndo,
        controller.canUndo,
      );
    },
  );

  testWidgets(
    'keyboard, single change announcement and corresponding focus in both directions',
    (tester) async {
      await pumpCalendar(tester, size: const Size(1280, 1000));
      final announcements = <Object?>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            if (message is Map && message['type'] == 'announce') {
              announcements.add(message);
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      tester.widget<DayCell>(cell(_day)).focusNode!.requestFocus();
      await tester.pumpAndSettle();
      await _choose(tester, 'list');
      expect(
        tester.widget<MonthListDay>(_row(_day)).focusNode.hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MonthListDay>(_row(_day.addDays(1))).focusNode.hasFocus,
        isTrue,
      );
      await _choose(tester, 'grid');
      expect(
        tester.widget<DayCell>(cell(_day.addDays(1))).focusNode!.hasFocus,
        isTrue,
      );
      await _choose(tester, 'list');
      final container = containerOf(tester);
      container.read(selectionControllerProvider.notifier).enter();
      await tester.pumpAndSettle();
      tester
          .widget<MonthListDay>(_row(_day.addDays(1)))
          .focusNode
          .requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(container.read(selectionControllerProvider).days, {
        _day.addDays(1),
      });
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MonthListDay>(_row(_day.addDays(2))).focusNode.hasFocus,
        isTrue,
      );
      expect(announcements, hasLength(3));
      await tester.pumpAndSettle();
      expect(announcements, hasLength(3));
      container.read(selectionControllerProvider.notifier).exit();
      await tester.pumpAndSettle();
      await _tap(tester, _day, true);
      expect(container.read(openDayProvider), _day);
      expect(find.byType(MonthPresentationControl), findsOneWidget);
    },
  );

  testWidgets(
    'list starts the same pattern wizard without painting the picked day',
    (tester) async {
      await pumpCalendar(tester, size: const Size(1280, 1000));
      await _choose(tester, 'list');
      await enterPaintMode(tester);
      final container = containerOf(tester);
      final before = scheduleOf(tester);
      container.read(patternStartPickProvider.notifier).begin('morning');
      await tester.pumpAndSettle();
      await _tap(tester, _day, true);
      expect(find.byType(PatternWizardScreen), findsOneWidget);
      expect(container.read(patternStartPickProvider), isNull);
      expectSameSchedule(
        container.read(scheduleControllerProvider).schedule,
        before,
      );
    },
  );

  testWidgets(
    'calendar selections are isolated and restored with month and tool intact',
    (tester) async {
      late String other;
      await full.AppUnderTest.pump(
        tester,
        prepare: (database) async {
          other = await full.addSecondCalendar(database);
        },
      );
      final container = containerOf(tester);
      final controller = container.read(scheduleControllerProvider.notifier);
      await _choose(tester, 'list');
      final selection = container.read(selectionControllerProvider.notifier);
      selection.select([_day, _day.addDays(1)]);
      await tester.pumpAndSettle();
      final switchOther = controller.switchCalendar(other);
      await tester.pumpAndSettle();
      await switchOther;
      await tester.pumpAndSettle();
      expect(container.read(selectionControllerProvider).days, isEmpty);
      selection.select([_day.addDays(3)]);
      final switchMain = controller.switchCalendar('main');
      await tester.pumpAndSettle();
      await switchMain;
      await tester.pumpAndSettle();
      expect(container.read(selectionControllerProvider).days, {
        _day,
        _day.addDays(1),
      });
      expect(container.read(monthPresentationProvider), MonthPresentation.list);
      expect(container.read(visibleMonthProvider), _day.firstDayOfMonth);
      final switchBack = controller.switchCalendar(other);
      await tester.pumpAndSettle();
      await switchBack;
      await tester.pumpAndSettle();
      expect(container.read(selectionControllerProvider).days, {
        _day.addDays(3),
      });
      selection.exit();
      paintOf(tester).enter();
      paintOf(tester).selectShift('night');
      paintOf(tester).toggleDoubling();
      await tester.pumpAndSettle();
      final tool = container.read(paintControllerProvider);
      await _choose(tester, 'grid');
      await _choose(tester, 'list');
      expect(
        container.read(paintControllerProvider).shiftTypeId,
        tool.shiftTypeId,
      );
      expect(container.read(paintControllerProvider).doubling, tool.doubling);
      expect(container.read(paintControllerProvider).active, isTrue);
      final restoreSelection = controller.switchCalendar('main');
      await tester.pumpAndSettle();
      await restoreSelection;
      await tester.pumpAndSettle();
      expect(container.read(selectionControllerProvider).days, {
        _day,
        _day.addDays(1),
      });
      expect(container.read(selectionControllerProvider).active, isTrue);
      expect(container.read(paintControllerProvider).active, isFalse);
    },
  );

  testWidgets(
    'all range operations share state and exact undo/redo history in grid and list',
    (tester) async {
      final results = <List<Schedule>>[];
      for (final listing in [false, true]) {
        await pumpCalendar(tester, size: const Size(1280, 1000));
        if (listing) {
          await _choose(tester, 'list');
        }
        await tester.ensureVisible(_key('month-select-days'));
        await tester.ensureVisible(_key('month-select-days'));
        await tester.pumpAndSettle();
        await tester.tap(_key('month-select-days'));
        await tester.pumpAndSettle();
        await _tap(tester, _day, listing);
        await _tap(tester, _day.addDays(1), listing);
        final container = containerOf(tester);
        final controller = container.read(scheduleControllerProvider.notifier);
        final selection = container.read(selectionControllerProvider.notifier);
        List<CivilDate> chosen() =>
            container.read(selectionControllerProvider).sorted;
        final states = <Schedule>[scheduleOf(tester)];
        void save() => states.add(scheduleOf(tester));
        // Same selected dates, same existing operation entry points.
        controller.setShiftOnDays(chosen(), 'morning');
        save();
        controller.doubleShiftOnDays(chosen(), 'afternoon');
        save();
        controller.setNoteOnDays(chosen(), 'Nota compartida');
        save();
        final cut = selection.cut()!;
        save();
        controller.pasteDays(cut.clip, _day.addDays(4), includeNotes: true);
        save();
        controller.repeatDays([_day.addDays(4), _day.addDays(5)], 2);
        save();
        controller.clearDays([_day.addDays(4)]);
        save();
        controller.resetDaysToPattern([_day.addDays(5)]);
        save();
        for (var i = states.length - 2; i >= 0; i--) {
          expect(controller.undo(), isTrue);
          expectSameSchedule(scheduleOf(tester), states[i]);
        }
        expect(container.read(scheduleControllerProvider).canUndo, isFalse);
        for (var i = 1; i < states.length; i++) {
          expect(controller.redo(), isTrue);
          expectSameSchedule(scheduleOf(tester), states[i]);
        }
        expect(container.read(scheduleControllerProvider).canRedo, isFalse);
        results.add(states);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < results.first.length; i++) {
        expectSameSchedule(results.first[i], results.last[i]);
      }
    },
  );
  for (final scale in [1.0, 1.3, 2.0]) {
    for (final selecting in [false, true]) {
      testWidgets(
        '320 dp ×$scale: all multi-shift starts survive ${selecting ? "selection" : "painting"}',
        (tester) async {
          await pumpCalendar(
            tester,
            size: const Size(320, 844),
            textScale: scale,
            prepare: (repository) async {
              for (final shift in shifts) {
                await repository.saveShiftType(shift);
              }
            },
          );
          final container = containerOf(tester);
          final controller = container.read(
            scheduleControllerProvider.notifier,
          );
          controller.setDayShifts(_day, ['m', 'p']);
          await tester.pumpAndSettle();
          await revealCell(tester, _day);
          final twoShiftHeight = tester.getSize(cell(_day)).height;
          if (selecting) {
            container.read(selectionControllerProvider.notifier).enter();
          } else {
            await enterPaintMode(tester);
            paintOf(tester).selectShift('w');
            paintOf(tester).toggleDoubling();
          }
          await tester.pumpAndSettle();
          await _tap(tester, _day, false);
          if (selecting) {
            expect(
              container.read(selectionControllerProvider).contains(_day),
              isTrue,
            );
          } else {
            expect(scheduleOf(tester).resolve(_day).shiftIds, ['m', 'p', 'w']);
            expect(
              tester.getSize(cell(_day)).height,
              greaterThan(twoShiftHeight),
            );
          }
          await revealCell(tester, _day);
          final inside = tester
              .getRect(cell(_day))
              .deflate(Sp.cellGap / 2 + Sp.selectedBorder);
          final texts = find.descendant(
            of: cell(_day),
            matching: find.byType(Text),
          );
          final data = tester
              .widgetList<Text>(texts)
              .map((text) => text.data!)
              .toList();
          for (final start in ['06', '09', if (!selecting) '22']) {
            final text = find.descendant(
              of: cell(_day),
              matching: find.textContaining(RegExp('^$start')),
            );
            expectUnscaledCellText(tester, text);
            final rect = renderedTextRect(tester, text);
            expect(rect.left, greaterThanOrEqualTo(inside.left - .01));
            expect(rect.right, lessThanOrEqualTo(inside.right + .01));
            expect(rect.top, greaterThanOrEqualTo(inside.top - .01));
            expect(rect.bottom, lessThanOrEqualTo(inside.bottom + .01));
          }
          expect(data, containsAll(['M', 'PPT', if (!selecting) 'WWW']));
          expect(
            find.descendant(
              of: cell(_day),
              matching: _key('cell-two-segments'),
            ),
            findsOneWidget,
          );
          if (selecting) {
            final mark = tester.widget<DecoratedBox>(
              _key('selected-mark-${_day.toIso()}'),
            );
            expect(
              (mark.decoration as BoxDecoration).border!.top.width,
              Sp.selectedBorder,
            );
          } else {
            expect(controller.undo(), isTrue);
            await tester.pumpAndSettle();
            expect(scheduleOf(tester).resolve(_day).shiftIds, ['m', 'p']);
            expect(controller.redo(), isTrue);
            await tester.pumpAndSettle();
            expect(scheduleOf(tester).resolve(_day).shiftIds, ['m', 'p', 'w']);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final size in [
    const Size(320, 640),
    const Size(915, 412),
    const Size(1280, 800),
  ]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        '$size ×$scale: selector fully visible and tappable in every mode',
        (tester) async {
          await pumpCalendar(tester, size: size, textScale: scale);
          final container = containerOf(tester);
          for (final mode in ['read', 'paint', 'select']) {
            if (mode == 'paint') {
              container.read(paintControllerProvider.notifier).toggle();
            } else if (mode == 'select') {
              container.read(selectionControllerProvider.notifier).enter();
            }
            await tester.pumpAndSettle();
            // First scroll days far away: the control must remain fixed.
            final scroll = tester.state<ScrollableState>(
              find
                  .descendant(
                    of: _key('month-scroll'),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            scroll.position.jumpTo(scroll.position.maxScrollExtent);
            await tester.pumpAndSettle();
            for (final presentation in ['list', 'grid']) {
              final control = _key('month-presentation-$presentation');
              final rect = tester.getRect(control);
              final viewport = tester.getRect(
                find.byType(MonthPresentationControl),
              );
              final visible = rect
                  .intersect(Offset.zero & size)
                  .intersect(viewport);
              expect(visible.width, greaterThanOrEqualTo(48));
              expect(visible.height, greaterThanOrEqualTo(48));
              expect(
                visible,
                rect,
                reason:
                    'the entire target is visible without scrolling controls',
              );
              // Both extremes of a 48 dp target really hit its button.
              for (final offset in [
                const Offset(0, -22),
                const Offset(0, 22),
              ]) {
                final point = rect.center + offset;
                final expected = presentation == 'list'
                    ? MonthPresentation.list
                    : MonthPresentation.grid;
                // Reset through the controller to make every physical tap observable.
                container
                    .read(monthPresentationProvider.notifier)
                    .choose(
                      expected == MonthPresentation.list
                          ? MonthPresentation.grid
                          : MonthPresentation.list,
                    );
                await tester.pumpAndSettle();
                await tester.tapAt(point);
                await tester.pumpAndSettle();
                expect(container.read(monthPresentationProvider), expected);
              }
            }
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets(
    'list rebuilds only changed dates for taps, live strokes and keyboard focus',
    (tester) async {
      await pumpCalendar(tester, size: const Size(1280, 1000));
      await _choose(tester, 'list');
      await enterPaintMode(tester);
      paintOf(tester).selectShift('morning');
      await tester.pumpAndSettle();
      final builds = <CivilDate, int>{};
      final previous = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        previous?.call(element, builtOnce);
        if (element.widget is MonthListDay) {
          final date = (element.widget as MonthListDay).day.date;
          builds.update(date, (value) => value + 1, ifAbsent: () => 1);
        }
      };
      addTearDown(() => debugOnRebuildDirtyWidget = previous);
      await _tap(tester, _day, true);
      expect(builds.keys.toSet(), {_day});
      expect(builds[_day], 1);
      builds.clear();
      final controller = containerOf(tester)
          .read(scheduleControllerProvider.notifier);
      controller.beginStroke(const PaintTool.replace('afternoon'));
      controller.paintDay(_day.addDays(1));
      await tester.pump();
      controller.paintDay(_day.addDays(2));
      await tester.pump();
      controller.endStroke();
      await tester.pumpAndSettle();
      expect(builds, {_day.addDays(1): 1, _day.addDays(2): 1});
      tester.widget<MonthListDay>(_row(_day)).focusNode.requestFocus();
      await tester.pumpAndSettle();
      builds.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(builds, {_day: 1, _day.addDays(1): 1});
      final selection = containerOf(tester)
          .read(selectionControllerProvider.notifier);
      selection.enter();
      await tester.pumpAndSettle();
      builds.clear();
      await _tap(tester, _day.addDays(2), true);
      expect(builds, {_day.addDays(2): 1});
      expect(tester.takeException(), isNull);
    },
  );

  for (final selecting in [false, true]) {
    testWidgets(
      'retained focus A, tap B in ${selecting ? "selection" : "paint"}: switching restores B',
      (tester) async {
        await pumpCalendar(tester, size: const Size(1280, 1000));
        await _choose(tester, 'list');
        final container = containerOf(tester);
        if (selecting) {
          container.read(selectionControllerProvider.notifier).enter();
        } else {
          await enterPaintMode(tester);
          paintOf(tester).selectShift('morning');
        }
        await tester.pumpAndSettle();
        tester.widget<MonthListDay>(_row(_day)).focusNode.requestFocus();
        await tester.pumpAndSettle();
        final next = _day.addDays(1);
        await _tap(tester, next, true);
        expect(
          tester.widget<MonthListDay>(_row(_day)).focusNode.hasFocus,
          isTrue,
        );
        expect(container.read(monthDayFocusProvider).date, next);
        await _choose(tester, 'grid');
        expect(tester.widget<DayCell>(cell(next)).focusNode!.hasFocus, isTrue);
        await _choose(tester, 'list');
        expect(
          tester.widget<MonthListDay>(_row(next)).focusNode.hasFocus,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
