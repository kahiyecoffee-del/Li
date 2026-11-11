#!/usr/bin/env python3
"""Solipsizm videosu için YouTube yükleme bilgileri (EN + TR başlık/açıklama/etiket, bölümler, kapak).

Çalıştır: python3 senaryolar/solipsizm_yayin.py  ->  cikti/solipsizm/youtube_bilgileri.md
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "araclar"))
import bolumler  # noqa: E402

srt = os.path.join(ROOT, "cikti", "solipsizm", "solipsizm_long_en.srt")
defs = json.load(open(os.path.join(ROOT, "senaryolar", "solipsizm_bolumler.json"), encoding="utf-8"))
ch = bolumler.chapters(srt, defs)
ch_en = "\n".join(f"{bolumler.fmt(t)} {d['en']}" for t, d in ch)
ch_tr = "\n".join(f"{bolumler.fmt(t)} {d['tr']}" for t, d in ch)

SOURCES = ("Descartes, Meditations (1641) · Berkeley, Principles of Human Knowledge (1710) · Boswell, Life of Johnson (6 Aug 1763) · "
           "J. S. Mill, An Examination of Sir William Hamilton's Philosophy (1865) · Chalmers, The Conscious Mind (1996) · "
           "Wimmer & Perner (1983); Baron-Cohen, Leslie & Frith (1985) · Gold & Gold, Cognitive Neuropsychiatry (2012) · "
           "Russell, Human Knowledge (1948) · Wittgenstein, Tractatus 5.62 (1921), Philosophical Investigations §243ff (1953) · "
           "Putnam, Reason, Truth and History (1981) · Bostrom, \"Are You Living in a Computer Simulation?\" (2003) · "
           "Hume, Treatise 1.4.7 · Vasubandhu, Twenty Verses · Zhuangzi, ch. 2")

EN_TITLE = "Can You Prove Anyone Else Exists? | Solipsism Explained"
EN_ALT = ["The Only Thing You Can Be Sure Exists (Solipsism)", "Why You Can't Prove Other People Are Real",
          "Solipsism: The Philosophy That Nobody Can Disprove"]
TR_TITLE = "Başka Birinin Var Olduğunu Kanıtlayabilir misin? | Solipsizm"
TR_ALT = ["Var Olduğundan Emin Olabileceğin Tek Şey: Solipsizm", "Diğer İnsanların Gerçek Olduğunu Kanıtlayamazsın"]

EN_DESC = f"""There is only one thing you can be absolutely sure exists — and it isn't this video.

Solipsism is the idea that only your own mind is certain. From Gorgias and Zhuangzi's butterfly dream to Descartes's evil demon, Samuel Johnson kicking a stone, the Sally–Anne test, Wittgenstein and the brain in a vat — this is the strange 2,500-year history of a question nobody has fully answered: can you prove anyone else is real?

⏱ Chapters
{ch_en}

📚 Sources
{SOURCES}

Note: the psychology section is for education only and is not medical advice. Narration is AI-generated; all illustrations are original.
Portraits: public-domain works via Wikimedia Commons.

#philosophy #solipsism #psychology"""

TR_DESC = f"""Var olduğundan kesinlikle emin olabileceğin tek bir şey var… ve o şey bu video değil.

Solipsizm, yalnızca kendi zihninin kesin olduğu fikridir. Gorgias'tan ve Zhuangzi'nin kelebek rüyasından Descartes'ın kötü iblisine, Samuel Johnson'ın taşa attığı tekmeye, Sally–Anne testine, Wittgenstein'a ve fıçıdaki beyne kadar; kimsenin tam olarak cevaplayamadığı bir sorunun 2.500 yıllık tuhaf hikâyesi: Başka birinin gerçek olduğunu kanıtlayabilir misin?

⏱ Bölümler
{ch_tr}

📚 Kaynaklar
{SOURCES}

Not: Psikoloji bölümü yalnızca bilgilendirme amaçlıdır, tıbbi tavsiye değildir. Seslendirme yapay zekâ ile üretilmiştir; tüm çizimler özgündür.
Portreler: Wikimedia Commons üzerinden kamu malı eserler.

#felsefe #solipsizm #psikoloji"""

TAGS_EN = ["solipsism", "philosophy", "solipsism explained", "problem of other minds", "descartes", "i think therefore i am",
           "evil demon", "theory of mind", "sally anne test", "brain in a vat", "simulation theory", "wittgenstein",
           "berkeley", "philosophy documentary", "psychology"]
TAGS_TR = ["solipsizm", "felsefe", "descartes", "düşünüyorum öyleyse varım", "zihin kuramı", "felsefe tarihi", "psikoloji"]

md = f"""# Solipsizm: YouTube yükleme bilgileri

## Dosyalar
- Video: `solipsizm_long_en.mp4` (Google Drive linki aşağıda)
- Altyazılar: `solipsizm_long_en.srt` (İngilizce), `solipsizm_long_en.tr.srt` (Türkçe)
- Kapak: `kapak/kapak_A.jpg`, `kapak_B.jpg`, `kapak_C.jpg` (1280×720)

## Kapak
3 seçenek var. YouTube Studio'da **"Test et ve karşılaştır" (Test & Compare)** ile üçünü birden yükle; YouTube en çok tıklananı otomatik seçer.
Önerim: **A (ONLY YOU EXIST?)**. En kısa ve en net olanı, tek odak noktası var.
Not: YouTube dile göre ayrı kapak desteklemiyor. Kapaklar kısa İngilizce metinle her ülkede çalışacak şekilde tasarlandı.

---

## 🇬🇧 İngilizce (ana dil)
**Başlık:** {EN_TITLE}

Alternatifler: {" / ".join(EN_ALT)}

**Açıklama:**
```
{EN_DESC}
```
**Etiketler:** {", ".join(TAGS_EN)}

---

## 🇹🇷 Türkçe (çeviri olarak eklenecek)
**Başlık:** {TR_TITLE}

Alternatifler: {" / ".join(TR_ALT)}

**Açıklama:**
```
{TR_DESC}
```
**Etiketler:** {", ".join(TAGS_TR)} (YouTube'da etiketler tek liste; İngilizcelerin sonuna ekle)

---

## Türkiye'deki izleyiciye Türkçe başlık nasıl gösterilir?
YouTube başlığı ülkeye göre değil, **izleyicinin YouTube dil ayarına göre** gösterir. Türkiye'deki izleyicilerin neredeyse hepsi Türkçe kullandığı için pratikte aynı sonuç çıkar.
1. YouTube Studio → **Videolar** → videoyu aç → **Ayrıntılar**: video dili **English**, başlık ve açıklama İngilizce.
2. Sol menü → **Altyazılar** → **Dil ekle** → **Turkish**.
3. Turkish satırında:
   - **Başlık ve açıklama** → yukarıdaki Türkçe başlık ve açıklamayı yapıştır → Yayınla.
   - **Altyazılar** → `solipsizm_long_en.tr.srt` dosyasını yükle.
   - **Seslendirme (Dubbing)** → Türkçe dublaj ses dosyası hazır olduğunda buradan yüklenecek. Bu seçenek kanalında görünmüyorsa çok dilli ses özelliği henüz kanalına açılmamış demektir.
"""
out = os.path.join(ROOT, "cikti", "solipsizm", "youtube_bilgileri.md")
open(out, "w", encoding="utf-8").write(md)
print(out)
