"""Telifsiz ses tasarımı: koddan üretilen arka plan müziği ve efektler.

Her şey sentezlenir; dışarıdan ses dosyası yok, telif riski yok.
"""
import math

import numpy as np

SR = 24000


def _t(dur):
    return np.arange(int(dur * SR)) / SR


def _env(n, attack, release):
    e = np.ones(n, dtype=np.float32)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    e[:a] = np.linspace(0, 1, a)
    if r < n:
        e[-r:] *= np.linspace(1, 0, r)
    return e


def _lowpass(x, k):
    if k <= 1:
        return x
    return np.convolve(x, np.ones(k) / k, mode="same").astype(np.float32)


def _band_noise(dur, lo, hi, seed):
    n = int(dur * SR)
    rng = np.random.default_rng(seed)
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    spec[(f < lo) | (f > hi)] = 0
    out = np.fft.irfft(spec, n).astype(np.float32)
    return out / (np.max(np.abs(out)) + 1e-9)


# --------------------------------------------------------------------------- #
# Efektler
# --------------------------------------------------------------------------- #
def sfx(name, seed=0):
    if name == "pop":
        t = _t(0.09)
        f = 950 * np.exp(-t * 28) + 260
        x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 38)
        return (x * 0.8).astype(np.float32)
    if name == "scribble":  # imza sesi: kalemle çizim
        dur = 0.38
        x = _band_noise(dur, 1800, 6500, seed)
        t = _t(dur)
        strokes = 0.55 + 0.45 * np.sin(2 * np.pi * (11 + seed % 4) * t) ** 2
        return (x * strokes * _env(len(t), 0.03, 0.12) * 0.35).astype(np.float32)
    if name == "whoosh":
        dur = 0.32
        t = _t(dur)
        x = _band_noise(dur, 300, 4200, seed + 7)
        env = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 2
        return (x * env * 0.55).astype(np.float32)
    if name == "ding":
        t = _t(0.7)
        x = (np.sin(2 * np.pi * 1318.5 * t) + 0.5 * np.sin(2 * np.pi * 1975.5 * t) + 0.25 * np.sin(2 * np.pi * 2637 * t))
        return (x * np.exp(-t * 6) * _env(len(t), 0.003, 0.05) * 0.35).astype(np.float32)
    if name == "boom":  # vurgu / punch-in
        t = _t(0.35)
        f = 110 * np.exp(-t * 9) + 45
        x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9)
        return (x * 0.9).astype(np.float32)
    if name == "tick":
        t = _t(0.03)
        return (np.sin(2 * np.pi * 2400 * t) * np.exp(-t * 200) * 0.4).astype(np.float32)
    if name == "boing":
        t = _t(0.35)
        f = 300 + 180 * np.sin(2 * np.pi * 9 * t) * np.exp(-t * 6)
        return (np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 7) * 0.45).astype(np.float32)
    raise ValueError(name)


# --------------------------------------------------------------------------- #
# Müzik: sakin lo-fi döngü (Am - F - C - G)
# --------------------------------------------------------------------------- #
def _note(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def ambient(total, seed=2):
    """Felsefe/tarih için sakin, sinematik altyapı: yaylı pad + seyrek piyano + derin drone (Dm - Bb - F - C)."""
    n = int(total * SR) + SR
    out = np.zeros(n, dtype=np.float32)
    bar = 60 / 66 * 4
    chords = [[50, 57, 62, 65], [46, 53, 58, 62], [41, 53, 57, 60], [48, 55, 60, 64]]
    rng = np.random.default_rng(seed)
    t0, bi = 0.0, 0
    seg_len = bar * 2
    while t0 < total:
        ch = chords[bi % 4]
        t = _t(seg_len + 1.5)
        pad = np.zeros_like(t, dtype=np.float64)
        for m in ch[1:]:
            f = _note(m)
            for det in (-0.12, 0.0, 0.13):  # hafif akortsuzluk = yaylı sıcaklığı
                ff = f * 2 ** (det / 12)
                pad += np.sin(2 * np.pi * ff * t) + 0.35 * np.sin(4 * np.pi * ff * t) + 0.12 * np.sin(6 * np.pi * ff * t)
        pad *= (0.6 + 0.4 * np.sin(2 * np.pi * 0.15 * t)) * _env(len(t), 1.4, 1.6) * 0.022
        drone = np.sin(2 * np.pi * _note(ch[0] - 12) * t) * _env(len(t), 1.0, 1.5) * 0.09
        seg = (pad + drone).astype(np.float32)
        for k in range(4):  # seyrek piyano
            if rng.random() < 0.75:
                m = ch[rng.integers(1, 4)] + 12
                tt = _t(3.0)
                f = _note(m)
                pl = (np.sin(2 * np.pi * f * tt) + 0.4 * np.sin(4 * np.pi * f * tt) + 0.15 * np.sin(6 * np.pi * f * tt))
                pl *= np.exp(-tt * 1.6) * _env(len(tt), 0.005, 0.3) * 0.06
                i = int((k * seg_len / 4 + rng.uniform(0, 0.3)) * SR)
                seg[i:i + len(pl)] += pl[:len(seg) - i]
        a = int(t0 * SR)
        out[a:a + len(seg)] += seg[:n - a]
        t0 += seg_len
        bi += 1
    out = _lowpass(out, 5)[:int(total * SR)]
    out *= _env(len(out), 1.0, 1.5)
    return out / (np.max(np.abs(out)) + 1e-9)


def music(total, bpm=88, seed=1, style="lofi"):
    if style == "ambient":
        return ambient(total)
    n = int(total * SR) + SR
    out = np.zeros(n, dtype=np.float32)
    beat = 60 / bpm
    bar = beat * 4
    chords = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]  # Am F C G
    rng = np.random.default_rng(seed)
    t0 = 0.0
    bi = 0
    while t0 < total:
        ch = chords[bi % 4]
        # pad
        t = _t(bar)
        pad = sum(np.sin(2 * np.pi * _note(m) * t) + 0.3 * np.sin(2 * np.pi * _note(m) * 2.001 * t) for m in ch)
        pad *= _env(len(t), 0.4, 0.6) * 0.06
        # bas
        bass = np.sin(2 * np.pi * _note(ch[0] - 12) * t) * _env(len(t), 0.02, 0.3) * 0.12
        seg = pad + bass
        # arpej (sekizlik)
        for k in range(8):
            m = ch[[0, 1, 2, 1, 0, 2, 1, 2][k]] + 12
            tt = _t(beat * 0.9)
            pl = np.sin(2 * np.pi * _note(m) * tt) * np.exp(-tt * 5) * 0.05 * (0.8 + 0.4 * rng.random())
            i = int(k * beat / 2 * SR)
            seg[i:i + len(pl)] += pl[:len(seg) - i]
        # davul: kick 1 ve 3'te, hat sekizliklerde
        for k in range(4):
            i = int(k * beat * SR)
            if k in (0, 2):
                kt = _t(0.25)
                kick = np.sin(2 * np.pi * np.cumsum(90 * np.exp(-kt * 20) + 45) / SR) * np.exp(-kt * 14) * 0.22
                seg[i:i + len(kick)] += kick[:len(seg) - i]
            else:
                sn = _band_noise(0.12, 900, 5000, int(rng.integers(1e6))) * np.exp(-_t(0.12) * 30) * 0.05
                seg[i:i + len(sn)] += sn[:len(seg) - i]
        for k in range(8):
            i = int((k + 0.5) * beat / 2 * SR)
            ht = _band_noise(0.04, 6000, 11000, int(rng.integers(1e6))) * np.exp(-_t(0.04) * 90) * 0.025
            seg[i:i + len(ht)] += ht[:len(seg) - i]
        a = int(t0 * SR)
        out[a:a + len(seg)] += seg[:n - a]
        t0 += bar
        bi += 1
    out = _lowpass(out, 3)[:int(total * SR)]
    # giriş/çıkış
    out *= _env(len(out), 0.5, 1.2)
    return out / (np.max(np.abs(out)) + 1e-9)


def duck(music_sig, voice, depth=0.7):
    """Konuşma varken müziği kıs (sidechain)."""
    voice = voice[:len(music_sig)]
    if len(voice) < len(music_sig):
        voice = np.pad(voice, (0, len(music_sig) - len(voice)))
    env = _lowpass(np.abs(voice), int(0.12 * SR))
    env = env / (np.percentile(env, 95) + 1e-9)
    g = 1 - depth * np.clip(env * 1.5, 0, 1)
    g = _lowpass(g, int(0.08 * SR))[:len(music_sig)]
    return music_sig * g


def place(buf, clip, at, gain=1.0):
    i = int(at * SR)
    if i >= len(buf) or i < 0:
        return
    j = min(len(buf), i + len(clip))
    buf[i:j] += clip[:j - i] * gain
