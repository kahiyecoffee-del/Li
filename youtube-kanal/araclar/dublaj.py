#!/usr/bin/env python3
"""YouTube çok dilli ses için dublaj kanalı üretir (Azure Speech).

Videonun zaman çizelgesi değişmez: her sahnenin yeni dildeki sesi, o sahnenin İngilizce
süresine sığdırılır (gerekirse hafifçe hızlandırılır), aynı müzik eklenir.

Kullanım:
    python3 araclar/dublaj.py senaryolar/solipsizm.json cikti/solipsizm/solipsizm_long_en.srt --dil tr
Çıktı: cikti/<slug>/<slug>_dublaj_tr.m4a
Azure anahtarı ortamın ağ sırlarından gelir (westeurope.tts.speech.microsoft.com).
"""
import argparse
import io
import json
import os
import subprocess
import sys
import urllib.request
from xml.sax.saxutils import escape

import numpy as np
import soundfile as sf

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import video_uret as v  # noqa: E402
import bolumler  # noqa: E402

VOICES = {"tr": ("tr-TR", "tr-TR-AhmetNeural"), "es": ("es-ES", "es-ES-AlvaroNeural"), "de": ("de-DE", "de-DE-ConradNeural"),
          "fr": ("fr-FR", "fr-FR-HenriNeural"), "pt": ("pt-BR", "pt-BR-AntonioNeural")}
REGION = os.environ.get("AZURE_SPEECH_REGION", "westeurope")


def azure_tts(text, lang, rate="-6%"):
    loc, voice = VOICES[lang]
    ssml = (f"<speak version='1.0' xml:lang='{loc}'><voice name='{voice}'><prosody rate='{rate}'>{escape(text)}</prosody>"
            f"</voice></speak>").encode("utf-8")
    req = urllib.request.Request(f"https://{REGION}.tts.speech.microsoft.com/cognitiveservices/v1", data=ssml, headers={
        "Content-Type": "application/ssml+xml", "X-Microsoft-OutputFormat": "riff-24khz-16bit-mono-pcm",
        "Ocp-Apim-Subscription-Key": "proxy-tarafindan-eklenir", "User-Agent": "youtube-kanal-dublaj"})
    with urllib.request.urlopen(req, timeout=120) as r:
        a, sr = sf.read(io.BytesIO(r.read()), dtype="float32")
    assert sr == v.SR, sr
    nz = np.nonzero(np.abs(a) > 0.01)[0]
    return a[max(0, nz[0] - 600):nz[-1] + 1500] if len(nz) else a


def stretch(a, factor):
    """Perdeyi bozmadan hızlandır (ffmpeg atempo)."""
    p = subprocess.run(["ffmpeg", "-loglevel", "error", "-f", "f32le", "-ar", str(v.SR), "-ac", "1", "-i", "-",
                        "-filter:a", f"atempo={factor:.4f}", "-f", "f32le", "-"], input=a.astype(np.float32).tobytes(),
                       stdout=subprocess.PIPE, check=True)
    return np.frombuffer(p.stdout, dtype=np.float32)


def scene_starts(data, srt):
    """Her sahnenin videodaki başlangıcını İngilizce altyazıdan çıkarır (altyazı parçaları deterministik)."""
    items = bolumler.parse_srt(srt)
    scenes = list(data["scenes"])
    sub = data.get("subscribe")
    if sub:
        scenes.insert(sub.get("after", 1), dict(say=sub["say"]))
    starts, k = [], 0
    for sc in scenes:
        starts.append(items[k][0])
        k += len(v.chunk_words(sc["say"]["en"], data.get("srt_chars", 42)))
    return scenes, starts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("senaryo")
    ap.add_argument("srt")
    ap.add_argument("--dil", default="tr")
    ap.add_argument("--video", help="süreyi buradan al (varsayılan: srt ile aynı klasördeki mp4)")
    args = ap.parse_args()
    data = json.load(open(args.senaryo, encoding="utf-8"))
    v.CUR["theme"] = v.THEMES[data.get("theme", "playful")]
    scenes, starts = scene_starts(data, args.srt)
    video = args.video or args.srt.replace(".srt", ".mp4")
    total = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", video],
                                 capture_output=True, text=True, check=True).stdout)
    voice = np.zeros(int(total * v.SR) + v.SR, dtype=np.float32)
    for i, sc in enumerate(scenes):
        txt = v.plain(sc["say"][args.dil])
        a = azure_tts(txt, args.dil)
        slot = (starts[i + 1] if i + 1 < len(scenes) else total) - starts[i] - 0.25
        if len(a) / v.SR > slot > 0.5:
            a = stretch(a, min(1.4, len(a) / v.SR / slot))
        j = int(starts[i] * v.SR)
        voice[j:j + len(a)] += a[:len(voice) - j]
        print(f"  {args.dil} sahne {i + 1}/{len(scenes)}", flush=True)
    voice = voice[:int(total * v.SR)]
    voice *= 0.85 / (np.max(np.abs(voice)) or 1)
    audio = v.final_mix(voice, [], data.get("music", True))
    outdir = os.path.dirname(os.path.abspath(args.srt))
    wav = os.path.join(outdir, f"_dublaj_{args.dil}.wav")
    sf.write(wav, audio, v.SR)
    out = os.path.join(outdir, f"{data['slug']}_dublaj_{args.dil}.m4a")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-af", v.LOUDNORM, "-c:a", "aac", "-b:a", "192k", out], check=True)
    os.remove(wav)
    print("✔", out)


if __name__ == "__main__":
    main()
