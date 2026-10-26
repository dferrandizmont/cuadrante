import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:cuadrante/features/calendar/presentation/shift_format.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot_builder.dart';
import 'package:cuadrante/features/widget/domain/widget_strings.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../schedule/domain/fixtures.dart';

WidgetSnapshot _build(CivilDate today, {Schedule? schedule}) =>
    buildWidgetSnapshot(
      schedule: schedule ?? Schedule(),
      holidays: const {},
      today: today,
      timeZone: 'Europe/Madrid',
      strings: WidgetStrings.es,
      weekStart: DateTime.sunday,
      generatedAt: DateTime.utc(2026, 10, 25),
    );

Future<void> main() async {
  await initializeLocale();
  test(
    'absence and empty-day texts come from each of the five locales',
    () async {
      const today = CivilDate(2026, 10, 25);
      final absence = allTypes.firstWhere(
        (s) => s.category == ShiftCategory.absence,
      );
      for (final locale in ['es', 'ca', 'gl', 'eu', 'en']) {
        final l10n = await AppLocalizations.delegate.load(Locale(locale));
        final snapshot = buildWidgetSnapshot(
          schedule: Schedule(
            shiftTypes: [absence],
            entries: {
              today: DayEntry(date: today, shiftTypeIds: [absence.id]),
            },
          ),
          holidays: const {},
          today: today,
          timeZone: 'Europe/Madrid',
          strings: WidgetStrings.fromL10n(l10n),
        );
        expect(snapshot.noShift, l10n.calendarNoShift, reason: locale);
        final day = snapshot.displayDays.firstWhere(
          (d) => d.date == today.toIso(),
        );
        expect(
          day.shifts.single.code,
          l10n.shiftTypesCategoryAbsence,
          reason: locale,
        );
        expect(
          day.shifts.single.name,
          l10n.shiftTypesCategoryAbsence,
          reason: locale,
        );
      }
    },
  );

  test('auxiliary range starts Monday and covers all 60 agenda horizons', () {
    // Sunday, DST fall-back; even when the month grid starts on Sunday.
    const today = CivilDate(2026, 10, 25);
    final snapshot = _build(today, schedule: Schedule());
    expect(snapshot.version, 2);
    expect(snapshot.days, hasLength(60));
    expect(snapshot.firstDate, today.toIso());
    expect(snapshot.displayDays.first.date, '2026-10-19');
    expect(snapshot.displayDays.last.date, today.addDays(72).toIso());
    expect(snapshot.displayDays, hasLength(79));
    for (var i = 0; i < snapshot.displayDays.length; i++) {
      expect(
        snapshot.displayDays[i].date,
        const CivilDate(2026, 10, 19).addDays(i).toIso(),
      );
    }
    final dates = snapshot.displayDays.map((d) => d.date).toSet();
    for (final day in snapshot.days) {
      final date = CivilDate.parse(day.date);
      final monday = date.addDays(1 - date.weekday);
      for (var i = 0; i < 14; i++) {
        expect(dates, contains(date.addDays(i).toIso()));
        expect(dates, contains(monday.addDays(i).toIso()));
      }
    }
    // Auxiliary days cannot make the snapshot valid before/after its timeline.
    expect(snapshot.dayOn('2026-10-19'), isNull);
    expect(snapshot.dayOn(today.addDays(60).toIso()), isNull);
  });

  test(
    'auxiliary days use real shifts, split hours and note presence only',
    () {
      const today = CivilDate(2026, 12, 31);
      final shift = allTypes
          .firstWhere((s) => s.id == 'morning')
          .copyWith(
            segment2StartMinute: 17 * 60,
            segment2DurationMinutes: 4 * 60,
          );
      final last = today.addDays(72);
      final snapshot = _build(
        today,
        schedule: Schedule(
          shiftTypes: [shift],
          entries: {
            last: DayEntry(
              date: last,
              shiftTypeIds: [shift.id],
              note: 'Texto privado de nota',
            ),
          },
        ),
      );
      final day = snapshot.displayDays.last;
      expect(day.date, '2027-03-13');
      expect(day.hasNote, isTrue);
      expect(day.shifts.single.code, shift.code);
      expect(day.shifts.single.compactTime, shift.compactTimeLabel);
      expect(day.shifts.single.timeLabel, shift.compactTimeLabel);
      expect(day.toJson().toString(), isNot(contains('Texto privado')));
      final light = ShiftSwatch.forColor(shift.colorValue, Brightness.light);
      expect(day.shifts.single.tintLight, light.tint.toARGB32());
    },
  );

  test(
    'absence has no private name, code, schedule, colour or note marker',
    () {
      const today = CivilDate(2026, 10, 25);
      final absence = allTypes
          .firstWhere((s) => s.category == ShiftCategory.absence)
          .copyWith(
            name: 'Diagnóstico privado',
            code: 'BM',
            startMinute: 480,
            endMinute: 600,
          );
      final snapshot = _build(
        today,
        schedule: Schedule(
          shiftTypes: [absence],
          entries: {
            today: DayEntry(
              date: today,
              shiftTypeIds: [absence.id],
              note: 'Consulta privada',
            ),
          },
        ),
      );
      final day = snapshot.displayDays.firstWhere(
        (d) => d.date == today.toIso(),
      );
      final shift = day.shifts.single;
      expect(shift.code, 'Ausencia');
      expect(shift.name, 'Ausencia');
      expect(shift.timeLabel, isNull);
      expect(shift.compactTime, isNull);
      expect(day.hasNote, isFalse);
      for (final brightness in Brightness.values) {
        final neutral = ShiftSwatch.forColor(
          ShiftPalette.rest.toARGB32(),
          brightness,
        );
        expect(
          brightness == Brightness.light ? shift.tintLight : shift.tintDark,
          neutral.tint.toARGB32(),
        );
      }
      final encoded = jsonEncode(day.toJson());
      for (final private in ['Diagnóstico', 'BM', 'Consulta', '08:00']) {
        expect(encoded, isNot(contains(private)));
      }
    },
  );

  test('v2 round trip includes auxiliary content in the hash', () {
    const today = CivilDate(2026, 10, 25);
    final base = _build(today, schedule: Schedule());
    final tail = today.addDays(72);
    final edited = _build(
      today,
      schedule: Schedule(
        entries: {
          tail: DayEntry(date: tail, shiftTypeIds: const [], note: 'nota'),
        },
      ),
    );
    expect(edited.contentHash, isNot(base.contentHash));
    final decoded = WidgetSnapshot.decode(edited.encode());
    expect(decoded.encode(), edited.encode());
    expect(decoded.computeContentHash(), edited.contentHash);
    expect(decoded.noShift, 'Sin turno');
    expect(decoded.displayDays.last.hasNote, isTrue);
  });

  test('v1 remains readable and preserves the original hash and JSON', () {
    final json = File('android/app/src/test/resources/widget_snapshot_v1.json')
        .readAsStringSync();
    final snapshot = WidgetSnapshot.decode(json);
    expect(snapshot.version, 1);
    expect(snapshot.displayDays, isEmpty);
    expect(snapshot.encode(), json);
    expect(snapshot.computeContentHash(), snapshot.contentHash);
    expect(snapshot.days.first.small.big, 'N');
  });
}
