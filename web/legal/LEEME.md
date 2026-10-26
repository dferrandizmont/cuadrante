# Web pública de Cuadrante

Mismo mecanismo que Ley al Blanco: portada estática, CSS compartido, políticas
generadas desde Markdown y una prueba que impide publicar textos desactualizados.
Sin JavaScript, cookies, fuentes remotas ni analítica.

URL prevista de GitHub Pages: **https://dferrandizmont.github.io/cuadrante/**.
La preparación de estos archivos no publica el sitio ni configura el repositorio remoto.

## Regenerar y comprobar

Python 3.11 o superior, sin instalar paquetes. Desde la raíz:

```bash
python -B web/legal/md2html.py
python -B web/legal/test_legal.py
python -B web/legal/rellenar.py
```

- Español: `docs/legal/politica-privacidad.md` → `privacidad/index.html`.
- Inglés: `docs/legal/politica-privacidad.en.md` → `privacidad/en/index.html`.
- El generador omite «Notas para el titular» y la regla que la precede. La
  traducción inglesa enlaza la versión española y conserva su aviso de cortesía.
- No se edita el HTML de las políticas a mano. Los textos legales se mantienen
  en sus fuentes; el generador no cambia su significado ni rellena datos inventados.
- `rellenar.py` conserva el nombre de la herramienta de referencia, pero aquí
  titular, correo y fecha ya están en las fuentes. Comprueba que no haya marcadores
  y crea `dist/` solo con portada, políticas, estilos, `robots.txt` y `.nojekyll`.
  No copia fuentes, scripts, tests ni notas. `dist/` está ignorado por Git.
- Destino alternativo: `python -B web/legal/rellenar.py --destino /ruta/vacia`.

## Publicar, cuando se autorice

La raíz del sitio debe ser **el contenido de `web/legal/dist/`**, sin añadir el
prefijo `web/legal/` en la URL. Para publicación por rama, lleva ese contenido a
la raíz de `gh-pages` del repositorio público `dferrandizmont/cuadrante` y elige
**Settings → Pages → Deploy from a branch → gh-pages → /(root)**. No subas el
repositorio completo como sitio. Otra opción es entregar el mismo directorio a
un workflow de GitHub Pages con autorización de despliegue.

Comprueba tras publicar:

- `/cuadrante/`, `/cuadrante/privacidad/` y `/cuadrante/privacidad/en/`.
- Enlaces de idioma, soporte y estilos tanto en claro como en oscuro.
- URL en las fichas de ambas tiendas: la española es
  `https://dferrandizmont.github.io/cuadrante/privacidad/`.

CI ejecuta `python -B web/legal/test_legal.py`; no publica ni hace push.
