// Usage: NODE_PATH=$(npm root -g) node tools/sim-chapters.js   (NOUP=1 drops the upgrade goals for comparison)
// Bot playing a goal-minded player for 260 days in Cappadocia. NOUP=1 removes the upgrade goals and purchases.
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 390, height: 800 } });
  await p.goto('file:///home/user/balloon-baron/prototype/balloon-baron.html'); await p.waitForTimeout(400);
  const noUp = !!process.env.NOUP;
  const out = [];
  for (let seed = 1; seed <= 8; seed++) {
    out.push(await p.evaluate(([seed, noUp]) => {
      let a = seed * 9301 + 49297; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
      if (noUp) { for (const C of CHAPTERS) C.goals = C.goals.filter(g => !g[0].startsWith('bld')); }
      sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {};
      startFlight = () => finishDay({ q: Math.random() < .3 ? 'perfect' : Math.random() < .85 ? 'good' : 'far', dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && Math.random() < .6 });
      S = newState(); S.company = 'Bot'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
      const log = { ch: [], up: [], bust: false, cashMin: 0 };
      for (let d = 0; d < 260; d++) {
        S.hezQ = []; S.paper = null; S.eventDue = false; S.chapterNews = null;
        unlockCheck(); assignPilots();
        const C = chap()[S.chapter || 0], need = k => C && C.goals.some(g => g[0] === k && !goalDone(g));
        if (S.lastShare && S.lastShare.cap) { const l = S.lastShare.me / S.lastShare.cap; if (l > .97) S.price += 5; else if (l < .75) S.price -= 5; S.price = clamp(S.price, 120, 260); }
        if (S.unl.bank && S.loans.length < 1 && S.day >= 6 && S.balloons.length < 4) { S.cash += 10000; S.loans.push({ amt: 10000, inst: 300, left: 40 }); }
        if (!S.winter) { if (S.cash > 50000 && S.balloons.length < 14) { S.cash -= 35000; addBalloon('M'); } else if (S.cash > 24000 && S.balloons.length < 3) { S.cash -= 15000; addBalloon('S'); } }
        while (S.balloons.some(x => canFly(x) === 'nopilot') && S.candidates.length) { const c = S.candidates.sort((x, y) => x.wage - y.wage)[0]; S.pilots.push(c); S.candidates = S.candidates.filter(x => x !== c); assignPilots(); }
        for (const x of S.balloons) if (cond(x) <= 0 && S.cash > SIZES[x.size].cost * RENEW + 3000) { S.cash -= SIZES[x.size].cost * RENEW; x.flights = 0; }
        if (S.unl.market) {
          for (const H of HOTELS) if (S.hotels.length < 2 && !S.hotels.includes(H.id) && !owns(H) && starVal(S.rep) >= H.min && S.cash > H.fee * 3 + 4000 && !(S.hotelTaken[H.id] && S.hotelTaken[H.id].until > S.day)) { S.cash -= H.fee * 3; S.hotels.push(H.id); }
          if (S.guideCd <= S.day && S.cash > 5500) { S.cash -= GUIDE_COST; S.rep = Math.min(1.4, S.rep + .05); S.guideCd = S.day + 5; S.guideUntil = S.day + 3; S.guideCount = (S.guideCount || 0) + 1; S.lastGuide = S.day; }
          if (need('influ') && S.influCd <= S.day && S.cash > influCost() + 5000) { S.cash -= influCost(); S.rep += .1; S.influUntil = S.day + 3; S.influCd = S.day + 10; S.influCount = (S.influCount || 0) + 1; }
          if (need('hotelOwn')) { const H = HOTELS.find(h => !owns(h) && starVal(S.rep) >= h.min && S.cash > h.buy + 20000); if (H) { S.cash -= H.buy; S.ownHotels.push(H.id); S.hotels = S.hotels.filter(i => i !== H.id); } }
        }
        if (need('workshop') && S.cash > WORKSHOP_COST + 20000) { S.cash -= WORKSHOP_COST; S.workshop = { day: S.day }; }
        if (need('school') && S.cash > SCHOOL_COST + 20000) { S.cash -= SCHOOL_COST; S.school = true; }
        if (need('xl') && S.cash > 170000) { S.cash -= 150000; addBalloon('XL'); }
        if (!noUp) {
          const up = (k, buf) => { const L = UPGRADES[k].lv[bl(k)]; if (L && S.cash > L.cost + buf) { S.cash -= L.cost; S.bld = Object.assign({}, S.bld, { [k]: bl(k) + 1 }); log.up.push(k + bl(k) + '@' + S.day); } };
          if (need('bldMast')) up('mast', 5000);
          if (need('bldHangar')) up('hangar', 10000);
          if (need('bldTop')) up('mast', 10000);
        }
        S.selfFly = true; assignPilots();
        const red = S.weather.flag === 'red';
        const was = S.chapter || 0;
        launch(red);
        if ((S.chapter || 0) > was) log.ch.push(S.day - 1);
        log.cashMin = Math.min(log.cashMin, S.cash);
        if (S.over || !S.balloons.length) { log.bust = true; break; }
        S.weather = S.weather || newWeather(); startDay && 0;
        if (!S.rivals[0].fly) rivalFlyPlan();
      }
      return { seed, ch: log.ch.join(','), up: log.up.join(' '), end: Math.round(S.cash), n: S.balloons.length, st: starVal(S.rep).toFixed(1), bust: log.bust };
    }, [seed, noUp]));
    await p.reload(); await p.waitForTimeout(300);
  }
  console.log(noUp ? 'WITHOUT upgrade goals' : 'WITH upgrade goals'); out.forEach(o => console.log(JSON.stringify(o)));
  await b.close();
})();
