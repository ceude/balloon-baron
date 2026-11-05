"""Builds BalloonBaron/Localizable.xcstrings from these sources. Edit the .py files, then run: python3 tools/strings/build.py"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import s1_ui, s2_hez, s3_events, s4_reviews, s5_v2, s6_world, s7_home, s8_world, s9_fleet, s10_flight, s11_intro, s12_extra, s13_report, s14_town, s15_v85, s16_morning, s17_boss, s18_bazaar, s19_home, s20_office, s21_platform, s22_a11y, s23_v101, s24_lux, s25_town, s26_flight, s27_fleet, s28_v108, s29_v110, s30_bnames, s31_show, s32_coach, s33_store, s34_factory, s35_v115, s36_v116, s37_v117, s38_opening, s39_v121, s40_v122, s41_letter, s42_port, s43_bri, s44_code, s45_pilots, s46_sell, s47_newplayer, s48_contracts, s49_uifix, s50_decorstore, s51_charter, s52_hangar, s53_v131, s54_v132, s55_v133, s56_v134, s57_v136, s59_v137, s60_v140, s61_v141, s62_v141_cast, s63_v1412, s64_v1414
S = s1_ui.S
LANGS = ["en", "tr", "de", "es", "ja", "ko", "fr"]
bad = 0
# v142: French lives in its own tables, fr_*.py, each a dict FR = {key: text}, so the add() calls above stay as they are.
# Every key needs French, and every French key must exist. Write plain spaces before ; : ! ? » and after «: they become
# no-break spaces here (French typography), so a line never breaks between a word and its punctuation.
import glob, importlib
FR = {}
for f in sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "fr_*.py"))):
    for k, t in importlib.import_module(os.path.basename(f)[:-3]).FR.items():
        if k in FR:
            print("FR DUPLICATE", k); bad += 1
        FR[k] = t
def fr_typo(t):
    t = re.sub(r" ([;:!?»])", "\u00a0\\1", t)
    t = re.sub(r"« ", "«\u00a0", t)
    t = re.sub(r"([\d@]) %(?![\d@$])", "\\1\u00a0%", t)
    t = re.sub(r"(\d) (?=\d{3}\b)", "\\1\u00a0", t)  # 10 000: the thousands never part
    return t
for k in FR:
    if k not in S:
        print("FR UNKNOWN KEY", k); bad += 1
for k, v in S.items():
    if k not in FR:
        print("FR MISSING", k); bad += 1
        v["fr"] = v["en"]
        continue
    t = fr_typo(FR[k])
    # A high punctuation mark glued to the word before it, or a « » without its space, is a typo in French.
    if re.search(r"[^\s\u00a0!?.…%@\d\)\]][!?;»]|[A-Za-zÀ-ÿ][:](?=\s|$)|«(?!\u00a0)", t.replace("%%", "")):
        print("FR TYPOGRAPHY", k, repr(t)); bad += 1
    # In a string with placeholders a literal percent sign is %%, in one without it is a single %, as in the English.
    if ("%%" in v["en"]) != ("%%" in t) and "%" in t.replace("%@", "").replace("$@", ""):
        print("FR PERCENT", k, repr(t)); bad += 1
    v["fr"] = t
# A ".short" text is the start of its full text (the rest sits behind "More"): the French must keep that.
for k in S:
    if k.endswith(".short") and k[:-6] in S and k in FR and k[:-6] in FR and not S[k[:-6]]["fr"].startswith(S[k]["fr"]):
        print("FR SHORT NOT A PREFIX", k); bad += 1
def specs(t):
    t = t.replace("%%", "")
    pos = re.findall(r"%(\d)\$@", t)
    plain = len(re.findall(r"%@", t))
    braces = sorted(re.findall(r"\{[a-z]\}", t))
    return (sorted(set(pos)) if pos else plain, sorted(set(braces)))
for k, v in S.items():
    ref = specs(v["en"])
    for l in LANGS:
        if specs(v[l]) != ref:
            print("MISMATCH", k, l, specs(v[l]), ref); bad += 1
# v126.1: no emoji in the game. Colour emoji (U+1F000 and up), the symbols block U+2600–27BF (✈ ☀ ⚠ ☕ ✔ ✨ …) and the
# emoji variation selector are refused; the text glyphs the game uses (★ ☆ ✓ ✕ ✦) are allowed.
EMOJI = re.compile("[\U0001F000-\U0010FFFF\u2600-\u27BF\uFE0F]")
for k, v in S.items():
    for l in LANGS:
        for ch in EMOJI.findall(v[l]):
            if ch not in "★☆✓✕✦":
                print("EMOJI", k, l, repr(ch)); bad += 1
out = {"sourceLanguage": "en", "strings": {}, "version": "1.0"}
for k in sorted(S):
    out["strings"][k] = {"extractionState": "manual", "localizations": {
        l: {"stringUnit": {"state": "translated", "value": S[k][l]}} for l in LANGS}}
target = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '../../BalloonBaron/Localizable.xcstrings')
json.dump(out, open(target, "w", encoding="utf-8", newline="\n"), ensure_ascii=False, indent=2, sort_keys=True)
print(len(S), "keys,", bad, "problems")
