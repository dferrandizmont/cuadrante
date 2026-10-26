import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/data/export_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'backup_test_support.dart';

/// An exported `.cuadrante` holds the whole schedule: it must not stay in the
/// cache after sharing.
void main() {
  late Directory cacheRoot;
  late ExportCache cache;
  final bytes = Uint8List.fromList([1, 2, 3]);

  List<String> names() => cache.directory.existsSync()
      ? [for (final f in cache.directory.listSync()) p.basename(f.path)]
      : <String>[];

  setUp(() {
    cacheRoot = makeTempDir('export-cache');
    cache = ExportCache(cacheRoot, graceBeforeDelete: Duration.zero);
  });

  test('the file is written under cache/export/, not the cache root', () async {
    late File seen;
    await cache.share(bytes, 'cuadrante-2026-10-19.cuadrante', (file) async {
      seen = file;
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), bytes);
    });
    expect(p.dirname(seen.path), p.join(cacheRoot.path, 'export'));
  });

  test('the file is deleted once the share sheet has returned', () async {
    await cache.share(bytes, 'a.cuadrante', (_) async {});
    await cache.lastCleanup;
    expect(names(), isEmpty);
  });

  test('also when the share sheet fails', () async {
    await expectLater(
      cache.share(bytes, 'a.cuadrante', (_) async => throw StateError('x')),
      throwsStateError,
    );
    await cache.lastCleanup;
    expect(names(), isEmpty);
  });

  test('the file is still there while the receiving app may read it', () async {
    final slow = ExportCache(
      cacheRoot,
      graceBeforeDelete: const Duration(minutes: 5),
    );
    await slow.share(bytes, 'a.cuadrante', (_) async {});
    expect(names(), ['a.cuadrante']);
    // The next export (or the next start) removes it.
    await slow.sweep();
    expect(names(), isEmpty);
  });

  test('an export first removes the leftovers of earlier ones', () async {
    await cache.directory.create(recursive: true);
    File(p.join(cache.directory.path, 'old.cuadrante')).writeAsBytesSync([9]);
    await cache.write(bytes, 'new.cuadrante');
    expect(names(), ['new.cuadrante']);
  });

  test('sweep empties the folder and never throws', () async {
    await cache.sweep(); // no folder yet
    await cache.directory.create(recursive: true);
    File(p.join(cache.directory.path, 'a.cuadrante')).writeAsBytesSync([1]);
    Directory(p.join(cache.directory.path, 'sub')).createSync();
    await cache.sweep();
    expect(names(), isEmpty);
  });

  test('a file name cannot climb out of the folder', () async {
    final file = await cache.write(bytes, '../../evil.cuadrante');
    expect(p.dirname(file.path), cache.directory.path);
    expect(
      File(p.join(cacheRoot.path, 'evil.cuadrante')).existsSync(),
      isFalse,
    );
  });

  group('the shared sharer (backupSharerProvider)', () {
    test('a second export inside the grace period keeps its file', () async {
      final root = makeTempDir('export-cache-sharer');
      // Wide margins: real timers and real files, and the suite runs on a
      // busy machine (an emulator next to it).
      final grace = const Duration(milliseconds: 2000);
      final container = ProviderContainer(
        overrides: [
          exportCacheProvider.overrideWith(
            (ref) async => ExportCache(root, graceBeforeDelete: grace),
          ),
          exportFileSenderProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(container.dispose);
      final share = container.read(backupSharerProvider);
      final dir = Directory(p.join(root.path, ExportCache.folderName));
      List<String> files() => dir.existsSync()
          ? [for (final f in dir.listSync()) p.basename(f.path)]
          : <String>[];

      // Same second, same name: the worst case for a delayed delete.
      await share(bytes, 'cuadrante-2026-10-19-120000.cuadrante');
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      await share(
        Uint8List.fromList([4, 5, 6]),
        'cuadrante-2026-10-19-120000.cuadrante',
      );
      // Past the moment the FIRST export's timer would have fired (2.0 s),
      // well before the second one's (3.0 s).
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(files(), ['cuadrante-2026-10-19-120000.cuadrante']);
      // ...and the second one's own timer still cleans up.
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (files().isNotEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(files(), isEmpty);
    });
  });
}
