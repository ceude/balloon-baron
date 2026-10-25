# Localization review (October 2026)

Every string in all six languages was read against the English by a native-level editor per language (the English itself too). The fixes were applied to `tools/strings/*.py` by key, with placeholders and the Turkish suffix rule checked by script. Not applied: Korean Hangul spellings of the Albuquerque/Luxor hotel and sponsor names (the names are shared by all languages), the longer strike placards (tr/de/es; the sign is small), and in Turkish AMBAR→DEPO, AJANS→AJANSLAR (zone words written in the sand) and €1 milyon→1 milyon €.

## en

## English review notes

55 changes, all meaning-preserving; placeholders checked by script (same set in every changed string).

Main problem types:
- Mixed British/US spelling. Standardised on US English, which most strings already used (license, colors): colour→color, centre→center, neighbouring→neighboring, metres→meters, pressurised→pressurized, Non-stop→Nonstop, any more→anymore.
- Inconsistent terms: Hezarfen says "kid" everywhere except the praise lines, which said "my child" (now "kid"); "competition authority" is now always capitalized "Competition Authority"; "Landing zone" is now "Landing field"; "Guides' flight" is now "Promo flight for guides"; goal.stars is now "Popularity: %@" to match the other "Label: N" goals.
- A real error: building.office.2 "Rest room" means a toilet in US English → "Pilots' lounge".
- Clumsy or unclear wording, comma splices, missing commas.

Examples:
- hez.accident: "Be patient until the balloon is out of repair" → "Be patient while the balloon is repaired, and work on winning back your popularity."
- event.hotelLeft: "fell too far below its level." → "fell too far below its standards."
- home.alert.absent.soon: "Past day %@, passengers start asking…" → "After %@ days away, passengers start asking…"
- event.fuel.no: "Pay the rise (5 days fuel ×1.5)" → "Pay more (fuel ×1.5 for 5 days)"
- trait.storyteller.d: "reviews glow, popularity on every flight" → "glowing reviews and a popularity boost on every flight"

Not changed, flagged: hgoal.million ("€1 million") and map.openSub.lux ("You start with €5,000") put euro amounts in the strings, against the brief's rule that money comes from code. Fixing them needs a code change.

## tr

## Turkish (tr) review notes

- Changes: 110 of 1615 strings. The base was already good, natural Turkish; most fixes are polish, not rewrites. Placeholders were checked by script (same set as before) and no suffix follows a placeholder.
- Main problem types: a few real meaning errors; grammar slips (subject/verb agreement, word order such as "bir küçük balon"); stiff or literal phrasing; inconsistent terms between screens; some Turkish spelling and typography (kâğıt, influencer'ları, “…” quotes).
- Examples (before → after):
  - report.adTitle: "Puanını aldığın reklamlar da etkiliyor" → "Parasını aldığın reklamların da bir bedeli var." (mistranslation)
  - marketPage.style.mid: "Orta yolcu." → "Ortayolcu." (written as two words it means "middle passenger")
  - event.poachAttempt: "%1$@, pilotun %2$@ için iş teklifi yaptı!" → "%1$@ pilotunu ayartmaya çalışıyor: %2$@ iş teklifi aldı!"
  - goals.baronHint: "…sağlarsan %@ baronu olur, dünyaya açılırsın" → "…tamamlarsan %@ baronu olursun ve dünyaya açılırsın" (agreement)
  - review.perfect.1 (+ .abq/.lux, proposal.0): "Hayatımın sabahıydı" → "Hayatımın en güzel sabahıydı"
- Standardised terms:
  - flagship: always "amiral balonu", never just "amiral" in sentences (the short "Amiral" tag stays);
  - holding money goes back to "bölgeler" (regions), not "ülkeler";
  - billboards: "reklam panosu";
  - cheap rivals: "agresif, ucuz bir firma" (replaces "ucuzcu");
  - "konu kapanır" (replaces the literal "hikâye kapanır");
  - "Rekor denemeleri", "Molasız dünya turu", "Sabah hatırlatması", "yer rüzgârı";
  - halved income: "yarıya düştü".
- Voice: Franklin and Imhotep now say "genç dostum"/"dostum", as in the English, so "evlat" stays Hezarfen's word. Dale's English lines ("Well, look what…", "No hard feelings") are left in English on purpose, the same as in the other languages.
- Other fixes: "römork" (balloon trailer) instead of "karavan", "Altın kuşak" for prime time, "Altın varak", "+%15" on the strike sign, "1 milyon €".

## de

## German review notes

- 150 strings changed (about 70 by hand, the rest from terminology and typography passes). The base translation was solid, du-form throughout.
- Main problems: mixed terminology (Fahrgäste/Passagiere, Ballons/Ballone, Rivale/Konkurrent, Kartellamt/Kartellbehörde/Wettbewerbsbehörde, Holdingkasse/Holding-Kasse); "guides" rendered as "Reiseführer"/"Führer" (reads as guidebook, and "Führer" is loaded); leftover English in Dale's lines; one typo ("Kredi aufnehmen") and one grammar slip ("haben wir umentschieden"); "aus dem %1$@" before hotel names whose gender doesn't fit; English straight quotes and "..." / "Wort…" instead of German „…“ and " …".
- Examples:
  - bank.take: Kredi aufnehmen → Kredit aufnehmen
  - town.sub.guides: Führer empfehlen dich → Guides empfehlen dich
  - event.vip.lead: Ein Geschäftsmann aus dem %1$@ … → Ein Geschäftsmann, der im Hotel %1$@ wohnt, …
  - boss.abq.hello: Well, look what the wind blew in. → Na sieh mal einer an, was der Wind da hergeweht hat.
  - event.pilotPromoted: %1$@ ist jetzt Pilot der Stufe %2$@! → Neue Stufe für %1$@: %2$@! (pairs with level.3 Erfahrener Kapitän → Routinier)
  - hez.licenseHold: Du weißt, was ich wählen würde. → Ich weiß, was ich wählen würde. (meaning had flipped)
- Standardised terms: Passagiere (not Fahrgäste), Ballone (plural; genitive "des Ballons" kept), Konkurrent/Konkurrenz (not Rivale), Wettbewerbsbehörde, Guides, Holding-Kasse / Holding-Ausgaben / Holding-Geld, Marktseite, Einstiegsgebühr, "Resttage: N" for compact countdown chips, Absolvent (pilot school), Routinier (senior pilot level). Hezarfen's "kid" is always "Lehrling" (two strings had "Kind"). His "my child" lines stay "mein Kind". Kenan's condescending "young one" is now the gender-neutral "Grünschnabel" instead of "Junge".
- Left as they were: Gas for in-flight fuel (HUD) next to Treibstoff in the ledger, "Kleiner" for Dale, proper names.

## es

## Spanish (es) review notes

107 strings changed out of ~1,600. Overall the translation was good. Most fixes deal with consistency and with making the Spanish neutral.

Main problem types:
- **Spain-only forms in a neutral (tú) localisation:** vosotros forms (No os lo perdáis, Manteneos lejos, Saludasteis, Volaréis), and the colloquialisms pillar, chaval, Vale, bombonas.
- **Terminology drift:** Crew was called both "Equipo" and "Tripulación". The equipment screen was also titled "Equipo", which clashed with Crew. Goals appeared as "Metas" and "Objetivos". Compensation appeared as "compensación" and "indemnización". Seats appeared as "asientos" and "plazas". The flagship was sometimes called "buque insignia". Patterns were often called "diseños". Hard landings appeared as "duro" and "brusco".
- **Real mistranslations:** "pilotos sin balón" (idle pilots), "Somos amigos del director" (it should say the manager and I are friends), "a mejor precio" (the English means a higher price), "Empieza el %@" (wrong article before feminine festival names), "Solo trabaja con cestas…".
- **Typography:** Straight "quotes" are now «…», including in reviews and in Hezarfen's lines. Leftover English: "low cost", "Showman".
- **Stiff or awkward wording:** for example "Con acuerdo con %1$@", "Sin arrepentimientos", "Ni un arrepentimiento", "haz lo que sea que hagas", and button labels that were imperatives instead of infinitives.

Examples (before → after):
- rescue.fire: "Despedir a los pilotos sin balón: %@" → "Despedir a los pilotos sin trabajo: %@"
- review.cheap.0: "¡No os lo perdáis!" → "¡No te lo pierdas!"
- boss.cap.hotel: "Somos amigos del director desde hace veinte años." → "El director y yo somos amigos desde hace veinte años."
- paper.festival: "Empieza el %@" → "Comienza %@"
- equip.title: "Equipo" → "Equipamiento" (it no longer clashes with Crew)

Standardised terms: Crew = Equipo, Goals = Objetivos, compensation = indemnización, seats = plazas, flagship = globo insignia, pattern = estampado (design = diseño), envelope = envoltura (worn = gastada), hard landing = aterrizaje brusco, budget rival = empresa de precios bajos, deep pockets = bolsillos llenos, advertising face = imagen de marca, kid = aprendiz (Dale says "chico"). I kept Dale's English phrases ("Well, look what the wind blew in", "No hard feelings") on purpose, because the German file does the same. I also kept "billete" as the word for ticket.

## ja

## ja review notes

153 strings changed (placeholders checked by script against the English and the old Japanese).

Main problem types:
- How the player is addressed was mixed: Hezarfen switched between お前 and 君, and narration/UI used 君, あなた or nothing. Now Hezarfen always uses わし/お前/弟子よ with old-master endings (～おる, ～せよ, ～のだ; dropped the off-voice ～なさい). UI and narration use あなた or no pronoun. Bosses and guides keep their own voices (Kenan お前, Nabil and Franklin 君).
- Terms were inconsistent: 艦隊/機材/船団/保有気球 vs フリート, エンベロープ vs 球皮, 公正取引委員会 vs 競争当局, 特別リクエスト vs 特別な依頼, ゲレメ vs ギョレメ, ウスキュダル vs ユスキュダル, 風向きマスト vs 風向塔, インフルエンサー施策/企画 vs キャンペーン, ホールディング vs ホールディングス.
- Mistranslations: "hard landing" as 強行着陸 (that means forced landing); "half empty" as 半分空で (reads as "half sky"); "their agents" as マネージャー; "Cancellation refunds" as キャンセル補償.
- Leftover English in Dale Whitaker's lines; half-width colons and です/ます in bank and deal texts while the rest of the game uses plain style.

Examples (before → after):
- paper.accident: %@の気球が強行着陸 → %@の気球がハードランディング
- hez.rivals: ライバルの気球は空で飛ぶ → ライバルの気球は空席だらけで飛ぶ
- hez.praise.pilot: 向こうも君を信じる → 正しい判断だ、弟子よ。…向こうもお前を信じる
- boss.abq.hello: Well, look what the wind blew in. → おやおや、風が妙なものを運んできたな。
- chapter.founding.award: カッパドキア観光協会が君を年間最優秀若手起業家に選んだ → カッパドキア観光協会の年間最優秀若手起業家に選ばれた

Standardised terms: フリート (fleet; screens are フリート画面/クルー画面/市場画面), 球皮 (envelope), 競争当局, 特別依頼, ホールディングス, 風向塔, インフルエンサーキャンペーン, ギョレメ・スカイ, ユスキュダル, 黄色の旗/赤い旗 in UI (赤旗 kept in headlines and Hezarfen's speech), 養成校出身 (school graduate).

## ko

## Korean (ko) review notes

- 222 strings changed (fix-ko.json). The placeholder set of every fix matches the English source (checked by script). No line breaks were changed.
- **Hezarfen's voice:** the old master's warm 하게체 ("자네", "~하게", "~일세", "제자여" for "kid") is kept and now used everywhere. Plain banmal (~야/~어) and 해라체 had slipped into about 40 lines, e.g. hez.delegate and hez.noRivals were entirely in 해라체. Rival bosses keep their own registers: Kenan uses 하오체, Dale uses banmal, Nabil uses 하게체.
- **Terminology standardised:** fleet = 기단 (was 기단/기구단/함대/열기구 함대); crew tab = 크루 (was 승무원/팀); basket = 바스켓 (was also 바구니); envelope = 외피 (was also 기낭); hotel deal = 제휴 (was also 계약); upkeep = 유지비 (was also 정비비); wind mast = 풍향탑; competition authority = 경쟁 당국 (was also 공정위/공정거래위원회); red flag = 빨간 깃발 (was 적색 깃발 in headlines); bazaar = 바자르, so it no longer clashes with Market = 시장; holding costs = 지주회사 비용; Master = 헤자르펜 장인 (was also 스승).
- **Particles after placeholders:** forms like "%@ 빨간 깃발에…", "%@이(가)" and "{c}가/{r}로" had a missing subject particle or a wrong 이/가 choice. They now use "%@ 측이", "%@ 열기구", a "Label: %@" form, or a rephrased sentence.
- **Meaning fixes:** report.holdBody showed the amount as a region name. event.moment.greet had the passengers waving instead of loving it. mission.desc.proposal lost "without a break". review.ad.2 said the ride "ended" under a billboard.
- **Leftover English** in boss.abq.hello and boss.abq.hotel is translated. The Albuquerque and Luxor hotel and sponsor names are now in Hangul, like the Cappadocia ones. Drop those 16 keys if Latin script is preferred.
- Newspaper sub-lines now use 한다체 consistently, as headlines do. Units are spaced consistently ("150 m").

Examples (before → after):
1. hez.yellow: 노란 깃발이야! … → 노란 깃발이네! …
2. event.rivalRedSneaked: %@ 빨간 깃발에 몰래 비행했습니다. → %@ 측이 빨간 깃발에 몰래 비행했습니다.
3. report.holdBody: %1$@ 지역이 자동 운영으로 벌었습니다. … → 자동 운영 수입 %1$@에서 지주회사 비용(%2$@)을 뺐습니다. …
4. boss.abq.hello: Well, look what the wind blew in. 샌디아 … → 이런, 바람에 누가 날려 왔나 보군. 샌디아 …
5. hez.delegate: 기단이 커졌구나. … 경영에 집중해라. → 기단이 커졌군, 제자여. … 경영에 집중하게.
