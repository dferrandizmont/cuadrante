import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The open database. `main` overrides it with the one `bootstrapApp` opened;
/// tests override it with an in-memory one.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'appDatabaseProvider must be overridden (bootstrapApp in main, an '
    'in-memory database in tests).',
  ),
);
