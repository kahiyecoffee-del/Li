#!/usr/bin/env python3
"""Moda videosunun sahne sahne senaryosu.  Çalıştır: python3 senaryolar/moda_uret.py -> senaryolar/moda.json"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
IMGS = {}
p = os.path.join(HERE, "moda_gorseller.json")
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
    S("Scientists who want to know when humans started wearing clothes have found an unexpected witness: *lice*.",
      "İnsanların ne zaman giysi giymeye başladığını bilmek isteyen bilim insanları beklenmedik bir tanık buldu: *bitler*.",
      [E("magnifier", 0.3, 0.42, 1.0), E("louse", 0.7, 0.5, 1.1)]),
    S("Head lice live in your hair. Body lice live in clothing.", "Baş bitleri saçında yaşar. Vücut bitleri ise giysilerde.",
      [E("head", 0.25, 0.5, 0.55), E("louse", 0.32, 0.22, 0.35), E("tshirt", 0.72, 0.5, 0.8), E("louse", 0.72, 0.5, 0.35)]),
    S("And by comparing their DNA, researchers estimated that body lice split off from head lice roughly 170,000 years ago,",
      "Araştırmacılar DNA'larını karşılaştırarak vücut bitlerinin baş bitlerinden kabaca 170.000 yıl önce ayrıldığını hesapladı.",
      [E("line", 0.15, 0.5, x2=0.45, y2=0.5, w=1.5), E("line", 0.45, 0.5, x2=0.85, y2=0.3, color="blue", w=1.5), E("line", 0.45, 0.5, x2=0.85, y2=0.7, color="red", w=1.5),
       T(0.45, 0.85, "≈ 170,000 years ago", 1.2, "red")]),
    S("which suggests that's around when our ancestors started regularly wearing clothes.",
      "Bu da atalarımızın düzenli olarak giysi giymeye yaklaşık o sıralarda başladığını gösteriyor.",
      [G(), F(0.5, 0.55, tone=0.75), T(0.5, 0.1, "the first clothes", 1.3, "blue")]),
    S("That makes sense. Clothes kept us warm as we spread into colder lands.", "Mantıklı. Daha soğuk topraklara yayılırken giysiler bizi sıcak tuttu.",
      [E("stars", 0.5, 0.3, 1.0, n=30, h=0.4), G(), F(0.3, 0.45, "walk"), F(0.45, 0.42, "walk"), T(0.78, 0.4, "cold", 1.5, "blue")]),
    S("But here's the puzzle. Somewhere along the way, clothing stopped being only about warmth.",
      "Ama bulmaca şu: Bir yerlerde giysi sadece sıcaklıkla ilgili olmaktan çıktı.", [T(0.5, 0.42, "?", 4.0, "red")]),
    S("Today, people pay thousands for a bag that holds the same things as a cheap one.",
      "Bugün insanlar, ucuz bir çantayla aynı şeyleri taşıyan bir çantaya binlerce dolar ödüyor.",
      [E("bag", 0.28, 0.55, 0.8, logo="$$$$"), T(0.5, 0.5, "=", 2.0), E("bag", 0.72, 0.55, 0.8, logo="$")]),
    S("They wear shoes that hurt.", "Ayaklarını acıtan ayakkabılar giyiyor.", [E("heel", 0.45, 0.55, 1.4), T(0.78, 0.35, "ouch", 1.5, "red")]),
    S("They throw away clothes that still work, because they're \"out of style.\"", "Hâlâ işe yarayan kıyafetleri \"modası geçti\" diye atıyor.",
      [E("pile", 0.4, 0.8, 1.1), T(0.75, 0.3, "\"out of style\"", 1.2, "red")]),
    S("Warmth explains clothing. It doesn't explain *fashion*.", "Sıcaklık giysiyi açıklıyor. *Modayı* açıklamıyor.",
      [T(0.3, 0.35, "clothing", 1.5, "blue"), T(0.72, 0.35, "fashion", 1.5, "red", underline="red"), T(0.3, 0.6, "warmth", 1.1), T(0.72, 0.6, "?", 1.6, "red")]),
    S("So why did we invent it?", "Peki onu neden icat ettik?", [T(0.5, 0.42, "Why fashion?", 2.0, "red", underline="red")]),
    # ------------------------------------------------------------ Bölüm 1: Boncuklar
    S("The first clue is surprising: we may have decorated ourselves *before* we were fully dressed.",
      "İlk ipucu şaşırtıcı: Tam olarak giyinmeden *önce* kendimizi süslemiş olabiliriz.",
      [G(), F(0.35, 0.55, tone=0.8), E("beads", 0.35, 0.36, 0.3), T(0.72, 0.4, "decoration first?", 1.2, "red")]),
    S("In caves in Morocco, archaeologists found tiny sea shells with holes drilled through them, strung like beads.",
      "Fas'taki mağaralarda arkeologlar, delinip boncuk gibi dizilmiş küçük deniz kabukları buldu.",
      [E("cave", 0.3, 0.6, 0.6, fire=False), E("beads", 0.7, 0.45, 0.9)]),
    S("They're about 150,000 years old.", "Yaklaşık 150.000 yıllıklar.", [E("beads", 0.5, 0.4, 1.2), T(0.5, 0.85, "≈ 150,000 years", 1.5, "red", underline="red")]),
    S("In South Africa's Blombos Cave, similar shell beads are around 75,000 years old.",
      "Güney Afrika'daki Blombos Mağarası'nda benzer kabuk boncuklar yaklaşık 75.000 yıllık.",
      [E("cave", 0.3, 0.6, 0.6, fire=False), T(0.72, 0.4, "Blombos", 1.3, "blue"), T(0.72, 0.6, "75,000 years", 1.2)]),
    S("Beads don't keep you warm. They don't protect you from anything.", "Boncuklar seni sıcak tutmaz. Hiçbir şeyden korumaz.",
      [E("beads", 0.5, 0.4, 1.0), E("cross", 0.25, 0.75, 0.4, at=0.6), T(0.4, 0.75, "warm", 1.0), E("cross", 0.62, 0.75, 0.4, at=1.0), T(0.77, 0.75, "protect", 1.0)]),
    S("Their only job is to be *seen*.", "Tek işleri *görülmek*.", [E("eye", 0.3, 0.45, 1.0), E("beads", 0.72, 0.4, 0.7)]),
    S("Archaeologists think they carried messages: who you are, which group you belong to, maybe whether you're married or important.",
      "Arkeologlar bunların mesaj taşıdığını düşünüyor: Kim olduğun, hangi gruba ait olduğun, belki evli ya da önemli biri olup olmadığın.",
      [G(), F(0.25, 0.5), E("beads", 0.25, 0.38, 0.25), F(0.55, 0.5, face=-1), E("beads", 0.55, 0.38, 0.25),
       T(0.82, 0.25, "who?", 1.0, "blue"), T(0.82, 0.42, "which group?", 1.0, "blue"), T(0.82, 0.59, "married?", 1.0, "blue")]),
    S("In other words, long before writing, humans had already invented a way to wear information on their bodies.",
      "Yani yazıdan çok önce insanlar bilgiyi bedenlerinde taşımanın bir yolunu çoktan icat etmişti.",
      [E("beads", 0.3, 0.4, 0.7), T(0.72, 0.42, "information\nyou can wear", 1.3, "red")]),
    # ------------------------------------------------------------ Bölüm 2: Ötzi
    S("Jump forward to about 5,300 years ago.", "Yaklaşık 5.300 yıl önceye atlayalım.", [E("hourglass", 0.4, 0.45, 1.0), T(0.72, 0.45, "5,300 years ago", 1.3, "blue")]),
    S("In 1991, hikers in the Alps found a frozen man in the ice. Scientists named him *Ötzi*.",
      "1991'de Alplerde yürüyüşçüler buzun içinde donmuş bir adam buldu. Bilim insanları ona *Ötzi* adını verdi.",
      [E("mountain", 0.5, 0.85, 1.0), F(0.5, 0.25, "lie", y=0.9), T(0.5, 0.08, "Ötzi · 1991", 1.4, "blue", underline="blue")]),
    IMG("otzi", "Ötzi's clothing · reconstruction",
        "His clothes survived, and in 2016, researchers analyzed their DNA.", "Kıyafetleri günümüze kaldı ve 2016'da araştırmacılar DNA'larını inceledi.",
        [E("magnifier", 0.35, 0.45, 1.0), T(0.72, 0.45, "DNA · 2016", 1.4, "blue")]),
    S("His coat was made from sheep and goat leather, stitched in alternating strips.",
      "Ceketi koyun ve keçi derisinden, şeritler halinde dönüşümlü dikilmişti.",
      [E("tshirt", 0.38, 0.5, 1.0), T(0.78, 0.35, "sheep", 1.2), T(0.78, 0.55, "+ goat", 1.2), T(0.5, 0.9, "alternating strips", 1.0, "blue")]),
    S("His hat was brown bear fur. His leggings were goat. His shoelaces, cattle.",
      "Şapkası boz ayı kürküydü. Tozlukları keçi. Ayakkabı bağları sığır.",
      [G(0.92), F(0.35, 0.7, y=0.92), T(0.7, 0.2, "hat: bear", 1.1, "blue"), T(0.7, 0.45, "leggings: goat", 1.1, "blue"), T(0.7, 0.7, "laces: cattle", 1.1, "blue")]),
    S("It was practical. But it was also *chosen*. The striped coat looks almost like a design.",
      "Pratikti. Ama aynı zamanda *seçilmişti*. Çizgili ceket neredeyse bir tasarım gibi görünüyor.",
      [E("tshirt", 0.4, 0.5, 1.0), T(0.78, 0.42, "design?", 1.5, "red")]),
    S("And Ötzi had more than sixty tattoos on his skin.", "Ve Ötzi'nin derisinde altmıştan fazla dövme vardı.",
      [E("hand", 0.4, 0.5, 1.4), T(0.78, 0.42, "61 tattoos", 1.5, "red", underline="red")]),
    S("Even a man walking alone through the mountains five thousand years ago was, in some way, dressed to be seen.",
      "Beş bin yıl önce dağlarda tek başına yürüyen bir adam bile bir şekilde görülmek için giyinmişti.",
      [E("mountain", 0.4, 0.85, 0.9), F(0.75, 0.35, "walk", y=0.85), E("eye", 0.85, 0.2, 0.4)]),
    # ------------------------------------------------------------ Bölüm 3: Güç
    S("Once clothing carried messages, it became a tool of *power*.", "Kıyafet mesaj taşımaya başlayınca bir *güç* aracına dönüştü.",
      [T(0.5, 0.42, "power", 2.4, "red", underline="red")]),
    IMG("murex", "Murex sea snail · source of Tyrian purple",
        "In the ancient Mediterranean, the most prestigious color was *Tyrian purple*.", "Antik Akdeniz'de en prestijli renk *Sur moru*ydu.",
        [E("snail", 0.42, 0.5, 1.2), T(0.5, 0.12, "Tyrian purple", 1.5, underline="red")]),
    S("It came from sea snails, and it took thousands of them to make a single gram of dye.",
      "Deniz salyangozlarından elde ediliyordu ve tek bir gram boya için binlercesi gerekiyordu.",
      [E("snail", 0.2, 0.3, 0.4), E("snail", 0.2, 0.55, 0.4), E("snail", 0.2, 0.8, 0.4), A(0.42, 0.55, 0.58, 0.55, bend=0.0), T(0.78, 0.45, "1 gram =", 1.2),
       T(0.78, 0.62, "thousands", 1.2, "red")]),
    IMG("justinian", "Emperor Justinian in purple · San Vitale, Ravenna (547)",
        "Purple became the color of emperors.", "Mor imparatorların rengi oldu.",
        [F(0.5, 0.65, tone=0.9), T(0.5, 0.1, "emperor's color", 1.3, "red")]),
    S("In Rome, wearing too much of it could get you in serious trouble.", "Roma'da ondan fazla giymek başını ciddi derde sokabilirdi.",
      [G(), F(0.4, 0.5), E("warning", 0.75, 0.4, 0.8)]),
    S("For centuries, many societies passed *sumptuary laws*: rules about who was allowed to wear what.",
      "Yüzyıllar boyunca birçok toplum *kılık kıyafet kanunları* çıkardı: Kimin neyi giyebileceğine dair kurallar.",
      [E("scroll", 0.35, 0.45, 1.0, text="who may wear what"), T(0.75, 0.42, "sumptuary laws", 1.2, "red")]),
    S("In Elizabethan England, laws restricted certain silks, furs and colors to the nobility.",
      "Elizabeth dönemi İngiltere'sinde yasalar bazı ipekleri, kürkleri ve renkleri soylulara ayırdı.",
      [T(0.5, 0.15, "England · 1574", 1.2, "blue"), T(0.3, 0.45, "silk", 1.2), T(0.5, 0.45, "fur", 1.2), T(0.7, 0.45, "purple", 1.2, "red"),
       T(0.5, 0.75, "nobles only", 1.3, "red", underline="red")]),
    S("In the Ottoman Empire, headgear and colors signaled rank and community.", "Osmanlı İmparatorluğu'nda başlıklar ve renkler rütbeyi ve topluluğu gösteriyordu.",
      [E("turban", 0.3, 0.7, 1.0), E("turban", 0.55, 0.7, 0.8), E("turban", 0.78, 0.7, 0.6), T(0.5, 0.15, "rank you can see", 1.2, "blue")]),
    S("And when rulers wanted to change society, they changed hats.", "Hükümdarlar toplumu değiştirmek istediğinde şapkaları değiştirdi.",
      [E("turban", 0.25, 0.65, 0.8), A(0.37, 0.5, 0.45, 0.5, bend=0.0), E("fez", 0.55, 0.65, 0.8), A(0.65, 0.5, 0.73, 0.5, bend=0.0), E("hat", 0.85, 0.65, 0.7)]),
    IMG("mahmud", "Sultan Mahmud II, wearing the fez",
        "In 1829, Sultan *Mahmud II* introduced the *fez* for officials.", "1829'da Sultan *II. Mahmud* memurlar için *fesi* getirdi.",
        [E("fez", 0.45, 0.65, 1.4), T(0.5, 0.12, "1829 · Mahmud II", 1.3, "blue")]),
    S("Less than a century later, in 1925, the Turkish Republic's *Hat Law* replaced the fez with the brimmed hat.",
      "Bir asır bile geçmeden, 1925'te Türkiye Cumhuriyeti'nin *Şapka Kanunu* fesin yerine şapkayı koydu.",
      [E("fez", 0.28, 0.65, 0.9), E("cross", 0.28, 0.55, 0.6, at=1.0), A(0.42, 0.55, 0.56, 0.55, bend=0.0), E("hat", 0.72, 0.65, 1.0), T(0.5, 0.12, "1925 · Hat Law", 1.3, "red")]),
    S("Clothing laws show something important: if governments bother to control what you wear, it's because clothes *say* something.",
      "Kıyafet yasaları önemli bir şey gösteriyor: Devletler ne giydiğini denetlemeye uğraşıyorsa bunun sebebi kıyafetlerin bir şey *söylemesidir*.",
      [E("tshirt", 0.35, 0.55, 0.9), B(0.7, 0.32, 0.9, tail=[0.45, 0.4]), T(0.7, 0.32, "...", 1.6)]),
    # ------------------------------------------------------------ Bölüm 4: Topuklar
    S("Here's a fashion story that surprises most people: high heels were originally worn by *men*.",
      "İnsanların çoğunu şaşırtan bir moda hikâyesi: Topuklu ayakkabıları ilk giyenler *erkeklerdi*.",
      [E("heel", 0.35, 0.55, 1.2), T(0.75, 0.42, "for men?", 1.6, "red")]),
    S("Historians trace them to Persian horsemen, who used heeled boots to keep their feet steady in the stirrups.",
      "Tarihçiler onların izini, ayaklarını üzengide sabit tutmak için topuklu çizme kullanan İranlı süvarilere kadar sürüyor.",
      [E("chariot", 0.45, 0.65, 0.9), T(0.5, 0.1, "Persian riders", 1.3, "blue")]),
    S("In the 1600s, European aristocrats adopted heels as a symbol of masculine, military style.",
      "1600'lerde Avrupalı aristokratlar topuğu erkeksi, askerî bir tarzın simgesi olarak benimsedi.",
      [G(), F(0.3, 0.55, hat="wig"), E("heel", 0.72, 0.6, 0.8), T(0.5, 0.1, "1600s", 1.3, "blue")]),
    IMG("louis", "Louis XIV · Hyacinthe Rigaud",
        "France's *Louis XIV* loved them. His heels were often red, and red heels became a sign of belonging at his court.",
        "Fransa Kralı *XIV. Louis* onlara bayılıyordu. Topukları çoğu zaman kırmızıydı ve kırmızı topuklar onun sarayına ait olmanın işareti oldu.",
        [G(), F(0.35, 0.6, hat="wig"), E("heel", 0.75, 0.6, 0.9, color="red")]),
    S("Then something interesting happened. As heels spread to ordinary people, the elite moved on,",
      "Sonra ilginç bir şey oldu. Topuklar sıradan insanlara yayılınca seçkinler başka şeylere geçti",
      [E("stairs", 0.15, 0.85, 1.2, n=3), F(0.75, 0.25, "walk", y=0.46), F(0.33, 0.2, y=0.73), F(0.5, 0.2, y=0.62)]),
    S("and over time heels became associated mainly with women's fashion.", "ve zamanla topuklu ayakkabılar daha çok kadın modasıyla anılır oldu.",
      [E("heel", 0.35, 0.55, 1.0), G(), F(0.72, 0.5, hat="dress")]),
    S("That pattern — the elite adopt something, others copy it, and the elite move on — turns out to be one of the engines of fashion itself.",
      "Bu döngü, yani seçkinlerin bir şeyi benimsemesi, diğerlerinin onu taklit etmesi ve seçkinlerin başka bir şeye geçmesi, modanın kendisinin motorlarından biri.",
      [T(0.5, 0.12, "1. elite adopt", 1.1, "blue"), T(0.84, 0.5, "2. others copy", 1.0), T(0.5, 0.88, "3. elite move on", 1.1, "red"),
       E("circle", 0.5, 0.5, 1.0, rx=220, ry=150, color="ink")]),
    # ------------------------------------------------------------ Bölüm 5: Simmel
    S("In 1904, the German sociologist *Georg Simmel* wrote a famous essay about fashion.", "1904'te Alman sosyolog *Georg Simmel* moda üzerine ünlü bir deneme yazdı.",
      [E("scroll", 0.35, 0.45, 0.9, text="Fashion · 1904"), T(0.72, 0.45, "Simmel", 1.5, "blue")]),
    S("He said fashion satisfies two opposite desires at the same time.", "Modanın aynı anda iki zıt arzuyu tatmin ettiğini söyledi.",
      [A(0.48, 0.45, 0.2, 0.45, bend=0.0, color="blue"), A(0.52, 0.45, 0.8, 0.45, bend=0.0, color="red")]),
    S("The first is *imitation*: we want to fit in, to belong, to look like the people we admire.",
      "Birincisi *taklit*: Uyum sağlamak, ait olmak, hayran olduğumuz insanlara benzemek isteriz.",
      [G(), F(0.25, 0.4), F(0.4, 0.4), F(0.55, 0.4), F(0.7, 0.4), T(0.5, 0.15, "imitation", 1.6, "blue", underline="blue")]),
    S("The second is *distinction*: we want to stand out, to be individual, to be different from the crowd.",
      "İkincisi *farklılaşma*: Öne çıkmak, birey olmak, kalabalıktan farklı olmak isteriz.",
      [G(), F(0.25, 0.4, tone=0.5), F(0.4, 0.4, tone=0.5), F(0.55, 0.4, tone=0.5), F(0.78, 0.45, "reach"), E("dot", 0.78, 0.2, 0.6, color="red"),
       T(0.5, 0.12, "distinction", 1.6, "red", underline="red")]),
    S("Fashion lets us do both.", "Moda ikisini birden yapmamıza izin veriyor.", [T(0.3, 0.42, "imitation", 1.3, "blue"), T(0.5, 0.42, "+", 1.6), T(0.72, 0.42, "distinction", 1.3, "red")]),
    S("You follow a trend to belong to a group, and by following it, you separate yourself from everyone who doesn't.",
      "Bir gruba ait olmak için bir akımı takip edersin ve onu takip ederek takip etmeyen herkesten ayrılırsın.",
      [G(), F(0.2, 0.4), F(0.32, 0.4), E("hat", 0.2, 0.42, 0.25), E("hat", 0.32, 0.42, 0.25), E("line", 0.5, 0.3, x2=0.5, y2=0.85, color="red"),
       F(0.68, 0.4, tone=0.5), F(0.82, 0.4, tone=0.5)]),
    S("But this creates a never-ending cycle.", "Ama bu bitmeyen bir döngü yaratıyor.", [E("circle", 0.5, 0.45, 1.0, rx=260, ry=200, color="red")]),
    S("Once everyone has copied a style, it can no longer make anyone stand out. So the people at the front move on.",
      "Herkes bir tarzı kopyaladığında artık o tarz kimseyi öne çıkaramaz. Bu yüzden öndekiler yola devam eder.",
      [G(), F(0.15, 0.4), F(0.27, 0.4), F(0.39, 0.4), F(0.51, 0.4), F(0.82, 0.4, "walk"), A(0.62, 0.3, 0.75, 0.3, bend=0.0, color="red")]),
    S("And the race begins again.", "Ve yarış yeniden başlar.", [E("circle", 0.5, 0.45, 1.0, rx=260, ry=200, color="red"), T(0.5, 0.45, "again", 1.4)]),
    S("That's why fashion *has* to change. A style that everyone wears stops saying anything.",
      "Bu yüzden moda *değişmek zorunda*. Herkesin giydiği bir tarz artık hiçbir şey söylemez.",
      [T(0.5, 0.35, "fashion has to change", 1.5, "red", underline="red"), T(0.5, 0.6, "everyone = no message", 1.2, "blue")]),
    # ------------------------------------------------------------ Bölüm 6: Önlük
    S("Clothes don't only send messages to other people. They may also send messages to *us*.",
      "Kıyafetler sadece başkalarına mesaj göndermez. Belki *bize* de mesaj gönderir.",
      [E("tshirt", 0.3, 0.5, 0.8), A(0.45, 0.45, 0.62, 0.45, bend=0.0), E("head", 0.75, 0.5, 0.55)]),
    S("In 2012, psychologists *Hajo Adam* and *Adam Galinsky* gave people a white coat to wear.",
      "2012'de psikologlar *Hajo Adam* ve *Adam Galinsky* insanlara giymeleri için beyaz bir önlük verdi.",
      [E("coat", 0.45, 0.48, 1.0), T(0.78, 0.4, "2012", 1.5, "blue")]),
    S("Some were told it was a *doctor's* lab coat. Others were told it was a *painter's* coat. It was the exact same coat.",
      "Bazılarına bunun bir *doktor* önlüğü olduğu söylendi. Diğerlerine bir *ressam* önlüğü olduğu. Tıpatıp aynı önlüktü.",
      [E("coat", 0.3, 0.45, 0.8, label="doctor"), E("coat", 0.72, 0.45, 0.8, label="painter"), T(0.5, 0.45, "=", 2.0, "red")]),
    S("Then everyone did a test that required careful attention.", "Sonra herkes dikkatli olmayı gerektiren bir test yaptı.",
      [E("letter", 0.45, 0.45, 1.0, text="attention test"), E("hourglass", 0.8, 0.45, 0.6)]),
    S("In their study, people who believed they were wearing a doctor's coat made fewer mistakes than those who thought it was a painter's coat.",
      "Çalışmalarında doktor önlüğü giydiğine inananlar, ressam önlüğü sananlardan daha az hata yaptı.",
      [E("bars", 0.5, 0.78, 0.9, values=[["\"doctor\"", 25, "blue"], ["\"painter\"", 45, "red"]], pct=False), T(0.5, 0.1, "fewer mistakes", 1.3, "blue")]),
    S("The researchers called this *enclothed cognition*: clothes can affect how we think, depending on what they *mean* to us.",
      "Araştırmacılar buna *giyinik biliş* dedi: Kıyafetler, bizim için ne *anlam* taşıdıklarına bağlı olarak nasıl düşündüğümüzü etkileyebilir.",
      [T(0.5, 0.35, "enclothed cognition", 1.6, underline="red"), E("head", 0.5, 0.75, 0.35, glow=True)]),
    S("Later studies have had mixed results, so the effect may be smaller than first claimed.",
      "Sonraki çalışmalar karışık sonuçlar verdi, yani etki ilk iddia edildiğinden küçük olabilir.",
      [E("balance", 0.5, 0.45, 0.9, tilt=0.1, left="?", right="?"), T(0.5, 0.9, "mixed results", 1.2, "blue")]),
    S("But the idea is familiar to anyone who has ever put on a uniform, a suit, or a favorite jacket, and felt like a slightly different person.",
      "Ama bu fikir, bir üniforma, takım elbise ya da en sevdiği ceketi giyip kendini biraz farklı biri gibi hisseden herkese tanıdık gelir.",
      [E("mirror", 0.65, 0.42, 0.9), G(), F(0.3, 0.55), F(0.65, 0.3, tone=0.5, y=0.6)]),
    # ------------------------------------------------------------ Bölüm 7: Veblen
    S("There's another reason fashion is often *expensive* and *impractical*.", "Modanın çoğu zaman *pahalı* ve *kullanışsız* olmasının bir sebebi daha var.",
      [T(0.3, 0.42, "expensive", 1.5, "red"), T(0.72, 0.42, "impractical", 1.5, "red")]),
    S("In 1899, the economist *Thorstein Veblen* coined the term *conspicuous consumption*:",
      "1899'da ekonomist *Thorstein Veblen*, *gösterişçi tüketim* kavramını ortaya attı:",
      [T(0.5, 0.35, "conspicuous consumption", 1.5, underline="red"), T(0.5, 0.58, "Veblen · 1899", 1.1, "blue")]),
    S("spending money in ways that others can see, to show your status.", "Statünü göstermek için başkalarının görebileceği şekilde para harcamak.",
      [E("money", 0.3, 0.6, 0.9, text="$"), E("eye", 0.72, 0.42, 0.8)]),
    S("He noticed that wealthy people often wore clothes that made physical work impossible: long sleeves, delicate fabrics, spotless white.",
      "Varlıklı insanların çoğu zaman bedensel işi imkânsız kılan kıyafetler giydiğini fark etti: uzun kollar, narin kumaşlar, lekesiz beyazlar.",
      [E("coat", 0.3, 0.45, 0.8), T(0.72, 0.25, "long sleeves", 1.0), T(0.72, 0.42, "delicate", 1.0), T(0.72, 0.59, "spotless white", 1.0)]),
    S("The message was clear: *I don't need to work with my hands.*", "Mesaj açıktı: *Elimle çalışmama gerek yok.*",
      [E("hand", 0.35, 0.5, 1.2), T(0.72, 0.42, "no work", 1.5, "red", underline="red")]),
    IMG("peacock", "Indian peafowl display · Pench National Park",
        "Biologists have a similar idea. In 1975, *Amotz Zahavi* proposed the *handicap principle*:",
        "Biyologların da benzer bir fikri var. 1975'te *Amotz Zahavi*, *handikap ilkesini* önerdi:",
        [E("peacock", 0.5, 0.6, 1.1)]),
    S("a peacock's enormous tail is a burden, and that's exactly why it's impressive. Only a strong bird can afford it.",
      "Bir tavus kuşunun devasa kuyruğu bir yüktür ve tam da bu yüzden etkileyicidir. Ancak güçlü bir kuş onu taşıyabilir.",
      [E("peacock", 0.4, 0.62, 1.0), T(0.82, 0.3, "burden", 1.2, "red"), T(0.82, 0.5, "= proof", 1.2, "blue")]),
    S("A designer logo works the same way. Its message isn't \"this is a good bag.\"", "Bir tasarımcı logosu da aynı şekilde çalışır. Mesajı \"bu iyi bir çanta\" değildir.",
      [E("bag", 0.35, 0.55, 1.0, logo="LOGO"), T(0.75, 0.42, "\"a good bag\"", 1.1), E("cross", 0.75, 0.42, 0.6, at=1.2)]),
    S("Its message is \"I can afford to waste money on a bag.\"", "Mesajı \"bir çantaya para saçabilecek durumdayım\"dır.",
      [E("bag", 0.3, 0.55, 0.9, logo="LOGO"), T(0.7, 0.42, "\"I can afford\nto waste money\"", 1.2, "red")]),
    S("And when everyone can buy logos, the very rich switch to \"quiet luxury\": no logos at all, just expensive simplicity that only insiders recognize.",
      "Herkes logo alabilir hale gelince de çok zenginler \"sessiz lükse\" geçer: hiç logo yok, sadece içeridekilerin tanıyabildiği pahalı bir sadelik.",
      [E("bag", 0.25, 0.55, 0.7, logo="LOGO"), A(0.4, 0.5, 0.55, 0.5, bend=0.0), E("tshirt", 0.72, 0.5, 0.8), T(0.72, 0.12, "quiet luxury", 1.3, "blue", underline="blue")]),
    # ------------------------------------------------------------ Bölüm 8: Hızlı moda
    S("For most of history, the fashion cycle moved slowly, because clothes were expensive and took weeks to make.",
      "Tarihin büyük kısmında moda döngüsü yavaş ilerledi, çünkü kıyafetler pahalıydı ve yapımı haftalar sürüyordu.",
      [E("sewing", 0.35, 0.7, 1.0), E("calendar", 0.78, 0.45, 0.7, text="weeks")]),
    S("Today, the cycle runs at the speed of the internet.", "Bugün döngü internet hızında dönüyor.",
      [E("phone", 0.35, 0.45, 1.0), E("circle", 0.72, 0.45, 0.8, rx=150, ry=150, color="red"), T(0.72, 0.45, "fast", 1.2)]),
    S("According to the Ellen MacArthur Foundation, global clothing production roughly *doubled* between 2000 and 2014,",
      "Ellen MacArthur Vakfı'na göre küresel giysi üretimi 2000 ile 2014 arasında kabaca *iki katına* çıktı.",
      [E("bars", 0.5, 0.78, 0.9, values=[["2000", 25, "blue"], ["2014", 50, "red"]], pct=False), T(0.5, 0.1, "production ×2", 1.4, "red")]),
    S("while the average number of times a garment was worn before being thrown away *fell* by about a third.",
      "Bir giysinin atılmadan önce giyildiği ortalama sayı ise yaklaşık üçte bir *azaldı*.",
      [E("tshirt", 0.3, 0.5, 0.8), E("graph", 0.72, 0.5, 0.6, up=False), T(0.72, 0.12, "times worn: −36%", 1.2, "red")]),
    S("The ancient desire to signal \"I belong, but I'm also unique\" now plays out every week, on every phone.",
      "\"Aitim ama aynı zamanda eşsizim\" demeye yönelik kadim arzu artık her hafta, her telefonda yaşanıyor.",
      [E("beads", 0.25, 0.4, 0.5), A(0.38, 0.45, 0.55, 0.45, bend=0.0), E("phone", 0.72, 0.45, 0.9)]),
    S("The price is paid by the planet, and often by the workers who make the clothes.", "Bedelini ise gezegen ve çoğu zaman kıyafetleri diken işçiler ödüyor.",
      [E("pile", 0.3, 0.85, 1.0), E("globe", 0.75, 0.45, 0.8)]),
    S("In 2013, the *Rana Plaza* factory building in Bangladesh collapsed, killing more than 1,100 garment workers.",
      "2013'te Bangladeş'teki *Rana Plaza* fabrika binası çöktü ve 1.100'den fazla konfeksiyon işçisi hayatını kaybetti.",
      [E("factory", 0.4, 0.85, 1.0), E("cross", 0.4, 0.6, 1.0, at=1.0), T(0.8, 0.35, "Rana Plaza", 1.2, "red"), T(0.8, 0.52, "2013", 1.0)]),
    S("Many of them had been making clothes for well-known Western brands.", "Birçoğu tanınmış Batılı markalar için kıyafet dikiyordu.",
      [E("sewing", 0.3, 0.7, 0.9), A(0.48, 0.5, 0.62, 0.5, bend=0.0), E("bag", 0.78, 0.55, 0.7, logo="BRAND")]),
    # ------------------------------------------------------------ Kendin dene
    S("Try this. Look at what you're wearing right now.", "Şunu dene. Şu an üzerinde ne olduğuna bak.",
      [T(0.12, 0.1, "try this", 1.0, "red", underline="red"), E("mirror", 0.65, 0.42, 1.0), G(), F(0.3, 0.55)]),
    S("Ask yourself three questions. What does it say about which group I belong to?", "Kendine üç soru sor: Bu, hangi gruba ait olduğum hakkında ne söylüyor?",
      [T(0.12, 0.12, "1.", 1.5, "red"), E("heads", 0.55, 0.45, 0.7, n=3)]),
    S("What does it say about how I'm different?", "Nasıl farklı olduğum hakkında ne söylüyor?",
      [T(0.12, 0.12, "2.", 1.5, "red"), G(), F(0.35, 0.4, tone=0.5), F(0.5, 0.4, tone=0.5), F(0.72, 0.45), E("dot", 0.72, 0.2, 0.5, color="red")]),
    S("And who, exactly, am I dressing for?", "Ve ben tam olarak kimin için giyiniyorum?", [T(0.12, 0.12, "3.", 1.5, "red"), E("eye", 0.5, 0.45, 1.1), T(0.5, 0.82, "for whom?", 1.3, "blue")]),
    S("Even if you think you \"don't care about fashion,\" that's a message too.", "\"Modayı umursamıyorum\" diye düşünsen bile bu da bir mesaj.",
      [E("tshirt", 0.3, 0.5, 0.8), B(0.7, 0.35, 0.9, tail=[0.42, 0.4]), T(0.7, 0.35, "\"I don't care\"", 0.9)]),
    S("Choosing not to play is still a move in the game.", "Oynamamayı seçmek de oyunda bir hamle.",
      [E("backgammon", 0.5, 0.5, 1.0)]),
    # ------------------------------------------------------------ Kapanış
    S("We invented clothing to survive the cold.", "Giysiyi soğuktan korunmak için icat ettik.",
      [E("stars", 0.5, 0.15, 1.0, n=30, h=0.2), G(), F(0.5, 0.5, tone=0.75)]),
    S("But we invented *fashion* to talk:", "Ama *modayı* konuşmak için icat ettik:", [E("tshirt", 0.35, 0.5, 0.8), B(0.7, 0.35, 0.9, tail=[0.45, 0.4])]),
    S("to say who we are, who we're with, and who we're not, without saying a single word.",
      "Tek bir kelime söylemeden kim olduğumuzu, kimlerle olduğumuzu ve kim olmadığımızı söylemek için.",
      [T(0.5, 0.25, "who we are", 1.3, "blue"), T(0.5, 0.45, "who we're with", 1.3, "blue"), T(0.5, 0.65, "who we're not", 1.3, "red")]),
    S("A hundred and fifty thousand years after the first shell beads, we're still doing it.",
      "İlk kabuk boncuklardan yüz elli bin yıl sonra hâlâ bunu yapıyoruz.",
      [E("beads", 0.3, 0.4, 0.7), A(0.48, 0.45, 0.6, 0.45, bend=0.0), E("bag", 0.75, 0.55, 0.7)]),
    S("Every morning, in front of the mirror, we choose what to say.", "Her sabah ayna karşısında ne söyleyeceğimizi seçiyoruz.",
      [E("mirror", 0.6, 0.42, 1.0), G(), F(0.32, 0.55), B(0.85, 0.2, 0.5, tail=[0.68, 0.3])]),
]

subscribe = dict(after=11, sketch=[dict(el="subscribe", x=0.45, y=0.45, s=1.4), dict(el="arrow", x=0.2, y=0.75, x2=0.33, y2=0.55, color="red", s=1.2)],
                 say={"en": "If you like finding out why we do the strange things we do, *subscribe*. It genuinely helps the channel.",
                      "tr": "Yaptığımız tuhaf şeyleri neden yaptığımızı keşfetmeyi seviyorsan *abone ol*. Kanala gerçekten çok yardımı oluyor."})
meta = {"en": dict(title="Why Did Humans Invent Fashion?", description="", tags=[]), "tr": dict(title="Modayı Neden İcat Ettik?", description="", tags=[])}
out = dict(slug="moda", format="long", theme="karakalem", character="none", languages=["en"], subtitles=["tr"],
           voices={"en": "am_fenrir"}, speech_rate=0.88, meta=meta, subscribe=subscribe, scenes=scenes)
json.dump(out, open(os.path.join(HERE, "moda.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
words = sum(len(s["say"]["en"].split()) for s in scenes) + len(subscribe["say"]["en"].split())
print(f"{len(scenes)} sahne, {words} kelime")
