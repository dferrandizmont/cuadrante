import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import 'app_database.steps.dart';

/// Adds the optional fixed shift payment in place. Existing rows retain all
/// their values and start with no plus. The automatic pre-migration copy is
/// made by openAppDatabase, before opening Drift (docs/datos.md).
Future<void> migrateFrom3To4(
  Migrator m,
  Schema4 schema, {
  Future<void> Function()? afterAdd,
}) async {
  final db = m.database;
  await db.transaction(() async {
    final before = await db
        .customSelect('SELECT * FROM shift_types ORDER BY id')
        .get();
    await m.addColumn(schema.shiftTypes, schema.shiftTypes.fixedPlusCents);
    await afterAdd?.call();
    final after = await db
        .customSelect('SELECT * FROM shift_types ORDER BY id')
        .get();
    final previous = [for (final row in before) row.data];
    final migrated = [
      for (final row in after)
        Map<String, Object?>.of(row.data)..remove('fixed_plus_cents'),
    ];
    if (!const DeepCollectionEquality().equals(previous, migrated) ||
        after.any((row) => row.data['fixed_plus_cents'] != null)) {
      throw StateError('Migration v3 -> v4 changed shift data; rolled back');
    }
  });
}
