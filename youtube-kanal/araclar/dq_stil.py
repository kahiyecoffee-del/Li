"""DEAD QUOTA stil motoru: referans stiline göre (koyu kahve sabit kontur, tek tonlu sert cel gölge, boyalı/sisli arka plan)."""
import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont

LINE = (30, 24, 20)
S = 3


def cr(pts, n=16, closed=True):
    P = pts + pts[:3] if closed else [pts[0]] + pts + [pts[-1]]
    out = []
    for i in range(len(pts) if closed else len(pts) - 1):
        p0, p1, p2, p3 = P[i], P[i + 1], P[i + 2], P[i + 3]
        for k in range(n):
            t = k / n
            out.append(tuple(0.5 * (2 * p1[j] + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t * t
                                    + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t ** 3) for j in range(2)))
    if not closed:
        out.append(pts[-1])
    return out


def noise(w, h, scale, seed):
    rng = np.random.default_rng(seed)
    small = rng.random((max(2, h // scale), max(2, w // scale)))
    return np.asarray(Image.fromarray((small * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)).astype(float) / 255


class Frame:
    def __init__(self, w=1920, h=1080, bg=(200, 200, 200)):
        self.w, self.h = w, h
        self.im = Image.new("RGB", (w * S, h * S), bg)
        self.d = ImageDraw.Draw(self.im)

    def s(self, pts):
        return [(x * S, y * S) for x, y in pts]

    # ---------------- boyalı arka plan araçları
    def sky(self, top, bottom, y1=None, tex=0.06, seed=1):
        y1 = y1 or self.h
        H = y1 * S
        a = np.zeros((H, self.w * S, 3))
        u = np.linspace(0, 1, H)[:, None]
        for i in range(3):
            a[:, :, i] = top[i] + (bottom[i] - top[i]) * u
        n = noise(self.w * S, H, 60, seed)
        a = a * (1 - tex + tex * 2 * n[:, :, None])
        self.im.paste(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), (0, 0))

    def painted(self, pts, col, tex=0.08, seed=0, smooth=False, line=None, lw=2):
        """Dokulu (boyalı) dolgu, isteğe bağlı ince kontur."""
        q = self.s(cr(pts) if smooth else pts)
        m = Image.new("L", self.im.size, 0)
        ImageDraw.Draw(m).polygon(q, fill=255)
        x0, y0, x1, y1 = m.getbbox() or (0, 0, 1, 1)
        w, h = x1 - x0, y1 - y0
        n = noise(w, h, 18, seed) * 0.6 + noise(w, h, 4, seed + 1) * 0.4
        arr = np.ones((h, w, 3)) * np.array(col)
        arr = arr * (1 - tex + tex * 2 * n[:, :, None])
        tile = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
        self.im.paste(tile, (x0, y0), m.crop((x0, y0, x1, y1)))
        if line:
            self.d.line(q + [q[0]], fill=line, width=int(lw * S), joint="curve")

    def haze(self, y0, y1, col, alpha=0.35):
        lay = Image.new("RGB", self.im.size, col)
        m = Image.new("L", self.im.size, 0)
        md = ImageDraw.Draw(m)
        for y in range(y0 * S, y1 * S):
            u = (y - y0 * S) / max(1, (y1 - y0) * S)
            md.line([(0, y), (self.w * S, y)], fill=int(255 * alpha * (1 - abs(u - 0.5) * 2)))
        self.im.paste(lay, (0, 0), m)

    # ---------------- karakter araçları (cel)
    def shape(self, pts, fill, lw=4.5, smooth=True):
        q = self.s(cr(pts) if smooth else pts)
        self.d.polygon(q, fill=fill)
        if lw:
            self.d.line(q + [q[0]], fill=LINE, width=int(lw * S), joint="curve")

    def shade(self, base, shadow_pts, col, smooth=True):
        m1 = Image.new("L", self.im.size, 0)
        ImageDraw.Draw(m1).polygon(self.s(cr(base)), fill=255)
        m2 = Image.new("L", self.im.size, 0)
        ImageDraw.Draw(m2).polygon(self.s(cr(shadow_pts) if smooth else shadow_pts), fill=255)
        self.im.paste(Image.new("RGB", self.im.size, col), (0, 0), ImageChops.multiply(m1, m2))

    def outline(self, pts, lw=4.5):
        q = self.s(cr(pts))
        self.d.line(q + [q[0]], fill=LINE, width=int(lw * S), joint="curve")

    def line(self, pts, lw=3, col=LINE, smooth=True):
        q = self.s(cr(pts, closed=False) if smooth and len(pts) > 2 else pts)
        self.d.line(q, fill=col, width=int(lw * S), joint="curve")

    def blob(self, pts, col, smooth=True):
        self.d.polygon(self.s(cr(pts) if smooth else pts), fill=col)

    def ell(self, box, col, lw=0):
        x0, y0, x1, y1 = box
        self.d.ellipse([x0 * S, y0 * S, x1 * S, y1 * S], fill=col, outline=LINE if lw else None, width=int(lw * S))

    def grade(self, col, alpha):
        self.im = Image.blend(self.im, Image.new("RGB", self.im.size, col), alpha)
        self.d = ImageDraw.Draw(self.im)

    def out(self, path):
        self.im.resize((self.w, self.h), Image.LANCZOS).save(path, quality=93)
