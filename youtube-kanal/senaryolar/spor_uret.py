#!/usr/bin/env python3
"""Spor videosunun sahne sahne senaryosu.  Çalıştır: python3 senaryolar/spor_uret.py -> senaryolar/spor.json"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
IMGS = {}
p = os.path.join(HERE, "spor_gorseller.json")
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
    S("In the summer of 2006, during the World Cup in Germany, doctors in Munich noticed something strange.",
      "2006 yazında, Almanya'daki Dünya Kupası sırasında Münihli doktorlar tuhaf bir şey fark etti.",
      [E("ball", 0.3, 0.45, 1.6), T(0.7, 0.35, "World Cup 2006", 1.3, "blue"), T(0.7, 0.55, "Munich", 1.1)]),
    S("On days when the German national team played, cardiac emergencies among local fans were more than *two and a half times* higher than normal.",
      "Alman milli takımının oynadığı günlerde, yerel taraftarlar arasındaki kalp acilleri normalin *iki buçuk katından* fazlaydı.",
      [E("heart", 0.25, 0.4, 1.0), E("ekg", 0.62, 0.45, 0.7, spike=1.4), T(0.62, 0.8, "×2.66", 1.8, "red", underline="red")]),
    S("People weren't running. They weren't playing. They were *watching*.", "İnsanlar koşmuyordu. Oynamıyordu. *İzliyordu*.",
      [E("tv", 0.62, 0.45, 1.0, text="LIVE"), F(0.22, 0.45, "sit", y=0.78), E("chair", 0.22, 0.78, 0.9)]),
    S("And watching was enough to push their hearts to the limit.", "Ve izlemek kalplerini sınıra dayamaya yetiyordu.",
      [E("heart", 0.35, 0.45, 1.3), E("gauge", 0.72, 0.6, 0.9, value=0.95, label="limit")]),
    S("Every weekend, billions of people do something that makes very little sense on paper:",
      "Her hafta sonu milyarlarca insan kâğıt üzerinde pek anlamlı olmayan bir şey yapıyor:",
      [E("globe", 0.3, 0.5, 1.0), E("calendar", 0.72, 0.45, 0.9, text="every weekend")]),
    S("they spend hours watching strangers chase a ball —", "Saatlerce bir topun peşinden koşan yabancıları izliyor",
      [G(0.55), F(0.3, 0.2, "walk", y=0.55), F(0.45, 0.2, "walk", -1, y=0.55), E("ball", 0.38, 0.5, 0.3), E("stands", 0.5, 0.95, 0.8)]),
    S("and feel joy, rage and heartbreak as if their own lives depended on it.",
      "ve sanki kendi hayatları buna bağlıymış gibi sevinç, öfke ve hayal kırıklığı yaşıyor.",
      [T(0.2, 0.42, "joy", 1.5, "blue"), T(0.5, 0.42, "rage", 1.5, "red"), T(0.8, 0.42, "heartbreak", 1.3)]),
    S("Why?", "Neden?", [T(0.5, 0.42, "Why?", 3.0, "red", underline="red")]),
    # ------------------------------------------------------------ Bölüm 1: Tarih
    S("Watching sports is not a modern habit.", "Spor izlemek modern bir alışkanlık değil.", [E("hourglass", 0.5, 0.45, 1.3)]),
    IMG("olympia", "Stadium of ancient Olympia, Greece",
        "The ancient Olympic Games began in Greece, traditionally dated to 776 BC.",
        "Antik Olimpiyat Oyunları Yunanistan'da, geleneksel olarak MÖ 776'da başladı.",
        [G(), F(0.3, 0.45, "walk"), F(0.5, 0.45, "walk"), F(0.7, 0.45, "walk"), T(0.5, 0.12, "776 BC", 1.6, "blue")]),
    S("Crowds traveled for days to watch.", "Kalabalıklar izlemek için günlerce yol yürüdü.",
      [G(), F(0.2, 0.35, "walk"), F(0.3, 0.38, "walk"), F(0.4, 0.33, "walk"), A(0.5, 0.55, 0.8, 0.55, bend=0.0), T(0.82, 0.4, "Olympia", 1.2, "blue")]),
    IMG("circus", "Circus Maximus, Rome (reconstruction)",
        "In Rome, the Circus Maximus could hold well over a hundred thousand spectators for chariot races.",
        "Roma'da Circus Maximus, araba yarışları için yüz binden fazla seyirci alabiliyordu.",
        [E("chariot", 0.45, 0.65, 1.0), T(0.5, 0.12, "100,000+", 1.6, "red")]),
    S("And in Constantinople, today's Istanbul,", "Ve bugünkü İstanbul olan Konstantinopolis'te",
      [T(0.5, 0.32, "Constantinople", 1.5), T(0.5, 0.55, "= Istanbul", 1.4, "red", underline="red")]),
    S("chariot-racing fans were divided into teams named after colors: the *Blues* and the *Greens*.",
      "araba yarışı taraftarları renklerle anılan takımlara ayrılmıştı: *Maviler* ve *Yeşiller*.",
      [E("flag", 0.25, 0.8, 1.0, color="blue", text="BLUES"), E("flag", 0.65, 0.8, 1.0, color=[70, 140, 70], text="GREENS")]),
    IMG("hippodrome", "Hippodrome of Constantinople · Istanbul",
        "In the year 532, the rival fans did something unthinkable: they united against the emperor.",
        "532 yılında iki rakip taraftar grubu akıl almaz bir şey yaptı: İmparatora karşı birleştiler.",
        [E("flag", 0.3, 0.8, 0.8, color="blue"), E("flag", 0.45, 0.8, 0.8, color=[70, 140, 70]), A(0.6, 0.5, 0.8, 0.5, bend=0.0, color="red"), E("dome", 0.85, 0.6, 0.6)]),
    S("The *Nika riots* burned much of the city.", "*Nika ayaklanması* şehrin büyük kısmını yaktı.",
      [E("house", 0.3, 0.8, 0.9), E("campfire", 0.3, 0.6, 1.0), E("house", 0.7, 0.8, 0.9), E("campfire", 0.7, 0.6, 1.0), T(0.5, 0.1, "Nika · 532", 1.4, "red")]),
    S("According to the historian Procopius, around thirty thousand people were killed when the uprising was crushed in the Hippodrome.",
      "Tarihçi Prokopios'a göre ayaklanma Hipodrom'da bastırıldığında yaklaşık otuz bin kişi öldürüldü.",
      [E("scroll", 0.3, 0.45, 0.9, text="Procopius"), T(0.72, 0.45, "≈ 30,000", 1.8, "red")]),
    S("Sports fandom almost toppled one of the most powerful empires in history.",
      "Spor taraftarlığı tarihin en güçlü imparatorluklarından birini neredeyse devirmişti.",
      [E("dome", 0.5, 0.65, 1.3), T(0.5, 0.1, "fans vs. an empire", 1.3, "red", underline="red")]),
    # ------------------------------------------------------------ Bölüm 2: Beyin
    S("So what happens inside us when we watch?", "Peki izlerken içimizde ne oluyor?", [E("head", 0.4, 0.5, 0.7), E("tv", 0.78, 0.45, 0.6)]),
    S("In the 1990s, Italian scientists studying monkeys found neurons that fired both when a monkey grabbed a peanut",
      "1990'larda maymunlar üzerinde çalışan İtalyan bilim insanları, bir maymun fıstık aldığında da",
      [E("ape", 0.35, 0.6, 1.0), E("dot", 0.5, 0.45, 0.6, color="gold"), T(0.75, 0.3, "1990s · Italy", 1.1, "blue")]),
    S("and when it simply *watched* someone else grab one.", "başka birinin fıstık aldığını sadece *izlediğinde* de ateşlenen nöronlar buldu.",
      [E("ape", 0.25, 0.6, 0.9), E("eye", 0.45, 0.35, 0.5), F(0.75, 0.45, "reach", -1), E("dot", 0.62, 0.45, 0.5, color="gold")]),
    S("They called them *mirror neurons*.", "Onlara *ayna nöronlar* dediler.",
      [E("brain", 0.35, 0.45, 1.0, spot=[0.1, -0.1]), E("mirror", 0.75, 0.42, 0.8), T(0.5, 0.88, "mirror neurons", 1.3, "red", underline="red")]),
    S("How exactly this works in humans is still debated.", "Bunun insanlarda tam olarak nasıl işlediği hâlâ tartışılıyor.",
      [E("brain", 0.4, 0.45, 0.9), T(0.78, 0.4, "?", 2.4, "red")]),
    S("But brain scans show that watching an action activates some of the same areas we use to perform it.",
      "Ama beyin taramaları, bir hareketi izlemenin onu yaparken kullandığımız bölgelerin bir kısmını etkinleştirdiğini gösteriyor.",
      [E("brain", 0.3, 0.45, 0.8, spot=[0.1, -0.1]), T(0.5, 0.45, "=", 1.8), E("brain", 0.72, 0.45, 0.8, spot=[0.1, -0.1]),
       T(0.3, 0.85, "watching", 1.0, "blue"), T(0.72, 0.85, "doing", 1.0, "red")]),
    S("And expertise makes it stronger.", "Ve uzmanlık bunu güçlendiriyor.", [E("graph", 0.5, 0.5, 1.0)]),
    S("In one study, professional basketball players watched short clips of free throws.",
      "Bir çalışmada profesyonel basketbolcular serbest atışların kısa kliplerini izledi.",
      [E("hoop", 0.7, 0.35, 0.8), G(0.85), F(0.3, 0.5, "reach", y=0.85), E("bball", 0.42, 0.25, 0.6)]),
    S("They could predict whether the ball would go in — *before it left the shooter's hand* —",
      "Topun girip girmeyeceğini, *top atıcının elinden çıkmadan önce*,",
      [E("hoop", 0.75, 0.35, 0.8), G(0.85), F(0.3, 0.5, "reach", y=0.85), E("bball", 0.34, 0.33, 0.5), T(0.55, 0.15, "in or out?", 1.3, "red")]),
    S("far better than coaches or sports journalists.", "antrenörlerden ve spor gazetecilerinden çok daha iyi tahmin ettiler.",
      [E("bars", 0.5, 0.78, 0.9, values=[["players", 60, "blue"], ["coaches", 40, "red"], ["journalists", 38, "red"]], pct=False)]),
    S("When you watch a striker shoot, a small part of your brain is shooting too.",
      "Bir golcünün şut çektiğini izlediğinde beyninin küçük bir parçası da şut çekiyor.",
      [E("head", 0.3, 0.5, 0.6, glow=True), E("goal", 0.72, 0.65, 0.7, scored=True)]),
    # ------------------------------------------------------------ Bölüm 3: Belirsizlik
    S("But mirroring alone doesn't explain the obsession.", "Ama sadece ayna etkisi bu tutkuyu açıklamıyor.",
      [E("mirror", 0.35, 0.42, 0.8), T(0.72, 0.42, "not enough", 1.3, "red")]),
    S("The real hook is something else: *we don't know how it ends*.", "Asıl kanca başka bir şey: *Nasıl biteceğini bilmiyoruz*.",
      [E("score", 0.5, 0.42, 1.2, a="?", b="?"), T(0.5, 0.85, "unknown ending", 1.3, "red", underline="red")]),
    S("Neuroscientist *Wolfram Schultz* found that dopamine neurons don't simply fire when we get a reward.",
      "Sinirbilimci *Wolfram Schultz*, dopamin nöronlarının bir ödül aldığımızda öylece ateşlenmediğini buldu.",
      [E("brain", 0.3, 0.45, 0.9, spot=[0.0, 0.1]), T(0.72, 0.4, "dopamine", 1.4, "blue"), T(0.72, 0.6, "Schultz · 1997", 1.0)]),
    S("They fire most strongly when something is *better than we expected*.", "En güçlü tepkiyi bir şey *beklediğimizden iyi* olduğunda veriyorlar.",
      [T(0.3, 0.3, "expected", 1.2), E("line", 0.1, 0.55, x2=0.45, y2=0.55, color="grey"), T(0.72, 0.3, "better!", 1.3, "red"),
       E("ekg", 0.72, 0.6, 0.45, spike=2.0)]),
    S("When a reward is completely predictable, the response fades.", "Bir ödül tamamen tahmin edilebilir olduğunda tepki sönüyor.",
      [E("ekg", 0.5, 0.5, 0.8, spike=0.15, color="grey"), T(0.5, 0.15, "predictable = flat", 1.3, "blue")]),
    S("That's why a recorded match whose result you already know feels flat.", "Bu yüzden sonucunu zaten bildiğin kayıtlı bir maç yavan gelir.",
      [E("tv", 0.35, 0.45, 0.9, text="REPLAY"), E("ekg", 0.78, 0.5, 0.35, spike=0.15, color="grey")]),
    S("And it's why a last-minute goal feels like an explosion.", "Ve bu yüzden son dakika golü bir patlama gibi hissettirir.",
      [E("score", 0.3, 0.4, 0.8, a="2", b="1", time="90+3'"), E("goal", 0.72, 0.7, 0.7, scored=True), T(0.72, 0.15, "GOAL!", 1.8, "red")]),
    S("Economists noticed this too. In 1956, *Simon Rottenberg* argued that fans want competition to be *uncertain*.",
      "Ekonomistler de bunu fark etti. 1956'da *Simon Rottenberg*, taraftarların rekabetin *belirsiz* olmasını istediğini savundu.",
      [E("balance", 0.5, 0.45, 0.9, tilt=0.0, left="A", right="B"), T(0.5, 0.92, "Rottenberg · 1956", 1.0, "blue")]),
    S("If one team always wins, people stop watching.", "Bir takım hep kazanırsa insanlar izlemeyi bırakır.",
      [E("trophy", 0.3, 0.75, 1.0), T(0.3, 0.12, "always", 1.1), E("tv", 0.72, 0.45, 0.7), E("cross", 0.72, 0.45, 0.7, at=1.0)]),
    S("That's why many leagues use drafts, salary caps and revenue sharing: to keep the ending unknown.",
      "Bu yüzden birçok lig draft, maaş sınırı ve gelir paylaşımı kullanıyor: sonu bilinmez tutmak için.",
      [T(0.5, 0.25, "drafts", 1.2), T(0.5, 0.42, "salary caps", 1.2), T(0.5, 0.59, "revenue sharing", 1.2), T(0.5, 0.85, "keep it uncertain", 1.1, "red")]),
    S("Sport is one of the few places left where nobody — not even the richest person on Earth — can buy the ending in advance.",
      "Spor, kimsenin, dünyanın en zengin insanının bile sonu önceden satın alamadığı az sayıdaki yerden biri.",
      [E("money", 0.3, 0.6, 1.0, text="$$$"), A(0.43, 0.5, 0.58, 0.5, bend=0.0), E("score", 0.75, 0.45, 0.7, a="?", b="?"), E("cross", 0.5, 0.5, 0.5, at=1.0)]),
    # ------------------------------------------------------------ Bölüm 4: Biz kazandık
    S("Now here's the strangest part. Listen to how fans talk.", "Şimdi en tuhaf kısma geldik. Taraftarların nasıl konuştuğunu dinle.",
      [E("ear", 0.4, 0.45, 2.2), E("stands", 0.7, 0.9, 0.5)]),
    S("When their team wins, they say *\"we won.\"*", "Takımları kazandığında *\"kazandık\"* derler.",
      [G(), F(0.3, 0.55, "reach"), B(0.64, 0.28, 1.1, tail=[0.4, 0.38]), T(0.62, 0.3, "WE won!", 1.2, "blue")]),
    S("When it loses, they often say *\"they lost.\"*", "Kaybettiğinde ise çoğu zaman *\"kaybettiler\"*.",
      [G(), F(0.3, 0.55, "shrug"), B(0.64, 0.28, 1.1, tail=[0.4, 0.38]), T(0.62, 0.3, "THEY lost.", 1.2, "red")]),
    S("In 1976, psychologist *Robert Cialdini* and his colleagues counted how many students at American universities wore their school's clothing on Mondays after football games.",
      "1976'da psikolog *Robert Cialdini* ve meslektaşları, Amerikan üniversitelerinde maçlardan sonraki pazartesi günleri kaç öğrencinin okulunun kıyafetini giydiğini saydı.",
      [E("tshirt", 0.3, 0.5, 0.9, text="U"), E("calendar", 0.72, 0.45, 0.8, text="Monday"), T(0.5, 0.08, "Cialdini · 1976", 1.1, "blue")]),
    S("After a win, significantly more students wore school colors.", "Bir galibiyetten sonra okul renklerini giyen öğrenci sayısı belirgin şekilde arttı.",
      [E("bars", 0.5, 0.78, 0.9, values=[["after a loss", 30, "red"], ["after a win", 55, "blue"]], pct=False)]),
    S("Asked to describe the game, they were more likely to say \"we\" after a victory, and \"they\" after a defeat.",
      "Maçı anlatmaları istendiğinde galibiyetten sonra \"biz\", yenilgiden sonra \"onlar\" deme olasılıkları daha yüksekti.",
      [T(0.3, 0.35, "win: \"we\"", 1.4, "blue"), T(0.7, 0.55, "loss: \"they\"", 1.4, "red")]),
    S("Cialdini called it *basking in reflected glory*.", "Cialdini buna *yansıyan şanın tadını çıkarmak* dedi.",
      [E("sun", 0.3, 0.35, 0.8), G(), F(0.6, 0.5, "reach"), T(0.5, 0.88, "basking in reflected glory", 1.1, "red", underline="red")]),
    S("Later researchers named the opposite *cutting off reflected failure*.", "Sonraki araştırmacılar tersine *yansıyan başarısızlıktan uzaklaşmak* adını verdi.",
      [G(), F(0.3, 0.5, "walk", -1), E("trophy", 0.75, 0.78, 0.6), E("cross", 0.75, 0.6, 0.5, at=0.8), T(0.5, 0.1, "cutting off reflected failure", 1.0, "blue")]),
    S("We borrow a little of the winners' success, and quietly step away from the losers.",
      "Kazananların başarısından biraz ödünç alıyoruz, kaybedenlerden sessizce uzaklaşıyoruz.",
      [G(), F(0.5, 0.5), A(0.45, 0.4, 0.25, 0.4, bend=-0.2, color="blue"), A(0.55, 0.6, 0.8, 0.6, bend=0.2, color="red"), E("trophy", 0.15, 0.6, 0.5)]),
    S("We didn't kick a single ball. But our self-esteem rises and falls with the score.",
      "Tek bir topa vurmadık. Ama özgüvenimiz skorla birlikte inip çıkıyor.",
      [E("score", 0.3, 0.42, 0.7, a="1", b="0"), E("gauge", 0.72, 0.6, 0.9, value=0.8, label="self-esteem")]),
    # ------------------------------------------------------------ Bölüm 5: Kabile
    S("Why would our self-esteem be tied to a team at all?", "Peki özgüvenimiz neden bir takıma bağlı olsun ki?",
      [E("head", 0.35, 0.5, 0.6), E("line", 0.45, 0.45, x2=0.62, y2=0.45, color="red"), E("flag", 0.7, 0.75, 0.8, color="red")]),
    S("In the early 1970s, psychologist *Henri Tajfel* ran a famous experiment.", "1970'lerin başında psikolog *Henri Tajfel* ünlü bir deney yaptı.",
      [T(0.5, 0.42, "Tajfel · 1970s", 1.8, underline="red")]),
    IMG("klee", "Paul Klee · Garden Plan (1922)",
        "He divided boys into two groups based on something trivial, like which abstract painter they supposedly preferred,",
        "Erkek çocukları önemsiz bir şeye göre iki gruba ayırdı: Örneğin güya hangi soyut ressamı tercih ettiklerine göre,",
        [E("painting", 0.3, 0.45, 1.0), E("painting", 0.72, 0.45, 1.0, style="kandinsky")]),
    IMG("kandinsky", "Wassily Kandinsky · Composition VIII (1923)",
        "*Klee* or *Kandinsky*.", "*Klee* mi *Kandinsky* mi.",
        [E("painting", 0.3, 0.45, 1.0), T(0.3, 0.8, "Klee", 1.2, "red"), E("painting", 0.72, 0.45, 1.0, style="kandinsky"), T(0.72, 0.8, "Kandinsky", 1.2, "blue")]),
    S("They never met their group. There was no history, no rivalry, nothing at stake.",
      "Gruplarıyla hiç tanışmadılar. Ortada geçmiş yoktu, rekabet yoktu, kaybedilecek bir şey yoktu.",
      [G(), F(0.2, 0.3, child=True), F(0.32, 0.3, child=True), F(0.68, 0.3, child=True), F(0.8, 0.3, child=True), T(0.5, 0.25, "nothing at stake", 1.2, "blue")]),
    S("And yet, when asked to share out rewards, the boys favored their own group,", "Yine de ödülleri paylaştırmaları istendiğinde çocuklar kendi gruplarını kayırdı;",
      [E("money", 0.5, 0.45, 0.8, text="$"), A(0.42, 0.5, 0.2, 0.55, bend=-0.2, color="red"), E("flag", 0.15, 0.85, 0.6, color="red"), E("flag", 0.82, 0.85, 0.6, color="blue")]),
    S("often even if it meant everyone got less overall, just so their group could come out ahead.",
      "çoğu zaman sırf kendi grupları öne geçsin diye herkesin toplamda daha az alması pahasına bile.",
      [E("bars", 0.5, 0.78, 0.9, values=[["us", 30, "red"], ["them", 20, "blue"]], pct=False), T(0.5, 0.12, "less for all, but ahead", 1.1, "red")]),
    S("Tajfel and *John Turner* developed *social identity theory*:", "Tajfel ve *John Turner*, *sosyal kimlik kuramını* geliştirdi:",
      [T(0.5, 0.42, "social identity theory", 1.6, underline="red")]),
    S("part of who we are comes from the groups we belong to. Our minds are built for tribes.",
      "Kim olduğumuzun bir kısmı ait olduğumuz gruplardan gelir. Zihnimiz kabileler için yapılmış.",
      [E("head", 0.3, 0.5, 0.6), E("heads", 0.72, 0.45, 0.5, n=3)]),
    S("For most of human history, belonging to a group meant survival.", "İnsanlık tarihinin büyük bölümünde bir gruba ait olmak hayatta kalmak demekti.",
      [E("campfire", 0.5, 0.75, 1.0), F(0.3, 0.38, "sit", y=0.78), F(0.7, 0.38, "sit", -1, y=0.78), F(0.5, 0.3, "sit", y=0.62)]),
    S("Sports gives that ancient instinct a home: colors, chants, rivals, and a reason to feel like part of something bigger.",
      "Spor bu kadim içgüdüye bir yuva veriyor: renkler, tezahüratlar, rakipler ve kendini büyük bir şeyin parçası hissetmek için bir sebep.",
      [E("stands", 0.5, 0.9, 1.0), T(0.5, 0.1, "colors · chants · rivals", 1.2, "blue")]),
    S("And it's not just in our heads.", "Ve bu sadece kafamızda değil.", [E("head", 0.5, 0.5, 0.7)]),
    S("A 1998 study found that fans' testosterone levels *rose* after their team won, and *fell* after a loss,",
      "1998'de yapılan bir çalışma, takımları kazandığında taraftarların testosteron seviyesinin *yükseldiğini*, kaybettiğinde *düştüğünü* buldu;",
      [E("graph", 0.3, 0.5, 0.6), T(0.3, 0.15, "win", 1.1, "blue"), E("graph", 0.72, 0.5, 0.6, up=False), T(0.72, 0.15, "loss", 1.1, "red")]),
    S("almost as if they had fought the battle themselves.", "sanki savaşı kendileri vermiş gibi.",
      [E("sword", 0.5, 0.6, 1.2)]),
    # ------------------------------------------------------------ Bölüm 6: They saw a game
    S("Tribes don't just feel differently. They *see* differently.", "Kabileler sadece farklı hissetmez. Farklı *görür*.",
      [E("eye", 0.3, 0.45, 0.9), E("eye", 0.72, 0.45, 0.9), T(0.5, 0.85, "see differently", 1.3, "red")]),
    S("In 1951, Princeton and Dartmouth played a brutal American football game. Players were injured on both sides.",
      "1951'de Princeton ve Dartmouth sert bir Amerikan futbolu maçı oynadı. İki taraftan da oyuncular sakatlandı.",
      [G(), F(0.35, 0.5, "kick"), F(0.6, 0.5, "lie", -1, y=0.8), T(0.5, 0.1, "Princeton vs Dartmouth · 1951", 1.1, "blue")]),
    S("Psychologists *Albert Hastorf* and *Hadley Cantril* showed a film of the game to students from both universities",
      "Psikologlar *Albert Hastorf* ve *Hadley Cantril*, maçın filmini iki üniversiteden öğrencilere izletti",
      [E("film", 0.5, 0.35, 1.0, text="1951"), G(0.9), F(0.3, 0.3, "sit", y=0.9), F(0.7, 0.3, "sit", -1, y=0.9)]),
    S("and asked them to count the rule violations.", "ve kural ihlallerini saymalarını istedi.",
      [E("film", 0.5, 0.35, 1.0, text="fouls?"), T(0.5, 0.75, "count the fouls", 1.2, "red")]),
    S("Princeton students saw Dartmouth commit about twice as many fouls as Dartmouth students did.",
      "Princeton öğrencileri, Dartmouth'un yaptığı faulleri Dartmouth öğrencilerinin gördüğünün yaklaşık iki katı kadar gördü.",
      [E("bars", 0.5, 0.78, 0.9, values=[["Princeton saw", 58, "red"], ["Dartmouth saw", 26, "blue"]], pct=False), T(0.5, 0.1, "Dartmouth fouls: 9.8 vs 4.3", 1.1)]),
    S("Same film. Same plays. Two completely different games.", "Aynı film. Aynı pozisyonlar. Tamamen farklı iki maç.",
      [E("film", 0.5, 0.3, 0.9, text="same film"), T(0.3, 0.7, "game A", 1.3, "red"), T(0.7, 0.7, "game B", 1.3, "blue")]),
    S("Their paper was called *\"They Saw a Game.\"*", "Makalelerinin adı *\"Bir Maç Gördüler\"*di.",
      [E("books", 0.5, 0.7, 1.0, n=1), T(0.5, 0.35, "\"They Saw a Game\"", 1.6, underline="red")]),
    S("It's one of the reasons every fan is absolutely certain the referee is biased against *their* team.",
      "Her taraftarın hakemin *kendi* takımına karşı taraflı olduğundan kesinlikle emin olmasının sebeplerinden biri bu.",
      [G(), F(0.5, 0.5, "point"), B(0.2, 0.25, 0.6), T(0.2, 0.25, "biased!", 0.9, "red"), B(0.82, 0.25, 0.6), T(0.82, 0.25, "biased!", 0.9, "blue")]),
    # ------------------------------------------------------------ Bölüm 7: Güvenli savaş
    S("Sociologists *Norbert Elias* and *Eric Dunning* had a theory about why all of this matters so much in the modern world.",
      "Sosyologlar *Norbert Elias* ve *Eric Dunning*'in tüm bunların modern dünyada neden bu kadar önemli olduğuna dair bir kuramı vardı.",
      [E("books", 0.3, 0.72, 0.9, n=2), T(0.68, 0.4, "Quest for Excitement", 1.2, "red"), T(0.68, 0.58, "Elias & Dunning", 1.0, "blue")]),
    S("Modern life, they argued, asks us to control our emotions almost all the time: at work, in traffic, in public.",
      "Onlara göre modern hayat, duygularımızı neredeyse her zaman kontrol etmemizi istiyor: işte, trafikte, toplum içinde.",
      [E("screen", 0.25, 0.6, 0.8), G(), F(0.55, 0.5, tone=0.5), E("padlock", 0.8, 0.45, 0.8)]),
    S("We rarely get to scream, hug strangers, or cry openly.", "Bağırmaya, yabancılara sarılmaya ya da açıkça ağlamaya pek fırsatımız olmuyor.",
      [T(0.25, 0.35, "scream", 1.2), T(0.5, 0.55, "hug", 1.2), T(0.75, 0.35, "cry", 1.2), E("cross", 0.5, 0.45, 1.2, at=1.2)]),
    S("Sport creates a protected space where intense emotion is allowed: a *controlled loss of control*.",
      "Spor, yoğun duyguların serbest olduğu korunaklı bir alan yaratıyor: *kontrollü bir kontrol kaybı*.",
      [E("stands", 0.5, 0.75, 0.9), E("circle", 0.5, 0.65, 1.0, rx=520, ry=200, color="blue"), T(0.5, 0.1, "controlled loss of control", 1.2, "red", underline="red")]),
    S("The danger is pretend. The feelings are real.", "Tehlike sahte. Duygular gerçek.",
      [T(0.3, 0.42, "danger: pretend", 1.2, "blue"), T(0.72, 0.42, "feelings: real", 1.2, "red", underline="red")]),
    S("A match is a story with heroes and villains, a beginning, a middle and an end,", "Bir maç kahramanları ve kötüleri, başı, ortası ve sonu olan bir hikâye;",
      [E("books", 0.5, 0.75, 1.0, n=1), T(0.25, 0.3, "hero", 1.2, "blue"), T(0.75, 0.3, "villain", 1.2, "red")]),
    S("played out live, with nobody knowing the final page.", "canlı oynanıyor ve son sayfayı kimse bilmiyor.",
      [E("scroll", 0.5, 0.45, 1.0, text="the end: ???")]),
    S("It's a safe war, between tribes that go home afterward.", "Ardından herkesin evine döndüğü kabileler arasında güvenli bir savaş.",
      [E("flag", 0.2, 0.85, 0.7, color="red"), E("ball", 0.5, 0.6, 0.8), E("flag", 0.75, 0.85, 0.7, color="blue"), E("house", 0.12, 0.88, 0.4), E("house", 0.9, 0.88, 0.4)]),
    # ------------------------------------------------------------ Kendin dene
    S("Try this. Next time you watch a match, pay attention to one tiny word: *\"we.\"*",
      "Şunu dene. Bir dahaki maç izleyişinde küçücük bir kelimeye dikkat et: *\"biz\"*.",
      [T(0.12, 0.1, "try this", 1.0, "red", underline="red"), E("tv", 0.62, 0.45, 0.8), F(0.22, 0.4, "sit", y=0.78), T(0.35, 0.25, "\"we\"", 1.4, "blue")]),
    S("Notice when you say it, and when you stop saying it.", "Onu ne zaman söylediğini ve ne zaman söylemeyi bıraktığını fark et.",
      [T(0.3, 0.42, "we", 1.8, "blue"), A(0.42, 0.42, 0.58, 0.42, bend=0.0), T(0.72, 0.42, "they", 1.8, "red")]),
    S("Notice how you feel about the referee. Notice your heart rate in the last five minutes.",
      "Hakem hakkında ne hissettiğini fark et. Son beş dakikada kalp atışını fark et.",
      [G(0.85), F(0.25, 0.45, "point", y=0.85), E("ekg", 0.68, 0.45, 0.5, spike=1.5), T(0.68, 0.75, "last 5 minutes", 1.0, "red")]),
    S("You'll be watching two games at once: the one on the field, and the one inside your own head.",
      "Aynı anda iki maç izliyor olacaksın: biri sahada, biri kendi kafanın içinde.",
      [E("tv", 0.3, 0.45, 0.7), T(0.5, 0.45, "+", 2.0), E("head", 0.75, 0.5, 0.55, glow=True)]),
    # ------------------------------------------------------------ Kapanış
    S("We love sport not because it matters, but because it *doesn't*,", "Sporu önemli olduğu için değil, *önemsiz* olduğu halde",
      [E("ball", 0.5, 0.45, 1.6)]),
    S("and yet it lets us feel everything as if it did.", "her şeyi önemliymiş gibi hissettirdiği için seviyoruz.",
      [E("heart", 0.5, 0.42, 1.3)]),
    S("It gives us a tribe without a war, a story without a script, and a reason to hug a stranger.",
      "Bize savaşsız bir kabile, senaryosuz bir hikâye ve bir yabancıya sarılmak için bir sebep veriyor.",
      [G(), F(0.42, 0.5, "hold"), F(0.58, 0.5, "hold", -1), E("line", 0.3, 0.42, x2=0.45, y2=0.42, color="red", w=2.0), E("line", 0.55, 0.42, x2=0.7, y2=0.42, color="blue", w=2.0),
       E("heart", 0.5, 0.15, 0.5)]),
    S("Maybe that's why, three thousand years after Olympia, we're still watching.", "Belki de bu yüzden, Olimpia'dan üç bin yıl sonra hâlâ izliyoruz.",
      [G(0.6), F(0.15, 0.2, "walk", y=0.6), F(0.25, 0.2, "walk", y=0.6), A(0.35, 0.5, 0.5, 0.5, bend=0.0), E("stands", 0.75, 0.9, 0.7), T(0.5, 0.1, "3,000 years later", 1.2, "blue")]),
]

subscribe = dict(after=8, sketch=[dict(el="subscribe", x=0.45, y=0.45, s=1.4), dict(el="arrow", x=0.2, y=0.75, x2=0.33, y2=0.55, color="red", s=1.2)],
                 say={"en": "If you like finding out why we do the strange things we do, *subscribe*. It genuinely helps the channel.",
                      "tr": "Yaptığımız tuhaf şeyleri neden yaptığımızı keşfetmeyi seviyorsan *abone ol*. Kanala gerçekten çok yardımı oluyor."})
meta = {"en": dict(title="Why Do We Love Watching Sports?", description="", tags=[]), "tr": dict(title="Spor İzlemek Neden Keyif Veriyor?", description="", tags=[])}
out = dict(slug="spor", format="long", theme="karakalem", character="none", languages=["en"], subtitles=["tr"],
           voices={"en": "am_fenrir"}, speech_rate=0.88, meta=meta, subscribe=subscribe, scenes=scenes)
json.dump(out, open(os.path.join(HERE, "spor.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
words = sum(len(s["say"]["en"].split()) for s in scenes) + len(subscribe["say"]["en"].split())
print(f"{len(scenes)} sahne, {words} kelime")
