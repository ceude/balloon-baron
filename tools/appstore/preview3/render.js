// App Preview v3: renders the preview (preview.html, timeline.js) from the real app's clips and encodes it to
// Apple's spec: iPhone 886x1920, iPad 1200x1600, 30 fps, H.264 High, yuv420p; then sfx.js adds the music and effects.
//   python3 tools/appstore/preview3/prep.py <store-raw checkout> <clips dir>         (the app's videos as frames)
//   NODE_PATH=$(npm root -g) node tools/appstore/preview3/render.js <clips dir> <out dir> [en-iphone tr-ipad …]
//   TIMELINE=tools/appstore/preview3/timeline.js NAMES=en-iphone,… node tools/marketing/reels/sfx.js <out>/silent <out>
// Writes <out>/silent/<lang>-<device>.mp4 and <out>/<lang>-<device>-poster.png. STILLS=0,30 writes JPEG stills instead.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const clipsRoot = path.resolve(process.argv[2]), out = path.resolve(process.argv[3]);
const jobs = process.argv.slice(4).length ? process.argv.slice(4) : ['en-iphone', 'en-ipad', 'tr-iphone', 'tr-ipad'];
const stills = process.env.STILLS ? process.env.STILLS.split(',').map(Number) : null;
const POSTER = +(process.env.POSTER || 30);
fs.mkdirSync(path.join(out, 'silent'), { recursive: true });
(async () => {
  const br = await chromium.launch({ args: ['--allow-file-access-from-files'] });
  for (const job of jobs) {
    const [lang, dev] = job.split('-'), dir = path.join(clipsRoot, lang, dev);
    const counts = Object.fromEntries(fs.readdirSync(dir).filter(d => fs.statSync(path.join(dir, d)).isDirectory()).map(d => [d, fs.readdirSync(path.join(dir, d)).length]));
    const [w, h] = dev === 'ipad' ? [1200, 1600] : [886, 1920];
    const p = await br.newPage({ viewport: { width: w, height: h } });
    const errs = []; p.on('pageerror', e => errs.push(e.message)); p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
    await p.goto('file://' + path.join(__dirname, 'preview.html'));
    const frames = await p.evaluate(([l, d, c, n]) => init(l, d, c, n), [lang, dev, 'file://' + dir, counts]);
    if (stills) {
      for (const f of stills) { const u = await p.evaluate(f => frame(f, 1), f); fs.writeFileSync(path.join(out, `still-${job}-${String(f).padStart(3, '0')}.jpg`), Buffer.from(u.split(',')[1], 'base64')); }
      console.log(job, 'stills', errs); await p.close(); continue;
    }
    const poster = await p.evaluate(f => frame(f, 'png'), POSTER);
    fs.writeFileSync(path.join(out, `${job}-poster.png`), Buffer.from(poster.split(',')[1], 'base64'));
    const file = path.join(out, 'silent', `${job}.mp4`);
    const ff = spawn(process.env.FFMPEG || 'ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', '30', '-c:v', 'mjpeg', '-i', '-',
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '17', '-profile:v', 'high', '-level', '4.0', '-pix_fmt', 'yuv420p', '-r', '30', '-maxrate', '10M', '-bufsize', '20M', '-movflags', '+faststart', '-an', file], { stdio: ['pipe', 'inherit', 'inherit'] });
    for (let f = 0; f < frames; f++) {
      const u = await p.evaluate(f => frame(f), f), buf = Buffer.from(u.split(',')[1], 'base64');
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
      if (f % 150 === 0) console.log(job, f, '/', frames);
    }
    ff.stdin.end(); await new Promise(r => ff.on('close', r));
    console.log('wrote', file, errs.length ? errs : 'no errors');
    await p.close();
  }
  await br.close();
})();
