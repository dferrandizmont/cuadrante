import 'dart:convert';
import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/format/text_fold.dart';
import 'package:cuadrante/core/icons/app_icons.dart';
import 'package:cuadrante/core/widgets/choice_row.dart';
import 'package:cuadrante/features/holidays/data/holiday_bundle_format.dart';
import 'package:cuadrante/features/holidays/presentation/holiday_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onboarding_support.dart';

/// «Tu comunidad» and «Tu municipio» (H-T01-3 and H-T01-4): the municipalities
/// in alphabetical order, and both sheets built from the same row.
void main() {
  setUpAll(initializeLocale);

  group('order of the municipalities', () {
    late MunicipalityIndex index;

    setUpAll(() {
      final json = jsonDecode(
        File('assets/holidays/municipalities.json').readAsStringSync(),
      ) as Map<String, Object?>;
      index = MunicipalityIndex.fromJson(json);
    });

    test('Catalunya is sorted by name, not by province and INE code', () {
      final names = [for (final m in index.inRegionByName('ES-CT')) m.name];
      expect(names, hasLength(947));
      expect(
        names.indexOf('Aiguafreda'),
        lessThan(names.indexOf('Avinyó')),
        reason:
            'Aiguafreda (Barcelona) goes before Avinyó (Barcelona) and '
            'Avinyonet (Girona)',
      );
      expect(
        names.indexOf('Avinyó'),
        lessThan(names.indexOf('Avinyonet del Penedès')),
      );
      for (var i = 1; i < names.length; i++) {
        expect(
          compareSpanish(names[i - 1], names[i]),
          lessThanOrEqualTo(0),
          reason: '«${names[i - 1]}» before «${names[i]}»',
        );
      }
    });

    test('the displayed names are kept as they are', () {
      final names = {for (final m in index.inRegionByName('ES-CT')) m.name};
      expect(names, containsAll(["L'Ametlla de Mar", 'El Bruc', 'Albanyà']));
    });

    test('every region keeps all of its municipalities', () {
      for (final code in ['ES-CT', 'ES-MD', 'ES-AN', 'ES-CE']) {
        expect(
          index.inRegionByName(code),
          hasLength(index.inRegion(code).length),
          reason: code,
        );
      }
    });
  });

  testWidgets('the municipality sheet lists names in alphabetical order', (
    tester,
  ) async {
    final app = await FirstLaunch.open(tester, size: const Size(390, 1200));
    await app.tap(key('onboarding-profession-nursing'));
    await app.tap(key('onboarding-next'));
    await app.tap(key('onboarding-region'));
    await app.tap(find.text('Catalunya'));
    await app.tap(key('onboarding-municipality'));

    final shown = [
      for (final row in tester.widgetList<ChoiceRow>(find.byType(ChoiceRow)))
        row.label,
    ];
    expect(shown.length, greaterThan(8));
    for (var i = 1; i < shown.length; i++) {
      expect(
        compareSpanish(shown[i - 1], shown[i]),
        lessThanOrEqualTo(0),
        reason: '«${shown[i - 1]}» before «${shown[i]}»',
      );
    }
  });

  testWidgets('both sheets use the same row: same indent, no chevron', (
    tester,
  ) async {
    final app = await FirstLaunch.open(tester, size: const Size(390, 1200));
    await app.tap(key('onboarding-profession-nursing'));
    await app.tap(key('onboarding-next'));

    await app.tap(key('onboarding-region'));
    final communities = find.byType(ChoiceRow);
    expect(communities, findsWidgets);
    final communityX = tester
        .getTopLeft(
          find.descendant(of: communities.first, matching: find.byType(Text)),
        )
        .dx;
    final communityHeight = tester.getSize(communities.first).height;
    expect(
      find.descendant(
        of: communities,
        matching: find.byIcon(AppIcons.chevronRight),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Catalunya'));
    await tester.pumpAndSettle();

    await app.tap(key('onboarding-municipality'));
    final municipalities = find.byType(ChoiceRow);
    expect(municipalities, findsWidgets);
    final municipalityX = tester
        .getTopLeft(
          find.descendant(
            of: municipalities.first,
            matching: find.byType(Text),
          ),
        )
        .dx;
    expect(municipalityX, closeTo(communityX, 0.5));
    expect(
      tester.getSize(municipalities.first).height,
      closeTo(communityHeight, 0.5),
    );
    expect(
      find.descendant(
        of: municipalities,
        matching: find.byIcon(AppIcons.chevronRight),
      ),
      findsNothing,
    );
  });

  testWidgets('H-T10-3: the community sheet is the one of Ajustes › Festivos: '
      'same list in the same order, the chosen one marked', (tester) async {
    final app = await FirstLaunch.open(tester, size: const Size(390, 2600));
    await app.tap(key('onboarding-profession-nursing'));
    await app.tap(key('onboarding-next'));

    List<String> labels() => [
      for (final row in tester.widgetList<ChoiceRow>(find.byType(ChoiceRow)))
        row.label,
    ];

    await app.tap(key('onboarding-region'));
    // The alphabetical list of Ajustes (Illes Balears among the I's, not
    // after Galicia or second-to-last as in the order of the INE).
    expect(labels(), [for (final r in alphabeticalRegions) r.name]);
    expect(
      labels().indexOf('Illes Balears'),
      lessThan(labels().indexOf('La Rioja')),
    );
    // Same keys as in Ajustes.
    expect(key('region-option-ES-CT'), findsOneWidget);
    expect(
      find.text('Sin comunidad'),
      findsNothing,
      reason: 'nothing to clear',
    );
    await tester.tap(key('region-option-ES-CT'));
    await tester.pumpAndSettle();

    // Reopened, the chosen community carries the check, like in Ajustes.
    await app.tap(key('onboarding-region'));
    final chosen = find.descendant(
      of: key('region-option-ES-CT'),
      matching: find.byIcon(AppIcons.check),
    );
    expect(chosen, findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsOneWidget);
  });
}
