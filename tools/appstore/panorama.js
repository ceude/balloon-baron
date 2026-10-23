// App Store screens with big balloons running across them:
// NODE_PATH=$(npm root -g) node tools/appstore/panorama.js <raw dir from shots.js> [tr]
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

(async () => {
  const raw = path.resolve(process.argv[2] || '.'), lang = process.argv[3] || 'tr';
  const out = path.join(__dirname, '../../marketing/appstore', lang);
  fs.mkdirSync(out, { recursive: true });
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1290, height: 2796 } });
  const errs = [];
  p.on('pageerror', e => errs.push(e.message));
  // The going-global phone: render.html's Cappadocia-to-Albuquerque picture without its text.
  await p.goto('file://' + path.join(__dirname, 'render.html') + `?s=5&lang=${lang}&bare`);
  await p.waitForFunction(() => document.title === 'done', null, { timeout: 60000 });
  await p.locator('#c').screenshot({ path: path.join(raw, 'raw-abq-flight.png') });
  await p.goto('file://' + path.join(__dirname, 'panorama.html') + `?lang=${lang}&raw=${encodeURIComponent('file://' + raw)}`);
  await p.waitForFunction(() => document.title === 'done' || document.title.startsWith('error'), null, { timeout: 180000 });
  const title = await p.title();
  if (title !== 'done') throw new Error(title);
  for (const f of fs.readdirSync(out)) if (f.endsWith('.jpg')) fs.unlinkSync(path.join(out, f));
  const n = await p.evaluate(() => N);
  for (let i = 0; i < n; i++) {
    await p.evaluate(i => { document.getElementById('c').style.transform = `translateX(${-i * 1290}px)`; }, i);
    await p.screenshot({ path: path.join(out, `${String(i + 1).padStart(2, '0')}.jpg`), type: 'jpeg', quality: 92 });
  }
  console.log('errors', errs);
  await b.close();
})();
