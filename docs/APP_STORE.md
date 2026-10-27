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
5. **Game Center**: 24 başarım ve 2 lider tablosu (aşağıdaki tablolar).
6. **App Privacy** (Uygulama Gizliliği) soruları: aşağıdaki cevaplar.
7. **Gizlilik politikası adresi**: `docs/privacy-policy.html` herkese açık bir adreste olmalı. En kolayı: repo ayarları → *Pages* → `main` dalı, `/docs` klasörü. Adres `https://ceude.github.io/balloon-baron/privacy-policy.html` olur. Pages, özel repoda yalnızca ücretli GitHub planında çalışır; olmazsa dosyayı herhangi bir siteye koyabiliriz.
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
| `balloonbaron.worldtour` | Dünya Turu | Grand Tour | Bölge kilidi (v115) | 5,99 € |
| `balloonbaron.supporter` | Destekçi Sürümü | Supporter Edition | Paket (v115) | 11,99 € |

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

**Başarımlar** (kartpostallar). Toplam puan 1000'i geçmemeli, bu tabloda 955.

| Kimlik | İngilizce | Türkçe | Açıklama (EN) | Puan |
|---|---|---|---|---|
| `balloonbaron.ach.first` | First flight | İlk uçuş | Your company's first morning | 10 |
| `balloonbaron.ach.mission` | First special request | İlk özel istek | You completed a request | 20 |
| `balloonbaron.ach.perfect10` | Light as a feather | Tüy gibi | 10 perfect landings | 40 |
| `balloonbaron.ach.fleet5` | Small fleet | Küçük filo | 5 balloons | 20 |
| `balloonbaron.ach.fleet10` | A crowded sky | Gökyüzü kalabalık | 10 balloons | 40 |
| `balloonbaron.ach.fleet20` | Armada | Armada | 20 balloons | 60 |
| `balloonbaron.ach.hotel` | Hotel partner | Otel ortağı | Your first hotel deal | 15 |
| `balloonbaron.ach.hotelOwn` | Hotel owner | Otel sahibi | You bought a hotel | 40 |
| `balloonbaron.ach.star45` | Darling of the valley | Vadinin gözdesi | 4.5★ popularity | 50 |
| `balloonbaron.ach.pax1k` | A thousand passengers | Bin yolcu | 1,000 passengers flown in all | 30 |
| `balloonbaron.ach.pax10k` | Ten thousand passengers | On bin yolcu | 10,000 passengers in all | 60 |
| `balloonbaron.ach.winter` | Through the winter | Kışı atlattın | Your first winter is over | 30 |
| `balloonbaron.ach.fest` | Festival spirit | Festival havası | You flew in a festival | 20 |
| `balloonbaron.ach.rivalDown` | A rival fell | Rakip düştü | A rival went bankrupt | 40 |
| `balloonbaron.ach.boss` | The old master | Eski usta | The valley's old owner stepped aside | 60 |
| `balloonbaron.ach.design` | Your own pattern | Kendi desenin | Your first balloon design | 20 |
| `balloonbaron.ach.upgrade3` | Master's work | Usta işi | You took a building to level 3 | 40 |
| `balloonbaron.ach.xl` | Giant balloon | Dev balon | Your giant balloon is in the sky | 60 |
| `balloonbaron.ach.baronCap` | Baron of Cappadocia | Kapadokya Baronu | Master of the valley | 80 |
| `balloonbaron.ach.abq` | New World | Yeni Dünya | You entered Albuquerque | 40 |
| `balloonbaron.ach.baronAbq` | Baron of Albuquerque | Albuquerque Baronu | The sky of two continents | 80 |
| `balloonbaron.ach.lux` | Sky of the Nile | Nil'in göğü | You entered Luxor | 40 |
| `balloonbaron.ach.baronLux` | Baron of Luxor | Luksor Baronu | The valley of the pharaohs is yours | 100 |
| `balloonbaron.ach.world` | World Baron | Dünya Baronu | Every goal of the holding | 100 |

Başarımlar oyunda kartpostal olarak kutlanıyor, bu yüzden Game Center afişi kapalı (`showsCompletionBanner = false`).

## 5. App Privacy (Uygulama Gizliliği) cevapları

- **İzleme (tracking):** Hayır.
- **Toplanan veri:** *Kullanım verisi → Ürün etkileşimi*.
  - Kullanıcıya bağlı değil.
  - İzleme için kullanılmıyor.
  - Amaç: *Analiz*.
  - Bu sadece TelemetryDeck App ID girilince geçerli. Girilmezse "Veri toplanmıyor" seçilir.
- **Satın almalar:** Apple yönetir, uygulama bu veriyi toplamaz.
- **Game Center:** Apple'ın kendi hizmeti. Uygulama oyuncu kimliğini sunucuya göndermez.

## 6. İnceleme notu (App Review)

> No login needed. The game saves on the device. All purchases are non-consumable and can be restored from the bazaar ("Restore purchases"). Balloon patterns, shaped envelopes, town decorations and Balloon Show figures change the look of the game; shop patterns and shapes never fade and can be applied to any balloon for free. The whole Cappadocia campaign is free; the "Grand Tour" unlocks the further regions (America, Egypt) after the player becomes Baron of Cappadocia. The "Founder Pack" unlocks every pattern, shape, decoration and show figure at once; the "Supporter Edition" is the Grand Tour plus the Founder Pack and a supporter plaque in town. The bazaar opens on game day 11; to reach it quickly, play a few days (each day: tap "Collect passengers", take off, land).

## 7. Sürüm numaraları

- `MARKETING_VERSION` (görünen sürüm): 1.0.
- `CURRENT_PROJECT_VERSION` (yapı numarası): Her TestFlight yüklemesinde bir artmalı. `tools/gen_xcodeproj.py` içinden değiştir, ya da Xcode'da *Build* alanını yükselt.
