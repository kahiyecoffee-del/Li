"""Eskiz motoru: anlatılan sahneyi kâğıda karakalemle çizer ve çizilirken gösterir.

Bir sahne, öğelerden oluşur (JSON):
    {"el": "figure", "x": 0.3, "y": 0.85, "h": 0.55, "pose": "kick", "face": 1, "at": 0.0}
    {"el": "chair", "x": 0.5, "y": 0.8, "s": 1.0}
    {"el": "cross", "x": 0.5, "y": 0.6, "s": 1.0, "at": 1.5}          # kırmızı kalemle üstünü çiz
    {"el": "text", "x": 0.5, "y": 0.2, "text": "SOLIPSISM", "size": 1.2}
x, y: kare içinde oran (0..1). s / h: genişliğe göre ölçek. at: çizime başlama saniyesi.

Her öğe kalem darbelerine (Stroke), gölge alanlarına (Fill) ve yazılara (Text) dönüşür.
Darbeler sırayla, uçtan uca çizilir; dolgular taranarak belirir; kalem ucu çizgiyi takip eder.
"""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import karakalem as kk

INK = (44, 42, 46)
RED = (176, 48, 38)
BLUE = (48, 86, 168)
COLORS = {"ink": INK, "red": RED, "blue": BLUE, "gold": (190, 140, 50), "grey": (120, 118, 122)}


# --------------------------------------------------------------------------- #
# Temel öğeler
# --------------------------------------------------------------------------- #
class Stroke:
    def __init__(self, pts, w=4.0, color=INK, passes=2, seed=0):
        pts = [(float(x), float(y)) for x, y in pts]
        if len(pts) >= 2:  # eskiz gibi uçlar hafif taşsın
            (ax, ay), (bx, by) = pts[0], pts[1]
            (cx, cy), (dx, dy) = pts[-2], pts[-1]
            la = math.hypot(bx - ax, by - ay) or 1
            lb = math.hypot(dx - cx, dy - cy) or 1
            o = w * 1.6
            pts = [(ax - (bx - ax) / la * o, ay - (by - ay) / la * o)] + pts + [(dx + (dx - cx) / lb * o, dy + (dy - cy) / lb * o)]
        self.pts = pts
        self.w, self.color, self.passes, self.seed = w * 1.45, color, max(passes, 3), seed
        L = 0.0
        self.cum = [0.0]
        for a, b in zip(self.pts, self.pts[1:]):
            L += math.hypot(b[0] - a[0], b[1] - a[1])
            self.cum.append(L)
        self.length = max(L, 1.0)

    def weight(self):
        return 0.15 + self.length / 900

    def tip(self, u):
        return self._partial(u)[-1]

    def _partial(self, u):
        if u >= 1:
            return self.pts
        target = self.length * max(u, 0)
        out = [self.pts[0]]
        for i in range(1, len(self.pts)):
            if self.cum[i] <= target:
                out.append(self.pts[i])
            else:
                a, b = self.pts[i - 1], self.pts[i]
                seg = self.cum[i] - self.cum[i - 1]
                k = (target - self.cum[i - 1]) / seg if seg else 0
                out.append((a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k))
                break
        return out

    def draw(self, img, u=1.0):
        pts = self._partial(u)
        if len(pts) < 2:
            return
        d = ImageDraw.Draw(img, "RGBA")
        rng = random.Random(self.seed)
        for k in range(self.passes):
            j = self.w * (0.25 if k == 0 else 0.7)
            q = [(x + rng.uniform(-j, j), y + rng.uniform(-j, j)) for x, y in pts]
            a = (230, 110, 70)[min(k, 2)]
            wd = self.w * (1.0, 0.5, 0.35)[min(k, 2)]
            d.line(q, fill=(*self.color, a), width=max(1, int(round(wd))), joint="curve")


class Fill:
    """Kömür dolgu (silüet) ya da tarama: bir maske + doku. Yukarıdan aşağı taranarak belirir."""

    def __init__(self, mask, origin, tone=0.85, style="charcoal", color=INK, seed=0, outline=True):
        self.mask = mask  # L görüntü (yerel)
        self.ox, self.oy = origin
        self.tone, self.style, self.color, self.seed, self.outline = tone, style, color, seed, outline
        m = np.asarray(mask, np.float32) / 255.0
        h, w = m.shape
        self.h, self.w = h, w
        rng = np.random.default_rng(seed)
        if style == "charcoal":
            n1 = kk._smooth_noise(w, h, max(4, w // 18), seed) - 0.5
            n2 = rng.normal(0, 1, (h, w)).astype(np.float32)
            a = np.clip(tone + n1 * 0.18 + n2 * 0.05, 0, 1)
            # ışık kenarı: sol üstte hafif açık
            yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
            a *= 1 - 0.18 * np.clip(1 - (xx / max(w, 1) + yy / max(h, 1)), 0, 1)
        else:  # hatch
            ang = math.radians(rng.uniform(35, 55))
            yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
            sp = 9.0
            wob = (kk._smooth_noise(w, h, 30, seed) - 0.5) * 6
            dd = (xx * math.cos(ang) + yy * math.sin(ang) + wob) % sp
            a = np.clip(1 - np.abs(dd - sp / 2) / 1.3, 0, 1) * tone
        self.alpha = a * m
        if outline:
            mx = np.asarray(mask.filter(ImageFilter.MaxFilter(5)), np.float32) / 255
            mn = np.asarray(mask.filter(ImageFilter.MinFilter(3)), np.float32) / 255
            ring = np.clip(mx - mn, 0, 1) * (0.7 + 0.3 * (kk._smooth_noise(w, h, 8, seed + 1)))
            self.alpha = np.maximum(self.alpha, ring * 0.95)
        self.order = (np.mgrid[0:h, 0:w][0].astype(np.float32) / max(h, 1)) * 0.8 + kk._smooth_noise(w, h, 40, seed + 2) * 0.2

    def weight(self):
        return 0.4 + (self.w * self.h) / 400000

    def tip(self, u):
        return (self.ox + self.w * (0.2 + 0.6 * ((u * 7) % 1)), self.oy + self.h * min(1, u))

    def draw(self, img, u=1.0):
        a = self.alpha if u >= 1 else self.alpha * np.clip((u * 1.15 - self.order) / 0.1, 0, 1)
        W, H = img.size
        x0, y0 = int(self.ox), int(self.oy)
        x1, y1 = min(W, x0 + self.w), min(H, y0 + self.h)
        if x1 <= max(x0, 0) or y1 <= max(y0, 0):
            return
        sx, sy = max(0, -x0), max(0, -y0)
        a = a[sy:sy + (y1 - max(y0, 0)), sx:sx + (x1 - max(x0, 0))]
        reg = np.asarray(img.crop((max(x0, 0), max(y0, 0), x1, y1)), np.float32)
        col = np.array(self.color, np.float32)
        out = reg * (1 - a[..., None]) + col * a[..., None]
        img.paste(Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)), (max(x0, 0), max(y0, 0)))


_FONT = {}


def hand_font(size):
    import os
    size = int(size)
    if size not in _FONT:
        p = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "fonts", "Kalam-Bold.ttf")
        _FONT[size] = ImageFont.truetype(p, size)
    return _FONT[size]


class Text:
    def __init__(self, text, x, y, size, color=INK, anchor="mm"):
        self.text, self.x, self.y, self.size, self.color, self.anchor = text, x, y, size, color, anchor
        f = hand_font(size)
        b = ImageDraw.Draw(Image.new("L", (4, 4))).textbbox((x, y), text, font=f, anchor=anchor)
        self.box = b

    def weight(self):
        return 0.2 + len(self.text) * 0.05

    def tip(self, u):
        x0, y0, x1, y1 = self.box
        return (x0 + (x1 - x0) * min(u, 1), y1)

    def draw(self, img, u=1.0):
        x0, y0, x1, y1 = self.box
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).text((self.x, self.y), self.text, font=hand_font(self.size), fill=(*self.color, 235),
                                   anchor=self.anchor)
        if u < 1:
            cut = x0 + (x1 - x0) * u
            ImageDraw.Draw(layer).rectangle([cut, 0, img.size[0], img.size[1]], fill=(0, 0, 0, 0))
        img.paste(layer, (0, 0), layer)


# --------------------------------------------------------------------------- #
# Yardımcılar
# --------------------------------------------------------------------------- #
def wobble(pts, amt, seed):
    rng = random.Random(seed)
    return [(x + rng.uniform(-amt, amt), y + rng.uniform(-amt, amt)) for x, y in pts]


def ellipse_pts(cx, cy, rx, ry, n=48, start=0.0, extra=0.08, seed=0):
    rng = random.Random(seed)
    out = []
    for i in range(n + int(n * extra) + 1):
        u = start + 2 * math.pi * i / n
        w = 1 + 0.03 * math.sin(u * 3 + rng.random())
        out.append((cx + math.cos(u) * rx * w, cy + math.sin(u) * ry * w))
    return out


def bez(p0, p1, p2, n=20):
    return [((1 - u) ** 2 * p0[0] + 2 * (1 - u) * u * p1[0] + u * u * p2[0],
             (1 - u) ** 2 * p0[1] + 2 * (1 - u) * u * p1[1] + u * u * p2[1]) for u in (i / n for i in range(n + 1))]


def mask_from(draw_fn, box, ss=2, smooth=0.0):
    x0, y0, x1, y1 = [int(v) for v in box]
    w, h = max(2, x1 - x0), max(2, y1 - y0)
    m = Image.new("L", (w * ss, h * ss), 0)
    draw_fn(ImageDraw.Draw(m), lambda p: ((p[0] - x0) * ss, (p[1] - y0) * ss), ss)
    if smooth:  # eklem yerlerini yuvarla, organik kontur
        m = m.filter(ImageFilter.GaussianBlur(smooth * ss)).point(lambda v: 255 if v > 118 else 0)
        m = m.filter(ImageFilter.GaussianBlur(1.2 * ss))
    return m.resize((w, h), Image.LANCZOS), (x0, y0)


# --------------------------------------------------------------------------- #
# Silüet insan figürü
# --------------------------------------------------------------------------- #
POSES = {
    "stand": dict(la1=-8, la2=-4, ra1=8, ra2=4, ll1=-4, ll2=-2, rl1=4, rl2=2),
    "walk": dict(la1=-22, la2=-30, ra1=20, ra2=10, ll1=-20, ll2=-8, rl1=22, rl2=6),
    "kick": dict(la1=-35, la2=-60, ra1=-40, ra2=-20, ll1=-8, ll2=-4, rl1=75, rl2=70, lean=-6),
    "think": dict(la1=-10, la2=-6, ra1=40, ra2=-150, ll1=-4, ll2=-2, rl1=4, rl2=2),
    "point": dict(la1=-8, la2=-4, ra1=80, ra2=85, ll1=-6, ll2=-3, rl1=6, rl2=3),
    "shrug": dict(la1=-40, la2=-110, ra1=40, ra2=110, ll1=-4, ll2=-2, rl1=4, rl2=2),
    "sit": dict(la1=10, la2=60, ra1=20, ra2=70, ll1=88, ll2=0, rl1=92, rl2=0, sit=True),
    "lie": dict(la1=-6, la2=-4, ra1=6, ra2=4, ll1=-3, ll2=-2, rl1=3, rl2=2, rot=-90),
    "sitbed": dict(la1=-30, la2=-10, ra1=30, ra2=60, ll1=90, ll2=90, rl1=92, rl2=92, sit=True),
    "climb": dict(la1=150, la2=170, ra1=120, ra2=150, ll1=40, ll2=-10, rl1=-5, rl2=-5),
    "reach": dict(la1=-8, la2=-4, ra1=120, ra2=130, ll1=-4, ll2=-2, rl1=4, rl2=2),
    "hold": dict(la1=-10, la2=-6, ra1=25, ra2=80, ll1=-4, ll2=-2, rl1=4, rl2=2),
    "sleep_head": dict(la1=-6, la2=-4, ra1=6, ra2=4, ll1=-3, ll2=-2, rl1=3, rl2=2),
}


def _limb(start, a1, a2, l1, l2, flip):
    a1, a2 = (-a1, -a2) if flip else (a1, a2)
    e = (start[0] + math.sin(math.radians(a1)) * l1, start[1] + math.cos(math.radians(a1)) * l1)
    h = (e[0] + math.sin(math.radians(a2)) * l2, e[1] + math.cos(math.radians(a2)) * l2)
    return e, h


def figure(x, y, h, pose="stand", face=1, child=False, hat=None, tone=0.88, seed=0, W=1920):
    """Ayakları (x, y) noktasında, yüksekliği h piksel olan kömür silüet. face: 1 sağa, -1 sola bakar."""
    P = dict(POSES.get(pose, POSES["stand"]))
    flip = face < 0
    head_r = h * (0.095 if child else 0.072)
    hip_y = y - h * (0.42 if child else 0.47)
    if P.get("sit"):
        hip_y = y - h * 0.27
    sh_y = y - h * (0.74 if child else 0.79)
    if P.get("sit"):
        sh_y = hip_y - h * 0.32
    lean = math.radians(P.get("lean", 0)) * (-1 if flip else 1)
    neck = (x + (hip_y - sh_y) * math.sin(lean), sh_y)
    head_c = (neck[0] + h * 0.01 * face, sh_y - head_r * 1.25)
    thigh, shin = h * 0.24, h * 0.23
    ua, fa = h * 0.17, h * 0.16
    lw, aw = h * 0.058, h * 0.052
    parts = []  # (tip, data)

    def draw(dr, T, ss):
        # bacaklar
        for side, a1, a2 in ((-1, P["ll1"], P["ll2"]), (1, P["rl1"], P["rl2"])):
            hp = (x + side * h * 0.045, hip_y)
            k, f = _limb(hp, a1, a2, thigh, shin, flip)
            dr.line([T(hp), T(k), T(f)], fill=255, width=int(lw * ss), joint="curve")
            for q in (k, f):
                r = lw / 2 * ss
                qq = T(q)
                dr.ellipse([qq[0] - r, qq[1] - r, qq[0] + r, qq[1] + r], fill=255)
            fo = T((f[0] + face * h * 0.035, f[1] + lw * 0.2))
            dr.ellipse([fo[0] - h * 0.05 * ss, fo[1] - h * 0.022 * ss, fo[0] + h * 0.05 * ss, fo[1] + h * 0.02 * ss], fill=255)
        # gövde (ceket)
        sw, hw = h * 0.11, h * 0.09
        torso = [(neck[0] - sw, sh_y + h * 0.02), (neck[0] + sw, sh_y + h * 0.02), (x + hw, hip_y + h * 0.04),
                 (x - hw, hip_y + h * 0.04)]
        dr.polygon([T(p) for p in torso], fill=255)
        for p in (torso[0], torso[1]):  # yuvarlak omuz
            r = h * 0.045 * ss
            pp = T((p[0] + (neck[0] - p[0]) * 0.25, p[1] + h * 0.025))
            dr.ellipse([pp[0] - r, pp[1] - r, pp[0] + r, pp[1] + r], fill=255)
        if not P.get("sit") and not child:  # ceket eteği
            dr.polygon([T((x - hw * 0.95, hip_y)), T((x + hw * 0.95, hip_y)), T((x + hw * 1.15, hip_y + h * 0.12)),
                        T((x - hw * 1.15, hip_y + h * 0.12))], fill=255)
        # boyun + baş
        dr.line([T(neck), T((head_c[0], head_c[1] + head_r * 0.6))], fill=255, width=int(h * 0.03 * ss))
        hc = T(head_c)
        rr = head_r * ss
        dr.ellipse([hc[0] - rr * 0.92, hc[1] - rr, hc[0] + rr * 0.92, hc[1] + rr], fill=255)
        nose = T((head_c[0] + face * head_r * 0.95, head_c[1] + head_r * 0.15))
        dr.polygon([T((head_c[0] + face * head_r * 0.7, head_c[1] - head_r * 0.1)), nose,
                    T((head_c[0] + face * head_r * 0.7, head_c[1] + head_r * 0.35))], fill=255)
        if hat == "tricorn":
            dr.polygon([T((head_c[0] - head_r * 1.5, head_c[1] - head_r * 0.6)), T((head_c[0] + head_r * 1.5, head_c[1] - head_r * 0.6)),
                        T((head_c[0], head_c[1] - head_r * 1.7))], fill=255)
        elif hat == "wig":
            dr.ellipse([hc[0] - rr * 1.2, hc[1] - rr * 1.1, hc[0] + rr * 1.15, hc[1] + rr * 0.9], fill=255)
        elif hat == "bun":
            dr.ellipse([hc[0] - rr * 0.5 - face * rr * 0.9, hc[1] - rr * 1.3, hc[0] + rr * 0.5 - face * rr * 0.9, hc[1] - rr * 0.4],
                       fill=255)
        elif hat == "dress":
            sk = [T((x - h * 0.08, hip_y - h * 0.05)), T((x + h * 0.08, hip_y - h * 0.05)), T((x + h * 0.17, y - h * 0.08)),
                  T((x - h * 0.17, y - h * 0.08))]
            dr.polygon(sk, fill=255)
        # kollar
        for side, a1, a2 in ((-1, P["la1"], P["la2"]), (1, P["ra1"], P["ra2"])):
            s0 = (neck[0] + side * h * 0.1, sh_y + h * 0.03)
            e, hd = _limb(s0, a1, a2, ua, fa, flip)
            dr.line([T(s0), T(e), T(hd)], fill=255, width=int(aw * ss), joint="curve")
            for q in (e, hd):
                r = aw / 2 * ss * (1.25 if q is hd else 1)
                qq = T(q)
                dr.ellipse([qq[0] - r, qq[1] - r, qq[0] + r, qq[1] + r], fill=255)
            parts.append(hd)

    box = (x - h * 0.75, y - h * 1.25, x + h * 0.75, y + h * 0.1)
    m, o = mask_from(draw, box, smooth=h * 0.018)
    rot = P.get("rot")
    if rot:  # yatan figür: ayak noktası etrafında döndür
        m = m.rotate(rot * (-1 if flip else 1), resample=Image.BICUBIC, expand=False, center=(x - o[0], y - o[1] - h * 0.5))
        o = (o[0], o[1] + h * 0.45)
    items = []
    if not rot:  # zemin gölgesi (taranmış)
        gm, go = mask_from(lambda d, T, ss: d.ellipse([T((x - h * 0.22, y - h * 0.018)), T((x + h * 0.26, y + h * 0.022))], fill=255),
                           (x - h * 0.24, y - h * 0.03, x + h * 0.28, y + h * 0.03))
        items.append(Fill(gm, go, tone=0.5, style="hatch", seed=seed + 50, outline=False))
    items.append(Fill(m, o, tone=tone, seed=seed))
    return items, {"hand_l": parts[0] if parts else (x, y), "hand_r": parts[1] if len(parts) > 1 else (x, y),
                   "head": head_c, "head_r": head_r}


# --------------------------------------------------------------------------- #
# Eşyalar ve semboller (kalem çizgileri)
# --------------------------------------------------------------------------- #
PROFILE = [(-0.25, 0.95), (-0.3, 0.62), (-0.46, 0.34), (-0.55, 0.02), (-0.52, -0.28), (-0.38, -0.52), (-0.12, -0.63),
           (0.14, -0.61), (0.34, -0.5), (0.45, -0.31), (0.47, -0.14), (0.43, -0.06), (0.5, 0.05), (0.63, 0.18), (0.51, 0.22),
           (0.53, 0.28), (0.47, 0.32), (0.51, 0.37), (0.44, 0.43), (0.47, 0.51), (0.38, 0.59), (0.16, 0.62), (0.16, 0.95)]


def el_head(x, y, s, face=1, glow=False, lock=False, tone=0.9, seed=0, **_):
    """Profilden kömür baş silüeti (zihin). glow: içinde altın ışık; lock: asma kilit."""
    r = 330 * s
    pts = [(x + px * r * face, y + py * r) for px, py in PROFILE]
    m, o = mask_from(lambda d, T, ss: d.polygon([T(p) for p in pts], fill=255), (x - r * 0.7, y - r * 0.7, x + r * 0.7, y + r),
                     smooth=r * 0.012)
    items = [Fill(m, o, tone=tone, seed=seed)]
    cx, cy = x - 0.05 * r * face, y - 0.15 * r
    if glow:
        gm, go = mask_from(lambda d, T, ss: d.ellipse([T((cx - r * 0.2, cy - r * 0.2)), T((cx + r * 0.2, cy + r * 0.2))], fill=255),
                           (cx - r * 0.3, cy - r * 0.3, cx + r * 0.3, cy + r * 0.3), smooth=r * 0.05)
        items.append(Fill(gm, go, tone=0.95, color=(245, 205, 110), seed=seed + 1, outline=False))
        for k in range(10):
            a = k * math.pi / 5
            items.append(Stroke([(cx + math.cos(a) * r * 0.25, cy + math.sin(a) * r * 0.25),
                                 (cx + math.cos(a) * r * 0.36, cy + math.sin(a) * r * 0.36)], 3 * s + 1, (245, 205, 110), seed=seed + k))
    if lock:
        lx, ly = cx, cy
        items.append(Stroke(bez((lx - r * 0.1, ly), (lx, ly - r * 0.3), (lx + r * 0.1, ly)), 7 * s + 2, (238, 232, 218), seed=seed + 3))
        lm, lo = mask_from(lambda d, T, ss: d.rounded_rectangle([T((lx - r * 0.16, ly)), T((lx + r * 0.16, ly + r * 0.24))],
                                                                radius=int(r * 0.03 * ss), fill=255),
                           (lx - r * 0.16, ly, lx + r * 0.16, ly + r * 0.24))
        items.append(Fill(lm, lo, tone=0.95, color=(238, 232, 218), seed=seed, outline=False))
    return items


def el_chair(x, y, s, seed=0, **_):
    w, h = 160 * s, 320 * s
    pts = [[(x - w / 2, y), (x - w / 2, y - h)], [(x - w / 2, y - h * 0.5), (x + w / 2, y - h * 0.5)],
           [(x + w / 2, y - h * 0.5), (x + w / 2, y)], [(x - w / 2, y - h), (x - w / 2 + w * 0.15, y - h * 0.5)],
           [(x - w / 2 + 10 * s, y - h * 0.92), (x - w / 2 + 10 * s, y - h * 0.58)],
           [(x - w / 2 - 6 * s, y - h * 0.47), (x + w / 2 + 6 * s, y - h * 0.47)]]
    return [Stroke(wobble(p, 2, seed + i), 5 * s + 1, seed=seed + i) for i, p in enumerate(pts)]


def el_screen(x, y, s, seed=0, **_):
    w, h = 340 * s, 220 * s
    out = [Stroke([(x - w / 2, y - h), (x + w / 2, y - h), (x + w / 2, y), (x - w / 2, y), (x - w / 2, y - h)], 6 * s + 1, seed=seed),
           Stroke([(x - w / 2 + 16 * s, y - h + 16 * s), (x + w / 2 - 16 * s, y - h + 16 * s), (x + w / 2 - 16 * s, y - 16 * s),
                   (x - w / 2 + 16 * s, y - 16 * s), (x - w / 2 + 16 * s, y - h + 16 * s)], 3 * s + 1, seed=seed + 1),
           Stroke([(x, y), (x, y + 50 * s)], 7 * s + 1, seed=seed + 2),
           Stroke([(x - 70 * s, y + 52 * s), (x + 70 * s, y + 52 * s)], 7 * s + 1, seed=seed + 3)]
    for k in range(3):
        yy = y - h + 50 * s + k * 40 * s
        out.append(Stroke([(x - w / 2 + 40 * s, yy), (x + w / 2 - 60 * s - k * 30 * s, yy)], 3 * s, COLORS["grey"], 1, seed + 5 + k))
    return out


def el_cross(x, y, s, color="red", seed=0, **_):
    c = COLORS.get(color, RED)
    r = 140 * s
    return [Stroke(wobble([(x - r, y - r), (x, y), (x + r, y + r)], 3, seed), 9 * s + 2, c, seed=seed),
            Stroke(wobble([(x + r, y - r * 0.9), (x, y), (x - r * 0.95, y + r)], 3, seed + 1), 9 * s + 2, c, seed=seed + 1)]


def el_circle(x, y, s, rx=None, ry=None, color="red", seed=0, **_):
    c = COLORS.get(color, RED)
    return [Stroke(ellipse_pts(x, y, (rx or 150) * s, (ry or 90) * s, start=-0.6, extra=0.15, seed=seed), 6 * s + 2, c, seed=seed)]


def el_arrow(x, y, s, x2=None, y2=None, bend=0.2, color="ink", seed=0, W=1920, H=1080, **_):
    c = COLORS.get(color, INK)
    a, b = (x, y), (x2 * W, y2 * H)
    mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    nx, ny = -(b[1] - a[1]), b[0] - a[0]
    pts = bez(a, (mx + nx * bend, my + ny * bend), b)
    ang = math.atan2(b[1] - pts[-3][1], b[0] - pts[-3][0])
    L = 26 * s + 10
    head = [(b[0] - L * math.cos(ang + 0.5), b[1] - L * math.sin(ang + 0.5)), b,
            (b[0] - L * math.cos(ang - 0.5), b[1] - L * math.sin(ang - 0.5))]
    return [Stroke(pts, 5 * s + 1, c, seed=seed), Stroke(head, 5 * s + 1, c, seed=seed + 1)]


def el_text(x, y, s, text="", size=1.0, color="ink", underline=False, seed=0, **_):
    c = COLORS.get(color, INK)
    t = Text(text, x, y, 80 * size * s, c)
    out = [t]
    if underline:
        x0, y0, x1, y1 = t.box
        out.append(Stroke(wobble([(x0, y1 + 10), ((x0 + x1) / 2, y1 + 16), (x1, y1 + 8)], 3, seed), 6 * s + 2,
                          COLORS.get(underline if isinstance(underline, str) else "red", RED), seed=seed))
    return out


def el_bubble(x, y, s, rx=1.0, ry=1.0, kind="thought", tail=None, seed=0, W=1920, H=1080, **_):
    """Düşünce balonu (bulut) ya da konuşma balonu. tail: [x, y] oran olarak kuyruk ucu."""
    RX, RY = 260 * s * rx, 170 * s * ry
    out = []
    if kind == "thought":
        n = 9
        pts = []
        for i in range(n):
            a0 = 2 * math.pi * i / n
            a1 = 2 * math.pi * (i + 1) / n
            p0 = (x + math.cos(a0) * RX, y + math.sin(a0) * RY)
            p1 = (x + math.cos(a1) * RX, y + math.sin(a1) * RY)
            mid = ((a0 + a1) / 2)
            c = (x + math.cos(mid) * RX * 1.28, y + math.sin(mid) * RY * 1.28)
            pts += bez(p0, c, p1, 8)[:-1]
        pts.append(pts[0])
        out.append(Stroke(pts, 5 * s + 1, seed=seed))
        if tail:
            tx, ty = tail[0] * W, tail[1] * H
            for k, rr in enumerate((26, 17, 10)):
                u = 0.45 + k * 0.22
                cx, cy = x + (tx - x) * u, y + RY * 0.9 + (ty - y - RY * 0.9) * u
                out.append(Stroke(ellipse_pts(cx, cy, rr * s, rr * s * 0.8, n=20, seed=seed + k), 4 * s + 1, seed=seed + k))
    else:
        out.append(Stroke(ellipse_pts(x, y, RX, RY, seed=seed), 5 * s + 1, seed=seed))
        if tail:
            tx, ty = tail[0] * W, tail[1] * H
            out.append(Stroke([(x - RX * 0.2, y + RY * 0.9), (tx, ty), (x + RX * 0.1, y + RY * 0.97)], 5 * s + 1, seed=seed + 1))
    return out


def el_butterfly(x, y, s, seed=0, **_):
    out = []
    for side in (-1, 1):
        up = bez((x, y - 5 * s), (x + side * 170 * s, y - 190 * s), (x + side * 120 * s, y + 10 * s), 18)
        low = bez((x, y + 5 * s), (x + side * 120 * s, y + 140 * s), (x + side * 30 * s, y + 40 * s), 14)
        out.append(Stroke(up, 4 * s + 1, seed=seed + side))
        out.append(Stroke(low, 4 * s + 1, seed=seed + side * 2))
        out.append(Stroke(ellipse_pts(x + side * 85 * s, y - 70 * s, 25 * s, 18 * s, n=18, seed=seed), 3 * s + 1, seed=seed))
    m, o = mask_from(lambda d, T, ss: d.ellipse([T((x - 10 * s, y - 60 * s)), T((x + 10 * s, y + 60 * s))], fill=255),
                     (x - 12 * s, y - 62 * s, x + 12 * s, y + 62 * s))
    out.append(Fill(m, o, tone=0.9, seed=seed))
    out.append(Stroke(bez((x, y - 58 * s), (x - 10 * s, y - 110 * s), (x - 50 * s, y - 120 * s), 8), 3 * s + 1, seed=seed))
    out.append(Stroke(bez((x, y - 58 * s), (x + 10 * s, y - 110 * s), (x + 50 * s, y - 120 * s), 8), 3 * s + 1, seed=seed + 1))
    return out


def el_stairs(x, y, s, n=3, labels=None, seed=0, **_):
    """Soldan sağa yükselen basamaklar (x, y = sol alt köşe)."""
    sw, sh = 230 * s, 110 * s
    pts = [(x, y)]
    for i in range(n):
        pts += [(x + i * sw, y - (i + 1) * sh), (x + (i + 1) * sw, y - (i + 1) * sh)]
    pts += [(x + n * sw, y)]
    out = [Stroke(wobble(pts, 2, seed), 6 * s + 1, seed=seed), Stroke([(x, y), (x + n * sw, y)], 6 * s + 1, seed=seed + 1)]
    for i, lab in enumerate(labels or []):
        out.append(Text(f"{i + 1}. {lab}", x + i * sw + sw / 2, y - (i + 1) * sh - 34 * s, 34 * s, INK))
    return out


def el_padlock(x, y, s, seed=0, **_):
    out = [Stroke(bez((x - 45 * s, y), (x, y - 140 * s), (x + 45 * s, y)), 12 * s + 1, seed=seed)]
    m, o = mask_from(lambda d, T, ss: d.rounded_rectangle([T((x - 75 * s, y)), T((x + 75 * s, y + 110 * s))], radius=int(12 * s * ss),
                                                          fill=255), (x - 75 * s, y, x + 75 * s, y + 110 * s))
    out.append(Fill(m, o, tone=0.85, seed=seed))
    return out


def el_bed(x, y, s, seed=0, **_):
    w = 620 * s
    return [Stroke([(x - w / 2, y), (x - w / 2, y - 200 * s)], 7 * s + 1, seed=seed),
            Stroke([(x + w / 2, y), (x + w / 2, y - 120 * s)], 7 * s + 1, seed=seed + 1),
            Stroke(wobble([(x - w / 2, y - 70 * s), (x + w / 2, y - 70 * s)], 2, seed), 6 * s + 1, seed=seed + 2),
            Stroke(wobble([(x - w / 2, y - 110 * s), (x - w / 4, y - 128 * s), (x + w / 2, y - 112 * s)], 3, seed), 4 * s + 1,
                   seed=seed + 3),
            Stroke(ellipse_pts(x - w / 2 + 70 * s, y - 135 * s, 55 * s, 28 * s, n=24, seed=seed), 4 * s + 1, seed=seed + 4)]


def el_moon(x, y, s, seed=0, **_):
    r = 70 * s
    return [Stroke([(x + math.cos(u) * r, y + math.sin(u) * r) for u in np.linspace(0.6, 2 * math.pi - 0.6, 30)] +
                   [(x + math.cos(u) * r * 0.7 + r * 0.35, y + math.sin(u) * r * 0.75) for u in np.linspace(2 * math.pi - 0.9, 0.9, 24)],
                   5 * s + 1, seed=seed)] + [Stroke(ellipse_pts(x + dx * s, y + dy * s, 6 * s, 6 * s, n=10), 3, seed=seed + i)
                                              for i, (dx, dy) in enumerate(((-220, 40), (-140, -80), (160, 90)))]


def el_room(x, y, s, seed=0, **_):
    """İçinde kalınan kapalı oda (kutu) + anahtar deliği; dışarıda soru işaretleri."""
    w, h = 520 * s, 380 * s
    out = [Stroke([(x - w / 2, y - h), (x + w / 2, y - h), (x + w / 2, y), (x - w / 2, y), (x - w / 2, y - h)], 7 * s + 1, seed=seed),
           Stroke([(x - w / 2, y - h), (x - w / 2 + 70 * s, y - h - 60 * s), (x + w / 2 + 70 * s, y - h - 60 * s), (x + w / 2, y - h)],
                  5 * s + 1, seed=seed + 1),
           Stroke([(x + w / 2 + 70 * s, y - h - 60 * s), (x + w / 2 + 70 * s, y - 60 * s), (x + w / 2, y)], 5 * s + 1, seed=seed + 2)]
    for i, (dx, dy) in enumerate(((-w * 0.85, -h * 0.9), (w * 0.85, -h * 1.1), (-w * 0.75, -h * 0.2), (w * 0.9, -h * 0.3))):
        out.append(Text("?", x + dx, y + dy, 90 * s, INK))
    return out


def el_globe(x, y, s, seed=0, **_):
    r = 150 * s
    out = [Stroke(ellipse_pts(x, y, r, r, seed=seed), 5 * s + 1, seed=seed)]
    for k in (-0.5, 0, 0.5):
        out.append(Stroke([(x + math.cos(u) * r * math.sqrt(1 - k * k), y + k * r + math.sin(u) * r * 0.12)
                           for u in np.linspace(0, math.pi, 20)], 3 * s + 1, COLORS["grey"], 1, seed + 3))
    out.append(Stroke([(x + math.sin(u) * r * 0.45, y - math.cos(u) * r) for u in np.linspace(0, math.pi, 24)], 3 * s + 1,
                      COLORS["grey"], 1, seed + 4))
    land = [(x - r * 0.5, y - r * 0.3), (x - r * 0.1, y - r * 0.5), (x + r * 0.2, y - r * 0.2), (x + 0.1 * r, y + r * 0.2),
            (x - 0.3 * r, y + 0.1 * r)]
    m, o = mask_from(lambda d, T, ss: d.polygon([T(p) for p in land], fill=255), (x - r, y - r, x + r, y + r))
    out.append(Fill(m, o, tone=0.4, style="hatch", seed=seed, outline=True))
    return out


def el_stars(x, y, s, n=40, w=1.0, h=1.0, seed=0, W=1920, H=1080, **_):
    rng = random.Random(seed)
    out = []
    for i in range(n):
        cx, cy = rng.uniform(0.05, 0.95) * W * w + (1 - w) * W / 2, rng.uniform(0.05, 0.8) * H * h
        r = rng.uniform(4, 11) * s
        out.append(Stroke([(cx - r, cy), (cx + r, cy)], 2, INK, 1, seed + i))
        out.append(Stroke([(cx, cy - r), (cx, cy + r)], 2, INK, 1, seed + i + 99))
    return out


def el_dot(x, y, s, color="gold", seed=0, **_):
    c = COLORS.get(color, COLORS["gold"])
    r = 26 * s
    out = [Stroke(ellipse_pts(x, y, r, r, n=20, seed=seed), 5 * s + 1, c, seed=seed)]
    for k in range(8):
        a = k * math.pi / 4
        out.append(Stroke([(x + math.cos(a) * r * 1.5, y + math.sin(a) * r * 1.5), (x + math.cos(a) * r * 2.3, y + math.sin(a) * r * 2.3)],
                          3 * s + 1, c, 1, seed + k))
    return out


def el_scroll(x, y, s, seed=0, text=None, **_):
    w, h = 300 * s, 380 * s
    out = [Stroke(wobble([(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x + w / 2, y + h / 2), (x - w / 2, y + h / 2), (x - w / 2, y - h / 2)],
                         3, seed), 5 * s + 1, seed=seed)]
    for side in (-1, 1):
        out.append(Stroke(ellipse_pts(x - w / 2 - 10 * s, y + side * h / 2, 22 * s, 22 * s, n=16, seed=seed), 4 * s + 1, seed=seed))
        out.append(Stroke(ellipse_pts(x + w / 2 + 10 * s, y + side * h / 2, 22 * s, 22 * s, n=16, seed=seed + 1), 4 * s + 1, seed=seed))
    for k in range(6):
        yy = y - h / 2 + 60 * s + k * 50 * s
        out.append(Stroke(wobble([(x - w / 2 + 40 * s, yy), (x + w / 2 - 40 * s - (k % 2) * 60 * s, yy)], 2, seed + k), 3 * s, COLORS["grey"], 1,
                          seed + k))
    if text:
        out.append(Text(text, x, y - h / 2 - 50 * s, 46 * s, INK))
    return out


def el_letter(x, y, s, seed=0, lines=5, text=None, **_):
    w, h = 340 * s, 240 * s
    out = [Stroke(wobble([(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x + w / 2, y + h / 2), (x - w / 2, y + h / 2), (x - w / 2, y - h / 2)],
                         2, seed), 5 * s + 1, seed=seed),
           Stroke([(x - w / 2, y - h / 2), (x, y + 10 * s), (x + w / 2, y - h / 2)], 4 * s + 1, seed=seed + 1)]
    if text:
        out.append(Text(text, x, y + h / 2 + 50 * s, 44 * s, INK))
    return out


def el_child_panel(x, y, s, seed=0, **_):
    items, _a = figure(x, y, 300 * s, "stand", 1, child=True, seed=seed)
    return items + [Stroke(ellipse_pts(x - 120 * s, y - 380 * s, 70 * s, 50 * s, n=20, seed=seed), 4 * s + 1, seed=seed),
                    Text("?", x - 120 * s, y - 380 * s, 70 * s, INK)]


def el_hourglass(x, y, s, seed=0, **_):
    w, h = 170 * s, 300 * s
    return [Stroke([(x - w / 2, y - h / 2), (x + w / 2, y - h / 2)], 8 * s + 1, seed=seed),
            Stroke([(x - w / 2, y + h / 2), (x + w / 2, y + h / 2)], 8 * s + 1, seed=seed + 1),
            Stroke(bez((x - w * 0.42, y - h / 2), (x - w * 0.1, y), (x - w * 0.42, y + h / 2)), 4 * s + 1, seed=seed + 2),
            Stroke(bez((x + w * 0.42, y - h / 2), (x + w * 0.1, y), (x + w * 0.42, y + h / 2)), 4 * s + 1, seed=seed + 3),
            Stroke([(x, y), (x, y + h * 0.4)], 2, COLORS["grey"], 1, seed + 4)]


def el_line(x, y, s, x2=None, y2=None, color="ink", w=1.0, seed=0, W=1920, H=1080, **_):
    return [Stroke(wobble([(x, y), (x2 * W, y2 * H)], 2, seed), (5 * s + 1) * w, COLORS.get(color, INK), seed=seed)]


def el_subscribe(x, y, s, seed=0, **_):
    w, h = 420 * s, 110 * s
    m, o = mask_from(lambda d, T, ss: d.rounded_rectangle([T((x - w / 2, y - h / 2)), T((x + w / 2, y + h / 2))], radius=int(h / 2 * ss),
                                                          fill=255), (x - w / 2, y - h / 2, x + w / 2, y + h / 2))
    out = [Fill(m, o, tone=0.9, color=RED, seed=seed), Text("SUBSCRIBE", x, y, 56 * s, (250, 245, 235))]
    bx = x + w / 2 + 90 * s
    out.append(Stroke(bez((bx - 45 * s, y + 35 * s), (bx, y - 100 * s), (bx + 45 * s, y + 35 * s), 16), 6 * s + 1, seed=seed))
    out.append(Stroke([(bx - 55 * s, y + 35 * s), (bx + 55 * s, y + 35 * s)], 6 * s + 1, seed=seed + 1))
    out.append(Stroke(ellipse_pts(bx, y + 50 * s, 10 * s, 10 * s, n=12), 4 * s + 1, seed=seed + 2))
    return out


def el_ground(x, y, s, w=0.7, seed=0, W=1920, **_):
    x0, x1 = x - w * W / 2, x + w * W / 2
    pts = [(x0 + (x1 - x0) * u, y + 3 * math.sin(u * 9 + seed)) for u in (i / 30 for i in range(31))]
    return [Stroke(pts, 3 * s + 1, COLORS["grey"], seed=seed)]


ELEMENTS = {
    "ground": el_ground,
    "head": el_head, "chair": el_chair, "screen": el_screen, "cross": el_cross, "circle": el_circle, "arrow": el_arrow,
    "text": el_text, "bubble": el_bubble, "butterfly": el_butterfly, "stairs": el_stairs, "padlock": el_padlock, "bed": el_bed,
    "moon": el_moon, "room": el_room, "globe": el_globe, "stars": el_stars, "dot": el_dot, "scroll": el_scroll, "letter": el_letter,
    "child_q": el_child_panel, "hourglass": el_hourglass, "line": el_line, "subscribe": el_subscribe,
}


# --------------------------------------------------------------------------- #
# Sahne: öğeleri sırayla çizer
# --------------------------------------------------------------------------- #
class SketchScene:
    def __init__(self, elements, W, H, draw_time=None, seed=1):
        self.W, self.H = W, H
        self.groups = []  # (başlangıç, [items])
        k = W / 1920
        for i, e in enumerate(elements):
            e = dict(e)
            name = e.pop("el")
            at = e.pop("at", None)
            x, y = e.pop("x", 0.5) * W, e.pop("y", 0.5) * H
            if name == "figure":
                items, _ = figure(x, y, e.pop("h", 0.5) * H, e.pop("pose", "stand"), e.pop("face", 1), e.pop("child", False),
                                  e.pop("hat", None), e.pop("tone", 0.88), seed + i, W)
            else:
                s = e.pop("s", 1.0) * k
                items = ELEMENTS[name](x, y, s, seed=seed + i * 7, W=W, H=H, **e)
            self.groups.append([at, items])
        # başlangıç zamanı verilmeyenler sırayla, kendi ağırlıklarıyla
        t = 0.0
        speed = 1.0 if draw_time is None else None
        for g in self.groups:
            w = sum(it.weight() for it in g[1])
            if g[0] is None:
                g[0] = t
            g.append(w * 0.42)  # çizim süresi (sn)
            t = g[0] + g[2]
        self.end = t
        self.base = Image.fromarray(kk.paper(W, H).astype(np.uint8))
        self.done = self.base.copy()
        self.done_upto = []  # tamamen çizilmiş (grup, öğe) çiftleri
        self._done_set = set()

    def frame(self, t):
        img = None
        tip = None
        # tamamlananları kalıcı katmana ekle
        for gi, (st, items, dur) in enumerate(self.groups):
            total = sum(it.weight() for it in items) or 1
            acc = 0.0
            for ii, it in enumerate(items):
                w = it.weight() / total
                a, b = st + acc * dur, st + (acc + w) * dur
                acc += w
                key = (gi, ii)
                if key in self._done_set:
                    continue
                if t >= b:
                    it.draw(self.done, 1.0)
                    self._done_set.add(key)
        img = self.done.copy()
        for gi, (st, items, dur) in enumerate(self.groups):
            total = sum(it.weight() for it in items) or 1
            acc = 0.0
            for ii, it in enumerate(items):
                w = it.weight() / total
                a, b = st + acc * dur, st + (acc + w) * dur
                acc += w
                if (gi, ii) in self._done_set or t < a:
                    continue
                u = (t - a) / max(b - a, 1e-3)
                it.draw(img, u)
                tip = it.tip(u)
        if tip is not None:
            kk.draw_pencil(ImageDraw.Draw(img), tip[0], tip[1], self.W / 1920 * 0.9)
        return img
