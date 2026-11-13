#!/usr/bin/env python3
"""dizi_pilot.json -> senaryolar/dizi_kare_batch.json (gorsel_uret.py --batch için).
Karakter referansları (kilitli tasarımlar) REFS sözlüğünde. Başlık kartları (black screen) atlanır; montaj programı çizer."""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
K = "cikti/dizi/karakterler/"
REFS = {"moss": K + "moss_b_ref.png", "jessie": K + "jessie_b_ref.png", "bruno": K + "bruno_b_ref.png", "adler": K + "adler_a_ref.png", "rotter": K + "rotter_a_ref.png"}
plan = json.load(open(os.path.join(HERE, "dizi_pilot.json"), encoding="utf-8"))
only = set(sys.argv[1].split(",")) if len(sys.argv) > 1 else None
items = []
for i, s in enumerate(plan["shots"]):
    if s["prompt"].startswith("black screen"):
        continue
    if only and s["id"] not in only:
        continue
    it = dict(prompt=s["prompt"], out=f"cikti/dizi/pilot/kareler/{s['id']}.png", seed=100 + i, w=1344, h=768, steps=25, skip_if_exists=True)
    if s.get("ref"):
        it["ref"] = REFS[s["ref"]]
        it["ref_scale"] = 0.32 if s["ref"] in ("moss", "jessie", "bruno", "adler") else 0.22
    items.append(it)
out = os.path.join(HERE, "dizi_kare_batch.json" if not only else "dizi_kare_test.json")
json.dump(items, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(items), "kare ->", out)
