#!/usr/bin/env python3
"""Spor videosu için kopyalanabilir YouTube bilgileri (EN + TR). Çıktı: cikti/spor/youtube_bilgileri.txt"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

ch = bolumler.chapters(os.path.join(ROOT, "cikti", "spor", "spor_long_en.srt"),
                       json.load(open(os.path.join(ROOT, "senaryolar", "spor_bolumler.json"), encoding="utf-8")))
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)
SRC = ("Wilbert-Lampen et al. (2008), NEJM · Procopius, Wars I.24 (Nika riots, 532) · Rizzolatti et al. (1996) · Aglioti et al. (2008), Nature Neuroscience · "
       "Schultz, Dayan & Montague (1997), Science · Rottenberg (1956) · Cialdini et al. (1976), JPSP · Snyder, Lassegard & Ford (1986) · "
       "Tajfel (1970); Tajfel & Turner (1979) · Bernhardt et al. (1998), Physiology & Behavior · Hastorf & Cantril (1954) · Elias & Dunning, Quest for Excitement (1986)")

EN_TITLE = "Why Do We Love Watching Sports? (The Psychology of Fans)"
TR_TITLE = "Spor İzlemek Bize Neden Bu Kadar Keyif Veriyor? (Taraftar Psikolojisi)"
EN_DESC = f"""During the 2006 World Cup, cardiac emergencies among German fans more than doubled on match days. They weren't playing. They were watching.

Why do billions of us feel joy, rage and heartbreak over strangers chasing a ball? From the chariot fans who nearly toppled an empire in Istanbul in 532, to mirror neurons, dopamine and the thrill of not knowing the ending, to why we say "we won" but "they lost," why our brains are built for tribes, and why every fan is sure the referee is against them.

⏱ Chapters
{ch_en}

📚 Sources
{SRC}

Narration is AI-generated; illustrations are original. Images via Wikimedia Commons: Hippodrome of Constantinople (Ank Kumar, CC BY-SA 4.0); Stadium of Olympia (Annatsach, CC BY-SA 4.0); Circus Maximus (public domain); Kandinsky, Composition VIII (public domain); Klee, Garden Plan (public domain).

#psychology #sports #football"""
TR_DESC = f"""2006 Dünya Kupası'nda Alman taraftarlar arasındaki kalp acilleri maç günlerinde iki katından fazla arttı. Oynamıyorlardı. İzliyorlardı.

Milyarlarca insan neden bir topun peşinden koşan yabancılar için sevinç, öfke ve hayal kırıklığı yaşıyor? 532'de İstanbul'da neredeyse bir imparatorluğu deviren araba yarışı taraftarlarından ayna nöronlara, dopamine ve sonu bilmemenin heyecanına; neden "kazandık" ama "kaybettiler" dediğimize, beynimizin neden kabileler için yapıldığına ve her taraftarın neden hakemin kendisine karşı olduğundan emin olduğuna.

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SRC}

Seslendirme yapay zekâ ile üretilmiştir; çizimler özgündür. Görseller Wikimedia Commons'tan (lisanslar İngilizce açıklamada).

#psikoloji #futbol #spor"""
TAGS = ("why we love sports, sports psychology, fan psychology, football fans, basking in reflected glory, social identity theory, mirror neurons, "
        "dopamine, Nika riots, Hippodrome Istanbul, They Saw a Game, referee bias, Tajfel, Cialdini, psychology, history, taraftar psikolojisi, futbol")
SHORTS = ["Watching Football Can Literally Break Your Heart ❤️ #shorts", "Sports Fans Almost Destroyed an Empire (Istanbul, 532) 🏟️ #shorts",
          "Your Brain Plays the Game Too 🧠 #shorts", "Why a Last-Minute Goal Feels Like an Explosion ⚽ #shorts",
          "\"We Won.\" \"They Lost.\" The Psychology of Fans #shorts", "Your Brain Picks a Team in Seconds #shorts",
          "Why Every Fan Thinks the Referee Hates Their Team #shorts", "Sport Is a Safe War #shorts", "Try This During Your Next Match #shorts"]
txt = "\n\n".join([
    "=== İNGİLİZCE BAŞLIK ===", EN_TITLE, "=== İNGİLİZCE AÇIKLAMA ===", EN_DESC, "=== ETİKETLER ===", TAGS,
    "=== TÜRKÇE BAŞLIK ===", TR_TITLE, "=== TÜRKÇE AÇIKLAMA ===", TR_DESC, "=== SHORTS BAŞLIKLARI ===", "\n".join(SHORTS)])
out = os.path.join(ROOT, "cikti", "spor", "youtube_bilgileri.txt")
open(out, "w", encoding="utf-8").write(txt)
print(out)
