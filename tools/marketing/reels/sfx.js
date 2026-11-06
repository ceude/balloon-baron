// The reels' sound-effects track, all synthesised here (no samples): every event of REELS[n].sfx (reels.js, the same
// beat timeline as the pictures) becomes a sound at its exact frame, mixed to 48 kHz stereo, normalised to about
// -13 LUFS with true peaks under -1 dBTP, encoded AAC and muxed into the reel (the video stream is copied untouched).
//   node tools/marketing/reels/sfx.js <silent dir> <out dir> [1 2 3]
// reads <silent dir>/reel<n>.mp4, writes <out dir>/reel<n>.mp4 and <out dir>/reel<n>-sfx.wav. The music is added in
// Instagram on top, so the track leaves headroom and keeps to the 120 BPM grid.
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { execFileSync, spawnSync } = require('child_process');
const SR = 48000, FPS = 30;
const [silent, out] = [path.resolve(process.argv[2]), path.resolve(process.argv[3])];
const reels = process.argv.slice(4).length ? process.argv.slice(4) : ['1', '2', '3'];
const FFMPEG = process.env.FFMPEG || 'ffmpeg';

/* the timelines: lib.js and reels.js run here without a page (only their constants and event lists are used) */
const C = { Math, console }; vm.createContext(C);
for (const f of ['lib.js', 'reels.js']) vm.runInContext(fs.readFileSync(path.join(__dirname, f), 'utf8'), C);
const REELS = vm.runInContext('REELS', C);

/* ---------- DSP ---------- */
let seed = 1; const rnd = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647; };
const noise = () => rnd() * 2 - 1;
/* RBJ biquad; type 'lp' | 'hp' | 'bp'; f can change per sample via set() */
function biquad(type, f, q) {
  let b0, b1, b2, a1, a2, x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  const set = (fr, qq = q) => {
    const w = 2 * Math.PI * Math.min(fr, SR * .45) / SR, al = Math.sin(w) / (2 * qq), c = Math.cos(w), a0 = 1 + al;
    if (type === 'lp') { b0 = (1 - c) / 2; b1 = 1 - c; b2 = (1 - c) / 2; }
    else if (type === 'hp') { b0 = (1 + c) / 2; b1 = -(1 + c); b2 = (1 + c) / 2; }
    else { b0 = al; b1 = 0; b2 = -al; }
    b0 /= a0; b1 /= a0; b2 /= a0; a1 = -2 * c / a0; a2 = (1 - al) / a0;
  };
  set(f);
  const run = x => { const y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2; x2 = x1; x1 = x; y2 = y1; y1 = y; return y; };
  run.set = set; return run;
}
const env = (t, a, d) => t < 0 ? 0 : t < a ? t / a : Math.exp(-(t - a) / d);
/* every sound is a function (o) => { L, R } of Float32Arrays starting at the hit */
function buf(sec) { const n = Math.ceil(sec * SR); return { L: new Float32Array(n), R: new Float32Array(n), n }; }
function mono(sec, fn, pan = 0) {
  const b = buf(sec), gl = Math.cos((pan + 1) * Math.PI / 4), gr = Math.sin((pan + 1) * Math.PI / 4);
  for (let i = 0; i < b.n; i++) { const v = fn(i / SR, i); b.L[i] = v * gl * 1.41; b.R[i] = v * gr * 1.41; }
  return b;
}

const S = {
  /* 808 kick: a sine dropping from 160 Hz to 42 Hz, a click on top, and a long sub tail */
  kick(o) {
    let ph = 0; const click = biquad('hp', 2000, .7);
    return mono(.7, t => {
      const f = 42 + 118 * Math.exp(-t / .035); ph += 2 * Math.PI * f / SR;
      return Math.sin(ph) * env(t, .002, .22) * .95 + click(noise()) * env(t, 0, .004) * .5;
    });
  },
  /* a slam: the kick, a sub drop underneath and a short, dark noise thump */
  boom(o) {
    let ph = 0, ph2 = 0; const lp = biquad('lp', 400, .8), dist = x => Math.tanh(x * 1.6) / Math.tanh(1.6);
    const b = mono(1.6, t => {
      const f = 45 + 135 * Math.exp(-t / .04); ph += 2 * Math.PI * f / SR;
      const fs = 58 * Math.exp(-t / .9) + 26; ph2 += 2 * Math.PI * fs / SR;
      return dist(Math.sin(ph) * env(t, .002, .28) + Math.sin(ph2) * env(t, .01, .55) * .55) * .9 + lp(noise()) * env(t, .001, .06) * .9;
    });
    return b;
  },
  /* clap: three quick bursts of band-passed noise and a short tail */
  clap(o) {
    const bpL = biquad('bp', 1200, .9), bpR = biquad('bp', 1350, .9), b = buf(.45);
    for (let i = 0; i < b.n; i++) {
      const t = i / SR; let e = 0;
      for (const d of [0, .011, .022]) e = Math.max(e, env(t - d, .0008, .006));
      e = Math.max(e, env(t - .03, .001, .09) * .7);
      b.L[i] = bpL(noise()) * e * 2.2; b.R[i] = bpR(noise()) * e * 2.2;
    }
    return b;
  },
  /* snare: a 190 Hz body and bright noise */
  snare(o) {
    let ph = 0; const hp = biquad('hp', 1800, .7), bp = biquad('bp', 4000, .6);
    return mono(.4, t => { ph += 2 * Math.PI * (190 + 60 * Math.exp(-t / .01)) / SR; return Math.sin(ph) * env(t, .001, .05) * .7 + (hp(noise()) * .6 + bp(noise()) * .5) * env(t, .001, .11); });
  },
  /* whoosh: noise through a band-pass sweeping up then down, panning across */
  whoosh(o) {
    const len = o.short ? .32 : .55, bL = biquad('bp', 300, 1.2), bR = biquad('bp', 300, 1.2), b = buf(len);
    for (let i = 0; i < b.n; i++) {
      const t = i / SR, k = t / len, e = Math.sin(Math.PI * Math.pow(k, o.rev ? .4 : .7)) ** 2;
      const f = 250 * Math.pow(18, Math.sin(Math.PI * k)); bL.set(f, 1.4); bR.set(f * 1.08, 1.4);
      const pan = (k * 2 - 1) * .8, n1 = noise(), n2 = noise();
      b.L[i] = bL(n1) * e * (1 - pan) * 1.3; b.R[i] = bR(n2) * e * (1 + pan) * 1.3;
    }
    return b;
  },
  /* riser: noise and a detuned saw sweeping up over o.len frames, ending on the hit (placed before it) */
  riser(o) {
    const len = o.len / FPS, b = buf(len), bL = biquad('bp', 400, 2), bR = biquad('bp', 400, 2); let p1 = 0, p2 = 0;
    for (let i = 0; i < b.n; i++) {
      const t = i / SR, k = t / len, e = Math.pow(k, 2.2) * (k > .97 ? (1 - k) / .03 : 1), f = 200 * Math.pow(30, k);
      bL.set(f, 3); bR.set(f * 1.03, 3);
      const fs = 80 * Math.pow(6, k); p1 += fs / SR; p2 += fs * 1.007 / SR;
      const saw = o.air ? 0 : ((p1 % 1) * 2 - 1 + (p2 % 1) * 2 - 1) * .12;
      b.L[i] = (bL(noise()) * 1.4 + saw) * e; b.R[i] = (bR(noise()) * 1.4 + saw) * e;
    }
    b.pre = b.n; return b;
  },
  /* coin: two bell partials, a little brighter as the counter runs (o.p) */
  coin(o) {
    const f = 1650 * (o.p || 1); let a = 0, c = 0;
    return mono(.16, t => { a += 2 * Math.PI * f / SR; c += 2 * Math.PI * f * 1.5 / SR; return (Math.sin(a) * .6 + Math.sin(c) * .4) * env(t, .0005, .035) * .55; }, (rnd() - .5) * .6);
  },
  /* cash register: a drawer clunk, a rattle of coins and a bright two-tone bell */
  kaching(o) {
    const lp = biquad('lp', 900, .9), hp = biquad('hp', 5000, .7); let a = 0, b2 = 0, c = 0;
    const b = mono(1.1, t => {
      a += 2 * Math.PI * 2093 / SR; b2 += 2 * Math.PI * 3136 / SR; c += 2 * Math.PI * 4186 / SR;
      const bell = t > .06 ? (Math.sin(a) * .5 + Math.sin(b2) * .35 + Math.sin(c) * .15) * env(t - .06, .001, .3) : 0;
      let rattle = 0; for (let k = 0; k < 6; k++) rattle += env(t - .02 - k * .017, .0005, .006);
      return bell * .8 + lp(noise()) * env(t, .001, .03) * .9 + hp(noise()) * rattle * .45;
    });
    return b;
  },
  /* burner: a roaring band of low noise with a quick attack and flutter */
  fwoosh(o) {
    const lL = biquad('lp', 700, .7), lR = biquad('lp', 760, .7), hp = biquad('hp', 60, .7), b = buf(1.1);
    for (let i = 0; i < b.n; i++) {
      const t = i / SR, e = env(t, .07, .35) * (1 + .25 * Math.sin(t * 2 * Math.PI * 23)), f = 500 + 900 * Math.exp(-t / .25);
      lL.set(f, .9); lR.set(f * 1.05, .9);
      b.L[i] = hp(lL(noise())) * e * 2.4; b.R[i] = lR(noise()) * e * 2.4;
    }
    return b;
  },
  /* record scratch: a buzzy grain played forwards then yanked back */
  scratch(o) {
    let ph = 0; const bp = biquad('bp', 1500, 1.5), len = .32;
    return mono(len, t => {
      const k = t / len, sp = k < .45 ? .35 + .65 * Math.sin(k / .45 * Math.PI) : -Math.sin((k - .45) / .55 * Math.PI) * 1.4;
      ph += sp * 900 / SR; const src = Math.sin(ph * 2 * Math.PI * 1.0) * .5 + Math.sin(ph * 2 * Math.PI * 2.7) * .3 + noise() * .4;
      bp.set(800 + Math.abs(sp) * 2500, 1.4); return bp(src) * Math.abs(sp) * 2.2 * env(t, .004, .5);
    });
  },
  /* the comedic "bwomp": a muted brass wah sliding down, with vibrato */
  bwomp(o) {
    let ph = 0; const lp = biquad('lp', 600, 2.5), len = .9;
    return mono(len, t => {
      const k = t / len, f = 233 * Math.pow(.62, k) * (1 + .025 * Math.sin(t * 2 * Math.PI * 6 * k)); ph += f / SR;
      const saw = (ph % 1) * 2 - 1; lp.set(300 + 1600 * Math.sin(Math.PI * Math.min(1, k * 1.6)) * (1 - k * .5), 3);
      return lp(saw) * (k < .04 ? k / .04 : k > .8 ? (1 - k) / .2 : 1) * .7;
    });
  },
  /* a building popping up: a low thud, a metal clank (inharmonic partials), a short rising scrape and dust */
  build(o) {
    let ph = 0; const parts = [[620, .5], [987, .35], [1530, .25], [2210, .15]], lp = biquad('lp', 1200, .7), bp = biquad('bp', 900, 3);
    return mono(.6, t => {
      ph += 2 * Math.PI * (55 + 70 * Math.exp(-t / .03)) / SR;
      let clank = 0; if (t > .015) for (const [f, a] of parts) clank += Math.sin(2 * Math.PI * f * (t - .015)) * a * env(t - .015, .0005, .07 + f / 30000);
      bp.set(500 + 2500 * Math.min(1, t / .12), 3);
      return Math.sin(ph) * env(t, .002, .09) * .9 + clank * .55 + bp(noise()) * env(t, .01, .05) * .5 + lp(noise()) * env(t, .002, .12) * .35;
    }, (rnd() - .5) * .5);
  },
  /* clock: tick high, tock lower */
  tick(o) { let a = 0; return mono(.05, t => { a += 2 * Math.PI * 3200 / SR; return Math.sin(a) * env(t, .0003, .007) * .8 + noise() * env(t, 0, .002) * .3; }, .3); },
  tock(o) { let a = 0; return mono(.06, t => { a += 2 * Math.PI * 2100 / SR; return Math.sin(a) * env(t, .0003, .009) * .8 + noise() * env(t, 0, .002) * .3; }, -.3); },
  pop(o) { let a = 0; return mono(.12, t => { a += 2 * Math.PI * (400 + 900 * Math.exp(-t / .02)) / SR; return Math.sin(a) * env(t, .001, .03) * .7; }); },
  ding(o) { let a = 0, b2 = 0; return mono(1.2, t => { a += 2 * Math.PI * 1568 / SR; b2 += 2 * Math.PI * 2352 / SR; return (Math.sin(a) * .6 + Math.sin(b2) * .3) * env(t, .002, .35) * .7; }); },
  /* shimmer: a fast rising arpeggio of soft bells across the stereo field */
  shimmer(o) {
    const b = buf(2.2), notes = o.low ? [523, 659, 784, 1047, 1319, 1568] : [1047, 1319, 1568, 2093, 2637, 3136, 4186];
    notes.forEach((f, j) => {
      const d = j * .045, pan = (j / (notes.length - 1)) * 1.6 - .8, gl = Math.cos((pan + 1) * Math.PI / 4), gr = Math.sin((pan + 1) * Math.PI / 4);
      for (let i = Math.floor(d * SR); i < b.n; i++) { const t = i / SR - d, v = Math.sin(2 * Math.PI * f * t) * env(t, .004, .55) * .22 * (1 + .3 * Math.sin(t * 30)); b.L[i] += v * gl; b.R[i] += v * gr; }
    });
    return b;
  },
  /* Victor's laugh: formant-synthesised "ha"s. A glottal source (harmonics with a 1/k roll-off, falling pitch, jitter)
     and a breathy "h" through three resonators tuned to an open "a" (F1 760, F2 1180, F3 2550 Hz). */
  laugh(o) {
    const n = o.n || 3, gap = (o.gap || 7) / FPS, b = buf(gap * n + .5);
    for (let s = 0; s < n; s++) {
      const t0 = s * gap, f0 = 168 * (1.12 - s * .06) * (o.pitch || 1), dur = Math.min(.2, gap * .82), start = Math.floor(t0 * SR);
      const F = [[760, 9], [1180, 10], [2550, 14]].map(([f, q]) => biquad('bp', f, q)), Fn = [[760, 4], [1180, 5], [2550, 6]].map(([f, q]) => biquad('bp', f, q));
      let ph = 0;
      for (let i = 0; i < (dur + .08) * SR && start + i < b.n; i++) {
        const t = i / SR, h = t < .045;                                  /* the "h", then the voiced "a" */
        const f = f0 * (1 + .18 * Math.exp(-t / .03) - .22 * t / dur) * (1 + .01 * noise());
        ph += f / SR; let src = 0;
        for (let k = 1; k <= 22; k++) { if (k * f > 5000) break; src += Math.sin(2 * Math.PI * k * ph) / k; }
        const voiced = t < .03 ? 0 : Math.min(1, (t - .03) / .02) * (t > dur ? Math.exp(-(t - dur) / .025) : 1);
        const breath = noise() * (h ? .9 : .18) * (t < .01 ? t / .01 : 1);
        let v = 0; F.forEach((fl, j) => { v += fl(src * voiced) * [1, .75, .35][j]; });
        let a = 0; Fn.forEach((fl, j) => { a += fl(breath * (t > dur ? Math.exp(-(t - dur) / .02) : 1)) * [1, .7, .5][j]; });
        const val = (v * 1.6 + a * .9) * .9, pan = (s % 2 ? .12 : -.12);
        b.L[start + i] += val * (1 - pan); b.R[start + i] += val * (1 + pan);
      }
    }
    return b;
  },
};
/* sound levels in the mix (before normalising) */
const LEVEL = { build: .7, boom: 1, kick: .85, clap: .55, snare: .6, whoosh: .45, riser: .4, coin: .35, kaching: .55, fwoosh: .55, scratch: .6, bwomp: .6, tick: .3, tock: .3, pop: .4, ding: .4, shimmer: .45, laugh: 1.6 };
/* a short room on a send, for claps, the laugh, bells */
const SEND = { build: .15, clap: .25, snare: .2, laugh: .22, ding: .35, shimmer: .4, kaching: .25, pop: .2, bwomp: .2 };
function room(L, R) {
  const mk = (d, fb) => { const z = new Float32Array(Math.round(d * SR)); let i = 0, lp = 0; return x => { const y = z[i]; lp = y * .6 + lp * .4; z[i] = x + lp * fb; i = (i + 1) % z.length; return y; }; };
  const cl = [.0297, .0371, .0411, .0437].map(d => mk(d, .78)), cr = [.0307, .0353, .0423, .0451].map(d => mk(d, .78));
  const ap = (d, g) => { const z = new Float32Array(Math.round(d * SR)); let i = 0; return x => { const y = z[i], v = x + y * g; z[i] = v; i = (i + 1) % z.length; return y - v * g; }; };
  const al = [ap(.005, .5), ap(.0017, .5)], ar = [ap(.0053, .5), ap(.0019, .5)];
  for (let i = 0; i < L.length; i++) {
    let l = 0, r = 0; for (const c of cl) l += c(L[i]); for (const c of cr) r += c(R[i]);
    for (const a of al) l = a(l); for (const a of ar) r = a(r); L[i] = l * .25; R[i] = r * .25;
  }
}

function writeWav(file, L, R) {
  const n = L.length, b = Buffer.alloc(44 + n * 8);
  b.write('RIFF', 0); b.writeUInt32LE(36 + n * 8, 4); b.write('WAVE', 8); b.write('fmt ', 12); b.writeUInt32LE(16, 16); b.writeUInt16LE(3, 20); b.writeUInt16LE(2, 22);
  b.writeUInt32LE(SR, 24); b.writeUInt32LE(SR * 8, 28); b.writeUInt16LE(8, 32); b.writeUInt16LE(32, 34); b.write('data', 36); b.writeUInt32LE(n * 8, 40);
  for (let i = 0; i < n; i++) { b.writeFloatLE(L[i], 44 + i * 8); b.writeFloatLE(R[i], 48 + i * 8); }
  fs.writeFileSync(file, b);
}

fs.mkdirSync(out, { recursive: true });
for (const n of reels) {
  const R = REELS[n], len = Math.round(R.frames / FPS * SR);
  const L = new Float32Array(len), Rr = new Float32Array(len), sL = new Float32Array(len), sR = new Float32Array(len);
  seed = 1000 + +n;
  const map = [];
  for (const [f, name, o = {}] of R.sfx.slice().sort((a, b) => a[0] - b[0])) {
    const s = S[name](o), g = (o.g ?? 1) * LEVEL[name], at = Math.round(f / FPS * SR) - (s.pre || 0), send = SEND[name] || 0;
    for (let i = 0; i < s.n; i++) { const j = at + i; if (j < 0 || j >= len) continue; L[j] += s.L[i] * g; Rr[j] += s.R[i] * g; if (send) { sL[j] += s.L[i] * g * send; sR[j] += s.R[i] * g * send; } }
    map.push(`${(f / FPS).toFixed(2).padStart(6)}s  f${String(f).padStart(3)}  ${name}${o.n ? ' x' + o.n : ''}${o.len ? ` (from ${((f - o.len) / FPS).toFixed(2)}s)` : ''}`);
  }
  room(sL, sR); for (let i = 0; i < len; i++) { L[i] += sL[i]; Rr[i] += sR[i]; }
  /* a 4 ms fade in (a hit on the very first sample makes the AAC encoder overshoot) and a fade out at the end */
  for (let i = 0; i < SR * .004; i++) { const k = i / (SR * .004); L[i] *= k; Rr[i] *= k; }
  for (let i = 0; i < SR * .05; i++) { const k = i / (SR * .05); L[len - 1 - i] *= k; Rr[len - 1 - i] *= k; }
  const raw = path.join(out, `reel${n}-sfx-raw.wav`), wav = path.join(out, `reel${n}-sfx.wav`);
  writeWav(raw, L, Rr);
  /* loudness: measure, then normalise linearly to -13 LUFS, then a true-peak-safe limiter (-1.5 dBFS at 4x) */
  const m = spawnSync(FFMPEG, ['-hide_banner', '-i', raw, '-af', 'loudnorm=I=-13:TP=-1.5:LRA=20:print_format=json', '-f', 'null', '-']).stderr.toString();
  let meas; try { meas = JSON.parse(m.slice(m.lastIndexOf('{'), m.lastIndexOf('}') + 1)); } catch (e) { meas = null; }
  const gain = meas ? -13 - +meas.input_i : 0;
  execFileSync(FFMPEG, ['-y', '-loglevel', 'error', '-i', raw, '-af', `highpass=f=28:p=2,volume=${gain.toFixed(2)}dB,aresample=192000,alimiter=limit=0.79:attack=1:release=60:level=false,aresample=48000`, '-c:a', 'pcm_f32le', wav]);
  fs.unlinkSync(raw);
  const mp4 = path.join(out, `reel${n}.mp4`);
  execFileSync(FFMPEG, ['-y', '-loglevel', 'error', '-i', path.join(silent, `reel${n}.mp4`), '-i', wav, '-map', '0:v:0', '-map', '1:a:0', '-c:v', 'copy',
    '-c:a', 'aac', '-b:a', '320k', '-ar', '48000', '-ac', '2', '-movflags', '+faststart', '-shortest', mp4]);
  fs.writeFileSync(path.join(out, `reel${n}-sfx-map.txt`), map.join('\n') + '\n');
  console.log(`reel ${n}: ${R.sfx.length} sounds, measured ${meas ? meas.input_i : '?'} LUFS raw, gain ${gain.toFixed(1)} dB -> ${mp4}`);
}
