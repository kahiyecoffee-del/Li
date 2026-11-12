#!/usr/bin/env python3
"""Diktatörlük videosu için kopyalanabilir YouTube bilgileri (EN + TR). Çıktı: cikti/diktator/youtube_bilgileri.txt"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

ch = bolumler.chapters(os.path.join(ROOT, "cikti", "diktator", "diktator_long_en.srt"),
                       json.load(open(os.path.join(ROOT, "senaryolar", "diktator_bolumler.json"), encoding="utf-8")))
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)
SRC = ("La Boétie, Discourse on Voluntary Servitude (c. 1548) · Livy, Ab Urbe Condita III · Fromm, Escape from Freedom (1941) · Hobbes, Leviathan (1651) · "
       "Stenner, The Authoritarian Dynamic (2005) · Hasher, Goldstein & Toppino (1977) · Milgram (1963); Perry, Behind the Shock Machine (2012); Burger (2009) · "
       "Enabling Act (March 23, 1933) · Levitsky & Ziblatt, How Democracies Die (2018) · Kuran, Private Truths, Public Lies (1995) · "
       "Ceaușescu's last speech (Dec 21, 1989) · Chenoweth & Stephan, Why Civil Resistance Works (2011)")

EN_TITLE = "Why Do We Let Dictators Rise? (The Psychology of Power)"
TR_TITLE = "Diktatörlere Neden İzin Veriyoruz? (Gücün Psikolojisi)"
EN_DESC = f"""A tyrant has only two eyes and two hands. So how does one person end up ruling millions? In 1548, a young law student asked this question — and history, psychology and philosophy still give uncomfortable answers.

From Rome's six-month dictators and Caesar's "dictator for life," to Fromm's Escape from Freedom, fear as fuel, the illusory truth effect, the Milgram experiment, democracies that die step by step, and the moment Ceaușescu lost his crowd. And the oldest answer of all: power was always ours to give — and ours to take back.

⏱ Chapters
{ch_en}

📚 Sources
{SRC}

This is an educational video about history and psychology; it does not refer to any current government or politician. Narration is AI-generated; illustrations are original. Images via Wikimedia Commons: Cicero Denounces Catiline, Cesare Maccari (public domain); Cincinnatus, J. A. Ribera (public domain); Julius Caesar, Tusculum portrait (public domain); Leviathan frontispiece, Abraham Bosse (public domain); Milgram recruitment ad (public domain); Montaigne & La Boétie engraving (Cinokat, CC BY-SA 4.0).

#psychology #history #philosophy"""
TR_DESC = f"""Bir tiranın yalnızca iki gözü ve iki eli var. Peki tek bir kişi nasıl oluyor da milyonları yönetiyor? 1548'de genç bir hukuk öğrencisi bu soruyu sordu; tarih, psikoloji ve felsefe hâlâ rahatsız edici cevaplar veriyor.

Roma'nın altı aylık diktatörlerinden Sezar'ın "ömür boyu diktatörlüğüne", Fromm'un Özgürlükten Kaçış'ından yakıt olarak korkuya, yanıltıcı doğruluk etkisine, Milgram deneyine, adım adım ölen demokrasilere ve Çavuşesku'nun kalabalığı kaybettiği ana kadar. Ve en eski cevap: Güç her zaman vermesi de geri alması da bize ait olan bir şeydi.

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SRC}

Bu video tarih ve psikoloji üzerine eğitsel bir içeriktir; günümüzdeki herhangi bir hükümete ya da siyasetçiye atıfta bulunmaz. Seslendirme yapay zekâ ile üretilmiştir; çizimler özgündür. Görseller Wikimedia Commons'tan (lisanslar İngilizce açıklamada).

#psikoloji #tarih #felsefe"""
TAGS = ("why do we let dictators rise, psychology of power, authoritarianism, dictatorship history, La Boetie voluntary servitude, Roman dictator, Cincinnatus, "
        "Erich Fromm escape from freedom, Hobbes Leviathan, Milgram experiment, illusory truth effect, how democracies die, preference falsification, Ceausescu, "
        "nonviolent resistance, psychology, history, philosophy, diktatörlük, otoriterlik")
SHORTS = ["A Tyrant Has Only Two Hands #shorts", "\"Dictator\" Was a 6-Month Job in Rome 🏛️ #shorts", "How Rome Lost Its Republic #shorts",
          "Why Freedom Feels Like a Burden #shorts", "Hobbes: We Trade Freedom for Safety #shorts", "Fear Is the Fuel of Dictators #shorts",
          "Repeat a Lie Often Enough... (Illusory Truth Effect) #shorts", "The Milgram Experiment: 2 out of 3 Went All the Way ⚡ #shorts",
          "Most Dictatorships Don't Start With Tanks #shorts", "The Boiling Frog Is a Myth 🐸 #shorts", "The Moment a Dictator Lost His Crowd #shorts",
          "\"Resolve to Serve No More\" #shorts", "Try This: Is the Silence Real? #shorts"]
txt = "\n\n".join([
    "=== İNGİLİZCE BAŞLIK ===", EN_TITLE, "=== İNGİLİZCE AÇIKLAMA ===", EN_DESC, "=== ETİKETLER ===", TAGS,
    "=== TÜRKÇE BAŞLIK ===", TR_TITLE, "=== TÜRKÇE AÇIKLAMA ===", TR_DESC, "=== SHORTS BAŞLIKLARI ===", "\n".join(SHORTS)])
out = os.path.join(ROOT, "cikti", "diktator", "youtube_bilgileri.txt")
open(out, "w", encoding="utf-8").write(txt)
print(out)
