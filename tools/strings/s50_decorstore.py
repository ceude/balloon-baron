# v125.7: the bazaar's "Your decorations" shelf: each owned decoration is in town or put away in storage, with a toggle.
from s1_ui import add

add("bazaar.mine", "Your decorations", "Süslerin", "Dein Schmuck", "Tus adornos", "あなたの飾り", "내 장식")
add("bazaar.mine.hint", "A decoration you put away stays yours; it just isn't shown in town. Place it again whenever you like.",
    "Depoya kaldırdığın süs senin kalır, sadece kasabada görünmez. İstediğin zaman yeniden yerleştir.",
    "Weggeräumter Schmuck bleibt deiner, er ist nur nicht in der Stadt zu sehen. Stell ihn wieder auf, wann du willst.",
    "Un adorno guardado sigue siendo tuyo; solo deja de verse en el pueblo. Vuelve a colocarlo cuando quieras.",
    "しまった飾りもあなたのもの。町に出ないだけで、いつでもまた飾れる。",
    "보관한 장식도 계속 당신 것입니다. 마을에 보이지 않을 뿐, 언제든 다시 놓을 수 있어요.")
add("bazaar.inTown", "In town", "Kasabada", "In der Stadt", "En el pueblo", "町に飾り中", "마을에 있음")
add("bazaar.stored", "In storage", "Depoda", "Im Lager", "Guardado", "しまってある", "보관 중")
add("bazaar.putAway", "Put away", "Kaldır", "Wegräumen", "Guardar", "しまう", "보관하기")
add("bazaar.place", "Place", "Yerleştir", "Aufstellen", "Colocar", "飾る", "놓기")
