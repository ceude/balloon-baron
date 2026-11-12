from s1_ui import add

# v140 (developer, from the holding economy review in tools/sim-holding.js): new holding prices, office rent, better
# office perks, the World Games again every 360 days, the International Balloon Festival and the Hot Air Foundation.

# Offices: perks and rent
add("holding.officesRent",
    "Rent and staff for your offices come out of the holding every evening: %@ a day.",
    "Ofislerinin kirası ve personeli her akşam holding kasasından ödenir: günde %@.",
    "Miete und Personal deiner Büros zahlt die Holding jeden Abend: %@ am Tag.",
    "El alquiler y el personal de tus oficinas salen del holding cada noche: %@ al día.",
    "オフィスの家賃と人件費は毎晩ホールディングスから支払われる：1日%@。",
    "사무소 임대료와 인건비는 매일 저녁 지주회사에서 나갑니다: 하루 %@.")
add("holding.officesRentNone",
    "Each office's rent and staff come out of the holding every evening.",
    "Her ofisin kirası ve personeli her akşam holding kasasından ödenir.",
    "Miete und Personal jedes Büros zahlt die Holding jeden Abend.",
    "El alquiler y el personal de cada oficina salen del holding cada noche.",
    "各オフィスの家賃と人件費は毎晩ホールディングスから支払われる。",
    "각 사무소의 임대료와 인건비는 매일 저녁 지주회사에서 나갑니다.")
add("holding.rentLine", "Office rent and staff", "Ofis kirası ve personel", "Büromiete und Personal",
    "Alquiler y personal de oficinas", "オフィスの家賃と人件費", "사무소 임대료와 인건비")
add("holding.perDayValue", "%@/day", "%@/gün", "%@/Tag", "%@/día", "%@/日", "%@/일")
add("holding.legendExpense",
    "Expenses: holding costs (%@), office rent and investments",
    "Gider: holding giderleri (%@), ofis kiraları ve yatırımlar",
    "Ausgaben: Holding-Ausgaben (%@), Büromieten und Investitionen",
    "Gastos: costes del holding (%@), alquiler de oficinas e inversiones",
    "支出：ホールディングス経費（%@）、オフィスの家賃と投資",
    "지출: 지주회사 비용(%@), 사무소 임대료와 투자")
add("why.offices", "Offices", "Ofisler", "Büros", "Oficinas", "オフィス", "사무소")

# Celebrity: the first deal is a rising star's
add("holding.celeb.descFirst",
    "Your first contract is with a rising star: the agents give you a better price this time. Later faces cost more.",
    "İlk sözleşmen yükselen bir yıldızla: menajerler bu sefer indirim yapıyor. Sonraki yüzler daha pahalı.",
    "Dein erster Vertrag ist mit einem aufstrebenden Star: Diesmal machen dir die Agenten einen besseren Preis. Spätere Gesichter kosten mehr.",
    "Tu primer contrato es con una estrella en ascenso: esta vez los representantes te hacen mejor precio. Las siguientes caras costarán más.",
    "最初の契約は売り出し中のスター。今回はエージェントが値引きしてくれる。次からの顔はもっと高い。",
    "첫 계약은 떠오르는 스타와 맺습니다. 이번엔 에이전시가 할인해 줍니다. 다음 얼굴부터는 더 비쌉니다.")

# World Games: again every 360 days
add("holding.wg.desc",
    "The official balloon show of the World Games opening ceremony. Hundreds of balloons over the stadium, live around the world. The Games come round every 360 days.",
    "Dünya Oyunları açılış töreninin resmî balon gösterisi. Stadyumun üstünde yüzlerce balon, bütün dünyada canlı yayın. Oyunlar 360 günde bir yapılır.",
    "Die offizielle Ballonshow der Eröffnungsfeier der Weltspiele. Hunderte Ballone über dem Stadion, weltweit live. Die Spiele finden alle 360 Tage statt.",
    "El espectáculo oficial de globos de la ceremonia inaugural de los Juegos Mundiales. Cientos de globos sobre el estadio, en directo para todo el mundo. Los Juegos se celebran cada 360 días.",
    "世界競技大会開会式の公式バルーンショー。スタジアムの上に何百もの気球、世界中に生中継。大会は360日ごとに開かれる。",
    "세계 대회 개막식의 공식 열기구 쇼. 경기장 위의 수백 대의 열기구, 전 세계 생중계. 대회는 360일마다 열립니다.")
add("holding.wg.descDone",
    "You put on the opening ceremony's show; the world is still talking about it. The organisers want you for the next Games too.",
    "Açılış töreninin gösterisini yaptın; dünya hâlâ konuşuyor. Organizatörler sonraki Oyunlar için de seni istiyor.",
    "Du hast die Show zur Eröffnungsfeier gemacht; die Welt spricht noch davon. Die Veranstalter wollen dich auch für die nächsten Spiele.",
    "Hiciste el espectáculo de la ceremonia inaugural; el mundo aún habla de ello. Los organizadores te quieren también para los próximos Juegos.",
    "開会式のショーを成功させた。世界はまだその話をしている。主催者は次の大会でもあなたを望んでいる。",
    "개막식 쇼를 해냈습니다. 세계는 아직도 그 이야기를 합니다. 주최 측은 다음 대회에도 당신을 원합니다.")
add("holding.wg.descAgain",
    "New World Games are coming, and the organisers offer you the opening show again. Each show is bigger than the last.",
    "Yeni Dünya Oyunları geliyor; organizatörler açılış gösterisini yine sana teklif ediyor. Her seferinde daha büyük bir gösteri.",
    "Neue Weltspiele stehen an, und die Veranstalter bieten dir wieder die Eröffnungsshow an. Jede Show ist größer als die letzte.",
    "Llegan nuevos Juegos Mundiales y los organizadores vuelven a ofrecerte el espectáculo inaugural. Cada uno es más grande que el anterior.",
    "新しい世界競技大会が近づき、主催者が再び開会式のショーを依頼してきた。毎回、前回より大きなショーになる。",
    "새 세계 대회가 다가오고, 주최 측이 다시 개막식 쇼를 제안합니다. 쇼는 매번 지난번보다 커집니다.")
add("holding.wg.chipStep", "Next Games: price ×%@", "Sonraki Oyunlar: fiyat ×%@", "Nächste Spiele: Preis ×%@",
    "Próximos Juegos: precio ×%@", "次の大会：価格×%@", "다음 대회: 가격 ×%@")
add("holding.wg.ctaN", "Take on show no. %@", "%@. gösteriyi üstlen", "Show Nr. %@ übernehmen",
    "Organizar el espectáculo n.º %@", "%@回目のショーを引き受ける", "%@번째 쇼 맡기")
add("holding.wg.wait", "Shows: %1$@ · next Games in days: %2$@", "Gösteri: %1$@ · sonraki Oyunlara kalan gün: %2$@",
    "Shows: %1$@ · nächste Spiele in Tagen: %2$@", "Espectáculos: %1$@ · próximos Juegos en días: %2$@",
    "ショー：%1$@回・次の大会まであと%2$@日", "쇼: %1$@회 · 다음 대회까지 남은 일수: %2$@")

# The International Balloon Festival
add("hq.festival", "Festival office", "Festival ofisi", "Festivalbüro", "Oficina del festival", "フェスティバル事務局", "축제 사무국")
add("hq.s.festivalOn", "%1$@, days: %2$@", "%1$@, gün: %2$@", "%1$@, Tage: %2$@", "%1$@, días: %2$@", "%1$@、残り%2$@日", "%1$@, 남은 일수: %2$@")
add("hq.s.festivalWait", "Next festival in days: %@", "Sonraki festivale gün: %@", "Nächstes Festival in Tagen: %@",
    "Próximo festival en días: %@", "次の祭りまで%@日", "다음 축제까지 %@일")
add("hq.s.festivals", "Festivals: %@", "Festival: %@", "Festivals: %@", "Festivales: %@", "開催：%@回", "축제: %@회")
add("hq.s.noFestival", "No festival yet", "Henüz festival yok", "Noch kein Festival", "Aún sin festival", "まだ開催なし", "아직 축제 없음")
add("holding.fest.section", "International Balloon Festival", "Uluslararası Balon Festivali", "Internationales Ballonfestival",
    "Festival Internacional de Globos", "国際バルーンフェスティバル", "국제 열기구 축제")
add("holding.fest.hint",
    "Invite pilots from every continent to a region you own. Each festival leaves that region a little more famous for good. One festival at a time.",
    "Sahip olduğun bir bölgeye her kıtadan pilotları davet et. Her festival o bölgeyi kalıcı olarak biraz daha ünlü yapar. Aynı anda bir festival.",
    "Lade Piloten aus allen Kontinenten in eine deiner Regionen ein. Jedes Festival macht die Region dauerhaft ein wenig berühmter. Immer nur ein Festival zugleich.",
    "Invita a pilotos de todos los continentes a una de tus regiones. Cada festival deja esa región un poco más famosa para siempre. Un festival a la vez.",
    "自分の地域にあらゆる大陸から操縦士を招こう。祭りを開くたびに、その地域の名はずっと少しずつ高まる。開催は一度に一つ。",
    "소유한 지역에 모든 대륙의 조종사를 초대하세요. 축제를 열 때마다 그 지역은 영구히 조금 더 유명해집니다. 축제는 한 번에 하나.")
add("holding.fest.kicker", "International event", "Uluslararası etkinlik", "Internationales Ereignis", "Evento internacional", "国際イベント", "국제 행사")
add("holding.fest.title", "International Balloon Festival", "Uluslararası Balon Festivali", "Internationales Ballonfestival",
    "Festival Internacional de Globos", "国際バルーンフェスティバル", "국제 열기구 축제")
add("holding.fest.desc",
    "Your own festival: pilots from all over the world, glowing nights, packed squares. Tourists pour in, and every festival makes the region's name a little better known.",
    "Kendi festivalin: dünyanın dört bir yanından pilotlar, ışıl ışıl geceler, kalabalık meydanlar. Turist akın eder; her festival bölgenin adını biraz daha duyurur.",
    "Dein eigenes Festival: Piloten aus aller Welt, leuchtende Nächte, volle Plätze. Die Touristen strömen herbei, und jedes Festival macht den Namen der Region ein wenig bekannter.",
    "Tu propio festival: pilotos de todo el mundo, noches resplandecientes, plazas llenas. Los turistas llegan en masa y cada festival da a conocer un poco más la región.",
    "自分の祭り：世界中の操縦士、輝く夜、にぎわう広場。観光客が押し寄せ、祭りのたびに地域の名が少しずつ知れ渡る。",
    "당신만의 축제: 전 세계의 조종사, 빛나는 밤, 붐비는 광장. 관광객이 몰려들고, 축제를 열 때마다 지역의 이름이 조금씩 더 알려집니다.")
add("holding.fest.descOn",
    "%@ is the balloon capital of the world right now: pilots from every continent, glowing nights, packed squares.",
    "%@ şu an dünyanın balon başkenti: her kıtadan pilotlar, ışıl ışıl geceler, kalabalık meydanlar.",
    "%@ ist gerade die Ballonhauptstadt der Welt: Piloten aus allen Kontinenten, leuchtende Nächte, volle Plätze.",
    "%@ es ahora mismo la capital mundial del globo: pilotos de todos los continentes, noches resplandecientes, plazas llenas.",
    "いま世界の気球の都は%@：あらゆる大陸の操縦士、輝く夜、にぎわう広場。",
    "지금 세계 열기구의 수도는 %@: 모든 대륙의 조종사, 빛나는 밤, 붐비는 광장.")
add("holding.fest.chipFame", "Festival fame: lasting +%1$@ (up to %2$@)", "Festival ünü: kalıcı +%1$@ (en çok %2$@)",
    "Festivalruhm: dauerhaft +%1$@ (bis %2$@)", "Fama de festival: +%1$@ para siempre (hasta %2$@)",
    "フェスティバルの名声：永続+%1$@（最大%2$@）", "축제 명성: 영구 +%1$@ (최대 %2$@)")
add("holding.fest.chipEvery", "Between festivals (days): %@", "Festivaller arası (gün): %@", "Zwischen Festivals (Tage): %@",
    "Entre festivales (días): %@", "祭りの間隔（日）：%@", "축제 간격(일): %@")
add("holding.fest.chipStep", "Each festival %1$@ more (up to %2$@)", "Her festival %1$@ daha pahalı (en çok %2$@)",
    "Jedes Festival %1$@ teurer (bis %2$@)", "Cada festival %1$@ más (hasta %2$@)",
    "毎回%1$@ずつ値上がり（最大%2$@）", "축제마다 %1$@씩 인상 (최대 %2$@)")
add("holding.fest.on", "Festival on · days left: %@", "Festival sürüyor · kalan gün: %@", "Festival läuft · Resttage: %@",
    "Festival en curso · días restantes: %@", "開催中・残り日数：%@", "축제 중 · 남은 일수: %@")
add("holding.fest.fame", "Festival fame +%1$@ · festivals: %2$@", "Festival ünü +%1$@ · festival: %2$@", "Festivalruhm +%1$@ · Festivals: %2$@",
    "Fama de festival +%1$@ · festivales: %2$@", "名声+%1$@・開催%2$@回", "축제 명성 +%1$@ · 축제: %2$@회")
add("holding.fest.none", "No festival yet", "Henüz festival yok", "Noch kein Festival", "Aún sin festival", "まだ開催なし", "아직 축제 없음")
add("holding.fest.wait", "Next festival in days: %@", "Sonraki festivale kalan gün: %@", "Nächstes Festival in Tagen: %@",
    "Próximo festival en días: %@", "次の祭りまであと%@日", "다음 축제까지 남은 일수: %@")
add("holding.fest.cta", "Host the festival", "Festivali düzenle", "Festival ausrichten", "Organizar el festival", "祭りを開く", "축제 열기")
add("why.hostedFestival", "International festival", "Uluslararası festival", "Internationales Festival", "Festival internacional", "国際フェスティバル", "국제 축제")
add("why.festivalFame", "Festival fame", "Festival ünü", "Festivalruhm", "Fama de festival", "フェスティバルの名声", "축제 명성")
add("hez.festivalHosted",
    "%@ is the balloon capital of the world this week, kid! Your own festival: ten days of pilots from every continent and a sky full of colour. The tourists will pour in.",
    "%@ bu hafta dünyanın balon başkenti evlat! Senin festivalin: on gün boyunca her kıtadan pilotlar, gökyüzü renk renk. Turistler akın edecek.",
    "%@ ist diese Woche die Ballonhauptstadt der Welt, Lehrling! Dein eigenes Festival: zehn Tage Piloten aus allen Kontinenten und ein Himmel voller Farben. Die Touristen werden in Scharen kommen.",
    "¡%@ es esta semana la capital mundial del globo, aprendiz! Tu propio festival: diez días de pilotos de todos los continentes y un cielo lleno de color. Los turistas llegarán en masa.",
    "今週は%@が世界の気球の都だ、弟子よ！お前の祭りだ。十日間、あらゆる大陸から操縦士が集まり、空は色であふれる。観光客が押し寄せるぞ。",
    "이번 주 세계 열기구의 수도는 바로 %@, 제자여! 자네의 축제야. 열흘 동안 모든 대륙에서 조종사들이 모이고 하늘이 온통 색으로 물들지. 관광객이 몰려올 거야.")
add("paper.festivalHosted", "%@ International Balloon Festival opens", "%@ Uluslararası Balon Festivali başladı",
    "Internationales Ballonfestival von %@ eröffnet", "Abre el Festival Internacional de Globos de %@",
    "%@国際バルーンフェスティバル開幕", "%@ 국제 열기구 축제 개막")
add("paper.festivalHosted.sub", "For ten days %@ welcomes balloons from all over the world.",
    "%@ on gün boyunca dünyanın dört bir yanından balonları ağırlıyor.",
    "Zehn Tage lang empfängt %@ Ballone aus aller Welt.", "Durante diez días, %@ recibe globos de todo el mundo.",
    "十日間、%@に世界中から気球が集まる。", "열흘 동안 %@에 전 세계의 열기구가 모입니다.")
add("home.alert.hfest", "International Balloon Festival, day %1$@/%2$@!", "Uluslararası Balon Festivali, gün %1$@/%2$@!",
    "Internationales Ballonfestival, Tag %1$@/%2$@!", "¡Festival Internacional de Globos, día %1$@/%2$@!",
    "国際バルーンフェスティバル、%1$@/%2$@日目！", "국제 열기구 축제, %1$@/%2$@일차!")
add("home.alert.hfest.body", "Your own festival: tourists +%@, and the sky full of balloons from every continent.",
    "Senin festivalin: turist +%@, gökyüzü her kıtadan balonla dolu.",
    "Dein eigenes Festival: Touristen +%@, der Himmel voller Ballone aus allen Kontinenten.",
    "Tu propio festival: turistas +%@ y el cielo lleno de globos de todos los continentes.",
    "あなたの祭り：観光客+%@、空はあらゆる大陸の気球でいっぱい。",
    "당신의 축제: 관광객 +%@, 하늘은 모든 대륙의 열기구로 가득합니다.")
add("night.fglow",
    "International Balloon Festival night: balloons from every continent glow on the field.",
    "Uluslararası Balon Festivali gecesi: her kıtadan balonlar yerde ışıldıyor.",
    "Nacht des Internationalen Ballonfestivals: Ballone aus allen Kontinenten leuchten auf der Wiese.",
    "Noche del Festival Internacional de Globos: globos de todos los continentes brillan en el campo.",
    "国際バルーンフェスティバルの夜：あらゆる大陸の気球が地上で輝く。",
    "국제 열기구 축제의 밤: 모든 대륙에서 온 열기구들이 들판에서 빛납니다.")
add("paper.night.fglow", "Festival night: the world's balloons glowed", "Festival gecesi: dünyanın balonları ışıldadı",
    "Festivalnacht: Die Ballone der Welt leuchteten", "Noche de festival: brillaron los globos del mundo",
    "祭りの夜、世界の気球が輝いた", "축제의 밤, 세계의 열기구가 빛나다")
add("paper.night.fglow.sub",
    "The international festival's guest pilots fired their burners to music.",
    "Uluslararası festivalin konuk pilotları brülörlerini müzikle yaktı.",
    "Die Gastpiloten des internationalen Festivals zündeten ihre Brenner zur Musik.",
    "Los pilotos invitados del festival internacional encendieron sus quemadores al ritmo de la música.",
    "国際フェスティバルのゲスト操縦士たちが音楽に合わせてバーナーを焚いた。",
    "국제 축제의 초청 조종사들이 음악에 맞춰 버너를 켰습니다.")

# The Hot Air Foundation
add("hq.foundation", "Hot Air Foundation", "Sıcak Hava Vakfı", "Heißluft-Stiftung", "Fundación Aire Caliente", "ホットエア財団", "핫에어 재단")
add("hq.s.projects", "Projects: %@", "Proje: %@", "Projekte: %@", "Proyectos: %@", "事業：%@件", "사업: %@건")
add("hq.s.noProject", "No project yet", "Henüz proje yok", "Noch kein Projekt", "Aún sin proyectos", "まだ事業なし", "아직 사업 없음")
add("holding.fdn.section", "Foundation projects", "Vakıf projeleri", "Projekte der Stiftung", "Proyectos de la fundación", "財団の事業", "재단 사업")
add("holding.fdn.hint",
    "Give back where you fly. Every project lifts your popularity in all your regions, and a small monument in that region's town remembers it. There is no end to them.",
    "Uçtuğun yerlere bir şey geri ver. Her proje bütün bölgelerinde popülerliğini artırır, o bölgenin kasabasında küçük bir anıt projeyi anar. Projelerin sonu yok.",
    "Gib den Orten etwas zurück, an denen du fliegst. Jedes Projekt hebt deine Beliebtheit in allen Regionen, und ein kleines Denkmal in der Stadt der Region erinnert daran. Ein Ende gibt es nicht.",
    "Devuelve algo a los lugares donde vuelas. Cada proyecto aumenta tu popularidad en todas tus regiones, y un pequeño monumento en el pueblo de esa región lo recuerda. No tienen fin.",
    "飛ぶ土地に恩返しを。事業ごとに全地域で人気が上がり、その地域の町に小さな記念碑が残る。事業に終わりはない。",
    "날아다니는 곳에 보답하세요. 사업마다 모든 지역에서 인기가 오르고, 그 지역 마을의 작은 기념비가 사업을 기억합니다. 사업에는 끝이 없습니다.")
add("holding.fdn.kicker", "Hot Air Foundation", "Sıcak Hava Vakfı", "Heißluft-Stiftung", "Fundación Aire Caliente", "ホットエア財団", "핫에어 재단")
add("holding.fdn.title", "The foundation's first project", "Vakfın ilk projesi", "Das erste Projekt der Stiftung",
    "El primer proyecto de la fundación", "財団の最初の事業", "재단의 첫 사업")
add("holding.fdn.titleN", "The foundation's legacy · projects: %@", "Vakfın mirası · proje: %@", "Das Vermächtnis der Stiftung · Projekte: %@",
    "El legado de la fundación · proyectos: %@", "財団の足跡・事業%@件", "재단의 유산 · 사업: %@건")
add("holding.fdn.desc",
    "Give back what you earned: from restoring a fresco to a school library, every project leaves a lasting mark on a region. A small monument in its town remembers it.",
    "Kazandığını geri ver: fresk restorasyonundan okul kitaplığına, her proje bir bölgede kalıcı bir iz bırakır. Kasabasında küçük bir anıt projeyi anar.",
    "Gib zurück, was du verdient hast: von der Restaurierung eines Freskos bis zur Schulbibliothek hinterlässt jedes Projekt eine bleibende Spur in einer Region. Ein kleines Denkmal in ihrer Stadt erinnert daran.",
    "Devuelve lo que has ganado: de restaurar un fresco a una biblioteca escolar, cada proyecto deja una huella duradera en una región. Un pequeño monumento en su pueblo lo recuerda.",
    "稼いだものを還元しよう。フレスコ画の修復から学校の図書室まで、事業はどれも地域に消えない足跡を残す。町の小さな記念碑がそれを伝える。",
    "번 것을 돌려주세요. 프레스코화 복원부터 학교 도서관까지, 모든 사업이 지역에 오래 남는 흔적을 남깁니다. 마을의 작은 기념비가 그것을 기억합니다.")
add("holding.fdn.chipMonument", "A monument in the town", "Kasabada bir anıt", "Ein Denkmal in der Stadt", "Un monumento en el pueblo", "町に記念碑", "마을에 기념비")
# v142: priced per region (each region's next project counts only the projects funded there)
add("holding.fdn.chipStep", "Per region: each project %@ more", "Bölgedeki her proje %@ daha pahalı", "Pro Region: jedes Projekt %@ teurer",
    "Por región: cada proyecto %@ más", "地域ごとに事業のたびに%@ずつ値上がり", "지역별로 사업마다 %@씩 인상")
add("holding.fdn.next", "Next: %@", "Sıradaki: %@", "Als Nächstes: %@", "Siguiente: %@", "次：%@", "다음: %@")
add("holding.fdn.here", "Projects here: %@", "Buradaki proje: %@", "Projekte hier: %@", "Proyectos aquí: %@", "ここでの事業：%@件", "이곳의 사업: %@건")
add("holding.fdn.cta", "Fund the project", "Projeyi fonla", "Projekt finanzieren", "Financiar el proyecto", "事業に出資する", "사업 후원하기")
add("hez.foundationProject",
    "The foundation's new project: %@. Money comes and goes, kid, but people remember this for years. Every region you own speaks your name kindly.",
    "Vakfın yeni projesi: %@. Para gelir gider evlat, ama bunu insanlar yıllarca hatırlar. Bütün bölgelerinde adını sevgiyle anıyorlar.",
    "Das neue Projekt der Stiftung: %@. Geld kommt und geht, Lehrling, aber daran erinnern sich die Leute jahrelang. In all deinen Regionen spricht man voller Wärme von dir.",
    "El nuevo proyecto de la fundación: %@. El dinero va y viene, aprendiz, pero esto la gente lo recuerda durante años. En todas tus regiones hablan bien de ti.",
    "財団の新しい事業だ：%@。金は入っては出ていくものだが、弟子よ、これは人々が何年も覚えている。お前のどの地域でも、皆がお前の名を温かく口にしている。",
    "재단의 새 사업일세: %@. 돈은 들어왔다 나가는 것이지만, 제자여, 이건 사람들이 몇 년이고 기억한다네. 자네의 모든 지역에서 자네 이름을 따뜻하게 부르고 있어.")
add("paper.foundationProject", "Hot Air Foundation: %@", "Sıcak Hava Vakfı: %@", "Heißluft-Stiftung: %@", "Fundación Aire Caliente: %@",
    "ホットエア財団：%@", "핫에어 재단: %@")
add("paper.foundationProject.sub", "The foundation's project no. %1$@, for %2$@.", "Vakfın %1$@. projesi; bölge: %2$@.",
    "Projekt Nr. %1$@ der Stiftung, für %2$@.", "Proyecto n.º %1$@ de la fundación, para %2$@.",
    "財団の%1$@件目の事業、%2$@にて。", "재단의 %1$@번째 사업, 지역: %2$@.")
add("ach.patron", "Patron of the skies", "Gökyüzünün hayırseveri", "Gönner der Lüfte", "Mecenas de los cielos", "空の篤志家", "하늘의 후원자")
add("ach.patron.d", "The foundation's first project", "Vakfın ilk projesi", "Das erste Projekt der Stiftung",
    "El primer proyecto de la fundación", "財団の最初の事業", "재단의 첫 사업")

# Each region's foundation projects (the list goes round): fdn.<region>.<0-4>
P = {
    "cap": [
        ("Restoring a rock-cut church's frescoes in Göreme", "Göreme'de kaya kilisesi fresklerinin restorasyonu", "Restaurierung der Fresken einer Felsenkirche in Göreme",
         "Restauración de los frescos de una iglesia rupestre en Göreme", "ギョレメの岩窟教会フレスコ画の修復", "괴레메 암굴 교회 프레스코화 복원"),
        ("Scholarships for young potters in Avanos", "Avanos'ta genç çömlekçilere burs", "Stipendien für junge Töpfer in Avanos",
         "Becas para jóvenes alfareros de Avanos", "アヴァノスの若い陶芸家への奨学金", "아바노스 젊은 도공들을 위한 장학금"),
        ("New footpaths for the Ihlara Valley", "Ihlara Vadisi'ne yeni yürüyüş yolları", "Neue Wanderwege im Ihlara-Tal",
         "Nuevos senderos en el valle de Ihlara", "イフララ渓谷の新しい遊歩道", "으흘라라 계곡의 새 산책로"),
        ("A children's library in Ürgüp", "Ürgüp'te bir çocuk kütüphanesi", "Eine Kinderbibliothek in Ürgüp",
         "Una biblioteca infantil en Ürgüp", "ユルギュップの子ども図書館", "위르귑의 어린이 도서관"),
        ("A photography school for the valley's young", "Vadinin gençleri için fotoğraf okulu", "Eine Fotoschule für die Jugend des Tals",
         "Una escuela de fotografía para los jóvenes del valle", "谷の若者のための写真学校", "계곡 청년들을 위한 사진 학교"),
    ],
    "abq": [
        ("A balloon pilot programme for young people", "Gençlere balon pilotluğu programı", "Ein Ballonpiloten-Programm für Jugendliche",
         "Un programa de pilotos de globo para jóvenes", "若者のための気球パイロット養成プログラム", "청소년 열기구 조종사 프로그램"),
        ("Cottonwoods replanted along the Rio Grande", "Rio Grande kıyısına yeni kavaklar", "Neue Pappeln am Ufer des Rio Grande",
         "Nuevos álamos a orillas del Río Grande", "リオ・グランデ河畔のハコヤナギ植樹", "리오그란데 강가의 미루나무 심기"),
        ("Weather stations for the city's schools", "Şehrin okullarına hava istasyonları", "Wetterstationen für die Schulen der Stadt",
         "Estaciones meteorológicas para las escuelas de la ciudad", "市内の学校に気象観測所", "시내 학교들에 기상 관측소"),
        ("A community music school in Old Town", "Old Town'da bir mahalle müzik okulu", "Eine Musikschule für alle in der Old Town",
         "Una escuela de música comunitaria en Old Town", "オールドタウンの地域音楽学校", "올드타운의 지역 음악 학교"),
        ("A mobile library for desert roads", "Çöl yollarında gezici kütüphane", "Eine Fahrbücherei für die Wüstenstraßen",
         "Una biblioteca móvil para los caminos del desierto", "砂漠の道を走る移動図書館", "사막 길을 달리는 이동 도서관"),
    ],
    "lux": [
        ("A school on the Nile's west bank", "Nil'in batı yakasında bir okul", "Eine Schule am Westufer des Nils",
         "Una escuela en la orilla oeste del Nilo", "ナイル西岸の学校", "나일강 서안의 학교"),
        ("A workshop restoring Theban tomb paintings", "Teb mezar resimleri için restorasyon atölyesi", "Eine Werkstatt für die Malereien thebanischer Gräber",
         "Un taller para restaurar las pinturas de las tumbas tebanas", "テーベの墓壁画の修復工房", "테베 무덤 벽화 복원 공방"),
        ("A clinic boat for the river villages", "Nehir köylerine gezici sağlık teknesi", "Ein Arztboot für die Dörfer am Fluss",
         "Un barco clínica para las aldeas del río", "川沿いの村を回る診療船", "강변 마을을 도는 진료선"),
        ("Apprenticeships with the felucca builders", "Feluka ustalarının yanında çıraklık", "Lehrstellen bei den Feluken-Bootsbauern",
         "Aprendices con los constructores de falúas", "ファルーカ職人のもとでの見習い制度", "펠루카 장인들의 도제 과정"),
        ("New saplings for the date groves", "Hurma bahçelerine yeni fidanlar", "Neue Setzlinge für die Dattelhaine",
         "Nuevos plantones para los palmerales", "ナツメヤシ林に新しい苗木", "대추야자 숲에 새 묘목"),
    ],
    "bri": [
        ("A community balloon for Bristol", "Bristol halkının balonu", "Ein Gemeinschaftsballon für Bristol",
         "Un globo comunitario para Bristol", "ブリストル市民の気球", "브리스톨 시민의 열기구"),
        ("A youth sailing club in the harbour", "Limanda gençler için yelken kulübü", "Ein Segelclub für Jugendliche im Hafen",
         "Un club de vela juvenil en el puerto", "港の若者向けセーリングクラブ", "항구의 청소년 요트 클럽"),
        ("A wildflower meadow along the Avon", "Avon kıyısında kır çiçeği çayırı", "Eine Wildblumenwiese am Avon",
         "Un prado de flores silvestres junto al Avon", "エイボン川沿いの野の花の草原", "에이번강 변의 야생화 초원"),
        ("A reading room in a Georgian townhouse", "18. yüzyıldan kalma bir konakta okuma salonu", "Ein Lesesaal in einem georgianischen Stadthaus",
         "Una sala de lectura en una casa georgiana", "ジョージ王朝様式の邸宅の閲覧室", "조지 왕조풍 타운하우스의 열람실"),
        ("Balloon science workshops for schools", "Okullara balon bilimi atölyeleri", "Ballon-Wissenschaftswerkstätten für Schulen",
         "Talleres de ciencia del globo para escuelas", "学校向けの気球サイエンス教室", "학교를 위한 열기구 과학 교실"),
    ],
}
for r, names in P.items():
    for i, n in enumerate(names):
        add(f"fdn.{r}.{i}", *n)
