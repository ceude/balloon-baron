from s1_ui import add

# v124.6: why passengers come (price sheet), why the stars moved (report), seat goals, the price lesson.
add("goal.seats", "Seats in the fleet: %@", "Filoda koltuk: %@", "Sitzplätze in der Flotte: %@", "Plazas en la flota: %@", "保有座席：%@席", "보유 좌석: %@석")

add("why.popularity", "Popularity %1$@ · rivals %2$@", "Popülerlik %1$@ · rakipler %2$@", "Beliebtheit %1$@ · Konkurrenz %2$@", "Popularidad %1$@ · rivales %2$@", "人気 %1$@ · ライバル %2$@", "인기 %1$@ · 경쟁사 %2$@")
add("why.interest", "tourist interest %@", "turist ilgisi %@", "Interesse der Touristen %@", "interés turístico %@", "観光客の関心 %@", "관광객 관심 %@")
add("why.equal", "equal interest", "eşit ilgi", "gleiches Interesse", "mismo interés", "関心は互角", "관심 비슷함")
add("why.tourists", "Tourists today", "Bugünkü turist", "Touristen heute", "Turistas hoy", "今日の観光客", "오늘의 관광객")
add("why.fiesta", "Fiesta", "Fiesta", "Fiesta", "Fiesta", "フィエスタ", "피에스타")
add("why.festival", "Festival", "Festival", "Festival", "Festival", "フェスティバル", "축제")
add("why.winter", "Winter", "Kış", "Winter", "Invierno", "冬", "겨울")
add("why.flag", "%@", "%@", "%@", "%@", "%@", "%@")
add("why.sales", "Booking office", "Satış ofisi", "Verkaufsbüro", "Oficina de ventas", "予約所", "예약 사무소")
add("why.holding", "Holding investments", "Holding yatırımları", "Holding-Investitionen", "Inversiones del holding", "ホールディングスの投資", "지주회사 투자")
add("why.pax", "+%@ passengers", "+%@ yolcu", "+%@ Passagiere", "+%@ pasajeros", "+%@人", "+%@명")

add("report.repTitle", "Popularity %1$@ → %2$@", "Popülerlik %1$@ → %2$@", "Beliebtheit %1$@ → %2$@", "Popularidad %1$@ → %2$@", "人気 %1$@ → %2$@", "인기 %1$@ → %2$@")
for k, en, tr, de, es, ja, ko in [
    ("cancelled", "Cancelled flight", "İptal edilen uçuş", "Abgesagter Flug", "Vuelo cancelado", "欠航", "취소된 비행"),
    ("traits", "Your pilots' traits", "Pilotların özellikleri", "Eigenschaften deiner Piloten", "Rasgos de tus pilotos", "パイロットの個性", "조종사 특성"),
    ("ads", "Balloon ads", "Balon reklamları", "Ballonwerbung", "Anuncios en globos", "気球広告", "열기구 광고"),
    ("mission", "Mission", "Görev", "Auftrag", "Misión", "依頼", "임무"),
    ("moment", "A moment in flight", "Uçuştaki güzel an", "Ein schöner Moment im Flug", "Un buen momento en vuelo", "フライトの名場面", "비행 중 멋진 순간"),
    ("perfect", "Perfect landing", "Kusursuz iniş", "Perfekte Landung", "Aterrizaje perfecto", "完璧な着陸", "완벽한 착륙"),
    ("good", "Good landing", "Düzgün iniş", "Gute Landung", "Buen aterrizaje", "上手な着陸", "좋은 착륙"),
    ("far", "Landed far from the target", "Hedeften uzağa iniş", "Weit vom Ziel gelandet", "Aterrizaje lejos del objetivo", "目標から遠い着陸", "목표에서 먼 착륙"),
    ("farm", "The farmer's complaint", "Çiftçinin şikâyeti", "Beschwerde des Bauern", "Queja del granjero", "農家の苦情", "농부의 항의"),
    ("mud", "Landed in the mud", "Çamura iniş", "Landung im Schlamm", "Aterrizaje en el barro", "泥への着陸", "진흙 착륙"),
    ("airspace", "Airspace violation", "Hava sahası ihlali", "Luftraumverletzung", "Infracción del espacio aéreo", "空域違反", "공역 침범"),
    ("pilotsSafe", "Your pilots' safe flights", "Pilotların güvenli uçuşları", "Sichere Flüge deiner Piloten", "Vuelos seguros de tus pilotos", "パイロットの安全な飛行", "조종사들의 안전 비행"),
    ("hard", "Hard landing", "Sert iniş", "Harte Landung", "Aterrizaje brusco", "ハードランディング", "거친 착륙"),
    ("crash", "Accident", "Kaza", "Unfall", "Accidente", "事故", "사고"),
    ("pilotAccident", "A pilot's accident", "Pilot kazası", "Unfall eines Piloten", "Accidente de un piloto", "パイロットの事故", "조종사 사고"),
    ("hotels", "Hotel deals", "Otel anlaşmaları", "Hotelverträge", "Acuerdos con hoteles", "ホテル契約", "호텔 계약"),
    ("drift", "Drifts back to average", "Ortalamaya dönüş", "Pendelt sich beim Durchschnitt ein", "Vuelve poco a poco a la media", "時間とともに平均へ", "시간이 지나며 평균으로"),
    ("xl", "Giant balloon", "Dev balon", "Riesenballon", "Globo gigante", "巨大気球", "대형 열기구"),
    ("designs", "Your balloon designs", "Balon tasarımların", "Deine Ballondesigns", "Tus diseños de globos", "気球のデザイン", "열기구 디자인"),
    ("glow", "Night Glow", "Gece Işıltısı", "Night Glow", "Night Glow", "ナイトグロー", "나이트 글로"),
    ("show", "Balloon Show", "Balon Şöleni", "Ballonshow", "Espectáculo de globos", "バルーンショー", "열기구 쇼"),
    ("prCap", "Needs promotion (guides, hotels)", "Tanıtım eksik (rehber, otel)", "Es fehlt Werbung (Reiseleiter, Hotels)", "Falta promoción (guías, hoteles)", "宣伝不足（ガイド、ホテル）", "홍보 부족(가이드, 호텔)"),
    ("absent", "The founder didn't fly", "Kurucu sepete binmedi", "Der Gründer flog nicht mit", "El fundador no voló", "創業者が乗らなかった", "창업자가 비행하지 않음"),
    ("influencer", "Influencer post", "Influencer paylaşımı", "Influencer-Post", "Publicación del influencer", "インフルエンサーの投稿", "인플루언서 게시물"),
]:
    add("repWhy." + k, en, tr, de, es, ja, ko)

add("tut.priceAgain", "No more passengers yet: tap − once more.", "Yolcu henüz artmadı: − düğmesine bir kez daha bas.", "Noch nicht mehr Passagiere: Tippe noch einmal auf −.", "Aún no hay más pasajeros: toca − una vez más.", "まだ乗客は増えていない。もう一度−を押そう。", "아직 승객이 늘지 않았어요. −를 한 번 더 누르세요.")

add("tip.priceRep.short",
 "Yesterday seats stayed empty, kid: not because of the price, but because your stars are falling.",
 "Dün koltuklar boş kaldı evlat: fiyat değil, düşen yıldızların yüzünden.",
 "Gestern blieben Plätze leer, Lehrling: nicht wegen des Preises, sondern wegen deiner sinkenden Sterne.",
 "Ayer quedaron plazas vacías, aprendiz: no por el precio, sino porque tus estrellas han bajado.",
 "昨日は席が空いたな、弟子よ。値段のせいではない、星が下がったせいだ。",
 "어제는 빈 좌석이 남았네, 제자여. 가격 탓이 아니라 별점이 떨어진 탓일세.")
add("hez.priceRep",
 "Not every seat filled yesterday, kid, but your price is fair. The problem is popularity: accidents and hard landings pulled your stars down, and tourists go to the company with more stars first. Soft landings, completed missions and guides bring the stars back. Lowering the price helps only a little.",
 "Dün koltukların hepsi dolmadı evlat, ama fiyatın uygun. Sorun popülerlikte: kazalar ve sert inişler yıldızlarını düşürdü, turistler önce yıldızı yüksek şirkete gider. Yumuşak inişler, tamamlanan görevler ve rehberler yıldızı geri getirir. Fiyatı düşürmek ancak biraz işe yarar.",
 "Gestern war nicht jeder Platz besetzt, Lehrling, aber dein Preis ist fair. Das Problem ist die Beliebtheit: Unfälle und harte Landungen haben deine Sterne gedrückt, und Touristen gehen zuerst zur Firma mit mehr Sternen. Sanfte Landungen, erfüllte Aufträge und Reiseleiter bringen die Sterne zurück. Den Preis zu senken hilft nur wenig.",
 "Ayer no se llenaron todas las plazas, aprendiz, pero tu precio es justo. El problema es la popularidad: los accidentes y los aterrizajes bruscos bajaron tus estrellas, y los turistas van primero a la empresa con más estrellas. Los aterrizajes suaves, las misiones cumplidas y los guías traen las estrellas de vuelta. Bajar el precio ayuda poco.",
 "昨日は全席が埋まらなかったな、弟子よ。だが値段は手頃だ。問題は人気だ。事故やハードランディングで星が下がり、観光客は星の多い会社を先に選ぶ。柔らかな着陸、やり遂げた依頼、それにガイドが星を取り戻してくれる。値下げはあまり効かない。",
 "어제는 자리가 다 차지 않았네, 제자여. 하지만 가격은 적당하다네. 문제는 인기일세. 사고와 거친 착륙으로 별점이 떨어졌고, 관광객은 별점이 높은 회사부터 찾지. 부드러운 착륙, 완수한 임무, 가이드가 별점을 되찾아 준다네. 가격을 내려 봐야 별 도움이 안 되네.")
add("tip.priceRiv.short",
 "Yesterday seats stayed empty, kid: there were more seats in the sky than tourists.",
 "Dün koltuklar boş kaldı evlat: gökyüzünde turistten çok koltuk vardı.",
 "Gestern blieben Plätze leer, Lehrling: Am Himmel gab es mehr Plätze als Touristen.",
 "Ayer quedaron plazas vacías, aprendiz: había más plazas en el cielo que turistas.",
 "昨日は席が空いたな、弟子よ。空には観光客より多くの席があった。",
 "어제는 빈 좌석이 남았네, 제자여. 하늘에 관광객보다 좌석이 더 많았지.")
add("hez.priceRiv",
 "Not every seat filled yesterday, kid. Your price and your stars are both fine, but there were more seats in the sky than tourists. Price a little below the rivals, or sign a guide or a hotel deal, and the tourists will come to you.",
 "Dün koltukların hepsi dolmadı evlat. Fiyatın da yıldızların da iyi; ama gökyüzünde turistten çok koltuk vardı. Rakiplerden biraz ucuz olursan ya da bir rehber veya otelle anlaşırsan turist sana gelir.",
 "Gestern war nicht jeder Platz besetzt, Lehrling. Dein Preis und deine Sterne sind gut, aber am Himmel gab es mehr Plätze als Touristen. Ein wenig billiger als die Konkurrenz zu sein oder ein Reiseleiter- oder Hotelvertrag bringt dir die Touristen.",
 "Ayer no se llenaron todas las plazas, aprendiz. Tu precio y tus estrellas están bien, pero había más plazas en el cielo que turistas. Ser un poco más barato que los rivales, o un acuerdo con un guía o un hotel, te traen a los turistas.",
 "昨日は全席が埋まらなかったな、弟子よ。値段も星も悪くない。だが空には観光客より多くの席があった。ライバルより少し安くするか、ガイドやホテルと契約すれば、観光客はお前のところに来る。",
 "어제는 자리가 다 차지 않았네, 제자여. 가격도 별점도 괜찮다네. 하지만 하늘에 관광객보다 좌석이 더 많았지. 경쟁사보다 조금 싸게 하거나, 가이드나 호텔과 계약하면 관광객이 자네에게 온다네.")
