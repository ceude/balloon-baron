# Swift'e aktarılacaklar

Prototipte yapılıp henüz iOS koduna geçmemiş değişiklikler. Karar verilince toplu olarak aktarılır.

## Bekleyenler (prototip v106)

- **Bölge geçişi** (`showTravel`): bölge değişince yaklaşık 3,4 saniyelik bir ekran açılır. Dünya haritasında şirket balonu eski şehirden yenisine noktalı bir yay boyunca süzülür. Başlık "Kapadokya → Albuquerque", alt yazı "Rüzgâr seni … göğüne taşıyor…". Bölge arkada hemen değişir; açılır pencereler balon inince gelir.
- **Pilot eksik uyarısı** (`pilotCheck`): "Yolcu topla"ya basınca uçması seçili ama pilotu olmayan balon varsa kart açılır: "Bir balon yerde kalacak" ya da "Yerde kalacak balon: N", balon adları, "Ekip sayfası" ve "Yine de uç" düğmeleri. Kırmızı bayrak sorusu ondan sonra gelir.
- **Ayarlar menüsü** (`showMenu`): sağ üstteki menü bir ayarlar ekranı oldu.
  - Gruplar: Oyun (Başarımlar, Game Center), Ses ve titreşim (Ses ve Titreşim anahtarları; titreşim kapanınca Haptics susar), Bildirim (Sabah hatırlatıcısı anahtarı), Kayıt, Satın alımlar (geri yükle), Hakkında (Gizlilik politikası, Destek, Sürüm).
  - Kayıt grubu: otomatik kayıt satırı, "Kayıt kodunu kopyala" (açılınca kod ve Kopyala) ve "Kayıt kodu yükle" (boş kutu, Yapıştır, Yükle).
  - Sonda kırmızı "Yeni oyun başlat" (iki dokunuşla) ve "Devam et".
  - Görünüm (v106.1): emoji yok. Her satırda oyunun yan butonlarıyla aynı çizgi stilinde ikon (`SET_IC`: kupa, oyun kolu, hoparlör, titreşim, zil, bulut, kopyala, yapıştır, çanta, kalkan, zarf, bilgi, çöp), 36 pt yuvarlak karede; her grubun kendi rengi var (oyun mercan, ses turkuaz, bildirim sarı, kayıt mavi, satın alım mor, hakkında gri, yeni oyun kırmızı). Satırlar oyunun beyaz kartlarında, sert alt gölgeli; başlıkta şirket balonu, şirket adı · gün · bölge ve kapatma düğmesi. Anahtarlar yeşil, kendi gölgeli topuzlu.
- **Üç boyutlu şirket balonu** (`balloon3d`): uygulama ikonundaki gibi 13 dilimli, ışık ve gölgeli, alevli balon; renkler şirket renkleri (her dördüncü dilim ikinci renk). Giriş ekranının balonunda ve uçuşta amiral balonunda kullanılır. Atölye tasarımı giydirilmiş balon eski çizimde kalır. Kaynağı `tools/appstore/art.js` içindeki `balloon` ve `flame`.

(Swift'te doğrudan düzeltilenler, prototipte karşılığı yok: yakınlaşınca sağdaki ikon sütunu da tamamen ekrandan çıkıyor; holding ofisinde masalar arası en az 175 pt, kısa ekranda ofis aşağı kayıyor.)

Önceki durum: Swift uygulaması prototip v105.1 ile aynıydı.

v104–v105.1 aktarımı (Ekim 2026): Luksor bölgesi (rakipler, yeni girenler, dört bölüm, Nil rüzgârı, Nil gemisi sezonu ve Nil gecesi, erken birleşmeler, 150.000 giriş, 5.000 başlangıç, Nabil Haddad, Nil Postası, başarımlar `lux` / `baronLux`, uçuş manzarası); bölgeye göre kasabalar ve holding penceresi; çarşı etiketi ve dokunma önceliği; balon donanımı (çift/üçlü brülör, dönüş valfi, `Burners`), uçuşta VALF düğmesi ve elektrik hatları (`PowerLine`); zarf müfettişi (`HezMessage.inspector`); bölgesel rehberler Ben Franklin ve İmhotep (`HezMessage.guideHello`, `GuideAvatar`); holding 5. masa rekor denemeleri (ilk deneme hep başarılı) ve 6. masa sponsorlu şekiller (`AdShapeArt`); dünya haritasında Bristol ve Maasai Mara. Altı dilde metinler. Yeni kayıt alanlarının hepsi isteğe bağlı. App Store Connect'te iki yeni Game Center başarımı açılmalı (`docs/APP_STORE.md`).

Önceki durum: Swift uygulaması prototip v103 ile aynıydı. v101: XL balonun adı "Dev balon", "İmza balon" etiketi kalktı.

v98–v100 aktarımı (Ekim 2026): reklam yok (bölüm kartındaki reklam düğmesi ve `doubleChapterReward` kalktı); Hezarfen balonu yerine Kurukafa balon (`StoreItem.skull`, `EnvelopeShape.skull`; eski kayıtlardaki "hezarfen" kurukafa olarak okunur); Hezarfen övgüleri (`Praise`, `Game.praiseCheck`, `HezMessage.praise`, düğme "Sağ ol usta"); ilk 3 günde kırmızı bayrak yok, ilk 20 günde kırmızı bayrakta ikinci onay (`RedFlagView`); kartpostal paylaşımı (`ShareCardArt`, `ShareCardButton`, iOS paylaşım sayfası). Altı dilde metinler.

Son toplu aktarım (prototip v68–v85, Ekim 2026): telefon testi düzeltmeleri (alt panel şeridi ve yukarı çekme, sağ butonların hepsi, bölgeler kartı, bilet kartında kimin uçuracağı, ana ekrandan iki parmakla yakınlaşma, yakınlaşınca sabit ufuk ve üst çubuk, geniş yatay kaydırma, rüzgâr direği, yolcu toplama sahnesinde ofis önünde kuyruk ve safari cipleri, holding ofisi katı ve masalar), açılış aralıkları, sabah gazetesi, kurtarma planı, kış karı, Kapadokya festivalleri, rakip patronlar, sabah olayları (kamera olay yerine gider, grevde pankartlı pilotlar), bina yükseltmeleri ve direkte hava tahmini, pilot özellikleri, başarımlar ve kartpostal albümü, holding hedefleri ve Dünya Baronu, uçuş anları (termik, selam, fotoğraf), Çarşı (özel desenler, şekilli balonlar, süsler) ve atölyesiz bedava giydirme, ödüllü reklamla bölüm ödülü 2 katı, gece (ışıklar, süslerin gece aydınlatması, ateş böcekleri, cırcır böcekleri, gece olayları, kendiliğinden geçen gece ve büyük sabah düğmesi), fiyat sayfasında kurucu primi ve belgesel notu. Altı dilde metinler. Eski (v67) kayıtlar açılmaya devam eder: yeni alanların hepsi isteğe bağlı.

Ondan önceki aktarım (prototip v67'ye kadar): bölüm sonu ekranında biten hedefler, Devam'dan sonra yeni bölümün hedefleri; kasabaya ana ekranın içinde yakınlaşma. Daha önce (v64'e kadar): kurucu primi ve popülerlik tavanı, Şirketim kasabası, Hedef ve Holding butonları.

Aktarımda bilerek eksik ya da sade kalanlar (ileride):
- **Gerçek ödeme:** Çarşının satın alma kartı şimdilik test kartı, ürünü ödeme almadan verir (kartta "Test sürümü" yazar). StoreKit 2 için App Store Connect'te ürünler açılmalı: kimlikler `balloonbaron.<ürün>` (`StoreItem.productID`), desenler ve süsler Tier 1, şekiller Tier 2, hepsi non-consumable.

Sonradan tamamlananlar (Ekim 2026): 22 başarımın her biri prototipteki kendi kartpostal sahnesiyle (`pcScene`) çiziliyor; süs satın alma kartında kasabanın o süsle canlı gece önizlemesi var; holding ofisine kasabada kuleye süzülüp dalarak giriliyor, çıkınca kamera kulenin önüne döner; masaların açtığı sayfalar prototipteki gibi açık renk (krem sayfa, beyaz kartlar); beyaz tahta Caveat Brush el yazısıyla (uygulamaya gömülü, OFL lisansı `docs/licenses`), uzun hedefler tahtaya sığacak kadar küçülür. Her ofis sayfasının sonunda ortada küçük bir Tamam düğmesi, kapatılabilen her kartta sağ üstte ✕ var (v69/v70).

v86–v88 aktarımı (Ekim 2026): sabah gecenin kamerasıyla gelir (`NightCamera`, `GameStore.morningCamera`, `HomeTownView.startMorning`); kontroller o yakın görünümde kalır, yakınlaşınca (`endHold`) her zamanki gibi kayar; tam uzaklaşınca ufuk da süzülerek ana ekranınkine iner. Gün doğumu parıltısı gece ekranında yükselir, gece katmanı sabah kasabasının üstünde 1,4 saniyede söner. Gece ve sabah kasabası yana gündüzün yakın görünümü kadar kayar. Yolcu toplama ve sabah olayı kamerayı (ve ufku) olduğu yerden devralır; toplamadan sonra ana ekran görünümü gelir.

v89–v90 aktarımı (Ekim 2026): Ekip sayfasında pilotun birleşik kaza çarpanı (seviye × karakter, `Game.pilotRisk`, kaza hesabıyla aynı). Bölüm 1 (Kuruluş) yeni hedefleri: 2 balon, ilk pilot (yeni `GoalKind.pilots`), 4,3★, otel anlaşması, rüzgâr direği Sv. 2.
