import 'package:cuadrante/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

/// Written by hand (not generated, so `make-migrations` never overwrites it):
/// the schema the code creates must be exactly the latest dump in
/// `drift_schemas/app_database/`. Changing a table without running
/// `make-migrations` and writing the migration step fails here.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('the latest dump is the version the code declares', () {
    expect(GeneratedHelper.versions.last, AppDatabase.latestSchemaVersion);
  });

  test('a new database has exactly the schema of the latest dump', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.latestSchemaVersion);
  });
}
