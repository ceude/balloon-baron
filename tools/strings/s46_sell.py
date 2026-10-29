from s1_ui import add

# v124.5: selling a balloon asks first, in the game's own card, and says "sold" after.
add("sell.title", "Sell this balloon?", "Balonu sat", "Ballon verkaufen?", "¿Vender este globo?", "気球を売る？", "열기구를 팔까요?")
add("sell.lead",
 "%1$@ will be sold for %2$@. The money goes straight into the till.",
 "%1$@ %2$@ karşılığında satılacak. Para hemen kasaya girer.",
 "%1$@ wird für %2$@ verkauft. Das Geld kommt sofort in die Kasse.",
 "%1$@ se venderá por %2$@. El dinero entra en caja al momento.",
 "%1$@を%2$@で売る。お金はすぐに金庫に入る。",
 "%1$@을(를) %2$@에 팝니다. 돈은 바로 금고에 들어옵니다.")
add("sell.used",
 "It is second-hand, so it fetches 40% of its price.",
 "İkinci el olduğu için değerinin %40'ı ödenir.",
 "Er ist gebraucht, daher gibt es 40 % seines Preises.",
 "Es de segunda mano, así que se paga el 40 % de su precio.",
 "中古なので、価格の40%で売れる。",
 "중고라서 가격의 40%를 받습니다.")
add("sell.flagship",
 "It is your flagship; the flag moves to another balloon.",
 "Amiral balonun bu. Amiral başka bir balona geçer.",
 "Es ist dein Flaggschiff; die Flagge geht an einen anderen Ballon.",
 "Es tu globo insignia; la insignia pasa a otro globo.",
 "これは旗艦だ。旗艦は別の気球に移る。",
 "기함입니다. 기함은 다른 열기구로 넘어갑니다.")
add("sell.pilot",
 "Its pilot %@ moves to another balloon or waits.",
 "Pilotu %@ başka balona geçer ya da boşta kalır.",
 "Sein Pilot %@ wechselt auf einen anderen Ballon oder wartet.",
 "Su piloto %@ pasa a otro globo o se queda libre.",
 "パイロットの%@は別の気球に移るか、待機になる。",
 "조종사 %@ 님은 다른 열기구로 가거나 대기합니다.")
add("sell.cancel", "Cancel", "Vazgeç", "Abbrechen", "Cancelar", "やめる", "취소")
add("sell.done", "%1$@ sold · +%2$@", "%1$@ satıldı · +%2$@", "%1$@ verkauft · +%2$@", "%1$@ vendido · +%2$@", "%1$@を売却 · +%2$@", "%1$@ 판매 완료 · +%2$@")
