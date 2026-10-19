# Balloon Baron: Cappadocia

Kapadokya'da sıcak hava balonu şirketi kurup büyüttüğün bir tycoon oyunu. Uçuşları kendin yapıyorsun (beceri), şirketi de sen yönetiyorsun (strateji).

- **Hedef:** iOS App Store, global kitle
- **Diller:** İngilizce, Türkçe, Almanca, İspanyolca, Japonca, Korece. Yeni dil eklemeye hazır.
- **Teknoloji:** Swift, SwiftUI (menüler), SpriteKit (uçuş sahnesi). En az iOS 17.
- **Ekip:** tek geliştirici + Claude. Görseller ve sesler kodla üretiliyor.

## Mac'te ilk açılış
1. `git clone https://github.com/ceude/balloon-baron.git`
2. `BalloonBaron.xcodeproj` dosyasını Xcode 16 veya üstüyle aç.
3. Sol üstte **BalloonBaron** hedefini ve bir iPhone simülatörünü seç, ▶︎ ile çalıştır.
4. Gerçek iPhone'da denemek için: proje ayarlarında *Signing & Capabilities* altında kendi Apple ID ekibini seç.

Dili değiştirmek için: Xcode'da *Product › Scheme › Edit Scheme › Run › Options › App Language*.

## Klasörler

| Yol | İçerik |
|---|---|
| `BalloonBaron/` | iOS uygulaması: ekranlar, tema, fontlar, ikon, `Localizable.xcstrings` (tüm metinler, 6 dil) |
| `Packages/BalloonBaronCore/` | Oyunun beyni: ekonomi, pazar, rakipler, hava, kayıt. Testleri var. |
| `prototype/balloon-baron.html` | Oynanabilir HTML prototip; davranış ve denge için referans |
| `prototype/archive/` | Eski prototip sürümleri (v1–v17) ve elenen Derinkuyu fikri |
| `promo/` | Tanıtım PDF'i, kaynağı ve ekran görüntüleri |
| `docs/GAME_DESIGN.md` | Tüm mekanikler ve sayılar |
| `docs/ROADMAP.md` | iOS'a geçiş planı ve ilerleme |
| `tools/` | Bulut oturumları için yardımcı betikler |

## Testler
Mac'te Xcode'da `Packages/BalloonBaronCore` paketini açıp ⌘U, ya da terminalde:
```
cd Packages/BalloonBaronCore && swift test
```

## Canlı prototip
https://claude.ai/artifact/1mBPBfaqsUMAMPLj5fzwdA
