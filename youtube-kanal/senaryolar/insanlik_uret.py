#!/usr/bin/env python3
"""İnsanlık videosunun sahne sahne senaryosu.  Çalıştır: python3 senaryolar/insanlik_uret.py -> senaryolar/insanlik.json"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
IMGS = {}
p = os.path.join(HERE, "insanlik_gorseller.json")
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


scenes = [
    # ------------------------------------------------------------ Açılış
    S("Two million years ago, our ancestors were not hunters. They were often the hunted.",
      "İki milyon yıl önce atalarımız avcı değildi. Çoğu zaman av olan onlardı.",
      [G(), F(0.25, 0.4, "walk", -1), E("leopard", 0.68, 0.62, 0.9, face=-1)]),
    S("Leopards dragged them into caves; their bones have been found with tooth marks.",
      "Leoparlar onları mağaralara sürüklüyordu; kemikleri diş izleriyle bulundu.",
      [E("cave", 0.3, 0.55, 0.7, fire=False), E("skull", 0.72, 0.45, 1.0), T(0.72, 0.85, "tooth marks", 1.0, "red")]),
    S("Today, there are about eight billion of us.", "Bugün yaklaşık sekiz milyarız.",
      [E("globe", 0.35, 0.5, 1.1), T(0.75, 0.45, "8,000,000,000", 1.2, "blue", underline="blue")]),
    S("We live on every continent, we've walked on the Moon, and we've changed the planet itself.",
      "Her kıtada yaşıyoruz, Ay'da yürüdük ve gezegenin kendisini değiştirdik.",
      [E("globe", 0.3, 0.55, 0.9), E("moon", 0.75, 0.3, 1.0), F(0.75, 0.15, y=0.48)]),
    S("So here's a strange fact: according to scientists, we are *not* at the top of the food chain.",
      "İşte tuhaf bir gerçek: Bilim insanlarına göre besin zincirinin tepesinde *değiliz*.",
      [E("stairs", 0.165, 0.85, 1.4, n=4), F(0.25, 0.22, y=0.71), T(0.5, 0.1, "not at the top?", 1.4, "red", underline="red")]),
    S("In 2013, a team of researchers calculated humanity's average \"trophic level\" — where we sit in the food chain — from what people actually eat around the world.",
      "2013'te bir araştırma ekibi, dünyada insanların gerçekte ne yediğine bakarak insanlığın ortalama \"trofik seviyesini\", yani besin zincirindeki yerimizi hesapladı.",
      [E("books", 0.3, 0.75, 0.9, n=2), E("magnifier", 0.3, 0.38, 0.7), T(0.72, 0.4, "trophic level", 1.3, underline="red"), T(0.72, 0.6, "2013", 1.0, "blue")]),
    S("The answer: about *2.2*.", "Cevap: yaklaşık *2,2*.", [T(0.5, 0.42, "2.2", 3.5, "red")]),
    S("That's roughly the same as an *anchovy*.", "Bu kabaca bir *hamsiyle* aynı.",
      [G(), F(0.3, 0.5), T(0.5, 0.5, "=", 2.0), E("fish", 0.75, 0.45, 1.2, label="anchovy · 2.2", color="blue")]),
    S("A polar bear or a killer whale sits near 5.", "Bir kutup ayısı ya da katil balina 5'e yakın.",
      [E("bear", 0.3, 0.5, 0.8), E("fish", 0.75, 0.45, 1.8), T(0.5, 0.12, "≈ 5", 1.8, "red")]),
    S("We're not the strongest predator. We're not even close.", "En güçlü avcı değiliz. Yakınından bile geçmiyoruz.",
      [E("leopard", 0.35, 0.5, 1.0), G(), F(0.8, 0.4, "shrug", -1)]),
    S("And yet we rule the planet.", "Yine de gezegene hükmediyoruz.",
      [E("globe", 0.5, 0.5, 1.2), F(0.5, 0.2, y=0.26)]),
    S("How?", "Nasıl?", [T(0.5, 0.42, "How?", 3.0, "red", underline="red")]),
    # ------------------------------------------------------------ Bölüm 1
    S("Look at the human body as a zoologist would.", "İnsan bedenine bir zoolog gibi bak.",
      [E("magnifier", 0.3, 0.4, 1.0), G(), F(0.7, 0.55)]),
    S("No claws. Small teeth. Thin skin.", "Pençe yok. Küçük dişler. İnce deri.",
      [G(), F(0.3, 0.55), T(0.72, 0.25, "no claws", 1.2, "red"), T(0.72, 0.45, "small teeth", 1.2, "red"), T(0.72, 0.65, "thin skin", 1.2, "red")]),
    S("We're slow sprinters: a rabbit can outrun the fastest person on Earth.", "Kısa mesafede yavaşız: Bir tavşan dünyanın en hızlı insanını geride bırakabilir.",
      [G(), F(0.3, 0.5, "walk"), E("antelope", 0.72, 0.62, 0.6), T(0.72, 0.15, "faster", 1.2, "blue")]),
    S("Pound for pound, a chimpanzee's muscles are roughly one and a half times more powerful than ours.",
      "Kilo başına bir şempanzenin kasları bizimkilerden yaklaşık bir buçuk kat daha güçlüdür.",
      [E("ape", 0.3, 0.6, 1.1), G(0.85), F(0.72, 0.55, y=0.85), T(0.3, 0.1, "×1.5", 1.6, "red")]),
    S("And our babies are almost uniquely helpless.", "Bebeklerimiz neredeyse benzersiz derecede çaresizdir.",
      [E("bed", 0.5, 0.8, 1.1), F(0.5, 0.18, "lie", y=0.68, child=True)]),
    S("A baby giraffe can stand within an hour. A human baby takes about a year to walk.",
      "Bir zürafa yavrusu bir saat içinde ayağa kalkar. Bir insan bebeğinin yürümesi yaklaşık bir yıl sürer.",
      [G(), E("antelope", 0.28, 0.62, 0.8), T(0.28, 0.12, "1 hour", 1.2, "blue"), F(0.72, 0.22, "lie", child=True), T(0.72, 0.12, "1 year", 1.2, "red")]),
    S("On paper, we're one of the worst-designed animals to dominate a planet.",
      "Kâğıt üzerinde, bir gezegene hükmetmek için en kötü tasarlanmış hayvanlardan biriyiz.",
      [E("scroll", 0.35, 0.45, 1.0, text="on paper"), E("cross", 0.72, 0.45, 1.0)]),
    # ------------------------------------------------------------ Bölüm 2: Ateş
    S("The first secret was *fire*.", "İlk sır *ateşti*.", [E("campfire", 0.5, 0.65, 1.6), T(0.5, 0.12, "fire", 1.8, "red", underline="red")]),
    S("Our ancestors were using fire at least hundreds of thousands of years ago, and possibly much earlier.",
      "Atalarımız ateşi en az yüz binlerce yıl önce kullanıyordu, belki çok daha önce.",
      [E("campfire", 0.35, 0.7, 1.2), T(0.72, 0.4, "100,000s", 1.3, "blue"), T(0.72, 0.6, "of years", 1.0, "blue")]),
    S("Fire gave light, warmth, and protection from predators.", "Ateş ışık, sıcaklık ve yırtıcılardan koruma sağladı.",
      [E("campfire", 0.45, 0.72, 1.1), F(0.3, 0.35, "sit", y=0.75), F(0.6, 0.35, "sit", -1, y=0.75), E("eye", 0.88, 0.3, 0.3), E("eye", 0.1, 0.3, 0.3)]),
    S("But its biggest gift was *cooking*.", "Ama en büyük armağanı *pişirmekti*.",
      [E("campfire", 0.5, 0.78, 1.0), E("meat", 0.5, 0.4, 0.8, cooked=True)]),
    S("Harvard anthropologist *Richard Wrangham* argues that cooking changed our bodies.",
      "Harvard antropoloğu *Richard Wrangham*, pişirmenin bedenlerimizi değiştirdiğini savunur.",
      [E("books", 0.3, 0.72, 1.0, n=1), T(0.3, 0.4, "Catching Fire", 1.1, "red"), T(0.72, 0.42, "Wrangham · 2009", 1.1, "blue")]),
    S("Cooked food is softer and gives more energy for less chewing and digestion.",
      "Pişmiş yemek daha yumuşaktır ve daha az çiğneme ve sindirimle daha fazla enerji verir.",
      [E("meat", 0.25, 0.5, 0.9), A(0.42, 0.5, 0.58, 0.5, bend=0.0), E("meat", 0.75, 0.55, 0.9, cooked=True), T(0.75, 0.88, "+ energy", 1.1, "blue")]),
    S("And that energy went somewhere expensive: the *brain*.", "Ve bu enerji pahalı bir yere gitti: *beyne*.",
      [E("meat", 0.25, 0.55, 0.7, cooked=True), A(0.4, 0.5, 0.55, 0.45, bend=0.0, color="red"), E("brain", 0.75, 0.45, 1.0)]),
    S("Your brain is about 2% of your body weight, but it uses roughly 20% of your energy.",
      "Beynin vücut ağırlığının yaklaşık %2'si, ama enerjinin kabaca %20'sini kullanıyor.",
      [E("brain", 0.3, 0.45, 1.0), T(0.72, 0.32, "2% weight", 1.3, "blue"), T(0.72, 0.55, "20% energy", 1.3, "red", underline="red")]),
    S("A big brain is a luxury, and cooking may have helped us afford it.", "Büyük bir beyin bir lükstür ve pişirmek onu karşılayabilmemize yardım etmiş olabilir.",
      [E("campfire", 0.28, 0.72, 0.9), T(0.5, 0.45, "=", 2.0), E("head", 0.75, 0.5, 0.6, glow=True)]),
    S("In a sense, we didn't just tame fire. Fire helped make us human.", "Bir anlamda ateşi sadece evcilleştirmedik. Ateş bizi insan yapmaya yardım etti.",
      [E("campfire", 0.5, 0.75, 1.3), T(0.5, 0.15, "fire made us human", 1.3, "red", underline="red")]),
    # ------------------------------------------------------------ Bölüm 3: Koşmak, fırlatmak
    S("The second secret is hiding in your legs.", "İkinci sır bacaklarında saklı.", [G(), F(0.5, 0.6, "walk"), E("circle", 0.5, 0.75, 0.8, rx=140, ry=160)]),
    S("We're bad sprinters, but we're incredible *long-distance* runners.", "Kısa mesafede kötüyüz ama *uzun mesafede* inanılmaz koşucularız.",
      [G(), F(0.3, 0.5, "walk"), T(0.72, 0.4, "long distance", 1.4, "blue", underline="blue")]),
    S("We sweat to cool down, we have long legs and springy Achilles tendons,", "Serinlemek için terleriz, uzun bacaklarımız ve esnek Aşil tendonlarımız var",
      [G(), F(0.4, 0.6, "walk"), E("dot", 0.44, 0.3, 0.4, color="blue"), E("dot", 0.36, 0.38, 0.4, color="blue"), T(0.75, 0.3, "sweat", 1.1, "blue"),
       T(0.75, 0.6, "Achilles", 1.1, "red")]),
    S("and we can keep running in the heat long after most animals have to stop.", "ve çoğu hayvan durmak zorunda kaldıktan çok sonra bile sıcakta koşmaya devam edebiliriz.",
      [E("sun", 0.85, 0.18, 0.8), G(), F(0.3, 0.5, "walk"), E("antelope", 0.7, 0.62, 0.7, tired=True)]),
    S("Scientists *Daniel Lieberman* and *Dennis Bramble* argue this allowed *persistence hunting*:",
      "Bilim insanları *Daniel Lieberman* ve *Dennis Bramble*, bunun *dayanıklılık avcılığını* mümkün kıldığını savunur:",
      [T(0.5, 0.35, "persistence hunting", 1.6, underline="red"), T(0.5, 0.58, "Bramble & Lieberman · 2004", 1.0, "blue")]),
    S("chasing an animal in the midday heat, for hours, until it collapses from exhaustion.",
      "bir hayvanı öğle sıcağında saatlerce, yorgunluktan yığılıp kalana kadar kovalamak.",
      [E("sun", 0.5, 0.15, 0.7), G(), F(0.25, 0.45, "walk"), E("antelope", 0.72, 0.65, 0.8, tired=True), E("hourglass", 0.5, 0.5, 0.6)]),
    S("Some hunters in the Kalahari have been documented doing exactly this in recent times.",
      "Kalahari'de bazı avcıların yakın zamanda tam olarak bunu yaptığı belgelendi.",
      [E("sun", 0.85, 0.15, 0.6), G(), F(0.3, 0.45, "walk"), F(0.42, 0.45, "walk"), T(0.7, 0.4, "Kalahari", 1.3, "blue")]),
    S("And then there's *throwing*.", "Bir de *fırlatmak* var.", [G(), F(0.3, 0.55, "reach"), E("spear", 0.65, 0.35, 0.8)]),
    S("Humans are the only animals that can throw hard and accurately.", "İnsanlar güçlü ve isabetli fırlatabilen tek hayvanlardır.",
      [G(), F(0.2, 0.5, "reach"), A(0.3, 0.3, 0.75, 0.5, bend=-0.2, color="red"), E("circle", 0.8, 0.55, 0.6)]),
    S("A 2013 study found that changes in our shoulders, appearing around two million years ago, work like a catapult,",
      "2013'te yapılan bir çalışma, yaklaşık iki milyon yıl önce ortaya çıkan omuz değişikliklerimizin bir mancınık gibi çalıştığını buldu:",
      [G(), F(0.3, 0.55, "reach"), E("circle", 0.33, 0.35, 0.5, color="blue"), T(0.72, 0.35, "a catapult", 1.3, "red"), T(0.72, 0.55, "2 million years", 1.0, "blue")]),
    S("storing energy and releasing it in a snap.", "enerjiyi depolayıp bir anda serbest bırakıyor.",
      [E("spear", 0.5, 0.45, 1.3), T(0.5, 0.85, "snap!", 1.4, "red")]),
    S("We didn't need to be strong. We could tire our prey out, and hit it from a distance.",
      "Güçlü olmamız gerekmiyordu. Avımızı yorabilir ve ona uzaktan vurabilirdik.",
      [G(), F(0.2, 0.45, "reach"), E("spear", 0.48, 0.4, 0.6), E("mammoth", 0.78, 0.55, 0.7)]),
    # ------------------------------------------------------------ Bölüm 4: Burke & Wills
    S("But fire, running and throwing still don't explain everything.", "Ama ateş, koşmak ve fırlatmak hâlâ her şeyi açıklamıyor.",
      [E("campfire", 0.2, 0.6, 0.7), E("antelope", 0.5, 0.55, 0.6), E("spear", 0.8, 0.5, 0.5), T(0.5, 0.88, "not enough", 1.1, "red")]),
    S("Other species have had their own superpowers. None of them built cities.", "Başka türlerin de kendi süper güçleri oldu. Hiçbiri şehir kurmadı.",
      [E("leopard", 0.25, 0.5, 0.7), E("fish", 0.25, 0.85, 0.6), E("house", 0.72, 0.8, 0.8), E("cross", 0.72, 0.6, 0.8, at=1.0)]),
    S("The real secret, many researchers argue, is something you can't see in a skeleton:",
      "Birçok araştırmacıya göre asıl sır bir iskelette göremeyeceğin bir şey:",
      [E("skull", 0.35, 0.45, 1.0, marks=False), T(0.72, 0.45, "?", 2.6, "red")]),
    S("*we learn from each other, and the knowledge adds up*.", "*birbirimizden öğreniyoruz ve bilgi birikiyor*.",
      [E("heads", 0.5, 0.45, 1.0, n=3), T(0.5, 0.88, "learning adds up", 1.2, "blue", underline="blue")]),
    S("Here's a story that shows it.", "Bunu gösteren bir hikâye var.", [E("scroll", 0.5, 0.45, 1.1, text="1860")]),
    IMG("burke", "Burke & Wills set out · Melbourne, 1860",
        "In 1860, the explorers *Burke* and *Wills* set out to cross Australia from south to north.",
        "1860'ta kâşifler *Burke* ve *Wills*, Avustralya'yı güneyden kuzeye geçmek için yola çıktı.",
        [E("australia", 0.5, 0.5, 1.2), A(0.52, 0.8, 0.5, 0.25, bend=0.1, color="red")]),
    S("They were well funded and well equipped.", "Bol paraları ve iyi teçhizatları vardı.",
      [E("money", 0.3, 0.6, 1.0, text="£"), E("box", 0.7, 0.6, 1.0), E("box", 0.82, 0.62, 0.7)]),
    S("On the way back, they ran out of food.", "Dönüş yolunda yiyecekleri bitti.",
      [E("sun", 0.82, 0.15, 0.6), G(), F(0.35, 0.45, "walk"), F(0.5, 0.45, "walk"), E("basket", 0.75, 0.75, 0.6), T(0.75, 0.5, "empty", 1.0, "red")]),
    S("They found a plant called *nardoo*", "*Nardoo* adlı bir bitki buldular",
      [E("plant", 0.5, 0.75, 1.3), T(0.5, 0.1, "nardoo", 1.6, "blue", underline="blue")]),
    S("and learned from local Aboriginal people how to grind its seeds into flour.",
      "ve yerel Aborjin halkından tohumlarını öğütüp un yapmayı öğrendiler.",
      [E("plant", 0.25, 0.75, 0.8), A(0.36, 0.55, 0.5, 0.55, bend=0.0), E("stone", 0.65, 0.65, 1.0), E("dots", 0.85, 0.6, 0.4, n=20, cols=5, highlight=0)]),
    S("They ate it every day. And they kept getting weaker.", "Her gün yediler. Ve giderek zayıfladılar.",
      [E("graph", 0.5, 0.5, 1.0, up=False), T(0.5, 0.1, "weaker", 1.3, "red")]),
    S("What they didn't know was that nardoo, prepared the wrong way, contains an enzyme that destroys vitamin B1.",
      "Bilmedikleri şey, yanlış hazırlanan nardoonun B1 vitaminini yok eden bir enzim içermesiydi.",
      [E("plant", 0.3, 0.75, 0.9), E("warning", 0.72, 0.4, 0.8), T(0.72, 0.8, "destroys B1", 1.1, "red")]),
    S("The local *Yandruwandha* people prepared it with careful steps, using water, that made it safe.",
      "Yerel *Yandruwandha* halkı onu su kullanarak, dikkatli adımlarla hazırlıyor ve güvenli hale getiriyordu.",
      [T(0.2, 0.3, "1. grind", 1.1, "blue"), T(0.5, 0.3, "2. water", 1.1, "blue"), T(0.8, 0.3, "3. wash", 1.1, "blue"), G(), F(0.3, 0.4, "sit", y=0.8),
       F(0.7, 0.4, "sit", -1, y=0.8)]),
    S("Burke and Wills skipped those steps.", "Burke ve Wills bu adımları atladı.",
      [T(0.2, 0.42, "1.", 1.6), T(0.5, 0.42, "2.", 1.6), T(0.8, 0.42, "3.", 1.6), E("cross", 0.5, 0.42, 0.7, at=0.5), E("cross", 0.8, 0.42, 0.7, at=0.9)]),
    IMG("wills", "The death of Wills · S. T. Gill",
        "Both men died.", "İkisi de öldü.", [E("skull", 0.5, 0.45, 1.0, marks=False)]),
    S("One of their companions survived — because the Yandruwandha took him in and fed him.",
      "Arkadaşlarından biri hayatta kaldı, çünkü Yandruwandha halkı onu yanlarına alıp besledi.",
      [E("campfire", 0.5, 0.75, 0.9), F(0.3, 0.4, "sit", y=0.78), F(0.7, 0.4, "sit", -1, y=0.78), F(0.5, 0.35, "lie", y=0.9), E("heart", 0.5, 0.2, 0.5)]),
    S("Intelligent individuals, alone, could not survive where an entire culture had learned how to live.",
      "Zeki bireyler tek başlarına, koca bir kültürün nasıl yaşanacağını öğrendiği yerde hayatta kalamadı.",
      [G(), F(0.2, 0.45), T(0.2, 0.12, "alone", 1.1, "red"), F(0.55, 0.4), F(0.65, 0.42), F(0.75, 0.38), F(0.85, 0.4), T(0.7, 0.12, "a culture", 1.1, "blue")]),
    # ------------------------------------------------------------ Bölüm 5: Birikimli kültür
    S("Anthropologist *Joseph Henrich* calls this *cumulative culture*, and he argues it's the secret of our success.",
      "Antropolog *Joseph Henrich* buna *birikimli kültür* diyor ve bunun başarımızın sırrı olduğunu savunuyor.",
      [T(0.5, 0.35, "cumulative culture", 1.6, underline="red"), T(0.5, 0.58, "Henrich · The Secret of Our Success", 1.0, "blue")]),
    S("No single person invented the bow, the canoe, or the smartphone.", "Yayı, kanoyu ya da akıllı telefonu tek bir kişi icat etmedi.",
      [E("spear", 0.25, 0.45, 0.5), E("phone", 0.75, 0.45, 0.8), T(0.5, 0.85, "no single inventor", 1.1, "red")]),
    S("Each generation inherits what the last one figured out, adds a little, and passes it on.",
      "Her nesil bir öncekinin çözdüğünü devralır, biraz ekler ve aktarır.",
      [G(), F(0.2, 0.45, hat="bun"), A(0.28, 0.4, 0.42, 0.4, bend=-0.3), F(0.5, 0.45), A(0.58, 0.4, 0.72, 0.4, bend=-0.3), F(0.8, 0.3, child=True)]),
    S("Over thousands of years, a ladder of knowledge grows that no individual could ever climb alone.",
      "Binlerce yıl içinde hiçbir bireyin tek başına tırmanamayacağı bir bilgi merdiveni büyür.",
      [E("stairs", 0.08, 0.9, 1.4, n=5, labels=["stone", "fire", "bow", "print", "phone"])]),
    S("And we're built for this. Children are amazing copiers.", "Ve biz bunun için yaratılmışız. Çocuklar inanılmaz taklitçilerdir.",
      [G(), F(0.35, 0.55, "point"), F(0.65, 0.3, "point", child=True)]),
    S("In experiments, young children copy every step an adult shows them, even steps that are obviously useless,",
      "Deneylerde küçük çocuklar bir yetişkinin gösterdiği her adımı, açıkça işe yaramayan adımları bile kopyalar;",
      [E("box", 0.5, 0.65, 1.1), G(0.85), F(0.25, 0.3, "reach", child=True, y=0.85), T(0.5, 0.15, "1 · 2 · 3 · 4", 1.4, "blue")]),
    S("while chimpanzees skip straight to what works.", "şempanzeler ise doğrudan işe yarayana atlar.",
      [E("box", 0.5, 0.65, 1.1), E("ape", 0.8, 0.7, 0.6, face=-1), T(0.5, 0.15, "1 · 4", 1.4, "red")]),
    S("Psychologists call it *overimitation*.", "Psikologlar buna *aşırı taklit* diyor.", [T(0.5, 0.42, "overimitation", 2.0, underline="red")]),
    S("It sounds silly. But it's exactly what would have saved Burke and Wills:", "Saçma görünüyor. Ama Burke ve Wills'i kurtaracak olan tam olarak buydu:",
      [E("plant", 0.3, 0.75, 0.9), T(0.72, 0.42, "silly?", 1.5, "red")]),
    S("when you don't know *why* a step is there, copying it anyway can keep you alive.",
      "Bir adımın *neden* orada olduğunu bilmediğinde, yine de onu kopyalamak seni hayatta tutabilir.",
      [T(0.5, 0.3, "don't know why?", 1.3, "blue"), T(0.5, 0.55, "copy it anyway", 1.5, "red", underline="red")]),
    # ------------------------------------------------------------ Bölüm 6: İş birliği
    S("There's one more ingredient: we cooperate on a scale no other mammal does.",
      "Bir malzeme daha var: Başka hiçbir memelinin yapmadığı ölçekte iş birliği yapıyoruz.",
      [G(), F(0.3, 0.5, "hold"), F(0.7, 0.5, "hold", -1), E("line", 0.33, 0.42, x2=0.67, y2=0.42, w=4.0)]),
    S("Psychologist *Michael Tomasello* found that even toddlers spontaneously help strangers,",
      "Psikolog *Michael Tomasello*, küçük çocukların bile yabancılara kendiliğinden yardım ettiğini,",
      [G(), F(0.35, 0.55, "reach", -1), F(0.6, 0.3, "reach", child=True), E("box", 0.45, 0.72, 0.5), T(0.5, 0.1, "Tomasello", 1.1, "blue")]),
    S("point things out to share attention, and work toward shared goals.", "dikkat paylaşmak için bir şeyleri işaret ettiğini ve ortak hedefler için çalıştığını buldu.",
      [G(), F(0.3, 0.3, "point", child=True), E("butterfly", 0.75, 0.3, 0.8), F(0.5, 0.5, face=1)]),
    S("Great apes rarely do.", "Büyük maymunlar bunu nadiren yapar.", [E("ape", 0.5, 0.6, 1.1)]),
    S("Anthropologist *Robin Dunbar* suggested we can keep track of around 150 personal relationships.",
      "Antropolog *Robin Dunbar*, yaklaşık 150 kişisel ilişkiyi takip edebildiğimizi öne sürdü.",
      [E("dots", 0.4, 0.5, 1.0, n=150, cols=15, highlight=0), T(0.82, 0.45, "≈150", 1.6, "red")]),
    S("But humans found ways to cooperate far beyond that:", "Ama insanlar bunun çok ötesinde iş birliği yapmanın yollarını buldu:",
      [E("dots", 0.5, 0.55, 0.9, n=400, cols=40, highlight=0), T(0.5, 0.08, "millions", 1.3, "blue")]),
    S("through *stories, rules, gods and money*, things that exist because we all agree they do.",
      "*hikâyeler, kurallar, tanrılar ve para* aracılığıyla; hepimiz var olduklarında anlaştığımız için var olan şeyler.",
      [E("books", 0.18, 0.6, 0.6, n=2), E("scroll", 0.4, 0.45, 0.6), E("dot", 0.6, 0.4, 1.0), E("money", 0.82, 0.6, 0.7, text="$"),
       T(0.5, 0.88, "we all agree", 1.1, "red")]),
    IMG("gobekli", "Göbekli Tepe · Şanlıurfa, Türkiye",
        "One of the oldest monuments we know, *Göbekli Tepe* in southeastern Turkey, was built around 11,000 years ago,",
        "Bildiğimiz en eski anıtlardan biri, Türkiye'nin güneydoğusundaki *Göbeklitepe*, yaklaşık 11.000 yıl önce",
        [E("pillar", 0.35, 0.85, 1.0), E("pillar", 0.68, 0.85, 1.0)]),
    S("by people who, as far as we know, had not yet started farming.", "bildiğimiz kadarıyla henüz tarıma başlamamış insanlar tarafından inşa edildi.",
      [E("pillar", 0.3, 0.85, 1.0), T(0.7, 0.4, "before farming", 1.3, "red", underline="red")]),
    IMG("gobekli2", "Göbekli Tepe · carved animals",
        "Huge carved pillars, raised by hundreds of hands working together.", "Birlikte çalışan yüzlerce elin diktiği dev oymalı sütunlar.",
        [E("pillar", 0.5, 0.75, 1.0), G(0.9), F(0.2, 0.3, "hold", y=0.9), F(0.35, 0.3, "hold", y=0.9), F(0.65, 0.3, "hold", -1, y=0.9), F(0.8, 0.3, "hold", -1, y=0.9)]),
    S("Cooperation came first. Civilization followed.", "Önce iş birliği geldi. Uygarlık sonra.",
      [T(0.5, 0.32, "1. cooperation", 1.4, "blue"), T(0.5, 0.55, "2. civilization", 1.4)]),
    # ------------------------------------------------------------ Bölüm 7: Bedel
    S("And that's how a weak, slow ape took over a planet.", "İşte zayıf, yavaş bir maymun gezegeni böyle ele geçirdi.",
      [E("globe", 0.5, 0.5, 1.2), F(0.5, 0.2, y=0.26)]),
    IMG("mammoths", "Woolly mammoths · Charles R. Knight",
        "When humans arrived in Australia and the Americas, many giant animals, like giant kangaroos, mammoths and ground sloths, disappeared.",
        "İnsanlar Avustralya'ya ve Amerika'ya vardığında dev kangurular, mamutlar ve yer tembelleri gibi birçok dev hayvan ortadan kayboldu.",
        [E("mammoth", 0.4, 0.55, 1.0, faded=True)]),
    S("Scientists still debate how much was hunting and how much was climate, but the timing is hard to ignore.",
      "Bilim insanları bunun ne kadarının avcılık, ne kadarının iklim olduğunu hâlâ tartışıyor; ama zamanlamayı görmezden gelmek zor.",
      [E("balance", 0.5, 0.45, 0.9, tilt=0.15, left="?", right="?"), T(0.33, 0.88, "hunting", 1.2, "red"), T(0.67, 0.88, "climate", 1.2, "blue")]),
    S("Today, if you weighed every wild mammal on Earth, they would make up only about *4%* of all mammal biomass.",
      "Bugün Dünya'daki tüm yabani memelileri tartsan, bütün memeli kütlesinin yalnızca yaklaşık *%4*'ünü oluştururlar.",
      [E("dots", 0.5, 0.5, 1.0, n=100, cols=20, highlight=4), T(0.5, 0.1, "wild mammals: 4%", 1.4, "red")]),
    S("Humans are about a third. Our livestock — cows, pigs, sheep — make up most of the rest.",
      "İnsanlar yaklaşık üçte biri. Geri kalanın çoğu ise hayvanlarımız: inekler, domuzlar, koyunlar.",
      [E("bars", 0.5, 0.78, 1.0)]),
    S("We may not be at the top of the food chain.", "Belki besin zincirinin tepesinde değiliz.",
      [E("stairs", 0.165, 0.85, 1.4, n=4), F(0.25, 0.22, y=0.71)]),
    S("But we've become something no species has been before: the force that *shapes* the food chain.",
      "Ama hiçbir türün daha önce olmadığı bir şey olduk: besin zincirini *şekillendiren* güç.",
      [E("stairs", 0.06, 0.85, 1.2, n=4), E("hand", 0.82, 0.4, 1.0, face=-1), T(0.5, 0.1, "shapes the chain", 1.3, "red", underline="red")]),
    # ------------------------------------------------------------ Kendin dene
    S("Try this. Look around you right now,", "Şunu dene. Şu an etrafına bak", [T(0.12, 0.1, "try this", 1.0, "red", underline="red"), E("eye", 0.5, 0.45, 1.2)]),
    S("and count how many things you can see that you could make *entirely by yourself*, from scratch.",
      "ve *tamamen kendi başına*, sıfırdan yapabileceğin kaç şey gördüğünü say.",
      [E("chair", 0.2, 0.75, 0.9), E("tshirt", 0.45, 0.5, 0.6), E("phone", 0.68, 0.5, 0.7), E("screen", 0.88, 0.6, 0.5), T(0.5, 0.1, "by yourself?", 1.3, "blue")]),
    S("The chair? The glass? The clothes you're wearing? The device you're watching this on?",
      "Sandalye mi? Bardak mı? Üzerindeki kıyafetler mi? Bu videoyu izlediğin cihaz mı?",
      [E("chair", 0.2, 0.75, 0.9), E("tshirt", 0.45, 0.5, 0.6), E("phone", 0.68, 0.5, 0.7), E("screen", 0.88, 0.6, 0.5),
       T(0.2, 0.2, "?", 1.4, "red"), T(0.45, 0.15, "?", 1.4, "red"), T(0.68, 0.15, "?", 1.4, "red"), T(0.88, 0.2, "?", 1.4, "red")]),
    S("Probably zero.", "Muhtemelen sıfır.", [T(0.5, 0.42, "0", 4.0, "red")]),
    S("And that's not a weakness. It's the whole point.", "Ve bu bir zayıflık değil. Asıl mesele bu.",
      [T(0.5, 0.3, "not a weakness", 1.4, "blue"), T(0.5, 0.55, "the whole point", 1.5, "red", underline="red")]),
    S("You're surrounded by the knowledge of millions of people you'll never meet.", "Hiç tanışmayacağın milyonlarca insanın bilgisiyle çevrilisin.",
      [E("network", 0.5, 0.48, 1.0, extra=True)]),
    # ------------------------------------------------------------ Kapanış
    S("We didn't win because we were the strongest, or even because each of us was the smartest.",
      "Kazanmamızın sebebi en güçlü, hatta tek tek en zeki olmamız değildi.",
      [T(0.3, 0.35, "strongest", 1.3), E("cross", 0.3, 0.35, 0.6, at=0.6), T(0.7, 0.55, "smartest", 1.3), E("cross", 0.7, 0.55, 0.6, at=1.2)]),
    S("We won because we learned to share fire, share knowledge, and share goals with people we'd never met.",
      "Kazandık, çünkü ateşi, bilgiyi ve hedefleri hiç tanımadığımız insanlarla paylaşmayı öğrendik.",
      [E("campfire", 0.2, 0.65, 0.7), E("books", 0.5, 0.65, 0.6, n=2), E("heads", 0.8, 0.45, 0.6, n=3), T(0.5, 0.12, "share", 1.4, "blue", underline="blue")]),
    S("That's our superpower.", "Bu bizim süper gücümüz.", [E("heads", 0.5, 0.45, 1.1, n=5), T(0.5, 0.88, "superpower", 1.4, "red")]),
    S("And it comes with a question that no other species has ever had to answer:", "Ve beraberinde başka hiçbir türün cevaplamak zorunda kalmadığı bir soru getiriyor:",
      [E("globe", 0.5, 0.48, 1.1)]),
    S("now that we shape the planet, what will we *do* with it?", "Artık gezegeni şekillendirdiğimize göre, onunla ne *yapacağız*?",
      [E("globe", 0.4, 0.5, 1.0), E("hand", 0.65, 0.55, 0.9, face=-1), T(0.82, 0.3, "?", 2.6, "red")]),
]

subscribe = dict(after=12, sketch=[dict(el="subscribe", x=0.45, y=0.45, s=1.4), dict(el="arrow", x=0.2, y=0.75, x2=0.33, y2=0.55, color="red", s=1.2)],
                 say={"en": "If you like big questions about who we are and how we got here, *subscribe*. It genuinely helps the channel.",
                      "tr": "Kim olduğumuz ve buraya nasıl geldiğimizle ilgili büyük soruları seviyorsan *abone ol*. Kanala gerçekten çok yardımı oluyor."})
meta = {"en": dict(title="How Did Humans Get to the Top?", description="", tags=[]), "tr": dict(title="İnsanlık Neden Başarılı?", description="", tags=[])}
out = dict(slug="insanlik", format="long", theme="karakalem", character="none", languages=["en"], subtitles=["tr"],
           voices={"en": "am_fenrir"}, speech_rate=0.88, meta=meta, subscribe=subscribe, scenes=scenes)
json.dump(out, open(os.path.join(HERE, "insanlik.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
words = sum(len(s["say"]["en"].split()) for s in scenes) + len(subscribe["say"]["en"].split())
print(f"{len(scenes)} sahne, {words} kelime")
