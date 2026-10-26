import 'dart:async';

import '../data/widget_publisher.dart';
import '../domain/widget_snapshot.dart';
import '../domain/widget_strings.dart';
import '../domain/widget_sync_planner.dart';
import 'widget_sync.dart';

/// Keeps the snapshot on the platform widgets equal to the app's state.
///
/// [request] raises a [WidgetSyncTrigger]; triggers that come in bursts
/// (schedule and holiday edits) wait [WidgetSyncTrigger.debounce] of quiet,
/// the rest act at once. Runs are serialised and coalesced: while one is in
/// flight the next triggers only queue, and they are handled together by one
/// more run. A failed run never stops later ones.
class WidgetSyncService {
  WidgetSyncService({
    required this.publisher,
    required this.buildSnapshot,
    this.onError,
  });

  final WidgetPublisher publisher;

  /// Builds the snapshot for the current state (primary calendar, holidays,
  /// clock, time zone) with the given texts.
  final Future<WidgetSnapshot> Function(WidgetStrings strings) buildSnapshot;

  /// Called with the errors of a run.
  final void Function(Object error, StackTrace stack)? onError;

  WidgetStrings? _strings;

  final List<WidgetSyncTrigger> _pending = [];
  Timer? _timer;
  Future<void>? _loop;
  bool _disposed = false;

  /// Runs that built a snapshot (for tests and diagnostics).
  int runs = 0;

  /// The plan of the latest completed run.
  WidgetSyncPlan? lastPlan;

  /// Texts of the current locale. Until they are set (the host sets them as
  /// soon as it has a context) triggers wait; setting them handles the ones
  /// that were waiting.
  WidgetStrings? get strings => _strings;

  set strings(WidgetStrings? value) {
    _strings = value;
    if (value != null && _pending.isNotEmpty) unawaited(_kick());
  }

  /// Raises [trigger]. Returns when the run that handles it has finished (a
  /// debounced trigger returns at once).
  Future<void> request(WidgetSyncTrigger trigger) {
    if (_disposed) return Future.value();
    _pending.add(trigger);
    if (trigger.debounce == Duration.zero) {
      _timer?.cancel();
      _timer = null;
      return _kick();
    }
    _timer?.cancel();
    _timer = Timer(trigger.debounce, () {
      _timer = null;
      unawaited(_kick());
    });
    return Future.value();
  }

  /// Completes when the run in flight (if any) has finished.
  Future<void> flush() => _loop ?? Future.value();

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _pending.clear();
  }

  Future<void> _kick() => _loop ??= _run();

  Future<void> _run() async {
    await null; // never complete synchronously (see `_loop = null` below)
    try {
      while (_pending.isNotEmpty && !_disposed && _strings != null) {
        final batch = List.of(_pending);
        _pending.clear();
        try {
          await _once(_representative(batch), _strings!);
        } catch (error, stack) {
          onError?.call(error, stack);
        }
      }
    } finally {
      _loop = null;
    }
  }

  /// The trigger that stands for [batch]: one that reloads the timelines
  /// beats one that does not.
  static WidgetSyncTrigger _representative(List<WidgetSyncTrigger> batch) =>
      batch.firstWhere(
        (t) => t.alwaysReloadsTimelines,
        orElse: () => batch.last,
      );

  Future<void> _once(WidgetSyncTrigger trigger, WidgetStrings strings) async {
    final snapshot = await buildSnapshot(strings);
    if (_disposed) return;
    runs++;
    lastPlan = await syncWidget(
      publisher: publisher,
      trigger: trigger,
      build: () => snapshot,
    );
  }
}
