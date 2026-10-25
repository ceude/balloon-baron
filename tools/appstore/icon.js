// Usage: NODE_PATH=$(npm root -g) node tools/appstore/icon.js   -> the app icon (concept 1 of icon.html) at 1024×1024
// icon.html holds all six concepts from the October 2026 icon round (?i=1..6); the app uses 1.
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1024, height: 1024 } });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.goto('file://' + path.join(__dirname, 'icon.html') + '?i=1');
  await p.waitForFunction(() => document.title === 'done', null, { timeout: 60000 });
  const out = path.join(__dirname, '../../BalloonBaron/Assets.xcassets/AppIcon.appiconset/AppIcon.png');
  await p.locator('#c').screenshot({ path: out, omitBackground: false });
  console.log(out, errs);
  await b.close();
})();
