#!/usr/bin/env python3
"""Onay videosu için kopyalanabilir YouTube bilgileri (EN + TR). Çıktı: cikti/onay/youtube_bilgileri.txt"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

ch = bolumler.chapters(os.path.join(ROOT, "cikti", "vr", "vr_long_en.srt"),
                       json.load(open(os.path.join(ROOT, "senaryolar", "vr_bolumler.json"), encoding="utf-8")))
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)
SRC = ("Ivan Sutherland, \"The Ultimate Display\" (1965) · Plato, Republic VII · Antonin Artaud, Le Théâtre et son double (1938) · "
       "Morton Heilig, Sensorama patent (1962) · Meehan et al. (2002), UNC virtual pit · Botvinick & Cohen (1998), Nature · "
       "Yee & Bailenson (2007), Human Communication Research · Hoffman & Patterson, SnowWorld · Aardema et al. (2010), Cyberpsychology, Behavior, and Social Networking · "
       "Nozick, Anarchy, State, and Utopia (1974) · De Brigard (2010), Philosophical Psychology · Chalmers, Reality+ (2022)")

EN_TITLE = "Would You Plug Into the Experience Machine? | The Psychology & Philosophy of Virtual Reality"
TR_TITLE = "Deneyim Makinesine Bağlanır mıydın? | Sanal Gerçekliğin Psikolojisi ve Felsefesi"
EN_DESC = f"""In 1965, Ivan Sutherland imagined a room where a displayed bullet could be fatal. Today, millions wear his invention on their faces.

From Plato's cave and the first VR machines to the virtual pit experiment, the rubber hand illusion, the Proteus effect, VR therapy and Nozick's experience machine — if a world feels completely real, is it?

⏱ Chapters
{ch_en}

📚 Sources
{SRC}

Narration is AI-generated; all illustrations are original. Portrait: Plato (Silanion copy), Capitoline Museums, via Wikimedia Commons (CC BY 2.5).

#virtualreality #philosophy #psychology"""
TR_DESC = f"""1965'te Ivan Sutherland, gösterilen bir kurşunun öldürücü olabileceği bir oda hayal etti. Bugün milyonlarca insan onun icadını yüzünde taşıyor.

Platon'un mağarasından ilk VR makinelerine, sanal uçurum deneyinden lastik el yanılsamasına, Proteus etkisine, VR terapisine ve Nozick'in deneyim makinesine kadar: Bir dünya tamamen gerçek hissettiriyorsa, gerçek midir?

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SRC}

Seslendirme yapay zekâ ile üretilmiştir; tüm çizimler özgündür. Portre: Platon (Silanion kopyası), Capitolini Müzeleri, Wikimedia Commons (CC BY 2.5).

#sanalgerçeklik #felsefe #psikoloji"""
TAGS = ("virtual reality, VR, experience machine, nozick, plato's cave, philosophy of virtual reality, presence, rubber hand illusion, "
        "proteus effect, social vr, vr therapy, david chalmers, reality plus, simulation, psychology, sanal gerçeklik, felsefe")
SHORTS = ["In 1965, he imagined a room where a fake bullet could kill 🥽 #shorts", "They Knew It Wasn't Real. They Still Wouldn't Step. #shorts",
          "Your Brain Can Adopt a Fake Hand ✋ #shorts", "Your Avatar Changes Your Personality 🎭 #shorts",
          "Would You Plug Into the Experience Machine? 🔌 #shorts"]
txt = "\n\n".join([
    "=== İNGİLİZCE BAŞLIK ===", EN_TITLE, "=== İNGİLİZCE AÇIKLAMA ===", EN_DESC, "=== ETİKETLER ===", TAGS,
    "=== TÜRKÇE BAŞLIK ===", TR_TITLE, "=== TÜRKÇE AÇIKLAMA ===", TR_DESC, "=== SHORTS BAŞLIKLARI ===", "\n".join(SHORTS)])
out = os.path.join(ROOT, "cikti", "vr", "youtube_bilgileri.txt")
open(out, "w", encoding="utf-8").write(txt)
print(out)
