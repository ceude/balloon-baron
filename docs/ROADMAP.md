# Yol haritası

28 Ekim 2026. TestFlight'taki yeni oyuncuların (Senem, Atakan) yorumlarına ve iki yeni oyuncu incelemesine (prototipte 26 günlük oynanış, Swift kod denetimi) göre. Her faz önce prototipte yapılır, sonra "aktar" ile Swift'e geçer. TestFlight'a yalnızca Uraz "gönder" deyince gidilir.

## Faz 1: Gösteren öğretici (en önemli)

**Sorun:** Oyun öğretiyor ama yazıyla. Yeni oyuncular Hezarfen'in balonlarını okumuyor ("hiçbir oyunda okumuyorum"), ileri nasıl gidileceğini geç anlıyor. Şunları bilmediler:
- Valfin sıcak havayı bırakıp balonu **indirdiği**; Senem ileri götürdüğünü sandı.
- Peribacalarına sepetle **çarpılabildiği**: bacalar arka planla birleşik görünüyor.
- Termiğin ne yaptığı: Atakan kafası karıştı, yukarı çıkaracağını sandı ama etkisini fark etmedi.

**İlke:** anlatma, göster. Ekran kararır, tek bir öğe aydınlık kalır, ok ve en fazla bir kısa cümle görünür, oyuncu o öğeyi kullanınca sonraki adıma geçilir. Hezarfen konuşur ama metin bir satırı geçmez.

1. **İlk uçuş, adım adım (spotlight).**
   1. Brülör: "Basılı tut: yükselirsin." Balonun yanında yukarı ok.
   2. Rüzgâr katmanları: "İleri gitmek için doğru yükseklik." Soldaki oklar sırayla yanar, hedefe doğru esen katman vurgulanır.
   3. Valf: "Sıcak havayı bırakır: alçalırsın. İleri götürmez." Aşağı ok.
   4. İniş alanı: kamera hedefe kayar, "Burada in."
   5. Peribacaları: kamera ilk uçuşta engelleri tek tek gösterir, kırmızı kontur ve "Sepet çarparsa kaza" etiketi.
   6. Termik: ilk göründüğünde "Termik: içine girersen seni yukarı taşır" etiketi, girince yukarı ok animasyonu.
2. **Engeller her zaman ayırt edilsin:** peribacaları ön planda daha koyu ve kontrastlı çizilir, sepet yaklaşınca baca kırmızı parlar. Arka plandaki süs bacalarıyla çarpılan bacalar aynı görünmemeli.
3. **Termik görünür etkili olsun:** içindeyken balonun altında yukarı oklar ve küçük "Termik ↑" etiketi. Kaldırma gücü gözle fark edilecek kadar (şimdi `vy += .5`, denenip ayarlanacak).
4. **Ana ekran, ilk gün:** "Yolcu topla" düğmesi nabızla parlar ve ok gösterir. Bilet kartı ve dock birer kez vurgulanır.
5. **Yeni bina açılınca:** kamera binaya kayar, bina nabızla parlar, ok gösterir; Hezarfen tek cümle söyler. "Kasabada bul ve dokun" metninin yerine geçer.
6. **Hezarfen metinlerini kısaltmak:** ilk 11 günün derslerini tek cümleye indirmek, ayrıntıyı "Daha fazla" altına almak.
7. **Ölçmek:** TelemetryDeck'te öğretici adımlarının tamamlanma oranı ve ilk 3 günde bırakanlar.

## Faz 2: Yeni oyuncu incelemesinden kalanlar

- **Dokunma alanları:** en az 44 pt. "Bu balonu ben uçurayım / Pilota ver" (~22 pt), HUD çipleri, menü ve ✕ düğmeleri, plan düğmeleri, açılıştaki "Geç ›".
- **Kasa eksi (Swift):** kalıcı uyarı, dokununca kurtarma kartı; 1–3. günlerde en az bir seçenek açık olsun.
- **Sarı bayrak sigortası:** kart kapalıyken de bugünkü sigorta tutarı görünsün.
- **9. gün çarşı ipucu:** "Şimdi değil" seçeneği.
- **Küçük hatalar:**
  - Hedef listesinde "yok" yerine "0/1", popülerlik çubuğu 1★'dan ölçekli.
  - Para yetmeyince "şu kadar eksik" yazsın.
  - "Hedef" etiketi rozetin altında kalmasın.
  - Uzun şirket adı film başlığında kesilmesin.
  - "SATILIK" tabelası tam görünsün.
  - Gazetenin büyük ilk harfi kısa metinde boşluk açmasın.
  - Otel kartlarına resim.
- **Sigorta ipucu:** düğmelerin yerini göstersin (Faz 1'in spotlight'ıyla).
- **Rüya uçuşu girişi:** geri dönen oyuncu atlayabilsin.
- **Denge kararları (Uraz'ın):**
  - Peribacası koridoru: hedefin çevresindeki güvenli alan genişlesin mi?
  - Kasa küçükken 60–75 bin €'luk duyurular ertelensin mi?

## Faz 3: Swift'e aktarılacaklar

`docs/PORT_QUEUE.md`: devralmada ve iflas filosunda pilotlar sözleşmeleriyle gelir (v121.13).

## Faz 4: Mağaza ve App Store (Uraz'ın hesabında)

- App Store Connect'te eksik ürünler:
  - `founder`
  - desenler: `gold`, `tile`, `sky`, `kilim`
  - şekiller: `heart`, `star`, `skull`
  - süsler: `fountain`, `statue`, `flags`
  - paketler: `decorpack`, `figurepack`
- Her ürün için inceleme ekran görüntüsü.
- Mağaza görselleri: iPad seti ve de, es, ja, ko setleri (`tools/appstore/panorama.js`).

## Faz 5: iPhone Duo

Açık ekranda tam ekran oyun: sağdaki düğmeler kendi çizdiğimiz dikey bir şeritte, kasaba ortada. Xcode 27.1 gerektiriyor; geliştirici Mac'i Xcode 15.2'de. Karar: derlemeyi Xcode Cloud'da 27.1 ile yapmak mı, yeni Mac mi.

## Test edenlere sorulacaklar

- Hangi anda "ne yapacağımı bilmiyorum" dedin?
- İlk uçuşta brülör, valf ve rüzgârın ne yaptığını kendi sözlerinle anlatır mısın?
- Kaçıncı günde bıraktın ya da sıkıldın?
