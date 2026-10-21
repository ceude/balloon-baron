# Balloon Baron: Cappadocia — Oyun Tasarımı

Bu belge `prototype/balloon-baron.html` içindeki güncel mekanikleri ve sayıları özetler. Swift portu bu sayıları referans alır. Para birimi Kapadokya'da €, Albuquerque'de $ (aynı rakamlar), holding kasası her zaman €.

## Günlük döngü
1. **Sabah:** hava bayrağı (yeşil/sarı/kırmızı), fiyat, uçacak balonlar, kendin uçmak.
2. **Yolcu toplama:** zamanlayıcılı ekran. Yolcular kaynaklarına göre gelir (otel, rehber, influencer, pazar, tavsiye).
3. **Uçuş (SpriteKit):** brülörle ısı kontrolü, 4 rüzgâr katmanı (0–60, 60–180, 180–350, 350–650 m), hedef alana yumuşak iniş. Dikey hız > 2,6 ise sert iniş. Peribacasına çarpmak kaza sayılır. İptal edilirse kişi başı €40 tazminat ödenir.
4. **Gün sonu:** bilet tasarımlı uçuş defteri (gelir, giderler, olaylar, görev ödülü).
5. **Yönetim:** Filo, Ekip, Banka, Pazar sekmeleri.

## Başlangıç
Kasa €3.000, fiyat €170, popülerlik 1,0, temel talep 165 turist/gün. Sigorta ilk günden açık. Kurulumda şirket adı ve balon rengi seçilir (10 palet).

**Binaların açılışı** (her ders yerine otursun diye iki günde bir): sigorta 2. gün, hangar 4. gün (ya da kasa ≥ 7.000), banka 6. gün, pazar 8. gün, pilot ofisi 10. gün (ya da 2 balon). Hezarfen'in popülerlik dersi 9. gün, rakip ipuçları 10., 13. ve 16. gün.

## Balonlar
| Boy | Kapasite | Fiyat | Yakıt/uçuş | Bakım | Risk |
|---|---|---|---|---|---|
| S Küçük | 8 | 15.000 | 60 | 40 | ×0,8 |
| M Orta | 16 | 35.000 | 90 | 60 | ×1,0 |
| L Büyük | 24 | 60.000 | 120 | 80 | ×1,3 |
| XL Kapadokya Yıldızı | 32 | 150.000 | 170 | 140 | ×1,15 |

- XL özel tasarım dev balondur. Her uçuş +0,005 popülerlik verir.
- Ömür 120 uçuş (holding Ar-Ge'siyle 160 / 200). Yenileme fiyatın %35'i.

## Kurucu (sen)
- **Lisans:** En az 15 günde bir kendin uçmalısın. Lisans düşerse amiral dışındaki tüm balonlar yerde kalır. Ya amirali kendin uçurursun (ücretsiz yenileme uçuşu) ya da €15.000 ödersin.
- **Kurucu uçuşu primi:** Amiral balonunu sen uçurursan o balonun yolcuları %25 fazla öder.
- **Kurucu yokluğu:** 5 günden uzun süre kendin uçmazsan, balon uçan her gün popülerlik −0,008 (yaklaşık −0,03★) düşer. Hezarfen uyarır, yolcular yorumlarda kurucuyu sorar.

## Pilotlar
| Seviye | Maaş/gün | Kaza riski |
|---|---|---|
| Çaylak | 90 | ×1,6 |
| Deneyimli | 150 | ×1,0 |
| Kıdemli | 240 | ×0,6 |

- XP eşikleri 0 / 40 / 100.
- Rakipler pilot ayartabilir (günlük %4 şans).
- Pilot okulu €60.000'a kurulur.
- **Özellikler:** adayların %75'inin bir özelliği vardır: Şovmen (bahşiş +€9/yolcu), Temkinli (risk ×0,75), Gözü kara (risk ×1,3, uçuş başına popülerlik +0,003), Tutumlu (yakıt ×0,85), Sadık (ayartılamaz), Hikâyeci (popülerlik +0,002, iyi yorum), Gece kuşu (maaş ×0,85, sabah %7 şansla geç kalır ve o gün balonu uçmaz).
- **Atama:** Pilotlar önce uçabilecek balonlara, büyükten küçüğe atanır; onarımdaki veya zarfı bitmiş balonlar en sona kalır. Kıdemli ve tecrübesi (XP) yüksek olan önce gelir.

## Hava
| Bayrak | Kaza olasılığı | Not |
|---|---|---|
| Yeşil | 0,006 | Normal uçuş |
| Sarı | 0,03 | Risk yüksek |
| Kırmızı | 0,14 | Uçuş yasak. %35 yakalanma, €5.000 ceza, 3 uyarıda 3 gün yasak. Sigorta geçersiz. |

## Sigorta (balon başına, günlük)
- Gövde: max(değerin %0,1'i, p × değer × 0,21 × 1,3)
- Yolcu: max(kapasite × 2, p × kapasite × 1500 × 1,3)

Burada p, balonun kaza olasılığıdır (hava × boy × pilot).

## Krediler
| Tutar | Vade | Taksit/gün | Gereken balon |
|---|---|---|---|
| 10.000 | 40 gün | 300 | 0 |
| 25.000 | 45 gün | 650 | 2 |
| 50.000 | 50 gün | 1.250 | 3 |

Kasa −€5.000'in altına düşerse banka balona el koyar.

## Pazar ve popülerlik
- **Fiyat:** €40–320 arası.
- **Fiyat isteği:** `willing(p) = 1 / (1 + exp((p − 230) / 30))`
- **Çekicilik:** `rep² × (190 / p)^1.5 × koltuk`. Büyük şirket daha görünür. Popülerlik < 0,5 ise ×0,35 (kriz).
- **Popülerlik bonusu:** Rakiplerden bağımsız gelen yolcu, koltuklarının en fazla %50'si (2,8★'da 0, 5★'da %50), fiyat isteğiyle çarpılır.
- **Başlangıç baskısı:** 1. gün tek küçük balonla €170'te 7/8 dolar, dolması için yaklaşık €155'e inmek gerekir.
- **Turist sayısı:** Günün turisti fiyattan bağımsızdır (pazar talebi + otel misafirleri + rehber 5 + influencer 8 + fiyatsız popülerlik bonusu). Fiyat sadece kaçının seni seçtiğini değiştirir. Fiyat algısı eşikleri: fiyat isteği ≥%85 uygun, ≥%60 biraz pahalı, ≥%35 pahalı, altı çok pahalı.
- **Dağıtım sırası:** önce sözleşmeli kaynaklar (otel, rehber, influencer), sonra pazar, en son popülerlik bonusu. Boş koltuğu olanlara taşma havuzu dağıtılır.
- **Yıldız:** `clamp(3 + (rep − 0,75) × 4, 1, 5)`. Popülerlik 0,4–1,4 arasında tutulur.
- **PR tavanı:** Otel anlaşması ya da sahip olunan otel yoksa ve son 10 günde rehber uçuşu yapılmadıysa popülerlik 4,2★'ı geçemez; son 10 günde influencer kampanyası varsa tavan 4,5★.
- **4,5★ üstü:**
  - Günde −0,006 popülerlik.
  - İyi iniş popülerlik getirmez.
  - Uzak iniş iki kat kaybettirir.
  - Hezarfen bu konuda uyarır.
- **Rehber:** €1.500. Popülerlik artırır (+0,2★ civarı).
- **Influencer:** 2.500 + 400 × balon sayısı.

## Reklam sponsorları (uçuş başına, × (kapasite/8)^0,6)
| Sponsor | En küçük boy | Ödeme |
|---|---|---|
| Halı | S | 30 |
| Şarap | M | 55 |
| Banka | M | 90 |
| Enerji | L | 150 |

## Oteller
| Otel | Min ★ | Ücret/gün | Popülerlik | Misafir | Fiyat merkezi | Satın alma | Günlük gelir |
|---|---|---|---|---|---|---|---|
| Taş Otel | 2,0 | 60 | +0,005 | 4 | 200 | 40.000 | 350 |
| Konak | 3,0 | 120 | +0,0075 | 7 | 240 | 110.000 | 900 |
| Mağara Otel | 3,8 | 220 | +0,01 | 12 | 290 | 240.000 | 2.000 |
| Saray | 4,4 | 380 | +0,0125 | 18 | 340 | 520.000 | 4.300 |

**Kendi otelin:**
- 1,5× misafir, 1,5× popülerlik, ücret ödenmez.
- Popülerlik eşiğin altındaysa gelirin %50'si gelir.
- Kışın gelir ×0,6.

## Görevler
Ödül amiral balonunun boyuyla çarpılır: S ×1, M ×2, L ×3, XL ×4.

| Görev | Taban ödül |
|---|---|
| Evlilik teklifi: 250–350 m arasında kesintisiz 8 sn kal | 450 |
| Vadi | 300 |
| Panorama | 250 |
| Hassas iniş | 400 |

İlk görev her zaman evlilik teklifidir. Görev başarılırsa ödül sert inişte bile korunur. Başarı kutlaması alkış ve fanfarla yapılır.

## Rakipler
| Şirket | Tarz | Filo | Fiyat | Popülerlik | Kasa |
|---|---|---|---|---|---|
| Göreme Sky | temkinli | L L L M M M | 195 | 1,15 | 50.000 |
| Peribaca Balloons | orta | M M M S | 165 | 1,0 | 20.000 |
| Kızıl Vadi Air | riskli | S S S | 135 | 0,85 | 12.000 |

- Fiyat tabanı maliyetten hesaplanır (en fazla 220). Tavanlar: riskli 190, orta 260.
- 5. günden sonra zor durumdaki rakip satışa çıkar (filo satın alma veya devralma).
- **Büyüme:** 3 gün üst üste %70 üstü dolulukla uçan ve kasası balon fiyatının %60'ına yeten rakip 4 günde bir balon alır (temkinli L, diğerleri M). Tavanlar: temkinli 25, orta 18, riskli 12 balon. Sahipler kasadan para çeker ama bir sonraki balonun %60'ı kadar birikim bırakırlar.
- **Yeni girenler:** Bosphorus Balloons, Anatolian Sky, Peri Luxe Flights, Aegean Air Tours (Albuquerque'de Mesa Gold, Turquoise Trail, Desert Bloom, Big Sky Fiesta). Batan rakibin yerine 6+ gün sonra, günlük %30 şansla gelirler.
  - Zengin zincir (Bosphorus / Mesa Gold) oyuncunun balon sayısı + 3 balonla ve en az 60.000 + 9.000 × balon kasayla gelir.
  - Diğerleri 50. günden sonra oyuncunun yarısı kadar balonla gelir (ek balon başına +6.000 kasa).
  - Yeni gelenlerin kasasından 20 gün para çekilmez (savaş sandığı).
- **Birleşme:** 30. günden sonra oyuncunun payı %50'yi 4+ gün aşarsa günlük %35, ya da bir rakibin kasası −€4.000'in altındayken oyuncunun payı %40'ı aşarsa günlük %60 şansla en küçük iki rakip "A & B Balloons" olarak birleşir. Filolar toplanır, kasa (iki kasa) × 1,3 + 40.000, popülerlik yüksek olanınki, fiyat ortalama, 20 gün savaş sandığı. En fazla 25 günde bir.
- **Tekel cezası:** 20. günden sonra pazar payı > %60 olan her gün sayılır.
  - 3. günde Hezarfen uyarır (oran yazmaz).
  - 5 ve üstünde her gün %25 şansla max(€5.000, şirket değerinin %3'ü) ceza. Şirket değeri: pozitif kasa + balonların alış fiyatı + sahip olunan oteller.

## Bölümler ve Baron
Hedefler gün sonunda kontrol edilir. Bölüm bitince ödül kasaya girer, ertesi sabah tören açılır.

| Bölge | Bölüm | Ödül | Hedefler |
|---|---|---|---|
| Kapadokya | Kuruluş | 5.000 | 5 balon, 4,0★, otel anlaşması, kasada 20.000, rüzgâr direği Sv. 2 |
| Kapadokya | Büyüme | 20.000 | 10 balon, otel satın al, influencer, rehber, pazarın %50'si, balon atölyesi, hangar Sv. 2 |
| Kapadokya | Kapadokya Baronu | unvan | pazarın %70'i, 2 otel, pilot okulu, 4,8★, XL, bir bina Sv. 3 |
| Albuquerque | Yeni Dünya | 5.000 | 5 balon, 4,0★, otel anlaşması, rehber, rüzgâr direği Sv. 2 |
| Albuquerque | Fiesta | 20.000 | 10 balon, otel satın al, Fiesta'da uç, influencer, pazarın %50'si, hangar Sv. 2 |
| Albuquerque | Albuquerque Baronu | unvan | pazarın %70'i, 2 otel, pilot okulu, 4,8★, XL, bir bina Sv. 3 |

Simülasyon (`tools/sim-chapters.js`, 8 tohum, yeni açılış günleriyle): Kuruluş 52–64. gün, Büyüme 94–113. gün, Baron 125–188. gün. Yükseltme hedefleri olmadan 48–59 / 85–108 / 103–189; yükseltmeler kendini ödediği için fark küçük.

Bölüm ödülü kartında "Reklam izle, ödülü 2'ye katla: €10.000" düğmesi (toplam ödülü yazar): 30 saniyelik ödüllü reklam bitince ödül bir kez daha kasaya girer.

## Bina yükseltmeleri
Her bina 3 seviyelidir. Binaya dokununca kartında seviyeler ve sıradaki yükseltme görünür.

| Bina | Sv. 2 | Sv. 3 |
|---|---|---|
| Rüzgâr direği | €6.000: direğe dokununca yarının bayrağı | €25.000: iki gün sonrası da görünür, sarı bayrakta kaza riski ×0,8 |
| Hangar | €12.000: bakım ×0,85 | €45.000: bakım ×0,7, zarf yıpranması ×0,85 |
| Pilot ofisi | €10.000: pilot ayartma şansı %2 | €35.000: pilotlar ×1,5 XP kazanır |
| Satış ofisi | €15.000: talep ×1,05 | €50.000: talep ×1,12 |

## Sabah olayları
12. günden sonra (pilot ofisi açıksa, kış değilse) 7–8 günde bir. Kamera olayın yerine yakınlaşır, kart alttan çıkar. Aynı olay arka arkaya gelmez.
- **Pilot grevi** (en az 2 pilot): ofisin önünde pankartlı pilotlar. Zam (%15 kalıcı) ya da bir gün dayan (pilotlu balonlar uçmaz, amirali sen uçurursun, popülerlik −0,02).
- **VIP / Düğün** (boşta uçabilen balon): en büyük boş balonu kirala, peşin kapasite × fiyat × 2,2 (VIP) / × 1,4 (düğün), popülerlik +0,02 / +0,015. Balon o gün yolcu almaz.
- **Belgesel:** amiralde 4 koltuk o gün kameraya ayrılır (satılmaz), popülerlik +0,06.
- **Propan zammı** (en az 2 balon): 5 gün yakıt ×1,5; günlük yakıtın 5 günlüğünün %25'i ödenirse etkilenmez.
- **Basın röportajı:** %65 şansla popülerlik artar, yoksa düşer.

## Gece
Uçuş defterinden sonra kasabada gece olur (birkaç saniye, dokununca geçer): ışıklar yanar, cırcır böcekleri öter, ateş böcekleri uçar. Bazen bir gece olayı olur ve ertesi sabah gazetede çıkar: festival gecesi fener alayı, Fiesta'da Balloon Glow, kışın ilk gecesi karlı ışıklı kasaba, bir otelde düğün havai fişekleri (%22), kayan yıldız (%10). Olaylar şimdilik yalnızca görsel ve haber.

## Festivaller (Kapadokya)
24. günden başlayarak 35 günde bir, 3 gün: Bağ Bozumu, Bayram tatili, Işık Şenliği sırayla. Talep ×1,4, özel istek her gün çıkar, ödülleri ×1,5. Yollarda bayraklar asılır.

## Uçuş anları
Uçuşların %70'inde bir an çıkar: **termik** (65 m genişliğinde yükselen hava kolonu, 2 sn içinde kal: +15 yakıt), **selam** (başka bir balonun 95 m / 50 m yakınında 2 sn), **fotoğraf** (150–280 m arasında 1,5 sn, flaş). Başarılırsa yolcu başı bahşiş +€5 ve popülerlik +0,008.

## Gazete, rakip patronlar, kurtarma planı
- **Sabah gazetesi** (Kapadokya Postası / Albuquerque Herald) yalnızca bir şey olduysa gelir: kazalar, cezalar, rakip olayları, iflas, yeni rakip, rekor yolcu günü, festival, yükseltmeler.
- **Rakip patronlar:** Kenan Arslan (Göreme Sky) ve Dale Whitaker (Sandia Sky Rides). Selam (3. gün), bölüm başları, geçilince, otel kapışması, pilot ayartma, kazan, anlaşma, batış ve Baron töreninde konuşurlar; her söz bölge başına bir kez.
- **Kurtarma planı:** kasa eksiye düşünce adım adım seçenekler: boştaki pilotları çıkar, en küçük balonu %60'a sat, fiyatı en ucuz rakibin €10 altına çek, kredi al.

## Başarımlar ve holding hedefleri
- ☰ menüsünde "Başarımlar": 22 başarım, her biri bir kartpostal.
- Holding hedefleri (ofisteki beyaz tahtada yazılı): holding kasası €1 milyon, Albuquerque Baronu, bir TV kampanyası, ünlü reklam yüzü, Ar-Ge tamam, dört ofis. Hepsi bitince Dünya Baronu.

## Mağaza (uygulama içi satın alma)
Fiyatlar App Store'un yerel fiyat basamaklarıyla gösterilir (Avrupa'da):
- **Özel desenler** 0,99 €: Varak altın 92, İznik çinisi 90, Takımyıldız 92, Kapadokya kilimi 90 (desen tabanı).
- **Balon şekilleri** 1,99 €: Kalp, Yıldız, Hezarfen (sarıklı, bıyıklı). Tasarıma eklenir: yaratıcılık +8 ve her uçuşta ek popülerlik +0,0015.
- **Kasaba süsleri** 0,99 €: meydan çeşmesi, Hezarfen heykeli, fener dizileri, şirket bayrakları. Her biri kasabada görünür ve talebi %1 artırır. Gece her birinin kendi aydınlatması var (çeşmede su altı ışığı, heykelde spotlar, bayraklarda yukarı ışık, fener dizilerinde yollar boyunca ampul dizileri ve 8 lamba).
- Hepsi kasabadaki **Çarşı** binasından alınır (pazarla birlikte açılır). Desen ya da şekil şirket renklerinde hazır bir tasarımla gelir ve amiral balonuna hemen giydirilir; atölye gerekmez; bu tasarımlar her balona bedava giydirilir (normal tasarımda boya €1.000) (atölye yalnızca kendi tasarımını yapmak için). Atölyede bu desen ve şekiller kilitli görünür, oradan da alınabilir.


## Bölgeler ve otomatik mod
- Kapadokya baronu olunca holding açılır. Albuquerque'ye giriş €100.000 (holdingden). Orada sıfırdan başlanır: $3.000 ve bir S balon.
- Her bölgenin kendi kasası, bankası, filosu, pilotları, rakipleri, otelleri, popülerliği, bölümü vardır. Kurucu lisansı, atölye, tasarımlar ve gün sayacı ortaktır.
- **Kutu rüzgârı (Albuquerque):** katmanlar −, +, −, + yönünde. Hedef 1.000–1.700 m.
- **Balloon Fiesta:** her 30 günde bir, 4 gün, talep ×1,9 (ilki girişten 12 gün sonra).
- **Otomatik mod:** Ayrılınan bölge son 14 günün ortanca net kârının %85'ini (euroya çevrilmiş) her gün ±%15 oynayarak holdinge getirir.
- **Sorunlar:** son sorundan 6 gün sonra her gün %7. Karar verilene kadar kazanç yarıda.
  - Zam: kalıcı −%6 ya da 3 gün sıfır.
  - Fiyat savaşı: kalıcı −%10 ya da %50 şansla 10 gün −%25.
  - Sert iniş: bölgeye git (popülerlik −0,05) ya da 7 gün −%15.
  - Otel kapışması: 5 günlük kazanç öde ya da kalıcı −%5.
  - Yıpranan zarflar: 8 günlük kazanç öde ya da 10 gün −%12.

## Holding
- Holding kasası euro. Ülkelere para aktaramaz. Otomatik bölgelerin kazancı her gün gelir; oynanan bölgeden %25, %50 ya da 10.000 bırakıp hepsi çekilebilir (dolar 1,1'e bölünür).
- Giderler: otomatik gelirin %25'i (dört ofis açıksa %20).
- **TV kampanyası:** €250.000, 14 gün bütün bölgelerde talep +%20, bulunulan bölgede +0,1 popülerlik, 30 gün bekleme.
- **Ünlü reklam yüzü:** €600.000, 90 gün talep +%10, +0,15 popülerlik.
- **Billboard:** €120.000, bulunulan bölgede 20 gün talep +%10.
- **Zarf Ar-Ge'si:** €400.000 ile ömür 160, €900.000 ile 200 uçuş.
- **Ofisler:** İstanbul €350.000 (Kapadokya otomatik +%25), New York €450.000 (TV %25 ucuz, Albuquerque otomatik +%20), Seul €400.000 (ünlü sözleşmesi 180 gün ve €420.000), Tokyo €400.000 (tasarım bedava, yaratıcılık +10, tazelik 60 gün, ileride Asya girişi yarı fiyatına).

## Balon atölyesi ve tasarımlar
- Atölye €75.000, bir kez. Tasarım €5.000, balona giydirme €1.000.
- Yaratıcılık (5–100): desen tabanı × 0,6 + ana/desen rengi parlaklık farkı × 30 + (farklı renk − 1) × 6 + 10. Aynı desen ve ana renk tekrarı −20, yaşayan bir rakibin ana rengi −10.
- Desen tabanları: çizgili 35, zikzak 60, damalı 55, yıldızlı 70, kalpli 70, güneş 75, dalga 60, gökkuşağı 65, puantiyeli 50.
- Etki: tasarımlı balon her uçuşta 0,003 × puan/100 × tazelik (+0,0015 şekilli zarf), günlük en fazla 0,015. Tazelik 40 günde %100'den %20'ye iner. Parayla alınan desen ya da şekil içeren tasarımlar hiç eskimez.

## Kış
- En erken 40. gün, kasa ≥ €50.000 iken başlar ve 8 gün sürer.
- Bir sonraki kış 45 gün sonra gelir.
- Talep ×0,55. Bayrak olasılıkları: yeşil %35, sarı %35, kırmızı %30.
- Kasabaya kar yağar, çatılar ve zemin beyazlar.

## Hezarfen Usta
Yaşlı, karizmatik mentor. Daktilo efektli konuşma balonuyla konuşur. Konuları:
- karşılama, sigorta, filo, banka, pazar, ekip
- sarı ve kırmızı bayrak
- görev, kaza, kriz
- rakipleri batırma ipuçları
- beklenti (4,5★), tekel, eskime
- hedefler, holding, Albuquerque, Fiesta, bölge sorunları, ofisler, ünlü anlaşması
- dinamik haberler (kış, yeni rakip)

## Görsel ve ses
- **Renkler:** mürekkep #2b2350, mercan #ff5e3a, güneş #ffc23d, cam rgba(30,24,64,.84).
- **Fontlar:** Barlow ve Barlow Condensed.
- **Görseller:** gün doğumu Kapadokya, katmanlı peribacası silüetleri, kodla çizilmiş balonlar.
- **Sesler (sentez):** brülör gürültüsü, kuş ve ortam sesi, formant sesli kalabalık uğultusu, alkış, fanfar, para, tık.

## Yerelleştirme
Metinler altı dilde: İngilizce (kaynak), Türkçe, Almanca, İspanyolca, Japonca, Korece. Swift'te String Catalog kullanılır (`tools/strings`). Türkçe ek uyumu ("Balon'a/Air'e") için metinler şirket adının arkasına ek gelmeyecek şekilde yazılır.
