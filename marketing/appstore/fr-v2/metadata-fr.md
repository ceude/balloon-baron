# App Store metadata (Français (France, Canada)) — v2

Ekran görüntüleri `appstore-assets` dalında: `marketing/appstore/fr-v2/iphone/01–10.png` (1320×2868), `ipad/01–10.png` (2064×2752), `overview.jpg`. Bu dil için App Preview videosu yok. Metinler: `tools/appstore/v2/captions.js` (`fr`). Oyun ekranları gerçek uygulamadan, bu dilde çekildi (`.github/workflows/store-shots.yml`).

Yerelleştirmeler: `fr-FR`; `fr-CA` (Kanada) aynı metni kullanır (`tools/appstore/asc/config.json` `extraLocales`, `--extra-locales` ile).

## Ad, alt başlık, anahtar kelimeler

| Alan | Metin | Karakter | Sınır |
|---|---|---|---|
| Ad | Balloon Baron: Cappadoce | 24 | 30 |
| Alt başlık | Gestion de montgolfières | 24 | 30 |
| Anahtar kelimeler | `tycoon,simulation,entreprise,idle,empire,ballon,stratégie,pilote,compagnie,ville,flotte,tourisme` | 96 | 100 |
| Tanıtım metni | (aşağıda) | 166 | 170 |
| Açıklama | (aşağıda) | 3686 | 4000 |

**Ad:** Marka İngilizce kalır, yer adı Fransızca: Fransızlar "vol en montgolfière Cappadoce" diye arar. Fransız tipografisi iki noktadan önce boşluk ister, ama marka adı oyundaki ve diğer dillerdeki gibi yazıldı.

**Alt başlık:** "montgolfière" Fransızcada sıcak hava balonunun asıl adı ve en çok aranan kelime; "gestion" (yönetim oyunu) türün ana arama terimi ("jeu de gestion").

**Anahtar kelimeler:** tycoon, simulation, entreprise, idle ve empire Fransız mağazasında bu türün arama kelimeleri; "ballon" günlük dilde montgolfière'in kısası; tourisme ve ville kasaba kurma ve Kapadokya aramalarını yakalıyor. Yer kalırsa: `jeu`, `festival`, `turquie`.

Anahtar kelimeler virgülle ve boşluksuz; ad ve alt başlıktaki kelimeler tekrar edilmedi (Apple üçünü birlikte indeksler), rakip marka yok.

## App Store Connect alanları

`tools/appstore/asc/asc.py metadata` bu blokları okur. Açıklamada başlıklar büyük harfle, çünkü App Store kalın yazı göstermez. İki noktadan, ünlem ve soru işaretinden önceki boşluklar bölünmez boşluk (U+00A0).

```asc:name
Balloon Baron: Cappadoce
```

```asc:subtitle
Gestion de montgolfières
```

```asc:keywords
tycoon,simulation,entreprise,idle,empire,ballon,stratégie,pilote,compagnie,ville,flotte,tourisme
```

```asc:promotionalText
Commencez avec une seule nacelle au lever du soleil sur les cheminées de fées. Laissez filer les jours, regardez la caisse se remplir et bâtissez un empire. Sans pub.
```

```asc:description
Au lever du soleil, en Cappadoce, tout commence avec une petite nacelle. Quelques saisons plus tard, la moitié du ciel est couverte de vos montgolfières et votre compagnie est devenue une holding présente dans cinq régions. Balloon Baron est un jeu de gestion et de simulation d’entreprise : à vous de bâtir votre propre compagnie de montgolfières.

PAS DE PUB. PAS D’ÉNERGIE. PAS D’ATTENTE.
Rien ne vous empêche de jouer. Aucune publicité ne couvre l’écran, aucune jauge d’énergie ne se vide, aucun minuteur ne vous fait patienter.

LES JOURS FILENT, LA CAISSE SE REMPLIT
Quand votre flotte est grande et que vous êtes Baron de Cappadoce, l’avance rapide se débloque : les jours défilent tout seuls, vos pilotes volent et les recettes tombent dans la caisse. Dès qu’une décision vous attend, le jeu s’arrête et vous appelle. Les régions conquises restent aux mains de leurs directeurs en pilote automatique et envoient chaque jour de l’argent à votre holding. Détendu pour les fans d’idle, riche pour les fans de tycoon.

PILOTEZ VOUS-MÊME À L’AUBE
Prenez les commandes quand vous voulez. Allumez le brûleur, lisez les couches de vent et posez-vous en douceur sur l’aire d’atterrissage. Demandes en mariage dans le ciel, vols photo et atterrissages de précision rapportent un bonus.

FONDEZ VOTRE COMPAGNIE, FAITES GRANDIR VOTRE VILLE
Achetez des ballons, fixez le prix du billet, signez avec des hôtels, des guides et des agences de voyages. Votre petit bureau devient toute une ville avec hangars, école de pilotage, atelier et hôtels. La nuit, les lanternes s’allument et les feux d’artifice montent dans le ciel.

CHAQUE PILOTE A SON CARACTÈRE
Méthodique, casse-cou ou fidèle ? Engagez vos pilotes, formez-les et faites-en des seniors. Vos concurrents tenteront de vous débaucher les meilleurs ; à vous de garder votre équipage.

DAMEZ LE PION À LA CONCURRENCE
D’autres compagnies de montgolfières se partagent la vallée. Elles fusionnent, lancent des guerres des prix et décollent sous drapeau rouge. Conquérez le marché, rachetez vos concurrents et devenez Baron de Cappadoce.

D’UNE NACELLE À UNE HOLDING
Une fois baron, vous fondez votre holding : services marketing et R&D, bureaux à Istanbul, Séoul, New York, Londres, Tokyo et Dubaï, tentatives de record et ballons géants sponsorisés vous attendent.

CINQ RÉGIONS, UN EMPIRE
- Cappadoce : cheminées de fées et lever de soleil
- Albuquerque : le désert, les vents en « boîte » et la Balloon Fiesta
- Louxor : le Nil, ses temples et ses bateaux de croisière
- Bristol : matins brumeux, la gorge de l’Avon et un festival de montgolfières
- Maasai Mara (Kenya) : safaris à l’aube au-dessus de la savane, saisons des pluies et Grande Migration
Chaque région a ses vents, ses concurrents et son histoire. Le Maasai Mara est la région la plus redoutable : de petits avions de brousse amènent vos passagers depuis Nairobi, et un ancien maasaï vous sert de guide. Il s’ouvre une fois que vous êtes Baron de Bristol. Albuquerque, Louxor, Bristol et le Maasai Mara font partie de l’achat intégré Grand Tour.

UN SHOW GÉANT DANS LE CIEL NOCTURNE
Quand votre flotte est grande, une nuit, vous illuminez tous vos ballons au-dessus de la ville. Les brûleurs s’embrasent ensemble, et les jours suivants, les touristes font la queue devant votre porte.

VOTRE BALLON, VOTRE SIGNATURE
Dessinez vos propres ballons dans le studio de création : motifs, couleurs, et enveloppes en forme de cœur, d’étoile ou de tête de mort (motifs et formes spéciaux en achats intégrés). Avec le temps, votre atelier devient une usine qui fabrique vos propres ballons.

Chaque image et chaque son du jeu ont été créés en code. Le ciel de Cappadoce vous attend.
```

## Ekran görüntüsü metinleri

Sıra ve hikâye Türkçe setle aynı; her karede büyük başlık ve kısa bir alt satır. Birebir çeviri değil, Fransız mağazasının arama terimleriyle (montgolfière, gestion, idle, empire) reklam diliyle yazıldı. Ekranlardaki başlıklar "tu" ile (oyunun dili), mağaza açıklaması "vous" ile (Fransız mağazalarında alışılan).

| # | Başlık | Alt satır |
|---|---|---|
| 01 | Bâtis ton empire / de montgolfières | D’une nacelle à toute une flotte |
| 02 | Cinq régions, / un empire | De la Cappadoce au Maasai Mara |
| 03 | Pilote / à l’aube | Vol réaliste en montgolfière |
| 04 | Les jours filent, / la caisse se remplit | Jeu de gestion idle avec avance rapide |
| 05 | D’une nacelle / à un empire | Du jour 2 au jour (gün) |
| 06 | Chaque pilote / a son style | Méthodique, casse-cou, fidèle |
| 07 | Ton ballon, / ta signature | Ballons cœur, étoile et tête de mort |
| 08 | Rachète / tes concurrents | La stratégie gagne le marché |
| 09 | La nuit, / tout s’illumine | Ton bureau devient une ville |
| 10 | Un show géant / dans le ciel | Spectacle de ballons : toute la flotte |

- 1. karedeki küçük etiket: **Sans pub**
- 10. karenin imzası: **Balloon Baron · Cappadoce**
- Rozetlerdeki rakamlar aynı karedeki gerçek uygulama ekranından, Fransız yazımıyla (binlik ayırıcı boşluk, € sonda, % önünde boşluk).

## Uygunluk notları

- Ekranlardaki oyun görüntüleri gerçek uygulamadan, Fransızca (debug yapı, `DemoSetup.swift`; şirket adı "Ballons de l’Aube").
- Hiçbir balonun üstünde yazı ya da isim yok (sponsor bantları kapalı).
- Puan, ödül, "1 numara" iddiası, fiyat ve emoji yok. "Sans pub" doğru: oyunda reklam yok.
- 2. kare (Louxor, Bristol, Albuquerque; başlıkta Maasai Mara) ve 7. kare (yıldız balon, takımyıldız deseni) uygulama içi satın alımla açılan içerik gösteriyor; açıklamada belirtildi.
