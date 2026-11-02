from s1_ui import add

# v136 (TestFlight): TV and billboards are bought for each region from one Marketing page; the worldwide deals lift
# popularity in every region you own.

# Chips of the worldwide deals: popularity goes to every region you own (no region name that follows the viewer).
add("holding.chip.starsAll", "All regions: +%@", "Bütün bölgelerde: +%@", "Alle Regionen: +%@", "Todas las regiones: +%@", "全地域：+%@", "전 지역: +%@")
add("holding.deals.hint",
    "Deals lift popularity in every region you own on the day you sign. A region you enter later starts with its own.",
    "Anlaşmalar imzaladığın gün sahip olduğun bütün bölgelerde popülerliği artırır. Sonradan girdiğin bölge kendi popülerliğiyle başlar.",
    "Deals heben die Beliebtheit in allen deinen Regionen am Tag der Unterschrift. Eine später betretene Region beginnt mit ihrer eigenen.",
    "Los acuerdos suben la popularidad en todas tus regiones el día que firmas. Una región en la que entres después empieza con la suya.",
    "契約は署名した日に、所有する全地域の人気を上げる。後から進出した地域は自分の人気から始まる。",
    "계약은 서명한 날 보유한 모든 지역의 인기를 올립니다. 나중에 진출한 지역은 자기 인기로 시작합니다.")

# Marketing: one row per region you own, in each campaign's card.
add("holding.mkt.hint",
    "TV and billboards run in one region at a time. Buy them here for any region you own; the effect stays in that region.",
    "TV ve afişler tek bir bölgede yayınlanır. Sahip olduğun her bölge için buradan alabilirsin; etkisi o bölgede kalır.",
    "TV und Plakate laufen jeweils in einer Region. Kauf sie hier für jede deiner Regionen; die Wirkung bleibt in dieser Region.",
    "La TV y las vallas funcionan en una sola región. Cómpralas aquí para cualquiera de tus regiones; el efecto se queda en esa región.",
    "テレビと看板は地域ごとに展開する。ここで所有するどの地域の分も買える。効果はその地域だけ。",
    "TV와 광고판은 지역마다 따로 진행됩니다. 보유한 어느 지역이든 여기서 살 수 있고, 효과는 그 지역에만 있습니다.")
add("holding.tv.descRegion",
    "Your balloons gliding at sunrise, on the region's national channels right before the evening news.",
    "Bölgenin ulusal kanallarında akşam haberlerinden önce, gün doğumunda süzülen balonların.",
    "Deine Ballone im Sonnenaufgang, auf den großen Sendern der Region direkt vor den Abendnachrichten.",
    "Tus globos planeando al amanecer, en los canales nacionales de la región justo antes de las noticias de la noche.",
    "その地域の全国放送で、夕方のニュース直前に朝日の中を漂うあなたの気球。",
    "그 지역 전국 방송 저녁 뉴스 직전, 해돋이 속을 떠다니는 당신의 열기구.")
add("holding.bb.descRegion",
    "Giant posters along the airport road and highways of the region.",
    "Bölgenin havalimanı yolunda ve otobanlarında dev afişler.",
    "Riesige Plakate an der Flughafenstraße und den Autobahnen der Region.",
    "Carteles gigantes en la carretera del aeropuerto y las autopistas de la región.",
    "その地域の空港への道と高速道路に巨大看板。",
    "그 지역 공항 도로와 고속도로의 대형 광고판.")
add("holding.chip.demandRegion", "Demand in the region +%@", "Bölgede talep +%@", "Nachfrage in der Region +%@", "Demanda en la región +%@", "その地域の需要+%@", "해당 지역 수요 +%@")
add("holding.chip.starsRegion", "Popularity in the region +%@", "Bölgede popülerlik +%@", "Beliebtheit in der Region +%@", "Popularidad en la región +%@", "その地域の人気+%@", "해당 지역 인기 +%@")
add("holding.chip.wait", "Wait between campaigns (days): %@", "Kampanyalar arası bekleme (gün): %@", "Pause zwischen Kampagnen (Tage): %@", "Espera entre campañas (días): %@", "キャンペーン間の待機（日）：%@", "캠페인 간 대기(일): %@")
add("holding.row.here", "You're here", "Buradasın", "Du bist hier", "Estás aquí", "現在地", "현재 위치")
add("holding.row.free", "No campaign", "Kampanya yok", "Keine Kampagne", "Sin campaña", "キャンペーンなし", "캠페인 없음")
add("holding.row.wait", "Next campaign in days: %@", "Yeni kampanyaya kalan gün: %@", "Nächste Kampagne in Tagen: %@", "Próxima campaña en días: %@", "次のキャンペーンまで：%@日", "다음 캠페인까지 일수: %@")
add("holding.row.a11y", "%1$@: %2$@", "%1$@: %2$@", "%1$@: %2$@", "%1$@: %2$@", "%1$@：%2$@", "%1$@: %2$@")

# The Marketing desk: how many regions have TV and billboards running.
add("hq.s.campaigns", "TV: %1$@ · Billboards: %2$@", "TV: %1$@ · Afiş: %2$@", "TV: %1$@ · Plakate: %2$@", "TV: %1$@ · Vallas: %2$@", "テレビ：%1$@・看板：%2$@", "TV: %1$@ · 광고판: %2$@")

# A world record reported among the day's popularity reasons.
add("repWhy.record", "World record", "Dünya rekoru", "Weltrekord", "Récord mundial", "世界記録", "세계 기록")

# The TV campaign now airs in one region: the guide and the paper say so.
add("hez.deed.tv",
    "Your TV ad is on the air, kid! The whole country is talking about your balloons. You'll see this investment pay off in your cash.",
    "TV reklamın yayında evlat! Bütün ülke balonlarını konuşuyor. Bu yatırımın karşılığını kasada göreceksin.",
    "Dein TV-Spot läuft, Lehrling! Das ganze Land redet über deine Ballone. Diese Investition wirst du in der Kasse sehen.",
    "¡Tu anuncio ya está en la tele, aprendiz! Todo el país habla de tus globos. Verás esta inversión en la caja.",
    "テレビCMが流れ始めたぞ、弟子よ！国じゅうがお前の気球の話でもちきりだ。この投資の見返りは金庫に表れる。",
    "TV 광고가 방송을 탔네, 제자여! 온 나라가 자네 열기구 이야기를 하고 있다네. 이 투자의 보답은 금고에서 확인하게 될 걸세.")
add("paper.deed.tv.sub",
    "The holding's TV campaign brings tourists to the region.",
    "Holdingin TV kampanyası bölgeye turist getiriyor.",
    "Die TV-Kampagne der Holding bringt Touristen in die Region.",
    "La campaña de TV del holding atrae turistas a la región.",
    "ホールディングスのテレビキャンペーンで、その地域に観光客が来る。",
    "지주회사의 TV 캠페인이 그 지역에 관광객을 부른다.")
