# Dayly

**Your operating system for everyday life.** A Flutter (Android-first, iOS-ready) life assistant that
combines a Daily Brief, an explainable Life Score, planning, budgeting, food, habits, mood, journal and an
AI assistant that proposes actions you confirm — monetised with rewarded ads and a Premium subscription.

- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Setup (Firebase, env vars, AI, AdMob, Billing), build & test: [docs/SETUP.md](docs/SETUP.md)
- Google Play listing, data safety & release checklist: [docs/PLAY_RELEASE.md](docs/PLAY_RELEASE.md)
- Monetization metrics: [docs/MONETIZATION.md](docs/MONETIZATION.md)

## Quick start
```bash
flutter pub get
flutter run            # runs in on-device mode until Firebase is configured
```
With Firebase + backend configured (see SETUP): `flutter run --dart-define-from-file=env/prod.json`.

## What is implemented
| Area | Status |
|---|---|
| Onboarding (9 steps, A/B "short" variant), anonymous → Google/email account linking | ✅ |
| Home / Daily Brief: dynamic cards by focus area & data, weather, goals, insight, weekly review, news teaser | ✅ |
| Life Score: deterministic, explainable, 14-day history, breakdown (Premium or rewarded unlock) | ✅ |
| Daily goals, Life Progress, streaks, 7 badges | ✅ |
| Plan: Today timeline / Week / Month, recurring tasks, deterministic optimizer | ✅ |
| Money: dashboard, safe daily spending, weekly & category limits, smart input, on-device receipt OCR | ✅ |
| Habits, mood (with disclaimer), sleep, encrypted local journal | ✅ |
| Food: meal suggestions (local library + AI), pantry matching, smart shopping list | ✅ |
| AI assistant: backend proxy, structured actions with confirmation, memory (view/delete), credits, compression | ✅ |
| Weekly & monthly reports with charts and optional AI summary | ✅ |
| Notifications: local planner with caps & quiet hours; FCM token registration | ✅ |
| Rewarded ads (+ policy-gated interstitial/banner), UMP consent, server-granted rewards / SSV | ✅ |
| Premium via Google Play Billing with server verification + RTDN | ✅ |
| Analytics events, retention markers, daily AI-cost metrics | ✅ |
| Remote Config, feature flags, Firebase A/B Testing hooks (5 experiments) | ✅ |
| Offline-first sync with LWW conflict resolution | ✅ |
| Dark mode, high contrast, dynamic type, semantics, 48dp targets | ✅ |
| Localization: architecture for 11 languages; English + Turkish populated (569 strings) | ✅ |
| Privacy: AI data scopes, analytics/crash/ads opt-outs, export, per-type deletion, account deletion | ✅ |
| On-device ML: bundled expense/shopping classifiers (~50 KB, typo-robust) + optional downloadable offline assistant (MediaPipe LLM) | ✅ |

## Where you must provide credentials
| What | Where |
|---|---|
| `android/app/google-services.json` | Firebase console |
| Anthropic / OpenAI / Gemini API key | `firebase functions:secrets:set ANTHROPIC_API_KEY` (never in the app) |
| News API key (GNews/NewsAPI) | `firebase functions:secrets:set NEWS_API_KEY` |
| Google Sign-In web client id | `GOOGLE_SERVER_CLIENT_ID` dart-define |
| AdMob app id / ad unit ids | `-PADMOB_APP_ID`, `ADMOB_*` dart-defines (defaults are Google test ids) |
| Play subscription ids, service account access, RTDN topic | Play Console + `PREMIUM_*` defines/params |
| Release keystore | `android/key.properties` |
| Privacy policy / terms URLs | `PRIVACY_POLICY_URL`, `TERMS_URL` |

## Verification done in development
- `flutter analyze`: no issues. `flutter test`: 91 tests (engines, sync, encryption, services, widget
  flows incl. onboarding→Home, smart expense entry, AI action confirmation, Turkish + dark mode,
  offline, habits, and a compile check of the production entry point).
- `functions`: TypeScript build + 24 vitest tests (validator, routing, credits, handlers, providers, SSV
  signatures, Play parsing, metrics).
- Firestore rules: 8 tests on the Firestore emulator.

## Known limitations
- **No APK/AAB was built in the development environment** (Google's Maven repository was unreachable
  there); the Gradle config is standard but unverified until the first `flutter build` on your machine/CI
  (`.github/workflows/ci.yml` builds a debug APK).
- iOS is architecturally supported (Info.plist keys added) but untested; Apple Sign-In/StoreKit paths are not wired.
- Only English and Turkish strings exist; other locales fall back to English until ARBs are added.
- The journal key is device-bound: journal entries don't move to a new phone (they are included in data export).
- Sync resolves conflicts per record (last write wins); simultaneous edits of different fields on two devices keep only the latest.
- Calories are planned (meal plans), not tracked as intake, so "N calories away from target" nudges are not implemented.
- No server-sent push campaigns (weekly report is a local notification); FCM tokens are registered for future use.
- Revenue metrics (ARPU, eCPM, LTV) require BigQuery exports; only AI cost and reward metrics are computed in-app.
- Step counts are not read from Health Connect; the Health sub-score uses health habits.
- Built-in recipes are a small curated set (20); larger variety comes from AI meal plans.
- Legal screens are placeholders until URLs are configured.
- The on-device classifiers are trained on synthetic data (seed vocabulary + templates); they handle
  typos/variants well but know only words similar to their vocabulary. Retrain with real, user-confirmed
  corrections once available.
- The offline assistant is text-only (no app actions), slower and less accurate than the cloud assistant,
  and was not run on a real device here (no Android SDK in the dev environment); the model file must be
  hosted by you.

## Next recommended features
1. Health Connect integration (steps, sleep) to replace manual sleep logging.
2. Bank/open-banking import or CSV import for transactions (read-only).
3. Home-screen widgets (Daily Brief, safe-to-spend) and Wear OS tile.
4. Calendar sync (read Google Calendar events into the timeline).
5. Server-driven weekly report push and re-engagement campaigns via FCM + Remote Config.
6. More languages (es, pt, de, fr, ar first) and localized store listings.
7. Field-level merge for conflicts on profile/settings records.
8. Family/shared shopping lists.
