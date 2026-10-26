import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:flutter_test/flutter_test.dart';

const _split = ShiftType(
  id: 'partido',
  code: 'P',
  name: 'Partido',
  colorValue: 0xFF123456,
  category: ShiftCategory.work,
  startMinute: 8 * 60,
  endMinute: 12 * 60,
  icon: ShiftIcon.sun,
  alarmSound: 'content://media/internal/audio/media/42',
  segment2StartMinute: 16 * 60,
  segment2DurationMinutes: 4 * 60,
);

/// Editing a type must never drop what it already has: the icon, the alarm
/// sound and the second segment.
void main() {
  test('editing a type and saving it unchanged keeps icon, sound and '
      'second segment', () {
    final saved = ShiftTypeDraft.fromShiftType(_split).toShiftType('partido');
    expect(saved.icon, ShiftIcon.sun);
    expect(saved.alarmSound, 'content://media/internal/audio/media/42');
    expect(saved.segment2StartMinute, 16 * 60);
    expect(saved.segment2DurationMinutes, 4 * 60);
    expect(saved, _split);
  });

  test('editing the name or the color keeps them too', () {
    final saved = ShiftTypeDraft.fromShiftType(_split)
        .copyWith(name: 'Otro', colorValue: 0xFF00FF00)
        .toShiftType('partido');
    expect(saved.name, 'Otro');
    expect(saved.icon, ShiftIcon.sun);
    expect(saved.segment2StartMinute, 16 * 60);
  });

  test('times that no longer fit the second segment are a validation issue '
      '(it blocks saving), not a silent drop', () {
    final draft = ShiftTypeDraft.fromShiftType(_split);
    // 08:00-18:00 ends after the second segment starts.
    final longer = draft.copyWith(endMinute: 18 * 60);
    expect(longer.segment2Fits, isFalse);
    expect(
      longer.validate()[ShiftTypeField.segment2]?.issue,
      ShiftTypeIssue.segment2TooLong,
    );
    // Fixing the times (or the segment) makes it valid again, with the rest
    // of the type kept.
    final fixed = longer.copyWith(endMinute: 12 * 60).toShiftType('partido');
    expect(fixed, _split);
    // A shift without times has no second segment, and no problem either.
    final noTimes = draft.copyWith(hasTimes: false);
    expect(noTimes.validate(), isEmpty);
    expect(noTimes.toShiftType('p').hasSegment2, false);
  });

  test('clearing is explicit', () {
    final draft = ShiftTypeDraft.fromShiftType(_split)
        .copyWith(clearIcon: true, clearAlarmSound: true, clearSegment2: true);
    final saved = draft.toShiftType('partido');
    expect(saved.icon, isNull);
    expect(saved.alarmSound, isNull);
    expect(saved.hasSegment2, isFalse);
  });

  test('a new draft has none of them', () {
    final saved = const ShiftTypeDraft(
      code: 'X',
      name: 'Nuevo',
    ).toShiftType('nuevo');
    expect(saved.icon, isNull);
    expect(saved.alarmSound, isNull);
    expect(saved.hasSegment2, isFalse);
  });
}
