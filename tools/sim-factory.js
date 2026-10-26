// Usage: NODE_PATH=$(npm root -g) node tools/sim-factory.js   (the balloon factory check behind docs/GAME_DESIGN.md "Balon fabrikası")
// Bots play 400 days in Cappadocia with the same luck. "base" never upgrades the workshop (today's game); "fab" grows the
// workshop into a factory, builds its own balloons there when the line is free and takes every rival order; "noOrder" does
// the same but turns orders down. VARIANTS is a JSON list of FAB overrides to compare (upgrade costs, discount, order price).
// Does the factory pay back, how much faster is the baron, and do orders feed the rivals?
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 390, height: 800 } });
  const SEEDS = +(process.env.SEEDS || 10), DAYS = +(process.env.DAYS || 400), out = [];
  const PROTO = process.env.PROTO || '/home/user/balloon-baron/prototype/balloon-baron.html';
  const VARIANTS = JSON.parse(process.env.VARIANTS || '[{}]');
  for (const [vi, V] of VARIANTS.entries()) for (const style of (process.env.STYLES || 'base,fab,noOrder').split(',')) for (let seed = 1; seed <= SEEDS; seed++) {
    if (style === 'base' && vi > 0) continue;
    await p.goto('file://' + PROTO); await p.waitForTimeout(250);
    out.push(await p.evaluate(([seed, style, DAYS, V, vi]) => {
      let a = seed * 9301 + 49297; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
      sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {};
      if (V.lv) V.lv.forEach((c, i) => { if (c && FAB.lv[i]) FAB.lv[i].cost = c; });
      for (const k of ['disc', 'orderK', 'orderP']) if (V[k] != null) FAB[k] = V[k];
      if (V.days) Object.assign(FAB.days, V.days);
      startFlight = () => finishDay({ q: Math.random() < .3 ? 'perfect' : Math.random() < .85 ? 'good' : 'far', dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && Math.random() < .6 });
      const rb = [0, 0, 0, 0]; const rp = simRivals; simRivals = rev => { const n0 = S.rivals.reduce((x, r) => x + r.balloons.length, 0); rp(rev); const n1 = S.rivals.reduce((x, r) => x + r.balloons.length, 0); if (n1 > n0) { rb[Math.min(3, S.day / 100 | 0)] += n1 - n0; const k = [fabLv(), fabBusy(), !!(S.workshop && S.workshop.order)].join(); (L.why = L.why || {})[k] = (L.why[k] || 0) + 1; } };
      const L = { ch: [], upDays: [], spent: 0, cashMin: 0, bust: false, maxN: 0, rivB: 0, rivN: 0, own: 0 };
      S = newState(); S.company = 'Bot'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
      const fab = style !== 'base';
      for (let d = 0; d < DAYS; d++) {
        S.hezQ = []; S.paper = null; S.eventDue = false; S.chapterNews = null; unlockCheck(); assignPilots();
        const C = chap()[S.chapter || 0], need = k => C && C.goals.some(g => g[0] === k && !goalDone(g));
        if (S.lastShare && S.lastShare.cap) { const l = S.lastShare.me / S.lastShare.cap; if (l > .97) S.price += 5; else if (l < .75) S.price -= 5; S.price = clamp(S.price, 120, 260); }
        // the factory: found it once the fleet is growing, upgrade with spare cash, answer orders
        if (fab) {
          if (!S.workshop && S.balloons.length >= (V.wAt || 4) && S.cash > WORKSHOP_COST + 10000) { S.cash -= WORKSHOP_COST; S.workshop = { day: S.day }; L.upDays.push('w' + S.day); }
          const nx = S.workshop && FAB.lv[fabLv() + 1];
          if (nx && !S.winter && S.cash > nx.cost + 10000) { L.spent += nx.cost; fabUpgrade(); L.upDays.push(fabLv() + '@' + S.day); }
          if (S.workshop && S.workshop.order) { if (style !== 'noOrder') fabAccept(); else fabDecline(); }
        } else if (need('workshop') && S.cash > WORKSHOP_COST + 20000) { S.cash -= WORKSHOP_COST; S.workshop = { day: S.day }; }
        // growth, as the careful bot in sim-economy: an M when there's cash (from the factory when the line is free)
        // the factory bot saves up for the workshop (from 4 balloons) and its first two lines instead of buying balloons
        const saving = fab && S.balloons.length >= (V.wAt || 4) && !S.workshop;
        if (!saving && !S.winter && S.balloons.length < 40) {
          const own = fab && style !== 'trader', z = own && fabCan('L') ? 'L' : 'M', price = own && fabCan(z) ? fabCost(z) : SIZES[z].cost;
          if (S.cash > price + 15000 + (z === 'L' ? 10000 : 0)) {
            if (own && fabCan(z) && !fabBusy()) { fabBuild(z); L.own++; }
            else if (!(own && fabCan(z))) { S.cash -= SIZES[z].cost; addBalloon(z); }
          }
          if (S.cash > 24000 && S.balloons.length < 3) { S.cash -= 15000; addBalloon('S'); }
        }
        while (S.balloons.some(x => canFly(x) === 'nopilot') && S.candidates.length) { const c = S.candidates.sort((x, y) => x.wage - y.wage)[0]; S.pilots.push(c); S.candidates = S.candidates.filter(x => x !== c); assignPilots(); }
        for (const x of S.balloons) if (cond(x) <= .05 && S.cash > SIZES[x.size].cost * RENEW + 3000) { S.cash -= SIZES[x.size].cost * RENEW; x.flights = 0; }
        if (S.unl.market) {
          for (const H of HOTELS) if (S.hotels.length < 3 && !S.hotels.includes(H.id) && !owns(H) && starVal(S.rep) >= H.min && S.cash > H.fee * 3 + 4000 && !(S.hotelTaken[H.id] && S.hotelTaken[H.id].until > S.day)) { S.cash -= H.fee * 3; S.hotels.push(H.id); }
          if (S.guideCd <= S.day && S.cash > 8000) { S.cash -= GUIDE_COST; S.rep = Math.min(1.4, S.rep + .05); S.guideCd = S.day + 5; S.guideUntil = S.day + 3; S.guideCount = (S.guideCount || 0) + 1; S.lastGuide = S.day; }
          if (need('influ') && S.influCd <= S.day && S.cash > influCost() + 5000) { S.cash -= influCost(); S.rep += .1; S.influUntil = S.day + 3; S.influCd = S.day + 10; S.influCount = (S.influCount || 0) + 1; }
          if (need('hotelOwn')) { const H = HOTELS.find(h => !owns(h) && starVal(S.rep) >= h.min && S.cash > h.buy + 20000); if (H) { S.cash -= H.buy; S.ownHotels.push(H.id); S.hotels = S.hotels.filter(i => i !== H.id); } }
        }
        if (need('school') && S.cash > SCHOOL_COST + 20000) { S.cash -= SCHOOL_COST; S.school = true; }
        if (need('xl') && S.cash > 170000) { S.cash -= 150000; addBalloon('XL'); }
        if (need('fab2') && S.workshop && fabLv() < 2 && S.cash > FAB.lv[2].cost + 20000) { L.spent += FAB.lv[2].cost; fabUpgrade(); L.upDays.push('g2@' + S.day); }
        if (need('fab2') && !S.workshop && S.cash > WORKSHOP_COST + 20000) { S.cash -= WORKSHOP_COST; S.workshop = { day: S.day }; }
        if (need('fabBuilt') && fabCan('S') && !fabBusy() && S.cash > fabCost('S') + 10000) { fabBuild('S'); L.own++; }
        const up = (k, b2) => { const U = UPGRADES[k].lv[bl(k)]; if (U && S.cash > U.cost + b2) { S.cash -= U.cost; S.bld = Object.assign({}, S.bld, { [k]: bl(k) + 1 }); } };
        if (need('bldMast')) up('mast', 5000); if (need('bldHangar')) up('hangar', 10000); if (need('bldTop')) up('mast', 10000);
        S.selfFly = true; assignPilots();
        const was = S.chapter || 0;
        launch(S.weather.flag === 'red');
        if ((S.chapter || 0) > was) L.ch.push(S.day - 1);
        { const W = S.workshop || {}; if (!L.pay && fab && W.day != null && (W.saved || 0) + (W.earned || 0) >= L.spent + WORKSHOP_COST) L.pay = S.day; }
        const al = S.rivals.filter(r => r.alive); L.rivB += al.reduce((x, r) => x + r.balloons.length, 0); L.rivN++;
        L.cashMin = Math.min(L.cashMin, S.cash); L.maxN = Math.max(L.maxN, S.balloons.length);
        if (S.over || !S.balloons.length) { L.bust = true; break; }
        if (!S.weather) S.weather = newWeather();
        if (!S.rivals[0].fly) rivalFlyPlan();
      }
      const W = S.workshop || {};
      return { vi, style, seed, ch: L.ch.join(','), baron: (S.barons || {}).cap || null, bust: L.bust, end: Math.round(S.cash), n: S.balloons.length, rivB: +(L.rivB / Math.max(1, L.rivN)).toFixed(1),
        lv: fabLv(), ups: L.upDays.join(' '), spent: L.spent, saved: W.saved || 0, earned: W.earned || 0, orders: W.orders || 0, own: L.own, why: JSON.stringify(L.why), pay: L.pay || null, rb: rb.join('/'), share: +(S.shareNow || 0).toFixed(2) };
    }, [seed, style, DAYS, V, vi]));
  }
  if (process.env.RAW) out.forEach(o => console.log(JSON.stringify(o)));
  const avg = xs => xs.length ? Math.round(xs.reduce((x, y) => x + y, 0) / xs.length) : '-';
  for (const vi of [...new Set(out.map(o => o.vi))]) for (const st of [...new Set(out.map(o => o.style))]) {
    const R = out.filter(o => o.style === st && (o.vi === vi || st === 'base')); if (!R.length || (st === 'base' && vi > 0)) continue;
    const ch = i => avg(R.map(o => +(o.ch.split(',')[i])).filter(x => x > 0));
    console.log(`v${vi} ${JSON.stringify(VARIANTS[vi])} ${st.padEnd(8)} bust ${R.filter(o => o.bust).length}/${R.length} ch ${[0, 1, 2, 3].map(ch).join('/')} baron ${R.filter(o => o.baron).length} @${avg(R.filter(o => o.baron).map(o => o.baron))} end ${avg(R.map(o => o.end / 1000))}k n ${avg(R.map(o => o.n))} rivB ${(R.reduce((x, o) => x + o.rivB, 0) / R.length).toFixed(1)} share ${(R.reduce((x, o) => x + o.share, 0) / R.length).toFixed(2)} | lv ${avg(R.map(o => o.lv))} spent ${avg(R.map(o => o.spent / 1000))}k saved ${avg(R.map(o => o.saved / 1000))}k earned ${avg(R.map(o => o.earned / 1000))}k orders ${avg(R.map(o => o.orders))} own ${avg(R.map(o => o.own))} payback ${avg(R.filter(o => o.pay).map(o => o.pay))} (${R.filter(o => o.pay).length}) rivalBuys/100d ${[0, 1, 2, 3].map(i => avg(R.map(o => +o.rb.split('/')[i]))).join('/')}`);
  }
  await b.close();
})();
