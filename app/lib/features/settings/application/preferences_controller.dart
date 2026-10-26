import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/preferences_repository.dart';
import '../domain/preferences.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(ref.watch(appDatabaseProvider)),
);

/// The preferences `bootstrapApp` loaded before the first frame, so the app
/// opens in the right theme without a flash. `main` overrides it. Left
/// `null` (tests, the QA harness), the controller starts on the defaults and
/// reads the stored values right after.
final initialPreferencesProvider = Provider<Preferences?>((ref) => null);

/// The user's preferences. The state changes at once; the write follows. If
/// it fails the previous value comes back and the error reaches the caller.
class PreferencesController extends Notifier<Preferences> {
  // A change made before the first read finished wins over that read.
  bool _touched = false;

  @override
  Preferences build() {
    _touched = false;
    final initial = ref.read(initialPreferencesProvider);
    if (initial != null) return initial;
    unawaited(_loadInitial());
    return Preferences.defaults;
  }

  Future<void> _loadInitial() async {
    try {
      final stored = await ref.read(preferencesRepositoryProvider).load();
      if (ref.mounted && !_touched) state = stored;
    } catch (_) {
      // Unreadable preferences: keep the defaults.
    }
  }

  /// Reads the stored preferences again (after a restore replaced them).
  Future<void> reload() async {
    final stored = await ref.read(preferencesRepositoryProvider).load();
    if (ref.mounted) state = stored;
  }

  Future<void> setThemeMode(ThemeMode mode) => _change(
    state.copyWith(themeMode: mode),
    (repository) => repository.setThemeMode(mode),
  );

  /// [weekStart] is [WeekStart.monday] or [WeekStart.sunday].
  Future<void> setWeekStart(int weekStart) => _change(
    state.copyWith(weekStart: weekStart),
    (repository) => repository.setWeekStart(weekStart),
  );

  Future<void> setWeekNumbers(bool show) => _change(
    state.copyWith(weekNumbers: show),
    (repository) => repository.setWeekNumbers(show),
  );

  /// Applied at once through `MaterialApp.locale` (see `CuadranteApp`).
  Future<void> setLanguage(AppLanguage language) => _change(
    state.copyWith(language: language),
    (repository) => repository.setLanguage(language),
  );

  Future<void> _change(
    Preferences next,
    Future<void> Function(PreferencesRepository repository) write,
  ) async {
    final previous = state;
    if (next == previous) return;
    _touched = true;
    state = next;
    try {
      await write(ref.read(preferencesRepositoryProvider));
    } catch (_) {
      if (ref.mounted && state == next) state = previous;
      rethrow;
    }
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesController, Preferences>(
      PreferencesController.new,
    );
