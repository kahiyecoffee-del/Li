import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../services/ai/offline/offline_model_service.dart';
import '../../services/config/feature_flags.dart';
import '../../services/config/remote_config_service.dart';

/// Download / delete the on-device assistant model.
class OfflineAiScreen extends ConsumerWidget {
  const OfflineAiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final url = services.remote.getString(RcKeys.offlineModelUrl);
    final size = services.remote.getInt(RcKeys.offlineModelSizeMb);
    final status = ref.watch(offlineModelStatusProvider).value ?? services.offlineModel.current;
    final locked = services.flags.isPremiumOnly(PremiumFeature.offlineAi) && !ref.watch(isPremiumProvider);
    final settings = ref.watch(settingsProvider);

    Widget action() {
      if (url.isEmpty) return Text(l.offlineAiUnavailable);
      if (locked && status.state != OfflineModelState.ready) {
        return FilledButton(onPressed: () => context.push('/premium?from=offline_ai'), child: Text(l.premiumTitle));
      }
      return switch (status.state) {
        OfflineModelState.downloading => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProgressBar(value: status.progress / 100, label: l.offlineAiDownloading(status.progress)),
            const SizedBox(height: Space.sm),
            Text(l.offlineAiDownloading(status.progress)),
            TextButton(onPressed: services.offlineModel.cancel, child: Text(l.cancel)),
          ],
        ),
        OfflineModelState.ready => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: context.semantic.positive),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(l.offlineAiReady, style: context.text.titleSmall)),
              ],
            ),
            const SizedBox(height: Space.md),
            OutlinedButton(
              onPressed: () async {
                if (await confirmDialog(
                  context,
                  title: l.offlineAiDelete,
                  body: l.deleteConfirmBody,
                  destructive: true,
                )) {
                  await services.offlineModel.remove();
                }
              },
              child: Text(l.offlineAiDelete),
            ),
          ],
        ),
        OfflineModelState.notInstalled || OfflineModelState.error => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status.state == OfflineModelState.error)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text(l.offlineAiError, style: TextStyle(color: context.semantic.negative)),
              ),
            FilledButton.icon(
              onPressed: () => unawaited(services.offlineModel.install(url)),
              icon: const Icon(Icons.download),
              label: Text(l.offlineAiDownload),
            ),
          ],
        ),
      };
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.offlineAiTitle)),
      body: PageList(
        children: [
          Text(l.offlineAiBody, style: context.text.bodyLarge),
          const SizedBox(height: Space.sm),
          Text(l.offlineAiSize(size), style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
          const SizedBox(height: Space.xl),
          AppCard(child: action()),
          if (status.ready) ...[
            const SizedBox(height: Space.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.offlineAiPrefer),
              subtitle: Text(l.offlineAiPreferHelp),
              value: settings.preferOfflineAi,
              onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(preferOfflineAi: v)),
            ),
          ],
          const SizedBox(height: Space.xl),
          Text(l.localModelsInfo, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
        ],
      ),
    );
  }
}
