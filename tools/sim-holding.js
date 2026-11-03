// Usage: NODE_PATH=$(npm root -g) node tools/sim-holding.js [seeds=16] [postDays=400] [modes=goals,spend,prop] [firstSeed=1] [out.json]
// The holding's late-game economy: where its money comes from, where it can go, and how much piles up.
// The campaign bot of tools/sim-campaign.js plays the whole game (Cappadocia, Albuquerque, Luxor, Bristol, World Baron)
// and then `postDays` more days. Modes:
//   goals: the bot of sim-campaign.js (buys the holding goals; after World Baron a documentary season whenever it can and
//          the record ladder). The baseline.
//   spend: today's prices; the bot buys every holding item the moment it can afford it (TV and billboards in every
//          region, celebrity, jersey, documentary, records and their improvement attempts, World Games), keeping a reserve
//          for the next holding goal until World Baron. The player who tries hard to spend.
//   prop:  a proposed rebalance, implemented here only (nothing in the game changes): realistic prices, marketing boosts
//          that add up to a cap instead of multiplying, office running costs, and new late-game systems (hosted festival,
//          estates, rival buyouts, a foundation, a stratospheric capsule programme). Same spending bot as `spend`.
// Prints per mode: milestone days, holding cash and income at each, the cash curve (median, 10th and 90th percentile)
// by days after World Baron, cash measured in days of income, and where the money went. With out.json it also writes
// every seed's daily samples (for charts).
// Results (32 seeds, 400 days after World Baron), holding cash median at +400: goals €42M (300 days of income), spend €44M
// (214 days: the bot spends only 43% of its income, and stacked campaigns lift the income from €140k to €200k a day),
// prop €3.3M (23 days; 94% of income spent). World Baron day: 604 today, 630 with the proposal.
const { chromium } = require('playwright');
const SEEDS = +(process.argv[2] || 16), POST = +(process.argv[3] || 400), MODES = (process.argv[4] || 'goals,spend,prop').split(','), FROM = +(process.argv[5] || 1), OUT = process.argv[6];

/* The proposal, as page code. Everything here only exists inside this simulator. */
const PROPOSAL = `
  /* existing items, new prices and effects (the report's table) */
  TVC.cost = 120000; TVC.days = 21; TVC.cd = 45; TVC.boost = 1.15;   /* New York keeps its 25% off */
  JERSEY.cost = 10000000; JERSEY.days = 360; JERSEY.boost = 1.15; JERSEY.rep = .1;
  WGAMES.again = 360; WGAMES.step = 1.5;                               /* the first show stays €10M (a goal); every Games after it */
  DOC.cost = 3000000; DOC.days = 120; DOC.gap = 60;                    /* Paris keeps its 20% off */
  RECORDS.alt.cost = 1500000; RECORDS.pacific.cost = 4000000; RECORDS.world.cost = 8000000; /* Dubai keeps its 25% off */
  PX = {
    celeb: { cost: 1800000, days: 180, sel: .75, selDays: 180 },     /* Seoul: 25% off, no longer twice as long */
    bb: { cost: 80000, days: 30, boost: .08 },
    cap: .5,                                                         /* temporary campaigns add up, to +50% at most in a region */
    upkeep: { ist: 1000, sel: 1500, tyo: 1500, dxb: 1500, nyc: 2000, par: 2000 }, /* rent and staff, € a day */
    fest: { base: 1500000, step: 500000, max: 5000000, every: 90, days: 10, boost: .4, rep: .15, fame: .03, fameMax: .15 },
    estate: { tiers: [[1200000, 3000], [3000000, 4500], [7000000, 6500]], rep: .05 }, /* per region: price, € a day */
    buyout: { base: 2500000, step: 1.5, per: 3, gain: .15 },          /* per region, up to 3 rivals: price ×1.5 each, +15% income */
    found: { base: 1000000, step: 500000, rep: .05 },                  /* projects without end, each €500,000 bigger; +0.05 popularity everywhere */
    strato: [{ cost: 8000000, days: 60 }, { cost: 15000000, days: 90 }, { cost: 25000000, days: 120 }], stratoInc: 30000
  };
  /* temporary campaigns in a region, added up (festival and records are outside the cap) */
  pxTemp = function (id) {
    const H = S.hold || {};
    return (tvUntilR(id) > S.day ? TVC.boost - 1 : 0) + (H.celeb && H.celeb.until > S.day ? .1 : 0) + (H.jersey > S.day ? JERSEY.boost - 1 : 0)
      + (H.wg && H.wg.until > S.day ? WGAMES.boost - 1 : 0) + (H.bb && H.bb[id] > S.day ? PX.bb.boost : 0) + (H.doc && H.doc.until > S.day ? DOC.boost - 1 : 0);
  };
  holdBoost = function (id) {
    const H = S.hold; if (!H) return 1; const P = H.px || {};
    return (1 + (H.recBoost || 0)) * (1 + Math.min(PX.cap, pxTemp(id))) * (1 + ((P.fame || {})[id] || 0)) * (P.festOn && P.festOn[id] > S.day ? 1 + PX.fest.boost : 1);
  };
  holdingDay = function () {
    if (!S.hold) S.hold = { log: [] };
    const H = S.hold, P = H.px || (H.px = {});
    let gross = 0;
    for (const id in (S.regions || {})) {
      const A = S.regions[id].auto; if (!A) continue;
      gross += (A.todayRaw || 0) * holdBoost(id) * officeMult(id) * (1 + PX.buyout.gain * ((P.buy || {})[id] || 0));
    }
    /* estates earn wherever they are, parked or not (a hotel has its own manager) */
    for (const id in (P.est || {})) for (let t = 0; t < P.est[id]; t++) gross += PX.estate.tiers[t][1];
    if (P.strato >= PX.strato.length && S.day >= P.stratoBusy) gross += PX.stratoInc;
    gross = Math.round(gross);
    const upkeep = Object.keys(HQ_CITIES).filter(hasOffice).reduce((a, k) => a + PX.upkeep[k], 0);
    const cost = Math.round(gross * holdCostRate()) + upkeep;
    S.holding = (S.holding || 0) + gross - cost;
    if (gross) { holdLog('inc', gross); holdLog('exp', cost); }
    H.today = { gross, cost };
    recordDay(); adShapeDay(); markMillion();
    return gross - cost;
  };
`;

(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 390, height: 800 } });
  p.on('pageerror', e => console.error('ERR', e.message));
  const all = {};
  for (const MODE of MODES) {
    await p.goto('file://' + require('path').resolve(__dirname, '../prototype/balloon-baron.html')); await p.waitForTimeout(500);
    if (MODE.startsWith('prop')) await p.addScriptTag({ content: PROPOSAL });
    const res = [];
    for (let seed = FROM; seed < FROM + SEEDS; seed++) {
      res.push(await p.evaluate(([seed, POST, MODE]) => {
        let a = seed * 9301 + 49297; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
        sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {}; buildWorld = () => {}; nextPopup = () => {}; showTravel = () => {}; applyRegionTheme = () => {};
        const realStart = startDay; startDay = () => {};
        startFlight = () => finishDay({ q: Math.random() < .3 ? 'perfect' : Math.random() < .85 ? 'good' : 'far', dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && Math.random() < .6 });
        S = newState(); S.company = 'Bot'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
        S.iap = { worldTour: 1 };
        const PROP = MODE.startsWith('prop'), SPEND = MODE === 'spend' || MODE === 'prop';
        const L = { baron: {}, enter: { cap: 1 }, world: 0, err: null, days: [], spent: {}, buys: [], at: {} };
        let postEnd = 99999, dayIn = 0, dayAuto = 0;
        /* money into the holding from the region you play (withdrawals) is counted with the autopilot as income */
        const wd = withdraw; withdraw = s => { const h0 = S.holding || 0; wd(s); dayIn += (S.holding || 0) - h0; };
        const NEXT = { cap: 'abq', abq: 'lux', lux: 'bri' };
        const H = () => S.hold || (S.hold = { log: [] });
        const spend = (cat, c, f) => { if ((S.holding || 0) < c) return false; S.holding -= c; holdLog('exp', c); f(); L.spent[cat] = (L.spent[cat] || 0) + c; (L.dspent = L.dspent || {})[cat] = ((L.dspent || {})[cat] || 0) + c; return true; };
        const officeOrder = Object.keys(HQ_CITIES).sort((x, y) => HQ_CITIES[x].cost - HQ_CITIES[y].cost);
        const celebC = () => PROP ? Math.round(PX.celeb.cost * (hasOffice('sel') ? PX.celeb.sel : 1)) : celebCost();
        const celebD = () => PROP ? (hasOffice('sel') ? PX.celeb.selDays : PX.celeb.days) : (hasOffice('sel') ? 180 : 90);
        const bbC = () => PROP ? PX.bb.cost : 120000, bbD = () => PROP ? PX.bb.days : 20;
        /* the holding goals, in the order the campaign bot buys them */
        const goals = () => {
          const h = H(), out = [];
          for (const k of officeOrder) if (!hasOffice(k)) out.push({ k: 'office', c: HQ_CITIES[k].cost, f: () => { h.offices = Object.assign({}, h.offices, { [k]: S.day }); } });
          if ((h.rnd || 0) < RD_LEVELS.length) out.push({ k: 'rnd', c: RD_LEVELS[h.rnd || 0].cost, f: () => { h.rnd = (h.rnd || 0) + 1; } });
          if (!h.tvN) out.push({ k: 'tv', c: tvCost(), f: () => { h.tvN = 1; (h.tv = h.tv || {})[S.region] = { until: S.day + TVC.days, cd: S.day + TVC.cd }; repIn(S.region, TVC.rep); } });
          if (!h.celeb) out.push({ k: 'celeb', c: celebC(), f: () => { h.celeb = { name: 'X', until: S.day + celebD() }; repAll(.15); } });
          if (!h.wg) out.push({ k: 'wg', c: WGAMES.cost, f: () => { h.wg = { until: S.day + WGAMES.days, n: 1, at: S.day }; repAll(WGAMES.rep); } });
          return out;
        };
        /* everything else the holding can buy today, in the order the spending bot tries them */
        const extras = () => {
          const h = H(), d = S.day, out = [], P = h.px || (h.px = {}), mine = myRegionIds();
          for (const id of mine) if (tvReadyR(id) <= d) out.push({ k: 'tv', cls: 'mkt', b: TVC.boost - 1, ids: [id], c: tvCost(), f: () => { h.tvN = (h.tvN || 0) + 1; (h.tv = h.tv || {})[id] = { until: d + TVC.days, cd: d + TVC.cd }; repIn(id, TVC.rep); } });
          if (!(h.celeb && h.celeb.until > d)) out.push({ k: 'celeb', cls: 'mkt', b: .1, ids: mine, c: celebC(), f: () => { h.celeb = { name: 'X', until: d + celebD() }; repAll(.15); } });
          if (!(h.doc && h.doc.next > d)) out.push({ k: 'doc', cls: 'mkt', b: DOC.boost - 1, ids: mine, c: docCost(), f: () => { h.doc = { until: d + DOC.days, next: d + DOC.days + DOC.gap, n: ((h.doc && h.doc.n) || 0) + 1 }; repAll(DOC.rep); } });
          if (!(h.jersey > d)) out.push({ k: 'jersey', cls: 'big', b: JERSEY.boost - 1, ids: mine, c: JERSEY.cost, f: () => { h.jersey = d + JERSEY.days; repAll(JERSEY.rep); } });
          /* the record ladder first (a record not yet set), then attempts to improve one while the lasting boost is under its ceiling */
          const recs = ['alt', 'pacific', 'world'].filter(k => !(RECORDS[k].after && !(h.records && h.records[RECORDS[k].after])));
          const rk = recs.find(k => !(h.records && h.records[k])) || ((h.recBoost || 0) < recCap() - 1e-9 ? recs[0] : null);
          if (!h.rec && rk) out.push({ k: 'record', cls: 'big', c: recCost(rk), f: () => { h.rec = { k: rk, done: d + RECORDS[rk].days }; h.recV2 = 1; } });
          if (PROP && h.wg && WGAMES.again && d >= h.wg.at + WGAMES.again) out.push({ k: 'wg', cls: 'big', c: Math.round(WGAMES.cost * Math.pow(WGAMES.step, h.wg.n)), f: () => { h.wg = { until: d + WGAMES.days, n: h.wg.n + 1, at: d }; repAll(WGAMES.rep); } });
          if (PROP) {
            const F = PX.fest; if ((P.festNext || 0) <= d) { const id = mine.slice().sort((x, y) => (((P.fame || {})[x]) || 0) - (((P.fame || {})[y]) || 0))[0], n = P.festN || 0;
              out.push({ k: 'festival', cls: 'mkt', c: Math.min(F.max, F.base + F.step * n), f: () => { P.festN = n + 1; P.festNext = d + F.every; (P.festOn = P.festOn || {})[id] = d + F.days; const fm = P.fame = P.fame || {}; fm[id] = Math.min(F.fameMax, (fm[id] || 0) + F.fame); repIn(id, F.rep); } }); }
            for (const id of mine) { const t = (P.est || {})[id] || 0; if (t < PX.estate.tiers.length) out.push({ k: 'estate', cls: 'inv', c: PX.estate.tiers[t][0], f: () => { (P.est = P.est || {})[id] = t + 1; repIn(id, PX.estate.rep); } }); }
            for (const id of mine) { const n = (P.buy || {})[id] || 0; if (n < PX.buyout.per && id !== S.region) out.push({ k: 'buyout', cls: 'inv', c: Math.round(PX.buyout.base * Math.pow(PX.buyout.step, n)), f: () => { (P.buy = P.buy || {})[id] = n + 1; } }); }
            const st = P.strato || 0; if (st < PX.strato.length && !(P.stratoBusy > d)) out.push({ k: 'strato', cls: 'big', c: PX.strato[st].cost, f: () => { P.strato = st + 1; P.stratoBusy = d + PX.strato[st].days; } });
            const fn = P.found || 0; out.push({ k: 'foundation', cls: 'found', c: PX.found.base + PX.found.step * fn, f: () => { P.found = fn + 1; repAll(PX.found.rep); } });
          }
          for (const id of mine) if (!((h.bb || {})[id] > d)) out.push({ k: 'billboards', cls: 'mkt', b: PROP ? PX.bb.boost : .1, ids: [id], c: bbC(), f: () => { (h.bb = h.bb || {})[id] = d + bbD(); } });
          return out;
        };
        /* trailing income (autopilot net + withdrawals), for "cash in days of income" */
        const inc30 = [];
        for (let d = 0; d < 1400 + POST; d++) {
          for (const k of S.hezQ) if (!/^(news|boss|hz|ctr|insp|guide):/.test(k)) S.tips[k] = 1;
          if (S.day >= (S.nextEvent || 12)) S.nextEvent = S.day + 7 + Math.round(Math.random());
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
          dayIn = 0; L.dspent = {};
          if (baron && NEXT[S.region] && !ownsRegion(NEXT[S.region])) {
            withdraw(1);
            if ((S.holding || 0) >= entryFee(NEXT[S.region])) { const nx = NEXT[S.region], fee = entryFee(nx); enterRegion(nx); L.spent.entry = (L.spent.entry || 0) + fee; L.dspent.entry = fee; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan(); L.enter[nx] = S.day; continue; }
          }
          if (isBaron('lux')) {
            if (isBaron() && S.cash > 30000) withdraw(1);
            /* goals first; the spender keeps the next goal's price in reserve until World Baron */
            const G = goals(); let reserve = 0;
            /* the World Games show is the last goal and opens with the Bristol baron: a goal-minded player saves for it before */
            for (const g of G) { if (g.k === 'wg' && !isBaron('bri')) { reserve = g.c; break; } if (!spend(g.k, g.c, g.f)) { reserve = g.c; break; } }
            if (!SPEND) {
              const h = H();
              if (h.worldBaron) {
                if (!docOn() && !(h.doc && h.doc.next > S.day)) spend('doc', docCost(), () => { h.doc = { until: S.day + DOC.days, next: S.day + DOC.days + DOC.gap, n: ((h.doc && h.doc.n) || 0) + 1 }; repAll(DOC.rep); });
                for (const k of ['alt', 'world', 'pacific']) { const R = RECORDS[k]; if (!h.rec && !(h.records && h.records[k]) && !(R.after && !(h.records && h.records[R.after]))) spend('record', recCost(k), () => { h.rec = { k, done: S.day + R.days }; }); }
              }
            } else {
              const X = extras();
              if (!PROP) { for (const x of X) if ((S.holding || 0) - x.c >= reserve) spend(x.k, x.c, x.f); }
              else {
                /* 1. campaigns, when they add something under the region's cap; 2. the big projects, cheapest first, saved up
                   for; 3. estates and buyouts with what is over the next big project's price; 4. the foundation with what is
                   over the whole of it (or over 30 days of income when nothing big is left) */
                const cash = () => (S.holding || 0) - reserve, inc = Math.max(0, inc30.reduce((x, y) => x + y, 0) / Math.max(1, inc30.length));
                for (const x of X.filter(x => x.cls === 'mkt')) { if (x.b && x.ids.reduce((a, id) => a + Math.min(x.b, Math.max(0, PX.cap - pxTemp(id))), 0) < x.b * x.ids.length * .5) continue; if (cash() >= x.c) spend(x.k, x.c, x.f); }
                /* big projects take turns: the kind bought longest ago (or never) first, so every one gets saved up for */
                const lb = L.lastBig = L.lastBig || {}, turn = (u, v) => ((lb[u.k] ?? -1) - (lb[v.k] ?? -1)) || (u.c - v.c);
                const next = extras().filter(x => x.cls === 'big').sort(turn)[0];
                if (next && cash() >= next.c && spend(next.k, next.c, next.f)) lb[next.k] = S.day;
                const tgt = (extras().filter(x => x.cls === 'big').sort(turn)[0] || {}).c;
                for (const x of X.filter(x => x.cls === 'inv')) if (cash() - x.c >= (tgt || 0)) spend(x.k, x.c, x.f);
                for (const x of extras().filter(x => x.cls === 'found')) if (cash() - x.c >= (tgt || inc * 30)) spend(x.k, x.c, x.f);
              }
            }
          }
          if (typeof ctrState === 'function' && ctrCfg() && ctrState().offer) { const O = ctrState().offer, fog = O.fogP ? O.fogP.reduce((x, y) => x + y, 0) / O.fogP.length : 0; if (O.n <= fleetSeats() * .85 && fog <= .45) ctrAccept(); else ctrDecline(); } S.xfer = null;
          const C0 = chap()[S.chapter || 0], need = k => C0 && C0.goals.some(g => g[0] === k && !goalDone(g));
          const saving = C0 && !need('balloons') && C0.goals.some(g => !goalDone(g) && ['fabBuilt', 'workshop', 'xl', 'school', 'hotelOwn', 'bldTop', 'bldHangar', 'bldMast'].includes(g[0])) && S.cash < 250000;
          if (S.unl.bank && S.loans.length < 1 && S.balloons.length < 4 && S.cash < 15000 && (S.day >= 6 || S.region !== 'cap')) { S.cash += 10000; S.loans.push({ amt: 10000, inst: 300, left: 40 }); }
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
          if (typeof ctrDelayJob === 'function' && ctrDelayJob()) ctrDelayChoose(ctrDelayJob().dl.q >= .5 ? 'hold' : 'open');
          const h0 = S.holding || 0;
          try { launch(S.weather.flag === 'red'); } catch (e) { L.err = e.message + ' @' + S.day; break; }
          /* the night: autopilot net (after running costs), record payouts etc. */
          const hNight = (S.holding || 0) - h0;
          for (const id of ['cap', 'abq', 'lux', 'bri']) if (S.barons && S.barons[id] && !L.baron[id]) L.baron[id] = S.barons[id];
          if (S.hold && S.hold.worldBaron && !L.world) { L.world = S.hold.worldBaron; postEnd = S.day + POST; }
          const td = (S.hold && S.hold.today) || {};
          const base = Object.keys(S.regions || {}).reduce((x, id) => x + ((S.regions[id].auto || {}).todayRaw || 0) * officeMult(id), 0);
          inc30.push(hNight + dayIn); if (inc30.length > 30) inc30.shift();
          const spentToday = Object.values(L.dspent).reduce((x, y) => x + y, 0);
          L.days.push([S.day, Math.round(S.holding || 0), Math.round(td.gross || 0), Math.round(td.cost || 0), Math.round(dayIn), Math.round(spentToday), Math.round(inc30.reduce((x, y) => x + y, 0) / inc30.length), Math.round(base)]);
          if (L.world && S.day >= postEnd) break;
          if (S.over) { L.err = 'bankrupt @' + S.day; break; }
        }
        const h = S.hold || {};
        L.end = { auto: Object.keys(S.regions || {}).filter(id => S.regions[id].auto).map(id => id + ':' + Math.round(S.regions[id].auto.base * officeMult(id))).join(' '), rnd: h.rnd, offices: officeCount(), recBoost: h.recBoost, records: h.records, px: h.px, wg: h.wg, rep: myRegionIds().map(id => id + ':' + Math.round((id === S.region ? S.rep : S.regions[id].rep) * 100) / 100).join(' ') };
        withdraw = wd; startDay = realStart;
        return L;
      }, [seed, POST, MODE]));
    }
    all[MODE] = res;
  }
  await b.close();

  /* ---- summary ---- */
  const q = (arr, f) => { const s = arr.filter(x => x != null && !isNaN(x)).sort((x, y) => x - y); if (!s.length) return null; const i = (s.length - 1) * f, lo = Math.floor(i); return s[lo] + (s[Math.min(lo + 1, s.length - 1)] - s[lo]) * (i - lo); };
  const M = v => v == null ? '–' : Math.abs(v) >= 1e6 ? '€' + (v / 1e6).toFixed(1) + 'M' : '€' + Math.round(v / 1000) + 'k';
  const at = (r, day) => r.days.find(x => x[0] >= day) || r.days[r.days.length - 1];
  for (const MODE of MODES) {
    const R = all[MODE];
    console.log(`\n=== ${MODE} (${R.length} seeds${R.filter(r => r.err).length ? ', errors: ' + R.filter(r => r.err).map(r => r.err).join(', ') : ''}) ===`);
    const ms = [['Luxor baron', r => r.baron.lux], ['Bristol baron', r => r.baron.bri], ['World Baron', r => r.world]];
    for (const [n, f] of ms) {
      const ds = R.map(f).filter(Boolean);
      const cash = R.filter(f).map(r => at(r, f(r))[1]), inc = R.filter(f).map(r => at(r, f(r))[6]);
      console.log(`${n.padEnd(14)} day ${Math.round(q(ds, .5))} (${q(ds, 0)}–${q(ds, 1)}, ${ds.length}/${R.length}) · holding cash ${M(q(cash, .5))} (${M(q(cash, .1))}–${M(q(cash, .9))}) · income ${M(q(inc, .5))}/day`);
    }
    console.log('days after World Baron: holding cash median [p10–p90] · income/day (30-day avg, net of running costs) · cash ÷ income = days of income');
    for (let k = 0; k <= POST; k += 50) {
      const rows = R.filter(r => r.world).map(r => at(r, r.world + k));
      const c = rows.map(x => x[1]), i = rows.map(x => x[6]), dd = rows.map(x => x[1] / Math.max(1, x[6]));
      const bx = rows.map(x => x[7] ? x[2] / x[7] : null), bp = rows.map(x => x[7]);
      console.log(`  +${String(k).padStart(3)}  ${M(q(c, .5)).padStart(7)} [${M(q(c, .1))}–${M(q(c, .9))}]  income ${M(q(i, .5))}/day  = ${Math.round(q(dd, .5))} days · autopilot before holding boosts ${M(q(bp, .5))}/day, boosts ×${(q(bx, .5) || 0).toFixed(2)}`);
    }
    const post = R.filter(r => r.world).map(r => { const d = r.days.filter(x => x[0] > r.world); const inc = d.reduce((a, x) => a + (x[2] - x[3]) + x[4], 0), sp = d.reduce((a, x) => a + x[5], 0); return [inc / d.length, sp / d.length]; });
    console.log(`after World Baron, per day: income ${M(q(post.map(x => x[0]), .5))} (autopilot net + withdrawals), spent ${M(q(post.map(x => x[1]), .5))} (${Math.round(100 * q(post.map(x => x[1] / x[0]), .5))}% of income)`);
    const cats = {}; for (const r of R) for (const k in r.spent) (cats[k] = cats[k] || []).push(r.spent[k]);
    console.log('spent over the whole game, median per seed: ' + Object.keys(cats).sort((x, y) => q(cats[y], .5) - q(cats[x], .5)).map(k => `${k} ${M(q(cats[k], .5))}`).join(' · '));
    console.log('end state, seed 1:', JSON.stringify(R[0].end));
  }
  if (OUT) require('fs').writeFileSync(OUT, JSON.stringify(Object.fromEntries(Object.entries(all).map(([k, R]) => [k, R.map(r => ({ world: r.world, baron: r.baron, days: r.days.filter((x, i) => i % 5 === 0) }))]))));
})();
