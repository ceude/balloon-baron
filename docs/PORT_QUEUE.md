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
  - **Pazar cümlesi:** "Bugün X turist var, rakiplerle birlikte gökyüzünde Y koltuk: koltuk fazla, rekabet sert / turist fazla, balonlar kolay dolar."
  - **Sonuç:** büyük "228/272 koltuk dolar" ve tahmini gelir. Gelirin panel açıldığındaki haline göre farkı ▲/▼ ile gösterilir. Altında doluluk çubuğu ve "Tamam".

## Tekel cezası (denge değişikliği)
- Uyarı metninde ceza oranı yazmaz, sadece "Rekabet Kurumu seni izliyor" der. Hezarfen de "şirketinin büyüklüğüne göre ağır bir ceza" der.
- Ceza = max(€5.000, şirket değerinin %3'ü). Şirket değeri: pozitif kasa + balonların alış fiyatı + sahip olunan otellerin alış fiyatı. Kasası boş olana da kesilir (eskiden `cash > 0` şartı vardı).
