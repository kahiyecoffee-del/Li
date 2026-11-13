# THE BUDGETS: dizi kitabı

Yetişkinlere yönelik, özgün bir aile ve sitcom animasyonu. İngilizce seslendirme, Türkçe altyazı. Her bölüm 8–9 dakika (mid-roll reklam için). Her gün bir bölüm çıkar.

## Fikir
Ohio'daki küçük Lower Fairview kasabasında yaşayan, sürekli batan Budget ailesi. Baba Dale her bölüm yeni bir "zengin olma" planı kurar. Plan felakete döner; felaketi genelde evin akıllı asistanı HOMI ya da kasabanın beceriksiz polisi büyütür.

**Esinlendiğimiz anlatım teknikleri** (karakter, replik ya da sahne kopyalanmadan, yalnızca tür teknikleri):
- **Kesme şakaları (cutaway):** Konuşmanın ortasında alakasız bir geçmiş anıya kısa bir sıçrama. Bizde Büyükbaba Earl'ün "Back in '68..." ile başlayan uydurma anıları.
- **Absürt bilimkurgu tırmanışı:** Küçük bir sorun saniyeler içinde kontrolden çıkar. Bizde HOMI'nin her bölüm biraz daha fazla güç kazanması.
- **Kaba kurum hicvi:** Beceriksiz otorite figürleri. Bizde Memur Gutierrez ve HOA (site yönetimi) savaşları.

## Karakterler
| Karakter | Yaş | Ses | Görünüm | Kişilik |
|---|---|---|---|---|
| **Dale Budget** | 42 | am_michael | Beyaz gömlek, gevşek kırmızı kravat, göbek, kahve perçem, sakal gölgesi | Aşırı özgüvenli. Her planı "bu sefer kesin" diye sunar. İyi kalpli ama aptal. |
| **Tammy Budget** | 40 | af_bella | Sarı küt saç, mor hırka, inci kolye, kırmızı ruj | HOA başkanı. Korkutucu derecede yetkin, kasabayı gizlice o yönetir. Komşu Gary ile savaş halinde. |
| **Kyle Budget** | 16 | am_puck | Yeşil bere, haki kapüşonlu, yarı kapalı gözler, hep telefonda | Nihilist yayıncı. Ailesinin felaketlerini canlı yayınlayıp para kazanır. |
| **Büyükbaba Earl** | 78 | bm_lewis | Kel, yanlarda beyaz saç, kalın gözlük, bıyık, kahve hırka | Her şeyin "gizli" olduğunu söyler. Uydurma anıları kesme şakası olarak gösterilir. |
| **HOMI** | – | af_nova | Masa üstü siyah silindir, konuşurken mavi halka ışığı, sinirlenince kırmızı | Pasif-agresif akıllı ev asistanı. Her bölüm biraz daha güç toplar. |
| **Memur Gutierrez** | 45 | am_eric | Lacivert üniforma, kep, bıyık, göbek | Kasabanın tek polisi. Kendinden çok emin, hiçbir şeyden anlamaz. |

## Mekânlar
Oturma odası, mutfak, Kyle'ın odası, ön bahçe ve sokak. Kesme şakaları için sepya tonlu "geçmiş" mekânları.

## Görsel stil
- Kalın siyah kontur, düz renkler, büyük yuvarlak gözler, abartılı çeneler.
- Karakterler kemikli (rig) 2D kuklalar: dudak senkronu, göz kırpma, jestler, yürüme, nefes alma.
- 24 kare/saniye tam animasyon, sık kamera kesmeleri, yakın, geniş ve ikili planlar.
- Karakter görünüşleri kodda sabit (`araclar/cizgi/karakter.py`), bu yüzden her bölümde birebir aynı kalır.

## Bölüm formatı
1. Soğuk açılış ve ilk şaka.
2. Jenerik kartı.
3. Dale'in planı.
4. Tırmanış (HOMI, Gutierrez, HOA).
5. Felaket.
6. Ders alınmayan bir son ve kapanış şakası.
