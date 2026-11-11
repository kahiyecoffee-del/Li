#!/usr/bin/env python3
"""Sanal gerçeklik videosunun sahne sahne senaryosu.  Çalıştır: python3 senaryolar/vr_uret.py -> senaryolar/vr.json"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
IMG_FILES = {}
p = os.path.join(HERE, "vr_gorseller.json")
if os.path.exists(p):
    IMG_FILES = json.load(open(p, encoding="utf-8"))


def S(en, tr, sk=None, **kw):
    d = dict(say={"en": en, "tr": tr})
    if sk is not None:
        d["sketch"] = sk
    d.update(kw)
    return d


def IMG(key, label, en, tr, fallback, fit="contain"):
    if key in IMG_FILES:
        return S(en, tr, image=dict(file=IMG_FILES[key], style="sketch", fit=fit, label=label, tint=0.3))
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


VR = dict(hat="vr")

scenes = [
    # ------------------------------------------------------------ Açılış
    S("In 1965, a young computer scientist wrote an essay describing the *ultimate display*.",
      "1965'te genç bir bilgisayar bilimcisi, *nihai ekranı* anlatan bir deneme yazdı.",
      [E("scroll", 0.5, 0.45, 1.2, text="The Ultimate Display · 1965")]),
    S("*\"A chair displayed in such a room would be good enough to sit in,\"* he wrote.",
      "*\"Böyle bir odada gösterilen bir sandalye üzerine oturulacak kadar iyi olurdu,\"* diye yazdı.",
      [E("room", 0.5, 0.82, 1.2), E("chair", 0.5, 0.78, 0.8)]),
    S("*\"Handcuffs displayed in such a room would be confining, and a bullet displayed in such a room would be fatal.\"*",
      "*\"Böyle bir odada gösterilen kelepçeler insanı bağlardı, böyle bir odada gösterilen bir kurşun ise öldürücü olurdu.\"*",
      [E("room", 0.5, 0.82, 1.2), T(0.5, 0.55, "fatal", 1.6, "red", underline="red")]),
    S("His name was *Ivan Sutherland*. Three years later, he built one of the first head-mounted displays —",
      "Adı *Ivan Sutherland*'dı. Üç yıl sonra ilk başa takılan ekranlardan birini yaptı.",
      [G(), F(0.5, 0.55, **VR), T(0.5, 0.1, "Ivan Sutherland · 1968", 1.0, "blue")]),
    S("a machine so heavy it had to hang from the ceiling.", "Makine o kadar ağırdı ki tavana asılması gerekiyordu.",
      [E("sword", 0.5, 0.42, 1.1), G(0.9), F(0.5, 0.42, y=0.9, **VR), T(0.8, 0.2, "Sword of Damocles", 0.9, "red")]),
    S("Today, millions of people wear its descendants on their faces.", "Bugün milyonlarca insan onun torunlarını yüzlerinde taşıyor.",
      [G(), F(0.15, 0.4, **VR), F(0.3, 0.42, "point", **VR), F(0.45, 0.4, face=-1, hat="vr"), F(0.6, 0.42, "shrug", **VR), F(0.75, 0.4, **VR),
       F(0.88, 0.3, child=True, face=-1, hat="vr")]),
    S("And they raise a question philosophers have asked for two and a half thousand years: *if a world feels completely real... is it?*",
      "Ve bu cihazlar, filozofların iki bin beş yüz yıldır sorduğu bir soruyu yeniden gündeme getiriyor: *Bir dünya tamamen gerçek hissettiriyorsa… gerçek midir?*",
      [E("head", 0.32, 0.5, 0.6), E("globe", 0.7, 0.45, 0.9), T(0.7, 0.85, "real?", 1.2, "red")]),
    S("In this video, you'll see why people refuse to step off a virtual ledge they *know* isn't there,",
      "Bu videoda insanların orada olmadığını *bildikleri* sanal bir uçurumun kenarından neden adım atmadığını,",
      [E("plank", 0.5, 0.55, 1.0), F(0.5, 0.4, "shrug", y=0.53, **VR)]),
    S("how your brain can adopt a fake hand as its own,", "beyninin sahte bir eli nasıl kendi eli sanabildiğini,",
      [E("hand", 0.3, 0.7, 1.0), E("line", 0.47, 0.3, x2=0.47, y2=0.75), E("hand", 0.65, 0.7, 1.0, color=[205, 150, 140], tone=0.6)]),
    S("how an avatar can quietly change your personality —", "bir avatarın kişiliğini nasıl sessizce değiştirebildiğini",
      [G(), F(0.35, 0.4, **VR), A(0.45, 0.5, 0.58, 0.45, bend=0.0), F(0.7, 0.62)]),
    S("and why one philosopher's thought experiment suggests that most of us would refuse paradise, if it were made of code.",
      "ve bir filozofun düşünce deneyine göre çoğumuzun koddan yapılmış bir cenneti neden reddedeceğini göreceksin.",
      [E("machine", 0.4, 0.85, 1.0), T(0.78, 0.15, "paradise?", 1.2, "red")]),
    # ------------------------------------------------------------ Bilgisayardan önce
    S("The idea of a convincing fake world is much older than computers.", "İnandırıcı sahte bir dünya fikri bilgisayarlardan çok daha eski.",
      [E("hourglass", 0.5, 0.45, 1.2), T(0.5, 0.1, "2,400 years", 1.0)]),
    IMG("plato", "Plato · c. 428–348 BC", "Around 375 BC, in *The Republic*, Plato imagined prisoners chained inside a cave since birth.",
        "MÖ 375 civarında Platon *Devlet*'te doğduklarından beri bir mağarada zincirli tutsakları hayal etti.",
        [E("portrait_frame", 0.5, 0.45, 1.3, text="Plato")]),
    S("All they can see are shadows on a wall, cast by objects carried behind them.",
      "Tek görebildikleri, arkalarından taşınan nesnelerin duvara düşen gölgeleri.", [E("cave", 0.5, 0.85, 1.0)]),
    S("To them, the shadows *are* reality.", "Onlar için gölgeler *gerçekliğin ta kendisi*.",
      [E("cave", 0.5, 0.85, 1.0, fire=False), T(0.5, 0.75, "reality?", 1.2, "red", underline="red")]),
    S("When one prisoner is freed and sees the real world, the light hurts his eyes.", "Tutsaklardan biri serbest bırakılıp gerçek dünyayı gördüğünde ışık gözlerini acıtır.",
      [G(), F(0.3, 0.5, "shrug"), E("dot", 0.75, 0.25, 2.0)]),
    S("And when he returns to tell the others, they don't believe him.", "Diğerlerine anlatmak için geri döndüğünde ise ona inanmazlar.",
      [G(), F(0.3, 0.5, "point"), F(0.55, 0.45, face=-1), F(0.7, 0.45, face=-1), F(0.85, 0.45, face=-1), T(0.7, 0.2, "no.", 1.2, "red")]),
    S("The phrase \"virtual reality\" itself came long before the technology.", "\"Sanal gerçeklik\" ifadesinin kendisi de teknolojiden çok önce ortaya çıktı.",
      [T(0.5, 0.42, "\"virtual reality\"", 1.8, underline="red")]),
    S("In 1938, the French playwright *Antonin Artaud* described theater as *\"la réalité virtuelle\"* — a world that becomes real for the audience while it lasts.",
      "1938'de Fransız oyun yazarı *Antonin Artaud* tiyatroyu *\"la réalité virtuelle\"*, yani sanal gerçeklik olarak tanımladı: sürdüğü süre boyunca seyirci için gerçek hale gelen bir dünya.",
      [E("line", 0.1, 0.2, x2=0.9, y2=0.2, w=1.5), G(0.62), F(0.4, 0.3, "point", y=0.62), F(0.6, 0.3, face=-1, y=0.62, hat="dress"),
       T(0.5, 0.82, "la réalité virtuelle · 1938", 1.0, "blue")]),
    # ------------------------------------------------------------ Makineler
    S("The machines came later.", "Makineler daha sonra geldi.", [T(0.5, 0.42, "the machines", 1.6, underline="red")]),
    IMG("sensorama", "Sensorama patent · 1962",
        "In 1962, cinematographer *Morton Heilig* patented the *Sensorama* — a booth where you sat, looked into a stereoscopic screen,",
        "1962'de görüntü yönetmeni *Morton Heilig*, *Sensorama*'nın patentini aldı. Bu bir kabindi: Oturuyor, stereoskopik bir ekrana bakıyordun",
        [E("booth", 0.6, 0.85, 1.0)]),
    S("and rode a motorcycle through Brooklyn, with wind on your face, a vibrating seat, and even smells.",
      "ve yüzünde rüzgâr, titreyen bir koltuk ve hatta kokularla Brooklyn'de motosiklet sürüyordun.",
      [E("booth", 0.55, 0.85, 1.0), T(0.15, 0.2, "wind", 0.9, "blue"), T(0.15, 0.35, "vibration", 0.9, "blue"), T(0.15, 0.5, "smells", 0.9, "blue")]),
    S("Then came Sutherland's ceiling-mounted headset in 1968, nicknamed *\"The Sword of Damocles.\"*",
      "Ardından 1968'de Sutherland'in tavana asılı başlığı geldi. Takma adı *\"Demokles'in Kılıcı\"*ydı.",
      [E("sword", 0.5, 0.42, 1.1), G(0.9), F(0.5, 0.42, y=0.9, **VR), T(0.8, 0.2, "1968", 1.0)]),
    S("In the 1980s, *Jaron Lanier* and his company VPL popularized the term \"virtual reality\" and sold gloves that let you reach into digital worlds.",
      "1980'lerde *Jaron Lanier* ve şirketi VPL \"sanal gerçeklik\" terimini yaygınlaştırdı ve dijital dünyalara uzanmayı sağlayan eldivenler sattı.",
      [E("hand", 0.35, 0.65, 1.2, color=[90, 130, 200], tone=0.7), A(0.5, 0.5, 0.62, 0.5, bend=0.0), E("screen", 0.75, 0.6, 0.9), T(0.5, 0.1, "VPL · 1980s", 1.0, "blue")]),
    S("In 1995, Nintendo launched the *Virtual Boy*. It gave many players headaches, sold poorly, and was discontinued in less than a year.",
      "1995'te Nintendo *Virtual Boy*'u piyasaya sürdü. Birçok oyuncunun başını ağrıttı, az sattı ve bir yıl dolmadan üretimden kaldırıldı.",
      [G(), F(0.4, 0.5, "think", **VR), T(0.4, 0.15, "ouch", 1.0, "red"), E("graph", 0.75, 0.45, 0.6, up=False), T(0.75, 0.82, "1995", 0.9)]),
    S("For a while, VR seemed like a dream that would never work.", "Bir süre VR asla işe yaramayacak bir hayal gibi göründü.",
      [E("bed", 0.45, 0.82, 1.2), F(0.52, 0.4, "lie", -1, y=0.68), B(0.68, 0.3, 0.8, "thought", tail=[0.45, 0.58]), F(0.68, 0.2, y=0.4, **VR)]),
    S("Then, in 2012, a young engineer named *Palmer Luckey* launched a Kickstarter campaign for a headset called *Oculus Rift*.",
      "Sonra 2012'de *Palmer Luckey* adında genç bir mühendis *Oculus Rift* adlı bir başlık için Kickstarter kampanyası başlattı.",
      [G(), F(0.35, 0.5, "point", **VR), E("graph", 0.72, 0.45, 0.6), T(0.72, 0.12, "2012", 1.0, "blue")]),
    S("Two years later, Facebook bought the company for about two billion dollars.", "İki yıl sonra Facebook şirketi yaklaşık iki milyar dolara satın aldı.",
      [E("money", 0.5, 0.7, 1.3), T(0.5, 0.12, "2014", 1.0)]),
    S("The shadows on the cave wall had become very, very convincing.", "Mağara duvarındaki gölgeler çok, çok inandırıcı hale gelmişti.",
      [E("cave", 0.5, 0.85, 1.0)]),
    # ------------------------------------------------------------ Sanal uçurum
    S("Here's the strange part: your brain is remarkably easy to fool.", "İşin tuhaf yanı şu: Beynini kandırmak şaşırtıcı derecede kolay.",
      [E("brain", 0.5, 0.5, 1.2), T(0.5, 0.08, "easy to fool", 1.2, "red", underline="red")]),
    S("Researchers call it *presence* — the feeling of actually *being there*.", "Araştırmacılar buna *mevcudiyet* (presence) diyor: gerçekten *orada olma* hissi.",
      [T(0.5, 0.42, "presence", 2.0, underline="red"), T(0.5, 0.62, "= being there", 1.0, "blue")]),
    S("In one well-known experiment at the University of North Carolina in 2002, participants walked through a virtual room that ended in a deep pit.",
      "2002'de Kuzey Carolina Üniversitesi'ndeki bilinen bir deneyde katılımcılar derin bir çukurla biten sanal bir odada yürüdü.",
      [E("pit", 0.6, 0.85, 1.0, figure_in=False), G(0.52), F(0.25, 0.4, "walk", y=0.52, **VR), T(0.5, 0.08, "UNC · 2002", 1.0, "blue")]),
    S("A real wooden ledge on the floor matched the virtual edge.", "Yerdeki gerçek bir tahta kenar, sanal kenarla birebir örtüşüyordu.",
      [E("plank", 0.5, 0.55, 1.0), E("circle", 0.32, 0.55, 1.0, rx=120, ry=60, color="blue")]),
    S("Everyone knew the pit wasn't real. They were standing in a lab.", "Herkes çukurun gerçek olmadığını biliyordu. Bir laboratuvarda duruyorlardı.",
      [G(), F(0.5, 0.5, **VR), T(0.2, 0.3, "not real", 1.0, "blue"), T(0.8, 0.3, "a lab", 1.0, "blue")]),
    S("And yet their heart rates went up as they approached the edge — and many refused to step forward.",
      "Yine de kenara yaklaştıkça kalp atışları hızlandı ve birçoğu ileri adım atmayı reddetti.",
      [E("plank", 0.42, 0.55, 0.8), F(0.3, 0.38, "shrug", y=0.53, **VR), E("heart", 0.82, 0.25, 0.8), E("graph", 0.8, 0.62, 0.45)]),
    S("In VR labs around the world, a simple version of this demo is still used: a narrow plank over a virtual drop.",
      "Dünyanın dört bir yanındaki VR laboratuvarlarında bu deneyin basit bir versiyonu hâlâ kullanılıyor: sanal bir boşluğun üzerinde dar bir tahta.",
      [E("plank", 0.5, 0.55, 1.0)]),
    S("People who are perfectly calm in a normal room suddenly crouch, hold their arms out, and shuffle like they're on a rooftop.",
      "Normal bir odada gayet sakin olan insanlar birden çömeliyor, kollarını açıyor ve bir çatıdaymış gibi ayaklarını sürüyor.",
      [E("plank", 0.5, 0.55, 1.0), F(0.5, 0.36, "shrug", y=0.53, **VR)]),
    S("The rational part of you says: *it's not real.* An older part of you says: *don't fall.* And the older part usually wins.",
      "Mantıklı yanın şöyle diyor: *Bu gerçek değil.* Daha eski bir yanın ise şöyle: *Düşme.* Ve genellikle eski olan kazanıyor.",
      [E("head", 0.3, 0.5, 0.6), B(0.6, 0.25, 0.55), T(0.6, 0.25, "it's not real", 0.8, "blue"), B(0.75, 0.6, 0.55), T(0.75, 0.6, "DON'T FALL", 0.9, "red")]),
    # ------------------------------------------------------------ Sahte el
    S("And your brain isn't only fooled about the world. It can be fooled about your *body*.",
      "Ve beynin sadece dünya konusunda kandırılmıyor. *Bedenin* konusunda da kandırılabiliyor.",
      [G(), F(0.5, 0.6), E("circle", 0.5, 0.5, 1.0, rx=180, ry=330)]),
    S("In 1998, psychologists *Matthew Botvinick* and *Jonathan Cohen* published a simple experiment called the *rubber hand illusion*.",
      "1998'de psikologlar *Matthew Botvinick* ve *Jonathan Cohen* *lastik el yanılsaması* adlı basit bir deney yayımladı.",
      [T(0.5, 0.35, "the rubber hand illusion", 1.4, underline="red"), T(0.5, 0.58, "Botvinick & Cohen · 1998", 0.9, "blue")]),
    S("A participant's real hand is hidden behind a screen. A rubber hand is placed in front of them.",
      "Katılımcının gerçek eli bir perdenin arkasına gizlenir. Önüne lastik bir el konur.",
      [E("hand", 0.27, 0.7, 1.0), E("line", 0.45, 0.25, x2=0.45, y2=0.78, w=1.6), E("hand", 0.65, 0.7, 1.0, color=[205, 150, 140], tone=0.6),
       T(0.27, 0.35, "real", 0.9), T(0.65, 0.35, "rubber", 0.9, "red")]),
    S("Then the experimenter strokes both hands with a brush at the same time.", "Sonra deneyi yapan kişi iki eli aynı anda bir fırçayla okşar.",
      [E("hand", 0.27, 0.7, 1.0), E("line", 0.45, 0.25, x2=0.45, y2=0.78, w=1.6), E("hand", 0.65, 0.7, 1.0, color=[205, 150, 140], tone=0.6),
       E("brush", 0.3, 0.52, 0.8), E("brush", 0.68, 0.52, 0.8)]),
    S("After a minute or two, many people start to feel the touch *on the rubber hand*.", "Bir iki dakika sonra birçok kişi dokunuşu *lastik elde* hissetmeye başlar.",
      [E("hand", 0.65, 0.7, 1.2, color=[205, 150, 140], tone=0.6), E("circle", 0.65, 0.6, 1.0, rx=260, ry=180), T(0.3, 0.4, "mine?", 1.4, "red")]),
    S("Some even flinch when someone threatens it.", "Hatta biri lastik ele zarar verecekmiş gibi yapınca bazıları irkilir.",
      [E("hand", 0.6, 0.75, 1.0, color=[205, 150, 140], tone=0.6), T(0.6, 0.35, "!", 3.0, "red"), G(), F(0.2, 0.55, "shrug")]),
    S("VR takes this much further. With a headset and motion tracking, researchers have made people feel ownership over virtual bodies —",
      "VR bunu çok daha ileri götürüyor. Bir başlık ve hareket takibiyle araştırmacılar insanlara sanal bedenlere sahiplik hissettirdi:",
      [G(), F(0.3, 0.55, **VR), E("mirror", 0.68, 0.42, 0.9), F(0.68, 0.32, y=0.55, face=-1, hat="dress")]),
    S("different heights, different ages, even bodies that look nothing like their own.", "farklı boylar, farklı yaşlar, hatta kendilerine hiç benzemeyen bedenler.",
      [G(), F(0.2, 0.3, child=True), F(0.4, 0.6), F(0.6, 0.45, hat="dress"), F(0.8, 0.5, "think", hat="wig")]),
    S("Your sense of \"this is me\" isn't fixed. It's constantly being built — and it can be rebuilt.",
      "\"Bu benim\" hissin sabit değil. Sürekli inşa ediliyor ve yeniden inşa edilebilir.",
      [E("head", 0.4, 0.5, 0.7), T(0.75, 0.42, "\"me\"", 1.6, "red", underline="red")]),
    # ------------------------------------------------------------ Proteus
    S("If your body can change, can your behavior change too?", "Bedenin değişebiliyorsa davranışın da değişebilir mi?",
      [G(), F(0.35, 0.5, **VR), T(0.65, 0.4, "behavior?", 1.3, "red")]),
    S("In 2007, *Nick Yee* and *Jeremy Bailenson* at Stanford tested this.", "2007'de Stanford'da *Nick Yee* ve *Jeremy Bailenson* bunu test etti.",
      [T(0.5, 0.42, "Yee & Bailenson · 2007", 1.3, underline="red")]),
    S("They gave people avatars that were more or less attractive, or taller or shorter, and watched what happened.",
      "İnsanlara daha çekici ya da daha az çekici, daha uzun ya da daha kısa avatarlar verip neler olduğunu izlediler.",
      [G(), F(0.3, 0.65), F(0.5, 0.45), F(0.7, 0.55, hat="dress")]),
    S("People with more attractive avatars walked closer to others in virtual space and shared more about themselves.",
      "Daha çekici avatarı olanlar sanal ortamda diğerlerine daha yakın yürüdü ve kendileri hakkında daha çok şey paylaştı.",
      [G(), F(0.42, 0.5, "point"), F(0.58, 0.5, face=-1, hat="dress"), B(0.38, 0.18, 0.4, tail=[0.41, 0.3]), T(0.38, 0.18, "so, I...", 0.7)]),
    S("People with taller avatars negotiated more aggressively than people with shorter ones.",
      "Daha uzun avatarı olanlar, kısa avatarı olanlardan daha agresif pazarlık yaptı.",
      [G(), F(0.3, 0.68, "point"), F(0.7, 0.42, face=-1), E("money", 0.5, 0.8, 0.4, text="$")]),
    S("The researchers named it the *Proteus effect*, after the Greek sea god who could change his shape.",
      "Araştırmacılar buna, şekil değiştirebilen Yunan deniz tanrısının adını vererek *Proteus etkisi* dedi.",
      [T(0.5, 0.35, "the Proteus effect", 1.6, underline="red"), T(0.5, 0.58, "~ ~ ~ shape-shifter ~ ~ ~", 0.9, "blue")]),
    S("We don't just wear our avatars. In a small way, they wear *us*.", "Avatarlarımızı sadece biz giymiyoruz. Küçük bir şekilde, onlar da *bizi* giyiyor.",
      [E("mask", 0.5, 0.45, 1.3)]),
    # ------------------------------------------------------------ Sosyal VR (ek bölüm)
    S("And there's one more side of virtual worlds that surprises people: they can be deeply *social*.",
      "Ve sanal dünyaların insanları şaşırtan bir yanı daha var: Son derece *sosyal* olabiliyorlar.",
      [G(), F(0.3, 0.45, **VR), F(0.5, 0.45, face=-1, hat="vr"), F(0.7, 0.45, face=-1, hat="vr"), T(0.5, 0.1, "social VR", 1.2, underline="red")]),
    S("On social VR platforms, people meet as avatars — to talk, dance, watch movies, or just sit around a virtual campfire.",
      "Sosyal VR platformlarında insanlar avatar olarak buluşuyor: sohbet etmek, dans etmek, film izlemek ya da sadece sanal bir kamp ateşinin etrafında oturmak için.",
      [G(), E("campfire", 0.5, 0.8, 1.2), F(0.3, 0.38, "sit", **VR), F(0.7, 0.38, "sit", face=-1, hat="vr")]),
    S("Researchers have found that people can feel genuine *social presence* with others in VR — the sense that another mind is really there with you.",
      "Araştırmacılar insanların VR'da başkalarıyla gerçek bir *sosyal mevcudiyet* hissedebildiğini buldu: başka bir zihnin gerçekten seninle orada olduğu hissi.",
      [E("heads", 0.5, 0.55, 1.0), T(0.5, 0.1, "social presence", 1.2, underline="red")]),
    S("Some people say they've found their closest friends there. Some have even met their partners.",
      "Bazı insanlar en yakın arkadaşlarını orada bulduklarını söylüyor. Hatta bazıları hayat arkadaşıyla orada tanışmış.",
      [G(), F(0.42, 0.5, **VR), F(0.58, 0.5, face=-1, hat="vr"), E("heart", 0.5, 0.2, 0.6)]),
    S("For people who are isolated, disabled, or far from home, these worlds can be a lifeline.",
      "Yalnız kalmış, engelli ya da evinden uzak insanlar için bu dünyalar bir can simidi olabiliyor.",
      [E("house", 0.25, 0.8, 0.6), A(0.35, 0.55, 0.6, 0.45), F(0.75, 0.45, **VR)]),
    S("Remember the need to belong? It doesn't switch off when the world is made of pixels.",
      "Ait olma ihtiyacını hatırlıyor musun? Dünya piksellerden oluştuğunda kapanmıyor.",
      [T(0.5, 0.42, "the need to belong", 1.5, "red", underline="red")]),
    # ------------------------------------------------------------ İyileştiren VR
    S("That flexibility isn't only a weakness. Doctors have turned it into medicine.", "Bu esneklik sadece bir zayıflık değil. Doktorlar onu bir tedaviye dönüştürdü.",
      [E("heart", 0.5, 0.45, 1.0), T(0.5, 0.82, "medicine", 1.0, "blue")]),
    S("At the University of Washington, researchers *Hunter Hoffman* and *David Patterson* created a game called *SnowWorld* for burn patients.",
      "Washington Üniversitesi'nde araştırmacılar *Hunter Hoffman* ve *David Patterson*, yanık hastaları için *SnowWorld* adlı bir oyun geliştirdi.",
      [G(), E("snowman", 0.7, 0.8, 0.9), F(0.35, 0.5, **VR), T(0.5, 0.08, "SnowWorld", 1.3, "blue", underline="blue")]),
    S("During painful wound care, patients threw snowballs at snowmen in an icy canyon.", "Acı veren yara bakımı sırasında hastalar buzlu bir kanyonda kardan adamlara kartopu attı.",
      [G(), E("snowman", 0.75, 0.8, 0.9), F(0.3, 0.5, "point", **VR), E("marble", 0.52, 0.42, 1.2, color="ink"), A(0.38, 0.4, 0.62, 0.45, color="blue")]),
    S("Many reported significantly less pain while they played.", "Birçoğu oynarken belirgin şekilde daha az acı hissettiğini söyledi.",
      [E("gauge", 0.5, 0.65, 1.3, value=0.2, label="pain")]),
    S("VR is also used for *exposure therapy*.", "VR *maruz bırakma terapisinde* de kullanılıyor.",
      [T(0.5, 0.42, "exposure therapy", 1.6, underline="red")]),
    S("People with a fear of heights, flying, or spiders can face their fear step by step, in a world where nothing can actually hurt them.",
      "Yükseklik, uçak ya da örümcek korkusu olan insanlar, gerçekte hiçbir şeyin onlara zarar veremeyeceği bir dünyada korkularıyla adım adım yüzleşebiliyor.",
      [E("spider", 0.72, 0.45, 1.0), G(), F(0.3, 0.5, "think", **VR), E("stairs", 0.4, 0.95, 0.5, n=3)]),
    S("It has also been used to help some veterans with PTSD.", "Bazı gazilerin travma sonrası stres bozukluğuna yardım etmek için de kullanıldı.",
      [G(), F(0.45, 0.55, "think", **VR), E("heart", 0.7, 0.3, 0.5)]),
    S("The same trick that makes you afraid of a virtual pit can help you stop being afraid of a real one.",
      "Seni sanal bir çukurdan korkutan aynı numara, gerçek bir çukurdan korkmayı bırakmana da yardım edebilir.",
      [E("plank", 0.5, 0.55, 1.0), F(0.5, 0.4, y=0.53, **VR), E("gauge", 0.85, 0.3, 0.5, value=0.8)]),
    # ------------------------------------------------------------ Karanlık taraf
    S("But there are costs.", "Ama bedelleri de var.", [T(0.5, 0.42, "the costs", 1.8, "red", underline="red")]),
    S("Many people feel *cybersickness* — nausea and dizziness.", "Birçok kişi *siber hastalık* yaşıyor: mide bulantısı ve baş dönmesi.",
      [G(), F(0.45, 0.55, "think", **VR), T(0.72, 0.3, "@ # ~", 1.4, "red")]),
    S("One common explanation is *sensory conflict*: your eyes say you're moving, but your inner ear says you're standing still,",
      "Yaygın açıklamalardan biri *duyusal çatışma*: Gözlerin hareket ettiğini söylüyor, iç kulağın ise yerinde durduğunu.",
      [E("eye", 0.27, 0.4, 0.8), T(0.27, 0.6, "moving!", 1.0, "blue"), E("ear", 0.72, 0.42, 0.9), T(0.72, 0.68, "standing still", 1.0, "red")]),
    S("and your brain doesn't like the disagreement.", "Beynin de bu anlaşmazlığı sevmiyor.",
      [E("brain", 0.5, 0.5, 1.1), T(0.5, 0.1, "?!", 2.0, "red")]),
    S("And some effects are stranger. In a 2010 study, psychologist *Frederick Aardema* and colleagues found that after a short session in VR,",
      "Bazı etkiler daha da tuhaf. 2010'daki bir çalışmada psikolog *Frederick Aardema* ve arkadaşları, VR'da geçirilen kısa bir oturumdan sonra",
      [G(), F(0.5, 0.55, **VR), T(0.5, 0.1, "Aardema · 2010", 1.0, "blue")]),
    S("participants reported more *dissociative* experiences — and a weaker sense of presence in the real world around them.",
      "katılımcıların daha fazla *dissosiyatif* deneyim bildirdiğini ve etraflarındaki gerçek dünyada mevcudiyet hislerinin zayıfladığını buldu.",
      [G(), F(0.5, 0.55, "think"), E("house", 0.2, 0.8, 0.5), E("globe", 0.82, 0.45, 0.5), T(0.5, 0.12, "not quite here", 1.0, "red")]),
    S("It was a small, temporary effect. But it hints at something:", "Küçük ve geçici bir etkiydi. Ama bir şeye işaret ediyor:",
      [E("gauge", 0.5, 0.65, 1.2, value=0.4, label="temporary")]),
    S("if a world can feel real enough to replace this one for a while, coming back isn't always seamless.",
      "Bir dünya bir süreliğine bunun yerini alacak kadar gerçek hissettirebiliyorsa, geri dönmek her zaman pürüzsüz olmuyor.",
      [E("door", 0.5, 0.8, 1.2, open_=True), G(), F(0.25, 0.5, "walk")]),
    # ------------------------------------------------------------ Deneyim makinesi
    S("And this brings us to the most famous thought experiment about virtual worlds.", "Ve bu bizi sanal dünyalarla ilgili en ünlü düşünce deneyine getiriyor.",
      [E("head", 0.5, 0.5, 0.7, glow=True)]),
    S("In 1974, the philosopher *Robert Nozick* asked his readers to imagine an *experience machine*.",
      "1974'te filozof *Robert Nozick* okurlarından bir *deneyim makinesi* hayal etmelerini istedi.",
      [E("machine", 0.4, 0.85, 1.0), T(0.78, 0.1, "Nozick · 1974", 1.0, "blue")]),
    S("Neuroscientists could plug you in and give you any experiences you wanted — writing a great novel, falling in love, making a friend.",
      "Sinirbilimciler seni makineye bağlayıp istediğin her deneyimi yaşatabilirdi: harika bir roman yazmak, âşık olmak, arkadaş edinmek.",
      [E("machine", 0.3, 0.85, 0.8), B(0.72, 0.35, 1.0, "thought"), E("books", 0.66, 0.42, 0.4), E("heart", 0.78, 0.3, 0.4)]),
    S("It would feel completely real. You'd never know you were in the machine.", "Tamamen gerçek hissettirirdi. Makinede olduğunu asla bilmezdin.",
      [E("machine", 0.4, 0.85, 1.0), T(0.8, 0.5, "100% real", 1.1, "blue")]),
    S("Would you plug in for the rest of your life?", "Hayatının geri kalanı için makineye bağlanır mıydın?",
      [E("plug", 0.5, 0.5, 1.3), T(0.78, 0.25, "?", 3.0, "red")]),
    S("Nozick bet that most people would say *no*. And when philosophers ask, most people do refuse.",
      "Nozick insanların çoğunun *hayır* diyeceğine bahse girdi. Filozoflar sorduğunda da çoğu insan reddediyor.",
      [E("machine", 0.35, 0.85, 0.8), E("cross", 0.35, 0.6, 1.4, at=1.5), T(0.8, 0.4, "no", 2.0, "red")]),
    S("We seem to want to actually *do* things, not just feel like we're doing them. To actually *be* someone, not just experience being them.",
      "Görünen o ki sadece bir şeyleri yapıyormuş gibi hissetmek değil, gerçekten *yapmak* istiyoruz. Birisi olmayı sadece deneyimlemek değil, gerçekten *o kişi olmak* istiyoruz.",
      [T(0.3, 0.35, "feel", 1.3), E("cross", 0.3, 0.35, 0.6, at=1.5), T(0.7, 0.35, "DO", 1.6, "blue", underline="blue"), T(0.7, 0.6, "BE", 1.6, "blue", underline="blue")]),
    S("But here's the twist. In 2010, philosopher *Felipe De Brigard* flipped the question.",
      "Ama işin ilginç yanı şu: 2010'da filozof *Felipe De Brigard* soruyu tersine çevirdi.",
      [T(0.5, 0.42, "flip it", 1.8, "red", underline="red"), T(0.5, 0.65, "De Brigard · 2010", 0.9, "blue")]),
    S("He told people: imagine you discover that you're *already* in the experience machine. Your whole life so far has been simulated.",
      "İnsanlara şöyle dedi: *Zaten* deneyim makinesinde olduğunu keşfettiğini hayal et. Şimdiye kadarki bütün hayatın bir simülasyondu.",
      [E("machine", 0.4, 0.85, 1.0), G(0.86), F(0.33, 0.35, "sit", y=0.68), T(0.82, 0.12, "already?", 1.2, "red")]),
    S("Do you want to unplug and return to your real life — which you know nothing about?",
      "Fişi çekip hakkında hiçbir şey bilmediğin gerçek hayatına dönmek ister misin?",
      [E("plug", 0.3, 0.5, 1.0), E("door", 0.72, 0.8, 1.1), T(0.72, 0.12, "???", 1.3)]),
    S("Many people chose to *stay*.", "Birçok kişi *kalmayı* seçti.",
      [E("machine", 0.4, 0.85, 1.0), T(0.8, 0.45, "stay", 2.0, "blue", underline="red")]),
    S("Maybe it isn't reality we're attached to. Maybe it's just the life we already have.",
      "Belki de bağlı olduğumuz şey gerçeklik değil. Belki sadece zaten sahip olduğumuz hayat.",
      [E("house", 0.5, 0.8, 1.2)]),
    # ------------------------------------------------------------ Sanal olan gerçek mi
    S("So is a virtual world real?", "Peki sanal bir dünya gerçek midir?", [T(0.5, 0.42, "real?", 2.4, underline="red")]),
    S("In his 2022 book *Reality+*, philosopher *David Chalmers* argues something surprising: *yes*.",
      "Filozof *David Chalmers* 2022 tarihli *Reality+* kitabında şaşırtıcı bir şey savunuyor: *Evet*.",
      [E("books", 0.3, 0.75, 1.0, n=2), T(0.3, 0.3, "Reality+", 1.2, "blue"), T(0.72, 0.42, "YES", 2.4, "red", underline="red")]),
    S("Not in the sense that a virtual chair is made of wood. But virtual objects are real *digital* objects.",
      "Sanal bir sandalyenin tahtadan yapıldığı anlamında değil. Ama sanal nesneler gerçek *dijital* nesnelerdir.",
      [E("chair", 0.35, 0.78, 1.0), T(0.7, 0.4, "wood", 1.1), E("cross", 0.7, 0.4, 0.6, at=1.2), T(0.7, 0.6, "digital", 1.2, "blue", underline="blue")]),
    S("They exist, they have effects, and the experiences you have with them are genuine experiences.",
      "Var olurlar, etkileri vardır ve onlarla yaşadığın deneyimler gerçek deneyimlerdir.",
      [G(), F(0.4, 0.5, "sit", **VR), E("chair", 0.62, 0.8, 0.8)]),
    S("In his view, a life in a virtual world could be a meaningful life — with real relationships, real achievements, real choices.",
      "Ona göre sanal bir dünyadaki hayat anlamlı bir hayat olabilir: gerçek ilişkiler, gerçek başarılar, gerçek seçimlerle.",
      [T(0.5, 0.25, "relationships", 1.1), T(0.5, 0.42, "achievements", 1.1), T(0.5, 0.59, "choices", 1.1)]),
    S("Virtual reality, he says, is *genuine reality*.", "Sanal gerçeklik, diyor, *hakiki gerçekliktir*.",
      [T(0.5, 0.42, "genuine reality", 1.8, "red", underline="red")]),
    S("Not everyone agrees. Critics point out that a world designed by someone else is also a world *controlled* by someone else —",
      "Herkes aynı fikirde değil. Eleştirmenler, başkası tarafından tasarlanan bir dünyanın aynı zamanda başkası tarafından *kontrol edilen* bir dünya olduğuna dikkat çekiyor.",
      [E("demon", 0.5, 0.25, 0.6, strings_to=[[0.45, 0.55], [0.55, 0.55]]), G(), F(0.5, 0.4, **VR)]),
    S("with its owners deciding what you see, what you can do, and what it costs.", "Neyi göreceğine, neyi yapabileceğine ve bunun neye mal olacağına sahipleri karar veriyor.",
      [T(0.5, 0.25, "what you see", 1.0), T(0.5, 0.42, "what you can do", 1.0), T(0.5, 0.59, "what it costs", 1.0, "red")]),
    S("Which brings us back to Plato's cave. The prisoners weren't only fooled. Someone else was holding the objects that cast the shadows.",
      "Bu da bizi Platon'un mağarasına geri getiriyor. Tutsaklar sadece kandırılmıyordu. Gölgeleri oluşturan nesneleri başka biri tutuyordu.",
      [E("cave", 0.5, 0.85, 1.0), F(0.68, 0.35, "reach", y=0.85)]),
    # ------------------------------------------------------------ Kendin dene
    S("Let's try something. Imagine three machines.", "Bir şey deneyelim. Üç makine hayal et.",
      [E("door", 0.3, 0.8, 1.0, label="1"), E("door", 0.5, 0.8, 1.0, label="2"), E("door", 0.7, 0.8, 1.0, label="3"), T(0.1, 0.1, "try this", 1.0, "red", underline="red")]),
    S("The first gives you a perfect life, but you'll never know it's not real.", "Birincisi sana kusursuz bir hayat veriyor ama gerçek olmadığını asla bilmeyeceksin.",
      [E("door", 0.3, 0.8, 1.2, label="1", open_=True), T(0.65, 0.45, "never know", 1.2, "blue")]),
    S("The second gives you the same perfect life, but you'll *always* know it's a simulation.",
      "İkincisi aynı kusursuz hayatı veriyor ama bir simülasyon olduğunu *her zaman* bileceksin.",
      [E("door", 0.3, 0.8, 1.2, label="2", open_=True), T(0.65, 0.45, "always know", 1.2, "red")]),
    S("The third is just your real life — with all its boredom, failure, and people who sometimes disappoint you.",
      "Üçüncüsü sadece senin gerçek hayatın: bütün sıkıntısı, başarısızlıkları ve bazen seni hayal kırıklığına uğratan insanlarıyla.",
      [E("door", 0.3, 0.8, 1.2, label="3"), E("house", 0.68, 0.8, 0.8), F(0.86, 0.35)]),
    S("Which would you choose? And here's the harder question: why does your answer change between the first and the second, if the experiences are exactly the same?",
      "Hangisini seçerdin? Daha zor soru şu: Deneyimler tamamen aynıysa, cevabın birinci ve ikinci arasında neden değişiyor?",
      [E("door", 0.35, 0.8, 1.0, label="1"), T(0.5, 0.5, "≠", 2.0, "red"), E("door", 0.65, 0.8, 1.0, label="2")]),
    S("Whatever you answered tells you what you really value. Not just feeling good — but something about *truth*.",
      "Verdiğin cevap sana gerçekten neye değer verdiğini söylüyor. Sadece iyi hissetmeye değil, *hakikat* dediğimiz bir şeye.",
      [T(0.5, 0.35, "feeling good", 1.1), T(0.5, 0.58, "TRUTH", 2.0, "blue", underline="red")]),
    # ------------------------------------------------------------ Kapanış
    S("Ivan Sutherland imagined a room where a displayed bullet could be fatal. We're not there.",
      "Ivan Sutherland, gösterilen bir kurşunun öldürücü olabileceği bir oda hayal etmişti. Henüz orada değiliz.",
      [E("room", 0.5, 0.82, 1.2), T(0.5, 0.5, "not yet", 1.3, "blue")]),
    S("But every year, the shadows on the wall get sharper.", "Ama her yıl duvardaki gölgeler biraz daha keskinleşiyor.", [E("cave", 0.5, 0.85, 1.0)]),
    S("Maybe the real question isn't whether virtual worlds will become indistinguishable from this one.",
      "Belki asıl soru, sanal dünyaların bu dünyadan ayırt edilemez hale gelip gelmeyeceği değil.",
      [E("globe", 0.3, 0.45, 0.8), T(0.5, 0.45, "=", 2.0), E("screen", 0.72, 0.55, 0.9)]),
    S("Maybe it's whether we'll still remember that we chose to walk in — and that we can walk back out.",
      "Belki de içeri girmeyi bizim seçtiğimizi ve geri çıkabileceğimizi hâlâ hatırlayıp hatırlamayacağımız.",
      [E("door", 0.6, 0.8, 1.2, open_=True), G(), F(0.35, 0.5, "walk", **VR)]),
    S("Because the most important thing about a cave... is knowing where the exit is.", "Çünkü bir mağarayla ilgili en önemli şey… çıkışın nerede olduğunu bilmektir.",
      [E("cave", 0.5, 0.85, 1.0, fire=False), E("dot", 0.92, 0.4, 1.4), F(0.82, 0.38, "walk", y=0.85)]),
]

subscribe = dict(after=11, sketch=[dict(el="subscribe", x=0.45, y=0.45, s=1.4), dict(el="arrow", x=0.2, y=0.75, x2=0.33, y2=0.55, color="red", s=1.2)],
                 say={"en": "Quick favor before we start: if you like questions about what's real, *subscribe*. It genuinely helps the channel.",
                      "tr": "Başlamadan küçük bir rica: Neyin gerçek olduğuyla ilgili sorulardan hoşlanıyorsan *abone ol*. Kanala gerçekten çok yardımı oluyor."})
meta = {"en": dict(title="Would You Plug Into the Experience Machine?", description="", tags=[]),
        "tr": dict(title="Deneyim Makinesine Bağlanır mıydın?", description="", tags=[])}
out = dict(slug="vr", format="long", theme="karakalem", character="none", languages=["en"], subtitles=["tr"],
           voices={"en": "am_fenrir"}, speech_rate=0.88, meta=meta, subscribe=subscribe, scenes=scenes)
json.dump(out, open(os.path.join(HERE, "vr.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
words = sum(len(s["say"]["en"].split()) for s in scenes) + len(subscribe["say"]["en"].split())
print(f"{len(scenes)} sahne, {words} kelime")
