# Google Play listing & release checklist

## Store listing (draft — only describes implemented features)
**App name:** Dayly: Daily Planner & Budget
**Short description (≤80):** Plan your day, track spending and habits, with an AI assistant that helps.

**Full description:**
Dayly brings your day together in one calm place.

• Daily Brief — open the app and see what matters today: your plan, safe-to-spend amount, goals, mood and a suggested meal.
• Life Score — a transparent 0–100 score built from the areas you track (money, productivity, habits, sleep, mood, planning), with a plain-language reason when it changes.
• Money — log expenses in seconds ("250 lunch"), scan receipts on your device, set weekly or category limits and see how much you can safely spend each day.
• Plan — tasks with priorities, durations and repeats; one tap to fit your open tasks around fixed appointments.
• Habits & mood — streaks, weekly completion and private mood check-ins with simple patterns.
• Food — meal ideas from what's in your pantry, a smart shopping list and diet/allergy filters.
• Assistant — ask in your own words. It can suggest tasks, budgets, meal plans or shopping items, and nothing changes until you confirm. It never moves money.
• Weekly review and monthly report.
• Private by design — works offline, journal stays encrypted on your device, choose exactly what the assistant may see, export or delete your data anytime.

Free with optional rewarded ads for extra assistant requests. Dayly Premium: unlimited assistant (fair use), full score breakdown, monthly reports, no ads.
Mood features are for self-reflection only and are not medical advice.

## Data safety form (based on this codebase)
| Data type | Collected | Shared | Purpose | Notes |
|---|---|---|---|---|
| Name (first name) | Yes | No | App functionality | Profile, synced |
| Email | Yes (if account linked) | No | Account management | Firebase Auth |
| User IDs | Yes | No | Functionality, analytics | Firebase uid |
| Financial info (purchase history? no; user-entered expenses/income) | Yes | No | App functionality | Synced, encrypted in transit and at rest by Google |
| Approximate location | Optional | No | Weather | Rounded to ~1 km; or manual city |
| Photos | Processed on device only | No | Receipt scanning | Not uploaded |
| Health & fitness / mood | Yes (self-reported) | No | App functionality | Mood/sleep/habit logs |
| App interactions, crash logs, diagnostics | Yes | No | Analytics | Opt-out in settings |
| Device or other IDs (advertising ID) | Yes | **Yes (AdMob)** | Advertising | Consent via UMP |
| Messages to the assistant | Yes | **Processed by AI provider** | App functionality | Only consented scopes sent; disclose your provider |
- Data encrypted in transit: **Yes**. Users can request deletion: **Yes** (in-app account deletion; provide a web deletion URL in Play Console as required).

## Ads & subscriptions
- Declare **Contains ads** (AdMob). Rewarded ads are opt-in.
- Subscription disclosure is shown on the paywall (auto-renewal, cancel in Play). Prices come from Play.
- Provide an account deletion URL and privacy policy URL (`PRIVACY_POLICY_URL`).

## Release checklist
- [ ] Change `applicationId`/`namespace` and `ANDROID_PACKAGE`; app name/icon (`flutter_launcher_icons` or manual mipmaps)
- [ ] `google-services.json` from the production project; SHA certificates (incl. Play App Signing) added
- [ ] Release keystore + `android/key.properties`; build `appbundle`
- [ ] Real AdMob App ID and ad unit ids; UMP consent messages published; `app-ads.txt` on your domain
- [ ] Play subscriptions created; service account permissions; RTDN topic configured; license testers verified
- [ ] Backend deployed; secrets set; App Check enforced (Play Integrity registered); rules/indexes deployed
- [ ] Remote Config published (limits, flags); A/B experiments created in Firebase A/B Testing if desired
- [ ] Privacy policy & terms published; URLs set; in-app legal screens show links (not placeholder)
- [ ] Data safety form, content rating questionnaire, target audience (not designed for children), ads declaration
- [ ] Store listing screenshots (light + dark), feature graphic, localized listings (en, tr)
- [ ] `flutter analyze`, all tests green in CI; manual QA on a low-end device (cold start < 2 s target)
- [ ] Internal testing track → closed testing → production staged rollout; monitor Crashlytics & `metrics_daily`
