#!/usr/bin/env python3
"""Duygulu seslendirme ön geçişi (Chatterbox, CPU). sdvenv python'u ile çalıştır:

    HF_HOME=... $SDVENV/bin/python araclar/cizgi/ses_cb.py senaryolar/budgets/b03.txt [--extra "dale|happy|metin"]

Her karakter için Kokoro sesinden üretilmiş referans klip (cikti/sesler/ref_<ad>.wav) klonlanır;
senaryodaki duygu -> exaggeration/cfg. Sonuç: <TTS_CACHE>/cb/<anahtar>.npy ; motor.py TTS_ENGINE=cb ile okur.
"""
import argparse
import os
import sys
import time

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor  # noqa: E402

EXAG = {"neutral": 0.45, "smug": 0.55, "happy": 0.7, "sad": 0.5, "angry": 0.95, "shock": 1.1}
CFG = {"neutral": 0.5, "smug": 0.45, "happy": 0.4, "sad": 0.35, "angry": 0.3, "shock": 0.3}
REF_DIR = "cikti/sesler"


def trim(a, sr):
    nz = np.nonzero(np.abs(a) > 0.012)[0]
    if len(nz):
        a = a[max(0, nz[0] - int(0.03 * sr)):nz[-1] + int(0.08 * sr)]
    return a.astype(np.float32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("scripts", nargs="+")
    ap.add_argument("--extra", action="append", default=[])
    a = ap.parse_args()
    cache = os.path.join(os.environ.get("TTS_CACHE", "cikti/budgets/.tts"), "cb")
    os.makedirs(cache, exist_ok=True)
    jobs = []
    for sc in a.scripts:
        for e in motor.parse(sc):
            w = motor.VOICE_ALIAS.get(e["who"], e["who"]) if e["t"] == "line" else None
            if w and w not in motor.KOKORO_ONLY:
                jobs.append((w, e["emo"], e["en"]))
    for x in a.extra:
        w, em, tx = x.split("|", 2)
        jobs.append((w, em, tx))
    todo = [j for j in dict.fromkeys(jobs) if not os.path.exists(os.path.join(cache, motor.cb_key(*j) + ".npy"))]
    print(f"cb: {len(todo)} replik üretilecek", flush=True)
    if not todo:
        return
    import torch
    torch.set_num_threads(os.cpu_count() or 4)
    from chatterbox.tts import ChatterboxTTS
    m = ChatterboxTTS.from_pretrained(device="cpu")
    for i, (who, emo, text) in enumerate(todo):
        ref = os.path.join(REF_DIR, f"ref_{who}.wav")
        if not os.path.exists(ref):
            raise SystemExit(f"referans yok: {ref}  (python3 araclar/cizgi/ses_ref.py)")
        t = time.time()
        with torch.inference_mode():
            w = m.generate(text, audio_prompt_path=ref, exaggeration=EXAG.get(emo, 0.5), cfg_weight=CFG.get(emo, 0.5),
                           temperature=0.75)
        v = trim(w.squeeze().numpy(), m.sr)
        np.save(os.path.join(cache, motor.cb_key(who, emo, text) + ".npy"), v)
        print(f"  {i + 1}/{len(todo)} {who}/{emo} {len(v) / m.sr:.1f}sn ({time.time() - t:.0f}sn)", flush=True)


if __name__ == "__main__":
    main()
