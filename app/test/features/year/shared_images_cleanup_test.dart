import 'dart:io';

import 'package:cuadrante/features/year/application/year_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  final now = DateTime(2026, 10, 20, 12);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('shared_images');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  File make(String name, {required Duration age}) {
    final file = File(p.join(dir.path, name))..writeAsBytesSync([1, 2, 3]);
    file.setLastModifiedSync(now.subtract(age));
    return file;
  }

  test('old shared month and year images go, recent ones stay', () async {
    final oldMonth = make(
      'cuadrante-2026-09.png',
      age: const Duration(days: 3),
    );
    final oldYear = make('cuadrante-2025.png', age: const Duration(days: 2));
    final recent = make('cuadrante-2026-10.png', age: const Duration(hours: 3));
    await deleteStaleSharedImages(dir, now: now);
    expect(oldMonth.existsSync(), isFalse);
    expect(oldYear.existsSync(), isFalse);
    expect(recent.existsSync(), isTrue);
  });

  test('other files in the folder are never touched', () async {
    final other = make('foto.png', age: const Duration(days: 30));
    final similar = make('cuadrante-notas.png', age: const Duration(days: 30));
    final backup = make(
      'cuadrante-2026.cuadrante',
      age: const Duration(days: 30),
    );
    await deleteStaleSharedImages(dir, now: now);
    expect(other.existsSync(), isTrue);
    expect(similar.existsSync(), isTrue);
    expect(backup.existsSync(), isTrue);
  });

  test('a folder that is missing is not an error', () async {
    await deleteStaleSharedImages(Directory(p.join(dir.path, 'nada')));
  });
}
