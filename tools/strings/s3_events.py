from s1_ui import add

add("event.cancelled",
 "You cancelled the %1$@ flight. %2$@ passengers got their money back plus %3$@ each in compensation.",
 "%1$@ uçuşunu iptal ettin. %2$@ yolcunun bilet parası iade edildi ve kişi başı %3$@ tazminat ödendi.",
 "Du hast den Flug mit %1$@ abgesagt. %2$@ Passagiere bekamen ihr Geld zurück und je %3$@ Entschädigung.",
 "Cancelaste el vuelo de %1$@. %2$@ pasajeros recuperaron su dinero y recibieron %3$@ cada uno de indemnización.",
 "%1$@のフライトを中止した。乗客%2$@人に払い戻しと、一人%3$@の補償を支払った。",
 "%1$@ 비행을 취소했습니다. 승객 %2$@명에게 환불하고 1인당 %3$@의 보상금을 지급했습니다.")
add("event.missionDone",
 "Mission complete: %1$@. The customer paid a %2$@ reward.",
 "Görev tamamlandı: %1$@. Müşteri %2$@ ödül verdi.",
 "Auftrag erfüllt: %1$@. Der Kunde zahlte %2$@ Belohnung.",
 "Misión cumplida: %1$@. El cliente pagó una recompensa de %2$@.",
 "依頼達成：%1$@。お客から%2$@の報酬。",
 "임무 완료: %1$@. 손님이 %2$@의 보상을 지급했습니다.")
add("event.missionFailed",
 "Mission failed: %@.", "Görev tamamlanamadı: %@.", "Auftrag nicht erfüllt: %@.", "Misión fallida: %@.", "依頼失敗：%@。", "임무 실패: %@.")
add("event.perfectLanding",
 "%1$@: perfect landing. Passengers left %2$@ in tips.",
 "%1$@: kusursuz iniş. Yolcular %2$@ bahşiş bıraktı.",
 "%1$@: perfekte Landung. Die Passagiere gaben %2$@ Trinkgeld.",
 "%1$@: aterrizaje perfecto. Los pasajeros dejaron %2$@ de propina.",
 "%1$@：完璧な着陸。乗客から%2$@のチップ。",
 "%1$@: 완벽한 착륙. 승객들이 %2$@의 팁을 남겼습니다.")
add("event.goodLanding",
 "%@: smooth landing, happy passengers.", "%@: düzgün iniş, yolcular memnun.", "%@: saubere Landung, zufriedene Passagiere.", "%@: buen aterrizaje, pasajeros contentos.", "%@：スムーズな着陸。乗客は満足。", "%@: 부드러운 착륙, 승객 만족.")
add("event.farLanding",
 "%1$@: you landed %2$@ m from the target and the ground crew took a long time to find you.",
 "%1$@: hedeften %2$@ m uzağa indin, yer ekibi seni geç buldu.",
 "%1$@: Du bist %2$@ m vom Ziel gelandet, die Bodencrew hat dich spät gefunden.",
 "%1$@: aterrizaste a %2$@ m del objetivo y el equipo de tierra tardó en encontrarte.",
 "%1$@：目標から%2$@ m離れて着陸。地上クルーの到着が遅れた。",
 "%1$@: 목표에서 %2$@ m 떨어진 곳에 착륙해 지상 요원이 늦게 찾았습니다.")
add("event.accident.light",
 "%1$@ (%2$@) had a hard landing and will be grounded for %3$@ days. Repairs %4$@, compensation %5$@.",
 "%1$@ (%2$@) sert iniş yaptı ve %3$@ gün yerde kalacak. Onarım %4$@, tazminat %5$@.",
 "%1$@ (%2$@) hatte eine harte Landung und bleibt %3$@ Tage am Boden. Reparatur %4$@, Entschädigung %5$@.",
 "%1$@ (%2$@) tuvo un aterrizaje brusco y quedará en tierra %3$@ días. Reparación %4$@, indemnización %5$@.",
 "%1$@（%2$@）がハードランディング。%3$@日間地上待機。修理費%4$@、補償%5$@。",
 "%1$@ (%2$@) 거친 착륙으로 %3$@일간 운항 불가. 수리비 %4$@, 보상금 %5$@.")
add("event.accident.severe",
 "%1$@ (%2$@) had a serious accident and will be grounded for %3$@ days. Repairs %4$@, compensation %5$@.",
 "%1$@ (%2$@) ağır kaza yaptı ve %3$@ gün yerde kalacak. Onarım %4$@, tazminat %5$@.",
 "%1$@ (%2$@) hatte einen schweren Unfall und bleibt %3$@ Tage am Boden. Reparatur %4$@, Entschädigung %5$@.",
 "%1$@ (%2$@) sufrió un accidente grave y quedará en tierra %3$@ días. Reparación %4$@, indemnización %5$@.",
 "%1$@（%2$@）が重大事故。%3$@日間地上待機。修理費%4$@、補償%5$@。",
 "%1$@ (%2$@) 중대 사고로 %3$@일간 운항 불가. 수리비 %4$@, 보상금 %5$@.")
add("pilot.you", "you", "sen", "du", "tú", "あなた", "당신")
add("pilot.unknown", "pilot", "pilot", "Pilot", "piloto", "パイロット", "조종사")
add("cover.all", "Insurance paid for everything.", "Sigorta tamamını ödedi.", "Die Versicherung hat alles bezahlt.", "El seguro lo pagó todo.", "保険ですべてまかなわれた。", "보험이 모두 보상했습니다.")
add("cover.hullOnly", "Insurance paid the repairs; compensation came out of your cash.", "Sigorta onarımı ödedi, tazminat kasadan çıktı.", "Die Versicherung zahlte die Reparatur, die Entschädigung kam aus deiner Kasse.", "El seguro pagó la reparación; la indemnización salió de tu caja.", "修理は保険、補償は自腹。", "수리는 보험, 보상금은 금고에서 나갔습니다.")
add("cover.paxOnly", "Insurance paid the compensation; repairs came out of your cash.", "Sigorta tazminatı ödedi, onarım kasadan çıktı.", "Die Versicherung zahlte die Entschädigung, die Reparatur kam aus deiner Kasse.", "El seguro pagó la indemnización; la reparación salió de tu caja.", "補償は保険、修理は自腹。", "보상금은 보험, 수리비는 금고에서 나갔습니다.")
add("cover.none", "No insurance: it all came out of your cash.", "Sigorta yoktu, hepsi kasadan çıktı.", "Keine Versicherung: Alles ging aus deiner Kasse.", "Sin seguro: todo salió de tu caja.", "保険なし。すべて自腹。", "보험이 없어 모두 금고에서 나갔습니다.")
add("event.licenseRenewedByFlight",
 "You flew the renewal flight yourself. License renewed, your balloons can take off again.",
 "Yenileme uçuşunu kendin yaptın. Lisansın yenilendi, balonların yeniden kalkabilir.",
 "Du hast den Erneuerungsflug selbst gemacht. Lizenz erneuert, deine Ballone dürfen wieder starten.",
 "Hiciste tú mismo el vuelo de renovación. Licencia renovada; tus globos pueden volver a despegar.",
 "更新フライトを自分で飛んだ。免許が更新され、気球はまた飛べる。",
 "갱신 비행을 직접 마쳤습니다. 면허가 갱신되어 열기구들이 다시 이륙할 수 있습니다.")
add("event.founderAbsent",
 "You haven't been in a basket for %@ days. Passengers keep asking for the founder, and popularity is slipping.",
 "%@ gündür sepete binmedin. Yolcular kurucuyu soruyor, popülerlik eriyor.",
 "Du warst seit %@ Tagen nicht im Korb. Die Passagiere fragen nach dem Gründer, die Beliebtheit bröckelt.",
 "Llevas %@ días sin subir a una cesta. Los pasajeros preguntan por el fundador y la popularidad cae.",
 "%@日間バスケットに乗っていない。乗客は創業者を探し、人気が落ちている。",
 "%@일째 바스켓에 타지 않았습니다. 승객들이 창업자를 찾고 인기가 떨어지고 있습니다.")
add("event.redCaught",
 "Caught flying on a red flag: %2$@ fine, strike %1$@/3.",
 "Kırmızı bayrakta uçarken yakalandın: %2$@ ceza, uyarı %1$@/3.",
 "Bei roter Flagge erwischt: %2$@ Strafe, Verwarnung %1$@/3.",
 "Te descubrieron volando con bandera roja: multa de %2$@, aviso %1$@/3.",
 "赤い旗の日の飛行が発覚：罰金%2$@、警告%1$@/3。",
 "빨간 깃발에 비행하다 적발: 벌금 %2$@, 경고 %1$@/3.")
add("event.redBan",
 "Third strike: your company is banned from flying for 3 days.",
 "Üçüncü uyarı: şirketine 3 gün uçuş yasağı geldi.",
 "Dritte Verwarnung: Deine Firma darf 3 Tage nicht fliegen.",
 "Tercer aviso: tu empresa no podrá volar durante 3 días.",
 "警告3回目：3日間の飛行禁止処分。",
 "세 번째 경고: 3일간 비행 금지 처분을 받았습니다.")
add("event.redUnseen",
 "You flew on a red flag and nobody noticed. This time.",
 "Kırmızı bayrakta uçtun ve kimse fark etmedi. Bu sefer.",
 "Du bist bei roter Flagge geflogen, und keiner hat's gemerkt. Diesmal.",
 "Volaste con bandera roja y nadie se dio cuenta. Esta vez.",
 "赤い旗の日に飛んだが、誰にも気づかれなかった。今回は。",
 "빨간 깃발에 비행했지만 아무도 눈치채지 못했습니다. 이번엔.")
add("event.pilotPromoted",
 "%1$@ is now a %2$@ pilot! Accident risk is down, wage is now %3$@/day.",
 "%1$@ artık %2$@ pilot! Kaza riski düştü, maaşı %3$@/gün oldu.",
 "Neue Stufe für %1$@: %2$@! Weniger Unfallrisiko, Gehalt jetzt %3$@/Tag.",
 "¡%1$@ ya es piloto de nivel %2$@! Menos riesgo de accidente; sueldo ahora %3$@/día.",
 "%1$@が%2$@パイロットに昇格！事故リスクが下がり、日給は%3$@に。",
 "%1$@ 조종사가 %2$@ 등급이 되었습니다! 사고 위험이 줄고, 일급은 이제 %3$@입니다.")
add("event.envelopeWorn",
 "The envelope of %@ is worn out. It can't fly until renewed.",
 "%@ balonunun zarfı ömrünü doldurdu. Yenilenmeden uçamaz.",
 "Die Hülle von %@ ist verschlissen. Ohne Erneuerung kein Flug.",
 "La envoltura de %@ está desgastada. No podrá volar hasta renovarla.",
 "%@の球皮が寿命を迎えた。張り替えるまで飛べない。",
 "%@ 열기구의 외피 수명이 다했습니다. 교체 전에는 비행할 수 없습니다.")
add("event.licenseExpiring",
 "Your pilot license expires today. Tomorrow you can't fly the flagship yourself; renew it in the Crew tab.",
 "Pilot lisansın bugün sona eriyor. Yarın amiral balonunu kendin uçuramazsın; Ekip sekmesinden yenileyebilirsin.",
 "Deine Pilotenlizenz läuft heute ab. Morgen darfst du das Flaggschiff nicht selbst fliegen; erneuere sie im Bereich Crew.",
 "Tu licencia de piloto caduca hoy. Mañana no podrás pilotar el globo insignia; renuévala en la pestaña Equipo.",
 "操縦免許は今日で切れる。明日は旗艦を自分で飛ばせない。クルー画面で更新しよう。",
 "조종 면허가 오늘 만료됩니다. 내일은 기함을 직접 조종할 수 없으니 크루 탭에서 갱신하세요.")
add("event.antitrustFine",
 "The Competition Authority fined you %2$@ for holding %1$@%% of the market.",
 "Rekabet Kurumu pazarın %%%1$@ kısmını elinde tuttuğun için %2$@ tekel cezası kesti.",
 "Die Wettbewerbsbehörde hat eine Strafe von %2$@ gegen dich verhängt, weil du %1$@ %% des Marktes hältst.",
 "La Autoridad de la Competencia te multó con %2$@ por controlar el %1$@ %% del mercado.",
 "市場の%1$@%%を握っているとして、競争当局が%2$@の罰金を科した。",
 "시장의 %1$@%%를 차지해 경쟁 당국이 %2$@의 벌금을 부과했습니다.")
add("event.seized",
 "The bank seized %1$@ over your debt and sold it for %2$@.",
 "Banka borcun için %1$@ balonuna el koydu ve %2$@ karşılığında sattı.",
 "Die Bank hat wegen deiner Schulden %1$@ gepfändet und für %2$@ verkauft.",
 "El banco embargó %1$@ por tu deuda y lo vendió por %2$@.",
 "借金のため銀行が%1$@を差し押さえ、%2$@で売却した。",
 "은행이 빚 때문에 %1$@ 열기구를 압류해 %2$@에 팔았습니다.")
add("event.hotelLeft",
 "%@ ended the deal. Your popularity fell too far below its standards.",
 "%@ anlaşmayı bitirdi. Popülerliğin otelin seviyesinin çok altına düştü.",
 "%@ hat den Vertrag beendet. Deine Beliebtheit ist zu weit unter sein Niveau gefallen.",
 "%@ terminó el acuerdo. Tu popularidad cayó muy por debajo de su nivel.",
 "%@が契約を打ち切った。人気がホテルの水準を大きく下回った。",
 "%@ 측이 제휴를 끝냈습니다. 인기가 호텔 수준보다 너무 낮아졌습니다.")

# Rivals
add("event.rivalFleetSold", "The %@ fleet was sold to another buyer.", "%@ filosu başka bir alıcıya satıldı.", "Die Flotte von %@ wurde an einen anderen Käufer verkauft.", "La flota de %@ se vendió a otro comprador.", "%@のフリートは別の買い手に売却された。", "%@ 기단이 다른 구매자에게 팔렸습니다.")
add("event.newEntrant", "New rival: %1$@ has started flying in %2$@!", "Yeni rakip: %1$@ %2$@ bölgesinde uçmaya başladı!", "Neue Konkurrenz: %1$@ fliegt jetzt in %2$@!", "Nuevo rival: ¡%1$@ empieza a volar en %2$@!", "新たなライバル：%1$@が%2$@で飛行を開始！", "새 경쟁자: %1$@, %2$@에서 비행을 시작했습니다!")
add("event.rivalAccidents", "%1$@ had accidents. Balloons damaged: %2$@.", "%1$@ kaza yaptı. Hasarlı balon: %2$@.", "%1$@ hatte Unfälle. Beschädigte Ballone: %2$@.", "%1$@ tuvo accidentes. Globos dañados: %2$@.", "%1$@で事故。損傷した気球：%2$@機。", "%1$@ 사고 발생. 파손된 열기구: %2$@대.")
add("event.rivalRedFined", "%1$@ flew on a red flag and got a %2$@ fine.", "%1$@ kırmızı bayrakta uçtu ve %2$@ ceza yedi.", "%1$@ flog bei roter Flagge und bekam %2$@ Strafe.", "%1$@ voló con bandera roja y recibió una multa de %2$@.", "%1$@が赤い旗の日に飛び、%2$@の罰金。", "%1$@ 측이 빨간 깃발에 비행했다가 벌금 %2$@ 처분을 받았습니다.")
add("event.rivalRedSneaked", "%@ secretly flew on a red flag.", "%@ kırmızı bayrakta gizlice uçtu.", "%@ ist heimlich bei roter Flagge geflogen.", "%@ voló a escondidas con bandera roja.", "%@がこっそり赤い旗の日に飛んだ。", "%@ 측이 빨간 깃발에 몰래 비행했습니다.")
add("event.poachAttempt", "%1$@ offered your pilot %2$@ a job!", "%1$@ senin pilotunu ayartmaya çalışıyor: %2$@ iş teklifi aldı!", "%1$@ hat deinem Piloten %2$@ einen Job angeboten!", "¡%1$@ ofreció trabajo a tu piloto %2$@!", "%1$@があなたのパイロット%2$@を引き抜こうとしている！", "%1$@ 측이 내 조종사 %2$@에게 일자리를 제안했습니다!")
add("event.rivalHotelDeal", "%1$@ signed with %2$@. The hotel won't work with anyone else for 12 days.", "%1$@, %2$@ ile anlaştı. Otel 12 gün boyunca başka şirketle çalışmayacak.", "%1$@ hat einen Vertrag mit %2$@ geschlossen. Das Hotel arbeitet 12 Tage lang mit niemand anderem zusammen.", "%1$@ firmó con %2$@. El hotel no trabajará con nadie más durante 12 días.", "%1$@が%2$@と契約。ホテルは12日間ほかの会社と組まない。", "%1$@ 측이 %2$@ 측과 제휴했습니다. 이 호텔은 12일간 다른 회사와 일하지 않습니다.")
add("event.rivalStoleHotel", "%2$@ took a better offer from %1$@ and ended its deal with you!", "%2$@, %1$@ şirketinden gelen daha iyi teklifi kabul edip seninle anlaşmasını bitirdi!", "%2$@ hat ein besseres Angebot von %1$@ angenommen und deinen Vertrag beendet!", "¡%2$@ aceptó una oferta mejor de %1$@ y terminó su acuerdo contigo!", "%2$@が%1$@のより良い条件を受け入れ、あなたとの契約を打ち切った！", "%2$@ 측이 %1$@의 더 좋은 제안을 받아들여 나와의 제휴를 끝냈습니다!")
add("event.rivalCampaign", "%@ launched an influencer campaign; their popularity went up.", "%@ influencer kampanyası başlattı, popülerliği arttı.", "%@ startete eine Influencer-Kampagne, ihre Beliebtheit stieg.", "%@ lanzó una campaña con influencers y su popularidad subió.", "%@がインフルエンサーキャンペーンを開始。人気が上昇。", "%@ 측이 인플루언서 캠페인을 벌여 인기가 올랐습니다.")
add("event.rivalPrice", "%1$@ changed its price: %2$@ → %3$@.", "%1$@ fiyatını değiştirdi: %2$@ → %3$@.", "%1$@ hat den Preis geändert: %2$@ → %3$@.", "%1$@ cambió su precio: %2$@ → %3$@.", "%1$@が価格を変更：%2$@ → %3$@。", "%1$@ 가격 변경: %2$@ → %3$@.")
add("event.rivalNewBalloon", "%@ added a new balloon to its fleet.", "%@ filosuna yeni bir balon ekledi.", "%@ hat einen neuen Ballon in die Flotte aufgenommen.", "%@ añadió un globo nuevo a su flota.", "%@が新しい気球を導入した。", "%@ 측이 기단에 새 열기구를 추가했습니다.")
add("event.rivalBankrupt", "%1$@ went bankrupt! Its fleet is for sale: %2$@ balloons for %3$@.", "%1$@ iflas etti! Filosu satışta: %2$@ balon, %3$@.", "%1$@ ist pleite! Die Flotte steht zum Verkauf: %2$@ Ballone für %3$@.", "¡%1$@ ha quebrado! Su flota está en venta: %2$@ globos por %3$@.", "%1$@が倒産！フリートが売りに出た：気球%2$@機で%3$@。", "%1$@ 파산! 기단 매각: 열기구 %2$@대, %3$@.")
add("event.rivalForSale", "%1$@ is struggling. You can make a takeover offer: %2$@.", "%1$@ zor durumda. Şirketi devralma teklifi yapabilirsin: %2$@.", "%1$@ steckt in Schwierigkeiten. Du kannst ein Übernahmeangebot machen: %2$@.", "%1$@ está en apuros. Puedes hacer una oferta de compra: %2$@.", "%1$@は苦境にある。買収を提案できる：%2$@。", "%1$@ 경영난. 인수 제안을 할 수 있습니다: %2$@.")
