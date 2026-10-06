import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/widgets/common.dart';

/// Bottom navigation: HOME · PLAN · MONEY · LIFE · AI.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final online = ref.watch(onlineProvider).value ?? true;
    return Scaffold(
      body: Column(
        children: [
          if (!online) SafeArea(bottom: false, child: const OfflineBanner()),
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: !online, child: shell),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny_rounded),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note_rounded),
            label: l.navPlan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: l.navMoney,
          ),
          NavigationDestination(
            icon: const Icon(Icons.spa_outlined),
            selectedIcon: const Icon(Icons.spa_rounded),
            label: l.navLife,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: l.navAi,
          ),
        ],
      ),
    );
  }
}

/// Top-right Profile / Settings entry used on every tab's app bar.
class ProfileButton extends ConsumerWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileProvider.select((p) => p.value?.name ?? ''));
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        tooltip: context.l10n.profileAndSettings,
        onPressed: () => context.push('/settings'),
        icon: CircleAvatar(
          radius: 17,
          child: name.isEmpty ? const Icon(Icons.person_outline, size: 20) : Text(name.characters.first.toUpperCase()),
        ),
      ),
    );
  }
}
