import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

ShiftType _type({
  int? start = 8 * 60,
  int? end = 12 * 60,
  int? seg2Start,
  int? seg2Duration,
  ShiftIcon? icon,
  String? alarmSound,
}) => ShiftType(
  id: 't',
  code: 'P',
  name: 'Partido',
  colorValue: 0xFF123456,
  category: ShiftCategory.work,
  startMinute: start,
  endMinute: end,
  segment2StartMinute: seg2Start,
  segment2DurationMinutes: seg2Duration,
  icon: icon,
  alarmSound: alarmSound,
);

/// Icon, alarm sound and second segment of a shift type (schema v3).
void main() {
  group('ShiftIcon', () {
    test('keys are the stable names and the set is curated', () {
      const keys = [
        'sun',
        'moon',
        'sunrise',
        'hospital',
        'ambulance',
        'police',
        'fire',
        'factory',
        'truck',
        'plane',
        'school',
        'home',
        'beach',
        'bed',
        'star',
        'heart',
        'coffee',
        'book',
        'money',
        'alert',
        'phone',
        'car',
        'train',
        'bus',
        'shop',
        'tool',
        'baby',
        'sport',
        'party',
        'medical',
      ];
      expect(ShiftIcon.keys, keys, reason: 'keys never change or move');
      for (final key in keys) {
        expect(ShiftIcon.fromKey(key)?.key, key);
      }
    });

    test('an unknown key, an emoji or an empty text reads as null', () {
      expect(ShiftIcon.fromKey(null), isNull);
      expect(ShiftIcon.fromKey(''), isNull);
      expect(ShiftIcon.fromKey('rocket'), isNull);
      expect(ShiftIcon.fromKey('☀'), isNull);
      expect(ShiftIcon.fromKey('Sun'), isNull);
    });
  });

  group('ShiftType icon and alarm sound', () {
    test('they default to none and take part in ==', () {
      expect(_type().icon, isNull);
      expect(_type().alarmSound, isNull);
      expect(_type(icon: ShiftIcon.moon), _type(icon: ShiftIcon.moon));
      expect(_type(icon: ShiftIcon.moon), isNot(_type(icon: ShiftIcon.sun)));
      expect(_type(alarmSound: 'a'), isNot(_type(alarmSound: 'b')));
      expect(
        _type(icon: ShiftIcon.moon, alarmSound: 'a').hashCode,
        _type(icon: ShiftIcon.moon, alarmSound: 'a').hashCode,
      );
    });

    test('copyWith sets, keeps and clears them', () {
      final t = _type(icon: ShiftIcon.moon, alarmSound: 'content://x');
      expect(t.copyWith(code: 'Q').icon, ShiftIcon.moon);
      expect(t.copyWith(code: 'Q').alarmSound, 'content://x');
      expect(t.copyWith(icon: ShiftIcon.sun).icon, ShiftIcon.sun);
      expect(t.copyWith(clearIcon: true).icon, isNull);
      expect(t.copyWith(clearAlarmSound: true).alarmSound, isNull);
      expect(t.copyWith(clearIcon: true).alarmSound, 'content://x');
    });

    test('an empty alarm sound id is refused', () {
      expect(() => _type(alarmSound: ''), throwsA(isA<AssertionError>()));
    });
  });

  group('second segment (turno partido)', () {
    test('without it, everything behaves as before', () {
      final t = _type();
      expect(t.hasSegment2, isFalse);
      expect(t.segment2Problem, isNull);
      expect(t.segment2EndMinute, isNull);
      expect(t.segment2GapMinutes, 0);
      expect(t.durationMinutes, 4 * 60);
      expect(t.spanMinutes, 4 * 60);
      expect(t.effectivePaidMinutes, 4 * 60);
    });

    test('08:00-12:00 + 16:00 for 4 h is valid; the engine still sees '
        'segment 1', () {
      final t = _type(seg2Start: 16 * 60, seg2Duration: 4 * 60);
      expect(t.hasSegment2, isTrue);
      expect(t.segment2Problem, isNull);
      expect(t.segment2EndMinute, 20 * 60);
      expect(t.segment2GapMinutes, 4 * 60);
      expect(t.spanMinutes, 12 * 60);
      // Engine support comes later: the duration is still segment 1.
      expect(t.durationMinutes, 4 * 60);
      expect(t.crossesMidnight, isFalse);
    });

    test('the second segment may run past midnight', () {
      final t = _type(
        start: 14 * 60,
        end: 18 * 60,
        seg2Start: 22 * 60,
        seg2Duration: 4 * 60,
      );
      expect(t.segment2Problem, isNull);
      expect(t.segment2EndMinute, 2 * 60);
      expect(t.spanMinutes, 12 * 60);
    });

    test('the first segment may cross midnight too', () {
      // 20:00-02:00, then 04:00-06:00.
      final t = _type(
        start: 20 * 60,
        end: 2 * 60,
        seg2Start: 4 * 60,
        seg2Duration: 2 * 60,
      );
      expect(t.segment2Problem, isNull);
      expect(t.segment2GapMinutes, 2 * 60);
      expect(t.spanMinutes, 10 * 60);
    });

    test('exactly 24 h fits; one minute more does not', () {
      // 08:00-12:00 (4 h) + gap 8 h + 12 h = 24 h.
      expect(
        _type(seg2Start: 20 * 60, seg2Duration: 12 * 60).segment2Problem,
        isNull,
      );
      expect(
        _type(seg2Start: 20 * 60, seg2Duration: 12 * 60 + 1).segment2Problem,
        Segment2Problem.tooLong,
      );
    });

    test('starting "before" the first segment only counts as the next day, '
        'which does not fit', () {
      // 07:00 comes after 12:00 only on the next day: a 19 h gap.
      expect(
        _type(seg2Start: 7 * 60, seg2Duration: 4 * 60).segment2Problem,
        Segment2Problem.tooLong,
      );
    });

    test('starting right when the first ends is one segment, not two', () {
      expect(
        _type(seg2Start: 12 * 60, seg2Duration: 60).segment2Problem,
        Segment2Problem.notAfterFirst,
      );
    });

    test('checkSegment2 reports each problem', () {
      Segment2Problem? check(int? s, int? e, int? s2, int? d2) => checkSegment2(
        startMinute: s,
        endMinute: e,
        segment2StartMinute: s2,
        segment2DurationMinutes: d2,
      );
      expect(check(480, 720, null, null), isNull);
      expect(check(null, null, null, null), isNull);
      expect(check(480, 720, 960, null), Segment2Problem.incomplete);
      expect(check(480, 720, null, 60), Segment2Problem.incomplete);
      expect(check(null, null, 960, 60), Segment2Problem.noTimes);
      expect(check(480, 720, 1440, 60), Segment2Problem.startOutOfRange);
      expect(check(480, 720, -1, 60), Segment2Problem.startOutOfRange);
      expect(check(480, 720, 960, 0), Segment2Problem.durationOutOfRange);
      expect(check(480, 720, 960, 1441), Segment2Problem.durationOutOfRange);
      expect(check(480, 480, 960, 60), Segment2Problem.tooLong, reason: '24 h');
    });

    test('both set or both null; it needs the shift to have times', () {
      expect(() => _type(seg2Start: 960), throwsA(isA<AssertionError>()));
      expect(() => _type(seg2Duration: 60), throwsA(isA<AssertionError>()));
      expect(
        () => _type(start: null, end: null, seg2Start: 960, seg2Duration: 60),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _type(seg2Start: 1440, seg2Duration: 60),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _type(seg2Start: 960, seg2Duration: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith: sets, clears, and goes with the times', () {
      final t = _type(seg2Start: 960, seg2Duration: 240);
      expect(t.copyWith(code: 'Q').segment2StartMinute, 960);
      expect(t.copyWith(clearSegment2: true).hasSegment2, isFalse);
      expect(t.copyWith(clearTimes: true).hasSegment2, isFalse);
      final moved = t.copyWith(segment2StartMinute: 17 * 60);
      expect(moved.segment2StartMinute, 17 * 60);
      expect(moved.segment2DurationMinutes, 240);
      expect(t, isNot(moved));
      expect(t, _type(seg2Start: 960, seg2Duration: 240));
    });
  });
}
