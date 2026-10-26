import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/post_night_settings.dart';

final postNightSettingsRepositoryProvider =
    Provider<PostNightSettingsRepository>(
      (ref) => PostNightSettingsRepository(ref.watch(appDatabaseProvider)),
    );

/// The setting "Saliente automático" (`postNight.auto`, off by default).
///
/// Synchronous on purpose: the paint stroke that ends reads it in the same
/// frame. It starts as `false` and adopts the stored value as soon as it is
/// read (the schedule controller reads it at start-up); [set] stores the new
/// value and updates the state at once. The Settings screen only needs
/// `ref.watch(postNightAutoProvider)` and
/// `ref.read(postNightAutoProvider.notifier).set(value)`.
class PostNightAuto extends Notifier<bool> {
  int _generation = 0;

  @override
  bool build() {
    _load(++_generation);
    return false;
  }

  Future<void> _load(int generation) async {
    try {
      final stored = await ref
          .read(postNightSettingsRepositoryProvider)
          .loadAuto();
      if (ref.mounted && generation == _generation) state = stored;
    } catch (_) {
      // Unreadable or no database (previews): stay off, never block painting.
    }
  }

  /// Reads the stored value again (after a restore replaced the settings).
  /// Unlike the first load, a failure is thrown so the caller can retry.
  Future<void> reload() async {
    final generation = ++_generation;
    final stored = await ref
        .read(postNightSettingsRepositoryProvider)
        .loadAuto();
    if (ref.mounted && generation == _generation) state = stored;
  }

  /// Switches it and stores it. If the write fails the switch goes back to
  /// what it was (it must not show a value that is not stored) and the error
  /// is rethrown for the caller to report.
  Future<void> set(bool value) async {
    _generation++;
    final previous = state;
    state = value;
    try {
      await ref.read(postNightSettingsRepositoryProvider).saveAuto(value);
    } catch (_) {
      if (ref.mounted) state = previous;
      rethrow;
    }
  }
}

final postNightAutoProvider = NotifierProvider<PostNightAuto, bool>(
  PostNightAuto.new,
);
