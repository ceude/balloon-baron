/* A made-up isometric balloon town for the growth montages (not the game's town: an ad's version, built for
   spectacle). It starts as a construction site (dirt plots, scaffolding, a crane, one balloon) and builds itself
   in steps: each building rises out of the ground with squash and stretch, a dust puff and its scaffolding
   dropping away; roads run out, trees and flags appear, the hangar and the HQ tower grow, the field fills with
   balloons, and at the last step the lights come on.
   town(f, o): o.steps = frames at which steps 1..8 begin (step 0 is there from the start), o.count = the fleet
   counter (balloons on the field and in the air), o.zoom, o.t. */
const TOWN = (() => {
  const N = 14, R = mulberry32(404), items = [], used = new Set(), key = (i, j) => i + ',' + j;
  const take = (i, j, w = 1, d = 1) => { for (let a = 0; a < w; a++) for (let b = 0; b < d; b++) used.add(key(i + a, j + b)); };
  const free = (i, j, w = 1, d = 1) => { for (let a = 0; a < w; a++) for (let b = 0; b < d; b++) { const ii = i + a, jj = j + b; if (ii < 0 || jj < 0 || ii >= N || jj >= N || used.has(key(ii, jj))) return false; } return true; };
  /* roads: the main street and the cross street, built out from the middle */
  const roads = [];
  for (let k = 0; k < N; k++) { roads.push({ i: 7, j: k, step: Math.min(8, 1 + Math.floor(Math.abs(k - 7) / 1.6)) }); if (k !== 7) roads.push({ i: k, j: 7, step: Math.min(8, 1 + Math.floor(Math.abs(k - 7) / 1.6)) }); take(7, k); take(k, 7); }
  /* the launch field */
  const field = { i: 3, j: 8, w: 4, d: 3 }; take(3, 8, 4, 3);
  items.push({ type: 'hangar', i: 9, j: 9, w: 3, d: 2, h: [0, 55, 55, 55, 90, 90, 90, 120, 120], step: 1 }); take(9, 9, 3, 2);
  items.push({ type: 'hq', i: 4, j: 3, w: 2, d: 2, h: [0, 0, 0, 120, 120, 250, 250, 400, 400], step: 3 }); take(4, 3, 2, 2);
  items.push({ type: 'shack', i: 8, j: 8, w: 1, d: 1, h: 34, step: 0 }); take(8, 8);
  items.push({ type: 'crane', i: 9, j: 4, step: 0, gone: 7 }); take(9, 4);
  /* houses, more of them in the later steps; nearer the middle first */
  const spots = [];
  for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) if (free(i, j)) spots.push({ i, j, d: Math.hypot(i - 7, j - 7) + R() * 2.5 });
  spots.sort((a, b) => a.d - b.d);
  const plan = [[1, 4], [2, 3], [3, 6], [4, 6], [5, 8], [6, 8], [7, 12], [8, 6]];
  let s = 0;
  for (const [step, n] of plan) for (let k = 0; k < n && s < spots.length; k++, s++) {
    const p = spots[s], r = R();
    const type = r < .16 ? 'cave' : r < .27 ? 'stall' : r < .37 && step >= 3 ? 'dome' : 'house';
    items.push({ type, i: p.i, j: p.j, w: 1, d: 1, h: type === 'stall' ? 26 : type === 'cave' ? 150 + R() * 70 : 44 + R() * 46 + step * 4, step, col: ['#f6dcb4', '#f0cfa0', '#f8e4c4', '#ecc49a', '#f3d6b0'][Math.floor(R() * 5)], aw: ['#e5432f', '#14a39a', '#ffc23d', '#9b7be0', '#ff6fa8'][Math.floor(R() * 5)], seed: Math.floor(R() * 1e5), stag: Math.floor(R() * 7) });
    take(p.i, p.j);
  }
  /* trees and flags in what is left near the streets */
  const rest = []; for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) if (free(i, j)) rest.push({ i, j, d: Math.hypot(i - 7, j - 7) });
  rest.sort((a, b) => a.d - b.d);
  rest.slice(0, 26).forEach((p, k) => items.push({ type: k % 4 === 3 ? 'flag' : 'tree', i: p.i + .5, j: p.j + .5, step: 2 + (k % 7), stag: k % 6, aw: ['#e5432f', '#14a39a', '#ffc23d', '#9b7be0', '#5aa9e6'][k % 5], seed: k }));
  /* string lights between the street corners (lit at the last step) */
  const lights = [[[3, 6.6], [11, 6.6]], [[6.6, 2], [6.6, 12]], [[8.4, 3], [8.4, 12]]];
  return { N, items, roads, field, lights };
})();

function town(f, o) {
  const T = TOWN, steps = o.steps, t = o.t || f / FPS;
  const stepAt = st => st <= 0 ? -1e9 : steps[st - 1];
  const cur = steps.filter(x => f >= x).length; /* how many steps have begun */
  const lit = clamp((f - stepAt(8)) / 18, 0, 1);
  const s = o.zoom || 1, cx = W / 2, cy = 1240 + (o.dy || 0), hw = 62 * s, hh = 31 * s;
  const P = (i, j, z = 0) => [cx + (i - j) * hw, cy + (i + j - T.N) * hh - z * s];
  /* sky: the dawn layers moved so their horizon sits at the top of the town */
  const D = buildDawn(), hy = cy - T.N * hh * .98;
  ctx.drawImage(D.sky, -MARGIN, hy - HZ + 40);
  const [sx, sy] = [W * .55, hy - 20];
  rays(sx, sy, 30, 1800, '#ffd6a0', .07, 12); sun(sx, sy, 60);
  ctx.drawImage(D.ridges, -MARGIN, hy - HZ - 30); ctx.drawImage(D.far, -MARGIN, hy - HZ - 120);
  /* ground */
  let g = ctx.createLinearGradient(0, hy - 10, 0, H); g.addColorStop(0, '#e9b48a'); g.addColorStop(.12, '#e8c293'); g.addColorStop(1, '#d6a271');
  ctx.fillStyle = g; ctx.fillRect(0, hy - 6, W, H);
  g = ctx.createLinearGradient(0, hy - 6, 0, hy + 140); g.addColorStop(0, 'rgba(255,190,150,.7)'); g.addColorStop(1, 'rgba(255,190,150,0)'); ctx.fillStyle = g; ctx.fillRect(0, hy - 6, W, 146);
  const poly = (pts, fill) => { ctx.beginPath(); pts.forEach((p, k) => k ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1])); ctx.closePath(); ctx.fillStyle = fill; ctx.fill(); };
  const tile = (i, j, w, d, fill) => poly([P(i, j), P(i + w, j), P(i + w, j + d), P(i, j + d)], fill);
  /* the lot, its grid, plots */
  tile(0, 0, T.N, T.N, '#e2b884');
  ctx.strokeStyle = 'rgba(150,100,60,.12)'; ctx.lineWidth = 1;
  for (let k = 0; k <= T.N; k++) { let a = P(k, 0), b = P(k, T.N); ctx.beginPath(); ctx.moveTo(a[0], a[1]); ctx.lineTo(b[0], b[1]); ctx.stroke(); a = P(0, k); b = P(T.N, k); ctx.beginPath(); ctx.moveTo(a[0], a[1]); ctx.lineTo(b[0], b[1]); ctx.stroke(); }
  for (const it of T.items) if (it.w) tile(it.i + .05, it.j + .05, it.w - .1, it.d - .1, f >= stepAt(it.step) ? '#cfa274' : 'rgba(150,100,70,.35)');
  /* roads run out from the middle */
  for (const r of T.roads) {
    const k = prog(f, stepAt(r.step), stepAt(r.step) + 8); if (k <= 0) continue;
    const m = (1 - eOut(k)) * .5; tile(r.i + m, r.j + m, 1 - 2 * m, 1 - 2 * m, '#8a6a58');
    if (k > .6) { const a = P(r.i + .5, r.j + .5); ctx.fillStyle = 'rgba(255,240,200,.5)'; ctx.fillRect(a[0] - 4 * s, a[1] - 1, 8 * s, 2); }
  }
  /* the field */
  const F = T.field; tile(F.i, F.j, F.w, F.d, '#9ccf6a'); tile(F.i + .15, F.j + .15, F.w - .3, F.d - .3, '#b4dc7c');
  /* everything that stands, back to front */
  const list = [];
  for (const it of T.items) list.push({ z: it.i + it.j + (it.w || 0) + (it.d || 0), it });
  const onField = Math.round(clamp(o.count / 164, 0, 1) * 11) + 1;
  for (let k = 0; k < onField; k++) { const i = F.i + .5 + (k % 4), j = F.j + .5 + Math.floor(k / 4) % 3; list.push({ z: i + j + .5, bal: { i, j, k } }); }
  list.sort((a, b) => a.z - b.z);
  const dusts = [];
  for (const e of list) {
    if (e.bal) { const [x, y] = P(e.bal.i, e.bal.j); const r = 15 * s; spriteBalloon(SPRITES.near[e.bal.k % 10], x, y - r * 2.6, r, Math.sin(t * 3 + e.bal.k) > .6 ? .8 : 0, t); continue; }
    const it = e.it, st = stepAt(it.step) + (it.stag || 0);
    /* the scaffolding before and while it rises */
    if (it.type !== 'crane' && it.w && f >= st - 30 && f < st + 10 && it.step > 0) scaffold(it, f - st, P, s);
    if (f < st) continue;
    const k = prog(f, st, st + 12);
    if (it.step > 0 && f - st < 16) dusts.push([it, f - st]);
    drawItem(it, f, k, P, s, t, cur, stepAt, lit);
  }
  for (const [it, a] of dusts) dust(it, a, P, s);
  /* string lights */
  if (lit > 0) {
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    for (const [a, b] of T.lights) for (let k = 0; k <= 24; k++) {
      const u = k / 24, p = P(lerp(a[0], b[0], u), lerp(a[1], b[1], u), 70 + Math.sin(u * Math.PI * 6) * -8);
      const gl = ctx.createRadialGradient(p[0], p[1], 0, p[0], p[1], 12 * s); gl.addColorStop(0, `rgba(255,220,140,${.9 * lit})`); gl.addColorStop(1, 'rgba(255,200,100,0)');
      ctx.fillStyle = gl; ctx.fillRect(p[0] - 12 * s, p[1] - 12 * s, 24 * s, 24 * s);
    }
    ctx.restore();
  }
  /* the air above it: more balloons as the fleet grows, rising off the field */
  const n = Math.round(lerp(0, 46, clamp(o.count / 164, 0, 1)));
  const RB = mulberry32(77);
  for (let k = 0; k < 46; k++) {
    const x0 = RB() * W, sp = 30 + RB() * 50, ph = RB() * 40, d = RB(), ds = RB();
    if (k >= n) continue;
    const y = cy - ((t * sp + ph * 30) % 900) - 150 * d, r = (12 + 30 * d * d) * s;
    spriteBalloon(SPRITES.near[k % 10], x0 + Math.sin(t + k) * 10, y, r, ds > .6 ? 1 : 0, t);
  }
  /* the warm evening tint when the lights come on */
  if (lit > 0) { ctx.save(); ctx.globalCompositeOperation = 'multiply'; ctx.fillStyle = `rgba(200,150,190,${.35 * lit})`; ctx.fillRect(0, 0, W, H); ctx.restore(); }
  if (lit > 0) relight(list, f, P, s, lit, stepAt);
}
function scaffold(it, a, P, s) {
  const h = (typeof it.h === 'number' ? it.h : 60) * .7, drop = a > 0 ? eIn(clamp(a / 10, 0, 1)) : 0, appear = clamp((a + 30) / 8, 0, 1);
  ctx.save(); ctx.globalAlpha = appear * (1 - drop); ctx.strokeStyle = '#8a5a34'; ctx.lineWidth = 2.2 * s;
  const z0 = -drop * 60;
  const c = [[it.i, it.j], [it.i + it.w, it.j], [it.i + it.w, it.j + it.d], [it.i, it.j + it.d]];
  for (const [i, j] of c) { const a1 = P(i, j, z0), b1 = P(i, j, z0 + h); ctx.beginPath(); ctx.moveTo(a1[0], a1[1] + drop * 40); ctx.lineTo(b1[0], b1[1] + drop * 40); ctx.stroke(); }
  for (const z of [h * .35, h * .7, h]) { ctx.beginPath(); c.forEach(([i, j], k) => { const p = P(i, j, z0 + z); k ? ctx.lineTo(p[0], p[1] + drop * 40) : ctx.moveTo(p[0], p[1] + drop * 40); }); ctx.closePath(); ctx.stroke(); }
  ctx.restore();
}
function dust(it, a, P, s) {
  const [x, y] = P(it.i + (it.w || 0) / 2, it.j + (it.d || 0) / 2), k = a / 16;
  ctx.save();
  for (let q = 0; q < 12; q++) {
    const ang = q / 12 * Math.PI * 2, r = (20 + 50 * eOut(k)) * s * (it.w || 1), px = x + Math.cos(ang) * r, py = y + Math.sin(ang) * r * .5 - 10 * k * s;
    const g = ctx.createRadialGradient(px, py, 0, px, py, 16 * s * (1 + k)); g.addColorStop(0, `rgba(240,214,176,${.75 * (1 - k)})`); g.addColorStop(1, 'rgba(240,214,176,0)');
    ctx.fillStyle = g; ctx.fillRect(px - 32 * s, py - 32 * s, 64 * s, 64 * s);
  }
  ctx.restore();
}
/* an iso box with squash and stretch (sy: height factor, sq: footprint factor about its middle) */
function box(P, i, j, w, d, h, top, left, right, sq = 1) {
  const ci = i + w / 2, cj = j + d / 2, a = w / 2 * sq, b = d / 2 * sq;
  const p = (u, v, z) => P(ci + u, cj + v, z);
  const poly = (pts, fill) => { ctx.beginPath(); pts.forEach((q, k) => k ? ctx.lineTo(q[0], q[1]) : ctx.moveTo(q[0], q[1])); ctx.closePath(); ctx.fillStyle = fill; ctx.fill(); };
  /* the long morning shadow, away from the sun */
  const sl = h / 55;
  poly([p(-a, -b, 0), p(-a, b, 0), p(-a - sl, b + sl * .25, 0), p(-a - sl, -b + sl * .25, 0)], 'rgba(90,40,50,.22)');
  poly([p(-a, b, 0), p(a, b, 0), p(a - sl, b + sl * .25, 0), p(-a - sl, b + sl * .25, 0)], 'rgba(90,40,50,.22)');
  const fg = (c, z0, z1) => { const q0 = p(0, b, z0), q1 = p(0, b, z1), g = ctx.createLinearGradient(0, q1[1], 0, q0[1]); g.addColorStop(0, mix(c, '#ffffff', .08)); g.addColorStop(1, mix(c, '#5a2a30', .22)); return g; };
  poly([p(-a, b, 0), p(a, b, 0), p(a, b, h), p(-a, b, h)], fg(left, 0, h));
  poly([p(a, -b, 0), p(a, b, 0), p(a, b, h), p(a, -b, h)], fg(right, 0, h));
  poly([p(-a, -b, h), p(a, -b, h), p(a, b, h), p(-a, b, h)], top);
  return { p, a, b };
}
function windowsOn(bx, h, n, lit, rows = 1) {
  for (let r = 0; r < rows; r++) for (let k = 0; k < n; k++) {
    const u = -bx.a + bx.a * 2 * (k + .5) / n, z = h * (rows > 1 ? (r + .4) / rows : .38), wz = Math.min(18, h / rows * .45);
    for (const face of ['L', 'R']) {
      const q = face === 'L' ? [bx.p(u - .09, bx.b, z), bx.p(u + .09, bx.b, z), bx.p(u + .09, bx.b, z + wz), bx.p(u - .09, bx.b, z + wz)]
        : [bx.p(bx.a, u - .09, z), bx.p(bx.a, u + .09, z), bx.p(bx.a, u + .09, z + wz), bx.p(bx.a, u - .09, z + wz)];
      ctx.beginPath(); q.forEach((p, m) => m ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1])); ctx.closePath();
      ctx.fillStyle = lit ? mix('#3a2a30', '#ffd27a', lit) : '#3a2a30'; ctx.fill();
    }
  }
}
function drawItem(it, f, k, P, s, t, cur, stepAt, lit) {
  const sy = it.step > 0 ? eBack(k, 2.6) : 1, sq = it.step > 0 ? clamp(1 + (1 - sy) * .5, .85, 1.25) : 1;
  if (it.type === 'house' || it.type === 'shack' || it.type === 'dome') {
    const h = it.h * sy, c = it.col || '#efd2aa';
    const bx = box(P, it.i + .12, it.j + .12, .76, .76, h, mix(c, '#ffffff', .2), mix(c, '#7a4a3a', .28), mix(c, '#ffffff', .05), sq);
    windowsOn(bx, h, 2, lit, h > 70 ? 2 : 1);
    /* a door and, on some, a coloured awning */
    { const d0 = bx.p(bx.a, -.08, 0), d1 = bx.p(bx.a, .08, 0), d2 = bx.p(bx.a, .08, Math.min(22, h * .4)), d3 = bx.p(bx.a, -.08, Math.min(22, h * .4)); ctx.fillStyle = '#6a3a2a'; ctx.beginPath(); [d0, d1, d2, d3].forEach((q, m) => m ? ctx.lineTo(q[0], q[1]) : ctx.moveTo(q[0], q[1])); ctx.closePath(); ctx.fill(); }
    if (it.seed % 3 === 0) { const z = Math.min(26, h * .45), q = [bx.p(-bx.a, bx.b, z), bx.p(bx.a, bx.b, z), bx.p(bx.a, bx.b + .18, z - 8), bx.p(-bx.a, bx.b + .18, z - 8)]; ctx.fillStyle = it.aw; ctx.beginPath(); q.forEach((p2, m) => m ? ctx.lineTo(p2[0], p2[1]) : ctx.moveTo(p2[0], p2[1])); ctx.closePath(); ctx.fill(); }
    /* parapet */
    const tp = [bx.p(-bx.a, -bx.b, h), bx.p(bx.a, -bx.b, h), bx.p(bx.a, bx.b, h), bx.p(-bx.a, bx.b, h)];
    ctx.strokeStyle = mix(c, '#7a4a3a', .35); ctx.lineWidth = 2 * s; ctx.beginPath(); tp.forEach((q, m) => m ? ctx.lineTo(q[0], q[1]) : ctx.moveTo(q[0], q[1])); ctx.closePath(); ctx.stroke();
    if (it.type === 'dome') { const q = bx.p(0, 0, h); const g = ctx.createRadialGradient(q[0] + 6 * s, q[1] - 14 * s, 2, q[0], q[1] - 6 * s, 26 * s); g.addColorStop(0, '#9fe0f0'); g.addColorStop(1, '#2a8aa8'); ctx.fillStyle = g; ctx.beginPath(); ctx.ellipse(q[0], q[1], 22 * s * sq, 24 * s * sy, 0, Math.PI, 0); ctx.fill(); }
  } else if (it.type === 'stall') {
    const h = it.h * sy, bx = box(P, it.i + .2, it.j + .2, .6, .6, h, it.aw, mix(it.aw, '#3a1a20', .35), mix(it.aw, '#ffffff', .25), sq);
    const q = bx.p(0, 0, h); ctx.fillStyle = '#fff6e6'; for (let m = -1; m <= 1; m++) { ctx.fillRect(q[0] + m * 12 * s - 2 * s, q[1] - 2 * s, 4 * s, 4 * s); }
  } else if (it.type === 'cave') {
    const [x, y] = P(it.i + .5, it.j + .5), h = it.h * s * sy;
    chimney(x, y + 6 * s, h * .42 * sq, h, { seed: it.seed, light: 1, lit: '#f0c49a', dark: '#9a5a4a', rim: '#ffe0b0', windows: 3, lamp: lit > .5 });
  } else if (it.type === 'hangar') {
    const hs = it.h, ha = hs[Math.min(cur, 8)], hb = hs[Math.max(0, Math.min(cur, 8) - 1)], kk = prog(f, stepAt(Math.max(1, cur)), stepAt(Math.max(1, cur)) + 12);
    const h = (cur <= 1 ? ha * sy : lerp(hb, ha, eBack(kk, 2.2)));
    const bx = box(P, it.i, it.j, it.w, it.d, h, '#c4483a', '#a8584a', '#e8c49a', sq);
    windowsOn(bx, h, 4, lit, h > 80 ? 2 : 1);
    /* the barrel roof: a red ridge along the long side */
    const r = Math.min(40, h * .4); ctx.fillStyle = '#d84a34';
    const a1 = bx.p(-bx.a, -bx.b, h), a2 = bx.p(bx.a, -bx.b, h), a3 = bx.p(bx.a, bx.b, h), a4 = bx.p(-bx.a, bx.b, h), m1 = bx.p(-bx.a, 0, h + r), m2 = bx.p(bx.a, 0, h + r);
    ctx.beginPath(); ctx.moveTo(a4[0], a4[1]); ctx.lineTo(m1[0], m1[1]); ctx.lineTo(m2[0], m2[1]); ctx.lineTo(a3[0], a3[1]); ctx.closePath(); ctx.fill();
    ctx.fillStyle = '#a8301e'; ctx.beginPath(); ctx.moveTo(a2[0], a2[1]); ctx.lineTo(m2[0], m2[1]); ctx.lineTo(a3[0], a3[1]); ctx.closePath(); ctx.fill();
    ctx.fillStyle = '#ffd27a'; const dd = bx.p(bx.a, 0, 0), de = bx.p(bx.a, 0, h * .7); ctx.globalAlpha = .55 + .45 * lit; ctx.fillRect(dd[0] - 14 * s, de[1], 28 * s, dd[1] - de[1]); ctx.globalAlpha = 1;
  } else if (it.type === 'hq') {
    const hs = it.h, ha = hs[Math.min(cur, 8)], hb = hs[Math.max(0, Math.min(cur, 8) - 1)], kk = prog(f, stepAt(Math.max(1, cur)), stepAt(Math.max(1, cur)) + 12);
    const h = cur <= 3 ? ha * sy : lerp(hb, ha, eBack(kk, 2.2));
    if (h <= 1) return;
    const bx = box(P, it.i + .1, it.j + .1, it.w - .2, it.d - .2, h, '#cfe8f4', '#3a6a9a', '#8ac0e0', sq);
    windowsOn(bx, h, 3, lit, Math.max(1, Math.round(h / 34)));
    if (cur >= 7) { /* the gold crown on top */
      const q = bx.p(0, 0, h), kc = eBack(prog(f, stepAt(7), stepAt(7) + 12), 2.5), cs = 30 * s * kc;
      ctx.fillStyle = '#ffcf4a'; ctx.beginPath(); ctx.moveTo(q[0] - cs, q[1]); ctx.lineTo(q[0] - cs * 1.1, q[1] - cs * 1.1); ctx.lineTo(q[0] - cs * .45, q[1] - cs * .5); ctx.lineTo(q[0], q[1] - cs * 1.4); ctx.lineTo(q[0] + cs * .45, q[1] - cs * .5); ctx.lineTo(q[0] + cs * 1.1, q[1] - cs * 1.1); ctx.lineTo(q[0] + cs, q[1]); ctx.closePath(); ctx.fill();
      ctx.save(); ctx.globalCompositeOperation = 'lighter'; const g = ctx.createRadialGradient(q[0], q[1] - cs * .6, 0, q[0], q[1] - cs * .6, cs * 4); g.addColorStop(0, 'rgba(255,210,120,.5)'); g.addColorStop(1, 'rgba(255,210,120,0)'); ctx.fillStyle = g; ctx.fillRect(q[0] - cs * 4, q[1] - cs * 5, cs * 8, cs * 8); ctx.restore();
    }
  } else if (it.type === 'crane') {
    if (cur >= it.gone && f > stepAt(it.gone) + 10) return;
    const go = cur >= it.gone ? prog(f, stepAt(it.gone), stepAt(it.gone) + 10) : 0;
    const [x, y] = P(it.i + .5, it.j + .5), H2 = 300 * s, sw = Math.sin(t * .8) * .35;
    ctx.save(); ctx.globalAlpha = 1 - go; ctx.strokeStyle = '#f0a020'; ctx.lineWidth = 6 * s;
    ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x, y - H2); ctx.stroke();
    const ex = x + Math.cos(sw) * 170 * s, ey = y - H2 + Math.sin(sw) * 20 * s;
    ctx.beginPath(); ctx.moveTo(x - 50 * s, y - H2); ctx.lineTo(ex, ey); ctx.stroke();
    ctx.lineWidth = 1.5 * s; ctx.strokeStyle = '#5a3a2a'; ctx.beginPath(); ctx.moveTo(ex - 20 * s, ey); ctx.lineTo(ex - 20 * s, ey + 90 * s); ctx.stroke();
    ctx.fillStyle = '#7a5a3a'; ctx.fillRect(ex - 34 * s, ey + 90 * s, 28 * s, 16 * s);
    ctx.restore();
  } else if (it.type === 'tree') {
    const [x, y] = P(it.i, it.j), r = 15 * s * sy;
    ctx.fillStyle = '#6a4a2a'; ctx.fillRect(x - 2 * s, y - 14 * s, 4 * s, 14 * s);
    const g = ctx.createRadialGradient(x + 4 * s, y - 26 * s, 2, x, y - 22 * s, r * 1.3); g.addColorStop(0, '#8ad06a'); g.addColorStop(1, '#2a7a3a');
    ctx.fillStyle = g; ctx.beginPath(); ctx.ellipse(x, y - 22 * s, r, r * 1.15, 0, 0, 7); ctx.fill();
  } else if (it.type === 'flag') {
    const [x, y] = P(it.i, it.j), hh = 46 * s * sy;
    ctx.strokeStyle = '#5a4a40'; ctx.lineWidth = 2 * s; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x, y - hh); ctx.stroke();
    const wv = Math.sin(t * 6 + it.seed) * 4 * s; ctx.fillStyle = it.aw; ctx.beginPath(); ctx.moveTo(x, y - hh); ctx.lineTo(x + 22 * s, y - hh + 6 * s + wv); ctx.lineTo(x, y - hh + 13 * s); ctx.closePath(); ctx.fill();
  }
}
/* when the lights come on: glowing windows and halos over the tinted scene */
function relight(list, f, P, s, lit, stepAt) {
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  for (const e of list) {
    const it = e.it; if (!it || f < stepAt(it.step)) continue;
    if (!['house', 'dome', 'hq', 'hangar', 'shack', 'stall'].includes(it.type)) continue;
    const [x, y] = P(it.i + (it.w || 1) / 2, it.j + (it.d || 1) / 2, it.type === 'hq' ? 120 : 30), r = (it.type === 'hq' ? 140 : it.type === 'hangar' ? 110 : 46) * s;
    const g = ctx.createRadialGradient(x, y, 0, x, y, r); g.addColorStop(0, `rgba(255,190,110,${.32 * lit})`); g.addColorStop(1, 'rgba(255,170,90,0)');
    ctx.fillStyle = g; ctx.fillRect(x - r, y - r, r * 2, r * 2);
  }
  ctx.restore();
}
