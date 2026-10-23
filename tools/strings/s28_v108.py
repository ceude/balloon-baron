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
