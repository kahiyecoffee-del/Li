#!/usr/bin/env python3
"""DEAD QUOTA pilot ("QUOTA") çekim listesi -> senaryolar/dizi_pilot.json

Her çekim:
  id, prompt (özne önce, kısa; stil bloğu gorsel_uret.py'de eklenir), ref (karakter referansı: moss/jessie/bruno/adler/rotter/None),
  cam (zoom_in / zoom_out / pan_left / pan_right / tilt_up / shake / still), lines [(kim, EN, TR)], sfx, min_dur (sn)
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# Mekânlar (kısa, sabit)
SUBURB = "abandoned American suburban street at sunset, overgrown lawns, red-orange sky"
VAN = "inside an armored white-and-teal transport van, bench seats, weapon racks, warm amber light"
MALL = "abandoned 90s shopping mall food court, flickering neon signs, overturned tables, dusty skylight"
SANTA = "abandoned mall Santa's grotto, broken Christmas decorations, red velvet throne, cold blue light"
STORE = "dark sporting goods store stockroom, barricaded with shelves, flashlight beams"
GARAGE = "mall parking garage at dusk, concrete pillars, abandoned cars"
VAN_NIGHT = "inside an armored transport van at night, dim blue light, sleeping family on benches"
DEPOT = "industrial warehouse at night, rows of teal shipping containers, harsh white floodlights, cold blue shadows"
OFFICE = "bright clean corporate office with a large window, white furniture, teal logo on the wall"

# Karakter kısa kimlikleri (tarife eklenecek; IP-Adapter ile birlikte)
MOSS = "44 year old Black man, yellow hard hat, short grey beard, dark navy vest with yellow stripes"
JESSIE = "young Vietnamese-American woman, short black bob with teal streak, white helmet with phone on top, purple hoodie, navy vest"
BRUNO = "huge heavy older white man, short white beard, red knitted beanie, green flannel, navy vest"
ADLER = "blonde woman executive in white blazer, sleek bun, headset, wide smile"
ROTTER = "zombie with grey-green skin and cloudy yellow eyes"


def S(id, prompt, ref=None, cam="zoom_in", lines=(), sfx=None, min_dur=3.0):
    return dict(id=id, prompt=prompt, ref=ref, cam=cam, lines=[dict(who=w, en=e, tr=t) for w, e, t in lines], sfx=sfx, min_dur=min_dur)


shots = [
    # ---------------- SOĞUK AÇILIŞ
    S("c01", f"wide shot, {SUBURB}, a lone zombie mowing a lawn with one arm, long shadows, eerie calm", None, "pan_right", sfx="mower", min_dur=4),
    S("c02", f"low angle medium shot of a {ROTTER}, suburban dad in torn polo shirt pushing a red lawn mower, sunset backlight", "rotter", "zoom_in", sfx="mower", min_dur=3),
    S("c03", f"over-the-shoulder shot from behind a {JESSIE}, phone screen showing a live stream, a zombie on a lawn in the distance, {SUBURB}", "jessie", "still",
      [("jessie", "Okay chat, we're live. Look at this guy.", "Tamam chat, yayındayız. Şu adama bakın."),
       ("jessie", "Three years dead and he still mows his lawn. That's more than my dad ever did.", "Üç yıldır ölü, hâlâ çimini biçiyor. Babam hayatında bu kadarını yapmadı.")]),
    S("c04", f"close-up of a {MOSS}, unimpressed tired expression, warm sunset side light", "moss", "zoom_in", [("moss", "Phone down, Vo.", "Telefonu indir, Vo.")]),
    S("c05", f"close-up of a {JESSIE}, whispering excitedly, grinning, sunset rim light", "jessie", "zoom_in",
      [("jessie", "Moss, we're at four hundred viewers. The algorithm loves commuters.", "Moss, dört yüz izleyicideyiz. Algoritma commuter'lara bayılıyor.")]),
    S("c06", f"close-up of a {MOSS}, deadpan, looking at the zombie", "moss", "still", [("moss", "The algorithm doesn't bleed.", "Algoritma kanamıyor.")]),
    S("c07", f"medium shot of a {ROTTER} slowly turning his head toward camera, grass falling from his open mouth, menacing, sunset", "rotter", "zoom_in", sfx="growl", min_dur=3),
    S("c08", f"low angle dynamic shot of a {MOSS} raising a red fire axe overhead with both hands, sunset sky, dramatic silhouette edge light", "moss", "shake",
      [("moss", "Sorry, buddy. Lawn looks great.", "Kusura bakma dostum. Çimler harika görünüyor.")], sfx="axe"),
    S("c09", "black screen with the title DEAD QUOTA in bold distressed red comic lettering", None, "still", sfx="sting", min_dur=3.5),
    # ---------------- KAMYONET
    S("v01", f"wide shot, {VAN}, three crew members sitting on benches, a small radio screen glowing", None, "pan_left", min_dur=3),
    S("v02", f"close-up of a dashboard radio screen showing a {ADLER}, cheerful", "adler", "zoom_in",
      [("adler", "Good morning, Team Eleven! Happy Double Bonus Saturday!", "Günaydın Onbirinci Ekip! Mutlu Çift Prim Cumartesileri!"),
       ("adler", "Every confirmed Rotter is worth twice the points this weekend. Remember: a clean zone is a happy zone!", "Bu hafta sonu doğrulanmış her Rotter iki kat puan. Unutmayın: Temiz bölge, mutlu bölge!")], sfx="radio"),
    S("v03", f"medium shot of a {JESSIE} sitting in a van, amused, pointing at the radio, {VAN}", "jessie", "still",
      [("jessie", "I love her. She sounds like a yogurt commercial.", "Bu kadına bayılıyorum. Yoğurt reklamı gibi konuşuyor.")]),
    S("v04", f"medium shot of a {MOSS} sitting in a van, arms crossed, sour expression, {VAN}", "moss", "zoom_in",
      [("moss", "She sounds like a hostage negotiator. For the kidnapper.", "Bir rehine müzakerecisi gibi konuşuyor. Kaçıranın tarafında.")]),
    S("v05", f"close-up of a dashboard radio screen showing a {ADLER}, smiling", "adler", "still",
      [("adler", "Today's target: Pinecrest Mall. Estimated two hundred commuters. Quota: one-eighty.", "Bugünkü hedef: Pinecrest AVM. Tahminen iki yüz commuter. Kota: yüz seksen."),
       ("adler", "Fall below quota and, well... you know the policy!", "Kotanın altında kalırsanız... e, politikayı biliyorsunuz!")], sfx="radio"),
    S("v06", f"two shot, {JESSIE} whispering to a {BRUNO} in a van, {VAN}", "jessie", "still", [("jessie", "What's the policy?", "Politika ne?")]),
    S("v07", f"close-up of a {BRUNO}, grim quiet expression, staring ahead, {VAN}", "bruno", "zoom_in",
      [("bruno", "We don't talk about Team Nine.", "Dokuzuncu Ekip'ten bahsetmiyoruz.")], min_dur=3.5),
    # ---------------- AVM YEMEK KATI
    S("m01", f"wide shot, {MALL}, dozens of zombies standing in a neat line in front of a closed burger counter", None, "pan_right", sfx="growl", min_dur=4),
    S("m02", f"medium shot of a {JESSIE} filming with her phone, shocked and delighted, {MALL}", "jessie", "zoom_in",
      [("jessie", "Oh my God. They're waiting in line. Chat, they're still waiting in line.", "Aman Tanrım. Sırada bekliyorlar. Chat, hâlâ sırada bekliyorlar.")]),
    S("m03", f"medium shot of a {MOSS} holding a fire axe, dry expression, {MALL}", "moss", "still",
      [("moss", "Some things survive the apocalypse. Brand loyalty's one of them.", "Bazı şeyler kıyametten sağ çıkar. Marka sadakati de onlardan biri.")]),
    S("m04", f"medium shot of a {BRUNO}, nostalgic look at the burger counter, {MALL}", "bruno", "still",
      [("bruno", "I waited forty minutes there once. For the fish sandwich.", "Bir keresinde orada kırk dakika bekledim. Balıklı sandviç için."),
       ("moss", "Was it worth it?", "Değdi mi?"), ("bruno", "...No.", "...Hayır.")]),
    S("m05", f"dynamic action shot of a {BRUNO} swinging a steel crowbar into a crowd of zombies, speed lines, stylized comic gore, {MALL}", "bruno", "shake", sfx="hit", min_dur=2.5),
    S("m06", f"dynamic action shot of a {MOSS} swinging a fire axe at a zombie, motion blur, stylized comic gore, {MALL}", "moss", "shake", sfx="axe", min_dur=2.5),
    S("m07", f"medium shot of a {JESSIE} dodging a zombie while filming, laughing nervously, {MALL}", "jessie", "shake",
      [("jessie", "Okay, that one had braces. Who gets braces in the apocalypse? That's optimism!", "Tamam, şunun diş teli vardı. Kıyamette kim diş teli taktırır? Buna iyimserlik denir!")], sfx="growl"),
    S("m08", f"close-up of a zombie hand smashing a smartphone, cracked screen, {MALL}", "rotter", "shake", sfx="crack", min_dur=2),
    S("m09", f"close-up of a {JESSIE} screaming in horror at her broken phone", "jessie", "zoom_in",
      [("jessie", "My phone! Not the phone! I have sponsors!", "Telefonum! Telefona dokunma! Sponsorlarım var!")]),
    # ---------------- NOEL BABA KÖŞESİ
    S("s01", f"wide shot, {SANTA}, eerie silence, a small child zombie standing alone in front of the throne holding a faded wish list", None, "zoom_in", min_dur=4),
    S("s02", f"medium shot of a {JESSIE}, hesitant and sad, cold blue light, {SANTA}", "jessie", "still", [("jessie", "Bruno... you want me to...", "Bruno... ister misin ben...")]),
    S("s03", f"close-up of a {BRUNO}, heartbroken but calm, cold blue light", "bruno", "zoom_in", [("bruno", "No. I've got this one.", "Hayır. Bunu ben hallederim.")]),
    S("s04", f"medium shot of a {BRUNO} kneeling down gently in front of a small child zombie, back view, {SANTA}", "bruno", "zoom_in", sfx="lullaby", min_dur=4.5),
    S("s05", "close-up of a dim golden star on top of a broken Christmas tree, cold blue light, silence", None, "tilt_up", sfx="thud", min_dur=3.5),
    S("s06", f"close-up of a {BRUNO} holding a faded child's wish list with a drawing of a bicycle", "bruno", "still",
      [("bruno", "He wanted a bike.", "Bisiklet istemiş."), ("moss", "Yeah.", "Evet.")], min_dur=4),
    # ---------------- DEPO / HAYATTA KALANLAR
    S("r01", f"medium shot, {STORE}, a frightened mother with two children and an old man hiding behind shelves", None, "zoom_in", min_dur=3.5),
    S("r02", f"medium shot of a {MOSS} speaking into a shoulder radio, serious, {STORE}", "moss", "still",
      [("moss", "Halcyon, Team Eleven. We have survivors. Four civilians. Requesting evac.", "Halcyon, burası Onbirinci Ekip. Hayatta kalanlar var. Dört sivil. Tahliye istiyoruz.")], sfx="radio"),
    S("r03", f"close-up of a {ADLER} on a screen, polite smile, {OFFICE}", "adler", "zoom_in",
      [("adler", "Ooh. That's awkward. Survivors aren't really in this quarter's KPIs, Marcus.", "Ooo. Bu biraz garip oldu. Hayatta kalanlar bu çeyreğin KPI'larında pek yok, Marcus.")], sfx="radio"),
    S("r04", f"close-up of a {MOSS}, controlled anger", "moss", "zoom_in", [("moss", "They're people.", "Bunlar insan.")]),
    S("r05", f"medium shot of a {ADLER} in her office, cheerful, giving a thumbs up, {OFFICE}", "adler", "still",
      [("adler", "And people are wonderful! But evacuation is a separate contract.", "İnsanlar harikadır! Ama tahliye ayrı bir kontrat."),
       ("adler", "Please complete your quota and seal the east doors on your way out. Great energy today, team!", "Lütfen kotanızı tamamlayın ve çıkarken doğu kapılarını mühürleyin. Bugün enerjiniz harikaydı ekip!")], sfx="radio"),
    S("r06", f"medium shot of a {JESSIE}, stunned, {STORE}", "jessie", "zoom_in",
      [("jessie", "Did she just tell us to lock a family in a zombie mall?", "Az önce bize bir aileyi zombi dolu bir AVM'ye kilitlememizi mi söyledi?")]),
    S("r07", f"medium shot of a {BRUNO}, deadpan, {STORE}", "bruno", "still", [("bruno", "She said it with a smile, though.", "Ama gülümseyerek söyledi.")]),
    S("r08", f"extreme close-up of a {MOSS} switching off a radio, determined", "moss", "zoom_in", sfx="click", min_dur=3),
    S("r09", f"two shot, {MOSS} and {JESSIE}, {STORE}", "moss", "still",
      [("moss", "Vo. How many people are watching your stream?", "Vo. Yayınını kaç kişi izliyor?"),
       ("jessie", "With the cracked screen? Like... eleven thousand.", "Çatlak ekranla mı? Şey... on bir bin."),
       ("moss", "Good. Keep it on them.", "Güzel. Kamerayı onlara çevir.")]),
    # ---------------- KAÇIŞ
    S("e01", f"dynamic action shot, the crew escorting a family through the mall, zombies closing in, {MALL}", None, "pan_right", sfx="growl", min_dur=3),
    S("e02", "close-up of a cracked phone screen showing a live stream with chat comments flying: IS THIS REAL, HALCYON LEFT THEM", None, "zoom_in", sfx="ping", min_dur=3),
    S("e03", f"dynamic action shot of a {BRUNO} ramming zombies with a shopping cart like a battering ram, {MALL}", "bruno", "shake",
      [("bruno", "Excuse me. Pardon. Excuse me.", "Pardon. Affedersiniz. Pardon.")], sfx="hit"),
    S("e04", f"wide shot, {GARAGE}, the family climbing into an armored white-and-teal van, the crew covering them", None, "zoom_out", sfx="door", min_dur=3.5),
    # ---------------- GECE
    S("n01", f"wide shot, {VAN_NIGHT}, the crew sitting exhausted", None, "zoom_in", min_dur=3.5),
    S("n02", "close-up of a cracked phone screen showing 1.2M views", None, "zoom_in", min_dur=2.5),
    S("n03", f"close-up of a {JESSIE}, pale and quiet, blue night light", "jessie", "still",
      [("jessie", "One point two million. That's the most I've ever had.", "Bir virgül iki milyon. Bu şimdiye kadarki en yüksek sayım.")]),
    S("n04", f"close-up of a {MOSS}, tired, blue night light", "moss", "still",
      [("moss", "How's it feel?", "Nasıl hissettiriyor?"), ("jessie", "Like I want to throw up.", "Kusmak istiyormuşum gibi."), ("moss", "Welcome to the job.", "İşe hoş geldin.")]),
    S("n05", f"close-up of a dashboard radio screen showing a {ADLER}, not smiling, cold", "adler", "zoom_in",
      [("adler", "Marcus. That stream was... unfortunate. Your team has been reassigned. Tomorrow, Sector Four.", "Marcus. O yayın... talihsizdi. Ekibinin görev yeri değişti. Yarın Dördüncü Sektör.")], sfx="radio"),
    S("n06", f"close-up of a {BRUNO}, suspicious, blue night light", "bruno", "still", [("bruno", "Sector Four was cleared last year.", "Dördüncü Sektör geçen yıl temizlenmişti.")]),
    S("n07", f"close-up of a dashboard radio screen showing a {ADLER}, big fake smile", "adler", "still",
      [("adler", "Not anymore! Sleep well, Team Eleven!", "Artık değil! İyi uykular Onbirinci Ekip!")], sfx="radio"),
    # ---------------- SON SAHNE
    S("x01", f"wide shot, {DEPOT}, long corridor", None, "zoom_in", sfx="drone", min_dur=4),
    S("x02", f"medium shot, {DEPOT}, a forklift loading a teal container, shadows of zombie hands pressing against the container vents", None, "pan_left", sfx="growl", min_dur=4),
    S("x03", "close-up of a label on a teal shipping container reading SECTOR 4: RESTOCK, harsh white light", None, "zoom_in", sfx="sting", min_dur=3.5),
    S("x04", "black screen with a clean teal corporate logo and the slogan Tomorrow, safer.", None, "still", sfx="jingle", min_dur=4),
]

out = dict(slug="dead-quota-pilot", title="DEAD QUOTA · Episode 1: Quota",
           voices={"moss": "am_onyx", "jessie": "af_nicole", "bruno": "bm_george", "adler": "af_heart"}, shots=shots)
json.dump(out, open(os.path.join(HERE, "dizi_pilot.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(shots), "çekim,", sum(len(s["lines"]) for s in shots), "replik")
