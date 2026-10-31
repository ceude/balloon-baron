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

**Binaların açılışı** (v121.9, TestFlight: hiçbir şey açılmayan günler boş geçiyordu; artık 2.–11. günler arasında her gün bir şey açılır ve Hezarfen anlatır): sigorta 2. gün, hangar ve filo 3. gün (ya da kasa ≥ 7.000), banka 4. gün, pilot ofisi ve ekip 5. gün (ya da 2 balon), pazar, oteller ve şirketler 6. gün, rehber ofisi 7. gün, influencer ajansı 8. gün, çarşı 9. gün, balon atölyesinin arsası 10. gün, pilot okulunun arsası 11. gün. Popülerlik tavanı (4,2★) ve Hezarfen'in otel uyarısı pazar açıldıktan sonra başlar. Eski kayıtlarda o sayfalarla gelen binalar açık kalır.

## Balonlar
| Boy | Kapasite | Fiyat | Yakıt/uçuş | Bakım | Risk |
|---|---|---|---|---|---|
| S Küçük | 8 | 15.000 | 60 | 40 | ×0,8 |
| M Orta | 16 | 35.000 | 90 | 60 | ×1,0 |
| L Büyük | 24 | 60.000 | 120 | 80 | ×1,3 |
| XL Kapadokya Yıldızı | 32 | 150.000 | 170 | 140 | ×1,15 |

- XL, Dev balondur (v101'e kadar adı "Özel tasarım dev balon / İmza balon" idi). Her uçuş +0,005 popülerlik verir.
- Ömür 120 uçuş (holding Ar-Ge'siyle 160 / 200). Yenileme fiyatın %35'i.

## Kurucu (sen)
- **Toplu zarf yenileme:** Filo sayfasındaki düğme %30'un altındaki bütün zarfları birden yeniler; tutar her balonun yenileme bedelinin (balon fiyatının %35'i) toplamıdır.
- **Lisans:** En az 15 günde bir kendin uçmalısın. Lisans düşerse amiral dışındaki tüm balonlar yerde kalır. Ya amirali kendin uçurursun (ücretsiz yenileme uçuşu) ya da €15.000 ödersin.
- **Geçici amiral:** Kendi uçurduğun amiral balon tamirdeyse sabah sorulur: tamir bitene kadar başka bir balonu sen uçurmak ister misin? En büyük uçabilen balon önerilir, listeden değiştirilebilir. Evet dersen o balon tamir süresince amiral olur ve tamir bittiği sabah gerçek amiral kendiliğinden geri döner. Hayır dersen diğer balonları pilotlar uçurur. Her tamir için bir kez sorulur, uçuş yasağında sorulmaz.
- **Kendi balonun (v111):** Filo'da bir balona dokunup "Bu balonu ben uçurayım" dersen o balon amiralin olur ve onu sen uçurursun; filo listesinde yanında "Sen uçuruyorsun" yazar. Balonlara isim verilebilir (en fazla 18 harf, iki balon aynı adı taşıyamaz); varsayılan isim değiştirilene kadar kalır. Varsayılan isimlerden kelime olanlar (Şafak, Güvercin, Dev balon adları) ve Mısır yer adları her dilde o dilin yazımıyla gösterilir.
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
- **Elle atama (v124.4):** oyuncu balon kartından pilotu ya da pilot kartından balonu seçebilir; pilot o balona sabitlenir. Başka balondaki bir pilot seçilirse ikisi yer değiştirir (öbür balon bu balonun eski pilotunu alır). "Otomatik" sabitlemeyi kaldırır. Sabit pilotlar önce yerleşir, kalanlar yukarıdaki kuralla dağılır. Sabit balon onarımdaysa, zarfı bittiyse ya da kurucu uçuruyorsa pilot o gün boşta kalmaz, başka balona geçer; sabitleme durur. Kovulan, ayartılan ya da ayrılan pilotun sabitlemesi düşer. Boşta pilot varken uçabilecek bir balon pilotsuz kalmaz.
- **Baş harf:** Kapadokya'da soyadı baş harfleri Türk alfabesinden (Q, W, X ve Ğ yok; Ç, Ö, Ş, Ü, İ var). Eski kayıtlarda Q/W/X olan pilotlar K/V/S olur.

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
| 100.000 | 80 gün | 1.500 | 8 + günlük net ≥ 10.000 |

Kasa −€5.000'in altına düşerse banka balona el koyar.

100.000 kredisi (v109.1) bölgenin son 14 günlük ortanca net kazancı 10.000'i ilk geçtiği akşam açılır ve bir daha kapanmaz. Simülasyon (`tools/sim-loans.js`; bot krediyi açıldığı gün çekip hepsini balona harcıyor): 10 tohumda 94–122. günde açıldı, hiç el koyma yok.

**Satın alma kredisi (v109.2):** bankanın kredi listesinde değil; satılık bir rakip ya da iflas etmiş bir filo olunca teklif kartında ve Pazar'da "Krediyle al" düğmesi çıkar. Konut kredisi gibi: banka eksik tutarı doğrudan satıcıya öder, kasaya para girmez. Oyuncu kasasından ödeyebildiğini öder, kasada €10.000 kalır; bu pay fiyatın en az %20'si olmalı. Banka en fazla 500.000 öder; 150 gün, faiz %20 (taksit = ödenen × 1,2 / 150, 10'a yuvarlanmış). Aynı anda tek satın alma kredisi; sadece 100.000 kredisi açıldıktan sonra ve filoda en az 10 balon varken (v109.3; azsa teklif kartı gereken ve mevcut balon sayısını yazar). Kasa fiyata yetiyorsa sadece nakit seçeneği çıkar, kredi sunulmaz. Onay kartı fiyatı, senin payını, bankanın payını, taksiti, toplamı ve kış/bakım/el koyma uyarısını gösterir.

Simülasyon (`tools/sim-buyloan.js`; bot satılık bir rakibi parası yetmezse her seferinde krediyle alıyor, mevsime bakmadan):
- Hiç sınır yokken: 6–30. günde, tek balonla rakip alıyor; 12 tohumun yarısından fazlası battı.
- 100.000 açılmış olsun: batan yok ama üst üste 4 şirket alınca 12'nin 9'unda banka balona el koydu.
- + %20 peşinat + aynı anda tek kredi: 12 tohumun 10'unda el koyma yok, 2'sinde 1–2 balon; batan yok.
- + en az 10 balon (v109.3, son hâli): 7–9 balonla erken alım yapan 3 tohum bekledi; 12 tohumun 9'unda el koyma yok, 3'ünde 1–2 balon; batan yok. Kural küçük şirketin kasayı 6–8 bine kadar düşürmesini engelliyor, ama geç ve pahalı alımı engellemiyor.

**Bütün oyun simülasyonu (`tools/sim-economy.js`, v109.3):** 400 gün, 12 tohum, aynı şansla beş bot.

| Bot | Batan | Balon kaybeden oyun (balon) | Bölüm günleri (ort.) | Baron (ort. gün) |
|---|---|---|---|---|
| Hiç borç almayan | 0 | 3 (9) | 28 / 62 / 141 / 171 | 171 |
| Dikkatli (kışın almaz, taksit < günlük netin 1/3'ü) | 0 | 10 (21) | 25 / 60 / 142 / 162 | 162 |
| Pervasız, sadece eski krediler (10–50k) | 0 | 6 (15) | 8 / 36 / 121 / 140 | 140 |
| Pervasız, bütün krediler | 0 | 9 (17) | 8 / 36 / 114 / 139 | 139 |
| İflas filosunu alıp hemen satan | 0 | 3 (3) | 28 / 65 / 115 / 153 | 153 |

- Yeni krediler (100k, satın alma) oyunu kısaltmıyor: pervasız bot ile eski kredili pervasız bot aynı günde baron oluyor. Hızlanmayı eski küçük krediler yapıyor (ilk bölüm 28 yerine 8. gün).
- Dikkatli botun el koymalarının çoğu satın alma kredisi sürerken ve tekel cezasıyla aynı gün: rakibi alınca pazar payı sıçrıyor, Rekabet Kurumu cezası taksitle üst üste geliyor.
- Açık (v109.3'te bulundu): iflas filosu filo değerinin %45'ine satılıyor, oyuncu her balonu %60'a satabiliyordu; alıp hemen satan bot 400 günde 3,7–5,6 milyon fazladan kazanıyordu. v110'da rakipten alınan balonlar ikinci el (%40) oldu: aynı bot şimdi 0,7–1,1 milyon zarar ediyor.
- Rakip iflası oyun sonunda çok sıktı (150. günden sonra 24). v110 denemeleri (bot "none", 12 tohum):

| Kural | 150. gün sonrası iflas | Sahadaki rakip (ort.) | Baron (gün) | 400. gün kasası |
|---|---|---|---|---|
| Eski | 24 | 2,01 | 171 | 2,57 M |
| Yeni gelen 14–60 gün bekler | 7 | 1,15 | 147 | 6,04 M |
| Daha zengin yeni gelen (40 günlük gider) | 21 | – | 166 | 2,52 M |
| Rakip önce küçülür | 17 | 2,23 | 161 | 2,64 M |
| Küçülme + iflastan sonra 14 gün (seçilen) | 14 | 1,98 | 157 | 2,93 M |

  Uzun bekleme iflası en çok azaltıyor ama pazarı boşaltıp oyuncuyu çok zenginleştiriyor; seçilen kural rakip sayısını korur.
- v110 sonrası bütün botlar (12 tohum): batan yok. Pervasız botlarda (her krediyi çekip kışa giren) el koyma arttı (7–11 oyunda), çünkü rakipler batmak yerine küçülüp sahada kalıyor.
- Prototipte kurtarma planı kazanç şartlı 100.000 kredisini açılmamışken de öneriyordu; Swift'teki gibi sadece şartsız krediler önerilecek şekilde düzeltildi (v109.3).

Önceki tasarım (v109.1, kaldırıldı): bankada günlük net 50.000 ile açılan 500.000 kredisi; parası toplu balona harcanınca doymuş pazarda kışın iki tohumda şirketi batırıyordu.

## Pazar ve popülerlik
- **Neden bu kadar yolcu? (v124.6):** bilet fiyatı ekranında fiyat ölçerin altında, yalnız o gün geçerli olanlar satır satır çıkar:
  - **Popülerlik:** senin yıldızın ve rakiplerin ortalaması, turist ilgisi yüzde olarak. Formül pazar dağıtımındaki çekicilik: rep², 2★ altında ×0,35, rakip ortalamasının rep²'sine bölünür.
  - **Turist sayısı:** festival, fiesta, kış, bayrak, satış ofisi ve holding yatırımlarının çarpanı.
  - **Doğrudan gelenler:** otel anlaşmaları, rehber tavsiyesi, influencer, şölen ve popülerlik bonusu, "+N yolcu" olarak.

  İlk günlerde yalnız popülerlik satırı vardır; diğerleri oyuncu onları edindikçe görünür.
- **Boş koltuk dersi (v124.6):** 2–12. günlerde koltuk boş kaldıysa Hezarfen sebebi ayırır:
  - fiyat pahalıysa (turistlerin %70'inden azı razı) fiyatı düşür (`price`),
  - popülerlik 2★'ın altındaysa ya da rakiplerin %60'ından az ilgi görüyorsan sebep yıldızlar (`priceRep`),
  - ikisi de iyiyse gökyüzünde turistten çok koltuk vardır (`priceRiv`).

  Rehberli fiyat dersi, hiçbir balonun uçamadığı günde çıkmaz.
- **Rapor:** yıldız değiştiyse "Popülerlik 4,0★ → 3,5★" satırı ve en büyük üç sebep çıkar (sert iniş, kaza, görev, oteller, reklamlar, kurucu yokluğu, zamanla ortalamaya dönme…).
- **Fiyat:** €40–320 arası.
- **Fiyat isteği:** `willing(p) = 1 / (1 + exp((p − 230) / 30))`
- **Çekicilik:** `rep² × (190 / p)^1.5 × koltuk`. Büyük şirket daha görünür. Popülerlik < 0,5 ise ×0,35 (kriz).
- **Popülerlik bonusu:** Rakiplerden bağımsız gelen yolcu, koltuklarının en fazla %50'si (2,8★'da 0, 5★'da %50), fiyat isteğiyle çarpılır.
- **Başlangıç baskısı:** 1. gün tek küçük balonla €170'te 7/8 dolar, dolması için yaklaşık €155'e inmek gerekir.
- **Turist sayısı:** Günün turisti fiyattan bağımsızdır (pazar talebi + otel misafirleri + rehber 4–7 + influencer 5–12, seçilen kişiye göre, + fiyatsız popülerlik bonusu). Fiyat sadece kaçının seni seçtiğini değiştirir. Fiyat algısı eşikleri: fiyat isteği ≥%85 uygun, ≥%60 biraz pahalı, ≥%35 pahalı, altı çok pahalı.
- **Dağıtım sırası:** önce sözleşmeli kaynaklar (otel, rehber, influencer), sonra pazar, en son popülerlik bonusu. Boş koltuğu olanlara taşma havuzu dağıtılır.
- **Yıldız:** `clamp(3 + (rep − 0,75) × 4, 1, 5)`. Popülerlik 0,4–1,4 arasında tutulur.
- **PR tavanı:** Otel anlaşması ya da sahip olunan otel yoksa ve son 10 günde rehber uçuşu yapılmadıysa popülerlik 4,2★'ı geçemez; son 10 günde influencer kampanyası varsa tavan 4,5★.
- **4,5★ üstü:**
  - Günde −0,006 popülerlik.
  - İyi iniş popülerlik getirmez.
  - Uzak iniş iki kat kaybettirir.
  - Hezarfen bu konuda uyarır.
- **Rehber ofisi (v122):** kendi ekranı, üç rehberden biri seçilir; bekleme süresi ortaktır. Rehberin turistleri fiyat isteğiyle çarpılır.

  | Rehber | Ücret | Popülerlik | Süre | Turist/gün | Bekleme |
  |---|---|---|---|---|---|
  | Ayşe, otel rehberi | €900 | +0,03 (≈+0,1★) | 2 gün | 4 | 4 gün |
  | Sena, tur rehberi (eski tek anlaşma) | €1.500 | +0,05 (≈+0,2★) | 3 gün | 5 | 5 gün |
  | Ekin, kıdemli rehber | €2.400 | +0,07 (≈+0,3★) | 4 gün | 7 | 6 gün |

  v124: Ayşe, Sena ve Ekin yalnız Kapadokya'da. Diğer bölgelerin rehber ofisinde aynı üç sıra (ücret, etki, id'ler aynı) yerel adlarla: Albuquerque Emily, Carlos, Dakota; Luksor Nour, Karim, Yasmin; Bristol Olivia, Harry, Imogen (`GUIDE_NAMES`, `guideName`). Influencer adları ("Yerel gezgin" vb.) kişi adı olmadığı için değişmedi.
- **Influencer ajansı (v122):** kendi ekranı, üç influencer; fiyat 2.500 + 400 × balon sayısı ile çarpılır (100'e yuvarlanır). Kampanya süresince her gün +0,03 popülerlik (eskisi gibi).

  | Influencer | Fiyat | Popülerlik | Süre | Turist/gün | Bekleme |
  |---|---|---|---|---|---|
  | Yerel gezgin | × 0,6 | +0,06 (≈+0,2★) | 2 gün | 5 | 8 gün |
  | Gezi influencerı (eski tek kampanya) | × 1 | +0,10 (≈+0,4★) | 3 gün | 8 | 10 gün |
  | Ünlü gezgin | × 1,8 | +0,16 (≈+0,6★) | 4 gün | 12 | 12 gün |

  Rehber yalnız rehber ofisinden, influencer yalnız ajanstan yapılır (iki bina, iki ekran; eski evet/hayır kartları kalktı). Popülerlik kartındaki "Popülerliğini toparla" satırları bu iki ekranı açar. Kurtarma planındaki rehber seçeneği Mehmet'tir. Gece ajansın havuz ışığı ajans açılınca, çarşının ampulleri çarşı açılınca yanar.

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

- **Otel satışı (v118):** sahip olunan otel alış fiyatının %60'ına satılır (Pazar'daki otel kartında "Sat"). Kurtarma planında, otelin varsa en küçüğünü satma seçeneği çıkar. Satmadan önce bir kart sorar: oteli en popüler rakip satın alır; o rakip ayakta olduğu sürece bu otelle anlaşma yapılamaz (kartta "Sahibi: X"), otel ancak ondan geri alınır ve fiyatı %10 fazladır (oyunda yazmaz, sadece fiyat görünür). Rakip yoksa otel serbest kalır. Oteli alan rakip batarsa "Satılık otel" kartı çıkar: otel bir kez alış fiyatının %70'ine sana önerilir; geçersen piyasaya döner. O rakibi sen satın alırsan otel bedavaya sana geçer; iki rakip birleşirse otel yeni firmaya geçer.

## Görevler
Ödül amiral balonunun boyuyla çarpılır: S ×1, M ×2, L ×3, XL ×4. v124.6: şirket büyüdükçe görev ödülü günlük kazançla da büyür; ödül en az günlük netin (son 14 günün ortancası) %8 × taban/400'üdür (evlilik teklifi %9, panorama %5). Hangisi büyükse o, festivalde ×1,5, 10'a yuvarlanır. Erken oyunda eski ödül geçerli; günlük net €28.000 iken evlilik teklifi €2.520, €40.000 iken €3.600.

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

Albuquerque'nin şirketleri Kapadokya'dakilerden güçlü (v96):

| Rakip | Tarz | Filo | Fiyat | İtibar | Kasa |
|---|---|---|---|---|---|
| Sandia Sky Rides | temkinli | L L L L M M M M | 205 | 1,2 | 90.000 |
| Rio Grande Balloons | orta | L M M M M S | 170 | 1,05 | 40.000 |
| Route 66 Air | riskli | M S S S S | 140 | 0,9 | 20.000 |

Luksor en çetin pazar (v104). Patron Nabil Haddad'ın Theban Skies'ı en büyük filoya sahip:

| Rakip | Tarz | Filo | Fiyat | İtibar | Kasa |
|---|---|---|---|---|---|
| Theban Skies | temkinli | L L L L L M M M M M | 215 | 1,28 | 130.000 |
| Pharaoh Balloons | orta | L L M M M M S | 175 | 1,1 | 60.000 |
| Nile Dawn Air | riskli | M M S S S S | 130 | 0,95 | 30.000 |

Luksor'un yeni girenleri: Red Sea Balloon Co. (zengin zincir), Felucca Flights, Hatshepsut Air, Karnak Wings.

Albuquerque ve Luksor rakipleri daha sert oynar (`RIVAL_EDGE`, Swift'te `RegionID.rivalEdge`): kampanya olasılığı günde %6 (Kapadokya %4), otel anlaşmanı kapma %2,5 (%1,5), 3 günde bir balon alabilirler (4) ve filo üst sınırları 5 fazla (30/23/17). Bot üç bölümü 65–79 / 107–126 / 141–230. günlerde bitirir (önce 57–66 / 99–108 / 136–210).

- Fiyat tabanı maliyetten hesaplanır (en fazla 220). Tavanlar: riskli 190, orta 260.
- 5. günden sonra zor durumdaki rakip satışa çıkar (filo satın alma veya devralma).
- **Küçülme (v110):** kasası −€5.000'in altına düşen rakip, 3 balonun üstündeyse her gün bir balonunu yarı fiyatına satar. İflas (kasa −€10.000 altı) ancak küçülecek balon kalmayınca gelir. İflas filosu filo değerinin %45'ine satılır.
- **İkinci el (v110):** devralınan ya da iflas filosundan alınan balonlar ikinci eldir: satış %40 (yeni balon %60), bankanın el koyması %30 (yeni %50). Filo kartında "İkinci el" etiketi, teklif kartında açıklama var.
- **Pilotlarıyla devralma (v121.13):** bir rakibi devralınca pilotları da mevcut sözleşmeleriyle gelir, balon başına bir pilot. Seviye rakibin tarzına göre (temkinli: %60 kıdemli, %35 deneyimli, %5 çaylak; orta: %25/%55/%20; riskli: %10/%40/%50), maaş seviyenin maaşının %90–110'u. Satış kartı pilot sayısını, seviyelerini ve günlük maaş toplamını gösterir. İflas eden şirketin filosu da pilotlarıyla gelir (oyuncu iki anlaşmayı ayırt edemez).
- **Büyüme:** 3 gün üst üste %70 üstü dolulukla uçan ve kasası balon fiyatının %60'ına yeten rakip 4 günde bir balon alır (temkinli L, diğerleri M). Tavanlar: temkinli 25, orta 18, riskli 12 balon. Sahipler kasadan para çeker ama bir sonraki balonun %60'ı kadar birikim bırakırlar.
- **Yeni girenler:** Bosphorus Balloons, Anatolian Sky, Peri Luxe Flights, Aegean Air Tours (Albuquerque'de Mesa Gold, Turquoise Trail, Desert Bloom, Big Sky Fiesta). Batan rakibin yerine 6+ gün sonra (bölgede bir rakip iflas ettikten sonra 14+ gün, v110), günlük %30 şansla gelirler.
  - Zengin zincir (Bosphorus / Mesa Gold) oyuncunun balon sayısı + 3 balonla ve en az 60.000 + 9.000 × balon kasayla gelir.
  - Diğerleri 50. günden sonra oyuncunun yarısı kadar balonla gelir (ek balon başına +6.000 kasa).
  - Yeni gelenlerin kasasından 20 gün para çekilmez (savaş sandığı).
- **Birleşme (Luksor):** rakipler daha sık birleşir. 20. günden sonra oyuncunun payı %38'i aştığı her gün de sayılır, 2 gün yeter, şans günlük %50, birleşmeler arası en az 15 gün.
- **Birleşme:** 30. günden sonra oyuncunun payı %50'yi 4+ gün aşarsa günlük %35, ya da bir rakibin kasası −€4.000'in altındayken oyuncunun payı %40'ı aşarsa günlük %60 şansla en küçük iki rakip "A & B Balloons" olarak birleşir. Filolar toplanır, kasa (iki kasa) × 1,3 + 40.000, popülerlik yüksek olanınki, fiyat ortalama, 20 gün savaş sandığı. En fazla 25 günde bir.
- **Tekel cezası:** 20. günden sonra pazar payı > %60 olan her gün sayılır.
  - 3. günde Hezarfen uyarır (oran yazmaz).
  - 5 ve üstünde, payın o gün de %60'ın üstünde olduğu her gün %25 şansla max(€5.000, şirket değerinin %3'ü) ceza (v110: önceden kırmızı bayrakta yerde kalınan gün de gelebiliyor, gazete %0 yazıyordu). Şirket değeri: pozitif kasa + balonların alış fiyatı + sahip olunan oteller.

## Bölümler ve Baron
Filo hedefleri v124.6'dan beri balon sayısı değil koltuk sayısıdır (S 8, M 16, L 24, XL 32), böylece her balon boyu adil sayılır; sadece küçük balon almak eskisi kadar hızlı değil (sim, 6 tohum, Kapadokya: karışık filo bölümleri 12/67/107/143. günde, önce 12/61/101/141; sadece S 12/45/85/121, önce 12/36/88/122). Hedefler her işlemden sonra kontrol edilir: bir bölümün bütün hedefleri tuttuğu anda ödül kasaya girer ve tören hemen açılır (v108). Baron bölümü de öyle (v109): bütün hedefleri aynı anda tuttuğu an baron olursun. Bölüm kartlarında "Bölüm 2/4" büyük başlıkla yazar.

| Bölge | Bölüm | Ödül | Hedefler |
|---|---|---|---|
| Kapadokya | Kuruluş | 5.000 | 16 koltuk, ilk pilot, 4,3★, otel anlaşması, rüzgâr direği Sv. 2 |
| Kapadokya | Yükseliş | 10.000 | 64 koltuk, influencer, rehber, hangar Sv. 2 |
| Kapadokya | Büyüme | 20.000 | 150 koltuk, otel satın al, pazarın %50'si, balon atölyesi |
| Kapadokya | Kapadokya Baronu | unvan | pazarın %70'i, 2 otel, pilot okulu, 4,8★, XL, bir bina Sv. 3 |
| Albuquerque | Yeni Dünya | 5.000 | 32 koltuk, 2 pilot, 4,6★, 2 otel anlaşması, rehber, rüzgâr direği Sv. 2 |
| Albuquerque | Kutu Rüzgârı | 10.000 | 100 koltuk, influencer, 4,7★, 2 tur grubunu eksiksiz uçur (v125, eskiden rüzgâr direği Sv. 3), hangar Sv. 2 |
| Albuquerque | Fiesta | 20.000 | 180 koltuk, otel satın al, Fiesta'da uç, 3 tur grubunu eksiksiz uçur (herhangi bir şirket, v125), pazarın %50'si |
| Luksor | Batı Yakası | 5.000 | 48 koltuk, 3 pilot, 4,7★, 2 otel anlaşması, rehber, rüzgâr direği Sv. 2 |
| Luksor | Nil Rüzgârı | 10.000 | 120 koltuk, influencer, 4,75★, pazarın %30'u, rüzgâr direği Sv. 3, hangar Sv. 2 |
| Luksor | Firavunlar Vadisi | 20.000 | 220 koltuk, otel satın al, Nil gemisi sezonunda uç, pazarın %50'si |
| Luksor | Luksor Baronu | unvan | pazarın %70'i, 2 otel, pilot okulu, 4,8★, XL (Teb Yıldızı), hangar Sv. 3 |
| Albuquerque | Albuquerque Baronu | unvan | pazarın %70'i, 2 otel, pilot okulu, 4,8★, XL, hangar Sv. 3 |

İki bölgede de 4 bölüm var (prototip v97). Albuquerque her bölümde Kapadokya'dan bir kademe zor. Araya giren ikinci bölüm, eskiden 1. ile 2. bölüm arasındaki yaklaşık 80 günlük boşluğu böler. Balon atölyesi holdinge ait olduğu için Albuquerque'de hedef olamaz; yerine Fiesta ve hangar Sv. 3 var. Üç bölümlü plandan gelen kayıtlar yüklenirken bölüm numarası kaydırılır (2. bölümü geçmiş olan 3.'ye geçer), kimse geriye düşmez.

Bütün oyunu (Kapadokya → holding → Albuquerque → holding hedefleri → Dünya Baronu) oynayan botla ortanca bitiş günleri (60 oyun):

| Oyuncu | Kap. B1 | B2 | B3 | Baron | Abq B1 | B2 | B3 | Baron | Dünya Baronu |
|---|---|---|---|---|---|---|---|---|---|
| Usta (tycoon meraklısı) | 8 | 46 | 88 | 123 | 152 | 194 | 219 | 306 | 315 |
| Pek oyun bilmeyen yetişkin | 29 | 86 | 141 | 173 | 229 | 300 | 328 | 369 | 404 |
| Çocuk | 54 | 107 | 196 | 250 | 319 | 414 | 440 | 498 | 517 |

Üç bölümlü planda aynı oyuncular 8 / 89 / 124 (usta) ve 29 / 142 / 171 (pek oyun bilmeyen) günlerinde bitiriyordu.

Kuruluş Ekim 2026'da (prototip v90) "5 balon, 4,0★, kasada 20.000" yerine "2 balon, ilk pilot, 4,3★" oldu: 4,0★ ilk gün kendiliğinden tamamlanıyordu, 5 balon da bölümü 52–66. güne uzatıyordu. Aynı botla Kuruluş artık 17–33. günde (çoğunlukla 18–20) biter, 4,3★ 8. gün civarında gelir. Albuquerque'de bölge 4,0★ ile sıfırdan başladığı için Yeni Dünya da aynı sorunu taşıyordu (4,0★ ilk gün, 5 balon 54–65. gün); v92'de, oyuncu buraya tecrübeli geldiği için Kapadokya'dan daha zorlu oldu: "4 balon, 3 pilot, 4,6★, 2 otel anlaşması, rehber, direk Sv. 3". Bot onu 57–66. günde bitirir; hedefler zamana yayılır: oteller ve rehber 8. gün, 4,6★ 10–13., direk Sv. 3 34–44., balonlar ve pilotlar 57–66. gün. Baron bölümündeki "bir binayı 3. seviyeye çıkar" hedefi, Yeni Dünya'daki direk Sv. 3 ile kendiliğinden tamamlanmasın diye "hangar Sv. 3" oldu. Bot üç bölümü 57–66 / 99–108 / 136–210. günlerde bitirir. Eski simülasyon (`tools/sim-chapters.js`, 8 tohum, yeni açılış günleriyle): Kuruluş 52–64. gün, Büyüme 94–113. gün, Baron 125–188. gün. Yükseltme hedefleri olmadan 48–59 / 85–108 / 103–189; yükseltmeler kendini ödediği için fark küçük.

Oyunda reklam yok (v98). Bölüm ödülü tek sefer verilir; eskiden bölüm kartında ödülü reklamla 2'ye katlama düğmesi vardı.

## Balon donanımı (v105)
- **Brülör:** tek (standart), çift (balon fiyatının %10'u, kaza riski ×0,85, ısınma ×1,3), üçlü (%12, ×0,72, ×1,6). Yedek brülör güvenlik olarak pazarlanır.
- **Dönüş valfi:** %6. Sarı ve kırmızı bayrakta kaza riski ×0,85; kurucu uçuşunda sert iniş eşiği 2,6 yerine 3,1 m/s.
- **Paraşüt valfi:** uçuşta VALF düğmesi, basılı tutunca hızlı alçalış.
- **Elektrik hatları:** uçuşta engel, altına inilmez.
- **Müfettiş:** zarf %30 altındayken 5 günde bir denetim. İki uyarı, sonra her ziyarette yıpranmış balon başına 2.500 ceza.

## Bina yükseltmeleri
Her bina 3 seviyelidir (hangar v127'den beri 8). Binaya dokununca kartında seviyeler ve sıradaki yükseltme görünür.

| Bina | Sv. 2 | Sv. 3 |
|---|---|---|
| Rüzgâr direği | €6.000: direğe dokununca yarının bayrağı | €25.000: iki gün sonrası da görünür, sarı bayrakta kaza riski ×0,8 |
| Hangar | €12.000: bakım ×0,85 | €45.000: bakım ×0,7, zarf yıpranması ×0,85 |
| Pilot ofisi | €10.000: pilot ayartma şansı %2 | €35.000: pilotlar ×1,5 XP kazanır |
| Satış ofisi | €15.000: talep ×1,05 | €50.000: talep ×1,12 |

### Hangar kapasitesi (v127)
Hangar seviyesine göre balon alır. Seviye numarası oyundaki gibi 1'den başlar (sahibin tablosundaki "Sv.0" = oyunda Seviye 1); Luksor, Albuquerque ve Bristol baron bölümlerindeki "Hangar seviyesi: 3" hedefi aynı kalır (€45.000'lik kumaş deposu, 24 balon).

| Seviye | Kapasite | Yükseltme (bölgenin parasıyla, aynı sayı) | Etki |
|---|---|---|---|
| 1 | 6 | başlangıç | |
| 2 | 12 | 12.000 | bakım ×0,85 |
| 3 | 24 | 45.000 | bakım ×0,7, zarf yıpranması ×0,85 |
| 4 | 48 | 120.000 | yalnızca yer (İkinci hangar) |
| 5 | 96 | 350.000 | yalnızca yer (Büyük hangar) |
| 6 | 192 | 900.000 | yalnızca yer (Hangar kompleksi) |
| 7 | 384 | 2.400.000 | yalnızca yer (Balon üssü) |
| 8 | 768 | 6.000.000 | yalnızca yer (Dev balon üssü) |

- Balon almak, şirket devralmak, batan filoyu almak, atölye üretimi ve kargo **engellenmez**. Kapasiteyi aşan balonlar **dışarıda** durur: bakım yapılamadığı için uçamazlar, pilot almazlar, günlük bakım gideri ödenmez; uçuş ve pazar kapasitesine (bugünkü uçuş, Balon Şöleni / Gece Işıltısı filosu, kontrat koltukları, yakıt stoğu olayı, otomatik ilerletmenin 35 balonu, mecburi pas) sayılmazlar. Bölüm hedeflerindeki koltuk ve balon sayıları, başarımlar ve rakiplerin oyuncunun filosuna göre büyümesi bütün balonları sayar (değişmedi). Rakipler etkilenmez.
- Hangarın içi: amiral her zaman içeride; diğerleri filoya giriş sırasıyla, en yeniler dışarıda. Hangar büyüyünce kendiliğinden içeri girer, pilot alırlar.
- Uyarılar: oyuncunun kendi alımında (balon, devralma, batan filo) "Hangarda yer yok" kartı: "Hangarın dolu: N balon dışarıda kaldı. Hangarı geliştirmen lazım." ve "Hangarı geliştir" düğmesi. Atölye üretimi ve kargo gelince aynı cümle Hezarfen'in haberi olarak gelir. Filo sayfasının başında kırmızı satır "Dışarıda N balon: uçamıyorlar · Hangarı geliştir ›" (hangarın yükseltme kartını açar); uçuş planında dışarıdakiler listelenmez, altta aynı satır; balon kartında da. Filo listesinde dışarıdakiler en altta, soluk ve "Dışarıda" etiketli; "Dışarıda" süzgeci. Hezarfen sabahları hatırlatır, en fazla 5 günde bir: "Dışarıda N balonun var evlat; hangara giremeyip bakım yapılamadığı için uçamıyorlar. Hangarın seviyesini yükselt." (bir uyarı kartı da bu 5 günü baştan başlatır; otomatik ilerletmeyi durdurmaz, haber olarak bekler).
- Eski kayıtlar: bedava geçiş yok, hangar seviyesi olduğu gibi kalır, fazla balonlar dışarıda başlar. 393–400 balonlu kayıt: dışarıdakiler bir kerede hesaplanır (prototipte önbellek, Swift'te `statusByID` / `outsideIDs`), filo listesi Swift'te tembel (`LazyVStack`).
- Simülasyon (`tools/sim-campaign.js`, 24 tohum; bot hangar dolunca bir sonraki balondan önce hangarı aynı nakit payıyla büyütür): bölgeye girişten bölüm bitişine ortalama gün, önce → sonra: Kapadokya 10,9 / 67,3 / 112,4 / 147,6 → 10,9 / 67,3 / 114,7 / 148,9; Albuquerque 53,9 / 78,8 / 104,7 / 140,6 → 53,4 / 78,6 / 107,0 / 141,8; Luksor 60,3 / 86,9 / 109,8 / 141,3 → 58,5 / 85,1 / 111,2 / 139,7; Bristol 57,7 / 104,3 / 134,6 / 157,5 → 56,9 / 102,4 / 133,8 / 152,5; Dünya Baronu 595,5 → 591,8. En büyük fark %3,2 (Bristol Baronu, erken); %5'in altında, fiyatlar değişmedi. `tools/sim-chapters.js` (Kapadokya, 8 tohum, 260 gün) bölüm günleri aynı; bot hangarı 25–43. günde Sv. 2'ye, 89–101. günde Sv. 3'e çıkarır.

## Sabah olayları
12. günden sonra (pilot ofisi açıksa, kış değilse) 7–8 günde bir. Kamera olayın yerine yakınlaşır, kart alttan çıkar. Aynı olay arka arkaya gelmez.
- **Pilot grevi** (en az 2 pilot): ofisin önünde pankartlı pilotlar. Zam (%15 kalıcı) ya da bir gün dayan (pilotlu balonlar uçmaz, amirali sen uçurursun, popülerlik −0,02).
- **VIP / Düğün** (boşta uçabilen balon): en büyük boş balonu kirala, peşin kapasite × fiyat × 2,2 (VIP) / × 1,4 (düğün), popülerlik +0,02 / +0,015. Balon o gün yolcu almaz.
- **Belgesel:** amiralde 4 koltuk o gün kameraya ayrılır (satılmaz), popülerlik +0,06.
- **Yakıt zammı** (en az 2 balon): 5 gün yakıt ×1,5; günlük yakıtın 5 günlüğünün %25'i ödenirse etkilenmez.
- **Basın röportajı:** %65 şansla popülerlik artar, yoksa düşer.

## Gece
Uçuş defterinden sonra kasabada gece olur (3,5 sn, olay gecesi 5,5 sn; kasabayı gezerken bekler, en fazla 25 sn; alttaki düğmeyle hemen sabaha geçilir): ışıklar yanar, cırcır böcekleri öter, ateş böcekleri uçar. Bazen bir gece olayı olur ve ertesi sabah gazetede çıkar: festival gecesi fener alayı, Fiesta'da Balloon Glow, kışın ilk gecesi karlı ışıklı kasaba, bir otelde düğün havai fişekleri (%22), kayan yıldız (%10). Olaylar şimdilik yalnızca görsel ve haber.

## Açılış (v120–v121.6)
Eski başlangıç hikâyesinin yerine sinematik bir açılış. 3B, kodla üretilmiş bir Kapadokya (three.js); WebGL yoksa ya da yüklenemezse v119'un 2B açılışı oynar.
- **Tek parça drone çekimi (~30 sn), karanlıktan gün doğumuna:**
  1. Üç Güzeller: yıldızların altında üç kapaklı peri bacasının etrafında alçak dönüş, "KAPADOKYA · Şafaktan hemen önce".
  2. Uçhisar Kalesi: pencereleri yanık kaya kütlesi, yamaçta evler ve minare, "UÇHİSAR · Kalede ilk ışıklar".
  3. Peri bacası vadisi: bacaların arasından alçak geçiş; yerde brülörleri yanan balonlar.
  4. Göreme'de bir otelin çatı terası (kilim, fener, minder, sehpa): güneş doğarken peribacalarının üstünden yükselen balonlar, "GÖREME · Güneş balonlarla doğar".
  5. Köyün kenarındaki tarla: eski sepet ve yere serili kumaş. Hezarfen tek cümle söyler; isim ve renk seçilir.
- **Kalkış (~12 sn):** kumaş şirketin renkleriyle (adı da üstünde) brülörle şişer, alttan yukarı bakan kameranın yanından yükselir, kamera vinçle yukarı çıkıp köyün ve balonlarla dolu gökyüzünün üstünde durur; şirketin adı ve "Gün 1", karartma, ana ekran.
- **Görüntü:** peri bacaları gürültüyle oyulmuş altı ayrı biçim (yumrular, katmanlar, oyuklar, bazılarında bazalt kapak), oyma kapı ve pencereler (bir kısmı ışıklı); evler yuvarlak köşeli beş tip (sıvalı, kesme taş, tonozlu, kademeli, revaklı) ve kendi cephe dokularıyla; mağara evli kayalar; yerde kayalar ve çalılar; vadide sis, ışıkta toz; parlama (bloom), vinyet, ince film greni; sinema şeritleri ve HTML yazılar.
- Sağ üstte "Geç ›" her iki çekimi de atlar.
- **Müzik (v121):** WebAudio ile kodla: rüzgâr, sabit bas (gün doğarken açılan filtre), doğru anlarda bas vuruşları ve yükselen geçişler, Hicaz makamında ney cümleleri, kalkışta darbuka (maksum) ve yaylılar; balon şişerken brülör sesi.

- **Filmin sonu (v121.5):** kalkıştan sonra kamera balondan uzaklaşıp ondan hızlı yükselir, yukarıdan hafif açıyla bakar (şirketin adı ve "Gün 1"). Balon kuzeydoğuya, Göreme'nin yanındaki kendi kasabamıza süzülür: oyunun 16×16 yerleşimi birebir 3B (karo 12 m; duvar ve kapılar, yollar, yeşil kalkış alanı, ilk günün binaları, boş arsalarda iskele, kenar peribacaları ve ağaçlar; hiç yazı yok). Balon hangarın önündeki alana, oyunda amiralin durduğu yere iner; kamera oyunun açısına (güneydoğudan 30°) dönüp uzun odakla yaklaşır. Köye gece çöker, pencereler yanar; karanlıkta film aynı yer ve ölçekteki 2B oyun kasabasına erir (balon 2B balona döner), kamera ilk günün açısına uzaklaşırken gece kalkar ve güneş doğar. Sonra HUD ve kartlar gelir, ardından Hezarfen. "Geç ›" eskisi gibi doğrudan oyuna geçer.
- **Renk seçimi (v121.3):** isim yazılırken olduğu gibi film sahnesinde kalınır: kamera tarladan gökyüzüne döner (güneşi arkasına alır), on renk seçeneği gerçek balonlar olarak süzülür; dokunulan balon öne gelir, brülörü yanar. "Geri" kamerayı tarlaya indirir. WebGL yoksa eski 2B seçim.
- **Uçuş (v121.1):** kamera yüksekliği tek tek tümseklere değil, yolun önündeki ve arkasındaki en yüksek zeminin yumuşatılmış haline göre ayarlanır: yere girmez, inip çıkıp titremez; sonda düz tarlaya iner.
- **Başlık ekranı:** "Brülöre basılı tut" beyaz bir konuşma balonunda, düğmeyi gösteren küçük bir çentikle.

## Hikâye (v121)
Film yalnızca tohumu atar; hikâye ilk günlerde oyunun içinde akar. Eski v112 hikâyesini oynayan kayıtlarda (`storyDone`) bu satırlar çıkmaz.
- **Film:** Hezarfen tarlada: "Bu sepet deden Hasan'ındı evlat. Kapadokya'nın ilk balonlarından biriydi. Kumaş hazır, sepet hazır. Bir tek adı eksik."
- **Gün 1 sabahı:** Kenan Arslan (Göreme Sky) küçümser: "Hasan'ın torunu ha? … Deden de böyle başlamıştı." (Kapadokya'da selam artık 1. gün; diğer bölgelerde 3. gün.)
- **İlk uçuştan sonra:** Hezarfen dedeyi anlatır: Hasan ilk balonculardandı, şirketi borca girince Kenan ucuza toplayıp aldı, Hasan bir daha uçmadı, sepeti Hezarfen sakladı.
- **Kenan'ı ilk geçtiğin gün:** gazete manşeti ("Yıllar önce Hasan Usta'nın şirketini Göreme Sky almıştı. Şimdi … torununun.") ve Kenan'ın tonu değişir: artık seni ciddiye alır.
- **Kapadokya Baronu töreni:** kartta camın ardında dedenin sepeti (HASAN plaketli vitrin) ve Kenan'dan kısa bir tebrik notu.

## İlk uçuşlar (v111.1)
TestFlight gözleminden: oyuncu hedefin iniş alanı olduğunu anlamadı, rüzgâr katmanlarının kesik çizgilerini görmedi, çizginin hemen üstünde rüzgârın değişmediğini fark etti ve yakıtı bitirip ilk uçuşta kaza yaptı. Bu yüzden:
- Rüzgâr artık katmanlar arasındaki kesik çizgide değişir (24 m'lik yumuşak geçiş), çizgiler daha belirgin ve yanlarında yüksekliği yazar.
- Sepetin altında anlık rüzgâr etiketi: hedefe taşıyorsa yeşil, uzaklaştırıyorsa kırmızı. Esintisiz katman rüzgârını gösterir, böylece soldaki katman etiketiyle aynı sayıdır.
- İniş alanı, termik gibi gökyüzüne uzanan yumuşak bir ışık sütunuyla işaretlidir.
- Katman sınırını geçerken balon, yeni rüzgârla kendi sürüklenmesi arasındaki farka doğru en fazla ~6° eğilir (zarf yeni havaya önce girer, sepet geride kalır), bir kez salınıp durulur. Yalnızca görüntü; uçuş fiziği değişmez.
- Uçuştaki ipuçları ve uyarılar sol üstte, uçuş panelinin yanında çıkar; balonu ve iniş alanını kapatmaz.
- İlk üç kendi uçuşunda (Hezarfen koçluğu): kalkışta hedef hatırlatması, hedeften uzaklaşırken, dururken ve iniş alanının üstündeyken kısa ipuçları; iniş alanı oku balonun hizasında ve sallanır. Yakıt %30'un altına inince her uçuşta uyarı.
- Acemi koruması: ilk üç kendi uçuşunda kaza ya da sert iniş tamirde 1 gün tutar.
- Fiyat dersi: 2.–12. günlerde dün koltuk boş kaldıysa Hezarfen fiyatı anlatır, "Fiyatı ayarla" düğmesi fiyat sayfasını açar.
- Filo dersinin metni artık "kasada para birikiyor" demiyor (tamirdeyken de açılabildiği için).

## Balon fabrikası (v114)
Balon atölyesi binası artık seviye seviye büyüyen bir fabrika. Binaya dokununca kendi ekranı açılır (Filo sayfasındaki tasarım bölümü buraya taşındı; Filo'da "Balon atölyesi" düğmesi var).
- **Seviyeler:** 1 Tasarım atölyesi (kuruluş €75.000, tasarım hemen açık), 2 Üretim hattı €30.000 (küçük sepet), 3 Orta balon hattı €60.000 (orta sepet), 4 Büyük balon hattı €120.000 (büyük sepet) (v118; 90k/180k idi). Dev balon fabrikada yapılmaz.
- **Üretim:** piyasa fiyatının %50 altına (küçük €7.500, orta €17.500, büyük €30.000), parası hemen ödenir, balon küçükte 3, ortada 4, büyükte 5 gün sonra filoya katılır (v118; 3/5/7 idi). Simülasyon (12 oyun, 400 gün, v118): fabrikayı büyüten bot 27 balonunu kendi üretir, €751k tasarruf + €78k sipariş kârı, €210k yatırım 181. günde geri döner (12 oyunun hepsinde); Kapadokya Baronu 158. gün (fabrikasız 160), 400. gün kasası €2,94M (fabrikasız €2,81M). Hat aynı anda tek balon üretir. Filo'nun "Yeni balon al" listesinde her boyun yanında "Atölyede" seçeneği de çıkar.
- **Siparişler:** hat boşken her gün %8 olasılıkla bir rakip senden balon ister (güvenli rakipler büyük, diğerleri orta; yapamıyorsan yapabildiğin en büyük boy). Fiyat liste fiyatının %80'i, teslimde ödenir (orta: €28.000, sana maliyeti €17.500, kâr €10.500). Kabul edersen hat o kadar gün meşgul olur ve rakibin bir balonla büyür; reddedersen hiçbir şey olmaz. Teklif sabah kart olarak gelir, o gün geçerlidir.
- **Bölüm 3 (Büyüme) hedefi:** "Balon atölyesi kur" yerine "Atölyende ilk balonunu üret" (seviye 2 gerekir).
- **Tasarım yokken:** "Yeni tasarım" düğmesinin hemen üstünde üç gri, kesik çerçeveli örnek kare (Yıldızlı, Zikzak, Güneş; şirket renklerinde ama soluk) durur, oyuncu basmadan ne yapacağını anlar. Örneklere dokunmak da "Yeni tasarım" gibi stüdyoyu açar. İlk tasarımdan sonra yerlerini kendi tasarımları alır (v114.1, prototip ve Swift).
- **Kasabada:** seviye 2'den itibaren tuğla baca; üretim varken tüter ve yanında yeni zarf rafta alttan yukarı dikilir (rakip siparişi gri).
- **Simülasyon (tools/sim-factory.js, 12 oyun × 400 gün):**
  - Fabrikasız oyuncu (yalnızca bölüm hedefi için seviye 2): 3. bölüm 134. gün, baron 160. gün, 400. günde kasa €2,81 milyon.
  - Fabrikayı 10 balonda kurup 4. seviyeye çıkaran, kendi balonlarını atölyede üretip siparişleri alan oyuncu: 3. bölüm 104, baron 155, kasa €3,34 milyon. Yatırım €300.000; tasarruf €231.000 + sipariş kârı €93.000 (oyun başına yaklaşık 10 sipariş).
  - Sadece sipariş alan: sipariş kârı €112.000, baron 163. Siparişleri reddeden: baron 159, kasa €2,99 milyon.
  - Siparişler rakipleri ölçülebilir biçimde büyütmüyor (rakip balon ortalaması 40 civarı, her durumda aynı); oyuncu pazar payı %90 civarı.
  - Denenen diğer seçenekler: %40 indirim ve €40.000/120.000/250.000 seviyeler daha yavaş geri dönüyor (400 günde çoğu kez dönmüyor); %50 indirim + ucuz seviyeler oyunu kolaylaştırmadan en iyi sonucu veriyor. Fabrikaya çok erken (4 balonda) para biriktirmek büyümeyi yavaşlatıyor (baron ~200. gün): fabrika orta oyunun yatırımı.

## Balon Şöleni (v111)
Pazar açıldıktan sonra, en az 5 uçabilen balonla, 15 günde bir düzenlenebilir. Uçabilen bütün balonlar katılır (seçim yok: hepsi ya da hiçbiri), balon başına €1.000 ödenir (50 balon = €50.000). Şölen o gece oynar: balonlar kalkış alanından dalga dalga yükselip kasabanın üstünde sıralanır, brülörler müziğe göre yanıp söner, ışık soldan sağa dalga gibi geçer, sonra balonlar bir figüre geçer (8 balondan azsa V, 16'dan azsa halka, daha çoksa kalp), havai fişek ve alkışla biter (27 sn; gece sahnesi ayarı kapalı olsa da oynar, düğmeyle geçilebilir). Gösteri yalnızca oyuncunun kendi balonlarından oluşur: sayıları, boyları, desenleri ve özel şekilleri. Etkisi: popülerlik hemen +0,05 (+0,2★) ve 10 gün boyunca popülerlik tavanını otel ya da rehber gibi açar; sonraki 3 gün her gün balon başına 4 turist (fiyat isteğiyle çarpılır) koltuklara önce yerleşir; ertesi sabah gazete manşeti. Hezarfen, sakin bir sabah, koltuklar dolmuyorken (dünkü doluluk %90 altı) ve kasada maliyetin üç katı varken bir kez önerir. Girişler ("Balon Şöleni Düzenle"): Filo sayfası, Pazar'daki tanıtım kartı, popülerlik sayfası, Hezarfen'in "Şöleni gör" düğmesi. Kart ne kazandırdığını ve hesabı (balon × €1.000 = toplam) gösterir, onaydan sonra "bugünü tamamladığında bu gece düzenlenecek" der. O gün kaza yapan (ya da satılan) balon şölene çıkamaz, ücreti geri döner; katılan 5'in altına düşerse şölen iptal olur, bütün ücretler döner ve bekleme sıfırlanır. 30'dan fazla balon varsa gösteride 30'u uçar (önce özel şekilliler, sonra desenliler, sonra amiral ve büyük balonlar, düz şirket balonları en son elenir); ücret ve etki bütün balonlar üzerinden.

Denge (tools/sim-show.js, 250 gün, 12 tohum): doğrudan getiri (şölen turistlerinin bileti / şölen maliyeti) €1.000 ve balon başı günde 1,5 / 2 / 2,5 / 3,5 / 4 turistte 0,5 / 0,65 / 0,85 / 1,1 / 1,4; €1.500'de zarar. 10/15/20 gün aralığı sonucu az değiştirdi. Koltukları zaten dolu olan şirkette şölen kazandırmaz (turistler sığmaz), boş koltuğu olan şirkette yaklaşık 1,4 kat geri döner; bu yüzden Hezarfen yalnızca koltuklar boş kalırken önerir.

**Şölenin en güzel anları (v116):** gösteri oynarken dört an saklanır: bütün brülörlerin aynı vuruşta yandığı an (8,5. sn), ışık dalgası (10,3), balonların figürü tuttuğu an (20,85; adı satın alınan figür ya da filoya göre Kaz sürüsü / Işık çemberi / Gökte bir kalp) ve final (22,9; "Final: N balon"). Ertesi sabah ilk kart olarak 2×2 baskı halinde gelir; her biri dokununca 1080×1350 paylaşım kartı olur (gece gökyüzü, eğik baskı, altında oyunun adı). Şölen bir an gelmeden geçilirse o an olmaz; ikiden az an varsa kart çıkmaz.

## Festivaller (Kapadokya)
24. günden başlayarak 35 günde bir, 4 gün (v121.11; Fiesta gibi): Bağ Bozumu, Bayram tatili, Işık Şenliği sırayla. Talep ×1,4, özel istek her gün çıkar, ödülleri ×1,5. Yollarda bayraklar asılır.

## İlk iki gün sabit senaryo (v122.4)
Öğretici sürerken Kapadokya'nın 1. ve 2. günü herkes için aynıdır, sürpriz yoktur (`tutScene`, `TUT_WX`, `TUT_DEMAND`):
- **1. gün:** yeşil bayrak, yer rüzgârı 5 km/sa, katmanlar (0–60 m'den yukarı) −1,3 / +4,6 / −2,2 / +6,2 m/s, iniş alanı 1.300'de (v124.6, önce 1.720), görev yok. Talep 110: 170 €'da 5/8 yolcu, 140 €'da 7/8, 110 €'da 8/8; fiyatı düşürme dersi her zaman işe yarar.
- **2. gün:** yeşil bayrak, yer rüzgârı 6 km/sa, katmanlar −1 / −2 / +5,2 / +3,4 m/s, iniş alanı 1.420'de (v124.6, önce 1.900), görev yok. Talep 320 (turist koltuktan çok). Gün 160 € fiyatla başlar (`TUT_P2`); fiyat 260 €'ya kadar çıksa da sepet dolu kalır.
- **2. gün dersi (`price2`):** sabah kartlarından sonra bilet kartı aydınlanır: "Dün düşürmek işe yaradı; bugün turist çok: fiyatı artır, müşterin azalmaz." + düğmesi gösterilir; fiyat artıp sepet dolu kalınca "Gördün mü? Yolcu aynı, kazanç arttı. Fiyatı her gün turiste göre ayarla." Tamam'la biter. Amaç: oyuncu 1. günden "fiyat hep düşürülür" diye öğrenmesin, fiyatın günün talebine göre ayarlandığını görsün. Ölçüm: `price2_up`, `price2`.
- **3. gün hatırlatması (v122.11, `price3`):** 3. gün sabahı (öğreticiyi oynamış oyuncuda) Hezarfen'in ilk kartı: "Dünkü kalabalık geçti evlat: fiyatı bugünün turistine göre yeniden ayarla." Düğmesi fiyat sayfasını açar; sabah sınırında hep önce gelir, aynı sabahki "koltuklar boş kaldı" dersinin yerini tutar. Neden: simülasyonda (20 tohum) 2. günün ~220 € fiyatını koruyan oyuncunun 3–7. gün doluluğu %90'dan %52'ye düşüyor, 10. günde kasası ~3.000 € eksik kalıyordu; fiyatı geri çeken oyuncu eski sürümle aynı tempoda (bölümler 11 / 56 / 98, baron 138. gün ortanca).

## Yeni oyuncu düzeltmeleri (v121.12)
- **Sabah kartları:** bir sabah en fazla 2 Hezarfen dersi ve 1 kartpostal gösterilir; kalanlar sırayla sonraki sabahlara kalır (`MORNING_TIPS`, `Rules.morningLessons`, `hezLater`, `postcardsLater`). Haberler, rakipler, müfettiş ve övgüler sınıra girmez (övgü zaten iki günde bir).
- **Tek balon onarımı:** tek balonun varsa onarım en fazla 2 gün sürer (`ONLY_REPAIR`, `Rules.onlyBalloonRepairDays`), raporda yazar.
- **Zorunlu pas geç:** bütün balonlar onarımda ya da uçuş yasağı varsa ana düğme "Günü pas geç" olur ve kart "Bugün günü pas geçmek zorundasın" der.
- **Yıldızlar:** popülerlik her yerde ekrandaki gibi tek ondalığa yuvarlanır; 2,96★ "3,0★" görünür ve 3,0★ isteyen oteli açar.
- **Kartpostallar:** "İlk uçuş" kazasız ilk uçuştan sonra, "Festival havası" bir festival gününde uçunca gelir.
- **Boş sepet:** hiç yolcu binmediyse kalkıştan önce sorar: Fiyatı değiştir / Boş kalk.
- **Uçuş koçu:** yakıt uyarısı %30'da (v124.6, önce %25; yakıt çubuğu da %30'un altında kırmızı); "Bu rüzgâr seni uzaklaştırıyor" ipucu doğru katmana geçince kalkar. Bekleyen bir övgü artık doğru değilse (pilot çıkarıldıysa) gösterilmez.
- **Başka bölgedeki mevsimler (v121.13):** bir bölgenin Fiesta'sı, festivali ve kışı yalnızca orada oynanan günün sonunda biter; bölgeye dönünce süresi geçmiş olanlar sabah sessizce kapanır (`expireSeasons`).
- **Bina ipuçları:** rehber, ajans, atölye ve okul açılınca Hezarfen "kasabada binayı bul ve dokun" derdi; v122'de yerini rehberli eylemler aldı ("Gösteren öğretici").

## TestFlight düzeltmeleri (v121.2, v121.6)
- **Uçuşta duraklatma:** uçuş sırasında sağ üstteki menü düğmesi ⏸ olur; "Duraklatıldı" kartı (irtifa, yakıt, Devam et, Ayarlar) açılır, uçuş donar, brülör ve valf bırakılır. Ayarlar kapanınca kart geri gelir. Uygulama arka plana giderse uçuş kendiliğinden duraklar.
- **Rüzgâr etiketi:** sepetin altındaki yeşil/kırmızı hap yerine balonun üstünde küçük koyu cam bir etiket: renkli dairede ok (yeşil: tarlaya taşıyor, turuncu: taşımıyor) ve hız. Alçalırken iniş alanı, peri bacaları ve engeller görünür kalır.
- **Binişin sonu (v121.6):** "Sen ve pilotlar uçsun" / "Sadece pilotlar uçsun" her zaman sorulur; boşta pilot yoksa ikincisi kaç balonun yerde kalacağını yazar.
- **Ana ekran (v121.6):** kasabanın ortası ekranın ortasında.
- **Bugünün uçuş planı:** SEN/PİLOT sorusu kalktı. Kendin uçurduğun balon kendi grubunda, yerinde "Sen uçuruyorsun" etiketiyle durur (altında "Pilota ver"; v121.7); diğer balonlarda "Ben uçurayım" düğmesi var (o balon amiral olur, filodaki gibi). Üstteki kart yalnızca durumu ve günün görevini söyler; kendin uçmuyorsan görev uyarısı kırmızı.

## Uçuş anları
Uçuşların %70'inde bir an çıkar: **termik** (65 m genişliğinde yükselen hava kolonu; içindeyken dikey hıza sim saniyesi başına +1,0 eklenir, v122'den önce +0,5; 2 sn içinde kal: +15 yakıt), **selam** (başka bir balonun 95 m / 50 m yakınında 2 sn), **fotoğraf** (150–280 m arasında 1,5 sn, flaş). Başarılırsa yolcu başı bahşiş +€5 ve popülerlik +0,008.

## Gazete, rakip patronlar, kurtarma planı
- **Sabah gazetesi** (Kapadokya Postası / Albuquerque Herald) yalnızca bir şey olduysa gelir: kazalar, cezalar, rakip olayları, iflas, yeni rakip, rekor yolcu günü, festival, yükseltmeler.
- **Rakip patronlar:** Kenan Arslan (Göreme Sky) ve Dale Whitaker (Sandia Sky Rides). Selam (3. gün), bölüm başları, geçilince, otel kapışması, pilot ayartma, kazan, anlaşma, batış ve Baron töreninde konuşurlar; her söz bölge başına bir kez.
- **Gün kutlamaları (v109):** 100, 200, 300, 365 (şirketin bir yaşı), 400, 500. günler ve sonra her 100 günde bir, bölgenin rehberi kutlar ve ertesi sabah gazeteye çıkar.
- **Holding yatırımları (v109):** TV kampanyası, ilan panoları, Ar-Ge, rekor denemesi ve sponsorlu şekil sözleşmesini bulunduğun bölgenin rehberi över; ünlü yüz ve ofisler kendi mesajlarıyla gelir. Hepsi ertesi sabah gazetede.
- **Kurtarma planı:** kasa eksiye düşünce adım adım seçenekler: rehberlere tanıtım uçuşu (€1.500, bekleme süresi bittiyse), otel anlaşması (hiç anlaşma yoksa, yıldızın yettiği en iyi otel, 3 günlük peşin), boştaki pilotları çıkar, en küçük balonu sat (%60, ikinci else %40), fiyatı koltukları dolduran en yüksek fiyata getir (aşağı ya da yukarı; sadece bugünkü tahmini geliri artırıyorsa görünür, seçilince kaybolur, v110), kredi al (sadece kazanç şartı olmayanlar). Rehber ve otel bu kartta kasayı eksiye indirebilir ama €-5.000 el koyma sınırının altına asla (v109.4).

## Başarımlar ve holding hedefleri
- ☰ menüsünde "Başarımlar": 22 başarım, her biri bir kartpostal.
- Holding hedefleri (ofisteki beyaz tahtada yazılı): holding kasası €1 milyon, Luksor Baronu (v109, önceden Albuquerque), bir TV kampanyası, ünlü reklam yüzü, Ar-Ge tamam, dört ofis. Hepsi bitince Dünya Baronu; ondan sonra hedefler işaretli kalır (kasa 1 milyonun altına düşse de).

## Mağaza (uygulama içi satın alma)
Fiyatlar App Store'un yerel fiyat basamaklarıyla gösterilir (Avrupa'da):
- **Özel desenler** 0,99 €: Varak altın 92, İznik çinisi 90, Takımyıldız 92, Kapadokya kilimi 90 (desen tabanı).
- **Balon şekilleri** 1,99 €: Kalp, Yıldız, Kurukafa (oyuk gözler, kalp burun, sırıtan dişler; v99'da Hezarfen balonunun yerine geldi, onu alanlara kurukafa verilir). Tasarıma eklenir: yaratıcılık +8 ve her uçuşta ek popülerlik +0,0015.
- **Kasaba süsleri** 0,99 €: meydan çeşmesi, Hezarfen heykeli, şirket bayrakları. Fener dizileri bedava: 11. günde Hezarfen çarşıyı tanıtırken hediye eder. Her biri kasabada görünür (v115'ten beri yalnızca görsel). Gece her birinin kendi aydınlatması var (çeşmede su altı ışığı, heykelde spotlar, bayraklarda yukarı ışık, fener dizilerinde yollar boyunca ampul dizileri ve 8 lamba).
- **Meydan Süsleri paketi (v115)** 0,99 €: güvercin sürüsü, karşılama kemeri, bahçe kafe, kilim sergisi (tek tek satılmaz). Güvercinler gündüz kasabanın üstünde döner, gece yoktur; kemer kasabaya giren iki yolun üstünde şirket renklerinde ve adıyla; kafe bankanın arkasındaki köşede; kilimler atölyenin yanında; hepsinin gece ışığı var.
- **Şölen Figürleri paketi (v115)** 0,99 €: Yıldız, Lale, Kelebek, Girdap, Baş harfin. Şölen finalinde (13.–23. sn) balonlar ücretsiz figür (filoya göre V, halka, kalp) yerine seçilen figürü çizer, arkada noktalı bir ışık çizgisi figürü okunur kılar. Şölen kartındaki "Final figürü" satırında kilitliler "🔒 Pakette" yazar, dokununca paket açılır.
- **Süsler artık yalnızca görsel (v115):** eski kuraldaki "her süs talebi %1 artırır" kaldırıldı.
- **Süsleri depoya kaldırma (v125.7):** Çarşı'nın "Süslerin" rafında sahip olunan her süs "Kasabada" ya da "Depoda" yazar; "Kaldır" süsü depoya alır (hiçbir kasabada, gündüz de gece de çizilmez), "Yerleştir" geri koyar. Süs satın alınmış olarak kalır; çarşının "Süs: N/8" sayısı ve Kurucu Paketi hesabı sahip olunanları sayar. Süslerin oyun etkisi olmadığı için kaldırmak yalnızca görünüşü değiştirir.
- **Dünya Turu (v115)** 4,99 € (v121: 5,99 €'dan indi): Kapadokya ücretsiz oyundur; Amerika (Albuquerque), Mısır (Luksor) ve gelecek bölgeler Dünya Turu ister (oyun içi giriş bedeli yine holdingden). Kapadokya Baronu töreninde "Devam" ile teklif kartı açılır: Dünya Turu, ve Kurucu Paketi alınmamışsa ikinci seçenek **Destekçi Sürümü 9,99 €** (v121: 11,99 €'dan indi; Dünya Turu + Kurucu Paketi + kasabada destekçi plaketi; üstü çizili 11,98 €). Kurucu Paketi alınmışsa yalnızca Dünya Turu sunulur. Dünya haritasında ve holdingin bölgeler listesinde de "Dünya Turu 5,99 €" düğmesi aynı kartı açar. Çarşıda bölge satılmaz. v113'ün Mısır (2,99 €) ürünü kaldırıldı; onu alanlarda Dünya Turu açık sayılır.
- **Kurucu Paketi** 6,99 €: desenler, şekiller, büyük süsler ve iki paket (bölge değil). Tek tek toplamı 14,88 €, yani %53 indirim; üstü çizili fiyat henüz sahip olunmayanların toplamıdır, %20'nin altına düşerse gösterilmez.
- Hepsi kasabadaki **Çarşı** binasından alınır (9. günde açılır). Desen ya da şekil şirket renklerinde hazır bir tasarımla gelir ve amiral balonuna hemen giydirilir; atölye gerekmez; bu tasarımlar her balona bedava giydirilir (normal tasarımda boya €1.000) (atölye yalnızca kendi tasarımını yapmak için). Atölyede bu desen ve şekiller kilitli görünür, oradan da alınabilir.


## Otomatik ilerletme (v117)
- **Ne zaman:** bulunulan bölgede en az 35 balon ve Kapadokya Baronu olunca, alttaki düğmelerde "İlerlet" (çizilmiş ileri sar simgesi) çıkar. Hezarfen ilk açıldığında bir kez anlatır.
- **Ne yapar:** günleri kendi kendine oynatır. Amirali de ekip uçurur (kurucu primi ve görev yok). Kırmızı bayrakta pas geçer. Gecelerin sahnesi atlanır, ama **Balon Şöleni gecesi atlanmaz**: gösteri baştan sona oynar, sonra durur ("Şölen bitti") ve en güzel anlar kartı gelir. Her gün düğmelerin üstünde kısa bir şerit: "Gün N +€X".
- **Ne zaman durur:** karar ya da kart isteyen her şey (sabah olayı, hedef/bölüm, birleşme, satılık rakip, transfer teklifi, sipariş, sorun, kartpostal, Hezarfen dersi, şölen anları), kasa 3 günlük giderin altına inince, lisans yenileme uçuşu gerekince, 7 gün dolunca ya da ekrana dokununca.
- **Durmayanlar:** gazete ve Hezarfen'in haberleri biriktirilir, durunca gösterilir (haberlerin son üçü). 35 balonla neredeyse her sabah bir manşet, çoğu gün bir sert iniş olur; kazalar sadece sayılır ("kaza: N"). Durunca şerit: sebep, gün sayısı, toplam net, kaza sayısı.

## Bölgeler ve otomatik mod
- **Bölge düğmesi (v113):** üst çubukta ilk günden itibaren bulunulan bölgenin adı ("Kapadokya ▾") durur. Dokununca "Bölgeler" kartı açılır: sahip olunan bölgeler (geçiş), ardından kilitli ve açılmış bölgeler ("Kapadokya baronu olunca açılır", "Yakında" vb., kilitliler soluk ve 🔒) ve Dünya haritası. Böylece oyuncu oyunun Kapadokya'dan öteye ilerlediğini baştan görür.
- Kapadokya baronu olunca holding açılır. Albuquerque'ye giriş €100.000 (holdingden). Orada sıfırdan başlanır: $3.000 ve bir S balon.
- Her bölgenin kendi kasası, bankası, filosu, pilotları, rakipleri, otelleri, popülerliği, bölümü vardır. Kurucu lisansı, atölye, tasarımlar ve gün sayacı ortaktır.
- **Luksor** Albuquerque baronu olunca açılır. Giriş €150.000 (holdingden), başlangıç €5.000 ve bir S balon. Girerken Hezarfen burasının en çetin pazar olduğunu söyler.
- **Nil rüzgârı (Luksor):** katmanlar +, −, +, − yönünde, Albuquerque'den biraz daha sert.
- **Nil gemisi sezonu (Luksor):** her 21 günde bir, 3 gün, talep ×1,6. Gece olayı "Nil gecesi". Gazete: Nil Postası.
- **Kasabalar bölgeye göre:** Kapadokya peri bacaları ve tüf evler; Albuquerque kızıl mesalar, kerpiç (adobe) evler, düz çatılar ve vigalar, kaktüs, yucca ve kavak; Luksor kireç badanalı kerpiç evler ve kubbeler, hurma bahçeleri, şeker kamışı tarlaları, Nil, dikilitaş, tapınak kalıntıları ve Teb tepeleri. Satın alınan süsler her bölgede görünür.
- **Bristol (v124)** Luksor baronu olunca açılır; ayrıntılar aşağıda "Bristol (v124)" bölümünde.
- **Kutu rüzgârı (Albuquerque):** katmanlar −, +, −, + yönünde. Hedef 1.000–1.700 m.
- **Balloon Fiesta:** her 30 günde bir, 4 gün, talep ×1,9 (ilki girişten 12 gün sonra).
- **Otomatik mod:** Ayrılınan bölge son 14 günün ortanca net kârının %85'ini (euroya çevrilmiş) her gün ±%15 oynayarak holdinge getirir.
- **Sorunlar:** son sorundan 6 gün sonra her gün %7. Karar verilene kadar kazanç yarıda.
- **Sorunlu bölgeye gitmek (v108):** karar bekleyen sorun bölgeyle birlikte durur; oraya geçince kaybolmaz. Varınca kamera önce ofisin önüne gider (zam isteyen pilotlar orada pankartla bekler), 3,5 saniye sonra karar kartı alttan açılır (ofisin önü üstte görünmeye devam eder); ana ekranda kırmızı uyarı da olur. Kartta "Sonra" yok: bölgedeyken karar verilir; başka bölgedeyken kartta iki seçeneğin yanında "<bölge> bölgesine git" düğmesi var. Geri dönersen sorun otomatik modda beklemeye devam eder. Bölgedeyken seçimlerin sonucu yerinde olur: zam ver = pilot maaşları %15 artar; reddet = pilotlar 3 gün uçmaz (sadece amiral, sen); fiyatı eşitle = bilet fiyatın en ucuz rakibe iner; popülerliğine güven = %50 popülerlik −0,08; sert iniş: kendin ilgilen −0,05, müdür halletsin −0,1 popülerlik; otel (yalnızca anlaşmalı oteli olan bölgede çıkar; sahip olunan oteller kapışmaya girmez): o otelin 60 günlük ücretini (holding kasasından; rakibe kaptırmamanın bedeli) ödersen kalır, bırakırsan bir otel anlaşman en popüler rakibe geçer ve 30 gün seninle çalışmaz (aynı gün 3 günlük ücretle geri alınamaz); zarflar: bütçeyi onaylarsan %30 altındaki zarflar yenilenir.
  - Zam: kalıcı −%6 ya da 3 gün sıfır.
  - Fiyat savaşı: kalıcı −%10 ya da %50 şansla 10 gün −%25.
  - Sert iniş: bölgeye git (popülerlik −0,05) ya da 7 gün −%15.
  - Otel kapışması: 5 günlük kazanç öde ya da kalıcı −%5.
  - Yıpranan zarflar: 8 günlük kazanç öde ya da 10 gün −%12.

## Kurumsal kontratlar (v125–v125.3: Albuquerque, Luksor, Bristol; v126: Kapadokya)
Arada bir sabah yerel bir şirketin sahibi teklif getirir. Bölge ayarı `CTR[bölge]` (prototip), ortak kod; her bölgenin kendi türü, kadrosu, kontrat yeri, aracı ve sesi var.

| | Albuquerque | Luksor | Bristol | Kapadokya (v126) |
|---|---|---|---|---|
| Kim | Tur otobüsü şirketleri (Route 66) | Nil gemisi şirketleri | Londra hafta sonu tren paketleri | Seul, Şanghay, İstanbul tur acentaları (charter uçağı) |
| Tür | tek gün, tek grup | **blok:** 4–6 ardışık sabah, her sabah N kişi | **hafta sonu:** Cumartesi + Pazar, **sis garantisi** | **iki ardışık sabah**, her sabah N kişi, **uçak rötarı** |
| Grup | filonun koltuklarının %40–70'i | %18–30'u (her sabah) | %25–40'ı (her sabah) | %25–40'ı (her sabah) |
| Kişi başı fiyat | referansın ×0,80–0,90'ı | ×0,80–0,90 | ×0,90–1,00 | ×0,80–0,90 |
| Sıklık (tercihte) | 10–14 gün (6–9) | 13–18 gün (9–12) | 7–10 gün (5–7; v125.4) | 11–15 gün (7–10) |
| Kırmızı bayrak | grup bir gün kayar, ilk kaymada %20 iner | o sabah sayılmaz (ödeme yok, ceza yok) | o sabah sayılmaz | o sabah sayılmaz |
| Kontrat yeri | otoyolun sonunda otobüs terminali | Nil kıyısında iskele | batı yolunun sonunda Avonside istasyonu | doğu yolunun sonunda NAV · Nevşehir Airport |
| Araç ve ses | 1–3 otobüs, motor rölantisi, korna | üç katlı gemi sallanır, nehir sesi, gemi düdüğü | kırmızı buharlı tren, duman, yavaş puf-puf, düdük | çift pervaneli charter uçağı: yaklaşma, teker cıyaklaması, ters itki, taksi; kalkışta motor açılır, tırmanır |

- **Fiyat (v125.3):** tur şirketi toptan alır: kişi başı fiyat, senin fiyatınla yaşayan rakiplerin ortalamasının ortası (referans) çarpı yukarıdaki oran, 5'e yuvarlı, ve **asla senin biletinden ve referanstan yüksek değil**. Tercih edilen operatöre ×1,06 (Bristol ×1,04), yine aynı tavanla. Pazarlık %10 fazla ister ama en fazla referansa (ve biletine) kadar; fiyat zaten tavandaysa pazarlık düğmesi çıkmaz. %35 ihtimalle (tercihte %15) şirket grubu rakibe götürür. Bristol'ün paketleri pazara daha yakın (×0,90–1,00): Londra'dan gelen hafta sonu kaçamağı premium bir üründür, ama sis garantisinin bedeli (iade ve kupon) operatöre de sana da riskli olduğu için yine biletin üstüne çıkmaz.
- **Neden alınır:** kontratın değeri prim değil, garanti dolu koltuk ve rakibe gitmemesi. Kişi başı biraz ucuzdur; ama grup, pazarın dolduramayacağı koltukları doldurur. Simde kontrat gelirinin normal bir günde aynı koltukların getireceği bilet gelirine oranı Albuquerque 0,91, Luksor 0,97, Bristol 1,12; kontratın yerinden ettiği pazar yolcuları düşülünce kalan **net kazanç** kontrat gelirinin Albuquerque'de %14'ü, Luksor'da %52'si (küçük gruplar, çok sabah: hep boş koltuk doldurur), Bristol'de %49'u.
- **Ne zaman:** 2. bölüm başlayınca, ertesi sabah ilk teklif (filo en az 40 / 48 / 48 koltuk). Kapadokya'da 2. bölümde, **40. günden önce değil** ve filo en az 40 koltuksa (aşağıda). Bekleyen kendi işin varken yeni teklif gelmez. Cevaplanmayan teklif ertesi sabah reddedilmiş sayılır. Bristol'de iş hep bir Cumartesi başlar (1. gün Pazartesi; teklif en az 3 gün sonrası için).
- **O sabah:** grup koltuklara önce oturur, kalanı normal pazara satılır (`market(fiyat, koltuk − grup)`). Raporda "Tur grubu (N kişi)" ayrı satır, fiyat sayfasında "Tur grubu: şirket +N yolcu · fiyat", bilet kartında "Tur grubu bugün: x/N kişi".
- **Sis garantisi (Bristol):** teklifte her günün sis tahmini yazar (Cmt %x · Paz %y; %5–45). O günün sisi bu tahmine göre gelir (kontratlı sabahta hava sisini tahmin belirler). Sisli sabah o günün grubu uçmaz: bilet parası iade, üstüne kişi başı fiyatın %15'i kupon (raporda "Sis garantisi: kuponlar"); başarısızlık sayılmaz. Bot ortalama tahmin %45'ten yüksekse reddeder.
- **Teslim edemezsen:** her sabah eksik koltuk başına kişi başı fiyatın %50'si ceza, popülerlik −0,02, eksik yolcular o gün rakibe gider. İş son gününde bütün olarak değerlendirilir: hiç eksik yoksa başarılı iş; eksik varsa güven düşer; hava yüzünden hiç uçulamadıysa kimsenin suçu değil.
- **Gözde ortak ilerlemesi sahip başına (v126.1):** kartlardaki noktalar ve "n/3" satırları yalnızca o sahiple teslim ettiğin işleri sayar (`okBy`); yeni sahip 0/3 başlar ve kendini tanıtır; veda eden sahibin sayacı sıfırlanır. Bölüm hedefi bölge toplamıdır ve "Toplam … (bütün şirketler)" diye yazar.
- **Güven ve karakterler:** başarılı iş +1 (en çok 5), eksik teslim −1 (≥%75 uçtuysa) ya da −2, ret ve pazarlıkta kaçma −1. Aynı kişiyle 3 başarılı iş ve puan ≥2: tercih edilen operatör ("Artık sana daha sık geleceğim"); puan 1'in altında unvan gider; −3'te sahibi veda eder, 14 gün sonra kadrodaki sıradaki sahip kendini tanıtarak gelir. Kadrolar (her birinin SVG portresi, rengi, kendi sesiyle replikleri):
  - Albuquerque: Rosa Delgado (Mother Road Coaches), Hank Begay (Turquoise Mesa Tours), Linda Park (High Desert Coachlines).
  - Luksor: Kaptan Farouk Mansour (Sobek Nile Cruises; "kaptan" der), Dalia Rizk (Golden Lotus Line; lüks, resmî), Hamza El-Sayed (Dahabiya Pearl; neşeli, yelkenli dahabiyeler).
  - Bristol: Nigel Pemberton (West Country Weekenders; "splendid"), Priya Shah (Capital Rail Breaks; hızlı, uygulamalı), Fiona MacLeod (Steam & Sky Excursions; buharlı tren, "canım").
  - Kapadokya (v126): Han Ji-woo (Haneul Wings, Seul; neşeli, "annyeong", fotoğraf meraklısı), Chen Hao (Pearl Bund Travel, Şanghay; kısa, rakamcı, takvimci), Murat Bey (Haliç Gündoğumu Turları, İstanbul; "gün doğumu paketi", "kardeşim").
- **Rakip güçlenir:** reddedilen, kaçan ya da teslim edilemeyen grup o gün(ler) popülerliği en yüksek rakibin yolcusu olur (pazar payına sayılır); ilk gününde rakibin popülerliği +0,05, kişi başı farkı kasasına girer ve grubun toplam yolcusuna göre hemen balon alır (Abq ve Bristol 24, Luksor 20 kişiden bir balon, her iki katı için bir tane daha). Gazete ve rapor satırı.
- **Bölüm hedefleri:** 2. bölümde rüzgâr direği Sv. 3 yerine "2 tur / gemi / hafta sonu grubunu eksiksiz uçur", 3. bölümde yeni beşinci hedef "3 kontratı eksiksiz uçur (herhangi bir şirket)" (bölgedeki toplam başarılı iş).
- **Kapadokya'da hedef yok (v126):** charter anlaşmaları Kapadokya'da yalnızca bir fırsat; bölüm hedefleri değişmedi.
- **Kaydırma (v125.5):** `townClamp`, kontrat yerini her yakınlaştırmada ekranın ortasına ve ±%25 yatay / ±%20 dikey çevresine getirmeye izin verir (telefonda Luksor ve Bristol'de takılma düzeltildi).
- **Bristol saçağı (v125.5):** peron saçağı trenden sonra çizilir; tren saçağın altından/arkasından geçer, saçak kaybolmaz.
- **Görünmezlik kuralı (bütün şehirler):** kontrat yeri, ona giden asfalt ve cipler ana ekranın varsayılan görünümünde hiç görünmez; kasabaya yakın yol kasabanın kendi toprak yoludur. Kontrol: kontrat yeri ve cip animasyonu (11 sn'lik döngünün her yarım saniyesi) tek başına boş bir tuvale ana ekran kamerasıyla çizilir; 390×844, 400×860, 430×932, 834×1194 ve 1024×1366'da (dikey) ekrana düşen piksel 0. Kasaba görünümünde sürükleyerek gidilir (`townClamp` kontrat yerini her yönde ekranın ortasına getirmeye izin verir).
  - Albuquerque: güneybatı yolunda, yerleşim 12 kare dışarıda. Otoyol terminalde biter: asfalt terminalden dışarıya doğru, kasabaya doğru değil; terminalin kasaba tarafında toprak "BALLOON SHUTTLE" cip durağı.
  - Luksor: Nil kıyısında doğuda (gx ≈ 30): taş rıhtım, ahşap iskele, bilet kulübesi, "LUXOR CRUISE PIER" tabelası, hurmalar, fenerler, feluka; iskeleden doğu yoluna toprak patika.
  - Bristol: batı yolunun ucunda (gx ≈ −11): raylar ufka uzanır, tampon, peron ve yeşil saçak, saatli tuğla istasyon, "AVONSIDE" levhası, cip durağı yolun öbür yanında.
  - Kapadokya (v126): doğu yolunun ucunda (gx 20–46, gy 0–8; her yerinde gx − gy ≥ 18): gx boyunca pist (gy ≈ 1, 27/09 yazılı, eşik çizgileri), iki taksi yolu (gx 31 iniş çıkışı, gx 24,6 kalkış girişi), beton apron ve sarı park çizgisi (uçak burnu batıya, gx 27,4 / gy 3,8), tüf taşı terminal (cam cephe, çatıda "NAV · Nevşehir Airport" panosu), ince kontrol kulesi (yanıp sönen ikaz lambası), rüzgâr tulumu, apronla cip durağı arasında tel çit, toprak cip durağı ve "BALON SERVİSİ" tabelası (oyuncunun dilinde, `sign.shuttle`), yolda "NAV" levhası (yanında kodla çizilmiş uçak ve ok; emoji yok), peri bacaları ve kavaklar. Kasabaya giden yol kasabanın kendi toprak yolu.
- **Araç ne zaman orada:** yalnızca senin bir işin sürerken (ilk günden son güne). **Bir kez gelir, kalır, bir kez gider (v126.1):** işin günlerinden birinde ilk baktığında gelir, iş bitene kadar (kırmızı bayrak ya da rötar işi kaydırsa da) park halinde durur, yeniden açılan oyunda varış tekrar oynamaz. İlk gün araç, kontrat yerine ilk baktığında gelir (otobüsler otoyoldan perona girer ve korna; gemi akıntıdan yanaşır ve düdük; tren raylardan girer, düdük ve puf-puf) ve iş bitene kadar kalır. **Ayrılış (v125.4):** işin son gününden sonra araç, kontrat yerine ilk baktığında gider: otobüsler perondan çıkıp otoyoldan uzaklaşır (motor ve kısa korna; giderken önleri görünür), gemi iskeleden ayrılıp Nil'de akıntı yönüne açılır (gemi düdüğü), tren geldiği yöne çekilir (düdük, hızlanan puf-puf); 4–6 saniyede kaybolur, yer boş kalır. Yeni bir iş gelirse bekleyen ayrılış atlanır. Ayrılış da varsayılan görünümün dışında kalır. Araç dururken ekrana yakınsa ortam sesi (`ctrHum`, türe göre).
- **Otobüsler gerçek otobüs gibi (v126.1):** gelirken otoyoldan yavaşlayarak gelir, sağa park alanının arka koridoruna, sonra sola cebine kıvrılarak girer ve durur (gövde dönüşle birlikte döner); giderken cebinden ileri çıkar, öbür otobüslerin burnunun önünden sola, otoyola sola dönüp hızlanarak uzaklaşır; otobüsler sırayla (gelişte 0,9, gidişte 2,4 sn arayla).
- **Cipler:** işin bir sabahı (araç oradaysa ve kırmızı bayrak / sis yoksa) yolcular araçtan inip oyunun safari ciplerine yürür, cipler toprak yoldan kasabaya doğru gider ve varsayılan görünüme girmeden kaybolur; 11 saniyelik döngü.
- **Yolcu toplama (v125.3):** kontrat sabahı "Yolcu topla"ya basınca önce 1–3 cip dükkânın önünden kontrat yerinin yoluna çıkar ("Jeepler tur grubunu almaya gidiyor"), grubu alıp geri gelir ("Tur grubu geliyor: N kişi"), koltuk göstergesinde grup ilk dolar (kendi rengiyle), sonra normal kuyruk oluşur; kalkışta kuyruk aynı ciplere biner ve hepsi birlikte çıkar. 2,6 sn ekler; yolcu toplama animasyonu ayarı kapalıysa hiç oynamaz.
- **İlk teklif sahnesi (bölge başına bir kez):** kamera kasabadan kontrat yerine kayar (3,6 sn), araç gelir (sesiyle), rehber (Ben Franklin / İmhotep / Maggie / Hezarfen) dört kısa cümle söyler, "Geç" atlar; teklif kartı yerin altında açılır, karar sonrası kamera kasabaya döner. Kapadokya'da kamera havalimanına daha uzaktan bakar (yakınlık 0,6), uçak sahne başlayınca piste iner. **Albuquerque kısa sürümü (v126):** oyuncu Kapadokya'da daha önce anlaşma yaptıysa (`taken`, `ok` ya da `fail` > 0) Ben Franklin yalnızca iki cümle söyler: "burada işler otobüsle" ve "gerisini Kapadokya'dan biliyorsun; bir farkı var: grup tek sabah uçar". Hiç anlaşma yapmamışsa tam sürüm.

### Kapadokya charter anlaşmaları (v126)
- **İlk teklif:** 2. bölümde (Yükseliş), **40. günden önce gelmez** (`firstDay` 40) ve filo en az **40 koltuk** olmalı (oyuncu iki sabah 10–16 kişiyi kaldırabilmeli). **Kalabalık sabaha konmaz** (`quiet`): o sabah bir sabah olayı, bölüm kartı, birleşme, filo getirme kartı varsa ya da kuyrukta ikiden fazla kart bekliyorsa teklif bir sonraki sakin sabaha kalır. Botta filo 40. günde çoğunlukla 24 koltuk, ilk iş ortalama 59–60. günde uçar.
- **Tür:** iki ardışık sabah, her sabah N kişi (filonun %25–40'ı, en az 12); kişi başı referansın ×0,80–0,90'ı (tavan senin biletin), gözde ortağa ×1,06; teklif 3–5 gün sonrası için; ceza eksik koltuk başına fiyatın %50'si, her sabah ayrı; kırmızı bayraklı sabah sayılmaz. Güven, gözde ortak (3 iş), veda (−3) ve sıradaki sahip, rakibin kaçan grubu alması, gazete ve rapor satırları öbür bölgelerle aynı.
- **Uçak rötarı:** oyuncunun Kapadokya'daki **ilk iki işinde hiç olmaz** (`delay.after` 2; iş sırası `nth`). Üçüncü işten itibaren işin ilk sabahından önceki akşam %35 ihtimalle raporda "Rötar haberi, <sahip>: 'Uçağım yarın sabah gecikebilir.' Sabah netleşir." yazar. Ertesi sabah (kırmızı bayrak yoksa) %60 ihtimalle uçak rötarlıdır (yani işlerin ≈%21'i); değilse sahip "zamanında indi" der. Rötar ilk kez olduğunda önce Hezarfen kısaca anlatır ("Uçaklar bazen rötar yapar evlat. Sabah karar senin…"). Sonra sahibin kartı: **"Sabaha yetişme ihtimali: %30–70"** (10'un katı) ve iki seçenek:
  - **Koltukları beklet:** uçak yetişirse grup bugün uçar, iş planlandığı gibi. Yetişmezse grubun koltukları bugün **boş kalkar** (pazara satılmaz), grup **bir gün kayar** (iki sabahı ertesi gün başlar) ve acenta **koltuk başı fiyatın %40'ı rötar tazminatı** öder (raporda "Rötar tazminatı (boş koltuklar)").
  - **Pazara aç:** koltuklar bugün normal satılır, grup bir gün kayar. Uçak yine de yetişmişse grup boşuna bekler: **güven −1** (sahip kırgın konuşur; güven −3'e düşerse veda). Yetişmemişse kimse bir şey kaybetmez.
  - Karar hemen sonuçlanır (sonuç kartı: "Uçak indi!" / "Uçak yetişmedi" / "Uçak indi, koltuk yok"). Para açısından pazara açmak hep biraz daha kârlıdır; beklemek güveni korur ve iş zamanında biter. Cevapsız kalırsa (otomatik mod) koltuklar bekler. Bot ihtimal ≥%50 ise bekletir.
  - Fiyat sayfası ve tahmin: bekletilen boş koltuklar pazardan düşülür, tazminat tahmini gelire eklenir ("Rötar: N koltuk charter grubu için boş bekliyor…").
- **Uçak:** yalnızca işin ilk gününden son gününe kadar havalimanında. İlk sabah havalimanına ilk baktığında iner (13,5 sn: doğudan 300 px yükseklikten pist üstüne süzülme 4,5 sn, gx 40'ta teker koyma, gx 31'e kadar yavaşlama, taksi yolundan apronda park yerine; pervaneler yavaşlar, arka kapıya merdiven gelir). İş bitince ertesi bakışta kalkar (14 sn: batıya taksi, gx 24,6 taksi yolundan piste, doğuya kalkış koşusu, gx 38'de havalanır, tırmanıp kaybolur). Rötar yüzünden grup kayarsa uçak ertesi sabah iner. Uçak sahibinin renginde (gövde şeridi, kuyruk, kanat uçları, pervane göbeği).
- **Sesler (kodla):** iniş: türbin ıslığı (sinüs 1.500→1.150 Hz), pervane vuruşu (22 Hz kare dalga ile genlik), gürültü ve testere dişi motor (118→92 Hz), 4,5 ve 4,72 sn'de iki kısa teker cıyaklaması (2.600 Hz bant gürültü + 1.900→1.500 Hz), ardından ters itki kabarması ve taksi rölantisi. Kalkış: rölanti, 4,5 sn'den sonra ıslık 900→2.100 Hz, motor 80→140 Hz, gürültü kabarır, tırmanışta söner. Park halindeyken uzaktan hafif APU uğultusu (`ctrHum`: 1.500 Hz bant gürültü).
- **Yolcular:** iş sabahı uçağın merdiveninden terminale yürüyen yolcular, terminalin ön kapısından toprak cip durağına yürüyüş, üç cip doğu yolundan kasabaya (gx 23'te kaybolur). Yolcu toplamada cipler önce havalimanına gidip grubu getirir.
- **Test:** Ayarlar › Test › "Kapadokya anlaşma testi (charter uçağı)" (`testCapContract`: 40. gün, 2. bölüm, 56 koltuk, ilk teklif sahnesi).

Simülasyon (bütün kampanya botu `camp2.js` = `tools/sim-campaign.js` + istatistik; 16 tohum; gün = bölgeye girişten sonra; bot teklifi filo koltuklarının %85'ine sığarsa ve Bristol'de ortalama sis tahmini %45'i geçmezse kabul eder):

| Bölge | Durum | B1 | B2 | B3 | Baron |
|---|---|---|---|---|---|
| Albuquerque | kontratsız (v124.6) | 55,1 | 83,5 | 105,0 | 140,9 |
| Albuquerque | v125.3 | 55,1 | 79,3 | 100,6 | 141,9 |
| Luksor | kontratsız | 59,9 | 86,3 | 109,7 | 139,1 |
| Luksor | v125.3 | 57,4 | 83,9 | 105,2 | 134,9 |
| Bristol | kontratsız | 56,4 | 98,1 | 127,8 | 147,5 |
| Bristol | v125.3 | 57,8 | 106,4 | 135,3 | 156,1 |
| Bristol | kontratsız, 32 tohum (1–32) | 57,4 | 101,0 | 128,6 | 148,2 |
| Bristol | v125.4 (teklif aralığı 7–10), 32 tohum | 56,5 | 102,5 | 130,8 | 151,3 |

Koşu başına başarılı iş: Albuquerque 9,6, Luksor 5,4 (24 uçulan sabah), Bristol v125.4'te 10,2 (14 uçulan sabah, sis kuponları ortalama £9.400). v125.3'te Bristol B2 %8,5 uzundu; v125.4'te teklif aralığı 7–10 güne indi ve 32 tohumla B2 +%1,5, B3 +%1,7, baron +%2,1 (16 tohumluk yarılar arasında ±%3 gürültü var: 1–16 +%6,5, 17–32 −%3). Kontrat hedefleri kaldırılıp kontratlar açık bırakılınca (ekonomik etki) Bristol baronu 150,9, kontratlar kapalıyken 150,4: kontratlar kendi başına aşağı yukarı nötr, fark hedeften.

**Kapadokya charter simülasyonu (v126):** `tools/sim-campaign.js`'in botu iki yerde düzeldi: oyuncunun dünkü kartları okuduğunu (bir ipucu bir kez çıkar) ve sabah olaylarının 7–8 günde bir geldiğini taklit eder (yoksa "sakin sabah" kuralı teklifi hiç getirmiyordu); rötarda ihtimal ≥%50 ise koltukları bekletir. Aynı botla, Kapadokya anlaşmaları kapalı / açık, gün = oyunun başından:

| Kapadokya | B1 | B2 | B3 | Baron |
|---|---|---|---|---|
| anlaşmasız, 32 tohum (yalnız Kapadokya, 240 gün) | 11,1 | 65,5 | 110,9 | 146,7 |
| v126 (grup %25–40), 32 tohum | 11,1 | 66,5 (+%1,5) | 113,2 (+%2,1) | 149,2 (+%1,7) |
| anlaşmasız, bütün kampanya, 16 tohum | 11,3 | 65,3 | 110,4 | 145,3 |
| v126, bütün kampanya, 16 tohum | 11,3 | 66,9 (+%2,4) | 113,3 (+%2,7) | 149,8 (+%3,1) |

İlk denemede grup %30–45'ti: 32 tohumda baron +%2,7, tohum 1–16'da +%4,9; grup %25–40'a indi. Gecikmenin kaynağı Baron bölümündeki %70 pazar payı: grubun yerinden ettiği pazar yolcuları rakiplere gider, rakipler biraz büyür. Koşu başına: teklif 9,8–10,1, başarılı iş 9,0–9,1 (bot hepsini kabul eder, hiç eksik yok), uçulan anlaşma sabahı ≈15, ilk iş 58–61. günde uçar (bot filosu 40. günde çoğunlukla 24 koltuk). Kontrat geliri / aynı koltukların normal bir gündeki bilet geliri 0,91–0,94; yerinden edilen pazar yolcuları düşülünce net kazanç ≈ €43.000–47.000 (kontrat gelirinin %39–47'si). Rötar: koşu başına 2,6–3,9 "gecikebilir" haberi, 1,5 gerçek rötar (uygun işlerin ≈%21'i); bot rötarların %79'unda bekletti, uçak bunların ≈%60'ında yetişti; tazminat koşu başına ≈ €1.300–1.700. Dünya Baronu günü 590,9 → 598,1 (+%1,2); öbür bölgelerin bölüm günleri rastgele sıranın kaymasıyla oynar (Bristol B2/B3 ±%7 gürültü, baronlar ±%2).

Önceki sürümün (v125–v125.1, yalnız Albuquerque, prim fiyatla) `sim-abq.js` sonuçları: kontratsız 53,5 / 82,2 / 102,3 / 139,8; kontratlı 53,5 / 80,5 / 101,1 / 141,4.

## Filo ve pilot getirme (v125, bütün bölgeler)
- **Kart (v125.5):** üç adım: balonlar, pilotlar, özet ve bedel (Geri / İleri, her adımda "Geç: sıfırdan başla"); listeler ince çerçeveli kutuda kayar, kart 375×667'ye kadar ekrana sığar.
Yeni bir bölgeye **girerken, yalnızca o an**, otomatik moddaki bölgelerden balon ve pilot getirilebilir ("Filonu getir" kartı; geçilebilir).
- **En çok 2 pilot** ve **en çok 16 koltuk** balon (iki küçük ya da bir orta sepet; büyük ve dev sepet taşınmaz). Kart en iyileri işaretli açar.
- **Pilotlar hemen gelir** (girişte ekipte). **Balonlar kargoyla 10 günde gelir** (Gün +10 sabahı "Kargo geldi evlat!"; v125.1, önce 30 gün ve pilotlar da kargodaydı).
- **Bedel:** balonların yeni fiyatı (bölgenin parasıyla) balonlar gelince başlayıp 30 gün boyunca günlük taksitle bölgenin kasasından holdinge ödenir (raporda "Getirilen balonların bedeli").
- Balonlar adını, tasarımını ve donanımını korur; reklam anlaşması evde kalır. Pilotlar seviyesini, tecrübesini ve özelliğini korur; maaşı yeni bölgenin parasıyla aynı rakam (Bristol'ün ×1,15'i girerken eklenir, çıkarken düşer).
- **Getirilenler yeni bölgenin bölüm hedeflerine sayılmaz** (koltuk ve pilot hedeflerinde "(getirilenler hariç)").
- **Kaynak bölge:** otomatik kazancı (`auto.base`) ve son 14 günün net geçmişi, giden koltukların payı kadar ve her pilot için %2 düşer.

Neden bu kadar sınır: Albuquerque'nin ilk haftaları koltuk sınırlı ($3.000 ve bir S balon), her ek koltuk birikerek büyür. Simülasyon (16 tohum, girişten sonraki günler):

| Getirilen | Abq B1 | B2 | B3 | Baron | Pazar payı 80./100. gün |
|---|---|---|---|---|---|
| Hiçbir şey | 53,5 | 80,5 | 101,7 | 140,7 | %25 / %49 |
| Sınırsız en güçlü seçim (XL+L, 2 kıdemli, hemen, bedelsiz, hedeflere sayılır) | 1,3 | 22,2 | 38,3 | 67,1 | %59 / – |
| 2 M + 2 kıdemli, hemen | 1,6 | 29,7 | 55,6 | 88,8 | %56 / – |
| 2 S + 2 kıdemli, hemen, hedeflere sayılmaz | 24 | 58 | 79 | 116 | %44 / %62 |
| Rakipler her balona 2 (ya da 4) balonla cevap verir | 17 | 38 | 56 | 86 | %57 / – |
| 2 S/M, 45 gün sonra, bedelsiz | 53 | 74 | 91 | 119 | %43 / %63 |
| **Seçilen: 16 koltuk (bot 1 M seçer) + 2 kıdemli, 30 gün kargo, bedeli 30 günde, hedeflere sayılmaz** | **53,4** | **75,6** | **93,1** | **128,8** | **%36 / %60** |

| **v125.1: aynı kural, pilotlar hemen, balonlar 10 günde** | **55,9** | **79,2** | **95,7** | **127,1** | **%39 / %61** |

v125 kuralı Albuquerque'yi ~%8 kısaltıyordu; v125.1'de baron ~%10 erken (127 / 141), ilk bölüm biraz uzar (kıdemli maaşları ilk haftalarda kasayı yer), B3 %5 erken. 20. gündeki pazar payı %8 (getirmeden %5). Yalnız pilot getirmek (balonsuz) yavaşlatır (71/91/111/144): kıdemli maaşı erken kasayı eritir.

## Bristol (v124)
Dördüncü bölge, İngiltere. Luksor'dan bir basamak zor.
- **Açılış:** Luksor Baronu olunca (`regionOpen('bri')`), Dünya Turu / Destekçi paketiyle (abq, lux gibi). Giriş £200.000, holding kasasından €240.000 (v124.2). Para birimi sterlin (`£`, sabit kur £1 = €1,20 (v124.2); eskiden `fx` 0,85: £1 = €1,20 (sabit kur); holdinge aktarılan sterlin euroya çevrilir). Başlangıç £6.000 ve bir S balon, başlangıç bileti £185. Pilot maaşları %15 yüksek (`regWage`). Turist tabanı 145 (diğer bölgeler 165).
- **Karakterler:** rehber Maggie Holloway (emekli balon zarfı terzisi), rakip patron Sir Reginald Ashby (Clifton Crown Balloons), müfettiş Graham Pike (İngiltere Sivil Havacılık Otoritesi). Rakipler: Clifton Crown Balloons (11 balon, £230), Severn Sky Co. (7, £190), Harbourside Air (6, £145); sonradan gelebilecekler Cotswold Air Holidays, Cheap Skies Bristol, Royal Crescent Flights, Mendip Balloon Co. Rakipler Luksor'daki gibi çabuk birleşir. Gazete: Avon Postası (20 peni). Girişte Hezarfen'in Bristol mesajı ve Maggie'nin tanışma sözü.
- **Hava:** sarı bayrak daha sık (yeşil %42, sarı %43, kırmızı %15; kış aynı). Batı rüzgârı Bristol Kanalı'ndan: katmanlar alçakta −2,5…+1,5, 60–180 m +2,5…+5, 180–350 m +3…+6 (doğuya, hedefe), en üstte yarı yarıya ters ya da zayıf.
- **Sabah sisi:** kırmızı olmayan günlerin %28'inde (`S.weather.fog.top` 90–150 m). Uçuşta yere yakın beyaz-gri bir bant; balon sisin üstündeyken iniş alanı (bayraklar, ışık sütunu, karavan) görünmez, altına inince görünür. Uçuş ipucu "Sis var: iniş alanını görmek için alçal". Sisli günde kendi uçuşunu kazasız bitirmek `fogFlown` sayacını artırır.
- **Havalimanı hava sahası:** kırmızı olmayan günlerin %40'ında (`S.weather.air`: başlangıçtan 380 m ötede başlayan 420–620 m genişlikte bir şerit, 340–410 m tabanının üstü). Kırmızı çizgili yarı saydam bölge, küçük uçak ve "HAVA SAHASI · N m üstü" etiketi. İçine girince uyarı; 3 saniye içinde kalınca ihlal: gün sonunda £1.500 ceza, popülerlik −0,04, gazete haberi. Kaza değil.
- **Uçuş manzarası:** Avon Kanyonu ve asma köprü (iki taş kule, zincirler, askılar; çoğu gün yolun üstünde). Köprü engeldir: kayalıklar 52 m, kuleler 108 m, kuleler arası zincir çizgisi 62–108 m; güvertenin altından geçmek yok. Tepedeki yuvarlak taş gözlem kulesi (82 m), liman (su, eski yelkenlinin direkleri 64–74 m, iki liman vinci 72–78 m), kilise kuleleri (engellerin %14'ü), meşe ve bakır kayın ağaçları, elektrik hatları. Tarlalar yeşil, çitlerle bölünmüş; önde gelgitli nehir. Martılar. Çarpışma mesajı engelin adını söyler.
- **İniş yerleri:** koyunlu ya da inekli tarla (1–3 tane): oraya inmek çiftçiyi kızdırır, £300 ceza, popülerlik −0,015, kötü yorum. Gelgit çamuru (yolda bir, limanda bir): kötü iniş, popülerlik −0,03, kötü yorum. Hedef alanı ve kalkış yeri bunlardan uzak tutulur.
- **Bristol Balon Festivali:** her 30 günde bir, 4 gün, talep ×1,8, kışın olmaz (ilki girişten 12 gün sonra). Bölüm hedefi `fiesta`. Festival günleri **akşam kalkışı**: filo gün batımında ikinci kez kalkar; elle uçulmaz, raporda oynanır: sabahki yolcunun %50'si aynı fiyatla, yakıt %60 (`EVE`). Rapor satırı "Akşam kalkışı (festival)", gece sahnesinde balonlar çayırdan yükselir.
- **Gece Işıltısı (Night Glow):** her festivalde bir kez, festival günlerinden birinde ayarlanır (£2.500, en az 3 uçabilen balon, o gece Şölen yoksa). O gece balonlar çayırda yerde durup müzikle (Şölen müziği) dalga dalga, sonra hep birlikte brülör yakar, 9. saniyeden sonra havai fişekler; ~15 sn, atlanabilir, gece animasyonu kapalı olsa da oynar. Popülerlik +0,04, ertesi sabah manşet, "Gece Işıltısı" kartpostalı. Balon Şöleni'nin yerine geçmez. Filo sayfasında ve aksiyon listesinde düğme, festival uyarısından da açılır.
- **Kasaba:** bal rengi Bath taşı, arduvaz (slate) beşik çatılar, pastel Clifton evleri (mağara otelinin yerine), yeşil bakır kubbeli saray oteli, kırmızı telefon kulübeleri ve posta kutuları, iki yolda giden çift katlı otobüsler, çizgili tenteli sokak pazarı (v128: çarşı; tabelası, bayrak dizisi ve çiçek sepetleriyle), arnavut kaldırımı ve su birikintileri, bakır kayın (mor-kırmızı) ve meşe, kenarlarda çitli tarlalar ve koyunlar, kasabanın arkasında liman ve eski yelkenli, martılar, bulutlu soluk mavi-gri gökyüzü ve gri-beyaz pus. Açılış ekranında BRISTOL, kuleler, Gürcü sıra evleri ve ağaçlar.
- **Bölümler (`CHAPTERS_BRI`):**
  1. Ashton Malikânesi (£5.000, Bristol Ticaret Odası): 48 koltuk, 3 pilot, 4,7★, iki otel anlaşması, rehber uçuşu, rüzgâr direği sv. 2.
  2. Avon Kanyonu (£10.000, Batı İngiltere Pilotlar Derneği): 220 koltuk, influencer, 4,75★, pazarın %35'i, sisli bir günde uç, direk sv. 3, hangar sv. 2.
  3. Festival (£20.000, festival jürisi): 380 koltuk, bir otel satın al, festivalde uç, bir Gece Işıltısı düzenle, pazarın %55'i.
  4. Bristol Baronu: pazarın %75'i, 2 otel, pilot okulu, 4,8★, dev balon "Avon Yıldızı", hangar sv. 3.
  Bristol Baronu, holdingin son hedefi Dünya Oyunları gösterisini açar (Dünya Baronu).
- **Simülasyon (v124, `tools/sim-campaign.js 6 2000`):** Bristol'e girişten bölüm sonlarına gün (tohum 1–6): [39, 91, 126, 139], [39, 86, 120, 144], [37, 82, 116, 127], [31, 76, 116, 135], [55, 109, 161, 188], [34, 81, 124, 151]. Baron 127–188 gün, ortalama ~147 (12 tohumda bir tohum 215). Hiçbir bot takılmadı, iflas yok; Dünya Oyunları Bristol Baronu'ndan 1 gün sonra alınır, Dünya Baronu 540.–665. gün. Ayar: başta (4/8/15 balon, %30/%50/%70) Bristol ~118 gün sürüyordu; filo hedefleri 4/14/24, pay %35/%55/%75, turist tabanı 145 ve akşam kalkışı %50 ile uzatıldı. Bölümleri çoğunlukla filo (para) bitiriyor; son bölümü dev balon.
- **Test:** Ayarlar > Test (prototip) > "Bristol testi": üç bölgenin baronu, Bristol'de 6 balon, 5 pilot, £40.000, iki gün sonra festival.

## Holding
- Holding kasası euro. Ülkelere para aktaramaz. Otomatik bölgelerin kazancı her gün gelir; oynanan bölgeden %25, %50 ya da 10.000 bırakıp hepsi çekilebilir (dolar 1,1'e bölünür).
- Giderler: otomatik gelirin %25'i (dört ofis açıksa %20).
- **TV kampanyası:** €250.000, 14 gün bütün bölgelerde talep +%20, bulunulan bölgede +0,1 popülerlik, 30 gün bekleme.
- **Ünlü reklam yüzü:** €600.000, 90 gün talep +%10, +0,15 popülerlik.
- **Forma sponsorluğu (v122.7, Anlaşmalar birimi):** ligin son şampiyonunun forma sponsoru (takım adı yazılmaz, oyun dünya çapında): €3.000.000, 180 gün bütün bölgelerde talep +%15, +0,1 popülerlik (≈+0,4★); süre bitince yeniden alınabilir.
- **Dünya Oyunları açılış gösterisi (v122.7, Anlaşmalar birimi):** açılış töreninin resmî balon gösterisi: €10.000.000, bir kez; 60 gün bütün bölgelerde talep +%30, +0,2 popülerlik (≈+0,8★). Etkiler ünlü yüz ve TV ile çarpılarak birleşir.
- **Billboard:** €120.000, bulunulan bölgede 20 gün talep +%10.
- **Zarf Ar-Ge'si:** €400.000 ile ömür 160, €900.000 ile 200 uçuş.
- **Rekor projesi (5. masa):** Luksor'a girince açılır. İrtifa rekoru €400.000 / 25 gün / %65 / talep kalıcı +%5; dünya turu €900.000 / 40 gün / %50 / +%10. İlk deneme hep başarılı (gizli); geliştirme denemelerinde oranlar geçerli, başarı +%2 (toplam en fazla +%25).
- **Sponsorlu özel şekiller (6. masa):** şişe 30 gün €4.000/gün, roket 45 gün €6.500/gün, ayakkabı 60 gün €9.000/gün; imzalanan bölgede popülerlik her gün 0,001 / 0,0015 / 0,002 düşer (yıldız olarak 0,004 / 0,006 / 0,008). Fiyatın altında "€4.000 × 30 gün" yazar. Sözleşme bozulabilir (v108): ceza = şimdiye kadar alınan para + kalan günlerin ödemesinin yarısı, yani bozmak her zaman kalan sürenin yarısı kadar zarar ettirir.
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

## Görünüm ayarları (v110)
- **Uçuş:** gökyüzünde üç katman bulut var; sadece balonun yatay hareketiyle kayar (balon sağa giderken sola), uzaktakiler kameranın %25'i, ortadakiler %45'i, yakındakiler %70'i hızında; balon yatayda durunca bulutlar da durur. Sepet zarfın altında hafifçe salınır (±~2°), brülör yanarken biraz daha; yerde durur. TestFlight'ta "uçtuğumu hissetmiyorum, sadece yer gidiyor" geri bildirimiyle eklendi.
- **Yolcu toplama animasyonu:** ayarlardan kapatılabilir. Kapalıyken yolcu kartı yine çıkar (yolcuların nereden geldiği, kimin uçacağı seçimi) ama hemen dolar; kasabada yürüyen yolcular ve cipler gösterilmez, kalkışa beklemeden geçilir.
- **Gece sahnesi:** ayarlardan kapatılabilir. Kapalıyken gece yine hesaplanır (olayı gazeteye girer), sadece kasabanın gece görüntüsü atlanıp sabaha geçilir.
- **Kayıt kodu (v124.3):** başka cihaza geçmek için. Kod oyunun sıkıştırılmış hâli ("BB1:" ile başlar); yarın gelecek gazeteyi, ekranda görünen 8'den eski yorumları ve grafikteki 60 günden eski itibar geçmişini taşımaz, kesirli sayılar 4 basamağa yuvarlanır (prototip). Geç bir oyunda ~%25 kısalır. Kod kopyalanabilir ya da "BalloonBaron-<şirket>.txt" dosyası olarak paylaşılabilir (AirDrop, Mesajlar, Dosyalar); yükleme ekranında yapıştırılır ya da "Dosyadan" ile seçilir. Eski kodlar da yüklenir. Kısa kod için sunucu sonra.

## Bölgenin ilk günü (v125.5)
Yeni bölgeye girince gelen kartlar kısa: Hezarfen'in giriş sözü, yerel rehberin tanışması ve patronun merhabası birer ikişer cümle (rüzgârın türü, başlangıç parası ve balon, rehberin adı, patronun tek iğnesi); geri kalanı "Daha fazla"nın arkasında. Metinler PORT_QUEUE v125.5'te eski/yeni olarak listeli.

## Hezarfen Usta
Hezarfen Kapadokya'nın rehberi. Albuquerque'de Ben Franklin (1783'te Paris'te ilk balonları izlemişti), Luksor'da İmhotep rehberlik eder. Dünya haritasında Bristol ve Maasai Mara isim olarak var, henüz açılmaz.

Yaşlı, karizmatik mentor. Daktilo efektli konuşma balonuyla konuşur. Konuları:
- karşılama (1. gün), sigorta (2. gün), hedefler (3. gün, v110; önceden 2. gün), filo, banka, pazar, ekip
- sarı ve kırmızı bayrak
- görev, kaza, kriz
- rakipleri batırma ipuçları
- beklenti (4,5★), tekel, eskime
- hedefler, holding, Albuquerque, Fiesta, bölge sorunları, ofisler, ünlü anlaşması
- dinamik haberler (kış, yeni rakip)
- **yönetime geçiş** (v110): 7. günden sonra, ekip dersini görmüş ve en az 2 balonu olan, hâlâ kendi uçan oyuncuya: amirali pilota verip yönetime geçebilirsin, ama lisans için 15 günde bir uç, 5 günden uzun uçmazsan popülerlik aşınır
- **rakipsiz gün** (v110): hiç rakip yaşamıyorken koltuklar dolmadıysa ve fiyat "uygun" bandın üstündeyse: rakip olmasa da turist pahalı bilette vazgeçer, dolu sepet çoğu zaman daha çok kazandırır
- **övgü** (v99): Kapadokya'daki ilk 40 günde doğru hamleleri över, her biri bir kez, en fazla iki günde bir: kırmızı bayrakta yerde kalmak, ilk kusursuz iniş, ilk özel istek, üst üste 3 iyi iniş, ikinci balon, ilk pilot, ilk otel anlaşması, ilk bina yükseltmesi, 5 gün üst üste kâr, 4,3★. Düğmesi "Sağ ol usta".

**Acemiyi koruma** (v99): ilk 3 günde kırmızı bayrak çıkmaz (çıkarsa sarı olur). İlk 20 günde kırmızı bayrakta "Yine de uç"tan sonra Hezarfen bir kez daha sorar ("Uçarsan batabilirsin"); öne çıkan düğme "Haklısın, pas geç".

## Kasaba: binaları ayırt etmek (v128)
Sahibin geri bildirimi: oyuncular binaları karıştırıyordu (en çok rehber ofisi, influencer ajansı, çarşı ve pilot okulu). Binaların üstüne yazı yok (altı bölge yazısı, HANGAR / EKİP / FİNANS / ŞİRKETLER / AJANS / OTELLER, kumda kalır); bunun yerine her biri uzaktan okunan, kodla çizilmiş bir işaret taşır, her bölgede o bölgenin üslubunda (Kapadokya tüf, Albuquerque kerpiç, Luksor kerpiç ve kireç badana, Bristol tuğla):
- **Rehber ofisi:** kapının önünde lacivert ceketli rehber, havaya kaldırdığı sarı-beyaz şemsiye (ucunda mercan flama); solda ayaklı, iki kanatlı büyük katlanır vadi haritası (nehir, tarlalar, kırmızı noktalı tur rotası ve iğneler, köşede küçük balon); önünde 5 küçük turist (rehberler seni öneriyorken 7), şapkalı ve fotoğraf makineli.
- **Influencer ajansı:** çatıda iki ayak üstünde büyük bir telefon tabelası (koyu gövde, mor-pembe ekran, oynat düğmesi, ekrandan yükselen kalpler) ve yanında üç ayaklı halka ışık. Kampanya sürerken ekran parlar ve halka ışık yanar. Duvardaki eski neon tabela ve terastaki küçük halka ışık kalktı.
- **Pilot okulu:** ön köşede lacivert bayrak, üstünde beyaz kep (kare tepe, alt bant, sarı püskül), çizilmiş, yazı ya da simge değil; avluda direkli rüzgâr çorabı; eğitim balonu artık havada uçmaz, avlunun üstünde dört halatla yerdeki kazıklara bağlı alçakta durur, sepeti yerden biraz yukarıda (yarıçap 30).
- **Çarşı (taşındı):** eskiden doğu duvarına sıkışmıştı (gx 14,05, gy 2,75, 1,35 × 1,7) ve ızgarayı bozuyordu. Şimdi meydanın güneybatı köşesinde, ana yolun (gx 7,55–8,45) batı kaldırımında, yola bakan üç dükkânlık bir sıra: gx 5,9, gy 8,7, 1,4 × 2,5 (yükseklikler 44 / 52 / 44). Her dükkânın yola bakan açık önü (içinde mallar), kaldırımda bir tezgâh (mal yığınları), kendi renginde 8 çizgili, kenarı fistolu tente ve tentelerden sarkan fenerler; sıranın sonundaki dükkânın bize bakan yan duvarında asılı dokumalar. Bölgeye göre: Kapadokya kırmızı / turkuaz / safran tenteler, kilimler, renkli mozaik fenerler, ortadaki dükkânda mavi kubbe; Albuquerque çok çizgili serape tenteler, Navajo desenli kilimler ve köşelerde kırmızı biber ristraları, teneke fenerler, papel picado dizisi, boyalı çömlekler; Luksor mavi / hardal / yeşil tenteler, çizgili kumaşlar, pirinç fanuslar, kâselerde baharat külahları, ortada kubbe; Bristol yeşil / kırmızı / lacivert tenteler, arduvaz beşik çatılar (ortadaki dükkân badanalı), dükkân üstü renkli tabela bandı, çiçek sepetleri, üçgen bayrak dizisi, yan duvarda şirket balonlu asılı tabela. Önünde üç alışverişçi. Gece fenerler ve ampuller yanar (`NIGHT_LITE`).
- **Yer değişiklikleri:** Hezarfen heykeli (süs) (6,9, 8,9) → (9,05, 6,95), meydanın kuzeydoğu köşesi (önizleme noktası da); oradaki ağaç kalktı; meydanın güneybatısındaki iki ağaç (7,1, 9,2) ve (6,6, 10,7) kalktı, çarşının eski köşesine iki ağaç geldi (14,55, 3,35) ve (14,85, 4,5). Saray otelinin sağ ağacı (g+3, k+0,25) → (g+3,1, k+0,7). Bristol'de posta kutusu (7,3, 10,6) → (8,72, 9,7), pub tabelası (13,7, 4,65) kalktı. Otobüslerin meydan yolu (kare 7,08–8,92), yollar, duvar, kemerler, fener ve bayrak süsleri, sabah olayı noktaları ve 3B açılıştaki kasaba çakışmaz.
- **İsimler yalnız gerekince:** bir binaya dokunmak adını zaten gösterir. Yakınlaşınca (yakınlık ≥ 0,55) bütün binaların isim etiketi çıkar (eskisi gibi, adı ve alt satırı). Yeni: bir bina açıldığı gün (özelliği açılınca, ya da okul / atölye kurulunca; `S.opened[özellik] = gün`) ana ekranın uzak görünümünde de üstünde küçük bir isim etiketi durur, ertesi gün kalkar; geceleri yok. Etiket arayüzle aynı krem kutucuk, hafif gölgeli, binaya inen küçük bir uçla. Normal görünümde başka etiket yok.
- Hezarfen'in çarşı dersi artık "Meydanın hemen yanında, ana yolda bir çarşı açıldı" der.

## Görsel ve ses
- **Renkler:** mürekkep #2b2350, mercan #ff5e3a, güneş #ffc23d, cam rgba(30,24,64,.84).
- **Fontlar:** Barlow ve Barlow Condensed.
- **Görseller:** gün doğumu Kapadokya, katmanlı peribacası silüetleri, kodla çizilmiş balonlar.
- **Sesler (sentez):** brülör gürültüsü, kuş ve ortam sesi, formant sesli kalabalık uğultusu, alkış, fanfar, para, tık.

## Yerelleştirme
Metinler altı dilde: İngilizce (kaynak), Türkçe, Almanca, İspanyolca, Japonca, Korece. Swift'te String Catalog kullanılır (`tools/strings`). Türkçe ek uyumu ("Balon'a/Air'e") için metinler şirket adının arkasına ek gelmeyecek şekilde yazılır.

## Gösteren öğretici (v122)
TestFlight'taki yeni oyuncular Hezarfen'in balonlarını okumuyor ("hiçbir oyunda okumuyorum"); valfin balonu indirdiğini, peribacalarına çarpılabildiğini ve termiğin ne yaptığını bilmediler. İlke: anlatma, göster. Ekran kararır, kullanılacak öğe bir deliğin içinde aydınlık kalır (kesik altın çerçeve), bir ok gösterir, Hezarfen'in küçük yüzüyle en fazla bir cümle görünür. Adım, oyuncu o öğeyi kullanınca geçer, "Tamam"la değil. Katman hiçbir dokunuşu almaz, oyunu kilitleyemez. Satırdaki küçük "Geç" bütün öğreticiyi bitirir. İlerleme `S.tut.steps` içinde (adım → yapıldığı gün); hiçbir adım tekrarlanmaz. Eski kayıtlar (en az bir uçuş yapmış ya da 1. günü geçmiş) öğreticiyi atlar (`S.tut.done`).

**1. gün, ana ekran** (Hezarfen'in kısa "hoş geldin"i ve Kenan'ın selamından sonra):
1. `price`: bilet kartı aydınlık, "Fiyatı düşür: daha çok yolcu biner." Kart açılınca − düğmesi ve tahmin kutusu aydınlık. Fiyat düşünce (`price_low`) tahmini yolcu sayısı zıplar, çubuk dolarak uzar, yeşil "+N yolcu" yükselir (bu sayaç her fiyat değişiminde çalışır, kartta da); satır "Gördün mü? Yolcu arttı. Tamam'a bas." olur. Fiyat sayfası kapanınca adım biter (düşürmese de).
2. `go`: "Yolcu topla" nabızla parlar, ok gösterir: "Hazırsın: yolcu topla ve uç."

Eski boş koltuk ipucu (`price`, 2.–12. gün) kalır; artık o da rehberli bir eylemdir (bilet kartı, sonra − düğmesi).

**İlk kendi uçuşu** (uçuşta karartma 2,5 sn sonra %80 açılır ki peribacaları görünsün; çerçeve, ok ve satır kalır; Hezarfen'in koç ipuçları ve eski valf ipucu o sırada susar):
1. `burn` (yerdeyken): brülör ve balon aydınlık, balonun yanında yukarı ok, "Basılı tut: yükselirsin." Brülöre toplam 1 sn basıp 20 m'yi geçince ve yükselirken geçer.
2. `wind`: soldaki katman okları 0,6 sn arayla yukarıdan aşağı sırayla yanar, sonra hedefe en güçlü esen katman yeşil çerçeve ve "HEDEFE" etiketiyle işaretlenir, ok onu gösterir: "İleri gitmek için doğru yüksekliği bul." Balon toplam 2 sn hedefe doğru gidince (yatay hız hedef yönünde > 0,25) geçer.
3. `vent`: 70 m'nin üstünde (ya da 6 sn bekledikten sonra) valf düğmesi ve balon aydınlık, aşağı ok: "Valf sıcak havayı bırakır: alçalırsın, ileri götürmez." Valfe toplam 0,5 sn basınca geçer.
4. `field`: kamera 1,2 sn'de iniş alanına kayar, 2 sn durur, 1 sn'de döner; bu sırada uçuş %25 hızda akar. "Burada in." 4,2 sn sonra geçer.
5. `chimney` (kalkıştan sonra ne zaman çıkarsa, rüzgâr/valf/alan adımlarının önüne geçer): önündeki 40–300 m içindeki, ekranda görünen ve sepetin çarpabileceği yükseklikteki (tepesinin en çok 160 m üstü) ilk peribacası; bütün çarpılabilir bacalar kırmızı konturlu, o bacanın üstünde kırmızı "Sepet çarparsa kaza" etiketi, satır "Peribacasının üstünden geç: sepet çarparsa kaza." Bacayı geçince (ya da 9 sn sonra) biter.
6. `thermal`: termik 420 m'den yakına gelince sütun aydınlık, "Termik: içine girersen seni yukarı taşır." İçine girince ya da geçip gidince biter. İlk uçuşta termik çıkmadıysa ikinci kendi uçuşunda bir termik garanti edilir. Kalan uçuş adımları 5. kendi uçuşuna kadar gösterilir (`TUT_FLIGHTS`).

Uçuş bitince yarım kalan adımlar sonraki uçuşa kalır.

**Peribacaları her zaman okunur:** çarpılabilen bacalar daha koyu ve ince koyu konturlu çizilir; arka plandaki süs bacaları ufuk sisine daha çok karışır (%45 yerine %58). Sepet bir bacaya yatayda 90 m, dikeyde tepesinin 60 m üstüne kadar yaklaştıkça baca kırmızı kontur ve kırmızı ışıltıyla parlar.

**v122.1 (TestFlight):** yaklaşınca yanan kırmızı parlama yalnızca ilk kendi uçuşunda (v122.8; önce ilk 3 uçuştu); sonra bacalar yalnızca koyu ve ince konturlu kalır. Açılıştaki rüya uçuşunda brülörle balon daha hızlı yükselir (ivme 240 → 520, en çok 230 → 420); v122.6: yalnızca ilk açılışta (henüz şirket yokken) eski sakin hızla (240 / 230) yükselir.

**Termik (v124.6):** sütunun içinde olduğun sürece, sütunun tepesine (520 m) kadar taşır; önceden 2 sn'lik an sayılınca kaldırma bitiyordu ve balon sütunun ortasında düşüyordu. Termik dersi ikinci kendi uçuşunda (birinci uçuşta peribacası dersi kalır). İlk üç gün iniş alanı daha yakın: 1. gün 1.080 m, 2. gün 1.200 m, 3. gün 780–1.030 m (Kapadokya'da sonra 1.080–1.880 m).

**Termik:** kaldırma ikiye katlandı: içindeyken dikey hıza sim saniyesi başına +1,0 (önceden +0,5; sim saati gerçek saatin 6 katı, yani dikey hızda ~2,5 birimlik fark yerine önceki ~1,25). 2 sn'lik an hâlâ tamamlanır (sütun 130 m geniş); an tamamlanınca kaldırma eskisi gibi durur. Sütun daha belirgin: daha sıcak ışık, kenarlarında akan kesik çizgiler, yükselen ok başları, "TERMİK ↑" yazısı. İçindeyken sepetin altında yükselen üç ok ve küçük turuncu "Termik ↑" etiketi.

**Rehberli eylemler (yeni binalar ve ilk işler):** Hezarfen'in dersi uzun kart yerine tek cümlelik altyazı olur, uzun metin satırdaki "Daha fazla"nın arkasında. Ana ekran kamerası 0,9 sn'de binaya kayar ve yakınlaşır, bina altın halkayla nabız atar, ok gösterir; o sırada yalnızca bina dokunulur. Bina açılınca sayfa yapılacak öğeye kayar, geri kalan kararır, düğme aydınlanır. Düğme pasifse (para ya da yıldız yetmiyor) satır bunu tek cümleyle söyler, "Geç" ile geçilir. Oyuncu işi yapınca, sayfayı kapatınca ya da "Geç"e basınca biter (burada "Geç" yalnız o eylemi geçer); sonra sabahın sıradaki kartı gelir. Sabah en fazla 2 ders kuralı (v121.12) bunları da sayar.

| Ders | Nereye | Yapılacak |
|---|---|---|
| `ins` (2. gün) | Dock'taki sigorta çipi | Dock açılır, sigorta seçenekleri 2,5 sn gösterilir |
| `goals` (3. gün) | Hedef düğmesi | Hedefleri aç |
| `fleet` (3. gün) | Hangar | Bina kartında "Balonlarına git", sonra ilk "Yeni balon al" düğmesi |
| `bank` (4. gün) | Banka | İlk kredi teklifi 3 sn gösterilir (çekmek zorunlu değil) |
| `crew` (5. gün) | Pilot ofisi | "Ekibe git", ilk "İşe al" |
| `market` (6. gün) | Satış ofisi | "Pazara git", anlaşılabilecek ilk otel (yoksa ilki) |
| `guide` (7. gün) | Rehber ofisi | Rehber ekranı, bir rehber seç |
| `agency` (8. gün) | Influencer ajansı | Ajans ekranı, bir influencer seç |
| `bazaar` (9. gün) | Çarşı | Hediye fener seti, "Hediyeni al" |
| `workshop` (10. gün) | Balon atölyesi | Atölyeyi kur düğmesi |
| `school` (11. gün) | Pilot okulu | Okulu kur düğmesi |
| `price` (boş koltuk, 2.–12. gün) | Bilet kartı | − düğmesi |

**Kısa dersler:** ilk günlerin dersleri tek cümle (`HEZ_SHORT`: welcome, ins, fleet, bank, crew, market, guide, agency, bazaar, workshop, school, goals, price, yellow, red, mission, accident, pr, rivals, aging); eski metin balondaki "Daha fazla"da açılır. Anahtarlar aynı.

**Ölçüm:** `tutStep(ad)` her adımı bir kez `S.tut.steps`'e yazar; Swift portu TelemetryDeck olayını oradan gönderir. Olaylar: `price`, `price_low`, `go`, `burn`, `wind`, `vent`, `field`, `chimney`, `thermal`, `first_landing`, `skip`; rehberli eylemler için `ga_<ders>_done`, `ga_<ders>_left`, `ga_<ders>_skip`.

## Ailenin mektubu ve puan isteği (v123.1)
- **Puan penceresi:** ilk bölüm töreninden sonra ("Başla"ya basınca) bir kez Apple'ın kendi puan penceresi istenir. İlk büyük mutlu an orası.
- **Mektup:** 50. gün sabahı, Hezarfen'in kartlarından sonra bir kez bir zarf gelir. Ön yüzde Nevşehir balon pulu, Göreme damgası (o günün numarası) ve çizgisiz, romantik el yazısıyla "<şirket adı> kurucusuna, Göreme, Nevşehir". Dokununca zarf 180° döner; arkada kapağı tutan balon sticker'ı (şirketin renklerinde) brülör sesiyle yükselip uçar (alev çizilmez), kapak açılır, mektup zarftan çıkıp büyür. Zarf dönerken ve açılırken havada gündoğumu simleri (altın, şeftali, pembe) uçuşur, çanlarla sihirli bir müzik çalar; mektup açılınca açılış filmindeki gibi Hicaz makamında, kanunun çaldığı, hafif def eşliğinde ve kısa bir ney cevabıyla sade bir ezgi başlar, simler mektubun çevresinde süzülmeye devam eder. Mektup parşömen gibidir, mürekkep lekeli el yazısıyla yazılmıştır ve kaydırmadan ekrana sığar; üstünde köşelerinden bantlı aile fotoğrafı; metin aileden, 50. günü kutlar ve sevdiyse App Store'a yorum yazmasını rica eder; "Sevgiler, S. & U." imzalı. Altta "App Store'da yorum yaz" (uygulamada App Store'un yorum yazma sayfası) ve "Şimdi değil". Bir daha gösterilmez; otomatik ilerletmede gelmez.

## Tam oyun süresi (simülasyon, v123.4)
`tools/sim-campaign.js`: bot Kapadokya'dan başlar, baron olunca kasasını holdinge çekip Albuquerque'ye, sonra Luksor'a girer (Dünya Turu alınmış), en son holding hedeflerini bitirir. Uçuşların %85'i iyi ya da kusursuz, bölüm hedeflerine göre para biriktirir. 20 tohum, hepsi bitirdi, iflas yok. Ortanca oyun günü (aralık):

| Bölge | Giriş | Bölüm 1 | Bölüm 2 | Bölüm 3 | Baron |
|---|---|---|---|---|---|
| Kapadokya | 1 | 11 (10–13) | 56 (37–62) | 98 (85–114) | 139 (118–155) |
| Albuquerque | 142 (120–160) | 168 | 223 | 248 | 288 (252–311) |
| Luksor | 289 (253–312) | 340 | 370 | 387 | 424 (397–474) |

Bölge içinde baron süresi her bölgede ~140–145 gün. Dünya Baronu ortanca 428. gün (400–477), Luksor Baronu'ndan 1–3 gün sonra: Luksor Baronu anında holding kasasında €7–9 milyon birikmiş oluyor (Albuquerque baronunda €2,3–3,1 milyon), holding hedeflerinin toplamı ise ~€4,75 milyon (dört ofis €1,6M, Ar-Ge €1,3M, TV €250 bin, ünlü yüz €600 bin, kasa €1M). Yani holding hedefleri şu haliyle ayrı bir aşama değil.

v124: bot Luksor'dan sonra Bristol'e girer (Gece Işıltısı'nı festival bölümünde ayarlar), Bristol Baronu olunca Dünya Oyunları gösterisini alır. Sonuçlar "Bristol (v124)" bölümünde; Kapadokya, Albuquerque ve Luksor değişmedi.

v123.5: Dünya Baronu için 7. hedef Dünya Oyunları gösterisi (€10M), gösteri de ancak Bristol Baronu olunca alınabilir; Bristol Luksor Baronu'ndan sonra açılır. Böylece Dünya Baronu Bristol'ün sonuna taşınır.

v124.1: Bristol'ün kasabası kırmızı tuğla ağırlıklı: Viktorya dönemi tuğla duvarlar (açık derz, ara ara koyu ve açık tuğla), gri arduvaz üçgen çatılar, beyaz çerçeveli sürgülü pencereler, taş lento ve denizlik, her evde ayrı renkte boyalı kapı ve üstünde küçük ışıklık. Oteller ve banka bal rengi Bath taşı (Clifton). Çarşı v124.1'de siyah meşe kirişli bir Tudor pub'dı; v128'den beri meydanın yanında çizgili tenteli bir İngiliz sokak pazarı. Kasabanın çevresi taş kapaklı alçak tuğla duvar. Hangar da tuğla.
