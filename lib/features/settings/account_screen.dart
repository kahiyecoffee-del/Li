import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../data/local/database_opener.dart';
import '../../services/account/account_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../auth/auth_screen.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;

  Future<void> _signOut() async {
    final l = context.l10n;
    final user = ref.read(sessionProvider).value?.user;
    if (user != null && user.isAnonymous) {
      // Guest data cannot be recovered after signing out.
      if (!await confirmDialog(
        context,
        title: l.deleteConfirmTitle,
        body: l.linkAccountBody,
        confirmLabel: l.signOut,
        destructive: true,
      )) {
        return;
      }
    }
    final s = ref.read(servicesProvider);
    if (user != null) await s.push?.unregister(user.uid);
    await s.notifications.cancelAll();
    await s.auth.signOut();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          title: Text(l.deleteAccount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.deleteAccountBody),
              const SizedBox(height: Space.lg),
              TextField(
                controller: c,
                decoration: InputDecoration(labelText: l.typeDeleteToConfirm),
                onChanged: (_) => set(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: d.semantic.negative),
              onPressed: c.text.trim().toUpperCase() == 'DELETE' ? () => Navigator.pop(d, true) : null,
              child: Text(l.delete),
            ),
          ],
        ),
      ),
    );
    c.dispose();
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final services = ref.read(servicesProvider);
    final session = ref.read(sessionProvider).value!;
    try {
      unawaited(services.analytics.log(AnalyticsEvent.accountDeleted));
      await services.push?.unregister(session.user.uid);
      await AccountService(
        store: session.store,
        journal: session.repos.journal,
        journalKeys: services.journalKeys,
        functions: services.cloudEnabled && !session.user.isLocalOnly ? services.functions : null,
      ).deleteEverything();
      await services.notifications.cancelAll();
      await services.auth.deleteCurrentUser();
      await services.auth.signOut();
      await DatabaseOpener.deleteForUser(session.user.uid);
    } catch (e) {
      if (mounted) showSnack(context, l.failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(authUserProvider).value;
    final cloud = ref.watch(servicesProvider).cloudEnabled;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAccount)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(Space.page),
          children: [
            if (_busy) const LinearProgressIndicator(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_circle_outlined, size: 40),
              title: Text(user?.email ?? l.guestAccount),
              subtitle: Text(user?.provider.name ?? ''),
            ),
            if (user != null && user.isAnonymous && cloud) ...[
              const SizedBox(height: Space.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.linkAccountTitle, style: context.text.titleMedium),
                    const SizedBox(height: Space.xs),
                    Text(l.linkAccountBody, style: context.text.bodySmall),
                    const SizedBox(height: Space.md),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => const AuthScreen(mode: AuthMode.link))),
                      child: Text(l.linkAccountTitle),
                    ),
                  ],
                ),
              ),
            ],
            if (user != null && user.isLocalOnly)
              Padding(
                padding: const EdgeInsets.only(top: Space.md),
                child: Text(l.localModeNotice, style: context.text.bodySmall),
              ),
            const SizedBox(height: Space.xl),
            OutlinedButton.icon(onPressed: _signOut, icon: const Icon(Icons.logout), label: Text(l.signOut)),
            const SizedBox(height: Space.xxl),
            Text(l.deleteAccountBody, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: context.semantic.negative),
              onPressed: _delete,
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l.deleteAccount),
            ),
          ],
        ),
      ),
    );
  }
}
