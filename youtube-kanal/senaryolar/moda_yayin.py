#!/usr/bin/env python3
"""Moda videosu için kopyalanabilir YouTube bilgileri (EN + TR). Çıktı: cikti/moda/youtube_bilgileri.txt"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

ch = bolumler.chapters(os.path.join(ROOT, "cikti", "moda", "moda_long_en.srt"),
                       json.load(open(os.path.join(ROOT, "senaryolar", "moda_bolumler.json"), encoding="utf-8")))
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)
SRC = ("Toups et al. (2011), Mol. Biol. Evol. · Sehasseh et al. (2021), Science Advances · Henshilwood et al. (2004), Science · "
       "O'Sullivan et al. (2016), Scientific Reports · Samadelli et al. (2015) · Pliny, Natural History IX · Elizabeth I, Statutes of Apparel (1574) · "
       "Mahmud II dress reform (1829) · Turkish Hat Law No. 671 (1925) · Semmelhack, Standing Tall (Bata Shoe Museum, 2015) · Simmel, Fashion (1904) · "
       "Adam & Galinsky (2012), JESP · Veblen, The Theory of the Leisure Class (1899) · Zahavi (1975) · Ellen MacArthur Foundation, A New Textiles Economy (2017) · Rana Plaza (2013)")

EN_TITLE = "Why Did Humans Invent Fashion? (It Was Never About Warmth)"
TR_TITLE = "İnsanlar Modayı Neden İcat Etti? (Mesele Hiç Sıcaklık Değildi)"
EN_DESC = f"""Lice tell us humans started wearing clothes about 170,000 years ago. But warmth explains clothing — it doesn't explain fashion.

Why do we pay thousands for a logo, wear shoes that hurt, and throw away clothes that still work? From 150,000-year-old shell beads and the Iceman's wardrobe, to purple only emperors could wear, the fez and Turkey's 1925 Hat Law, high heels invented for men, Simmel's theory of imitation and distinction, the lab-coat experiment, the peacock's tail and fast fashion.

⏱ Chapters
{ch_en}

📚 Sources
{SRC}

Narration is AI-generated; illustrations are original. Images via Wikimedia Commons: Justinian mosaic, San Vitale (Steven Zucker, CC BY 2.0); Louis XIV by Rigaud (CC0); Ötzi clothing reconstruction, Archeoparc (Wolfgang Sauber, CC BY-SA 3.0); Mahmud II (public domain); Bolinus brandaris (H. Zell, CC BY-SA 3.0); Peacock display (Rohit Sharma, CC BY-SA 4.0).

#fashion #history #psychology"""
TR_DESC = f"""Bitler bize insanların yaklaşık 170 bin yıl önce giysi giymeye başladığını söylüyor. Ama sıcaklık giysiyi açıklıyor, modayı açıklamıyor.

Neden bir logoya binlerce lira ödüyoruz, ayak acıtan ayakkabılar giyiyoruz ve hâlâ işe yarayan kıyafetleri atıyoruz? 150 bin yıllık kabuk boncuklardan Buzadam'ın gardırobuna, sadece imparatorların giyebildiği mordan fese ve 1925 Şapka Kanunu'na, erkekler için icat edilen topuklu ayakkabılara, Simmel'in taklit ve farklılık kuramına, önlük deneyine, tavus kuşunun kuyruğuna ve hızlı modaya.

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SRC}

Seslendirme yapay zekâ ile üretilmiştir; çizimler özgündür. Görseller Wikimedia Commons'tan (lisanslar İngilizce açıklamada).

#moda #tarih #psikoloji"""
TAGS = ("why fashion exists, history of fashion, fashion psychology, sumptuary laws, Tyrian purple, fez, Hat Law 1925, Şapka Kanunu, high heels history, "
        "Louis XIV, Georg Simmel, conspicuous consumption, Veblen, handicap principle, enclothed cognition, fast fashion, Ötzi, history, psychology, moda tarihi")
SHORTS = ["Lice Tell Us When Humans Started Wearing Clothes 🔬 #shorts", "We Wore Jewelry Before We Wore Clothes? 🐚 #shorts",
          "What a 5,300-Year-Old Man Wore (Ötzi) 🧊 #shorts", "Purple Was Illegal (For You) 👑 #shorts", "The Fez, the Hat, and the Law 🇹🇷 #shorts",
          "High Heels Were Invented for Men 👠 #shorts", "Why Fashion HAS to Change #shorts", "Can a Lab Coat Change How You Think? 🥼 #shorts",
          "Why Logos Exist (The Peacock Principle) 🦚 #shorts", "The Real Cost of Fast Fashion #shorts", "Try This: What Is Your Outfit Saying? #shorts"]
txt = "\n\n".join([
    "=== İNGİLİZCE BAŞLIK ===", EN_TITLE, "=== İNGİLİZCE AÇIKLAMA ===", EN_DESC, "=== ETİKETLER ===", TAGS,
    "=== TÜRKÇE BAŞLIK ===", TR_TITLE, "=== TÜRKÇE AÇIKLAMA ===", TR_DESC, "=== SHORTS BAŞLIKLARI ===", "\n".join(SHORTS)])
out = os.path.join(ROOT, "cikti", "moda", "youtube_bilgileri.txt")
open(out, "w", encoding="utf-8").write(txt)
print(out)
