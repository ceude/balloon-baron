# Devir notu (yeni oturum için)

Yeni bir Claude oturumu bu repoyu açınca önce bunu ve `CLAUDE.md`'yi okusun.

## Durum (prototip v85)
- Prototip: `prototype/balloon-baron.html`, oynanabilir ve en güncel tasarım burada.
- Swift uygulaması v67'ye kadar olan her şeyi içeriyor. Mac'te Xcode 15.2 ile derlenip telefonda çalıştırıldı.
- `docs/PORT_QUEUE.md`: prototipte olup Swift'te henüz olmayanlar (v68–v85): telefon testi düzeltmeleri, tasarım incelemesi (gazete, rakip patronlar, sabah olayları, bina yükseltmeleri, pilot özellikleri, başarımlar, uçuş anları, festivaller, kurtarma planı), mağaza ve Çarşı (özel desenler, şekilli balonlar, süsler, ödüllü reklam), gece döngüsü ve gece olayları.
- `docs/GAME_DESIGN.md` güncel sayıları içeriyor.

## Artifact
Eski hesabın artifact'i (`claude.ai/artifact/1mBPBfaqsUMAMPLj5fzwdA`) yeni hesaptan güncellenemez. Yeni oturumda prototip dosyası yeni bir artifact olarak yayınlanmalı ve `CLAUDE.md`'deki adres yenisiyle değiştirilmeli.

## Test
- Çekirdek: `tools/install-swift-linux.sh && export PATH=/opt/swift/usr/bin:$PATH && cd Packages/BalloonBaronCore && swift test`
- Prototip: Playwright ile (`NODE_PATH=$(npm root -g) node test.js`), Chromium hazır.
- Metinler: `python3 tools/strings/build.py` (altı dil, yer tutucu kontrolü).
- Dosya ekleyip çıkarınca: `python3 tools/gen_xcodeproj.py`.
