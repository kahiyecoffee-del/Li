#!/usr/bin/env python3
"""NVIDIA videosu için kopyalanabilir YouTube bilgileri (EN + TR). Çıktı: cikti/nvidia/youtube_bilgileri.txt"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

ch = bolumler.chapters(os.path.join(ROOT, "cikti", "nvidia", "nvidia_long_en.srt"),
                       json.load(open(os.path.join(ROOT, "senaryolar", "nvidia_bolumler.json"), encoding="utf-8")))
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)
SRC = ("Wikipedia: Jensen Huang · Fortune (2024) · NVIDIA GeForce 256 (1999), CUDA (2006) · Krizhevsky, Sutskever & Hinton (2012), AlexNet · "
       "NVIDIA $5T market cap (Oct 29, 2025) · U.S. AI chip export controls (2022–) · C4ADS (Sep 2026) · IEA, Energy and AI (2025) · "
       "Carlyle, On Heroes (1840) · Spencer, The Study of Sociology (1873) · Thorndike (1920), halo effect · "
       "Scandal coverage, Nov 8–12, 2026: NVIDIA Board statement; CNN; NBC; CNBC; Al Jazeera; TechCrunch; CBS News; The Wall Street Journal (as reported); Tom's Hardware")

EN_TITLE = "Jensen Huang & NVIDIA: How One Man Became a Single Point of Failure for the AI Age"
TR_TITLE = "Jensen Huang ve NVIDIA: Bir Adam Yapay Zekâ Çağının Tek Hata Noktası Nasıl Oldu?"
EN_DESC = f"""He washed dishes at Denny's. Decades later, the company he co-founded at a Denny's booth became the first in history worth $5 trillion — and this week, according to reports, its board was discussing whether to remove him.

How did a gaming-chip company end up powering most of the world's AI? Why does NVIDIA matter for markets, geopolitics and energy? And what does the November 2026 crisis teach us about "great man" thinking, the halo effect and key-person risk?

⚠ This is a developing story. The scandal section reflects reporting as of November 12, 2026. Allegations are attributed to their sources; no one named has been charged, and the companies involved deny wrongdoing.

⏱ Chapters
{ch_en}

📚 Sources
{SRC}

Narration is AI-generated; illustrations are original. Photos via Wikimedia Commons: Jensen Huang at Stanford (Anderseidesvik, CC BY-SA 4.0); GeForce 256 (Konstantin Lanzet, CC BY-SA 3.0); NVIDIA HQ (Coolcaesar, CC BY-SA 4.0); Denny's (Alexis Doine, CC0); data center (Carl Lender, CC BY 2.0); TSMC Fab 12A (曾 成訓, CC BY 2.0); GTX 580 chip (Fritzchens Fritz, CC0); Edward Thorndike (public domain).

#nvidia #jensenhuang #ai"""
TR_DESC = f"""Denny's'te bulaşık yıkadı. On yıllar sonra bir Denny's masasında kurduğu şirket, tarihte 5 trilyon dolara ulaşan ilk şirket oldu. Bu hafta ise haberlere göre yönetim kurulu onu görevden almayı tartışıyordu.

Bir oyun çipi şirketi nasıl oldu da dünyadaki yapay zekânın büyük kısmını çalıştırır hale geldi? NVIDIA piyasalar, jeopolitik ve enerji için neden bu kadar önemli? Kasım 2026 krizi bize "büyük adam" düşüncesi, hale etkisi ve kilit kişi riski hakkında ne öğretiyor?

⚠ Bu gelişmekte olan bir haber. Skandal bölümü 12 Kasım 2026 itibarıyla çıkan haberleri yansıtıyor. İddialar kaynaklarına atfedilmiştir. Adı geçen kimse suçlanmamıştır ve ilgili şirketler herhangi bir yanlışı reddetmektedir.

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SRC}

Seslendirme yapay zekâ ile üretilmiştir; çizimler özgündür. Fotoğraflar Wikimedia Commons'tan (lisanslar İngilizce açıklamada).

#nvidia #jensenhuang #yapayzeka"""
TAGS = ("nvidia, jensen huang, nvidia scandal, nvidia ceo, nvidia stock, AI chips, GPU, CUDA, AlexNet, AI boom, $5 trillion, "
        "chip war, US China chips, TSMC, single point of failure, key person risk, halo effect, great man theory, psychology, history, yapay zeka")
SHORTS = ["From Denny's Dishwasher to a $5 Trillion Company 🍽️➡️💰 #shorts", "\"Our Company Is 30 Days From Going Out of Business\" #nvidia #shorts",
          "Two Gaming Cards Started the AI Revolution 🎮🧠 #shorts", "Why We Turn CEOs Into Gods (The Halo Effect) #shorts"]
txt = "\n\n".join([
    "=== İNGİLİZCE BAŞLIK ===", EN_TITLE, "=== İNGİLİZCE AÇIKLAMA ===", EN_DESC, "=== ETİKETLER ===", TAGS,
    "=== TÜRKÇE BAŞLIK ===", TR_TITLE, "=== TÜRKÇE AÇIKLAMA ===", TR_DESC, "=== SHORTS BAŞLIKLARI ===", "\n".join(SHORTS)])
out = os.path.join(ROOT, "cikti", "nvidia", "youtube_bilgileri.txt")
open(out, "w", encoding="utf-8").write(txt)
print(out)
