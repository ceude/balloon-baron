from s1_ui import add

# Luxor (prototype v104): region, map, names
add("region.lux", "Luxor", "Luksor", "Luxor", "Luxor", "ルクソール", "룩소르")
add("pin.bri", "Bristol", "Bristol", "Bristol", "Bristol", "ブリストル", "브리스톨")
add("pin.bri.land", "England", "İngiltere", "England", "Inglaterra", "イングランド", "잉글랜드")
add("pin.mara", "Maasai Mara", "Maasai Mara", "Maasai Mara", "Maasai Mara", "マサイマラ", "마사이마라")
add("pin.mara.land", "Kenya", "Kenya", "Kenia", "Kenia", "ケニア", "케냐")
add("map.here.lux",
 "The Nile, the valley of the pharaohs and the toughest balloon market in the world.",
 "Nil, firavunların vadisi ve dünyanın en çetin balon pazarı.",
 "Der Nil, das Tal der Pharaonen und der härteste Ballonmarkt der Welt.",
 "El Nilo, el valle de los faraones y el mercado de globos más duro del mundo.",
 "ナイル、王家の谷、そして世界一厳しい気球市場。",
 "나일강, 파라오의 계곡, 그리고 세상에서 가장 험한 열기구 시장.")
add("map.openSub.lux",
 "The Nile, the Valley of the Kings, Hatshepsut's temple. The toughest balloon market in the world: strong rivals who join forces quickly. You start with €5,000. Entry fee %@ from the holding.",
 "Nil kıyısı, Krallar Vadisi, Hatşepsut Tapınağı. Dünyanın en çetin balon pazarı: rakipler güçlü ve çabuk birleşir. 5.000 euro ile başlarsın. Giriş bedeli %@ holding kasasından.",
 "Der Nil, das Tal der Könige, der Tempel der Hatschepsut. Der härteste Ballonmarkt der Welt: starke Konkurrenten, die sich schnell verbünden. Du startest mit 5.000 €. Einstiegsgebühr %@ aus der Holding.",
 "La orilla del Nilo, el Valle de los Reyes, el templo de Hatshepsut. El mercado de globos más duro del mundo: rivales fuertes que se unen enseguida. Empiezas con 5.000 €. Cuota de entrada: %@, a cargo del holding.",
 "ナイル河畔、王家の谷、ハトシェプスト女王葬祭殿。世界一厳しい気球市場だ。ライバルは強く、すぐに手を組む。5,000ユーロからのスタート。参入費%@はホールディングスから。",
 "나일강변, 왕가의 계곡, 하트셉수트 신전. 세상에서 가장 험한 열기구 시장으로, 경쟁사가 강하고 금세 손을 잡습니다. 5,000유로로 시작합니다. 진입 비용 %@, 지주회사에서 지급.")
add("map.lockedSub.lux",
 "Unlocks when you become baron of Albuquerque. On the banks of the Nile, above the valley of the pharaohs.",
 "Albuquerque baronu olunca açılır. Nil kıyısında, firavunların vadisi üstünde.",
 "Wird freigeschaltet, wenn du Baron von Albuquerque bist. Am Ufer des Nils, über dem Tal der Pharaonen.",
 "Se desbloquea cuando seas barón de Albuquerque. A orillas del Nilo, sobre el valle de los faraones.",
 "アルバカーキの男爵になると解放される。ナイルのほとり、王家の谷の上空。",
 "앨버커키의 남작이 되면 열립니다. 나일강 기슭, 파라오의 계곡 위.")
add("map.soonSub.bri",
 "Home of the world's biggest balloon makers and Europe's biggest balloon festival, the Bristol International Balloon Fiesta. Coming very soon.",
 "Dünyanın en büyük balon üreticilerinin şehri ve Avrupa'nın en büyük balon festivali, Bristol International Balloon Fiesta. Çok yakında.",
 "Heimat der größten Ballonbauer der Welt und von Europas größtem Ballonfestival, der Bristol International Balloon Fiesta. Schon sehr bald.",
 "La ciudad de los mayores fabricantes de globos del mundo y del mayor festival de globos de Europa, la Bristol International Balloon Fiesta. Muy pronto.",
 "世界最大級の気球メーカーの街で、ヨーロッパ最大の気球祭り、ブリストル国際バルーン・フィエスタの地。まもなく登場。",
 "세계 최대 열기구 제조사들의 도시이자 유럽 최대 열기구 축제, 브리스톨 인터내셔널 벌룬 피에스타의 고향. 곧 공개됩니다.")
add("map.soonSub.mara",
 "A sunrise safari over the savanna: lions, elephants and the great migration. Breakfast under an acacia after landing. Coming very soon.",
 "Savananın üstünde gün doğumu safarisi: aslanlar, filler ve büyük göç. İnişte akasya altında kahvaltı. Çok yakında.",
 "Eine Safari bei Sonnenaufgang über der Savanne: Löwen, Elefanten und die große Wanderung. Nach der Landung Frühstück unter einer Akazie. Schon sehr bald.",
 "Un safari al amanecer sobre la sabana: leones, elefantes y la gran migración. Desayuno bajo una acacia tras aterrizar. Muy pronto.",
 "サバンナの上を飛ぶ日の出のサファリ。ライオン、ゾウ、そして大移動。着陸後はアカシアの木の下で朝食。まもなく登場。",
 "사바나 위를 나는 일출 사파리. 사자, 코끼리, 그리고 대이동. 착륙 후엔 아카시아 아래에서 아침 식사. 곧 공개됩니다.")

for k, name in [("stone", "Memnon View Inn"), ("mansion", "Theban Garden Hotel"), ("cave", "Karnak Nile Lodge"), ("palace", "Nefertari Palace Resort")]:
    add("lux.hotel." + k, name, name, name, name, name, name)
for k, name in [("carpet", "Karkade Co."), ("wine", "Papyrus Bank"), ("bank", "Nile Cruise Line"), ("energy", "Scarab Mobile")]:
    add("lux.sponsor." + k, name, name, name, name, name, name)
add("lux.mission.valley", "Touch of the Nile", "Nil dokunuşu", "Gruß an den Nil", "Toque del Nilo", "ナイル・タッチ", "나일 터치")
add("lux.mission.desc.valley",
 "Drop below 150 m over the Nile and salute the feluccas.",
 "Nil'in üzerinde 150 m'nin altına alçal, felukaları selamla.",
 "Sinke über dem Nil unter 150 m und grüße die Feluken.",
 "Desciende por debajo de 150 m sobre el Nilo y saluda a las falucas.",
 "ナイルの上で高度150 m以下に下り、ファルーカに挨拶しよう。",
 "나일강 위에서 150 m 아래로 내려가 펠루카에 인사하세요.")

# Chapters
add("chapter.westBank", "West Bank", "Batı Yakası", "Westufer", "Ribera Oeste", "西岸", "서안")
add("chapter.nileWind", "Nile Wind", "Nil Rüzgârı", "Nilwind", "Viento del Nilo", "ナイルの風", "나일의 바람")
add("chapter.pharaohs", "Valley of the Pharaohs", "Firavunlar Vadisi", "Tal der Pharaonen", "Valle de los Faraones", "王家の谷", "파라오의 계곡")
add("chapter.baronLux", "Baron of Luxor", "Luksor Baronu", "Baron von Luxor", "Barón de Luxor", "ルクソールの男爵", "룩소르의 남작")
add("chapter.westBank.award",
 "The Governorate of Luxor named you the new face of the West Bank",
 "Luksor Valiliği seni Batı Yakası'nın yeni yüzü seçti",
 "Das Gouvernement Luxor kürte dich zum neuen Gesicht des Westufers",
 "La Gobernación de Luxor te nombró la nueva cara de la Ribera Oeste",
 "ルクソール県から西岸の新しい顔に選ばれた",
 "룩소르 주정부가 당신을 서안의 새 얼굴로 선정했습니다")
add("chapter.nileWind.award",
 "Egypt's Civil Aviation Authority named you the safest operator of the year",
 "Mısır Sivil Havacılık Otoritesi seni yılın en güvenli işletmesi seçti",
 "Ägyptens Zivilluftfahrtbehörde kürte dich zum sichersten Betreiber des Jahres",
 "La Autoridad de Aviación Civil de Egipto te nombró el operador más seguro del año",
 "エジプト民間航空局から年間最も安全な事業者に選ばれた",
 "이집트 민간항공청이 당신을 올해 가장 안전한 운영사로 선정했습니다")
add("chapter.pharaohs.award",
 "Egypt's Ministry of Tourism named you Balloon Company of the Year",
 "Mısır Turizm Bakanlığı seni yılın balon şirketi seçti",
 "Ägyptens Tourismusministerium kürte dich zur Ballonfirma des Jahres",
 "El Ministerio de Turismo de Egipto te nombró Empresa de Globos del Año",
 "エジプト観光省から年間最優秀気球会社に選ばれた",
 "이집트 관광부가 당신을 올해의 열기구 회사로 선정했습니다")
add("chapter.baronLux.award", "", "", "", "", "", "")
add("goal.fiesta.lux", "Fly in a Nile cruise season", "Bir Nil gemisi sezonunda uç", "Flieg in einer Nilkreuzfahrt-Saison", "Vuela en una temporada de cruceros del Nilo", "ナイルクルーズの季節に飛ぶ", "나일 크루즈 시즌에 비행하기")

for k, en, tr, de, es, ja, ko in [
    ("lux", ("Sky of the Nile", "You entered Luxor"), ("Nil'in göğü", "Luksor'a girdin"), ("Himmel des Nils", "Du bist in Luxor gestartet"), ("Cielo del Nilo", "Entraste en Luxor"), ("ナイルの空", "ルクソールに進出した"), ("나일의 하늘", "룩소르에 진출했습니다")),
    ("baronLux", ("Baron of Luxor", "The valley of the pharaohs is yours"), ("Luksor Baronu", "Firavunların vadisi senin"), ("Baron von Luxor", "Das Tal der Pharaonen gehört dir"), ("Barón de Luxor", "El valle de los faraones es tuyo"), ("ルクソールの男爵", "王家の谷はあなたのもの"), ("룩소르의 남작", "파라오의 계곡이 당신의 것")),
]:
    add(f"ach.{k}", en[0], tr[0], de[0], es[0], ja[0], ko[0])
    add(f"ach.{k}.d", en[1], tr[1], de[1], es[1], ja[1], ko[1])

# Hezarfen says goodbye at the border; the cruise season
add("hez.entered.lux",
 "Egypt, kid, Luxor! This is the toughest balloon market in the world. Every morning hundreds of tourists wait on the West Bank above the valley of the pharaohs, but Nabil Haddad's Theban Skies and his friends share them all. Here the rivals join forces against you very quickly, hotels sign their deals over tea, and Civil Aviation never takes its eyes off you. You start with %@ and one small balloon; the holding can't send money here. The Nile wind blows north down low and south higher up. Now and then the Nile cruise ships dock and the town fills with tourists. Be patient, kid: the Nile loves the patient. From here on my old friend Imhotep will show you the way.",
 "Mısır evlat, Luksor! Burası dünyanın en çetin balon pazarı. Batı Yakası'nda, firavunların vadisinin üstünde her sabah yüzlerce turist bekler ama hepsini Nabil Haddad'ın Theban Skies'ı ve onun dostları paylaşır. Burada rakipler sana karşı çok çabuk birleşir, oteller çayla anlaşır, Sivil Havacılık da gözünü senden ayırmaz. %@ ve küçük bir balonla başlıyorsun; holding buraya para gönderemez. Nil'in rüzgârı alçakta kuzeye, yukarıda güneye eser. Arada bir Nil gemileri yanaşır, kasaba turistle dolar. Sabırlı ol evlat, Nil sabırlıyı sever. Buradan sonra sana eski dostum İmhotep yol gösterecek.",
 "Ägypten, Lehrling, Luxor! Das ist der härteste Ballonmarkt der Welt. Jeden Morgen warten Hunderte Touristen am Westufer über dem Tal der Pharaonen, aber Nabil Haddads Theban Skies und seine Freunde teilen sie alle unter sich auf. Hier verbünden sich die Konkurrenten sehr schnell gegen dich, Hotels schließen ihre Verträge beim Tee, und die Luftfahrtbehörde lässt dich nie aus den Augen. Du startest mit %@ und einem kleinen Ballon; die Holding kann kein Geld hierher schicken. Der Nilwind weht unten nach Norden und weiter oben nach Süden. Ab und zu legen die Nilkreuzfahrtschiffe an, und die Stadt füllt sich mit Touristen. Sei geduldig, Lehrling: Der Nil liebt die Geduldigen. Von hier an zeigt dir mein alter Freund Imhotep den Weg.",
 "¡Egipto, aprendiz, Luxor! Este es el mercado de globos más duro del mundo. Cada mañana cientos de turistas esperan en la Ribera Oeste, sobre el valle de los faraones, pero Theban Skies de Nabil Haddad y sus amigos se los reparten todos. Aquí los rivales se unen contra ti muy rápido, los hoteles cierran sus tratos con té y Aviación Civil no te quita el ojo de encima. Empiezas con %@ y un globo pequeño; el holding no puede enviar dinero aquí. El viento del Nilo sopla hacia el norte abajo y hacia el sur más arriba. De vez en cuando atracan los cruceros del Nilo y el pueblo se llena de turistas. Ten paciencia, aprendiz: el Nilo ama a los pacientes. Desde aquí te guiará mi viejo amigo Imhotep.",
 "エジプトだ、弟子よ、ルクソールだ！ここは世界一厳しい気球市場だ。毎朝、王家の谷の上の西岸で何百人もの観光客が待っているが、ナビル・ハッダードのテーベ・スカイズとその仲間が全部分け合っている。ここではライバルがすぐに手を組んでお前に対抗し、ホテルは茶を飲みながら契約し、民間航空局はお前から目を離さん。%@と小さな気球ひとつで始まる。ホールディングスからここへは送金できん。ナイルの風は低空では北へ、上空では南へ吹く。時々ナイルのクルーズ船が着いて、町は観光客でいっぱいになる。辛抱するのだ、弟子よ。ナイルは辛抱強い者を愛する。ここから先は、わしの古い友人イムホテプが道を示してくれる。",
 "이집트라네, 제자여, 룩소르일세! 이곳은 세상에서 가장 험한 열기구 시장이지. 매일 아침 파라오의 계곡 위 서안에서 수백 명의 관광객이 기다리지만, 나빌 하다드의 테베 스카이스와 그 친구들이 모두 나눠 가진다네. 여기선 경쟁사들이 아주 빨리 손잡고 자네에게 맞서고, 호텔은 차를 마시며 계약하고, 민간항공청은 자네에게서 눈을 떼지 않을 걸세. 자금 %@, 그리고 작은 열기구 하나로 시작하네. 지주회사는 여기로 돈을 보낼 수 없네. 나일의 바람은 낮은 곳에선 북쪽으로, 높은 곳에선 남쪽으로 분다네. 가끔 나일 크루즈선이 들어오면 마을이 관광객으로 가득 차지. 인내하게, 제자여. 나일은 인내하는 자를 사랑한다네. 여기서부터는 내 오랜 친구 임호테프가 길을 안내할 걸세.")
add("hez.fiestaStarted.lux",
 "The Nile cruise ships have docked! For three days the riverbank is full of tourists, and everyone wants a sunrise balloon ride. Get all your balloons up, but Theban Skies will do the same.",
 "Nil gemileri yanaştı evlat! Üç gün boyunca kıyı turistle dolu, herkes sabah balonuna binmek istiyor. Bütün balonlarını havaya kaldır, ama Theban Skies da aynı şeyi yapacak.",
 "Die Nilkreuzfahrtschiffe haben angelegt! Drei Tage lang ist das Ufer voller Touristen, und alle wollen eine Ballonfahrt bei Sonnenaufgang. Schick alle deine Ballone hoch, aber Theban Skies wird dasselbe tun.",
 "¡Han atracado los cruceros del Nilo! Durante tres días la orilla está llena de turistas y todos quieren un vuelo en globo al amanecer. Sube todos tus globos, pero Theban Skies hará lo mismo.",
 "ナイルのクルーズ船が着いたぞ！3日間、川岸は観光客でいっぱいで、誰もが日の出の気球に乗りたがる。気球を全部飛ばせ。だがテーベ・スカイズも同じことをするだろう。",
 "나일 크루즈선이 들어왔네! 사흘 동안 강변은 관광객으로 가득하고 모두가 일출 열기구를 타고 싶어 하지. 열기구를 전부 띄우게. 하지만 테베 스카이스도 똑같이 할 걸세.")
add("home.alert.fiesta.lux", "Nile cruise ships in port, day %1$@/%2$@!", "Nil gemileri limanda, gün %1$@/%2$@!", "Nilschiffe im Hafen, Tag %1$@/%2$@!", "¡Cruceros del Nilo en el puerto, día %1$@/%2$@!", "ナイルのクルーズ船が入港中、%1$@/%2$@日目！", "나일 크루즈선 정박 중, %1$@/%2$@일차!")
add("home.alert.fiesta.body.lux", "The riverbank is full of tourists. Get all your balloons up.", "Kıyı turist dolu. Bütün balonlarını kaldır.", "Das Ufer ist voller Touristen. Schick alle deine Ballone hoch.", "La orilla está llena de turistas. Sube todos tus globos.", "川岸は観光客でいっぱい。全部の気球を上げよう。", "강변이 관광객으로 가득합니다. 모든 열기구를 띄우세요.")
add("home.alert.fiestaSoon.lux", "Days until the Nile ships dock: %@.", "Nil gemilerinin yanaşmasına kalan gün: %@.", "Tage, bis die Nilschiffe anlegen: %@.", "Días para que atraquen los cruceros del Nilo: %@.", "ナイルの船が着くまで：%@日。", "나일 크루즈선 입항까지: %@일.")
add("home.alert.fiestaSoon.body.lux", "Get your fleet ready and sign hotel deals.", "Filonu hazırla, otellerle anlaş.", "Mach deine Flotte bereit und schließ Hotelverträge.", "Prepara tu flota y cierra acuerdos con hoteles.", "フリートを整え、ホテルと契約しよう。", "기단을 준비하고 호텔과 제휴하세요.")

# Luxor's newcomers
add("hez.entrant.redSea",
 "Red Sea Balloon Co. has come to Luxor with the money of Hurghada's hotel chains! A big fleet and deep pockets. After Theban Skies this may be the most dangerous of them all.",
 "Red Sea Balloon Co., Hurghada'nın otel zincirlerinin parasıyla Luksor'a geldi! Filosu büyük, kesesi derin. Theban Skies'tan sonra en tehlikelisi bu olabilir.",
 "Red Sea Balloon Co. ist mit dem Geld der Hotelketten von Hurghada nach Luxor gekommen! Große Flotte, volle Kassen. Nach Theban Skies vielleicht die gefährlichste von allen.",
 "¡Red Sea Balloon Co. ha llegado a Luxor con el dinero de las cadenas hoteleras de Hurghada! Flota grande y bolsillos llenos. Después de Theban Skies, quizá la más peligrosa.",
 "レッドシー・バルーン社がフルガダのホテルチェーンの資金でルクソールに来た！大規模なフリートに潤沢な資金。テーベ・スカイズの次に危険な相手かもしれん。",
 "레드시 벌룬이 후르가다 호텔 체인의 돈을 등에 업고 룩소르에 왔네! 기단이 크고 자금도 두둑하지. 테베 스카이스 다음으로 가장 위험한 상대일지도 모르겠네.")
add("hez.entrant.felucca",
 "A discount outfit called Felucca Flights has opened. They'll sell tickets to the cruise tourists at half price, and they won't care much for the rules.",
 "Felucca Flights diye bir ucuzcu açıldı. Gemi turistlerine yarı fiyata bilet satacaklar, kuralları da pek takmayacaklar.",
 "Ein Billiganbieter namens Felucca Flights hat eröffnet. Sie verkaufen den Kreuzfahrttouristen Tickets zum halben Preis und nehmen es mit den Regeln nicht so genau.",
 "Ha abierto una empresa de precios bajos llamada Felucca Flights. Venderán billetes a mitad de precio a los turistas de los cruceros y no harán mucho caso de las normas.",
 "ファルーカ・フライツという格安業者が開業した。クルーズ客に半額でチケットを売り、規則などあまり気にせんだろう。",
 "펠루카 플라이츠라는 저가 업체가 문을 열었네. 크루즈 관광객에게 반값에 표를 팔고 규칙은 별로 신경 쓰지 않을 걸세.")
add("hez.entrant.hatshepsut",
 "A luxury boutique company called Hatshepsut Air has opened. Few balloons, very high prices, very popular. The rich tourists will go to them.",
 "Hatshepsut Air adında lüks bir butik şirket açıldı. Az balon, çok yüksek fiyat, çok popüler. Zengin turistler onlara gidecek.",
 "Eine Luxus-Boutiquefirma namens Hatshepsut Air hat eröffnet. Wenige Ballone, sehr hohe Preise, sehr beliebt. Die reichen Touristen werden zu ihnen gehen.",
 "Ha abierto una empresa boutique de lujo llamada Hatshepsut Air. Pocos globos, precios muy altos, muy popular. Los turistas ricos irán con ellos.",
 "ハトシェプスト・エアという高級ブティック会社が開業した。気球は少なく、値段はとても高く、大人気だ。裕福な観光客はそちらへ行くだろう。",
 "하트셉수트 에어라는 고급 부티크 회사가 문을 열었네. 열기구는 적고 가격은 아주 비싸며 인기가 많지. 부유한 관광객은 그쪽으로 갈 걸세.")
add("hez.entrant.karnak",
 "Investors from Cairo have founded Karnak Wings. A balanced, solid, patient rival.",
 "Kahireli yatırımcılar Karnak Wings'i kurdu. Dengeli, sağlam, sabırlı bir rakip.",
 "Investoren aus Kairo haben Karnak Wings gegründet. Ein ausgewogener, solider, geduldiger Konkurrent.",
 "Inversores de El Cairo han fundado Karnak Wings. Un rival equilibrado, sólido y paciente.",
 "カイロの投資家たちがカルナック・ウィングスを設立した。バランスのとれた、堅実で辛抱強いライバルだ。",
 "카이로 투자자들이 카르나크 윙스를 세웠네. 균형 잡히고 단단하며 끈기 있는 경쟁자라네.")

# Luxor's rival boss: Nabil Haddad of Theban Skies
add("boss.lux.name", "Nabil Haddad", "Nabil Haddad", "Nabil Haddad", "Nabil Haddad", "ナビル・ハッダード", "나빌 하다드")
add("boss.lux.title", "Owner of Theban Skies", "Theban Skies sahibi", "Inhaber von Theban Skies", "Dueño de Theban Skies", "テーベ・スカイズのオーナー", "테베 스카이스 대표")
add("boss.lux.hello",
 "Welcome, stranger. Nabil Haddad, Theban Skies. When my father inflated the first balloon on this West Bank, you weren't even born. Here every hotel, every guide, every felucca knows my name. I hear you won in Cappadocia and in America. The Nile is different. The Nile loves the patient and swallows the proud.",
 "Hoş geldin, yabancı. Nabil Haddad, Theban Skies. Babam bu Batı Yakası'nda ilk balonu şişirdiğinde sen daha doğmamıştın. Burada her otel, her rehber, her feluka benim adımı bilir. Kapadokya'da, Amerika'da kazanmışsın, duydum. Nil başkadır. Nil sabırlı olanı sever, kibirliyi yutar.",
 "Willkommen, Fremder. Nabil Haddad, Theban Skies. Als mein Vater an diesem Westufer den ersten Ballon aufblies, warst du noch nicht geboren. Hier kennt jedes Hotel, jeder Guide, jede Feluke meinen Namen. Du hast in Kappadokien und in Amerika gewonnen, hört man. Der Nil ist anders. Der Nil liebt die Geduldigen und verschlingt die Hochmütigen.",
 "Bienvenido, forastero. Nabil Haddad, Theban Skies. Cuando mi padre infló el primer globo en esta Ribera Oeste, tú ni habías nacido. Aquí cada hotel, cada guía, cada faluca conoce mi nombre. Dicen que ganaste en Capadocia y en Estados Unidos. El Nilo es distinto. El Nilo ama al paciente y se traga al soberbio.",
 "ようこそ、よそ者。ナビル・ハッダード、テーベ・スカイズだ。父がこの西岸で最初の気球を膨らませた時、君はまだ生まれてもいなかった。ここではどのホテルも、どのガイドも、どのファルーカも私の名を知っている。カッパドキアでもアメリカでも勝ったそうだな。ナイルは違う。ナイルは辛抱強い者を愛し、傲慢な者を呑み込む。",
 "어서 오게, 이방인. 나빌 하다드, 테베 스카이스일세. 우리 아버지가 이 서안에서 첫 열기구를 부풀렸을 때 자네는 태어나지도 않았지. 여기선 모든 호텔, 모든 가이드, 모든 펠루카가 내 이름을 알아. 카파도키아에서도, 미국에서도 이겼다고 들었네. 나일은 다르다네. 나일은 인내하는 자를 사랑하고 오만한 자를 삼키지.")
add("boss.lux.ch1",
 "Eight balloons? My fleet casts a shadow over the valley of the pharaohs. You still count customers; I count ships.",
 "Sekiz balon mu? Benim filom firavunların vadisini gölgeler. Sen hâlâ müşteri sayıyorsun, ben gemileri sayarım.",
 "Acht Ballone? Meine Flotte wirft ihren Schatten über das Tal der Pharaonen. Du zählst noch Kunden, ich zähle Schiffe.",
 "¿Ocho globos? Mi flota hace sombra sobre el valle de los faraones. Tú aún cuentas clientes; yo cuento barcos.",
 "8機だと？私のフリートは王家の谷に影を落とす。君はまだ客を数えているが、私は船を数える。",
 "여덟 대라고? 내 기단은 파라오의 계곡에 그늘을 드리우지. 자네는 아직 손님을 세지만 나는 배를 센다네.")
add("boss.lux.ch2",
 "When the Nile ships dock, whose balloons do the tourists ride? Have you ever looked? Mine. But you're not doing badly, I admit.",
 "Nil gemileri yanaştığında turistler kimin balonuna biniyor, hiç baktın mı? Benimkine. Ama fena gitmiyorsun, kabul.",
 "Wenn die Nilschiffe anlegen, in wessen Ballone steigen die Touristen? Hast du je hingesehen? In meine. Aber du machst dich nicht schlecht, zugegeben.",
 "Cuando atracan los barcos del Nilo, ¿en qué globos suben los turistas? ¿Te has fijado? En los míos. Pero no lo haces mal, lo admito.",
 "ナイルの船が着いた時、観光客は誰の気球に乗る？見たことがあるか？私のだ。だが、悪くはやっていない。認めよう。",
 "나일 배가 들어오면 관광객이 누구 열기구를 타는지 본 적 있나? 내 것이지. 그래도 자네, 나쁘지 않군. 인정하지.")
add("boss.lux.passed",
 "Yesterday you flew more passengers than me. That has happened twice in the history of Theban Skies. Both times I laughed last.",
 "Dün benden fazla yolcu uçurmuşsun. Theban Skies'ın tarihinde bu iki kez oldu. İkisinde de son gülen ben oldum.",
 "Gestern hast du mehr Passagiere geflogen als ich. Das ist in der Geschichte von Theban Skies zweimal passiert. Beide Male habe ich zuletzt gelacht.",
 "Ayer llevaste más pasajeros que yo. Eso ha pasado dos veces en la historia de Theban Skies. Las dos veces reí el último.",
 "昨日は私より多くの客を乗せたそうだな。テーベ・スカイズの歴史で二度あったことだ。二度とも最後に笑ったのは私だ。",
 "어제 나보다 승객을 더 태웠더군. 테베 스카이스 역사에 두 번 있었던 일이야. 두 번 모두 마지막에 웃은 건 나였지.")
add("boss.lux.hotel",
 "That hotel's manager is my cousin's brother-in-law. Here deals are made over tea, not on paper, stranger.",
 "O otelin müdürü benim kuzenimin kayınbiraderi. Burada anlaşmalar kâğıtla değil, çayla yapılır, yabancı.",
 "Der Manager dieses Hotels ist der Schwager meines Cousins. Hier werden Verträge beim Tee gemacht, nicht auf Papier, Fremder.",
 "El gerente de ese hotel es el cuñado de mi primo. Aquí los tratos se hacen con té, no con papel, forastero.",
 "あのホテルの支配人は私のいとこの義兄弟だ。ここでは契約は紙ではなく茶で結ぶものだ、よそ者。",
 "그 호텔 지배인은 내 사촌의 처남이라네. 여기선 계약을 종이가 아니라 차로 맺지, 이방인.")
add("boss.lux.poach",
 "I offered your pilot a house with a view of the Nile. Here loyalty is measured in bread.",
 "Pilotuna Nil manzaralı bir ev teklif ettim. Burada sadakat ekmekle ölçülür.",
 "Ich habe deinem Piloten ein Haus mit Nilblick angeboten. Hier misst man Treue in Brot.",
 "Le ofrecí a tu piloto una casa con vistas al Nilo. Aquí la lealtad se mide en pan.",
 "君のパイロットにナイルの見える家を提案した。ここでは忠誠はパンで量られる。",
 "자네 조종사에게 나일이 보이는 집을 제안했네. 여기선 충성심을 빵으로 잰다네.")
add("boss.lux.accident",
 "I hear you came down hard in a sugar-cane field. The Nile doesn't forgive. Neither do I.",
 "Şeker kamışı tarlasına sert indin, duydum. Nil affetmez. Ben de affetmem.",
 "Ich habe gehört, du bist hart in einem Zuckerrohrfeld gelandet. Der Nil verzeiht nicht. Ich auch nicht.",
 "Me dicen que aterrizaste bruscamente en un cañaveral. El Nilo no perdona. Yo tampoco.",
 "サトウキビ畑に強く降りたそうだな。ナイルは許さない。私もだ。",
 "사탕수수밭에 거칠게 내렸다고 들었네. 나일은 용서하지 않아. 나도 마찬가지고.")
add("boss.lux.deal",
 "Very well. The wind has turned. If you want to take over Theban Skies, let's talk. But don't change the name; it was my father's.",
 "Peki. Rüzgâr döndü. Theban Skies'ı devralmak istersen konuşalım. Ama adını değiştirme, babamın adıdır.",
 "Nun gut. Der Wind hat gedreht. Wenn du Theban Skies übernehmen willst, reden wir. Aber ändere den Namen nicht, er stammt von meinem Vater.",
 "Muy bien. El viento ha cambiado. Si quieres quedarte con Theban Skies, hablemos. Pero no le cambies el nombre; era el de mi padre.",
 "いいだろう。風向きが変わった。テーベ・スカイズを引き継ぎたいなら話そう。だが名前は変えるな。父の名だ。",
 "좋네. 바람이 바뀌었군. 테베 스카이스를 인수하고 싶다면 이야기하세. 하지만 이름은 바꾸지 말게. 우리 아버지 이름이야.")
add("boss.lux.gone",
 "I sold my last balloon. The West Bank is yours now. Some morning, fly a round over Deir el-Bahari for me too.",
 "Son balonumu da sattım. Batı Yakası artık senin. Bir sabah Deir el-Bahari'nin üstünde benim için de bir tur at.",
 "Ich habe meinen letzten Ballon verkauft. Das Westufer gehört jetzt dir. Flieg eines Morgens auch für mich eine Runde über Deir el-Bahari.",
 "Vendí mi último globo. La Ribera Oeste es tuya. Alguna mañana, da también una vuelta por mí sobre Deir el-Bahari.",
 "最後の気球も売った。西岸はもう君のものだ。いつかの朝、私のためにもデイル・エル・バハリの上を一周してくれ。",
 "마지막 열기구도 팔았네. 이제 서안은 자네 것이야. 어느 아침, 날 위해서도 데이르 엘 바하리 위를 한 바퀴 돌아 주게.")
add("boss.lux.baron",
 "Baron of Luxor. I don't know what my father would say. I say this: the Nile has accepted you. That is not easy.",
 "Luksor Baronu. Babam görse ne derdi bilmiyorum. Ben şunu diyorum: Nil seni kabul etti. Bu kolay değildir.",
 "Baron von Luxor. Ich weiß nicht, was mein Vater sagen würde. Ich sage: Der Nil hat dich angenommen. Das ist nicht leicht.",
 "Barón de Luxor. No sé qué diría mi padre. Yo digo esto: el Nilo te ha aceptado. Eso no es fácil.",
 "ルクソールの男爵か。父なら何と言ったかわからん。私はこう言おう。ナイルは君を受け入れた。容易なことではない。",
 "룩소르의 남작이라. 우리 아버지라면 뭐라고 했을지 모르겠군. 나는 이렇게 말하겠네. 나일이 자네를 받아들였어. 쉬운 일이 아니지.")

# Regional guides (prototype v105): Ben Franklin in Albuquerque, Imhotep in Luxor
add("guide.abq.name", "Ben Franklin", "Ben Franklin", "Ben Franklin", "Ben Franklin", "ベン・フランクリン", "벤 프랭클린")
add("guide.lux.name", "Imhotep", "İmhotep", "Imhotep", "Imhotep", "イムホテプ", "임호테프")
add("guide.abq.hello",
 "Hello, my young friend, I'm Ben Franklin. In 1783 I was in Paris when the Montgolfiers' balloon went up. Someone asked me, \"What good is a balloon?\" and I answered, \"What good is a newborn baby?\" Master Hezarfen has left you in my care; in Albuquerque I'll show you the way. Remember: time is money!",
 "Merhaba genç dostum, ben Ben Franklin. 1783'te Paris'te Montgolfier'lerin balonu havalandığında oradaydım. Biri \"Bu balonun ne faydası var?\" diye sordu, ben de \"Yeni doğmuş bir bebeğin ne faydası var?\" dedim. Hezarfen Usta seni bana emanet etti, Albuquerque'de sana ben yol göstereceğim. Unutma: vakit nakittir!",
 "Hallo, mein junger Freund, ich bin Ben Franklin. 1783 war ich in Paris, als der Ballon der Montgolfiers aufstieg. Jemand fragte mich: „Wozu ist ein Ballon gut?“ und ich antwortete: „Wozu ist ein neugeborenes Kind gut?“ Meister Hezarfen hat dich mir anvertraut; in Albuquerque zeige ich dir den Weg. Denk daran: Zeit ist Geld!",
 "Hola, joven amigo, soy Ben Franklin. En 1783 estaba en París cuando subió el globo de los Montgolfier. Alguien me preguntó: «¿Para qué sirve un globo?», y respondí: «¿Para qué sirve un recién nacido?». El maestro Hezarfen te ha dejado a mi cargo; en Albuquerque te mostraré el camino. Recuerda: ¡el tiempo es oro!",
 "やあ、若い友よ、ベン・フランクリンだ。1783年、モンゴルフィエ兄弟の気球が上がった時、私はパリにいた。ある人に「気球が何の役に立つのか」と聞かれ、「生まれたばかりの赤ん坊が何の役に立つのか」と答えたものだ。ヘザルフェン師匠が君を私に託した。アルバカーキでは私が道を示そう。覚えておきたまえ、時は金なりだ！",
 "안녕하신가, 젊은 친구. 나는 벤 프랭클린일세. 1783년 몽골피에 형제의 열기구가 떠오를 때 나는 파리에 있었지. 누군가 \"열기구가 무슨 쓸모가 있소?\" 하고 묻길래 \"갓난아기는 무슨 쓸모가 있소?\" 하고 답했다네. 자네 스승 헤자르펜께서 자네를 내게 맡기셨으니, 앨버커키에선 내가 길을 안내하겠네. 기억하게, 시간은 돈일세!")
add("guide.lux.hello",
 "Welcome, my young friend, I'm Imhotep. Four thousand years ago I drew the first step pyramid on this land and healed the sick. They call Hezarfen \"master of a thousand sciences\"; they used to call me that too. I never tried flying, but I know the sky well: the Nile wind helps the patient. In Luxor I'll show you the way.",
 "Hoş geldin genç dostum, ben İmhotep. Dört bin yıl önce bu topraklarda ilk basamaklı piramidi ben çizdim, hastaları ben iyileştirdim. Hezarfen'e \"bin ilmin ustası\" derler, bana da öyle derlerdi. Uçmayı hiç denemedim ama gökyüzünü iyi bilirim: Nil'in rüzgârı sabırlıya yardım eder. Luksor'da sana ben yol göstereceğim.",
 "Willkommen, mein junger Freund, ich bin Imhotep. Vor viertausend Jahren habe ich auf diesem Land die erste Stufenpyramide entworfen und die Kranken geheilt. Hezarfen nennt man „Meister der tausend Wissenschaften“; so nannte man auch mich. Fliegen habe ich nie versucht, aber den Himmel kenne ich gut: Der Nilwind hilft den Geduldigen. In Luxor zeige ich dir den Weg.",
 "Bienvenido, joven amigo, soy Imhotep. Hace cuatro mil años dibujé en esta tierra la primera pirámide escalonada y curé a los enfermos. A Hezarfen lo llaman «maestro de mil ciencias»; a mí también me llamaban así. Nunca intenté volar, pero conozco bien el cielo: el viento del Nilo ayuda al paciente. En Luxor te mostraré el camino.",
 "ようこそ、若い友よ、イムホテプだ。四千年前、この地で最初の階段ピラミッドを設計し、病人を癒やした。ヘザルフェンは「千の学問の師」と呼ばれるが、私もかつてそう呼ばれた。空を飛ぼうとしたことはないが、空のことはよく知っている。ナイルの風は辛抱強い者を助ける。ルクソールでは私が道を示そう。",
 "어서 오게, 젊은 친구. 나는 임호테프일세. 사천 년 전 이 땅에 첫 계단식 피라미드를 설계하고 병자를 고쳤지. 헤자르펜을 '천 가지 학문의 대가'라 부르는데, 나도 그렇게 불렸다네. 하늘을 날아 본 적은 없지만 하늘은 잘 알지. 나일의 바람은 인내하는 자를 돕는다네. 룩소르에선 내가 길을 안내하겠네.")
add("ceremony.baronLead.abq",
 "Day %1$@. Two of every three balloons in the sky over %2$@ fly the colors of %3$@. Ben Franklin wipes his spectacles: “In Paris in 1783 I watched the first balloon and said this baby would grow up. Well, it has grown up, my friend.”",
 "Gün %1$@. %2$@ göğündeki her üç balondan ikisi %3$@ renklerinde. Ben Franklin gözlüğünü siliyor: “1783'te Paris'te ilk balonu izlerken 'bu bebek büyüyecek' demiştim. İşte büyüdü, dostum.”",
 "Tag %1$@. Zwei von drei Ballonen am Himmel über %2$@ tragen die Farben von %3$@. Ben Franklin putzt seine Brille: „1783 in Paris sah ich den ersten Ballon und sagte, dieses Baby wird groß. Nun ist es groß geworden, mein Freund.“",
 "Día %1$@. Dos de cada tres globos en el cielo de %2$@ llevan los colores de %3$@. Ben Franklin limpia sus gafas: «En París, en 1783, vi el primer globo y dije que ese bebé crecería. Pues ha crecido, amigo mío».",
 "%1$@日目。%2$@の空を飛ぶ気球の3機に2機が%3$@の色だ。ベン・フランクリンが眼鏡を拭く。「1783年のパリで最初の気球を見て、この赤ん坊は育つと言った。ほら、育ったよ、友よ」",
 "%1$@일차. %2$@ 하늘의 열기구 세 대 중 두 대가 %3$@의 색을 달고 있습니다. 벤 프랭클린이 안경을 닦습니다. “1783년 파리에서 첫 열기구를 보며 이 아기는 자랄 거라 했지. 보게, 자랐네, 친구.”")
add("ceremony.baronLead.lux",
 "Day %1$@. Two of every three balloons in the sky over %2$@ fly the colors of %3$@. Imhotep smiles: “Four thousand years ago I raised stone toward the sky. You have raised people, my friend. The pharaohs would be jealous.”",
 "Gün %1$@. %2$@ göğündeki her üç balondan ikisi %3$@ renklerinde. İmhotep gülümsüyor: “Dört bin yıl önce taşı göğe doğru yükselttim. Sen insanları yükselttin, dostum. Firavunlar kıskanırdı.”",
 "Tag %1$@. Zwei von drei Ballonen am Himmel über %2$@ tragen die Farben von %3$@. Imhotep lächelt: „Vor viertausend Jahren habe ich Stein zum Himmel gehoben. Du hast Menschen gehoben, mein Freund. Die Pharaonen wären neidisch.“",
 "Día %1$@. Dos de cada tres globos en el cielo de %2$@ llevan los colores de %3$@. Imhotep sonríe: «Hace cuatro mil años elevé la piedra hacia el cielo. Tú has elevado personas, amigo mío. Los faraones sentirían envidia».",
 "%1$@日目。%2$@の空を飛ぶ気球の3機に2機が%3$@の色だ。イムホテプが微笑む。「四千年前、私は石を天へと積み上げた。君は人を空へ上げたのだ、友よ。ファラオたちも羨むだろう」",
 "%1$@일차. %2$@ 하늘의 열기구 세 대 중 두 대가 %3$@의 색을 달고 있습니다. 임호테프가 미소 짓습니다. “사천 년 전 나는 돌을 하늘로 쌓아 올렸지. 자네는 사람을 하늘로 올렸네, 친구. 파라오들도 부러워할 걸세.”")
add("ceremony.baronHint.lux",
 "The skies of three continents are yours. Bristol and the Maasai Mara will open on the map very soon.",
 "Üç kıtanın göğü senin. Bristol ve Maasai Mara çok yakında haritada açılacak.",
 "Der Himmel dreier Kontinente gehört dir. Bristol und die Maasai Mara öffnen sich bald auf der Karte.",
 "El cielo de tres continentes es tuyo. Bristol y el Maasai Mara se abrirán muy pronto en el mapa.",
 "三つの大陸の空はあなたのものだ。ブリストルとマサイマラもまもなく地図に登場する。",
 "세 대륙의 하늘이 당신의 것입니다. 브리스톨과 마사이마라가 곧 지도에 열립니다.")

# The civil aviation inspector (worn envelopes)
add("insp.name.cap", "Inspector Ekin Demir", "Müfettiş Ekin Demir", "Inspektorin Ekin Demir", "Inspectora Ekin Demir", "エキン・デミル検査官", "에킨 데미르 감독관")
add("insp.name.abq", "Inspector Karen Diaz", "Müfettiş Karen Diaz", "Inspektorin Karen Diaz", "Inspectora Karen Diaz", "カレン・ディアス検査官", "캐런 디아스 감독관")
add("insp.name.lux", "Inspector Omar Fathy", "Müfettiş Omar Fathy", "Inspektor Omar Fathy", "Inspector Omar Fathy", "オマル・ファトヒ検査官", "오마르 파트히 감독관")
add("insp.title.cap", "Directorate General of Civil Aviation", "Sivil Havacılık Genel Müdürlüğü", "Generaldirektion für Zivilluftfahrt", "Dirección General de Aviación Civil", "民間航空総局", "민간항공총국")
add("insp.title.abq", "FAA, Federal Aviation Administration", "FAA, Federal Havacılık İdaresi", "FAA, US-Bundesluftfahrtbehörde", "FAA, Administración Federal de Aviación", "FAA（米連邦航空局）", "FAA, 미국 연방항공청")
add("insp.title.lux", "Egyptian Civil Aviation Authority", "Mısır Sivil Havacılık Otoritesi", "Ägyptische Zivilluftfahrtbehörde", "Autoridad de Aviación Civil de Egipto", "エジプト民間航空局", "이집트 민간항공청")
add("insp.1.one",
 "Routine inspection. The envelope of your balloon %1$@ is below 30%%. Carrying passengers on worn fabric raises the accident risk. Please renew it. I'll check again in five days.",
 "Rutin denetim. %1$@ balonunuzun zarfı %%30'un altına düşmüş. Yıpranmış kumaşla yolcu taşımak kaza riskini artırır. Zarfı yenilemenizi rica ederim. Beş gün sonra tekrar bakacağım.",
 "Routinekontrolle. Die Hülle deines Ballons %1$@ liegt unter 30 %%. Mit abgenutztem Stoff Passagiere zu befördern erhöht das Unfallrisiko. Bitte erneuere sie. In fünf Tagen sehe ich wieder nach.",
 "Inspección rutinaria. La envoltura de tu globo %1$@ está por debajo del 30 %%. Llevar pasajeros con tela gastada aumenta el riesgo de accidente. Te ruego que la renueves. Volveré a revisarla en cinco días.",
 "定期検査です。気球%1$@の球皮が30%%を下回っています。傷んだ生地で乗客を運ぶと事故の危険が高まります。交換をお願いします。5日後にもう一度確認します。",
 "정기 점검입니다. 열기구 %1$@의 외피가 30%% 아래로 떨어졌습니다. 낡은 천으로 승객을 태우면 사고 위험이 높아집니다. 교체를 부탁드립니다. 5일 뒤에 다시 확인하겠습니다.")
add("insp.1.many",
 "Routine inspection. The envelopes of your balloons %1$@ are below 30%%. Carrying passengers on worn fabric raises the accident risk. Please renew them. I'll check again in five days.",
 "Rutin denetim. %1$@ balonlarınızın zarfları %%30'un altına düşmüş. Yıpranmış kumaşla yolcu taşımak kaza riskini artırır. Zarfları yenilemenizi rica ederim. Beş gün sonra tekrar bakacağım.",
 "Routinekontrolle. Die Hüllen deiner Ballone %1$@ liegen unter 30 %%. Mit abgenutztem Stoff Passagiere zu befördern erhöht das Unfallrisiko. Bitte erneuere sie. In fünf Tagen sehe ich wieder nach.",
 "Inspección rutinaria. Las envolturas de tus globos %1$@ están por debajo del 30 %%. Llevar pasajeros con tela gastada aumenta el riesgo de accidente. Te ruego que las renueves. Volveré a revisarlas en cinco días.",
 "定期検査です。気球%1$@の球皮が30%%を下回っています。傷んだ生地で乗客を運ぶと事故の危険が高まります。交換をお願いします。5日後にもう一度確認します。",
 "정기 점검입니다. 열기구 %1$@의 외피가 30%% 아래로 떨어졌습니다. 낡은 천으로 승객을 태우면 사고 위험이 높아집니다. 교체를 부탁드립니다. 5일 뒤에 다시 확인하겠습니다.")
add("insp.2.one",
 "My second warning. The envelope of %1$@ still hasn't been renewed. If it's the same at the next inspection, I'll have to write a fine.",
 "İkinci uyarım. %1$@ balonunun zarfı hâlâ yenilenmemiş. Bir dahaki denetimde aynı durumdaysa ceza yazmak zorundayım.",
 "Meine zweite Warnung. Die Hülle von %1$@ wurde immer noch nicht erneuert. Ist es bei der nächsten Kontrolle genauso, muss ich ein Bußgeld verhängen.",
 "Mi segundo aviso. La envoltura de %1$@ sigue sin renovarse. Si sigue igual en la próxima inspección, tendré que multarte.",
 "2度目の警告です。%1$@の球皮はまだ交換されていません。次の検査でも同じなら罰金を科さざるを得ません。",
 "두 번째 경고입니다. %1$@의 외피가 아직 교체되지 않았습니다. 다음 점검에서도 그대로면 벌금을 부과할 수밖에 없습니다.")
add("insp.2.many",
 "My second warning. The envelopes of %1$@ still haven't been renewed. If it's the same at the next inspection, I'll have to write a fine.",
 "İkinci uyarım. %1$@ balonlarının zarfları hâlâ yenilenmemiş. Bir dahaki denetimde aynı durumdaysa ceza yazmak zorundayım.",
 "Meine zweite Warnung. Die Hüllen von %1$@ wurden immer noch nicht erneuert. Ist es bei der nächsten Kontrolle genauso, muss ich ein Bußgeld verhängen.",
 "Mi segundo aviso. Las envolturas de %1$@ siguen sin renovarse. Si sigue igual en la próxima inspección, tendré que multarte.",
 "2度目の警告です。%1$@の球皮はまだ交換されていません。次の検査でも同じなら罰金を科さざるを得ません。",
 "두 번째 경고입니다. %1$@의 외피가 아직 교체되지 않았습니다. 다음 점검에서도 그대로면 벌금을 부과할 수밖에 없습니다.")
add("insp.3.one",
 "At this inspection I found the envelope of %1$@ worn again. Fine: %2$@. I'll write a fine at every inspection until it's renewed.",
 "Denetimde %1$@ balonunun zarfını yine yıpranmış buldum. Ceza: %2$@. Yenilenene kadar her denetimde ceza yazacağım.",
 "Bei dieser Kontrolle war die Hülle von %1$@ wieder abgenutzt. Bußgeld: %2$@. Bis sie erneuert ist, verhänge ich bei jeder Kontrolle eins.",
 "En esta inspección encontré otra vez gastada la envoltura de %1$@. Multa: %2$@. Multaré en cada inspección hasta que se renueve.",
 "今回の検査でも%1$@の球皮が傷んでいました。罰金：%2$@。交換されるまで検査のたびに罰金を科します。",
 "이번 점검에서도 %1$@의 외피가 낡은 상태였습니다. 벌금: %2$@. 교체될 때까지 점검 때마다 벌금을 부과하겠습니다.")
add("insp.3.many",
 "At this inspection I found the envelopes of %1$@ worn again. Fine: %2$@. I'll write a fine at every inspection until they're renewed.",
 "Denetimde %1$@ balonlarının zarflarını yine yıpranmış buldum. Ceza: %2$@. Yenilenene kadar her denetimde ceza yazacağım.",
 "Bei dieser Kontrolle waren die Hüllen von %1$@ wieder abgenutzt. Bußgeld: %2$@. Bis sie erneuert sind, verhänge ich bei jeder Kontrolle eins.",
 "En esta inspección encontré otra vez gastadas las envolturas de %1$@. Multa: %2$@. Multaré en cada inspección hasta que se renueven.",
 "今回の検査でも%1$@の球皮が傷んでいました。罰金：%2$@。交換されるまで検査のたびに罰金を科します。",
 "이번 점검에서도 %1$@의 외피가 낡은 상태였습니다. 벌금: %2$@. 교체될 때까지 점검 때마다 벌금을 부과하겠습니다.")

# Balloon equipment (fleet page)
add("equip.title", "Equipment", "Donanım", "Ausrüstung", "Equipamiento", "装備", "장비")
add("equip.burners.1", "Single burner", "Tek brülör", "Einzelbrenner", "Quemador simple", "シングルバーナー", "싱글 버너")
add("equip.burners.2", "Double burner", "Çift brülör", "Doppelbrenner", "Quemador doble", "ダブルバーナー", "더블 버너")
add("equip.burners.3", "Triple burner", "Üçlü brülör", "Dreifachbrenner", "Quemador triple", "トリプルバーナー", "트리플 버너")
add("equip.ventShort", "turning vent", "dönüş valfi", "Drehventil", "válvula de giro", "回転ベント", "회전 밸브")
add("equip.single.d", "Standard burner.", "Standart brülör.", "Standardbrenner.", "Quemador estándar.", "標準のバーナー。", "기본 버너.")
add("equip.double.d",
 "If one burner clogs or goes out, you land safely on the other. Accident risk %1$@%% lower, the balloon heats and climbs %2$@%% faster. Passengers love a safe balloon.",
 "Bir brülör tıkansa ya da sönse diğeriyle güvenle inersin. Kaza riski %%%1$@ daha düşük, balon %%%2$@ daha hızlı ısınır ve tırmanır. Yolcular güvenli balonu sever.",
 "Verstopft oder erlischt ein Brenner, landest du sicher mit dem anderen. Unfallrisiko %1$@ %% niedriger, der Ballon heizt und steigt %2$@ %% schneller. Passagiere lieben einen sicheren Ballon.",
 "Si un quemador se atasca o se apaga, aterrizas seguro con el otro. Riesgo de accidente un %1$@ %% menor; el globo se calienta y sube un %2$@ %% más rápido. A los pasajeros les encanta un globo seguro.",
 "片方のバーナーが詰まったり消えたりしても、もう片方で安全に着陸できる。事故リスクは%1$@%%低下、気球は%2$@%%速く温まり上昇する。乗客は安全な気球が大好きだ。",
 "버너 하나가 막히거나 꺼져도 다른 하나로 안전하게 내릴 수 있습니다. 사고 위험 %1$@%% 감소, 열기구가 %2$@%% 더 빨리 데워지고 상승합니다. 승객은 안전한 열기구를 좋아하죠.")
add("equip.triple.d",
 "The choice of big baskets. Accident risk %1$@%% lower than a single burner, the balloon heats and climbs %2$@%% faster.",
 "Büyük sepetlerin tercihi. Kaza riski tek brülöre göre %%%1$@ daha düşük, balon %%%2$@ daha hızlı ısınır ve tırmanır.",
 "Die Wahl großer Körbe. Unfallrisiko %1$@ %% niedriger als mit einem Brenner, der Ballon heizt und steigt %2$@ %% schneller.",
 "La elección de las cestas grandes. Riesgo de accidente un %1$@ %% menor que con un quemador; el globo se calienta y sube un %2$@ %% más rápido.",
 "大きなバスケットの定番。事故リスクはシングルより%1$@%%低く、気球は%2$@%%速く温まり上昇する。",
 "대형 바스켓의 선택. 싱글 버너보다 사고 위험이 %1$@%% 낮고, 열기구가 %2$@%% 더 빨리 데워지고 상승합니다.")
add("equip.vent", "Turning vent", "Dönüş valfi", "Drehventil", "Válvula de giro", "回転ベント", "회전 밸브")
add("equip.vent.d",
 "A vent in the side of the envelope turns the balloon on its axis. On a windy landing the wide side of the basket comes to the front: a hard landing is less likely, and on yellow and red days the accident risk is %@%% lower.",
 "Zarfın yanındaki valf balonu kendi ekseninde döndürür. Rüzgârlı inişte sepetin geniş yüzü öne gelir: sert iniş daha zor, sarı ve kırmızı bayrakta kaza riski %%%@ daha düşük.",
 "Ein Ventil in der Seite der Hülle dreht den Ballon um seine Achse. Bei windiger Landung kommt die breite Seite des Korbs nach vorn: Eine harte Landung wird unwahrscheinlicher, und bei gelber und roter Flagge sinkt das Unfallrisiko um %@ %%.",
 "Una válvula en el costado de la envoltura hace girar el globo sobre su eje. En un aterrizaje con viento, el lado ancho de la cesta va delante: un aterrizaje brusco es menos probable y con bandera amarilla y roja el riesgo de accidente baja un %@ %%.",
 "球皮の側面にあるベントで気球をその場で回転させる。風のある着陸ではバスケットの広い面が前に来る。ハードランディングしにくくなり、黄色と赤の旗の日の事故リスクが%@%%下がる。",
 "외피 옆의 밸브가 열기구를 제자리에서 돌립니다. 바람 부는 날 착륙할 때 바스켓의 넓은 면이 앞으로 와서 거친 착륙이 줄고, 노란 깃발과 빨간 깃발 날의 사고 위험이 %@%% 낮아집니다.")
add("equip.fit", "Fit %@", "Tak %@", "Einbauen %@", "Instalar %@", "取り付け %@", "장착 %@")

# Holding desks 5 and 6 (prototype v105)
add("hq.records", "Record attempts", "Rekor denemeleri", "Rekordversuche", "Récords", "記録挑戦", "기록 도전")
add("hq.shapes", "Sponsored shapes", "Sponsorlu şekiller", "Sponsorformen", "Formas patrocinadas", "スポンサー気球", "스폰서 열기구")
add("hq.recordsTitle", "Record attempts", "Rekor denemeleri", "Rekordversuche", "Intentos de récord", "記録への挑戦", "기록 도전")
add("hq.shapesTitle", "Sponsored special shapes", "Sponsorlu özel şekiller", "Gesponserte Sonderformen", "Formas especiales patrocinadas", "スポンサーの特殊形状気球", "스폰서 특수 형태 열기구")
add("hq.s.luxFirst", "Open Luxor first", "Önce Luksor'u açmalısın", "Erst Luxor eröffnen", "Primero abre Luxor", "まずルクソールを開こう", "먼저 룩소르를 여세요")
add("hq.s.recordRun", "%1$@, days: %2$@", "%1$@, gün: %2$@", "%1$@, Tage: %2$@", "%1$@, días: %2$@", "%1$@、残り%2$@日", "%1$@, 남은 일수: %2$@")
add("hq.s.records", "Records: %1$@/%2$@", "Rekor: %1$@/%2$@", "Rekorde: %1$@/%2$@", "Récords: %1$@/%2$@", "記録：%1$@/%2$@", "기록: %1$@/%2$@")
add("hq.s.shapeRun", "%1$@, days: %2$@", "%1$@, gün: %2$@", "%1$@, Tage: %2$@", "%1$@, días: %2$@", "%1$@、残り%2$@日", "%1$@, 남은 일수: %2$@")
add("hq.s.noShape", "No contract", "Sözleşme yok", "Kein Vertrag", "Sin contrato", "契約なし", "계약 없음")
add("record.altitude", "Altitude record", "İrtifa rekoru", "Höhenrekord", "Récord de altitud", "高度記録", "고도 기록")
add("record.world", "Nonstop around the world", "Molasız dünya turu", "Nonstop um die Welt", "Vuelta al mundo sin escalas", "無着陸世界一周", "무착륙 세계 일주")
add("record.altitude.d",
 "Into the stratosphere with a special balloon and a pressurized cabin: the world record is 21,027 meters. The pilot flies with an oxygen mask, and the cabin is heated so it doesn't freeze.",
 "Basınçlı kabinli özel bir balonla stratosfere: dünya rekoru 21.027 metre. Pilot oksijen maskesiyle uçar, kabin donmasın diye ısıtılır.",
 "Mit einem Spezialballon und Druckkabine in die Stratosphäre: Der Weltrekord liegt bei 21.027 Metern. Der Pilot fliegt mit Sauerstoffmaske, die Kabine wird beheizt, damit sie nicht einfriert.",
 "A la estratosfera con un globo especial y cabina presurizada: el récord mundial es de 21.027 metros. El piloto vuela con máscara de oxígeno y la cabina se calienta para que no se congele.",
 "与圧キャビン付きの特別な気球で成層圏へ。世界記録は21,027メートル。パイロットは酸素マスクを着け、キャビンは凍らないよう暖められる。",
 "여압 캐빈을 단 특수 열기구로 성층권까지. 세계 기록은 21,027미터. 조종사는 산소마스크를 쓰고 비행하며, 캐빈은 얼지 않게 데웁니다.")
add("record.world.d",
 "Take-off in the Swiss Alps, 20 days in the jet streams, landing in the Egyptian desert. It was first done in 1999.",
 "İsviçre Alpleri'nden kalkış, 20 gün jet akımlarında, iniş Mısır çölünde. İlk kez 1999'da başarılmıştı.",
 "Start in den Schweizer Alpen, 20 Tage in den Jetstreams, Landung in der ägyptischen Wüste. Zum ersten Mal gelang es 1999.",
 "Despegue en los Alpes suizos, 20 días en las corrientes en chorro, aterrizaje en el desierto egipcio. Se logró por primera vez en 1999.",
 "スイス・アルプスから離陸し、ジェット気流に乗って20日、エジプトの砂漠に着陸。1999年に初めて達成された。",
 "스위스 알프스에서 이륙해 제트기류 속에서 20일, 이집트 사막에 착륙. 1999년에 처음 성공했습니다.")
add("record.success",
 "The record is yours: %@! Your company's name is in newspapers all over the world. Tourists in every region are asking for you now.",
 "Rekor senin: %@! Şirketinin adı bütün dünya gazetelerinde. Turistler artık her bölgede seni soruyor.",
 "Der Rekord gehört dir: %@! Der Name deiner Firma steht in Zeitungen auf der ganzen Welt. Touristen in jeder Region fragen jetzt nach dir.",
 "¡El récord es tuyo: %@! El nombre de tu empresa está en periódicos de todo el mundo. Ahora los turistas de todas las regiones preguntan por ti.",
 "記録はあなたのものだ：%@！会社の名前が世界中の新聞に載っている。今やどの地域の観光客もあなたを指名する。",
 "기록은 자네 것일세: %@! 회사 이름이 전 세계 신문에 실렸네. 이제 모든 지역의 관광객이 자네를 찾는다네.")
add("record.fail",
 "The attempt fell short: %@. The pilot came down safe and sound and the balloon was saved, but the record didn't fall this time. We can try again if you like.",
 "Deneme yarıda kaldı: %@. Pilot sağ salim indi, balon da kurtarıldı ama rekor bu sefer kırılamadı. İstersen yeniden deneriz.",
 "Der Versuch ist gescheitert: %@. Der Pilot ist heil gelandet und der Ballon gerettet, aber diesmal fiel der Rekord nicht. Wenn du willst, versuchen wir es noch einmal.",
 "El intento se quedó corto: %@. El piloto bajó sano y salvo y el globo se salvó, pero esta vez no cayó el récord. Si quieres, lo intentamos de nuevo.",
 "挑戦は届かなかった：%@。パイロットは無事に降り、気球も回収できたが、今回は記録にならなかった。よければもう一度挑もう。",
 "도전이 아쉽게 끝났네: %@. 조종사는 무사히 내렸고 열기구도 건졌지만 이번엔 기록을 깨지 못했네. 원한다면 다시 도전하세.")
add("holding.rec.hint",
 "Sponsored world record attempts. Success raises demand in every region for good. If it fails, the money is gone, but you can try again.",
 "Sponsorlu dünya rekoru denemeleri. Başarı bütün bölgelerde talebi kalıcı olarak artırır. Başarısız olursa para gider ama tekrar denenebilir.",
 "Gesponserte Weltrekordversuche. Ein Erfolg steigert die Nachfrage in allen Regionen dauerhaft. Scheitert er, ist das Geld weg, aber du kannst es noch einmal versuchen.",
 "Intentos de récord mundial patrocinados. El éxito sube la demanda en todas las regiones para siempre. Si falla, el dinero se pierde, pero puedes volver a intentarlo.",
 "スポンサー付きの世界記録への挑戦。成功すればすべての地域で需要が永続的に増える。失敗すれば資金は失うが、再挑戦できる。",
 "스폰서가 붙은 세계 기록 도전. 성공하면 모든 지역의 수요가 영구히 늘어납니다. 실패하면 돈은 사라지지만 다시 도전할 수 있습니다.")
add("holding.rec.locked",
 "Record projects open once you have entered Luxor. Open Luxor first.",
 "Rekor projeleri Luksor'a girdikten sonra açılır. Önce Luksor'u açmalısın.",
 "Rekordprojekte öffnen sich, sobald du in Luxor eingestiegen bist. Eröffne erst Luxor.",
 "Los proyectos de récord se abren cuando entras en Luxor. Primero abre Luxor.",
 "記録プロジェクトはルクソールに進出すると開く。まずルクソールを開こう。",
 "기록 프로젝트는 룩소르에 진출하면 열립니다. 먼저 룩소르를 여세요.")
add("holding.rec.kicker", "Record attempt", "Rekor denemesi", "Rekordversuch", "Intento de récord", "記録挑戦", "기록 도전")
add("holding.rec.cta", "Start the attempt", "Denemeyi başlat", "Versuch starten", "Empezar el intento", "挑戦を始める", "도전 시작")
add("holding.rec.again", "Beat your record", "Rekoru geliştir", "Rekord verbessern", "Superar tu récord", "記録を更新する", "기록 경신")
add("holding.rec.yours", "The record is yours", "Rekor senin", "Der Rekord gehört dir", "El récord es tuyo", "記録はあなたのもの", "기록은 당신의 것")
add("holding.rec.lockNote", "Open Luxor first", "Önce Luksor'u açmalısın", "Erst Luxor eröffnen", "Primero abre Luxor", "まずルクソールを開こう", "먼저 룩소르를 여세요")
add("holding.rec.oneAtATime", "One attempt at a time", "Aynı anda bir deneme", "Immer nur ein Versuch", "Un intento a la vez", "挑戦は一度にひとつ", "한 번에 하나의 도전")
add("holding.rec.active", "Getting ready · days left: %@", "Hazırlanıyor · kalan gün: %@", "In Vorbereitung · Resttage: %@", "En preparación · días restantes: %@", "準備中・残り%@日", "준비 중 · 남은 일수: %@")
add("holding.chip.prep", "Preparation: %@ days", "Hazırlık: %@ gün", "Vorbereitungstage: %@", "Preparación: %@ días", "準備：%@日", "준비: %@일")
add("holding.chip.odds", "Success chance %@", "Başarı şansı %@", "Erfolgschance %@", "Probabilidad de éxito %@", "成功率%@", "성공 확률 %@")
add("holding.chip.allDemandLasting", "Demand +%@ for good", "Talep kalıcı +%@", "Nachfrage dauerhaft +%@", "Demanda +%@ para siempre", "需要が永続的に+%@", "수요 영구 +%@")
add("holding.shape.hint",
 "A brand pays the holding every day to fly a giant balloon shaped like its product over your region. Tourists don't like the ad: while the contract runs, popularity in that region drops a little every day. One contract at a time.",
 "Bir marka kendi ürünü biçiminde dev bir balonu senin bölgende uçurman için holdinge her gün para öder. Turistler reklamı sevmez: sözleşme sürdükçe o bölgede popülerlik her gün biraz düşer. Aynı anda bir sözleşme.",
 "Eine Marke zahlt der Holding jeden Tag dafür, dass du einen Riesenballon in Form ihres Produkts über deiner Region fliegst. Touristen mögen die Werbung nicht: Solange der Vertrag läuft, sinkt die Beliebtheit dort jeden Tag ein wenig. Immer nur ein Vertrag.",
 "Una marca paga al holding cada día para que vueles sobre tu región un globo gigante con la forma de su producto. A los turistas no les gusta el anuncio: mientras dure el contrato, la popularidad en esa región baja un poco cada día. Un contrato a la vez.",
 "ブランドが自社製品の形をした巨大気球をあなたの地域で飛ばし、その対価として毎日ホールディングスに支払う。観光客は広告を好まないため、契約中はその地域の人気が毎日少し下がる。契約は一度にひとつ。",
 "브랜드가 자사 제품 모양의 거대 열기구를 당신 지역에 띄우는 대가로 매일 지주회사에 돈을 냅니다. 관광객은 광고를 싫어해서, 계약 기간 동안 그 지역 인기가 매일 조금씩 떨어집니다. 한 번에 하나의 계약.")
add("holding.shape.kicker", "Ad balloon", "Reklam balonu", "Werbeballon", "Globo publicitario", "広告気球", "광고 열기구")
add("holding.shape.desc",
 "A specially sewn shaped envelope in the brand's colors.",
 "Markanın renklerinde, özel olarak dikilmiş şekilli zarf.",
 "Eine eigens genähte Sonderform in den Farben der Marke.",
 "Una envoltura de forma especial cosida a medida con los colores de la marca.",
 "ブランドカラーで特別に縫製された特殊形状の球皮。",
 "브랜드 색으로 특별히 재봉한 특수 형태 외피.")
add("holding.shape.cta", "Sign", "İmzala", "Unterschreiben", "Firmar", "契約する", "계약")
add("holding.shape.oneAtATime", "One contract at a time", "Aynı anda bir sözleşme", "Immer nur ein Vertrag", "Un contrato a la vez", "契約は一度にひとつ", "한 번에 하나의 계약")
add("holding.shape.active", "Flying over %1$@ · days left: %2$@", "%1$@ üstünde uçuyor · kalan gün: %2$@", "Fliegt über %1$@ · Resttage: %2$@", "Volando sobre %1$@ · días restantes: %2$@", "%1$@の上空を飛行中・残り%2$@日", "%1$@ 상공 비행 중 · 남은 일수: %2$@")
add("holding.chip.perDay", "To the holding: %@/day", "Holdinge %@/gün", "An die Holding: %@/Tag", "Al holding: %@/día", "ホールディングスへ%@/日", "지주회사 수입: %@/일")
add("holding.chip.repDay", "Popularity per day −%@", "Popülerlik günde −%@", "Beliebtheit pro Tag −%@", "Popularidad por día −%@", "人気：1日−%@", "인기 하루 −%@")
add("adshape.bottle", "Fizz Cola bottle", "Fizz Cola şişesi", "Fizz-Cola-Flasche", "Botella de Fizz Cola", "フィズコーラのボトル", "피즈 콜라 병")
add("adshape.rocket", "Yıldız Telekom rocket", "Yıldız Telekom roketi", "Yıldız-Telekom-Rakete", "Cohete de Yıldız Telekom", "ユルドゥズ・テレコムのロケット", "이을드즈 텔레콤 로켓")
add("adshape.shoe", "Kanat sneaker", "Kanat spor ayakkabısı", "Kanat-Sneaker", "Zapatilla Kanat", "カナットのスニーカー", "카나트 운동화")

# Luxor's cruise-season night
add("night.glow.lux",
 "Nile night: the ships are all lit up, and on the bank the balloons fire their burners.",
 "Nil gecesi: gemiler ışıl ışıl, kıyıda balonlar brülör yakıyor.",
 "Nilnacht: Die Schiffe leuchten, und am Ufer zünden die Ballone ihre Brenner.",
 "Noche del Nilo: los barcos iluminados y, en la orilla, los globos encienden sus quemadores.",
 "ナイルの夜。船は光り輝き、岸辺では気球がバーナーを焚いている。",
 "나일의 밤. 배들은 환히 빛나고, 강변에선 열기구가 버너를 켭니다.")
add("paper.night.glow.lux", "A night of light on the Nile", "Nil kıyısında ışık gecesi", "Eine Nacht des Lichts am Nil", "Una noche de luz en el Nilo", "ナイル河畔の光の夜", "나일강변 빛의 밤")
add("paper.night.glow.lux.sub",
 "The ships' lights and the balloons on the ground lit up the Nile.",
 "Gemilerin ışıkları ve yerdeki balonlar Nil'i aydınlattı.",
 "Die Lichter der Schiffe und die Ballone am Boden erhellten den Nil.",
 "Las luces de los barcos y los globos en tierra iluminaron el Nilo.",
 "船の灯りと地上の気球がナイルを照らした。",
 "배들의 불빛과 땅 위의 열기구가 나일강을 밝혔다.")

# Grounded balloons before collecting passengers (prototype v106, `pilotCheck`)
add("grounded.one", "One balloon will stay on the ground", "Bir balon yerde kalacak", "Ein Ballon bleibt am Boden", "Un globo se quedará en tierra", "1機が地上に残る", "열기구 한 대가 땅에 남습니다")
add("grounded.many", "Balloons staying on the ground: %@", "Yerde kalacak balon: %@", "Ballone am Boden: %@", "Globos que se quedan en tierra: %@", "地上に残る気球：%@機", "땅에 남을 열기구: %@대")
add("grounded.lead",
 "No pilot for: %@. Today only the balloons with a pilot take off, and they take the passengers.",
 "Pilotu olmayan balonlar: %@. Bugün yalnızca pilotu olan balonlar kalkar, yolcuları da onlar alır.",
 "Kein Pilot für: %@. Heute starten nur die Ballone mit Pilot, und sie nehmen die Passagiere.",
 "Sin piloto: %@. Hoy solo despegan los globos con piloto, y ellos llevan a los pasajeros.",
 "パイロットがいない気球：%@。今日はパイロットのいる気球だけが飛び、乗客もそちらに乗る。",
 "조종사가 없는 열기구: %@. 오늘은 조종사가 있는 열기구만 이륙하고 승객도 그쪽에 탑니다.")
add("grounded.crew", "Crew page", "Ekip sayfası", "Crew-Seite", "Página del equipo", "クルー画面", "크루 페이지")
add("grounded.fly", "Fly anyway", "Yine de uç", "Trotzdem fliegen", "Volar igualmente", "それでも飛ぶ", "그래도 비행")

# Region travel (prototype v106, `showTravel`)
add("travel.sub", "The wind is carrying you to the skies of %@…", "Rüzgâr seni %@ göğüne taşıyor…", "Der Wind trägt dich in den Himmel über %@ …", "El viento te lleva al cielo de %@…", "風があなたを%@の空へ運んでいく…", "바람이 당신을 %@의 하늘로 데려갑니다…")

# Settings screen (prototype v106.1, `showMenu`)
add("settings.title", "Settings", "Ayarlar", "Einstellungen", "Ajustes", "設定", "설정")
add("settings.sub", "%1$@ · Day %2$@ · %3$@", "%1$@ · Gün %2$@ · %3$@", "%1$@ · Tag %2$@ · %3$@", "%1$@ · Día %2$@ · %3$@", "%1$@・%2$@日目・%3$@", "%1$@ · %2$@일차 · %3$@")
add("settings.game", "Game", "Oyun", "Spiel", "Juego", "ゲーム", "게임")
add("settings.album", "Achievements", "Başarımlar", "Erfolge", "Logros", "実績", "업적")
add("settings.soundHaptics", "Sound and haptics", "Ses ve titreşim", "Ton und Haptik", "Sonido y vibración", "サウンドと振動", "소리와 진동")
add("settings.sound", "Sound", "Ses", "Ton", "Sonido", "サウンド", "소리")
add("settings.haptics", "Haptics", "Titreşim", "Haptik", "Vibración", "振動", "진동")
add("settings.notice", "Notifications", "Bildirimler", "Mitteilungen", "Notificaciones", "通知", "알림")
add("settings.reminder", "Morning reminder", "Sabah hatırlatması", "Morgenerinnerung", "Recordatorio matinal", "朝のリマインダー", "아침 알림")
add("settings.save", "Save", "Kayıt", "Spielstand", "Partida", "セーブ", "저장")
add("settings.autosaved", "Saved automatically", "Otomatik kaydedildi", "Automatisch gespeichert", "Guardado automáticamente", "自動保存済み", "자동 저장됨")
add("settings.copyCode", "Copy save code", "Kayıt kodunu kopyala", "Speichercode kopieren", "Copiar código de partida", "セーブコードをコピー", "저장 코드 복사")
add("settings.loadCode", "Load a save code", "Kayıt kodu yükle", "Speichercode laden", "Cargar un código de partida", "セーブコードを読み込む", "저장 코드 불러오기")
add("settings.copyHint",
 "To continue on another device, copy this code and paste it there under \"Load a save code\".",
 "Başka bir cihazda devam etmek için bu kodu kopyala, orada “Kayıt kodu yükle” bölümüne yapıştır.",
 "Um auf einem anderen Gerät weiterzuspielen, kopiere diesen Code und füge ihn dort unter „Speichercode laden“ ein.",
 "Para seguir en otro dispositivo, copia este código y pégalo allí en «Cargar un código de partida».",
 "別の端末で続けるには、このコードをコピーし、その端末の「セーブコードを読み込む」に貼り付けてください。",
 "다른 기기에서 이어 하려면 이 코드를 복사해 그쪽의 '저장 코드 불러오기'에 붙여 넣으세요.")
add("settings.loadHint",
 "Paste the code you copied on another device and tap Load. It replaces the game on this device.",
 "Başka cihazdan kopyaladığın kodu buraya yapıştır ve Yükle'ye bas. Buradaki oyunun yerini alır.",
 "Füge den Code ein, den du auf einem anderen Gerät kopiert hast, und tippe auf Laden. Er ersetzt das Spiel auf diesem Gerät.",
 "Pega el código que copiaste en otro dispositivo y toca Cargar. Sustituye la partida de este dispositivo.",
 "別の端末でコピーしたコードを貼り付けて「読み込む」をタップしてください。この端末のゲームは上書きされます。",
 "다른 기기에서 복사한 코드를 붙여 넣고 불러오기를 누르세요. 이 기기의 게임을 대체합니다.")
add("settings.pastePlaceholder", "Paste the code here", "Kodu buraya yapıştır", "Code hier einfügen", "Pega el código aquí", "ここにコードを貼り付け", "여기에 코드를 붙여 넣으세요")
add("settings.paste", "Paste", "Yapıştır", "Einfügen", "Pegar", "貼り付け", "붙여넣기")
add("settings.purchases", "Purchases", "Satın alımlar", "Käufe", "Compras", "購入", "구매")
add("settings.restore", "Restore purchases", "Satın alımları geri yükle", "Käufe wiederherstellen", "Restaurar compras", "購入を復元", "구매 복원")
add("settings.restoring", "Checking your purchases with the App Store…", "Satın alımların App Store'dan kontrol ediliyor…", "Deine Käufe werden beim App Store geprüft …", "Comprobando tus compras con la App Store…", "App Storeで購入を確認しています…", "App Store에서 구매 내역을 확인하는 중…")
add("settings.about", "About", "Hakkında", "Info", "Acerca de", "このアプリについて", "정보")
add("settings.privacy", "Privacy policy", "Gizlilik politikası", "Datenschutz", "Política de privacidad", "プライバシーポリシー", "개인정보 처리방침")
add("settings.support", "Support", "Destek", "Support", "Soporte", "サポート", "지원")
add("settings.version", "Version", "Sürüm", "Version", "Versión", "バージョン", "버전")
add("settings.sure", "Sure? All progress is deleted. Tap again", "Emin misin? Bütün ilerleme silinir. Tekrar dokun", "Sicher? Der gesamte Fortschritt wird gelöscht. Noch mal tippen", "¿Seguro? Se borra todo el progreso. Toca otra vez", "本当に？進行状況はすべて消えます。もう一度タップ", "정말요? 모든 진행 상황이 삭제됩니다. 다시 누르세요")
add("a11y.on", "On", "Açık", "Ein", "Activado", "オン", "켬")
add("a11y.off", "Off", "Kapalı", "Aus", "Desactivado", "オフ", "끔")
