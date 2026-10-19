# Swift'e aktarılacaklar

Prototipte yapılıp henüz iOS koduna geçmemiş değişiklikler. Karar verilince toplu olarak aktarılır.

## Filo ve ekip arayüzü (prototip v19)
- **Filo sırası:** Amiral önce, sonra kapasiteye göre büyükten küçüğe, sonra isme göre.
- **Ana ekranda filo:** 4 balona kadar yan yana kartlar. 5 ve üstünde tek özet çubuğu ("Filo: 17/20 balon uçacak · 240 koltuk · 1 onarımda…").
- **Bugünün uçuş planı listesi:** Özet çubuğuna dokununca açılır. Boya göre gruplanır (XL, L, M, S), her grupta "Hepsi / Hiçbiri", üstte "Hepsi uçsun / Hepsi yerde". Uçamayan balonlarda sebep ve ilgili sayfaya kısayol bulunur.
- **Ekip sekmesi:** Boştaki pilotlar en üstte ayrı bölümde, toplam boşa giden maaş uyarısıyla. Görevdeki pilotlar balon büyüklüğüne göre sıralı, onarımdaki balonun pilotunda "(onarımda)" yazar.
- **Pilot ataması (davranış düzeltmesi):** Pilotlar önce uçabilecek balonlara atanır, onarımdaki veya zarfı bitmiş balonlar en sona kalır. Aynı kıdemde tecrübesi (XP) yüksek olan önce gelir. Ekip sekmesinde bu kural bir cümleyle anlatılır. Swift'te `Game.assignPilots()`.
