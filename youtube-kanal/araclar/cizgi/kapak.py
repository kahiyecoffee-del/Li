#!/usr/bin/env python3
"""THE BUDGETS kapak üretici (1280x720).

Kullanım: python3 araclar/cizgi/kapak.py b01 "MY AI FIRED ME" [--char dale] [--emo shock] [--bg kitchen] [--pose up] [--side homi]
"""
import argparse
import os
import sys

import cairo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from karakter import INK, POSES, make, rgb  # noqa: E402
from mekan import COUNTER_Y, GROUND, background  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("slug")
ap.add_argument("text")
ap.add_argument("--char", default="dale")
ap.add_argument("--emo", default="shock")
ap.add_argument("--pose", default="up")
ap.add_argument("--bg", default="kitchen")
ap.add_argument("--side", default="")
ap.add_argument("--out")
a = ap.parse_args()

W, H = 1280, 720
s = cairo.ImageSurface(cairo.FORMAT_ARGB32, W, H)
c = cairo.Context(s)
c.save()
c.scale(W / 1920 * 1.25, H / 1080 * 1.25)
c.translate(-200, -200)
c.save()
c.scale(0.5, 0.5)
c.set_source_surface(background(a.bg), 0, 0)
c.paint()
c.restore()
if a.side == "homi":
    make("homi").draw(c, 1500, COUNTER_Y.get(a.bg, GROUND), 1.2, dict(mouth=0.5, emo="angry"))
c.restore()
c.set_source_rgba(0, 0, 0, 0.25)
c.paint()
# büyük karakter (sağ)
make(a.char).draw(c, 900, 1500, 2.1, dict(emo=a.emo, pose=POSES[a.pose], mouth=0.9 if a.emo != "neutral" else 0,
                                          look=(-0.6, 0), facing=-1))
# metin (sol)
c.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
words = a.text.upper().split()
lines, cur = [], ""
for w in words:
    if len(cur) + len(w) + 1 > 11 and cur:
        lines.append(cur)
        cur = w
    else:
        cur = (cur + " " + w).strip()
lines.append(cur)
fs = 104 if len(lines) <= 3 else 84
c.set_font_size(fs)
for i, ln in enumerate(lines):
    c.move_to(46, 140 + i * (fs + 12))
    c.text_path(ln)
    c.set_source_rgb(*INK)
    c.set_line_width(16)
    c.set_line_join(cairo.LINE_JOIN_ROUND)
    c.stroke_preserve()
    c.set_source_rgb(*rgb("#ffe14d") if i % 2 else (1, 1, 1))
    c.fill()
# logo şeridi
c.save()
c.translate(40, 640)
c.rotate(-0.04)
c.rectangle(-10, -66, 470, 84)
c.set_source_rgb(*rgb("#d9342b"))
c.fill_preserve()
c.set_source_rgb(*INK)
c.set_line_width(6)
c.stroke()
c.set_font_size(58)
c.move_to(12, 0)
c.text_path("THE BUDGETS")
c.set_source_rgb(*rgb("#fff3c4"))
c.fill()
c.restore()
out = a.out or f"cikti/budgets/{a.slug}/kapak.png"
os.makedirs(os.path.dirname(out), exist_ok=True)
s.write_to_png(out)
print("✔", out)
