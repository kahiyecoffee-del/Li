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
                  cap_size=104, cap_w=980, prop_c=(540, 530), prop_dx=290, prop_sc=1.3),
    "long": dict(w=1920, h=1080, fig_x=560, hip_y=640, sc=0.85, cap_y=985,
                 cap_size=68, cap_w=1700, prop_c=(1320, 440), prop_dx=360, prop_sc=1.45),
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


def font(size):
    size = int(size)
    if size not in _font_cache:
        _font_cache[size] = ImageFont.truetype(FONT_PATH, size)
    return _font_cache[size]


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


def draw_figure(pen, p, expr, cx, hip_y, sc, mouth_open):
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
    pen.circle(head, r, fill=BG)
    hx, hy = head
    ex, ey, er = 21 * sc, -10 * sc, 7 * sc
    look = 8 * sc if expr == "down" else 0
    d = pen.d
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
    cfg = LANGS[lang]
    samples, sr = _kokoro.create(text, voice=cfg["voice"], speed=speed, lang=cfg["kokoro"])
    assert sr == SR
    return np.asarray(samples, dtype=np.float32)


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


def layout(timeline, durs_for):
    """Sahne başlangıç zamanları ve süreleri."""
    t = LEAD
    spans = []
    for idx, (sc, audios) in enumerate(timeline):
        d = durs_for(audios) + GAP
        spans.append((t, d))
        t += d
    return spans, t + TAIL


def mix_audio(timeline, spans, total, lang):
    buf = np.zeros(int(total * SR) + SR, dtype=np.float32)
    for (sc, audios), (st, _) in zip(timeline, spans):
        a = audios[lang]
        i = int(st * SR)
        buf[i:i + len(a)] += a
    buf = buf[:int(total * SR)]
    peak = np.max(np.abs(buf)) or 1
    return buf * (0.89 / peak)


def render_video(path_noext, timeline, spans, total, F, lang, audio, captions, env):
    W, H = F["w"], F["h"]
    n = int(math.ceil(total * FPS))
    wav = path_noext + ".wav"
    import soundfile as sf
    sf.write(wav, audio, SR)
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
           "-r", str(FPS), "-i", "-", "-i", wav, "-c:v", "libx264", "-preset", "medium", "-crf", "20",
           "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart",
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
        p, expr = pose(scene.get("pose", "talk"), lt)
        expr = scene.get("expr", expr)
        if scene_idx > 0:
            prev_scene = timeline[scene_idx - 1][0]
            pp, _ = pose(prev_scene.get("pose", "talk"), lt + spans[scene_idx - 1][1])
            p = blend(pp, p, ease(lt / 0.3))

        kind = scene.get("bg", "room")
        if kind not in bg_cache:
            bg_cache[kind] = ab.build_static(kind, F)
        img = bg_cache[kind].copy()
        if scene_idx > 0 and lt < 0.35:
            pk = timeline[scene_idx - 1][0].get("bg", "room")
            if pk != kind:
                img = Image.blend(bg_cache[pk], img, ease(lt / 0.35))
        d = ImageDraw.Draw(img)
        ab.animate(kind, d, F, t)
        pen = Pen(d, sc_, seed=fi // 4)
        fig_c = (F["fig_x"], F["hip_y"] - 120 * sc_)
        for name in scene.get("deco", ab.DEFAULT_DECO.get(scene.get("pose", "talk"), [])):
            ab.deco(name, d, F, lt, font, fig_c)
        mouth = float(env[fi]) if env is not None and fi < len(env) else 0.0
        anchors = draw_figure(pen, p, expr, F["fig_x"], F["hip_y"], sc_, mouth)
        for spec in scene.get("props", []):
            delay = spec.get("delay", 0.0)
            if lt < delay:
                continue
            k = ease_back((lt - delay) / 0.35)
            if dur - lt < 0.2:  # sahne sonunda küçülerek çık
                k *= max(0.0, (dur - lt) / 0.2)
            if k <= 0.12:
                continue
            x, y = prop_pos(spec, F, anchors)
            fl = 0 if spec.get("pos") in anchors else 6 * math.sin(lt * 2 + hash(spec["type"]) % 5)
            draw_prop(pen, spec, (x, y + fl * sc_), spec.get("size", 1.0) * sc_ * F["prop_sc"] * k, lt - delay, lang)
        if captions:
            for a, b, txt in captions:
                if a <= t < b:
                    ab.draw_caption(img, F, t, a, b, txt, font)
                    break
        ff.stdin.write(img.tobytes())
        if fi % (FPS * 5) == 0:
            print(f"  video [{lang}]: {t:5.1f}/{total:.1f} sn", flush=True)
    ff.stdin.close()
    ff.wait()
    os.remove(wav)
    if ff.returncode != 0:
        sys.exit("ffmpeg hatası")


def write_notes(path, meta, lang, total):
    m = meta.get(lang, {})
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"BAŞLIK:\n{m.get('title', '')}\n\nAÇIKLAMA:\n{m.get('description', '')}\n\n")
        f.write(f"ETİKETLER:\n{', '.join(m.get('tags', []))}\n\nSÜRE: {total:.1f} sn\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("senaryo")
    ap.add_argument("--diller", help="virgülle: en,es,pt,hi (varsayılan: senaryodaki hepsi)")
    ap.add_argument("--format", choices=FORMATS, help="short veya long (varsayılan: senaryodaki)")
    ap.add_argument("--mod", choices=["ayri", "coklu"], default="ayri",
                    help="ayri: dil başına ayrı video (altyazı gömülü). coklu: tek video + dil başına ses dosyası")
    ap.add_argument("--hiz", type=float, default=1.0, help="konuşma hızı")
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
    for sc in data["scenes"]:
        sc.setdefault("bg", data.get("bg", "room"))
    slug = data.get("slug") or os.path.splitext(os.path.basename(args.senaryo))[0]
    outdir = os.path.join(args.cikti, slug)
    os.makedirs(outdir, exist_ok=True)
    cap_chars = 22 if fmt == "short" else 42

    print(f"Senaryo: {slug} | format: {fmt} | diller: {','.join(langs)} | mod: {args.mod}")
    timeline = build_timeline(data["scenes"], langs, args.hiz)

    if args.mod == "ayri":
        for lang in langs:
            spans, total = layout(timeline, lambda au, lg=lang: len(au[lg]) / SR)
            audio = mix_audio(timeline, spans, total, lang)
            caps, srt = [], []
            for (sc, au), (st, _) in zip(timeline, spans):
                d = len(au[lang]) / SR
                caps += timed_chunks(sc["say"][lang], st, d, cap_chars)
                srt += timed_chunks(sc["say"][lang], st, d, 42)
            env = envelope(audio, int(math.ceil(total * FPS)))
            base = os.path.join(outdir, f"{slug}_{fmt}_{lang}")
            render_video(base, timeline, spans, total, F, lang, audio, caps if data.get("burn_captions", True) else None, env)
            write_srt(base + ".srt", srt)
            write_notes(base + "_yukleme.txt", data.get("meta", {}), lang, total)
            print(f"✔ {base}.mp4 ({total:.1f} sn)")
    else:
        spans, total = layout(timeline, lambda au: max(len(a) for a in au.values()) / SR)
        base = os.path.join(outdir, f"{slug}_{fmt}_coklu")
        main_audio = mix_audio(timeline, spans, total, langs[0])
        render_video(base, timeline, spans, total, F, langs[0], main_audio, None, None)
        import soundfile as sf
        for lang in langs:
            audio = mix_audio(timeline, spans, total, lang)
            wav = f"{base}_{lang}.wav"
            sf.write(wav, audio, SR)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "aac", "-b:a", "192k",
                            f"{base}_ses_{lang}.m4a"], check=True)
            os.remove(wav)
            srt = []
            for (sc, au), (st, _) in zip(timeline, spans):
                srt += timed_chunks(sc["say"][lang], st, len(au[lang]) / SR, 42)
            write_srt(f"{base}_{lang}.srt", srt)
            write_notes(f"{base}_{lang}_yukleme.txt", data.get("meta", {}), lang, total)
        print(f"✔ {base}.mp4 + {len(langs)} ses kanalı ({total:.1f} sn)")


if __name__ == "__main__":
    main()
