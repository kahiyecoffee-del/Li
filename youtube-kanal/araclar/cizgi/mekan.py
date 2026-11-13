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
# ---------------------------------------------------------------- detay katmanları
def plant(ctx, x, y, s=1.0):
    box(ctx, x - 40 * s, y - 70 * s, 80 * s, 70 * s, "#b5643c", r=8)
    for i, a in enumerate((-0.9, -0.45, 0.0, 0.45, 0.9)):
        ctx.save()
        ctx.translate(x, y - 70 * s)
        ctx.rotate(a)
        ellipse(ctx, 0, -70 * s, 22 * s, 70 * s)
        fill_stroke(ctx, rgb("#4f9a4a" if i % 2 else "#3f8040"), 4)
        ctx.move_to(0, -10 * s)
        ctx.line_to(0, -120 * s)
        ctx.set_source_rgba(0, 0, 0, 0.25)
        ctx.set_line_width(3)
        ctx.stroke()
        ctx.restore()


def clock(ctx, x, y, r=48):
    ellipse(ctx, x, y, r, r)
    fill_stroke(ctx, rgb("#fbf7ec"))
    for k in range(12):
        a = k * math.pi / 6
        ctx.move_to(x + math.cos(a) * r * 0.78, y + math.sin(a) * r * 0.78)
        ctx.line_to(x + math.cos(a) * r * 0.9, y + math.sin(a) * r * 0.9)
    ctx.move_to(x, y)
    ctx.line_to(x + r * 0.5, y - r * 0.2)
    ctx.move_to(x, y)
    ctx.line_to(x - r * 0.1, y - r * 0.7)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(4)
    ctx.stroke()


def bookshelf(ctx, x, y, w, h):
    box(ctx, x, y, w, h, "#7a4f2c")
    rnd = random.Random(int(x))
    rows = 4
    for r in range(rows):
        yy = y + 14 + r * (h - 20) / rows
        box(ctx, x + 10, yy + (h - 20) / rows - 12, w - 20, 10, "#5e3b1f", 3)
        bx = x + 14
        while bx < x + w - 30:
            bw_ = rnd.randint(14, 28)
            bh_ = rnd.randint(int((h - 20) / rows * 0.55), int((h - 20) / rows * 0.8))
            col = rnd.choice(("#c0392b", "#2e86c1", "#27ae60", "#f1c40f", "#8e44ad", "#e67e22", "#ecf0f1"))
            box(ctx, bx, yy + (h - 20) / rows - 12 - bh_, bw_, bh_, col, 3)
            bx += bw_ + 2


def tv(ctx, x, y, w=300, h=180, on=True):
    box(ctx, x - 20, y + h + 10, w + 40, 120, "#6b4a2f")
    box(ctx, x, y, w, h, "#1b1b22", r=10)
    if on:
        g = cairo.LinearGradient(x, y, x + w, y + h)
        g.add_color_stop_rgb(0, 0.35, 0.6, 0.95)
        g.add_color_stop_rgb(1, 0.65, 0.35, 0.85)
        rrect(ctx, x + 12, y + 12, w - 24, h - 24, 6)
        ctx.set_source(g)
        ctx.fill()


def finish(ctx, floor_y=820, light_x=300):
    """Ortam ışığı: pencere ışığı, köşe kararması, zemin temas gölgesi, kâğıt dokusu."""
    g = cairo.RadialGradient(light_x, 200, 50, light_x, 300, 1500)
    g.add_color_stop_rgba(0, 1, 0.97, 0.85, 0.16)
    g.add_color_stop_rgba(0.5, 1, 0.97, 0.85, 0.0)
    g.add_color_stop_rgba(1, 0.1, 0.05, 0.15, 0.22)
    ctx.set_source(g)
    ctx.paint()
    sh = cairo.LinearGradient(0, floor_y - 30, 0, floor_y + 40)
    sh.add_color_stop_rgba(0, 0, 0, 0, 0.0)
    sh.add_color_stop_rgba(0.45, 0, 0, 0, 0.18)
    sh.add_color_stop_rgba(1, 0, 0, 0, 0.0)
    ctx.set_source(sh)
    ctx.rectangle(0, floor_y - 30, W, 70)
    ctx.fill()
    rnd = random.Random(11)
    for _ in range(5000):
        ctx.rectangle(rnd.uniform(0, W), rnd.uniform(0, H), 1.6, 1.6)
        v = rnd.random()
        ctx.set_source_rgba(v, v, v, 0.05)
        ctx.fill()


def living_d(ctx):
    living(ctx)
    bookshelf(ctx, 1560, 380, 260, 440)
    plant(ctx, 760, 820, 1.1)
    clock(ctx, 1240, 200)
    tv(ctx, 40, 560, 240, 140)
    ctx.move_to(1180, 560)  # kanepe dikiş/gölge
    ctx.line_to(1180, 640)
    ctx.set_source_rgba(0, 0, 0, 0.3)
    ctx.set_line_width(4)
    ctx.stroke()
    for (x, col) in ((960, "#e8c547"), (1300, "#6fb3d9")):  # yastıklar
        ctx.save()
        ctx.translate(x, 640)
        ctx.rotate(-0.15 if x < 1100 else 0.15)
        rrect(ctx, -70, -60, 140, 110, 30)
        fill_stroke(ctx, rgb(col))
        ctx.restore()
    for k in range(6):  # halı deseni
        ellipse(ctx, 960, 930, 560 - k * 90, 52 - k * 8)
        ctx.set_source_rgba(1, 1, 1, 0.08 if k % 2 else 0.0)
        ctx.set_line_width(6)
        ctx.stroke()
    finish(ctx, light_x=300)


def kitchen_d(ctx):
    kitchen(ctx)
    for x in range(100, 1700, 48):  # fayans
        for y in range(470, 700, 48):
            ctx.rectangle(x, y, 46, 46)
    ctx.set_source_rgba(1, 1, 1, 0.18)
    ctx.fill()
    clock(ctx, 1210, 430, 40)
    plant(ctx, 560, 700, 0.6)
    for i, x in enumerate((1340, 1420, 1500)):  # asılı tencereler
        ctx.move_to(x, 380)
        ctx.line_to(x, 420)
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(3)
        ctx.stroke()
        ellipse(ctx, x, 450, 34, 30)
        fill_stroke(ctx, rgb(("#b87333", "#9aa3ab", "#c0392b")[i]), 4)
    box(ctx, 1730, 330, 60, 60, "#f7d774", 3)  # buzdolabı notları
    box(ctx, 1800, 360, 60, 50, "#8fd3f4", 3)
    box(ctx, 1745, 540, 70, 60, "#f4a6c4", 3)
    finish(ctx, light_x=960)


def kyle_d(ctx):
    kyle_room(ctx)
    ctx.set_source_rgba(0.75, 0.3, 0.95, 0.10)  # led ışığı
    ctx.rectangle(0, 50, W, 300)
    ctx.fill()
    box(ctx, 900, 560, 240, 260, "#2a2f45", r=16)  # yatak kenarı
    box(ctx, 900, 540, 240, 60, "#4b6cb7", r=16)
    for i in range(5):  # enerji içeceği kutuları
        box(ctx, 1210 + i * 36, 618, 24, 42, ("#36d16b", "#f1c40f")[i % 2], 3)
    finish(ctx, light_x=1560)


def street(ctx):
    sky = cairo.LinearGradient(0, 0, 0, 600)
    sky.add_color_stop_rgb(0, *rgb("#89c9f0"))
    sky.add_color_stop_rgb(1, *rgb("#e3f2f8"))
    ctx.set_source(sky)
    ctx.paint()
    cols = ("#e8c27a", "#9ec1d9", "#c7a2c9", "#a8d5a2", "#f0b48a")
    for i, x0 in enumerate(range(-80, W, 420)):
        box(ctx, x0, 380, 360, 330, cols[i % 5])
        ctx.move_to(x0 - 30, 390)
        ctx.line_to(x0 + 180, 250)
        ctx.line_to(x0 + 390, 390)
        ctx.close_path()
        fill_stroke(ctx, rgb(("#8e3b2f", "#3b4f6e", "#5e3b6e", "#3f6b3a", "#7a4a2a")[i % 5]))
        box(ctx, x0 + 140, 560, 80, 150, "#6b4a2f")
        box(ctx, x0 + 40, 460, 80, 70, "#cfeaf7", 4)
        box(ctx, x0 + 240, 460, 80, 70, "#cfeaf7", 4)
    box(ctx, -10, 700, W + 20, 60, "#7cc65e", 0)  # çim şeridi
    box(ctx, -10, 760, W + 20, 60, "#cfcac0")  # kaldırım
    box(ctx, -10, 820, W + 20, 280, "#55585e")  # yol
    for x in range(0, W, 220):
        box(ctx, x, 955, 120, 14, "#f2d24b", 0)
    for x in (300, 1300):  # sokak lambası
        box(ctx, x, 380, 16, 380, "#3b3b3b", 4)
        box(ctx, x - 40, 370, 96, 26, "#3b3b3b", 4, r=10)
    # park etmiş araba
    box(ctx, 1500, 860, 330, 90, "#c0392b", r=30)
    box(ctx, 1570, 800, 190, 80, "#c0392b", r=24)
    box(ctx, 1590, 815, 70, 50, "#bfe3f5", 4, r=8)
    box(ctx, 1675, 815, 70, 50, "#bfe3f5", 4, r=8)
    for wx in (1570, 1760):
        ellipse(ctx, wx, 950, 40, 40)
        fill_stroke(ctx, rgb("#222222"))
    finish(ctx, floor_y=760, light_x=1600)


def diner(ctx):
    wall_floor(ctx, "#e8f1f2", "#d63c3c", "#d9d2c0")
    for x in range(0, W, 60):  # dama zemin
        for y in range(820, H, 60):
            if (x // 60 + y // 60) % 2:
                ctx.rectangle(x, y, 60, 60)
    ctx.set_source_rgb(0.15, 0.15, 0.18)
    ctx.fill()
    box(ctx, -10, 560, W + 20, 40, "#d63c3c", 0)  # kırmızı şerit
    for x in (120, 620, 1120, 1620):
        window(ctx, x, 150, 260, 220)
    box(ctx, 0, 640, W, 40, "#b8bcc2")  # bar tezgâhı
    box(ctx, 0, 680, W, 140, "#d63c3c")
    for x in range(120, W, 260):  # taburelar
        box(ctx, x, 820, 18, 110, "#9aa3ab", 4)
        ellipse(ctx, x + 9, 820, 56, 18)
        fill_stroke(ctx, rgb("#d63c3c"))
    box(ctx, 800, 40, 320, 80, "#2b2b2b", r=12)  # neon tabela
    ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(52)
    ctx.move_to(838, 98)
    ctx.set_source_rgb(1, 0.4, 0.55)
    ctx.show_text("EAT 24/7")
    for x in (300, 900, 1500):  # kek/kahve
        ellipse(ctx, x, 630, 50, 14)
        fill_stroke(ctx, rgb("#f4f1e8"), 4)
        box(ctx, x - 20, 590, 40, 40, "#f4f1e8", 4, r=6)
    finish(ctx, light_x=960)


def police(ctx):
    wall_floor(ctx, "#b9c4cf", "#5a6a7c", "#8a8d90")
    box(ctx, 120, 160, 520, 330, "#f2efe6")  # ilan panosu
    rnd = random.Random(4)
    for i in range(9):
        box(ctx, 140 + (i % 3) * 165, 180 + (i // 3) * 100, 140, 86, ("#fbf7ec", "#f7d774", "#f4a6c4")[i % 3], 3)
        ellipse(ctx, 210 + (i % 3) * 165, 184 + (i // 3) * 100, 7, 7)
        fill_stroke(ctx, rgb("#c0392b"), 2)
    box(ctx, 1500, 150, 240, 340, "#5a6a7c")  # dosya dolabı
    for k in range(4):
        box(ctx, 1520, 170 + k * 80, 200, 66, "#8798aa", 4)
        box(ctx, 1600, 196 + k * 80, 40, 12, "#2b2b2b", 3)
    box(ctx, 700, 600, 700, 50, "#6b4a2f")  # masa
    box(ctx, 720, 650, 660, 170, "#5a3d27")
    box(ctx, 880, 520, 170, 80, "#e8e2d0", 4)  # evrak yığını
    box(ctx, 900, 500, 150, 24, "#f5f0e0", 4)
    ellipse(ctx, 1250, 585, 60, 16)  # çörek kutusu
    fill_stroke(ctx, rgb("#f2b6c6"))
    for k in range(3):
        ellipse(ctx, 1215 + k * 35, 570, 18, 10)
        fill_stroke(ctx, rgb("#c47a3a"), 3)
    clock(ctx, 1100, 220)
    box(ctx, 1840, 300, 60, 520, "#3d4a5a")  # nezarethane parmaklık
    for x in range(1760, 1920, 34):
        box(ctx, x, 120, 12, 700, "#2b2b2b", 3)
    finish(ctx, light_x=600)


def garage(ctx):
    wall_floor(ctx, "#a7a39a", "#6e6a62", "#7c7f84")
    box(ctx, 100, 140, 600, 380, "#7a5a3a")  # alet panosu
    for i in range(12):
        x = 140 + (i % 6) * 92
        y = 190 + (i // 6) * 160
        ctx.move_to(x, y)
        ctx.line_to(x + 20 * ((i % 3) - 1), y + 110)
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(14)
        ctx.stroke()
        ctx.move_to(x, y)
        ctx.line_to(x + 20 * ((i % 3) - 1), y + 110)
        ctx.set_source_rgb(*rgb(("#c0392b", "#9aa3ab", "#e67e22")[i % 3]))
        ctx.set_line_width(8)
        ctx.stroke()
    box(ctx, 1000, 120, 820, 640, "#cfcac0")  # garaj kapısı
    for y in range(160, 760, 70):
        ctx.move_to(1000, y)
        ctx.line_to(1820, y)
    ctx.set_source_rgba(0, 0, 0, 0.3)
    ctx.set_line_width(4)
    ctx.stroke()
    for i in range(5):  # karton kutular
        box(ctx, 760 + (i % 3) * 70, 700 - (i // 3) * 70, 66, 66, "#c9a06a", 4)
    ellipse(ctx, 600, 960, 180, 24)  # yağ lekesi
    ctx.set_source_rgba(0, 0, 0, 0.25)
    ctx.fill()
    finish(ctx, light_x=1400)


def office(ctx):
    wall_floor(ctx, "#dfe6ee", "#9aa7b4", "#6f7f8f")
    window(ctx, 1200, 120, 620, 380)
    for x in range(1210, 1820, 60):  # şehir silueti
        h = 80 + (x * 37) % 160
        ctx.rectangle(x, 500 - h - 10, 50, h)
    ctx.set_source_rgba(0.3, 0.4, 0.55, 0.35)
    ctx.fill()
    box(ctx, 120, 200, 420, 260, "#ffffff")  # beyaz tahta
    ctx.move_to(150, 420)
    for k in range(6):
        ctx.line_to(170 + k * 60, 420 - k * 30 - (k % 2) * 30)
    ctx.set_source_rgb(0.2, 0.6, 0.3)
    ctx.set_line_width(6)
    ctx.stroke()
    ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(34)
    ctx.move_to(150, 250)
    ctx.set_source_rgb(0.15, 0.3, 0.7)
    ctx.show_text("SYNERGY!!!")
    box(ctx, 600, 620, 720, 40, "#e8e2d8")  # toplantı masası
    box(ctx, 640, 660, 20, 160, "#9aa3ab", 4)
    box(ctx, 1260, 660, 20, 160, "#9aa3ab", 4)
    box(ctx, 860, 520, 200, 110, "#1b1b22", r=8)  # laptop
    box(ctx, 872, 532, 176, 86, "#5aa0e6", 3, r=4)
    plant(ctx, 1700, 820, 1.2)
    finish(ctx, light_x=1500)


def chapel_d(ctx):
    chapel(ctx)
    for x in range(200, 1800, 300):  # sıralar
        box(ctx, x, 760, 220, 60, "#8a5a2b")
    finish(ctx, light_x=960)


def snow_d(ctx):
    snow(ctx)
    finish(ctx, floor_y=780, light_x=960)


def lawn_d(ctx):
    lawn(ctx)
    for x in (720, 1180):  # posta kutusu / çalı
        ellipse(ctx, x, 770, 90, 50)
        fill_stroke(ctx, rgb("#3f8040"))
    finish(ctx, floor_y=780, light_x=1600)


BGS.update({"living": living_d, "kitchen": kitchen_d, "kyle_room": kyle_d, "lawn": lawn_d, "chapel": chapel_d,
            "snow": snow_d, "street": street, "diner": diner, "police": police, "garage": garage, "office": office})

def school(ctx):
    wall_floor(ctx, "#f1e3b6", "#7a8b99", "#b9b2a4")
    for x in range(0, W, 120):  # dolaplar
        box(ctx, x + 4, 330, 112, 470, ("#3f6fb5", "#3a66a8")[(x // 120) % 2])
        for k in range(4):
            ctx.rectangle(x + 30, 350 + k * 12, 60, 5)
        ctx.set_source_rgba(0, 0, 0, 0.35)
        ctx.fill()
        box(ctx, x + 88, 560, 10, 40, "#c9ced4", 3)
    box(ctx, 600, 120, 720, 130, "#2d6a4f", r=10)  # pano
    ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(56)
    ctx.move_to(650, 205)
    ctx.set_source_rgb(1, 1, 1)
    ctx.show_text("GO FIGHTING BEAVERS!")
    clock(ctx, 300, 190, 46)
    for x in (1500, 1640):  # duvara asılı afiş
        box(ctx, x, 140, 110, 150, "#f4a6c4", 4)
    finish(ctx, light_x=960)


def townhall(ctx):
    wall_floor(ctx, "#cdbfa6", "#7a5a3a", "#6b4a2f")
    for x in (180, 560, 1240, 1620):  # sütunlar
        box(ctx, x, 120, 110, 700, "#e9e1d0")
        for k in range(4):
            ctx.move_to(x + 22 + k * 22, 140)
            ctx.line_to(x + 22 + k * 22, 800)
        ctx.set_source_rgba(0, 0, 0, 0.15)
        ctx.set_line_width(4)
        ctx.stroke()
    box(ctx, 720, 110, 480, 110, "#2c3e66", r=8)  # pankart
    ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(46)
    ctx.move_to(752, 182)
    ctx.set_source_rgb(1, 0.92, 0.6)
    ctx.show_text("LOWER FAIRVIEW")
    box(ctx, 800, 560, 320, 260, "#7a4f2c")  # kürsü
    box(ctx, 780, 540, 360, 40, "#5e3b1f")
    ellipse(ctx, 960, 515, 14, 30)
    fill_stroke(ctx, rgb("#2b2b2b"), 4)
    finish(ctx, light_x=960)


BGS.update({"school": school, "townhall": townhall})

def basement(ctx):
    wall_floor(ctx, "#8d8a7e", "#5a564c", "#5b5048")
    for y in range(0, 800, 60):  # beton blok duvar
        for x in range(-(y // 60 % 2) * 60, W, 120):
            ctx.rectangle(x, y, 118, 58)
    ctx.set_source_rgba(0, 0, 0, 0.10)
    ctx.set_line_width(3)
    ctx.stroke()
    box(ctx, 1400, 90, 260, 90, "#1c2430")  # küçük üst pencere
    box(ctx, 1412, 102, 236, 66, "#33415a", 4)
    box(ctx, 240, 560, 760, 160, "#5f6b3a", r=26)  # eski yeşil kanepe
    box(ctx, 200, 640, 90, 190, "#525c32", r=24)
    box(ctx, 950, 640, 90, 190, "#525c32", r=24)
    box(ctx, 260, 700, 720, 120, "#6b7842", r=18)
    ctx.move_to(420, 720)  # kanepe yırtığı
    ctx.line_to(470, 760)
    ctx.line_to(440, 790)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(4)
    ctx.stroke()
    box(ctx, 450, 830, 360, 30, "#7a5a3a")  # sehpa
    for i in range(4):
        box(ctx, 480 + i * 70, 800, 34, 34, ("#c0392b", "#f1c40f", "#2e86c1", "#c0392b")[i], 3, r=4)
    box(ctx, 1150, 600, 140, 200, "#d9d9d9", r=10)  # mini buzdolabı
    box(ctx, 1500, 380, 34, 160, "#6b3fa0", r=16)  # lav lambası
    ellipse(ctx, 1517, 430, 12, 18)
    fill_stroke(ctx, rgb("#ff7a59"), 3)
    box(ctx, 1480, 540, 74, 30, "#2b2b2b")
    box(ctx, 1600, 260, 200, 260, "#2e2e3a", 4)  # poster
    ellipse(ctx, 1700, 380, 60, 60)
    fill_stroke(ctx, rgb("#7fd17f"), 4)
    for i, x in enumerate(range(80, 1900, 260)):  # tavan boruları
        ctx.move_to(0, 40 + (i % 2) * 6)
    box(ctx, -10, 30, W + 20, 26, "#7f8c8d", 4)
    box(ctx, 1240, 0, 4, 140, "#333333", 0)  # çıplak ampul
    ellipse(ctx, 1242, 160, 22, 26)
    fill_stroke(ctx, rgb("#fff3b0"), 4)
    finish(ctx, light_x=1242)
    g = cairo.RadialGradient(1242, 160, 20, 1242, 160, 900)
    g.add_color_stop_rgba(0, 1, 0.95, 0.7, 0.18)
    g.add_color_stop_rgba(1, 0, 0, 0.05, 0.25)
    ctx.set_source(g)
    ctx.paint()


def group(ctx):
    wall_floor(ctx, "#d9d4c4", "#8a8370", "#9c8f7a")
    box(ctx, 160, 160, 340, 220, "#f7f3e8")  # motivasyon posteri
    ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(36)
    for i, t in enumerate(("ONE DAY", "AT A TIME", "(PLEASE)")):
        ctx.move_to(200, 230 + i * 50)
        ctx.set_source_rgb(0.2, 0.35, 0.6)
        ctx.show_text(t)
    box(ctx, 1400, 520, 300, 30, "#8a6d4b")  # kahve masası
    box(ctx, 1420, 550, 20, 270, "#6b5038", 4)
    box(ctx, 1660, 550, 20, 270, "#6b5038", 4)
    box(ctx, 1460, 410, 90, 110, "#b8bcc2", r=14)  # kahve semaveri
    for i in range(5):
        box(ctx, 1580 + (i % 3) * 30, 480 - (i // 3) * 22, 24, 30, "#f4f1e8", 3)
    box(ctx, 1600, 150, 180, 150, "#2d6a4f", r=6)  # pano
    for x in (120, 420, 720, 1020):  # katlanır sandalyeler (arka)
        box(ctx, x, 640, 120, 18, "#7f8c8d", 4)
        box(ctx, x + 10, 560, 100, 80, "#95a5a6", 4, r=8)
        box(ctx, x + 14, 658, 10, 160, "#5d6d7e", 3)
        box(ctx, x + 96, 658, 10, 160, "#5d6d7e", 3)
    clock(ctx, 960, 180, 50)
    finish(ctx, light_x=960)
    ctx.set_source_rgba(0.85, 1.0, 0.85, 0.06)  # floresan yeşilimsi
    ctx.paint()


def gas_station(ctx):
    sky = cairo.LinearGradient(0, 0, 0, 700)
    sky.add_color_stop_rgb(0, *rgb("#0b1026"))
    sky.add_color_stop_rgb(1, *rgb("#2a2350"))
    ctx.set_source(sky)
    ctx.paint()
    rnd = random.Random(5)
    for _ in range(80):
        ellipse(ctx, rnd.uniform(0, W), rnd.uniform(0, 380), 1.8, 1.8)
        ctx.set_source_rgba(1, 1, 1, rnd.uniform(0.3, 0.9))
        ctx.fill()
    box(ctx, 900, 330, 900, 450, "#d9d4c4")  # market
    box(ctx, 960, 420, 520, 260, "#ffe9a8", 5)  # vitrin ışığı
    for x in range(990, 1460, 90):
        box(ctx, x, 470, 60, 160, "#c9b37a", 3)
    box(ctx, 1540, 470, 160, 310, "#3a5a7a", 5)  # kapı
    box(ctx, 900, 300, 900, 50, "#c0392b")
    ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(40)
    ctx.move_to(1180, 338)
    ctx.set_source_rgb(1, 1, 1)
    ctx.show_text("QUIK-STOP 24")
    box(ctx, 60, 200, 760, 60, "#f2f2f2")  # pompa saçağı
    box(ctx, 120, 260, 40, 520, "#bdbdbd", 4)
    box(ctx, 720, 260, 40, 520, "#bdbdbd", 4)
    for x in (260, 520):  # pompalar
        box(ctx, x, 560, 110, 220, "#c0392b", r=10)
        box(ctx, x + 18, 590, 74, 50, "#1b1b1b", 3)
    g = cairo.LinearGradient(0, 260, 0, 900)  # saçak ışığı
    g.add_color_stop_rgba(0, 1, 1, 0.9, 0.35)
    g.add_color_stop_rgba(1, 1, 1, 0.9, 0.0)
    ctx.move_to(60, 260)
    ctx.line_to(820, 260)
    ctx.line_to(980, 900)
    ctx.line_to(-100, 900)
    ctx.close_path()
    ctx.set_source(g)
    ctx.fill()
    box(ctx, -10, 780, W + 20, 320, "#3b3b44")  # asfalt
    for x in range(40, W, 300):
        box(ctx, x, 880, 140, 10, "#e8e2d0", 0)
    finish(ctx, floor_y=780, light_x=1200)


BGS.update({"basement": basement, "group": group, "gas_station": gas_station})

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
