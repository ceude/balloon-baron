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
- **Özellikler:** adayların %75'inin bir özelliği vardır: Şovmen (bahşiş +€9/yolcu), Temkinli (risk ×0,75), Gözü kara (risk ×1,3, uçuş başına popülerlik +0,003), Tutumlu (yakıt ×0,85), Sadık (ayartılamaz), Hikâyeci (popülerlik +0,002, iyi yorum; v131: açıklaması "yörenin efsanelerini anlatır", her bölgede doğru), Gece kuşu (maaş ×0,85, sabah %7 şansla geç kalır ve o gün balonu uçmaz).
- **Atama:** Pilotlar önce uçabilecek balonlara, büyükten küçüğe atanır; onarımdaki veya zarfı bitmiş balonlar en sona kalır. Kıdemli ve tecrübesi (XP) yüksek olan önce gelir.
- **Elle atama (v124.4):** oyuncu balon kartından pilotu ya da pilot kartından balonu seçebilir; pilot o balona sabitlenir. Başka balondaki bir pilot seçilirse ikisi yer değiştirir (öbür balon bu balonun eski pilotunu alır). "Otomatik" sabitlemeyi kaldırır. Sabit pilotlar önce yerleşir, kalanlar yukarıdaki kuralla dağılır. Sabit balon onarımdaysa, zarfı bittiyse ya da kurucu uçuruyorsa pilot o gün boşta kalmaz, başka balona geçer; sabitleme durur. Kovulan, ayartılan ya da ayrılan pilotun sabitlemesi düşer. Boşta pilot varken uçabilecek bir balon pilotsuz kalmaz.
- **Baş harf:** Kapadokya'da soyadı baş harfleri Türk alfabesinden (Q, W, X ve Ğ yok; Ç, Ö, Ş, Ü, İ var). Eski kayıtlarda Q/W/X olan pilotlar K/V/S olur.

## Hava
| Bayrak | Kaza olasılığı | Not |
|---|---|---|
| Yeşil | 0,006 | Normal uçuş |
| Sarı | 0,03 | Risk yüksek |
| Kırmızı | 0,14 | Uçuş yasak. %35 yakalanma, €5.000 ceza, 3 uyarıda 3 gün yasak. Sigorta geçersiz. |

**Hedefe giden kullanılabilir katman (v131).** TestFlight: "dört katman da alandan uzağa esiyordu, uçuşu iptal ettim". Eski kural her gün en az bir katmanın doğuya (hedefe) 3 m/s'den hızlı esmesini istiyordu, ama en alttaki katmanı (0–60 m) da sayıyordu. Orası peribacalarının, ağaçların ve elektrik hatlarının (95 m'ye kadar; Bristol'de köprü 108 m) arasında, boyunca uçulamaz. Kapadokya'da yer rüzgârı (yer rüzgârı / 3,6 × 0,45) kırmızı bayrakta 3,75 m/s'ye çıkabildiği için kırmızı Kapadokya günlerinin ~%7'sinde hedefe giden tek katman buydu; öbür üçü geriye esiyordu. Yeşil ve sarı günlerde (12.000 günlük denemede) böyle bir gün çıkmadı.
- Artık her gün (bütün bayraklar, bütün bölgeler) **kullanılabilir** bir katman hedefe en az `MIN_TOWARD` = 3 m/s (11 km/sa) eser. Kullanılabilir katmanlar 60 m'den yukarısı (1, 2, 3); Bristol'de havalimanı sahası (taban 340–410 m) rotanın üstündeyse en üst katman sayılmaz. Yoksa kullanılabilirlerden biri 3,5–6 × bayrak rüzgârı yapılır (eskisi gibi), havalimanı sahası çıkınca bir kez daha bakılır. Geri getiren katman kuralı (en az biri −0,5'ten yavaş değil) aynı.
- Oyunda "uçulamaz" gün kırmızı bayraktır; uçuş öncesi bellidir. Rüzgârlar artık kırmızı günde de hedefe götürür.
- Test: `WindReachTests` (dört bölge × 2.500 gün; basit bir bot her yeşil ve sarı günde en iyi kullanılabilir katmana çıkıp hiçbir şeye çarpmadan alana varıyor).
- Denge: oyunun hissi değişmedi (kural sadece eski kuralın kaçırdığı günlerde devreye giriyor), ama rastgele dizi kaydı. Baron günü simülasyonu (WorldTests'teki odaklı bot, 56 tohum): eski 172, yeni 177,5 gün ortalama (gürültü düzeyi).

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

Kasa −€5.000'in altına düşerse banka balona el koyar. Ayrıntı: "İflas, holding kurtarma ve kapanan bölge (v133)".

### İflas, holding kurtarma ve kapanan bölge (v133)
Önce (`tools/sim-bankrupt.js`): gün sonunda kasa −5.000'in altındaysa banka her gün bir balon alıyordu (amiral dışındaki en büyüğü önce; %50, ikinci elde %30); son balon (amiral) gidince oyun bitiyor ve kayıt **siliniyordu**, milyonluk bir holding de dahil. Yeni bölgeye tek küçük balon ve 3–6 bin ile girildiği için sigortasız tek kaza yetiyordu; holding de bölgeye para gönderemiyor.
- **Amiral için süre:** amiral dışındaki balonlar eskisi gibi her gün birer birer gider. Amiral ancak kasa gün sonunda **3 gün üst üste** −5.000'in altında kalınca alınır (`RegionState.debtDays`, prototipte `S.debtDays`, bölge başına; kasa bir gün sonunda çizginin üstüne çıkınca sayaç sıfırlanır). Sıradaki balon amiralse raporda, ana ekranda (dokununca kurtarma planı) ve kurtarma planında kırmızı uyarı: "Banka N gün içinde amiral balonuna el koyacak" (`grace.title`, N = 3 − sayaç). İlk böyle sabahta kurtarma planı (kredi, satış, fiyat…) kendiliğinden yeniden açılır.
- **Holding yoksa** (Kapadokya baronu olunmadan): son balon gidince oyun eskisi gibi biter, kayıt silinir.
- **Holding varsa** (herhangi bir baronluk) son balon alınmadan önce karar sorulur (`GameState.ruinPending`, prototipte `S.ruin`): raporda "Banka son balonuna el koymak üzere" ve "Karar ver"; kart (`RuinView`, `showRuin`) bedeli, holding kasasının önce/sonrasını ve iki seçeneği gösterir. Otomatik ilerletme bu anda ve amiral sıradayken durur. Uygulama kapatılıp açılırsa kart ilk iş olarak yeniden gelir.
- **Holding kurtarma:** bölgenin kasası 10.000'e (bölgenin parasıyla) çıkarılır. Bedel holdingden: **kurtarılan paranın 3 katı (euroya çevrilmiş), holding kasasının %25'i ve €250.000'den hangisi büyükse** (1.000'e yukarı yuvarlanır; v134, TestFlight: "yoksa sonsuz ekstra can"; v133'te %10 ve €100.000). Holding bunu ödeyemiyorsa kurtarma yok, bölge kapanır. Ayrıca bölgenin popülerliği **yarım yıldız** düşer (`Bankruptcy.rescueRepLoss` 0,125, en az 0,4; prototipte `RESCUE.rep`), gazete "Holding kurtardı" diye manşet atar, Hezarfen popülerliğin düştüğünü söyler. Her bölge için **bir kez, kalıcı** (`Holding.rescued` hiç silinmez: bölge kapanıp yeniden girilse de hak geri gelmez); balon, krediler, bölümler ve oteller yerinde kalır, sayaç sıfırlanır, gece normal gelir. Kurtarma kartı kabul etmeden önce bütün zararı kırmızı bir kutuda söyler: euro bedeli, holding kasası önce → sonra, bu bölgedeki popülerlik önce → sonra (yıldız) ve bu bölge için bir daha asla kullanılamayacağı; "Holding kurtarsın" seçeneği de kırmızı çerçevelidir ve kasa ile popülerlik değişimini tekrar yazar (`ruin.damage`, `ruin.dmg.*`).
- **Bölge kapanır** (holding yetmezse, kurtarma kullanılmışsa ya da oyuncu seçerse): bölgedeki şirket tasfiye edilir (balonlar, pilotlar, oteller, binalar bankaya), bölge silinir (`Holding.closed[bölge] = gün`). Oyuncu filosu en büyük öteki bölgesine geçer (`ruinNext`). Başka bölge yoksa aynı bölgede **ücretsiz** sıfırdan yeni şirket kurulur (küçük balon, başlangıç kasası, bölüm 1; Kapadokya'da Kapadokya rakipleri). Holding, öteki bölgeler, baron unvanları, holding hedefleri, kartpostallar ve Game Center başarımları, tasarımlar ve kayıt kalır. Hezarfen ve gazete söyler.
- **Yeniden giriş:** kapanan bölge dünya haritasında "Kapandı" etiketiyle görünür ve giriş bedeliyle (Albuquerque/Kapadokya €100.000, Luksor €150.000, Bristol €240.000) yeniden girilir: sıfırdan, bölümler baştan, bölüm ödülleri yeniden kazanılabilir. Kazanılmış baron unvanı kalır, sonraki bölgeler açık kalır. Kapadokya da kapanınca bu yolla geri gelir (Hezarfen'in "yeniden hoş geldin" sözü). Bir bölgenin kurtarma hakkı yeniden girince geri gelmez.
- **Simülasyon** (`tools/sim-bankrupt.js all 40 800`, 15 profil × 40 tohum = 600 oyun; `RUIN=accept` kurtarmayı karşılayabildiği her seferde alır, `RUIN=half` yarı yarıya reddeder):

| | Önce | v133, hep kabul | v133, yarı yarıya | v134, hep kabul | v134, yarı yarıya |
|---|---|---|---|---|---|
| Oyun sonu (kayıt silinir) | 333 | 278 | 278 | 278 | 278 |
| … holding varken | 45 (Albuquerque 30, Luksor 10, Bristol 5; toplam €88 milyon holding silindi) | 0 | 0 | 0 | 0 |
| … holding yokken (Kapadokya) | 288 | 278 | 278 | 278 | 278 |
| Holding kurtarma (oyun) | – | 54 (41) | 30 (28) | 53 (40) | 29 (28) |
| Kurtarma bedeli: ortanca / ortalama / en çok | – | €305.000 / €388.000 / €1,39 milyon | €322.000 / €362.000 / €936.000 | €843.000 / €1,02 milyon / €3,48 milyon | €855.000 / €1,01 milyon / €2,58 milyon |
| Kurtarma anında holding (ortanca) | – | €3,05 milyon | €3,22 milyon | €3,37 milyon | €3,42 milyon |
| Kapanan bölge (oyun) | – | 56 (20): kurtarma kullanılmış 52, holding yetmedi 4 | 85 (32): reddetti 35, kullanılmış 46, yetmedi 4 | 58 (24): kullanılmış 44, holding yetmedi 14 | 71 (36): reddetti 32, kullanılmış 25, yetmedi 14 |
| Dünya Baronu | 122 | 143 | 142 | 143 | 138 |

  v134: bedel ortancası €305.000'den €843.000'e çıktı (holdingin ~%25'i; 53 kurtarmanın 11'i €250.000 tabanında). Holding kurtarmayı karşılayamadığı için kapanan bölge 4'ten 14'e çıktı. Kurtarmayı hep alan botlar Dünya Baronu sayısında değişmedi (holding oyun sonunda zaten zengin), ama her kurtarma artık holdingin dörtte birini ve yarım yıldızı götürüyor.

  Holding artık hiç kaybolmuyor. Holding yokken oyun sonları azaldı ama az (288 → 278): bu botlar kurtarma planına bakmıyor ve batan şirketlerin çoğu tek balona düştüğünde zaten günlerce eksidedir; süre dikkatli oyuncuya üç gün verir. Kapanan bölgelerin çoğu aynı kumarbaz botların yeniden girdikleri bölgede tekrar batmasıdır.

100.000 kredisi (v109.1) bölgenin son 14 günlük ortanca net kazancı 10.000'i ilk geçtiği akşam açılır ve bir daha kapanmaz. Simülasyon (`tools/sim-loans.js`; bot krediyi açıldığı gün çekip hepsini balona harcıyor): 10 tohumda 94–122. günde açıldı, hiç el koyma yok.

**Satın alma kredisi (v109.2):** bankanın kredi listesinde değil; satılık bir rakip ya da iflas etmiş bir filo olunca teklif kartında ve Pazar'da "Krediyle al" düğmesi çıkar. Konut kredisi gibi: banka eksik tutarı doğrudan satıcıya öder, kasaya para girmez. Oyuncu kasasından ödeyebildiğini öder, kasada €10.000 kalır; bu pay fiyatın en az %20'si olmalı. Banka en fazla 500.000 öder; 150 gün, faiz %20 (taksit = ödenen × 1,2 / 150, 10'a yuvarlanmış). Aynı anda tek satın alma kredisi; sadece 100.000 kredisi açıldıktan sonra ve filoda en az 10 balon varken (v109.3; azsa teklif kartı gereken ve mevcut balon sayısını yazar). Kasa fiyata yetiyorsa sadece nakit seçeneği çıkar, kredi sunulmaz.

**Neden kullanılamadığı (v131).** TestFlight: "hiç kredim yoktu, bütün şartları sağladım ama satın alma kredisini alamadım." Kodda bir hata yoktu; kart sadece "bankadan kredi çek" diyordu ve hangi şartın tutmadığını söylemiyordu. En olası sebep: 100.000 kredisi o bölgede hiç **açılmamıştı** (kredi almamış olmak yetmez; bölgede tipik bir günün net kazancı, son 14 günün ortancası, en az 7 gün sayılmışken 10.000'e ulaşmalı ve bu kredi bölge başına açılır: Albuquerque'ye geçince orada, dolarla yeniden açılması gerekir) ya da banka payı 500.000'i aşıyordu (büyük bir rakipte kasadaki parayla fiyat arasındaki fark). Artık teklif kartı "Kasa: X. Fiyata eksik: Y." yazar ve kredi kullanılamıyorsa sarı kutuda bütün engelleri sayılarıyla sıralar; Pazar'daki teklif ve iflas satışı kartlarında da düğmenin altında aynı kutu çıkar (`Game.buyLoanBlocks`, prototipte `buyLoanWhy`):
- Banka henüz açılmadı.
- Balon: gereken 10, buradaki N.
- Aynı anda tek satın alma kredisi (şimdiki ödeniyor) / aynı anda en fazla iki kredi.
- 100.000 kredisi bu bölgede açılmadı: tipik gün şu an X (7 günden azsa sayılan gün).
- Banka en fazla 500.000 öder: kendi cebinden X daha gerekir.
- Senin payın fiyatın en az %20'si, kasada 10.000 kalır: X daha gerekir. Onay kartı fiyatı, senin payını, bankanın payını, taksiti, toplamı ve kış/bakım/el koyma uyarısını gösterir.

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
  - **Turist sayısı:** festival, fiesta, kış, bayrak, satış ofisi ve holding yatırımlarının çarpanı. v129: satırın sağında o günkü turist sayısı (öteki satırlar gibi), çarpanlar etiketin altında küçük, soluk, sola yaslı bir alt satır ("Festival +%40 · Sarı bayrak −%10").
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
  **v141.4 (TestFlight):** influencer yorumu her bölgede Kapadokya'nın @gezginayse'sini anıyordu (Bristol'de görüldü). Yorumların yer adı geçen satırları gibi influencer'ın hesabı da bölgeye özgü (hepsi uydurma): Kapadokya @gezginayse, Albuquerque @mesa.maddie, Luksor @layla.on.the.nile, Bristol @harbourside.hattie, Maasai Mara @savanna.amani (`review.influencer.0.<bölge>`, prototipte `REV_AT[bölge].influ`; Türkçede hesap adına ek gelmez: "… hesabındaki videoyu"). Gezi influencer'ının alt yazısı "Vadiyi" değil "Burayı bütün dünyaya tanıtır". Uygulamada rastgele yorumcular arasında Göreme'li Mehmet de vardı (yalnız Kapadokya'nın açılış yorumu için); artık rastgele yorumu yalnız gezginler yazar, prototipteki gibi.
