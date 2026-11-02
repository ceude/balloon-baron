"""Writes <raw>/<lang>/shots.js for story.html from the app's captures (store-shots.yml): which capture stands for each
of the story's pictures, the rectangles lifted out of them ([x, y, w, h] in raw pixels; the lens [cx, cy, r]) and the
figures on the badges.
Places that are fixed in the app's layout are given per device (FIXED). What moves with the length of a language's
text (the crew list under the licence card, the rival's take-over card, the auto-advance strip) or with the moment
(the balloon in the flight) is found in the picture, so no rectangle depends on one language's words.
The badge figures are read off the captures by eye and passed in, written the way the language writes numbers; a
figure for one device only is prefixed with it (the two devices' auto-advance strips show different days):
  python3 crops.py <store-raw dir> <lang> 'iphone:IDLE=+€137,103' 'ipad:IDLE=+€146,380' 'FLEET=164' 'DAY=132' 'SHARE=99%'
AUTO_PICK='iphone=auto-3,ipad=auto-5' forces the auto-advance frames (otherwise the one with the most green takings)."""
import json, os, sys
import numpy as np
from PIL import Image

raw, lang = sys.argv[1], sys.argv[2]
VALUES = dict(a.split('=', 1) for a in sys.argv[3:] if ':' not in a.split('=')[0])
DEV_VALUES = {}
for a in sys.argv[3:]:
    k, v = a.split('=', 1)
    if ':' in k: d, k = k.split(':'); DEV_VALUES.setdefault(d, {})[k] = v
FORCE = dict(p.split('=') for p in os.environ.get('AUTO_PICK', '').split(',') if p)
DEVS = ('iphone', 'ipad')
# frames of one launch are <scene>-<n> (store-shots.txt takes them a second or so apart)
PICK = {'design': 'design-1'}
FIXED = {
    'iphone': {'studio': ['design', [40, 335, 1240, 610]], 'hold': ['holding', [24, 195, 1130, 160]]},
    'ipad': {'studio': ['design', [470, 840, 1130, 385]], 'hold': ['holding', [0, 66, 2064, 132]]},
}
CARD = {'iphone': (48, 1224), 'ipad': (366, 1334)}   # the office pages' card: left edge, width
ROW = {'iphone': 161, 'ipad': 108}                    # one pilot row
NIGHT = {'iphone': [.175, .7], 'ipad': [.13, .74]}      # the night picture without its title and morning button
AUTO = {'iphone': 'auto-run3', 'ipad': 'auto-run2'}   # story.html's name for the auto-advance picture


def img(dev, name):
    return np.asarray(Image.open(os.path.join(raw, lang, dev, name + '.png')).convert('RGB')).astype(int)


def runs(mask):
    """(start, end) of the True runs of a 1-D mask."""
    out, st = [], None
    for i, v in enumerate(list(mask) + [False]):
        if v and st is None: st = i
        if not v and st is not None: out.append((st, i)); st = None
    return out


def navy(px):
    return (px[..., 0] < 75) & (px[..., 1] < 65) & (px[..., 2] < 115) & (px[..., 2] > px[..., 0] + 15)


def frames(dev, scene):
    n, out = 0, []
    while os.path.exists(os.path.join(raw, lang, dev, f'{scene}-{n}.png')): out.append(f'{scene}-{n}'); n += 1
    return out


def crew_rows(dev):
    """The first three pilot rows: the list's white card starts under the filter chips ("All" is dark navy)."""
    a = img(dev, 'crew'); x0, w = CARD[dev]
    frac = navy(a[:, x0 + 8:x0 + 100]).mean(axis=1)
    chip = [r for r in runs(frac > .5) if r[1] - r[0] > 25][-1]
    y = chip[1]
    while a[y, x0 + 12].min() < 235: y += 1
    return ['crew', [x0, y, w, ROW[dev] * 3 + 4]]


def deal(dev):
    """The struggling rival's card and its offer to sell, down to the take-over button (the yellow-edged box)."""
    a = img(dev, 'market'); x0, w = CARD[dev]
    col = a[:, x0 + 92]
    yel = (col[:, 0] > 200) & (col[:, 1] > 140) & (col[:, 1] < 205) & (col[:, 2] < 80)
    r = runs(yel)
    top, bot = r[0][0], r[1][1]
    border = runs(np.abs(col[:top] - np.array([226, 220, 239])).sum(1) < 24)[::-1]  # the rival card's bottom, then top
    y = border[1][0]
    return ['market', [x0, y - 4, w, bot - y + 12]]


# the auto-advance strip: a translucent pill at a fixed place over the dock; BAND its rows, TEXT rows of its words
# that the chips behind it don't reach
BAND = {'iphone': (2196, 2320), 'ipad': (2322, 2404)}
TEXT = {'iphone': (2252, 2292), 'ipad': (2362, 2388)}


def mint(px):
    """The strip's green day takings (+€…)."""
    return (px[..., 0] > 80) & (px[..., 0] < 180) & (px[..., 1] > 195) & (px[..., 2] > 120) & (px[..., 2] < 200)


def auto_frame(dev):
    """The auto-advance picture: the frame whose strip shows a day's takings most clearly (green), not a day in flight."""
    y0, y1 = BAND[dev]
    if dev in FORCE: return FORCE[dev]
    best = max(frames(dev, 'auto'), key=lambda n: mint(img(dev, n)[y0:y1]).sum())
    if not mint(img(dev, best)[y0:y1]).sum(): raise SystemExit(f'{lang} {dev}: no day takings on the auto strip')
    return best


def bar(dev, name):
    a = img(dev, name); y0, y1 = BAND[dev]; t0, t1 = TEXT[dev]
    rows = a[t0:t1].astype(int)
    light = (rows.min(axis=2) > 170) | mint(rows)
    xs = np.nonzero(light.any(axis=0))[0]
    W = a.shape[1]; xs = xs[(xs > W * .12) & (xs < W * .88)]
    pad = 60 if dev == 'iphone' else 40
    return [AUTO[dev], [int(xs.min()) - pad, y0, int(xs.max() - xs.min()) + pad * 2, y1 - y0]]


def flight_frame(dev):
    """The flight picture: a frame with the balloon well up in the sky (the company's red-orange envelope; the
    others are pale) and no report over it. Returns the frame and the lens on the balloon."""
    best = None
    for n in range(0, 9):
        name = f'flight-{n}'
        if not os.path.exists(os.path.join(raw, lang, dev, name + '.png')): break
        a = img(dev, name); H, W = a.shape[:2]
        m = (a[:, :, 0] > 200) & (a[:, :, 1] > 60) & (a[:, :, 1] < 130) & (a[:, :, 2] < 90)
        m[:int(H * .1)] = False; m[int(H * .83):] = False
        m[:, int(W * .82):] = False   # the burner button
        ys, xs = np.nonzero(m)
        if len(xs) < 400: continue
        cx, cy = int(np.median(xs)), int(np.median(ys))
        report = (a[int(H * .9):, :, 0] > 230).mean() > .5 and (a[int(H * .9):, :, 1] < 130).mean() > .3
        score = abs(cy / H - .5) + (1 if report else 0)
        if best is None or score < best[0]: best = (score, name, cx, cy)
    if best is None: raise SystemExit(f'{lang} {dev}: no balloon in the flight frames')
    _, name, cx, cy = best
    r = 330 if dev == 'iphone' else 300
    return name, ['flight', [cx, cy + r // 8, r]]


def night_frame(dev):
    """The night with the most fireworks in the sky (bright, saturated sparks above the town)."""
    def sparks(name):
        a = img(dev, name)[::4, ::4].astype(float); H = a.shape[0]
        top = a[int(H * .18):int(H * .6)]
        mx, mn = top.max(axis=2), top.min(axis=2)
        return ((mx > 170) & (mx - mn > 90)).sum()
    dark = [f for f in frames(dev, 'night') if img(dev, f)[::8, ::8].mean() < 90]  # not yet the morning
    return max(dark, key=sparks)


def show_frames(dev):
    """Two moments of the Balloon Show: an early one and the last before the highlights card comes up."""
    def card(name):
        a = img(dev, name)[::4, ::4]; H, W = a.shape[:2]
        band = a[int(H * .1):int(H * .2), int(W * .1):int(W * .9)]  # the card's white top over the night sky
        return (band.min(axis=2) > 225).mean() > .3
    fs = [f for f in frames(dev, 'show') if not card(f) and img(dev, f)[::8, ::8].mean() < 70]  # still night
    return fs[1] if len(fs) > 2 else fs[0], fs[-1]


out = {'values': VALUES}
for dev in DEVS:
    if not os.path.isdir(os.path.join(raw, lang, dev)): continue
    pick = dict(PICK)
    an = auto_frame(dev); pick[AUTO[dev]] = an
    fn, lens = flight_frame(dev); pick['flight'] = fn
    pick['night'] = night_frame(dev)
    pick['show-6'], pick['show-20'] = show_frames(dev)
    src = dict(FIXED[dev], rows=crew_rows(dev), deal=deal(dev), bar=bar(dev, an), lens=lens)
    out[dev] = {'pick': pick, 'src': src, 'night': NIGHT[dev], 'values': DEV_VALUES.get(dev, {})}
    print(lang, dev, json.dumps(pick), json.dumps(src))
with open(os.path.join(raw, lang, 'shots.js'), 'w') as f:
    f.write('/* written by tools/appstore/v2/crops.py */\nvar SHOTS = ' + json.dumps(out, ensure_ascii=False, indent=1) + ';\n')
