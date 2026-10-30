**English** · [Español](CONTRIBUTING.es.md)

# Contributing

Bug reports, ideas and translations are welcome. Describe the problem, the expected
behaviour and how you checked it. Discuss UI and scope changes in an issue first.
Use synthetic data instead of attaching personal schedules.

Turnly is free, with no accounts, ads or purchases. Flutter code lives in
`app/`; scope is defined in [turnos-spec.md](turnos-spec.md), with technical
contracts in `docs/` (Spanish).

- Calculate shifts through `Schedule`, using rules and exceptions. Test engine
  changes. Calendar dates use `CivilDate`; get today from `clockProvider`.
- Drift migrations require `dart run drift_dev make-migrations`, migration
  tests and compatibility with old backups. Read [data](docs/datos.md) and
  [backups](docs/copia-de-seguridad.md).
- Use the [design](docs/diseno.md) tokens: `context.colors`, `context.type`,
  `Sp`, `Rad`, `AppIcons`. Show each shift with colour, code and time.
- Put UI strings in all five ARB files (es, ca, gl, eu, en). Use a direct,
  informal tone, without emoji. Follow the [glossary](docs/glosario-idiomas.md),
  review translations and placeholders, and do not attach Basque suffixes to a
  placeholder.

## Build and test

Requirements: **Flutter 3.47.7**, Android SDK for Android or macOS with Xcode
for iPhone. The app uses Riverpod, go_router and Drift for state, navigation
and the local database.

From the repository root:

```bash
cd app
flutter pub get
flutter gen-l10n
flutter analyze
TZ=Europe/Madrid flutter test
```

Offline, use `flutter pub get --offline` with previously downloaded packages.
On Windows, use the system's Madrid time zone (`Get-TimeZone`) and run
`flutter test` without setting `TZ`; the Linux IANA identifier changes time
handling in the Windows runtime.

To build an APK using real storage, without demo data:

```bash
flutter build apk --release --dart-define=USE_DEMO_DATA=false
```

Generated files are checked in; after changing Drift, freezed or JSON sources, run
`dart run build_runner build`.

Prepare the public selection with the [exporter](tool/publish/LEEME.en.md).
Signing and publishing require separate preparation and review.

Include the commands and results in your PR. Report vulnerabilities following
[SECURITY.en.md](SECURITY.en.md).

[Regenerate graphics and screenshots](tool/store/LEEME.md) (in Spanish) ·
[Privacy policy and website](docs/legal/LEEME.en.md) ·
[Design](docs/diseno.md) (in Spanish).
