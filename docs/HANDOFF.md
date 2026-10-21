# Devir notu (yeni oturum için)

Yeni bir Claude oturumu bu repoyu açınca önce bunu ve `CLAUDE.md`'yi okusun.

## Durum (prototip v76)
- Prototip: `prototype/balloon-baron.html`, oynanabilir ve en güncel tasarım burada.
- Swift uygulaması v67'ye kadar olan her şeyi içeriyor (kasaba, holding butonu, bölüm sonu ekranı, yerinde yakınlaşma, kurucu primi %25, popülerlik tavanı). Mac'te Xcode 15.2 ile derlenip telefonda çalıştırıldı.
- `docs/PORT_QUEUE.md`: prototipte olup Swift'te henüz olmayanlar (v68–v76): sabit ufuk, alt panel şeridi (yukarı çekilir), sağ butonların geri dönüşü, yolcu toplarken ofis önü ve safari cipleri, holding ofis sahnesi, sayfalarda ✕ ve küçük Tamam, bölge değiştirme listesi, bilet kartında "kim uçuracak", rüzgâr kartı sol üstte ve yorumlar altında, rüzgâr direği, yakınken üst çubuğun kalması, ana ekranda doğrudan iki parmakla yakınlaşma.

## Artifact
Eski hesabın artifact'i (`claude.ai/artifact/1mBPBfaqsUMAMPLj5fzwdA`) yeni hesaptan güncellenemez. Yeni oturumda prototip dosyası yeni bir artifact olarak yayınlanmalı ve `CLAUDE.md`'deki adres yenisiyle değiştirilmeli.

## Test
- Çekirdek: `tools/install-swift-linux.sh && export PATH=/opt/swift/usr/bin:$PATH && cd Packages/BalloonBaronCore && swift test`
- Prototip: Playwright ile (`NODE_PATH=$(npm root -g) node test.js`), Chromium hazır.
- Metinler: `python3 tools/strings/build.py` (altı dil, yer tutucu kontrolü).
- Dosya ekleyip çıkarınca: `python3 tools/gen_xcodeproj.py`.
