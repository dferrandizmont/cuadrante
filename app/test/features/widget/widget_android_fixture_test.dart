import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;

import 'dart:io';

import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot_builder.dart';
import 'package:cuadrante/features/widget/domain/widget_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../schedule/domain/fixtures.dart';

/// The snapshot the Kotlin unit tests read
/// (`android/app/src/test/resources/widget_snapshot.json`). It is written by
/// the Dart builder, so a change of the contract that the Kotlin reader does
/// not follow fails there; and this test fails when the builder's output no
/// longer matches the file. Refresh it with:
/// `UPDATE_WIDGET_FIXTURE=1 flutter test test/features/widget/widget_android_fixture_test.dart`
const _first = CivilDate(2026, 10, 19);

String _build() {
  final schedule = Schedule(
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
    runs: [PatternRun(id: 'r', patternId: 'rot', startDate: _first, seq: 1)],
    entries: {
      // A double day with a note, an empty override and a vacation.
      _first.addDays(2): DayEntry(
        date: _first.addDays(2),
        shiftTypeIds: const ['morning', 'afternoon'],
        note: 'cambio',
      ),
      _first.addDays(3): DayEntry(
        date: _first.addDays(3),
        shiftTypeIds: const [],
      ),
      _first.addDays(4): DayEntry(
        date: _first.addDays(4),
        shiftTypeIds: const ['vacation'],
      ),
    },
  );
  final holiday = _first.addDays(1);
  return buildWidgetSnapshot(
    schedule: schedule,
    holidays: {
      holiday: Holiday(
        date: holiday,
        name: 'Fiesta de prueba',
        scope: HolidayScope.national,
      ),
    },
    today: _first,
    timeZone: 'Europe/Madrid',
    strings: WidgetStrings.es,
    days: 10,
    generatedAt: DateTime.utc(2026, 10, 19, 8),
  ).encode();
}

/// Five days across a month change (Fri 2026-10-30 to Tue 2026-11-03), with
/// the week starting on Sunday: the November grid begins on the 1st itself
/// (today's cell is the first one on Sunday 1st), October's grid on Sunday
/// 2026-09-27, and both have days of the neighbouring months. Used by the
/// month widget tests.
String _buildMonthChange() {
  const first = CivilDate(2026, 10, 30);
  final schedule = Schedule(
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
    // Started a week earlier so the cells before today have shifts too.
    runs: [
      PatternRun(
        id: 'r',
        patternId: 'rot',
        startDate: first.addDays(-7),
        seq: 1,
      ),
    ],
    entries: {
      first.addDays(3): DayEntry(
        date: first.addDays(3),
        shiftTypeIds: const ['morning', 'afternoon'],
        note: 'cambio',
      ),
    },
  );
  final holiday = first.addDays(2);
  return buildWidgetSnapshot(
    schedule: schedule,
    holidays: {
      holiday: Holiday(
        date: holiday,
        name: 'Todos los Santos',
        scope: HolidayScope.national,
      ),
    },
    today: first,
    timeZone: 'Europe/Madrid',
    strings: WidgetStrings.es,
    days: 5,
    weekStart: DateTime.sunday,
    generatedAt: DateTime.utc(2026, 10, 30, 8),
  ).encode();
}

void _check(String path, String json) {
  final file = File(path);
  if (Platform.environment['UPDATE_WIDGET_FIXTURE'] == '1') {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(json);
  }
  expect(
    file.existsSync(),
    isTrue,
    reason: 'run with UPDATE_WIDGET_FIXTURE=1 to create it',
  );
  expect(file.readAsStringSync(), json);
}

Future<void> main() async {
  await initializeLocale();
  test('the Kotlin test snapshot is what the builder writes', () {
    _check('android/app/src/test/resources/widget_snapshot.json', _build());
  });

  test('the month-change snapshot of the Kotlin tests is what the builder '
      'writes', () {
    _check(
      'android/app/src/test/resources/widget_snapshot_month_change.json',
      _buildMonthChange(),
    );
  });
}
