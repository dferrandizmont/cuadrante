import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../domain/backup_codec.dart';

/// Why a file handed to the app by the system (WhatsApp, Files, Drive...)
/// could not be read.
enum IncomingFileProblem {
  /// Larger than `BackupCodec.maxFileBytes`: not a backup.
  tooLarge,

  /// The system refused to give the bytes (permission, a provider that went
  /// away, no network for a Drive file).
  unreadable,
}

/// A `.cuadrante` the system opened with Cuadrante: either its [bytes] or the
/// [problem] that stopped them being read.
class IncomingFile {
  const IncomingFile.bytes(Uint8List this.bytes, {this.sender})
    : problem = null;
  const IncomingFile.problem(IncomingFileProblem this.problem)
    : bytes = null,
      sender = null;

  final Uint8List? bytes;
  final IncomingFileProblem? problem;

  /// Who handed the file over, as the system reports it ("WhatsApp
  /// (com.whatsapp)" or just a package name), or `null` when it does not say
  /// (a file picked in the app, a copy of the phone). Informational only: it
  /// is shown in the preview and decides nothing.
  final String? sender;
}

/// Whether the phone's own backup (Android Auto Backup) is on, as far as the
/// app can tell. The app cannot ask for sure on every phone, so [unknown] is
/// an honest answer, shown as such.
enum SystemBackupState {
  on,
  off,
  unknown,

  /// This platform has no system backup the app can speak about (desktop
  /// tests, and iOS, whose iCloud state is told by `ICloudBackupStore`): the
  /// line is not shown.
  notApplicable,
}

/// The small bridge to the platform (docs/copia-de-seguridad.md, "Abrir un
/// .cuadrante desde otra app"). Tests and desktop use [NoPlatformBackupChannel].
abstract interface class PlatformBackupChannel {
  /// Whether the system handed the app a file that nobody has taken yet.
  /// Instant: it does not read the file, so the screen can open at once and
  /// show "Leyendo el archivo..." while [takeIncomingFile] works.
  Future<bool> hasIncomingFile();

  /// The file the system opened the app with, once (`null` when there is
  /// none). Reading it happens off the main thread on the Android side, with
  /// a deadline: a file that does not arrive in time is `unreadable`.
  Future<IncomingFile?> takeIncomingFile();

  /// Forgets the pending file without reading it (the app is busy and does
  /// not take it).
  Future<void> discardIncomingFile();

  /// Called whenever a new file arrives while the app is already running.
  void onIncomingFile(void Function()? listener);

  Future<SystemBackupState> systemBackupState();

  /// Turns the tapjacking guard of the restore preview on or off: while on,
  /// touches that reach the app through another app's overlay are dropped and
  /// (Android 12+) other apps' overlay windows are hidden.
  Future<void> setPreviewProtection({required bool enabled});
}

/// Reference-counted tapjacking guard of the restore preview.
///
/// Two previews can overlap for a moment: `pushReplacement` builds the new
/// screen (initState) before the old one is disposed. With a plain on/off per
/// screen the old dispose would switch the guard off under the new preview.
/// Every preview [acquire]s the guard while it lives and [release]s it when it
/// goes; the platform hears `true` on the first acquire and `false` on the last
/// release, nothing in between.
class PreviewProtectionGuard {
  PreviewProtectionGuard(this._channel);

  final PlatformBackupChannel _channel;
  int _holders = 0;

  /// Previews holding the guard right now.
  int get holders => _holders;

  void acquire() {
    _holders++;
    if (_holders == 1) {
      unawaited(_channel.setPreviewProtection(enabled: true));
    }
  }

  void release() {
    if (_holders == 0) return;
    _holders--;
    if (_holders == 0) {
      unawaited(_channel.setPreviewProtection(enabled: false));
    }
  }
}

/// Nothing arrives and the system backup cannot be known.
class NoPlatformBackupChannel implements PlatformBackupChannel {
  const NoPlatformBackupChannel();

  @override
  Future<bool> hasIncomingFile() async => false;

  @override
  Future<void> discardIncomingFile() async {}

  @override
  Future<IncomingFile?> takeIncomingFile() async => null;

  @override
  void onIncomingFile(void Function()? listener) {}

  @override
  Future<SystemBackupState> systemBackupState() async =>
      SystemBackupState.notApplicable;

  @override
  Future<void> setPreviewProtection({required bool enabled}) async {}
}

/// The `MethodChannel` implementation: `MainActivity` on Android, the Swift
/// side (`AppDelegate` / `SceneDelegate`) on iOS. Same name, same methods.
///
/// - `hasPending` -> `bool`: there is a content URI of a VIEW / SEND intent
///   that nobody has taken yet. Does not read anything.
/// - `discardPending`: forgets it.
/// - `readPending` -> `null` | `{bytes: Uint8List, sender: String?}` | `{error: String}`: the
///   content URI of the VIEW / SEND intent that opened the app, read in
///   chunks with a hard cap of `BackupCodec.maxFileBytes` and a 60 s
///   deadline (`{error: "unreadable"}` past it).
/// - `incomingAvailable` (Android -> Dart): a new intent arrived.
/// - `systemBackupState` -> `"on"` | `"off"` | `"unknown"` (Android only).
/// - `setPreviewProtection(bool)`: tapjacking guard of the restore preview
///   (Android only).
///
/// On iOS only `hasPending`, `readPending`, `discardPending` and
/// `incomingAvailable` exist (docs/copia-de-seguridad.md, "Abrir un .cuadrante
/// desde otra app (iOS)"). A method the native side does not implement, or no
/// native side at all, comes back as `MissingPluginException` and is handled
/// like "nothing to do".
class MethodChannelBackupChannel implements PlatformBackupChannel {
  /// [reportsSystemBackup] is `false` on iOS: the state of the system backup
  /// is only told for Android (its line says "Copia del sistema de Android");
  /// the state of iCloud has its own place (`ICloudBackupStore.status`).
  MethodChannelBackupChannel([
    MethodChannel? channel,
    this.reportsSystemBackup = true,
  ]) : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'app.cuadrante/backup';

  final MethodChannel _channel;
  final bool reportsSystemBackup;

  @override
  Future<bool> hasIncomingFile() async {
    try {
      return await _channel.invokeMethod<bool>('hasPending') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> discardIncomingFile() async {
    try {
      await _channel.invokeMethod<void>('discardPending');
    } on MissingPluginException {
      // Nothing to forget.
    } on PlatformException {
      // Same.
    }
  }

  @override
  Future<IncomingFile?> takeIncomingFile() async {
    try {
      final reply = await _channel.invokeMethod<Map<Object?, Object?>>(
        'readPending',
      );
      if (reply == null) return null;
      final bytes = reply['bytes'];
      if (bytes is Uint8List) {
        // The native side caps the read, but it is not trusted: a reply over
        // the cap is not a backup and never reaches the decoder.
        if (bytes.length > BackupCodec.maxFileBytes) {
          return const IncomingFile.problem(IncomingFileProblem.tooLarge);
        }
        final sender = reply['sender'];
        return IncomingFile.bytes(
          bytes,
          sender: sender is String && sender.isNotEmpty ? sender : null,
        );
      }
      return IncomingFile.problem(
        reply['error'] == 'tooLarge'
            ? IncomingFileProblem.tooLarge
            : IncomingFileProblem.unreadable,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return const IncomingFile.problem(IncomingFileProblem.unreadable);
    }
  }

  @override
  void onIncomingFile(void Function()? listener) {
    _channel.setMethodCallHandler(
      listener == null
          ? null
          : (call) async {
              if (call.method == 'incomingAvailable') listener();
              return null;
            },
    );
  }

  @override
  Future<void> setPreviewProtection({required bool enabled}) async {
    try {
      await _channel.invokeMethod<void>('setPreviewProtection', enabled);
    } on MissingPluginException {
      // No platform side (tests, desktop).
    } on PlatformException {
      // The guard is best effort; the preview works without it.
    }
  }

  @override
  Future<SystemBackupState> systemBackupState() async {
    if (!reportsSystemBackup) return SystemBackupState.notApplicable;
    try {
      return switch (await _channel.invokeMethod<String>('systemBackupState')) {
        'on' => SystemBackupState.on,
        'off' => SystemBackupState.off,
        _ => SystemBackupState.unknown,
      };
    } on MissingPluginException {
      return SystemBackupState.unknown;
    } on PlatformException {
      return SystemBackupState.unknown;
    }
  }
}

/// What came of «Guardar en el móvil».
enum BackupSaveOutcome {
  /// The file is where the user chose.
  saved,

  /// The user closed the save dialog: nothing was written.
  cancelled,
}

/// Opens the system's save dialog (Android: `ACTION_CREATE_DOCUMENT`) and
/// writes [bytes] to the place the user picks, suggesting [fileName]. Throws
/// when the dialog cannot open or the place refuses the file.
Future<BackupSaveOutcome> saveWithSystemDialog(
  Uint8List bytes,
  String fileName, [
  MethodChannel? channel,
]) async {
  final reply =
      await (channel ??
              const MethodChannel(MethodChannelBackupChannel.channelName))
          .invokeMethod<String>('saveDocument', {
            'fileName': fileName,
            'bytes': bytes,
          });
  return reply == 'saved'
      ? BackupSaveOutcome.saved
      : BackupSaveOutcome.cancelled;
}

/// The channel of this platform: the real one on Android and iOS, nothing on
/// desktop and in tests. [isAndroid] and [isIOS] are for tests.
///
/// On iOS the channel exists in Dart, but until the Swift side registers it
/// (Mac phase) every call finds no plugin and behaves as "no file arrived".
PlatformBackupChannel defaultPlatformBackupChannel({
  bool? isAndroid,
  bool? isIOS,
}) {
  if (isAndroid ?? Platform.isAndroid) return MethodChannelBackupChannel();
  if (isIOS ?? Platform.isIOS) {
    return MethodChannelBackupChannel(null, false);
  }
  return const NoPlatformBackupChannel();
}
