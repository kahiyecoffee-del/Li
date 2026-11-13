#!/usr/bin/env python3
"""THE BUDGETS Shorts: bölüm senaryosundan dikey (1080x1920) klipler.

Kullanım: python3 araclar/cizgi/shorts.py senaryolar/budgets/b01.txt senaryolar/budgets/b01_shorts.json [--only 1,3]
Her klip: üstte kanca başlığı, ortada büyütülmüş sahne (4:3 kırpım), altta büyük altyazı,
sonda abone ol çağrısı (Dale'in sesiyle). Ses: bölüm miksajından ilgili aralık + CTA.
"""
import argparse
import json
import math
import os
import subprocess
import sys
import wave

import cairo
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor  # noqa: E402
from karakter import INK, rgb  # noqa: E402
from motor import FPS, SR  # noqa: E402

VW, VH = 1080, 1920
CTA_EN = "Full episode is on the channel. Subscribe, or Homi fires you."
CTA_DUR = 4.2
SHOW = "THE BUDGETS"
CTA = {"budgets": ("dale", "Full episode is on the channel. Subscribe, or Homi fires you."),
       "comedown": ("tuna", "Full episode is on the channel. Subscribe. It is cheaper than therapy.")}


def wrap(ctx, text, maxw):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if ctx.text_extents(t).width > maxw and cur:
            lines.append(cur)
            cur = w
        else:
            cur = t
    lines.append(cur)
    return lines


def outlined(ctx, text, x, y, size, fill, lw=12, center=True):
    ctx.set_font_size(size)
    ext = ctx.text_extents(text)
    if center:
        x = x - ext.width / 2 - ext.x_bearing
    ctx.move_to(x, y)
    ctx.text_path(text)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(lw)
    ctx.set_line_join(cairo.LINE_JOIN_ROUND)
    ctx.stroke_preserve()
    ctx.set_source_rgb(*fill)
    ctx.fill()


def frame_bg(ctx):
    g = cairo.LinearGradient(0, 0, 0, VH)
    g.add_color_stop_rgb(0, *rgb("#2b1d4a"))
    g.add_color_stop_rgb(1, *rgb("#0f0b1c"))
    ctx.set_source(g)
    ctx.paint()


def header(ctx, hook):
    ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.save()
    ctx.translate(VW / 2, 150)
    ctx.rotate(-0.03)
    ctx.rectangle(-300, -62, 600, 84)
    ctx.set_source_rgb(*rgb("#d9342b"))
    ctx.fill_preserve()
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(6)
    ctx.stroke()
    outlined(ctx, SHOW, 0, 0, 60, rgb("#fff3c4"), 0)
    ctx.restore()
    ctx.set_font_size(78)
    lines = wrap(ctx, hook, VW - 120)
    for i, ln in enumerate(lines[:2]):
        outlined(ctx, ln, VW / 2, 330 + i * 92, 78, rgb("#ffe14d") if i else (1, 1, 1), 14)


def sub(ctx, text):
    ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(62)
    lines = wrap(ctx, text, VW - 140)
    for i, ln in enumerate(lines[:4]):
        outlined(ctx, ln, VW / 2, 1420 + i * 78, 62, (1, 1, 1), 12)


def cta(ctx, u):
    frame_bg(ctx)
    ctx.select_font_face("Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    outlined(ctx, "FULL EPISODE", VW / 2, 640, 96, (1, 1, 1), 16)
    outlined(ctx, "ON THE CHANNEL", VW / 2, 750, 96, rgb("#ffe14d"), 16)
    s = 1.0 + 0.06 * math.sin(u * 14) * (u < 0.8)
    press = 0.92 if 0.55 < u < 0.7 else 1.0
    ctx.save()
    ctx.translate(VW / 2, 1020)
    ctx.scale(s * press, s * press)
    motor_rr(ctx, -300, -80, 600, 160, 40)
    ctx.set_source_rgb(*(rgb("#d9342b") if u < 0.62 else (0.45, 0.45, 0.48)))
    ctx.fill_preserve()
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(8)
    ctx.stroke()
    outlined(ctx, "SUBSCRIBE" if u < 0.62 else "SUBSCRIBED", 0, 26, 72, (1, 1, 1), 0)
    ctx.restore()
    if u > 0.3:  # el imleci
        k = min(1, (u - 0.3) / 0.25)
        x, y = VW / 2 + 400 - 170 * k, 1260 - 170 * k
        ctx.save()
        ctx.translate(x, y)
        motor_rr(ctx, -30, -10, 60, 90, 20)
        ctx.set_source_rgb(*rgb("#f2c49b"))
        ctx.fill_preserve()
        ctx.set_source_rgb(*INK)
        ctx.set_line_width(6)
        ctx.stroke()
        motor_rr(ctx, -12, -70, 24, 70, 12)
        ctx.set_source_rgb(*rgb("#f2c49b"))
        ctx.fill_preserve()
        ctx.set_source_rgb(*INK)
        ctx.stroke()
        ctx.restore()
    outlined(ctx, "New episode every day", VW / 2, 1330, 54, (1, 1, 1), 10)


def motor_rr(ctx, x, y, w, h, r):
    from karakter import rrect
    rrect(ctx, x, y, w, h, r)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("script")
    ap.add_argument("shorts")
    ap.add_argument("--only")
    a = ap.parse_args()
    slug = os.path.splitext(os.path.basename(a.script))[0]
    series = motor.series_of(a.script)
    global SHOW
    SHOW = motor.SHOWS.get(series, "THE BUDGETS")
    outdir = f"cikti/{series}/{slug}/shorts"
    os.makedirs(outdir, exist_ok=True)
    segs, audio, total = motor.build(motor.parse(a.script))
    prev = {}
    for s in segs:
        if s["kind"] == "shot":
            s["prev_pose"] = prev
            prev = s["pose"]
    total += 0.8
    mix = np.zeros(int(total * SR) + SR, np.float32)
    for at, x, vol in audio:
        i = int(at * SR)
        x = x[:len(mix) - i]
        mix[i:i + len(x)] += x * vol
    envs = {id(s): motor.envelope(s["audio"]) for s in segs if "audio" in s}
    lines = [s for s in segs if s.get("en")]
    cw, ctext = CTA.get(series, CTA["budgets"])
    cta_v = motor.line_audio(cw, "happy", ctext)
    clips = json.load(open(a.shorts, encoding="utf-8"))
    only = {int(x) for x in a.only.split(",")} if a.only else None
    for ci, c in enumerate(clips, 1):
        if only and ci not in only:
            continue
        s0, s1 = lines[c["from"] - 1], lines[c["to"] - 1]
        t0 = s0["t0"]
        i1 = segs.index(s1)
        t1 = s1["t1"]
        if i1 + 1 < len(segs) and segs[i1 + 1].get("react"):
            t1 = segs[i1 + 1]["t1"]
        dur = t1 - t0
        out = f"{outdir}/{slug}_short{ci:02d}"
        clip = mix[int(t0 * SR):int(t1 * SR)].copy()
        fade = int(0.08 * SR)
        clip[:fade] *= np.linspace(0, 1, fade)
        tail = np.zeros(int(CTA_DUR * SR), np.float32)
        tail[int(0.3 * SR):int(0.3 * SR) + len(cta_v)] += cta_v[:len(tail) - int(0.3 * SR)]
        pi = int(0.3 * SR + 0.62 * (CTA_DUR - 0.3) * SR * 0.9)
        pg = motor.sfx("ping")
        tail[pi:pi + len(pg)] += pg[:len(tail) - pi] * 0.7
        aud = np.concatenate([clip, tail])
        with wave.open(out + ".wav", "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((np.clip(aud / max(1e-6, np.max(np.abs(aud))) * 0.9, -1, 1) * 32767).astype(np.int16).tobytes())
        ff = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "bgra", "-s", f"{VW}x{VH}",
                               "-r", str(FPS), "-i", "-", "-i", out + ".wav", "-c:v", "libx264", "-preset", "medium",
                               "-crf", "20", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k",
                               "-af", "loudnorm=I=-14:TP=-1.5:LRA=11", "-shortest", "-movflags", "+faststart",
                               out + ".mp4"], stdin=subprocess.PIPE)
        big = cairo.ImageSurface(cairo.FORMAT_ARGB32, motor.W, motor.H)
        bctx = cairo.Context(big)
        vs = cairo.ImageSurface(cairo.FORMAT_ARGB32, VW, VH)
        vctx = cairo.Context(vs)
        blink = motor.Blinker()
        n_main = int(dur * FPS)
        n_cta = int(CTA_DUR * FPS)
        si = 0
        for f in range(n_main + n_cta):
            if f < n_main:
                t = t0 + f / FPS
                while si < len(segs) - 1 and t >= segs[si]["t1"]:
                    si += 1
                seg = segs[si]
                bctx.set_source_rgb(0, 0, 0)
                bctx.paint()
                motor.render_frame(bctx, seg, t, blink, envs, subs=False)
                big.flush()
                frame_bg(vctx)
                # 4:3 kırpım (1440x1080) -> 1080x810, y=520
                vctx.save()
                vctx.rectangle(0, 520, VW, 810)
                vctx.clip()
                vctx.translate(0, 520)
                vctx.scale(VW / 1440, 810 / 1080)
                vctx.set_source_surface(big, -240, 0)
                vctx.paint()
                vctx.restore()
                vctx.rectangle(0, 520, VW, 810)
                vctx.set_source_rgb(*INK)
                vctx.set_line_width(10)
                vctx.stroke()
                header(vctx, c["hook"])
                if seg.get("en") and t >= seg["a0"] - 0.1:
                    sub(vctx, seg["en"])
                # ilerleme çubuğu
                vctx.rectangle(0, VH - 14, VW * f / n_main, 14)
                vctx.set_source_rgb(*rgb("#ffe14d"))
                vctx.fill()
            else:
                cta(vctx, (f - n_main) / n_cta)
            vs.flush()
            ff.stdin.write(bytes(vs.get_data()))
        ff.stdin.close()
        ff.wait()
        os.remove(out + ".wav")
        print(f"✔ {out}.mp4 ({dur + CTA_DUR:.1f} sn)", flush=True)


if __name__ == "__main__":
    main()
