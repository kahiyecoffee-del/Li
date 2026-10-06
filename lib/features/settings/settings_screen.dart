import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/enums.dart';
import '../../l10n/gen/app_localizations.dart';
import 'city_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.asTab = false});

  /// Shown as the Profile tab (bottom bar) rather than a pushed page.
  final bool asTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final profile = ref.watch(profileProvider).value;
    final premium = ref.watch(isPremiumProvider);
    final session = ref.watch(sessionProvider).value;
    final pending = ref.watch(outboxCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(asTab ? l.navProfile : l.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          if (!premium)
            Padding(
              padding: const EdgeInsets.all(Space.page),
              child: AppCard(
                onTap: () => context.push('/premium?from=settings'),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined, color: context.colors.primary),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.premiumTitle, style: context.text.titleMedium),
                          Text(l.premiumSubtitle, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          _Header(l.settingsProfile),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(profile?.name.isNotEmpty == true ? profile!.name : l.onbNameHint),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: () => _editName(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.location_city_outlined),
            title: Text(l.city),
            subtitle: Text(profile?.place?.name ?? l.setCityForWeather),
            onTap: () async {
              final p = await pickCity(context);
              if (p != null && profile != null) await ref.read(actionsProvider).saveProfile(profile.copyWith(place: p));
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes_outlined),
            title: Text(l.onbFocusTitle),
            subtitle: Text(profile?.focusAreas.map(l.focusArea).join(', ') ?? ''),
            onTap: () => _editFocus(context, ref),
          ),
          _Header(l.settingsAppearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page, vertical: Space.sm),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
                ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => ctrl.update((x) => x.copyWith(themeMode: s.first)),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.contrast),
            title: Text(l.highContrast),
            value: settings.highContrast,
            onChanged: (v) => ctrl.update((x) => x.copyWith(highContrast: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.emoji_nature_outlined),
            title: Text(l.lioSetting),
            subtitle: Text(l.lioSettingHelp),
            value: settings.showLio,
            onChanged: (v) => ctrl.update((x) => x.copyWith(showLio: v)),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.language),
            subtitle: Text(settings.localeCode == null ? l.languageSystem : _languageName(settings.localeCode!)),
            onTap: () => _pickLanguage(context, ref),
          ),
          _Header(l.settingsNotifications),
          RadioGroup<NotificationFrequency>(
            groupValue: settings.notificationFrequency,
            onChanged: (v) => ctrl.update((x) => x.copyWith(notificationFrequency: v)),
            child: Column(
              children: NotificationFrequency.values
                  .map((f) => RadioListTile<NotificationFrequency>(value: f, title: Text(l.notificationFrequency(f))))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Text(l.notifExplain, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
          ),
          _Header(l.settingsPrivacy),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(l.settingsPrivacy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: Text(l.settingsAiMemory),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/memory'),
          ),
          _Header(l.settingsAccount),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: Text(l.settingsAccount),
            subtitle: Text(session?.user.email ?? l.guestAccount),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/account'),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l.syncStatus),
            subtitle: Text(
              session?.sync == null ? l.syncLocalOnly : (pending == 0 ? l.syncUpToDate : l.syncPending(pending)),
            ),
            onTap: session?.sync == null ? null : () => session!.sync!.sync().ignore(),
          ),
          _Header(l.settingsAbout),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(l.privacyPolicy),
            onTap: () => context.push('/legal/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l.termsOfService),
            onTap: () => context.push('/legal/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.appName),
            subtitle: Text(l.version(AppConfig.appVersion)),
          ),
        ],
      ),
    );
  }

  static String _languageName(String code) => switch (code) {
    'en' => 'English',
    'tr' => 'Türkçe',
    'es' => 'Español',
    'pt' => 'Português',
    'de' => 'Deutsch',
    'fr' => 'Français',
    'it' => 'Italiano',
    'ar' => 'العربية',
    'ja' => '日本語',
    'ko' => '한국어',
    'hi' => 'हिन्दी',
    _ => code,
  };

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final current = ref.read(settingsProvider).localeCode;
    final codes = [null, ...AppLocalizations.supportedLocales.map((x) => x.languageCode)];
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (c) => SafeArea(
        child: RadioGroup<String>(
          groupValue: current ?? '',
          onChanged: (v) => Navigator.pop(c, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: codes
                .map(
                  (code) => RadioListTile<String>(
                    value: code ?? '',
                    title: Text(code == null ? l.languageSystem : _languageName(code)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (picked == null) return;
    await ref
        .read(settingsProvider.notifier)
        .update((s) => picked.isEmpty ? s.copyWith(clearLocale: true) : s.copyWith(localeCode: picked));
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    final c = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.onbNameTitle),
        content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(l.save)),
        ],
      ),
    );
    c.dispose();
    if (name != null && name.isNotEmpty) await ref.read(actionsProvider).saveProfile(profile.copyWith(name: name));
  }

  Future<void> _editFocus(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    final selected = {...profile.focusAreas};
    final l = context.l10n;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.onbFocusTitle, style: c.text.titleLarge),
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: FocusArea.values
                    .map(
                      (f) => FilterChip(
                        label: Text(l.focusArea(f)),
                        selected: selected.contains(f),
                        onSelected: (v) => set(() => v ? selected.add(f) : selected.remove(f)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: Space.xl),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.save)),
            ],
          ),
        ),
      ),
    );
    if (ok == true) await ref.read(actionsProvider).saveProfile(profile.copyWith(focusAreas: selected));
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.sm),
    child: Semantics(
      header: true,
      child: Text(
        context.upper(text),
        style: context.text.labelSmall?.copyWith(color: context.semantic.muted, letterSpacing: 1),
      ),
    ),
  );
}
