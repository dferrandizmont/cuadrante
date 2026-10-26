import 'package:cuadrante/features/alarms/data/wall_clock.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Reminders of day notes in the planner (docs/paridad.md, A1).

const _strings = AlarmStrings(
  title: _title,
  body: _body,
  channelName: 'Alarmas de turno',
  channelDescription: 'Descripción',
  dayBeforeTitle: _title,
  snoozeAction: 'Posponer 10 min',
  awakeAction: 'Ya estoy despierto',
  testTitle: 'Prueba',
  testBody: 'Cuerpo de prueba',
  reminderTitle: 'Recordatorio',
  reminderEmptyBody: 'Tienes un recordatorio para hoy',
  reminderChannelName: 'Recordatorios de notas',
  reminderChannelDescription: 'Descripción',
);

String _title(String name, String start) => 'Turno de $name a las $start';
String _body(String name, String start, String end) =>
    '$name: de $start a $end';

final _night = ShiftType(
  id: 'night',
  code: 'N',
  name: 'Noche',
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: 22 * 60,
  endMinute: 6 * 60,
  alarmSound: 'content://media/internal/audio/media/42',
);

const _today = CivilDate(2026, 10, 19);
final _now = DateTime(2026, 10, 19, 12);

DayEntry _reminder(CivilDate date, int minute, {String? note}) =>
    DayEntry(date: date, note: note, noteReminderMinute: minute);

Schedule _schedule(
  List<DayEntry> entries, {
  List<ShiftType> types = const [],
}) =>
    Schedule(shiftTypes: types, entries: {for (final e in entries) e.date: e});

List<PlannedAlarm> _plan(
  Schedule schedule, {
  AlarmSettings settings = AlarmSettings.disabled,
  DateTime? now,
}) => planAlarms(
  schedule: schedule,
  settings: settings,
  now: now ?? _now,
  strings: _strings,
);

const _nightOn = AlarmSettings(
  enabled: true,
  byShiftType: {'night': AlarmTypeSettings(enabled: true)},
);

void main() {
  late tz.Location madrid;

  setUpAll(() {
    tzdata.initializeTimeZones();
    madrid = tz.getLocation('Europe/Madrid');
  });

  group('on a day whose shift is an absence', () {
    // A sick-leave type that someone gave a time range (the form allows it).
    const sickLeave = ShiftType(
      id: 'sick',
      code: 'B',
      name: 'Baja',
      colorValue: 0xFFCC3333,
      category: ShiftCategory.absence,
      startMinute: 8 * 60,
      endMinute: 15 * 60,
    );
    final day = _today.addDays(2);
    final schedule = Schedule(
      shiftTypes: [_night, sickLeave],
      entries: {
        day: DayEntry(
          date: day,
          shiftTypeIds: const ['sick'],
          note: 'Llamar al médico',
          noteReminderMinute: 9 * 60,
        ),
        _today.addDays(3): DayEntry(
          date: _today.addDays(3),
          shiftTypeIds: const ['night'],
        ),
      },
    );
    const settings = AlarmSettings(
      enabled: true,
      byShiftType: {
        'sick': AlarmTypeSettings(enabled: true, dayBefore: true),
        'night': AlarmTypeSettings(enabled: true, dayBefore: true),
      },
    );

    test('the reminder still rings, and the absence still makes no alarm', () {
      final plan = _plan(schedule, settings: settings);
      expect(plan.where((a) => a.shiftTypeId == 'sick'), isEmpty);
      final reminders = plan.where((a) => a.kind == AlarmKind.reminder);
      expect(reminders, hasLength(1));
      expect(reminders.single.fireDate, day);
      expect(reminders.single.fireMinute, 9 * 60);
      // The note's text never reaches the lock screen on an absence day.
      expect(reminders.single.body, 'Tienes un recordatorio para hoy');
      expect(reminders.single.body, isNot(contains('médico')));
      // The night beside it rings as always (before and the evening before).
      expect(
        plan
            .where((a) => a.kind != AlarmKind.reminder)
            .map((a) => a.shiftTypeId),
        everyElement('night'),
      );
      expect(plan.where((a) => a.kind != AlarmKind.reminder), hasLength(2));
    });

    test('any absence of the day hides the note, also next to a work shift '
        'and also when the absence comes from the rotation', () {
      final mixed = _today.addDays(4);
      final fromRotation = _today.addDays(5);
      final plan = _plan(
        Schedule(
          shiftTypes: [_night, sickLeave],
          patterns: [
            Pattern(
              id: 'p',
              name: 'Baja',
              steps: const [
                ['sick'],
              ],
            ),
          ],
          runs: [
            PatternRun(
              id: 'r',
              patternId: 'p',
              startDate: fromRotation,
              endDate: fromRotation,
              seq: 1,
            ),
          ],
          entries: {
            mixed: DayEntry(
              date: mixed,
              shiftTypeIds: const ['night', 'sick'],
              note: 'Resultado de la analítica',
              noteReminderMinute: 10 * 60,
            ),
            // No override: the day is what the rotation says (an absence).
            fromRotation: DayEntry(
              date: fromRotation,
              note: 'Diagnóstico',
              noteReminderMinute: 11 * 60,
            ),
          },
        ),
      );
      final bodies = {
        for (final a in plan.where((a) => a.kind == AlarmKind.reminder))
          a.fireDate: a.body,
      };
      expect(bodies, {
        mixed: 'Tienes un recordatorio para hoy',
        fromRotation: 'Tienes un recordatorio para hoy',
      });
    });

    test('a work day keeps showing the first line of its note', () {
      final plan = _plan(
        Schedule(
          shiftTypes: [_night],
          entries: {
            _today.addDays(1): DayEntry(
              date: _today.addDays(1),
              shiftTypeIds: const ['night'],
              note: 'Llevar el uniforme\nsegunda línea',
              noteReminderMinute: 9 * 60,
            ),
          },
        ),
      );
      expect(plan.single.body, 'Llevar el uniforme');
    });

    test('with every shift alarm off the reminder is the only one', () {
      final plan = _plan(schedule);
      expect(plan, hasLength(1));
      expect(plan.single.kind, AlarmKind.reminder);
    });

    test(
      'the absence with its reminder is not a "next alarm" (shifts only)',
      () {
        final next = nextAlarm(
          schedule: Schedule(
            shiftTypes: [sickLeave],
            entries: {
              day: DayEntry(
                date: day,
                shiftTypeIds: const ['sick'],
                noteReminderMinute: 9 * 60,
              ),
            },
          ),
          settings: settings,
          now: _now,
        );
        expect(next, isNull);
      },
    );
  });

  group('one reminder', () {
    test(
      'rings at that minute of that day with the first line of the note',
      () {
        final plan = _plan(
          _schedule([
            _reminder(
              _today.addDays(2),
              9 * 60 + 15,
              note: '  Llevar el informe\nsegunda línea  ',
            ),
          ]),
        );
        expect(plan, hasLength(1));
        final a = plan.single;
        expect(a.kind, AlarmKind.reminder);
        expect(a.title, 'Recordatorio');
        expect(a.body, 'Llevar el informe');
        expect(a.fireDate, _today.addDays(2));
        expect(a.fireMinute, 9 * 60 + 15);
        expect(a.shiftDate, _today.addDays(2));
        expect(a.shiftTypeId, '');
        expect(a.snoozeLabel, isNull, reason: 'a reminder has no buttons');
        expect(a.sound, isNull);
        expect(a.payload, startsWith(alarmPayloadPrefix));
        final payload = AlarmPayload.decode(a.payload)!;
        expect(payload.kind, AlarmKind.reminder);
        expect(payload.shiftTypeId, '');
        expect(payload.shiftDate, _today.addDays(2));
      },
    );

    test('a note without text says there is a reminder for today', () {
      for (final note in [null, '', '   \n \t ']) {
        final a = _plan(
          _schedule([_reminder(_today.addDays(1), 600, note: note)]),
        ).single;
        expect(a.body, 'Tienes un recordatorio para hoy', reason: '"$note"');
      }
    });

    test('the body is the first non-blank line, one line, cut when long', () {
      expect(reminderBody('\n\n  Dentista  \nresto'), 'Dentista');
      expect(reminderBody('uno   dos\t tres'), 'uno dos tres');
      expect(reminderBody(null), isNull);
      expect(reminderBody(' \n '), isNull);
      final long = 'a' * 400;
      final cut = reminderBody(long)!;
      expect(cut.runes.length, maxReminderBodyLength);
      expect(cut, endsWith('…'));
      // Emoji are code points, not halves of a surrogate pair.
      final emoji = reminderBody('😀' * 400)!;
      expect(emoji.runes.length, maxReminderBodyLength);
      expect(emoji.runes.first, '😀'.runes.first);
    });

    test('the id is stable and different from every shift alarm', () {
      final entries = [_reminder(_today.addDays(1), 600)];
      final a = _plan(_schedule(entries)).single;
      final b = _plan(_schedule(entries)).single;
      expect(a.id, b.id);
      expect(a.id, alarmIdFor(_today.addDays(1), '', 0, AlarmKind.reminder));
      expect(a.id, isNot(alarmIdFor(_today.addDays(1), 'night', 0)));
      expect(a, b);
    });
  });

  group('independent of the shift alarms', () {
    test('rings with every alarm switch off', () {
      final entries = [_reminder(_today.addDays(1), 600)];
      expect(AlarmSettings.disabled.enabled, isFalse);
      expect(_plan(_schedule(entries)), hasLength(1));
      // Global switch on, no type on: still only the reminder.
      expect(
        _plan(_schedule(entries), settings: const AlarmSettings(enabled: true)),
        hasLength(1),
      );
    });

    test('"Sin alarma este día" does not silence it', () {
      final day = _today.addDays(1);
      final plan = _plan(
        _schedule(
          [
            DayEntry(
              date: day,
              shiftTypeIds: const ['night'],
              noteReminderMinute: 600,
            ),
          ],
          types: [_night],
        ),
        settings: _nightOn.withSkipped(day, skipped: true),
      );
      expect(plan.map((a) => a.kind), [AlarmKind.reminder]);
    });

    test('mixes with shift alarms in time order', () {
      final plan = _plan(
        _schedule(
          [
            DayEntry(
              date: _today.addDays(1),
              shiftTypeIds: const ['night'],
              note: 'Cita',
              noteReminderMinute: 21 * 60,
            ),
          ],
          types: [_night],
        ),
        settings: _nightOn,
      );
      // Shift alarm 20:30, reminder 21:00 the same day.
      expect(plan.map((a) => a.kind), [AlarmKind.shift, AlarmKind.reminder]);
      expect(plan.map((a) => a.fireMinute), [20 * 60 + 30, 21 * 60]);
    });

    test('shift alarms carry the sound of their shift type', () {
      final plan = _plan(
        _schedule(
          [
            DayEntry(date: _today.addDays(1), shiftTypeIds: const ['night']),
          ],
          types: [_night],
        ),
        settings: _nightOn,
      );
      expect(plan.single.sound, 'content://media/internal/audio/media/42');
      expect(
        AlarmPayload.decode(plan.single.payload)!.sound,
        'content://media/internal/audio/media/42',
      );
    });

    test('nextAlarm is about shifts: a reminder is not "the next alarm"', () {
      // The reminder (00:30 on the 20th) is earlier than the shift alarm
      // (20:30 on the 20th) and still not "the next alarm".
      final schedule = _schedule(
        [
          DayEntry(
            date: _today.addDays(1),
            shiftTypeIds: const ['night'],
            noteReminderMinute: 30,
          ),
        ],
        types: [_night],
      );
      expect(_plan(schedule, settings: _nightOn).map((a) => a.kind), [
        AlarmKind.reminder,
        AlarmKind.shift,
      ]);
      final next = nextAlarm(
        schedule: schedule,
        settings: _nightOn,
        now: _now,
      )!;
      expect(next.kind, AlarmKind.shift);
      expect(
        nextAlarm(
          schedule: _schedule([_reminder(_today.addDays(1), 30)]),
          settings: AlarmSettings.disabled,
          now: _now,
        ),
        isNull,
      );
    });
  });

  group('window', () {
    test('reminders in the past are not scheduled, nor the current minute', () {
      final schedule = _schedule([
        _reminder(_today.addDays(-1), 600),
        _reminder(_today, 11 * 60 + 59),
        _reminder(_today, 12 * 60), // this very minute counts as past
        _reminder(_today, 12 * 60 + 1),
        _reminder(_today.addDays(1), 0),
      ]);
      final plan = _plan(schedule);
      expect(plan.map((a) => (a.fireDate, a.fireMinute)), [
        (_today, 12 * 60 + 1),
        (_today.addDays(1), 0),
      ]);
    });

    test('nothing beyond the horizon', () {
      // Now is 12:00; the window ends 14 days later at 12:00 (inclusive).
      Iterable<int> within(int day, int minute) =>
          _plan(_schedule([_reminder(_today.addDays(day), minute)]))
              .map((a) => a.fireMinute);
      expect(within(14, 11 * 60 + 59), [11 * 60 + 59]);
      expect(within(14, 12 * 60), [12 * 60], reason: 'exactly at the end');
      expect(within(14, 12 * 60 + 1), isEmpty, reason: 'one minute too far');
      expect(within(40, 600), isEmpty);
      // A longer horizon brings the far one in.
      final longer = _plan(
        _schedule([_reminder(_today.addDays(20), 600)]),
        settings: const AlarmSettings(horizonDays: 30),
      );
      expect(longer, hasLength(1));
    });

    test('a corrupted minute is ignored instead of crashing', () {
      // The entry asserts 0..1439; the planner also guards a release build.
      final plan = _plan(_schedule([_reminder(_today.addDays(1), 1439)]));
      expect(plan.single.fireMinute, 1439);
    });
  });

  group('cap of $maxPendingAlarms', () {
    // Two shifts a day with the evening-before reminder on: far more than 60
    // alarms in 30 days from the shifts alone.
    final late = ShiftType(
      id: 'late',
      code: 'T',
      name: 'Tarde',
      colorValue: 0xFF996633,
      category: ShiftCategory.work,
      startMinute: 14 * 60,
      endMinute: 22 * 60,
    );
    Schedule dense(List<DayEntry> extra) => _schedule(
      [
        for (var i = 1; i <= 31; i++)
          DayEntry(
            date: _today.addDays(i),
            shiftTypeIds: const ['night', 'late'],
          ),
        ...extra,
      ],
      types: [_night, late],
    );

    const settings = AlarmSettings(
      enabled: true,
      horizonDays: 30,
      byShiftType: {
        'night': AlarmTypeSettings(enabled: true, dayBefore: true),
        'late': AlarmTypeSettings(enabled: true, dayBefore: true),
      },
    );

    test('shift alarms alone are capped, nearest first', () {
      final plan = _plan(dense([]), settings: settings);
      expect(plan, hasLength(maxPendingAlarms));
      expect(plan.every((a) => a.kind != AlarmKind.reminder), isTrue);
    });

    test('a reminder at the far end of the horizon is never dropped for '
        'shift alarms', () {
      final farDay = _today.addDays(29);
      final far = DayEntry(
        date: farDay,
        shiftTypeIds: const ['night', 'late'],
        note: 'Importante',
        noteReminderMinute: 600,
      );
      final alone = _plan(dense([]), settings: settings);
      final plan = _plan(dense([far]), settings: settings);
      expect(plan, hasLength(maxPendingAlarms));
      final reminders = plan.where((a) => a.kind == AlarmKind.reminder);
      expect(reminders.single.body, 'Importante');
      expect(reminders.single.fireDate, farDay);
      // The shift alarms gave up exactly one slot: the farthest one.
      final shifts = plan.where((a) => a.kind != AlarmKind.reminder).toList();
      expect(shifts, hasLength(maxPendingAlarms - 1));
      expect(shifts, alone.take(maxPendingAlarms - 1).toList());
      final sorted = [...plan]
        ..sort((a, b) {
          final c = a.wallMinutes.compareTo(b.wallMinutes);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      expect(plan, sorted, reason: 'the result stays in time order');
    });

    test('over the cap with reminders only, the nearest ones win', () {
      final lots = [
        for (var d = 1; d <= 90; d++) _reminder(_today.addDays(d), 600),
      ];
      final plan = _plan(
        _schedule(lots),
        settings: const AlarmSettings(horizonDays: 90),
      );
      expect(plan, hasLength(maxPendingAlarms));
      expect(plan.first.fireDate, _today.addDays(1));
      expect(plan.last.fireDate, _today.addDays(maxPendingAlarms));
    });

    test('ids stay unique when everything is mixed', () {
      final plan = _plan(
        dense([
          _reminder(_today.addDays(3), 600),
          _reminder(_today.addDays(5), 600),
        ]),
        settings: settings,
      );
      expect({for (final a in plan) a.id}, hasLength(plan.length));
    });
  });

  group('daylight saving (Europe/Madrid)', () {
    PlannedAlarm remindAt(CivilDate day, int minute, DateTime now) =>
        _plan(_schedule([_reminder(day, minute)]), now: now).single;

    test('a minute that does not exist rings forward by the length of the '
        'gap, never earlier (02:30 on 29 March is 03:30)', () {
      final a = remindAt(
        const CivilDate(2026, 3, 29),
        2 * 60 + 30,
        DateTime(2026, 3, 28, 12),
      );
      expect((a.fireDate, a.fireMinute), (const CivilDate(2026, 3, 29), 150));
      final instant = resolveAlarmInstant(a, madrid);
      expect(instant.toUtc(), DateTime.utc(2026, 3, 29, 1, 30));
      expect((instant.hour, instant.minute), (3, 30));
      // Not before the 01:59 CET that precedes the gap.
      expect(
        instant.isAfter(resolveWallClock(madrid, 2026, 3, 29, 1 * 60 + 59)),
        isTrue,
      );
    });

    test('a repeated minute rings the first time (02:30 on 25 October, '
        'still summer time)', () {
      final a = remindAt(
        const CivilDate(2026, 10, 25),
        2 * 60 + 30,
        DateTime(2026, 10, 24, 12),
      );
      final instant = resolveAlarmInstant(a, madrid);
      expect(instant.toUtc(), DateTime.utc(2026, 10, 25, 0, 30));
      expect(instant.timeZoneOffset, const Duration(hours: 2));
    });

    test('an ordinary minute keeps its local hour on the days that change', () {
      final spring = remindAt(
        const CivilDate(2026, 3, 29),
        9 * 60,
        DateTime(2026, 3, 28, 12),
      );
      final fall = remindAt(
        const CivilDate(2026, 10, 25),
        9 * 60,
        DateTime(2026, 10, 24, 12),
      );
      expect(resolveAlarmInstant(spring, madrid).hour, 9);
      expect(resolveAlarmInstant(fall, madrid).hour, 9);
    });
  });
}
