#!/usr/bin/env python3
"""Trains the on-device text classifiers (pure Python, no dependencies).

    python3 tool/ml/train_classifiers.py

Outputs:
  assets/models/expense_classifier.json   expense category from short text
  assets/models/shopping_classifier.json  supermarket aisle for an item name
  test/fixtures/classifier_parity.json    predictions the Dart port must match

Model: multinomial logistic regression over hashed word + char n-grams
(see featurize.py), trained with SGD + L2, weights quantised to int8.
Generalisation is measured on *held-out terms* (never seen in training)
before the final model is trained on everything.
"""
import base64
import json
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from featurize import features  # noqa: E402
from vocab import EXPENSE, SHOPPING  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DIMS = 4096
SEED = 7

FOLD_ASCII = str.maketrans("çğıöşüÇĞİÖŞÜ", "cgiosuCGIOSU")


def typo(word: str, rnd: random.Random) -> str:
    if len(word) < 5:
        return word
    i = rnd.randrange(1, len(word) - 1)
    op = rnd.randrange(3)
    if op == 0:
        return word[:i] + word[i + 1:]
    if op == 1:
        return word[:i] + word[i + 1] + word[i] + word[i + 2:]
    return word[:i] + word[i] + word[i:]


def expand(term: str, lang: str, rnd: random.Random, expense: bool):
    """Realistic variants of one labelled term."""
    out = [term, term.title()]
    if expense:
        amt = str(rnd.choice([12, 35, 50, 85, 120, 250, 499, 1200, 3500]))
        cur = rnd.choice(["", " tl", " ₺", " $", " usd", " eur"])
        out += [f"{amt} {term}", f"{term} {amt}{cur}", f"{amt}{cur} {term}"]
        if lang == "tr":
            out += [f"{term} için {amt}", f"bugün {term}"]
        else:
            out += [f"{term} for {amt}", f"paid {term}"]
    else:
        qty = rnd.choice(["2", "1 kg", "500g", "x3", "a pack of", "bir paket"])
        out += [f"{qty} {term}", f"{term} {qty}"]
    out.append(term.translate(FOLD_ASCII))          # typed without Turkish letters
    out.append(" ".join(typo(w, rnd) for w in term.split()))
    return out


def dataset(spec, expense: bool, rnd: random.Random, exclude=frozenset()):
    rows = []
    for label, langs in spec.items():
        for lang, terms in langs.items():
            for term in terms:
                if term in exclude:
                    continue
                for text in expand(term, lang, rnd, expense):
                    rows.append((text, label))
    rnd.shuffle(rows)
    return rows


def train(rows, classes, epochs=12, lr=0.5, l2=1e-5, seed=SEED):
    rnd = random.Random(seed)
    k = len(classes)
    idx = {c: i for i, c in enumerate(classes)}
    w = [[0.0] * k for _ in range(DIMS)]
    b = [0.0] * k
    feats = [(features(t, DIMS), idx[y]) for t, y in rows]
    # Class weights counter label imbalance.
    counts = [0] * k
    for _, y in feats:
        counts[y] += 1
    cw = [len(feats) / (k * max(1, c)) for c in counts]
    for ep in range(epochs):
        rnd.shuffle(feats)
        rate = lr / (1 + ep * 0.5)
        for x, y in feats:
            logits = b[:]
            for j, v in x.items():
                row = w[j]
                for c in range(k):
                    logits[c] += row[c] * v
            m = max(logits)
            exps = [math.exp(z - m) for z in logits]
            s = sum(exps)
            for c in range(k):
                g = (exps[c] / s - (1.0 if c == y else 0.0)) * cw[y]
                b[c] -= rate * g
                for j, v in x.items():
                    w[j][c] -= rate * (g * v + l2 * w[j][c])
    return w, b


def predict(w, b, classes, text):
    x = features(text, DIMS)
    logits = b[:]
    for j, v in x.items():
        for c in range(len(classes)):
            logits[c] += w[j][c] * v
    m = max(logits)
    exps = [math.exp(z - m) for z in logits]
    s = sum(exps)
    probs = [e / s for e in exps]
    best = max(range(len(classes)), key=lambda c: probs[c])
    return classes[best], probs[best]


def quantize(w):
    mx = max(abs(v) for row in w for v in row) or 1.0
    scale = mx / 127.0
    flat = bytearray()
    for row in w:
        for v in row:
            q = max(-127, min(127, round(v / scale)))
            flat.append(q & 0xFF)
    return scale, flat


def dequantized(scale, flat, k):
    vals = [((x ^ 0x80) - 0x80) * scale for x in flat]
    return [vals[i * k:(i + 1) * k] for i in range(DIMS)]


CONFIDENCE_THRESHOLD = 0.7


def evaluate_holdout(name, spec, expense):
    """Trains without ~1/6 of the terms, then reports:
    - accuracy on those unseen terms (all predictions, and above the
      confidence threshold the app uses),
    - accuracy on fresh double-typo variants of seen terms vs a plain
      keyword-substring matcher (what the app used before)."""
    rnd = random.Random(SEED)
    held = set()
    for langs in spec.values():
        for terms in langs.values():
            terms = sorted(terms)
            rnd.shuffle(terms)
            held.update(terms[: max(1, len(terms) // 6)])
    classes = sorted(spec)
    w, b = train(dataset(spec, expense, random.Random(SEED), exclude=frozenset(held)), classes, epochs=8)
    gold = {t: label for label, langs in spec.items() for terms in langs.values() for t in terms}
    preds = [(predict(w, b, classes, t), gold[t]) for t in held]
    unseen_acc = sum(p[0] == g for p, g in preds) / len(preds)
    confident = [(p, g) for p, g in preds if p[1] >= CONFIDENCE_THRESHOLD]
    precision = sum(p[0] == g for p, g in confident) / max(1, len(confident))
    r2 = random.Random(99)
    n = model_ok = kw_ok = 0
    for t in (t for t in gold if t not in held):
        v = " ".join(typo(typo(x, r2), r2) for x in t.split())
        if v == t:
            continue
        n += 1
        model_ok += predict(w, b, classes, v)[0] == gold[t]
        kw_ok += any(term in v.lower() for term, lab in gold.items() if lab == gold[t])
    m = {
        "unseenTermAccuracy": round(unseen_acc, 3),
        "unseenPrecisionAtThreshold": round(precision, 3),
        "unseenCoverageAtThreshold": round(len(confident) / len(preds), 3),
        "typoAccuracy": round(model_ok / n, 3),
        "typoKeywordBaseline": round(kw_ok / n, 3),
    }
    print(f"[{name}] held-out: {m}")
    return m


def build(name, spec, expense, parity_samples):
    holdout = evaluate_holdout(name, spec, expense)
    classes = sorted(spec)
    rows = dataset(spec, expense, random.Random(SEED))
    w, b = train(rows, classes)
    scale, flat = quantize(w)
    wq = dequantized(scale, flat, len(classes))
    train_acc = sum(predict(wq, b, classes, t)[0] == y for t, y in rows) / len(rows)
    print(f"[{name}] {len(rows)} examples, training accuracy (int8): {train_acc:.1%}")
    model = {
        "format": "lifeos-textclf-v1",
        "name": name,
        "dims": DIMS,
        "classes": classes,
        "ngrams": [3, 4],
        "scale": scale,
        "bias": b,
        "weights_int8_b64": base64.b64encode(bytes(flat)).decode(),
        "threshold": CONFIDENCE_THRESHOLD,
        "metrics": {**holdout, "trainAccuracy": round(train_acc, 4), "examples": len(rows)},
    }
    path = os.path.join(ROOT, "assets", "models", f"{name}_classifier.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(model, f, separators=(",", ":"))
    print(f"[{name}] wrote {os.path.relpath(path, ROOT)} ({os.path.getsize(path) // 1024} KB)")
    return {t: dict(zip(("label", "p"), predict(wq, b, classes, t))) for t in parity_samples}


def main():
    parity = {
        "expense": build("expense", EXPENSE, True,
                         ["250 lunch", "taksi 85", "netflix", "elektrik faturası 640", "kira", "ecznae",
                          "starbucks latte", "sinema bileti", "random words here", "migros alışveriş"]),
        "shopping": build("shopping", SHOPPING, False,
                          ["Milk", "yumurta", "chicken breast", "deterjan", "şampuan", "2 kg domates",
                           "frozen pizza", "zeytinyağı", "unknownthing"]),
    }
    fx = os.path.join(ROOT, "test", "fixtures")
    os.makedirs(fx, exist_ok=True)
    with open(os.path.join(fx, "classifier_parity.json"), "w", encoding="utf-8") as f:
        json.dump(parity, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
