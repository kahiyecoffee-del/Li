#!/usr/bin/env python3
"""Onay videosu için kopyalanabilir YouTube bilgileri (EN + TR). Çıktı: cikti/onay/youtube_bilgileri.txt"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

ch = bolumler.chapters(os.path.join(ROOT, "cikti", "onay", "onay_long_en.srt"),
                       json.load(open(os.path.join(ROOT, "senaryolar", "onay_bolumler.json"), encoding="utf-8")))
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)
SRC = ("Marcus Aurelius, Meditations 12.4 · Baumeister & Leary (1995), Psychological Bulletin · Eisenberger, Lieberman & Williams (2003), Science · "
       "Leary et al. (1995), sociometer theory · Asch (1951, 1956) · Gilovich, Medvec & Savitsky (2000), JPSP · Marmot et al., Whitehall studies · "
       "Festinger (1954) · Sherman et al. (2016), Psychological Science · B. F. Skinner, schedules of reinforcement · Sean Parker, Axios interview (Nov 2017) · "
       "Nietzsche, Beyond Good and Evil §199 (1886), Thus Spoke Zarathustra Prologue §5, The Gay Science §270, Ecce Homo (1888) · "
       "Rogers (1959) · Holt-Lunstad, Smith & Layton (2010), PLoS Medicine")

EN_TITLE = "Why Do We Need Other People's Approval? | Nietzsche & The Psychology of Belonging"
TR_TITLE = "Neden Başkalarının Onayına Muhtacız? | Nietzsche ve Aidiyet Psikolojisi"
EN_DESC = f"""Even Marcus Aurelius — the most powerful man in the known world — couldn't stop caring what people thought. Why?

From the evolution of belonging and the Cyberball experiment to Solomon Asch, the spotlight effect, the Whitehall studies, social media's like button and Nietzsche's herd — this is why we crave approval, and what to do about it.

⏱ Chapters
{ch_en}

📚 Sources
{SRC}

Narration is AI-generated; all illustrations are original. Portraits: public-domain works via Wikimedia Commons.

#psychology #nietzsche #philosophy"""
TR_DESC = f"""Bilinen dünyanın en güçlü adamı Marcus Aurelius bile insanların ne düşündüğünü umursamadan edemiyordu. Neden?

Aidiyetin evriminden ve Cyberball deneyinden Solomon Asch'a, spot ışığı etkisine, Whitehall araştırmalarına, sosyal medyanın beğeni butonuna ve Nietzsche'nin sürüsüne kadar: Neden onaya bu kadar muhtacız ve bununla ne yapmalıyız?

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SRC}

Seslendirme yapay zekâ ile üretilmiştir; tüm çizimler özgündür. Portreler: Wikimedia Commons üzerinden kamu malı eserler.

#psikoloji #nietzsche #felsefe"""
TAGS = ("need for approval, approval seeking, nietzsche, herd mentality, psychology, social psychology, need to belong, asch conformity experiment, "
        "spotlight effect, social media psychology, self esteem, marcus aurelius, carl rogers, philosophy, onay ihtiyacı, nietzsche türkçe, psikoloji")
SHORTS = ["The most powerful man on Earth still cared what people thought #shorts", "Why being left out literally hurts #shorts",
          "They denied what they could see #shorts", "Nobody is looking at you (as much as you think) #shorts",
          "Your phone is a slot machine for approval #shorts", "Nietzsche's books barely sold #shorts"]
txt = "\n\n".join([
    "=== İNGİLİZCE BAŞLIK ===", EN_TITLE, "=== İNGİLİZCE AÇIKLAMA ===", EN_DESC, "=== ETİKETLER ===", TAGS,
    "=== TÜRKÇE BAŞLIK ===", TR_TITLE, "=== TÜRKÇE AÇIKLAMA ===", TR_DESC, "=== SHORTS BAŞLIKLARI ===", "\n".join(SHORTS)])
out = os.path.join(ROOT, "cikti", "onay", "youtube_bilgileri.txt")
open(out, "w", encoding="utf-8").write(txt)
print(out)
