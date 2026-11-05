// Usage: NODE_PATH=$(npm root -g) node tools/test-vehicle-sounds.js   (v141.6: contract vehicles sound once per event)
// Plays a week in Bristol with two train contracts through the real town view (requestAnimationFrame, ctrTick) and
// counts the vehicle sounds actually played. Every day it first looks at the station with a card up (the day's report,
// a guide's bubble, a page), then with nothing up, then pans away and back. Expects exactly one arrival and one
// departure per contract, and none while anything covers the town. Also runs Luxor (ship), Albuquerque (coach),
// Cappadocia (charter plane) and the Mara (bush plane) for one contract each. Exit code 1 on failure.
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 390, height: 844 } });
  const errs = []; p.on('pageerror', e => errs.push(String(e)));
  let fail = false;
  for (const [region, jobs, days] of [['bri', [[1, 2], [5, 1]], 8], ['lux', [[1, 3]], 6], ['abq', [[1, 1]], 4], ['cap', [[1, 1]], 4], ['mara', [[1, 2]], 5]]) {
    await p.goto('file://' + (process.env.PROTO || '/home/user/balloon-baron/prototype/balloon-baron.html')); await p.waitForTimeout(300);
    await p.evaluate(([region, jobs]) => {
      let a = 7; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
      save = () => {}; nextPopup = () => {}; startFlight = () => finishDay({ q: 'good', dist: 50 });
      audioInit(); soundOn = true;
      S = newState(); S.company = 'Test';
      const nx = newRegionState(region); RKEYS.forEach(k => { S[k] = nx[k]; }); S.region = region; S.weather = null; S.demand = null; S.plan = null;
      S.unl = Object.assign(S.unl || {}, { crew: true, market: true });
      for (let i = 0; i < 6; i++) addBalloon('L');
      while (S.balloons.some(x => canFly(x) === 'nopilot') && S.candidates.length) { const c = S.candidates[0]; S.pilots.push(c); S.candidates = S.candidates.slice(1); assignPilots(); }
      const K = ctrCfg(), C = ctrState(); C.scene = true; C.met = true;
      for (const [d, len] of jobs) { C.offer = { n: 12, price: 150, day: S.day + d, len, who: K.cast[0].id, made: S.day }; ctrAccept(); }
      C.next = 9999; /* no other offers this week */
      window.LOG = [];
      const real = vehSound;
      vehSound = (key, leaving, g) => { const fresh = !VEH_SND.has(key); window.LOG.push({ key, leaving, day: S.day, covered: uiCovered(), fresh, g }); real(key, leaving, g); };
      const realVx = vxPlay; window.VX_N = 0; vxPlay = (o, g) => { window.VX_N++; realVx(o, g); };
    }, [region, jobs]);
    const look = async () => p.evaluate(() => { /* the station in the middle of the screen, zoomed in */
      if (!TOWN.open) openTown(null, true);
      const r = $('tcv').getBoundingClientRect(), q = tiso(...ctrSpot()); TOWN.anim = null; TOWN.z = .8; TOWN.ox = r.width / 2 - q[0] * TOWN.z; TOWN.oy = r.height / 2 - q[1] * TOWN.z;
    });
    const away = async () => p.evaluate(() => { TOWN.ox += 2000; });
    const clean = () => p.evaluate(() => { S.hezQ = []; S.paper = null; S.eventDue = false; S.chapterNews = null; S.mergeNews = null; S.newPost = []; });
    await clean(); await p.evaluate(() => startDay());
    for (let d = 0; d < days; d++) {
      // 1) a guide's bubble up while you look at the station
      await look(); await p.evaluate(() => { $('hez').hidden = false; }); await p.waitForTimeout(500); await p.evaluate(() => { $('hez').hidden = true; });
      // 2) a page up
      await p.evaluate(() => { $('page').hidden = false; }); await p.waitForTimeout(400); await p.evaluate(() => { $('page').hidden = true; });
      // 3) nothing up: an arrival or departure due now happens, with its sound
      await p.waitForTimeout(600);
      // 4) pan away and back, and keep looking: nothing again
      await away(); await p.waitForTimeout(300); await look(); await p.waitForTimeout(900);
      // the day: fly, the end-of-day report comes up; look at the station under it
      await p.evaluate(() => { closeTown(); TOWN.open = false; launch(false); });
      await p.waitForTimeout(200); await look(); await p.waitForTimeout(700);
      await clean(); await p.evaluate(() => { $('report').hidden = true; startDay(); });
    }
    const r = await p.evaluate(() => ({ log: window.LOG, vx: window.VX_N, booked: S.ctr.booked.filter(k => !k.rival).map(k => ({ id: k.id, day: k.day, len: k.len, arrived: !!k.arrived })), depart: S.ctr.depart, day: S.day, hum: typeof ctrHum }));
    const played = r.log.filter(x => x.fresh), arr = played.filter(x => !x.leaving), dep = played.filter(x => x.leaving), cov = played.filter(x => x.covered);
    const ok = arr.length === jobs.length && dep.length === jobs.length && !cov.length && r.log.length === played.length && r.hum === 'undefined';
    if (!ok) fail = true;
    console.log(`${region}: ${jobs.length} contract(s), days ${days}: arrival sounds ${arr.length} (days ${arr.map(x => x.day).join(',')}), departure sounds ${dep.length} (days ${dep.map(x => x.day).join(',')}), while covered ${cov.length}, suppressed repeats ${r.log.length - played.length}, voices ${r.vx}, gain ${played.map(x => x.g.toFixed(2)).join('/')} ${ok ? 'OK' : 'FAIL'}`);
    if (!ok) console.log(JSON.stringify(r));
  }
  if (errs.length) { console.log('page errors:', errs.slice(0, 5)); fail = true; }
  await b.close(); process.exit(fail ? 1 : 0);
})();
