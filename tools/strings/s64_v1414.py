from s1_ui import add

# v141.4 (TestFlight): a region whose baron title you haven't won yet keeps its autopilot profit in its own cash box;
# the daily send switch is locked until then.
add("holding.sendLocked", "Until you're baron here, the profit stays in the region.",
    "Baron olana kadar kâr bölgenin kasasında kalır.",
    "Bis du hier Baron bist, bleibt der Gewinn in der Region.",
    "Hasta que seas barón aquí, el beneficio se queda en la región.",
    "ここで男爵になるまで、利益は地域に残る。",
    "이곳의 남작이 되기 전까지 수익은 지역에 남아요.")
add("holding.sendLockedTag", "Locked", "Kilitli", "Gesperrt", "Bloqueado", "ロック中", "잠김")
add("map.keptSubBaron", "Your manager runs it: until you're baron here, the profit stays in its own cash box.",
    "Müdürün yönetiyor: baron olana kadar kâr bölgenin kasasında kalır.",
    "Dein Manager führt sie: Bis du hier Baron bist, bleibt der Gewinn in ihrer eigenen Kasse.",
    "La dirige tu gerente: hasta que seas barón aquí, el beneficio se queda en su propia caja.",
    "マネージャーが運営中：ここで男爵になるまで、利益は地域の金庫に残る。",
    "매니저가 운영 중: 이곳의 남작이 되기 전까지 수익은 지역 금고에 남아요.")

# The influencer review named Cappadocia's @gezginayse in every region: each region has its own (fictional) handle.
# Turkish avoids a suffix on the handle ("… hesabındaki videoyu").
INFLU = {
    "abq": "@mesa.maddie", "lux": "@layla.on.the.nile", "bri": "@harbourside.hattie", "mara": "@savanna.amani",
}
for r, h in INFLU.items():
    add(f"review.influencer.0.{r}",
        f"We came after seeing {h}'s video on Instagram. It really was as beautiful as she said!",
        f"Instagram'da {h} hesabındaki videoyu görüp geldik. Gerçekten anlattığı kadar güzeldi!",
        f"Wir kamen wegen des Instagram-Videos von {h}. Es war wirklich so schön, wie sie erzählt hat!",
        f"Vinimos tras ver el vídeo de {h} en Instagram. ¡Era tan bonito como contaba!",
        f"Instagramで{h}の動画を見て来た。本当に言っていた通り素晴らしかった！",
        f"인스타그램에서 {h} 영상을 보고 왔어요. 정말 말한 그대로 아름다웠어요!")

# Home: with nothing flying, the ticket card opens the flight plan; its action word says so.
add("home.planGo", "Plan ›", "Plan ›", "Plan ›", "Plan ›", "プラン ›", "계획 ›")
