# Monetization metrics

| Metric | Source | How |
|---|---|---|
| AI cost / user | `metrics_daily.aiCostPerActiveUser`, `usage/{uid}.estimated_ai_cost_per_user` | computed by `dailyMetrics` from token usage × prices |
| Ad impressions / user | AdMob reporting + Analytics `ad_impression` (auto) | BigQuery export |
| Rewarded eCPM | AdMob reporting API / BigQuery (AdMob linking) | revenue ÷ impressions × 1000 |
| Rewarded ads redeemed / user | `metrics_daily.rewardedAdsPerUser` | server-side grants |
| Subscription conversion | Analytics funnel `paywall_viewed` → `subscription_started` | Firebase funnels |
| Churn | Play Console subscriptions report; `billing_events` (RTDN) | cancellations ÷ active |
| ARPU / ARPPU | Play + AdMob revenue (BigQuery) ÷ DAU / paying users | see query below |
| LTV | cohort revenue by `install_week` user property | BigQuery |

Enable **Analytics → BigQuery export**, **AdMob ↔ Firebase linking**, and **Play Console → Financial
reports** export. Example ARPU (daily):
```sql
WITH users AS (
  SELECT event_date, COUNT(DISTINCT user_pseudo_id) dau
  FROM `PROJECT.analytics_XXXX.events_*` WHERE event_name = 'app_open' GROUP BY event_date),
ads AS (
  SELECT event_date, SUM((SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'value')) ad_rev
  FROM `PROJECT.analytics_XXXX.events_*` WHERE event_name = 'ad_impression' GROUP BY event_date)
SELECT u.event_date, (IFNULL(a.ad_rev, 0) /* + subscription revenue from Play export */) / u.dau AS arpu
FROM users u LEFT JOIN ads a USING (event_date) ORDER BY 1 DESC;
```
Remote Config levers (no app update): `daily_free_ai_limit`, `rewarded_ai_limit`, `rewarded_credits_per_ad`,
`interstitial_frequency`, `interstitial_max_per_day`, `banner_enabled`, `premium_price` (paywall variant label),
`premium_features`, `notification_daily_cap`, `free_memory_limit`, `feature_flags`, `experiments`.
