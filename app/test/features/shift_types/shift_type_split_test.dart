import 'package:cuadrante/core/format/text_wrap.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';
import 'shift_types_screen_test.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

const _base = ShiftTypeDraft(
  code: 'P',
  name: 'Partido',
  startMinute: 9 * 60,
  endMinute: 13 * 60,
);

ShiftTypeDraft _split(int start, int duration, {ShiftTypeDraft? base}) =>
    (base ?? _base).copyWith(
      segment2StartMinute: start,
      segment2DurationMinutes: duration,
    );

ShiftTypeIssue? _issue(ShiftTypeDraft draft) =>
    draft.validate()[ShiftTypeField.segment2]?.issue;

void main() {
  group('the draft (turno partido, A12)', () {
    test('a type that is not split has nothing to validate', () {
      expect(_base.isSplit, isFalse);
      expect(_base.validate(), isEmpty);
      expect(_base.toShiftType('p').hasSegment2, isFalse);
    });

    test('a valid second segment is saved as it is', () {
      final draft = _split(17 * 60, 4 * 60);
      expect(draft.isSplit, isTrue);
      expect(draft.segment2EndMinute, 21 * 60);
      expect(draft.validate(), isEmpty);
      final type = draft.toShiftType('p');
      expect(type.segment2StartMinute, 17 * 60);
      expect(type.segment2DurationMinutes, 4 * 60);
      expect(type.scheduledMinutes, 8 * 60);
      expect(type.paidMinutes, isNull);
      expect(type.effectivePaidMinutes, 8 * 60);
    });

    test('the end is picked as a clock time and becomes a duration', () {
      final draft = _base.withSplit().copyWith(segment2EndMinute: 22 * 60);
      expect(draft.segment2StartMinute, 17 * 60);
      expect(draft.segment2DurationMinutes, 5 * 60);
      // Moving the start keeps the end.
      final moved = draft.copyWith(
        segment2StartMinute: 18 * 60,
        segment2EndMinute: draft.segment2EndMinute,
      );
      expect(moved.segment2DurationMinutes, 4 * 60);
      expect(moved.segment2EndMinute, 22 * 60);
      // Past midnight.
      final late = _split(
        22 * 60,
        1,
      ).copyWith(segment2EndMinute: 2 * 60, segment2StartMinute: 22 * 60);
      expect(late.segment2DurationMinutes, 4 * 60);
    });

    test('the switch on suggests 4 h, 4 h after the first segment', () {
      final draft = _base.withSplit();
      expect(draft.segment2StartMinute, 17 * 60);
      expect(draft.segment2DurationMinutes, 4 * 60);
      expect(draft.validate(), isEmpty);
      expect(draft.copyWith(clearSegment2: true).isSplit, isFalse);
    });

    test('starting right when the first segment ends is not a split', () {
      final draft = _split(13 * 60, 4 * 60);
      expect(_issue(draft), ShiftTypeIssue.segment2NotAfterFirst);
    });

    test('overlapping the first segment does not fit in 24 h', () {
      // 09-13 and 12-16: the second one would start the next day.
      expect(_issue(_split(12 * 60, 4 * 60)), ShiftTypeIssue.segment2TooLong);
    });

    test('segments and gap longer than a day do not fit', () {
      final long = _base.copyWith(startMinute: 6 * 60, endMinute: 18 * 60);
      expect(
        _issue(_split(19 * 60, 12 * 60, base: long)),
        ShiftTypeIssue.segment2TooLong,
      );
      // Exactly 24 h fits: 06-18, gap of 1 h, 11 h.
      expect(_split(19 * 60, 11 * 60, base: long).validate(), isEmpty);
    });

    test('same start and end of the second segment (24 h) does not fit', () {
      final draft = _base.withSplit().copyWith(segment2EndMinute: 17 * 60);
      expect(draft.segment2DurationMinutes, 1440);
      expect(_issue(draft), ShiftTypeIssue.segment2TooLong);
    });

    test('every other problem of checkSegment2 is reported too', () {
      expect(
        _issue(_base.copyWith(segment2StartMinute: 17 * 60)),
        ShiftTypeIssue.segment2Incomplete,
        reason: 'only the start',
      );
      expect(_issue(_split(1500, 60)), ShiftTypeIssue.segment2StartOutOfRange);
      expect(
        _issue(_split(17 * 60, 0)),
        ShiftTypeIssue.segment2DurationOutOfRange,
      );
      expect(
        _issue(_split(17 * 60, 1441)),
        ShiftTypeIssue.segment2DurationOutOfRange,
      );
    });

    test('each Segment2Problem has an issue', () {
      // The enum has six values; the five issues cover them (noTimes goes
      // with incomplete, and a draft without times has no section at all).
      final seen = <Segment2Problem>{};
      for (final draft in [
        _base.copyWith(segment2StartMinute: 17 * 60),
        _split(1500, 60),
        _split(17 * 60, 0),
        _split(13 * 60, 4 * 60),
        _split(12 * 60, 4 * 60),
      ]) {
        final p = draft.segment2Problem;
        expect(p, isNotNull);
        seen.add(p!);
      }
      expect(
        seen,
        Segment2Problem.values.toSet()..remove(Segment2Problem.noTimes),
      );
    });

    test('the fix for an invalid draft lets it save', () {
      final bad = _split(13 * 60, 4 * 60);
      expect(bad.validate(), isNotEmpty);
      expect(bad.copyWith(segment2StartMinute: 17 * 60).validate(), isEmpty);
    });

    test(
      'editing the times of a stored split shift is validated, not dropped',
      () {
        final stored = _split(17 * 60, 4 * 60).toShiftType('p');
        final draft = ShiftTypeDraft.fromShiftType(stored);
        expect(draft.isSplit, isTrue);
        expect(draft.validate(), isEmpty);
        // 09:00-18:00 ends after the second segment starts.
        final longer = draft.copyWith(endMinute: 18 * 60);
        expect(_issue(longer), ShiftTypeIssue.segment2TooLong);
        expect(longer.segment2Fits, isFalse);
      },
    );

    test('a shift without times has no second segment and no problem', () {
      final noTimes = _split(13 * 60, 4 * 60).copyWith(hasTimes: false);
      expect(noTimes.splitSectionApplies, isFalse);
      expect(noTimes.validate(), isEmpty);
      expect(noTimes.toShiftType('p').hasSegment2, isFalse);
      expect(noTimes.toShiftType('p').hasTimes, isFalse);
    });

    test('the unpaid break is taken off both segments together', () {
      final draft = _split(17 * 60, 4 * 60).copyWith(unpaidBreakText: '30');
      expect(draft.scheduledMinutes, 8 * 60);
      expect(draft.validate(), isEmpty);
      expect(draft.toShiftType('p').paidMinutes, 450);
      // A break as long as the whole shift is rejected, as before.
      expect(
        _split(
          17 * 60,
          4 * 60,
        ).copyWith(unpaidBreakText: '480').validate().keys,
        contains(ShiftTypeField.unpaidBreak),
      );
      // Round trip through the stored type.
      final back = ShiftTypeDraft.fromShiftType(draft.toShiftType('p'));
      expect(back.unpaidBreakText, '30');
    });
  });

  group('the template', () {
    test(
      'Partido 09-13 / 17-21 is a valid split type, outside the palette',
      () {
        final type = splitShiftTemplate.toShiftType('split');
        expect(type.name, 'Partido');
        expect(type.startMinute, 9 * 60);
        expect(type.endMinute, 13 * 60);
        expect(type.segment2StartMinute, 17 * 60);
        expect(type.segment2DurationMinutes, 4 * 60);
        expect(type.segment2Problem, isNull);
        expect(type.scheduledMinutes, 8 * 60);
        expect(ShiftTypeDraft.fromShiftType(type).validate(), isEmpty);
        // New calendars keep starting with the same ten types.
        expect(shiftTemplates.map((t) => t.key), isNot(contains('split')));
        expect(shiftTemplates, hasLength(10));
        expect(shiftTemplateByKey('split'), same(splitShiftTemplate));
        expect(shiftTemplateByKey('morning').segment2StartMinute, isNull);
      },
    );
  });

  group('the form', () {
    testWidgets('the switch reveals the second segment and a split type is '
        'saved', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      expect(_key('shift-split'), findsOneWidget);
      expect(find.text('Turno partido'), findsOneWidget);
      expect(_key('shift-start2'), findsNothing);

      await setTime(tester, 'shift-start', 9, 0);
      await setTime(tester, 'shift-end', 13, 0);
      await tapKey(tester, 'shift-split');
      expect(find.text('Segundo tramo'), findsOneWidget);
      expect(find.text('Empieza 17:00'), findsOneWidget);
      expect(find.text('Termina 21:00'), findsOneWidget);
      expect(find.text('Trabajas 4 h y 4 h: 8 h en total'), findsOneWidget);
      expect(_key('shift-split-error'), findsNothing);

      await setTime(tester, 'shift-start2', 16, 30);
      await setTime(tester, 'shift-end2', 20, 30);
      expect(find.text('Empieza 16:30'), findsOneWidget);
      expect(find.text('Termina 20:30'), findsOneWidget);

      await typeInto(tester, 'shift-name', 'Partido');
      await typeInto(tester, 'shift-break', '30');
      expect(find.text('Se pagan 7 h 30 min'), findsOneWidget);
      await save(tester);

      final created = stateOf(tester).palette.last;
      expect(created.name, 'Partido');
      expect(created.startMinute, 9 * 60);
      expect(created.endMinute, 13 * 60);
      expect(created.segment2StartMinute, 16 * 60 + 30);
      expect(created.segment2DurationMinutes, 4 * 60);
      expect(created.paidMinutes, 450);
      final stored = await storedSnapshot(tester);
      final saved = stored.palette.firstWhere((t) => t.id == created.id);
      expect(saved.segment2StartMinute, 16 * 60 + 30);
      expect(saved.segment2DurationMinutes, 4 * 60);
    });

    testWidgets('a bad second segment says why and blocks saving', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      final before = paletteIds(tester).length;
      await typeInto(tester, 'shift-name', 'Partido');
      await setTime(tester, 'shift-start', 9, 0);
      await setTime(tester, 'shift-end', 13, 0);
      await tapKey(tester, 'shift-split');

      // Right when the first one ends.
      await setTime(tester, 'shift-start2', 13, 0);
      expect(
        find.text(
          'El segundo tramo no puede empezar justo cuando acaba el primero: '
          'sería un solo tramo. Deja un descanso entre los dos.',
        ),
        findsOneWidget,
      );
      await save(tester);
      expect(_key('shift-save'), findsOneWidget, reason: 'still in the form');
      expect(paletteIds(tester), hasLength(before));

      // Overlapping the first one.
      await setTime(tester, 'shift-start2', 12, 0);
      expect(find.textContaining('no caben en 24 h'), findsOneWidget);
      await save(tester);
      expect(paletteIds(tester), hasLength(before));

      // Fixed: it saves.
      await setTime(tester, 'shift-start2', 17, 0);
      expect(_key('shift-split-error'), findsNothing);
      await save(tester);
      expect(paletteIds(tester), hasLength(before + 1));
      expect(stateOf(tester).palette.last.hasSegment2, isTrue);
    });

    testWidgets('turning the switch off before saving gives a normal shift', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Normal');
      await tapKey(tester, 'shift-split');
      expect(_key('shift-start2'), findsOneWidget);
      await tapKey(tester, 'shift-split');
      expect(_key('shift-start2'), findsNothing);
      await save(tester);
      expect(stateOf(tester).palette.last.hasSegment2, isFalse);
    });

    testWidgets('a stored split type opens with the switch on and keeps its '
        'second segment', (tester) async {
      await pumpCalendar(tester);
      // Mañana becomes a split shift: 09:00-13:00 and 17:00-21:00.
      final morning = stateOf(tester).palette
          .firstWhere((t) => t.id == 'morning');
      controllerOf(tester).saveShiftType(
        morning.copyWith(
          startMinute: 9 * 60,
          endMinute: 13 * 60,
          segment2StartMinute: 17 * 60,
          segment2DurationMinutes: 4 * 60,
        ),
      );
      await tester.pumpAndSettle();
      await openShiftTypes(tester);
      // The row shows both ranges.
      expect(find.textContaining(keepTimeRangesTogether('09:00–13:00 · 17:00–21:00')), findsWidgets);
      await tapKey(tester, 'shift-row-morning');
      expect(tester.widget<SwitchListTile>(_key('shift-split')).value, isTrue);
      expect(find.text('Empieza 17:00'), findsOneWidget);
      await save(tester);
      final saved = stateOf(tester).palette
          .firstWhere((t) => t.id == 'morning');
      expect(saved.segment2StartMinute, 17 * 60);
      expect(saved.segment2DurationMinutes, 4 * 60);

      // Make it a normal shift again.
      await tapKey(tester, 'shift-row-morning');
      await tapKey(tester, 'shift-split');
      await save(tester);
      expect(
        stateOf(tester).palette
            .firstWhere((t) => t.id == 'morning')
            .hasSegment2,
        isFalse,
      );
    });

    testWidgets('moving the first segment over the second one is flagged', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Partido');
      await setTime(tester, 'shift-start', 9, 0);
      await setTime(tester, 'shift-end', 13, 0);
      await tapKey(tester, 'shift-split');
      expect(_key('shift-split-error'), findsNothing);
      // 09:00-18:00 ends after the second segment starts at 17:00.
      await setTime(tester, 'shift-end', 18, 0);
      expect(_key('shift-split-error'), findsOneWidget);
      await save(tester);
      expect(_key('shift-save'), findsOneWidget);
    });

    testWidgets('the template «Partido 09–13 / 17–21» fills a new shift', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      expect(_key('shift-split-template'), findsOneWidget);
      await tapKey(tester, 'shift-split-template');
      expect(find.text('Empieza 09:00'), findsOneWidget);
      expect(find.text('Termina 13:00'), findsOneWidget);
      expect(find.text('Empieza 17:00'), findsOneWidget);
      expect(find.text('Termina 21:00'), findsOneWidget);
      expect(find.text('Trabajas 4 h y 4 h: 8 h en total'), findsOneWidget);
      // The button is gone once the shift is split.
      expect(_key('shift-split-template'), findsNothing);
      await save(tester);
      final created = stateOf(tester).palette.last;
      expect(created.name, 'Partido');
      expect(created.code, 'P');
      expect(created.startMinute, 9 * 60);
      expect(created.segment2StartMinute, 17 * 60);
      expect(created.segment2DurationMinutes, 4 * 60);
    });

    testWidgets('the template keeps a name the user already typed, and an '
        'existing type does not offer it', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Tienda');
      await tapKey(tester, 'shift-split-template');
      expect(
        tester.widget<TextField>(_key('shift-name')).controller?.text,
        'Tienda',
      );
      await save(tester);
      expect(stateOf(tester).palette.last.name, 'Tienda');
      expect(stateOf(tester).palette.last.hasSegment2, isTrue);

      await tapKey(tester, 'shift-row-morning');
      expect(_key('shift-split-template'), findsNothing);
    });

    testWidgets('a shift without times hides the split switch', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      expect(_key('shift-split'), findsOneWidget);
      await tapKey(tester, 'shift-no-times');
      expect(_key('shift-split'), findsNothing);
    });

    testWidgets('320 dp, text x1.3: the split section fits without overflow', (
      tester,
    ) async {
      await pumpCalendar(tester, size: const Size(320, 640), textScale: 1.3);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Turno partido largo');
      await tapKey(tester, 'shift-split');
      for (final key in [
        'shift-split',
        'shift-start2',
        'shift-end2',
        'shift-save',
      ]) {
        await reveal(tester, key);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: key);
        final rect = tester.getRect(_key(key));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(320), reason: key);
      }
      // Targets of 48 dp.
      expect(
        tester.getRect(_key('shift-start2')).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getRect(_key('shift-end2')).height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}
