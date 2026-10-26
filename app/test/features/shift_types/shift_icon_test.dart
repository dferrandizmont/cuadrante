import 'package:cuadrante/features/calendar/presentation/shift_icon_glyph.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';
import 'shift_types_screen_test.dart'
    show
        openNewShift,
        openShiftTypes,
        save,
        stateOf,
        storedSnapshot,
        tapKey,
        typeInto;

// The icon of a shift type (A8): the symbol of each key, the picker in the
// editor and where the icon shows.

Finder _key(String key) => find.byKey(ValueKey(key));

String _label(WidgetTester tester) {
  final button = find.descendant(
    of: _key('shift-icon'),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(button.first).data!;
}

Future<void> _openPicker(WidgetTester tester) async {
  await tapKey(tester, 'shift-icon');
  expect(_key('shift-icon-grid'), findsOneWidget);
}

Future<void> _pick(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pump();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

void main() {
  group('the symbols', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      test('${platform.name}: every key has its own symbol', () {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final seen = <String, ShiftIcon>{};
        for (final icon in ShiftIcon.values) {
          final data = icon.data;
          final id = '${data.fontFamily}:${data.codePoint}';
          expect(
            seen.containsKey(id),
            isFalse,
            reason: '${icon.key} repeats ${seen[id]?.key}',
          );
          seen[id] = icon;
        }
        expect(seen, hasLength(ShiftIcon.values.length));
      });
    }

    test('Android draws Material Symbols rounded, iOS the SF-like set', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = [for (final i in ShiftIcon.values) i.data];
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ios = [for (final i in ShiftIcon.values) i.data];
      for (var i = 0; i < android.length; i++) {
        expect(android[i], isNot(ios[i]), reason: ShiftIcon.values[i].key);
        expect(ios[i].fontFamily, 'CupertinoIcons');
        expect(android[i].fontFamily, isNot('CupertinoIcons'));
      }
    });
  });

  group('the editor', () {
    testWidgets('a new shift has no icon; the grid has «Sin icono» and the '
        'whole set', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      expect(_label(tester), 'Sin icono');
      await _openPicker(tester);
      expect(_key('shift-icon-none'), findsOneWidget);
      for (final icon in ShiftIcon.values) {
        expect(
          _key('shift-icon-${icon.key}'),
          findsOneWidget,
          reason: icon.key,
        );
      }
      // «Sin icono» is the selected one.
      expect(
        tester.getSemantics(_key('shift-icon-none')),
        matchesSemantics(
          label: 'Sin icono',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasEnabledState: false,
          isFocusable: false,
        ),
      );
    });

    testWidgets('picking one shows it in the button and a new shift is saved '
        'with it', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Refuerzo');
      await _openPicker(tester);
      await _pick(tester, 'shift-icon-ambulance');
      expect(_key('shift-icon-grid'), findsNothing);
      expect(_label(tester), 'Icono: Ambulancia');

      await save(tester);
      final created = stateOf(tester).palette.last;
      expect(created.name, 'Refuerzo');
      expect(created.icon, ShiftIcon.ambulance);
      final stored = await storedSnapshot(tester);
      expect(
        stored.schedule.shiftTypeById(created.id)!.icon,
        ShiftIcon.ambulance,
      );
    });

    testWidgets('dismissing the grid changes nothing', (tester) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await tester.tap(_key('shift-row-night'));
      await tester.pumpAndSettle();
      await _openPicker(tester);
      await _pick(tester, 'shift-icon-moon');
      expect(_label(tester), 'Icono: Luna');

      await _openPicker(tester);
      // The moon is the selected one now.
      expect(
        tester.getSemantics(_key('shift-icon-moon')),
        matchesSemantics(
          label: 'Luna',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasEnabledState: false,
          isFocusable: false,
        ),
      );
      await tester.tapAt(const Offset(5, 5)); // the scrim
      await tester.pumpAndSettle();
      expect(_key('shift-icon-grid'), findsNothing);
      expect(_label(tester), 'Icono: Luna');
    });

    testWidgets('an existing shift keeps its icon through other edits, can '
        'change it and can lose it', (tester) async {
      await pumpCalendar(
        tester,
        prepare: (ScheduleRepository repository) async {
          await repository.saveShiftType(
            shiftTemplates
                .firstWhere((t) => t.key == 'night')
                .toShiftType('night')
                .copyWith(icon: ShiftIcon.moon),
          );
        },
      );
      await openShiftTypes(tester);
      await tester.tap(_key('shift-row-night'));
      await tester.pumpAndSettle();
      expect(_label(tester), 'Icono: Luna');

      // Editing something else does not lose it.
      await typeInto(tester, 'shift-rate', '14');
      await save(tester);
      expect(
        stateOf(tester).schedule.shiftTypeById('night')!.icon,
        ShiftIcon.moon,
      );
      expect(
        stateOf(tester).schedule.shiftTypeById('night')!.hourlyRateCents,
        1400,
      );

      // Another icon.
      await tester.tap(_key('shift-row-night'));
      await tester.pumpAndSettle();
      await _openPicker(tester);
      await _pick(tester, 'shift-icon-hospital');
      await save(tester);
      expect(
        stateOf(tester).schedule.shiftTypeById('night')!.icon,
        ShiftIcon.hospital,
      );
      expect(
        (await storedSnapshot(tester)).schedule.shiftTypeById('night')!.icon,
        ShiftIcon.hospital,
      );

      // «Sin icono».
      await tester.tap(_key('shift-row-night'));
      await tester.pumpAndSettle();
      await _openPicker(tester);
      await _pick(tester, 'shift-icon-none');
      expect(_label(tester), 'Sin icono');
      await save(tester);
      expect(stateOf(tester).schedule.shiftTypeById('night')!.icon, isNull);
      expect(
        (await storedSnapshot(tester)).schedule.shiftTypeById('night')!.icon,
        isNull,
      );
    });

    testWidgets('the preview of the shift shows the icon when it fits', (
      tester,
    ) async {
      await pumpCalendar(tester);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await typeInto(tester, 'shift-name', 'Zeta');
      await typeInto(tester, 'shift-code', 'Z');
      await _openPicker(tester);
      await _pick(tester, 'shift-icon-star');
      await tester.ensureVisible(_key('shift-icon'));
      expect(find.byKey(const ValueKey('cell-icon')), findsWidgets);
    });

    testWidgets('320 dp wide, text x1.3: the picker and the form do not '
        'overflow', (tester) async {
      await pumpCalendar(tester, size: const Size(320, 640), textScale: 1.3);
      await openShiftTypes(tester);
      await openNewShift(tester);
      await _openPicker(tester);
      expect(tester.takeException(), isNull);
      // 48 dp targets everywhere.
      expect(tester.getSize(_key('shift-icon-sun')), const Size(48, 48));
      await _pick(tester, 'shift-icon-bus');
      expect(tester.takeException(), isNull);
    });
  });

  group('where the icon shows', () {
    Future<void> prepare(ScheduleRepository repository) async {
      await repository.saveShiftType(
        shiftTemplates
            .firstWhere((t) => t.key == 'night')
            .toShiftType('night')
            .copyWith(icon: ShiftIcon.moon),
      );
    }

    testWidgets('in the shift list and in the day detail rows', (tester) async {
      await pumpCalendar(tester, size: const Size(390, 1400), prepare: prepare);
      // Day detail of a Noche.
      await tester.tap(cell(const CivilDate(2026, 10, 20)));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('day-shift-0')),
          matching: find.byKey(const ValueKey('badge-icon')),
        ),
        findsOneWidget,
      );
      // The row of a shift without icon has none.
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(cell(const CivilDate(2026, 10, 26)));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('day-shift-0')),
          matching: find.byKey(const ValueKey('badge-icon')),
        ),
        findsNothing,
      );
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();

      await openShiftTypes(tester);
      expect(
        find.descendant(
          of: _key('shift-row-night'),
          matching: find.byKey(const ValueKey('badge-icon')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _key('shift-row-morning'),
          matching: find.byKey(const ValueKey('badge-icon')),
        ),
        findsNothing,
      );
    });

    testWidgets('in the annual legend', (tester) async {
      await pumpCalendar(tester, prepare: prepare);
      await tester.tap(_key('open-year'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        _key('year-legend-night'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(
          of: _key('year-legend-night'),
          matching: find.byKey(const ValueKey('legend-icon')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _key('year-legend-morning'),
          matching: find.byKey(const ValueKey('legend-icon')),
        ),
        findsNothing,
      );
    });
  });
}
