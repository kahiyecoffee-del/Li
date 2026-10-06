# LifeOS — Setup, build & test

## 0. Prerequisites
- Flutter stable (developed with 3.47 / Dart 3.13), Android Studio + Android SDK (API 36), JDK 17–21
- Node.js 22 + `npm i -g firebase-tools` (for the backend)
- A Firebase project on the **Blaze** plan (Cloud Functions + Secret Manager need billing)

The app runs without any of the cloud setup ("on-device mode"): `flutter run` works immediately with
local data, Life Score, budget, plan, habits, food, notifications and offline features.

## 1. Firebase setup
1. Create a project in the Firebase console; add an **Android app** with your package name
   (default `com.lifeos.lifeos` — change `applicationId`/`namespace` in `android/app/build.gradle.kts`
   **before the first Play upload**, and `ANDROID_PACKAGE` in env/params).
2. Download `google-services.json` → `android/app/google-services.json` (git-ignored). The Gradle build
   applies the Google Services and Crashlytics plugins only when this file exists.
   (iOS later: `GoogleService-Info.plist` → `ios/Runner/`.)
3. Enable products:
   - **Authentication** → Anonymous, Email/Password, Google. For Google, add your SHA-1/SHA-256
     (debug + release + Play App Signing) and copy the **Web client ID** into `GOOGLE_SERVER_CLIENT_ID`.
   - **Firestore** (production mode), **Remote Config**, **Analytics**, **Crashlytics**, **Cloud Messaging**.
   - **App Check** → Play Integrity for Android. In debug builds the debug provider prints a token in
     logcat — register it under App Check → Manage debug tokens.
4. Deploy rules, indexes and Remote Config defaults:
   ```bash
   cp .firebaserc.example .firebaserc   # set your project id
   firebase deploy --only firestore:rules,firestore:indexes,remoteconfig
   ```
5. Firestore TTL: the index file declares TTL on `ai_cache.expiresAt`; confirm it under Firestore → TTL.

## 2. Environment variables / build-time config
Client values are `--dart-define`s (no secrets). Copy `env/example.json` → `env/prod.json` and run with
`--dart-define-from-file=env/prod.json`.

| Key | Where to get it | Default |
|---|---|---|
| `GOOGLE_SERVER_CLIENT_ID` | Firebase Auth → Google → Web SDK config | none (required for Google Sign-In) |
| `FUNCTIONS_REGION` | region you deploy Functions to | `us-central1` |
| `ADMOB_REWARDED_ANDROID`, `ADMOB_INTERSTITIAL_ANDROID`, `ADMOB_BANNER_ANDROID` | AdMob ad units | Google **test** ids |
| `PREMIUM_MONTHLY_ID`, `PREMIUM_YEARLY_ID` | Play Console subscription product ids | `lifeos_premium_monthly/yearly` |
| `ANDROID_PACKAGE` | your applicationId | `com.lifeos.lifeos` |
| `PRIVACY_POLICY_URL`, `TERMS_URL`, `SUPPORT_EMAIL` | your published pages | empty → placeholder screen |
| `APP_VERSION` | CI | `1.0.0` |
| `USE_FIREBASE_EMULATORS`, `EMULATOR_HOST` | local dev | `false`, `10.0.2.2` |

Gradle property: `-PADMOB_APP_ID=ca-app-pub-XXX~YYY` (AdMob **app** id; defaults to Google's test app id).
iOS: set the `ADMOB_APP_ID` build setting (used by `GADApplicationIdentifier` in Info.plist).

Backend (Cloud Functions):

| Name | Type | Notes |
|---|---|---|
| `ANTHROPIC_API_KEY` | secret | `firebase functions:secrets:set ANTHROPIC_API_KEY` |
| `OPENAI_API_KEY`, `GEMINI_API_KEY` | secret | only if you switch provider (set a placeholder otherwise — see note) |
| `NEWS_API_KEY` | secret | GNews or NewsAPI key |
| `AI_PROVIDER` | param | `anthropic` (default) \| `openai` \| `gemini` |
| `ANTHROPIC_MODEL_FAST` / `_SMART` | env | defaults `claude-haiku-4-5` / `claude-opus-5-5` |
| `OPENAI_MODEL_FAST` / `_SMART`, `GEMINI_MODEL_FAST` / `_SMART` | env | required for those providers |
| `AI_PRICING_JSON` | env | per-model USD/1M-token prices for non-Anthropic models (cost tracking) |
| `NEWS_PROVIDER` | param | `gnews` (default) \| `newsapi` |
| `ENFORCE_APP_CHECK` | param | `true` (set `false` only for emulator testing) |
| `REWARD_MODE` | param | `callable` (default) \| `ssv` |
| `ANDROID_PACKAGE`, `PREMIUM_PRODUCT_IDS` | param | must match the app |

Non-secret env values go in `functions/.env.<projectId>` (e.g. `ANTHROPIC_MODEL_SMART=claude-opus-5-5`).
Every secret referenced by a function must exist at deploy time; set unused provider keys to a dummy
value (`firebase functions:secrets:set OPENAI_API_KEY` → `unused`).

## 3. AI provider setup
- **Anthropic (default)**: create an API key at console.anthropic.com → `functions:secrets:set ANTHROPIC_API_KEY`.
  The backend uses the official `@anthropic-ai/sdk` with JSON-schema structured output. Routing: simple
  chat and all small tasks → `claude-haiku-4-5`; complex chat (planning/finance analysis, long messages)
  and Premium users → `claude-opus-5-5` (effort `medium`, with server-side refusal fallbacks enabled via
  `fallbacks: "default"`). Prices used for cost tracking are in `functions/src/ai/cost.ts`.
- **OpenAI / Gemini**: set `AI_PROVIDER`, the key secret, the two model env vars and `AI_PRICING_JSON`.
- Tune free limits without a release in Remote Config: `daily_free_ai_limit`, `rewarded_ai_limit`,
  `rewarded_credits_per_ad`, `premium_daily_fair_use`, `ai_requests_per_minute`.

Deploy:
```bash
cd functions && npm ci && npm run build && cd ..
firebase deploy --only functions
```

## 3b. On-device models
- **Classifiers** are bundled; retrain after editing `tool/ml/vocab.py` with
  `python3 tool/ml/train_classifiers.py` (writes `assets/models/` and the parity fixture), then `flutter test`.
- **Offline assistant**: download a MediaPipe `.task` model you are licensed to redistribute (e.g. Gemma 3
  1B IT int4 from Hugging Face after accepting the Gemma terms; include the Gemma terms notice in your
  app's licenses), upload it to Firebase Storage or a CDN with a public HTTPS URL, then set Remote Config
  `offline_model_url` (and `offline_model_size_mb`). Empty URL hides the feature. Never ship a Hugging Face
  token in the app.

## 4. AdMob setup
1. Create an AdMob app (Android) → note the **App ID** → build with `-PADMOB_APP_ID=…`.
2. Create ad units: **Rewarded** (required), Interstitial and Banner (optional) → dart-defines.
3. Privacy & messaging → create a **GDPR** consent message (UMP) and, if relevant, US state regulations.
   The app requests consent before loading ads.
4. Optional **SSV**: Rewarded ad unit → Server-side verification → callback URL
   `https://<region>-<project>.cloudfunctions.net/admobSsv`; then set `REWARD_MODE=ssv`.
5. Keep test ids for development; never click your own live ads.
6. Interstitials are disabled until you set `interstitial_frequency` > 0 in Remote Config.

## 5. Google Play Billing setup
1. Play Console → Monetize → Subscriptions: create `lifeos_premium_monthly` and `lifeos_premium_yearly`
   (each with a base plan; optional free-trial offer).
2. Grant the Functions runtime service account (`<project>@appspot.gserviceaccount.com` or the compute
   default SA) access in Play Console → Users and permissions with *View financial data* and *Manage orders
   and subscriptions*. Enable the **Google Play Android Developer API** in the Cloud project.
3. Real-time developer notifications: create Pub/Sub topic `play-billing`, grant
   `google-play-developer-notifications@system.gserviceaccount.com` the Publisher role, and set the topic in
   Play Console → Monetization setup. `playRtdn` keeps entitlements current (renewals, cancellations).
4. Add license testers to test purchases. Purchases are acknowledged by the app only after the server
   verified them (`verifyPurchase`).

## 6. Build
```bash
flutter pub get
flutter gen-l10n                      # also runs automatically on build
flutter run --dart-define-from-file=env/prod.json                      # debug
flutter build appbundle --release --dart-define-from-file=env/prod.json -PADMOB_APP_ID=ca-app-pub-XXX~YYY
```
Release signing: create `android/key.properties` (git-ignored):
```
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/absolute/path/upload-keystore.jks
```
Strings: edit `tool/l10n_strings.py`, run `python3 tool/l10n_strings.py`. To add a language, add its
ARB (e.g. `lib/l10n/app_de.arb`); it appears automatically in Settings → Language. Architecture covers
en, tr, es, pt, de, fr, it, ar (RTL handled by Flutter), ja, ko, hi; English and Turkish are populated.

## 7. Testing
```bash
flutter analyze
flutter test                                   # unit + data + services + widget flow tests
flutter test integration_test/app_test.dart    # on a device/emulator
cd functions && npm test                       # backend unit tests (vitest)
cd firebase/rules-test && npm ci && npm test   # Firestore rules on the emulator (needs Java)
```
Local end-to-end with emulators: `firebase emulators:start`, set `ENFORCE_APP_CHECK=false` in
`functions/.env.local`, and run the app with `--dart-define=USE_FIREBASE_EMULATORS=true`.
