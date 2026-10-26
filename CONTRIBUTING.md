# Colaborar en Cuadrante

[English](CONTRIBUTING.en.md)

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

Con Flutter **3.47.7**, desde `app/`:

```sh
flutter pub get
flutter gen-l10n
flutter analyze
TZ=Europe/Madrid flutter test
```

En Windows usa la zona de Madrid del sistema y `flutter test` sin `TZ`. Sin red,
usa `flutter pub get --offline` si ya tienes las dependencias. Si cambias Drift,
freezed o JSON, ejecuta `dart run build_runner build` y conserva los generados.
Incluye en el PR los comandos ejecutados y su resultado. Para vulnerabilidades,
sigue [SECURITY.md](SECURITY.md).
