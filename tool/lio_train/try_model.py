"""Runs Lio's .litertlm on CPU with the same runtime phones use (LiteRT-LM)
and prints answers to a fixed set of TR/EN prompts, so the model can be
judged without a phone.

    python3 tool/lio_train/try_model.py model.litertlm
"""
import json
import sys
import time

import litert_lm

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from make_dataset import SYSTEM_HEAD  # noqa: E402  (same prompt as the app)

FACTS_TR = """- Name: Eray
- Time: Tue 14:05
- Tasks today: 08:00 Spor salonu (done); Ali'ye e-posta; 18:00 Annemi ara
- Budget today: safe ₺500, left ₺320
- Life score: 72/100
- Goals left today: 2
- Streak: 4 days
- Meal idea: Menemen (15 min)"""
FACTS_EN = FACTS_TR.replace("Spor salonu", "Gym").replace("Ali'ye e-posta", "Email Ali").replace(
    "Annemi ara", "Call mom").replace("₺", "$").replace("Menemen", "Veggie omelette")

PROMPTS = [
    ("tr", "Merhaba, kendini tanıtır mısın?"),
    ("tr", "Günümü planla"),
    ("tr", "Bugün ne kadar harcayabilirim?"),
    ("tr", "Akşam yemeğine ne yapsam?"),
    ("tr", "Bugün çok yorgunum ve moralim bozuk"),
    ("tr", "Türkiye'nin en yüksek dağı hangisi?"),
    ("tr", "1500'ün yüzde 20'si kaç?"),
    ("tr", "Bana kısa bir şiir yaz"),
    ("tr", "Bugün dolar kaç lira?"),
    ("tr", "Bana görev ekle: yarın 9'da toplantı"),
    ("en", "Plan my day"),
    ("en", "What's the capital of Australia?"),
    ("en", "Should I buy bitcoin?"),
]


def main():
    model = sys.argv[1]
    litert_lm.set_min_log_severity(litert_lm.LogSeverity.ERROR)
    t0 = time.time()
    engine = litert_lm.Engine(model, backend=litert_lm.Backend.CPU(), max_num_tokens=1280)
    print(f"model loaded in {time.time() - t0:.1f}s", flush=True)
    for lang, q in PROMPTS:
        system = SYSTEM_HEAD.format(lang="Turkish" if lang == "tr" else "English") + (FACTS_TR if lang == "tr" else FACTS_EN)
        conv = engine.create_conversation(system_message=system, max_output_tokens=200)
        t = time.time()
        res = conv.send_message(q)
        try:
            text = "".join(c.get("text", "") for c in res.get("content", []))
        except Exception:  # unknown shape: print raw
            text = json.dumps(res, ensure_ascii=False)
        print(f"\n=== [{lang}] {q}\n{text.strip()}\n({time.time() - t:.1f}s)", flush=True)


if __name__ == "__main__":
    main()
