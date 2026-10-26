import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/providers.dart';
import '../data/calendars_repository.dart';

/// The only door to the calendars and to `calendars.active` /
/// `calendars.primary`.
final calendarsRepositoryProvider = Provider<CalendarsRepository>(
  (ref) => CalendarsRepository(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
  ),
);
