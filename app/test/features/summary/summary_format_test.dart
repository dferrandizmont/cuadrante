import 'dart:ui';

import 'package:cuadrante/core/format/app_date_format.dart';
import 'package:cuadrante/core/l10n/l10n.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/summary/presentation/summary_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  final l10n = lookupAppLocalizations(const Locale('es'));

  test('hours as "152 h 30 min"', () {
    expect(formatHours(l10n, 152 * 60 + 30), '152 h 30 min');
    expect(formatHours(l10n, 160 * 60), '160 h');
    expect(formatHours(l10n, 45), '45 min');
    expect(formatHours(l10n, 0), '0 h');
    expect(formatHours(l10n, 60), '1 h');
    // Never days, however long.
    expect(formatHours(l10n, 30 * 24 * 60), '720 h');
    expect(formatHours(l10n, 26 * 60 + 5), '26 h 5 min');
  });

  test('signed differences', () {
    expect(formatSignedHours(l10n, 8 * 60), '+8 h');
    expect(formatSignedHours(l10n, -(4 * 60 + 30)), '−4 h 30 min');
    expect(formatSignedHours(l10n, 0), '+0 h');
  });

  test('short month names without the dot', () {
    expect(monthAbbreviation('es', const CivilDate(2026, 1, 1)), 'Ene');
    expect(monthAbbreviation('es', const CivilDate(2026, 9, 1)), 'Sep');
    expect(monthAbbreviation('es', const CivilDate(2026, 10, 1)), 'Oct');
  });

  test('H-T08-3: every short month has three letters, "sep" included', () {
    for (var m = 1; m <= 12; m++) {
      expect(
        monthAbbreviation('es', CivilDate(2026, m, 1)),
        hasLength(3),
        reason: 'month $m',
      );
    }
    // The same abbreviation in every place a month is abbreviated.
    expect(formatRangeDate('es', const CivilDate(2026, 9, 14)), '14 sep 2026');
    expect(
      const AppDateFormat().shortDate(DateTime(2026, 9, 14)),
      'lun 14 sep',
    );
    expect(const AppDateFormat().monthShort(DateTime(2026, 9, 1)), 'sep');
  });
}
