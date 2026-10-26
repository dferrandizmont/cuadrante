import 'package:cuadrante/features/backup/domain/backup_retention.dart';
import 'package:cuadrante/features/backup/domain/backup_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const retention = BackupRetention();

  // Noon UTC is the same calendar day in every time zone the tests may run in.
  final now = DateTime.utc(2026, 10, 19, 12);

  BackupEntry entry(String id, DateTime at) =>
      BackupEntry(id: id, modifiedAt: at, sizeBytes: 100);

  /// [perDay] copies on each of [days] days back from today, `d<day>-<n>`
  /// with `n` 0 the newest of the day.
  List<BackupEntry> history({required int days, required int perDay}) => [
    for (var d = 0; d < days; d++)
      for (var n = 0; n < perDay; n++)
        entry('d$d-$n', now.subtract(Duration(days: d, minutes: n * 10))),
  ];

  test('defaults: the 7 newest and one a day for 30 days', () {
    expect(retention.newest, 7);
    expect(retention.dailyForDays, 30);
  });

  test('nothing to keep, nothing to drop', () {
    expect(retention.idsToKeep(const [], now: now), isEmpty);
    expect(retention.toDrop(const [], now: now), isEmpty);
  });

  test('few copies are all kept', () {
    final entries = history(days: 1, perDay: 3);
    expect(retention.idsToKeep(entries, now: now), {'d0-0', 'd0-1', 'd0-2'});
    expect(retention.toDrop(entries, now: now), isEmpty);
  });

  test('a busy day keeps only the 7 newest', () {
    final entries = history(days: 1, perDay: 12);
    final keep = retention.idsToKeep(entries, now: now);
    expect(keep, {for (var n = 0; n < 7; n++) 'd0-$n'});
    expect(retention.toDrop(entries, now: now), hasLength(5));
  });

  test('the order of the list does not matter', () {
    final entries = history(days: 1, perDay: 12).reversed.toList();
    expect(retention.idsToKeep(entries, now: now), {
      for (var n = 0; n < 7; n++) 'd0-$n',
    });
  });

  test('one copy a day for 30 days, then nothing', () {
    final entries = history(days: 45, perDay: 1);
    final keep = retention.idsToKeep(entries, now: now);
    // Days 0..29 (today and the 29 before it).
    expect(keep, {for (var d = 0; d < 30; d++) 'd$d-0'});
    expect(keep.contains('d29-0'), isTrue);
    expect(keep.contains('d30-0'), isFalse);
  });

  test('with several a day: the last one of each day, plus the 7 newest', () {
    final entries = history(days: 45, perDay: 2);
    final keep = retention.idsToKeep(entries, now: now);
    // 30 day representatives, and the 3 older copies of days 0-2 that are
    // among the 7 newest (4 copies on days 0-1, then day 2 and the newest of
    // day 3).
    expect(keep, hasLength(33));
    expect(keep, containsAll(['d0-0', 'd0-1', 'd1-0', 'd1-1', 'd2-0', 'd2-1']));
    expect(keep.contains('d3-0'), isTrue);
    expect(keep.contains('d3-1'), isFalse, reason: 'not among the 7 newest');
    expect(keep.contains('d5-1'), isFalse, reason: 'only the last of a day');
    expect(keep.contains('d29-0'), isTrue);
    expect(keep.contains('d29-1'), isFalse);
    expect(keep.contains('d30-0'), isFalse);
  });

  test('the newest copy is kept however old it is', () {
    final entries = [entry('only', now.subtract(const Duration(days: 90)))];
    expect(retention.idsToKeep(entries, now: now), {'only'});
  });

  test('the 7 newest are kept even when older than 30 days', () {
    // A phone left off for two months: its last copies are all that exists.
    final entries = [
      for (var n = 0; n < 9; n++)
        entry('old$n', now.subtract(Duration(days: 60, hours: n))),
    ];
    final keep = retention.idsToKeep(entries, now: now);
    expect(keep, {for (var n = 0; n < 7; n++) 'old$n'});
  });

  test('copies dated after now (clock moved back) are not lost', () {
    final entries = [
      entry('future', now.add(const Duration(days: 2))),
      entry('today', now),
    ];
    expect(retention.idsToKeep(entries, now: now), {'future', 'today'});
  });

  test('custom numbers', () {
    const small = BackupRetention(newest: 2, dailyForDays: 3);
    final entries = history(days: 10, perDay: 2);
    final keep = small.idsToKeep(entries, now: now);
    // 3 day representatives + the older copy of day 0 (second newest).
    expect(keep, {'d0-0', 'd0-1', 'd1-0', 'd2-0'});
  });

  group('copies of the same second', () {
    // What the folder lists: `-2` is the second copy of that second, so it is
    // the newer one (listBackupFiles sorts the same way).
    test('the counter decides: -2 is newer than the plain name', () {
      final entries = [
        for (var n = 0; n < 9; n++)
          entry('cuadrante-20261019-100000-${n + 2}.cuadrante', now),
        entry('cuadrante-20261019-100000.cuadrante', now),
      ];
      final keep = retention.idsToKeep(entries, now: now);
      // 10 copies of one second: the 7 newest are -10 .. -4, the plain one
      // (the oldest) and -2, -3 go.
      expect(keep, hasLength(7));
      expect(keep, isNot(contains('cuadrante-20261019-100000.cuadrante')));
      expect(keep, isNot(contains('cuadrante-20261019-100000-2.cuadrante')));
      expect(keep, isNot(contains('cuadrante-20261019-100000-3.cuadrante')));
      expect(keep, contains('cuadrante-20261019-100000-4.cuadrante'));
      expect(keep, contains('cuadrante-20261019-100000-10.cuadrante'));
    });

    test('two copies with 1 slot of room keep the -2', () {
      const one = BackupRetention(newest: 1, dailyForDays: 0);
      final keep = one.idsToKeep([
        entry('cuadrante-20261019-100000.cuadrante', now),
        entry('cuadrante-20261019-100000-2.cuadrante', now),
      ], now: now);
      expect(keep, {'cuadrante-20261019-100000-2.cuadrante'});
    });
  });
}
