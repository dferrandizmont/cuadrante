"""Pruebas de fidelidad y publicación. Solo biblioteca estándar de Python.

Ejecutar desde cualquier carpeta: python -B web/legal/test_legal.py
"""
import re
import sys
import tempfile
import unittest
from html.parser import HTMLParser
from pathlib import Path
from unittest.mock import patch

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import md2html
import rellenar

BASE = Path(__file__).resolve().parent
PAGINAS = ["index.html", *md2html.DESTINOS.values()]
VOID = {"meta", "link", "br", "hr", "img", "input"}


class Documento(HTMLParser):
    def __init__(self):
        super().__init__()
        self.pila, self.errores, self.enlaces, self.textos = [], [], [], []
        self.idioma = None

    def handle_starttag(self, tag, attrs):
        atributos = dict(attrs)
        if tag not in VOID:
            self.pila.append(tag)
        if tag == 'html':
            self.idioma = atributos.get('lang')
        if tag in ('a', 'link'):
            self.enlaces.append(atributos.get('href', ''))
        if tag in ('td', 'th'):
            self.textos.append(' ')

    def handle_endtag(self, tag):
        if not self.pila or self.pila[-1] != tag:
            self.errores.append(f"Cierre inesperado: {tag}, pila {self.pila}")
        else:
            self.pila.pop()
        if tag in ('p', 'li', 'h1', 'h2', 'h3', 'td', 'th'):
            self.textos.append(' ')

    def handle_data(self, data):
        self.textos.append(data)


def normalizar(texto):
    return ' '.join(texto.split())


class WebLegalTest(unittest.TestCase):
    def test_html_balanceado_idiomas_y_enlaces_locales(self):
        for relativo in PAGINAS:
            with self.subTest(pagina=relativo):
                archivo = BASE / relativo
                texto = archivo.read_text(encoding='utf-8')
                documento = Documento()
                documento.feed(texto)
                self.assertEqual(documento.errores, [])
                self.assertEqual(documento.pila, [])
                self.assertEqual(documento.idioma, 'en' if '/en/' in relativo else 'es')
                self.assertNotIn('<script', texto)
                self.assertNotIn('href="politica-privacidad.md"', texto)
                for enlace in documento.enlaces:
                    self.assertTrue(enlace)
                    if enlace.startswith(('http:', 'https:', 'mailto:', '#')):
                        continue
                    destino = archivo.parent / enlace
                    if enlace.endswith('/'):
                        destino /= 'index.html'
                    self.assertTrue(destino.is_file(), f'{relativo}: {enlace}')

    def test_politicas_al_dia(self):
        for idioma, relativo in md2html.DESTINOS.items():
            with self.subTest(idioma=idioma):
                self.assertEqual((BASE / relativo).read_text(encoding='utf-8'), md2html.pagina(idioma))

    def test_fidelidad_del_texto_y_tabla(self):
        for idioma, fuente in md2html.FUENTES.items():
            with self.subTest(idioma=idioma):
                md = md2html.publico(fuente.read_text(encoding='utf-8'))
                cuerpo = md2html.convertir(md)
                documento = Documento()
                documento.feed(cuerpo)
                texto = normalizar(''.join(documento.textos))
                self.assertIn('<thead>', cuerpo)
                self.assertEqual(cuerpo.count('<h2>'), 11)
                for linea in md.splitlines():
                    if not linea.strip() or re.fullmatch(r'\|[-| :]+\|', linea):
                        continue
                    # Every source line must survive, including list continuations.
                    partes = linea.strip().strip('|').split('|') if linea.startswith('|') else [linea]
                    for parte in partes:
                        parte = re.sub(r'^\s*(?:#{1,3} |- )', '', parte)
                        parte = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', parte)
                        parte = parte.replace('**', '').replace('`', '')
                        self.assertIn(normalizar(parte), texto)
                self.assertIn('dev@mainshai.com', texto)

    def test_sin_notas_ni_marcadores_en_salida(self):
        for relativo in rellenar.FICHEROS:
            texto = (BASE / relativo).read_text(encoding='utf-8')
            self.assertIsNone(rellenar.RE_MARCADOR.search(texto), relativo)
            self.assertNotIn('Notas para el titular', texto)
            self.assertNotIn('no publicar', texto)

    def test_conversion_escapa_y_conserva_continuaciones(self):
        cuerpo = md2html.convertir('# Título\n\n- primera línea\n  segunda & tercera\n- cuarta\n\n<script>\n\n---\n\n## Notas para el titular\nSECRETO')
        self.assertIn('<li>primera línea segunda &amp; tercera</li>', cuerpo)
        self.assertIn('&lt;script&gt;', cuerpo)
        self.assertNotIn('SECRETO', cuerpo)
        self.assertNotIn('<hr>', cuerpo)
        self.assertIn('<code>.cuadrante</code>', md2html.inline('`.cuadrante`'))

    def test_prepara_solo_archivos_publicos(self):
        with tempfile.TemporaryDirectory() as tmp:
            destino = Path(tmp) / 'pages'
            rellenar.generar(destino)
            archivos = {p.relative_to(destino).as_posix() for p in destino.rglob('*') if p.is_file()}
            self.assertEqual(archivos, set(rellenar.FICHEROS))
            rellenar.generar(destino)  # Idempotent.
            for rel in rellenar.FICHEROS:
                self.assertEqual((destino / rel).read_bytes(), (BASE / rel).read_bytes())

    def test_rechaza_marcadores_y_html_desactualizado(self):
        with tempfile.TemporaryDirectory() as tmp:
            origen = Path(tmp) / 'source'
            rellenar.generar(origen)
            with patch.object(rellenar, 'BASE', origen):
                (origen / 'index.html').write_text('[CORREO_SOPORTE]', encoding='utf-8')
                with self.assertRaisesRegex(ValueError, 'Marcadores'):
                    rellenar.generar(Path(tmp) / 'out')
                (origen / 'index.html').write_text('Cuadrante', encoding='utf-8')
                (origen / 'privacidad/index.html').write_text('antigua', encoding='utf-8')
                with self.assertRaisesRegex(ValueError, 'desactualizada'):
                    rellenar.generar(Path(tmp) / 'out')

    def test_no_publica_archivos_ajenos(self):
        with tempfile.TemporaryDirectory() as tmp:
            destino = Path(tmp)
            (destino / 'interno.txt').write_text('privado', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'archivos ajenos'):
                rellenar.generar(destino)
            self.assertTrue((destino / 'interno.txt').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
