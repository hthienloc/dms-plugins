#!/usr/bin/env python3
"""
generate_pixel_skins.py

Generate clean, pixel-perfect Bongo Cat skins using the baseline pixel template
(32x25) as the master silhouette/mask, recoloring into distinct cat color themes:
- white    : Classic White Doodle (default in pixel/)
- black    : Midnight / Black Cat (inspired by Black Witch theme)
- orange   : Ginger / Orange Tabby
- calico   : Calico / Tricolor
- siamese  : Siamese / Seal Point
- pink     : Sakura / Pastel Pink
"""

from pathlib import Path
import numpy as np
from PIL import Image

TPL_DIR = Path(__file__).resolve().parent.parent / "assets" / "skins" / "pixel"
SKINS_ROOT = Path(__file__).resolve().parent.parent / "assets" / "skins"

PALETTES = {
    "black": {
        (255, 255, 255): [70, 68, 90],
        (186, 216, 247): [58, 56, 76],
        (119, 154, 202): [89, 81, 140],
        (246, 138, 152): [230, 75, 101],
        (22, 23, 26):    [18, 16, 24],
    },
    "orange": {
        (255, 255, 255): [245, 175, 95],
        (186, 216, 247): [220, 140, 65],
        (119, 154, 202): [180, 105, 45],
        (246, 138, 152): [245, 120, 130],
        (22, 23, 26):    [60, 35, 20],
    },
    "calico": {
        # Softer warm cream with pastel orange patches and warm cocoa desk
        (255, 255, 255): [250, 246, 240], # Soft cream fur
        (186, 216, 247): [238, 195, 145], # Gentle honey/calico orange shadow
        (119, 154, 202): [145, 125, 115], # Soft warm mocha desk
        (246, 138, 152): [245, 155, 160], # Soft pink blush
        (22, 23, 26):    [48, 40, 38],    # Soft dark espresso outline
    },
    "siamese": {
        # Gentle toasted cream body with soft milk-chocolate point shadings
        (255, 255, 255): [245, 238, 228], # Warm fawn/cream fur
        (186, 216, 247): [198, 175, 158], # Soft muted beige-taupe shadow
        (119, 154, 202): [138, 115, 102], # Muted cocoa desk
        (246, 138, 152): [140, 185, 215], # Gentle soft blue accent
        (22, 23, 26):    [55, 45, 40],    # Warm dark chocolate outline
    },
    "pink": {
        (255, 255, 255): [255, 230, 238],
        (186, 216, 247): [245, 195, 210],
        (119, 154, 202): [225, 155, 175],
        (246, 138, 152): [240, 95, 130],
        (22, 23, 26):    [75, 45, 55],
    },
}

STATES = ["idle", "left", "right", "both", "sleep", "blink"]


def main():
    if not TPL_DIR.exists():
        raise FileNotFoundError(f"Template directory not found: {TPL_DIR}")

    for color_id, mapping in PALETTES.items():
        out_dir = SKINS_ROOT / f"pixel_{color_id}"
        out_dir.mkdir(parents=True, exist_ok=True)
        for state in STATES:
            tpl_path = TPL_DIR / f"{state}.png"
            tpl = Image.open(tpl_path).convert("RGBA")
            arr = np.array(tpl)
            out = arr.copy()
            for src, dst in mapping.items():
                mask = np.all(arr[:, :, :3] == src, axis=2) & (arr[:, :, 3] > 0)
                out[mask, :3] = dst

            img = Image.fromarray(out)
            img.save(out_dir / f"{state}.png", optimize=True)
            img.resize((img.width * 4, img.height * 4), Image.Resampling.NEAREST).save(
                out_dir / f"{state}@4x.png", optimize=True
            )
        print(f"Generated skin: pixel_{color_id}")


if __name__ == "__main__":
    main()
