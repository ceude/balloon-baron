/* Every word on the v2 App Store screenshots, one table per language. To add a language, copy the `tr` block,
   translate it, and run `node tools/appstore/v2/render.js <raw dir> <lang>`. Headlines are written in normal case;
   the page upper-cases them with the language's own rules (Turkish i → İ). `|` breaks a headline line.
   Apple indexes the words on screenshots, so the kickers and lines carry the search terms on purpose. */
const CAPTIONS = {
  tr: {
    locale: 'tr-TR',
    brand: ['Balon Baronu', 'Kapadokya'],
    /* the four cities on screen 2, left to right as they read on the screen */
    cities: { cap: ['Kapadokya', 'Türkiye'], lux: ['Luksor', 'Mısır'], bri: ['Bristol', 'İngiltere'], abq: ['Albuquerque', 'ABD'] },
    screens: {
      hero: { kicker: 'Sıcak hava balonu tycoon', head: 'Balon|işletmecisi ol', sub: 'Kapadokya’da bir balon şirketi, dünyaya uzanan bir imparatorluk' },
      cities: { kicker: 'Dünya turu', head: 'Dört şehir|tek imparatorluk', sub: 'Kapadokya’dan Nil’e, Bristol’den Balloon Fiesta’ya' },
      idle: { kicker: 'Idle tycoon', head: 'Günler akar|kasa dolar', sub: 'Otomatik ilerletme: şirketin kendi kendine uçar, kazanır' },
      flight: { kicker: 'Gerçekçi balon uçuşu', head: 'Şafakta|dümen sende', sub: 'Brülör, rüzgâr katmanları ve kusursuz bir iniş' },
      holding: { kicker: 'Holding imparatorluğu', head: 'Tek sepetten|holdinge', sub: 'Bölgelerin otomatik modda, kazanç holding kasasında' },
      crew: { kicker: 'Pilot ve ekip yönetimi', head: 'Her pilot|bir karakter', sub: 'Temkinli, gözü kara, sadık: ekibini sen seçersin' },
      design: { kicker: 'Tasarım stüdyosu', head: 'Balonun|imzan olsun', sub: 'Desenler, renkler; kalp, yıldız ve kurukafa balonlar' },
      night: { kicker: 'Şirket kur, kasaba büyüt', head: 'Geceleri|ışıl ışıl', sub: 'Ofisinden koca bir kasabaya: hangar, oteller, havai fişek' },
      show: { kicker: 'Balon Şöleni', head: 'Gece göğünde|dev gösteri', sub: 'Filonun brülörleri aynı anda parlar, kasaba nefesini tutar' },
      close: { kicker: 'Simülasyon ve strateji', head: 'Reklam yok|enerji yok', sub: 'Sadece sen, rüzgâr ve balonların' }
    }
  }
};
if (typeof module !== 'undefined') module.exports = CAPTIONS;
