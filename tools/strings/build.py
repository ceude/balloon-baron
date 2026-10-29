"""Builds BalloonBaron/Localizable.xcstrings from these sources. Edit the .py files, then run: python3 tools/strings/build.py"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import s1_ui, s2_hez, s3_events, s4_reviews, s5_v2, s6_world, s7_home, s8_world, s9_fleet, s10_flight, s11_intro, s12_extra, s13_report, s14_town, s15_v85, s16_morning, s17_boss, s18_bazaar, s19_home, s20_office, s21_platform, s22_a11y, s23_v101, s24_lux, s25_town, s26_flight, s27_fleet, s28_v108, s29_v110, s30_bnames, s31_show, s32_coach, s33_store, s34_factory, s35_v115, s36_v116, s37_v117, s38_opening, s39_v121, s40_v122, s41_letter, s42_port
S = s1_ui.S
LANGS = ["en", "tr", "de", "es", "ja", "ko"]
def specs(t):
    t = t.replace("%%", "")
    pos = re.findall(r"%(\d)\$@", t)
    plain = len(re.findall(r"%@", t))
    braces = sorted(re.findall(r"\{[a-z]\}", t))
    return (sorted(set(pos)) if pos else plain, sorted(set(braces)))
bad = 0
for k, v in S.items():
    ref = specs(v["en"])
    for l in LANGS:
        if specs(v[l]) != ref:
            print("MISMATCH", k, l, specs(v[l]), ref); bad += 1
out = {"sourceLanguage": "en", "strings": {}, "version": "1.0"}
for k in sorted(S):
    out["strings"][k] = {"extractionState": "manual", "localizations": {
        l: {"stringUnit": {"state": "translated", "value": S[k][l]}} for l in LANGS}}
target = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '../../BalloonBaron/Localizable.xcstrings')
json.dump(out, open(target, "w", encoding="utf-8", newline="\n"), ensure_ascii=False, indent=2, sort_keys=True)
print(len(S), "keys,", bad, "problems")
