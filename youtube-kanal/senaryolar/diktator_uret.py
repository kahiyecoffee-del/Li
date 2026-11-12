#!/usr/bin/env python3
"""Diktatörlük videosunun sahne sahne senaryosu.  Çalıştır: python3 senaryolar/diktator_uret.py -> senaryolar/diktator.json"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
IMGS = {}
p = os.path.join(HERE, "diktator_gorseller.json")
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
    IMG("boetie", "Montaigne and La Boétie · engraving",
        "In 1548, a young French law student named *Étienne de La Boétie* asked a question that still has no comfortable answer.",
        "1548'de *Étienne de La Boétie* adında genç bir Fransız hukuk öğrencisi, hâlâ rahat bir cevabı olmayan bir soru sordu.",
        [E("scroll", 0.35, 0.45, 1.0, text="1548"), T(0.75, 0.42, "La Boétie", 1.5, "blue")]),
    S("How is it, he wrote, that so many people, so many towns, so many nations, sometimes put up with a single ruler,",
      "Nasıl oluyor da, diye yazdı, bu kadar çok insan, bu kadar çok kasaba, bu kadar çok ulus bazen tek bir yöneticiye katlanıyor?",
      [E("throne", 0.5, 0.55, 0.6, empty=False), E("stands", 0.5, 0.98, 0.9)]),
    S("who has no power except the power they *give* him?", "Hem de onların ona *verdiği* güçten başka hiçbir gücü olmayan birine?",
      [E("throne", 0.5, 0.55, 0.6, empty=False), A(0.2, 0.85, 0.42, 0.45, bend=0.2, color="red"), A(0.8, 0.85, 0.58, 0.45, bend=-0.2, color="red"),
       T(0.5, 0.92, "the power they give", 1.2, "red")]),
    S("A tyrant has only two eyes, two hands and one body. He can't arrest a million people by himself.",
      "Bir tiranın yalnızca iki gözü, iki eli ve tek bir bedeni vardır. Bir milyon insanı tek başına tutuklayamaz.",
      [G(), F(0.25, 0.55), T(0.65, 0.3, "2 eyes · 2 hands", 1.3), T(0.65, 0.5, "1 body", 1.3, "red")]),
    S("He needs police, soldiers, clerks, and the quiet obedience of everyone else.",
      "Polise, askerlere, memurlara ve geri kalan herkesin sessiz itaatine ihtiyacı vardır.",
      [E("throne", 0.5, 0.45, 0.5, empty=False), G(0.92), F(0.2, 0.3, y=0.92), F(0.35, 0.3, y=0.92), F(0.5, 0.3, y=0.92), F(0.65, 0.3, y=0.92), F(0.8, 0.3, y=0.92)]),
    S("So why do we give it?", "Peki biz bunu neden veriyoruz?", [T(0.5, 0.42, "Why do we give it?", 2.0, "red", underline="red")]),
    S("This isn't a question about one country or one century. It's a question about *human nature*.",
      "Bu bir ülkeyle ya da bir yüzyılla ilgili bir soru değil. *İnsan doğasıyla* ilgili bir soru.",
      [E("globe", 0.3, 0.5, 0.9), A(0.45, 0.5, 0.58, 0.5, bend=0.0), E("head", 0.72, 0.5, 0.6)]),
    S("And psychology, history and philosophy have some uncomfortable answers.", "Ve psikolojinin, tarihin ve felsefenin bazı rahatsız edici cevapları var.",
      [T(0.2, 0.42, "psychology", 1.2, "blue"), T(0.5, 0.42, "history", 1.2, "blue"), T(0.8, 0.42, "philosophy", 1.2, "blue")]),
    # ------------------------------------------------------------ Roma
    S("The word *dictator* didn't start as an insult.", "*Diktatör* kelimesi bir hakaret olarak başlamadı.", [T(0.5, 0.42, "dictator", 2.4, underline="red")]),
    IMG("senate", "The Roman Senate · Cesare Maccari (1888)",
        "In the Roman Republic, a *dictator* was an emergency office.", "Roma Cumhuriyeti'nde *diktatör* bir olağanüstü hâl makamıydı.",
        [E("palace", 0.5, 0.85, 1.0), T(0.5, 0.1, "Roman Republic", 1.4, "blue")]),
    S("In a crisis, like a war, the Senate could appoint one person with extraordinary powers,", "Savaş gibi bir krizde Senato bir kişiyi olağanüstü yetkilerle atayabilirdi;",
      [E("sword", 0.25, 0.55, 1.0), G(), F(0.6, 0.6), E("halo", 0.6, 0.2, 0.5)]),
    S("but only for a maximum of *six months*.", "ama en fazla *altı aylığına*.",
      [E("hourglass", 0.4, 0.45, 1.2), T(0.75, 0.42, "6 months", 1.8, "red", underline="red")]),
    IMG("cincinnatus", "Cincinnatus leaves the plough · J. A. Ribera (c. 1806)",
        "The legend of *Cincinnatus* says he was called from his farm to save Rome, won the war,",
        "*Cincinnatus* efsanesine göre çiftliğinden Roma'yı kurtarmaya çağrıldı, savaşı kazandı",
        [E("plow", 0.45, 0.7, 1.0), F(0.25, 0.4, "hold", y=0.75)]),
    S("and gave his power back within days, then went home to plow his fields.", "ve birkaç gün içinde gücünü geri verip tarlasını sürmeye döndü.",
      [E("sword", 0.2, 0.55, 0.8), A(0.3, 0.45, 0.48, 0.45, bend=0.0), E("plow", 0.72, 0.7, 0.9)]),
    S("For centuries, the system worked.", "Yüzyıllar boyunca sistem işledi.", [E("balance", 0.5, 0.45, 0.9), T(0.5, 0.92, "centuries", 1.2, "blue")]),
    S("Then, in the first century BC, generals began to stretch the rules.", "Sonra MÖ birinci yüzyılda generaller kuralları esnetmeye başladı.",
      [E("hourglass", 0.35, 0.45, 1.0), A(0.5, 0.45, 0.75, 0.45, bend=-0.3, color="red"), T(0.82, 0.3, "6 months... ?", 1.1, "red")]),
    IMG("caesar", "Julius Caesar · Tusculum portrait",
        "In 44 BC, *Julius Caesar* was named *dictator for life*.", "MÖ 44'te *Jül Sezar* *ömür boyu diktatör* ilan edildi.",
        [E("throne", 0.4, 0.85, 0.8, empty=False), T(0.78, 0.4, "for life", 1.5, "red")]),
    S("A month later, he was assassinated, but the Republic never truly recovered.", "Bir ay sonra suikaste kurban gitti, ama Cumhuriyet bir daha asla tam olarak toparlanamadı.",
      [E("throne", 0.4, 0.85, 0.8), E("sword", 0.75, 0.6, 1.0), T(0.5, 0.08, "44 BC", 1.3, "red")]),
    S("The lesson Rome learned too late: emergency powers have a way of becoming permanent.",
      "Roma'nın çok geç öğrendiği ders: Olağanüstü yetkilerin kalıcı hale gelmek gibi bir huyu vardır.",
      [T(0.5, 0.35, "emergency", 1.5, "blue"), A(0.5, 0.45, 0.5, 0.58, bend=0.0), T(0.5, 0.68, "permanent", 1.6, "red", underline="red")]),
    # ------------------------------------------------------------ Fromm & Hobbes
    S("Why would people *want* to give power away?", "İnsanlar gücü neden *vermek isteyebilir* ki?", [G(), F(0.3, 0.5, "hold"), E("throne", 0.75, 0.85, 0.6)]),
    S("In 1941, in the middle of the Second World War, the psychologist and philosopher *Erich Fromm* published a book called *Escape from Freedom*.",
      "1941'de, İkinci Dünya Savaşı'nın ortasında, psikolog ve filozof *Erich Fromm* *Özgürlükten Kaçış* adlı bir kitap yayımladı.",
      [E("books", 0.3, 0.72, 1.0, n=1), T(0.68, 0.4, "Escape from Freedom", 1.3, "red"), T(0.68, 0.6, "Fromm · 1941", 1.1, "blue")]),
    S("His idea was surprising: freedom isn't only a gift. It's also a *burden*.", "Fikri şaşırtıcıydı: Özgürlük sadece bir armağan değil. Aynı zamanda bir *yük*.",
      [E("sack", 0.5, 0.9, 1.0, label="freedom")]),
    S("When you're free, you have to choose, take responsibility, and live with uncertainty.",
      "Özgür olduğunda seçmen, sorumluluk alman ve belirsizlikle yaşaman gerekir.",
      [T(0.5, 0.25, "choose", 1.3), T(0.5, 0.45, "responsibility", 1.3), T(0.5, 0.65, "uncertainty", 1.3, "red")]),
    S("In times of crisis, unemployment and fear, that burden can feel unbearable.", "Kriz, işsizlik ve korku zamanlarında bu yük dayanılmaz hissettirebilir.",
      [E("sack", 0.5, 0.9, 1.3, label="freedom"), E("graph", 0.85, 0.35, 0.35, up=False)]),
    S("And a strong leader offers an escape: *don't worry, I'll decide for you.*", "Güçlü bir lider de bir kaçış yolu sunar: *Merak etme, senin yerine ben karar veririm.*",
      [E("throne", 0.3, 0.85, 0.7, empty=False), B(0.68, 0.3, 1.1, tail=[0.4, 0.45]), T(0.68, 0.3, "I'll decide\nfor you", 0.9)]),
    IMG("leviathan", "Leviathan · frontispiece by Abraham Bosse (1651)",
        "Centuries earlier, the philosopher *Thomas Hobbes* had argued something similar in *Leviathan*:",
        "Yüzyıllar önce filozof *Thomas Hobbes* da *Leviathan*'da benzer bir şey savunmuştu:",
        [E("books", 0.3, 0.72, 1.0, n=1), T(0.7, 0.42, "Leviathan · 1651", 1.4, "blue")]),
    S("people accept an all-powerful ruler because, without one, life would be \"nasty, brutish, and short.\"",
      "İnsanlar her şeye kadir bir yöneticiyi kabul eder, çünkü o olmadan hayat \"kötü, vahşi ve kısa\" olurdu.",
      [T(0.5, 0.42, "\"nasty, brutish, and short\"", 1.4, "red")]),
    S("Security, in exchange for freedom.", "Özgürlük karşılığında güvenlik.", [E("balance", 0.5, 0.45, 0.9, tilt=0.4, left="safety", right="freedom")]),
    S("It's a deal that looks reasonable when you're afraid. The problem is what happens after the fear passes.",
      "Korktuğunda makul görünen bir anlaşma. Sorun, korku geçtikten sonra ne olduğu.",
      [E("letter", 0.35, 0.45, 0.9, text="the deal"), T(0.75, 0.42, "and after?", 1.3, "red")]),
    # ------------------------------------------------------------ Stenner
    S("Political psychologist *Karen Stenner* found something important about how this works.",
      "Siyaset psikoloğu *Karen Stenner* bunun nasıl işlediğine dair önemli bir şey buldu.",
      [E("books", 0.3, 0.72, 1.0, n=1), T(0.7, 0.42, "Stenner · 2005", 1.4, "blue")]),
    S("She argued that some people have an *authoritarian predisposition*: a stronger preference for sameness, order and obedience.",
      "Bazı insanların *otoriter bir yatkınlığı* olduğunu öne sürdü: aynılığa, düzene ve itaate daha güçlü bir tercih.",
      [T(0.5, 0.25, "authoritarian predisposition", 1.3, underline="red"), T(0.5, 0.5, "sameness · order · obedience", 1.2, "blue")]),
    S("But here's the key: this tendency often lies *dormant*.", "Ama asıl önemli nokta şu: Bu eğilim çoğu zaman *uykudadır*.",
      [E("bed", 0.45, 0.8, 1.1), F(0.45, 0.2, "lie", y=0.7), T(0.78, 0.3, "Zzz", 1.4, "blue")]),
    S("What activates it is a feeling of *threat*, especially the sense that society is falling apart, or that \"our\" way of life is under attack.",
      "Onu uyandıran şey bir *tehdit* hissidir; özellikle toplumun dağıldığı ya da \"bizim\" yaşam tarzımızın saldırı altında olduğu duygusu.",
      [E("warning", 0.3, 0.42, 0.9), A(0.45, 0.45, 0.58, 0.45, bend=0.0), G(), F(0.75, 0.5, "hold")]),
    S("When people feel threatened, they become more willing to accept strong leaders, harsh rules and limits on others' freedom.",
      "İnsanlar tehdit altında hissettiğinde güçlü liderleri, sert kuralları ve başkalarının özgürlüğüne getirilen sınırları kabul etmeye daha istekli hale gelir.",
      [E("warning", 0.2, 0.4, 0.6), E("throne", 0.5, 0.85, 0.6, empty=False), E("padlock", 0.82, 0.45, 0.8)]),
    S("That's why would-be authoritarians so often need an *enemy*: a crisis, a scapegoat, a danger that only they can stop.",
      "Bu yüzden otoriter olmaya heveslenenler çoğu zaman bir *düşmana* ihtiyaç duyar: bir kriz, bir günah keçisi, sadece onların durdurabileceği bir tehlike.",
      [G(), F(0.25, 0.5, "point"), F(0.75, 0.5, tone=0.4, face=-1), T(0.75, 0.15, "the enemy", 1.3, "red")]),
    S("Fear isn't just a side effect of authoritarianism. Often, it's the fuel.", "Korku otoriterliğin sadece bir yan etkisi değil. Çoğu zaman yakıtıdır.",
      [E("campfire", 0.5, 0.75, 1.5), T(0.5, 0.15, "fear = fuel", 1.6, "red", underline="red")]),
    # ------------------------------------------------------------ Tekrar
    S("Fear opens the door. *Repetition* keeps it open.", "Korku kapıyı açar. *Tekrar* onu açık tutar.",
      [E("door", 0.35, 0.8, 1.0, open_=True), T(0.75, 0.42, "repetition", 1.5, "red")]),
    S("In 1977, psychologists *Lynn Hasher*, *David Goldstein* and *Thomas Toppino* asked people to rate whether statements were true or false.",
      "1977'de psikologlar *Lynn Hasher*, *David Goldstein* ve *Thomas Toppino*, insanlardan bazı ifadelerin doğru mu yanlış mı olduğunu değerlendirmelerini istedi.",
      [E("letter", 0.35, 0.45, 1.0, text="true or false?"), T(0.75, 0.42, "1977", 1.6, "blue")]),
    S("Some statements appeared more than once over several weeks.", "Bazı ifadeler birkaç hafta boyunca birden fazla kez karşılarına çıktı.",
      [E("calendar", 0.25, 0.45, 0.7, text="week 1"), E("calendar", 0.5, 0.45, 0.7, text="week 2"), E("calendar", 0.75, 0.45, 0.7, text="week 3")]),
    S("The result: people rated *repeated* statements as more likely to be true, whether they were actually true or not.",
      "Sonuç: İnsanlar *tekrarlanan* ifadeleri, gerçekte doğru olsun ya da olmasın, daha büyük ihtimalle doğru diye değerlendirdi.",
      [E("graph", 0.45, 0.5, 1.0), T(0.5, 0.1, "repeated = \"true\"", 1.4, "red")]),
    S("Psychologists call this the *illusory truth effect*. A familiar claim feels easier to process, and our brains mistake \"easy\" for \"true.\"",
      "Psikologlar buna *yanıltıcı doğruluk etkisi* diyor. Tanıdık bir iddiayı işlemek daha kolay gelir ve beynimiz \"kolay\"ı \"doğru\" sanır.",
      [T(0.5, 0.3, "illusory truth effect", 1.5, underline="red"), E("brain", 0.3, 0.7, 0.5), T(0.68, 0.7, "easy = true?", 1.2, "red")]),
    S("Every authoritarian regime has understood this instinctively. Control the newspapers, the radio, the screens,",
      "Her otoriter rejim bunu içgüdüsel olarak anlamıştır. Gazeteleri, radyoyu, ekranları kontrol et,",
      [E("newspaper", 0.2, 0.45, 0.5), E("radio", 0.5, 0.5, 0.6), E("tv", 0.82, 0.45, 0.5)]),
    S("repeat the same few messages everywhere, and over time they stop feeling like opinions. They start feeling like reality.",
      "aynı birkaç mesajı her yerde tekrarla; zamanla bunlar fikir gibi gelmeyi bırakır. Gerçeklik gibi gelmeye başlar.",
      [E("radio", 0.25, 0.5, 0.5, text="X"), E("tv", 0.55, 0.45, 0.4, text="X"), E("newspaper", 0.82, 0.45, 0.4, head="X"), T(0.5, 0.88, "opinion = reality?", 1.3, "red")]),
    # ------------------------------------------------------------ Milgram
    S("But dictators don't just need followers. They need *ordinary people* willing to carry out orders.",
      "Ama diktatörlerin sadece takipçiye ihtiyacı yok. Emirleri uygulamaya istekli *sıradan insanlara* ihtiyaçları var.",
      [G(), F(0.2, 0.4), F(0.35, 0.4), F(0.5, 0.4), F(0.65, 0.4), F(0.8, 0.4), T(0.5, 0.12, "ordinary people", 1.4, "blue")]),
    IMG("milgram", "Milgram experiment · recruitment ad (1961)",
        "In 1961, at Yale University, psychologist *Stanley Milgram* ran one of the most famous experiments in history.",
        "1961'de Yale Üniversitesi'nde psikolog *Stanley Milgram* tarihin en ünlü deneylerinden birini yaptı.",
        [E("shockbox", 0.5, 0.5, 1.0, level=0.0), T(0.5, 0.1, "Milgram · 1961", 1.4, "blue")]),
    S("Volunteers were told to give electric shocks to a \"learner\" in another room whenever he made a mistake, increasing the voltage each time.",
      "Gönüllülere, başka bir odadaki \"öğrenci\" her hata yaptığında ona elektrik şoku vermeleri ve voltajı her seferinde artırmaları söylendi.",
      [E("shockbox", 0.35, 0.5, 0.7, level=0.3), E("line", 0.62, 0.15, x2=0.62, y2=0.85, w=1.5), F(0.82, 0.4, "sit", -1, y=0.75)]),
    S("The shocks were fake, and the learner was an actor. But the volunteers didn't know that.",
      "Şoklar sahteydi, öğrenci de bir aktördü. Ama gönüllüler bunu bilmiyordu.",
      [E("mask", 0.3, 0.45, 1.0), T(0.72, 0.35, "fake shocks", 1.2, "blue"), T(0.72, 0.55, "an actor", 1.2, "blue")]),
    S("They heard him shout, complain about his heart, and then go silent.", "Onun bağırdığını, kalbinden şikâyet ettiğini ve sonra sustuğunu duydular.",
      [E("line", 0.5, 0.1, x2=0.5, y2=0.9, w=1.5), B(0.75, 0.3, 0.6), T(0.75, 0.3, "stop!", 1.0, "red"), E("heart", 0.75, 0.62, 0.5), E("ear", 0.25, 0.45, 1.5)]),
    S("In the best-known version, about *two-thirds* of participants kept going all the way to the maximum: 450 volts.",
      "En bilinen versiyonda katılımcıların yaklaşık *üçte ikisi* sonuna kadar, en yüksek seviye olan 450 volta kadar devam etti.",
      [E("shockbox", 0.5, 0.42, 1.0, level=1.0), T(0.5, 0.82, "≈ 2/3 went to 450V", 1.4, "red", underline="red")]),
    S("Not because they were cruel, but because a calm man in a lab coat kept saying, *\"The experiment requires that you continue.\"*",
      "Zalim oldukları için değil; önlüklü sakin bir adam sürekli *\"Deney devam etmenizi gerektiriyor\"* dediği için.",
      [E("coat", 0.3, 0.5, 0.8), B(0.7, 0.3, 1.2, tail=[0.4, 0.3]), T(0.7, 0.3, "please\ncontinue", 1.0)]),
    S("Later researchers have questioned parts of Milgram's methods.", "Sonraki araştırmacılar Milgram'ın yöntemlerinin bazı kısımlarını sorguladı.",
      [E("magnifier", 0.35, 0.45, 1.0), E("letter", 0.72, 0.45, 0.8, text="methods?")]),
    S("But the core finding has been repeated in many forms: ordinary people will do surprising things when an authority takes responsibility for them.",
      "Ama temel bulgu pek çok biçimde tekrarlandı: Bir otorite sorumluluğu üstlendiğinde sıradan insanlar şaşırtıcı şeyler yapabilir.",
      [E("coat", 0.25, 0.5, 0.6), A(0.38, 0.45, 0.55, 0.45, bend=0.0), G(), F(0.72, 0.5), T(0.72, 0.12, "\"not my responsibility\"", 1.0, "red")]),
    # ------------------------------------------------------------ Yavaş yavaş
    S("Here's what surprises most people: many dictatorships don't begin with tanks in the street.",
      "İnsanların çoğunu şaşırtan şey şu: Birçok diktatörlük sokaklarda tanklarla başlamaz.",
      [E("tank", 0.5, 0.55, 1.1), E("cross", 0.5, 0.5, 1.0, at=1.2)]),
    S("In January 1933, Adolf Hitler was legally appointed Chancellor of Germany.", "Ocak 1933'te Adolf Hitler yasal olarak Almanya Şansölyesi'ne atandı.",
      [E("scroll", 0.35, 0.45, 1.0, text="appointed"), T(0.75, 0.42, "January 1933", 1.4, "blue")]),
    S("Two months later, the parliament passed the *Enabling Act*, giving his government the power to make laws without parliament.",
      "İki ay sonra meclis, hükümetine meclis olmadan yasa yapma yetkisi veren *Yetki Yasası*'nı kabul etti.",
      [E("ballot", 0.3, 0.8, 1.0), T(0.7, 0.35, "Enabling Act", 1.4, "red"), T(0.7, 0.55, "March 1933", 1.1, "blue")]),
    S("It was voted through, under intimidation, but through a vote.", "Yıldırma altında ama bir oylamayla geçti.",
      [E("ballot", 0.4, 0.8, 1.0), E("warning", 0.75, 0.4, 0.6), T(0.5, 0.1, "a vote", 1.4, "red")]),
    S("In their 2018 book *How Democracies Die*, political scientists *Steven Levitsky* and *Daniel Ziblatt* argue that this is the common pattern today:",
      "Siyaset bilimciler *Steven Levitsky* ve *Daniel Ziblatt*, 2018'de yayımlanan *Demokrasiler Nasıl Ölür* kitabında bugün yaygın örüntünün bu olduğunu savunuyor:",
      [E("books", 0.3, 0.72, 1.0, n=1), T(0.68, 0.4, "How Democracies Die", 1.3, "red"), T(0.68, 0.6, "2018", 1.1, "blue")]),
    S("democracies are more often eroded step by step, by elected leaders, than overthrown in a single coup.",
      "Demokrasiler tek bir darbeyle devrilmekten çok, seçilmiş liderler tarafından adım adım aşındırılıyor.",
      [E("stairs", 0.12, 0.88, 1.5, n=4), T(0.5, 0.12, "step by step", 1.5, "red", underline="red")]),
    S("Each step looks small and legal on its own: a court packed here, a newspaper pressured there,",
      "Her adım tek başına küçük ve yasal görünür: burada mahkemeye yeni atamalar, orada baskı altına alınan bir gazete,",
      [E("balance", 0.3, 0.45, 0.7, tilt=0.5), E("newspaper", 0.75, 0.45, 0.6, head="NEWS"), E("padlock", 0.75, 0.75, 0.5)]),
    S("an election rule changed, an \"emergency\" extended.", "değiştirilen bir seçim kuralı, uzatılan bir \"olağanüstü hâl\".",
      [E("ballot", 0.3, 0.8, 0.8), E("hourglass", 0.72, 0.45, 0.9), T(0.72, 0.85, "extended", 1.1, "red")]),
    S("You may have heard that a frog in slowly heating water won't jump out.", "Yavaşça ısınan sudaki kurbağanın dışarı zıplamayacağını duymuşsundur.",
      [E("frog", 0.45, 0.8, 1.0, jump=False)]),
    S("In reality, frogs *do* jump out. It's people who are bad at noticing slow change.", "Gerçekte kurbağalar *zıplıyor*. Yavaş değişimi fark etmekte kötü olan insanlar.",
      [E("frog", 0.35, 0.8, 0.9, jump=True), T(0.78, 0.25, "frogs jump", 1.2, "blue"), T(0.78, 0.45, "people don't", 1.2, "red")]),
    # ------------------------------------------------------------ Tercih gizleme
    S("And once a dictatorship is in place, why do people stay quiet, even when most of them are unhappy?",
      "Peki bir diktatörlük kurulduktan sonra, çoğu mutsuz olsa bile insanlar neden sessiz kalıyor?",
      [G(0.95), F(0.2, 0.35, y=0.95), F(0.35, 0.35, y=0.95), F(0.5, 0.35, y=0.95), F(0.65, 0.35, y=0.95), F(0.8, 0.35, y=0.95), T(0.5, 0.15, "silence", 1.6, "blue")]),
    S("Economist *Timur Kuran* called it *preference falsification*: people hide what they really think, because speaking up is dangerous.",
      "Ekonomist *Timur Kuran* buna *tercih gizleme* dedi: İnsanlar gerçekte ne düşündüklerini saklar, çünkü konuşmak tehlikelidir.",
      [E("maskface", 0.3, 0.92, 0.9, thought="no"), T(0.72, 0.35, "preference", 1.2, "red"), T(0.72, 0.52, "falsification", 1.2, "red")]),
    S("And because everyone hides, everyone believes they're alone.", "Herkes sakladığı için de herkes yalnız olduğuna inanır.",
      [E("maskface", 0.2, 0.92, 0.6, thought="no"), E("maskface", 0.5, 0.92, 0.6, thought="no"), E("maskface", 0.8, 0.92, 0.6, thought="no")]),
    S("On December 21, 1989, Romania's dictator *Nicolae Ceaușescu* gave a speech to a huge crowd in Bucharest.",
      "21 Aralık 1989'da Romanya diktatörü *Nicolae Çavuşesku*, Bükreş'te devasa bir kalabalığa konuşma yaptı.",
      [E("palace", 0.5, 0.6, 0.7), E("stands", 0.5, 0.98, 1.0), T(0.5, 0.08, "Bucharest · Dec 21, 1989", 1.2, "blue")]),
    S("Partway through, some people began to boo. On live television, you can see his face freeze.",
      "Konuşmanın ortasında bazı insanlar yuhalamaya başladı. Canlı yayında yüzünün donduğunu görebilirsin.",
      [E("tv", 0.35, 0.45, 0.9, text="LIVE"), T(0.75, 0.3, "BOO", 1.8, "red"), T(0.82, 0.55, "boo", 1.2, "red")]),
    S("In that moment, thousands of people discovered that they weren't alone.", "O anda binlerce insan yalnız olmadığını keşfetti.",
      [T(0.2, 0.25, "BOO", 1.2, "red"), T(0.5, 0.2, "BOO", 1.5, "red"), T(0.8, 0.25, "BOO", 1.2, "red"), E("stands", 0.5, 0.95, 1.0)]),
    S("The very next day, he fled the capital by helicopter, and his regime collapsed.", "Hemen ertesi gün helikopterle başkentten kaçtı ve rejimi çöktü.",
      [E("heli", 0.6, 0.35, 0.9), E("throne", 0.3, 0.9, 0.6), T(0.75, 0.75, "Dec 22, 1989", 1.2, "blue")]),
    S("Dictatorships often look unbreakable right up until the moment they suddenly aren't.",
      "Diktatörlükler, aniden yıkılana kadar çoğu zaman yıkılmaz görünür.",
      [E("throne", 0.5, 0.85, 0.9, shaky=True), T(0.5, 0.1, "unbreakable... until", 1.4, "red")]),
    # ------------------------------------------------------------ La Boétie'nin cevabı
    S("Which brings us back to La Boétie's answer from 1548.", "Bu da bizi La Boétie'nin 1548'deki cevabına geri getiriyor.",
      [E("scroll", 0.5, 0.45, 1.1, text="1548")]),
    S("He argued that tyranny doesn't need to be defeated by force. It only needs to lose the cooperation it depends on.",
      "Tiranlığın zorla yenilmesi gerekmediğini savundu. Sadece dayandığı iş birliğini kaybetmesi yeterliydi.",
      [E("throne", 0.5, 0.5, 0.6), G(0.92), F(0.3, 0.3, "walk", -1, y=0.92), F(0.7, 0.3, "walk", 1, y=0.92), T(0.5, 0.08, "no cooperation", 1.3, "red")]),
    S("\"Resolve to serve no more,\" he wrote, \"and you are at once freed.\"", "\"Artık hizmet etmemeye karar verin,\" diye yazdı, \"ve anında özgür olursunuz.\"",
      [T(0.5, 0.35, "\"Resolve to serve no more,", 1.4, "blue"), T(0.5, 0.55, "and you are at once freed.\"", 1.4, "blue", underline="red")]),
    S("Modern research points in a similar direction.", "Modern araştırmalar da benzer bir yönü gösteriyor.", [E("magnifier", 0.5, 0.45, 1.1)]),
    S("Political scientist *Erica Chenoweth* studied hundreds of campaigns against governments in the twentieth century",
      "Siyaset bilimci *Erica Chenoweth*, yirminci yüzyılda hükümetlere karşı yürütülen yüzlerce kampanyayı inceledi",
      [E("books", 0.3, 0.72, 1.0, n=3), T(0.7, 0.42, "Chenoweth", 1.4, "blue")]),
    S("and found that nonviolent mass movements succeeded more often than violent ones, largely because they could draw in far more participants.",
      "ve şiddet içermeyen kitlesel hareketlerin şiddet içerenlerden daha sık başarılı olduğunu buldu; büyük ölçüde çok daha fazla insanı dahil edebildikleri için.",
      [G(0.9), F(0.15, 0.25, "hold", y=0.9), F(0.28, 0.25, "hold", y=0.9), F(0.41, 0.25, "hold", y=0.9), F(0.54, 0.25, "hold", y=0.9), F(0.67, 0.25, "hold", y=0.9),
       F(0.8, 0.25, "hold", y=0.9), T(0.5, 0.15, "nonviolent · many people", 1.3, "blue")]),
    S("Power, in the end, is a relationship. Every regime, however strong it looks, runs on the daily choices of ordinary people.",
      "Güç, sonunda bir ilişkidir. Ne kadar güçlü görünürse görünsün her rejim, sıradan insanların günlük seçimleriyle ayakta durur.",
      [E("throne", 0.5, 0.55, 0.6), E("line", 0.42, 0.62, x2=0.25, y2=0.88), E("line", 0.58, 0.62, x2=0.75, y2=0.88), G(0.92), F(0.25, 0.2, y=0.92), F(0.75, 0.2, y=0.92)]),
    # ------------------------------------------------------------ Kendin dene
    S("Try this. Think of a time you went along with something you didn't agree with, at school, at work, in a group, because everyone else seemed to.",
      "Şunu dene. Okulda, işte ya da bir grupta, herkes kabul ediyor gibi göründüğü için katılmadığın bir şeye uyduğun bir anı düşün.",
      [T(0.12, 0.1, "try this", 1.0, "red", underline="red"), E("table", 0.5, 0.72, 1.3), F(0.25, 0.4, "sit", y=0.75), F(0.75, 0.4, "sit", -1, y=0.75)]),
    S("Ask yourself: did I actually know what the others thought? Or did I just assume?",
      "Kendine sor: Diğerlerinin ne düşündüğünü gerçekten biliyor muydum? Yoksa sadece varsaydım mı?",
      [E("head", 0.35, 0.5, 0.6), T(0.75, 0.35, "know?", 1.4, "blue"), T(0.75, 0.55, "or assume?", 1.4, "red")]),
    S("Very often, the silence around you is made of people who feel exactly like you.", "Çoğu zaman etrafındaki sessizlik, tam olarak senin gibi hisseden insanlardan oluşur.",
      [E("maskface", 0.2, 0.92, 0.55, thought="me too"), E("maskface", 0.5, 0.92, 0.55, thought="me too"), E("maskface", 0.8, 0.92, 0.55, thought="me too")]),
    # ------------------------------------------------------------ Kapanış
    S("We don't let dictators rise because we're evil, or stupid.", "Diktatörlerin yükselmesine kötü ya da aptal olduğumuz için izin vermiyoruz.",
      [T(0.3, 0.42, "evil", 1.5), E("cross", 0.3, 0.42, 0.5, at=0.6), T(0.7, 0.42, "stupid", 1.5), E("cross", 0.7, 0.42, 0.5, at=1.0)]),
    S("We let them rise because we're afraid, because we're tired, because we trust authority, and because we think we're alone.",
      "Korktuğumuz için, yorgun olduğumuz için, otoriteye güvendiğimiz için ve yalnız olduğumuzu düşündüğümüz için izin veriyoruz.",
      [T(0.25, 0.3, "afraid", 1.3, "red"), T(0.75, 0.3, "tired", 1.3, "red"), T(0.25, 0.6, "trust authority", 1.2, "red"), T(0.75, 0.6, "alone", 1.3, "red")]),
    S("Those are human weaknesses. But they come with a human strength:", "Bunlar insani zayıflıklar. Ama beraberlerinde insani bir güç de getiriyorlar:",
      [E("heads", 0.5, 0.45, 1.0, n=3)]),
    S("the power was always ours to give, and ours to take back.", "Güç her zaman vermesi de geri alması da bize ait olan bir şeydi.",
      [E("throne", 0.5, 0.6, 0.45), G(0.92), F(0.15, 0.3, "hold", y=0.92), F(0.3, 0.3, "hold", y=0.92), F(0.7, 0.3, "hold", -1, y=0.92), F(0.85, 0.3, "hold", -1, y=0.92),
       T(0.5, 0.1, "ours to take back", 1.4, "blue", underline="blue")]),
]

subscribe = dict(after=8, sketch=[dict(el="subscribe", x=0.45, y=0.45, s=1.4), dict(el="arrow", x=0.2, y=0.75, x2=0.33, y2=0.55, color="red", s=1.2)],
                 say={"en": "If you like big questions about human nature, *subscribe*. It genuinely helps the channel.",
                      "tr": "İnsan doğasıyla ilgili büyük soruları seviyorsan *abone ol*. Kanala gerçekten çok yardımı oluyor."})
meta = {"en": dict(title="Why Do We Let Dictators Rise?", description="", tags=[]), "tr": dict(title="Diktatörlere Neden İzin Veriyoruz?", description="", tags=[])}
out = dict(slug="diktator", format="long", theme="karakalem", character="none", languages=["en"], subtitles=["tr"],
           voices={"en": "am_fenrir"}, speech_rate=0.88, meta=meta, subscribe=subscribe, scenes=scenes)
json.dump(out, open(os.path.join(HERE, "diktator.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
words = sum(len(s["say"]["en"].split()) for s in scenes) + len(subscribe["say"]["en"].split())
print(f"{len(scenes)} sahne, {words} kelime")
