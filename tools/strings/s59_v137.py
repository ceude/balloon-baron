from s1_ui import add

# v137 (TestFlight: "EUR 18M in the holding and nothing left to spend it on"): the documentary series, R&D levels 3
# and 4, the Pacific crossing, the Dubai and Paris offices; the developer's new expense rule and holding goals.

# Offices 5 and 6
add("office.dxb", "Dubai", "Dubai", "Dubai", "Dubái", "ドバイ", "두바이")

# The expense rule: any four offices 20%, all six 15%
add("holding.officesRule",
    "Open offices in the world's great cities; each one has its own perk. With any four open, holding expenses drop from %1$@ to %2$@; with all six, to %3$@.",
    "Dünyanın büyük şehirlerinde ofis aç; her ofisin kendi avantajı var. Herhangi dört ofis açıksa holding giderleri %1$@ yerine %2$@ olur, altısı birden açıksa %3$@.",
    "Eröffne Büros in den großen Städten der Welt; jedes hat einen eigenen Vorteil. Mit beliebigen vier sinken die Holding-Ausgaben von %1$@ auf %2$@, mit allen sechs auf %3$@.",
    "Abre oficinas en las grandes ciudades del mundo; cada una tiene su ventaja. Con cuatro cualesquiera, los gastos del holding bajan del %1$@ al %2$@; con las seis, al %3$@.",
    "世界の大都市にオフィスを開こう。それぞれに特典がある。どれか4つ開けばホールディングス経費は%1$@から%2$@に、6つすべてなら%3$@に下がる。",
    "세계 대도시에 사무소를 여세요. 사무소마다 혜택이 있습니다. 아무 곳이나 네 곳을 열면 지주회사 비용이 %1$@에서 %2$@로, 여섯 곳을 모두 열면 %3$@로 줄어듭니다.")
add("holding.officesFour",
    "Offices open: %1$@. Holding expenses are %2$@ instead of %3$@; with all six open they drop to %4$@.",
    "Açık ofis: %1$@. Holding giderlerin %3$@ yerine %2$@; altısı birden açıksa %4$@ olur.",
    "Offene Büros: %1$@. Die Holding-Ausgaben betragen %2$@ statt %3$@; mit allen sechs sinken sie auf %4$@.",
    "Oficinas abiertas: %1$@. Los gastos del holding son del %2$@ en vez del %3$@; con las seis bajan al %4$@.",
    "開設済みオフィス：%1$@。ホールディングス経費は%3$@ではなく%2$@。6つすべて開けば%4$@になる。",
    "운영 중인 사무소: %1$@. 지주회사 비용은 %3$@ 대신 %2$@입니다. 여섯 곳을 모두 열면 %4$@로 줄어듭니다.")
add("holding.officesSix",
    "You have offices in six great cities. Holding expenses are %1$@ instead of %2$@.",
    "Altı büyük şehirde ofisin var. Holding giderlerin %2$@ yerine %1$@.",
    "Du hast Büros in sechs großen Städten. Die Holding-Ausgaben betragen %1$@ statt %2$@.",
    "Tienes oficinas en seis grandes ciudades. Los gastos del holding son del %1$@ en vez del %2$@.",
    "6つの大都市にオフィスがある。ホールディングス経費は%2$@ではなく%1$@。",
    "여섯 대도시에 사무소가 있습니다. 지주회사 비용은 %2$@ 대신 %1$@입니다.")
add("hez.allOffices",
    "Four offices open, kid! You're a real global company now. Shared costs fell: holding expenses are down to 20%. Open all six and they drop to 15%.",
    "Dört ofisin açık evlat! Artık gerçek bir dünya şirketisin. Ortak giderler azaldı, holding giderlerin %20'ye indi. Altısını da açarsan %15'e iner.",
    "Vier Büros sind offen, Lehrling! Du bist jetzt ein echter Weltkonzern. Die gemeinsamen Kosten sind gesunken: Die Holding-Ausgaben liegen nur noch bei 20 %. Mit allen sechs sind es 15 %.",
    "¡Cuatro oficinas abiertas, aprendiz! Ya eres una empresa global de verdad. Los gastos comunes bajaron: los gastos del holding son ahora del 20 %. Con las seis bajan al 15 %.",
    "オフィスが4つになったぞ、弟子よ！もう本物の世界企業だ。共通経費が減り、ホールディングスの経費は20%になった。6つすべて開けば15%だ。",
    "사무소가 네 곳이 되었네, 제자여! 이제 진짜 세계적인 회사일세. 공통 비용이 줄어 지주회사 비용이 20%로 내려갔다네. 여섯 곳을 모두 열면 15%가 되지.")
add("hez.sixOffices",
    "All six offices are open, kid! From Istanbul to London, from Dubai to Tokyo... Holding expenses are down to 15%. Pick the city for your morning coffee.",
    "Altı ofisin de açık evlat! İstanbul'dan Londra'ya, Dubai'den Tokyo'ya... Holding giderlerin %15'e indi. Sabah kahveni hangi şehirde içeceğini sen seç.",
    "Alle sechs Büros sind offen, Lehrling! Von Istanbul bis London, von Dubai bis Tokio … Die Holding-Ausgaben liegen nur noch bei 15 %. Such dir die Stadt für deinen Morgenkaffee aus.",
    "¡Las seis oficinas están abiertas, aprendiz! De Estambul a Londres, de Dubái a Tokio... Los gastos del holding bajaron al 15 %. Elige en qué ciudad tomas el café de la mañana.",
    "6つのオフィスがすべて開いたぞ、弟子よ！イスタンブールからロンドン、ドバイから東京まで……ホールディングスの経費は15%になった。朝のコーヒーはどの街で飲むか選ぶといい。",
    "여섯 사무소가 모두 문을 열었네, 제자여! 이스탄불에서 런던까지, 두바이에서 도쿄까지... 지주회사 비용이 15%로 내려갔다네. 아침 커피는 어느 도시에서 마실지 골라 보게.")

# Holding goals (developer): six offices, all four R&D levels
add("hgoal.offices", "Six world offices", "Altı dünya ofisi", "Sechs Büros weltweit", "Seis oficinas en el mundo", "世界6都市のオフィス", "세계 6개 도시 사무소")
add("hgoal.research", "All four R&D levels", "Ar-Ge'nin dört seviyesi tamam", "Alle vier F&E-Stufen", "Los cuatro niveles de I+D", "研究開発の4段階すべて", "R&D 4단계 모두 완료")
add("hgoal.officesNow", "Offices: %1$@/%2$@", "Ofis: %1$@/%2$@", "Büros: %1$@/%2$@", "Oficinas: %1$@/%2$@", "オフィス：%1$@/%2$@", "사무소: %1$@/%2$@")
add("hgoal.researchNow", "R&D: %1$@/%2$@", "Ar-Ge: %1$@/%2$@", "F&E: %1$@/%2$@", "I+D: %1$@/%2$@", "研究開発：%1$@/%2$@", "R&D: %1$@/%2$@")
add("hq.s.research", "R&D: %1$@/%2$@", "Ar-Ge: %1$@/%2$@", "F&E: %1$@/%2$@", "I+D: %1$@/%2$@", "研究開発：%1$@/%2$@", "R&D: %1$@/%2$@")

# Documentary series
add("hq.s.documentary", "Documentary on air · days left: %@", "Belgesel yayında · kalan gün: %@", "Doku läuft · Resttage: %@",
    "Documental en emisión · días restantes: %@", "ドキュメンタリー放送中・残り日数：%@", "다큐멘터리 방영 중 · 남은 일수: %@")
add("holding.doc.kicker", "Documentary series", "Belgesel dizisi", "Doku-Serie", "Serie documental", "ドキュメンタリーシリーズ", "다큐멘터리 시리즈")
add("holding.doc.title", "Barons of the Sky", "Gökyüzünün Baronları", "Barone des Himmels", "Barones del cielo", "空の男爵たち", "하늘의 남작들")
add("holding.doc.desc",
    "A documentary series about your company for a big streaming platform: burners lit at three in the morning, pilots bargaining with the wind, the world seen from the basket.",
    "Büyük bir yayın platformu için şirketinin belgesel dizisi: sabahın üçünde ısınan brülörler, rüzgârla pazarlık eden pilotlar, sepetten dünyaya bakış.",
    "Eine Doku-Serie über deine Firma für eine große Streaming-Plattform: Brenner, die um drei Uhr morgens zünden, Piloten, die mit dem Wind verhandeln, die Welt aus dem Korb gesehen.",
    "Una serie documental sobre tu empresa para una gran plataforma de streaming: quemadores encendidos a las tres de la mañana, pilotos negociando con el viento, el mundo visto desde la cesta.",
    "大手配信サービス向けの、あなたの会社のドキュメンタリーシリーズ。午前3時に灯るバーナー、風と駆け引きするパイロット、バスケットから見る世界。",
    "대형 스트리밍 플랫폼에서 방영할 회사 다큐멘터리 시리즈. 새벽 세 시에 켜지는 버너, 바람과 흥정하는 조종사들, 바스켓에서 내려다본 세상.")
add("holding.doc.descActive",
    "The documentary about %@ is on air; viewers are looking for a seat in a balloon.",
    "Belgesel yayında, şirketin adı herkesin ağzında: %@. İzleyenler balona binmek için yer arıyor.",
    "Die Doku über %@ läuft; die Zuschauer suchen einen Platz im Ballon.",
    "El documental sobre %@ está en emisión; los espectadores buscan plaza en un globo.",
    "%@のドキュメンタリーが放送中。視聴者が気球の席を探している。",
    "%@ 다큐멘터리가 방영 중입니다. 시청자들이 열기구 자리를 찾고 있어요.")
add("holding.doc.cta", "Make the series", "Diziyi çek", "Serie drehen", "Rodar la serie", "シリーズを制作", "시리즈 제작")
add("holding.doc.ctaSeason", "Make season %@", "Yeni sezonu çek: %@", "Staffel %@ drehen", "Rodar la temporada %@", "シーズン%@を制作", "시즌 %@ 제작")
add("holding.doc.active", "Season %1$@ on air · days left: %2$@", "Sezon %1$@ yayında · kalan gün: %2$@", "Staffel %1$@ läuft · Resttage: %2$@",
    "Temporada %1$@ en emisión · días restantes: %2$@", "シーズン%1$@放送中・残り日数：%2$@", "시즌 %1$@ 방영 중 · 남은 일수: %2$@")
add("holding.doc.wait", "Days until a new season: %@", "Yeni sezona kalan gün: %@", "Tage bis zur neuen Staffel: %@",
    "Días hasta una nueva temporada: %@", "新シーズンまでの日数：%@", "새 시즌까지 남은 일수: %@")

# R&D levels 3 and 4
add("holding.lab.kickerLevel", "R&D · level %@", "Ar-Ge · seviye %@", "F&E · Stufe %@", "I+D · nivel %@", "研究開発・レベル%@", "R&D · 레벨 %@")
add("holding.lab.first", "Level %@ first", "Önce seviye %@", "Erst Stufe %@", "Primero el nivel %@", "先にレベル%@", "먼저 레벨 %@")
add("holding.radar.title", "Weather radar network", "Hava radarı ağı", "Wetterradar-Netz", "Red de radares meteorológicos", "気象レーダー網", "기상 레이더망")
add("holding.radar.desc",
    "Doppler radars and wind probes in every region: pilots know where the wind will turn before they take off.",
    "Her bölgeye Doppler radarları ve rüzgâr sondaları: pilotlar sabah kalkmadan rüzgârın nereye döneceğini bilir.",
    "Doppler-Radare und Windsonden in jeder Region: Die Piloten wissen vor dem Start, wohin der Wind dreht.",
    "Radares Doppler y sondas de viento en cada región: los pilotos saben hacia dónde girará el viento antes de despegar.",
    "全地域にドップラーレーダーと風のゾンデ。パイロットは離陸前に風の向きの変化がわかる。",
    "모든 지역에 도플러 레이더와 바람 탐측기. 조종사는 이륙 전에 바람이 어디로 바뀔지 압니다.")
add("holding.comp.title", "Composite basket and efficient burner", "Kompozit sepet ve verimli brülör", "Verbundkorb und Sparbrenner",
    "Cesta de composite y quemador eficiente", "複合素材バスケットと高効率バーナー", "복합소재 바스켓과 고효율 버너")
add("holding.comp.desc",
    "A carbon-fibre basket and a new burner that burns every drop of gas: lighter balloons, cylinders that last longer.",
    "Karbon elyaf sepet ve gazı sonuna kadar yakan yeni brülör: balonlar hafifler, tüpler daha geç biter.",
    "Ein Korb aus Kohlefaser und ein neuer Brenner, der jeden Tropfen Gas nutzt: leichtere Ballone, Flaschen, die länger halten.",
    "Una cesta de fibra de carbono y un quemador nuevo que aprovecha todo el gas: globos más ligeros, bombonas que duran más.",
    "カーボンファイバーのバスケットと、ガスを使い切る新バーナー。気球は軽くなり、ボンベは長持ちする。",
    "탄소섬유 바스켓과 가스를 끝까지 태우는 새 버너. 열기구는 가벼워지고 연료통은 더 오래갑니다.")
add("holding.radar.chipRisk", "Accident risk −%@, premiums too", "Kaza riski −%@, sigorta primleri de", "Unfallrisiko −%@, Prämien auch",
    "Riesgo de accidente −%@, y las primas", "事故リスク−%@、保険料も", "사고 위험 −%@, 보험료도")
add("holding.comp.chipFuel", "Fuel −%@", "Yakıt −%@", "Treibstoff −%@", "Combustible −%@", "燃料−%@", "연료 −%@")
add("holding.comp.chipUpkeep", "Upkeep −%@", "Bakım −%@", "Wartung −%@", "Mantenimiento −%@", "整備費−%@", "정비비 −%@")
add("holding.chip.autoIncome", "Autopilot income +%@", "Otomatik bölgelerde kazanç +%@", "Autopilot-Einnahmen +%@",
    "Ingresos en piloto automático +%@", "自動運営収入+%@", "자동 운영 수입 +%@")

# The Pacific crossing
add("record.pacific", "Across the Pacific", "Pasifik geçişi", "Über den Pazifik", "Travesía del Pacífico", "太平洋横断", "태평양 횡단")
add("record.pacific.d",
    "Take-off in Japan, 8,000 km on the jet stream, landing in North America's snowy forests. Crossing an ocean in a single balloon.",
    "Japonya'dan kalkış, jet akımında 8.000 km, iniş Kuzey Amerika'nın karlı ormanlarında. Bir okyanusu tek balonla aşmak.",
    "Start in Japan, 8.000 km im Jetstream, Landung in den verschneiten Wäldern Nordamerikas. Ein Ozean in einem einzigen Ballon.",
    "Despegue en Japón, 8.000 km en la corriente en chorro, aterrizaje en los bosques nevados de Norteamérica. Cruzar un océano en un solo globo.",
    "日本を離陸し、ジェット気流に乗って8,000km、北米の雪の森に着陸。一つの気球で大洋を越える。",
    "일본에서 이륙해 제트기류를 타고 8,000km, 북아메리카의 눈 덮인 숲에 착륙. 열기구 하나로 대양을 건넙니다.")
# v137 (developer): the round-the-world flight is the pinnacle of the ladder now
add("record.world.d",
    "Take-off in the Swiss Alps, 20 days in the jet streams over two oceans, landing in the Egyptian desert. Breitling Orbiter 3 first did it in 1999.",
    "İsviçre Alpleri'nden kalkış, 20 gün jet akımlarında, iki okyanus, iniş Mısır çölünde. İlk kez 1999'da Breitling Orbiter 3 başarmıştı.",
    "Start in den Schweizer Alpen, 20 Tage in den Jetstreams über zwei Ozeane, Landung in der ägyptischen Wüste. Breitling Orbiter 3 schaffte es 1999 als Erster.",
    "Despegue en los Alpes suizos, 20 días en las corrientes en chorro sobre dos océanos, aterrizaje en el desierto egipcio. El Breitling Orbiter 3 lo logró por primera vez en 1999.",
    "スイス・アルプスから離陸し、ジェット気流に乗って二つの大洋を越える20日間、エジプトの砂漠に着陸。1999年にブライトリング・オービター3号が初めて達成した。",
    "스위스 알프스에서 이륙해 제트기류 속에서 두 대양을 건너는 20일, 이집트 사막에 착륙. 1999년 브라이틀링 오비터 3호가 처음 성공했습니다.")
add("holding.rec.after", "First set this record: %@", "Önce bu rekoru kır: %@", "Erst diesen Rekord aufstellen: %@",
    "Primero bate este récord: %@", "先にこの記録を達成：%@", "먼저 이 기록을 세우세요: %@")
add("holding.chip.recCeiling", "Records' ceiling %1$@ → %2$@", "Rekor tavanı %1$@ → %2$@", "Rekord-Obergrenze %1$@ → %2$@",
    "Techo de los récords %1$@ → %2$@", "記録の上限%1$@ → %2$@", "기록 상한 %1$@ → %2$@")

# Praise and the paper
for k, hz, head, sub in [
    ("documentary",
     ("Your documentary is on air, kid! The whole world is watching your pilots light burners at midnight. Tourists now come knowing what they'll see.",
      "Belgeselin yayında evlat! Gece yarısı brülör yakan pilotlarını bütün dünya izliyor. Turistler artık neyi göreceklerini bilerek geliyor.",
      "Deine Doku läuft, Lehrling! Die ganze Welt sieht deinen Piloten zu, wie sie um Mitternacht die Brenner zünden. Die Touristen wissen jetzt, was sie erwartet.",
      "¡Tu documental está en emisión, aprendiz! Todo el mundo ve a tus pilotos encender quemadores a medianoche. Los turistas ya vienen sabiendo lo que verán.",
      "お前のドキュメンタリーが放送中だ、弟子よ！真夜中にバーナーを灯すパイロットたちを世界中が見ている。観光客は何が見られるか知ってやって来る。",
      "자네 다큐멘터리가 방영 중일세, 제자여! 한밤중에 버너를 켜는 조종사들을 온 세상이 보고 있네. 관광객들은 이제 무엇을 보게 될지 알고 온다네."),
     ("A new documentary on the streaming platforms: %@", "Yayın platformunda yeni belgesel: %@", "Neue Doku auf den Streaming-Plattformen: %@",
      "Nuevo documental en las plataformas: %@", "配信サービスに新ドキュメンタリー：%@", "스트리밍 플랫폼에 새 다큐멘터리: %@"),
     ("The series Barons of the Sky went into the most-watched list.", "Gökyüzünün Baronları dizisi en çok izlenenler listesine girdi.",
      "Die Serie Barone des Himmels ist in der Liste der meistgesehenen.", "La serie Barones del cielo entró en la lista de lo más visto.",
      "シリーズ『空の男爵たち』が視聴ランキング入り。", "시리즈 「하늘의 남작들」이 최다 시청 목록에 올랐다.")),
    ("radar",
     ("Your radar network is up, kid! I used to smell the wind; you see it on a screen. Fewer accidents, and the insurer is happy too.",
      "Radar ağın kuruldu evlat! Ben rüzgârı burnumla koklardım; sen artık onu ekranda görüyorsun. Kazalar azalır, sigortacı da sevinir.",
      "Dein Radarnetz steht, Lehrling! Ich habe den Wind gerochen, du siehst ihn auf dem Bildschirm. Weniger Unfälle, und die Versicherung freut sich auch.",
      "¡Tu red de radares está lista, aprendiz! Yo olía el viento; tú lo ves en una pantalla. Menos accidentes, y la aseguradora también contenta.",
      "レーダー網ができたぞ、弟子よ！わしは風を鼻で嗅いでいたが、お前は画面で見る。事故は減り、保険会社も喜ぶ。",
      "레이더망이 세워졌네, 제자여! 나는 바람을 코로 맡았는데 자네는 화면으로 보는군. 사고가 줄고 보험사도 기뻐하겠지."),
     ("Its own weather radar network: %@", "Kendi hava radarı ağını kurdu: %@", "Ein eigenes Wetterradar-Netz: %@",
      "Su propia red de radares meteorológicos: %@", "独自の気象レーダー網：%@", "자체 기상 레이더망 구축: %@"),
     ("Pilots know before take-off where the wind will turn.", "Pilotlar rüzgârın döneceğini sabah kalkmadan biliyor.",
      "Die Piloten wissen vor dem Start, wohin der Wind dreht.", "Los pilotos saben antes de despegar hacia dónde girará el viento.",
      "パイロットは離陸前に風の変化を知っている。", "조종사들은 이륙 전에 바람이 어디로 바뀔지 안다.")),
    ("composite",
     ("The composite baskets are here, kid! Mine was willow; yours is lighter than a space shuttle. And the gas lasts longer now.",
      "Kompozit sepetler geldi evlat! Benim sepetim söğüttendi, seninki uzay mekiğinden hafif. Yakıt da artık daha geç bitiyor.",
      "Die Verbundkörbe sind da, Lehrling! Meiner war aus Weide, deiner ist leichter als ein Raumschiff. Und das Gas hält jetzt länger.",
      "¡Llegaron las cestas de composite, aprendiz! La mía era de mimbre; la tuya pesa menos que un transbordador espacial. Y el gas dura más.",
      "複合素材のバスケットが届いたぞ、弟子よ！わしのは柳だったが、お前のはスペースシャトルより軽い。ガスも長持ちする。",
      "복합소재 바스켓이 도착했네, 제자여! 내 것은 버드나무였는데 자네 것은 우주왕복선보다 가볍군. 가스도 더 오래간다네."),
     ("Carbon baskets, efficient burners: %@", "Karbon sepet, verimli brülör: %@", "Kohlefaserkörbe, Sparbrenner: %@",
      "Cestas de carbono, quemadores eficientes: %@", "カーボンのバスケット、高効率バーナー：%@", "탄소 바스켓, 고효율 버너: %@"),
     ("Lighter balloons, less fuel, less upkeep.", "Daha hafif balonlar, daha az yakıt, daha az bakım.",
      "Leichtere Ballone, weniger Treibstoff, weniger Wartung.", "Globos más ligeros, menos combustible, menos mantenimiento.",
      "気球は軽く、燃料も整備費も少なく。", "더 가벼운 열기구, 더 적은 연료, 더 적은 정비.")),
]:
    add(f"hez.deed.{k}", *hz)
    add(f"paper.deed.{k}", *head)
    add(f"paper.deed.{k}.sub", *sub)
