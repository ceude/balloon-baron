/* Shared pieces for the Instagram reels (reels.html): the beat clock, the dawn world with its parallax layers and
   balloons, the rival boss, chat bubbles, kinetic type, phones with real game footage, the world map and the end card.
   Draws on the global `ctx` with art.js / art2.js helpers (the App Store set's look). */
W = 1080; H = 1920;
let ctx;
const FPS = 30, BPM = 120, BEAT = FPS * 60 / BPM; /* 15 frames: every cut lands on a frame */
const ACC = '#ff6a3d', GOLD = '#ffc95a';
/* language: 'en', or 'tr' with TR_TEXT (tr.js). Every word goes through tx() where it is drawn, so the reels'
   timelines stay one. A word missing from the table is listed in MISSING (render.js reports it). */
let LANG = 'en';
const MISSING = new Set();
function tx(s) {
  if (LANG === 'en' || typeof s !== 'string' || !/[A-Za-z]/.test(s)) return s;
  if (TR_TEXT[s] !== undefined) return TR_TEXT[s];
  if (!tx.done) { tx.done = new Set(Object.values(TR_TEXT)); }
  if (!tx.done.has(s)) MISSING.add(s);
  return s;
}

/* ---------- time ---------- */
const prog = (f, a, b) => clamp((f - a) / (b - a), 0, 1);
const eOut = k => 1 - Math.pow(1 - k, 3);
const eIn = k => k * k * k;
const eIO = k => k < .5 ? 4 * k * k * k : 1 - Math.pow(-2 * k + 2, 3) / 2;
const eBack = (k, s = 2.2) => { const c = s + 1; return 1 + c * Math.pow(k - 1, 3) + s * Math.pow(k - 1, 2); };
const eExpo = k => k >= 1 ? 1 : 1 - Math.pow(2, -10 * k);
const B = n => Math.round(n * BEAT); /* beats to frames */
/* 0..1 decay after each beat (for pulses) */
const beatPulse = (f, from = 0) => f < from ? 0 : Math.exp(-((f - from) % BEAT) / 3.5);

/* ---------- canvases ---------- */
function layer(w, h, fn) {
  const c = document.createElement('canvas'); c.width = w; c.height = h;
  const o = [ctx, W, H]; ctx = c.getContext('2d'); W = w; H = h; fn(); [ctx, W, H] = o; return c;
}

/* ---------- game footage ---------- */
let CLIPS = {}, CLIPDIR = '';
const IMGC = new Map();
function loadImg(src) {
  if (IMGC.has(src)) return IMGC.get(src);
  const p = new Promise((res, rej) => { const i = new Image(); i.onload = () => res(i); i.onerror = () => rej(new Error('img ' + src)); i.src = src; });
  IMGC.set(src, p);
  if (IMGC.size > 260) IMGC.delete(IMGC.keys().next().value);
  return p;
}
/* frame of clip `id` at t seconds into it (speed x), clamped to the clip */
function clip(id, t, speed = 1, start = 0) {
  const n = CLIPS[id]; if (!n) throw new Error('no clip ' + id);
  const i = clamp(Math.floor(start + t * FPS * speed), 0, n - 1);
  return loadImg(`${CLIPDIR}/${id}/${String(i).padStart(4, '0')}.jpg`);
}
/* footage filling the screen; zoom about (fx, fy) of the picture */
function cover(img, zoom = 1, fx = .5, fy = .5, dx = 0, dy = 0) {
  const s = Math.max(W / img.width, H / img.height) * zoom, w = img.width * s, h = img.height * s;
  const x = W / 2 - fx * w + (fx - .5) * W * 0 + dx, y = H / 2 - fy * h + dy;
  ctx.drawImage(img, clamp(x, W - w, 0), clamp(y, H - h, 0), w, h);
}
function phoneShot(img, cx, cy, w, rot = 0) {
  const h = w * img.height / img.width;
  device('iphone', cx - w / 2, cy - h / 2, w, h, img, { rot, shadow: 'rgba(8,2,20,.7)' });
}

/* ---------- type ---------- */
/* `*word*` in a line is set in the accent colour */
function segs(line) { return line.split(/(\*[^*]+\*)/).filter(Boolean).map(s => s[0] === '*' ? { t: s.slice(1, -1), acc: 1 } : { t: s }); }
function fitSize(lines, size, maxW, font = s => `800 ${s}px BC`) {
  ctx.save(); ctx.font = font(size); ctx.letterSpacing = `${-size * .01}px`;
  const wd = Math.max(...lines.map(l => ctx.measureText(l.replace(/\*/g, '')).width)); ctx.restore();
  return wd > maxW ? Math.floor(size * maxW / wd) : size;
}
/* Headline lines punched in one after another. o: f0 (start frame), stagger, size, maxW, out (exit frame), gold,
   acc (accent colour), from ('punch' | 'up' | 'slam'), lh, align */
function kinetic(f, lines, cx, y, o = {}) {
  lines = lines.map(tx);
  const size = fitSize(lines, o.size || 150, o.maxW || (LANG === 'tr' ? 780 : 860)) /* Turkish runs longer: keep it inside the right margin */, lh = size * (o.lh || .92), f0 = o.f0 || 0, st = o.stagger ?? 4;
  let yy = y;
  lines.forEach((line, i) => {
    yy += lh; const a = f0 + i * st; if (f < a) return;
    const k = prog(f, a, a + (o.dur || 7)); let s = 1, alpha = clamp((f - a) / 2.5, 0, 1), oy = 0, rot = 0;
    if ((o.from || 'punch') === 'punch') s = lerp(1.7, 1, eBack(k, 1.6));
    else if (o.from === 'up') { oy = (1 - eOut(k)) * size * .6; alpha = eOut(k); }
    else if (o.from === 'slam') { s = lerp(3.2, 1, eOut(k)); rot = (1 - eOut(k)) * -.08; }
    if (o.out != null && f > o.out) { const q = prog(f, o.out, o.out + 5); alpha *= 1 - q; s *= 1 + q * .25; }
    if (alpha <= 0) return;
    ctx.save(); ctx.translate(cx, yy - size * .35 + oy); ctx.rotate(rot + (o.tilt || 0)); ctx.scale(s, s); ctx.globalAlpha = alpha;
    drawLine(line, 0, size * .35, size, o);
    ctx.restore();
  });
  return yy;
}
function drawLine(line, cx, y, size, o = {}) {
  line = tx(line);
  ctx.font = `800 ${size}px BC`; ctx.letterSpacing = `${-size * .01}px`; ctx.textAlign = 'left'; ctx.textBaseline = 'alphabetic';
  const parts = segs(line), ws = parts.map(p => ctx.measureText(p.t).width), tot = ws.reduce((a, b) => a + b, 0);
  let x = o.align === 'left' ? cx : cx - tot / 2;
  parts.forEach((p, i) => {
    /* a dark edge and a soft shadow keep it legible over anything */
    ctx.lineJoin = 'round'; ctx.strokeStyle = 'rgba(22,6,34,.55)'; ctx.lineWidth = size * .1;
    ctx.shadowColor = 'rgba(12,2,24,.65)'; ctx.shadowBlur = size * .25; ctx.shadowOffsetY = size * .05;
    ctx.strokeText(p.t, x, y); ctx.shadowColor = 'transparent';
    const g = ctx.createLinearGradient(0, y - size * .75, 0, y + size * .05);
    if (p.acc || o.allAcc) { g.addColorStop(0, '#ffd0a8'); g.addColorStop(.45, o.acc || ACC); g.addColorStop(1, mix(o.acc || ACC, '#c0262a', .35)); }
    else { g.addColorStop(0, '#ffffff'); g.addColorStop(.5, '#fff3dc'); g.addColorStop(1, o.gold || GOLD); }
    ctx.fillStyle = g; ctx.fillText(p.t, x, y);
    x += ws[i];
  });
}
/* small tracked label (kickers, name tags) */
function label(text, x, y, size, color = '#ffe6b8', o = {}) {
  text = tx(text);
  ctx.save(); ctx.font = `${o.w || 700} ${size}px ${o.font || 'BC'}`; ctx.letterSpacing = `${size * (o.track ?? .16)}px`; ctx.textAlign = o.align || 'center';
  ctx.shadowColor = 'rgba(10,2,20,.7)'; ctx.shadowBlur = size * .4; ctx.fillStyle = color; ctx.globalAlpha = o.alpha ?? 1;
  ctx.fillText(text, x + (o.align === 'left' ? 0 : size * (o.track ?? .16) / 2), y); ctx.restore();
}
function fmt(n) { return Math.round(n).toLocaleString(LANG === 'tr' ? 'tr-TR' : 'en-US'); }

/* ---------- finishing ---------- */
let NOISE;
function grainOverlay(f, a = .07) {
  if (!NOISE) NOISE = layer(512, 512, () => { const d = ctx.createImageData(512, 512), R = mulberry32(9); for (let i = 0; i < d.data.length; i += 4) { const v = 128 + (R() - .5) * 255; d.data[i] = d.data[i + 1] = d.data[i + 2] = v; d.data[i + 3] = 255; } ctx.putImageData(d, 0, 0); });
  const R = mulberry32(f * 31 + 7), ox = -Math.floor(R() * 512), oy = -Math.floor(R() * 512);
  ctx.save(); ctx.globalAlpha = a; ctx.globalCompositeOperation = 'overlay';
  for (let x = ox; x < W; x += 512) for (let y = oy; y < H; y += 512) ctx.drawImage(NOISE, x, y);
  ctx.restore();
}
function vig(a = .5) {
  const g = ctx.createRadialGradient(W / 2, H * .5, H * .3, W / 2, H * .5, H * .75); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, `rgba(10,2,20,${a})`);
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
}
function flash(f, at, a = .85, len = 6, col = '255,244,226') { if (f < at || f > at + len) return; ctx.fillStyle = `rgba(${col},${a * (1 - (f - at) / len)})`; ctx.fillRect(0, 0, W, H); }
/* top and bottom shade so words read over footage */
function shade(top = .5, bot = .4, a = .55) {
  let g = ctx.createLinearGradient(0, 0, 0, H * top); g.addColorStop(0, `rgba(14,4,28,${a})`); g.addColorStop(1, 'rgba(14,4,28,0)'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H * top);
  g = ctx.createLinearGradient(0, H * (1 - bot), 0, H); g.addColorStop(0, 'rgba(14,4,28,0)'); g.addColorStop(1, `rgba(14,4,28,${a})`); ctx.fillStyle = g; ctx.fillRect(0, H * (1 - bot), W, H * bot);
}
function shakeAt(f, hits, amp = 22) {
  let x = 0, y = 0;
  for (const h of hits) if (f >= h) { const k = Math.exp(-(f - h) / 3.2); x += Math.sin((f - h) * 2.7 + h) * amp * k; y += Math.cos((f - h) * 3.3 + h) * amp * k; }
  return [x, y];
}

/* ---------- the dawn world ---------- */
const SKYC = ['#141a4a', '#4a2a6c', '#c8506a', '#ff9a6a', '#ffd49a'];
const DESIGNS = [
  { cols: ['#ff5e3a', '#ffc23d'], pattern: 'band', pc: ['#2b2350', '#ffffff'] },
  { cols: ['#5aa9e6', '#f2f8ff'], pattern: 'chevron', pc: ['#ffc23d', '#e5432f'] },
  { cols: ['#9b7be0', '#f4eeff'], pattern: 'stars', pc: ['#2b2350', '#ffc23d'] },
  { cols: ['#e5432f', '#ffffff'], pattern: 'diamond', pc: ['#ffc23d', '#2b2350'] },
  { cols: ['#22a45d', '#fff3b0'], pattern: 'rings', pc: ['#ffffff', '#e5432f'] },
  { cols: ['#ff6fa8', '#fff0f6'], pattern: 'band', pc: ['#9b7be0', '#ffffff'] },
  { cols: ['#2b2350', '#ffc23d'], pattern: 'sun', pc: ['#ffc23d', '#ff5e3a'] },
  { cols: ['#3ad0c0', '#1f6f8b'], pattern: 'chevron', pc: ['#ffffff', '#ffc23d'] },
  { cols: ['#ffc23d', '#e5432f'], pattern: 'band', pc: ['#2b2350', '#ffffff'] },
  { cols: ['#14a39a', '#e8fff9'], pattern: 'diamond', pc: ['#ff5e3a', '#ffffff'] },
];
/* the rival's colours: royal purple and gold, a crown on top (no words, no logo) */
const RIVAL_D = { cols: ['#4a1f7a', '#2e1250'], pattern: 'crown', pc: ['#e8b03a', '#ffe08a'] };
const SPR_R = 150;
function balloonSprite(d, hz = 0, people = 3, R = SPR_R) {
  const c = layer(Math.ceil(R * 2.5), Math.ceil(R * 3.55), () => {
    balloon2(R * 1.25, R * 1.15, R, { cols: d.cols, pattern: d.pattern, pc: d.pc, burn: 0, people, light: 1, sky: '#ff9a7a', rim: '#ffe2b8', gores: 16, haze: hz, hazeColor: '#e88a7a' });
  });
  c.R = R; return c;
}
let SPRITES, RIVAL_SPR;
function sprites() {
  if (SPRITES) return SPRITES;
  SPRITES = { near: DESIGNS.map(d => balloonSprite(d)), mid: DESIGNS.map(d => balloonSprite(d, .38, 0)) };
  RIVAL_SPR = balloonSprite(RIVAL_D, 0, 2, 320);
  /* the hero, drawn big for close-ups */
  SPRITES.hero = balloonSprite({ cols: ['#ff5e3a', '#ffc23d'], pattern: 'chevron', pc: ['#e5432f', '#fff3dc'] }, 0, 4, 520);
  return SPRITES;
}
/* a sprite balloon whose envelope centre is (x, y), radius r; flame when burn > 0 */
function spriteBalloon(spr, x, y, r, burn = 0, t = 0) {
  const k = r / spr.R;
  ctx.drawImage(spr, x - spr.R * 1.25 * k, y - spr.R * 1.15 * k, spr.width * k, spr.height * k);
  if (burn > 0) {
    const fy = y + r * (1.45 + .6 - .2), s = r * .55 * burn * (.85 + .15 * Math.sin(t * 40 + x));
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    const gl = ctx.createRadialGradient(x, fy - s * .5, 0, x, fy - s * .5, s * 3);
    gl.addColorStop(0, `rgba(255,200,110,${.7 * burn})`); gl.addColorStop(.3, `rgba(255,140,50,${.25 * burn})`); gl.addColorStop(1, 'rgba(255,100,30,0)');
    ctx.fillStyle = gl; ctx.fillRect(x - s * 3, fy - s * 3.5, s * 6, s * 6);
    /* the envelope lit from inside */
    const eg = ctx.createRadialGradient(x, y + r * 1.2, 0, x, y + r * .6, r * 1.4);
    eg.addColorStop(0, `rgba(255,170,80,${.35 * burn})`); eg.addColorStop(1, 'rgba(255,120,40,0)');
    ctx.fillStyle = eg; ctx.fillRect(x - r * 1.4, y - r * 1.2, r * 2.8, r * 2.8);
    ctx.restore();
    flame2(x, fy, s);
  }
}

/* World space: x 0..W (plus margins), y 0..WH; the horizon at HZ. A camera {x, y, z} looks at the window
   [cam.y, cam.y + H]; a layer with parallax p moves p times as far. */
const WH = 3700, HZ = 2380, MARGIN = 420, YREF = 900; /* at cam.y = YREF every layer lines up (horizon at screen 1480) */
let DAWN;
function buildDawn() {
  if (DAWN) return DAWN;
  sprites();
  const LW = W + MARGIN * 2;
  const sky = layer(LW, WH, () => {
    const g = ctx.createLinearGradient(0, 0, 0, HZ + 200);
    g.addColorStop(0, '#0f1440'); g.addColorStop(.3, '#2a2462'); g.addColorStop(.55, '#6a3274'); g.addColorStop(.75, '#d0566a'); g.addColorStop(.88, '#ff9a6a'); g.addColorStop(1, '#ffd8a0');
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, WH);
    /* stars fading into the dawn */
    const R = mulberry32(3); for (let i = 0; i < 260; i++) { const x = R() * W, y = R() * HZ * .45, a = (1 - y / (HZ * .45)) * (.3 + R() * .6); ctx.fillStyle = `rgba(255,248,230,${a})`; ctx.beginPath(); ctx.arc(x, y, .6 + R() * 1.6, 0, 7); ctx.fill(); }
    /* long soft cloud bands lit from below */
    const R2 = mulberry32(8);
    for (let i = 0; i < 26; i++) {
      const y = HZ * (.35 + R2() * .55), x = R2() * W, w = 500 + R2() * 900, h = w * (.03 + R2() * .04), c = mix('#ffb48a', '#8a4a8a', 1 - (y / HZ - .35) / .55);
      const gg = ctx.createRadialGradient(x, y, 0, x, y, w / 2); gg.addColorStop(0, rgba(c, .32)); gg.addColorStop(1, rgba(c, 0));
      ctx.save(); ctx.translate(x, y); ctx.scale(1, h / (w / 2)); ctx.translate(-x, -y); ctx.fillStyle = gg; ctx.fillRect(x - w / 2, y - w / 2, w, w); ctx.restore();
    }
  });
  const ridges = layer(LW, WH, () => {
    ridge(HZ + 40, 120, '#b8607a', 4, 18); ridge(HZ + 90, 90, '#9a4c72', 6, 18);
    ctx.fillStyle = '#7a3a64'; ctx.fillRect(0, HZ + 80, W, WH);
  });
  const field = (n, minH, maxH, base, seed, lit, dark, hz) => layer(LW, WH, () => {
    const R = mulberry32(seed), items = [];
    for (let i = 0; i < n; i++) items.push({ x: R() * W, h: minH + R() * (maxH - minH), b: base + R() * 40 });
    items.sort((a, b) => a.h - b.h);
    for (const it of items) chimney(it.x, it.b, it.h * (.34 + R() * .1), it.h, { seed: seed + it.x | 0, light: 1, lit, dark, rim: '#ffd59a', windows: it.h > 300 ? 2 : 0, haze: hz, hazeColor: '#e08a80' });
    const gg = ctx.createLinearGradient(0, base + 20, 0, base + 600); gg.addColorStop(0, mix(dark, lit, .25)); gg.addColorStop(1, mix(dark, '#120818', .5));
    ctx.fillStyle = gg; ctx.fillRect(0, base + 20, W, WH);
  });
  const far = field(Math.round(90 * W / 1080), 60, 170, HZ + 120, 21, '#d88a7a', '#7a3a5a', .35);
  const mid = field(Math.round(36 * W / 1080), 180, 380, HZ + 260, 33, '#e6a27a', '#5a2c44', .12);
  const near = layer(LW, WH, () => {
    const R = mulberry32(55);
    for (const [x, h] of [[60, 820], [260, 520], [LW - 120, 900], [LW - 330, 560], [LW * .52, 380], [LW * .36, 300], [LW * .7, 330]])
      chimney(x, 2930 + R() * 40, h * .36, h, { seed: x | 0, light: 1, lit: '#c9806a', dark: '#2a1426', rim: '#ffcf8a', windows: 3 });
    const g = ctx.createLinearGradient(0, 2900, 0, 3300); g.addColorStop(0, '#3a1a34'); g.addColorStop(1, '#1a0a1c'); ctx.fillStyle = g; ctx.fillRect(0, 2950, W, WH);
  });
  /* the balloons: depth d (0 far .. 1 near), world position, sway */
  const R = mulberry32(17), bal = [];
  for (let i = 0, n = Math.round(90 * W / 1080); i < n; i++) {
    const d = Math.pow(R(), 1.9);
    bal.push({ x: R() * LW - MARGIN, y: lerp(250, HZ - 60, Math.pow(R(), .7)), d, s: Math.floor(R() * DESIGNS.length), ph: R() * 9, v: 8 + R() * 18, burnPh: R() * 9, rank: R(), c: COLS2[Math.floor(R() * COLS2.length)], st: COLS2[Math.floor(R() * COLS2.length)] });
  }
  bal.sort((a, b) => a.d - b.d);
  DAWN = { sky, ridges, far, mid, near, bal, LW };
  return DAWN;
}
const COLS2 = ['#ff5e3a', '#ffc23d', '#14a39a', '#9b7be0', '#e5432f', '#5aa9e6', '#22a45d', '#ff6fa8', '#3ad0c0'];
function camLayer(img, cam, p) {
  const z = 1 + (cam.z - 1) * p;
  ctx.save(); ctx.translate(W / 2, H / 2); ctx.scale(z, z); ctx.translate(-W / 2, -H / 2);
  ctx.drawImage(img, -MARGIN - cam.x * p, -(YREF + (cam.y - YREF) * p)); ctx.restore();
}
function camPt(x, y, cam, p) {
  const z = 1 + (cam.z - 1) * p;
  return [W / 2 + (x - cam.x * p - W / 2) * z, H / 2 + (y - (YREF + (cam.y - YREF) * p) - H / 2) * z, z];
}
/* o: t (seconds), cam, count (how many balloons are up), rise (0..1: the whole fleet lifting from the ground),
   sun ([x, y] in world), extra(depthBand) hook to draw things between layers */
function dawn(o) {
  const D = buildDawn(), cam = o.cam, t = o.t;
  camLayer(D.sky, cam, .12);
  /* the sun and its rays, just over the horizon */
  const [sx, sy] = camPt(o.sun ? o.sun[0] : W * .62, o.sun ? o.sun[1] : HZ - 30, cam, .2);
  rays(sx, sy, 34, 2200, '#ffd6a0', .07, 12 + Math.floor(t * 0) );
  ctx.save(); ctx.translate(sx, sy); ctx.rotate(t * .02); ctx.translate(-sx, -sy); rays(sx, sy, 18, 2600, '#fff0c8', .05, 40); ctx.restore();
  sun(sx, sy, 70);
  camLayer(D.ridges, cam, .3);
  const band = (lo, hi, p0, p1) => {
    for (const b of D.bal) {
      if (b.d < lo || b.d >= hi) continue;
      if (o.count != null && D.bal.indexOf(b) >= o.count) continue;
      const p = lerp(p0, p1, (b.d - lo) / (hi - lo)), r = lerp(10, 170, Math.pow(b.d, 2.3));
      const lift = o.lift ? o.lift(b) : o.rise != null ? (1 - eIO(clamp(o.rise * 1.6 - (1 - b.d) * .3 - (b.ph % 1) * .3, 0, 1))) * 1200 * (.4 + b.d) : 0;
      let [x, y, z] = camPt(b.x + Math.sin(t * .5 + b.ph) * 12 * b.d, b.y - t * b.v * (.3 + b.d) + lift, cam, p);
      const rr = r * z; if (y < -rr * 3 || y > H + rr * 2 || x < -rr * 2 || x > W + rr * 2) continue;
      if (b.d < .28) farBalloon(x, y, rr, b.c, .55 - b.d, '#d07a84', { stripe: b.st });
      else {
        const burn = b.d > .55 && Math.sin(t * 1.7 + b.burnPh) > .35 ? 1 : 0;
        spriteBalloon(b.d < .5 ? SPRITES.mid[b.s] : SPRITES.near[b.s], x, y, rr, burn * (o.burn ?? 1), t);
      }
    }
  };
  band(0, .28, .3, .45);
  camLayer(D.far, cam, .5);
  band(.28, .55, .5, .75);
  camLayer(D.mid, cam, .8);
  if (o.extra) o.extra('mid');
  band(.55, 1.01, .8, 1.2);
  camLayer(D.near, cam, 1.25);
  if (o.extra) o.extra('near');
}

/* ---------- the rival: Victor Smugg, boss of Smugg Air (made up) ---------- */
/* e: { shock 0..1, laugh 0..1, talk 0..1 (mouth open), look -1..1, sweat 0..1 }. Head radius 100·s at (cx, cy). */
function rival(cx, cy, s, e = {}) {
  const sh = e.shock || 0, la = e.laugh || 0, tk = e.talk || 0, look = e.look ?? .4;
  ctx.save(); ctx.translate(cx, cy); ctx.scale(s * 100, s * 100); ctx.rotate((e.tilt || 0) + la * Math.sin((e.t || 0) * 18) * .03);
  const lw = 1 / (s * 100);
  /* suit */
  let g = ctx.createLinearGradient(-2, 1, 2, 3); g.addColorStop(0, '#5a2a8a'); g.addColorStop(1, '#2a1048');
  ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(-2.3, 3.2); ctx.bezierCurveTo(-2.2, 1.9, -1.7, 1.35, -.6, 1.15); ctx.lineTo(.6, 1.15); ctx.bezierCurveTo(1.7, 1.35, 2.2, 1.9, 2.3, 3.2); ctx.closePath(); ctx.fill();
  /* shirt and gold cravat */
  ctx.fillStyle = '#fff6ea'; ctx.beginPath(); ctx.moveTo(-.55, 1.12); ctx.lineTo(.55, 1.12); ctx.lineTo(0, 2.4); ctx.closePath(); ctx.fill();
  g = ctx.createLinearGradient(-.3, 1.2, .3, 2); g.addColorStop(0, '#ffd56a'); g.addColorStop(1, '#c8861e');
  ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(-.32, 1.2); ctx.quadraticCurveTo(0, 1.38, .32, 1.2); ctx.lineTo(.18, 1.5); ctx.quadraticCurveTo(.28, 1.9, 0, 2.15); ctx.quadraticCurveTo(-.28, 1.9, -.18, 1.5); ctx.closePath(); ctx.fill();
  ctx.fillStyle = '#7a2a8a'; for (const [x, y] of [[0, 1.55], [-.08, 1.8], [.09, 1.75]]) { ctx.beginPath(); ctx.arc(x, y, .045, 0, 7); ctx.fill(); }
  /* lapels with gold piping */
  for (const sd of [-1, 1]) {
    ctx.fillStyle = '#3a1660'; ctx.beginPath(); ctx.moveTo(sd * .58, 1.12); ctx.lineTo(sd * 1.05, 1.5); ctx.lineTo(sd * .62, 1.75); ctx.lineTo(sd * .9, 1.9); ctx.lineTo(sd * .1, 2.9); ctx.lineTo(sd * .05, 2.5); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = '#e8b03a'; ctx.lineWidth = .045; ctx.stroke();
  }
  /* a little gold crown pin */
  ctx.fillStyle = '#ffcf4a'; ctx.beginPath(); const px = -1.05, py = 2.05; ctx.moveTo(px - .16, py + .1); ctx.lineTo(px - .18, py - .1); ctx.lineTo(px - .08, py); ctx.lineTo(px, py - .14); ctx.lineTo(px + .08, py); ctx.lineTo(px + .18, py - .1); ctx.lineTo(px + .16, py + .1); ctx.closePath(); ctx.fill();
  /* neck */
  ctx.fillStyle = '#d8946e'; ctx.fillRect(-.36, .75, .72, .5);
  /* ears */
  for (const sd of [-1, 1]) { ctx.fillStyle = '#e8a77e'; ctx.beginPath(); ctx.ellipse(sd * .93, .12, .17, .25, sd * .2, 0, 7); ctx.fill(); ctx.fillStyle = 'rgba(160,70,50,.35)'; ctx.beginPath(); ctx.ellipse(sd * .95, .14, .07, .13, 0, 0, 7); ctx.fill(); }
  /* head */
  const head = new Path2D(); head.moveTo(0, -1.02); head.bezierCurveTo(.62, -1.02, .95, -.62, .95, -.05); head.bezierCurveTo(.95, .55, .62, 1.0, 0, 1.02); head.bezierCurveTo(-.62, 1.0, -.95, .55, -.95, -.05); head.bezierCurveTo(-.95, -.62, -.62, -1.02, 0, -1.02);
  g = ctx.createRadialGradient(.35, -.3, .1, .1, 0, 1.3); g.addColorStop(0, '#ffd8b4'); g.addColorStop(.6, '#f0b088'); g.addColorStop(1, '#c87a5a');
  ctx.fillStyle = g; ctx.fill(head);
  ctx.save(); ctx.clip(head);
  ctx.fillStyle = 'rgba(255,120,110,.28)'; for (const sd of [-1, 1]) { ctx.beginPath(); ctx.ellipse(sd * .52, .32, .2, .13, 0, 0, 7); ctx.fill(); }
  ctx.fillStyle = 'rgba(255,220,170,.5)'; ctx.fillRect(.85, -1, .2, 2); /* warm rim from the sunrise */
  ctx.restore();
  /* hair: a slick silver-streaked pompadour */
  g = ctx.createLinearGradient(-1, -1.4, 1, -.4); g.addColorStop(0, '#2a1a2e'); g.addColorStop(1, '#46304a');
  ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(-.98, -.05); ctx.bezierCurveTo(-1.08, -.85, -.6, -1.38, .1, -1.4); ctx.bezierCurveTo(.75, -1.42, 1.15, -1.1, 1.0, -.55); ctx.bezierCurveTo(.98, -.3, .96, -.15, .94, -.05);
  ctx.bezierCurveTo(.9, -.55, .6, -.72, .2, -.7); ctx.bezierCurveTo(-.3, -.72, -.75, -.6, -.98, -.05); ctx.fill();
  ctx.strokeStyle = 'rgba(220,220,240,.55)'; ctx.lineWidth = .06; ctx.beginPath(); ctx.moveTo(-.55, -1.05); ctx.bezierCurveTo(-.1, -1.32, .5, -1.3, .85, -.95); ctx.stroke();
  /* aviator goggles on the forehead */
  ctx.strokeStyle = '#5a3a28'; ctx.lineWidth = .13; ctx.beginPath(); ctx.moveTo(-.98, -.62); ctx.quadraticCurveTo(0, -.9, .98, -.62); ctx.stroke();
  for (const sd of [-1, 1]) {
    const gx = sd * .32, gy = -.82 + (sh ? -sh * .12 : 0);
    ctx.fillStyle = '#d9a441'; ctx.beginPath(); ctx.ellipse(gx, gy, .24, .19, 0, 0, 7); ctx.fill();
    const lg = ctx.createLinearGradient(gx - .2, gy - .15, gx + .2, gy + .15); lg.addColorStop(0, '#bff4ff'); lg.addColorStop(.5, '#3a8aa8'); lg.addColorStop(1, '#1a3a5a');
    ctx.fillStyle = lg; ctx.beginPath(); ctx.ellipse(gx, gy, .17, .13, 0, 0, 7); ctx.fill();
    ctx.fillStyle = 'rgba(255,255,255,.8)'; ctx.beginPath(); ctx.ellipse(gx - .06, gy - .05, .05, .03, -.5, 0, 7); ctx.fill();
  }
  /* brows: one cocked up when smug, both high when shocked */
  ctx.strokeStyle = '#2a1a2e'; ctx.lineCap = 'round'; ctx.lineWidth = .13;
  const bl = lerp(-.42, -.62, sh), br = lerp(-.52, -.62, sh), tiltL = lerp(-.12, .08, sh), tiltR = lerp(.14, -.08, sh);
  ctx.beginPath(); ctx.moveTo(-.62, bl + tiltL + la * .05); ctx.quadraticCurveTo(-.4, bl - .12, -.16, bl - tiltL); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(.16, br - tiltR + la * .05); ctx.quadraticCurveTo(.4, br - .2 * (1 - sh) - .1, .62, br + tiltR); ctx.stroke();
  /* eyes */
  for (const sd of [-1, 1]) {
    const ex = sd * .38, ey = -.2;
    if (la > .5) { ctx.strokeStyle = '#2a1a2e'; ctx.lineWidth = .08; ctx.beginPath(); ctx.arc(ex, ey + .06, .13, Math.PI * 1.1, Math.PI * 1.9); ctx.stroke(); continue; }
    const rw = lerp(.17, .2, sh), rh = lerp(.12, .21, sh);
    ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.ellipse(ex, ey, rw, rh, 0, 0, 7); ctx.fill();
    ctx.save(); ctx.beginPath(); ctx.ellipse(ex, ey, rw, rh, 0, 0, 7); ctx.clip();
    const pr = lerp(.085, .055, sh);
    ctx.fillStyle = '#3a2418'; ctx.beginPath(); ctx.arc(ex + look * .06 * (1 - sh), ey + .01, pr, 0, 7); ctx.fill();
    ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(ex + look * .06 * (1 - sh) - .025, ey - .025, pr * .35, 0, 7); ctx.fill();
    /* the heavy, unimpressed upper lid */
    const lid = lerp(.45, 0, sh);
    ctx.fillStyle = '#e09a74'; ctx.fillRect(ex - .3, ey - .3, .6, .3 + rh * (2 * lid - 1) + .01);
    ctx.restore();
    ctx.strokeStyle = '#4a2a28'; ctx.lineWidth = .035; ctx.beginPath(); ctx.moveTo(ex - rw, ey + rh * (2 * lid - 1) * (1 - sh) - sh * .0); ctx.lineTo(ex + rw, ey + rh * (2 * lid - 1) * (1 - sh)); if (lid > .05) ctx.stroke();
  }
  /* nose */
  g = ctx.createRadialGradient(.04, .12, .02, 0, .15, .26); g.addColorStop(0, '#ffc8a0'); g.addColorStop(1, '#d88a64');
  ctx.fillStyle = g; ctx.beginPath(); ctx.ellipse(0, .14, .17, .2, 0, 0, 7); ctx.fill();
  /* mouth */
  const my = .55;
  if (la > .02 || tk > .02 || sh > .02) {
    const open = Math.max(la * (.75 + .25 * Math.sin((e.t || 0) * 22)), tk * .5, sh * .9);
    const mw = lerp(.32, .2, sh), mh = .08 + open * .3;
    ctx.fillStyle = '#5a1420'; ctx.beginPath();
    if (sh > .5) ctx.ellipse(0, my + mh * .3, mw * .8, mh, 0, 0, 7);
    else { ctx.moveTo(-mw, my - .02); ctx.quadraticCurveTo(0, my + .04, mw, my - .06); ctx.quadraticCurveTo(mw * .6, my + mh * 1.6, 0, my + mh * 1.5); ctx.quadraticCurveTo(-mw * .7, my + mh * 1.5, -mw, my - .02); }
    ctx.fill();
    ctx.save(); ctx.clip(); ctx.fillStyle = '#fff'; ctx.fillRect(-mw, my - .1, mw * 2, .1 + (sh > .5 ? 0 : .02)); ctx.fillStyle = '#ffcf4a'; ctx.fillRect(mw * .25, my - .1, .07, .12); /* gold tooth */
    ctx.fillStyle = '#e0505a'; ctx.beginPath(); ctx.ellipse(0, my + mh * 1.3, mw * .5, mh * .5, 0, 0, 7); ctx.fill(); ctx.restore();
  } else {
    /* the smirk: one corner up */
    ctx.strokeStyle = '#6a2a28'; ctx.lineWidth = .07; ctx.beginPath(); ctx.moveTo(-.26, my + .02); ctx.quadraticCurveTo(.05, my + .1, .3, my - .1); ctx.stroke();
    ctx.lineWidth = .05; ctx.beginPath(); ctx.moveTo(.3, my - .1); ctx.lineTo(.36, my - .14); ctx.stroke();
  }
  /* the handlebar moustache, waxed into curls */
  g = ctx.createLinearGradient(0, .3, 0, .55); g.addColorStop(0, '#46304a'); g.addColorStop(1, '#1e1222');
  ctx.fillStyle = g;
  const droop = sh * .12;
  for (const sd of [-1, 1]) {
    ctx.beginPath(); ctx.moveTo(0, .32); ctx.bezierCurveTo(sd * .2, .26, sd * .42, .33, sd * .55, .44 + droop);
    ctx.bezierCurveTo(sd * .68, .52 + droop, sd * .78, .44 + droop, sd * .74, .32 + droop * 2); ctx.bezierCurveTo(sd * .8, .5 + droop, sd * .66, .62 + droop, sd * .5, .54 + droop);
    ctx.bezierCurveTo(sd * .3, .48, sd * .12, .46, 0, .44); ctx.closePath(); ctx.fill();
  }
  /* sweat */
  if (e.sweat) {
    ctx.globalAlpha = e.sweat; const sx = .72, sy = -.5 + ((e.t || 0) * .6 % .5);
    const sg = ctx.createLinearGradient(sx, sy - .2, sx, sy + .12); sg.addColorStop(0, '#e8fbff'); sg.addColorStop(1, '#5ac0f0');
    ctx.fillStyle = sg; ctx.beginPath(); ctx.moveTo(sx, sy - .22); ctx.quadraticCurveTo(sx + .12, sy, sx, sy + .1); ctx.quadraticCurveTo(sx - .12, sy, sx, sy - .22); ctx.fill(); ctx.globalAlpha = 1;
  }
  ctx.restore();
}
/* the rival in a round gold-rimmed portrait */
function rivalBadge(cx, cy, r, e, o = {}) {
  ctx.save();
  ctx.shadowColor = 'rgba(10,2,24,.6)'; ctx.shadowBlur = r * .35; ctx.shadowOffsetY = r * .08;
  const g = ctx.createRadialGradient(cx, cy - r * .3, r * .1, cx, cy, r); g.addColorStop(0, o.bg0 || '#7a3aa8'); g.addColorStop(1, o.bg1 || '#2a1048');
  ctx.fillStyle = g; ctx.beginPath(); ctx.arc(cx, cy, r, 0, 7); ctx.fill(); ctx.shadowColor = 'transparent';
  ctx.save(); ctx.beginPath(); ctx.arc(cx, cy, r, 0, 7); ctx.clip();
  /* rays behind him */
  ctx.globalCompositeOperation = 'lighter'; for (let i = 0; i < 12; i++) { const a = i / 12 * Math.PI * 2 + (e.t || 0) * .2; ctx.fillStyle = 'rgba(255,200,120,.06)'; ctx.beginPath(); ctx.moveTo(cx, cy); ctx.arc(cx, cy, r, a, a + .22); ctx.fill(); }
  ctx.globalCompositeOperation = 'source-over';
  rival(cx, cy - r * .02, r / 150, e);
  ctx.restore();
  const rg = ctx.createLinearGradient(cx - r, cy - r, cx + r, cy + r); rg.addColorStop(0, '#fff2c8'); rg.addColorStop(.5, '#e8a83a'); rg.addColorStop(1, '#ffe7a0');
  ctx.strokeStyle = rg; ctx.lineWidth = Math.max(4, r * .05); ctx.beginPath(); ctx.arc(cx, cy, r, 0, 7); ctx.stroke();
  ctx.restore();
}
/* a trash-talk bubble from the rival; typed out from frame f0 */
function bubble(f, f0, text, x, y, w, o = {}) {
  text = tx(text);
  if (f < f0) return;
  const k = eBack(prog(f, f0, f0 + 7), 1.4), n = Math.floor((f - f0 - 3) * (o.cps || 2.2));
  const size = o.size || 52, pad = 34, av = o.noAvatar ? 0 : 110;
  ctx.save(); ctx.font = `700 ${size}px B`;
  const words = text.split(' '), lines = []; let cur = '';
  for (const wd of words) { const tt = cur ? cur + ' ' + wd : wd; if (ctx.measureText(tt).width > w - pad * 2 - av) { lines.push(cur); cur = wd; } else cur = tt; }
  lines.push(cur);
  const h = Math.max(av + pad * .6, pad * 2 + 44 + lines.length * size * 1.2);
  ctx.translate(x + w / 2, y + h / 2); ctx.scale(k, k); ctx.rotate((o.rot || 0) * (1 - prog(f, f0, f0 + 10) * .5)); ctx.translate(-(x + w / 2), -(y + h / 2));
  ctx.globalAlpha = clamp((f - f0) / 3, 0, 1) * (o.alpha ?? 1);
  ctx.shadowColor = 'rgba(8,2,20,.55)'; ctx.shadowBlur = 50; ctx.shadowOffsetY = 16;
  const bg = ctx.createLinearGradient(0, y, 0, y + h); bg.addColorStop(0, 'rgba(48,24,84,.96)'); bg.addColorStop(1, 'rgba(24,10,46,.96)');
  ctx.fillStyle = bg; rrect(x, y, w, h, 40); ctx.fill(); ctx.shadowColor = 'transparent';
  /* tail */
  ctx.beginPath(); ctx.moveTo(x + 70, y + h - 2); ctx.lineTo(x + 40, y + h + 38); ctx.lineTo(x + 120, y + h - 2); ctx.fill();
  ctx.strokeStyle = 'rgba(255,214,140,.7)'; ctx.lineWidth = 3; rrect(x, y, w, h, 40); ctx.stroke();
  if (av) rivalBadge(x + pad + av / 2 - 6, y + pad + av / 2 - 4, av / 2, Object.assign({ talk: n < text.length ? .5 + .5 * Math.sin(f * 1.3) : 0 }, o.e || {}));
  ctx.textAlign = 'left';
  label('VICTOR SMUGG', x + pad + av + 4, y + pad + 30, 30, '#ffcf7a', { align: 'left', track: .14 });
  label('YOUR RIVAL', x + pad + av + 228, y + pad + 30, 24, 'rgba(255,230,200,.6)', { align: 'left', track: .14 });
  ctx.font = `700 ${size}px B`; ctx.fillStyle = '#fff6ea'; ctx.letterSpacing = '0px';
  let left = clamp(n, 0, text.length);
  lines.forEach((ln, i) => { const s = ln.slice(0, Math.max(0, left)); left -= ln.length + 1; ctx.fillText(s, x + pad + av + 4, y + pad + 44 + size * (1.05 + i * 1.2)); });
  ctx.restore();
  return h;
}

/* ---------- counters ---------- */
function bigNumber(text, cx, y, size, lab, o = {}) {
  ctx.save(); ctx.translate(cx, y); ctx.scale(o.s || 1, o.s || 1);
  if (o.card) {
    ctx.font = `800 ${size}px BC`; const w = Math.max(ctx.measureText(text).width, size * 2) + size * .6, top = -size * .95, h = size * (lab ? 1.55 : 1.2);
    ctx.save(); ctx.shadowColor = 'rgba(8,2,20,.5)'; ctx.shadowBlur = 40; ctx.fillStyle = 'rgba(22,10,46,.82)'; rrect(-w / 2, top, w, h, size * .22); ctx.fill(); ctx.restore();
    ctx.strokeStyle = 'rgba(255,214,140,.7)'; ctx.lineWidth = 3; rrect(-w / 2, top, w, h, size * .22); ctx.stroke();
  }
  drawLine(text, 0, 0, size, o);
  if (lab) label(lab, 0, size * .42, size * .24, '#ffe6b8', { track: .2 });
  ctx.restore();
}

/* ---------- world map ---------- */
let WORLD_D = '';
const CITIES = {
  cap: { name: 'CAPPADOCIA', lon: 34.8, lat: 38.6 }, abq: { name: 'ALBUQUERQUE', lon: -106.6, lat: 35.1 }, lux: { name: 'LUXOR', lon: 32.6, lat: 25.7 },
  bri: { name: 'BRISTOL', lon: -2.6, lat: 51.45 }, mara: { name: 'MAASAI MARA', lon: 35.1, lat: -1.5 },
};
const mapPt = c => [(c.lon + 130) / 260 * 100, (70 - c.lat) / 110 * 42.3];
let LAND;
/* the map drawn so that map point (mx, my) sits at screen (W/2, H/2) at k px per map unit */
function worldMap(mx, my, k, f, o = {}) {
  if (!LAND) LAND = new Path2D(WORLD_D);
  const bg = ctx.createLinearGradient(0, 0, 0, H); bg.addColorStop(0, '#0c1034'); bg.addColorStop(.5, '#1a1650'); bg.addColorStop(1, '#2a1a5a');
  ctx.fillStyle = bg; ctx.fillRect(0, 0, W, H);
  const R = mulberry32(5); for (let i = 0; i < 180; i++) { ctx.fillStyle = `rgba(255,246,230,${.15 + R() * .4})`; ctx.beginPath(); ctx.arc(R() * W, R() * H, .6 + R() * 1.6, 0, 7); ctx.fill(); }
  ctx.save(); ctx.globalCompositeOperation = 'lighter'; const gl = ctx.createRadialGradient(W * .5, H * 1.05, 0, W * .5, H * 1.05, H * .8); gl.addColorStop(0, 'rgba(255,120,90,.35)'); gl.addColorStop(1, 'rgba(255,120,90,0)'); ctx.fillStyle = gl; ctx.fillRect(0, 0, W, H); ctx.restore();
  ctx.save(); ctx.translate(W / 2 - mx * k, H / 2 - my * k); ctx.scale(k, k);
  /* graticule */
  ctx.strokeStyle = 'rgba(160,170,255,.09)'; ctx.lineWidth = 1 / k;
  for (let x = -20; x <= 120; x += 100 / 26) { ctx.beginPath(); ctx.moveTo(x, -20); ctx.lineTo(x, 60); ctx.stroke(); }
  for (let y = -20; y <= 60; y += 42.3 / 11) { ctx.beginPath(); ctx.moveTo(-20, y); ctx.lineTo(120, y); ctx.stroke(); }
  ctx.save(); ctx.shadowColor = 'rgba(255,170,110,.35)'; ctx.shadowBlur = 30;
  const lg = ctx.createLinearGradient(0, 0, 0, 42.3); lg.addColorStop(0, '#463c86'); lg.addColorStop(1, '#5a3a7a');
  ctx.fillStyle = lg; ctx.fill(LAND); ctx.restore();
  ctx.strokeStyle = 'rgba(255,214,160,.45)'; ctx.lineWidth = 1.6 / k; ctx.stroke(LAND);
  ctx.restore();
  return (c) => { const [px, py] = mapPt(c); return [W / 2 + (px - mx) * k, H / 2 + (py - my) * k]; };
}
function pin(x, y, name, f, f0, o = {}) {
  name = tx(name); o = Object.assign({}, o, { tag: tx(o.tag) });
  if (f < f0) return;
  const k = eBack(prog(f, f0, f0 + 8), 2), pulse = (f - f0) % 30 / 30;
  ctx.save(); ctx.translate(x, y); ctx.scale(k, k);
  ctx.strokeStyle = `rgba(255,214,120,${(1 - pulse) * .8})`; ctx.lineWidth = 4; ctx.beginPath(); ctx.arc(0, 0, 18 + pulse * 50, 0, 7); ctx.stroke();
  ctx.globalCompositeOperation = 'lighter'; const g = ctx.createRadialGradient(0, 0, 0, 0, 0, 70); g.addColorStop(0, 'rgba(255,200,100,.6)'); g.addColorStop(1, 'rgba(255,160,60,0)'); ctx.fillStyle = g; ctx.fillRect(-70, -70, 140, 140); ctx.globalCompositeOperation = 'source-over';
  ctx.fillStyle = o.locked ? '#8a86b0' : '#ffc95a'; ctx.beginPath(); ctx.arc(0, 0, 17, 0, 7); ctx.fill(); ctx.strokeStyle = '#fff6dc'; ctx.lineWidth = 5; ctx.stroke();
  ctx.restore();
  if (name) {
    ctx.save(); ctx.globalAlpha = prog(f, f0 + 2, f0 + 8);
    const s = o.size || 50; ctx.font = `800 ${s}px BC`; ctx.letterSpacing = `${s * .06}px`; const tw = ctx.measureText(name).width;
    const lx = o.side === 'l' ? x - 40 - tw - 30 : x + 40, ly = y - s * .7;
    ctx.fillStyle = 'rgba(20,10,44,.85)'; rrect(lx - 4, ly - 6, tw + 38, s * 1.3, 16); ctx.fill(); ctx.strokeStyle = 'rgba(255,214,140,.7)'; ctx.lineWidth = 2.5; rrect(lx - 4, ly - 6, tw + 38, s * 1.3, 16); ctx.stroke();
    ctx.fillStyle = '#fff3dc'; ctx.textAlign = 'left'; ctx.fillText(name, lx + 14, ly + s * .98);
    if (o.tag) { const ts = s * .55; ctx.font = `800 ${ts}px BC`; ctx.letterSpacing = `${ts * .14}px`; const w2 = ctx.measureText(o.tag).width + ts;
      const tx = o.side === 'l' ? lx + tw + 34 - w2 : lx - 4, ty = ly + s * 1.3 + 8; ctx.fillStyle = o.tagCol || '#ffc95a'; rrect(tx, ty, w2, ts * 1.55, ts * .4); ctx.fill(); ctx.fillStyle = '#2a1048'; ctx.fillText(o.tag, tx + ts * .55, ty + ts * 1.16); }
    ctx.restore();
  }
}
/* a dotted flight path from a to b, drawn to k (0..1), with a balloon at its head */
function route(a, b, k, f) {
  if (k <= 0) return;
  const mid = [(a[0] + b[0]) / 2, Math.min(a[1], b[1]) - Math.hypot(b[0] - a[0], b[1] - a[1]) * .35];
  const at = u => { const v = 1 - u; return [v * v * a[0] + 2 * v * u * mid[0] + u * u * b[0], v * v * a[1] + 2 * v * u * mid[1] + u * u * b[1]]; };
  ctx.save(); ctx.strokeStyle = 'rgba(255,214,140,.95)'; ctx.lineWidth = 7; ctx.lineCap = 'round'; ctx.setLineDash([2, 20]);
  ctx.beginPath(); for (let i = 0; i <= 60; i++) { const u = i / 60 * k, p = at(u); i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); ctx.restore();
  if (k < 1) { const p = at(k); spriteBalloon(SPRITES.near[0], p[0], p[1] - 70, 44, 1, f / 30); }
}

/* ---------- end card ---------- */
let ICON;
function endCard(f, f0, head, o = {}) {
  const t = (f - f0) / FPS;
  /* the world, slowly rising */
  dawn({ t: 20 + t, cam: { x: -40 + t * 14, y: 780 - t * 35, z: 1.0 + t * .015 } });
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, 'rgba(12,6,36,.72)'); g.addColorStop(.45, 'rgba(12,6,36,.25)'); g.addColorStop(.75, 'rgba(12,6,36,.35)'); g.addColorStop(1, 'rgba(12,6,36,.7)');
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  const cx = W / 2;
  kinetic(f, head, cx, 250, { f0, stagger: 5, size: o.size || 150, maxW: 800 });
  /* icon */
  const ik = eBack(prog(f, f0 + B(2), f0 + B(2) + 9), 1.8), iy = 850, is = 260;
  if (ik > 0 && ICON) {
    ctx.save(); ctx.translate(cx, iy); ctx.scale(ik, ik); ctx.rotate((1 - ik) * .2);
    ctx.shadowColor = 'rgba(10,2,24,.6)'; ctx.shadowBlur = 50; ctx.shadowOffsetY = 18; ctx.fillStyle = '#000'; rrect(-is / 2, -is / 2, is, is, is * .225); ctx.fill(); ctx.shadowColor = 'transparent';
    ctx.save(); rrect(-is / 2, -is / 2, is, is, is * .225); ctx.clip(); ctx.drawImage(ICON, -is / 2, -is / 2, is, is); ctx.restore();
    ctx.strokeStyle = 'rgba(255,255,255,.35)'; ctx.lineWidth = 3; rrect(-is / 2, -is / 2, is, is, is * .225); ctx.stroke();
    ctx.restore();
  }
  const tf = f0 + B(2.5);
  if (f >= tf) {
    const k = eOut(prog(f, tf, tf + 8));
    ctx.save(); ctx.globalAlpha = k; ctx.translate(0, (1 - k) * 40);
    drawLine('BALLOON BARON', cx, 1135, 150);
    label('CAPPADOCIA', cx, 1205, 50, '#ffd28a', { track: .5 });
    ctx.restore();
  }
  const sf = f0 + B(3);
  if (f >= sf) {
    ctx.save(); ctx.globalAlpha = eOut(prog(f, sf, sf + 8));
    label('No ads. No energy timers.', cx, 1290, 44, '#fff3e6', { font: 'B', w: 700, track: 0 });
    ctx.restore();
  }
  const pf = f0 + B(3.5);
  if (f >= pf) {
    const k = eBack(prog(f, pf, pf + 8), 1.8) * (1 + beatPulse(f, pf + B(1)) * .04);
    const w = 600, h = 120, y = 1340;
    ctx.save(); ctx.translate(cx, y + h / 2); ctx.scale(k, k); ctx.translate(-cx, -(y + h / 2));
    ctx.shadowColor = 'rgba(255,90,40,.55)'; ctx.shadowBlur = 50; ctx.shadowOffsetY = 10;
    const bg = ctx.createLinearGradient(0, y, 0, y + h); bg.addColorStop(0, '#ff8a4a'); bg.addColorStop(1, '#ec4a26');
    ctx.fillStyle = bg; rrect(cx - w / 2, y, w, h, h / 2); ctx.fill(); ctx.shadowColor = 'transparent';
    ctx.fillStyle = 'rgba(255,255,255,.22)'; rrect(cx - w / 2 + 8, y + 6, w - 16, h * .42, h * .3); ctx.fill();
    /* a sheen sweeping across */
    ctx.save(); rrect(cx - w / 2, y, w, h, h / 2); ctx.clip(); const sx = cx - w + ((f - pf) % 45) / 45 * w * 2.5; const sg = ctx.createLinearGradient(sx - 80, 0, sx + 80, 0); sg.addColorStop(0, 'rgba(255,255,255,0)'); sg.addColorStop(.5, 'rgba(255,255,255,.35)'); sg.addColorStop(1, 'rgba(255,255,255,0)'); ctx.fillStyle = sg; ctx.fillRect(cx - w / 2, y, w, h); ctx.restore();
    ctx.font = '800 64px BC'; ctx.letterSpacing = '4px'; ctx.textAlign = 'center'; ctx.fillStyle = '#fff'; ctx.shadowColor = 'rgba(120,20,0,.5)'; ctx.shadowBlur = 8; ctx.fillText(tx('ON THE APP STORE'), cx + 2, y + h * .7);
    ctx.restore();
  }
}
