import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../lio/lio_companion.dart';

/// Bottom navigation: HOME · PLAN · LIFE · AI (Money lives inside Life).
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final online = ref.watch(onlineProvider).value ?? true;
    final showLio = ref.watch(settingsProvider.select((s) => s.showLio));
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              if (!online) SafeArea(bottom: false, child: const OfflineBanner()),
              Expanded(
                child: MediaQuery.removePadding(context: context, removeTop: !online, child: shell),
              ),
            ],
          ),
          if (showLio) Positioned.fill(child: LioCompanion(tab: shell.currentIndex)),
        ],
      ),
      bottomNavigationBar: _FloatingNavBar(
        index: shell.currentIndex,
        onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          (Icons.wb_sunny_outlined, Icons.wb_sunny_rounded, l.navHome),
          (Icons.event_note_outlined, Icons.event_note_rounded, l.navPlan),
          (Icons.spa_outlined, Icons.spa_rounded, l.navLife),
          (Icons.auto_awesome_outlined, Icons.auto_awesome, l.navAi),
        ],
      ),
    );
  }
}

/// Floating, rounded tab bar with a sliding pill under the active icon.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.index, required this.onSelect, required this.items});

  final int index;
  final ValueChanged<int> onSelect;
  final List<(IconData, IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: Space.sm),
      child: Container(
        margin: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.lg, Space.xs),
        height: 68,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          boxShadow: [
            if (b == Brightness.light) ...Shadows.soft(b),
            if (b == Brightness.light)
              BoxShadow(
                color: const Color(0xFF3B2A1E).withValues(alpha: 0.06),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
          ],
          border: b == Brightness.dark ? Border.all(color: context.semantic.border) : null,
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavItem(
                  icon: items[i].$1,
                  selectedIcon: items[i].$2,
                  label: items[i].$3,
                  selected: i == index,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.primary : context.semantic.muted;
    final d = Motion.of(context, Motion.normal);
    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightShape: BoxShape.rectangle,
        containedInkWell: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: d,
              curve: Motion.curve,
              width: selected ? 52 : 36,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? context.colors.primary.withValues(alpha: 0.13) : Colors.transparent,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: AnimatedSwitcher(
                duration: d,
                transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(a), child: c),
                child: Icon(selected ? selectedIcon : icon, key: ValueKey(selected), size: 22, color: color),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: d,
              style: context.text.labelSmall!.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
            ),
          ],
        ),
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
