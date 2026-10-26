import 'dart:isolate';

/// Tasks carry only plain data, never database/provider/widget instances.
typedef BackupTaskRunner = Future<R> Function<R>(R Function() task);

Future<R> runInBackgroundIsolate<R>(R Function() task) => Isolate.run(task);

/// Fake-clock widget tests can run processing synchronously.
Future<R> runOnThisIsolate<R>(R Function() task) async => task();
