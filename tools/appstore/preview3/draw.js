/* Draws the App Preview v3 timeline (timeline.js) from real app footage: each shot is a captured clip filling the
   screen with a slow push or pull and a kick on the beat; captions punch in on the beats; the end card sits on the
   app's own Balloon Show, dimmed. Uses lib.js's type and finishing (tools/marketing/reels/lib.js). */
let PV_LANG = 'en', PV_DEV = 'iphone';
async function drawPV(f) {
  const T = PV_TEXT[PV_LANG], U = PV_DEV === 'ipad' ? 1.25 : 1, maxW = W * .84;
  const s = PV_SHOTS.find(x => f >= B(x[0]) && f < B(x[1])) || PV_SHOTS[PV_SHOTS.length - 1];
  const [a, b, id, start, speed, z0, z1, fx, fy, cap] = s, f0 = B(a), k = (f - f0) / (B(b) - f0);
  const img = await clip(id, (f - f0) / FPS, speed, start * FPS);
  const end = cap === 'end';
  if (end) ctx.filter = `blur(${Math.round(6 * U)}px) brightness(.62) saturate(1.15)`;
  cover(img, lerp(z0, z1, eIO(clamp(k, 0, 1))) + beatPulse(f, 0) * .018, fx, fy);
  ctx.filter = 'none';
  /* a soft shade at the top for the captions, a little at the bottom */
  shade(.36, .14, end ? .2 : .6);
  const top = H * .095;
  if (cap && T[cap] && !end) {
    if (cap === 'fleet' || cap === 'dawn' || cap === 'regions' || cap === 'night' || cap === 'empire' || cap === 'safari' || cap === 'cash' || cap === 'fill' || cap === 'one' || cap === 'wind')
      kinetic(f, T[cap], W / 2, top, { f0, stagger: 5, size: 170 * U, maxW, from: a === 0 ? 'slam' : 'punch' });
  }
  if (cap && cap.startsWith('city')) kinetic(f, [T.cities[+cap.slice(4)]], W / 2, H * .62, { f0, size: 140 * U, maxW, from: 'slam' });
  if (cap === 'fleet' && f >= B(16)) kinetic(f, ['*' + T.n164 + '*'], W / 2, H * .66, { f0: B(16), size: 120 * U, maxW, from: 'slam' });
  if (end) endCardPV(f, f0, T, U);
  /* a flash on the cuts that carry a caption */
  for (const x of PV_SHOTS) if (x[0] > 0 && x[9] && !String(x[9]).startsWith('city')) flash(f, B(x[0]), .45, 5);
}
function endCardPV(f, f0, T, U) {
  const cx = W / 2, cy = H * .42;
  const k = eBack(prog(f, f0, f0 + 9), 1.8);
  if (k > 0 && ICON) {
    const is = 230 * U; ctx.save(); ctx.translate(cx, cy - 250 * U); ctx.scale(k, k);
    ctx.shadowColor = 'rgba(10,2,24,.6)'; ctx.shadowBlur = 50; ctx.shadowOffsetY = 18; ctx.fillStyle = '#000'; rrect(-is / 2, -is / 2, is, is, is * .225); ctx.fill(); ctx.shadowColor = 'transparent';
    ctx.save(); rrect(-is / 2, -is / 2, is, is, is * .225); ctx.clip(); ctx.drawImage(ICON, -is / 2, -is / 2, is, is); ctx.restore(); ctx.restore();
  }
  kinetic(f, [T.title], cx, cy - 60 * U, { f0: f0 + 5, size: 150 * U, maxW: W * .86 });
  if (f >= f0 + 10) label(T.sub, cx, cy + 120 * U, 52 * U, '#ffd28a', { track: .45, alpha: prog(f, f0 + 10, f0 + 18) });
  const pf = f0 + B(2);
  if (f >= pf) {
    const kk = eBack(prog(f, pf, pf + 8), 1.8) * (1 + beatPulse(f, pf + B(1)) * .04), s = 56 * U;
    ctx.save(); ctx.font = `800 ${s}px BC`; ctx.letterSpacing = `${s * .12}px`; const w = ctx.measureText(T.pill).width + s * 1.6, h = s * 1.7, y = cy + 190 * U;
    ctx.translate(cx, y + h / 2); ctx.scale(kk, kk); ctx.translate(-cx, -(y + h / 2));
    ctx.fillStyle = 'rgba(16,8,34,.55)'; rrect(cx - w / 2, y, w, h, h / 2); ctx.fill();
    ctx.strokeStyle = '#ffd28a'; ctx.lineWidth = 4 * U; rrect(cx - w / 2, y, w, h, h / 2); ctx.stroke();
    ctx.fillStyle = '#ffe6b8'; ctx.textAlign = 'center'; ctx.fillText(T.pill, cx + s * .06, y + h * .7); ctx.restore();
  }
  if (f >= pf + 6) label(T.line, cx, cy + 340 * U, 44 * U, '#fff3e6', { font: 'B', w: 700, track: 0, alpha: prog(f, pf + 6, pf + 14) });
}
