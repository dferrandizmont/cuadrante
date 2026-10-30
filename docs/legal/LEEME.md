# Documentos legales

No son asesoramiento jurídico; conviene que los revise un profesional antes del lanzamiento. English version:
[LEEME.en.md](LEEME.en.md).

| Fichero | Qué es | Estado |
|---|---|---|
| `politica-privacidad.md` | Política de privacidad para publicar (RGPD y LOPDGDD), en tuteo. Refleja [`docs/privacy.md`](../privacy.md), que es la fuente de verdad técnica. | Sin marcadores: titular, correo y fecha ya rellenos. Las notas internas están al final de este documento. |
| `politica-privacidad.en.md` | Traducción de cortesía al inglés. Manda la española. | Mantenerla al día con la española. |
| `../privacy.md` y `../privacy.en.md` | Inventario técnico de datos, permisos, copias y exportaciones, comprobado contra el código. | Revisar cada vez que cambie el flujo de datos. |
| `../../SECURITY.md` y `SECURITY.en.md` | Cómo avisar de una vulnerabilidad sin mandar datos reales. | — |
| `../../LICENSE` y `../../LICENSE-CONTENT.md` (`.en.md`) | MIT para el código; CC BY-SA 4.0 para el contenido propio; festivos oficiales, Mochila y terceros aparte. | — |

Convención: el texto en español es el que vale; cada documento tiene su versión inglesa en `*.en.md` al lado.

## Cómo se mantienen en sincronía con la web
La política se publica en la web de la app, `https://turnly.mainshai.com/privacy/` (en inglés, `/en/privacy/`; en
catalán, gallego y euskera se muestra la española con un aviso), generada **desde este markdown** sin resumirla:

1. La fuente es `docs/legal/politica-privacidad.md` y su traducción `politica-privacidad.en.md`. El generador común de
   las webs (`mainshai-web`, `sitegen`) las lee según `web/site.toml` y comprueba que el texto publicado coincide con
   el markdown y que `privacy_date` de `web/content/<idioma>.json` es la fecha de «Última actualización».
2. Esa misma URL va en las fichas de las dos tiendas y en la fila «Política de privacidad» de Ajustes › Ayuda, ya
   implementada: abre el navegador externo solo al tocarla. El build usa `PRIVACY_URL` para la política española y
   `PRIVACY_URL_EN` para la inglesa (las URL de arriba por defecto; se pueden sustituir con `--dart-define`).
3. **Si cambia el flujo de datos**, se actualizan a la vez y en el mismo commit: `docs/privacy.md`, esta política (y
   las dos versiones inglesas), la fecha de «Última actualización», `privacy_date` en `web/content/*.json` y las
   declaraciones de las tiendas (`docs/tienda/google-play.md`, «Seguridad de los datos»; `docs/tienda/app-store.md`,
   «App Privacy»). Después se regenera y se despliega la web (skill `web-app`).

Hasta el 30-oct-2026 se publicaba en GitHub Pages (`web/legal/`, rama `gh-pages`); esas páginas se retiran con una
redirección a la web nueva.

## Lista para publicar
1. Revisar las notas para el titular de abajo y, si procede, cambiar el plazo de conservación de los correos o la fecha.
2. Comprobar el correo de soporte en el build: `kSupportEmail` (`app/lib/core/config.dart`) ya contiene
   `turnly@mainshai.com`; `SUPPORT_EMAIL` permite sustituirlo.
3. Generar, comprobar y desplegar la web de la app.
4. Poner la URL en las fichas de las tiendas y comprobar que coincide con «Seguridad de los datos» (Play) y
   «Privacidad de la app» (Apple): no se recopilan datos.

## Notas para el titular
Estaban al final de la política y salieron de ella el 30-oct-2026, al publicarla en la web nueva. Texto redactado el
26-oct-2026 contra el código de esa fecha (`docs/privacy.md` es la fuente de verdad): revísalo con una persona antes
del lanzamiento.

Decisiones ya tomadas en el texto, por si quieres cambiarlas: titular Daniel Mont Ferrandiz; correo
`turnly@mainshai.com` (el de la app desde el 30-oct-2026, reenviado con Cloudflare Email Routing; antes
`dev@mainshai.com`); conservación de correos «un año desde la última respuesta»; fecha de última actualización la de
la redacción. No se publica el NIF: el RGPD pide identificar al responsable y un contacto, y una app gratuita sin
actividad económica no está obligada a darlo por la LSSI.

Pendientes: la decisión 13 de `docs/preguntas.md` (ausencias de salud fuera de toda copia automática) no está
implementada, y la política dice la verdad actual (van en las copias); si se implementa, reescribir «Tu baja médica» y
«Copias de seguridad». Comprobar que la política coincide con «Seguridad de los datos» (Play) y «Privacidad de la app»
(Apple): no se recopilan datos. La versión inglesa (`politica-privacidad.en.md`) es una traducción de cortesía; manda
la española.
