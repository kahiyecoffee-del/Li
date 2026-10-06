import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/mascot.dart';
import '../../services/ai/offline/offline_model_service.dart';
import '../../services/config/feature_flags.dart';
import '../../services/config/remote_config_service.dart';

/// A downloadable on-device model variant.
class _Variant {
  const _Variant(this.url, this.sizeMb, {required this.plus});

  final String url;
  final int sizeMb;
  final bool plus;

  String get id => EdgeAiOfflineModelService.modelIdFor(url);
}

/// Pick, download, switch or delete Lio's on-device model.
class OfflineAiScreen extends ConsumerStatefulWidget {
  const OfflineAiScreen({super.key});

  @override
  ConsumerState<OfflineAiScreen> createState() => _OfflineAiScreenState();
}

class _OfflineAiScreenState extends ConsumerState<OfflineAiScreen> {
  bool? _plus;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final lite = _Variant(
      services.remote.getString(RcKeys.offlineModelUrl),
      services.remote.getInt(RcKeys.offlineModelSizeMb),
      plus: false,
    );
    final plusUrl = services.remote.getString(RcKeys.offlineModelPlusUrl);
    final plus = plusUrl.isEmpty
        ? null
        : _Variant(plusUrl, services.remote.getInt(RcKeys.offlineModelPlusSizeMb), plus: true);
    final status = ref.watch(offlineModelStatusProvider).value ?? services.offlineModel.current;
    final installed = status.ready ? services.offlineModel.installedId : null;
    final selected = (_plus ?? (plus != null && installed == plus.id)) && plus != null ? plus : lite;
    final url = selected.url;
    final locked = services.flags.isPremiumOnly(PremiumFeature.offlineAi) && !ref.watch(isPremiumProvider);
    final settings = ref.watch(settingsProvider);
    final name = selected.plus ? l.offlinePlusTitle : l.offlineLiteTitle;

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
        OfflineModelState.ready when installed != null && installed != selected.id => FilledButton.icon(
          onPressed: () => unawaited(services.offlineModel.install(url)),
          icon: const Icon(Icons.swap_horiz_rounded),
          label: Text(l.offlineSwitchTo(name)),
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
              label: Text('${l.offlineAiDownload} · $name'),
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
          const SizedBox(height: Space.md),
          for (final v in [lite, ?plus])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: _VariantTile(
                title: v.plus ? l.offlinePlusTitle : l.offlineLiteTitle,
                body: v.plus ? l.offlinePlusBody(v.sizeMb) : l.offlineLiteBody(v.sizeMb),
                badge: installed == v.id ? l.offlineInstalled : (v.plus ? null : l.offlineRecommended),
                selected: selected == v,
                onTap: status.state == OfflineModelState.downloading ? null : () => setState(() => _plus = v.plus),
              ),
            ),
          Text(l.offlineOneAtATime, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
          const SizedBox(height: Space.lg),
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

class _VariantTile extends StatelessWidget {
  const _VariantTile({
    required this.title,
    required this.body,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
  final String? badge;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: AnimatedContainer(
      duration: Motion.of(context, Motion.normal),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg + 2),
        border: Border.all(color: selected ? context.colors.primary : Colors.transparent, width: 2),
      ),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Mascot(mood: selected ? MascotMood.happy : MascotMood.front, size: 44, float: false),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: context.text.titleMedium),
                      if (badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          child: Text(badge!, style: context.text.labelSmall?.copyWith(color: context.colors.primary)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? context.colors.primary : context.semantic.muted,
            ),
          ],
        ),
      ),
    ),
  );
}
