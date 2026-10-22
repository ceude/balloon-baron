# Swift'e aktarılacaklar

Prototipte yapılıp henüz iOS koduna geçmemiş değişiklikler. Karar verilince toplu olarak aktarılır.

(Şu an kuyruk boş: Swift uygulaması prototip v94 ile aynı.)

Son toplu aktarım (prototip v68–v85, Ekim 2026): telefon testi düzeltmeleri (alt panel şeridi ve yukarı çekme, sağ butonların hepsi, bölgeler kartı, bilet kartında kimin uçuracağı, ana ekrandan iki parmakla yakınlaşma, yakınlaşınca sabit ufuk ve üst çubuk, geniş yatay kaydırma, rüzgâr direği, yolcu toplama sahnesinde ofis önünde kuyruk ve safari cipleri, holding ofisi katı ve masalar), açılış aralıkları, sabah gazetesi, kurtarma planı, kış karı, Kapadokya festivalleri, rakip patronlar, sabah olayları (kamera olay yerine gider, grevde pankartlı pilotlar), bina yükseltmeleri ve direkte hava tahmini, pilot özellikleri, başarımlar ve kartpostal albümü, holding hedefleri ve Dünya Baronu, uçuş anları (termik, selam, fotoğraf), Çarşı (özel desenler, şekilli balonlar, süsler) ve atölyesiz bedava giydirme, ödüllü reklamla bölüm ödülü 2 katı, gece (ışıklar, süslerin gece aydınlatması, ateş böcekleri, cırcır böcekleri, gece olayları, kendiliğinden geçen gece ve büyük sabah düğmesi), fiyat sayfasında kurucu primi ve belgesel notu. Altı dilde metinler. Eski (v67) kayıtlar açılmaya devam eder: yeni alanların hepsi isteğe bağlı.

Ondan önceki aktarım (prototip v67'ye kadar): bölüm sonu ekranında biten hedefler, Devam'dan sonra yeni bölümün hedefleri; kasabaya ana ekranın içinde yakınlaşma. Daha önce (v64'e kadar): kurucu primi ve popülerlik tavanı, Şirketim kasabası, Hedef ve Holding butonları.

Aktarımda bilerek eksik ya da sade kalanlar (ileride):
- **Gerçek ödeme:** Çarşının satın alma kartı şimdilik test kartı, ürünü ödeme almadan verir (kartta "Test sürümü" yazar). StoreKit 2 için App Store Connect'te ürünler açılmalı: kimlikler `balloonbaron.<ürün>` (`StoreItem.productID`), desenler ve süsler Tier 1, şekiller Tier 2, hepsi non-consumable.
- **Ödüllü reklam:** Bölüm sonundaki reklam düğmesi 30 saniyelik geri sayımla ödülü verir, gerçek reklam SDK'sı seçilip bağlanmadı.

Sonradan tamamlananlar (Ekim 2026): 22 başarımın her biri prototipteki kendi kartpostal sahnesiyle (`pcScene`) çiziliyor; süs satın alma kartında kasabanın o süsle canlı gece önizlemesi var; holding ofisine kasabada kuleye süzülüp dalarak giriliyor, çıkınca kamera kulenin önüne döner; masaların açtığı sayfalar prototipteki gibi açık renk (krem sayfa, beyaz kartlar); beyaz tahta Caveat Brush el yazısıyla (uygulamaya gömülü, OFL lisansı `docs/licenses`), uzun hedefler tahtaya sığacak kadar küçülür. Her ofis sayfasının sonunda ortada küçük bir Tamam düğmesi, kapatılabilen her kartta sağ üstte ✕ var (v69/v70).

v86–v88 aktarımı (Ekim 2026): sabah gecenin kamerasıyla gelir (`NightCamera`, `GameStore.morningCamera`, `HomeTownView.startMorning`); kontroller o yakın görünümde kalır, yakınlaşınca (`endHold`) her zamanki gibi kayar; tam uzaklaşınca ufuk da süzülerek ana ekranınkine iner. Gün doğumu parıltısı gece ekranında yükselir, gece katmanı sabah kasabasının üstünde 1,4 saniyede söner. Gece ve sabah kasabası yana gündüzün yakın görünümü kadar kayar. Yolcu toplama ve sabah olayı kamerayı (ve ufku) olduğu yerden devralır; toplamadan sonra ana ekran görünümü gelir.

v89–v90 aktarımı (Ekim 2026): Ekip sayfasında pilotun birleşik kaza çarpanı (seviye × karakter, `Game.pilotRisk`, kaza hesabıyla aynı). Bölüm 1 (Kuruluş) yeni hedefleri: 2 balon, ilk pilot (yeni `GoalKind.pilots`), 4,3★, otel anlaşması, rüzgâr direği Sv. 2.
