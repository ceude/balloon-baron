"""Writes <out>/tr2en.json: every Turkish string of the app's catalog (tools/strings) with its English, so the reel
captures can show the Turkish prototype in English. capture.js runs it: python3 tools/marketing/reels/tr2en.py <out>"""
import glob, importlib, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
SD = os.path.join(HERE, '../../strings')
sys.path.insert(0, SD)
sys.dont_write_bytecode = True
pairs = {}
for f in sorted(glob.glob(os.path.join(SD, 's*.py'))):
    importlib.import_module(os.path.basename(f)[:-3])
import s1_ui
for k, v in s1_ui.S.items():
    tr, en = v['tr'], v['en']
    if tr and en and tr != en: pairs.setdefault(tr, en)
json.dump(pairs, open(os.path.join(sys.argv[1] if len(sys.argv) > 1 else HERE, 'tr2en.json'), 'w'), ensure_ascii=False, indent=0)
print(len(pairs), 'pairs')
