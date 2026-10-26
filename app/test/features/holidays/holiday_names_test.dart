import 'dart:convert';
import 'dart:io';

import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/holidays/presentation/holiday_names.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// H-T21-1: the names of the holidays come from the bundle in Spanish; the
/// national and the common regional ones are shown in the app's language.
void main() {
  AppLocalizations l10nOf(String code) => lookupAppLocalizations(Locale(code));

  Holiday bundled(String name) => Holiday(
    date: const CivilDate(2026, 1, 1),
    name: name,
    scope: HolidayScope.national,
  );

  // Spanish name of the bundle -> ca / gl / eu / en.
  const expected = <String, List<String>>{
    'Año Nuevo': [
      'Cap d’Any',
      'Aninovo',
      'Urteberri eguna',
      'New Year’s Day',
    ],
    'Epifanía del Señor': ['Reis', 'Reis', 'Errege eguna', 'Epiphany'],
    'Jueves Santo': [
      'Dijous Sant',
      'Xoves Santo',
      'Ostegun Santua',
      'Maundy Thursday',
    ],
    'Viernes Santo': [
      'Divendres Sant',
      'Venres Santo',
      'Ostiral Santua',
      'Good Friday',
    ],
    'Lunes de Pascua': [
      'Dilluns de Pasqua',
      'Luns de Pascua',
      'Pazko astelehena',
      'Easter Monday',
    ],
    'Fiesta del Trabajo': [
      'Festa del Treball',
      'Festa do Traballo',
      'Langileen eguna',
      'Labour Day',
    ],
    'Asunción de la Virgen': [
      'L’Assumpció',
      'Asunción',
      'Andre Mariaren Jasokundea',
      'Assumption Day',
    ],
    'Fiesta Nacional de España': [
      'Festa Nacional d’Espanya',
      'Festa Nacional de España',
      'Espainiako Jai Nazionala',
      'National Day of Spain',
    ],
    'Todos los Santos': [
      'Tots Sants',
      'Santos',
      'Santu Guztien eguna',
      'All Saints’ Day',
    ],
    'Día de la Constitución Española': [
      'Dia de la Constitució',
      'Día da Constitución',
      'Konstituzio eguna',
      'Constitution Day',
    ],
    'Inmaculada Concepción': [
      'La Immaculada',
      'Inmaculada Concepción',
      'Sortzez Garbiaren eguna',
      'Immaculate Conception',
    ],
    'Natividad del Señor': [
      'Nadal',
      'Nadal',
      'Eguberri eguna',
      'Christmas Day',
    ],
    'San Esteban': [
      'Sant Esteve',
      'Santo Estevo',
      'San Esteban',
      'St Stephen’s Day',
    ],
    'San José': ['Sant Josep', 'San Xosé', 'San José', 'St Joseph’s Day'],
    'Santiago Apóstol': [
      'Sant Jaume',
      'Santiago Apóstolo',
      'Santiago Apostolua',
      'St James’ Day',
    ],
    'Santiago Apóstol / Día Nacional de Galicia': [
      'Sant Jaume / Dia de Galícia',
      'Santiago Apóstolo / Día Nacional de Galicia',
      'Santiago Apostolua / Galiziako eguna',
      'St James’ Day / Galicia Day',
    ],
    'Diada Nacional de Cataluña': [
      'Diada Nacional de Catalunya',
      'Diada de Cataluña',
      'Kataluniako Diada',
      'Catalonia National Day',
    ],
  };
  const languages = ['ca', 'gl', 'eu', 'en'];

  test('the bundle names show in ca, gl, eu and en', () {
    for (final entry in expected.entries) {
      for (final (i, code) in languages.indexed) {
        expect(
          holidayDisplayName(l10nOf(code), bundled(entry.key)),
          entry.value[i],
          reason: '${entry.key} in $code',
        );
      }
    }
  });

  test('Spanish keeps the bundle name', () {
    for (final name in expected.keys) {
      expect(holidayDisplayName(l10nOf('es'), bundled(name)), name);
    }
  });

  test('the key ignores accents, case and the variant of Catalunya', () {
    final ca = l10nOf('ca');
    expect(localizedHolidayName(ca, 'ANO NUEVO'), 'Cap d’Any');
    expect(localizedHolidayName(ca, ' viernes santo '), 'Divendres Sant');
    expect(
      localizedHolidayName(ca, 'Diada Nacional de Catalunya'),
      'Diada Nacional de Catalunya',
    );
    expect(localizedHolidayName(l10nOf('en'), 'Día de Galicia'), 'Galicia Day');
    expect(
      localizedHolidayName(l10nOf('eu'), 'Día del País Vasco'),
      'Euskadiko eguna',
    );
  });

  test('an unknown name falls back to the bundle name', () {
    for (final code in languages) {
      expect(
        holidayDisplayName(l10nOf(code), bundled('La Bien Aparecida')),
        'La Bien Aparecida',
      );
    }
    expect(localizedHolidayName(l10nOf('ca'), 'La Bien Aparecida'), isNull);
  });

  test('a holiday the person added is never translated', () {
    const own = Holiday(
      date: CivilDate(2026, 3, 20),
      name: 'Año Nuevo',
      scope: HolidayScope.local,
      source: HolidaySource.user,
    );
    for (final code in languages) {
      expect(holidayDisplayName(l10nOf(code), own), 'Año Nuevo');
    }
  });

  test('every national holiday of the bundle has a translation', () {
    for (final year in [2026, 2027]) {
      final file = File('assets/holidays/$year/es.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      for (final h in json['national']! as List<Object?>) {
        final name = (h! as Map<String, Object?>)['name']! as String;
        for (final code in languages) {
          expect(
            localizedHolidayName(l10nOf(code), name),
            isNotNull,
            reason: '$name ($year) in $code',
          );
        }
      }
    }
  });
}
