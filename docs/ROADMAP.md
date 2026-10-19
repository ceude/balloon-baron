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
3. 🟡 **Ofis ekranları:** ana ekran, gün sonu raporu ve Hezarfen hazır. Sırada filo, ekip, banka, pazar sekmeleri, yolcu toplama ekranı, popülerlik grafiği, rakip satış teklifleri.
4. ⬜ **Uçuş sahnesi (SpriteKit):** rüzgâr katmanları, brülör, iniş, peribacaları, görevler, kutlama. Şimdilik yerinde iniş sonucunu seçtiren geçici bir ekran var.
5. ⬜ **Intro ve kurulum:** rüya uçuşu, balon seçimi.
6. ⬜ **Ses:** brülör, ortam, kalabalık, alkış (AVAudioEngine ile sentez).
7. ⬜ **Cilalama:** haptics, Game Center, son ikon, App Store görselleri.
8. ⬜ **TestFlight**, ardından App Store.

## Para kazanma ilkesi
Balon desenleri, reklamsız paket, ödüllü reklam. Parayla güç satın alma yok.

## Bölgeler ve globalleşme (prototipte fazlar halinde)
1. ✅ Bölüm hedefleri, Kapadokya Baronu töreni, dünya haritası önizlemesi.
2. ✅ **Albuquerque bölgesi ve otomatik mod** (prototipte). Kararlar:
   - Giriş bedeli: €100.000.
   - Albuquerque'de tüm tutarlar Kapadokya'dakiyle aynı rakam ama dolar ($15.000'lik balon). Holding kasası euro çalışır, etkisi 1,1'e bölünerek gelir.
   - Eski bölge otomatik moda geçer, nakit getirmeye devam eder. Sorun çıkınca Hezarfen yönlendirir, oyuncu gidip karar verir.
   - Luksor ve diğer bölgeler haritada "Yakında" ve gizemli kalır.
3. ✅ **Balon atölyesi tasarım stüdyosu** (prototipte): kendi desenlerin, yaratıcı tasarımlar popülerlik getirir.
4. ✅ **Holding** (prototipte): ayrı kasalar, holding giderleri, TV reklamı, ünlü reklam yüzü, billboard, zarf Ar-Ge'si, ofisler (New York, İstanbul, Tokyo, Seul; dördü birden açılabilir).

Simülasyonla ölçülen bölüm süreleri (hedef odaklı oynayan oyuncu, 8 deneme): Kuruluş 28–35. gün, Büyüme 68–106. gün, Baron 99–172. gün (çoğunlukla 110–120).
