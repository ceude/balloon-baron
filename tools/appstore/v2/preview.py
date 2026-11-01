"""Builds the App Preview from the frames preview.js recorded: captions in the screenshots' style, crossfades between
scenes, an end card, and a music bed with a few sound effects, all made in code. Encodes H.264 High@4.0 30 fps with
stereo AAC 256 kbps 48 kHz (Apple's App Preview spec).
Usage: python3 preview.py <frames dir> <lang> <iphone|ipad> <out.mp4>"""
import json, os, subprocess, sys, wave
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, '../../../BalloonBaron/Fonts/')
work, lang, dev, out = sys.argv[1:5]
FPS, XF = 30, 12  # crossfade frames

C = json.loads(subprocess.check_output(['node', '-e', f"console.log(JSON.stringify(require('{HERE}/captions.js')['{lang}']))"]))
loc = C['locale']

def upper(s):
    if loc.startswith('tr') or loc.startswith('az'):
        s = s.replace('i', 'İ').replace('ı', 'I')
    return s.upper()

scenes = sorted(d for d in os.listdir(work) if os.path.isdir(os.path.join(work, d)))
frames = [sorted(os.listdir(os.path.join(work, d))) for d in scenes]
first = Image.open(os.path.join(work, scenes[0], frames[0][0]))
Wd, Hd = first.size
starts, t = [], 0
for i, fr in enumerate(frames):
    starts.append(t); t += len(fr) - (XF if i < len(frames) - 1 else 0)
TOTAL = t
print(dev, Wd, Hd, 'frames', TOTAL, 'seconds', TOTAL / FPS)

def font(name, size): return ImageFont.truetype(FONTS + name, size)

def text_layer(lines, size, y0, gold=(255, 201, 90), spacing=.9, sub=None, subsize=None, pill=None):
    """An RGBA layer with a centred gold-white headline (and an optional line and pill), with a soft shadow."""
    layer = Image.new('RGBA', (Wd, Hd), (0, 0, 0, 0))
    f = font('BarlowCondensed-ExtraBold.ttf', size)
    mask = Image.new('L', (Wd, Hd), 0); d = ImageDraw.Draw(mask)
    y = y0
    for ln in lines:
        w = d.textlength(ln, font=f)
        while w > Wd * .9:
            size = int(size * .95); f = font('BarlowCondensed-ExtraBold.ttf', size); w = d.textlength(ln, font=f)
        d.text(((Wd - w) / 2, y), ln, font=f, fill=255); y += size * spacing
    bottom = y + size * .12
    if sub:
        fs = font('Barlow-Bold.ttf', subsize)
        d.text(((Wd - d.textlength(sub, font=fs)) / 2, bottom + subsize * .2), sub, font=fs, fill=255)
        bottom += subsize * 1.5
    # gradient: white at the top of each line to gold at the bottom
    g = np.zeros((Hd, Wd, 4), np.uint8)
    yy = np.arange(Hd)[:, None]
    k = ((yy - y0) % (size * spacing)) / (size * .95)
    k = np.clip(k, 0, 1)[:, :, None]
    top, mid = np.array([255, 255, 255]), np.array([255, 243, 220])
    col = np.where(k < .5, top + (mid - top) * (k / .5), mid + (np.array(gold) - mid) * ((k - .5) / .5))
    g[..., :3] = np.broadcast_to(col, (Hd, Wd, 3)).astype(np.uint8)
    g[..., 3] = np.asarray(mask)
    if sub:  # the line under the headline stays cream
        sub_rows = slice(int(y), Hd)
        g[sub_rows, :, :3] = (255, 242, 228)
    text = Image.fromarray(g, 'RGBA')
    shadow = Image.new('RGBA', (Wd, Hd), (10, 2, 22, 0))
    sm = mask.filter(ImageFilter.GaussianBlur(size * .12)).point(lambda v: int(v * .8))
    shadow.putalpha(sm)
    layer = Image.alpha_composite(layer, shadow)
    layer = Image.alpha_composite(layer, Image.new('RGBA', (Wd, Hd), (0, 0, 0, 0)).copy())
    layer.alpha_composite(text, (0, int(size * .04)))
    if pill:
        fp = font('BarlowCondensed-Bold.ttf', int(subsize * .7))
        t = '  '.join(pill)
        tw = ImageDraw.Draw(layer).textlength(t, font=fp)
        pw, ph = tw + subsize * 1.6, subsize * 1.25
        x0, y1 = (Wd - pw) / 2, bottom + subsize * .5
        dd = ImageDraw.Draw(layer)
        dd.rounded_rectangle((x0, y1, x0 + pw, y1 + ph), ph / 2, fill=(16, 8, 34, 110), outline=(255, 222, 160, 200), width=max(2, int(subsize * .06)))
        dd.text(((Wd - tw) / 2, y1 + ph * .17), t, font=fp, fill=(255, 230, 184, 255))
    return np.asarray(layer).astype(np.float32) / 255

def veil(h, a):
    v = np.zeros((Hd, 1, 1), np.float32)
    ys = np.arange(Hd)
    v[:, 0, 0] = np.clip(1 - ys / h, 0, 1) ** 1.6 * a
    return v

S = Wd / 886
caps = C['preview']
layers = [text_layer([upper(l) for l in c.split('|')], int(118 * S), int(Hd * .075)) for c in caps]
brand = C['brand']
end = text_layer([upper(brand[0])], int(150 * S), int(Hd * .5), sub=upper(brand[1]), subsize=int(52 * S), pill=[upper(C['noAds'])])
V_TOP = veil(Hd * .38, .86)

def frame_at(i):
    """The game frame at output frame i (crossfading between scenes)."""
    def get(s, j):
        j = min(max(j, 0), len(frames[s]) - 1)
        return np.asarray(Image.open(os.path.join(work, scenes[s], frames[s][j])).convert('RGB')).astype(np.float32) / 255
    for s in range(len(scenes) - 1, -1, -1):
        if i >= starts[s]:
            j = i - starts[s]
            if s > 0 and j < XF:  # still fading in from the scene before
                a = (j + 1) / (XF + 1); a = a * a * (3 - 2 * a)
                return get(s - 1, len(frames[s - 1]) - XF + j) * (1 - a) + get(s, j) * a
            return get(s, j)

def ease(x): x = min(max(x, 0), 1); return x * x * (3 - 2 * x)

END_LEN = 60  # the last scene's last frames carry the end card
proc = subprocess.Popen(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{Wd}x{Hd}', '-r', str(FPS), '-i', '-',
                         '-c:v', 'libx264', '-profile:v', 'high', '-level', '4.0', '-pix_fmt', 'yuv420p', '-preset', 'slow',
                         '-b:v', '11M', '-maxrate', '12M', '-bufsize', '24M', '-r', str(FPS), out + '.video.mp4'], stdin=subprocess.PIPE)
for i in range(TOTAL):
    img = frame_at(i)
    s = max(k for k in range(len(scenes)) if i >= starts[k]); j = i - starts[s]
    last = s == len(scenes) - 1
    n = len(frames[s]) - (0 if last else XF)
    cap_end = n - END_LEN if last else n
    # caption: fades in after the cut, out before the next one
    a = ease((j - 4) / 10) * (1 - ease((j - (cap_end - 12)) / 10))
    endA = ease((j - (n - END_LEN)) / 14) if last else 0
    vA = max(a, endA)
    img = img * (1 - V_TOP * vA)
    if endA > 0:
        img = img * (1 - .3 * endA)
    if a > 0:
        L = layers[s]
        dy = int((1 - a) * 18 * S)
        L2 = np.roll(L, dy, axis=0) if dy else L
        al = L2[..., 3:4] * a
        img = img * (1 - al) + L2[..., :3] * al
    if endA > 0:
        al = end[..., 3:4] * endA
        img = img * (1 - al) + end[..., :3] * al
    if i < 8: img = img * (i + 1) / 9  # a quick fade from black
    proc.stdin.write((np.clip(img, 0, 1) * 255 + .5).astype(np.uint8).tobytes())
proc.stdin.close(); proc.wait()

# ---------- sound: a warm pad, a plucked arpeggio, soft bass and percussion, and a few effects ----------
SR = 48000
dur = TOTAL / FPS
n = int(dur * SR)
L = np.zeros(n); R = np.zeros(n)
t = np.arange(n) / SR
rng = np.random.default_rng(3)
def hz(m): return 440 * 2 ** ((m - 69) / 12)
def add(sig, start, pan=0.0, gain=1.0):
    i0 = int(start * SR); i1 = min(n, i0 + len(sig))
    if i1 <= i0: return
    s = sig[:i1 - i0] * gain
    L[i0:i1] += s * np.cos((pan + 1) * np.pi / 4); R[i0:i1] += s * np.sin((pan + 1) * np.pi / 4)
def env(length, a, r, sustain=1.0):
    m = int(length * SR); e = np.ones(m) * sustain
    ai = int(a * SR); ri = int(r * SR)
    if ai: e[:ai] = np.linspace(0, sustain, ai)
    if ri: e[-ri:] *= np.linspace(1, 0, ri)
    return e
def tone(f, length, partials=((1, 1), (2, .35), (3, .12)), detune=0.0):
    tt = np.arange(int(length * SR)) / SR
    return sum(g * np.sin(2 * np.pi * f * k * (1 + detune) * tt) for k, g in partials)
def lowpass(x, cutoff):
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1 / np.sqrt(1 + (f / cutoff) ** 4); return np.fft.irfft(X, len(x))
def bandpass(x, lo, hi):
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= (1 / np.sqrt(1 + (f / hi) ** 4)) * (1 / np.sqrt(1 + (lo / np.maximum(f, 1)) ** 4)); return np.fft.irfft(X, len(x))

BPM = 96; beat = 60 / BPM; bar = beat * 4
# D major: Dmaj9, Bm9, Gmaj7#11-ish, A6sus — two bars each
chords = [[50, 57, 62, 66, 69, 76], [47, 54, 62, 66, 69, 73], [43, 55, 59, 62, 66, 71], [45, 52, 57, 61, 64, 69]]
nbars = int(np.ceil(dur / bar)) + 1
for b in range(0, nbars, 2):
    ch = chords[(b // 2) % 4]; st = b * bar; length = 2 * bar + 1.2
    for m in ch[1:]:
        for dt, pan in ((-.0025, -.6), (.0025, .6)):
            add(tone(hz(m), length, ((1, 1), (2, .18)), dt) * env(length, 1.0, 1.6), st, pan, .028)
    add(tone(hz(ch[0] - 12), length, ((1, 1), (2, .25))) * env(length, .08, 1.0, .9), st, 0, .09)
# the arpeggio comes in after the first bar
arp_on = bar * .75
k = 0
for b in range(nbars):
    ch = chords[(b // 2) % 4]
    for e in range(8):
        st = b * bar + e * beat / 2
        if st < arp_on or st > dur - 1.6: continue
        m = ch[[1, 2, 3, 4, 3, 2, 4, 5][e]] + 12
        pl = tone(hz(m), .9, ((1, 1), (2, .4), (3, .15), (4, .06))) * np.exp(-np.arange(int(.9 * SR)) / SR / .22)
        add(pl, st, [-.35, .35][k % 2], .05); k += 1
# soft kick on 1 and 3, a shaker on the off-beats
for b in range(nbars):
    for e in (0, 2):
        st = b * bar + e * beat
        if st < bar or st > dur - 1.4: continue
        tt = np.arange(int(.35 * SR)) / SR
        kick = np.sin(2 * np.pi * (48 * tt + 60 * (1 - np.exp(-tt * 30)) / 30)) * np.exp(-tt * 9)
        add(kick, st, 0, .18)
    for e in range(8):
        st = b * bar + e * beat / 2 + beat / 4
        if st < bar or st > dur - 1.4: continue
        sh = bandpass(rng.standard_normal(int(.08 * SR)), 5000, 12000) * np.exp(-np.arange(int(.08 * SR)) / SR / .02)
        add(sh, st, .25 if e % 2 else -.25, .05)

sec = lambda f: f / FPS
# the burner in the flight scene (frames 0-75 and 112-160 of scene 0)
for f0, f1 in ((0, 75), (112, 160)):
    length = sec(f1 - f0) + .25
    roar = lowpass(rng.standard_normal(int(length * SR)), 900) * env(length, .12, .3)
    roar += .4 * lowpass(rng.standard_normal(int(length * SR)), 260) * env(length, .1, .3)
    add(roar / (np.abs(roar).max() + 1e-9), sec(starts[0] + f0), -.1, .22)
# a soft whoosh at each cut
for s in range(1, len(scenes)):
    length = .7; x = rng.standard_normal(int(length * SR))
    sweep = np.concatenate([lowpass(x[i:i + 4800], 400 + 3000 * i / len(x)) for i in range(0, len(x), 4800)])[:len(x)]
    add(sweep / (np.abs(sweep).max() + 1e-9) * np.sin(np.linspace(0, np.pi, len(x))) ** 2, sec(starts[s]) - .35, 0, .07)
# coins as the days roll by on autopilot
ai = scenes.index(next(d for d in scenes if d.endswith('auto')))
for c in (.6, 2.4):
    for m, dl in ((88, 0), (95, .07)):
        bell = tone(hz(m), .8, ((1, 1), (2.76, .3), (5.4, .1))) * np.exp(-np.arange(int(.8 * SR)) / SR / .18)
        add(bell, sec(starts[ai]) + c + dl, .2, .05)
# fireworks at night
ni = scenes.index(next(d for d in scenes if d.endswith('night')))
for c in (.3, 1.1, 1.7, 2.4):
    length = 1.2; tt = np.arange(int(length * SR)) / SR
    pop = lowpass(rng.standard_normal(len(tt)), 2500) * np.exp(-tt * 7)
    crackle = bandpass(rng.standard_normal(len(tt)), 3000, 9000) * (rng.random(len(tt)) < .01) * np.exp(-tt * 3)
    add((pop + crackle * 3) / 3, sec(starts[ni]) + c, rng.uniform(-.5, .5), .16)

mix = np.stack([L, R], 1)
fade = np.ones(n); fi = int(.4 * SR); fo = int(1.5 * SR)
fade[:fi] = np.linspace(0, 1, fi); fade[-fo:] = np.linspace(1, 0, fo) ** 1.5
mix *= fade[:, None]
mix = np.tanh(mix * 1.1)
mix *= .89 / (np.abs(mix).max() + 1e-9)
wav = out + '.wav'
with wave.open(wav, 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((mix * 32767).astype('<i2').tobytes())
subprocess.check_call(['ffmpeg', '-y', '-loglevel', 'error', '-i', out + '.video.mp4', '-i', wav, '-map', '0:v', '-map', '1:a',
                       '-c:v', 'copy', '-c:a', 'aac', '-b:a', '256k', '-ar', '48000', '-ac', '2', '-shortest', '-movflags', '+faststart', out])
os.remove(out + '.video.mp4'); os.remove(wav)
print('wrote', out)
