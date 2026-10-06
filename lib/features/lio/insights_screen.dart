import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/mascot.dart';
import '../../services/ads/ads_service.dart';
import '../premium/interstitial.dart';
import '../premium/rewarded.dart';
import 'advice_view.dart';

/// Everything Lio noticed across the user's data, most useful first. The
/// top three are free; the rest open with Premium or a rewarded ad (today).
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  static const free = 3;

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final advice = ref.watch(adviceProvider);
    final open =
        ref.watch(isPremiumProvider) || ref.watch(rewardUnlocksProvider).isUnlocked(RewardPlacement.extraInsights);
    final shown = open ? advice : advice.take(InsightsScreen.free).toList();
    final hidden = advice.length - shown.length;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(maybeShowInterstitial(ref));
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.insightsTitle)),
        body: PageList(
          children: [
            Row(
              children: [
                const Mascot(mood: MascotMood.thoughtful, size: 52, float: false),
                const SizedBox(width: Space.md),
                Expanded(child: Text(l.insightsIntro, style: context.text.bodyLarge)),
              ],
            ),
            const SizedBox(height: Space.lg),
            if (advice.isEmpty) AppCard(child: Text(l.lioAllGood, style: context.text.bodyLarge)),
            for (final a in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: AdviceCard(a),
              ),
            if (hidden > 0)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.insightsMore(hidden), style: context.text.titleMedium),
                    const SizedBox(height: Space.sm),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        if (await watchRewardedAd(context, ref, RewardPlacement.extraInsights)) {
                          await ref.read(rewardUnlocksProvider).unlock(RewardPlacement.extraInsights);
                          if (mounted) setState(() {});
                        }
                      },
                      icon: const Text('🎁'),
                      label: Text(l.insightsUnlock),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
