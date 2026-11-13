#!/usr/bin/env python3
"""Stüdyo seyirci kahkahası üretir (lisans derdi yok): Chatterbox ile tekil gülüşler -> kalabalık miksajı.
sdvenv python ile:  HF_HOME=... $SDVENV/bin/python araclar/cizgi/kahkaha_uret.py
Çıktı: cikti/sesler/kahkaha/small_*.wav, big_*.wav
"""
import glob
import os
import random
import wave

import numpy as np

SR = 24000
OUT = "cikti/sesler/kahkaha"
TEXTS = ["Ha ha ha ha!", "Hahaha! Ha ha!", "Ha! Ha ha ha ha.", "Heh heh heh!", "Oh ha ha ha ha!", "Ahaha ha ha!"]


def raw_laughs():
    d = os.path.join(OUT, "tekil")
    os.makedirs(d, exist_ok=True)
    have = sorted(glob.glob(d + "/*.npy"))
    if len(have) >= 30:
        return [np.load(f) for f in have]
    import torch
    from chatterbox.tts import ChatterboxTTS
    torch.set_num_threads(2)
    m = ChatterboxTTS.from_pretrained(device="cpu")
    refs = sorted(glob.glob("cikti/sesler/ref_*.wav"))
    refs = [r for r in refs if "homi" not in r]
    rnd = random.Random(3)
    i = len(have)
    while i < 30:
        ref = refs[i % len(refs)]
        txt = TEXTS[rnd.randrange(len(TEXTS))]
        with torch.inference_mode():
            w = m.generate(txt, audio_prompt_path=ref, exaggeration=rnd.uniform(1.0, 1.5), cfg_weight=0.3, temperature=0.9)
        a = w.squeeze().numpy().astype(np.float32)
        nz = np.nonzero(np.abs(a) > 0.01)[0]
        if len(nz):
            a = a[nz[0]:nz[-1]]
        np.save(f"{d}/l{i:02d}.npy", a)
        print("  gülüş", i, f"{len(a) / SR:.1f}sn", flush=True)
        i += 1
    return [np.load(f) for f in sorted(glob.glob(d + "/*.npy"))]


def reverb(x, t60=0.9):
    n = int(t60 * SR)
    ir = np.random.default_rng(1).standard_normal(n) * np.exp(-6.9 * np.arange(n) / n)
    ir[0] = 1.0
    y = np.convolve(x, ir * 0.12)[:len(x) + n]
    return y


def lowpass(x, k):
    return np.convolve(x, np.ones(k) / k, mode="same")


def crowd(laughs, n, dur, rnd):
    out = np.zeros(int((dur + 1.5) * SR), np.float32)
    for _ in range(n):
        a = laughs[rnd.randrange(len(laughs))]
        sp = rnd.uniform(0.9, 1.15)  # perde/hız çeşitliliği
        a = np.interp(np.arange(0, len(a), sp), np.arange(len(a)), a)
        at = int(rnd.uniform(0, 0.45) * SR)
        g = rnd.uniform(0.25, 1.0)
        a = a[:len(out) - at]
        out[at:at + len(a)] += a * g
    # kalabalık zarfı: hızlı yükseliş, yavaş sönüm
    t = np.arange(len(out)) / SR
    e = np.minimum(1, t / 0.12) * np.exp(-np.maximum(0, t - dur * 0.45) / (dur * 0.35))
    out = lowpass(out * e, 3)
    out = reverb(out)
    out += np.random.default_rng(rnd.randrange(999)).standard_normal(len(out)) * 0.004 * np.exp(-t[:len(out)] / 2) if False else 0
    return (out / (np.abs(out).max() + 1e-6) * 0.9).astype(np.float32)


def save(path, a):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((a * 32767).astype(np.int16).tobytes())


if __name__ == "__main__":
    laughs = raw_laughs()
    rnd = random.Random(11)
    for i in range(6):
        save(f"{OUT}/small_{i}.wav", crowd(laughs, rnd.randint(9, 13), rnd.uniform(1.4, 1.9), rnd))
        save(f"{OUT}/big_{i}.wav", crowd(laughs, rnd.randint(20, 28), rnd.uniform(2.2, 2.8), rnd))
    print("✔ kahkahalar hazır")
