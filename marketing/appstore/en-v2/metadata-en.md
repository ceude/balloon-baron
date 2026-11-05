# App Store metadata (English (U.S., U.K.)) — v2

Ekran görüntüleri `appstore-assets` dalında: `marketing/appstore/en-v2/iphone/01–10.png` (1320×2868), `ipad/01–10.png` (2064×2752), `overview.jpg`. Bu dil için App Preview videosu yok. Metinler: `tools/appstore/v2/captions.js` (`en`). Oyun ekranları gerçek uygulamadan, bu dilde çekildi (`.github/workflows/store-shots.yml`).

## Ad, alt başlık, anahtar kelimeler

| Alan | Metin | Karakter | Sınır |
|---|---|---|---|
| Ad | Balloon Baron: Cappadocia | 25 | 30 |
| Alt başlık | Hot Air Balloon Tycoon Game | 27 | 30 |
| Anahtar kelimeler | `idle,business,sim,simulator,empire,manager,company,pilot,flight,strategy,builder,town,fleet,turkey` | 98 | 100 |
| Tanıtım metni | (aşağıda) | 158 | 170 |
| Açıklama | (aşağıda) | 3080 | 4000 |

**Ad:** İngilizce ad aynen kalıyor (birincil dil İngilizce ABD; İngiltere mağazası da aynı metni kullanır, ayrı bir en-GB yerelleştirmesi istenirse bu dosya kopyalanır).

**Alt başlık:** "hot air balloon" bu tür için en çok aranan ifade; "tycoon" ve "game" tür aramalarını yakalıyor. Bu kelimeler anahtar kelime alanında tekrar edilmedi.

**Anahtar kelimeler:** idle, business sim/simulator, empire, manager ve strategy oyuncuların bu türü ararken kullandığı kelimeler; `turkey` ve `town` Kapadokya ve kasaba kurma aramalarını yakalıyor. Yer kalırsa: `fiesta`, `festival`, `tourism`.

Anahtar kelimeler virgülle ve boşluksuz; ad ve alt başlıktaki kelimeler tekrar edilmedi (Apple üçünü birlikte indeksler), rakip marka yok.

## App Store Connect alanları

`tools/appstore/asc/asc.py metadata` bu blokları okur. Açıklamada başlıklar büyük harfle, çünkü App Store kalın yazı göstermez.

```asc:name
Balloon Baron: Cappadocia
```

```asc:subtitle
Hot Air Balloon Tycoon Game
```

```asc:keywords
idle,business,sim,simulator,empire,manager,company,pilot,flight,strategy,builder,town,fleet,turkey
```

```asc:promotionalText
Start with one basket at sunrise over the fairy chimneys. Let the days roll on, watch the cash pile up and build a balloon empire across five regions. No ads.
```

```asc:description
You start at sunrise in Cappadocia with one small basket. A few seasons later half the sky is full of your balloons and your company has grown into a holding that spans five regions. Balloon Baron is a hot air balloon tycoon game and business sim about building that company yourself.

NO ADS. NO ENERGY. NO WAITING.
Nothing stops you from playing. No ads cover the screen, no energy runs out, no timers make you wait.

DAYS ROLL BY, CASH ROLLS IN
Once your fleet is big and you are Baron of Cappadocia, auto-advance unlocks: the days play themselves, your pilots fly and the takings go into the bank. When a decision needs you, the game stops and calls you. Regions you have conquered stay with their managers on autopilot and send money to your holding every day. Relaxed for idle fans, deep for tycoon fans.

FLY IT YOURSELF AT DAWN
Take the controls whenever you like. Fire the burner, read the wind layers and land softly on the field. Marriage proposals in the sky, photo flights and precision landing missions pay extra.

BUILD YOUR COMPANY, GROW YOUR TOWN
Buy balloons, set your ticket price, sign deals with hotels, guides and tour agencies. Your little office grows into a whole town with hangars, a pilot school, a workshop and hotels. At night the lanterns come on and fireworks go up.

EVERY PILOT IS A CHARACTER
Careful, daredevil or loyal? Hire your pilots, train them and make them seniors. Rivals will try to poach your best pilot; keeping your crew is your job.

OUTSMART YOUR RIVALS
Other balloon companies share the valley. They merge, start price wars and fly under red flags. Win the market, buy out your rivals and become Baron of Cappadocia.

FROM ONE BASKET TO A HOLDING
As Baron you found a holding: marketing and R&D units, offices in Istanbul, Seoul, New York, London, Tokyo and Dubai, record attempts and sponsored giant balloon shapes are waiting.

FIVE REGIONS, ONE EMPIRE
- Cappadocia: fairy chimneys and sunrise
- Albuquerque: desert, the box winds and the Balloon Fiesta
- Luxor: the Nile, temples and river cruisers
- Bristol: misty mornings, the Avon Gorge and a balloon festival
- Maasai Mara, Kenya: dawn safaris over the savanna, the rains and the Great Migration
Every region has its own winds, rivals and story. The Maasai Mara is the toughest of all: small safari planes fly your guests in from Nairobi, and a Maasai elder is your guide. It opens once you become Baron of Bristol. Albuquerque, Luxor, Bristol and the Maasai Mara are part of the Grand Tour in-app purchase.

A GIANT SHOW IN THE NIGHT SKY
When your fleet is big, one night you light up every balloon you own above the town. The burners glow together, and in the days after, tourists queue at your door.

YOUR BALLOON, YOUR SIGNATURE
Design your own balloons in the design studio: patterns, colours, and heart, star and skull shaped envelopes (special patterns and shapes are in-app purchases). In time your workshop becomes a factory that builds your own balloons.

Every piece of art and every sound in the game is made in code. The sky over Cappadocia is waiting for you.
```

## Ekran görüntüsü metinleri

Sıra ve hikâye Türkçe setle aynı; her karede büyük başlık ve en çok beş kelimelik bir alt satır. Birebir çeviri değil, bu pazarın arama terimleriyle yazıldı.

| # | Başlık | Alt satır |
|---|---|---|
| 01 | Become a / balloon tycoon | From one basket to hundreds |
| 02 | Five regions, / one empire | Cappadocia to the Maasai Mara |
| 03 | Fly it yourself / at dawn | Realistic hot air balloon flight |
| 04 | Days roll by, / cash rolls in | Idle tycoon with auto-advance |
| 05 | From one basket / to big business | Day 2 to Day 132 |
| 06 | Every pilot / is a character | Careful, daredevil, loyal |
| 07 | Your balloon, / your signature | Heart, star and skull balloons |
| 08 | Buy out / your rivals | Strategy wins the market |
| 09 | Glowing / after dark | Your office becomes a town |
| 10 | A giant show / in the night sky | Balloon Show: the whole fleet |

- 1. karedeki küçük etiket: **Ad-free**
- 10. karenin imzası: **Balloon Baron · Cappadocia**
- Rozetlerdeki rakamlar, aynı karedeki gerçek uygulama ekranından:
- 04: **+€137,103** in one day · **164** balloon fleet
- 05: Day 2 **1** balloon → Day 132 **164** balloons
- 08: **99%** market share

## Uygunluk notları

- Ekranlardaki oyun görüntüleri gerçek uygulamadan (debug yapı, `DemoSetup.swift` ile kurulan bir şirket: 130 gün kurallarla oynandı, ekran görüntüsü için filo 164 balona büyütüldü, holding kasası test durumundan).
- Hiçbir balonun üstünde yazı ya da isim yok (sponsor bantları kapalı).
- Puan, ödül, "1 numara" iddiası, fiyat ve emoji yok. "Reklamsız" doğru: oyunda reklam yok.
- 2. kare (Luksor, Bristol, Albuquerque; başlıkta Maasai Mara) ve 7. kare (yıldız balon, takımyıldız deseni) uygulama içi satın alımla açılan içerik gösteriyor; açıklamada belirtildi.
