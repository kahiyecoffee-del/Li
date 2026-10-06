import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/mascot.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      // Anonymous account: zero friction; can be linked to Google/email later.
      await ref.read(servicesProvider).auth.signInAnonymously();
    } catch (e) {
      if (mounted) showSnack(context, context.l10n.failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cloud = ref.watch(servicesProvider).cloudEnabled;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - Space.xl * 2),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    const Center(child: Mascot(mood: MascotMood.excited, size: 170)),
                    const SizedBox(height: Space.xl),
                    Text(l.welcomeTitle, style: context.text.headlineMedium),
                    const SizedBox(height: Space.lg),
                    Text(l.welcomeBody, style: context.text.bodyLarge?.copyWith(color: context.semantic.muted)),
                    const Spacer(),
                    if (!cloud)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.lg),
                        child: Text(
                          l.localModeNotice,
                          style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                        ),
                      ),
                    FilledButton(
                      onPressed: _busy ? null : _start,
                      child: _busy
                          ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l.getStarted),
                    ),
                    const SizedBox(height: Space.md),
                    if (cloud)
                      OutlinedButton(
                        onPressed: _busy ? null : () => context.push('/auth?mode=signin'),
                        child: Text(l.haveAccount),
                      ),
                    const SizedBox(height: Space.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(onPressed: () => context.push('/legal/privacy'), child: Text(l.privacyPolicy)),
                        TextButton(onPressed: () => context.push('/legal/terms'), child: Text(l.termsOfService)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
