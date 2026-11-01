"""Finishes the rendered screens: RGB (no alpha), a light dither against banding, and an overview strip.
Usage: python3 finish.py <overview.jpg or -> <png>…"""
import sys
import numpy as np
from PIL import Image

overview, files = sys.argv[1], sys.argv[2:]
rng = np.random.default_rng(7)
thumbs = []
for f in files:
    im = Image.open(f).convert('RGB')
    a = np.asarray(im).astype(np.float32)
    a += rng.uniform(-1.2, 1.2, a.shape[:2])[..., None]
    im = Image.fromarray(np.clip(a + .5, 0, 255).astype(np.uint8), 'RGB')
    im.save(f, optimize=True)
    thumbs.append(im)
if overview != '-':
    h = 900
    ts = [t.resize((round(t.width * h / t.height), h), Image.LANCZOS) for t in thumbs]
    strip = Image.new('RGB', (sum(t.width for t in ts), h))
    x = 0
    for t in ts:
        strip.paste(t, (x, 0)); x += t.width
    strip.save(overview, quality=90)
print('finished', len(files))
