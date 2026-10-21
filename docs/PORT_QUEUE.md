# Swift'e aktarılacaklar

Prototipte yapılıp henüz iOS koduna geçmemiş değişiklikler. Karar verilince toplu olarak aktarılır.

## Tasarım incelemesi (v77–v78)
Ayrıntılı sayılar `docs/GAME_DESIGN.md`'de. Hepsi yeni metin ister (altı dil).
- **Açılış aralıkları:** sigorta 2, hangar 4 (ya da €7.000), banka 6, pazar 8, pilot ofisi 10 (ya da 2 balon); `pr` dersi 9. gün, rakip ipuçları 10/13/16.
- **Sabah gazetesi:** olay varsa sabah ilk kart; bölgeye göre "Kapadokya Postası" / "Albuquerque Herald". Çekirdek `PaperItem` (id + değerler) üretir.
- **Kurtarma planı:** kasa eksiye düşünce adım adım kart (pilot çıkar, en küçük balonu %60'a sat, fiyatı rakibin altına çek, kredi).
- **Kış karı:** kış günlerinde kasabaya kar yağar, çatı ve zemin beyazlar.
- **Festivaller (Kapadokya):** 24. günden 35 günde bir, 3 gün, talep ×1,4, görev ödülü ×1,5, yollarda bayraklar.
- **Rakip patronlar:** Kenan Arslan ve Dale Whitaker, SVG yüz, konuşma kartında patron stili; satır listesi `BOSS_LINES`.
- **Sabah olayları:** grev (ofis önünde pankartlı pilotlar), VIP, düğün, belgesel, propan zammı, basın. Kamera olay yerine yakınlaşır, etiketler gizlenir, kart alttan çıkar.
- **Bina yükseltmeleri:** direk, hangar, pilot ofisi, satış ofisi 3 seviye; bina kartı; direkte hava tahmini (yarın / öbür gün), direk çiziminde istasyon kutusu ve radar kubbesi. Bölüm hedeflerine yükseltme hedefleri.
- **Pilot özellikleri:** yedi özellik, aday ve ekip listesinde etiket.
- **Başarımlar:** ☰ menüsünde albüm, 22 kartpostal; holding hedefleri ve Dünya Baronu, tahtada marker yazısı.
- **Uçuş anları:** termik, selam, fotoğraf; yeşil şerit, gün sonunda bahşiş ve popülerlik.
- **Mağaza (v78):** özel desenler, şekilli zarflar (kalp, yıldız, Hezarfen; `envShape`), kasaba süsleri (çeşme, heykel, fenerler, bayraklar) ve Çarşı binası (12,15; 3,1). StoreKit 2 ürünleri: desenler ve süsler Tier 1, şekiller Tier 2; non-consumable. Bölüm ödülünde ödüllü reklamla 2 katı (reklam SDK'sı seçilecek).

## Telefon testinden sonra (v68, düzeltmeler v69)
- **v76:** Yakınlaşınca üst çubuk (gün, para, popülerlik, menü) yerinde kalır; sadece rüzgâr kartı, yan butonlar, yorum ve alt panel kayarak çıkar. ✕ üst çubuğun altında. Ana ekranda önce dokunmaya gerek yok: iki parmakla açınca kasaba doğrudan o noktadan yakınlaşmaya başlar (ilk %4'lük açılmadan sonra), parmak kalkmadan yakınlaşma sürer. Ana ekran boyutuna kadar kapatınca geri döner.
- **v75:** Kasabada fırlatma alanının köşesinde (7,15; 4,15) rüzgâr direği: tüf kaide, kırmızı-beyaz direk, tepede dönen kepçeli rüzgârölçer (hız rüzgârla artar), kırmızı-beyaz rüzgâr tulumu. Tulum günün yer rüzgârının (0–60 m katmanı) yönünü gösterir; sert rüzgârda dimdik, sakinde sarkık, hafifçe dalgalanır. Gölgesi var.
- **v74:** Rüzgâr kartı sol üstte, üst çubuğun hemen altında. Yolcu yorumları rüzgâr kartının altında çıkar, sola dayalı; genişlik en fazla 400 pt ve sağdaki butonların altına girmez (ekran genişliği − buton sütunu − boşluk). Kasaba rüzgâr kartının altından başladığı için biraz büyüdü.
- **v73:** Holding ofisinde birim sayfaları ekrana sığar: sayfa en fazla ekran yüksekliği − 70 pt, içerik sıkıştırılmaz, sayfa parmakla kayar (kaydırma arkadaki sahneye geçmez). (Swift'te ScrollView + `.presentationDetents([.large])` yeterli.)
- **v72:** Bilet kartında yolcu ve tutar satırının altında, çubuktan sonra kimin uçuracağı yazar: "Sen uçuracaksın", "Sen ve pilotun uçuracak", "Sen ve pilotların uçuracak", "Pilot uçuracak", "Pilotlar uçuracak".
- **v70:** Alt panel parmakla tutup yukarı çekince de açılır (kapalıyken tarayıcı kaydırması kapalı, sürükleme 18 pt'de açar). Ufuk uzakta: yakınlaşınca kasabanın üstüne inmez, uzak vadinin arkasında kalıp yukarı çekilir; uzaklaşınca ana ekrandaki yerinin altına inmez. Üst çubuktaki bölge adına (birden çok bölge varsa, yanında ▾) dokununca "Bölgelerin" kartı: sahip olunan bölgeler (Buradasın ✓ / Geç ›, otomatik mod ya da sorun durumu), Dünya haritası, Kapat. Sayfa sonundaki Tamam küçük, ortalı (44 pt yükseklik).
- **v69:** Ufuk çizgisi yakınken ve yolcu toplarken hiç oynamaz (ana ekrandaki yerinde sabit; kaydırınca da). Kasabadan bir binayı açınca sayfa doğru bölüme kayar ama sayfanın kendisi kaymaz (eskiden tüm ekran kayıp başlık ve ✕ ekrandan çıkıyor, alttaki panel sayfanın üstüne biniyordu). Her sayfanın sonunda "Tamam", sağ üstte ✕. Kapatılabilen her kartta (Hedefler, bina kartları, bölüm sonu vb.) sağ üstte ✕ var; alttaki Kapat/Tamam/Devam ne yapıyorsa onu yapar. Zorunlu seçim kartlarında (ör. pilot ayartma) ✕ yok.
- **Ufuk sabit:** yakınlaşınca ufuk çizgisi ana ekrandaki yerinden aşağı inmez (gökyüzü büyümez); vadi geriye doğru uzar. `TOWN.hz` = ana ekranın ufku, `townHorizon` bunun altına düşmez.
- **Yatay kaydırma:** yakınken sola/sağa duvarın iki köşesine kadar rahatça gidilir (sınır 16 karo genişliği, ekranın %15–85'i). Dikey sınır aynı.
- **Alt panel şerit oldu:** kapalıyken yalnızca tutamaç, tek satır şerit (en acil uyarı + kalan sayı, filo "uçacak/toplam", sigorta durumu), bilet kartı ve Pas geç / Yolcu topla. Şeride ya da tutamaca dokununca veya yukarı çekince tüm kartlar açılır (uyarılar, filo, sigortalar); aşağı çekince kapanır. Panel yarı saydam; kasaba ekranın tamamına çizilir, panelin arkasında ve kenarlarında harita görünür. Kasaba kapalı şeridin üstüne oturur.
- **Sağ butonlar geri:** Hedef, (Baron olunca) Holding, Filo, Ekip, Banka, Pazar (açıldıkça). Ekip ve Pazar'da uyarı noktası. Butonlar biraz küçüldü (44 pt kutu), kasaba butonların solundaki alana ortalanır.
- **Yolcu toplama sahnesi:** arka plan kasabaya geçer ve 0,8 sn'de senin ofisine (kiosk sırasının ilki) yakınlaşır; etiketler gizli. Yolcular yoldan yürüyüp ofisin önünde sıraya girer (gerçek sayı; 30'dan fazlaysa en fazla 30 figür temsili), üstte "N yolcu" etiketi. Kalkışa basınca panel kapanır, 6 kişilik açık safari cipleri (en fazla 5) yoldan gelip sıranın önüne dizilir, yolcular binip etiket sayısı azalır, cipler yola çıkıp ekrandan gider; ~3,5 sn sonra uçuş açılır.
- **Holding ofisi:** Holding butonu ya da kuleye dokunmak kasabada kuleye yakınlaşır (z 1,5) ve ofis katı açılır (solarak + hafif ölçek). Sahne: krem duvar, ahşap parke, sağ üstte büyük pencereden gündoğumunda kasaba ve süzülen balonlar, solda beyaz tahtada son 14 günün holding kasası çizgi grafiği (yeşil marker, çizilerek gelir), dört masa (çalışan, monitör, masa eşyası): Pazarlama (TV + billboard), Anlaşmalar (ünlü reklam yüzü), Ar-Ge (zarf araştırması), Ofisler (dünya ofisleri). Etiketler: "Kasa ve aktarım" (grafik + bölge kasasından aktarım), "Bölgeler" (pencere), birimler; altlarında durum (ör. "TV yayında, 5 gün", "Ofis: 1/4"; sorunlu bölgede kırmızı nokta). Dokununca alttan açık renkli sayfa açılır; eski lacivert-altın panel renkleri oyunun krem/mercan/yeşil renklerine çevrildi. ✕ ofisten çıkar, kasabada kuleye geri döner.

Son toplu aktarım (prototip v67'ye kadar): bölüm sonu ekranında biten hedefler, Devam'dan sonra yeni bölümün hedefleri; kasabaya ana ekranın içinde yakınlaşma (kontroller yukarı ve aşağı kayarak çıkar, yuvarlak X ya da iki parmakla uzaklaşınca geri gelir; ayrı Şirketim sayfası kalktı). Ondan önce (v64'e kadar): kurucu primi %25 ve popülerlik tavanı (4,2★, influencer ile 4,5★), Hezarfen'in `pr`, `influ`, `prcap` dersleri, Şirketim kasabası (`BalloonBaron/Town/`: izometrik çizim, dört otel, gündoğumu, uzak balonlar, kuma yazılı bölgeler, tam ekran görünüm ve ana ekrandaki kasaba), Hedef ve Holding butonları, bölge uyarı noktaları.

Bir önceki toplu aktarım: filo/ekip arayüzü, sade ana ekran ve fiyat paneli, tekel cezası, pazar kartları, güçlü rakipler ve birleşmeler, bölümler ve Baron, Albuquerque ve otomatik mod, tasarım stüdyosu, holding ve ofisler.

Aktarımda bilerek eksik kalanlar (ileride):
- (yok)
