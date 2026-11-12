#!/usr/bin/env python3
"""Tartarya videosunun sahne sahne senaryosu.  Çalıştır: python3 senaryolar/tartarya_uret.py -> senaryolar/tartarya.json"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
IMGS = {}
p = os.path.join(HERE, "tartarya_gorseller.json")
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
    # ============================================================ 1. PERDE: TEORİ
    S("What if everything you learned about the last three hundred years was a lie?",
      "Ya son üç yüz yıl hakkında öğrendiğin her şey bir yalansa?",
      [E("scroll", 0.35, 0.45, 1.0, text="history"), E("cross", 0.35, 0.45, 1.0, at=1.0), T(0.75, 0.42, "a lie?", 1.8, "red")]),
    S("What if, not long ago, there was an empire so vast it covered much of the Earth,",
      "Ya çok uzun olmayan bir süre önce, dünyanın büyük kısmını kaplayan devasa bir imparatorluk varsa?",
      [E("globe", 0.5, 0.5, 1.3), E("circle", 0.5, 0.5, 1.0, rx=260, ry=260, color="red")]),
    S("with domed palaces, star-shaped citadels, and towers that drew energy from the sky?",
      "Kubbeli sarayları, yıldız biçimli kaleleri ve gökyüzünden enerji çeken kuleleri olan?",
      [E("palace", 0.25, 0.85, 0.55), E("starfort", 0.55, 0.5, 0.5), E("spire", 0.85, 0.92, 0.5)]),
    S("And what if it was wiped from history so completely that today, almost no one has heard its name?",
      "Ve ya tarihten öyle bir silindiyse ki bugün neredeyse kimse adını bile duymamışsa?",
      [E("oldmap", 0.5, 0.5, 1.1, label="TARTARIA", faded=True), E("cross", 0.5, 0.5, 0.9, at=1.4)]),
    S("Its name, they say, was *Tartaria*.", "İddiaya göre adı *Tartarya*ydı.",
      [T(0.5, 0.42, "TARTARIA", 3.0, "red", underline="red")]),
    S("Millions of people have watched videos about it. Some are convinced it's the greatest cover-up ever.",
      "Milyonlarca insan onunla ilgili videolar izledi. Bazıları bunun gelmiş geçmiş en büyük örtbas olduğuna inanıyor.",
      [E("phone", 0.25, 0.45, 0.8), E("screen", 0.5, 0.6, 0.8), E("phone", 0.75, 0.45, 0.8), T(0.5, 0.1, "millions of views", 1.2, "blue")]),
    S("Tonight, we'll follow the clues, all of them, and see where they lead.",
      "Bu gece ipuçlarını, hepsini, takip edeceğiz ve bizi nereye götürdüklerine bakacağız.",
      [E("pinboard", 0.45, 0.5, 1.0), E("magnifier", 0.85, 0.3, 0.6)]),
    # ------------------------------------------------------------ İpucu 1
    S("The first clue is real, and you can check it yourself.", "İlk ipucu gerçek ve kendin kontrol edebilirsin.",
      [T(0.12, 0.1, "clue 1", 1.2, "red", underline="red"), E("magnifier", 0.5, 0.45, 1.2)]),
    IMG("map", "Tartaria · Abraham Ortelius, 1570",
        "Open old European maps from the 1500s to the 1700s, and you'll find a huge territory across Asia labeled *Tartaria*, or *Great Tartary*.",
        "1500'lerden 1700'lere kadar eski Avrupa haritalarını aç; Asya boyunca *Tartaria* ya da *Büyük Tartarya* yazan devasa bir toprak bulursun.",
        [E("oldmap", 0.5, 0.5, 1.4, label="TARTARIA")]),
    S("An eighteenth-century encyclopedia even describes Tartary as \"a vast country in the northern parts of Asia.\"",
      "On sekizinci yüzyıldan bir ansiklopedi bile Tartarya'yı \"Asya'nın kuzeyinde uçsuz bucaksız bir ülke\" diye tanımlıyor.",
      [E("books", 0.3, 0.72, 1.0, n=3), T(0.68, 0.38, "\"a vast country\"", 1.3, "red"), T(0.68, 0.58, "1700s encyclopedia", 1.0, "blue")]),
    S("So believers ask: if Tartary was on the maps, and in the encyclopedias, *where did it go*?",
      "İnananlar soruyor: Tartarya haritalardaysa, ansiklopedilerdeyse *nereye gitti*?",
      [E("oldmap", 0.4, 0.5, 1.0, label="TARTARIA"), T(0.85, 0.42, "?", 3.0, "red")]),
    S("Why don't schools teach it? Why does it simply vanish from maps in the 1800s?",
      "Okullar neden öğretmiyor? 1800'lerde neden haritalardan öylece kayboluyor?",
      [E("oldmap", 0.4, 0.5, 1.0, label="TARTARIA", faded=True), T(0.82, 0.35, "1800s", 1.3, "blue"), T(0.82, 0.55, "gone?", 1.3, "red")]),
    # ------------------------------------------------------------ İpucu 2
    S("The second clue is under our feet.", "İkinci ipucu ayaklarımızın altında.",
      [T(0.12, 0.1, "clue 2", 1.2, "red", underline="red"), G(0.7), F(0.5, 0.45, y=0.7), E("arrow", 0.5, 0.75, x2=0.5, y2=0.92, color="red")]),
    S("All over the world, there are old buildings whose ground-floor windows sit *below* the street,",
      "Dünyanın her yerinde zemin kat pencereleri sokağın *altında* kalmış eski binalar var,",
      [E("buried", 0.45, 0.72, 0.9), E("circle", 0.45, 0.8, 0.8, rx=300, ry=80, color="red")]),
    S("half-buried, as if the earth rose up and swallowed them.", "sanki toprak yükselip onları yutmuş gibi yarı gömülü.",
      [E("buried", 0.45, 0.72, 0.9), A(0.85, 0.95, 0.85, 0.75, bend=0.0, color="red")]),
    S("Believers call it the *mud flood*: a global catastrophe in the 1800s that buried Tartarian cities under meters of mud.",
      "İnananlar buna *çamur seli* diyor: 1800'lerde Tartarya şehirlerini metrelerce çamurun altına gömen küresel bir felaket.",
      [E("palace", 0.5, 0.75, 0.9, faded=True), E("mudwave", 0.5, 0.82, 1.0), T(0.5, 0.1, "MUD FLOOD", 1.8, "red", underline="red")]),
    S("The survivors, they say, simply built on top and forgot.", "Hayatta kalanlar da diyorlar, üstüne inşa edip unuttu.",
      [E("mudwave", 0.5, 0.9, 1.0), E("house", 0.35, 0.72, 0.7), E("house", 0.65, 0.72, 0.7)]),
    # ------------------------------------------------------------ İpucu 3
    S("The third clue can only be seen from above.", "Üçüncü ipucu ancak yukarıdan görülebiliyor.",
      [T(0.12, 0.1, "clue 3", 1.2, "red", underline="red"), E("eye", 0.5, 0.45, 1.2)]),
    IMG("bourtange", "Bourtange, Netherlands · aerial view",
        "Star-shaped fortresses, with perfect geometric points, appear in Europe, the Americas, Africa and Asia.",
        "Kusursuz geometrik uçlara sahip yıldız biçimli kaleler Avrupa'da, Amerika'da, Afrika'da ve Asya'da karşımıza çıkıyor.",
        [E("starfort", 0.5, 0.5, 1.2)]),
    S("Some believers say they're too advanced, too similar, too widespread to be a coincidence.",
      "Bazı inananlar bunların tesadüf olamayacak kadar gelişmiş, benzer ve yaygın olduğunu söylüyor.",
      [E("starfort", 0.2, 0.4, 0.35), E("starfort", 0.5, 0.35, 0.35), E("starfort", 0.8, 0.4, 0.35), T(0.5, 0.82, "coincidence?", 1.4, "red")]),
    S("A few go further: maybe they weren't forts at all, but *machines*, built to harness some forgotten form of energy.",
      "Bazıları daha da ileri gidiyor: Belki bunlar hiç kale değildi, unutulmuş bir enerji türünü kullanmak için yapılmış *makinelerdi*.",
      [E("starfort", 0.45, 0.55, 1.0, glow=True), T(0.85, 0.3, "machines?", 1.3, "red")]),
    # ------------------------------------------------------------ İpucu 4: kuleler
    S("The fourth clue points to the sky.", "Dördüncü ipucu gökyüzünü gösteriyor.",
      [T(0.12, 0.1, "clue 4", 1.2, "red", underline="red"), E("spire", 0.5, 0.95, 0.9, bolt=False)]),
    S("Look closely at old palaces, churches and exhibition halls, and you'll see spires, domes topped with metal points, and towers crowned with what look like antennas.",
      "Eski saraylara, kiliselere ve sergi salonlarına dikkatlice bak; sivri kuleler, tepesinde metal uçlar olan kubbeler ve anten gibi görünen şeylerle taçlanmış kuleler görürsün.",
      [E("palace", 0.35, 0.88, 0.75), E("spire", 0.8, 0.95, 0.7, bolt=False), E("circle", 0.8, 0.25, 0.5, rx=120, ry=120, color="red")]),
    S("Some believers say these weren't decorations at all.", "Bazı inananlar bunların hiç süs olmadığını söylüyor.",
      [E("spire", 0.5, 0.95, 0.8, bolt=False), T(0.8, 0.4, "decoration?", 1.2), E("cross", 0.8, 0.4, 0.5, at=0.8)]),
    S("They say Tartarian buildings were connected to a worldwide grid of *free energy*, pulling electricity straight out of the atmosphere,",
      "Onlara göre Tartarya binaları, elektriği doğrudan atmosferden çeken küresel bir *bedava enerji* ağına bağlıydı;",
      [E("spire", 0.2, 0.95, 0.5), E("spire", 0.5, 0.95, 0.5), E("spire", 0.8, 0.95, 0.5), T(0.5, 0.08, "FREE ENERGY?", 1.5, "red")]),
    S("technology later hidden so people would have to pay for power.", "bu teknoloji de insanlar elektriğe para ödesin diye sonradan saklandı.",
      [E("plug", 0.3, 0.55, 1.0), E("money", 0.72, 0.6, 0.9, text="$")]),
    IMG("tesla", "Tesla's Wardenclyffe Tower · c. 1904",
        "They often point to the inventor *Nikola Tesla*, who really did dream of sending electricity through the air without wires.",
        "Sık sık mucit *Nikola Tesla*'yı gösteriyorlar; Tesla gerçekten de elektriği kablosuz olarak havadan iletmeyi hayal etmişti.",
        [E("spire", 0.4, 0.95, 0.8), T(0.78, 0.4, "Tesla", 1.6, "blue")]),
    # ------------------------------------------------------------ İpucu 5: Beyaz şehir
    S("The fifth clue is in old photographs.", "Beşinci ipucu eski fotoğraflarda.",
      [T(0.12, 0.1, "clue 5", 1.2, "red", underline="red"), E("camera", 0.5, 0.45, 1.2)]),
    IMG("whitecity", "World's Columbian Exposition · Chicago, 1893",
        "In 1893, Chicago hosted a World's Fair. Photos show a dazzling \"White City\": palaces, domes and columns, gleaming like marble.",
        "1893'te Chicago bir Dünya Fuarı'na ev sahipliği yaptı. Fotoğraflar göz kamaştırıcı bir \"Beyaz Şehir\" gösteriyor: mermer gibi parıldayan saraylar, kubbeler, sütunlar.",
        [E("palace", 0.5, 0.85, 1.1), T(0.5, 0.08, "Chicago · 1893", 1.3, "blue")]),
    S("Then, within a couple of years, almost all of it was *gone*.", "Sonra birkaç yıl içinde neredeyse hepsi *yok oldu*.",
      [E("palace", 0.5, 0.85, 1.1, faded=True), T(0.5, 0.15, "gone", 2.0, "red", underline="red")]),
    S("How, believers ask, could anyone build such wonders so quickly? And why would they destroy them?",
      "İnananlar soruyor: Biri böyle harikaları nasıl bu kadar hızlı inşa edebilir? Ve neden yok etsin?",
      [E("hourglass", 0.3, 0.45, 0.9), T(0.72, 0.35, "so fast?", 1.3, "red"), T(0.72, 0.55, "destroyed?", 1.3, "red")]),
    S("Unless, they say, the buildings were never built for the fair at all, but *found*.",
      "Meğer ki, diyorlar, binalar fuar için hiç inşa edilmemişti; *bulunmuştu*.",
      [E("palace", 0.4, 0.85, 0.8), E("magnifier", 0.82, 0.3, 0.7), T(0.82, 0.7, "found?", 1.4, "red")]),
    # ------------------------------------------------------------ İpucu 6: trenler
    S("And the sixth clue is the darkest.", "Ve altıncı ipucu en karanlığı.", [T(0.5, 0.42, "clue 6", 2.2, "red", underline="red")]),
    S("Between 1854 and 1929, trains carried around two hundred thousand children from crowded eastern American cities to new homes in the West.",
      "1854 ile 1929 arasında trenler, kalabalık doğu Amerika şehirlerinden yaklaşık iki yüz bin çocuğu batıdaki yeni evlerine taşıdı.",
      [E("train", 0.5, 0.7, 1.0), T(0.5, 0.12, "1854–1929 · ≈200,000", 1.3, "blue")]),
    S("History calls them the *orphan trains*.", "Tarih bunlara *yetim trenleri* diyor.", [E("train", 0.5, 0.7, 1.0), T(0.5, 0.12, "orphan trains", 1.6, underline="red")]),
    S("Some Tartaria believers have a chilling explanation: these children, they claim, were used to *repopulate* the world after the mud flood,",
      "Bazı Tartarya inananlarının ürpertici bir açıklaması var: İddiaya göre bu çocuklar çamur selinden sonra dünyayı *yeniden nüfuslandırmak* için kullanıldı",
      [E("mudwave", 0.3, 0.85, 0.5), A(0.5, 0.6, 0.62, 0.6, bend=0.0), E("train", 0.8, 0.7, 0.5), T(0.5, 0.15, "repopulate?", 1.5, "red")]),
    S("and to raise a new generation that would never know the truth.", "ve gerçeği hiç bilmeyecek yeni bir nesil yetiştirmek için.",
      [G(), F(0.3, 0.3, child=True), F(0.42, 0.3, child=True), F(0.54, 0.3, child=True), E("padlock", 0.8, 0.45, 0.8)]),
    S("Maps. Mud. Stars. Spires. White cities. Trains full of children.", "Haritalar. Çamur. Yıldızlar. Kuleler. Beyaz şehirler. Çocuk dolu trenler.",
      [E("pinboard", 0.5, 0.5, 1.2, n=6)]),
    S("It sounds like a perfect puzzle. So now, let's do what every good detective does: check the records.",
      "Kusursuz bir yapboz gibi görünüyor. O zaman şimdi her iyi dedektifin yaptığını yapalım: kayıtlara bakalım.",
      [E("magnifier", 0.3, 0.45, 1.0), E("books", 0.72, 0.72, 1.0, n=4), T(0.72, 0.25, "the records", 1.3, "blue", underline="blue")]),
    # ============================================================ 2. PERDE: KAYITLAR
    S("Start with the maps. \"Tartary\" was never one country.", "Haritalarla başlayalım. \"Tartarya\" hiçbir zaman tek bir ülke olmadı.",
      [E("oldmap", 0.4, 0.5, 1.0, label="TARTARIA"), T(0.85, 0.42, "not a\ncountry", 1.2, "blue")]),
    S("It was what Europeans called the huge part of Asia they knew little about,", "Avrupalıların pek tanımadıkları devasa Asya topraklarına verdikleri addı:",
      [E("oldmap", 0.5, 0.5, 1.1, label="?"), T(0.5, 0.1, "\"lands we don't know\"", 1.2, "red")]),
    S("the lands of the *Tatars*, a loose name for many Turkic and Mongol peoples.", "*Tatarların* toprakları. Tatar da birçok Türk ve Moğol halkı için kullanılan gevşek bir isimdi.",
      [E("chariot", 0.4, 0.65, 0.8, color="red"), T(0.8, 0.35, "Tatars", 1.5, "red"), T(0.8, 0.55, "Turkic · Mongol", 1.0, "blue")]),
    S("Medieval writers even linked \"Tatar\" to *Tartarus*, the Greek underworld, as if the Mongol riders had come from hell.",
      "Ortaçağ yazarları \"Tatar\"ı Yunan yeraltı dünyası *Tartaros* ile bile ilişkilendirdi; sanki Moğol atlıları cehennemden gelmişti.",
      [T(0.25, 0.42, "Tatar", 1.6), A(0.38, 0.42, 0.6, 0.42, bend=-0.2, color="red"), T(0.78, 0.42, "Tartarus", 1.6, "red"), E("campfire", 0.78, 0.8, 0.8)]),
    S("As explorers and empires mapped Asia in detail, the vague label was replaced with real names: Siberia, Kazakhstan, Mongolia.",
      "Kâşifler ve imparatorluklar Asya'yı ayrıntılı haritalandırdıkça bu belirsiz etiketin yerini gerçek isimler aldı: Sibirya, Kazakistan, Moğolistan.",
      [E("oldmap", 0.5, 0.5, 1.2, label=None), T(0.4, 0.38, "Siberia", 1.0), T(0.35, 0.58, "Kazakhstan", 1.0), T(0.62, 0.55, "Mongolia", 1.0)]),
    S("Tartary didn't vanish. The *blank spot* did.", "Tartarya kaybolmadı. *Boş nokta* kayboldu.",
      [T(0.5, 0.35, "Tartary didn't vanish", 1.3), T(0.5, 0.58, "the blank spot did", 1.5, "red", underline="red")]),
    S("The \"mud flood\" buildings have well-recorded explanations.", "\"Çamur seli\" binalarının iyi kayıt altına alınmış açıklamaları var.",
      [E("buried", 0.4, 0.72, 0.8), E("books", 0.8, 0.72, 0.7, n=3)]),
    IMG("seattle", "Seattle Underground · old storefronts below today's street",
        "After the Great Seattle Fire of 1889, Seattle rebuilt its streets one to two stories *higher* to fix flooding and drainage.",
        "1889'daki Büyük Seattle Yangını'ndan sonra Seattle, su baskını ve drenaj sorunlarını çözmek için sokaklarını bir iki kat *yukarıda* yeniden yaptı.",
        [E("buried", 0.45, 0.72, 0.9), T(0.5, 0.08, "Seattle · 1889", 1.3, "blue")]),
    S("Old ground floors became basements. You can tour the *Seattle Underground* today.",
      "Eski zemin katlar bodrum oldu. Bugün *Seattle Yeraltı*'nı gezebilirsin.",
      [E("buried", 0.4, 0.72, 0.9), G(0.72), F(0.82, 0.35, "walk", -1, y=0.72), T(0.82, 0.88, "tours today", 1.0, "blue")]),
    IMG("briggs", "Raising the Briggs House · Chicago, 1860s",
        "In the 1850s and 60s, Chicago used thousands of jackscrews to *lift entire buildings* to install a sewer system,",
        "1850'ler ve 60'larda Chicago, kanalizasyon sistemi kurmak için binlerce kriko kullanarak *koca binaları kaldırdı*;",
        [E("jacks", 0.5, 0.8, 1.1), T(0.5, 0.08, "Chicago · 1850s–60s", 1.3, "blue")]),
    S("sometimes while people kept working inside.", "bazen insanlar içeride çalışmaya devam ederken.",
      [E("jacks", 0.4, 0.8, 1.0), F(0.42, 0.18, "sit", y=0.45), T(0.82, 0.35, "still open", 1.2, "red")]),
    S("And everywhere else, streets simply rise over centuries, as new paving and rubble pile up.",
      "Geri kalan her yerde de sokaklar, yüzyıllar boyunca biriken yeni kaldırım ve molozla kendiliğinden yükselir.",
      [E("buried", 0.4, 0.72, 0.8), A(0.85, 0.95, 0.85, 0.65, bend=0.0, color="red"), T(0.5, 0.1, "street level rises over centuries", 1.2)]),
    S("Star forts were a response to the *cannon*.", "Yıldız kaleler *topa* verilmiş bir cevaptı.",
      [E("starfort", 0.35, 0.5, 0.8), E("dot", 0.8, 0.45, 1.4, color="ink"), A(0.75, 0.45, 0.55, 0.45, bend=0.0, color="red")]),
    S("In Italy in the late 1400s and 1500s, engineers learned that tall walls shattered under cannon fire,",
      "1400'lerin sonu ve 1500'lerde İtalya'da mühendisler yüksek surların top atışıyla parçalandığını öğrendi;",
      [E("door", 0.35, 0.8, 1.2), E("cross", 0.35, 0.55, 1.0, at=1.0), T(0.75, 0.4, "tall walls", 1.3), T(0.75, 0.6, "shatter", 1.3, "red")]),
    S("while low, thick, angled walls survived, and pointed bastions left no blind spots.",
      "alçak, kalın, açılı surlar ise ayakta kalıyordu; sivri burçlar da kör nokta bırakmıyordu.",
      [E("starfort", 0.45, 0.5, 1.0), T(0.85, 0.42, "no blind\nspots", 1.1, "blue")]),
    IMG("palmanova", "Palmanova, Italy (1593) · aerial view",
        "They wrote books full of diagrams. France's *Vauban* built or rebuilt more than a hundred.",
        "Çizimlerle dolu kitaplar yazdılar. Fransa'nın ünlü mühendisi *Vauban* yüzden fazlasını inşa etti ya da yeniden yaptı.",
        [E("books", 0.3, 0.72, 1.0, n=3), T(0.72, 0.42, "Vauban: 100+", 1.4, "blue")]),
    S("They look alike for the same reason airports look alike: same problem, same solution.",
      "Birbirlerine benzemelerinin sebebi havalimanlarının birbirine benzemesiyle aynı: aynı sorun, aynı çözüm.",
      [E("starfort", 0.25, 0.45, 0.4), E("starfort", 0.5, 0.45, 0.4), E("starfort", 0.75, 0.45, 0.4), T(0.5, 0.85, "same problem · same solution", 1.2, "red")]),
    S("And the White City? Most of its buildings were *temporary*:", "Peki Beyaz Şehir? Binalarının çoğu *geçiciydi*:",
      [E("palace", 0.45, 0.85, 1.0), T(0.5, 0.1, "temporary", 1.6, "red", underline="red")]),
    S("frames covered in *staff*, a cheap mix of plaster and fibers, painted to look like marble.",
      "Mermer gibi görünsün diye boyanmış, alçı ve lif karışımı ucuz bir malzeme olan *staff* ile kaplı iskeletler.",
      [E("palace", 0.3, 0.85, 0.7), E("ladder", 0.75, 0.75, 0.9), T(0.75, 0.15, "staff = plaster + fiber", 1.1, "blue")]),
    S("They were built to last one summer. A fire in 1894 destroyed much of what remained.",
      "Tek bir yaz dayanmak için yapılmışlardı. 1894'teki bir yangın kalanların çoğunu yok etti.",
      [E("calendar", 0.25, 0.45, 0.8, text="1 summer"), E("palace", 0.68, 0.85, 0.7), E("campfire", 0.68, 0.55, 1.2), T(0.68, 0.1, "1894", 1.3, "red")]),
    S("One building was rebuilt in stone, and it's now Chicago's Museum of Science and Industry.",
      "Bir bina taşla yeniden inşa edildi ve bugün Chicago'nun Bilim ve Sanayi Müzesi.",
      [E("palace", 0.5, 0.85, 1.0), T(0.5, 0.1, "Museum of Science and Industry", 1.1, "blue")]),
    S("The spires? Many are simply architecture: bell towers, flagpoles and decoration.", "Kuleler mi? Birçoğu sadece mimari: çan kuleleri, bayrak direkleri ve süslemeler.",
      [E("spire", 0.3, 0.95, 0.6, bolt=False), E("bell", 0.7, 0.45, 0.8)]),
    S("And the metal points on top are often *lightning rods*, invented by *Benjamin Franklin* in the 1750s,",
      "Tepedeki metal uçlar da çoğu zaman *paratoner*; *Benjamin Franklin* tarafından 1750'lerde icat edildi",
      [E("spire", 0.4, 0.95, 0.7, bolt=True, rod=True), T(0.8, 0.4, "Franklin · 1750s", 1.2, "blue")]),
    S("to carry lightning safely into the ground, not to pull free energy out of the sky.",
      "ve yıldırımı güvenle toprağa iletmek içindi, gökyüzünden bedava enerji çekmek için değil.",
      [E("spire", 0.4, 0.95, 0.7, bolt=True, rod=True), A(0.6, 0.85, 0.6, 0.97, bend=0.0, color="red"), T(0.82, 0.4, "into the ground", 1.1, "red")]),
    S("As for Tesla, his famous wireless power tower at *Wardenclyffe* was never finished.",
      "Tesla'ya gelince, *Wardenclyffe*'teki ünlü kablosuz enerji kulesi hiçbir zaman bitirilemedi.",
      [E("spire", 0.35, 0.95, 0.7, bolt=False), T(0.75, 0.42, "never finished", 1.3, "red")]),
    S("His investors pulled out, and the tower was demolished in 1917. A real story of ambition and failure, not a hidden grid.",
      "Yatırımcıları çekildi ve kule 1917'de yıkıldı. Gizli bir şebeke değil, gerçek bir hırs ve başarısızlık hikâyesi.",
      [E("money", 0.25, 0.6, 0.8, text="$"), A(0.35, 0.5, 0.15, 0.3, bend=0.0), E("spire", 0.65, 0.95, 0.6, bolt=False), E("cross", 0.65, 0.6, 0.8, at=1.2), T(0.85, 0.2, "1917", 1.2, "red")]),
    S("And the orphan trains are among the best-documented chapters of American social history.",
      "Yetim trenleri de Amerikan sosyal tarihinin en iyi belgelenmiş bölümlerinden biri.",
      [E("train", 0.45, 0.7, 0.8), E("books", 0.88, 0.72, 0.5, n=3)]),
    S("The children had names, birth records and families. Many told their own stories as adults, and historians have collected their letters and interviews.",
      "Çocukların isimleri, doğum kayıtları ve aileleri vardı. Birçoğu yetişkin olunca kendi hikâyesini anlattı; tarihçiler mektuplarını ve röportajlarını derledi.",
      [E("letter", 0.25, 0.45, 0.8, text="name · birth · family"), E("letter", 0.72, 0.45, 0.8, text="\"my story\"")]),
    S("The real story is about poverty and a controversial child welfare system, not a secret reset of humanity.",
      "Gerçek hikâye yoksulluk ve tartışmalı bir çocuk refahı sistemiyle ilgili, insanlığın gizlice sıfırlanmasıyla değil.",
      [E("pinboard", 0.45, 0.5, 1.0, n=6), E("cross", 0.45, 0.5, 1.4, at=1.2)]),
    # ============================================================ 3. PERDE
    S("So why does Tartaria feel so convincing?", "Peki Tartarya neden bu kadar inandırıcı geliyor?", [E("head", 0.4, 0.5, 0.7), T(0.78, 0.42, "why?", 1.8, "red")]),
    S("Psychologist *Karen Douglas* and her colleagues suggest conspiracy theories meet three needs:",
      "Psikolog *Karen Douglas* ve meslektaşları, komplo teorilerinin üç ihtiyacı karşıladığını öne sürüyor:",
      [T(0.5, 0.35, "3 needs", 2.0, underline="red"), T(0.5, 0.6, "Douglas et al. · 2017", 1.0, "blue")]),
    S("to *understand* a confusing world, to feel *safe and in control*, and to feel *special*, to know something others don't.",
      "kafa karıştırıcı bir dünyayı *anlamak*, kendini *güvende ve kontrol sahibi* hissetmek ve kendini *özel* hissetmek, yani başkalarının bilmediği bir şeyi bilmek.",
      [T(0.2, 0.42, "understand", 1.3, "blue"), T(0.5, 0.42, "safe", 1.3, "blue"), T(0.8, 0.42, "special", 1.3, "red")]),
    S("There's also *proportionality bias*: we feel that something magnificent must have a magnificent cause.",
      "Bir de *orantılılık yanlılığı* var: Muhteşem bir şeyin muhteşem bir sebebi olması gerektiğini hissederiz.",
      [E("balance", 0.5, 0.45, 0.9, tilt=0.6, left="big", right="small"), T(0.5, 0.92, "proportionality bias", 1.2, "red")]),
    S("Ordinary workers with ordinary tools feel like too small an answer.", "Sıradan aletlerle çalışan sıradan işçiler fazla küçük bir cevap gibi gelir.",
      [E("palace", 0.35, 0.85, 0.7), G(0.85), F(0.82, 0.25, "hold", -1, y=0.85)]),
    S("But notice what the theory quietly does: it takes the real achievements of real people, architects, stonemasons, laborers,",
      "Ama teorinin sessizce ne yaptığına dikkat et: Gerçek insanların, mimarların, taş ustalarının, işçilerin gerçek başarılarını alıp",
      [G(), F(0.2, 0.4, "hold"), F(0.32, 0.4, "hold"), F(0.44, 0.4, "hold"), E("palace", 0.75, 0.85, 0.5)]),
    S("and gives them to an empire that never existed.", "hiç var olmamış bir imparatorluğa veriyor.",
      [G(), F(0.25, 0.4, tone=0.4), E("palace", 0.6, 0.85, 0.5), A(0.7, 0.5, 0.85, 0.5, bend=0.0, color="red"), T(0.88, 0.35, "?", 2.0, "red")]),
    S("And here's the twist. The *real* lands of \"Tartary\" had a history more spectacular than any myth.",
      "Ve işte büyük dönemeç: \"Tartarya\"nın *gerçek* topraklarının tarihi her efsaneden daha görkemliydi.",
      [T(0.5, 0.42, "the real Tartary", 1.8, "blue", underline="blue")]),
    S("In the 1200s, the *Mongol Empire* became the largest contiguous land empire in history, from Korea to Eastern Europe.",
      "1200'lerde *Moğol İmparatorluğu*, Kore'den Doğu Avrupa'ya uzanarak tarihin en büyük bitişik kara imparatorluğu oldu.",
      [E("globe", 0.35, 0.5, 1.0), E("chariot", 0.75, 0.65, 0.6, color="red"), T(0.5, 0.08, "Mongol Empire · 1200s", 1.3, "red")]),
    S("After it, the *Golden Horde*, largely Turkic-speaking, ruled the western steppe for more than two centuries.",
      "Ardından büyük ölçüde Türkçe konuşan *Altın Orda*, batı bozkırına iki yüzyıldan uzun süre hükmetti.",
      [E("flag", 0.35, 0.85, 1.2, color=[210, 160, 50], text="ALTIN ORDA"), T(0.72, 0.15, "Golden Horde", 1.3, "gold")]),
    S("Its descendants include today's Tatars, Kazakhs and many others. And through these lands ran the *Silk Road*.",
      "Torunları arasında bugünün Tatarları, Kazakları ve daha birçok halk var. Bu topraklardan da *İpek Yolu* geçiyordu.",
      [E("line", 0.1, 0.6, x2=0.9, y2=0.55, color="gold", w=2.0), E("antelope", 0.35, 0.5, 0.4, horns=False), E("antelope", 0.55, 0.48, 0.4, horns=False), T(0.5, 0.12, "Silk Road", 1.4, "gold")]),
    S("A real giant empire existed. We just don't need to invent one.", "Gerçek bir dev imparatorluk vardı. Sadece bir tane uydurmamıza gerek yok.",
      [T(0.5, 0.35, "real · giant · documented", 1.3, "blue"), T(0.5, 0.58, "no invention needed", 1.3, "red", underline="red")]),
    # ------------------------------------------------------------ Kendin dene
    S("Next time you meet a \"hidden history,\" ask three questions.", "Bir dahaki sefere bir \"gizli tarih\"le karşılaştığında üç soru sor.",
      [T(0.12, 0.1, "try this", 1.0, "red", underline="red"), E("magnifier", 0.5, 0.45, 1.1)]),
    S("Is there a simpler explanation that's already written down?", "Zaten yazıya geçirilmiş daha basit bir açıklama var mı?",
      [T(0.12, 0.15, "1.", 1.5, "red"), E("books", 0.5, 0.7, 1.0, n=3)]),
    S("If this were true, what else would we expect to find, and do we find it?", "Bu doğru olsaydı başka neler bulmayı beklerdik ve bunları buluyor muyuz?",
      [T(0.12, 0.15, "2.", 1.5, "red"), E("letter", 0.3, 0.5, 0.6), E("skull", 0.55, 0.5, 0.5, marks=False), E("spear", 0.8, 0.5, 0.4)]),
    S("And who gains if I believe it?", "Ve buna inanırsam kim kazanç sağlar?", [T(0.12, 0.15, "3.", 1.5, "red"), E("money", 0.4, 0.6, 0.9, text="$"), E("phone", 0.72, 0.45, 0.8)]),
    # ------------------------------------------------------------ Kapanış
    S("Tartaria is a story about a lost empire.", "Tartarya kayıp bir imparatorluğun hikâyesi.", [E("oldmap", 0.5, 0.5, 1.2, label="TARTARIA", faded=True)]),
    S("But maybe what's really lost is our trust that ordinary people, with simple tools and enormous effort, built extraordinary things.",
      "Ama belki gerçekten kaybolan şey, sıradan insanların basit aletler ve muazzam bir emekle olağanüstü şeyler inşa ettiğine olan inancımız.",
      [E("ladder", 0.3, 0.75, 1.0), F(0.3, 0.25, "climb", y=0.6), E("palace", 0.72, 0.85, 0.6)]),
    S("They did. We know their names.", "İnşa ettiler. İsimlerini biliyoruz.",
      [E("scroll", 0.5, 0.45, 1.0, text="names · plans · workers")]),
    S("The truth didn't erase a civilization. It *is* the civilization.", "Gerçek bir uygarlığı silmedi. Uygarlığın *ta kendisi* o.",
      [E("starfort", 0.5, 0.45, 0.8), G(0.88), F(0.3, 0.2, y=0.88), F(0.5, 0.2, y=0.88), F(0.7, 0.2, y=0.88)]),
]

subscribe = dict(after=7, sketch=[dict(el="subscribe", x=0.45, y=0.45, s=1.4), dict(el="arrow", x=0.2, y=0.75, x2=0.33, y2=0.55, color="red", s=1.2)],
                 say={"en": "If you love a good mystery, and finding out what's really behind it, *subscribe*. It genuinely helps the channel.",
                      "tr": "İyi bir gizemi ve arkasında gerçekte ne olduğunu bulmayı seviyorsan *abone ol*. Kanala gerçekten çok yardımı oluyor."})
meta = {"en": dict(title="Tartaria", description="", tags=[]), "tr": dict(title="Tartarya", description="", tags=[])}
out = dict(slug="tartarya", format="long", theme="karakalem", character="none", languages=["en"], subtitles=["tr"],
           voices={"en": "am_fenrir"}, speech_rate=0.88, meta=meta, subscribe=subscribe, scenes=scenes)
json.dump(out, open(os.path.join(HERE, "tartarya.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
words = sum(len(s["say"]["en"].split()) for s in scenes) + len(subscribe["say"]["en"].split())
print(f"{len(scenes)} sahne, {words} kelime")
