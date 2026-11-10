"""Arka planlar, dekorasyonlar ve karaoke altyazı.

Arka planlar: room, office, park, city, notebook, plain
Dekorasyonlar: sparkles, confetti, hearts, speed, coins, questions, rain
"""
import math
import random

import numpy as np
from PIL import Image, ImageDraw

INK = (25, 25, 25)
SOFT = (95, 85, 80)  # arka plan çizgileri: figürden daha açık


def _darker(c, k=0.75):
    return tuple(int(v * k) for v in c)


def _grain(img, amount=5, seed=7):
    arr = np.asarray(img).astype(np.int16)
    rng = np.random.default_rng(seed)
    noise = rng.integers(-amount, amount + 1, size=arr.shape[:2], dtype=np.int16)[..., None]
    return Image.fromarray(np.clip(arr + noise, 0, 255).astype(np.uint8))


def _vgrad(d, box, top, bottom):
    x0, y0, x1, y1 = [int(v) for v in box]
    for y in range(y0, y1):
        k = (y - y0) / max(1, y1 - y0 - 1)
        d.line([(x0, y), (x1, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * k) for i in range(3)))


def slots(F):
    """Figürün iki yanındaki dekor yerleri (zemin ve duvar)."""
    W, H, sc = F["w"], F["h"], F["sc"]
    floor = F["hip_y"] + 292 * sc
    if H > W:  # dikey
        return dict(floor=floor, left_low=(150, floor), right_low=(930, floor),
                    left_high=(160, floor - 560 * sc), right_high=(920, floor - 560 * sc), s=1.0)
    return dict(floor=floor, left_low=(150, floor), right_low=(1810, floor),
                left_high=(170, 300), right_high=(1760, 230), s=0.85)


# --------------------------------------------------------------------------- #
# Sabit öğeler (el çizimi tarzı)
# --------------------------------------------------------------------------- #
def plant(d, x, y, s):
    pot = [(x - 45 * s, y - 95 * s), (x + 45 * s, y - 95 * s), (x + 33 * s, y), (x - 33 * s, y)]
    for ang, ln in ((-35, 190), (-12, 240), (10, 220), (32, 175), (-60, 130), (55, 140)):
        a = math.radians(ang)
        tip = (x + math.sin(a) * ln * s, y - 95 * s - math.cos(a) * ln * s)
        mid = (x + math.sin(a) * ln * 0.5 * s, y - 95 * s - math.cos(a) * ln * 0.5 * s)
        w = 26 * s
        leaf = [(x, y - 95 * s), (mid[0] - w * math.cos(a), mid[1] - w * math.sin(a)), tip,
                (mid[0] + w * math.cos(a), mid[1] + w * math.sin(a))]
        d.polygon(leaf, fill=(120, 185, 110), outline=SOFT, width=int(4 * s))
    d.polygon(pot, fill=(215, 120, 85), outline=SOFT, width=int(5 * s))
    d.rectangle([x - 50 * s, y - 108 * s, x + 50 * s, y - 92 * s], fill=(200, 105, 75), outline=SOFT, width=int(4 * s))


def floor_lamp(d, x, y, s):
    d.line([(x, y), (x, y - 330 * s)], fill=SOFT, width=int(8 * s))
    d.ellipse([x - 45 * s, y - 14 * s, x + 45 * s, y + 4 * s], fill=(120, 110, 105))
    shade = [(x - 70 * s, y - 330 * s), (x + 70 * s, y - 330 * s), (x + 45 * s, y - 430 * s), (x - 45 * s, y - 430 * s)]
    d.polygon(shade, fill=(250, 220, 140), outline=SOFT, width=int(5 * s))


def frame(d, x, y, s, kind="mountain"):
    w, h = 150 * s, 115 * s
    d.rectangle([x - w / 2, y - h / 2, x + w / 2, y + h / 2], fill=(170, 125, 80), outline=SOFT, width=int(5 * s))
    ix0, iy0, ix1, iy1 = x - w / 2 + 14 * s, y - h / 2 + 14 * s, x + w / 2 - 14 * s, y + h / 2 - 14 * s
    d.rectangle([ix0, iy0, ix1, iy1], fill=(190, 225, 245))
    if kind == "mountain":
        d.polygon([(ix0, iy1), ((ix0 + ix1) / 2 - 10 * s, iy0 + 20 * s), (ix1, iy1)], fill=(110, 170, 120))
        d.ellipse([ix1 - 30 * s, iy0 + 8 * s, ix1 - 12 * s, iy0 + 26 * s], fill=(255, 205, 60))
    else:  # grafik posteri
        d.rectangle([ix0, iy0, ix1, iy1], fill=(250, 250, 250))
        for i, hh in enumerate((0.3, 0.5, 0.45, 0.8)):
            bx = ix0 + 10 * s + i * (ix1 - ix0 - 20 * s) / 4
            d.rectangle([bx, iy1 - (iy1 - iy0 - 10 * s) * hh, bx + 14 * s, iy1 - 4 * s], fill=(90, 150, 230))


def shelf(d, x, y, s):
    d.rectangle([x - 110 * s, y, x + 110 * s, y + 14 * s], fill=(170, 125, 80), outline=SOFT, width=int(4 * s))
    colors = [(230, 90, 80), (90, 150, 230), (250, 200, 70), (110, 180, 110), (180, 120, 200)]
    bx = x - 100 * s
    for i, c in enumerate(colors):
        h = (70 + (i * 23) % 35) * s
        w = 26 * s
        if i == 4:  # yatık kitap
            d.rectangle([bx, y - 24 * s, bx + 70 * s, y], fill=c, outline=SOFT, width=int(3 * s))
            break
        d.rectangle([bx, y - h, bx + w, y], fill=c, outline=SOFT, width=int(3 * s))
        bx += w + 4 * s


def window(d, x, y, s, night=False):
    w, h = 210 * s, 250 * s
    d.rectangle([x - w / 2, y - h / 2, x + w / 2, y + h / 2], fill=(25, 40, 90) if night else (175, 220, 250),
                outline=SOFT, width=int(8 * s))
    d.ellipse([x + 20 * s, y - 90 * s, x + 70 * s, y - 40 * s], fill=(255, 225, 120))
    d.line([(x, y - h / 2), (x, y + h / 2)], fill=SOFT, width=int(7 * s))
    d.line([(x - w / 2, y), (x + w / 2, y)], fill=SOFT, width=int(7 * s))
    for side in (-1, 1):  # perdeler
        cx = x + side * (w / 2 + 10 * s)
        d.polygon([(cx - 22 * s, y - h / 2 - 15 * s), (cx + 22 * s, y - h / 2 - 15 * s), (cx + 30 * s * side, y + h / 2 + 20 * s),
                   (cx - 10 * s * side, y + h / 2 + 20 * s)], fill=(235, 120, 110), outline=SOFT, width=int(4 * s))


def desk(d, x, y, s):
    d.rectangle([x - 150 * s, y - 175 * s, x + 150 * s, y - 155 * s], fill=(175, 130, 85), outline=SOFT, width=int(5 * s))
    for lx in (x - 130 * s, x + 130 * s):
        d.line([(lx, y - 155 * s), (lx, y)], fill=SOFT, width=int(8 * s))
    d.polygon([(x - 70 * s, y - 175 * s), (x + 30 * s, y - 175 * s), (x + 20 * s, y - 250 * s), (x - 60 * s, y - 250 * s)],
              fill=(150, 160, 175), outline=SOFT, width=int(4 * s))
    d.rectangle([x + 60 * s, y - 215 * s, x + 95 * s, y - 175 * s], fill=(240, 240, 240), outline=SOFT, width=int(4 * s))


def tree(d, x, y, s):
    d.rectangle([x - 16 * s, y - 210 * s, x + 16 * s, y], fill=(150, 105, 70), outline=SOFT, width=int(4 * s))
    for dx, dy, r in ((0, -300, 95), (-70, -240, 70), (70, -240, 70), (0, -200, 60)):
        d.ellipse([x + (dx - r) * s, y + (dy - r) * s, x + (dx + r) * s, y + (dy + r) * s], fill=(110, 175, 100),
                  outline=SOFT, width=int(4 * s))


def street_lamp(d, x, y, s):
    d.line([(x, y), (x, y - 420 * s)], fill=(90, 95, 105), width=int(10 * s))
    d.line([(x, y - 420 * s), (x - 60 * s, y - 420 * s)], fill=(90, 95, 105), width=int(8 * s))
    d.ellipse([x - 85 * s, y - 425 * s, x - 35 * s, y - 385 * s], fill=(255, 225, 130), outline=SOFT, width=int(4 * s))


def doodle_star(d, x, y, r, color, w):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
    d.polygon(pts, fill=color, outline=SOFT, width=w)


def build_static(kind, F):
    W, H, sc = F["w"], F["h"], F["sc"]
    S = slots(F)
    fl, s = S["floor"], S["s"]
    img = Image.new("RGB", (W, H), (250, 249, 244))
    d = ImageDraw.Draw(img)
    if kind in ("room", "office"):
        wall = (245, 232, 212) if kind == "room" else (226, 236, 242)
        d.rectangle([0, 0, W, fl], fill=wall)
        stripe = _darker(wall, 0.97)
        for x in range(0, W, 70):
            d.rectangle([x, 0, x + 30, fl], fill=stripe)
        floor_c = (200, 155, 110) if kind == "room" else (175, 180, 190)
        d.rectangle([0, fl, W, H], fill=floor_c)
        for i, y in enumerate(range(int(fl) + 55, H, 70)):
            d.line([(0, y), (W, y)], fill=_darker(floor_c, 0.88), width=3)
            off = 140 if i % 2 else 0
            for x in range(off, W, 280):
                d.line([(x, y - 70), (x, y)], fill=_darker(floor_c, 0.88), width=3)
        d.rectangle([0, fl - 6, W, fl + 16], fill=(250, 250, 250), outline=SOFT, width=3)
        if kind == "room":
            plant(d, *S["left_low"], 1.15 * s)
            floor_lamp(d, *S["right_low"], 1.1 * s)
            frame(d, *S["left_high"], 1.1 * s)
            shelf(d, *S["right_high"], 1.0 * s)
        else:
            plant(d, *S["left_low"], 1.0 * s)
            desk(d, S["right_low"][0] - 20 * s, fl, 1.0 * s)
            frame(d, *S["left_high"], 1.1 * s, kind="chart")
            window(d, *S["right_high"], 0.9 * s)
    elif kind in ("park", "city"):
        _vgrad(d, (0, 0, W, fl), (150, 205, 245), (225, 240, 250))
        if kind == "park":
            for i, (cx, r, c) in enumerate(((0.15, 0.55, (165, 210, 130)), (0.8, 0.6, (150, 200, 120)))):
                d.ellipse([W * cx - W * r, fl - W * r * 0.35, W * cx + W * r, fl + W * r * 0.5], fill=c)
            d.rectangle([0, fl, W, H], fill=(125, 185, 95))
            rng = random.Random(3)
            for _ in range(int(W / 12)):
                gx = rng.uniform(0, W)
                gy = rng.uniform(fl + 10, H)
                d.line([(gx, gy), (gx + rng.uniform(-6, 6), gy - 18 * sc)], fill=(95, 155, 75), width=3)
            for _ in range(int(W / 70)):
                fx, fy = rng.uniform(0, W), rng.uniform(fl + 30, H - 20)
                c = rng.choice([(255, 255, 255), (250, 210, 70), (240, 120, 140)])
                for k in range(5):
                    a = k * 2 * math.pi / 5
                    d.ellipse([fx + math.cos(a) * 9 - 7, fy + math.sin(a) * 9 - 7, fx + math.cos(a) * 9 + 7,
                               fy + math.sin(a) * 9 + 7], fill=c)
                d.ellipse([fx - 5, fy - 5, fx + 5, fy + 5], fill=(240, 170, 40))
            tree(d, *S["left_low"], 1.1 * s)
            tree(d, *S["right_low"], 0.95 * s)
        else:
            rng = random.Random(5)
            x = -20
            while x < W:
                bw = rng.uniform(110, 200) * s
                bh = rng.uniform(250, 520) * s
                c = rng.choice([(200, 205, 220), (185, 195, 215), (210, 200, 205)])
                d.rectangle([x, fl - bh, x + bw, fl], fill=c, outline=_darker(c, 0.85), width=3)
                for wy in np.arange(fl - bh + 25 * s, fl - 40 * s, 48 * s):
                    for wx in np.arange(x + 18 * s, x + bw - 30 * s, 40 * s):
                        lit = rng.random() < 0.3
                        d.rectangle([wx, wy, wx + 20 * s, wy + 26 * s], fill=(255, 235, 160) if lit else _darker(c, 0.9))
                x += bw + rng.uniform(5, 25)
            d.rectangle([0, fl, W, H], fill=(190, 190, 195))
            d.rectangle([0, fl, W, fl + 14], fill=(160, 160, 165))
            for x in range(0, W, 160):
                d.line([(x, fl + 14), (x - 40, H)], fill=(170, 170, 175), width=3)
            street_lamp(d, *S["right_low"], 1.1 * s)
            plant(d, *S["left_low"], 0.9 * s)
    elif kind == "notebook":
        d.rectangle([0, 0, W, H], fill=(252, 251, 245))
        gap = int(64 * sc)
        for y in range(gap * 2, H, gap):
            d.line([(0, y), (W, y)], fill=(190, 215, 240), width=3)
        mx = int(110 * sc)
        d.line([(mx, 0), (mx, H)], fill=(240, 150, 150), width=4)
        for y in range(int(gap * 1.5), H, int(gap * 3)):
            d.ellipse([mx / 2 - 14, y - 14, mx / 2 + 14, y + 14], fill=(225, 225, 220), outline=(200, 200, 195), width=2)
        rng = random.Random(11)
        corners = [(W * 0.82, H * 0.07), (W * 0.9, H * 0.5), (W * 0.2, H * 0.92), (W * 0.85, H * 0.9)]
        for (cx, cy) in corners:
            doodle_star(d, cx + rng.uniform(-20, 20), cy, 22 * sc, (250, 215, 90), 3)
        # zemin: kalem çizgisi
        d.line([(F["fig_x"] - 300 * sc, fl), (F["fig_x"] + 300 * sc, fl)], fill=(140, 140, 140), width=int(6 * sc))
    else:  # plain
        d.line([(F["fig_x"] - 260 * sc, fl + 6), (F["fig_x"] + 260 * sc, fl + 6)], fill=(170, 170, 170), width=int(6 * sc))
    return _grain(img, 4)


def animate(kind, d, F, t):
    """Arka plandaki hareketli öğeler (bulutlar, güneş, kuşlar)."""
    W, H, sc = F["w"], F["h"], F["sc"]
    if kind in ("park", "city"):
        sx, sy = (W * 0.13, H * 0.41) if H > W else (W * 0.9, H * 0.12)
        r = 55 * sc
        for i in range(10):
            a = t * 0.4 + i * math.pi / 5
            d.line([(sx + math.cos(a) * r * 1.3, sy + math.sin(a) * r * 1.3),
                    (sx + math.cos(a) * r * 1.75, sy + math.sin(a) * r * 1.75)], fill=(245, 190, 50), width=int(6 * sc))
        d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=(255, 210, 70), outline=(240, 170, 40), width=int(4 * sc))
        ys = (0.21, 0.31, 0.37) if H > W else (0.06, 0.16, 0.03)
        for i, (y0, sp, cs) in enumerate(zip(ys, (18, 11, 7), (1.0, 0.8, 0.65))):
            cx = ((i * 0.37 * W + t * sp * sc * 3) % (W + 400)) - 200
            cy = H * y0
            k = cs * sc
            for dx, dy, rr in ((0, 0, 45), (45, -18, 55), (95, 0, 45), (48, 15, 45)):
                d.ellipse([cx + (dx - rr) * k, cy + (dy - rr) * k, cx + (dx + rr) * k, cy + (dy + rr) * k], fill=(255, 255, 255))
        if kind == "park":
            for i in range(2):
                bx = ((t * 60 * sc + i * 140) % (W + 300)) - 150
                by = H * (0.2 if H > W else 0.25) + i * 30 + 8 * math.sin(t * 3 + i)
                fl = 12 * math.sin(t * 12 + i) * sc
                d.line([(bx - 18 * sc, by - fl), (bx, by), (bx + 18 * sc, by - fl)], fill=SOFT, width=int(4 * sc), joint="curve")


# --------------------------------------------------------------------------- #
# Dekorasyonlar (sahneye eklenen efektler)
# --------------------------------------------------------------------------- #
DEFAULT_DECO = {"celebrate": ["confetti"], "run": ["speed"], "idea": ["sparkles"], "wave": ["hearts"],
                "shock": ["exclaims"], "think": ["questions"], "shrug": ["questions"], "tired": ["zzz"]}


def deco(name, d, F, t, font_fn, avoid):
    W, H, sc = F["w"], F["h"], F["sc"]
    rng = random.Random(hash(name) & 0xffff)
    ax, ay = avoid  # figür merkezi, buradan uzak dur
    if name == "sparkles":
        for i in range(9):
            x, y = rng.uniform(0.08, 0.92) * W, rng.uniform(0.18, 0.75) * H
            if abs(x - ax) < 160 * sc and abs(y - ay) < 300 * sc:
                continue
            k = max(0.0, math.sin(t * 4 + i * 1.7))
            r = 26 * sc * k
            if r > 2:
                d.polygon([(x, y - r), (x + r * 0.25, y - r * 0.25), (x + r, y), (x + r * 0.25, y + r * 0.25), (x, y + r),
                           (x - r * 0.25, y + r * 0.25), (x - r, y), (x - r * 0.25, y - r * 0.25)], fill=(255, 205, 50),
                          outline=SOFT, width=max(2, int(3 * sc)))
    elif name == "confetti":
        cols = [(230, 70, 60), (60, 175, 90), (70, 140, 230), (255, 205, 50), (200, 110, 220)]
        for i in range(45):
            x0 = rng.uniform(0, W)
            sp = rng.uniform(120, 260) * sc
            y = (rng.uniform(-H, 0) + t * sp) % (H + 60) - 30
            x = x0 + 30 * sc * math.sin(t * 3 + i)
            a = t * 5 + i
            w, h = 14 * sc, 7 * sc * abs(math.cos(a))
            d.polygon([(x - w, y - h), (x + w, y - h), (x + w, y + h), (x - w, y + h)], fill=cols[i % len(cols)])
    elif name == "hearts":
        for i in range(6):
            x = rng.uniform(0.1, 0.9) * W
            if abs(x - ax) < 140 * sc:
                x += 280 * sc
            y = H * 0.75 - ((t * 90 * sc + i * 160) % (H * 0.6))
            r = 18 * sc
            d.ellipse([x - r, y - r, x, y], fill=(240, 100, 120))
            d.ellipse([x, y - r, x + r, y], fill=(240, 100, 120))
            d.polygon([(x - r, y - r * 0.45), (x + r, y - r * 0.45), (x, y + r)], fill=(240, 100, 120))
    elif name == "speed":
        for i in range(10):
            y = ay - 250 * sc + i * 55 * sc
            x = W - ((t * 900 * sc + i * 230) % (W + 400))
            if abs(x - ax) < 120 * sc:
                continue
            d.line([(x, y), (x + rng.uniform(80, 180) * sc, y)], fill=(160, 160, 160), width=int(6 * sc))
    elif name == "coins":
        for i in range(10):
            x = rng.uniform(0.05, 0.95) * W
            y = (rng.uniform(-H, 0) + t * 300 * sc) % (H + 80) - 40
            sq = abs(math.cos(t * 4 + i))
            r = 24 * sc
            d.ellipse([x - r * max(sq, 0.2), y - r, x + r * max(sq, 0.2), y + r], fill=(255, 205, 50), outline=SOFT,
                      width=max(2, int(3 * sc)))
    elif name in ("questions", "exclaims", "zzz"):
        ch = {"questions": "?", "exclaims": "!", "zzz": "z"}[name]
        f = font_fn(70 * sc)
        for i in range(3):
            ph = (t * 0.6 + i / 3) % 1.0
            x = ax + (110 + i * 30) * sc * (1 if i % 2 == 0 else -1)
            y = ay - 380 * sc - ph * 160 * sc
            col = (int(25 + 200 * ph),) * 3
            d.text((x, y), ch, font=f, fill=col, anchor="mm")
    elif name == "rain":
        for i in range(70):
            x = rng.uniform(0, W)
            y = (rng.uniform(0, H) + t * 900 * sc) % H
            d.line([(x, y), (x - 6 * sc, y + 30 * sc)], fill=(120, 160, 220), width=max(2, int(3 * sc)))


# --------------------------------------------------------------------------- #
# Karaoke altyazı
# --------------------------------------------------------------------------- #
def parse_words(text):
    """'*' ile işaretli anahtar kelimeleri ayırır: [(kelime, anahtar_mi)]."""
    out, inside = [], False
    for w in text.split():
        opens = w.startswith("*")
        closes = w.rstrip(".,!?;:।…").endswith("*")
        kw = inside or opens
        out.append((w.replace("*", ""), kw))
        if opens and not closes:
            inside = True
        elif closes:
            inside = False
    return out


def word_times(start, end, text):
    words = parse_words(text)
    total = sum(len(w) + 1 for w, _ in words) or 1
    res, acc = [], 0
    for w, kw in words:
        t0 = start + (end - start) * acc / total
        acc += len(w) + 1
        res.append((t0, start + (end - start) * acc / total, w, kw))
    return res


KEY = (255, 120, 100)


def draw_caption(img, F, t, start, end, text, font_fn, highlight=(255, 205, 50), key=None, box=(20, 20, 25, 185)):
    """Kutu içinde altyazı: anahtar kelimeler mercan rengi, söylenen kelime sarı ve zıplar."""
    d = ImageDraw.Draw(img, "RGBA")
    wt = word_times(start, end, text)
    if not wt:
        return None
    words = [w for _, _, w, _ in wt]
    cur = next((i for i, (a, b, _, _) in enumerate(wt) if a <= t < b), len(wt) - 1)
    size = F["cap_size"]
    pop = 0.9 + 0.1 * min(1.0, (t - start) / 0.12)
    while True:
        f = font_fn(size * pop)
        space = d.textlength(" ", font=f)
        widths = [d.textlength(w, font=f) for w in words]
        lines, line, lw = [], [], 0
        for i, w in enumerate(widths):
            if line and lw + space + w > F["cap_w"]:
                lines.append((line, lw))
                line, lw = [], 0
            lw = lw + (space if line else 0) + w
            line.append(i)
        lines.append((line, lw))
        if len(lines) <= 2 or size < 30:
            break
        size *= 0.9
    asc, desc = f.getmetrics()
    lh = (asc + desc) * 1.05
    pad = size * 0.28
    box_w = max(l[1] for l in lines) + pad * 2
    box_h = lh * len(lines) + pad * 1.2
    cx, cy = F["w"] / 2, F["cap_y"]
    y0 = cy - box_h / 2
    d.rounded_rectangle([cx - box_w / 2, y0, cx + box_w / 2, y0 + box_h], radius=int(size * 0.35), fill=box)
    stroke = max(2, int(size * 0.07))
    for li, (idxs, lw) in enumerate(lines):
        x = cx - lw / 2
        y = y0 + pad * 0.6 + li * lh
        for i in idxs:
            kw = wt[i][3]
            if i == cur:
                col, dy = highlight, -size * 0.06
            else:
                col, dy = ((key or KEY) if kw else (255, 255, 255)), 0
            if kw:  # anahtar kelimenin altına fosforlu kalem çizgisi
                d.rounded_rectangle([x - 4, y + asc * 0.78, x + widths[i] + 4, y + asc * 0.98],
                                    radius=6, fill=(*(key or KEY), 150))
            d.text((x, y + dy), words[i], font=f, fill=col, stroke_width=stroke, stroke_fill=(15, 15, 15))
            x += widths[i] + space
    return (cx - box_w / 2, y0, cx + box_w / 2, y0 + box_h)


# --------------------------------------------------------------------------- #
# Akademi teması (felsefe / tarih): kütüphane, çalışma odası, agora, parşömen
# --------------------------------------------------------------------------- #
def _vignette(img, strength=0.38):
    W, H = img.size
    y, x = np.ogrid[0:H, 0:W]
    r = np.sqrt(((x - W / 2) / (W / 2)) ** 2 + ((y - H / 2) / (H / 2)) ** 2)
    k = 1 - strength * np.clip(r - 0.55, 0, 1) ** 1.5
    arr = np.asarray(img).astype(np.float32) * k[..., None]
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))


def _bookshelf(d, x0, y0, x1, y1, seed, s):
    rng = random.Random(seed)
    wood, dark = (110, 70, 45), (80, 50, 32)
    d.rectangle([x0, y0, x1, y1], fill=(60, 38, 26))
    shelf_h = 150 * s
    y = y0 + 12 * s
    cols = [(130, 40, 45), (40, 70, 60), (45, 55, 95), (150, 110, 50), (95, 60, 40), (120, 90, 110), (70, 85, 60)]
    while y + shelf_h < y1:
        x = x0 + 10 * s
        while x < x1 - 30 * s:
            bw = rng.uniform(18, 34) * s
            bh = rng.uniform(0.62, 0.92) * shelf_h
            c = rng.choice(cols)
            if rng.random() < 0.08:  # yatık kitap yığını
                for k in range(3):
                    d.rectangle([x, y + shelf_h - 22 * s * (k + 1), x + 90 * s, y + shelf_h - 22 * s * k], fill=rng.choice(cols),
                                outline=dark, width=2)
                x += 100 * s
                continue
            d.rectangle([x, y + shelf_h - bh, x + bw, y + shelf_h], fill=c, outline=_darker(c, 0.6), width=2)
            d.line([(x + 3 * s, y + shelf_h - bh + 12 * s), (x + bw - 3 * s, y + shelf_h - bh + 12 * s)], fill=(200, 170, 90), width=2)
            x += bw + rng.uniform(0, 4) * s
        y += shelf_h
        d.rectangle([x0, y - 6 * s, x1, y + 8 * s], fill=wood, outline=dark, width=2)
    d.rectangle([x0, y0, x1, y1], outline=dark, width=int(10 * s))


def _column(d, x, y_top, y_bot, w, color=(232, 225, 210)):
    shade = _darker(color, 0.82)
    d.rectangle([x - w / 2, y_top + 40, x + w / 2, y_bot - 30], fill=color)
    for k in range(1, 6):
        fx = x - w / 2 + k * w / 6
        d.line([(fx, y_top + 45), (fx, y_bot - 35)], fill=shade, width=max(2, int(w / 40)))
    d.rectangle([x - w * 0.7, y_top, x + w * 0.7, y_top + 40], fill=color, outline=shade, width=3)
    d.ellipse([x - w * 0.8, y_top + 5, x - w * 0.45, y_top + 38], fill=color, outline=shade, width=3)
    d.ellipse([x + w * 0.45, y_top + 5, x + w * 0.8, y_top + 38], fill=color, outline=shade, width=3)
    d.rectangle([x - w * 0.65, y_bot - 30, x + w * 0.65, y_bot], fill=color, outline=shade, width=3)


def build_academia(kind, F):
    W, H, sc = F["w"], F["h"], F["sc"]
    S = slots(F)
    fl, s = S["floor"], S["s"]
    img = Image.new("RGB", (W, H), (235, 225, 205))
    d = ImageDraw.Draw(img)
    if kind == "library":
        _vgrad(d, (0, 0, W, fl), (70, 50, 40), (95, 68, 50))
        if H > W:
            _bookshelf(d, -20, 360 * sc, W * 0.36, fl, 1, sc)
            _bookshelf(d, W * 0.64, 360 * sc, W + 20, fl, 2, sc)
        else:
            _bookshelf(d, -20, 80, W * 0.26, fl, 1, sc)
            _bookshelf(d, W * 0.74, 80, W + 20, fl, 2, sc)
        d.rectangle([0, fl, W, H], fill=(120, 40, 40))  # halı
        for y in range(int(fl) + 30, H, 46):
            d.line([(0, y), (W, y)], fill=(140, 55, 50), width=4)
        d.rectangle([0, fl - 8, W, fl + 10], fill=(90, 58, 38))
    elif kind == "study":
        _vgrad(d, (0, 0, W, fl), (60, 78, 70), (78, 98, 86))  # koyu yeşil duvar
        for x in range(0, W, 120):
            d.line([(x, 0), (x, fl)], fill=(70, 90, 80), width=3)
        d.rectangle([0, fl, W, H], fill=(100, 66, 44))
        for i, y in enumerate(range(int(fl) + 50, H, 64)):
            d.line([(0, y), (W, y)], fill=(85, 55, 36), width=3)
        lx, ly = S["left_low"]
        # masa + mum + küre
        d.rectangle([lx - 120 * s, ly - 230 * s, lx + 170 * s, ly - 205 * s], fill=(120, 78, 50), outline=(70, 45, 30), width=4)
        d.line([(lx - 100 * s, ly - 205 * s), (lx - 100 * s, ly)], fill=(70, 45, 30), width=int(14 * s))
        d.line([(lx + 150 * s, ly - 205 * s), (lx + 150 * s, ly)], fill=(70, 45, 30), width=int(14 * s))
        gx, gy = lx + 60 * s, ly - 300 * s
        d.ellipse([gx - 60 * s, gy - 60 * s, gx + 60 * s, gy + 60 * s], fill=(70, 120, 150), outline=(60, 45, 30), width=4)
        d.arc([gx - 75 * s, gy - 75 * s, gx + 75 * s, gy + 75 * s], 120, 420, fill=(190, 150, 70), width=int(6 * s))
        d.polygon([(gx - 30 * s, gy - 20 * s), (gx + 10 * s, gy - 40 * s), (gx + 25 * s, gy + 10 * s), (gx - 10 * s, gy + 25 * s)],
                  fill=(150, 160, 100))
        d.line([(gx, gy + 75 * s), (gx, ly - 230 * s)], fill=(60, 45, 30), width=int(8 * s))
        rx, ry = S["right_high"]
        # çerçeveli harita
        d.rectangle([rx - 130 * s, ry - 100 * s, rx + 130 * s, ry + 100 * s], fill=(225, 205, 160), outline=(110, 75, 40), width=int(12 * s))
        rng = random.Random(4)
        for _ in range(4):
            cx_, cy_ = rx + rng.uniform(-80, 80) * s, ry + rng.uniform(-50, 50) * s
            d.ellipse([cx_ - 35 * s, cy_ - 22 * s, cx_ + 35 * s, cy_ + 22 * s], outline=(140, 110, 70), width=3)
        hx, hy = S["left_high"]
        _bookshelf(d, hx - 120 * s, hy - 60 * s, hx + 120 * s, hy + 100 * s, 7, sc * 0.6)
    elif kind == "agora":
        _vgrad(d, (0, 0, W, fl), (120, 170, 215), (235, 225, 200))
        # uzak tepeler ve tapınak
        d.ellipse([-W * 0.3, fl - 260 * sc, W * 0.7, fl + 300 * sc], fill=(170, 175, 140))
        d.ellipse([W * 0.4, fl - 200 * sc, W * 1.3, fl + 300 * sc], fill=(155, 165, 130))
        tx = W * (0.8 if H > W else 0.85)
        tw = 300 * sc
        d.polygon([(tx - tw / 2 - 20, fl - 300 * sc), (tx, fl - 380 * sc), (tx + tw / 2 + 20, fl - 300 * sc)], fill=(225, 218, 200),
                  outline=(180, 170, 150), width=3)
        for k in range(5):
            _column(d, tx - tw / 2 + 25 + k * (tw - 50) / 4, fl - 300 * sc, fl - 150 * sc, 22 * sc)
        d.rectangle([0, fl - 150 * sc, W, fl], fill=(200, 190, 165))
        d.rectangle([0, fl, W, H], fill=(215, 200, 170))
        for x in range(0, W, 140):
            d.line([(x, fl), (x - 60, H)], fill=(195, 180, 150), width=3)
        for y in range(int(fl) + 60, H, 80):
            d.line([(0, y), (W, y)], fill=(195, 180, 150), width=3)
        lx = S["left_low"][0]
        rx = S["right_low"][0]
        _column(d, lx, fl - 720 * s, fl, 90 * s)
        _column(d, rx, fl - 720 * s, fl, 90 * s)
        # zeytin dalı
        ox, oy = W * 0.5, fl - 150 * sc
    elif kind == "parchment":
        d.rectangle([0, 0, W, H], fill=(232, 212, 170))
        arr = np.asarray(img).astype(np.int16)
        rng = np.random.default_rng(3)
        from PIL import ImageFilter
        blot = Image.fromarray((rng.random((H // 40 + 1, W // 40 + 1)) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
        blot = blot.filter(ImageFilter.GaussianBlur(40))
        b = np.asarray(blot).astype(np.int16)[..., None]
        arr = arr - ((b - 128) * 0.12).astype(np.int16) - np.array([0, 4, 10], dtype=np.int16)
        img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
        d = ImageDraw.Draw(img)
        # harita çizgileri, pusula
        rr = random.Random(9)
        for _ in range(6):
            x0, y0 = rr.uniform(0, W), rr.uniform(0, H)
            pts = [(x0 + k * 40 * sc, y0 + 30 * sc * math.sin(k * 0.7 + rr.random())) for k in range(14)]
            d.line(pts, fill=(170, 140, 100), width=3, joint="curve")
        cx_, cy_ = W * 0.82, H * (0.88 if H > W else 0.8)
        r = 80 * sc
        d.ellipse([cx_ - r, cy_ - r, cx_ + r, cy_ + r], outline=(140, 100, 60), width=4)
        for a in range(4):
            ang = a * math.pi / 2
            d.polygon([(cx_ + math.cos(ang) * r * 1.2, cy_ + math.sin(ang) * r * 1.2),
                       (cx_ + math.cos(ang + 0.5) * r * 0.25, cy_ + math.sin(ang + 0.5) * r * 0.25),
                       (cx_ + math.cos(ang - 0.5) * r * 0.25, cy_ + math.sin(ang - 0.5) * r * 0.25)], fill=(140, 100, 60))
        d.line([(F["fig_x"] - 320 * sc, fl), (F["fig_x"] + 320 * sc, fl)], fill=(150, 115, 80), width=int(6 * sc))
    elif kind == "night":
        _vgrad(d, (0, 0, W, H), (20, 25, 50), (60, 50, 80))
        rng = random.Random(2)
        for _ in range(int(W * H / 9000)):
            x, y = rng.uniform(0, W), rng.uniform(0, fl)
            r = rng.choice([1, 1, 2, 3])
            d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 250, 220))
        d.ellipse([W * 0.75, H * 0.08, W * 0.75 + 130 * sc, H * 0.08 + 130 * sc], fill=(245, 235, 200))
        d.rectangle([0, fl, W, H], fill=(40, 40, 55))
    return _vignette(_grain(img, 5))


ACADEMIA_BGS = ("library", "study", "agora", "parchment", "night")
_orig_build = build_static


def build_static(kind, F):  # noqa: F811
    if kind in ACADEMIA_BGS:
        return build_academia(kind, F)
    return _orig_build(kind, F)
