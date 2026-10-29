"""Port of v122.11 to v123.5 to Swift: day 3's price reminder, the holding's seventh goal (the World Games show), and the
guide office's local guide names per region. The letter's own strings are in s41_letter.py."""
from s1_ui import add

# v122.11: day 3's price reminder (HEZ.price3 / HEZ_SHORT.price3)
add("hez.price3",
    "Yesterday's crowd is gone, kid; today the valley has its usual tourists. Set the price every morning for that day's tourists: keep yesterday's high price and your seats go empty, lower it for nothing and you leave money on the table. You set the price in the Ticket box at the bottom.",
    "Dünkü kalabalık geçti evlat; bugün vadide turist her zamanki kadar. Fiyatı her sabah o günün turistine göre ayarla: dünkü yüksek fiyatta kalırsan koltukların boş gider, gereksiz düşürürsen de para kaçırırsın. Fiyatı alttaki Bilet kutusundan ayarlarsın.",
    "Der Andrang von gestern ist vorbei, Lehrling; heute sind so viele Touristen im Tal wie immer. Stell den Preis jeden Morgen auf die Touristen des Tages ein: Bleibst du beim hohen Preis von gestern, bleiben deine Plätze leer, senkst du ihn ohne Grund, verschenkst du Geld. Den Preis stellst du unten im Ticket-Feld ein.",
    "La multitud de ayer ya pasó, aprendiz; hoy hay en el valle los turistas de siempre. Ajusta el precio cada mañana a los turistas del día: si te quedas con el precio alto de ayer, tus plazas se quedan vacías, y si lo bajas sin motivo, pierdes dinero. El precio se ajusta en la casilla Billete de abajo.",
    "弟子よ、昨日の混雑は終わった。今日の谷の観光客はいつも通りだ。料金は毎朝その日の客に合わせて決めるのだ。昨日の高い料金のままだと席が空くし、必要もないのに下げれば儲けを逃す。料金は下のチケット欄で設定するのだ。",
    "제자여, 어제의 인파는 지나갔네. 오늘 계곡의 관광객은 평소만큼이라네. 가격은 매일 아침 그날의 관광객에 맞춰 정하게. 어제의 높은 가격을 그대로 두면 좌석이 비고, 괜히 내리면 돈을 놓친다네. 가격은 아래 티켓 칸에서 정한다네.")
add("tip.price3.short",
    "Yesterday's crowd is gone, kid: set the price again for today's tourists.",
    "Dünkü kalabalık geçti evlat: fiyatı bugünün turistine göre yeniden ayarla.",
    "Der Andrang von gestern ist vorbei, Lehrling: Stell den Preis neu auf die heutigen Touristen ein.",
    "La multitud de ayer ya pasó, aprendiz: vuelve a ajustar el precio a los turistas de hoy.",
    "弟子よ、昨日の混雑は終わった。今日の客に合わせて料金を決め直すのだ。",
    "제자여, 어제의 인파는 지나갔네. 오늘 관광객에 맞춰 가격을 다시 정하게.")

# v123.5: the World Games show is the holding's seventh goal, and opens with the Baron of Bristol
add("hgoal.worldGames", "World Games show", "Dünya Oyunları gösterisi", "Show bei den Weltspielen", "Espectáculo de los Juegos Mundiales", "世界競技大会のショー", "세계 대회 쇼")
add("holding.wg.lockBri", "Once you're Baron of Bristol", "Bristol Baronu olunca", "Sobald du Baron von Bristol bist", "Cuando seas barón de Bristol", "ブリストルの男爵になったら", "브리스톨의 남작이 되면")

# v124 (f9e60f0): the guide office's guides are local in every region (GUIDE_NAMES). Cappadocia keeps guide.<id>.name
# (Ayşe, Sena, Ekin); every other region has guidePick.<region>.<id> and its title, by the guide's gender. Same ids,
# costs and effects. To add a region, add one line here: its three guides as (name in en/tr/de/es, ja, ko, gender).
GUIDE_NAMES = {
    "abq": [("Emily", "エミリー", "에밀리", "f"), ("Carlos", "カルロス", "카를로스", "m"), ("Dakota", "ダコタ", "다코타", "f")],
    "lux": [("Nour", "ヌール", "누르", "f"), ("Karim", "カリーム", "카림", "m"), ("Yasmin", "ヤスミン", "야스민", "f")],
}
GUIDE_TITLES = {  # slot → gender → en, tr, de, es, ja, ko (the feminine forms are guide.<id>.title in s40_v122.py)
    "ayse": {"f": ("Hotel guide", "Otel rehberi", "Hotelguide", "Guía de hotel", "ホテルのガイド", "호텔 가이드"),
             "m": ("Hotel guide", "Otel rehberi", "Hotelguide", "Guía de hotel", "ホテルのガイド", "호텔 가이드")},
    "mehmet": {"f": ("Tour guide", "Tur rehberi", "Reiseleiterin", "Guía turística", "ツアーガイド", "투어 가이드"),
               "m": ("Tour guide", "Tur rehberi", "Reiseleiter", "Guía turístico", "ツアーガイド", "투어 가이드")},
    "selin": {"f": ("Senior guide", "Kıdemli rehber", "Erfahrene Reiseleiterin", "Guía veterana", "ベテランガイド", "베테랑 가이드"),
              "m": ("Senior guide", "Kıdemli rehber", "Erfahrener Reiseleiter", "Guía veterano", "ベテランガイド", "베테랑 가이드")},
}
for region, guides in GUIDE_NAMES.items():
    for gid, (latin, ja, ko, gender) in zip(["ayse", "mehmet", "selin"], guides):
        add(f"guidePick.{region}.{gid}", latin, latin, latin, latin, ja, ko)
        add(f"guidePick.{region}.{gid}.title", *GUIDE_TITLES[gid][gender])
