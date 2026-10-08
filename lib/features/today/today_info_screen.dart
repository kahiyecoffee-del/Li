import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../services/daily/daily_info_service.dart';
import '../premium/native_slot.dart';
import '../settings/city_picker.dart';

String prayerName(AppLocalizations l, String key) => switch (key) {
  'imsak' => l.prayerImsak,
  'gunes' => l.prayerGunes,
  'ogle' => l.prayerOgle,
  'ikindi' => l.prayerIkindi,
  'aksam' => l.prayerAksam,
  _ => l.prayerYatsi,
};

const _symbols = {'USD': r'$', 'EUR': '€', 'GBP': '£'};

/// The everyday things people check: weather, exchange rates, prayer
/// times, the pharmacy on duty and fuel prices.
class TodayInfoScreen extends ConsumerWidget {
  const TodayInfoScreen({super.key});

  Future<void> _pickCity(BuildContext context, WidgetRef ref) async {
    final p = await pickCity(context);
    final profile = ref.read(profileProvider).value;
    if (p != null && profile != null) await ref.read(actionsProvider).saveProfile(profile.copyWith(place: p));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final loc = Localizations.localeOf(context).toString();
    final settings = ref.watch(settingsProvider);
    final place = ref.watch(profileProvider.select((p) => p.value?.place));
    final weather = ref.watch(weatherProvider).value;
    final rates = ref.watch(ratesProvider);
    final prayer = ref.watch(prayerTimesProvider);
    final now = DateTime.now();
    final city = place?.name.split(',').first;

    Widget toggle(String label, bool value, ValueChanged<bool> onChanged, Key key) => SwitchListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.todayInfoTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ratesProvider);
          ref.invalidate(prayerTimesProvider);
          ref.invalidate(weatherProvider);
        },
        child: PageList(
          children: [
            Eyebrow(DateFormat.MMMMEEEEd(loc).format(now)),
            const SizedBox(height: Space.xs),
            if (place == null)
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.location_city_outlined, color: context.colors.primary),
                    const SizedBox(width: Space.md),
                    Expanded(child: Text(l.todayNeedsCity)),
                    TextButton(onPressed: () => _pickCity(context, ref), child: Text(l.todayPickCity)),
                  ],
                ),
              )
            else if (weather != null) ...[
              SectionTitle(l.todayWeather),
              AppCard(
                child: Row(
                  children: [
                    Text('${weather.temperatureC.round()}°', style: context.text.displaySmall),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.weather(weather.condition), style: context.text.titleMedium),
                          Text(
                            '$city · ${weather.lowC.round()}° / ${weather.highC.round()}° · ☂ %${weather.rainProbability}',
                            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SectionTitle(l.todayRates),
            if (!settings.showRates)
              toggle(
                l.todayRatesOff,
                false,
                (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(showRates: v)),
                const Key('today-rates-toggle'),
              )
            else
              AppCard(
                key: const Key('today-rates'),
                child: switch (rates) {
                  AsyncData(value: final r?) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final c in HttpDailyInfoProvider.currencies)
                        if (r.$1[c] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(width: 36, child: Text(_symbols[c] ?? c, style: context.text.titleLarge)),
                                Text(c, style: context.text.titleMedium),
                                const Spacer(),
                                Text(
                                  '₺${NumberFormat('#,##0.00', loc).format(r.$1[c])}',
                                  style: context.text.titleLarge?.copyWith(
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      const SizedBox(height: Space.xs),
                      Text(
                        '${l.todayRatesUpdated(DateFormat.MMMd(loc).add_Hm().format(r.$2))} · ${l.todayRatesNote}',
                        style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                      ),
                    ],
                  ),
                  AsyncLoading() => const LoadingView(),
                  _ => Text(l.todayUnavailable, style: context.text.bodyMedium),
                },
              ),

            SectionTitle(l.todayPrayer),
            if (!settings.showPrayerTimes)
              toggle(
                l.todayPrayerOn,
                false,
                (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(showPrayerTimes: v)),
                const Key('today-prayer-toggle'),
              )
            else if (place == null)
              Text(l.todayNeedsCity, style: context.text.bodyMedium)
            else
              AppCard(
                key: const Key('today-prayer'),
                child: switch (prayer) {
                  AsyncData(value: final p?) => _PrayerTable(times: p, now: now),
                  AsyncLoading() => const LoadingView(),
                  _ => Text(l.todayUnavailable, style: context.text.bodyMedium),
                },
              ),

            SectionTitle(l.todayNearby),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.local_pharmacy_outlined, color: context.colors.primary),
                    title: Text(l.todayPharmacy),
                    subtitle: Text(l.todayOpensOutside),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => launchUrl(
                      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': 'nöbetçi eczane'}),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.local_gas_station_outlined, color: context.colors.primary),
                    title: Text(l.todayFuel),
                    subtitle: Text(l.todayOpensOutside),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => launchUrl(
                      Uri.https('www.google.com', '/search', {'q': 'akaryakıt fiyatları ${city ?? ''}'.trim()}),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            const NativeSlot(),
          ],
        ),
      ),
    );
  }
}

class _PrayerTable extends StatelessWidget {
  const _PrayerTable({required this.times, required this.now});
  final PrayerTimes times;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final next = times.next(now);
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (next != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Text(
              l.todayNext(prayerName(l, next.$1), durationLabelShort(l, next.$2.difference(now))),
              style: context.text.titleMedium?.copyWith(color: gold),
            ),
          ),
        for (final k in PrayerTimes.order)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Text(
                  prayerName(l, k),
                  style: context.text.bodyLarge?.copyWith(fontWeight: next?.$1 == k ? FontWeight.w700 : null),
                ),
                const Spacer(),
                Text(
                  times.times[k] ?? '–',
                  style: context.text.bodyLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: next?.$1 == k ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: Space.xs),
        Text(l.todayPrayerNote, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
      ],
    );
  }
}

/// "1 sa 20 dk" / "35 dk" for a duration.
String durationLabelShort(AppLocalizations l, Duration d) {
  final m = d.inMinutes.clamp(1, 24 * 60);
  return m >= 60 ? l.hoursMinutes(m ~/ 60, m % 60) : l.minutesShort(m);
}

/// Home: the two things people glance at most (rates and the next prayer).
class TodayInfoStrip extends ConsumerWidget {
  const TodayInfoStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final loc = Localizations.localeOf(context).toString();
    final rates = ref.watch(ratesProvider).value;
    final prayer = ref.watch(prayerTimesProvider).value;
    final next = prayer?.next(DateTime.now());
    final parts = <String>[
      if (rates != null)
        for (final c in const ['USD', 'EUR'])
          if (rates.$1[c] != null) '${_symbols[c]} ${NumberFormat('#,##0.00', loc).format(rates.$1[c])}',
      if (next != null) l.todayNext(prayerName(l, next.$1), durationLabelShort(l, next.$2.difference(DateTime.now()))),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: AppCard(
        key: const Key('today-strip'),
        onTap: () => context.push('/today-info'),
        child: Row(
          children: [
            Icon(Icons.wb_sunny_outlined, color: context.colors.primary),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.todayInfoTitle, style: context.text.titleMedium),
                  if (parts.isNotEmpty)
                    Text(
                      parts.join('  ·  '),
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.semantic.muted),
          ],
        ),
      ),
    );
  }
}
