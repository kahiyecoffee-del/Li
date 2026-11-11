#!/usr/bin/env python3
"""Uzun videonun senaryosundan Shorts üretir (9:16).

Her Short: uzun senaryodan bir sahne aralığı + sonda "tam video kanalda" sahnesi.
Sahneler yatay (16:9) çizilir, sonra dikey kareye yerleştirilir:
üstte el yazısı kanca başlığı, ortada çizim, altında büyük altyazı.

Kullanım:
    python3 araclar/shorts.py senaryolar/solipsizm.json senaryolar/solipsizm_shorts.json
"""
import json
import os
import subprocess
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import karakalem as kk  # noqa: E402
import eskiz  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 1080, 1920
CROP_W = 1560          # yatay kareden ortadaki bu genişlik alınır
VID_H = int(1080 * W / CROP_W)
VID_Y = 470


def background(title, cta, path):
    img = Image.fromarray(kk.paper(W, H, seed=9).astype("uint8"))
    d = ImageDraw.Draw(img, "RGBA")
    lines = title.split("\n")
    y = 150
    for ln in lines:
        size = 92
        f = eskiz.hand_font(size)
        while d.textlength(ln, font=f) > W - 120 and size > 50:
            size -= 4
            f = eskiz.hand_font(size)
        d.text((W / 2, y), ln, font=f, fill=(40, 38, 42), anchor="mm")
        y += size * 1.15
    tw = d.textlength(lines[-1], font=f)
    eskiz.Stroke([(W / 2 - tw / 2, y - size * 0.45), (W / 2, y - size * 0.38), (W / 2 + tw / 2, y - size * 0.47)], 5,
                 eskiz.RED, seed=3).draw(img)
    # çizim alanı çerçevesi
    d.rectangle([24, VID_Y - 12, W - 24, VID_Y + VID_H + 12], outline=(60, 58, 62, 200), width=4)
    f2 = eskiz.hand_font(40)
    d.text((W / 2, H - 120), cta, font=f2, fill=(150, 45, 35), anchor="mm")
    img.save(path)


def main():
    base = json.load(open(sys.argv[1], encoding="utf-8"))
    defs = json.load(open(sys.argv[2], encoding="utf-8"))
    outdir = os.path.join(ROOT, "cikti", base["slug"] + "-shorts")
    tmpdir = os.path.join(outdir, "_tmp")
    os.makedirs(tmpdir, exist_ok=True)
    for k, sd in enumerate(defs["shorts"], 1):
        slug = f"{base['slug']}-short{k}"
        scenes = base["scenes"][sd["from"]:sd["to"] + 1] + [defs["cta_scene"]]
        sc = dict(base, slug=slug, scenes=scenes, burn_captions=False, srt_chars=22, subtitles=[])
        sc.pop("subscribe", None)
        sc.pop("loop", None)
        spath = os.path.join(tmpdir, slug + ".json")
        json.dump(sc, open(spath, "w", encoding="utf-8"), ensure_ascii=False)
        print(f"[{k}] {sd['title']!r}: sahne {sd['from']}–{sd['to']}", flush=True)
        subprocess.run([sys.executable, os.path.join(ROOT, "araclar", "video_uret.py"), spath, "--cikti", tmpdir], check=True,
                       env=dict(os.environ))
        src = os.path.join(tmpdir, slug, f"{slug}_long_en.mp4")
        srt = os.path.join(tmpdir, slug, f"{slug}_long_en.srt")
        bg = os.path.join(tmpdir, slug + "_bg.png")
        background(sd["title"], defs.get("cta", "full video on the channel"), bg)
        fontdir = os.path.join(ROOT, "fonts")
        style = ("FontName=Kalam,Bold=1,FontSize=15,PrimaryColour=&H002A2628,OutlineColour=&H00DCE8EE,BorderStyle=3,"
                 "Outline=6,Shadow=0,Alignment=2,MarginV=75")
        out = os.path.join(outdir, f"{slug}.mp4")
        vf = (f"[1:v]crop={CROP_W}:1080:(iw-{CROP_W})/2:0,scale={W}:{VID_H}[v];"
              f"[0:v][v]overlay=0:{VID_Y}[c];"
              f"[c]subtitles='{srt}':fontsdir='{fontdir}':original_size={W}x{H}:force_style='{style}'[o]")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-loop", "1", "-i", bg, "-i", src, "-filter_complex", vf,
                        "-map", "[o]", "-map", "1:a", "-c:v", "libx264", "-preset", "medium", "-crf", "21", "-pix_fmt", "yuv420p",
                        "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", out], check=True)
        print(f"✔ {out}", flush=True)


if __name__ == "__main__":
    main()
