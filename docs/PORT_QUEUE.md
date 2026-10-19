# Swift'e aktarılacaklar

Prototipte yapılıp henüz iOS koduna geçmemiş değişiklikler. Karar verilince toplu olarak aktarılır.

## Filo ve ekip arayüzü (prototip v19)
- **Filo sırası:** Amiral önce, sonra kapasiteye göre büyükten küçüğe, sonra isme göre.
- **Ana ekranda filo:** 4 balona kadar yan yana kartlar. 5 ve üstünde tek özet çubuğu ("Filo: 17/20 balon uçacak · 240 koltuk · 1 onarımda…").
- **Bugünün uçuş planı listesi:** Özet çubuğuna dokununca açılır. Boya göre gruplanır (XL, L, M, S), her grupta "Hepsi / Hiçbiri", üstte "Hepsi uçsun / Hepsi yerde". Uçamayan balonlarda sebep ve ilgili sayfaya kısayol bulunur. Aç/kapa için ayar anahtarı değil, oyun tarzı buton: "UÇACAK" (mercan) / "YERDE" (gri), dokununca tık sesi.
- **Pilot etiketi:** Balon kartlarında ve listede "Pilot: Elif (Kıdemli)" biçiminde, seviye parantez içinde.
- **Ekip sekmesi:** Boştaki pilotlar en üstte ayrı bölümde, toplam boşa giden maaş uyarısıyla. Görevdeki pilotlar balon büyüklüğüne göre sıralı, onarımdaki balonun pilotunda "(onarımda)" yazar.
- **Pilot ataması (davranış düzeltmesi):** Pilotlar önce uçabilecek balonlara atanır, onarımdaki veya zarfı bitmiş balonlar en sona kalır. Aynı kıdemde tecrübesi (XP) yüksek olan önce gelir. Ekip sekmesinde bu kural bir cümleyle anlatılır. Swift'te `Game.assignPilots()`.

## Sade ana ekran (prototip v21)
- **Alt panelin sırası:** tek uyarı, filo çubuğu, sigorta çipleri, bilet kartı, "Pas geç / Yolcu topla".
- **Uyarılar:** Önem sırasına göre dizilir: kırmızı, görev, sarı, yeşil, kış. Sadece ilki görünür, kalanlar "+N uyarı daha" ile açılır. Her sabah yeniden kapanır.
- **Filo çubuğu:** Balon sayısından bağımsız her zaman tek çubuk. Altında "Amirali sen/pilot uçuruyor" yazar. Yan yana kartlar kaldırıldı.
- **"Kendim uçururum":** Sigorta çiplerinden çıktı, uçuş planının en üstüne taşındı: "Şafak balonunu kim uçursun? SEN / PİLOT", altında kurucu primi ve görev açıklaması. Lisans düşmüşse sadece "Amiral balonunu sen uçurmalısın" yazar.
- **Bilet kartı:** Tek satır: fiyat, tahmini yolcu/koltuk, gelir, doluluk çubuğu ve "Ayarla ›". Dokununca alttan fiyat paneli açılır (alt panel gizlenir). İçeriği:
  - −/+ butonları ve isimli rakip fiyatları ("Göreme €195").
  - **Fiyat algısı ölçeği:** "Turistlere göre: Uygun / Biraz pahalı / Pahalı / Çok pahalı". Fiyat isteği eşikleri ≥%85 / ≥%60 / ≥%35, ölçekte dört eşit renk bölgesi.
  - **Pazar cümlesi:** "Bugün X turist var, rakiplerle birlikte gökyüzünde Y koltuk: koltuk fazla, rekabet sert / turist fazla, balonlar kolay dolar." Turist sayısı fiyattan bağımsızdır: pazar talebi + otel misafirleri + rehber (5) + influencer (8) + popülerlik bonusunun fiyatsız hali (`touristsToday()`). Fiyat sadece kaçının seni seçtiğini değiştirir.
  - **Sonuç:** büyük "228/272 koltuk dolar" ve tahmini gelir. Gelirin panel açıldığındaki haline göre farkı ▲/▼ ile gösterilir. Altında doluluk çubuğu ve "Tamam".

## Tekel cezası (denge değişikliği)
- Uyarı metninde ceza oranı yazmaz, sadece "Rekabet Kurumu seni izliyor" der. Hezarfen de "şirketinin büyüklüğüne göre ağır bir ceza" der.
- Ceza = max(€5.000, şirket değerinin %3'ü). Şirket değeri: pozitif kasa + balonların alış fiyatı + sahip olunan otellerin alış fiyatı. Kasası boş olana da kesilir (eskiden `cash > 0` şartı vardı).

## Pazar sekmesi
- "Sen ve rakiplerin" bölümünde en üstte oyuncunun kendi kartı: rakip kartlarıyla aynı dört kutu (balon, fiyat, popülerlik, dünkü doluluk), mercan çerçeve ve "Sen" etiketi.
- Her kartın başlığında dünkü pazar payı etiketi ("pay %74").
- Dünkü doluluk için `lastShare`'a dünkü koltuk sayısı (`cap`) eklendi.

## Rakipler güçlendi (denge değişikliği)
- **Büyüme:** Rakip, 3 gün üst üste %70 üstü dolulukla uçarsa (eskiden %90) ve kasası yetiyorsa, 4 günde bir balon alır (temkinli L, diğerleri M). Filo tavanları temkinli 25, orta 18, riskli 12 (eskiden 10/7/5). Sahiplerin çektiği para için eşik artık bir sonraki balonun fiyatının %60'ını da içerir; rakip büyümek için birikim yapar.
- **Yeni gelenler (`entrantFleet`):**
  - Bosphorus Balloons her zaman oyuncunun balon sayısı + 3 balonla girer (L L M M M karışımı). Kasası en az 60.000 + 9.000 × balon.
  - Diğerleri 50. günden sonra oyuncunun yarısı kadar balonla girer; ek balon başına +6.000 kasa.
  - Yeni gelenlerin kasası ilk 20 gün çekilmez (savaş sandığı).
- **Birleşme (`mergeRivals`):** En küçük iki rakip tek şirket olur ("A & B Balloons"). Filolar toplanır, kasa = (iki kasa) × 1,3 + 40.000, popülerlik ikisinin yükseği, fiyat ortalaması, 20 gün savaş sandığı.
  - **Tetik:** 30. günden sonra oyuncunun payı %50'nin üstünde ve 4+ gün sürmüşse günlük %35, ya da bir rakibin kasası −€4.000'in altına inmiş ve oyuncunun payı %40'ın üstündeyse günlük %60.
  - En fazla 25 günde bir olur.
  - Oyuncuya kırmızı "SON DAKİKA: Rakiplerin sana karşı birleşti!" uyarısı çıkar: iki balon ikonu, yeni şirketin adı, balon/kasa/popülerlik, "Mücadeleye hazırım" butonu. Diğer açılır pencerelerden önce gösterilir.
  - Pazar sekmesinde birleşen eski şirket "Birleşti · X çatısı altında" diye görünür.
- **Kızıl Vadi Air başlangıç kasası:** €12.000 (eskiden €9.000).

## Bölümler ve Baron (Faz 1)
- **Kapadokya'da 3 bölüm (`CHAPTERS`), hedefler gün sonunda kontrol edilir:**
  1. **Kuruluş** (ödül €5.000): 5 balon, 4,0★, en az bir otel anlaşması, kasada €20.000.
  2. **Büyüme** (ödül €20.000): 10 balon, bir otel satın alımı, en az bir influencer kampanyası, en az bir rehber tanıtım uçuşu, pazarın %50'si, balon atölyesi.
  3. **Kapadokya Baronu** (unvan + dünya haritası): pazarın %70'i, 2 otelin sahibi, pilot okulu, 4,8★, imza balon (XL). Hepsi aynı gün.
- Influencer ve rehber kullanım sayıları tutulur (`influCount`, `guideCount`). Eski kayıtlarda `influCd > 0` / `guideCd > 0` kullanılmış sayılır.
- Pazar payı `shareNow` olarak tutulur; kimsenin uçmadığı günde son değer korunur.
- **Balon atölyesi:** Filo sayfasında €75.000'e kurulur. Tasarım stüdyosu Faz 3'te gelecek.
- Bölüm gün sonunda tamamlanınca ödül kasaya girer ve uçuş defterinde "Bölüm ödülü: X" satırı çıkar. Ertesi sabah tören penceresi açılır (diğer pencerelerden önce). Pencerede sıradaki bölümün hedefleri gerçek ilerlemeyle gösterilir: tamamlananlar tikli, diğerleri çubuk ve sayıyla.
- **Ödüller hikâyeye bağlı** ("yatırımcılar" yok):
  - Kuruluş: "Kapadokya Turizm Derneği seni yılın genç girişimcisi seçti".
  - Büyüme: "Türkiye Turizm Ödülleri'nde Yılın Balon Şirketi seçildin".
  - Yeni Dünya: "Albuquerque Ticaret Odası seni Yılın Yeni Şirketi seçti".
  - Fiesta: "Balloon Fiesta jürisi seni Fiesta'nın Yıldızı seçti".
- Yan menüde en üstte "Hedef" butonu, üstünde "1/4" rozetiyle. Hedef kartında her hedefin ilerleme çubuğu ve sayısı var (evet/hayır hedeflerinde "tamam / yok"). Baron olunca buton "Dünya" olur.
- **Baron töreni:** taç, Hezarfen'in sözleri, fanfar ve alkış, "Dünya haritasını aç".
- **Dünya haritası:** Gerçek koordinatlardan çizilmiş kıtalar, boylam −130…130, enlem 70…−40 kırpılmış. Kapadokya (Baron), Albuquerque (Baron olunca "Açıldı"), Luksor ve iki gizemli "???" bölge (Asya, Avrupa; Yakında).
- Hezarfen'in yeni "goals" dersi 2. gün çıkar.
- Yeni gelen rakip seçilirken, yaşayan ya da satıştaki şirketlerin adında geçen markalar (ör. birleşmiş "X & Bosphorus") dışarıda tutulur.
- **Lisans tuzağı uyarısı:** Lisans düşmüşken amiral balon uçamıyorsa (zarf eskimiş ya da onarımda), uyarı çıkış yolunu söyler: zarfı yenile, başka balonu amiral yap ya da ücreti öde.

## Bölgeler: Albuquerque ve otomatik mod (Faz 2)
- **Bölge yapısı:** Her bölgenin kendi durumu var (`RKEYS`): kendi kasası ve bankası (krediler), filo, pilotlar, rakipler, oteller, popülerlik, fiyat, yorumlar, bölüm, kış, Fiesta vb. Holding seviyesinde kalanlar: holding kasası, kurucu lisansı, atölye, tasarımlar, Hezarfen dersleri, gün sayacı.
- **Para birimi ve kasalar:** Her bölgede aynı rakamlar geçerli (Kapadokya'da €15.000 olan balon Albuquerque'de $15.000). Her bölgenin kasası kendi para birimindedir; `eur()` aktif bölgenin simgesini, `eurH()` her zaman euroyu gösterir. Krediler, atölye ve tasarımlar oynanan bölgenin kasasından ödenir.
- **Albuquerque:**
  - Kapadokya baronu olunca açılır. Giriş €100.000, holding kasasından. Bölgede sıfırdan başlanır: $3.000 ve bir küçük balon.
  - Kendi rakipleri: Sandia Sky Rides, Rio Grande Balloons, Route 66 Air.
  - Yeni gelenler: Mesa Gold Balloons (zengin zincir, oyuncu + 3 balon kuralı), Turquoise Trail Air, Desert Bloom Flights, Big Sky Fiesta Co.
  - Bölgeye özgü otel, sponsor, balon ve pilot isimleri (`REGION_DEF`), imza balon "Fiesta Yıldızı". Vadi görevi "Rio Grande dokunuşu" olur.
  - **Kutu rüzgârı:** katmanlar sırayla −, +, −, + yönde. İniş alanı 1.000–1.700 m.
  - **Balloon Fiesta:** her 30 günde bir, 4 gün, talep ×1,9, gökyüzünde 46'ya kadar arka plan balonu. Öncesinde 3 gün uyarı, sırasında görev uyarısı.
  - Görsel: daha sıcak gökyüzü, pembe Sandia sırtı, masa (düz tepeli) tepeler, kum rengi zemin, Rio Grande nehri, engel olarak kavak ağaçları.
  - Bölümler: **Yeni Dünya** ($5.000: 5 balon, 4,0★, otel anlaşması, rehber), **Fiesta** ($20.000: 10 balon, otel satın al, bir Fiesta'da uç, influencer, %50 pazar), **Albuquerque Baronu** (%70 pazar, 2 otel, pilot okulu, 4,8★, imza balon).
- **Otomatik mod:** Ayrılınan bölge son 14 günün ortanca net kârının %85'ini (euroya çevrilmiş) her gün ±%15 oynayarak holding kasasına getirir. Bölgenin kendi kasası olduğu gibi bekler.
  - Bölgede sorun yokken 6 günde bir sonrası her gün %7 ihtimalle sorun çıkar; Hezarfen haber verir, ana ekranda kırmızı uyarı, dünya haritasında "Sorun var".
  - Karar verilene kadar kazanç yarıya iner.
  - **Sorunlar** (her biri iki seçenekli, Hezarfen tavsiyeli):
    - Pilotlar zam istiyor: kalıcı −%6 ya da 3 gün sıfır.
    - Fiyat savaşı: kalıcı −%10 ya da %50 şansla 10 gün −%25.
    - Sert iniş: bölgeye gidip ilgilen (popülerlik −0,05) ya da 7 gün −%15.
    - Otel kapışması: 5 günlük kazanç kadar öde ya da kalıcı −%5.
    - Yıpranan zarflar: 8 günlük kazanç kadar öde ya da 10 gün −%12.
    - Ödemeler holding kasasından yapılır.
- **Dünya haritası:** Bölge kartlarında "Buradasın / Otomatik mod / Sorun var / Açıldı" ve "Bölgeye git", "Karar ver", "Gir €100.000" butonları.
- **Yan menü:** Baron olana kadar "Hedef", sonra tek "Holding" butonu (holding sayfası; sorun varsa kırmızı nokta, bölge baronu olunmadıysa hedef rozeti). Hedef kartında baronlar için "Dünya haritası ›" kısayolu.
- **Üst çubuk:** Birden fazla bölge varsa şirket adı yerine bölge adı.
- Hardcoded "€5.000" gibi tutarlar bölge para birimiyle yazılır.

## Balon atölyesi ve tasarım stüdyosu (Faz 3)
- Atölye bir kez kurulur (€75.000, oynanan bölgenin kasasından), tasarımlar bütün bölgelerde geçerli. Kurulunca Filo sayfasında "Balon atölyesi" bölümü: tasarımların listesi (küçük resim, yaratıcılık, tazelik, kaç balonda) ve "Yeni tasarım".
- **Tasarım stüdyosu:** 9 desen (çizgili, zikzak, damalı, yıldızlı, kalpli, güneş, dalga, gökkuşağı, puantiyeli), 12 renklik paletten ana/desen/vurgu rengi, isim. Canlı önizleme ve yaratıcılık puanı. Üretim €5.000.
- **Yaratıcılık puanı (5–100):** desen tabanı × 0,6 + ana/desen rengi parlaklık farkı × 30 + farklı renk sayısı + 10. Aynı desen ve ana rengi tekrar ederse −20, yaşayan bir rakibin ana rengini kullanırsa −10.
- Balon kartında "Desen: X" butonu: tasarım giydirmek €1.000.
- **Etki:** Tasarımlı her balon uçuşta popülerliğe 0,003 × puan/100 × tazelik ekler, günlük toplam en fazla 0,012. Tazelik 40 günde %100'den %20'ye iner. Uçuş defterinde "Tasarımların konuşuluyor" notu, %25 ihtimalle tasarım adını anan yolcu yorumu.
- Uçuşta, yerde ve listelerde balonlar desenleriyle çizilir.

## Holding (Faz 4)
- **Holding kasası (euro):** Ülkelere para aktaramaz. İki yoldan para girer:
  - Otomatik moddaki bölgelerin kazancı her gün doğrudan girer.
  - Oynanan bölgenin kasasından, sadece holding sayfasından ve istek üzerine çekilir (%25, %50, ya da 10.000 bırakıp hepsi). Dolar kasadan çekilen para 1,1'e bölünerek euro olur.
- **Holding giderleri:** Maaş, bina vb. için otomatik gelirin %25'i her gün düşülür. Uçuş defterinde "Holding kasasına +€X" notu.
- **Holding sayfası** (yan menüde "Holding"): kasa ve dünün akışı; bölge hedefi özeti; oynanan bölgeden para çekme; bölgeler (Karar ver / Bölgeye git / Gir); dünya haritası; yatırımlar; ofisler.
- **Yatırımlar** (hepsi holding kasasından):
  - **TV reklam kampanyası:** €250.000. 14 gün bütün bölgelerde talep +%20, bulunulan bölgede +0,4★. 30 gün bekleme.
  - **Ünlü reklam yüzü:** €600.000, 90 günlük sözleşme (uydurma ünlüler). Bütün bölgelerde talep +%10, bulunulan bölgede +0,6★.
  - **Otoban billboardları:** €120.000, bulunulan bölgede 20 gün talep +%10.
  - **Akademisyenlerle zarf Ar-Ge'si:** €400.000 ile zarf ömrü 120 → 160 uçuş, €900.000 ile 200 uçuş. Bütün bölgelerde kalıcı.
- **Talep etkisi:** Bu yatırımlar oynanan bölgenin günlük talebini ve otomatik bölgelerin kazancını (`holdBoost`) çarpar.
- **Ofisler (0/4):** Her şehirde bir ofis açılabilir, avantajlar birikir:
  - New York (€1,5 M): TV kampanyaları %25 ucuz.
  - İstanbul (€1,2 M): Kapadokya otomatik kazancı +%15.
  - Tokyo (€1,4 M): tasarım yaratıcılığı +10.
  - Seul (€1,3 M): ünlü sözleşmeleri iki kat uzun.
  - Dördü de açıksa holding giderleri %25 yerine %20. Her açılışta Hezarfen haber verir; dördüncüde "gerçek bir dünya şirketisin" kutlaması.
- Kapadokya baronu olununca Hezarfen holdingi tanıtır: para çekme, giriş bedeli, holding parasının ülkelere dönmediği.
