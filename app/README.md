# Cuadrante (app)

Calendario de turnos de trabajo en Flutter, iOS primero. Producto: `../turnos-spec.md`.

## Ejecutar

```sh
flutter pub get
flutter run                                   # datos de demostración (USE_DEMO_DATA=true por defecto)
flutter run --dart-define=SHOW_DEV_TOOLS=true
```

Un build de release exige `--dart-define=USE_DEMO_DATA=false`; si no, `main()` se niega a arrancar.

## Comprobar

```sh
flutter analyze
flutter test        # TZ=Europe/Madrid en CI
```

## Código generado

- Textos: `lib/l10n/app_es.arb` es la plantilla. Tras editarla, `flutter gen-l10n` regenera `lib/l10n/app_localizations*.dart` (se versionan).
- Modelos (freezed / json_serializable) y base de datos (drift):

```sh
dart run build_runner build
```

La base de datos (Drift) tiene un volcado de cada versión en `drift_schemas/`; al cambiar una tabla se sube `schemaVersion`, se ejecuta `dart run drift_dev make-migrations` y se escribe el paso de migración (`docs/datos.md`, «Migraciones»).

## Estructura

- `lib/core/`: tema (`theme/`), iconos por plataforma (`icons/`), widgets de UI puros (`widgets/`), formato (`format/`), arranque, configuración, router y providers.
- `lib/features/`: una carpeta por funcionalidad (`calendar`, `schedule`, `settings`...).
- Convenciones: providers de Riverpod manuales (sin codegen), freezed solo para modelos, colores y estilos siempre por `context.colors` / `context.type`, textos siempre por `context.l10n`.
