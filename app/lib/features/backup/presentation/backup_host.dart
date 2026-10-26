import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router.dart';
import '../application/backup_models.dart';
import '../application/backup_providers.dart';
import '../data/platform_backup_channel.dart';

/// Keeps the automatic copies running for the whole life of the app and opens
/// the preview when another app hands Cuadrante a `.cuadrante` (WhatsApp,
/// Files, Drive). Shows nothing; it only wraps [child].
///
/// A file that arrives is never restored by itself: it goes to the preview
/// screen, where the user decides. During the first-use flow it waits and
/// opens when the flow ends.
class BackupHost extends ConsumerStatefulWidget {
  const BackupHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BackupHost> createState() => _BackupHostState();
}

class _BackupHostState extends ConsumerState<BackupHost> {
  late final PlatformBackupChannel _channel;
  late final GoRouter _router;
  bool _pushing = false;

  /// A file arrived during the first-use flow: it stays pending (on the
  /// platform side) and opens as soon as that flow is left.
  bool _waitingForOnboarding = false;

  @override
  void initState() {
    super.initState();
    _channel = ref.read(platformBackupChannelProvider);
    _router = ref.read(routerProvider);
    _router.routerDelegate.addListener(_routeChanged);
    // A file that arrives while the app is open.
    _channel.onIncomingFile(_openIncoming);
    // Exports left in the cache by an earlier session are removed.
    ref.read(exportCacheSweepProvider);
    // The file the app was started with, once the router is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openIncoming());
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_routeChanged);
    _channel.onIncomingFile(null);
    super.dispose();
  }

  /// The first-use flow is the screen on top right now.
  bool get _onboardingOnTop {
    final matches = _router.routerDelegate.currentConfiguration;
    return matches.isNotEmpty &&
        matches.last.matchedLocation == AppRoutes.onboarding;
  }

  void _routeChanged() {
    if (!_waitingForOnboarding || _onboardingOnTop) return;
    _waitingForOnboarding = false;
    unawaited(_openIncoming());
  }

  /// Whether the preview of a file is the screen on top right now (or is
  /// about to be: [_pushing]).
  bool get _previewOnTop {
    if (_pushing) return true;
    final matches = ref
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration;
    return matches.isNotEmpty &&
        matches.last.matchedLocation == AppRoutes.settingsBackupImport;
  }

  /// A file arrived. The preview opens at once, with "Leyendo el archivo..."
  /// and Back available while the platform reads it (a file on Drive can be
  /// slow, or never come): nothing waits on the bytes here.
  ///
  /// Never more than one preview: if one is already on top, the new file
  /// replaces it (the newest file is what the user just opened), unless a
  /// restore is replacing the data right now, in which case the new file is
  /// dropped. Repeated intents therefore cannot stack screens.
  Future<void> _openIncoming() async {
    if (!mounted || !await _channel.hasIncomingFile() || !mounted) return;
    // Not over the first-use flow: restoring there would be overwritten by
    // the choices the person goes on to make. The file stays pending and
    // opens once the flow has ended.
    if (_onboardingOnTop) {
      _waitingForOnboarding = true;
      return;
    }
    final router = ref.read(routerProvider);
    final request = BackupImportRequest(
      origin: BackupImportOrigin.sharedFile,
      load: () async =>
          await _channel.takeIncomingFile() ??
          const IncomingFile.problem(IncomingFileProblem.unreadable),
    );
    if (!_previewOnTop) {
      _pushing = true;
      // The route is registered a frame later: until then it counts as on top.
      WidgetsBinding.instance.addPostFrameCallback((_) => _pushing = false);
      unawaited(
        router.push<void>(AppRoutes.settingsBackupImport, extra: request),
      );
      return;
    }
    if (ref.read(restoreInProgressProvider)) {
      await _channel.discardIncomingFile();
      return;
    }
    unawaited(
      router.pushReplacement<void>(
        AppRoutes.settingsBackupImport,
        extra: request,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watching the runner is what starts it (and keeps it alive).
    ref.listen(autoBackupRunnerProvider, (previous, next) {});
    return widget.child;
  }
}
