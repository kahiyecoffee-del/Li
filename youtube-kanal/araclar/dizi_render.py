#!/usr/bin/env python3
"""DEAD QUOTA bölüm montajı: AI kareleri + karakter sesleri + telsiz efekti + SFX + müzik + kamera hareketi + altyazı.

Kullanım:
    python araclar/dizi_render.py senaryolar/dizi_pilot.json [--only c01,c02] [--out cikti/dizi/pilot/bolum.mp4]

Kareler: cikti/dizi/pilot/kareler/<id>.png (yoksa yer tutucu çizilir).
"""
import argparse
import json
import math
import os
import re
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_DIR = os.environ.get("KOKORO_DIR", "/home/user/models")
SR = 24000
FPS = 24
W, H = 1920, 1080
KARE = os.path.join(ROOT, "cikti", "dizi", "pilot", "kareler")
FONT = os.path.join(ROOT, "fonts", "Merriweather.ttf")

# ------------------------------------------------------------------ ses
_k = None


def tts(text, voice, speed=1.0):
    global _k
    if _k is None:
        from kokoro_onnx import Kokoro
        _k = Kokoro(os.path.join(MODEL_DIR, "kokoro-v1.0.onnx"), os.path.join(MODEL_DIR, "voices-v1.0.bin"))
    parts = [p.strip() for p in re.split(r"(?<=[.!?])\s+", text) if p.strip()]
    out = []
    for i, part in enumerate(parts):
        s, sr = _k.create(part, voice=voice, speed=speed, lang="en-us" if voice[0] == "a" else "en-gb")
        a = np.asarray(s, dtype=np.float32)
        nz = np.nonzero(np.abs(a) > 0.01)[0]
        if len(nz):
            a = a[max(0, nz[0] - 600):nz[-1] + 1500]
        out.append(a)
        if i < len(parts) - 1:
            out.append(np.zeros(int((0.55 if part.endswith("...") else 0.28) * SR), np.float32))
    return np.concatenate(out) if out else np.zeros(1, np.float32)


def bandpass(x, lo, hi):
    n = len(x)
    sp = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1 / SR)
    sp[(f < lo) | (f > hi)] = 0
    return np.fft.irfft(sp, n).astype(np.float32)


def radio(x):
    y = bandpass(x, 350, 3200)
    y = np.tanh(y * 3.0) / 3.0 * 1.6
    rng = np.random.default_rng(1)
    return (y + rng.standard_normal(len(y)).astype(np.float32) * 0.006).astype(np.float32)


def t_(d):
    return np.arange(int(d * SR)) / SR


def env(n, a, r):
    e = np.ones(n, np.float32)
    a, r = max(1, int(a * SR)), max(1, int(r * SR))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def noise(d, lo, hi, seed=0):
    rng = np.random.default_rng(seed)
    x = rng.standard_normal(int(d * SR)).astype(np.float32)
    y = bandpass(x, lo, hi)
    return y / (np.max(np.abs(y)) + 1e-9)


def sfx(name, dur):
    if name == "mower":
        t = t_(dur)
        x = np.sign(np.sin(2 * np.pi * 48 * t)) * 0.25 + noise(dur, 80, 900, 2) * 0.5
        return (x * env(len(t), 0.3, 0.5) * 0.18).astype(np.float32)
    if name == "growl":
        d = 1.6
        t = t_(d)
        x = noise(d, 60, 500, 5) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * t))
        return (x * env(len(t), 0.2, 0.5) * 0.35).astype(np.float32)
    if name == "axe":
        d = 0.7
        t = t_(d)
        w = noise(0.3, 400, 5000, 3) * env(int(0.3 * SR), 0.15, 0.1)
        thud = np.sin(2 * np.pi * 70 * t) * np.exp(-t * 18) + noise(d, 100, 1800, 4) * np.exp(-t * 25) * 0.6
        out = np.zeros(len(t), np.float32)
        out[:len(w)] += w * 0.4
        out[int(0.25 * SR):] += thud[:len(out) - int(0.25 * SR)] * 0.9
        return out
    if name in ("hit", "thud"):
        d = 0.5
        t = t_(d)
        return ((np.sin(2 * np.pi * 60 * t) * np.exp(-t * 14) + noise(d, 80, 1200, 6) * np.exp(-t * 30) * 0.5) * (0.8 if name == "hit" else 0.5)).astype(np.float32)
    if name == "crack":
        d = 0.35
        t = t_(d)
        return (noise(d, 2000, 9000, 7) * np.exp(-t * 20) * 0.6).astype(np.float32)
    if name == "radio":
        d = 0.25
        t = t_(d)
        return (noise(d, 800, 6000, 8) * np.exp(-t * 10) * 0.25).astype(np.float32)
    if name == "click":
        d = 0.08
        t = t_(d)
        return (noise(d, 1000, 6000, 9) * np.exp(-t * 80) * 0.6).astype(np.float32)
    if name == "ping":
        d = 0.5
        t = t_(d)
        return (np.sin(2 * np.pi * 1320 * t) * np.exp(-t * 9) * 0.25).astype(np.float32)
    if name == "door":
        d = 0.6
        t = t_(d)
        return ((np.sin(2 * np.pi * 90 * t) * np.exp(-t * 10) + noise(d, 200, 2500, 10) * np.exp(-t * 15) * 0.5) * 0.7).astype(np.float32)
    if name in ("sting", "drone"):
        d = 3.0
        t = t_(d)
        x = np.sin(2 * np.pi * 41 * t) + 0.5 * np.sin(2 * np.pi * 61.5 * t) + 0.3 * noise(d, 40, 300, 11)
        return (x * env(len(t), 0.02 if name == "sting" else 1.0, 1.5) * (0.5 if name == "sting" else 0.25)).astype(np.float32)
    if name == "lullaby":  # Bruno'nun mırıldandığı ninni (yumuşak hum)
        notes = [64, 67, 69, 67, 64, 62, 64, 60]
        out = []
        for m in notes:
            d = 0.55
            t = t_(d)
            f = 440 * 2 ** ((m - 69) / 12) / 2
            out.append((np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)) * env(len(t), 0.08, 0.2) * 0.12)
        return np.concatenate(out).astype(np.float32)
    if name == "jingle":
        out = []
        for m in (72, 76, 79, 84):
            d = 0.28
            t = t_(d)
            f = 440 * 2 ** ((m - 69) / 12)
            out.append(np.sin(2 * np.pi * f * t) * env(len(t), 0.01, 0.15) * 0.2)
        return np.concatenate(out).astype(np.float32)
    return np.zeros(1, np.float32)


def music_bed(total):
    """Karanlık synth zemin: alçak pad + yavaş nabız."""
    t = t_(total)
    root = 55.0
    pad = np.zeros(len(t), np.float32)
    for k, ratio in enumerate((1, 1.5, 2, 2.4)):
        pad += np.sin(2 * np.pi * root * ratio * t + k) * (0.5 / (k + 1))
    lfo = 0.6 + 0.4 * np.sin(2 * np.pi * 0.07 * t)
    pulse = (np.sin(2 * np.pi * 1.0 * t) > 0.97).astype(np.float32)
    pulse = np.convolve(pulse, np.exp(-np.arange(int(0.25 * SR)) / (0.05 * SR)), mode="same")[:len(t)]
    kick = pulse * np.sin(2 * np.pi * 50 * t)
    return ((pad * lfo * 0.12 + kick * 0.08)).astype(np.float32)


def place(buf, clip, at, g=1.0):
    a = int(at * SR)
    if a >= len(buf):
        return
    n = min(len(clip), len(buf) - a)
    buf[a:a + n] += clip[:n] * g


# ------------------------------------------------------------------ görüntü
def load_frame(sid):
    p = os.path.join(KARE, sid + ".png")
    if os.path.exists(p):
        im = Image.open(p).convert("RGB")
    else:
        im = Image.new("RGB", (1344, 768), (24, 22, 28))
        d = ImageDraw.Draw(im)
        d.text((672, 384), f"[{sid}]", font=ImageFont.truetype(FONT, 48), fill=(160, 160, 170), anchor="mm")
    # 16:9'a kırp, 1.15x büyüt (kamera hareketi payı)
    tw, th = int(W * 1.15), int(H * 1.15)
    r = max(tw / im.width, th / im.height)
    im = im.resize((int(im.width * r) + 1, int(im.height * r) + 1), Image.LANCZOS)
    x0, y0 = (im.width - tw) // 2, (im.height - th) // 2
    return im.crop((x0, y0, x0 + tw, y0 + th))


def cam_box(cam, u, iw, ih, frame_i):
    """u: 0..1 çekim ilerlemesi -> kırpma kutusu (W/H oranında)."""
    e = u * u * (3 - 2 * u)
    base_w, base_h = W, H
    if cam == "zoom_in":
        s = 1.0 - 0.10 * e
    elif cam == "zoom_out":
        s = 0.90 + 0.10 * e
    else:
        s = 0.96
    cw, ch = base_w * s * (iw / (W * 1.15)) * 1.15 / 1.15, base_h * s * (ih / (H * 1.15)) * 1.15 / 1.15
    cx, cy = iw / 2, ih / 2
    if cam == "pan_right":
        cx = iw / 2 - (iw - cw) * 0.45 + (iw - cw) * 0.9 * e
    elif cam == "pan_left":
        cx = iw / 2 + (iw - cw) * 0.45 - (iw - cw) * 0.9 * e
    elif cam == "tilt_up":
        cy = ih / 2 + (ih - ch) * 0.45 - (ih - ch) * 0.9 * e
    if cam == "shake":
        cx += math.sin(frame_i * 2.7) * 9 * (1 - e * 0.5)
        cy += math.cos(frame_i * 3.3) * 7 * (1 - e * 0.5)
    x0 = max(0, min(iw - cw, cx - cw / 2))
    y0 = max(0, min(ih - ch, cy - ch / 2))
    return (x0, y0, x0 + cw, y0 + ch)


def draw_sub(img, text):
    if not text:
        return img
    d = ImageDraw.Draw(img, "RGBA")
    f = ImageFont.truetype(FONT, 44)
    words, lines, cur = text.split(), [], ""
    for w_ in words:
        test = (cur + " " + w_).strip()
        if d.textlength(test, font=f) > 1400 and cur:
            lines.append(cur)
            cur = w_
        else:
            cur = test
    lines.append(cur)
    y = H - 70 - (len(lines) - 1) * 56
    for ln in lines:
        tw = d.textlength(ln, font=f)
        d.rectangle([W / 2 - tw / 2 - 18, y - 32, W / 2 + tw / 2 + 18, y + 26], fill=(0, 0, 0, 170))
        d.text((W / 2, y), ln, font=f, fill=(255, 255, 255), anchor="mm")
        y += 56
    return img


def ts(sec):
    h, r = divmod(sec, 3600)
    m, s = divmod(r, 60)
    return f"{int(h):02d}:{int(m):02d}:{int(s):02d},{int((s - int(s)) * 1000):03d}"


# ------------------------------------------------------------------ ana
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("plan")
    ap.add_argument("--only")
    ap.add_argument("--out")
    a = ap.parse_args()
    plan = json.load(open(a.plan, encoding="utf-8"))
    shots = plan["shots"]
    if a.only:
        keep = set(a.only.split(","))
        shots = [s for s in shots if s["id"] in keep]
    voices = plan["voices"]
    out = a.out or os.path.join(ROOT, "cikti", "dizi", "pilot", plan["slug"] + ".mp4")
    os.makedirs(os.path.dirname(out), exist_ok=True)

    # 1) sesler ve zamanlama
    timeline, t, subs = [], 0.0, []
    prev_sec = None
    for s in shots:
        sec = s["id"][0]
        gap_before = 0.35 if prev_sec and sec != prev_sec else 0.0  # sahne geçişinde siyah nefes
        t += gap_before
        prev_sec = sec
        clips, cur = [], 0.45
        for ln in s["lines"]:
            v = tts(ln["en"], voices[ln["who"]], 1.0)
            if ln["who"] == "adler" and s.get("sfx") == "radio":
                v = radio(v)
            clips.append((cur, v, ln))
            cur += len(v) / SR + 0.32
        dur = max(s.get("min_dur", 3.0), cur + 0.35)
        timeline.append((t, dur, s, clips))
        for at, v, ln in clips:
            subs.append((t + at, t + at + len(v) / SR, ln["en"], ln["tr"]))
        t += dur
        print(f"  ses: {s['id']} {dur:.1f} sn", flush=True)
    total = t + 1.0

    voice = np.zeros(int(total * SR) + SR, np.float32)
    fx = np.zeros_like(voice)
    for st, dur, s, clips in timeline:
        for at, v, ln in clips:
            place(voice, v, st + at)
        if s.get("sfx"):
            name = s["sfx"]
            clip = sfx(name, dur)
            g = 0.9
            at = st + (0.25 if name in ("axe", "hit", "thud", "crack") and not s["lines"] else (0.0 if name not in ("axe",) else max(0.0, dur - 1.0)))
            place(fx, clip, at, g)
    bed = music_bed(len(voice) / SR)[:len(voice)]
    # ducking
    win = int(0.25 * SR)
    lvl = np.sqrt(np.convolve(voice ** 2, np.ones(win) / win, mode="same"))
    duck = 1.0 - 0.6 * np.clip(lvl / 0.05, 0, 1)
    mix = voice * 1.0 + fx * 0.8 + bed * duck
    mix = mix / (np.max(np.abs(mix)) + 1e-9) * 0.9
    wav = out.replace(".mp4", ".wav")
    import wave
    with wave.open(wav, "wb") as w_:
        w_.setnchannels(1)
        w_.setsampwidth(2)
        w_.setframerate(SR)
        w_.writeframes((mix * 32767).astype(np.int16).tobytes())

    # altyazı dosyaları
    for lang, idx in (("en", 2), ("tr", 3)):
        with open(out.replace(".mp4", f".{lang}.srt"), "w", encoding="utf-8") as f:
            for i, sub in enumerate(subs, 1):
                f.write(f"{i}\n{ts(sub[0])} --> {ts(sub[1])}\n{sub[idx]}\n\n")

    # 2) görüntü
    n_total = int(total * FPS)
    proc = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                             "-i", wav, "-c:v", "libx264", "-preset", "medium", "-crf", "19", "-pix_fmt", "yuv420p",
                             "-c:a", "aac", "-b:a", "192k", "-af", "loudnorm=I=-14:TP=-1.5:LRA=11", "-shortest", out], stdin=subprocess.PIPE)
    black = Image.new("RGB", (W, H), (0, 0, 0)).tobytes()
    fi = 0
    for st, dur, s, clips in timeline:
        while fi < int(st * FPS):
            proc.stdin.write(black)
            fi += 1
        im = load_frame(s["id"])
        nf = int((st + dur) * FPS) - fi
        for k in range(nf):
            u = k / max(1, nf - 1)
            box = cam_box(s["cam"], u, im.width, im.height, fi)
            fr = im.crop(tuple(int(v) for v in box)).resize((W, H), Image.BILINEAR)
            now = fi / FPS
            txt = next((sb[2] for sb in subs if sb[0] <= now <= sb[1]), "")
            proc.stdin.write(draw_sub(fr, txt).tobytes())
            fi += 1
    while fi < n_total:
        proc.stdin.write(black)
        fi += 1
    proc.stdin.close()
    proc.wait()
    print(f"✔ {out} ({total:.1f} sn)")


if __name__ == "__main__":
    main()
