import 'package:cuadrante/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final utcHour in [0, 1]) {
    test('minute clock preserves repeated October hour UTC $utcHour', () {
      final instant = DateTime.utc(
        2026,
        10,
        25,
        utcHour,
        30,
        45,
        123,
        456,
      ).toLocal();
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => instant)],
      );
      addTearDown(container.dispose);
      final minute = container.read(minuteClockProvider);
      expect((minute.hour, minute.minute), (2, 30));
      expect(minute.timeZoneOffset, instant.timeZoneOffset);
      expect(minute.toUtc(), DateTime.utc(2026, 10, 25, utcHour, 30));
    });
  }
}
