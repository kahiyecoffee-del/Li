#!/usr/bin/env python3
"""Solipsizm uzun videosunun senaryosunu (sahne sahne: EN anlatım, TR altyazı, karakalem çizim) üretir.

Çalıştır: python3 senaryolar/solipsizm_uret.py  ->  senaryolar/solipsizm.json
Deneme bölümündeki (solipsizm-deneme.json) ilk sahneler aynen alınır, kalan bölümler burada tanımlıdır.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
deneme = json.load(open(os.path.join(HERE, "solipsizm-deneme.json"), encoding="utf-8"))

# Wikimedia'dan indirilen portreler (bulunamayanlar çizilmiş çerçeveye düşer)
PORTRE = {
    "descartes": "File:Frans Hals, Portrait of René Descartes.jpg",
    "berkeley": "File:Bishop George Berkeley by John Smibert, perhaps 1727, oil on canvas, from the National Portrait Gallery - NPG-8900050A 2.jpg",
}
extra = os.path.join(HERE, "portreler.json")
if os.path.exists(extra):
    PORTRE.update(json.load(open(extra, encoding="utf-8")))


def S(en, tr, sk=None, **kw):
    d = dict(say={"en": en, "tr": tr})
    if sk is not None:
        d["sketch"] = sk
    d.update(kw)
    return d


def P(key, label, en, tr, fallback_text=None):
    """Portre sahnesi: varsa gerçek portre karakalem olarak çizilir, yoksa çizilmiş çerçeve."""
    if key in PORTRE:
        return S(en, tr, image=dict(file=PORTRE[key], style="sketch", fit="contain", label=label, tint=0.3))
    return S(en, tr, [dict(el="portrait_frame", x=0.5, y=0.45, s=1.3, text=fallback_text or label)])


def G(y=0.8):
    return dict(el="ground", x=0.5, y=y, w=0.8)


def T(x, y, text, size=1.0, color="ink", underline=False):
    return dict(el="text", x=x, y=y, text=text, size=size, color=color, underline=underline)


def fig(x, h=0.5, pose="stand", face=1, y=0.8, **kw):
    return dict(el="figure", x=x, y=y, h=h, pose=pose, face=face, **kw)


def arrow(x, y, x2, y2, **kw):
    return dict(el="arrow", x=x, y=y, x2=x2, y2=y2, **kw)


def bubble(x, y, s=0.6, kind="speech", tail=None, **kw):
    return dict(el="bubble", x=x, y=y, s=s, kind=kind, tail=tail, **kw)


def head(x, y, s=0.6, **kw):
    return dict(el="head", x=x, y=y, s=s, **kw)


scenes = list(deneme["scenes"])  # açılış + bölüm 1 + bölüm 2 (Zhuangzi'ye kadar)

# ---------------------------------------------------------------- Doğu felsefesi
scenes += [
    S("Meanwhile, in India, a similar question took a different path.",
      "Bu sırada Hindistan'da benzer bir soru farklı bir yol izledi.",
      [G(), fig(0.5, 0.42, "sit"), T(0.5, 0.12, "India", 1.1, underline="red")]),
    S("Around the fourth or fifth century, the Buddhist philosopher *Vasubandhu* wrote a short text known as the *Twenty Verses*.",
      "Dördüncü ya da beşinci yüzyıl civarında Budist filozof *Vasubandhu*, *Yirmi Dize* olarak bilinen kısa bir metin yazdı.",
      [G(), fig(0.3, 0.42, "sit"), dict(el="scroll", x=0.66, y=0.42, s=1.0, text="Twenty Verses"), T(0.3, 0.12, "Vasubandhu · 4th–5th c.", 0.7)]),
    S("His school, *Yogācāra*, is often called \"consciousness-only.\"",
      "Onun okulu *Yogācāra*, genellikle \"yalnızca bilinç\" okulu diye anılır.",
      [head(0.5, 0.48, 0.75, glow=True), T(0.5, 0.1, "\"consciousness-only\"", 1.0, underline="red")]),
    S("His starting point sounds familiar: in a dream, you see places, people, and objects that feel completely real — yet there's nothing outside your mind producing them.",
      "Çıkış noktası tanıdık geliyor: Rüyada tamamen gerçek gelen yerler, insanlar ve nesneler görürsün. Ama onları üreten, zihninin dışında hiçbir şey yoktur.",
      [dict(el="bed", x=0.38, y=0.82, s=1.2), fig(0.45, 0.4, "lie", -1, y=0.68), bubble(0.68, 0.3, 1.1, "thought", tail=[0.4, 0.58]),
       dict(el="house", x=0.62, y=0.4, s=0.35), fig(0.74, 0.18, y=0.42), fig(0.79, 0.16, face=-1, y=0.42, hat="dress")]),
    S("So how do we know waking life is different?",
      "Peki uyanık hayatın farklı olduğunu nereden biliyoruz?",
      [G(), fig(0.4, 0.55), T(0.65, 0.4, "?", 4.0)]),
    S("But here's the twist: Vasubandhu was *not* a solipsist.",
      "Ama işin ilginç yanı şu: Vasubandhu solipsist *değildi*.",
      [T(0.5, 0.4, "NOT a solipsist", 1.5, underline="red")]),
    S("His tradition accepted many minds — many streams of consciousness, influencing one another.",
      "Onun geleneği birçok zihni kabul ediyordu: birbirini etkileyen birçok bilinç akışı.",
      [dict(el="heads", x=0.5, y=0.55, s=1.2)]),
    S("The question wasn't \"Am I the only one?\" It was \"What are we really experiencing when we experience a world?\"",
      "Soru \"Tek ben miyim?\" değildi. Soru şuydu: \"Bir dünyayı deneyimlerken aslında neyi deneyimliyoruz?\"",
      [T(0.5, 0.25, "Am I the only one?", 1.0), dict(el="cross", x=0.5, y=0.25, s=0.9, at=1.4),
       T(0.5, 0.58, "What is a world?", 1.3, color="blue", underline="blue")]),
    S("Centuries later, the Hindu philosopher *Adi Shankara* taught that the everyday world of separate things is *maya* — appearance —",
      "Yüzyıllar sonra Hindu filozof *Adi Şankara*, ayrı ayrı şeylerden oluşan gündelik dünyanın *maya*, yani görünüş olduğunu öğretti.",
      [G(), fig(0.3, 0.42, "sit"), T(0.65, 0.35, "maya", 1.6, underline="red"), T(0.65, 0.52, "= appearance", 0.9, color="blue"),
       T(0.3, 0.12, "Adi Shankara · 8th c.", 0.7)]),
    S("and that, at the deepest level, there is only one Self.",
      "Ve en derin düzeyde yalnızca tek bir Benlik olduğunu.",
      [dict(el="circle", x=0.5, y=0.45, s=1.0, rx=330, ry=330, color="ink"), dict(el="dot", x=0.5, y=0.45, s=1.6)]),
    S("That's not \"only my mind exists\" either. It's closer to: the line between \"me\" and \"everything else\" may not be where we think.",
      "Bu da \"yalnızca benim zihnim var\" demek değil. Daha çok şuna yakın: \"ben\" ile \"geri kalan her şey\" arasındaki çizgi sandığımız yerde olmayabilir.",
      [head(0.32, 0.48, 0.6), T(0.72, 0.48, "everything else", 0.9), dict(el="line", x=0.52, y=0.15, x2=0.52, y2=0.8, color="red"),
       T(0.52, 0.86, "?", 1.2, color="red")]),
]

# ---------------------------------------------------------------- Descartes
scenes += [
    S("Two thousand years later, in the 1600s, a French philosopher decided to take doubt to its absolute limit.",
      "İki bin yıl sonra, 1600'lerde, bir Fransız filozof şüpheyi en uç sınırına kadar götürmeye karar verdi.",
      [dict(el="hourglass", x=0.5, y=0.45, s=1.2), T(0.5, 0.1, "1600s · France", 0.9)]),
    P("descartes", "René Descartes · 1596–1650", "His name was *René Descartes*.", "Adı *René Descartes*'tı."),
    S("His plan was simple and radical: throw out every belief that could possibly be false, and see if anything survives.",
      "Planı basit ve radikaldi: Yanlış olma ihtimali olan her inancı at ve geriye bir şey kalıyor mu bak.",
      [T(0.5, 0.2, "the sky is blue", 0.9), T(0.5, 0.35, "I have hands", 0.9), T(0.5, 0.5, "2 + 3 = 5", 0.9),
       T(0.5, 0.65, "the world exists", 0.9), dict(el="cross", x=0.5, y=0.42, s=1.8, at=2.2)]),
    S("First, the senses. They fool us all the time — a straight stick looks bent in water.",
      "Önce duyular. Bizi sürekli kandırırlar: Düz bir çubuk suda kırık görünür.",
      [dict(el="glass_stick", x=0.5, y=0.78, s=1.4), T(0.2, 0.15, "1. senses", 1.0, underline="red")]),
    S("So they can't be fully trusted.", "Yani onlara tamamen güvenilemez.",
      [dict(el="eye", x=0.5, y=0.45, s=1.6), dict(el="cross", x=0.5, y=0.45, s=1.3, at=0.8)]),
    S("Then, the *dream argument*. Every night you experience vivid worlds that feel completely real while you're in them.",
      "Sonra *rüya argümanı*. Her gece, içindeyken tamamen gerçek gelen canlı dünyalar yaşıyorsun.",
      [dict(el="moon", x=0.82, y=0.15, s=0.9), dict(el="bed", x=0.38, y=0.82, s=1.2), fig(0.45, 0.4, "lie", -1, y=0.68),
       bubble(0.66, 0.32, 1.0, "thought", tail=[0.4, 0.58]), dict(el="globe", x=0.66, y=0.32, s=0.55), T(0.2, 0.12, "2. dreams", 1.0, underline="red")]),
    S("Can you be certain, right now, that you're awake?", "Şu an uyanık olduğundan emin olabilir misin?",
      [G(), fig(0.38, 0.55, "think"), bubble(0.62, 0.28, 0.6, tail=[0.43, 0.33]), T(0.62, 0.28, "awake?", 0.9)]),
    S("And finally, his most famous thought experiment.", "Ve son olarak en ünlü düşünce deneyi.",
      [head(0.5, 0.5, 0.7), T(0.5, 0.1, "3. the evil demon", 1.1, underline="red")]),
    S("What if there were an *evil demon*, supremely powerful and cunning, using all its energy to deceive you —",
      "Ya son derece güçlü ve kurnaz bir *kötü iblis* tüm gücüyle seni kandırıyorsa?",
      [dict(el="demon", x=0.5, y=0.3, s=1.3, strings_to=[[0.46, 0.56], [0.54, 0.56]]), G(), fig(0.5, 0.36)]),
    S("feeding you a fake world, fake people, even fake mathematics?",
      "Sana sahte bir dünya, sahte insanlar, hatta sahte bir matematik sunuyorsa?",
      [dict(el="demon", x=0.2, y=0.3, s=0.8), dict(el="globe", x=0.5, y=0.35, s=0.55), fig(0.68, 0.25, y=0.48), fig(0.73, 0.23, face=-1, y=0.48, hat="dress"),
       T(0.84, 0.35, "2 + 2 = 5", 0.9, color="red"), arrow(0.3, 0.3, 0.42, 0.33, s=0.8)]),
    S("Descartes pushed until almost nothing was left.", "Descartes neredeyse hiçbir şey kalmayana kadar zorladı.",
      [G(), fig(0.5, 0.25, "think")]),
    S("And then he found the one thing the demon could never fake.", "Ve sonra iblisin asla taklit edemeyeceği tek şeyi buldu.",
      [head(0.5, 0.48, 0.75, glow=True)]),
    S("If you are being deceived, then you exist — someone must be there to be deceived.",
      "Eğer kandırılıyorsan, var olmalısın. Kandırılacak biri orada olmalı.",
      [dict(el="demon", x=0.22, y=0.35, s=0.7), arrow(0.35, 0.4, 0.55, 0.45), head(0.68, 0.48, 0.55, glow=True), T(0.68, 0.12, "someone is here", 0.9, underline="red")]),
    S("Doubting is a kind of thinking, and thinking requires a thinker.",
      "Şüphe etmek bir tür düşünmektir ve düşünmek bir düşünen gerektirir.",
      [T(0.2, 0.45, "doubt", 1.2), arrow(0.29, 0.45, 0.39, 0.45, bend=0.0), T(0.5, 0.45, "thinking", 1.2), arrow(0.61, 0.45, 0.71, 0.45, bend=0.0),
       T(0.82, 0.45, "thinker", 1.2, color="red", underline="red")]),
    S("In his words: *I think, therefore I am*.", "Onun sözleriyle: *Düşünüyorum, öyleyse varım*.",
      [T(0.5, 0.33, "Cogito, ergo sum", 1.6), T(0.5, 0.55, "I think, therefore I am", 1.0, color="blue", underline="red")]),
]

# ---------------------------------------------------------------- Tuzak
scenes += [
    S("It's one of the most famous sentences in philosophy.", "Felsefenin en ünlü cümlelerinden biri bu.",
      [T(0.5, 0.45, "\"I think, therefore I am\"", 1.2), dict(el="circle", x=0.5, y=0.45, s=1.0, rx=560, ry=110)]),
    S("But notice what it actually proves. It proves that *you* exist.",
      "Ama gerçekte neyi kanıtladığına dikkat et. *Senin* var olduğunu kanıtlıyor.",
      [head(0.5, 0.5, 0.7, glow=True), T(0.5, 0.1, "YOU exist", 1.2, underline="red")]),
    S("Not your body — just your thinking.", "Bedenini değil, sadece düşünmeni.",
      [G(), fig(0.38, 0.6, tone=0.35), dict(el="cross", x=0.38, y=0.52, s=1.2, at=0.8), head(0.7, 0.45, 0.5, glow=True)]),
    S("And it says absolutely nothing about anyone else.", "Ve başka herhangi biri hakkında kesinlikle hiçbir şey söylemiyor.",
      [G(), fig(0.25, 0.45), fig(0.45, 0.47, face=-1, hat="dress"), fig(0.65, 0.44), fig(0.82, 0.3, child=True, face=-1),
       T(0.25, 0.2, "?", 1.2), T(0.45, 0.18, "?", 1.2), T(0.65, 0.2, "?", 1.2), T(0.82, 0.38, "?", 1.2)]),
    S("Descartes had dug himself into a hole, and he knew it.", "Descartes kendini bir çukura sokmuştu ve bunun farkındaydı.",
      [dict(el="pit", x=0.5, y=0.82, s=1.0)]),
    S("To climb out, he argued that a perfect God exists and would not allow us to be deceived about everything.",
      "Çıkmak için, kusursuz bir Tanrı'nın var olduğunu ve bizim her konuda kandırılmamıza izin vermeyeceğini savundu.",
      [dict(el="pit", x=0.5, y=0.82, s=1.0), dict(el="ladder", x=0.62, y=0.82, s=0.75), dict(el="dot", x=0.72, y=0.12, s=1.3)]),
    S("Many later readers found that step much weaker than the doubt that came before it.",
      "Sonraki okurların çoğu bu adımı, ondan önceki şüpheden çok daha zayıf buldu.",
      [dict(el="pit", x=0.5, y=0.82, s=1.0, figure_in=False), dict(el="ladder", x=0.62, y=0.82, s=0.75, broken=True),
       dict(el="circle", x=0.66, y=0.6, s=1.0, rx=110, ry=180)]),
    S("The hole he dug was convincing. *The ladder out was not.*", "Kazdığı çukur ikna ediciydi. *Çıkış merdiveni değildi.*",
      [dict(el="pit", x=0.5, y=0.82, s=1.0), dict(el="ladder", x=0.62, y=0.82, s=0.75, broken=True), dict(el="cross", x=0.65, y=0.6, s=1.0, at=1.6)]),
]

# ---------------------------------------------------------------- Berkeley ve Johnson
scenes += [
    P("berkeley", "George Berkeley · 1685–1753", "A century later, the Irish bishop *George Berkeley* went even further.",
      "Bir yüzyıl sonra İrlandalı piskopos *George Berkeley* daha da ileri gitti."),
    S("In 1710 he argued that physical objects are nothing more than collections of perceptions.",
      "1710'da fiziksel nesnelerin algıların toplamından başka bir şey olmadığını savundu.",
      [dict(el="eye", x=0.25, y=0.45, s=0.9), arrow(0.36, 0.45, 0.55, 0.45, bend=0.0), dict(el="chair", x=0.7, y=0.72, s=1.0),
       T(0.7, 0.15, "= perceptions", 0.9, color="blue")]),
    S("To be, he said, *is to be perceived*.", "Ona göre var olmak *algılanmaktır*.",
      [T(0.5, 0.35, "esse est percipi", 1.5), T(0.5, 0.55, "to be is to be perceived", 1.0, color="blue", underline="red")]),
    S("Berkeley wasn't a solipsist — he believed other minds and God were real.",
      "Berkeley solipsist değildi; başka zihinlerin ve Tanrı'nın gerçek olduğuna inanıyordu.",
      [dict(el="heads", x=0.5, y=0.6, s=1.0), dict(el="dot", x=0.5, y=0.15, s=1.3)]),
    S("But critics said his ideas slid dangerously close.", "Ama eleştirmenleri fikirlerinin tehlikeli biçimde solipsizme yaklaştığını söyledi.",
      [G(), fig(0.25, 0.5, "point", hat="wig"), fig(0.4, 0.5, "point", hat="tricorn"), T(0.72, 0.4, "solipsism?", 1.2, color="red")]),
    P("johnson", "Samuel Johnson · 1709–1784", "His most famous critic didn't use an argument at all.",
      "En ünlü eleştirmeni hiç argüman kullanmadı."),
    S("In 1763, the writer *Samuel Johnson* was walking with his biographer James Boswell, who remarked that Berkeley's theory was impossible to refute.",
      "1763'te yazar *Samuel Johnson*, biyografisini yazan James Boswell ile yürürken Boswell, Berkeley'in teorisinin çürütülmesinin imkânsız olduğunu söyledi.",
      [G(), fig(0.38, 0.6, "walk", hat="wig"), fig(0.58, 0.55, "walk", hat="tricorn"), bubble(0.7, 0.2, 0.6, tail=[0.6, 0.3]),
       T(0.7, 0.2, "irrefutable!", 0.8), T(0.15, 0.1, "1763", 1.0)]),
    S("Johnson walked up to a large stone, kicked it hard enough to bounce back, and said: *\"I refute it thus.\"*",
      "Johnson büyük bir taşa yürüdü, geri sekecek kadar sert bir tekme attı ve şöyle dedi: *\"Onu işte böyle çürütüyorum.\"*",
      [G(), fig(0.38, 0.62, "kick", hat="wig"), dict(el="stone", x=0.62, y=0.8, s=0.9),
       bubble(0.3, 0.16, 0.7, tail=[0.36, 0.28], at=2.2), T(0.3, 0.16, "I refute it thus!", 0.75)]),
    S("It's a great moment. It's also, philosophers will tell you, not a refutation at all.",
      "Harika bir an. Ama filozoflar sana bunun hiç de bir çürütme olmadığını söyleyecektir.",
      [G(), dict(el="stone", x=0.5, y=0.8, s=1.2), T(0.5, 0.3, "refutation?", 1.3), dict(el="cross", x=0.5, y=0.3, s=1.0, at=1.5)]),
    S("Berkeley never denied that you *feel* the stone. He only questioned what the feeling is made of.",
      "Berkeley taşı *hissettiğini* hiçbir zaman inkâr etmedi. Sadece o hissin neyden yapıldığını sorguladı.",
      [G(), dict(el="stone", x=0.25, y=0.8, s=0.9), arrow(0.36, 0.6, 0.55, 0.45), head(0.72, 0.45, 0.6, glow=True), T(0.72, 0.1, "made of... ?", 0.9)]),
]

# ---------------------------------------------------------------- Başka zihinler
scenes += [
    S("And this brings us to the heart of it — a puzzle philosophers call *the problem of other minds*.",
      "Ve bu bizi meselenin kalbine getiriyor: Filozofların *başka zihinler sorunu* dediği bulmaca.",
      [head(0.3, 0.5, 0.6, face=1, glow=True), head(0.7, 0.5, 0.6, face=-1), dict(el="line", x=0.5, y=0.2, x2=0.5, y2=0.8, w=1.6),
       T(0.5, 0.1, "the problem of other minds", 1.0, underline="red")]),
    S("You see other people laugh, cry, flinch when they're hurt.", "Başkalarının güldüğünü, ağladığını, canları yandığında irkildiğini görürsün.",
      [G(), fig(0.25, 0.48), fig(0.5, 0.48, "shrug", face=-1, hat="dress"), fig(0.75, 0.48, "think", face=-1),
       T(0.25, 0.22, "ha ha", 0.8), T(0.5, 0.2, "...", 0.8), T(0.75, 0.22, "ouch!", 0.8, color="red")]),
    S("But you never experience their pain. You only see the outside: a face, a sound, a movement.",
      "Ama onların acısını asla yaşamazsın. Sadece dışarıyı görürsün: bir yüz, bir ses, bir hareket.",
      [dict(el="eye", x=0.22, y=0.45, s=0.8), arrow(0.33, 0.45, 0.5, 0.45, bend=0.0), head(0.68, 0.48, 0.6, face=-1, lock=True)]),
    S("Their inner world, if there is one, is permanently hidden from you.", "İç dünyaları, eğer varsa, senden sonsuza kadar gizlidir.",
      [dict(el="room", x=0.5, y=0.78, s=1.1), fig(0.5, 0.3, y=0.76, face=-1)]),
    P("mill", "John Stuart Mill · 1806–1873", "In 1865, *John Stuart Mill* offered the classic answer: the *argument from analogy*.",
      "1865'te *John Stuart Mill* klasik cevabı verdi: *analoji argümanı*."),
    S("When I'm hurt, I wince. Others wince in the same situations. So, by analogy, they probably feel what I feel.",
      "Canım yandığında yüzümü buruşturuyorum. Başkaları da aynı durumlarda yüzünü buruşturuyor. O hâlde benzetme yoluyla, muhtemelen benim hissettiğimi hissediyorlar.",
      [G(), fig(0.3, 0.5), T(0.3, 0.22, "ouch!", 0.9, color="red"), T(0.5, 0.45, "=", 1.6), fig(0.7, 0.5, face=-1),
       T(0.7, 0.22, "ouch!", 0.9, color="red"), T(0.5, 0.1, "same feeling?", 0.9, color="blue")]),
    S("It sounds reasonable — until you notice the problem. You're generalizing from exactly *one* example: yourself.",
      "Kulağa makul geliyor, ta ki sorunu fark edene kadar: Tam olarak *tek* bir örnekten genelleme yapıyorsun, yani kendinden.",
      [G(), fig(0.5, 0.55), dict(el="circle", x=0.5, y=0.55, s=1.0, rx=170, ry=330), T(0.78, 0.3, "n = 1", 1.4, color="red")]),
    S("Modern philosophers have made the puzzle even sharper.", "Modern filozoflar bulmacayı daha da keskinleştirdi.",
      [G(), fig(0.4, 0.5, "think"), fig(0.6, 0.5, "point", face=-1)]),
    S("In 1996, *David Chalmers* popularized the idea of a *philosophical zombie*:",
      "1996'da *David Chalmers*, *felsefi zombi* fikrini yaygınlaştırdı:",
      [G(), fig(0.5, 0.55), T(0.5, 0.1, "philosophical zombie", 1.2, underline="red")]),
    S("a being that looks and acts exactly like a person, says \"ouch,\" writes poetry, falls in love —",
      "Tam bir insan gibi görünen ve davranan, \"ah\" diyen, şiir yazan, âşık olan,",
      [G(), fig(0.3, 0.5), fig(0.7, 0.5, face=-1), T(0.5, 0.25, "identical", 1.0, color="blue")]),
    S("but has no inner experience at all.", "ama hiçbir iç deneyimi olmayan bir varlık.",
      [head(0.3, 0.5, 0.6, glow=True), head(0.7, 0.5, 0.6, face=-1), T(0.7, 0.44, "?", 1.0, color="red")]),
    S("The lights are on, but nobody's home.", "Işıklar yanıyor ama evde kimse yok.",
      [dict(el="house", x=0.5, y=0.78, s=1.3)]),
    S("Here's the uncomfortable question: from the outside, how would you ever *tell the difference*?",
      "Rahatsız edici soru şu: Dışarıdan bakarak *farkı* nasıl anlarsın?",
      [G(), fig(0.3, 0.5), fig(0.7, 0.5, face=-1), T(0.5, 0.4, "?", 3.5, color="red")]),
]

# ---------------------------------------------------------------- Kendin dene
scenes += [
    S("Let's try something. Think of someone you know well — a friend, a parent.",
      "Bir şey deneyelim. İyi tanıdığın birini düşün: bir arkadaşını, annen ya da babanı.",
      [G(), fig(0.35, 0.55, "think"), bubble(0.66, 0.3, 0.9, "thought", tail=[0.4, 0.32]), fig(0.66, 0.2, y=0.4, face=-1, hat="dress"),
       T(0.15, 0.1, "try this", 1.0, color="red", underline="red")]),
    S("Now try to *prove* — not believe, but prove — that they feel anything at all.",
      "Şimdi bir şey hissettiklerini *kanıtlamaya* çalış. İnanmaya değil, kanıtlamaya.",
      [T(0.5, 0.3, "believe", 1.2), dict(el="cross", x=0.5, y=0.3, s=0.8, at=1.2), T(0.5, 0.55, "PROVE", 1.6, color="red", underline="red")]),
    S("You'll notice that every piece of evidence is behavior: words, faces, reactions.",
      "Her kanıtın aslında bir davranış olduğunu fark edeceksin: kelimeler, yüz ifadeleri, tepkiler.",
      [dict(el="eye", x=0.22, y=0.45, s=0.8), T(0.62, 0.25, "words", 1.0), T(0.62, 0.45, "faces", 1.0), T(0.62, 0.65, "reactions", 1.0),
       dict(el="circle", x=0.62, y=0.45, s=1.0, rx=230, ry=280, color="blue")]),
    S("Now flip it. How would *they* prove that *you* feel anything?",
      "Şimdi tersine çevir. *Onlar*, *senin* bir şey hissettiğini nasıl kanıtlardı?",
      [G(), fig(0.3, 0.5), fig(0.7, 0.5, face=-1, hat="dress"), arrow(0.38, 0.35, 0.62, 0.35, color="blue"), arrow(0.62, 0.5, 0.38, 0.5, color="red")]),
    S("You are certain about your own pain, and uncertain about everyone else's. That asymmetry is the whole problem in a single breath.",
      "Kendi acından eminsin, başkalarınınkinden değil. Bütün sorun bu tek asimetride saklı.",
      [T(0.3, 0.3, "my pain", 1.2), T(0.3, 0.48, "certain", 1.0, color="blue", underline="blue"), dict(el="line", x=0.5, y=0.2, x2=0.5, y2=0.7),
       T(0.7, 0.3, "your pain", 1.2), T(0.7, 0.48, "?", 1.6, color="red")]),
    S("There's even a word for the opposite feeling: *sonder*, coined by the writer John Koenig.",
      "Bunun tersi olan duyguya dair bir kelime bile var: yazar John Koenig'in uydurduğu *sonder*.",
      [T(0.5, 0.4, "sonder", 2.2, underline="red"), T(0.5, 0.62, "John Koenig", 0.8, color="blue")]),
    S("It's the sudden realization that every stranger around you has a life as vivid and complicated as your own.",
      "Etrafındaki her yabancının, seninki kadar canlı ve karmaşık bir hayatı olduğunu birden fark etmek.",
      [G(0.82), fig(0.12, 0.35, y=0.82), fig(0.25, 0.38, y=0.82, face=-1, hat="dress"), fig(0.38, 0.33, y=0.82), fig(0.5, 0.4, y=0.82, face=-1),
       fig(0.62, 0.34, y=0.82, hat="dress"), fig(0.75, 0.37, y=0.82, face=-1), fig(0.88, 0.3, y=0.82, child=True),
       dict(el="dot", x=0.12, y=0.35, s=0.5, at=1.5), dict(el="dot", x=0.25, y=0.33, s=0.5, at=1.7), dict(el="dot", x=0.38, y=0.37, s=0.5, at=1.9),
       dict(el="dot", x=0.5, y=0.3, s=0.5, at=2.1), dict(el="dot", x=0.62, y=0.36, s=0.5, at=2.3), dict(el="dot", x=0.75, y=0.33, s=0.5, at=2.5),
       dict(el="dot", x=0.88, y=0.5, s=0.5, at=2.7)]),
]

# ---------------------------------------------------------------- Psikoloji
scenes += [
    S("And here's where psychology gives us a surprising twist. In a sense, every one of us starts life as a kind of solipsist.",
      "Ve burada psikoloji bize şaşırtıcı bir dönemeç sunuyor. Bir anlamda her birimiz hayata bir tür solipsist olarak başlarız.",
      [G(), dict(el="child_q", x=0.5, y=0.8, s=1.3), T(0.5, 0.1, "psychology", 1.0, underline="red")]),
    S("Very young children struggle to understand that other people have beliefs different from their own.",
      "Çok küçük çocuklar, başkalarının kendilerinden farklı inançları olabileceğini anlamakta zorlanır.",
      [G(), fig(0.32, 0.32, child=True), fig(0.68, 0.58, face=-1), bubble(0.3, 0.3, 0.55, "thought", tail=[0.32, 0.45]),
       dict(el="globe", x=0.3, y=0.3, s=0.3), bubble(0.72, 0.15, 0.55, "thought", tail=[0.69, 0.25]), dict(el="butterfly", x=0.72, y=0.15, s=0.3)]),
    S("Psychologists test this with what's called a *false-belief task*.", "Psikologlar bunu *yanlış inanç testi* denen bir yöntemle ölçer.",
      [T(0.5, 0.42, "false-belief task", 1.6, underline="red")]),
    S("In one well-known version, the *Sally–Anne test*, a child watches a doll named Sally put a marble in a basket and leave.",
      "Bilinen bir versiyonu olan *Sally–Anne testinde* çocuk, Sally adlı bir bebeğin bilyesini sepete koyup gittiğini izler.",
      [G(), fig(0.25, 0.45, "hold", hat="dress"), T(0.25, 0.25, "Sally", 0.8, color="blue"), dict(el="basket", x=0.5, y=0.8, s=1.0),
       dict(el="marble", x=0.5, y=0.66, s=1.0, at=2.0), dict(el="box", x=0.75, y=0.8, s=1.0)]),
    S("While she's gone, Anne moves the marble into a box.", "Sally yokken Anne bilyeyi bir kutuya taşır.",
      [G(), fig(0.25, 0.45, "point", hat="bun"), T(0.25, 0.25, "Anne", 0.8, color="blue"), dict(el="basket", x=0.5, y=0.8, s=1.0),
       dict(el="box", x=0.75, y=0.8, s=1.0), dict(el="marble", x=0.76, y=0.7, s=1.0), arrow(0.5, 0.55, 0.74, 0.58, color="red")]),
    S("Then the child is asked: when Sally comes back, where will she look?",
      "Sonra çocuğa sorulur: Sally geri geldiğinde bilyeyi nerede arayacak?",
      [G(), fig(0.2, 0.32, child=True), T(0.2, 0.35, "?", 1.4, color="red"), dict(el="basket", x=0.5, y=0.8, s=1.0), dict(el="box", x=0.75, y=0.8, s=1.0)]),
    S("Most three-year-olds say: the box — because that's where *they* know it is.",
      "Üç yaşındakilerin çoğu \"kutuda\" der, çünkü bilyenin orada olduğunu *kendileri* bilir.",
      [G(), fig(0.2, 0.3, "point", child=True), T(0.2, 0.36, "age 3", 0.8), dict(el="basket", x=0.5, y=0.8, s=1.0), dict(el="box", x=0.75, y=0.8, s=1.0),
       dict(el="circle", x=0.77, y=0.7, s=1.0, rx=170, ry=130, at=1.6)]),
    S("Around age four, most children start to answer: the basket.", "Dört yaş civarında çocukların çoğu \"sepette\" demeye başlar.",
      [G(), fig(0.2, 0.34, "point", child=True), T(0.2, 0.33, "age 4", 0.8), dict(el="basket", x=0.5, y=0.8, s=1.0), dict(el="box", x=0.75, y=0.8, s=1.0),
       dict(el="circle", x=0.5, y=0.7, s=1.0, rx=170, ry=130, color="blue", at=1.2)]),
    S("They've realized something huge: other people have minds of their own, with their own, sometimes wrong, picture of the world.",
      "Çok büyük bir şeyi fark etmişlerdir: Başkalarının da kendine ait, bazen yanlış bir dünya resmi olan zihinleri vardır.",
      [head(0.3, 0.55, 0.5, glow=True), head(0.7, 0.55, 0.5, face=-1, glow=True), bubble(0.3, 0.18, 0.5, "thought", tail=[0.3, 0.32]),
       dict(el="basket", x=0.3, y=0.22, s=0.4), bubble(0.7, 0.18, 0.5, "thought", tail=[0.7, 0.32]), dict(el="box", x=0.7, y=0.22, s=0.4)]),
    S("Psychologists call this ability *theory of mind*.", "Psikologlar bu yeteneğe *zihin kuramı* der.",
      [T(0.5, 0.42, "theory of mind", 1.8, underline="red")]),
    S("So in a way, your brain already made its leap out of solipsism — not by proof, but by *development*.",
      "Yani bir anlamda beynin solipsizmden çıkış sıçramasını zaten yaptı. Kanıtla değil, *gelişimle*.",
      [G(), fig(0.25, 0.3, child=True), arrow(0.33, 0.6, 0.6, 0.45, color="blue"), fig(0.72, 0.6), T(0.5, 0.1, "development", 1.0, underline="red")]),
    S("And sometimes, that sense of reality can slip.", "Ve bazen o gerçeklik hissi kayabilir.",
      [dict(el="globe", x=0.5, y=0.45, s=1.3), T(0.5, 0.82, "reality", 0.8, color="grey")]),
    S("Many people experience brief moments of *derealization* — a feeling that the world is flat, distant, dreamlike, not quite real.",
      "Pek çok insan kısa *derealizasyon* anları yaşar: dünyanın düz, uzak, rüya gibi, tam olarak gerçek değilmiş gibi hissedilmesi.",
      [G(), fig(0.3, 0.55, "think"), bubble(0.66, 0.35, 1.0, "thought", tail=[0.36, 0.33]), dict(el="house", x=0.62, y=0.45, s=0.35),
       fig(0.74, 0.16, y=0.45), T(0.66, 0.08, "not quite real", 0.8, color="blue")]),
    S("When it's persistent and distressing, it's recognized as a clinical condition, *depersonalization-derealization disorder*, estimated to affect around two percent of people.",
      "Bu durum kalıcı ve sıkıntı verici olduğunda klinik bir tablo olarak tanınır: *duyarsızlaşma-derealizasyon bozukluğu*. İnsanların yaklaşık yüzde ikisini etkilediği tahmin ediliyor.",
      [dict(el="dots", x=0.5, y=0.45, s=1.4, n=50, cols=10, highlight=1), T(0.5, 0.1, "≈ 2 in 100", 1.1, color="red")]),
    S("In the 2000s, psychiatrist *Joel Gold* and his brother, the philosopher *Ian Gold*, began describing patients who believed their entire life was a staged reality show, with everyone around them as actors.",
      "2000'lerde psikiyatrist *Joel Gold* ve filozof kardeşi *Ian Gold*, tüm hayatlarının sahnelenmiş bir realite şov olduğuna, etraflarındaki herkesin oyuncu olduğuna inanan hastaları tanımlamaya başladı.",
      [dict(el="dome", x=0.45, y=0.82, s=0.9), fig(0.45, 0.4, y=0.82), fig(0.3, 0.3, y=0.82, face=1, hat="dress"), fig(0.6, 0.3, y=0.82, face=-1),
       dict(el="camera", x=0.86, y=0.4, s=0.9)]),
    S("They called it the *Truman Show delusion*.", "Buna *Truman Show sanrısı* adını verdiler.",
      [T(0.5, 0.42, "the Truman Show delusion", 1.4, underline="red"), dict(el="camera", x=0.85, y=0.75, s=0.6)]),
    S("The philosophers' thought experiment, it turns out, can become someone's lived experience.",
      "Filozofların düşünce deneyi, anlaşılan o ki, birinin yaşadığı gerçeklik olabiliyor.",
      [head(0.5, 0.5, 0.7), T(0.5, 0.1, "thought experiment = real life", 1.0, color="blue")]),
]

# ---------------------------------------------------------------- Ladd-Franklin
scenes += [
    S("Now, the logician I promised you.", "Şimdi söz verdiğim mantıkçıya gelelim.",
      [dict(el="letter", x=0.5, y=0.45, s=1.3)]),
    P("laddfranklin", "Christine Ladd-Franklin · 1847–1930", "*Christine Ladd-Franklin* was a brilliant American logician and psychologist.",
      "*Christine Ladd-Franklin* parlak bir Amerikalı mantıkçı ve psikologdu."),
    P("russell", "Bertrand Russell · 1872–1970", "In his 1948 book *Human Knowledge*, *Bertrand Russell* recalled receiving a letter from her.",
      "*Bertrand Russell*, 1948 tarihli *İnsan Bilgisi* kitabında ondan bir mektup aldığını anlatır."),
    S("She told him she was a solipsist — and that she was *surprised there were no others*.",
      "Ladd-Franklin ona solipsist olduğunu ve *başka solipsist olmamasına şaşırdığını* yazmıştı.",
      [dict(el="letter", x=0.5, y=0.4, s=1.0), T(0.5, 0.68, "\"...surprised there were no others\"", 1.0),
       dict(el="circle", x=0.5, y=0.68, s=1.0, rx=600, ry=70, at=2.0)]),
    S("Think about that sentence for a second. If solipsism is true, of course there are no others. That's the whole point.",
      "Bu cümleyi bir saniye düşün. Solipsizm doğruysa, elbette başka solipsist yoktur. Bütün mesele zaten bu.",
      [G(), fig(0.5, 0.5, hat="dress")]),
    S("And yet she was surprised.", "Ama yine de şaşırmıştı.",
      [G(), fig(0.5, 0.5, "shrug", hat="dress"), T(0.62, 0.2, "!", 2.5, color="red")]),
    S("It's funny. But it also shows something important: solipsism is almost impossible to *live* consistently.",
      "Komik. Ama önemli bir şeyi de gösteriyor: Solipsizmi tutarlı biçimde *yaşamak* neredeyse imkânsız.",
      [T(0.5, 0.4, "impossible to LIVE", 1.5, underline="red")]),
    S("The moment you talk, write, argue, or expect to be understood, you're already acting as if other minds are out there.",
      "Konuştuğun, yazdığın, tartıştığın ya da anlaşılmayı beklediğin anda, zaten başka zihinler varmış gibi davranıyorsun.",
      [G(), fig(0.3, 0.5, "point"), bubble(0.45, 0.2, 0.6, tail=[0.34, 0.3]), T(0.45, 0.2, "you see?", 0.8), fig(0.72, 0.5, face=-1)]),
]

# ---------------------------------------------------------------- Wittgenstein
scenes += [
    S("The Austrian philosopher *Ludwig Wittgenstein* turned that observation into one of the most powerful responses to solipsism.",
      "Avusturyalı filozof *Ludwig Wittgenstein* bu gözlemi solipsizme verilmiş en güçlü cevaplardan birine dönüştürdü.",
      [G(), fig(0.5, 0.55, "think"), T(0.5, 0.1, "Ludwig Wittgenstein · 1889–1951", 0.9)]),
    S("His point, roughly, was this: the solipsist expresses the idea in language. But language is *public*.",
      "Kabaca şunu söyledi: Solipsist fikrini dille ifade ediyor. Ama dil *ortaktır*.",
      [G(), fig(0.25, 0.48), fig(0.5, 0.48, face=-1, hat="dress"), fig(0.75, 0.48, face=-1), bubble(0.37, 0.18, 0.4, tail=[0.27, 0.3]),
       bubble(0.62, 0.18, 0.4, tail=[0.73, 0.3]), T(0.5, 0.06, "public", 1.0, color="red", underline="red")]),
    S("Words get their meaning from shared rules, from use among people.", "Kelimeler anlamlarını ortak kurallardan, insanlar arasındaki kullanımdan alır.",
      [T(0.5, 0.45, "\"stone\"", 1.4), arrow(0.2, 0.75, 0.42, 0.52), arrow(0.8, 0.75, 0.58, 0.52), arrow(0.5, 0.15, 0.5, 0.36, bend=0.0),
       fig(0.15, 0.2, y=0.88), fig(0.85, 0.2, y=0.88, face=-1)]),
    S("A truly *private language* — one that only you could ever understand — may not even be possible.",
      "Sadece senin anlayabileceğin gerçek bir *özel dil* belki de mümkün bile değildir.",
      [head(0.32, 0.5, 0.6, lock=True), T(0.7, 0.45, "private language?", 1.1), dict(el="cross", x=0.7, y=0.45, s=1.0, at=1.8)]),
    S("So the very sentence \"only my mind exists\" borrows its meaning from a world full of other speakers.",
      "Yani \"yalnızca benim zihnim var\" cümlesi bile anlamını, başka konuşanlarla dolu bir dünyadan ödünç alıyor.",
      [T(0.5, 0.25, "\"only my mind exists\"", 1.2), G(0.85), fig(0.15, 0.28, y=0.85), fig(0.3, 0.3, y=0.85, hat="dress"), fig(0.7, 0.28, y=0.85, face=-1),
       fig(0.85, 0.3, y=0.85, face=-1), arrow(0.2, 0.55, 0.38, 0.32), arrow(0.8, 0.55, 0.62, 0.32)]),
    S("Strangely, in his early work, Wittgenstein also wrote that what the solipsist *means* is, in a sense, quite correct — it just *cannot be said*.",
      "İşin tuhafı, Wittgenstein ilk dönem eserinde solipsistin *kastettiği* şeyin bir anlamda oldukça doğru olduğunu, sadece *söylenemeyeceğini* de yazmıştı.",
      [head(0.5, 0.5, 0.7, glow=True), T(0.5, 0.08, "Tractatus 5.62", 0.9, color="blue")]),
    S("It can only show itself. Philosophers are still arguing about what exactly he meant.",
      "Ancak kendini gösterebilir. Filozoflar tam olarak ne demek istediğini hâlâ tartışıyor.",
      [G(), fig(0.36, 0.5, "point"), fig(0.64, 0.5, "shrug", face=-1, hat="wig"), T(0.5, 0.2, "?", 2.4, color="red")]),
]

# ---------------------------------------------------------------- Fıçıdaki beyin
scenes += [
    S("Today, the old demon has a new costume.", "Bugün eski iblis yeni bir kostüm giymiş durumda.",
      [dict(el="demon", x=0.3, y=0.45, s=1.0), arrow(0.45, 0.45, 0.6, 0.45, bend=0.0), dict(el="screen", x=0.75, y=0.55, s=1.0)]),
    S("In 1981, the philosopher *Hilary Putnam* described a *brain in a vat*:",
      "1981'de filozof *Hilary Putnam*, *fıçıdaki beyin* senaryosunu anlattı:",
      [dict(el="vat", x=0.45, y=0.82, s=1.2, wires=False), T(0.5, 0.08, "brain in a vat · 1981", 1.0, underline="red")]),
    S("a brain kept alive by scientists, wired to a computer that feeds it a perfectly convincing world.",
      "Bilim insanlarının hayatta tuttuğu, kendisine kusursuz derecede ikna edici bir dünya sunan bir bilgisayara bağlı bir beyin.",
      [dict(el="vat", x=0.3, y=0.82, s=1.1), dict(el="screen", x=0.72, y=0.5, s=1.0), bubble(0.72, 0.15, 0.55, "thought"), dict(el="globe", x=0.72, y=0.15, s=0.3)]),
    S("How could you know you're not that brain?", "O beyin olmadığını nasıl bilebilirsin?",
      [head(0.25, 0.5, 0.55), arrow(0.38, 0.5, 0.55, 0.55), dict(el="vat", x=0.72, y=0.82, s=0.9, wires=False), T(0.5, 0.15, "?", 2.6, color="red")]),
    S("Putnam himself argued the scenario undermines itself — that if you really were such a brain, your words couldn't even refer to real brains and vats.",
      "Putnam'ın kendisi bu senaryonun kendi kendini çürüttüğünü savundu: Eğer gerçekten böyle bir beyin olsaydın, kelimelerin gerçek beyinlere ve fıçılara gönderme bile yapamazdı.",
      [dict(el="vat", x=0.3, y=0.82, s=0.9, wires=False), bubble(0.62, 0.3, 0.8, tail=[0.38, 0.45]), T(0.62, 0.3, "\"vat\"", 1.2),
       dict(el="cross", x=0.62, y=0.3, s=0.9, at=2.5)]),
    S("Not everyone accepts his argument.", "Bu argümanı herkes kabul etmiyor.",
      [G(), fig(0.35, 0.5, "shrug"), fig(0.65, 0.5, "shrug", face=-1, hat="dress")]),
    S("And in 2003, *Nick Bostrom* published the *simulation argument*, suggesting that under certain assumptions, we might be living in a computer simulation.",
      "Ve 2003'te *Nick Bostrom*, belirli varsayımlar altında bir bilgisayar simülasyonunda yaşıyor olabileceğimizi öne süren *simülasyon argümanını* yayımladı.",
      [dict(el="screen", x=0.5, y=0.62, s=2.0), fig(0.43, 0.14, y=0.5), fig(0.5, 0.15, y=0.5, face=-1, hat="dress"), fig(0.57, 0.13, y=0.5),
       T(0.5, 0.08, "simulation argument · 2003", 1.0, underline="red")]),
    S("That isn't solipsism — a simulation could contain many real minds.", "Bu solipsizm değil, çünkü bir simülasyonda pek çok gerçek zihin olabilir.",
      [dict(el="screen", x=0.5, y=0.68, s=2.0), dict(el="heads", x=0.5, y=0.45, s=0.55)]),
    S("But it reopens Descartes's question: how much of what you experience can you actually *verify*?",
      "Ama Descartes'ın sorusunu yeniden açıyor: Deneyimlediklerinin ne kadarını gerçekten *doğrulayabilirsin*?",
      [head(0.4, 0.5, 0.65), T(0.75, 0.45, "verify?", 1.5, color="red", underline="red")]),
]

# ---------------------------------------------------------------- Sinema ve kültür
scenes += [
    S("Pop culture loves this question.", "Popüler kültür bu soruya bayılıyor.",
      [dict(el="screen", x=0.5, y=0.6, s=1.6), T(0.5, 0.1, "on screen", 1.0, underline="red")]),
    S("In *The Truman Show*, a man slowly discovers that his whole life is a TV set, and everyone he knows is an actor.",
      "*Truman Show*'da bir adam, bütün hayatının bir televizyon seti, tanıdığı herkesin de birer oyuncu olduğunu yavaş yavaş keşfeder.",
      [dict(el="dome", x=0.45, y=0.82, s=0.9), fig(0.45, 0.4, "think", y=0.82),
       dict(el="camera", x=0.87, y=0.38, s=0.8), T(0.15, 0.08, "1998", 0.9)]),
    S("In *The Matrix*, the world is a simulation fed into people's brains — Descartes's demon with better graphics.",
      "*Matrix*'te dünya, insanların beynine yüklenen bir simülasyondur: Descartes'ın iblisinin daha iyi grafiklisi.",
      [dict(el="demon", x=0.25, y=0.35, s=0.75), T(0.45, 0.35, "+", 1.5), dict(el="screen", x=0.68, y=0.45, s=1.0), T(0.15, 0.08, "1999", 0.9)]),
    S("In *Inception*, characters carry small objects to test whether they're dreaming.",
      "*Inception*'da karakterler rüyada olup olmadıklarını test etmek için küçük nesneler taşır.",
      [dict(el="top", x=0.5, y=0.7, s=1.6), T(0.5, 0.1, "dream test", 1.0, underline="red"), T(0.15, 0.08, "2010", 0.9)]),
    S("None of these stories are really solipsism — there are always other real people in them.",
      "Bu hikâyelerin hiçbiri aslında solipsizm değil, çünkü içlerinde her zaman başka gerçek insanlar var.",
      [G(), fig(0.25, 0.45), fig(0.4, 0.48, face=-1, hat="dress"), fig(0.6, 0.46), fig(0.75, 0.44, face=-1)]),
    S("Maybe that's telling: even our wildest fantasies about fake worlds can't quite let go of other minds.",
      "Belki de bu bir şey anlatıyor: Sahte dünyalara dair en çılgın fantezilerimiz bile başka zihinlerden tam olarak vazgeçemiyor.",
      [head(0.3, 0.55, 0.6, glow=True), bubble(0.66, 0.32, 1.0, "thought", tail=[0.4, 0.4]), fig(0.6, 0.2, y=0.42), fig(0.68, 0.2, y=0.42, face=-1, hat="dress"),
       fig(0.75, 0.18, y=0.42)]),
]

# ---------------------------------------------------------------- Neden kimse solipsist değil
scenes += [
    S("So why isn't everyone a solipsist?", "Peki neden herkes solipsist değil?",
      [T(0.5, 0.42, "why not?", 2.0, underline="red")]),
    S("One answer: *inference to the best explanation*.", "Bir cevap: *en iyi açıklamaya çıkarım*.",
      [T(0.5, 0.42, "best explanation", 1.6, underline="red")]),
    S("The world behaves too consistently, too surprisingly, too independently of your wishes.",
      "Dünya fazla tutarlı, fazla şaşırtıcı, isteklerinden fazla bağımsız davranıyor.",
      [dict(el="globe", x=0.5, y=0.45, s=1.1), T(0.2, 0.25, "consistent", 0.8), T(0.8, 0.25, "surprising", 0.8), T(0.5, 0.82, "independent", 0.8)]),
    S("Other people tell you things you didn't know, disagree with you, surprise you.",
      "Diğer insanlar sana bilmediğin şeyler söylüyor, seninle aynı fikirde olmuyor, seni şaşırtıyor.",
      [G(), fig(0.3, 0.5), fig(0.7, 0.5, "point", face=-1, hat="dress"), bubble(0.66, 0.18, 0.6, tail=[0.68, 0.3]), T(0.66, 0.18, "Did you know...?", 0.7),
       T(0.3, 0.2, "!", 1.6, color="red")]),
    S("The simplest explanation is that they're *real*.", "En basit açıklama, onların *gerçek* olması.",
      [G(), fig(0.35, 0.5), fig(0.65, 0.5, face=-1, hat="dress"), T(0.5, 0.15, "real", 1.6, color="blue", underline="red")]),
    P("hume", "David Hume · 1711–1776", "And another answer comes from the Scottish philosopher *David Hume*.",
      "Bir diğer cevap İskoç filozof *David Hume*'dan geliyor."),
    S("Hume took skeptical doubts seriously — and admitted they didn't survive contact with ordinary life.",
      "Hume şüpheci kuşkuları ciddiye aldı ve bunların sıradan hayatla temasa geçince ayakta kalmadığını itiraf etti.",
      [G(), fig(0.3, 0.55, "think", hat="wig"), arrow(0.4, 0.45, 0.58, 0.45, bend=0.0), fig(0.68, 0.45, face=-1), fig(0.8, 0.42, face=-1, hat="dress")]),
    S("He wrote that he would dine, play a game of *backgammon*, talk and be merry with his friends,",
      "Yemek yediğini, *tavla* oynadığını, arkadaşlarıyla sohbet edip neşelendiğini yazdı.",
      [dict(el="backgammon", x=0.5, y=0.55, s=0.9), fig(0.2, 0.42, "sit", hat="wig"), fig(0.8, 0.42, "sit", face=-1, hat="tricorn")]),
    S("and after a few hours, his speculations would seem so cold and strained that he couldn't bring himself to return to them.",
      "Birkaç saat sonra da düşünceleri ona o kadar soğuk ve zoraki geliyordu ki, onlara geri dönmeye gönlü elvermiyordu.",
      [dict(el="scroll", x=0.3, y=0.45, s=0.9, text="doubts"), G(), fig(0.7, 0.5, "walk", hat="wig"), arrow(0.6, 0.3, 0.85, 0.3, bend=0.0)]),
    S("Nature, in other words, is *stronger than philosophy*.", "Yani doğa, *felsefeden daha güçlü*.",
      [T(0.5, 0.42, "nature > philosophy", 1.5, underline="red")]),
]

# ---------------------------------------------------------------- Kapanış
scenes += [
    S("So here's where we end up.", "Vardığımız yer şu.", [G(), fig(0.5, 0.45)]),
    S("You cannot prove, with absolute certainty, that anyone else has a mind.", "Başka birinin zihni olduğunu kesin olarak kanıtlayamazsın.",
      [G(), fig(0.3, 0.45), fig(0.5, 0.47, face=-1, hat="dress"), fig(0.7, 0.45, face=-1), T(0.3, 0.22, "?", 1.0), T(0.5, 0.2, "?", 1.0), T(0.7, 0.22, "?", 1.0)]),
    S("Not your friends. Not your family. Not the person reading the comments under this video.",
      "Arkadaşlarının değil. Aileninkinin değil. Bu videonun altındaki yorumları okuyan kişinin bile değil.",
      [dict(el="screen", x=0.5, y=0.6, s=1.6), T(0.5, 0.1, "comments", 1.0)]),
    S("But every day, you act as if they do.", "Ama her gün varmış gibi davranıyorsun.",
      [G(), fig(0.35, 0.5, "walk"), fig(0.5, 0.48, "walk", hat="dress"), fig(0.62, 0.3, "walk", child=True)]),
    S("You apologize. You explain. You hope to be *understood*.", "Özür diliyorsun. Açıklıyorsun. *Anlaşılmayı* umuyorsun.",
      [G(), fig(0.32, 0.5), fig(0.68, 0.5, face=-1, hat="dress"), bubble(0.38, 0.18, 0.5, tail=[0.33, 0.3]), T(0.38, 0.18, "sorry...", 0.7)]),
    S("Maybe that's the real answer to solipsism. Not a proof — but a *choice*.",
      "Belki de solipsizmin gerçek cevabı budur. Bir kanıt değil, bir *seçim*.",
      [T(0.5, 0.3, "proof", 1.4), dict(el="cross", x=0.5, y=0.3, s=0.8, at=1.5), T(0.5, 0.58, "a choice", 1.8, color="blue", underline="red")]),
    S("A choice to treat the minds around you as real, because the alternative is a universe with only one person in it.",
      "Etrafındaki zihinleri gerçek kabul etme seçimi. Çünkü alternatifi, içinde tek bir kişinin olduğu bir evren.",
      [dict(el="stars", n=40, h=0.95), head(0.5, 0.45, 0.4, glow=True)]),
    S("Because in the end, there is only one thing you can be absolutely sure exists... and it's *lonely* in there by yourself.",
      "Çünkü sonunda var olduğundan kesinlikle emin olabileceğin tek bir şey var… ve orada tek başına olmak *yalnız* bir his.",
      [dict(el="stars", n=40, h=0.95), head(0.5, 0.45, 0.55, glow=True)]),
]

meta = {
    "en": dict(
        title="Solipsism: The Only Thing You Can Be Sure Exists",
        description=("Can you prove that anyone else has a mind? From Gorgias and Zhuangzi to Descartes's evil demon, Samuel Johnson's stone, "
                     "the Sally–Anne test, Wittgenstein and the brain in a vat — the strange history of solipsism.\n\n"
                     "Note: the psychology section is for education only and is not medical advice.\n\n"
                     "Sources: Descartes, Meditations (1641); Berkeley, Principles (1710); Boswell, Life of Johnson (1763 entry); "
                     "Mill, An Examination of Sir William Hamilton's Philosophy (1865); Chalmers, The Conscious Mind (1996); "
                     "Wimmer & Perner (1983); Baron-Cohen, Leslie & Frith (1985); Gold & Gold (2012); Russell, Human Knowledge (1948); "
                     "Wittgenstein, Tractatus 5.62 & Philosophical Investigations §243ff; Putnam, Reason, Truth and History (1981); "
                     "Bostrom (2003); Hume, Treatise 1.4.7; Vasubandhu, Twenty Verses.\n\n#philosophy #solipsism #psychology #history"),
        tags=["solipsism", "philosophy", "descartes", "problem of other minds", "theory of mind", "brain in a vat", "simulation theory",
              "psychology", "history of philosophy"]),
    "tr": dict(
        title="Solipsizm: Var olduğundan emin olabileceğin tek şey",
        description=("Başka birinin zihni olduğunu kanıtlayabilir misin? Gorgias ve Zhuangzi'den Descartes'ın kötü iblisine, Johnson'ın taşına, "
                     "Sally–Anne testine, Wittgenstein'a ve fıçıdaki beyne kadar solipsizmin tuhaf tarihi.\n\n"
                     "Not: Psikoloji bölümü yalnızca bilgilendirme amaçlıdır, tıbbi tavsiye değildir.\n\n#felsefe #solipsizm #psikoloji #tarih"),
        tags=["solipsizm", "felsefe", "descartes", "zihin kuramı", "psikoloji", "felsefe tarihi"]),
}

out = dict(slug="solipsizm", format="long", theme="karakalem", character="none", languages=["en"], subtitles=["tr"],
           voices=deneme.get("voices", {"en": "bm_george"}), speech_rate=0.88, meta=meta, subscribe=deneme["subscribe"], scenes=scenes)
json.dump(out, open(os.path.join(HERE, "solipsizm.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
words = sum(len(s["say"]["en"].split()) for s in scenes) + len(deneme["subscribe"]["say"]["en"].split())
print(f"{len(scenes)} sahne, {words} kelime (~{words / 130:.1f} dk, yavaş okumayla)")
