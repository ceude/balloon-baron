// Records the gameplay clips for the Instagram reels from the HTML prototype, frame by frame on a fake clock (as
// tools/appstore/v2/preview.js does), with the Turkish prototype shown in English: every text node and every canvas
// fillText goes through the app's own catalog (<raw>/tr2en.json, made by tr2en.py) plus a few extras below.
//   NODE_PATH=$(npm root -g) node tools/appstore/v2/shots.js <raw> iphone        (writes <raw>/saves.json)
//   NODE_PATH=$(npm root -g) node tools/marketing/reels/capture.js <raw> [scene…]   (writes <raw>/clips/<scene>/0000.jpg…, 1329x2880)
// PROBE=1 takes one frame per scene and lists the texts that stayed Turkish.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../..');
const GAME = 'file://' + ROOT + '/prototype/balloon-baron.html';
const raw = path.resolve(process.argv[2] || '.'), only = process.argv.slice(3);
const saves = JSON.parse(fs.readFileSync(path.join(raw, 'saves.json'), 'utf8'));
require('child_process').execFileSync('python3', [path.join(__dirname, 'tr2en.py'), raw], { stdio: 'inherit' });
const DICT = JSON.parse(fs.readFileSync(path.join(raw, 'tr2en.json'), 'utf8'));
const FPS = 30, STEP = 1000 / FPS, PROBE = !!process.env.PROBE;
/* texts the catalog words differently (the prototype builds them itself) */
Object.assign(DICT, {
  'Kapadokya': 'Cappadocia', 'Luksor': 'Luxor', 'Kenya': 'Kenya', 'Türkiye': 'Türkiye', 'ABD': 'USA', 'Mısır': 'Egypt', 'İngiltere': 'England',
  'Kapadokya, Türkiye': 'Cappadocia, Türkiye', 'Luksor, Mısır': 'Luxor, Egypt', 'Albuquerque, ABD': 'Albuquerque, USA', 'Bristol, İngiltere': 'Bristol, England', 'Maasai Mara, Kenya': 'Maasai Mara, Kenya',
  'Dünya haritası': 'World map', 'Otomatik': 'Autopilot', 'Otomatik mod': 'Autopilot', 'Buradasın': 'You are here', 'Kilitli': 'Locked', 'Yakında': 'Soon', 'Baron': 'Baron', 'Bölgeye git': 'Go there', 'Kapat': 'Close',
  'Brülör': 'Burner', 'BRÜLÖR': 'BURNER', 'VALF': 'VENT', 'İrtifa': 'Altitude', 'Dikey': 'Vertical', 'Yakıt': 'Fuel', 'Panorama fotoğrafı': 'Panorama photo',
  'Hedef': 'Goals', 'Holding': 'Holding', 'Pazar': 'Market', 'Banka': 'Bank', 'Ekip': 'Crew', 'Filo': 'Fleet', 'Pas geç': 'Skip', 'İlerlet': 'Advance', 'Sigorta': 'Insurance', 'Bilet': 'Ticket', 'Ayarla': 'Set',
  'HANGAR': 'HANGAR', 'EKİP': 'CREW', 'FİNANS': 'FINANCE', 'ŞİRKETLER': 'COMPANIES', 'AJANS': 'AGENCY', 'SATIŞ': 'SALES', 'OTEL': 'HOTEL', 'OTELLER': 'HOTELS',
});
const PAT = { 'Bugünkü görev: (.+)': "Today's mission: $1", '(\\+?[\\d.,]+) yolcu': '$1 passengers', 'Yolcu topla \\(1 balon\\)': 'Collect passengers (1 balloon)', '✓ ?Sigorta': '✓ Insurance', 'Kurucuyla uçuş:?': "Founder's flight", 'Tahmini': 'Expected', 'yolcu ·': 'passengers ·', 'Gün (\\d+) sabahına geç': 'On to the morning of day $1', 'Gün (\\d+)': 'Day $1', 'Yolcu topla \\((\\d+) balon\\)': 'Collect passengers ($1 balloons)', 'Tahmini (\\S+) yolcu · (.+)': 'Expected $1 passengers · $2',
  'Yerde rüzgâr (\\d+) km/sa': 'Surface wind $1 km/h', '(\\d+) km/sa': '$1 km/h', 'İniş alanı (.+) km': 'Landing field $1 km', 'Gün (\\d+) gecesi': 'Night of day $1',
  'Balon Şöleni · (\\d+) balon': 'Balloon Show · $1 balloons', '(.+) Holding': '$1 Holding', 'Holding kasası (.+)': 'Holding cash $1', '(\\d+)\\. gün': 'Day $1' };

const clean = `S.hezQ = []; S.paper = null; S.paperNext = null; S.eventDue = false; S.nextEvent = 99999; S.chapterNews = null; S.late = null; S.newPost = []; S.tutorialDone = true; S.tips = new Proxy({}, { get: () => 1 }); S.iap = Object.fromEntries(Object.keys(SHOP).map(k => [k, 1])); S.ach = Object.fromEntries(ACHS.map(a => [a[0], 1])); S.tut = { done: 1 }; S.ventTip = 1; S.selfFlights = Math.max(S.selfFlights || 0, 60); S.company = 'Daybreak Balloons';`;
const fleet = n => `S.barons = Object.assign({}, S.barons, { cap: 120 }); S.holding = 8760000; S.bld = Object.assign({}, S.bld, { hangar: 6 }); const sz = ['M','L','M','S','L']; while (S.balloons.length < ${n}) addBalloon(sz[S.balloons.length % 5]); while (S.pilots.length < ${n}) S.pilots.push({ id: S.nextId++, name: P_NAMES[S.pilots.length % P_NAMES.length] + ' ' + pilotInitial(S.pilots.length) + '.', lvl: 2, xp: 0, trait: null }); S.cash = ${Math.round(n * 18500)}; assignPilots();`;
const green = "S.weather.flag = 'green'; const nw = newWeather; newWeather = () => { const w = nw(); w.flag = 'green'; return w; };";
const noUI = "document.getElementById('sheet').style.visibility = 'hidden';";

/* each scene loads a company, sets the moment up and records `frames` frames (`step` game frames apart) */
const SCENES = [
  { id: 'early', save: 'early', prep: green + "S.tut = { done: 1 };", frames: 60, warm: 400, go: () => { TUTA = null; $('tut').hidden = true; } },
  { id: 'town10', save: 'cap', prep: green + fleet(10).replace('cap: 120', 'cap: 0').replace('S.holding = 8760000;', ''), frames: 45, warm: 300 },
  { id: 'town40', save: 'cap', prep: green + fleet(40), frames: 45, warm: 300 },
  { id: 'town90', save: 'cap', prep: green + fleet(90), frames: 45, warm: 300 },
  { id: 'empire', save: 'cap', prep: green + fleet(164), frames: 90, warm: 300 },
  { id: 'flight', save: 'cap', prep: green, frames: 180, warm: 500,
    go: () => startFlight(16), at: { 0: () => setBurn(true), 100: () => setBurn(false), 135: () => setBurn(true) } },
  { id: 'collect', save: 'cap', prep: green + fleet(60), frames: 90, warm: 200, go: () => $('go').click() },
  { id: 'auto', save: 'cap', prep: green + fleet(164) + ' nightOn = false;', frames: 150, warm: 1600,
    go: () => { nextPopup = () => {}; showPoach = () => {}; autoStart(); } },
  { id: 'travel', save: 'world', frames: 120, warm: 100, go: () => switchRegion('lux') },
  { id: 'world', save: 'world', frames: 20, warm: 1200, go: () => showWorldMap() },
  { id: 'lux', save: 'world', prep: "switchRegion('lux'); document.querySelectorAll('.travel').forEach(e => e.remove());", frames: 45, warm: 3600 },
  { id: 'abq', save: 'world', prep: "switchRegion('abq');", frames: 45, warm: 3600 },
  { id: 'bri', save: 'world', frames: 45, warm: 600 },
  { id: 'holding', save: 'world', prep: "S.hold = Object.assign({}, S.hold, { offices: { nyc: 400, ist: 410 }, tvUntil: S.day + 9, rnd: 2 });", frames: 30, warm: 2600, go: () => openHQ() },
  { id: 'show', save: 'cap', noStart: true, frames: 150, warm: 16500, at: { 0: () => { NIGHT.wait = 999; } },
    prep: "const sz = ['M','L','M','S','L']; while (S.balloons.length < 120) addBalloon(sz[S.balloons.length % 5]); S.bld = Object.assign({}, S.bld, { hangar: 6 }); S.showIds = S.balloons.map(b => b.id); S.showN = S.showIds.length; S.showTonight = S.day - 1;",
    go: () => startNight() },
];

(async () => {
  const br = await chromium.launch();
  const missing = new Set();
  for (const sc of SCENES) {
    if (only.length && !only.includes(sc.id)) continue;
    const dir = path.join(raw, 'clips', sc.id); fs.rmSync(dir, { recursive: true, force: true }); fs.mkdirSync(dir, { recursive: true });
    const ctxB = await br.newContext({ viewport: { width: 443, height: 960 }, deviceScaleFactor: 3, hasTouch: true }); /* 1329x2880: sharp even when the reels zoom in */
    await ctxB.addInitScript(([dict, pat]) => {
      try { localStorage.clear(); } catch (e) {}
      const P = Object.entries(pat).map(([k, v]) => [new RegExp('^' + k + '$'), v]);
      /* catalog entries with placeholders become patterns too */
      for (const [tr, en] of Object.entries(dict)) if (/%(\d\$)?@/.test(tr)) {
        let i = 0; const re = tr.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/%(\d)\\\$@|%@/g, (m, n) => '(.+?)');
        let j = 0; const out = en.replace(/%(\d)\$@|%@/g, (m, n) => '$' + (n || ++j));
        P.push([new RegExp('^' + re + '$'), out]);
      }
      window.__miss = new Set();
      const tl = s => {
        if (typeof s !== 'string') return s;
        const t = s.trim(); if (!t || !/[a-zçğıöşüâîû]/i.test(t)) return s;
        const fix = v => v.replace(/Luksor/g, 'Luxor').replace(/Kapadokya/g, 'Cappadocia');
        if (dict[t] !== undefined) return s.replace(t, fix(dict[t]));
        /* the pieces a pattern captured are looked up too (mission names inside "Today's mission: …") */
        for (const [re, out] of P) if (re.test(t)) return s.replace(t, fix(t.replace(re, (m, ...g) => out.replace(/\$(\d)/g, (q, i) => { const v = g[i - 1]; return typeof v === 'string' && dict[v.trim()] !== undefined ? dict[v.trim()] : v; }))));
        if (/[çğıöşüÇĞİÖŞÜâ]|\b(ve|bir|gün|balon|yolcu)\b/i.test(t)) window.__miss.add(t);
        return s;
      };
      window.__tl = tl;
      const C = CanvasRenderingContext2D.prototype;
      for (const f of ['fillText', 'strokeText', 'measureText']) { const o = C[f]; C[f] = function (t, ...a) { return o.call(this, tl(t), ...a); }; }
      window.__translateDOM = () => {
        const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
        for (let n; (n = w.nextNode());) { if (n.parentNode && /SCRIPT|STYLE/.test(n.parentNode.nodeName)) continue; const v = tl(n.nodeValue); if (v !== n.nodeValue) n.nodeValue = v; }
      };
    }, [DICT, PAT]);
    const p = await ctxB.newPage(); const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.clock.install({ time: new Date('2026-06-01T05:30:00') }); await p.clock.pauseAt(new Date('2026-06-01T05:30:01'));
    await p.goto(GAME);
    await p.evaluate(() => { const r = window.requestAnimationFrame.bind(window); window.requestAnimationFrame = cb => r(() => cb(performance.now())); });
    await p.clock.runFor(800);
    await p.evaluate(([j, prep, clean, start]) => {
      sfx = () => {}; save = () => {};
      let sd = 4242; Math.random = () => { sd = (sd * 9301 + 49297) % 233280; return sd / 233280; };
      S = JSON.parse(j); eval(clean); applyRegionTheme(); eval(prep || '');
      if (start) startDay();
    }, [saves[sc.save], sc.prep || '', clean, !sc.noStart]);
    await p.clock.runFor(1300);
    await p.evaluate(() => { $('menu').hidden = true; $('hez').hidden = true; const st = document.createElement('style'); st.textContent = '#chirp { visibility: hidden !important; }'; document.head.appendChild(st); });
    if (sc.go) await p.evaluate(sc.go);
    await p.clock.runFor(sc.warm);
    const n = PROBE ? 1 : sc.frames;
    for (let f = 0; f < n; f++) {
      if (sc.at && sc.at[f]) await p.evaluate(sc.at[f]);
      await p.evaluate(() => { $('hez').hidden = true; $('toast') && ($('toast').style.display = 'none'); __translateDOM(); });
      await p.clock.runFor(STEP * (sc.step || 1));
      await p.evaluate(() => __translateDOM());
      await p.screenshot({ path: path.join(dir, String(f).padStart(4, '0') + '.jpg'), type: 'jpeg', quality: 93 });
    }
    const miss = await p.evaluate(() => [...__miss]); miss.forEach(m => missing.add(sc.id + ': ' + m));
    console.log(sc.id, n, 'frames', errs.length ? errs : '');
    await ctxB.close();
  }
  if (missing.size) console.log('still Turkish:\n' + [...missing].join('\n'));
  await br.close();
})();
