import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/ai_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/decide/decide_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/today_screen.dart';
import '../features/lio/insights_screen.dart';
import '../features/focus/focus_screen.dart';
import '../features/lio/garden.dart';
import '../features/search/search_screen.dart';
import '../features/today/today_info_screen.dart';
import '../features/lio/lio_guide_screen.dart';
import '../features/life/journal_editor_screen.dart';
import '../features/life/journal_read_screen.dart';
import '../features/life/achievements_screen.dart';
import '../features/life/food_screen.dart';
import '../features/life/recipe_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/plan/routines_screen.dart';
import '../features/review/weekly_review_screen.dart';
import '../domain/models/food.dart';
import '../features/life/habits_screen.dart';
import '../features/life/journal_screen.dart';
import '../features/life/mood_screen.dart';
import '../features/life/news_screen.dart';
import '../features/life/pantry_screen.dart';
import '../features/life/shopping_screen.dart';
import '../features/money/money_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/problem/problem_home_screen.dart';
import '../features/problem/solution_screen.dart';
import '../features/reports/report_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/score/score_screen.dart';
import '../features/settings/account_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/memory_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/shell/splash_screen.dart';
import '../features/tools/calculator_screen.dart';
import 'providers.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const plan = '/plan';
  static const money = '/money';
  static const life = '/life';
  static const explore = '/explore';
  static const saved = '/saved';
  static const profile = '/profile';
  static const today = '/today';
  static const solve = '/solve';
  static const decide = '/decide';
  static const calc = '/calc';
  static const ai = '/ai';
  static const score = '/score';
  static const settings = '/settings';
  static const privacy = '/settings/privacy';
  static const memory = '/settings/memory';
  static const account = '/settings/account';
  static const legal = '/legal';
  static const premium = '/premium';
  static const weekly = '/reports/weekly';
  static const monthly = '/reports/monthly';
  static const habits = '/habits';
  static const mood = '/mood';
  static const journal = '/journal';
  static const food = '/food';
  static const pantry = '/pantry';
  static const shopping = '/shopping';
  static const news = '/news';
  static const achievements = '/achievements';
}

/// Re-evaluates redirects when auth/session/onboarding state changes.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(sessionProvider, (_, _) => refresh.ping());
  ref.listen(profileProvider.select((p) => p.value?.onboardingCompleted), (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final session = ref.read(sessionProvider);
      if (session.isLoading && !session.hasValue) return loc == Routes.splash ? null : Routes.splash;
      final signedIn = session.value != null;
      final atAuth = loc == Routes.welcome || loc.startsWith(Routes.auth) || loc.startsWith(Routes.legal);
      if (!signedIn) return atAuth ? null : Routes.welcome;

      final profile = ref.read(profileProvider);
      if (!profile.hasValue) return loc == Routes.splash ? null : Routes.splash;
      final onboarded = profile.value!.onboardingCompleted;
      if (!onboarded) return loc == Routes.onboarding ? null : Routes.onboarding;
      if (loc == Routes.splash || loc == Routes.onboarding || loc == Routes.welcome || loc.startsWith(Routes.auth)) {
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: Routes.auth,
        builder: (_, s) =>
            AuthScreen(mode: s.uri.queryParameters['mode'] == 'signup' ? AuthMode.signUp : AuthMode.signIn),
      ),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute(
        builder: (_, _, shell) => MainShell(shell: shell),
        navigatorContainerBuilder: (_, shell, children) =>
            AnimatedBranchContainer(currentIndex: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.explore, builder: (_, _) => const ExploreScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.saved, builder: (_, _) => const SavedScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.profile, builder: (_, _) => const SettingsScreen(asTab: true))],
          ),
        ],
      ),
      // Older links: Life is now Explore.
      GoRoute(path: Routes.life, redirect: (_, _) => Routes.explore),
      // Lio: opened from anywhere (he walks around the tabs), not a tab.
      GoRoute(
        path: Routes.ai,
        // Query parameters belong to /ai itself, not to /ai/chat below it.
        builder: (_, s) => s.uri.path == Routes.ai
            ? LioGuideScreen(
                initialText: s.uri.queryParameters['q'],
                topic: s.uri.queryParameters['topic'],
                nonce: s.uri.queryParameters['n'],
              )
            : const LioGuideScreen(),
        routes: [
          // Free-form chat with the cloud assistant (only when configured).
          GoRoute(
            path: 'chat',
            builder: (_, s) => AiScreen(
              initialPrompt: s.uri.queryParameters['q'],
              autoSend: s.uri.queryParameters['send'] == '1',
              nonce: s.uri.queryParameters['n'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.plan,
        builder: (_, s) =>
            PlanScreen(closeDay: s.uri.queryParameters['close'] == '1', doneId: s.uri.queryParameters['done']),
      ),
      GoRoute(path: Routes.today, builder: (_, _) => const TodayScreen()),
      GoRoute(
        path: '/focus',
        builder: (_, s) => FocusScreen(taskId: s.uri.queryParameters['task']),
      ),
      GoRoute(path: '/postcards', builder: (_, _) => const PostcardsScreen()),
      GoRoute(path: '/today-info', builder: (_, _) => const TodayInfoScreen()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: Routes.solve,
        builder: (_, s) => SolutionScreen(query: s.uri.queryParameters['q'] ?? ''),
      ),
      GoRoute(
        path: Routes.decide,
        builder: (_, s) => DecideScreen(
          initialOptions: (s.uri.queryParameters['o'] ?? '').split('|').where((e) => e.trim().isNotEmpty).toList(),
        ),
      ),
      GoRoute(path: Routes.calc, builder: (_, _) => const CalculatorScreen()),
      GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen()),
      GoRoute(path: '/journal/new', builder: (_, _) => const JournalEditorScreen()),
      GoRoute(
        path: '/journal/:id',
        builder: (_, s) => JournalReadScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.money,
        builder: (_, s) => MoneyScreen(
          initialTab: switch (s.uri.queryParameters['tab']) {
            'activity' => 1,
            'plan' => 2,
            _ => 0,
          },
        ),
      ),
      GoRoute(path: Routes.score, builder: (_, _) => const ScoreScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.privacy, builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: Routes.memory, builder: (_, _) => const MemoryScreen()),
      GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen()),
      GoRoute(
        path: '${Routes.legal}/:doc',
        builder: (_, s) => LegalScreen(doc: s.pathParameters['doc'] == 'terms' ? LegalDoc.terms : LegalDoc.privacy),
      ),
      GoRoute(
        path: Routes.premium,
        builder: (_, s) => PaywallScreen(source: s.uri.queryParameters['from'] ?? 'unknown'),
      ),
      GoRoute(path: Routes.weekly, builder: (_, _) => const ReportScreen(monthly: false)),
      GoRoute(path: Routes.monthly, builder: (_, _) => const ReportScreen(monthly: true)),
      GoRoute(path: Routes.habits, builder: (_, _) => const HabitsScreen()),
      GoRoute(path: '/routines', builder: (_, _) => const RoutinesScreen()),
      GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
      GoRoute(
        path: '/goals/:id',
        builder: (_, s) => GoalDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/review', builder: (_, _) => const WeeklyReviewScreen()),
      GoRoute(path: Routes.mood, builder: (_, _) => const MoodScreen()),
      GoRoute(path: Routes.journal, builder: (_, _) => const JournalScreen()),
      GoRoute(
        path: Routes.food,
        builder: (_, s) => FoodScreen(
          initialTab: switch (s.uri.queryParameters['tab']) {
            'recipes' => 1,
            'week' => 2,
            _ => 0,
          },
        ),
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) =>
            RecipeScreen(id: s.pathParameters['id'], recipe: s.extra is Recipe ? s.extra! as Recipe : null),
      ),
      GoRoute(path: Routes.pantry, builder: (_, _) => const PantryScreen()),
      GoRoute(path: Routes.shopping, builder: (_, _) => const ShoppingScreen()),
      GoRoute(path: Routes.news, builder: (_, _) => const NewsScreen()),
      GoRoute(path: Routes.achievements, builder: (_, _) => const AchievementsScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
