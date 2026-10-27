from s1_ui import add

# Day report ticket (showReport)
add("report.stubFlew", "%1$@, seats filled: %2$@/%3$@", "%1$@, dolan koltuk: %2$@/%3$@", "%1$@, belegte Plätze: %2$@/%3$@", "%1$@, plazas ocupadas: %2$@/%3$@", "%1$@、埋まった座席：%2$@/%3$@", "%1$@, 채운 좌석: %2$@/%3$@")
add("report.stubSkipped", "%@, no flight", "%@, uçuş yapılmadı", "%@, kein Flug", "%@, sin vuelo", "%@、運航なし", "%@, 비행 없음")
add("report.cash", "Cash", "Kasa", "Kasse", "Caja", "資金", "현금")
add("ledger.missionReward", "Mission reward", "Görev ödülü", "Auftragsprämie", "Recompensa de la misión", "依頼の報酬", "임무 보상")
add("report.holdTitle", "Holding cash +%@.", "Holding kasasına +%@.", "Holding-Kasse +%@.", "Caja del holding +%@.", "ホールディングスへ+%@。", "지주회사 금고 +%@.")
add("report.holdBody",
    "%1$@ earned on autopilot; holding expenses (%2$@) were deducted. Holding cash: %3$@.",
    "%1$@ otomatik modda kazandı, holding giderleri (%2$@) düşüldü. Holding kasası: %3$@.",
    "%1$@ hat im Autopilot verdient; die Holding-Ausgaben (%2$@) sind abgezogen. Holding-Kasse: %3$@.",
    "%1$@ ganó en piloto automático; se descontaron los gastos del holding (%2$@). Caja del holding: %3$@.",
    "%1$@が自動運営で稼いだ。ホールディングス経費（%2$@）差引済み。ホールディングス残高：%3$@。",
    "자동 운영 수입 %1$@에서 지주회사 비용(%2$@)을 뺐습니다. 지주회사 금고: %3$@.")
add("report.designTitle", "Your designs are the talk of the town.", "Tasarımların konuşuluyor.", "Deine Designs sind Stadtgespräch.", "Todo el mundo habla de tus diseños.", "あなたのデザインが話題だ。", "디자인이 화제입니다.")
add("report.designBody",
    "Your patterned balloons added +%@ to your popularity today.",
    "Desenli balonların bugün popülerliğine +%@ ekledi.",
    "Deine gemusterten Ballone haben deiner Beliebtheit heute +%@ gebracht.",
    "Tus globos con diseño sumaron hoy +%@ a tu popularidad.",
    "柄入りの気球が今日、人気を+%@押し上げた。",
    "무늬 열기구가 오늘 인기를 +%@ 올렸습니다.")
add("report.adTitle", "The ads you're paid for count too.", "Parasını aldığın reklamların da bir bedeli var.", "Die Werbung, für die du kassierst, wirkt auch.", "Los anuncios que te pagan también cuentan.", "お金をもらっている広告にも代償がある。", "광고 수입에도 대가가 있습니다.")
add("report.adBody",
    "Today the ads on your balloons lowered your popularity by %@.",
    "Bugün balonlarındaki reklamlar popülerliğini %@ düşürdü.",
    "Heute hat die Werbung auf deinen Ballonen deine Beliebtheit um %@ gesenkt.",
    "Hoy los anuncios de tus globos bajaron tu popularidad en %@.",
    "今日、気球の広告で人気が%@下がった。",
    "오늘 열기구 광고 때문에 인기가 %@ 떨어졌습니다.")
add("report.overTitle", "All your balloons are gone.", "Tüm balonların elden çıktı.", "Alle deine Ballone sind weg.", "Has perdido todos tus globos.", "気球はすべて失われた。", "열기구를 모두 잃었습니다.")
add("report.overBody", "%@ has closed.", "%@ kapandı.", "%@ hat geschlossen.", "%@ ha cerrado.", "%@は廃業した。", "%@ 폐업.")
add("report.newCompany", "Found a new company", "Yeni şirket kur", "Neue Firma gründen", "Fundar una nueva empresa", "新しい会社を立ち上げる", "새 회사 세우기")
add("report.monoTitle", "You're the only company in the %@ sky.", "%@ göğünde tek şirket sensin.", "Du bist die einzige Firma am Himmel über %@.", "Eres la única empresa en el cielo de %@.", "%@の空を飛ぶ会社はあなただけだ。", "%@ 하늘에 남은 회사는 당신뿐입니다.")
add("report.monoBody", "You set the price now.", "Fiyatı artık sen belirliyorsun.", "Den Preis bestimmst jetzt du.", "Ahora el precio lo pones tú.", "これからはあなたが価格を決める。", "이제 가격은 당신이 정합니다.")
add("report.tomorrow", "Tomorrow: %1$@, surface wind %2$@ km/h.", "Yarın: %1$@, yer rüzgârı %2$@ km/sa.", "Morgen: %1$@, Bodenwind %2$@ km/h.", "Mañana: %1$@, viento en superficie %2$@ km/h.", "明日：%1$@、地上風速%2$@ km/h。", "내일: %1$@, 지상 풍속 %2$@ km/h.")
add("report.nextDay", "On to the morning of day %@", "Gün %@ sabahına geç", "Weiter zum Morgen von Tag %@", "Pasar a la mañana del día %@", "%@日目の朝へ", "%@일차 아침으로")

# Popularity chart (showRepChart)
add("repChart.title", "Your popularity: %@", "Popülerliğin: %@", "Deine Beliebtheit: %@", "Tu popularidad: %@", "あなたの人気：%@", "당신의 인기: %@")
add("repChart.empty",
    "Play a few days and you'll see here how your popularity changes from day to day.",
    "Birkaç gün oynadıktan sonra burada popülerliğinin günden güne nasıl değiştiğini göreceksin.",
    "Spiel ein paar Tage, dann siehst du hier, wie sich deine Beliebtheit von Tag zu Tag ändert.",
    "Juega unos días y aquí verás cómo cambia tu popularidad de un día a otro.",
    "数日プレイすると、ここで人気の日々の変化が見られる。",
    "며칠 플레이하면 여기서 인기가 날마다 어떻게 변하는지 볼 수 있습니다.")
add("repChart.chartLabel", "Popularity by day", "Günlere göre popülerlik", "Beliebtheit nach Tagen", "Popularidad por día", "日ごとの人気", "날짜별 인기")
add("repChart.delta", "Change since day %1$@: %2$@", "%1$@. günden bu yana değişim: %2$@", "Veränderung seit Tag %1$@: %2$@", "Cambio desde el día %1$@: %2$@", "%1$@日目からの変化：%2$@", "%1$@일차 이후 변화: %2$@")
add("repChart.crisisTitle", "Your popularity is below %@.", "Popülerliğin %@ altında.", "Deine Beliebtheit liegt unter %@.", "Tu popularidad está por debajo de %@.", "人気が%@を下回っている。", "인기가 %@ 아래입니다.")
add("repChart.crisisBody",
    "Tourists avoid you and passengers are very hard to find. The actions below help you recover.",
    "Turistler seni seçmekten kaçınıyor, yolcu bulmak çok zor. Aşağıdakilerle toparlayabilirsin.",
    "Touristen meiden dich, Passagiere sind kaum zu finden. Mit den Maßnahmen unten erholst du dich.",
    "Los turistas evitan elegirte y cuesta mucho encontrar pasajeros. Con las acciones de abajo puedes recuperarte.",
    "観光客に避けられ、乗客がほとんど集まらない。下の手段で立て直そう。",
    "관광객이 당신을 피해서 승객을 찾기가 매우 어렵습니다. 아래 방법으로 회복할 수 있습니다.")
add("repChart.hint",
    "Popularity rises with perfect landings; accidents, far landings, cancellations and balloon ads lower it. High popularity brings extra tourists. Extra tourists today: about %1$@. Above %2$@, expectations rise and popularity wears down a little every day.",
    "Popülerlik kusursuz inişlerle yükselir; kazalar, uzak inişler, iptaller ve balon reklamları düşürür. Yüksek popülerlik ekstra turist getirir. Bugünkü ekstra turist: yaklaşık %1$@. %2$@ üzerinde beklentiler yükselir, popülerlik her gün biraz aşınır.",
    "Beliebtheit steigt mit perfekten Landungen; Unfälle, Landungen weit vom Ziel, Absagen und Ballonwerbung senken sie. Hohe Beliebtheit bringt zusätzliche Touristen. Zusätzliche Touristen heute: etwa %1$@. Über %2$@ steigen die Erwartungen, und die Beliebtheit bröckelt jeden Tag ein wenig.",
    "La popularidad sube con aterrizajes perfectos; los accidentes, los aterrizajes lejanos, las cancelaciones y los anuncios en globos la bajan. Una popularidad alta trae turistas extra. Turistas extra hoy: unos %1$@. Por encima de %2$@ las expectativas suben y la popularidad se desgasta un poco cada día.",
    "人気は完璧な着陸で上がり、事故・遠い着陸・キャンセル・気球広告で下がる。人気が高いと観光客が増える。今日の追加観光客：約%1$@。%2$@を超えると期待が高まり、人気は毎日少しずつ下がる。",
    "인기는 완벽한 착륙으로 오르고 사고, 먼 착륙, 취소, 열기구 광고로 떨어집니다. 인기가 높으면 관광객이 더 옵니다. 오늘 추가 관광객: 약 %1$@. %2$@ 이상에서는 기대치가 높아져 인기가 매일 조금씩 깎입니다.")
add("repChart.recover", "Recover your popularity", "Popülerliğini toparla", "Beliebtheit zurückgewinnen", "Recupera tu popularidad", "人気を立て直す", "인기 회복하기")
add("repChart.hotels", "Make hotel deals", "Otellerle anlaş", "Hotelverträge schließen", "Firma acuerdos con hoteles", "ホテルと提携する", "호텔과 제휴하기")
add("repChart.hotelsBody",
    "Hotels recommend you to their guests, bringing popularity and tourists every day.",
    "Oteller misafirlerine seni önerir, her gün popülerlik ve turist getirir.",
    "Hotels empfehlen dich ihren Gästen und bringen jeden Tag Beliebtheit und Touristen.",
    "Los hoteles te recomiendan a sus huéspedes y te traen popularidad y turistas cada día.",
    "ホテルが宿泊客にあなたを勧め、毎日人気と観光客をもたらす。",
    "호텔이 투숙객에게 당신을 추천해 매일 인기와 관광객을 가져다줍니다.")
add("repChart.hotelsCount", "Partner hotels: %@.", "Anlaştığın otel: %@.", "Partnerhotels: %@.", "Hoteles asociados: %@.", "提携ホテル：%@。", "제휴 호텔: %@.")
add("repChart.hotelsNone", "No deals yet.", "Henüz anlaşman yok.", "Noch keine Verträge.", "Aún no tienes acuerdos.", "まだ提携はない。", "아직 제휴가 없습니다.")
add("repChart.hotelsButton", "Hotels", "Oteller", "Hotels", "Hoteles", "ホテル", "호텔")
add("repChart.reviews", "Passenger reviews", "Yolcu yorumları", "Passagierbewertungen", "Reseñas de pasajeros", "乗客のレビュー", "승객 후기")
add("repChart.bonusTitle", "Your popularity is %@.", "Popülerliğin %@.", "Deine Beliebtheit liegt bei %@.", "Tu popularidad es %@.", "人気は%@。", "인기는 %@입니다.")
add("repChart.bonusBody",
    "High popularity brings extra passengers whatever your rivals do, up to %1$@ of your seats. Extra passengers today at this price: about %2$@. Below %3$@ the effect is gone; at %4$@ it reaches %5$@.",
    "Yüksek popülerlik, rakiplerden bağımsız ekstra yolcu getirir: koltuklarının en fazla %1$@ kadarı. Bugün bu fiyatla ekstra yolcu: yaklaşık %2$@. %3$@ altında bu etki sıfırlanır, %4$@ seviyesinde %5$@ olur.",
    "Hohe Beliebtheit bringt zusätzliche Passagiere, egal was die Konkurrenz tut: bis zu %1$@ deiner Plätze. Zusätzliche Passagiere heute zu diesem Preis: etwa %2$@. Unter %3$@ entfällt der Effekt, bei %4$@ erreicht er %5$@.",
    "Una popularidad alta trae pasajeros extra hagan lo que hagan tus rivales: hasta el %1$@ de tus plazas. Pasajeros extra hoy a este precio: unos %2$@. Por debajo de %3$@ el efecto desaparece; con %4$@ llega al %5$@.",
    "人気が高いと、ライバルに関係なく乗客が増える（座席の最大%1$@）。この価格での今日の追加乗客：約%2$@。%3$@未満では効果なし、%4$@で%5$@に達する。",
    "인기가 높으면 경쟁사와 상관없이 승객이 더 옵니다(좌석의 최대 %1$@). 이 가격에서 오늘 추가 승객: 약 %2$@. %3$@ 미만이면 효과가 없고 %4$@에서 %5$@에 이릅니다.")
add("repChart.rating", "Your passenger rating, which is your popularity", "Yolcu puanın, yani popülerliğin", "Deine Passagierbewertung, also deine Beliebtheit", "La nota que te dan los pasajeros: tu popularidad", "乗客の評価＝あなたの人気", "승객 평점, 즉 당신의 인기")
add("repChart.noReviews",
    "Your passengers will start writing reviews after your first flight.",
    "İlk uçuşundan sonra yolcuların yorum yazmaya başlayacak.",
    "Nach deinem ersten Flug schreiben deine Passagiere Bewertungen.",
    "Tras tu primer vuelo, tus pasajeros empezarán a escribir reseñas.",
    "最初のフライトの後、乗客がレビューを書き始める。",
    "첫 비행이 끝나면 승객들이 후기를 쓰기 시작합니다.")
