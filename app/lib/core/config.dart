/// The support address «Ayuda y contacto» offers to copy. A build can
/// override it with `--dart-define=SUPPORT_EMAIL=...`.
const String kSupportEmail = 'dev@mainshai.com';

/// Build-time configuration, supplied with `--dart-define`.
///
/// Example: `flutter run --dart-define=USE_DEMO_DATA=false`.
class AppConfig {
  const AppConfig({
    this.showDevTools = _showDevTools,
    this.useDemoData = _useDemoData,
    this.forceOnboarding = _forceOnboarding,
    this.appVersion = _appVersion,
    this.supportEmail = _supportEmail,
    this.privacyUrl = _privacyUrl,
    this.privacyUrlEn = _privacyUrlEn,
  });

  /// The configuration of this build (the `--dart-define` values).
  static const AppConfig current = AppConfig();

  static const bool _showDevTools = bool.fromEnvironment('SHOW_DEV_TOOLS');

  /// Demo data instead of the real data (default true until the real
  /// storage exists).
  static const bool _useDemoData = bool.fromEnvironment(
    'USE_DEMO_DATA',
    defaultValue: true,
  );

  /// Shows the first-use flow even on a build with demo data or a database
  /// that has data (`--dart-define=FORCE_ONBOARDING=true`). Once the flow is
  /// done it does not come back.
  static const bool _forceOnboarding = bool.fromEnvironment('FORCE_ONBOARDING');

  /// Version shown in Settings, "Acerca de" and "Ayuda y contacto".
  /// `tool/release_android.sh` passes `--dart-define=APP_VERSION=<version>`;
  /// empty in a development build (the screens then say so).
  static const String _appVersion = String.fromEnvironment('APP_VERSION');

  /// Address "Ayuda y contacto" offers to copy: [kSupportEmail], or the one
  /// the build sets (`--dart-define=SUPPORT_EMAIL=...`); the app has no mail
  /// launcher yet.
  static const String _supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: kSupportEmail,
  );

  /// Public policies opened in the external browser only on a user's tap.
  static const String _privacyUrl = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: 'https://dferrandizmont.github.io/cuadrante/privacidad/',
  );
  static const String _privacyUrlEn = String.fromEnvironment(
    'PRIVACY_URL_EN',
    defaultValue: 'https://dferrandizmont.github.io/cuadrante/privacidad/en/',
  );

  /// Shows the developer entries outside debug builds. Off by default.
  final bool showDevTools;

  /// Run on demo data rather than the real data.
  final bool useDemoData;

  /// Show the first-use flow whatever the data (see `FORCE_ONBOARDING`).
  final bool forceOnboarding;

  /// See `APP_VERSION`; empty when the build did not set it.
  final String appVersion;

  /// See `SUPPORT_EMAIL`; defaults to [kSupportEmail] when the build did not set it.
  final String supportEmail;

  /// See `PRIVACY_URL` and `PRIVACY_URL_EN`.
  final String privacyUrl;
  final String privacyUrlEn;

  /// Other supported languages use the authoritative Spanish policy.
  String privacyUrlFor(String languageCode) =>
      languageCode == 'en' ? privacyUrlEn : privacyUrl;

  /// Why this build must not run as a release, or null when it is fine.
  /// `main()` refuses to start a release build with a problem.
  static String? releaseConfigProblem({required bool useDemoData}) {
    if (useDemoData) {
      return 'USE_DEMO_DATA is true (the default): pass '
          '--dart-define=USE_DEMO_DATA=false for a release build.';
    }
    return null;
  }

  /// [releaseConfigProblem] for this configuration.
  String? get releaseProblem => releaseConfigProblem(useDemoData: useDemoData);
}
