#!/usr/bin/env python3
"""Onay videosu için kopyalanabilir YouTube bilgileri (EN + TR). Çıktı: cikti/onay/youtube_bilgileri.txt"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

ch = bolumler.chapters(os.path.join(ROOT, "cikti", "basilisk", "basilisk_long_en.srt"),
                       json.load(open(os.path.join(ROOT, "senaryolar", "basilisk_bolumler.json"), encoding="utf-8")))
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)
SRC = ("Roko, LessWrong post (July 2010) · Eliezer Yudkowsky, later comments (2014) · D. Auerbach, Slate (2014) · Pliny the Elder, Natural History 8.33 · "
       "David Langford, \"BLIT\", Interzone (1988) · Streisand v. Adelman (2003) · Pascal, Pensées (1670) · "
       "Wegner, Schneider, Carter & White (1987), JPSP · Bostrom, \"Information Hazards\" (2011)")

EN_TITLE = "Roko's Basilisk: The Thought Experiment That Was Banned for 5 Years"
TR_TITLE = "Roko'nun Basiliski: 5 Yıl Boyunca Yasaklanan Düşünce Deneyi"
EN_DESC = f"""In 2010, a short post about AI was deleted within hours — and discussing it was banned for five years. Its claim: simply knowing about it might put you at risk.

Here's how Roko's Basilisk works, why almost every philosopher thinks it falls apart (Pascal's Wager, the many-gods problem, why blackmail fails), and why your brain finds it so hard to forget (the white bear experiment).

Don't worry — by the end, you'll see why it's toothless.

⏱ Chapters
{ch_en}

📚 Sources
{SRC}

Narration is AI-generated; all illustrations are original. Basilisk engraving (1640): public domain, via Wikimedia Commons.

#rokosbasilisk #philosophy #psychology"""
TR_DESC = f"""2010'da yapay zekâ hakkında kısa bir gönderi birkaç saat içinde silindi ve konuyu tartışmak beş yıl boyunca yasaklandı. İddiası şuydu: Sadece onu bilmek bile seni risk altına sokabilir.

Roko'nun Basiliski nasıl işliyor, neden neredeyse her filozof çöktüğünü düşünüyor (Pascal'ın bahsi, birçok tanrı sorunu, şantajın neden işe yaramadığı) ve beynin onu unutmakta neden zorlanıyor (beyaz ayı deneyi)?

Merak etme, videonun sonunda neden dişsiz olduğunu göreceksin.

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SRC}

Seslendirme yapay zekâ ile üretilmiştir; tüm çizimler özgündür. Basilisk gravürü (1640): kamu malı, Wikimedia Commons.

#rokosbasilisk #felsefe #psikoloji"""
TAGS = ("rokos basilisk, roko's basilisk, thought experiment, philosophy, AI, artificial intelligence, pascal's wager, streisand effect, "
        "white bear experiment, ironic process theory, information hazard, lesswrong, decision theory, psychology, roko'nun basiliski, felsefe")
SHORTS = ["This Thought Experiment Was Banned for 5 Years 🐍 #shorts", "How a Deleted Post Became a Legend (The Streisand Effect) #shorts",
          "Roko's Basilisk Is Just Pascal's Wager With a Robot 🤖 #shorts", "Don't Think of a White Bear 🐻‍❄️ #shorts"]
txt = "\n\n".join([
    "=== İNGİLİZCE BAŞLIK ===", EN_TITLE, "=== İNGİLİZCE AÇIKLAMA ===", EN_DESC, "=== ETİKETLER ===", TAGS,
    "=== TÜRKÇE BAŞLIK ===", TR_TITLE, "=== TÜRKÇE AÇIKLAMA ===", TR_DESC, "=== SHORTS BAŞLIKLARI ===", "\n".join(SHORTS)])
out = os.path.join(ROOT, "cikti", "basilisk", "youtube_bilgileri.txt")
open(out, "w", encoding="utf-8").write(txt)
print(out)
