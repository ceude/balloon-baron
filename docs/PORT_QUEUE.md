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
- Bölüm gün sonunda tamamlanınca ödül kasaya girer ve uçuş defterinde "Bölüm ödülü: X" satırı çıkar. Ertesi sabah tören penceresi açılır (diğer pencerelerden önce).
- Yan menüde en üstte "Hedef" butonu, üstünde "1/4" rozetiyle. Hedef kartında her hedefin ilerleme çubuğu ve sayısı var (evet/hayır hedeflerinde "tamam / yok"). Baron olunca buton "Dünya" olur.
- **Baron töreni:** taç, Hezarfen'in sözleri, fanfar ve alkış, "Dünya haritasını aç".
- **Dünya haritası:** Gerçek koordinatlardan çizilmiş kıtalar, boylam −130…130, enlem 70…−40 kırpılmış. Kapadokya (Baron), Albuquerque (Baron olunca "Açıldı"), Luksor ve iki gizemli "???" bölge (Asya, Avrupa; Yakında).
- Hezarfen'in yeni "goals" dersi 2. gün çıkar.
- Yeni gelen rakip seçilirken, yaşayan ya da satıştaki şirketlerin adında geçen markalar (ör. birleşmiş "X & Bosphorus") dışarıda tutulur.
- **Lisans tuzağı uyarısı:** Lisans düşmüşken amiral balon uçamıyorsa (zarf eskimiş ya da onarımda), uyarı çıkış yolunu söyler: zarfı yenile, başka balonu amiral yap ya da ücreti öde.
