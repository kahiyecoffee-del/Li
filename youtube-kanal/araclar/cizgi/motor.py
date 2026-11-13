#!/usr/bin/env python3
"""THE BUDGETS bölüm motoru: senaryo (.txt) -> tam animasyonlu mp4 + EN/TR srt.

Kullanım:
    python araclar/cizgi/motor.py senaryolar/budgets/b01.txt [--out cikti/budgets/b01] [--limit 20]

24 kare/sn; her karede karakterler yeniden çizilir (dudak senkronu, göz kırpma, nefes, jest geçişi, yürüme),
kamera planları (geniş / yakın / ikili) yavaş itme hareketiyle, sahne geçişlerinde müzik vurgusu.
"""
import argparse
import math
import os
import random
import re
import subprocess
import sys

import cairo
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from karakter import INK, POSES, blend_pose, make, rgb  # noqa: E402
from mekan import COUNTER_Y, GROUND, H, W, Prop, background, snowfall  # noqa: E402

FPS = 24
SR = 24000
MODEL_DIR = os.environ.get("KOKORO_DIR", "/home/user/models")
VOICES = {"dale": "am_michael", "tammy": "af_bella", "kyle": "am_puck", "earl": "bm_lewis", "homi": "af_nova",
          "officer": "am_eric", "gary": "bm_daniel", "mayor": "af_sarah", "jace": "am_liam",
          "mikey": "am_echo", "tuna": "am_adam", "gus": "am_onyx", "pam": "af_kore", "linda": "af_jessica"}
SPEED = {"homi": 0.97, "earl": 0.92, "kyle": 1.02}
EMOS = {"neutral", "happy", "angry", "sad", "shock", "smug"}
PROPS = {"jukebox", "toaster", "toaster2"}
CUT_CAPTION = {"chapel": "1968", "snow": "DULUTH, 1971"}  # bölüm içinde @caption ile değiştirilebilir
SCALE = 0.95

# ---------------------------------------------------------------- senaryo


def parse(path):
    ev = []
    for raw in open(path, encoding="utf-8"):
        ln = raw.strip()
        if not ln or ln.startswith("#"):
            continue
        if ln.startswith("@"):
            cmd, _, rest = ln[1:].partition(" ")
            if cmd in ("scene", "cutaway"):
                bg, _, cast = rest.partition("|")
                pos = {}
                for tok in cast.split():
                    p = tok.split(":")
                    pos[p[0]] = [float(p[1]), int(p[2]) if len(p) > 2 else 1]
                ev.append(dict(t=cmd, bg=bg.strip(), cast=pos))
            elif cmd == "shot":
                ev.append(dict(t="shot", v=rest.split()))
            elif cmd == "walk":
                n, x = rest.split()
                ev.append(dict(t="walk", who=n, x=float(x)))
            elif cmd == "beat":
                ev.append(dict(t="beat", d=float(rest)))
            elif cmd == "sfx":
                ev.append(dict(t="sfx", n=rest.strip()))
            elif cmd == "caption":
                ev.append(dict(t="caption", text=rest.strip()))
            elif cmd == "title":
                ev.append(dict(t="title", text=rest.strip()))
            continue
        m = re.match(r"([A-Z]+)\s*(?:\[([^\]]*)\])?\s*:\s*(.+?)\s*\|\|\s*(.+)$", ln)
        if not m:
            raise SystemExit(f"anlaşılamadı: {ln}")
        who = m.group(1).lower()
        tags = [x.strip() for x in (m.group(2) or "").split(",") if x.strip()]
        emo = next((x for x in tags if x in EMOS), "neutral")
        pose = next((x for x in tags if x in POSES), None)
        ev.append(dict(t="line", who=who, emo=emo, pose=pose, en=m.group(3), tr=m.group(4)))
    return ev


# ---------------------------------------------------------------- ses
_k = None


KOKORO_ONLY = {"homi"}  # robot sesi Kokoro'da kalır


def cb_key(who, emo, text):
    import hashlib
    return hashlib.md5(f"cb2|{who}|{emo}|{text}".encode()).hexdigest()


VOICE_ALIAS = {"vo": "mikey"}


def line_audio(who, emo, text):
    """TTS_ENGINE=cb ise duygulu Chatterbox önbelleğinden (ses_cb.py üretir), yoksa Kokoro."""
    who = VOICE_ALIAS.get(who, who)
    if os.environ.get("TTS_ENGINE") == "cb" and who not in KOKORO_ONLY:
        cf = os.path.join(os.environ.get("TTS_CACHE", "cikti/budgets/.tts"), "cb", cb_key(who, emo, text) + ".npy")
        if os.path.exists(cf):
            return np.load(cf)
        print(f"  ! cb önbellekte yok, Kokoro: {who}: {text[:40]}", flush=True)
    return tts(text, VOICES[who], SPEED.get(who, 1.0))


def tts(text, voice, speed=1.0):
    import hashlib
    cdir = os.path.join(os.environ.get("TTS_CACHE", "cikti/budgets/.tts"))
    os.makedirs(cdir, exist_ok=True)
    cf = os.path.join(cdir, hashlib.md5(f"{voice}|{speed}|{text}".encode()).hexdigest() + ".npy")
    if os.path.exists(cf):
        return np.load(cf)
    v = _tts(text, voice, speed)
    np.save(cf, v)
    return v


def _tts(text, voice, speed=1.0):
    global _k
    if _k is None:
        from kokoro_onnx import Kokoro
        _k = Kokoro(os.path.join(MODEL_DIR, "kokoro-v1.0.onnx"), os.path.join(MODEL_DIR, "voices-v1.0.bin"))
    parts = [p.strip() for p in re.split(r"(?<=[.!?])\s+", text) if p.strip()]
    out = []
    for i, part in enumerate(parts):
        s, _ = _k.create(part, voice=voice, speed=speed, lang="en-us" if voice[0] == "a" else "en-gb")
        a = np.asarray(s, dtype=np.float32)
        nz = np.nonzero(np.abs(a) > 0.01)[0]
        if len(nz):
            a = a[max(0, nz[0] - 600):nz[-1] + 1500]
        out.append(a)
        if i < len(parts) - 1:
            out.append(np.zeros(int((0.5 if part.endswith("...") else 0.22) * SR), np.float32))
    return np.concatenate(out) if out else np.zeros(1, np.float32)


def tvec(d):
    return np.arange(int(d * SR)) / SR


def env(n, a=0.005, r=0.1):
    e = np.ones(n, np.float32)
    a, r = max(1, int(a * SR)), max(1, int(r * SR))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def tone(f, d, kind="sine", vol=0.3):
    t = tvec(d)
    ph = 2 * np.pi * np.cumsum(np.full(len(t), f) if np.isscalar(f) else f) / SR
    if kind == "square":
        w = np.sign(np.sin(ph)) * 0.5
    elif kind == "saw":
        w = 2 * ((ph / (2 * np.pi)) % 1) - 1
    else:
        w = np.sin(ph)
    return (w * vol * env(len(t), 0.004, min(0.12, d / 2))).astype(np.float32)


def noise(d, vol=0.3, seed=1):
    return (np.random.default_rng(seed).standard_normal(int(d * SR)) * vol).astype(np.float32)


def lowpass(x, k):
    k = max(1, int(k))
    return np.convolve(x, np.ones(k) / k, mode="same").astype(np.float32)


def sfx(name):
    if name == "door":
        x = lowpass(noise(0.35, 0.8), 40) * np.exp(-tvec(0.35) * 14)
        return np.concatenate([tone(np.linspace(300, 420, int(0.3 * SR)), 0.3, "saw", 0.05), x])
    if name == "ping":
        return tone(1320, 0.35, vol=0.25) * np.exp(-tvec(0.35) * 8) + tone(1980, 0.35, vol=0.1) * np.exp(-tvec(0.35) * 10)
    if name == "ding":
        return tone(2100, 0.8, vol=0.3) * np.exp(-tvec(0.8) * 5)
    if name == "whirr":
        t = tvec(1.6)
        return (lowpass(noise(1.6, 0.5), 6) * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * t)) * env(len(t), 0.2, 0.3)).astype(np.float32)
    if name == "deflate":
        t = tvec(1.4)
        f = np.linspace(900, 120, len(t))
        return (tone(f, 1.4, "saw", 0.12) + lowpass(noise(1.4, 0.25), 3) * np.linspace(1, 0, len(t))).astype(np.float32)
    if name == "rimshot":
        sn = lowpass(noise(0.25, 0.7), 2) * np.exp(-tvec(0.25) * 22)
        cy = noise(1.2, 0.25, 3) * np.exp(-tvec(1.2) * 3)
        cy = cy - lowpass(cy, 4)
        out = np.zeros(int(1.8 * SR), np.float32)
        for at in (0.0, 0.18):
            a = int(at * SR)
            out[a:a + len(sn)] += sn
        out[int(0.42 * SR):int(0.42 * SR) + len(cy)] += cy * 1.5
        out[int(0.42 * SR):int(0.42 * SR) + len(sn)] += sn
        return out
    if name == "jukebox":
        notes = [523, 659, 784, 659, 698, 880, 784, 0]
        return np.concatenate([tone(n, 0.18, "square", 0.08) if n else np.zeros(int(0.18 * SR), np.float32) for n in notes])
    if name == "whoosh":
        t = tvec(0.6)
        x = noise(0.6, 0.6, 5)
        x = x - lowpass(x, 3)
        return (lowpass(x, 3) * np.sin(np.pi * t / 0.6) ** 2).astype(np.float32)
    return np.zeros(1, np.float32)


def sting(kind="scene"):
    """Sitcom geçiş vurgusu: slap bas + akor."""
    if kind == "title":
        mel = [392, 523, 659, 784, 659, 784, 1046]
        d = 0.16
        lead = np.concatenate([tone(m, d, "square", 0.09) for m in mel])
        bass = np.concatenate([tone(98, 0.32, "saw", 0.18), tone(131, 0.32, "saw", 0.18), tone(196, 0.48, "saw", 0.18)])
        n = max(len(lead), len(bass)) + int(0.6 * SR)
        out = np.zeros(n, np.float32)
        out[:len(lead)] += lead
        out[:len(bass)] += lowpass(bass, 6)
        hit = tone(1046, 0.9, "square", 0.06) * np.exp(-tvec(0.9) * 4) + tone(523, 0.9, "saw", 0.08) * np.exp(-tvec(0.9) * 4)
        out[len(lead) - int(0.05 * SR):len(lead) - int(0.05 * SR) + len(hit)] += hit[:n - len(lead) + int(0.05 * SR)]
        return out
    seq = [(110, 0.12), (165, 0.12), (220, 0.3)]
    bass = lowpass(np.concatenate([tone(f, d, "saw", 0.22) for f, d in seq]), 5)
    ch = sum(tone(f, 0.55, "square", 0.035) * np.exp(-tvec(0.55) * 5) for f in (440, 554, 659))
    out = np.zeros(max(len(bass), int(0.24 * SR) + len(ch)), np.float32)
    out[:len(bass)] += bass
    out[int(0.24 * SR):int(0.24 * SR) + len(ch)] += ch
    return out


# ---------------------------------------------------------------- zaman çizelgesi


def build(events, limit=None):
    """Olayları kare-zamanlı segmentlere çevirir."""
    segs, audio = [], []
    t = 0.0
    scene = None
    shot = None
    pending_sfx = []
    emo = {}
    pose = {}
    nlines = 0
    for e in events:
        if e["t"] in ("scene", "cutaway"):
            if scene is not None:
                audio.append((t, sting() if e["t"] == "scene" and not scene.get("cut") else sfx("whoosh"), 0.8))
            if e["t"] == "cutaway":
                audio.append((t, sfx("whoosh"), 0.9))
            scene = dict(bg=e["bg"], cast={k: list(v) for k, v in e["cast"].items()}, cut=e["t"] == "cutaway")
            for k in scene["cast"]:
                emo.setdefault(k, "neutral")
            t += 0.2
            shot = None
        elif e["t"] == "shot":
            shot = e["v"]
        elif e["t"] == "caption":
            scene["caption"] = e["text"]
        elif e["t"] == "sfx":
            pending_sfx.append(e["n"])
        elif e["t"] == "title":
            audio.append((t, sting("title"), 0.9))
            segs.append(dict(kind="title", t0=t, t1=t + 3.0, text=e["text"]))
            t += 3.0
        elif e["t"] == "beat":
            for n in pending_sfx:
                audio.append((t, sfx(n), 0.8))
            pending_sfx = []
            segs.append(dict(kind="shot", t0=t, t1=t + e["d"], scene=scene, shot=shot or ["wide"], speaker=None,
                             emo=dict(emo), pose=dict(pose), snap=_snap(scene)))
            t += e["d"]
        elif e["t"] == "walk":
            who = e["who"]
            if who not in scene["cast"]:
                scene["cast"][who] = [-250.0 if e["x"] > 960 else 2170.0, 1]
                emo.setdefault(who, "neutral")
            x0 = scene["cast"][who][0]
            d = max(0.9, abs(e["x"] - x0) / 420)
            for n in pending_sfx:
                audio.append((t, sfx(n), 0.8))
            pending_sfx = []
            segs.append(dict(kind="shot", t0=t, t1=t + d, scene=scene, shot=["wide"], speaker=None, emo=dict(emo),
                             pose=dict(pose), snap=_snap(scene), walk=(who, x0, e["x"])))
            scene["cast"][who][0] = e["x"]
            scene["cast"][who][1] = 1 if e["x"] > x0 else -1
            if e["x"] < -100 or e["x"] > 2020:
                del scene["cast"][who]
            t += d
        elif e["t"] == "line":
            who = e["who"]
            if limit and nlines >= limit:
                break
            nlines += 1
            v = line_audio(who, e["emo"], e["en"])
            for n in pending_sfx:
                audio.append((t, sfx(n), 0.8))
            pending_sfx = []
            lead = 0.25
            vo = who == "vo"  # dış ses anlatıcı: ekranda konuşan yok
            if not vo:
                emo[who] = e["emo"]
                if e["pose"]:
                    pose[who] = e["pose"]
            d = lead + len(v) / SR + 0.45
            cam = shot or (["wide"] if vo else _auto_shot(scene, who, nlines))
            segs.append(dict(kind="shot", t0=t, t1=t + d, scene=scene, shot=cam, speaker=None if vo else who,
                             emo=dict(emo), pose=dict(pose), snap=_snap(scene), audio=v, a0=t + lead, en=e["en"],
                             tr=e["tr"], vo=vo))
            audio.append((t + lead, v, 1.0))
            shot = None
            t += d
            # tepki çekimi: dinleyenin yüzüne kısa kesme (sitcom ritmi)
            others = [k for k in scene["cast"] if k != who and k not in PROPS]
            if not vo and not scene["cut"] and others and nlines % 3 == 0:
                sx = scene["cast"][who][0]
                lis = min(others, key=lambda k: abs(scene["cast"][k][0] - sx))
                rx = {"shock": "shock", "angry": "sad", "smug": "angry", "happy": "smug", "sad": "smug"}.get(e["emo"], "neutral")
                if nlines % 2:
                    rx = {"neutral": "smug", "smug": "shock"}.get(rx, rx)
                em2 = dict(emo)
                em2[lis] = rx
                segs.append(dict(kind="shot", t0=t, t1=t + 1.0, scene=scene, shot=["close", lis], speaker=None,
                                 emo=em2, pose=dict(pose), snap=_snap(scene), react=who))
                t += 1.0
    return segs, audio, t


def _snap(scene):
    return dict(bg=scene["bg"], cut=scene["cut"], caption=scene.get("caption"),
                cast={k: list(v) for k, v in scene["cast"].items()})


def _auto_shot(scene, who, n):
    if who in scene["cast"] and n % 4:
        return ["close", who]
    return ["wide"]


# ---------------------------------------------------------------- çizim
FONT = "Inter"


def char_y(name, bg):
    if name == "homi":
        return COUNTER_Y.get(bg, GROUND)
    return GROUND


def head_pos(name, x, bg):
    if name == "homi":
        return x, COUNTER_Y.get(bg, GROUND) - 120
    if name in PROPS:
        return x, GROUND - 260
    from karakter import SPECS
    sp = SPECS[name]
    return x, GROUND - (sp["leg_h"] + sp["body_h"] + sp["head_h"] * 0.5) * SCALE


def camera(seg, u):
    cast = seg["snap"]["cast"]
    bg = seg["snap"]["bg"]
    kind = seg["shot"][0]
    push = 1 + 0.035 * u
    if kind == "close" and len(seg["shot"]) > 1 and seg["shot"][1] in cast:
        n = seg["shot"][1]
        x, y = head_pos(n, cast[n][0], bg)
        z = 2.55 if n != "homi" else 2.4
        cx, cy = x, y + 95
    elif kind == "two" and len(seg["shot"]) > 2 and all(n in cast for n in seg["shot"][1:3]):
        a, b = seg["shot"][1:3]
        (xa, ya), (xb, yb) = head_pos(a, cast[a][0], bg), head_pos(b, cast[b][0], bg)
        z = min(1.6, 1500 / (abs(xa - xb) + 700))
        cx, cy = (xa + xb) / 2, (ya + yb) / 2 + 200
    else:
        z, cx, cy = 1.0, 960, 540
    z *= push
    cx = min(max(cx, 960 / z), W - 960 / z)
    cy = min(max(cy, 540 / z), H - 540 / z)
    return cx, cy, z


class Blinker:
    def __init__(self):
        self.rnd = random.Random(3)
        self.next = {}

    def get(self, name, t):
        nb = self.next.get(name)
        if nb is None:
            nb = self.next[name] = t + self.rnd.uniform(0.5, 3.5)
        if t > nb + 0.15:
            self.next[name] = t + self.rnd.uniform(2.0, 5.0)
            return 0.0
        if t >= nb:
            k = (t - nb) / 0.15
            return 1.0 - abs(2 * k - 1)
        return 0.0


def envelope(v):
    hop = SR // FPS
    n = len(v) // hop + 1
    e = np.array([np.sqrt(np.mean(v[i * hop:(i + 1) * hop] ** 2)) if i * hop < len(v) else 0 for i in range(n)])
    p = np.percentile(e[e > 0], 90) if np.any(e > 0) else 1
    return np.clip(e / (p + 1e-6), 0, 1.3)


def wrap(text, n=58):
    words, lines, cur = text.split(), [], ""
    for w in words:
        if len(cur) + len(w) + 1 > n and cur:
            lines.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    lines.append(cur)
    return lines


def draw_sub(ctx, text, vo=False):
    ctx.select_font_face(FONT, cairo.FONT_SLANT_ITALIC if vo else cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(44)
    lines = wrap(text)
    y0 = H - 70 - (len(lines) - 1) * 56
    for i, ln in enumerate(lines):
        ext = ctx.text_extents(ln)
        x = (W - ext.width) / 2 - ext.x_bearing
        y = y0 + i * 56
        ctx.move_to(x, y)
        ctx.text_path(ln)
        ctx.set_source_rgb(0, 0, 0)
        ctx.set_line_width(9)
        ctx.set_line_join(cairo.LINE_JOIN_ROUND)
        ctx.stroke_preserve()
        ctx.set_source_rgb(*((1, 0.9, 0.55) if vo else (1, 1, 1)))
        ctx.fill()


def draw_title(ctx, text, u):
    g = cairo.RadialGradient(960, 540, 50, 960, 540, 1100)
    g.add_color_stop_rgb(0, *rgb("#ffb53b"))
    g.add_color_stop_rgb(1, *rgb("#d9342b"))
    ctx.set_source(g)
    ctx.paint()
    ctx.save()
    ctx.translate(960, 540)
    ctx.rotate(u * 0.6)
    for i in range(24):  # güneş ışınları
        ctx.move_to(0, 0)
        ctx.arc(0, 0, 1600, i * 2 * math.pi / 24, (i + 0.5) * 2 * math.pi / 24)
        ctx.close_path()
        ctx.set_source_rgba(1, 1, 1, 0.08)
        ctx.fill()
    ctx.restore()
    pop = min(1.0, u * 5) ** 0.5
    s = 0.6 + 0.4 * pop + 0.03 * math.sin(u * 20) * (1 - u)
    ctx.save()
    ctx.translate(960, 560)
    ctx.scale(s, s)
    ctx.rotate(-0.05)
    ctx.select_font_face(FONT, cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(190)
    ext = ctx.text_extents(text)
    ctx.move_to(-ext.width / 2 - ext.x_bearing, ext.height / 2)
    ctx.text_path(text)
    ctx.set_source_rgb(*INK)
    ctx.set_line_width(28)
    ctx.set_line_join(cairo.LINE_JOIN_ROUND)
    ctx.stroke_preserve()
    ctx.set_source_rgb(*rgb("#fff3c4"))
    ctx.fill()
    ctx.restore()


def render_frame(ctx, seg, t, blink, envs, subs=True):
    u = (t - seg["t0"]) / max(0.01, seg["t1"] - seg["t0"])
    if seg["kind"] == "title":
        draw_title(ctx, seg["text"], u)
        return
    snap = seg["snap"]
    bg = snap["bg"]
    cx, cy, z = camera(seg, u)
    ctx.save()
    ctx.translate(W / 2, H / 2)
    ctx.scale(z, z)
    ctx.translate(-cx, -cy)
    ctx.save()
    ctx.scale(0.5, 0.5)
    ctx.set_source_surface(background(bg), 0, 0)
    ctx.paint()
    ctx.restore()
    speaker = seg.get("speaker")
    mouth = 0.0
    if speaker and "a0" in seg:
        k = int((t - seg["a0"]) * FPS) // 2 * 2  # dudak: "ikili" kare (cartoon)
        ev = envs[id(seg)]
        mouth = float(ev[k]) if 0 <= k < len(ev) else 0.0
    cast = snap["cast"]
    order = sorted(cast.items(), key=lambda kv: (kv[0] == "homi", kv[1][0]))
    for name, (x, facing) in order:
        st = dict(facing=facing, t=t)
        walk = seg.get("walk")
        if walk and walk[0] == name:
            x = walk[1] + (walk[2] - walk[1]) * u
            st["walk"] = t * 9.0
            st["facing"] = 1 if walk[2] > walk[1] else -1
            st["bob"] = -abs(math.sin(t * 9.0)) * 8
        if name in PROPS:
            Prop(name).draw(ctx, x, GROUND, SCALE, st)
            continue
        st["emo"] = seg["emo"].get(name, "neutral")
        # bakış: konuşana / konuşan en yakına
        target = None
        if seg.get("react") in cast and seg["react"] != name:
            target = cast[seg["react"]][0]
        elif speaker and speaker != name and speaker in cast:
            target = cast[speaker][0]
        elif speaker == name:
            others = [v[0] for k, v in cast.items() if k != name]
            target = min(others, key=lambda ox: abs(ox - x)) if others else None
        lx = 0.0 if target is None else (0.75 if target > x else -0.75) * st["facing"]
        st["look"] = (lx, 0.0)
        st["blink"] = blink.get(name, t)
        talking = name == speaker
        st["mouth"] = mouth if talking else 0.0
        if "bob" not in st:
            st["bob"] = math.sin(t * 2.2 + x) * 2.5 + (math.sin(t * 13) * 4 * mouth if talking else 0)
        st["tilt"] = (0.05 * math.sin(t * 1.7) if talking else 0.02 * math.sin(t * 0.9 + x))
        p_now = seg["pose"].get(name, "rest")
        p_prev = seg.get("prev_pose", {}).get(name, p_now)
        pose = blend_pose(POSES.get(p_prev, POSES["rest"]), POSES.get(p_now, POSES["rest"]), (t - seg["t0"]) / 0.3)
        if talking and p_now not in ("phone", "facepalm", "think"):
            wob = math.sin(t * 6.0) * 7 * mouth
            pose = (pose[0], (pose[1][0] + wob * 0.5, pose[1][1] + wob))
        st["pose"] = pose
        if p_now == "phone":
            st["prop"] = "phone"
        if name == "homi":
            make("homi").draw(ctx, x, char_y(name, bg), 0.9, st)
        else:
            make(name).draw(ctx, x, GROUND, SCALE, st)
    if bg == "snow":
        snowfall(ctx, t)
    ctx.restore()
    if snap["cut"]:  # kesme şakası: sepya + başlık
        ctx.set_source_rgba(0.55, 0.38, 0.15, 0.22)
        ctx.paint()
        cap = snap.get("caption") or CUT_CAPTION.get(bg)
        if cap:
            ctx.select_font_face(FONT, cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
            ctx.set_font_size(54)
            ctx.move_to(60, 100)
            ctx.text_path(cap)
            ctx.set_source_rgb(0, 0, 0)
            ctx.set_line_width(8)
            ctx.stroke_preserve()
            ctx.set_source_rgb(1, 0.92, 0.6)
            ctx.fill()
    # vinyet
    g = cairo.RadialGradient(960, 540, 600, 960, 540, 1250)
    g.add_color_stop_rgba(0, 0, 0, 0, 0)
    g.add_color_stop_rgba(1, 0, 0, 0, 0.28)
    ctx.set_source(g)
    ctx.paint()
    if subs and seg.get("en") and t >= seg["a0"] - 0.1:
        draw_sub(ctx, seg["en"], seg.get("vo"))


SHOWS = {"budgets": "THE BUDGETS", "comedown": "THE COMEDOWN"}  # @title metni senaryoda


def series_of(script):
    return os.path.basename(os.path.dirname(os.path.abspath(script)))


def srt_time(s):
    ms = int(round(s * 1000))
    return f"{ms // 3600000:02d}:{ms // 60000 % 60:02d}:{ms // 1000 % 60:02d},{ms % 1000:03d}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("script")
    ap.add_argument("--out")
    ap.add_argument("--limit", type=int)
    a = ap.parse_args()
    slug = os.path.splitext(os.path.basename(a.script))[0]
    out = a.out or f"cikti/{series_of(a.script)}/{slug}/{slug}"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    segs, audio, total = build(parse(a.script), a.limit)
    # önceki pozları geçiş için bağla
    prev = {}
    for s in segs:
        if s["kind"] == "shot":
            s["prev_pose"] = prev
            prev = s["pose"]
    total += 0.8
    print(f"segment: {len(segs)}  süre: {total:.1f} sn", flush=True)
    # ses miksajı
    mix = np.zeros(int(total * SR) + SR, np.float32)
    for at, x, vol in audio:
        i = int(at * SR)
        x = x[:len(mix) - i]
        mix[i:i + len(x)] += x * vol
    room = noise(total + 1, 0.004, 9)[:len(mix)]
    mix += lowpass(room, 30)
    wav = out + ".wav"
    import wave
    with wave.open(wav, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(mix / max(1e-6, np.max(np.abs(mix))) * 0.9, -1, 1) * 32767).astype(np.int16).tobytes())
    # altyazılar
    with open(out + ".en.srt", "w", encoding="utf-8") as fe, open(out + ".tr.srt", "w", encoding="utf-8") as ft:
        k = 0
        for s in segs:
            if s.get("en"):
                k += 1
                tt = f"{k}\n{srt_time(s['a0'])} --> {srt_time(s['t1'] - 0.1)}\n"
                fe.write(tt + s["en"] + "\n\n")
                ft.write(tt + s["tr"] + "\n\n")
    envs = {id(s): envelope(s["audio"]) for s in segs if "audio" in s}
    # video
    nfr = int(total * FPS)
    ff = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "bgra", "-s", f"{W}x{H}", "-r", str(FPS),
                           "-i", "-", "-i", wav, "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p",
                           "-c:a", "aac", "-b:a", "160k", "-af", "loudnorm=I=-14:TP=-1.5:LRA=11", "-shortest",
                           "-movflags", "+faststart", out + ".mp4"], stdin=subprocess.PIPE)
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, W, H)
    ctx = cairo.Context(surf)
    blink = Blinker()
    si = 0
    for f in range(nfr):
        t = f / FPS
        while si < len(segs) - 1 and t >= segs[si]["t1"]:
            si += 1
        ctx.set_source_rgb(0, 0, 0)
        ctx.paint()
        seg = segs[si]
        if seg["t0"] <= t < seg["t1"] or si == len(segs) - 1:
            render_frame(ctx, seg, t, blink, envs)
        surf.flush()
        ff.stdin.write(bytes(surf.get_data()))
        if f % (FPS * 30) == 0:
            print(f"  kare {f}/{nfr}", flush=True)
    ff.stdin.close()
    ff.wait()
    print("✔", out + ".mp4", flush=True)


if __name__ == "__main__":
    main()
