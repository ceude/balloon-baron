// App Review screenshots for the in-app purchases: one picture per product, its purchase card in the bazaar,
// rendered from the HTML prototype (it only reads the game). Only Apple's reviewer sees these.
// Usage: NODE_PATH=$(npm root -g) node tools/appstore/asc/review/render.js [out dir] [productKey…]
// 430x932 @3 = 1290x2796. Then: python3 tools/appstore/asc/review/compress.py (makes the PNGs small).
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const ROOT = path.resolve(__dirname, '../../../..');
const GAME = 'file://' + ROOT + '/prototype/balloon-baron.html';
const out = path.resolve(process.argv[2] || __dirname), only = process.argv.slice(3);
/* App Store product id suffix → the prototype's SHOP key */
const KEYS = { gold: 'gold', tile: 'tile', sky: 'sky', kilim: 'kilim', heart: 'heart', star: 'star', skull: 'skull',
  fountain: 'fountain', statue: 'statue', flags: 'flags', founder: 'founder', decorpack: 'decorPack',
  figurepack: 'figPack', worldtour: 'worldTour', supporter: 'supporter' };

(async () => {
  const br = await chromium.launch();
  const p = await br.newPage({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 3, hasTouch: true });
  await p.context().addInitScript(() => { try { localStorage.clear(); } catch (e) {} });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  fs.mkdirSync(out, { recursive: true });
  for (const [id, k] of Object.entries(KEYS)) {
    if (only.length && !only.includes(id)) continue;
    await p.goto(GAME); await p.waitForTimeout(700);
    await p.evaluate(k => {
      sfx = () => {}; save = () => {};
      if ($('intro')) $('intro').hidden = true;
      S = newState(); S.company = 'Ekin Balon'; S.day = 160; startDay();
      for (const u of ['fleet', 'bank', 'market', 'crew']) S.unl[u] = 1;
      for (let i = 0; i < 9; i++) addBalloon('M');
      S.iap = { lanterns: 1 }; S.cash = 50000; S.tutorialDone = true; S.hezQ = [];
      ['menu', 'hez'].forEach(id => $(id).hidden = true); refresh();
      showBazaar(); iapBuy(k);
      /* the prototype's "no real payment" note is not in the app */
      document.querySelectorAll('#menu .card.iap .hint').forEach(e => e.remove());
    }, k);
    await p.waitForTimeout(900);
    const f = path.join(out, `${id}.png`);
    await p.screenshot({ path: f });
    console.log('wrote', f);
  }
  if (errs.length) console.log('page errors:', errs.slice(0, 5));
  await br.close();
})();
