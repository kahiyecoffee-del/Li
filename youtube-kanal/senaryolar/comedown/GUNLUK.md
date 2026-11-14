# THE COMEDOWN: günlük bölüm üretim talimatı

Her gün bir yeni bölüm üretilir. Bu dosya, otomatik oturumun izleyeceği adımlardır.

## 1. Kurulum (temiz oturum, ~10-15 dk)
```bash
cd youtube-kanal && bash araclar/cizgi/kurulum.sh   # KURULUM_OK görmelisin
```

## 2. Senaryo
- Önce `senaryolar/comedown/dizi-kitabi.md` dosyasını oku, sonra son 2 bölümün `cNN.txt` dosyalarını oku. Böylece tekrara düşülmez ve süregelen şakalar devam eder.
- Hikâye kaynağı: kullanıcı konuşmada arkadaşının bir hikâyesini paylaştıysa ve henüz kullanılmadıysa ONU uyarla (isimleri/ayrıntıları değiştir). Yoksa dizi-kitabi.md'ye uygun özgün bir hikâye yaz. İçerik kurallarına (18+, ayrıntısız, özendirmesiz) kesinlikle uy.
- Yeni bölümü `senaryolar/comedown/cNN.txt` olarak yaz; NN, bir sonraki numaradır. Biçim `c01.txt` ile birebir aynı olmalı (VO satırları dahil).
- Hedef uzunluk 165–172 replik: çıktı 10–15 dakika olur.
- Yapı:
  1. Soğuk açılış.
  2. `@title THE COMEDOWN`.
  3. Dale'in yeni planı.
  4. Tırmanış.
  5. En az 2 kesme şakası (`@cutaway`).
  6. Felaket.
  7. Kapanış şakası, `@sfx rimshot`, `@title`.
- Kullanılabilir karakterler: `dale tammy kyle earl homi officer gary mayor jace`, dekorlar: `jukebox toaster toaster2`.
- Kullanılabilir mekânlar: `living kitchen kyle_room lawn chapel snow street diner police garage office school townhall`. Yeni mekân ya da dekor gerekirse `araclar/cizgi/mekan.py` dosyasına ekle; kesme şakası yazısını `motor.py` içindeki `CUT_CAPTION`'a ekle.
- Kurallar:
  - Özgün içerik yaz. Başka dizilerin karakterlerini, repliklerini ya da sahnelerini kullanma.
  - Gerçek marka ya da kişi adı kullanma.
  - Türkçe çeviriyi `||` işaretinden sonra yaz.

## 3. Üretim
```bash
cd youtube-kanal && araclar/cizgi/uret.sh comedown cNN   # ses + render + sıkıştırma + 6 Shorts + disk temizliği; URETDONE
```
- Süre 600 saniyenin altındaysa senaryoya replik ya da `@beat` ekle ve yeniden üret.
- Kullanım tasarrufu: alt ajan kullanma, senaryoyu kendin yaz; tek bir kontrol görseli (6 kare birleştirilmiş) yeter; ara durum mesajı gönderme.
- Kapak üretmek için: `python3 araclar/cizgi/kapak.py cNN --series comedown "BAŞLIK METNİ"`.
- Shorts klip listesi (`cNN_shorts.json`) üretimden ÖNCE yazılmış olmalı: 6 klip, her biri 7–10 replik, 60 sn altı.
- `cikti/comedown/cNN/youtube_bilgileri.txt` dosyasını yaz: EN başlık, açıklama, etiketler, TR başlık.

## 4. Teslim
- Dosya 100 MB'tan büyükse 2 geçişte sıkıştır.
- `git add -f cikti/comedown/cNN/cNN_yt.mp4 cikti/comedown/cNN/*.srt cikti/comedown/cNN/shorts/*.mp4 cikti/comedown/cNN/kapak.png cikti/comedown/cNN/youtube_bilgileri.txt senaryolar/comedown/` Commit at ve `claude/confident-maxwell-wmenav` dalına pushla.
- Kullanıcıya şunları kopyalanabilir olarak gönder:
  - GitHub raw linkleri (mp4, en.srt, tr.srt, kapak)
  - Başlık
  - Açıklama
  - Etiketler
