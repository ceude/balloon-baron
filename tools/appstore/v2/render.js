// Renders the v2 App Store screenshots from raw game captures (made by shots.js):
//   NODE_PATH=$(npm root -g) node tools/appstore/v2/shots.js /tmp/raw iphone
//   NODE_PATH=$(npm root -g) node tools/appstore/v2/shots.js /tmp/raw ipad
//   NODE_PATH=$(npm root -g) node tools/appstore/v2/render.js /tmp/raw tr [iphone|ipad]
// Writes marketing/appstore/<lang>-v2/<device>/01.png … (exact App Store sizes, RGB, no alpha) and, for the
// iPhone set, overview.jpg (all screens side by side, to judge the panorama). Captions: captions.js.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');

(async () => {
  const raw = path.resolve(process.argv[2] || '.'), lang = process.argv[3] || 'tr', devs = process.argv[4] ? [process.argv[4]] : ['iphone', 'ipad'];
  const base = process.env.OUT || path.join(__dirname, '../../../marketing/appstore', `${lang}-v2`); /* OUT: somewhere else */
  const b = await chromium.launch();
  for (const dev of devs) {
    const [w, h] = dev === 'ipad' ? [2064, 2752] : [1320, 2868];
    const out = path.join(base, dev); fs.mkdirSync(out, { recursive: true });
    for (const f of fs.readdirSync(out)) if (f.endsWith('.png')) fs.unlinkSync(path.join(out, f));
    const p = await b.newPage({ viewport: { width: w, height: h } });
    const errs = []; p.on('pageerror', e => errs.push(e.message)); p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
    await p.goto('file://' + path.join(__dirname, 'story.html') + `?dev=${dev}&lang=${lang}&raw=${encodeURIComponent('file://' + raw)}`);
    await p.waitForFunction(() => document.title === 'done' || document.title.startsWith('error'), null, { timeout: 300000 });
    const title = await p.title(); if (title !== 'done') throw new Error(title + ' ' + errs.join(' | '));
    const n = await p.evaluate(() => N), files = [];
    for (let i = 0; i < n; i++) {
      await p.evaluate(([i, w]) => { document.getElementById('c').style.transform = `translateX(${-i * w}px)`; }, [i, w]);
      const f = path.join(out, `${String(i + 1).padStart(2, '0')}.png`); files.push(f);
      await p.screenshot({ path: f });
    }
    /* RGB without alpha, with a whisper of noise so the long sky gradients don't band */
    execFileSync('python3', ['-I', path.join(__dirname, 'finish.py'), dev === 'iphone' ? path.join(base, 'overview.jpg') : '-', ...files], { stdio: 'inherit' });
    console.log(dev, n, 'screens', errs.length ? errs : 'no errors');
    await p.close();
  }
  await b.close();
})();
