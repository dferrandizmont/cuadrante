import 'dart:convert';
import 'dart:io';

import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wording decided after the QA campaigns T17 and T21.
void main() {
  const languages = ['es', 'ca', 'gl', 'eu', 'en'];
  AppLocalizations l10nOf(String code) => lookupAppLocalizations(Locale(code));

  test('H-T17-5: the Settings row and its screen have the same title', () {
    for (final code in languages) {
      final l10n = l10nOf(code);
      expect(l10n.calExportRowTitle, l10n.calExportTitle, reason: code);
      expect(l10n.calExportRowTitle.length, lessThan(24), reason: code);
    }
    expect(l10nOf('es').calExportTitle, 'Exportar turnos');
    expect(l10nOf('ca').calExportTitle, 'Exporta torns');
    // The old long title lives on as the subtitle of the row.
    expect(l10nOf('es').calExportRowSubtitle, contains('calendario del móvil'));
  });

  test('H-T21-4: «widget» in every language, never «giny»', () {
    for (final code in languages) {
      final arb = File('lib/l10n/app_$code.arb').readAsStringSync();
      expect(arb.toLowerCase(), isNot(contains('giny')), reason: code);
      final json = jsonDecode(arb) as Map<String, dynamic>;
      expect(
        (json['faqWidgetQ'] as String).toLowerCase(),
        contains('widget'),
        reason: code,
      );
    }
    expect(l10nOf('ca').widgetAddTitle, 'Afegeix un widget');
  });

  test('H-T21-5: the Catalan weekdays are the two-letter ones', () {
    final ca = l10nOf('ca');
    expect([
      ca.calendarWeekdayMon,
      ca.calendarWeekdayTue,
      ca.calendarWeekdayWed,
      ca.calendarWeekdayThu,
      ca.calendarWeekdayFri,
      ca.calendarWeekdaySat,
      ca.calendarWeekdaySun,
    ], ['dl', 'dt', 'dc', 'dj', 'dv', 'ds', 'dg']);
    expect(ca.widgetWeekdayHeaders, 'dl,dt,dc,dj,dv,ds,dg');
  });
}
