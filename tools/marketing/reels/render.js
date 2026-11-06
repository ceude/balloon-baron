// Renders the Instagram reels frame by frame (deterministic, no real-time recording) and encodes them with ffmpeg:
// 1080x1920, 30 fps, H.264 yuv420p, faststart, no audio (the music is added in Instagram; cuts sit on a 120 BPM grid).
//   NODE_PATH=$(npm root -g) node tools/marketing/reels/capture.js <raw>            (gameplay clips, see there)
//   NODE_PATH=$(npm root -g) node tools/marketing/reels/render.js <raw> <out dir> [1 2 3]
// STILLS=0,45,300 writes those frames as JPEGs (<out>/still-<reel>-<f>.jpg) instead of a video; COVER=f1,f2,f3 a PNG per reel.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const ROOT = path.resolve(__dirname, '../../..');
const raw = path.resolve(process.argv[2]), out = path.resolve(process.argv[3]), reels = process.argv.slice(4).length ? process.argv.slice(4) : ['1', '2', '3'];
const FFMPEG = process.env.FFMPEG || 'ffmpeg';
fs.mkdirSync(out, { recursive: true });
const clipsDir = path.join(raw, 'clips');
const counts = Object.fromEntries(fs.readdirSync(clipsDir).map(d => [d, fs.readdirSync(path.join(clipsDir, d)).filter(f => f.endsWith('.jpg')).length]));
const proto = fs.readFileSync(path.join(ROOT, 'prototype/balloon-baron.html'), 'utf8');
const world = proto.match(/const WORLD_SVG = `<svg[^>]*><path d="([^"]+)"/)[1];
const stills = process.env.STILLS ? process.env.STILLS.split(',').map(Number) : null;
/* COVER=f1,f2,f3: the cover picture of each reel (in the order of the reels asked for), as reel<n>-cover.png */
const covers = process.env.COVER ? process.env.COVER.split(',').map(Number) : null;

(async () => {
  const br = await chromium.launch({ args: ['--allow-file-access-from-files'] });
  for (const n of reels) {
    const p = await br.newPage({ viewport: { width: 1080, height: 1920 } });
    const errs = []; p.on('pageerror', e => errs.push(e.message)); p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
    await p.goto('file://' + path.join(__dirname, 'reels.html'));
    const frames = await p.evaluate(([n, d, c, w]) => init(+n, d, c, w), [n, 'file://' + clipsDir, counts, world]);
    if (covers) {
      const url = await p.evaluate(f => frame(f, 'png'), covers[reels.indexOf(n)]);
      fs.writeFileSync(path.join(out, `reel${n}-cover.png`), Buffer.from(url.split(',')[1], 'base64'));
      console.log('reel', n, 'cover', errs); await p.close(); continue;
    }
    if (stills) {
      for (const f of stills) {
        const url = await p.evaluate(f => frame(f, 1), f);
        fs.writeFileSync(path.join(out, `still-${n}-${String(f).padStart(3, '0')}.jpg`), Buffer.from(url.split(',')[1], 'base64'));
      }
      console.log('reel', n, 'stills', stills.join(','), errs);
      await p.close(); continue;
    }
    const file = path.join(out, `reel${n}.mp4`);
    const ff = spawn(FFMPEG, ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', '30', '-c:v', 'mjpeg', '-i', '-',
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-profile:v', 'high', '-level', '4.1', '-pix_fmt', 'yuv420p', '-r', '30', '-movflags', '+faststart', '-an', file], { stdio: ['pipe', 'inherit', 'inherit'] });
    const t0 = Date.now();
    for (let f = 0; f < frames; f++) {
      const url = await p.evaluate(f => frame(f), f);
      const buf = Buffer.from(url.split(',')[1], 'base64');
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
      if (f % 60 === 0) process.stdout.write(`reel ${n} frame ${f}/${frames} ${((Date.now() - t0) / 1000).toFixed(0)}s\n`);
    }
    ff.stdin.end(); await new Promise(r => ff.on('close', r));
    console.log('wrote', file, frames, 'frames', errs.length ? errs : 'no errors');
    await p.close();
  }
  await br.close();
})();
