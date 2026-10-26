# Contributing to Cuadrante

[Español](CONTRIBUTING.md)

Cuadrante is free, with no accounts, ads or purchases. Flutter code lives in
`app/`; scope is defined in [turnos-spec.md](turnos-spec.md), with technical
contracts in `docs/` (Spanish). Describe the problem, expected behaviour and
verification. Discuss UI and scope changes in an issue first. Use synthetic
data instead of attaching personal schedules.

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

With Flutter **3.47.7**, from `app/`:

```sh
flutter pub get
flutter gen-l10n
flutter analyze
TZ=Europe/Madrid flutter test
```

On Windows, use the Madrid system time zone and run `flutter test` without `TZ`.
Without a connection, use `flutter pub get --offline` if dependencies are cached.
After changing Drift, freezed or JSON, run `dart run build_runner build` and
keep generated files. Include the commands and results in your PR. Report
vulnerabilities following [SECURITY.md](SECURITY.md).
