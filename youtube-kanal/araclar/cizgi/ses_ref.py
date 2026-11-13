#!/usr/bin/env python3
"""Her karakter için Kokoro sesinden ~10 sn referans klip üretir (Chatterbox klonlaması için)."""
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor  # noqa: E402

TEXT = ("Well, I'll tell you exactly what happened, because nobody ever believes me. "
        "It started on a Tuesday, and honestly, it only got worse from there.")
os.makedirs("cikti/sesler", exist_ok=True)
for who, voice in motor.VOICES.items():
    out = f"cikti/sesler/ref_{who}.wav"
    if os.path.exists(out):
        continue
    v = motor._tts(TEXT, voice, motor.SPEED.get(who, 1.0))
    with wave.open(out, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(motor.SR)
        w.writeframes((np.clip(v / max(1e-6, np.abs(v).max()) * 0.9, -1, 1) * 32767).astype(np.int16).tobytes())
    print("✔", out)
