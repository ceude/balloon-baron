// Usage: NODE_PATH=$(npm root -g) node tools/sim-holding.js [seeds=16] [postDays=400] [modes=goals,spend] [firstSeed=1] [out.json]
// The holding's late-game economy: where its money comes from, where it can go, and how much piles up.
// The campaign bot of tools/sim-campaign.js plays the whole game (Cappadocia, Albuquerque, Luxor, Bristol, World Baron)
// and then `postDays` more days, on the prototype as it is. Modes:
//   goals: the bot of sim-campaign.js (buys the holding goals; after World Baron a documentary season whenever it can and
//          the record ladder once). The baseline.
//   spend: the bot buys every holding item: every campaign the moment it can pay for it (TV and billboards in every
//          region, celebrity, documentary, the International Balloon Festival in the region with the least festival
//          fame), the big projects saved up for in turns (jersey, records and their improvement attempts, the World
//          Games again every 360 days), and Hot Air Foundation projects with what is over the next big project's price.
//          It keeps a reserve for the next holding goal until World Baron. The player who tries hard to spend.
// A mode can carry tweaks (TWEAKS below), e.g. `goals+celebFull`: page code that changes one number to see what it does.
// Prints per mode: milestone days, holding cash and income at each, the cash curve (median, 10th and 90th percentile)
// by days after World Baron, cash measured in days of income, and where the money went (office rent included). With
// out.json it also writes every seed's daily samples (for charts).
// Results (32 seeds, 400 days after World Baron), median:
//   v139 (commit 35dc6e8, before):  World Baron day 604. goals: cash +100/+200/+400 €10.3M / €18.2M / €42.3M, 22% of
//     income spent. spend: €9.3M / €19.7M / €44.1M, 43% spent.
//   v140 (developer's price table, office rent, festival, foundation, no cap; this file): World Baron day 606.
//     goals: €4.0M / €10.7M / €30.9M, 44% spent. spend: €3.6M / €3.3M / €8.4M, 90% spent.
//   goals+celebFull (first celebrity €1.8M): World Baron 617 (+11 days), so the first deal stays €600,000.
//   spend+rd4old: €5k a day less income (R&D 4 at +2%); spend+noTyo: €11k a day less (Tokyo's +5%); goals+noPar: €5k.
const { chromium } = require('playwright');
const SEEDS = +(process.argv[2] || 16), POST = +(process.argv[3] || 400), MODES = (process.argv[4] || 'goals,spend').split(','), FROM = +(process.argv[5] || 1), OUT = process.argv[6];

/* Variants: page code run after the prototype loads, to try a change without touching the game. A mode is a bot and
   optional tweaks, e.g. `goals+celebFull`. */
const TWEAKS = {
  celebFull: 'CELEB.first = CELEB.cost;',                                   /* the first celebrity deal at the full €1.8M */
  noRent: 'for (const k in HQ_CITIES) HQ_CITIES[k].rent = 0;',              /* offices without rent */
  rd4old: 'RD_FX.auto4 = 1.02;',                                           /* R&D level 4 at its old +2% */
  noTyo: 'OFFICE_FX.tyo = 1;',                                              /* Tokyo without its +5% tourists */
  noPar: 'OFFICE_FX.par = 1;'                                              /* Paris without its Bristol +20% */
};
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 390, height: 800 } });
  p.on('pageerror', e => console.error('ERR', e.message));
  const all = {};
  for (const MODE of MODES) {
    await p.goto('file://' + require('path').resolve(__dirname, '../prototype/balloon-baron.html')); await p.waitForTimeout(500);
    for (const t of MODE.split('+').slice(1)) await p.addScriptTag({ content: TWEAKS[t] });
    const res = [];
    for (let seed = FROM; seed < FROM + SEEDS; seed++) {
      res.push(await p.evaluate(([seed, POST, MODE]) => {
        let a = seed * 9301 + 49297; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
        sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {}; buildWorld = () => {}; nextPopup = () => {}; showTravel = () => {}; applyRegionTheme = () => {};
        const realStart = startDay; startDay = () => {};
        startFlight = () => finishDay({ q: Math.random() < .3 ? 'perfect' : Math.random() < .85 ? 'good' : 'far', dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && Math.random() < .6 });
        S = newState(); S.company = 'Bot'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
        S.iap = { worldTour: 1 };
        const SPEND = MODE.split('+')[0] === 'spend';
        const L = { baron: {}, enter: { cap: 1 }, world: 0, err: null, days: [], spent: {}, buys: [], at: {} };
        let postEnd = 99999, dayIn = 0, dayAuto = 0;
        /* money into the holding from the region you play (withdrawals) is counted with the autopilot as income */
        const wd = withdraw; withdraw = s => { const h0 = S.holding || 0; wd(s); dayIn += (S.holding || 0) - h0; };
        const NEXT = { cap: 'abq', abq: 'lux', lux: 'bri', bri: 'mara' }; /* v141: the Maasai Mara after Bristol (World Baron needs it: Dubai's office and the first safari-plane group) */
        const H = () => S.hold || (S.hold = { log: [] });
        const spend = (cat, c, f) => { if ((S.holding || 0) < c) return false; S.holding -= c; holdLog('exp', c); f(); L.spent[cat] = (L.spent[cat] || 0) + c; (L.dspent = L.dspent || {})[cat] = ((L.dspent || {})[cat] || 0) + c; return true; };
        const officeOrder = Object.keys(HQ_CITIES).sort((x, y) => HQ_CITIES[x].cost - HQ_CITIES[y].cost);
        const celebC = () => celebCost(), celebD = () => CELEB.days;
        /* the holding goals, in the order the campaign bot buys them */
        const goals = () => {
          const h = H(), out = [];
          for (const k of officeOrder) if (!hasOffice(k) && officeOpenable(k)) out.push({ k: 'office', c: HQ_CITIES[k].cost, f: () => { h.offices = Object.assign({}, h.offices, { [k]: S.day }); } });
          if ((h.rnd || 0) < RD_LEVELS.length) out.push({ k: 'rnd', c: RD_LEVELS[h.rnd || 0].cost, f: () => { h.rnd = (h.rnd || 0) + 1; } });
          if (!h.tvN) out.push({ k: 'tv', c: tvCost(), f: () => { h.tvN = 1; (h.tv = h.tv || {})[S.region] = { until: S.day + TVC.days, cd: S.day + TVC.cd }; repIn(S.region, TVC.rep); } });
          if (!h.celeb) out.push({ k: 'celeb', c: celebC(), f: () => { h.celeb = { name: 'X', until: S.day + celebD() }; repAll(.15); } });
          if (!h.wg) out.push({ k: 'wg', c: wgCost(), f: () => { h.wg = { until: S.day + WGAMES.days, n: 1, at: S.day }; repAll(WGAMES.rep); } });
          return out;
        };
        /* everything else the holding can buy today, in the order the spending bot tries them */
        const extras = () => {
          const h = H(), d = S.day, out = [], P = h.px || (h.px = {}), mine = myRegionIds();
          for (const id of mine) if (tvReadyR(id) <= d) out.push({ k: 'tv', cls: 'mkt', c: tvCost(), f: () => { h.tvN = (h.tvN || 0) + 1; (h.tv = h.tv || {})[id] = { until: d + TVC.days, cd: d + TVC.cd }; repIn(id, TVC.rep); } });
          if (!(h.celeb && h.celeb.until > d)) out.push({ k: 'celeb', cls: 'mkt', c: celebC(), f: () => { h.celeb = { name: 'X', until: d + celebD() }; repAll(CELEB.rep); } });
          if (!(h.doc && h.doc.next > d)) out.push({ k: 'doc', cls: 'mkt', c: docCost(), f: () => { h.doc = { until: d + DOC.days, next: d + DOC.days + DOC.gap, n: ((h.doc && h.doc.n) || 0) + 1 }; repAll(DOC.rep); } });
          if (!(h.jersey > d)) out.push({ k: 'jersey', cls: 'big', c: JERSEY.cost, f: () => { h.jersey = d + JERSEY.days; repAll(JERSEY.rep); } });
          /* the record ladder first (a record not yet set), then attempts to improve one while the lasting boost is under its ceiling */
          const recs = ['alt', 'pacific', 'world'].filter(k => !(RECORDS[k].after && !(h.records && h.records[RECORDS[k].after])));
          const rk = recs.find(k => !(h.records && h.records[k])) || ((h.recBoost || 0) < recCap() - 1e-9 ? recs[0] : null);
          if (!h.rec && rk) out.push({ k: 'record', cls: 'big', c: recCost(rk), f: () => { h.rec = { k: rk, done: d + RECORDS[rk].days }; h.recV2 = 1; } });
          /* v140: the World Games again, 360 days after the last show, each 1.5 times the last */
          if (h.wg && !(h.wg.until > d) && wgNext() <= d) out.push({ k: 'wg', cls: 'big', c: wgCost(), f: () => { h.wg = { until: d + WGAMES.days, n: wgN() + 1, at: d }; repAll(WGAMES.rep); } });
          /* v140: the hosted festival, in the owned region with the least festival fame */
          if (hfReady()) { const id = mine.slice().sort((x, y) => (((h.fame || {})[x]) || 0) - (((h.fame || {})[y]) || 0))[0]; out.push({ k: 'festival', cls: 'mkt', c: hfCost(), f: () => hostFestival(id) }); }
          /* v140: the foundation, its projects round the owned regions */
          { const id = mine.slice().sort((x, y) => foundIn(x) - foundIn(y))[0]; out.push({ k: 'foundation', cls: 'found', c: foundCost(id), f: () => fundProject(id) }) /* v142: priced per region */; }
          for (const id of mine) if (!((h.bb || {})[id] > d)) out.push({ k: 'billboards', cls: 'mkt', ids: [id], c: BB.cost, f: () => { (h.bb = h.bb || {})[id] = d + BB.days; } });
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
              /* 1. every campaign (TV, billboards, celebrity, documentary, the hosted festival) the moment it can be paid;
                 2. the big projects (jersey, records, World Games), saved up for in turns; 3. the foundation with what is
                 over the next big project's price (or over 30 days of income when nothing big is waiting) */
              const X = extras(), cash = () => (S.holding || 0) - reserve, inc = Math.max(0, inc30.reduce((x, y) => x + y, 0) / Math.max(1, inc30.length));
              for (const x of X.filter(x => x.cls === 'mkt')) if (cash() >= x.c) spend(x.k, x.c, x.f);
              /* big projects take turns: the kind bought longest ago (or never) first, so every one gets saved up for */
              const lb = L.lastBig = L.lastBig || {}, turn = (u, v) => ((lb[u.k] ?? -1) - (lb[v.k] ?? -1)) || (u.c - v.c);
              const next = extras().filter(x => x.cls === 'big').sort(turn)[0];
              if (next && cash() >= next.c && spend(next.k, next.c, next.f)) lb[next.k] = S.day;
              const tgt = (extras().filter(x => x.cls === 'big').sort(turn)[0] || {}).c;
              for (const x of extras().filter(x => x.cls === 'found')) if (cash() - x.c >= (tgt || inc * 30)) spend(x.k, x.c, x.f);
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
          for (const id of ['cap', 'abq', 'lux', 'bri', 'mara']) if (S.barons && S.barons[id] && !L.baron[id]) L.baron[id] = S.barons[id];
          if (S.hold && S.hold.worldBaron && !L.world) { L.world = S.hold.worldBaron; postEnd = S.day + POST; }
          const td = (S.hold && S.hold.today) || {};
          if (td.rent) L.spent.rent = (L.spent.rent || 0) + td.rent; /* v140: the offices' rent, counted with the spending */
          const base = Object.keys(S.regions || {}).reduce((x, id) => x + ((S.regions[id].auto || {}).todayRaw || 0) * officeMult(id), 0);
          inc30.push(hNight + dayIn); if (inc30.length > 30) inc30.shift();
          const spentToday = Object.values(L.dspent).reduce((x, y) => x + y, 0);
          L.days.push([S.day, Math.round(S.holding || 0), Math.round(td.gross || 0), Math.round((td.cost || 0) + (td.rent || 0)), Math.round(dayIn), Math.round(spentToday), Math.round(inc30.reduce((x, y) => x + y, 0) / inc30.length), Math.round(base)]);
          if (L.world && S.day >= postEnd) break;
          if (S.over) { L.err = 'bankrupt @' + S.day; break; }
        }
        const h = S.hold || {};
        L.end = { auto: Object.keys(S.regions || {}).filter(id => S.regions[id].auto).map(id => id + ':' + Math.round(S.regions[id].auto.base * officeMult(id))).join(' '), rnd: h.rnd, offices: officeCount(), recBoost: h.recBoost, records: h.records, wg: h.wg, fame: h.fame, fdn: h.fdn && h.fdn.n, rep: myRegionIds().map(id => id + ':' + Math.round((id === S.region ? S.rep : S.regions[id].rep) * 100) / 100).join(' ') };
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
    const ms = [['Luxor baron', r => r.baron.lux], ['Bristol baron', r => r.baron.bri], ['Mara baron', r => r.baron.mara], ['World Baron', r => r.world]];
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
