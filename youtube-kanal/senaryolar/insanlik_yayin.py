#!/usr/bin/env python3
"""İnsanlık videosu için kopyalanabilir YouTube bilgileri (EN + TR). Çıktı: cikti/insanlik/youtube_bilgileri.txt"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

ch = bolumler.chapters(os.path.join(ROOT, "cikti", "insanlik", "insanlik_long_en.srt"),
                       json.load(open(os.path.join(ROOT, "senaryolar", "insanlik_bolumler.json"), encoding="utf-8")))
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)
SRC = ("Bonhommeau et al. (2013), PNAS, human trophic level · Brain, The Hunters or the Hunted? (1981) · O'Neill et al. (2017), PNAS · "
       "Wrangham, Catching Fire (2009) · Aiello & Wheeler (1995) · Bramble & Lieberman (2004), Nature · Roach et al. (2013), Nature · "
       "Henrich, The Secret of Our Success (2016) · Horner & Whiten (2005) · Tomasello, Why We Cooperate (2009) · Dunbar (1992) · "
       "Göbekli Tepe (DAI excavations) · Bar-On, Phillips & Milo (2018), PNAS, biomass distribution on Earth")

EN_TITLE = "Humans Aren't at the Top of the Food Chain. So How Did We Win?"
TR_TITLE = "İnsanlık Neden Bu Kadar Başarılı? Besin Zincirinin Tepesine Nasıl Çıktık?"
EN_DESC = f"""Two million years ago, leopards were dragging our ancestors into caves. Today there are 8 billion of us — but according to science, our place in the food chain is about the same as an anchovy's.

So how did a weak, slow ape take over the planet? Fire and cooking, running animals to exhaustion, a shoulder built like a catapult — and above all, something you can't see in a skeleton: we learn from each other, and the knowledge adds up. With the tragic story of Burke and Wills, children who copy useless steps, and Göbekli Tepe, built before farming.

⏱ Chapters
{ch_en}

📚 Sources
{SRC}

Narration is AI-generated; illustrations are original. Images via Wikimedia Commons: Göbekli Tepe (Dosseman, CC BY-SA 4.0); Burke & Wills departure, engraving after N. Chevalier (public domain); Death of Wills, S. T. Gill (public domain); Woolly mammoths, Charles R. Knight (public domain).

#history #evolution #psychology"""
TR_DESC = f"""İki milyon yıl önce leoparlar atalarımızı mağaralara sürüklüyordu. Bugün 8 milyarız; ama bilime göre besin zincirindeki yerimiz kabaca bir hamsiyle aynı.

Peki zayıf, yavaş bir maymun gezegeni nasıl ele geçirdi? Ateş ve pişirme, hayvanları yorgunluktan yığılana kadar kovalamak, mancınık gibi çalışan bir omuz ve hepsinden önemlisi, bir iskelette göremeyeceğin bir şey: birbirimizden öğreniyoruz ve bilgi birikiyor. Burke ve Wills'in trajik hikâyesi, gereksiz adımları bile kopyalayan çocuklar ve tarımdan önce inşa edilen Göbeklitepe ile.

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SRC}

Seslendirme yapay zekâ ile üretilmiştir; çizimler özgündür. Görseller Wikimedia Commons'tan (lisanslar İngilizce açıklamada).

#tarih #evrim #psikoloji"""
TAGS = ("human evolution, food chain, how humans took over the world, trophic level, cooking hypothesis, persistence hunting, cumulative culture, "
        "Burke and Wills, overimitation, Gobekli Tepe, Göbeklitepe, cooperation, Joseph Henrich, Richard Wrangham, history, psychology, anthropology, insanlık tarihi")
SHORTS = ["Humans Are NOT at the Top of the Food Chain 🐟 #shorts", "On Paper, Humans Are Terribly Designed #shorts", "Fire Made Us Human 🔥 #shorts",
          "We Hunted by Running Animals to Death 🏃 #shorts", "They Had Money and Maps. They Still Starved. #shorts",
          "Why Kids Copy Useless Steps (and Chimps Don't) #shorts", "Built Before Farming: Göbekli Tepe 🇹🇷 #shorts",
          "Only 4% of Mammals on Earth Are Wild #shorts", "Try This: Count What You Could Make Yourself #shorts"]
txt = "\n\n".join([
    "=== İNGİLİZCE BAŞLIK ===", EN_TITLE, "=== İNGİLİZCE AÇIKLAMA ===", EN_DESC, "=== ETİKETLER ===", TAGS,
    "=== TÜRKÇE BAŞLIK ===", TR_TITLE, "=== TÜRKÇE AÇIKLAMA ===", TR_DESC, "=== SHORTS BAŞLIKLARI ===", "\n".join(SHORTS)])
out = os.path.join(ROOT, "cikti", "insanlik", "youtube_bilgileri.txt")
open(out, "w", encoding="utf-8").write(txt)
print(out)
