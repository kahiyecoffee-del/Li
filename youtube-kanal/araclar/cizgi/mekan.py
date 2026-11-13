"""THE BUDGETS mekânları ve dekor objeleri (cairo, düz renk + kalın kontur).

Her mekân 2x çözünürlükte (3840x2160) bir kez çizilir, kamera yakınlaşınca da net kalır.
Zemin çizgisi tüm mekânlarda GROUND = 960 (1920x1080 dünya koordinatı).
"""
import math
import random

import cairo

from karakter import INK, darker, ellipse, fill_stroke, rgb, rrect

W, H = 1920, 1080
GROUND = 960
COUNTER_Y = {"kitchen": 700}


def box(ctx, x, y, w, h, col, lw=6, r=0):
    if r:
        rrect(ctx, x, y, w, h, r)
    else:
        ctx.rectangle(x, y, w, h)
    fill_stroke(ctx, rgb(col) if isinstance(col, str) else col, lw)


def wall_floor(ctx, wall, trim, floor, floor_y=820):
    box(ctx, -10, -10, W + 20, floor_y + 10, wall, 0)
    ctx.set_source_rgb(*rgb(wall))
    ctx.paint()
    box(ctx, -10, floor_y, W + 20, H - floor_y + 10, floor)
    box(ctx, -10, floor_y - 26, W + 20, 26, trim)


def window(ctx, x, y, w, h, sky="#9fd3f0", night=False):
    box(ctx, x - 14, y - 14, w + 28, h + 28, "#f4efe2")
    box(ctx, x, y, w, h, "#25325a" if night else sky)
    if not night:
        ellipse(ctx, x + w * 0.3, y + h * 0.35, w * 0.16, h * 0.08)
        ctx.set_source_rgb(1, 1, 1)
        ctx.fill()
        ellipse(ctx, x + w * 0.42, y + h * 0.33, w * 0.12, h * 0.07)
        ctx.fill()
    ctx.move_to(x + w / 2, y)
    ctx.line_to(x + w / 2, y + h)
    ctx.move_to(x, y + h / 2)
    ctx.line_to(x + w, y + h / 2)
    ctx.set_source_rgb(*rgb("#f4efe2"))
    ctx.set_line_width(14)
    ctx.stroke()


def frame_pic(ctx, x, y, w, h, inner):
    box(ctx, x, y, w, h, "#8a5a2b")
    box(ctx, x + 12, y + 12, w - 24, h - 24, inner, 4)


def living(ctx):
    wall_floor(ctx, "#e8d9a8", "#b98a55", "#8a6a4a")
    for i in range(0, W, 120):  # duvar kağıdı çizgileri
        ctx.rectangle(i, 0, 40, 794)
        ctx.set_source_rgba(1, 1, 1, 0.12)
        ctx.fill()
    window(ctx, 140, 170, 330, 300)
    frame_pic(ctx, 1500, 160, 230, 170, "#6fa36b")
    frame_pic(ctx, 560, 210, 150, 190, "#d98a5c")
    # kanepe
    box(ctx, 860, 560, 640, 170, "#b0413e", r=30)
    box(ctx, 820, 640, 90, 200, "#9a3633", r=26)
    box(ctx, 1450, 640, 90, 200, "#9a3633", r=26)
    box(ctx, 880, 700, 600, 120, "#c24b47", r=20)
    ctx.move_to(1180, 705)
    ctx.line_to(1180, 815)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(5)
    ctx.stroke()
    # lamba
    box(ctx, 1640, 520, 18, 300, "#3a3a3a")
    ctx.move_to(1580, 520)
    ctx.line_to(1720, 520)
    ctx.line_to(1690, 410)
    ctx.line_to(1610, 410)
    ctx.close_path()
    fill_stroke(ctx, rgb("#f3e3a1"))
    # halı
    ellipse(ctx, 960, 930, 620, 60)
    fill_stroke(ctx, rgb("#5f7f9a"))


def kitchen(ctx):
    wall_floor(ctx, "#cfe3d4", "#7aa08a", "#c9b38f")
    for x in range(0, W, 80):  # karo zemin
        ctx.move_to(x, 820)
        ctx.line_to(x - 200, H)
    ctx.set_source_rgba(0, 0, 0, 0.15)
    ctx.set_line_width(3)
    ctx.stroke()
    window(ctx, 760, 150, 400, 260)
    # üst dolaplar
    for x in (120, 380, 1260, 1520):
        box(ctx, x, 120, 250, 230, "#f2efe6")
        ellipse(ctx, x + 125, 320, 10, 10)
        fill_stroke(ctx, rgb("#b9a27a"), 3)
    # tezgâh
    box(ctx, 80, COUNTER_Y["kitchen"], 1760, 40, "#8d7b68")
    box(ctx, 100, COUNTER_Y["kitchen"] + 40, 1720, 160, "#f2efe6")
    for x in range(100, 1820, 215):
        box(ctx, x + 10, COUNTER_Y["kitchen"] + 56, 195, 128, "#e7e2d5", 4)
    # buzdolabı
    box(ctx, 1700, 260, 200, 560, "#e9eef2", r=18)
    ctx.move_to(1700, 470)
    ctx.line_to(1900, 470)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(5)
    ctx.stroke()
    box(ctx, 1720, 300, 14, 120, "#9aa3ab", 3)
    box(ctx, 1720, 500, 14, 160, "#9aa3ab", 3)
    # kahve makinesi + meyve kâsesi
    box(ctx, 300, 600, 110, 100, "#2c2c34", r=10)
    ellipse(ctx, 1450, 690, 90, 24)
    fill_stroke(ctx, rgb("#d7d0c0"))
    for i, col in enumerate(("#e0443a", "#f2b632", "#7cbf4a")):
        ellipse(ctx, 1410 + i * 40, 665, 26, 24)
        fill_stroke(ctx, rgb(col), 4)


def kyle_room(ctx):
    wall_floor(ctx, "#3d4a6b", "#2b344d", "#5a4b45")
    window(ctx, 1420, 160, 300, 260, night=True)
    for i, (x, y, col) in enumerate(((180, 160, "#e94f64"), (420, 240, "#f2c14e"), (260, 420, "#3fc1a5"))):
        box(ctx, x, y, 190, 250, col)  # posterler
        ctx.move_to(x + 30, y + 60)
        ctx.line_to(x + 160, y + 190)
        ctx.set_source_rgba(0, 0, 0, 0.3)
        ctx.set_line_width(14)
        ctx.stroke()
    # led şerit
    ctx.rectangle(0, 40, W, 10)
    ctx.set_source_rgb(0.75, 0.3, 0.95)
    ctx.fill()
    # masa + monitör + ring light
    box(ctx, 1180, 660, 600, 30, "#2a2a2a")
    box(ctx, 1220, 690, 30, 160, "#2a2a2a")
    box(ctx, 1710, 690, 30, 160, "#2a2a2a")
    box(ctx, 1300, 470, 360, 190, "#16161c", r=10)
    box(ctx, 1316, 486, 328, 158, "#2e7bd6", r=4)
    ctx.set_line_width(26)
    ctx.arc(640, 420, 130, 0, 2 * math.pi)
    ctx.set_source_rgb(*INK)
    ctx.stroke()
    ctx.set_line_width(16)
    ctx.arc(640, 420, 130, 0, 2 * math.pi)
    ctx.set_source_rgb(1, 0.97, 0.88)
    ctx.stroke()
    box(ctx, 632, 550, 16, 280, "#2a2a2a")
    # kirli çamaşır yığını
    for i, col in enumerate(("#6b8e23", "#444444", "#b03a2e", "#2f4f7f")):
        ellipse(ctx, 260 + i * 60, 880 - (i % 2) * 30, 90, 40)
        fill_stroke(ctx, rgb(col), 5)


def lawn(ctx):
    sky = cairo.LinearGradient(0, 0, 0, 600)
    sky.add_color_stop_rgb(0, *rgb("#7cc4ef"))
    sky.add_color_stop_rgb(1, *rgb("#cdeaf7"))
    ctx.set_source(sky)
    ctx.paint()
    for (cx, cy, r) in ((300, 150, 70), (380, 140, 90), (1400, 110, 60), (1480, 120, 80)):
        ellipse(ctx, cx, cy, r * 1.4, r * 0.6)
        ctx.set_source_rgb(1, 1, 1)
        ctx.fill()
    # Budget evi (sol) + Gary'nin evi (sağ)
    for x0, col, roof in ((60, "#e8c27a", "#8e3b2f"), (1240, "#9ec1d9", "#3b4f6e")):
        box(ctx, x0, 360, 620, 420, col)
        ctx.move_to(x0 - 40, 370)
        ctx.line_to(x0 + 310, 190)
        ctx.line_to(x0 + 660, 370)
        ctx.close_path()
        fill_stroke(ctx, rgb(roof))
        box(ctx, x0 + 250, 560, 120, 220, "#7a4a2a")
        for wx in (x0 + 70, x0 + 430):
            box(ctx, wx, 460, 120, 110, "#bfe3f5")
    # çim (logo biçilmiş)
    box(ctx, -10, 780, W + 20, 320, "#5aa845", 0)
    ctx.set_source_rgb(*rgb("#5aa845"))
    ctx.rectangle(0, 780, W, 300)
    ctx.fill()
    ctx.set_source_rgb(*rgb("#7cc65e"))
    ctx.set_line_width(26)
    ctx.arc(960, 900, 120, 0, 2 * math.pi)  # HOMI logosu çimde
    ctx.stroke()
    ctx.arc(960, 900, 40, 0, 2 * math.pi)
    ctx.fill()
    # ssöndürülmüş flamingo (sağda)
    ctx.move_to(1500, 800)
    ctx.curve_to(1560, 760, 1680, 770, 1740, 800)
    ctx.curve_to(1700, 830, 1560, 830, 1500, 800)
    fill_stroke(ctx, rgb("#f07aa8"))
    ellipse(ctx, 1760, 790, 30, 18)
    fill_stroke(ctx, rgb("#f07aa8"))
    # çit
    for x in range(0, W, 70):
        box(ctx, x, 720, 36, 70, "#f6f3ea", 4)


def chapel(ctx):
    wall_floor(ctx, "#d9c7a6", "#a58d68", "#7d6a52")
    for x in (360, 1460):
        ctx.move_to(x, 620)
        ctx.line_to(x, 260)
        ctx.arc(x + 100, 260, 100, math.pi, 0)
        ctx.line_to(x + 200, 620)
        ctx.close_path()
        fill_stroke(ctx, rgb("#e9d9a8"))
    box(ctx, 860, 150, 200, 34, "#b38b4d")  # haç yerine çiçek kemer
    for i in range(9):
        ellipse(ctx, 700 + i * 65, 300 - math.sin(i / 8 * math.pi) * 140, 34, 30)
        fill_stroke(ctx, rgb("#f0b7c9"), 4)
    for x in (120, 1650):
        box(ctx, x, 700, 150, 120, "#8a5a2b")


def snow(ctx):
    sky = cairo.LinearGradient(0, 0, 0, 800)
    sky.add_color_stop_rgb(0, *rgb("#8796a8"))
    sky.add_color_stop_rgb(1, *rgb("#c9d3dd"))
    ctx.set_source(sky)
    ctx.paint()
    for i, x in enumerate(range(-20, W, 260)):
        h = 300 + (i * 97) % 220
        box(ctx, x, 780 - h, 240, h, ("#8f6f5a", "#7d7f8a", "#a0806a")[i % 3])
        for wy in range(780 - h + 40, 740, 90):
            box(ctx, x + 40, wy, 60, 50, "#f2d27a", 4)
            box(ctx, x + 140, wy, 60, 50, "#f2d27a", 4)
    box(ctx, -10, 780, W + 20, 320, "#eef2f6")


BGS = {"living": living, "kitchen": kitchen, "kyle_room": kyle_room, "lawn": lawn, "chapel": chapel, "snow": snow}
_cache = {}


def background(name):
    if name not in _cache:
        s = cairo.ImageSurface(cairo.FORMAT_ARGB32, W * 2, H * 2)
        c = cairo.Context(s)
        c.scale(2, 2)
        c.set_line_join(cairo.LINE_JOIN_ROUND)
        BGS[name](c)
        _cache[name] = s
    return _cache[name]


# ---------- dekor objeleri (karakter gibi sahneye konur) ----------
class Prop:
    def __init__(self, name):
        self.name = name

    def draw(self, ctx, x, y, s, st):
        ctx.save()
        ctx.translate(x, y)
        ctx.scale(s, s)
        t = st.get("t", 0.0)
        if self.name == "jukebox":
            ctx.move_to(-130, 0)
            ctx.line_to(-130, -330)
            ctx.arc(0, -330, 130, math.pi, 0)
            ctx.line_to(130, 0)
            ctx.close_path()
            fill_stroke(ctx, rgb("#b5452f"))
            ctx.move_to(-95, -40)
            ctx.line_to(-95, -320)
            ctx.arc(0, -320, 95, math.pi, 0)
            ctx.line_to(95, -40)
            ctx.close_path()
            hue = 0.5 + 0.5 * math.sin(t * 6)
            fill_stroke(ctx, (1.0, 0.75 + 0.2 * hue, 0.35), 5)
            for k in range(4):
                box(ctx, -70, -250 + k * 50, 140, 26, "#f7efe0", 3)
            # duvak
            ctx.move_to(-110, -420)
            ctx.curve_to(-200, -300, -170, -120, -150, -40)
            ctx.line_to(150, -40)
            ctx.curve_to(170, -120, 200, -300, 110, -420)
            ctx.curve_to(60, -470, -60, -470, -110, -420)
            ctx.set_source_rgba(1, 1, 1, 0.45)
            ctx.fill_preserve()
            ctx.set_source_rgb(*INK)
            ctx.set_line_width(4)
            ctx.stroke()
        elif self.name.startswith("toaster"):
            ph = t * 7 + (1.3 if self.name.endswith("2") else 0)
            for sx in (-1, 1):
                sw = math.sin(ph + (0 if sx > 0 else math.pi)) * 16
                ctx.move_to(sx * 50, -110)
                ctx.line_to(sx * 50 + sw, -8)
                ctx.set_source_rgb(*INK)
                ctx.set_line_width(14)
                ctx.stroke()
            rrect(ctx, -130, -330, 260, 220, 40)
            fill_stroke(ctx, rgb("#c8ccd2"))
            for sx in (-1, 1):
                rrect(ctx, sx * 55 - 30, -350, 60, 30, 8)
                fill_stroke(ctx, rgb("#d9a066"), 5)
            for sx in (-1, 1):
                ctx.move_to(sx * 70, -255)
                ctx.line_to(sx * 30, -238)
                ctx.set_source_rgb(0.9, 0.1, 0.1)
                ctx.set_line_width(10)
                ctx.stroke()
            ellipse(ctx, 0, -175, 40, 12)
            fill_stroke(ctx, rgb("#333333"), 4)
        ctx.restore()


def snowfall(ctx, t, n=120):
    rnd = random.Random(7)
    ctx.set_source_rgba(1, 1, 1, 0.9)
    for _ in range(n):
        x0, sp, r = rnd.uniform(0, W), rnd.uniform(60, 140), rnd.uniform(3, 7)
        y = (rnd.uniform(0, H) + t * sp) % H
        x = x0 + math.sin(t * 1.3 + x0) * 20
        ellipse(ctx, x, y, r, r)
        ctx.fill()
