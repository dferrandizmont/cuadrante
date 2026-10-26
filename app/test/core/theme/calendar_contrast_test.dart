import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/features/calendar/presentation/day_cell.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same assertion is used by the real cell and the deliberately broken
/// two-band fixture below. Find the code's OWN nearest painted background.
void expectBandCodeReadable(WidgetTester tester, Finder code) {
  ColoredBox? band;
  tester.element(code).visitAncestorElements((element) {
    if (element.widget case final ColoredBox box) {
      band = box;
      return false;
    }
    return true;
  });
  expect(band, isNotNull);
  final text = tester.widget<Text>(code);
  expect(
    contrastRatio(text.style!.color!, band!.color),
    greaterThanOrEqualTo(kTextContrast),
  );
}

/// The contrast rules of `docs/diseno.md`: every text on its real background
/// reaches 4.5:1, rings and graphics 3:1, in both themes, in the month and
/// outside it.
void main() {
  // Every default shift colour, "Libre" included.
  final shifts = <String, Color>{
    'morning': ShiftPalette.morning,
    'afternoon': ShiftPalette.afternoon,
    'night': ShiftPalette.night,
    'guard': ShiftPalette.guard,
    'postNight': ShiftPalette.postNight,
    'vacation': ShiftPalette.vacation,
    'personalDay': ShiftPalette.personalDay,
    'rest': ShiftPalette.rest,
  };
  const themes = {
    Brightness.light: AppColors.light,
    Brightness.dark: AppColors.dark,
  };

  Matcher readable([double ratio = kTextContrast]) =>
      greaterThanOrEqualTo(ratio);

  for (final MapEntry(key: brightness, value: colors) in themes.entries) {
    testWidgets('${brightness.name}: band assertion rejects another band ink', (
      tester,
    ) async {
      final swatches = [
        for (final color in ShiftPalette.editorChoices)
          ShiftSwatch.forColor(color.toARGB32(), brightness),
      ];
      final broken = [
        for (final own in swatches)
          for (final other in swatches)
            if (contrastRatio(other.ink, own.tint) < kTextContrast)
              (own, other),
      ];
      expect(
        broken,
        isNotEmpty,
        reason: 'a wrong-band fixture must really fail AA',
      );
      final (own, other) = broken.first;
      Future<void> render(Color ink) => tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              ColoredBox(
                color: other.tint,
                child: Text('A', style: TextStyle(color: other.ink)),
              ),
              ColoredBox(
                color: own.tint,
                child: Text('B', style: TextStyle(color: ink)),
              ),
            ],
          ),
        ),
      );
      await render(other.ink);
      expectBandCodeReadable(tester, find.text('A'));
      expect(
        () => expectBandCodeReadable(tester, find.text('B')),
        throwsA(isA<TestFailure>()),
      );
      await render(own.ink);
      expectBandCodeReadable(tester, find.text('B'));
    });
    for (final painted in [false, true]) {
      for (final selected in [false, true]) {
        testWidgets(
          '${brightness.name}: each rendered multi-shift band reaches AA, '
          'painted=$painted selected=$selected',
          (tester) async {
            const date = CivilDate(2026, 10, 12);
            final rest = ShiftType(
              id: 'rest',
              code: 'L',
              name: 'Libre',
              colorValue: ShiftPalette.rest.toARGB32(),
              category: ShiftCategory.rest,
            );
            final morning = ShiftType(
              id: 'morning',
              code: 'M',
              name: 'Mañana',
              colorValue: ShiftPalette.morning.toARGB32(),
              category: ShiftCategory.work,
              startMinute: 6 * 60,
              endMinute: 14 * 60,
            );
            final night = ShiftType(
              id: 'night',
              code: 'N',
              name: 'Noche',
              colorValue: ShiftPalette.night.toARGB32(),
              category: ShiftCategory.work,
              startMinute: 22 * 60,
              endMinute: 6 * 60,
            );
            for (final inMonth in [true, false]) {
              for (final types in [
                [rest, morning],
                [morning, rest],
                [rest, morning, night],
              ]) {
                final day = Schedule(
                  shiftTypes: types,
                  entries: {
                    date: DayEntry(
                      date: date,
                      shiftTypeIds: [for (final shift in types) shift.id],
                    ),
                  },
                ).resolve(date);
                await tester.pumpWidget(
                  MaterialApp(
                    theme: brightness == Brightness.dark
                        ? AppTheme.dark()
                        : AppTheme.light(),
                    locale: const Locale('es'),
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: Center(
                      child: SizedBox(
                        width: 100,
                        height: 180,
                        child: DayCell(
                          day: day,
                          holiday: null,
                          inMonth: inMonth,
                          isToday: false,
                          painted: painted,
                          selected: selected,
                        ),
                      ),
                    ),
                  ),
                );
                final cell = find.byType(DayCell);
                final actualBackgrounds = <Color>[];
                for (final shift in types) {
                  final code = find.descendant(
                    of: cell,
                    matching: find.text(shift.code),
                  );
                  expect(code, findsOneWidget);
                  expectBandCodeReadable(tester, code);
                  // The nearest painted ancestor is THIS band's background,
                  // not the first band's tint or the bottom colour bar.
                  ColoredBox? band;
                  tester.element(code).visitAncestorElements((element) {
                    if (element.widget case final ColoredBox box) {
                      band = box;
                      return false;
                    }
                    return true;
                  });
                  expect(band, isNotNull);
                  final background = band!.color;
                  actualBackgrounds.add(background);
                  final swatch = ShiftSwatch.forColor(
                    shift.colorValue,
                    brightness,
                    outOfMonth: !inMonth,
                  );
                  expect(
                    background,
                    painted || (selected && inMonth)
                        ? swatch.disc
                        : swatch.tint,
                  );
                  // Check every rendered code against its own band.
                  // Multi-shift cells currently show compact codes only;
                  // times remain in their spoken label and day detail.
                  for (final text in tester.widgetList<Text>(
                    find.descendant(
                      of: find.byWidget(band!),
                      matching: find.byType(Text),
                    ),
                  )) {
                    expect(
                      contrastRatio(text.style!.color!, background),
                      readable(),
                      reason:
                          '${text.data}, ${types.map((s) => s.id).join('+')}, '
                          'inMonth=$inMonth, painted=$painted, '
                          'selected=$selected, ${brightness.name}',
                    );
                  }
                }
                // Grey neighbouring days intentionally share surfaceMuted.
                expect(
                  actualBackgrounds.toSet(),
                  hasLength(inMonth ? types.length : 1),
                );
                expect(tester.takeException(), isNull);
              }
            }
          },
        );
        testWidgets(
          '${brightness.name}: rendered painted=$painted selected=$selected '
          'text reaches AA on its actual background for the entire catalog',
          (tester) async {
            const date = CivilDate(2026, 10, 12);
            for (final inMonth in [true, false]) {
              // null covers the empty selected public holiday (4.22:1 before).
              for (final color in [null, ...ShiftPalette.editorChoices]) {
                final shift = color == null
                    ? null
                    : ShiftType(
                        id: 'test',
                        code: 'T',
                        name: 'Test',
                        colorValue: color.toARGB32(),
                        category: ShiftCategory.work,
                        startMinute: 14 * 60,
                        endMinute: 22 * 60,
                      );
                final day = Schedule(
                  shiftTypes: [?shift],
                  entries: {
                    date: DayEntry(
                      date: date,
                      shiftTypeIds: [if (shift != null) shift.id],
                    ),
                  },
                ).resolve(date);
                await tester.pumpWidget(
                  MaterialApp(
                    theme: brightness == Brightness.dark
                        ? AppTheme.dark()
                        : AppTheme.light(),
                    locale: const Locale('es'),
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: DayCell(
                          day: day,
                          holiday: const Holiday(
                            date: date,
                            name: 'Fiesta',
                            scope: HolidayScope.national,
                          ),
                          inMonth: inMonth,
                          isToday: false,
                          painted: painted,
                          selected: selected,
                        ),
                      ),
                    ),
                  ),
                );
                final cell = find.byType(DayCell);
                final backgrounds = tester.widgetList<ColoredBox>(
                  find.descendant(of: cell, matching: find.byType(ColoredBox)),
                );
                final background = backgrounds.first.color;
                for (final text in tester.widgetList<Text>(
                  find.descendant(of: cell, matching: find.byType(Text)),
                )) {
                  expect(
                    contrastRatio(text.style!.color!, background),
                    readable(),
                    reason:
                        '${text.data}, $color, inMonth=$inMonth, '
                        'painted=$painted, selected=$selected, ${brightness.name}',
                  );
                }
                // Selection is a border, never a wash painted over the glyphs.
                for (final box in tester.widgetList<DecoratedBox>(
                  find.descendant(
                    of: cell,
                    matching: find.byType(DecoratedBox),
                  ),
                )) {
                  final decoration = box.decoration as BoxDecoration;
                  if (decoration.shape != BoxShape.circle) {
                    expect(decoration.color, isNull);
                  }
                }
                expect(tester.takeException(), isNull);
              }
            }
          },
        );
      }
    }
    for (final outOfMonth in [false, true]) {
      group(
        '${brightness.name} ${outOfMonth ? 'out-of-month' : 'in-month'}',
        () {
          for (final MapEntry(key: name, value: color) in shifts.entries) {
            ShiftSwatch swatch() => ShiftSwatch.forColor(
              color.toARGB32(),
              brightness,
              outOfMonth: outOfMonth,
            );

            test('$name: ink reaches AA on the tint and on the disc', () {
              final s = swatch();
              expect(contrastRatio(s.ink, s.tint), readable());
              expect(contrastRatio(s.ink, s.disc), readable());
            });

            if (!outOfMonth) {
              test('$name: ink reaches AA on the surface (card label)', () {
                expect(contrastRatio(swatch().ink, colors.surface), readable());
              });

              test('$name: the bar shows against the surface', () {
                final s = swatch();
                if (!s.isRest && brightness == Brightness.dark) {
                  expect(
                    s.bar.computeLuminance(),
                    greaterThanOrEqualTo(ShiftSwatch.minDarkBarLuminance),
                  );
                }
                expect(
                  contrastRatio(s.bar, colors.surface),
                  greaterThanOrEqualTo(s.isRest ? 1.2 : 2.0),
                );
              });

              test(
                '$name: today ring reaches 3:1 on the tint and the surface',
                () {
                  final s = swatch();
                  expect(contrastRatio(colors.todayRing, s.tint), readable(3));
                  expect(contrastRatio(colors.todayRing, s.disc), readable(3));
                  expect(
                    contrastRatio(colors.todayRing, colors.surface),
                    readable(3),
                  );
                },
              );
            }

            test('$name: day number, time and holiday number reach AA', () {
              final s = swatch();
              final number = s.legible(
                outOfMonth ? colors.textMuted : colors.textSecondary,
              );
              expect(contrastRatio(number, s.tint), readable());
              expect(
                contrastRatio(s.legible(colors.textMuted), s.tint),
                readable(),
              );
              expect(
                contrastRatio(s.legible(colors.holiday), s.tint),
                readable(),
              );
            });

            test('$name: legible only moves a token that needs it', () {
              final s = swatch();
              for (final token in [colors.textSecondary, colors.textMuted]) {
                if (contrastRatio(token, s.tint) >= kTextContrast) {
                  expect(s.legible(token), token);
                }
              }
            });
          }

          test('empty day: number and holiday reach AA', () {
            final s = ShiftSwatch.none(brightness, outOfMonth: outOfMonth);
            final background = outOfMonth
                ? colors.surfaceMuted
                : colors.surface;
            expect(s.tint, background);
            expect(
              contrastRatio(
                s.legible(outOfMonth ? colors.textMuted : colors.textSecondary),
                background,
              ),
              readable(),
            );
            expect(
              contrastRatio(s.legible(colors.holiday), background),
              readable(),
            );
          });
        },
      );
    }

    group('${brightness.name} tokens', () {
      test('the spec token pairs reach AA', () {
        final pairs = <String, (Color, Color)>{
          'textPrimary/background': (colors.textPrimary, colors.background),
          'textPrimary/surface': (colors.textPrimary, colors.surface),
          'textSecondary/surface': (colors.textSecondary, colors.surface),
          'textMuted/background': (colors.textMuted, colors.background),
          'textMuted/surface': (colors.textMuted, colors.surface),
          'textMuted/surfaceMuted': (colors.textMuted, colors.surfaceMuted),
          'textMuted/surfaceRaised': (colors.textMuted, colors.surfaceRaised),
          'accentText/surface': (colors.accentText, colors.surface),
          'holiday/surface': (colors.holiday, colors.surface),
          'onAccent/accent': (colors.onAccent, colors.accent),
          'onHighlight/highlight': (colors.onHighlight, colors.highlight),
          'onPrimaryButton/primaryButton': (
            colors.onPrimaryButton,
            colors.primaryButton,
          ),
          'onFab/fab': (colors.onFab, colors.fab),
        };
        for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
          expect(
            contrastRatio(fg, bg),
            readable(),
            reason: '$name in ${brightness.name}',
          );
        }
      });

      test('rings and icons reach 3:1', () {
        expect(contrastRatio(colors.todayRing, colors.surface), readable(3));
        expect(contrastRatio(colors.todayRing, colors.background), readable(3));
        // The brush icon of the "Pintar" button.
        expect(contrastRatio(colors.highlight, colors.fab), readable(3));
        // Resting outline of inputs and switches.
        expect(
          contrastRatio(colors.controlBorder, colors.surface),
          readable(3),
        );
      });
    });
  }
}
