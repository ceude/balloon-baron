# App Store ve TestFlight hazırlığı

Bu dosya App Store Connect'e girilecek her şeyi tek yerde toplar. Kodda gereken her şey hazır:

- gizlilik bildirimi `BalloonBaron/PrivacyInfo.xcprivacy`
- şifreleme beyanı `ITSAppUsesNonExemptEncryption = NO`
- sürüm 1.0
- StoreKit 2 (`Shop.swift`)
- Game Center (`Platform.swift`)
- ölçüm (`Telemetry.swift`)

Burada yazanlar senin hesabında yapılacaklar.

## 1. Sırayla yapılacaklar

1. **Apple Developer Program** üyeliği (yıllık 99 $). Ücretsiz hesapla TestFlight, Game Center ve iCloud olmaz.
2. **App Store Connect → Uygulamalar → +**:
   - Platform: iOS.
   - Ad: `Balloon Baron: Cappadocia`.
   - Birincil dil: İngilizce (ABD).
   - Paket kimliği: `com.ceude.balloonbaron`.
   - SKU: `balloonbaron`.
3. **Xcode → proje → Signing & Capabilities**:
   - Team: ücretli hesabın.
   - Game Center ve iCloud (Key-value storage) projede hazır: `BalloonBaron/BalloonBaron.entitlements`, `gen_xcodeproj.py` her çalıştığında korunur. Otomatik imzalama bu yetkileri App ID'ye kendisi ekler.
4. **Uygulama içi satın almalar** (aşağıdaki tablo):
   - Her biri *Non-Consumable* olarak açılır.
   - Her ürün için incelemeye bir ekran görüntüsü yüklenir: Çarşı'daki satın alma kartı yeterli.
5. **Game Center**: 25 başarım ve 2 lider tablosu (aşağıdaki tablolar).
6. **App Privacy** (Uygulama Gizliliği) soruları: aşağıdaki cevaplar.
7. **Adresler (GitHub Pages, `docs/`):** destek `https://ceude.github.io/balloon-baron/support.html`, pazarlama `https://ceude.github.io/balloon-baron/`, gizlilik `https://ceude.github.io/balloon-baron/privacy-policy.html`. Pages bir kez açılmalı: repo Settings → Pages → Source: Deploy from a branch, `main`, `/docs`.
   Eski not: **Gizlilik politikası adresi**: `docs/privacy-policy.html` herkese açık bir adreste olmalı. En kolayı: repo ayarları → *Pages* → `main` dalı, `/docs` klasörü. Adres `https://ceude.github.io/balloon-baron/privacy-policy.html` olur. Pages, özel repoda yalnızca ücretli GitHub planında çalışır; olmazsa dosyayı herhangi bir siteye koyabiliriz.
8. **Xcode → Product → Archive → Distribute App → App Store Connect → Upload.** Birkaç dakika sonra yapı TestFlight sekmesinde görünür.
9. **TestFlight**:
   - **Dahili test:** Senin ve ekleyeceğin 100 kişiye kadar App Store Connect kullanıcısı. Apple incelemesi gerekmez.
   - **Harici test:** Link ile 10.000 kişiye kadar. İlk yapı için kısa bir Beta incelemesi gerekir.

## 2. Mağaza sayfası

- **Ad (30):** Balloon Baron: Cappadocia
- **Alt başlık (30):**
  - EN: Build a hot-air balloon empire
  - TR: Balon imparatorluğunu kur
- **Kategori:** Oyunlar → Simülasyon. İkincil: Strateji.
- **Fiyat:** Ücretsiz, uygulama içi satın alma var, reklam yok.
- **Anahtar kelimeler (100):**
  - EN: `balloon,hot air,tycoon,cappadocia,business,sim,manager,flight,pilot,empire,idle,strategy,turkey`
  - TR: `balon,sıcak hava,kapadokya,tycoon,işletme,simülasyon,şirket,pilot,uçuş,strateji,imparatorluk`
- **Tanıtım metni (170):**
  - EN: Fly at dawn over the fairy chimneys, read the wind, land perfectly and grow one basket into a balloon empire that reaches America.
  - TR: Peri bacalarının üstünde şafakta uç, rüzgârı oku, kusursuz in ve tek bir sepetten Amerika'ya uzanan bir balon imparatorluğu kur.

**Açıklama (EN):**

> Start with one small basket in Cappadocia and become the baron of the sky.
>
> FLY IT YOURSELF: fire the burner, find the right wind layer and land softly. Proposals in the sky, photo flights and precision landings pay extra.
>
> RUN THE COMPANY: buy balloons, hire pilots with their own characters, set your price, sign hotels and guides, survive winter, and outsmart rival companies that merge, poach your pilots and fly under red flags.
>
> GROW YOUR TOWN: your office becomes a town: hangar, wind mast, workshop, pilot school, hotels. At night it lights up with lanterns, fireworks and fireflies.
>
> DESIGN YOUR BALLOONS: patterns, colours, heart, star and skull envelopes.
>
> GO GLOBAL: become the Baron of Cappadocia, open a holding, fly the Balloon Fiesta in Albuquerque and open offices in New York, Istanbul, Tokyo and Seoul.
>
> No ads. No energy timers. Every piece of art and sound is made in code.

**Açıklama (TR):**

> Kapadokya'da tek bir küçük sepetle başla, göğün baronu ol.
>
> KENDİN UÇ: brülörü yak, doğru rüzgâr katmanını bul, yumuşacık in. Gökyüzünde evlilik teklifleri, fotoğraf uçuşları ve hassas inişler ekstra kazandırır.
>
> ŞİRKETİNİ YÖNET: balon al, her biri kendi karakterinde pilotlar işe al, fiyatını belirle, otellerle ve rehberlerle anlaş, kışı atlat. Birleşen, pilotunu ayartan, kırmızı bayrakta uçan rakip şirketleri alt et.
>
> KASABANI BÜYÜT: ofisin bir kasabaya dönüşür: hangar, rüzgâr direği, atölye, pilot okulu, oteller. Gece fenerler, havai fişekler ve ateş böcekleriyle ışıl ışıl.
>
> BALONUNU TASARLA: desenler, renkler, kalp, yıldız ve kurukafa balonlar.
>
> DÜNYAYA AÇIL: Kapadokya Baronu ol, holding kur, Albuquerque'de Balloon Fiesta'da uç; New York, İstanbul, Tokyo ve Seul'de ofis aç.
>
> Reklam yok. Enerji beklemesi yok. Bütün çizimler ve sesler kodla yapıldı.

- **Ekran görüntüleri:**
  - Türkçe iPhone seti `marketing/appstore/tr` içinde: 9 adet, 1290×2796, 6,7"/6,9" boyutu.
  - iPad seti (2048×2732) ve diğer diller, iPad düzeni bitince aynı araçla (`tools/appstore/panorama.js`) çıkacak.
- **Yaş sınırı:** Bütün sorulara "Yok / None". Sonuç 4+. Simüle kumar yok; şiddet yok (kaza var ama grafik değil).
  - **Alkol, Tütün veya Uyuşturucu Kullanımı ya da Göndermeleri (Alcohol, Tobacco, or Drug Use or References): Yok / None → 4+.** v141.5'te bütün göndermeler kaldırıldı: şampanyalı iniş kutlaması portakal suyuna döndü (sürahi ve karton bardaklar), şampanya / bira / şarap / elma şarabı geçen yorum, rakip ve sponsor metinleri altı dilde çay, kahve, gurme kahvaltı, üzüm suyu ve elma suyu oldu. Oyunda tütün ya da uyuşturucu hiç yok. Yeni metin eklerken bu kurala uy.
- **Telif:** © 2026 (adın ya da şirket adın)

## 3. Uygulama içi satın almalar (Non-Consumable)

| Ürün kimliği | Türkçe ad | İngilizce ad | Tür | Fiyat |
|---|---|---|---|---|
| `balloonbaron.gold` | Varak altın | Gold leaf | Desen | 0,99 € |
| `balloonbaron.tile` | İznik çinisi | Iznik tile | Desen | 0,99 € |
| `balloonbaron.sky` | Takımyıldız | Constellation | Desen | 0,99 € |
| `balloonbaron.kilim` | Kapadokya kilimi | Cappadocia kilim | Desen | 0,99 € |
| `balloonbaron.heart` | Kalp balon | Heart balloon | Şekil | 1,99 € |
| `balloonbaron.star` | Yıldız balon | Star balloon | Şekil | 1,99 € |
| `balloonbaron.skull` | Kurukafa balon | Skull balloon | Şekil | 1,99 € |
| `balloonbaron.fountain` | Meydan çeşmesi | Square fountain | Süs | 0,99 € |
| `balloonbaron.statue` | Hezarfen heykeli | Hezarfen statue | Süs | 0,99 € |
| `balloonbaron.flags` | Şirket bayrakları | Company flags | Süs | 0,99 € |
| `balloonbaron.decorpack` | Meydan Süsleri | Square Decorations | Paket (v115) | 0,99 € |
| `balloonbaron.figurepack` | Şölen Figürleri | Show Figures | Paket (v115) | 0,99 € |
| `balloonbaron.founder` | Kurucu Paketi | Founder Pack | Paket (v113) | 6,99 € |
| `balloonbaron.worldtour` | Dünya Turu | Grand Tour | Bölge kilidi (v115): Albuquerque, Luksor, Bristol ve Maasai Mara (v141) | 4,99 € |
| `balloonbaron.supporter` | Destekçi Sürümü | Supporter Edition | Paket (v115) | 9,99 € |

- Fener dizileri (`lanterns`) Hezarfen'in hediyesi. Ürün değil, App Store'a girilmez.
- Kimlikler `StoreItem.productID` ile aynı olmalı.
- v113 ürünleri uygulamada ve `StoreKit/BalloonBaron.storekit` dosyasında var; App Store Connect'e de aynı kimliklerle girilmeli. Kurucu Paketi bir Non-Consumable üründür; alınınca uygulama paketteki bütün kozmetikleri açar (geri yüklemede de).

Xcode'da ödeme denemek için:

1. Xcode → Product → Scheme → Edit Scheme… → Run → Options.
2. *StoreKit Configuration*: `StoreKit/BalloonBaron.storekit`.

Bu dosya App Store Connect olmadan da çalışır. TestFlight'ta Apple'ın test ödemesi kullanılır, para çekilmez.

## 4. Game Center

**Lider tabloları** (Classic, Best Score, büyük olan iyi):

- `balloonbaron.lb.passengers`: Toplam yolcu / Total passengers
- `balloonbaron.lb.bestday`: En kalabalık gün / Best day (passengers)

**Başarımlar** (kartpostallar). v141.1 (geliştirici kararı): bütün kartpostallar Game Center'da, Bristol'ün ve Maasai Mara'nın kartpostalları dahil. Apple'ın sınırı 1000 puan; toplam **880**, 120 puan gelecekteki bir Asya şehri bölgesinin iki kartpostalı için boş bırakıldı (örneğin giriş 20, baron 70). Puanlar çekirdekte `Achievement.gameCenterPoints` (testi `GameCenter141Tests`). Yayından önce App Store Connect'te var olan başarımların puanı değiştirilebilir: "değişti" satırlarının puanı güncellenmeli, "yeni" satırlar oluşturulmalı (ikisinin de başlık ve açıklaması yedi dilde, oyundaki `ach.<id>` ve `ach.<id>.d` metinleri; Fransızca v142'de eklendi, var olan başarımlara da fr-FR yerelleştirmesi girilmeli).

| Kimlik | Puan | Önce | Durum | en | tr | de | es | ja | ko | fr | Açıklama (en) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `balloonbaron.ach.first` | 5 | 10 | değişti | First flight | İlk uçuş | Erster Flug | Primer vuelo | 初フライト | 첫 비행 | Premier vol | Your company's first morning |
| `balloonbaron.ach.mission` | 10 | 20 | değişti | First special request | İlk özel istek | Erster Sonderwunsch | Primer encargo especial | 初めての特別依頼 | 첫 특별 요청 | Première demande spéciale | You completed a request |
| `balloonbaron.ach.perfect10` | 25 | 40 | değişti | Light as a feather | Tüy gibi | Federleicht | Como una pluma | 羽のように | 깃털처럼 | Léger comme une plume | 10 perfect landings |
| `balloonbaron.ach.fleet5` | 10 | 20 | değişti | Small fleet | Küçük filo | Kleine Flotte | Pequeña flota | 小さな船団 | 작은 기단 | Petite flotte | 5 balloons |
| `balloonbaron.ach.fleet10` | 20 | 40 | değişti | A crowded sky | Gökyüzü kalabalık | Voller Himmel | Cielo concurrido | にぎやかな空 | 붐비는 하늘 | Un ciel bien rempli | 10 balloons |
| `balloonbaron.ach.fleet20` | 35 | 60 | değişti | Armada | Armada | Armada | Armada | 大艦隊 | 대함대 | Armada | 20 balloons |
| `balloonbaron.ach.hotel` | 10 | 15 | değişti | Hotel partner | Otel ortağı | Hotelpartner | Socio hotelero | ホテルの相棒 | 호텔 파트너 | Partenaire hôtelier | Your first hotel deal |
| `balloonbaron.ach.hotelOwn` | 25 | 40 | değişti | Hotel owner | Otel sahibi | Hotelbesitzer | Dueño de hotel | ホテルオーナー | 호텔 주인 | Propriétaire d’hôtel | You bought a hotel |
| `balloonbaron.ach.star45` | 30 | 50 | değişti | Darling of the valley | Vadinin gözdesi | Liebling des Tals | Favorito del valle | 谷の人気者 | 계곡의 인기 스타 | Chouchou de la vallée | 4.5★ popularity |
| `balloonbaron.ach.pax1k` | 15 | 30 | değişti | A thousand passengers | Bin yolcu | Tausend Passagiere | Mil pasajeros | 乗客千人 | 승객 천 명 | Mille passagers | 1,000 passengers flown in all |
| `balloonbaron.ach.pax10k` | 35 | 60 | değişti | Ten thousand passengers | On bin yolcu | Zehntausend Passagiere | Diez mil pasajeros | 乗客1万人 | 승객 만 명 | Dix mille passagers | 10,000 passengers flown in all |
| `balloonbaron.ach.winter` | 15 | 30 | değişti | Through the winter | Kışı atlattın | Winter überstanden | Superaste el invierno | 冬を越えた | 겨울을 버텼다 | L’hiver est passé | Your first winter is over |
| `balloonbaron.ach.fest` | 10 | 20 | değişti | Festival spirit | Festival havası | Festivalstimmung | Ambiente de fiesta | お祭り気分 | 축제 분위기 | Esprit de fête | You flew in a festival |
| `balloonbaron.ach.rivalDown` | 25 | 40 | değişti | A rival fell | Rakip düştü | Ein Konkurrent weniger | Cayó un rival | ライバル陥落 | 경쟁자 몰락 | Un concurrent à terre | A rival went bankrupt |
| `balloonbaron.ach.boss` | 35 | 60 | değişti | The old master | Eski usta | Der alte Meister | El viejo maestro | 古参の退場 | 노장의 퇴장 | Le vieux maître | The valley's old owner stepped aside |
| `balloonbaron.ach.design` | 10 | 20 | değişti | Your own pattern | Kendi desenin | Dein eigenes Muster | Tu propio diseño | 自分の柄 | 나만의 무늬 | Ton propre motif | Your first balloon design |
| `balloonbaron.ach.upgrade3` | 25 | 40 | değişti | Masterwork | Usta işi | Meisterwerk | Obra maestra | 匠の技 | 장인의 솜씨 | Chef-d’œuvre | You took a building to level 3 |
| `balloonbaron.ach.xl` | 40 | 60 | değişti | Giant balloon | Dev balon | Riesenballon | Globo gigante | 巨大気球 | 거대 열기구 | Ballon géant | Your giant balloon is in the sky |
| `balloonbaron.ach.baronCap` | 50 | 80 | değişti | Baron of Cappadocia | Kapadokya Baronu | Baron von Kappadokien | Barón de Capadocia | カッパドキアの男爵 | 카파도키아의 남작 | Baron de Cappadoce | Master of the valley |
| `balloonbaron.ach.abq` | 20 | 40 | değişti | New World | Yeni Dünya | Neue Welt | Nuevo Mundo | 新世界 | 신대륙 | Nouveau Monde | You entered Albuquerque |
| `balloonbaron.ach.baronAbq` | 50 | 80 | değişti | Baron of Albuquerque | Albuquerque Baronu | Baron von Albuquerque | Barón de Albuquerque | アルバカーキの男爵 | 앨버커키의 남작 | Baron d’Albuquerque | The sky of two continents |
| `balloonbaron.ach.lux` | 20 | 40 | değişti | Sky of the Nile | Nil'in göğü | Himmel des Nils | Cielo del Nilo | ナイルの空 | 나일의 하늘 | Le ciel du Nil | You entered Luxor |
| `balloonbaron.ach.baronLux` | 60 | 100 | değişti | Baron of Luxor | Luksor Baronu | Baron von Luxor | Barón de Luxor | ルクソールの男爵 | 룩소르의 남작 | Baron de Louxor | The valley of the pharaohs is yours |
| `balloonbaron.ach.bri` | 20 | – | yeni | Sky of the Avon | Avon'un göğü | Himmel über dem Avon | El cielo del Avon | エイボンの空 | 에이번의 하늘 | Le ciel de l’Avon | You entered Bristol |
| `balloonbaron.ach.nightGlow` | 15 | – | yeni | Night Glow | Gece Işıltısı | Night Glow | Night Glow | ナイトグロー | 나이트 글로 | Night Glow | Your balloons glowed on a festival night |
| `balloonbaron.ach.baronBri` | 60 | – | yeni | Baron of Bristol | Bristol Baronu | Baron von Bristol | Barón de Bristol | ブリストル男爵 | 브리스톨 남작 | Baron de Bristol | Master of the gorge and the festival |
| `balloonbaron.ach.world` | 100 | 100 | aynı | World Baron | Dünya Baronu | Weltbaron | Barón mundial | 世界の男爵 | 세계의 남작 | Baron du monde | All holding goals complete |
| `balloonbaron.ach.patron` | 15 | 30 | değişti | Patron of the skies | Gökyüzünün hayırseveri | Gönner der Lüfte | Mecenas de los cielos | 空の篤志家 | 하늘의 후원자 | Mécène des cieux | The foundation's first project |
| `balloonbaron.ach.mara` | 20 | – | yeni | Sky of the savanna | Savananın göğü | Himmel über der Savanne | El cielo de la sabana | サバンナの空 | 사바나의 하늘 | Le ciel de la savane | You entered the Maasai Mara |
| `balloonbaron.ach.baronMara` | 70 | – | yeni | Baron of the Maasai Mara | Maasai Mara Baronu | Baron der Maasai Mara | Barón del Maasai Mara | マサイマラ男爵 | 마사이마라 남작 | Baron du Maasai Mara | Master of the savanna and the Great Migration |

Başarımlar oyunda kartpostal olarak kutlanıyor, bu yüzden Game Center afişi kapalı (`showsCompletionBanner = false`).

## 5. App Privacy (Uygulama Gizliliği) cevapları

- **İzleme (tracking):** Hayır.
- **Toplanan veri:** *Kullanım verisi → Ürün etkileşimi*.
  - Kullanıcıya bağlı değil.
  - İzleme için kullanılmıyor.
  - Amaç: *Analiz*.
  - TelemetryDeck App ID girildi (Ekim 2026), bu yüzden bu seçenek işaretlenir.
- **Satın almalar:** Apple yönetir, uygulama bu veriyi toplamaz.
- **Game Center:** Apple'ın kendi hizmeti. Uygulama oyuncu kimliğini sunucuya göndermez.

## 6. İnceleme notu (App Review)

> No login needed. The game saves on the device. All purchases are non-consumable and can be restored from the bazaar ("Restore purchases"). Balloon patterns, shaped envelopes, town decorations and Balloon Show figures change the look of the game; shop patterns and shapes never fade and can be applied to any balloon for free. The whole Cappadocia campaign is free; the "Grand Tour" unlocks the further regions (America, Egypt) after the player becomes Baron of Cappadocia. The "Founder Pack" unlocks every pattern, shape, decoration and show figure at once; the "Supporter Edition" is the Grand Tour plus the Founder Pack and a supporter plaque in town. The bazaar opens on game day 11; to reach it quickly, play a few days (each day: tap "Collect passengers", take off, land).

## 7. Sürüm numaraları

- `MARKETING_VERSION` (görünen sürüm): 1.0.
- `CURRENT_PROJECT_VERSION` (yapı numarası): Her TestFlight yüklemesinde bir artmalı. `tools/gen_xcodeproj.py` içinden değiştir, ya da Xcode'da *Build* alanını yükselt.
