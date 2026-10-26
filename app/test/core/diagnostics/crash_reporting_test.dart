import 'dart:ui';

import 'package:cuadrante/core/diagnostics/crash_reporting.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder implements CrashReporter {
  final List<Object> errors = [];
  final List<bool> fatal = [];
  bool? enabled;

  @override
  Future<void> setEnabled(bool enabled) async => this.enabled = enabled;

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async {
    errors.add(error);
    this.fatal.add(fatal);
  }
}

void main() {
  const secret = 'Nota privada: baja por depresion';

  group('RedactingCrashReporter', () {
    test(
      'only the runtime type reaches the backend, never the message',
      () async {
        final inner = _Recorder();
        final reporter = RedactingCrashReporter(inner);

        await reporter.record(
          const FormatException(secret),
          StackTrace.current,
          fatal: false,
        );
        await reporter.record(StateError(secret), null, fatal: true);
        await reporter.record(secret, null, fatal: false);

        expect(inner.errors.every((e) => e is RedactedError), isTrue);
        expect(inner.errors.map((e) => '$e'), [
          'FormatException',
          'StateError',
          'String',
        ]);
        expect(inner.errors.join(' '), isNot(contains('privada')));
        expect(inner.fatal, [false, true, false]);
      },
    );

    test('an already redacted error passes unchanged', () async {
      final inner = _Recorder();
      const redacted = RedactedError('RangeError');
      await RedactingCrashReporter(inner).record(redacted, null, fatal: false);
      expect(inner.errors.single, same(redacted));
    });

    test('setEnabled is forwarded', () async {
      final inner = _Recorder();
      await RedactingCrashReporter(inner).setEnabled(true);
      expect(inner.enabled, isTrue);
    });

    test('the app-wide provider redacts by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(crashReporterProvider),
        isA<RedactingCrashReporter>(),
      );
    });
  });

  group('installCrashReporting', () {
    late FlutterExceptionHandler? savedFlutter;
    late ErrorCallback? savedPlatform;

    setUp(() {
      savedFlutter = FlutterError.onError;
      savedPlatform = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = savedFlutter;
      PlatformDispatcher.instance.onError = savedPlatform;
    });

    test('the global handlers hand the backend a redacted error even when '
        'given a bare reporter', () async {
      final inner = _Recorder();
      var chained = false;
      FlutterError.onError = (_) => chained = true;
      await installCrashReporting(inner, enabled: true, release: true);

      FlutterError.onError!(
        FlutterErrorDetails(exception: const FormatException(secret)),
      );
      PlatformDispatcher.instance.onError!(
        StateError(secret),
        StackTrace.empty,
      );
      await Future<void>.delayed(Duration.zero);

      // The default handler (which prints the message to logcat) is not
      // chained in release.
      expect(chained, isFalse);
      expect(inner.enabled, isTrue);
      expect(inner.errors, hasLength(2));
      expect(inner.errors.every((e) => e is RedactedError), isTrue);
      expect(inner.errors.join(' '), isNot(contains('privada')));
    });
  });
}
