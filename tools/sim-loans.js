// Usage: NODE_PATH=$(npm root -g) node tools/sim-loans.js   (the big-loan check behind docs/GAME_DESIGN.md "Krediler")
// Careless player: takes the big loan the day it unlocks and spends it all on balloons at once. Does the bank seize?
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  const res = [];
  for (const cfg of [{ k: 500, amt: 500000, days: 150, inst: 4000, needN: 20, needNet: 24000, baron: 1 }]) {
   for (let seed = 1; seed <= 12; seed++) {
    await p.goto('file:///home/user/balloon-baron/prototype/balloon-baron.html'); await p.waitForTimeout(300);
    res.push(await p.evaluate(([seed, cfg]) => {
      let a = seed * 9301 + 49297; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
      sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {};
      startFlight = () => finishDay({ q: Math.random() < .3 ? 'perfect' : Math.random() < .85 ? 'good' : 'far', dist: 60, mis: S.weather.mission, mok: false });
      S = newState(); S.company = 'Bot'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
      const med = () => { const h = (S.netHist || []).slice().sort((x, y) => x - y); return h.length >= 7 ? h[h.length >> 1] : 0; };
      let took = null, minCash = 1e9, seized = 0, nBefore = 0;
      for (let d = 0; d < 420; d++) {
        S.hezQ = []; S.paper = null; S.eventDue = false; S.chapterNews = null; unlockCheck(); assignPilots();
        const C = chap()[S.chapter || 0], need = k => C && C.goals.some(g => g[0] === k && !goalDone(g));
        if (S.lastShare && S.lastShare.cap) { const l = S.lastShare.me / S.lastShare.cap; if (l > .97) S.price += 5; else if (l < .75) S.price -= 5; S.price = clamp(S.price, 120, 260); }
        if (!S.winter && !S.loans.length && S.cash > 50000 && S.balloons.length < 40) { S.cash -= 35000; addBalloon('M'); }
        while (S.balloons.some(x => canFly(x) === 'nopilot') && S.candidates.length) { const c = S.candidates.sort((x, y) => x.wage - y.wage)[0]; S.pilots.push(c); S.candidates = S.candidates.filter(x => x !== c); assignPilots(); }
        for (const x of S.balloons) if (cond(x) <= .05 && S.cash > SIZES[x.size].cost * RENEW + 3000) { S.cash -= SIZES[x.size].cost * RENEW; x.flights = 0; }
        if (S.unl.market) for (const H of HOTELS) if (S.hotels.length < 3 && !S.hotels.includes(H.id) && !owns(H) && starVal(S.rep) >= H.min && S.cash > H.fee * 3 + 4000 && !(S.hotelTaken[H.id] && S.hotelTaken[H.id].until > S.day)) { S.cash -= H.fee * 3; S.hotels.push(H.id); }
        if (S.unl.market && S.guideCd <= S.day && S.cash > 8000) { S.cash -= GUIDE_COST; S.rep = Math.min(1.4, S.rep + .05); S.guideCd = S.day + 5; S.guideUntil = S.day + 3; S.guideCount = (S.guideCount || 0) + 1; S.lastGuide = S.day; }
        const up = (k, buf) => { const L = UPGRADES[k].lv[bl(k)]; if (L && S.cash > L.cost + buf) { S.cash -= L.cost; S.bld = Object.assign({}, S.bld, { [k]: bl(k) + 1 }); } };
        if (need('bldMast')) up('mast', 5000); if (need('bldHangar')) up('hangar', 10000); if (need('bldTop')) up('mast', 10000);
        if (need('influ') && S.influCd <= S.day && S.cash > influCost() + 5000) { S.cash -= influCost(); S.rep += .1; S.influUntil = S.day + 3; S.influCd = S.day + 10; S.influCount = (S.influCount || 0) + 1; }
        // the careless move: big loan the day it unlocks, all of it into balloons right away (even in winter)
        if (!took && (!cfg.baron || (S.barons || {})[S.region]) && S.balloons.length >= cfg.needN && med() >= cfg.needNet && S.loans.length < 2) {
          took = { day: S.day, med: med(), n: S.balloons.length };
          S.cash += cfg.amt; S.loans.push({ amt: cfg.amt, inst: cfg.inst, left: cfg.days }); nBefore = S.balloons.length;
          while (S.cash > 35000) { S.cash -= 35000; addBalloon('M'); }
        }
        S.selfFly = true; assignPilots();
        const before = S.balloons.length;
        launch(S.weather.flag === 'red');
        if (took && S.day - took.day <= cfg.days + 5) { minCash = Math.min(minCash, S.cash); if (S.balloons.length < before) seized++; }
        if (!S.weather) S.weather = newWeather();
        if (!S.rivals[0].fly) rivalFlyPlan();
      }
      return { loan: cfg.k, seed, took: took && `${took.day}d n${took.n} med${Math.round(took.med)}`, minCash: took ? Math.round(minCash) : null, seized, endCash: Math.round(S.cash), n: S.balloons.length };
    }, [seed, cfg]));
   }
  }
  res.forEach(r => console.log(JSON.stringify(r)));
  await b.close();
})();
