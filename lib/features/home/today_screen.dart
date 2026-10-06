import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/mascot.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/models/enums.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/config/feature_flags.dart';
import '../life/mood_sheet.dart';
import '../money/expense_sheet.dart';
import '../plan/task_editor.dart';
import '../shell/main_shell.dart';
import 'home_cards.dart';

/// Daily Brief: answers "what should I do today?" in one glance. Cards are
/// chosen from the user's focus areas and data — unused features stay out
/// of the way.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final String _layout;

  @override
  void initState() {
    super.initState();
    final s = ref.read(servicesProvider);
    _layout = Experiments(s.remote, (e, v) {
      unawaited(s.analytics.log(AnalyticsEvent.experimentExposure, {'experiment': e.key, 'variant': v}));
    }).variant(Experiment.homeLayout);
    unawaited(s.analytics.log(AnalyticsEvent.dailyBriefViewed, {'layout': _layout}));
  }

  MascotMood _mood(bool allDone) {
    final h = DateTime.now().hour;
    if (allDone) return MascotMood.excited;
    if (h < 6 || h >= 22) return MascotMood.sleepy;
    return h < 12 ? MascotMood.happy : MascotMood.front;
  }

  String _greeting(BuildContext context, String name) {
    final l = context.l10n;
    if (name.isEmpty) return l.greetingNoName;
    final h = DateTime.now().hour;
    return h < 12 ? l.greetingMorning(name) : (h < 18 ? l.greetingAfternoon(name) : l.greetingEvening(name));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final profile = ref.watch(profileProvider).value;
    final focus = profile?.focusAreas ?? const <FocusArea>{};
    final services = ref.watch(servicesProvider);
    final hasTasks = (ref.watch(tasksProvider).list).isNotEmpty;
    final hasBudget = profile?.hasBudget ?? false;
    final compact = _layout == 'compact';
    final today = ref.watch(todayProvider);
    final goals = ref.watch(dailyGoalsProvider);
    final allDone = goals.isNotEmpty && goals.every((g) => g.completed);
    final openGoals = goals.where((g) => !g.completed).length;
    final weekend = today.weekday == DateTime.sunday || today.weekday == DateTime.monday;

    final cards = <Widget>[
      const LifeScoreCard(),
      const DailyGoalsCard(),
      if (focus.contains(FocusArea.planning) || focus.contains(FocusArea.productivity) || hasTasks)
        const TodayPlanCard(),
      if (focus.contains(FocusArea.money) || hasBudget) const MoneyCard(),
      if (!compact && (focus.contains(FocusArea.food) || focus.contains(FocusArea.health))) const FoodCard(),
      const WellbeingCard(),
      const InsightCard(),
      if (!compact && weekend && services.flags.isEnabled(Feature.weeklyReport)) const WeeklyReviewCard(),
      if (!compact && services.cloudEnabled && services.flags.isEnabled(Feature.news)) const NewsTeaserCard(),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(weatherProvider);
            try {
              await ref.read(sessionProvider).value?.sync?.sync();
            } catch (_) {
              // Offline: local data is already shown.
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                title: Text(
                  context.upper(fmt.weekdayDayMonth(today)),
                  style: context.text.labelMedium?.copyWith(color: context.semantic.muted, letterSpacing: 1.2),
                ),
                actions: const [ProfileButton()],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(_greeting(context, profile?.name ?? ''), style: context.text.headlineMedium),
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              l.dayAtAGlance,
                              style: context.text.bodyLarge?.copyWith(color: context.semantic.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.lg),
                      FadeSlideIn(
                        delay: Motion.fast,
                        child: AppCard(
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? Gradients.meadowDark
                              : Gradients.meadow,
                          padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.lg, Space.md),
                          onTap: () => context.go('/ai'),
                          child: Row(
                            children: [
                              Mascot(mood: _mood(allDone), size: 92),
                              const SizedBox(width: Space.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      allDone ? l.allGoalsDone : l.mascotTip(openGoals),
                                      style: context.text.titleMedium,
                                    ),
                                    const SizedBox(height: Space.xs),
                                    Text(
                                      l.mascotAsk,
                                      style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, size: 20, color: context.colors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      const WeatherChip(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, 120),
                sliver: SliverList.separated(
                  itemCount: cards.length,
                  itemBuilder: (_, i) => FadeSlideIn(
                    delay: Duration(milliseconds: 70 * i.clamp(0, 8)),
                    child: cards[i],
                  ),
                  separatorBuilder: (_, _) => const SizedBox(height: Space.md),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-home',
        tooltip: l.quickAdd,
        onPressed: () => _quickAdd(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context) async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      builder: (c) {
        final items = [
          (Icons.payments_rounded, l.quickExpense, Accent.money),
          (Icons.check_circle_rounded, l.quickTask, Accent.plan),
          (Icons.mood_rounded, l.quickMood, Accent.wellbeing),
          (Icons.auto_awesome_rounded, l.quickAsk, Accent.ai),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.quickAdd, style: c.text.headlineSmall),
                const SizedBox(height: Space.lg),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: Space.md,
                  crossAxisSpacing: Space.md,
                  childAspectRatio: 1.9,
                  children: [
                    for (final (i, it) in items.indexed)
                      FadeSlideIn(
                        delay: Duration(milliseconds: 40 * i),
                        child: AppCard(
                          color: Color.alphaBlend(it.$3.tint(Theme.of(c).brightness), c.colors.surface),
                          padding: const EdgeInsets.all(Space.md + 2),
                          onTap: () => Navigator.pop(c, i),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(it.$1, color: it.$3.color),
                              Text(it.$2, style: c.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted) return;
    switch (choice) {
      case 0:
        await showExpenseSheet(context);
      case 1:
        await showTaskEditor(context);
      case 2:
        await showMoodSheet(context);
      case 3:
        context.go('/ai');
    }
  }
}
