"""Prepara dist/ para GitHub Pages. Los datos ya están en las políticas fuente.

No sustituye textos legales: genera, comprueba y copia solo los archivos públicos.
Uso: python -B web/legal/rellenar.py [--destino RUTA]
"""
import argparse
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
import md2html

BASE = Path(__file__).resolve().parent
FICHEROS = ["index.html", *md2html.DESTINOS.values(), "styles.css", "robots.txt", ".nojekyll"]
RE_MARCADOR = re.compile(r"\[(?:TITULAR|CORREO_SOPORTE|FECHA|PLAZO_[A-Z_]+|ENLACE[A-Z_]*)\]|\b(?:PENDIENTE|TODO|FIXME)\b")


def generar(destino=BASE / "dist"):
    contenidos = {rel: (BASE / rel).read_text(encoding="utf-8") for rel in FICHEROS}
    for idioma, relativo in md2html.DESTINOS.items():
        if contenidos[relativo] != md2html.pagina(idioma):
            raise ValueError("Política desactualizada: ejecuta python -B web/legal/md2html.py")
    for rel, texto in contenidos.items():
        if RE_MARCADOR.search(texto) or "Notas para el titular" in texto:
            raise ValueError(f"Marcadores o notas internas en {rel}")
    # A previous output containing unknown files is refused, never published.
    if destino.exists():
        extras = {p.relative_to(destino).as_posix() for p in destino.rglob('*') if p.is_file()} - set(FICHEROS)
        if extras:
            raise ValueError(f"Destino con archivos ajenos; elige uno vacío: {sorted(extras)}")
    for rel, texto in contenidos.items():
        archivo = destino / rel
        archivo.parent.mkdir(parents=True, exist_ok=True)
        archivo.write_text(texto, encoding="utf-8", newline="\n")
    return destino


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destino', type=Path, default=BASE / 'dist')
    args = parser.parse_args()
    try:
        print(f"Listo para Pages: {generar(args.destino)}")
    except ValueError as error:
        parser.exit(1, f"ERROR: {error}\n")
