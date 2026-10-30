import 'dart:io';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/backup_settings_repository.dart';
import 'package:cuadrante/features/backup/data/icloud_backup_store.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_retention.dart';
import 'package:cuadrante/features/backup/domain/backup_store.dart';
import 'package:cuadrante/features/backup/domain/icloud_errors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';

/// The Swift side, in memory: the contract of docs/copia-de-seguridad.md,
/// "Copia en iCloud", for the Dart half to be tested against.
class _FakeICloud {
  /// Files of the container, by name.
  final Map<String, Uint8List> files = {};
  final List<MethodCall> calls = [];

  /// `null` = answers normally; a code makes every call fail with it.
  String? failWith;

  /// What `status` says.
  bool available = true;
  String? reason;

  /// Names whose `delete` fails.
  final Set<String> undeletable = {};

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    if (failWith != null && call.method != 'status') {
      throw PlatformException(code: failWith!, message: 'fake');
    }
    final args = call.arguments as Map<Object?, Object?>?;
    switch (call.method) {
      case 'status':
        return {'available': available, 'reason': ?reason};
      case 'save':
        final name = args!['name']! as String;
        final bytes = args['bytes']! as Uint8List;
        files[name] = bytes;
        return {
          'id': name,
          'modifiedAtMs': DateTime.utc(2030).millisecondsSinceEpoch,
          'sizeBytes': bytes.length,
        };
      case 'list':
        return [
          for (final e in files.entries)
            {
              'id': e.key,
              'name': e.key,
              // iCloud's own dates are rubbish on purpose: the store must use
              // the stamp in the name.
              'modifiedAtMs': 1,
              'sizeBytes': e.value.length,
            },
        ];
      case 'read':
        return files[args!['id']];
      case 'delete':
        final id = args!['id']! as String;
        if (undeletable.contains(id)) {
          throw PlatformException(code: 'icloud_timeout');
        }
        files.remove(id);
        return null;
    }
    throw MissingPluginException(call.method);
  }
}

Future<bool> _alwaysOn() async => true;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ICloudBackupStore.channelName);
  late _FakeICloud native;

  void install(_FakeICloud? fake) => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(channel, fake?.handle);

  setUp(() {
    native = _FakeICloud();
    install(native);
  });
  tearDown(() => install(null));

  /// "Now" of the stores of these tests: names after it (plus a day) are
  /// ignored.
  final storeNow = DateTime.utc(2026, 10, 25);

  ICloudBackupStore store({
    int keep = 5,
    Set<String> Function(List<BackupEntry>)? retain,
    bool pruneOnSave = true,
  }) => ICloudBackupStore(
    channel: channel,
    keep: keep,
    retain: retain,
    pruneOnSave: pruneOnSave,
    now: () => storeNow,
  );

  DateTime day(int d, [int hour = 9]) => DateTime.utc(2026, 10, d, hour);

  test('the channel is app.cuadrante/icloud', () {
    expect(ICloudBackupStore.channelName, 'app.cuadrante/icloud');
  });

  group('available', () {
    test('says so, with the date of the newest copy', () async {
      final s = store();
      var status = await s.status();
      expect(status.available, isTrue);
      expect(status.lastCopyAt, isNull, reason: 'no copy yet');
      expect(await s.isAvailable(), isTrue);

      await s.save(Uint8List.fromList([1]), at: day(18));
      await s.save(Uint8List.fromList([2]), at: day(19));
      status = await s.status();
      expect(status.lastCopyAt, day(19));
    });

    test(
      'a write then a read gives the same bytes and lists the copy',
      () async {
        final s = store();
        final bytes = Uint8List.fromList(List.generate(300, (i) => i % 256));
        final saved = await s.save(
          bytes,
          at: DateTime.utc(2026, 10, 19, 10, 5, 7),
        );

        expect(saved.id, 'turnly-20261019-100507.turnly');
        expect(saved.modifiedAt, DateTime.utc(2026, 10, 19, 10, 5, 7));
        expect(saved.sizeBytes, 300);

        final save = native.calls.singleWhere((c) => c.method == 'save');
        expect((save.arguments as Map)['name'], saved.id);

        expect(await s.list(), [saved]);
        expect(await s.latest(), saved);
        expect(await s.read(saved), bytes);
      },
    );

    test(
      'two copies in the same second get a counter and neither is lost',
      () async {
        final s = store();
        final first = await s.save(Uint8List.fromList([1]), at: day(19));
        final second = await s.save(Uint8List.fromList([2]), at: day(19));
        final third = await s.save(Uint8List.fromList([3]), at: day(19));
        expect(second.id, 'turnly-20261019-090000-2.turnly');
        expect(third.id, 'turnly-20261019-090000-3.turnly');
        expect((await s.list()).map((e) => e.id), [
          third.id,
          second.id,
          first.id,
        ]);
        expect(await s.read(first), [1]);
        expect(await s.read(second), [2]);
      },
    );

    test('lists newest first by the date in the name, not by iCloud', () async {
      final s = store(keep: 9);
      await s.save(Uint8List(1), at: day(20));
      await s.save(Uint8List(1), at: day(18));
      await s.save(Uint8List(1), at: day(19));
      expect((await s.list()).map((e) => e.modifiedAt), [
        day(20),
        day(19),
        day(18),
      ]);
    });

    test('files that are not ours are ignored and never deleted', () async {
      native.files['notas.txt'] = Uint8List(1);
      native.files['pre-restore-20261019-090000.cuadrante'] = Uint8List(1);
      final s = store(keep: 1);
      await s.save(Uint8List(1), at: day(18));
      await s.save(Uint8List(1), at: day(19));
      expect(native.files.keys, contains('notas.txt'));
      expect(
        native.files.keys,
        contains('pre-restore-20261019-090000.cuadrante'),
      );
      expect((await s.list()).length, 1);
      await expectLater(
        s.read(
          BackupEntry(id: '../x.cuadrante', modifiedAt: day(1), sizeBytes: 0),
        ),
        throwsArgumentError,
      );
      await expectLater(
        s.delete(
          BackupEntry(id: 'notas.txt', modifiedAt: day(1), sizeBytes: 0),
        ),
        throwsArgumentError,
      );
    });
  });

  group('retention', () {
    test(
      'legacy and current names share listing, reads and rotation',
      () async {
        final names = [
          'turnly-20261016-090000.turnly',
          'cuadrante-20261017-090000.cuadrante',
          'turnly-20261018-090000.turnly',
          'cuadrante-20261019-090000.cuadrante',
        ];
        for (var i = 0; i < names.length; i++) {
          native.files[names[i]] = Uint8List.fromList([i]);
        }
        const foreign = 'pre-restore-20261015-090000.cuadrante';
        native.files[foreign] = Uint8List.fromList([9]);
        final s = store(keep: 3);
        final before = await s.list();
        expect(before.map((e) => e.id), names.reversed);
        expect(await s.read(before.first), [3]);
        final saved = await s.save(Uint8List.fromList([4]), at: day(20));
        expect(native.files.keys.toSet(), {
          saved.id,
          names[3],
          names[2],
          foreign,
        });
        expect((await s.list()).map((e) => e.id), [
          saved.id,
          names[3],
          names[2],
        ]);
      },
    );

    test('daily retention applies across both names', () async {
      const retention = BackupRetention(newest: 1, dailyForDays: 2);
      final names = [
        'cuadrante-20261017-090000.cuadrante',
        'turnly-20261018-080000.turnly',
        'cuadrante-20261018-090000.cuadrante',
        'turnly-20261019-080000.turnly',
      ];
      for (final name in names) {
        native.files[name] = Uint8List.fromList([1]);
      }
      final s = store(
        retain: (entries) => retention.idsToKeep(entries, now: day(19)),
      );
      final saved = await s.save(Uint8List.fromList([2]), at: day(19));
      expect(native.files.keys.toSet(), {saved.id, names[2]});
    });

    test('a same-second new copy follows the highest legacy counter', () async {
      const old = 'cuadrante-20261019-090000-9.cuadrante';
      native.files[old] = Uint8List.fromList([9]);
      final s = store(keep: 1);
      final saved = await s.save(Uint8List.fromList([10]), at: day(19));
      expect(saved.id, 'turnly-20261019-090000-10.turnly');
      expect(native.files.keys, [saved.id]);
      expect(await s.read(saved), [10]);
    });

    test('keeps the newest [keep] when saving', () async {
      final s = store(keep: 3);
      for (var d = 10; d <= 15; d++) {
        await s.save(Uint8List.fromList([d]), at: day(d));
      }
      expect((await s.list()).map((e) => e.modifiedAt.day), [15, 14, 13]);
      expect(native.files.length, 3);
    });

    test('a custom policy decides, but the newest copy always stays', () async {
      final s = store(retain: (entries) => <String>{});
      await s.save(Uint8List.fromList([1]), at: day(10));
      final newest = await s.save(Uint8List.fromList([2]), at: day(11));
      expect((await s.list()).map((e) => e.id), [newest.id]);

      final oldOnly = store(
        retain: (entries) => {entries.last.id},
        pruneOnSave: false,
      );
      await oldOnly.save(Uint8List.fromList([3]), at: day(12));
      await oldOnly.prune();
      expect(await oldOnly.list(), hasLength(2), reason: 'oldest and newest');
    });

    test('with pruneOnSave off nothing goes until prune()', () async {
      final s = store(keep: 1, pruneOnSave: false);
      await s.save(Uint8List(1), at: day(10));
      await s.save(Uint8List(1), at: day(11));
      expect(native.files.length, 2);
      await s.prune();
      expect(native.files.length, 1);
      expect((await s.latest())!.modifiedAt, day(11));
    });

    test(
      'a copy that cannot be deleted is left; the save still works',
      () async {
        final s = store(keep: 1);
        final old = await s.save(Uint8List(1), at: day(10));
        native.undeletable.add(old.id);
        final fresh = await s.save(Uint8List(1), at: day(11));
        expect(native.files.keys, containsAll([old.id, fresh.id]));
      },
    );
  });

  group('unavailable', () {
    test(
      'status says no, with the reason when the native side gives one',
      () async {
        native
          ..available = false
          ..reason = 'signed_out';
        final status = await store().status();
        expect(status.available, isFalse);
        expect(status.reason, 'signed_out');
        expect(status.lastCopyAt, isNull);
        expect(await store().isAvailable(), isFalse);
      },
    );

    test(
      'icloud_unavailable: listing is empty, save and read say so',
      () async {
        native.failWith = 'icloud_unavailable';
        final s = store();
        expect(await s.list(), isEmpty);
        expect(await s.latest(), isNull);
        await expectLater(
          s.save(Uint8List(1), at: day(10)),
          throwsA(isA<ICloudUnavailable>()),
        );
        await expectLater(
          s.read(
            BackupEntry(
              id: 'cuadrante-20261010-090000.cuadrante',
              modifiedAt: day(10),
              sizeBytes: 1,
            ),
          ),
          throwsA(isA<ICloudUnavailable>()),
        );
      },
    );

    test('the other errors of the contract are typed', () async {
      final s = store();
      native.failWith = 'icloud_full';
      await expectLater(
        s.save(Uint8List(1), at: day(10)),
        throwsA(isA<ICloudFull>()),
      );
      native.failWith = 'icloud_timeout';
      await expectLater(s.list(), throwsA(isA<ICloudTimeout>()));
      native.failWith = 'something_else';
      await expectLater(s.list(), throwsA(isA<ICloudFailed>()));
    });

    test('a native side that never answers times out', () async {
      install(null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) => Future<Object?>.delayed(const Duration(seconds: 5)),
          );
      final s = ICloudBackupStore(
        channel: channel,
        callTimeout: const Duration(milliseconds: 20),
      );
      await expectLater(s.list(), throwsA(isA<ICloudTimeout>()));
      expect((await s.status()).available, isFalse);
    });
  });

  group('no native side (Android, iOS before the Swift channel)', () {
    setUp(() => install(null));

    test(
      'iCloud no disponible, and nothing throws where it should not',
      () async {
        final s = store();
        expect(await s.isAvailable(), isFalse);
        final status = await s.status();
        expect(status.available, isFalse);
        expect(await s.list(), isEmpty);
        expect(await s.latest(), isNull);
        await expectLater(
          s.save(Uint8List(1), at: day(10)),
          throwsA(
            isA<ICloudUnavailable>().having(
              (e) => e.message,
              'message',
              'iCloud no disponible',
            ),
          ),
        );
        await expectLater(
          s.delete(
            BackupEntry(
              id: 'cuadrante-20261010-090000.cuadrante',
              modifiedAt: day(10),
              sizeBytes: 1,
            ),
          ),
          throwsA(isA<ICloudUnavailable>()),
        );
      },
    );
  });

  group('the backup flow', () {
    late Directory dir;
    final at = DateTime.utc(2026, 10, 19, 10);

    BackupTools tools(
      ICloudBackupStore? cloud, {
      Future<bool> Function() enabled = _alwaysOn,
    }) {
      final db = openMemoryDatabase();
      addTearDown(db.close);
      final auto = LocalFileBackupStore(dir);
      return BackupTools(
        directory: dir,
        autoStore: auto,
        safetyStore: LocalFileBackupStore(dir, prefix: 'pre-restore'),
        cloudStore: cloud,
        cloudEnabled: enabled,
        service: BackupService(
          repository: makeRepository(db, dir, now: () => at),
          store: auto,
          appVersion: testAppVersion,
          now: () => at,
        ),
      );
    }

    setUp(() => dir = Directory(p.join(makeTempDir('icloud').path, 'backups')));

    test(
      'a verified local copy is mirrored to iCloud with the same name',
      () async {
        final t = tools(store(pruneOnSave: false));
        final entry = await t.backupAndVerify();
        expect(native.files.keys, [entry.id]);
        expect(t.cloudError, isNull);
        const BackupCodec().decode(native.files[entry.id]!);
        expect((await t.cloudCopies()).single.id, entry.id);
        expect(await t.readCloud(entry), native.files[entry.id]);
      },
    );

    test(
      'iCloud failing never fails the backup; the copy is on the phone',
      () async {
        native.failWith = 'icloud_full';
        final t = tools(store());
        final entry = await t.backupAndVerify();
        expect(fileNames(dir), [entry.id]);
        expect(t.cloudError, isA<ICloudFull>());

        native.failWith = null;
        await t.backupAndVerify();
        expect(t.cloudError, isNull);
      },
    );

    test(
      'with no native side the backup works and says iCloud is missing',
      () async {
        install(null);
        final t = tools(store());
        final entry = await t.backupAndVerify();
        expect(fileNames(dir), [entry.id]);
        expect(t.cloudError, isA<ICloudUnavailable>());
        expect(await t.cloudCopies(), isEmpty);
      },
    );

    test('with no iCloud store (Android) nothing changes', () async {
      final t = tools(null);
      await t.backupAndVerify();
      expect(t.cloudError, isNull);
      expect(await t.cloudCopies(), isEmpty);
      await expectLater(
        t.readCloud(
          BackupEntry(
            id: 'cuadrante-20261010-090000.cuadrante',
            modifiedAt: at,
            sizeBytes: 1,
          ),
        ),
        throwsA(isA<ICloudUnavailable>()),
      );
      expect(native.calls, isEmpty);
    });
  });

  group('size caps before reading (M1)', () {
    const big = BackupCodec.maxFileBytes + 1;
    const name = 'cuadrante-20261019-090000.cuadrante';

    test('a listed entry over the cap is refused without asking native '
        'for the bytes', () async {
      native.files[name] = Uint8List(big);
      final s = store();
      final entry = (await s.list()).single;
      expect(entry.sizeBytes, big);
      await expectLater(
        s.read(entry),
        throwsA(
          isA<ICloudFailed>().having(
            (e) => e.message,
            'message',
            'read: too large',
          ),
        ),
      );
      expect(native.calls.where((c) => c.method == 'read'), isEmpty);
    });

    test('a file of exactly the cap is read', () async {
      native.files[name] = Uint8List(BackupCodec.maxFileBytes);
      final s = store();
      final entry = (await s.list()).single;
      expect((await s.read(entry)).length, BackupCodec.maxFileBytes);
    });

    test('the too_large code of the contract is a typed failure', () async {
      native.failWith = 'too_large';
      await expectLater(
        store().read(BackupEntry(id: name, modifiedAt: day(19), sizeBytes: 10)),
        throwsA(
          isA<ICloudFailed>().having(
            (e) => e.message,
            'message',
            contains('too large'),
          ),
        ),
      );
    });

    test('bytes over the cap are refused even if the listing said they were '
        'small', () async {
      native.files[name] = Uint8List(big);
      await expectLater(
        store().read(BackupEntry(id: name, modifiedAt: day(19), sizeBytes: 1)),
        throwsA(isA<ICloudFailed>()),
      );
    });
  });

  group('names that are not a real moment (L1)', () {
    test('a stamp that is not a date, or lies after tomorrow, is not a copy of '
        'ours', () async {
      native.files
        ..['cuadrante-20261399-999999.cuadrante'] = Uint8List(1)
        ..['cuadrante-20260230-090000.cuadrante'] = Uint8List(1)
        ..['cuadrante-20261231-090000.cuadrante'] = Uint8List(1)
        ..['cuadrante-20261026-000001.cuadrante'] = Uint8List(1)
        // Exactly one day after "now" still counts (clocks differ).
        ..['cuadrante-20261026-000000.cuadrante'] = Uint8List(1)
        ..['cuadrante-20261019-090000.cuadrante'] = Uint8List(1);
      final s = store();
      expect((await s.list()).map((e) => e.id), [
        'cuadrante-20261026-000000.cuadrante',
        'cuadrante-20261019-090000.cuadrante',
      ]);
      expect((await s.status()).lastCopyAt, DateTime.utc(2026, 10, 26));
    });

    test('a bogus file is never pruned or read as if it were ours', () async {
      native.files['cuadrante-20261399-999999.cuadrante'] = Uint8List(1);
      final s = store(keep: 1);
      await s.save(Uint8List(1), at: day(18));
      await s.save(Uint8List(1), at: day(19));
      expect(
        native.files.keys,
        contains('cuadrante-20261399-999999.cuadrante'),
      );
    });
  });

  group('replies of an unexpected shape (L2)', () {
    void answer(Object? Function(MethodCall call) reply) =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async => reply(call));

    test('status never throws, whatever it is told', () async {
      answer((_) => 'yes');
      var status = await store().status();
      expect(status.available, isFalse);

      answer((_) => [1, 2]);
      status = await store().status();
      expect(status.available, isFalse);
      expect(await store().isAvailable(), isFalse);
    });

    test('available with a listing of the wrong shape is still available, '
        'date unknown', () async {
      answer((call) => call.method == 'status' ? {'available': true} : 'junk');
      final status = await store().status();
      expect(status.available, isTrue);
      expect(status.lastCopyAt, isNull);
    });

    test(
      'list, save and read fail with a typed error, not a TypeError',
      () async {
        answer((_) => {'not': 'a list'});
        await expectLater(store().list(), throwsA(isA<ICloudFailed>()));

        answer((call) => call.method == 'list' ? <Object?>[] : [1, 2, 3]);
        await expectLater(
          store().save(Uint8List(1), at: day(10)),
          throwsA(isA<ICloudFailed>()),
        );

        answer((_) => 'text');
        await expectLater(
          store().read(
            BackupEntry(
              id: 'cuadrante-20261019-090000.cuadrante',
              modifiedAt: day(19),
              sizeBytes: 1,
            ),
          ),
          throwsA(isA<ICloudFailed>()),
        );
      },
    );
  });

  group('the iCloud replica is opt-in (H1)', () {
    late Directory dir;
    late AppDatabase db;
    final at = DateTime.utc(2026, 10, 19, 10);

    setUp(() {
      dir = Directory(p.join(makeTempDir('icloud-optin').path, 'backups'));
      db = openMemoryDatabase();
      addTearDown(db.close);
    });

    /// The real providers over an in-memory database. [builtIn] stands for
    /// `kICloudReplica` (a constant cannot change in a test).
    Future<({ProviderContainer container, BackupTools tools})> open({
      bool builtIn = false,
      bool ios = true,
      bool optIn = false,
    }) async {
      if (optIn) await BackupSettingsRepository(db).saveCloud(true);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => at),
          backupDirectoryProvider.overrideWith((ref) async => dir),
          backupTaskRunnerProvider.overrideWithValue(runOnThisIsolate),
          iCloudPlatformProvider.overrideWithValue(ios),
          if (builtIn) iCloudReplicaBuiltInProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);
      // The switch is read at start, as the app does.
      await container.read(cloudBackupEnabledProvider.future);
      final tools = await container.read(backupToolsProvider.future);
      return (container: container, tools: tools);
    }

    int saves() => native.calls.where((c) => c.method == 'save').length;

    BackupTools bareTools({Future<bool> Function()? enabled}) {
      final db2 = openMemoryDatabase();
      addTearDown(db2.close);
      final auto = LocalFileBackupStore(dir);
      final service = BackupService(
        repository: makeRepository(db2, dir, now: () => at),
        store: auto,
        appVersion: testAppVersion,
        now: () => at,
      );
      final safety = LocalFileBackupStore(dir, prefix: 'pre-restore');
      return enabled == null
          ? BackupTools(
              directory: dir,
              autoStore: auto,
              safetyStore: safety,
              cloudStore: store(),
              service: service,
            )
          : BackupTools(
              directory: dir,
              autoStore: auto,
              safetyStore: safety,
              cloudStore: store(),
              cloudEnabled: enabled,
              service: service,
            );
    }

    test(
      'this build has the replica off (question 13 of docs/preguntas.md)',
      () {
        expect(kICloudReplica, isFalse);
      },
    );

    test('with kICloudReplica off nothing is mirrored, even with the Swift '
        'channel there and the switch on', () async {
      final app = await open(optIn: true);
      expect(await BackupSettingsRepository(db).loadCloud(), isTrue);
      expect(app.container.read(iCloudBackupStoreProvider), isNull);
      expect(app.tools.cloudStore, isNull);

      final entry = await app.tools.backupAndVerify();
      expect(fileNames(dir), [entry.id]);
      expect(native.calls, isEmpty);
      expect(native.files, isEmpty);
      expect(app.tools.cloudError, isNull);
    });

    test(
      'built in but the switch off (the default): no store, no mirror',
      () async {
        final app = await open(builtIn: true);
        expect(await BackupSettingsRepository(db).loadCloud(), isFalse);
        expect(app.container.read(iCloudBackupStoreProvider), isNull);

        final entry = await app.tools.backupAndVerify();
        expect(fileNames(dir), [entry.id]);
        expect(native.calls, isEmpty);
      },
    );

    test('built in and the switch on: the verified copy is mirrored', () async {
      final app = await open(builtIn: true, optIn: true);
      expect(app.container.read(iCloudBackupStoreProvider), isNotNull);

      final entry = await app.tools.backupAndVerify();
      expect(native.files.keys, [entry.id]);
    });

    test('only on iOS', () async {
      final app = await open(builtIn: true, optIn: true, ios: false);
      expect(app.container.read(iCloudBackupStoreProvider), isNull);
      await app.tools.backupAndVerify();
      expect(native.calls, isEmpty);
    });

    test('switching it off stops the very next copy, without rebuilding '
        'anything', () async {
      final app = await open(builtIn: true, optIn: true);
      await app.tools.backupAndVerify();
      expect(saves(), 1);

      // Straight to the database: nothing tells the tools or the providers.
      await BackupSettingsRepository(db).saveCloud(false);
      final second = await app.tools.backupAndVerify();
      expect(saves(), 1, reason: 'the second copy stayed on the phone');
      expect(fileNames(dir), hasLength(2));
      expect(native.files.keys, isNot(contains(second.id)));
    });

    test(
      'a store alone mirrors nothing: the default of the tools is off',
      () async {
        await bareTools().backupAndVerify();
        expect(native.calls, isEmpty);
      },
    );

    test('a switch that cannot be read counts as off', () async {
      await bareTools(enabled: () async => throw StateError('db closed'))
          .backupAndVerify();
      expect(native.calls, isEmpty);
    });

    test('the switch is off unless explicitly true', () async {
      final repo = BackupSettingsRepository(db);
      expect(await repo.loadCloud(), isFalse);
      await db.customStatement(
        "INSERT INTO settings (key, value) VALUES ('backup.cloud', 'garbage')",
      );
      expect(await repo.loadCloud(), isFalse);
      await repo.saveCloud(true);
      expect(await repo.loadCloud(), isTrue);
      await repo.saveCloud(false);
      expect(await repo.loadCloud(), isFalse);
    });

    test(
      'reading what is in iCloud stays possible, and never writes',
      () async {
        native.files['cuadrante-20261019-090000.cuadrante'] = Uint8List(3);
        final app = await open(builtIn: true, optIn: true);
        final copies = await app.tools.cloudCopies();
        expect(copies.single.sizeBytes, 3);
        expect(await app.tools.readCloud(copies.single), hasLength(3));
        expect(saves(), 0);
      },
    );
  });

  group('the platform channel of each system', () {
    test('Android and iOS get the real channel, desktop gets nothing', () {
      expect(
        defaultPlatformBackupChannel(isAndroid: true, isIOS: false),
        isA<MethodChannelBackupChannel>(),
      );
      expect(
        defaultPlatformBackupChannel(isAndroid: false, isIOS: true),
        isA<MethodChannelBackupChannel>(),
      );
      expect(
        defaultPlatformBackupChannel(isAndroid: false, isIOS: false),
        isA<NoPlatformBackupChannel>(),
      );
    });

    test(
      'on iOS, without the Swift side, nothing arrives and nothing breaks',
      () async {
        final ios = defaultPlatformBackupChannel(isAndroid: false, isIOS: true);
        expect(await ios.hasIncomingFile(), isFalse);
        expect(await ios.takeIncomingFile(), isNull);
        await ios.discardIncomingFile();
        await ios.setPreviewProtection(enabled: true);
        expect(await ios.systemBackupState(), SystemBackupState.notApplicable);
      },
    );

    test(
      'on iOS the Android line of the system backup is never asked',
      () async {
        const backup = MethodChannel(MethodChannelBackupChannel.channelName);
        final asked = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(backup, (call) async {
              asked.add(call.method);
              return 'on';
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(backup, null),
        );
        final ios = defaultPlatformBackupChannel(isAndroid: false, isIOS: true);
        expect(await ios.systemBackupState(), SystemBackupState.notApplicable);
        expect(asked, isEmpty);

        final android = defaultPlatformBackupChannel(
          isAndroid: true,
          isIOS: false,
        );
        expect(await android.systemBackupState(), SystemBackupState.on);
        expect(asked, ['systemBackupState']);
      },
    );
  });
}
