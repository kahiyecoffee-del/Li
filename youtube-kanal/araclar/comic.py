"""Noir çizgi roman çizim yardımcıları (2x süper örnekleme, kalın kontur, sert gölge, tram)."""
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

INK = (12, 10, 14)
SS = 2


class Panel:
    def __init__(self, w, h, bg=(240, 230, 210)):
        self.w, self.h = w, h
        self.im = Image.new("RGB", (w * SS, h * SS), bg)
        self.d = ImageDraw.Draw(self.im)

    def P(self, pts):
        return [(x * SS, y * SS) for x, y in pts]

    def poly(self, pts, fill, outline=INK, width=5):
        self.d.polygon(self.P(pts), fill=fill)
        if outline and width:
            q = self.P(pts)
            self.d.line(q + [q[0]], fill=outline, width=width * SS, joint="curve")

    def line(self, pts, fill=INK, width=4):
        self.d.line(self.P(pts), fill=fill, width=width * SS, joint="curve")

    def ellipse(self, box, fill, outline=INK, width=4):
        x0, y0, x1, y1 = box
        self.d.ellipse([x0 * SS, y0 * SS, x1 * SS, y1 * SS], fill=fill, outline=outline, width=width * SS if outline else 0)

    def gradient(self, top, bottom, y0=0, y1=None):
        y1 = y1 or self.h
        for y in range(y0 * SS, y1 * SS):
            u = (y - y0 * SS) / max(1, (y1 - y0) * SS)
            self.d.line([(0, y), (self.w * SS, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * u) for i in range(3)))

    def halftone(self, box, color, step=14, rmax=5, fade="down"):
        x0, y0, x1, y1 = box
        for y in range(y0, y1, step):
            for x in range(x0 + (step // 2 if (y // step) % 2 else 0), x1, step):
                u = (y - y0) / max(1, y1 - y0)
                r = rmax * (1 - u if fade == "down" else u)
                if r > 0.6:
                    self.ellipse((x - r, y - r, x + r, y + r), color, outline=None)

    def text(self, xy, s, size, fill=INK, anchor="mm", font="fonts/Kalam-Bold.ttf", stroke=0, stroke_fill=INK):
        f = ImageFont.truetype(font, size * SS)
        self.d.text((xy[0] * SS, xy[1] * SS), s, font=f, fill=fill, anchor=anchor, stroke_width=stroke * SS, stroke_fill=stroke_fill)

    def bubble(self, x, y, w, h, tail, s, size=34):
        tx, ty = tail
        ang = math.atan2(ty - y, tx - x)
        bx, by = x + math.cos(ang) * w * 0.38, y + math.sin(ang) * h * 0.38
        nx, ny = -math.sin(ang) * w * 0.08, math.cos(ang) * h * 0.08
        self.poly([(bx + nx, by + ny), (tx, ty), (bx - nx, by - ny)], (250, 250, 245), width=4)
        self.ellipse((x - w / 2, y - h / 2, x + w / 2, y + h / 2), (250, 250, 245), width=4)
        self.ellipse((x - w / 2 + 5, y - h / 2 + 5, x + w / 2 - 5, y + h / 2 - 5), (250, 250, 245), outline=None)
        self.text((x, y), s, size)

    def caption(self, x, y, s, size=30, fill=(245, 215, 90)):
        f = ImageFont.truetype("fonts/Kalam-Bold.ttf", size * SS)
        bb = self.d.textbbox((x * SS, y * SS), s, font=f, anchor="lt")
        pad = 12 * SS
        self.d.rectangle([bb[0] - pad, bb[1] - pad, bb[2] + pad, bb[3] + pad], fill=fill, outline=INK, width=4 * SS)
        self.d.text((x * SS, y * SS), s, font=f, fill=INK, anchor="lt")

    def image(self):
        return self.im.resize((self.w, self.h), Image.LANCZOS)


def page(panels, W=1920, H=1080, gutter=18, bg=(15, 12, 16)):
    """panels: [(Panel, x, y)]"""
    out = Image.new("RGB", (W, H), bg)
    for p, x, y in panels:
        im = p.image()
        out.paste(im, (x, y))
        ImageDraw.Draw(out).rectangle([x, y, x + p.w - 1, y + p.h - 1], outline=(0, 0, 0), width=6)
    return out
