import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/derived_providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/mascot.dart';
import 'advice_view.dart';

/// Everything Lio noticed across the user's data, most useful first.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final advice = ref.watch(adviceProvider);
    return Scaffold(
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
          if (advice.isEmpty)
            AppCard(child: Text(l.lioAllGood, style: context.text.bodyLarge))
          else
            for (final a in advice)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: AdviceCard(a),
              ),
        ],
      ),
    );
  }
}
