[English](CONTRIBUTING.md) · **Español**

# Colaborar en Cuadrante

Cuadrante es gratuita, sin cuentas, anuncios ni compras. El código Flutter está en
`app/`; el alcance está en [turnos-spec.md](turnos-spec.md) y los contratos en
`docs/`. Explica el problema, el comportamiento esperado y cómo lo has comprobado.
Para cambios de interfaz o de alcance, acuerda primero la propuesta en una issue.
No adjuntes cuadrantes personales: usa datos sintéticos.

- Los turnos se calculan con `Schedule`, mediante reglas y excepciones. Prueba
  cualquier cambio del motor. Las fechas de calendario usan `CivilDate`; «hoy»
  procede de `clockProvider`.
- Una migración de Drift exige `dart run drift_dev make-migrations`, una prueba
  de migración y compatibilidad con las copias antiguas. Consulta
  [datos](docs/datos.md) y [copias](docs/copia-de-seguridad.md).
- Usa los tokens de [diseño](docs/diseno.md): `context.colors`, `context.type`,
  `Sp`, `Rad`, `AppIcons`. Cada turno muestra color, código y hora.
- Todo texto de interfaz va en los cinco ARB (es, ca, gl, eu, en), con tú y sin
  emojis. Consulta el [glosario](docs/glosario-idiomas.md). Revisa los idiomas y
  sus placeholders; en euskera no añadas sufijos a un placeholder.

## Compilar y probar

Requisitos: **Flutter 3.47.7**, Android SDK para Android o macOS con Xcode para
iPhone. La app usa Riverpod, go_router y Drift para el estado, la navegación y
la base de datos local.

Desde la raíz:

```bash
cd app
flutter pub get
flutter gen-l10n
flutter analyze
TZ=Europe/Madrid flutter test
```

Sin conexión, usa `flutter pub get --offline` con los paquetes ya descargados.
En Windows, usa la zona de Madrid del sistema (`Get-TimeZone`) y ejecuta
`flutter test` sin definir `TZ`; el identificador IANA de Linux altera las horas
en el runtime de Windows.

Para compilar un APK con almacenamiento real, sin los datos de demostración:

```bash
flutter build apk --release --dart-define=USE_DEMO_DATA=false
```

Los archivos generados se versionan; si cambias Drift, freezed o JSON, ejecuta
`dart run build_runner build`.

La selección pública se prepara con el [exportador](tool/publish/LEEME.md). La firma
y la publicación requieren una preparación y revisión separadas.

Incluye en el PR los comandos ejecutados y su resultado. Para vulnerabilidades,
sigue [SECURITY.md](SECURITY.md).

[Regenerar imágenes y capturas](tool/store/LEEME.md) ·
[Generar la web de privacidad](web/legal/LEEME.md) · [Diseño](docs/diseno.md).
