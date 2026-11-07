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
    /* the four painted landscapes on screen 2, top to bottom (the headline counts five regions: the Maasai Mara is on the world map) */
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
      cities: { head: 'Beş bölge|tek imparatorluk', sub: 'Kapadokya’dan Maasai Mara’ya' },
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
  ,
  en: {
    locale: 'en-US',
    brand: ['Balloon Baron', 'Cappadocia'],
    noAds: 'Ad-free',
    cities: { cap: ['Cappadocia', 'Türkiye'], lux: ['Luxor', 'Egypt'], bri: ['Bristol', 'England'], abq: ['Albuquerque', 'USA'] },
    badges: {
      idle: [['@IDLE', 'in one day'], ['@FLEET', 'balloon fleet']],
      holding: { before: ['Day 2', '1', 'balloon'], after: ['Day @DAY', '@FLEET', 'balloons'] },
      rivals: ['@SHARE', 'market share'],
    },
    preview: ['Fly it yourself|at dawn', 'Become a|balloon tycoon', 'Days roll by,|cash rolls in', 'Four cities,|one empire', 'Glowing|after dark', 'A giant show|in the night sky'],
    screens: {
      hero: { head: 'Become a|balloon tycoon', sub: 'From one basket to hundreds' },
      cities: { head: 'Five regions,|one empire', sub: 'Cappadocia to the Maasai Mara' },
      flight: { head: 'Fly it yourself|at dawn', sub: 'Realistic hot air balloon flight' },
      idle: { head: 'Days roll by,|cash rolls in', sub: 'Idle tycoon with auto-advance' },
      holding: { head: 'From one basket|to big business', sub: 'Day 2 to Day @DAY' },
      crew: { head: 'Every pilot|is a character', sub: 'Careful, daredevil, loyal' },
      design: { head: 'Your balloon,|your signature', sub: 'Heart, star and skull balloons' },
      rivals: { head: 'Buy out|your rivals', sub: 'Strategy wins the market' },
      night: { head: 'Glowing|after dark', sub: 'Your office becomes a town' },
      show: { head: 'A giant show|in the night sky', sub: 'Balloon Show: the whole fleet' }
    }
  },
  de: {
    locale: 'de-DE',
    brand: ['Balloon Baron', 'Kappadokien'],
    noAds: 'Werbefrei',
    cities: { cap: ['Kappadokien', 'Türkei'], lux: ['Luxor', 'Ägypten'], bri: ['Bristol', 'England'], abq: ['Albuquerque', 'USA'] },
    badges: {
      idle: [['@IDLE', 'an einem Tag'], ['@FLEET', 'Ballons in der Flotte']],
      holding: { before: ['Tag 2', '1', 'Ballon'], after: ['Tag @DAY', '@FLEET', 'Ballons'] },
      rivals: ['@SHARE', 'Marktanteil'],
    },
    preview: ['Du fliegst|im Morgenrot', 'Gründe deine|Ballonfirma', 'Die Tage laufen,|die Kasse klingelt', 'Vier Städte,|ein Imperium', 'Nachts hell|erleuchtet', 'Große Show|am Nachthimmel'],
    screens: {
      hero: { head: 'Gründe deine|Ballonfirma', sub: 'Vom Korb zur Riesenflotte' },
      cities: { head: 'Fünf Regionen,|ein Imperium', sub: 'Von Kappadokien bis in die Maasai Mara' },
      flight: { head: 'Du fliegst|im Morgenrot', sub: 'Realistische Heißluftballonfahrt' },
      idle: { head: 'Die Tage laufen,|die Kasse klingelt', sub: 'Wirtschaftssimulation mit Vorspulen' },
      holding: { head: 'Vom Korb|zum Konzern', sub: 'Tag 2 bis Tag @DAY' },
      crew: { head: 'Jeder Pilot|ein Charakter', sub: 'Vorsichtig, Draufgänger, treu' },
      design: { head: 'Dein Ballon,|deine Handschrift', sub: 'Herz-, Stern- und Totenkopfballons' },
      rivals: { head: 'Übernimm|die Konkurrenz', sub: 'Strategie gewinnt den Markt' },
      night: { head: 'Nachts hell|erleuchtet', sub: 'Dein Büro wird zur Stadt' },
      show: { head: 'Große Show|am Nachthimmel', sub: 'Ballon-Show: die ganze Flotte' }
    }
  },
  es: {
    locale: 'es-ES',
    brand: ['Balloon Baron', 'Capadocia'],
    noAds: 'Sin anuncios',
    cities: { cap: ['Capadocia', 'Turquía'], lux: ['Luxor', 'Egipto'], bri: ['Bristol', 'Inglaterra'], abq: ['Albuquerque', 'EE. UU.'] },
    badges: {
      idle: [['@IDLE', 'en un solo día'], ['@FLEET', 'globos en la flota']],
      holding: { before: ['Día 2', '1', 'globo'], after: ['Día @DAY', '@FLEET', 'globos'] },
      rivals: ['@SHARE', 'cuota de mercado'],
    },
    preview: ['Vuela tú mismo|al amanecer', 'Conviértete en|magnate del globo', 'Pasan los días,|entra el dinero', 'Cuatro ciudades,|un imperio', 'De noche,|todo brilla', 'Gran espectáculo|en el cielo nocturno'],
    screens: {
      hero: { head: 'Conviértete en|magnate del globo', sub: 'De un globo a cientos' },
      cities: { head: 'Cinco regiones,|un imperio', sub: 'De Capadocia al Maasai Mara' },
      flight: { head: 'Vuela tú mismo|al amanecer', sub: 'Vuelo realista en globo aerostático' },
      idle: { head: 'Pasan los días,|entra el dinero', sub: 'Simulador de negocios idle' },
      holding: { head: 'De una cesta|a un holding', sub: 'Del día 2 al @DAY' },
      crew: { head: 'Cada piloto,|un carácter', sub: 'Prudente, temerario, leal' },
      design: { head: 'Tu globo,|tu firma', sub: 'Globos corazón, estrella y calavera' },
      rivals: { head: 'Compra a|tus rivales', sub: 'La estrategia gana el mercado' },
      night: { head: 'De noche,|todo brilla', sub: 'Tu oficina se vuelve pueblo' },
      show: { head: 'Gran espectáculo|en el cielo nocturno', sub: 'Espectáculo con toda la flota' }
    }
  },
  ja: {
    locale: 'ja-JP',
    brand: ['バルーンバロン', 'カッパドキア'],
    noAds: '広告なし',
    cities: { cap: ['カッパドキア', 'トルコ'], lux: ['ルクソール', 'エジプト'], bri: ['ブリストル', 'イギリス'], abq: ['アルバカーキ', 'アメリカ'] },
    badges: {
      idle: [['@IDLE', '1日の利益'], ['@FLEET', '機の気球船団']],
      holding: { before: ['2日目', '1', '機'], after: ['@DAY日目', '@FLEET', '機'] },
      rivals: ['@SHARE', '市場シェア'],
    },
    preview: ['夜明けの空を|自分で操縦', '気球会社の|社長になろう', '日々は進み|お金が貯まる', '4つの都市に|気球帝国を', '夜の町が|きらめく', '夜空を彩る|バルーンショー'],
    screens: {
      hero: { head: '気球会社の|社長になろう', sub: '1機の気球から大船団へ' },
      cities: { head: '5つの地域に|気球帝国を', sub: 'カッパドキアからマサイマラへ' },
      flight: { head: '夜明けの空を|自分で操縦', sub: 'リアルな熱気球フライト' },
      idle: { head: '日々は進み|お金が貯まる', sub: '早送りできる放置経営シミュレーション' },
      holding: { head: '気球1機から|大企業へ', sub: '2日目から@DAY日目まで' },
      crew: { head: 'パイロットは|みんな個性派', sub: '慎重、命知らず、忠実' },
      design: { head: '気球に|あなたのサインを', sub: 'ハート・星・ドクロの気球' },
      rivals: { head: 'ライバル会社を|買収せよ', sub: '戦略で市場を制する' },
      night: { head: '夜の町が|きらめく', sub: 'オフィスがひとつの町に' },
      show: { head: '夜空を彩る|バルーンショー', sub: '全機そろって夜空へ' }
    }
  },
  ko: {
    locale: 'ko-KR',
    brand: ['벌룬 바론', '카파도키아'],
    noAds: '광고 없음',
    cities: { cap: ['카파도키아', '튀르키예'], lux: ['룩소르', '이집트'], bri: ['브리스톨', '영국'], abq: ['앨버커키', '미국'] },
    badges: {
      idle: [['@IDLE', '하루 수익'], ['@FLEET', '대 열기구 기단']],
      holding: { before: ['2일차', '1', '대'], after: ['@DAY일차', '@FLEET', '대'] },
      rivals: ['@SHARE', '시장 점유율'],
    },
    preview: ['새벽 하늘을|직접 날다', '열기구 회사의|사장이 되자', '하루가 흐르면|금고가 찬다', '네 도시,|하나의 제국', '밤이면|반짝이는 마을', '밤하늘을 수놓는|열기구 쇼'],
    screens: {
      hero: { head: '열기구 회사의|사장이 되자', sub: '열기구 하나에서 대기단으로' },
      cities: { head: '다섯 지역,|하나의 제국', sub: '카파도키아에서 마사이마라까지' },
      flight: { head: '새벽 하늘을|직접 날다', sub: '리얼한 열기구 비행' },
      idle: { head: '하루가 흐르면|금고가 찬다', sub: '빨리 감기로 즐기는 방치형 타이쿤' },
      holding: { head: '바구니 하나에서|대기업으로', sub: '2일차에서 @DAY일차까지' },
      crew: { head: '조종사마다|개성이 다르다', sub: '신중함, 무모함, 충성스러움' },
      design: { head: '나만의 열기구를|디자인하라', sub: '하트, 별, 해골 열기구' },
      rivals: { head: '경쟁사를|인수하라', sub: '전략으로 시장을 장악하라' },
      night: { head: '밤이면|반짝이는 마을', sub: '사무실이 큰 마을이 된다' },
      show: { head: '밤하늘을 수놓는|열기구 쇼', sub: '모든 기단이 하늘로' }
    }
  },
  fr: {
    locale: 'fr-FR',
    brand: ['Balloon Baron', 'Cappadoce'],
    noAds: 'Sans pub',
    cities: { cap: ['Cappadoce', 'Turquie'], lux: ['Louxor', 'Égypte'], bri: ['Bristol', 'Angleterre'], abq: ['Albuquerque', 'États-Unis'] },
    badges: {
      idle: [['@IDLE', 'en une journée'], ['@FLEET', 'ballons dans la flotte']],
      holding: { before: ['Jour 2', '1', 'ballon'], after: ['Jour @DAY', '@FLEET', 'ballons'] },
      rivals: ['@SHARE', 'de parts de marché'],
    },
    preview: ['Pilote à|l’aube', 'Bâtis ton empire|de montgolfières', 'Les jours filent,|la caisse se remplit', 'Quatre villes,|un empire', 'La nuit,|tout s’illumine', 'Un show géant|dans le ciel'],
    screens: {
      hero: { head: 'Bâtis ton empire|de montgolfières', sub: 'D’une nacelle à toute une flotte' },
      cities: { head: 'Cinq régions,|un empire', sub: 'De la Cappadoce au Maasai Mara' },
      flight: { head: 'Pilote|à l’aube', sub: 'Vol réaliste en montgolfière' },
      idle: { head: 'Les jours filent,|la caisse se remplit', sub: 'Jeu de gestion idle avec avance rapide' },
      holding: { head: 'D’une nacelle|à un empire', sub: 'Du jour 2 au jour @DAY' },
      crew: { head: 'Chaque pilote|a son style', sub: 'Méthodique, casse-cou, fidèle' },
      design: { head: 'Ton ballon,|ta signature', sub: 'Ballons cœur, étoile et tête de mort' },
      rivals: { head: 'Rachète|tes concurrents', sub: 'La stratégie gagne le marché' },
      night: { head: 'La nuit,|tout s’illumine', sub: 'Ton bureau devient une ville' },
      show: { head: 'Un show géant|dans le ciel', sub: 'Spectacle de ballons\u00a0: toute la flotte' }
    }
  }
};if (typeof module !== 'undefined') module.exports = CAPTIONS;
