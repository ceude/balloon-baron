/* Drawing for the v2 App Store set: hot-air balloons with real volume and burner light, the device frames, the
   type, and the four cities' landscapes. Everything draws on the global `ctx`. Uses art.js's small helpers
   (mulberry32, clamp, lerp, mix, rgba, rrect, chimney, mesa). */

/* ---------- colour ---------- */
function lerpCol(a, b, k) { return mix(a, b, k); }
/* a palette of keyed stops, sampled at u */
function sampleStops(stops, u) {
  if (u <= stops[0][0]) return stops[0][1];
  for (let i = 0; i < stops.length - 1; i++) {
    const [ua, ca] = stops[i], [ub, cb] = stops[i + 1];
    if (u <= ub) { const k = (u - ua) / (ub - ua), s = k * k * (3 - 2 * k); return ca.map((c, j) => mix(c, cb[j], s)); }
  }
  return stops[stops.length - 1][1];
}

/* ---------- balloon ---------- */
/* The envelope's half-width at height yy; (0,0) is the widest point, R its radius. */
function envHalf(R, yy) {
  const topY = -R * 1.06, mouth = R * 1.45, mouthW = R * .25;
  if (yy <= 0) { const t = (yy - topY) / -topY; return R * Math.sin(Math.PI / 2 * Math.pow(clamp(t, 0, 1), .6)); }
  const t = clamp(yy / mouth, 0, 1); return lerp(R, mouthW, Math.pow(t, 1.3)) * (1 - .07 * Math.sin(Math.PI * t));
}
/* A balloon lit by the sky (`light` −1 = from the left) and, when `burn`, by its own flame.
   o: cols (gore colours, repeated), pattern ('band' | 'chevron' | 'stars' | 'rings' | 'diamond'), pc (pattern colours),
   people, burn (0..1 flame size), glow (0..1 night glow: the envelope lit from inside), sky (bounce colour), haze. */
function balloon2(x, y, R, o) {
  const cols = o.cols, nG = o.gores || 16, light = o.light ?? -1, topY = -R * 1.06, mouth = R * 1.45, steps = 64;
  const sky = o.sky || '#ffb98a', haze = o.haze || 0, glow = o.glow || 0;
  ctx.save(); ctx.translate(x, y); ctx.rotate(o.tilt || 0);
  const env = new Path2D();
  for (let i = 0; i <= steps; i++) { const yy = lerp(topY, mouth, i / steps); i ? env.lineTo(envHalf(R, yy), yy) : env.moveTo(envHalf(R, yy), yy); }
  for (let i = steps; i >= 0; i--) { const yy = lerp(topY, mouth, i / steps); env.lineTo(-envHalf(R, yy), yy); }
  env.closePath();
  /* the gore between meridians a0 and a1 (angles across the visible half, −π/2 … π/2) */
  const gore = (a0, a1, pad = 0) => {
    const p = new Path2D();
    for (let i = 0; i <= steps; i++) { const yy = lerp(topY - pad, mouth + pad, i / steps), hw = envHalf(R, yy); i ? p.lineTo(hw * Math.sin(a0), yy) : p.moveTo(hw * Math.sin(a0), yy); }
    for (let i = steps; i >= 0; i--) { const yy = lerp(topY - pad, mouth + pad, i / steps); p.lineTo(envHalf(R, yy) * Math.sin(a1), yy); }
    p.closePath(); return p;
  };
  ctx.save(); ctx.clip(env);
  for (let k = 0; k < nG; k++) {
    const a0 = -Math.PI / 2 + Math.PI * k / nG, a1 = -Math.PI / 2 + Math.PI * (k + 1) / nG;
    ctx.fillStyle = cols[k % cols.length]; ctx.fill(gore(a0, a1, 4));
  }
  if (o.pattern) pattern2(o.pattern, R, topY, mouth, o.pc || ['#ffffff', '#ffc23d'], nG, gore);
  /* each gore bulges a little between its load tapes: a soft light down its middle */
  ctx.save(); ctx.filter = `blur(${Math.max(1, R * .025)}px)`;
  for (let k = 0; k < nG; k++) {
    const a0 = -Math.PI / 2 + Math.PI * (k + .3) / nG, a1 = -Math.PI / 2 + Math.PI * (k + .7) / nG, am = (a0 + a1) / 2;
    const facing = Math.cos(am - light * .7);
    ctx.fillStyle = `rgba(255,250,240,${.05 + .07 * Math.max(0, facing)})`; ctx.fill(gore(a0, a1));
  }
  ctx.restore();
  /* key light from the sky side, a terminator, and the shadow side picking up the sky */
  const kx = light * R * .5, ky = -R * .5;
  const kl = ctx.createRadialGradient(kx, ky, R * .02, kx * .6, ky * .6, R * 1.5);
  kl.addColorStop(0, 'rgba(255,248,232,.55)'); kl.addColorStop(.25, 'rgba(255,240,215,.2)'); kl.addColorStop(.6, 'rgba(255,240,215,0)');
  ctx.fillStyle = kl; ctx.fillRect(-R * 1.2, topY, R * 2.4, mouth - topY);
  const sh = ctx.createLinearGradient(light * R, 0, -light * R, 0);
  sh.addColorStop(0, 'rgba(18,8,34,0)'); sh.addColorStop(.45, 'rgba(18,8,34,.06)'); sh.addColorStop(.78, 'rgba(18,8,34,.42)'); sh.addColorStop(1, 'rgba(18,8,34,.62)');
  ctx.fillStyle = sh; ctx.fillRect(-R * 1.2, topY, R * 2.4, mouth - topY);
  const bot = ctx.createLinearGradient(0, R * .1, 0, mouth); bot.addColorStop(0, 'rgba(18,8,34,0)'); bot.addColorStop(1, 'rgba(18,8,34,.5)');
  ctx.fillStyle = bot; ctx.fillRect(-R * 1.2, R * .1, R * 2.4, mouth);
  /* bounce: the sky's colour on the shadow rim */
  const bx = -light * R;
  const bn = ctx.createRadialGradient(bx * 1.05, R * .15, R * .1, bx * 1.05, R * .15, R * .9);
  bn.addColorStop(0, rgba(sky, .38)); bn.addColorStop(1, rgba(sky, 0));
  ctx.fillStyle = bn; ctx.fillRect(-R * 1.2, topY, R * 2.4, mouth - topY);
  /* the burner's light inside the throat, and at night the whole envelope glowing */
  if (o.burn || glow) {
    ctx.globalCompositeOperation = 'lighter';
    const fr = R * (1.1 + glow * 1.2);
    const fg = ctx.createRadialGradient(0, mouth * 1.05, 0, 0, mouth * .7, fr);
    const a = .35 * (o.burn || 0) + .6 * glow;
    fg.addColorStop(0, `rgba(255,190,90,${a})`); fg.addColorStop(.45, `rgba(255,130,50,${a * .35})`); fg.addColorStop(1, 'rgba(255,110,40,0)');
    ctx.fillStyle = fg; ctx.fillRect(-R * 1.3, topY, R * 2.6, mouth - topY + R * .2);
    ctx.globalCompositeOperation = 'source-over';
  }
  /* load tapes */
  ctx.strokeStyle = 'rgba(30,10,24,.24)'; ctx.lineWidth = Math.max(1, R * .007);
  for (let k = 1; k < nG; k++) { const a = -Math.PI / 2 + Math.PI * k / nG; ctx.beginPath(); for (let i = 0; i <= steps; i++) { const yy = lerp(topY, mouth, i / steps), xx = envHalf(R, yy) * Math.sin(a); i ? ctx.lineTo(xx, yy) : ctx.moveTo(xx, yy); } ctx.stroke(); }
  /* horizontal tapes */
  ctx.strokeStyle = 'rgba(30,10,24,.12)';
  for (const t of [-.62, -.25, .3, .82, 1.18]) { const yy = t * R, hw = envHalf(R, yy); ctx.beginPath(); ctx.ellipse(0, yy, hw, hw * .06, 0, 0, Math.PI); ctx.stroke(); }
  /* specular sheen */
  ctx.save(); ctx.filter = `blur(${R * .06}px)`; ctx.fillStyle = 'rgba(255,255,255,.22)';
  ctx.beginPath(); ctx.ellipse(light * R * .42, -R * .52, R * .16, R * .32, light * -.5, 0, 7); ctx.fill(); ctx.restore();
  if (haze) { ctx.fillStyle = rgba(o.hazeColor || sky, haze); ctx.fillRect(-R * 1.2, topY, R * 2.4, mouth - topY + 10); }
  ctx.restore();
  /* rim light on the lit edge */
  ctx.save(); ctx.clip(env); ctx.strokeStyle = rgba(o.rim || '#ffe6c0', .55 * (1 - haze)); ctx.lineWidth = Math.max(2, R * .022); ctx.filter = `blur(${Math.max(.5, R * .006)}px)`;
  ctx.beginPath(); for (let i = 0; i <= steps; i++) { const yy = lerp(topY + R * .1, mouth * .65, i / steps), xx = envHalf(R, yy) * light; i ? ctx.lineTo(xx, yy) : ctx.moveTo(xx, yy); } ctx.stroke(); ctx.restore();
  if (o.envOnly) { ctx.restore(); return; }
  rig2(R, mouth, cols, o);
  ctx.restore();
}
/* Patterns painted inside the envelope (already clipped). `gore(a0,a1)` gives a gore path. */
function pattern2(kind, R, top, mouth, [c1, c2], nG, gore) {
  if (kind === 'band') {
    ctx.fillStyle = c1; ctx.fillRect(-R * 1.1, R * .16, R * 2.2, R * .34);
    ctx.fillStyle = c2; ctx.fillRect(-R * 1.1, R * .12, R * 2.2, R * .05); ctx.fillRect(-R * 1.1, R * .49, R * 2.2, R * .05);
  } else if (kind === 'crown') {
    for (let k = 0; k < nG; k += 2) ctx.fillStyle = c1;
    ctx.fillStyle = c1; ctx.beginPath(); ctx.ellipse(0, top + R * .1, R * .9, R * .62, 0, 0, 7); ctx.fill();
    ctx.fillStyle = c2; ctx.fillRect(-R * 1.1, top + R * .62, R * 2.2, R * .06);
  } else if (kind === 'chevron') {
    for (let r = 0; r < 3; r++) {
      ctx.fillStyle = r % 2 ? c2 : c1; const y0 = -R * .35 + r * R * .32;
      ctx.beginPath(); for (let k = 0; k <= 12; k++) ctx.lineTo(-R * 1.1 + k * R * 2.2 / 12, y0 + (k % 2 ? -R * .1 : R * .1));
      for (let k = 12; k >= 0; k--) ctx.lineTo(-R * 1.1 + k * R * 2.2 / 12, y0 + R * .16 + (k % 2 ? -R * .1 : R * .1)); ctx.fill();
    }
  } else if (kind === 'stars') {
    ctx.fillStyle = c1; ctx.fillRect(-R * 1.1, -R * .05, R * 2.2, R * .4);
    const star = (x, y, r) => { ctx.beginPath(); for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? r * .45 : r; ctx.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); } ctx.closePath(); ctx.fill(); };
    ctx.fillStyle = c2; for (const [dx, dy, s] of [[-.5, -.5, .14], [.42, -.55, .12], [0, -.82, .1], [-.2, .15, .1], [.3, .15, .1], [-.7, .15, .08], [.75, .15, .08]]) star(dx * R, dy * R, s * R);
  } else if (kind === 'diamond') {
    for (let k = 0; k < nG; k++) if (k % 2) {
      const a0 = -Math.PI / 2 + Math.PI * k / nG, a1 = -Math.PI / 2 + Math.PI * (k + 1) / nG;
      ctx.save(); ctx.clip(gore(a0, a1)); ctx.fillStyle = c1; ctx.fillRect(-R * 1.2, -R * .4, R * 2.4, R * .55); ctx.fillStyle = c2; ctx.fillRect(-R * 1.2, -R * .4, R * 2.4, R * .06); ctx.restore();
    }
  } else if (kind === 'rings') {
    for (const [yy, hh, c] of [[-R * .7, R * .12, c1], [-R * .3, R * .12, c2], [R * .1, R * .12, c1], [R * .5, R * .12, c2]]) { ctx.fillStyle = c; ctx.fillRect(-R * 1.1, yy, R * 2.2, hh); }
  } else if (kind === 'sun') {
    for (let k = 0; k < 16; k++) { ctx.fillStyle = k % 2 ? c1 : c2; ctx.beginPath(); ctx.moveTo(0, R * 1.6); const a0 = -Math.PI / 2 + (k - 8) * .14, a1 = a0 + .14; ctx.lineTo(Math.cos(a0) * R * 4, R * 1.6 + Math.sin(a0) * R * 4); ctx.lineTo(Math.cos(a1) * R * 4, R * 1.6 + Math.sin(a1) * R * 4); ctx.fill(); }
  }
}
/* skirt, cables, burner frame, flame and the wicker basket with its passengers */
function rig2(R, mouth, cols, o) {
  const mw = R * .25, skirtB = mouth + R * .16, by = mouth + R * .6, bw = R * .36, bh = R * .27;
  const sk = ctx.createLinearGradient(-mw, 0, mw, 0); sk.addColorStop(0, mix(cols[0], '#120614', .55)); sk.addColorStop(.5, mix(cols[0], '#120614', .3)); sk.addColorStop(1, mix(cols[0], '#120614', .65));
  ctx.fillStyle = sk; ctx.beginPath(); ctx.moveTo(-mw, mouth - 3); ctx.lineTo(mw, mouth - 3); ctx.lineTo(mw * .78, skirtB); ctx.lineTo(-mw * .78, skirtB); ctx.closePath(); ctx.fill();
  ctx.strokeStyle = 'rgba(40,24,20,.85)'; ctx.lineWidth = Math.max(1, R * .007);
  for (const s of [-1, -.4, .4, 1]) { ctx.beginPath(); ctx.moveTo(s * mw * .78, skirtB - 2); ctx.lineTo(s * bw * .42, by - R * .17); ctx.lineTo(s * bw * .46, by); ctx.stroke(); }
  /* burner frame */
  ctx.fillStyle = '#26262c'; ctx.fillRect(-R * .1, by - R * .2, R * .2, R * .07);
  ctx.fillStyle = '#5a5a66'; ctx.fillRect(-R * .1, by - R * .2, R * .2, R * .015);
  if (o.burn) {
    const s = R * .55 * o.burn, fy = by - R * .2;
    ctx.save(); ctx.globalCompositeOperation = 'lighter';
    const gl = ctx.createRadialGradient(0, fy - s * .5, 0, 0, fy - s * .5, s * 2.6);
    gl.addColorStop(0, 'rgba(255,200,110,.75)'); gl.addColorStop(.3, 'rgba(255,140,50,.28)'); gl.addColorStop(1, 'rgba(255,100,30,0)');
    ctx.fillStyle = gl; ctx.fillRect(-s * 2.6, fy - s * 3.1, s * 5.2, s * 5.2); ctx.restore();
    ctx.save(); ctx.beginPath(); ctx.rect(-R, skirtB - 4, R * 2, R * 2); ctx.clip(); flame2(0, fy, s); ctx.restore();
  }
  /* basket: wicker with a leather rim, lit from the flame above */
  const bg = ctx.createLinearGradient(-bw / 2, 0, bw / 2, 0); bg.addColorStop(0, '#3e2414'); bg.addColorStop(.45, '#94603a'); bg.addColorStop(1, '#2e1a0e');
  ctx.fillStyle = bg; ctx.beginPath(); ctx.moveTo(-bw / 2, by); ctx.lineTo(bw / 2, by); ctx.lineTo(bw * .44, by + bh); ctx.lineTo(-bw * .44, by + bh); ctx.closePath(); ctx.fill();
  ctx.save(); ctx.clip(); ctx.strokeStyle = 'rgba(30,14,6,.32)'; ctx.lineWidth = Math.max(1, R * .005);
  for (let i = 1; i < 7; i++) { ctx.beginPath(); ctx.moveTo(-bw / 2, by + bh * i / 7); ctx.lineTo(bw / 2, by + bh * i / 7); ctx.stroke(); }
  for (let i = 1; i < 9; i++) { const xx = -bw / 2 + bw * i / 9; ctx.beginPath(); ctx.moveTo(xx, by); ctx.lineTo(xx * .88, by + bh); ctx.stroke(); }
  const top = ctx.createLinearGradient(0, by, 0, by + bh); top.addColorStop(0, o.burn ? 'rgba(255,190,110,.35)' : 'rgba(255,230,190,.15)'); top.addColorStop(1, 'rgba(0,0,0,.3)');
  ctx.fillStyle = top; ctx.fillRect(-bw, by, bw * 2, bh); ctx.restore();
  /* passengers, then the padded rim in front of them */
  if (o.people) {
    const n = o.people;
    for (let i = 0; i < n; i++) {
      const px = -bw * .36 + i * bw * .72 / Math.max(1, n - 1), ph = R * (.05 + (i % 2) * .008);
      ctx.fillStyle = ['#2a1c22', '#3a2630', '#24181e'][i % 3];
      ctx.beginPath(); ctx.arc(px, by - ph - R * .018, R * .026, 0, 7); ctx.fill();
      rrect(px - R * .028, by - ph + R * .006, R * .056, ph + 2, R * .015); ctx.fill();
    }
  }
  const rim = ctx.createLinearGradient(0, by - R * .025, 0, by + R * .02); rim.addColorStop(0, '#6a4228'); rim.addColorStop(1, '#2a160c');
  ctx.fillStyle = rim; rrect(-bw / 2 - R * .01, by - R * .02, bw + R * .02, R * .042, R * .015); ctx.fill();
}
function flame2(x, y, s) {
  ctx.save();
  const layers = [['#ff4a12', 1, 16], ['#ff9a2a', .76, 10], ['#ffd870', .52, 6], ['#fff8e0', .28, 3]];
  for (const [c, k, blur] of layers) {
    const w = s * .3 * k, h = s * 1.3 * k;
    ctx.filter = `blur(${Math.max(1, s * blur / 110)}px)`; ctx.fillStyle = c; ctx.beginPath(); ctx.moveTo(x - w, y);
    ctx.bezierCurveTo(x - w * 1.25, y - h * .35, x - w * .5, y - h * .55, x - w * .3, y - h * .8);
    ctx.quadraticCurveTo(x - w * .1, y - h * .64, x + w * .02, y - h);
    ctx.quadraticCurveTo(x + w * .22, y - h * .7, x + w * .42, y - h * .84);
    ctx.bezierCurveTo(x + w * .58, y - h * .55, x + w * 1.25, y - h * .35, x + w, y);
    ctx.quadraticCurveTo(x, y + w * .5, x - w, y); ctx.closePath(); ctx.fill();
  }
  ctx.filter = 'none'; ctx.restore();
}
/* a far balloon: a small lit silhouette that sinks into the haze */
function farBalloon(x, y, r, col, hz, hazeCol, o = {}) {
  const c = mix(col, hazeCol, hz), d = mix(col, '#1a0c22', .35 + hz * .1);
  ctx.save(); ctx.translate(x, y);
  const g = ctx.createLinearGradient(-r, 0, r, 0); g.addColorStop(0, mix(c, '#fff3dc', .25 * (1 - hz))); g.addColorStop(.6, c); g.addColorStop(1, mix(d, hazeCol, hz));
  ctx.fillStyle = g; ctx.beginPath();
  for (let i = 0; i <= 24; i++) { const yy = lerp(-r * 1.06, r * 1.45, i / 24); ctx.lineTo(envHalf(r, yy), yy); }
  for (let i = 24; i >= 0; i--) { const yy = lerp(-r * 1.06, r * 1.45, i / 24); ctx.lineTo(-envHalf(r, yy), yy); }
  ctx.fill();
  if (o.stripe) { ctx.save(); ctx.clip(); ctx.fillStyle = mix(o.stripe, hazeCol, hz); for (let k = -2; k <= 2; k += 2) { ctx.beginPath(); ctx.ellipse(k * r * .33, 0, r * .12, r * 1.4, 0, 0, 7); ctx.fill(); } ctx.restore(); }
  if (o.glow) { ctx.globalCompositeOperation = 'lighter'; const gg = ctx.createRadialGradient(0, r * 1.2, 0, 0, r * .4, r * 1.6); gg.addColorStop(0, `rgba(255,190,90,${.7 * o.glow})`); gg.addColorStop(1, 'rgba(255,140,60,0)'); ctx.fillStyle = gg; ctx.fillRect(-r * 1.6, -r * 1.4, r * 3.2, r * 3.2); ctx.globalCompositeOperation = 'source-over'; }
  ctx.fillStyle = mix('#2a1810', hazeCol, hz); ctx.fillRect(-r * .13, r * 1.72, r * .26, r * .2);
  ctx.strokeStyle = mix('#2a1810', hazeCol, hz); ctx.lineWidth = Math.max(.6, r * .03); ctx.beginPath(); ctx.moveTo(-r * .22, r * 1.4); ctx.lineTo(-r * .12, r * 1.72); ctx.moveTo(r * .22, r * 1.4); ctx.lineTo(r * .12, r * 1.72); ctx.stroke();
  ctx.restore();
}

/* ---------- devices ---------- */
/* A phone (iPhone-like, titanium rim, slim black border) or a tablet around a game screen.
   (x, y, w, h) is the visible screen; the frame grows outward. */
function device(kind, x, y, w, h, img, o = {}) {
  const ipad = kind === 'ipad';
  const bez = ipad ? w * .032 : w * .028, rim = ipad ? w * .0075 : w * .011;
  const rad = ipad ? w * .045 : w * .118, R0 = rad + bez, R1 = R0 + rim;
  ctx.save();
  if (o.rot) { ctx.translate(x + w / 2, y + h / 2); ctx.rotate(o.rot); ctx.translate(-(x + w / 2), -(y + h / 2)); }
  /* the shadow: one wide and soft, one close */
  ctx.save(); ctx.shadowColor = o.shadow || 'rgba(8,2,20,.55)'; ctx.shadowBlur = w * .12; ctx.shadowOffsetY = w * .05;
  ctx.fillStyle = '#0c0a14'; rrect(x - bez - rim, y - bez - rim, w + 2 * (bez + rim), h + 2 * (bez + rim), R1); ctx.fill(); ctx.restore();
  ctx.save(); ctx.shadowColor = 'rgba(8,2,20,.45)'; ctx.shadowBlur = w * .025; ctx.shadowOffsetY = w * .01;
  ctx.fillStyle = '#0c0a14'; rrect(x - bez - rim, y - bez - rim, w + 2 * (bez + rim), h + 2 * (bez + rim), R1); ctx.fill(); ctx.restore();
  /* side buttons */
  ctx.fillStyle = '#6d6a74';
  if (!ipad) { const bx = x - bez - rim; rrect(bx - w * .007, y + h * .17, w * .01, h * .045, 3); ctx.fill(); rrect(bx - w * .007, y + h * .245, w * .01, h * .075, 3); ctx.fill(); rrect(bx - w * .007, y + h * .335, w * .01, h * .075, 3); ctx.fill(); rrect(x + w + bez + rim - w * .003, y + h * .27, w * .01, h * .11, 3); ctx.fill(); }
  else { rrect(x + w * .78, y - bez - rim - w * .006, w * .07, w * .008, 3); ctx.fill(); }
  /* titanium rim */
  const tg = ctx.createLinearGradient(x - bez, y - bez, x + w + bez, y + h + bez);
  tg.addColorStop(0, '#d9d5de'); tg.addColorStop(.18, '#7d7986'); tg.addColorStop(.5, '#a9a5b0'); tg.addColorStop(.82, '#5f5b66'); tg.addColorStop(1, '#c9c5ce');
  ctx.fillStyle = tg; rrect(x - bez - rim, y - bez - rim, w + 2 * (bez + rim), h + 2 * (bez + rim), R1); ctx.fill();
  ctx.fillStyle = '#050407'; rrect(x - bez, y - bez, w + 2 * bez, h + 2 * bez, R0); ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,.08)'; ctx.lineWidth = 2; rrect(x - bez + 2, y - bez + 2, w + 2 * bez - 4, h + 2 * bez - 4, R0 - 2); ctx.stroke();
  /* the screen */
  ctx.save(); rrect(x, y, w, h, rad); ctx.clip();
  if (img) {
    const sh = img.height - (o.cutTop || 0) - (o.cutBottom || 0), sw = img.width;
    ctx.drawImage(img, 0, o.cutTop || 0, sw, sh, x, y, w, h);
  }
  /* a faint glass sheen */
  const gl = ctx.createLinearGradient(x, y, x + w * .9, y + h * .5);
  gl.addColorStop(0, 'rgba(255,255,255,.07)'); gl.addColorStop(.35, 'rgba(255,255,255,.02)'); gl.addColorStop(.351, 'rgba(255,255,255,0)'); gl.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = gl; ctx.fillRect(x, y, w, h);
  ctx.restore();
  ctx.restore();
}
/* A piece of the real game screen lifted out and enlarged, as a floating card.
   src: [sx, sy, sw, sh] in the raw image; (x, y) top left on the canvas; s the scale. */
function popout(img, src, x, y, s, o = {}) {
  const [sx, sy, sw, sh] = src, w = sw * s, h = sh * s, r = (o.r || 28) * s;
  ctx.save();
  if (o.rot) { ctx.translate(x + w / 2, y + h / 2); ctx.rotate(o.rot); ctx.translate(-(x + w / 2), -(y + h / 2)); }
  ctx.shadowColor = 'rgba(10,2,24,.55)'; ctx.shadowBlur = 70; ctx.shadowOffsetY = 26;
  ctx.fillStyle = o.bg || '#fff'; rrect(x, y, w, h, r); ctx.fill(); ctx.restore();
  ctx.save();
  if (o.rot) { ctx.translate(x + w / 2, y + h / 2); ctx.rotate(o.rot); ctx.translate(-(x + w / 2), -(y + h / 2)); }
  rrect(x, y, w, h, r); ctx.clip(); ctx.drawImage(img, sx, sy, sw, sh, x, y, w, h);
  ctx.restore();
  ctx.save();
  if (o.rot) { ctx.translate(x + w / 2, y + h / 2); ctx.rotate(o.rot); ctx.translate(-(x + w / 2), -(y + h / 2)); }
  ctx.strokeStyle = o.ring || 'rgba(255,255,255,.85)'; ctx.lineWidth = o.ringW || 5; rrect(x, y, w, h, r); ctx.stroke();
  ctx.restore();
}

/* ---------- type ---------- */
function upper(s, locale) { return s.toLocaleUpperCase(locale); }
/* Kicker, headline and supporting line, centred on cx. Returns the bottom y. */
function caption2(cx, y, cap, o) {
  const loc = o.locale, maxW = o.maxW;
  ctx.save(); ctx.textAlign = 'center'; ctx.textBaseline = 'alphabetic';
  if (cap.kicker) {
    const ks = o.kicker || 40;
    ctx.font = `700 ${ks}px BC`; ctx.letterSpacing = `${ks * .32}px`;
    const t = upper(cap.kicker, loc), tw = ctx.measureText(t).width - ks * .32;
    ctx.fillStyle = o.accent || '#ffcf7a'; ctx.shadowColor = 'rgba(10,2,20,.5)'; ctx.shadowBlur = 16;
    ctx.fillText(t, cx + ks * .16, y);
    ctx.shadowBlur = 0; ctx.letterSpacing = '0px';
    /* thin rules either side */
    const gx = tw / 2 + ks * .8, L = ks * 1.6;
    for (const s of [-1, 1]) { const g = ctx.createLinearGradient(cx + s * gx, 0, cx + s * (gx + L), 0); g.addColorStop(0, rgba(o.accent || '#ffcf7a', .9)); g.addColorStop(1, rgba(o.accent || '#ffcf7a', 0)); ctx.fillStyle = g; ctx.fillRect(Math.min(cx + s * gx, cx + s * (gx + L)), y - ks * .36, L, Math.max(2, ks * .06)); }
    y += ks * .5;
  }
  const lines = cap.head.split('|').map(l => upper(l, loc));
  let size = o.size || 176; ctx.font = `800 ${size}px BC`; ctx.letterSpacing = `${-size * .005}px`;
  const widest = Math.max(...lines.map(l => ctx.measureText(l).width));
  if (widest > maxW) { size = Math.floor(size * maxW / widest); ctx.font = `800 ${size}px BC`; ctx.letterSpacing = `${-size * .005}px`; }
  const lh = size * .9;
  /* a warm light behind the words */
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  const bh = lh * lines.length, gy = y + bh * .55, gr = Math.max(widest, maxW * .7) * .62;
  const g0 = ctx.createRadialGradient(cx, gy, 0, cx, gy, gr); g0.addColorStop(0, rgba(o.glow || '#ff9a5a', .16)); g0.addColorStop(1, rgba(o.glow || '#ff9a5a', 0));
  ctx.fillStyle = g0; ctx.save(); ctx.translate(cx, gy); ctx.scale(1, .45); ctx.translate(-cx, -gy); ctx.fillRect(cx - gr, gy - gr, gr * 2, gr * 2); ctx.restore(); ctx.restore();
  for (const line of lines) {
    y += lh;
    const g = ctx.createLinearGradient(0, y - size * .75, 0, y + size * .05);
    g.addColorStop(0, '#ffffff'); g.addColorStop(.5, o.mid || '#fff3dc'); g.addColorStop(1, o.gold || '#ffc95a');
    ctx.shadowColor = 'rgba(12,2,24,.55)'; ctx.shadowBlur = size * .22; ctx.shadowOffsetY = size * .04;
    ctx.fillStyle = g; ctx.fillText(line, cx, y);
  }
  ctx.shadowColor = 'transparent';
  if (cap.sub) {
    const ss = o.sub || 46; y += ss * 1.55;
    ctx.font = `600 ${ss}px B`; ctx.letterSpacing = '0px';
    let t = cap.sub; const lw = ctx.measureText(t).width;
    if (lw > maxW) { ctx.font = `600 ${Math.floor(ss * maxW / lw)}px B`; }
    ctx.fillStyle = o.subColor || 'rgba(255,240,226,.94)'; ctx.shadowColor = 'rgba(10,2,20,.6)'; ctx.shadowBlur = 18;
    ctx.fillText(t, cx, y);
  }
  ctx.restore();
  return y;
}

/* A round magnifier over the game: the circle of radius src[2] around (src[0], src[1]) in the raw image, drawn at
   scale s centred on (x, y). */
function lens(img, src, x, y, s) {
  const [sx, sy, sr] = src, r = sr * s;
  ctx.save(); ctx.shadowColor = 'rgba(10,2,24,.55)'; ctx.shadowBlur = 80; ctx.shadowOffsetY = 30;
  ctx.fillStyle = '#1a1430'; ctx.beginPath(); ctx.arc(x, y, r, 0, 7); ctx.fill(); ctx.restore();
  ctx.save(); ctx.beginPath(); ctx.arc(x, y, r, 0, 7); ctx.clip();
  ctx.drawImage(img, sx - sr, sy - sr, sr * 2, sr * 2, x - r, y - r, r * 2, r * 2);
  const g = ctx.createRadialGradient(x - r * .4, y - r * .5, 0, x, y, r); g.addColorStop(0, 'rgba(255,255,255,.12)'); g.addColorStop(.5, 'rgba(255,255,255,0)'); g.addColorStop(1, 'rgba(10,2,24,.25)');
  ctx.fillStyle = g; ctx.fillRect(x - r, y - r, r * 2, r * 2); ctx.restore();
  const rg = ctx.createLinearGradient(x - r, y - r, x + r, y + r); rg.addColorStop(0, '#fff6e0'); rg.addColorStop(.5, '#ffc95a'); rg.addColorStop(1, '#fff0d0');
  ctx.strokeStyle = rg; ctx.lineWidth = Math.max(6, r * .035); ctx.beginPath(); ctx.arc(x, y, r, 0, 7); ctx.stroke();
}
