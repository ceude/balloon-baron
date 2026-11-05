# App Store metadata (日本語) — v2

Ekran görüntüleri `appstore-assets` dalında: `marketing/appstore/ja-v2/iphone/01–10.png` (1320×2868), `ipad/01–10.png` (2064×2752), `overview.jpg`. Bu dil için App Preview videosu yok. Metinler: `tools/appstore/v2/captions.js` (`ja`). Oyun ekranları gerçek uygulamadan, bu dilde çekildi (`.github/workflows/store-shots.yml`).

## Ad, alt başlık, anahtar kelimeler

| Alan | Metin | Karakter | Sınır |
|---|---|---|---|
| Ad | バルーンバロン：気球会社経営 | 14 | 30 |
| Alt başlık | カッパドキアの熱気球タイクーン | 15 | 30 |
| Anahtar kelimeler | `放置,シミュレーション,育成,社長,パイロット,フライト,空,街づくり,まちづくり,戦略,トルコ,観光,帝国,ホールディングス,フェスティバル,シム,大富豪,ゲーム` | 82 | 100 |
| Tanıtım metni | (aşağıda) | 65 | 170 |
| Açıklama | (aşağıda) | 1257 | 4000 |

**Ad (yerelleştirilmiş, önerilir):** "バルーンバロン：気球会社経営". Japon mağazasında Latin harfli ad hem okunmuyor hem aranmıyor; katakana marka adı ve "気球" (balon) ile "経営" (işletme) adda en güçlü sinyali verir. Uygulamanın ana ekrandaki adı (CFBundleDisplayName) aynı kalabilir; istenirse Japonca için "バルーンバロン" yerelleştirilebilir.

**Alt başlık:** "カッパドキアの熱気球タイクーン": カッパドキア (Kapadokya), 熱気球 (sıcak hava balonu), タイクーン (tycoon).

**Anahtar kelimeler:** 放置 (idle), シミュレーション (adla birlikte "経営シミュレーション" aramasını tutar), 育成, 社長, 街づくり/まちづくり, 戦略, 大富豪, シム. Japonca'da 100 karakterin hepsi gerekmiyor; kelimeler kısa olduğu için 82 karakterde bırakıldı.

Anahtar kelimeler virgülle ve boşluksuz; ad ve alt başlıktaki kelimeler tekrar edilmedi (Apple üçünü birlikte indeksler), rakip marka yok.

## App Store Connect alanları

`tools/appstore/asc/asc.py metadata` bu blokları okur. Açıklamada başlıklar büyük harfle, çünkü App Store kalın yazı göstermez.

```asc:name
バルーンバロン：気球会社経営
```

```asc:subtitle
カッパドキアの熱気球タイクーン
```

```asc:keywords
放置,シミュレーション,育成,社長,パイロット,フライト,空,街づくり,まちづくり,戦略,トルコ,観光,帝国,ホールディングス,フェスティバル,シム,大富豪,ゲーム
```

```asc:promotionalText
妖精の煙突の上、夜明けの空へ、たった一つのバスケットから。日々を進めて資金を貯め、4つの都市にまたがる気球帝国を築こう。広告なし。
```

```asc:description
カッパドキアの夜明け、あなたの手元には小さなバスケットがひとつだけ。数シーズン後には空の半分をあなたの気球が埋めつくし、会社は4つの都市にまたがるホールディングスに成長します。『バルーンバロン』は、熱気球の会社を立ち上げて育てる経営シミュレーション＆タイクーンゲームです。

広告なし。スタミナなし。待ち時間なし。
プレイを止めるものは何もありません。画面をふさぐ広告も、なくなるスタミナも、待たされるタイマーもありません。

日々は進み、お金が貯まる
船団が大きくなり「カッパドキアの男爵」になると、早送りが解放されます。日々が自動で進み、パイロットが飛び、売上が金庫に入ります。判断が必要になるとゲームが止まってあなたを呼びます。制覇した地域はマネージャーが自動で運営し、毎日ホールディングスに送金してくれます。放置ゲーム好きには気軽に、経営ゲーム好きには奥深く。

夜明けの空を自分で操縦
いつでも自分で操縦できます。バーナーを焚き、高度ごとの風を読み、着陸場にそっと降り立とう。空でのプロポーズ、撮影フライト、精密着陸ミッションはボーナス収入に。

会社を興し、町を育てる
気球を買い、チケット価格を決め、ホテルやガイド、旅行会社と契約しよう。小さなオフィスは、格納庫、パイロット学校、工房、ホテルが並ぶひとつの町に。夜になればランタンが灯り、花火が上がります。

パイロットはみんな個性派
慎重？命知らず？それとも忠実？パイロットを雇い、育て、ベテランにしよう。ライバルはあなたのエースを引き抜こうとします。チームを守るのはあなたの仕事です。

ライバル会社を買収せよ
谷には他の気球会社もあります。合併し、価格競争を仕掛け、赤旗の日にも飛びます。市場を制し、ライバルを買収して、カッパドキアの男爵になろう。

バスケット1つからホールディングスへ
男爵になるとホールディングスを設立できます。マーケティング部門と研究開発部門、世界のオフィス、記録への挑戦、スポンサー付きの巨大な形の気球が待っています。

4つの都市、ひとつの帝国
・カッパドキア：妖精の煙突と朝日
・ルクソール：ナイル川、神殿、ナイル川クルーズ船
・ブリストル：霧の朝、エイボン渓谷、バルーンフェスティバル
・アルバカーキ：砂漠、ボックス風、バルーンフィエスタ
都市ごとに風もライバルも物語も違います。アルバカーキ、ルクソール、ブリストルはアプリ内課金「グランドツアー」で解放されます。

夜空を彩るバルーンショー
船団が大きくなったら、ある夜、すべての気球を町の上空で一斉に灯そう。バーナーが同時に輝き、その後の数日は観光客が列をなします。

気球にあなたのサインを
デザインスタジオで自分だけの気球をデザイン。模様、色、そしてハート・星・ドクロ形の気球（特別な模様と形はアプリ内課金）。やがて工房は、自社の気球を生産する工場になります。

ゲーム内のすべての絵と音はコードで作られています。カッパドキアの空があなたを待っています。
```

## Ekran görüntüsü metinleri

Sıra ve hikâye Türkçe setle aynı; her karede büyük başlık ve en çok beş kelimelik bir alt satır. Birebir çeviri değil, bu pazarın arama terimleriyle yazıldı.

| # | Başlık | Alt satır |
|---|---|---|
| 01 | 気球会社の / 社長になろう | 1機の気球から大船団へ |
| 02 | 4つの都市に / 気球帝国を | カッパドキアからバルーンフィエスタへ |
| 03 | 夜明けの空を / 自分で操縦 | リアルな熱気球フライト |
| 04 | 日々は進み / お金が貯まる | 早送りできる放置経営シミュレーション |
| 05 | 気球1機から / 大企業へ | 2日目から132日目まで |
| 06 | パイロットは / みんな個性派 | 慎重、命知らず、忠実 |
| 07 | 気球に / あなたのサインを | ハート・星・ドクロの気球 |
| 08 | ライバル会社を / 買収せよ | 戦略で市場を制する |
| 09 | 夜の町が / きらめく | オフィスがひとつの町に |
| 10 | 夜空を彩る / バルーンショー | 全機そろって夜空へ |

- 1. karedeki küçük etiket: **広告なし**
- 10. karenin imzası: **バルーンバロン · カッパドキア**
- Rozetlerdeki rakamlar, aynı karedeki gerçek uygulama ekranından:
- 04: **+€143,447** 1日の利益 · **164** 機の気球船団
- 05: 2日目 **1** 機 → 132日目 **164** 機
- 08: **99%** 市場シェア

## Uygunluk notları

- Ekranlardaki oyun görüntüleri gerçek uygulamadan (debug yapı, `DemoSetup.swift` ile kurulan bir şirket: 130 gün kurallarla oynandı, ekran görüntüsü için filo 164 balona büyütüldü, holding kasası test durumundan).
- 04: iPhone'daki şeritte 133. gün henüz uçarken çekildi; rozet o günün gerçek kazancı (+€143,447; iPad çekiminde şeritte görünüyor, simülasyon her dilde aynı).
- Hiçbir balonun üstünde yazı ya da isim yok (sponsor bantları kapalı).
- Puan, ödül, "1 numara" iddiası, fiyat ve emoji yok. "Reklamsız" doğru: oyunda reklam yok.
- 2. kare (Luksor, Bristol, Albuquerque) ve 7. kare (yıldız balon, takımyıldız deseni) uygulama içi satın alımla açılan içerik gösteriyor; açıklamada belirtildi.
