#!/usr/bin/env python3
"""Çöp adam videosu üretici.

Senaryo JSON dosyasını okur, her dil için seslendirme yapar, çöp adam
animasyonunu çizer ve ffmpeg ile MP4 çıkarır. Ayrıca altyazı (SRT) ve
yükleme notlarını (başlık/açıklama/etiket) yazar.

Kullanım:
    python3 araclar/video_uret.py senaryolar/2-dakika-kurali.json
    python3 araclar/video_uret.py senaryo.json --diller en,es --format long
    python3 araclar/video_uret.py senaryo.json --mod coklu   # tek video + dil başına ses kanalı
"""
import argparse
import json
import math
import os
import random
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import arkaplan as ab  # noqa: E402
import theo  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_PATH = os.path.join(ROOT, "fonts", "Kalam-Bold.ttf")
MODEL_DIR = os.environ.get("KOKORO_DIR", os.path.join(ROOT, "modeller"))
FPS = 30
SR = 24000

# Kokoro'nun desteklediği diller (Türkçe yok).
LANGS = {
    "en": {"kokoro": "en-us", "voice": "am_michael"},
    "es": {"kokoro": "es", "voice": "em_alex"},
    "pt": {"kokoro": "pt-br", "voice": "pm_alex"},
    "fr": {"kokoro": "fr-fr", "voice": "ff_siwis"},
    "hi": {"kokoro": "hi", "voice": "hm_omega"},
    "it": {"kokoro": "it", "voice": "im_nicola"},
}

FORMATS = {
    # Shorts: altyazı üstte, alt kısım YouTube arayüzüne bırakılır.
    "short": dict(w=1080, h=1920, fig_x=540, hip_y=1195, sc=1.25, cap_y=230,
                  cap_size=104, cap_w=980, prop_c=(540, 520), prop_dx=290, prop_sc=1.3, focus=(540, 900)),
    "long": dict(w=1920, h=1080, fig_x=560, hip_y=640, sc=0.85, cap_y=985,
                 cap_size=68, cap_w=1700, prop_c=(1320, 440), prop_dx=360, prop_sc=1.45, focus=(900, 520)),
}

BG = (250, 249, 244)
INK = (25, 25, 25)
ACCENT = (255, 205, 50)
RED = (230, 70, 60)
GREEN = (60, 175, 90)
BLUE = (70, 140, 230)

# --------------------------------------------------------------------------- #
# Pozlar. Açılar derece, 0 = aşağı, pozitif = ekranın sağına doğru.
# --------------------------------------------------------------------------- #
BASE = dict(lean=0.0, head=0.0, droop=0.0, la1=-14.0, la2=-8.0, ra1=14.0, ra2=8.0,
            ll1=-9.0, ll2=-5.0, rl1=9.0, rl2=5.0, bob=0.0)


def pose(name, t):
    s = math.sin
    p = dict(BASE)
    expr = "neutral"
    if name == "stand":
        p["bob"] = 3 * s(t * 2)
    elif name == "talk":
        p.update(ra1=35 + 10 * s(t * 3), ra2=105 + 20 * s(t * 3 + 1),
                 la1=-22 - 6 * s(t * 2.3), la2=-35 - 15 * s(t * 2.3 + .5), bob=3 * s(t * 2.5))
    elif name == "wave":
        p.update(ra1=140, ra2=165 + 25 * s(t * 9), bob=4 * s(t * 3))
        expr = "happy"
    elif name == "point_right":
        p.update(ra1=78, ra2=82 + 3 * s(t * 4), la1=-16, bob=2 * s(t * 2))
        expr = "happy"
    elif name == "point_left":
        p.update(la1=-78, la2=-82 - 3 * s(t * 4), ra1=16, bob=2 * s(t * 2))
        expr = "happy"
    elif name == "idea":
        p.update(ra1=160, ra2=178, la1=-20, la2=-30, bob=-abs(s(t * 4)) * 8)
        expr = "happy"
    elif name == "think":
        p.update(ra1=55, ra2=-140, la1=-25, la2=55, head=6 * s(t * 1.5))
        expr = "think"
    elif name == "shock":
        j = 4 * s(t * 30)
        p.update(la1=-145 + j, la2=-160 - j, ra1=145 - j, ra2=160 + j, ll1=-14, rl1=14)
        expr = "shock"
    elif name == "celebrate":
        p.update(la1=-150, la2=-170, ra1=150, ra2=170, ll1=-16, ll2=-10, rl1=16, rl2=10,
                 bob=-abs(s(t * 6)) * 30)
        expr = "happy"
    elif name == "tired":
        p.update(la1=-12, la2=-4, ra1=12, ra2=4, droop=18, head=10, bob=2 * s(t))
        expr = "tired"
    elif name == "sad":
        p.update(la1=-12, la2=-5, ra1=12, ra2=5, droop=12, bob=1.5 * s(t))
        expr = "sad"
    elif name == "shrug":
        k = 0.5 + 0.5 * s(t * 3)
        p.update(la1=-40, la2=-105, ra1=40, ra2=105, head=8, bob=-6 * k)
        expr = "confused"
    elif name == "walk":
        a = 22 * s(t * 6)
        p.update(ll1=a, ll2=a - 12, rl1=-a, rl2=-a - 12, la1=-a - 8, la2=-a - 20,
                 ra1=a + 8, ra2=a + 20, bob=-abs(s(t * 6)) * 6)
    elif name == "run":
        a = 38 * s(t * 10)
        p.update(lean=8, ll1=a, ll2=a - 35, rl1=-a, rl2=-a - 35, la1=-a - 20, la2=-a + 60,
                 ra1=a + 20, ra2=a - 60, bob=-abs(s(t * 10)) * 14)
        expr = "happy"
    elif name == "phone":
        p.update(ra1=20, ra2=160, la1=-18, la2=40, droop=8, bob=1.5 * s(t * 1.5))
        expr = "down"
    elif name == "read":
        p.update(la1=-25, la2=-150, ra1=25, ra2=150, droop=6, bob=1.5 * s(t * 1.5))
        expr = "down"
    else:
        raise ValueError(f"Bilinmeyen poz: {name}")
    return p, expr


def blend(a, b, k):
    return {key: a[key] + (b[key] - a[key]) * k for key in a}


def ease(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def ease_back(x):
    x = min(max(x, 0.0), 1.0)
    c = 1.70158
    return 1 + (c + 1) * (x - 1) ** 3 + c * (x - 1) ** 2


# --------------------------------------------------------------------------- #
# Çizim yardımcıları (hafif titreşimli "el çizimi" görünümü)
# --------------------------------------------------------------------------- #
class Pen:
    def __init__(self, draw, sc, seed):
        self.d = draw
        self.sc = sc
        self.rng = random.Random(seed)
        self.lw = max(3, int(13 * sc))

    def j(self, pt, amt=1.8):
        a = amt * self.sc
        return (pt[0] + self.rng.uniform(-a, a), pt[1] + self.rng.uniform(-a, a))

    def line(self, pts, color=INK, w=None, jitter=True):
        w = w or self.lw
        pts = [self.j(p) if jitter else p for p in pts]
        self.d.line(pts, fill=color, width=w, joint="curve")
        r = w / 2
        for p in (pts[0], pts[-1]):
            self.d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color)

    def circle(self, c, r, outline=INK, fill=None, w=None):
        w = w or self.lw
        c = self.j(c)
        self.d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], outline=outline, fill=fill, width=w)

    def poly(self, pts, fill=None, outline=INK, w=None):
        w = w or self.lw
        pts = [self.j(p) for p in pts]
        if fill:
            self.d.polygon(pts, fill=fill)
        self.d.line(pts + [pts[0]], fill=outline, width=w, joint="curve")

    def rrect(self, box, rad, fill=None, outline=INK, w=None):
        w = w or self.lw
        x0, y0, x1, y1 = box
        o = self.rng.uniform(-1.5, 1.5) * self.sc
        x0, x1 = sorted((x0 + o, x1 - o))
        y0, y1 = sorted((y0 - o, y1 + o))
        if x1 - x0 < 2 * w or y1 - y0 < 2 * w:
            return
        rad = max(0, min(rad, (x1 - x0) / 2, (y1 - y0) / 2))
        self.d.rounded_rectangle([x0, y0, x1, y1], radius=rad, fill=fill, outline=outline, width=w)


_font_cache = {}

# Temalar: renkler, yazı tipi, müzik, karakter
THEMES = {
    "playful": dict(font="Kalam-Bold.ttf", font_hi="Kalam-Bold.ttf", swipe=[(255, 201, 60), (255, 107, 91), (46, 196, 182),
                    (120, 110, 230)], stars=True, badge=(255, 107, 91), cap_box=(20, 20, 25, 185), cap_key=(255, 120, 100),
                    cap_cur=(255, 205, 50), music="lofi", character="stick", bar=(255, 201, 60)),
    "academia": dict(font="Merriweather.ttf", font_hi="TiroDevanagariHindi-Regular.ttf",
                     swipe=[(120, 30, 45), (35, 80, 62), (32, 45, 82), (165, 125, 55)], stars=False, badge=(130, 32, 48),
                     cap_box=(28, 20, 16, 200), cap_key=(240, 175, 120), cap_cur=(255, 214, 110), music="ambient", cap_scale=0.84,
                     character="theo", bar=(200, 160, 70)),
    # karakalem: kâğıt, grafit, kırmızı/mavi kalem vurguları
    "karakalem": dict(font="Kalam-Bold.ttf", font_hi="Kalam-Bold.ttf", swipe=[(236, 230, 215), (228, 220, 202)], stars=False,
                      badge=(150, 45, 35), cap_box=(240, 234, 220, 238), cap_key=(176, 48, 38), cap_cur=(48, 86, 168),
                      cap_text=(40, 38, 42), cap_stroke=(40, 38, 42), cap_stroke_scale=0.0, music="ambient", cap_scale=0.9,
                      character="none", bar=(150, 45, 35), whoosh=False, music_gain=0.24, duck=0.55, gap=0.65),
}
CUR = {"theme": THEMES["playful"], "lang": "en"}


def font(size):
    size = int(size)
    th = CUR["theme"]
    path = os.path.join(ROOT, "fonts", th["font_hi"] if CUR["lang"] == "hi" else th["font"])
    key = (path, size)
    if key not in _font_cache:
        f = ImageFont.truetype(path, size)
        try:
            axes = f.get_variation_axes()
            vals = []
            for ax in axes:
                n = ax["name"]
                n = n.decode() if isinstance(n, bytes) else n
                vals.append({"Weight": 800, "Width": 100}.get(n, max(ax["minimum"], min(ax["maximum"], size * 0.4))))
            f.set_variation_by_axes(vals)
        except Exception:
            pass
        _font_cache[key] = f
    return _font_cache[key]


def text_center(draw, xy, text, size, fill=INK, stroke=0, stroke_fill=INK, max_w=None):
    while True:
        f = font(size)
        box = draw.textbbox((0, 0), text, font=f, stroke_width=stroke)
        tw, th = box[2] - box[0], box[3] - box[1]
        if not max_w or tw <= max_w or size < 20:
            break
        size *= 0.92
    draw.text((xy[0] - tw / 2 - box[0], xy[1] - th / 2 - box[1]), text, font=f, fill=fill,
              stroke_width=stroke, stroke_fill=stroke_fill)


# --------------------------------------------------------------------------- #
# Çöp adam
# --------------------------------------------------------------------------- #
def rad(a):
    return math.radians(a)


def limb(start, a1, a2, l1, l2):
    e = (start[0] + math.sin(rad(a1)) * l1, start[1] + math.cos(rad(a1)) * l1)
    h = (e[0] + math.sin(rad(a2)) * l2, e[1] + math.cos(rad(a2)) * l2)
    return e, h


SCARF = (255, 120, 60)
CHEEK = (255, 160, 160)


def draw_figure(pen, p, expr, cx, hip_y, sc, mouth_open, t=0.0, glow=False):
    L = dict(torso=230 * sc, head=62 * sc, ua=125 * sc, fa=115 * sc, th=150 * sc, sh=140 * sc)
    hip = (cx, hip_y + p["bob"] * sc)
    lean = rad(p["lean"])
    neck = (hip[0] + math.sin(lean) * L["torso"], hip[1] - math.cos(lean) * L["torso"])
    shoulder = (hip[0] + math.sin(lean) * L["torso"] * 0.86, hip[1] - math.cos(lean) * L["torso"] * 0.86)
    ha = lean + rad(p["head"])
    hd = L["head"] + 6 * sc
    head = (neck[0] + math.sin(ha) * hd, neck[1] - math.cos(ha) * hd + p["droop"] * sc)

    for a1, a2 in ((p["ll1"], p["ll2"]), (p["rl1"], p["rl2"])):
        knee, foot = limb(hip, a1, a2, L["th"], L["sh"])
        pen.line([hip, knee, foot])
    pen.line([hip, neck])
    hands = []
    for a1, a2 in ((p["la1"], p["la2"]), (p["ra1"], p["ra2"])):
        elbow, hand = limb(shoulder, a1, a2, L["ua"], L["fa"])
        pen.line([shoulder, elbow, hand])
        hands.append(hand)

    r = L["head"]
    d = pen.d
    # imza: anten (fikir anında yanar)
    ax0 = (head[0] + 0.25 * r, head[1] - 0.95 * r)
    sway = 6 * sc * math.sin(t * 3)
    ax1 = (head[0] + 0.55 * r + sway, head[1] - 1.55 * r)
    ax2 = (head[0] + 0.3 * r + sway * 1.5, head[1] - 1.95 * r)
    pen.line([ax0, ax1, ax2], w=int(pen.lw * 0.55))
    br = 14 * sc * (1.25 if glow else 1.0)
    if glow:
        for k in range(8):
            a = k * math.pi / 4 + t * 2
            d.line([(ax2[0] + math.cos(a) * br * 1.6, ax2[1] + math.sin(a) * br * 1.6),
                    (ax2[0] + math.cos(a) * br * 2.3, ax2[1] + math.sin(a) * br * 2.3)], fill=(255, 190, 40),
                   width=max(2, int(5 * sc)))
    d.ellipse([ax2[0] - br, ax2[1] - br, ax2[0] + br, ax2[1] + br], fill=(255, 201, 60) if glow else (255, 107, 91),
              outline=INK, width=max(2, int(5 * sc)))
    pen.circle(head, r, fill=(255, 255, 255))
    # imza: atkı (uçları rüzgârda dalgalanır)
    nk = (neck[0], neck[1] + 4 * sc)
    d.rounded_rectangle([nk[0] - 34 * sc, nk[1] - 12 * sc, nk[0] + 34 * sc, nk[1] + 14 * sc], radius=int(12 * sc),
                        fill=SCARF, outline=INK, width=max(2, int(5 * sc)))
    tail = []
    for k in range(5):
        u = k / 4
        tail.append((nk[0] + 18 * sc + u * 70 * sc, nk[1] + 8 * sc + u * 50 * sc + 9 * sc * math.sin(t * 7 - u * 4) * u))
    pen.line(tail, color=INK, w=int(24 * sc))
    pen.line(tail, color=SCARF, w=int(15 * sc), jitter=False)
    hx, hy = head
    ex, ey, er = 21 * sc, -10 * sc, 7 * sc
    look = 8 * sc if expr == "down" else 0
    if expr == "tired":
        for sx in (-1, 1):
            d.line([(hx + sx * ex - 12 * sc, hy + ey + 2 * sc), (hx + sx * ex + 12 * sc, hy + ey + 2 * sc)],
                   fill=INK, width=int(6 * sc))
    elif expr == "happy" and mouth_open < 0.05:
        for sx in (-1, 1):
            d.arc([hx + sx * ex - 11 * sc, hy + ey - 8 * sc, hx + sx * ex + 11 * sc, hy + ey + 10 * sc],
                  200, 340, fill=INK, width=int(6 * sc))
    else:
        big = 1.5 if expr == "shock" else 1.0
        for sx in (-1, 1):
            c = (hx + sx * ex, hy + ey + look)
            rr = er * big
            d.ellipse([c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr], fill=INK)
    if expr in ("confused", "think"):
        d.line([(hx + ex - 12 * sc, hy + ey - 22 * sc), (hx + ex + 12 * sc, hy + ey - 28 * sc)],
               fill=INK, width=int(6 * sc))

    for sx in (-1, 1):
        cxk = hx + sx * 36 * sc
        d.ellipse([cxk - 11 * sc, hy + 10 * sc, cxk + 11 * sc, hy + 20 * sc], fill=CHEEK)
    my = hy + 26 * sc + look * 0.5
    mw = 22 * sc
    if expr == "shock":
        d.ellipse([hx - 12 * sc, my - 14 * sc, hx + 12 * sc, my + 14 * sc], fill=INK)
    elif mouth_open > 0.05:
        oh = (5 + 22 * mouth_open) * sc
        d.ellipse([hx - mw * 0.75, my - oh / 2, hx + mw * 0.75, my + oh / 2], fill=INK)
    elif expr == "happy":
        d.arc([hx - mw, my - 22 * sc, hx + mw, my + 8 * sc], 20, 160, fill=INK, width=int(6 * sc))
    elif expr in ("sad", "tired"):
        d.arc([hx - mw * 0.8, my - 2 * sc, hx + mw * 0.8, my + 20 * sc], 200, 340, fill=INK, width=int(6 * sc))
    elif expr == "confused":
        d.line([(hx - mw * 0.7, my + 4 * sc), (hx + mw * 0.7, my - 4 * sc)], fill=INK, width=int(6 * sc))
    else:
        d.line([(hx - mw * 0.6, my), (hx + mw * 0.6, my)], fill=INK, width=int(6 * sc))
    return dict(hand_l=hands[0], hand_r=hands[1], head=head, hands=((hands[0][0] + hands[1][0]) / 2,
                                                                    (hands[0][1] + hands[1][1]) / 2))


# --------------------------------------------------------------------------- #
# Aksesuarlar / ikonlar
# --------------------------------------------------------------------------- #
def prop_text(spec, lang):
    t = spec.get("text", "")
    if isinstance(t, dict):
        return t.get(lang) or t.get("en") or next(iter(t.values()))
    return t


def draw_prop(pen, spec, c, s, t, lang):
    d = pen.d
    kind = spec["type"]
    x, y = c
    S = 100 * s  # temel boyut
    color = {"red": RED, "green": GREEN, "blue": BLUE, "yellow": ACCENT}.get(spec.get("color"), ACCENT)
    if kind == "bigtext":
        room = 2 * min(x, d.im.size[0] - x) - 40
        text_center(d, (x, y), prop_text(spec, lang), 1.25 * S, fill=color, stroke=int(9 * s),
                    stroke_fill=INK, max_w=min(2.2 * S * spec.get("width", 4), room))
    elif kind in ("bubble", "thought"):
        txt = prop_text(spec, lang)
        f = font(0.55 * S)
        box = d.textbbox((0, 0), txt, font=f)
        w = min(box[2] - box[0], 8 * S) + 0.6 * S
        h = 1.1 * S
        pen.rrect([x - w / 2, y - h / 2, x + w / 2, y + h / 2], int(0.4 * S), fill="white")
        tail = spec.get("tail", "down")
        if kind == "bubble" and tail == "down":
            pen.poly([(x - 0.2 * S, y + h / 2 - 3), (x + 0.15 * S, y + h / 2 - 3), (x - 0.15 * S, y + h / 2 + 0.5 * S)],
                     fill="white", w=int(pen.lw * 0.7))
        elif kind == "thought":
            pen.circle((x - 0.2 * S, y + h / 2 + 0.3 * S), 0.12 * S, fill="white", w=int(pen.lw * 0.6))
            pen.circle((x - 0.35 * S, y + h / 2 + 0.6 * S), 0.07 * S, fill="white", w=int(pen.lw * 0.5))
        text_center(d, (x, y), txt, 0.55 * S, max_w=w - 0.4 * S)
    elif kind == "phone":
        w, h = 0.75 * S, 1.35 * S
        pen.rrect([x - w / 2, y - h / 2, x + w / 2, y + h / 2], int(0.14 * S), fill=(60, 60, 70))
        glow = BLUE if int(t * 4) % 2 else (110, 180, 250)
        d.rectangle([x - w / 2 + 0.1 * S, y - h / 2 + 0.17 * S, x + w / 2 - 0.1 * S, y + h / 2 - 0.2 * S], fill=glow)
    elif kind == "clock":
        r = 0.9 * S
        pen.circle((x, y), r, fill="white")
        for i in range(12):
            a = i * math.pi / 6
            d.line([(x + math.sin(a) * r * 0.78, y - math.cos(a) * r * 0.78),
                    (x + math.sin(a) * r * 0.9, y - math.cos(a) * r * 0.9)], fill=INK, width=max(2, int(5 * s)))
        am = t * 2.5
        pen.line([(x, y), (x + math.sin(am) * r * 0.7, y - math.cos(am) * r * 0.7)], color=RED, w=int(pen.lw * 0.6))
        pen.line([(x, y), (x + math.sin(am / 12) * r * 0.45, y - math.cos(am / 12) * r * 0.45)], w=int(pen.lw * 0.8))
        if spec.get("text"):
            text_center(d, (x, y + r + 0.45 * S), prop_text(spec, lang), 0.6 * S, fill=INK)
    elif kind == "bulb":
        r = 0.6 * S
        cy = y - 0.15 * S
        pulse = 1 + 0.06 * math.sin(t * 8)
        for i in range(8):
            a = i * math.pi / 4 + math.pi / 8
            pen.line([(x + math.cos(a) * r * 1.35 * pulse, cy + math.sin(a) * r * 1.35 * pulse),
                      (x + math.cos(a) * r * 1.75 * pulse, cy + math.sin(a) * r * 1.75 * pulse)],
                     color=INK, w=int(pen.lw * 0.6))
        pen.circle((x, cy), r, fill=ACCENT)
        pen.rrect([x - 0.3 * S, cy + r * 0.85, x + 0.3 * S, cy + r * 0.85 + 0.45 * S], int(0.08 * S), fill=(180, 180, 180))
    elif kind == "brain":
        r = 0.55 * S
        pts = [(x - 0.5 * S, y), (x - 0.25 * S, y - 0.3 * S), (x + 0.25 * S, y - 0.3 * S), (x + 0.5 * S, y),
               (x + 0.25 * S, y + 0.25 * S), (x - 0.25 * S, y + 0.25 * S)]
        for p in pts:
            pen.circle(p, r * 0.62, fill=(250, 170, 190), w=int(pen.lw * 0.6))
        for p in pts:
            d.ellipse([p[0] - r * 0.5, p[1] - r * 0.5, p[0] + r * 0.5, p[1] + r * 0.5], fill=(250, 170, 190))
        pen.line([(x, y - 0.5 * S), (x - 0.05 * S, y), (x, y + 0.45 * S)], w=int(pen.lw * 0.5))
    elif kind == "book":
        w, h = 1.6 * S, 1.0 * S
        flap = 0.1 * S * math.sin(t * 3)
        pen.poly([(x, y - h / 2 + 0.1 * S), (x - w / 2, y - h / 2 + flap), (x - w / 2, y + h / 2), (x, y + h / 2 + 0.1 * S)],
                 fill="white", w=int(pen.lw * 0.7))
        pen.poly([(x, y - h / 2 + 0.1 * S), (x + w / 2, y - h / 2 - flap), (x + w / 2, y + h / 2), (x, y + h / 2 + 0.1 * S)],
                 fill="white", w=int(pen.lw * 0.7))
        for i in range(3):
            yy = y - 0.15 * S + i * 0.2 * S
            d.line([(x - w / 2 + 0.15 * S, yy), (x - 0.15 * S, yy)], fill=(120, 120, 120), width=max(2, int(4 * s)))
            d.line([(x + 0.15 * S, yy), (x + w / 2 - 0.15 * S, yy)], fill=(120, 120, 120), width=max(2, int(4 * s)))
    elif kind == "shoe":
        pts = [(x - 0.8 * S, y - 0.5 * S), (x - 0.35 * S, y - 0.5 * S), (x - 0.2 * S, y - 0.1 * S),
               (x + 0.6 * S, y + 0.05 * S), (x + 0.85 * S, y + 0.3 * S), (x + 0.85 * S, y + 0.45 * S),
               (x - 0.8 * S, y + 0.45 * S)]
        pen.poly(pts, fill=RED)
        d.rectangle([x - 0.8 * S, y + 0.32 * S, x + 0.85 * S, y + 0.45 * S], fill="white")
        pen.line([(x - 0.8 * S, y + 0.3 * S), (x + 0.85 * S, y + 0.3 * S)], w=int(pen.lw * 0.6))
    elif kind == "mountain":
        w, h = 2.6 * S, 1.8 * S
        pen.poly([(x - w / 2, y + h / 2), (x, y - h / 2), (x + w / 2, y + h / 2)], fill=(180, 180, 190))
        pen.poly([(x - 0.3 * S, y - h / 2 + 0.55 * S), (x, y - h / 2), (x + 0.3 * S, y - h / 2 + 0.55 * S)], fill="white",
                 w=int(pen.lw * 0.6))
        if spec.get("text"):
            text_center(d, (x, y + 0.5 * S), prop_text(spec, lang), 0.55 * S, fill=INK, max_w=w * 0.62)
    elif kind == "chart_up":
        w, h = 2.0 * S, 1.5 * S
        pen.line([(x - w / 2, y - h / 2), (x - w / 2, y + h / 2), (x + w / 2, y + h / 2)])
        k = min(1.0, t / 1.2)
        pts = [(x - w / 2 + 0.1 * S, y + h / 2 - 0.2 * S), (x - 0.3 * S, y + 0.1 * S), (x, y + 0.25 * S),
               (x + 0.3 * S, y - 0.2 * S), (x + w / 2 - 0.1 * S, y - h / 2 + 0.1 * S)]
        n = max(2, int(1 + k * (len(pts) - 1) + 0.999))
        pen.line(pts[:n], color=GREEN, w=int(pen.lw * 1.1))
        if k >= 1:
            tip = pts[-1]
            pen.poly([(tip[0] - 0.25 * S, tip[1]), (tip[0] + 0.05 * S, tip[1] - 0.12 * S), (tip[0], tip[1] + 0.25 * S)],
                     fill=GREEN, outline=GREEN, w=int(pen.lw * 0.6))
    elif kind == "check":
        pen.circle((x, y), 0.8 * S, fill=GREEN)
        pen.line([(x - 0.4 * S, y), (x - 0.1 * S, y + 0.3 * S), (x + 0.45 * S, y - 0.35 * S)], color="white",
                 w=int(pen.lw * 1.3))
    elif kind == "cross":
        pen.circle((x, y), 0.8 * S, fill=RED)
        pen.line([(x - 0.35 * S, y - 0.35 * S), (x + 0.35 * S, y + 0.35 * S)], color="white", w=int(pen.lw * 1.3))
        pen.line([(x + 0.35 * S, y - 0.35 * S), (x - 0.35 * S, y + 0.35 * S)], color="white", w=int(pen.lw * 1.3))
    elif kind == "heart":
        k = 1 + 0.08 * math.sin(t * 7)
        pts = []
        for i in range(40):
            a = i / 40 * 2 * math.pi
            hx = 16 * math.sin(a) ** 3
            hy = 13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a)
            pts.append((x + hx * 0.045 * S * k, y - hy * 0.045 * S * k))
        pen.poly(pts, fill=RED)
    elif kind == "coin":
        sq = abs(math.cos(t * 3))
        w = 0.8 * S * max(sq, 0.15)
        pen.d.ellipse([x - w, y - 0.8 * S, x + w, y + 0.8 * S], fill=ACCENT, outline=INK, width=pen.lw)
        if sq > 0.5:
            text_center(d, (x, y), "$", 0.9 * S, fill=INK)
    elif kind in ("question", "exclaim", "zzz"):
        txt = {"question": "?", "exclaim": "!", "zzz": "Z z z"}[kind]
        text_center(d, (x, y + 4 * math.sin(t * 5) * s), txt, 1.6 * S, fill=color, stroke=int(8 * s), stroke_fill=INK)
    elif kind == "arrow":
        dirx = -1 if spec.get("dir") == "left" else 1
        w = 1.4 * S
        off = 0.1 * S * math.sin(t * 6) * dirx
        pen.line([(x - dirx * w / 2 + off, y), (x + dirx * w / 2 + off, y)], w=int(pen.lw * 1.2))
        pen.line([(x + dirx * (w / 2 - 0.35 * S) + off, y - 0.35 * S), (x + dirx * w / 2 + off, y),
                  (x + dirx * (w / 2 - 0.35 * S) + off, y + 0.35 * S)], w=int(pen.lw * 1.2))
    elif kind == "subscribe":
        txt_a = {"en": "SUBSCRIBE", "es": "SUSCRIBIRSE", "pt": "INSCREVER-SE", "hi": "सब्सक्राइब", "fr": "S'ABONNER",
                 "it": "ISCRIVITI"}.get(lang, "SUBSCRIBE")
        txt_b = {"en": "SUBSCRIBED", "es": "SUSCRITO", "pt": "INSCRITO", "hi": "सब्सक्राइब्ड", "fr": "ABONNÉ",
                 "it": "ISCRITTO"}.get(lang, "SUBSCRIBED")
        click = spec.get("click", 1.1)
        done = t >= click
        press = 0.92 if click <= t < click + 0.12 else 1.0
        w, h = 3.4 * S * press, 0.9 * S * press
        col = (90, 90, 95) if done else (220, 30, 35)
        pen.rrect([x - w / 2, y - h / 2, x + w / 2, y + h / 2], int(h / 2), fill=col)
        text_center(d, (x - 0.25 * S if done else x, y), txt_b if done else txt_a, 0.42 * S, fill="white", max_w=w - 0.9 * S)
        if done:
            pen.line([(x + w / 2 - 0.62 * S, y), (x + w / 2 - 0.48 * S, y + 0.14 * S), (x + w / 2 - 0.25 * S, y - 0.16 * S)],
                     color="white", w=int(pen.lw * 0.6))
        # zil
        bx, by = x + w / 2 + 0.75 * S, y
        wig = 0.35 * math.sin((t - click) * 30) * math.exp(-(t - click) * 3) if done else 0
        bell = []
        for k in range(13):
            a = math.pi + math.pi * k / 12
            bell.append((bx + math.cos(a) * 0.32 * S, by - 0.05 * S + math.sin(a) * 0.38 * S))
        bell += [(bx + 0.42 * S, by + 0.28 * S), (bx - 0.42 * S, by + 0.28 * S)]
        ca, sa = math.cos(wig), math.sin(wig)
        bell = [(bx + (px - bx) * ca - (py - by) * sa, by + (px - bx) * sa + (py - by) * ca) for px, py in bell]
        pen.poly(bell, fill=(255, 205, 60) if done else (235, 235, 235))
        d.ellipse([bx - 0.08 * S, by + 0.28 * S, bx + 0.08 * S, by + 0.42 * S], fill=INK)
        # imleç: gelir ve tıklar
        if t < click + 0.5:
            k = ease(min(1.0, t / max(click - 0.1, 0.1)))
            cx_, cy_ = x + 1.6 * S * (1 - k) + 0.3 * S, y + 1.4 * S * (1 - k) + 0.15 * S
            hand = [(cx_, cy_), (cx_, cy_ + 0.55 * S), (cx_ + 0.14 * S, cy_ + 0.42 * S), (cx_ + 0.26 * S, cy_ + 0.66 * S),
                    (cx_ + 0.34 * S, cy_ + 0.62 * S), (cx_ + 0.23 * S, cy_ + 0.39 * S), (cx_ + 0.42 * S, cy_ + 0.39 * S)]
            pen.poly(hand, fill="white")
    elif kind == "scroll":
        w, h = 2.2 * S, 1.3 * S
        unroll = min(1.0, 0.25 + t / 0.6)
        ww = w * unroll
        pen.rrect([x - ww / 2, y - h / 2, x + ww / 2, y + h / 2], int(0.05 * S), fill=(240, 222, 180))
        for i in range(4):
            yy = y - h / 2 + 0.3 * S + i * 0.22 * S
            if ww > 0.8 * S:
                d.line([(x - ww / 2 + 0.25 * S, yy), (x + ww / 2 - 0.25 * S - (i % 2) * 0.3 * S, yy)], fill=(140, 110, 80),
                       width=max(2, int(5 * s)))
        for sx in (-1, 1):
            pen.rrect([x + sx * ww / 2 - 0.16 * S, y - h / 2 - 0.12 * S, x + sx * ww / 2 + 0.16 * S, y + h / 2 + 0.12 * S],
                      int(0.12 * S), fill=(200, 170, 120))
        if spec.get("text"):
            text_center(d, (x, y), prop_text(spec, lang), 0.42 * S, fill=(90, 60, 40), max_w=ww * 0.8)
    elif kind == "column":
        w, h = 0.55 * S, 2.2 * S
        pen.rrect([x - w / 2, y - h / 2 + 0.25 * S, x + w / 2, y + h / 2 - 0.2 * S], 0, fill=(235, 228, 212))
        for i in range(1, 4):
            fx = x - w / 2 + i * w / 4
            d.line([(fx, y - h / 2 + 0.3 * S), (fx, y + h / 2 - 0.25 * S)], fill=(190, 180, 160), width=max(2, int(4 * s)))
        pen.rrect([x - w * 0.8, y - h / 2, x + w * 0.8, y - h / 2 + 0.25 * S], int(0.05 * S), fill=(235, 228, 212))
        pen.rrect([x - w * 0.75, y + h / 2 - 0.2 * S, x + w * 0.75, y + h / 2], 0, fill=(235, 228, 212))
    elif kind == "hourglass":
        w, h = 1.0 * S, 1.6 * S
        k = min(1.0, t / 4.0)
        pen.rrect([x - w * 0.6, y - h / 2 - 0.12 * S, x + w * 0.6, y - h / 2 + 0.04 * S], int(0.04 * S), fill=(130, 85, 50))
        pen.rrect([x - w * 0.6, y + h / 2 - 0.04 * S, x + w * 0.6, y + h / 2 + 0.12 * S], int(0.04 * S), fill=(130, 85, 50))
        top_sand = (1 - k) * 0.85
        d.polygon([(x - w / 2 * top_sand, y - h * 0.05 - h * 0.4 * top_sand), (x + w / 2 * top_sand, y - h * 0.05 - h * 0.4 * top_sand),
                   (x, y - h * 0.03)], fill=(230, 190, 110))
        d.polygon([(x - w / 2 * 0.85, y + h / 2 - 0.05 * S), (x + w / 2 * 0.85, y + h / 2 - 0.05 * S),
                   (x, y + h / 2 - 0.05 * S - h * 0.38 * (0.15 + 0.85 * k))], fill=(230, 190, 110))
        if k < 1:
            d.line([(x, y - h * 0.03), (x, y + h / 2 - 0.1 * S)], fill=(230, 190, 110), width=max(2, int(4 * s)))
        pen.line([(x - w / 2, y - h / 2), (x - 0.08 * S, y), (x - w / 2, y + h / 2)], color=(90, 70, 60), w=int(pen.lw * 0.6))
        pen.line([(x + w / 2, y - h / 2), (x + 0.08 * S, y), (x + w / 2, y + h / 2)], color=(90, 70, 60), w=int(pen.lw * 0.6))
    elif kind == "quill":
        ang = math.radians(-35 + 8 * math.sin(t * 6))
        L_ = 1.9 * S
        tipx, tipy = x - math.sin(ang) * L_ / 2, y + math.cos(ang) * L_ / 2
        topx, topy = x + math.sin(ang) * L_ / 2, y - math.cos(ang) * L_ / 2
        nx_, ny_ = math.cos(ang) * 0.32 * S, math.sin(ang) * 0.32 * S
        midx, midy = (tipx + topx) / 2, (tipy + topy) / 2
        pen.poly([(tipx, tipy), (midx - nx_, midy - ny_), (topx, topy), (midx + nx_ * 0.6, midy + ny_ * 0.6)], fill=(245, 242, 235))
        pen.line([(tipx, tipy), (topx, topy)], color=(120, 100, 80), w=int(pen.lw * 0.5))
        d.ellipse([tipx - 0.08 * S, tipy - 0.08 * S, tipx + 0.08 * S, tipy + 0.08 * S], fill=(30, 30, 40))
    elif kind == "crown":
        w, h = 1.8 * S, 1.0 * S
        pts = [(x - w / 2, y + h / 2), (x - w / 2, y - h / 4), (x - w / 4, y + h / 8), (x, y - h / 2), (x + w / 4, y + h / 8),
               (x + w / 2, y - h / 4), (x + w / 2, y + h / 2)]
        pen.poly(pts, fill=(235, 185, 60))
        for gx_, gc in ((x - w / 3, RED), (x, BLUE), (x + w / 3, GREEN)):
            d.ellipse([gx_ - 0.1 * S, y + h / 4 - 0.1 * S, gx_ + 0.1 * S, y + h / 4 + 0.1 * S], fill=gc, outline=INK, width=2)
    elif kind == "laurel":
        r = 0.9 * S
        for side in (-1, 1):
            for i in range(7):
                a = math.radians(200 - i * 22) if side < 0 else math.radians(-20 + i * 22)
                lx_, ly_ = x + math.cos(a) * r * side * (-1 if side < 0 else 1), y + math.sin(a) * r * 0.9
                lx_ = x + side * abs(math.cos(a)) * r
                ly_ = y - math.sin(math.radians(i * 22 - 40)) * r * 0.9
                d.ellipse([lx_ - 0.18 * S, ly_ - 0.1 * S, lx_ + 0.18 * S, ly_ + 0.1 * S], fill=(110, 150, 70), outline=INK, width=2)
        if spec.get("text"):
            text_center(d, (x, y), prop_text(spec, lang), 0.55 * S, fill=INK, max_w=1.4 * S)
    elif kind == "portrait":
        w, h = 1.7 * S, 2.1 * S
        pen.rrect([x - w / 2, y - h / 2, x + w / 2, y + h / 2], int(0.05 * S), fill=(190, 145, 70))
        d.rectangle([x - w / 2 + 0.16 * S, y - h / 2 + 0.16 * S, x + w / 2 - 0.16 * S, y + h / 2 - 0.5 * S], fill=(225, 210, 180))
        hx_, hy_ = x, y - 0.35 * S
        d.ellipse([hx_ - 0.32 * S, hy_ - 0.4 * S, hx_ + 0.32 * S, hy_ + 0.35 * S], fill=(110, 90, 75))
        d.chord([x - 0.6 * S, hy_ + 0.3 * S, x + 0.6 * S, y + h / 2 - 0.2 * S], 180, 360, fill=(110, 90, 75))
        d.rectangle([x - w / 2 + 0.16 * S, y + h / 2 - 0.52 * S, x + w / 2 - 0.16 * S, y + h / 2 - 0.16 * S], fill=(60, 40, 30))
        if spec.get("text"):
            text_center(d, (x, y + h / 2 - 0.34 * S), prop_text(spec, lang), 0.26 * S, fill=(235, 200, 120), max_w=w - 0.4 * S)
    elif kind == "chain":
        n = 5
        for i in range(n):
            cx_ = x - 1.0 * S + i * 0.5 * S
            cy_ = y + 0.08 * S * math.sin(t * 3 + i)
            if i % 2 == 0:
                d.ellipse([cx_ - 0.32 * S, cy_ - 0.2 * S, cx_ + 0.32 * S, cy_ + 0.2 * S], outline=(120, 120, 130), width=int(pen.lw * 0.9))
            else:
                d.ellipse([cx_ - 0.3 * S, cy_ - 0.08 * S, cx_ + 0.3 * S, cy_ + 0.08 * S], outline=(150, 150, 160), width=int(pen.lw * 0.9))
        if spec.get("broken") and t > 0.5:
            d.line([(x - 0.15 * S, y - 0.3 * S), (x + 0.15 * S, y + 0.3 * S)], fill=RED, width=int(pen.lw))
    elif kind == "scales":
        tilt = 0.25 * math.sin(min(t, 1.5) * 2) * spec.get("tilt", 1)
        pen.line([(x, y - 0.9 * S), (x, y + 0.9 * S)], w=int(pen.lw * 0.8))
        pen.line([(x - 0.5 * S, y + 0.9 * S), (x + 0.5 * S, y + 0.9 * S)], w=int(pen.lw * 0.8))
        lx_, ly_ = x - 1.1 * S, y - 0.75 * S + tilt * S
        rx_, ry_ = x + 1.1 * S, y - 0.75 * S - tilt * S
        pen.line([(lx_, ly_), (rx_, ry_)], w=int(pen.lw * 0.8))
        for (px, py), lbl in (((lx_, ly_), spec.get("left")), ((rx_, ry_), spec.get("right"))):
            pen.line([(px, py), (px - 0.35 * S, py + 0.6 * S)], w=int(pen.lw * 0.4))
            pen.line([(px, py), (px + 0.35 * S, py + 0.6 * S)], w=int(pen.lw * 0.4))
            d.chord([px - 0.45 * S, py + 0.4 * S, px + 0.45 * S, py + 0.85 * S], 0, 180, fill=(220, 180, 80), outline=INK, width=3)
            if lbl:
                txt = lbl.get(lang, lbl.get("en")) if isinstance(lbl, dict) else lbl
                text_center(d, (px, py + 1.15 * S), txt, 0.3 * S, fill=INK, max_w=1.2 * S)
    else:
        raise ValueError(f"Bilinmeyen aksesuar: {kind}")


def prop_pos(spec, F, anchors):
    pos = spec.get("pos", "center")
    cx, cy = F["prop_c"]
    dx = F["prop_dx"]
    if isinstance(pos, list):
        return pos[0] * F["w"], pos[1] * F["h"]
    if pos in anchors:
        ax, ay = anchors[pos]
        ox, oy = spec.get("offset", [0, 0])
        return ax + ox * 100 * F["sc"], ay + oy * 100 * F["sc"]
    return {"center": (cx, cy), "left": (cx - dx, cy), "right": (cx + dx, cy),
            "top": (cx, cy - dx * 0.8), "bottom": (cx, cy + dx * 0.8)}[pos]


# --------------------------------------------------------------------------- #
# Ses
# --------------------------------------------------------------------------- #
_kokoro = None


def tts(text, lang, speed):
    global _kokoro
    if _kokoro is None:
        from kokoro_onnx import Kokoro
        _kokoro = Kokoro(os.path.join(MODEL_DIR, "kokoro-v1.0.onnx"), os.path.join(MODEL_DIR, "voices-v1.0.bin"))
    cfg = dict(LANGS[lang])
    cfg["voice"] = CUR.get("voices", {}).get(lang, cfg["voice"])
    text = text.replace("*", "")
    speed = speed * CUR.get("speech_rate", 1.0)
    # daha insani okuma: cümle cümle seslendir, aralara doğal duraklar koy
    import re
    parts = [p.strip() for p in re.split(r"(?<=[.!?…])\s+|(?<=—)\s+", text) if p.strip()]
    out = []
    for i, part in enumerate(parts):
        samples, sr = _kokoro.create(part, voice=cfg["voice"], speed=speed, lang=cfg["kokoro"])
        assert sr == SR
        a = np.asarray(samples, dtype=np.float32)
        # baştaki/sondaki sessizliği kırp
        nz = np.nonzero(np.abs(a) > 0.01)[0]
        if len(nz):
            a = a[max(0, nz[0] - int(0.03 * SR)):nz[-1] + int(0.06 * SR)]
        out.append(a)
        if i < len(parts) - 1:
            end = part.rstrip()[-1:]
            pause = {"?": 0.5, "…": 0.6, ".": 0.38, "!": 0.4, "—": 0.22}.get(end, 0.3)
            if part.rstrip().endswith("..."):
                pause = 0.6
            out.append(np.zeros(int(pause * SR), dtype=np.float32))
    return np.concatenate(out) if out else np.zeros(1, dtype=np.float32)


def envelope(audio, n_frames):
    spf = SR / FPS
    env = np.zeros(n_frames, dtype=np.float32)
    for i in range(n_frames):
        a, b = int(i * spf), int((i + 1) * spf)
        seg = audio[a:b]
        if len(seg):
            env[i] = float(np.sqrt(np.mean(seg ** 2)))
    peak = np.percentile(env[env > 0], 95) if np.any(env > 0) else 1
    env = np.clip(env / (peak + 1e-6), 0, 1)
    env[env < 0.12] = 0
    return env


# --------------------------------------------------------------------------- #
# Altyazı parçaları
# --------------------------------------------------------------------------- #
def chunk_words(text, max_chars):
    words = text.split()
    out, cur = [], []
    for w in words:
        if cur and (len(" ".join(cur + [w])) > max_chars):
            out.append(" ".join(cur))
            cur = []
        cur.append(w)
        if w[-1:] in ".?!।:" and len(" ".join(cur)) > max_chars * 0.4:
            out.append(" ".join(cur))
            cur = []
    if cur:
        out.append(" ".join(cur))
    return out


def timed_chunks(text, start, dur, max_chars):
    parts = chunk_words(text, max_chars)
    total = sum(len(p) + 3 for p in parts)
    t = start
    res = []
    for p in parts:
        d = dur * (len(p) + 3) / total
        res.append((t, t + d, p))
        t += d
    return res


def srt_time(x):
    ms = int(round(x * 1000))
    h, ms = divmod(ms, 3600000)
    m, ms = divmod(ms, 60000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def write_srt(path, chunks):
    with open(path, "w", encoding="utf-8") as f:
        for i, (a, b, txt) in enumerate(chunks, 1):
            f.write(f"{i}\n{srt_time(a)} --> {srt_time(b)}\n{txt}\n\n")


# --------------------------------------------------------------------------- #
# Zaman çizelgesi ve render
# --------------------------------------------------------------------------- #
GAP = 0.35
LEAD = 0.2
TAIL = 0.9


def build_timeline(scenes, langs, speed):
    """Her sahne için her dilin sesini üretir. Döner: [(sahne, {dil: ses})]."""
    out = []
    for i, sc in enumerate(scenes):
        audios = {}
        for lang in langs:
            txt = sc["say"].get(lang)
            if not txt:
                sys.exit(f"Sahne {i + 1} için '{lang}' metni yok.")
            audios[lang] = tts(txt, lang, sc.get("speed", speed))
        out.append((sc, audios))
        print(f"  ses: sahne {i + 1}/{len(scenes)}", flush=True)
    return out


def layout(timeline, durs_for, loop=False):
    """Sahne başlangıç zamanları ve süreleri. loop=True: sonda boşluk yok (Shorts döngüsü)."""
    t = 0.05 if loop else LEAD
    spans = []
    for idx, (sc, audios) in enumerate(timeline):
        d = durs_for(audios) + CUR["theme"].get("gap", GAP)
        spans.append((t, d))
        t += d
    return spans, t + (0.1 if loop else TAIL)


def mix_audio(timeline, spans, total, lang):
    """Sadece konuşma kanalı (ağız animasyonu için de kullanılır)."""
    buf = np.zeros(int(total * SR) + SR, dtype=np.float32)
    for (sc, audios), (st, _) in zip(timeline, spans):
        a = audios[lang]
        i = int(st * SR)
        buf[i:i + len(a)] += a
    buf = buf[:int(total * SR)]
    peak = np.max(np.abs(buf)) or 1
    return buf * (0.85 / peak)


LOUDNORM = "loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000"  # YouTube hedef ses seviyesi
REVEAL = 0.45          # aksesuarın "çizilerek" belirme süresi
SWIPE = 0.36           # geçiş bandı süresi
BRAND = [(255, 201, 60), (255, 107, 91), (46, 196, 182), (120, 110, 230)]
ANCHORED = ("hand_r", "hand_l", "hands", "head")


def sfx_events(timeline, spans):
    ev = []
    for i, ((sc, _), (st, dur)) in enumerate(zip(timeline, spans)):
        if i > 0:
            if CUR["theme"].get("whoosh", True):
                ev.append(("whoosh", st - SWIPE / 2 - 0.05, 0.55))
        if sc.get("punch"):
            ev.append(("boom", st, 0.7))
        for j, spec in enumerate(sc.get("props", [])):
            at = st + spec.get("delay", 0.0)
            if spec.get("pos") in ANCHORED:
                ev.append(("pop", at, 0.45))
            else:
                ev.append(("scribble", at, 0.6))
            if spec["type"] in ("check", "bulb", "coin"):
                ev.append(("ding", at + REVEAL * 0.7, 0.45))
            if spec["type"] == "clock":
                for k in range(4):
                    ev.append(("tick", at + 0.5 + k * 0.5, 0.5))
        for spec in sc.get("props", []):
            if spec["type"] == "subscribe":
                at = st + spec.get("delay", 0.0) + spec.get("click", 1.1)
                ev.append(("click", at, 0.8))
                ev.append(("ding", at + 0.1, 0.5))
        for e in sc.get("sfx", []):
            ev.append((e["name"], st + e.get("at", 0.0), e.get("gain", 0.6)))
    return ev


def final_mix(voice, events, use_music):
    from ses import sfx, music, duck, place
    out = voice.copy()
    fx = np.zeros_like(voice)
    for k, (name, at, gain) in enumerate(events):
        place(fx, sfx(name, seed=k), at, gain)
    out += fx * 0.8
    if use_music:
        m = music(len(voice) / SR, style=CUR["theme"]["music"])
        m = m[:len(voice)]
        out[:len(m)] += duck(m, voice, depth=CUR["theme"].get("duck", 0.7)) * CUR["theme"].get("music_gain", 0.13)
    peak = np.max(np.abs(out))
    if peak > 0.97:
        out = np.tanh(out * 1.1) * (0.97 / np.tanh(peak * 1.1))
    return out.astype(np.float32)


def caption_word_times(caps):
    """Altyazı parçalarından anahtar kelime (*...*) zamanları."""
    times = []
    for a, b, txt in caps:
        for (t0, t1, w, kw) in ab.word_times(a, b, txt):
            if kw:
                times.append(t0)
    # aynı vurgunun ardışık kelimeleri tek vuruş olsun
    out = []
    for t in times:
        if not out or t - out[-1] > 0.6:
            out.append(t)
    return out


def camera_zoom(t, st, dur, scene, kw_times):
    z = 1.0 + 0.04 * min(1.0, max(0.0, t - st) / max(dur, 0.1))  # yavaş yaklaşma
    for k in kw_times:
        dt = t - k
        if -0.08 < dt < 0.7:
            z += 0.05 * (ease((dt + 0.08) / 0.08) if dt < 0 else math.exp(-dt * 5))
    if scene.get("punch"):
        dt = t - st
        if 0 <= dt < 0.9:
            z += 0.12 * math.exp(-dt * 4)
    return z


def apply_camera(img, F, z, shake=(0, 0)):
    z = max(z, 1.0)
    if abs(z - 1.0) < 1e-3 and shake == (0, 0):
        return img
    W, H = F["w"], F["h"]
    fx, fy = F.get("focus", (W / 2, H / 2))
    cw, ch = W / z, H / z
    x0 = min(max(fx - cw / 2 + shake[0], 0), W - cw)
    y0 = min(max(fy - ch / 2 + shake[1], 0), H - ch)
    return img.resize((W, H), Image.BILINEAR, box=(x0, y0, x0 + cw, y0 + ch))


def draw_swipe(img, F, u, color):
    """Sahne geçişi: el çizimi renkli bant ekranı süpürür."""
    W, H = F["w"], F["h"]
    d = ImageDraw.Draw(img)
    skew = 0.3 * W
    bw = 1.5 * W
    cx = -bw + u * (W + 2 * bw)
    pts = [(cx - bw / 2 + skew, 0), (cx + bw / 2 + skew, 0), (cx + bw / 2 - skew, H), (cx - bw / 2 - skew, H)]
    d.polygon(pts, fill=color)
    lw = int(10 * F["sc"])
    d.line([pts[0], pts[3]], fill=INK, width=lw)
    d.line([pts[1], pts[2]], fill=INK, width=lw)
    for k in range(5):  # bandın üzerinde yıldız karalamaları
        yy = H * (0.15 + 0.17 * k)
        xx = cx + skew * (1 - 2 * yy / H) + (k % 2 - 0.5) * bw * 0.4
        if CUR["theme"]["stars"]:
            ab.doodle_star(d, xx, yy, 30 * F["sc"], (255, 255, 255), max(2, int(4 * F["sc"])))
        else:  # ince altın çizgi
            d.line([(cx + skew * 0.9 - bw * 0.35, 0), (cx - skew * 0.9 - bw * 0.35, H)], fill=(215, 175, 85), width=lw // 2)


def draw_badge(img, F, text, cap_box=None):
    """Bölüm etiketi (ör. KURAL 1): altyazı kutusunun üst kenarına yapışık sekme."""
    d = ImageDraw.Draw(img)
    size = F["cap_size"] * 0.5
    f = font(size)
    tw = d.textlength(text, font=f)
    pad = size * 0.5
    w, h = tw + pad * 2, size * 1.35
    if cap_box:
        x0 = cap_box[0] + size * 0.3
        y0 = cap_box[1] - h * 0.72
    else:
        x0, y0 = 40, 30
    d.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=int(h * 0.45), fill=CUR["theme"]["badge"], outline=INK,
                        width=max(3, int(5 * F["sc"])))
    d.text((x0 + w / 2, y0 + h / 2), text, font=f, fill="white", anchor="mm", stroke_width=2, stroke_fill=INK)


# --------------------------------------------------------------------------- #
# Sahne görselleri: tarihî tablo/fotoğraf + Ken Burns + film dokusu
# --------------------------------------------------------------------------- #
_img_cache = {}
_grain_tiles = {}


def _grade(im, theme):
    arr = np.asarray(im.convert("RGB")).astype(np.float32)
    if theme == "academia":  # sıcak, hafif sepya, kontrast
        lum = arr.mean(axis=2, keepdims=True)
        sep = np.concatenate([lum * 1.07, lum * 0.97, lum * 0.82], axis=2)
        arr = arr * 0.72 + sep * 0.28
        arr = (arr - 128) * 1.08 + 128
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))


def cutaway_source(spec, F):
    """Sahne görselini hazırlar: (kaynak_görüntü, mod)."""
    key = (spec["file"], F["w"], F["h"])
    if key in _img_cache:
        return _img_cache[key]
    import gorsel
    path, info = gorsel.fetch(spec["file"])
    im = _grade(Image.open(path), "academia" if CUR["theme"] is THEMES["academia"] else "")
    W, H = F["w"], F["h"]
    ar_img, ar_frame = im.width / im.height, W / H
    mode = spec.get("fit") or ("contain" if max(ar_img / ar_frame, ar_frame / ar_img) > 1.6 else "cover")
    if mode == "cover":
        sc_ = max(W / im.width, H / im.height) * 1.25
        src = im.resize((int(im.width * sc_), int(im.height * sc_)), Image.LANCZOS)
        bg = None
    else:  # bulanık arka plan + çerçeveli tablo
        sc_ = min(W * 0.94 / im.width, H * 0.6 / im.height)
        src = im.resize((int(im.width * sc_), int(im.height * sc_)), Image.LANCZOS)
        from PIL import ImageFilter, ImageEnhance
        cov = max(W / im.width, H / im.height) * 1.1
        bg = im.resize((int(im.width * cov), int(im.height * cov)), Image.BILINEAR)
        bg = bg.crop(((bg.width - W) // 2, (bg.height - H) // 2, (bg.width - W) // 2 + W, (bg.height - H) // 2 + H))
        bg = ImageEnhance.Brightness(bg.filter(ImageFilter.GaussianBlur(40))).enhance(0.45)
    _img_cache[key] = (src, mode, bg, info)
    return _img_cache[key]


class VideoClip:
    """ffmpeg ile video karelerini sırayla okur (kapla + kırp, 30 fps, sessiz). Biterse başa sarar."""

    def __init__(self, spec, F):
        import gorsel
        self.path, self.info = gorsel.fetch(spec["file"])
        self.W, self.H = F["w"], F["h"]
        self.start = spec.get("start", 0.0)
        self.speed = spec.get("speed", 1.0)
        self.proc = None
        self.last = None

    def _open(self):
        vf = (f"setpts=PTS/{self.speed},scale={self.W}:{self.H}:force_original_aspect_ratio=increase,"
              f"crop={self.W}:{self.H},fps={FPS}")
        self.proc = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-ss", str(self.start), "-i", self.path, "-an",
                                      "-vf", vf, "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)

    def frame(self):
        n = self.W * self.H * 3
        for _ in range(2):
            if self.proc is None:
                self._open()
            buf = self.proc.stdout.read(n)
            if len(buf) == n:
                self.last = Image.frombytes("RGB", (self.W, self.H), buf)
                return self.last
            self.close()  # bitti: başa sar
        return self.last or Image.new("RGB", (self.W, self.H))

    def close(self):
        if self.proc:
            self.proc.kill()
            self.proc.wait()
            self.proc = None


_clips = {}
_sketches = {}


def render_cutaway(spec, F, lt, dur, t, scene_key=None):
    W, H = F["w"], F["h"]
    if spec.get("file", "").lower().endswith(("webm", "ogv", "mp4", "mpg", "mpeg")) or spec.get("video"):
        if scene_key not in _clips:
            for c in _clips.values():
                c.close()
            _clips.clear()
            _clips[scene_key] = VideoClip(spec, F)
        img = _clips[scene_key].frame()
        if CUR["theme"] is THEMES["academia"]:
            img = _grade(img, "academia")
        return film_finish(img, F, t, spec)
    src, mode, bg, info = cutaway_source(spec, F)
    u = min(1.0, max(0.0, lt / max(dur, 0.1)))
    move = spec.get("move", "in")
    fx, fy = spec.get("focus", [0.5, 0.4])
    if mode == "cover":
        z = 1.0 + 0.12 * (u if move != "out" else 1 - u)
        cw, ch = W * 1.0 / (src.width / (W * 1.25)) / z / 1.0, None
        # görünen pencere (kaynak piksel cinsinden)
        base = min(src.width / W, src.height / H)
        cw, ch = W * base / z, H * base / z
        cx = fx * src.width
        cy = fy * src.height
        if move == "left":
            cx += (0.5 - u) * cw * 0.2
        elif move == "right":
            cx -= (0.5 - u) * cw * 0.2
        x0 = min(max(cx - cw / 2, 0), src.width - cw)
        y0 = min(max(cy - ch / 2, 0), src.height - ch)
        img = src.resize((W, H), Image.BILINEAR, box=(x0, y0, x0 + cw, y0 + ch))
    else:
        img = bg.copy()
        z = 1.0 + 0.06 * u
        pw, ph = int(src.width * z), int(src.height * z)
        pic = src.resize((pw, ph), Image.BILINEAR)
        px, py = (W - pw) // 2, int(H * 0.5 - ph / 2)
        d = ImageDraw.Draw(img)
        fr = int(14 * F["sc"])
        d.rectangle([px - fr, py - fr, px + pw + fr, py + ph + fr], fill=(150, 115, 55))
        d.rectangle([px - fr // 3, py - fr // 3, px + pw + fr // 3, py + ph + fr // 3], fill=(60, 42, 25))
        img.paste(pic, (px, py))
    return film_finish(img, F, t, spec)


def film_finish(img, F, t, spec):
    """Film dokusu: kumlanma + hafif titreme + vinyet + kaynak etiketi."""
    W, H = F["w"], F["h"]
    key = (W, H)
    if key not in _grain_tiles:
        rng = np.random.default_rng(5)
        tiles = [rng.normal(0, 7, (H // 2, W // 2)).astype(np.float32) for _ in range(4)]
        yy, xx = np.ogrid[0:H, 0:W]
        r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
        vig = (1 - 0.45 * np.clip(r - 0.5, 0, 1) ** 1.4).astype(np.float32)
        _grain_tiles[key] = (tiles, vig)
    tiles, vig = _grain_tiles[key]
    g = np.kron(tiles[int(t * 12) % 4], np.ones((2, 2), dtype=np.float32))[:H, :W]
    flick = 1 + 0.015 * math.sin(t * 23) * math.sin(t * 7)
    arr = np.asarray(img).astype(np.float32) * (vig * flick)[..., None] + g[..., None]
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    lbl = spec.get("label")
    if lbl:
        txt = lbl.get(CUR["lang"], lbl.get("en")) if isinstance(lbl, dict) else lbl
        d = ImageDraw.Draw(img, "RGBA")
        f = font(26 * F["sc"])
        tw = d.textlength(txt, font=f)
        y = H - (330 if H > W else 70) * F["sc"]
        d.rectangle([30, y - 6, 30 + tw + 24, y + 30 * F["sc"] + 6], fill=(0, 0, 0, 120))
        d.text((42, y), txt, font=f, fill=(235, 220, 190))
    return img


LOOK = {"point_right": (1, 0), "point_left": (-1, 0), "phone": (0.6, 0.9), "read": (0, 1), "idea": (0.3, -1),
        "think": (0.7, -0.8), "tired": (0, 0.6), "sad": (0, 0.7)}


def look_dir(scene, pname, lt, F, face):
    """Yeni beliren nesneye 1 sn bak (izleyicinin dikkatini oraya yönlendirir), sonra kameraya/poz yönüne."""
    for spec in scene.get("props", []):
        if spec.get("pos") in ANCHORED:
            continue
        dl = lt - spec.get("delay", 0.0)
        if 0 <= dl < 1.1:
            x, y = prop_pos(spec, F, {})
            dx, dy = x - face[0], y - face[1]
            n = math.hypot(dx, dy) or 1
            return dx / n, dy / n
    return LOOK.get(pname, (0.0, 0.0))


def render_prop(img, pen_seed, spec, F, anchors, lt, dur, lang):
    delay = spec.get("delay", 0.0)
    if lt < delay:
        return
    sc_ = F["sc"]
    x, y = prop_pos(spec, F, anchors)
    anchored = spec.get("pos") in ANCHORED
    pt = lt - delay
    base = spec.get("size", 1.0) * sc_ * F["prop_sc"]
    k = 1.0
    if dur - lt < 0.2:
        k *= max(0.0, (dur - lt) / 0.2)
    if anchored:
        k *= ease_back(pt / 0.3)
    else:
        k *= 0.9 + 0.1 * ease_back(pt / REVEAL)
        y += 6 * math.sin(lt * 2 + len(spec["type"])) * sc_
    if k <= 0.12:
        return
    if anchored or pt >= REVEAL:
        d = ImageDraw.Draw(img)
        draw_prop(Pen(d, sc_, pen_seed), spec, (x, y), base * k, pt, lang)
        return
    # çizilerek belirme: şeffaf katmana çiz, soldan sağa maske ile aç
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw_prop(Pen(ImageDraw.Draw(layer), sc_, pen_seed), spec, (x, y), base * k, pt, lang)
    bbox = layer.getbbox()
    if not bbox:
        return
    u = ease(pt / REVEAL)
    edge = bbox[0] + (bbox[2] - bbox[0] + 40) * u
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rectangle([bbox[0] - 5, bbox[1] - 5, edge, bbox[3] + 5], fill=255)
    alpha = Image.composite(layer.getchannel("A"), mask, mask)
    layer.putalpha(alpha)
    img.paste(layer, (0, 0), layer)
    # kalem ucu
    d = ImageDraw.Draw(img)
    py = bbox[1] + (bbox[3] - bbox[1]) * (0.5 + 0.4 * math.sin(pt * 40))
    r = 9 * sc_
    if edge < bbox[2]:
        d.line([(edge, py), (edge + 40 * sc_, py - 70 * sc_)], fill=INK, width=int(12 * sc_))
        d.ellipse([edge - r, py - r, edge + r, py + r], fill=INK)


def render_video(path_noext, timeline, spans, total, F, lang, audio, captions, env, kw_times=(), badges=True):
    W, H = F["w"], F["h"]
    n = int(math.ceil(total * FPS))
    wav = path_noext + ".wav"
    import soundfile as sf
    sf.write(wav, audio, SR)
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
           "-r", str(FPS), "-i", "-", "-i", wav, "-c:v", "libx264", "-preset", "medium", "-crf", "20",
           "-pix_fmt", "yuv420p", "-af", LOUDNORM, "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart",
           path_noext + ".mp4"]
    ff = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    sc_ = F["sc"]
    bg_cache = {}
    scene_idx = 0
    for fi in range(n):
        t = fi / FPS
        while scene_idx + 1 < len(spans) and t >= spans[scene_idx + 1][0]:
            scene_idx += 1
        st, dur = spans[scene_idx]
        scene = timeline[scene_idx][0]
        lt = t - st if t >= st else 0.0
        pname = scene.get("pose", "talk")
        p, expr = pose(pname, lt)
        expr = scene.get("expr", expr)
        if scene_idx > 0:
            prev_scene = timeline[scene_idx - 1][0]
            pp, _ = pose(prev_scene.get("pose", "talk"), lt + spans[scene_idx - 1][1])
            p = blend(pp, p, ease(lt / 0.3))

        media = scene.get("image") or scene.get("video")
        if scene.get("sketch") is not None:
            media = media or {}
            if scene_idx not in _sketches:
                import eskiz
                _sketches.clear()
                sk = eskiz.SketchScene(scene["sketch"], W, H, seed=scene_idx * 13 + 1)
                _sketches[scene_idx] = (sk, max(1.0, sk.end / max(dur * 0.55, 0.5)))
            sk, speed = _sketches[scene_idx]
            img = sk.frame(lt * speed)
        elif media and media.get("style") == "sketch":  # gerçek portre/tablo, karakalem olarak çizilir
            if scene_idx not in _sketches:
                import gorsel
                import karakalem
                path, _info = gorsel.fetch(media["file"])
                skp = karakalem.Sketch(Image.open(path), W, H, mode=media.get("fit", "contain"),
                                       focus=tuple(media.get("focus", [0.5, 0.4])), tint=media.get("tint", 0.22), seed=scene_idx + 3)
                _sketches.clear()
                _sketches[scene_idx] = (skp, min(3.2, max(1.2, dur * 0.5)))
            skp, dtime = _sketches[scene_idx]
            img = skp.frame(lt / dtime)
            if media.get("label") and lt > dtime * 0.7:
                import eskiz
                eskiz.Text(media["label"], W / 2, H * 0.08, int(46 * W / 1920), eskiz.INK).draw(img, min(1.0, (lt - dtime * 0.7) / 0.8))
        elif media:
            img = render_cutaway(media, F, lt, dur, t, scene_key=scene_idx)
        if media is not None and (media or scene.get("sketch") is not None):
            if scene.get("props") and media:
                dim = media.get("dim", 0.3)
                if dim:
                    img = Image.blend(img, Image.new("RGB", img.size, (0, 0, 0)), dim)
                for j, spec in enumerate(scene["props"]):
                    render_prop(img, fi // 4 + j, spec, F, {}, lt, dur, lang)
            z = camera_zoom(t, st, dur, dict(scene, punch=False), ())
            img = apply_camera(img, F, 1 + (z - 1) * 0.5)
            for i in (scene_idx, scene_idx + 1):
                if 0 < i < len(spans):
                    b = spans[i][0]
                    u = (t - (b - SWIPE / 2)) / SWIPE
                    if 0 <= u <= 1:
                        sw = CUR["theme"]["swipe"]
                        draw_swipe(img, F, u, sw[i % len(sw)])
            if captions:
                for a, b, txt in captions:
                    if a <= t < b:
                        th = CUR["theme"]
                        Fc = dict(F, cap_size=F["cap_size"] * th.get("cap_scale", 1.0))
                        cb = ab.draw_caption(img, Fc, t, a, b, txt, font, highlight=th["cap_cur"], key=th["cap_key"],
                                             box=th["cap_box"], text_col=th.get("cap_text", (255, 255, 255)),
                                             stroke_col=th.get("cap_stroke", (15, 15, 15)),
                                             stroke_scale=th.get("cap_stroke_scale", 1.0))
                        if badges and scene.get("badge") and lt > 0.15:
                            bt = scene["badge"].get(lang) if isinstance(scene["badge"], dict) else scene["badge"]
                            draw_badge(img, Fc, bt, cb)
                        break
            ff.stdin.write(img.tobytes())
            if fi % (FPS * 10) == 0:
                print(f"  video [{lang}]: {t:5.1f}/{total:.1f} sn", flush=True)
            continue
        kind = scene.get("bg", "room")
        if kind not in bg_cache:
            bg_cache[kind] = ab.build_static(kind, F)
        img = bg_cache[kind].copy()
        d = ImageDraw.Draw(img)
        ab.animate(kind, d, F, t)
        pen = Pen(d, sc_, seed=fi // 4)
        fig_c = (F["fig_x"], F["hip_y"] - 120 * sc_)
        for name in scene.get("deco", ab.DEFAULT_DECO.get(pname, [])):
            ab.deco(name, d, F, lt, font, fig_c)
        mouth = float(env[fi]) if env is not None and fi < len(env) else 0.0
        glow = pname in ("idea", "celebrate") or expr == "happy"
        if F.get("character") == "none":
            anchors = {}
        elif F.get("character") == "stick":
            anchors = draw_figure(pen, p, expr, F["fig_x"], F["hip_y"], sc_, mouth, t=t, glow=glow)
        else:
            cs = sc_ * 1.08
            ground = F["hip_y"] + 292 * sc_
            face = (F["fig_x"], ground - 95 * cs - 0.67 * 390 * cs)
            blink = (t % 3.7) < 0.11 or ((t + 1.3) % 5.9) < 0.1
            cs = sc_ * 0.82
            face = (F["fig_x"], ground - 640 * cs)
            glow = pname == "idea"
            anchors = theo.draw_character(img, p, expr, F["fig_x"], ground, cs, mouth, t, glow=glow,
                                              look=look_dir(scene, pname, lt, F, face), blink=blink,
                                              talking=env is not None and mouth > 0.05)
        for j, spec in enumerate(scene.get("props", [])):
            render_prop(img, fi // 4 + j, spec, F, anchors, lt, dur, lang)

        # kamera: yavaş yaklaşma + vurgu kelimelerinde zıplama + şok sarsıntısı
        z = camera_zoom(t, st, dur, scene, kw_times)
        shake = (0, 0)
        if pname == "shock" and lt < 0.5:
            a = 14 * sc_ * (1 - lt / 0.5)
            shake = (a * math.sin(t * 90), a * math.cos(t * 77))
        img = apply_camera(img, F, z, shake)

        # geçiş bandı (bir önceki sahnenin sonu ile bu sahnenin başını örter)
        for i in (scene_idx, scene_idx + 1):
            if 0 < i < len(spans):
                b = spans[i][0]
                u = (t - (b - SWIPE / 2)) / SWIPE
                if 0 <= u <= 1:
                    sw = CUR["theme"]["swipe"]
                    draw_swipe(img, F, u, sw[i % len(sw)])

        cap_box = None
        if captions:
            for a, b, txt in captions:
                if a <= t < b:
                    th = CUR["theme"]
                    Fc = dict(F, cap_size=F["cap_size"] * th.get("cap_scale", 1.0))
                    cap_box = ab.draw_caption(img, Fc, t, a, b, txt, font, highlight=th["cap_cur"], key=th["cap_key"],
                                              box=th["cap_box"])
                    break
        if badges and scene.get("badge"):
            btxt = scene["badge"].get(lang) if isinstance(scene["badge"], dict) else scene["badge"]
            if btxt and lt > 0.15:
                draw_badge(img, dict(F, cap_size=F["cap_size"] * CUR["theme"].get("cap_scale", 1.0)), btxt, cap_box)
        if H < W:  # uzun video: üstte ilerleme çubuğu
            dd = ImageDraw.Draw(img)
            dd.rectangle([0, 0, W, 8], fill=(230, 225, 215))
            dd.rectangle([0, 0, W * t / total, 8], fill=CUR["theme"]["bar"])
        ff.stdin.write(img.tobytes())
        if fi % (FPS * 5) == 0:
            print(f"  video [{lang}]: {t:5.1f}/{total:.1f} sn", flush=True)
    for c in _clips.values():
        c.close()
    _clips.clear()
    ff.stdin.close()
    ff.wait()
    os.remove(wav)
    if ff.returncode != 0:
        sys.exit("ffmpeg hatası")


def image_credits(scenes):
    """Kullanılan sahne görsellerinin atıf satırları (CC BY / BY-SA için zorunlu)."""
    import gorsel
    lines, seen = [], set()
    for sc in scenes:
        f = (sc.get("image") or sc.get("video") or {}).get("file")
        if f and f not in seen:
            seen.add(f)
            info = gorsel._db().get(f)
            if info:
                lines.append(gorsel.credit_line(info))
    return lines


CREDITS = []


def write_notes(path, meta, lang, total):
    m = meta.get(lang, {})
    desc = m.get("description", "")
    if CREDITS:
        desc += "\n\nImages (Wikimedia Commons):\n" + "\n".join("• " + c for c in CREDITS)
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"BAŞLIK:\n{m.get('title', '')}\n\nAÇIKLAMA:\n{desc}\n\n")
        f.write(f"ETİKETLER:\n{', '.join(m.get('tags', []))}\n\nSÜRE: {total:.1f} sn\n")


def plain(txt):
    return txt.replace("*", "")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("senaryo")
    ap.add_argument("--diller", help="virgülle: en,es,pt,hi (varsayılan: senaryodaki hepsi)")
    ap.add_argument("--format", choices=FORMATS, help="short veya long (varsayılan: senaryodaki)")
    ap.add_argument("--mod", choices=["ayri", "coklu"], default="ayri",
                    help="ayri: dil başına ayrı video (altyazı gömülü). coklu: tek video + dil başına ses dosyası")
    ap.add_argument("--hiz", type=float, default=1.0, help="konuşma hızı")
    ap.add_argument("--muziksiz", action="store_true", help="arka plan müziği ekleme")
    ap.add_argument("--cikti", default=os.path.join(ROOT, "cikti"))
    args = ap.parse_args()

    with open(args.senaryo, encoding="utf-8") as f:
        data = json.load(f)
    fmt = args.format or data.get("format", "short")
    F = FORMATS[fmt]
    langs = args.diller.split(",") if args.diller else data.get("languages", ["en"])
    for lg in langs:
        if lg not in LANGS:
            sys.exit(f"Desteklenmeyen dil: {lg}. Desteklenen: {', '.join(LANGS)}")
    sub = data.get("subscribe")
    if sub:  # ilk paragraftan sonra abone ol hatırlatması
        pos = sub.get("after", 1)
        data["scenes"].insert(pos, dict(pose=sub.get("pose", "point_right"), bg=sub.get("bg"), punch=False,
                                        props=[dict(type="subscribe", pos=sub.get("pos", "center"), size=sub.get("size", 1.0),
                                                    click=sub.get("click", 1.2))], say=sub["say"]))
        if sub.get("sketch") is not None:
            data["scenes"][pos]["sketch"] = sub["sketch"]
        for k in ("image", "video"):
            if sub.get(k):
                data["scenes"][pos][k] = dict(sub[k], dim=sub[k].get("dim", 0.45))
    for sc in data["scenes"]:
        if not sc.get("bg"):
            sc.pop("bg", None)
        sc.setdefault("bg", data.get("bg", "room"))
    CUR["theme"] = THEMES[data.get("theme", "playful")]
    CUR["voices"] = data.get("voices", {})
    CUR["speech_rate"] = data.get("speech_rate", 1.0)
    F = dict(F, character=data.get("character", CUR["theme"]["character"]))
    CREDITS[:] = image_credits(data["scenes"])
    slug = data.get("slug") or os.path.splitext(os.path.basename(args.senaryo))[0]
    outdir = os.path.join(args.cikti, slug)
    os.makedirs(outdir, exist_ok=True)
    cap_chars = 22 if fmt == "short" else 42
    use_music = data.get("music", True) and not args.muziksiz

    print(f"Senaryo: {slug} | format: {fmt} | diller: {','.join(langs)} | mod: {args.mod}")
    timeline = build_timeline(data["scenes"], langs, args.hiz)

    def srt_for(spans, lang):
        out = []
        for (sc, au), (st, _) in zip(timeline, spans):
            out += [(a, b, plain(x)) for a, b, x in timed_chunks(sc["say"][lang], st, len(au[lang]) / SR, 42)]
        return out

    if args.mod == "ayri":
        for lang in langs:
            CUR["lang"] = lang
            spans, total = layout(timeline, lambda au, lg=lang: len(au[lg]) / SR, data.get("loop", False))
            voice = mix_audio(timeline, spans, total, lang)
            caps = []
            for (sc, au), (st, _) in zip(timeline, spans):
                caps += timed_chunks(sc["say"][lang], st, len(au[lang]) / SR, cap_chars)
            env = envelope(voice, int(math.ceil(total * FPS)))
            audio = final_mix(voice, sfx_events(timeline, spans), use_music)
            base = os.path.join(outdir, f"{slug}_{fmt}_{lang}")
            render_video(base, timeline, spans, total, F, lang, audio,
                         caps if data.get("burn_captions", True) else None, env, caption_word_times(caps))
            write_srt(base + ".srt", srt_for(spans, lang))
            write_notes(base + "_yukleme.txt", data.get("meta", {}), lang, total)
            for sl in data.get("subtitles", []):  # diğer diller: sadece altyazı (SRT) + çevrilmiş başlık/açıklama
                srt = []
                for (sc, au), (st, _) in zip(timeline, spans):
                    txt = sc["say"].get(sl)
                    if not txt:
                        sys.exit(f"Altyazı için '{sl}' metni eksik: {sc['say'].get(lang, '')[:40]}")
                    srt += [(a, b, plain(x)) for a, b, x in timed_chunks(txt, st, len(au[lang]) / SR, 42)]
                write_srt(f"{base}.{sl}.srt", srt)
                write_notes(f"{base}_yukleme_{sl}.txt", data.get("meta", {}), sl, total)
            print(f"✔ {base}.mp4 ({total:.1f} sn)")
    else:
        spans, total = layout(timeline, lambda au: max(len(a) for a in au.values()) / SR, data.get("loop", False))
        base = os.path.join(outdir, f"{slug}_{fmt}_coklu")
        CUR["lang"] = langs[0]
        events = sfx_events(timeline, spans)
        main_audio = final_mix(mix_audio(timeline, spans, total, langs[0]), events, use_music)
        render_video(base, timeline, spans, total, F, langs[0], main_audio, None, None, badges=False)
        import soundfile as sf
        for lang in langs:
            audio = final_mix(mix_audio(timeline, spans, total, lang), events, use_music)
            wav = f"{base}_{lang}.wav"
            sf.write(wav, audio, SR)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-af", LOUDNORM, "-c:a", "aac", "-b:a", "192k",
                            f"{base}_ses_{lang}.m4a"], check=True)
            os.remove(wav)
            write_srt(f"{base}_{lang}.srt", srt_for(spans, lang))
            write_notes(f"{base}_{lang}_yukleme.txt", data.get("meta", {}), lang, total)
        print(f"✔ {base}.mp4 + {len(langs)} ses kanalı ({total:.1f} sn)")


if __name__ == "__main__":
    main()
