from s1_ui import add

# v133: going bankrupt. The flagship's three-day grace, the holding's rescue, and a region that closes instead of the save.

# The countdown to the flagship (report, home screen, rescue plan).
add("grace.title", "Days until the bank takes your flagship: %@", "Banka %@ gün içinde amiral balonuna el koyacak",
    "Tage, bis die Bank dein Flaggschiff pfändet: %@", "Días hasta que el banco embargue tu globo insignia: %@",
    "銀行が旗艦を差し押さえるまで：あと%@日", "은행이 기함을 압류하기까지: %@일")
add("grace.body",
    "The count runs on every day that closes with cash below %@ and starts again once a day closes above it.",
    "Kasa gün sonunda %@ altında kaldıkça sayaç işler, üstüne çıkınca sıfırlanır.",
    "Der Zähler läuft an jedem Tag, der mit der Kasse unter %@ endet, und beginnt neu, sobald ein Tag darüber endet.",
    "La cuenta avanza cada día que cierra con la caja por debajo de %@ y vuelve a empezar cuando un día cierra por encima.",
    "資金が%@を下回ったまま一日を終えるたびにカウントが進み、上回って終えればリセットされる。",
    "하루를 금고 %@ 미만으로 마칠 때마다 카운트가 진행되고, 그 이상으로 마치면 처음부터 다시 셉니다.")
add("grace.holding", "On that day the holding either rescues this region or the region closes.",
    "O gün holding ya bu bölgeyi kurtarır ya da bölge kapanır.",
    "An diesem Tag rettet die Holding diese Region, oder die Region schließt.",
    "Ese día el holding rescata esta región o la región cierra.",
    "その日、ホールディングスがこの地域を救うか、地域が閉鎖される。",
    "그날 지주회사가 이 지역을 구하거나, 지역이 문을 닫습니다.")
add("grace.noHolding", "If the last balloon goes too, the company closes.", "Son balon da giderse şirket kapanır.",
    "Wenn auch der letzte Ballon geht, schließt die Firma.", "Si también se va el último globo, la empresa cierra.",
    "最後の気球も失えば、会社は廃業する。", "마지막 열기구마저 잃으면 회사는 문을 닫습니다.")
add("grace.home", "Get cash above %@ by the end of the day. Tap for the rescue plan.",
    "Kasayı gün sonuna kadar %@ üstüne çıkar. Kurtarma planı için dokun.",
    "Bring die Kasse bis Tagesende über %@. Tippe für den Rettungsplan.",
    "Sube la caja por encima de %@ antes de que acabe el día. Toca para ver el plan de rescate.",
    "今日のうちに資金を%@より上に戻そう。タップで救済プラン。",
    "오늘 안에 금고를 %@ 위로 올리세요. 눌러서 구조 계획 보기.")
add("grace.rescue", "If cash closes the day above %@, the count starts again.",
    "Kasa gün sonunda %@ üstüne çıkarsa sayaç sıfırlanır.",
    "Endet der Tag mit der Kasse über %@, beginnt der Zähler neu.",
    "Si la caja cierra el día por encima de %@, la cuenta vuelve a empezar.",
    "資金が%@を上回って一日を終えれば、カウントはリセットされる。",
    "금고가 %@ 이상으로 하루를 마치면 카운트는 처음부터 다시 시작됩니다.")
add("event.flagshipGrace",
    "Days until the bank takes your flagship: %1$@. If cash closes a day above %2$@, the count starts again.",
    "Banka %1$@ gün içinde amiral balonuna el koyacak. Kasa gün sonunda %2$@ üstüne çıkarsa sayaç sıfırlanır.",
    "Tage, bis die Bank dein Flaggschiff pfändet: %1$@. Endet ein Tag mit der Kasse über %2$@, beginnt der Zähler neu.",
    "Días hasta que el banco embargue tu globo insignia: %1$@. Si la caja cierra un día por encima de %2$@, la cuenta vuelve a empezar.",
    "銀行が旗艦を差し押さえるまで：あと%1$@日。資金が%2$@を上回って一日を終えれば、カウントはリセット。",
    "은행이 기함을 압류하기까지: %1$@일. 금고가 %2$@ 이상으로 하루를 마치면 카운트는 다시 시작됩니다.")
add("event.ruinPending", "The bank came for your last balloon. The holding decides: it rescues the region or the company closes. Region: %@.",
    "Banka son balonun için geldi. Holding karar verecek: ya bölgeyi kurtarır ya da şirket kapanır. Bölge: %@.",
    "Die Bank will deinen letzten Ballon. Die Holding entscheidet: Sie rettet die Region, oder die Firma schließt. Region: %@.",
    "El banco viene a por tu último globo. Decide el holding: rescata la región o la empresa cierra. Región: %@.",
    "銀行が最後の気球を取りに来た。ホールディングスが決める：地域を救うか、会社を閉じるか。地域：%@。",
    "은행이 마지막 열기구를 가지러 왔습니다. 지주회사가 결정합니다: 지역을 구하거나 회사가 문을 닫습니다. 지역: %@.")

# The report's footer when the holding has to decide.
add("report.ruinTitle", "The bank is about to take your last balloon.", "Banka son balonuna el koymak üzere.",
    "Die Bank will deinen letzten Ballon pfänden.", "El banco está a punto de embargar tu último globo.",
    "銀行が最後の気球を差し押さえようとしている。", "은행이 마지막 열기구를 압류하려 합니다.")
add("report.ruinBody",
    "Cash has closed three days below %1$@. The holding either rescues the company or it closes. Region: %2$@. Your holding and your other regions stay either way.",
    "Kasa üç gündür %1$@ altında. Holding ya şirketi kurtarır ya da şirket kapanır. Bölge: %2$@. Holdingin ve öteki bölgelerin her durumda yerinde kalır.",
    "Die Kasse lag drei Tage unter %1$@. Die Holding rettet die Firma, oder sie schließt. Region: %2$@. Deine Holding und deine anderen Regionen bleiben so oder so.",
    "La caja lleva tres días por debajo de %1$@. El holding rescata la empresa o esta cierra. Región: %2$@. Tu holding y tus otras regiones se quedan pase lo que pase.",
    "資金は3日続けて%1$@を下回った。ホールディングスが会社を救うか、会社が閉じるか。地域：%2$@。ホールディングスと他の地域はどちらでも残る。",
    "금고가 사흘째 %1$@ 미만입니다. 지주회사가 회사를 구하거나 회사가 문을 닫습니다. 지역: %2$@. 지주회사와 다른 지역은 어느 쪽이든 그대로 남습니다.")
add("report.decide", "Decide", "Karar ver", "Entscheiden", "Decidir", "決める", "결정하기")

# The holding's rescue card.
add("ruin.title", "Holding rescue", "Holding kurtarma", "Rettung durch die Holding", "Rescate del holding", "ホールディングスの救済", "지주회사 구조")
add("ruin.hez",
    "Kid, the bank came for your last balloon: %1$@. Cash has been below %2$@ for three days. Your holding and your other regions stay whatever happens; the decision is about this company. Region: %3$@.",
    "Evlat, banka son balonun için geldi: %1$@. Kasa üç gündür %2$@ altında. Holdingin ve öteki bölgelerin ne olursa olsun yerinde kalır; karar bu şirket için. Bölge: %3$@.",
    "Lehrling, die Bank will deinen letzten Ballon: %1$@. Die Kasse liegt seit drei Tagen unter %2$@. Deine Holding und deine anderen Regionen bleiben, was auch geschieht; es geht um diese Firma. Region: %3$@.",
    "Aprendiz, el banco viene a por tu último globo: %1$@. La caja lleva tres días por debajo de %2$@. Tu holding y tus otras regiones se quedan pase lo que pase; la decisión es sobre esta empresa. Región: %3$@.",
    "弟子よ、銀行が最後の気球を取りに来た：%1$@。資金は3日続けて%2$@を下回っている。ホールディングスと他の地域は何があっても残る。決めるのはこの会社のことだ。地域：%3$@。",
    "제자여, 은행이 마지막 열기구를 가지러 왔네: %1$@. 금고가 사흘째 %2$@ 미만이야. 지주회사와 다른 지역은 무슨 일이 있어도 남네. 결정할 건 이 회사일세. 지역: %3$@.")
add("ruin.cost", "Price: %@, from the holding's cash.", "Bedel: %@, holding kasasından.", "Preis: %@, aus der Holding-Kasse.",
    "Precio: %@, de la caja del holding.", "代価：%@（ホールディングス資金から）。", "대가: %@, 지주회사 금고에서.")
add("ruin.price",
    "%1$@ goes into the region's cash, which comes back to %2$@. The price is three times the money put in or a tenth of the holding's cash, whichever is more, and at least %3$@. Once per region.",
    "Bölgenin kasasına %1$@ girer, kasa %2$@ olur. Bedel kurtarılan paranın üç katı ya da holding kasasının %%10'u (hangisi büyükse), en az %3$@. Her bölge için bir kez.",
    "%1$@ fließen in die Kasse der Region, die wieder auf %2$@ steht. Der Preis ist das Dreifache des eingezahlten Geldes oder ein Zehntel der Holding-Kasse, je nachdem, was mehr ist, mindestens %3$@. Einmal pro Region.",
    "Entran %1$@ en la caja de la región, que vuelve a %2$@. El precio es el triple del dinero aportado o una décima parte de la caja del holding, lo que sea mayor, y como mínimo %3$@. Una vez por región.",
    "地域の資金に%1$@が入り、%2$@に戻る。代価は投入額の3倍かホールディングス資金の10分の1の多いほう、最低%3$@。各地域につき1回だけ。",
    "지역 금고에 %1$@이 들어가 %2$@가 됩니다. 대가는 넣은 돈의 3배와 지주회사 금고의 10분의 1 중 큰 쪽이며, 최소 %3$@입니다. 지역마다 한 번.")
add("ruin.holding", "Holding cash: %1$@ → %2$@", "Holding kasası: %1$@ → %2$@", "Holding-Kasse: %1$@ → %2$@",
    "Caja del holding: %1$@ → %2$@", "ホールディングス資金：%1$@ → %2$@", "지주회사 금고: %1$@ → %2$@")
add("ruin.short", "Holding cash: %1$@. Missing: %2$@.", "Holding kasası: %1$@. Yetmiyor, eksik: %2$@.",
    "Holding-Kasse: %1$@. Es fehlen: %2$@.", "Caja del holding: %1$@. Faltan: %2$@.",
    "ホールディングス資金：%1$@。不足：%2$@。", "지주회사 금고: %1$@. 부족: %2$@.")
add("ruin.used", "The holding already rescued this region (day %@).", "Holding bu bölgeyi bir kez kurtardı (gün %@).",
    "Die Holding hat diese Region schon gerettet (Tag %@).", "El holding ya rescató esta región (día %@).",
    "ホールディングスはこの地域をすでに救った（%@日目）。", "지주회사는 이미 이 지역을 구했습니다 (%@일차).")
add("ruin.used.body", "There is no second rescue.", "İkinci kurtarma yok.", "Eine zweite Rettung gibt es nicht.",
    "No hay un segundo rescate.", "2度目の救済はない。", "두 번째 구조는 없습니다.")
add("ruin.accept", "Let the holding rescue it: %@", "Holding kurtarsın: %@", "Die Holding soll retten: %@",
    "Que lo rescate el holding: %@", "ホールディングスに救ってもらう：%@", "지주회사가 구하게 하기: %@")
add("ruin.accept.sub", "Cash %1$@ → %2$@. Your balloon and loans stay; the bank's count starts again.",
    "Kasa %1$@ → %2$@. Balonun ve kredilerin yerinde kalır; banka sayacı sıfırlanır.",
    "Kasse %1$@ → %2$@. Dein Ballon und deine Kredite bleiben; der Zähler der Bank beginnt neu.",
    "Caja %1$@ → %2$@. Tu globo y tus préstamos se quedan; la cuenta del banco vuelve a empezar.",
    "資金 %1$@ → %2$@。気球と借入はそのまま。銀行のカウントはリセット。",
    "금고 %1$@ → %2$@. 열기구와 대출은 그대로이고, 은행 카운트는 다시 시작됩니다.")
add("ruin.close", "Close the company here: %@", "Bu şirketi kapat: %@", "Die Firma hier schließen: %@",
    "Cerrar la empresa aquí: %@", "ここの会社を閉じる：%@", "이곳 회사 닫기: %@")
add("ruin.close.sub",
    "The bank takes everything here: balloons, pilots, hotels, buildings. You move on to %1$@. You can enter %2$@ again later from the world map for %3$@, from scratch with a small balloon. Your baron titles and holding goals stay.",
    "Banka buradaki her şeyi alır: balonlar, pilotlar, oteller, binalar. Sen şu bölgeye geçersin: %1$@. Sonra dünya haritasından yeniden girebilirsin: %2$@, bedeli %3$@, küçük bir balonla sıfırdan. Baron unvanların ve holding hedeflerin yerinde kalır.",
    "Die Bank nimmt hier alles: Ballone, Piloten, Hotels, Gebäude. Du wechselst nach %1$@. %2$@ kannst du später über die Weltkarte für %3$@ wieder betreten, von vorn mit einem kleinen Ballon. Deine Barontitel und Holding-Ziele bleiben.",
    "El banco se queda con todo lo de aquí: globos, pilotos, hoteles, edificios. Pasas a %1$@. Podrás volver a entrar en %2$@ más tarde desde el mapa del mundo por %3$@, desde cero con un globo pequeño. Tus títulos de barón y los objetivos del holding se quedan.",
    "銀行がここのすべてを持っていく：気球、パイロット、ホテル、建物。あなたは%1$@へ移る。%2$@には後で世界地図から%3$@で再参入できる。小さな気球でゼロから。男爵の称号とホールディングスの目標はそのまま。",
    "은행이 이곳의 모든 것을 가져갑니다: 열기구, 조종사, 호텔, 건물. 당신은 %1$@(으)로 옮겨 갑니다. %2$@에는 나중에 세계 지도에서 %3$@에 다시 들어갈 수 있으며, 작은 열기구로 처음부터 시작합니다. 남작 칭호와 지주회사 목표는 그대로입니다.")
add("ruin.close.fresh",
    "The bank takes everything here. You have no other region, so a new company starts here, free, from a small balloon. Your holding, baron titles and holding goals stay.",
    "Banka buradaki her şeyi alır. Başka bölgen olmadığı için burada ücretsiz, küçük bir balonla sıfırdan yeni bir şirket kurarsın. Holdingin, baron unvanların ve holding hedeflerin yerinde kalır.",
    "Die Bank nimmt hier alles. Du hast keine andere Region, also beginnt hier kostenlos eine neue Firma mit einem kleinen Ballon. Deine Holding, Barontitel und Holding-Ziele bleiben.",
    "El banco se queda con todo lo de aquí. No tienes otra región, así que aquí empieza gratis una empresa nueva con un globo pequeño. Tu holding, tus títulos de barón y los objetivos del holding se quedan.",
    "銀行がここのすべてを持っていく。他の地域がないので、ここで無料で小さな気球から新しい会社を始める。ホールディングス、男爵の称号、ホールディングスの目標はそのまま。",
    "은행이 이곳의 모든 것을 가져갑니다. 다른 지역이 없으니 여기서 무료로, 작은 열기구로 새 회사를 시작합니다. 지주회사, 남작 칭호, 지주회사 목표는 그대로입니다.")

# Hezarfen afterwards.
add("hez.holdingRescued",
    "The holding rescued the company, kid. Region: %1$@. It paid %2$@, and %3$@ went into the cash box. This happens once: if it sinks again, the holding can't save it. Keep the costs tight.",
    "Holding şirketi kurtardı evlat. Bölge: %1$@. Holding %2$@ ödedi, kasaya %3$@ girdi. Bu bir kez olur; bir daha batarsa holding kurtaramaz. Masrafları sıkı tut.",
    "Die Holding hat die Firma gerettet, Lehrling. Region: %1$@. Sie hat %2$@ bezahlt, %3$@ sind in die Kasse geflossen. Das gibt es nur einmal: Geht sie wieder unter, kann die Holding nicht helfen. Halte die Kosten knapp.",
    "El holding rescató la empresa, aprendiz. Región: %1$@. Pagó %2$@ y entraron %3$@ en la caja. Esto pasa una sola vez: si vuelve a hundirse, el holding no podrá salvarla. Controla los gastos.",
    "ホールディングスが会社を救ったぞ、弟子よ。地域：%1$@。%2$@を払い、金庫に%3$@が入った。これは一度きりだ。また沈めば、ホールディングスでも救えん。出費を引き締めるのだ。",
    "지주회사가 회사를 구했네, 제자여. 지역: %1$@. %2$@를 냈고 금고에 %3$@가 들어갔네. 이건 한 번뿐일세. 또 가라앉으면 지주회사도 못 구하네. 지출을 줄이게.")
add("hez.regionClosed",
    "The company closed, kid. Region: %1$@. The bank took everything with the balloons, pilots and buildings. Your holding and your other regions stand, and your baron titles are yours. You can enter it again from the world map: entry fee %2$@, from scratch with a small balloon.",
    "Şirket kapandı evlat. Bölge: %1$@. Banka balonlar, pilotlar ve binalarla birlikte her şeyi aldı. Holding ve öteki bölgelerin duruyor, baron unvanların da senin. Dünya haritasından yeniden girebilirsin: giriş bedeli %2$@, küçük bir balonla sıfırdan.",
    "Die Firma ist geschlossen, Lehrling. Region: %1$@. Die Bank hat alles genommen, mit Ballonen, Piloten und Gebäuden. Deine Holding und deine anderen Regionen stehen, deine Barontitel gehören dir. Über die Weltkarte kannst du wieder einsteigen: Einstiegsgebühr %2$@, von vorn mit einem kleinen Ballon.",
    "La empresa cerró, aprendiz. Región: %1$@. El banco se lo llevó todo, con globos, pilotos y edificios. Tu holding y tus otras regiones siguen en pie, y tus títulos de barón son tuyos. Puedes volver a entrar desde el mapa del mundo: cuota de entrada %2$@, desde cero con un globo pequeño.",
    "会社は閉じたぞ、弟子よ。地域：%1$@。銀行が気球もパイロットも建物も、すべて持っていった。ホールディングスと他の地域は無事で、男爵の称号もお前のものだ。世界地図から再参入できる：参入費%2$@、小さな気球でゼロから。",
    "회사가 문을 닫았네, 제자여. 지역: %1$@. 은행이 열기구, 조종사, 건물까지 모두 가져갔네. 지주회사와 다른 지역은 건재하고 남작 칭호도 자네 것일세. 세계 지도에서 다시 들어갈 수 있네: 진입 비용 %2$@, 작은 열기구로 처음부터.")
add("hez.regionClosed.fresh",
    "The company closed, kid. Region: %1$@. You had no other region, so we started a new company right here, from a small balloon; your holding and baron titles are where they were. This time keep the cash above %2$@.",
    "Şirket kapandı evlat. Bölge: %1$@. Başka bölgen olmadığı için burada sıfırdan, küçük bir balonla yeni bir şirket kurduk; holdingin ve baron unvanların yerinde. Bu sefer kasayı %2$@ altına düşürme.",
    "Die Firma ist geschlossen, Lehrling. Region: %1$@. Du hattest keine andere Region, also haben wir genau hier eine neue Firma mit einem kleinen Ballon gegründet; Holding und Barontitel sind, wo sie waren. Halte die Kasse diesmal über %2$@.",
    "La empresa cerró, aprendiz. Región: %1$@. No tenías otra región, así que fundamos aquí mismo una empresa nueva con un globo pequeño; tu holding y tus títulos de barón siguen donde estaban. Esta vez mantén la caja por encima de %2$@.",
    "会社は閉じたぞ、弟子よ。地域：%1$@。他の地域がなかったので、ここで小さな気球から新しい会社を立ち上げた。ホールディングスと男爵の称号はそのままだ。今度は資金を%2$@より上に保つのだ。",
    "회사가 문을 닫았네, 제자여. 지역: %1$@. 다른 지역이 없어서 바로 여기서 작은 열기구로 새 회사를 세웠네. 지주회사와 남작 칭호는 그대로일세. 이번엔 금고를 %2$@ 위로 유지하게.")
add("hez.capReentered",
    "Welcome back to Cappadocia, kid! Where it all began. You start from scratch with a small balloon, but this time you have a holding behind you.",
    "Kapadokya'ya yeniden hoş geldin evlat! Her şeyin başladığı yer. Küçük bir balonla, sıfırdan başlıyorsun; ama bu sefer yanında bir holding var.",
    "Willkommen zurück in Kappadokien, Lehrling! Hier hat alles angefangen. Du beginnst von vorn mit einem kleinen Ballon, aber diesmal steht eine Holding hinter dir.",
    "¡Bienvenido de nuevo a Capadocia, aprendiz! Donde empezó todo. Empiezas desde cero con un globo pequeño, pero esta vez tienes un holding detrás.",
    "カッパドキアへおかえり、弟子よ！すべてが始まった場所だ。小さな気球でゼロからの出発だが、今度は後ろにホールディングスがある。",
    "카파도키아에 다시 온 걸 환영하네, 제자여! 모든 것이 시작된 곳이지. 작은 열기구로 처음부터 시작하지만, 이번엔 뒤에 지주회사가 있네.")

# The morning paper.
add("paper.holdingRescue", "The holding steps in: %@", "Holding devreye girdi: %@", "Die Holding springt ein: %@",
    "El holding interviene: %@", "ホールディングスが介入：%@", "지주회사 개입: %@")
add("paper.holdingRescue.sub", "The company kept its last balloon from the bank at the last moment. Region: %@.",
    "Şirket son balonunu bankaya kaptırmaktan son anda kurtuldu. Bölge: %@.",
    "Die Firma hat ihren letzten Ballon im letzten Moment vor der Bank bewahrt. Region: %@.",
    "La empresa salvó su último globo del banco en el último momento. Región: %@.",
    "会社は最後の気球を土壇場で銀行から守った。地域：%@。",
    "회사가 마지막 순간에 마지막 열기구를 은행에서 지켜냈습니다. 지역: %@.")
add("paper.regionClosed", "%1$@ closes its company. Region: %2$@", "%1$@ şirketini kapattı. Bölge: %2$@",
    "%1$@ schließt seine Firma. Region: %2$@", "%1$@ cierra su empresa. Región: %2$@",
    "%1$@が会社を閉鎖。地域：%2$@", "%1$@ 회사 폐업. 지역: %2$@")
add("paper.regionClosed.sub", "The bank took the last balloon too. The holding and the other regions stand.",
    "Banka son balonu da aldı. Holding ve öteki bölgeler ayakta.",
    "Die Bank nahm auch den letzten Ballon. Die Holding und die anderen Regionen stehen.",
    "El banco se llevó también el último globo. El holding y las demás regiones siguen en pie.",
    "銀行は最後の気球も持っていった。ホールディングスと他の地域は健在。",
    "은행이 마지막 열기구까지 가져갔습니다. 지주회사와 다른 지역은 건재합니다.")

# The world map.
add("map.closed", "Closed", "Kapandı", "Geschlossen", "Cerrada", "閉鎖", "폐업")
add("map.closedSub",
    "Your company here closed on day %1$@. Enter again and you start from scratch: a small balloon, the region's starting cash, the chapters from the beginning. The baron titles you earned stay. Entry fee %2$@ from the holding.",
    "Şirketin burada kapandı (gün %1$@). Yeniden girersen sıfırdan başlarsın: küçük bir balon ve bölgenin başlangıç kasası, bölümler baştan. Kazandığın baron unvanları yerinde kalır. Giriş bedeli %2$@ holding kasasından.",
    "Deine Firma hier hat an Tag %1$@ geschlossen. Steigst du wieder ein, beginnst du von vorn: ein kleiner Ballon, das Startkapital der Region, die Kapitel von Anfang an. Deine Barontitel bleiben. Einstiegsgebühr %2$@ aus der Holding.",
    "Tu empresa aquí cerró el día %1$@. Si vuelves a entrar, empiezas desde cero: un globo pequeño, la caja inicial de la región y los capítulos desde el principio. Los títulos de barón que ganaste se quedan. Cuota de entrada: %2$@, a cargo del holding.",
    "ここの会社は%1$@日目に閉鎖した。再参入するとゼロから：小さな気球、地域の初期資金、章も最初から。獲得した男爵の称号は残る。参入費%2$@はホールディングスから。",
    "이곳 회사는 %1$@일차에 문을 닫았습니다. 다시 들어가면 처음부터 시작합니다: 작은 열기구, 지역의 시작 자금, 챕터도 처음부터. 얻은 남작 칭호는 그대로입니다. 진입 비용 %2$@, 지주회사에서 지급.")

add("auto.stop.bank", "The bank is after your flagship", "Banka amiral balonuna el koymak üzere",
    "Die Bank will dein Flaggschiff", "El banco va a por tu globo insignia", "銀行が旗艦を狙っている", "은행이 기함을 노리고 있습니다")
