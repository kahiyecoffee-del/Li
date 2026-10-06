import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/mascot.dart';
import '../../services/analytics/analytics_service.dart';
import 'problem_flow.dart';

/// Home: "What should we solve today?" One big input (type, speak or snap a
/// photo), examples that show what Dayly can do, and quick tools.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  bool _listening = false;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<String> _examples(BuildContext context) {
    final l = context.l10n;
    return [l.problemEx1, l.problemEx2, l.problemEx3, l.problemEx4, l.problemEx5, l.problemEx6, l.problemEx7];
  }

  Future<void> _solve([String? text]) async {
    final q = (text ?? _input.text).trim();
    if (q.isEmpty) {
      _focus.requestFocus();
      return;
    }
    _focus.unfocus();
    await openProblem(context, ref, q);
  }

  Future<void> _voice() async {
    final s = ref.read(servicesProvider);
    final l = context.l10n;
    if (_listening) {
      await s.voice.stop();
      return;
    }
    if (!await s.voice.available) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.voiceUnavailable)));
      return;
    }
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _listening = true);
    unawaited(s.analytics.log(AnalyticsEvent.voiceInputUsed));
    final text = await s.voice.listen(
      localeId: lang == 'tr' ? 'tr_TR' : 'en_US',
      onPartial: (p) {
        if (mounted) _input.text = p;
      },
    );
    if (!mounted) return;
    setState(() => _listening = false);
    if (text != null) {
      _input.text = text;
      await _solve(text);
    }
  }

  Future<void> _photo() async {
    final l = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.chooseFromGallery),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(source: source, maxWidth: 2000, imageQuality: 85);
    if (image == null || !mounted) return;
    final s = ref.read(servicesProvider);
    String text;
    try {
      text = (await s.ocr.recognize(image.path)).trim();
    } catch (_) {
      text = '';
    }
    unawaited(s.analytics.log(AnalyticsEvent.photoInputUsed, {'found_text': text.isNotEmpty ? 1 : 0}));
    if (!mounted) return;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.photoNoText)));
      return;
    }
    _input.text = text.length > 1500 ? text.substring(0, 1500) : text;
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = ref.watch(profileProvider.select((p) => p.value?.name ?? ''));
    final examples = _examples(context);
    // A different example each day keeps the hint fresh without timers.
    final hint = examples[DateTime.now().day % examples.length];
    final recent = [...?ref.watch(savedProvider).value]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _focus.unfocus,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, 120),
            children: [
              FadeSlideIn(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? l.homeHelloNoName : l.homeHello(name),
                            style: context.text.titleMedium?.copyWith(color: context.semantic.muted),
                          ),
                          const SizedBox(height: Space.xs),
                          Semantics(header: true, child: Text(l.homeQuestion, style: context.text.headlineMedium)),
                        ],
                      ),
                    ),
                    const Mascot(mood: MascotMood.happy, size: 64),
                  ],
                ),
              ),
              const SizedBox(height: Space.lg),
              FadeSlideIn(
                delay: Motion.fast,
                child: _ProblemInput(
                  controller: _input,
                  focus: _focus,
                  hint: hint,
                  listening: _listening,
                  onSolve: _solve,
                  onVoice: _voice,
                  onPhoto: _photo,
                ),
              ),
              const SizedBox(height: Space.md),
              FadeSlideIn(
                delay: Motion.fast,
                child: Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    for (final e in examples.where((e) => e != hint).take(4))
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 2 * Space.page),
                        child: ActionChip(
                          label: Text(e, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onPressed: () {
                            _input.text = e;
                            _solve(e);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xl),
              const _QuickTools(),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: Space.xl),
                SectionTitle(
                  l.recentlySolved,
                  trailing: TextButton(onPressed: () => context.go('/saved'), child: Text(l.seeAll)),
                ),
                for (final item in recent.take(3))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bookmark_rounded),
                    title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _solve(item.payload['q'] as String? ?? item.title),
                  ),
              ],
              const SizedBox(height: Space.lg),
              AppCard(
                onTap: () => context.push('/today'),
                child: Row(
                  children: [
                    IconBubble(icon: Icons.wb_sunny_rounded, accent: Accent.plan),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.exploreMyDay, style: context.text.titleMedium),
                          Text(
                            l.exploreMyDayBody,
                            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProblemInput extends StatelessWidget {
  const _ProblemInput({
    required this.controller,
    required this.focus,
    required this.hint,
    required this.listening,
    required this.onSolve,
    required this.onVoice,
    required this.onPhoto,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final bool listening;
  final Future<void> Function([String?]) onSolve;
  final VoidCallback onVoice, onPhoto;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: Shadows.soft(Theme.of(context).brightness),
        border: Border.all(color: context.semantic.border),
      ),
      padding: const EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.sm, Space.sm),
      child: Column(
        children: [
          TextField(
            controller: controller,
            focusNode: focus,
            minLines: 2,
            maxLines: 6,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => onSolve(),
            style: context.text.bodyLarge,
            decoration: InputDecoration(
              hintText: listening ? l.listening : '${l.problemHint}\n$hint',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.sm),
            ),
          ),
          Row(
            children: [
              // Speech and on-device text recognition are phone features.
              if (!kIsWeb) ...[
                IconButton(
                  tooltip: l.voiceInput,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onVoice();
                  },
                  isSelected: listening,
                  icon: const Icon(Icons.mic_none_rounded),
                  selectedIcon: Icon(Icons.mic_rounded, color: context.colors.primary),
                ),
                IconButton(tooltip: l.photoInput, onPressed: onPhoto, icon: const Icon(Icons.photo_camera_outlined)),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: () => onSolve(),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l.solve),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTools extends StatelessWidget {
  const _QuickTools();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tools = <(IconData, String, Accent, VoidCallback)>[
      (Icons.account_balance_wallet_rounded, l.quickMoney, Accent.money, () => context.push('/money')),
      (Icons.balance_rounded, l.quickDecide, Accent.insight, () => context.push('/decide')),
      (Icons.restaurant_menu_rounded, l.quickFood, Accent.food, () => context.push('/food')),
      (Icons.calculate_rounded, l.quickCalc, Accent.score, () => context.push('/calc')),
      (
        Icons.edit_note_rounded,
        l.quickWrite,
        Accent.ai,
        () => context.go('/ai?topic=write&n=${DateTime.now().microsecondsSinceEpoch}'),
      ),
      (Icons.event_available_rounded, l.quickPlan, Accent.plan, () => context.push('/plan')),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.md,
      crossAxisSpacing: Space.md,
      childAspectRatio: 1.05,
      children: [
        for (final (icon, label, accent, onTap) in tools)
          AppCard(
            onTap: onTap,
            padding: const EdgeInsets.all(Space.md),
            semanticLabel: label,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBubble(icon: icon, accent: accent, size: 44),
                const SizedBox(height: Space.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
