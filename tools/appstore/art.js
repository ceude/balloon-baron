/* Drawing helpers shared by the App Store pictures (render.html posters, panorama.html). They draw on the global
   `ctx`; W and H are the canvas size and may be changed before drawing. */
let W = 1290, H = 2796;

function mulberry32(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; let q = Math.imul(a ^ a >>> 15, 1 | a); q = q + Math.imul(q ^ q >>> 7, 61 | q) ^ q; return ((q ^ q >>> 14) >>> 0) / 4294967296; }; }
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const lerp = (a, b, k) => a + (b - a) * k;
function hex(h) { return [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16)); }
function mix(a, b, k) { const A = hex(a), B = hex(b); return '#' + A.map((x, i) => Math.round(lerp(x, B[i], clamp(k, 0, 1))).toString(16).padStart(2, '0')).join(''); }
function rgba(h, a) { const [r, g, b] = hex(h); return `rgba(${r},${g},${b},${a})`; }

/* ---------- sky and light ---------- */
function sky(stops) {
  const g = ctx.createLinearGradient(0, 0, 0, H);
  stops.forEach(([k, c]) => g.addColorStop(k, c));
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
}
function sun(x, y, r, core = '#fff6dc', glow = '#ffcf8a') {
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  for (const [rr, a] of [[r * 14, .10], [r * 7, .18], [r * 3.2, .35]]) {
    const g = ctx.createRadialGradient(x, y, 0, x, y, rr); g.addColorStop(0, rgba(glow, a)); g.addColorStop(1, rgba(glow, 0));
    ctx.fillStyle = g; ctx.fillRect(x - rr, y - rr, rr * 2, rr * 2);
  }
  ctx.restore();
  const g = ctx.createRadialGradient(x, y, 0, x, y, r); g.addColorStop(0, '#ffffff'); g.addColorStop(.6, core); g.addColorStop(1, rgba(core, .0));
  ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r * 1.15, 0, 7); ctx.fill();
}
/* God rays fanning out from the sun. */
function rays(x, y, n, len, color, alpha, seed) {
  const R = mulberry32(seed);
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  for (let i = 0; i < n; i++) {
    const a = -Math.PI * (.05 + R() * .9), w = .02 + R() * .05, l = len * (.6 + R() * .5);
    const g = ctx.createRadialGradient(x, y, 0, x, y, l); g.addColorStop(0, rgba(color, alpha * (.5 + R()))); g.addColorStop(1, rgba(color, 0));
    ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(x, y);
    ctx.lineTo(x + Math.cos(a - w) * l, y + Math.sin(a - w) * l); ctx.lineTo(x + Math.cos(a + w) * l, y + Math.sin(a + w) * l); ctx.closePath(); ctx.fill();
  }
  ctx.restore();
}
function haze(y0, y1, color, a0, a1) {
  const g = ctx.createLinearGradient(0, y0, 0, y1); g.addColorStop(0, rgba(color, a0)); g.addColorStop(1, rgba(color, a1));
  ctx.fillStyle = g; ctx.fillRect(0, y0, W, y1 - y0);
}
function clouds(y, seed, color, alpha, count = 7) {
  const R = mulberry32(seed);
  for (let i = 0; i < count; i++) {
    const cx = R() * W * 1.2 - W * .1, cy = y + R() * 260 - 130, w = 300 + R() * 520, h = 26 + R() * 44;
    const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, w / 2); g.addColorStop(0, rgba(color, alpha)); g.addColorStop(1, rgba(color, 0));
    ctx.save(); ctx.translate(cx, cy); ctx.scale(1, h / (w / 2)); ctx.translate(-cx, -cy);
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(cx, cy, w / 2, 0, 7); ctx.fill(); ctx.restore();
  }
}

/* ---------- terrain ---------- */
function ridge(base, amp, color, seed, step = 24) {
  const R = mulberry32(seed), ph = R() * 10, ph2 = R() * 10;
  ctx.fillStyle = color; ctx.beginPath(); ctx.moveTo(0, H);
  for (let x = -20; x <= W + 20; x += step) {
    const y = base - amp * (.55 + .3 * Math.sin(x * .004 + ph) + .15 * Math.sin(x * .013 + ph2)) - R() * amp * .05;
    ctx.lineTo(x, y);
  }
  ctx.lineTo(W, H); ctx.closePath(); ctx.fill();
}
/* A tall fairy chimney with a basalt cap, lit from `lightX` (−1 left … 1 right). */
function chimney(x, base, w, h, o) {
  const R = mulberry32(o.seed || 1), lean = (R() - .5) * w * .25, light = o.light ?? 1;
  const neck = w * .18, top = base - h;
  const body = new Path2D();
  body.moveTo(x - w / 2, base);
  body.bezierCurveTo(x - w * .46, base - h * .35, x - w * .22 + lean * .5, base - h * .7, x - neck + lean, top + w * .1);
  body.lineTo(x + neck + lean, top + w * .1);
  body.bezierCurveTo(x + w * .22 + lean * .5, base - h * .7, x + w * .46, base - h * .35, x + w / 2, base);
  body.closePath();
  const lit = o.lit || '#e8b48a', dark = o.dark || '#5a3440';
  const g = ctx.createLinearGradient(x - w / 2, 0, x + w / 2, 0);
  g.addColorStop(0, light > 0 ? dark : lit); g.addColorStop(.55, mix(lit, dark, .45)); g.addColorStop(1, light > 0 ? lit : dark);
  ctx.fillStyle = g; ctx.fill(body);
  ctx.save(); ctx.clip(body);
  const v = ctx.createLinearGradient(0, top, 0, base); v.addColorStop(0, 'rgba(255,230,200,.10)'); v.addColorStop(.7, 'rgba(0,0,0,0)'); v.addColorStop(1, 'rgba(30,10,20,.45)');
  ctx.fillStyle = v; ctx.fillRect(x - w, top, w * 2, h);
  ctx.strokeStyle = 'rgba(60,25,30,.18)'; ctx.lineWidth = Math.max(1, w * .012);
  for (let i = 0; i < 14; i++) { const sx = x + (R() - .5) * w; ctx.beginPath(); ctx.moveTo(sx, base); ctx.bezierCurveTo(sx + (R() - .5) * 10, base - h * .4, sx * .6 + x * .4, base - h * .8, x + lean, top); ctx.stroke(); }
  /* erosion bands */
  for (let i = 0; i < 5; i++) { const by = base - h * (.15 + R() * .7); ctx.fillStyle = `rgba(255,220,190,${.04 + R() * .05})`; ctx.fillRect(x - w, by, w * 2, h * .015 + R() * 6); }
  /* rim light on the sun side */
  const rim = ctx.createLinearGradient(x + light * w * .5, 0, x + light * w * .28, 0); rim.addColorStop(0, rgba(o.rim || '#ffd9a0', .55)); rim.addColorStop(1, rgba(o.rim || '#ffd9a0', 0));
  ctx.fillStyle = rim; ctx.fillRect(x - w, top, w * 2, h);
  if (o.windows) for (let i = 0; i < o.windows; i++) {
    const wx = x + (R() - .5) * w * .45, wy = base - h * (.18 + R() * .45), ww = w * (.05 + R() * .04);
    ctx.fillStyle = o.lamp ? '#ffcf7a' : 'rgba(30,12,18,.75)';
    ctx.beginPath(); ctx.moveTo(wx - ww / 2, wy + ww * 1.2); ctx.lineTo(wx - ww / 2, wy); ctx.arc(wx, wy, ww / 2, Math.PI, 0); ctx.lineTo(wx + ww / 2, wy + ww * 1.2); ctx.fill();
    if (o.lamp) { ctx.save(); ctx.globalCompositeOperation = 'lighter'; const lg = ctx.createRadialGradient(wx, wy, 0, wx, wy, ww * 3); lg.addColorStop(0, 'rgba(255,190,90,.45)'); lg.addColorStop(1, 'rgba(255,190,90,0)'); ctx.fillStyle = lg; ctx.fillRect(wx - ww * 3, wy - ww * 3, ww * 6, ww * 6); ctx.restore(); }
  }
  if (o.haze) { ctx.fillStyle = rgba(o.hazeColor || '#f0a77a', o.haze); ctx.fillRect(x - w, top - w, w * 2, h + w); }
  ctx.restore();
  /* basalt cap */
  const cw = w * (.36 + R() * .12), ch = cw * .42, cx = x + lean, cy = top + w * .04;
  const cg = ctx.createLinearGradient(cx - cw, 0, cx + cw, 0); cg.addColorStop(0, light > 0 ? '#2a1a20' : '#7a5048'); cg.addColorStop(1, light > 0 ? '#7a5048' : '#2a1a20');
  ctx.fillStyle = cg; ctx.beginPath(); ctx.ellipse(cx, cy, cw, ch * .55, 0, 0, 7); ctx.fill();
  ctx.beginPath(); ctx.moveTo(cx - cw * .8, cy); ctx.quadraticCurveTo(cx - cw * .5, cy - ch * 1.5, cx + cw * .1, cy - ch * 1.35); ctx.quadraticCurveTo(cx + cw * .7, cy - ch * 1.1, cx + cw * .85, cy); ctx.closePath(); ctx.fill();
  ctx.fillStyle = rgba(o.rim || '#ffd9a0', .35); ctx.beginPath(); ctx.ellipse(cx + light * cw * .35, cy - ch * .9, cw * .35, ch * .3, 0, 0, 7); ctx.fill();
  if (o.haze) { ctx.fillStyle = rgba(o.hazeColor || '#f0a77a', o.haze); ctx.beginPath(); ctx.ellipse(cx, cy - ch * .4, cw * 1.05, ch * 1.2, 0, 0, 7); ctx.fill(); }
}
function chimneyField(base, n, minH, maxH, seed, style) {
  const R = mulberry32(seed);
  const items = [];
  for (let i = 0; i < n; i++) items.push({ x: R() * (W + 300) - 150, h: minH + R() * (maxH - minH), s: seed * 100 + i });
  items.sort((a, b) => a.h - b.h);
  for (const it of items) chimney(it.x, base + R() * 20, it.h * (.32 + R() * .12), it.h, Object.assign({ seed: it.s }, style));
}
function mesa(x, base, w, h, body, cap, light = 1) {
  const g = ctx.createLinearGradient(x - w / 2, 0, x + w / 2, 0); g.addColorStop(0, light > 0 ? mix(body, '#2a1420', .45) : body); g.addColorStop(1, light > 0 ? body : mix(body, '#2a1420', .45));
  ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(x - w / 2, base); ctx.lineTo(x - w * .36, base - h * .9); ctx.lineTo(x - w * .3, base - h); ctx.lineTo(x + w * .28, base - h); ctx.lineTo(x + w * .36, base - h * .88); ctx.lineTo(x + w / 2, base); ctx.closePath(); ctx.fill();
  ctx.fillStyle = cap; ctx.fillRect(x - w * .31, base - h - 6, w * .6, 10);
  ctx.fillStyle = 'rgba(255,210,170,.08)'; for (let i = 1; i < 6; i++) ctx.fillRect(x - w * .4, base - h * i / 6, w * .8, 4);
}

/* ---------- balloons ---------- */
/* A hot-air balloon with real gores and volume. (x, y) is the envelope's widest point; R its radius. */
function balloon(x, y, R, cols, o = {}) {
  const nG = o.gores || 12, light = o.light ?? -1, tilt = o.tilt || 0;
  ctx.save(); ctx.translate(x, y); ctx.rotate(tilt); ctx.globalAlpha = o.alpha ?? 1;
  const topY = -R * 1.05, eq = 0, mouth = R * 1.42, mouthW = R * .26;
  const half = yy => {
    if (yy <= eq) { const t = (yy - topY) / (eq - topY); return R * Math.sin(Math.PI / 2 * Math.pow(clamp(t, 0, 1), .62)); }
    const t = (yy - eq) / (mouth - eq); return lerp(R, mouthW, Math.pow(t, 1.25)) * (1 - .08 * Math.sin(Math.PI * t));
  };
  const env = new Path2D(); const steps = 40;
  for (let i = 0; i <= steps; i++) { const yy = lerp(topY, mouth, i / steps); const xx = half(yy); i ? env.lineTo(xx, yy) : env.moveTo(xx, yy); }
  for (let i = steps; i >= 0; i--) { const yy = lerp(topY, mouth, i / steps); env.lineTo(-half(yy), yy); }
  env.closePath();
  ctx.save(); ctx.clip(env);
  /* gores between meridians */
  for (let k = 0; k < nG; k++) {
    const a0 = -Math.PI / 2 + Math.PI * k / nG, a1 = -Math.PI / 2 + Math.PI * (k + 1) / nG;
    const p = new Path2D();
    for (let i = 0; i <= steps; i++) { const yy = lerp(topY - 4, mouth + 4, i / steps), xx = half(yy) * Math.sin(a0) * 1.002; i ? p.lineTo(xx, yy) : p.moveTo(xx, yy); }
    for (let i = steps; i >= 0; i--) { const yy = lerp(topY - 4, mouth + 4, i / steps); p.lineTo(half(yy) * Math.sin(a1) * 1.002, yy); }
    p.closePath(); ctx.fillStyle = cols[k % cols.length]; ctx.fill(p);
  }
  if (o.pattern) pattern(o.pattern, R, topY, mouth, o.pc || ['#ffc23d', '#ffffff']);
  if (o.band) { ctx.fillStyle = o.band; ctx.fillRect(-R, R * .38, R * 2, R * .2); ctx.fillStyle = 'rgba(255,255,255,.5)'; ctx.fillRect(-R, R * .38, R * 2, R * .025); ctx.fillRect(-R, R * .555, R * 2, R * .025); }
  if (o.text) { ctx.fillStyle = o.textColor || '#fff'; ctx.font = `800 ${R * .2}px BC`; ctx.textAlign = 'center'; ctx.fillText(o.text, 0, R * .53); }
  /* volume: key light, core shadow, bounce, and a glow from the flame */
  const kl = ctx.createRadialGradient(light * R * .45, -R * .45, R * .05, light * R * .3, -R * .3, R * 1.3);
  kl.addColorStop(0, 'rgba(255,248,230,.55)'); kl.addColorStop(.35, 'rgba(255,235,210,.12)'); kl.addColorStop(1, 'rgba(255,235,210,0)');
  ctx.fillStyle = kl; ctx.fillRect(-R * 1.2, topY, R * 2.4, mouth - topY);
  const sh = ctx.createLinearGradient(light * R, 0, -light * R, 0);
  sh.addColorStop(0, 'rgba(20,6,30,0)'); sh.addColorStop(.55, 'rgba(20,6,30,.12)'); sh.addColorStop(.85, 'rgba(20,6,30,.48)'); sh.addColorStop(1, 'rgba(20,6,30,.6)');
  ctx.fillStyle = sh; ctx.fillRect(-R * 1.2, topY, R * 2.4, mouth - topY);
  const bot = ctx.createLinearGradient(0, R * .2, 0, mouth); bot.addColorStop(0, 'rgba(20,6,30,0)'); bot.addColorStop(1, 'rgba(20,6,30,.45)');
  ctx.fillStyle = bot; ctx.fillRect(-R * 1.2, R * .2, R * 2.4, mouth);
  if (o.flame) {
    ctx.globalCompositeOperation = 'lighter';
    const fg = ctx.createRadialGradient(0, mouth, 0, 0, mouth, R * 1.3); fg.addColorStop(0, 'rgba(255,170,60,.45)'); fg.addColorStop(.4, 'rgba(255,120,40,.12)'); fg.addColorStop(1, 'rgba(255,120,40,0)');
    ctx.fillStyle = fg; ctx.fillRect(-R * 1.3, -R * .2, R * 2.6, R * 2);
    ctx.globalCompositeOperation = 'source-over';
  }
  /* gore seams */
  ctx.strokeStyle = 'rgba(40,15,30,.22)'; ctx.lineWidth = Math.max(1, R * .006);
  for (let k = 1; k < nG; k++) { const a = -Math.PI / 2 + Math.PI * k / nG; ctx.beginPath(); for (let i = 0; i <= steps; i++) { const yy = lerp(topY, mouth, i / steps), xx = half(yy) * Math.sin(a); i ? ctx.lineTo(xx, yy) : ctx.moveTo(xx, yy); } ctx.stroke(); }
  ctx.restore();
  /* rim light along the lit edge */
  ctx.save(); ctx.strokeStyle = 'rgba(255,225,180,.45)'; ctx.lineWidth = Math.max(1.5, R * .018); ctx.clip(env);
  ctx.beginPath(); for (let i = 0; i <= steps; i++) { const yy = lerp(topY, mouth * .7, i / steps), xx = half(yy) * light; i ? ctx.lineTo(xx, yy) : ctx.moveTo(xx, yy); } ctx.stroke(); ctx.restore();
  if (o.alpha !== undefined && o.alpha < .6 && !o.detail) { ctx.restore(); return; }
  /* skirt, ropes, burner, basket */
  const by = mouth + R * .55, bw = R * .34, bh = R * .26;
  ctx.fillStyle = mix(cols[0], '#1a0a14', .45); ctx.beginPath(); ctx.moveTo(-mouthW, mouth - 2); ctx.lineTo(mouthW, mouth - 2); ctx.lineTo(mouthW * .8, mouth + R * .12); ctx.lineTo(-mouthW * .8, mouth + R * .12); ctx.fill();
  ctx.strokeStyle = 'rgba(50,30,25,.9)'; ctx.lineWidth = Math.max(1, R * .008);
  for (const s of [-1, -.35, .35, 1]) { ctx.beginPath(); ctx.moveTo(s * mouthW * .8, mouth + R * .1); ctx.lineTo(s * bw * .45, by); ctx.stroke(); }
  ctx.fillStyle = '#2a2a30'; ctx.fillRect(-R * .09, by - R * .2, R * .18, R * .08);
  if (o.flame) flame(0, by - R * .2, R * (o.flameScale || .55));
  const bg = ctx.createLinearGradient(-bw / 2, 0, bw / 2, 0); bg.addColorStop(0, '#4a2c18'); bg.addColorStop(.5, '#8a5a32'); bg.addColorStop(1, '#3a2010');
  ctx.fillStyle = bg; ctx.beginPath(); ctx.moveTo(-bw / 2, by); ctx.lineTo(bw / 2, by); ctx.lineTo(bw * .44, by + bh); ctx.lineTo(-bw * .44, by + bh); ctx.closePath(); ctx.fill();
  ctx.strokeStyle = 'rgba(30,15,8,.35)'; ctx.lineWidth = Math.max(1, R * .005);
  for (let i = 1; i < 6; i++) { ctx.beginPath(); ctx.moveTo(-bw / 2, by + bh * i / 6); ctx.lineTo(bw / 2, by + bh * i / 6); ctx.stroke(); }
  ctx.fillStyle = '#2a160c'; ctx.fillRect(-bw / 2 - 2, by - R * .02, bw + 4, R * .035);
  if (o.people) { ctx.fillStyle = '#1d1418'; for (let i = 0; i < o.people; i++) { const px = -bw * .35 + i * bw * .7 / Math.max(1, o.people - 1); ctx.beginPath(); ctx.arc(px, by - R * .05, R * .028, 0, 7); ctx.fill(); ctx.fillRect(px - R * .025, by - R * .03, R * .05, R * .05); } }
  ctx.restore();
}
/* The studio's patterns, painted inside the clipped envelope (origin at the equator). */
function pattern(kind, R, top, mouth, [c2, c3]) {
  const star = (x, y, r, c) => { ctx.fillStyle = c; ctx.beginPath(); for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? r * .45 : r; ctx.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); } ctx.closePath(); ctx.fill(); };
  const heart = (x, y, s, c) => { ctx.fillStyle = c; ctx.beginPath(); ctx.moveTo(x, y + s * .35); ctx.bezierCurveTo(x - s * 1.1, y - s * .35, x - s * .45, y - s * 1.05, x, y - s * .45); ctx.bezierCurveTo(x + s * .45, y - s * 1.05, x + s * 1.1, y - s * .35, x, y + s * .35); ctx.fill(); };
  switch (kind) {
    case 'stars': ctx.fillStyle = c2; ctx.fillRect(-R, -R * .12, R * 2, R * .42); for (const [dx, dy, s] of [[-.5, -.45, .2], [.45, -.5, .17], [0, -.78, .14], [-.35, .75, .15], [.4, .7, .17]]) star(dx * R, dy * R, s * R, c3); break;
    case 'hearts': for (const [dx, dy, s, k] of [[-.45, -.4, .22, 0], [.4, -.5, .2, 1], [0, .05, .3, 0], [-.4, .65, .18, 1], [.42, .6, .2, 0]]) heart(dx * R, dy * R, s * R, k ? c3 : c2); break;
    case 'zigzag': for (let r = 0; r < 4; r++) { ctx.fillStyle = r % 2 ? c3 : c2; ctx.beginPath(); const y0 = top + R * (.5 + r * .6); for (let k = 0; k <= 8; k++) ctx.lineTo(-R + k * R / 4, y0 + (k % 2 ? -R * .14 : R * .14)); for (let k = 8; k >= 0; k--) ctx.lineTo(-R + k * R / 4, y0 + R * .24 + (k % 2 ? -R * .14 : R * .14)); ctx.fill(); } break;
    case 'dots': for (let i = 0; i < 5; i++) for (let j = 0; j < 7; j++) { ctx.fillStyle = (i + j) % 3 ? c2 : c3; ctx.beginPath(); ctx.arc(-R + R * .2 + i * R * .42 + (j % 2) * R * .21, top + R * .25 + j * R * .42, R * .11, 0, 7); ctx.fill(); } break;
    case 'sunburst': for (let k = 0; k < 14; k++) { ctx.fillStyle = k % 2 ? c2 : c3; ctx.beginPath(); ctx.moveTo(0, R * 1.5); const a0 = -Math.PI / 2 + (k - 7) * .16, a1 = a0 + .16; ctx.lineTo(Math.cos(a0) * R * 4, R * 1.5 + Math.sin(a0) * R * 4); ctx.lineTo(Math.cos(a1) * R * 4, R * 1.5 + Math.sin(a1) * R * 4); ctx.fill(); } break;
    case 'waves': ctx.lineWidth = R * .16; ctx.lineCap = 'round'; for (let r = 0; r < 5; r++) { ctx.strokeStyle = r % 2 ? c2 : c3; ctx.beginPath(); const y0 = top + R * (.45 + r * .48); for (let k = 0; k <= 20; k++) { const xx = -R + k * R / 10, yy = y0 + Math.sin(k * .9) * R * .09; k ? ctx.lineTo(xx, yy) : ctx.moveTo(xx, yy); } ctx.stroke(); } break;
    case 'rainbow': { const cs = ['#e5432f', '#ff8a3d', '#ffc23d', '#22a45d', '#3ad0c0', '#9b7be0']; for (let k = 0; k < 6; k++) { ctx.fillStyle = cs[k]; ctx.fillRect(-R + k * R / 3, top, R / 3 + .6, mouth - top + 10); } break; }
    case 'checker': { const s = R * .4; for (let i = 0; i < 6; i++) for (let j = 0; j < 8; j++) if ((i + j) % 2) { ctx.fillStyle = (i + j) % 4 === 1 ? c2 : c3; ctx.fillRect(-R + i * s, top + j * s, s, s); } break; }
  }
}
function flame(x, y, s) {
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  const glow = ctx.createRadialGradient(x, y - s * .6, 0, x, y - s * .6, s * 2.2); glow.addColorStop(0, 'rgba(255,190,80,.7)'); glow.addColorStop(.35, 'rgba(255,120,40,.22)'); glow.addColorStop(1, 'rgba(255,90,30,0)');
  ctx.fillStyle = glow; ctx.fillRect(x - s * 2.2, y - s * 2.8, s * 4.4, s * 4.4);
  /* soft, flickering tongues instead of hard cones */
  const layers = [['#ff5a1f', 1, 14], ['#ffa531', .74, 9], ['#ffe08a', .5, 6], ['#fffbe8', .26, 3]];
  ctx.globalCompositeOperation = 'source-over';
  for (const [c, k, blur] of layers) {
    const w = s * .3 * k, h = s * 1.25 * k;
    ctx.filter = `blur(${Math.max(1, s * blur / 120)}px)`;
    ctx.fillStyle = c; ctx.beginPath(); ctx.moveTo(x - w, y);
    ctx.bezierCurveTo(x - w * 1.25, y - h * .35, x - w * .55, y - h * .55, x - w * .35, y - h * .78);
    ctx.quadraticCurveTo(x - w * .15, y - h * .62, x - w * .05, y - h);
    ctx.quadraticCurveTo(x + w * .2, y - h * .7, x + w * .4, y - h * .86);
    ctx.bezierCurveTo(x + w * .55, y - h * .55, x + w * 1.25, y - h * .35, x + w, y);
    ctx.quadraticCurveTo(x, y + w * .5, x - w, y); ctx.closePath(); ctx.fill();
  }
  ctx.filter = 'none';
  ctx.restore();
}
const PALETTES = [['#ff5e3a', '#ffc23d'], ['#14a39a', '#e8fff9'], ['#2b2350', '#ffc23d'], ['#ff6fa8', '#fff0f6'], ['#5aa9e6', '#eaf4fc'], ['#9b7be0', '#f2ebff'], ['#22a45d', '#fff3b0'], ['#e5432f', '#ffffff'], ['#ffc23d', '#e5432f'], ['#3ad0c0', '#1f6f8b']];
/* Many balloons at different depths; far ones sink into the haze. */
function balloonSky(n, seed, yMin, yMax, rMin, rMax, hazeColor, o = {}) {
  const R = mulberry32(seed), list = [];
  for (let i = 0; i < n; i++) list.push({ x: R() * W, y: lerp(yMin, yMax, R()), d: R(), c: o.colors ? o.colors[i % o.colors.length] : PALETTES[Math.floor(R() * PALETTES.length)] });
  list.sort((a, b) => a.d - b.d);
  for (const b of list) {
    const r = lerp(rMin, rMax, Math.pow(b.d, 2.2)), k = 1 - b.d;
    const cols = b.c.map(c => mix(c, hazeColor, k * .75));
    balloon(b.x, b.y + (1 - b.d) * 200, r, cols, { gores: 10, light: o.light ?? -1, alpha: lerp(.55, 1, b.d), detail: r > 40, flame: r > 60 && R() < .3, flameScale: .4 });
  }
}

/* ---------- finishing ---------- */
function vignette(a = .55) {
  const g = ctx.createRadialGradient(W / 2, H * .5, H * .25, W / 2, H * .5, H * .78); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, `rgba(8,2,14,${a})`);
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
}
function grain(a = 10, seed = 3) {
  const img = ctx.getImageData(0, 0, W, H), d = img.data, R = mulberry32(seed);
  for (let i = 0; i < d.length; i += 4) { const n = (R() - .5) * a; d[i] += n; d[i + 1] += n; d[i + 2] += n; }
  ctx.putImageData(img, 0, 0);
}
function letterbox(top = 0, bottom = 0) { ctx.fillStyle = '#07030c'; if (top) ctx.fillRect(0, 0, W, top); if (bottom) ctx.fillRect(0, H - bottom, W, bottom); }
/* Big poster headline: kicker, then gold-white lines. */
function headline(y, kicker, lines, o = {}) {
  const sc = ctx.createLinearGradient(0, 0, 0, o.scrim || 1150); sc.addColorStop(0, 'rgba(8,3,18,.82)'); sc.addColorStop(.6, 'rgba(8,3,18,.45)'); sc.addColorStop(1, 'rgba(8,3,18,0)');
  ctx.fillStyle = sc; ctx.fillRect(0, 0, W, o.scrim || 1150);
  ctx.save(); ctx.textAlign = 'center';
  if (kicker) {
    ctx.font = '700 46px BC'; ctx.letterSpacing = '10px'; ctx.fillStyle = o.kickerColor || '#ffcf7a';
    ctx.shadowColor = 'rgba(0,0,0,.6)'; ctx.shadowBlur = 18; ctx.fillText(kicker, W / 2, y); y += 40;
    ctx.letterSpacing = '0px';
  }
  let size = o.size || 150;
  ctx.font = `800 ${size}px BC`;
  const widest = Math.max(...lines.map(l => ctx.measureText(l).width));
  if (widest > W - 130) { size = Math.floor(size * (W - 130) / widest); ctx.font = `800 ${size}px BC`; }
  for (const line of lines) {
    y += size * .95;
    const g = ctx.createLinearGradient(0, y - size, 0, y + 10); g.addColorStop(0, '#ffffff'); g.addColorStop(.55, '#fff1d0'); g.addColorStop(1, o.gold || '#ffc23d');
    ctx.shadowColor = 'rgba(10,2,20,.75)'; ctx.shadowBlur = 40; ctx.shadowOffsetY = 8;
    ctx.fillStyle = g; ctx.fillText(line, W / 2, y);
  }
  ctx.restore();
  return y;
}
function subline(y, text, size = 54) {
  ctx.save(); ctx.textAlign = 'center'; ctx.font = `600 ${size}px B`; ctx.fillStyle = 'rgba(255,245,230,.92)';
  ctx.shadowColor = 'rgba(0,0,0,.7)'; ctx.shadowBlur = 20; ctx.fillText(text, W / 2, y); ctx.restore();
}
function brand(y) {
  ctx.save(); ctx.textAlign = 'center'; ctx.font = '800 64px BC'; ctx.letterSpacing = '6px';
  ctx.fillStyle = 'rgba(255,255,255,.95)'; ctx.shadowColor = 'rgba(0,0,0,.7)'; ctx.shadowBlur = 20;
  ctx.fillText('BALLOON BARON', W / 2, y); ctx.font = '700 34px BC'; ctx.letterSpacing = '14px'; ctx.fillStyle = '#ffcf7a'; ctx.fillText('CAPPADOCIA', W / 2, y + 48); ctx.restore();
}
function rrect(x, y, w, h, r) { ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath(); }
/* Frosted in-game card floating over the scene. */
function card(x, y, w, h, title, lines, accent = '#22a45d', icon) {
  ctx.save(); ctx.shadowColor = 'rgba(10,0,20,.55)'; ctx.shadowBlur = 50; ctx.shadowOffsetY = 18;
  ctx.fillStyle = 'rgba(255,250,243,.95)'; rrect(x, y, w, h, 40); ctx.fill(); ctx.restore();
  ctx.fillStyle = accent; rrect(x, y + 34, 12, h - 68, 6); ctx.fill();
  let tx = x + 50;
  if (icon) { icon(x + 95, y + h / 2); tx = x + 170; }
  ctx.fillStyle = '#2b2350'; ctx.font = '800 58px BC'; ctx.fillText(title, tx, y + 82);
  ctx.font = '600 40px B';
  lines.forEach((l, i) => { ctx.fillStyle = i === lines.length - 1 ? accent : '#6c6488'; ctx.fillText(l, tx, y + 138 + i * 50); });
}
function crown(x, y, s) {
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  ctx.globalCompositeOperation = 'lighter'; const gl = ctx.createRadialGradient(0, 0, 0, 0, 0, 120); gl.addColorStop(0, 'rgba(255,200,80,.5)'); gl.addColorStop(1, 'rgba(255,200,80,0)'); ctx.fillStyle = gl; ctx.fillRect(-120, -120, 240, 240); ctx.globalCompositeOperation = 'source-over';
  const g = ctx.createLinearGradient(0, -40, 0, 40); g.addColorStop(0, '#fff3b0'); g.addColorStop(.5, '#ffc23d'); g.addColorStop(1, '#c98a00');
  ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(-58, 34); ctx.lineTo(-64, -26); ctx.lineTo(-30, 2); ctx.lineTo(0, -44); ctx.lineTo(30, 2); ctx.lineTo(64, -26); ctx.lineTo(58, 34); ctx.closePath(); ctx.fill();
  ctx.fillStyle = '#e0a400'; ctx.fillRect(-58, 30, 116, 14);
  for (const [cx, cy, c] of [[0, 4, '#ff5e3a'], [-34, 14, '#3ad0c0'], [34, 14, '#3ad0c0']]) { ctx.fillStyle = c; ctx.beginPath(); ctx.arc(cx, cy, 7, 0, 7); ctx.fill(); }
  ctx.restore();
}

/* ---------- slides ---------- */
