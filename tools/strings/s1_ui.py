# key: (en, tr, de, es, ja, ko)
S = {}
def add(key, en, tr, de, es, ja, ko):
    S[key] = dict(en=en, tr=tr, de=de, es=es, ja=ja, ko=ko)

# Setup
add("setup.title", "Found your balloon company", "Balon şirketini kur", "Gründe deine Ballonfirma", "Funda tu empresa de globos", "気球会社を立ち上げよう", "열기구 회사를 세우세요")
add("setup.subtitle", "Cappadocia's sky is waiting. What will tourists call you?", "Kapadokya'nın göğü seni bekliyor. Turistler sana ne diyecek?", "Der Himmel über Kappadokien wartet. Wie sollen dich die Touristen nennen?", "El cielo de Capadocia te espera. ¿Cómo te llamarán los turistas?", "カッパドキアの空が待っている。観光客にどう呼ばれたい？", "카파도키아의 하늘이 기다립니다. 관광객들이 당신을 뭐라고 부를까요?")
add("setup.placeholder", "Company name", "Şirket adı", "Firmenname", "Nombre de la empresa", "会社名", "회사 이름")
add("setup.color", "Balloon colors", "Balon renklerin", "Ballonfarben", "Colores del globo", "気球の色", "열기구 색상")
add("setup.start", "Take off", "Havalan", "Abheben", "Despegar", "出発", "이륙")

# HUD and home
add("hud.day", "Day %@", "Gün %@", "Tag %@", "Día %@", "%@日目", "%@일차")
add("flag.green", "Green flag", "Yeşil bayrak", "Grüne Flagge", "Bandera verde", "緑の旗", "녹색 깃발")
add("flag.yellow", "Yellow flag", "Sarı bayrak", "Gelbe Flagge", "Bandera amarilla", "黄色の旗", "노란 깃발")
add("flag.red", "Red flag", "Kırmızı bayrak", "Rote Flagge", "Bandera roja", "赤い旗", "빨간 깃발")
add("flag.note.green", "Good to fly, light winds.", "Uçuşa uygun, rüzgâr hafif.", "Gutes Flugwetter, leichter Wind.", "Buen día para volar, viento suave.", "飛行に適した日。風は穏やか。", "비행하기 좋은 날, 바람이 약합니다.")
add("flag.note.yellow", "You may fly, but accident risk and insurance premiums are high.", "Uçabilirsin ama kaza riski ve sigorta primleri yüksek.", "Du darfst fliegen, aber Unfallrisiko und Versicherungsprämien sind hoch.", "Puedes volar, pero el riesgo de accidente y las primas del seguro son altos.", "飛べるが、事故リスクと保険料が高い。", "비행은 가능하지만 사고 위험과 보험료가 높습니다.")
add("flag.note.red", "Flying is banned. You might get caught, and insurance pays nothing.", "Uçuş yasak. Kalkarsan yakalanabilirsin ve sigorta hiçbir şeyi ödemez.", "Fliegen verboten. Du könntest erwischt werden, und die Versicherung zahlt nichts.", "Volar está prohibido. Te pueden descubrir y el seguro no paga nada.", "飛行禁止。見つかる可能性があり、保険は一切払われない。", "비행 금지. 적발될 수 있고 보험은 아무것도 보상하지 않습니다.")
add("home.wind", "Surface wind: %@ km/h", "Yer rüzgârı: %@ km/sa", "Bodenwind: %@ km/h", "Viento en superficie: %@ km/h", "地上風速：%@ km/h", "지상 풍속: %@ km/h")
add("home.winter", "Winter: fewer tourists", "Kış: turist az", "Winter: weniger Touristen", "Invierno: menos turistas", "冬：観光客が少ない", "겨울: 관광객 감소")
add("home.price", "Ticket price", "Bilet fiyatı", "Ticketpreis", "Precio del billete", "チケット価格", "티켓 가격")
add("home.tourists", "Tourists today", "Bugünkü turist", "Touristen heute", "Turistas hoy", "今日の観光客", "오늘의 관광객")
add("home.seats", "Your seats", "Koltukların", "Deine Plätze", "Tus plazas", "自社の座席", "내 좌석")
add("home.rivalSeats", "Rival seats", "Rakip koltukları", "Plätze der Konkurrenz", "Plazas rivales", "ライバルの座席", "경쟁사 좌석")
add("home.mission", "Special request: %1$@ (%2$@)", "Özel istek: %1$@ (%2$@)", "Sonderwunsch: %1$@ (%2$@)", "Petición especial: %1$@ (%2$@)", "特別依頼：%1$@（%2$@）", "특별 요청: %1$@ (%2$@)")
add("home.missionSelf", "Only you can take this one: fly the flagship yourself.", "Bu görevi sadece sen yapabilirsin: amiral balonunu kendin uçur.", "Das kannst nur du übernehmen: Flieg das Flaggschiff selbst.", "Solo tú puedes encargarte: pilota tú el globo insignia.", "この依頼はあなたにしかできない。旗艦を自分で飛ばそう。", "이 임무는 당신만 할 수 있습니다. 기함을 직접 조종하세요.")
add("home.fly", "Fly", "Uç", "Fliegen", "Volar", "飛ぶ", "비행")
add("home.send", "Send balloons", "Balonları gönder", "Ballone starten", "Enviar globos", "気球を出す", "열기구 보내기")
add("home.skip", "Skip today", "Bugünü pas geç", "Heute aussetzen", "Saltar hoy", "今日は休む", "오늘은 쉬기")
add("home.license", "Pilot license · days left: %@", "Pilot lisansı: %@ gün kaldı", "Pilotenlizenz: noch %@ Tage", "Licencia de piloto: quedan %@ días", "操縦免許：残り%@日", "조종 면허: %@일 남음")
add("home.licenseExpired", "Your license has expired: your other balloons are grounded. Fly the flagship yourself today (free renewal flight) or pay %@ to renew.", "Lisansın doldu: diğer balonların yerde. Bugün amiral balonunu kendin uçur (ücretsiz yenileme uçuşu) ya da %@ ödeyip yenile.", "Deine Lizenz ist abgelaufen: Deine anderen Ballone bleiben am Boden. Flieg heute selbst das Flaggschiff (kostenloser Erneuerungsflug) oder zahle %@.", "Tu licencia ha caducado: tus otros globos están en tierra. Pilota hoy tú mismo el globo insignia (vuelo de renovación gratuito) o paga %@ para renovarla.", "免許が切れたため、ほかの気球は飛べない。今日、旗艦を自分で飛ばす（無料の更新フライト）か、%@を払って更新しよう。", "면허가 만료되어 다른 열기구는 운항할 수 없습니다. 오늘 기함을 직접 조종하거나(무료 갱신 비행) %@ 비용을 내고 갱신하세요.")
add("home.renew", "Pay to renew", "Ödeyip yenile", "Gegen Gebühr erneuern", "Pagar y renovar", "支払って更新", "비용 내고 갱신")
add("home.founderBonus", "Flying with the founder: passengers pay +30%.", "Kurucuyla uçuş: yolcular %30 fazla öder.", "Flug mit dem Gründer: Passagiere zahlen 30 % mehr.", "Volar con el fundador: los pasajeros pagan un 30 % más.", "創業者のフライト：乗客は30%増しで払う。", "창업자와 함께하는 비행: 승객이 30% 더 냅니다.")
add("home.absent", "Days since you last flew: %@. Passengers miss the founder; popularity is falling.", "Son uçuşundan bu yana geçen gün: %@. Yolcular kurucuyu arıyor, popülerlik düşüyor.", "Tage seit deinem letzten Flug: %@. Die Passagiere vermissen den Gründer, die Beliebtheit sinkt.", "Días desde tu último vuelo: %@. Los pasajeros echan de menos al fundador y la popularidad baja.", "最後に飛んでからの日数：%@。乗客は創業者を恋しがり、人気が下がっている。", "마지막 비행 후 지난 날: %@. 승객들이 창업자를 찾고 있어 인기가 떨어지고 있습니다.")
add("home.redConfirm", "Fly on a red flag?", "Kırmızı bayrakta uçulsun mu?", "Bei roter Flagge fliegen?", "¿Volar con bandera roja?", "赤い旗の日に飛ぶ？", "빨간 깃발인데 비행할까요?")
add("home.redConfirmBody", "35%% chance of a %@ fine and a strike. Insurance won't pay for anything.", "%%35 ihtimalle %@ ceza ve uyarı. Sigorta hiçbir şeyi ödemez.", "35 %% Risiko einer Strafe von %@ und einer Verwarnung. Die Versicherung zahlt nichts.", "35 %% de probabilidad de una multa de %@ y un aviso. El seguro no paga nada.", "35%%の確率で%@の罰金と警告。保険は一切払われない。", "35%% 확률로 %@ 벌금과 경고. 보험은 아무것도 보상하지 않습니다.")
add("home.redFly", "Fly anyway", "Yine de uç", "Trotzdem fliegen", "Volar igualmente", "それでも飛ぶ", "그래도 비행")
add("common.cancel", "Cancel", "Vazgeç", "Abbrechen", "Cancelar", "キャンセル", "취소")

# Flight placeholder
add("flight.title", "In the basket", "Sepettesin", "Im Korb", "En la cesta", "バスケットの中", "바스켓 안")
add("flight.pax", "Passengers with you: %@", "Seninle uçan yolcu: %@", "Passagiere an Bord: %@", "Pasajeros contigo: %@", "同乗客：%@人", "함께 탄 승객: %@명")
add("flight.placeholder", "The flight scene arrives in the next build. For now, pick how the landing went.", "Uçuş sahnesi bir sonraki sürümde geliyor. Şimdilik inişin nasıl geçtiğini seç.", "Die Flugszene kommt im nächsten Build. Wähle vorerst, wie die Landung lief.", "La escena de vuelo llega en la próxima versión. Por ahora, elige cómo fue el aterrizaje.", "飛行シーンは次のビルドで追加予定。今は着陸の結果を選ぼう。", "비행 장면은 다음 빌드에 추가됩니다. 지금은 착륙 결과를 고르세요.")
add("flight.missionDone", "Mission completed", "Görev tamamlandı", "Auftrag erfüllt", "Misión cumplida", "依頼達成", "임무 완료")
add("landing.perfect", "Perfect landing", "Kusursuz iniş", "Perfekte Landung", "Aterrizaje perfecto", "完璧な着陸", "완벽한 착륙")
add("landing.good", "Good landing", "İyi iniş", "Gute Landung", "Buen aterrizaje", "良い着陸", "좋은 착륙")
add("landing.far", "Far from target", "Hedeften uzak", "Weit vom Ziel", "Lejos del objetivo", "目標から遠い", "목표에서 멀리")
add("landing.hard", "Hard landing", "Sert iniş", "Harte Landung", "Aterrizaje brusco", "ハードランディング", "거친 착륙")
add("landing.crash", "Hit a fairy chimney", "Peribacasına çarptı", "Feenkamin gerammt", "Choque con una chimenea de hadas", "妖精の煙突に激突", "요정의 굴뚝에 충돌")
add("landing.cancel", "Cancel the flight", "Uçuştan vazgeç", "Flug absagen", "Cancelar el vuelo", "フライトを中止", "비행 취소")

# Report
add("report.title", "Flight log", "Uçuş defteri", "Flugbuch", "Cuaderno de vuelo", "フライトログ", "비행 일지")
add("report.passengers", "Passengers", "Yolcu", "Passagiere", "Pasajeros", "乗客", "승객")
add("report.seats", "Seats", "Koltuk", "Plätze", "Plazas", "座席", "좌석")
add("report.skipped", "Grounded today", "Bugün yerde kaldın", "Heute am Boden", "Hoy en tierra", "今日は地上待機", "오늘은 지상 대기")
add("report.income", "Income", "Gelir", "Einnahmen", "Ingresos", "収入", "수입")
add("report.costs", "Costs", "Gider", "Kosten", "Gastos", "支出", "지출")
add("report.net", "Net", "Net", "Netto", "Neto", "純利益", "순이익")
add("report.events", "Today", "Bugün", "Heute", "Hoy", "今日の出来事", "오늘")
add("report.rivals", "In the valley", "Vadide", "Im Tal", "En el valle", "谷のニュース", "계곡 소식")
add("report.next", "Next morning", "Ertesi sabah", "Nächster Morgen", "A la mañana siguiente", "翌朝へ", "다음 날 아침")
for k, v in {
 "tickets": ("Tickets", "Bilet", "Tickets", "Billetes", "チケット", "티켓"),
 "founderBonus": ("Founder's flight bonus", "Kurucu uçuşu primi", "Gründerflug-Aufschlag", "Extra por volar con el fundador", "創業者フライト割増", "창업자 비행 할증"),
 "hotelIncome": ("Hotel rooms", "Otel odaları", "Hotelzimmer", "Habitaciones de hotel", "ホテル客室収入", "호텔 객실"),
 "mission": ("Mission: %@", "Görev: %@", "Auftrag: %@", "Misión: %@", "依頼：%@", "임무: %@"),
 "ads": ("Balloon ads", "Balon reklamı", "Ballonwerbung", "Publicidad en globos", "気球広告", "열기구 광고"),
 "tips": ("Tips", "Bahşiş", "Trinkgeld", "Propinas", "チップ", "팁"),
 "insurancePaid": ("Insurance payout", "Sigorta ödemesi", "Versicherungsleistung", "Pago del seguro", "保険金", "보험금"),
 "seizure": ("Bank sale of a balloon", "Bankanın balon satışı", "Ballonverkauf durch die Bank", "Venta del globo por el banco", "銀行による気球売却", "은행 압류 매각"),
 "fuel": ("Fuel", "Yakıt", "Treibstoff", "Combustible", "燃料", "연료"),
 "wages": ("Pilot wages", "Pilot maaşları", "Pilotengehälter", "Sueldos de pilotos", "パイロット給与", "조종사 급여"),
 "upkeep": ("Upkeep", "Bakım", "Wartung", "Mantenimiento", "整備費", "유지비"),
 "insurance": ("Insurance premiums", "Sigorta primi", "Versicherungsprämien", "Primas de seguro", "保険料", "보험료"),
 "loans": ("Loan installments", "Kredi taksiti", "Kreditraten", "Cuotas del préstamo", "ローン返済", "대출 상환"),
 "repairs": ("Repairs", "Onarım", "Reparaturen", "Reparaciones", "修理費", "수리비"),
 "compensation": ("Passenger compensation", "Yolcu tazminatı", "Entschädigungen", "Indemnizaciones", "乗客への補償", "승객 보상금"),
 "fines": ("Fines", "Ceza", "Bußgelder", "Multas", "罰金", "벌금"),
 "cancellations": ("Cancellation refunds", "İptal iadesi", "Stornoerstattungen", "Reembolsos por cancelación", "キャンセル返金", "취소 보상"),
 "hotelFees": ("Hotel deals", "Otel anlaşmaları", "Hotelverträge", "Acuerdos con hoteles", "ホテル契約料", "호텔 제휴"),
 "antitrust": ("Antitrust fine", "Tekel cezası", "Kartellstrafe", "Multa antimonopolio", "独占禁止法の罰金", "독점 벌금"),
}.items():
    add("ledger." + k, *v)

# Hezarfen UI
add("hez.name", "Master Hezarfen", "Hezarfen Usta", "Meister Hezarfen", "Maestro Hezarfen", "ヘザルフェン師匠", "헤자르펜 스승")
add("hez.ok", "Got it", "Anladım", "Verstanden", "Entendido", "わかりました", "알겠어요")

# Names
for k, v in {
 "proposal": ("Marriage proposal", "Evlilik teklifi", "Heiratsantrag", "Pedida de mano", "プロポーズ", "청혼"),
 "valley": ("Pigeon Valley tour", "Güvercinlik Vadisi turu", "Tour durchs Taubental", "Paseo por el Valle de las Palomas", "鳩の谷ツアー", "비둘기 계곡 투어"),
 "panorama": ("Panorama photo", "Panorama fotoğrafı", "Panoramafoto", "Foto panorámica", "パノラマ写真", "파노라마 사진"),
 "precision": ("Precision landing", "Hassas iniş", "Präzisionslandung", "Aterrizaje de precisión", "精密着陸", "정밀 착륙"),
}.items():
    add("mission." + k, *v)
for k, v in {
 "proposal": ("Stay between 250 and 350 m for 8 seconds without a break. There's a ring in the basket!", "250–350 m arasında kesintisiz 8 saniye kal. Sepette yüzük var!", "Bleib 8 Sekunden am Stück zwischen 250 und 350 m. Im Korb liegt ein Ring!", "Mantente entre 250 y 350 m durante 8 segundos seguidos. ¡Hay un anillo en la cesta!", "高度250〜350 mを8秒間キープ。バスケットには指輪が！", "250~350 m 사이에서 8초간 연속으로 머무르세요. 바스켓에 반지가 있어요!"),
 "valley": ("Pass low over the marked valley, under 150 m.", "İşaretli vadinin üzerinden alçaktan geç: 150 m'nin altında.", "Überfliege das markierte Tal tief, unter 150 m.", "Sobrevuela el valle marcado a baja altura, por debajo de 150 m.", "印のついた谷の上を150 m以下で低く通過。", "표시된 계곡 위를 150 m 이하로 낮게 지나가세요."),
 "panorama": ("Climb above 550 m for the photographer, then come down.", "Fotoğrafçı için 550 m üstüne çık, sonra in.", "Steig für den Fotografen über 550 m und komm dann runter.", "Sube por encima de 550 m para el fotógrafo y luego baja.", "カメラマンのために550 m以上へ上昇し、その後降下。", "사진가를 위해 550 m 이상 올라갔다가 내려오세요."),
 "precision": ("Land within 40 m of the ground crew.", "Yer ekibine 40 m'den yakın in.", "Lande höchstens 40 m von der Bodencrew entfernt.", "Aterriza a menos de 40 m del equipo de tierra.", "地上クルーから40 m以内に着陸。", "지상 요원 40 m 이내에 착륙하세요."),
}.items():
    add("mission.desc." + k, *v)
for k, v in {
 "stone": ("Göreme Stone Houses", "Göreme Taş Evleri", "Göreme Steinhäuser", "Casas de piedra de Göreme", "ギョレメ・ストーンハウス", "괴레메 돌집"),
 "mansion": ("Peri Mansion Ürgüp", "Peri Konak Ürgüp", "Peri-Herrenhaus Ürgüp", "Mansión Peri Ürgüp", "ペリ邸宅ユルギュップ", "페리 맨션 위르귑"),
 "cave": ("Uçhisar Cave Hotel", "Uçhisar Mağara Otel", "Höhlenhotel Uçhisar", "Hotel cueva de Uçhisar", "ウチヒサル洞窟ホテル", "우치히사르 동굴 호텔"),
 "palace": ("Cappadocia Palace Resort", "Kapadokya Saray Resort", "Kappadokien Palast-Resort", "Resort Palacio de Capadocia", "カッパドキア・パレスリゾート", "카파도키아 팰리스 리조트"),
}.items():
    add("hotel." + k, *v)
for k, v in {
 "carpet": ("Göreme Carpet House", "Göreme Halı Evi", "Göreme Teppichhaus", "Casa de Alfombras Göreme", "ギョレメ・カーペットハウス", "괴레메 카펫 하우스"),
 "wine": ("Cappadocia Vineyards", "Kapadokya Bağları", "Weingüter Kappadokien", "Viñedos de Capadocia", "カッパドキア・ワイナリー", "카파도키아 포도원"),
 "bank": ("Peri Bank", "Peri Bankası", "Peri Bank", "Banco Peri", "ペリ銀行", "페리 은행"),
 "energy": ("Turbo Energy Drink", "Turbo Enerji İçeceği", "Turbo Energydrink", "Bebida energética Turbo", "ターボ・エナジードリンク", "터보 에너지 드링크"),
}.items():
    add("sponsor." + k, *v)
add("level.1", "Rookie", "Çaylak", "Anfänger", "Novato", "新人", "신입")
add("level.2", "Experienced", "Deneyimli", "Erfahren", "Experimentado", "中堅", "숙련")
add("level.3", "Senior", "Kıdemli", "Routinier", "Veterano", "ベテラン", "베테랑")
add("size.S", "Small basket", "Küçük sepet", "Kleiner Korb", "Cesta pequeña", "小型バスケット", "소형 바스켓")
add("size.M", "Medium basket", "Orta sepet", "Mittlerer Korb", "Cesta mediana", "中型バスケット", "중형 바스켓")
add("size.L", "Large basket", "Büyük sepet", "Großer Korb", "Cesta grande", "大型バスケット", "대형 바스켓")
add("size.XL", "Giant balloon", "Dev balon", "Riesenballon", "Globo gigante", "巨大気球", "거대 열기구")
for k, v in {
 "gb": ("United Kingdom", "Birleşik Krallık", "Großbritannien", "Reino Unido", "イギリス", "영국"),
 "jp": ("Japan", "Japonya", "Japan", "Japón", "日本", "일본"),
 "es": ("Spain", "İspanya", "Spanien", "España", "スペイン", "스페인"),
 "istanbul": ("Istanbul", "İstanbul", "Istanbul", "Estambul", "イスタンブール", "이스탄불"),
 "kr": ("South Korea", "Güney Kore", "Südkorea", "Corea del Sur", "韓国", "대한민국"),
 "eg": ("Egypt", "Mısır", "Ägypten", "Egipto", "エジプト", "이집트"),
 "pl": ("Poland", "Polonya", "Polen", "Polonia", "ポーランド", "폴란드"),
 "it": ("Italy", "İtalya", "Italien", "Italia", "イタリア", "이탈리아"),
 "in": ("India", "Hindistan", "Indien", "India", "インド", "인도"),
 "us": ("USA", "ABD", "USA", "EE. UU.", "アメリカ", "미국"),
 "fr": ("France", "Fransa", "Frankreich", "Francia", "フランス", "프랑스"),
 "cn": ("China", "Çin", "China", "China", "中国", "중국"),
 "ankara": ("Ankara", "Ankara", "Ankara", "Ankara", "アンカラ", "앙카라"),
 "de": ("Germany", "Almanya", "Deutschland", "Alemania", "ドイツ", "독일"),
 "br": ("Brazil", "Brezilya", "Brasilien", "Brasil", "ブラジル", "브라질"),
 "nl": ("Netherlands", "Hollanda", "Niederlande", "Países Bajos", "オランダ", "네덜란드"),
}.items():
    add("country." + k, *v)

# Debug
add("debug.reset", "Delete save (test)", "Kaydı sil (test)", "Spielstand löschen (Test)", "Borrar partida (prueba)", "セーブ削除（テスト）", "저장 삭제 (테스트)")
