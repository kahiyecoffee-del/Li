"""Anlatıcı karakter: "Theo" — gözlüklü, sakallı, tüvit ceketli entelektüel.

2.5D / kil (clay) görünüm: her parça maskeden yükseklik haritası çıkarılarak
ışıklandırılır (yumuşak gölge + parlama). Gerçek 3D motoru gerektirmez.
"""
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SKIN = (232, 188, 152)
HAIR = (62, 46, 38)
HAIR_GREY = (120, 110, 104)
BEARD = (78, 60, 50)
BLAZER = (150, 104, 66)
BLAZER_DARK = (112, 76, 48)
KNIT = (42, 52, 78)        # balıkçı yaka kazak
TROUSER = (58, 60, 70)
SHOE = (92, 58, 38)
GLASS = (35, 30, 28)
INK = (40, 28, 24)

LIGHT = np.array([-0.45, -0.65, 0.62])
LIGHT = LIGHT / np.linalg.norm(LIGHT)


def _r(a):
    return math.radians(a)


def _limb(start, a1, a2, l1, l2):
    e = (start[0] + math.sin(_r(a1)) * l1, start[1] + math.cos(_r(a1)) * l1)
    h = (e[0] + math.sin(_r(a2)) * l2, e[1] + math.cos(_r(a2)) * l2)
    return e, h


class Clay:
    """Şekilleri yumuşak 3D gölgelendirme ile çizer."""

    def __init__(self, img, sc):
        self.img = img
        self.sc = sc

    def shape(self, draw_fn, bbox, color, puff=0.22, outline=True, spec=0.28, ao=0.0):
        W, H = self.img.size
        pad = int(8 * self.sc) + 4
        x0 = max(0, int(bbox[0]) - pad)
        y0 = max(0, int(bbox[1]) - pad)
        x1 = min(W, int(bbox[2]) + pad)
        y1 = min(H, int(bbox[3]) + pad)
        if x1 - x0 < 3 or y1 - y0 < 3:
            return
        ss = 2  # kenar yumuşatma için 2x çiz
        mask = Image.new("L", ((x1 - x0) * ss, (y1 - y0) * ss), 0)
        draw_fn(ImageDraw.Draw(mask), lambda p: ((p[0] - x0) * ss, (p[1] - y0) * ss), ss)
        mask = mask.resize((x1 - x0, y1 - y0), Image.LANCZOS)
        m = np.asarray(mask, dtype=np.float32) / 255.0
        if m.max() <= 0:
            return
        rad = max(2.0, puff * min(x1 - x0, y1 - y0))
        hgt = np.asarray(mask.filter(ImageFilter.GaussianBlur(rad)), dtype=np.float32) / 255.0
        gy, gx = np.gradient(hgt)
        k = 1.0 / max(1e-3, 0.02 * rad / 10)
        nx, ny, nz = -gx * k * 6, -gy * k * 6, np.ones_like(gx)
        n = np.sqrt(nx * nx + ny * ny + nz * nz)
        diff = np.clip((nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]) / n, 0, 1)
        shade = 0.5 + 0.62 * diff - ao * (1 - hgt)
        hl = (diff ** 24) * spec
        col = np.array(color, dtype=np.float32)
        rgb = col[None, None, :] * shade[..., None] + 255 * hl[..., None]
        if outline:
            edge = np.asarray(mask.filter(ImageFilter.MaxFilter(3)), dtype=np.float32) / 255.0
            ring = np.clip(edge - np.asarray(mask.filter(ImageFilter.MinFilter(int(max(3, 2 * round(1.6 * self.sc) + 1)))),
                                              dtype=np.float32) / 255.0, 0, 1)
            dark = col * 0.38
            rgb = rgb * (1 - ring[..., None] * 0.85) + dark[None, None, :] * ring[..., None] * 0.85
        rgb = np.clip(rgb, 0, 255)
        region = np.asarray(self.img.crop((x0, y0, x1, y1)), dtype=np.float32)
        out = region * (1 - m[..., None]) + rgb * m[..., None]
        self.img.paste(Image.fromarray(out.astype(np.uint8)), (x0, y0))

    def ellipse(self, c, rx, ry, color, **kw):
        def f(d, T, ss):
            a, b = T((c[0] - rx, c[1] - ry)), T((c[0] + rx, c[1] + ry))
            d.ellipse([a, b], fill=255)
        self.shape(f, (c[0] - rx, c[1] - ry, c[0] + rx, c[1] + ry), color, **kw)

    def poly(self, pts, color, **kw):
        xs, ys = [p[0] for p in pts], [p[1] for p in pts]

        def f(d, T, ss):
            d.polygon([T(p) for p in pts], fill=255)
        self.shape(f, (min(xs), min(ys), max(xs), max(ys)), color, **kw)

    def capsule(self, pts, width, color, **kw):
        xs, ys = [p[0] for p in pts], [p[1] for p in pts]
        r = width / 2

        def f(d, T, ss):
            q = [T(p) for p in pts]
            d.line(q, fill=255, width=int(width * ss), joint="curve")
            for p in (q[0], q[-1]):
                d.ellipse([p[0] - r * ss, p[1] - r * ss, p[0] + r * ss, p[1] + r * ss], fill=255)
        self.shape(f, (min(xs) - r, min(ys) - r, max(xs) + r, max(ys) + r), color, **kw)


def _egg(cx, cy, w, h, bottom=0.92, n=48):
    pts = []
    for i in range(n):
        u = 2 * math.pi * i / n
        x, y = math.cos(u), math.sin(u)
        f = bottom if y > 0 else 1.0
        pts.append((cx + x * w / 2 * (1 - (1 - f) * y * y), cy + y * h / 2))
    return pts


def draw_character(img, p, expr, cx, ground_y, sc, mouth, t, glow=False, look=(0.0, 0.0), blink=False, talking=False):
    clay = Clay(img, sc)
    d = ImageDraw.Draw(img)
    da = ImageDraw.Draw(img, "RGBA")
    bob = p["bob"] * sc * 0.6
    LEG, TORSO = 260 * sc, 250 * sc
    hip_y = ground_y - LEG + bob
    lean = math.tan(_r(p["lean"] * 0.6))
    breathe = 2.5 * sc * math.sin(t * 2.2)

    # gölge
    da.ellipse([cx - 120 * sc, ground_y - 14 * sc, cx + 120 * sc, ground_y + 14 * sc], fill=(0, 0, 0, 55))

    # bacaklar
    for side, a1, a2 in ((-1, p["ll1"], p["ll2"]), (1, p["rl1"], p["rl2"])):
        hip = (cx + side * 45 * sc, hip_y)
        knee, foot = _limb(hip, a1 * 0.8, a2 * 0.8, LEG * 0.52, LEG * 0.48)
        clay.capsule([hip, knee, foot], 62 * sc, TROUSER, puff=0.3)
        clay.ellipse((foot[0] + side * 14 * sc, foot[1] + 4 * sc), 44 * sc, 22 * sc, SHOE, puff=0.35, spec=0.5)

    # gövde (ceket)
    top_y = hip_y - TORSO - breathe
    sh_w, wa_w = 128 * sc, 104 * sc
    tx = (hip_y - top_y) * lean
    torso = [(cx - wa_w, hip_y + 10 * sc), (cx - sh_w + tx, top_y + 30 * sc), (cx - sh_w * 0.8 + tx, top_y),
             (cx + sh_w * 0.8 + tx, top_y), (cx + sh_w + tx, top_y + 30 * sc), (cx + wa_w, hip_y + 10 * sc)]
    clay.poly(torso, BLAZER, puff=0.18, ao=0.15)
    # kazak (V açıklık) + yaka
    v = [(cx - 52 * sc + tx, top_y + 2 * sc), (cx + 52 * sc + tx, top_y + 2 * sc), (cx + 6 * sc + tx * 0.4, top_y + 150 * sc),
         (cx - 6 * sc + tx * 0.4, top_y + 150 * sc)]
    clay.poly(v, KNIT, puff=0.25, outline=False)
    for side in (-1, 1):  # ceket yakaları
        lap = [(cx + side * 52 * sc + tx, top_y + 2 * sc), (cx + side * 90 * sc + tx, top_y + 10 * sc),
               (cx + side * 48 * sc + tx * 0.6, top_y + 85 * sc), (cx + side * 8 * sc + tx * 0.4, top_y + 155 * sc)]
        clay.poly(lap, BLAZER_DARK, puff=0.3, spec=0.15)
    # düğme ve cep mendili
    bx = cx + tx * 0.3
    d.ellipse([bx - 7 * sc, top_y + 175 * sc, bx + 7 * sc, top_y + 189 * sc], fill=(60, 40, 28))
    d.polygon([(cx - 95 * sc + tx, top_y + 85 * sc), (cx - 60 * sc + tx, top_y + 85 * sc), (cx - 72 * sc + tx, top_y + 70 * sc),
               (cx - 86 * sc + tx, top_y + 66 * sc)], fill=(170, 40, 50))

    # boyun ve balıkçı yaka
    neck_c = (cx + tx, top_y - 10 * sc)
    clay.capsule([(neck_c[0], top_y + 10 * sc), (neck_c[0], top_y - 30 * sc)], 58 * sc, SKIN, puff=0.4, outline=False)
    clay.capsule([(neck_c[0] - 40 * sc, top_y + 4 * sc), (neck_c[0] + 40 * sc, top_y + 4 * sc)], 34 * sc, KNIT, puff=0.4)

    # baş
    hs = sc * 1.14  # baş biraz büyük (sevimli oran)
    droop = p["droop"] * hs * 0.6
    hx = neck_c[0] + p["head"] * 1.6 * hs
    hy = top_y - 120 * hs + droop
    HW, HH = 176 * hs, 214 * hs
    for side in (-1, 1):  # kulaklar
        clay.ellipse((hx + side * HW * 0.49, hy + 8 * hs), 20 * hs, 30 * hs, SKIN, puff=0.4, spec=0.1)
    clay.poly(_egg(hx, hy, HW, HH, bottom=0.82), SKIN, puff=0.28, spec=0.18)
    # sakal (çene hattı)
    beard = []
    for i in range(25):
        u = math.pi * i / 24
        beard.append((hx - math.cos(u) * HW * 0.47 * (1 - 0.15 * math.sin(u)), hy + 20 * hs + math.sin(u) * HH * 0.44))
    for i in range(24, -1, -1):
        u = math.pi * i / 24
        beard.append((hx - math.cos(u) * HW * 0.3, hy + 52 * hs + math.sin(u) * 22 * hs))
    clay.poly(beard, BEARD, puff=0.35, spec=0.05)
    # saç (yandan ayrılmış, şakaklarda kırlaşma)
    hair = []
    for i in range(31):
        u = math.pi + math.pi * i / 30
        hair.append((hx + math.cos(u) * HW * 0.54, hy - 12 * hs + math.sin(u) * HH * 0.6))
    hair += [(hx + HW * 0.5, hy + 6 * hs), (hx + HW * 0.47, hy - 38 * hs), (hx + HW * 0.3, hy - 66 * hs),
             (hx + HW * 0.05, hy - 74 * hs), (hx - HW * 0.12, hy - 60 * hs), (hx - HW * 0.2, hy - 78 * hs),
             (hx - HW * 0.42, hy - 48 * hs), (hx - HW * 0.5, hy + 6 * hs)]
    clay.poly(hair, HAIR, puff=0.3, spec=0.35)
    d.line([(hx - HW * 0.14, hy - HH * 0.55), (hx - HW * 0.2, hy - 76 * hs)], fill=(35, 25, 20), width=max(2, int(4 * hs)))
    for k in range(4):  # saç telleri
        x0 = hx + HW * (0.0 + 0.1 * k)
        d.arc([x0 - 40 * hs, hy - HH * 0.62, x0 + 30 * hs, hy - 40 * hs], 200, 280, fill=(95, 72, 60), width=max(2, int(3 * hs)))

    # yüz
    ey = hy - 4 * hs
    ex = 38 * hs
    lx, ly = look
    lid = {"tired": 0.55, "sad": 0.25, "think": 0.2, "neutral": 0.12, "down": 0.3}.get(expr, 0.0)
    if expr == "shock":
        lid = -0.1
    for side in (-1, 1):
        c = (hx + side * ex, ey)
        rx, ry = 17 * hs, 13 * hs * (1.25 if expr == "shock" else 1.0)
        if blink:
            d.line([(c[0] - rx, c[1] + 2 * hs), (c[0] + rx, c[1] + 2 * hs)], fill=INK, width=max(2, int(4 * hs)))
            continue
        d.ellipse([c[0] - rx, c[1] - ry, c[0] + rx, c[1] + ry], fill=(250, 248, 244))
        ir = 10 * hs
        ix, iy = c[0] + lx * rx * 0.45, c[1] + ly * ry * 0.4
        d.ellipse([ix - ir, iy - ir, ix + ir, iy + ir], fill=(85, 60, 40))
        d.ellipse([ix - ir * 0.55, iy - ir * 0.55, ix + ir * 0.55, iy + ir * 0.55], fill=(20, 15, 12))
        d.ellipse([ix - ir * 0.5, iy - ir * 0.7, ix - ir * 0.05, iy - ir * 0.25], fill=(255, 255, 255))
        yl = c[1] - ry + 2 * ry * max(lid, 0)
        if lid > 0:
            arc = [(c[0] + math.cos(u) * (rx + 1), c[1] + math.sin(u) * (ry + 1))
                   for u in (math.pi + math.pi * k / 16 for k in range(17))]
            cover = [(x, min(y, yl)) for x, y in arc]
            d.polygon(cover + [(c[0] + rx + 1, yl), (c[0] - rx - 1, yl)], fill=SKIN)
        d.arc([c[0] - rx, c[1] - ry, c[0] + rx, c[1] + ry], 190, 350, fill=INK, width=max(2, int(4 * hs)))
        if lid > 0:
            d.line([(c[0] - rx * 0.95, yl), (c[0] + rx * 0.95, yl)], fill=INK, width=max(2, int(4 * hs)))
    # kaşlar (kalın, ciddi)
    brows = {"neutral": (6, 0), "happy": (0, -6), "shock": (-6, -16), "sad": (-14, -4), "think": (10, -2),
             "confused": (12, -6), "tired": (2, 4), "down": (6, 2)}
    tilt, lift = brows.get(expr, (6, 0))
    for side in (-1, 1):
        tl, lf = tilt, lift
        if expr in ("think", "confused") and side == 1:
            tl, lf = -8, -14  # tek kaş kalkık
        inner = (hx + side * 16 * hs, ey - 30 * hs + lf * hs + tl * hs * 0.5)
        outer = (hx + side * 62 * hs, ey - 34 * hs + lf * hs - tl * hs * 0.4)
        d.line([inner, outer], fill=HAIR, width=max(3, int(11 * hs)))
    # burun
    d.arc([hx - 12 * hs, ey + 12 * hs, hx + 12 * hs, ey + 40 * hs], 300, 100, fill=(190, 140, 110), width=max(2, int(4 * hs)))
    # bıyık + ağız
    my = hy + 62 * hs
    d.chord([hx - 40 * hs, my - 26 * hs, hx + 40 * hs, my + 6 * hs], 180, 360, fill=BEARD)
    if expr == "shock":
        d.ellipse([hx - 13 * hs, my - 2 * hs, hx + 13 * hs, my + 24 * hs], fill=(70, 25, 30))
    elif talking and mouth > 0.05:
        mh = (6 + 24 * mouth) * hs
        mw = (24 + 6 * mouth) * hs
        d.ellipse([hx - mw, my - 2 * hs, hx + mw, my - 2 * hs + mh], fill=(70, 25, 30))
        d.chord([hx - mw * 0.75, my - 2 * hs, hx + mw * 0.75, my + mh * 0.45], 180, 360, fill=(245, 240, 230))
    elif expr == "happy":
        d.arc([hx - 28 * hs, my - 18 * hs, hx + 28 * hs, my + 12 * hs], 20, 160, fill=(70, 25, 30), width=max(2, int(6 * hs)))
    elif expr in ("sad", "tired"):
        d.arc([hx - 22 * hs, my + 2 * hs, hx + 22 * hs, my + 24 * hs], 200, 340, fill=(70, 25, 30), width=max(2, int(5 * hs)))
    elif expr == "think":
        d.line([(hx - 18 * hs, my + 6 * hs), (hx + 22 * hs, my + 2 * hs)], fill=(70, 25, 30), width=max(2, int(5 * hs)))
    else:
        d.line([(hx - 22 * hs, my + 4 * hs), (hx + 22 * hs, my + 4 * hs)], fill=(70, 25, 30), width=max(2, int(5 * hs)))
    # gözlük (yuvarlak, yansımalı)
    gw = max(2, int(5 * hs))
    for side in (-1, 1):
        c = (hx + side * ex, ey + 2 * hs)
        R = 30 * hs
        da.ellipse([c[0] - R, c[1] - R, c[0] + R, c[1] + R], fill=(200, 225, 240, 45))
        da.line([(c[0] - R * 0.5, c[1] - R * 0.15), (c[0] - R * 0.1, c[1] - R * 0.6)], fill=(255, 255, 255, 150),
                width=max(2, int(5 * hs)))
        d.ellipse([c[0] - R, c[1] - R, c[0] + R, c[1] + R], outline=GLASS, width=gw)
        d.line([(c[0] + side * R, c[1] - 4 * hs), (hx + side * HW * 0.47, c[1] - 6 * hs)], fill=GLASS, width=gw)
    d.arc([hx - 10 * hs, ey - 6 * hs, hx + 10 * hs, ey + 10 * hs], 200, 340, fill=GLASS, width=gw)

    # kollar (ceket kolu) + eller
    hands = []
    for side, a1, a2 in ((-1, p["la1"], p["la2"]), (1, p["ra1"], p["ra2"])):
        sh = (cx + side * sh_w * 0.86 + tx, top_y + 32 * sc)
        a1 = a1 + side * 8 if abs(a1) < 25 else a1
        elbow, hand = _limb(sh, a1, a2, 128 * sc, 112 * sc)
        clay.capsule([sh, elbow], 60 * sc, BLAZER, puff=0.32)
        clay.capsule([elbow, hand], 52 * sc, BLAZER, puff=0.32)
        cuff = (elbow[0] + (hand[0] - elbow[0]) * 0.86, elbow[1] + (hand[1] - elbow[1]) * 0.86)
        clay.ellipse(cuff, 22 * sc, 22 * sc, (235, 232, 225), puff=0.4, spec=0.1)
        clay.ellipse(hand, 26 * sc, 28 * sc, SKIN, puff=0.4, spec=0.15)
        hands.append(hand)

    if glow:  # fikir anı: başın üstünde yumuşak ışık
        gx_, gy_ = hx + 90 * sc, hy - HH * 0.75
        for k in range(8):
            a = k * math.pi / 4 + t * 1.5
            d.line([(gx_ + math.cos(a) * 30 * sc, gy_ + math.sin(a) * 30 * sc),
                    (gx_ + math.cos(a) * 44 * sc, gy_ + math.sin(a) * 44 * sc)], fill=(240, 195, 80), width=max(2, int(5 * sc)))
        clay.ellipse((gx_, gy_), 20 * sc, 20 * sc, (255, 210, 90), puff=0.4, spec=0.6)

    return dict(hand_l=hands[0], hand_r=hands[1], head=(hx, hy - HH / 2),
                hands=((hands[0][0] + hands[1][0]) / 2, (hands[0][1] + hands[1][1]) / 2), face=(hx, hy))
