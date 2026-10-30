import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;

import 'dart:convert';
import 'dart:ui' show Brightness;

import 'package:cuadrante/core/theme/app_colors.dart';
import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot_builder.dart';
import 'package:cuadrante/features/widget/domain/widget_strings.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

import '../schedule/domain/fixtures.dart';

const _tz = 'Europe/Madrid';
final _generatedAt = DateTime.utc(2026, 10, 19, 8, 30);

ShiftType _type(String key) => allTypes.firstWhere((t) => t.id == key);

/// Rotation N, T, M, L starting on [start] (day 0 is a night).
Schedule _rotation(
  CivilDate start, {
  Map<CivilDate, DayEntry> entries = const {},
}) => Schedule(
  shiftTypes: allTypes,
  patterns: const [
    Pattern(
      id: 'rot',
      name: 'rot',
      steps: [
        ['night'],
        ['afternoon'],
        ['morning'],
        ['rest'],
      ],
    ),
  ],
  runs: [PatternRun(id: 'r', patternId: 'rot', startDate: start, seq: 1)],
  entries: entries,
);

WidgetSnapshot _build(
  CivilDate today, {
  Schedule? schedule,
  Map<CivilDate, Holiday> holidays = const {},
  WidgetStrings strings = WidgetStrings.es,
  int days = kWidgetDays,
  String timeZone = _tz,
  int weekStart = DateTime.monday,
}) => buildWidgetSnapshot(
  schedule: schedule ?? _rotation(today),
  holidays: holidays,
  today: today,
  timeZone: timeZone,
  strings: strings,
  days: days,
  weekStart: weekStart,
  generatedAt: _generatedAt,
);

Future<void> main() async {
  await initializeLocale();
  const today = CivilDate(2026, 10, 19);

  group('shape', () {
    test('60 consecutive days starting today', () {
      final s = _build(today);
      expect(s.days, hasLength(60));
      expect(s.firstDate, '2026-10-19');
      expect(s.lastDate, '2026-12-17');
      for (var i = 0; i < 60; i++) {
        final d = today.addDays(i);
        expect(s.days[i].date, d.toIso());
        expect(s.days[i].weekday, d.weekday);
        expect(s.days[i].dayOfMonth, d.day);
      }
      expect(s.days.first.weekdayShort, 'lun');
      expect(s.days.first.dateLabel, 'lun 19');
      expect(s.dayOn('2026-10-19'), same(s.days.first));
      expect(s.dayOn('2026-12-18'), isNull);
      expect(s.dayOn('2026-10-18'), isNull);
    });

    test('top-level metadata', () {
      final s = _build(today);
      expect(s.version, kWidgetSnapshotVersion);
      expect(s.timeZone, _tz);
      expect(s.locale, 'es');
      expect(s.generatedAt, _generatedAt);
      expect(s.staleTitle, 'Turnly');
      expect(s.staleBody, 'Abre Turnly para seguir al día');
      expect(s.weekdayHeaders, ['L', 'M', 'X', 'J', 'V', 'S', 'D']);
    });

    test('fewer days on request', () {
      final s = _build(today, days: 3);
      expect(s.days, hasLength(3));
      expect(s.lastDate, '2026-10-21');
    });

    test('crosses month and year boundaries', () {
      final s = _build(const CivilDate(2026, 12, 20));
      expect(s.firstDate, '2026-12-20');
      expect(s.lastDate, '2027-02-17');
      expect(s.days[11].date, '2026-12-31');
      expect(s.days[12].date, '2027-01-01');
      expect(s.days[12].dayOfMonth, 1);
      expect(s.months.map((m) => m.key), ['2026-12', '2027-01', '2027-02']);
      expect(s.months.map((m) => m.title), [
        'Diciembre 2026',
        'Enero 2027',
        'Febrero 2027',
      ]);
      // Every day points at the grid of its own month, on its own cell.
      for (final d in s.days) {
        final month = s.months[d.large.month];
        expect(month.key, d.date.substring(0, 7));
        expect(month.cells[d.large.todayCell].date, d.date);
        expect(month.cells[d.large.todayCell].inMonth, isTrue);
      }
    });

    test('month grid: 42 cells, Monday first, in-month flags', () {
      final s = _build(today);
      expect(s.months.map((m) => m.key), ['2026-10', '2026-11', '2026-12']);
      for (final m in s.months) {
        expect(m.cells, hasLength(kWidgetMonthCells));
        final first = CivilDate.parse(m.cells.first.date);
        expect(first.weekday, DateTime.monday);
        for (var i = 0; i < m.cells.length; i++) {
          expect(m.cells[i].date, first.addDays(i).toIso());
        }
        final month = int.parse(m.key.substring(5));
        expect(
          m.cells.where((c) => c.inMonth),
          hasLength(CivilDate(2026, month, 1).daysInMonth),
        );
        for (final c in m.cells) {
          expect(
            c.inMonth,
            CivilDate.parse(c.date).month == month,
            reason: c.date,
          );
        }
      }
      // October 2026 starts on a Thursday: the grid starts on Mon 28 Sep.
      expect(s.months.first.cells.first.date, '2026-09-28');
    });

    test('medium strip: 7 days from the day, first one is today', () {
      final s = _build(today);
      for (var i = 0; i < 60; i++) {
        final cells = s.days[i].medium.cells;
        expect(cells, hasLength(7));
        for (var j = 0; j < 7; j++) {
          expect(cells[j].date, today.addDays(i + j).toIso());
          expect(cells[j].isToday, j == 0);
        }
      }
      // The last day's strip runs past the 60 days with real data.
      expect(s.days.last.medium.cells.last.date, '2026-12-23');
      expect(s.days.last.medium.cells.last.bands, isNotEmpty);
    });
  });

  group('month grids of the large widget', () {
    test('Monday first (default): headers and grid start agree', () {
      final s = _build(today);
      expect(s.weekdayHeaders, ['L', 'M', 'X', 'J', 'V', 'S', 'D']);
      expect(s.months.first.cells.first.date, '2026-09-28'); // a Monday
    });

    test('Sunday first: headers rotate and every grid starts on a Sunday', () {
      final s = _build(today, weekStart: DateTime.sunday);
      expect(s.weekdayHeaders, ['D', 'L', 'M', 'X', 'J', 'V', 'S']);
      for (final m in s.months) {
        expect(m.cells, hasLength(kWidgetMonthCells));
        final first = CivilDate.parse(m.cells.first.date);
        expect(first.weekday, DateTime.sunday, reason: m.key);
        // The 1st is in the first row (the grid never starts a week early).
        final firstOfMonth = CivilDate.parse('${m.key}-01');
        expect(firstOfMonth.differenceInDays(first), inInclusiveRange(0, 6));
        for (var i = 0; i < m.cells.length; i++) {
          expect(m.cells[i].date, first.addDays(i).toIso());
        }
        expect(
          m.cells.where((c) => c.inMonth),
          hasLength(firstOfMonth.daysInMonth),
        );
      }
      expect(s.months.first.cells.first.date, '2026-09-27');
    });

    test('a month that starts on a Sunday begins its grid on the 1st only when '
        'the week starts on Sunday', () {
      // 2026-11-01 is a Sunday.
      final monday = _build(today).months.firstWhere((m) => m.key == '2026-11');
      final sunday = _build(
        today,
        weekStart: DateTime.sunday,
      ).months.firstWhere((m) => m.key == '2026-11');
      expect(monday.cells.first.date, '2026-10-26');
      expect(monday.cells.first.inMonth, isFalse);
      expect(sunday.cells.first.date, '2026-11-01');
      expect(sunday.cells.first.inMonth, isTrue);
      // The extra trailing week stays in the 6 x 7 grid, out of the month.
      expect(sunday.cells.last.date, '2026-12-12');
      expect(sunday.cells.last.inMonth, isFalse);
    });

    test(
      'todayCell points at the cell of that day, Monday or Sunday first',
      () {
        for (final weekStart in [DateTime.monday, DateTime.sunday]) {
          final s = _build(const CivilDate(2026, 12, 20), weekStart: weekStart);
          for (final d in s.days) {
            final month = s.months[d.large.month];
            expect(month.key, d.date.substring(0, 7), reason: '$weekStart');
            final cell = month.cells[d.large.todayCell];
            expect(cell.date, d.date, reason: '$weekStart ${d.date}');
            expect(cell.inMonth, isTrue);
            expect(cell.dayOfMonth, d.dayOfMonth);
          }
        }
      },
    );

    test('days outside the month are flagged and still carry real shifts', () {
      // A rotation that started long before today also gives the days before
      // it (the grid shows them) and the ones past the 60 published days.
      final s = _build(today, schedule: _rotation(today.addDays(-90)));
      final oct = s.months.first;
      final outBefore = oct.cells.first;
      expect(outBefore.date, '2026-09-28');
      expect(outBefore.inMonth, isFalse);
      expect(outBefore.bands, isNotEmpty);
      final dec = s.months.last;
      final outAfter = dec.cells.last;
      expect(outAfter.inMonth, isFalse);
      expect(
        CivilDate.parse(outAfter.date).isAfter(CivilDate.parse(s.lastDate)),
        isTrue,
      );
      expect(outAfter.bands, isNotEmpty);
      // The dimmed variant exists for every style a grid cell points at.
      for (final c in s.months.expand((m) => m.cells)) {
        for (final b in c.bands) {
          expect(b.style, inInclusiveRange(0, s.styles.length - 1));
        }
      }
    });

    test('a double-shift day has one band per shift, in order', () {
      final day = today.addDays(3);
      final s = _build(
        today,
        schedule: _rotation(
          today,
          entries: {
            day: DayEntry(date: day, shiftTypeIds: const ['morning', 'night']),
          },
        ),
      );
      final cell = s.months.first.cells.firstWhere(
        (c) => c.date == day.toIso(),
      );
      expect(cell.bands.map((b) => b.code), ['M', 'N']);
      expect(cell.bands[0].style, isNot(cell.bands[1].style));
    });

    test('the week start changes the content hash (so it republishes)', () {
      expect(
        _build(today).contentHash,
        isNot(_build(today, weekStart: DateTime.sunday).contentHash),
      );
    });
  });

  group('DST weekends do not skip or repeat a day', () {
    for (final (name, start) in [
      ('2026-10-25 (clocks back)', const CivilDate(2026, 10, 20)),
      ('2027-03-28 (clocks forward)', const CivilDate(2027, 3, 23)),
      ('starting on 2026-10-25', const CivilDate(2026, 10, 25)),
      ('starting on 2027-03-28', const CivilDate(2027, 3, 28)),
    ]) {
      test(name, () {
        final s = _build(start);
        final dates = s.days.map((d) => d.date).toList();
        expect(dates.toSet(), hasLength(60));
        for (var i = 0; i < 60; i++) {
          // Independent oracle: UTC calendar arithmetic.
          final expected = DateTime.utc(start.year, start.month, start.day + i);
          expect(
            dates[i],
            '${expected.year.toString().padLeft(4, '0')}-'
            '${expected.month.toString().padLeft(2, '0')}-'
            '${expected.day.toString().padLeft(2, '0')}',
          );
        }
        // The rotation still advances one step per day across the change.
        const codes = ['N', 'T', 'M', 'L'];
        for (var i = 0; i < 60; i++) {
          expect(s.days[i].small.big, codes[i % 4], reason: dates[i]);
        }
      });
    }
  });

  group('content of a day', () {
    test('single shift: small, medium and lock texts', () {
      final s = _build(today);
      final d = s.days.first; // Night
      expect(d.shifts, hasLength(1));
      expect(d.shifts.single.code, 'N');
      expect(d.shifts.single.name, 'Noche');
      expect(d.shifts.single.timeLabel, '22:00–06:00');
      expect(d.shifts.single.compactTime, '22–06');
      expect(d.shifts.single.category, 'work');
      expect(d.small.big, 'N');
      expect(d.small.isEmpty, isFalse);
      expect(d.small.detail, '22:00–06:00');
      expect(d.small.tomorrow, 'Mañana: T 14–22');
      expect(d.lock.inline, 'N · 22:00');
      expect(d.lock.circular, 'N');
      expect(d.lock.rectangular, ['N · 22:00–06:00', 'Mañana: T 14–22']);
      expect(d.medium.cells.first.bands.map((b) => b.code), ['N']);
      expect(d.isHoliday, isFalse);
      expect(d.holidayName, isNull);
      expect(d.hasNote, isFalse);
    });

    test('tomorrow on the last day comes from the schedule, not a gap', () {
      final s = _build(today);
      // Day 59 is index 59 % 4 = 3 (L); day 60 would be N.
      expect(s.days.last.small.big, 'L');
      expect(s.days.last.small.tomorrow, 'Mañana: N 22–06');
    });

    test('several shifts are joined', () {
      final s = _build(
        today,
        schedule: _rotation(
          today,
          entries: {
            today.addDays(1): DayEntry(
              date: today.addDays(1),
              shiftTypeIds: const ['morning', 'afternoon'],
            ),
          },
        ),
      );
      final d = s.days[1];
      expect(d.shifts.map((x) => x.code), ['M', 'T']);
      expect(d.small.big, 'M+T');
      expect(d.small.detail, '06–14 + 14–22');
      expect(d.lock.inline, 'M+T · 06:00');
      expect(d.lock.circular, 'M+');
      expect(d.lock.rectangular, ['M+T · 06–14 + 14–22', 'Mañana: M 06–14']);
      expect(d.medium.cells.first.bands.map((b) => b.code), ['M', 'T']);
      // The day before announces both.
      expect(s.days[0].small.tomorrow, 'Mañana: M 06–14 + T 14–22');
    });

    test('empty day uses the localized "Sin turno"', () {
      final s = _build(
        today,
        schedule: _rotation(
          today,
          entries: {today: DayEntry(date: today, shiftTypeIds: const [])},
        ),
      );
      final d = s.days.first;
      expect(d.shifts, isEmpty);
      expect(d.small.big, 'Sin turno');
      expect(d.small.isEmpty, isTrue);
      expect(d.small.detail, isNull);
      expect(d.lock.inline, 'Sin turno');
      expect(d.lock.circular, '–');
      expect(d.lock.rectangular, ['Sin turno', 'Mañana: T 14–22']);
      expect(d.medium.cells.first.bands, isEmpty);
      // And as tomorrow.
      expect(
        _build(
          today.addDays(-1),
          schedule: _rotation(
            today.addDays(-1),
            entries: {today: DayEntry(date: today, shiftTypeIds: const [])},
          ),
          days: 2,
        ).days.first.small.tomorrow,
        'Mañana: Sin turno',
      );
    });

    test('no schedule at all: every day is empty', () {
      final s = _build(today, schedule: Schedule());
      expect(s.days.every((d) => d.small.isEmpty), isTrue);
      expect(s.styles, isEmpty);
    });

    test('shift without schedule shows its name and code only', () {
      final s = _build(
        today,
        schedule: _rotation(
          today,
          entries: {
            today: DayEntry(date: today, shiftTypeIds: const ['vacation']),
          },
        ),
      );
      final d = s.days.first;
      expect(d.shifts.single.timeLabel, isNull);
      expect(d.shifts.single.compactTime, isNull);
      expect(d.shifts.single.category, 'absence');
      expect(d.small.big, 'V');
      expect(d.small.detail, 'Vacaciones');
      expect(d.lock.inline, 'V');
      expect(d.lock.rectangular.first, 'V · Vacaciones');
      expect(s.days.last.small.tomorrow, 'Mañana: N 22–06');
    });

    test('compact time keeps minutes when they are not :00', () {
      final custom = ShiftType(
        id: 'x',
        code: 'X',
        name: 'Partido',
        colorValue: 0xFF123456,
        category: ShiftCategory.work,
        startMinute: 7 * 60 + 30,
        endMinute: 15 * 60,
      );
      final s = _build(
        today,
        schedule: Schedule(
          shiftTypes: [custom],
          patterns: const [
            Pattern(
              id: 'p',
              name: 'p',
              steps: [
                ['x'],
              ],
            ),
          ],
          runs: [PatternRun(id: 'r', patternId: 'p', startDate: today, seq: 1)],
        ),
        days: 1,
      );
      expect(s.days.first.shifts.single.timeLabel, '07:30–15:00');
      expect(s.days.first.shifts.single.compactTime, '07:30–15');
      expect(s.days.first.small.tomorrow, 'Mañana: X 07:30–15');
    });

    test('holiday: flag and name on the day, the strip and the grid', () {
      final holiday = Holiday(
        date: const CivilDate(2026, 11, 1),
        name: 'Todos los Santos',
        scope: HolidayScope.national,
      );
      final s = _build(today, holidays: {holiday.date: holiday});
      final d = s.dayOn('2026-11-01')!;
      expect(d.isHoliday, isTrue);
      expect(d.holidayName, 'Todos los Santos');
      expect(s.dayOn('2026-11-02')!.isHoliday, isFalse);
      // In the strip of the day before...
      final strip = s.dayOn('2026-10-31')!.medium.cells;
      expect(strip.map((c) => c.isHoliday), [
        false,
        true,
        false,
        false,
        false,
        false,
        false,
      ]);
      // ...and in the November grid.
      final nov = s.months.firstWhere((m) => m.key == '2026-11');
      expect(nov.cells.where((c) => c.isHoliday).map((c) => c.date), [
        '2026-11-01',
      ]);
    });

    test('note: flag on the day, the strip and the grid', () {
      final noteDay = today.addDays(2);
      final s = _build(
        today,
        schedule: _rotation(
          today,
          entries: {noteDay: DayEntry(date: noteDay, note: 'Cambio con Marta')},
        ),
      );
      expect(s.days[2].hasNote, isTrue);
      expect(s.days[2].shifts, isNotEmpty); // a note does not hide the shift
      expect(s.days[1].hasNote, isFalse);
      expect(s.days[0].medium.cells[2].hasNote, isTrue);
      final oct = s.months.first;
      expect(oct.cells.where((c) => c.hasNote).map((c) => c.date), [
        '2026-10-21',
      ]);
      // An empty note is not a note.
      final blank = _build(
        today,
        schedule: _rotation(
          today,
          entries: {noteDay: DayEntry(date: noteDay, note: '')},
        ),
      );
      expect(blank.days[2].hasNote, isFalse);
    });

    test('localized strings are used verbatim', () {
      const ca = WidgetStrings(
        locale: 'ca',
        weekdaysShort: ['dl', 'dt', 'dc', 'dj', 'dv', 'ds', 'dg'],
        weekdayHeaders: ['dl', 'dt', 'dc', 'dj', 'dv', 'ds', 'dg'],
        monthNames: [
          'gener',
          'febrer',
          'març',
          'abril',
          'maig',
          'juny',
          'juliol',
          'agost',
          'setembre',
          'octubre',
          'novembre',
          'desembre',
        ],
        noShift: 'Sense torn',
        tomorrow: 'Demà',
        emptyCircular: '-',
        staleTitle: 'Quadrant',
        staleBody: 'Obre Quadrant',
      );
      final s = _build(today, strings: ca, schedule: Schedule());
      expect(s.locale, 'ca');
      expect(s.days.first.small.big, 'Sense torn');
      expect(s.days.first.small.tomorrow, 'Demà: Sense torn');
      expect(s.days.first.dateLabel, 'dl 19');
      expect(s.months.first.title, 'Octubre 2026');
      expect(s.staleBody, 'Obre Quadrant');
    });
  });

  group('colours are the ones of the app', () {
    void expectSwatch(
      ShiftSwatch swatch, {
      required int bar,
      required int tint,
      required int ink,
      required int disc,
    }) {
      expect(bar, swatch.bar.toARGB32());
      expect(tint, swatch.tint.toARGB32());
      expect(ink, swatch.ink.toARGB32());
      expect(disc, swatch.disc.toARGB32());
    }

    test('shifts: light and dark equal ShiftSwatch.forColor', () {
      final s = _build(today);
      final seen = <String>{};
      for (final day in s.days) {
        for (final shift in day.shifts) {
          final type = _type(
            allTypes.firstWhere((t) => t.code == shift.code).id,
          );
          expectSwatch(
            ShiftSwatch.forColor(type.colorValue, Brightness.light),
            bar: shift.barLight,
            tint: shift.tintLight,
            ink: shift.inkLight,
            disc: shift.discLight,
          );
          expectSwatch(
            ShiftSwatch.forColor(type.colorValue, Brightness.dark),
            bar: shift.barDark,
            tint: shift.tintDark,
            ink: shift.inkDark,
            disc: shift.discDark,
          );
          seen.add(shift.code);
        }
      }
      expect(seen, {'N', 'T', 'M', 'L'});
    });

    test('rest is neutral: no tint, bar and ink from the tokens', () {
      final s = _build(today);
      final rest = s.days[3].shifts.single;
      expect(rest.code, 'L');
      expect(rest.barLight, AppColors.light.borderStrong.toARGB32());
      expect(rest.tintLight, AppColors.light.surface.toARGB32());
      expect(rest.inkLight, AppColors.light.textMuted.toARGB32());
      expect(rest.barDark, AppColors.dark.borderStrong.toARGB32());
      expect(rest.tintDark, AppColors.dark.surface.toARGB32());
      expect(rest.inkDark, AppColors.dark.textMuted.toARGB32());
      // A saturated shift keeps its own bar in light mode.
      expect(s.days[0].shifts.single.barLight, ShiftPalette.night.toARGB32());
    });

    test('styles table: light, dark and out-of-month equal ShiftSwatch', () {
      final s = _build(today);
      // Bands point at the style of their shift.
      final byCode = {for (final t in allTypes) t.code: t.colorValue};
      for (final m in s.months) {
        for (final c in m.cells) {
          for (final b in c.bands) {
            final style = s.styles[b.style];
            final value = byCode[b.code]!;
            ShiftSwatch of(Brightness br, {bool outOfMonth = false}) =>
                ShiftSwatch.forColor(value, br, outOfMonth: outOfMonth);
            expectSwatch(
              of(Brightness.light),
              bar: style.barLight,
              tint: style.tintLight,
              ink: style.inkLight,
              disc: style.discLight,
            );
            expectSwatch(
              of(Brightness.dark),
              bar: style.barDark,
              tint: style.tintDark,
              ink: style.inkDark,
              disc: style.discDark,
            );
            expectSwatch(
              of(Brightness.light, outOfMonth: true),
              bar: style.dimBarLight,
              tint: style.dimTintLight,
              ink: style.dimInkLight,
              disc: style.dimDiscLight,
            );
            expectSwatch(
              of(Brightness.dark, outOfMonth: true),
              bar: style.dimBarDark,
              tint: style.dimTintDark,
              ink: style.dimInkDark,
              disc: style.dimDiscDark,
            );
          }
        }
      }
      // One style per distinct colour, in order of first appearance.
      expect(s.styles, hasLength(4));
    });

    test('ink keeps AA contrast on the tint and the disc of every style', () {
      final s = _build(today);
      for (final st in s.styles) {
        for (final (ink, backgrounds) in [
          (st.inkLight, [st.tintLight, st.discLight]),
          (st.inkDark, [st.tintDark, st.discDark]),
          (st.dimInkLight, [st.dimTintLight, st.dimDiscLight]),
          (st.dimInkDark, [st.dimTintDark, st.dimDiscDark]),
        ]) {
          for (final background in backgrounds) {
            expect(
              contrastRatio(Color(ink), Color(background)),
              greaterThanOrEqualTo(4.5),
            );
          }
        }
      }
    });

    test('colours are positive ARGB ints in the JSON', () {
      final text = _build(today).encode();
      final j = jsonDecode(text) as Map<String, Object?>;
      final style = ((j['styles']! as List).first as Map)['barLight']! as int;
      expect(style, greaterThan(0xFF000000));
      expect(style, lessThanOrEqualTo(0xFFFFFFFF));
    });
  });

  group('JSON', () {
    test('round trip keeps everything', () {
      final s = _build(
        today,
        schedule: _rotation(
          today,
          entries: {
            today.addDays(1): DayEntry(
              date: today.addDays(1),
              shiftTypeIds: const ['morning', 'afternoon'],
              note: 'doblo',
            ),
            today.addDays(2): DayEntry(
              date: today.addDays(2),
              shiftTypeIds: const [],
            ),
          },
        ),
        holidays: {
          const CivilDate(2026, 12, 8): Holiday(
            date: const CivilDate(2026, 12, 8),
            name: 'Inmaculada Concepción',
            scope: HolidayScope.national,
          ),
        },
      );
      final text = s.encode();
      final back = WidgetSnapshot.decode(text);
      expect(back.encode(), text);
      expect(back.toJson(), s.toJson());
      expect(back.contentHash, s.contentHash);
      expect(back.computeContentHash(), s.contentHash);
      expect(back.generatedAt, s.generatedAt);
      expect(back.days, hasLength(60));
      expect(back.days[1].shifts, hasLength(2));
      expect(back.days[1].hasNote, isTrue);
      expect(back.dayOn('2026-12-08')!.holidayName, 'Inmaculada Concepción');
      expect(WidgetSnapshot.tryDecode(text), isNotNull);
    });

    test('output is stable and independent of generatedAt', () {
      final a = _build(today);
      final b = _build(today);
      expect(a.encode(), b.encode());
      final later = buildWidgetSnapshot(
        schedule: _rotation(today),
        holidays: const {},
        today: today,
        timeZone: _tz,
        strings: WidgetStrings.es,
        generatedAt: DateTime.utc(2026, 10, 19, 20),
      );
      expect(later.contentHash, a.contentHash);
      expect(later.encode(), isNot(a.encode()));
      expect(
        a.encode(),
        startsWith(
          '{"v":2,"generatedAt":"2026-10-19T08:30:00.000Z","contentHash":"',
        ),
      );
    });

    test('hash changes with any content difference', () {
      final base = _build(today).contentHash;
      expect(_build(today.addDays(1)).contentHash, isNot(base));
      expect(
        _build(today, timeZone: 'Atlantic/Canary').contentHash,
        isNot(base),
      );
      expect(_build(today, days: 59).contentHash, isNot(base));
      expect(
        _build(
          today,
          schedule: _rotation(
            today,
            entries: {today: DayEntry(date: today, shiftTypeIds: const [])},
          ),
        ).contentHash,
        isNot(base),
      );
      expect(
        _build(
          today,
          strings: const WidgetStrings(tomorrow: 'Mañana,'),
        ).contentHash,
        isNot(base),
      );
    });

    test('generatedAt is written as UTC', () {
      final local = buildWidgetSnapshot(
        schedule: Schedule(),
        holidays: const {},
        today: today,
        timeZone: _tz,
        strings: WidgetStrings.es,
        generatedAt: DateTime(2026, 10, 19, 10, 30),
      );
      final j = jsonDecode(local.encode()) as Map<String, Object?>;
      expect(j['generatedAt'], endsWith('Z'));
    });

    test('rejects other versions and garbage', () {
      final j = _build(today).toJson();
      final other = jsonEncode({...j, 'v': kWidgetSnapshotVersion + 1});
      expect(() => WidgetSnapshot.decode(other), throwsFormatException);
      expect(WidgetSnapshot.tryDecode(other), isNull);
      expect(WidgetSnapshot.tryDecode('nope'), isNull);
      expect(WidgetSnapshot.tryDecode('[]'), isNull);
      expect(WidgetSnapshot.tryDecode(null), isNull);
      final missing = Map<String, Object?>.of(j)..remove('days');
      expect(WidgetSnapshot.tryDecode(jsonEncode(missing)), isNull);
    });

    test('header reads any version and ignores broken text', () {
      final s = _build(today);
      final h = WidgetSnapshotHeader.tryParse(s.encode())!;
      expect(h.version, kWidgetSnapshotVersion);
      expect(h.firstDate, '2026-10-19');
      expect(h.lastDate, '2026-12-17');
      expect(h.timeZone, _tz);
      expect(h.contentHash, s.contentHash);
      expect(h.generatedAt, _generatedAt);
      final v9 = jsonEncode({...s.toJson(), 'v': 9});
      expect(WidgetSnapshotHeader.tryParse(v9)!.version, 9);
      expect(WidgetSnapshotHeader.tryParse('{'), isNull);
      expect(WidgetSnapshotHeader.tryParse(null), isNull);
    });

    test('header with dates that are not dates reads as nothing', () {
      final j = _build(today).toJson();
      for (final key in ['firstDate', 'lastDate']) {
        for (final bad in ['x', '', '2026-02-30', '2026-10-19T00:00']) {
          expect(
            WidgetSnapshotHeader.tryParse(jsonEncode({...j, key: bad})),
            isNull,
            reason: '$key = "$bad"',
          );
        }
      }
    });

    test('size: 60 days stay far below 200 KB', () {
      // Worst-ish case: every preset shift type, doubled shifts and notes.
      final entries = <CivilDate, DayEntry>{
        for (var i = 0; i < 60; i += 3)
          today.addDays(i): DayEntry(
            date: today.addDays(i),
            shiftTypeIds: const ['morning', 'afternoon'],
            note: 'nota',
          ),
      };
      final simple = utf8.encode(_build(today).encode()).length;
      final heavy = utf8
          .encode(
            _build(
              today,
              schedule: _rotation(today, entries: entries),
            ).encode(),
          )
          .length;
      // ignore: avoid_print
      print('widget snapshot, 60 days: simple $simple B, heavy $heavy B');
      expect(simple, lessThan(kWidgetSnapshotMaxBytes));
      expect(heavy, lessThan(kWidgetSnapshotMaxBytes));
    });
  });

  group('timeline serves the right day (7-day protocol, in code)', () {
    test('each of the 60 days finds its own entry; day 61 finds none', () {
      final schedule = _rotation(today);
      final s = WidgetSnapshot.decode(
        _build(today, schedule: schedule).encode(),
      );
      for (var i = 0; i < 70; i++) {
        final date = today.addDays(i);
        final day = s.dayOn(date.toIso());
        if (i < 60) {
          final expected = schedule
              .resolve(date)
              .shifts
              .map((x) => x.code)
              .join('+');
          expect(day, isNotNull);
          expect(day!.small.big, expected, reason: date.toIso());
        } else {
          expect(day, isNull, reason: date.toIso());
        }
      }
    });
  });

  group(
    'overtime, early leave and reminders are not in the widget (0.6.0)',
    () {
      test('the snapshot is the same with and without them', () {
        final plain = _rotation(today);
        final annotated = _rotation(
          today,
          entries: {
            today: DayEntry(
              date: today,
              overtimeMinutes: 60,
              earlyLeaveMinutes: 15,
              noteReminderMinute: 480,
            ),
            today.addDays(3): DayEntry(
              date: today.addDays(3),
              overtimeMinutes: 30,
            ),
          },
        );
        expect(
          jsonEncode(_build(today, schedule: annotated).toJson()),
          jsonEncode(_build(today, schedule: plain).toJson()),
        );
      });

      test('a note still marks its day, with or without a reminder', () {
        final plain = _build(
          today,
          schedule: _rotation(
            today,
            entries: {today: DayEntry(date: today, note: 'Nota')},
          ),
        );
        final withReminder = _build(
          today,
          schedule: _rotation(
            today,
            entries: {
              today: DayEntry(
                date: today,
                note: 'Nota',
                noteReminderMinute: 480,
              ),
            },
          ),
        );
        expect(jsonEncode(withReminder.toJson()), jsonEncode(plain.toJson()));
      });
    },
  );
}
