import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

// `?mes=` of /resumen and /comparar: a link can come from any app, so a year
// far from today is ignored (the screen opens on today's month).
void main() {
  const today = CivilDate(2026, 10, 20);

  test('a month near today is read', () {
    expect(parseMonthParam('2026-10', today), const CivilDate(2026, 10, 1));
    expect(parseMonthParam('2076-12', today), const CivilDate(2076, 12, 1));
    expect(parseMonthParam('1976-01', today), const CivilDate(1976, 1, 1));
  });

  test('years more than 50 from today are ignored', () {
    for (final bad in ['0000-01', '9999-12', '2077-01', '1975-12']) {
      expect(parseMonthParam(bad, today), isNull, reason: bad);
    }
  });

  test('anything that is not yyyy-mm is ignored', () {
    for (final bad in [null, '', '2026', '2026-13', '2026-00', 'x-y']) {
      expect(parseMonthParam(bad, today), isNull, reason: '$bad');
    }
  });
}
