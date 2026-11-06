/* The three reels. Each is { frames, draw: async f => … } on a 120 BPM grid (a beat is 15 frames, a bar 60), so
   every cut and every word lands on a beat for the music added in Instagram. */
const REELS = {};

/* backdrop behind phones and the rival: the dawn world, drifting */
function backdrop(f, o = {}) {
  const t = f / FPS;
  dawn({ t: 10 + t, cam: { x: (o.x || 0) + t * 10, y: o.y ?? 650, z: o.z || 1.05 }, burn: 1 });
  if (o.dim) { ctx.fillStyle = `rgba(14,6,34,${o.dim})`; ctx.fillRect(0, 0, W, H); }
}
/* footage filling the screen with a slow push and a kick on every beat */
async function footage(id, f, f0, o = {}) {
  const img = await clip(id, (f - f0) / FPS, o.speed || 1, o.start || 0);
  if (o.filter) ctx.filter = o.filter;
  const k = (f - f0) / Math.max(1, (o.len || 30)), z = (o.z0 || 1.12) + ((o.z1 || 1.22) - (o.z0 || 1.12)) * eIO(clamp(k, 0, 1)) + beatPulse(f, f0) * (o.kick ?? .025);
  cover(img, z, o.fx ?? .5, o.fy ?? .5, o.dx || 0, o.dy || 0);
  ctx.filter = 'none';
}
function tag(text, x, y, f, f0, o = {}) {
  if (f < f0) return;
  const k = eBack(prog(f, f0, f0 + 7), 1.8), s = o.size || 46;
  ctx.save(); ctx.font = `800 ${s}px BC`; ctx.letterSpacing = `${s * .1}px`;
  const w = ctx.measureText(text).width + s * 1.1, h = s * 1.5;
  ctx.translate(x, y); ctx.scale(k, k); ctx.rotate(o.rot || 0);
  ctx.shadowColor = 'rgba(8,2,20,.5)'; ctx.shadowBlur = 24; ctx.shadowOffsetY = 8;
  const bg = ctx.createLinearGradient(0, -h / 2, 0, h / 2); bg.addColorStop(0, o.c0 || 'rgba(44,22,80,.94)'); bg.addColorStop(1, o.c1 || 'rgba(20,10,44,.94)');
  ctx.fillStyle = bg; rrect(-w / 2, -h / 2, w, h, h * .3); ctx.fill(); ctx.shadowColor = 'transparent';
  ctx.strokeStyle = o.ring || 'rgba(255,214,140,.85)'; ctx.lineWidth = 3; rrect(-w / 2, -h / 2, w, h, h * .3); ctx.stroke();
  ctx.fillStyle = o.color || '#ffe2a0'; ctx.textAlign = 'center'; ctx.fillText(text, s * .05, s * .36);
  ctx.restore();
}
/* a vector tick (no emoji) */
function tick(x, y, s, col = '#3ad08a') {
  ctx.save(); ctx.fillStyle = col; ctx.beginPath(); ctx.arc(x, y, s, 0, 7); ctx.fill();
  ctx.strokeStyle = '#fff'; ctx.lineWidth = s * .28; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
  ctx.beginPath(); ctx.moveTo(x - s * .45, y + s * .02); ctx.lineTo(x - s * .1, y + s * .38); ctx.lineTo(x + s * .5, y - s * .35); ctx.stroke(); ctx.restore();
}

/* ======================= 1. "He thinks you can't fly" ======================= */
REELS[1] = {
  frames: B(36),
  async draw(f) {
    const t = f / FPS;
    const hits = [0, B(1), B(6), B(8), B(9), B(21), B(26)];
    const [sx, sy] = shakeAt(f, hits, 18);
    ctx.save(); ctx.translate(sx, sy);
    if (f < B(2)) {
      /* HOOK: the rival slams in */
      backdrop(f, { dim: .25, z: 1.12 - t * .05 });
      const k = eOut(prog(f, 0, 6)), r = 330 * lerp(1.9, 1, k);
      rivalBadge(540, 1080, r, { look: .5, t });
      tag('VICTOR SMUGG  ·  SMUGG AIR', 540, 1470, f, 8, { size: 40 });
      kinetic(f, ['HE THINKS', 'YOU *CAN\'T* FLY.'], 540, 230, { f0: 0, stagger: B(1), size: 168 });
    } else if (f < B(6)) {
      /* the first morning: one balloon, and the taunt */
      backdrop(f, { dim: .2 });
      const img = await clip('early', (f - B(2)) / FPS);
      const k = eOut(prog(f, B(2), B(2) + 10));
      phoneShot(img, 540, 1190 + (1 - k) * 700, 600, -.04 * k);
      bubble(f, B(2) + 3, 'Cute basket. Call me when you have 10.', 70, 270, 870, { size: 54, cps: 2.4 });
      tag('DAY 2  ·  1 BALLOON', 300, 1470, f, B(4), { rot: -.06, size: 50 });
    } else if (f < B(8)) {
      /* he laughs */
      backdrop(f, { dim: .35, z: 1.2 });
      rivalBadge(540, 1060, 360 + beatPulse(f, B(6)) * 20, { laugh: 1, t });
      const ha = [[B(6), 290, 470, -.12], [B(6.5), 760, 620, .1], [B(7), 300, 1500, -.05], [B(7.5), 770, 1420, .12]];
      for (const [a, x, y, r] of ha) if (f >= a) kinetic(f, ['HA'], x, y - 150, { f0: a, size: 170, tilt: r, from: 'slam' });
    } else if (f < B(10)) {
      /* CHALLENGE ACCEPTED */
      await footage('flight', f, B(8), { start: 60, z0: 1.9, z1: 1.7, fx: .42, fy: .74, len: 30 });
      ctx.fillStyle = 'rgba(14,4,28,.45)'; ctx.fillRect(0, 0, W, H);
      kinetic(f, ['CHALLENGE', '*ACCEPTED.*'], 540, 640, { f0: B(8), stagger: B(1), size: 190, from: 'slam' });
    } else if (f < B(14)) {
      /* fly it, land it, get paid */
      const words = ['FLY IT.', 'LAND IT.', 'GET *PAID.*', 'REPEAT.'], i = Math.floor((f - B(10)) / BEAT);
      if (i < 2) await footage('flight', f, B(10), { start: 90, speed: 1.6, z0: 1.7, z1: 1.5, fx: .42, fy: .66, len: 30 });
      else await footage('collect', f, B(12), { start: 10, speed: 1.2, z0: 1.06, z1: 1.0, fx: .5, fy: .7, len: 30 });
      shade(.32, .2, .6);
      kinetic(f, [words[i]], 540, 300, { f0: B(10 + i), size: 190, maxW: 740 }); /* inside the right 150 px margin */
    } else if (f < B(24)) {
      /* the growth: a new picture on every beat, the fleet counter racing */
      const seq = [['early', 1.95], ['town10', 1.75], ['town10', 1.6], ['town40', 1.55], ['town40', 1.45], ['town90', 1.3], ['town90', 1.2], ['empire', 1.12], ['empire', 1.04], ['empire', 1.0]]; /* wider as the fleet grows */
      const i = Math.floor((f - B(14)) / BEAT), [id, z] = seq[i], f0 = B(14 + i);
      await footage(id, f, f0, { z0: z + .06, z1: z, fx: .5, fy: .47, len: 15, kick: .04, start: i % 2 ? 20 : 0 });
      shade(.42, .25, .65);
      const vals = [1, 10, 10, 40, 40, 90, 90, 164, 164, 164], prev = i ? vals[i - 1] : 1;
      const v = Math.round(lerp(prev, vals[i], eOut(prog(f, f0, f0 + 8))));
      const pk = 1 + beatPulse(f, B(14)) * .08;
      bigNumber(fmt(v), 540, 560, 300, v === 1 ? 'BALLOON' : 'BALLOONS', { s: pk });
      const kick = ['ONE BASKET', 'TEN. CALL HIM?', 'NOT YET.', 'MORE PILOTS', 'MORE HANGARS', 'MORE SKY', 'KEEP GOING', 'FULL FLEET', 'FULL FLEET', 'FULL FLEET'][i];
      if (i < 7) tag(kick, 540, 760, f, f0, { size: 48 });
      if (i >= 7) kinetic(f, ['THE WHOLE', '*VALLEY.*'], 540, 1080, { f0: B(21), stagger: 5, size: 170 });
      flash(f, B(21), .7, 6);
    } else if (f < B(26)) {
      /* the money */
      await footage('auto', f, B(24), { start: 20, speed: 1.5, z0: 1.5, z1: 1.62, fx: .5, fy: .5, len: 30 });
      shade(.45, .2, .7);
      const v = lerp(0, 3034000, eOut(prog(f, B(24), B(25.5))));
      bigNumber('€' + fmt(v), 540, 560, 190, 'IN THE BANK', { card: 1 });
      kinetic(f, ['ON *AUTOPILOT.*'], 540, 700, { f0: B(25), size: 130 });
    } else if (f < B(30)) {
      /* his face drops */
      backdrop(f, { dim: .3, z: 1.15 });
      const k = prog(f, B(26), B(26) + 4);
      rivalBadge(540, 960, 300 + k * 20, { shock: eOut(k), sweat: prog(f, B(27), B(28)), t, look: 0 });
      bubble(f, B(26) + 2, '...wait. 164?!', 70, 270, 870, { size: 60, cps: 1.2, e: { shock: 1, t } });
      kinetic(f, ['WHO\'S *CUTE* NOW?'], 540, 1300, { f0: B(28), size: 140, from: 'slam' });
    } else {
      endCard(f, B(30), ['PROVE HIM', '*WRONG.*'], { size: 170 });
    }
    flash(f, B(30), .6, 8);
    ctx.restore();
  },
};

/* ======================= 2. Timelapse: one balloon to a world company ======================= */
const SPLITS = [['CAPPADOCIA', B(9)], ['ALBUQUERQUE', B(14)], ['LUXOR', B(18)], ['BRISTOL', B(22)]];
function timer(f, a, b) {
  if (f < a) return;
  const sec = (Math.min(f, b) - a) / FPS, mm = Math.floor(sec / 60), ss = Math.floor(sec % 60), cs = Math.floor(sec * 100 % 100);
  const txt = `${String(mm).padStart(2, '0')}:${String(ss).padStart(2, '0')}.${String(cs).padStart(2, '0')}`;
  const done = f >= b, x = 70, y = 270;
  ctx.save();
  ctx.fillStyle = 'rgba(16,8,34,.78)'; rrect(x, y, 470, 150, 28); ctx.fill(); ctx.strokeStyle = done ? '#ffc95a' : 'rgba(255,214,140,.6)'; ctx.lineWidth = 3; rrect(x, y, 470, 150, 28); ctx.stroke();
  ctx.fillStyle = done ? '#3ad08a' : '#ff5e3a'; ctx.beginPath(); ctx.arc(x + 38, y + 44, 10 + (done ? 0 : Math.sin(f * .4) * 2), 0, 7); ctx.fill();
  label('GAMEPLAY TIMELAPSE', x + 60, y + 54, 28, '#ffe6b8', { align: 'left', track: .14 });
  ctx.font = '800 92px BC'; ctx.letterSpacing = '0px'; ctx.textAlign = 'left';
  /* digits on a fixed pitch so they don't jitter */
  ctx.textAlign = 'center'; let xx = x + 34; for (const ch of txt) { ctx.fillStyle = done ? '#ffd56a' : '#fff6ea'; const cw = /\d/.test(ch) ? 48 : 22; ctx.fillText(ch, xx + cw / 2, y + 132); xx += cw; }
  ctx.restore();
  /* the splits */
  SPLITS.forEach(([name, at], i) => {
    if (f < at) return;
    const k = eBack(prog(f, at, at + 7), 1.6), yy = y + 180 + i * 78;
    ctx.save(); ctx.globalAlpha = clamp((f - at) / 3, 0, 1); ctx.translate(x + (1 - k) * -200, 0);
    ctx.fillStyle = 'rgba(16,8,34,.72)'; rrect(x, yy, 470, 64, 20); ctx.fill();
    tick(x + 34, yy + 32, 20);
    label(name, x + 66, yy + 45, 38, '#fff3dc', { align: 'left', track: .06, w: 800 });
    const st = (at - a) / FPS; label(`${String(Math.floor(st)).padStart(2, '0')}.${String(Math.floor(st * 100 % 100)).padStart(2, '0')}`, x + 450, yy + 45, 34, '#ffcf7a', { align: 'right', track: 0 });
    ctx.restore();
  });
}
REELS[2] = {
  frames: B(40),
  async draw(f) {
    const t = f / FPS, T0 = B(2), TEND = B(30);
    const [sx, sy] = shakeAt(f, [0, B(1), B(9), B(30)], 16);
    ctx.save(); ctx.translate(sx, sy);
    if (f < B(10)) {
      /* Cappadocia from one balloon to the full fleet, a cut on every beat */
      const seq = [['early', 1.95], ['early', 1.75], ['town10', 1.7], ['town10', 1.6], ['town40', 1.5], ['town40', 1.42], ['town90', 1.25], ['empire', 1.12], ['empire', 1.04], ['empire', 1.0]];
      const i = Math.floor(f / BEAT), [id, z] = seq[i];
      await footage(id, f, B(i), { z0: z + .06, z1: z, fx: .5, fy: .47, len: 15, kick: .035, start: i % 2 ? 20 : 0 });
      shade(.5, .35, .7);
      if (f < B(2)) {
        kinetic(f, ['1 BALLOON TO A', 'WORLD *EMPIRE*'], 540, 560, { f0: 0, stagger: 6, size: 160 });
        kinetic(f, ['IN 20 SECONDS.'], 540, 860, { f0: B(1), size: 110, from: 'slam' });
      } else {
        const vals = [1, 1, 10, 10, 40, 40, 90, 164, 164, 164], prev = vals[Math.max(0, i - 1)];
        const v = Math.round(lerp(prev, vals[i], eOut(prog(f, B(i), B(i) + 8))));
        bigNumber(fmt(v), 540, 1250, 260, 'BALLOONS IN CAPPADOCIA', { s: 1 + beatPulse(f, B(2)) * .06 });
      }
      if (f >= B(9)) kinetic(f, ['*BARON.*'], 540, 790, { f0: B(9), size: 190, from: 'slam' });
    } else if (f < B(26)) {
      /* the world tour: map legs and the cities */
      const legs = [['cap', 'abq', B(10)], ['abq', 'lux', B(15)], ['lux', 'bri', B(19)], ['bri', 'mara', B(23)]];
      const city = [['abq', B(12), B(15), 'ALBUQUERQUE', 'USA'], ['lux', B(17), B(19), 'LUXOR', 'EGYPT'], ['bri', B(21), B(23), 'BRISTOL', 'ENGLAND']].find(c => f >= c[1] && f < c[2]);
      if (city) {
        await footage(city[0], f, city[1], { z0: 1.6, z1: 1.45, fx: .5, fy: .5, len: city[2] - city[1] });
        shade(.45, .3, .65);
        kinetic(f, [city[3]], 540, 820, { f0: city[1], size: 170, from: 'slam' });
        label(city[4], 540, 1100, 48, '#ffd28a', { track: .5, alpha: prog(f, city[1] + 4, city[1] + 10) });
        bigNumber('€' + fmt(lerp(city[0] === 'abq' ? 900000 : city[0] === 'lux' ? 2900000 : 5600000, city[0] === 'abq' ? 2100000 : city[0] === 'lux' ? 4800000 : 7200000, prog(f, city[1], city[2]))), 540, 1390, 120, 'HOLDING CASH', { card: 1 });
        flash(f, city[1], .6, 5);
      } else {
        const leg = legs.filter(l => f >= l[2]).pop(), [a, b, f0] = leg;
        const A = mapPt(CITIES[a]), Bp = mapPt(CITIES[b]), k = eIO(prog(f, f0, f0 + B(1.8)));
        const mx = lerp(A[0], Bp[0], .15 + k * .7), my = lerp(A[1], Bp[1], .2 + k * .6) - 10, zoom = 12 + (f - f0) * .04 - Math.sin(k * Math.PI) * 1.5;
        const P = worldMap(mx, my, zoom, f);
        const order = ['cap', 'abq', 'lux', 'bri', 'mara'];
        for (const c of order.slice(0, order.indexOf(a) + 1)) { const p = P(CITIES[c]); pin(p[0], p[1], CITIES[c].name, f, 0, { size: 34, side: c === 'abq' || c === 'bri' ? 'l' : 'r' }); }
        for (let i = 0; i < order.indexOf(a); i++) { const p = P(CITIES[order[i]]), q = P(CITIES[order[i + 1]]); route(p, q, 1, f); }
        const pa = P(CITIES[a]), pb = P(CITIES[b]);
        route(pa, pb, k, f);
        pin(pb[0], pb[1], CITIES[b].name, f, f0 + B(1.2), { side: b === 'abq' || b === 'bri' ? 'l' : 'r', size: 58, tag: b === 'mara' ? 'NEXT: THE TOUGHEST SKY' : null, locked: b === 'mara' });
        if (f0 === B(10)) bubble(f, B(10) + 2, 'Lucky. Try that abroad.', 70, 1330, 870, { size: 54, cps: 2 });
      }
    } else if (f < B(32)) {
      /* the holding */
      await footage('holding', f, B(26), { z0: 1.2, z1: 1.3, fx: .5, fy: .4, len: B(6) });
      shade(.5, .45, .75);
      const v = lerp(7200000, 8760000, eOut(prog(f, B(26), B(29.5))));
      bigNumber('€' + fmt(v), 540, 1280, 170, 'HOLDING CASH', { card: 1, s: 1 + (f >= TEND ? beatPulse(f, TEND) * .06 : 0) });
      if (f >= TEND) kinetic(f, ['WORLD', '*EMPIRE.*'], 540, 700, { f0: TEND, stagger: 5, size: 190, from: 'slam' });
      flash(f, TEND, .7, 7);
    } else if (f < B(34)) {
      backdrop(f, { dim: .3, z: 1.18 });
      rivalBadge(540, 1150, 340, { shock: eOut(prog(f, B(32), B(32) + 5)), sweat: prog(f, B(33), B(34)), t, look: 0 });
      bubble(f, B(32) + 1, '...okay. That was fast.', 70, 270, 870, { size: 58, cps: 2.2, e: { shock: 1, t } });
    } else {
      endCard(f, B(34), ['YOUR TURN.', '*BEAT THAT.*'], { size: 165 });
    }
    if (f >= T0 && f < B(32)) timer(f, T0, TEND);
    flash(f, B(34), .6, 8);
    ctx.restore();
  },
};

/* ======================= 3. POV: you own the sunrise ======================= */
REELS[3] = {
  frames: B(36),
  async draw(f) {
    const t = f / FPS;
    if (f < B(14)) {
      /* one long crane up through the valley as the balloons rise */
      const k = eIO(prog(f, 0, B(12)));
      const cam = { x: -60 + k * 120, y: lerp(1250, 380, k), z: lerp(1.25, 1.0, eOut(prog(f, 0, B(8)))) };
      let rv = null;
      dawn({ t: t, cam, rise: prog(f, -B(2), B(10)), extra: band => {
        if (band !== 'near') return;
        /* the hero: our balloon right in front of the camera, burner roaring on the beats */
        const hk = eOut(prog(f, 0, B(4)));
        const hx = lerp(420, 300, k), hy = lerp(980, 1500, k) + Math.sin(t * 1.3) * 10, hr = lerp(560, 300, hk);
        const burn = f < B(3) ? 1 : (beatPulse(f, 0) > .5 ? 1 : .25);
        spriteBalloon(SPRITES.hero, hx, hy, hr, burn, t);
        /* the rival's balloon drifts in from the right */
        if (f >= B(8)) {
          const q = eOut(prog(f, B(8), B(10)));
          spriteBalloon(RIVAL_SPR, lerp(1300, 800, q), 760 + Math.sin(t) * 8, 230, Math.sin(t * 2) > 0 ? 1 : .3, t);
        }
      } });
      flash(f, 0, .3, 4);
      vig(.35);
      if (f < B(4)) {
        kinetic(f, ['POV:'], 540, 240, { f0: 0, size: 130 });
        kinetic(f, ['YOU OWN THE', '*SUNRISE.*'], 540, 360, { f0: B(1), stagger: 5, size: 175, out: B(4) - 6 });
      } else if (f < B(8)) {
        label('5:30 AM  ·  CAPPADOCIA', 540, 330, 50, '#ffe6b8', { track: .3, alpha: prog(f, B(4), B(5)) * (1 - prog(f, B(7.5), B(8))) });
        kinetic(f, ['DOZENS OF', 'BALLOONS.', '*ALL YOURS.*'], 540, 380, { f0: B(5), stagger: B(1), size: 150, out: B(8) - 4 });
      } else if (f < B(12)) {
        bubble(f, B(8) + 4, 'Nice view. Shame it\'s MY sky.', 70, 270, 870, { size: 56, cps: 2.2 });
      } else {
        kinetic(f, ['OH', '*REALLY?*'], 540, 330, { f0: B(12), stagger: B(1), size: 200, from: 'slam' });
      }
    } else if (f < B(20)) {
      /* the fleet answers: waves of balloons on every beat */
      const i = Math.floor((f - B(14)) / BEAT);
      const cam = { x: 40 + (f - B(14)) * .6, y: 520 - (f - B(14)) * 1.2, z: 1.05 + beatPulse(f, B(14)) * .02 };
      /* a quarter of the fleet takes off on each beat, rising out of the valley */
      dawn({ t: 3 + t, cam, lift: b => { const at = B(14) + Math.floor(b.rank * 4) * BEAT + (b.rank * 4 % 1) * 6; return (1 - eOut(prog(f, at, at + 40))) * 1500 * (.3 + b.d); } });
      vig(.35);
      const vals = [10, 40, 90, 164, 164, 164], v = Math.round(lerp(i ? vals[i - 1] : 1, vals[i], eOut(prog(f, B(14 + i), B(14 + i) + 8))));
      if (i < 4) bigNumber(fmt(v), 540, 700, 320, 'BALLOONS', { s: 1 + beatPulse(f, B(14)) * .08 });
      else kinetic(f, ['YOUR FLEET.', '*YOUR SKY.*'], 540, 330, { f0: B(18), stagger: 5, size: 170 });
      flash(f, B(14), .7, 6);
    } else if (f < B(24)) {
      /* the game itself: fly it, then the town */
      backdrop(f, { dim: .15, y: 200, z: 1.08 });
      const fly = f < B(22), img = await clip(fly ? 'flight' : 'empire', (f - (fly ? B(20) : B(22))) / FPS, 1, fly ? 20 : 0);
      const k = eOut(prog(f, fly ? B(20) : B(22), (fly ? B(20) : B(22)) + 9));
      phoneShot(img, 540 + (1 - k) * (fly ? 700 : -700), 1120, 600, fly ? .05 : -.05);
      kinetic(f, [fly ? 'FLY IT *YOURSELF.*' : 'BUILD THE *TOWN.*'], 540, 250, { f0: fly ? B(20) : B(22), size: 130 });
    } else if (f < B(28)) {
      /* then the night show */
      await footage('show', f, B(24), { start: 0, z0: 1.1, z1: 1.22, fx: .5, fy: .5, len: B(4), kick: .015, filter: 'brightness(1.3) saturate(1.25) contrast(1.05)' });
      shade(.4, .3, .55);
      kinetic(f, ['THEN', '*OWN THE NIGHT.*'], 540, 250, { f0: B(24), stagger: B(1), size: 160 });
      if (f >= B(26)) bubble(f, B(26), '...how?!', 70, 1220, 560, { size: 60, cps: 1.5, e: { shock: 1, t } });
    } else {
      endCard(f, B(28), ['THE SKY HAS', 'A NEW *BARON.*'], { size: 160 });
    }
    flash(f, B(28), .6, 8);
  },
};

/* a tuning sheet (not a reel): the dawn world at camera heights 0, 150, … */
REELS[0] = { frames: 10, async draw(f) { dawn({ t: 10, cam: { x: 0, y: 200 + f * 150, z: 1 } }); if (f === 9) endCard(f + 60, 0, ['TEST', '*LINE.*']); } };

/* ======================= sound: the same moments, as events for sfx.js =======================
   [frame, sound, options]. Frames use the same B() beats as the pictures above, so a hit lands on the frame its
   word, cut or counter does. Sounds: boom (808 kick + sub drop), kick, clap, snare, whoosh, riser (o.len frames long, ending on
   its frame: the hit it leads into), coin, kaching, fwoosh (burner), scratch, bwomp, tick, tock, shimmer, laugh (o.n "ha"s,
   o.gap frames apart), pop, ding. o.g scales the level. */
const counterTicks = (a, b, step = 2) => { const ev = []; for (let f = a; f < b; f += step) ev.push([f, 'coin', { g: .35 + .3 * (f - a) / (b - a), p: 1 + .25 * (f - a) / (b - a) }]); return ev; };
/* the end card's own beats (endCard in lib.js: headline, icon at +2, title +2.5, line +3, pill +3.5) */
const endSfx = f0 => [[f0, 'riser', { len: B(2) }], [f0, 'boom', { g: 1.1 }], [f0 + 5, 'clap'], [f0 + B(2), 'shimmer'], [f0 + B(2), 'kick', { g: .7 }],
  [f0 + B(2.5), 'boom', { g: .8 }], [f0 + B(3), 'tick', { g: .6 }], [f0 + B(3.5), 'ding'], [f0 + B(3.5), 'clap', { g: .7 }]];
REELS[1].sfx = [
  [0, 'boom', { g: 1.2 }], [0, 'whoosh', { g: .6, rev: 1 }], [B(1), 'boom'], [B(1), 'clap'],                           /* HE THINKS / YOU CAN'T FLY */
  [B(2), 'whoosh'], [B(2) + 3, 'pop'], [B(4), 'clap', { g: .8 }],                                                       /* the phone, the taunt, DAY 2 tag */
  [B(6), 'kick'], [B(6), 'laugh', { n: 4, gap: B(.5) }],                                                                /* HA HA */
  [B(8), 'riser', { len: B(1.5) }], [B(8), 'boom', { g: 1.2 }], [B(8), 'fwoosh'], [B(9), 'boom'],                     /* CHALLENGE ACCEPTED */
  [B(10), 'snare'], [B(10), 'fwoosh', { g: .7 }], [B(11), 'snare'], [B(12), 'whoosh', { g: .7 }], [B(12), 'snare'], [B(12), 'kaching'], [B(13), 'snare'],
  ...[14, 16, 18, 20, 22, 23].map(b => [B(b), 'whoosh', { g: .45, short: 1 }]),                                         /* a cut on every beat */
  [B(14), 'kick', { g: .8 }], ...[15, 17, 19].map(b => [B(b), 'boom', { g: .9 }]), [B(21), 'boom', { g: 1.25 }], [B(21), 'shimmer', { g: .6 }], /* 10, 40, 90, 164 */
  [B(24), 'whoosh'], ...counterTicks(B(24), B(25.5)), [B(25.5), 'kaching'], [B(25), 'clap'],                            /* the bank, on autopilot */
  [B(26), 'scratch'], [B(26) + 6, 'bwomp'],                                                                             /* ...wait. 164?! */
  [B(28), 'boom', { g: 1.1 }], [B(28), 'clap'],                                                                         /* WHO'S CUTE NOW? */
  ...endSfx(B(30)),
];
REELS[2].sfx = [
  [0, 'boom', { g: 1.2 }], [6, 'clap'], [B(1), 'boom'], [B(1), 'whoosh', { g: .6 }],                                     /* hook */
  ...[2, 3, 4, 5, 6, 7, 8].map(b => [B(b), 'whoosh', { g: .4, short: 1 }]),
  [B(2), 'kick', { g: .8 }], [B(4), 'boom', { g: .85 }], [B(6), 'boom', { g: .9 }], [B(7), 'boom', { g: 1.05 }],          /* 10, 40, 90, 164 */
  [B(9), 'riser', { len: B(1) }], [B(9), 'boom', { g: 1.2 }],                                                           /* BARON. */
  ...SPLITS.map(([, at]) => [at, 'ding', { g: .8 }]),                                                                   /* the splits */
  ...Array.from({ length: 28 }, (_, i) => [B(2 + i), i % 2 ? 'tock' : 'tick', { g: .55 }]),                             /* the timer runs to B(30) */
  ...[10, 15, 19, 23].map(b => [B(b), 'whoosh', { g: .8 }]), ...[10, 15, 19, 23].map(b => [B(b + 1.2), 'pop']),          /* map legs, the pin lands */
  [B(10) + 2, 'pop'], [B(10) + 2, 'laugh', { n: 2, gap: 6, g: .55 }],                                                   /* Lucky. Try that abroad. */
  ...[12, 17, 21].flatMap(b => [[B(b), 'boom'], ...counterTicks(B(b), B(b) + 24, 3)]),                            /* the cities, holding cash */
  [B(26), 'whoosh'], ...counterTicks(B(26), B(29.5), 3), [B(30), 'riser', { len: B(2) }],
  [B(30), 'boom', { g: 1.3 }], [B(30), 'kaching'], [B(30), 'ding'],                                                     /* 8,760,000 · WORLD EMPIRE · timer stops */
  [B(32), 'scratch'], [B(32) + 6, 'bwomp'],                                                                             /* ...okay. That was fast. */
  ...endSfx(B(34)),
];
REELS[3].sfx = [
  [0, 'boom', { g: 1.2 }], [0, 'fwoosh', { g: 1.1 }], [B(1), 'clap'], [B(1) + 5, 'boom'],                                /* POV: YOU OWN THE SUNRISE. */
  [B(8), 'riser', { len: B(8), g: .35, air: 1 }],                                                                          /* the crane up, a long swell of air */
  ...[4, 6, 8, 10, 12].map(b => [B(b), 'fwoosh', { g: .55 }]),                                                          /* the hero's burner on the beats */
  [B(4), 'shimmer', { g: .5 }], [B(5), 'clap', { g: .8 }], [B(6), 'clap', { g: .8 }], [B(7), 'clap'],                   /* DOZENS OF / BALLOONS. / ALL YOURS. */
  [B(8), 'whoosh'], [B(8) + 4, 'pop'], [B(10), 'laugh', { n: 3, gap: 7, g: .75 }],                                      /* the rival drifts in, smug */
  [B(12), 'riser', { len: B(1) }], [B(12), 'boom'], [B(13), 'boom', { g: 1.1 }],                                       /* OH REALLY? */
  ...[14, 15, 16, 17].map((b, i) => [B(b), 'fwoosh', { g: .8 + i * .1 }]),                                              /* the fleet launches in waves */
  [B(14), 'kick'], [B(15), 'boom', { g: .85 }], [B(16), 'boom', { g: .95 }], [B(17), 'boom', { g: 1.2 }],              /* 10, 40, 90, 164 */
  [B(18), 'clap'], [B(18) + 5, 'clap'], [B(18), 'shimmer', { g: .6 }],                                                  /* YOUR FLEET. YOUR SKY. */
  [B(20), 'whoosh'], [B(20), 'snare'], [B(22), 'whoosh'], [B(22), 'snare'],                                             /* FLY IT YOURSELF / BUILD THE TOWN */
  [B(24), 'whoosh', { g: .9 }], [B(24), 'boom', { g: .9 }], [B(25), 'boom'], [B(24), 'shimmer', { g: .7, low: 1 }],     /* THEN OWN THE NIGHT */
  [B(26), 'scratch', { g: .8 }], [B(26) + 5, 'bwomp'],                                                                  /* ...how?! */
  ...endSfx(B(28)),
];
