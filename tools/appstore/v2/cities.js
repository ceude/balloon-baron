/* Screen 2: the screen cut by four diagonal lines into four trapezoids, one city each, top to bottom:
   Kapadokya (fairy chimneys at sunrise), Luksor (the Nile, temple pylons and an obelisk), Bristol (green hills, the
   gorge and its suspension bridge), Albuquerque (desert mesas and the Balloon Fiesta). One light from the left
   for all four, thin light seams between them, and the game's world map (the real screen) in a phone over them. */

/* the dividing lines: [left y, right y] as fractions of the height; none parallel */
const CUTS = { iphone: [[.405, .335], [.555, .615], [.79, .735]], ipad: [[.40, .33], [.56, .62], [.8, .74]] };

function citiesScreen(i) {
  const w = D.W, h = D.H, cuts = CUTS[DEV].map(([a, b]) => [a * h, b * h]);
  const lines = [[0, 0], ...cuts, [h, h]];
  const kinds = ['cap', 'lux', 'bri', 'abq'];
  for (let k = 0; k < 4; k++) {
    const [a0, b0] = lines[k], [a1, b1] = lines[k + 1];
    ctx.save(); ctx.beginPath(); ctx.moveTo(0, a0); ctx.lineTo(w, b0); ctx.lineTo(w, b1); ctx.lineTo(0, a1); ctx.closePath(); ctx.clip();
    const top = Math.min(a0, b0), bot = Math.max(a1, b1);
    CITY[kinds[k]](w, top, bot, k === 0 ? 0 : Math.max(a0, b0));
    ctx.restore();
  }
  /* seams: a thin light line with a soft glow */
  for (const [a, b] of cuts) {
    ctx.save(); ctx.lineCap = 'round';
    ctx.strokeStyle = 'rgba(255,236,200,.25)'; ctx.lineWidth = w * .014; ctx.filter = `blur(${w * .006}px)`;
    ctx.beginPath(); ctx.moveTo(-10, a); ctx.lineTo(w + 10, b); ctx.stroke(); ctx.filter = 'none';
    ctx.strokeStyle = 'rgba(255,246,228,.95)'; ctx.lineWidth = Math.max(3, w * .0035);
    ctx.beginPath(); ctx.moveTo(-10, a); ctx.lineTo(w + 10, b); ctx.stroke(); ctx.restore();
  }
  /* the phone with the real world map, leaning in from the right */
  const pw = w * (DEV === 'ipad' ? .5 : .5), ph = pw * IMG.world.height / IMG.world.width;
  const px = w - pw - w * (DEV === 'ipad' ? .07 : .05), py = h - ph - h * .04;
  if (DEV === 'ipad') {
    /* on iPad the world map is a card in the middle of a big screen: lift the card itself out */
    const src = [609, 531, 834, 1677], sc = h * .5 / src[3];
    popout(IMG.world, src, w - src[2] * sc - w * .07, h - src[3] * sc - h * .05, sc, { r: 40, rot: .035, ring: 'rgba(255,255,255,.9)', ringW: 4 });
  } else device(D.kind, px, py, pw, ph, IMG.world, { rot: .04, shadow: 'rgba(6,2,16,.7)' });
  /* balloons that cross the seams tie the four together */
  const S = DEV === 'ipad' ? .8 : 1, cy = (c, x) => lerp(c[0], c[1], x / w);
  let x = w * .56; balloon2(x, cy(cuts[0], x) - h * .025, w * .068 * S, { cols: ['#ffc23d', '#e5432f'], pattern: 'band', pc: ['#2b2350', '#fff'], burn: .9, people: 3, light: -1, sky: '#ffb07a' });
  x = w * .3; balloon2(x, cy(cuts[2], x) - h * .03, w * .055 * S, { cols: ['#14a39a', '#f4fff8'], pattern: 'rings', pc: ['#ffc23d', '#2b2350'], burn: .7, light: -1, sky: '#9fc7e8' });
  /* city labels on the open left side of each band, tilted with it */
  const L = TXT.cities, at = CITY_LABEL[DEV];
  kinds.forEach((k, j) => {
    const slope = ((lines[j][1] - lines[j][0]) + (lines[j + 1][1] - lines[j + 1][0])) / 2 / w;
    cityLabel(w * at[j][0], h * at[j][1], L[k][0], L[k][1], Math.atan(slope) * .7);
  });
}
/* [x, y] of each label's baseline start, as fractions of the screen */
const CITY_LABEL = { iphone: [[.065, .31], [.065, .535], [.19, .655], [.065, .865]], ipad: [[.06, .3], [.06, .535], [.17, .66], [.06, .87]] };
function cityLabel(x, y, name, land, rot) {
  ctx.save(); ctx.translate(x, y); ctx.rotate(rot);
  const s = D.W * (DEV === 'ipad' ? .05 : .075) * TY.headK * (CJK ? 1.05 : 1), hf = z => CJK ? TY.head(z) : `800 ${z}px BC`;
  ctx.textAlign = 'left'; ctx.font = hf(s); ctx.letterSpacing = `${s * (CJK ? 0 : .02)}px`;
  const t = upper(name, TXT.locale); let tw = ctx.measureText(t).width;
  const fit = D.W * (DEV === 'ipad' ? .42 : .44); /* stays clear of the phone */
  if (tw > fit) { ctx.font = hf(s * fit / tw); tw = fit; }
  /* a soft shade behind the name so it reads over any landscape */
  const cx = tw / 2, cyy = -s * .2, g0 = ctx.createRadialGradient(cx, cyy, 0, cx, cyy, tw * .75);
  g0.addColorStop(0, 'rgba(14,6,26,.42)'); g0.addColorStop(1, 'rgba(14,6,26,0)');
  ctx.save(); ctx.translate(cx, cyy); ctx.scale(1, .42); ctx.translate(-cx, -cyy); ctx.fillStyle = g0; ctx.fillRect(cx - tw, cyy - tw, tw * 2, tw * 2); ctx.restore();
  ctx.shadowColor = 'rgba(10,4,20,.7)'; ctx.shadowBlur = s * .3; ctx.shadowOffsetY = s * .04;
  const g = ctx.createLinearGradient(0, -s * .8, 0, 0); g.addColorStop(0, '#ffffff'); g.addColorStop(1, '#ffe7c2');
  ctx.fillStyle = g; ctx.fillText(t, 0, 0);
  ctx.font = TY.label(700, s * (CJK ? .36 : .3)); ctx.letterSpacing = `${s * (CJK ? .03 : .12)}px`; ctx.fillStyle = '#ffd27a';
  ctx.fillText(upper(land, TXT.locale), s * .03, s * (CJK ? .52 : .44));
  ctx.restore();
}
/* soft gradient sky inside a band */
function bandSky(w, top, bot, stops) {
  const g = ctx.createLinearGradient(0, top, 0, bot); stops.forEach(([k, c]) => g.addColorStop(k, c));
  ctx.fillStyle = g; ctx.fillRect(0, top, w, bot - top);
}
function glowAt(x, y, r, col, a) {
  ctx.save(); ctx.globalCompositeOperation = 'lighter'; const g = ctx.createRadialGradient(x, y, 0, x, y, r); g.addColorStop(0, rgba(col, a)); g.addColorStop(1, rgba(col, 0)); ctx.fillStyle = g; ctx.fillRect(x - r, y - r, r * 2, r * 2); ctx.restore();
}
function hills(w, base, amp, col, seed, freq = 1) {
  const R = mulberry32(seed), p1 = R() * 6, p2 = R() * 6;
  ctx.fillStyle = col; ctx.beginPath(); ctx.moveTo(0, base + amp * 3);
  for (let x = -10; x <= w + 10; x += 8) ctx.lineTo(x, base - amp * (.5 + .35 * Math.sin(x * .0042 * freq + p1) + .15 * Math.sin(x * .011 * freq + p2)));
  ctx.lineTo(w, base + amp * 3); ctx.closePath(); ctx.fill();
}
function fewBalloons(w, top, bot, n, seed, hazeCol, light = -1) {
  const R = mulberry32(seed), list = [];
  for (let i = 0; i < n; i++) list.push({ x: R() * w, y: lerp(top, bot, R()), d: R(), c: COLS[Math.floor(R() * COLS.length)], s: COLS[Math.floor(R() * COLS.length)] });
  list.sort((a, b) => a.d - b.d);
  for (const b of list) farBalloon(b.x, b.y, w * (.006 + .022 * Math.pow(b.d, 2)), b.c, (1 - b.d) * .6, hazeCol, { stripe: R() < .5 ? b.s : null });
}

const CITY = {
  /* Kapadokya: the deepest sunrise, under the caption */
  cap(w, top, bot) {
    const hy = bot - (bot - top) * .2;
    bandSky(w, top, bot, [[0, '#1a1038'], [.35, '#4e2462'], [.62, '#c25a6c'], [.8, '#ffae7a'], [1, '#ffd29a']]);
    glowAt(w * .78, hy, w * .9, '#ffb070', .35); glowAt(w * .78, hy, w * .18, '#fff1c8', .8);
    ctx.fillStyle = '#fff6e0'; ctx.beginPath(); ctx.arc(w * .78, hy, w * .045, 0, 7); ctx.fill();
    fewBalloons(w, top + (bot - top) * .5, hy - 20, 60, 3, '#e88a78');
    hills(w, hy + 10, 40, '#b5636a', 4); hills(w, hy + 40, 30, '#8a4256', 5);
    const R = mulberry32(8);
    for (let i = 0; i < 26; i++) { const x = R() * w, hh = 60 + R() * 150; chimney(x, bot + 4, hh * .36, hh, { seed: 300 + i, light: 1, lit: '#f0ae86', dark: '#5a2c40', haze: .3, hazeColor: '#e88a78' }); }
    for (let i = 0; i < 7; i++) { const x = (i + .5) / 7 * w + (R() - .5) * 80, hh = 230 + R() * 170; chimney(x, bot + 30, hh * .34, hh, { seed: 400 + i, light: 1, lit: '#e09a74', dark: '#3a1a2a', rim: '#ffd59a', windows: 2 }); }
  },
  /* Luksor: gold over the Nile; a temple's pylons and colonnade, an obelisk, palms on the bank */
  lux(w, top, bot) {
    const hy = top + (bot - top) * .62;
    bandSky(w, top, hy + 40, [[0, '#e88c58'], [.5, '#ffc884'], [1, '#fff0c8']]);
    glowAt(w * .12, hy - 20, w * .7, '#ffe0a0', .4);
    fewBalloons(w, top + 30, hy - 120, 34, 9, '#ffcf9a');
    hills(w, hy - 4, 46, '#e2b07a', 12, .45); hills(w, hy + 4, 22, '#c99460', 13, .9);
    const th = (bot - top) * .2, tx = w * .3, tb = hy + 6;
    const lit = (x0, x1) => { const g = ctx.createLinearGradient(x0, 0, x1, 0); g.addColorStop(0, '#ffe2b0'); g.addColorStop(.55, '#e2b078'); g.addColorStop(1, '#a8703e'); return g; };
    /* colonnade behind */
    for (let c = 0; c < 10; c++) {
      const cx = tx - w * .27 + c * w * .022, ch = th * .62;
      ctx.fillStyle = lit(cx, cx + w * .016); ctx.fillRect(cx, tb - ch, w * .016, ch);
      ctx.fillStyle = '#f0c890'; ctx.fillRect(cx - w * .004, tb - ch - w * .008, w * .024, w * .008);
    }
    ctx.fillStyle = lit(tx - w * .28, tx - w * .05); ctx.fillRect(tx - w * .28, tb - th * .7, w * .23, th * .07);
    /* the two pylons and the gate */
    for (const s2 of [-1, 1]) {
      const pc = tx + s2 * w * .075, bw = w * .06, tw2 = w * .046;
      ctx.fillStyle = lit(pc - bw, pc + bw); ctx.beginPath(); ctx.moveTo(pc - bw, tb); ctx.lineTo(pc - tw2, tb - th); ctx.lineTo(pc + tw2, tb - th); ctx.lineTo(pc + bw, tb); ctx.fill();
      ctx.fillStyle = '#f6d4a0'; ctx.fillRect(pc - tw2 - w * .005, tb - th - w * .01, tw2 * 2 + w * .01, w * .01);
      ctx.fillStyle = 'rgba(90,50,20,.35)'; ctx.fillRect(pc - tw2 - w * .005, tb - th, tw2 * 2 + w * .01, w * .004);
      ctx.strokeStyle = 'rgba(110,60,30,.28)'; ctx.lineWidth = 2;
      for (let r = 1; r < 5; r++) { const yy = tb - th * r / 5.5, hw = lerp(bw, tw2, r / 5.5) * .7; ctx.beginPath(); ctx.moveTo(pc - hw, yy); ctx.lineTo(pc + hw, yy); ctx.stroke(); }
    }
    ctx.fillStyle = lit(tx - w * .03, tx + w * .03); ctx.fillRect(tx - w * .03, tb - th * .72, w * .06, th * .72);
    ctx.fillStyle = 'rgba(70,34,14,.6)'; ctx.fillRect(tx - w * .014, tb - th * .48, w * .028, th * .48);
    /* the obelisk in front */
    const ox = w * .5, oh = th * 1.35, ow = w * .018;
    ctx.fillStyle = lit(ox - ow, ox + ow); ctx.beginPath(); ctx.moveTo(ox - ow, tb + 4); ctx.lineTo(ox - ow * .72, tb - oh); ctx.lineTo(ox, tb - oh - ow * 1.3); ctx.lineTo(ox + ow * .72, tb - oh); ctx.lineTo(ox + ow, tb + 4); ctx.fill();
    ctx.fillStyle = '#ffeec8'; ctx.beginPath(); ctx.moveTo(ox - ow * .72, tb - oh); ctx.lineTo(ox, tb - oh - ow * 1.3); ctx.lineTo(ox, tb - oh); ctx.fill();
    /* the Nile with the sky in it */
    const rv = ctx.createLinearGradient(0, hy, 0, bot); rv.addColorStop(0, '#ffe2aa'); rv.addColorStop(.45, '#8ab0b8'); rv.addColorStop(1, '#2a5070');
    ctx.fillStyle = '#5a6a2e'; ctx.fillRect(0, hy + 2, w, 14);
    ctx.fillStyle = rv; ctx.fillRect(0, hy + 14, w, bot - hy);
    const R = mulberry32(14); ctx.strokeStyle = 'rgba(255,244,210,.55)'; ctx.lineWidth = 3;
    for (let i = 0; i < 50; i++) { const y = hy + 22 + R() * (bot - hy - 22), x = R() * w, l = 20 + R() * 90; ctx.globalAlpha = .25 + R() * .5; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + l, y); ctx.stroke(); }
    ctx.globalAlpha = 1;
    /* a felucca */
    const fx = w * .36, fy = hy + (bot - hy) * .38; ctx.fillStyle = '#3a2418'; ctx.beginPath(); ctx.moveTo(fx - 50, fy); ctx.lineTo(fx + 55, fy); ctx.lineTo(fx + 40, fy + 14); ctx.lineTo(fx - 40, fy + 14); ctx.fill();
    ctx.fillStyle = '#fff4dc'; ctx.beginPath(); ctx.moveTo(fx - 4, fy - 4); ctx.lineTo(fx + 8, fy - 140); ctx.lineTo(fx + 64, fy - 10); ctx.closePath(); ctx.fill();
    ctx.fillStyle = 'rgba(255,244,220,.25)'; ctx.beginPath(); ctx.moveTo(fx - 4, fy + 18); ctx.lineTo(fx + 8, fy + 90); ctx.lineTo(fx + 64, fy + 22); ctx.fill();
    for (const [px, ph] of [[w * .03, 200], [w * .1, 150], [w * .6, 230], [w * .67, 170]]) palm(px, hy + 10, ph);
  },
  /* Bristol: green hills, the Avon gorge and its suspension bridge, the river below */
  bri(w, top, bot) {
    const hy = top + (bot - top) * .48;
    bandSky(w, top, bot, [[0, '#6a7cb8'], [.4, '#e0aaa4'], [.7, '#ffd4a8'], [1, '#ffe6c0']]);
    glowAt(w * .15, hy, w * .5, '#ffe0b0', .3);
    fewBalloons(w, top + 30, hy - 30, 30, 17, '#e8c0b0');
    hills(w, hy + 10, 50, '#8aa070', 18, .8); hills(w, hy + 60, 60, '#5f8048', 19, 1.1);
    const gx0 = w * .2, gx1 = w * .55, gy = hy + (bot - hy) * .32;
    ctx.fillStyle = '#a8b4b8'; ctx.fillRect(gx0, gy, gx1 - gx0, bot - gy);
    const rv = ctx.createLinearGradient(0, bot - (bot - gy) * .3, 0, bot); rv.addColorStop(0, '#d4e0e4'); rv.addColorStop(1, '#6a8ca0');
    ctx.fillStyle = rv; ctx.fillRect(gx0, bot - (bot - gy) * .3, gx1 - gx0, bot);
    const cl = ctx.createLinearGradient(0, gy, 0, bot); cl.addColorStop(0, '#4e7040'); cl.addColorStop(1, '#263c22');
    ctx.fillStyle = cl;
    ctx.beginPath(); ctx.moveTo(-10, gy - 8); ctx.lineTo(gx0, gy); ctx.lineTo(gx0 + 30, bot - (bot - gy) * .3); ctx.lineTo(gx0 + 14, bot + 10); ctx.lineTo(-10, bot + 10); ctx.fill();
    ctx.beginPath(); ctx.moveTo(w, gy - 14); ctx.lineTo(gx1, gy); ctx.lineTo(gx1 - 40, bot - (bot - gy) * .3); ctx.lineTo(gx1 - 24, bot + 10); ctx.lineTo(w, bot + 10); ctx.fill();
    const t1 = gx0 + 8, t2 = gx1 - 8, deck = gy + 4, th = (bot - top) * .26, tw = w * .032;
    ctx.strokeStyle = '#2e2830'; ctx.lineWidth = 5;
    ctx.beginPath(); ctx.moveTo(t1, deck - th + 8); ctx.quadraticCurveTo((t1 + t2) / 2, deck + th * .5, t2, deck - th + 8); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(t2, deck - th + 8); ctx.lineTo(t2 + w * .1, gy + 24); ctx.stroke();
    ctx.lineWidth = 2; for (let k = 1; k < 18; k++) { const t = k / 18, x = lerp(t1, t2, t), cyy = (1 - t) * (1 - t) * (deck - th + 8) + 2 * (1 - t) * t * (deck + th * .5) + t * t * (deck - th + 8); ctx.beginPath(); ctx.moveTo(x, cyy); ctx.lineTo(x, deck); ctx.stroke(); }
    for (const tx of [t1, t2]) {
      const tg = ctx.createLinearGradient(tx - tw, 0, tx + tw, 0); tg.addColorStop(0, '#fbecd4'); tg.addColorStop(1, '#a0897a'); ctx.fillStyle = tg;
      ctx.beginPath(); ctx.moveTo(tx - tw, deck + 12); ctx.lineTo(tx - tw * .82, deck - th); ctx.lineTo(tx + tw * .82, deck - th); ctx.lineTo(tx + tw, deck + 12); ctx.fill();
      ctx.fillStyle = 'rgba(60,40,34,.5)'; ctx.beginPath(); ctx.moveTo(tx - tw * .4, deck + 12); ctx.lineTo(tx - tw * .4, deck - th * .55); ctx.arc(tx, deck - th * .55, tw * .4, Math.PI, 0); ctx.lineTo(tx + tw * .4, deck + 12); ctx.fill();
      ctx.fillStyle = '#efe0c6'; ctx.fillRect(tx - tw * 1.02, deck - th - 10, tw * 2.04, 12);
    }
    ctx.fillStyle = '#2e2a2e'; ctx.fillRect(t1, deck, t2 - t1, 10);
    const R = mulberry32(23);
    for (let i = 0; i < 26; i++) { const x = gx1 + R() * (w - gx1), y = gy + R() * (bot - gy) * .7, r = 16 + R() * 24; ctx.fillStyle = ['#3c5a30', '#4a6a38', '#2e4a28'][i % 3]; ctx.beginPath(); ctx.arc(x, y, r, 0, 7); ctx.fill(); }
  },
  /* Albuquerque: pink Sandia mountains, desert mesas, a sky full of Fiesta balloons */
  abq(w, top, bot) {
    const hy = top + (bot - top) * .72;
    bandSky(w, top, bot, [[0, '#3a5aa0'], [.4, '#9a8ab8'], [.7, '#ffb88a'], [1, '#ffd6a0']]);
    glowAt(w * .5, hy, w * .6, '#ffc890', .3);
    hills(w, hy - 30, 90, '#c87c86', 31, .5); hills(w, hy, 40, '#a85e64', 32, .9);
    const R = mulberry32(33);
    for (let i = 0; i < 4; i++) mesa(w * (.15 + i * .25) + (R() - .5) * 60, hy + 20, 200 + R() * 120, 60 + R() * 50, '#b8664a', '#8a4632');
    const gr = ctx.createLinearGradient(0, hy + 10, 0, bot); gr.addColorStop(0, '#d89a68'); gr.addColorStop(1, '#a86a44');
    ctx.fillStyle = gr; ctx.fillRect(0, hy + 18, w, bot - hy);
    /* the Fiesta: a mass ascension, dense near the field */
    fewBalloons(w, top + 40, hy + 10, 90, 34, '#e8b0a0');
    const R2 = mulberry32(35);
    for (let i = 0; i < 14; i++) { const x = R2() * w, y = hy + 30 + R2() * (bot - hy - 40), r = w * (.012 + R2() * .012); farBalloon(x, y - r * 1.5, r, COLS[i % COLS.length], .05, '#ffd0a0', { stripe: i % 2 ? '#ffffff' : null }); }
  }
};
function palm(x, base, h) {
  ctx.save(); ctx.strokeStyle = '#3a2a1c'; ctx.lineWidth = h * .045; ctx.lineCap = 'round';
  ctx.beginPath(); ctx.moveTo(x, base); ctx.quadraticCurveTo(x + h * .1, base - h * .5, x + h * .04, base - h); ctx.stroke();
  const tx = x + h * .04, ty = base - h; ctx.fillStyle = '#2c4a24';
  for (let k = 0; k < 8; k++) { const a = -Math.PI / 2 + (k - 3.5) * .42; ctx.save(); ctx.translate(tx, ty); ctx.rotate(a + Math.PI / 2); ctx.beginPath(); ctx.ellipse(0, -h * .2, h * .045, h * .22, 0, 0, 7); ctx.fill(); ctx.restore(); }
  ctx.restore();
}
