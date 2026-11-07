"""App Preview v3: turns the app's recorded clips (store-shots.yml with video=true/only: <lang>/<device>/video/<scene>.mov
on the store-raw branch) into 30 fps JPEG frames for preview.html, at 1.5x the preview's width so the zooms stay sharp.
Clips recorded slowed down (-demoSlow in store-shots.txt) are sped up again here.
Usage: python3 prep.py <store-raw checkout> <clips dir> [lang …]"""
import os, subprocess, sys
src, dst = sys.argv[1], sys.argv[2]
langs = sys.argv[3:] or ['en', 'tr']
SLOW = {'show': 0.08, 'night': 0.15, 'travel': 0.2}  # -demoSlow of the scene
WIDTH = {'iphone': 1329, 'ipad': 1800}
for lang in langs:
    for dev in ('iphone', 'ipad'):
        vd = os.path.join(src, lang, dev, 'video')
        if not os.path.isdir(vd): continue
        for f in sorted(os.listdir(vd)):
            if not f.endswith('.mov'): continue
            scene = f[:-4]; out = os.path.join(dst, lang, dev, scene); os.makedirs(out, exist_ok=True)
            for old in os.listdir(out): os.remove(os.path.join(out, old))
            k = SLOW.get(scene, 1)
            vf = (f'setpts={k}*PTS,' if k != 1 else '') + f'fps=30,scale={WIDTH[dev]}:-2:flags=lanczos'
            subprocess.run(['ffmpeg', '-v', 'error', '-i', os.path.join(vd, f), '-vf', vf, '-q:v', '3', '-start_number', '0', os.path.join(out, '%04d.jpg')], check=True)
            print(lang, dev, scene, len(os.listdir(out)), 'frames')
