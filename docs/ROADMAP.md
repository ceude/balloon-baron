# iOS Yol Haritası

## Çalışma düzeni
- **Bulutta (Claude Code web/mobil):** Swift kodu yazılır, oyun mantığı Linux'ta derlenip test edilir, repoya gönderilir.
- **Mac'te (Xcode):** repo çekilir, derlenir, simülatörde ve iPhone'da denenir. Hatalar Claude'a bildirilir.

## Diller
Çıkışta: İngilizce (kaynak), Türkçe, Almanca, İspanyolca, Japonca, Korece.
Sonra eklenebilir: Rusça, Çince, Portekizce.

## Aşamalar
1. ✅ **İskelet:** Xcode projesi, String Catalog (6 dil), tema, Barlow fontları, geçici uygulama ikonu.
2. ✅ **Çekirdek model:** `GameState` (kayıt), ekonomi, pazar, rakipler, hava, görevler, oteller, kış, tekel cezası, yorumlar. Birim testli, 80 günlük simülasyonla dengesi kontrol edildi.
3. 🟡 **Ofis ekranları:** ana ekran (tek uyarı, filo çubuğu, fiyat paneli, uçuş planı), gün sonu raporu, Hezarfen, filo, tasarım stüdyosu, ekip, pazar, hedefler ve bölüm töreni, holding, dünya haritası, bölge sorunları hazır (Mac'te derlenip denenecek). Sırada banka sekmesi, yolcu toplama ekranı, popülerlik grafiği.
4. 🟡 **Uçuş sahnesi:** prototipten SwiftUI Canvas'a port edildi (rüzgâr katmanları, brülör, iniş, peribacaları, görevler, evlilik teklifi kutlaması, yolcu toplama). Uçuş fiziği çekirdekte, testli. Mac'te denenecek.
5. 🟡 **Intro ve kurulum:** rüya uçuşu, isim önerileri, gökyüzünden balon seçimi, ana ekranın arkasında canlı sabah sahnesi. Mac'te denenecek.
6. 🟡 **Ses:** brülör, ortam ve kuşlar, kalabalık, alkış, fanfar, tık sesleri AVAudioEngine ile koddan sentezleniyor. Mac'te denenecek.
7. ⬜ **Cilalama:** haptics, Game Center, son ikon, App Store görselleri.
8. ⬜ **TestFlight**, ardından App Store.

## Para kazanma ilkesi
Balon desenleri, reklamsız paket, ödüllü reklam. Parayla güç satın alma yok.

## Bölgeler ve globalleşme (prototipte fazlar halinde, Swift'e aktarıldı)
1. ✅ Bölüm hedefleri, Kapadokya Baronu töreni, dünya haritası önizlemesi.
2. ✅ **Albuquerque bölgesi ve otomatik mod** (prototipte). Kararlar:
   - Giriş bedeli: €100.000.
   - Albuquerque'de tüm tutarlar Kapadokya'dakiyle aynı rakam ama dolar ($15.000'lik balon). Holding kasası euro çalışır, etkisi 1,1'e bölünerek gelir.
   - Eski bölge otomatik moda geçer, nakit getirmeye devam eder. Sorun çıkınca Hezarfen yönlendirir, oyuncu gidip karar verir.
   - Luksor ve diğer bölgeler haritada "Yakında" ve gizemli kalır.
3. ✅ **Balon atölyesi tasarım stüdyosu** (prototipte): kendi desenlerin, yaratıcı tasarımlar popülerlik getirir.
4. ✅ **Holding** (prototipte): ayrı kasalar, holding giderleri, TV reklamı, ünlü reklam yüzü, billboard, zarf Ar-Ge'si, ofisler (New York, İstanbul, Tokyo, Seul; dördü birden açılabilir).

Simülasyonla ölçülen bölüm süreleri (hedef odaklı oynayan oyuncu, 8 deneme): Kuruluş 28–35. gün, Büyüme 68–106. gün, Baron 99–172. gün (çoğunlukla 110–120).
