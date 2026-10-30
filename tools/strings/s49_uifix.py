# v125.6: UI fixes. The offer card's penalty callout (the rule without the penalty, which has its own line), the
# transfer card's note when nothing more fits, and balloons on their way by cargo in the fleet list.
from s1_ui import add

add("ctr.penalty", "Penalty per missing seat: %@", "Eksik koltuk başına ceza: %@", "Strafe pro fehlendem Platz: %@",
    "Multa por plaza que falte: %@", "不足座席1つにつき違約金：%@", "부족한 좌석당 위약금: %@")
add("ctr.rule2.fog", "Every morning the seats go to the group first. Fog guarantee: on a foggy morning that day's tickets are refunded, plus a %@ voucher a head.",
    "Her sabah koltuklar önce gruba gider. Sis garantisi: sisli sabah o günün bilet parası iade edilir, üstüne kişi başı %@ kupon verilir.",
    "Jeden Morgen gehen die Plätze zuerst an die Gruppe. Nebelgarantie: An einem nebligen Morgen werden die Tickets des Tages erstattet, dazu ein Gutschein von %@ pro Kopf.",
    "Cada mañana las plazas van primero al grupo. Garantía de niebla: una mañana con niebla se devuelven los billetes del día y además un vale de %@ por cabeza.",
    "毎朝、座席はまずグループへ。霧保証：霧の朝はその日のチケット代を返金し、さらに1人%@のクーポン。",
    "매일 아침 좌석은 먼저 단체에게 갑니다. 안개 보증: 안개 낀 아침엔 그날 표값을 환불하고 1인당 %@ 쿠폰을 더 줍니다.")
add("ctr.rule2.block", "For %@ mornings the seats go to the group first, and the penalty counts every morning. A red-flag morning doesn't count.",
    "%@ sabah boyunca koltuklar önce gruba gider, ceza her sabah ayrı. Kırmızı bayraklı sabah sayılmaz.",
    "%@ Morgen lang gehen die Plätze zuerst an die Gruppe; die Strafe gilt jeden Morgen. Ein Morgen mit roter Flagge zählt nicht.",
    "Durante %@ mañanas las plazas van primero al grupo, y la multa cuenta cada mañana. Una mañana con bandera roja no cuenta.",
    "%@日間、毎朝座席はまずグループへ。違約金は毎朝かかる。赤い旗の朝は数えない。",
    "%@일 아침 동안 좌석은 먼저 단체에게 갑니다. 위약금은 매일 아침 따로 붙습니다. 빨간 깃발 아침은 치지 않습니다.")
add("ctr.rule2.one", "That morning the seats go to the group first; on a red flag the group moves a day (at %@ off).",
    "O sabah koltuklar önce gruba gider; kırmızı bayrakta grup bir gün kayar (%@ indirimle).",
    "An dem Morgen gehen die Plätze zuerst an die Gruppe; bei roter Flagge rückt die Gruppe einen Tag weiter (mit %@ Rabatt).",
    "Esa mañana las plazas van primero al grupo; con bandera roja el grupo se mueve un día (con un %@ de descuento).",
    "その朝、座席はまずグループへ。赤い旗ならグループは1日ずれる（%@引き）。",
    "그날 아침 좌석은 먼저 단체에게 갑니다. 빨간 깃발이면 단체는 하루 밀립니다(%@ 할인).")

add("xfer.cargoFull", "Cargo full: untick one to swap", "Kargo dolu: değiştirmek için birinin işaretini kaldır",
    "Fracht voll: zum Tauschen einen abwählen", "Carga llena: desmarca uno para cambiar",
    "貨物は満杯：入れ替えるには1つ外して", "화물이 가득: 바꾸려면 하나를 해제하세요")
add("xfer.pilotsFull", "No room left: untick one to swap", "Yer dolu: değiştirmek için birinin işaretini kaldır",
    "Kein Platz mehr: zum Tauschen einen abwählen", "No queda sitio: desmarca uno para cambiar",
    "枠がいっぱい：入れ替えるには1人外して", "자리가 가득: 바꾸려면 한 명을 해제하세요")

add("fleet.row.cargo", "In cargo · Days left: %@", "Kargoda: %@ gün kaldı", "In der Fracht · Verbleibende Tage: %@",
    "En la carga · Días restantes: %@", "輸送中・残り日数：%@", "화물 운송 중 · 남은 일수: %@")
