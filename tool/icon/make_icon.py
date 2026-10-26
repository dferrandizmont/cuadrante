#!/usr/bin/env python
"""Genera el icono de Cuadrante y la imagen de la pantalla de arranque.

Diseño (docs/diseno.md, «Icono de la app»): cuadrícula 3x3 sobre #141418; la
fila central en Mañana, Tarde y Noche; el resto, #2A2A31. Todo sale de las
constantes de abajo, sin dibujos a mano:

  python tool/icon/make_icon.py          (desde la raíz del repositorio)

Salidas, en app/assets/icon/:
  icon.png        1024, a sangre, sin alfa (iOS y respaldo de Android).
  foreground.png  1024, transparente: capa frontal del icono adaptable.
  monochrome.png  1024, blanco sobre transparente: icono tematizado de Android 13.
  splash.png      1152, solo la cuadrícula, transparente (pantalla de arranque).
Vistas previas a 48 y 96 px en tool/icon/preview/.

Requiere Pillow. Se dibuja a 4x y se reduce, para bordes suaves.
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

BACKGROUND = "#141418"
OFF_CELL = "#2A2A31"
MIDDLE_ROW = ("#F5A524", "#F06A3F", "#4B4FD1")  # Mañana, Tarde, Noche

SIZE = 1024
GRID_RATIO = 0.60  # lado de la cuadrícula / lado del lienzo (icono completo)
GAP_RATIO = 0.06  # separación / lado de la cuadrícula
RADIUS_RATIO = 0.04  # radio de las casillas / lado de la cuadrícula
OFF_ALPHA_MONO = 90  # casillas de relleno en el icono monocromo (de 255)

# Icono adaptable: lienzo de 108 dp; la zona segura es un círculo de 66 dp.
# flutter_launcher_icons mete la capa frontal y la monocroma con un margen del
# 16 % por lado (<inset android:inset="16%">), así que el PNG se dibuja más
# grande para que, ya con el margen, la cuadrícula mida FOREGROUND_GRID_RATIO
# del lienzo de 108 dp y quepa en el círculo seguro (se comprueba abajo).
SAFE_ZONE = 0.66
PLUGIN_INSET = 0.16
FOREGROUND_GRID_RATIO = 0.46  # sobre el lienzo de 108 dp, ya con el margen
FOREGROUND_FILE_RATIO = FOREGROUND_GRID_RATIO / (1 - 2 * PLUGIN_INSET)

# Pantalla de arranque: lienzo de 1152 px (288 dp a 4x); Android 12 recorta a un
# círculo de 192 dp (768 px).
SPLASH_CANVAS = 1152
SPLASH_GRID = 520
SPLASH_CIRCLE = 768

SS = 4  # supermuestreo

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "assets" / "icon"
PREVIEW = Path(__file__).resolve().parent / "preview"


def rgb(hex_color: str) -> tuple[int, int, int]:
    h = hex_color.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def draw_grid(
    canvas: int,
    grid: float,
    *,
    background: str | None,
    mono: bool = False,
) -> Image.Image:
    """Lienzo cuadrado de `canvas` px con la cuadrícula centrada, de lado `grid` px.

    Con `background` sale RGB opaco; sin él, RGBA transparente.
    """
    big = canvas * SS
    if background:
        img = Image.new("RGB", (big, big), rgb(background))
    else:
        img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    g = grid * SS
    gap = g * GAP_RATIO
    cell = (g - 2 * gap) / 3
    radius = g * RADIUS_RATIO
    x0 = (big - g) / 2
    y0 = (big - g) / 2
    for row in range(3):
        for col in range(3):
            if mono:
                color = (255, 255, 255, 255 if row == 1 else OFF_ALPHA_MONO)
            else:
                color = rgb(MIDDLE_ROW[col] if row == 1 else OFF_CELL)
            left = x0 + col * (cell + gap)
            top = y0 + row * (cell + gap)
            draw.rounded_rectangle(
                (left, top, left + cell, top + cell), radius=radius, fill=color
            )
    return img.resize((canvas, canvas), Image.LANCZOS)


def max_radius_of_content(img: Image.Image) -> float:
    """Distancia máxima al centro de un píxel visible (alfa > 8), en px."""
    alpha = img.getchannel("A")
    w, h = img.size
    cx, cy = (w - 1) / 2, (h - 1) / 2
    best = 0.0
    px = alpha.load()
    for y in range(h):
        for x in range(w):
            if px[x, y] > 8:
                best = max(best, math.hypot(x - cx, y - cy))
    return best


def mask_preview(img: Image.Image, size: int, shape: str) -> Image.Image:
    base = img.convert("RGBA").resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size * SS, size * SS), 0)
    d = ImageDraw.Draw(mask)
    if shape == "circle":
        d.ellipse((0, 0, size * SS - 1, size * SS - 1), fill=255)
    else:
        d.rounded_rectangle(
            (0, 0, size * SS - 1, size * SS - 1), radius=int(size * SS * 0.22), fill=255
        )
    mask = mask.resize((size, size), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)

    # 1. Icono completo: a sangre, sin alfa.
    icon = draw_grid(SIZE, SIZE * GRID_RATIO, background=BACKGROUND)
    icon.save(OUT / "icon.png")

    # 2. Capa frontal adaptable: transparente, cuadrícula dentro de la zona segura.
    fg = draw_grid(SIZE, SIZE * FOREGROUND_FILE_RATIO, background=None)
    # Como queda en el icono: el PNG a (1 - 2 * margen) del lienzo, centrado.
    inner = round(SIZE * (1 - 2 * PLUGIN_INSET))
    fg_placed = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    fg_placed.paste(fg.resize((inner, inner), Image.LANCZOS), ((SIZE - inner) // 2,) * 2)
    reach = max_radius_of_content(fg_placed)
    limit = SIZE * SAFE_ZONE / 2
    assert reach <= limit, f"la cuadrícula se sale de la zona segura: {reach:.1f} > {limit:.1f}"
    fg.save(OUT / "foreground.png")

    # 3. Monocromo: blanco, fila central sólida, el resto con menos alfa.
    mono = draw_grid(SIZE, SIZE * FOREGROUND_FILE_RATIO, background=None, mono=True)
    mono.save(OUT / "monochrome.png")

    # 4. Pantalla de arranque: solo la cuadrícula, cabe en el círculo de Android 12.
    splash = draw_grid(SPLASH_CANVAS, SPLASH_GRID, background=None)
    reach = max_radius_of_content(splash)
    assert reach <= SPLASH_CIRCLE / 2, (
        f"la cuadrícula del arranque no cabe en el círculo: {reach:.1f}"
    )
    splash.save(OUT / "splash.png")

    # 5. Vistas previas a 48 y 96 px.
    adaptive = Image.new("RGBA", (SIZE, SIZE), (*rgb(BACKGROUND), 255))
    adaptive.alpha_composite(fg_placed)
    # Lo visible de un icono adaptable es el centro de 72/108 del lienzo.
    inset = int(SIZE * (1 - 72 / 108) / 2)
    box = (inset, inset, SIZE - inset, SIZE - inset)
    mono_on_dark = Image.new("RGBA", (SIZE, SIZE), (58, 58, 66, 255))
    mono_placed = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    mono_placed.paste(mono.resize((inner, inner), Image.LANCZOS), ((SIZE - inner) // 2,) * 2)
    mono_on_dark.alpha_composite(mono_placed)
    for px in (48, 96):
        mask_preview(icon, px, "squircle").save(PREVIEW / f"icon_{px}.png")
        mask_preview(adaptive.crop(box), px, "circle").save(PREVIEW / f"adaptive_{px}.png")
        mask_preview(mono_on_dark.crop(box), px, "circle").save(
            PREVIEW / f"monochrome_{px}.png"
        )

    print("Listo:", ", ".join(sorted(p.name for p in OUT.glob("*.png"))))


if __name__ == "__main__":
    main()
