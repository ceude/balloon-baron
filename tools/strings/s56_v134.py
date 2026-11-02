from s1_ui import add

# v134 (TestFlight): the send switch on the region you're in, and a much harsher holding rescue.

# The region you're in has the switch too: nothing flows while you play there.
add("holding.sendHereOn",
    "On. Nothing is sent while you play in this region; only on autopilot, while you're elsewhere, does its profit reach the holding each evening.",
    "Açık. Bu bölgede oynarken aktarılmaz; yalnız otomatik modda, sen başka bölgedeyken, kazanç her akşam holding kasasına geçer.",
    "An. Solange du in dieser Region spielst, wird nichts überwiesen; nur im Autopiloten, während du woanders bist, geht ihr Gewinn jeden Abend an die Holding.",
    "Activado. Mientras juegas en esta región no se envía nada; solo con el piloto automático, mientras estás en otra parte, su beneficio llega al holding cada tarde.",
    "オン。この地域でプレイしている間は送らない。自動運営で、あなたが他の地域にいる間だけ、利益が毎晩ホールディングスに入る。",
    "켜짐. 이 지역에서 플레이하는 동안에는 보내지 않아요. 다른 지역에 가서 자동 운영이 될 때만 매일 저녁 수익이 지주회사로 들어가요.")
add("holding.sendHereOff",
    "Off. Nothing is sent while you play here anyway; once it's on autopilot, its profit will pile up in its own cash box.",
    "Kapalı. Bu bölgede oynarken zaten aktarılmaz; otomatik moda geçince de kazanç bölgenin kasasında birikir.",
    "Aus. Solange du hier spielst, wird ohnehin nichts überwiesen; im Autopiloten sammelt sich der Gewinn dann in der eigenen Kasse der Region.",
    "Desactivado. Mientras juegas aquí no se envía nada de todos modos; con el piloto automático, el beneficio se acumulará en su propia caja.",
    "オフ。ここでプレイしている間はもともと送らない。自動運営になっても、利益は地域の金庫にたまる。",
    "꺼짐. 여기서 플레이하는 동안에는 어차피 보내지 않아요. 자동 운영이 되어도 수익은 지역 금고에 쌓여요.")

# The rescue card: the whole damage up front.
add("ruin.price",
    "%1$@ goes into the region's cash, which comes back to %2$@. The price is three times the money put in or a quarter of the holding's cash, whichever is more, and at least %3$@.",
    "Bölgenin kasasına %1$@ girer, kasa %2$@ olur. Bedel kurtarılan paranın üç katı ya da holding kasasının %%25'i (hangisi büyükse), en az %3$@.",
    "%1$@ fließen in die Kasse der Region, die wieder auf %2$@ steht. Der Preis ist das Dreifache des eingezahlten Geldes oder ein Viertel der Holding-Kasse, je nachdem, was mehr ist, mindestens %3$@.",
    "Entran %1$@ en la caja de la región, que vuelve a %2$@. El precio es el triple del dinero aportado o una cuarta parte de la caja del holding, lo que sea mayor, y como mínimo %3$@.",
    "地域の資金に%1$@が入り、%2$@に戻る。代価は投入額の3倍かホールディングス資金の4分の1の多いほう、最低%3$@。",
    "지역 금고에 %1$@이 들어가 %2$@가 됩니다. 대가는 넣은 돈의 3배와 지주회사 금고의 4분의 1 중 큰 쪽이며, 최소 %3$@입니다.")
add("ruin.damage", "What the rescue costs", "Kurtarmanın bedeli", "Was die Rettung kostet", "Lo que cuesta el rescate",
    "救済の代償", "구조의 대가")
add("ruin.dmg.cost", "%@ from the holding's cash.", "Holding kasasından: %@.", "%@ aus der Holding-Kasse.",
    "%@ de la caja del holding.", "ホールディングス資金から%@。", "지주회사 금고에서 %@.")
add("ruin.dmg.rep", "Popularity here: %1$@ → %2$@. The paper will run the bailout.",
    "Bu bölgede popülerlik: %1$@ → %2$@. Gazete kurtarmayı yazar.",
    "Beliebtheit hier: %1$@ → %2$@. Die Zeitung berichtet über die Rettung.",
    "Popularidad aquí: %1$@ → %2$@. El periódico publicará el rescate.",
    "この地域の人気：%1$@ → %2$@。新聞が救済を報じる。",
    "이 지역 인기: %1$@ → %2$@. 신문이 구제 소식을 실어요.")
add("ruin.dmg.once", "One chance only: the holding can never rescue this region again, not even after it closes and you enter it again.",
    "Tek hak: holding bu bölgeyi bir daha asla kurtaramaz, bölge kapanıp yeniden girilse de.",
    "Nur ein einziges Mal: Die Holding kann diese Region nie wieder retten, auch nicht, wenn sie schließt und du sie neu betrittst.",
    "Solo una vez: el holding nunca podrá volver a rescatar esta región, ni siquiera si cierra y vuelves a entrar.",
    "一度きり：ホールディングスはこの地域を二度と救えない。閉鎖して再参入しても同じ。",
    "단 한 번: 지주회사는 이 지역을 다시는 구할 수 없어요. 문을 닫고 다시 들어가도 마찬가지예요.")
add("ruin.accept.sub", "Cash %1$@ → %2$@. Popularity %3$@ → %4$@. Your balloon and loans stay; the bank's count starts again.",
    "Kasa %1$@ → %2$@. Popülerlik %3$@ → %4$@. Balonun ve kredilerin yerinde kalır; banka sayacı sıfırlanır.",
    "Kasse %1$@ → %2$@. Beliebtheit %3$@ → %4$@. Dein Ballon und deine Kredite bleiben; der Zähler der Bank beginnt neu.",
    "Caja %1$@ → %2$@. Popularidad %3$@ → %4$@. Tu globo y tus préstamos se quedan; la cuenta del banco vuelve a empezar.",
    "資金 %1$@ → %2$@。人気 %3$@ → %4$@。気球と借入はそのまま。銀行のカウントはリセット。",
    "금고 %1$@ → %2$@. 인기 %3$@ → %4$@. 열기구와 대출은 그대로이고, 은행 카운트는 다시 시작됩니다.")

# Hezarfen and the paper afterwards.
add("hez.holdingRescued",
    "The holding rescued the company, kid. Region: %1$@. It paid %2$@, and %3$@ went into the cash box. Everyone heard: your popularity here fell half a star. This happens once: if it sinks again, the holding can't save it. Keep the costs tight.",
    "Holding şirketi kurtardı evlat. Bölge: %1$@. Holding %2$@ ödedi, kasaya %3$@ girdi. Herkes duydu, popülerliğin burada yarım yıldız düştü. Bu bir kez olur; bir daha batarsa holding kurtaramaz. Masrafları sıkı tut.",
    "Die Holding hat die Firma gerettet, Lehrling. Region: %1$@. Sie hat %2$@ bezahlt, %3$@ sind in die Kasse geflossen. Alle haben es gehört: Deine Beliebtheit hier ist um einen halben Stern gefallen. Das gibt es nur einmal: Geht sie wieder unter, kann die Holding nicht helfen. Halte die Kosten knapp.",
    "El holding rescató la empresa, aprendiz. Región: %1$@. Pagó %2$@ y entraron %3$@ en la caja. Todos se enteraron: tu popularidad aquí bajó media estrella. Esto pasa una sola vez: si vuelve a hundirse, el holding no podrá salvarla. Controla los gastos.",
    "ホールディングスが会社を救ったぞ、弟子よ。地域：%1$@。%2$@を払い、金庫に%3$@が入った。皆が知っておる。ここでの人気は星半分下がった。これは一度きりだ。また沈めば、ホールディングスでも救えん。出費を引き締めるのだ。",
    "지주회사가 회사를 구했네, 제자여. 지역: %1$@. %2$@를 냈고 금고에 %3$@가 들어갔네. 다들 알게 됐지. 이곳 인기가 별 반 개 떨어졌네. 이건 한 번뿐일세. 또 가라앉으면 지주회사도 못 구하네. 지출을 줄이게.")
add("paper.holdingRescue", "Holding bailout: %@", "Holding kurtardı: %@", "Rettung durch die Holding: %@",
    "Rescate del holding: %@", "ホールディングスが救済：%@", "지주회사 구제: %@")
add("paper.holdingRescue.sub", "The company was about to go under and its holding paid up. Customers are uneasy. Region: %@.",
    "Şirket batmak üzereydi, holding parayı bastı. Müşteriler tedirgin. Bölge: %@.",
    "Die Firma stand vor dem Aus, ihre Holding hat bezahlt. Die Kunden sind verunsichert. Region: %@.",
    "La empresa estaba a punto de hundirse y su holding pagó. Los clientes están inquietos. Región: %@.",
    "会社は倒産寸前で、ホールディングスが資金を出した。客は不安げだ。地域：%@。",
    "회사가 무너지기 직전이었고 지주회사가 돈을 댔습니다. 손님들은 불안해합니다. 지역: %@.")
