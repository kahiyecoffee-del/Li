# Çöp Adam YouTube Kanalı – Video Üretim Hattı

Senaryo (JSON) → çok dilli seslendirme → çöp adam animasyonu → MP4 + altyazı + yükleme notları.
Her şey ücretsiz ve yerel çalışır (API anahtarı gerekmez).

## Kurulum (bir kez)
```bash
./kurulum.sh          # Python paketleri + ses modeli (~350 MB) + ffmpeg kontrolü
```

## Video üretme
```bash
python3 araclar/video_uret.py senaryolar/2-dakika-kurali.json                 # senaryodaki tüm diller
python3 araclar/video_uret.py senaryolar/2-dakika-kurali.json --diller en,es  # sadece bazı diller
python3 araclar/video_uret.py senaryo.json --format long                      # 16:9 uzun video
python3 araclar/video_uret.py senaryo.json --format long --mod coklu          # tek video + dil başına ses kanalı
```
Çıktılar `cikti/<senaryo>/` altına yazılır:
- `*_<dil>.mp4`: altyazısı gömülü video
- `*_<dil>.srt`: YouTube'a ayrıca yüklenecek altyazı
- `*_<dil>_yukleme.txt`: başlık, açıklama ve etiketler

### İki mod
| Mod | Ne üretir | Ne zaman |
|---|---|---|
| `ayri` (varsayılan) | Her dil için ayrı video, altyazı gömülü | Shorts, dil başına ayrı kanal |
| `coklu` | Tek video (yazısız) + her dil için `.m4a` ses + `.srt` | Uzun video: YouTube Studio'da "Ses parçaları" ile aynı videoya dublaj eklemek için |

## Diller ve sesler
| Kod | Dil | Ses |
|---|---|---|
| en | İngilizce | am_michael |
| es | İspanyolca | em_alex |
| pt | Portekizce (BR) | pm_alex |
| fr | Fransızca | ff_siwis |
| hi | Hintçe | hm_omega |
| it | İtalyanca | im_nicola |

Türkçe bu ücretsiz modelde yok. Türkçe için ElevenLabs gibi bir servis eklenebilir.

## Senaryo formatı
```json
{
  "slug": "video-adi", "format": "short", "languages": ["en", "es"],
  "meta": {"en": {"title": "...", "description": "...", "tags": ["..."]}},
  "scenes": [
    {"pose": "talk",
     "props": [{"type": "bulb", "pos": "left", "size": 1.0, "delay": 0.3}],
     "say": {"en": "Narration...", "es": "Narración..."}}
  ]
}
```
**Pozlar:** stand, talk, wave, point_right, point_left, idea, think, shock, celebrate, tired, sad, shrug, walk, run, phone, read
(isteğe bağlı `"expr"`: neutral, happy, sad, shock, tired, confused, think, down)

**Aksesuarlar (`type`):** bigtext, bubble, thought, phone, clock, bulb, brain, book, shoe, mountain, chart_up, check, cross, heart, coin, question, exclaim, zzz, arrow
- `pos`: center, left, right, top, bottom, hand_r, hand_l, hands, head, ya da `[x, y]` (0–1 arası oran)
- `text` tek metin olabilir ya da dil başına sözlük: `{"en": "BIG TASK", "es": "TAREA"}`
- `offset: [dx, dy]`, `color: red|green|blue|yellow`, `delay` (saniye)

## Yükleme kontrol listesi
1. Başlık, açıklama ve etiketleri `_yukleme.txt` dosyasından kopyala.
2. Altyazıyı `.srt` olarak ekle.
3. Seslendirme yapay zekâ ile yapıldığı için YouTube Studio'da istenirse "değiştirilmiş/sentetik içerik" beyanını işaretle.
4. Shorts için dikey (1080×1920) video, uzun video için ayrıca 1280×720 kapak görseli kullan.
