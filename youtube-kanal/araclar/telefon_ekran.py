#!/usr/bin/env python3
"""DEAD QUOTA: canlı yayın telefon ekranı kareleri (e02, n02).

SDXL ekran içi yazıyı üretemediği için arka planı AI karesinden alır (bulanıklaştırır),
üstüne kalın konturlu çizgi roman tarzı bir telefon + yayın arayüzü çizer.
"""
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

K = "cikti/dizi/pilot/kareler/"
F = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def font(s):
    try:
        return ImageFont.truetype(F, s)
    except OSError:
        return ImageFont.load_default()


def ekran(base, out, views, chat, tilt=-6, tint=(255, 60, 60)):
    bg = Image.open(base).convert("RGB").resize((1344, 768)).filter(ImageFilter.GaussianBlur(9))
    bg = Image.blend(bg, Image.new("RGB", bg.size, (10, 8, 16)), 0.35)
    pw, ph = 470, 860
    ph_img = Image.new("RGBA", (pw + 40, ph + 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(ph_img)
    d.rounded_rectangle((20, 20, 20 + pw, 20 + ph), 58, fill=(18, 18, 22), outline=(0, 0, 0), width=10)
    sx0, sy0, sx1, sy1 = 46, 70, pw - 6, ph - 10
    d.rounded_rectangle((sx0, sy0, sx1, sy1), 34, fill=(24, 20, 34))
    # yayın görüntüsü (üst bölge): kırmızı acil durum ışığında silüetler
    vid = Image.new("RGB", (sx1 - sx0, 330), (60, 14, 18))
    vd = ImageDraw.Draw(vid)
    for i, x in enumerate(range(20, sx1 - sx0, 70)):
        h = 140 + (i * 37) % 70
        vd.ellipse((x, 330 - h - 40, x + 44, 330 - h + 4), fill=(20, 8, 10))
        vd.rectangle((x - 6, 330 - h, x + 50, 330), fill=(20, 8, 10))
    vd.rectangle((0, 0, vid.width, 330), outline=(0, 0, 0), width=6)
    ph_img.paste(vid, (sx0, sy0 + 20))
    d.rounded_rectangle((sx0 + 16, sy0 + 36, sx0 + 106, sy0 + 76), 10, fill=(225, 30, 40), outline=(0, 0, 0), width=4)
    d.text((sx0 + 28, sy0 + 42), "LIVE", font=font(26), fill="white")
    d.text((sx0 + 120, sy0 + 44), views, font=font(26), fill="white", stroke_width=3, stroke_fill="black")
    y = sy0 + 380
    cols = [(255, 214, 64), (120, 230, 255), (255, 120, 200), (150, 255, 140)]
    for i, (u, m) in enumerate(chat):
        d.text((sx0 + 20, y), u, font=font(22), fill=cols[i % 4], stroke_width=2, stroke_fill="black")
        d.text((sx0 + 20, y + 28), m, font=font(28), fill="white", stroke_width=3, stroke_fill="black")
        y += 76
    # çatlaklar
    for a, b in (((300, 120), (420, 260)), ((300, 120), (210, 330)), ((300, 120), (470, 90)), ((420, 260), (480, 420))):
        d.line((a, b), fill=(235, 235, 245), width=3)
    ph_img = ph_img.rotate(tilt, expand=True, resample=Image.BICUBIC)
    bg.paste(ph_img, ((1344 - ph_img.width) // 2, (768 - ph_img.height) // 2 + 110), ph_img)
    vg = Image.new("L", bg.size, 0)
    ImageDraw.Draw(vg).ellipse((-300, -250, 1644, 1018), fill=255)
    bg = Image.composite(bg, Image.new("RGB", bg.size, (0, 0, 0)), vg.filter(ImageFilter.GaussianBlur(120)))
    bg.save(out)
    print("✔", out)


if __name__ == "__main__":
    ekran(K + "e01.png", K + "e02.png", "48.3K watching",
          [("@grimfan", "IS THIS REAL"), ("@ok_boomer", "HALCYON LEFT THEM"), ("@vibes", "RUN JESSIE RUN")])
    ekran(K + "n01.png", K + "n02.png", "1.2M views",
          [("@leakhunter", "1.2M VIEWS LETS GO"), ("@m0ss_fan", "HALCYON LIED"), ("@sadsanta", "justice for bruno")], tilt=5)
