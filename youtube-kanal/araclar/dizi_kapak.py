#!/usr/bin/env python3
"""DEAD QUOTA pilot kapakları (1280x720): AI kareleri + kalın başlık."""
import os
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

K = "cikti/dizi/pilot/kareler/"
O = "cikti/dizi/pilot/kapak/"
F = "/usr/share/fonts/opentype/inter/InterDisplay-Black.otf"


def f(s):
    return ImageFont.truetype(F, s)


def base(name, crop=None):
    im = Image.open(K + name).convert("RGB")
    if crop:
        im = im.crop(crop)
    im = im.resize((1280, int(1280 * im.height / im.width)))
    im = im.crop((0, (im.height - 720) // 2, 1280, (im.height - 720) // 2 + 720))
    im = ImageEnhance.Contrast(im).enhance(1.15)
    return ImageEnhance.Color(im).enhance(1.15)


def shade(im, side):
    g = Image.new("L", (1280, 720), 0)
    d = ImageDraw.Draw(g)
    for x in range(1280):
        t = x / 1279 if side == "right" else 1 - x / 1279
        d.line((x, 0, x, 720), fill=int(235 * max(0, t - 0.35) / 0.65))
    return Image.composite(Image.new("RGB", im.size, (8, 6, 10)), im, g)


def text(d, xy, s, size, fill, anchor="la"):
    d.text(xy, s, font=f(size), fill=fill, stroke_width=max(6, size // 12), stroke_fill=(0, 0, 0), anchor=anchor)


def logo(d, x, y, size=118, anchor="la"):
    text(d, (x, y), "DEAD QUOTA", size, (225, 30, 36), anchor)


def kapak_a():  # Bruno levye aksiyonu
    im = shade(base("m05.png"), "left")
    d = ImageDraw.Draw(im)
    text(d, (40, 70), "EX-SANTA", 92, (255, 255, 255))
    text(d, (40, 170), "VS.", 92, (255, 214, 40))
    text(d, (40, 270), "THE DEAD", 92, (255, 255, 255))
    logo(d, 40, 560, 104)
    im.save(O + "kapak_A.jpg", quality=92)


def kapak_b():  # Moss + balta, kota
    im = shade(base("m06.png"), "right")
    d = ImageDraw.Draw(im)
    text(d, (1240, 60), "QUOTA:", 96, (255, 255, 255), "ra")
    text(d, (1240, 165), "180 HEADS", 110, (255, 214, 40), "ra")
    text(d, (1240, 290), "OR ELSE", 96, (255, 255, 255), "ra")
    logo(d, 1240, 560, 104, "ra")
    im.save(O + "kapak_B.jpg", quality=92)


def kapak_c():  # Adler gülümsemesi, kurumsal kötülük
    im = shade(base("v02.png"), "left")
    d = ImageDraw.Draw(im)
    text(d, (40, 80), "\"EVACUATION IS", 70, (255, 255, 255))
    text(d, (40, 165), "A SEPARATE", 70, (255, 255, 255))
    text(d, (40, 250), "CONTRACT\"", 70, (225, 30, 36))
    text(d, (40, 370), "Great energy, team!", 48, (255, 214, 40))
    logo(d, 40, 560, 104)
    im.save(O + "kapak_C.jpg", quality=92)


if __name__ == "__main__":
    os.makedirs(O, exist_ok=True)
    kapak_a(); kapak_b(); kapak_c()
    print("✔ kapaklar")
