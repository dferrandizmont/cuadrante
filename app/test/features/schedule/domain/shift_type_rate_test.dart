import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// The optional hourly rate of a shift type (schema v2): whole cents, no
/// rate by default, part of equality, and the engine ignores it.
void main() {
  const plain = ShiftType(
    id: 'm',
    code: 'M',
    name: 'Mañana',
    colorValue: 0xFFF5A524,
    category: ShiftCategory.work,
    startMinute: 360,
    endMinute: 840,
  );

  test('there is no rate by default', () {
    expect(plain.hourlyRateCents, isNull);
  });

  test('copyWith sets, keeps and clears it', () {
    final paid = plain.copyWith(hourlyRateCents: 1250);
    expect(paid.hourlyRateCents, 1250);
    expect(paid.copyWith(name: 'Otra').hourlyRateCents, 1250);
    expect(paid.copyWith(clearHourlyRate: true).hourlyRateCents, isNull);
    expect(plain.hourlyRateCents, isNull, reason: 'immutable');
  });

  test('it takes part in equality', () {
    expect(
      plain.copyWith(hourlyRateCents: 1250),
      plain.copyWith(hourlyRateCents: 1250),
    );
    expect(plain.copyWith(hourlyRateCents: 1250), isNot(plain));
    expect(
      plain.copyWith(hourlyRateCents: 1250).hashCode,
      plain.copyWith(hourlyRateCents: 1250).hashCode,
    );
  });

  test('the engine does not care about it', () {
    final paid = plain.copyWith(hourlyRateCents: 1250);
    const day = CivilDate(2026, 10, 19);
    Schedule schedule(ShiftType t) => Schedule(
      shiftTypes: [t],
      entries: {
        day: DayEntry(date: day, shiftTypeIds: const ['m']),
      },
    );
    expect(
      schedule(paid).resolve(day).shiftIds,
      schedule(plain).resolve(day).shiftIds,
    );
    expect(paid.durationMinutes, plain.durationMinutes);
    expect(paid.effectivePaidMinutes, plain.effectivePaidMinutes);
  });
}
