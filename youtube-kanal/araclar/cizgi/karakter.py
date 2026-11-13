"""THE BUDGETS: cairo ile çizilen, kemikli (rig) 2D karakterler.

Stil: kalın siyah kontur, düz renk dolgu, tek ton gölge, büyük göz, abartılı çene.
Her karakter bir SPEC sözlüğüyle tanımlanır; her karede poz/duygu/ağız/göz parametreleriyle çizilir.
Koordinat: karakter kökeni ayak ortası (x, zemin y). Yerel birimde boy ~620.
"""
import math

import cairo

LW = 6.0  # kontur kalınlığı (yerel birim)
INK = (0.07, 0.06, 0.08)


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def darker(c, k=0.78):
    return tuple(v * k for v in c)


SPECS = {
    "dale": dict(skin="#f2c49b", hair="#5a3a22", hair_style="tuft", shirt="#f4f1e8", accent="#c8262c", pants="#3b4a6b",
                 shoes="#3a2a1e", body_w=230, body_h=230, belly=34, head_w=200, head_h=205, chin=1.18, leg_h=135, arm_w=34,
                 stubble=True),
    "tammy": dict(skin="#f6d0b0", hair="#f2c94c", hair_style="bob", shirt="#7b4fa0", accent="#f4f1e8", pants="#2e2a3a",
                  shoes="#7a1f2b", body_w=170, body_h=225, belly=0, head_w=176, head_h=196, chin=0.9, leg_h=165, arm_w=26,
                  lipstick="#c0303c", pearls=True),
    "kyle": dict(skin="#efc3a0", hair="#2b211b", hair_style="beanie", hat="#2f6f5e", shirt="#556b2f", accent="#d9d4c5",
                 pants="#2f3440", shoes="#d8d8d8", body_w=150, body_h=215, belly=0, head_w=168, head_h=190, chin=0.95,
                 leg_h=170, arm_w=24, lids=0.45, hoodie=True),
    "earl": dict(skin="#e8b994", hair="#ecebe6", hair_style="bald", shirt="#8a6d4b", accent="#c9b48a", pants="#6b6b5e",
                 shoes="#2d2420", body_w=170, body_h=200, belly=14, head_w=182, head_h=196, chin=1.05, leg_h=140, arm_w=26,
                 glasses=True, mustache=True, lids=0.2),
    "officer": dict(skin="#c98e64", hair="#1c1a19", hair_style="flat", shirt="#2c3e66", accent="#e3c35a", pants="#22304f",
                    shoes="#141414", body_w=210, body_h=225, belly=40, head_w=188, head_h=200, chin=1.1, leg_h=140, arm_w=32,
                    cap=True, mustache=True),
    "gary": dict(skin="#f0c2a2", hair="#8a6a3a", hair_style="flat", shirt="#f08aa8", accent="#f4f1e8", pants="#c8b48a",
                 shoes="#f4f1e8", body_w=180, body_h=225, belly=22, head_w=170, head_h=210, chin=1.25, leg_h=170, arm_w=27,
                 mustache=True, lids=0.15),
    "mayor": dict(skin="#e9b896", hair="#bdbdbd", hair_style="bob", shirt="#b3263a", accent="#f4f1e8", pants="#2b2b33",
                  shoes="#1b1b1b", body_w=175, body_h=220, belly=10, head_w=178, head_h=196, chin=0.95, leg_h=155, arm_w=27,
                  glasses=True, pearls=True, lipstick="#8a1f2b"),
    "jace": dict(skin="#8d5a3b", hair="#151212", hair_style="flat", shirt="#e67e22", accent="#f4f1e8", pants="#3a4a6b",
                 shoes="#e74c3c", body_w=140, body_h=210, belly=0, head_w=162, head_h=186, chin=0.92, leg_h=175, arm_w=23,
                 hoodie=True),
}

# Kol pozları: (üst kol açısı, ön kol açısı) derece; 0 = aşağı, + = dışa, 180 = yukarı. (sol_kol, sağ_kol)
POSES = {
    "rest": ((10, 6), (10, 6)),
    "hips": ((48, -48), (48, -48)),
    "point": ((10, 6), (92, 98)),
    "shrug": ((32, 115), (32, 115)),
    "up": ((150, 172), (150, 172)),
    "wave": ((10, 6), (125, 175)),
    "phone": ((10, 6), (22, -152)),
    "fold": ((14, -82), (14, -82)),
    "think": ((14, -82), (22, -140)),
    "fist": ((10, 6), (60, 165)),
    "present": ((55, 95), (55, 95)),
    "facepalm": ((10, 6), (25, -165)),
}


def lerp(a, b, t):
    return a + (b - a) * t


def ease(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def blend_pose(p1, p2, t):
    t = ease(t)
    return tuple(tuple(lerp(a, b, t) for a, b in zip(x, y)) for x, y in zip(p1, p2))


def fill_stroke(ctx, col, lw=LW):
    ctx.set_source_rgb(*col)
    ctx.fill_preserve()
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(lw)
    ctx.stroke()


def ellipse(ctx, x, y, rx, ry):
    ctx.save()
    ctx.translate(x, y)
    ctx.scale(rx, ry)
    ctx.new_sub_path()
    ctx.arc(0, 0, 1, 0, 2 * math.pi)
    ctx.restore()


def rrect(ctx, x, y, w, h, r):
    r = min(r, w / 2, h / 2)
    ctx.new_sub_path()
    ctx.arc(x + w - r, y + r, r, -math.pi / 2, 0)
    ctx.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
    ctx.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
    ctx.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
    ctx.close_path()


def limb(ctx, pts, w, col):
    """Kalın konturlu uzuv (çoklu nokta)."""
    ctx.set_line_cap(cairo.LINE_CAP_ROUND)
    ctx.set_line_join(cairo.LINE_JOIN_ROUND)
    for width, c in ((w + 2 * LW, INK), (w, col)):
        ctx.move_to(*pts[0])
        for p in pts[1:]:
            ctx.line_to(*p)
        ctx.set_source_rgb(*c)
        ctx.set_line_width(width)
        ctx.stroke()


class Character:
    def __init__(self, name):
        self.name = name
        sp = SPECS[name]
        self.sp = sp
        self.c = {k: rgb(v) for k, v in sp.items() if isinstance(v, str) and v.startswith("#")}

    # ---------- parçalar ----------
    def head_path(self, ctx, w, h, chin):
        ellipse(ctx, 0, -h * 0.08, w / 2, h * 0.42)
        ellipse(ctx, 0, h * 0.18, w * 0.42 * chin, h * 0.30)

    def draw_head(self, ctx, st):
        sp, c = self.sp, self.c
        w, h, chin = sp["head_w"], sp["head_h"], sp["chin"]
        # arka saç (bob)
        if sp["hair_style"] == "bob":
            ctx.move_to(-w * 0.62, h * 0.26)
            ctx.curve_to(-w * 0.80, -h * 0.78, w * 0.80, -h * 0.78, w * 0.62, h * 0.26)
            ctx.curve_to(w * 0.3, h * 0.34, -w * 0.3, h * 0.34, -w * 0.62, h * 0.26)
            ctx.close_path()
            fill_stroke(ctx, c["hair"])
        # kulaklar
        for sx in (-1, 1):
            ellipse(ctx, sx * w * 0.49, h * 0.0, w * 0.09, h * 0.11)
            fill_stroke(ctx, c["skin"])
            ctx.arc(sx * w * 0.50, h * 0.0, w * 0.04, math.pi * 0.6, math.pi * 1.4) if sx < 0 else ctx.arc(sx * w * 0.50, h * 0.0, w * 0.04, -math.pi * 0.4, math.pi * 0.4)
            ctx.set_source_rgb(*darker(c["skin"], 0.6))
            ctx.set_line_width(3)
            ctx.stroke()
        # kafa + çene birleşik kontur
        ctx.set_source_rgb(*INK)
        self.head_path(ctx, w + 2 * LW, h + 2 * LW, chin)
        ctx.fill()
        ctx.set_source_rgb(*c["skin"])
        self.head_path(ctx, w, h, chin)
        ctx.fill()
        ctx.save()
        self.head_path(ctx, w, h, chin)
        ctx.clip()
        ctx.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
        ctx.rectangle(-w, -h, 2 * w, 2 * h)
        ellipse(ctx, -w * 0.13, -h * 0.13, w * 0.50, h * 0.60)
        ctx.set_source_rgba(*darker(c["skin"], 0.72), 0.55)
        ctx.fill()
        ctx.set_fill_rule(cairo.FILL_RULE_WINDING)
        ellipse(ctx, -w * 0.22, -h * 0.30, w * 0.14, h * 0.06)
        ctx.set_source_rgba(1, 1, 1, 0.18)
        ctx.fill()
        for sx in (-1, 1):
            ellipse(ctx, sx * w * 0.27, h * 0.15, w * 0.075, h * 0.04)
            ctx.set_source_rgba(0.95, 0.45, 0.45, 0.30)
            ctx.fill()
        ctx.restore()
        # sakal gölgesi
        if sp.get("stubble"):
            ctx.save()
            self.head_path(ctx, w, h, chin)
            ctx.clip()
            ellipse(ctx, 0, h * 0.30, w * 0.44 * chin, h * 0.22)
            ctx.set_source_rgba(0.35, 0.33, 0.42, 0.28)
            ctx.fill()
            ctx.restore()
        # saç / şapka
        hs = sp["hair_style"]
        if hs in ("tuft", "flat"):
            ctx.save()
            self.head_path(ctx, w, h, chin)
            ctx.clip()
            ctx.move_to(-w, -h)
            ctx.line_to(w, -h)
            ctx.line_to(w, -h * 0.26)
            ctx.curve_to(w * 0.3, -h * 0.30, w * 0.1, -h * 0.20, -w * 0.05, -h * 0.30)
            ctx.curve_to(-w * 0.25, -h * 0.24, -w * 0.4, -h * 0.20, -w, -h * 0.14)
            ctx.close_path()
            ctx.set_source_rgb(*c["hair"])
            ctx.fill_preserve()
            ctx.set_source_rgb(*INK)
            ctx.set_line_width(LW)
            ctx.stroke()
            for k in range(3):
                ctx.move_to(-w * (0.30 - k * 0.12), -h * 0.40)
                ctx.curve_to(-w * (0.24 - k * 0.12), -h * 0.36, -w * (0.18 - k * 0.12), -h * 0.33, -w * (0.12 - k * 0.12), -h * 0.32)
            ctx.set_source_rgba(1, 1, 1, 0.22)
            ctx.set_line_width(5)
            ctx.stroke()
            ctx.restore()
            if hs == "tuft":
                ctx.move_to(-w * 0.04, -h * 0.47)
                ctx.curve_to(w * 0.02, -h * 0.62, w * 0.12, -h * 0.60, w * 0.16, -h * 0.66)
                ctx.curve_to(w * 0.14, -h * 0.55, w * 0.10, -h * 0.50, w * 0.12, -h * 0.47)
                ctx.close_path()
                fill_stroke(ctx, c["hair"])
        elif hs == "bob":
            ctx.save()
            self.head_path(ctx, w, h, chin)
            ctx.clip()
            ctx.move_to(-w, -h)
            ctx.line_to(w, -h)
            ctx.line_to(w, -h * 0.05)
            ctx.curve_to(w * 0.45, -h * 0.10, w * 0.40, -h * 0.30, w * 0.05, -h * 0.28)
            ctx.curve_to(-w * 0.3, -h * 0.26, -w * 0.45, -h * 0.20, -w, -h * 0.02)
            ctx.close_path()
            fill_stroke(ctx, c["hair"])
            ctx.restore()
            ellipse(ctx, 0, -h * 0.36, w * 0.52, h * 0.2)
            ctx.set_source_rgb(*c["hair"])
            ctx.fill()
            ctx.arc(-w * 0.02, -h * 0.22, w * 0.30, math.pi * 1.15, math.pi * 1.5)
            ctx.set_source_rgba(1, 1, 1, 0.35)
            ctx.set_line_width(9)
            ctx.stroke()
            for k in (-0.25, 0.0, 0.22):
                ctx.move_to(w * k, -h * 0.47)
                ctx.curve_to(w * (k + 0.03), -h * 0.38, w * (k + 0.08), -h * 0.32, w * (k + 0.12), -h * 0.28)
            ctx.set_source_rgb(*darker(c["hair"], 0.75))
            ctx.set_line_width(3)
            ctx.stroke()
        elif hs == "beanie":
            ctx.move_to(-w * 0.55, -h * 0.22)
            ctx.curve_to(-w * 0.58, -h * 0.75, w * 0.58, -h * 0.75, w * 0.55, -h * 0.22)
            ctx.close_path()
            fill_stroke(ctx, c["hat"])
            ctx.arc(-w * 0.05, -h * 0.34, w * 0.24, math.pi * 1.15, math.pi * 1.5)
            ctx.set_source_rgba(1, 1, 1, 0.2)
            ctx.set_line_width(8)
            ctx.stroke()
            rrect(ctx, -w * 0.58, -h * 0.30, w * 1.16, h * 0.13, 10)
            fill_stroke(ctx, darker(c["hat"]))
            for k in range(-6, 7):
                ctx.move_to(k * w * 0.085, -h * 0.29)
                ctx.line_to(k * w * 0.085, -h * 0.18)
            ctx.set_source_rgba(0, 0, 0, 0.25)
            ctx.set_line_width(3)
            ctx.stroke()
            for sx in (-1, 1):  # perçem
                ctx.move_to(sx * w * 0.45, -h * 0.18)
                ctx.line_to(sx * w * 0.50, -h * 0.02)
                ctx.line_to(sx * w * 0.36, -h * 0.17)
                ctx.close_path()
                fill_stroke(ctx, c["hair"], 4)
        elif hs == "bald":
            for sx in (-1, 1):
                ellipse(ctx, sx * w * 0.47, -h * 0.10, w * 0.10, h * 0.12)
                fill_stroke(ctx, c["hair"])
            ctx.move_to(-w * 0.18, -h * 0.38)
            ctx.curve_to(-w * 0.1, -h * 0.42, w * 0.0, -h * 0.40, w * 0.06, -h * 0.36)
            ctx.set_source_rgb(*darker(c["skin"], 0.7))
            ctx.set_line_width(3)
            ctx.stroke()
        if sp.get("cap"):
            ctx.move_to(-w * 0.52, -h * 0.30)
            ctx.curve_to(-w * 0.5, -h * 0.72, w * 0.5, -h * 0.72, w * 0.52, -h * 0.30)
            ctx.close_path()
            fill_stroke(ctx, c["shirt"])
            ctx.move_to(-w * 0.1, -h * 0.30)
            ctx.curve_to(w * 0.2, -h * 0.38, w * 0.55, -h * 0.34, w * 0.70, -h * 0.24)
            ctx.line_to(-w * 0.1, -h * 0.24)
            ctx.close_path()
            fill_stroke(ctx, (0.08, 0.1, 0.16))
            ellipse(ctx, 0, -h * 0.47, w * 0.07, h * 0.06)
            fill_stroke(ctx, c["accent"], 3)
        self.draw_face(ctx, st, w, h)

    def draw_face(self, ctx, st, w, h):
        sp, c = self.sp, self.c
        emo = st.get("emo", "neutral")
        lx, ly = st.get("look", (0.0, 0.0))
        blink = st.get("blink", 0.0)
        ew, eh = w * 0.15, h * 0.17
        ey = -h * 0.06
        big = 1.18 if emo == "shock" else 1.0
        for i, sx in enumerate((-1, 1)):
            ex = sx * w * 0.135
            ellipse(ctx, ex, ey, ew * big, eh * big)
            fill_stroke(ctx, (1, 1, 1), 4.5)
            pr = 0.22 if emo == "shock" else 0.30
            px, py = ex + lx * ew * 0.45, ey + ly * eh * 0.35 + eh * 0.1
            ellipse(ctx, px, py, ew * pr, ew * pr)
            ctx.set_source_rgb(*INK)
            ctx.fill()
            ellipse(ctx, px - ew * pr * 0.35, py - ew * pr * 0.4, ew * pr * 0.32, ew * pr * 0.32)
            ctx.set_source_rgb(1, 1, 1)
            ctx.fill()
            lid = max(blink, sp.get("lids", 0.0) if emo not in ("shock", "happy") else 0.0)
            if emo == "angry":
                lid = max(lid, 0.3)
            if lid > 0.01:
                ctx.save()
                ellipse(ctx, ex, ey, ew * big, eh * big)
                ctx.clip()
                ctx.rectangle(ex - ew * 1.2, ey - eh * 1.2, ew * 2.4, eh * 2.4 * lid)
                ctx.set_source_rgb(*c["skin"])
                ctx.fill()
                ctx.move_to(ex - ew * 1.2, ey - eh * 1.2 + eh * 2.4 * lid)
                ctx.line_to(ex + ew * 1.2, ey - eh * 1.2 + eh * 2.4 * lid)
                ctx.set_source_rgb(*INK)
                ctx.set_line_width(4)
                ctx.stroke()
                ctx.restore()
                ellipse(ctx, ex, ey, ew * big, eh * big)
                ctx.set_source_rgb(*INK)
                ctx.set_line_width(4.5)
                ctx.stroke()
            # kaş
            tilt = {"angry": 0.35, "sad": -0.3, "shock": -0.05, "happy": -0.1, "smug": 0.15}.get(emo, 0.0)
            by = ey - eh * (1.25 if emo == "shock" else 1.12)
            ctx.move_to(ex - sx * ew * 0.9, by - tilt * eh * 0.6 * -1)
            ctx.line_to(ex + sx * ew * 0.9, by + tilt * eh * 0.6 * -1 + (0 if emo != "smug" or sx < 0 else -eh * 0.3))
            ctx.set_source_rgb(*(darker(c["hair"], 0.6) if sp["hair_style"] != "bald" else (0.75, 0.75, 0.72)))
            ctx.set_line_width(7)
            ctx.set_line_cap(cairo.LINE_CAP_ROUND)
            ctx.stroke()
        if sp.get("glasses"):
            for sx in (-1, 1):
                ellipse(ctx, sx * w * 0.135, ey, ew * 1.25, eh * 1.15)
                ctx.set_source_rgba(0.85, 0.92, 1.0, 0.18)
                ctx.fill_preserve()
                ctx.set_source_rgb(*INK)
                ctx.set_line_width(5)
                ctx.stroke()
        # burun (bakış yönüne)
        ctx.move_to(w * 0.02, h * 0.06)
        ctx.curve_to(w * 0.16, h * 0.06, w * 0.16, h * 0.17, w * 0.03, h * 0.16)
        ctx.set_source_rgb(*c["skin"])
        ctx.fill_preserve()
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(4.5)
        ctx.stroke()
        if sp.get("mustache"):
            ctx.move_to(-w * 0.17, h * 0.25)
            ctx.curve_to(-w * 0.12, h * 0.17, w * 0.12, h * 0.17, w * 0.19, h * 0.25)
            ctx.curve_to(w * 0.08, h * 0.22, -w * 0.08, h * 0.22, -w * 0.17, h * 0.25)
            fill_stroke(ctx, c["hair"] if sp["hair_style"] == "bald" else (0.12, 0.1, 0.09), 3.5)
        self.draw_mouth(ctx, st, w, h)

    def draw_mouth(self, ctx, st, w, h):
        c = self.c
        emo = st.get("emo", "neutral")
        o = st.get("mouth", 0.0)
        my = h * 0.30
        mw = w * (0.17 if emo != "shock" else 0.10)
        if emo == "shock":
            o = max(o, 0.6)
        if o < 0.08:
            curve = {"happy": 0.10, "smug": 0.05, "sad": -0.07, "angry": -0.05}.get(emo, 0.02)
            ctx.move_to(-mw, my)
            ctx.curve_to(-mw * 0.4, my + h * curve, mw * 0.4, my + h * curve, mw * (1.15 if emo == "smug" else 1), my - (h * 0.04 if emo == "smug" else 0))
            ctx.set_source_rgb(*INK)
            ctx.set_line_width(5)
            ctx.set_line_cap(cairo.LINE_CAP_ROUND)
            ctx.stroke()
            return
        oh = h * 0.035 + o * h * 0.13
        top = my - oh * 0.25
        wide = mw * (1.0 + (0.25 if emo in ("happy", "angry") else 0) - o * 0.15)
        ctx.move_to(-wide, top)
        ctx.curve_to(-wide * 0.5, top - h * 0.015, wide * 0.5, top - h * 0.015, wide, top)
        ctx.curve_to(wide * 0.9, top + oh * 1.2, -wide * 0.9, top + oh * 1.2, -wide, top)
        ctx.close_path()
        ctx.save()
        ctx.clip_preserve()
        ctx.set_source_rgb(0.32, 0.06, 0.08)
        ctx.fill()
        ctx.rectangle(-wide, top - 5, wide * 2, oh * 0.28)
        ctx.set_source_rgb(1, 1, 1)
        ctx.fill()
        ellipse(ctx, 0, top + oh * 0.95, wide * 0.55, oh * 0.35)
        ctx.set_source_rgb(0.9, 0.42, 0.45)
        ctx.fill()
        ctx.restore()
        ctx.move_to(-wide, top)
        ctx.curve_to(-wide * 0.5, top - h * 0.015, wide * 0.5, top - h * 0.015, wide, top)
        ctx.curve_to(wide * 0.9, top + oh * 1.2, -wide * 0.9, top + oh * 1.2, -wide, top)
        ctx.close_path()
        ctx.set_source_rgb(*(rgb(self.sp["lipstick"]) if self.sp.get("lipstick") else INK))
        ctx.set_line_width(5)
        ctx.stroke()

    def arm_pts(self, sx, shoulder, a1, a2, L1, L2):
        r1, r2 = math.radians(a1), math.radians(a2)
        e = (shoulder[0] + sx * math.sin(r1) * L1, shoulder[1] + math.cos(r1) * L1)
        hnd = (e[0] + sx * math.sin(r2) * L2, e[1] + math.cos(r2) * L2)
        return [shoulder, e, hnd]

    def draw(self, ctx, x, y, s, st):
        """st: facing(+1/-1), pose(tuple), emo, mouth, blink, look, bob, walk(faz) ."""
        sp, c = self.sp, self.c
        ctx.save()
        ctx.translate(x, y)
        ctx.scale(s * st.get("facing", 1), s)
        bw, bh, lh = sp["body_w"], sp["body_h"], sp["leg_h"]
        bob = st.get("bob", 0.0)
        walk = st.get("walk")
        ellipse(ctx, 6, -4, bw * 0.66, 18)
        ctx.set_source_rgba(0, 0, 0, 0.22)
        ctx.fill()
        # bacaklar
        for sx in (-1, 1):
            sw = math.sin(walk + (0 if sx > 0 else math.pi)) * 18 if walk is not None else 0
            lift = max(0, math.sin(walk + (0 if sx > 0 else math.pi))) * 14 if walk is not None else 0
            hx = sx * bw * 0.22
            limb(ctx, [(hx, -lh), (hx + sw, -lift - 12)], bw * 0.28, c["pants"])
            ctx.move_to(hx + bw * 0.08, -lh + 10)
            ctx.line_to(hx + sw + bw * 0.08, -lift - 26)
            ctx.set_source_rgba(0, 0, 0, 0.18)
            ctx.set_line_width(bw * 0.09)
            ctx.stroke()
            ellipse(ctx, hx + sw + 16, -lift - 8, bw * 0.19, 15)
            fill_stroke(ctx, c["shoes"])
            ellipse(ctx, hx + sw + 6, -lift - 14, bw * 0.07, 4)
            ctx.set_source_rgba(1, 1, 1, 0.35)
            ctx.fill()
        ctx.translate(0, -lh + bob)
        # kollar arka katman değil: gövdeden sonra çizilecek; omuz noktaları
        top = -bh
        # gövde
        ctx.move_to(-bw * 0.42, top + 10)
        ctx.curve_to(-bw * 0.55, top + bh * 0.4, -bw * 0.5 - sp["belly"], top + bh * 0.8, -bw * 0.44, 4)
        ctx.line_to(bw * 0.44, 4)
        ctx.curve_to(bw * 0.5 + sp["belly"], top + bh * 0.8, bw * 0.55, top + bh * 0.4, bw * 0.42, top + 10)
        ctx.curve_to(bw * 0.2, top - 6, -bw * 0.2, top - 6, -bw * 0.42, top + 10)
        ctx.close_path()
        torso = ctx.copy_path()
        fill_stroke(ctx, c["shirt"])
        ctx.save()
        ctx.append_path(torso)
        ctx.clip()
        ctx.move_to(bw * 0.16, top - 10)
        ctx.curve_to(bw * 0.30, top + bh * 0.3, bw * 0.26, top + bh * 0.7, bw * 0.20, 10)
        ctx.line_to(bw, 10)
        ctx.line_to(bw, top - 10)
        ctx.close_path()
        ctx.set_source_rgba(*darker(c["shirt"], 0.7), 0.6)
        ctx.fill()
        for sx in (-1, 1):  # kıvrım çizgileri
            ctx.move_to(sx * bw * 0.36, top + bh * 0.62)
            ctx.curve_to(sx * bw * 0.30, top + bh * 0.70, sx * bw * 0.30, top + bh * 0.78, sx * bw * 0.34, top + bh * 0.86)
        ctx.set_source_rgba(0, 0, 0, 0.3)
        ctx.set_line_width(3.5)
        ctx.stroke()
        ctx.restore()
        ctx.append_path(torso)
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(LW)
        ctx.stroke()
        if self.name == "dale":  # cep + düğmeler
            rrect(ctx, -bw * 0.34, top + 50, 42, 46, 4)
            ctx.set_source_rgb(*INK)
            ctx.set_line_width(3.5)
            ctx.stroke()
            for k in range(4):
                ellipse(ctx, -24, top + 70 + k * 42, 4.5, 4.5)
                ctx.set_source_rgb(0.75, 0.72, 0.66)
                ctx.fill()
        if self.name == "tammy":  # hırka açıklığı + düğmeler
            ctx.move_to(0, top + 30)
            ctx.line_to(0, -12)
            ctx.set_source_rgb(*INK)
            ctx.set_line_width(4)
            ctx.stroke()
            for k in range(4):
                ellipse(ctx, -12, top + 60 + k * 40, 6, 6)
                fill_stroke(ctx, (0.95, 0.9, 0.75), 2.5)
        # kemer
        ctx.rectangle(-bw * 0.44, -12, bw * 0.88, 16)
        fill_stroke(ctx, darker(c["pants"], 0.7), 4)
        if sp.get("hoodie"):
            for sx in (-1, 1):
                ctx.move_to(sx * bw * 0.08, top + 18)
                ctx.line_to(sx * bw * 0.1, top + 85)
                ctx.set_source_rgb(*c["accent"])
                ctx.set_line_width(5)
                ctx.stroke()
            rrect(ctx, -bw * 0.3, top + bh * 0.55, bw * 0.6, bh * 0.28, 14)
            fill_stroke(ctx, darker(c["shirt"], 0.85), 4)
        elif self.name == "dale":
            for sx in (-1, 1):  # yaka
                ctx.move_to(0, top + 8)
                ctx.line_to(sx * bw * 0.22, top + 2)
                ctx.line_to(sx * bw * 0.12, top + 42)
                ctx.close_path()
                fill_stroke(ctx, c["shirt"], 4)
            ctx.move_to(-10, top + 18)  # gevşek kravat
            ctx.line_to(10, top + 18)
            ctx.line_to(18, top + 130)
            ctx.line_to(4, top + 150)
            ctx.line_to(-8, top + 128)
            ctx.close_path()
            fill_stroke(ctx, c["accent"], 4)
        elif self.name == "officer":
            ellipse(ctx, -bw * 0.22, top + 60, 16, 18)
            fill_stroke(ctx, c["accent"], 4)
            ctx.move_to(0, top + 4)
            ctx.line_to(0, -14)
            ctx.set_source_rgb(*INK)
            ctx.set_line_width(4)
            ctx.stroke()
        elif self.name == "earl":
            for sx in (-1, 1):
                ctx.move_to(sx * 6, top + 4)
                ctx.line_to(sx * bw * 0.16, -14)
                ctx.set_source_rgb(*INK)
                ctx.set_line_width(4)
                ctx.stroke()
            ctx.rectangle(-bw * 0.06, top + 4, bw * 0.12, bh - 18)
            ctx.set_source_rgb(*c["accent"])
            ctx.fill()
        # boyun + kafa
        neck = sp["head_h"] * 0.42
        rrect(ctx, -sp["head_w"] * 0.13, top - neck * 0.55, sp["head_w"] * 0.26, neck * 0.7, 10)
        fill_stroke(ctx, c["skin"], 5)
        if sp.get("pearls"):
            for i in range(9):
                a = math.pi * (0.15 + 0.7 * i / 8)
                ellipse(ctx, math.cos(a) * bw * 0.22, top + 6 + math.sin(a) * 26, 7, 7)
                fill_stroke(ctx, (0.97, 0.95, 0.9), 2.5)
        # kollar
        pose = st.get("pose", POSES["rest"])
        L1, L2 = bh * 0.48, bh * 0.44
        for i, sx in enumerate((-1, 1)):
            a1, a2 = pose[i]
            sh = (sx * bw * 0.40, top + 26)
            pts = self.arm_pts(sx, sh, a1, a2, L1, L2)
            limb(ctx, pts, sp["arm_w"], c["shirt"])
            # kol ağzı + el
            hx, hy = pts[2]
            ex_, ey_ = pts[1]
            dx, dy = hx - ex_, hy - ey_
            dl = math.hypot(dx, dy) or 1
            cxm, cym = ex_ + dx * 0.80, ey_ + dy * 0.80
            nx, ny = -dy / dl * sp["arm_w"] * 0.55, dx / dl * sp["arm_w"] * 0.55
            ctx.move_to(cxm - nx, cym - ny)
            ctx.line_to(cxm + nx, cym + ny)
            ctx.set_source_rgb(*INK)
            ctx.set_line_width(3.5)
            ctx.stroke()
            ellipse(ctx, hx - sx * sp["arm_w"] * 0.45, hy - sp["arm_w"] * 0.2, sp["arm_w"] * 0.26, sp["arm_w"] * 0.22)
            fill_stroke(ctx, c["skin"], 4)
            ellipse(ctx, hx, hy, sp["arm_w"] * 0.62, sp["arm_w"] * 0.62)
            fill_stroke(ctx, c["skin"], 5)
            ctx.arc(hx, hy, sp["arm_w"] * 0.62, 0.2, 1.4)
            ctx.set_source_rgba(0, 0, 0, 0.18)
            ctx.set_line_width(6)
            ctx.stroke()
            if st.get("prop") == "phone" and sx > 0:
                ctx.save()
                ctx.translate(hx, hy - 6)
                ctx.rotate(-0.2)
                rrect(ctx, -14, -34, 30, 54, 6)
                fill_stroke(ctx, (0.15, 0.15, 0.18), 4)
                rrect(ctx, -9, -28, 20, 40, 3)
                ctx.set_source_rgb(0.45, 0.8, 1.0)
                ctx.fill()
                ctx.restore()
        hy = top - neck * 0.38 - sp["head_h"] * 0.36
        ctx.save()
        ctx.translate(0, hy)
        ctx.rotate(st.get("tilt", 0.0))
        self.draw_head(ctx, st)
        ctx.restore()
        ctx.restore()


class Homi:
    """Akıllı ev asistanı: masa üstü silindir, konuşurken halka ışığı yanar."""
    name = "homi"

    def draw(self, ctx, x, y, s, st):
        ctx.save()
        ctx.translate(x, y)
        ctx.scale(s, s)
        o = st.get("mouth", 0.0)
        emo = st.get("emo", "neutral")
        col = (0.95, 0.25, 0.25) if emo == "angry" else (0.35, 0.85, 1.0)
        ctx.move_to(-70, 0)
        ctx.line_to(-70, -170)
        ctx.curve_to(-70, -200, 70, -200, 70, -170)
        ctx.line_to(70, 0)
        ctx.curve_to(70, 22, -70, 22, -70, 0)
        ctx.close_path()
        fill_stroke(ctx, (0.18, 0.19, 0.23))
        for k in range(5):
            ctx.move_to(-56, -40 - k * 22)
            ctx.line_to(56, -40 - k * 22)
            ctx.set_source_rgb(0.12, 0.13, 0.16)
            ctx.set_line_width(4)
            ctx.stroke()
        ellipse(ctx, 0, -178, 64, 16)
        glow = 0.35 + 0.65 * min(1, o * 1.6)
        ctx.set_source_rgba(*col, glow)
        ctx.fill_preserve()
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(5)
        ctx.stroke()
        if o > 0.05:
            for r in (1.2, 1.45):
                ellipse(ctx, 0, -178, 64 * r, 16 * r)
                ctx.set_source_rgba(*col, 0.25 * o)
                ctx.set_line_width(4)
                ctx.stroke()
        # "göz": iki küçük ekran noktası
        for sx in (-1, 1):
            if emo == "angry":
                ctx.move_to(sx * 34, -132)
                ctx.line_to(sx * 14, -122)
                ctx.set_source_rgb(*col)
                ctx.set_line_width(8)
                ctx.stroke()
            else:
                ellipse(ctx, sx * 24, -124, 9, 9 * (1 - st.get("blink", 0) * 0.9))
                ctx.set_source_rgb(*col)
                ctx.fill()
        ctx.restore()


def make(name):
    return Homi() if name == "homi" else Character(name)
