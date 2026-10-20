# Swift'e aktarılacaklar

Prototipte yapılıp henüz iOS koduna geçmemiş değişiklikler. Karar verilince toplu olarak aktarılır.

## Bölüm sonu ekranı (v66)
- Bölüm bitince gelen kartta artık biten bölümün hedefleri görünür: hepsi tamamlandı işaretli, çubuklar dolu. Değer o arada hedefin altına düştüyse (ör. kasa harcandı) sağda "Tamamlandı" yazar.
- "Devam"a basınca ikinci kart açılır: "Kapadokya · Bölüm 2/3", yeni bölümün adı ve hedefleri (ilerlemeleriyle), "Başla" butonu. Baron töreni değişmedi.

## Kasabaya yakınlaşma ana ekranın içinde (v66)
- Ayrı "Şirketim" sayfası kalktı (başlık ve ipucu yazısı yok). Ana ekrandaki kasabaya dokununca aynı görüntüden başlayarak oraya yakınlaşılır, ekrandaki her şey (üst çubuk, rüzgâr kartı, Hedef, alt kartlar) 0,25 sn'de solar. Bölge yazısına dokununca o bölgeye, boş zemine dokununca dokunulan noktaya yakınlaşır (zoom 0,65, 0,45 sn). Binaya dokunmak eskisi gibi binayı açar. Masaüstünde ana ekranda tekerleği yukarı çevirmek de yakınlaştırır.
- Yakınken kaydırma ve iki parmakla yakınlaştırma çalışır. Ana ekrandaki büyüklüğe kadar uzaklaşınca kendiliğinden ana ekrana döner: görüntü ana ekrandaki kasabaya kayar, ekrandaki nesneler geri gelir. En küçük zoom ana ekranın zoom'u.
- Yakınken sağ üstte yuvarlak beyaz X durur. Basınca otomatik tam uzaklaşır ve X kaybolur.

Son toplu aktarım (prototip v64'e kadar): kurucu primi %25 ve popülerlik tavanı (4,2★, influencer ile 4,5★), Hezarfen'in `pr`, `influ`, `prcap` dersleri, Şirketim kasabası (`BalloonBaron/Town/`: izometrik çizim, dört otel, gündoğumu, uzak balonlar, kuma yazılı bölgeler, tam ekran görünüm ve ana ekrandaki kasaba), Hedef ve Holding butonları, bölge uyarı noktaları.

Bir önceki toplu aktarım: filo/ekip arayüzü, sade ana ekran ve fiyat paneli, tekel cezası, pazar kartları, güçlü rakipler ve birleşmeler, bölümler ve Baron, Albuquerque ve otomatik mod, tasarım stüdyosu, holding ve ofisler.

Aktarımda bilerek eksik kalanlar (ileride):
- (yok)
