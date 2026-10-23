# Swift'e aktarılacaklar

Prototipte yapılıp henüz iOS koduna geçmemiş değişiklikler. Karar verilince toplu olarak aktarılır.

## Bekleyenler (prototip v104)

- **Luksor bölgesi** (`RegionID.lux`): Albuquerque baronu olunca açılır, giriş €150.000, başlangıç €5.000. Rakipler Theban Skies / Pharaoh Balloons / Nile Dawn Air, yeni girenler Red Sea Balloon Co. / Felucca Flights / Hatshepsut Air / Karnak Wings (sayılar `docs/GAME_DESIGN.md`). Patron Nabil Haddad (avatar ve `BOSS_LINES.lux` repliklerinin hepsi). `rivalEdge` Luksor'u da kapsar.
  - Dört bölüm: Batı Yakası, Nil Rüzgârı, Firavunlar Vadisi, Luksor Baronu.
  - Birleşme kuralı Luksor'da daha sık (15 gün ara, %38 pay sayılır, 2 gün, %50).
  - Nil gemisi sezonu: `fiesta` alanını kullanır, 21 günde bir, 3 gün, talep ×1,6; uyarılar, "Nil gecesi" gece olayı.
  - Hava katmanları +, −, +, −. Gazete "Nil Postası". Otel, sponsor, balon ve pilot adları `REGION_DEF.lux`.
  - Hezarfen'in giriş uyarısı ("en çetin pazar"), başarımlar `lux` ve `baronLux` (kartpostal sahneleriyle).
  - Uçuş manzarası: Teb tepeleri ve el-Kurn, tapınak, hurmalar, yeşil Nil vadisi, feluka; engeller hurma ağacı.
  - Giriş ekranı (`IntroScene`) Luksor teması. Dünya haritasında Luksor artık "yakında" değil.
- **Bölgeye göre kasaba:** Albuquerque ve Luksor'da duvar renkleri (`TUFF_BY`), düz çatılar (`flatRoof`: vigalar / kubbe), kenarda peri bacası yerine mesa ya da dikilitaş ve hurma kümesi, ağaçlar (kaktüs, yucca, kavak / hurma), çevre arazi renkleri ve tarlalar, Luksor'da Nil şeridi, uzak sırtlar (mesalar / Teb tepeleri ve hurma siluetleri), zemin renkleri, mağara otel yerine kayaya oyulmuş oda (Albuquerque) ya da Nubya evi (Luksor), otel bahçesinde servi yerine kavak / hurma, holding ofisinin penceresindeki manzara. Süsler her bölgede.
## Bekleyenler (prototip v105)

- **Çarşı etiketi:** etiket yüksekliği 82 (önceden varsayılan 135'ti ve bankanın üstüne çıkıyordu). Dokunmada önce binanın kendi zemini, sonra etiket kutusu sayılır (`townHit`).
- **Albuquerque kasabası:** kenardaki mesalar kalktı. Mağara otel yerine basamaklı kerpiç (pueblo) bina.
- **Brülör ve dönüş valfi** (balon başına, `Balloon.burner` 1–3, `Balloon.tvent`; ikisi de isteğe bağlı alan). Filo sayfasında "Donanım" kartı.
  - Çift brülör: balon fiyatının %10'u, kaza riski ×0,85, uçuşta ısınma ×1,3.
  - Üçlü brülör: %12 daha, risk ×0,72, ısınma ×1,6.
  - Dönüş valfi: %6, sarı ve kırmızı bayrakta risk ×0,85, uçuşta sert iniş eşiği 2,6 yerine 3,1.
- **Paraşüt valfi:** uçuşta havalanınca "Uçuştan vazgeç" yerine VALF düğmesi çıkar. Basılı tutunca ısı saniyede ekstra 0,07 düşer. İlk kullanımda ipucu çıkar.
- **Elektrik hatları:** uçuşta en fazla 3 hat (190–280 birim, 42–58 m). Altında alçak uçmak ya da altına inmek kaza demek, kaza metni "Elektrik hattına takıldın!".
- **Müfettiş:** bir zarf %30'un altındaysa 5 günde bir denetim. 1. ve 2. ziyarette uyarı, 3. ziyaretten itibaren yıpranmış balon başına 2.500 ceza ve gazete haberi. Bölgeye göre: SHGM / FAA / Mısır Sivil Havacılık. Kendi portresi var (`inspDay`, `inspN` bölge alanları).
- **Bölgesel rehberler:** Hezarfen Kapadokya'da kalır. Albuquerque'de Ben Franklin, Luksor'da İmhotep, kendi portreleriyle. Bölgeye girerken Hezarfen'in sözü, ardından yeni rehberin tanışma konuşması. Baron metni, otomatik mod sorunları ve rakip taktikleri düğmesi o bölgenin rehberiyle.
- **Holding 5. masa, Rekor projesi:** Luksor'a girmeden kilitli. İrtifa rekoru €400.000, 25 gün, %65 şans, talep kalıcı +%5. Durmadan dünya turu €900.000, 40 gün, %50 şans, +%10. Her rekorun ilk denemesi hep başarılı (oyuncuya gösterilmez); sonra "Rekoru geliştir" denemelerinde oranlar geçerli, başarı talebe +%2 ekler (toplam en fazla +%25). Aynı anda bir deneme.
- **Holding 6. masa, Sponsorlu özel şekiller:** Fizz Cola şişesi (30 gün, €4.000/gün), Yıldız Telekom roketi (45 gün, €6.500/gün), Kanat spor ayakkabısı (60 gün, €9.000/gün). Sözleşme imzalanan bölgede popülerlik her gün 0,001 / 0,0015 / 0,002 düşer (yıldız olarak 0,004 / 0,006 / 0,008). Balon kasabanın üstünde uçar.
- **Dünya haritası:** Bristol (İngiltere) ve Maasai Mara (Kenya) yalnızca isim olarak var, açılmazlar. Asya "???" kaldı.

- **Metinler** (altı dil): Luksor adı, ülke, bölüm adları ve hedefleri, rakip ve patron replikleri, Nil sezonu uyarıları, Hezarfen uyarısı, gazete adı, başarım adları.

Önceki durum: Swift uygulaması prototip v103 ile aynıydı. v101: XL balonun adı "Dev balon", "İmza balon" etiketi kalktı.

v98–v100 aktarımı (Ekim 2026): reklam yok (bölüm kartındaki reklam düğmesi ve `doubleChapterReward` kalktı); Hezarfen balonu yerine Kurukafa balon (`StoreItem.skull`, `EnvelopeShape.skull`; eski kayıtlardaki "hezarfen" kurukafa olarak okunur); Hezarfen övgüleri (`Praise`, `Game.praiseCheck`, `HezMessage.praise`, düğme "Sağ ol usta"); ilk 3 günde kırmızı bayrak yok, ilk 20 günde kırmızı bayrakta ikinci onay (`RedFlagView`); kartpostal paylaşımı (`ShareCardArt`, `ShareCardButton`, iOS paylaşım sayfası). Altı dilde metinler.

Son toplu aktarım (prototip v68–v85, Ekim 2026): telefon testi düzeltmeleri (alt panel şeridi ve yukarı çekme, sağ butonların hepsi, bölgeler kartı, bilet kartında kimin uçuracağı, ana ekrandan iki parmakla yakınlaşma, yakınlaşınca sabit ufuk ve üst çubuk, geniş yatay kaydırma, rüzgâr direği, yolcu toplama sahnesinde ofis önünde kuyruk ve safari cipleri, holding ofisi katı ve masalar), açılış aralıkları, sabah gazetesi, kurtarma planı, kış karı, Kapadokya festivalleri, rakip patronlar, sabah olayları (kamera olay yerine gider, grevde pankartlı pilotlar), bina yükseltmeleri ve direkte hava tahmini, pilot özellikleri, başarımlar ve kartpostal albümü, holding hedefleri ve Dünya Baronu, uçuş anları (termik, selam, fotoğraf), Çarşı (özel desenler, şekilli balonlar, süsler) ve atölyesiz bedava giydirme, ödüllü reklamla bölüm ödülü 2 katı, gece (ışıklar, süslerin gece aydınlatması, ateş böcekleri, cırcır böcekleri, gece olayları, kendiliğinden geçen gece ve büyük sabah düğmesi), fiyat sayfasında kurucu primi ve belgesel notu. Altı dilde metinler. Eski (v67) kayıtlar açılmaya devam eder: yeni alanların hepsi isteğe bağlı.

Ondan önceki aktarım (prototip v67'ye kadar): bölüm sonu ekranında biten hedefler, Devam'dan sonra yeni bölümün hedefleri; kasabaya ana ekranın içinde yakınlaşma. Daha önce (v64'e kadar): kurucu primi ve popülerlik tavanı, Şirketim kasabası, Hedef ve Holding butonları.

Aktarımda bilerek eksik ya da sade kalanlar (ileride):
- **Gerçek ödeme:** Çarşının satın alma kartı şimdilik test kartı, ürünü ödeme almadan verir (kartta "Test sürümü" yazar). StoreKit 2 için App Store Connect'te ürünler açılmalı: kimlikler `balloonbaron.<ürün>` (`StoreItem.productID`), desenler ve süsler Tier 1, şekiller Tier 2, hepsi non-consumable.

Sonradan tamamlananlar (Ekim 2026): 22 başarımın her biri prototipteki kendi kartpostal sahnesiyle (`pcScene`) çiziliyor; süs satın alma kartında kasabanın o süsle canlı gece önizlemesi var; holding ofisine kasabada kuleye süzülüp dalarak giriliyor, çıkınca kamera kulenin önüne döner; masaların açtığı sayfalar prototipteki gibi açık renk (krem sayfa, beyaz kartlar); beyaz tahta Caveat Brush el yazısıyla (uygulamaya gömülü, OFL lisansı `docs/licenses`), uzun hedefler tahtaya sığacak kadar küçülür. Her ofis sayfasının sonunda ortada küçük bir Tamam düğmesi, kapatılabilen her kartta sağ üstte ✕ var (v69/v70).

v86–v88 aktarımı (Ekim 2026): sabah gecenin kamerasıyla gelir (`NightCamera`, `GameStore.morningCamera`, `HomeTownView.startMorning`); kontroller o yakın görünümde kalır, yakınlaşınca (`endHold`) her zamanki gibi kayar; tam uzaklaşınca ufuk da süzülerek ana ekranınkine iner. Gün doğumu parıltısı gece ekranında yükselir, gece katmanı sabah kasabasının üstünde 1,4 saniyede söner. Gece ve sabah kasabası yana gündüzün yakın görünümü kadar kayar. Yolcu toplama ve sabah olayı kamerayı (ve ufku) olduğu yerden devralır; toplamadan sonra ana ekran görünümü gelir.

v89–v90 aktarımı (Ekim 2026): Ekip sayfasında pilotun birleşik kaza çarpanı (seviye × karakter, `Game.pilotRisk`, kaza hesabıyla aynı). Bölüm 1 (Kuruluş) yeni hedefleri: 2 balon, ilk pilot (yeni `GoalKind.pilots`), 4,3★, otel anlaşması, rüzgâr direği Sv. 2.
