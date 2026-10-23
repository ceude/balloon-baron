// Captures the App Store scenes from the prototype at 1290x2796 (raw-<scene>.png in the current folder).
// Usage: NODE_PATH=$(npm root -g) node tools/appstore/shots.js [scene]; then python3 tools/appstore/compose.py . marketing/appstore/tr tr
const { chromium } = require('playwright');
const fs = require('fs');
const sim = fs.readFileSync('/home/user/balloon-baron/tools/sim-chapters.js', 'utf8');
const a = sim.indexOf('for (let d = 0; d < 260; d++) {'), b = sim.indexOf('      return { seed');
const loop = sim.slice(a, b).replace('d < 260', 'd < DAYS').replace("if ((S.chapter || 0) > was) log.ch.push(S.day - 1);", '').replace(/log\.[a-zA-Z]+ = [^;]+;|log\.\w+\.push\([^)]*\);|if \(S\.over[^}]+}/g, '');
const only = process.argv[2];
(async () => {
  const br = await chromium.launch();
  const p = await br.newPage({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 3, hasTouch: true });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  const fresh = async (days) => {
    await p.goto('file:///home/user/balloon-baron/prototype/balloon-baron.html'); await p.waitForTimeout(500);
    await p.evaluate(`(() => {
      let a = 7 * 9301 + 49297; const R0 = Math.random; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
      const keep = { sfx, save, showReport, refresh, startFlight };
      sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {};
      startFlight = () => finishDay({ q: Math.random() < .3 ? 'perfect' : 'good', dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && Math.random() < .6 });
      S = newState(); S.company = 'Şafak Balon'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
      const DAYS = ${days}, noUp = false, log = { ch: [], up: [], met: {} };
      ${loop}
      Object.assign(window, keep); sfx = keep.sfx; save = keep.save; showReport = keep.showReport; refresh = keep.refresh; startFlight = keep.startFlight;
      Math.random = R0;
      S.company = 'Şafak Balon';
      S.iap = Object.fromEntries(Object.keys(SHOP).map(k => [k, 1])); /* every paid item owned: nothing in the shots looks locked or priced */
      S.hezQ = []; S.paper = null; S.paperNext = null; S.eventDue = false; S.nextEvent = 99999; S.chapterNews = null; S.late = null; S.newPost = []; S.tutorialDone = true; S.tips = new Proxy({}, { get: () => 1 });
      startDay();
    })()`);
    await p.waitForTimeout(1500);
    await p.evaluate(() => { $('menu').hidden = true; $('hez').hidden = true; });
    await p.waitForTimeout(300);
  };

  await fresh(100);
  const saved = await p.evaluate(() => JSON.stringify(S));
  const load = async (prep) => {
    await p.goto('file:///home/user/balloon-baron/prototype/balloon-baron.html'); await p.waitForTimeout(500);
    await p.evaluate(([j, prep]) => {
      S = JSON.parse(j); S.nextEvent = 99999; S.eventDue = false; S.late = null; S.hezQ = []; S.paper = null; S.paperNext = null; S.newPost = [];
      eval(prep || '');
      startDay();
    }, [saved, prep]);
    await p.waitForTimeout(1300);
    await p.evaluate(() => { $('menu').hidden = true; $('hez').hidden = true; });
    await p.waitForTimeout(200);
  };
  const shot = async (name) => { await p.screenshot({ path: 'raw-' + name + '.png' }); console.log('shot', name); };
  if (!only || only === 'home') { await load(); await shot('home'); }
  if (!only || only === 'flight') {
    await load("S.weather.flag = 'green';");
    await p.evaluate(() => { startFlight(16); });
    await p.waitForTimeout(800); await p.evaluate(() => setBurn(true)); await p.waitForTimeout(5000); await p.evaluate(() => setBurn(false)); await p.waitForTimeout(2000); await p.evaluate(() => setBurn(true)); await p.waitForTimeout(450);
    await shot('flight');
  }
  if (!only || only === 'collect') { await load(); await p.evaluate(() => $('go').click()); await p.waitForTimeout(2300); await shot('collect'); }
  if (!only || only === 'night') {
    await load();
    await p.evaluate(() => { pickNightEvent = () => ({ k: 'fireworks', hotel: 1, line: 'Düğün havai fişekleri: ' + RD().hotels[1], head: 'x', sub: 'y' }); startNight(); const B = nightBase(W, H); const k = 1.12, c = tiso(6.5, 9); NIGHT.v = { z: B.z * k, ox: W / 2 - c[0] * B.z * k, oy: H * .66 - c[1] * B.z * k }; NIGHT.wait = 99; });
    await p.waitForTimeout(3200); await shot('night');
  }
  if (!only || only === 'design') {
    await load("S.workshop = { day: 5 };");
    await p.evaluate(() => showDesigner()); await p.waitForTimeout(800); await shot('design');
  }
  if (!only || only === 'crew') { await load(); await p.evaluate(() => openPage('crew')); await p.waitForTimeout(600); await shot('crew'); }
  if (!only || only === 'album') {
    await load("S.ach = {}; ['first','mission','perfect10','fleet5','fleet10','hotel','star45','pax1k','winter','fest','rivalDown','design','upgrade3'].forEach((k, i) => S.ach[k] = 2 + i * 7);");
    await p.evaluate(() => showAlbum()); await p.waitForTimeout(800); await shot('album');
  }
  if (!only || only === 'holding') {
    await load("S.barons = { cap: 160 }; S.holding = 486000; S.chapter = 3; S.hold = Object.assign({}, S.hold || {}, { hist: Array.from({ length: 14 }, (_, i) => ({ d: 88 + i, inc: 9000 + i * 900 + (i % 3) * 1500, exp: 4000 + (i % 4) * 700 })) });");
    await p.evaluate(() => openHQ()); await p.waitForTimeout(2600); await shot('holding');
  }
  console.log('errors', errs);
  await br.close();
})();
