# iOS TestFlight: Mac olmadan kurulum

Bu rehber Dayly'yi iPhone'una TestFlight ile kurman içindir. Her şey telefondan
yapılabilir. Anahtarları **sohbete asla yapıştırma**; yalnızca GitHub Secrets'a gir.

## 1. Apple Developer Program (yıllık 99 $)
1. App Store'dan **Apple Developer** uygulamasını indir.
2. Apple ID'nle gir → **Account → Enroll Now** → bireysel (Individual) kayıt.
3. Onay e-postasını bekle (genelde birkaç saat, en fazla 48 saat).
4. developer.apple.com → Account → **Membership details** sayfasındaki
   **Team ID**'yi not al (10 karakter, ör. `AB12CD34EF`).

## 2. Kimlikler (Safari, developer.apple.com → Certificates, IDs & Profiles → Identifiers)
1. **+** → **App Groups** → Identifier: `group.com.dayly.app` → Register.
2. **+** → **App IDs** → App → Bundle ID (Explicit): `com.dayly.app`
   - Capabilities: **App Groups** işaretle → Configure → `group.com.dayly.app` seç → Save.
3. **+** → **App IDs** → App → Bundle ID: `com.dayly.app.DaylyWidget`
   - Capabilities: **App Groups** → `group.com.dayly.app` → Save.

## 3. App Store Connect'te uygulamayı oluştur
1. appstoreconnect.apple.com → **Apps → + → New App**.
2. Platform iOS, Ad: **Dayly** (alınmışsa "Dayly: Life Helper" gibi), Dil: Türkçe,
   Bundle ID: `com.dayly.app`, SKU: `dayly-ios`.

## 4. App Store Connect API anahtarı
1. App Store Connect → **Users and Access → Integrations → App Store Connect API**
   → Team Keys → **+**. Ad: `GitHub`, Erişim: **Admin**.
2. **Download API Key** ile `.p8` dosyasını indir (yalnızca bir kez indirilebilir).
3. Sayfadaki **Key ID** ve **Issuer ID**'yi not al.

## 5. Sertifikalar için gizli depo
1. GitHub'da **yeni private repo** oluştur: adı tam olarak `dayly-certs` (boş kalsın).
2. GitHub → Settings → Developer settings → **Fine-grained tokens → Generate new token**:
   - Repository access: yalnızca `dayly-certs`
   - Permissions → Contents: **Read and write**
   - Token'ı kopyala.

## 6. GitHub Secrets (Li reposu → Settings → Secrets and variables → Actions → New repository secret)
| Ad | Değer |
|---|---|
| `ASC_KEY_ID` | 4. adımdaki Key ID |
| `ASC_ISSUER_ID` | 4. adımdaki Issuer ID |
| `ASC_KEY_P8` | `.p8` dosyasının tüm içeriği (`-----BEGIN PRIVATE KEY-----` dahil). iPhone'da Dosyalar'da açıp metni kopyala. |
| `APPLE_TEAM_ID` | 1. adımdaki Team ID |
| `MATCH_PASSWORD` | Kendin seçtiğin güçlü bir parola (sertifikaları şifreler; bir yere not et) |
| `MATCH_GIT_TOKEN` | 5. adımdaki token |

## 7. Build'i başlat
GitHub (uygulama ya da Safari) → Li reposu → **Actions → iOS TestFlight → Run workflow**.
Yaklaşık 20–30 dakika sürer. Sonra App Store Connect → Dayly → **TestFlight**:
1. Build "Processing" bitince **Internal Testing** grubuna kendini ekle.
2. iPhone'a **TestFlight** uygulamasını indir, davet e-postasındaki bağlantıyı aç → Yükle.

## Widget'ı ekleme
Ana ekranda boş bir yere basılı tut → sol üstte **+** → **Dayly** → boyut seç → Ekle.
Kilit ekranında: kilit ekranına basılı tut → Özelleştir → Kilit Ekranı → widget alanı → Dayly.

## Sorun olursa
Actions'taki kırmızı adımın adını söylemen yeterli; logları ben okurum.
