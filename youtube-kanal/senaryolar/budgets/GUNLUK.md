# THE BUDGETS: günlük bölüm üretim talimatı

Her gün bir yeni bölüm üretilir. Bu dosya, otomatik oturumun izleyeceği adımlardır.

## 1. Kurulum (temiz konteynerde)
```bash
cd youtube-kanal
pip install pycairo kokoro-onnx soundfile numpy
mkdir -p /home/user/models && cd /home/user/models
for f in kokoro-v1.0.onnx voices-v1.0.bin; do
  [ -f $f ] || curl -sSL -o $f https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/$f
done
```

## 2. Senaryo
- Önce `senaryolar/budgets/dizi-kitabi.md` dosyasını oku, sonra son 2 bölümün `bNN.txt` dosyalarını oku. Böylece tekrara düşülmez ve süregelen şakalar devam eder.
- O haftanın gündemindeki bir trendi/tartışmayı seç (WebSearch ile kontrol et); son 5 bölümde işlenmemiş olsun. Yapay zekâ konusu en fazla 6 bölümde 1.
- Yeni bölümü `senaryolar/budgets/bNN.txt` olarak yaz; NN, bir sonraki numaradır. Biçim `b01.txt` ile birebir aynı olmalı.
- Hedef uzunluk 165–185 replik: çıktı 10–15 dakika olur.
- Yapı:
  1. Soğuk açılış.
  2. `@title THE BUDGETS`.
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
cd youtube-kanal
KOKORO_DIR=/home/user/models python3 araclar/cizgi/motor.py senaryolar/budgets/bNN.txt
ffmpeg -v error -i cikti/budgets/bNN/bNN.mp4 -f null -      # hata çıkmamalı
ffprobe -v error -show_entries format=duration -of csv=p=0 cikti/budgets/bNN/bNN.mp4   # 600–900 sn olmalı
```
- Süre 600 saniyenin altındaysa senaryoya replik ya da `@beat` ekle ve yeniden üret.
- 4–5 kontrol karesi çıkar (`ffmpeg -ss T -frames:v 1`) ve görsel olarak kontrol et.
- Kapak üretmek için: `python3 araclar/cizgi/kapak.py bNN "BAŞLIK METNİ"`.
- `cikti/budgets/bNN/youtube_bilgileri.txt` dosyasını yaz: EN başlık, açıklama, etiketler, TR başlık.

## 4. Teslim
- Dosya 100 MB'tan büyükse 2 geçişte sıkıştır.
- `git add -f cikti/budgets/bNN/*.mp4` ve diğer dosyaları ekle. Commit at ve `claude/confident-maxwell-wmenav` dalına pushla.
- Kullanıcıya şunları kopyalanabilir olarak gönder:
  - GitHub raw linkleri (mp4, en.srt, tr.srt, kapak)
  - Başlık
  - Açıklama
  - Etiketler
