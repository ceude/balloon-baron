// Usage: NODE_PATH=$(npm root -g) node tools/sim-show.js   (the Balloon Show balance behind docs/GAME_DESIGN.md "Balon Şöleni")
// A careful growing bot plays DAYS days in Cappadocia without shows, then with shows at several prices, waits and
// tourist effects (VARIANTS="per:cd:pax,..."). It books a show whenever it can and has three times the cost in cash.
// Reports the show's direct return (tickets sold to show tourists / what the shows cost) and the end net worth.
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 390, height: 800 } });
  const SEEDS = +(process.env.SEEDS || 10), DAYS = +(process.env.DAYS || 300), MAXN = +(process.env.MAXN || 40);
  const VARIANTS = (process.env.VARIANTS || 'off,500:15:1.5,1000:15:1.5,1500:15:1.5,2000:15:1.5,1000:10:1.5,1000:20:1.5,1000:15:1,1000:15:2').split(',');
  const out = [];
  for (const v of VARIANTS) for (let seed = 1; seed <= SEEDS; seed++) {
    await p.goto('file://' + (process.env.PROTO || '/home/user/balloon-baron/prototype/balloon-baron.html')); await p.waitForTimeout(200);
    out.push(await p.evaluate(([seed, v, DAYS, MAXN]) => {
      let a = seed * 9301 + 49297; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
      sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {};
      startFlight = () => finishDay({ q: Math.random() < .3 ? 'perfect' : Math.random() < .85 ? 'good' : 'far', dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && Math.random() < .6 });
      const on = v !== 'off'; if (on) { const [per, cd, pax] = v.split(':').map(Number); Object.assign(SHOW, { per, cd, pax }); }
      const L = { shows: 0, cost: 0, rev: 0, repGain: 0, firstDay: 0, nAvg: 0 };
      S = newState(); S.company = 'Bot'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
      const fin = finishDay; finishDay = fl => { if (S.plan) { const sp = (S.plan.parts || []).find(x => x.label === 'Balon şöleni'); } return fin(fl); };
      for (let d = 0; d < DAYS; d++) {
        S.hezQ = []; S.paper = null; S.eventDue = false; S.chapterNews = null; unlockCheck(); assignPilots();
        if (S.lastShare && S.lastShare.cap) { const l = S.lastShare.me / S.lastShare.cap; if (l > .97) S.price += 5; else if (l < .75) S.price -= 5; S.price = clamp(S.price, 120, 260); }
        if (!S.winter && S.cash > 50000 && S.balloons.length < MAXN) { S.cash -= 35000; addBalloon('M'); }
        if (!S.winter && S.cash > 24000 && S.balloons.length < 3) { S.cash -= 15000; addBalloon('S'); }
        while (S.balloons.some(x => canFly(x) === 'nopilot') && S.candidates.length) { const c = S.candidates.sort((x, y) => x.wage - y.wage)[0]; S.pilots.push(c); S.candidates = S.candidates.filter(x => x !== c); assignPilots(); }
        for (const x of S.balloons) if (cond(x) <= .05 && S.cash > SIZES[x.size].cost * RENEW + 3000) { S.cash -= SIZES[x.size].cost * RENEW; x.flights = 0; }
        if (S.unl.market) {
          for (const H of HOTELS) if (S.hotels.length < 3 && !S.hotels.includes(H.id) && !owns(H) && starVal(S.rep) >= H.min && S.cash > H.fee * 3 + 4000 && !(S.hotelTaken[H.id] && S.hotelTaken[H.id].until > S.day)) { S.cash -= H.fee * 3; S.hotels.push(H.id); }
          if (S.guideCd <= S.day && S.cash > 8000) { S.cash -= GUIDE_COST; S.rep = Math.min(1.4, S.rep + .05); S.guideCd = S.day + 5; S.guideUntil = S.day + 3; S.guideCount = (S.guideCount || 0) + 1; S.lastGuide = S.day; }
          if (on && showState() === 'ok' && S.cash >= showCost() * 3 && !S.winter) { L.cost += showCost(); L.shows++; L.nAvg += showFleet().length; if (!L.firstDay) L.firstDay = S.day; const r0 = S.rep; bookShow(); }
        }
        S.selfFly = true; assignPilots();
        // tickets sold to show tourists today
        const fl = flying(), cap = fl.reduce((x, y) => x + sellSeats(y), 0), m = market(S.price, cap), sp = m.parts.find(x => x.label === 'Balon şöleni');
        if (sp && S.weather.flag !== 'red') L.rev += sp.n * S.price;
        launch(S.weather.flag === 'red');
        if (S.over || !S.balloons.length) break;
        if (!S.weather) S.weather = newWeather();
        if (!S.rivals[0].fly) rivalFlyPlan();
      }
      const worth = S.cash + S.balloons.reduce((x, y) => x + SIZES[y.size].cost * .6, 0) - S.loans.reduce((x, l) => x + l.inst * l.left, 0);
      return { v, seed, shows: L.shows, cost: L.cost, rev: Math.round(L.rev), first: L.firstDay, n: L.shows ? Math.round(L.nAvg / L.shows) : 0, worth: Math.round(worth), stars: +starVal(S.rep).toFixed(2), fleet: S.balloons.length };
    }, [seed, v, DAYS, MAXN]));
  }
  const avg = xs => xs.reduce((x, y) => x + y, 0) / Math.max(1, xs.length);
  const base = avg(out.filter(o => o.v === 'off').map(o => o.worth));
  for (const v of VARIANTS) {
    const R = out.filter(o => o.v === v);
    const cost = avg(R.map(o => o.cost)), rev = avg(R.map(o => o.rev)), worth = avg(R.map(o => o.worth));
    console.log(`${v.padEnd(13)} shows ${avg(R.map(o => o.shows)).toFixed(1)} (first day ${Math.round(avg(R.filter(o => o.first).map(o => o.first)))}, balloons ${Math.round(avg(R.filter(o => o.n).map(o => o.n)))})  cost ${Math.round(cost)}  show tickets ${Math.round(rev)}  direct ROI ${cost ? (rev / cost).toFixed(2) : '-'}  net worth ${Math.round(worth)} (${worth >= base ? '+' : ''}${Math.round(worth - base)} vs off)  stars ${avg(R.map(o => o.stars)).toFixed(2)}  fleet ${avg(R.map(o => o.fleet)).toFixed(1)}`);
  }
  await b.close();
})();
