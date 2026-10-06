import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
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

/// Keeps every tab alive (like an IndexedStack) and plays a short
/// fade + rise when a tab becomes active.
class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [for (var i = 0; i < children.length; i++) _Branch(active: i == currentIndex, child: children[i])],
  );
}

class _Branch extends StatefulWidget {
  const _Branch({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Branch> createState() => _BranchState();
}

class _BranchState extends State<_Branch> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.normal,
    value: widget.active ? 1 : 0,
  );
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Motion.curve);

  @override
  void didUpdateWidget(_Branch old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    } else if (!widget.active) {
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !widget.active,
    child: TickerMode(
      enabled: widget.active,
      child: FadeTransition(
        opacity: _a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(_a),
          child: widget.child,
        ),
      ),
    ),
  );
}
