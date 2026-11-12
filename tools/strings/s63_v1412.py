from s1_ui import add

# v141.2 (developer): the offices page says little: a one-line rule, short perks, short rent and lock lines. The TV
# campaign goal gave way to the Maasai Mara's first safari-plane group.

# ---- Offices ----
add("holding.officesIntro", "4 offices: expenses %1$@. All 6: %2$@.", "4 ofis: giderler %1$@. 6 ofis: %2$@.",
    "4 Büros: Ausgaben %1$@. Alle 6: %2$@.", "4 oficinas: gastos %1$@. Las 6: %2$@.",
    "4オフィスで経費%1$@、6つで%2$@。", "사무소 4곳: 비용 %1$@. 6곳: %2$@.")
add("holding.officesIntroSix", "All 6 open: expenses %@.", "6 ofis açık: giderler %@.", "Alle 6 offen: Ausgaben %@.",
    "Las 6 abiertas: gastos %@.", "6オフィスすべて開設：経費%@。", "6곳 모두 개설: 비용 %@.")
add("holding.officesRentDay", "Rent: %@ a day.", "Kira: günde %@.", "Miete: %@ pro Tag.", "Alquiler: %@ al día.",
    "家賃：1日%@。", "임대료: 하루 %@.")
add("holding.office.rent", "Rent: %@/day", "Kira: %@/gün", "Miete: %@/Tag", "Alquiler: %@/día", "家賃：%@/日", "임대료: %@/일")
add("holding.officeLocked", "Opens with %@", "Açan bölge: %@", "Öffnet mit %@", "Se abre con %@", "%@で開放", "%@ 진출 시 개방")
PERKS = {
    "ist": ("Cappadocia +25% autopilot", "Kapadokya +%25 otomatik kazanç", "Kappadokien +25 % Autopilot", "Capadocia +25 % automático",
            "カッパドキア自動運営 +25%", "카파도키아 자동 운영 +25%"),
    "sel": ("Celebrities −25%", "Ünlü −%25", "Promis −25 %", "Famosos −25 %", "有名人 −25%", "유명인 −25%"),
    "nyc": ("TV −25% · Albuquerque +20%", "TV −%25 · Albuquerque +%20", "TV −25 % · Albuquerque +20 %", "TV −25 % · Albuquerque +20 %",
            "TV −25% · アルバカーキ +20%", "TV −25% · 앨버커키 +20%"),
    "par": ("Bristol +20% · Documentary −20%", "Bristol +%20 · Belgesel −%20", "Bristol +20 % · Doku −20 %", "Bristol +20 % · Documental −20 %",
            "ブリストル +20% · ドキュメンタリー −20%", "브리스톨 +20% · 다큐 −20%"),
    "tyo": ("Luxor +20% · Tourists +5% · Designs", "Luksor +%20 · Turist +%5 · Tasarım", "Luxor +20 % · Touristen +5 % · Designs",
            "Luxor +20 % · Turistas +5 % · Diseños", "ルクソール +20% · 観光客 +5% · デザイン", "룩소르 +20% · 관광객 +5% · 디자인"),
    "dxb": ("Mara +20% · Records −25%", "Mara +%20 · Rekor −%25", "Mara +20 % · Rekorde −25 %", "Mara +20 % · Récords −25 %",
            "マラ +20% · 記録 −25%", "마라 +20% · 기록 −25%"),
}
for k, t in PERKS.items():
    add(f"office.{k}.perk", *t)

# ---- The holding's goal ----
# v142 (players found it unclear): says what to do; a line under it in the goals list says how (s65_v142.py)
add("hgoal.maraGroup", "Fly a full safari-plane group in the Mara", "Mara'da bir safari uçağı grubunu uçur", "Safariflug-Gruppe in der Mara fliegen",
    "Vuela un grupo de avioneta safari en el Mara", "マラでサファリ機の団体を乗せる", "마라에서 사파리 비행기 단체 태우기")
add("hgoal.maraGroupNote", "The Maasai Mara opens with the Baron of Bristol.", "Maasai Mara, Bristol baronluğuyla açılır.",
    "Die Maasai Mara öffnet mit dem Baron von Bristol.", "El Maasai Mara se abre al ser barón de Bristol.",
    "マサイマラはブリストル男爵で開放。", "마사이마라는 브리스톨 남작이 되면 열립니다.")
