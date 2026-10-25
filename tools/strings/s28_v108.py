from s1_ui import add

# A parked region's problem waits for you when you fly there (prototype v108)
add("issueSheet.here", "%@ · you're here", "%@ · buradasın", "%@ · du bist hier", "%@ · estás aquí", "%@・現地にいる", "%@ · 현재 위치")
add("issueSheet.yourCall", "You're here, so it's your call.", "Buradasın, karar senin.", "Du bist vor Ort, du entscheidest.", "Estás aquí, tú decides.",
    "君は現地にいる。決めるのは君だ。", "자네가 여기 있으니 결정은 자네 몫이네.")
add("home.alert.issueHere", "Tap to decide.", "Karar vermek için dokun.", "Tippen, um zu entscheiden.", "Toca para decidir.", "タップして決める。", "탭해서 결정하세요.")
add("home.alert.issueHere.raise", "Your pilots are waiting outside the office. Tap to decide.", "Pilotların ofisin önünde bekliyor. Karar vermek için dokun.",
    "Deine Piloten warten vor dem Büro. Tippen, um zu entscheiden.", "Tus pilotos esperan frente a la oficina. Toca para decidir.",
    "パイロットたちがオフィスの前で待っている。タップして決める。", "조종사들이 사무실 앞에서 기다립니다. 탭해서 결정하세요.")
add("issue.raise.a.live", "Pilot wages go up 15%.", "Pilot maaşları %15 artar.", "Die Pilotengehälter steigen um 15 %.", "Los sueldos de los pilotos suben un 15 %.",
    "パイロットの給料が15%上がる。", "조종사 급여가 15% 오릅니다.")
add("issue.raise.b.live", "Your pilots stay off for three days; only you fly, in the flagship.", "Pilotlar üç gün uçmaz, sadece amiral balonunu sen uçurursun.",
    "Deine Piloten bleiben drei Tage weg, nur du fliegst, im Flaggschiff.", "Tus pilotos no vuelan durante tres días; solo vuelas tú, en el buque insignia.",
    "パイロットは3日間飛ばない。飛ぶのは旗艦の君だけ。", "조종사들이 사흘간 비행하지 않고, 기함은 당신만 띄웁니다.")
add("issue.war.a.live", "Your ticket price drops to your cheapest rival's.", "Bilet fiyatın en ucuz rakibinkine iner.",
    "Dein Ticketpreis sinkt auf den des günstigsten Konkurrenten.", "El precio de tu billete baja al de tu rival más barato.",
    "チケット価格が最も安いライバルと同じになる。", "티켓 가격이 가장 싼 경쟁사 수준으로 내려갑니다.")
add("issue.war.b.live", "Fifty-fifty: nothing happens, or your popularity drops.", "Yarı yarıya: ya bir şey olmaz ya da popülerliğin düşer.",
    "Fifty-fifty: Entweder passiert nichts, oder deine Beliebtheit sinkt.", "Mitad y mitad: o no pasa nada o baja tu popularidad.",
    "五分五分：何も起きないか、人気が下がるか。", "반반입니다: 아무 일도 없거나 인기가 떨어집니다.")
add("issue.accident.a.live", "Popularity drops a little, but the story is over.", "Popülerlik biraz düşer ama hikâye kapanır.",
    "Die Beliebtheit sinkt etwas, aber die Geschichte ist vorbei.", "La popularidad baja un poco, pero la historia se cierra.",
    "人気は少し下がるが、話はそこで終わる。", "인기가 조금 떨어지지만 이야기는 끝납니다.")
add("issue.accident.b.live", "The press keeps at it; popularity drops more.", "Basın üstüne gider, popülerlik daha çok düşer.",
    "Die Presse bleibt dran, die Beliebtheit sinkt stärker.", "La prensa insiste y la popularidad baja más.",
    "マスコミが追及を続け、人気がさらに下がる。", "언론이 계속 파고들어 인기가 더 떨어집니다.")
add("issue.hotel.b.live", "One of your partner hotels goes to the rival.", "Anlaşmalı otellerinden biri rakibe geçer.",
    "Eines deiner Partnerhotels wechselt zur Konkurrenz.", "Uno de tus hoteles asociados se va con el rival.",
    "提携ホテルの一つがライバルに移る。", "제휴 호텔 하나가 경쟁사로 넘어갑니다.")
add("issue.envelope.a.live", "Paid from the holding; envelopes below 30% are renewed.", "Holding kasasından ödenir, %30 altındaki zarfların yenilenir.",
    "Aus der Holding bezahlt; Hüllen unter 30 % werden erneuert.", "Lo paga el holding; se renuevan las envolturas por debajo del 30 %.",
    "ホールディングスが支払い、30%未満の球皮が交換される。", "지주회사가 내고, 30% 미만인 외피가 교체됩니다.")
add("issue.envelope.b.live", "The worn envelopes keep flying.", "Yıpranmış zarflar uçmaya devam eder.", "Die abgenutzten Hüllen fliegen weiter.",
    "Las envolturas gastadas siguen volando.", "劣化した球皮のまま飛び続ける。", "마모된 외피로 계속 비행합니다.")

# The make-up of a rival's fleet on take-over and bankrupt-sale offers
add("deal.fleetRow", "%1$@ · seats: %2$@", "%1$@ · koltuk: %2$@", "%1$@ · Plätze: %2$@", "%1$@ · plazas: %2$@", "%1$@・座席：%2$@", "%1$@ · 좌석: %2$@")

# Reviews that name a place get their own lines in Albuquerque and Luxor: review.<kind>.<variant>.<region>
RR = {
 "abq": {
  "perfect.1": ("Sunrise over the Sandia Mountains and a flawless landing. The morning of my life.", "Sandia Dağları'nda gün doğumu ve kusursuz bir iniş. Hayatımın sabahıydı.",
                "Sonnenaufgang über den Sandia Mountains und eine makellose Landung. Der Morgen meines Lebens.", "Amanecer sobre las montañas Sandia y un aterrizaje perfecto. La mañana de mi vida.",
                "サンディア山脈の日の出と完璧な着陸。人生最高の朝。", "샌디아 산맥 위의 일출과 완벽한 착륙. 인생 최고의 아침이었어요."),
  "crash.0": ("We hit a cottonwood! Everyone's okay, but this is unacceptable.", "Kavak ağacına çarptık! Herkes iyi ama bu kabul edilemez.",
              "Wir sind in eine Pappel gekracht! Allen geht's gut, aber das ist inakzeptabel.", "¡Chocamos con un álamo! Todos están bien, pero esto es inaceptable.",
              "ハコヤナギに激突！全員無事だけど、ありえない。", "미루나무에 부딪혔어요! 다들 괜찮지만 이건 용납할 수 없어요."),
  "cheap.1": ("I paid {p}. Maybe the best price in Albuquerque.", "{p} ödedim, Albuquerque'nin en iyi fiyatı bu olabilir.",
              "Ich habe {p} bezahlt. Vielleicht der beste Preis in Albuquerque.", "Pagué {p}. Quizás el mejor precio de Albuquerque.",
              "{p}払った。アルバカーキでいちばん安いかも。", "{p} 냈어요. 앨버커키 최저가일지도."),
  "general.0": ("You can't come to Albuquerque and skip the balloon. This team is very professional.", "Albuquerque'ye gelip balona binmemek olmaz. Bu ekip çok profesyonel.",
                "Man kann nicht nach Albuquerque kommen und keinen Ballon fahren. Sehr professionelles Team.", "No puedes venir a Albuquerque y no subir en globo. Este equipo es muy profesional.",
                "アルバカーキに来て気球に乗らないなんてありえない。とてもプロのチーム。", "앨버커키에 와서 열기구를 안 탈 순 없죠. 정말 프로페셔널한 팀이에요."),
  "panorama.0": ("Our photographer loved the shot from 550 meters. The whole Rio Grande valley was at our feet.", "Fotoğrafçımız 550 metreden çektiği kareye bayıldı. Bütün Rio Grande vadisi ayaklarımızın altındaydı.",
                 "Unser Fotograf liebte das Bild aus 550 Metern. Das ganze Rio-Grande-Tal lag uns zu Füßen.", "A nuestro fotógrafo le encantó la foto desde 550 metros. Todo el valle del Río Grande a nuestros pies.",
                 "カメラマンは550メートルからの一枚に大満足。リオグランデの谷がまるごと足元に。", "사진작가가 550미터에서 찍은 사진을 정말 좋아했어요. 리오그란데 계곡 전체가 발아래 있었죠."),
  "valley.0": ("We skimmed the Rio Grande; it felt like we could touch the water!", "Rio Grande'nin üstünden süzüldük, suya dokunacak gibiydik!",
               "Wir glitten über den Rio Grande, als könnten wir das Wasser berühren!", "¡Rozamos el Río Grande, parecía que podíamos tocar el agua!",
               "リオグランデの水面すれすれを飛んだ。水に触れそうだった！", "리오그란데 위를 스치듯 날았어요, 물에 손이 닿을 것 같았죠!"),
  "valley.1": ("The low flight over the river was incredible; herons took off right beside us.", "Nehrin üstünde alçak uçuş inanılmazdı, balıkçıllar hemen yanımızdan havalandı.",
               "Der Tiefflug über den Fluss war unglaublich, Reiher flogen direkt neben uns auf.", "El vuelo bajo sobre el río fue increíble; las garzas despegaban a nuestro lado.",
               "川の上の低空飛行は最高。すぐ横からサギが飛び立った。", "강 위 저공비행은 정말 대단했어요. 바로 옆에서 왜가리가 날아올랐죠."),
  "xl.2": ("We saw the Fiesta Star from afar and booked. No regrets.", "Fiesta Yıldızı'nı uzaktan görüp rezervasyon yaptık, pişman değiliz.",
           "Wir sahen den Fiesta-Stern von Weitem und buchten. Keine Reue.", "Vimos la Estrella de la Fiesta de lejos y reservamos. Sin arrepentimientos.",
           "遠くからフィエスタ・スターを見て予約した。後悔なし。", "멀리서 피에스타 스타를 보고 예약했어요. 후회 없어요."),
 },
 "lux": {
  "perfect.1": ("Sunrise over the Valley of the Kings and a flawless landing. The morning of my life.", "Krallar Vadisi'nde gün doğumu ve kusursuz bir iniş. Hayatımın sabahıydı.",
                "Sonnenaufgang über dem Tal der Könige und eine makellose Landung. Der Morgen meines Lebens.", "Amanecer sobre el Valle de los Reyes y un aterrizaje perfecto. La mañana de mi vida.",
                "王家の谷の日の出と完璧な着陸。人生最高の朝。", "왕가의 계곡 위 일출과 완벽한 착륙. 인생 최고의 아침이었어요."),
  "crash.0": ("We hit the date palms! Everyone's okay, but this is unacceptable.", "Hurma ağaçlarına çarptık! Herkes iyi ama bu kabul edilemez.",
              "Wir sind in die Dattelpalmen gekracht! Allen geht's gut, aber das ist inakzeptabel.", "¡Chocamos con las palmeras! Todos están bien, pero esto es inaceptable.",
              "ナツメヤシに激突！全員無事だけど、ありえない。", "대추야자나무에 부딪혔어요! 다들 괜찮지만 이건 용납할 수 없어요."),
  "cheap.1": ("I paid {p}. Maybe the best price in Luxor.", "{p} ödedim, Luksor'un en iyi fiyatı bu olabilir.",
              "Ich habe {p} bezahlt. Vielleicht der beste Preis in Luxor.", "Pagué {p}. Quizás el mejor precio de Luxor.",
              "{p}払った。ルクソールでいちばん安いかも。", "{p} 냈어요. 룩소르 최저가일지도."),
  "general.0": ("You can't come to Luxor and skip the balloon. This team is very professional.", "Luksor'a gelip balona binmemek olmaz. Bu ekip çok profesyonel.",
                "Man kann nicht nach Luxor kommen und keinen Ballon fahren. Sehr professionelles Team.", "No puedes venir a Luxor y no subir en globo. Este equipo es muy profesional.",
                "ルクソールに来て気球に乗らないなんてありえない。とてもプロのチーム。", "룩소르에 와서 열기구를 안 탈 순 없죠. 정말 프로페셔널한 팀이에요."),
  "panorama.0": ("Our photographer loved the shot from 550 meters. The temples and the Nile were at our feet.", "Fotoğrafçımız 550 metreden çektiği kareye bayıldı. Tapınaklar ve Nil ayaklarımızın altındaydı.",
                 "Unser Fotograf liebte das Bild aus 550 Metern. Die Tempel und der Nil lagen uns zu Füßen.", "A nuestro fotógrafo le encantó la foto desde 550 metros. Los templos y el Nilo a nuestros pies.",
                 "カメラマンは550メートルからの一枚に大満足。神殿とナイルが足元に。", "사진작가가 550미터에서 찍은 사진을 정말 좋아했어요. 신전과 나일강이 발아래 있었죠."),
  "valley.0": ("We skimmed the Nile; it felt like we could touch the feluccas' sails!", "Nil'in üstünden süzüldük, feluka yelkenlerine dokunacak gibiydik!",
               "Wir glitten über den Nil, als könnten wir die Segel der Feluken berühren!", "¡Rozamos el Nilo, parecía que podíamos tocar las velas de las falúas!",
               "ナイルの水面すれすれを飛んだ。ファルーカの帆に触れそうだった！", "나일강 위를 스치듯 날았어요, 펠루카 돛에 손이 닿을 것 같았죠!"),
  "valley.1": ("The low flight over the Nile was incredible; the fishermen waved at us.", "Nil'in üstünde alçak uçuş inanılmazdı, balıkçılar bize el salladı.",
               "Der Tiefflug über den Nil war unglaublich, die Fischer winkten uns zu.", "El vuelo bajo sobre el Nilo fue increíble; los pescadores nos saludaban.",
               "ナイルの上の低空飛行は最高。漁師たちが手を振ってくれた。", "나일강 위 저공비행은 정말 대단했어요. 어부들이 손을 흔들어 줬죠."),
  "xl.2": ("We saw the Theban Star from afar and booked. No regrets.", "Teb Yıldızı'nı uzaktan görüp rezervasyon yaptık, pişman değiliz.",
           "Wir sahen den Theben-Stern von Weitem und buchten. Keine Reue.", "Vimos la Estrella de Tebas de lejos y reservamos. Sin arrepentimientos.",
           "遠くからテーベ・スターを見て予約した。後悔なし。", "멀리서 테베 스타를 보고 예약했어요. 후회 없어요."),
 },
}
for r, items in RR.items():
    for k, t in items.items():
        add(f"review.{k}.{r}", *t)

# Shaped-balloon deals: how the price adds up, and breaking a deal
add("holding.shape.terms", "%1$@ a day × %2$@ days", "%1$@ × %2$@ gün", "%1$@ pro Tag × %2$@ Tage", "%1$@ al día × %2$@ días", "1日%1$@ × %2$@日", "하루 %1$@ × %2$@일")
add("holding.shape.break", "Break the deal · penalty %@", "Sözleşmeyi boz · ceza %@", "Vertrag brechen · Strafe %@", "Romper el contrato · multa %@",
    "契約を破棄・違約金 %@", "계약 파기 · 위약금 %@")
add("holding.shape.breakNote", "The penalty is what the brand has paid you so far plus half of the time left. Breaking always costs you.",
    "Ceza: şimdiye kadar aldığın para ve kalan sürenin yarısı. Bozmak hep zarar ettirir.",
    "Die Strafe ist alles, was die Marke bisher gezahlt hat, plus die Hälfte der Restlaufzeit. Ein Vertragsbruch kostet dich immer.",
    "La multa es lo que la marca te ha pagado hasta ahora más la mitad del tiempo restante. Romper siempre te cuesta.",
    "違約金は、これまでブランドから受け取った額と残り期間の半分。破棄すれば必ず損をする。",
    "위약금은 지금까지 브랜드에게 받은 돈과 남은 기간의 절반입니다. 파기하면 언제나 손해입니다.")
add("holding.shape.breakYes", "Break it", "Boz", "Brechen", "Romper", "破棄する", "파기")
add("holding.shape.breakNo", "Keep the deal", "Sözleşme sürsün", "Vertrag behalten", "Mantener el contrato", "契約を続ける", "계약 유지")

# The chapter's number as a big heading
add("goals.chapterBig", "Chapter %1$@/%2$@", "Bölüm %1$@/%2$@", "Kapitel %1$@/%2$@", "Capítulo %1$@/%2$@", "第%1$@章 / %2$@", "챕터 %1$@/%2$@")

# The guides' short names, for buttons
add("guide.short.cap", "Hezarfen", "Hezarfen", "Hezarfen", "Hezarfen", "ヘザルフェン", "헤자르펜")
add("guide.short.abq", "Franklin", "Franklin", "Franklin", "Franklin", "フランクリン", "프랭클린")
add("guide.short.lux", "Imhotep", "İmhotep", "Imhotep", "Imhotep", "イムホテプ", "임호테프")

# A parked region's problem card: no "later", but you can fly over and see it
add("issueSheet.goThere", "Go to %@", "%@ bölgesine git", "Nach %@ reisen", "Ir a %@", "%@へ行く", "%@(으)로 가기")

# Holding goal: Luxor's baron (was Albuquerque's)
add("hgoal.baronLux", "Baron of Luxor", "Luksor Baronu", "Baron von Luxor", "Barón de Luxor", "ルクソールの男爵", "룩소르의 남작")

# Compact crew page (prototype v109)
add("crew.sum.pilots", "pilots", "pilot", "Piloten", "pilotos", "パイロット", "조종사")
add("crew.sum.wages", "wages/day", "maaş/gün", "Gehalt/Tag", "sueldos/día", "給料/日", "급여/일")
add("crew.sum.idle", "idle", "boşta", "untätig", "sin trabajo", "待機中", "대기 중")
add("crew.sum.senior", "senior", "kıdemli", "erfahren", "veteranos", "ベテラン", "베테랑")
add("crew.f.all", "All", "Hepsi", "Alle", "Todos", "すべて", "전체")
add("crew.f.idle", "Idle", "Boşta", "Untätig", "Sin trabajo", "待機中", "대기 중")
add("crew.f.school", "School graduates", "Okul mezunu", "Schulabsolventen", "Graduados", "養成校出身", "학교 출신")
add("crew.fireIdle", "Let the idle ones go (%@)", "Boştakileri kov (%@)", "Untätige entlassen (%@)", "Despedir a los inactivos (%@)", "待機中を解雇（%@）", "대기 조종사 해고 (%@)")
add("crew.row.repair", "%@ · in repair", "%@ · onarımda", "%@ · in Reparatur", "%@ · en reparación", "%@・修理中", "%@ · 수리 중")
add("crew.row.worn", "%@ · envelope worn out", "%@ · zarf bitti", "%@ · Hülle verschlissen", "%@ · envoltura agotada", "%@・球皮が寿命", "%@ · 외피 수명 다함")
add("crew.empty", "No pilots in this filter.", "Bu filtrede pilot yok.", "Keine Piloten in diesem Filter.", "No hay pilotos con este filtro.", "この条件のパイロットはいません。", "이 필터에 해당하는 조종사가 없습니다.")
add("crew.ringHint", "The ring shows experience up to the next level.", "Halka, bir sonraki seviyeye kadar tecrübeyi gösterir.", "Der Ring zeigt die Erfahrung bis zur nächsten Stufe.", "El anillo muestra la experiencia hasta el siguiente nivel.", "リングは次のレベルまでの経験を示す。", "고리는 다음 레벨까지의 경험치를 보여줍니다.")
add("crew.row.a11y", "%1$@, %2$@, %3$@", "%1$@, %2$@, %3$@", "%1$@, %2$@, %3$@", "%1$@, %2$@, %3$@", "%1$@、%2$@、%3$@", "%1$@, %2$@, %3$@")

# Holding investments: the region's guide praises them, the next paper reports them (v109)
D = {
 "tv": (
  "Your TV ad is on the air, kid! People all over the world are talking about your balloons. You'll see this investment in the till.",
  "TV reklamın yayında evlat! Dünyanın dört bir yanında insanlar balonlarını konuşuyor. Bu yatırımın karşılığını kasada göreceksin.",
  "Dein TV-Spot läuft, Lehrling! Überall auf der Welt reden die Leute über deine Ballone. Diese Investition wirst du in der Kasse sehen.",
  "¡Tu anuncio ya está en la tele, aprendiz! En todo el mundo se habla de tus globos. Verás esta inversión en la caja.",
  "テレビCMが流れ始めたぞ、弟子よ！世界中で君の気球が話題だ。この投資の見返りは金庫に表れる。",
  "TV 광고가 방송을 탔네, 제자여! 전 세계 사람들이 자네 열기구 이야기를 하고 있어. 이 투자의 보답은 금고에서 보게 될 걸세."),
 "billboards": (
  "Billboards all over town, kid! Every tourist who walks past them will remember your name tomorrow morning.",
  "Bütün şehirde ilan panoların asıldı evlat! Önünden geçen her turist yarın sabah adını hatırlayacak.",
  "Plakate in der ganzen Stadt, Lehrling! Jeder Tourist, der daran vorbeigeht, erinnert sich morgen früh an deinen Namen.",
  "¡Vallas por toda la ciudad, aprendiz! Cada turista que pase por delante recordará tu nombre mañana por la mañana.",
  "街じゅうに看板が立ったぞ、弟子よ！前を通る観光客はみな、明日の朝君の名を思い出す。",
  "온 도시에 광고판이 걸렸네, 제자여! 그 앞을 지나는 관광객은 모두 내일 아침 자네 이름을 기억할 걸세."),
 "research": (
  "Good news from the lab, kid: the new envelope fabric lasts longer. Fewer renewals, more flights. That's how a real company grows.",
  "Laboratuvardan iyi haber evlat: yeni zarf kumaşı daha uzun dayanıyor. Daha az yenileme, daha çok uçuş. Gerçek şirket böyle büyür.",
  "Gute Nachrichten aus dem Labor, Lehrling: Der neue Hüllenstoff hält länger. Weniger Erneuerungen, mehr Flüge. So wächst eine echte Firma.",
  "Buenas noticias del laboratorio, aprendiz: la nueva tela dura más. Menos renovaciones, más vuelos. Así crece una empresa de verdad.",
  "研究所から朗報だ、弟子よ。新しい球皮の生地は長持ちする。交換が減り、飛行が増える。本物の会社はこうして育つ。",
  "연구소에서 좋은 소식이네, 제자여. 새 외피 원단이 더 오래 간다네. 교체는 줄고 비행은 늘지. 진짜 회사는 이렇게 크는 걸세."),
 "record": (
  "A world record attempt! The whole world will be watching your balloon, kid. Whatever happens, your name will be in every paper.",
  "Dünya rekoru denemesi! Bütün dünya senin balonunu izleyecek evlat. Ne olursa olsun adın her gazetede olacak.",
  "Ein Weltrekordversuch! Die ganze Welt wird deinen Ballon beobachten, Lehrling. Was auch passiert, dein Name steht in jeder Zeitung.",
  "¡Un intento de récord mundial! El mundo entero mirará tu globo, aprendiz. Pase lo que pase, tu nombre saldrá en todos los periódicos.",
  "世界記録への挑戦だ！世界中が君の気球を見守るぞ、弟子よ。どうなろうと、君の名はあらゆる新聞に載る。",
  "세계 기록 도전이라니! 온 세상이 자네 열기구를 지켜볼 걸세, 제자여. 무슨 일이 있어도 자네 이름은 모든 신문에 실릴 거야."),
 "shape": (
  "A brand wants its own giant balloon in your sky, kid! Tourists will grumble a little, but the holding gets paid every single day.",
  "Bir marka kendi dev balonunu senin göğünde uçurmak istiyor evlat! Turistler biraz söylenir ama holding her gün parasını alır.",
  "Eine Marke will ihren eigenen Riesenballon an deinem Himmel, Lehrling! Die Touristen murren ein wenig, aber die Holding wird jeden Tag bezahlt.",
  "¡Una marca quiere su propio globo gigante en tu cielo, aprendiz! Los turistas refunfuñarán un poco, pero el holding cobra cada día.",
  "あるブランドが君の空に自社の巨大気球を飛ばしたいそうだ、弟子よ！観光客は少しぼやくが、ホールディングスには毎日お金が入る。",
  "한 브랜드가 자네 하늘에 자기 거대 열기구를 띄우고 싶어 하네, 제자여! 관광객은 조금 투덜대겠지만 지주회사는 매일 돈을 받지."),
}
for k, t in D.items():
    add(f"hez.deed.{k}", *t)
P = {
 "tv": (("%@ ad on every TV", "Her televizyonda reklamı var: %@", "%@-Werbung auf jedem Fernseher", "El anuncio de %@ en todas las teles", "%@のCM、どのテレビにも", "모든 TV에 %@ 광고"),
        ("The holding's TV campaign brings tourists to every region.", "Holdingin TV kampanyası bütün bölgelere turist getiriyor.", "Die TV-Kampagne der Holding bringt Touristen in jede Region.", "La campaña de TV del holding atrae turistas a todas las regiones.", "ホールディングスのテレビキャンペーンで、どの地域にも観光客が来る。", "지주회사의 TV 캠페인이 모든 지역에 관광객을 부른다.")),
 "billboards": (("Billboards everywhere: %@", "Her köşede ilan panosu: %@", "Plakate an jeder Ecke: %@", "Vallas en cada esquina: %@", "街の至る所に看板：%@", "곳곳에 광고판: %@"),
        ("Tourists can't miss the name on their way to the hotel.", "Turistler otele giderken bu adı görmeden geçemiyor.", "Auf dem Weg zum Hotel kommen Touristen an dem Namen nicht vorbei.", "Los turistas no pueden pasar por alto el nombre camino del hotel.", "観光客はホテルへ向かう途中、その名を見ずにはいられない。", "관광객은 호텔 가는 길에 그 이름을 지나칠 수 없다.")),
 "celebrity": (("A famous face for %@", "Ünlü bir yüz: %@", "Ein berühmtes Gesicht für %@", "Una cara famosa para %@", "%@に有名人の顔", "%@의 새 얼굴은 유명인"),
        ("The posters went up overnight; the phones haven't stopped since.", "Afişler bir gecede asıldı, telefonlar o günden beri susmuyor.", "Die Plakate hingen über Nacht, seitdem klingeln die Telefone ununterbrochen.", "Los carteles aparecieron de la noche a la mañana; los teléfonos no paran desde entonces.", "ポスターは一晩で貼られ、それ以来電話が鳴りやまない。", "포스터가 하룻밤 새 붙었고, 그 뒤로 전화가 끊이지 않는다.")),
 "research": (("New envelope fabric from %@", "Yeni zarf kumaşı: %@", "Neuer Hüllenstoff von %@", "Nueva tela de envoltura de %@", "%@の新しい球皮生地", "%@의 새 외피 원단"),
        ("Tougher envelopes mean fewer renewals and more safe flights.", "Daha dayanıklı zarflar: daha az yenileme, daha çok güvenli uçuş.", "Robustere Hüllen: weniger Erneuerungen, mehr sichere Flüge.", "Envolturas más resistentes: menos renovaciones y más vuelos seguros.", "丈夫な球皮で交換は減り、安全な飛行が増える。", "더 튼튼한 외피로 교체는 줄고 안전한 비행은 늘어난다.")),
 "office": (("%@ opens a new office abroad", "Yurt dışında yeni ofis: %@", "%@ eröffnet ein neues Büro im Ausland", "%@ abre una nueva oficina en el extranjero", "%@、海外に新オフィス", "%@, 해외에 새 사무소"),
        ("Travel agencies there now sell its balloon flights.", "Oradaki seyahat acenteleri artık onun balon uçuşlarını satıyor.", "Reisebüros dort verkaufen jetzt seine Ballonflüge.", "Las agencias de viajes de allí ya venden sus vuelos en globo.", "現地の旅行代理店が、その気球フライトを売り始めた。", "그곳 여행사들이 이제 이 회사의 열기구 비행을 판다.")),
 "record": (("%@ goes for a world record", "Dünya rekoru denemesi: %@", "%@ will einen Weltrekord", "%@ va a por un récord mundial", "%@、世界記録に挑む", "%@, 세계 기록에 도전"),
        ("The whole ballooning world is watching the attempt.", "Bütün balon dünyası denemeyi izliyor.", "Die ganze Ballonwelt verfolgt den Versuch.", "Todo el mundo del globo sigue el intento.", "気球界全体がこの挑戦を見守っている。", "열기구 업계 전체가 이 도전을 지켜보고 있다.")),
 "shape": (("A giant brand balloon in the sky: %@", "Gökyüzünde dev marka balonu: %@", "Ein riesiger Markenballon am Himmel: %@", "Un globo gigante de marca en el cielo: %@", "空に巨大なブランド気球：%@", "하늘에 거대한 브랜드 열기구: %@"),
        ("Children point at it; the brand pays the holding every day.", "Çocuklar parmakla gösteriyor, marka her gün holdinge ödüyor.", "Kinder zeigen darauf, die Marke zahlt der Holding jeden Tag.", "Los niños lo señalan; la marca paga al holding cada día.", "子どもたちが指さし、ブランドは毎日ホールディングスに支払う。", "아이들이 손가락으로 가리키고, 브랜드는 매일 지주회사에 돈을 낸다.")),
}
for k, (head, sub) in P.items():
    add(f"paper.deed.{k}", *head)
    add(f"paper.deed.{k}.sub", *sub)

# Round days (v109)
M = {
 "100": ("A hundred days, kid! Remember that single balloon on the first morning? Look at the sky now.",
         "Yüzüncü günün kutlu olsun evlat! İlk sabahki o tek balonu hatırlıyor musun? Şimdi bir bak gökyüzüne.",
         "Hundert Tage, Lehrling! Weißt du noch, der eine Ballon am ersten Morgen? Schau dir jetzt den Himmel an.",
         "¡Cien días, aprendiz! ¿Recuerdas aquel único globo la primera mañana? Mira ahora el cielo.",
         "100日目おめでとう、弟子よ！最初の朝のたった一機の気球を覚えているか？今の空を見てみろ。",
         "100일째를 축하하네, 제자여! 첫날 아침 그 열기구 한 대를 기억하나? 이제 하늘을 보게."),
 "200": ("Two hundred days! Everyone can see now that you run this on hard work, not luck, kid.",
         "İki yüz gün! Bu işi şansla değil emekle yürüttüğünü artık herkes görüyor evlat.",
         "Zweihundert Tage! Jetzt sieht jeder, dass du das mit harter Arbeit schaffst, nicht mit Glück, Lehrling.",
         "¡Doscientos días! Ya todos ven que esto lo sacas adelante con esfuerzo, no con suerte, aprendiz.",
         "200日だ！君が運ではなく努力でやっていることを、今では誰もが知っている。",
         "200일이라니! 이제 모두가 자네가 운이 아니라 노력으로 해낸다는 걸 안다네, 제자여."),
 "300": ("Day three hundred, kid! You've learned to read the wind; now it's time to read the world.",
         "Üç yüzüncü gün evlat! Rüzgârı okumayı öğrendin, şimdi sıra dünyayı okumakta.",
         "Tag dreihundert, Lehrling! Du hast gelernt, den Wind zu lesen; jetzt ist die Welt dran.",
         "¡Día trescientos, aprendiz! Has aprendido a leer el viento; ahora toca leer el mundo.",
         "300日目だ、弟子よ！風を読むことは覚えた。次は世界を読む番だ。",
         "300일째일세, 제자여! 바람 읽는 법을 배웠으니, 이제 세상을 읽을 차례야."),
 "365": ("A whole year, kid! A year ago today you lit your first burner. Happy birthday: your company is one year old!",
         "Tam bir yıl oldu evlat! Bir yıl önce bugün ilk brülörünü yaktın. Doğum günün kutlu olsun, şirketin bir yaşında!",
         "Ein ganzes Jahr, Lehrling! Heute vor einem Jahr hast du deinen ersten Brenner gezündet. Alles Gute: Deine Firma wird ein Jahr alt!",
         "¡Un año entero, aprendiz! Hoy hace un año encendiste tu primer quemador. ¡Feliz cumpleaños: tu empresa cumple un año!",
         "まる一年だ、弟子よ！一年前の今日、君は初めてバーナーに火を入れた。誕生日おめでとう、君の会社は一歳だ！",
         "꼬박 1년일세, 제자여! 1년 전 오늘 자네는 첫 버너에 불을 붙였지. 생일 축하하네, 자네 회사가 한 살이 됐어!"),
 "400": ("Four hundred days! I've seen few companies last as long as you in the sky, kid.",
         "Dört yüz gün! Gökyüzünde senin kadar uzun dayanan az şirket gördüm evlat.",
         "Vierhundert Tage! Ich habe wenige Firmen gesehen, die sich so lange am Himmel halten wie du, Lehrling.",
         "¡Cuatrocientos días! He visto pocas empresas aguantar tanto en el cielo como tú, aprendiz.",
         "400日！君ほど長く空で生き残った会社はそう多くない。",
         "400일이라니! 자네만큼 오래 하늘에서 버틴 회사는 많지 않았네, 제자여."),
 "500": ("Day five hundred! You're a legend now, kid. Young pilots tell your story on their first flight.",
         "Beş yüzüncü gün! Artık bir efsanesin evlat. Genç pilotlar ilk uçuşlarında senin hikâyeni anlatıyor.",
         "Tag fünfhundert! Du bist jetzt eine Legende, Lehrling. Junge Piloten erzählen auf ihrem ersten Flug deine Geschichte.",
         "¡Día quinientos! Ya eres una leyenda, aprendiz. Los pilotos jóvenes cuentan tu historia en su primer vuelo.",
         "500日目！君はもう伝説だ。若いパイロットたちは初飛行で君の物語を語る。",
         "500일째! 자네는 이제 전설일세, 제자여. 젊은 조종사들이 첫 비행에서 자네 이야기를 한다네."),
}
for d, t in M.items():
    add(f"hez.milestone.{d}", *t)
add("hez.milestone.more", "Day: %@! One more milestone, kid. The sky is still yours.", "Gün: %@! Bir kilometre taşı daha evlat. Gökyüzü hâlâ senin.",
    "Tag: %@! Wieder ein Meilenstein, Lehrling. Der Himmel gehört immer noch dir.", "Día: %@. ¡Otro hito, aprendiz! El cielo sigue siendo tuyo.",
    "%@日目！また一つ節目だ。空はまだ君のものだ。", "%@일째! 또 하나의 이정표일세, 제자여. 하늘은 여전히 자네 것이야.")
add("paper.milestone", "Day %2$@ in the sky: %1$@", "Gökyüzünde gün %2$@: %1$@", "Tag %2$@ am Himmel: %1$@", "Día %2$@ en el cielo: %1$@", "空で%2$@日目：%1$@", "하늘에서 %2$@일째: %1$@")
add("paper.milestone.sub", "The company hasn't stopped flying since its first morning.", "Şirket ilk sabahından beri gökyüzünden hiç inmedi.", "Die Firma fliegt ohne Pause seit ihrem ersten Morgen.", "La empresa no ha dejado de volar desde su primera mañana.", "会社は最初の朝から一度も空を離れていない。", "회사는 첫날 아침부터 한 번도 하늘을 떠나지 않았다.")
add("paper.year", "One year old: %@", "Bir yaşında: %@", "Ein Jahr alt: %@", "Un año: %@", "創業1周年：%@", "창업 1주년: %@")
add("paper.year.sub", "The town celebrates the balloon company's first birthday.", "Kasaba, balon şirketinin ilk doğum gününü kutluyor.", "Die Stadt feiert den ersten Geburtstag der Ballonfirma.", "El pueblo celebra el primer cumpleaños de la empresa de globos.", "町は気球会社の1歳の誕生日を祝っている。", "마을이 열기구 회사의 첫 생일을 축하한다.")

# Big loans (v109)
add("bank.needNet", "Opens for good when your typical day here nets at least %1$@ (lately: %2$@).", "Buradaki günlük net kazancın en az %1$@ olunca açılır ve açık kalır (son iki hafta: %2$@).",
    "Öffnet sich dauerhaft, wenn dein typischer Tag hier mindestens %1$@ netto bringt (zuletzt: %2$@).", "Se abre para siempre cuando tu día típico aquí deje al menos %1$@ netos (últimamente: %2$@).",
    "ここでの1日の純利益が%1$@以上になると利用可能になり、その後も使える（最近：%2$@）。", "이곳의 하루 순이익이 %1$@ 이상이 되면 열리고 계속 열려 있습니다 (최근: %2$@).")
add("bank.opened", "Open.", "Açıldı.", "Freigeschaltet.", "Disponible.", "利用可能。", "열림.")
add("bank.needFirst", "The %@ loan has to open first.", "Önce %@ kredisi açılmalı.", "Zuerst muss der Kredit über %@ freigeschaltet sein.", "Primero debe abrirse el préstamo de %@.", "先に%@のローンが利用可能になる必要がある。", "먼저 %@ 대출이 열려야 합니다.")
add("bank.bigTip", "Tip: buying a lot of balloons at once for a full market costs you in winter. Opening a new region or investing in the holding is safer.", "Tavsiye: doymuş pazara toplu balon almak kışın zarar ettirir. Bu parayla yeni bir bölgeye açılmak ya da holdinge yatırım yapmak daha güvenli.",
    "Tipp: Viele Ballone auf einmal für einen vollen Markt kosten dich im Winter Geld. Eine neue Region oder Investitionen in die Holding sind sicherer.", "Consejo: comprar muchos globos de golpe para un mercado lleno te hará perder en invierno. Abrir una nueva región o invertir en el holding es más seguro.",
    "ヒント：飽和した市場に気球をまとめて買うと冬に赤字になる。新しい地域への進出やホールディングスへの投資のほうが安全。", "팁: 포화된 시장에 열기구를 한꺼번에 사면 겨울에 손해를 봅니다. 새 지역 진출이나 지주회사 투자가 더 안전합니다.")
