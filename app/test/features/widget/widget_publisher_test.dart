import 'dart:async';

import 'package:cuadrante/features/widget/data/widget_publisher.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands for the `home_widget` plugin: records every call in order.
class FakeHomeWidgetLayer implements HomeWidgetLayer {
  final List<String> calls = [];
  final Map<String, String> store = {};
  bool failSave = false;
  bool failUpdate = false;
  bool pinSupported = true;
  final StreamController<Uri?> clicksController =
      StreamController<Uri?>.broadcast();
  Uri? launch;

  @override
  Future<void> saveString(String key, String? value) async {
    calls.add('save:$key');
    if (failSave) throw Exception('disk full');
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<String?> readString(String key) async => store[key];

  @override
  Future<void> setAppGroupId(String id) async => calls.add('group:$id');

  @override
  Future<void> updateAndroid(String qualifiedName) async {
    calls.add('android:$qualifiedName');
    if (failUpdate) throw Exception('no such widget');
  }

  @override
  Future<void> updateIos(String kind) async => calls.add('ios:$kind');

  @override
  Future<bool> isPinSupported() async => pinSupported;

  @override
  Future<void> requestPin(String qualifiedName) async =>
      calls.add('pin:$qualifiedName');

  @override
  Stream<Uri?> get clicks => clicksController.stream;

  @override
  Future<Uri?> initiallyLaunchedFrom() async => launch;
}

void main() {
  group('Android', () {
    late FakeHomeWidgetLayer layer;
    late HomeWidgetPublisher publisher;

    setUp(() {
      layer = FakeHomeWidgetLayer();
      publisher = HomeWidgetPublisher(layer: layer, ios: false);
    });

    test('publish stores the JSON under the snapshot key, then redraws the '
        'five providers', () async {
      await publisher.publish('{"v":1}');
      expect(layer.store[kWidgetSnapshotKey], '{"v":1}');
      expect(layer.calls, [
        'save:$kWidgetSnapshotKey',
        'android:es.cuadrante.app.widget.CuadranteSmallWidgetProvider',
        'android:es.cuadrante.app.widget.CuadranteMediumWidgetProvider',
        'android:es.cuadrante.app.widget.CuadranteLargeWidgetProvider',
        'android:es.cuadrante.app.widget.CuadranteAgendaWidgetProvider',
        'android:es.cuadrante.app.widget.CuadranteTwoWeeksWidgetProvider',
      ]);
      expect(await publisher.readPublished(), '{"v":1}');
    });

    test('a failed save does not redraw anything', () async {
      layer.failSave = true;
      await publisher.publish('{"v":1}');
      expect(layer.calls, ['save:$kWidgetSnapshotKey']);
    });

    test('failing providers do not stop the remaining updates', () async {
      layer.failUpdate = true;
      await publisher.publish('{"v":1}');
      expect(layer.calls.where((c) => c.startsWith('android:')), hasLength(5));
    });

    test('reloadTimelines redraws without storing', () async {
      await publisher.reloadTimelines();
      expect(layer.calls.where((c) => c.startsWith('save:')), isEmpty);
      expect(layer.calls.where((c) => c.startsWith('android:')), hasLength(5));
    });

    test('clear removes the snapshot and redraws', () async {
      await publisher.publish('{"v":1}');
      layer.calls.clear();
      await publisher.clear();
      expect(layer.store, isEmpty);
      expect(await publisher.readPublished(), isNull);
      expect(layer.calls.first, 'save:$kWidgetSnapshotKey');
      expect(layer.calls.where((c) => c.startsWith('android:')), hasLength(5));
    });

    test('pinning asks the launcher for the provider of that size', () async {
      expect(await publisher.canPin(), isTrue);
      await publisher.requestPin(WidgetSize.small);
      await publisher.requestPin(WidgetSize.medium);
      await publisher.requestPin(WidgetSize.large);
      await publisher.requestPin(WidgetSize.agenda);
      await publisher.requestPin(WidgetSize.twoWeeks);
      expect(layer.calls, [
        'pin:es.cuadrante.app.widget.CuadranteSmallWidgetProvider',
        'pin:es.cuadrante.app.widget.CuadranteMediumWidgetProvider',
        'pin:es.cuadrante.app.widget.CuadranteLargeWidgetProvider',
        'pin:es.cuadrante.app.widget.CuadranteAgendaWidgetProvider',
        'pin:es.cuadrante.app.widget.CuadranteTwoWeeksWidgetProvider',
      ]);
      layer.pinSupported = false;
      expect(await publisher.canPin(), isFalse);
    });

    test('taps and the launch link come from the plugin', () async {
      layer.launch = Uri.parse('cuadrante://widget/day/2026-10-19');
      expect(await publisher.launchedFrom(), layer.launch);
      final taps = <Uri?>[];
      final sub = publisher.taps.listen(taps.add);
      layer.clicksController.add(
        Uri.parse('cuadrante://widget/day/2026-10-20'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(taps.single.toString(), 'cuadrante://widget/day/2026-10-20');
      await sub.cancel();
    });
  });

  group('iOS', () {
    test('uses the App Group and the iOS kind, and never pins', () async {
      final layer = FakeHomeWidgetLayer();
      final publisher = HomeWidgetPublisher(layer: layer, ios: true);
      await publisher.publish('{"v":1}');
      expect(layer.calls, [
        'group:$kWidgetAppGroupId',
        'save:$kWidgetSnapshotKey',
        'ios:$kWidgetIosKind',
      ]);
      expect(await publisher.canPin(), isFalse);
      await publisher.requestPin(WidgetSize.small);
      expect(layer.calls.where((c) => c.startsWith('pin:')), isEmpty);
    });
  });

  test('the provider names are the Kotlin class names', () {
    // Renaming a provider orphans the widgets already on a home screen.
    expect(
      kWidgetSmallProvider,
      endsWith('.widget.CuadranteSmallWidgetProvider'),
    );
    expect(
      kWidgetMediumProvider,
      endsWith('.widget.CuadranteMediumWidgetProvider'),
    );
    expect(WidgetSize.small.androidProvider, kWidgetSmallProvider);
    expect(
      kWidgetLargeProvider,
      endsWith('.widget.CuadranteLargeWidgetProvider'),
    );
    expect(WidgetSize.medium.androidProvider, kWidgetMediumProvider);
    expect(WidgetSize.large.androidProvider, kWidgetLargeProvider);
    expect(
      kWidgetAgendaProvider,
      endsWith('.widget.CuadranteAgendaWidgetProvider'),
    );
    expect(
      kWidgetTwoWeeksProvider,
      endsWith('.widget.CuadranteTwoWeeksWidgetProvider'),
    );
    expect(WidgetSize.agenda.androidProvider, kWidgetAgendaProvider);
    expect(WidgetSize.twoWeeks.androidProvider, kWidgetTwoWeeksProvider);
    // Every size has its provider in the list the snapshot feeds.
    expect(kWidgetProviders, [
      for (final size in WidgetSize.values) size.androidProvider,
    ]);
  });
}
