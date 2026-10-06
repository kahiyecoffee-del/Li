import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/enums.dart';

/// Data categories the user may allow the assistant to see. Each one is sent
/// to the AI backend only when enabled (Settings → Privacy → AI data).
enum AiDataScope { money, tasks, habits, mood, food, journal }

/// Device-level preferences (not synced).
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.highContrast = false,
    this.localeCode,
    this.notificationFrequency = NotificationFrequency.normal,
    this.analyticsEnabled = true,
    this.crashReportingEnabled = true,
    this.aiMemoryEnabled = true,
    this.aiScopes = const {AiDataScope.money, AiDataScope.tasks, AiDataScope.habits, AiDataScope.food},
    this.personalizedAds = true,
  });

  final ThemeMode themeMode;
  final bool highContrast;

  /// `null` follows the device language.
  final String? localeCode;
  final NotificationFrequency notificationFrequency;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
  final bool aiMemoryEnabled;
  final Set<AiDataScope> aiScopes;
  final bool personalizedAds;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? highContrast,
    String? localeCode,
    bool clearLocale = false,
    NotificationFrequency? notificationFrequency,
    bool? analyticsEnabled,
    bool? crashReportingEnabled,
    bool? aiMemoryEnabled,
    Set<AiDataScope>? aiScopes,
    bool? personalizedAds,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    highContrast: highContrast ?? this.highContrast,
    localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
    notificationFrequency: notificationFrequency ?? this.notificationFrequency,
    analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    crashReportingEnabled: crashReportingEnabled ?? this.crashReportingEnabled,
    aiMemoryEnabled: aiMemoryEnabled ?? this.aiMemoryEnabled,
    aiScopes: aiScopes ?? this.aiScopes,
    personalizedAds: personalizedAds ?? this.personalizedAds,
  );
}

class SettingsStore {
  SettingsStore(this._p);

  final SharedPreferences _p;

  AppSettings load() {
    T byName<T extends Enum>(List<T> v, String? n, T d) => v.firstWhere((e) => e.name == n, orElse: () => d);
    final scopes = _p.getStringList('aiScopes');
    return AppSettings(
      themeMode: byName(ThemeMode.values, _p.getString('themeMode'), ThemeMode.system),
      highContrast: _p.getBool('highContrast') ?? false,
      localeCode: _p.getString('locale'),
      notificationFrequency: byName(
        NotificationFrequency.values,
        _p.getString('notifFreq'),
        NotificationFrequency.normal,
      ),
      analyticsEnabled: _p.getBool('analytics') ?? true,
      crashReportingEnabled: _p.getBool('crash') ?? true,
      aiMemoryEnabled: _p.getBool('aiMemory') ?? true,
      aiScopes: scopes == null
          ? const AppSettings().aiScopes
          : scopes.map((s) => byName(AiDataScope.values, s, AiDataScope.money)).toSet(),
      personalizedAds: _p.getBool('personalizedAds') ?? true,
    );
  }

  Future<void> save(AppSettings s) async {
    await _p.setString('themeMode', s.themeMode.name);
    await _p.setBool('highContrast', s.highContrast);
    if (s.localeCode == null) {
      await _p.remove('locale');
    } else {
      await _p.setString('locale', s.localeCode!);
    }
    await _p.setString('notifFreq', s.notificationFrequency.name);
    await _p.setBool('analytics', s.analyticsEnabled);
    await _p.setBool('crash', s.crashReportingEnabled);
    await _p.setBool('aiMemory', s.aiMemoryEnabled);
    await _p.setStringList('aiScopes', s.aiScopes.map((e) => e.name).toList());
    await _p.setBool('personalizedAds', s.personalizedAds);
  }
}
