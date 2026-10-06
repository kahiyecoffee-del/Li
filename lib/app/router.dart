import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/ai_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/home/home_screen.dart';
import '../features/life/achievements_screen.dart';
import '../features/life/food_screen.dart';
import '../features/life/habits_screen.dart';
import '../features/life/journal_screen.dart';
import '../features/life/life_screen.dart';
import '../features/life/mood_screen.dart';
import '../features/life/news_screen.dart';
import '../features/life/pantry_screen.dart';
import '../features/life/shopping_screen.dart';
import '../features/money/money_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/premium/paywall_screen.dart';
import '../features/reports/report_screen.dart';
import '../features/score/score_screen.dart';
import '../features/settings/account_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/memory_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/shell/splash_screen.dart';
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
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.plan, builder: (_, _) => const PlanScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.money, builder: (_, _) => const MoneyScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.life, builder: (_, _) => const LifeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.ai,
                builder: (_, s) => AiScreen(initialPrompt: s.uri.queryParameters['q']),
              ),
            ],
          ),
        ],
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
      GoRoute(path: Routes.mood, builder: (_, _) => const MoodScreen()),
      GoRoute(path: Routes.journal, builder: (_, _) => const JournalScreen()),
      GoRoute(path: Routes.food, builder: (_, _) => const FoodScreen()),
      GoRoute(path: Routes.pantry, builder: (_, _) => const PantryScreen()),
      GoRoute(path: Routes.shopping, builder: (_, _) => const ShoppingScreen()),
      GoRoute(path: Routes.news, builder: (_, _) => const NewsScreen()),
      GoRoute(path: Routes.achievements, builder: (_, _) => const AchievementsScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
