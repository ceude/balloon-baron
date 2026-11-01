// Captures the raw game screens for the v2 App Store set from the HTML prototype (it only reads the game).
// Usage: NODE_PATH=$(npm root -g) node tools/appstore/v2/shots.js <out dir> [iphone|ipad] [scene…]
// iphone: 430x932 @3 (1290x2796); ipad: 1032x1376 @2 (2064x2752). Writes <out dir>/<device>/<scene>.png.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const GAME = 'file://' + ROOT + '/prototype/balloon-baron.html';
const out = path.resolve(process.argv[2] || '.'), dev = process.argv[3] || 'iphone', only = process.argv.slice(4);
const VIEW = { iphone: { width: 430, height: 932, s: 3 }, ipad: { width: 1032, height: 1376, s: 2 } }[dev];
const dir = path.join(out, dev); fs.mkdirSync(dir, { recursive: true });
const want = k => !only.length || only.includes(k);

/* the campaign simulation from tools/sim-chapters.js, so the company on screen grew by playing the real rules */
const sim = fs.readFileSync(ROOT + '/tools/sim-chapters.js', 'utf8');
const a = sim.indexOf('for (let d = 0; d < 260; d++) {'), b = sim.indexOf('      return { seed');
const loop = sim.slice(a, b).replace('d < 260', 'd < DAYS').replace("if ((S.chapter || 0) > was) log.ch.push(S.day - 1);", '').replace(/log\.[a-zA-Z]+ = [^;]+;|log\.\w+\.push\([^)]*\);|if \(S\.over[^}]+}/g, '');

(async () => {
  const br = await chromium.launch();
  const p = await br.newPage({ viewport: { width: VIEW.width, height: VIEW.height }, deviceScaleFactor: VIEW.s, hasTouch: true });
  await p.context().addInitScript(() => { try { localStorage.clear(); } catch (e) {} });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  const quiet = () => p.evaluate(() => { $('menu').hidden = true; $('hez').hidden = true; document.querySelectorAll('.travel').forEach(e => e.remove()); });
  const clean = `S.hezQ = []; S.paper = null; S.paperNext = null; S.eventDue = false; S.nextEvent = 99999; S.chapterNews = null; S.late = null; S.newPost = []; S.tutorialDone = true; S.tips = new Proxy({}, { get: () => 1 }); S.iap = Object.fromEntries(Object.keys(SHOP).map(k => [k, 1])); S.ach = Object.fromEntries(ACHS.map(a => [a[0], 1]));`;

  /* a Cappadocia company played by the real rules for `days` days (the second day for the "before" picture,
     130 days for the rest) */
  const simulate = async days => {
    await p.goto(GAME); await p.waitForTimeout(500);
    await p.evaluate(`(() => {
      let a = 7 * 9301 + 49297; const R0 = Math.random; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
      const keep = { sfx, save, showReport, refresh, startFlight };
      sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {};
      startFlight = () => finishDay({ q: Math.random() < .3 ? 'perfect' : 'good', dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && Math.random() < .6 });
      S = newState(); S.company = 'Şafak Balon'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
      const DAYS = ${days}, noUp = false, log = { ch: [], up: [], met: {} };
      ${loop}
      Object.assign(window, keep); sfx = keep.sfx; save = keep.save; showReport = keep.showReport; refresh = keep.refresh; startFlight = keep.startFlight;
      Math.random = R0; S.company = 'Şafak Balon';
    })()`);
    return p.evaluate(() => JSON.stringify(S));
  };
  const capSave = await simulate(130), earlySave = await simulate(1);

  /* 2. the world company: barons of Cappadocia, Albuquerque and Luxor, now in Bristol, the others on autopilot */
  await p.goto(GAME); await p.waitForTimeout(500);
  await p.evaluate(() => { sfx = () => {}; S.company = 'Şafak Balon'; testLuxBaron(); S.barons.lux = 424; S.holding = 9e6; enterRegion('bri'); });
  await p.waitForTimeout(3800);
  const worldSave = await p.evaluate(() => JSON.stringify(S));

  /* the saved games, for preview.js (the App Preview video records its scenes from the same companies) */
  fs.writeFileSync(path.join(out, 'saves.json'), JSON.stringify({ cap: capSave, world: worldSave, early: earlySave }));

  const load = async (saved, prep, start = true) => {
    await p.goto(GAME); await p.waitForTimeout(500);
    await p.evaluate(([j, prep, clean, start]) => {
      sfx = () => {}; save = () => {};
      let sd = 4242; Math.random = () => { sd = (sd * 9301 + 49297) % 233280; return sd / 233280; }; /* the same week every run */
      S = JSON.parse(j); eval(clean); applyRegionTheme(); eval(prep || '');
      if (start) startDay();
    }, [saved, prep, clean, start]);
    await p.waitForTimeout(1300); await quiet(); await p.waitForTimeout(200);
  };
  const shot = async name => { await p.screenshot({ path: path.join(dir, name + '.png') }); console.log('shot', dev, name); };

  if (want('home')) { await load(capSave); await shot('home'); }
  if (want('flight')) {
    await load(capSave, "S.weather.flag = 'green';");
    await p.evaluate(() => startFlight(16));
    await p.waitForTimeout(800); await p.evaluate(() => setBurn(true)); await p.waitForTimeout(5000); await p.evaluate(() => setBurn(false)); await p.waitForTimeout(2000); await p.evaluate(() => setBurn(true)); await p.waitForTimeout(450);
    await shot('flight');
  }
  if (want('auto')) {
    /* a big Cappadocia fleet (the hangar complex holds 192) runs its days by itself */
    await load(capSave, "S.barons = Object.assign({}, S.barons, { cap: 120 }); S.bld = Object.assign({}, S.bld, { hangar: 6 }); const sz = ['M','L','M','S','L']; while (S.balloons.length < 164) addBalloon(sz[S.balloons.length % 5]); while (S.pilots.length < 150) S.pilots.push({ id: S.nextId++, name: P_NAMES[S.pilots.length % P_NAMES.length] + ' ' + pilotInitial(S.pilots.length) + '.', lvl: 2, xp: 0, trait: null }); S.cash = 2400000; assignPilots(); nightOn = false; S.weather.flag = 'green'; const nw = newWeather; newWeather = () => { const w = nw(); w.flag = 'green'; return w; };");
    /* nothing asks for a decision this week (the offers and lessons would stop the run), so it plays its 7 days */
    await p.evaluate(() => { nextPopup = () => {}; showPoach = () => {}; autoStart(); });
    for (let i = 0; i < 6; i++) { await p.waitForTimeout(1500); await shot('auto-run' + i); }
    await p.waitForFunction(() => !AUTO, null, { timeout: 60000 }); await p.waitForTimeout(500); await shot('auto');
  }
  if (want('holding')) {
    await load(worldSave, "S.hold = Object.assign({}, S.hold, { offices: { nyc: 400, ist: 410 }, tvUntil: S.day + 9, rnd: 2 });");
    await p.evaluate(() => openHQ()); await p.waitForTimeout(2600); await shot('holding');
  }
  if (want('world')) { await load(worldSave); await p.evaluate(() => showWorldMap()); await p.waitForTimeout(1200); await shot('world'); }
  if (want('night')) {
    await load(capSave);
    await p.evaluate(() => { pickNightEvent = () => ({ k: 'fireworks', hotel: 1, line: 'Düğün havai fişekleri: ' + RD().hotels[1], head: 'x', sub: 'y' }); startNight(); const B = nightBase(W, H); const k = 1.12, c = tiso(6.5, 9); NIGHT.v = { z: B.z * k, ox: W / 2 - c[0] * B.z * k, oy: H * .66 - c[1] * B.z * k }; NIGHT.wait = 99; });
    await p.waitForTimeout(3200); await shot('night');
  }
  if (want('show')) {
    await load(capSave, "const sz = ['M','L','M','S','L']; while (S.balloons.length < 120) addBalloon(sz[S.balloons.length % 5]); S.bld = Object.assign({}, S.bld, { hangar: 6 }); S.showIds = S.balloons.map(b => b.id); S.showN = S.showIds.length; S.showTonight = S.day - 1;", false);
    await p.evaluate(() => startNight());
    for (const t of [6, 12, 20]) { await p.waitForTimeout(t === 6 ? 6000 : (t - (t === 12 ? 6 : 12)) * 1000); await shot('show-' + t); }
  }
  if (want('design')) { await load(capSave, "S.workshop = { day: 5 };"); await p.evaluate(() => showDesigner()); await p.waitForTimeout(500);
    /* a design worth showing: the constellation pattern on a star envelope, navy and gold */
    const tap = async (fn, arg) => { await p.evaluate(fn, arg); await p.waitForTimeout(250); };
    await tap(() => [...document.querySelectorAll('#menu .pat')].find(b => b.textContent.includes('Takımyıldız')).click());
    await tap(() => [...document.querySelectorAll('#menu .pat')].find(b => b.textContent.includes('Yıldız balon')).click());
    for (const [row, i] of [[0, 2], [1, 1], [2, 9]]) await tap(([row, i]) => document.querySelectorAll('#menu .sws')[row].children[i].click(), [row, i]);
    await p.waitForTimeout(900); await shot('design'); }
  if (want('crew')) { await load(capSave); await p.evaluate(() => openPage('crew')); await p.waitForTimeout(600); await shot('crew'); }
  if (want('fleet')) { await load(capSave, "S.bld = Object.assign({}, S.bld, { hangar: 8 }); const sz = ['M','L','M','S','L']; while (S.balloons.length < 412) addBalloon(sz[S.balloons.length % 5]); while (S.pilots.length < 400) S.pilots.push({ id: S.nextId++, name: P_NAMES[S.pilots.length % P_NAMES.length] + ' ' + pilotInitial(S.pilots.length) + '.', lvl: 2, xp: 0, trait: null }); assignPilots();"); await p.evaluate(() => openPage('fleet')); await p.waitForTimeout(600); await shot('fleet'); }
  /* the "before": the company's second morning, one balloon and a small office */
  if (want('early')) { await load(earlySave, "S.weather.flag = 'green'; S.tut = { done: 1 }; S.ventTip = 1;"); await p.evaluate(() => { TUTA = null; $('tut').hidden = true; }); await p.waitForTimeout(300); await shot('early'); }
  /* the "after": the same company grown to a 164-balloon fleet, Baron of Cappadocia, its holding tower in the town */
  const empire = "S.barons = Object.assign({}, S.barons, { cap: 120 }); S.holding = 8760000; S.bld = Object.assign({}, S.bld, { hangar: 6 }); const sz = ['M','L','M','S','L']; while (S.balloons.length < 164) addBalloon(sz[S.balloons.length % 5]); while (S.pilots.length < 150) S.pilots.push({ id: S.nextId++, name: P_NAMES[S.pilots.length % P_NAMES.length] + ' ' + pilotInitial(S.pilots.length) + '.', lvl: 2, xp: 0, trait: null }); S.cash = 3043969; assignPilots(); S.weather.flag = 'green';";
  if (want('empire')) { await load(capSave, empire); await shot('empire'); }
  if (want('market')) {
    /* one real day on autopilot first, so yesterday's market share is a flown day */
    await load(capSave, empire + " nightOn = false; const nw = newWeather; newWeather = () => { const w = nw(); w.flag = 'green'; return w; };");
    await p.evaluate(() => { nextPopup = () => {}; showPoach = () => {}; autoStart(); });
    await p.waitForFunction(() => AUTO && AUTO.n >= 1, null, { timeout: 30000 }); await p.evaluate(() => autoStop('')); await p.waitForTimeout(1500);
    await quiet(); await p.evaluate(() => { $('autobar') && $('autobar').classList.remove('on'); openPage('market'); }); await p.waitForTimeout(800); await shot('market');
  }
  for (const r of ['lux', 'bri', 'abq', 'cap']) if (want('town-' + r)) {
    await load(worldSave, r === 'bri' ? '' : `switchRegion('${r}')`); await p.waitForTimeout(3600); await quiet(); await shot('town-' + r);
  }
  console.log('errors', errs);
  await br.close();
})();
