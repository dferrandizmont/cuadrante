# Gráficos y capturas del README y las tiendas

Como en Ley al Blanco, los tests de `app/test/store/` dibujan las composiciones
alrededor de **pantallas reales de Cuadrante**. No necesitan emulador, dispositivo,
red, una base de datos del usuario ni herramientas de retoque.

## Regenerar los README

Flutter **3.47.7**, desde `app/`:

```bash
TZ=Europe/Madrid flutter test --dart-define=GENERATE_STORE=true test/store
```

PowerShell:

```powershell
Get-TimeZone # En este equipo: Romance Standard Time (Madrid)
Remove-Item Env:TZ -ErrorAction SilentlyContinue
flutter test --dart-define=GENERATE_STORE=true test/store
```

Sin `GENERATE_STORE=true`, los tests quedan omitidos: `flutter test` normal no
escribe PNG. La etiqueta `store` permite seleccionarlos. La fuente Roboto se
carga desde el SDK de Flutter (no se descarga ni se incluye en la app). Si no
está disponible, la generación falla en vez de usar la fuente cuadrada de tests.
En Windows se usa la zona del sistema: no definas `TZ=Europe/Madrid`, porque
su runtime no interpreta ese identificador IANA como Linux.

Salidas versionadas en **`docs/readme/es/` y `docs/readme/en/`**, ocho por idioma:

| Archivo | Tamaño | Contenido |
|---|---|---|
| `header.png` | 1024 × 500 | Cabecera, reutilizable como gráfico destacado de Play |
| `icon-512.png` | 512 × 512 | Icono real de `app/assets/icon/icon.png` |
| `01-mes.png` | 540 × 1080 | Cuadrícula del mes, tema oscuro |
| `02-lista.png` | 540 × 1080 | Lista del mismo mes |
| `03-pintar.png` | 540 × 1080 | Pintar con la paleta, tema oscuro |
| `04-rotaciones.png` | 540 × 1080 | Asistente y vista previa de la rotación |
| `05-horas.png` | 540 × 1080 | Resumen de horas |
| `06-festivos.png` | 540 × 1080 | Festivos, comunidad y municipio |

PNG RGB de 8 bits, opacos y sin metadatos. El escritor comprueba las dimensiones
decodificando el PNG antes de guardarlo. La cabecera y el icono los genera
`readme_graphics_test.dart`; las escenas, `store_screenshots_test.dart`.

## Muestra reproducible

Reloj fijo: **24-dic-2026, 18:00**, por `clockProvider`. Base Drift en memoria,
nueva en cada escena. Calendario «Demo» y plantillas de turno del ARB del idioma:
Mañana 1–4, Tarde 10–11, Noche 23–25 y Saliente 26; el resto Libre. Madrid,
comunidad y municipio, con los festivos del paquete real de la app.

El test comprueba con el motor **9 turnos, 72 h, 24 h nocturnas y 8 h festivas**
antes de guardar cada imagen. Sin datos personales, salud ni importes ficticios.
El asistente usa otro calendario vacío, «Industria» / «Industry», para enseñar
la rotación Continental sin las excepciones de «Demo».
Pintar y la vista previa no se guardan: no alteran el resumen de las otras escenas.
La sexta escena usa Festivos; no se simula un escritorio ni un widget nativo.

## Tamaños de tienda

Los mismos tests pueden componer las seis escenas para cada tienda, sin estirar
ni cortar la pantalla. Desde `app/`:

```bash
TZ=Europe/Madrid flutter test --dart-define=GENERATE_STORE=true --dart-define=STORE_TARGET=play test/store/store_screenshots_test.dart
TZ=Europe/Madrid flutter test --dart-define=GENERATE_STORE=true --dart-define=STORE_TARGET=ios69 test/store/store_screenshots_test.dart
TZ=Europe/Madrid flutter test --dart-define=GENERATE_STORE=true --dart-define=STORE_TARGET=ios65 test/store/store_screenshots_test.dart
```

| Target | Lienzo | Salida regenerable |
|---|---|---|
| `play` | 1080 × 1920 | `app/build/store/play/{es,en}/` |
| `ios69` | 1320 × 2868 | `app/build/store/ios69/{es,en}/` |
| `ios65` | 1242 × 2688 | `app/build/store/ios65/{es,en}/` |

El target iOS selecciona controles Flutter de iOS; estos renders **no sustituyen
la validación del build de iPhone** ni las capturas de widgets nativos. Comprueba
los tamaños aceptados en cada consola y revisa visualmente cada PNG antes de
subirlo. Este generador entrega seis escenas en es/en; el guion de ocho capturas
y cinco idiomas de `docs/tienda/capturas.md` sigue siendo otra entrega.

Para validar sin escribir imágenes: `flutter analyze` y
`TZ=Europe/Madrid flutter test`. No se necesitan `flutter run`, `adb` ni pruebas
de integración en dispositivos.
