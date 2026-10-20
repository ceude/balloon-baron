# Swift'e aktarılacaklar

Prototipte yapılıp henüz iOS koduna geçmemiş değişiklikler. Karar verilince toplu olarak aktarılır.

## Kurucu primi ve PR tavanı (denge değişikliği)
- Kurucu uçuşu primi %30 → %25 (`Rules.founderPremium`).
- **PR tavanı:** Aktif otel anlaşması / sahip olunan otel yoksa ve son 10 günde rehber tanıtım uçuşu yapılmadıysa popülerlik gün sonunda 4,2★'ı (rep 1,05) geçemez. Son 10 günde influencer kampanyası varsa (`influencerCooldown > day`) tavan 4,5★ (rep 1,125). Tavan dersi (`prcap`) iki sınırı da anlatır. `lastGuide` bölge durumuna eklenir.
- **Hezarfen'in yeni dersleri:** `pr` (6. gün: otel ve rehber anlaşmaları, lüks oteller yüksek fiyata misafir getirir, otelsiz şirket 4,2★'ı geçemez), `influ` (ilk influencer kampanyasından hemen sonra: influencer'ı başta nadir yap; kampanya yapılmazsa hiç çıkmaz), `prcap` (tavana ilk takılınca).

## Şirketim: izometrik şirket kasabası (prototip v54)
- Yan menüdeki Filo, Ekip, Banka ve Pazar butonları tek bir **Şirketim** butonunda birleşti (kasaba ikonu, ekip ya da pazar uyarısı varsa kırmızı nokta). Hedef/Holding butonu aynı kalır.
- Şirketim tam ekran, kaydırılabilir ve iki parmakla yakınlaştırılabilen izometrik bir Kapadokya kasabası. Binaya dokununca ilgili sayfa ya da bölüm açılır:
  - Hangar → Filo ("Balonların"). Gelişmiş: 8+ balon, çatıda bayrak. Çatı şirket renklerinde.
  - Balon atölyesi → Filo, "Balon atölyesi" bölümü. Kurulmadıysa "Satılık" arsa ve fiyat. Gelişmiş: 3+ tasarım. Çatıda son tasarımın renkleri.
  - Pilot ofisi → Ekip. Gelişmiş: 6+ pilot.
  - Pilot okulu → Ekip, "Pilot okulu" bölümü. Kurulmadıysa arsa. Çan kulesi.
  - Banka → Banka. Krediler varken gelişmiş görünüm.
  - Otel sokağı (4 otel) → Pazar, "Otel anlaşmaları". Anlaşmalıysa senin bayrağın, sahibiysen bayrak + ışıltı, rakiple anlaşmalıysa rakibin bayrağı; yıldız sayısı otelin sınıfı.
  - Influencer ajansı ve rehber ofisi → doğrudan kampanya kartı (bekleme süresi, fiyat). Kampanya sürerken neon tabela yanıp söner.
  - Rakiplerin ofisleri → Pazar, "Sen ve rakiplerin". Batan rakibin ofisi kapalı.
  - Holding kulesi (Baron olunca) → Holding; öncesinde arsa ve "Baron olunca".
  - Henüz açılmamış özellikler iskeleyle ve koyu etiketle görünür; dokununca "X. günde açılır" kartı.
- Etiketler yakınlaştırmaya göre küçülür (uzakta sadece ad), birbirinin üstüne binenler gizlenir. Fırlatma alanında filodaki balonlar (ilk 6) desenleriyle durur.
- Influencer ve rehber işlemleri ortak fonksiyonlara taşındı (`doInfluencer`, `doGuide`); popülerlik grafiği de onları kullanır.

Önceki toplu aktarım tamamlandı. Son toplu aktarım: filo/ekip arayüzü, sade ana ekran ve fiyat paneli, tekel cezası, pazar kartları, güçlü rakipler ve birleşmeler, bölümler ve Baron, Albuquerque ve otomatik mod, tasarım stüdyosu, holding ve ofisler.

Aktarımda bilerek eksik kalanlar (ileride):
- (yok)
