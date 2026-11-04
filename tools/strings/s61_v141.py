from s1_ui import add
from s48_contracts import short_more

# v141: the Maasai Mara (Kenya), the fifth region and the hardest: open after the Bristol baron, part of the Grand Tour,
# counted in US dollars. Rains instead of winter, the Great Migration instead of a fiesta, the rangers' fine for landing
# among the herds, the Mara River, the reserve fee per passenger. Its guide is Lemayian Ole Sankale, a Maasai elder; its
# boss Catherine Wanjiru of Oloololo Sky Safaris. The offices now open with their regions; Paris became London.

# ---- The region, the map ----
add("region.mara", "Maasai Mara", "Maasai Mara", "Maasai Mara", "Maasai Mara", "マサイマラ", "마사이마라")
add("pin.mara", "Maasai Mara", "Maasai Mara", "Maasai Mara", "Maasai Mara", "マサイマラ", "마사이마라")
add("pin.mara.land", "Kenya", "Kenya", "Kenia", "Kenia", "ケニア", "케냐")
add("map.here.mara", "The savanna, the Great Migration and the toughest balloon safari in the world.",
    "Savana, büyük göç ve dünyanın en çetin balon safarisi.",
    "Die Savanne, die Große Migration und die härteste Ballonsafari der Welt.",
    "La sabana, la Gran Migración y el safari en globo más duro del mundo.",
    "サバンナ、大移動、そして世界一過酷な気球サファリ。",
    "사바나, 대이동, 그리고 세상에서 가장 험난한 열기구 사파리.")
add("map.openSub.mara",
    "A sunrise safari over the savanna in Kenya. The toughest region: few tourists, costly fuel, a reserve fee for every passenger, strong rivals and rainy seasons; landing among the herds brings a fine, landing in the river is a disaster. You start with %1$@. Entry fee %2$@ from the holding.",
    "Kenya'da savananın üstünde gün doğumu safarisi. En çetin bölge: az turist, pahalı yakıt, yolcu başı koruma alanı ücreti, güçlü rakipler, yağmur mevsimleri; sürülerin arasına inmek ceza, nehre inmek felaket. Başlangıç kasası: %1$@. Giriş bedeli holding kasasından: %2$@.",
    "Eine Safari bei Sonnenaufgang über der Savanne Kenias. Die härteste Region: wenige Touristen, teurer Treibstoff, eine Schutzgebietsgebühr pro Passagier, starke Rivalen und Regenzeiten; eine Landung zwischen den Herden kostet eine Strafe, eine Landung im Fluss ist eine Katastrophe. Du startest mit %1$@. Einstiegsgebühr %2$@ aus der Holding.",
    "Un safari al amanecer sobre la sabana de Kenia. La región más dura: pocos turistas, combustible caro, una tasa de la reserva por pasajero, rivales fuertes y temporadas de lluvias; aterrizar entre las manadas trae multa y aterrizar en el río es un desastre. Empiezas con %1$@. Cuota de entrada %2$@ desde el holding.",
    "ケニアのサバンナで日の出のサファリ。最も過酷な地域だ。観光客は少なく、燃料は高く、乗客ごとに保護区の料金がかかり、ライバルは強く、雨季もある。群れの中に着陸すれば罰金、川に着陸すれば大惨事。開始資金は%1$@。参入費%2$@はホールディングスから。",
    "케냐 사바나 위의 일출 사파리. 가장 험난한 지역입니다: 적은 관광객, 비싼 연료, 승객마다 내는 보호구역 요금, 강한 경쟁자, 우기. 무리 사이에 착륙하면 벌금, 강에 착륙하면 재앙입니다. 시작 자금 %1$@. 진입 비용 %2$@은(는) 지주회사가 냅니다.")
add("map.lockedSub.mara",
    "Unlocks when you become baron of Bristol. Over the savanna in Kenya: the Great Migration, lions and elephants. The toughest region in the game.",
    "Bristol baronu olunca açılır. Kenya'da savananın üstünde: büyük göç, aslanlar ve filler. Oyunun en çetin bölgesi.",
    "Öffnet, wenn du Baron von Bristol wirst. Über der Savanne Kenias: die Große Migration, Löwen und Elefanten. Die härteste Region des Spiels.",
    "Se abre cuando seas barón de Bristol. Sobre la sabana de Kenia: la Gran Migración, leones y elefantes. La región más dura del juego.",
    "ブリストル男爵になると開放。ケニアのサバンナの上空、大移動、ライオンとゾウ。ゲームで最も過酷な地域。",
    "브리스톨 남작이 되면 열립니다. 케냐 사바나 위: 대이동, 사자와 코끼리. 게임에서 가장 험난한 지역.")
add("regions.lockedMara", "Opens when you're baron of Bristol", "Bristol baronu olunca açılır", "Öffnet, wenn du Baron von Bristol bist",
    "Se abre cuando seas barón de Bristol", "ブリストル男爵になると開放", "브리스톨 남작이 되면 열림")

# ---- Names: hotels, sponsors, the valley mission, the giant balloon ----
for k, name in [("stone", "Talek River Camp"), ("mansion", "Oloololo Ridge Lodge"), ("cave", "Acacia Tented Camp"), ("palace", "Mara Crown Lodge")]:
    ja = {"stone": "タレク・リバー・キャンプ", "mansion": "オロロロ・リッジ・ロッジ", "cave": "アカシア・テンテッド・キャンプ", "palace": "マラ・クラウン・ロッジ"}[k]
    ko = {"stone": "탈렉 리버 캠프", "mansion": "올로롤로 리지 로지", "cave": "아카시아 텐티드 캠프", "palace": "마라 크라운 로지"}[k]
    add(f"mara.hotel.{k}", name, name, name, name, ja, ko)
for k, name, ja, ko in [("carpet", "Kahawa Coffee Co.", "カハワ・コーヒー", "카하와 커피"), ("wine", "Savanna Bank", "サバンナ銀行", "사바나 은행"),
                        ("bank", "Kericho Tea Estates", "ケリチョ・ティー農園", "케리초 차 농원"), ("energy", "Twiga Mobile", "トゥイガ・モバイル", "트위가 모바일")]:
    add(f"mara.sponsor.{k}", name, name, name, name, ja, ko)
add("mara.mission.valley", "Touch of the Mara", "Mara dokunuşu", "Berührung der Mara", "Toque del Mara", "マラ川タッチ", "마라 강 터치")
add("mara.mission.desc.valley",
    "Drop below 150 m over the Mara River and salute the hippos, but never land on its banks.",
    "Mara Nehri'nin üstünde 150 m'nin altına alçal, su aygırlarını selamla; ama kıyısına inme.",
    "Sinke über dem Mara-Fluss unter 150 m und grüße die Flusspferde, aber lande nie an seinen Ufern.",
    "Baja de 150 m sobre el río Mara y saluda a los hipopótamos, pero nunca aterrices en sus orillas.",
    "マラ川の上で高度150m未満まで下り、カバにあいさつしよう。ただし岸には絶対に着陸しないこと。",
    "마라 강 위에서 150m 아래로 내려가 하마들에게 인사하세요. 단, 강가에는 절대 착륙하지 마세요.")
add("bname.maraStar", "Star of the Mara", "Mara Yıldızı", "Stern der Mara", "Estrella del Mara", "マラの星", "마라의 별")

# ---- Chapters and goals ----
add("chapter.tentedCamp", "Tented Camp", "Çadırlı Kamp", "Zeltcamp", "Campamento de tiendas", "テントキャンプ", "텐트 캠프")
add("chapter.tentedCamp.award", "The Narok Chamber of Commerce named you New Safari Business of the Year",
    "Narok Ticaret Odası seni yılın yeni safari işletmesi seçti",
    "Die Handelskammer von Narok kürte dich zum neuen Safari-Unternehmen des Jahres",
    "La Cámara de Comercio de Narok te nombró nueva empresa de safaris del año",
    "ナロク商工会議所が、あなたを今年の新しいサファリ企業に選んだ",
    "나록 상공회의소가 당신을 올해의 신규 사파리 기업으로 선정했습니다")
add("chapter.oloololo", "Oloololo Escarpment", "Oloololo Sırtı", "Oloololo-Steilhang", "Escarpe de Oloololo", "オロロロ断崖", "올로롤로 절벽")
add("chapter.oloololo.award", "The East African Balloon Pilots' Association named you master of the savanna",
    "Doğu Afrika Balon Pilotları Derneği seni savananın ustası ilan etti",
    "Der Ostafrikanische Ballonpilotenverband ernannte dich zum Meister der Savanne",
    "La Asociación de Pilotos de Globo de África Oriental te nombró maestro de la sabana",
    "東アフリカ気球パイロット協会が、あなたをサバンナの名手と認めた",
    "동아프리카 열기구 조종사 협회가 당신을 사바나의 달인으로 인정했습니다")
add("chapter.migration", "The Great Migration", "Büyük Göç", "Die Große Migration", "La Gran Migración", "大移動", "대이동")
add("chapter.migration.award", "The Kenya Tourism Board named you Safari Company of the Year",
    "Kenya Turizm Kurulu seni yılın safari şirketi seçti",
    "Das Kenya Tourism Board kürte dich zum Safari-Unternehmen des Jahres",
    "La Junta de Turismo de Kenia te nombró empresa de safaris del año",
    "ケニア観光局が、あなたを今年のサファリ会社に選んだ",
    "케냐 관광청이 당신을 올해의 사파리 회사로 선정했습니다")
add("chapter.baronMara", "Baron of the Maasai Mara", "Maasai Mara Baronu", "Baron der Maasai Mara", "Barón del Maasai Mara", "マサイマラ男爵", "마사이마라 남작")
add("chapter.baronMara.award", "", "", "", "", "", "")
add("goal.rains", "Get through a rainy season", "Bir yağmur mevsimini atlat", "Überstehe eine Regenzeit", "Supera una temporada de lluvias",
    "雨季を一度乗り切る", "우기를 한 번 버텨 내기")
add("goal.fiesta.mara", "Fly during the Great Migration", "Büyük Göç'te uç", "Fliege während der Großen Migration", "Vuela durante la Gran Migración",
    "大移動の間に飛ぶ", "대이동 기간에 비행하기")
add("goal.ctrDone.mara", "Total safari plane groups flown in full: %@", "Toplam eksiksiz uçurulan safari uçağı grubu: %@",
    "Vollständig geflogene Safariflug-Gruppen insgesamt: %@", "Total de grupos de avioneta safari completados: %@",
    "全員を飛ばしたサファリ機グループ（合計）：%@", "전원 태운 사파리 비행기 단체(합계): %@")
add("goal.ctrDoneAny.mara", "Total groups flown in full (all companies): %@", "Toplam eksiksiz uçurulan grup (bütün şirketler): %@",
    "Vollständig geflogene Safariflug-Gruppen, beliebige Firma: %@", "Grupos de avioneta safari completados, cualquier empresa: %@",
    "全員を飛ばしたサファリ機グループ（どの会社でも）：%@", "전원 태운 사파리 비행기 단체(어느 회사든): %@")

# ---- Achievements ----
add("ach.mara", "Sky of the savanna", "Savananın göğü", "Himmel über der Savanne", "El cielo de la sabana", "サバンナの空", "사바나의 하늘")
add("ach.mara.d", "You entered the Maasai Mara", "Maasai Mara'ya girdin", "Du bist in der Maasai Mara angekommen", "Llegaste al Maasai Mara",
    "マサイマラに進出した", "마사이마라에 진출했습니다")
add("ach.baronMara", "Baron of the Maasai Mara", "Maasai Mara Baronu", "Baron der Maasai Mara", "Barón del Maasai Mara", "マサイマラ男爵", "마사이마라 남작")
add("ach.baronMara.d", "Master of the savanna and the Great Migration", "Savananın ve büyük göçün sahibi", "Herr über Savanne und Große Migration",
    "Dueño de la sabana y de la Gran Migración", "サバンナと大移動の主", "사바나와 대이동의 주인")

# ---- New rivals ----
add("hez.entrant.serengeti",
    "Serengeti Crossing Balloons has crossed the border from Tanzania into the Mara! A big fleet and deep pockets. After Oloololo Sky, this may be the most dangerous one, my friend.",
    "Serengeti Crossing Balloons, Tanzanya'dan sınırı geçip Mara'ya geldi! Filosu büyük, kesesi derin. Oloololo Sky'dan sonra en tehlikelisi bu olabilir dostum.",
    "Serengeti Crossing Balloons ist aus Tansania über die Grenze in die Mara gekommen! Große Flotte, tiefe Taschen. Nach Oloololo Sky ist das vielleicht der gefährlichste, mein Freund.",
    "¡Serengeti Crossing Balloons ha cruzado la frontera desde Tanzania hasta el Mara! Flota grande y bolsillos profundos. Después de Oloololo Sky, quizá sea el más peligroso, amigo.",
    "セレンゲティ・クロッシング・バルーンズがタンザニアから国境を越えてマラにやって来た！大きな船団に、豊かな資金。オロロロ・スカイの次に危険な相手かもしれないぞ、友よ。",
    "세렝게티 크로싱 벌룬스가 탄자니아에서 국경을 넘어 마라에 들어왔네! 함대도 크고 자금도 두둑해. 올로롤로 스카이 다음으로 가장 위험한 상대일지도 모르네, 친구.")
add("hez.entrant.budgetBush",
    "A cut-price outfit called Budget Bush Flights has opened. They'll sell backpackers tickets at half price, and they won't pay much attention to the herds.",
    "Budget Bush Flights diye bir ucuzcu açıldı. Sırt çantalı gezginlere yarı fiyata bilet satacaklar; sürülere de pek dikkat etmeyecekler.",
    "Ein Billiganbieter namens Budget Bush Flights hat eröffnet. Er verkauft Rucksackreisenden Tickets zum halben Preis und achtet kaum auf die Herden.",
    "Ha abierto una low cost llamada Budget Bush Flights. Venderán billetes a mitad de precio a mochileros, y no prestarán mucha atención a las manadas.",
    "バジェット・ブッシュ・フライツという格安業者が開業した。バックパッカーに半額でチケットを売るそうだ。群れにはあまり気を配らないだろう。",
    "버짓 부시 플라이츠라는 저가 업체가 문을 열었네. 배낭여행객에게 반값에 표를 팔 거고, 동물 무리에는 별로 신경 쓰지 않을 걸세.")
add("hez.entrant.leopardRock",
    "A luxury boutique company called Leopard Rock Luxury Flights has opened. Few balloons, a champagne breakfast after landing, very high prices. The rich tourists will go to them.",
    "Leopard Rock Luxury Flights adında lüks bir butik şirket açıldı. Az balon, inişte şampanyalı kahvaltı, çok yüksek fiyat. Zengin turistler onlara gidecek.",
    "Eine Luxus-Boutiquefirma namens Leopard Rock Luxury Flights hat eröffnet. Wenige Ballons, Champagnerfrühstück nach der Landung, sehr hohe Preise. Die reichen Touristen gehen zu ihnen.",
    "Ha abierto una empresa boutique de lujo llamada Leopard Rock Luxury Flights. Pocos globos, desayuno con champán al aterrizar y precios altísimos. Los turistas ricos irán con ellos.",
    "レパード・ロック・ラグジュアリー・フライツという高級ブティック会社が開業した。気球は少なく、着陸後にはシャンパンの朝食、値段はとても高い。裕福な観光客はそちらへ行くだろう。",
    "레퍼드 록 럭셔리 플라이츠라는 고급 부티크 회사가 문을 열었네. 열기구는 적고, 착륙 후엔 샴페인 아침 식사, 가격은 아주 비싸지. 부유한 관광객은 그쪽으로 갈 걸세.")
add("hez.entrant.narokHighlands",
    "A family from Narok has founded Narok Highlands Balloons. A balanced, solid, patient rival.",
    "Narok'tan bir aile şirketi Narok Highlands Balloons'u kurdu. Dengeli, sağlam, sabırlı bir rakip.",
    "Eine Familie aus Narok hat Narok Highlands Balloons gegründet. Ein ausgewogener, solider, geduldiger Rivale.",
    "Una familia de Narok ha fundado Narok Highlands Balloons. Un rival equilibrado, sólido y paciente.",
    "ナロクの一家がナロク・ハイランズ・バルーンズを立ち上げた。バランスが良く、堅実で、辛抱強いライバルだ。",
    "나록의 한 가족이 나록 하이랜즈 벌룬스를 세웠네. 균형 잡히고 탄탄하며 끈기 있는 경쟁자일세.")

# ---- The boss: Catherine Wanjiru, Oloololo Sky Safaris ----
add("boss.mara.name", "Catherine Wanjiru", "Catherine Wanjiru", "Catherine Wanjiru", "Catherine Wanjiru", "キャサリン・ワンジル", "캐서린 완지루")
add("boss.mara.title", "Owner of Oloololo Sky Safaris", "Oloololo Sky Safaris sahibi", "Inhaberin von Oloololo Sky Safaris", "Dueña de Oloololo Sky Safaris",
    "オロロロ・スカイ・サファリズのオーナー", "올로롤로 스카이 사파리스 대표")
short_more("boss.mara.hello",
 ("Karibu, newcomer. Catherine Wanjiru, Oloololo Sky Safaris. My father inflated the first balloon under this escarpment in 1979; every lodge here has worked with us ever since.",
  "Karibu, yeni gelen. Catherine Wanjiru, Oloololo Sky Safaris. Babam bu sırtın altında ilk balonu 1979'da şişirdi; o günden beri buradaki her lodge bizimle çalışır.",
  "Karibu, Neuling. Catherine Wanjiru, Oloololo Sky Safaris. Mein Vater hat 1979 unter diesem Steilhang den ersten Ballon aufgeblasen; seitdem arbeitet jede Lodge hier mit uns.",
  "Karibu, recién llegado. Catherine Wanjiru, Oloololo Sky Safaris. Mi padre infló el primer globo bajo este escarpe en 1979; desde entonces todos los lodges de aquí trabajan con nosotros.",
  "カリブ、新入りさん。オロロロ・スカイ・サファリズのキャサリン・ワンジルよ。父は1979年にこの断崖の下で最初の気球をふくらませた。それ以来、ここのロッジはどこも私たちと仕事をしているの。",
  "카리부, 신참. 올로롤로 스카이 사파리스의 캐서린 완지루예요. 우리 아버지가 1979년에 이 절벽 아래에서 첫 열기구를 부풀렸죠. 그 뒤로 여기 모든 로지가 우리와 일해요."),
 ("You won in Bristol, I hear. The savanna is nothing like fog: here the wind, the rain and the lions do nobody any favours.",
  "Bristol'de kazanmışsın, duydum. Savana sise benzemez: burada rüzgâr, yağmur ve aslan kimseye torpil yapmaz.",
  "Du hast in Bristol gewonnen, höre ich. Die Savanne ist kein Nebel: Hier machen Wind, Regen und Löwen niemandem Geschenke.",
  "Ganaste en Bristol, he oído. La sabana no se parece a la niebla: aquí el viento, la lluvia y los leones no le hacen favores a nadie.",
  "ブリストルで勝ったそうね。サバンナは霧とは違う。ここでは風も雨もライオンも、誰にもひいきはしないわ。",
  "브리스톨에서 이겼다면서요. 사바나는 안개와 달라요. 여기선 바람도, 비도, 사자도 누구 편을 들어주지 않아요."))
add("boss.mara.ch1",
    "You've gone on safari with five balloons? My fleet fills the morning sky like a herd. The lodge managers don't even know you yet.",
    "Beş balonla mı safariye çıktın? Benim filom sabah göğünü bir sürü gibi doldurur. Lodge müdürleri seni daha tanımıyor bile.",
    "Mit fünf Ballons auf Safari? Meine Flotte füllt den Morgenhimmel wie eine Herde. Die Lodge-Manager kennen dich noch nicht einmal.",
    "¿Te has ido de safari con cinco globos? Mi flota llena el cielo de la mañana como una manada. Los gerentes de los lodges ni siquiera te conocen todavía.",
    "気球5機でサファリに出たの？私の船団は朝の空を群れのように埋め尽くすわ。ロッジの支配人たちはまだあなたを知りもしない。",
    "열기구 다섯 대로 사파리에 나섰다고요? 내 함대는 아침 하늘을 동물 무리처럼 가득 채워요. 로지 지배인들은 아직 당신을 알지도 못해요.")
add("boss.mara.ch2",
    "You got through the rains, I'll grant you. But look whose balloons the tourists board when the Great Migration comes. The migration comes every year; will you be here every year?",
    "Yağmurları atlattın, kabul. Ama Büyük Göç gelince turistler kimin balonuna biniyor, bir bak. Göç her yıl gelir; sen her yıl burada olacak mısın?",
    "Du hast die Regenzeit überstanden, zugegeben. Aber schau, in wessen Ballons die Touristen steigen, wenn die Große Migration kommt. Die Migration kommt jedes Jahr; wirst du jedes Jahr hier sein?",
    "Superaste las lluvias, lo admito. Pero mira en qué globos se suben los turistas cuando llega la Gran Migración. La migración llega cada año; ¿estarás tú aquí cada año?",
    "雨季を乗り切ったのは認めるわ。でも大移動が来たとき、観光客が誰の気球に乗るか見てごらんなさい。大移動は毎年来る。あなたは毎年ここにいるのかしら？",
    "우기를 버틴 건 인정해요. 하지만 대이동이 오면 관광객이 누구 열기구에 타는지 보세요. 대이동은 해마다 와요. 당신도 해마다 여기 있을까요?")
add("boss.mara.passed",
    "Yesterday you flew more passengers than I did. They're talking about it in Nairobi. I'm not talking; I'm flying.",
    "Dün benden fazla yolcu uçurmuşsun. Nairobi'de konuşuluyor. Ben konuşmuyorum; ben uçuyorum.",
    "Gestern hast du mehr Passagiere geflogen als ich. In Nairobi redet man darüber. Ich rede nicht; ich fliege.",
    "Ayer volaste más pasajeros que yo. En Nairobi se habla de ello. Yo no hablo; yo vuelo.",
    "昨日はあなたのほうが多くの乗客を飛ばしたそうね。ナイロビで噂になってる。私は噂しない。飛ぶだけよ。",
    "어제 나보다 승객을 더 태웠다면서요. 나이로비에서 다들 그 얘기예요. 난 말하지 않아요. 난 날아요.")
add("boss.mara.hotel",
    "My father opened his lodge the same year as that camp's owner. Here deals are made by the fire, with a handshake.",
    "O kampın sahibiyle babam aynı yıl lodge açtı. Burada anlaşmalar ateş başında, el sıkışarak yapılır.",
    "Mein Vater hat seine Lodge im selben Jahr eröffnet wie der Besitzer dieses Camps. Hier werden Geschäfte am Feuer gemacht, mit Handschlag.",
    "Mi padre abrió su lodge el mismo año que el dueño de ese campamento. Aquí los tratos se cierran junto al fuego, con un apretón de manos.",
    "あのキャンプのオーナーと父は同じ年にロッジを開いたの。ここでは取引は焚き火のそばで、握手で決まるのよ。",
    "그 캠프 주인과 우리 아버지는 같은 해에 로지를 열었어요. 여기선 거래를 모닥불 옆에서 악수로 해요.")
add("boss.mara.poach",
    "I offered your pilot a house in Nairobi and lessons at the flying school. On the savanna a good pilot is worth more than gold.",
    "Pilotuna Nairobi'de bir ev ve uçuş okulunda ders teklif ettim. İyi pilot savanada altından değerlidir.",
    "Ich habe deinem Piloten ein Haus in Nairobi und Stunden an der Flugschule angeboten. In der Savanne ist ein guter Pilot mehr wert als Gold.",
    "Le ofrecí a tu piloto una casa en Nairobi y clases en la escuela de vuelo. En la sabana un buen piloto vale más que el oro.",
    "あなたのパイロットにナイロビの家と飛行学校の授業を提案したわ。サバンナでは良いパイロットは金より価値があるの。",
    "당신 조종사에게 나이로비의 집과 비행 학교 수업을 제안했어요. 사바나에선 좋은 조종사가 금보다 귀하죠.")
add("boss.mara.accident",
    "You came down hard, I hear. The rangers keep a thick notebook; my memory is thicker still.",
    "Sert indin, duydum. Korucuların defteri kalındır; benim hafızam daha da kalın.",
    "Du bist hart heruntergekommen, höre ich. Die Ranger führen ein dickes Notizbuch; mein Gedächtnis ist noch dicker.",
    "Aterrizaste fuerte, he oído. Los guardas llevan un cuaderno grueso; mi memoria es aún más gruesa.",
    "ひどい着陸だったそうね。レンジャーの手帳は分厚いけど、私の記憶はもっと分厚いわよ。",
    "거칠게 내려왔다면서요. 레인저들의 수첩은 두껍지만, 내 기억력은 더 두꺼워요.")
add("boss.mara.deal",
    "Very well. The wind has turned your way. If you want to take over Oloololo Sky, let's talk. Only, look after my pilots; every one of them is a child of this savanna.",
    "Peki. Rüzgâr senden yana döndü. Oloololo Sky'ı devralmak istersen konuşalım. Yalnız pilotlarımı koru; her biri bu savananın çocuğu.",
    "Nun gut. Der Wind hat sich zu deinen Gunsten gedreht. Wenn du Oloololo Sky übernehmen willst, lass uns reden. Nur pass auf meine Piloten auf; jeder von ihnen ist ein Kind dieser Savanne.",
    "Muy bien. El viento ha girado a tu favor. Si quieres quedarte con Oloololo Sky, hablemos. Solo cuida de mis pilotos; cada uno es hijo de esta sabana.",
    "いいわ。風はあなたのほうへ向いた。オロロロ・スカイを引き継ぎたいなら話しましょう。ただ、私のパイロットたちを大事にして。みんなこのサバンナの子なの。",
    "좋아요. 바람이 당신 쪽으로 돌았네요. 올로롤로 스카이를 인수하고 싶다면 이야기해요. 다만 내 조종사들을 지켜 줘요. 모두 이 사바나의 아이들이니까.")
add("boss.mara.gone",
    "I've sold my last balloon. My father's basket is going to the museum in Nairobi. The Mara is yours now. When the migration comes, look at the sky once for me too.",
    "Son balonumu da sattım. Babamın sepeti Nairobi'deki müzeye gidiyor. Mara artık senin. Göç geldiğinde gökyüzüne bir de benim için bak.",
    "Ich habe meinen letzten Ballon verkauft. Der Korb meines Vaters kommt ins Museum in Nairobi. Die Mara gehört jetzt dir. Wenn die Migration kommt, schau auch einmal für mich in den Himmel.",
    "He vendido mi último globo. La cesta de mi padre se va al museo de Nairobi. El Mara es tuyo ahora. Cuando llegue la migración, mira al cielo también por mí.",
    "最後の気球も売ったわ。父のバスケットはナイロビの博物館へ行く。マラはもうあなたのものよ。大移動が来たら、私の分も一度空を見上げてね。",
    "마지막 열기구도 팔았어요. 아버지의 바스켓은 나이로비 박물관으로 가요. 이제 마라는 당신 거예요. 대이동이 오면 나를 위해서도 한 번 하늘을 봐 줘요.")
add("boss.mara.baron",
    "Baron of the Maasai Mara. My father would have frowned first, then shaken your hand. I'm shaking your hand. The savanna has accepted you; that is not easy.",
    "Maasai Mara Baronu. Babam görse önce kaşlarını çatardı, sonra elini sıkardı. Ben elini sıkıyorum. Savana seni kabul etti; bu kolay değildir.",
    "Baron der Maasai Mara. Mein Vater hätte zuerst die Stirn gerunzelt und dir dann die Hand geschüttelt. Ich schüttle dir die Hand. Die Savanne hat dich angenommen; das ist nicht leicht.",
    "Barón del Maasai Mara. Mi padre primero habría fruncido el ceño y luego te habría dado la mano. Yo te doy la mano. La sabana te ha aceptado; eso no es fácil.",
    "マサイマラ男爵。父なら最初は眉をひそめて、それから握手したでしょうね。私は握手するわ。サバンナがあなたを受け入れた。それは簡単なことじゃないの。",
    "마사이마라 남작. 우리 아버지라면 먼저 눈살을 찌푸리고, 그다음 악수했을 거예요. 나는 악수할게요. 사바나가 당신을 받아들였어요. 쉬운 일이 아니죠.")

# ---- The guide: Lemayian Ole Sankale, a Maasai elder ----
add("guide.mara.name", "Lemayian Ole Sankale", "Lemayian Ole Sankale", "Lemayian Ole Sankale", "Lemayian Ole Sankale", "レマイアン・オレ・サンカレ", "레마이안 올레 산칼레")
add("guide.short.mara", "Lemayian", "Lemayian", "Lemayian", "Lemayian", "レマイアン", "레마이안")
short_more("guide.mara.hello",
 ("Supa, my friend! I'm Lemayian Ole Sankale. I was born on this savanna and for thirty years I led guests after the herds; I'll show you the way in the Mara.",
  "Supa, dostum! Ben Lemayian Ole Sankale. Bu savanada doğdum, otuz yıl misafirleri sürülerin peşinden götürdüm; Mara'da sana ben yol göstereceğim.",
  "Supa, mein Freund! Ich bin Lemayian Ole Sankale. Ich bin in dieser Savanne geboren und habe dreißig Jahre lang Gäste den Herden nachgeführt; in der Mara zeige ich dir den Weg.",
  "¡Supa, amigo! Soy Lemayian Ole Sankale. Nací en esta sabana y durante treinta años llevé a los huéspedes tras las manadas; en el Mara yo te mostraré el camino.",
  "スパ、友よ！わしはレマイアン・オレ・サンカレ。このサバンナで生まれ、30年間お客を群れのあとへ案内してきた。マラではわしが道を教えよう。",
  "수파, 친구! 나는 레마이안 올레 산칼레라네. 이 사바나에서 태어나 30년 동안 손님들을 동물 무리 뒤로 안내했지. 마라에서는 내가 길을 알려 주겠네."),
 ("The grass tells you the wind, the birds tell you the rain. Respect the animals and stay away from the river. Master Hezarfen has left you in my care. Pole pole, my friend: slowly, slowly.",
  "Rüzgârı otlar söyler, yağmuru kuşlar. Hayvanlara saygı göster, nehre yaklaşma. Hezarfen Usta seni bana emanet etti. Pole pole, dostum: yavaş yavaş.",
  "Das Gras verrät dir den Wind, die Vögel den Regen. Achte die Tiere und halte dich vom Fluss fern. Meister Hezarfen hat dich mir anvertraut. Pole pole, mein Freund: langsam, langsam.",
  "La hierba te dice el viento; los pájaros, la lluvia. Respeta a los animales y aléjate del río. El maestro Hezarfen te ha dejado a mi cuidado. Pole pole, amigo: despacio, despacio.",
  "風は草が教え、雨は鳥が教えてくれる。動物を敬い、川には近づくな。ヘザルフェン師匠がおまえをわしに託した。ポレポレ、友よ。ゆっくり、ゆっくりだ。",
  "바람은 풀이 알려 주고, 비는 새가 알려 준다네. 동물을 존중하고 강에는 가까이 가지 말게. 헤자르펜 스승이 자네를 내게 맡겼네. 폴레 폴레, 친구. 천천히, 천천히."))
add("ceremony.baronLead.mara",
    "Day %1$@. Two of every three balloons in the sky over %2$@ fly the colors of %3$@. Lemayian Ole Sankale leans on his stick and smiles: “My forefathers shared this savanna with the lion, my friend. You have learned to share the sky. Ashe oleng: thank you very much.”",
    "Gün %1$@. %2$@ göğündeki her üç balondan ikisi %3$@ renklerinde. Lemayian Ole Sankale sopasını yere dayayıp gülümsüyor: “Atalarım bu savanayı aslanla paylaştı, dostum. Sen gökyüzünü paylaşmayı öğrendin. Ashe oleng: çok teşekkür ederim.”",
    "Tag %1$@. Zwei von drei Ballons am Himmel über %2$@ tragen die Farben von %3$@. Lemayian Ole Sankale stützt sich auf seinen Stock und lächelt: „Meine Vorfahren haben diese Savanne mit dem Löwen geteilt, mein Freund. Du hast gelernt, den Himmel zu teilen. Ashe oleng: vielen Dank.“",
    "Día %1$@. Dos de cada tres globos en el cielo de %2$@ llevan los colores de %3$@. Lemayian Ole Sankale se apoya en su bastón y sonríe: «Mis antepasados compartieron esta sabana con el león, amigo. Tú has aprendido a compartir el cielo. Ashe oleng: muchas gracias».",
    "%1$@日目。%2$@の空を飛ぶ気球の3機に2機が%3$@の色だ。レマイアン・オレ・サンカレが杖にもたれて微笑む。「わしの祖先はこのサバンナをライオンと分け合ってきた、友よ。おまえは空を分け合うことを覚えた。アシェ・オレン。本当にありがとう。」",
    "%1$@일째. %2$@ 하늘의 열기구 셋 중 둘이 %3$@의 색을 띠고 있습니다. 레마이안 올레 산칼레가 지팡이에 기대어 미소 짓습니다. “내 조상들은 이 사바나를 사자와 나눠 썼다네, 친구. 자네는 하늘을 나누는 법을 배웠지. 아셰 올렝. 정말 고맙네.”")
add("ceremony.baronHint.mara",
    "The skies of five regions are yours, the savanna's too. The holding's last goals are waiting.",
    "Beş bölgenin göğü senin, savananınki de. Holdingin son hedefleri seni bekliyor.",
    "Der Himmel über fünf Regionen gehört dir, auch der über der Savanne. Die letzten Ziele der Holding warten.",
    "Los cielos de cinco regiones son tuyos, también el de la sabana. Te esperan los últimos objetivos del holding.",
    "5つの地域の空は君のもの、サバンナの空もだ。ホールディングスの最後の目標が待っている。",
    "다섯 지역의 하늘이 당신 것입니다. 사바나의 하늘까지. 지주회사의 마지막 목표들이 기다립니다.")
add("insp.name.mara", "Inspector Wanjiku Mwangi", "Müfettiş Wanjiku Mwangi", "Inspektorin Wanjiku Mwangi", "Inspectora Wanjiku Mwangi",
    "ワンジク・ムワンギ検査官", "완지쿠 므왕기 검사관")
add("insp.title.mara", "Kenya Civil Aviation Authority", "Kenya Sivil Havacılık Otoritesi", "Kenianische Zivilluftfahrtbehörde",
    "Autoridad de Aviación Civil de Kenia", "ケニア民間航空局", "케냐 민간항공청")

# ---- Hezarfen and Lemayian: entering, the migration, the rains ----
short_more("hez.entered.mara",
 ("The Maasai Mara, kid: the toughest sky in the game! You start with %@ and one small balloon. Few tourists, fuel trucked in from Nairobi, and a reserve fee for every passenger.",
  "Maasai Mara evlat, oyunun en çetin göğü! %@ ve küçük bir balonla başlıyorsun. Turist az, yakıt kamyonla Nairobi'den gelir, her yolcu için koruma alanına ücret ödersin.",
  "Die Maasai Mara, Lehrling: der härteste Himmel im Spiel! Du startest mit %@ und einem kleinen Ballon. Wenige Touristen, Treibstoff per Lastwagen aus Nairobi und eine Schutzgebietsgebühr für jeden Passagier.",
  "¡El Maasai Mara, aprendiz: el cielo más duro del juego! Empiezas con %@ y un globo pequeño. Pocos turistas, combustible traído en camión desde Nairobi y una tasa de la reserva por cada pasajero.",
  "マサイマラだぞ、弟子よ。ゲームで最も過酷な空だ！%@と小さな気球ひとつで始める。観光客は少なく、燃料はナイロビからトラックで運ばれ、乗客ひとりごとに保護区へ料金を払う。",
  "마사이마라라네, 제자여. 게임에서 가장 험난한 하늘이지! %@, 그리고 작은 열기구 하나로 시작하네. 관광객은 적고, 연료는 나이로비에서 트럭으로 오고, 승객마다 보호구역에 요금을 내야 하네."),
 ("Don't land among the herds: the rangers will fine you. Keep away from the Mara River; the hippos and crocodiles don't joke. In the rainy seasons the tourists drop by half, but when the Great Migration comes the savanna fills up. Catherine Wanjiru of Oloololo Sky has flown here for thirty years; the rivals join forces quickly. Be patient, kid.",
  "Sürülerin arasına inme: korucular ceza keser. Mara Nehri'ne yaklaşma; su aygırları ve timsahlar şaka bilmez. Yağmur mevsimlerinde turist yarıya iner; ama Büyük Göç gelince savana dolar. Oloololo Sky'ın sahibi Catherine Wanjiru burada otuz yıldır uçuyor; rakipler çabuk birleşir. Sabırlı ol evlat.",
  "Lande nicht zwischen den Herden: Die Ranger verhängen Strafen. Halte dich vom Mara-Fluss fern; Flusspferde und Krokodile verstehen keinen Spaß. In den Regenzeiten halbieren sich die Touristen, aber wenn die Große Migration kommt, füllt sich die Savanne. Catherine Wanjiru von Oloololo Sky fliegt hier seit dreißig Jahren; die Rivalen schließen sich schnell zusammen. Sei geduldig, Lehrling.",
  "No aterrices entre las manadas: los guardas ponen multas. Aléjate del río Mara; los hipopótamos y los cocodrilos no bromean. En las temporadas de lluvias los turistas bajan a la mitad, pero cuando llega la Gran Migración la sabana se llena. Catherine Wanjiru, de Oloololo Sky, vuela aquí desde hace treinta años; los rivales se unen rápido. Ten paciencia, aprendiz.",
  "群れの中に着陸するな。レンジャーに罰金を取られる。マラ川には近づくな。カバとワニは冗談が通じない。雨季には観光客が半分に減るが、大移動が来ればサバンナは満員になる。オロロロ・スカイのキャサリン・ワンジルはここで30年飛んでいて、ライバルたちはすぐ手を組む。辛抱するのだ、弟子よ。",
  "동물 무리 사이에 착륙하지 말게. 레인저들이 벌금을 매기네. 마라 강에는 가까이 가지 말게. 하마와 악어는 농담을 모르지. 우기에는 관광객이 절반으로 줄지만, 대이동이 오면 사바나가 가득 찬다네. 올로롤로 스카이의 캐서린 완지루는 여기서 30년째 날고 있고, 경쟁자들은 금세 손을 잡지. 인내하게, 제자여."))
add("hez.fiestaStarted.mara",
    "The Great Migration is here, my friend! Hundreds of thousands of wildebeest and zebras are pouring into the Mara from the Serengeti; for six days every camp is full. Get all your balloons up, but don't land among the herds.",
    "Büyük Göç geldi dostum! Serengeti'den yüz binlerce yaban öküzü ve zebra Mara'ya akıyor; altı gün boyunca bütün kamplar dolu. Bütün balonlarını havaya kaldır, ama sürülerin arasına inme.",
    "Die Große Migration ist da, mein Freund! Hunderttausende Gnus und Zebras strömen aus der Serengeti in die Mara; sechs Tage lang ist jedes Camp voll. Bring alle deine Ballons in die Luft, aber lande nicht zwischen den Herden.",
    "¡Ha llegado la Gran Migración, amigo! Cientos de miles de ñus y cebras llegan al Mara desde el Serengeti; durante seis días todos los campamentos están llenos. Sube todos tus globos, pero no aterrices entre las manadas.",
    "大移動が来たぞ、友よ！何十万頭ものヌーとシマウマがセレンゲティからマラへ流れ込んでいる。6日間、どのキャンプも満員だ。気球を全部上げろ。ただし群れの中には着陸するな。",
    "대이동이 왔네, 친구! 수십만 마리의 누와 얼룩말이 세렝게티에서 마라로 밀려들고 있어. 엿새 동안 모든 캠프가 꽉 찬다네. 열기구를 전부 띄우게. 하지만 무리 사이에는 착륙하지 말게.")
add("hez.rainsLong",
    "The long rains have begun, my friend! Days: %@. Tourists will be halved, most mornings will be red flags, and your camps will empty out. You still pay wages and upkeep. Keep spare balloons on the ground and protect your cash.",
    "Uzun yağmurlar başladı dostum! Süre: %@ gün. Turist yarı yarıya azalacak, sabahların çoğunda kırmızı bayrak olacak, kampların da boşalacak. Maaş ve bakım yine ödenir. Gereksiz balonları yerde tut, nakdini koru.",
    "Die langen Regen haben begonnen, mein Freund! Tage: %@. Die Touristen halbieren sich, an den meisten Morgen gibt es die rote Flagge, und deine Camps leeren sich. Löhne und Wartung zahlst du trotzdem. Lass überzählige Ballons am Boden und schone deine Kasse.",
    "¡Han empezado las lluvias largas, amigo! Días: %@. Los turistas bajarán a la mitad, casi todas las mañanas habrá bandera roja y tus campamentos se vaciarán. Los sueldos y el mantenimiento se pagan igual. Deja en tierra los globos que sobren y protege tu caja.",
    "大雨季が始まったぞ、友よ！日数：%@。観光客は半分に減り、ほとんどの朝は赤旗、キャンプも空になる。給料と整備費はそれでもかかる。余分な気球は地上に置き、資金を守れ。",
    "긴 우기가 시작됐네, 친구! 기간: %@일. 관광객은 절반으로 줄고, 대부분의 아침엔 빨간 깃발이 걸리고, 캠프도 텅 빌 걸세. 급여와 정비비는 그대로 나가네. 남는 열기구는 땅에 두고 현금을 지키게.")
add("hez.rainsShort",
    "The short rains have begun, my friend! Days: %@. Tourists will be halved, most mornings will be red flags, and your camps will empty out. You still pay wages and upkeep. Keep spare balloons on the ground and protect your cash.",
    "Kısa yağmurlar başladı dostum! Süre: %@ gün. Turist yarı yarıya azalacak, sabahların çoğunda kırmızı bayrak olacak, kampların da boşalacak. Maaş ve bakım yine ödenir. Gereksiz balonları yerde tut, nakdini koru.",
    "Die kurzen Regen haben begonnen, mein Freund! Tage: %@. Die Touristen halbieren sich, an den meisten Morgen gibt es die rote Flagge, und deine Camps leeren sich. Löhne und Wartung zahlst du trotzdem. Lass überzählige Ballons am Boden und schone deine Kasse.",
    "¡Han empezado las lluvias cortas, amigo! Días: %@. Los turistas bajarán a la mitad, casi todas las mañanas habrá bandera roja y tus campamentos se vaciarán. Los sueldos y el mantenimiento se pagan igual. Deja en tierra los globos que sobren y protege tu caja.",
    "小雨季が始まったぞ、友よ！日数：%@。観光客は半分に減り、ほとんどの朝は赤旗、キャンプも空になる。給料と整備費はそれでもかかる。余分な気球は地上に置き、資金を守れ。",
    "짧은 우기가 시작됐네, 친구! 기간: %@일. 관광객은 절반으로 줄고, 대부분의 아침엔 빨간 깃발이 걸리고, 캠프도 텅 빌 걸세. 급여와 정비비는 그대로 나가네. 남는 열기구는 땅에 두고 현금을 지키게.")
add("hez.rainsOver",
    "The rains are over, my friend! The savanna is green, the herds are back, and so are the tourists. You got through the rainy season.",
    "Yağmurlar dindi dostum! Savana yemyeşil, sürüler geri döndü, turistler de dönüyor. Yağmur mevsimini atlattın.",
    "Der Regen ist vorbei, mein Freund! Die Savanne ist grün, die Herden sind zurück, und die Touristen auch. Du hast die Regenzeit überstanden.",
    "¡Se acabaron las lluvias, amigo! La sabana está verde, las manadas han vuelto y los turistas también. Has superado la temporada de lluvias.",
    "雨季が終わったぞ、友よ！サバンナは緑一色、群れも戻り、観光客も戻ってくる。雨季を乗り切ったな。",
    "비가 그쳤네, 친구! 사바나는 푸르고, 무리도 돌아왔고, 관광객도 돌아오고 있네. 우기를 버텨 냈군.")

# ---- Home alerts ----
add("home.alert.fiesta.mara", "The Great Migration, day %1$@/%2$@!", "Büyük Göç, gün %1$@/%2$@!", "Die Große Migration, Tag %1$@/%2$@!",
    "¡La Gran Migración, día %1$@/%2$@!", "大移動、%1$@/%2$@日目！", "대이동, %1$@/%2$@일차!")
add("home.alert.fiesta.body.mara", "The savanna is full of herds and the camps are full. Get all your balloons up; don't land among the herds.",
    "Savana sürülerle dolu, kamplar dolu. Bütün balonlarını kaldır; sürülerin arasına inme.",
    "Die Savanne ist voller Herden, die Camps sind voll. Bring alle Ballons hoch; lande nicht zwischen den Herden.",
    "La sabana está llena de manadas y los campamentos, llenos. Sube todos tus globos; no aterrices entre las manadas.",
    "サバンナは群れでいっぱい、キャンプも満員。気球を全部上げよう。群れの中には着陸しないこと。",
    "사바나는 동물 무리로, 캠프는 손님으로 가득합니다. 열기구를 모두 띄우세요. 무리 사이에는 착륙하지 마세요.")
add("home.alert.fiestaSoon.mara", "Days until the Great Migration: %@.", "Büyük Göç'e kalan gün: %@.", "Tage bis zur Großen Migration: %@.",
    "Días hasta la Gran Migración: %@.", "大移動まであと%@日。", "대이동까지 남은 날: %@.")
add("home.alert.fiestaSoon.body.mara", "Get your fleet ready and sign deals with the camps.", "Filonu hazırla, kamplarla anlaş.",
    "Mach deine Flotte bereit und schließe Verträge mit den Camps.", "Prepara tu flota y cierra tratos con los campamentos.",
    "船団を準備して、キャンプと契約しよう。", "함대를 준비하고 캠프들과 계약하세요.")
add("home.alert.rainsLong", "Long rains, day %1$@/%2$@.", "Uzun yağmurlar, gün %1$@/%2$@.", "Lange Regen, Tag %1$@/%2$@.",
    "Lluvias largas, día %1$@/%2$@.", "大雨季、%1$@/%2$@日目。", "긴 우기, %1$@/%2$@일차.")
add("home.alert.rainsShort", "Short rains, day %1$@/%2$@.", "Kısa yağmurlar, gün %1$@/%2$@.", "Kurze Regen, Tag %1$@/%2$@.",
    "Lluvias cortas, día %1$@/%2$@.", "小雨季、%1$@/%2$@日目。", "짧은 우기, %1$@/%2$@일차.")
add("home.alert.rains.body", "Half as many tourists, and most mornings are red flags. Keep spare balloons on the ground.",
    "Turist yarı yarıya az, sabahların çoğu kırmızı bayrak. Gereksiz balonları yerde tut.",
    "Halb so viele Touristen, und an den meisten Morgen gilt die rote Flagge. Lass überzählige Ballons am Boden.",
    "La mitad de turistas y casi todas las mañanas con bandera roja. Deja en tierra los globos que sobren.",
    "観光客は半分、ほとんどの朝は赤旗。余分な気球は地上に置いておこう。",
    "관광객은 절반, 대부분의 아침엔 빨간 깃발. 남는 열기구는 땅에 두세요.")
add("home.rains", "Rains: fewer tourists", "Yağmurlar: turist az", "Regenzeit: weniger Touristen", "Lluvias: menos turistas", "雨季：観光客が少ない", "우기: 관광객 감소")
add("why.winter.mara", "Rainy season", "Yağmur mevsimi", "Regenzeit", "Temporada de lluvias", "雨季", "우기")
add("why.fiesta.mara", "Great Migration", "Büyük Göç", "Große Migration", "Gran Migración", "大移動", "대이동")

# ---- The newspaper and the nights ----
add("paper.mast.mara", "Mara Habari", "Mara Habari", "Mara Habari", "Mara Habari", "マラ・ハバリ", "마라 하바리")
add("paper.price.mara", "30 shillings", "30 şilin", "30 Schilling", "30 chelines", "30シリング", "30실링")
add("paper.migration", "The Great Migration reaches the Mara", "Büyük Göç Mara'da", "Die Große Migration erreicht die Mara",
    "La Gran Migración llega al Mara", "大移動、マラに到達", "대이동, 마라에 도착")
add("paper.migration.sub", "Wildebeest are crossing the river; the lodges are full and safari planes land every hour.",
    "Yaban öküzleri nehri geçiyor; lodge'lar dolu, safari uçakları her saat iniyor.",
    "Gnus durchqueren den Fluss; die Lodges sind voll, und stündlich landen Safariflugzeuge.",
    "Los ñus cruzan el río; los lodges están llenos y las avionetas de safari aterrizan cada hora.",
    "ヌーが川を渡っている。ロッジは満室、サファリ機が毎時着陸している。",
    "누 떼가 강을 건너고 있다. 로지는 만실이고, 사파리 비행기가 매시간 착륙한다.")
add("paper.herdLanding", "%@ lands among a herd", "Bir balon sürünün arasına indi: %@", "%@ landet zwischen einer Herde",
    "%@ aterriza entre una manada", "%@、群れの中に着陸", "%@, 동물 무리 사이에 착륙")
add("paper.herdLanding.sub", "The reserve's rangers fined the company. Fine: %@.", "Koruma alanının korucuları şirkete ceza kesti. Ceza: %@.",
    "Die Ranger des Schutzgebiets haben die Firma bestraft. Strafe: %@.", "Los guardas de la reserva multaron a la empresa. Multa: %@.",
    "保護区のレンジャーが会社に罰金を科した。罰金：%@。", "보호구역 레인저들이 회사에 벌금을 부과했다. 벌금: %@.")
add("paper.riverLanding", "%@ balloon lands in the Mara River", "Mara Nehri'ne bir balon indi: %@", "Ballon von %@ landet im Mara-Fluss",
    "Un globo de %@ cae en el río Mara", "%@の気球、マラ川に着水", "%@ 열기구, 마라 강에 착수")
add("paper.riverLanding.sub", "Frightening moments in the river of hippos and crocodiles; the passengers were helped ashore with difficulty.",
    "Su aygırlarının ve timsahların nehrinde korkulu anlar; yolcular kıyıya güçlükle çıkarıldı.",
    "Bange Momente im Fluss der Flusspferde und Krokodile; die Passagiere wurden mit Mühe ans Ufer gebracht.",
    "Momentos de miedo en el río de hipopótamos y cocodrilos; los pasajeros llegaron a la orilla con dificultad.",
    "カバとワニの川で恐怖の瞬間。乗客はやっとのことで岸に引き上げられた。",
    "하마와 악어의 강에서 아찔한 순간. 승객들은 간신히 강가로 구조되었다.")
add("night.migration", "Migration night: thousands of wildebeest on the savanna, the camp fires burning.",
    "Göç gecesi: savanada binlerce yaban öküzü, kampta ateşler yanıyor.",
    "Migrationsnacht: Tausende Gnus in der Savanne, die Lagerfeuer brennen.",
    "Noche de migración: miles de ñus en la sabana y las hogueras del campamento encendidas.",
    "大移動の夜。サバンナには何千頭ものヌー、キャンプでは焚き火が燃えている。",
    "대이동의 밤: 사바나에 수천 마리의 누, 캠프엔 모닥불이 타오른다.")
add("paper.night.migration", "Migration night on the savanna", "Savanada göç gecesi", "Migrationsnacht in der Savanne",
    "Noche de migración en la sabana", "サバンナの大移動の夜", "사바나의 대이동의 밤")
add("paper.night.migration.sub", "By the light of the camp fires, the sound of the wildebeest went on all night.",
    "Kamp ateşlerinin ışığında yaban öküzlerinin sesi bütün gece sürdü.",
    "Im Schein der Lagerfeuer waren die Gnus die ganze Nacht zu hören.",
    "A la luz de las hogueras, el sonido de los ñus duró toda la noche.",
    "キャンプの焚き火の明かりの中、ヌーの声が一晩中続いた。",
    "모닥불 빛 아래, 누 떼의 소리가 밤새 이어졌다.")
add("night.rain", "A rainy night: the sound of rain on the tents.", "Yağmur gecesi: çadırların üstünde yağmurun sesi.",
    "Eine Regennacht: das Prasseln des Regens auf den Zelten.", "Una noche de lluvia: el sonido de la lluvia sobre las tiendas.",
    "雨の夜。テントを打つ雨の音。", "비 오는 밤: 텐트 위로 떨어지는 빗소리.")
add("paper.night.rain", "A rainy night on the savanna", "Savanada yağmur gecesi", "Regennacht in der Savanne",
    "Noche de lluvia en la sabana", "サバンナの雨の夜", "사바나의 비 오는 밤")
add("paper.night.rain.sub", "The camps' lanterns flickered behind the rain; by morning the savanna will be green.",
    "Kampların fenerleri yağmurun ardında titreşti; sabah savana yemyeşil olacak.",
    "Die Laternen der Camps flackerten hinter dem Regen; am Morgen wird die Savanne grün sein.",
    "Los faroles de los campamentos titilaron tras la lluvia; por la mañana la sabana estará verde.",
    "雨の向こうでキャンプのランタンが揺らめいた。朝にはサバンナが緑になるだろう。",
    "빗줄기 너머로 캠프의 등불이 깜박였다. 아침이면 사바나가 푸르게 변할 것이다.")

# ---- Flight: the herds, the river, the obstacles ----
add("flight.tip.herd", "**You're over a herd!** Don't land here: the rangers will fine you. Land once you're past the animals.",
    "**Sürünün üstündesin!** Buraya inme: korucular ceza keser. Hayvanları geçince in.",
    "**Du bist über einer Herde!** Lande hier nicht: Die Ranger verhängen eine Strafe. Lande erst hinter den Tieren.",
    "**¡Estás sobre una manada!** No aterrices aquí: los guardas te multarán. Aterriza cuando hayas pasado a los animales.",
    "**群れの上にいる！**ここに着陸するな。レンジャーに罰金を取られる。動物を越えてから着陸しよう。",
    "**동물 무리 위에 있습니다!** 여기 착륙하지 마세요. 레인저가 벌금을 매깁니다. 동물들을 지나서 착륙하세요.")
add("flight.tip.river", "**The Mara River!** Hippos and crocodiles: never land in the river or on its banks. Climb and cross it.",
    "**Mara Nehri!** Su aygırları ve timsahlar: nehre ve kıyısına asla inme. Yüksel ve geç.",
    "**Der Mara-Fluss!** Flusspferde und Krokodile: Lande nie im Fluss oder an seinen Ufern. Steig und überquere ihn.",
    "**¡El río Mara!** Hipopótamos y cocodrilos: nunca aterrices en el río ni en sus orillas. Sube y crúzalo.",
    "**マラ川だ！**カバとワニがいる。川にも岸にも絶対に着陸するな。上昇して越えよう。",
    "**마라 강입니다!** 하마와 악어가 있습니다. 강이나 강가에 절대 착륙하지 마세요. 상승해서 건너세요.")
add("flight.hit.acacia", "**You hit an acacia!** The balloon is badly damaged and passengers are injured.",
    "**Akasya ağacına çarptın!** Balon ağır hasar gördü, yolcular yaralandı.",
    "**Du bist in eine Akazie gekracht!** Der Ballon ist schwer beschädigt, Passagiere sind verletzt.",
    "**¡Chocaste contra una acacia!** El globo está muy dañado y hay pasajeros heridos.",
    "**アカシアに衝突した！** 気球は大破し、乗客が負傷した。",
    "**아카시아에 부딪혔습니다!** 열기구가 크게 파손되고 승객들이 다쳤습니다.")
add("flight.hit.kopje", "**You hit a rocky kopje!** The balloon is badly damaged and passengers are injured.",
    "**Kayalık tepeye çarptın!** Balon ağır hasar gördü, yolcular yaralandı.",
    "**Du bist gegen einen Felshügel gekracht!** Der Ballon ist schwer beschädigt, Passagiere sind verletzt.",
    "**¡Chocaste contra un kopje rocoso!** El globo está muy dañado y hay pasajeros heridos.",
    "**岩山に衝突した！** 気球は大破し、乗客が負傷した。",
    "**바위 언덕에 부딪혔습니다!** 열기구가 크게 파손되고 승객들이 다쳤습니다.")
add("flight.hit.river", "**You came down in the Mara River!** The basket tipped into the water; the passengers were pulled out among the hippos.",
    "**Mara Nehri'ne indin!** Sepet suya devrildi, yolcular su aygırlarının arasından kıyıya çıkarıldı.",
    "**Du bist im Mara-Fluss gelandet!** Der Korb kippte ins Wasser; die Passagiere wurden zwischen den Flusspferden herausgezogen.",
    "**¡Caíste en el río Mara!** La cesta volcó en el agua; sacaron a los pasajeros entre los hipopótamos.",
    "**マラ川に着水した！** バスケットは水中に倒れ、乗客はカバの間から引き上げられた。",
    "**마라 강에 떨어졌습니다!** 바스켓이 물속으로 넘어졌고, 승객들은 하마들 사이에서 구조되었습니다.")
HERDS = {
    "gnu": ("wildebeest", "yaban öküzlerinin", "Gnus", "ñus", "ヌー", "누"),
    "zebra": ("zebras", "zebraların", "Zebras", "cebras", "シマウマ", "얼룩말"),
    "elephant": ("elephants", "fillerin", "Elefanten", "elefantes", "ゾウ", "코끼리"),
    "giraffe": ("giraffes", "zürafaların", "Giraffen", "jirafas", "キリン", "기린"),
}
for k, (en, tr, de, es, ja, ko) in HERDS.items():
    add(f"flight.land.herd.{k}", f"**You landed among the {en}!** The rangers are coming; they'll fine you.",
        f"**{tr.capitalize()} arasına indin!** Korucular geliyor; ceza kesecekler.",
        f"**Du bist zwischen den {de} gelandet!** Die Ranger kommen; sie werden dich bestrafen.",
        f"**¡Aterrizaste entre los {es}!** Vienen los guardas; te pondrán una multa." if k in ("gnu", "elephant") else
        f"**¡Aterrizaste entre las {es}!** Vienen los guardas; te pondrán una multa.",
        f"**{ja}の群れの中に着陸した！**レンジャーが来る。罰金を取られるだろう。",
        f"**{ko} 무리 사이에 착륙했습니다!** 레인저들이 오고 있습니다. 벌금을 매길 겁니다.")
    add(f"event.herdLanding.{k}", f"You landed among the {en}. The rangers fined you; the animals were startled, and so were the passengers. Fine: %@.",
        f"{tr.capitalize()} arasına indin. Korucular ceza kesti; hayvanlar ürktü, yolcular da. Ceza: %@.",
        f"Du bist zwischen den {de} gelandet. Die Ranger haben dich bestraft; die Tiere sind erschrocken, die Passagiere auch. Strafe: %@.",
        (f"Aterrizaste entre los {es}." if k in ("gnu", "elephant") else f"Aterrizaste entre las {es}.") +
        " Los guardas te multaron; los animales se asustaron, y los pasajeros también. Multa: %@.",
        f"{ja}の群れの中に着陸した。レンジャーに罰金を科された。動物も乗客も驚いた。罰金：%@。",
        f"{ko} 무리 사이에 착륙했습니다. 레인저들이 벌금을 매겼고, 동물도 승객도 놀랐습니다. 벌금: %@.")
add("flight.land.river", "**Hippos and crocodiles!** The passengers were helped ashore with difficulty.",
    "**Su aygırları ve timsahlar!** Yolcular kıyıya güçlükle çıkarıldı.",
    "**Flusspferde und Krokodile!** Die Passagiere wurden mit Mühe ans Ufer gebracht.",
    "**¡Hipopótamos y cocodrilos!** Los pasajeros llegaron a la orilla con dificultad.",
    "**カバとワニだ！**乗客はやっとのことで岸に上がった。",
    "**하마와 악어!** 승객들은 간신히 강가로 올라왔습니다.")
add("event.riverLanding", "You came down in the Mara River! The basket tipped into the water and the passengers were pulled ashore among the hippos.",
    "Mara Nehri'ne indin! Sepet suya devrildi, yolcular su aygırlarının arasından kıyıya çıkarıldı.",
    "Du bist im Mara-Fluss gelandet! Der Korb kippte ins Wasser, und die Passagiere wurden zwischen den Flusspferden ans Ufer gezogen.",
    "¡Caíste en el río Mara! La cesta volcó en el agua y sacaron a los pasajeros a la orilla entre los hipopótamos.",
    "マラ川に着水した！バスケットは水中に倒れ、乗客はカバの間から岸へ引き上げられた。",
    "마라 강에 떨어졌습니다! 바스켓이 물속으로 넘어졌고, 승객들은 하마들 사이에서 강가로 구조되었습니다.")
add("repWhy.herd", "Wildlife violation", "Yaban hayatı ihlali", "Verstoß gegen den Wildschutz", "Infracción contra la fauna", "野生動物保護違反", "야생동물 보호 위반")
add("ledger.park", "Reserve fee", "Koruma alanı ücreti", "Schutzgebietsgebühr", "Tasa de la reserva", "保護区の料金", "보호구역 요금")

# ---- Reviews ----
add("review.herd.0", "The balloon came down next to a herd of zebras and the animals ran in every direction. The rangers were not pleased at all.",
    "Balon bir zebra sürüsünün yanına indi, hayvanlar dört bir yana kaçtı. Korucular hiç memnun değildi.",
    "Der Ballon landete neben einer Zebraherde, und die Tiere stoben in alle Richtungen davon. Die Ranger waren gar nicht erfreut.",
    "El globo bajó junto a una manada de cebras y los animales huyeron en todas direcciones. Los guardas no estaban nada contentos.",
    "気球がシマウマの群れのそばに着陸して、動物たちは四方八方へ逃げた。レンジャーはまったく喜んでいなかった。",
    "열기구가 얼룩말 무리 옆에 내려앉자 동물들이 사방으로 달아났다. 레인저들은 전혀 달가워하지 않았다.")
add("review.herd.1", "The flight was wonderful, but we startled the elephants when we landed. Our guide was embarrassed, and so were we.",
    "Uçuş harikaydı ama inişte filleri ürkettik. Rehberimiz utandı, biz de.",
    "Der Flug war wunderbar, aber bei der Landung haben wir die Elefanten erschreckt. Unserem Guide war das peinlich, uns auch.",
    "El vuelo fue maravilloso, pero al aterrizar asustamos a los elefantes. Nuestro guía pasó vergüenza, y nosotros también.",
    "フライトは最高だったけど、着陸でゾウを驚かせてしまった。ガイドは恥ずかしがっていたし、私たちもそう。",
    "비행은 훌륭했지만 착륙할 때 코끼리들을 놀라게 했다. 가이드도 민망해했고, 우리도 그랬다.")
add("review.river.0", "The balloon came down in the Mara River! We were pulled ashore among the hippos. Never again.",
    "Balon Mara Nehri'ne indi! Su aygırlarının arasından kıyıya çıkarıldık. Bir daha asla.",
    "Der Ballon landete im Mara-Fluss! Man zog uns zwischen den Flusspferden ans Ufer. Nie wieder.",
    "¡El globo cayó en el río Mara! Nos sacaron a la orilla entre los hipopótamos. Nunca más.",
    "気球がマラ川に落ちた！カバの間から岸へ引き上げられた。二度とごめんだ。",
    "열기구가 마라 강에 떨어졌다! 하마들 사이에서 강가로 끌려 나왔다. 다시는 안 탄다.")
add("review.river.1", "We landed on the riverbank; after we saw the crocodiles, nobody wanted breakfast.",
    "Nehrin kıyısına indik; timsahları gördükten sonra kimse kahvaltı istemedi.",
    "Wir landeten am Flussufer; nachdem wir die Krokodile gesehen hatten, wollte niemand mehr frühstücken.",
    "Aterrizamos en la orilla del río; después de ver a los cocodrilos, nadie quiso desayunar.",
    "川岸に着陸した。ワニを見たあとでは、誰も朝食を欲しがらなかった。",
    "강가에 착륙했다. 악어를 본 뒤로는 아무도 아침을 먹고 싶어 하지 않았다.")
add("review.perfect.1.mara", "Sunrise over the savanna, giraffes below us and a perfect landing. The morning of my life.",
    "Savanada gün doğumu, altımızda zürafalar ve kusursuz bir iniş. Hayatımın sabahıydı.",
    "Sonnenaufgang über der Savanne, Giraffen unter uns und eine perfekte Landung. Der Morgen meines Lebens.",
    "Amanecer sobre la sabana, jirafas debajo de nosotros y un aterrizaje perfecto. La mañana de mi vida.",
    "サバンナの日の出、眼下にはキリン、そして完璧な着陸。人生最高の朝だった。",
    "사바나의 일출, 발아래 기린들, 그리고 완벽한 착륙. 내 인생의 아침이었다.")
add("review.crash.0.mara", "We crashed into an acacia! Everyone's fine, but this is unacceptable.",
    "Akasya ağacına çarptık! Herkes iyi ama bu kabul edilemez.",
    "Wir sind in eine Akazie gekracht! Allen geht es gut, aber das ist inakzeptabel.",
    "¡Chocamos contra una acacia! Todos estamos bien, pero esto es inaceptable.",
    "アカシアに衝突した！みんな無事だけど、これはありえない。",
    "아카시아에 부딪혔다! 모두 무사하지만 이건 용납할 수 없다.")
add("review.cheap.1.mara", "I paid {p}, maybe the best price in the Mara.", "{p} ödedim, Mara'nın en iyi fiyatı bu olabilir.",
    "Ich habe {p} bezahlt, vielleicht der beste Preis in der Mara.", "Pagué {p}, quizá el mejor precio del Mara.",
    "{p}払った。マラで一番お得な値段かもしれない。", "{p} 냈다. 마라에서 가장 좋은 가격일지도.")
add("review.general.0.mara", "You can't come to the Mara and not go on a balloon safari. This team is very professional.",
    "Mara'ya gelip balon safarisine çıkmamak olmaz. Bu ekip çok profesyonel.",
    "Man kann nicht in die Mara kommen, ohne eine Ballonsafari zu machen. Dieses Team ist sehr professionell.",
    "No puedes venir al Mara y no hacer un safari en globo. Este equipo es muy profesional.",
    "マラに来て気球サファリをしないなんてありえない。このチームはとてもプロフェッショナルだ。",
    "마라에 와서 열기구 사파리를 안 하면 안 된다. 이 팀은 아주 프로답다.")
add("review.general.1.mara", "We watched the Great Migration from above: thousands of wildebeest streaming toward the river. Unforgettable.",
    "Büyük Göç'ü yukarıdan izledik: binlerce yaban öküzü nehre doğru akıyordu. Unutulmaz.",
    "Wir haben die Große Migration von oben gesehen: Tausende Gnus strömten zum Fluss. Unvergesslich.",
    "Vimos la Gran Migración desde arriba: miles de ñus corriendo hacia el río. Inolvidable.",
    "大移動を上から見た。何千頭ものヌーが川へ向かって流れていた。忘れられない。",
    "대이동을 위에서 봤다. 수천 마리의 누가 강을 향해 흘러가고 있었다. 잊을 수 없다.")
add("review.panorama.0.mara", "Our photographer loved the shot from 550 meters. The savanna lay at our feet from the Oloololo Escarpment to the horizon.",
    "Fotoğrafçımız 550 metreden çektiği kareye bayıldı. Oloololo Sırtı'ndan ufka kadar savana ayaklarımızın altındaydı.",
    "Unser Fotograf liebte das Bild aus 550 Metern. Vom Oloololo-Steilhang bis zum Horizont lag uns die Savanne zu Füßen.",
    "A nuestro fotógrafo le encantó la foto desde 550 metros. La sabana estaba a nuestros pies, desde el escarpe de Oloololo hasta el horizonte.",
    "カメラマンは高度550mから撮った一枚に大喜び。オロロロ断崖から地平線まで、サバンナが足もとに広がっていた。",
    "사진작가는 550미터에서 찍은 사진에 반했다. 올로롤로 절벽부터 지평선까지 사바나가 발아래 펼쳐져 있었다.")
add("review.valley.0.mara", "We glided low over the Mara River, and the hippos raised their heads to look at us!",
    "Mara Nehri'nin üstünden alçaktan süzüldük, su aygırları başlarını kaldırıp bize baktı!",
    "Wir glitten tief über den Mara-Fluss, und die Flusspferde hoben die Köpfe, um uns anzusehen!",
    "¡Planeamos bajo sobre el río Mara y los hipopótamos levantaron la cabeza para mirarnos!",
    "マラ川の上を低く滑空したら、カバが顔を上げてこちらを見た！",
    "마라 강 위를 낮게 미끄러지듯 날았더니 하마들이 고개를 들어 우리를 쳐다봤다!")
add("review.valley.1.mara", "The low flight over the river was incredible; a crocodile was sunning itself on the bank.",
    "Nehrin üstünde alçak uçuş inanılmazdı; kıyıda bir timsah güneşleniyordu.",
    "Der Tiefflug über dem Fluss war unglaublich; am Ufer sonnte sich ein Krokodil.",
    "El vuelo bajo sobre el río fue increíble; un cocodrilo tomaba el sol en la orilla.",
    "川の上の低空飛行は最高だった。岸ではワニが日なたぼっこをしていた。",
    "강 위의 저공비행은 믿을 수 없을 정도였다. 강가에서는 악어가 햇볕을 쬐고 있었다.")
add("review.xl.2.mara", "We saw the Star of the Mara from our camp and booked. No regrets.",
    "Mara Yıldızı'nı kamptan görüp rezervasyon yaptık, pişman değiliz.",
    "Wir haben den Stern der Mara von unserem Camp aus gesehen und gebucht. Keine Reue.",
    "Vimos la Estrella del Mara desde el campamento y reservamos. Sin arrepentimientos.",
    "キャンプからマラの星が見えて予約した。後悔なし。",
    "캠프에서 마라의 별을 보고 예약했다. 후회 없다.")

# ---- The Hot Air Foundation's projects in the Mara ----
FDN = [
    ("A school for the villages of the reserve", "Koruma alanının köylerine bir okul", "Eine Schule für die Dörfer des Schutzgebiets",
     "Una escuela para las aldeas de la reserva", "保護区の村々のための学校", "보호구역 마을들을 위한 학교"),
    ("Off-road vehicles and radios for the rangers", "Korucular için arazi araçları ve telsizler", "Geländewagen und Funkgeräte für die Ranger",
     "Todoterrenos y radios para los guardas", "レンジャーのためのオフロード車と無線機", "레인저를 위한 오프로드 차량과 무전기"),
    ("Clean water wells for the villages along the Talek", "Talek kıyısındaki köylere temiz su kuyuları", "Brunnen mit sauberem Wasser für die Dörfer am Talek",
     "Pozos de agua limpia para las aldeas junto al Talek", "タレク川沿いの村々にきれいな水の井戸", "탈렉 강변 마을들을 위한 깨끗한 우물"),
    ("A workshop for the Maasai women's beadwork cooperative", "Maasai kadınlarının boncuk kooperatifine atölye", "Eine Werkstatt für die Perlen-Kooperative der Maasai-Frauen",
     "Un taller para la cooperativa de abalorios de las mujeres masái", "マサイの女性たちのビーズ協同組合に工房", "마사이 여성 구슬공예 협동조합을 위한 작업장"),
    ("Safari guide scholarships for young people", "Gençlere safari rehberliği bursu", "Stipendien zur Safari-Guide-Ausbildung für junge Leute",
     "Becas de guía de safari para jóvenes", "若者へのサファリガイド奨学金", "청년들을 위한 사파리 가이드 장학금"),
]
for i, t in enumerate(FDN):
    add(f"fdn.mara.{i}", *t)

# ---- Offices: Paris became London; they open with their regions ----
add("holding.officeLocked", "Locked. Enter this region first to open it: %@", "Kilitli. Açmak için önce bu bölgeye gir: %@",
    "Gesperrt. Betritt zuerst diese Region, um es zu eröffnen: %@", "Bloqueada. Para abrirla, entra antes en esta región: %@",
    "ロック中。開くには先にこの地域へ進出しよう：%@", "잠김. 열려면 먼저 이 지역에 진출하세요: %@")
add("holding.officesNeedRegions", "Some offices open only once you've entered their region.",
    "Bazı ofisler ancak bölgelerine girince açılır.",
    "Manche Büros lassen sich erst eröffnen, wenn du ihre Region betreten hast.",
    "Algunas oficinas solo se abren cuando has entrado en su región.",
    "一部のオフィスは、その地域に進出してからでないと開けない。",
    "일부 사무소는 해당 지역에 진출해야만 열 수 있습니다.")

# ---- Contracts: the airstrip, the scene ----
add("paper.rivalGroup.sub.bush", "%1$@ safari plane guests in the baskets of %2$@.", "%1$@ safari uçağı misafiri %2$@ sepetlerinde.",
    "%1$@ Safariflug-Gäste in den Körben von %2$@.", "%1$@ huéspedes de avioneta safari en las cestas de %2$@.",
    "%2$@のバスケットにサファリ機の客%1$@人。", "%2$@의 바스켓에 사파리 비행기 손님 %1$@명.")
add("ctr.mara.tag", "Safari plane group offer", "Safari uçağı grubu teklifi", "Angebot: Safariflug-Gruppe", "Oferta de grupo de avioneta safari",
    "サファリ機グループの依頼", "사파리 비행기 단체 제안")
add("ctr.mara.place", "TALEK AIRSTRIP", "TALEK AIRSTRIP", "TALEK AIRSTRIP", "TALEK AIRSTRIP", "TALEK AIRSTRIP", "TALEK AIRSTRIP")
add("ctr.mara.accepted", "Wonderful! My planes land on the strip that morning and my guests take the jeeps. Get the baskets ready!",
    "Harika! Uçaklarım o sabah piste iner, misafirlerim cipe biner. Sepetleri hazırla!",
    "Wunderbar! Meine Flugzeuge landen an dem Morgen auf der Piste, und meine Gäste steigen in die Jeeps. Mach die Körbe bereit!",
    "¡Estupendo! Mis aviones aterrizan en la pista esa mañana y mis huéspedes suben a los jeeps. ¡Prepara las cestas!",
    "よかった！その朝、私の飛行機が滑走路に着いて、お客さんはジープに乗ります。バスケットを準備して！",
    "좋아요! 그날 아침 내 비행기가 활주로에 내리고, 손님들은 지프에 타요. 바스켓을 준비해 줘요!")
add("ctr.mara.where", "The planes wait at the dirt airstrip on the savanna for the whole booking; drag the town to the right, along the east road, to see it. Have enough balloons ready to fly every morning.",
    "Uçaklar anlaşma boyunca savanadaki toprak pistte bekleyecek; kasabayı sağa, doğu yolu boyunca kaydırırsan görürsün. Her sabah yeterli balonun uçmaya hazır olsun.",
    "Die Flugzeuge warten während der ganzen Buchung auf der Schotterpiste in der Savanne; zieh die Stadt nach rechts, entlang der Ostroute, um sie zu sehen. Halte jeden Morgen genug Ballons flugbereit.",
    "Los aviones esperan en la pista de tierra de la sabana durante toda la reserva; arrastra el pueblo a la derecha, por el camino del este, para verla. Ten listos suficientes globos cada mañana.",
    "飛行機は予約の間ずっとサバンナの未舗装滑走路で待っている。町を右へ、東の道に沿ってドラッグすると見える。毎朝、十分な気球を飛べる状態にしておこう。",
    "비행기는 예약 기간 내내 사바나의 흙 활주로에서 기다립니다. 마을을 오른쪽으로, 동쪽 길을 따라 끌면 보입니다. 매일 아침 충분한 열기구를 띄울 준비를 해 두세요.")
add("ctr.mara.empty", "The airstrip is empty. A new safari plane offer comes in the morning.", "Pist boş. Yeni bir safari uçağı teklifi sabah gelir.",
    "Die Piste ist leer. Ein neues Safariflug-Angebot kommt am Morgen.", "La pista está vacía. Mañana por la mañana llega una nueva oferta de avioneta safari.",
    "滑走路は空っぽ。新しいサファリ機の依頼は朝に届く。", "활주로가 비어 있습니다. 새 사파리 비행기 제안은 아침에 옵니다.")
add("ctr.mara.fresh", "Small safari planes from Nairobi land on this dirt strip; the lodge guests take the jeeps to camp.",
    "Nairobi'den gelen küçük safari uçakları bu toprak piste iner, lodge misafirleri cipe binip kampa gelir.",
    "Kleine Safariflugzeuge aus Nairobi landen auf dieser Schotterpiste; die Lodge-Gäste fahren mit den Jeeps ins Camp.",
    "Las pequeñas avionetas de safari de Nairobi aterrizan en esta pista de tierra; los huéspedes de los lodges van al campamento en jeep.",
    "ナイロビからの小さなサファリ機がこの未舗装の滑走路に着陸し、ロッジの客はジープでキャンプへ向かう。",
    "나이로비에서 온 작은 사파리 비행기가 이 흙 활주로에 내리고, 로지 손님들은 지프를 타고 캠프로 옵니다.")
add("ctr.mara.prefPaper", "The safari planes now come to them first.", "Safari uçakları artık önce ona geliyor.",
    "Die Safariflugzeuge kommen jetzt zuerst zu ihnen.", "Las avionetas de safari ahora acuden primero a ellos.",
    "サファリ機は今やまずそこへ来る。", "이제 사파리 비행기들이 먼저 그곳으로 간다.")
SCENE = [
    ("Look, my friend: the dirt airstrip on the savanna. Little propeller planes from Nairobi bring the lodge guests here.",
     "Bak dostum: savanadaki toprak pist. Nairobi'den küçük pervaneli uçaklar lodge misafirlerini buraya getirir.",
     "Schau, mein Freund: die Schotterpiste in der Savanne. Kleine Propellerflugzeuge aus Nairobi bringen die Lodge-Gäste hierher.",
     "Mira, amigo: la pista de tierra de la sabana. Pequeñas avionetas de hélice traen aquí a los huéspedes de los lodges desde Nairobi.",
     "見ろ、友よ。サバンナの未舗装滑走路だ。ナイロビから小さなプロペラ機がロッジの客をここへ運んでくる。",
     "보게, 친구. 사바나의 흙 활주로라네. 나이로비에서 작은 프로펠러 비행기가 로지 손님들을 여기로 데려오지."),
    ("The guests step off the plane, take the jeeps and come along the dirt road to camp. The first offer is coming!",
     "Misafirler uçaktan inip cipe biner, toprak yoldan kampa gelir. İlk teklif geliyor!",
     "Die Gäste steigen aus dem Flugzeug in die Jeeps und kommen über die Schotterstraße ins Camp. Das erste Angebot kommt!",
     "Los huéspedes bajan del avión, suben a los jeeps y llegan al campamento por el camino de tierra. ¡Ya llega la primera oferta!",
     "客は飛行機を降りてジープに乗り、土の道を通ってキャンプへ来る。最初の依頼が来るぞ！",
     "손님들은 비행기에서 내려 지프를 타고 흙길을 따라 캠프로 온다네. 첫 제안이 오고 있네!"),
    ("A group flies two or three mornings; on those mornings the seats go to the group first. Turn it down and a rival grabs the group.",
     "Grup iki ya da üç sabah uçar; o sabahlar koltuklar önce gruba gider. Reddedersen grubu bir rakip kapar.",
     "Eine Gruppe fliegt an zwei oder drei Morgen; an diesen Morgen gehen die Plätze zuerst an die Gruppe. Lehnst du ab, schnappt sie sich ein Rivale.",
     "Un grupo vuela dos o tres mañanas; esas mañanas los asientos son primero para el grupo. Si lo rechazas, un rival se lo queda.",
     "グループは2〜3回の朝に飛ぶ。その朝は座席がまずグループに回る。断ればライバルが持っていく。",
     "단체는 이틀이나 사흘 아침을 난다네. 그 아침에는 좌석이 먼저 단체에 돌아가지. 거절하면 경쟁자가 단체를 가져간다네."),
    ("Deliver three jobs well and you become their preferred partner; they'll come more often. Pole pole, my friend.",
     "Üç işi sağlam teslim edersen gözde ortakları olursun, daha sık gelirler. Pole pole, dostum.",
     "Erledige drei Aufträge gut, dann wirst du ihr bevorzugter Partner und sie kommen öfter. Pole pole, mein Freund.",
     "Cumple bien tres trabajos y serás su socio preferido; vendrán más a menudo. Pole pole, amigo.",
     "3つの仕事をしっかりこなせば、お気に入りのパートナーになり、もっと頻繁に来てくれる。ポレポレ、友よ。",
     "세 건을 잘 해내면 선호 파트너가 되어 더 자주 올 걸세. 폴레 폴레, 친구."),
]
for i, t in enumerate(SCENE):
    add(f"ctr.mara.scene.{i}", *t)
add("ctr.mara.delayIntro",
    "Planes are sometimes late here, my friend: storms over the Rift Valley, zebras grazing on the strip. In the morning it's your call: keep the seats for the group, or put them on the market. Both have a price; it's on the card.",
    "Burada uçaklar bazen gecikir dostum: Rift Vadisi'nde fırtına olur, pistte zebralar otlar. Sabah karar senin: koltukları gruba beklet ya da pazara aç. İkisinin de bedeli var; kartta yazıyor.",
    "Hier verspäten sich die Flugzeuge manchmal, mein Freund: Gewitter über dem Rift Valley, Zebras, die auf der Piste grasen. Am Morgen entscheidest du: die Plätze für die Gruppe freihalten oder sie verkaufen. Beides hat seinen Preis; er steht auf der Karte.",
    "Aquí los aviones a veces se retrasan, amigo: tormentas sobre el valle del Rift, cebras pastando en la pista. Por la mañana decides tú: guardar los asientos para el grupo o ponerlos a la venta. Ambas cosas tienen un precio; está en la tarjeta.",
    "ここでは飛行機が遅れることがあるのだ、友よ。大地溝帯の嵐、滑走路で草を食むシマウマ。朝に決めるのはおまえだ。座席をグループのために取っておくか、売りに出すか。どちらにも代償があり、カードに書いてある。",
    "여기선 비행기가 가끔 늦는다네, 친구. 리프트 밸리의 폭풍, 활주로에서 풀을 뜯는 얼룩말 때문이지. 아침에 결정은 자네 몫이네. 좌석을 단체를 위해 비워 둘지, 시장에 내놓을지. 둘 다 대가가 있고, 카드에 적혀 있다네.")

# ---- The Grand Tour now names its regions ----
add("store.lead.worldTour",
    "Beyond Cappadocia: Albuquerque in America, Luxor in Egypt, Bristol in England and the Maasai Mara in Kenya. The in-game entry fee is still paid from the holding.",
    "Kapadokya'nın ötesi: Amerika'da Albuquerque, Mısır'da Luksor, İngiltere'de Bristol ve Kenya'da Maasai Mara. Bölgelere girişin oyun içi bedeli yine holding kasasından ödenir.",
    "Jenseits von Kappadokien: Albuquerque in Amerika, Luxor in Ägypten, Bristol in England und die Maasai Mara in Kenia. Die Einstiegsgebühr im Spiel zahlt weiterhin die Holding.",
    "Más allá de Capadocia: Albuquerque en Estados Unidos, Luxor en Egipto, Bristol en Inglaterra y el Maasai Mara en Kenia. La cuota de entrada del juego se sigue pagando desde el holding.",
    "カッパドキアの先へ。アメリカのアルバカーキ、エジプトのルクソール、イギリスのブリストル、ケニアのマサイマラ。ゲーム内の参入費はこれまで通りホールディングスから支払う。",
    "카파도키아 너머로: 미국의 앨버커키, 이집트의 룩소르, 영국의 브리스톨, 케냐의 마사이마라. 게임 내 진입 비용은 여전히 지주회사가 냅니다.")
add("tour.lead",
    "Cappadocia is yours. With the Grand Tour you expand to Albuquerque in America, Luxor in Egypt, Bristol in England and the Maasai Mara in Kenya, and you found your own holding. One-time purchase.",
    "Kapadokya senin. Dünya Turu ile Amerika'da Albuquerque'ye, Mısır'da Luksor'a, İngiltere'de Bristol'e ve Kenya'da Maasai Mara'ya açılırsın; kendi holdingini de kurarsın. Bir kez alınır.",
    "Kappadokien gehört dir. Mit der Weltreise geht es nach Albuquerque in Amerika, Luxor in Ägypten, Bristol in England und in die Maasai Mara in Kenia, und du gründest deine eigene Holding. Einmaliger Kauf.",
    "Capadocia es tuya. Con el Gran Tour te abres a Albuquerque en Estados Unidos, Luxor en Egipto, Bristol en Inglaterra y el Maasai Mara en Kenia, y fundas tu propio holding. Se compra una vez.",
    "カッパドキアはあなたのものだ。グランドツアーでアメリカのアルバカーキ、エジプトのルクソール、イギリスのブリストル、ケニアのマサイマラへ進出し、自分のホールディングスも作れる。購入は一度だけ。",
    "카파도키아는 당신 것입니다. 그랜드 투어로 미국의 앨버커키, 이집트의 룩소르, 영국의 브리스톨, 케냐의 마사이마라로 진출하고 지주회사도 세웁니다. 한 번만 구매합니다.")
add("tour.worldSub", "Albuquerque, Luxor, Bristol and the Maasai Mara", "Albuquerque, Luksor, Bristol ve Maasai Mara",
    "Albuquerque, Luxor, Bristol und die Maasai Mara", "Albuquerque, Luxor, Bristol y el Maasai Mara",
    "アルバカーキ、ルクソール、ブリストル、マサイマラ", "앨버커키, 룩소르, 브리스톨, 마사이마라")

# ---- Offices: London (save key "par"), and the perks that moved ----
add("office.par", "London", "Londra", "London", "Londres", "ロンドン", "런던")
add("office.par.perk",
    "Bristol +20%: its autopilot income, and its tourists while you play there. The documentary series 20% cheaper.",
    "Bristol'de %20 fazla: otomatikteyken kazancı, oradayken turisti. Belgesel dizisi %20 daha ucuz.",
    "Bristol +20 %: die Autopilot-Einnahmen und die Touristen, solange du dort spielst. Die Doku-Serie 20 % günstiger.",
    "Bristol +20 %: sus ingresos en piloto automático y sus turistas mientras juegas allí. La serie documental un 20 % más barata.",
    "ブリストル+20%：自動運営の収入と、そこでプレイ中の観光客。ドキュメンタリーシリーズが20%安くなる。",
    "브리스톨 +20%: 자동 운영 수입, 그리고 그곳에서 플레이하는 동안의 관광객. 다큐멘터리 시리즈 20% 할인.")
add("office.dxb.perk",
    "The Maasai Mara's autopilot income +20%. Record attempts 25% cheaper.",
    "Maasai Mara'nın otomatik kazancı %20 artar. Rekor denemeleri %25 daha ucuz.",
    "Autopilot-Einnahmen in der Maasai Mara +20 %. Rekordversuche 25 % günstiger.",
    "Ingresos en piloto automático del Maasai Mara +20 %. Intentos de récord un 25 % más baratos.",
    "マサイマラの自動運営収入+20%。記録挑戦が25%安くなる。",
    "마사이마라 자동 운영 수입 +20%. 기록 도전 25% 할인.")
add("office.tyo.perk",
    "Asian tour operators: tourists +5% in every region. Luxor's autopilot income +20%. Free design production, creativity +10, designs stay fresh for 60 days.",
    "Asyalı tur şirketleri: bütün bölgelerde turist +%5. Luksor'un otomatik kazancı %20 artar. Tasarım üretimi bedava, yaratıcılık +10, tasarımlar 60 gün taze kalır.",
    "Asiatische Reiseveranstalter: Touristen +5 % in jeder Region. Autopilot-Einnahmen in Luxor +20 %. Kostenlose Designproduktion, Kreativität +10, Designs bleiben 60 Tage frisch.",
    "Agencias de viajes asiáticas: turistas +5 % en todas las regiones. Ingresos en piloto automático de Luxor +20 %. Diseños gratis, creatividad +10, los diseños siguen frescos 60 días.",
    "アジアの旅行会社：全地域で観光客+5%。ルクソールの自動運営収入+20%。デザイン制作が無料、創造性+10、デザインの鮮度が60日間持続。",
    "아시아 여행사: 모든 지역 관광객 +5%. 룩소르 자동 운영 수입 +20%. 디자인 제작 무료, 창의성 +10, 디자인 신선도 60일 유지.")
add("ceremony.baronHint.bri",
    "The skies of four regions are yours. The Maasai Mara has opened on the world map: the toughest sky in the game.",
    "Dört bölgenin göğü senin. Dünya haritasında Maasai Mara açıldı: oyunun en çetin göğü.",
    "Der Himmel über vier Regionen gehört dir. Auf der Weltkarte hat sich die Maasai Mara geöffnet: der härteste Himmel im Spiel.",
    "Los cielos de cuatro regiones son tuyos. En el mapa del mundo se ha abierto el Maasai Mara: el cielo más duro del juego.",
    "4つの地域の空は君のものだ。世界地図にマサイマラが開いた。ゲームで最も過酷な空だ。",
    "네 지역의 하늘이 당신 것입니다. 세계 지도에 마사이마라가 열렸습니다: 게임에서 가장 험난한 하늘.")
