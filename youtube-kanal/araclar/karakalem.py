"""Karakalem (charcoal / graphite) tarzı.

- paper(): kâğıt dokusu (lif + leke + kumlanma)
- Sketch: bir görseli karakalem çizime çevirir (dış hatlar + taramalar) ve
  elle çiziliyormuş gibi açar: önce hatlar, sonra gölge taramaları, en sonda
  hafif renk lekesi. Çizim ucunda kalem görünür.
- pencil_*: tarama/ok/daire/alt çizgi gibi elle çizilmiş işaretler.
"""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

PAPER = np.array([238, 232, 218], dtype=np.float32)
GRAPHITE = np.array([46, 44, 48], dtype=np.float32)
RED_PENCIL = (170, 45, 35)
BLUE_PENCIL = (40, 80, 170)

_paper_cache = {}


def _smooth_noise(w, h, cell, seed):
    rng = np.random.default_rng(seed)
    small = rng.random((h // cell + 2, w // cell + 2)).astype(np.float32)
    im = Image.fromarray((small * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    return np.asarray(im, dtype=np.float32) / 255.0


def paper(W, H, seed=3):
    key = (W, H, seed)
    if key not in _paper_cache:
        rng = np.random.default_rng(seed)
        blot = _smooth_noise(W, H, 180, seed) - 0.5
        fiber = _smooth_noise(W, H, 6, seed + 1) - 0.5
        grain = rng.normal(0, 1, (H, W)).astype(np.float32)
        tone = 1 + blot * 0.05 + fiber * 0.025 + grain * 0.012
        yy, xx = np.ogrid[0:H, 0:W]
        r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
        tone *= 1 - 0.18 * np.clip(r - 0.6, 0, 1) ** 1.5
        _paper_cache[key] = np.clip(PAPER[None, None, :] * tone[..., None], 0, 255)
    return _paper_cache[key]


def _fit(im, W, H, mode, focus):
    im = im.convert("RGB")
    if mode == "cover":
        sc = max(W / im.width, H / im.height)
        r = im.resize((int(im.width * sc) + 1, int(im.height * sc) + 1), Image.LANCZOS)
        fx, fy = focus
        x0 = int(min(max(fx * r.width - W / 2, 0), r.width - W))
        y0 = int(min(max(fy * r.height - H / 2, 0), r.height - H))
        return r.crop((x0, y0, x0 + W, y0 + H)), np.ones((H, W), np.float32)
    sc = min(W * 0.9 / im.width, H * 0.62 / im.height)
    r = im.resize((int(im.width * sc), int(im.height * sc)), Image.LANCZOS)
    canvas = Image.new("RGB", (W, H), (255, 255, 255))
    px, py = (W - r.width) // 2, int(H * 0.5 - r.height / 2)
    canvas.paste(r, (px, py))
    mask = np.zeros((H, W), np.float32)
    mask[py:py + r.height, px:px + r.width] = 1
    # kenarları yumuşak "eskiz" sınırı
    m = Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(18))
    edge_noise = _smooth_noise(W, H, 30, 7)
    mask = np.clip((np.asarray(m, np.float32) / 255 - 0.25 + (edge_noise - 0.5) * 0.5) * 2.2, 0, 1)
    return canvas, mask


def _hatch(W, H, angle, spacing, seed, width=1.2):
    """Bölgeye göre açısı değişen, dalgalı, kesik kesik tarama çizgileri (0..1 maske)."""
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    var = (_smooth_noise(W, H, 260, seed + 9) - 0.5) * math.radians(30)
    a = math.radians(angle) + var
    wob = (_smooth_noise(W, H, 60, seed) - 0.5) * spacing * 1.2
    d = (xx * np.cos(a) + yy * np.sin(a) + wob) % spacing
    line = np.clip(1 - np.abs(d - spacing / 2) / width, 0, 1)
    # çizgiler yer yer kesik (kalem bastırma farkı)
    press = np.clip(_smooth_noise(W, H, 22, seed + 3) * 1.6 - 0.25, 0, 1)
    return line * press


class Sketch:
    """Bir görselin karakalem çizimi + çizilerek açılma animasyonu."""

    def __init__(self, im, W, H, mode="cover", focus=(0.5, 0.45), tint=0.18, seed=1):
        self.W, self.H = W, H
        src, self.mask = _fit(im, W, H, mode, focus)
        g = np.asarray(src.convert("L"), np.float32)
        # 1) karakalem tonu (dodge yöntemi)
        inv = Image.fromarray((255 - g).astype(np.uint8)).filter(ImageFilter.GaussianBlur(max(2, W / 140)))
        b = np.asarray(inv, np.float32)
        dodge = np.clip(g * 255.0 / np.maximum(1, 255 - b), 0, 255)
        tone = 1 - dodge / 255.0
        # 2) dış hatlar
        gb = Image.fromarray(g.astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.3))
        edges = np.asarray(gb.filter(ImageFilter.FIND_EDGES), np.float32) / 255.0
        edges = np.clip((edges - 0.04) * 5, 0, 1)
        self.lines = np.clip(tone * 1.35 + edges * 0.8, 0, 1) * self.mask
        # 3) gölge taramaları (koyu bölgelerde çoğalan çapraz çizgiler)
        dark = 1 - g / 255.0
        sp = max(8, W / 95)
        h1 = _hatch(W, H, 45, sp, seed) * np.clip((dark - 0.5) * 3, 0, 1)
        h2 = _hatch(W, H, -40, sp * 1.1, seed + 1) * np.clip((dark - 0.68) * 3, 0, 1)
        h3 = _hatch(W, H, 10, sp * 0.9, seed + 2) * np.clip((dark - 0.82) * 4, 0, 1)
        soft = np.asarray(Image.fromarray((dark * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6)), np.float32) / 255
        smudge = (soft ** 1.6) * (0.75 + 0.5 * _smooth_noise(W, H, 90, seed + 4))  # parmakla dağıtılmış kömür
        self.shade = np.clip(np.maximum.reduce([h1 * 0.45, h2 * 0.5, h3 * 0.55]) + smudge * 0.32, 0, 1) * self.mask
        # 4) hafif renk lekesi (sulu boya gibi)
        col = np.asarray(src.filter(ImageFilter.GaussianBlur(6)), np.float32)
        self.wash = col
        self.tint = tint
        # açılma sırası: köşegen + organik gürültü
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        diag = (xx / W * 0.45 + yy / H * 0.55)
        self.order = diag * 0.82 + _smooth_noise(W, H, 160, seed + 5) * 0.18
        self.order = (self.order - self.order.min()) / (self.order.max() - self.order.min() + 1e-6)
        # kalem ucunun dolaşacağı noktalar
        rng = np.random.default_rng(seed)
        ys, xs = np.nonzero(self.lines > 0.35)
        if len(xs) > 4000:
            idx = rng.choice(len(xs), 4000, replace=False)
            xs, ys = xs[idx], ys[idx]
        o = self.order[ys, xs]
        srt = np.argsort(o)
        self.path = np.stack([xs[srt], ys[srt]], 1) if len(xs) else np.array([[W // 2, H // 2]])
        self.path_o = o[srt] if len(xs) else np.array([0.0])
        self._final = None

    def frame(self, p):
        """p: 0..1 çizim ilerlemesi (1'den büyükse tamamlanmış)."""
        if p >= 1.0 and self._final is not None:
            return self._final.copy()
        pap = paper(self.W, self.H)

        def reveal(start, span):
            k = (p - start) / span
            return np.clip((k * 1.1 - self.order) / 0.08, 0, 1)
        a_line = self.lines * reveal(0.0, 0.6)
        a_shade = self.shade * reveal(0.3, 0.6)
        a = np.clip(np.maximum(a_line, a_shade), 0, 1)[..., None]
        out = pap * (1 - a * 0.92) + GRAPHITE[None, None, :] * a * 0.92
        tw = np.clip((p - 0.8) / 0.2, 0, 1) * self.tint
        if tw > 0:
            lum = self.wash.mean(axis=2, keepdims=True)
            wash = out * (self.wash / np.maximum(lum, 1)) ** 0.9
            m = (tw * self.mask)[..., None]
            out = out * (1 - m) + np.clip(wash, 0, 255) * m
        img = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))
        if p < 0.92:
            self._pencil(img, p)
        if p >= 1.0:
            self._final = img.copy()
        return img

    def _pencil(self, img, p):
        k = np.searchsorted(self.path_o, min(1.0, p / 0.6 * 1.1 - 0.02))
        k = int(min(max(k, 0), len(self.path) - 1))
        x, y = self.path[k]
        x += 8 * math.sin(p * 90)
        y += 6 * math.cos(p * 70)
        draw_pencil(ImageDraw.Draw(img), x, y, self.W / 1080)


def draw_pencil(d, x, y, s=1.0):
    """Çizim ucundaki kurşun kalem (sağ üste doğru)."""
    ang = math.radians(-50)
    L, w = 260 * s, 26 * s
    ux, uy = math.cos(ang), math.sin(ang)
    nx, ny = -uy, ux
    tip = (x, y)
    cone = (x + ux * 60 * s, y + uy * 60 * s)
    end = (x + ux * L, y + uy * L)
    d.polygon([tip, (cone[0] + nx * w / 2, cone[1] + ny * w / 2), (cone[0] - nx * w / 2, cone[1] - ny * w / 2)], fill=(225, 190, 140))
    d.polygon([tip, (x + ux * 20 * s + nx * w * 0.17, y + uy * 20 * s + ny * w * 0.17),
               (x + ux * 20 * s - nx * w * 0.17, y + uy * 20 * s - ny * w * 0.17)], fill=(40, 40, 45))
    body = [(cone[0] + nx * w / 2, cone[1] + ny * w / 2), (end[0] + nx * w / 2, end[1] + ny * w / 2),
            (end[0] - nx * w / 2, end[1] - ny * w / 2), (cone[0] - nx * w / 2, cone[1] - ny * w / 2)]
    d.polygon(body, fill=(70, 70, 75), outline=(30, 30, 30))
    d.line([(cone[0], cone[1]), (end[0], end[1])], fill=(95, 95, 100), width=max(1, int(4 * s)))


# --------------------------------------------------------------------------- #
# Elle çizilmiş işaretler (kalem darbesi)
# --------------------------------------------------------------------------- #
def pencil_stroke(d, pts, color=(46, 44, 48), width=6, passes=2, seed=0):
    rng = random.Random(seed)
    for k in range(passes):
        j = width * 0.6
        q = [(x + rng.uniform(-j, j), y + rng.uniform(-j, j)) for x, y in pts]
        alpha = 210 if k == 0 else 140
        c = (*color, alpha)
        d.line(q, fill=c, width=max(1, int(width * (1 if k == 0 else 0.6))), joint="curve")


def pencil_circle(d, c, rx, ry, color=RED_PENCIL, width=6, seed=0):
    pts = []
    for i in range(70):
        u = i / 60 * 2 * math.pi - 0.6
        wob = 1 + 0.05 * math.sin(u * 3 + seed)
        pts.append((c[0] + math.cos(u) * rx * wob * (1 + i / 600), c[1] + math.sin(u) * ry * wob))
    pencil_stroke(d, pts, color, width, 2, seed)


def pencil_arrow(d, a, b, color=(46, 44, 48), width=6, seed=0, bend=0.18):
    mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    nx, ny = -(b[1] - a[1]), b[0] - a[0]
    ctrl = (mx + nx * bend, my + ny * bend)
    pts = [((1 - u) ** 2 * a[0] + 2 * (1 - u) * u * ctrl[0] + u * u * b[0],
            (1 - u) ** 2 * a[1] + 2 * (1 - u) * u * ctrl[1] + u * u * b[1]) for u in (i / 24 for i in range(25))]
    pencil_stroke(d, pts, color, width, 2, seed)
    ang = math.atan2(b[1] - pts[-3][1], b[0] - pts[-3][0])
    L = width * 6
    for s in (-1, 1):
        e = (b[0] - L * math.cos(ang + s * 0.5), b[1] - L * math.sin(ang + s * 0.5))
        pencil_stroke(d, [e, b], color, width, 2, seed + s)


def pencil_underline(d, x0, x1, y, color=RED_PENCIL, width=6, seed=0):
    pts = [(x0 + (x1 - x0) * u, y + 4 * math.sin(u * 7 + seed)) for u in (i / 20 for i in range(21))]
    pencil_stroke(d, pts, color, width, 2, seed)
    pencil_stroke(d, [(x1 - 10, y + 6), (x0 + 30, y + 12)], color, width * 0.7, 1, seed + 1)
