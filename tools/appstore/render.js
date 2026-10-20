// Renders the App Store screenshots: NODE_PATH=$(npm root -g) node tools/appstore/render.js [tr|en]
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

(async () => {
  const lang = process.argv[2] || 'tr';
  const out = path.join(__dirname, '../../marketing/appstore', lang);
  fs.mkdirSync(out, { recursive: true });
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1290, height: 2796 } });
  const errs = [];
  p.on('pageerror', e => errs.push(e.message));
  // App Store order: hero, flight, hotels, workshop, pilot school, rivals, America, holding.
  const order = [1, 2, 3, 6, 7, 4, 5, 8];
  for (const f of fs.readdirSync(out)) if (f.endsWith('.jpg')) fs.unlinkSync(path.join(out, f));
  for (const [i, s] of order.entries()) {
    await p.goto('file://' + path.join(__dirname, 'render.html') + `?s=${s}&lang=${lang}`);
    await p.waitForFunction(() => document.title === 'done', null, { timeout: 60000 });
    await p.locator('#c').screenshot({ path: path.join(out, `${String(i + 1).padStart(2, '0')}.jpg`), type: 'jpeg', quality: 93 });
  }
  console.log('errors', errs);
  await b.close();
})();
