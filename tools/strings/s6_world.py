from s1_ui import add

# Regions and the world map
add("region.cap", "Cappadocia", "Kapadokya", "Kappadokien", "Capadocia", "カッパドキア", "카파도키아")
add("region.abq", "Albuquerque", "Albuquerque", "Albuquerque", "Albuquerque", "アルバカーキ", "앨버커키")
add("pin.cap", "Cappadocia", "Kapadokya", "Kappadokien", "Capadocia", "カッパドキア", "카파도키아")
add("pin.abq", "Albuquerque", "Albuquerque", "Albuquerque", "Albuquerque", "アルバカーキ", "앨버커키")
add("pin.luxor", "Luxor", "Luksor", "Luxor", "Luxor", "ルクソール", "룩소르")
add("pin.asia", "Asia", "Asya", "Asien", "Asia", "アジア", "아시아")
add("pin.europe", "Europe", "Avrupa", "Europa", "Europa", "ヨーロッパ", "유럽")
add("pin.cap.land", "Türkiye", "Türkiye", "Türkei", "Turquía", "トルコ", "튀르키예")
add("pin.abq.land", "USA", "ABD", "USA", "EE. UU.", "アメリカ", "미국")
add("pin.luxor.land", "Egypt", "Mısır", "Ägypten", "Egipto", "エジプト", "이집트")
add("pin.asia.land", "Asia", "Asya", "Asien", "Asia", "アジア", "아시아")
add("pin.europe.land", "Europe", "Avrupa", "Europa", "Europa", "ヨーロッパ", "유럽")
add("map.soon", "Coming soon", "Yakında", "Demnächst", "Próximamente", "近日公開", "곧 공개")

# Albuquerque's own names
for k, name in [("stone", "Old Town Adobe Inn"), ("mansion", "Los Poblanos Hacienda"), ("cave", "Sandia Peak Lodge"), ("palace", "Rio Grande Grand Resort")]:
    add("abq.hotel." + k, name, name, name, name, name, name)
for k, name in [("carpet", "Green Chile Co."), ("wine", "Rio Grande Winery"), ("bank", "Turquoise Bank"), ("energy", "Route 66 Energy")]:
    add("abq.sponsor." + k, name, name, name, name, name, name)
add("abq.mission.valley", "Rio Grande touch", "Rio Grande dokunuşu", "Rio-Grande-Berührung", "Toque del Río Grande", "リオグランデ・タッチ", "리오그란데 터치")
add("abq.mission.desc.valley",
 "Drop below 150 m over the Rio Grande and salute the river.",
 "Rio Grande nehrinin üstünde 150 m altına alçal, nehri selamla.",
 "Sinke über dem Rio Grande unter 150 m und grüße den Fluss.",
 "Desciende por debajo de 150 m sobre el Río Grande y saluda al río.",
 "リオグランデ川の上で高度150m以下まで下がり、川にあいさつしよう。",
 "리오그란데강 위에서 150m 아래로 내려가 강에 인사하세요.")

# Day events
add("event.chapterDone",
 "Chapter complete: %1$@! %2$@: %3$@ award.",
 "Bölüm tamamlandı: %1$@! %2$@: %3$@ ödül.",
 "Kapitel geschafft: %1$@! %2$@: %3$@ Preisgeld.",
 "¡Capítulo completado: %1$@! %2$@: premio de %3$@.",
 "章クリア：%1$@！%2$@：賞金%3$@。",
 "챕터 완료: %1$@! %2$@: 상금 %3$@.")
add("event.baron",
 "You've earned the title: %@!",
 "Unvanı kazandın: %@!",
 "Du hast den Titel errungen: %@!",
 "¡Has ganado el título: %@!",
 "称号を獲得：%@！",
 "칭호 획득: %@!")
add("event.rivalsMerged",
 "%1$@ and %2$@ have merged into %3$@. Balloons: %4$@.",
 "%1$@ ile %2$@ birleşti, yeni şirket: %3$@. Balon: %4$@.",
 "%1$@ und %2$@ haben zu %3$@ fusioniert. Ballone: %4$@.",
 "%1$@ y %2$@ se han fusionado en %3$@. Globos: %4$@.",
 "%1$@と%2$@が合併し%3$@に。気球：%4$@機。",
 "%1$@와(과) %2$@ 합병, 새 회사: %3$@. 열기구: %4$@대.")

# Chapters
add("chapter.founding", "Founding", "Kuruluş", "Gründung", "Fundación", "創業", "창업")
add("chapter.rising", "Rising", "Yükseliş", "Aufstieg", "Ascenso", "躍進", "도약")
add("chapter.growth", "Growth", "Büyüme", "Wachstum", "Crecimiento", "成長", "성장")
add("chapter.baron", "Baron of Cappadocia", "Kapadokya Baronu", "Baron von Kappadokien", "Barón de Capadocia", "カッパドキアの男爵", "카파도키아의 남작")
add("chapter.newWorld", "New World", "Yeni Dünya", "Neue Welt", "Nuevo Mundo", "新世界", "신세계")
add("chapter.boxWind", "The Box", "Kutu Rüzgârı", "Die Box", "La Caja", "ボックスの風", "박스 바람")
add("chapter.fiesta", "Fiesta", "Fiesta", "Fiesta", "Fiesta", "フィエスタ", "피에스타")
add("chapter.baronAbq", "Baron of Albuquerque", "Albuquerque Baronu", "Baron von Albuquerque", "Barón de Albuquerque", "アルバカーキの男爵", "앨버커키의 남작")
add("chapter.founding.award",
 "The Cappadocia Tourism Association named you young entrepreneur of the year",
 "Kapadokya Turizm Derneği seni yılın genç girişimcisi seçti",
 "Der Tourismusverband Kappadokien kürte dich zum Jungunternehmer des Jahres",
 "La Asociación de Turismo de Capadocia te nombró joven emprendedor del año",
 "カッパドキア観光協会が君を年間最優秀若手起業家に選んだ",
 "카파도키아 관광협회가 당신을 올해의 청년 기업가로 선정했습니다")
add("chapter.rising.award",
 "The Göreme Municipality named you the fastest-growing company in the valley",
 "Göreme Belediyesi seni vadinin en hızlı büyüyen şirketi seçti",
 "Die Gemeinde Göreme kürte dich zur am schnellsten wachsenden Firma im Tal",
 "El Ayuntamiento de Göreme te nombró la empresa de más rápido crecimiento del valle",
 "ギョレメ市が君を谷で最も急成長した会社に選んだ",
 "괴레메 시가 당신을 계곡에서 가장 빠르게 성장한 회사로 선정했습니다")
add("chapter.growth.award",
 "You were named Balloon Company of the Year at the Türkiye Tourism Awards",
 "Türkiye Turizm Ödülleri'nde Yılın Balon Şirketi seçildin",
 "Bei den Türkiye-Tourismuspreisen wurdest du Ballonfirma des Jahres",
 "Fuiste elegido Empresa de Globos del Año en los Premios de Turismo de Turquía",
 "トルコ観光アワードで年間最優秀気球会社に選ばれた",
 "튀르키예 관광 어워드에서 올해의 열기구 회사로 선정되었습니다")
add("chapter.newWorld.award",
 "The Albuquerque Chamber of Commerce named you New Company of the Year",
 "Albuquerque Ticaret Odası seni Yılın Yeni Şirketi seçti",
 "Die Handelskammer Albuquerque kürte dich zum Neuunternehmen des Jahres",
 "La Cámara de Comercio de Albuquerque te nombró Nueva Empresa del Año",
 "アルバカーキ商工会議所が君を年間最優秀新企業に選んだ",
 "앨버커키 상공회의소가 당신을 올해의 신생 기업으로 선정했습니다")
add("chapter.boxWind.award",
 "The Albuquerque Pilots' Club named you master of the box",
 "Albuquerque Pilotlar Kulübü seni kutunun ustası ilan etti",
 "Der Pilotenclub Albuquerque ernannte dich zum Meister der Box",
 "El Club de Pilotos de Albuquerque te nombró maestro de la caja",
 "アルバカーキ・パイロットクラブが君をボックスの達人と認めた",
 "앨버커키 조종사 클럽이 당신을 박스의 달인으로 인정했습니다")
add("chapter.fiesta.award",
 "The Balloon Fiesta jury named you Star of the Fiesta",
 "Balloon Fiesta jürisi seni Fiesta'nın Yıldızı seçti",
 "Die Jury der Balloon Fiesta kürte dich zum Star der Fiesta",
 "El jurado de la Balloon Fiesta te nombró Estrella de la Fiesta",
 "バルーン・フィエスタの審査員が君をフィエスタのスターに選んだ",
 "벌룬 피에스타 심사위원단이 당신을 피에스타의 스타로 선정했습니다")
add("chapter.baron.award", "", "", "", "", "", "")
add("chapter.baronAbq.award", "", "", "", "", "", "")

# Goals
add("goal.balloons", "Balloons in the fleet: %@", "Filoda balon: %@", "Ballone in der Flotte: %@", "Globos en la flota: %@", "保有気球：%@機", "보유 열기구: %@대")
add("goal.pilots", "Pilots on the team: %@", "Ekipteki pilot: %@", "Piloten im Team: %@", "Pilotos en el equipo: %@", "チームのパイロット：%@", "팀의 조종사: %@")
add("goal.hotelDeals", "Hotel deals: %@", "Otel anlaşması: %@", "Hotelverträge: %@", "Acuerdos con hoteles: %@", "ホテル契約：%@", "호텔 계약: %@")
add("goal.bldMastLevel", "Wind mast level: %@", "Rüzgâr direği seviyesi: %@", "Windmast-Stufe: %@", "Nivel del mástil de viento: %@", "風向きマストのレベル：%@", "풍향 마스트 레벨: %@")
add("goal.bldHangarLevel", "Hangar level: %@", "Hangar seviyesi: %@", "Hangar-Stufe: %@", "Nivel del hangar: %@", "格納庫のレベル：%@", "격납고 레벨: %@")
add("goal.stars", "Popularity %@", "Popülerlik %@", "Beliebtheit %@", "Popularidad %@", "人気 %@", "인기 %@")
add("goal.cash", "Cash: %@", "Kasada: %@", "Kasse: %@", "Caja: %@", "所持金：%@", "보유 현금: %@")
add("goal.hotelDeal", "Sign a deal with a hotel", "Bir otelle anlaşma yap", "Schließe einen Hotelvertrag", "Firma un acuerdo con un hotel", "ホテルと契約する", "호텔과 계약하기")
add("goal.hotelOwn", "Hotels owned: %@", "Sahip olduğun otel: %@", "Eigene Hotels: %@", "Hoteles propios: %@", "所有ホテル：%@軒", "보유 호텔: %@곳")
add("goal.influencer", "Run an influencer campaign", "Bir influencer kampanyası yap", "Starte eine Influencer-Kampagne", "Haz una campaña con influencers", "インフルエンサー企画を実施する", "인플루언서 캠페인 진행하기")
add("goal.guide", "Fly a promo flight for tour guides", "Rehberlere tanıtım uçuşu yap", "Mach einen Werbeflug für Reiseführer", "Haz un vuelo promocional para guías", "ガイド向け招待フライトを飛ぶ", "가이드 홍보 비행하기")
add("goal.share", "Market share: %@", "Pazar payı: %@", "Marktanteil: %@", "Cuota de mercado: %@", "市場シェア：%@", "시장 점유율: %@")
add("goal.workshop", "Build a balloon workshop", "Balon atölyesi kur", "Baue eine Ballonwerkstatt", "Construye un taller de globos", "気球工房を建てる", "열기구 공방 세우기")
add("goal.school", "Found a pilot school", "Pilot okulu kur", "Gründe eine Pilotenschule", "Funda una escuela de pilotos", "パイロット学校を設立する", "조종사 학교 세우기")
add("goal.xl", "Your signature balloon in the sky: %@", "İmza balonun gökyüzünde: %@", "Dein Signaturballon am Himmel: %@", "Tu globo insignia en el cielo: %@", "看板気球を空へ：%@", "시그니처 열기구를 하늘로: %@")
add("goal.fiesta", "Fly at a Balloon Fiesta", "Bir Balloon Fiesta'da uç", "Flieg bei einer Balloon Fiesta", "Vuela en una Balloon Fiesta", "バルーン・フィエスタで飛ぶ", "벌룬 피에스타에서 비행하기")
add("goal.done", "done", "tamam", "erledigt", "hecho", "達成", "완료")
add("goal.notYet", "not yet", "yok", "noch nicht", "aún no", "未達成", "아직")

# Design patterns
for k, v in {
    "stripes": ("Stripes", "Çizgili", "Streifen", "Rayas", "ストライプ", "줄무늬"),
    "zigzag": ("Zigzag", "Zikzak", "Zickzack", "Zigzag", "ジグザグ", "지그재그"),
    "checker": ("Checkers", "Damalı", "Karo", "Cuadros", "チェッカー", "체크"),
    "stars": ("Stars", "Yıldızlı", "Sterne", "Estrellas", "スター", "별무늬"),
    "hearts": ("Hearts", "Kalpli", "Herzen", "Corazones", "ハート", "하트"),
    "sunburst": ("Sunburst", "Güneş", "Sonnenstrahlen", "Sol", "サンバースト", "햇살"),
    "waves": ("Waves", "Dalga", "Wellen", "Olas", "ウェーブ", "물결"),
    "rainbow": ("Rainbow", "Gökkuşağı", "Regenbogen", "Arcoíris", "レインボー", "무지개"),
    "dots": ("Polka dots", "Puantiyeli", "Punkte", "Lunares", "水玉", "물방울"),
}.items():
    add("pattern." + k, *v)

# Offices
add("office.ist", "Istanbul", "İstanbul", "Istanbul", "Estambul", "イスタンブール", "이스탄불")
add("office.nyc", "New York", "New York", "New York", "Nueva York", "ニューヨーク", "뉴욕")
add("office.sel", "Seoul", "Seul", "Seoul", "Seúl", "ソウル", "서울")
add("office.tyo", "Tokyo", "Tokyo", "Tokio", "Tokio", "東京", "도쿄")
add("office.ist.perk",
 "Cappadocia's autopilot income +25%.",
 "Kapadokya'nın otomatik kazancı %25 artar.",
 "Autopilot-Einnahmen in Kappadokien +25 %.",
 "Ingresos en piloto automático de Capadocia +25 %.",
 "カッパドキアの自動運営収入+25%。",
 "카파도키아 자동 운영 수입 +25%.")
add("office.nyc.perk",
 "TV campaigns 25% cheaper, Albuquerque's autopilot income +20%.",
 "TV kampanyaları %25 daha ucuz, Albuquerque'nin otomatik kazancı %20 artar.",
 "TV-Kampagnen 25 % günstiger, Autopilot-Einnahmen in Albuquerque +20 %.",
 "Campañas de TV un 25 % más baratas, ingresos en piloto automático de Albuquerque +20 %.",
 "テレビCMが25%安く、アルバカーキの自動運営収入+20%。",
 "TV 캠페인 25% 할인, 앨버커키 자동 운영 수입 +20%.")
add("office.sel.perk",
 "Celebrity contracts last twice as long and cost 30% less.",
 "Ünlü reklam yüzü sözleşmeleri iki kat uzun ve %30 ucuz.",
 "Promi-Verträge laufen doppelt so lang und kosten 30 % weniger.",
 "Los contratos con famosos duran el doble y cuestan un 30 % menos.",
 "有名人との契約が2倍長く、30%安くなる。",
 "유명인 계약 기간 2배, 비용 30% 할인.")
add("office.tyo.perk",
 "Free design production, creativity +10, designs stay fresh for 60 days. Half-price entry to Asia.",
 "Tasarım üretimi bedava, yaratıcılık +10, tasarımlar 60 gün taze kalır. Asya'ya giriş yarı fiyatına.",
 "Designs kostenlos, Kreativität +10, Designs bleiben 60 Tage frisch. Einstieg in Asien zum halben Preis.",
 "Diseños gratis, creatividad +10, los diseños siguen frescos 60 días. Entrada a Asia a mitad de precio.",
 "デザイン制作が無料、創造性+10、デザインが60日間新鮮。アジア進出が半額。",
 "디자인 제작 무료, 창의성 +10, 디자인 신선도 60일 유지. 아시아 진출 반값.")

# Made-up celebrities for the holding's ad deal
for i, v in enumerate([
    ("Selin Arda (actor)", "Selin Arda (oyuncu)", "Selin Arda (Schauspielerin)", "Selin Arda (actriz)", "セリン・アルダ（俳優）", "셀린 아르다 (배우)"),
    ("Kenji Mori (actor)", "Kenji Mori (aktör)", "Kenji Mori (Schauspieler)", "Kenji Mori (actor)", "森健二（俳優）", "모리 겐지 (배우)"),
    ("Lucía Varela (singer)", "Lucía Varela (şarkıcı)", "Lucía Varela (Sängerin)", "Lucía Varela (cantante)", "ルシア・バレラ（歌手）", "루시아 바렐라 (가수)"),
    ("Emre Kaan (footballer)", "Emre Kaan (futbolcu)", "Emre Kaan (Fußballer)", "Emre Kaan (futbolista)", "エムレ・カーン（サッカー選手）", "엠레 칸 (축구 선수)"),
    ("Ji-ho Park (K-pop star)", "Ji-ho Park (K-pop yıldızı)", "Ji-ho Park (K-Pop-Star)", "Ji-ho Park (estrella del K-pop)", "パク・ジホ（K-POPスター）", "박지호 (K팝 스타)"),
    ("Maya Collins (TV host)", "Maya Collins (sunucu)", "Maya Collins (Moderatorin)", "Maya Collins (presentadora)", "マヤ・コリンズ（司会者）", "마야 콜린스 (방송인)"),
]):
    add(f"celebrity.{i}", *v)

# Autopilot problems
ISSUES = {
    "raise": (
        ("Pilots want a raise", "Pilotlar zam istiyor", "Piloten wollen mehr Geld", "Los pilotos piden aumento", "パイロットが昇給を要求", "조종사 임금 인상 요구"),
        ("The pilots want a raise, or they won't fly for three days.", "Pilotlar maaşlarına zam istiyor, yoksa üç gün uçmayacaklarmış.", "Die Piloten wollen eine Gehaltserhöhung, sonst fliegen sie drei Tage nicht.", "Los pilotos quieren un aumento o no volarán durante tres días.", "パイロットが昇給を求めている。さもなくば3日間飛ばないそうだ。", "조종사들이 임금 인상을 요구합니다. 아니면 3일간 비행하지 않겠답니다."),
        ("No balloon flies without a pilot, kid. A raise is usually cheaper than a strike.", "Pilotsuz balon uçmaz evlat. Zam çoğu zaman greve göre ucuzdur.", "Ohne Piloten fliegt kein Ballon, Lehrling. Eine Erhöhung ist meist billiger als ein Streik.", "Sin piloto no vuela ningún globo, aprendiz. Un aumento suele salir más barato que una huelga.", "パイロットなしに気球は飛ばん。昇給はたいていストより安くつくぞ。", "조종사 없이는 열기구가 못 뜬다네. 인상이 대개 파업보다 싸지."),
        ("Give the raise", "Zam ver", "Erhöhung geben", "Dar el aumento", "昇給する", "인상해 주기"),
        ("The region's daily income drops 6% for good.", "Bölgenin günlük kazancı kalıcı olarak %6 düşer.", "Die Tageseinnahmen der Region sinken dauerhaft um 6 %.", "Los ingresos diarios de la región bajan un 6 % para siempre.", "地域の日収が恒久的に6%下がる。", "지역 일일 수입이 영구적으로 6% 감소합니다."),
        ("Refuse", "Reddet", "Ablehnen", "Rechazar", "断る", "거절하기"),
        ("No income for three days.", "Üç gün hiç kazanç gelmez.", "Drei Tage keine Einnahmen.", "Tres días sin ingresos.", "3日間収入なし。", "3일간 수입 없음."),
    ),
    "war": (
        ("Price war", "Fiyat savaşı", "Preiskampf", "Guerra de precios", "価格競争", "가격 전쟁"),
        ("A rival cut its prices and your balloons are flying half empty.", "Bir rakip biletleri ucuzlattı, balonların yarı boş uçuyor.", "Ein Konkurrent hat die Preise gesenkt, deine Ballone fliegen halb leer.", "Un rival bajó sus precios y tus globos vuelan medio vacíos.", "ライバルが値下げし、君の気球は半分空で飛んでいる。", "경쟁사가 가격을 내려 열기구가 반쯤 빈 채로 날고 있습니다."),
        ("If your popularity is high, waiting can work. If you're not sure, protect your market.", "Popülerliğin yüksekse beklemek işe yarayabilir. Ama emin değilsen pazarını koru.", "Wenn deine Beliebtheit hoch ist, kann Abwarten klappen. Wenn nicht, schütze deinen Markt.", "Si tu popularidad es alta, esperar puede funcionar. Si no estás seguro, protege tu mercado.", "人気が高ければ待つのも手だ。自信がなければ市場を守れ。", "인기가 높다면 기다리는 것도 방법이지. 확신이 없으면 시장을 지키게."),
        ("Match the price", "Fiyatı eşitle", "Preis angleichen", "Igualar el precio", "価格を合わせる", "가격 맞추기"),
        ("Income drops 10% for good, but you keep your market.", "Kazanç kalıcı olarak %10 düşer ama pazarını korursun.", "Die Einnahmen sinken dauerhaft um 10 %, aber du behältst deinen Markt.", "Los ingresos bajan un 10 % para siempre, pero conservas tu mercado.", "収入は恒久的に10%下がるが、市場は守れる。", "수입이 영구적으로 10% 줄지만 시장을 지킵니다."),
        ("Trust your popularity", "Popülerliğine güven", "Auf Beliebtheit vertrauen", "Confiar en tu popularidad", "人気を信じる", "인기를 믿기"),
        ("Fifty-fifty: nothing happens, or income drops 25% for 10 days.", "Yarı yarıya: ya bir şey olmaz ya da 10 gün kazanç %25 düşer.", "Fifty-fifty: Nichts passiert, oder die Einnahmen sinken 10 Tage um 25 %.", "Mitad y mitad: no pasa nada o los ingresos bajan un 25 % durante 10 días.", "五分五分：何も起きないか、10日間収入が25%下がる。", "반반: 아무 일 없거나 10일간 수입 25% 감소."),
    ),
    "accident": (
        ("Hard landing", "Sert iniş", "Harte Landung", "Aterrizaje brusco", "ハードランディング", "거친 착륙"),
        ("A balloon made a hard landing. Passengers are complaining and the local press is at the door.", "Bir balon sert iniş yaptı. Yolcular şikâyetçi, yerel basın kapıda.", "Ein Ballon ist hart gelandet. Die Passagiere beschweren sich, die Lokalpresse steht vor der Tür.", "Un globo aterrizó bruscamente. Los pasajeros se quejan y la prensa local está en la puerta.", "気球がハードランディングした。乗客は苦情を言い、地元の記者が来ている。", "열기구가 거칠게 착륙했습니다. 승객들은 항의하고 지역 언론이 찾아왔습니다."),
        ("On days like this, the boss showing up changes everything.", "Böyle günlerde patronun orada olması her şeyi değiştirir.", "An solchen Tagen ändert es alles, wenn der Chef vor Ort ist.", "En días así, que el jefe aparezca lo cambia todo.", "こういう日は、社長が顔を出すだけで全てが変わる。", "이런 날엔 사장이 직접 나타나는 게 모든 걸 바꾸지."),
        ("Go and handle it", "Gidip kendin ilgilen", "Selbst hinfahren", "Ir y ocuparte tú", "自ら対応しに行く", "직접 가서 처리하기"),
        ("You move to the region; popularity dips a little but the story is over.", "Bölgeye geçersin, popülerlik biraz düşer ama hikâye kapanır.", "Du wechselst in die Region; die Beliebtheit sinkt etwas, aber die Geschichte ist erledigt.", "Te trasladas a la región; la popularidad baja un poco, pero la historia se cierra.", "その地域へ移動する。人気は少し下がるが、騒ぎは収まる。", "그 지역으로 이동합니다. 인기는 조금 떨어지지만 이야기는 끝납니다."),
        ("Let the manager handle it", "Müdür halletsin", "Der Manager soll es regeln", "Que lo resuelva el gerente", "マネージャーに任せる", "매니저에게 맡기기"),
        ("Income drops 15% for 7 days.", "7 gün kazanç %15 düşer.", "7 Tage lang 15 % weniger Einnahmen.", "Los ingresos bajan un 15 % durante 7 días.", "7日間収入が15%下がる。", "7일간 수입 15% 감소."),
    ),
    "hotel": (
        ("Hotel tug-of-war", "Otel kapışması", "Hotel-Gerangel", "Disputa por un hotel", "ホテルの奪い合い", "호텔 쟁탈전"),
        ("A rival is trying to lure away your partner hotel.", "Bir rakip, anlaşmalı otelini kendine çekmeye çalışıyor.", "Ein Konkurrent versucht, dein Partnerhotel abzuwerben.", "Un rival intenta quitarte tu hotel asociado.", "ライバルが提携ホテルを引き抜こうとしている。", "경쟁사가 제휴 호텔을 빼가려 합니다."),
        ("Hotels aren't loyal, kid, but a small gesture is usually enough.", "Oteller sadık değildir evlat, ama küçük bir jest çoğu zaman yeter.", "Hotels sind nicht treu, Lehrling, aber eine kleine Geste genügt meistens.", "Los hoteles no son leales, aprendiz, pero un pequeño gesto suele bastar.", "ホテルに忠誠心はない。だが小さな心づけで大抵は足りる。", "호텔은 의리가 없다네. 하지만 작은 성의면 대개 충분하지."),
        ("Pay a bonus", "Ek ödeme yap", "Prämie zahlen", "Pagar un extra", "上乗せして払う", "추가금 지급하기"),
        ("Paid from the holding; the problem is closed.", "Holding kasasından ödenir, sorun kapanır.", "Wird von der Holding bezahlt; das Problem ist erledigt.", "Lo paga el holding; el problema queda resuelto.", "ホールディングスから支払い、問題は解決。", "지주회사에서 지급하고 문제가 해결됩니다."),
        ("Let it go", "Bırak gitsin", "Gehen lassen", "Dejarlo ir", "手放す", "보내주기"),
        ("Income drops 5% for good.", "Kazanç kalıcı olarak %5 düşer.", "Die Einnahmen sinken dauerhaft um 5 %.", "Los ingresos bajan un 5 % para siempre.", "収入が恒久的に5%下がる。", "수입이 영구적으로 5% 감소합니다."),
    ),
    "envelope": (
        ("Worn envelopes", "Yıpranan zarflar", "Verschlissene Hüllen", "Envolturas gastadas", "傷んだ球皮", "낡은 기구 외피"),
        ("The balloon envelopes are wearing out and the manager wants a renewal budget.", "Balonların zarfları yıpranıyor, müdür yenileme bütçesi istiyor.", "Die Ballonhüllen verschleißen, der Manager will ein Budget für neue.", "Las envolturas se desgastan y el gerente pide presupuesto para renovarlas.", "球皮が傷んできて、マネージャーが交換予算を求めている。", "기구 외피가 낡아 매니저가 교체 예산을 요청합니다."),
        ("Old fabric invites accidents in strong winds. Don't forget that.", "Eski kumaş sert rüzgârda kazaya davetiyedir, unutma.", "Alter Stoff lädt bei starkem Wind zu Unfällen ein, vergiss das nicht.", "La tela vieja invita a accidentes con viento fuerte, no lo olvides.", "古い布は強風で事故を招く。忘れるな。", "낡은 천은 강풍에 사고를 부른다네, 잊지 말게."),
        ("Approve the budget", "Bütçeyi onayla", "Budget freigeben", "Aprobar el presupuesto", "予算を承認する", "예산 승인하기"),
        ("Paid from the holding; the problem is closed.", "Holding kasasından ödenir, sorun kapanır.", "Wird von der Holding bezahlt; das Problem ist erledigt.", "Lo paga el holding; el problema queda resuelto.", "ホールディングスから支払い、問題は解決。", "지주회사에서 지급하고 문제가 해결됩니다."),
        ("Postpone", "Ertele", "Verschieben", "Aplazar", "先送りする", "미루기"),
        ("Income drops 12% for 10 days.", "10 gün kazanç %12 düşer.", "10 Tage lang 12 % weniger Einnahmen.", "Los ingresos bajan un 12 % durante 10 días.", "10日間収入が12%下がる。", "10일간 수입 12% 감소."),
    ),
}
for k, (t, body, hez, a, an, b, bn) in ISSUES.items():
    add(f"issue.{k}", *t)
    add(f"issue.{k}.body", *body)
    add(f"issue.{k}.hez", *hez)
    add(f"issue.{k}.a", *a)
    add(f"issue.{k}.a.note", *an)
    add(f"issue.{k}.b", *b)
    add(f"issue.{k}.b.note", *bn)

# Hezarfen
add("hez.goals",
 "Every great company has a road map, kid. Tap Goals: your chapter goals are there. Finish all three chapters and you become the baron of Cappadocia, and then the world awaits.",
 "Her büyük şirketin bir yol haritası olur evlat. Hedef butonuna dokun: bölüm hedeflerin orada yazıyor. Üç bölümü bitiren Kapadokya'nın baronu olur, sonra da dünya seni bekler.",
 "Jede große Firma hat einen Fahrplan, Lehrling. Tippe auf Ziele: Dort stehen deine Kapitelziele. Wer alle drei Kapitel schafft, wird Baron von Kappadokien, und dann wartet die Welt.",
 "Toda gran empresa tiene una hoja de ruta, aprendiz. Toca Metas: ahí están los objetivos de cada capítulo. Quien termine los tres capítulos será barón de Capadocia, y luego le espera el mundo.",
 "大きな会社には道しるべがあるものだ。「目標」を押してみよ。章ごとの目標が書いてある。三章すべてを終えればカッパドキアの男爵、その先は世界が待っておる。",
 "큰 회사엔 로드맵이 있는 법이지. '목표'를 눌러 보게. 챕터 목표가 적혀 있다네. 세 챕터를 모두 끝내면 카파도키아의 남작이 되고, 그다음엔 세계가 기다리지.")
add("hez.holdingOpened",
 "You have a holding now, kid! Tap Holding. You can move money from the Cappadocia cash box into the holding, and Albuquerque's entry fee is paid from the holding. One warning: holding money never goes back to a country. Each country grows on its own cash.",
 "Artık bir holdingin var evlat! Holding butonuna dokun. Kapadokya kasasından holdinge para çekebilirsin; Albuquerque'nin giriş bedeli holdingden ödenir. Bir uyarı: holding parası ülkelere geri dönmez, her ülke kendi kasasıyla büyür.",
 "Du hast jetzt eine Holding, Lehrling! Tippe auf Holding. Du kannst Geld aus der Kasse in Kappadokien in die Holding holen, und der Einstieg in Albuquerque wird von der Holding bezahlt. Eine Warnung: Holding-Geld fließt nie in ein Land zurück. Jedes Land wächst mit seiner eigenen Kasse.",
 "¡Ya tienes un holding, aprendiz! Toca Holding. Puedes pasar dinero de la caja de Capadocia al holding, y la entrada en Albuquerque se paga desde el holding. Un aviso: el dinero del holding nunca vuelve a un país. Cada país crece con su propia caja.",
 "ついにホールディングスを持ったな、弟子よ！「ホールディングス」を押せ。カッパドキアの金庫から資金を移せるし、アルバカーキへの参入費はホールディングスから払う。ひとつ忠告だ。ホールディングスの金は国へは戻らん。各国は自分の金庫で育つのだ。",
 "이제 지주회사가 생겼네, 제자여! '지주회사'를 눌러 보게. 카파도키아 금고의 돈을 지주회사로 옮길 수 있고, 앨버커키 진출비는 지주회사에서 낸다네. 경고 하나: 지주회사 돈은 절대 나라로 돌아가지 않아. 각 나라는 자기 금고로 커야 하지.")
add("hez.entered.abq",
 "America, kid! The wind in Albuquerque is something else: the famous \"box\". Down low it carries you one way, a little higher it brings you back, so a good pilot lands where they took off. Every 30 days there's the Balloon Fiesta: for four days the tourists double. Everything here runs in dollars and you start from scratch: %@ and one small balloon. Cappadocia keeps earning on autopilot and its income goes to the holding, but the holding can't send money here. You'll make America on your own. If there's trouble, I'll call you.",
 "Amerika evlat! Albuquerque'de rüzgâr bambaşka: meşhur \"kutu\". Alçakta seni bir yöne, biraz yukarıda ters yöne taşır; usta pilot kalktığı yere geri döner. Her 30 günde bir de Balloon Fiesta var: dört gün boyunca turist iki katına çıkar. Burada her şey dolarla döner ve sıfırdan başlıyorsun: %@ ve bir küçük balon. Kapadokya otomatik modda kazanmaya devam edecek, kazancı holdinge gidecek; ama holding buraya para gönderemez, Amerika'yı kendi yağınla kavuracaksın. Bir sorun olursa seni çağırırım.",
 "Amerika, Lehrling! Der Wind in Albuquerque ist etwas Besonderes: die berühmte \"Box\". Unten trägt er dich in eine Richtung, etwas höher zurück, so landet ein guter Pilot dort, wo er gestartet ist. Alle 30 Tage ist Balloon Fiesta: Vier Tage lang kommen doppelt so viele Touristen. Hier läuft alles in Dollar, und du fängst bei null an: %@ und ein kleiner Ballon. Kappadokien verdient im Autopilot weiter und schickt alles an die Holding, aber die Holding kann kein Geld hierher schicken. Amerika musst du allein erobern. Gibt es Ärger, rufe ich dich.",
 "¡América, aprendiz! El viento de Albuquerque es otra cosa: la famosa \"caja\". Abajo te lleva en una dirección y un poco más arriba te devuelve, así que un buen piloto aterriza donde despegó. Cada 30 días hay Balloon Fiesta: durante cuatro días los turistas se duplican. Aquí todo va en dólares y empiezas de cero: %@ y un globo pequeño. Capadocia sigue ganando en piloto automático y sus ingresos van al holding, pero el holding no puede enviar dinero aquí. Conquistarás América con lo tuyo. Si hay problemas, te llamaré.",
 "アメリカだぞ、弟子よ！アルバカーキの風は別物だ。名高い「ボックス」。低空では一方へ、少し上では逆へ運ぶから、腕のいい操縦士は離陸地点に戻ってこられる。30日ごとにバルーン・フィエスタもある。4日間、観光客が倍になる。ここでは全てドルで、ゼロからの出発だ。%@と小さな気球ひとつ。カッパドキアは自動運営で稼ぎ続け、収入はホールディングスへ行く。だがホールディングスからここへは送金できん。アメリカは自力で攻略するのだ。何かあれば呼ぶぞ。",
 "미국이라네, 제자여! 앨버커키의 바람은 완전히 다르지. 그 유명한 '박스'야. 낮은 곳에선 한쪽으로, 조금 위에선 반대로 데려가니, 노련한 조종사는 이륙한 곳에 다시 내린다네. 30일마다 벌룬 피에스타도 열리지. 나흘 동안 관광객이 두 배가 된다네. 여기선 모든 게 달러고 처음부터 시작이야. %@와 작은 열기구 하나. 카파도키아는 자동 운영으로 계속 벌고 그 수입은 지주회사로 가지만, 지주회사는 여기로 돈을 보낼 수 없어. 미국은 자네 힘으로 일궈야 하네. 문제가 생기면 부르겠네.")
add("hez.fiestaStarted",
 "The Albuquerque Balloon Fiesta has begun, kid! For four days tourists will pour in from all over the world and the sky will fill with hundreds of balloons. Get every balloon you have into the air!",
 "Albuquerque Balloon Fiesta başladı evlat! Dört gün boyunca dünyanın dört bir yanından turist akın edecek, gökyüzü yüzlerce balonla dolacak. Bütün balonlarını havaya kaldır!",
 "Die Albuquerque Balloon Fiesta hat begonnen, Lehrling! Vier Tage lang strömen Touristen aus aller Welt herbei, und der Himmel füllt sich mit Hunderten Ballonen. Bring jeden Ballon, den du hast, in die Luft!",
 "¡Ha empezado la Balloon Fiesta de Albuquerque, aprendiz! Durante cuatro días llegarán turistas de todo el mundo y el cielo se llenará de cientos de globos. ¡Sube todos tus globos al aire!",
 "アルバカーキ・バルーン・フィエスタが始まったぞ、弟子よ！4日間、世界中から観光客が押し寄せ、空は何百もの気球で埋まる。持っている気球を全部飛ばせ！",
 "앨버커키 벌룬 피에스타가 시작됐네, 제자여! 나흘 동안 전 세계에서 관광객이 몰려오고 하늘은 수백 개의 열기구로 가득 찰 걸세. 가진 열기구를 모두 띄우게!")
add("hez.regionIssue",
 "News from %1$@, kid: %2$@ Until you decide, income there is cut in half. Tap the alert on the home screen or open the holding.",
 "%1$@ bölgesinden haber var evlat: %2$@ Karar verene kadar oradaki kazancın yarıya düştü. Ana ekrandaki uyarıya dokun ya da holdingi aç.",
 "Neuigkeiten aus %1$@, Lehrling: %2$@ Bis du entscheidest, halbieren sich die Einnahmen dort. Tippe auf die Warnung auf dem Startbildschirm oder öffne die Holding.",
 "Noticias de %1$@, aprendiz: %2$@ Hasta que decidas, los ingresos allí se reducen a la mitad. Toca el aviso en la pantalla principal o abre el holding.",
 "%1$@から知らせだ、弟子よ。%2$@ 君が決めるまで、そこの収入は半分になる。ホーム画面の警告を押すか、ホールディングスを開け。",
 "%1$@에서 소식이 왔네, 제자여. %2$@ 자네가 결정할 때까지 그곳 수입은 절반으로 줄어. 홈 화면의 알림을 누르거나 지주회사를 열게.")
add("hez.officeOpened",
 "Your new office is open, kid: %@!",
 "Yeni ofisin açıldı evlat: %@!",
 "Dein neues Büro ist eröffnet, Lehrling: %@!",
 "¡Tu nueva oficina está abierta, aprendiz: %@!",
 "新しいオフィスが開いたぞ、弟子よ：%@！",
 "새 사무소가 문을 열었네, 제자여: %@!")
add("hez.allOffices",
 "All four offices are open, kid! New York, Istanbul, Tokyo, Seoul... You're a real global company now. Shared costs fell: holding expenses are down to 20%.",
 "Dört ofisin de açık evlat! New York, İstanbul, Tokyo, Seul... Artık gerçek bir dünya şirketisin. Ortak giderler azaldı, holding giderlerin %20'ye indi.",
 "Alle vier Büros sind offen, Lehrling! New York, Istanbul, Tokio, Seoul... Du bist jetzt ein echter Weltkonzern. Die gemeinsamen Kosten sind gesunken: Die Holding-Ausgaben liegen nur noch bei 20 %.",
 "¡Las cuatro oficinas están abiertas, aprendiz! Nueva York, Estambul, Tokio, Seúl... Ya eres una empresa global de verdad. Los gastos comunes bajaron: los gastos del holding son ahora del 20 %.",
 "4つのオフィスがすべて開いたぞ、弟子よ！ニューヨーク、イスタンブール、東京、ソウル……もう本物の世界企業だ。共通経費が減り、ホールディングスの経費は20%になった。",
 "네 사무소가 모두 문을 열었네, 제자여! 뉴욕, 이스탄불, 도쿄, 서울... 이제 진짜 세계적인 회사야. 공통 비용이 줄어 지주회사 경비가 20%로 내려갔다네.")
add("hez.celebritySigned",
 "%@ is now the face of your ads! Posters everywhere, kid, the phones won't stop ringing.",
 "Reklamlarının yeni yüzü: %@! Afişler her yerde evlat, telefonlar susmuyor.",
 "%@ ist jetzt das Gesicht deiner Werbung! Plakate überall, Lehrling, die Telefone stehen nicht still.",
 "¡%@ es ahora la imagen de tus anuncios! Carteles por todas partes, aprendiz, los teléfonos no paran.",
 "%@が君の広告の顔になったぞ！ポスターがあちこちに、電話が鳴りやまん。",
 "%@ 이제 자네 광고의 얼굴이네! 포스터가 사방에 붙고 전화가 끊이질 않아.")
for k, v in {
    "mesaGold": (
        "Mesa Gold Balloons has come to Albuquerque with Texas oil money! Deep pockets and a big fleet. Be careful, kid.",
        "Mesa Gold Balloons, Teksas petrol parasıyla Albuquerque'ye geldi! Kesesi derin, filosu büyük. Dikkatli ol evlat.",
        "Mesa Gold Balloons ist mit texanischem Ölgeld nach Albuquerque gekommen! Volle Kassen und eine große Flotte. Pass auf, Lehrling.",
        "¡Mesa Gold Balloons ha llegado a Albuquerque con dinero del petróleo de Texas! Bolsillos llenos y una gran flota. Cuidado, aprendiz.",
        "メサ・ゴールド・バルーンズがテキサスの石油マネーでアルバカーキにやって来た！資金も機体も豊富だ。気をつけろ。",
        "메사 골드 벌룬스가 텍사스 석유 자본을 등에 업고 앨버커키에 왔네! 돈도 많고 기단도 크지. 조심하게."),
    "turquoise": (
        "An aggressive budget outfit called Turquoise Trail Air has opened. They'll cut prices and don't care much for the rules.",
        "Turquoise Trail Air diye agresif bir ucuzcu açıldı. Fiyat kıracaklar, kuralları da pek takmazlar.",
        "Ein aggressiver Billiganbieter namens Turquoise Trail Air hat eröffnet. Sie werden Preise drücken und halten sich kaum an Regeln.",
        "Ha abierto una aerolínea low cost agresiva llamada Turquoise Trail Air. Bajarán precios y no respetan mucho las reglas.",
        "ターコイズ・トレイル・エアという攻撃的な格安業者が開業した。値下げしてくるし、規則もあまり守らん。",
        "터쿼이즈 트레일 에어라는 공격적인 저가 업체가 문을 열었네. 가격을 깎고 규칙도 잘 안 지킬 걸세."),
    "desertBloom": (
        "A luxury boutique called Desert Bloom Flights has opened. Few balloons, high prices, very popular.",
        "Desert Bloom Flights adında lüks bir butik şirket açıldı. Az balon, yüksek fiyat, çok popüler.",
        "Eine Luxus-Boutique namens Desert Bloom Flights hat eröffnet. Wenige Ballone, hohe Preise, sehr beliebt.",
        "Ha abierto una empresa boutique de lujo llamada Desert Bloom Flights. Pocos globos, precios altos y mucha popularidad.",
        "デザート・ブルーム・フライツという高級ブティックが開業した。機数は少なく高価格、だが大人気だ。",
        "데저트 블룸 플라이츠라는 고급 부티크 업체가 문을 열었네. 열기구는 적고 가격은 높지만 인기가 대단하지."),
    "bigSky": (
        "Big Sky Fiesta Co. from California has opened a branch here. A balanced, solid rival.",
        "Big Sky Fiesta Co. Kaliforniya'dan şube açtı. Dengeli, sağlam bir rakip.",
        "Big Sky Fiesta Co. aus Kalifornien hat hier eine Filiale eröffnet. Ein ausgewogener, solider Konkurrent.",
        "Big Sky Fiesta Co., de California, ha abierto una sucursal aquí. Un rival equilibrado y sólido.",
        "カリフォルニアのビッグ・スカイ・フィエスタ社が支店を出した。バランスの取れた手堅いライバルだ。",
        "캘리포니아의 빅 스카이 피에스타가 지점을 열었네. 균형 잡힌 탄탄한 경쟁자지."),
}.items():
    add("hez.entrant." + k, *v)

# Design reviews
add("review.design.0",
 "We booked after seeing the \"{d}\" balloon. The photos are legendary!",
 "\"{d}\" desenli balonu görünce rezervasyon yaptık, fotoğraflar efsane oldu!",
 "Wir haben gebucht, nachdem wir den Ballon \"{d}\" gesehen hatten. Die Fotos sind legendär!",
 "Reservamos después de ver el globo \"{d}\". ¡Las fotos son legendarias!",
 "「{d}」柄の気球を見て予約した。写真が最高！",
 "'{d}' 무늬 열기구를 보고 예약했어요. 사진이 전설이에요!")
add("review.design.1",
 "\"{d}\" was the most beautiful balloon in the sky. Being in it felt special.",
 "Gökyüzündeki en güzel balon \"{d}\" idi, içinde olmak ayrıcalıktı.",
 "\"{d}\" war der schönste Ballon am Himmel. Darin zu sein war etwas Besonderes.",
 "\"{d}\" era el globo más bonito del cielo. Ir dentro fue un privilegio.",
 "空でいちばん美しい気球は「{d}」だった。乗れて光栄。",
 "하늘에서 가장 아름다운 열기구는 '{d}'였어요. 타는 것만으로 특별했어요.")
add("review.design.2",
 "The \"{d}\" design is so creative, the kids loved it.",
 "\"{d}\" deseni çok yaratıcı, çocuklar bayıldı.",
 "Das Design \"{d}\" ist so kreativ, die Kinder waren begeistert.",
 "El diseño \"{d}\" es muy creativo, a los niños les encantó.",
 "「{d}」のデザインはとても独創的。子どもたちが大喜び。",
 "'{d}' 디자인이 정말 창의적이에요. 아이들이 너무 좋아했어요.")

# Day report
add("ledger.chapterReward", "Chapter award", "Bölüm ödülü", "Kapitelpreis", "Premio del capítulo", "章の賞金", "챕터 상금")
add("report.designBuzz",
 "Your designs are the talk of the town: popularity is up.",
 "Tasarımların konuşuluyor: popülerliğin arttı.",
 "Deine Designs sind Stadtgespräch: Die Beliebtheit steigt.",
 "Todo el mundo habla de tus diseños: tu popularidad sube.",
 "君のデザインが話題だ。人気が上がった。",
 "디자인이 화제가 되어 인기가 올랐습니다.")
add("report.holding",
 "Holding cash +%1$@ from regions on autopilot, after holding expenses (%2$@). Holding cash: %3$@.",
 "Holding kasasına +%1$@: otomatik moddaki bölgeler kazandı, holding giderleri (%2$@) düşüldü. Holding kasası: %3$@.",
 "Holding-Kasse +%1$@ aus Regionen im Autopilot, nach Holding-Ausgaben (%2$@). Holding-Kasse: %3$@.",
 "Caja del holding +%1$@ de regiones en piloto automático, tras los gastos del holding (%2$@). Caja del holding: %3$@.",
 "自動運営の地域からホールディングスへ+%1$@（経費%2$@差引後）。ホールディングス残高：%3$@。",
 "자동 운영 지역에서 지주회사로 +%1$@ (지주회사 경비 %2$@ 차감). 지주회사 금고: %3$@.")

# Setup: the first review
add("country.goreme", "Göreme", "Göreme", "Göreme", "Göreme", "ギョレメ", "괴레메")
add("review.welcome.0",
 "I hear {c} is starting tours. Finally a proper company, it seems!",
 "{c} turlara başlıyormuş. Sonunda galiba düzgün bir şirket geldi!",
 "Wie ich höre, startet {c} mit Touren. Endlich mal eine ordentliche Firma, scheint's!",
 "Dicen que {c} empieza con los vuelos. ¡Por fin una empresa como es debido, parece!",
 "{c}がツアーを始めるらしい。ようやくまともな会社が来たみたいだ！",
 "{c}가 투어를 시작한대요. 드디어 제대로 된 회사가 온 것 같네요!")
