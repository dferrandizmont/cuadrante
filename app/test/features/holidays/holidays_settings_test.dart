import 'dart:async';

import 'package:cuadrante/core/database/database_provider.dart';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/holidays/data/holiday_bundle_format.dart';
import 'package:cuadrante/features/holidays/data/holiday_repository.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/holidays/domain/holiday_entry.dart';
import 'package:cuadrante/features/holidays/domain/substituted_holidays.dart';
import 'package:cuadrante/features/holidays/domain/text_fold.dart';
import 'package:cuadrante/features/holidays/presentation/holiday_pickers.dart';
import 'package:cuadrante/features/holidays/presentation/holidays_settings_providers.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

void main() {
  setUpAll(initializeLocale);

  // Tall enough for a whole year of holidays without scrolling.
  const tall = Size(390, 2900);

  Finder key(String value) => find.byKey(ValueKey(value));

  /// Settings -> Festivos.
  Future<void> openHolidays(WidgetTester tester, AppUnderTest app) async {
    await app.openSettings();
    await tester.ensureVisible(key('settings-holidays'));
    await tester.pumpAndSettle();
    await tester.tap(key('settings-holidays'));
    await tester.pumpAndSettle();
    expect(key('holidays-region'), findsOneWidget);
  }

  /// Loads the municipality index with real I/O (an asset read does not
  /// complete under fake time) so the picker finds it ready.
  Future<void> warmIndex(WidgetTester tester, AppUnderTest app) async {
    await tester.runAsync(
      () => app.container.read(municipalityIndexProvider.future),
    );
    await tester.pump();
  }

  Future<void> chooseRegion(WidgetTester tester, String code) async {
    await tester.tap(key('holidays-region'));
    await tester.pumpAndSettle();
    await tester.tap(key('region-option-$code'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseMunicipality(
    WidgetTester tester,
    String search,
    String code,
  ) async {
    await tester.tap(key('holidays-municipality'));
    await tester.pumpAndSettle();
    await tester.enterText(key('municipality-search'), search);
    await tester.pumpAndSettle();
    await tester.tap(key('municipality-option-$code'));
    await tester.pumpAndSettle();
  }

  Finder inRow(String rowKey, Finder matching) =>
      find.descendant(of: key(rowKey), matching: matching);

  /// Back to the month screen and forward to December 2026.
  Future<void> monthOfDecember(WidgetTester tester, AppUnderTest app) async {
    await app.back();
    await app.back();
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Diciembre'), findsOneWidget);
  }

  group('the screen', () {
    testWidgets(
      'opens from Settings with nobody chosen and national days only',
      (tester) async {
        final app = await AppUnderTest.pump(tester, size: tall);
        await app.openSettings();
        expect(
          inRow('settings-holidays', find.text('Sin elegir')),
          findsOneWidget,
        );

        await tester.tap(key('settings-holidays'));
        await tester.pumpAndSettle();

        expect(find.text('Festivos'), findsWidgets);
        expect(
          inRow('holidays-region', find.text('Sin elegir')),
          findsOneWidget,
        );
        // The municipality needs a community first.
        expect(
          inRow('holidays-municipality', find.text('Elige antes la comunidad')),
          findsOne,
        );
        expect(
          find.text(
            'Sin comunidad solo salen los festivos nacionales. '
            'Elige la tuya para ver los autonómicos.',
          ),
          findsOne,
        );
        // 2026 national days, nothing regional.
        expect(find.text('Año Nuevo'), findsOneWidget);
        expect(find.text('Natividad del Señor'), findsOneWidget);
        expect(find.text('San Esteban'), findsNothing);
        expect(find.text('Epifanía del Señor'), findsNothing);
        expect(key('holidays-substituted'), findsNothing);
        // Grouped by month, with the scope in words.
        expect(find.text('ENERO'), findsOneWidget);
        expect(find.text('DICIEMBRE'), findsOneWidget);
        expect(
          inRow('holiday-row-2026-01-01-0', find.text('Nacional')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'the region picker lists the 19 alphabetically, current marked',
      (tester) async {
        final app = await AppUnderTest.pump(
          tester,
          size: tall,
          prepare: (db) async {
            // Stored before the app starts.
            await db.customStatement(
              "INSERT INTO settings (key, value) VALUES ('holidays.region', '\"ES-CT\"')",
            );
          },
        );
        await openHolidays(tester, app);
        expect(
          inRow('holidays-region', find.text('Catalunya')),
          findsOneWidget,
        );

        await tester.tap(key('holidays-region'));
        await tester.pumpAndSettle();

        final names = [
          for (final r in alphabeticalRegions)
            find
                .descendant(
                  of: key('region-option-${r.code}'),
                  matching: find.byType(Text),
                )
                .evaluate()
                .map((e) => (e.widget as Text).data)
                .single,
        ];
        expect(names, hasLength(19));
        expect(
          names.first,
          'Andalucía',
          reason: 'accents do not decide the order',
        );
        expect(names, containsAllInOrder(['Aragón', 'Canarias', 'Cantabria']));
        expect(names.last, 'Región de Murcia');
        // Current one marked with a check.
        expect(
          find.descendant(
            of: key('region-option-ES-CT'),
            matching: find.byType(Icon),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: key('region-option-ES-MD'),
            matching: find.byType(Icon),
          ),
          findsNothing,
        );
      },
    );
  });

  group('region', () {
    testWidgets(
      'choosing Catalunya lists its holidays and marks them in the month',
      (tester) async {
        final app = await AppUnderTest.pump(tester, size: tall);
        await openHolidays(tester, app);
        expect(find.text('San Esteban'), findsNothing);

        await chooseRegion(tester, 'ES-CT');

        expect(
          inRow('holidays-region', find.text('Catalunya')),
          findsOneWidget,
        );
        // Regional holidays with the community as the chip; the kept
        // national-optional day (Epifanía) is national.
        expect(find.text('San Esteban'), findsOneWidget);
        expect(
          inRow('holiday-row-2026-12-26-0', find.text('Catalunya')),
          findsOneWidget,
        );
        expect(
          inRow('holiday-row-2026-01-06-0', find.text('Nacional')),
          findsOneWidget,
        );
        expect(find.text('Lunes de Pascua'), findsOneWidget);
        // The status asks for the municipality.
        expect(
          find.text(
            'Elige tu municipio para ver sus festivos locales, '
            'o añádelos tú abajo.',
          ),
          findsOneWidget,
        );
        // The Settings row follows.
        expect(app.container.read(holidayPlaceProvider).regionCode, 'ES-CT');

        // The month grid refreshed on its own.
        await monthOfDecember(tester, app);
        expect(key('holiday-dot-2026-12-26'), findsOneWidget);
        expect(key('holiday-dot-2026-12-25'), findsOneWidget);
        await app.openSettings();
        expect(
          inRow('settings-holidays', find.text('Catalunya')),
          findsOneWidget,
        );
      },
    );

    testWidgets('the replaceable national days it does not keep are listed', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await chooseRegion(tester, 'ES-CT');

      expect(find.text('No son festivo en Catalunya'), findsOneWidget);
      expect(
        find.descendant(
          of: key('holidays-substituted'),
          matching: find.textContaining('Jueves Santo'),
        ),
        findsOneWidget,
      );

      // Madrid keeps Jueves Santo: it is a holiday in its list, not a note.
      await chooseRegion(tester, 'ES-MD');
      expect(
        inRow('holiday-row-2026-04-02-0', find.text('Nacional')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: key('holidays-substituted'),
          matching: find.textContaining('Jueves Santo'),
        ),
        findsNothing,
      );
    });

    testWidgets('«Sin comunidad» goes back to national days only', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await chooseRegion(tester, 'ES-CT');
      expect(find.text('San Esteban'), findsOneWidget);

      await chooseRegion(tester, 'none');

      expect(inRow('holidays-region', find.text('Sin elegir')), findsOneWidget);
      expect(find.text('San Esteban'), findsNothing);
      expect(app.container.read(holidayPlaceProvider).regionCode, isNull);
    });

    testWidgets('changing community drops the municipality', (tester) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await warmIndex(tester, app);
      await chooseRegion(tester, 'ES-CT');
      await chooseMunicipality(tester, 'barcelona', '08019');
      expect(
        app.container.read(holidayPlaceProvider).municipalityCode,
        '08019',
      );

      await chooseRegion(tester, 'ES-MD');

      final place = app.container.read(holidayPlaceProvider);
      expect(place.regionCode, 'ES-MD');
      expect(place.municipalityCode, isNull);
    });
  });

  group('municipality', () {
    testWidgets('Barcelona (08019) brings its local holidays', (tester) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await warmIndex(tester, app);
      await chooseRegion(tester, 'ES-CT');
      expect(find.text('Fiesta local'), findsNothing);

      await chooseMunicipality(tester, 'barcelona', '08019');

      expect(
        inRow('holidays-municipality', find.text('Barcelona')),
        findsOneWidget,
      );
      expect(
        find.text('Festivos locales de Barcelona: incluidos'),
        findsOneWidget,
      );
      // 25 May and 24 Sep, as Local.
      expect(
        inRow('holiday-row-2026-05-25-0', find.text('Fiesta local')),
        findsOneWidget,
      );
      expect(
        inRow('holiday-row-2026-05-25-0', find.text('Local')),
        findsOneWidget,
      );
      expect(key('holiday-row-2026-09-24-0'), findsOneWidget);
      // The grid marks 24 Sep as well (the Diada, 11 Sep, is regional).
      final stored = app.container.read(holidaysProvider);
      expect(stored[const CivilDate(2026, 5, 25)]?.scope, HolidayScope.local);

      // «Ninguno» takes them away again.
      await tester.tap(key('holidays-municipality'));
      await tester.pumpAndSettle();
      await tester.tap(key('municipality-option-none'));
      await tester.pumpAndSettle();
      expect(find.text('Fiesta local'), findsNothing);
      expect(
        inRow('holidays-municipality', find.text('Ninguno')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Sevilla (41091) has none in the bundle: the screen says to add them',
      (tester) async {
        final app = await AppUnderTest.pump(tester, size: tall);
        await openHolidays(tester, app);
        await warmIndex(tester, app);
        await chooseRegion(tester, 'ES-AN');

        await chooseMunicipality(tester, 'sevilla', '41091');

        expect(
          inRow('holidays-municipality', find.text('Sevilla')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Todavía no tenemos los de tu municipio: añádelos tú abajo',
          ),
          findsOneWidget,
        );
        expect(find.text('Fiesta local'), findsNothing);
        // Andalucía's own holidays are there.
        expect(find.text('Día de Andalucía'), findsOneWidget);
      },
    );

    testWidgets('the search ignores accents and case', (tester) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await warmIndex(tester, app);
      await chooseRegion(tester, 'ES-MD');

      await tester.tap(key('holidays-municipality'));
      await tester.pumpAndSettle();
      // The whole region, alphabetically, with «Ninguno» first.
      expect(key('municipality-option-none'), findsOneWidget);
      await tester.enterText(key('municipality-search'), 'alcala');
      await tester.pumpAndSettle();

      expect(key('municipality-option-28005'), findsOneWidget);
      expect(find.text('Alcalá de Henares'), findsOneWidget);
      expect(find.text('Valverde de Alcalá'), findsOneWidget);
      expect(find.text('Madrid'), findsNothing);
      // Names that start with it come first.
      final first = tester.getTopLeft(key('municipality-option-28005'));
      final contained = tester.getTopLeft(key('municipality-option-28166'));
      expect(first.dy, lessThan(contained.dy));
      // «Ninguno» is only for the unfiltered list.
      expect(key('municipality-option-none'), findsNothing);

      await tester.enterText(key('municipality-search'), 'ALCALÁ DE H');
      await tester.pumpAndSettle();
      expect(key('municipality-option-28005'), findsOneWidget);
      expect(find.text('Valverde de Alcalá'), findsNothing);

      await tester.enterText(key('municipality-search'), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('Ningún municipio coincide con «zzzz»'), findsOneWidget);
    });

    testWidgets('the search finds names with an apostrophe or a hyphen typed '
        'the way a phone keyboard does', (tester) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await warmIndex(tester, app);
      await chooseRegion(tester, 'ES-CT');

      await tester.tap(key('holidays-municipality'));
      await tester.pumpAndSettle();
      // Typographic apostrophe, as iOS and many keyboards type it.
      await tester.enterText(key('municipality-search'), 'l\u2019ametlla');
      await tester.pumpAndSettle();
      expect(key('municipality-option-43013'), findsOneWidget);
      expect(find.text("L'Ametlla de Mar"), findsOneWidget);

      // A space where the name has a hyphen.
      await tester.enterText(key('municipality-search'), 'palau solita');
      await tester.pumpAndSettle();
      expect(key('municipality-option-08156'), findsOneWidget);
    });

    testWidgets('a name that repeats in the region shows its province', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        overrides: [
          municipalityIndexProvider.overrideWith(
            (ref) => const MunicipalityIndex({
              'ES-AN': [
                Municipality('11001', 'Alcalá', 'ES-AN'),
                Municipality('41001', 'Alcalá', 'ES-AN'),
                Municipality('41091', 'Sevilla', 'ES-AN'),
              ],
            }),
          ),
        ],
      );
      await openHolidays(tester, app);
      await chooseRegion(tester, 'ES-AN');
      await tester.tap(key('holidays-municipality'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: key('municipality-option-11001'),
          matching: find.text('Cádiz'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: key('municipality-option-41001'),
          matching: find.text('Sevilla'),
        ),
        findsOneWidget,
      );
      // A name that is alone in the region shows nothing under it.
      expect(
        find.descendant(
          of: key('municipality-option-41091'),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
    });
  });

  group('year', () {
    testWidgets('the next year has its own list and local holidays pending', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await warmIndex(tester, app);
      await chooseRegion(tester, 'ES-CT');
      await chooseMunicipality(tester, 'barcelona', '08019');
      expect(key('holidays-year-2026'), findsOneWidget);
      expect(key('holidays-year-2027'), findsOneWidget);
      expect(key('holidays-year-2028'), findsNothing);
      expect(key('holiday-row-2026-05-25-0'), findsOneWidget);

      await tester.tap(key('holidays-year-2027'));
      await tester.pumpAndSettle();

      // 2027: Viernes Santo is on 26 Mar, Todos los Santos is national on
      // a Monday 1 Nov, and Catalunya has no local file yet.
      expect(key('holiday-row-2026-05-25-0'), findsNothing);
      expect(
        inRow('holiday-row-2027-03-26-0', find.text('Viernes Santo')),
        findsOneWidget,
      );
      expect(find.text('Todos los Santos'), findsOneWidget);
      expect(find.text('San Juan'), findsOneWidget);
      expect(find.text('Fiesta local'), findsNothing);
      expect(
        find.text(
          'Todavía no tenemos los de Barcelona en 2027: añádelos tú abajo',
        ),
        findsOneWidget,
      );

      await tester.tap(key('holidays-year-2026'));
      await tester.pumpAndSettle();
      expect(key('holiday-row-2026-05-25-0'), findsOneWidget);
      expect(
        find.text('Festivos locales de Barcelona: incluidos'),
        findsOneWidget,
      );
    });
  });

  group('years outside the bundle', () {
    testWidgets('a year with no official data says so, and its own days '
        'make it selectable', (tester) async {
      // Two years on from the bundle (2026 and 2027).
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        clock: () => DateTime(2028, 3, 1, 12),
        expectMonth: false,
        prepare: (db) => db.customStatement(
          'INSERT INTO holidays (date, scope, name, source) '
          "VALUES ('2030-05-06', 'local', 'Mi fiesta de 2030', 'user')",
        ),
      );
      await openHolidays(tester, app);

      // Official years, the current one and the year of the person's own.
      for (final year in [2026, 2027, 2028, 2030]) {
        expect(key('holidays-year-$year'), findsOneWidget, reason: '$year');
      }
      expect(key('holidays-year-2029'), findsNothing);
      // Opens on the current year, which has nothing official yet.
      expect(
        find.text(
          'Los festivos oficiales de 2028 llegarán con una actualización',
        ),
        findsOneWidget,
      );
      expect(find.text('Todavía no tenemos los festivos de 2028.'), findsOne);

      await tester.tap(key('holidays-year-2030'));
      await tester.pumpAndSettle();
      expect(find.textContaining('oficiales de 2030'), findsOneWidget);
      expect(find.text('Mi fiesta de 2030'), findsOneWidget);

      await tester.tap(key('holidays-year-2027'));
      await tester.pumpAndSettle();
      expect(find.textContaining('oficiales de'), findsNothing);
      expect(find.text('Año Nuevo'), findsOneWidget);
    });
  });

  group('your own holidays', () {
    testWidgets('Q58: a closed editor can still be saving; the named holiday '
        'appears after completion and removal can be undone', (tester) async {
      final gate = Completer<void>();
      final app = await AppUnderTest.pump(
        tester,
        overrides: [
          holidayRepositoryProvider.overrideWith(
            (ref) => _DelayedHolidayRepository(
              ref.read(appDatabaseProvider),
              gate.future,
            ),
          ),
        ],
      );
      await openHolidays(tester, app);
      await tester.ensureVisible(key('holidays-add'));
      await tester.tap(key('holidays-add'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(CalendarDatePicker),
          matching: find.text('23'),
        ),
      );
      await tester.enterText(key('holiday-name-field'), 'San Fulano');
      await tester.ensureVisible(key('holiday-save'));
      await tester.tap(key('holiday-save'));
      await tester.pumpAndSettle();
      expect(key('holiday-save'), findsNothing);
      expect(find.text('San Fulano'), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      final row = key('holiday-row-2026-10-23-0');
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(
        inRow('holiday-row-2026-10-23-0', find.text('San Fulano')),
        findsOneWidget,
      );
      await tester.tap(key('holiday-remove-2026-10-23'));
      await tester.pumpAndSettle();
      expect(row, findsNothing);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(
        inRow('holiday-row-2026-10-23-0', find.text('San Fulano')),
        findsOneWidget,
      );
      final stored = await app.real(
        () => HolidayRepository(app.database).userHolidays(),
      );
      expect(stored.single.name, 'San Fulano');
    });

    Future<void> addLocal(
      WidgetTester tester, {
      required String day,
      String? name,
    }) async {
      await tester.tap(key('holidays-add'));
      await tester.pumpAndSettle();
      // Name prefilled and editable.
      final field = tester.widget<TextField>(key('holiday-name-field'));
      expect(field.controller!.text, 'Fiesta local');
      await tester.tap(
        find.descendant(
          of: find.byType(CalendarDatePicker),
          matching: find.text(day),
        ),
      );
      await tester.pump();
      if (name != null) {
        await tester.enterText(key('holiday-name-field'), name);
      }
      await tester.tap(key('holiday-save'));
      await tester.pumpAndSettle();
    }

    testWidgets('adding one: pick the day, keep or edit the name, save', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);

      await addLocal(tester, day: '22');

      expect(
        inRow('holiday-row-2026-10-22-0', find.text('Fiesta local')),
        findsOneWidget,
      );
      expect(
        inRow('holiday-row-2026-10-22-0', find.text('Tuyo')),
        findsOneWidget,
      );
      expect(
        app.container.read(holidaysProvider)[const CivilDate(2026, 10, 22)],
        isA<Holiday>().having((h) => h.isUserAdded, 'isUserAdded', isTrue),
      );

      await addLocal(tester, day: '23', name: 'San Fulano');
      expect(
        inRow('holiday-row-2026-10-23-0', find.text('San Fulano')),
        findsOneWidget,
      );

      // The month grid marks both without reloading anything.
      await app.back();
      await app.back();
      expect(key('holiday-dot-2026-10-22'), findsOneWidget);
      expect(key('holiday-dot-2026-10-23'), findsOneWidget);
    });

    testWidgets('removing one offers to undo exactly that removal', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await addLocal(tester, day: '22', name: 'Mi fiesta');
      await addLocal(tester, day: '23', name: 'Otra fiesta');

      await tester.tap(key('holiday-remove-2026-10-22'));
      await tester.pumpAndSettle();

      expect(key('holiday-row-2026-10-22-0'), findsNothing);
      expect(key('holiday-row-2026-10-23-0'), findsOneWidget);
      expect(find.text('Festivo quitado: Mi fiesta'), findsOneWidget);
      // The SnackBar has one action and it is «Deshacer».
      expect(find.byType(SnackBarAction), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byType(TextButton),
        ),
        findsOneWidget,
        reason: 'only the undo button',
      );
      expect(
        app.container.read(holidaysProvider)[const CivilDate(2026, 10, 22)],
        isNull,
      );

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(
        inRow('holiday-row-2026-10-22-0', find.text('Mi fiesta')),
        findsOneWidget,
      );
      expect(
        inRow('holiday-row-2026-10-23-0', find.text('Otra fiesta')),
        findsOneWidget,
      );
      expect(
        app.container
            .read(holidaysProvider)[const CivilDate(2026, 10, 22)]
            ?.name,
        'Mi fiesta',
      );
    });

    testWidgets('adding one on the day just removed drops the stale undo', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await addLocal(tester, day: '22', name: 'Mi fiesta');
      await tester.tap(key('holiday-remove-2026-10-22'));
      await tester.pumpAndSettle();
      expect(find.text('Deshacer'), findsOneWidget);

      await addLocal(tester, day: '22', name: 'Nueva');
      expect(find.text('Deshacer'), findsNothing);
      expect(
        inRow('holiday-row-2026-10-22-0', find.text('Nueva')),
        findsOneWidget,
      );
    });

    testWidgets('«Deshacer» never overwrites a holiday added meanwhile', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await addLocal(tester, day: '22', name: 'Mi fiesta');
      await tester.tap(key('holiday-remove-2026-10-22'));
      await tester.pumpAndSettle();

      // Added behind the screen's back (the SnackBar stays up).
      await tester.runAsync(
        () => app.container
            .read(holidayControllerProvider.notifier)
            .addUserHoliday(date: const CivilDate(2026, 10, 22), name: 'Nueva'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deshacer'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(
        app.container
            .read(holidaysProvider)[const CivilDate(2026, 10, 22)]
            ?.name,
        'Nueva',
      );
      expect(find.text('Mi fiesta'), findsNothing);
    });

    testWidgets('swiping a row away removes it too, with the same undo', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await addLocal(tester, day: '22', name: 'Mi fiesta');

      await tester.drag(
        key('holiday-dismiss-2026-10-22-0'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(key('holiday-row-2026-10-22-0'), findsNothing);
      expect(find.text('Festivo quitado: Mi fiesta'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        app.container.read(holidaysProvider)[const CivilDate(2026, 10, 22)],
        isNull,
      );

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(key('holiday-row-2026-10-22-0'), findsOneWidget);
    });

    testWidgets(
      'official holidays have no remove button and cannot be swiped',
      (tester) async {
        final app = await AppUnderTest.pump(tester, size: tall);
        await openHolidays(tester, app);

        expect(key('holiday-remove-2026-01-01'), findsNothing);
        expect(key('holiday-dismiss-2026-01-01-0'), findsNothing);
      },
    );

    testWidgets('one on an official day says it replaces it', (tester) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);
      await tester.runAsync(
        () => app.container
            .read(holidayControllerProvider.notifier)
            .addUserHoliday(
              date: const CivilDate(2026, 10, 12),
              name: 'Mi día',
            ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Sustituye a Fiesta Nacional de España'),
        findsOneWidget,
      );
      expect(find.text('En tu calendario lo tapa «Mi día»'), findsOneWidget);
      // The grid shows the person's own on that day.
      expect(
        app.container
            .read(holidaysProvider)[const CivilDate(2026, 10, 12)]
            ?.name,
        'Mi día',
      );
    });

    testWidgets('two own holidays on one date (a restored file) render', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        prepare: (db) async {
          for (final name in ['Una', 'Otra']) {
            await db.customStatement(
              'INSERT INTO holidays (date, scope, name, source) '
              "VALUES ('2026-10-22', 'local', '$name', 'user')",
            );
          }
        },
      );
      await openHolidays(tester, app);

      expect(tester.takeException(), isNull);
      expect(key('holiday-dismiss-2026-10-22-0'), findsOneWidget);
      expect(key('holiday-dismiss-2026-10-22-1'), findsOneWidget);
      expect(find.text('Una'), findsOneWidget);
      expect(find.text('Otra'), findsOneWidget);
    });

    testWidgets('adding one in the next year switches the list to it', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await openHolidays(tester, app);

      await tester.tap(key('holidays-year-2027'));
      await tester.pumpAndSettle();
      await tester.tap(key('holidays-add'));
      await tester.pumpAndSettle();
      // Opens on January of the year being looked at.
      expect(find.text('enero de 2027'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(CalendarDatePicker),
          matching: find.text('15'),
        ),
      );
      await tester.pump();
      await tester.tap(key('holiday-save'));
      await tester.pumpAndSettle();

      expect(key('holiday-row-2027-01-15-0'), findsOneWidget);
      expect(key('holidays-year-2027'), findsOneWidget);
    });
  });

  group('large text and dark', () {
    for (final scale in [1.3, 2.0]) {
      testWidgets('picking a community closes the sheet at x$scale', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final app = await AppUnderTest.pump(tester, size: tall);
        await openHolidays(tester, app);

        for (final (code, name) in [
          ('ES-CT', 'Catalunya'),
          ('ES-CN', 'Canarias'),
        ]) {
          await tester.tap(key('holidays-region'));
          await tester.pumpAndSettle();
          expect(key('region-option-$code'), findsOneWidget);
          await tester.ensureVisible(key('region-option-$code'));
          await tester.pumpAndSettle();
          await tester.tap(key('region-option-$code'));
          await tester.pumpAndSettle();

          expect(
            key('region-option-$code'),
            findsNothing,
            reason: 'the sheet is closed after picking $name',
          );
          expect(
            inRow('holidays-region', find.text(name)),
            findsOneWidget,
            reason: 'the row shows $name',
          );
        }

        // Picking the community already chosen just closes the sheet.
        await tester.tap(key('holidays-region'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(key('region-option-ES-CN'));
        await tester.pumpAndSettle();
        await tester.tap(key('region-option-ES-CN'));
        await tester.pumpAndSettle();
        expect(key('region-option-ES-CN'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('nothing overflows at x$scale in the dark', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final app = await AppUnderTest.pump(
          tester,
          size: tall,
          platformBrightness: Brightness.dark,
        );
        await openHolidays(tester, app);
        await warmIndex(tester, app);
        await chooseRegion(tester, 'ES-CN');
        await chooseMunicipality(tester, 'palmas', '35016');
        await tester.runAsync(
          () => app.container
              .read(holidayControllerProvider.notifier)
              .addUserHoliday(
                date: const CivilDate(2026, 10, 12),
                name: 'Una fiesta con un nombre bastante largo del barrio',
              ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(key('holidays-region'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(key('region-option-ES-NC'), findsOneWidget);
      });
    }
  });

  group('pure helpers', () {
    test('foldSpanish drops accents and case', () {
      expect(foldSpanish('Alcalá de Henares'), 'alcala de henares');
      expect(foldSpanish('PEÑÍSCOLA'), 'peniscola');
      expect(foldSpanish("L'Hospitalet"), "l'hospitalet");
      expect(compareSpanish('Ávila', 'Badajoz'), lessThan(0));
      expect(compareSpanish('Aragón', 'Andalucía'), greaterThan(0));
    });

    test('foldSpanish folds typographic apostrophes, hyphens and the dot', () {
      expect(foldSpanish('l\u2019ametlla'), "l'ametlla");
      expect(foldSpanish('L\u2018Ametlla de Mar'), "l'ametlla de mar");
      expect(foldSpanish('Palau-solità'), 'palau solita');
      expect(foldSpanish('palau solita'), foldSpanish('Palau-solità'));
      expect(foldSpanish('Vall\u00b7llobrega'), 'vallllobrega');
    });

    test('the 19 regions come out alphabetical, accents ignored', () {
      expect(alphabeticalRegions, hasLength(19));
      final names = [for (final r in alphabeticalRegions) r.name];
      expect([
        for (final n in names) foldSpanish(n),
      ], orderedEquals([for (final n in names) foldSpanish(n)]..sort()));
      expect(names.first, 'Andalucía');
    });

    test(
      'substitutedNationalDays: what some region keeps and this one does not',
      () {
        HolidayEntry kept(String region, String iso, String name) =>
            HolidayEntry(
              date: CivilDate.parse(iso),
              scope: HolidayScope.national,
              name: name,
              regionCode: region,
            );
        final rows = [
          kept('ES-MD', '2026-04-02', 'Jueves Santo'),
          kept('ES-AN', '2026-04-02', 'Jueves Santo'),
          kept(
            'ES-MD',
            '2026-12-07',
            'Lunes siguiente al Día de la Constitución',
          ),
          kept(
            'ES-RI',
            '2026-12-07',
            'Lunes siguiente al Día de la Constitución Española',
          ),
          kept(
            'ES-AN',
            '2026-12-07',
            'Lunes siguiente al Día de la Constitución',
          ),
          kept('ES-CT', '2026-01-06', 'Epifanía del Señor'),
          kept('ES-MD', '2026-01-06', 'Epifanía del Señor'),
          kept('ES-MD', '2027-03-25', 'Jueves Santo'),
        ];

        List<String> run(String? region, int year) => [
          for (final d in substitutedNationalDays(
            regionalNational: rows,
            regionCode: region,
            year: year,
          ))
            '${d.date.toIso()} ${d.name}',
        ];

        expect(run('ES-CT', 2026), [
          '2026-04-02 Jueves Santo',
          '2026-12-07 Lunes siguiente al Día de la Constitución',
        ]);
        expect(run('ES-MD', 2026), isEmpty);
        expect(run('ES-CT', 2027), ['2027-03-25 Jueves Santo']);
        expect(run(null, 2026), isEmpty, reason: 'nothing chosen yet');
        expect(run('xx', 2026), isEmpty);
      },
    );
  });
}

class _DelayedHolidayRepository extends HolidayRepository {
  _DelayedHolidayRepository(super.db, this.ready);
  final Future<void> ready;

  @override
  Future<void> addUserHoliday({
    required CivilDate date,
    required String name,
    HolidayScope scope = HolidayScope.local,
  }) async {
    await ready;
    await super.addUserHoliday(date: date, name: name, scope: scope);
  }
}
