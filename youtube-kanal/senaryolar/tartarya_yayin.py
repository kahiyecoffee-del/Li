#!/usr/bin/env python3
"""Tartarya videosu için kopyalanabilir YouTube bilgileri (EN + TR). Çıktı: cikti/tartarya/youtube_bilgileri.txt"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

ch = bolumler.chapters(os.path.join(ROOT, "cikti", "tartarya", "tartarya_long_en.srt"),
                       json.load(open(os.path.join(ROOT, "senaryolar", "tartarya_bolumler.json"), encoding="utf-8")))
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)
SRC = ("Ortelius, Theatrum Orbis Terrarum (1570) · Encyclopaedia Britannica, 1st ed. (1768–71), \"Tartary\" · Matthew Paris, Chronica Majora · "
       "HistoryLink.org: Seattle regrade after the 1889 fire · Encyclopedia of Chicago: \"Raising Chicago\" · Duffy, Siege Warfare (1979) · UNESCO: Fortifications of Vauban · "
       "World's Columbian Exposition (1893) & 1894 fire · Wardenclyffe Tower (1901–1917) · National Orphan Train Complex; Holt, The Orphan Trains (1992) · "
       "Douglas, Sutton & Cichocka (2017) · Leman & Cinnirella (2007) · Mongol Empire, Golden Horde, Silk Road")

EN_TITLE = "Tartaria: The Empire Erased From History? (Following Every Clue)"
TR_TITLE = "Tartarya: Tarihten Silinen Dev İmparatorluk mu? (Tüm İpuçlarını Takip Ettik)"
EN_DESC = f"""A vast empire with domed palaces, star forts and free-energy towers — wiped out by a "mud flood" and erased from history? Millions of people believe the Tartaria theory. So we followed every clue: old maps, buried buildings, star forts, spires, Chicago's vanished White City and the orphan trains.

Then we checked the records. What we found is stranger, and more interesting, than the myth — including the real "Tartary," home of the Mongol Empire and the Golden Horde.

⏱ Chapters
{ch_en}

📚 Sources
{SRC}

This video examines a popular conspiracy theory and compares its claims with historical evidence. Narration is AI-generated; illustrations are original. Images via Wikimedia Commons: Court of Honor, World's Columbian Exposition (public domain); Bourtange aerial (Capital Press Schiphol / RCE, CC BY-SA 4.0); Palmanova aerial (Carsten Steger, CC BY-SA 4.0); Seattle Underground (Ronincmc, CC BY-SA 4.0); Raising the Briggs House (public domain); Wardenclyffe Tower (public domain).

#tartaria #history #mystery"""
TR_DESC = f"""Kubbeli sarayları, yıldız kaleleri ve bedava enerji kuleleri olan, bir "çamur seli"yle yok edilip tarihten silinmiş devasa bir imparatorluk mu? Milyonlarca insan Tartarya teorisine inanıyor. Biz de tüm ipuçlarını takip ettik: eski haritalar, gömülü binalar, yıldız kaleler, kuleler, Chicago'nun kaybolan Beyaz Şehri ve yetim trenleri.

Sonra kayıtlara baktık. Bulduğumuz şey efsaneden daha tuhaf ve daha ilginç; Moğol İmparatorluğu'na ve Altın Orda'ya ev sahipliği yapan gerçek "Tartarya" da dahil.

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SRC}

Bu video popüler bir komplo teorisini inceliyor ve iddialarını tarihsel kanıtlarla karşılaştırıyor. Seslendirme yapay zekâ ile üretilmiştir; çizimler özgündür. Görseller Wikimedia Commons'tan (lisanslar İngilizce açıklamada).

#tartarya #tarih #gizem"""
TAGS = ("tartaria, tartarian empire, tartaria explained, mud flood, star forts, lost civilization, hidden history, conspiracy theory, white city 1893, "
        "orphan trains, Seattle Underground, raising Chicago, Golden Horde, Mongol Empire, Tatars, Tartary map, mystery, history, tartarya, altın orda")
SHORTS = ["The Empire Erased From History? 🗺️ #tartaria #shorts", "Why Do Old Maps Say \"Tartaria\"? #shorts", "Why Are These Windows Underground? 🏚️ #mudflood #shorts",
          "Star Forts: Weapons or Machines? ⭐ #shorts", "Free Energy Towers on Old Buildings? ⚡ #shorts", "The City That Vanished in Two Years #shorts",
          "The Darkest Tartaria Theory 🚂 #shorts", "Tartaria on Old Maps: Solved ✅ #shorts", "The \"Mud Flood\" Solved: Chicago Lifted Entire Buildings #shorts",
          "Star Forts & the White City: Solved #shorts", "Why Conspiracy Theories Feel So Convincing 🧠 #shorts", "The REAL Tartaria Was Even Bigger #shorts"]
txt = "\n\n".join([
    "=== İNGİLİZCE BAŞLIK ===", EN_TITLE, "=== İNGİLİZCE AÇIKLAMA ===", EN_DESC, "=== ETİKETLER ===", TAGS,
    "=== TÜRKÇE BAŞLIK ===", TR_TITLE, "=== TÜRKÇE AÇIKLAMA ===", TR_DESC, "=== SHORTS BAŞLIKLARI ===", "\n".join(SHORTS)])
out = os.path.join(ROOT, "cikti", "tartarya", "youtube_bilgileri.txt")
open(out, "w", encoding="utf-8").write(txt)
print(out)
