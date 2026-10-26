/// Why the iCloud copy of a backup could not be stored, listed or read
/// (docs/copia-de-seguridad.md, "Copia en iCloud"; matrix row R8). None of
/// them touches the copies on the phone: iCloud is a second place, never the
/// only one.
sealed class ICloudException implements Exception {
  const ICloudException(this.message);

  /// Developer-facing detail. The UI maps the subtype to its own localised
  /// text.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// iCloud is not there: signed out, iCloud Drive off for the app, no
/// container, or the app has no native side for it (Android, iOS before the
/// Swift channel exists, tests).
class ICloudUnavailable extends ICloudException {
  const ICloudUnavailable() : super(userMessage);

  /// The text the screen shows for this state.
  static const String userMessage = 'iCloud no disponible';
}

/// The iCloud account is out of space.
class ICloudFull extends ICloudException {
  const ICloudFull() : super('iCloud storage is full');
}

/// iCloud did not answer in time (a file still downloading, no network).
class ICloudTimeout extends ICloudException {
  const ICloudTimeout() : super('iCloud did not answer in time');
}

/// Anything else: an unexpected answer from the native side or an error the
/// contract does not name.
class ICloudFailed extends ICloudException {
  const ICloudFailed(super.message);
}
