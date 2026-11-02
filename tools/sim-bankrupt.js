// Usage: NODE_PATH=$(npm root -g) [RUIN=accept|half] node tools/sim-bankrupt.js [profiles=all] [seeds=40] [days=800] [firstSeed=1]
//   profiles: comma list of ordinary,overexp,gambler,neglect,allbad,newbie,newbieMild,redOnly,noIns,noRenew,badPrice,priceHigh,priceLow,noHangar,stuckNoRenew (or "all")
// Can a careless player still go bankrupt? Bots with different habits play the whole campaign on the prototype's real
// game code (Cappadocia, then Albuquerque, Luxor and Bristol with the Grand Tour owned, as tools/sim-campaign.js does).
// The game ends (S.over) only when cash is below -5,000 at the close of a day and the bank has taken the last balloon
// (one seizure a day, biggest non-flagship first). Per run: bankrupt day and region, seizures, worst cash, longest
// stretch below zero, longest stretch with nothing able to fly, baron days, and what drained the money on seizure days.
const { chromium } = require('playwright');
const ALL = ['ordinary', 'overexp', 'gambler', 'neglect', 'allbad', 'newbie', 'newbieMild', 'redOnly', 'noIns', 'noRenew', 'badPrice', 'priceHigh', 'priceLow', 'noHangar', 'stuckNoRenew'];
const PROF = (process.argv[2] && process.argv[2] !== 'all') ? process.argv[2].split(',') : ALL;
/* TRACE=1: each run also lists its days (region, day, flag, balloons at dawn, cash after the morning's moves, cash at night, net, balloons at night).
   SELFQ=safe: the founder never lands hard or crashes (as in the other sims); otherwise 2% of green, 8% of yellow and 25% of
   red own flights end in a hard landing or a crash. */
const TRACE = !!process.env.TRACE, SAFE = process.env.SELFQ === 'safe';
/* v133: when the bank comes for a region's last balloon and the player owns a holding, the bot takes the holding's
   rescue whenever it can pay (RUIN=accept, the default) or only half the time (RUIN=half); otherwise the region closes
   and the bot goes on in another region (or a fresh start of this one). */
const RUIN = process.env.RUIN || 'accept';
const SEEDS = +(process.argv[3] || 40), DAYS = +(process.argv[4] || 800), FROM = +(process.argv[5] || 1);
/* profile switches
   buf: cash cushion kept when buying (×), loans: 'starter' (10k while small) | 'all' (biggest loan whenever the bank allows, two at once),
   buyLoan: rivals bought with the purchase loan, hangar: 'grow' | 'lazy' (only once 3+ balloons stand outside) | 'never',
   renew: envelopes replaced, price: 'adapt' | 'bad' (30 days at 300, 30 days at 70) | a fixed number, events: 'best' | 'random',
   winter: buys in winter too, ins: insurance, flags: highest flag flown ('yellow' | 'red'), hire: 'best' | 'cheap' | 'rookie',
   rescue: uses the rescue card's moves when cash is below zero, xfer: brings balloons from home on entering (30-day debt) */
const BASE = { buf: 1, loans: 'starter', buyLoan: false, hangar: 'grow', renew: true, price: 'adapt', events: 'best', winter: false, ins: true, flags: 'yellow', hire: 'best', rescue: true, xfer: false, issues: true };
const BAD = { buf: 0, loans: 'all', buyLoan: true, hangar: 'never', renew: false, price: 'bad', events: 'random', winter: true, ins: false, flags: 'red', hire: 'rookie', rescue: false, xfer: true, issues: false };
const PROFILES = {
  ordinary: BASE,
  overexp: { ...BASE, buf: 0, loans: 'all', buyLoan: true, hangar: 'lazy', winter: true, rescue: false, xfer: true, events: 'random' },
  gambler: { ...BASE, ins: false, flags: 'red', hire: 'rookie', rescue: false, events: 'random' },
  neglect: { ...BASE, renew: false, winter: true, price: 'bad', events: 'random', hangar: 'never', rescue: false, issues: false },
  allbad: BAD,
  newbie: { ...BASE, newbie: 60 }, /* days 1-60 play like allbad (but grows the hangar lazily), then like ordinary */
  newbieMild: { ...BASE, newbie: 60, early: { buf: 0, loans: 'all', winter: true, flags: 'red', hire: 'rookie', rescue: false, events: 'random', hangar: 'lazy' } }, /* days 1-60: spends everything, every loan, flies red, but keeps insurance and a sane price */
  /* one bad habit each, on top of the ordinary player, to see which one does the damage */
  redOnly: { ...BASE, flags: 'red' },
  noIns: { ...BASE, ins: false },
  noRenew: { ...BASE, renew: false },
  badPrice: { ...BASE, price: 'bad' },
  priceHigh: { ...BASE, price: 250 }, /* a fixed ticket price, never looked at again */
  priceLow: { ...BASE, price: 110 },
  noHangar: { ...BASE, hangar: 'never' }, /* never grows the hangar: Cappadocia's chapter 2 can't end, the player stays */
  stuckNoRenew: { ...BASE, hangar: 'never', renew: false }
};
(async () => {
  const b = await chromium.launch();
  const out = [];
  await Promise.all(PROF.map(async prof => {
    const p = await b.newPage({ viewport: { width: 390, height: 800 } });
    p.on('pageerror', e => console.error('ERR', e.message));
    await p.goto('file://' + require('path').resolve(__dirname, '../prototype/balloon-baron.html')); await p.waitForTimeout(600);
    for (let seed = FROM; seed < FROM + SEEDS; seed++) {
      const r = await p.evaluate(([seed, DAYS, prof, P0, BADP, TRACE, SAFE, RUIN]) => {
        let a = seed * 9301 + 49297; Math.random = () => { a = (a * 9301 + 49297) % 233280; return a / 233280; };
        sfx = () => {}; save = () => {}; showReport = () => {}; refresh = () => {}; buildWorld = () => {}; nextPopup = () => {}; showTravel = () => {}; applyRegionTheme = () => {};
        const realStart = startDay; startDay = () => {};
        /* the founder's own landing: worse on yellow, much worse on red */
        const Q = SAFE ? { green: [.3, .55, .15, 0, 0] } : { green: [.3, .55, .13, .015], yellow: [.2, .5, .22, .06], red: [.1, .4, .25, .15] };
        startFlight = () => { const q = Q[S.weather.flag] || Q.green, x = Math.random(); const k = x < q[0] ? 'perfect' : x < q[0] + q[1] ? 'good' : x < q[0] + q[1] + q[2] ? 'far' : x < q[0] + q[1] + q[2] + q[3] ? 'hard' : 'crash'; finishDay({ q: k, dist: 60, mis: S.weather.mission, mok: !!S.weather.mission && k !== 'hard' && k !== 'crash' && Math.random() < .6 }); };
        const L = { prof, seed, rescues: [], closes: [], over: null, overRegion: null, seized: 0, seizedBy: {}, seizeDays: [], minCash: 0, minCashRegion: 'cap', negRun: 0, negMax: 0, groundRun: 0, groundMax: 0, baron: {}, enter: { cap: 1 }, world: 0, causes: {}, reds: 0, fines: 0, crashes: 0, loansTaken: 0, buyLoans: 0, err: null };
        if (!window.__paW) { const pa = paperAdd; window.__paW = 1; paperAdd = (pr, hd, sub) => { if (window.__onPaper) window.__onPaper(hd); return pa(pr, hd, sub); }; }
        window.__onPaper = hd => { if (/^Banka .*el koydu/.test(hd) && hd.includes(S.company)) { L.seized++; L.seizedBy[S.region] = (L.seizedBy[S.region] || 0) + 1; L.seizeDays.push(S.region + S.day); L.seizeToday = 1; } };
        S = newState(); S.company = 'Bot'; S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan();
        S.iap = { worldTour: 1 };
        const NEXT = { cap: 'abq', abq: 'lux', lux: 'bri' }, HQ_ORDER = ['ist', 'nyc', 'tyo', 'sel'];
        const hist = []; /* the last 10 days' money, for the cause of a seizure */
        for (let d = 0; d < DAYS; d++) {
          const P = P0.newbie && S.day <= P0.newbie ? Object.assign({}, P0.early ? P0 : BADP, P0.early || { hangar: 'lazy' }) : P0;
          S.ins = { hull: P.ins, pax: P.ins };
          for (const k of S.hezQ) if (!/^(news|boss|hz|ctr|insp|guide):/.test(k)) S.tips[k] = 1;
          let evDue = false;
          if (S.day >= 12 && S.unl.crew && !S.winter && S.day >= (S.nextEvent || 12)) { S.nextEvent = S.day + 7 + Math.round(Math.random()); evDue = true; }
          S.hezQ = []; S.paper = null; S.eventDue = false; S.chapterNews = null; S.poach = null; S.mergeNews = null;
          if (S.issue) S.issue = null;
          for (const id in (S.regions || {})) { const A = S.regions[id].auto; if (A && A.issue && P.issues) A.issue = null; }
          if (typeof expireSeasons === 'function') expireSeasons();
          if (!S.weather) S.weather = newWeather(); if (!S.demand) S.demand = dayDemand(); if (!S.rivals[0].fly) rivalFlyPlan();
          if (!S.candidates.length) newCandidates();
          unlockCheck(); assignPilots();
          if (S.day === 3 && S.tut) S.tut.done = 1;
          const cash0 = S.cash; let lent = 0;
          /* the morning event card: the highlighted choice, or any */
          if (evDue) {
            const keys = Object.keys(EVENTS).filter(k => EVENTS[k].ok() && k !== S.lastEvent);
            if (keys.length) { const k = S.lastEvent = pick(keys); try { eventCard(k); const bs = [...document.querySelectorAll('#menu button')].filter(x => !x.disabled); const bt = P.events === 'best' ? bs[0] : bs[Math.floor(Math.random() * bs.length)]; if (bt) bt.click(); } catch (e) { } document.getElementById('menu').hidden = true; }
          }
          /* price */
          if (P.price === 'bad') S.price = (S.day % 60) < 30 ? 300 : 70;
          else if (typeof P.price === 'number') S.price = P.price;
          else if (S.region === 'cap' && S.day === 1) S.price = 140; else if (S.region === 'cap' && S.day === 2) S.price = 220; else if (S.region === 'cap' && S.day === 3) S.price = 170;
          else if (S.lastShare && S.lastShare.cap) { const l = S.lastShare.me / S.lastShare.cap; if (l > .97) S.price += 10; else if (l < .75) S.price -= 10; S.price = clamp(S.price, 100, 320); }
          const baron = isBaron();
          if (baron && NEXT[S.region] && !ownsRegion(NEXT[S.region])) {
            withdraw(1);
            if ((S.holding || 0) >= entryFee(NEXT[S.region])) {
              const nx = NEXT[S.region]; enterRegion(nx); S.weather = newWeather(); S.demand = dayDemand(); rivalFlyPlan(); L.enter[nx] = S.day;
              if (P.xfer && S.xfer) { const B = xferBalloons(), Pp = xferPilots(), sel = {}; let st = 0, n = 0; for (const x of B) if (n < XFER.maxB && st + SIZES[x.b.size].cap <= XFER.seats) { (sel[x.id] = sel[x.id] || { b: [], p: [] }).b.push(x.b.id); st += SIZES[x.b.size].cap; n++; } for (const x of Pp.slice(0, XFER.maxP)) (sel[x.id] = sel[x.id] || { b: [], p: [] }).p.push(x.p.id); xferApply(sel); }
              S.xfer = null; continue;
            }
          }
          if (isBaron('lux')) {
            if (isBaron() && S.cash > 30000) withdraw(1);
            const H = S.hold || (S.hold = { log: [] }), buy = (c, f) => { if ((S.holding || 0) >= c) { S.holding -= c; f(); return true; } return false; };
            for (const k of HQ_ORDER) if (!hasOffice(k)) buy(HQ_CITIES[k].cost, () => { H.offices = Object.assign({}, H.offices, { [k]: S.day }); });
            if ((H.rnd || 0) < 2) buy(RD_LEVELS[H.rnd || 0].cost, () => { H.rnd = (H.rnd || 0) + 1; });
            if (!(H.tvN)) buy(tvCost(), () => { H.tvN = 1; H.tvUntil = S.day + 14; H.tvCd = S.day + 30; });
            if (!H.celeb) buy(celebCost(), () => { H.celeb = { name: 'X', until: S.day + 90 }; });
            if (isBaron('bri') && !H.wg) buy(WGAMES.cost, () => { H.wg = { until: S.day + WGAMES.days }; });
          }
          if (typeof ctrState === 'function' && ctrCfg() && ctrState().offer) { const O = ctrState().offer, fog = O.fogP ? O.fogP.reduce((x, y) => x + y, 0) / O.fogP.length : 0; if (P.buf === 0 || (O.n <= fleetSeats() * .85 && fog <= .45)) ctrAccept(); else ctrDecline(); } S.xfer = null;
          const C0 = chap()[S.chapter || 0], need = k => C0 && C0.goals.some(g => g[0] === k && !goalDone(g));
          const saving = P.buf > 0 && C0 && !need('balloons') && C0.goals.some(g => !goalDone(g) && ['fabBuilt', 'workshop', 'xl', 'school', 'hotelOwn', 'bldTop', 'bldHangar', 'bldMast'].includes(g[0])) && S.cash < 250000;
          /* loans */
          const takeLoan = o => { S.cash += o.amt; lent += o.amt; S.loans.push({ amt: o.amt, inst: o.inst, left: o.days }); L.loansTaken++; };
          if (P.loans === 'all') { while (S.unl.bank && S.loans.length < 2) { const open = LOANS.filter(o => S.balloons.length >= o.need && (!o.net || (S.loanOpen || {})[o.amt])); if (!open.length) break; takeLoan(open[open.length - 1]); } }
          else if (S.unl.bank && S.loans.length < 1 && S.balloons.length < 4 && S.cash < 15000 && (S.day >= 6 || S.region !== 'cap')) takeLoan(LOANS[0]);
          /* rescue card (ordinary player): cash below zero in the morning */
          if (P.rescue && S.cash < 0) {
            const idle = S.pilots.filter(q => !S.balloons.some(x => x.pilot === q.id)); if (idle.length) S.pilots = S.pilots.filter(q => !idle.includes(q));
            const rp = rescuePrice(); if (rp) S.price = rp.p;
            if (S.cash < 0 && unlocked('bank') && S.loans.length < 2) { const ln = [...LOANS].reverse().find(o => !o.net && S.balloons.length >= o.need); if (ln) takeLoan(ln); }
          }
          const hasRoom = () => S.balloons.length < hangarCap();
          const growHangar = buf => { const Lv = UPGRADES.hangar.lv[bl('hangar')]; if (Lv && S.cash > Lv.cost + buf) { S.cash -= Lv.cost; S.bld = Object.assign({}, S.bld, { hangar: bl('hangar') + 1 }); } };
          if (P.hangar === 'lazy' && outN() >= 3) growHangar(0);
          const buyB = (z, buf) => { if (hasRoom() || P.hangar !== 'grow') { S.cash -= SIZES[z].cost; addBalloon(z); } else growHangar(buf); };
          const bf = P.buf;
          if (S.unl.fleet && (P.winter || !S.winter) && !saving && !baron) {
            if (bf === 0) { /* every euro into balloons */
              let n = 0; while (n++ < 8 && S.balloons.length < 60) { const z = S.balloons.length < 3 ? 'S' : S.balloons.length < 14 ? 'M' : 'L'; if (S.cash >= SIZES[z].cost) { S.cash -= SIZES[z].cost; addBalloon(z); } else break; }
            } else if (S.balloons.length < 3 && S.cash >= SIZES.S.cost + 1500) buyB('S', 1500);
            else if (S.balloons.length >= 3 && S.balloons.length < 14 && S.cash > SIZES.M.cost + 15000) buyB('M', 15000);
            else if (S.balloons.length >= 14 && S.balloons.length < 45 && S.cash > SIZES.L.cost + 30000) buyB('L', 30000);
            assignPilots();
          }
          if (P.buyLoan) for (const rv of S.rivals) {
            const sale = !!rv.forSale, price = sale ? rv.forSale.price : (rv.alive && rv.offer) || 0; if (!price) continue;
            if (S.cash < price) { const T = buyLoanTerms(price); if (!T) continue; S.loans.push({ amt: T.fin, inst: T.inst, left: T.days, buy: 1 }); S.cash += T.fin; lent += T.fin; L.buyLoans++; }
            try { sale ? buyFleet(rv) : takeOver(rv); } catch (e) { } document.getElementById('menu').hidden = true;
          }
          if (S.unl.crew) {
            const want = () => S.balloons.some(x => canFly(x) === 'nopilot');
            while (want() && S.candidates.length) {
              const cs = P.hire === 'rookie' ? S.candidates.filter(c => c.lvl === 1) : S.candidates; if (!cs.length) break;
              const c = cs.sort((x, y) => P.hire === 'best' ? y.lvl - x.lvl : x.lvl - y.lvl)[0]; S.pilots.push(c); S.candidates = S.candidates.filter(x => x !== c); assignPilots();
            }
          }
          if (P.renew) for (const x of S.balloons) if (cond(x) <= 0 && S.cash > SIZES[x.size].cost * RENEW + 3000 * bf) { S.cash -= SIZES[x.size].cost * RENEW; x.flights = 0; }
          if (S.unl.market) for (const Hh of HOTELS) if (S.hotels.length < 2 && !S.hotels.includes(Hh.id) && !owns(Hh) && starVal(S.rep) >= Hh.min && S.cash > Hh.fee * 3 + 4000 * bf && !(S.hotelTaken[Hh.id] && S.hotelTaken[Hh.id].until > S.day)) { S.cash -= Hh.fee * 3; S.hotels.push(Hh.id); }
          if ((S.unl.guide || S.unl.market) && S.guideCd <= S.day && S.cash > 6000 * bf + GUIDE_COST) doGuide();
          if (need('glow') && typeof glowState === 'function' && glowState() === 'ok') bookGlow();
          if ((S.unl.agency || S.unl.market) && (need('influ') || need('stars')) && S.influCd <= S.day && S.cash > influCost() * (1 + bf) + 5000 * bf) doInfluencer();
          if (need('hotelOwn')) { const Hh = HOTELS.find(h => !owns(h) && starVal(S.rep) >= h.min && S.cash > h.buy + 20000 * bf); if (Hh) { S.cash -= Hh.buy; S.ownHotels.push(Hh.id); S.hotels = S.hotels.filter(i => i !== Hh.id); } }
          if ((need('workshop') || need('fabBuilt')) && !S.workshop && S.cash > WORKSHOP_COST + 20000 * bf) { S.cash -= WORKSHOP_COST; S.workshop = { day: S.day, lv: 1 }; }
          if (need('fabBuilt') && S.workshop) { if (fabLv() < 2) fabUpgrade(); else fabBuild('S'); }
          if (need('school') && S.cash > SCHOOL_COST + 20000 * bf) { S.cash -= SCHOOL_COST; S.school = true; }
          if (need('xl') && S.cash > 150000 + 20000 * bf) { if (hasRoom() || P.hangar !== 'grow') { S.cash -= 150000; addBalloon('XL'); assignPilots(); } else growHangar(170000); }
          const up = (k, buf) => { const Lv = UPGRADES[k].lv[bl(k)]; if (Lv && S.cash > Lv.cost + buf * bf) { S.cash -= Lv.cost; S.bld = Object.assign({}, S.bld, { [k]: bl(k) + 1 }); } };
          if (need('bldMast')) up('mast', 5000); if (need('bldHangar') && P.hangar !== 'never') up('hangar', 10000); if (need('bldTop')) up('mast', 10000);
          if (typeof ctrDelayJob === 'function' && ctrDelayJob()) ctrDelayChoose(ctrDelayJob().dl.q >= .5 ? 'hold' : 'open');
          const spent = cash0 + lent - S.cash;
          const red = S.weather.flag === 'red', skip = red && P.flags !== 'red'; if (red && !skip) L.reds++;
          const reg = S.region, day = S.day, nb = S.balloons.length;
          if (!skip && !flying().length) L.groundRun++; else if (!skip) L.groundRun = 0; L.groundMax = Math.max(L.groundMax, L.groundRun);
          L.seizeToday = 0;
          try { launch(skip); } catch (e) { L.err = e.message + ' @' + day; break; }
          if (S.ruin) {
            const Q = rescueQuote(), h0 = Math.round(S.holding || 0);
            if (Q.ok && (RUIN === 'accept' || Math.random() < .5)) { applyRescue(); L.rescues.push({ r: reg, d: day, cost: Q.cost, h0, h1: Math.round(S.holding) }); }
            else { L.closes.push({ r: reg, d: day, h: h0, why: Q.used != null ? 'used' : Q.ok ? 'declined' : 'poor' }); closeRegion(); }
          }
          const G = lastReport ? lastReport.Lg : {};
          if (G.repair || G.comp) L.crashes++; if (G.fine) L.fines++;
          hist.push({ acc: (G.repair || 0) + (G.comp || 0) - (G.insPay || 0), fines: (G.fine || 0) + (G.mono || 0), loans: G.loan || 0, xfer: G.xfer || 0, opex: (G.wage || 0) + (G.up || 0) + (G.fuel || 0) + (G.ins || 0) + (G.hotel || 0) + (G.ctrPen || 0) + (G.cancel || 0), inc: (G.rev || 0) + (G.tips || 0) + (G.founder || 0) + (G.hotelInc || 0) + (G.mission || 0) + (G.ad || 0) + (G.ctr || 0) + (G.ctrWait || 0) + (G.eve || 0), buys: Math.max(0, spent) });
          if (hist.length > 10) hist.shift();
          if (L.seizeToday) {
            const s = k => hist.reduce((x, h) => x + h[k], 0);
            const c = { accidents: s('acc'), fines: s('fines'), loans: s('loans'), xferDebt: s('xfer'), opexOverIncome: Math.max(0, s('opex') - s('inc')), purchases: s('buys') };
            const top = Object.keys(c).sort((x, y) => c[y] - c[x])[0]; L.causes[top] = (L.causes[top] || 0) + 1;
          }
          if (TRACE) (L.trace = L.trace || []).push([reg, day, S.weather && lastReport.flag, nb, Math.round(cash0 + lent - spent), Math.round(S.cash), Math.round(lastReport.net), S.balloons.length].join(' '));
          if (S.cash < L.minCash) { L.minCash = Math.round(S.cash); L.minCashRegion = S.region; }
          if (S.cash < 0) L.negRun++; else L.negRun = 0; L.negMax = Math.max(L.negMax, L.negRun);
          for (const id of ['cap', 'abq', 'lux', 'bri']) if (S.barons && S.barons[id] && !L.baron[id]) L.baron[id] = S.barons[id];
          if (S.hold && S.hold.worldBaron) { L.world = S.hold.worldBaron; break; }
          if (S.over) { L.over = day; L.overRegion = reg; L.overHolding = Math.round(S.holding || 0); L.overBaron = anyBaron(); break; }
        }
        L.end = { day: S.day, region: S.region, ch: S.chapter || 0, cash: Math.round(S.cash), n: S.balloons.length, pilots: S.pilots.length, wages: S.pilots.reduce((x, q) => x + pilotWage(q), 0), loanInst: S.loans.reduce((x, l) => x + l.inst, 0), fly: flying().length, holding: Math.round(S.holding || 0), loans: S.loans.length };
        startDay = realStart; delete L.seizeToday; delete L.negRun; delete L.groundRun;
        return L;
      }, [seed, DAYS, prof, PROFILES[prof], BAD, TRACE, SAFE, RUIN]);
      out.push(r); console.log(JSON.stringify(r));
    }
  }));
  const med = xs => { const s = xs.filter(x => x != null).sort((a, b) => a - b); return s.length ? s[s.length >> 1] : '-'; };
  console.log(`\nRUIN=${RUIN}: profile runs | game over (with a holding) | rescues: runs, count, avg cost, avg holding before | regions closed (poor/declined/used)`);
  let T = { runs: 0, over: 0, overH: 0, resc: 0, rescRuns: 0, cost: 0, closes: 0 };
  for (const pf of PROF) {
    const R = out.filter(o => o.prof === pf), ov = R.filter(o => o.over), rs = R.flatMap(o => o.rescues || []), cl = R.flatMap(o => o.closes || []), why = {};
    cl.forEach(c => { why[c.why] = (why[c.why] || 0) + 1; });
    const avg = xs => xs.length ? Math.round(xs.reduce((a, b) => a + b, 0) / xs.length) : '-';
    console.log(`${pf.padEnd(12)} ${R.length} | ${ov.length} (${ov.filter(o => o.overBaron).length}) | ${R.filter(o => (o.rescues || []).length).length} ${rs.length} ${avg(rs.map(x => x.cost))} ${avg(rs.map(x => x.h0))} | ${cl.length} ${JSON.stringify(why)}`);
    T.runs += R.length; T.over += ov.length; T.overH += ov.filter(o => o.overBaron).length; T.resc += rs.length; T.rescRuns += R.filter(o => (o.rescues || []).length).length; T.cost += rs.reduce((a, x) => a + x.cost, 0); T.closes += cl.length;
  }
  console.log(`TOTAL ${T.runs} runs | game over ${T.over} (with a holding ${T.overH}) | rescues ${T.resc} in ${T.rescRuns} runs, avg cost ${T.resc ? Math.round(T.cost / T.resc) : '-'} | regions closed ${T.closes}`);
  console.log('\nprofile   runs bankrupt(day med, region) seizedRuns seizures(med/max) worstCash(med/min) negDaysMax groundMax capBaron(n, med day) world(n, med) crashes reds main seizure cause');
  for (const pf of PROF) {
    const R = out.filter(o => o.prof === pf), ov = R.filter(o => o.over), cs = {};
    R.forEach(o => { for (const k in o.causes) cs[k] = (cs[k] || 0) + o.causes[k]; });
    const regs = {}; ov.forEach(o => { regs[o.overRegion] = (regs[o.overRegion] || 0) + 1; });
    console.log(`${pf.padEnd(9)} ${R.length} ${ov.length} (${med(ov.map(o => o.over))}, ${JSON.stringify(regs)}) ${R.filter(o => o.seized).length} ${med(R.map(o => o.seized))}/${Math.max(...R.map(o => o.seized))} ${med(R.map(o => o.minCash))}/${Math.min(...R.map(o => o.minCash))} ${Math.max(...R.map(o => o.negMax))} ${Math.max(...R.map(o => o.groundMax))} ${R.filter(o => o.baron.cap).length} ${med(R.map(o => o.baron.cap))} ${R.filter(o => o.world).length} ${med(R.map(o => o.world || null))} ${med(R.map(o => o.crashes))} ${med(R.map(o => o.reds))} ${JSON.stringify(cs)}`);
  }
  await b.close();
})();
