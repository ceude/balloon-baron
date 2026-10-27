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
