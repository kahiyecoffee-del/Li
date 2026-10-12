# E-posta Altyapısı – Kurulum Kaydı

**Durum (12 Ekim 2026):** Tamamlandı ve test edildi (gönderme + alma çalışıyor).

| Öğe | Değer |
|---|---|
| Alan adı | `bridgelineglobalsourcing.com` (Namecheap, 1 yıl, otomatik yenileme açık, WHOIS gizliliği açık) |
| E-posta servisi | Google Workspace (deneme süresi; eski `bridgelineglobals.com` ana alan adı olarak duruyor, kullanılmıyor) |
| Kullanıcı | `eraysozer@bridgelineglobalsourcing.com` |

## DNS kayıtları (Namecheap → Advanced DNS)

| Tür | Host | Değer | Amaç |
|---|---|---|---|
| TXT | `@` | `v=spf1 include:_spf.google.com ~all` | SPF |
| TXT | `@` | `google-site-verification=...` | Google alan adı doğrulama |
| TXT | `google._domainkey` | `v=DKIM1; k=rsa; p=...` (Google Admin'den) | DKIM (Admin'de "Authenticating email with DKIM") |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:eraysozer@bridgelineglobalsourcing.com` | DMARC (izleme modu) |
| MX (Mail Settings → Custom MX) | `@` | `smtp.google.com` (öncelik 1) | Gelen e-posta |

## Bilinmesi gerekenler
- **Ana alan adı değişikliği:** Workspace deneme süresindeyken ana alan adı değiştirilemiyor. Kullanıcı ikincil alan adına taşındı, bu yeterli. Ücretli plana geçince istenirse Admin → Account → Domains → "Change primary domain".
- **Yenileme:** Namecheap alan adı yenilemesi her yıl otomatik. Kart süresi dolarsa güncelle, yoksa e-posta durur.
- **Yeni alan adını ısıtma:** 1. hafta tanıdıklara normal e-posta; 2. hafta günde 5–10 soğuk e-posta; 3–4. hafta günde 15–25.
- **İleride (isteğe bağlı):** Birkaç hafta sorunsuz gidince DMARC `p=none` → `p=quarantine` yapılabilir.

## E-posta imzası (Gmail uygulaması + mobil web'de ayarlı)
```
Eray Burak Sözer
Founder | Bridgeline Global Sourcing
PPE Sourcing & Sales Representation
WhatsApp: +90 543 684 95 16
eraysozer@bridgelineglobalsourcing.com
```
Not: Masaüstü Gmail imzası ayrıca ayarlanmalı (Gmail → ⚙️ → Tüm ayarlar → İmza). Kopyalarken biçim taşımaması için önce Notlar'a yapıştırıp oradan kopyala.
