from s1_ui import add

# Placeholders in braces are filled by the app: {c} company, {b} balloon, {p} price, {s} sponsor, {r} rival.
R = {
 "perfect": [
  ("The pilot set us down in the middle of the field like a feather. Not a drop of champagne spilled!", "Pilot bizi tarlanın tam ortasına kuş tüyü gibi indirdi. Şampanya bile dökülmedi!", "Der Pilot hat uns wie eine Feder mitten aufs Feld gesetzt. Kein Tropfen Champagner verschüttet!", "El piloto nos posó en medio del campo como una pluma. ¡Ni una gota de champán derramada!", "パイロットは野原の真ん中に羽のように降ろしてくれた。シャンパンも一滴もこぼれなかった！", "조종사가 깃털처럼 들판 한가운데 내려 줬어요. 샴페인 한 방울도 안 흘렸어요!"),
  ("Sunrise, fairy chimneys and a flawless landing. The morning of my life.", "Gün doğumu, peribacaları ve kusursuz bir iniş. Hayatımın en güzel sabahıydı.", "Sonnenaufgang, Feenkamine und eine makellose Landung. Der Morgen meines Lebens.", "Amanecer, chimeneas de hadas y un aterrizaje impecable. La mañana de mi vida.", "日の出、妖精の煙突、そして完璧な着陸。人生最高の朝。", "일출, 요정의 굴뚝, 완벽한 착륙. 인생 최고의 아침이었어요."),
  ("The captain literally reads the wind. I'd fly again in a heartbeat.", "Kaptan rüzgârı okuyor resmen. Kesinlikle tekrar uçarım.", "Der Kapitän liest den Wind förmlich. Ich würde sofort wieder fliegen.", "El capitán literalmente lee el viento. Volvería a volar sin dudarlo.", "パイロットはまさに風を読んでいる。絶対にまた乗る。", "기장님이 진짜 바람을 읽어요. 당장이라도 또 탈래요."),
 ],
 "good": [
  ("The view was stunning; the landing was a little bumpy, but no problem.", "Manzara muhteşemdi, iniş biraz sarsıntılıydı ama sorun değil.", "Die Aussicht war atemberaubend, die Landung etwas holprig, aber kein Problem.", "La vista fue impresionante; el aterrizaje, algo movido, pero sin problema.", "景色は最高。着陸は少し揺れたけど問題なし。", "경치가 최고였어요. 착륙이 좀 흔들렸지만 괜찮아요."),
  ("The crew was so attentive, and the hot chocolate after landing was wonderful.", "Ekip çok ilgiliydi, inişten sonraki sıcak çikolata harikaydı.", "Die Crew war sehr aufmerksam, die heiße Schokolade nach der Landung war wunderbar.", "El equipo fue muy atento y el chocolate caliente al aterrizar, maravilloso.", "スタッフがとても親切で、着陸後のホットチョコが最高だった。", "직원들이 정말 세심했고 착륙 후 핫초코가 최고였어요."),
  ("The photos came out incredible; the pilot knew all the best angles.", "Fotoğraflar inanılmaz çıktı, pilot en güzel açıları biliyordu.", "Die Fotos sind unglaublich geworden, der Pilot kannte die besten Winkel.", "Las fotos salieron increíbles; el piloto conocía los mejores ángulos.", "写真が信じられないほど綺麗。パイロットは最高のアングルを知っていた。", "사진이 끝내주게 나왔어요. 조종사가 최고의 각도를 알더라고요."),
 ],
 "far": [
  ("We waited an hour in a field for the van after landing. The view was nice, but…", "İnişten sonra bir tarlada bir saat araç bekledik. Manzara güzeldi ama…", "Nach der Landung warteten wir eine Stunde auf einem Feld auf den Bus. Die Aussicht war schön, aber …", "Tras aterrizar esperamos una hora en un campo a la furgoneta. La vista era bonita, pero…", "着陸後、畑で1時間も車を待った。景色は良かったけど…", "착륙 후 들판에서 한 시간이나 차를 기다렸어요. 경치는 좋았지만…"),
  ("I don't think the pilot knew where we'd landed either.", "Pilot nereye indiğimizi kendisi de bilmiyordu sanırım.", "Ich glaube, der Pilot wusste selbst nicht, wo wir gelandet waren.", "Creo que ni el piloto sabía dónde habíamos aterrizado.", "どこに着陸したのか、パイロット自身もわかっていなかったと思う。", "어디에 착륙했는지 조종사도 몰랐던 것 같아요."),
 ],
 "hard": [
  ("The basket tipped over and my knee still hurts. I'll think twice.", "Sepet devrildi, dizim hâlâ ağrıyor. Bir daha düşünürüm.", "Der Korb kippte um, mein Knie tut immer noch weh. Ich überlege es mir zweimal.", "La cesta volcó y aún me duele la rodilla. Me lo pensaré dos veces.", "バスケットが倒れて、まだ膝が痛い。次はちょっと考えちゃう。", "바스켓이 넘어져서 아직 무릎이 아파요. 다음엔 다시 생각해 볼래요."),
  ("The landing was a total rodeo. Not funny at all.", "İniş tam bir rodeo gibiydi. Hiç komik değil.", "Die Landung war ein echtes Rodeo. Überhaupt nicht lustig.", "El aterrizaje fue un auténtico rodeo. Nada gracioso.", "着陸はまるでロデオ。全然笑えない。", "착륙이 완전 로데오였어요. 하나도 안 웃겨요."),
 ],
 "crash": [
  ("We hit a fairy chimney! Everyone's okay, but this is unacceptable.", "Peribacasına çarptık! Herkes iyi ama bu kabul edilemez.", "Wir sind gegen einen Feenkamin geprallt! Allen geht's gut, aber das ist inakzeptabel.", "¡Chocamos con una chimenea de hadas! Todos estamos bien, pero esto es inaceptable.", "妖精の煙突に激突！全員無事だけど、ありえない。", "요정의 굴뚝에 부딪혔어요! 다들 무사하지만 이건 용납 못 해요."),
  ("The scariest morning of my life. Stay away.", "Hayatımın en korkunç sabahı. Uzak durun.", "Der schlimmste Morgen meines Lebens. Finger weg.", "La mañana más aterradora de mi vida. Evítalos.", "人生で一番怖い朝。おすすめしない。", "인생에서 가장 무서운 아침. 피하세요."),
 ],
 "accident": [
  ("We were on {b} and came down really hard. Nobody properly looked after us.", "{b} balonundaydık, çok sert indik. Kimse doğru düzgün ilgilenmedi.", "Wir saßen im Ballon {b} und sind sehr hart gelandet. Niemand hat sich richtig um uns gekümmert.", "Íbamos en el {b} y aterrizamos muy fuerte. Nadie se ocupó de nosotros como es debido.", "{b}に乗っていたが、すごく強く着地した。誰もまともに対応してくれなかった。", "{b}에 탔는데 엄청 세게 착륙했어요. 아무도 제대로 챙겨 주지 않았어요."),
  ("The landing on {b} was terrible. The pilot looked very inexperienced.", "{b} balonunun inişi korkunçtu. Pilot çok tecrübesiz görünüyordu.", "Die Landung mit dem Ballon {b} war schrecklich. Der Pilot wirkte sehr unerfahren.", "El aterrizaje del {b} fue terrible. El piloto parecía muy inexperto.", "{b}の着陸はひどかった。パイロットはかなり未熟に見えた。", "{b}의 착륙은 끔찍했어요. 조종사가 너무 미숙해 보였어요."),
 ],
 "red": [
  ("The wind was howling and no other balloon took off. Why did we?!", "Rüzgâr uğulduyordu, başka hiçbir balon kalkmamıştı. Biz neden uçtuk?!", "Der Wind heulte, kein anderer Ballon war oben. Warum wir?!", "El viento aullaba y ningún otro globo despegó. ¡¿Por qué nosotros sí?!", "風がうなり、ほかの気球は一機も飛んでいなかった。なぜ私たちは飛んだの？！", "바람이 윙윙거리고 다른 열기구는 하나도 안 떴는데, 우린 왜 날았죠?!"),
  ("A company that ignores the rules. The flag was red and they still took off.", "Kurallara uymayan bir şirket. Bayrak kırmızıydı, yine de kaldırdılar.", "Eine Firma, die Regeln ignoriert. Die Flagge war rot, und sie sind trotzdem gestartet.", "Una empresa que ignora las normas. La bandera era roja y aun así despegaron.", "ルールを守らない会社。旗は赤だったのに飛ばした。", "규칙을 무시하는 회사. 깃발이 빨간데도 띄웠어요."),
 ],
 "skip": [
  ("The flight was called off because of the weather, but they refunded us right away. Safety first.", "Hava yüzünden uçuş iptal oldu ama paramızı hemen iade ettiler. Önce güvenlik.", "Der Flug fiel wegen des Wetters aus, aber wir bekamen sofort unser Geld zurück. Sicherheit geht vor.", "El vuelo se canceló por el tiempo, pero nos devolvieron el dinero enseguida. La seguridad es lo primero.", "天候で中止になったが、すぐに返金してくれた。安全第一。", "날씨 때문에 취소됐지만 바로 환불해 줬어요. 안전이 우선이죠."),
  ("Postponed because of the wind, but they rebooked us for the next day right away.", "Rüzgâr yüzünden ertelendi, ertesi güne hemen yer buldular.", "Wegen des Windes verschoben, für den nächsten Tag haben sie sofort Plätze gefunden.", "Se aplazó por el viento y nos encontraron sitio al día siguiente enseguida.", "風で延期になったが、翌日の枠をすぐ用意してくれた。", "바람 때문에 미뤄졌지만 다음 날 자리를 바로 잡아 줬어요."),
 ],
 "cheap": [
  ("This view at this price? Don't miss it!", "Bu fiyata bu manzara mı? Kaçırmayın!", "Diese Aussicht zu dem Preis? Nicht verpassen!", "¿Estas vistas a este precio? ¡No te lo pierdas!", "この値段でこの景色？見逃し厳禁！", "이 가격에 이 경치라니? 놓치지 마세요!"),
  ("I paid {p}. Maybe the best price in Cappadocia.", "{p} ödedim, Kapadokya'nın en iyi fiyatı bu olabilir.", "Ich habe {p} bezahlt. Vielleicht der beste Preis in Kappadokien.", "Pagué {p}. Quizá el mejor precio de Capadocia.", "{p}払った。カッパドキアでいちばん安いかも。", "{p} 냈어요. 카파도키아 최저가일지도요."),
 ],
 "pricey": [
  ("It was lovely, but {p} is a bit much. Others next door were cheaper.", "Güzeldi ama {p} biraz fazla. Yan firmada daha ucuza uçmuşlar.", "Schön war's, aber {p} ist etwas viel. Bei der Konkurrenz flogen andere billiger.", "Estuvo bonito, pero {p} es un poco caro. En la empresa de al lado volaron más barato.", "良かったけど{p}は少し高い。隣の会社はもっと安かったらしい。", "좋았지만 {p} 내기엔 좀 비싸요. 옆 회사는 더 싸게 탔대요."),
  ("The experience was good; my wallet, however, cried.", "Deneyim iyiydi ama cüzdanım ağladı.", "Das Erlebnis war gut, mein Geldbeutel hat allerdings geweint.", "La experiencia fue buena; mi cartera, en cambio, lloró.", "体験は良かった。財布は泣いたけど。", "경험은 좋았는데 지갑이 울었어요."),
 ],
 "general": [
  ("You can't come to Cappadocia and skip the balloon. This team is very professional.", "Kapadokya'ya gelip balona binmemek olmaz. Bu ekip çok profesyonel.", "Man kann nicht nach Kappadokien kommen und keinen Ballon fahren. Sehr professionelles Team.", "No puedes venir a Capadocia y no subir en globo. Este equipo es muy profesional.", "カッパドキアに来て気球に乗らないなんてありえない。このチームはとてもプロフェッショナル。", "카파도키아에 와서 열기구를 안 탈 순 없죠. 정말 프로페셔널한 팀이에요."),
  ("Worth getting up at 4 a.m. The sky was full of hundreds of balloons.", "Sabah 4'te kalkmaya değdi. Gökyüzü yüzlerce balonla doluydu.", "Das Aufstehen um 4 Uhr hat sich gelohnt. Am Himmel waren Hunderte Ballone.", "Mereció la pena madrugar a las 4. El cielo estaba lleno de cientos de globos.", "朝4時起きの価値あり。空は何百もの気球でいっぱいだった。", "새벽 4시에 일어난 보람이 있었어요. 하늘이 수백 개의 열기구로 가득했어요."),
  ("We flew with {c}; everything was planned to the minute.", "{c} ile uçtuk, her şey dakikası dakikasına planlıydı.", "Wir sind mit {c} geflogen, alles war auf die Minute geplant.", "Volamos con {c}; todo estaba planificado al minuto.", "{c}で飛んだ。すべてが分刻みで計画されていた。", "{c}에서 탔는데 모든 게 분 단위로 짜여 있었어요."),
 ],
 "ad": [
  ("There was a huge {s} ad on the balloon, and it's in all my photos.", "Balonun üstünde kocaman bir {s} reklamı vardı, bütün fotoğraflarıma girdi.", "Auf dem Ballon prangte riesige Werbung für {s}, sie ist auf all meinen Fotos.", "En el globo había un enorme anuncio de {s} y sale en todas mis fotos.", "気球に巨大な{s}の広告があって、全部の写真に写り込んだ。", "열기구에 거대한 {s} 광고가 있어서 모든 사진에 찍혔어요."),
  ("The flight was nice, but the {s} ad kind of killed the romance.", "Uçuş güzeldi ama {s} reklamı romantizmi biraz bozdu.", "Der Flug war schön, aber die Werbung für {s} hat die Romantik etwas zerstört.", "El vuelo fue bonito, pero el anuncio de {s} mató un poco el romanticismo.", "フライトは良かったが、{s}の広告でロマンチックさが台無し。", "비행은 좋았지만 {s} 광고 때문에 낭만이 좀 깨졌어요."),
  ("My dream balloon ride happened under a billboard.", "Hayalimdeki balon turu bir reklam panosunun altında geçti.", "Meine Traum-Ballonfahrt fand unter einer Werbetafel statt.", "El paseo en globo de mis sueños fue bajo una valla publicitaria.", "夢の気球ツアーは広告看板の下で終わった。", "꿈에 그리던 열기구 투어를 광고판 밑에서 했네요."),
 ],
 "cancel": [
  ("We got up at 4 a.m. and the balloon never took off. They compensated us, but what a letdown.", "Sabah 4'te kalktık, balon hiç havalanmadı. Tazminat verdiler ama tam bir hayal kırıklığı.", "Um 4 Uhr aufgestanden, und der Ballon hob nie ab. Wir wurden entschädigt, aber was für eine Enttäuschung.", "Nos levantamos a las 4 y el globo nunca despegó. Nos indemnizaron, pero qué decepción.", "朝4時に起きたのに気球は飛ばなかった。補償はあったけど残念。", "새벽 4시에 일어났는데 열기구가 뜨지도 않았어요. 보상은 받았지만 실망이에요."),
  ("The flight was cancelled at the last minute. At least they refunded us immediately.", "Uçuş son anda iptal edildi. En azından paramızı hemen iade ettiler.", "Der Flug wurde in letzter Minute abgesagt. Immerhin gab es sofort Geld zurück.", "El vuelo se canceló en el último minuto. Al menos nos devolvieron el dinero al instante.", "直前でフライト中止。少なくともすぐ返金してくれた。", "막판에 비행이 취소됐어요. 그래도 바로 환불은 해 줬어요."),
 ],
 "influencer": [
  ("We came after seeing @gezginayse's video on Instagram. It really was as beautiful as she said!", "Instagram'da @gezginayse'nin videosunu görüp geldik. Gerçekten anlattığı kadar güzeldi!", "Wir kamen wegen des Instagram-Videos von @gezginayse. Es war wirklich so schön, wie sie erzählt hat!", "Vinimos tras ver el vídeo de @gezginayse en Instagram. ¡Era tan bonito como contaba!", "Instagramで@gezginayseの動画を見て来た。本当に言っていた通り素晴らしかった！", "인스타그램에서 @gezginayse 영상을 보고 왔어요. 정말 말한 그대로 아름다웠어요!"),
  ("We'd seen it in a YouTube vlog; the crew was very friendly.", "Bir YouTube vlogunda görmüştük, ekip çok güler yüzlüydü.", "Wir hatten es in einem YouTube-Vlog gesehen, die Crew war sehr freundlich.", "Lo habíamos visto en un vlog de YouTube; el equipo fue muy amable.", "YouTubeのVlogで見た。スタッフがとてもフレンドリー。", "유튜브 브이로그에서 봤는데 직원들이 정말 친절했어요."),
  ("We got the same sunrise shot we saw on TikTok!", "TikTok'ta gördüğümüz o gün doğumu karesini biz de çektik!", "Wir haben dasselbe Sonnenaufgangsfoto wie auf TikTok geschossen!", "¡Sacamos la misma foto del amanecer que vimos en TikTok!", "TikTokで見たあの日の出の写真、私たちも撮れた！", "틱톡에서 본 그 일출 사진, 우리도 찍었어요!"),
 ],
 "guide": [
  ("The guide at our hotel recommended this company. Glad we listened.", "Otelimizdeki rehber bu şirketi önerdi, iyi ki dinlemişiz.", "Der Guide in unserem Hotel hat diese Firma empfohlen. Gut, dass wir auf ihn gehört haben.", "El guía de nuestro hotel nos recomendó esta empresa. Menos mal que le hicimos caso.", "ホテルのガイドがこの会社を勧めてくれた。聞いてよかった。", "호텔 가이드가 이 회사를 추천했는데, 듣길 잘했어요."),
  ("Our guide had flown with them himself and recommended them to us.", "Rehberimiz kendisi de uçmuş, bize bu firmayı tavsiye etti.", "Unser Guide ist selbst mit ihnen geflogen und hat sie uns empfohlen.", "Nuestro guía había volado con ellos y nos los recomendó.", "ガイド自身もここで飛んだことがあり、勧めてくれた。", "가이드가 직접 타 봤다며 이 회사를 추천해 줬어요."),
 ],
 "proposal": [
  ("The pilot stopped right at 300 meters and my partner got down on one knee. The morning of my life!", "Pilot tam 300 metrede durdu, sevgilim diz çöktü. Hayatımın en güzel sabahıydı!", "Der Pilot hielt genau auf 300 Metern, und mein Schatz ging auf die Knie. Der Morgen meines Lebens!", "El piloto se detuvo justo a 300 metros y mi pareja se arrodilló. ¡La mañana de mi vida!", "パイロットがちょうど300メートルで止まり、恋人がひざまずいた。人生最高の朝！", "조종사가 딱 300미터에서 멈추고 연인이 무릎을 꿇었어요. 인생 최고의 아침!"),
  ("I proposed in the sky, and the crew arranged everything perfectly.", "Evlilik teklifimi gökyüzünde yaptım, ekip her şeyi kusursuz ayarladı.", "Ich habe am Himmel einen Antrag gemacht, das Team hat alles perfekt organisiert.", "Pedí matrimonio en el cielo y el equipo lo organizó todo a la perfección.", "空の上でプロポーズした。スタッフが全部完璧に準備してくれた。", "하늘에서 청혼했어요. 팀이 모든 걸 완벽하게 준비해 줬어요."),
 ],
 "valley": [
  ("We glided through Pigeon Valley; it felt like we could touch the rocks!", "Güvercinlik Vadisi'nin içinden süzüldük, kayalara dokunacak gibiydik!", "Wir glitten durchs Taubental, als könnten wir die Felsen berühren!", "Planeamos por el Valle de las Palomas; ¡parecía que podíamos tocar las rocas!", "鳩の谷を滑るように飛んだ。岩に触れそうだった！", "비둘기 계곡 사이로 미끄러지듯 날았어요. 바위에 손이 닿을 것 같았어요!"),
  ("The low flight through the valley was incredible; we flew side by side with pigeons.", "Vadide alçak uçuş inanılmazdı, güvercinlerle yan yana uçtuk.", "Der Tiefflug durchs Tal war unglaublich, wir flogen Seite an Seite mit Tauben.", "El vuelo bajo por el valle fue increíble; volamos junto a las palomas.", "谷の低空飛行は最高。鳩と並んで飛んだ。", "계곡 저공비행은 대단했어요. 비둘기와 나란히 날았어요."),
 ],
 "panorama": [
  ("Our photographer loved the shot from 550 meters. All of Cappadocia was at our feet.", "Fotoğrafçımız 550 metreden çektiği kareye bayıldı. Bütün Kapadokya ayaklarımızın altındaydı.", "Unser Fotograf war begeistert von der Aufnahme aus 550 Metern. Ganz Kappadokien lag uns zu Füßen.", "A nuestro fotógrafo le encantó la foto desde 550 metros. Toda Capadocia a nuestros pies.", "カメラマンは550メートルからの一枚に大喜び。カッパドキア全体が足元に。", "사진가가 550미터에서 찍은 사진에 반했어요. 카파도키아 전체가 발아래였어요."),
  ("We went really high; a bit cold, but the view was unique.", "Çok yükseğe çıktık, biraz üşüdük ama manzara eşsizdi.", "Wir sind sehr hoch gestiegen, etwas kalt, aber die Aussicht war einzigartig.", "Subimos muchísimo; hacía algo de frío, pero la vista era única.", "かなり高く上がった。少し寒かったけど景色は唯一無二。", "아주 높이 올라가서 좀 추웠지만 경치는 정말 특별했어요."),
 ],
 "precision": [
  ("The pilot set the balloon right next to the trailer. We didn't take a single step!", "Pilot balonu tam römorkun yanına kondurdu, tek adım atmadık!", "Der Pilot setzte den Ballon direkt neben den Anhänger. Wir mussten keinen Schritt gehen!", "El piloto posó el globo justo al lado del remolque. ¡No dimos ni un paso!", "パイロットは気球をトレーラーのすぐ横に降ろした。一歩も歩かなかった！", "조종사가 열기구를 트레일러 바로 옆에 내려놨어요. 한 걸음도 안 걸었어요!"),
  ("A landing like that in this wind… Masterful.", "Rüzgârlı havada bu iniş… Usta işi.", "So eine Landung bei diesem Wind … Meisterarbeit.", "Un aterrizaje así con este viento… Trabajo de maestro.", "この風でこの着陸…まさに職人技。", "이 바람에 이런 착륙이라니… 장인의 솜씨예요."),
 ],
 "xl": [
  ("That giant {c} balloon was in everyone's photos, and we were inside it!", "Gökyüzündeki o dev {c} balonu herkesin fotoğrafındaydı, biz de içindeydik!", "Der riesige {c}-Ballon war auf allen Fotos, und wir waren drin!", "¡Ese globo gigante de {c} salía en las fotos de todos, y nosotros íbamos dentro!", "空に浮かぶ巨大な{c}の気球はみんなの写真に写っていた。私たちはその中にいた！", "하늘의 거대한 {c} 열기구가 모두의 사진에 있었고, 우린 그 안에 있었어요!"),
  ("The 32-person giant balloon was unbelievable. The basket felt like a balcony.", "32 kişilik dev balon inanılmazdı. Sepet bir balkon gibiydi.", "Der Riesenballon für 32 Personen war unglaublich. Der Korb war wie ein Balkon.", "El globo gigante de 32 plazas fue increíble. La cesta parecía un balcón.", "32人乗りの巨大気球は信じられない。バスケットはまるでバルコニー。", "32인승 거대 열기구는 믿기지 않았어요. 바스켓이 발코니 같았어요."),
  ("We saw the Cappadocia Star from afar and booked. No regrets.", "Kapadokya Yıldızı'nı uzaktan görüp rezervasyon yaptık, pişman değiliz.", "Wir haben den Kappadokien-Stern von Weitem gesehen und gebucht. Keine Reue.", "Vimos la Estrella de Capadocia de lejos y reservamos. No nos arrepentimos.", "遠くからカッパドキアの星を見て予約した。後悔なし。", "멀리서 카파도키아의 별을 보고 예약했어요. 후회 없어요."),
 ],
 "meh": [
  ("Not bad, but the crew didn't seem to care, and the balloon looked tired.", "Fena değildi ama ekip pek ilgilenmedi, balon da yorgun görünüyordu.", "Nicht schlecht, aber die Crew war desinteressiert und der Ballon wirkte müde.", "No estuvo mal, pero al equipo no le importábamos y el globo parecía cansado.", "悪くはないが、スタッフはそっけなく、気球もくたびれていた。", "나쁘진 않았지만 직원들이 무심했고 열기구도 낡아 보였어요."),
  ("We were a bit worried after reading the reviews; sadly, they were right.", "Yorumları okuyup biraz çekinmiştik, maalesef haklı çıktılar.", "Nach den Bewertungen waren wir skeptisch, leider zu Recht.", "Leer las reseñas nos preocupó un poco; por desgracia, tenían razón.", "レビューを読んで少し不安だったが、残念ながらその通りだった。", "리뷰를 보고 좀 걱정했는데, 아쉽게도 맞더라고요."),
  ("The view was beautiful; the company, mediocre. I'll try another next time.", "Manzara güzeldi, şirket vasat. Bir dahakine başka firmayı denerim.", "Die Aussicht war schön, die Firma mittelmäßig. Nächstes Mal probiere ich eine andere.", "La vista era preciosa; la empresa, mediocre. La próxima vez probaré otra.", "景色は美しかったが会社は平凡。次は別の会社にする。", "경치는 아름다웠지만 회사는 평범했어요. 다음엔 다른 곳을 가 볼래요."),
 ],
 "rival": [
  ("We were going to fly with {r}; glad we changed our minds. {c} was amazing.", "Önce {r} ile uçacaktık, iyi ki fikrimizi değiştirmişiz. {c} harikaydı.", "Eigentlich wollten wir mit {r} fliegen, zum Glück haben wir uns umentschieden. {c} war großartig.", "Íbamos a volar con {r}; menos mal que cambiamos de idea. {c} fue increíble.", "最初は{r}で飛ぶつもりだったが、変えて正解。{c}は最高だった。", "원래 {r}에서 타려다 마음을 바꿨는데 잘했어요. {c} 최고였어요."),
  ("{r} was full, so we flew with {c}. No regrets at all.", "{r} doluydu, {c} ile uçtuk. Hiç pişman değiliz.", "{r} war ausgebucht, also flogen wir mit {c}. Kein bisschen bereut.", "{r} estaba lleno, así que volamos con {c}. No nos arrepentimos en absoluto.", "{r}は満席で、{c}で飛んだ。まったく後悔なし。", "{r} 쪽이 꽉 차서 {c}에서 탔는데, 전혀 후회 없어요."),
 ],
}
for kind, items in R.items():
    for i, t in enumerate(items):
        add(f"review.{kind}.{i}", *t)
add("review.day", "day %@", "gün %@", "Tag %@", "día %@", "%@日目", "%@일차")
