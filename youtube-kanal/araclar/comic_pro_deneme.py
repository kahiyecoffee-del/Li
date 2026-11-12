import math, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops
S = 3; W, H = 1080, 1080
INK = (14, 10, 16)

def cr(pts, n=14, closed=True):
    """Catmull-Rom ile yumuşak eğri."""
    P = pts + pts[:3] if closed else [pts[0]] + pts + [pts[-1]]
    out = []
    rng = len(pts) if closed else len(pts) - 1
    for i in range(rng):
        p0, p1, p2, p3 = P[i], P[i + 1], P[i + 2], P[i + 3]
        for k in range(n):
            t = k / n; t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2 + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in range(2)))
    if not closed: out.append(pts[-1])
    return out

def sc(pts): return [(x * S, y * S) for x, y in pts]

class C:
    def __init__(s, bg):
        s.im = Image.new("RGB", (W * S, H * S), bg); s.d = ImageDraw.Draw(s.im)
    def shape(s, pts, fill, ink=6, smooth=True):
        q = sc(cr(pts) if smooth else pts)
        s.d.polygon(q, fill=fill)
        if ink: s.d.line(q + [q[0]], fill=INK, width=int(ink * S), joint="curve")
        return q
    def clip_shape(s, base_pts, shade_pts, fill, smooth=True):
        """shade_pts'i base_pts içine kırp (cel gölge)."""
        m1 = Image.new("L", s.im.size, 0); ImageDraw.Draw(m1).polygon(sc(cr(base_pts)), fill=255)
        m2 = Image.new("L", s.im.size, 0); ImageDraw.Draw(m2).polygon(sc(cr(shade_pts) if smooth else shade_pts), fill=255)
        m = ImageChops.multiply(m1, m2)
        s.im.paste(Image.new("RGB", s.im.size, fill), (0, 0), m)
    def stroke(s, pts, w, col=INK, smooth=True, taper=True):
        q = sc(cr(pts, closed=False) if smooth else pts)
        n = len(q)
        for i in range(n - 1):
            u = i / max(1, n - 2)
            ww = w * (math.sin(math.pi * u) * 0.75 + 0.25) if taper else w
            s.d.line([q[i], q[i + 1]], fill=col, width=max(1, int(ww * S)))
    def dots(s, box, col, step=10, r=2.4, mask_pts=None):
        x0, y0, x1, y1 = box
        lay = Image.new("L", s.im.size, 0); ld = ImageDraw.Draw(lay)
        for y in range(y0, y1, step):
            for x in range(x0 + (step // 2 if (y // step) % 2 else 0), x1, step):
                ld.ellipse([(x - r) * S, (y - r) * S, (x + r) * S, (y + r) * S], fill=255)
        if mask_pts:
            m = Image.new("L", s.im.size, 0); ImageDraw.Draw(m).polygon(sc(cr(mask_pts)), fill=255); lay = ImageChops.multiply(lay, m)
        s.im.paste(Image.new("RGB", s.im.size, col), (0, 0), lay)
    def out(s): return s.im.resize((W, H), Image.LANCZOS)

c = C((150, 30, 25))
# --- arka plan: radyal hız çizgileri + tram
cx, cy = 760, 380
for k in range(140):
    a = k * 2 * math.pi / 140 + random.random() * 0.02
    r0 = 260 + random.random() * 80
    c.d.line([((cx + math.cos(a) * r0) * S, (cy + math.sin(a) * r0) * S), ((cx + math.cos(a) * 1600) * S, (cy + math.sin(a) * 1600) * S)],
             fill=(110, 18, 18) if k % 2 else (180, 45, 30), width=int((3 + (k % 3) * 2) * S))
c.dots((0, 0, W, H), (90, 10, 12), step=12, r=2.2)
# --- omuzlar / yelek
SKIN, SKIN_M, SKIN_D = (180, 120, 88), (138, 84, 60), (70, 38, 30)
vest = [(80, 1080), (120, 900), (240, 820), (400, 790), (560, 800), (720, 860), (820, 960), (860, 1080)]
c.shape(vest, (38, 48, 60), smooth=True)
c.clip_shape(vest, [(80, 1080), (120, 900), (240, 820), (400, 790), (380, 1080)], (22, 28, 36))
c.stroke([(400, 800), (430, 1080)], 5)
for y in (900, 960, 1020): c.stroke([(560, y), (700, y + 15)], 4, (230, 170, 40), smooth=False, taper=False)  # reflektör şerit
# --- boyun
neck = [(380, 820), (395, 690), (520, 690), (545, 820), (470, 850)]
c.shape(neck, SKIN)
c.clip_shape(neck, [(380, 820), (395, 690), (470, 700), (455, 850)], SKIN_D)
# --- kafa (3/4)
head = [(330, 470), (345, 360), (420, 300), (520, 295), (600, 340), (630, 430), (628, 520), (610, 600), (570, 680), (510, 735), (450, 745), (395, 715), (355, 640), (335, 560)]
c.shape(head, SKIN, ink=7)
# orta ton ve ağır gölge (ışık sağdan)
c.clip_shape(head, [(320, 300), (470, 300), (465, 420), (485, 520), (470, 620), (500, 760), (300, 760)], SKIN_M)
c.clip_shape(head, [(320, 300), (420, 300), (405, 420), (430, 520), (415, 610), (450, 760), (300, 760)], SKIN_D)
# kulak
ear = [(345, 500), (318, 480), (312, 540), (330, 585), (352, 575)]
c.shape(ear, SKIN_D, ink=5)
# kaş + göz (kısık, yorgun)
c.stroke([(470, 470), (520, 455), (580, 462), (610, 475)], 13)
c.stroke([(380, 480), (420, 470), (450, 478)], 10)
eye = [(500, 500), (540, 490), (585, 497), (575, 512), (530, 515)]
c.shape(eye, (240, 232, 220), ink=4)
c.d.ellipse([548 * S, 494 * S, 566 * S, 512 * S], fill=(60, 40, 30)); c.d.ellipse([552 * S, 498 * S, 562 * S, 508 * S], fill=INK)
c.stroke([(498, 498), (540, 486), (590, 494)], 6)  # üst kapak
c.stroke([(510, 528), (550, 532), (580, 524)], 3, (90, 50, 40))  # göz altı torbası
c.stroke([(400, 505), (440, 500)], 5)  # gölgedeki göz
# burun
c.stroke([(560, 520), (575, 590), (598, 615), (575, 630), (545, 622)], 6)
c.clip_shape(head, [(545, 590), (575, 590), (600, 615), (575, 632), (545, 625)], SKIN_D)
# ağız + çene çizgisi
c.stroke([(495, 680), (540, 675), (585, 668)], 7)
c.stroke([(520, 700), (560, 698)], 3, (90, 50, 40))
# yanak çizgileri (yaş)
c.stroke([(590, 600), (600, 650), (590, 690)], 3, (100, 60, 45))
# sakal tramı
c.dots((420, 620, 640, 760), (55, 35, 28), step=8, r=1.8, mask_pts=[(430, 640), (520, 630), (625, 600), (615, 690), (560, 735), (470, 745), (430, 700)])
# yara izi
c.stroke([(600, 420), (612, 470), (618, 520)], 5, (150, 50, 45))
# kenar ışığı (sıcak)
c.stroke([(605, 345), (632, 430), (630, 520), (612, 600), (572, 682)], 7, (255, 205, 130), taper=True)
# --- kask
helm = [(310, 455), (325, 360), (380, 270), (470, 225), (570, 230), (650, 290), (680, 380), (675, 440)]
c.shape(helm, (232, 172, 40), ink=8)
c.clip_shape(helm, [(300, 470), (325, 360), (380, 270), (450, 230), (470, 300), (450, 470)], (165, 110, 20))
c.stroke([(560, 250), (620, 290), (650, 360)], 9, (255, 235, 160))  # parlama
c.stroke([(470, 228), (480, 445)], 5)  # kask sırtı
brim = [(290, 455), (690, 432), (700, 470), (300, 495)]
c.shape(brim, (40, 40, 46), ink=7, smooth=False)
# çatlak ve kan lekesi kaskta
c.stroke([(600, 300), (585, 330), (605, 355), (590, 385)], 4)
for (x, y, r) in [(540, 300, 9), (555, 318, 5), (520, 330, 4)]:
    c.d.ellipse([(x - r) * S, (y - r) * S, (x + r) * S, (y + r) * S], fill=(120, 15, 20))
# --- balta sapı (ön plan, çapraz)
c.shape([(830, 1080), (860, 1080), (1060, 470), (1035, 460)], (110, 70, 40), ink=6, smooth=False)
c.shape([(1000, 420), (1080, 380), (1080, 560), (1045, 520), (1030, 470)], (190, 195, 205), ink=6, smooth=False)
c.stroke([(1050, 400), (1078, 390)], 4, (255, 255, 255), smooth=False, taper=False)
img = c.out()
# --- konuşma balonu + altyazı kutusu
d = ImageDraw.Draw(img)
f = ImageFont.truetype("fonts/Kalam-Bold.ttf", 46)
d.polygon([(250, 205), (330, 290), (300, 205)], fill=(250, 248, 240), outline=INK)
d.ellipse([40, 60, 420, 230], fill=(250, 248, 240), outline=INK, width=5)
d.text((230, 145), "Phone down, Vo.", font=f, fill=INK, anchor="mm")
d.rectangle([40, 950, 470, 1030], fill=(245, 215, 90), outline=INK, width=5)
d.text((60, 990), "MOSS. CREW LEAD.", font=ImageFont.truetype("fonts/Kalam-Bold.ttf", 40), fill=INK, anchor="lm")
img.save("cikti/dizi/comic_pro_moss.png")
