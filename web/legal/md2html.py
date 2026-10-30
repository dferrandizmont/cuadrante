"""Genera las dos políticas desde docs/legal, sin dependencias externas.

Uso: python -B web/legal/md2html.py
Las notas internas nunca se publican. No cambia las fuentes ni sus textos.
"""
import html
import re
from pathlib import Path

BASE = Path(__file__).resolve().parent
RAIZ = BASE.parents[1]
FUENTES = {
    "es": RAIZ / "docs/legal/politica-privacidad.md",
    "en": RAIZ / "docs/legal/politica-privacidad.en.md",
}
DESTINOS = {"es": "privacidad/index.html", "en": "privacidad/en/index.html"}
CORTE = "## Notas para el titular"


def publico(md):
    texto = md.split(CORTE)[0].rstrip()
    return re.sub(r"\n---\s*$", "", texto)


def inline(texto):
    # Only the small, explicit Markdown subset used by the supplied policies.
    # Escape plain text and attributes separately; never accept raw HTML.
    patron = r"(\*\*.+?\*\*|`[^`]+`|\[[^\]]+\]\([^)]+\)|https?://[^\s<]+|[\w.+-]+@[\w.-]+\.[A-Za-z]{2,})"
    salida = []
    for parte in re.split(patron, texto):
        if parte.startswith("**") and parte.endswith("**"):
            salida.append("<strong>" + inline(parte[2:-2]) + "</strong>")
        elif parte.startswith("`") and parte.endswith("`"):
            salida.append("<code>" + html.escape(parte[1:-1]) + "</code>")
        elif re.fullmatch(r"\[[^\]]+\]\([^)]+\)", parte):
            m = re.fullmatch(r"\[([^\]]+)\]\(([^)]+)\)", parte)
            destino = m[2]
            if destino == "politica-privacidad.md":
                destino = "../"  # English courtesy-translation link.
            if not (destino.startswith(("https://", "http://", "../", "./"))):
                raise ValueError(f"Enlace no admitido: {destino}")
            salida.append(f'<a href="{html.escape(destino, quote=True)}">{inline(m[1])}</a>')
        elif parte.startswith(("https://", "http://")):
            destino = html.escape(parte, quote=True)
            salida.append(f'<a href="{destino}">{html.escape(parte)}</a>')
        elif re.fullmatch(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", parte):
            correo = html.escape(parte, quote=True)
            salida.append(f'<a href="mailto:{correo}">{correo}</a>')
        else:
            salida.append(html.escape(parte))
    return "".join(salida)


def convertir(md):
    lineas = publico(md).splitlines()
    salida = []
    i = 0
    while i < len(lineas):
        linea = lineas[i]
        if not linea.strip():
            i += 1
            continue
        titulo = re.fullmatch(r"(#{1,3}) (.+)", linea)
        if titulo:
            nivel = len(titulo[1])
            salida.append(f"<h{nivel}>{inline(titulo[2])}</h{nivel}>")
            i += 1
        elif linea == "---":
            salida.append("<hr>")
            i += 1
        elif linea.startswith("|"):
            filas = []
            while i < len(lineas) and lineas[i].startswith("|"):
                filas.append([c.strip() for c in lineas[i].strip("|").split("|")])
                i += 1
            salida.append('<div class="tabla" role="region" aria-label="' +
                          ('Purposes and legal basis' if '# Turnly privacy' in md else 'Finalidades y base jurídica') +
                          '" tabindex="0"><table><thead><tr>')
            salida.append("".join(f'<th scope="col">{inline(c)}</th>' for c in filas[0]))
            salida.append("</tr></thead><tbody>")
            for fila in filas[2:]:
                salida.append("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in fila) + "</tr>")
            salida.append("</tbody></table></div>")
        elif linea.startswith("- "):
            salida.append("<ul>")
            while i < len(lineas) and lineas[i].startswith("- "):
                partes = [lineas[i][2:]]
                i += 1
                while i < len(lineas) and lineas[i].startswith("  "):
                    partes.append(lineas[i].strip())
                    i += 1
                salida.append("<li>" + inline(" ".join(partes)) + "</li>")
            salida.append("</ul>")
        else:
            partes = [linea]
            i += 1
            while i < len(lineas) and lineas[i].strip() and not re.match(r"^(#|\||- |---)", lineas[i]):
                partes.append(lineas[i].strip())
                i += 1
            salida.append("<p>" + inline(" ".join(partes)) + "</p>")
    return "\n".join(salida)


def pagina(idioma):
    ingles = idioma == "en"
    titulo = "Turnly privacy policy" if ingles else "Política de privacidad de Turnly"
    raiz = "../../" if ingles else "../"
    alternativa = "../" if ingles else "en/"
    nombre = "Español" if ingles else "English"
    cuerpo = convertir(FUENTES[idioma].read_text(encoding="utf-8"))
    ruta = "privacidad/en/" if ingles else "privacidad/"
    return f'''<!DOCTYPE html>
<html lang="{idioma}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>{titulo}</title>
<meta name="description" content="{titulo}">
<link rel="canonical" href="https://dferrandizmont.github.io/turnly/{ruta}">
<link rel="stylesheet" href="{raiz}styles.css">
</head>
<body>
<main id="contenido">
<nav aria-label="{'Language' if ingles else 'Idioma'}"><a href="{alternativa}" lang="{'es' if ingles else 'en'}" hreflang="{'es' if ingles else 'en'}">{nombre}</a></nav>
{cuerpo}
<footer><a href="{raiz}">Turnly</a></footer>
</main>
</body>
</html>
'''


def generar(destino=BASE):
    for idioma, relativo in DESTINOS.items():
        archivo = destino / relativo
        archivo.parent.mkdir(parents=True, exist_ok=True)
        archivo.write_text(pagina(idioma), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    generar()
    print("Generadas las políticas en español e inglés.")
