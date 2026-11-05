# App Store metadata (한국어) — v2

Ekran görüntüleri `appstore-assets` dalında: `marketing/appstore/ko-v2/iphone/01–10.png` (1320×2868), `ipad/01–10.png` (2064×2752), `overview.jpg`. Bu dil için App Preview videosu yok. Metinler: `tools/appstore/v2/captions.js` (`ko`). Oyun ekranları gerçek uygulamadan, bu dilde çekildi (`.github/workflows/store-shots.yml`).

## Ad, alt başlık, anahtar kelimeler

| Alan | Metin | Karakter | Sınır |
|---|---|---|---|
| Ad | 벌룬 바론: 열기구 회사 경영 | 16 | 30 |
| Alt başlık | 카파도키아 열기구 타이쿤 시뮬레이션 | 19 | 30 |
| Anahtar kelimeler | `방치형,키우기,육성,사장,파일럿,비행,전략,마을,제국,관광,튀르키예,하늘,풍선,기업,재벌,부자,건설,게임` | 58 | 100 |
| Tanıtım metni | (aşağıda) | 84 | 170 |
| Açıklama | (aşağıda) | 1437 | 4000 |

**Ad (yerelleştirilmiş, önerilir):** "벌룬 바론: 열기구 회사 경영". Kore mağazasında Hangıl ad hem okunur hem aranır; "열기구" (sıcak hava balonu) ve "경영" (işletme) adda. Ana ekrandaki ad istenirse "벌룬 바론" yapılabilir.

**Alt başlık:** "카파도키아 열기구 타이쿤 시뮬레이션": 타이쿤 (tycoon) ve 시뮬레이션; adla birlikte "경영 시뮬레이션" aramasını da tutar.

**Anahtar kelimeler:** 방치형 (idle), 키우기, 육성, 사장, 기업, 재벌, 부자, 건설, 마을, 제국, 관광, 튀르키예. Kısa kelimeler; 58 karakter yeterli.

Anahtar kelimeler virgülle ve boşluksuz; ad ve alt başlıktaki kelimeler tekrar edilmedi (Apple üçünü birlikte indeksler), rakip marka yok.

## App Store Connect alanları

`tools/appstore/asc/asc.py metadata` bu blokları okur. Açıklamada başlıklar büyük harfle, çünkü App Store kalın yazı göstermez.

```asc:name
벌룬 바론: 열기구 회사 경영
```

```asc:subtitle
카파도키아 열기구 타이쿤 시뮬레이션
```

```asc:keywords
방치형,키우기,육성,사장,파일럿,비행,전략,마을,제국,관광,튀르키예,하늘,풍선,기업,재벌,부자,건설,게임
```

```asc:promotionalText
요정의 굴뚝 위로 해가 뜨는 새벽, 바구니 하나로 시작하세요. 하루하루 흐르는 동안 금고를 채우고 네 도시에 걸친 열기구 제국을 세우세요. 광고 없음.
```

```asc:description
카파도키아의 새벽, 당신에게는 작은 바구니 하나뿐입니다. 몇 시즌이 지나면 하늘의 절반이 당신의 열기구로 가득하고, 회사는 네 도시에 걸친 지주회사로 성장합니다. 《벌룬 바론》은 열기구 회사를 직접 세우고 키우는 경영 시뮬레이션이자 타이쿤 게임입니다.

광고 없음. 에너지 없음. 기다림 없음.
플레이를 막는 것은 아무것도 없습니다. 화면을 가리는 광고도, 떨어지는 에너지도, 기다려야 하는 타이머도 없습니다.

하루가 흐르면 금고가 찬다
기단이 커지고 카파도키아의 남작이 되면 빨리 감기가 열립니다. 하루하루가 저절로 흘러가고, 조종사들이 날고, 수익이 금고에 쌓입니다. 결정이 필요하면 게임이 멈추고 당신을 부릅니다. 정복한 지역은 매니저가 자동으로 운영하며 매일 지주회사로 돈을 보냅니다. 방치형 게임을 좋아한다면 편안하게, 타이쿤을 좋아한다면 깊이 있게.

새벽 하늘을 직접 날다
언제든 직접 조종할 수 있습니다. 버너를 켜고, 고도마다 다른 바람을 읽고, 착륙장에 사뿐히 내려앉으세요. 하늘 위의 프러포즈, 사진 비행, 정밀 착륙 임무는 추가 수익을 안겨 줍니다.

회사를 세우고 마을을 키우세요
열기구를 사고, 티켓 가격을 정하고, 호텔, 가이드, 여행사와 계약하세요. 작은 사무실이 격납고, 조종사 학교, 공방, 호텔이 들어선 하나의 마을로 자라납니다. 밤이 되면 등불이 켜지고 불꽃놀이가 터집니다.

조종사마다 개성이 다르다
신중함, 무모함, 아니면 충성스러움? 조종사를 고용하고, 키우고, 베테랑으로 만드세요. 경쟁사는 당신의 에이스를 빼가려 합니다. 팀을 지키는 것은 당신의 몫입니다.

경쟁사를 인수하라
계곡에는 다른 열기구 회사들도 있습니다. 합병하고, 가격 경쟁을 벌이고, 빨간 깃발에도 날아오릅니다. 시장을 장악하고, 경쟁사를 인수하고, 카파도키아의 남작이 되세요.

바구니 하나에서 대기업으로
남작이 되면 지주회사를 세웁니다. 마케팅과 연구개발 부서, 세계 곳곳의 사무소, 기록 도전, 후원을 받은 거대한 모양의 열기구가 기다립니다.

네 도시, 하나의 제국
- 카파도키아: 요정의 굴뚝과 일출
- 룩소르: 나일강, 신전, 나일 크루즈선
- 브리스톨: 안개 낀 아침, 에이번 협곡, 열기구 축제
- 앨버커키: 사막, 박스 바람, 벌룬 피에스타
도시마다 바람도, 경쟁사도, 이야기도 다릅니다. 앨버커키, 룩소르, 브리스톨은 인앱 구매 '그랜드 투어'로 열립니다.

밤하늘을 수놓는 열기구 쇼
기단이 커지면 어느 밤 모든 열기구를 마을 위에서 한꺼번에 밝히세요. 버너가 일제히 빛나고, 그 후 며칠 동안 관광객들이 줄을 섭니다.

나만의 열기구를 디자인하라
디자인 스튜디오에서 나만의 열기구를 만드세요. 무늬, 색상, 그리고 하트, 별, 해골 모양 열기구(특별한 무늬와 모양은 인앱 구매). 시간이 지나면 공방이 직접 열기구를 생산하는 공장이 됩니다.

게임 속 모든 그림과 소리는 코드로 만들어졌습니다. 카파도키아의 하늘이 당신을 기다립니다.
```

## Ekran görüntüsü metinleri

Sıra ve hikâye Türkçe setle aynı; her karede büyük başlık ve en çok beş kelimelik bir alt satır. Birebir çeviri değil, bu pazarın arama terimleriyle yazıldı.

| # | Başlık | Alt satır |
|---|---|---|
| 01 | 열기구 회사의 / 사장이 되자 | 열기구 하나에서 대기단으로 |
| 02 | 네 도시, / 하나의 제국 | 카파도키아에서 벌룬 피에스타까지 |
| 03 | 새벽 하늘을 / 직접 날다 | 리얼한 열기구 비행 |
| 04 | 하루가 흐르면 / 금고가 찬다 | 빨리 감기로 즐기는 방치형 타이쿤 |
| 05 | 바구니 하나에서 / 대기업으로 | 2일차에서 132일차까지 |
| 06 | 조종사마다 / 개성이 다르다 | 신중함, 무모함, 충성스러움 |
| 07 | 나만의 열기구를 / 디자인하라 | 하트, 별, 해골 열기구 |
| 08 | 경쟁사를 / 인수하라 | 전략으로 시장을 장악하라 |
| 09 | 밤이면 / 반짝이는 마을 | 사무실이 큰 마을이 된다 |
| 10 | 밤하늘을 수놓는 / 열기구 쇼 | 모든 기단이 하늘로 |

- 1. karedeki küçük etiket: **광고 없음**
- 10. karenin imzası: **벌룬 바론 · 카파도키아**
- Rozetlerdeki rakamlar, aynı karedeki gerçek uygulama ekranından:
- 04: **+€137,103** 하루 수익 · **164** 대 열기구 기단
- 05: 2일차 **1** 대 → 132일차 **164** 대
- 08: **99%** 시장 점유율

## Uygunluk notları

- Ekranlardaki oyun görüntüleri gerçek uygulamadan (debug yapı, `DemoSetup.swift` ile kurulan bir şirket: 130 gün kurallarla oynandı, ekran görüntüsü için filo 164 balona büyütüldü, holding kasası test durumundan).
- 04: iPhone'da şerit 138일차 +€137,103 gösteriyor. iPad'de şerit 134. gün uçarken çekildi; iPad rozeti o günün gerçek kazancı (+€145,847, Almanca çekimde şeritte görünüyor, simülasyon her dilde aynı).
- Hiçbir balonun üstünde yazı ya da isim yok (sponsor bantları kapalı).
- Puan, ödül, "1 numara" iddiası, fiyat ve emoji yok. "Reklamsız" doğru: oyunda reklam yok.
- 2. kare (Luksor, Bristol, Albuquerque) ve 7. kare (yıldız balon, takımyıldız deseni) uygulama içi satın alımla açılan içerik gösteriyor; açıklamada belirtildi.
