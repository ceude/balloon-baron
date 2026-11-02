# App Store metadata (Deutsch) — v2

Ekran görüntüleri `appstore-assets` dalında: `marketing/appstore/de-v2/iphone/01–10.png` (1320×2868), `ipad/01–10.png` (2064×2752), `overview.jpg`. Bu dil için App Preview videosu yok. Metinler: `tools/appstore/v2/captions.js` (`de`). Oyun ekranları gerçek uygulamadan, bu dilde çekildi (`.github/workflows/store-shots.yml`).

## Ad, alt başlık, anahtar kelimeler

| Alan | Metin | Karakter | Sınır |
|---|---|---|---|
| Ad | Balloon Baron: Kappadokien | 26 | 30 |
| Alt başlık | Heißluftballon Aufbauspiel | 26 | 30 |
| Anahtar kelimeler | `wirtschaftssimulation,tycoon,idle,manager,firma,imperium,pilot,ballonfahrt,strategie,stadt,flotte` | 97 | 100 |
| Tanıtım metni | (aşağıda) | 166 | 170 |
| Açıklama | (aşağıda) | 3034 | 4000 |

**Ad:** "Balloon Baron: Kappadokien" önerilir: marka İngilizce kalır, ama Almanların aradığı yer adı ("Ballonfahrt Kappadokien" Almanya'da çok aranır) adda olur. İstenirse "Balloon Baron: Cappadocia" da kalabilir; o zaman 10. karenin imzası (`captions.js` `brand`) değişmeli.

**Alt başlık:** "Heißluftballon" ve "Aufbauspiel" (kurma oyunu) Almanca mağazada türün ana arama terimleri. "Wirtschaftssimulation" alt başlığa sığmadığı için anahtar kelimelerde ve açıklamada.

**Anahtar kelimeler:** wirtschaftssimulation, tycoon, idle, manager, firma, imperium, ballonfahrt (Almanca'da balonla uçmanın asıl adı), strategie, stadt, flotte.

Anahtar kelimeler virgülle ve boşluksuz; ad ve alt başlıktaki kelimeler tekrar edilmedi (Apple üçünü birlikte indeksler), rakip marka yok.

## App Store Connect alanları

`tools/appstore/asc/asc.py metadata` bu blokları okur. Açıklamada başlıklar büyük harfle, çünkü App Store kalın yazı göstermez.

```asc:name
Balloon Baron: Kappadokien
```

```asc:subtitle
Heißluftballon Aufbauspiel
```

```asc:keywords
wirtschaftssimulation,tycoon,idle,manager,firma,imperium,pilot,ballonfahrt,strategie,stadt,flotte
```

```asc:promotionalText
Starte mit einem einzigen Korb im Morgenrot über den Feenkaminen. Lass die Tage laufen, die Kasse klingeln und bau ein Ballon-Imperium in vier Städten auf. Werbefrei.
```

```asc:description
Im Morgenrot über Kappadokien beginnst du mit einem einzigen kleinen Korb. Ein paar Jahreszeiten später ist der halbe Himmel voller Ballons, und aus deiner Firma ist ein Konzern geworden, der sich über vier Städte erstreckt. Balloon Baron ist eine Wirtschaftssimulation und ein Aufbauspiel rund um dein eigenes Heißluftballon-Unternehmen.

KEINE WERBUNG. KEINE ENERGIE. KEIN WARTEN.
Nichts hält dich vom Spielen ab. Keine Werbung verdeckt den Bildschirm, keine Energie geht aus, kein Timer lässt dich warten.

DIE TAGE LAUFEN, DIE KASSE KLINGELT
Ist deine Flotte groß und bist du Baron von Kappadokien, schaltest du das Vorspulen frei: Die Tage laufen von selbst, deine Piloten fahren, die Einnahmen landen in der Kasse. Braucht es eine Entscheidung, hält das Spiel an und ruft dich. Eroberte Regionen bleiben im Autopilot bei ihren Managern und schicken jeden Tag Geld an deinen Konzern. Entspannt für Idle-Fans, tief für Tycoon-Fans.

DU FLIEGST IM MORGENROT
Wann immer du willst, übernimmst du selbst. Heiz den Brenner an, lies die Windschichten und setz sanft auf dem Landefeld auf. Heiratsanträge über den Wolken, Fotofahrten und Präzisionslandungen bringen extra Geld.

GRÜNDE DEINE FIRMA, BAU DEINE STADT
Kauf Ballons, leg den Ticketpreis fest, schließ Verträge mit Hotels, Reiseführern und Reiseagenturen. Aus deinem kleinen Büro wird eine ganze Stadt mit Hangars, Pilotenschule, Werkstatt und Hotels. Nachts gehen die Laternen an und Feuerwerk steigt auf.

JEDER PILOT EIN CHARAKTER
Vorsichtig, Draufgänger oder treu? Stell Piloten ein, bilde sie aus und mach sie zu Senior-Piloten. Die Konkurrenz versucht, dir die Besten abzuwerben; dein Team zusammenzuhalten ist deine Aufgabe.

ÜBERNIMM DIE KONKURRENZ
Im Tal fliegen auch andere Ballonfirmen. Sie fusionieren, heizen den Preiskampf an und starten bei roter Flagge. Erobere den Markt, übernimm deine Rivalen und werde Baron von Kappadokien.

VOM KORB ZUM KONZERN
Als Baron gründest du deinen Konzern: Marketing- und Forschungsabteilung, Büros in aller Welt, Rekordprojekte und gesponserte Riesenballons warten auf dich.

VIER STÄDTE, EIN IMPERIUM
- Kappadokien: Feenkamine und Sonnenaufgang
- Luxor: der Nil, Tempel und Nilkreuzfahrtschiffe
- Bristol: neblige Morgen, die Avon-Schlucht und ein Ballonfestival
- Albuquerque: Wüste, die Box-Winde und die Balloon Fiesta
Jede Stadt hat ihre eigenen Winde, Rivalen und Geschichten. Albuquerque, Luxor und Bristol öffnet der In-App-Kauf Weltreise.

GROSSE SHOW AM NACHTHIMMEL
Ist deine Flotte groß, lässt du eines Nachts alle deine Ballons über der Stadt leuchten. Die Brenner glühen gemeinsam auf, und in den Tagen danach stehen die Touristen bei dir Schlange.

DEIN BALLON, DEINE HANDSCHRIFT
Gestalte im Designstudio deine eigenen Ballons: Muster, Farben, dazu Ballons in Herz-, Stern- und Totenkopfform (besondere Muster und Formen per In-App-Kauf). Mit der Zeit wird deine Werkstatt zur Fabrik, die eigene Ballons baut.

Jedes Bild und jeder Ton im Spiel ist in Code entstanden. Der Himmel über Kappadokien wartet auf dich.
```

## Ekran görüntüsü metinleri

Sıra ve hikâye Türkçe setle aynı; her karede büyük başlık ve en çok beş kelimelik bir alt satır. Birebir çeviri değil, bu pazarın arama terimleriyle yazıldı.

| # | Başlık | Alt satır |
|---|---|---|
| 01 | Gründe deine / Ballonfirma | Vom Korb zur Riesenflotte |
| 02 | Vier Städte, / ein Imperium | Von Kappadokien zur Balloon Fiesta |
| 03 | Du fliegst / im Morgenrot | Realistische Heißluftballonfahrt |
| 04 | Die Tage laufen, / die Kasse klingelt | Wirtschaftssimulation mit Vorspulen |
| 05 | Vom Korb / zum Konzern | Tag 2 bis Tag 132 |
| 06 | Jeder Pilot / ein Charakter | Vorsichtig, Draufgänger, treu |
| 07 | Dein Ballon, / deine Handschrift | Herz-, Stern- und Totenkopfballons |
| 08 | Übernimm / die Konkurrenz | Strategie gewinnt den Markt |
| 09 | Nachts hell / erleuchtet | Dein Büro wird zur Stadt |
| 10 | Große Show / am Nachthimmel | Ballon-Show: die ganze Flotte |

- 1. karedeki küçük etiket: **Werbefrei**
- 10. karenin imzası: **Balloon Baron · Kappadokien**
- Rozetlerdeki rakamlar, aynı karedeki gerçek uygulama ekranından:
- 04: **+145.847 €** an einem Tag · **164** Ballons in der Flotte
- 05: Tag 2 **1** Ballon → Tag 132 **164** Ballons
- 08: **99 %** Marktanteil

## Uygunluk notları

- Ekranlardaki oyun görüntüleri gerçek uygulamadan (debug yapı, `DemoSetup.swift` ile kurulan bir şirket: 130 gün kurallarla oynandı, ekran görüntüsü için filo 164 balona büyütüldü, holding kasası test durumundan).
- 04: iPhone şeridi Tag 134 +145.847 €, iPad şeridi Tag 133 +143.447 € gösteriyor; her cihazın rozeti kendi şeridindeki rakam.
- Hiçbir balonun üstünde yazı ya da isim yok (sponsor bantları kapalı).
- Puan, ödül, "1 numara" iddiası, fiyat ve emoji yok. "Reklamsız" doğru: oyunda reklam yok.
- 2. kare (Luksor, Bristol, Albuquerque) ve 7. kare (yıldız balon, takımyıldız deseni) uygulama içi satın alımla açılan içerik gösteriyor; açıklamada belirtildi.
