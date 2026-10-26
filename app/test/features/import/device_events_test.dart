import 'package:cuadrante/features/calendar_export/domain/device_calendar_api.dart';
import 'package:cuadrante/features/import/data/device_events_reader.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_device_calendar.dart';

DeviceEvent event(
  String id,
  String title,
  DateTime start,
  DateTime end, {
  bool allDay = false,
  bool cancelled = false,
}) => DeviceEvent(
  instanceId: id,
  calendarId: 'c',
  title: title,
  start: start,
  end: end,
  allDay: allDay,
  cancelled: cancelled,
);

void main() {
  group('rawEventFromDevice', () {
    test('timed events use the local start and end', () {
      final raw = rawEventFromDevice(
        event(
          '1',
          'Noche',
          DateTime(2026, 10, 19, 22),
          DateTime(2026, 10, 20, 6),
        ),
      );
      expect(raw.allDay, isFalse);
      expect(raw.startDate, const CivilDate(2026, 10, 19));
      expect(raw.startMinute, 22 * 60);
      expect(raw.endDate, const CivilDate(2026, 10, 20));
      expect(raw.endMinute, 6 * 60);
    });

    test('an event with no length has no end', () {
      final raw = rawEventFromDevice(
        event('1', 'X', DateTime(2026, 10, 19, 8), DateTime(2026, 10, 19, 8)),
      );
      expect(raw.endMinute, isNull);
    });

    test('all-day: the end is exclusive (Android)', () {
      final raw = rawEventFromDevice(
        event(
          '1',
          'Vacaciones',
          DateTime(2026, 10, 19),
          DateTime(2026, 10, 22),
          allDay: true,
        ),
      );
      expect(raw.startDate, const CivilDate(2026, 10, 19));
      expect(raw.endDate, const CivilDate(2026, 10, 22));
    });

    test('all-day: an end inside the last day still covers it (iOS)', () {
      final raw = rawEventFromDevice(
        event(
          '1',
          'Vacaciones',
          DateTime(2026, 10, 19),
          DateTime(2026, 10, 21, 23, 59, 59),
          allDay: true,
        ),
      );
      expect(raw.endDate, const CivilDate(2026, 10, 22));
    });

    test('all-day with an end at or before the start is one day', () {
      final raw = rawEventFromDevice(
        event(
          '1',
          'Libre',
          DateTime(2026, 10, 19),
          DateTime(2026, 10, 19),
          allDay: true,
        ),
      );
      expect(raw.endDate, const CivilDate(2026, 10, 20));
    });
  });

  group('clipTitle', () {
    test('short titles stay, long ones are cut, pairs are not split', () {
      expect(clipTitle('Mañana'), 'Mañana');
      expect(clipTitle('x' * 5000), hasLength(maxImportTitleLength));
      // A surrogate pair that straddles the limit is dropped whole.
      final straddle = '${'a' * (maxImportTitleLength - 1)}\u{1F600}b';
      final clipped = clipTitle(straddle);
      expect(clipped, 'a' * (maxImportTitleLength - 1));
    });

    test('an enormous title never reaches the occurrences', () {
      final e = expandEvents([
        RawEvent(
          title: 'T' * 1000000,
          startDate: const CivilDate(2026, 10, 19),
          startMinute: 360,
        ),
      ], const ImportRange(CivilDate(2026, 10, 1), CivilDate(2026, 10, 31)));
      expect(e.occurrences.single.title.length, maxImportTitleLength);
    });
  });

  group('expandEvents', () {
    const range = ImportRange(CivilDate(2026, 10, 1), CivilDate(2026, 10, 31));

    test('a multi-day all-day event gives one occurrence per day', () {
      final e = expandEvents([
        const RawEvent(
          title: 'Vacaciones',
          startDate: CivilDate(2026, 10, 19),
          endDate: CivilDate(2026, 10, 22),
          allDay: true,
        ),
      ], range);
      expect(e.occurrences.map((o) => o.date.toIso()), [
        '2026-10-19',
        '2026-10-20',
        '2026-10-21',
      ]);
      expect(e.occurrences.every((o) => o.allDay), isTrue);
    });

    test('an event that crosses midnight belongs to its start day', () {
      final e = expandEvents([
        const RawEvent(
          title: 'Noche',
          startDate: CivilDate(2026, 10, 19),
          startMinute: 22 * 60,
          endDate: CivilDate(2026, 10, 20),
          endMinute: 6 * 60,
        ),
      ], range);
      expect(e.occurrences.single.date, const CivilDate(2026, 10, 19));
      expect(e.occurrences.single.startMinute, 22 * 60);
      expect(e.occurrences.single.endMinute, 6 * 60);
    });

    test('a long all-day event is clipped to the range and to a year', () {
      final e = expandEvents([
        const RawEvent(
          title: 'Excedencia',
          startDate: CivilDate(2026, 9, 20),
          endDate: CivilDate(2026, 10, 3),
          allDay: true,
        ),
      ], range);
      expect(e.occurrences.map((o) => o.date.day), [1, 2]);
      final long = expandEvents([
        const RawEvent(
          title: 'Excedencia',
          startDate: CivilDate(2020, 1, 1),
          endDate: CivilDate(2030, 1, 1),
          allDay: true,
        ),
      ], const ImportRange(CivilDate(2020, 1, 1), CivilDate(2030, 1, 1)));
      expect(long.occurrences, hasLength(maxAllDaySpanDays));
    });

    test('the events cap and the occurrence cap are separate and reported', () {
      final many = [
        for (var i = 0; i < 6000; i++)
          RawEvent(
            title: 'M',
            startDate: const CivilDate(2026, 10, 1).addDays(i % 30),
            startMinute: 360,
          ),
      ];
      final e = expandEvents(many, range);
      expect(e.occurrences, hasLength(maxImportEvents));
      expect(e.truncated, isTrue);

      final spans = [
        for (var i = 0; i < 4000; i++)
          const RawEvent(
            title: 'V',
            startDate: CivilDate(2026, 10, 1),
            endDate: CivilDate(2026, 10, 31),
            allDay: true,
          ),
      ];
      final s = expandEvents(spans, range);
      expect(s.occurrences, hasLength(maxImportOccurrences));
      expect(s.truncated, isTrue);
    });

    test('ImportRange: defaults, clamping and containment', () {
      final r = ImportRange.around(const CivilDate(2026, 10, 19));
      expect(r.from, const CivilDate(2025, 10, 19));
      expect(r.to, const CivilDate(2027, 4, 18));
      expect(r.contains(const CivilDate(2026, 10, 19)), isTrue);
      expect(r.contains(const CivilDate(2027, 4, 19)), isFalse);
      final wide = ImportRange(
        const CivilDate(2000, 1, 1),
        const CivilDate(2030, 1, 1),
      );
      final clamped = wide.clamped();
      expect(clamped.to, wide.to);
      expect(clamped.days, maxImportRangeDays);
      // 31 Aug + 6 months is cut to the end of February.
      expect(
        ImportRange.around(const CivilDate(2026, 8, 31)).to,
        const CivilDate(2027, 2, 27),
      );
    });
  });

  group('readDeviceEvents', () {
    test(
      'reads the chosen calendars only, drops cancelled and repeats',
      () async {
        final phone = FakeDeviceCalendar();
        final mine = phone.addCalendar('Turnos');
        final other = phone.addCalendar('Otro');
        phone.addSimpleEvent(
          mine,
          'Mañana',
          DateTime(2026, 10, 19, 6),
          DateTime(2026, 10, 19, 14),
        );
        phone.addSimpleEvent(
          other,
          'Cena',
          DateTime(2026, 10, 19, 21),
          DateTime(2026, 10, 19, 22),
        );
        phone.addEvent(
          event(
            'x',
            'Cancelado',
            DateTime(2026, 10, 20, 6),
            DateTime(2026, 10, 20, 14),
            cancelled: true,
          ),
        );
        final read = await readDeviceEvents(phone, [
          mine,
        ], const ImportRange(CivilDate(2026, 10, 1), CivilDate(2026, 10, 31)));
        expect(read.events.map((e) => e.title), ['Mañana']);
        expect(read.truncated, isFalse);
      },
    );

    test(
      'a long range is read in slices and an event on a boundary counts once',
      () async {
        final phone = FakeDeviceCalendar();
        final id = phone.addCalendar('Turnos');
        // Spans the end of the first slice.
        phone.addSimpleEvent(
          id,
          'Vacaciones',
          DateTime(2026, 1, 30),
          DateTime(2026, 2, 4),
          allDay: true,
        );
        phone.addSimpleEvent(
          id,
          'Mañana',
          DateTime(2026, 12, 1, 6),
          DateTime(2026, 12, 1, 14),
        );
        final read = await readDeviceEvents(phone, [
          id,
        ], const ImportRange(CivilDate(2026, 1, 1), CivilDate(2026, 12, 31)));
        expect(phone.eventListings, greaterThan(1));
        expect(read.events.where((e) => e.title == 'Vacaciones'), hasLength(1));
        expect(read.events, hasLength(2));
      },
    );

    test('stops at the cap and says so', () async {
      final phone = FakeDeviceCalendar();
      final id = phone.addCalendar('Turnos');
      for (var i = 0; i < maxImportEvents + 50; i++) {
        phone.addSimpleEvent(
          id,
          'M',
          DateTime(2026, 2, 1 + i % 20, 6),
          DateTime(2026, 2, 1 + i % 20, 14),
        );
      }
      final read = await readDeviceEvents(phone, [
        id,
      ], const ImportRange(CivilDate(2026, 1, 1), CivilDate(2026, 12, 31)));
      expect(read.events, hasLength(maxImportEvents));
      expect(read.truncated, isTrue);
    });

    test(
      'a failure of the calendar is an exception the wizard catches',
      () async {
        final phone = FakeDeviceCalendar()
          ..failNext = CalendarApiError.unavailable;
        await expectLater(
          readDeviceEvents(phone, [
            'c',
          ], const ImportRange(CivilDate(2026, 1, 1), CivilDate(2026, 1, 31))),
          throwsA(isA<CalendarApiException>()),
        );
      },
    );
  });
}
