import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/billing/billing_service.dart';
import '../../services/config/feature_flags.dart';
import '../../services/config/remote_config_service.dart';

/// Premium subscription paywall (Google Play Billing). Prices always come
/// from Play; the `paywall` experiment only changes plan ordering.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, required this.source});

  final String source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  late Future<List<PremiumProduct>> _products;
  StreamSubscription<PurchaseResult>? _sub;
  PremiumProduct? _selected;
  bool _pending = false;
  late final String _variant;

  @override
  void initState() {
    super.initState();
    final s = ref.read(servicesProvider);
    _variant = Experiments(s.remote, (e, v) {
      unawaited(s.analytics.log(AnalyticsEvent.experimentExposure, {'experiment': e.key, 'variant': v}));
    }).variant(Experiment.paywall);
    unawaited(s.analytics.log(AnalyticsEvent.paywallViewed, {'source': widget.source, 'variant': _variant}));
    _products = s.billing.products();
    _sub = s.billing.results.listen((r) {
      if (!mounted) return;
      final l = context.l10n;
      setState(() => _pending = r == PurchaseResult.pending);
      switch (r) {
        case PurchaseResult.success:
          unawaited(
            s.analytics.log(AnalyticsEvent.subscriptionStarted, {
              'product': _selected?.id ?? 'restore',
              'source': widget.source,
            }),
          );
          showSnack(context, l.premiumSuccess);
          Navigator.of(context).maybePop();
        case PurchaseResult.error:
          showSnack(context, l.errorGeneric);
        case PurchaseResult.pending:
          showSnack(context, l.premiumPending);
        case PurchaseResult.cancelled || PurchaseResult.unavailable:
          break;
      }
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final premium = ref.watch(isPremiumProvider);
    final features = [
      (Icons.auto_awesome, l.premiumFeatureAi),
      (Icons.insights_outlined, l.premiumFeatureScore),
      (Icons.block, l.premiumFeatureNoAds),
      (Icons.analytics_outlined, l.premiumFeatureAnalytics),
      (Icons.restaurant_menu_outlined, l.premiumFeatureMeals),
      (Icons.psychology_outlined, l.premiumFeatureMemory),
      (Icons.ac_unit_rounded, l.premiumFeatureStreak),
      (Icons.local_post_office_outlined, l.premiumFeaturePostcards),
    ];
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final trialDays = ref.read(servicesProvider).remote.getInt(RcKeys.premiumTrialDays);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xxl),
        children: [
          Icon(Icons.workspace_premium_outlined, size: 56, color: context.colors.primary),
          const SizedBox(height: Space.md),
          Text(l.premiumTitle, textAlign: TextAlign.center, style: context.text.headlineMedium),
          const SizedBox(height: Space.xs),
          Text(
            l.premiumSubtitle,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(color: context.semantic.muted),
          ),
          const SizedBox(height: Space.xl),
          ...features.map(
            (f) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(f.$1, color: context.colors.primary),
              title: Text(f.$2),
            ),
          ),
          const SizedBox(height: Space.lg),
          if (premium) ...[
            AppCard(
              child: Text(l.premiumActive, style: context.text.titleMedium, textAlign: TextAlign.center),
            ),
            const SizedBox(height: Space.md),
            OutlinedButton(
              onPressed: () => launchUrl(
                Uri.parse(
                  ios
                      ? 'https://apps.apple.com/account/subscriptions'
                      : 'https://play.google.com/store/account/subscriptions?package=${AppConfig.androidPackage}',
                ),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(ios ? l.premiumManageIos : l.premiumManage),
            ),
          ] else
            FutureBuilder<List<PremiumProduct>>(
              future: _products,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.all(Space.xl), child: LoadingView());
                }
                var products = snap.data ?? const <PremiumProduct>[];
                if (products.isEmpty) return Text(l.premiumUnavailable, textAlign: TextAlign.center);
                products = [...products]
                  ..sort(
                    (a, b) => _variant == 'annual_first'
                        ? (a.yearly ? 0 : 1).compareTo(b.yearly ? 0 : 1)
                        : (a.yearly ? 1 : 0).compareTo(b.yearly ? 1 : 0),
                  );
                _selected ??= products.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioGroup<String>(
                      groupValue: _selected!.id,
                      onChanged: (id) => setState(() => _selected = products.firstWhere((p) => p.id == id)),
                      child: Column(
                        children: products
                            .map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: Space.sm),
                                child: Card(
                                  child: RadioListTile<String>(
                                    value: p.id,
                                    title: Text(p.yearly ? l.premiumYearly : l.premiumMonthly),
                                    subtitle: Text(p.price, style: context.text.titleMedium),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    if (trialDays > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: Text(
                          l.premiumTrial(trialDays),
                          textAlign: TextAlign.center,
                          style: context.text.titleSmall?.copyWith(color: context.colors.primary),
                        ),
                      ),
                    FilledButton(
                      onPressed: _pending ? null : () => ref.read(servicesProvider).billing.buy(_selected!),
                      child: _pending
                          ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(trialDays > 0 ? l.premiumTry : l.premiumSubscribe),
                    ),
                  ],
                );
              },
            ),
          TextButton(onPressed: () => ref.read(servicesProvider).billing.restore(), child: Text(l.premiumRestore)),
          const SizedBox(height: Space.md),
          Text(
            ios ? l.premiumDisclosureIos : l.premiumDisclosure,
            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
          ),
        ],
      ),
    );
  }
}
