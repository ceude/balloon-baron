from s1_ui import add

# v142 (version 1.0.1, developer): the Mara goal says how it's met; the report names the brought balloons' instalment;
# the workshop's production lines are per region.

# The holding goal "Fly a full safari-plane group in the Mara": under it in the goals list once the Mara is entered.
add("hgoal.maraGroupHow", "Accept a safari-plane deal in the Mara and fly the whole group.",
    "Mara'da bir safari uçağı anlaşmasını kabul et ve grubu eksiksiz uçur.",
    "Nimm in der Mara einen Safariflug-Auftrag an und fliege die ganze Gruppe.",
    "Acepta un trato de avioneta safari en el Mara y vuela con todo el grupo.",
    "マラでサファリ機の契約を受けて、団体を一人残らず乗せよう。",
    "마라에서 사파리 비행기 계약을 수락하고 단체 전원을 태우세요.")

# The day's report: the payment for balloons brought from another region, and which of the 30 it is (7/30).
add("ledger.transferN", "Balloons brought from home (instalment %1$@/%2$@)", "Getirilen balonların bedeli (taksit %1$@/%2$@)",
    "Mitgebrachte Ballone (Rate %1$@/%2$@)", "Globos traídos de casa (cuota %1$@/%2$@)", "持ち込んだ気球の代金（分割 %1$@/%2$@）",
    "가져온 열기구 대금 (할부 %1$@/%2$@)")

# The workshop's level card, once you own more than one region: a new region starts at level 1.
add("factory.perRegion", "Each region has its own production lines; your designs work in every region.",
    "Her bölgenin kendi üretim hatları var; tasarımların bütün bölgelerde geçerli.",
    "Jede Region hat ihre eigenen Produktionslinien; deine Designs gelten in allen Regionen.",
    "Cada región tiene sus propias líneas de producción; tus diseños sirven en todas las regiones.",
    "生産ラインは地域ごと。デザインはすべての地域で使える。",
    "생산 라인은 지역마다 따로 있고, 디자인은 모든 지역에서 쓸 수 있습니다.")
