import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/widget_snapshot.dart';

/// Qualified class names of the Android widget providers
/// (`android/app/src/main/kotlin/app/cuadrante/cuadrante/widget/`). They are
/// part of the contract: placed widgets survive updates only while the names
/// stay.
const String kWidgetSmallProvider =
    'app.cuadrante.cuadrante.widget.CuadranteSmallWidgetProvider';
const String kWidgetMediumProvider =
    'app.cuadrante.cuadrante.widget.CuadranteMediumWidgetProvider';
const String kWidgetLargeProvider =
    'app.cuadrante.cuadrante.widget.CuadranteLargeWidgetProvider';
const String kWidgetAgendaProvider =
    'app.cuadrante.cuadrante.widget.CuadranteAgendaWidgetProvider';
const String kWidgetTwoWeeksProvider =
    'app.cuadrante.cuadrante.widget.CuadranteTwoWeeksWidgetProvider';

/// Every Android provider the snapshot feeds.
const List<String> kWidgetProviders = [
  kWidgetSmallProvider,
  kWidgetMediumProvider,
  kWidgetLargeProvider,
  kWidgetAgendaProvider,
  kWidgetTwoWeeksProvider,
];

/// The widget sizes the app can ask the launcher to pin.
enum WidgetSize {
  /// 2x2 (Android) / systemSmall (iOS): today and tomorrow.
  small,

  /// 4x2 (Android) / systemMedium (iOS): the next seven days.
  medium,

  /// 4x4 (Android) / systemLarge (iOS): the month grid.
  large,

  /// 4x2 (Android): upcoming shifts as an agenda.
  agenda,

  /// 4x2 (Android): the current and next weeks in two rows, from Monday.
  twoWeeks;

  /// The Android provider of this size.
  String get androidProvider => switch (this) {
    small => kWidgetSmallProvider,
    medium => kWidgetMediumProvider,
    large => kWidgetLargeProvider,
    agenda => kWidgetAgendaProvider,
    twoWeeks => kWidgetTwoWeeksProvider,
  };
}

/// Hands the snapshot to the platform widgets (iOS App Group
/// `group.app.cuadrante`, Android `HomeWidgetPreferences`). Everything is best
/// effort: a host without widgets must never break the app.
abstract class WidgetPublisher {
  /// Stores [snapshotJson] under [kWidgetSnapshotKey] and reloads the widgets'
  /// timelines.
  Future<void> publish(String snapshotJson);

  /// Reloads the timelines without touching the stored snapshot.
  Future<void> reloadTimelines();

  /// The JSON currently stored, or null when none.
  Future<String?> readPublished();

  /// Removes the stored snapshot (the widgets then show their "open the app"
  /// state) and reloads the timelines.
  Future<void> clear();

  /// Whether the launcher can pin a widget from inside the app (Android 8+
  /// with a launcher that supports it; never on iOS).
  Future<bool> canPin();

  /// Asks the launcher to pin a widget of [size]; the system shows its own
  /// confirmation. Does nothing where [canPin] is false.
  Future<void> requestPin(WidgetSize size);

  /// Links of the widget taps that arrive while the app is running.
  Stream<Uri?> get taps;

  /// The link of the tap that started the app, or null when it was not
  /// started from a widget.
  Future<Uri?> launchedFrom();
}

/// The few `home_widget` calls the publisher needs, so that tests can stand in
/// for the plugin (the real one needs a platform channel).
abstract class HomeWidgetLayer {
  Future<void> saveString(String key, String? value);
  Future<String?> readString(String key);
  Future<void> setAppGroupId(String id);
  Future<void> updateAndroid(String qualifiedName);
  Future<void> updateIos(String kind);
  Future<bool> isPinSupported();
  Future<void> requestPin(String qualifiedName);
  Stream<Uri?> get clicks;
  Future<Uri?> initiallyLaunchedFrom();
}

/// [HomeWidgetLayer] on top of the `home_widget` plugin.
class PluginHomeWidgetLayer implements HomeWidgetLayer {
  const PluginHomeWidgetLayer();

  @override
  Future<void> saveString(String key, String? value) async {
    await HomeWidget.saveWidgetData<String>(key, value);
  }

  @override
  Future<String?> readString(String key) =>
      HomeWidget.getWidgetData<String>(key);

  @override
  Future<void> setAppGroupId(String id) => HomeWidget.setAppGroupId(id);

  @override
  Future<void> updateAndroid(String qualifiedName) =>
      HomeWidget.updateWidget(qualifiedAndroidName: qualifiedName);

  @override
  Future<void> updateIos(String kind) => HomeWidget.updateWidget(iOSName: kind);

  @override
  Future<bool> isPinSupported() async =>
      await HomeWidget.isRequestPinWidgetSupported() ?? false;

  @override
  Future<void> requestPin(String qualifiedName) =>
      HomeWidget.requestPinWidget(qualifiedAndroidName: qualifiedName);

  @override
  Stream<Uri?> get clicks => HomeWidget.widgetClicked;

  @override
  Future<Uri?> initiallyLaunchedFrom() =>
      HomeWidget.initiallyLaunchedFromHomeWidget();
}

/// Android and iOS implementation on top of `home_widget`. On iOS the
/// extension reads the snapshot from the App Group and builds its own
/// timeline; on Android the providers re-draw on the broadcast
/// `updateWidget` sends and arm their own midnight alarm (see
/// `docs/widget-contrato.md`, "Android").
class HomeWidgetPublisher implements WidgetPublisher {
  HomeWidgetPublisher({HomeWidgetLayer? layer, bool? ios})
    : _layer = layer ?? const PluginHomeWidgetLayer(),
      _ios = ios ?? (!kIsWeb && Platform.isIOS);

  final HomeWidgetLayer _layer;
  final bool _ios;

  Future<void> _store(String? value) async {
    if (_ios) await _layer.setAppGroupId(kWidgetAppGroupId);
    await _layer.saveString(kWidgetSnapshotKey, value);
  }

  Future<void> _redraw() async {
    if (_ios) {
      try {
        await _layer.updateIos(kWidgetIosKind);
      } catch (_) {}
      return;
    }
    for (final provider in kWidgetProviders) {
      try {
        await _layer.updateAndroid(provider);
      } catch (_) {}
    }
  }

  @override
  Future<void> publish(String snapshotJson) async {
    try {
      await _store(snapshotJson);
    } catch (e) {
      // Nothing was stored, so there is nothing to redraw either.
      debugPrint('widget: could not store the snapshot ($e)');
      return;
    }
    await _redraw();
  }

  @override
  Future<void> reloadTimelines() => _redraw();

  @override
  Future<String?> readPublished() async {
    try {
      if (_ios) await _layer.setAppGroupId(kWidgetAppGroupId);
      return await _layer.readString(kWidgetSnapshotKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _store(null);
    } catch (_) {
      return;
    }
    await _redraw();
  }

  @override
  Future<bool> canPin() async {
    if (_ios) return false;
    try {
      return await _layer.isPinSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestPin(WidgetSize size) async {
    if (_ios) return;
    try {
      await _layer.requestPin(size.androidProvider);
    } catch (_) {}
  }

  @override
  Stream<Uri?> get taps {
    try {
      return _layer.clicks;
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<Uri?> launchedFrom() async {
    try {
      return await _layer.initiallyLaunchedFrom();
    } catch (_) {
      return null;
    }
  }
}

/// In-memory publisher for tests and for hosts without widgets.
class FakeWidgetPublisher implements WidgetPublisher {
  /// The stored JSON.
  String? stored;

  /// Every JSON published, oldest first.
  final List<String> published = [];

  /// Times [publish], [reloadTimelines] and [clear] reloaded the timelines.
  int reloadCount = 0;

  /// Whether [canPin] answers yes.
  bool pinSupported = false;

  /// Sizes asked to pin, in order.
  final List<WidgetSize> pinRequests = [];

  /// Feed of [taps]: tests add links here.
  final StreamController<Uri?> tapsController =
      StreamController<Uri?>.broadcast();

  /// What [launchedFrom] answers.
  Uri? launchUri;

  @override
  Future<void> publish(String snapshotJson) async {
    stored = snapshotJson;
    published.add(snapshotJson);
    reloadCount++;
  }

  @override
  Future<void> reloadTimelines() async => reloadCount++;

  @override
  Future<String?> readPublished() async => stored;

  @override
  Future<void> clear() async {
    stored = null;
    reloadCount++;
  }

  @override
  Future<bool> canPin() async => pinSupported;

  @override
  Future<void> requestPin(WidgetSize size) async => pinRequests.add(size);

  @override
  Stream<Uri?> get taps => tapsController.stream;

  @override
  Future<Uri?> launchedFrom() async => launchUri;
}
