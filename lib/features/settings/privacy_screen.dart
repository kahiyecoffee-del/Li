import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../services/account/account_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/settings/app_settings.dart';

/// What the AI can see, analytics/crash/ads consent, export and deletion.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final repos = ref.read(reposProvider);

    Future<void> wipe(Future<void> Function() f) async {
      if (!await confirmDialog(
        context,
        title: l.deleteConfirmTitle,
        body: l.deleteConfirmBody,
        confirmLabel: l.delete,
        destructive: true,
      )) {
        return;
      }
      await f();
      if (context.mounted) showSnack(context, l.deleted);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsPrivacy)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.aiDataTitle, style: context.text.titleLarge),
                const SizedBox(height: Space.sm),
                Text(l.aiDataBody, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
              ],
            ),
          ),
          ...AiDataScope.values.map(
            (scope) => SwitchListTile(
              title: Text(l.scopeLong(scope)),
              value: s.aiScopes.contains(scope),
              onChanged: (v) => ctrl.update(
                (x) => x.copyWith(aiScopes: v ? {...x.aiScopes, scope} : ({...x.aiScopes}..remove(scope))),
              ),
            ),
          ),
          const Divider(height: Space.xxl),
          SwitchListTile(
            title: Text(l.analyticsToggle),
            value: s.analyticsEnabled,
            onChanged: (v) => ctrl.update((x) => x.copyWith(analyticsEnabled: v)),
          ),
          SwitchListTile(
            title: Text(l.crashToggle),
            value: s.crashReportingEnabled,
            onChanged: (v) => ctrl.update((x) => x.copyWith(crashReportingEnabled: v)),
          ),
          SwitchListTile(
            title: Text(l.personalizedAdsToggle),
            value: s.personalizedAds,
            onChanged: (v) => ctrl.update((x) => x.copyWith(personalizedAds: v)),
          ),
          const Divider(height: Space.xxl),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l.exportData),
            onTap: () async {
              final services = ref.read(servicesProvider);
              final session = ref.read(sessionProvider).value!;
              final file = await AccountService(
                store: session.store,
                journal: repos.journal,
                journalKeys: services.journalKeys,
                functions: services.functions,
              ).exportData(uid: session.user.uid);
              unawaited(services.analytics.log(AnalyticsEvent.dataExported));
              if (context.mounted) showSnack(context, l.exportDone(file.path));
            },
          ),
          _Header(l.deleteDataSection),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: Text(l.deleteJournal),
            onTap: () => wipe(repos.journal.deleteAll),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(l.deleteExpenses),
            onTap: () => wipe(repos.transactions.deleteAll),
          ),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: Text(l.deleteMemories),
            onTap: () => wipe(repos.memories.deleteAll),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(l.deleteChats),
            onTap: () => wipe(repos.conversations.deleteAll),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: context.semantic.negative),
            title: Text(l.deleteAccount, style: TextStyle(color: context.semantic.negative)),
            onTap: () => context.push('/settings/account'),
          ),
          const Divider(height: Space.xxl),
          ListTile(title: Text(l.privacyPolicy), onTap: () => context.push('/legal/privacy')),
          ListTile(title: Text(l.termsOfService), onTap: () => context.push('/legal/terms')),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.sm),
    child: Text(
      context.upper(text),
      style: context.text.labelSmall?.copyWith(color: context.semantic.muted, letterSpacing: 1),
    ),
  );
}
