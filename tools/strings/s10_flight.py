from s1_ui import add

# Flight scene (FlightView). **bold** is Markdown, rendered by the app.
add("flight.burn", "BURNER", "BRÜLÖR", "BRENNER", "QUEMADOR", "バーナー", "버너")
add("flight.abort", "Cancel flight", "Uçuştan vazgeç", "Flug absagen", "Cancelar vuelo", "フライト中止", "비행 취소")
add("flight.inAir", "In the air", "Havadasın", "In der Luft", "En el aire", "飛行中", "비행 중")
add("flight.tip.tutorial",
    "**Your goal is the landing field on the right.** **Hold the burner:** the balloon heats up and climbs. **Let go:** it cools and sinks. The wind blows differently at every height. Find the layer that carries you right and come down gently on the landing field.",
    "**Hedefin sağdaki iniş alanı.** **Brülöre basılı tut:** balon ısınır ve yükselir. **Bırak:** soğur ve alçalır. Her yükseklikte rüzgâr farklı eser. Seni sağa taşıyan katmanı bul ve iniş alanına yavaşça in.",
    "**Dein Ziel ist das Landefeld rechts.** **Halte den Brenner gedrückt:** Der Ballon heizt sich auf und steigt. **Loslassen:** Er kühlt ab und sinkt. In jeder Höhe weht der Wind anders. Finde die Schicht, die dich nach rechts trägt, und setz sanft auf dem Landefeld auf.",
    "**Tu objetivo es el campo de aterrizaje de la derecha.** **Mantén pulsado el quemador:** el globo se calienta y sube. **Suéltalo:** se enfría y baja. El viento sopla distinto a cada altura. Encuentra la capa que te lleva a la derecha y baja suavemente en el campo de aterrizaje.",
    "**目標は右の着陸場。** **バーナーを長押し**：気球が温まって上昇する。**離す**：冷えて下降する。風は高度ごとに違う。右へ運んでくれる層を見つけて、着陸場にそっと降りよう。",
    "**목표는 오른쪽 착륙장입니다.** **버너를 길게 누르세요:** 열기구가 데워져 올라갑니다. **손을 떼면:** 식으면서 내려갑니다. 바람은 고도마다 다르게 붑니다. 오른쪽으로 데려다주는 층을 찾아 착륙장에 살며시 내리세요.")
add("flight.tip.pax",
    "**Passengers in the basket: %@.** Your goal: the landing field on the right.",
    "**Sepetteki yolcu: %@.** Hedef: sağdaki iniş alanı.",
    "**Passagiere im Korb: %@.** Dein Ziel: das Landefeld rechts.",
    "**Pasajeros en la cesta: %@.** Tu objetivo: el campo de aterrizaje de la derecha.",
    "**バスケットの乗客：%@**。目標：右の着陸場。",
    "**바스켓의 승객: %@.** 목표: 오른쪽 착륙장.")
add("flight.tip.fuel",
    "**Out of fuel!** The balloon is cooling and coming down.",
    "**Yakıt bitti!** Balon soğuyarak iniyor.",
    "**Kein Gas mehr!** Der Ballon kühlt ab und sinkt.",
    "**¡Sin combustible!** El globo se enfría y desciende.",
    "**燃料切れ**！気球は冷えながら降下中。",
    "**연료가 떨어졌습니다!** 열기구가 식으며 내려갑니다.")

# Landing
add("flight.land.perfect",
    "**Perfect landing!** Right in the middle of the landing field.",
    "**Kusursuz iniş!** İniş alanının tam ortası.",
    "**Perfekte Landung!** Genau in der Mitte des Landefelds.",
    "**¡Aterrizaje perfecto!** Justo en el centro del campo de aterrizaje.",
    "**完璧な着陸**！着陸場のど真ん中。",
    "**완벽한 착륙!** 착륙장 한가운데입니다.")
add("flight.land.good",
    "**Good landing.** The ground crew found you right away.",
    "**İyi iniş.** Yer ekibi seni hemen buldu.",
    "**Gute Landung.** Die Bodencrew hat dich sofort gefunden.",
    "**Buen aterrizaje.** El equipo de tierra te encontró enseguida.",
    "**良い着陸**。地上クルーがすぐに見つけてくれた。",
    "**좋은 착륙.** 지상 요원이 바로 찾아왔습니다.")
add("flight.land.far",
    "**You landed %@ m from the target.** Passengers had to wait an hour.",
    "**Hedeften %@ m uzağa indin.** Yolcular bir saat beklemek zorunda kaldı.",
    "**Du bist %@ m vom Ziel entfernt gelandet.** Die Passagiere mussten eine Stunde warten.",
    "**Aterrizaste a %@ m del objetivo.** Los pasajeros tuvieron que esperar una hora.",
    "**目標から%@ m離れて着陸**。乗客は1時間待たされた。",
    "**목표에서 %@ m 떨어진 곳에 착륙했습니다.** 승객들은 한 시간을 기다려야 했습니다.")
add("flight.land.hard",
    "**Hard landing!** The basket tipped over and passengers have minor injuries.",
    "**Sert iniş!** Sepet devrildi, yolcularda hafif yaralanmalar var.",
    "**Harte Landung!** Der Korb ist umgekippt, die Passagiere sind leicht verletzt.",
    "**¡Aterrizaje brusco!** La cesta volcó y los pasajeros tienen heridas leves.",
    "**ハードランディング**！バスケットが倒れ、乗客が軽いけがをした。",
    "**거친 착륙!** 바스켓이 넘어져 승객들이 가벼운 부상을 입었습니다.")
add("flight.land.crash",
    "**You hit a fairy chimney!** The balloon is badly damaged and passengers are injured.",
    "**Peribacasına çarptın!** Balon ağır hasarlı, yolcular yaralı.",
    "**Du hast einen Feenkamin gerammt!** Der Ballon ist schwer beschädigt, die Passagiere sind verletzt.",
    "**¡Chocaste con una chimenea de hadas!** El globo está muy dañado y los pasajeros, heridos.",
    "**妖精の煙突に激突**！気球は大破し、乗客がけがをした。",
    "**요정의 굴뚝에 부딪혔습니다!** 열기구가 크게 부서지고 승객들이 다쳤습니다.")
add("flight.land.crash.abq",
    "**You hit a cottonwood!** The balloon is badly damaged and passengers are injured.",
    "**Kavak ağacına çarptın!** Balon ağır hasarlı, yolcular yaralı.",
    "**Du bist in eine Pappel gekracht!** Der Ballon ist schwer beschädigt, die Passagiere sind verletzt.",
    "**¡Chocaste con un álamo!** El globo está muy dañado y los pasajeros, heridos.",
    "**ハコヤナギに激突**！気球は大破し、乗客がけがをした。",
    "**미루나무에 부딪혔습니다!** 열기구가 크게 부서지고 승객들이 다쳤습니다.")
add("flight.missionOk", "Mission complete: %@!", "Görev tamam: %@!", "Auftrag erfüllt: %@!", "¡Misión cumplida: %@!", "依頼達成：%@！", "임무 완료: %@!")
add("flight.missionFail", "Mission failed: %@.", "Görev tamamlanamadı: %@.", "Auftrag nicht erfüllt: %@.", "Misión fallida: %@.", "依頼失敗：%@。", "임무 실패: %@.")
add("flight.dayReport", "Day report", "Gün sonu raporu", "Tagesbericht", "Informe del día", "本日のレポート", "일일 보고서")

# Canvas labels
add("flight.kmh", "%@ km/h", "%@ km/sa", "%@ km/h", "%@ km/h", "%@ km/h", "%@ km/h")
add("flight.toField", "Landing field %@ km", "İniş alanı %@ km", "Landefeld %@ km", "Zona de aterrizaje %@ km", "着陸場まで%@ km", "착륙장 %@ km")
add("flight.proposalZone", "PROPOSAL ZONE  250–350 m", "TEKLİF ALANI  250–350 m", "ANTRAGSZONE  250–350 m", "ZONA DE PEDIDA  250–350 m", "プロポーズ高度  250–350 m", "청혼 구역  250–350 m")
add("flight.proposalProgress", "%@/8 s", "%@/8 sn", "%@/8 s", "%@/8 s", "%@/8秒", "%@/8초")
add("flight.missionPop", "Mission complete! +%@", "Görev tamamlandı! +%@", "Auftrag erfüllt! +%@", "¡Misión cumplida! +%@", "依頼達成！+%@", "임무 성공! +%@")
add("flight.alt", "Altitude", "İrtifa", "Höhe", "Altitud", "高度", "고도")
add("flight.vert", "Vertical", "Dikey", "Vertikal", "Vertical", "昇降", "수직")
add("flight.fuel", "Fuel", "Yakıt", "Gas", "Combustible", "燃料", "연료")
add("flight.meters", "%@ m", "%@ m", "%@ m", "%@ m", "%@ m", "%@ m")

# Cancel before take-off
add("flight.abort.title", "Cancel the flight?", "Uçuş iptal edilsin mi?", "Flug absagen?", "¿Cancelar el vuelo?", "フライトを中止する？", "비행을 취소할까요?")
add("flight.abort.lead",
    "The balloon hasn't left the ground yet. If you cancel, you pay compensation to the tourists in the basket. Passengers: %@",
    "Balon henüz yerden kalkmadı. İptal edersen sepetteki turistlere tazminat ödersin. Yolcu: %@",
    "Der Ballon ist noch am Boden. Wenn du absagst, zahlst du den Touristen im Korb eine Entschädigung. Passagiere: %@",
    "El globo aún no ha despegado. Si cancelas, pagas una indemnización a los turistas de la cesta. Pasajeros: %@",
    "気球はまだ地上にいる。中止するとバスケットの観光客に補償金を払う。乗客：%@",
    "열기구가 아직 이륙하지 않았습니다. 취소하면 바스켓의 관광객에게 보상금을 지급합니다. 승객: %@")
add("flight.abort.refund", "Ticket refunds (lost revenue)", "Bilet iadesi (gelir kaybı)", "Ticketerstattung (Umsatzverlust)", "Reembolso de billetes (ingresos perdidos)", "チケット払い戻し（売上減）", "티켓 환불 (매출 손실)")
add("flight.abort.comp", "Compensation per person: %@", "Kişi başı tazminat: %@", "Entschädigung pro Person: %@", "Indemnización por persona: %@", "1人あたりの補償：%@", "1인당 보상: %@")
add("flight.abort.rep", "Popularity", "Popülerlik", "Beliebtheit", "Popularidad", "人気", "인기")
add("flight.abort.total", "From your cash", "Kasadan çıkacak", "Aus der Kasse", "Sale de tu caja", "資金から", "현금에서 지출")
add("flight.abort.hint",
    "Since you don't fly, today doesn't renew your pilot license.",
    "Uçmadığın için bugün pilot lisansın yenilenmez.",
    "Da du nicht fliegst, wird deine Pilotenlizenz heute nicht verlängert.",
    "Como no vuelas, hoy no se renueva tu licencia de piloto.",
    "飛ばないので、今日は操縦免許が更新されない。",
    "비행하지 않으므로 오늘은 조종 면허가 갱신되지 않습니다.")
add("flight.abort.keep", "Keep flying", "Uçuşa devam", "Weiterfliegen", "Seguir volando", "フライトを続ける", "비행 계속")
add("flight.abort.confirm", "Cancel flight", "İptal et", "Flug absagen", "Cancelar vuelo", "中止する", "취소하기")

# Gathering passengers (CollectView)
add("collect.title", "Gathering passengers…", "Yolcular toplanıyor…", "Passagiere werden gesammelt …", "Reuniendo pasajeros…", "乗客を集めています…", "승객을 모으는 중…")
add("collect.sub", "Ticket: %1$@ · Balloons: %2$@", "Bilet: %1$@ · Balon: %2$@", "Ticket: %1$@ · Ballone: %2$@", "Billete: %1$@ · Globos: %2$@", "チケット：%1$@・気球：%2$@", "티켓: %1$@ · 열기구: %2$@")
add("collect.full", "Balloons are full!", "Balonlar doldu!", "Die Ballone sind voll!", "¡Los globos están llenos!", "気球は満席！", "열기구가 꽉 찼어요!")
add("collect.ready", "Passengers ready", "Yolcular hazır", "Passagiere bereit", "Pasajeros listos", "乗客の準備完了", "승객 준비 완료")
add("collect.skip", "Skip", "Atla", "Überspringen", "Saltar", "スキップ", "건너뛰기")
add("collect.takeOff", "Take off", "Kalkışa geç", "Abheben", "Despegar", "離陸へ", "이륙하기")
add("collect.pilotsGo", "Pilots fly", "Pilotlar uçsun", "Die Piloten fliegen", "Que vuelen los pilotos", "パイロットが飛ぶ", "조종사들이 비행")
add("collect.pilotGo", "Your pilot flies", "Pilot uçursun", "Dein Pilot fliegt", "Que vuele tu piloto", "パイロットが飛ぶ", "조종사가 비행")
add("collect.onlyPilots", "Only the pilots fly", "Sadece pilotlar uçsun", "Nur die Piloten fliegen", "Solo vuelan los pilotos", "パイロットだけが飛ぶ", "조종사만 비행")
add("collect.selfAndPilots", "You and your pilots fly", "Sen ve pilotlar uçsun", "Du und deine Piloten fliegen", "Tú y tus pilotos vuelan", "あなたとパイロットが飛ぶ", "당신과 조종사들이 비행")
add("collect.selfGo", "Fly it yourself", "Kendin uç", "Flieg selbst", "Vuela tú", "自分で飛ぶ", "직접 비행")
add("collect.src.tourists", "Tourists in %@", "%@ bölgesindeki turistler", "Touristen in %@", "Turistas en %@", "%@の観光客", "%@의 관광객")
add("collect.src.guide", "Guide referrals", "Rehber tavsiyesi", "Empfehlungen der Guides", "Recomendación de guías", "ガイドの紹介", "가이드 추천")
add("collect.src.influencer", "Influencer post", "Influencer paylaşımı", "Influencer-Beitrag", "Publicación de influencers", "インフルエンサーの投稿", "인플루언서 게시물")
add("collect.src.popularity", "Your popularity", "Popülerliğin", "Deine Beliebtheit", "Tu popularidad", "あなたの人気", "당신의 인기")

# Red flag confirmation (RedFlagView)
add("red.title", "Red flag!", "Kırmızı bayrak!", "Rote Flagge!", "¡Bandera roja!", "赤い旗！", "빨간 깃발!")
add("red.lead",
    "The wind is far too strong today and flying is banned. If you take your balloons up anyway (balloons: %@):",
    "Bugün rüzgâr çok sert ve uçuş yasak. Balonları yine de kaldırırsan (balon: %@):",
    "Heute ist der Wind viel zu stark, Fliegen ist verboten. Wenn du trotzdem startest (Ballone: %@):",
    "Hoy el viento es demasiado fuerte y está prohibido volar. Si despegas igualmente (globos: %@):",
    "今日は風が強すぎて飛行禁止。それでも飛ばすなら（気球：%@）：",
    "오늘은 바람이 너무 강해 비행이 금지되었습니다. 그래도 띄운다면 (열기구: %@):")
add("red.fine",
    "%1$@ chance of a %2$@ fine and a strike. Strikes so far: %3$@/3. The third brings a 3-day flying ban.",
    "%1$@ ihtimalle %2$@ ceza ve bir uyarı alırsın. Uyarı sayın: %3$@/3. Üçüncüsünde 3 gün uçuş yasağı gelir.",
    "%1$@ Risiko einer Strafe von %2$@ und einer Verwarnung. Verwarnungen bisher: %3$@/3. Bei der dritten gibt es 3 Tage Flugverbot.",
    "%1$@ de probabilidad de una multa de %2$@ y un aviso. Avisos hasta ahora: %3$@/3. Con el tercero llegan 3 días sin volar.",
    "%1$@の確率で%2$@の罰金と警告。現在の警告：%3$@/3。3回目で3日間の飛行禁止。",
    "%1$@ 확률로 %2$@ 벌금과 경고를 받습니다. 현재 경고: %3$@/3. 세 번째에는 3일 비행 금지가 내려집니다.")
add("red.insurance",
    "Insurance pays for no damage or compensation today.",
    "Sigorta bugün hiçbir hasarı ve tazminatı ödemez.",
    "Die Versicherung zahlt heute weder Schäden noch Entschädigungen.",
    "Hoy el seguro no cubre ningún daño ni indemnización.",
    "今日は保険が損害も補償金も一切払わない。",
    "오늘은 보험이 어떤 손해나 보상금도 지급하지 않습니다.")
add("red.risk",
    "Accident risk is very high: up to %@ per balloon.",
    "Kaza riski çok yüksek: balon başına en fazla %@.",
    "Unfallrisiko sehr hoch: bis zu %@ pro Ballon.",
    "Riesgo de accidente muy alto: hasta %@ por globo.",
    "事故リスクが非常に高い：気球1機あたり最大%@。",
    "사고 위험이 매우 높습니다: 열기구당 최대 %@.")
add("red.reviews",
    "Passengers will write in their reviews that you broke the rules.",
    "Yolcular kuralları çiğnediğini yorumlarda yazar.",
    "Die Passagiere schreiben in ihren Bewertungen, dass du die Regeln gebrochen hast.",
    "Los pasajeros escribirán en sus reseñas que te saltaste las normas.",
    "乗客はあなたがルールを破ったとレビューに書く。",
    "승객들이 당신이 규칙을 어겼다고 후기에 씁니다.")
add("red.sure", "Are you sure?", "Emin misin?", "Bist du sicher?", "¿Seguro?", "本当に飛ぶ？", "정말 띄울까요?")
add("red.skip", "Skip today", "Pas geç", "Heute aussetzen", "Saltar hoy", "今日は休む", "오늘은 쉬기")
add("red.fly", "Fly anyway", "Yine de uç", "Trotzdem fliegen", "Volar igualmente", "それでも飛ぶ", "그래도 비행")
