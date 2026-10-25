# Devir notu (yeni oturum için)

Yeni bir Claude oturumu bu repoyu açınca önce bunu ve `CLAUDE.md`'yi okusun.

## Durum (prototip v109.4, Swift v109.4)
- Prototip: `prototype/balloon-baron.html`, oynanabilir ve en güncel tasarım burada.
- Swift uygulaması prototip v85'e kadar her şeyi içeriyor (Ekim 2026 aktarımı). Neyin bilerek sade bırakıldığı `docs/PORT_QUEUE.md` sonunda yazıyor (gerçek ödeme, reklam SDK'sı, kartpostal sahneleri vb.).
- `docs/PORT_QUEUE.md` boş: yeni tasarım değişiklikleri prototipte yapılınca buraya yazılır.
- `docs/GAME_DESIGN.md` güncel sayıları içeriyor.

## Artifact
Prototip yeni hesapta `claude.ai/artifact/9LyVDNN1dngsGGydyFuNYt` adresinde (v109.4). Eski hesabın artifact'i (`claude.ai/artifact/1mBPBfaqsUMAMPLj5fzwdA`) artık güncellenmiyor.

## Test
- **GitHub Actions (`.github/workflows/ci.yml`):** `main`'e her gönderide çekirdek testleri Swift 5.9 ile çalışır ve uygulamanın tamamı macOS'ta Xcode 15.2 (15C500b) ile simülatör için derlenir. Sonuç, hatalar ve uyarılar çalışmanın özet sayfasında yazar (Actions sekmesi). Geliştiricinin Mac'iyle aynı Xcode olduğu için burada derlenen Mac'te de derlenir.
- Çekirdek (yerelde): `tools/install-swift-linux.sh && export PATH=/opt/swift/usr/bin:$PATH && cd Packages/BalloonBaronCore && swift test`
- Prototip: Playwright ile (`NODE_PATH=$(npm root -g) node test.js`), Chromium hazır.
- Metinler: `python3 tools/strings/build.py` (altı dil, yer tutucu kontrolü). Windows'ta da çalışır.
- Dosya ekleyip çıkarınca: `python3 tools/gen_xcodeproj.py` (Windows'ta da aynı çıktıyı verir).
