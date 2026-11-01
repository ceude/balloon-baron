#!/usr/bin/env python3
"""Shrinks the App Review screenshots: 256-colour palette PNGs (only Apple's reviewer sees them).
Usage: python3 tools/appstore/asc/review/compress.py [src dir] [dst dir]   (default: this folder, in place)"""
import pathlib
import sys

from PIL import Image

here = pathlib.Path(__file__).resolve().parent
src = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else here
dst = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else src
dst.mkdir(parents=True, exist_ok=True)
for f in sorted(src.glob("*.png")):
    im = Image.open(f).convert("RGB")
    q = im.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
    out = dst / f.name
    q.save(out, optimize=True)
    print(f"{out.name}: {im.size[0]}x{im.size[1]} {out.stat().st_size // 1024} KB")
