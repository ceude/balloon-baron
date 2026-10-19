# iOS Yol Haritası

## Çalışma düzeni
- **Bulutta (Claude Code web/mobil):** Swift kodu yazılır ve bu repoya push edilir. Mac gerekmez.
- **Mac'te (Xcode):** repo çekilir, derlenir, simülatörde ve iPhone'da denenir. Hatalar Claude'a geri bildirilir.

## Aşamalar
1. **İskelet:** Xcode projesi (SwiftUI App ve SpriteKit `SKView`), String Catalog (`Localizable.xcstrings`, tr + en), tasarım tokenları (renkler, Barlow fontları).
2. **Çekirdek model:** `GameState` (Codable, kayıt/geri yükleme ve göç), ekonomi, pazar (`allocate`), rakipler, hava durumu. Saf Swift, birim testli.
3. **Uçuş sahnesi:** SpriteKit'te rüzgâr katmanları, brülör, iniş, peribacaları, görevler, kutlama.
4. **Menüler:** ana ekran, filo, ekip, banka, pazar, rapor (bilet tasarımı), Hezarfen Usta diyalogları, popülerlik grafiği.
5. **Ses:** brülör, ortam, kalabalık, alkış (AVAudioEngine ile sentez).
6. **Cilalama:** intro, kurulum ekranı, haptics, Game Center.
7. **TestFlight**, ardından App Store.

## Para kazanma ilkesi
Balon desenleri, reklamsız paket, ödüllü reklam. Parayla güç satın alma yok.
