#!/usr/bin/env python3
"""YouTube bölümleri (chapters): altyazı dosyasından her bölümün başladığı anı bulur.

Kullanım: python3 araclar/bolumler.py altyazi.srt bolumler.json
bolumler.json: [{"start": "There is only one thing", "en": "Intro", "tr": "Giriş"}, ...]
"""
import json
import re
import sys


def parse_srt(path):
    items = []
    for block in open(path, encoding="utf-8").read().strip().split("\n\n"):
        lines = block.splitlines()
        if len(lines) >= 3:
            h, m, s = lines[1].split(" --> ")[0].replace(",", ".").split(":")
            items.append((int(h) * 3600 + int(m) * 60 + float(s), " ".join(lines[2:])))
    return items


def norm(t):
    return re.sub(r"[^a-z0-9 ]", "", t.lower())


def chapters(srt, defs):
    """Altyazıları tek bir metin akışına çevirip her bölümün ilk cümlesini sırayla arar."""
    items = parse_srt(srt)
    stream, owners = "", []
    for k, (ts, txt) in enumerate(items):
        piece = norm(txt) + " "
        stream += piece
        owners += [k] * len(piece)
    out, pos = [], 0
    for d in defs:
        key = norm(d["start"])
        idx = stream.find(key, pos)
        if idx < 0:
            raise SystemExit(f"Bölüm bulunamadı: {d['start']}")
        t = items[owners[idx]][0]
        out.append((0.0 if not out else t, d))
        pos = idx + len(key)
    return out


def fmt(t):
    t = int(t)
    return f"{t // 60}:{t % 60:02d}" if t < 3600 else f"{t // 3600}:{t % 3600 // 60:02d}:{t % 60:02d}"


if __name__ == "__main__":
    res = chapters(sys.argv[1], json.load(open(sys.argv[2], encoding="utf-8")))
    for lang in ("en", "tr"):
        print(f"--- {lang}")
        for t, d in res:
            print(f"{fmt(t)} {d[lang]}")
