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
