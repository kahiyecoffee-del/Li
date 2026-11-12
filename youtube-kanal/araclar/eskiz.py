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
        elif hat == "vr":
            dr.rounded_rectangle([T((head_c[0] - head_r * 0.6 + face * head_r * 0.25, head_c[1] - head_r * 0.45)),
                                  T((head_c[0] + head_r * 0.6 + face * head_r * 0.75, head_c[1] + head_r * 0.25))], radius=int(head_r * 0.2 * ss),
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
    if hat == "vr":  # görünür VR gözlüğü (açık renk, kayışlı)
        gx0, gx1 = head_c[0] - head_r * 0.55 + face * head_r * 0.3, head_c[0] + head_r * 0.55 + face * head_r * 0.75
        gy0, gy1 = head_c[1] - head_r * 0.45, head_c[1] + head_r * 0.22
        vm, vo = mask_from(lambda d, T, ss: d.rounded_rectangle([T((gx0, gy0)), T((gx1, gy1))], radius=int(head_r * 0.18 * ss), fill=255),
                           (gx0 - 2, gy0 - 2, gx1 + 2, gy1 + 2))
        items.append(Fill(vm, vo, tone=0.95, color=(90, 130, 200), seed=seed + 7))
        items.append(Stroke([(gx0, head_c[1] - head_r * 0.1), (head_c[0] - face * head_r * 0.85, head_c[1] - head_r * 0.25)], max(2, head_r * 0.12),
                            (90, 130, 200), 1, seed + 8))
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


def _rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0)]


def _blob(points, tone=0.85, color=INK, seed=0, style="charcoal", smooth=0.0):
    xs, ys = [p[0] for p in points], [p[1] for p in points]
    m, o = mask_from(lambda d, T, ss: d.polygon([T(p) for p in points], fill=255), (min(xs) - 4, min(ys) - 4, max(xs) + 4, max(ys) + 4),
                     smooth=smooth)
    return Fill(m, o, tone=tone, color=color, seed=seed, style=style)


def el_glass_stick(x, y, s, seed=0, **_):
    w, h = 220 * s, 330 * s
    out = [Stroke([(x - w / 2, y - h), (x - w * 0.4, y), (x + w * 0.4, y), (x + w / 2, y - h)], 5 * s + 1, seed=seed),
           Stroke(wobble([(x - w * 0.47, y - h * 0.55), (x + w * 0.47, y - h * 0.55)], 3, seed), 3 * s + 1, BLUE, seed=seed + 1)]
    for k in range(4):
        yy = y - h * 0.45 + k * h * 0.11
        out.append(Stroke([(x - w * 0.42, yy), (x + w * 0.42, yy)], 2, (120, 150, 200), 1, seed + 5 + k))
    out.append(Stroke([(x - w * 0.9, y - h * 1.15), (x - w * 0.05, y - h * 0.55)], 8 * s + 1, (120, 80, 50), seed=seed + 2))
    out.append(Stroke([(x - w * 0.05, y - h * 0.55), (x + w * 0.15, y - h * 0.08)], 8 * s + 1, (120, 80, 50), seed=seed + 3))
    return out


def el_eye(x, y, s, seed=0, **_):
    w, h = 300 * s, 140 * s
    out = [Stroke(bez((x - w / 2, y), (x, y - h * 1.1), (x + w / 2, y)), 6 * s + 1, seed=seed),
           Stroke(bez((x - w / 2, y), (x, y + h * 1.1), (x + w / 2, y)), 6 * s + 1, seed=seed + 1),
           Stroke(ellipse_pts(x, y, h * 0.42, h * 0.42, n=24, seed=seed), 4 * s + 1, seed=seed + 2)]
    m, o = mask_from(lambda d, T, ss: d.ellipse([T((x - h * 0.2, y - h * 0.2)), T((x + h * 0.2, y + h * 0.2))], fill=255),
                     (x - h * 0.22, y - h * 0.22, x + h * 0.22, y + h * 0.22))
    out.append(Fill(m, o, tone=0.95, seed=seed))
    for k in range(5):
        a = math.pi * (1.15 + k * 0.17)
        out.append(Stroke([(x + math.cos(a) * w * 0.42, y + math.sin(a) * h * 0.62),
                           (x + math.cos(a) * w * 0.5, y + math.sin(a) * h * 0.95)], 3 * s + 1, seed=seed + 9 + k))
    return out


def el_demon(x, y, s, strings_to=None, seed=0, W=1920, H=1080, **_):
    """Gökyüzünde büyük boynuzlu iblis silüeti; ellerinden aşağı ipler (kukla)."""
    r = 120 * s
    pts = [(x - r * 1.6, y + r * 1.2), (x - r * 1.3, y + r * 0.2), (x - r * 0.75, y - r * 0.35), (x - r * 1.05, y - r * 1.0),
           (x - r * 1.0, y - r * 1.7), (x - r * 0.55, y - r * 0.75), (x, y - r * 0.85), (x + r * 0.55, y - r * 0.75),
           (x + r * 1.0, y - r * 1.7), (x + r * 1.05, y - r * 1.0), (x + r * 0.75, y - r * 0.35), (x + r * 1.3, y + r * 0.2),
           (x + r * 1.6, y + r * 1.2)]
    out = [_blob(pts, tone=0.92, seed=seed, smooth=r * 0.03)]
    grin = [(x - r * 0.45, y + r * 0.25), (x - r * 0.3, y + r * 0.38), (x - r * 0.15, y + r * 0.28), (x, y + r * 0.42),
            (x + r * 0.15, y + r * 0.28), (x + r * 0.3, y + r * 0.38), (x + r * 0.45, y + r * 0.25)]
    out.append(Stroke(grin, 4 * s + 1, (238, 232, 218), 1, seed=seed + 7))
    for side in (-1, 1):
        ex, ey = x + side * r * 0.35, y - r * 0.15
        m, o = mask_from(lambda d, T, ss: d.polygon([T((ex - r * 0.18, ey - r * 0.05 * side)), T((ex + r * 0.18, ey + r * 0.05 * side)),
                                                     T((ex, ey + r * 0.1))], fill=255), (ex - r * 0.2, ey - r * 0.12, ex + r * 0.2, ey + r * 0.12))
        out.append(Fill(m, o, tone=0.95, color=RED, seed=seed + side, outline=False))
    if strings_to:
        for k, (tx, ty) in enumerate(strings_to):
            sx = x + (-1 if k % 2 == 0 else 1) * r * (1.2 + 0.2 * k)
            out.append(Stroke([(sx, y + r * 1.0), (tx * W, ty * H)], 2, COLORS["grey"], 1, seed + 20 + k))
    return out


def el_pit(x, y, s, figure_in=True, seed=0, **_):
    w, d_ = 520 * s, 330 * s
    out = [Stroke(wobble([(x - w * 1.0, y - d_), (x - w / 2, y - d_)], 2, seed), 5 * s + 1, seed=seed),
           Stroke(wobble([(x + w / 2, y - d_), (x + w * 1.0, y - d_)], 2, seed + 1), 5 * s + 1, seed=seed + 1),
           Stroke(wobble([(x - w / 2, y - d_), (x - w * 0.45, y), (x + w * 0.45, y), (x + w / 2, y - d_)], 3, seed + 2), 5 * s + 1, seed=seed + 2)]
    hm, ho = mask_from(lambda dd, T, ss: dd.polygon([T((x - w / 2, y - d_)), T((x - w * 0.45, y)), T((x + w * 0.45, y)), T((x + w / 2, y - d_))],
                                                     fill=255), (x - w / 2, y - d_, x + w / 2, y))
    out.append(Fill(hm, ho, tone=0.35, style="hatch", seed=seed, outline=False))
    if figure_in:
        items, _a = figure(x, y - 6 * s, d_ * 0.75, "think", 1, seed=seed + 5)
        out += items
    return out


def el_ladder(x, y, s, h=1.0, broken=False, seed=0, **_):
    L, w = 520 * s * h, 90 * s
    out = [Stroke(wobble([(x - w / 2, y), (x - w / 2 + 40 * s, y - L)], 2, seed), 6 * s + 1, (120, 80, 50), seed=seed),
           Stroke(wobble([(x + w / 2, y), (x + w / 2 + 40 * s, y - L)], 2, seed + 1), 6 * s + 1, (120, 80, 50), seed=seed + 1)]
    n = 7
    for k in range(1, n):
        u = k / n
        yy = y - L * u
        x0, x1 = x - w / 2 + 40 * s * u, x + w / 2 + 40 * s * u
        if broken and k in (3, 5):
            out.append(Stroke([(x0, yy), (x0 + w * 0.35, yy + 14 * s)], 5 * s, (120, 80, 50), seed=seed + k))
            continue
        out.append(Stroke([(x0, yy), (x1, yy)], 5 * s, (120, 80, 50), seed=seed + k))
    return out


def el_stone(x, y, s, seed=0, **_):
    r = 120 * s
    pts = [(x - r * 1.3, y), (x - r * 1.2, y - r * 0.6), (x - r * 0.5, y - r * 1.05), (x + r * 0.4, y - r * 0.95),
           (x + r * 1.2, y - r * 0.45), (x + r * 1.35, y)]
    return [_blob(pts, tone=0.55, seed=seed, smooth=r * 0.06), Stroke(wobble(pts, 3, seed), 5 * s + 1, seed=seed)]


def el_house(x, y, s, lit=True, seed=0, **_):
    w, h = 360 * s, 260 * s
    out = [Stroke(_rect(x - w / 2, y - h, x + w / 2, y), 6 * s + 1, seed=seed),
           Stroke([(x - w * 0.6, y - h), (x, y - h * 1.8), (x + w * 0.6, y - h)], 6 * s + 1, seed=seed + 1),
           Stroke(_rect(x - 40 * s, y - 130 * s, x + 40 * s, y), 4 * s + 1, seed=seed + 2)]
    for wx in (x - w * 0.32, x + w * 0.32):
        if lit:
            m, o = mask_from(lambda d, T, ss, wx=wx: d.rectangle([T((wx - 45 * s, y - h * 0.8)), T((wx + 45 * s, y - h * 0.45))], fill=255),
                             (wx - 45 * s, y - h * 0.8, wx + 45 * s, y - h * 0.45))
            out.append(Fill(m, o, tone=0.95, color=(245, 205, 110), seed=seed, outline=False))
        out.append(Stroke(_rect(wx - 45 * s, y - h * 0.8, wx + 45 * s, y - h * 0.45), 4 * s + 1, seed=seed + 3))
    return out


def el_basket(x, y, s, seed=0, **_):
    w, h = 220 * s, 130 * s
    out = [Stroke(bez((x - w / 2, y - h), (x, y - h * 0.8), (x + w / 2, y - h)), 5 * s + 1, (140, 95, 50), seed=seed),
           Stroke([(x - w / 2, y - h), (x - w * 0.38, y), (x + w * 0.38, y), (x + w / 2, y - h)], 5 * s + 1, (140, 95, 50), seed=seed + 1),
           Stroke(bez((x - w * 0.42, y - h), (x, y - h * 2.2), (x + w * 0.42, y - h)), 4 * s + 1, (140, 95, 50), seed=seed + 2)]
    for k in range(3):
        yy = y - h * (0.25 + 0.25 * k)
        out.append(Stroke([(x - w * 0.44, yy), (x + w * 0.44, yy)], 2, (160, 115, 70), 1, seed + 5 + k))
    return out


def el_box(x, y, s, seed=0, **_):
    w, h = 220 * s, 160 * s
    return [Stroke(_rect(x - w / 2, y - h, x + w / 2, y), 5 * s + 1, (120, 80, 50), seed=seed),
            Stroke([(x - w / 2, y - h), (x - w / 2 + 40 * s, y - h - 40 * s), (x + w / 2 + 40 * s, y - h - 40 * s), (x + w / 2, y - h)],
                   4 * s + 1, (120, 80, 50), seed=seed + 1),
            Stroke([(x + w / 2 + 40 * s, y - h - 40 * s), (x + w / 2 + 40 * s, y - 40 * s), (x + w / 2, y)], 4 * s + 1, (120, 80, 50), seed=seed + 2)]


def el_marble(x, y, s, color="blue", seed=0, **_):
    r = 26 * s
    m, o = mask_from(lambda d, T, ss: d.ellipse([T((x - r, y - r)), T((x + r, y + r))], fill=255), (x - r, y - r, x + r, y + r))
    return [Fill(m, o, tone=0.95, color=COLORS.get(color, BLUE), seed=seed)]


def el_camera(x, y, s, face=-1, seed=0, **_):
    w, h = 200 * s, 120 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 5 * s + 1, seed=seed),
           Stroke(ellipse_pts(x - w * 0.22, y - h * 0.85, h * 0.35, h * 0.35, n=20, seed=seed), 4 * s + 1, seed=seed + 1),
           Stroke(ellipse_pts(x + w * 0.22, y - h * 0.85, h * 0.35, h * 0.35, n=20, seed=seed + 1), 4 * s + 1, seed=seed + 2),
           Stroke([(x + face * w / 2, y - h * 0.3), (x + face * w * 0.85, y - h * 0.5), (x + face * w * 0.85, y + h * 0.5),
                   (x + face * w / 2, y + h * 0.3)], 4 * s + 1, seed=seed + 3),
           Stroke([(x, y + h / 2), (x - w * 0.4, y + h * 2.4)], 4 * s + 1, seed=seed + 4),
           Stroke([(x, y + h / 2), (x + w * 0.4, y + h * 2.4)], 4 * s + 1, seed=seed + 5),
           Stroke([(x, y + h / 2), (x, y + h * 2.4)], 4 * s + 1, seed=seed + 6)]
    return out


def el_dome(x, y, s, seed=0, **_):
    r = 520 * s
    out = [Stroke([(x + math.cos(u) * r, y - math.sin(u) * r * 0.75) for u in np.linspace(0, math.pi, 40)], 4 * s + 1, BLUE, seed=seed)]
    for k in range(1, 5):
        u = k / 5 * math.pi
        out.append(Stroke([(x + math.cos(u) * r, y - math.sin(u) * r * 0.75), (x + math.cos(u) * r * 0.5, y)], 2, (120, 150, 200), 1, seed + k))
    return out


def el_vat(x, y, s, wires=True, seed=0, **_):
    w, h = 260 * s, 340 * s
    out = [Stroke([(x - w / 2, y - h), (x - w / 2, y), (x + w / 2, y), (x + w / 2, y - h)], 5 * s + 1, seed=seed),
           Stroke(ellipse_pts(x, y - h, w / 2, 26 * s, n=30, seed=seed), 4 * s + 1, seed=seed + 1),
           Stroke(wobble([(x - w * 0.48, y - h * 0.82), (x + w * 0.48, y - h * 0.82)], 3, seed), 3 * s + 1, (120, 150, 200), seed=seed + 2)]
    bx, by = x, y - h * 0.42
    bm, bo = mask_from(lambda d, T, ss: d.ellipse([T((bx - w * 0.32, by - h * 0.22)), T((bx + w * 0.32, by + h * 0.18))], fill=255),
                       (bx - w * 0.34, by - h * 0.24, bx + w * 0.34, by + h * 0.2), smooth=4)
    out.append(Fill(bm, bo, tone=0.75, color=(200, 120, 130), seed=seed))
    for k in range(5):
        yy = by - h * 0.15 + k * h * 0.07
        out.append(Stroke(bez((bx - w * 0.28, yy), (bx, yy - 20 * s * ((-1) ** k)), (bx + w * 0.28, yy), 10), 2, (120, 50, 60), 1, seed + 9 + k))
    if wires:
        for k, dx in enumerate((-0.15, 0.0, 0.15)):
            out.append(Stroke(bez((bx + w * dx, by - h * 0.18), (bx + w * dx + 60 * s, y - h * 1.4), (x + w * 1.1, y - h * (0.9 - 0.15 * k)), 16),
                              3 * s + 1, seed=seed + 20 + k))
    return out


def el_top(x, y, s, seed=0, **_):
    w, h = 140 * s, 180 * s
    out = [Stroke([(x - w / 2, y - h * 0.6), (x, y), (x + w / 2, y - h * 0.6)], 5 * s + 1, seed=seed),
           Stroke(ellipse_pts(x, y - h * 0.6, w / 2, 20 * s, n=26, seed=seed), 5 * s + 1, seed=seed + 1),
           Stroke([(x, y - h * 0.6), (x, y - h)], 7 * s + 1, seed=seed + 2)]
    for k in range(3):
        out.append(Stroke([(x + math.cos(u) * w * (0.8 + 0.12 * k), y - h * 0.35 + math.sin(u) * 30 * s) for u in np.linspace(0.3, 2.6, 12)],
                          2, COLORS["grey"], 1, seed + 5 + k))
    return out


def el_backgammon(x, y, s, seed=0, **_):
    w, h = 520 * s, 300 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 6 * s + 1, (120, 80, 50), seed=seed),
           Stroke([(x, y - h / 2), (x, y + h / 2)], 4 * s + 1, (120, 80, 50), seed=seed + 1)]
    for k in range(12):
        side = -1 if k < 6 else 1
        cx = x - w / 2 + (k + 0.5 + (0.6 if k >= 6 else 0)) * (w / 12.6)
        out.append(Stroke([(cx - 16 * s, y - h / 2 + 4), (cx, y - h * 0.08), (cx + 16 * s, y - h / 2 + 4)], 2, INK if k % 2 else RED, 1, seed + k))
        out.append(Stroke([(cx - 16 * s, y + h / 2 - 4), (cx, y + h * 0.08), (cx + 16 * s, y + h / 2 - 4)], 2, RED if k % 2 else INK, 1,
                          seed + 30 + k))
    for k, (dx, dy) in enumerate(((-0.3, -0.3), (-0.25, -0.3), (0.2, 0.32), (0.32, 0.25))):
        cx, cy = x + dx * w, y + dy * h
        out.append(Stroke(ellipse_pts(cx, cy, 16 * s, 16 * s, n=14, seed=seed + k), 4 * s + 1, seed=seed + 50 + k))
    return out


def el_dots(x, y, s, n=50, cols=10, highlight=1, seed=0, **_):
    out = []
    sp = 46 * s
    rows = (n + cols - 1) // cols
    for i in range(n):
        cx = x + (i % cols - (cols - 1) / 2) * sp
        cy = y + (i // cols - (rows - 1) / 2) * sp
        c = RED if i < highlight else INK
        out.append(Stroke(ellipse_pts(cx, cy, 10 * s, 10 * s, n=12, seed=seed + i), 4 * s + 1, c, 1, seed + i))
    return out


def el_heads(x, y, s, n=3, glow=True, links=True, seed=0, **_):
    """Yan yana küçük başlar (birden çok zihin) ve aralarında oklar."""
    out = []
    xs = [x + (i - (n - 1) / 2) * 330 * s for i in range(n)]
    for i, cx in enumerate(xs):
        out += el_head(cx, y, s * 0.45, face=1 if i < n / 2 else -1, glow=glow, seed=seed + i)
    if links:
        for a, b in zip(xs, xs[1:]):
            out.append(Stroke(bez((a + 90 * s, y - 160 * s), ((a + b) / 2, y - 260 * s), (b - 90 * s, y - 160 * s), 14), 3 * s + 1, BLUE,
                              seed=seed + 20))
    return out


def el_portrait_frame(x, y, s, text=None, seed=0, **_):
    w, h = 300 * s, 380 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 7 * s + 1, (150, 110, 60), seed=seed)]
    out += el_head(x, y + 30 * s, s * 0.55, seed=seed)
    if text:
        out.append(Text(text, x, y + h / 2 + 50 * s, 44 * s, INK))
    return out


ELEMENTS_EXTRA = {
    "glass_stick": el_glass_stick, "eye": el_eye, "demon": el_demon, "pit": el_pit, "ladder": el_ladder, "stone": el_stone,
    "house": el_house, "basket": el_basket, "box": el_box, "marble": el_marble, "camera": el_camera, "dome": el_dome, "vat": el_vat,
    "top": el_top, "backgammon": el_backgammon, "dots": el_dots, "heads": el_heads, "portrait_frame": el_portrait_frame,
}


def el_campfire(x, y, s, seed=0, **_):
    out = []
    for k, (dx, ang) in enumerate(((-60, -0.3), (60, 0.3), (0, 0.0))):
        out.append(Stroke([(x + dx * s - 90 * s * math.cos(ang), y + 10 * s), (x + dx * s + 90 * s * math.cos(ang), y - 20 * s)], 12 * s + 1,
                          (110, 75, 45), seed=seed + k))
    flame = [(x - 70 * s, y - 20 * s), (x - 50 * s, y - 110 * s), (x - 15 * s, y - 70 * s), (x, y - 190 * s), (x + 25 * s, y - 80 * s),
             (x + 55 * s, y - 130 * s), (x + 70 * s, y - 20 * s)]
    out.append(_blob(flame, tone=0.9, color=(235, 140, 50), seed=seed, smooth=8 * s))
    inner = [(x - 30 * s, y - 25 * s), (x - 10 * s, y - 90 * s), (x + 15 * s, y - 60 * s), (x + 30 * s, y - 25 * s)]
    out.append(_blob(inner, tone=0.9, color=(250, 205, 90), seed=seed + 1, smooth=6 * s))
    return out


def el_phone(x, y, s, likes=None, heart=True, seed=0, **_):
    w, h = 220 * s, 400 * s
    out = [Stroke([(x - w / 2 + 20 * s, y - h / 2), (x + w / 2 - 20 * s, y - h / 2), (x + w / 2, y - h / 2 + 20 * s), (x + w / 2, y + h / 2 - 20 * s),
                   (x + w / 2 - 20 * s, y + h / 2), (x - w / 2 + 20 * s, y + h / 2), (x - w / 2, y + h / 2 - 20 * s), (x - w / 2, y - h / 2 + 20 * s),
                   (x - w / 2 + 20 * s, y - h / 2)], 6 * s + 1, seed=seed),
           Stroke(_rect(x - w * 0.38, y - h * 0.38, x + w * 0.38, y + h * 0.15), 3 * s + 1, COLORS["grey"], seed=seed + 1)]
    if heart:
        out += el_heart(x - w * 0.22, y + h * 0.3, s * 0.35, seed=seed + 2)
    if likes:
        out.append(Text(str(likes), x + w * 0.1, y + h * 0.3, 40 * s, RED))
    return out


def el_heart(x, y, s, color="red", seed=0, **_):
    pts = []
    for i in range(41):
        a = i / 40 * 2 * math.pi
        hx = 16 * math.sin(a) ** 3
        hy = 13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a)
        pts.append((x + hx * 7 * s, y - hy * 7 * s))
    return [_blob(pts, tone=0.9, color=COLORS.get(color, RED), seed=seed, smooth=2)]


def el_bell(x, y, s, ringing=True, seed=0, **_):
    out = [Stroke(bez((x - 90 * s, y + 70 * s), (x, y - 230 * s), (x + 90 * s, y + 70 * s), 20), 7 * s + 1, (190, 140, 50), seed=seed),
           Stroke([(x - 115 * s, y + 70 * s), (x + 115 * s, y + 70 * s)], 7 * s + 1, (190, 140, 50), seed=seed + 1),
           Stroke(ellipse_pts(x, y + 95 * s, 18 * s, 18 * s, n=14, seed=seed), 5 * s + 1, (190, 140, 50), seed=seed + 2)]
    if ringing:
        for side in (-1, 1):
            for k in range(2):
                r = (150 + 45 * k) * s
                out.append(Stroke([(x + side * math.cos(u) * r, y - math.sin(u) * r * 0.6) for u in np.linspace(0.3, 0.9, 8)], 3 * s + 1, RED, 1,
                                  seed + 5 + k))
    return out


def el_brain(x, y, s, spot=None, seed=0, **_):
    r = 200 * s
    out = []
    pts = []
    for i in range(41):
        u = 2 * math.pi * i / 40
        wob = 1 + 0.06 * math.sin(u * 9 + seed)
        pts.append((x + math.cos(u) * r * 1.25 * wob, y + math.sin(u) * r * 0.85 * wob))
    out.append(_blob(pts, tone=0.35, color=(200, 150, 160), seed=seed, smooth=6 * s))
    out.append(Stroke(pts, 5 * s + 1, seed=seed))
    for k in range(6):
        yy = y - r * 0.55 + k * r * 0.22
        out.append(Stroke([(x - r * 1.0 + 30 * s * (k % 2), yy), (x - r * 0.4, yy + 25 * s), (x + r * 0.2, yy - 15 * s), (x + r * 0.9, yy + 10 * s)],
                          3 * s, (130, 80, 90), 1, seed + 3 + k))
    out.append(Stroke([(x, y - r * 0.85), (x - 10 * s, y + r * 0.85)], 3 * s + 1, (130, 80, 90), seed=seed + 20))
    if spot:
        sx, sy = x + spot[0] * r, y + spot[1] * r
        out.append(Stroke(ellipse_pts(sx, sy, 50 * s, 40 * s, n=20, seed=seed), 7 * s + 1, RED, seed=seed + 30))
        m, o = mask_from(lambda d, T, ss: d.ellipse([T((sx - 40 * s, sy - 32 * s)), T((sx + 40 * s, sy + 32 * s))], fill=255),
                         (sx - 42 * s, sy - 34 * s, sx + 42 * s, sy + 34 * s))
        out.append(Fill(m, o, tone=0.6, color=RED, seed=seed, outline=False))
    return out


def el_gauge(x, y, s, value=0.2, label=None, seed=0, **_):
    r = 220 * s
    out = [Stroke([(x + math.cos(u) * r, y - math.sin(u) * r) for u in np.linspace(math.pi, 0, 40)], 6 * s + 1, seed=seed)]
    for k in range(9):
        u = math.pi - k * math.pi / 8
        out.append(Stroke([(x + math.cos(u) * r * 0.85, y - math.sin(u) * r * 0.85), (x + math.cos(u) * r, y - math.sin(u) * r)],
                          3 * s + 1, RED if k < 3 else (INK if k < 6 else (60, 150, 80)), 1, seed + k))
    u = math.pi - value * math.pi
    out.append(Stroke([(x, y), (x + math.cos(u) * r * 0.75, y - math.sin(u) * r * 0.75)], 8 * s + 1, RED, seed=seed + 20))
    out.append(Stroke(ellipse_pts(x, y, 14 * s, 14 * s, n=12), 6 * s + 1, seed=seed + 21))
    if label:
        out.append(Text(label, x, y + 70 * s, 48 * s, INK))
    return out


def el_asch_card(x, y, s, seed=0, **_):
    w, h = 900 * s, 420 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 5 * s + 1, seed=seed),
           Stroke([(x - w * 0.02, y - h / 2), (x - w * 0.02, y + h / 2)], 3 * s, COLORS["grey"], seed=seed + 1)]
    bx = x - w * 0.27
    out.append(Stroke([(bx, y + h * 0.35), (bx, y - h * 0.25)], 9 * s + 1, seed=seed + 2))
    for k, (lab, L) in enumerate((("A", 0.42), ("B", 0.78), ("C", 0.6))):
        lx = x + w * (0.1 + 0.14 * k)
        out.append(Stroke([(lx, y + h * 0.35), (lx, y + h * 0.35 - h * L)], 9 * s + 1, seed=seed + 5 + k))
        out.append(Text(lab, lx, y + h * 0.43, 46 * s, INK))
    return out


def el_slot(x, y, s, seed=0, **_):
    w, h = 420 * s, 480 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 6 * s + 1, seed=seed),
           Stroke(_rect(x - w * 0.4, y - h * 0.3, x + w * 0.4, y), 4 * s + 1, seed=seed + 1),
           Stroke([(x + w / 2, y - h * 0.1), (x + w / 2 + 70 * s, y - h * 0.1), (x + w / 2 + 70 * s, y - h * 0.45)], 6 * s + 1, seed=seed + 2),
           Stroke(ellipse_pts(x + w / 2 + 70 * s, y - h * 0.5, 22 * s, 22 * s, n=14), 5 * s + 1, RED, seed=seed + 3)]
    for k in range(1, 3):
        xx = x - w * 0.4 + k * w * 0.8 / 3
        out.append(Stroke([(xx, y - h * 0.3), (xx, y)], 3 * s, seed=seed + 4 + k))
    out += el_heart(x - w * 0.27, y - h * 0.15, s * 0.3, seed=seed + 7)
    out += el_heart(x, y - h * 0.15, s * 0.3, seed=seed + 8)
    out.append(Text("?", x + w * 0.27, y - h * 0.15, 80 * s, INK))
    out.append(Stroke(_rect(x - w * 0.3, y + h * 0.18, x + w * 0.3, y + h * 0.3), 3 * s + 1, COLORS["grey"], seed=seed + 9))
    return out


def el_mirror(x, y, s, seed=0, **_):
    w, h = 300 * s, 520 * s
    return [Stroke(ellipse_pts(x, y, w / 2, h / 2, n=48, seed=seed), 8 * s + 1, (150, 110, 60), seed=seed),
            Stroke([(x - w * 0.25, y - h * 0.25), (x - w * 0.05, y - h * 0.35)], 3 * s, (170, 190, 210), 1, seed + 1),
            Stroke([(x - w * 0.25, y - h * 0.15), (x + w * 0.05, y - h * 0.32)], 3 * s, (170, 190, 210), 1, seed + 2),
            Stroke([(x, y + h / 2), (x, y + h / 2 + 80 * s)], 8 * s + 1, (150, 110, 60), seed=seed + 3),
            Stroke([(x - 90 * s, y + h / 2 + 80 * s), (x + 90 * s, y + h / 2 + 80 * s)], 8 * s + 1, (150, 110, 60), seed=seed + 4)]


def el_mask(x, y, s, seed=0, **_):
    w, h = 260 * s, 300 * s
    pts = [(x + math.cos(u) * w / 2 * (1 - 0.15 * max(0, math.sin(u))), y + math.sin(u) * h / 2) for u in np.linspace(0, 2 * math.pi, 40)]
    out = [_blob(pts, tone=0.25, color=(230, 225, 210), seed=seed, smooth=4), Stroke(pts, 5 * s + 1, seed=seed)]
    for side in (-1, 1):
        out.append(Stroke(ellipse_pts(x + side * w * 0.2, y - h * 0.1, 38 * s, 22 * s, n=18, seed=seed + side), 5 * s + 1, seed=seed + 2))
    out.append(Stroke(bez((x - w * 0.22, y + h * 0.18), (x, y + h * 0.32), (x + w * 0.22, y + h * 0.18)), 5 * s + 1, seed=seed + 3))
    out.append(Stroke([(x + w / 2, y - h * 0.05), (x + w / 2 + 90 * s, y - h * 0.15)], 3 * s, COLORS["grey"], seed=seed + 4))
    return out


def el_mountain(x, y, s, seed=0, **_):
    w = 900 * s
    out = [Stroke([(x - w / 2, y), (x - w * 0.15, y - 420 * s), (x + 0.02 * w, y - 300 * s), (x + 0.2 * w, y - 520 * s), (x + w / 2, y)],
                  6 * s + 1, seed=seed),
           Stroke([(x + 0.2 * w - 60 * s, y - 440 * s), (x + 0.2 * w, y - 520 * s), (x + 0.2 * w + 70 * s, y - 430 * s)], 4 * s + 1, BLUE, seed=seed + 1),
           Stroke(bez((x - w * 0.42, y - 10 * s), (x - w * 0.05, y - 120 * s), (x + 0.2 * w, y - 500 * s), 24), 3 * s, (150, 110, 60), seed=seed + 2)]
    return out


def el_books(x, y, s, n=4, seed=0, **_):
    out = []
    cols = [(130, 40, 45), (45, 55, 95), (60, 100, 70), (150, 110, 50)]
    for k in range(n):
        yy = y - k * 46 * s
        dx = (k % 2) * 20 * s - 10 * s
        out.append(Stroke(_rect(x - 170 * s + dx, yy - 42 * s, x + 170 * s + dx, yy), 5 * s + 1, cols[k % 4], seed=seed + k))
    return out


def el_graph(x, y, s, up=True, seed=0, **_):
    w, h = 700 * s, 420 * s
    out = [Stroke([(x - w / 2, y - h / 2), (x - w / 2, y + h / 2), (x + w / 2, y + h / 2)], 5 * s + 1, seed=seed)]
    pts = [(x - w / 2 + 40 * s + i * (w - 80 * s) / 8, y + h / 2 - 40 * s - (i / 8 if up else 1 - i / 8) * (h - 100 * s)
            + 25 * s * math.sin(i * 1.7)) for i in range(9)]
    out.append(Stroke(pts, 7 * s + 1, (60, 150, 80) if up else RED, seed=seed + 1))
    return out


def el_tshirt(x, y, s, text=None, seed=0, **_):
    pts = [(x - 170 * s, y - 180 * s), (x - 60 * s, y - 210 * s), (x, y - 175 * s), (x + 60 * s, y - 210 * s), (x + 170 * s, y - 180 * s),
           (x + 240 * s, y - 90 * s), (x + 165 * s, y - 50 * s), (x + 135 * s, y - 95 * s), (x + 135 * s, y + 200 * s),
           (x - 135 * s, y + 200 * s), (x - 135 * s, y - 95 * s), (x - 165 * s, y - 50 * s), (x - 240 * s, y - 90 * s)]
    out = [_blob(pts, tone=0.25, color=(240, 200, 90), seed=seed, smooth=3), Stroke(pts + [pts[0]], 5 * s + 1, seed=seed)]
    if text:
        out.append(Text(text, x, y, 50 * s, RED))
    return out


def el_spotlight(x, y, s, seed=0, H=1080, **_):
    w = 360 * s
    pts = [(x - 40 * s, 0), (x + 40 * s, 0), (x + w / 2, y), (x - w / 2, y)]
    m, o = mask_from(lambda d, T, ss: d.polygon([T(p) for p in pts], fill=255), (x - w / 2, 0, x + w / 2, y))
    return [Fill(m, o, tone=0.25, color=(245, 215, 120), seed=seed, outline=False),
            Stroke(ellipse_pts(x, y, w / 2, 40 * s, n=30, seed=seed), 3 * s + 1, (200, 160, 60), seed=seed)]


def el_tags(x, y, s, labels=(), seed=0, **_):
    out = []
    for k, lab in enumerate(labels):
        yy = y + k * 80 * s
        out.append(Stroke(_rect(x - 150 * s, yy - 30 * s, x + 150 * s, yy + 30 * s), 4 * s + 1, RED, seed=seed + k))
        out.append(Text(lab, x, yy, 40 * s, RED))
    return out


ELEMENTS_EXTRA.update({
    "campfire": el_campfire, "phone": el_phone, "heart": el_heart, "bell": el_bell, "brain": el_brain, "gauge": el_gauge,
    "asch_card": el_asch_card, "slot": el_slot, "mirror": el_mirror, "mask": el_mask, "mountain": el_mountain, "books": el_books,
    "graph": el_graph, "tshirt": el_tshirt, "spotlight": el_spotlight, "tags": el_tags,
})


def el_cave(x, y, s, fire=True, seed=0, W=1920, H=1080, **_):
    """Mağara: kavisli tavan, arkada ateş, duvarda gölgeler."""
    out = [Stroke([(0.05 * W, y), (0.05 * W, 0.25 * H), (0.3 * W, 0.08 * H), (0.7 * W, 0.08 * H), (0.95 * W, 0.25 * H), (0.95 * W, y)],
                  6 * s + 1, (110, 90, 70), seed=seed)]
    m, o = mask_from(lambda d, T, ss: d.polygon([T((0.05 * W, 0.25 * H)), T((0.3 * W, 0.08 * H)), T((0.7 * W, 0.08 * H)), T((0.95 * W, 0.25 * H)),
                                                 T((0.95 * W, 0.12 * H)), T((0.05 * W, 0.12 * H))], fill=255), (0, 0, W, 0.3 * H))
    out.append(Fill(m, o, tone=0.35, style="hatch", seed=seed, outline=False))
    if fire:
        out += el_campfire(0.8 * W, y, s * 0.8, seed=seed + 3)
    for k, (gx, gh) in enumerate(((0.2, 0.28), (0.32, 0.22), (0.44, 0.3))):  # duvardaki gölgeler
        it, _ = figure(gx * W, 0.55 * H, gh * H, "stand", 1, tone=0.35, seed=seed + 10 + k)
        out += it
    return out


def el_plank(x, y, s, seed=0, **_):
    w = 700 * s
    out = [Stroke(_rect(x - w / 2, y - 18 * s, x + w / 2, y + 18 * s), 5 * s + 1, (120, 80, 50), seed=seed)]
    for k in range(5):
        xx = x - w / 2 + (k + 0.5) * w / 5
        out.append(Stroke([(xx, y - 18 * s), (xx + 20 * s, y + 18 * s)], 2, (150, 110, 70), 1, seed + k))
    for k in range(6):  # aşağıdaki derinlik çizgileri
        yy = y + 60 * s + k * 50 * s
        out.append(Stroke([(x - w * (0.7 - k * 0.08), yy), (x + w * (0.7 - k * 0.08), yy)], 2, COLORS["grey"], 1, seed + 20 + k))
    for side in (-1, 1):
        out.append(Stroke([(x + side * w * 0.8, y + 20 * s), (x + side * w * 0.35, y + 380 * s)], 3 * s, COLORS["grey"], seed=seed + 40 + side))
    return out


def el_hand(x, y, s, face=1, color="ink", tone=0.85, seed=0, **_):
    """Avuç içi aşağıda, masada duran el silüeti."""
    pts = [(x - 120 * s * face, y), (x - 120 * s * face, y - 70 * s), (x - 40 * s * face, y - 95 * s)]
    for k in range(4):
        fx = x - 10 * s * face + k * 38 * s * face
        pts += [(fx, y - 95 * s), (fx + 6 * s * face, y - 185 * s + k * 12 * s), (fx + 28 * s * face, y - 185 * s + k * 12 * s), (fx + 32 * s * face, y - 95 * s)]
    pts += [(x + 150 * s * face, y - 60 * s), (x + 200 * s * face, y - 110 * s), (x + 215 * s * face, y - 85 * s), (x + 160 * s * face, y)]
    c = COLORS.get(color, INK) if isinstance(color, str) else color
    return [_blob(pts, tone=tone, color=c, seed=seed, smooth=6 * s)]


def el_brush(x, y, s, seed=0, **_):
    return [Stroke([(x, y), (x + 160 * s, y - 120 * s)], 9 * s + 1, (140, 95, 50), seed=seed),
            _blob([(x - 10 * s, y + 5 * s), (x - 60 * s, y + 40 * s), (x - 40 * s, y + 55 * s), (x + 12 * s, y + 18 * s)], tone=0.7, seed=seed + 1)]


def el_snowman(x, y, s, seed=0, **_):
    out = []
    for k, r in enumerate((110, 80, 55)):
        cy = y - sum((110, 80, 55)[:k]) * 2 * s - r * s
        out.append(Stroke(ellipse_pts(x, cy, r * s, r * s, n=30, seed=seed + k), 5 * s + 1, seed=seed + k))
    hy = y - (220 + 160) * s - 55 * s
    out.append(Stroke([(x, hy), (x + 55 * s, hy + 6 * s)], 7 * s, (230, 130, 40), seed=seed + 5))
    for side in (-1, 1):
        out.append(Stroke(ellipse_pts(x + side * 20 * s - 10 * s, hy - 18 * s, 5 * s, 5 * s, n=8), 4 * s, seed=seed + 6))
    return out


def el_spider(x, y, s, seed=0, **_):
    out = [_blob([(x + math.cos(u) * 45 * s, y + math.sin(u) * 35 * s) for u in np.linspace(0, 2 * math.pi, 20)], tone=0.9, seed=seed)]
    for side in (-1, 1):
        for k in range(4):
            a = -0.9 + k * 0.6
            out.append(Stroke([(x + side * 30 * s, y), (x + side * 90 * s, y - 50 * s + k * 30 * s),
                               (x + side * 130 * s, y + 10 * s + k * 25 * s)], 4 * s + 1, seed=seed + k + side * 10))
    out.append(Stroke([(x, y - 35 * s), (x, 0)], 2, COLORS["grey"], 1, seed + 30))
    return out


def el_ear(x, y, s, seed=0, **_):
    return [Stroke(bez((x - 40 * s, y + 120 * s), (x - 160 * s, y - 160 * s), (x + 60 * s, y - 130 * s), 20) +
                   bez((x + 60 * s, y - 130 * s), (x + 150 * s, y + 20 * s), (x, y + 140 * s), 16), 6 * s + 1, seed=seed),
            Stroke(bez((x - 30 * s, y - 40 * s), (x + 40 * s, y - 80 * s), (x + 30 * s, y + 20 * s), 12), 4 * s + 1, seed=seed + 1)]


def el_machine(x, y, s, seed=0, **_):
    """Deneyim makinesi: kasklı koltuk ve kablolar."""
    out = [Stroke([(x - 150 * s, y), (x - 150 * s, y - 180 * s), (x + 150 * s, y - 180 * s), (x + 150 * s, y)], 7 * s + 1, seed=seed),
           Stroke([(x - 150 * s, y - 180 * s), (x - 170 * s, y - 470 * s), (x - 60 * s, y - 470 * s), (x - 40 * s, y - 180 * s)], 7 * s + 1, seed=seed + 1),
           Stroke(bez((x - 200 * s, y - 520 * s), (x - 110 * s, y - 640 * s), (x - 20 * s, y - 520 * s), 16), 7 * s + 1, BLUE, seed=seed + 2)]
    for k in range(3):
        out.append(Stroke(bez((x - 110 * s + k * 30 * s, y - 600 * s), (x + 150 * s, y - 760 * s), (x + 330 * s, y - 400 * s + k * 60 * s), 16),
                          3 * s + 1, seed=seed + 5 + k))
    out.append(Stroke(_rect(x + 300 * s, y - 470 * s, x + 470 * s, y - 220 * s), 5 * s + 1, seed=seed + 9))
    for k in range(3):
        out.append(Stroke(ellipse_pts(x + 345 * s + k * 40 * s, y - 400 * s, 12 * s, 12 * s, n=10), 3 * s, RED if k == 1 else INK, 1, seed + 12 + k))
    return out


def el_door(x, y, s, label=None, open_=False, seed=0, **_):
    w, h = 200 * s, 380 * s
    out = [Stroke(_rect(x - w / 2, y - h, x + w / 2, y), 6 * s + 1, (120, 80, 50), seed=seed),
           Stroke(ellipse_pts(x + w * 0.32, y - h * 0.5, 10 * s, 10 * s, n=10), 4 * s, seed=seed + 1)]
    if open_:
        m, o = mask_from(lambda d, T, ss: d.rectangle([T((x - w / 2 + 6, y - h + 6)), T((x + w / 2 - 6, y - 6))], fill=255),
                         (x - w / 2, y - h, x + w / 2, y))
        out.append(Fill(m, o, tone=0.6, color=(245, 215, 120), seed=seed, outline=False))
    if label:
        out.append(Text(label, x, y - h - 50 * s, 60 * s, INK))
    return out


def el_plug(x, y, s, seed=0, **_):
    out = [Stroke(_rect(x - 60 * s, y - 50 * s, x + 60 * s, y + 50 * s), 6 * s + 1, seed=seed),
           Stroke([(x - 25 * s, y - 50 * s), (x - 25 * s, y - 120 * s)], 9 * s + 1, seed=seed + 1),
           Stroke([(x + 25 * s, y - 50 * s), (x + 25 * s, y - 120 * s)], 9 * s + 1, seed=seed + 2),
           Stroke(bez((x, y + 50 * s), (x + 30 * s, y + 200 * s), (x + 220 * s, y + 240 * s), 16), 7 * s + 1, seed=seed + 3)]
    return out


def el_booth(x, y, s, seed=0, **_):
    """Sensorama: kabin, dürbün gibi ekran, oturan figür."""
    out = [Stroke(_rect(x - 100 * s, y - 520 * s, x + 220 * s, y), 6 * s + 1, (120, 80, 50), seed=seed),
           Stroke(_rect(x - 100 * s, y - 520 * s, x - 10 * s, y - 380 * s), 5 * s + 1, seed=seed + 1),
           Stroke([(x - 260 * s, y), (x - 260 * s, y - 150 * s), (x - 120 * s, y - 150 * s)], 6 * s + 1, seed=seed + 2)]
    for k in range(3):
        out.append(Stroke([(x - 340 * s + k * 15 * s, y - 520 * s + k * 40 * s), (x - 200 * s + k * 15 * s, y - 520 * s + k * 40 * s)],
                          3 * s, BLUE, 1, seed + 5 + k))
    it, _ = figure(x - 200 * s, y, 380 * s, "sit", 1, seed=seed + 9)
    return out + it


def el_sword(x, y, s, seed=0, H=1080, **_):
    out = [Stroke([(x, 0), (x, y - 260 * s)], 2, COLORS["grey"], 1, seed),
           Stroke([(x, y - 260 * s), (x, y + 40 * s)], 10 * s + 1, (150, 150, 160), seed=seed + 1),
           Stroke([(x - 60 * s, y - 200 * s), (x + 60 * s, y - 200 * s)], 10 * s + 1, (110, 80, 50), seed=seed + 2)]
    return out


def el_money(x, y, s, text="$2B", seed=0, **_):
    pts = [(x - 120 * s, y), (x - 140 * s, y - 120 * s), (x - 60 * s, y - 200 * s), (x - 40 * s, y - 240 * s), (x + 40 * s, y - 240 * s),
           (x + 60 * s, y - 200 * s), (x + 140 * s, y - 120 * s), (x + 120 * s, y)]
    return [_blob(pts, tone=0.3, color=(190, 150, 80), seed=seed, smooth=6 * s), Stroke(pts + [pts[0]], 5 * s + 1, (140, 100, 50), seed=seed),
            Text(text, x, y - 90 * s, 70 * s, (140, 100, 50))]


ELEMENTS_EXTRA.update({
    "cave": el_cave, "plank": el_plank, "hand": el_hand, "brush": el_brush, "snowman": el_snowman, "spider": el_spider, "ear": el_ear,
    "machine": el_machine, "door": el_door, "plug": el_plug, "booth": el_booth, "sword": el_sword, "money": el_money,
})


def el_basilisk(x, y, s, toothless=False, faded=False, seed=0, **_):
    """Taçlı yılan (basilisk): kıvrımlı gövde, taç, göz."""
    tone = 0.3 if faded else 0.9
    pts = []
    for i in range(60):
        u = i / 59
        pts.append((x - 380 * s + u * 760 * s, y + 70 * s * math.sin(u * 2.6 * math.pi) * (1 - 0.3 * u)))
    hx, hy = pts[-1]
    m, o = mask_from(lambda d, T, ss: d.line([T(p) for p in pts], fill=255, width=int(48 * s * ss), joint="curve"),
                     (x - 420 * s, y - 120 * s, x + 420 * s, y + 120 * s), smooth=6 * s)
    out = [Fill(m, o, tone=tone, color=(60, 90, 60), seed=seed)]
    head = [(hx - 30 * s, hy - 40 * s), (hx + 80 * s, hy - 30 * s), (hx + 110 * s, hy), (hx + 80 * s, hy + 30 * s), (hx - 30 * s, hy + 35 * s)]
    out.append(_blob(head, tone=tone, color=(60, 90, 60), seed=seed + 1, smooth=4 * s))
    crown = [(hx - 10 * s, hy - 40 * s), (hx, hy - 95 * s), (hx + 20 * s, hy - 55 * s), (hx + 40 * s, hy - 100 * s), (hx + 55 * s, hy - 52 * s),
             (hx + 75 * s, hy - 90 * s), (hx + 80 * s, hy - 35 * s)]
    out.append(_blob(crown, tone=0.9 if not faded else 0.3, color=(220, 175, 60), seed=seed + 2, smooth=2))
    out.append(Stroke(ellipse_pts(hx + 50 * s, hy - 8 * s, 12 * s, 10 * s, n=12), 5 * s, RED, seed=seed + 3))
    if not toothless:
        for k in range(3):
            tx = hx + 70 * s + k * 12 * s
            out.append(Stroke([(tx, hy + 12 * s), (tx + 5 * s, hy + 32 * s)], 3 * s + 1, (240, 240, 240), 1, seed + 4 + k))
    return out


def el_bear(x, y, s, seed=0, **_):
    """Beyaz ayı (kontur)."""
    body = ellipse_pts(x, y, 210 * s, 120 * s, n=40, seed=seed)
    out = [Stroke(body, 6 * s + 1, seed=seed),
           Stroke(ellipse_pts(x + 230 * s, y - 70 * s, 85 * s, 70 * s, n=30, seed=seed + 1), 6 * s + 1, seed=seed + 1)]
    for ex in (x + 185 * s, x + 255 * s):
        out.append(Stroke(ellipse_pts(ex, y - 135 * s, 22 * s, 20 * s, n=14), 5 * s, seed=seed + 2))
    out.append(Stroke(ellipse_pts(x + 300 * s, y - 60 * s, 12 * s, 10 * s, n=10), 5 * s, seed=seed + 3))
    out.append(Stroke(ellipse_pts(x + 250 * s, y - 85 * s, 5 * s, 5 * s, n=8), 4 * s, seed=seed + 4))
    for lx in (x - 140 * s, x - 60 * s, x + 60 * s, x + 140 * s):
        out.append(Stroke([(lx, y + 90 * s), (lx, y + 190 * s), (lx + 30 * s, y + 190 * s)], 6 * s + 1, seed=seed + 5))
    return out


def el_post(x, y, s, deleted=False, title="Roko · 2010", seed=0, **_):
    w, h = 620 * s, 380 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 5 * s + 1, seed=seed),
           Stroke(ellipse_pts(x - w / 2 + 45 * s, y - h / 2 + 45 * s, 22 * s, 22 * s, n=14), 4 * s, seed=seed + 1),
           Text(title, x - w / 2 + 180 * s, y - h / 2 + 45 * s, 34 * s, INK)]
    for k in range(5):
        yy = y - h / 2 + 110 * s + k * 48 * s
        out.append(Stroke([(x - w / 2 + 30 * s, yy), (x + w / 2 - 30 * s - (k % 2) * 90 * s, yy)], 3 * s, COLORS["grey"], 1, seed + 2 + k))
    if deleted:
        out += el_cross(x, y, s * 1.8, seed=seed + 9)
        out.append(Text("DELETED", x, y + h / 2 + 60 * s, 70 * s, RED))
    return out


def el_lock(x, y, s, text=None, seed=0, **_):
    out = el_padlock(x, y, s * 1.2, seed=seed)
    if text:
        out.append(Text(text, x, y + 200 * s, 60 * s, RED))
    return out


def el_balance(x, y, s, tilt=0.0, left=None, right=None, seed=0, **_):
    out = [Stroke([(x, y + 260 * s), (x, y - 160 * s)], 7 * s + 1, seed=seed),
           Stroke([(x - 120 * s, y + 260 * s), (x + 120 * s, y + 260 * s)], 7 * s + 1, seed=seed + 1)]
    lx, ly = x - 300 * s, y - 160 * s + tilt * 120 * s
    rx, ry = x + 300 * s, y - 160 * s - tilt * 120 * s
    out.append(Stroke([(lx, ly), (rx, ry)], 6 * s + 1, seed=seed + 2))
    for k, (px, py, lab) in enumerate(((lx, ly, left), (rx, ry, right))):
        out.append(Stroke([(px, py), (px - 90 * s, py + 150 * s)], 2, COLORS["grey"], 1, seed + 5 + k))
        out.append(Stroke([(px, py), (px + 90 * s, py + 150 * s)], 2, COLORS["grey"], 1, seed + 7 + k))
        out.append(Stroke(bez((px - 110 * s, py + 150 * s), (px, py + 230 * s), (px + 110 * s, py + 150 * s), 14), 5 * s + 1, (190, 140, 50), seed=seed + 9 + k))
        if lab:
            out.append(Text(lab, px, py + 95 * s, 70 * s, RED if k == 0 else BLUE))
    return out


def el_ai(x, y, s, seed=0, **_):
    """Yapay zekâ çekirdeği: parlayan daire, devre çizgileri."""
    out = []
    m, o = mask_from(lambda d, T, ss: d.ellipse([T((x - 110 * s, y - 110 * s)), T((x + 110 * s, y + 110 * s))], fill=255),
                     (x - 112 * s, y - 112 * s, x + 112 * s, y + 112 * s), smooth=3)
    out.append(Fill(m, o, tone=0.85, color=(90, 130, 200), seed=seed))
    out.append(Stroke(ellipse_pts(x, y, 60 * s, 60 * s, n=24, seed=seed), 5 * s, (240, 240, 250), 1, seed + 1))
    for k in range(8):
        a = k * math.pi / 4
        p0 = (x + math.cos(a) * 130 * s, y + math.sin(a) * 130 * s)
        p1 = (x + math.cos(a) * 220 * s, y + math.sin(a) * 220 * s)
        p2 = (p1[0] + (40 * s if k % 2 else 0), p1[1] + (0 if k % 2 else 40 * s))
        out.append(Stroke([p0, p1, p2], 4 * s, (90, 130, 200), 1, seed + 2 + k))
        out.append(Stroke(ellipse_pts(p2[0], p2[1], 10 * s, 10 * s, n=10), 4 * s, (90, 130, 200), 1, seed + 12 + k))
    return out


def el_timeline(x, y, s, left="now", right="future", seed=0, W=1920, **_):
    x0, x1 = 0.1 * W, 0.9 * W
    out = [Stroke([(x0, y), (x1, y)], 6 * s + 1, seed=seed),
           Stroke([(x1 - 30 * s, y - 20 * s), (x1, y), (x1 - 30 * s, y + 20 * s)], 6 * s + 1, seed=seed + 1)]
    for k in range(7):
        xx = x0 + k * (x1 - x0) / 7
        out.append(Stroke([(xx, y - 15 * s), (xx, y + 15 * s)], 3 * s, seed=seed + 2 + k))
    out.append(Text(left, x0 + 60 * s, y + 60 * s, 50 * s, INK))
    out.append(Text(right, x1 - 80 * s, y + 60 * s, 50 * s, BLUE))
    return out


def el_film(x, y, s, text="SPOILER", seed=0, **_):
    w, h = 600 * s, 200 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 5 * s + 1, seed=seed)]
    for k in range(8):
        xx = x - w / 2 + 30 * s + k * 75 * s
        out.append(Stroke(_rect(xx, y - h / 2 + 12 * s, xx + 30 * s, y - h / 2 + 32 * s), 3 * s, seed=seed + k))
        out.append(Stroke(_rect(xx, y + h / 2 - 32 * s, xx + 30 * s, y + h / 2 - 12 * s), 3 * s, seed=seed + 10 + k))
    out.append(Text(text, x, y, 70 * s, RED))
    return out


def el_magnifier(x, y, s, seed=0, **_):
    return [Stroke(ellipse_pts(x, y, 110 * s, 110 * s, n=36, seed=seed), 9 * s + 1, seed=seed),
            Stroke([(x + 80 * s, y + 80 * s), (x + 230 * s, y + 230 * s)], 18 * s + 1, (120, 80, 50), seed=seed + 1),
            Stroke([(x - 50 * s, y - 40 * s), (x - 20 * s, y - 70 * s)], 4 * s, (170, 190, 210), 1, seed + 2)]


def el_calendar(x, y, s, text="tomorrow", seed=0, **_):
    w, h = 320 * s, 300 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 6 * s + 1, seed=seed),
           Stroke([(x - w / 2, y - h / 2 + 70 * s), (x + w / 2, y - h / 2 + 70 * s)], 5 * s, RED, seed=seed + 1)]
    for k in range(3):
        for j in range(4):
            cx, cy = x - w / 2 + 50 * s + j * 75 * s, y - h / 2 + 115 * s + k * 55 * s
            out.append(Stroke(_rect(cx - 15 * s, cy - 15 * s, cx + 15 * s, cy + 15 * s), 2, COLORS["grey"], 1, seed + 3 + k * 4 + j))
    out.append(Text(text, x, y + h / 2 + 50 * s, 46 * s, BLUE))
    return out


def el_warning(x, y, s, seed=0, **_):
    out = [Stroke([(x, y - 170 * s), (x + 190 * s, y + 140 * s), (x - 190 * s, y + 140 * s), (x, y - 170 * s)], 10 * s + 1, RED, seed=seed),
           Stroke([(x, y - 60 * s), (x, y + 50 * s)], 14 * s + 1, RED, seed=seed + 1),
           Stroke(ellipse_pts(x, y + 95 * s, 10 * s, 10 * s, n=10), 10 * s, RED, seed=seed + 2)]
    return out


def el_countdown(x, y, s, n=10, seed=0, **_):
    out = [Stroke(ellipse_pts(x, y, 200 * s, 200 * s, n=40, seed=seed), 7 * s + 1, seed=seed)]
    for k in range(12):
        a = k * math.pi / 6
        out.append(Stroke([(x + math.cos(a) * 170 * s, y + math.sin(a) * 170 * s), (x + math.cos(a) * 195 * s, y + math.sin(a) * 195 * s)], 3 * s, seed=seed + k))
    out.append(Text(str(n), x, y, 150 * s, RED))
    return out


ELEMENTS_EXTRA.update({
    "basilisk": el_basilisk, "bear": el_bear, "post": el_post, "lock": el_lock, "balance": el_balance, "ai": el_ai, "timeline": el_timeline,
    "film": el_film, "magnifier": el_magnifier, "calendar": el_calendar, "warning": el_warning, "countdown": el_countdown,
})


# ----------------------------------------------------------- NVIDIA videosu
GREEN = (90, 150, 50)


def el_sink(x, y, s, seed=0, **_):
    """Lavabo ve tabak yığını."""
    out = [Stroke([(x - 300 * s, y), (x + 300 * s, y)], 7 * s + 1, seed=seed),
           Stroke(bez((x - 220 * s, y), (x, y + 220 * s), (x + 220 * s, y), 20), 6 * s + 1, seed=seed + 1),
           Stroke([(x + 160 * s, y), (x + 160 * s, y - 170 * s), (x + 60 * s, y - 170 * s), (x + 60 * s, y - 120 * s)], 7 * s + 1, (130, 130, 140), seed=seed + 2)]
    for k in range(6):
        yy = y - 20 * s - k * 26 * s
        out.append(Stroke(ellipse_pts(x - 120 * s + (k % 2) * 10 * s, yy, 110 * s, 16 * s, n=24, seed=seed + k), 4 * s + 1, BLUE if k % 2 else INK, seed=seed + 3 + k))
    for k in range(3):
        out.append(Stroke(ellipse_pts(x + 110 * s + k * 30 * s, y - 230 * s - k * 40 * s, 12 * s, 12 * s, n=10), 3 * s, (150, 180, 210), 1, seed + 12 + k))
    return out


def el_gpu(x, y, s, label=None, seed=0, **_):
    """Ekran kartı: kart, fan(lar), konnektör."""
    w, h = 620 * s, 260 * s
    out = [_blob([(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x + w / 2, y + h / 2), (x - w / 2, y + h / 2)], tone=0.35, color=GREEN, seed=seed),
           Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 6 * s + 1, seed=seed + 1)]
    for k, fx in enumerate((x - 140 * s, x + 140 * s)):
        out.append(Stroke(ellipse_pts(fx, y, 95 * s, 95 * s, n=32, seed=seed + k), 5 * s + 1, seed=seed + 2 + k))
        for j in range(5):
            a = j * 2 * math.pi / 5
            out.append(Stroke(bez((fx, y), (fx + math.cos(a) * 60 * s, y + math.sin(a) * 30 * s), (fx + math.cos(a + 0.6) * 85 * s, y + math.sin(a + 0.6) * 85 * s), 8),
                              3 * s, seed=seed + 5 + j))
    for k in range(10):
        xx = x - w / 2 + 40 * s + k * 26 * s
        out.append(Stroke([(xx, y + h / 2), (xx, y + h / 2 + 30 * s)], 4 * s, (190, 150, 60), 1, seed + 20 + k))
    if label:
        out.append(Text(label, x, y - h / 2 - 55 * s, 56 * s, INK))
    return out


def el_chip(x, y, s, glow=False, seed=0, **_):
    r = 150 * s
    out = []
    if glow:
        m, o = mask_from(lambda d, T, ss: d.ellipse([T((x - r * 1.8, y - r * 1.8)), T((x + r * 1.8, y + r * 1.8))], fill=255),
                         (x - r * 1.8, y - r * 1.8, x + r * 1.8, y + r * 1.8), smooth=r * 0.3)
        out.append(Fill(m, o, tone=0.35, color=(245, 205, 110), seed=seed, outline=False))
    out += [_blob([(x - r, y - r), (x + r, y - r), (x + r, y + r), (x - r, y + r)], tone=0.9, color=(50, 55, 60), seed=seed + 1),
            Stroke(_rect(x - r * 0.55, y - r * 0.55, x + r * 0.55, y + r * 0.55), 4 * s + 1, GREEN, seed=seed + 2)]
    for k in range(6):
        d = -r * 0.8 + k * r * 0.32
        for (a, b) in (((x + d, y - r), (x + d, y - r - 45 * s)), ((x + d, y + r), (x + d, y + r + 45 * s)),
                       ((x - r, y + d), (x - r - 45 * s, y + d)), ((x + r, y + d), (x + r + 45 * s, y + d))):
            out.append(Stroke([a, b], 6 * s, (170, 170, 175), 1, seed + 3 + k))
    return out


def el_shovel(x, y, s, seed=0, **_):
    out = [Stroke([(x, y - 330 * s), (x, y + 80 * s)], 12 * s + 1, (130, 90, 55), seed=seed),
           Stroke([(x - 50 * s, y - 330 * s), (x + 50 * s, y - 330 * s)], 12 * s + 1, (130, 90, 55), seed=seed + 1)]
    blade = [(x - 80 * s, y + 80 * s), (x + 80 * s, y + 80 * s), (x + 70 * s, y + 220 * s), (x, y + 270 * s), (x - 70 * s, y + 220 * s)]
    out += [_blob(blade, tone=0.6, color=(130, 130, 140), seed=seed + 2), Stroke(blade + [blade[0]], 5 * s + 1, seed=seed + 3)]
    return out


def el_network(x, y, s, extra=False, seed=0, **_):
    """Tek düğümlü ağ (yıldız); extra: düğümler arasında yedek bağlantılar."""
    rnd = random.Random(seed)
    nodes = [(x + math.cos(k * math.pi / 4) * 380 * s * (0.8 + 0.2 * rnd.random()), y + math.sin(k * math.pi / 4) * 260 * s) for k in range(8)]
    out = []
    for i, p in enumerate(nodes):
        out.append(Stroke([(x, y), p], 4 * s + 1, seed=seed + i))
    if extra:
        for i in range(8):
            out.append(Stroke([nodes[i], nodes[(i + 1) % 8]], 5 * s + 1, BLUE, seed=seed + 20 + i))
    for i, p in enumerate(nodes):
        out.append(Stroke(ellipse_pts(p[0], p[1], 26 * s, 26 * s, n=14), 6 * s, seed=seed + 40 + i))
    m, o = mask_from(lambda d, T, ss: d.ellipse([T((x - 60 * s, y - 60 * s)), T((x + 60 * s, y + 60 * s))], fill=255),
                     (x - 62 * s, y - 62 * s, x + 62 * s, y + 62 * s))
    out.append(Fill(m, o, tone=0.9, color=RED, seed=seed + 60))
    return out


def el_capitol(x, y, s, seed=0, **_):
    """Kongre binası: kubbe, sütunlar, basamaklar."""
    out = [Stroke([(x - 380 * s, y), (x + 380 * s, y)], 7 * s + 1, seed=seed),
           Stroke(_rect(x - 330 * s, y - 230 * s, x + 330 * s, y - 30 * s), 5 * s + 1, seed=seed + 1),
           Stroke([(x - 360 * s, y - 15 * s), (x + 360 * s, y - 15 * s)], 4 * s, seed=seed + 2)]
    for k in range(9):
        xx = x - 280 * s + k * 70 * s
        out.append(Stroke([(xx, y - 210 * s), (xx, y - 30 * s)], 5 * s, seed=seed + 3 + k))
    out.append(Stroke(_rect(x - 160 * s, y - 300 * s, x + 160 * s, y - 230 * s), 5 * s + 1, seed=seed + 15))
    out.append(Stroke(bez((x - 140 * s, y - 300 * s), (x, y - 560 * s), (x + 140 * s, y - 300 * s), 24), 6 * s + 1, seed=seed + 16))
    out.append(Stroke([(x, y - 430 * s), (x, y - 500 * s)], 6 * s + 1, seed=seed + 17))
    return out


def el_newspaper(x, y, s, head="REPORT", seed=0, **_):
    w, h = 560 * s, 420 * s
    out = [_blob([(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x + w / 2, y + h / 2), (x - w / 2, y + h / 2)], tone=0.15, color=(200, 195, 180), seed=seed),
           Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 5 * s + 1, seed=seed + 1),
           Text(head, x, y - h / 2 + 70 * s, 64 * s, INK),
           Stroke([(x - w / 2 + 30 * s, y - h / 2 + 120 * s), (x + w / 2 - 30 * s, y - h / 2 + 120 * s)], 4 * s, seed=seed + 2)]
    for c in range(2):
        for k in range(5):
            yy = y - h / 2 + 160 * s + k * 42 * s
            x0 = x - w / 2 + 30 * s + c * (w / 2)
            out.append(Stroke([(x0, yy), (x0 + w / 2 - 60 * s - (k % 3) * 30 * s, yy)], 3 * s, COLORS["grey"], 1, seed + 3 + c * 5 + k))
    return out


def el_halo(x, y, s, cracked=False, seed=0, **_):
    out = [Stroke(ellipse_pts(x, y, 170 * s, 45 * s, n=40, seed=seed), 12 * s + 1, (225, 180, 70), seed=seed)]
    if cracked:
        out.append(Stroke([(x + 20 * s, y - 60 * s), (x - 10 * s, y - 10 * s), (x + 30 * s, y + 15 * s), (x - 5 * s, y + 70 * s)], 6 * s + 1, INK, seed=seed + 1))
    return out


def el_bridge(x, y, s, cracked=False, seed=0, W=1920, **_):
    out = [Stroke([(x - 700 * s, y), (x + 700 * s, y)], 9 * s + 1, seed=seed),
           Stroke(bez((x - 700 * s, y), (x, y - 330 * s), (x + 700 * s, y), 30), 5 * s + 1, seed=seed + 1)]
    for k in range(5):
        px = x - 560 * s + k * 280 * s
        tilt = 40 * s if (cracked and k == 2) else 0
        out.append(Stroke([(px, y), (px + tilt, y + 260 * s)], 14 * s + 1, seed=seed + 2 + k))
    for k in range(13):
        px = x - 600 * s + k * 100 * s
        u = (px - (x - 700 * s)) / (1400 * s)
        top = y - 4 * u * (1 - u) * 165 * s
        out.append(Stroke([(px, top), (px, y)], 2 * s + 1, COLORS["grey"], 1, seed + 10 + k))
    if cracked:
        cx = x
        out.append(Stroke([(cx - 20 * s, y + 40 * s), (cx + 15 * s, y + 100 * s), (cx - 10 * s, y + 160 * s), (cx + 20 * s, y + 230 * s)], 6 * s, RED, seed=seed + 30))
    return out


def el_seesaw(x, y, s, seed=0, **_):
    out = [Stroke([(x - 90 * s, y), (x, y - 120 * s), (x + 90 * s, y), (x - 90 * s, y)], 6 * s + 1, seed=seed),
           Stroke([(x - 560 * s, y - 40 * s), (x + 560 * s, y - 200 * s)], 9 * s + 1, (130, 90, 55), seed=seed + 1)]
    it, _ = figure(x - 470 * s, y - 50 * s, 240 * s, "stand", 1, seed=seed + 3)
    out += it
    for k in range(6):
        bx = x + 230 * s + k * 55 * s
        by = y - 170 * s - (bx - x) * 0.143
        hgt = (80 + (k * 37) % 90) * s
        out.append(Stroke(_rect(bx, by - hgt, bx + 45 * s, by), 4 * s + 1, BLUE, seed=seed + 10 + k))
    return out


def el_factory(x, y, s, seed=0, **_):
    out = [Stroke([(x - 300 * s, y), (x - 300 * s, y - 200 * s), (x - 180 * s, y - 280 * s), (x - 180 * s, y - 200 * s), (x - 60 * s, y - 280 * s),
                   (x - 60 * s, y - 200 * s), (x + 60 * s, y - 280 * s), (x + 60 * s, y - 200 * s), (x + 300 * s, y - 200 * s), (x + 300 * s, y), (x - 300 * s, y)], 6 * s + 1, seed=seed),
           Stroke(_rect(x + 150 * s, y - 460 * s, x + 220 * s, y - 200 * s), 6 * s + 1, seed=seed + 1)]
    for k in range(3):
        cx, cy = x + 185 * s + k * 50 * s, y - 520 * s - k * 60 * s
        out.append(Stroke(ellipse_pts(cx, cy, (40 + k * 15) * s, (28 + k * 10) * s, n=20, seed=seed + k), 4 * s, COLORS["grey"], 1, seed + 2 + k))
    bolt = [(x - 30 * s, y - 470 * s), (x - 110 * s, y - 330 * s), (x - 40 * s, y - 330 * s), (x - 100 * s, y - 200 * s)]
    out.append(Stroke(bolt, 10 * s + 1, (230, 180, 40), seed=seed + 8))
    return out


def el_piggy(x, y, s, seed=0, **_):
    body = ellipse_pts(x, y, 200 * s, 140 * s, n=40, seed=seed)
    out = [_blob(body, tone=0.35, color=(220, 140, 150), seed=seed), Stroke(body, 6 * s + 1, seed=seed + 1),
           Stroke(ellipse_pts(x + 200 * s, y - 10 * s, 35 * s, 45 * s, n=16), 5 * s + 1, seed=seed + 2),
           Stroke([(x - 50 * s, y - 145 * s), (x + 50 * s, y - 145 * s)], 8 * s + 1, seed=seed + 3)]
    for lx in (x - 110 * s, x + 100 * s):
        out.append(Stroke([(lx, y + 120 * s), (lx, y + 190 * s)], 12 * s + 1, seed=seed + 4))
    out.append(Stroke(ellipse_pts(x + 120 * s, y - 50 * s, 8 * s, 8 * s, n=8), 6 * s, seed=seed + 5))
    return out


def el_workers(x, y, s, n=3, small=False, seed=0, **_):
    """n figür yan yana (CPU = 3 iri, GPU = çok sayıda küçük)."""
    out = []
    if small:
        cols = 12
        for k in range(n):
            r, c = divmod(k, cols)
            it, _ = figure(x - 330 * s + c * 60 * s, y - r * 110 * s, 100 * s, "stand", 1, seed=seed + k)
            out += it
    else:
        for k in range(n):
            it, _ = figure(x - 220 * s + k * 220 * s, y, 360 * s, "think" if k == 1 else "stand", 1, seed=seed + k)
            out += it
    return out


def el_table(x, y, s, seed=0, **_):
    """Restoran masası, üç kahve fincanı, peçetede çip çizimi."""
    out = [Stroke([(x - 340 * s, y), (x + 340 * s, y)], 9 * s + 1, (130, 90, 55), seed=seed),
           Stroke([(x - 260 * s, y), (x - 260 * s, y + 220 * s)], 8 * s + 1, (130, 90, 55), seed=seed + 1),
           Stroke([(x + 260 * s, y), (x + 260 * s, y + 220 * s)], 8 * s + 1, (130, 90, 55), seed=seed + 2)]
    for k, cx in enumerate((x - 230 * s, x + 200 * s, x + 280 * s)):
        out.append(Stroke([(cx - 30 * s, y - 70 * s), (cx - 25 * s, y), (cx + 25 * s, y), (cx + 30 * s, y - 70 * s)], 5 * s + 1, seed=seed + 3 + k))
        out.append(Stroke(bez((cx + 30 * s, y - 55 * s), (cx + 60 * s, y - 40 * s), (cx + 28 * s, y - 20 * s), 8), 4 * s, seed=seed + 6 + k))
    out.append(Stroke([(x - 120 * s, y - 8 * s), (x - 90 * s, y - 70 * s), (x + 110 * s, y - 70 * s), (x + 80 * s, y - 8 * s), (x - 120 * s, y - 8 * s)], 4 * s, seed=seed + 9))
    out.append(Stroke(_rect(x - 30 * s, y - 58 * s, x + 30 * s, y - 20 * s), 3 * s + 1, GREEN, seed=seed + 10))
    return out


ELEMENTS_EXTRA.update({
    "sink": el_sink, "gpu": el_gpu, "chip": el_chip, "shovel": el_shovel, "network": el_network, "capitol": el_capitol,
    "newspaper": el_newspaper, "halo": el_halo, "bridge": el_bridge, "seesaw": el_seesaw, "factory": el_factory, "piggy": el_piggy,
    "workers": el_workers, "table": el_table,
})


# ----------------------------------------------------------- İnsanlık videosu
def _quad(x, y, s, body, head, legs, tail=None, color=INK, tone=0.85, seed=0, extra=()):
    """Dört ayaklı silüet: body (poligon, göreli), head (poligon), legs [(x0,y0,x1,y1)], tail (çizgi)."""
    P = lambda pts: [(x + px * s, y + py * s) for px, py in pts]
    out = [_blob(P(body), tone=tone, color=color, seed=seed, smooth=6 * s), _blob(P(head), tone=tone, color=color, seed=seed + 1, smooth=4 * s)]
    for k, (a, b, c, d) in enumerate(legs):
        out.append(Stroke([(x + a * s, y + b * s), (x + c * s, y + d * s)], 16 * s + 2, color, seed=seed + 2 + k))
    if tail:
        out.append(Stroke(P(tail), 7 * s + 1, color, seed=seed + 9))
    for e in extra:
        out.append(e)
    return out


def el_leopard(x, y, s, face=1, seed=0, **_):
    f = face
    body = [(-150 * f, -40), (-60 * f, -70), (90 * f, -65), (150 * f, -40), (140 * f, 30), (-140 * f, 35)]
    head = [(140 * f, -60), (215 * f, -85), (250 * f, -55), (235 * f, -20), (160 * f, -10)]
    legs = [(-120 * f, 20, -130 * f, 140), (-80 * f, 25, -60 * f, 140), (90 * f, 20, 80 * f, 140), (130 * f, 20, 150 * f, 140)]
    tail = [(-145 * f, -30), (-230 * f, 0), (-260 * f, 80), (-230 * f, 110)]
    out = _quad(x, y, s, body, head, legs, tail, color=(170, 120, 50), tone=0.75, seed=seed)
    rnd = random.Random(seed)
    for k in range(14):
        sx, sy = x + rnd.uniform(-130, 130) * s, y + rnd.uniform(-55, 20) * s
        out.append(Stroke(ellipse_pts(sx, sy, 9 * s, 8 * s, n=8), 4 * s, INK, 1, seed + 20 + k))
    return out


def el_antelope(x, y, s, face=1, tired=False, horns=True, seed=0, **_):
    f = face
    body = [(-130 * f, -30), (110 * f, -40), (140 * f, 10), (-120 * f, 25)]
    head = [(110 * f, -40), (150 * f, -130), (200 * f, -120), (165 * f, -30)] if not tired else [(120 * f, -10), (200 * f, 30), (210 * f, 60), (150 * f, 40)]
    legs = [(-110 * f, 10, -115 * f, 150), (-80 * f, 15, -70 * f, 150), (90 * f, 10, 95 * f, 150), (120 * f, 10, 130 * f, 150)]
    show_horns = horns
    horns = (150 * f, -130, 140 * f, -230) if not tired else (200 * f, 30, 260 * f, -20)
    out = _quad(x, y, s, body, head, legs, color=(150, 105, 60), tone=0.7, seed=seed)
    if not show_horns:
        return out
    out.append(Stroke([(x + horns[0] * s, y + horns[1] * s), (x + horns[2] * s, y + horns[3] * s)], 6 * s + 1, seed=seed + 30))
    return out


def el_mammoth(x, y, s, faded=False, seed=0, **_):
    tone = 0.3 if faded else 0.85
    body = [(-200, -60), (-120, -180), (60, -190), (170, -120), (190, 40), (-190, 50)]
    head = [(150, -170), (250, -150), (270, -60), (210, 0), (160, -40)]
    legs = [(-150, 30, -150, 200), (-90, 30, -90, 200), (100, 30, 100, 200), (160, 30, 160, 200)]
    out = _quad(x, y, s, body, head, legs, color=(110, 80, 60), tone=tone, seed=seed)
    out.append(Stroke(bez((x + 250 * s, y - 60 * s), (x + 300 * s, y + 100 * s), (x + 250 * s, y + 160 * s), 14), 18 * s + 1, (110, 80, 60), seed=seed + 31))
    out.append(Stroke(bez((x + 230 * s, y - 20 * s), (x + 360 * s, y + 20 * s), (x + 340 * s, y - 110 * s), 14), 9 * s + 1, (235, 225, 200), seed=seed + 32))
    return out


def el_spear(x, y, s, angle=-0.35, seed=0, **_):
    L = 520 * s
    dx, dy = math.cos(angle) * L / 2, math.sin(angle) * L / 2
    tip = [(x + dx, y + dy), (x + dx * 1.18, y + dy * 1.18)]
    return [Stroke([(x - dx, y - dy), (x + dx, y + dy)], 8 * s + 1, (130, 90, 55), seed=seed),
            Stroke(tip, 16 * s + 1, (120, 120, 130), seed=seed + 1)]


def el_fish(x, y, s, label=None, color="ink", seed=0, **_):
    c = COLORS.get(color, INK)
    body = ellipse_pts(x, y, 120 * s, 45 * s, n=30, seed=seed)
    out = [Stroke(body, 5 * s + 1, c, seed=seed),
           Stroke([(x - 115 * s, y), (x - 190 * s, y - 50 * s), (x - 190 * s, y + 50 * s), (x - 115 * s, y)], 5 * s + 1, c, seed=seed + 1),
           Stroke(ellipse_pts(x + 70 * s, y - 10 * s, 6 * s, 6 * s, n=8), 5 * s, c, seed=seed + 2)]
    if label:
        out.append(Text(label, x, y + 100 * s, 50 * s, c))
    return out


def el_skull(x, y, s, marks=True, seed=0, **_):
    out = [Stroke(ellipse_pts(x, y - 30 * s, 120 * s, 110 * s, n=36, seed=seed), 6 * s + 1, seed=seed),
           Stroke([(x - 70 * s, y + 60 * s), (x - 60 * s, y + 130 * s), (x + 60 * s, y + 130 * s), (x + 70 * s, y + 60 * s)], 6 * s + 1, seed=seed + 1)]
    for ex in (x - 45 * s, x + 45 * s):
        m, o = mask_from(lambda d, T, ss, ex=ex: d.ellipse([T((ex - 30 * s, y - 40 * s)), T((ex + 30 * s, y + 15 * s))], fill=255),
                         (ex - 32 * s, y - 42 * s, ex + 32 * s, y + 17 * s))
        out.append(Fill(m, o, tone=0.9, seed=seed + 2))
    if marks:
        for k in range(2):
            mx = x - 25 * s + k * 50 * s
            out.append(Stroke(ellipse_pts(mx, y - 110 * s, 10 * s, 10 * s, n=10), 6 * s, RED, seed=seed + 5 + k))
    return out


def el_sun(x, y, s, seed=0, **_):
    m, o = mask_from(lambda d, T, ss: d.ellipse([T((x - 80 * s, y - 80 * s)), T((x + 80 * s, y + 80 * s))], fill=255),
                     (x - 82 * s, y - 82 * s, x + 82 * s, y + 82 * s))
    out = [Fill(m, o, tone=0.9, color=(240, 190, 60), seed=seed)]
    for k in range(12):
        a = k * math.pi / 6
        out.append(Stroke([(x + math.cos(a) * 110 * s, y + math.sin(a) * 110 * s), (x + math.cos(a) * 160 * s, y + math.sin(a) * 160 * s)], 6 * s, (230, 170, 40), seed=seed + k))
    return out


def el_meat(x, y, s, cooked=False, seed=0, **_):
    col = (150, 90, 50) if cooked else (200, 80, 80)
    pts = [(x - 130 * s, y - 40 * s), (x - 40 * s, y - 100 * s), (x + 90 * s, y - 80 * s), (x + 130 * s, y), (x + 60 * s, y + 70 * s), (x - 100 * s, y + 50 * s)]
    out = [_blob(pts, tone=0.8, color=col, seed=seed, smooth=8 * s),
           Stroke([(x + 110 * s, y + 10 * s), (x + 220 * s, y + 60 * s)], 18 * s + 1, (235, 225, 205), seed=seed + 1)]
    if cooked:
        for k in range(3):
            out.append(Stroke(bez((x - 40 * s + k * 50 * s, y - 120 * s), (x - 10 * s + k * 50 * s, y - 170 * s), (x - 40 * s + k * 50 * s, y - 230 * s), 8),
                              4 * s, COLORS["grey"], 1, seed + 2 + k))
    return out


def el_plant(x, y, s, seed=0, **_):
    """Nardoo: dört yapraklı (yonca benzeri) su eğreltisi."""
    out = [Stroke([(x, y), (x, y - 220 * s)], 6 * s + 1, (70, 120, 60), seed=seed)]
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        cx, cy = x + math.cos(a) * 60 * s, y - 220 * s + math.sin(a) * 60 * s
        out.append(_blob(ellipse_pts(cx, cy, 55 * s, 55 * s, n=16, extra=0), tone=0.7, color=(80, 140, 70), seed=seed + 1 + k, smooth=3))
    for k in range(5):
        out.append(Stroke(ellipse_pts(x - 100 * s + k * 50 * s, y + 20 * s, 14 * s, 10 * s, n=10), 4 * s, (120, 90, 60), seed=seed + 8 + k))
    return out


def el_pillar(x, y, s, carved=True, seed=0, **_):
    """Göbeklitepe T-sütunu."""
    out = [_blob([(x - 70 * s, y), (x - 70 * s, y - 380 * s), (x + 70 * s, y - 380 * s), (x + 70 * s, y)], tone=0.35, color=(190, 175, 150), seed=seed),
           Stroke(_rect(x - 70 * s, y - 380 * s, x + 70 * s, y), 5 * s + 1, seed=seed + 1),
           _blob([(x - 170 * s, y - 380 * s), (x - 170 * s, y - 470 * s), (x + 130 * s, y - 470 * s), (x + 130 * s, y - 380 * s)], tone=0.35, color=(190, 175, 150), seed=seed + 2),
           Stroke(_rect(x - 170 * s, y - 470 * s, x + 130 * s, y - 380 * s), 5 * s + 1, seed=seed + 3)]
    if carved:
        out.append(Stroke([(x - 40 * s, y - 330 * s), (x - 40 * s, y - 150 * s), (x - 10 * s, y - 120 * s)], 4 * s, seed=seed + 4))
        out.append(Stroke(bez((x - 20 * s, y - 280 * s), (x + 50 * s, y - 250 * s), (x + 10 * s, y - 210 * s), 10), 4 * s, seed=seed + 5))
    return out


def el_bars(x, y, s, values=(("wild", 4, "green"), ("humans", 36, "blue"), ("livestock", 60, "red")), pct=True, seed=0, **_):
    out = [Stroke([(x - 380 * s, y), (x + 380 * s, y)], 5 * s + 1, seed=seed)]
    cols = {"green": (70, 140, 70), "blue": BLUE, "red": RED}
    n = len(values)
    for k, (lab, v, c) in enumerate(values):
        cx = x - 260 * s + k * 520 * s / max(n - 1, 1)
        h = v / 60 * 420 * s
        col = cols.get(c, INK)
        out.append(_blob([(cx - 70 * s, y), (cx - 70 * s, y - h), (cx + 70 * s, y - h), (cx + 70 * s, y)], tone=0.6, color=col, seed=seed + k))
        if pct:
            out.append(Text(f"{v}%", cx, y - h - 45 * s, 60 * s, col))
        out.append(Text(lab, cx, y + 50 * s, 46 * s, INK))
    return out


def el_ape(x, y, s, face=1, seed=0, **_):
    """Kambur, uzun kollu maymun silüeti."""
    f = face
    body = [(-60 * f, -40), (40 * f, -170), (110 * f, -160), (90 * f, 0), (-70 * f, 20)]
    head = [(90 * f, -230), (150 * f, -225), (160 * f, -170), (100 * f, -160)]
    legs = [(-50 * f, 10, -80 * f, 150), (60 * f, 0, 30 * f, 150), (100 * f, -140, 150 * f, 120), (50 * f, -140, 0 * f, 130)]
    return _quad(x, y, s, body, head, legs, color=(60, 55, 55), tone=0.88, seed=seed)


def el_australia(x, y, s, seed=0, **_):
    pts = [(-300, -60), (-220, -150), (-120, -140), (-60, -220), (20, -180), (60, -260), (120, -150), (220, -60), (290, 40), (240, 170), (130, 220),
           (40, 160), (-60, 150), (-180, 190), (-280, 120), (-320, 20)]
    P = [(x + a * s, y + b * s) for a, b in pts]
    return [_blob(P, tone=0.2, color=(200, 160, 100), seed=seed, smooth=4 * s), Stroke(P + [P[0]], 5 * s + 1, seed=seed + 1)]


ELEMENTS_EXTRA.update({
    "leopard": el_leopard, "antelope": el_antelope, "mammoth": el_mammoth, "spear": el_spear, "fish": el_fish, "skull": el_skull,
    "sun": el_sun, "meat": el_meat, "plant": el_plant, "pillar": el_pillar, "bars": el_bars, "ape": el_ape, "australia": el_australia,
})


# ----------------------------------------------------------- Spor videosu
def el_ball(x, y, s, seed=0, **_):
    r = 70 * s
    out = [_blob(ellipse_pts(x, y, r, r, n=30, extra=0), tone=0.15, color=(240, 240, 235), seed=seed, smooth=2),
           Stroke(ellipse_pts(x, y, r, r, n=30, seed=seed), 5 * s + 1, seed=seed + 1)]
    pent = [(x + math.cos(a) * r * 0.35, y + math.sin(a) * r * 0.35) for a in [k * 2 * math.pi / 5 - math.pi / 2 for k in range(5)]]
    out.append(_blob(pent, tone=0.9, seed=seed + 2))
    for p in pent:
        out.append(Stroke([p, (x + (p[0] - x) * 2.7, y + (p[1] - y) * 2.7)], 3 * s, seed=seed + 3))
    return out


def el_goal(x, y, s, scored=False, seed=0, **_):
    w, h = 560 * s, 240 * s
    out = [Stroke([(x - w / 2, y), (x - w / 2, y - h), (x + w / 2, y - h), (x + w / 2, y)], 9 * s + 1, (240, 240, 240), seed=seed),
           Stroke([(x - w / 2, y), (x - w / 2, y - h), (x + w / 2, y - h), (x + w / 2, y)], 4 * s, INK, seed=seed + 1)]
    for k in range(1, 9):
        xx = x - w / 2 + k * w / 9
        out.append(Stroke([(xx, y - h), (xx, y)], 1.5, COLORS["grey"], 1, seed + 2 + k))
    for k in range(1, 5):
        yy = y - h + k * h / 5
        out.append(Stroke([(x - w / 2, yy), (x + w / 2, yy)], 1.5, COLORS["grey"], 1, seed + 12 + k))
    if scored:
        out += el_ball(x + w * 0.3, y - h * 0.45, s * 0.8, seed=seed + 20)
    return out


def el_stands(x, y, s, n=60, cols=None, seed=0, W=1920, **_):
    """Tribün: sıra sıra kafalar, iki renk atkı."""
    rnd = random.Random(seed)
    cols = cols or [(176, 48, 38), (48, 86, 168)]
    out = []
    per = 15
    for k in range(n):
        r, c = divmod(k, per)
        cx = x - 7 * 60 * s + c * 60 * s + (r % 2) * 30 * s
        cy = y - r * 70 * s
        col = cols[0] if c < per // 2 else cols[1]
        m, o = mask_from(lambda d, T, ss, cx=cx, cy=cy: d.ellipse([T((cx - 20 * s, cy - 48 * s)), T((cx + 20 * s, cy - 8 * s))], fill=255),
                         (cx - 22 * s, cy - 50 * s, cx + 22 * s, cy - 6 * s))
        out.append(Fill(m, o, tone=0.85, seed=seed + k, outline=False))
        out.append(Stroke([(cx - 22 * s, cy), (cx + 22 * s, cy)], 9 * s, col, 1, seed + 200 + k))
    return out


def el_tv(x, y, s, text=None, seed=0, **_):
    w, h = 520 * s, 320 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 8 * s + 1, seed=seed),
           Stroke([(x - 60 * s, y + h / 2), (x - 90 * s, y + h / 2 + 60 * s)], 6 * s, seed=seed + 1),
           Stroke([(x + 60 * s, y + h / 2), (x + 90 * s, y + h / 2 + 60 * s)], 6 * s, seed=seed + 2),
           _blob([(x - w / 2 + 20 * s, y + 40 * s), (x + w / 2 - 20 * s, y + 40 * s), (x + w / 2 - 20 * s, y + h / 2 - 20 * s), (x - w / 2 + 20 * s, y + h / 2 - 20 * s)],
                 tone=0.45, color=(80, 150, 70), seed=seed + 3)]
    out += el_ball(x + 60 * s, y + 10 * s, s * 0.35, seed=seed + 5)
    if text:
        out.append(Text(text, x, y - 70 * s, 60 * s, RED))
    return out


def el_ekg(x, y, s, spike=1.0, color="red", seed=0, **_):
    c = COLORS.get(color, RED)
    pts = []
    for k in range(5):
        bx = x - 400 * s + k * 200 * s
        pts += [(bx, y), (bx + 60 * s, y), (bx + 80 * s, y - 40 * s * spike), (bx + 100 * s, y + 30 * s * spike),
                (bx + 120 * s, y - 160 * s * spike), (bx + 140 * s, y + 60 * s * spike), (bx + 160 * s, y)]
    return [Stroke(pts, 6 * s + 1, c, seed=seed)]


def el_hoop(x, y, s, seed=0, **_):
    out = [Stroke([(x + 120 * s, y + 500 * s), (x + 120 * s, y - 120 * s)], 10 * s + 1, seed=seed),
           Stroke(_rect(x - 60 * s, y - 180 * s, x + 120 * s, y - 20 * s), 6 * s + 1, seed=seed + 1),
           Stroke(ellipse_pts(x - 80 * s, y, 70 * s, 16 * s, n=24), 7 * s + 1, (220, 100, 40), seed=seed + 2)]
    for k in range(5):
        xx = x - 145 * s + k * 32 * s
        out.append(Stroke([(xx, y + 5 * s), (x - 80 * s + (xx - (x - 80 * s)) * 0.5, y + 110 * s)], 2, COLORS["grey"], 1, seed + 3 + k))
    return out


def el_bball(x, y, s, seed=0, **_):
    r = 60 * s
    return [_blob(ellipse_pts(x, y, r, r, n=28, extra=0), tone=0.85, color=(220, 110, 40), seed=seed, smooth=2),
            Stroke([(x - r, y), (x + r, y)], 3 * s, seed=seed + 1), Stroke([(x, y - r), (x, y + r)], 3 * s, seed=seed + 2)]


def el_flag(x, y, s, color="red", text=None, seed=0, **_):
    c = COLORS.get(color, RED) if isinstance(color, str) else tuple(color)
    pts = [(x, y - 300 * s), (x + 240 * s, y - 270 * s), (x + 220 * s, y - 180 * s), (x, y - 160 * s)]
    out = [Stroke([(x, y), (x, y - 310 * s)], 7 * s + 1, (110, 80, 50), seed=seed), _blob(pts, tone=0.8, color=c, seed=seed + 1, smooth=3)]
    if text:
        out.append(Text(text, x + 115 * s, y - 230 * s, 44 * s, (250, 248, 240)))
    return out


def el_chariot(x, y, s, color="blue", seed=0, **_):
    c = COLORS.get(color, BLUE)
    out = el_antelope(x + 150 * s, y - 20 * s, s * 1.1, horns=False, seed=seed)
    out.append(Stroke([(x + 20 * s, y - 60 * s), (x - 140 * s, y - 60 * s), (x - 160 * s, y - 180 * s)], 6 * s + 1, c, seed=seed + 40))
    out.append(Stroke(ellipse_pts(x - 80 * s, y + 40 * s, 70 * s, 70 * s, n=24, seed=seed), 6 * s + 1, seed=seed + 41))
    it, _ = figure(x - 100 * s, y - 60 * s, 260 * s, "reach", 1, seed=seed + 42)
    return out + it


def el_trophy(x, y, s, seed=0, **_):
    gold = (215, 170, 60)
    cup = [(x - 120 * s, y - 260 * s), (x + 120 * s, y - 260 * s), (x + 90 * s, y - 120 * s), (x + 30 * s, y - 80 * s), (x - 30 * s, y - 80 * s), (x - 90 * s, y - 120 * s)]
    return [_blob(cup, tone=0.85, color=gold, seed=seed, smooth=4 * s),
            Stroke(bez((x - 115 * s, y - 230 * s), (x - 210 * s, y - 210 * s), (x - 90 * s, y - 140 * s), 10), 7 * s + 1, gold, seed=seed + 1),
            Stroke(bez((x + 115 * s, y - 230 * s), (x + 210 * s, y - 210 * s), (x + 90 * s, y - 140 * s), 10), 7 * s + 1, gold, seed=seed + 2),
            Stroke([(x, y - 80 * s), (x, y - 20 * s)], 14 * s + 1, gold, seed=seed + 3),
            Stroke(_rect(x - 80 * s, y - 20 * s, x + 80 * s, y + 20 * s), 6 * s + 1, (120, 80, 50), seed=seed + 4)]


def el_score(x, y, s, a="0", b="0", la="", lb="", time=None, seed=0, **_):
    w, h = 620 * s, 220 * s
    out = [_blob([(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x + w / 2, y + h / 2), (x - w / 2, y + h / 2)], tone=0.92, color=(40, 40, 45), seed=seed),
           Text(f"{a} - {b}", x, y + 10 * s, 110 * s, (250, 220, 90))]
    if la:
        out.append(Text(la, x - w / 2 + 70 * s, y - 50 * s, 40 * s, (240, 240, 240)))
    if lb:
        out.append(Text(lb, x + w / 2 - 70 * s, y - 50 * s, 40 * s, (240, 240, 240)))
    if time:
        out.append(Text(time, x, y + h / 2 + 50 * s, 56 * s, RED))
    return out


def el_painting(x, y, s, style="klee", seed=0, **_):
    w, h = 340 * s, 260 * s
    out = [Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 10 * s + 1, (150, 110, 60), seed=seed)]
    rnd = random.Random(seed)
    if style == "klee":
        cols = [(210, 150, 70), (90, 140, 120), (190, 90, 70), (230, 200, 120)]
        for k in range(12):
            cx, cy = x - w / 2 + 20 * s + (k % 4) * 75 * s, y - h / 2 + 20 * s + (k // 4) * 75 * s
            out.append(_blob([(cx, cy), (cx + 70 * s, cy), (cx + 70 * s, cy + 70 * s), (cx, cy + 70 * s)], tone=0.6, color=cols[k % 4], seed=seed + k))
    else:
        out.append(Stroke(ellipse_pts(x - 60 * s, y - 30 * s, 60 * s, 60 * s, n=24), 6 * s + 1, BLUE, seed=seed + 1))
        out.append(Stroke([(x - w / 2 + 30 * s, y + 80 * s), (x + w / 2 - 30 * s, y - 90 * s)], 5 * s, RED, seed=seed + 2))
        out.append(Stroke([(x + 20 * s, y + 90 * s), (x + 110 * s, y - 20 * s), (x + 140 * s, y + 90 * s), (x + 20 * s, y + 90 * s)], 5 * s, (220, 170, 40), seed=seed + 3))
        out.append(Stroke([(x - 150 * s, y - 100 * s), (x + 60 * s, y - 100 * s)], 4 * s, INK, seed=seed + 4))
    return out


ELEMENTS_EXTRA.update({
    "ball": el_ball, "goal": el_goal, "stands": el_stands, "tv": el_tv, "ekg": el_ekg, "hoop": el_hoop, "bball": el_bball,
    "flag": el_flag, "chariot": el_chariot, "trophy": el_trophy, "score": el_score, "painting": el_painting,
})


# ----------------------------------------------------------- Moda videosu
def el_louse(x, y, s, seed=0, **_):
    body = ellipse_pts(x, y, 70 * s, 110 * s, n=28, seed=seed)
    out = [_blob(body, tone=0.6, color=(150, 120, 90), seed=seed, smooth=3), Stroke(body, 4 * s + 1, seed=seed + 1),
           Stroke(ellipse_pts(x, y - 140 * s, 40 * s, 35 * s, n=16), 4 * s + 1, seed=seed + 2)]
    for k in range(3):
        yy = y - 50 * s + k * 50 * s
        for f in (-1, 1):
            out.append(Stroke([(x + f * 65 * s, yy), (x + f * 130 * s, yy - 20 * s), (x + f * 150 * s, yy + 30 * s)], 4 * s + 1, seed=seed + 3 + k))
    out.append(Stroke([(x - 20 * s, y - 170 * s), (x - 50 * s, y - 230 * s)], 3 * s, seed=seed + 9))
    out.append(Stroke([(x + 20 * s, y - 170 * s), (x + 50 * s, y - 230 * s)], 3 * s, seed=seed + 10))
    return out


def el_beads(x, y, s, n=11, seed=0, **_):
    out = [Stroke(bez((x - 300 * s, y - 120 * s), (x, y + 200 * s), (x + 300 * s, y - 120 * s), 30), 3 * s, (120, 90, 60), seed=seed)]
    for k in range(n):
        u = (k + 0.5) / n
        bx = (1 - u) ** 2 * (x - 300 * s) + 2 * (1 - u) * u * x + u ** 2 * (x + 300 * s)
        by = (1 - u) ** 2 * (y - 120 * s) + 2 * (1 - u) * u * (y + 200 * s) + u ** 2 * (y - 120 * s)
        sh = ellipse_pts(bx, by, 26 * s, 34 * s, n=14, extra=0)
        out.append(_blob(sh, tone=0.35, color=(220, 200, 170), seed=seed + k))
        out.append(Stroke(sh + [sh[0]], 3 * s, (120, 90, 60), seed=seed + 20 + k))
        out.append(Stroke(ellipse_pts(bx, by - 10 * s, 6 * s, 6 * s, n=8), 3 * s, INK, 1, seed + 40 + k))
    return out


def el_snail(x, y, s, seed=0, **_):
    """Murex (mor boya salyangozu): dikenli kabuk ve mor damla."""
    shell = [(x - 150 * s, y), (x - 60 * s, y - 120 * s), (x + 60 * s, y - 110 * s), (x + 130 * s, y - 30 * s), (x + 260 * s, y + 10 * s),
             (x + 100 * s, y + 60 * s), (x - 100 * s, y + 60 * s)]
    out = [_blob(shell, tone=0.55, color=(200, 180, 150), seed=seed, smooth=5 * s), Stroke(shell + [shell[0]], 5 * s + 1, seed=seed + 1)]
    for k in range(6):
        sx = x - 110 * s + k * 50 * s
        out.append(Stroke([(sx, y - 90 * s + abs(k - 2) * 15 * s), (sx - 10 * s, y - 150 * s + abs(k - 2) * 15 * s)], 5 * s, seed=seed + 2 + k))
    drop = [(x + 330 * s, y - 60 * s), (x + 360 * s, y + 10 * s), (x + 330 * s, y + 40 * s), (x + 300 * s, y + 10 * s)]
    out.append(_blob(drop, tone=0.9, color=(110, 40, 120), seed=seed + 10, smooth=4 * s))
    return out


def el_heel(x, y, s, color="red", seed=0, **_):
    c = COLORS.get(color, RED)
    sole = [(x - 220 * s, y - 120 * s), (x - 120 * s, y - 140 * s), (x + 60 * s, y - 40 * s), (x + 200 * s, y - 10 * s), (x + 220 * s, y + 10 * s),
            (x + 60 * s, y + 10 * s), (x - 140 * s, y - 80 * s)]
    out = [_blob(sole, tone=0.85, color=(40, 40, 45), seed=seed, smooth=4 * s), Stroke(sole + [sole[0]], 4 * s + 1, seed=seed + 1),
           _blob([(x - 210 * s, y - 100 * s), (x - 170 * s, y - 100 * s), (x - 180 * s, y + 10 * s), (x - 200 * s, y + 10 * s)], tone=0.9, color=c, seed=seed + 2)]
    return out


def el_fez(x, y, s, seed=0, **_):
    pts = [(x - 110 * s, y), (x - 85 * s, y - 190 * s), (x + 85 * s, y - 190 * s), (x + 110 * s, y)]
    return [_blob(pts, tone=0.9, color=(170, 35, 35), seed=seed, smooth=3), Stroke(pts + [pts[0]], 4 * s + 1, seed=seed + 1),
            Stroke([(x, y - 190 * s), (x + 60 * s, y - 140 * s), (x + 70 * s, y - 60 * s)], 5 * s, INK, seed=seed + 2)]


def el_hat(x, y, s, seed=0, **_):
    crown = [(x - 100 * s, y - 20 * s), (x - 90 * s, y - 170 * s), (x + 90 * s, y - 170 * s), (x + 100 * s, y - 20 * s)]
    return [_blob(crown, tone=0.9, color=(60, 55, 55), seed=seed, smooth=3),
            Stroke(bez((x - 210 * s, y - 10 * s), (x, y + 30 * s), (x + 210 * s, y - 10 * s), 16), 14 * s + 1, (60, 55, 55), seed=seed + 1),
            Stroke([(x - 95 * s, y - 50 * s), (x + 95 * s, y - 50 * s)], 10 * s, (150, 40, 40), seed=seed + 2)]


def el_turban(x, y, s, seed=0, **_):
    out = []
    for k in range(4):
        out.append(Stroke(ellipse_pts(x, y - 50 * s - k * 40 * s, 140 * s - k * 15 * s, 55 * s, n=30, extra=0.0, seed=seed + k), 18 * s + 1, (215, 200, 165), seed=seed + k))
        out.append(Stroke(ellipse_pts(x, y - 50 * s - k * 40 * s, 140 * s - k * 15 * s, 55 * s, n=30, extra=0.0, seed=seed + k), 4 * s, (100, 85, 60), 1, seed + 10 + k))
    return out


def el_bag(x, y, s, logo=None, seed=0, **_):
    body = [(x - 170 * s, y - 120 * s), (x + 170 * s, y - 120 * s), (x + 200 * s, y + 120 * s), (x - 200 * s, y + 120 * s)]
    out = [_blob(body, tone=0.75, color=(150, 100, 60), seed=seed, smooth=4 * s), Stroke(body + [body[0]], 5 * s + 1, seed=seed + 1),
           Stroke(bez((x - 100 * s, y - 120 * s), (x, y - 300 * s), (x + 100 * s, y - 120 * s), 16), 8 * s + 1, (110, 70, 40), seed=seed + 2)]
    if logo:
        out.append(Text(logo, x, y, 70 * s, (240, 210, 120)))
    return out


def el_coat(x, y, s, label=None, seed=0, **_):
    pts = [(x - 90 * s, y - 220 * s), (x, y - 180 * s), (x + 90 * s, y - 220 * s), (x + 190 * s, y - 160 * s), (x + 210 * s, y + 40 * s), (x + 150 * s, y + 40 * s),
           (x + 140 * s, y - 60 * s), (x + 140 * s, y + 230 * s), (x - 140 * s, y + 230 * s), (x - 140 * s, y - 60 * s), (x - 150 * s, y + 40 * s),
           (x - 210 * s, y + 40 * s), (x - 190 * s, y - 160 * s)]
    out = [_blob(pts, tone=0.08, color=(250, 250, 250), seed=seed, smooth=3), Stroke(pts + [pts[0]], 5 * s + 1, seed=seed + 1),
           Stroke([(x, y - 180 * s), (x, y + 230 * s)], 3 * s, seed=seed + 2)]
    if label:
        out.append(Text(label, x, y + 300 * s, 54 * s, BLUE))
    return out


def el_peacock(x, y, s, seed=0, **_):
    out = []
    for k in range(15):
        a = math.pi + k * math.pi / 14
        ex, ey = x + math.cos(a) * 330 * s, y + math.sin(a) * 300 * s
        out.append(Stroke([(x, y), (ex, ey)], 4 * s, (60, 120, 90), seed=seed + k))
        out.append(_blob(ellipse_pts(ex, ey, 30 * s, 38 * s, n=12, extra=0), tone=0.8, color=(40, 110, 150), seed=seed + 20 + k, smooth=2))
        out.append(_blob(ellipse_pts(ex, ey, 12 * s, 15 * s, n=10, extra=0), tone=0.9, color=(220, 180, 60), seed=seed + 40 + k, smooth=1))
    body = ellipse_pts(x, y + 30 * s, 50 * s, 80 * s, n=20, extra=0)
    out.append(_blob(body, tone=0.9, color=(30, 80, 150), seed=seed + 60, smooth=3))
    out.append(Stroke([(x, y - 40 * s), (x + 10 * s, y - 120 * s)], 14 * s, (30, 80, 150), seed=seed + 61))
    return out


def el_sewing(x, y, s, seed=0, **_):
    out = [Stroke([(x - 260 * s, y), (x + 260 * s, y)], 8 * s + 1, seed=seed),
           Stroke([(x + 180 * s, y), (x + 180 * s, y - 220 * s), (x - 140 * s, y - 220 * s), (x - 140 * s, y - 80 * s)], 14 * s + 1, (60, 60, 65), seed=seed + 1),
           Stroke([(x - 140 * s, y - 80 * s), (x - 140 * s, y - 20 * s)], 4 * s, (150, 150, 160), seed=seed + 2),
           Stroke(ellipse_pts(x + 230 * s, y - 150 * s, 30 * s, 50 * s, n=14), 6 * s, seed=seed + 3)]
    return out


def el_pile(x, y, s, seed=0, **_):
    rnd = random.Random(seed)
    cols = [(176, 48, 38), (48, 86, 168), (220, 180, 80), (90, 140, 90), (150, 150, 155)]
    out = []
    for k in range(14):
        cx, cy = x + rnd.uniform(-260, 260) * s * (1 - k / 20), y - k * 22 * s
        pts = [(cx - 90 * s, cy), (cx - 60 * s, cy - 50 * s), (cx + 70 * s, cy - 45 * s), (cx + 95 * s, cy + 5 * s)]
        out.append(_blob(pts, tone=0.7, color=cols[k % 5], seed=seed + k, smooth=4 * s))
    return out


ELEMENTS_EXTRA.update({
    "louse": el_louse, "beads": el_beads, "snail": el_snail, "heel": el_heel, "fez": el_fez, "hat": el_hat, "turban": el_turban,
    "bag": el_bag, "coat": el_coat, "peacock": el_peacock, "sewing": el_sewing, "pile": el_pile,
})


# ----------------------------------------------------------- Tartarya videosu
PARCH = (215, 195, 150)


def el_oldmap(x, y, s, label="TARTARIA", faded=False, seed=0, **_):
    w, h = 760 * s, 480 * s
    rnd = random.Random(seed)
    edge = [(x - w / 2 + rnd.uniform(-8, 8) * s, y - h / 2), (x + w / 2, y - h / 2 + rnd.uniform(-8, 8) * s), (x + w / 2 + rnd.uniform(-8, 8) * s, y + h / 2),
            (x - w / 2, y + h / 2 + rnd.uniform(-8, 8) * s)]
    out = [_blob(edge, tone=0.45, color=PARCH, seed=seed, smooth=3), Stroke(edge + [edge[0]], 4 * s + 1, (120, 90, 50), seed=seed + 1)]
    coast = [(x - w * 0.42, y - h * 0.1), (x - w * 0.25, y - h * 0.3), (x, y - h * 0.32), (x + w * 0.25, y - h * 0.25), (x + w * 0.4, y - h * 0.05),
             (x + w * 0.3, y + h * 0.25), (x + w * 0.05, y + h * 0.3), (x - w * 0.2, y + h * 0.22), (x - w * 0.4, y + h * 0.15)]
    out.append(Stroke(coast + [coast[0]], 4 * s, (110, 80, 45), seed=seed + 2))
    if label:
        out.append(Text(label, x, y, 70 * s, (140, 50, 40) if not faded else (190, 170, 140)))
    for k in range(4):
        a = k * math.pi / 2
        out.append(Stroke([(x + w * 0.38, y + h * 0.35), (x + w * 0.38 + math.cos(a) * 40 * s, y + h * 0.35 + math.sin(a) * 40 * s)], 3 * s, (110, 80, 45), seed=seed + 5 + k))
    return out


def el_starfort(x, y, s, n=5, glow=False, seed=0, **_):
    R, r = 330 * s, 200 * s
    pts = []
    for k in range(n * 2):
        a = -math.pi / 2 + k * math.pi / n
        rr = R if k % 2 == 0 else r
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
    out = [_blob(pts, tone=0.35, color=(120, 150, 90), seed=seed, smooth=2), Stroke(pts + [pts[0]], 6 * s + 1, seed=seed + 1)]
    inner = [(x + (px - x) * 0.55, y + (py - y) * 0.55) for px, py in pts]
    out.append(Stroke(inner + [inner[0]], 3 * s, seed=seed + 2))
    big = [(x + (px - x) * 1.15, y + (py - y) * 1.15) for px, py in pts]
    out.append(Stroke(big + [big[0]], 3 * s, (70, 110, 170), seed=seed + 3))
    if glow:
        out.append(Stroke([(x, y), (x - 30 * s, y - 120 * s), (x + 20 * s, y - 160 * s), (x - 10 * s, y - 300 * s)], 9 * s, (230, 180, 40), seed=seed + 4))
    return out


def el_pinboard(x, y, s, n=5, seed=0, **_):
    w, h = 800 * s, 480 * s
    out = [_blob([(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x + w / 2, y + h / 2), (x - w / 2, y + h / 2)], tone=0.55, color=(170, 130, 85), seed=seed),
           Stroke(_rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2), 7 * s + 1, (110, 75, 45), seed=seed + 1)]
    rnd = random.Random(seed)
    pins = []
    for k in range(n):
        px = x - w / 2 + 100 * s + (k % 3) * 280 * s + rnd.uniform(-30, 30) * s
        py = y - h / 2 + 110 * s + (k // 3) * 220 * s + rnd.uniform(-20, 20) * s
        out.append(_blob([(px - 70 * s, py - 50 * s), (px + 70 * s, py - 50 * s), (px + 70 * s, py + 50 * s), (px - 70 * s, py + 50 * s)], tone=0.15, color=(245, 240, 230), seed=seed + 5 + k))
        out.append(Stroke(_rect(px - 70 * s, py - 50 * s, px + 70 * s, py + 50 * s), 2, COLORS["grey"], 1, seed + 20 + k))
        pins.append((px, py - 50 * s))
    for k in range(len(pins) - 1):
        out.append(Stroke([pins[k], pins[k + 1]], 3 * s + 1, RED, 1, seed + 40 + k))
    if len(pins) > 2:
        out.append(Stroke([pins[0], pins[-1]], 3 * s + 1, RED, 1, seed + 60))
    for p in pins:
        out.append(Stroke(ellipse_pts(p[0], p[1], 9 * s, 9 * s, n=8), 7 * s, RED, seed=seed + 70))
    return out


def el_train(x, y, s, kids=True, seed=0, **_):
    out = [Stroke([(x - 520 * s, y), (x + 420 * s, y)], 5 * s + 1, (110, 80, 50), seed=seed)]
    eng = [(x + 120 * s, y - 40 * s), (x + 120 * s, y - 200 * s), (x + 260 * s, y - 200 * s), (x + 260 * s, y - 130 * s), (x + 400 * s, y - 130 * s), (x + 400 * s, y - 40 * s)]
    out.append(_blob(eng, tone=0.9, color=(50, 50, 55), seed=seed + 1))
    out.append(Stroke(_rect(x + 330 * s, y - 230 * s, x + 370 * s, y - 130 * s), 6 * s + 1, seed=seed + 2))
    for k in range(3):
        out.append(Stroke(ellipse_pts(x + 360 * s + k * 45 * s, y - 280 * s - k * 50 * s, (35 + k * 12) * s, (25 + k * 8) * s, n=16), 4 * s, COLORS["grey"], 1, seed + 3 + k))
    for c in range(2):
        cx0 = x - 480 * s + c * 300 * s
        out.append(Stroke(_rect(cx0, y - 190 * s, cx0 + 260 * s, y - 40 * s), 6 * s + 1, (140, 60, 40), seed=seed + 10 + c))
        for wdw in range(3):
            wx = cx0 + 25 * s + wdw * 80 * s
            out.append(Stroke(_rect(wx, y - 160 * s, wx + 55 * s, y - 100 * s), 3 * s, seed=seed + 20 + c * 3 + wdw))
            if kids:
                m, o = mask_from(lambda d, T, ss, wx=wx: d.ellipse([T((wx + 15 * s, y - 150 * s)), T((wx + 40 * s, y - 120 * s))], fill=255),
                                 (wx + 13 * s, y - 152 * s, wx + 42 * s, y - 118 * s))
                out.append(Fill(m, o, tone=0.85, seed=seed + 40 + c * 3 + wdw, outline=False))
    for k in range(6):
        out.append(Stroke(ellipse_pts(x - 430 * s + k * 160 * s, y - 25 * s, 25 * s, 25 * s, n=12), 5 * s, seed=seed + 60 + k))
    return out


def el_palace(x, y, s, faded=False, seed=0, **_):
    col = INK if not faded else (170, 165, 160)
    out = [Stroke([(x - 420 * s, y), (x + 420 * s, y)], 6 * s + 1, col, seed=seed),
           Stroke(_rect(x - 380 * s, y - 220 * s, x + 380 * s, y), 5 * s + 1, col, seed=seed + 1)]
    for k in range(11):
        xx = x - 340 * s + k * 68 * s
        out.append(Stroke([(xx, y - 200 * s), (xx, y - 10 * s)], 4 * s, col, seed=seed + 2 + k))
    out.append(Stroke(_rect(x - 140 * s, y - 300 * s, x + 140 * s, y - 220 * s), 5 * s, col, seed=seed + 15))
    out.append(Stroke(bez((x - 130 * s, y - 300 * s), (x, y - 560 * s), (x + 130 * s, y - 300 * s), 24), 6 * s + 1, col, seed=seed + 16))
    out.append(Stroke([(x, y - 430 * s), (x, y - 520 * s)], 5 * s, col, seed=seed + 17))
    for f in (-1, 1):
        out.append(Stroke(bez((x + f * 330 * s, y - 220 * s), (x + f * 280 * s, y - 360 * s), (x + f * 230 * s, y - 220 * s), 14), 5 * s, col, seed=seed + 18))
    return out


def el_spire(x, y, s, bolt=True, rod=False, seed=0, **_):
    out = [Stroke([(x - 90 * s, y), (x - 90 * s, y - 260 * s), (x + 90 * s, y - 260 * s), (x + 90 * s, y)], 6 * s + 1, seed=seed),
           Stroke([(x - 110 * s, y - 260 * s), (x, y - 560 * s), (x + 110 * s, y - 260 * s)], 6 * s + 1, seed=seed + 1),
           Stroke([(x, y - 560 * s), (x, y - 680 * s)], 6 * s, (150, 150, 160), seed=seed + 2)]
    if bolt:
        out.append(Stroke([(x + 120 * s, y - 900 * s), (x + 40 * s, y - 800 * s), (x + 90 * s, y - 780 * s), (x + 5 * s, y - 690 * s)], 9 * s + 1, (230, 180, 40), seed=seed + 3))
    if rod:
        out.append(Stroke([(x + 5 * s, y - 680 * s), (x + 120 * s, y - 500 * s), (x + 130 * s, y + 20 * s)], 4 * s, (200, 120, 50), seed=seed + 4))
        out.append(Stroke([(x + 100 * s, y + 30 * s), (x + 160 * s, y + 30 * s)], 6 * s, (120, 90, 60), seed=seed + 5))
    return out


def el_buried(x, y, s, street=True, seed=0, **_):
    """Zemin kat pencereleri sokak seviyesinin altında kalmış bina cephesi."""
    out = [Stroke(_rect(x - 300 * s, y - 520 * s, x + 300 * s, y + 160 * s), 6 * s + 1, seed=seed)]
    for r in range(3):
        for c in range(4):
            wx, wy = x - 240 * s + c * 140 * s, y - 470 * s + r * 220 * s
            out.append(Stroke(_rect(wx, wy, wx + 80 * s, wy + 130 * s), 4 * s, seed=seed + 2 + r * 4 + c))
    if street:
        ground = [(x - 420 * s, y), (x + 420 * s, y), (x + 420 * s, y + 220 * s), (x - 420 * s, y + 220 * s)]
        out.append(_blob(ground, tone=0.85, color=(120, 95, 70), seed=seed + 30))
        out.append(Stroke([(x - 420 * s, y), (x + 420 * s, y)], 7 * s + 1, (80, 60, 40), seed=seed + 31))
    return out


def el_jacks(x, y, s, seed=0, **_):
    out = el_buried(x, y - 120 * s, s * 0.8, street=False, seed=seed)
    for k in range(7):
        jx = x - 220 * s + k * 73 * s
        out.append(Stroke([(jx, y + 10 * s), (jx, y - 120 * s * 0.8 + 130 * s)], 9 * s, (100, 100, 110), seed=seed + 50 + k))
        out.append(Stroke(_rect(jx - 18 * s, y + 10 * s, jx + 18 * s, y + 40 * s), 4 * s, seed=seed + 60 + k))
    out.append(Stroke([(x - 320 * s, y + 40 * s), (x + 320 * s, y + 40 * s)], 6 * s + 1, (110, 80, 50), seed=seed + 70))
    return out


def el_mudwave(x, y, s, seed=0, W=1920, **_):
    pts = [(x - 600 * s, y + 200 * s), (x - 600 * s, y - 60 * s)]
    for k in range(13):
        pts.append((x - 600 * s + k * 100 * s, y - 60 * s - 120 * s * math.sin(k * 0.6) * (1 if k % 2 else 0.6)))
    pts += [(x + 600 * s, y + 200 * s)]
    return [_blob(pts, tone=0.85, color=(110, 85, 60), seed=seed, smooth=8 * s)]


ELEMENTS_EXTRA.update({
    "oldmap": el_oldmap, "starfort": el_starfort, "pinboard": el_pinboard, "train": el_train, "palace": el_palace, "spire": el_spire,
    "buried": el_buried, "jacks": el_jacks, "mudwave": el_mudwave,
})


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
                fn = ELEMENTS.get(name) or ELEMENTS_EXTRA[name]
                items = fn(x, y, s, seed=seed + i * 7, W=W, H=H, **e)
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
