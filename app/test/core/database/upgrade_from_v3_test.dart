import 'dart:io';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_opener.dart';
import 'package:cuadrante/core/database/migration_backup.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../drift/app_database/generated/schema_v3.dart' as v3;
import '../../support/test_storage.dart';
import '../../support/v3_database.dart';

void main() {
  late Directory dir;
  late File file;
  late Directory backups;
  late Map<String, List<Map<String, Object?>>> before;
  final stamp = DateTime.utc(2026, 11, 2, 8, 30, 15);

  setUp(() async {
    dir = makeTempDir('upgrade3');
    file = File(p.join(dir.path, databaseFileName));
    backups = Directory(p.join(dir.path, backupsDirectoryName));
    final old = v3.DatabaseAtV3(NativeDatabase(file));
    await seedV3(old);
    before = await dumpV3Columns(old);
    await old.close();
  });

  List<String> backupNames() => backups.existsSync()
      ? ([for (final f in backups.listSync()) p.basename(f.path)]..sort())
      : <String>[];

  Future<AppDatabase> open() async {
    final db = await openAppDatabase(directory: dir, now: () => stamp);
    await db.customSelect('SELECT 1').get();
    return db;
  }

  test(
    'real v3 file gets a complete v3 safety copy before reaching v4',
    () async {
      expect(readUserVersion(file), 3);
      final db = await open();
      expect(readUserVersion(file), 4);
      expect(await dumpV3Columns(db), before);
      expect(
        (await db.select(db.shiftTypes).get()).every(
          (t) => t.fixedPlusCents == null,
        ),
        isTrue,
      );
      await db.close();

      expect(backupNames(), ['pre-v3-a-v4-20261102-083015.sqlite']);
      final copy = File(p.join(backups.path, backupNames().single));
      expect(readUserVersion(copy), 3);
      final asV3 = v3.DatabaseAtV3(NativeDatabase(copy));
      expect(await dumpV3Columns(asV3), before);
      expect([
        for (final row
            in await asV3
                .customSelect("PRAGMA table_info('shift_types')")
                .get())
          row.data['name'],
      ], isNot(contains('fixed_plus_cents')));
      await asV3.close();
    },
  );

  test(
    'second open preserves the new plus and never repeats the migration copy',
    () async {
      final first = await open();
      final repo = ScheduleRepository(first);
      final night = (await repo.load('main')).schedule.shiftTypeById('night')!;
      await repo.saveShiftType(night.copyWith(fixedPlusCents: 3000));
      await first.close();

      final second = await openAppDatabase(
        directory: dir,
        now: () => stamp.add(const Duration(days: 1)),
      );
      final loaded = await ScheduleRepository(second).load('main');
      expect(loaded.schedule.shiftTypeById('night')!.fixedPlusCents, 3000);
      expect(backupNames(), ['pre-v3-a-v4-20261102-083015.sqlite']);
      expect(readUserVersion(file), 4);
      await second.close();
    },
  );

  test(
    'a failed safety copy leaves the v3 file and every value untouched',
    () async {
      File(backups.path).writeAsStringSync('blocking the backup directory');
      await expectLater(
        openAppDatabase(directory: dir, now: () => stamp),
        throwsA(isA<FileSystemException>()),
      );
      expect(readUserVersion(file), 3);
      final untouched = v3.DatabaseAtV3(NativeDatabase(file));
      expect(await dumpV3Columns(untouched), before);
      await untouched.close();
    },
  );
}
