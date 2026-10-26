import 'package:cuadrante/features/calendar_export/data/calendar_exporter.dart';
import 'package:cuadrante/features/calendar_export/domain/export_events.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_device_calendar.dart';

const _from = CivilDate(2026, 10, 19);
const _to = CivilDate(2026, 10, 21);

/// 09:00-13:00 and 17:00-21:00.
const _partido = ShiftType(
  id: 'partido',
  code: 'P',
  name: 'Partido',
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: 9 * 60,
  endMinute: 13 * 60,
  segment2StartMinute: 17 * 60,
  segment2DurationMinutes: 4 * 60,
);

/// 20:00-23:00 and 01:00-03:00 of the next day.
const _lateEarly = ShiftType(
  id: 'le',
  code: 'E',
  name: 'Nocturno partido',
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: 20 * 60,
  endMinute: 23 * 60,
  segment2StartMinute: 60,
  segment2DurationMinutes: 2 * 60,
);

const _tarde = ShiftType(
  id: 'tarde',
  code: 'T',
  name: 'Tarde',
  colorValue: 0xFFF06A3F,
  category: ShiftCategory.work,
  startMinute: 14 * 60,
  endMinute: 22 * 60,
);

Schedule _schedule(Map<CivilDate, List<String>> days) => Schedule(
  shiftTypes: [_partido, _lateEarly, _tarde],
  entries: {
    for (final e in days.entries)
      e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
  },
);

List<ExportEvent> _events(Schedule s, {CivilDate to = _to}) =>
    buildExportEvents(s, calendarId: 'main', from: _from, to: to);

/// A split shift exports TWO events (A12): one per segment, each with its own
/// tag, so a re-export finds and replaces both.
void main() {
  group('building the events', () {
    test('a split shift is two timed events with the same title', () {
      final events = _events(
        _schedule({
          _from: ['partido'],
        }),
      );
      expect(events, hasLength(2));
      expect(events.map((e) => e.title), ['Partido · P', 'Partido · P']);
      expect(events[0].start, DateTime(2026, 10, 19, 9));
      expect(events[0].end, DateTime(2026, 10, 19, 13));
      expect(events[1].start, DateTime(2026, 10, 19, 17));
      expect(events[1].end, DateTime(2026, 10, 19, 21));
      expect(events.every((e) => !e.allDay), isTrue);
      expect(events.map((e) => e.segment), [0, 1]);
    });

    test('each segment has its own tag and they parse back', () {
      final events = _events(
        _schedule({
          _from: ['partido'],
        }),
      );
      expect(events[0].tag, 'cuadrante:v1:main:2026-10-19:partido:0');
      expect(events[1].tag, 'cuadrante:v1:main:2026-10-19:partido:100');
      expect(events[0].tag, isNot(events[1].tag));
      final back = ExportTag.parse(events[1].description)!;
      expect(back.typeId, 'partido');
      expect(back.date, _from);
      expect(back.index, exportSecondSegmentIndexOffset);
      expect(back.key, events[1].tag);
    });

    test('the tag of the first segment is the one of a normal shift', () {
      // Exports made before split shifts existed keep matching.
      expect(
        _events(
          _schedule({
            _from: ['partido'],
          }),
        ).first.tag,
        exportTag('main', _from, 'partido', 0),
      );
    });

    test('tags never clash with the other shifts of the day', () {
      final events = _events(
        _schedule({
          _from: ['tarde', 'partido', 'partido2'],
        }),
      );
      // 'partido2' does not exist and is ignored; tarde + partido remain.
      expect({for (final e in events) e.tag}, hasLength(events.length));
      expect(events.map((e) => e.tag), [
        'cuadrante:v1:main:2026-10-19:tarde:0',
        'cuadrante:v1:main:2026-10-19:partido:1',
        'cuadrante:v1:main:2026-10-19:partido:101',
      ]);
    });

    test('a second segment after midnight lands on the next day', () {
      final events = _events(
        _schedule({
          _from: ['le'],
        }),
      );
      expect(events[0].start, DateTime(2026, 10, 19, 20));
      expect(events[0].end, DateTime(2026, 10, 19, 23));
      expect(events[1].start, DateTime(2026, 10, 20, 1));
      expect(events[1].end, DateTime(2026, 10, 20, 3));
      // Both are tagged with the day the shift starts.
      expect(events.map((e) => e.date), [_from, _from]);
    });

    test('shifts that are not split give one event, as before', () {
      final events = _events(
        _schedule({
          _from: ['tarde'],
        }),
      );
      expect(events, hasLength(1));
      expect(events.single.segment, 0);
      expect(events.single.tag, 'cuadrante:v1:main:2026-10-19:tarde:0');
    });
  });

  group('exporting', () {
    late FakeDeviceCalendar phone;
    late CalendarExporter exporter;

    Future<ExportResult> run(
      ExportTarget target, {
      required Schedule schedule,
      CivilDate to = _to,
    }) => exporter.export(
      schedule: schedule,
      appCalendarId: 'main',
      target: target,
      from: _from,
      to: to,
      includeRest: false,
    );

    final week = _schedule({
      _from: ['partido'],
      _from.addDays(1): ['partido'],
      _from.addDays(2): ['tarde'],
    });

    setUp(() {
      phone = FakeDeviceCalendar();
      exporter = CalendarExporter(phone);
    });

    test('writes two events per split day', () async {
      final result = await run(const NewCalendar(), schedule: week);
      expect(result.created, 5);
      expect(result.failed, 0);
      final onPhone = phone.eventsOf(result.deviceCalendarId);
      expect(onPhone, hasLength(5));
      expect(onPhone.where((e) => e.title == 'Partido · P'), hasLength(4));
    });

    test('exporting again does not duplicate anything', () async {
      final first = await run(const NewCalendar(), schedule: week);
      final id = first.deviceCalendarId;
      final second = await run(ExistingCalendar(id), schedule: week);
      expect(second.created, 0);
      expect(second.removed, 0);
      expect(second.unchanged, 5);
      final third = await run(ExistingCalendar(id), schedule: week);
      expect(third.created, 0);
      expect(phone.eventsOf(id), hasLength(5));
    });

    test('changing the times replaces both events of the shift only', () async {
      final first = await run(const NewCalendar(), schedule: week);
      final id = first.deviceCalendarId;
      final later = week.copyWith(
        shiftTypes: [
          _partido.copyWith(segment2StartMinute: 18 * 60),
          _lateEarly,
          _tarde,
        ],
      );
      final result = await run(ExistingCalendar(id), schedule: later);
      // Only the second segment moved, on the two split days.
      expect(result.removed, 2);
      expect(result.created, 2);
      expect(result.unchanged, 3);
      expect(phone.eventsOf(id), hasLength(5));
      final starts =
          phone
              .eventsOf(id)
              .where((e) => e.title == 'Partido · P')
              .map((e) => e.start.hour)
              .toList()
            ..sort();
      expect(starts, [9, 9, 18, 18]);
    });

    test(
      'a split day turned into a normal shift removes both old events',
      () async {
        final first = await run(const NewCalendar(), schedule: week);
        final id = first.deviceCalendarId;
        final changed = week.copyWith(
          entries: {
            ...week.entries,
            _from: DayEntry(date: _from, shiftTypeIds: const ['tarde']),
          },
        );
        final result = await run(ExistingCalendar(id), schedule: changed);
        expect(result.removed, 2);
        expect(result.created, 1);
        expect(result.unchanged, 3);
        expect(phone.eventsOf(id), hasLength(4));
      },
    );

    test(
      'a normal day turned into a split one adds the second event',
      () async {
        final normal = _schedule({
          _from: ['tarde'],
        });
        final first = await run(const NewCalendar(), schedule: normal);
        final id = first.deviceCalendarId;
        final split = _schedule({
          _from: ['partido'],
        });
        final result = await run(ExistingCalendar(id), schedule: split);
        // The tarde event goes; the two segments are new.
        expect(result.removed, 1);
        expect(result.created, 2);
        expect(phone.eventsOf(id), hasLength(2));
      },
    );

    test('the repeated copy of one segment is cleaned up', () async {
      final first = await run(const NewCalendar(), schedule: week);
      final id = first.deviceCalendarId;
      final second = phone
          .eventsOf(id)
          .firstWhere((e) => e.start == DateTime(2026, 10, 19, 17));
      phone.addSimpleEvent(
        id,
        second.title,
        second.start,
        second.end,
        description: second.description,
      );
      expect(phone.eventsOf(id), hasLength(6));
      final result = await run(ExistingCalendar(id), schedule: week);
      expect(result.removed, 1);
      expect(result.created, 0);
      expect(phone.eventsOf(id), hasLength(5));
    });

    test(
      'a segment the user dragged to another day is still replaced',
      () async {
        final first = await run(const NewCalendar(), schedule: week);
        final id = first.deviceCalendarId;
        final dragged = phone
            .eventsOf(id)
            .firstWhere((e) => e.start == DateTime(2026, 10, 19, 17));
        await phone.deleteEvent(dragged.instanceId);
        phone.addSimpleEvent(
          id,
          dragged.title,
          DateTime(2026, 10, 25, 17),
          DateTime(2026, 10, 25, 21),
          description: dragged.description,
        );
        final result = await run(ExistingCalendar(id), schedule: week);
        expect(result.removed, 1);
        expect(result.created, 1);
        expect(phone.eventsOf(id), hasLength(5));
      },
    );

    test('another Cuadrante calendar exported into the same one is left alone', () async {
      final id = phone.addCalendar('Personal');
      final other = phone.addSimpleEvent(
        id,
        'Partido · P',
        DateTime(2026, 10, 19, 17),
        DateTime(2026, 10, 19, 21),
        description:
            'Creado con Cuadrante\n'
            '${exportTag('pareja', _from, 'partido', exportSecondSegmentIndexOffset)}',
      );
      await run(ExistingCalendar(id), schedule: week);
      await run(ExistingCalendar(id), schedule: week);
      expect(phone.eventsOf(id).map((e) => e.instanceId), contains(other));
      expect(phone.eventsOf(id), hasLength(6));
    });
  });
}
