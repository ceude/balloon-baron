# French for s42_port.py. "Guide" is the same word for women and men, so every region's guides share one title per slot.
FR = {
"hez.price3": "La foule d’hier est repartie, mon enfant ; aujourd’hui, la vallée a ses touristes habituels. Fixe ton prix chaque matin selon les touristes du jour : garde le prix élevé d’hier et tes places resteront vides, baisse-le pour rien et tu laisseras de l’argent sur la table. Tu fixes le prix dans la case Billet, en bas.",
"tip.price3.short": "La foule d’hier est repartie, mon enfant : ajuste de nouveau ton prix aux touristes du jour.",
"hgoal.worldGames": "Spectacle des Jeux mondiaux",
"holding.wg.lockBri": "Une fois baron de Bristol",
}
GUIDES = {"abq": ("Emily", "Carlos", "Dakota"), "lux": ("Nour", "Karim", "Yasmin"),
          "bri": ("Olivia", "Harry", "Imogen"), "mara": ("Naserian", "Kaleku", "Sopiato")}
TITLES = {"ayse": "Guide d’hôtel", "mehmet": "Guide touristique", "selin": "Guide senior"}
for region, names in GUIDES.items():
    for gid, name in zip(["ayse", "mehmet", "selin"], names):
        FR[f"guidePick.{region}.{gid}"] = name
        FR[f"guidePick.{region}.{gid}.title"] = TITLES[gid]
