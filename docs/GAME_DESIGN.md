# Balloon Baron: Cappadocia — Oyun Tasarımı

Bu belge `prototype/balloon-baron.html` içindeki güncel mekanikleri ve sayıları özetler. Swift portu bu sayıları referans alır. Para birimi €.

## Günlük döngü
1. **Sabah:** hava bayrağı (yeşil/sarı/kırmızı), fiyat, uçacak balonlar, kendin uçmak.
2. **Yolcu toplama:** zamanlayıcılı ekran. Yolcular kaynaklarına göre gelir (otel, rehber, influencer, pazar, tavsiye).
3. **Uçuş (SpriteKit):** brülörle ısı kontrolü, 4 rüzgâr katmanı (0–60, 60–180, 180–350, 350–650 m), hedef alana yumuşak iniş. Dikey hız > 2,6 ise sert iniş. Peribacasına çarpmak kaza sayılır. İptal edilirse kişi başı €40 tazminat ödenir.
4. **Gün sonu:** bilet tasarımlı uçuş defteri (gelir, giderler, olaylar, görev ödülü).
5. **Yönetim:** Filo, Ekip, Banka, Pazar sekmeleri.

## Başlangıç
Kasa €3.000, fiyat €170, popülerlik 1,0, temel talep 165 turist/gün. Sigorta ilk günden açık. Kurulumda şirket adı ve balon rengi seçilir (10 palet).

## Balonlar
| Boy | Kapasite | Fiyat | Yakıt/uçuş | Bakım | Risk |
|---|---|---|---|---|---|
| S Küçük | 8 | 15.000 | 60 | 40 | ×0,8 |
| M Orta | 16 | 35.000 | 90 | 60 | ×1,0 |
| L Büyük | 24 | 60.000 | 120 | 80 | ×1,3 |
| XL Kapadokya Yıldızı | 32 | 150.000 | 170 | 140 | ×1,15 |

- XL özel tasarım dev balondur. Her uçuş +0,005 popülerlik verir.
- Ömür 120 uçuş. Yenileme fiyatın %35'i.

## Kurucu (sen)
- **Lisans:** En az 15 günde bir kendin uçmalısın. Lisans düşerse amiral dışındaki tüm balonlar yerde kalır. Ya amirali kendin uçurursun (ücretsiz yenileme uçuşu) ya da €15.000 ödersin.
- **Kurucu uçuşu primi:** Amiral balonunu sen uçurursan o balonun yolcuları %30 fazla öder.
- **Kurucu yokluğu:** 5 günden uzun süre kendin uçmazsan, balon uçan her gün popülerlik −0,008 (yaklaşık −0,03★) düşer. Hezarfen uyarır, yolcular yorumlarda kurucuyu sorar.

## Pilotlar
| Seviye | Maaş/gün | Kaza riski |
|---|---|---|
| Çaylak | 90 | ×1,6 |
| Deneyimli | 150 | ×1,0 |
| Kıdemli | 240 | ×0,6 |

- XP eşikleri 0 / 40 / 100.
- Rakipler pilot ayartabilir (günlük %4 şans).
- Pilot okulu €60.000'a kurulur.

## Hava
| Bayrak | Kaza olasılığı | Not |
|---|---|---|
| Yeşil | 0,006 | Normal uçuş |
| Sarı | 0,03 | Risk yüksek |
| Kırmızı | 0,14 | Uçuş yasak. %35 yakalanma, €5.000 ceza, 3 uyarıda 3 gün yasak. Sigorta geçersiz. |

## Sigorta (balon başına, günlük)
- Gövde: max(değerin %0,1'i, p × değer × 0,21 × 1,3)
- Yolcu: max(kapasite × 2, p × kapasite × 1500 × 1,3)

Burada p, balonun kaza olasılığıdır (hava × boy × pilot).

## Krediler
| Tutar | Vade | Taksit/gün | Gereken balon |
|---|---|---|---|
| 10.000 | 40 gün | 300 | 0 |
| 25.000 | 45 gün | 650 | 2 |
| 50.000 | 50 gün | 1.250 | 3 |

Kasa −€5.000'in altına düşerse banka balona el koyar.

## Pazar ve popülerlik
- **Fiyat:** €40–320 arası.
- **Fiyat isteği:** `willing(p) = 1 / (1 + exp((p − 230) / 30))`
- **Çekicilik:** `rep² × (190 / p)^1.5 × koltuk`. Büyük şirket daha görünür. Popülerlik < 0,5 ise ×0,35 (kriz).
- **Popülerlik bonusu:** Rakiplerden bağımsız gelen yolcu, koltuklarının en fazla %50'si (2,8★'da 0, 5★'da %50), fiyat isteğiyle çarpılır.
- **Başlangıç baskısı:** 1. gün tek küçük balonla €170'te 7/8 dolar, dolması için yaklaşık €155'e inmek gerekir.
- **Dağıtım sırası:** önce sözleşmeli kaynaklar (otel, rehber, influencer), sonra pazar, en son popülerlik bonusu. Boş koltuğu olanlara taşma havuzu dağıtılır.
- **Yıldız:** `clamp(3 + (rep − 0,75) × 4, 1, 5)`. Popülerlik 0,4–1,4 arasında tutulur.
- **4,5★ üstü:**
  - Günde −0,006 popülerlik.
  - İyi iniş popülerlik getirmez.
  - Uzak iniş iki kat kaybettirir.
  - Hezarfen bu konuda uyarır.
- **Rehber:** €1.500. Popülerlik artırır (+0,2★ civarı).
- **Influencer:** 2.500 + 400 × balon sayısı.

## Reklam sponsorları (uçuş başına, × (kapasite/8)^0,6)
| Sponsor | En küçük boy | Ödeme |
|---|---|---|
| Halı | S | 30 |
| Şarap | M | 55 |
| Banka | M | 90 |
| Enerji | L | 150 |

## Oteller
| Otel | Min ★ | Ücret/gün | Popülerlik | Misafir | Fiyat merkezi | Satın alma | Günlük gelir |
|---|---|---|---|---|---|---|---|
| Taş Otel | 2,0 | 60 | +0,005 | 4 | 200 | 40.000 | 350 |
| Konak | 3,0 | 120 | +0,0075 | 7 | 240 | 110.000 | 900 |
| Mağara Otel | 3,8 | 220 | +0,01 | 12 | 290 | 240.000 | 2.000 |
| Saray | 4,4 | 380 | +0,0125 | 18 | 340 | 520.000 | 4.300 |

**Kendi otelin:**
- 1,5× misafir, 1,5× popülerlik, ücret ödenmez.
- Popülerlik eşiğin altındaysa gelirin %50'si gelir.
- Kışın gelir ×0,6.

## Görevler
Ödül amiral balonunun boyuyla çarpılır: S ×1, M ×2, L ×3, XL ×4.

| Görev | Taban ödül |
|---|---|
| Evlilik teklifi: 250–350 m arasında kesintisiz 8 sn kal | 450 |
| Vadi | 300 |
| Panorama | 250 |
| Hassas iniş | 400 |

İlk görev her zaman evlilik teklifidir. Görev başarılırsa ödül sert inişte bile korunur. Başarı kutlaması alkış ve fanfarla yapılır.

## Rakipler
| Şirket | Tarz | Filo | Fiyat | Popülerlik | Kasa |
|---|---|---|---|---|---|
| Göreme Sky | temkinli | L L L M M M | 195 | 1,15 | 50.000 |
| Peribaca Balloons | orta | M M M S | 165 | 1,0 | 20.000 |
| Kızıl Vadi Air | riskli | S S S | 135 | 0,85 | 9.000 |

- Fiyat tabanı maliyetten hesaplanır (en fazla 220). Tavanlar: riskli 190, orta 260.
- 5. günden sonra zor durumdaki rakip satışa çıkar (filo satın alma veya devralma).
- **Yeni girenler:** Bosphorus Balloons, Anatolian Sky, Peri Luxe Flights, Aegean Air Tours. Batan rakibin yerine 6+ gün sonra, günlük %30 şansla gelirler.
- **Tekel cezası:** 20. günden sonra pazar payı > %60 olan her gün sayılır.
  - 3. günde Hezarfen uyarır.
  - 5 ve üstünde her gün %25 şansla max(€5.000, kasanın %8'i) ceza.

## Kış
- En erken 40. gün, kasa ≥ €50.000 iken başlar ve 8 gün sürer.
- Bir sonraki kış 45 gün sonra gelir.
- Talep ×0,55. Bayrak olasılıkları: yeşil %35, sarı %35, kırmızı %30.
- Kar görselleri gösterilir.

## Hezarfen Usta
Yaşlı, karizmatik mentor. Daktilo efektli konuşma balonuyla konuşur. Konuları:
- karşılama, sigorta, filo, banka, pazar, ekip
- sarı ve kırmızı bayrak
- görev, kaza, kriz
- rakipleri batırma ipuçları
- beklenti (4,5★), tekel, eskime
- dinamik haberler (kış, yeni rakip)

## Görsel ve ses
- **Renkler:** mürekkep #2b2350, mercan #ff5e3a, güneş #ffc23d, cam rgba(30,24,64,.84).
- **Fontlar:** Barlow ve Barlow Condensed.
- **Görseller:** gün doğumu Kapadokya, katmanlı peribacası silüetleri, kodla çizilmiş balonlar.
- **Sesler (sentez):** brülör gürültüsü, kuş ve ortam sesi, formant sesli kalabalık uğultusu, alkış, fanfar, para, tık.

## Yerelleştirme
Tüm metinler TR ve EN olacak. Swift'te String Catalog kullanılacak. Türkçe ek uyumu ("Balon'a/Air'e") için metinler şirket adının arkasına ek gelmeyecek şekilde yazılır.
