"""Text featurizer shared (bit-for-bit) with lib/domain/ml/text_classifier.dart.

Features: word unigrams + character 3- and 4-grams of " word ", hashed with
32-bit FNV-1a over UTF-8 into `dims` buckets.
"""
import re

# All i-variants fold to "i" so Turkish (KIRA/kıra) and English (NETFLIX) both work.
TR_FOLD = str.maketrans({"I": "i", "İ": "i", "ı": "i"})
_STRIP = re.compile(r"[^\w\s&]+", re.UNICODE)
_DIGITS = re.compile(r"\d+")
_SPACE = re.compile(r"\s+")


def normalize(text: str) -> str:
    t = text.translate(TR_FOLD).lower()
    t = _DIGITS.sub(" ", t)
    t = _STRIP.sub(" ", t.replace("_", " "))
    return _SPACE.sub(" ", t).strip()


def fnv1a(s: str) -> int:
    h = 0x811C9DC5
    for b in s.encode("utf-8"):
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return h


def tokens(text: str):
    t = normalize(text)
    out = []
    for w in t.split(" "):
        if not w:
            continue
        out.append("w:" + w)
        padded = f" {w} "
        chars = list(padded)
        for n in (3, 4):
            for i in range(len(chars) - n + 1):
                out.append("c:" + "".join(chars[i:i + n]))
    return out


def features(text: str, dims: int):
    counts = {}
    for tok in tokens(text):
        k = fnv1a(tok) % dims
        counts[k] = counts.get(k, 0) + 1
    if not counts:
        return {}
    norm = sum(v * v for v in counts.values()) ** 0.5
    return {k: v / norm for k, v in counts.items()}
