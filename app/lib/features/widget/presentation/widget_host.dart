import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router.dart';
import '../../backup/application/backup_providers.dart'
    show restoreInProgressProvider;
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/application/visible_month.dart';
import '../../calendar/presentation/day_detail_sheet.dart';
import '../../alarms/application/alarm_providers.dart' show alarmSystemProvider;
import '../../alarms/data/alarm_system.dart' show ClockChange;
import '../../calendars/application/calendars_controller.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/application/preferences_controller.dart';
import '../application/widget_providers.dart';
import '../domain/widget_links.dart';
import '../domain/widget_strings.dart';
import '../domain/widget_sync_planner.dart';

/// Keeps the home-screen widgets in step with the app. Mounted once above the
/// router (`MaterialApp.builder`), shows nothing and only wraps [child].
///
/// It republishes the snapshot (`docs/widget-contrato.md`, section 5):
/// - at start and when the app comes back to the foreground;
/// - after any change of the schedule, the holidays, the preferences or the
///   primary calendar (debounced by the planner);
/// - at the next local midnight while the app is running, when the device
///   date changes under it, and when the time zone changes (both found by a
///   once-a-minute look at the clock, because Flutter has no notification).
///
/// With the app closed it does nothing: the Android widgets pick the right
/// day from the snapshot by themselves (`WidgetDayLogic.kt`).
///
/// It also opens the day a widget tap names.
class WidgetHost extends ConsumerStatefulWidget {
  const WidgetHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<WidgetHost> createState() => _WidgetHostState();
}

class _WidgetHostState extends ConsumerState<WidgetHost> {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<Uri?>? _taps;
  StreamSubscription<ClockChange>? _clockChanges;
  Timer? _midnight;
  Timer? _watch;
  bool _started = false;
  String? _locale;

  // What the minute watch compares the clock with.
  late CivilDate _seenDay;
  late String _seenZone;
  late Duration _seenOffset;

  /// How often the clock is checked for a changed date or zone.
  static const Duration watchEvery = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    final now = ref.read(clockProvider)();
    _remember(now);
    // Android tells us at once when the zone or the time changes under the
    // running app (the minute watch below stays as the fallback and for
    // hosts that cannot say).
    _clockChanges = ref
        .read(alarmSystemProvider)
        .clockChanges
        .listen(_onClockChanged);
  }

  /// A notice from the system: the zone or the time changed.
  void _onClockChanged(ClockChange change) {
    if (!mounted) return;
    _remember(ref.read(clockProvider)());
    ref
        .read(widgetSyncProvider)
        .request(
          change == ClockChange.timezone
              ? WidgetSyncTrigger.timeZoneChanged
              : WidgetSyncTrigger.dayChanged,
        );
    _armTimers();
  }

  void _remember(DateTime now) {
    _seenDay = CivilDate.fromDateTime(now);
    _seenZone = now.timeZoneName;
    _seenOffset = now.timeZoneOffset;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;
    final sync = ref.read(widgetSyncProvider);
    sync.strings = WidgetStrings.fromL10n(l10n);
    if (!_started) {
      _started = true;
      sync.request(WidgetSyncTrigger.appStart);
      _armTimers();
      unawaited(_listenToTaps());
    } else if (_locale != l10n.localeName) {
      sync.request(WidgetSyncTrigger.localeChanged);
    }
    _locale = l10n.localeName;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _midnight?.cancel();
    _watch?.cancel();
    unawaited(_taps?.cancel());
    unawaited(_clockChanges?.cancel());
    super.dispose();
  }

  // ---- Triggers -----------------------------------------------------------

  void _onResume() {
    _remember(ref.read(clockProvider)());
    ref.read(widgetSyncProvider).request(WidgetSyncTrigger.appResumed);
    _armTimers();
  }

  void _armTimers() {
    _midnight?.cancel();
    final now = ref.read(clockProvider)();
    _midnight = Timer(WidgetSyncPlanner.untilNextDay(now), _onMidnight);
    _watch ??= Timer.periodic(watchEvery, (_) => _lookAtClock());
  }

  void _onMidnight() {
    final now = ref.read(clockProvider)();
    _remember(now);
    ref.read(widgetSyncProvider).request(WidgetSyncTrigger.dayChanged);
    _armTimers();
  }

  /// Raises [WidgetSyncTrigger.timeZoneChanged] or
  /// [WidgetSyncTrigger.dayChanged] when the device clock moved under the
  /// app: a new zone (by name or UTC offset) or another civil date than the
  /// one last seen (date set by hand, or a midnight timer that fired late).
  void _lookAtClock() {
    if (!mounted) return;
    final now = ref.read(clockProvider)();
    final sync = ref.read(widgetSyncProvider);
    final zoneChanged =
        now.timeZoneName != _seenZone || now.timeZoneOffset != _seenOffset;
    final dayChanged = CivilDate.fromDateTime(now) != _seenDay;
    if (!zoneChanged && !dayChanged) return;
    _remember(now);
    sync.request(
      zoneChanged
          ? WidgetSyncTrigger.timeZoneChanged
          : WidgetSyncTrigger.dayChanged,
    );
    _armTimers();
  }

  // ---- Taps ---------------------------------------------------------------

  Future<void> _listenToTaps() async {
    final publisher = ref.read(widgetPublisherProvider);
    try {
      _taps = publisher.taps.listen(_open);
      _open(await publisher.launchedFrom());
    } catch (_) {
      // No widget plugin on this host: nothing to open.
    }
  }

  /// Opens what a widget tap names (see [widgetLinkTarget]). Anything else is
  /// ignored: the links can come from any app.
  void _open(Uri? uri) {
    if (!mounted) return;
    final target = widgetLinkTarget(
      uri,
      today: CivilDate.fromDateTime(ref.read(clockProvider)()),
    );
    if (target == null) return;
    final router = ref.read(routerProvider);
    // The matched location of the top route: a pushed screen (the restore
    // preview) is not in the route information.
    final matches = router.routerDelegate.currentConfiguration;
    final here = matches.isEmpty
        ? router.routeInformationProvider.value.uri.path
        : matches.last.matchedLocation;
    // First use is not interrupted by a tap on a widget left from before.
    if (here == AppRoutes.onboarding) return;
    // Nor is the restore preview, or a restore that is replacing the data:
    // leaving them could drop the confirmation the user is about to give.
    if (here == AppRoutes.settingsBackupImport ||
        ref.read(restoreInProgressProvider)) {
      return;
    }
    // A day sheet (or any other sheet) that is open is closed first: the new
    // day replaces it, they never stack.
    rootNavigatorKey.currentState?.popUntil((route) => route is PageRoute);
    router.go(AppRoutes.home);
    final month = target.month;
    if (month != null) {
      ref.read(visibleMonthProvider.notifier).goTo(month);
      return;
    }
    final day = target.day;
    if (day == null) return;
    ref.read(visibleMonthProvider.notifier).goTo(day);
    unawaited(_showDayAfterNavigation(day));
  }

  /// `go` rebuilds the stack on the next frame(s): a sheet pushed before that
  /// would sit above the page that go_router is about to remove. Waits for
  /// the navigation to settle (home on top), then opens the day.
  Future<void> _showDayAfterNavigation(CivilDate day) async {
    for (var frame = 0; frame < 10; frame++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final matches = ref
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration;
      if (matches.isNotEmpty &&
          matches.last.matchedLocation == AppRoutes.home) {
        break;
      }
    }
    // One more frame so the replaced page is gone before the sheet goes on.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _showDay(day, 0);
  }

  /// The sheet needs the navigator's overlay, which does not exist yet on a
  /// cold start from the widget: try again for a couple of seconds.
  void _showDay(CivilDate day, int attempt) {
    if (!mounted) return;
    final context = rootNavigatorKey.currentState?.overlay?.context;
    if (context != null && context.mounted) {
      unawaited(openDayOnMonth(context, ref, date: day));
      return;
    }
    if (attempt < 20) {
      Timer(
        const Duration(milliseconds: 100),
        () => _showDay(day, attempt + 1),
      );
    }
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final sync = ref.read(widgetSyncProvider);
    ref.listen(scheduleControllerProvider, (previous, next) {
      // Only a different schedule matters (not undo/redo availability).
      if (!identical(previous?.schedule, next.schedule)) {
        sync.request(WidgetSyncTrigger.scheduleChanged);
      }
    });
    ref.listen(holidaysProvider, (previous, next) {
      if (!identical(previous, next)) {
        sync.request(WidgetSyncTrigger.holidaysChanged);
      }
    });
    ref.listen(preferencesProvider, (previous, next) {
      if (previous != next) sync.request(WidgetSyncTrigger.scheduleChanged);
    });
    ref.listen(calendarsControllerProvider.select((s) => s.value?.primaryId), (
      previous,
      next,
    ) {
      // A different primary calendar: the widget follows another schedule.
      if (previous != null && previous != next) {
        sync.request(WidgetSyncTrigger.scheduleChanged);
      }
    });
    return widget.child;
  }
}
