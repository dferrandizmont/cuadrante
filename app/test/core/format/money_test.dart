import 'package:cuadrante/core/format/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  // Spanish formatting: "." for thousands (also with four digits), "," for
  // decimals and a no-break space before the euro sign.
  const nbsp = ' ';

  test('whole cents as es_ES euros', () {
    expect(formatEuroCentsFor('es', 123456), '1.234,56$nbsp€');
    expect(formatEuroCentsFor('es', 100000), '1.000,00$nbsp€');
    expect(formatEuroCentsFor('es', 99999), '999,99$nbsp€');
    expect(formatEuroCentsFor('es', 5), '0,05$nbsp€');
    expect(formatEuroCentsFor('es', 0), '0,00$nbsp€');
    expect(formatEuroCentsFor('es', 123456789), '1.234.567,89$nbsp€');
  });

  test('the hourly rates the shift editor stores', () {
    expect(formatEuroCentsFor('es', 1250), '12,50$nbsp€');
    expect(formatEuroCentsFor('es', 2210), '22,10$nbsp€');
  });
}
