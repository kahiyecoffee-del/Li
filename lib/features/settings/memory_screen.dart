import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../services/ai/memory_manager.dart';
import '../../services/config/feature_flags.dart';
import '../../services/config/remote_config_service.dart';

/// "What do you know about me?" — every memory is visible and deletable.
class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final enabled = ref.watch(settingsProvider).aiMemoryEnabled;
    final memories = ref.watch(memoriesProvider).list;
    final services = ref.watch(servicesProvider);
    final premium = ref.watch(isPremiumProvider);
    final limited = !premium && services.flags.isPremiumOnly(PremiumFeature.aiMemoryUnlimited);
    final grouped = MemoryManager.grouped(memories);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAiMemory)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          SwitchListTile(
            title: Text(l.memoryEnabledToggle),
            value: enabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(aiMemoryEnabled: v)),
          ),
          if (limited)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              child: Text(
                l.memoryLimit(memories.length, services.remote.getInt(RcKeys.freeMemoryLimit)),
                style: context.text.bodySmall,
              ),
            ),
          if (memories.isEmpty) EmptyState(icon: Icons.psychology_outlined, message: l.memoryEmpty),
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.xs),
              child: Text(l.memoryCategory(entry.key), style: context.text.titleSmall),
            ),
            ...entry.value.map(
              (m) => ListTile(
                title: Text(m.content),
                trailing: IconButton(
                  tooltip: l.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(reposProvider).memories.delete(m.id),
                ),
              ),
            ),
          ],
          if (memories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(Space.page),
              child: OutlinedButton(
                onPressed: () async {
                  if (await confirmDialog(
                    context,
                    title: l.deleteConfirmTitle,
                    body: l.deleteConfirmBody,
                    destructive: true,
                  )) {
                    await ref.read(reposProvider).memories.deleteAll();
                  }
                },
                child: Text(l.memoryDeleteAll),
              ),
            ),
        ],
      ),
    );
  }
}
