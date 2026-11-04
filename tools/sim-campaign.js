// Usage: NODE_PATH=$(npm root -g) node tools/sim-campaign.js [seeds=6] [maxDays=1400] [firstSeed=1] [postDays=0]
// v137: the bot buys all six offices and all four R&D levels (the new holding goals); prints the average day each
// holding goal is met. With postDays > 0 it plays on after World Baron, buys the v137 sinks (the documentary, the
// records) when the holding can, and prints the holding's cash every 50 days.
// v141: the Maasai Mara after Bristol (the hardest region; a Mara flight lands among a herd now and then: the rangers'
// fine), offices only where their region is owned (Dubai with the Mara, so World Baron needs the Mara entered).
// v123: a bot plays the whole game: Cappadocia, then Albuquerque and Luxor (Grand Tour owned), then the holding goals
// (World Baron). v126: Cappadocia's charter offers (taken like the others; a late plane: seats kept when it makes the morning with ≥50%). v124: Bristol after Luxor (Night Glow booked when a chapter wants it), and the World Games show at the end. Prints per seed: chapter end days per region, entry days, baron days, holding cash at each baron.
const { chromium } = require('playwright');
const SEEDS = +(process.argv[2] || 6), DAYS = +(process.argv[3] || 1400), FROM = +(process.argv[4] || 1), POST = +(process.argv[5] || 0);
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 390, height: 800 } });
  p.on('pageerror', e => console.error('ERR', e.message));
  await p.goto('file://' + require('path').resolve(__dirname, '../prototype/balloon-baron.html')); await p.waitForTimeout(600);
  /* v141.1: MARAFX='{"rains":.6}' overrides the Mara's numbers for a tuning run */
  if (process.env.MARAFX) await p.evaluate(o => Object.assign(MARA_FX, o), JSON.parse(process.env.MARAFX));
  const res = [];
  for (let seed = FROM; seed < FROM + SEEDS; seed++) {
    res.push(await p.evaluate(([seed, DAYS, POST]) => {
      let a = seed * 9301 + 49297; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
      sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {}; buildWorld = () => {}; nextPopup = () => {}; showTravel = () => {}; applyRegionTheme = () => {};
      const realStart = startDay; startDay = () => {};
      startFlight = () => { const mara = S.region === 'mara', q = mara && Math.random() < .02 ? 'crash' : Math.random() < .3 ? 'perfect' : Math.random() < .85 ? 'good' : 'far'; finishDay({ q, dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && Math.random() < .6, herd: mara && q !== 'crash' && Math.random() < .08 ? 'gnu' : null, river: mara && q === 'crash' }); }; /* v141: in the Mara 8% of own flights come down among a herd, 2% in the river */
      S = newState(); S.company = 'Bot'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
      S.iap = { worldTour: 1 }; /* the player bought the Grand Tour */
      const L = { ch: { cap: [], abq: [], lux: [], bri: [], mara: [] }, bank: {}, enter: { cap: 1 }, baron: {}, world: 0, hold: [], err: null, stuck: null, goals: {}, post: [] };
      let postEnd = 0;
      const NEXT = typeof MARA_FX !== 'undefined' ? { cap: 'abq', abq: 'lux', lux: 'bri', bri: 'mara' } : { cap: 'abq', abq: 'lux', lux: 'bri' };
      const HQ_ORDER = typeof OFFICE_RATE6 !== 'undefined' ? ['ist', 'nyc', 'tyo', 'sel', 'dxb', 'par'] : ['ist', 'nyc', 'tyo', 'sel'];
      for (let d = 0; d < DAYS; d++) {
        for (const k of S.hezQ) if (!/^(news|boss|hz|ctr|insp|guide):/.test(k)) S.tips[k] = 1; /* v126: the player read yesterday's cards (a tip shows once) */
        if (S.day >= (S.nextEvent || 12)) S.nextEvent = S.day + 7 + Math.round(Math.random()); /* v126: startDay's morning-event cadence (startDay is stubbed); Cappadocia's charter offers wait for a morning without one */
        S.hezQ = []; S.paper = null; S.eventDue = false; S.chapterNews = null; S.poach = null; S.mergeNews = null;
        if (S.issue) S.issue = null; for (const id in (S.regions || {})) { const A = S.regions[id].auto; if (A && A.issue) { A.issue = null; } }
        if (typeof expireSeasons === 'function') expireSeasons();
        if (!S.weather) S.weather = newWeather(); if (!S.demand) S.demand = dayDemand(); if (!S.rivals[0].fly) rivalFlyPlan();
        if (!S.candidates.length) newCandidates();
        unlockCheck(); assignPilots();
        if (S.day === 3 && S.tut) S.tut.done = 1;
        if (S.region === 'cap' && S.day === 1) S.price = 140; else if (S.region === 'cap' && S.day === 2) S.price = 220; else if (S.region === 'cap' && S.day === 3) S.price = 170;
        else if (S.lastShare && S.lastShare.cap) { const l = S.lastShare.me / S.lastShare.cap; if (l > .97) S.price += 10; else if (l < .75) S.price -= 10; S.price = clamp(S.price, 100, 320); }
        const baron = isBaron();
        /* move on: once baron here, send the money to the holding and enter the next region */
        if (baron && NEXT[S.region] && !ownsRegion(NEXT[S.region])) {
          withdraw(1);
          if ((S.holding || 0) >= entryFee(NEXT[S.region])) { const nx = NEXT[S.region]; enterRegion(nx); S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan(); L.enter[nx] = S.day; continue; }
        }
        /* after Luxor: the holding goals */
        if (isBaron('lux')) {
          if (isBaron() && S.cash > 30000) withdraw(1); /* not from Bristol while it is still growing */
          const H = S.hold || (S.hold = { log: [] }), buy = (c, f) => { if ((S.holding || 0) >= c) { S.holding -= c; f(); return true; } return false; };
          for (const k of HQ_ORDER) if (!hasOffice(k) && (typeof officeOpenable !== 'function' || officeOpenable(k)) && buy(HQ_CITIES[k].cost, () => { H.offices = Object.assign({}, H.offices, { [k]: S.day }); })) L.hold.push(k + '@' + S.day);
          if ((H.rnd || 0) < RD_LEVELS.length && buy(RD_LEVELS[H.rnd || 0].cost, () => { H.rnd = (H.rnd || 0) + 1; })) L.hold.push('rnd@' + S.day);
          if (!(H.tvN) && buy(tvCost(), () => { H.tvN = 1; (H.tv = H.tv || {})[S.region] = { until: S.day + 14, cd: S.day + 30 }; })) L.hold.push('tv@' + S.day); /* v136: TV for the region you're in */
          if (!H.celeb && buy(celebCost(), () => { H.celeb = { name: 'X', until: S.day + 90 }; })) L.hold.push('celeb@' + S.day);
          if (isBaron('bri') && !H.wg && buy(WGAMES.cost, () => { H.wg = { until: S.day + WGAMES.days }; })) L.hold.push('wg@' + S.day);
          /* v137: after World Baron, the new sinks: a documentary season whenever one can be made, then the records */
          if (H.worldBaron && typeof DOC !== 'undefined') {
            if (!docOn() && !(H.doc && H.doc.next > S.day) && buy(docCost(), () => { H.doc = { until: S.day + DOC.days, next: S.day + DOC.days + DOC.gap, n: ((H.doc && H.doc.n) || 0) + 1 }; repAll(DOC.rep); })) L.hold.push('doc@' + S.day);
            for (const k of ['alt', 'world', 'pacific']) { const R = RECORDS[k]; if (!H.rec && !(H.records && H.records[k]) && !(R.after && !(H.records && H.records[R.after])) && buy(recCost(k), () => { H.rec = { k, done: S.day + R.days }; })) L.hold.push(k + '@' + S.day); }
          }
        }
        /* v125: a contract offer: take it when it fits 85% of the fleet's seats (and, in Bristol, the fog forecast averages 45% or less); nothing brought along on entering */
        if (typeof ctrState === 'function' && ctrCfg() && ctrState().offer) { const O = ctrState().offer, fog = O.fogP ? O.fogP.reduce((x, y) => x + y, 0) / O.fogP.length : 0; if (O.n <= fleetSeats() * .85 && fog <= .45) ctrAccept(); else ctrDecline(); } S.xfer = null;
        const C0 = chap()[S.chapter || 0], need = k => C0 && C0.goals.some(g => g[0] === k && !goalDone(g));
        const saving = C0 && !need('balloons') && C0.goals.some(g => !goalDone(g) && ['fabBuilt', 'workshop', 'xl', 'school', 'hotelOwn', 'bldTop', 'bldHangar', 'bldMast'].includes(g[0])) && S.cash < 250000;
        if (S.unl.bank && S.loans.length < 1 && S.balloons.length < 4 && S.cash < 15000 && (S.day >= 6 || S.region !== 'cap')) { S.cash += 10000; S.loans.push({ amt: 10000, inst: 300, left: 40 }); }
        /* v127: the hangar holds hangarCap() balloons; a full hangar is grown (with the same cash cushion) before the next balloon */
        const hasRoom = () => typeof hangarCap !== 'function' || S.balloons.length < hangarCap();
        const growHangar = buf => { const Lv = UPGRADES.hangar.lv[bl('hangar')]; if (Lv && S.cash > Lv.cost + buf) { S.cash -= Lv.cost; S.bld = Object.assign({}, S.bld, { hangar: bl('hangar') + 1 }); } };
        const buyB = (z, buf) => { if (hasRoom()) { S.cash -= SIZES[z].cost; addBalloon(z); } else growHangar(buf); };
        if (S.unl.fleet && !S.winter && !saving && !baron) {
          if (S.balloons.length < 3 && S.cash >= SIZES.S.cost + 1500) buyB('S', 1500);
          else if (S.balloons.length >= 3 && S.balloons.length < 14 && S.cash > SIZES.M.cost + 15000) buyB('M', 15000);
          else if (S.balloons.length >= 14 && S.balloons.length < 45 && S.cash > SIZES.L.cost + 30000) buyB('L', 30000);
          assignPilots();
        }
        if (S.unl.crew) while (S.balloons.some(x => canFly(x) === 'nopilot') && S.candidates.length) { const c = S.candidates.sort((x, y) => x.lvl - y.lvl)[0]; S.pilots.push(c); S.candidates = S.candidates.filter(x => x !== c); assignPilots(); }
        for (const x of S.balloons) if (cond(x) <= 0 && S.cash > SIZES[x.size].cost * RENEW + 3000) { S.cash -= SIZES[x.size].cost * RENEW; x.flights = 0; }
        if (S.unl.market) for (const Hh of HOTELS) if (S.hotels.length < 2 && !S.hotels.includes(Hh.id) && !owns(Hh) && starVal(S.rep) >= Hh.min && S.cash > Hh.fee * 3 + 4000 && !(S.hotelTaken[Hh.id] && S.hotelTaken[Hh.id].until > S.day)) { S.cash -= Hh.fee * 3; S.hotels.push(Hh.id); }
        if ((S.unl.guide || S.unl.market) && S.guideCd <= S.day && S.cash > 6000) doGuide();
        if (need('glow') && typeof glowState === 'function' && glowState() === 'ok') bookGlow();
        if ((S.unl.agency || S.unl.market) && (need('influ') || need('stars')) && S.influCd <= S.day && S.cash > influCost() * 2 + 5000) doInfluencer();
        if (need('hotelOwn')) { const Hh = HOTELS.find(h => !owns(h) && starVal(S.rep) >= h.min && S.cash > h.buy + 20000); if (Hh) { S.cash -= Hh.buy; S.ownHotels.push(Hh.id); S.hotels = S.hotels.filter(i => i !== Hh.id); } }
        if ((need('workshop') || need('fabBuilt')) && !S.workshop && S.cash > WORKSHOP_COST + 20000) { S.cash -= WORKSHOP_COST; S.workshop = { day: S.day, lv: 1 }; }
        if (need('fabBuilt') && S.workshop) { if (fabLv() < 2) fabUpgrade(); else fabBuild('S'); }
        if (need('school') && S.cash > SCHOOL_COST + 20000) { S.cash -= SCHOOL_COST; S.school = true; }
        if (need('xl') && S.cash > 170000) { if (hasRoom()) { S.cash -= 150000; addBalloon('XL'); assignPilots(); } else growHangar(170000); }
        const up = (k, buf) => { const Lv = UPGRADES[k].lv[bl(k)]; if (Lv && S.cash > Lv.cost + buf) { S.cash -= Lv.cost; S.bld = Object.assign({}, S.bld, { [k]: bl(k) + 1 }); } };
        if (need('bldMast')) up('mast', 5000); if (need('bldHangar')) up('hangar', 10000); if (need('bldTop')) up('mast', 10000);
        const reg = S.region, ch0 = S.chapter || 0, day = S.day;
        /* v126: a charter plane is late: keep the seats when it is at least as likely as not to make the morning, otherwise sell them */
        if (typeof ctrDelayJob === 'function' && ctrDelayJob()) ctrDelayChoose(ctrDelayJob().dl.q >= .5 ? 'hold' : 'open');
        try { launch(S.weather.flag === 'red'); } catch (e) { L.err = e.message + ' @' + day; break; }
        if ((S.chapter || 0) > ch0 && S.region === reg) L.ch[reg].push(day);
        for (const id of ['cap', 'abq', 'lux', 'bri', 'mara']) if (S.barons && S.barons[id] && !L.baron[id]) { L.baron[id] = S.barons[id]; L['hold_' + id] = Math.round(S.holding || 0); L['cash_' + id] = Math.round(S.cash); L['auto_' + id] = Object.keys(S.regions || {}).map(k => k + ':' + Math.round((S.regions[k].auto || {}).base || 0)).join(' '); }
        if (typeof HOLD_GOALS !== 'undefined') HOLD_GOALS.forEach(g => { if (L.goals[g[0]] == null && g[1]()) L.goals[g[0]] = S.day; });
        if (S.hold && S.hold.worldBaron && !L.world) { L.world = S.hold.worldBaron; postEnd = S.day + POST; }
        if (L.world && S.day % 50 === 0) L.post.push([S.day, Math.round(S.holding || 0), Math.round((S.hold.today || {}).gross || 0)]);
        if (L.world && S.day >= postEnd && (typeof MARA_FX === 'undefined' || isBaron('mara'))) break; /* v141: play on to the Mara's baron */
        if (S.over) { L.err = 'bankrupt @' + day; break; }
        if (S.loans.some(l => l.amt >= 10000) && !L.bank[S.region]) L.bank[S.region] = day; /* v141: the first bank loan per region */
        if (S.region === 'mara') { L.maraMin = Math.min(L.maraMin == null ? 1e9 : L.maraMin, Math.round(S.cash)); if (S.cash < 0) L.maraNeg = (L.maraNeg || 0) + 1; if (S.debtDays) L.maraDebt = Math.max(L.maraDebt || 0, S.debtDays); }
      }
      if (!L.world) { const C = chap()[S.chapter || 0]; L.stuck = { day: S.day, region: S.region, ch: S.chapter, goals: C ? C.goals.map(g => g[0] + '=' + Math.round(goalVal(g[0]) * 100) / 100 + '/' + g[1]) : HOLD_GOALS.map(g => g[0] + ':' + g[1]()), holding: Math.round(S.holding || 0), cash: Math.round(S.cash) }; }
      startDay = realStart;
      return L;
    }, [seed, DAYS, POST]));
  }
  
  /* per region: days from entering to each chapter's end (the last one is the baron) */
  for (const r of res) { const per = {}; for (const id of ['cap', 'abq', 'lux', 'bri', 'mara']) per[id] = (r.ch[id] || []).map(d => d - (r.enter[id] || 1)); console.log('days in region per chapter', JSON.stringify(per), 'world', r.world); }
  const gd = {}; for (const r of res) for (const k in r.goals) (gd[k] = gd[k] || []).push(r.goals[k]);
  console.log('holding goals, average day met:'); for (const k of Object.keys(gd).sort((a, b) => gd[a].reduce((x, y) => x + y, 0) / gd[a].length - gd[b].reduce((x, y) => x + y, 0) / gd[b].length)) console.log('  ' + Math.round(gd[k].reduce((x, y) => x + y, 0) / gd[k].length), k, '(' + gd[k].length + ' seeds)');
  const w = res.filter(r => r.world).map(r => r.world); console.log('World Baron: average day', Math.round(w.reduce((x, y) => x + y, 0) / w.length), 'of', res.length, 'seeds:', w.join(' '));
  if (POST) for (const r of res) console.log('after World Baron [day, holding cash, autopilot gross]:', JSON.stringify(r.post), r.hold.filter(x => /^(doc|alt|world|pacific)@/.test(x)).join(' '));
  for (const r of res) console.log('baron days', JSON.stringify(r.baron), 'enter', JSON.stringify(r.enter), 'mara cash min', r.maraMin, 'days below 0', r.maraNeg || 0, 'debt days', r.maraDebt || 0, 'err', r.err);
  console.log(JSON.stringify(res.map(r => ({ hc: r.hold_cap, ha: r.hold_abq, hl: r.hold_lux, hb: r.hold_bri, cl: r.cash_lux, al: r.auto_lux, ch: r.ch, enter: r.enter, baron: r.baron, world: r.world, hold: r.hold, err: r.err, stuck: r.stuck }))));
  await b.close();
})();
