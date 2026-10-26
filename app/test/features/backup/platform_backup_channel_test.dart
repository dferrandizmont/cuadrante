import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Dart half of the contract with `MainActivity` (docs/copia-de-seguridad.md).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const name = MethodChannelBackupChannel.channelName;
  late MethodChannel channel;
  late MethodChannelBackupChannel platform;
  final calls = <MethodCall>[];
  Object? Function(MethodCall call) reply = (_) => null;

  setUp(() {
    calls.clear();
    reply = (_) => null;
    channel = const MethodChannel(name);
    platform = MethodChannelBackupChannel(channel);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return reply(call);
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('hasIncomingFile asks without reading', () async {
    reply = (_) => true;
    expect(await platform.hasIncomingFile(), isTrue);
    expect(calls.single.method, 'hasPending');

    reply = (_) => false;
    expect(await platform.hasIncomingFile(), isFalse);
    reply = (_) => null;
    expect(await platform.hasIncomingFile(), isFalse);
  });

  test('discardIncomingFile forgets the file', () async {
    await platform.discardIncomingFile();
    expect(calls.single.method, 'discardPending');
  });

  test('a read brings the bytes and who sent them', () async {
    reply = (_) => {
      'bytes': Uint8List.fromList([1, 2, 3]),
      'sender': 'WhatsApp (com.whatsapp)',
    };
    final file = (await platform.takeIncomingFile())!;
    expect(file.bytes, [1, 2, 3]);
    expect(file.sender, 'WhatsApp (com.whatsapp)');
    expect(file.problem, isNull);
  });

  test('no sender, or an empty one, is no sender', () async {
    reply = (_) => {'bytes': Uint8List(1)};
    expect((await platform.takeIncomingFile())!.sender, isNull);
    reply = (_) => {'bytes': Uint8List(1), 'sender': ''};
    expect((await platform.takeIncomingFile())!.sender, isNull);
  });

  test(
    'the errors of the read keep their meaning, deadline included',
    () async {
      reply = (_) => {'error': 'tooLarge'};
      expect(
        (await platform.takeIncomingFile())!.problem,
        IncomingFileProblem.tooLarge,
      );
      // The 60 s deadline of the Android side answers "unreadable".
      reply = (_) => {'error': 'unreadable'};
      expect(
        (await platform.takeIncomingFile())!.problem,
        IncomingFileProblem.unreadable,
      );
      reply = (_) => null;
      expect(await platform.takeIncomingFile(), isNull);
    },
  );

  test('bytes over the cap are tooLarge even if the native side let them '
      'through (M1)', () async {
    reply = (_) => {'bytes': Uint8List(BackupCodec.maxFileBytes + 1)};
    final file = (await platform.takeIncomingFile())!;
    expect(file.problem, IncomingFileProblem.tooLarge);
    expect(file.bytes, isNull);

    reply = (_) => {'bytes': Uint8List(BackupCodec.maxFileBytes)};
    final atTheCap = (await platform.takeIncomingFile())!;
    expect(atTheCap.problem, isNull);
    expect(atTheCap.bytes, hasLength(BackupCodec.maxFileBytes));
  });

  test('the tapjacking guard is switched with a bool', () async {
    await platform.setPreviewProtection(enabled: true);
    await platform.setPreviewProtection(enabled: false);
    expect(calls.map((c) => c.method), [
      'setPreviewProtection',
      'setPreviewProtection',
    ]);
    expect(calls.map((c) => c.arguments), [true, false]);
  });

  test('a platform without the guard is not an error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await platform.setPreviewProtection(enabled: true);
    expect(await platform.hasIncomingFile(), isFalse);
    await platform.discardIncomingFile();
  });
}
