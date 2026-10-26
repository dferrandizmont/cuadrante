import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/providers.dart';
import '../data/schedule_repository.dart';
import '../data/schedule_snapshot.dart';

/// The only door to the stored schedule.
final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
  ),
);

/// The schedule `bootstrapApp` loaded before the first frame. `main`
/// overrides it; tests override it with the snapshot of their own database.
final initialScheduleProvider = Provider<ScheduleSnapshot>(
  (ref) => throw UnimplementedError(
    'initialScheduleProvider must be overridden (bootstrapApp in main, a '
    'loaded in-memory database in tests).',
  ),
);
