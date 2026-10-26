# Documentos legales

No son asesoramiento jurídico; conviene que los revise un profesional antes del lanzamiento. English version:
[LEEME.en.md](LEEME.en.md).

| Fichero | Qué es | Estado |
|---|---|---|
| `politica-privacidad.md` | Política de privacidad para publicar (RGPD y LOPDGDD), en tuteo. Refleja [`docs/privacy.md`](../privacy.md), que es la fuente de verdad técnica. | Sin marcadores: titular, correo y fecha ya rellenos. Revisar las «Notas para el titular» del final, que el generador HTML **omite**. |
| `politica-privacidad.en.md` | Traducción de cortesía al inglés. Manda la española. | Mantenerla al día con la española. |
| `../privacy.md` y `../privacy.en.md` | Inventario técnico de datos, permisos, copias y exportaciones, comprobado contra el código. | Revisar cada vez que cambie el flujo de datos. |
| `../../SECURITY.md` y `SECURITY.en.md` | Cómo avisar de una vulnerabilidad sin mandar datos reales. | — |
| `../../LICENSE` y `../../LICENSE-CONTENT.md` (`.en.md`) | MIT para el código; CC BY-SA 4.0 para el contenido propio; festivos oficiales, Mochila y terceros aparte. | — |

Convención: el texto en español es el que vale; cada documento tiene su versión inglesa en `*.en.md` al lado.

## Cómo se mantienen en sincronía con la web
La política se publica como página estática generada **desde este markdown**, nunca editada a mano en HTML, con el
mismo esquema que Ley al Blanco (`web/legal/`, tarea T08 del plan de publicación):

1. La fuente es `docs/legal/politica-privacidad.md`. El generador (`web/legal/md2html.py`) convierte el markdown a
   `web/legal/privacidad/index.html` y **omite** la sección «Notas para el titular». La versión inglesa se genera
   igual desde `politica-privacidad.en.md` a `web/legal/privacidad/en/index.html`.
2. Un test (`web/legal/test_legal.py`) compara el HTML generado con el markdown y falla si no coinciden, para que
   nadie edite el HTML por su cuenta ni se olvide de regenerar.
3. La página se sube a la rama `gh-pages` del repositorio público y queda en GitHub Pages
   (`https://dferrandizmont.github.io/cuadrante/privacidad/`, a confirmar cuando exista el repositorio).
4. Esa misma URL va en las fichas de las dos tiendas y en la fila «Política de privacidad» de Ajustes › Ayuda, ya
   implementada: abre el navegador externo solo al tocarla. El build usa `PRIVACY_URL` para la política española y
   `PRIVACY_URL_EN` para la inglesa (las URL de arriba por defecto; se pueden sustituir con `--dart-define`).
5. **Si cambia el flujo de datos**, se actualizan a la vez y en el mismo commit: `docs/privacy.md`, esta política (y
   las dos versiones inglesas), la fecha de «Última actualización» y las declaraciones de las tiendas
   (`docs/tienda/google-play.md`, «Seguridad de los datos»; `docs/tienda/app-store.md`, «App Privacy»). Después se
   regenera el HTML y se vuelve a subir a `gh-pages`.

## Lista para publicar
1. Revisar las «Notas para el titular» y, si procede, cambiar el plazo de conservación de los correos o la fecha.
2. Comprobar el correo de soporte en el build: `kSupportEmail` (`app/lib/core/config.dart`) ya contiene
   `dev@mainshai.com`; `SUPPORT_EMAIL` permite sustituirlo.
3. Generar el HTML, pasar el test y subir `gh-pages`.
4. Poner la URL en las fichas de las tiendas y comprobar que coincide con «Seguridad de los datos» (Play) y
   «Privacidad de la app» (Apple): no se recopilan datos.
