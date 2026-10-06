import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
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
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
                  fmt.weekdayDayMonth(today),
                  style: context.text.labelLarge?.copyWith(color: context.semantic.muted),
                ),
                actions: const [ProfileButton()],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          '${_greeting(context, profile?.name ?? '')} 👋',
                          style: context.text.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(l.dayAtAGlance, style: context.text.bodyLarge?.copyWith(color: context.semantic.muted)),
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
                  itemBuilder: (_, i) => cards[i],
                  separatorBuilder: (_, _) => const SizedBox(height: Space.md),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _quickAdd(context),
        icon: const Icon(Icons.add),
        label: Text(l.quickAdd),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context) async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(l.quickExpense),
              onTap: () => Navigator.pop(c, 0),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l.quickTask),
              onTap: () => Navigator.pop(c, 1),
            ),
            ListTile(
              leading: const Icon(Icons.mood_outlined),
              title: Text(l.quickMood),
              onTap: () => Navigator.pop(c, 2),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(l.quickAsk),
              onTap: () => Navigator.pop(c, 3),
            ),
          ],
        ),
      ),
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
