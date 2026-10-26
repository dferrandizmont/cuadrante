import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/data/schedule_seeding.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../backup/backup_test_support.dart';

const _today = CivilDate(2026, 10, 19);
final _now = DateTime(2026, 10, 19, 12);

/// A database written by an older build, whose shift type form let a code of
/// more than three UTF-16 units through (two emojis are four).
void main() {
  late AppDatabase db;
  late ScheduleRepository repo;
  late BackupService service;

  setUp(() async {
    db = openMemoryDatabase();
    addTearDown(db.close);
    repo = ScheduleRepository(db, now: () => _now);
    await seedIfEmpty(repo, demo: false, today: _today);
    final dir = makeTempDir('shift-code-repair');
    service = BackupService(
      repository: makeRepository(db, Directory(p.join(dir.path, 'safety'))),
      store: LocalFileBackupStore(Directory(p.join(dir.path, 'store'))),
      appVersion: testAppVersion,
      now: () => DateTime.utc(2026, 11, 10, 9),
    );
  });

  Future<void> corrupt() async {
    await db.customStatement(
      "UPDATE shift_types SET code = '🙂🙂' WHERE id = 'morning'",
    );
    await db.customStatement(
      "UPDATE shift_types SET code = 'ABCDE' WHERE id = 'afternoon'",
    );
    await db.customStatement(
      "UPDATE shift_types SET code = '' WHERE id = 'night'",
    );
  }

  Future<Map<String, String>> codes() async {
    final rows = await db
        .customSelect('SELECT id, code FROM shift_types')
        .get();
    return {for (final r in rows) r.read<String>('id'): r.read<String>('code')};
  }

  test('a stored code the backup rejects blocks every export', () async {
    await corrupt();
    await expectLater(service.exportBytes(), throwsA(anything));
    await expectLater(service.backupNow(), throwsA(anything));
  });

  test('repairShiftTypeCodes cuts a long code to whole characters within '
      'three units, fills an empty one, and leaves the rest alone', () async {
    final before = await codes();
    await corrupt();

    expect(await repo.repairShiftTypeCodes(), 3);

    final after = await codes();
    expect(after['morning'], '🙂');
    expect(after['afternoon'], 'ABC');
    expect(after['night'], '?');
    for (final id in before.keys.where(
      (id) => !{'morning', 'afternoon', 'night'}.contains(id),
    )) {
      expect(after[id], before[id], reason: id);
    }
    // Nothing else is touched, and a second pass finds nothing to do.
    expect(await repo.repairShiftTypeCodes(), 0);
    expect(await codes(), after);
  });

  test('start-up repairs them: the schedule loads and the backup works '
      'again', () async {
    await corrupt();

    final result = await bootstrapApp(database: db, now: () => _now);

    final byId = {for (final t in result.schedule.schedule.shiftTypes) t.id: t};
    expect(byId['morning']?.code, '🙂');
    expect(byId['afternoon']?.code, 'ABC');
    expect(byId['night']?.code, '?');

    final bytes = await service.exportBytes();
    expect(bytes, isNotEmpty);
    await service.backupNow();
    // The safety copy a restore takes first works too.
    final pending = await service.inspect(bytes);
    await service.restore(pending);
  });
}
