// The Instagram profile-grid panorama (grid.html), English and Turkish: two posts that read as one picture.
//   NODE_PATH=$(npm root -g) node tools/marketing/reels/grid.js <out dir>
// Writes <out>/<lang>/left.png, right.png (1080x1080), left-3x4.png, right-3x4.png (1080x1440, for the 3:4 profile
// grid) and preview.png / preview-3x4.png (both posts side by side with the grid's thin gap).
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const out = path.resolve(process.argv[2] || '.');
(async () => {
  const br = await chromium.launch();
  for (const lang of ['en', 'tr']) {
    const p = await br.newPage({ viewport: { width: 2160, height: 1920 } });
    const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.goto('file://' + path.join(__dirname, 'grid.html'));
    const url = await p.evaluate(l => draw(l), lang);
    const dir = path.join(out, lang); fs.mkdirSync(dir, { recursive: true });
    const full = path.join(dir, 'panorama-full.png'); fs.writeFileSync(full, Buffer.from(url.split(',')[1], 'base64'));
    const miss = await p.evaluate(() => [...MISSING]);
    console.log(lang, errs.length ? errs : 'ok', miss.length ? 'UNTRANSLATED ' + miss : '');
    await p.close();
    execFileSync('python3', ['-I', '-c', `
import sys
from PIL import Image
full, d = sys.argv[1], sys.argv[2]
im = Image.open(full).convert('RGB')
for name, y0, h in (('', 520, 1080), ('-3x4', 340, 1440)):
    L = im.crop((0, y0, 1080, y0 + h)); R = im.crop((1080, y0, 2160, y0 + h))
    L.save(f'{d}/left{name}.png'); R.save(f'{d}/right{name}.png')
    gap = 4; P = Image.new('RGB', (2160 + gap, h), (250, 250, 250)); P.paste(L, (0, 0)); P.paste(R, (1080 + gap, 0)); P.save(f'{d}/preview{name}.png')
`, full, dir]);
    fs.unlinkSync(full);
  }
  await br.close();
})();
