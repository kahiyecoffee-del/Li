#!/usr/bin/env python3
"""Jensen Huang & NVIDIA videosunun sahne sahne senaryosu.  Çalıştır: python3 senaryolar/nvidia_uret.py -> senaryolar/nvidia.json"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
IMGS = {}
p = os.path.join(HERE, "nvidia_gorseller.json")
if os.path.exists(p):
    IMGS = json.load(open(p, encoding="utf-8"))


def S(en, tr, sk=None, **kw):
    d = dict(say={"en": en, "tr": tr})
    if sk is not None:
        d["sketch"] = sk
    d.update(kw)
    return d


def IMG(key, label, en, tr, fallback, fit="contain"):
    if key in IMGS:
        return S(en, tr, image=dict(file=IMGS[key], style="sketch", fit=fit, label=label, tint=0.3))
    return S(en, tr, fallback)


def G(y=0.8):
    return dict(el="ground", x=0.5, y=y, w=0.8)


def T(x, y, text, size=1.0, color="ink", underline=False, at=None):
    d = dict(el="text", x=x, y=y, text=text, size=size, color=color, underline=underline)
    if at is not None:
        d["at"] = at
    return d


def F(x, h=0.5, pose="stand", face=1, y=0.8, **kw):
    return dict(el="figure", x=x, y=y, h=h, pose=pose, face=face, **kw)


def E(name, x, y, s=1.0, **kw):
    return dict(el=name, x=x, y=y, s=s, **kw)


def A(x, y, x2, y2, **kw):
    return dict(el="arrow", x=x, y=y, x2=x2, y2=y2, **kw)


def B(x, y, s=0.6, kind="speech", tail=None, **kw):
    return dict(el="bubble", x=x, y=y, s=s, kind=kind, tail=tail, **kw)

ASOF = "as of Nov 12, 2026"

scenes = [
    # ------------------------------------------------------------ Soğuk açılış
    S("As a teenager, he washed dishes and bussed tables at a Denny's restaurant.",
      "Gençken bir Denny's restoranında bulaşık yıkadı ve masa topladı.",
      [E("sink", 0.45, 0.6, 1.3), F(0.78, 0.5, "stand", -1)]),
    S("Decades later, the company he co-founded at a Denny's booth became the first in history to be worth *five trillion dollars*",
      "On yıllar sonra, bir Denny's masasında kurmaya yardım ettiği şirket tarihte *beş trilyon dolar* değere ulaşan ilk şirket oldu.",
      [E("table", 0.3, 0.6, 0.9), E("graph", 0.72, 0.5, 0.7), T(0.72, 0.12, "$5,000,000,000,000", 1.1, "red", underline="red")]),
    S("— more than the entire economy of almost every country on Earth.",
      "Dünyadaki neredeyse her ülkenin bütün ekonomisinden daha büyük.",
      [E("globe", 0.35, 0.5, 1.1), T(0.72, 0.42, "$5T", 2.2, "red"), T(0.72, 0.65, "> most economies", 0.9, "blue")]),
    IMG("huang", "Jensen Huang · Stanford, 2026",
        "His name is *Jensen Huang*. His company, *NVIDIA*, makes the chips that power most of the world's artificial intelligence.",
        "Adı *Jensen Huang*. Şirketi *NVIDIA*, dünyadaki yapay zekânın büyük bölümünü çalıştıran çipleri üretiyor.",
        [F(0.35, 0.6, "stand", tone=0.95), E("chip", 0.72, 0.45, 0.9, glow=True)]),
    S("And this week, according to multiple reports, his own board was discussing whether to remove him.",
      "Ve bu hafta, birçok habere göre, kendi yönetim kurulu onu görevden alıp almamayı tartışıyordu.",
      [E("table", 0.5, 0.7, 1.4), F(0.25, 0.4, "sit", y=0.72), F(0.75, 0.4, "sit", -1, y=0.72),
       T(0.5, 0.12, "the board", 1.2, "red", underline="red")]),
    S("This is the story of how one company — and, for a while, one man — became something engineers fear most:",
      "Bu, bir şirketin ve bir dönem tek bir adamın, mühendislerin en çok korktuğu şeye nasıl dönüştüğünün hikâyesi:",
      [E("network", 0.5, 0.48, 1.0)]),
    S("a *single point of failure*. For an entire technological age.", "koca bir teknoloji çağı için *tek hata noktası*.",
      [E("network", 0.5, 0.5, 0.9), T(0.5, 0.1, "single point of failure", 1.4, "red", underline="red"), E("circle", 0.5, 0.5, 0.6, color="red")]),
    # ------------------------------------------------------------ Bölüm 1
    S("Jensen Huang was born in 1963 in Tainan, Taiwan.", "Jensen Huang 1963'te Tayvan'ın Tainan şehrinde doğdu.",
      [E("globe", 0.35, 0.5, 1.0), E("dot", 0.4, 0.42, 0.8, color="red"), T(0.75, 0.42, "Tainan · 1963", 1.2, "blue")]),
    S("As a child, he and his older brother were sent to the United States to live with an uncle.",
      "Çocukken o ve ağabeyi bir amcanın yanında yaşamak üzere Amerika'ya gönderildi.",
      [T(0.15, 0.3, "Taiwan", 1.1), A(0.25, 0.35, 0.75, 0.35, bend=-0.25, color="blue"), T(0.85, 0.3, "USA", 1.1), G(0.85),
       F(0.42, 0.28, child=True, y=0.85), F(0.5, 0.33, child=True, y=0.85)]),
    S("The uncle enrolled them at a school in rural Kentucky that he thought was a prestigious boarding school.",
      "Amca onları Kentucky kırsalında prestijli bir yatılı okul sandığı bir okula yazdırdı.",
      [E("house", 0.4, 0.82, 1.3, lit=False), T(0.75, 0.25, "boarding school?", 1.1, "blue")]),
    S("It turned out to be a religious academy for troubled youth.", "Okul aslında sorunlu gençler için dinî bir akademi çıktı.",
      [E("house", 0.4, 0.82, 1.3, lit=False), T(0.75, 0.25, "boarding school?", 1.1, "blue"), E("cross", 0.75, 0.25, 0.9, at=0.4),
       T(0.75, 0.5, "troubled youth", 1.1, "red")]),
    IMG("dennys", "a Denny's restaurant",
        "Later, as a teenager in Oregon, Huang worked at Denny's — washing dishes, bussing tables, and waiting on customers.",
        "Daha sonra Oregon'da bir gençken Huang, Denny's'te çalıştı: bulaşık yıkadı, masa topladı, müşterilere servis yaptı.",
        [E("sink", 0.45, 0.6, 1.3)]),
    S("He has often said those jobs taught him humility and hard work.", "Bu işlerin ona alçakgönüllülüğü ve çalışkanlığı öğrettiğini sık sık söyledi.",
      [E("sink", 0.3, 0.6, 1.0), T(0.72, 0.35, "humility", 1.2, "blue"), T(0.72, 0.55, "hard work", 1.2, "blue")]),
    S("He studied electrical engineering, worked as a chip designer,", "Elektrik mühendisliği okudu, çip tasarımcısı olarak çalıştı",
      [E("scroll", 0.3, 0.45, 0.8, text="B.S. · M.S."), E("chip", 0.72, 0.45, 0.9)]),
    S("and by his late twenties he had an idea about where computing was going.",
      "ve yirmilerinin sonunda bilgisayarların nereye gittiğine dair bir fikri vardı.",
      [E("head", 0.35, 0.5, 0.65, glow=True), E("screen", 0.75, 0.6, 0.9)]),
    # ------------------------------------------------------------ Bölüm 2
    S("In 1993, Huang and two engineers, *Chris Malachowsky* and *Curtis Priem*, met at a Denny's in San Jose and decided to start a company.",
      "1993'te Huang ve iki mühendis, *Chris Malachowsky* ve *Curtis Priem*, San Jose'deki bir Denny's'te buluşup bir şirket kurmaya karar verdi.",
      [E("table", 0.5, 0.65, 1.3), F(0.2, 0.45, "sit", y=0.75), F(0.8, 0.45, "sit", -1, y=0.75),
       T(0.5, 0.08, "San Jose · 1993", 1.0, "blue")]),
    S("They called it NVIDIA.", "Adını NVIDIA koydular.", [T(0.5, 0.42, "NVIDIA", 2.4, underline="red")]),
    S("Their bet: video games would need special chips to draw 3D graphics —", "Bahisleri şuydu: Video oyunları 3 boyutlu grafik çizmek için özel çiplere ihtiyaç duyacaktı;",
      [E("screen", 0.38, 0.62, 1.4), E("box", 0.38, 0.45, 0.6), E("chip", 0.78, 0.45, 0.7)]),
    S("chips that could do thousands of simple calculations at the same time.", "aynı anda binlerce basit hesap yapabilen çiplere.",
      [E("chip", 0.3, 0.45, 0.8), E("dots", 0.72, 0.45, 0.9, n=60, cols=12, highlight=60)]),
    S("The early years were brutal. Their first product struggled, and the company came close to running out of money.",
      "İlk yıllar çok zorlu geçti. İlk ürünleri tutmadı ve şirketin parası bitmek üzereydi.",
      [E("graph", 0.4, 0.5, 0.9, up=False), E("piggy", 0.8, 0.55, 0.6)]),
    S("For years afterward, Huang reportedly opened staff meetings with a line that became company legend:",
      "Sonraki yıllarda Huang'ın personel toplantılarını şirket efsanesine dönüşen bir cümleyle açtığı anlatılır:",
      [G(), F(0.25, 0.55, "point"), F(0.6, 0.4, face=-1), F(0.72, 0.4, face=-1), F(0.84, 0.4, face=-1)]),
    S("*\"Our company is thirty days from going out of business.\"*", "*\"Şirketimizin batmasına otuz gün var.\"*",
      [E("calendar", 0.5, 0.42, 1.3, text="30 days"), T(0.5, 0.88, "\"30 days from going out of business\"", 1.0, "red")]),
    IMG("geforce", "GeForce 256 · 1999",
        "In 1999, NVIDIA launched the *GeForce 256* and marketed it as the world's first *GPU* — a graphics processing unit.",
        "1999'da NVIDIA *GeForce 256*'yı piyasaya sürdü ve onu dünyanın ilk *GPU*'su, yani grafik işlem birimi olarak tanıttı.",
        [E("gpu", 0.5, 0.45, 1.2, label="GeForce 256 · 1999")]),
    S("Gamers loved it. But the most important thing about the GPU wasn't graphics at all.",
      "Oyuncular bayıldı. Ama GPU'nun en önemli yanı aslında grafik değildi.",
      [E("gpu", 0.4, 0.45, 0.9), T(0.8, 0.45, "?", 3.0, "red")]),
    # ------------------------------------------------------------ Bölüm 3
    S("A normal processor, a *CPU*, is like a few brilliant workers doing complex tasks one after another.",
      "Normal bir işlemci, yani *CPU*, karmaşık işleri sırayla yapan birkaç dâhi işçi gibidir.",
      [E("workers", 0.5, 0.82, 1.2, n=3), T(0.5, 0.12, "CPU", 1.6, "blue", underline="blue")]),
    S("A GPU is like thousands of simple workers doing small tasks all at once.", "GPU ise küçük işleri aynı anda yapan binlerce basit işçi gibidir.",
      [E("workers", 0.5, 0.85, 1.3, n=48, small=True), T(0.5, 0.12, "GPU", 1.6, "red", underline="red")]),
    S("That turned out to be exactly what another field needed: the kind of math used to train neural networks.",
      "Bu, başka bir alanın tam olarak ihtiyaç duyduğu şey çıktı: yapay sinir ağlarını eğitmek için kullanılan türden matematik.",
      [E("brain", 0.35, 0.45, 1.0), A(0.55, 0.45, 0.68, 0.45, bend=0.0), E("gpu", 0.82, 0.45, 0.5)]),
    S("In 2006, NVIDIA released *CUDA*, software that let scientists use GPUs for general computing, not just graphics.",
      "2006'da NVIDIA, bilim insanlarının GPU'ları sadece grafik için değil genel hesaplama için kullanmasını sağlayan *CUDA* yazılımını çıkardı.",
      [T(0.5, 0.25, "CUDA · 2006", 1.8, underline="red"), E("screen", 0.3, 0.8, 0.8), E("gpu", 0.72, 0.65, 0.6)]),
    S("It cost a lot to build, and for years many investors didn't see the point.",
      "Geliştirmesi çok pahalıydı ve yıllarca birçok yatırımcı ne işe yarayacağını anlamadı.",
      [E("money", 0.3, 0.6, 1.0, text="$$$"), G(), F(0.7, 0.5, "shrug", -1)]),
    S("Then, in 2012, a small team at the University of Toronto — *Alex Krizhevsky*, *Ilya Sutskever* and *Geoffrey Hinton* —",
      "Sonra 2012'de Toronto Üniversitesi'nden küçük bir ekip, *Alex Krizhevsky*, *Ilya Sutskever* ve *Geoffrey Hinton*,",
      [G(), F(0.3, 0.45), F(0.5, 0.5, "think"), F(0.7, 0.45, face=-1), T(0.5, 0.1, "Toronto · 2012", 1.1, "blue")]),
    IMG("gtx580", "GeForce GTX 580 chip",
        "trained a neural network called *AlexNet* on two NVIDIA gaming graphics cards.",
        "*AlexNet* adlı bir sinir ağını iki NVIDIA oyun ekran kartında eğitti.",
        [E("gpu", 0.3, 0.45, 0.65), E("gpu", 0.7, 0.45, 0.65), T(0.5, 0.85, "AlexNet", 1.4, "red")]),
    S("It crushed the competition in a major image recognition contest.", "Büyük bir görüntü tanıma yarışmasında rakiplerini ezdi geçti.",
      [E("eye", 0.3, 0.45, 0.9), E("stairs", 0.72, 0.8, 0.9, n=3), T(0.85, 0.2, "#1", 1.4, "red")]),
    S("Two gaming cards had helped kick off the deep learning revolution.", "İki oyun kartı derin öğrenme devriminin başlamasına yardım etmişti.",
      [E("gpu", 0.3, 0.5, 0.6), E("gpu", 0.3, 0.75, 0.6), A(0.47, 0.6, 0.62, 0.5, bend=0.0, color="red"), E("brain", 0.8, 0.45, 0.8)]),
    S("And NVIDIA was already holding the shovels.", "Ve NVIDIA kürekleri çoktan elinde tutuyordu.",
      [E("shovel", 0.5, 0.45, 1.2)]),
    # ------------------------------------------------------------ Bölüm 4
    S("There's an old saying about gold rushes: the people who got rich weren't always the miners — they were the ones selling shovels.",
      "Altına hücumla ilgili eski bir söz vardır: Zengin olanlar her zaman madenciler değildi; kürek satanlardı.",
      [E("mountain", 0.3, 0.85, 0.7), F(0.25, 0.25, "kick", y=0.85), E("shovel", 0.68, 0.5, 0.6), E("shovel", 0.78, 0.5, 0.6),
       E("shovel", 0.88, 0.5, 0.6), T(0.78, 0.12, "$", 2.0, "gold")]),
    S("When *ChatGPT* launched in late 2022, the AI gold rush began.", "*ChatGPT* 2022 sonunda çıktığında yapay zekâ altına hücumu başladı.",
      [E("screen", 0.4, 0.62, 1.4), B(0.4, 0.4, 0.5), T(0.8, 0.3, "late 2022", 1.1, "blue")]),
    S("Every major tech company suddenly needed enormous numbers of advanced chips to train and run AI models.",
      "Her büyük teknoloji şirketi yapay zekâ modellerini eğitmek ve çalıştırmak için aniden muazzam sayıda gelişmiş çipe ihtiyaç duydu.",
      [E("chip", 0.2, 0.3, 0.45), E("chip", 0.4, 0.3, 0.45), E("chip", 0.6, 0.3, 0.45), E("chip", 0.8, 0.3, 0.45),
       E("chip", 0.3, 0.7, 0.45), E("chip", 0.5, 0.7, 0.45), E("chip", 0.7, 0.7, 0.45)]),
    S("And NVIDIA made the best ones.", "Ve en iyilerini NVIDIA yapıyordu.",
      [E("chip", 0.5, 0.45, 1.2, glow=True), T(0.5, 0.88, "the best ones", 1.2, "red")]),
    IMG("datacenter", "data center server racks",
        "Data centers filled with its chips began appearing all over the world.",
        "Onun çipleriyle dolu veri merkezleri dünyanın her yerinde ortaya çıkmaya başladı.",
        [E("factory", 0.5, 0.85, 1.0)]),
    S("In 2023, NVIDIA's value passed one trillion dollars.", "2023'te NVIDIA'nın değeri bir trilyon doları geçti.",
      [E("graph", 0.45, 0.5, 1.0), T(0.5, 0.1, "$1T · 2023", 1.4, "blue")]),
    S("On October 29, 2025, it became the first company in history to pass five trillion.",
      "29 Ekim 2025'te beş trilyonu geçen tarihteki ilk şirket oldu.",
      [E("graph", 0.45, 0.5, 1.0), T(0.5, 0.1, "$5T · Oct 29, 2025", 1.4, "red", underline="red")]),
    IMG("huang2", "Jensen Huang · Stanford, 2026",
        "Huang, in his signature black leather jacket, became one of the most recognizable executives on Earth — and one of the richest.",
        "İmzası olan siyah deri ceketiyle Huang, dünyanın en tanınan ve en zengin yöneticilerinden biri oldu.",
        [E("spotlight", 0.5, 0.5, 1.0), F(0.5, 0.55, tone=0.98)]),
    # ------------------------------------------------------------ Bölüm 5
    S("So how does one chip company shape the world? In at least four ways.", "Peki tek bir çip şirketi dünyayı nasıl şekillendiriyor? En az dört şekilde.",
      [E("chip", 0.3, 0.45, 0.8), A(0.45, 0.45, 0.6, 0.45, bend=0.0), E("globe", 0.75, 0.48, 0.8), T(0.5, 0.88, "4 ways", 1.2, "red")]),
    S("*First, AI itself.* A huge share of the world's most advanced AI is trained on NVIDIA hardware.",
      "*Birincisi, yapay zekânın kendisi.* Dünyanın en gelişmiş yapay zekâ sistemlerinin büyük bir kısmı NVIDIA donanımı üzerinde eğitiliyor.",
      [T(0.1, 0.1, "1.", 1.6, "red"), E("ai", 0.5, 0.48, 1.1)]),
    S("When NVIDIA can't make chips fast enough, AI progress slows down everywhere.",
      "NVIDIA yeterince hızlı çip üretemediğinde yapay zekâ ilerlemesi her yerde yavaşlıyor.",
      [T(0.1, 0.1, "1.", 1.6, "red"), E("chip", 0.3, 0.45, 0.6), E("hourglass", 0.55, 0.45, 0.8), E("ai", 0.8, 0.45, 0.6)]),
    S("*Second, money.* NVIDIA became one of the largest companies in the stock market.",
      "*İkincisi, para.* NVIDIA borsadaki en büyük şirketlerden biri oldu.",
      [T(0.1, 0.1, "2.", 1.6, "red"), E("graph", 0.5, 0.5, 1.0)]),
    S("Millions of people's retirement savings move up and down with its share price — often without them knowing it.",
      "Milyonlarca insanın emeklilik birikimi, çoğu zaman haberleri bile olmadan, onun hisse fiyatıyla inip çıkıyor.",
      [T(0.1, 0.1, "2.", 1.6, "red"), E("piggy", 0.32, 0.5, 0.9), A(0.55, 0.5, 0.68, 0.5, bend=0.0), E("graph", 0.82, 0.5, 0.45)]),
    S("*Third, geopolitics.* Since 2022, the United States has restricted exports of the most advanced AI chips to China,",
      "*Üçüncüsü, jeopolitik.* ABD 2022'den beri en gelişmiş yapay zekâ çiplerinin Çin'e ihracatını kısıtlıyor",
      [T(0.1, 0.1, "3.", 1.6, "red"), T(0.2, 0.45, "USA", 1.4, "blue"), E("chip", 0.5, 0.45, 0.6), T(0.8, 0.45, "China", 1.4, "red"),
       E("padlock", 0.5, 0.78, 0.7)]),
    S("and NVIDIA has had to design special, weaker versions for that market.", "ve NVIDIA o pazar için daha zayıf özel versiyonlar tasarlamak zorunda kaldı.",
      [T(0.1, 0.1, "3.", 1.6, "red"), E("chip", 0.3, 0.45, 0.9), A(0.47, 0.45, 0.6, 0.45, bend=0.0), E("chip", 0.75, 0.48, 0.5),
       T(0.75, 0.8, "H20 · H800", 1.0, "red")]),
    IMG("tsmc", "TSMC fab · Taiwan",
        "At the same time, its chips are manufactured mostly in Taiwan.", "Aynı zamanda çipleri ağırlıklı olarak Tayvan'da üretiliyor.",
        [E("factory", 0.4, 0.85, 1.0), T(0.8, 0.3, "Taiwan", 1.3, "blue")]),
    S("A single company sits right on the fault line between the world's two largest economies.",
      "Tek bir şirket, dünyanın en büyük iki ekonomisi arasındaki fay hattının tam üzerinde duruyor.",
      [T(0.2, 0.3, "USA", 1.4, "blue"), T(0.8, 0.3, "China", 1.4, "red"), E("chip", 0.5, 0.42, 0.6),
       E("line", 0.1, 0.72, x2=0.9, y2=0.68, color="red"), T(0.5, 0.88, "the fault line", 1.0, "red")]),
    S("*Fourth, energy.* The data centers filled with these chips use vast amounts of electricity.",
      "*Dördüncüsü, enerji.* Bu çiplerle dolu veri merkezleri muazzam miktarda elektrik tüketiyor.",
      [T(0.1, 0.1, "4.", 1.6, "red"), E("factory", 0.5, 0.88, 1.1)]),
    S("The International Energy Agency has projected that global data center electricity use could roughly double by 2030, driven largely by AI.",
      "Uluslararası Enerji Ajansı, küresel veri merkezi elektrik tüketiminin büyük ölçüde yapay zekâ nedeniyle 2030'a kadar yaklaşık iki katına çıkabileceğini öngördü.",
      [T(0.1, 0.1, "4.", 1.6, "red"), E("graph", 0.45, 0.55, 0.9), T(0.82, 0.4, "×2", 2.2, "red"), T(0.82, 0.62, "by 2030", 1.0, "blue")]),
    S("Chips are not just products anymore. They are *power* — in every sense of the word.",
      "Çipler artık sadece ürün değil. Kelimenin her anlamında *güç*.",
      [E("chip", 0.5, 0.45, 1.3, glow=True), T(0.5, 0.88, "power", 1.6, "red", underline="red")]),
    # ------------------------------------------------------------ Bölüm 6
    S("When a company becomes this important, something interesting happens in our heads: we start to see it as *one person*.",
      "Bir şirket bu kadar önemli hale geldiğinde kafamızda ilginç bir şey olur: Onu *tek bir insan* olarak görmeye başlarız.",
      [E("house", 0.3, 0.82, 1.0), T(0.5, 0.5, "=", 2.0), G(), F(0.75, 0.5)]),
    S("In 1840, the Scottish writer *Thomas Carlyle* argued that *\"the history of the world is but the biography of great men.\"*",
      "1840'ta İskoç yazar *Thomas Carlyle* *\"dünya tarihi, büyük adamların biyografisinden başka bir şey değildir\"* diye yazdı.",
      [E("portrait_frame", 0.3, 0.45, 1.0, text="Thomas Carlyle"), E("scroll", 0.75, 0.45, 0.8, text="1840")], key="carlyle", label="Thomas Carlyle · 1795–1881"),
    S("This became known as the *Great Man theory* of history.", "Bu, tarihe dair *Büyük Adam kuramı* olarak bilinir hale geldi.",
      [G(0.9), F(0.5, 0.62, y=0.9), F(0.2, 0.2, y=0.9), F(0.3, 0.2, y=0.9), F(0.7, 0.2, y=0.9), F(0.8, 0.2, y=0.9),
       T(0.5, 0.08, "the Great Man theory", 1.3, underline="red")]),
    S("Critics, like the philosopher *Herbert Spencer*, pushed back: great people are products of their societies.",
      "Filozof *Herbert Spencer* gibi eleştirmenler buna karşı çıktı: Büyük insanlar toplumlarının ürünüdür.",
      [E("portrait_frame", 0.3, 0.45, 1.0, text="Herbert Spencer"), E("workers", 0.75, 0.8, 0.8, n=24, small=True)], key="spencer", label="Herbert Spencer · 1820–1903"),
    S("Without the right conditions, no single person changes anything.", "Doğru koşullar olmadan hiçbir tek kişi bir şey değiştiremez.",
      [E("workers", 0.5, 0.88, 1.2, n=36, small=True), F(0.5, 0.35, y=0.56), T(0.5, 0.08, "on the shoulders of many", 1.1, "blue")]),
    IMG("thorndike", "Edward Thorndike · 1874–1949",
        "Psychology adds another twist. In 1920, psychologist *Edward Thorndike* described the *halo effect*:",
        "Psikoloji bir dönemeç daha ekliyor. 1920'de psikolog *Edward Thorndike* *hale etkisini* tanımladı:",
        [T(0.5, 0.42, "the halo effect", 1.8, underline="red")]),
    S("when we see one impressive quality in a person, we tend to assume they're impressive in other ways too —",
      "Bir insanda etkileyici bir özellik gördüğümüzde, başka açılardan da etkileyici olduğunu varsayma eğilimindeyiz:",
      [E("halo", 0.4, 0.2, 0.8), G(), F(0.4, 0.55), T(0.78, 0.4, "brilliant", 1.1, "blue")]),
    S("smarter, more trustworthy, more moral.", "daha zeki, daha güvenilir, daha ahlaklı.",
      [E("halo", 0.4, 0.2, 0.8), G(), F(0.4, 0.55), T(0.78, 0.3, "smarter", 1.0, "blue"), T(0.78, 0.47, "trustworthy", 1.0, "blue"),
       T(0.78, 0.64, "moral", 1.0, "blue")]),
    S("A brilliant engineer and visionary CEO starts to look like someone who can't make mistakes.",
      "Parlak bir mühendis ve vizyoner bir CEO, hata yapamayacak biri gibi görünmeye başlar.",
      [E("halo", 0.5, 0.2, 0.9), G(), F(0.5, 0.58, tone=0.98), T(0.5, 0.92, "no mistakes?", 1.0, "red")]),
    S("And investors, employees and governments begin to rely on that one person far more than is safe.",
      "Ve yatırımcılar, çalışanlar ve hükümetler o tek kişiye güvenli olandan çok daha fazla yaslanmaya başlar.",
      [E("seesaw", 0.5, 0.82, 1.0)]),
    # ------------------------------------------------------------ Bölüm 7
    S("In early November 2026, that halo cracked.", "Kasım 2026'nın başında o hale çatladı.",
      [E("halo", 0.5, 0.4, 1.4, cracked=True), T(0.5, 0.85, "November 2026", 1.1, "red")]),
    S("On November 8, Huang sent a note to NVIDIA staff admitting that he had been unfaithful to his wife.",
      "8 Kasım'da Huang, NVIDIA çalışanlarına gönderdiği bir notta eşini aldattığını itiraf etti.",
      [E("letter", 0.45, 0.45, 1.2, text="to all staff"), T(0.82, 0.15, "Nov 8", 1.1, "blue")]),
    S("On its own, that would have been a private matter.", "Tek başına bu özel bir mesele olurdu.",
      [E("door", 0.5, 0.8, 1.0, label="private")]),
    S("But several U.S. outlets reported something far more serious:", "Ama birkaç ABD medya kuruluşu çok daha ciddi bir şey bildirdi:",
      [E("newspaper", 0.3, 0.45, 0.8, head="REPORT"), E("newspaper", 0.7, 0.5, 0.8, head="REPORT")]),
    S("that the woman involved was suspected by American officials of having ties to Chinese intelligence —",
      "Söz konusu kadının ABD'li yetkililer tarafından Çin istihbaratıyla bağlantılı olduğundan şüphelenildiğini",
      [E("magnifier", 0.35, 0.42, 1.0), T(0.72, 0.4, "suspected", 1.3, "red"), T(0.72, 0.6, "(not charged)", 0.9, "blue")]),
    S("and that a company linked to her had bought billions of dollars of NVIDIA chips,",
      "ve ona bağlı bir şirketin milyarlarca dolarlık NVIDIA çipi satın aldığını,",
      [E("money", 0.3, 0.6, 1.0, text="$4.8B"), A(0.45, 0.45, 0.6, 0.45, bend=0.0), E("chip", 0.78, 0.45, 0.6), T(0.5, 0.1, "reported", 1.0, "red")]),
    S("amid long-running concerns about advanced chips being smuggled into China.",
      "gelişmiş çiplerin Çin'e kaçırıldığına dair uzun süredir devam eden endişeler sürerken.",
      [E("box", 0.4, 0.55, 1.0), E("chip", 0.4, 0.4, 0.35), A(0.55, 0.5, 0.75, 0.5, bend=-0.2, color="red"), T(0.85, 0.5, "China", 1.2, "red")]),
    S("She has not been charged, and the company linked to her has denied wrongdoing.",
      "Kadın hakkında herhangi bir suçlama yapılmadı ve ona bağlı şirket herhangi bir yanlışı reddetti.",
      [T(0.5, 0.32, "not charged", 1.5, "blue"), T(0.5, 0.55, "denies wrongdoing", 1.5, "blue", underline="blue")]),
    S("NVIDIA's board launched an independent investigation, led by a committee of independent directors with outside lawyers.",
      "NVIDIA'nın yönetim kurulu, bağımsız yöneticilerden oluşan bir komite ve dışarıdan avukatlarla bağımsız bir soruşturma başlattı.",
      [E("table", 0.4, 0.7, 1.2), F(0.2, 0.38, "sit", y=0.72), F(0.6, 0.38, "sit", -1, y=0.72), E("magnifier", 0.82, 0.3, 0.6),
       T(0.5, 0.1, "independent investigation", 1.1, "blue")]),
    S("The company said it had no reason to believe that national security or NVIDIA's secrets had been compromised.",
      "Şirket, ulusal güvenliğin ya da NVIDIA'nın sırlarının tehlikeye girdiğine inanmak için bir sebep olmadığını açıkladı.",
      [E("padlock", 0.3, 0.45, 1.0), T(0.68, 0.35, "\"no reason to believe", 0.9, "blue"), T(0.68, 0.52, "secrets were compromised\"", 0.9, "blue")]),
    S("Still, the reaction was fast. Lawmakers called on Huang to testify before Congress.",
      "Yine de tepki hızlı geldi. Milletvekilleri Huang'ı Kongre'de ifade vermeye çağırdı.",
      [E("capitol", 0.45, 0.85, 1.0), T(0.82, 0.2, "testify?", 1.2, "red")]),
    S("A shareholder lawsuit was filed.", "Bir hissedar davası açıldı.",
      [E("balance", 0.5, 0.5, 0.9), T(0.5, 0.08, "lawsuit", 1.3, "red")]),
    S("And on November 11, *The Wall Street Journal* reported that the board was preparing to remove him as CEO, citing people familiar with the matter.",
      "Ve 11 Kasım'da *The Wall Street Journal*, konuya yakın kaynaklara dayanarak yönetim kurulunun onu CEO'luktan almaya hazırlandığını bildirdi.",
      [E("newspaper", 0.38, 0.45, 1.0, head="WSJ · Nov 11"), E("chair", 0.8, 0.75, 1.0), T(0.8, 0.3, "?", 2.0, "red")]),
    S("Further reports described a separate relationship with an NVIDIA employee.", "Başka haberler NVIDIA'dan bir çalışanla ayrı bir ilişkiyi de aktardı.",
      [E("newspaper", 0.5, 0.45, 0.9, head="REPORT")]),
    S("NVIDIA's stock, which had already been sliding, fell sharply.", "Zaten düşüşte olan NVIDIA hissesi sert biçimde düştü.",
      [E("graph", 0.5, 0.5, 1.1, up=False)]),
    S("In after-hours trading on November 11, it stood roughly a third below its October high.",
      "11 Kasım'da mesai sonrası işlemlerde ekim zirvesinin yaklaşık üçte bir altındaydı.",
      [E("graph", 0.45, 0.5, 1.0, up=False), T(0.82, 0.45, "-33%", 1.8, "red")]),
    S("As of this recording, no final decision has been announced.", "Bu kaydın yapıldığı an itibarıyla nihai bir karar açıklanmadı.",
      [E("chair", 0.5, 0.75, 1.3), T(0.5, 0.1, ASOF, 1.2, "blue", underline="blue"), T(0.5, 0.9, "no decision yet", 1.0, "red")]),
    # ------------------------------------------------------------ Bölüm 8
    S("Engineers have a name for a part of a system that, if it fails, brings everything down: a *single point of failure*.",
      "Mühendislerin, bir sistemde bozulduğunda her şeyi çökerten parçaya verdiği bir isim var: *tek hata noktası*.",
      [E("bridge", 0.5, 0.5, 0.9, cracked=True), T(0.5, 0.1, "single point of failure", 1.3, "red", underline="red")]),
    S("Good systems are designed to avoid them.", "İyi sistemler bunlardan kaçınacak şekilde tasarlanır.",
      [E("network", 0.5, 0.48, 0.9, extra=True), T(0.5, 0.9, "backups", 1.1, "blue")]),
    S("Investors have a similar idea: *key person risk* — when a company's value depends heavily on one individual.",
      "Yatırımcıların da benzer bir kavramı var: *kilit kişi riski*, yani bir şirketin değerinin büyük ölçüde tek bir kişiye bağlı olması.",
      [E("seesaw", 0.5, 0.82, 1.0), T(0.5, 0.1, "key person risk", 1.4, underline="red")]),
    S("For years, NVIDIA's story was told as Jensen Huang's story. His vision, his bets, his jacket.",
      "Yıllarca NVIDIA'nın hikâyesi Jensen Huang'ın hikâyesi olarak anlatıldı. Onun vizyonu, onun bahisleri, onun ceketi.",
      [E("spotlight", 0.4, 0.5, 1.0), F(0.4, 0.55, tone=0.98), T(0.8, 0.3, "vision", 1.0, "blue"), T(0.8, 0.47, "bets", 1.0, "blue"),
       T(0.8, 0.64, "jacket", 1.0, "blue")]),
    IMG("hq", "NVIDIA headquarters · Santa Clara",
        "That story helped build one of the most valuable companies in history.", "Bu hikâye tarihin en değerli şirketlerinden birini inşa etmeye yardım etti.",
        [E("graph", 0.5, 0.5, 1.0)]),
    S("But it also meant that a crisis in one person's life could shake markets, worry governments,",
      "Ama aynı zamanda tek bir insanın hayatındaki bir krizin piyasaları sarsabileceği, hükümetleri endişelendirebileceği",
      [G(), F(0.2, 0.45), A(0.3, 0.45, 0.45, 0.45, bend=0.0, color="red"), E("graph", 0.6, 0.45, 0.4, up=False), E("capitol", 0.85, 0.75, 0.45)]),
    S("and raise questions about the security of the technology the whole AI industry runs on.",
      "ve bütün yapay zekâ sektörünün üzerinde çalıştığı teknolojinin güvenliği hakkında sorular doğurabileceği anlamına da geliyordu.",
      [E("chip", 0.4, 0.45, 1.0), E("warning", 0.75, 0.42, 0.6)]),
    S("Whatever the board decides, the lesson is bigger than one man.", "Yönetim kurulu ne karar verirse versin, ders tek bir adamdan büyük.",
      [E("chair", 0.3, 0.75, 1.0), T(0.7, 0.42, "bigger than\none man", 1.3, "blue")]),
    S("When a society builds its future on a single company — and a single company on a single person —",
      "Bir toplum geleceğini tek bir şirketin, tek bir şirket de tek bir insanın üzerine kurduğunda,",
      [E("globe", 0.5, 0.25, 0.6), E("house", 0.5, 0.65, 0.7), G(0.92), F(0.5, 0.18, y=0.92)]),
    S("it isn't only betting on their genius. It's betting on their every decision.",
      "sadece onların dehasına bahse girmiyor. Her bir kararlarına bahse giriyor.",
      [T(0.5, 0.32, "genius", 1.5, "blue"), T(0.5, 0.58, "+ every decision", 1.5, "red", underline="red")]),
    # ------------------------------------------------------------ Bölüm 9
    S("Let's try something. Think about something you depend on every day — your job, a team, a family, a project.",
      "Bir şey deneyelim. Her gün bağlı olduğun bir şeyi düşün: işin, bir ekip, ailen, bir proje.",
      [T(0.12, 0.1, "try this", 1.0, "red", underline="red"), E("head", 0.35, 0.5, 0.6), B(0.7, 0.4, 1.2, "thought", tail=[0.42, 0.35]),
       T(0.7, 0.4, "job · team · family", 0.6)]),
    S("Now ask: is there one person, or one thing, that if it suddenly disappeared, everything would stop?",
      "Şimdi sor: Aniden ortadan kalksa her şeyi durduracak tek bir kişi ya da tek bir şey var mı?",
      [E("network", 0.5, 0.48, 0.9), E("circle", 0.5, 0.48, 0.6, color="red"), T(0.5, 0.92, "if it disappeared?", 1.0, "red")]),
    S("If the answer is yes, you've found your single point of failure.", "Cevap evetse, kendi tek hata noktanı buldun.",
      [E("network", 0.5, 0.48, 0.9), E("cross", 0.5, 0.48, 0.5, at=0.6)]),
    S("And the fix is usually the same for companies and for people: share knowledge, build backups,",
      "Ve çözüm şirketler için de insanlar için de genellikle aynı: bilgiyi paylaş, yedekler kur",
      [E("network", 0.5, 0.48, 0.9, extra=True)]),
    S("and don't confuse one person's brilliance with a system's strength.", "ve bir kişinin parlaklığını bir sistemin gücüyle karıştırma.",
      [E("halo", 0.28, 0.25, 0.6), G(0.85), F(0.28, 0.45, y=0.85), T(0.5, 0.5, "≠", 2.0, "red"), E("network", 0.75, 0.5, 0.55, extra=True)]),
    # ------------------------------------------------------------ Kapanış
    S("A dishwasher from Denny's helped build the machine at the center of the AI age.",
      "Denny's'ten bir bulaşıkçı, yapay zekâ çağının merkezindeki makineyi inşa etmeye yardım etti.",
      [E("sink", 0.22, 0.6, 0.6), A(0.36, 0.5, 0.45, 0.5, bend=0.0), E("chip", 0.55, 0.5, 0.55), A(0.66, 0.5, 0.74, 0.5, bend=0.0),
       E("globe", 0.85, 0.5, 0.55)]),
    S("That part of the story is real, and remarkable.", "Hikâyenin bu kısmı gerçek ve olağanüstü.",
      [T(0.5, 0.42, "real & remarkable", 1.6, "blue", underline="blue")]),
    S("But the most important chapter may be the one being written right now —", "Ama en önemli bölüm belki şu anda yazılan bölüm:",
      [E("scroll", 0.5, 0.45, 1.1, text="next chapter?")]),
    S("not about how one man rose, but about whether the systems around him are strong enough to survive without him.",
      "Bir adamın nasıl yükseldiği değil, etrafındaki sistemlerin onsuz ayakta kalacak kadar güçlü olup olmadığı.",
      [E("bridge", 0.5, 0.5, 0.9), T(0.5, 0.1, "strong enough?", 1.3, "red")]),
    S("Because in the end, the most powerful technology in the world still runs on something very old and very fragile:",
      "Çünkü sonunda dünyanın en güçlü teknolojisi hâlâ çok eski ve çok kırılgan bir şeyle çalışıyor:",
      [E("chip", 0.5, 0.45, 1.0, glow=True)]),
    S("*human beings*.", "*insanlarla*.",
      [G(), F(0.5, 0.6), E("chip", 0.58, 0.48, 0.2, glow=True), T(0.5, 0.1, "human beings", 1.6, "red", underline="red")]),
]

# Carlyle / Spencer portreleri indirildiyse fotoğraf, değilse çizim
for i, sc in enumerate(scenes):
    k = sc.pop("key", None)
    lab = sc.pop("label", None)
    if k and k in IMGS:
        scenes[i] = dict(say=sc["say"], image=dict(file=IMGS[k], style="sketch", fit="contain", label=lab, tint=0.3))

subscribe = dict(after=7, sketch=[dict(el="subscribe", x=0.45, y=0.45, s=1.4), dict(el="arrow", x=0.2, y=0.75, x2=0.33, y2=0.55, color="red", s=1.2)],
                 say={"en": "Quick favor before we start: if you like stories about the people and ideas shaping our world, *subscribe*. It genuinely helps the channel.",
                      "tr": "Başlamadan küçük bir rica: Dünyamızı şekillendiren insanlar ve fikirlerle ilgili hikâyeleri seviyorsan *abone ol*. Kanala gerçekten çok yardımı oluyor."})
meta = {"en": dict(title="Jensen Huang & NVIDIA", description="", tags=[]), "tr": dict(title="Jensen Huang ve NVIDIA", description="", tags=[])}
out = dict(slug="nvidia", format="long", theme="karakalem", character="none", languages=["en"], subtitles=["tr"],
           voices={"en": "am_fenrir"}, speech_rate=0.88, meta=meta, subscribe=subscribe, scenes=scenes)
json.dump(out, open(os.path.join(HERE, "nvidia.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
words = sum(len(s["say"]["en"].split()) for s in scenes) + len(subscribe["say"]["en"].split())
print(f"{len(scenes)} sahne, {words} kelime")
