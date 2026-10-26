# Licencias del contenido

Copyright (c) 2026 Daniel Mont Ferrandiz, para el contenido de redacción propia.

Versión en inglés: [LICENSE-CONTENT.en.md](LICENSE-CONTENT.en.md).

## Contenido propio: CC BY-SA 4.0

La documentación de `docs/` y `turnos-spec.md`, los textos de la app
(`app/lib/l10n/*.arb` y sus traducciones), el icono y la pantalla de arranque
(`app/assets/icon/`, generados con `tool/icon/`), las capturas de pantalla y los
recursos de presentación (`docs/tienda/`) se ofrecen bajo Creative Commons
Atribución-CompartirIgual 4.0 Internacional (CC BY-SA 4.0).

Puedes compartirlos y adaptarlos, también con fines comerciales, con atribución,
indicando los cambios y compartiendo las adaptaciones bajo la misma licencia.
La atribución debe identificar a Daniel Mont Ferrandiz y a Cuadrante e incluir
un enlace a esta licencia. Rigen los términos del
[texto de la licencia CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/legalcode.es).

Esta licencia se aplica solo al contenido propio. El nombre «Cuadrante» y el
icono identifican esta app: si publicas una versión modificada, dale otro nombre
y otro icono para que nadie la confunda con la original.

## Festivos oficiales

Los calendarios de festivos de `app/assets/holidays/` se construyen a partir de
datos publicados por administraciones públicas. Cada archivo lleva en
`app/assets/holidays/manifest.json` su fuente (`source`: URL, referencia y fecha
de publicación) y su suma de control (`docs/festivos.md`, «Formato del paquete»).
Fuentes del paquete incluido:

| Datos | Fuente |
|---|---|
| Festivos nacionales y autonómicos 2026 y 2027 | Boletín Oficial del Estado: BOE-A-2025-21667 y BOE-A-2026-21254 (Dirección General de Trabajo) |
| Festivos locales de la Comunidad de Madrid | Boletín Oficial de la Comunidad de Madrid, BOCM núm. 296 de 12.12.2025 |
| Festivos locales de la Región de Murcia (solo los del calendario escolar) | Boletín Oficial de la Región de Murcia, BORM núm. 132 de 11.6.2026 y núm. 167 de 22.7.2026 |
| Festivos locales de Cataluña | Dades Obertes de Catalunya, conjunto `b4eh-r8up` (Departament d'Empresa i Treball) |
| Índice de municipios (código y nombre) | Instituto Nacional de Estadística (INE) |

Los textos de disposiciones oficiales publicadas en boletines no tienen derechos
de autor conforme al artículo 13 de la Ley de Propiedad Intelectual, y los datos
de las administraciones se reutilizan conforme a la Ley 37/2007, de reutilización
de la información del sector público, citando la fuente y sin alterar su
sentido. Los conjuntos de datos abiertos (Cataluña, INE) se reutilizan según las
condiciones de su portal, que piden citar la fuente. **Estos datos quedan
excluidos de MIT y de CC BY-SA 4.0**: lo que es nuestro es la selección, la
transformación a JSON y las pruebas, no el contenido oficial. Ninguna
administración revisa ni respalda esta app.

## Formatos de otras apps

La importación lee copias de LRHSoft (`.Shifter`) y archivos `.ics` y CSV para
que puedas traer tu historial (`docs/importar.md`). El lector es código propio
bajo MIT; el repositorio no incluye código, datos ni material de LRHSoft ni de
ninguna otra app, y sus nombres pertenecen a sus titulares. Los archivos de
prueba (`app/test/fixtures/`) son sintéticos.

## Código de Mochila

Parte de `app/lib/core/` y de los festivos (`app/lib/features/holidays/`) está
copiada y adaptada de Mochila, otro proyecto del mismo autor (Daniel Mont
Ferrandiz), como anotan los propios archivos. Es del mismo titular, así que se
ofrece aquí bajo MIT sin ninguna condición adicional.

## Código y materiales de terceros

El código se ofrece bajo [MIT](LICENSE). Las dependencias de Flutter y de
pub.dev conservan sus propias licencias; la app las enseña en Ajustes ›
«Licencias de código abierto» (la página de licencias de Flutter) y la lista
exacta está en `app/pubspec.lock`. En particular:

- Los iconos de `cupertino_icons` se distribuyen bajo MIT (Copyright (c) 2016
  Vladimir Kharlampidi) y los de `material_symbols_icons` bajo Apache License
  2.0 (Google). Conservan sus avisos: no todo el contenido del binario pasa a
  ser MIT.
- `dbus` (MPL-2.0) entra como dependencia transitiva de
  `flutter_local_notifications` para Linux. No forma parte de las apps de
  Android ni de iOS; si compilas para Linux, se aplican sus condiciones (el
  código de `dbus` se puede usar sin cambios y, si lo modificas, esos cambios
  siguen bajo MPL-2.0).
- No se distribuyen fuentes tipográficas propias: la app usa la tipografía del
  sistema. Las pruebas cargan Roboto desde el SDK de Flutter.
