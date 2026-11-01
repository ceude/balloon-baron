# App Store Connect yükleyici

`asc.py`, mağaza sayfasını App Store Connect API ile doldurur:

- metinler,
- ekran görüntüleri,
- App Preview videoları,
- uygulama içi satın almalar (IAP).

Her şeyi önce okur, sonra yalnızca eksik ya da farklı olanı yazar. İkinci kez çalıştırmak hiçbir şeyi çoğaltmaz. Sürümü incelemeye **göndermez**: "Submit for Review" her zaman senin işin.

## 1. API anahtarı

1. App Store Connect → **Users and Access** (Kullanıcılar ve Erişim) → **Integrations** → **App Store Connect API** → **Team Keys**.
2. İlk kez açıyorsan önce *Request Access*, sonra **+** (Generate API Key):
   - Ad: `balloon-baron-asc`.
   - Rol (Access): **App Manager**.
3. Sayfada iki değer görünür:
   - **Issuer ID**: tablonun üstünde, bütün anahtarlar için aynı.
   - **Key ID**: anahtarın satırında.
4. **Download API Key** ile `AuthKey_XXXXXXXXXX.p8` dosyasını indir. Bu dosya **yalnızca bir kez** indirilebilir. Güvenli bir yerde sakla (ör. `~/.appstoreconnect/`), repoya koyma.

## 2. Ortam değişkenleri

| Değişken | Değer |
|---|---|
| `ASC_KEY_ID` | Key ID (ör. `ABC123DEFG`) |
| `ASC_ISSUER_ID` | Issuer ID (UUID) |
| `ASC_KEY_P8_PATH` | `.p8` dosyasının yolu |
| `ASC_KEY_P8` | ya da dosyanın içeriği (PEM metni). Tek satıra `\n` ile yazılabilir. |

`ASC_KEY_P8` ve `ASC_KEY_P8_PATH` ikisi birden varsa `ASC_KEY_P8` kullanılır.

**Mac'te** `~/.zshrc` dosyasının sonuna ekle, sonra yeni bir Terminal aç:

```sh
export ASC_KEY_ID=ABC123DEFG
export ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000
export ASC_KEY_P8_PATH=~/.appstoreconnect/AuthKey_ABC123DEFG.p8
```

**Bulutta** (Claude Code ortamı): ortam ayarlarındaki *secrets* bölümüne üç değişkeni ekle: `ASC_KEY_ID`, `ASC_ISSUER_ID` ve `ASC_KEY_P8` (dosyanın tüm içeriği). Ağ izinlerine `api.appstoreconnect.apple.com` eklenmeli. Yüklemeler Apple'ın dosya sunucularına da gider; o adresleri `uploadOperations` cevabı söyler.

## 3. Kurulum

Mac'te (Python 3.9 ya da yenisi):

```sh
cd balloon-baron
python3 -m venv .venv-asc
source .venv-asc/bin/activate
pip install -r tools/appstore/asc/requirements.txt
brew install ffmpeg        # videoları kontrol eden ffprobe için
```

Linux'ta aynı adımlar, ffmpeg için `apt install ffmpeg`.

## 4. Komutlar

Her yazan komut üç kipte çalışır:

- `--dry-run`: dosyaları kontrol eder ve yapılacak her isteği gövdesiyle birlikte yazar. Hiçbir şey yazmaz. Anahtar yoksa çevrimdışı çalışır, kimlikler `<APP_ID>` gibi yer tutucu olur. Anahtar varsa mevcut durumu okur, planı ona göre gösterir.
- Bayraksız: ilk yazmadan önce `Continue? [y/N]` diye sorar.
- `--yes`: sormadan yazar.

```sh
A=tools/appstore/asc/asc.py

python3 $A status                                  # salt okunur özet
python3 $A metadata    --langs tr,en --dry-run
python3 $A screenshots --langs tr --dry-run        # ekran görüntüleri + videolar
python3 $A previews    --langs tr --dry-run        # yalnızca videolar
python3 $A iap --dry-run
python3 $A all         --langs tr --dry-run        # metadata → screenshots → previews → iap
python3 $A all         --langs tr --yes            # gerçekten yazar
```

### Ortak seçenekler

- `--langs`: dil listesi. Varsayılan: `tr,en,de,es,ja,ko`.
- `--extra-locales`: `en-GB` ve `es-MX` yerelleştirmelerini de doldurur. Metinler `en` ve `es` ile aynı olur. Kalıcı açmak için `config.json` içinde `useExtraLocales: true`.
- `-v`: her isteği günlüğe yazar.
- `--root`: dosyaların okunacağı repo. Varsayılan: bu repo.

### status

Uygulamayı paket kimliğiyle (`com.ceude.balloonbaron`) bulur ve şunları listeler:

- sürümler ve durumları,
- düzenlenebilir sürümün yerelleştirmeleri,
- her dildeki ekran görüntüsü ve video setleri,
- uygulama adı ve alt başlıklar,
- IAP'ler (kimlik, productId, durum),
- `iap.json`'da olup App Store Connect'te henüz olmayanlar.

### metadata

Düzenlenebilir sürüm (ör. 1.0, *Prepare for Submission*) için iki şeyi oluşturur ya da günceller:

- **appStoreVersionLocalizations**: açıklama, anahtar kelimeler, tanıtım metni, `supportUrl`, `marketingUrl`.
- **appInfoLocalizations**: ad, alt başlık, `privacyPolicyUrl`.

Yalnızca değişen alanlar PATCH edilir.

Dil kodları şöyle eşlenir:

| Bizim kod | App Store Connect yerelleştirmesi |
|---|---|
| tr | tr |
| en | en-US (+ en-GB) |
| de | de-DE |
| es | es-ES (+ es-MX) |
| ja | ja |
| ko | ko |

Parantezdekiler yalnızca `--extra-locales` ile doldurulur.

Metinler `marketing/appstore/<dil>-v2/metadata-<dil>.md` dosyasından okunur. Dosyası olmayan dil "missing" olarak raporlanır, atlanır.

Adresler `config.json` → `urls` bölümünden gelir. `null` olan adres yazılmaz.

### Metadata blok biçimi (kesin biçim)

Md dosyasında her alan kendi kod bloğundadır. Bloğun bilgi satırı `asc:<alan>` olur:

````md
```asc:name
Balon Baronu: Kapadokya
```

```asc:subtitle
Sıcak Hava Balonu Tycoon Oyunu
```

```asc:keywords
idle,işletme,simülasyon,strateji
```

```asc:promotionalText
Peri bacalarının üstünde şafak sökerken tek bir sepetle başla.
```

```asc:description
İlk paragraf.

BÜYÜK HARFLİ BAŞLIK
• madde
```
````

Kurallar:

- Alanlar: `name`, `subtitle`, `keywords`, `promotionalText`, `description`.
- İsteğe bağlı alanlar: `supportUrl`, `marketingUrl`, `privacyPolicyUrl`. Bunlar `config.json`'daki adresi o dil için ezer.
- Tek satırlık alanlarda tam bir dolu satır olmalı. `description` olduğu gibi alınır, satır sonları korunur.
- Bir alan iki kez yazılamaz. Bilinmeyen alan adı ya da kapanmamış blok hata verir.
- Sınırlar:
  - ad ve alt başlık: 30,
  - anahtar kelimeler: 100,
  - tanıtım metni: 170,
  - açıklama: 4000 karakter.
- Sınır aşılırsa hiçbir istek gönderilmez.
- Uyarılar:
  - anahtar kelimelerde boşluk,
  - tekrar eden kelime,
  - ad ya da alt başlıkta zaten geçen kelime.

Md'de hiç `asc:` bloğu yoksa araç eski tr-v2 taslağının düzenini okur ve uyarı verir. Eski düzen:

- "Önerilen ad ve alt başlık" tablosundaki *Ad*, *Alt başlık* ve *Anahtar kelimeler* satırları,
- `## Tanıtım metni` altındaki alıntı,
- `## Açıklama` altındaki ilk kod bloğu.

Türkçe yerelleştirmedeki ad ("Balon Baronu: Kapadokya") bu md'den gelir. Birincil dil en-US'nin adı "Balloon Baron: Cappadocia" kalır.

### screenshots / previews

**Ekran görüntüleri**

| Klasör | App Store Connect tipi | Kabul edilen boyutlar |
|---|---|---|
| `iphone/*.png` | `APP_IPHONE_67` (6,9"/6,7" yuvası) | 1320×2868 ya da 1290×2796 |
| `ipad/*.png` | `APP_IPAD_PRO_3GEN_129` (13"/12,9") | 2064×2752 ya da 2048×2732 |

Kontroller:

- Boyut,
- saydamlık (alfa kanalı) olmaması,
- en çok 10 dosya.

Sıra dosya adına göredir: 01 … 10.

Bir setteki dosyaların hepsi aynıysa (MD5 ile karşılaştırılır) hiçbir şey yapılmaz. Dosyalar aynı ama sıra farklıysa yalnızca sıra düzeltilir. Başka bir fark varsa:

1. setteki eski görüntüler silinir,
2. yenileri yüklenir:
   - `fileName` ve `fileSize` ile rezervasyon yapılır,
   - Apple'ın verdiği her `uploadOperation` parçası kendi adresine ve başlıklarıyla gönderilir,
   - `uploaded=true` ve `sourceFileChecksum` (MD5) ile onaylanır,
   - `assetDeliveryState` COMPLETE olana kadar beklenir,
3. sıra 01…10 olarak ayarlanır.

**App Preview videoları**

| Dosya | Tip | Boyut |
|---|---|---|
| `preview/iphone.mp4` | `IPHONE_67` | 886×1920 |
| `preview/ipad.mp4` | `IPAD_PRO_3GEN_129` | 1200×1600 |

`ffprobe` ile kontrol edilenler:

- süre 15–30 sn,
- en çok 30 fps,
- H.264 ya da ProRes,
- stereo ses,
- en çok 500 MB.

Kapak karesi `config.json` → `previewFrameTimeCode` alanından gelir. Varsayılan `00:00:05:00` (5. saniye).

Apple videoyu bir süre işler. Bu süre uzarsa araç bunu hata değil uyarı olarak raporlar; sonucu `status` ile kontrol edebilirsin.

`metadata` önce çalışmalı, çünkü ekran görüntüleri dilin sürüm yerelleştirmesine bağlanır. `all` bunu kendisi sıraya koyar.

### iap

`iap.json` içindeki 15 ürünü tamamlar. Ürünler `StoreKit/BalloonBaron.storekit` ile birebir aynıdır; araç her çalıştığında fiyatları ve kimlikleri karşılaştırır.

Her ürün için yapılanlar:

1. Ürün yoksa `/v2/inAppPurchases` ile **NON_CONSUMABLE** olarak oluşturulur:
   - referans adı,
   - `familySharable=false`,
   - inceleme notu.
2. Altı dilde ad (≤30) ve açıklama (≤45) eklenir. Adlar oyundaki adlardır (`tools/strings`, `store.<ürün>` anahtarı).
3. **Fiyat:** taban ülke `config.json` → `iap.baseTerritory` (varsayılan `DEU`, Almanya, EUR). O ülkenin fiyat noktaları arasında .storekit'teki euro fiyatı (0,99 / 1,99 / 4,99 / 6,99 / 9,99) aranır ve fiyat programı kurulur. Diğer ülkelerin fiyatını Apple eşitler. Komut satırından değiştirmek için `--base-territory TUR`.
4. **Satış bölgeleri:** bütün ülkeler, yeni ülkeler de otomatik.
5. **İnceleme ekran görüntüsü:** `review/<ürün>.png`. Ürünün çarşıdaki satın alma kartını gösterir.

Elle oluşturduğun ürünler bozulmaz. Varsayılan davranış **yalnızca eksikleri doldurmaktır**: farklı bir ad, fiyat ya da ekran görüntüsü varsa araç uyarır ama dokunmaz. Hepsini `iap.json`'a eşitlemek için `--overwrite` kullan.

İncelemedeki (`WAITING_FOR_REVIEW`, `IN_REVIEW`) ürünlere hiç dokunulmaz.

### İnceleme ekran görüntülerini yeniden üretmek

```sh
NODE_PATH=$(npm root -g) node tools/appstore/asc/review/render.js /tmp/review-raw
python3 tools/appstore/asc/review/compress.py /tmp/review-raw tools/appstore/asc/review
```

Görüntüler HTML prototipinden 1290×2796 boyutunda alınır ve 256 renge sıkıştırılır. Prototipin "gerçek ödeme yok" notu kaldırılır.

İstersen bunların yerine uygulamanın simülatörde açılmış çarşı kartını koyabilirsin: aynı dosya adı, PNG, saydamlık yok.

## 5. Testler

```sh
python3 -m unittest discover -s tools/appstore/asc/tests -v
```

Testler çevrimdışıdır, Apple'a hiçbir istek göndermez. Kapsadıkları:

- md biçimi ve sınırlar,
- PNG başlığı, MD5 ve yükleme parçaları,
- JWT (ES256, `aud appstoreconnect-v1`, 20 dakika). Test için o an üretilen bir anahtar kullanılır.
- 429/5xx'te bekleyip yeniden deneme, 401'de jetonu yenileme, sayfalama,
- tekrar çalıştırınca bir şeyin çoğalmaması,
- `iap.json` ile `.storekit` ve oyundaki adların uyuşması.

## 6. Senin karar vermen gerekenler

`config.json` içinde:

- `urls.supportUrl`: zorunlu, destek adresi.
- `urls.privacyPolicyUrl`: zorunlu, gizlilik politikası adresi. Öneri: GitHub Pages'te `docs/privacy-policy.html`.
- `urls.marketingUrl`: isteğe bağlı.
- `iap.baseTerritory`: hesabın taban ülkesi. Euro fiyatları için `DEU`; Türkiye tabanlı fiyat istersen `TUR`, ama o zaman fiyatlar TL fiyat noktalarına göre aranır ve `iap.json` fiyatları ona göre değişmeli.
- `useExtraLocales`: en-GB ve es-MX de doldurulsun mu?
