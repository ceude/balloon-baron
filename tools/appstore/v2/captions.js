/* Every word on the v2 App Store screenshots, one table per language. To add a language, copy the `tr` block,
   translate it, and run `node tools/appstore/v2/render.js <raw dir> <lang>`. Headlines are written in normal case;
   the page upper-cases them with the language's own rules (Turkish i → İ). `|` breaks a headline line.
   Apple indexes the words on screenshots, so the headlines and lines carry the search terms on purpose.
   The badge figures are the real values on the captured game screens (shots.js): change them only together with
   the captures, and write them the way the language writes numbers. */
const CAPTIONS = {
  tr: {
    locale: 'tr-TR',
    brand: ['Balon Baronu', 'Kapadokya'],
    noAds: 'Reklamsız',
    /* the four cities on screen 2, top to bottom */
    cities: { cap: ['Kapadokya', 'Türkiye'], lux: ['Luksor', 'Mısır'], bri: ['Bristol', 'İngiltere'], abq: ['Albuquerque', 'ABD'] },
    badges: {
      idle: [['+€146.644', 'tek günde'], ['164', 'balonluk filo']],   /* the run's day 135, the hangar's 164 balloons */
      holding: { before: ['Gün 2', '1', 'balon'], after: ['Gün 131', '164', 'balon'] },
      rivals: ['%98', 'pazar payı'],
    },
    /* the App Preview's captions, one per scene in preview.js's order; the end card uses brand and noAds */
    preview: ['Şafakta|dümen sende', 'Balon|işletmecisi ol', 'Günler akar|kasa dolar', 'Dört şehir|tek imparatorluk', 'Geceleri|ışıl ışıl', 'Gece göğünde|dev gösteri'],
    screens: {
      hero: { head: 'Balon|işletmecisi ol', sub: 'Tek balondan dev filoya' },
      cities: { head: 'Dört şehir|tek imparatorluk', sub: 'Kapadokya’dan Balloon Fiesta’ya' },
      flight: { head: 'Şafakta|dümen sende', sub: 'Gerçekçi sıcak hava balonu uçuşu' },
      idle: { head: 'Günler akar|kasa dolar', sub: 'Otomatik ilerletmeli idle tycoon' },
      holding: { head: 'Tek sepetten|holdinge', sub: 'Gün 2’den Gün 131’e' },
      crew: { head: 'Her pilot|bir karakter', sub: 'Temkinli, gözü kara, sadık' },
      design: { head: 'Balonun|imzan olsun', sub: 'Kalp, yıldız, kurukafa balonlar' },
      rivals: { head: 'Rakiplerini|devral', sub: 'Strateji kazanır, pazar senin' },
      night: { head: 'Geceleri|ışıl ışıl', sub: 'Ofisin koca bir kasaba olur' },
      show: { head: 'Gece göğünde|dev gösteri', sub: 'Balon Şöleni: bütün filo havada' }
    }
  }
};
if (typeof module !== 'undefined') module.exports = CAPTIONS;
