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
