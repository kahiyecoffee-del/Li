"""Anlatıcı karakter: "Mo".

Yuvarlak (fasulye) gövde, büyük ifadeli gözler, makarna kollar, eldivenli eller.
İmza: turuncu atkı + fikir anında yanan anten.
Gözler yeni beliren nesneye bakar (izleyicinin dikkatini yönlendirir), göz kırpar,
ağız seslendirmeye göre açılıp kapanır.
"""
import math

from PIL import ImageDraw

INK = (30, 28, 40)
BODY = (160, 145, 245)       # lavanta
BODY_DARK = (125, 110, 215)  # gölge tarafı
BELLY = (195, 185, 252)
SCARF = (255, 125, 60)
SCARF_DARK = (220, 95, 40)
SHOE = (255, 107, 91)
GLOVE = (255, 255, 255)
CHEEK = (255, 150, 185)
MOUTH = (90, 30, 50)
TONGUE = (255, 120, 140)
GLOW = (255, 201, 60)


def _r(a):
    return math.radians(a)


def _limb(start, a1, a2, l1, l2):
    e = (start[0] + math.sin(_r(a1)) * l1, start[1] + math.cos(_r(a1)) * l1)
    h = (e[0] + math.sin(_r(a2)) * l2, e[1] + math.cos(_r(a2)) * l2)
    return e, h


def _noodle(d, pts, color, w, outline=INK, ow=None):
    """Kenar çizgili kalın çizgi (makarna kol/bacak)."""
    ow = ow or max(3, int(w * 0.32))
    d.line(pts, fill=outline, width=int(w + ow * 2), joint="curve")
    for p in (pts[0], pts[-1]):
        r = w / 2 + ow
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=outline)
    d.line(pts, fill=color, width=int(w), joint="curve")
    for p in (pts[0], pts[-1]):
        r = w / 2
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color)


def _bezier(p0, p1, p2, n=12):
    return [((1 - u) ** 2 * p0[0] + 2 * (1 - u) * u * p1[0] + u * u * p2[0],
             (1 - u) ** 2 * p0[1] + 2 * (1 - u) * u * p1[1] + u * u * p2[1]) for u in (i / n for i in range(n + 1))]


def draw_character(img, p, expr, cx, ground_y, sc, mouth, t, glow=False, look=(0.0, 0.0), blink=False, talking=False):
    d = ImageDraw.Draw(img)
    da = ImageDraw.Draw(img, "RGBA")
    lw = max(3, int(9 * sc))
    BW, BH, LEG = 300 * sc, 390 * sc, 95 * sc
    bob = p["bob"] * sc
    jump = max(0.0, -p["bob"]) / 30
    sy = 1 + 0.018 * math.sin(t * 2.4) + 0.06 * min(jump, 1)
    sx = 1 / sy
    w, h = BW * sx, BH * sy
    bottom = ground_y - LEG + bob
    cy = bottom - h / 2
    lean = math.tan(_r(p["lean"] + p["head"] * 0.4))

    # zemin gölgesi
    shw = w * 0.42 * (1 - 0.35 * min(jump, 1))
    da.ellipse([cx - shw, ground_y - 12 * sc, cx + shw, ground_y + 12 * sc], fill=(0, 0, 0, 45))

    # bacaklar (gövdenin arkasında)
    feet = []
    for side, a1, a2 in ((-1, p["ll1"], p["ll2"]), (1, p["rl1"], p["rl2"])):
        hip = (cx + side * w * 0.2, bottom - 15 * sc)
        knee, foot = _limb(hip, a1 * 0.9, a2 * 0.9, LEG * 0.55, LEG * 0.55)
        _noodle(d, [hip, knee, foot], BODY_DARK, 26 * sc)
        feet.append((side, foot))
    for side, foot in feet:
        fx, fy = foot[0] + side * 10 * sc, foot[1] + 4 * sc
        d.ellipse([fx - 34 * sc, fy - 20 * sc, fx + 34 * sc, fy + 16 * sc], fill=SHOE, outline=INK, width=lw)
        d.line([(fx - 22 * sc, fy + 6 * sc), (fx + 22 * sc, fy + 6 * sc)], fill=(255, 255, 255), width=max(2, int(5 * sc)))

    # gövde: yumurta biçimi süper elips
    pts = []
    for i in range(72):
        u = 2 * math.pi * i / 72
        x, y = math.cos(u), math.sin(u)
        x = math.copysign(abs(x) ** 0.82, x)
        y = math.copysign(abs(y) ** 0.9, y)
        Y = cy + y * h / 2
        f = 1 + 0.07 * y
        pts.append((cx + x * w / 2 * f + (cy - Y) * lean, Y))
    top = (cx + (h / 2) * lean, cy - h / 2)

    # anten (gövdenin arkasından çıkar)
    sway = 8 * sc * math.sin(t * 3)
    a0 = (top[0] + 10 * sc, top[1] + 20 * sc)
    a1 = (top[0] + 40 * sc + sway, top[1] - 55 * sc)
    a2 = (top[0] + 15 * sc + sway * 1.6, top[1] - 105 * sc)
    _noodle(d, _bezier(a0, a1, a2), BODY_DARK, 12 * sc)
    br = 22 * sc * (1.2 if glow else 1.0)
    if glow:
        for k in range(10):
            a = k * math.pi / 5 + t * 2
            d.line([(a2[0] + math.cos(a) * br * 1.5, a2[1] + math.sin(a) * br * 1.5),
                    (a2[0] + math.cos(a) * br * 2.2, a2[1] + math.sin(a) * br * 2.2)], fill=GLOW, width=max(2, int(6 * sc)))
        da.ellipse([a2[0] - br * 1.6, a2[1] - br * 1.6, a2[0] + br * 1.6, a2[1] + br * 1.6], fill=(255, 220, 90, 70))
    d.ellipse([a2[0] - br, a2[1] - br, a2[0] + br, a2[1] + br], fill=GLOW if glow else SHOE, outline=INK, width=lw)
    d.ellipse([a2[0] - br * 0.45, a2[1] - br * 0.55, a2[0] - br * 0.05, a2[1] - br * 0.15], fill=(255, 255, 255))

    d.polygon(pts, fill=BODY)
    # gölge tarafı ve karın
    shade = [(x + (x - cx) * 0.0, y) for x, y in pts if x > cx + w * 0.18]
    if len(shade) > 2:
        d.polygon(shade, fill=BODY_DARK)
    d.ellipse([cx - w * 0.28 + (cy + h * 0.25 - cy) * -lean, cy + h * 0.05, cx + w * 0.28 + (cy + h * 0.25 - cy) * -lean,
               cy + h * 0.46], fill=BELLY)
    d.line(pts + [pts[0]], fill=INK, width=lw, joint="curve")

    # yüz
    droop = p["droop"] * sc * 0.8
    fx = cx + (h * 0.18) * lean + p["head"] * 1.2 * sc
    fy = cy - h * 0.17 + droop
    lx, ly = look
    ex, er_x, er_y = 56 * sc, 36 * sc, 44 * sc
    if expr == "shock":
        er_x, er_y = er_x * 1.15, er_y * 1.2
    for side in (-1, 1):
        ecx, ecy = fx + side * ex, fy
        if blink:
            d.arc([ecx - er_x, ecy - er_y * 0.3, ecx + er_x, ecy + er_y * 0.5], 20, 160, fill=INK, width=lw)
            continue
        d.ellipse([ecx - er_x, ecy - er_y, ecx + er_x, ecy + er_y], fill=(255, 255, 255), outline=INK, width=lw)
        pr = 19 * sc if expr != "shock" else 13 * sc
        px, py = ecx + lx * er_x * 0.45, ecy + ly * er_y * 0.45 + 4 * sc
        d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=INK)
        d.ellipse([px - pr * 0.55, py - pr * 0.75, px - pr * 0.05, py - pr * 0.25], fill=(255, 255, 255))
        if expr == "tired":  # yarı kapalı göz kapağı
            d.chord([ecx - er_x, ecy - er_y, ecx + er_x, ecy + er_y], 180, 360, fill=BODY, outline=INK, width=lw)
        elif expr == "happy" and not talking:
            d.chord([ecx - er_x, ecy + er_y * 0.2, ecx + er_x, ecy + er_y * 1.6], 180, 360, fill=BODY)
    # kaşlar
    by = fy - er_y - 18 * sc
    brow = {
        "happy": (8, -6), "shock": (-4, -18), "sad": (-16, 0), "tired": (-6, 6), "think": (10, -14),
        "confused": (14, -16), "down": (0, 0), "neutral": (4, -2),
    }.get(expr, (4, -2))
    for side in (-1, 1):
        tilt, lift = brow
        if expr in ("think", "confused") and side == -1:
            tilt, lift = -4, 0
        inner = (fx + side * (ex - 26 * sc), by + lift * sc + (tilt * sc if expr == "sad" else -tilt * sc * 0.4))
        outer = (fx + side * (ex + 26 * sc), by + lift * sc + (-tilt * sc * 0.2 if expr == "sad" else tilt * sc * 0.4))
        _noodle(d, [inner, outer], INK, 9 * sc, ow=1)
    # yanaklar
    for side in (-1, 1):
        ccx, ccy = fx + side * 98 * sc, fy + 46 * sc
        da.ellipse([ccx - 24 * sc, ccy - 13 * sc, ccx + 24 * sc, ccy + 13 * sc], fill=(*CHEEK, 170))
    # ağız
    mx, my = fx, fy + 72 * sc
    if expr == "shock":
        d.ellipse([mx - 22 * sc, my - 26 * sc, mx + 22 * sc, my + 26 * sc], fill=MOUTH, outline=INK, width=lw)
    elif talking and mouth > 0.05:
        mw = (34 + 10 * mouth) * sc
        mh = (8 + 40 * mouth) * sc
        smile = 8 * sc if expr in ("happy", "neutral") else 0
        d.chord([mx - mw, my - mh / 2 - smile, mx + mw, my + mh / 2 + smile], 0, 180, fill=MOUTH, outline=INK, width=lw)
        d.line([(mx - mw, my - smile * 0.2), (mx + mw, my - smile * 0.2)], fill=INK, width=lw)
        if mh > 18 * sc:
            d.ellipse([mx - mw * 0.45, my + mh * 0.05, mx + mw * 0.45, my + mh / 2 + smile * 0.8], fill=TONGUE)
    elif expr == "happy":
        d.chord([mx - 40 * sc, my - 26 * sc, mx + 40 * sc, my + 30 * sc], 0, 180, fill=MOUTH, outline=INK, width=lw)
        d.line([(mx - 40 * sc, my + 2 * sc), (mx + 40 * sc, my + 2 * sc)], fill=INK, width=lw)
        d.ellipse([mx - 16 * sc, my + 10 * sc, mx + 16 * sc, my + 26 * sc], fill=TONGUE)
    elif expr in ("sad", "tired"):
        d.arc([mx - 30 * sc, my, mx + 30 * sc, my + 34 * sc], 200, 340, fill=INK, width=lw)
    elif expr == "confused":
        pts_m = [(mx - 30 * sc + k * 6 * sc, my + 6 * sc * math.sin(k * 1.3)) for k in range(11)]
        d.line(pts_m, fill=INK, width=lw, joint="curve")
    elif expr == "think":
        d.arc([mx - 10 * sc, my - 8 * sc, mx + 34 * sc, my + 14 * sc], 10, 170, fill=INK, width=lw)
    else:
        d.arc([mx - 30 * sc, my - 20 * sc, mx + 30 * sc, my + 16 * sc], 25, 155, fill=INK, width=lw)

    # atkı (gövdeye sarılı bant + dalgalanan uç)
    ys = cy + h * 0.2
    hw = w * 0.5 * 0.97
    band = [(cx + k / 10 * 2 * hw - hw + (cy - ys) * lean, ys + 14 * sc * (1 - ((k / 10 * 2) - 1) ** 2)) for k in range(11)]
    d.line(band, fill=INK, width=int(46 * sc), joint="curve")
    d.line(band, fill=SCARF, width=int(32 * sc), joint="curve")
    for k in (3, 6):
        x0 = band[k][0]
        d.line([(x0, band[k][1] - 12 * sc), (x0 + 6 * sc, band[k][1] + 12 * sc)], fill=SCARF_DARK, width=max(2, int(4 * sc)))
    tail0 = (band[7][0], band[7][1] + 10 * sc)
    tail = [(tail0[0] + u * 60 * sc + 10 * sc * math.sin(t * 7 - u * 4) * u, tail0[1] + u * 95 * sc)
            for u in (k / 6 for k in range(7))]
    d.line(tail, fill=INK, width=int(40 * sc), joint="curve")
    d.line(tail, fill=SCARF, width=int(27 * sc), joint="curve")
    d.line([(tail[-1][0] - 14 * sc, tail[-1][1] + 6 * sc), (tail[-1][0] + 14 * sc, tail[-1][1] + 6 * sc)], fill=INK,
           width=max(2, int(6 * sc)))

    # kollar (önde)
    hands = []
    for side, a1, a2 in ((-1, p["la1"], p["la2"]), (1, p["ra1"], p["ra2"])):
        sh = (cx + side * w * 0.43 + (cy - (cy + h * 0.22)) * lean, cy + h * 0.22)
        a1 = a1 + side * 12 if abs(a1) < 30 else a1
        elbow, hand = _limb(sh, a1, a2, 82 * sc, 72 * sc)
        _noodle(d, _bezier(sh, elbow, hand, 10), BODY, 24 * sc)
        hands.append(hand)
        r = 25 * sc
        d.ellipse([hand[0] - r, hand[1] - r, hand[0] + r, hand[1] + r], fill=GLOVE, outline=INK, width=lw)
        d.arc([hand[0] - r * 0.6, hand[1] - r * 0.6, hand[0] + r * 0.6, hand[1] + r * 0.6], 200, 300, fill=(200, 200, 210),
              width=max(2, int(4 * sc)))

    return dict(hand_l=hands[0], hand_r=hands[1], head=(fx, top[1]),
                hands=((hands[0][0] + hands[1][0]) / 2, (hands[0][1] + hands[1][1]) / 2), face=(fx, fy))
