import 'package:cuadrante/core/format/app_date_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    for (final l in ['es', 'ca', 'gl', 'eu', 'en']) {
      await initializeDateFormatting(l);
    }
  });

  // Monday 20 October 2025.
  final monday = DateTime(2025, 10, 20);

  test('«lunes, 20 de octubre» in each language', () {
    expect(const AppDateFormat('es').longDate(monday), 'lunes, 20 de octubre');
    expect(const AppDateFormat('ca').longDate(monday), 'dilluns, 20 d’octubre');
    expect(const AppDateFormat('gl').longDate(monday), 'luns, 20 de outubro');
    expect(
      const AppDateFormat('eu').longDate(monday),
      'astelehena, urriaren 20a',
    );
    expect(const AppDateFormat('en').longDate(monday), 'Monday, October 20');
  });

  test('Catalan writes «de» before a consonant', () {
    expect(
      const AppDateFormat('ca').longDate(DateTime(2025, 12, 1)),
      'dilluns, 1 de desembre',
    );
  });

  test('Basque: the day takes -a except 11 and 31 (already ending in -a)', () {
    const eu = AppDateFormat('eu');
    expect(eu.longDate(DateTime(2026, 1, 1)), 'osteguna, urtarrilaren 1a');
    expect(eu.longDate(DateTime(2026, 3, 11)), 'asteazkena, martxoaren 11');
    expect(eu.longDate(DateTime(2026, 8, 31)), 'astelehena, abuztuaren 31');
    expect(eu.longDate(DateTime(2026, 6, 21)), 'igandea, ekainaren 21a');
  });

  test('the Spanish spoken form keeps its «de» and no comma', () {
    expect(
      const AppDateFormat('es').weekdayDayMonth(monday),
      'lunes 20 de octubre',
    );
    expect(
      const AppDateFormat('gl').weekdayDayMonth(monday),
      'luns, 20 de outubro',
    );
  });

  test('short dates: three-letter month, no dot', () {
    expect(const AppDateFormat('es').shortDate(monday), 'lun 20 oct');
    expect(const AppDateFormat('ca').shortDate(monday), 'dl 20 oct');
    expect(const AppDateFormat('gl').shortDate(monday), 'luns 20 out');
    expect(const AppDateFormat('eu').shortDate(monday), 'urr 20, al');
    expect(const AppDateFormat('en').shortDate(monday), 'Mon Oct 20');
    final september = DateTime(2025, 9, 3);
    expect(const AppDateFormat('es').monthShort(september), 'sep');
    expect(const AppDateFormat('ca').monthShort(september), 'set');
    expect(const AppDateFormat('gl').monthShort(DateTime(2025, 6)), 'xuñ');
    expect(const AppDateFormat('eu').monthShort(DateTime(2025, 1)), 'urt');
    expect(const AppDateFormat('en').dayMonthYear(monday), 'Oct 20, 2025');
  });

  test('month and year headers come from the language data', () {
    expect(const AppDateFormat('eu').monthYear(monday), 'urria 2025');
    expect(const AppDateFormat('ca').monthYear(monday), 'octubre 2025');
    expect(const AppDateFormat('gl').monthYear(monday), 'outubro 2025');
    expect(const AppDateFormat('en').monthYear(monday), 'October 2025');
  });
}
