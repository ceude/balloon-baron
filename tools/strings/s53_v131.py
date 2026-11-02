from s1_ui import add

# v131: fixes from a four-hour TestFlight session.

# The purchase loan says what blocks it, with the numbers (offer card and Market page).
add("deal.cashShort", "Cash: %1$@. Short of the price: %2$@.", "Kasa: %1$@. Fiyata eksik: %2$@.",
    "Kasse: %1$@. Zum Preis fehlen: %2$@.", "Caja: %1$@. Falta para el precio: %2$@.",
    "所持金：%1$@。価格まであと：%2$@。", "현금: %1$@. 가격까지 부족: %2$@.")
add("buyLoan.blockTitle", "The purchase loan can't be used right now", "Satın alma kredisi şu an kullanılamıyor",
    "Der Kaufkredit ist gerade nicht möglich", "El préstamo de compra no está disponible ahora",
    "今は買収ローンを使えない", "지금은 인수 대출을 쓸 수 없어요")
add("buyLoan.why.noBank", "The bank isn't open yet.", "Banka henüz açılmadı.", "Die Bank hat noch nicht geöffnet.",
    "El banco aún no ha abierto.", "銀行はまだ開いていない。", "은행이 아직 열리지 않았어요.")
add("buyLoan.why.few", "It needs a bigger fleet here. Balloons needed: %1$@. You have: %2$@.",
    "Burada daha büyük bir filo gerekir. Gereken balon: %1$@, sende: %2$@.",
    "Dafür braucht es hier eine größere Flotte. Nötige Ballone: %1$@. Du hast: %2$@.",
    "Hace falta una flota más grande aquí. Globos necesarios: %1$@. Tienes: %2$@.",
    "ここではもっと大きな船団が必要。必要な気球：%1$@機、保有：%2$@機。",
    "여기서는 더 큰 기단이 필요해요. 필요한 열기구: %1$@대, 보유: %2$@대.")
add("buyLoan.why.running", "One purchase loan at a time: the current one is still being paid off.",
    "Aynı anda tek satın alma kredisi olur: şimdiki hâlâ ödeniyor.",
    "Immer nur ein Kaufkredit: Der jetzige wird noch abbezahlt.",
    "Solo un préstamo de compra a la vez: el actual aún se está pagando.",
    "買収ローンは一度に一つだけ。今のローンはまだ返済中。",
    "인수 대출은 한 번에 하나만: 지금 대출을 아직 갚는 중이에요.")
add("buyLoan.why.full", "The bank gives at most two loans at once: pay one off first.",
    "Banka aynı anda en fazla iki kredi verir: önce birini kapat.",
    "Die Bank gibt höchstens zwei Kredite gleichzeitig: Zahl zuerst einen ab.",
    "El banco da como máximo dos préstamos a la vez: cancela uno primero.",
    "銀行のローンは同時に二つまで。先に一つ完済しよう。",
    "은행 대출은 동시에 두 개까지예요: 먼저 하나를 갚으세요.")
add("buyLoan.why.notOpen",
    "The %1$@ loan hasn't opened in this region yet; it's needed even if you have no loans. It opens for good once a typical day here (the median net of the last two weeks) reaches %2$@. Now: %3$@.",
    "%1$@ kredisi bu bölgede henüz açılmadı; hiç kredin olmasa da bu şart. Burada tipik bir günün net kazancı (son iki haftanın ortancası) %2$@ olunca açılır ve açık kalır. Şu an: %3$@.",
    "Der Kredit über %1$@ ist in dieser Region noch nicht freigeschaltet; das gilt auch ohne laufende Kredite. Er öffnet sich dauerhaft, sobald ein typischer Tag hier (Median-Netto der letzten zwei Wochen) %2$@ erreicht. Jetzt: %3$@.",
    "El préstamo de %1$@ aún no se ha abierto en esta región; es necesario aunque no tengas préstamos. Se abre para siempre cuando un día típico aquí (la mediana neta de las dos últimas semanas) llega a %2$@. Ahora: %3$@.",
    "この地域ではまだ%1$@のローンが開いていない。借入がなくても必要な条件だ。ここでの典型的な一日の純利益（直近2週間の中央値）が%2$@に届くと開き、その後も開いたまま。現在：%3$@。",
    "이 지역에서는 아직 %1$@ 대출이 열리지 않았어요. 대출이 없어도 필요한 조건이에요. 여기서 보통 하루 순이익(최근 2주 중앙값)이 %2$@에 닿으면 열리고 계속 열려 있어요. 지금: %3$@.")
add("buyLoan.why.notOpenFew",
    "The %1$@ loan hasn't opened in this region yet; it's needed even if you have no loans. It opens for good once a typical day here (the median net of the last two weeks) reaches %2$@, counted after at least 7 days here. Days so far: %3$@.",
    "%1$@ kredisi bu bölgede henüz açılmadı; hiç kredin olmasa da bu şart. Burada tipik bir günün net kazancı (son iki haftanın ortancası) %2$@ olunca açılır ve açık kalır; en az 7 gün sonra sayılır. Sayılan gün: %3$@.",
    "Der Kredit über %1$@ ist in dieser Region noch nicht freigeschaltet; das gilt auch ohne laufende Kredite. Er öffnet sich dauerhaft, sobald ein typischer Tag hier (Median-Netto der letzten zwei Wochen) %2$@ erreicht, gezählt nach mindestens 7 Tagen hier. Bisher gezählte Tage: %3$@.",
    "El préstamo de %1$@ aún no se ha abierto en esta región; es necesario aunque no tengas préstamos. Se abre para siempre cuando un día típico aquí (la mediana neta de las dos últimas semanas) llega a %2$@, contado tras al menos 7 días aquí. Días contados: %3$@.",
    "この地域ではまだ%1$@のローンが開いていない。借入がなくても必要な条件だ。ここでの典型的な一日の純利益（直近2週間の中央値）が%2$@に届くと開く。ここで7日以上たってから数える。数えた日数：%3$@。",
    "이 지역에서는 아직 %1$@ 대출이 열리지 않았어요. 대출이 없어도 필요한 조건이에요. 여기서 보통 하루 순이익(최근 2주 중앙값)이 %2$@에 닿으면 열리며, 여기서 최소 7일이 지나야 계산해요. 센 날: %3$@.")
add("buyLoan.why.tooBig", "The bank pays at most %1$@: you need %2$@ more of your own.",
    "Banka en fazla %1$@ öder: kendi cebinden %2$@ daha gerekir.",
    "Die Bank zahlt höchstens %1$@: Dir fehlen noch %2$@ eigenes Geld.",
    "El banco paga como máximo %1$@: necesitas %2$@ más de tu bolsillo.",
    "銀行が払うのは最大%1$@。自己資金があと%2$@必要。",
    "은행은 최대 %1$@까지 내요: 자기 돈이 %2$@ 더 필요해요.")
add("buyLoan.why.lowDown", "Your share must be at least %1$@ of the price, with %2$@ left in the cash box: you need %3$@ more.",
    "Senin payın fiyatın en az %1$@ kadarı olmalı ve kasada %2$@ kalır: %3$@ daha gerekir.",
    "Dein Anteil muss mindestens %1$@ des Preises sein, und %2$@ bleiben in der Kasse: Dir fehlen noch %3$@.",
    "Tu parte debe ser al menos el %1$@ del precio, y quedan %2$@ en la caja: necesitas %3$@ más.",
    "自己負担は価格の%1$@以上、金庫には%2$@を残す。あと%3$@必要。",
    "내 몫은 가격의 %1$@ 이상이어야 하고 금고에 %2$@이 남아요: %3$@ 더 필요해요.")

# The day's money table: the group's company, and Balloon Show fees that came back.
add("ledger.contractFrom", "Group: %1$@ (people: %2$@)", "Grup: %1$@ (%2$@ kişi)", "Gruppe: %1$@ (Personen: %2$@)",
    "Grupo: %1$@ (personas: %2$@)", "グループ：%1$@（%2$@人）", "단체: %1$@ (%2$@명)")
add("ledger.showRefund", "Balloon Show: fees refunded", "Balon Şöleni: ücret iadesi", "Ballon-Show: Gebühren erstattet",
    "Espectáculo de globos: tarifas devueltas", "バルーンショー：参加費の返金", "열기구 쇼: 참가비 환불")

# Holding: a region can keep its autopilot profit instead of sending it every day.
add("holding.sendTitle", "Send profit to the holding daily", "Kazancı her gün holdinge aktar",
    "Gewinn täglich an die Holding", "Enviar el beneficio al holding cada día",
    "利益を毎日ホールディングスへ送る", "수익을 매일 지주회사로 보내기")
add("holding.sendOn", "On: each evening the autopilot's profit reaches the holding.",
    "Açık: otomatik modun kazancı her akşam holding kasasına geçer.",
    "An: Jeden Abend geht der Gewinn des Autopiloten an die Holding.",
    "Activado: cada tarde el beneficio del piloto automático llega al holding.",
    "オン：自動運営の利益が毎晩ホールディングスに入る。",
    "켜짐: 자동 운영 수익이 매일 저녁 지주회사로 들어가요.")
add("holding.sendOff", "Off: the profit piles up in the region's cash box; move it whenever you like.",
    "Kapalı: kazanç bölgenin kasasında birikir, istediğinde aktarırsın.",
    "Aus: Der Gewinn sammelt sich in der Kasse der Region; überweise ihn, wann du willst.",
    "Desactivado: el beneficio se acumula en la caja de la región; muévelo cuando quieras.",
    "オフ：利益は地域の金庫にたまる。好きなときに移そう。",
    "꺼짐: 수익이 지역 금고에 쌓여요. 원할 때 옮기세요.")
add("holding.keptSub", "Autopilot: the profit stays in the region, about %1$@ a day. Cash box: %2$@.",
    "Otomatik mod: kazanç bölgede kalıyor, günde yaklaşık %1$@. Kasa: %2$@.",
    "Autopilot: Der Gewinn bleibt in der Region, etwa %1$@ am Tag. Kasse: %2$@.",
    "Piloto automático: el beneficio se queda en la región, unos %1$@ al día. Caja: %2$@.",
    "自動運営：利益は地域に残る。1日約%1$@。金庫：%2$@。",
    "자동 운영: 수익은 지역에 남아요. 하루 약 %1$@. 금고: %2$@.")
add("holding.moveOut", "Transfer %@", "%@ aktar", "%@ überweisen", "Transferir %@", "%@を移す", "%@ 옮기기")
add("holding.moveHint", "To the holding; %@ stays in the cash box.", "Holdinge geçer; kasada %@ kalır.",
    "An die Holding; %@ bleiben in der Kasse.", "Al holding; quedan %@ en la caja.",
    "ホールディングスへ。金庫には%@を残す。", "지주회사로 가요. 금고에 %@ 남아요.")
add("map.keptSub", "Your manager runs it: the profit piles up in its own cash box (sending to the holding is off).",
    "Müdürün yönetiyor: kazanç bölgenin kasasında birikiyor (holdinge aktarım kapalı).",
    "Dein Manager führt sie: Der Gewinn sammelt sich in ihrer eigenen Kasse (Überweisung an die Holding ist aus).",
    "La dirige tu gerente: el beneficio se acumula en su propia caja (el envío al holding está desactivado).",
    "マネージャーが運営中：利益は地域の金庫にたまっている（ホールディングスへの送金はオフ）。",
    "매니저가 운영 중: 수익이 지역 금고에 쌓이고 있어요(지주회사 송금 꺼짐).")
