from s1_ui import add

# What the first TestFlight players stumbled on (v111.1): the flying coach, the price lesson, the show's card
add("flight.lineAlt", "%@ m", "%@ m", "%@ m", "%@ m", "%@ m", "%@ m")
add("flight.coach.goal",
    "**Your goal is the landing field:** on the right, km: %@. The arrows on the left show the wind at each height; find the layer that blows toward it.",
    "**Hedefin iniş alanı:** sağda, km: %@. Soldaki oklar her yükseklikteki rüzgârı gösterir; hedefe doğru esen katmanı bul.",
    "**Dein Ziel ist das Landefeld:** rechts, km: %@. Die Pfeile links zeigen den Wind in jeder Höhe; finde die Schicht, die dorthin weht.",
    "**Tu objetivo es el campo de aterrizaje:** a la derecha, km: %@. Las flechas de la izquierda muestran el viento a cada altura; busca la capa que sopla hacia allí.",
    "**目標は着陸場**：右へ%@ km。左の矢印は高度ごとの風。そちらへ吹く層を探そう。",
    "**목표는 착륙장입니다:** 오른쪽, km: %@. 왼쪽 화살표가 고도별 바람을 보여 줍니다. 그쪽으로 부는 층을 찾으세요.")
add("flight.coach.wrong",
    "**This wind is carrying you away from the field.** Look at the arrows on the left: climb or sink into the layer that blows toward it. The wind changes at the dashed line.",
    "**Bu rüzgâr seni hedeften uzaklaştırıyor.** Soldaki oklara bak: hedefe doğru esen katmana çık ya da in. Kesik çizgiyi geçince rüzgâr değişir.",
    "**Dieser Wind trägt dich vom Feld weg.** Schau auf die Pfeile links: Steig oder sink in die Schicht, die dorthin weht. An der gestrichelten Linie wechselt der Wind.",
    "**Este viento te aleja del campo.** Mira las flechas de la izquierda: sube o baja a la capa que sopla hacia allí. El viento cambia en la línea discontinua.",
    "**この風は着陸場から遠ざけている。** 左の矢印を見て、そちらへ吹く層まで上昇か下降を。破線を越えると風が変わる。",
    "**이 바람은 착륙장에서 멀어지게 합니다.** 왼쪽 화살표를 보고 그쪽으로 부는 층까지 오르거나 내려가세요. 점선을 넘으면 바람이 바뀝니다.")
add("flight.coach.still",
    "**You're hardly moving.** Go to another height: each layer's wind is on the left, and the tag under your basket shows the wind right where you are.",
    "**Neredeyse duruyorsun.** Başka bir yüksekliğe geç: her katmanın rüzgârı solda, sepetinin altındaki etiket de şu anki rüzgârı gösterir.",
    "**Du kommst kaum voran.** Wechsle die Höhe: Der Wind jeder Schicht steht links, und das Schild unter deinem Korb zeigt den Wind genau dort, wo du bist.",
    "**Casi no te mueves.** Cambia de altura: el viento de cada capa está a la izquierda y la etiqueta bajo tu cesta muestra el viento justo donde estás.",
    "**ほとんど進んでいない。** 高度を変えよう。各層の風は左に、バスケットの下のラベルが今いる場所の風を示す。",
    "**거의 움직이지 않고 있습니다.** 다른 고도로 가세요. 층마다의 바람은 왼쪽에, 바스켓 아래 표시가 지금 위치의 바람을 보여 줍니다.")
add("flight.coach.near",
    "**You're over the landing field!** Let go of the burner and sink slowly. Near the ground, short presses give you a soft landing.",
    "**İniş alanının üstündesin!** Brülörü bırak, yavaşça alçal. Yere yaklaşınca kısa basışlarla yumuşak in.",
    "**Du bist über dem Landefeld!** Lass den Brenner los und sink langsam. Kurz vor dem Boden sorgen kurze Stöße für eine weiche Landung.",
    "**¡Estás sobre el campo de aterrizaje!** Suelta el quemador y baja despacio. Cerca del suelo, toques cortos te dan un aterrizaje suave.",
    "**着陸場の上だ！** バーナーを離してゆっくり降下。地面が近づいたら短く押して、やさしく着地しよう。",
    "**착륙장 위에 있습니다!** 버너를 놓고 천천히 내려가세요. 땅이 가까워지면 짧게 눌러 부드럽게 착륙하세요.")
add("flight.coach.lowFuel",
    "**Fuel is running low.** Use the burner in short presses and keep some for the landing. Stay in the layer that blows toward the field.",
    "**Yakıt azalıyor.** Brülöre kısa kısa bas, yakıtı inişe sakla. Hedefe doğru esen katmanda kal.",
    "**Das Gas wird knapp.** Nutze den Brenner in kurzen Stößen und heb etwas für die Landung auf. Bleib in der Schicht, die zum Feld weht.",
    "**Queda poco combustible.** Usa el quemador a toques cortos y guarda algo para el aterrizaje. Quédate en la capa que sopla hacia el campo.",
    "**燃料が少ない。** バーナーは短く押して、着陸の分を残そう。着陸場へ吹く層にとどまろう。",
    "**연료가 부족합니다.** 버너를 짧게 눌러 착륙할 연료를 남기세요. 착륙장 쪽으로 부는 층에 머무르세요.")
add("event.rookieRepair",
    "Beginner's luck: Hezarfen knows a mechanic who will fix your balloon in one day.",
    "Acemi şansı: Hezarfen'in tanıdığı tamirci balonunu bir günde onaracak.",
    "Anfängerglück: Hezarfen kennt einen Mechaniker, der deinen Ballon an einem Tag repariert.",
    "Suerte de principiante: Hezarfen conoce a un mecánico que arreglará tu globo en un día.",
    "ビギナーズラック：ヘザルフェンの知り合いの整備士が1日で気球を直してくれる。",
    "초심자의 행운: 헤자르펜이 아는 정비사가 하루 만에 열기구를 고쳐 줍니다.")
add("hez.price",
    "Yesterday not every seat was filled, kid. The ticket price changes the tourists' minds: lower it a little and no seat stays empty. If your seats are always full, raise it and earn more. You set the price in the Ticket box at the bottom.",
    "Dün koltukların hepsi dolmadı evlat. Bilet fiyatı turistin kararını değiştirir: biraz düşürürsen boş koltuk kalmaz. Koltuklar hep doluysa da fiyatı artırıp daha çok kazanırsın. Fiyatı alttaki Bilet kutusundan ayarlarsın.",
    "Gestern blieben Plätze leer, Lehrling. Der Ticketpreis entscheidet mit: Senkst du ihn etwas, bleibt kein Platz frei. Sind deine Plätze immer voll, erhöhe ihn und verdiene mehr. Den Preis stellst du unten im Ticket-Feld ein.",
    "Ayer no se llenaron todas las plazas, aprendiz. El precio del billete hace cambiar de idea a los turistas: bájalo un poco y no quedará ninguna vacía. Si siempre se llenan, súbelo y ganarás más. El precio se ajusta en la casilla Billete de abajo.",
    "弟子よ、昨日は空席が出たな。チケット代で客の気持ちは変わる。少し下げれば空席はなくなる。いつも満席なら上げて稼げばよい。料金は下のチケット欄で設定するのだ。",
    "제자여, 어제는 빈 좌석이 남았네. 티켓 가격이 관광객의 마음을 바꾼다네. 조금 내리면 빈 좌석이 없어지고, 늘 가득 찬다면 올려서 더 벌게. 가격은 아래 티켓 칸에서 정한다네.")
add("hez.toPrice", "Set the price", "Fiyatı ayarla", "Preis einstellen", "Ajustar el precio", "料金を設定", "가격 정하기")
add("event.showDropped", "A balloon that crashed today can't go up in tonight's show. Its fee came back: %@.", "Kaza yapan balon bu gece şölene çıkamayacak. Ücreti kasana geri döndü: %@.", "Ein Ballon, der heute verunglückt ist, kann heute Nacht nicht bei der Show mitmachen. Seine Gebühr wurde erstattet: %@.", "Un globo que se accidentó hoy no podrá salir en el espectáculo de esta noche. Su tarifa se devolvió: %@.", "今日事故を起こした気球は今夜のショーに出られない。その分の費用が戻った：%@。", "오늘 사고 난 열기구는 오늘 밤 쇼에 나갈 수 없습니다. 그 비용이 돌아왔습니다: %@.")
add("event.showCancelled", "After today's accidents too few balloons are left for a show, so tonight's show is off. The other fees came back too: %@. You can hold it again once the balloons are repaired.", "Kazalar yüzünden şölene yeterli balon kalmadı, bu geceki şölen iptal. Kalan ücretler de kasana döndü: %@. Balonlar onarılınca yeniden düzenleyebilirsin.", "Nach den heutigen Unfällen sind zu wenige Ballone für eine Show übrig, die Show heute Nacht fällt aus. Auch die übrigen Gebühren wurden erstattet: %@. Sobald die Ballone repariert sind, kannst du sie erneut veranstalten.", "Tras los accidentes de hoy quedan muy pocos globos para el espectáculo, así que se cancela el de esta noche. También se devolvieron las demás tarifas: %@. Podrás organizarlo de nuevo cuando reparen los globos.", "今日の事故でショーに必要な気球が足りなくなり、今夜のショーは中止。残りの費用も戻った：%@。気球が直れば、また開ける。", "오늘 사고로 쇼에 필요한 열기구가 부족해 오늘 밤 쇼는 취소됩니다. 나머지 비용도 돌아왔습니다: %@. 열기구가 수리되면 다시 열 수 있습니다.")
add("show.openTitle", "Hold a Balloon Show", "Balon Şöleni düzenle", "Ballon-Show veranstalten", "Organizar un espectáculo de globos", "バルーンショーを開く", "열기구 쇼 열기")
add("show.intro", "One night all your balloons fire their burners over the town and put on a show in the sky, to music.", "Bir gece bütün balonların kasabanın üstünde brülörlerini yakar, müzikle gökyüzünde gösteri yapar.", "Eine Nacht lang zünden alle deine Ballone über der Stadt ihre Brenner und zeigen zur Musik eine Show am Himmel.", "Una noche todos tus globos encienden sus quemadores sobre el pueblo y montan un espectáculo con música en el cielo.", "ある夜、すべての気球が町の上でバーナーを灯し、音楽に合わせて空でショーを披露する。", "어느 밤 모든 열기구가 마을 위에서 버너를 켜고 음악에 맞춰 하늘에서 쇼를 펼칩니다.")
add("show.gainsTitle", "What does it bring?", "Ne kazandırır?", "Was bringt sie?", "¿Qué aporta?", "何が得られる？", "무엇을 얻나요?")
add("show.gainRep", "Popularity at once: +0.2★", "Popülerlik hemen: +0,2★", "Beliebtheit sofort: +0,2★", "Popularidad al instante: +0,2★", "人気がすぐに：+0.2★", "인기 즉시: +0.2★")
add("show.gainPax", "For the next 3 days, about %1$@ more tourists per balloon each day (now about %2$@ a day)", "Sonraki 3 gün her gün balon başına yaklaşık %1$@ turist daha (şimdi günde yaklaşık %2$@)", "In den nächsten 3 Tagen täglich etwa %1$@ Touristen mehr pro Ballon (jetzt etwa %2$@ pro Tag)", "Los próximos 3 días, unos %1$@ turistas más por globo cada día (ahora unos %2$@ al día)", "この先3日間、毎日気球1機あたり約%1$@人の観光客が追加（今なら1日約%2$@人）", "앞으로 3일 동안 매일 기구당 약 %1$@명의 관광객 추가 (지금은 하루 약 %2$@명)")
add("show.gainCap", "For 10 days it lifts the popularity cap, like a hotel or a guide flight", "10 gün boyunca otel ya da rehber gibi popülerlik tavanını açar", "10 Tage lang hebt sie die Beliebtheitsgrenze an, wie ein Hotel oder ein Werbeflug für Guides", "Durante 10 días levanta el tope de popularidad, como un hotel o un vuelo para guías", "10日間、ホテルやガイド招待フライトのように人気の上限を引き上げる", "10일 동안 호텔이나 가이드 비행처럼 인기 상한을 올립니다")
add("show.gainPaper", "A headline in the next morning's paper", "Ertesi sabah gazete manşeti", "Eine Schlagzeile in der Zeitung am nächsten Morgen", "Un titular en el periódico de la mañana siguiente", "翌朝の新聞の見出し", "다음 날 아침 신문 헤드라인")
add("show.gainNote", "It pays best on days when seats go empty. Days between shows: %@.", "En çok koltukların boş kaldığı günlerde kazandırır. İki şölen arası gün: %@.", "Am meisten bringt sie an Tagen mit leeren Plätzen. Tage zwischen zwei Shows: %@.", "Rinde más los días con plazas vacías. Días entre espectáculos: %@.", "空席が出ている日ほど効果が大きい。ショーの間隔（日）：%@。", "빈 좌석이 남는 날에 가장 효과가 큽니다. 쇼 사이 간격(일): %@.")
add("show.calcBalloons", "Balloons that can fly", "Uçabilen balon", "Flugbereite Ballone", "Globos que pueden volar", "飛べる気球", "날 수 있는 열기구")
add("show.calcEach", "Per balloon", "Balon başına", "Pro Ballon", "Por globo", "1機あたり", "기구당")
add("show.calcTotal", "Total: %1$@ × %2$@", "Toplam: %1$@ × %2$@", "Gesamt: %1$@ × %2$@", "Total: %1$@ × %2$@", "合計：%1$@ × %2$@", "합계: %1$@ × %2$@")
add("show.confirm", "Confirm and book: %@", "Onayla ve düzenle: %@", "Bestätigen und buchen: %@", "Confirmar y organizar: %@", "確定して開く：%@", "확인하고 열기: %@")
add("show.cancelBtn", "Not now", "Vazgeç", "Nicht jetzt", "Ahora no", "やめておく", "다음에")
add("show.doneTitle", "The show is tonight!", "Şölen bu gece!", "Die Show ist heute Nacht!", "¡El espectáculo es esta noche!", "ショーは今夜！", "쇼는 오늘 밤!")
add("show.doneBody", "When you finish today, the Balloon Show takes place over the town tonight: your balloons put on a show in the sky. Balloons: %@. You'll see it even if you've turned the night scene off.", "Bugünü tamamladığında bu gece kasabanın üstünde Balon Şöleni düzenlenecek: balonların gökyüzünde gösteri yapacak. Balon: %@. Gece sahnesini kapatmış olsan da şöleni göreceksin.", "Wenn du den heutigen Tag beendest, findet heute Nacht über der Stadt die Ballon-Show statt: Deine Ballone zeigen eine Show am Himmel. Ballone: %@. Du siehst sie auch, wenn du die Nachtszene ausgeschaltet hast.", "Cuando termines el día de hoy, esta noche se celebrará el Espectáculo de globos sobre el pueblo: tus globos darán un espectáculo en el cielo. Globos: %@. Lo verás aunque hayas desactivado la escena nocturna.", "今日を終えると、今夜町の上でバルーンショーが開かれ、あなたの気球が空でショーを披露する。気球：%@。夜のシーンをオフにしていても見られる。", "오늘을 마치면 오늘 밤 마을 위에서 열기구 쇼가 열리고, 열기구들이 하늘에서 쇼를 펼칩니다. 열기구: %@. 밤 장면을 꺼 두었어도 볼 수 있습니다.")
add("show.doneNote", "A balloon that crashes today can't go up tonight; its fee comes back. If fewer than %@ are left, the show is called off and every fee comes back.", "Bugün kaza yapan balon olursa o gece şölene çıkamaz; ücreti kasana geri döner. Uçabilen balon şu sayının altına düşerse şölen iptal olur ve bütün ücretler geri döner: %@.", "Ein Ballon, der heute verunglückt, kann heute Nacht nicht mitmachen; seine Gebühr wird erstattet. Bleiben weniger als %@, fällt die Show aus und alle Gebühren werden erstattet.", "Un globo que se accidente hoy no podrá salir esta noche; su tarifa se devuelve. Si quedan menos de %@, se cancela el espectáculo y se devuelven todas las tarifas.", "今日事故を起こした気球は今夜出られず、その分の費用は戻る。%@機を下回るとショーは中止になり、費用はすべて戻る。", "오늘 사고 난 열기구는 오늘 밤 나갈 수 없고 비용은 돌아옵니다. %@대 미만이 남으면 쇼는 취소되고 비용이 모두 돌아옵니다.")
add("show.ok", "OK", "Tamam", "OK", "Entendido", "OK", "확인")
add("flight.fieldColumn", "LANDING FIELD", "İNİŞ ALANI", "LANDEFELD", "ZONA DE ATERRIZAJE", "着陸場", "착륙장")
