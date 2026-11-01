// Records the App Preview's scenes from the HTML prototype, frame by frame on a fake clock (so every frame is a
// real 1/30 s of the game, however slow the capture), then preview.py adds the captions, the cuts and the music
// and encodes the video. The game is only read, never changed.
//   NODE_PATH=$(npm root -g) node tools/appstore/v2/shots.js <raw dir> iphone      (writes <raw dir>/saves.json)
//   NODE_PATH=$(npm root -g) node tools/appstore/v2/preview.js <raw dir> <lang> [iphone|ipad]
// Output: marketing/appstore/<lang>-v2/preview/<device>.mp4 (iPhone 886x1920, iPad 1200x1600, 30 fps).
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');
const GAME = 'file://' + ROOT + '/prototype/balloon-baron.html';
const raw = path.resolve(process.argv[2] || '.'), lang = process.argv[3] || 'tr', devs = process.argv[4] ? [process.argv[4]] : ['iphone', 'ipad'];
const VIEW = { iphone: { width: 443, height: 960 }, ipad: { width: 600, height: 800 } };
const saves = JSON.parse(fs.readFileSync(path.join(raw, 'saves.json'), 'utf8'));
const FPS = 30, STEP = 1000 / FPS;

const clean = `S.hezQ = []; S.paper = null; S.paperNext = null; S.eventDue = false; S.nextEvent = 99999; S.chapterNews = null; S.late = null; S.newPost = []; S.tutorialDone = true; S.tips = new Proxy({}, { get: () => 1 }); S.iap = Object.fromEntries(Object.keys(SHOP).map(k => [k, 1])); S.ach = Object.fromEntries(ACHS.map(a => [a[0], 1])); S.tut = { done: 1 }; S.ventTip = 1; S.selfFlights = Math.max(S.selfFlights || 0, 60);`;
const empire = "S.barons = Object.assign({}, S.barons, { cap: 120 }); S.holding = 8760000; S.bld = Object.assign({}, S.bld, { hangar: 6 }); const sz = ['M','L','M','S','L']; while (S.balloons.length < 164) addBalloon(sz[S.balloons.length % 5]); while (S.pilots.length < 150) S.pilots.push({ id: S.nextId++, name: P_NAMES[S.pilots.length % P_NAMES.length] + ' ' + pilotInitial(S.pilots.length) + '.', lvl: 2, xp: 0, trait: null }); S.cash = 3043969; assignPilots();";
const green = "S.weather.flag = 'green'; const nw = newWeather; newWeather = () => { const w = nw(); w.flag = 'green'; return w; };";

/* The story: each scene loads a company, sets the moment up, and records `frames` frames; `at` runs game calls on
   given frames. The order and lengths match preview.py's captions. */
const SCENES = [
  { id: 'flight', save: 'cap', prep: green, frames: 180, warm: 500,
    go: () => startFlight(16), at: { 0: () => setBurn(true), 105: () => setBurn(false), 140: () => setBurn(true), 172: () => setBurn(false) } },
  { id: 'collect', save: 'cap', prep: green, frames: 96, warm: 200, go: () => $('go').click() },
  { id: 'auto', save: 'cap', prep: empire + green + ' nightOn = false;', frames: 120, warm: 1600,
    go: () => { nextPopup = () => {}; showPoach = () => {}; autoStart(); } },
  { id: 'cities', save: 'world', frames: 132, warm: 100, go: () => switchRegion('lux') },
  { id: 'night', save: 'cap', frames: 90, warm: 1800,
    go: () => { pickNightEvent = () => ({ k: 'fireworks', hotel: 1, line: 'Düğün havai fişekleri: ' + RD().hotels[1], head: null }); startNight(); const B = nightBase(W, H); const k = 1.12, c = tiso(6.5, 9); NIGHT.v = { z: B.z * k, ox: W / 2 - c[0] * B.z * k, oy: H * .66 - c[1] * B.z * k }; NIGHT.wait = 99; } },
  /* the show's last seconds, so its finale lands under the end card */
  { id: 'show', save: 'cap', noStart: true, frames: 195, warm: 17200, at: { 0: () => { NIGHT.wait = 999; } },
    prep: "const sz = ['M','L','M','S','L']; while (S.balloons.length < 120) addBalloon(sz[S.balloons.length % 5]); S.bld = Object.assign({}, S.bld, { hangar: 6 }); S.showIds = S.balloons.map(b => b.id); S.showN = S.showIds.length; S.showTonight = S.day - 1;",
    go: () => startNight() },
];

(async () => {
  const br = await chromium.launch();
  for (const dev of devs) {
    const work = path.join(raw, 'preview', dev);
    if (!process.env.ONLY) fs.rmSync(work, { recursive: true, force: true });
    for (const [i, sc] of SCENES.entries()) {
      if (process.env.ONLY && !process.env.ONLY.split(',').includes(sc.id)) continue;
      const dir = path.join(work, `${i}-${sc.id}`); fs.rmSync(dir, { recursive: true, force: true }); fs.mkdirSync(dir, { recursive: true });
      const ctxB = await br.newContext({ viewport: VIEW[dev], deviceScaleFactor: 2, hasTouch: true });
      await ctxB.addInitScript(() => { try { localStorage.clear(); } catch (e) {} });
      const p = await ctxB.newPage(); const errs = []; p.on('pageerror', e => errs.push(e.message));
      /* a paused fake clock: only runFor moves it, so a slow screenshot doesn't speed the game up */
      await p.clock.install({ time: new Date('2026-06-01T05:30:00') }); await p.clock.pauseAt(new Date('2026-06-01T05:30:01'));
      await p.goto(GAME);
      /* animation frames get the faked clock's time, as the game's own timers do */
      await p.evaluate(() => { const r = window.requestAnimationFrame.bind(window); window.requestAnimationFrame = cb => r(() => cb(performance.now())); });
      await p.clock.runFor(800);
      await p.evaluate(([j, prep, clean, start]) => {
        sfx = () => {}; save = () => {};
        let sd = 4242; Math.random = () => { sd = (sd * 9301 + 49297) % 233280; return sd / 233280; };
        S = JSON.parse(j); eval(clean); applyRegionTheme(); eval(prep || '');
        if (start) startDay();
      }, [saves[sc.save], sc.prep || '', clean, !sc.noStart]);
      await p.clock.runFor(1300);
      await p.evaluate(() => { $('menu').hidden = true; $('hez').hidden = true; });
      await p.evaluate(sc.go); await p.clock.runFor(sc.warm);
      for (let f = 0; f < sc.frames; f++) {
        if (sc.at && sc.at[f]) await p.evaluate(sc.at[f]);
        await p.evaluate(() => { $('hez').hidden = true; if (S.reviews) S.reviews = S.reviews.filter(r => r.stars >= 4); }); /* the review ticker shows the happy ones */
        await p.clock.runFor(STEP * (sc.step || 1));
        await p.screenshot({ path: path.join(dir, String(f).padStart(4, '0') + '.jpg'), type: 'jpeg', quality: 94 });
      }
      console.log(dev, sc.id, sc.frames, 'frames', errs.length ? errs : '');
      await ctxB.close();
    }
    if (process.env.ONLY) continue;
    const out = path.join(ROOT, 'marketing/appstore', `${lang}-v2`, 'preview'); fs.mkdirSync(out, { recursive: true });
    execFileSync('python3', ['-I', path.join(__dirname, 'preview.py'), work, lang, dev, path.join(out, `${dev}.mp4`)], { stdio: 'inherit' });
  }
  await br.close();
})();
