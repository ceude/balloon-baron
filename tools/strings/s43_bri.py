from s1_ui import add

# v124 Bristol (prototype v124 / v124.1): region, map, names, chapters, characters, festival, flight, town.

# Region and map
add("region.bri", "Bristol", "Bristol", "Bristol", "Bristol", "ブリストル", "브리스톨")
add("map.here.bri",
 "The Avon Gorge, foggy mornings and festival evenings.",
 "Avon Kanyonu, sisli sabahlar ve festival akşamları.",
 "Die Avon-Schlucht, neblige Morgen und Festivalabende.",
 "La garganta del Avon, mañanas de niebla y tardes de festival.",
 "エイボン渓谷、霧の朝、そして祭りの夕べ。",
 "에이번 협곡, 안개 낀 아침, 그리고 축제의 저녁.")
add("map.openSub.bri",
 "The Avon Gorge and its suspension bridge, Georgian houses, the harbour. Changeable English weather: morning fog, the west wind, the airport's forbidden sky. A balloon festival every month, with a second flight on festival evenings. The money here is the pound. You start with %1$@. Entry fee %2$@ from the holding.",
 "Avon Kanyonu ve asma köprü, Gürcü evleri, liman. Değişken İngiliz havası: sabah sisi, batı rüzgârı, havalimanının yasak göğü. Her ay bir balon festivali, festival akşamları ikinci uçuş. Para birimi sterlin. Başlangıç kasası: %1$@. Giriş bedeli %2$@ holding kasasından.",
 "Die Avon-Schlucht mit ihrer Hängebrücke, georgianische Häuser, der Hafen. Wechselhaftes englisches Wetter: Morgennebel, Westwind, der gesperrte Himmel des Flughafens. Jeden Monat ein Ballonfestival, an Festivalabenden ein zweiter Flug. Hier zahlt man in Pfund. Startkapital: %1$@. Einstiegsgebühr %2$@ aus der Holding.",
 "La garganta del Avon y su puente colgante, casas georgianas, el puerto. Tiempo inglés y cambiante: niebla matinal, viento del oeste, el cielo prohibido del aeropuerto. Un festival de globos cada mes, con un segundo vuelo en las tardes de festival. Aquí se paga en libras. Capital inicial: %1$@. Cuota de entrada: %2$@, a cargo del holding.",
 "エイボン渓谷と吊り橋、ジョージアン様式の家々、港。変わりやすいイギリスの天気：朝霧、西風、空港の飛行禁止空域。毎月気球祭りがあり、祭りの夕方には2回目のフライト。通貨はポンド。開始資金：%1$@。参入費%2$@はホールディングスから。",
 "에이번 협곡과 현수교, 조지아풍 집들, 항구. 변덕스러운 영국 날씨: 아침 안개, 서풍, 공항의 비행 금지 하늘. 매달 열기구 축제가 열리고, 축제 저녁에는 두 번째 비행이 있습니다. 화폐는 파운드. 시작 자금: %1$@. 진입 비용 %2$@, 지주회사에서 지급.")
add("map.lockedSub.bri",
 "Unlocks when you become baron of Luxor. Over the Avon Gorge, in misty English mornings.",
 "Luksor baronu olunca açılır. Avon Kanyonu'nun üstünde, sisli İngiliz sabahlarında.",
 "Wird freigeschaltet, wenn du Baron von Luxor bist. Über der Avon-Schlucht, an nebligen englischen Morgen.",
 "Se desbloquea cuando seas barón de Luxor. Sobre la garganta del Avon, en brumosas mañanas inglesas.",
 "ルクソールの男爵になると解放される。エイボン渓谷の上、霧のイギリスの朝。",
 "룩소르의 남작이 되면 열립니다. 에이번 협곡 위, 안개 낀 영국의 아침.")
add("regions.lockedBri", "Opens when you're baron of Luxor", "Luksor baronu olunca açılır", "Öffnet, wenn du Baron von Luxor bist",
 "Se abre cuando seas barón de Luxor", "ルクソールの男爵になると開く", "룩소르의 남작이 되면 열림")

# Local names
for k, name in [("stone", "Harbourside Inn"), ("mansion", "Clifton Terrace Hotel"), ("cave", "Avon Gorge Lodge"), ("palace", "Royal Crescent Grand")]:
    add("bri.hotel." + k, name, name, name, name, name, name)
for k, name in [("carpet", "Cider Press Co."), ("wine", "Severn Bank"), ("bank", "Harbour Tea Rooms"), ("energy", "Westcountry Mobile")]:
    add("bri.sponsor." + k, name, name, name, name, name, name)
add("bri.mission.valley", "Touch of the Avon", "Avon dokunuşu", "Gruß an den Avon", "Toque del Avon", "エイボン・タッチ", "에이번 터치")
add("bri.mission.desc.valley",
 "Drop below 150 m over the River Avon and salute the gorge.",
 "Avon nehrinin üstünde 150 m'nin altına alçal, kanyonu selamla.",
 "Sinke über dem Avon unter 150 m und grüße die Schlucht.",
 "Desciende por debajo de 150 m sobre el río Avon y saluda a la garganta.",
 "エイボン川の上で高度150 m以下に下り、渓谷に挨拶しよう。",
 "에이번강 위에서 150 m 아래로 내려가 협곡에 인사하세요.")
add("bname.avonStar", "Star of the Avon", "Avon Yıldızı", "Stern des Avon", "Estrella del Avon", "エイボンの星", "에이번의 별")
# The guide office's local guides (v124 `GUIDE_NAMES.bri`; ids ayse, mehmet, selin)
add("guide.ayse.name.bri", "Olivia", "Olivia", "Olivia", "Olivia", "オリビア", "올리비아")
add("guide.mehmet.name.bri", "Harry", "Harry", "Harry", "Harry", "ハリー", "해리")
add("guide.selin.name.bri", "Imogen", "Imogen", "Imogen", "Imogen", "イモージェン", "이모젠")

# Chapters and goals
add("chapter.ashton", "Ashton Court", "Ashton Malikânesi", "Ashton Court", "Ashton Court", "アシュトン・コート", "애시턴 코트")
add("chapter.ashton.award",
 "The Bristol Chamber of Commerce named you New Business of the Year",
 "Bristol Ticaret Odası seni yılın yeni işletmesi seçti",
 "Die Handelskammer Bristol hat dich zum neuen Unternehmen des Jahres gewählt",
 "La Cámara de Comercio de Bristol te eligió nueva empresa del año",
 "ブリストル商工会議所が君を年間最優秀新企業に選んだ",
 "브리스톨 상공회의소가 당신을 올해의 신생 기업으로 선정했습니다")
add("chapter.avonGorge", "Avon Gorge", "Avon Kanyonu", "Avon-Schlucht", "Garganta del Avon", "エイボン渓谷", "에이번 협곡")
add("chapter.avonGorge.award",
 "The West of England Pilots' Association named you master of the gorge",
 "Batı İngiltere Pilotlar Derneği seni kanyonun ustası ilan etti",
 "Der Pilotenverband Westengland hat dich zum Meister der Schlucht erklärt",
 "La Asociación de Pilotos del Oeste de Inglaterra te nombró maestro de la garganta",
 "西イングランド・パイロット協会が君を渓谷の名手と認めた",
 "서잉글랜드 조종사 협회가 당신을 협곡의 명인으로 인정했습니다")
add("chapter.festivalBri", "Festival", "Festival", "Festival", "Festival", "フェスティバル", "축제")
add("chapter.festivalBri.award",
 "The festival jury named you the star of the festival",
 "Festival jürisi seni festivalin yıldızı seçti",
 "Die Festivaljury hat dich zum Star des Festivals gewählt",
 "El jurado del festival te eligió la estrella del festival",
 "祭りの審査員が君を祭りのスターに選んだ",
 "축제 심사위원단이 당신을 축제의 스타로 선정했습니다")
add("chapter.baronBri", "Baron of Bristol", "Bristol Baronu", "Baron von Bristol", "Barón de Bristol", "ブリストル男爵", "브리스톨 남작")
add("chapter.baronBri.award", "", "", "", "", "", "")
add("goal.fog", "Fly on a foggy day", "Sisli bir günde uç", "Fliege an einem nebligen Tag", "Vuela un día de niebla", "霧の日に飛ぶ", "안개 낀 날 비행하기")
add("goal.glow", "Hold a Night Glow", "Bir Gece Işıltısı düzenle", "Veranstalte ein Night Glow", "Organiza un Night Glow", "ナイトグローを開く", "나이트 글로 열기")
add("goal.fiesta.bri", "Fly at the Bristol Balloon Festival", "Bristol Balon Festivali'nde uç", "Fliege beim Bristol-Ballonfestival",
 "Vuela en el Festival de Globos de Bristol", "ブリストル気球祭りで飛ぶ", "브리스톨 열기구 축제에서 비행하기")

# Postcards
add("ach.bri", "Sky of the Avon", "Avon'un göğü", "Himmel über dem Avon", "El cielo del Avon", "エイボンの空", "에이번의 하늘")
add("ach.bri.d", "You entered Bristol", "Bristol'e girdin", "Du bist in Bristol angekommen", "Llegaste a Bristol", "ブリストルに進出した", "브리스톨에 진출했습니다")
add("ach.nightGlow", "Night Glow", "Gece Işıltısı", "Night Glow", "Night Glow", "ナイトグロー", "나이트 글로")
add("ach.nightGlow.d", "Your balloons glowed on a festival night", "Festival gecesi balonların ışıldadı", "Deine Ballons leuchteten in einer Festivalnacht",
 "Tus globos brillaron en una noche de festival", "祭りの夜、君の気球が輝いた", "축제의 밤, 당신의 열기구가 빛났습니다")
add("ach.baronBri", "Baron of Bristol", "Bristol Baronu", "Baron von Bristol", "Barón de Bristol", "ブリストル男爵", "브리스톨 남작")
add("ach.baronBri.d", "Master of the gorge and the festival", "Kanyonun ve festivalin sahibi", "Herr über Schlucht und Festival",
 "Dueño de la garganta y del festival", "渓谷と祭りの主", "협곡과 축제의 주인")

# Newcomers
add("hez.entrant.cotswold",
 "Cotswold Air Holidays has come to Bristol with the money of London's tour companies! A big fleet and deep pockets. After Sir Reginald, this may be the most dangerous of them all, dear.",
 "Cotswold Air Holidays, Londra'daki tur şirketlerinin parasıyla Bristol'e geldi! Filosu büyük, kesesi derin. Sir Reginald'dan sonra en tehlikelisi bu olabilir canım.",
 "Cotswold Air Holidays ist mit dem Geld Londoner Reiseveranstalter nach Bristol gekommen! Eine große Flotte und tiefe Taschen. Nach Sir Reginald vielleicht der gefährlichste von allen, mein Lieber.",
 "¡Cotswold Air Holidays ha llegado a Bristol con el dinero de las agencias de viajes de Londres! Una gran flota y bolsillos profundos. Después de Sir Reginald, quizá sea el más peligroso de todos, cielo.",
 "コッツウォルド・エア・ホリデーズが、ロンドンの旅行会社の資金でブリストルにやって来たよ！大きな船団に潤沢な資金。サー・レジナルドの次に一番手ごわいかもしれないね、あんた。",
 "코츠월드 에어 홀리데이스가 런던 여행사들의 돈을 등에 업고 브리스톨에 왔어요! 함대도 크고 자금도 두둑해요. 레지널드 경 다음으로 가장 위험한 상대일지도 몰라요, 얘야.")
add("hez.entrant.cheapSkies",
 "A discount outfit called Cheap Skies Bristol has opened. They'll sell tickets to students at half price, and they won't care much about the fog.",
 "Cheap Skies Bristol diye bir ucuzcu açıldı. Öğrencilere yarı fiyata bilet satacaklar, sisi de pek takmayacaklar.",
 "Ein Billiganbieter namens Cheap Skies Bristol hat eröffnet. Sie verkaufen Studenten Tickets zum halben Preis und kümmern sich nicht groß um den Nebel.",
 "Ha abierto una empresa low cost llamada Cheap Skies Bristol. Venderán billetes a estudiantes a mitad de precio, y la niebla no les importará mucho.",
 "チープ・スカイズ・ブリストルという格安業者が開業した。学生に半額でチケットを売るつもりで、霧なんてあまり気にしないらしい。",
 "칩 스카이즈 브리스톨이라는 저가 업체가 문을 열었어요. 학생들에게 반값에 표를 팔 거고, 안개는 별로 신경 쓰지 않을 거예요.")
add("hez.entrant.royalCrescent",
 "A luxury boutique company called Royal Crescent Flights has opened. Few balloons, champagne breakfasts, very high prices. The rich tourists will go to them.",
 "Royal Crescent Flights adında lüks bir butik şirket açıldı. Az balon, şampanyalı kahvaltı, çok yüksek fiyat. Zengin turistler onlara gidecek.",
 "Ein Luxus-Boutiqueunternehmen namens Royal Crescent Flights hat eröffnet. Wenige Ballons, Champagnerfrühstück, sehr hohe Preise. Die reichen Touristen werden zu ihnen gehen.",
 "Ha abierto una empresa boutique de lujo llamada Royal Crescent Flights. Pocos globos, desayuno con champán, precios muy altos. Los turistas ricos irán con ellos.",
 "ロイヤル・クレセント・フライツという高級ブティック会社が開業した。気球は少なく、シャンパン付きの朝食、とても高い料金。裕福な観光客はそっちへ行くだろう。",
 "로열 크레센트 플라이츠라는 고급 부티크 회사가 문을 열었어요. 열기구는 적고, 샴페인 아침 식사에, 가격은 아주 비싸요. 부유한 관광객들은 그쪽으로 갈 거예요.")
add("hez.entrant.mendip",
 "A family from the Mendip Hills has founded Mendip Balloon Co. A balanced, solid, patient rival.",
 "Mendip tepelerinden bir aile şirketi Mendip Balloon Co.'yu kurdu. Dengeli, sağlam, sabırlı bir rakip.",
 "Eine Familie aus den Mendip Hills hat die Mendip Balloon Co. gegründet. Ein ausgewogener, solider, geduldiger Rivale.",
 "Una familia de las colinas de Mendip ha fundado Mendip Balloon Co. Un rival equilibrado, sólido y paciente.",
 "メンディップ丘陵の一家がメンディップ・バルーン社を立ち上げた。バランスが良く、堅実で、辛抱強いライバルだ。",
 "멘딥 언덕의 한 가족이 멘딥 벌룬 컴퍼니를 세웠어요. 균형 잡히고 탄탄하며 끈기 있는 경쟁자예요.")

# Sir Reginald Ashby, Clifton Crown Balloons
add("boss.bri.name", "Sir Reginald Ashby", "Sir Reginald Ashby", "Sir Reginald Ashby", "Sir Reginald Ashby", "サー・レジナルド・アシュビー", "레지널드 애슈비 경")
add("boss.bri.title", "Owner of Clifton Crown Balloons", "Clifton Crown Balloons sahibi", "Inhaber von Clifton Crown Balloons",
 "Dueño de Clifton Crown Balloons", "クリフトン・クラウン・バルーンズのオーナー", "클리프턴 크라운 벌룬스 대표")
add("boss.bri.hello",
 "Ah, a newcomer. Sir Reginald Ashby, Clifton Crown Balloons. When my great-grandfather flew the first balloon over this gorge, the bridge had only just been finished. Here one knows good families, good hotels and good tea. You won in Egypt, did you? Bristol's weather will greet you with fog in the morning and see you off with rain at noon. Let's see how long you last.",
 "Ah, yeni gelen. Sir Reginald Ashby, Clifton Crown Balloons. Büyük büyükbabam bu kanyonun üstünde ilk balonu uçurduğunda köprü daha yeni bitmişti. Burada iyi aileler, iyi oteller ve iyi çay bilinir. Mısır'da kazanmışsın, öyle mi? Bristol'ün havası seni sabah sisle karşılar, öğlen yağmurla uğurlar. Bakalım ne kadar dayanacaksın.",
 "Ah, ein Neuling. Sir Reginald Ashby, Clifton Crown Balloons. Als mein Urgroßvater den ersten Ballon über diese Schlucht flog, war die Brücke gerade erst fertig. Hier kennt man gute Familien, gute Hotels und guten Tee. In Ägypten hast du gewonnen, sagt man? Bristols Wetter empfängt dich morgens mit Nebel und verabschiedet dich mittags mit Regen. Mal sehen, wie lange du durchhältst.",
 "Ah, un recién llegado. Sir Reginald Ashby, Clifton Crown Balloons. Cuando mi bisabuelo voló el primer globo sobre esta garganta, el puente acababa de terminarse. Aquí se conocen las buenas familias, los buenos hoteles y el buen té. Ganaste en Egipto, ¿no? El tiempo de Bristol te recibirá con niebla por la mañana y te despedirá con lluvia al mediodía. Veamos cuánto aguantas.",
 "ほう、新参者か。サー・レジナルド・アシュビー、クリフトン・クラウン・バルーンズだ。曾祖父がこの渓谷の上に初めて気球を飛ばしたとき、橋はできたばかりだった。ここでは良き家柄、良きホテル、良き紅茶がものを言う。エジプトで勝ったそうだね？ブリストルの天気は朝は霧で迎え、昼は雨で見送る。どこまで持つか見せてもらおう。",
 "아, 신참이군. 레지널드 애슈비 경, 클리프턴 크라운 벌룬스일세. 증조부께서 이 협곡 위로 첫 열기구를 띄우셨을 때 다리는 막 완공된 참이었지. 이곳에선 좋은 가문, 좋은 호텔, 좋은 차를 알아본다네. 이집트에서 이겼다고? 브리스톨의 날씨는 아침엔 안개로 맞이하고 낮엔 비로 배웅하지. 얼마나 버티는지 보자고.")
add("boss.bri.ch1",
 "You think four balloons get you into the club? In my hangar, balloons are known by their family names. I count my fleet before I finish my morning tea.",
 "Dört balonla kulübe girdiğini mi sanıyorsun? Benim hangarımda balonlar soyadıyla anılır. Sabah çayını bitirmeden filonu sayarım.",
 "Glaubst du, vier Ballons bringen dich in den Club? In meinem Hangar kennt man Ballons beim Familiennamen. Ich zähle meine Flotte, bevor ich meinen Morgentee ausgetrunken habe.",
 "¿Crees que con cuatro globos entras en el club? En mi hangar los globos se conocen por su apellido. Cuento mi flota antes de terminar el té de la mañana.",
 "気球4機でクラブに入れると思っているのかね？私の格納庫では気球は家名で呼ばれる。朝の紅茶を飲み終える前に私は船団を数えるのだよ。",
 "열기구 네 대로 클럽에 들어올 수 있다고 생각하나? 내 격납고에선 열기구를 성으로 부른다네. 나는 아침 차를 다 마시기 전에 함대를 세지.")
add("boss.bri.ch2",
 "The festival is coming. In Bristol everyone comes to see Clifton Crown's balloons. Yours will be in the sky too, I grant you. In the back rows.",
 "Festival yaklaşıyor. Bristol'de herkes Clifton Crown'un balonlarını görmeye gelir. Senin balonların da gökyüzünde olacak, kabul. Arka sıralarda.",
 "Das Festival steht bevor. In Bristol kommen alle, um die Ballons von Clifton Crown zu sehen. Deine werden auch am Himmel sein, zugegeben. In den hinteren Reihen.",
 "Se acerca el festival. En Bristol todos vienen a ver los globos de Clifton Crown. Los tuyos también estarán en el cielo, lo admito. En las últimas filas.",
 "祭りが近い。ブリストルでは皆クリフトン・クラウンの気球を見に来る。君の気球も空にはいるだろう、認めよう。後ろの列でね。",
 "축제가 다가오는군. 브리스톨에선 모두가 클리프턴 크라운의 열기구를 보러 온다네. 자네 열기구도 하늘에 있겠지, 인정하지. 뒷줄에서.")
add("boss.bri.passed",
 "Yesterday you flew more passengers than I did. They're talking about it at the club. I'm not. But they are.",
 "Dün benden fazla yolcu uçurmuşsun. Kulüpte konuşuluyor. Ben konuşmuyorum. Ama konuşuluyor.",
 "Gestern hast du mehr Passagiere geflogen als ich. Im Club spricht man darüber. Ich nicht. Aber man spricht.",
 "Ayer volaste con más pasajeros que yo. En el club se habla de ello. Yo no. Pero se habla.",
 "昨日は私より多くの乗客を乗せたそうだね。クラブで噂になっている。私は口にしない。だが噂にはなっている。",
 "어제 자네가 나보다 승객을 더 태웠다더군. 클럽에서 말들이 많아. 나는 말하지 않네. 하지만 말들이 많지.")
add("boss.bri.hotel",
 "That hotel's owner and I went to the same school. Here deals are made over lunch with crystal glasses, my dear fellow.",
 "O otelin sahibiyle aynı okulda okuduk. Burada anlaşmalar öğle yemeğinde, kristal kadehle yapılır, sevgili dostum.",
 "Der Besitzer dieses Hotels und ich waren auf derselben Schule. Hier werden Geschäfte beim Mittagessen mit Kristallgläsern gemacht, mein Lieber.",
 "El dueño de ese hotel y yo fuimos al mismo colegio. Aquí los tratos se cierran en el almuerzo, con copas de cristal, querido amigo.",
 "あのホテルのオーナーとは同じ学校の出でね。ここでは取引は昼食の席で、クリスタルのグラスを傾けて決まるのだよ、君。",
 "그 호텔 주인과 나는 같은 학교를 다녔다네. 이곳에선 거래가 점심 자리에서 크리스털 잔을 들고 이루어지지, 친애하는 친구.")
add("boss.bri.poach",
 "I offered your pilot a flat in Clifton and a club membership. A gentlemanly offer; you'll accept it.",
 "Pilotuna Clifton'da bir daire ve kulübe üyelik teklif ettim. Centilmence bir teklif, kabul edersin.",
 "Ich habe deinem Piloten eine Wohnung in Clifton und eine Clubmitgliedschaft angeboten. Ein gentlemanhaftes Angebot; du wirst es akzeptieren.",
 "Le ofrecí a tu piloto un piso en Clifton y la membresía del club. Una oferta de caballeros; la aceptarás.",
 "君のパイロットにクリフトンのフラットとクラブの会員権を提示したよ。紳士的な申し出だ、受け入れたまえ。",
 "자네 조종사에게 클리프턴의 아파트와 클럽 회원권을 제안했네. 신사다운 제안이니 받아들이게.")
add("boss.bri.accident",
 "Did you come down in a sheep field, or in the mud? Over this gorge a gentleman chooses his landing.",
 "Bir koyun tarlasına mı indin, yoksa çamura mı? Bu kanyonda bir centilmen inişini seçer.",
 "Bist du auf einer Schafweide gelandet oder im Schlamm? Über dieser Schlucht wählt ein Gentleman seine Landung.",
 "¿Aterrizaste en un campo de ovejas o en el barro? Sobre esta garganta, un caballero elige dónde aterriza.",
 "羊の牧草地に降りたのかね、それとも泥の中かね？この渓谷では紳士は着陸地を選ぶものだ。",
 "양 목장에 내렸나, 아니면 진흙탕에? 이 협곡에선 신사라면 착륙지를 고르는 법이지.")
add("boss.bri.deal",
 "Very well. I must admit the wind has turned your way. If you wish to take over Clifton Crown, my solicitors are ready. Only, please don't take the crown off the logo.",
 "Peki. Kabul etmeliyim, rüzgâr senden yana döndü. Clifton Crown'u devralmak istersen avukatlarım hazır. Yalnız tacı logodan silme, rica ederim.",
 "Nun gut. Ich muss zugeben, der Wind hat sich zu deinen Gunsten gedreht. Wenn du Clifton Crown übernehmen willst, stehen meine Anwälte bereit. Nur nimm bitte die Krone nicht aus dem Logo.",
 "Muy bien. Debo admitir que el viento ha girado a tu favor. Si quieres quedarte con Clifton Crown, mis abogados están listos. Solo te ruego que no quites la corona del logotipo.",
 "よろしい。風が君の側に回ったことは認めねばなるまい。クリフトン・クラウンを引き継ぎたいなら、私の弁護士がいつでも応じる。ただ、ロゴから王冠は消さないでくれたまえ。",
 "좋네. 바람이 자네 쪽으로 돌아섰다는 걸 인정해야겠군. 클리프턴 크라운을 인수하고 싶다면 내 변호사들이 준비돼 있네. 다만 로고에서 왕관만은 지우지 말아 주게.")
add("boss.bri.gone",
 "I've sold my last balloon. I'm giving the hangar to a museum. Bristol is yours now. I'll raise a glass at the festival, from a distance.",
 "Son balonumu da sattım. Hangarı bir müzeye bağışlıyorum. Bristol artık senin. Festivalde bir kadeh kaldırırım, uzaktan.",
 "Ich habe meinen letzten Ballon verkauft. Den Hangar schenke ich einem Museum. Bristol gehört jetzt dir. Beim Festival erhebe ich ein Glas, aus der Ferne.",
 "He vendido mi último globo. Donaré el hangar a un museo. Bristol es tuyo ahora. En el festival alzaré una copa, desde lejos.",
 "最後の気球も売ったよ。格納庫は博物館に寄贈する。ブリストルはもう君のものだ。祭りでは遠くから杯を掲げよう。",
 "마지막 열기구도 팔았네. 격납고는 박물관에 기증하겠네. 이제 브리스톨은 자네 것이야. 축제 때 멀리서 잔을 들겠네.")
add("boss.bri.baron",
 "Baron of Bristol. My great-grandfather would have dropped his monocle. I'm not dropping mine, you see. But I take my hat off to you. You've earned it.",
 "Bristol Baronu. Büyük büyükbabam görse monoklü düşerdi. Ben düşürmüyorum, bak. Ama şapkamı çıkarıyorum. Hak ettin.",
 "Baron von Bristol. Meinem Urgroßvater wäre das Monokel heruntergefallen. Mir nicht, siehst du. Aber ich ziehe den Hut vor dir. Du hast es dir verdient.",
 "Barón de Bristol. A mi bisabuelo se le habría caído el monóculo. A mí no, ya ves. Pero me quito el sombrero. Te lo has ganado.",
 "ブリストル男爵か。曾祖父なら片眼鏡を落としていただろう。私は落とさんよ、ほらね。だが脱帽だ。君はそれに値する。",
 "브리스톨 남작이라. 증조부셨다면 외알 안경을 떨어뜨리셨을 걸세. 난 떨어뜨리지 않네, 보게. 하지만 모자는 벗겠네. 자네는 자격이 있어.")

# Maggie Holloway, the guide
add("guide.bri.name", "Maggie Holloway", "Maggie Holloway", "Maggie Holloway", "Maggie Holloway", "マギー・ホロウェイ", "매기 홀로웨이")
add("guide.short.bri", "Maggie", "Maggie", "Maggie", "Maggie", "マギー", "매기")
add("guide.bri.hello",
 "Hello, love, I'm Maggie. Maggie Holloway. I sewed balloon envelopes in this city for forty years; one look at your balloon's seams and I could tell you whose hands made it. Master Hezarfen has put you in my care, and in Bristol I'll show you the way. Three things to know, dear: there's fog in the mornings, the wind blows from the west, off the Bristol Channel, and never, ever fly into the airport's sky. Oh, and don't forget your umbrella.",
 "Merhaba canım, ben Maggie. Maggie Holloway. Kırk yıl bu şehirde balon zarfı diktim; senin balonunun dikişlerine bakınca kimin elinden çıktığını bile söylerim. Hezarfen Usta seni bana emanet etti, Bristol'de sana ben yol göstereceğim. Üç şey bil, tatlım: sabahları sis olur, rüzgâr Bristol Kanalı'ndan, batıdan eser, havalimanının göğüne de asla girme. Bir de şemsiyeni unutma.",
 "Hallo, Schätzchen, ich bin Maggie. Maggie Holloway. Vierzig Jahre lang habe ich in dieser Stadt Ballonhüllen genäht; ein Blick auf die Nähte deines Ballons, und ich sage dir, aus wessen Händen er stammt. Meister Hezarfen hat dich mir anvertraut, in Bristol zeige ich dir den Weg. Drei Dinge musst du wissen, Liebes: Morgens gibt es Nebel, der Wind weht von Westen, vom Bristolkanal, und flieg niemals in den Himmel des Flughafens. Ach, und vergiss deinen Regenschirm nicht.",
 "Hola, cielo, soy Maggie. Maggie Holloway. Cosí envolturas de globos en esta ciudad durante cuarenta años; con mirar las costuras de tu globo te diría de qué manos salió. El maestro Hezarfen te ha dejado a mi cargo, y en Bristol yo te guiaré. Tres cosas, querida: por las mañanas hay niebla, el viento sopla del oeste, desde el canal de Bristol, y nunca, jamás, entres en el cielo del aeropuerto. Ah, y no olvides el paraguas.",
 "こんにちは、あんた。マギーよ。マギー・ホロウェイ。この街で40年、気球の外皮を縫ってきたの。あんたの気球の縫い目を見れば、誰の手によるものかだってわかるわ。ヘザルフェン師匠にあんたを託されたから、ブリストルでは私が案内するわね。覚えておいてほしいことが三つ。朝は霧が出る、風は西のブリストル海峡から吹く、そして空港の空には絶対に入らないこと。あ、それと傘を忘れないでね。",
 "안녕, 얘야, 나는 매기란다. 매기 홀로웨이. 이 도시에서 40년 동안 열기구 외피를 꿰맸지. 네 열기구 바느질만 봐도 누구 손에서 나왔는지 알 수 있단다. 헤자르펜 스승님이 너를 내게 맡기셨으니, 브리스톨에선 내가 길을 알려 줄게. 세 가지만 기억하렴: 아침엔 안개가 끼고, 바람은 서쪽 브리스톨 해협에서 불어오고, 공항 하늘엔 절대 들어가지 마. 아, 우산도 잊지 말고.")
add("ceremony.baronLead.bri",
 "Day %1$@. Two of every three balloons in the sky over %2$@ fly the colors of %3$@. Maggie Holloway takes off her glasses and wipes her eyes: “Forty years I sewed balloon envelopes, love, and not one of them went this high. Come on, I'll put the kettle on.”",
 "Gün %1$@. %2$@ göğündeki her üç balondan ikisi %3$@ renklerinde. Maggie Holloway gözlüklerini çıkarıp gözünü siliyor: “Kırk yıl balon zarfı diktim tatlım, hiçbiri bu kadar yükseğe çıkmadı. Gel bakalım, bir çay koyayım.”",
 "Tag %1$@. Zwei von drei Ballons am Himmel über %2$@ tragen die Farben von %3$@. Maggie Holloway nimmt die Brille ab und wischt sich die Augen: „Vierzig Jahre habe ich Ballonhüllen genäht, Schätzchen, und keine ist so hoch gestiegen. Komm, ich setz Tee auf.“",
 "Día %1$@. Dos de cada tres globos en el cielo de %2$@ llevan los colores de %3$@. Maggie Holloway se quita las gafas y se seca los ojos: «Cuarenta años cosiendo envolturas de globos, cielo, y ninguna subió tan alto. Ven, que pongo el té».",
 "%1$@日目。%2$@の空を飛ぶ気球の3機に2機が%3$@の色だ。マギー・ホロウェイが眼鏡を外して目元をぬぐう。「40年も気球を縫ってきたけど、こんなに高く上がったのは一つもなかったよ、あんた。さあおいで、お茶を淹れるから。」",
 "%1$@일째. %2$@ 하늘의 열기구 셋 중 둘이 %3$@의 색을 띠고 있습니다. 매기 홀로웨이가 안경을 벗고 눈가를 훔칩니다. “40년 동안 열기구를 꿰맸지만 이렇게 높이 오른 건 하나도 없었단다, 얘야. 이리 와, 차 한잔 끓여 줄게.”")
add("ceremony.baronHint.bri",
 "The skies of four regions are yours. The holding's last goal is waiting: the World Games show.",
 "Dört bölgenin göğü senin. Holdingin son hedefi seni bekliyor: Dünya Oyunları gösterisi.",
 "Der Himmel über vier Regionen gehört dir. Das letzte Ziel der Holding wartet: die Show bei den Weltspielen.",
 "Los cielos de cuatro regiones son tuyos. Te espera el último objetivo del holding: el espectáculo de los Juegos Mundiales.",
 "4つの地域の空は君のものだ。ホールディングスの最後の目標が待っている。ワールドゲームズのショーだ。",
 "네 지역의 하늘이 당신 것입니다. 지주회사의 마지막 목표가 기다립니다: 월드 게임 쇼.")
# v124: after the Luxor baron, Bristol is open on the map (was "Bristol and the Maasai Mara very soon")
add("ceremony.baronHint.lux",
 "The skies of three regions are yours. Bristol has opened on the world map.",
 "Üç bölgenin göğü senin. Dünya haritasında Bristol açıldı.",
 "Der Himmel über drei Regionen gehört dir. Auf der Weltkarte ist Bristol freigeschaltet.",
 "Los cielos de tres regiones son tuyos. Bristol se ha abierto en el mapa del mundo.",
 "3つの地域の空は君のものだ。世界地図でブリストルが解放された。",
 "세 지역의 하늘이 당신 것입니다. 세계 지도에 브리스톨이 열렸습니다.")

# Inspector Graham Pike
add("insp.name.bri", "Inspector Graham Pike", "Müfettiş Graham Pike", "Inspektor Graham Pike", "Inspector Graham Pike", "グレアム・パイク検査官", "그레이엄 파이크 검사관")
add("insp.title.bri", "UK Civil Aviation Authority", "İngiltere Sivil Havacılık Otoritesi", "Britische Zivilluftfahrtbehörde",
 "Autoridad de Aviación Civil del Reino Unido", "英国民間航空局", "영국 민간항공청")

# Hezarfen sends you to Bristol
add("hez.entered.bri",
 "England, kid, Bristol! Half the world's balloon envelopes were sewn in this city, and the sky knows it. A suspension bridge over the Avon Gorge, an old tall ship in the harbour, bright green fields on the hills. But the weather is English: yellow flags are common and there's fog in the mornings; on a foggy morning you have to come down to see the landing field. The wind blows from the west, off the Bristol Channel, and carries you east. The airport's sky is forbidden: fly into it and you'll be fined. Sir Reginald Ashby's Clifton Crown has flown here for a hundred years, and the rivals join forces quickly. You start with %@ and one small balloon. Every month there's a four-day balloon festival; on festival evenings the balloons go up a second time, and you can hold a Night Glow too. Take your umbrella, kid.",
 "İngiltere evlat, Bristol! Dünyanın balon zarflarının yarısı bu şehirde dikilmiş, gökyüzü de onu bilir. Avon Kanyonu'nun üstünde asma bir köprü, limanda eski bir yelkenli, tepelerde yemyeşil tarlalar. Ama hava İngiliz havası: sarı bayrak sık, sabahları sis olur; sisli sabah iniş alanını görmek için alçalman gerekir. Rüzgâr batıdan, Bristol Kanalı'ndan esip seni doğuya taşır. Havalimanının göğü de yasak bölge, girersen ceza yersin. Sir Reginald Ashby'nin Clifton Crown'u burada yüz yıldır uçuyor ve rakipler çabuk birleşir. %@ ve küçük bir balonla başlıyorsun. Her ay dört günlük bir balon festivali var; festival akşamları balonlar ikinci kez kalkar, gece de Gece Işıltısı düzenleyebilirsin. Şemsiyeni al evlat.",
 "England, Kind, Bristol! Die Hälfte aller Ballonhüllen der Welt wurde in dieser Stadt genäht, und der Himmel weiß das. Eine Hängebrücke über der Avon-Schlucht, ein alter Großsegler im Hafen, sattgrüne Felder auf den Hügeln. Aber das Wetter ist englisch: Gelbe Flaggen sind häufig, und morgens gibt es Nebel; an einem nebligen Morgen musst du tiefer gehen, um das Landefeld zu sehen. Der Wind weht von Westen, vom Bristolkanal, und trägt dich nach Osten. Der Himmel des Flughafens ist Sperrgebiet: Fliegst du hinein, gibt es eine Strafe. Sir Reginald Ashbys Clifton Crown fliegt hier seit hundert Jahren, und die Rivalen verbünden sich schnell. Du beginnst mit %@ und einem kleinen Ballon. Jeden Monat gibt es ein viertägiges Ballonfestival; an Festivalabenden steigen die Ballons ein zweites Mal auf, und du kannst ein Night Glow veranstalten. Nimm deinen Regenschirm mit, Kind.",
 "¡Inglaterra, chico, Bristol! La mitad de las envolturas de globos del mundo se cosieron en esta ciudad, y el cielo lo sabe. Un puente colgante sobre la garganta del Avon, un viejo velero en el puerto, campos verdísimos en las colinas. Pero el tiempo es inglés: las banderas amarillas son frecuentes y por las mañanas hay niebla; una mañana de niebla tendrás que bajar para ver el campo de aterrizaje. El viento sopla del oeste, desde el canal de Bristol, y te lleva hacia el este. El cielo del aeropuerto está prohibido: si entras, te multarán. El Clifton Crown de Sir Reginald Ashby lleva cien años volando aquí, y los rivales se unen enseguida. Empiezas con %@ y un globo pequeño. Cada mes hay un festival de globos de cuatro días; en las tardes de festival los globos despegan por segunda vez, y también puedes organizar un Night Glow. Llévate el paraguas, chico.",
 "イギリスだ、ブリストルだぞ！世界の気球の外皮の半分はこの街で縫われた。空もそれを知っている。エイボン渓谷にかかる吊り橋、港の古い帆船、丘に広がる緑の畑。だが天気はイギリスの天気だ。黄旗が多く、朝は霧が出る。霧の朝は着陸場を見るために高度を下げねばならん。風は西、ブリストル海峡から吹き、君を東へ運ぶ。空港の空は飛行禁止区域だ。入れば罰金だぞ。サー・レジナルド・アシュビーのクリフトン・クラウンは百年もここを飛んでいるし、ライバルはすぐに手を組む。%@と小さな気球1機からのスタートだ。毎月4日間の気球祭りがあり、祭りの夕方には気球が2度目に飛び立つ。夜にはナイトグローも開ける。傘を持っていけ。",
 "영국이다, 브리스톨! 세상 열기구 외피의 절반이 이 도시에서 꿰매졌고, 하늘도 그걸 안단다. 에이번 협곡 위의 현수교, 항구의 오래된 범선, 언덕 위의 푸르른 들판. 하지만 날씨는 영국 날씨야: 노란 깃발이 잦고 아침엔 안개가 낀다. 안개 낀 아침엔 착륙장을 보려면 고도를 낮춰야 해. 바람은 서쪽, 브리스톨 해협에서 불어와 너를 동쪽으로 실어 간다. 공항 하늘은 금지 구역이야. 들어가면 벌금이다. 레지널드 애슈비 경의 클리프턴 크라운은 백 년째 여기서 날고 있고, 경쟁자들은 금세 손을 잡는다. 시작 자금은 %@, 그리고 작은 열기구 한 대다. 매달 나흘짜리 열기구 축제가 열리고, 축제 저녁엔 열기구가 두 번째로 뜨며 밤에는 나이트 글로도 열 수 있지. 우산 챙겨라.")

# The festival
add("hez.fiestaStarted.bri",
 "The Bristol Balloon Festival has begun, love! For four days Ashton's meadows are full of tourists. On festival evenings the balloons go up a second time, and one night you can hold a Night Glow. Get all your balloons up!",
 "Bristol Balon Festivali başladı canım! Dört gün boyunca Ashton'un çayırları turist dolu. Festival akşamları balonlar ikinci kez kalkar, bir gece de Gece Işıltısı düzenleyebilirsin. Bütün balonlarını havaya kaldır!",
 "Das Bristol-Ballonfestival hat begonnen, Schätzchen! Vier Tage lang sind Ashtons Wiesen voller Touristen. An Festivalabenden steigen die Ballons ein zweites Mal auf, und in einer Nacht kannst du ein Night Glow veranstalten. Bring alle deine Ballons in die Luft!",
 "¡Ha empezado el Festival de Globos de Bristol, cielo! Durante cuatro días los prados de Ashton estarán llenos de turistas. En las tardes de festival los globos despegan por segunda vez, y una noche puedes organizar un Night Glow. ¡Sube todos tus globos!",
 "ブリストル気球祭りが始まったよ、あんた！4日間、アシュトンの草地は観光客でいっぱい。祭りの夕方には気球が2度目に飛び立つし、ある夜にはナイトグローも開けるわ。気球を全部上げなさい！",
 "브리스톨 열기구 축제가 시작됐단다, 얘야! 나흘 동안 애시턴의 초원이 관광객으로 가득해. 축제 저녁엔 열기구가 두 번째로 뜨고, 하룻밤은 나이트 글로도 열 수 있어. 열기구를 전부 띄우렴!")
add("home.alert.fiesta.bri", "Bristol Balloon Festival, day %1$@/%2$@!", "Bristol Balon Festivali, gün %1$@/%2$@!", "Bristol-Ballonfestival, Tag %1$@/%2$@!",
 "¡Festival de Globos de Bristol, día %1$@/%2$@!", "ブリストル気球祭り、%1$@/%2$@日目！", "브리스톨 열기구 축제, %1$@/%2$@일째!")
add("home.alert.fiesta.body.bri",
 "Nearly twice the tourists, and a second ascent in the evening.",
 "Turist neredeyse iki katı, akşam da ikinci kalkış var.",
 "Fast doppelt so viele Touristen, und abends ein zweiter Aufstieg.",
 "Casi el doble de turistas, y un segundo despegue por la tarde.",
 "観光客はほぼ2倍、夕方には2回目の離陸もある。",
 "관광객이 거의 두 배, 저녁엔 두 번째 이륙도 있습니다.")
add("home.alert.fiesta.glow",
 "You can hold a Night Glow at this festival.",
 "Bu festivalde Gece Işıltısı düzenleyebilirsin.",
 "Bei diesem Festival kannst du ein Night Glow veranstalten.",
 "En este festival puedes organizar un Night Glow.",
 "この祭りではナイトグローを開ける。",
 "이번 축제에서 나이트 글로를 열 수 있습니다.")
add("home.alert.fiestaSoon.bri", "Days until the Bristol Balloon Festival: %@.", "Bristol Balon Festivali'ne kalan gün: %@.",
 "Tage bis zum Bristol-Ballonfestival: %@.", "Días para el Festival de Globos de Bristol: %@.", "ブリストル気球祭りまであと%@日。", "브리스톨 열기구 축제까지 남은 날: %@.")
add("home.alert.fiestaSoon.body.bri",
 "Get your fleet ready and sign hotel deals.",
 "Filonu hazırla, otellerle anlaş.",
 "Mach deine Flotte bereit und schließe Hotelverträge.",
 "Prepara tu flota y cierra tratos con hoteles.",
 "船団を準備し、ホテルと契約しよう。",
 "함대를 준비하고 호텔과 계약하세요.")
add("paper.briFestival", "The Bristol Balloon Festival begins", "Bristol Balon Festivali başladı", "Das Bristol-Ballonfestival beginnt",
 "Comienza el Festival de Globos de Bristol", "ブリストル気球祭りが開幕", "브리스톨 열기구 축제 개막")
add("paper.briFestival.sub",
 "Four days of morning and evening ascents, hundreds of balloons on the meadows.",
 "Dört gün boyunca sabah ve akşam kalkışları, çayırlarda yüzlerce balon.",
 "Vier Tage lang Aufstiege am Morgen und am Abend, Hunderte Ballons auf den Wiesen.",
 "Cuatro días de despegues por la mañana y por la tarde, cientos de globos en los prados.",
 "4日間、朝と夕方に離陸。草地には何百もの気球。",
 "나흘 동안 아침저녁 이륙, 초원에는 수백 대의 열기구.")
add("ledger.evening", "Evening ascent (festival)", "Akşam kalkışı (festival)", "Abendaufstieg (Festival)", "Despegue de la tarde (festival)", "夕方の離陸（祭り）", "저녁 이륙 (축제)")
add("event.eveningAscent",
 "Festival evening: your balloons went up a second time. Balloons: %1$@, evening passengers: %2$@, income: %3$@.",
 "Festival akşamı: balonların ikinci kez kalktı. Balon: %1$@, akşam yolcusu: %2$@, gelir: %3$@.",
 "Festivalabend: Deine Ballons stiegen ein zweites Mal auf. Ballons: %1$@, Abendpassagiere: %2$@, Einnahmen: %3$@.",
 "Tarde de festival: tus globos despegaron por segunda vez. Globos: %1$@, pasajeros de la tarde: %2$@, ingresos: %3$@.",
 "祭りの夕方：君の気球が2度目に飛び立った。気球：%1$@、夕方の乗客：%2$@、収入：%3$@。",
 "축제 저녁: 열기구가 두 번째로 이륙했습니다. 열기구: %1$@, 저녁 승객: %2$@, 수입: %3$@.")

# The Night Glow
add("glow.title", "Night Glow", "Gece Işıltısı", "Night Glow", "Night Glow", "ナイトグロー", "나이트 글로")
add("glow.bookedTitle", "Night Glow tonight!", "Gece Işıltısı bu gece!", "Heute Nacht Night Glow!", "¡Night Glow esta noche!", "今夜はナイトグロー！", "오늘 밤 나이트 글로!")
add("glow.bookedBody",
 "When you finish today, your balloons will stand on the festival meadow and fire their burners to music, then the fireworks go up. Balloons: %@.",
 "Bugünü tamamladığında balonların festival çayırında yerde durup müzikle brülörlerini yakacak, sonra havai fişekler atılacak. Balon: %@.",
 "Wenn du den Tag beendest, stehen deine Ballons auf der Festivalwiese und zünden ihre Brenner zur Musik, danach steigt das Feuerwerk. Ballons: %@.",
 "Cuando termines el día, tus globos estarán en el prado del festival encendiendo sus quemadores al ritmo de la música, y después habrá fuegos artificiales. Globos: %@.",
 "今日を終えると、君の気球が祭りの草地に並び、音楽に合わせてバーナーを燃やす。そのあと花火だ。気球：%@。",
 "오늘을 마치면 열기구들이 축제 초원에 서서 음악에 맞춰 버너를 켜고, 이어서 불꽃놀이가 펼쳐집니다. 열기구: %@.")
add("glow.intro",
 "On a festival night your balloons stand on the meadow and glow to music, firing their burners; fireworks at the end. Once per festival.",
 "Festival gecesi balonların çayırda yerde durur, müzikle brülörlerini yakıp ışıldar; sonunda havai fişekler. Her festivalde bir kez.",
 "In einer Festivalnacht stehen deine Ballons auf der Wiese und leuchten zur Musik, indem sie ihre Brenner zünden; zum Schluss ein Feuerwerk. Einmal pro Festival.",
 "En una noche de festival tus globos se quedan en el prado y brillan al ritmo de la música encendiendo sus quemadores; al final, fuegos artificiales. Una vez por festival.",
 "祭りの夜、君の気球が草地に並び、音楽に合わせてバーナーを燃やして輝く。最後は花火。祭りごとに1回。",
 "축제의 밤, 열기구들이 초원에 서서 음악에 맞춰 버너를 켜며 빛납니다. 마지막엔 불꽃놀이. 축제마다 한 번.")
add("glow.gainRep", "Popularity at once: %@", "Hemen popülerlik: %@", "Sofort Beliebtheit: %@", "Popularidad al instante: %@", "すぐに人気：%@", "즉시 인기: %@")
add("glow.gainPaper", "A headline the next morning and a postcard", "Ertesi sabah gazete manşeti ve bir kartpostal",
 "Eine Schlagzeile am nächsten Morgen und eine Postkarte", "Un titular a la mañana siguiente y una postal", "翌朝の新聞の見出しと絵はがき", "다음 날 아침 신문 머리기사와 엽서")
add("glow.gainGoal", "One of the festival chapter's goals", "Festival bölümünün hedeflerinden biri", "Eines der Ziele im Festival-Kapitel",
 "Uno de los objetivos del capítulo del festival", "祭りの章の目標のひとつ", "축제 챕터의 목표 중 하나")
add("glow.confirm", "Confirm and book: %@", "Onayla ve düzenle: %@", "Bestätigen und buchen: %@", "Confirmar y reservar: %@", "確定して予約：%@", "확정하고 예약: %@")
add("glow.why.nofest",
 "The Night Glow can only be held during the Bristol Balloon Festival.",
 "Gece Işıltısı yalnızca Bristol Balon Festivali günlerinde düzenlenir.",
 "Das Night Glow kann nur während des Bristol-Ballonfestivals stattfinden.",
 "El Night Glow solo se puede organizar durante el Festival de Globos de Bristol.",
 "ナイトグローはブリストル気球祭りの期間中しか開けない。",
 "나이트 글로는 브리스톨 열기구 축제 기간에만 열 수 있습니다.")
add("glow.why.booked", "The glow is tonight.", "Işıltı bu gece.", "Das Glow ist heute Nacht.", "El glow es esta noche.", "グローは今夜だ。", "글로는 오늘 밤입니다.")
add("glow.why.done",
 "This festival's Night Glow has been held. Wait for the next festival.",
 "Bu festivalin Gece Işıltısı yapıldı. Bir sonraki festivali bekle.",
 "Das Night Glow dieses Festivals hat stattgefunden. Warte auf das nächste Festival.",
 "El Night Glow de este festival ya se celebró. Espera al próximo festival.",
 "この祭りのナイトグローはもう開いた。次の祭りを待とう。",
 "이번 축제의 나이트 글로는 이미 열렸습니다. 다음 축제를 기다리세요.")
add("glow.why.show",
 "There's a Balloon Show tonight. Leave the glow for another night of the festival.",
 "Bu gece Balon Şöleni var. Işıltıyı festivalin başka bir gecesine bırak.",
 "Heute Nacht ist eine Ballonshow. Verschiebe das Glow auf eine andere Festivalnacht.",
 "Esta noche hay un Espectáculo de Globos. Deja el glow para otra noche del festival.",
 "今夜はバルーンショーがある。グローは祭りの別の夜にしよう。",
 "오늘 밤은 벌룬 쇼가 있습니다. 글로는 축제의 다른 밤으로 미루세요.")
add("glow.why.few", "You need flyable balloons: at least %@.", "Uçabilen balon gerekiyor: en az %@.", "Du brauchst flugbereite Ballons: mindestens %@.",
 "Necesitas globos listos para volar: al menos %@.", "飛べる気球が必要：最低%@機。", "비행 가능한 열기구가 필요합니다: 최소 %@대.")
add("glow.why.cash", "You need this much in the till: %@.", "Kasada şu kadar olmalı: %@.", "So viel muss in der Kasse sein: %@.",
 "Necesitas esto en caja: %@.", "金庫に必要な額：%@。", "금고에 이만큼 있어야 합니다: %@.")
add("glow.why.ok",
 "On a festival night your balloons glow to music on the meadow, then fireworks. Once per festival.",
 "Festival gecesi balonların çayırda müzikle ışıldar, sonra havai fişekler. Her festivalde bir kez.",
 "In einer Festivalnacht leuchten deine Ballons auf der Wiese zur Musik, danach Feuerwerk. Einmal pro Festival.",
 "En una noche de festival tus globos brillan con música en el prado, y luego fuegos artificiales. Una vez por festival.",
 "祭りの夜、草地で君の気球が音楽に合わせて輝き、そのあと花火。祭りごとに1回。",
 "축제의 밤, 초원에서 열기구가 음악에 맞춰 빛나고 이어서 불꽃놀이. 축제마다 한 번.")
add("glow.short.booked", "tonight", "bu gece", "heute Nacht", "esta noche", "今夜", "오늘 밤")
add("glow.short.done", "held at this festival", "bu festivalde yapıldı", "bei diesem Festival schon", "ya celebrado en este festival", "この祭りでは開催済み", "이번 축제에선 완료")
add("glow.short.few", "flyable balloons needed: %@", "gereken uçabilen balon: %@", "flugbereite Ballons nötig: %@", "globos listos necesarios: %@", "必要な飛べる気球：%@", "필요한 비행 가능 열기구: %@")
add("glow.short.show", "show tonight", "bu gece şölen var", "heute Nacht Show", "esta noche hay espectáculo", "今夜はショー", "오늘 밤 쇼")
add("glow.short.cash", "needed: %@", "gerekli: %@", "nötig: %@", "necesario: %@", "必要：%@", "필요: %@")
add("event.nightGlowTonight",
 "Tonight is the Night Glow: your balloons on the meadow will glow to music. Balloons: %@.",
 "Bu gece Gece Işıltısı var: balonların çayırda müzikle ışıldayacak. Balon: %@.",
 "Heute Nacht ist Night Glow: Deine Ballons leuchten auf der Wiese zur Musik. Ballons: %@.",
 "Esta noche es el Night Glow: tus globos brillarán con música en el prado. Globos: %@.",
 "今夜はナイトグロー：草地で君の気球が音楽に合わせて輝く。気球：%@。",
 "오늘 밤은 나이트 글로: 초원에서 열기구들이 음악에 맞춰 빛납니다. 열기구: %@.")
add("paper.nightGlow", "%@ lit up the festival night", "%@ festival gecesini aydınlattı", "%@ erhellt die Festivalnacht",
 "%@ iluminó la noche del festival", "%@が祭りの夜を照らす", "%@, 축제의 밤을 밝히다")
add("paper.nightGlow.sub",
 "At the Night Glow the balloons glowed to music, then came the fireworks. Balloons: %@.",
 "Gece Işıltısı'nda balonlar müzikle ışıldadı, ardından havai fişekler. Balon: %@.",
 "Beim Night Glow leuchteten die Ballons zur Musik, danach kam das Feuerwerk. Ballons: %@.",
 "En el Night Glow los globos brillaron con música, y luego llegaron los fuegos artificiales. Globos: %@.",
 "ナイトグローで気球が音楽に合わせて輝き、続いて花火が上がった。気球：%@。",
 "나이트 글로에서 열기구들이 음악에 맞춰 빛났고, 이어서 불꽃놀이가 펼쳐졌다. 열기구: %@.")

# Nights
add("night.glow.bri",
 "Festival night: on the meadow the balloons fire their burners.",
 "Festival gecesi: çayırda balonlar brülör yakıyor.",
 "Festivalnacht: Auf der Wiese zünden die Ballons ihre Brenner.",
 "Noche de festival: en el prado los globos encienden sus quemadores.",
 "祭りの夜：草地で気球がバーナーを燃やしている。",
 "축제의 밤: 초원에서 열기구들이 버너를 켜고 있습니다.")
add("paper.night.glow.bri", "Festival night all aglow", "Festival gecesi ışıl ışıl", "Festivalnacht im Lichterglanz",
 "Noche de festival resplandeciente", "光あふれる祭りの夜", "환하게 빛난 축제의 밤")
add("paper.night.glow.bri.sub",
 "On Ashton's meadow the balloons on the ground fired their burners.",
 "Ashton'un çayırında yerdeki balonlar brülörlerini yaktı.",
 "Auf Ashtons Wiese zündeten die Ballons am Boden ihre Brenner.",
 "En el prado de Ashton, los globos en tierra encendieron sus quemadores.",
 "アシュトンの草地で、地上の気球がバーナーを燃やした。",
 "애시턴의 초원에서 땅 위의 열기구들이 버너를 켰다.")
add("night.nglow", "Night Glow · balloons glowing to music: %@", "Gece Işıltısı · müzikle ışıldayan balon: %@",
 "Night Glow · Ballons, die zur Musik leuchten: %@", "Night Glow · globos que brillan con música: %@",
 "ナイトグロー・音楽に合わせて輝く気球：%@", "나이트 글로 · 음악에 맞춰 빛나는 열기구: %@")
add("paper.night.nglow", "The Night Glow lit up the festival meadow", "Gece Işıltısı festival çayırını aydınlattı",
 "Das Night Glow erhellte die Festivalwiese", "El Night Glow iluminó el prado del festival", "ナイトグローが祭りの草地を照らした", "나이트 글로가 축제 초원을 밝혔다")
add("paper.night.nglow.sub",
 "The balloons glowed to music on the ground, then the sky filled with fireworks.",
 "Balonlar yerde müzikle ışıldadı, sonra gökyüzü havai fişeklerle doldu.",
 "Die Ballons leuchteten am Boden zur Musik, dann füllte sich der Himmel mit Feuerwerk.",
 "Los globos brillaron en tierra al ritmo de la música, y luego el cielo se llenó de fuegos artificiales.",
 "気球は地上で音楽に合わせて輝き、やがて空は花火で満たされた。",
 "열기구들이 땅 위에서 음악에 맞춰 빛났고, 이어 하늘이 불꽃으로 가득 찼다.")
add("night.eve", "Festival evening: balloons in the evening ascent: %@", "Festival akşamı: akşam kalkışındaki balon: %@",
 "Festivalabend: Ballons beim Abendaufstieg: %@", "Tarde de festival: globos en el despegue de la tarde: %@",
 "祭りの夕方：夕方の離陸に参加した気球：%@", "축제 저녁: 저녁 이륙에 나선 열기구: %@")
add("paper.night.eve", "The sky filled again on the festival evening", "Festival akşamı gökyüzü yine doldu",
 "Am Festivalabend füllte sich der Himmel erneut", "El cielo volvió a llenarse en la tarde del festival", "祭りの夕方、空は再び気球で埋まった", "축제 저녁, 하늘이 다시 가득 찼다")
add("paper.night.eve.sub",
 "At the evening ascent the balloons rose over the Avon at sunset.",
 "Akşam kalkışında balonlar gün batımında Avon'un üstüne yükseldi.",
 "Beim Abendaufstieg stiegen die Ballons bei Sonnenuntergang über den Avon.",
 "En el despegue de la tarde, los globos se elevaron sobre el Avon al atardecer.",
 "夕方の離陸で、気球は夕日の中エイボン川の上へ昇っていった。",
 "저녁 이륙에서 열기구들이 해 질 녘 에이번강 위로 떠올랐다.")

# The paper
add("paper.mast.bri", "Avon Post", "Avon Postası", "Avon Post", "El Correo del Avon", "エイボン・ポスト", "에이번 포스트")
add("paper.price.bri", "20p", "20 peni", "20 Pence", "20 peniques", "20ペンス", "20펜스")
add("paper.airspace", "%@ flies into the airport's airspace", "%@ havalimanının göğüne girdi", "%@ fliegt in den Luftraum des Flughafens",
 "%@ entra en el espacio aéreo del aeropuerto", "%@、空港の空域に侵入", "%@, 공항 공역 침범")
add("paper.airspace.sub",
 "The Civil Aviation Authority fined the company. Fine: %@.",
 "Sivil Havacılık Otoritesi şirkete ceza kesti. Ceza: %@.",
 "Die Zivilluftfahrtbehörde verhängte eine Strafe gegen das Unternehmen. Strafe: %@.",
 "La Autoridad de Aviación Civil multó a la empresa. Multa: %@.",
 "民間航空局は同社に罰金を科した。罰金：%@。",
 "민간항공청은 회사에 벌금을 부과했다. 벌금: %@.")

# Flight
add("flight.tip.fog", "**Fog:** descend to see the landing field.", "**Sis var:** iniş alanını görmek için alçal.",
 "**Nebel:** Geh tiefer, um das Landefeld zu sehen.", "**Niebla:** desciende para ver el campo de aterrizaje.",
 "**霧だ：**着陸場を見るには高度を下げよう。", "**안개:** 착륙장을 보려면 고도를 낮추세요.")
add("flight.tip.air", "The red-striped zone is the airport's sky: stay out of it.", "Kırmızı çizgili bölge havalimanının göğü: içine girme.",
 "Die rot gestreifte Zone ist der Himmel des Flughafens: Halte dich fern.", "La zona de rayas rojas es el cielo del aeropuerto: no entres.",
 "赤い斜線の区域は空港の空だ。入ってはいけない。", "빨간 줄무늬 구역은 공항 하늘입니다: 들어가지 마세요.")
add("flight.tip.airspace", "**The airport's airspace!** Get below %@ m or you'll be fined.", "**Havalimanının hava sahası!** Şu yüksekliğin altına in, yoksa ceza yersin: %@ m.",
 "**Luftraum des Flughafens!** Sinke unter %@ m, sonst gibt es eine Strafe.", "**¡Espacio aéreo del aeropuerto!** Baja de %@ m o te multarán.",
 "**空港の空域だ！** %@ m以下に下りないと罰金だ。", "**공항 공역입니다!** %@ m 아래로 내려가지 않으면 벌금입니다.")
add("flight.tip.airspaceFined", "**You've violated the airspace.** The tower saw you: Civil Aviation will fine you. Descend.",
 "**Hava sahasını ihlal ettin.** Kule seni gördü: Sivil Havacılık ceza kesecek. Alçal.",
 "**Du hast den Luftraum verletzt.** Der Tower hat dich gesehen: Die Luftfahrtbehörde wird dich bestrafen. Geh tiefer.",
 "**Has violado el espacio aéreo.** La torre te ha visto: Aviación Civil te multará. Desciende.",
 "**空域に違反した。**管制塔に見られた。民間航空局から罰金が来る。高度を下げよう。",
 "**공역을 침범했습니다.** 관제탑이 봤습니다: 민간항공청이 벌금을 부과할 겁니다. 내려가세요.")
add("flight.airspaceLabel", "AIRSPACE · above %@ m", "HAVA SAHASI · %@ m üstü", "LUFTRAUM · über %@ m", "ESPACIO AÉREO · sobre %@ m", "空域・%@ m以上", "공역 · %@ m 이상")
add("flight.fogLabel", "FOG · %@ m · descend to see the landing field", "SİS · %@ m · iniş alanını görmek için alçal",
 "NEBEL · %@ m · tiefer gehen, um das Landefeld zu sehen", "NIEBLA · %@ m · desciende para ver el campo",
 "霧・%@ m・着陸場を見るには下降", "안개 · %@ m · 착륙장을 보려면 하강")
for k, en, tr, de, es, ja, ko in [
    ("bridge", "You hit the suspension bridge!", "Asma köprüye çarptın!", "Du bist gegen die Hängebrücke geprallt!", "¡Chocaste contra el puente colgante!", "吊り橋に衝突した！", "현수교에 부딪혔습니다!"),
    ("observatory", "You hit the observatory tower!", "Gözlem kulesine çarptın!", "Du bist gegen den Observatoriumsturm geprallt!", "¡Chocaste contra la torre del observatorio!", "展望塔に衝突した！", "전망탑에 부딪혔습니다!"),
    ("spire", "You hit a church spire!", "Kilise kulesine çarptın!", "Du bist gegen eine Kirchturmspitze geprallt!", "¡Chocaste contra la aguja de una iglesia!", "教会の尖塔に衝突した！", "교회 첨탑에 부딪혔습니다!"),
    ("mast", "You got caught in the tall ship's masts!", "Yelkenlinin direklerine takıldın!", "Du hast dich in den Masten des Großseglers verfangen!", "¡Te enganchaste en los mástiles del velero!", "帆船のマストに引っかかった！", "범선 돛대에 걸렸습니다!"),
    ("crane", "You hit a dock crane!", "Liman vincine çarptın!", "Du bist gegen einen Hafenkran geprallt!", "¡Chocaste contra una grúa del puerto!", "港のクレーンに衝突した！", "항구 크레인에 부딪혔습니다!"),
    ("tree", "You hit the trees!", "Ağaçlara çarptın!", "Du bist in die Bäume gekracht!", "¡Chocaste contra los árboles!", "木々に衝突した！", "나무에 부딪혔습니다!")]:
    add("flight.hit." + k,
        "**%s** The balloon is badly damaged and passengers are injured." % en,
        "**%s** Balon ağır hasarlı, yolcular yaralı." % tr,
        "**%s** Der Ballon ist schwer beschädigt, Passagiere sind verletzt." % de,
        "**%s** El globo está muy dañado y hay pasajeros heridos." % es,
        "**%s** 気球は大破し、乗客が負傷した。" % ja,
        "**%s** 열기구가 크게 파손되고 승객들이 다쳤습니다." % ko)
add("flight.land.farm.sheep", "**You landed in a field of sheep!** The farmer is not pleased.", "**Koyunların tarlasına indin!** Çiftçi hiç memnun değil.",
 "**Du bist auf einer Schafweide gelandet!** Der Bauer ist gar nicht erfreut.", "**¡Aterrizaste en un campo de ovejas!** El granjero no está nada contento.",
 "**羊の牧草地に着陸した！**農家はまったく喜んでいない。", "**양 목장에 착륙했습니다!** 농부가 전혀 달가워하지 않습니다.")
add("flight.land.farm.cow", "**You landed in a field of cows!** The farmer is not pleased.", "**İneklerin tarlasına indin!** Çiftçi hiç memnun değil.",
 "**Du bist auf einer Kuhweide gelandet!** Der Bauer ist gar nicht erfreut.", "**¡Aterrizaste en un campo de vacas!** El granjero no está nada contento.",
 "**牛の牧草地に着陸した！**農家はまったく喜んでいない。", "**소 목장에 착륙했습니다!** 농부가 전혀 달가워하지 않습니다.")
add("flight.land.mud", "**You landed in the tidal mud!** The passengers sank in up to their knees.", "**Gelgit çamuruna indin!** Yolcular dizlerine kadar çamura battı.",
 "**Du bist im Gezeitenschlamm gelandet!** Die Passagiere versanken bis zu den Knien.", "**¡Aterrizaste en el barro de la marea!** Los pasajeros se hundieron hasta las rodillas.",
 "**干潟の泥に着陸した！**乗客は膝まで泥に沈んだ。", "**갯벌 진흙에 착륙했습니다!** 승객들이 무릎까지 빠졌습니다.")
add("flight.land.airFine", "**You flew into the airport's sky.** Civil Aviation will fine you.", "**Havalimanının göğüne girdin.** Sivil Havacılık ceza kesecek.",
 "**Du bist in den Himmel des Flughafens geflogen.** Die Luftfahrtbehörde wird dich bestrafen.", "**Entraste en el cielo del aeropuerto.** Aviación Civil te multará.",
 "**空港の空に入ってしまった。**民間航空局から罰金が来る。", "**공항 하늘에 들어갔습니다.** 민간항공청이 벌금을 부과할 겁니다.")
add("event.fogFlown",
 "You flew on a foggy morning and landed safely. That's what flying in Bristol is about.",
 "Sisli bir sabah uçtun ve sağ salim indin. Bristol'de pilotluk budur.",
 "Du bist an einem nebligen Morgen geflogen und sicher gelandet. Genau darum geht es beim Fliegen in Bristol.",
 "Volaste una mañana de niebla y aterrizaste sano y salvo. De eso se trata volar en Bristol.",
 "霧の朝に飛び、無事に着陸した。ブリストルで飛ぶとはこういうことだ。",
 "안개 낀 아침에 비행하고 무사히 착륙했습니다. 브리스톨에서 조종한다는 게 바로 이런 거죠.")
add("event.farmLanding.sheep",
 "You landed in the sheep's field. The farmer ranted and raved; this calmed him down: %@.",
 "Koyunların tarlasına indin. Çiftçi bağırıp çağırdı, gönlünü şununla aldın: %@.",
 "Du bist auf der Schafweide gelandet. Der Bauer tobte; das hat ihn beruhigt: %@.",
 "Aterrizaste en el campo de ovejas. El granjero gritó y protestó; esto lo calmó: %@.",
 "羊の牧草地に着陸した。農家は怒鳴り散らしたが、これでなだめた：%@。",
 "양 목장에 착륙했습니다. 농부가 고래고래 소리쳤고, 이걸로 달랬습니다: %@.")
add("event.farmLanding.cow",
 "You landed in the cows' field. The farmer ranted and raved; this calmed him down: %@.",
 "İneklerin tarlasına indin. Çiftçi bağırıp çağırdı, gönlünü şununla aldın: %@.",
 "Du bist auf der Kuhweide gelandet. Der Bauer tobte; das hat ihn beruhigt: %@.",
 "Aterrizaste en el campo de vacas. El granjero gritó y protestó; esto lo calmó: %@.",
 "牛の牧草地に着陸した。農家は怒鳴り散らしたが、これでなだめた：%@。",
 "소 목장에 착륙했습니다. 농부가 고래고래 소리쳤고, 이걸로 달랬습니다: %@.")
add("event.mudLanding",
 "You landed in the tidal mud. The passengers sank into it, and their shoes could not be saved.",
 "Gelgit çamuruna indin. Yolcular çamura battı, ayakkabılar kurtarılamadı.",
 "Du bist im Gezeitenschlamm gelandet. Die Passagiere versanken darin, ihre Schuhe waren nicht mehr zu retten.",
 "Aterrizaste en el barro de la marea. Los pasajeros se hundieron y sus zapatos no se pudieron salvar.",
 "干潟の泥に着陸した。乗客は泥に沈み、靴は救えなかった。",
 "갯벌 진흙에 착륙했습니다. 승객들이 진흙에 빠졌고, 신발은 건지지 못했습니다.")
add("event.airspaceFine",
 "You flew into the airport's controlled airspace. Fine: %@.",
 "Havalimanının kontrollü hava sahasına girdin. Ceza: %@.",
 "Du bist in den kontrollierten Luftraum des Flughafens geflogen. Strafe: %@.",
 "Entraste en el espacio aéreo controlado del aeropuerto. Multa: %@.",
 "空港の管制空域に入った。罰金：%@。",
 "공항 관제 공역에 들어갔습니다. 벌금: %@.")

# Reviews: Bristol's versions of the lines that name a place, and the new landings
add("review.perfect.1.bri", "Sunrise over the suspension bridge and a perfect landing. The morning of my life.",
 "Asma köprünün üstünde gün doğumu ve kusursuz bir iniş. Hayatımın sabahıydı.",
 "Sonnenaufgang über der Hängebrücke und eine perfekte Landung. Der Morgen meines Lebens.",
 "Amanecer sobre el puente colgante y un aterrizaje perfecto. La mañana de mi vida.",
 "吊り橋の上の日の出、そして完璧な着陸。人生最高の朝だった。",
 "현수교 위의 일출과 완벽한 착륙. 내 인생 최고의 아침이었어요.")
add("review.crash.0.bri", "We crashed into the oak trees! Everyone's fine, but this is unacceptable.",
 "Meşe ağaçlarına çarptık! Herkes iyi ama bu kabul edilemez.",
 "Wir sind in die Eichen gekracht! Allen geht es gut, aber das ist inakzeptabel.",
 "¡Chocamos contra los robles! Todos estamos bien, pero esto es inaceptable.",
 "樫の木に突っ込んだ！みんな無事だけど、これは許されない。",
 "참나무에 부딪혔어요! 모두 무사하지만 이건 용납할 수 없어요.")
add("review.cheap.1.bri", "I paid {p}, maybe the best price in Bristol.", "{p} ödedim, Bristol'ün en iyi fiyatı bu olabilir.",
 "Ich habe {p} bezahlt, vielleicht der beste Preis in Bristol.", "Pagué {p}, quizá el mejor precio de Bristol.",
 "{p}払った。ブリストルで一番お得かも。", "{p} 냈어요. 브리스톨 최저가일지도요.")
add("review.general.0.bri", "You can't come to Bristol and not ride a balloon. This team is very professional.",
 "Bristol'e gelip balona binmemek olmaz. Bu ekip çok profesyonel.",
 "Man kann nicht nach Bristol kommen, ohne Ballon zu fahren. Dieses Team ist sehr professionell.",
 "No puedes venir a Bristol y no subir a un globo. Este equipo es muy profesional.",
 "ブリストルに来て気球に乗らないなんてありえない。とてもプロフェッショナルなチーム。",
 "브리스톨에 와서 열기구를 안 타면 안 되죠. 이 팀은 정말 프로예요.")
add("review.general.1.bri", "We were over Clifton as the morning fog lifted. And it didn't even rain, thank goodness.",
 "Sabah sisi kalkarken Clifton'ın üstündeydik. Yağmur da yağmadı, şükür.",
 "Wir waren über Clifton, als sich der Morgennebel lichtete. Und es hat nicht mal geregnet, Gott sei Dank.",
 "Estábamos sobre Clifton cuando se levantaba la niebla de la mañana. Y ni siquiera llovió, menos mal.",
 "朝霧が晴れていく中、クリフトンの上空にいた。雨も降らなくて本当によかった。",
 "아침 안개가 걷힐 때 클리프턴 위에 있었어요. 비도 안 와서 다행이었죠.")
add("review.panorama.0.bri", "Our photographer loved the shot from 550 meters. The gorge, the harbour and the Bristol Channel were at our feet.",
 "Fotoğrafçımız 550 metreden çektiği kareye bayıldı. Kanyon, liman ve Bristol Kanalı ayaklarımızın altındaydı.",
 "Unser Fotograf liebte die Aufnahme aus 550 Metern. Die Schlucht, der Hafen und der Bristolkanal lagen uns zu Füßen.",
 "A nuestro fotógrafo le encantó la foto desde 550 metros. La garganta, el puerto y el canal de Bristol a nuestros pies.",
 "カメラマンは550 mから撮った一枚に大喜び。渓谷も港もブリストル海峡も足元にあった。",
 "사진작가가 550 m에서 찍은 사진에 반했어요. 협곡, 항구, 브리스톨 해협이 발아래 있었죠.")
add("review.valley.0.bri", "We glided over the Avon, close enough to touch the bridge's towers!",
 "Avon'un üstünden süzüldük, köprünün kulelerine dokunacak gibiydik!",
 "Wir glitten über den Avon, so nah, dass wir die Brückentürme fast berühren konnten!",
 "¡Planeamos sobre el Avon, tan cerca que casi tocábamos las torres del puente!",
 "エイボン川の上を滑るように飛んで、橋の塔に手が届きそうだった！",
 "에이번강 위를 미끄러지듯 날았어요. 다리 탑에 손이 닿을 것 같았죠!")
add("review.valley.1.bri", "The low flight through the gorge was incredible; the gulls took off right beside us.",
 "Kanyonda alçak uçuş inanılmazdı, martılar hemen yanımızdan havalandı.",
 "Der Tiefflug durch die Schlucht war unglaublich; die Möwen flogen direkt neben uns auf.",
 "El vuelo bajo por la garganta fue increíble; las gaviotas alzaron el vuelo justo a nuestro lado.",
 "渓谷を低空で飛ぶのは最高だった。すぐそばからカモメが飛び立った。",
 "협곡을 낮게 나는 비행은 믿을 수 없었어요. 바로 옆에서 갈매기들이 날아올랐죠.")
add("review.xl.2.bri", "We saw the Star of the Avon from afar and booked. No regrets.",
 "Avon Yıldızı'nı uzaktan görüp rezervasyon yaptık, pişman değiliz.",
 "Wir haben den Stern des Avon von Weitem gesehen und gebucht. Wir bereuen nichts.",
 "Vimos la Estrella del Avon desde lejos y reservamos. No nos arrepentimos.",
 "遠くからエイボンの星を見て予約した。後悔なし。",
 "멀리서 에이번의 별을 보고 예약했어요. 후회 없어요.")
add("review.farm.0", "The balloon came down in the middle of a field and the animals scattered. The farmer shouted at us; the kids loved it.",
 "Balon bir tarlanın ortasına kondu, hayvanlar kaçıştı. Çiftçi bize bağırdı, çocuklar ise çok eğlendi.",
 "Der Ballon landete mitten auf einer Weide, und die Tiere stoben davon. Der Bauer schrie uns an; die Kinder fanden es toll.",
 "El globo bajó en medio de un campo y los animales salieron corriendo. El granjero nos gritó; a los niños les encantó.",
 "気球が畑の真ん中に降りて、動物たちが逃げ回った。農家には怒鳴られたけど、子どもたちは大喜び。",
 "열기구가 들판 한가운데 내려앉자 동물들이 흩어졌어요. 농부는 소리쳤지만 아이들은 신났죠.")
add("review.farm.1", "The animals in the field didn't like us much. The flight was lovely; the landing was a bit embarrassing.",
 "Tarladaki hayvanlar bizi pek sevmedi. Uçuş güzeldi, iniş biraz utanç vericiydi.",
 "Die Tiere auf der Weide mochten uns nicht besonders. Der Flug war schön, die Landung etwas peinlich.",
 "A los animales del campo no les gustamos mucho. El vuelo fue precioso; el aterrizaje, un poco vergonzoso.",
 "畑の動物たちには嫌われたみたい。フライトは素敵だったけど、着陸はちょっと恥ずかしかった。",
 "들판의 동물들이 우리를 별로 반기지 않았어요. 비행은 멋졌지만 착륙은 좀 민망했죠.")
add("review.mud.0", "We landed in the river mud. The view was wonderful, but my shoes stayed there.",
 "Nehrin çamuruna indik. Manzara harikaydı ama ayakkabılarım orada kaldı.",
 "Wir sind im Flussschlamm gelandet. Die Aussicht war herrlich, aber meine Schuhe sind dort geblieben.",
 "Aterrizamos en el barro del río. La vista era maravillosa, pero mis zapatos se quedaron allí.",
 "川の泥に着陸した。景色は最高だったけど、靴はそこに置いてきた。",
 "강 진흙에 착륙했어요. 경치는 훌륭했지만 제 신발은 거기 남았어요.")
add("review.mud.1", "The tide was out and the balloon sat down in the mud. We had breakfast at the hotel, muddy.",
 "Gelgit çekilmiş, balon çamura oturdu. Kahvaltıyı otelde yaptık, çamurlu.",
 "Es war Ebbe, und der Ballon setzte im Schlamm auf. Wir frühstückten im Hotel, voller Schlamm.",
 "Había marea baja y el globo se posó en el barro. Desayunamos en el hotel, llenos de barro.",
 "潮が引いていて、気球は泥の上に座り込んだ。泥だらけでホテルの朝食をとった。",
 "썰물이라 열기구가 진흙에 내려앉았어요. 진흙투성이로 호텔에서 아침을 먹었죠.")
add("holding.withdrawHintFx.bri",
 "The %1$@ cash box holds %2$@. Money you move is changed from pounds into euros (£0.85 = €1) on its way to the holding; holding money never goes back to the regions.",
 "%1$@ kasasında %2$@ var. Aktardığın para sterlinden euroya çevrilerek (£0,85 = €1) holdinge geçer; holding parası bölgelere geri dönmez.",
 "In der Kasse von %1$@ liegen %2$@. Überwiesenes Geld wird von Pfund in Euro umgerechnet (£0,85 = 1 €) und geht an die Holding; Holding-Geld fließt nie in die Regionen zurück.",
 "La caja de %1$@ tiene %2$@. El dinero que muevas se cambia de libras a euros (0,85 £ = 1 €) al pasar al holding; el dinero del holding nunca vuelve a las regiones.",
 "%1$@の金庫には%2$@ある。移した資金はポンドからユーロに両替され（£0.85＝€1）ホールディングスへ入る。ホールディングスの資金は地域へは戻らない。",
 "%1$@ 금고 잔액: %2$@. 옮긴 돈은 파운드에서 유로로 환전되어(£0.85 = €1) 지주회사로 가며, 지주회사 돈은 지역으로 돌아가지 않습니다.")
