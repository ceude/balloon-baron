from s1_ui import add

# v143 (developer, option A): the autopilot report. On the holding's Regions page each parked region has a Report
# button: how yesterday's autopilot money was worked out, the last seven days, and the region as you left it (the
# last days' report lines on average, the seats filled, the fleet, the prices).

add("autoRep.open", "Report ›", "Rapor ›", "Bericht ›", "Informe ›", "レポート ›", "보고서 ›")
add("autoRep.kicker", "Autopilot report", "Otomatik mod raporu", "Autopilot-Bericht", "Informe del piloto automático", "自動運営レポート", "자동 운영 보고서")
add("autoRep.sub", "Autopilot · day you left: %@", "Otomatik mod · ayrıldığın gün: %@", "Autopilot · Tag deiner Abreise: %@",
    "Piloto automático · día en que te fuiste: %@", "自動運営 · 離れた日：%@", "자동 운영 · 떠난 날: %@")
add("autoRep.yesterday", "Yesterday's earnings (day %@)", "Dünkü kazanç (gün %@)", "Ertrag von gestern (Tag %@)",
    "Ganancia de ayer (día %@)", "昨日の稼ぎ（%@日目）", "어제 수익 (%@일차)")
add("autoRep.base", "Base", "Temel kazanç", "Grundertrag", "Base", "基本の稼ぎ", "기본 수익")
add("autoRep.swing", "Daily swing", "Günlük dalgalanma", "Tagesschwankung", "Variación del día", "日々の変動", "일일 변동")
for k, v in {
    "after": ("After your decision", "Kararının etkisi", "Folge deiner Entscheidung", "Efecto de tu decisión", "決定の影響", "결정의 영향"),
    "issue": ("Open problem", "Bekleyen sorun", "Offenes Problem", "Problema pendiente", "未解決の問題", "미해결 문제"),
    "record": ("World records", "Dünya rekorları", "Weltrekorde", "Récords mundiales", "世界記録", "세계 기록"),
    "tv": ("TV campaign", "TV kampanyası", "TV-Kampagne", "Campaña de TV", "テレビCM", "TV 캠페인"),
    "celebrity": ("Celebrity deal", "Ünlü yüz", "Prominenter Werbeträger", "Famoso de la marca", "有名人の契約", "유명인 계약"),
    "billboards": ("Billboards", "Reklam panoları", "Plakatwände", "Vallas publicitarias", "看板広告", "옥외 광고판"),
    "jersey": ("Jersey sponsorship", "Forma sponsorluğu", "Trikotsponsoring", "Patrocinio de camiseta", "ユニフォームスポンサー", "유니폼 후원"),
    "worldGames": ("World Games show", "Dünya Oyunları gösterisi", "World-Games-Show", "Espectáculo de los Juegos Mundiales", "世界大会のショー", "월드 게임 쇼"),
    "documentary": ("Documentary", "Belgesel", "Dokuserie", "Documental", "ドキュメンタリー", "다큐멘터리"),
    "festival": ("International Balloon Festival", "Uluslararası Balon Festivali", "Internationales Ballonfestival", "Festival Internacional de Globos", "国際気球フェスティバル", "국제 열기구 축제"),
    "fame": ("Festival fame", "Festival ünü", "Festivalruhm", "Fama de los festivales", "フェスの名声", "축제 명성"),
    "office": ("Region's city office", "Bölgenin şehir ofisi", "Stadtbüro der Region", "Oficina de la región", "地域の支社", "지역 사무소"),
    "tokyo": ("Tokyo office", "Tokyo ofisi", "Büro Tokio", "Oficina de Tokio", "東京支社", "도쿄 사무소"),
    "research": ("R&D", "Ar-Ge", "F&E", "I+D", "研究開発", "연구개발"),
}.items():
    add("autoRep.f." + k, *v)
add("autoRep.gross", "Gross", "Brüt", "Brutto", "Bruto", "総額", "총액")
add("autoRep.expense", "Holding expenses (%@)", "Holding giderleri (%@)", "Holdingkosten (%@)", "Gastos del holding (%@)",
    "持株会社の経費（%@）", "지주회사 경비 (%@)")
add("autoRep.rent", "Share of office rent", "Ofis kirası payı", "Anteil an der Büromiete", "Parte del alquiler de oficinas",
    "支社の家賃の負担分", "사무소 임대료 분담")
add("autoRep.toHolding", "To the holding", "Holdinge giden", "An die Holding", "Al holding", "持株会社へ", "지주회사로")
add("autoRep.kept", "Stayed in the region's cash box", "Bölge kasasında kalan", "Blieb in der Kasse der Region",
    "Se quedó en la caja de la región", "地域の金庫に残った額", "지역 금고에 남은 금액")
add("autoRep.firstEvening", "The first breakdown comes this evening.", "İlk döküm bu akşam gelir.",
    "Die erste Aufschlüsselung kommt heute Abend.", "El primer desglose llega esta noche.", "最初の内訳は今夜届く。",
    "첫 내역은 오늘 저녁에 나옵니다.")
add("autoRep.week", "Last 7 days", "Son 7 gün", "Letzte 7 Tage", "Últimos 7 días", "直近7日", "최근 7일")
add("autoRep.weekA11y", "Earnings of the last days: %@", "Son günlerin kazancı: %@", "Ertrag der letzten Tage: %@",
    "Ganancias de los últimos días: %@", "直近の稼ぎ：%@", "최근 수익: %@")
add("autoRep.left", "When you left (daily average, days: %@)", "Ayrıldığında (günlük ortalama, gün sayısı: %@)",
    "Bei deiner Abreise (Tagesdurchschnitt, Tage: %@)", "Cuando te fuiste (media diaria, días: %@)",
    "離れたとき（1日平均、日数：%@）", "떠날 때 (일 평균, 일수: %@)")
add("autoRep.contract", "Tour groups", "Tur grupları", "Tourgruppen", "Grupos turísticos", "ツアー団体", "단체 관광")
add("autoRep.hotels", "Hotels", "Oteller", "Hotels", "Hoteles", "ホテル", "호텔")
add("autoRep.other", "Other", "Diğer", "Sonstiges", "Otros", "その他", "기타")
add("autoRep.occupancy", "Occupancy: %1$@ · seats: %2$@/%3$@", "Doluluk: %1$@ · koltuk: %2$@/%3$@",
    "Auslastung: %1$@ · Plätze: %2$@/%3$@", "Ocupación: %1$@ · plazas: %2$@/%3$@", "搭乗率：%1$@ · 座席：%2$@/%3$@",
    "탑승률: %1$@ · 좌석: %2$@/%3$@")
add("autoRep.noFlights", "Occupancy: no flights", "Doluluk: uçuş yok", "Auslastung: keine Flüge", "Ocupación: sin vuelos",
    "搭乗率：飛行なし", "탑승률: 비행 없음")
add("autoRep.fleet", "Balloons: %1$@ · seats: %2$@ · pilots: %3$@", "Balon: %1$@ · koltuk: %2$@ · pilot: %3$@",
    "Ballone: %1$@ · Plätze: %2$@ · Piloten: %3$@", "Globos: %1$@ · plazas: %2$@ · pilotos: %3$@",
    "気球：%1$@ · 座席：%2$@ · パイロット：%3$@", "열기구: %1$@ · 좌석: %2$@ · 조종사: %3$@")
add("autoRep.price", "Ticket: %1$@ · rivals: cheapest %2$@, average %3$@", "Bilet: %1$@ · rakipler: en ucuz %2$@, ortalama %3$@",
    "Ticket: %1$@ · Konkurrenz: günstigster %2$@, Schnitt %3$@", "Billete: %1$@ · rivales: el más barato %2$@, media %3$@",
    "チケット：%1$@ · ライバル：最安 %2$@、平均 %3$@", "티켓: %1$@ · 경쟁사: 최저 %2$@, 평균 %3$@")
add("autoRep.priceAlone", "Ticket: %@ · no rivals", "Bilet: %@ · rakip yok", "Ticket: %@ · keine Konkurrenz",
    "Billete: %@ · sin rivales", "チケット：%@ · ライバルなし", "티켓: %@ · 경쟁사 없음")
add("autoRep.old", "You left this region before this version; the breakdown appears the next time you leave it.",
    "Bu bölgeden bu sürümden önce ayrıldın; döküm bir sonraki ayrılışında görünür.",
    "Du hast diese Region vor dieser Version verlassen; die Aufschlüsselung erscheint, wenn du sie das nächste Mal verlässt.",
    "Dejaste esta región antes de esta versión; el desglose aparecerá la próxima vez que salgas de ella.",
    "この地域を離れたのはこのバージョンより前。内訳は次に離れたときから表示される。",
    "이 버전 이전에 이 지역을 떠났습니다. 다음에 떠날 때부터 내역이 표시됩니다.")
add("autoRep.explain", "Earnings were set from your last 14 days in this region. To raise them, go there, tune it (price, fleet, pilots), then leave.",
    "Kazanç bu bölgedeki son 14 günden belirlendi. Artırmak için bölgeye git, ayarla (fiyat, filo, pilotlar), sonra ayrıl.",
    "Der Ertrag wurde aus deinen letzten 14 Tagen in dieser Region bestimmt. Um ihn zu steigern, reise hin, stell alles ein (Preis, Flotte, Piloten) und reise wieder ab.",
    "La ganancia se fijó con tus últimos 14 días en esta región. Para subirla, ve allí, ajústala (precio, flota, pilotos) y luego vete.",
    "稼ぎはこの地域での直近14日から決まった。増やすには地域へ行き、価格・機体・パイロットを整えてから離れよう。",
    "수익은 이 지역에서의 최근 14일로 정해졌습니다. 올리려면 지역으로 가서 가격, 기단, 조종사를 조정한 뒤 떠나세요.")
