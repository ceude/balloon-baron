"""v121: the Hasan story in the game, and the TestFlight fixes (pause in flight, wind tag, flight plan)."""
from s1_ui import add

# v121: the Hasan story. Hezarfen tells it after the first flight in Cappadocia.
add("hez.hasan",
 "I never told you your grandfather's story, my child. Hasan lifted one of Cappadocia's first balloons from this very field. His company grew, then one bad season it fell into debt. Kenan Arslan bought up the debts cheap and took the company from him. Hasan never flew again. I kept his basket. Today that basket flew again.",
 "Sana dedenin hikâyesini hiç anlatmadım evlat. Hasan, Kapadokya'nın ilk balonlarından birini tam bu tarladan kaldırdı. Şirketi büyüdü, sonra kötü bir sezonda borca girdi. Kenan Arslan borçlarını ucuza toplayıp şirketi elinden aldı. Hasan bir daha uçmadı. Sepetini ben sakladım. Bugün o sepet yeniden havalandı.",
 "Ich habe dir nie die Geschichte deines Großvaters erzählt, mein Kind. Hasan ließ einen der ersten Ballone Kappadokiens von genau diesem Feld aufsteigen. Seine Firma wuchs, dann geriet sie in einer schlechten Saison in Schulden. Kenan Arslan kaufte die Schulden billig auf und nahm ihm die Firma. Hasan flog nie wieder. Ich habe seinen Korb aufbewahrt. Heute ist dieser Korb wieder geflogen.",
 "Nunca te conté la historia de tu abuelo, hijo. Hasan elevó uno de los primeros globos de Capadocia desde este mismo campo. Su empresa creció y luego, en una mala temporada, se endeudó. Kenan Arslan compró sus deudas a bajo precio y le quitó la empresa. Hasan no volvió a volar. Yo guardé su cesta. Hoy esa cesta ha vuelto a volar.",
 "お前の祖父の話をまだしていなかったな。ハサンはまさにこの畑から、カッパドキア最初の気球の一つを揚げた。会社は大きくなったが、ある不作の季節に借金を抱えた。ケナン・アルスランがその借金を安く買い集め、会社を奪った。ハサンは二度と飛ばなかった。バスケットはわしが預かっておいた。今日、そのバスケットがまた空を飛んだのだ。",
 "할아버지 이야기를 한 번도 해 준 적이 없구나. 하산은 바로 이 밭에서 카파도키아 최초의 열기구 중 하나를 띄웠단다. 회사는 커졌지만 어느 나쁜 시즌에 빚을 졌지. 케난 아르슬란이 그 빚을 헐값에 사들여 회사를 빼앗았다. 하산은 다시는 날지 않았어. 바스켓은 내가 간직했지. 오늘 그 바스켓이 다시 하늘을 날았구나.")
# The paper the day you first pass Kenan, in Cappadocia
add("paper.passedBoss.sub.cap",
 "Years ago Göreme Sky took over Hasan Usta's company. Now the valley's busiest company belongs to his grandchild.",
 "Yıllar önce Hasan Usta'nın şirketini Göreme Sky almıştı. Şimdi vadinin en çok yolcu uçuran şirketi torununun.",
 "Vor Jahren übernahm Göreme Sky die Firma von Hasan Usta. Jetzt gehört die Firma mit den meisten Passagieren im Tal seinem Enkelkind.",
 "Hace años Göreme Sky se quedó con la empresa de Hasan Usta. Ahora la empresa con más pasajeros del valle es de su nieto.",
 "かつてギョレメ・スカイはハサン親方の会社を手に入れた。今、谷で最も多くの乗客を運ぶ会社は、その孫のものだ。",
 "몇 해 전 괴레메 스카이가 하산 우스타의 회사를 차지했다. 이제 계곡에서 승객을 가장 많이 태우는 회사는 그의 손주 것이다.")
# The baron ceremony in Cappadocia: Hasan's basket in a glass case, and Kenan's note
add("ceremony.basket",
 "Your grandfather's basket now stands behind glass at the holding's entrance.",
 "Dedenin sepeti artık holdingin girişinde, camın ardında.",
 "Der Korb deines Großvaters steht jetzt hinter Glas im Eingang der Holding.",
 "La cesta de tu abuelo está ahora tras un cristal en la entrada del holding.",
 "祖父のバスケットは今、ホールディングの入口でガラスケースに収まっている。",
 "할아버지의 바스켓은 이제 지주회사 입구의 유리 진열장 안에 있다.")
add("ceremony.basketPlate", "HASAN", "HASAN", "HASAN", "HASAN", "HASAN", "HASAN")
add("ceremony.bossNote", "%@ left a note", "Not bırakan: %@", "%@ hat eine Nachricht hinterlassen", "%@ dejó una nota", "%@からの置き手紙", "%@의 쪽지")

# v121.2 (TestFlight): pause in flight
add("flight.pause.a11y", "Pause the flight", "Uçuşu duraklat", "Flug pausieren", "Pausar el vuelo", "フライトを一時停止", "비행 일시정지")
add("flight.pause.title", "Paused", "Duraklatıldı", "Pausiert", "En pausa", "一時停止中", "일시정지됨")
add("flight.pause.lead", "Altitude: %1$@ · Fuel: %2$@. Your balloon waits in the air until you're back.", "İrtifa: %1$@ · Yakıt: %2$@. Balonun sen dönene kadar havada bekler.", "Höhe: %1$@ · Brennstoff: %2$@. Dein Ballon wartet in der Luft, bis du zurück bist.", "Altitud: %1$@ · Combustible: %2$@. Tu globo te espera en el aire hasta que vuelvas.", "高度：%1$@ · 燃料：%2$@。戻るまで気球は空で待っている。", "고도: %1$@ · 연료: %2$@. 돌아올 때까지 열기구는 하늘에서 기다립니다.")
add("flight.pause.resume", "Resume", "Devam et", "Weiter", "Continuar", "再開", "계속")

# v121.2 (TestFlight): the flight plan without the "who flies?" question; you pick your balloon in the list
add("fplan.selfTitle", "Today you fly %@ yourself.", "Bugün %@ balonunu sen uçuruyorsun.", "Heute fliegst du %@ selbst.", "Hoy pilotas tú %@.", "今日は%@を自分で飛ばす。", "오늘은 %@ 기구를 직접 조종합니다.")
add("fplan.pilotsTitle", "Today your pilots fly every balloon.", "Bugün bütün balonları pilotlar uçuruyor.", "Heute fliegen deine Piloten alle Ballone.", "Hoy tus pilotos vuelan todos los globos.", "今日はパイロットが全機を飛ばす。", "오늘은 조종사들이 모든 기구를 조종합니다.")
add("fplan.selfNote", "Your passengers pay %@ more and the missions are yours. To fly another balloon, tap \"I'll fly this one\" in the list.", "Yolcular %@ fazla öder ve görevleri sen alırsın. Başka bir balonu uçurmak için listede \"Bu balonu ben uçurayım\" düğmesine dokun.", "Deine Passagiere zahlen %@ mehr, und die Aufträge gehören dir. Um einen anderen Ballon zu fliegen, tippe in der Liste auf \"Den fliege ich selbst\".", "Tus pasajeros pagan un %@ más y las misiones son tuyas. Para pilotar otro globo, toca \"Este lo piloto yo\" en la lista.", "乗客は%@多く払い、依頼はあなたが受ける。別の気球を飛ばすには、リストで「この気球は自分で飛ばす」をタップ。", "승객이 %@ 더 내고 임무는 당신 몫입니다. 다른 기구를 조종하려면 목록에서 \"이 기구는 내가 몬다\"를 누르세요.")
add("fplan.pilotsNote", "If you fly, passengers pay %@ more and you can take missions. Tap \"I'll fly this one\" on a balloon in the list.", "Kendin uçarsan yolcular %@ fazla öder ve görevleri alabilirsin. Listede bir balonda \"Bu balonu ben uçurayım\" düğmesine dokun.", "Wenn du selbst fliegst, zahlen die Passagiere %@ mehr und du kannst Aufträge annehmen. Tippe in der Liste bei einem Ballon auf \"Den fliege ich selbst\".", "Si pilotas tú, los pasajeros pagan un %@ más y puedes aceptar misiones. Toca \"Este lo piloto yo\" en un globo de la lista.", "自分で飛ばせば乗客は%@多く払い、依頼も受けられる。リストの気球で「この気球は自分で飛ばす」をタップ。", "직접 조종하면 승객이 %@ 더 내고 임무도 받을 수 있습니다. 목록의 기구에서 \"이 기구는 내가 몬다\"를 누르세요.")
add("fplan.missionYours", "Today's mission is yours: %1$@ (+%2$@).", "Bugünkü görev senin: %1$@ (+%2$@).", "Der heutige Auftrag gehört dir: %1$@ (+%2$@).", "La misión de hoy es tuya: %1$@ (+%2$@).", "今日の依頼はあなたのもの：%1$@（+%2$@）。", "오늘의 임무는 당신 몫: %1$@ (+%2$@).")
add("fplan.toPilot", "Give to a pilot", "Pilota ver", "An einen Piloten", "Dárselo a un piloto", "パイロットに任せる", "조종사에게 맡기기")

# v121.6: the pilots-only button at the end of boarding, when no pilot is spare
add("collect.downCount", "Grounded: %@", "Yerde: %@", "Am Boden: %@", "En tierra: %@", "地上：%@", "지상: %@")

# TestFlight: with nothing able to fly, the main button opens the flight plan
add("home.openPlan", "Open the flight plan", "Uçuş planını aç", "Flugplan öffnen", "Abrir el plan de vuelo", "飛行計画を開く", "비행 계획 열기")
add("home.fleet.flagNoPilot", "Your flagship has no pilot: fly it yourself in the plan", "Amiral balonunun pilotu yok: Plan'dan kendin uçur", "Dein Flaggschiff hat keinen Piloten: flieg es im Plan selbst", "Tu globo insignia no tiene piloto: pilótalo tú en el plan", "旗艦にパイロットがいない：計画で自分で飛ばそう", "기함에 조종사가 없습니다: 계획에서 직접 조종하세요")

# v121.10: "Give to a pilot" with no pilot free
add("noPilot.title", "No pilot", "Pilotun yok", "Kein Pilot", "Sin piloto", "パイロットがいない", "조종사가 없습니다")
add("noPilot.body", "You have no free pilot for this balloon. Would you like to hire a new pilot on the Crew page?", "Bu balon için boşta pilotun yok. Ekip sayfasından yeni bir pilot işe almak ister misin?", "Für diesen Ballon ist kein Pilot frei. Möchtest du auf der Crew-Seite einen neuen Piloten einstellen?", "No tienes ningún piloto libre para este globo. ¿Quieres contratar uno nuevo en la página de Equipo?", "この気球に空いているパイロットがいない。チームのページで新しいパイロットを雇う？", "이 열기구를 맡을 조종사가 없습니다. 팀 페이지에서 새 조종사를 고용할까요?")
add("noPilot.locked", "You have no pilot for this balloon. The pilot office opens soon; until then, fly it yourself.", "Bu balon için pilotun yok. Pilot ofisi yakında açılacak; o zamana kadar balonunu sen uçur.", "Für diesen Ballon hast du keinen Piloten. Das Pilotenbüro öffnet bald; bis dahin fliegst du selbst.", "No tienes piloto para este globo. La oficina de pilotos abre pronto; hasta entonces, pilótalo tú.", "この気球のパイロットがいない。パイロット事務所はもうすぐ開く。それまでは自分で飛ばそう。", "이 열기구를 맡을 조종사가 없습니다. 조종사 사무실이 곧 열리니 그때까지는 직접 조종하세요.")
add("noPilot.goCrew", "Go to Crew", "Ekibe git", "Zur Crew", "Ir a Equipo", "チームへ", "팀으로 가기")
add("noPilot.ok", "OK", "Tamam", "OK", "Vale", "OK", "확인")

# TestFlight: why nothing flies today, on the ticket card
add("home.none.damagedOne", "Your balloon is in repair. Days left: %@", "Balonun onarımda, uçamaz. Kalan gün: %@", "Dein Ballon ist in Reparatur. Tage übrig: %@", "Tu globo está en reparación. Días restantes: %@", "気球は修理中。残り日数：%@", "열기구가 수리 중입니다. 남은 날: %@")
add("home.none.damaged", "All your balloons are in repair. Days left: %@", "Bütün balonların onarımda, uçamaz. Kalan gün: %@", "Alle deine Ballone sind in Reparatur. Tage übrig: %@", "Todos tus globos están en reparación. Días restantes: %@", "すべての気球が修理中。残り日数：%@", "모든 열기구가 수리 중입니다. 남은 날: %@")
add("home.none.wornOne", "Your balloon's envelope is worn out. Renew it in the Fleet.", "Balonunun zarfı yıprandı, uçamaz. Filo'dan yenile.", "Die Hülle deines Ballons ist verschlissen. Erneuere sie in der Flotte.", "La envoltura de tu globo está gastada. Renuévala en la Flota.", "気球の外皮がすり切れた。フリートで交換しよう。", "열기구 외피가 닳았습니다. 함대에서 교체하세요.")
add("home.none.worn", "Your balloons are in repair or worn out. Look in the Fleet.", "Balonların onarımda ya da yıpranmış, uçamaz. Filo'ya bak.", "Deine Ballone sind in Reparatur oder verschlissen. Sieh in der Flotte nach.", "Tus globos están en reparación o gastados. Mira la Flota.", "気球は修理中かすり切れている。フリートを確認しよう。", "열기구가 수리 중이거나 닳았습니다. 함대를 확인하세요.")
add("home.none.noPilot", "No pilot for your balloons. Fly one yourself or hire a pilot.", "Balonlarının pilotu yok. Birini kendin uçur ya da pilot al.", "Keine Piloten für deine Ballone. Flieg selbst oder stell einen Piloten ein.", "Tus globos no tienen piloto. Pilota uno tú o contrata a alguien.", "気球のパイロットがいない。自分で飛ばすか、パイロットを雇おう。", "열기구에 조종사가 없습니다. 직접 조종하거나 조종사를 고용하세요.")
add("home.none.banned", "Flights are banned today.", "Bugün uçuş yasak.", "Heute herrscht Flugverbot.", "Hoy los vuelos están prohibidos.", "今日は飛行禁止。", "오늘은 비행이 금지되었습니다.")
add("home.none.strike", "Your pilots are on strike. Fly the flagship yourself.", "Pilotların grevde. Amiral balonunu kendin uçur.", "Deine Piloten streiken. Flieg das Flaggschiff selbst.", "Tus pilotos están en huelga. Pilota tú el globo insignia.", "パイロットがストライキ中。旗艦は自分で飛ばそう。", "조종사들이 파업 중입니다. 기함은 직접 조종하세요.")
add("home.none.grounded", "All your balloons are set to stay on the ground. Open the plan.", "Bütün balonların yerde kalacak şekilde ayarlı. Planı aç.", "Alle deine Ballone bleiben laut Plan am Boden. Öffne den Plan.", "Todos tus globos están puestos en tierra. Abre el plan.", "すべての気球が地上待機の設定。計画を開こう。", "모든 열기구가 지상 대기로 설정되어 있습니다. 계획을 여세요.")

# v121.9: something opens every day; Hezarfen's word for the new ones
add("hez.guide", "The guides' office is open, kid. Fly the hotel and tour guides for free and they'll send you their guests: popularity, and extra tourists for a few days.", "Rehber ofisi açıldı evlat. Otel ve tur rehberlerini ücretsiz uçurursan seni müşterilerine önerirler: popülerlik ve birkaç gün boyunca fazladan turist.", "Das Büro der Reiseführer hat geöffnet, Lehrling. Nimm Hotel- und Tourguides kostenlos mit, dann schicken sie dir ihre Gäste: Beliebtheit und ein paar Tage lang mehr Touristen.", "La oficina de guías ha abierto, aprendiz. Vuela gratis con los guías de hoteles y tours y te mandarán a sus clientes: popularidad y más turistas durante unos días.", "ガイド事務所が開いた。ホテルやツアーのガイドを無料で乗せれば客を回してくれる。人気が上がり、数日は観光客も増える。", "가이드 사무소가 문을 열었다네. 호텔과 투어 가이드를 무료로 태워 주면 손님을 보내 주지. 인기가 오르고 며칠간 관광객도 늘어난다네.")
add("hez.agency", "The influencer agency is open. Travel influencers fly with you and post it; your popularity climbs fast. It's pricey, so do it when your till is comfortable.", "Influencer ajansı açıldı. Gezi influencerları seninle uçup paylaşır, popülerliğin hızla yükselir. Pahalıdır, kasan rahatken yap.", "Die Influencer-Agentur hat geöffnet. Reise-Influencer fliegen mit dir und posten es; deine Beliebtheit steigt schnell. Teuer, also mach es, wenn die Kasse stimmt.", "La agencia de influencers ha abierto. Los influencers de viajes vuelan contigo y lo publican; tu popularidad sube rápido. Es caro, hazlo cuando la caja vaya holgada.", "インフルエンサー事務所が開いた。旅行インフルエンサーが一緒に飛んで発信してくれ、人気が一気に上がる。高いので、金庫に余裕がある時にな。", "인플루언서 에이전시가 문을 열었다네. 여행 인플루언서가 함께 날고 소식을 올리면 인기가 빠르게 오르지. 비싸니 금고가 넉넉할 때 하게.")
add("hez.workshop", "The balloon workshop's plot is ready, kid. Build it and you design your own balloons, and later you make them too.", "Balon atölyesinin arsası hazır evlat. Kurarsan balonlarını kendin tasarlarsın, sonra da kendi balonlarını üretirsin.", "Das Grundstück für die Ballonwerkstatt ist bereit, Lehrling. Bau sie, dann entwirfst du deine Ballone selbst und baust sie später auch.", "El solar del taller de globos está listo, aprendiz. Constrúyelo y diseñarás tus propios globos, y más tarde también los fabricarás.", "気球工房の土地が整ったぞ。建てれば自分で気球をデザインでき、いずれは作ることもできる。", "열기구 공방 부지가 준비됐다네. 지으면 열기구를 직접 디자인하고, 나중엔 직접 만들 수도 있지.")
add("hez.school", "The pilot school's plot is ready too. With a school, every morning one of the applicants is a graduate: pilots who crash less.", "Pilot okulunun arsası da hazır. Okulun olursa her sabah başvuranlar arasında bir okul mezunu bulunur: daha az kaza yapan pilotlar.", "Auch das Grundstück für die Pilotenschule ist bereit. Mit einer Schule ist jeden Morgen ein Absolvent unter den Bewerbern: Piloten, die seltener verunglücken.", "El solar de la escuela de pilotos también está listo. Con una escuela, cada mañana uno de los aspirantes es titulado: pilotos que tienen menos accidentes.", "パイロット学校の土地も整った。学校があれば毎朝の応募者に卒業生が一人混じる。事故の少ないパイロットだ。", "조종사 학교 부지도 준비됐다네. 학교가 있으면 매일 아침 지원자 중 졸업생이 한 명 있지. 사고를 덜 내는 조종사들이라네.")
add("crew.schoolSoon", "The pilot school opens on day %@.", "Pilot okulu %@. günde açılır.", "Die Pilotenschule öffnet an Tag %@.", "La escuela de pilotos abre el día %@.", "パイロット学校は%@日目に開く。", "조종사 학교는 %@일차에 엽니다.")
add("factory.soon", "The balloon workshop opens on day %@.", "Balon atölyesi %@. günde açılır.", "Die Ballonwerkstatt öffnet an Tag %@.", "El taller de globos abre el día %@.", "気球工房は%@日目に開く。", "열기구 공방은 %@일차에 엽니다.")
