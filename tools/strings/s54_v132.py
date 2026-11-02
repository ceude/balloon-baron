from s1_ui import add

# v132: TestFlight fixes. A Balloon Show (or Night Glow) that can't happen says so; the holding's million goal stays met.

add("event.showSeized", "The bank took a balloon that was in tonight's show. Its fee came back: %@.",
    "Bankanın aldığı balon bu geceki şölendeydi, çıkamayacak. Ücreti kasana döndü: %@.",
    "Die Bank hat einen Ballon aus der heutigen Show genommen. Seine Gebühr kam zurück: %@.",
    "El banco se llevó un globo que iba en el espectáculo de esta noche. Su tarifa se devolvió: %@.",
    "銀行が今夜のショーに出る気球を差し押さえた。その分の費用が戻った：%@。",
    "은행이 오늘 밤 쇼에 나갈 열기구를 가져갔어요. 그 비용은 돌아왔어요: %@.")

add("report.showOffTitle", "No Balloon Show tonight.", "Bu gece Balon Şöleni yok.", "Heute Nacht keine Ballon-Show.",
    "Esta noche no hay Espectáculo de globos.", "今夜のバルーンショーは中止。", "오늘 밤 열기구 쇼는 취소예요.")
add("report.showOffBody",
    "After today too few balloons can go up (at least %1$@ are needed), so tonight's show is called off. Every fee came back to your cash: %2$@. You can book a new one as soon as enough balloons can fly.",
    "Bugünden sonra şölene yeterli balon kalmadı (en az %1$@ gerekiyor), bu geceki şölen iptal. Bütün ücretler kasana döndü: %2$@. Yeterli balon uçabilir olunca yenisini hemen düzenleyebilirsin.",
    "Nach dem heutigen Tag können zu wenige Ballone aufsteigen (mindestens %1$@ sind nötig), die Show heute Nacht fällt aus. Alle Gebühren kamen zurück: %2$@. Sobald genug Ballone fliegen können, kannst du eine neue buchen.",
    "Después de hoy no quedan globos suficientes (hacen falta al menos %1$@), así que el espectáculo de esta noche se cancela. Te devolvieron todas las tarifas: %2$@. Podrás organizar otro en cuanto vuelvan a poder volar suficientes globos.",
    "今日のあと飛べる気球が足りない（最低%1$@機必要）ため、今夜のショーは中止。費用はすべて戻った：%2$@。十分な気球が飛べるようになればすぐ新しく開ける。",
    "오늘 이후 뜰 수 있는 열기구가 모자라(최소 %1$@대 필요) 오늘 밤 쇼는 취소예요. 비용은 모두 돌아왔어요: %2$@. 열기구가 충분히 뜰 수 있게 되면 바로 새로 열 수 있어요.")
add("night.showOff", "Balloon Show called off. Fees refunded: %@", "Balon Şöleni iptal. Ücretler iade: %@",
    "Ballon-Show abgesagt. Gebühren erstattet: %@", "Espectáculo de globos cancelado. Tarifas devueltas: %@",
    "バルーンショーは中止。返金：%@", "열기구 쇼 취소. 환불: %@")

add("hez.nightOff.show",
    "You left a region on the day of its Balloon Show, kid, so tonight's show is called off. Region: %1$@. The fee went back to its cash: %2$@.",
    "Şölen gününde bölgeden ayrıldın evlat, bu geceki Balon Şöleni iptal oldu. Bölge: %1$@. Ücret oranın kasasına döndü: %2$@.",
    "Du hast eine Region am Tag ihrer Ballon-Show verlassen, die Show heute Nacht fällt aus. Region: %1$@. Die Gebühr ging zurück in ihre Kasse: %2$@.",
    "Te fuiste de una región el día de su Espectáculo de globos, así que el de esta noche se cancela. Región: %1$@. La tarifa volvió a su caja: %2$@.",
    "ショーの日にその地域を離れたので、今夜のバルーンショーは中止だ。地域：%1$@。費用はその地域の資金に戻った：%2$@。",
    "쇼가 있는 날 그 지역을 떠나서 오늘 밤 열기구 쇼는 취소됐어요. 지역: %1$@. 비용은 그 지역 금고로 돌아갔어요: %2$@.")
add("hez.nightOff.glow",
    "You left a region on the day of its Night Glow, kid, so tonight's glow is called off. Region: %1$@. The fee went back to its cash: %2$@.",
    "Gece Işıltısı gününde bölgeden ayrıldın evlat, bu geceki ışıltı iptal oldu. Bölge: %1$@. Ücret oranın kasasına döndü: %2$@.",
    "Du hast eine Region am Tag ihres Night Glow verlassen, das Glühen heute Nacht fällt aus. Region: %1$@. Die Gebühr ging zurück in ihre Kasse: %2$@.",
    "Te fuiste de una región el día de su Night Glow, así que el de esta noche se cancela. Región: %1$@. La tarifa volvió a su caja: %2$@.",
    "ナイトグローの日にその地域を離れたので、今夜のグローは中止だ。地域：%1$@。費用はその地域の資金に戻った：%2$@。",
    "나이트 글로가 있는 날 그 지역을 떠나서 오늘 밤 글로는 취소됐어요. 지역: %1$@. 비용은 그 지역 금고로 돌아갔어요: %2$@.")

add("show.glow", "The Night Glow is booked tonight. The show can take another night.",
    "Bu gece Gece Işıltısı var. Şölen başka bir gece olabilir.",
    "Heute Nacht ist der Night Glow gebucht. Die Show kann an einem anderen Abend stattfinden.",
    "Esta noche está reservado el Night Glow. El espectáculo puede ser otra noche.",
    "今夜はナイトグローが予約済み。ショーは別の夜にしよう。",
    "오늘 밤은 나이트 글로가 예약돼 있어요. 쇼는 다른 밤에 할 수 있어요.")

# The million goal: what it measures, and that it stays met once reached.
add("hgoal.millionNow", "Holding cash now: %@", "Holding kasası şu an: %@", "Holding-Kasse jetzt: %@",
    "Caja del holding ahora: %@", "現在のホールディングス資金：%@", "현재 지주회사 금고: %@")
add("hgoal.millionOn", "Reached on day %@", "Ulaşıldı: gün %@", "Erreicht an Tag %@", "Alcanzado el día %@",
    "%@日目に達成", "%@일차에 달성")
