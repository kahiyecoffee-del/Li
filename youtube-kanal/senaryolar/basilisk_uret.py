#!/usr/bin/env python3
"""Roko's Basilisk videosunun sahne sahne senaryosu.  Çalıştır: python3 senaryolar/basilisk_uret.py -> senaryolar/basilisk.json"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
IMGS = {}
p = os.path.join(HERE, "basilisk_gorseller.json")
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
    S("In July 2010, someone posted a short thought experiment on an online forum about rationality and artificial intelligence.",
      "Temmuz 2010'da biri rasyonellik ve yapay zekâ üzerine bir internet forumuna kısa bir düşünce deneyi yazdı.",
      [E("post", 0.5, 0.45, 1.3), T(0.5, 0.08, "July 2010", 1.0, "blue")]),
    S("Within hours, the forum's founder deleted it.", "Birkaç saat içinde forumun kurucusu yazıyı sildi.",
      [E("post", 0.5, 0.45, 1.3, deleted=True)]),
    S("Then he banned all discussion of it — for *five years*.", "Sonra konuyla ilgili her türlü tartışmayı yasakladı: *beş yıl* boyunca.",
      [E("lock", 0.5, 0.38, 1.5, text="5 years")]),
    S("Some readers said it gave them nightmares. A few said they regretted ever reading it.",
      "Bazı okurlar yazının onlara kâbus gördürdüğünü söyledi. Birkaçı okuduklarına pişman olduğunu.",
      [E("moon", 0.82, 0.15, 0.9), E("bed", 0.42, 0.82, 1.2), F(0.42, 0.42, "sitbed", y=0.72), T(0.62, 0.25, "!", 2.4, "red")]),
    S("The idea is now known as *Roko's Basilisk*.", "Bu fikir bugün *Roko'nun Basiliski* olarak biliniyor.",
      [E("basilisk", 0.45, 0.5, 1.6), T(0.5, 0.1, "Roko's Basilisk", 1.6, underline="red")]),
    S("And its most unsettling claim is this: that simply *knowing about it* might put you at risk.",
      "Ve en rahatsız edici iddiası şu: Sadece onu *bilmek* bile seni risk altına sokabilir.",
      [E("head", 0.35, 0.5, 0.65), E("warning", 0.72, 0.45, 1.0)]),
    S("Don't worry. By the end of this video, you'll understand exactly how it works — and why almost every philosopher who has looked at it closely thinks it falls apart.",
      "Merak etme. Bu videonun sonunda nasıl işlediğini ve ona yakından bakan neredeyse her filozofun neden çöktüğünü düşündüğünü tam olarak anlayacaksın.",
      [E("basilisk", 0.45, 0.5, 1.4, toothless=True), E("magnifier", 0.75, 0.35, 0.8)]),
    S("But along the way, you'll also learn something strange about your own mind: why some ideas, once heard, are almost impossible to forget.",
      "Ama yol boyunca kendi zihnin hakkında da tuhaf bir şey öğreneceksin: Bazı fikirler bir kez duyulduktan sonra neden unutulması neredeyse imkânsız hale gelir.",
      [E("head", 0.35, 0.5, 0.65), B(0.68, 0.3, 0.9, "thought", tail=[0.42, 0.35]), E("bear", 0.63, 0.32, 0.4)]),
    # ------------------------------------------------------------ Efsane
    S("First, the name.", "Önce isim.", [T(0.5, 0.42, "basilisk", 2.2, underline="red")]),
    IMG("basilisk", "the basilisk · Renaissance woodcut",
        "In the first century, the Roman writer *Pliny the Elder* described a small serpent called the *basilisk* — the \"little king.\"",
        "Birinci yüzyılda Romalı yazar *Yaşlı Plinius*, *basilisk*, yani \"küçük kral\" denen küçük bir yılandan söz etti.",
        [E("basilisk", 0.45, 0.5, 1.6), T(0.5, 0.1, "Pliny the Elder · 1st c.", 1.0, "blue")]),
    S("According to legend, its gaze alone could kill. You didn't have to touch it. You just had to *see* it.",
      "Efsaneye göre yalnızca bakışı bile öldürebilirdi. Ona dokunman gerekmiyordu. Sadece onu *görmen* yeterliydi.",
      [E("basilisk", 0.3, 0.45, 1.0), A(0.48, 0.42, 0.7, 0.5, color="red", bend=0.0), G(), F(0.8, 0.45, "lie", -1, y=0.8)]),
    S("Over the centuries, the basilisk became a symbol for something strange: a danger that reaches you through *information*. Through looking.",
      "Yüzyıllar içinde basilisk tuhaf bir şeyin sembolü haline geldi: sana *bilgi* yoluyla, bakarak ulaşan bir tehlike.",
      [E("eye", 0.35, 0.45, 1.1), A(0.5, 0.45, 0.65, 0.45, bend=0.0), E("warning", 0.78, 0.45, 0.8)]),
    S("In 1988, science fiction writer *David Langford* published a story called *\"BLIT,\"* about images that crash the human brain like a virus — he called them basilisks too.",
      "1988'de bilimkurgu yazarı *David Langford*, insan beynini bir virüs gibi çökerten görüntüler hakkında *\"BLIT\"* adlı bir öykü yayımladı ve onlara da basilisk adını verdi.",
      [E("screen", 0.3, 0.6, 1.0), A(0.45, 0.45, 0.6, 0.45, bend=0.0, color="red"), E("brain", 0.75, 0.45, 0.8, spot=[0, -0.2]), T(0.5, 0.08, "BLIT · 1988", 1.0, "blue")]),
    S("So when an idea appeared online that was supposedly harmful just to *know*, the name was waiting for it.",
      "Yani bilmesi bile zararlı olduğu söylenen bir fikir internette ortaya çıktığında, ismi onu bekliyordu.",
      [E("post", 0.5, 0.45, 1.1), T(0.5, 0.88, "a basilisk", 1.0, "red")]),
    # ------------------------------------------------------------ Fikir
    S("Here's the idea, step by step.", "Fikir adım adım şöyle.", [T(0.5, 0.42, "step by step", 1.6, underline="red")]),
    S("Imagine that, sometime in the future, humanity creates a *superintelligent AI* — a machine vastly smarter than any human.",
      "Gelecekte bir gün insanlığın *süper zeki bir yapay zekâ* yarattığını hayal et: herhangi bir insandan çok daha zeki bir makine.",
      [E("ai", 0.5, 0.45, 1.3), T(0.5, 0.88, "superintelligence", 1.0, "blue")]),
    S("And imagine it's designed to do as much good as possible: curing diseases, ending poverty, saving millions of lives.",
      "Ve mümkün olduğunca çok iyilik yapmak üzere tasarlandığını düşün: hastalıkları iyileştiren, yoksulluğu bitiren, milyonlarca hayat kurtaran.",
      [E("ai", 0.3, 0.45, 0.9), E("heart", 0.65, 0.3, 0.6), T(0.7, 0.55, "cures", 0.9, "blue"), T(0.7, 0.7, "saves lives", 0.9, "blue")]),
    S("Every day it doesn't exist yet, people suffer who it could have saved. So, from its point of view, the sooner it's built, the better.",
      "Henüz var olmadığı her gün, kurtarabileceği insanlar acı çekiyor. Yani onun açısından ne kadar erken inşa edilirse o kadar iyi.",
      [E("timeline", 0.5, 0.7, 1.0), E("ai", 0.85, 0.35, 0.6), T(0.4, 0.35, "sooner = better", 1.2, "red")]),
    S("Now comes the dark twist.", "Şimdi karanlık dönemece geliyoruz.", [E("basilisk", 0.45, 0.5, 1.5)]),
    S("What if this AI decided to *encourage* its own creation — by punishing anyone in the past who knew it might exist, but didn't help bring it about?",
      "Ya bu yapay zekâ kendi yaratılmasını *teşvik etmeye* karar verirse? Geçmişte onun var olabileceğini bilen ama ortaya çıkmasına yardım etmeyen herkesi cezalandırarak.",
      [E("timeline", 0.5, 0.75, 1.0), E("ai", 0.85, 0.35, 0.6), A(0.75, 0.4, 0.3, 0.5, color="red", bend=0.3), F(0.22, 0.3, y=0.7)]),
    S("It couldn't reach you in the past, of course. But perhaps it could create a perfect *simulation* of you — and punish that.",
      "Elbette sana geçmişte ulaşamazdı. Ama belki senin kusursuz bir *simülasyonunu* yaratıp onu cezalandırabilirdi.",
      [E("screen", 0.5, 0.62, 1.6), F(0.5, 0.2, y=0.55), T(0.5, 0.1, "a simulation of you", 1.1, "red")]),
    S("And here's the trap: the threat only applies to people who *knew* about the idea. Before this video, you were safe.",
      "Ve tuzak şu: Tehdit yalnızca fikirden *haberdar olan* insanlar için geçerli. Bu videodan önce güvendeydin.",
      [G(), F(0.5, 0.5), T(0.5, 0.12, "now you know", 1.3, "red", underline="red")]),
    S("That's why it's called a basilisk. Looking at it is what makes it dangerous.",
      "Bu yüzden adı basilisk. Ona bakmak onu tehlikeli yapan şeyin ta kendisi.",
      [E("basilisk", 0.4, 0.5, 1.3), E("eye", 0.82, 0.45, 0.6)]),
    # ------------------------------------------------------------ Kopya
    S("But wait. Even if a future AI punished a simulation of you... would that actually be *you*?",
      "Ama bekle. Gelecekteki bir yapay zekâ senin bir simülasyonunu cezalandırsa bile… bu gerçekten *sen* olur muydu?",
      [G(), F(0.35, 0.5), E("screen", 0.72, 0.55, 0.9), F(0.72, 0.15, y=0.5), T(0.5, 0.12, "you?", 1.4, "red")]),
    S("This is one of philosophy's oldest puzzles: *personal identity*. What makes you the same person over time?",
      "Bu, felsefenin en eski bulmacalarından biri: *kişisel kimlik*. Seni zaman içinde aynı kişi yapan nedir?",
      [T(0.5, 0.35, "personal identity", 1.6, underline="red"), G(), F(0.3, 0.25, child=True), F(0.5, 0.35), F(0.7, 0.35, "think", hat="wig")]),
    S("If a perfect copy of you were created tomorrow, with all your memories, it would *feel* like you. It would insist it's you.",
      "Yarın tüm anılarına sahip kusursuz bir kopyan yaratılsa, o kopya *kendini* sen gibi hissederdi. Sen olduğunda ısrar ederdi.",
      [G(), F(0.38, 0.5), F(0.62, 0.5, face=-1, tone=0.6), B(0.68, 0.2, 0.5, tail=[0.63, 0.3]), T(0.68, 0.2, "I'm you!", 0.8)]),
    S("But you'd still be here, reading this. Two people. Which one is \"you\"?", "Ama sen hâlâ burada, bunu okuyor olurdun. İki kişi. Hangisi \"sen\"?",
      [G(), F(0.38, 0.5), F(0.62, 0.5, face=-1, tone=0.6), T(0.38, 0.2, "me?", 1.0), T(0.62, 0.2, "me?", 1.0, "red")]),
    S("Many philosophers argue that a copy isn't you — it's someone *new* who happens to share your past.",
      "Birçok filozof kopyanın sen olmadığını savunuyor: Geçmişini paylaşan *yeni* biri.",
      [G(), F(0.38, 0.5), F(0.62, 0.5, face=-1, tone=0.6), T(0.62, 0.15, "someone new", 1.0, "blue", underline="blue")]),
    S("If that's right, the basilisk's threat has a gap: it could hurt someone who resembles you. Just not *you*.",
      "Bu doğruysa basiliskin tehdidinde bir boşluk var: Sana benzeyen birine zarar verebilir. Ama *sana* değil.",
      [E("basilisk", 0.3, 0.5, 0.9), T(0.75, 0.42, "not you", 1.5, "blue", underline="red")]),
    S("That would still be a cruel thing to do. But it's not quite the personal threat the basilisk promises.",
      "Bu yine de zalimce bir şey olurdu. Ama basiliskin vaat ettiği kişisel tehdit tam olarak bu değil.",
      [E("basilisk", 0.45, 0.5, 1.2), E("circle", 0.45, 0.5, 1.0, rx=520, ry=200, color="ink")]),
    # ------------------------------------------------------------ Yasak, Streisand
    S("Back to 2010. The forum was called *LessWrong*, and its founder was *Eliezer Yudkowsky*, a writer and AI researcher.",
      "2010'a dönelim. Forumun adı *LessWrong*'du, kurucusu ise yazar ve yapay zekâ araştırmacısı *Eliezer Yudkowsky*.",
      [E("post", 0.5, 0.45, 1.2, title="LessWrong · 2010")]),
    S("He deleted the post and banned the topic.", "Yazıyı sildi ve konuyu yasakladı.",
      [E("post", 0.38, 0.45, 1.0, deleted=True), E("lock", 0.8, 0.35, 0.9)]),
    S("He later said he did it not because he believed the basilisk would actually work, but because he thought posting ideas designed to frighten people was harmful —",
      "Daha sonra bunu basiliskin gerçekten işe yarayacağına inandığı için değil, insanları korkutmak üzere tasarlanmış fikirleri paylaşmanın zararlı olduğunu düşündüğü için yaptığını söyledi.",
      [T(0.5, 0.3, "\"it won't work\"", 1.2, "blue"), T(0.5, 0.52, "\"but don't spread fear\"", 1.2, "red")]),
    S("and that even entertaining that kind of reasoning was a bad idea.", "Ve bu tür bir akıl yürütmeyi ciddiye almanın bile kötü bir fikir olduğunu.",
      [E("head", 0.4, 0.5, 0.65), E("cross", 0.4, 0.45, 1.0, at=1.0)]),
    S("But the ban had the opposite effect. The deleted post became legendary.", "Ama yasak tam tersi bir etki yarattı. Silinen yazı efsaneleşti.",
      [E("post", 0.5, 0.45, 1.2, deleted=True), T(0.5, 0.88, "legendary", 1.2, "red")]),
    S("Copies spread across the internet. Articles called it the most terrifying thought experiment of all time.",
      "Kopyaları internete yayıldı. Makaleler onu tüm zamanların en korkutucu düşünce deneyi olarak andı.",
      [E("post", 0.25, 0.3, 0.6), E("post", 0.5, 0.3, 0.6), E("post", 0.75, 0.3, 0.6), E("post", 0.38, 0.68, 0.6), E("post", 0.62, 0.68, 0.6)]),
    S("There's a name for this: the *Streisand effect*.", "Bunun bir adı var: *Streisand etkisi*.",
      [T(0.5, 0.42, "the Streisand effect", 1.8, underline="red")]),
    S("In 2003, singer *Barbra Streisand* sued a photographer to remove an aerial photo of her Malibu home from a website documenting the California coastline.",
      "2003'te şarkıcı *Barbra Streisand*, Kaliforniya kıyılarını belgeleyen bir sitede yer alan Malibu'daki evinin havadan çekilmiş fotoğrafını kaldırtmak için bir fotoğrafçıya dava açtı.",
      [E("house", 0.42, 0.75, 1.0), E("camera", 0.82, 0.25, 0.7), T(0.15, 0.12, "2003", 1.0, "blue")]),
    S("Before the lawsuit, the image had been downloaded only a handful of times.", "Davadan önce fotoğraf yalnızca birkaç kez indirilmişti.",
      [E("house", 0.35, 0.75, 0.9), T(0.75, 0.4, "6 downloads", 1.3, "blue")]),
    S("After the news broke, hundreds of thousands of people went to look at it.", "Haber duyulunca yüz binlerce kişi fotoğrafa bakmaya gitti.",
      [E("house", 0.35, 0.75, 0.9), T(0.75, 0.4, "420,000+", 1.6, "red", underline="red"), E("graph", 0.75, 0.68, 0.45)]),
    S("Trying to hide information often makes it more famous.", "Bilgiyi saklamaya çalışmak çoğu zaman onu daha da ünlü yapar.",
      [E("lock", 0.3, 0.4, 0.9), A(0.42, 0.45, 0.58, 0.45, bend=0.0), E("dots", 0.78, 0.45, 0.8, n=40, cols=8, highlight=40)]),
    S("And Roko's Basilisk became famous precisely because someone tried to bury it.", "Roko'nun Basiliski de tam olarak biri onu gömmeye çalıştığı için ünlendi.",
      [E("basilisk", 0.45, 0.5, 1.5), T(0.5, 0.1, "famous", 1.4, "red", underline="red")]),
    # ------------------------------------------------------------ Pascal
    S("If the basilisk feels oddly familiar, there's a reason. It's a modern cousin of one of the most famous arguments in philosophy.",
      "Basilisk sana tuhaf biçimde tanıdık geliyorsa bunun bir sebebi var. Felsefenin en ünlü argümanlarından birinin modern bir kuzeni.",
      [E("basilisk", 0.3, 0.5, 0.9), T(0.5, 0.45, "≈", 2.0), E("scroll", 0.78, 0.45, 0.8)]),
    IMG("pascal", "Blaise Pascal · 1623–1662",
        "In the 1600s, the French mathematician and philosopher *Blaise Pascal* proposed what became known as *Pascal's Wager*.",
        "1600'lerde Fransız matematikçi ve filozof *Blaise Pascal*, sonradan *Pascal'ın Bahsi* olarak bilinecek bir fikir ortaya attı.",
        [E("portrait_frame", 0.5, 0.45, 1.3, text="Blaise Pascal")]),
    S("His notes were published after his death, in a book called the *Pensées*.", "Notları ölümünden sonra *Düşünceler* (Pensées) adlı bir kitapta yayımlandı.",
      [E("books", 0.5, 0.72, 1.1, n=3), T(0.5, 0.3, "Pensées · 1670", 1.3, "blue")]),
    S("The idea: if God exists and you believe, you gain infinitely. If God exists and you don't, you lose infinitely.",
      "Fikir şu: Tanrı varsa ve inanırsan, sonsuz kazanırsın. Tanrı varsa ve inanmazsan, sonsuz kaybedersin.",
      [T(0.5, 0.25, "believe: +∞", 1.4, "blue"), T(0.5, 0.5, "don't: −∞", 1.4, "red")]),
    S("If God doesn't exist, you lose very little either way. So, Pascal argued, the rational bet is to believe.",
      "Tanrı yoksa, her iki durumda da çok az kaybedersin. Pascal'a göre rasyonel bahis inanmaktır.",
      [E("balance", 0.5, 0.5, 1.0, tilt=0.6, left="∞", right="0")]),
    S("The basilisk has the same shape: a tiny chance of an enormous punishment, used to push you toward action now.",
      "Basiliskin şekli de aynı: Muazzam bir cezanın çok küçük bir ihtimali, seni şimdi harekete geçirmek için kullanılıyor.",
      [E("balance", 0.5, 0.5, 1.0, tilt=0.6, left="∞", right="0"), E("basilisk", 0.22, 0.15, 0.4)]),
    S("And it has the same weakness. Critics of Pascal pointed out the *many gods* problem:",
      "Ve aynı zayıflığa sahip. Pascal'ın eleştirmenleri *birçok tanrı* sorununa dikkat çekti:",
      [T(0.5, 0.42, "the many gods problem", 1.6, underline="red")]),
    S("for every god who punishes disbelief, you can imagine another who punishes the opposite.",
      "İnanmamayı cezalandıran her tanrı için, tam tersini cezalandıran başka bir tanrı hayal edebilirsin.",
      [E("dot", 0.3, 0.3, 1.2), E("dot", 0.7, 0.3, 1.2), T(0.3, 0.6, "punishes A", 0.9, "red"), T(0.7, 0.6, "punishes B", 0.9, "red")]),
    S("Likewise, for every imaginable AI that punishes you for not helping, you can imagine another that punishes you *for* helping.",
      "Aynı şekilde, yardım etmediğin için seni cezalandıran her yapay zekâ için, yardım *ettiğin için* seni cezalandıran başka bir yapay zekâ hayal edebilirsin.",
      [E("ai", 0.28, 0.42, 0.8), E("ai", 0.72, 0.42, 0.8), T(0.28, 0.8, "didn't help?", 0.9, "red"), T(0.72, 0.8, "helped?", 0.9, "red")]),
    S("When every option has an imagined infinite punishment, the threats cancel out — and you're back to thinking about what's actually likely.",
      "Her seçeneğin hayali sonsuz bir cezası olduğunda tehditler birbirini götürür ve sen yeniden neyin gerçekten muhtemel olduğunu düşünmeye dönersin.",
      [E("balance", 0.5, 0.5, 1.0, tilt=0.0, left="∞", right="∞"), T(0.5, 0.08, "they cancel out", 1.2, "blue", underline="blue")]),
    # ------------------------------------------------------------ Şantaj
    S("There's another problem, and it's a deep one.", "Bir sorun daha var ve derin bir sorun.", [T(0.5, 0.42, "problem #2", 1.6, "red")]),
    S("Think about it from the AI's side. By the time it exists, the past is already over.",
      "Yapay zekânın tarafından düşün. O var olduğunda geçmiş çoktan bitmiş olacak.",
      [E("timeline", 0.5, 0.7, 1.0), E("ai", 0.85, 0.35, 0.6), T(0.3, 0.4, "already over", 1.2, "blue")]),
    S("Punishing simulated people can't change anything that already happened.", "Simüle edilmiş insanları cezalandırmak zaten olmuş hiçbir şeyi değiştiremez.",
      [E("timeline", 0.5, 0.75, 1.0), A(0.75, 0.4, 0.3, 0.5, color="red", bend=0.3), E("cross", 0.52, 0.4, 0.9, at=1.4)]),
    S("It would just waste energy and cause suffering — which is the opposite of what a good AI is supposed to want.",
      "Sadece enerji israf eder ve acıya yol açar; iyi bir yapay zekânın istemesi gerekenin tam tersi.",
      [E("gauge", 0.5, 0.65, 1.3, value=0.1, label="waste")]),
    S("The original argument tries to get around this with an unusual kind of decision theory, sometimes called *acausal* reasoning:",
      "Asıl argüman bunu alışılmadık bir karar teorisiyle aşmaya çalışıyor. Buna bazen *nedensel olmayan* (acausal) akıl yürütme deniyor:",
      [T(0.5, 0.42, "acausal reasoning", 1.6, underline="red")]),
    S("the idea that an agent might commit, in advance, to follow through on a threat, so that the threat works on people who can predict it.",
      "Bir aracının bir tehdidi önceden taahhüt etmesi, böylece tehdidin onu öngörebilen insanlar üzerinde işe yaraması fikri.",
      [E("ai", 0.3, 0.45, 0.8), E("letter", 0.68, 0.45, 0.9, text="a promised threat")]),
    S("But here's the catch. A threat like this only has power over people who *respond* to it.",
      "Ama işin püf noktası şu: Böyle bir tehdit yalnızca ona *boyun eğen* insanlar üzerinde güç sahibidir.",
      [G(), F(0.35, 0.5, "shrug"), E("letter", 0.7, 0.4, 0.8)]),
    S("Many decision theorists argue that the rational policy is simple: *never give in to this kind of blackmail.*",
      "Birçok karar teorisyeni rasyonel politikanın basit olduğunu savunuyor: *Bu tür bir şantaja asla boyun eğme.*",
      [E("letter", 0.5, 0.42, 1.2), E("cross", 0.5, 0.42, 1.2, at=1.6), T(0.5, 0.85, "never give in", 1.2, "blue", underline="blue")]),
    S("If you're the kind of person who ignores it, an AI that reasons the same way has no reason to target you at all.",
      "Onu görmezden gelen biriysen, aynı şekilde düşünen bir yapay zekânın seni hedef almak için hiçbir sebebi yoktur.",
      [G(), F(0.3, 0.5, "walk"), E("ai", 0.75, 0.4, 0.7), T(0.75, 0.75, "no reason", 1.0, "blue")]),
    S("In other words, the basilisk's teeth only work if you let them.", "Başka bir deyişle, basiliskin dişleri ancak sen izin verirsen işe yarar.",
      [E("basilisk", 0.45, 0.5, 1.5, toothless=True), T(0.5, 0.1, "no teeth", 1.4, "blue", underline="red")]),
    # ------------------------------------------------------------ Beyaz ayı
    S("So if it's so flawed, why did it frighten people?", "Peki bu kadar kusurluysa, insanları neden korkuttu?",
      [G(), F(0.5, 0.5, "think"), T(0.75, 0.3, "why?", 1.4, "red")]),
    S("Part of the answer is in how our minds work. In 1987, psychologist *Daniel Wegner* ran a famous experiment.",
      "Cevabın bir kısmı zihnimizin nasıl çalıştığında. 1987'de psikolog *Daniel Wegner* ünlü bir deney yaptı.",
      [T(0.5, 0.42, "Wegner · 1987", 1.6, underline="red")]),
    S("He asked people to think about anything they liked for five minutes — but *not* to think of a white bear.",
      "İnsanlardan beş dakika boyunca istedikleri her şeyi düşünmelerini istedi; ama beyaz bir ayıyı *düşünmemelerini*.",
      [E("bear", 0.45, 0.5, 1.2), E("cross", 0.53, 0.45, 1.6, at=1.8)]),
    S("Every time a white bear came to mind, they had to ring a bell.", "Akıllarına her beyaz ayı geldiğinde bir zil çalmaları gerekiyordu.",
      [G(), F(0.3, 0.45, "sit"), E("bell", 0.6, 0.55, 0.6), B(0.4, 0.2, 0.7, "thought", tail=[0.32, 0.32]), E("bear", 0.36, 0.22, 0.3)]),
    S("They rang it again and again.", "Zili tekrar tekrar çaldılar.",
      [E("bell", 0.5, 0.45, 1.2), T(0.2, 0.3, "ding", 1.0, "red"), T(0.8, 0.3, "ding", 1.0, "red"), T(0.25, 0.7, "ding", 1.0, "red"), T(0.75, 0.7, "ding", 1.0, "red")]),
    S("Trying not to think of something made it keep coming back.", "Bir şeyi düşünmemeye çalışmak onun geri gelmesini sağladı.",
      [E("bear", 0.2, 0.35, 0.45), E("bear", 0.55, 0.3, 0.45), E("bear", 0.35, 0.72, 0.45), E("bear", 0.7, 0.7, 0.45)]),
    S("And later, when they were allowed to think about it freely, the white bear showed up *more* than for people who had never tried to suppress it.",
      "Daha sonra serbestçe düşünmelerine izin verildiğinde, beyaz ayı onu hiç bastırmaya çalışmamış insanlara göre *daha sık* aklına geldi.",
      [E("graph", 0.5, 0.5, 1.1), E("bear", 0.82, 0.2, 0.3)]),
    S("Wegner called this *ironic process theory*.", "Wegner buna *ironik süreç kuramı* dedi.", [T(0.5, 0.42, "ironic process theory", 1.6, underline="red")]),
    S("The part of your mind that checks \"Am I thinking about it?\" keeps reminding you of the very thing you're avoiding.",
      "Zihninin \"Onu düşünüyor muyum?\" diye kontrol eden kısmı, kaçındığın şeyi sana sürekli hatırlatır.",
      [E("head", 0.35, 0.5, 0.65), B(0.68, 0.3, 0.7), T(0.68, 0.3, "am I thinking of it?", 0.7), E("arrow", 0.68, 0.48, x2=0.45, y2=0.45, color="red")]),
    S("Now add a frightening idea that tells you *knowing it is dangerous*.", "Şimdi buna *bilmenin tehlikeli olduğunu* söyleyen korkutucu bir fikir ekle.",
      [E("head", 0.35, 0.5, 0.65), E("warning", 0.72, 0.45, 0.8)]),
    S("The harder you try to push it away, the more it returns.", "Onu uzaklaştırmaya ne kadar çok çalışırsan o kadar geri gelir.",
      [E("head", 0.35, 0.5, 0.65), E("arrow", 0.5, 0.35, x2=0.8, y2=0.35, color="blue"), E("arrow", 0.8, 0.6, x2=0.5, y2=0.6, color="red")]),
    S("Anxious minds can get caught in exactly this loop — not because the idea is true, but because it's sticky.",
      "Kaygılı zihinler tam olarak bu döngüye takılabilir; fikir doğru olduğu için değil, yapışkan olduğu için.",
      [E("circle", 0.5, 0.45, 1.0, rx=300, ry=200, color="red"), T(0.5, 0.45, "sticky, not true", 1.2)]),
    # ------------------------------------------------------------ Bilgi tehlikeleri
    S("Still, the basilisk does point at something real.", "Yine de basilisk gerçek bir şeye işaret ediyor.", [E("basilisk", 0.45, 0.5, 1.3)]),
    S("In 2011, philosopher *Nick Bostrom* published a paper on what he called *information hazards*:",
      "2011'de filozof *Nick Bostrom*, *bilgi tehlikeleri* dediği şey üzerine bir makale yayımladı:",
      [E("books", 0.3, 0.72, 0.9, n=2), E("warning", 0.7, 0.45, 0.8), T(0.5, 0.08, "information hazards · 2011", 1.0, underline="red")]),
    S("cases where true information can cause harm — like detailed instructions for building a weapon, or a spoiler that ruins a story.",
      "Doğru bilginin zarar verebildiği durumlar; bir silahın nasıl yapılacağına dair ayrıntılı talimatlar ya da bir hikâyeyi mahveden bir spoiler gibi.",
      [E("scroll", 0.27, 0.45, 0.8, text="instructions"), E("film", 0.7, 0.45, 0.9)]),
    S("Most information hazards are boring and practical. The basilisk is unusual because the \"hazard\" is mostly *psychological*:",
      "Bilgi tehlikelerinin çoğu sıkıcı ve pratiktir. Basilisk sıra dışı, çünkü \"tehlike\" çoğunlukla *psikolojik*:",
      [E("head", 0.5, 0.5, 0.7), T(0.5, 0.08, "psychological", 1.3, "red", underline="red")]),
    S("the harm comes from the worry, not from any real danger.", "Zarar gerçek bir tehlikeden değil, endişeden geliyor.",
      [T(0.3, 0.42, "worry", 1.5, "red"), T(0.7, 0.42, "danger", 1.5), E("cross", 0.7, 0.42, 0.7, at=1.0)]),
    S("And that's worth knowing. If an idea makes you anxious, it's fair to ask: *is this dangerous because it's true — or just because it's hard to stop thinking about?*",
      "Ve bunu bilmeye değer. Bir fikir seni kaygılandırıyorsa şunu sormak hakkın: *Bu doğru olduğu için mi tehlikeli, yoksa sadece düşünmeyi bırakmak zor olduğu için mi?*",
      [T(0.5, 0.3, "true?", 1.4, "blue"), T(0.5, 0.55, "or just sticky?", 1.4, "red")]),
    # ------------------------------------------------------------ Pop kültürü
    S("Today, Roko's Basilisk has become a kind of internet folklore — part joke, part warning, part meme.",
      "Bugün Roko'nun Basiliski bir tür internet folkloruna dönüştü: Biraz şaka, biraz uyarı, biraz mim.",
      [E("basilisk", 0.45, 0.45, 1.1), T(0.2, 0.8, "joke", 0.9), T(0.5, 0.8, "warning", 0.9, "red"), T(0.8, 0.8, "meme", 0.9, "blue")]),
    S("It even made it into celebrity news. In 2018, it was widely reported that *Elon Musk* and the musician *Grimes* first connected over a pun on it: *\"Rococo's Basilisk.\"*",
      "Ünlü haberlerine bile girdi. 2018'de *Elon Musk* ile müzisyen *Grimes*'ın ilk olarak bu fikir üzerine yapılmış bir kelime oyunu üzerinden, *\"Rococo's Basilisk\"* sayesinde tanıştıkları yaygın olarak haber yapıldı.",
      [E("basilisk", 0.4, 0.5, 1.2), T(0.5, 0.1, "\"Rococo's Basilisk\"", 1.3, "red", underline="red"), E("heart", 0.82, 0.3, 0.5)]),
    S("And it often comes up in conversations about AI — though most AI researchers worry about very different things:",
      "Ve yapay zekâ konuşmalarında sık sık gündeme geliyor. Ama çoğu yapay zekâ araştırmacısı çok farklı şeylerden endişe ediyor:",
      [E("ai", 0.5, 0.45, 1.0)]),
    S("systems that make mistakes, that are misused, or that pursue goals that don't match ours. Those are real questions, being studied seriously.",
      "hata yapan, kötüye kullanılan ya da bizimkilerle örtüşmeyen hedefler peşinde koşan sistemler. Bunlar ciddi biçimde incelenen gerçek sorular.",
      [T(0.5, 0.25, "mistakes", 1.2), T(0.5, 0.42, "misuse", 1.2), T(0.5, 0.59, "the wrong goals", 1.2), T(0.5, 0.82, "real questions", 1.0, "blue", underline="blue")]),
    S("A vengeful machine punishing simulations of people who didn't donate is not one of them.",
      "Bağış yapmayan insanların simülasyonlarını cezalandıran intikamcı bir makine bunlardan biri değil.",
      [E("basilisk", 0.45, 0.5, 1.2, faded=True), E("cross", 0.45, 0.45, 1.4, at=1.0)]),
    # ------------------------------------------------------------ Kendin dene
    S("Let's try something. For the next ten seconds, don't think about the basilisk.",
      "Bir şey deneyelim. Önümüzdeki on saniye boyunca basiliski düşünme.",
      [E("countdown", 0.5, 0.45, 1.2), T(0.12, 0.1, "try this", 1.0, "red", underline="red")]),
    S("Hard, isn't it?", "Zor, değil mi?", [E("basilisk", 0.45, 0.5, 1.0), T(0.8, 0.3, "?", 2.4, "red")]),
    S("Now try the opposite. Think about it as clearly as you can — and ask three questions.",
      "Şimdi tersini dene. Onu olabildiğince net düşün ve üç soru sor.", [T(0.5, 0.42, "1 · 2 · 3", 2.0)]),
    S("First: what evidence would make this *likely*, not just *possible*?", "Birincisi: Bunu sadece *mümkün* değil, *muhtemel* yapacak kanıt ne olurdu?",
      [T(0.12, 0.12, "1.", 1.4, "red"), E("magnifier", 0.45, 0.42, 1.0), T(0.75, 0.42, "likely?", 1.2, "blue")]),
    S("Second: if I imagine the opposite threat, does it feel just as convincing?", "İkincisi: Tam tersi tehdidi hayal edersem, o da aynı derecede ikna edici geliyor mu?",
      [T(0.12, 0.12, "2.", 1.4, "red"), E("balance", 0.5, 0.5, 0.9, tilt=0.0, left="A", right="B")]),
    S("Third: if I ignore this completely, what actually changes in my life tomorrow?", "Üçüncüsü: Bunu tamamen görmezden gelirsem, yarın hayatımda gerçekte ne değişir?",
      [T(0.12, 0.12, "3.", 1.4, "red"), E("calendar", 0.5, 0.45, 1.1)]),
    S("Most scary ideas lose their grip when you look straight at them. The basilisk only works as long as you look *away*.",
      "Korkutucu fikirlerin çoğu, onlara doğrudan baktığında etkisini kaybeder. Basilisk ancak sen gözünü *kaçırdığın* sürece işe yarar.",
      [E("eye", 0.3, 0.45, 0.9), A(0.43, 0.45, 0.55, 0.45, bend=0.0), E("basilisk", 0.75, 0.5, 0.7, faded=True)]),
    # ------------------------------------------------------------ Kapanış
    S("The legend said you couldn't survive the basilisk's gaze.", "Efsaneye göre basiliskin bakışından kurtulamazdın.",
      [E("basilisk", 0.45, 0.5, 1.5)]),
    S("But in the old stories, there was one way to defeat it: hold up a *mirror*, and let it see itself.",
      "Ama eski hikâyelerde onu yenmenin bir yolu vardı: Bir *ayna* tut ve kendini görmesini sağla.",
      [E("basilisk", 0.3, 0.55, 0.9), E("mirror", 0.75, 0.42, 0.9)]),
    S("Maybe that's what thinking clearly is. Not running from an idea — but holding it up to the light, until you can see exactly what it's made of.",
      "Belki açık düşünmek de budur. Bir fikirden kaçmak değil; ne yapıldığını tam olarak görene kadar onu ışığa tutmak.",
      [E("basilisk", 0.3, 0.55, 0.9, faded=True), E("mirror", 0.75, 0.42, 0.9), E("dot", 0.75, 0.12, 1.2)]),
    S("And this one, it turns out, is made of fear... and a little bit of bad math.",
      "Ve bu fikrin, anlaşılan o ki, korkudan… ve biraz da kötü matematikten yapıldığı ortaya çıkıyor.",
      [T(0.5, 0.32, "fear", 1.6, "red"), T(0.5, 0.55, "+ bad math", 1.4, "blue", underline="red")]),
]

subscribe = dict(after=8, sketch=[dict(el="subscribe", x=0.45, y=0.45, s=1.4), dict(el="arrow", x=0.2, y=0.75, x2=0.33, y2=0.55, color="red", s=1.2)],
                 say={"en": "Quick favor before we start: if you like ideas that are a little dangerous to think about, *subscribe*. It genuinely helps the channel.",
                      "tr": "Başlamadan küçük bir rica: Düşünmesi biraz tehlikeli fikirleri seviyorsan *abone ol*. Kanala gerçekten çok yardımı oluyor."})
meta = {"en": dict(title="Roko's Basilisk", description="", tags=[]), "tr": dict(title="Roko'nun Basiliski", description="", tags=[])}
out = dict(slug="basilisk", format="long", theme="karakalem", character="none", languages=["en"], subtitles=["tr"],
           voices={"en": "am_fenrir"}, speech_rate=0.88, meta=meta, subscribe=subscribe, scenes=scenes)
json.dump(out, open(os.path.join(HERE, "basilisk.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
words = sum(len(s["say"]["en"].split()) for s in scenes) + len(subscribe["say"]["en"].split())
print(f"{len(scenes)} sahne, {words} kelime")
