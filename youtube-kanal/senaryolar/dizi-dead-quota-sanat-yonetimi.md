# DEAD QUOTA: Sanat Yönetimi Rehberi (DEĞİŞTİRİLEMEZ)

> Bu belge projenin görsel stil anayasasıdır. Bütün karakter, mekân, storyboard ve kare üretimleri buna bağlıdır.
> **Referans görsel:** Kullanıcının gönderdiği referans (yetişkin süper kahraman animasyonundan bir kare; telifli olduğu için repoya eklenmedi). Referans yalnızca **stil** içindir; o yapımın karakterleri, kostümleri ve logoları kullanılmaz. Tariflerde yapımın adı geçmez, stil özellikleri tarif edilir.

## 0. Referanstan çıkarılan stil özellikleri (bağlayıcı)
- **Kontur:** Koyu kahve-siyah (#1E1814), orta kalınlıkta, neredeyse sabit kalınlıkta, temiz ve tek geçişli çizgi. Uç incelmesi çok az. İç detay çizgileri dış konturdan daha ince.
- **Cel shading:** Tek gölge tonu: aynı rengin daha koyu ve hafif soğuk versiyonu, sert kenarlı, büyük ve sade gölge şekilleri. Yüzde çene altı, burun yanı, göz çukuru ve saç altı gölgeleri. Parlama (highlight) neredeyse yok; sadece gözlük ve metal gibi yansıtıcı yüzeylerde beyaz düz şekil.
- **Yüz yapısı:** Gerçekçi oranlar, sade özellikler. Burun, bir çizgi ve bir gölge şekliyle; ağız kısa tek çizgiyle; gözler küçük ve sade. Kaşlar düz şekiller. Abartılı anime gözü yok.
- **Renk:** Karakterlerde düz, doygun renkler (ana kostüm renkleri parlak), ten tonlarında 2 ton (ışık ve gölge).
- **Arka planlar:** Karakterlerden farklı olarak daha **boyalı ve dokulu**, detaylı, hafif sisli, atmosferik perspektif. Genellikle soğuk ve daha az doygun tonlar; karakterler arka plandan net ayrılıyor.
- **Işık ve grade:** Sahne ışığı genel renk tonunu belirliyor (gece = mavi-camgöbeği ton). Hafif atmosferik pus, buhar ve duman efektleri yumuşak ve yarı saydam.
- **Kompozisyon:** TV dizisi karesi gibi; karakter kadrajı net, sinematik derinlik.

## 1. Temel görsel kimlik
- Yüksek kaliteli Amerikan yetişkin animasyonu. 2D çizgi roman estetiği.
- Gerçekçi anatomik oranlar. Belirgin, temiz, kontrollü konturlar.
- Cel shading. Sinematik ışık. Canlı ve doygun renkler.
- Detaylı ve perspektifi güçlü arka planlar. Profesyonel TV animasyonu kalitesi.
- **Olmayacaklar:** Çocuk çizgi filmi, anime, Pixar/Disney tarzı 3D, fotogerçekçilik.

## 2. Karakter kuralları
Sabit yüz anatomisi, tutarlı göz ve burun yapısı, sabit saç, tutarlı vücut oranları, kendine özgü kıyafet. Farklı açılarda aynı görünüm, duyguya uygun ifadeler. **Bir tasarım onaylandıktan sonra değişmez.**

## 3. Renk ve ışık
Flat color ve cel shading. Gölgeler belirgin ama karakterler basit görünmez. Gece sahneleri soğuk mavi; gündüz sahneleri doğal ve sıcak; gün batımı kırmızı-turuncu.

## 4. Kamera
Close-up, medium, wide, low angle, high angle, over-the-shoulder, dinamik aksiyon. Her kare gerçek bir dizi karesi gibi görünmeli.

## 5. Continuity (en önemli kural)
Karakterlerin yüzü, saçı, kıyafeti ve fiziksel özellikleri; mekânlar ve renk paleti sahneler arasında değişmez.

## 6. Kaçınılacaklar
Anime, 3D render görünümü, plastik cilt, aşırı basit çocuk estetiği, suluboya/pastel, ince ve kararsız çizgiler, karede karede değişen yüz, rastgele palet, fotogerçekçilik.

---

# ÜRETİM SİSTEMİ: Continuity nasıl korunur?

1. **Önce karakter sayfaları (model sheet) üretilir.** Her karakter için önden, 3/4 ve yandan görünüm ile 4 ifade. Onaylanan görsel `cikti/dizi/karakterler/` klasörüne kaydedilir. Bu görsel o karakterin **kanonik referansı** olur.
2. **Her kare tarifi üç sabit bloktan oluşur:**
   - `[STYLE]`: Aşağıdaki sabit stil bloğu, her seferinde kelimesi kelimesine aynı.
   - `[CHARACTER]`: Karakterin sabit kimlik bloğu, kelimesi kelimesine aynı.
   - `[SHOT]`: Sadece o kareye özel kısım: açı, eylem, ifade, ışık.
3. **Görsel üretim aracında karakter referansı kullanılır.** Midjourney'de `--cref` / `--sref`, ChatGPT/Gemini'de "bu karakter sayfasındaki karakteri kullan" diyerek referans görsel eklenir. Onaylı model sheet her karede referans olarak verilir.
4. **Kontrol listesi:** Ben her kareyi model sheet ile karşılaştırırım (saç, yara izi, kıyafet rengi, aksesuar). Tutmayan kare yeniden üretilir.

## [STYLE] Sabit stil bloğu (her tarifin başına, değiştirmeden)
```
Frame from a high-end American adult animated TV series. 2D hand-drawn animation look with realistic human proportions. Clean, confident dark brown-black outlines of medium, almost uniform weight; thinner interior detail lines. Flat saturated base colors with a single hard-edged cel-shading tone per color (a darker, slightly cooler version of the base), large simple shadow shapes under the jaw, beside the nose, in the eye sockets and under the hair; almost no highlights except small flat white shapes on glasses and metal. Simple, realistic facial features: small eyes, nose drawn with one line and one shadow shape, short single-line mouth. Background is more painterly and textured than the characters, detailed with atmospheric perspective and slight haze, cooler and less saturated so the characters pop. Cinematic lighting that tints the whole frame. 16:9 TV frame.
```

## Negatif blok (aracın desteklediği yerde)
```
anime, manga, chibi, big anime eyes, Pixar, Disney, 3D render, CGI, soft gradient shading, airbrush, glossy highlights on skin, plastic skin, photorealistic, photograph, watercolor, pastel, sketchy thin lines, children's cartoon, simplified kids style, superhero costume, mask, inconsistent face, extra fingers, text artifacts, watermark
```

---

# KARAKTER KİMLİK BLOKLARI (sabit, kelimesi kelimesine)

## MOSS: Marcus "Moss" Okafor
```
[CHARACTER: MOSS] Marcus "Moss" Okafor, 44-year-old Black man, 6'1", broad shoulders, lean muscular build; square jaw, short salt-and-pepper beard and stubble, shaved head under helmet, tired heavy-lidded dark brown eyes, thick straight eyebrows, broad nose, a thin vertical scar through his left eyebrow; wears a scuffed yellow hard hat with a black brim and a crack on the right side, dark navy Halcyon tactical vest with yellow reflective stripes and an orange "11" patch on the left chest, charcoal long-sleeve shirt, black work gloves, dark cargo pants, brown work boots; carries a red fire axe with a worn wooden handle (named "Linda"). Palette: navy #26303C, hard hat yellow #E8AC28, skin #8A5A3C.
```

## JESSIE: Jessie Vo
```
[CHARACTER: JESSIE] Jessie Vo, 23-year-old Vietnamese-American woman, 5'4", slim athletic build; oval face, bright expressive dark eyes, small nose, black hair in a messy short bob with a streak of teal on the right side; wears a white bike-style helmet with a smartphone mounted on top (screen cracked in later scenes), purple oversized hoodie with rolled sleeves under a dark navy Halcyon vest with yellow stripes and an orange "11" patch, black fingerless gloves, ripped black jeans, white high-top sneakers with teal laces; holds a selfie stick ring light clipped to her vest. Palette: purple #5A2C6E, teal #2FB3A5, navy #26303C.
```

## BRUNO: Bruno Kasparek
```
[CHARACTER: BRUNO] Bruno Kasparek, 56-year-old white man of Czech descent, 6'6", huge heavy build with a big belly and very broad shoulders; round gentle face, full white beard trimmed short, bald head with a horseshoe of white hair, small kind pale blue eyes, rosy cheeks, bulbous nose; wears a faded red knitted beanie, dark navy Halcyon vest stretched over a dark green flannel shirt, thick leather work apron, heavy brown boots; carries a long steel crowbar. Palette: red #A8322B, flannel green #2F4A33, navy #26303C.
```

## DR. PAIGE ADLER ("Handler")
```
[CHARACTER: ADLER] Dr. Paige Adler, 38-year-old white woman, 5'7", slim; sharp angular face, perfectly symmetrical bright smile showing teeth, cold pale grey eyes, platinum blonde hair in a sleek low bun, thin wireless headset microphone; wears an immaculate white blazer with a small teal Halcyon logo pin, light grey silk blouse, slim black trousers; always in a clean bright corporate office with a large window. Palette: white #F2F2F0, teal #2FB3A5, grey #B9BEC4.
```

## ROTTER (zombi) kuralları
```
[CHARACTER: ROTTER] Infected human "Rotter": grey-green desaturated skin #7C8A6A with dark purple bruising, cloudy pale yellow eyes with no pupils, visible veins, torn everyday clothes from their old life (office wear, suburban clothes, fast-food uniforms), stylized comic-book gore only (dark red #6E1418, no realistic viscera), slow hunched posture.
```

## Halcyon marka kimliği
```
Halcyon Recovery corporate branding: teal #2FB3A5 circular logo with a stylized white sunrise, slogan "Tomorrow, safer." in clean sans-serif, armored white-and-teal vans.
```

---

# MEKÂN KİMLİK BLOKLARI

```
[LOCATION: SUBURB] Abandoned American suburban street at sunset, identical two-story houses with dark windows, overgrown lawns, abandoned cars, a large Halcyon billboard "Tomorrow, safer.", red-orange sky with purple clouds.
```
```
[LOCATION: VAN] Interior of an armored Halcyon transport van, white-and-teal metal walls, bench seats, weapon racks, a small dashboard radio screen showing Adler's face, warm amber interior light.
```
```
[LOCATION: MALL] Pinecrest Mall food court, abandoned, flickering neon signs, a closed burger counter "BIG BITE BURGERS", overturned tables, skylight with dusty sunbeams, teal and pink 90s mall decor.
```
```
[LOCATION: SANTA] Pinecrest Mall Santa's grotto, broken Christmas decorations, a red velvet Santa throne, fake snow, a dim golden star on top, cold blue light.
```
```
[LOCATION: WAREHOUSE] Halcyon facility at night, long industrial corridor, rows of teal shipping containers with Halcyon logos, harsh white floodlights, cold blue shadows.
```

---

# ADIM 1: KARAKTER SAYFASI TARİFLERİ (önce bunlar üretilecek)

Her karakter için aynı yapı kullanılacak:
```
[STYLE] + [CHARACTER: X] + Character model sheet on a plain light grey background: full body front view, 3/4 view and side view, plus four head close-ups showing neutral, angry, laughing and terrified expressions. Consistent design across all views. Clean turnaround sheet for an animation production.
```
Üretim sırası: MOSS → JESSIE → BRUNO → ADLER → ROTTER (3 örnek: banliyö babası, fast-food çalışanı, ofis kadını).

---

# ADIM 2: PİLOT SOĞUK AÇILIŞ, ÇEKİM LİSTESİ (ilk 8 kare)

| # | Açı | [SHOT] bloğu |
|---|---|---|
| 1 | Wide, establishing | `[LOCATION: SUBURB] Wide shot, empty street at sunset, a lone Rotter in a polo shirt mowing a lawn with one arm missing, the mower idling, long shadows. Eerie calm.` |
| 2 | Medium, low angle | `[CHARACTER: ROTTER] suburban dad in a torn polo shirt and khakis, low angle medium shot pushing a red lawn mower, cloudy yellow eyes, grass stuck to his chin, sunset backlight.` |
| 3 | Over-the-shoulder | `Over-the-shoulder shot from behind [CHARACTER: JESSIE], her phone screen in the foreground showing a live stream "LIVE 400" with chat comments, the Rotter in the background on the lawn.` |
| 4 | Close-up | `[CHARACTER: JESSIE] close-up, whispering excitedly to her phone camera, wide grin, sunset rim light on her face.` |
| 5 | Close-up | `[CHARACTER: MOSS] close-up, tired unimpressed expression, eyes half-closed, warm sunset side light, hard shadow on the left side of his face.` |
| 6 | Medium | `[CHARACTER: ROTTER] suburban dad slowly turning his head toward camera, grass falling from his open mouth, menacing.` |
| 7 | Low angle, dynamic | `[CHARACTER: MOSS] low angle dynamic shot, raising the red fire axe overhead with both hands, sunset sky behind, dramatic silhouette edge light.` |
| 8 | Title card | `Black screen with the title "DEAD QUOTA" in bold distressed red comic lettering, a single drip of red.` |

**Animasyon tarafı (bende):** Her karede katman ayırma (karakter / arka plan), parallax kamera hareketi, ağız animasyonu, göz kırpma, ışık titremesi, sesler (Moss: am_onyx, Jessie: af_nicole, Bruno: bm_george, Adler: af_heart), müzik, efektler (çim biçme makinesi, balta, hırıltı), altyazı ve Shorts.
