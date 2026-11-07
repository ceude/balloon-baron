/* App Preview v3: 25 s (50 beats at 120 BPM) of real app footage only (store-shots.yml video clips), cut on the
   beat, with kinetic captions, a synthesised music bed and sound effects. Apple's rules for app previews (2.3.4):
   only captures of the app itself, no device frames, no hands, nothing drawn that isn't in the app, no prices,
   no "free". This file is the timeline: draw.js draws it, sfx.js (tools/marketing/reels) sounds it.
   A shot: [from beat, to beat, clip, clip start (s), speed, zoom from, zoom to, focus x, focus y, caption, accent]. */
const PV_TEXT = {
  en: {
    dawn: ['FLY AT', '*DAWN*'], wind: ['CATCH THE', '*WIND*'], one: ['START WITH', '*ONE BASKET*'], fill: ['FILL EVERY', '*BASKET*'],
    fleet: ['BUILD YOUR', '*FLEET*'], n164: '164 BALLOONS', cash: ['CASH', '*ROLLS IN*'], empire: ['GROW A', '*WORLD EMPIRE*'],
    regions: ['*5* REGIONS'], safari: ['SAFARI AT', '*SUNRISE*'], night: ['LIGHT UP', 'THE *NIGHT*'],
    cities: ['ALBUQUERQUE', 'LUXOR', 'BRISTOL', 'MAASAI MARA'],
    title: 'BALLOON BARON', sub: 'CAPPADOCIA', pill: 'NO ADS', line: 'No energy timers.',
  },
  tr: {
    dawn: ['ŞAFAKTA', '*UÇ*'], wind: ['RÜZGÂRI', '*YAKALA*'], one: ['TEK SEPETLE', '*BAŞLA*'], fill: ['HER SEPETİ', '*DOLDUR*'],
    fleet: ['FİLONU', '*BÜYÜT*'], n164: '164 BALON', cash: ['KASA', '*DOLSUN*'], empire: ['HOLDİNGİNİ', '*KUR*'],
    regions: ['*5* BÖLGE'], safari: ['SAFARİDE', '*GÜNDOĞUMU*'], night: ['GECEYİ', '*AYDINLAT*'],
    cities: ['ALBUQUERQUE', 'LUKSOR', 'BRİSTOL', 'MAASAI MARA'],
    title: 'BALON BARONU', sub: 'KAPADOKYA', pill: 'REKLAMSIZ', line: 'Enerji beklemesi yok.',
  },
};
const PV_SHOTS = [
  [0, 4, 'dawn', 0.6, 1, 1.45, 1.2, .5, .62, 'dawn'],
  [4, 8, 'dawn', 6.0, 1, 1.75, 1.5, .5, .55, 'wind'],
  [8, 10, 'early', 1.0, 1, 1.3, 1.2, .5, .5, 'one'],
  [10, 14, 'collect164', 1.2, 1, 1.15, 1.35, .5, .62, 'fill'],
  [14, 18, 'empire', 1.0, 1, 1.5, 1.05, .5, .48, 'fleet'],
  [18, 22, 'auto164', 2.0, 1, 1.2, 1.4, .5, .62, 'cash'],
  [22, 26, 'holding', 1.0, 1, 1.25, 1.1, .5, .45, 'empire'],
  [26, 30, 'map', 1.0, 1, 1.1, 1.3, .5, .3, 'regions'],
  [30, 31, 'abq', 1.0, 1, 1.4, 1.3, .5, .5, 'city0'],
  [31, 32, 'lux', 1.0, 1, 1.4, 1.3, .5, .5, 'city1'],
  [32, 33, 'bri', 1.0, 1, 1.4, 1.3, .5, .5, 'city2'],
  [33, 34, 'mara', 1.0, 1, 1.4, 1.3, .5, .5, 'city3'],
  [34, 38, 'maraflight', 1.5, 1, 1.5, 1.3, .5, .6, 'safari'],
  [38, 44, 'show', 0, 1, 1.15, 1.3, .5, .4, 'night'],
  [44, 50, 'show', 6, 1, 1.3, 1.4, .5, .4, 'end'],
];
/* the sound: a whoosh on every cut, a boom under every caption, ticks on the counters, a shimmer on the end card */
const PV_SFX = (() => {
  const ev = [[0, 'boom', { g: 1.2 }], [0, 'fwoosh', { g: .9 }]];
  PV_SHOTS.forEach(([a, b, clip, , , , , , , cap], k) => {
    if (k) ev.push([B(a), 'whoosh', { g: a >= 30 && a < 34 ? .45 : .7, short: a >= 30 && a < 34 ? 1 : 0 }]);
    if (cap && cap !== 'end' && !cap.startsWith('city')) ev.push([B(a), k ? 'boom' : 'kick', { g: k ? .9 : .8 }], [B(a) + 6, 'clap', { g: .7 }]);
    if (cap && cap.startsWith('city')) ev.push([B(a), 'kick', { g: .7 }], [B(a), 'pop']);
  });
  ev.push([B(2), 'fwoosh', { g: .6 }], [B(5), 'fwoosh', { g: .6 }], [B(6), 'fwoosh', { g: .5 }]);   /* the burner */
  for (let f = B(11); f < B(13.5); f += 3) ev.push([f, 'coin', { g: .35, p: 1 + (f - B(11)) / B(3) * .3 }]); /* seats filling */
  ev.push([B(16), 'boom', { g: 1 }], [B(16), 'shimmer', { g: .5 }]);                                       /* 164 balloons */
  for (let f = B(19); f < B(21.5); f += 3) ev.push([f, 'coin', { g: .35, p: 1 + (f - B(19)) / B(3) * .3 }]);
  ev.push([B(21.5), 'kaching']);
  ev.push([B(26), 'riser', { len: B(2) }]);                                                               /* into 5 REGIONS */
  ev.push([B(34), 'fwoosh', { g: .7 }], [B(36), 'fwoosh', { g: .6 }]);
  ev.push([B(38), 'shimmer', { g: .6, low: 1 }]);
  ev.push([B(44), 'riser', { len: B(2) }], [B(44), 'boom', { g: 1.1 }], [B(44) + 5, 'clap'], [B(45), 'shimmer'], [B(46), 'ding']);
  return ev;
})();
const PREVIEW = { frames: B(50), sfx: PV_SFX, music: true, lufs: -16 };
