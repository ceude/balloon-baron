"""Frames raw 1290x2796 game screens for the App Store: caption on top, the screen in a phone frame below.
Usage: python3 compose.py <raw dir> <out dir> <lang>"""
import sys, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONTS = '/home/user/balloon-baron/BalloonBaron/Fonts/'
W, H = 1290, 2796
CAPTIONS = {
    'tr': [
        ('home', 'SICAK HAVA BALONU İMPARATORLUĞU', "KAPADOKYA'DA BALON\nŞİRKETİNİ KUR", 'Kasabanı büyüt, gökyüzünü balonlarınla doldur'),
        ('flight', 'GERÇEK UÇUŞ', 'BRÜLÖRÜ YAK,\nRÜZGÂRI OKU', 'Doğru rüzgâr katmanını bul, kusursuz in'),
        ('night', 'GECE OLUNCA', 'KASABAN\nIŞIL IŞIL', 'Havai fişekler, fener alayı, ateş böcekleri'),
        ('collect', 'SABAH TELAŞI', 'YOLCULARINI\nTOPLA', 'Ofisinin önünde sıra, safari cipleri yolda'),
        ('design', 'TASARIM STÜDYOSU', 'BALONUNU\nTASARLA', 'Desenler, renkler, kalp ve yıldız balonlar'),
        ('crew', 'EKİBİNİ KUR', 'HER PİLOTUN BİR\nKARAKTERİ VAR', 'Temkinli mi, gözü kara mı? Seçim senin'),
        ('album', 'BAŞARIMLAR', '22 KARTPOSTAL\nTOPLA', "Her başarı Kapadokya'dan bir anı"),
        ('holding', 'HOLDİNG PATRONU', 'BİR SEPETTEN\nHOLDİNGE', "Kapadokya'dan Albuquerque'ye, dünyaya açıl"),
    ]
}

def font(name, size): return ImageFont.truetype(FONTS + name, size)

def background():
    stops = [(0, (27, 24, 64)), (0.38, (74, 45, 99)), (0.72, (200, 96, 122)), (1, (240, 160, 112))]
    img = Image.new('RGB', (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        for i in range(len(stops) - 1):
            if stops[i][0] <= t <= stops[i + 1][0]:
                a, b = stops[i], stops[i + 1]; k = (t - a[0]) / (b[0] - a[0]); break
        c = tuple(round(a[1][j] + (b[1][j] - a[1][j]) * k) for j in range(3))
        for x in range(W): px[x, y] = c
    # a soft sunrise glow behind the phone
    glow = Image.new('L', (W, H), 0); d = ImageDraw.Draw(glow)
    d.ellipse((W / 2 - 900, H - 1500, W / 2 + 900, H + 300), fill=120)
    glow = glow.filter(ImageFilter.GaussianBlur(220))
    img = Image.composite(Image.new('RGB', (W, H), (255, 214, 160)), img, glow)
    # a few distant balloons in the sky behind the caption
    d = ImageDraw.Draw(img, 'RGBA')
    for (x, y, r, col) in [(1060, 690, 18, (20, 163, 154)),
                           (230, 760, 16, (155, 123, 224)), (980, 120, 20, (255, 111, 168)), (310, 110, 14, (90, 169, 230))]:
        d.ellipse((x - r, y - r * 1.15, x + r, y + r * 1.0), fill=col + (110,))
        d.polygon([(x - r * .55, y + r * .8), (x + r * .55, y + r * .8), (x + r * .2, y + r * 1.3), (x - r * .2, y + r * 1.3)], fill=col + (110,))
        d.rectangle((x - r * .2, y + r * 1.4, x + r * .2, y + r * 1.65), fill=(60, 36, 24, 110))
    return img

def centered(d, y, text, f, fill, spacing=0):
    if spacing:
        widths = [d.textlength(ch, font=f) for ch in text]
        total = sum(widths) + spacing * (len(text) - 1)
        x = (W - total) / 2
        for ch, w in zip(text, widths):
            d.text((x, y), ch, font=f, fill=fill); x += w + spacing
    else:
        d.text(((W - d.textlength(text, font=f)) / 2, y), text, font=f, fill=fill)

def compose(raw, kicker, head, sub):
    img = background()
    d = ImageDraw.Draw(img)
    centered(d, 128, kicker, font('BarlowCondensed-Bold.ttf', 42), (255, 194, 61), spacing=6)
    fh = font('BarlowCondensed-ExtraBold.ttf', 132)
    y = 190
    for line in head.split('\n'):
        centered(d, y, line, fh, (255, 255, 255)); y += 136
    centered(d, y + 22, sub, font('Barlow-SemiBold.ttf', 46), (255, 236, 214))
    # the phone
    s = 0.74
    sw, sh = round(1290 * s), round(2796 * s)
    x0, y0 = (W - sw) // 2, H - sh - 78
    screen = Image.open(raw).convert('RGB').resize((sw, sh), Image.LANCZOS)
    bez, rad = 20, 118
    shadow = Image.new('L', (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((x0 - bez, y0 - bez + 30, x0 + sw + bez, y0 + sh + bez + 30), rad + bez, fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    img = Image.composite(Image.new('RGB', (W, H), (20, 12, 40)), img, shadow)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((x0 - bez, y0 - bez, x0 + sw + bez, y0 + sh + bez), rad + bez, fill=(16, 13, 34))
    d.rounded_rectangle((x0 - bez + 3, y0 - bez + 3, x0 + sw + bez - 3, y0 + sh + bez - 3), rad + bez - 3, outline=(70, 62, 110), width=3)
    mask = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), rad, fill=255)
    img.paste(screen, (x0, y0), mask)
    return img

if __name__ == '__main__':
    raw_dir, out_dir, lang = sys.argv[1], sys.argv[2], sys.argv[3]
    import os; os.makedirs(out_dir, exist_ok=True)
    for i, (name, kicker, head, sub) in enumerate(CAPTIONS[lang], 1):
        compose(f'{raw_dir}/raw-{name}.png', kicker, head, sub).save(f'{out_dir}/{i:02d}.jpg', quality=93)
        print('saved', i, name)
