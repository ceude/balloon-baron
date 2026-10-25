// Usage: NODE_PATH=$(npm root -g) node tools/sim-economy.js   (the whole-game loan check behind docs/GAME_DESIGN.md "Krediler")
// Four bots play 400 days in Cappadocia with the same luck: one never borrows, one borrows with care (no purchase loan
// in winter, installment under a third of the daily net), one borrows every loan the bank allows the day it can and spends it on balloons at once (reckless), and the
// same without the v109 loans (reckOld: no 100,000 loan, no purchase loan) to see what the new loans add.
// Do loans make the game trivial, or ruin careless players?
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 390, height: 800 } });
  const SEEDS = +(process.env.SEEDS || 12), DAYS = 400, out = [];
  for (const style of (process.env.STYLES || 'none,smart,reckOld,reckless,flipper').split(',')) for (let seed = 1; seed <= SEEDS; seed++) {
    await p.goto('file:///home/user/balloon-baron/prototype/balloon-baron.html'); await p.waitForTimeout(300);
    if (process.env.EXTRA) await p.evaluate(process.env.EXTRA);
    out.push(await p.evaluate(([seed, style, DAYS]) => {
      let a = seed * 9301 + 49297; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
      sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {};
      startFlight = () => finishDay({ q: Math.random() < .3 ? 'perfect' : Math.random() < .85 ? 'good' : 'far', dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && Math.random() < .6 });
      const L = { seizeDays: [], seized: 0, fines: 0, ch: [], buys: [], loans: [], cashMin: 0, bust: false, maxN: 0 };
      const pa = paperAdd; paperAdd = (pr, hd, sub) => { if (/^Banka .*el koydu/.test(hd) && hd.includes(S.company)) { L.seized++; L.seizeDays.push(S.day + (S.loans.some(l => l.buy) ? 'b' : S.loans.length ? 'l' : '') + (L.lastFine === S.day ? 'f' : '')); } if (/iflas etti/.test(hd)) { L.busts = (L.busts || 0) + 1; if (S.day > 150) L.lateBusts = (L.lateBusts || 0) + 1; } if (/tekel/.test(hd)) { L.fines++; L.lastFine = S.day; } return pa(pr, hd, sub); };
      S = newState(); S.company = 'Bot'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
      const net = () => { const h = (S.netHist || []).slice(-14).sort((x, y) => x - y); return h.length >= 7 ? h[h.length >> 1] : 0; };
      const take = (o, why) => { S.cash += o.amt; S.loans.push({ amt: o.amt, inst: o.inst, left: o.days }); L.loans.push(`${o.amt / 1000}k@${S.day}${why || ''}`); };
      for (let d = 0; d < DAYS; d++) {
        S.hezQ = []; S.paper = null; S.eventDue = false; S.chapterNews = null; unlockCheck(); assignPilots();
        const C = chap()[S.chapter || 0], need = k => C && C.goals.some(g => g[0] === k && !goalDone(g));
        if (S.lastShare && S.lastShare.cap) { const l = S.lastShare.me / S.lastShare.cap; if (l > .97) S.price += 5; else if (l < .75) S.price -= 5; S.price = clamp(S.price, 120, 260); }
        // bank loans
        if (style !== 'none' && S.unl.bank && S.loans.length < 2) {
          const open = LOANS.filter(o => S.balloons.length >= o.need && (!o.net || (style !== 'reckOld' && (S.loanOpen || {})[o.amt])));
          const big = open[open.length - 1];
          if (style.startsWith('reck') && big) take(big);
          else if (style === 'smart' && big && !S.winter && !S.loans.length && S.cash < 40000 && big.inst < net() / 3) take(big);
        }
        // growth: balloons when there's cash (the reckless bot spends loan money at once, even in winter)
        if (style.startsWith('reck')) { while (S.cash > 40000 && S.balloons.length < 40) { S.cash -= 35000; addBalloon('M'); } while (S.cash > 20000 && S.balloons.length < 6) { S.cash -= 15000; addBalloon('S'); } }
        else { if (!S.winter && S.cash > 50000 && S.balloons.length < 40) { S.cash -= 35000; addBalloon('M'); } if (!S.winter && S.cash > 24000 && S.balloons.length < 3) { S.cash -= 15000; addBalloon('S'); } }
        while (S.balloons.some(x => canFly(x) === 'nopilot') && S.candidates.length) { const c = S.candidates.sort((x, y) => x.wage - y.wage)[0]; S.pilots.push(c); S.candidates = S.candidates.filter(x => x !== c); assignPilots(); }
        for (const x of S.balloons) if (cond(x) <= .05 && S.cash > SIZES[x.size].cost * RENEW + 3000) { S.cash -= SIZES[x.size].cost * RENEW; x.flights = 0; }
        if (S.unl.market) {
          for (const H of HOTELS) if (S.hotels.length < 3 && !S.hotels.includes(H.id) && !owns(H) && starVal(S.rep) >= H.min && S.cash > H.fee * 3 + 4000 && !(S.hotelTaken[H.id] && S.hotelTaken[H.id].until > S.day)) { S.cash -= H.fee * 3; S.hotels.push(H.id); }
          if (S.guideCd <= S.day && S.cash > 8000) { S.cash -= GUIDE_COST; S.rep = Math.min(1.4, S.rep + .05); S.guideCd = S.day + 5; S.guideUntil = S.day + 3; S.guideCount = (S.guideCount || 0) + 1; S.lastGuide = S.day; }
          if (need('influ') && S.influCd <= S.day && S.cash > influCost() + 5000) { S.cash -= influCost(); S.rep += .1; S.influUntil = S.day + 3; S.influCd = S.day + 10; S.influCount = (S.influCount || 0) + 1; }
          if (need('hotelOwn')) { const H = HOTELS.find(h => !owns(h) && starVal(S.rep) >= h.min && S.cash > h.buy + 20000); if (H) { S.cash -= H.buy; S.ownHotels.push(H.id); S.hotels = S.hotels.filter(i => i !== H.id); } }
        }
        if (need('workshop') && S.cash > WORKSHOP_COST + 20000) { S.cash -= WORKSHOP_COST; S.workshop = { day: S.day }; }
        if (need('school') && S.cash > SCHOOL_COST + 20000) { S.cash -= SCHOOL_COST; S.school = true; }
        if (need('xl') && S.cash > 170000) { S.cash -= 150000; addBalloon('XL'); }
        const up = (k, b2) => { const U = UPGRADES[k].lv[bl(k)]; if (U && S.cash > U.cost + b2) { S.cash -= U.cost; S.bld = Object.assign({}, S.bld, { [k]: bl(k) + 1 }); } };
        if (need('bldMast')) up('mast', 5000); if (need('bldHangar')) up('hangar', 10000); if (need('bldTop')) up('mast', 10000);
        // rivals for sale: cash if it's there, else the purchase loan
        for (const r of S.rivals) {
          const sale = !!r.forSale, price = sale ? r.forSale.price : (r.alive && r.offer) || 0;
          if (!price || (S.balloons.length >= 30 && style !== 'flipper')) continue; // a sane player stops buying rivals before the competition fines bite
          let how = null;
          if (S.cash >= price + 20000) how = 'cash';
          else if (style !== 'none' && style !== 'reckOld' && style !== 'flipper') { const T = buyLoanTerms(price); if (T && (style === 'reckless' || (!S.winter && T.inst < net() / 3))) { how = 'loan'; S.loans.push({ amt: T.fin, inst: T.inst, left: T.days, buy: 1 }); S.cash += T.fin; L.loans.push(`buy${Math.round(T.fin / 1000)}k@${S.day}`); } }
          if (style === 'flipper' && !sale) continue;
          if (style === 'flipper' && !how) { const T = buyLoanTerms(price); if (T) { how = 'loan'; S.loans.push({ amt: T.fin, inst: T.inst, left: T.days, buy: 1 }); S.cash += T.fin; L.loans.push(`buy${Math.round(T.fin / 1000)}k@${S.day}`); } }
          if (!how) continue;
          if (style === 'flipper') { const v = r.forSale.sizes.reduce((x, z) => x + SIZES[z].cost * (typeof sellValue === 'function' ? .4 : .6), 0); S.cash += v - price; L.flip = (L.flip || 0) + v - price; L.buys.push(`flip+${Math.round((v - price) / 1000)}k@${S.day}`); r.forSale = null; continue; }
          L.buys.push(`${how}${Math.round(price / 1000)}k@${S.day}`);
          if (sale) { S.cash -= r.forSale.price; r.forSale.sizes.forEach(addBalloon); r.forSale = null; } else { S.cash -= r.offer; r.balloons.forEach(addBalloon); r.alive = false; r.deadDay = S.day; r.forSale = null; r.offer = null; }
          assignPilots();
        }
        S.selfFly = true; assignPilots();
        const was = S.chapter || 0;
        launch(S.weather.flag === 'red');
        if ((S.chapter || 0) > was) L.ch.push(S.day - 1);
        L.alive = (L.alive || 0) + S.rivals.filter(r => r.alive).length; L.rivSeats = (L.rivSeats || 0) + S.rivals.filter(r => r.alive).reduce((x, r) => x + r.balloons.length, 0); L.cashMin = Math.min(L.cashMin, S.cash); L.maxN = Math.max(L.maxN, S.balloons.length);
        if (S.over || !S.balloons.length) { L.bust = true; break; }
        if (!S.weather) S.weather = newWeather();
        if (!S.rivals[0].fly) rivalFlyPlan();
      }
      return { style, seed, ch: L.ch.join(','), baron: (S.barons || {}).cap || null, bust: L.bust, seized: L.seized, seizeDays: L.seizeDays.join(' '), fines: L.fines, cashMin: Math.round(L.cashMin), end: Math.round(S.cash), n: S.balloons.length, maxN: L.maxN, rivals: S.rivals.filter(r => r.alive).length, busts: L.busts || 0, aliveAvg: +(L.alive / DAYS).toFixed(2), rivBalloons: Math.round(L.rivSeats / DAYS), lateBusts: L.lateBusts || 0, flip: Math.round(L.flip || 0), buys: L.buys.join(' '), loans: L.loans.join(' ') };
    }, [seed, style, DAYS]));
  }
  out.forEach(o => console.log(JSON.stringify(o)));
  const avg = (xs) => xs.length ? Math.round(xs.reduce((x, y) => x + y, 0) / xs.length) : '-';
  for (const st of [...new Set(out.map(o => o.style))]) {
    const R = out.filter(o => o.style === st), ch = i => avg(R.map(o => +(o.ch.split(',')[i])).filter(x => x > 0));
    console.log(`${st.padEnd(9)} bust ${R.filter(o => o.bust).length}/${R.length}  seized-runs ${R.filter(o => o.seized).length} (balloons ${R.reduce((x, o) => x + o.seized, 0)})  chapters avg day ${[0, 1, 2, 3, 4].map(ch).join('/')}  baron ${R.filter(o => o.baron).length} avg ${avg(R.filter(o => o.baron).map(o => o.baron))}  end cash ${avg(R.map(o => o.end))}  fleet ${avg(R.map(o => o.n))}  rivals alive ${(R.reduce((x, o) => x + o.aliveAvg, 0) / R.length).toFixed(2)} (balloons ${avg(R.map(o => o.rivBalloons))})  fines ${R.reduce((x, o) => x + o.fines, 0)}  rival busts ${avg(R.map(o => o.busts))} (after day 150: ${avg(R.map(o => o.lateBusts))})`);
  }
  await b.close();
})();
