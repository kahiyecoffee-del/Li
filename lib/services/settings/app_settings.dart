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
    this.showLio = true,
    this.journalReminder = true,
    this.planReminder = true,
    this.lioLearnsJournal = true,
    this.assistantName = 'Lio',
    this.favoriteRecipes = const {},
    this.planBreak = 0,
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

  /// Lio, the floating companion that offers tips and inspiration.
  final bool showLio;

  /// Evening "write in your journal" and morning "plan your day" nudges.
  final bool journalReminder;
  final bool planReminder;

  /// Lio may read journal entries on the device to learn mood patterns.
  final bool lioLearnsJournal;

  /// What the user calls the assistant ("Lio" by default).
  final String assistantName;

  /// Ids of recipes the user hearted (kept on the device).
  final Set<String> favoriteRecipes;

  /// Minutes the planner leaves between tasks when it moves them.
  final int planBreak;

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
    bool? showLio,
    bool? journalReminder,
    bool? planReminder,
    bool? lioLearnsJournal,
    String? assistantName,
    Set<String>? favoriteRecipes,
    int? planBreak,
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
    showLio: showLio ?? this.showLio,
    journalReminder: journalReminder ?? this.journalReminder,
    planReminder: planReminder ?? this.planReminder,
    lioLearnsJournal: lioLearnsJournal ?? this.lioLearnsJournal,
    assistantName: assistantName ?? this.assistantName,
    favoriteRecipes: favoriteRecipes ?? this.favoriteRecipes,
    planBreak: planBreak ?? this.planBreak,
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
      showLio: _p.getBool('showLio') ?? true,
      journalReminder: _p.getBool('journalReminder') ?? true,
      planReminder: _p.getBool('planReminder') ?? true,
      lioLearnsJournal: _p.getBool('lioLearnsJournal') ?? true,
      assistantName: _p.getString('assistantName') ?? 'Lio',
      favoriteRecipes: {...?_p.getStringList('favoriteRecipes')},
      planBreak: _p.getInt('planBreak') ?? 0,
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
    await _p.setBool('showLio', s.showLio);
    await _p.setInt('planBreak', s.planBreak);
    await _p.setBool('journalReminder', s.journalReminder);
    await _p.setBool('planReminder', s.planReminder);
    await _p.setBool('lioLearnsJournal', s.lioLearnsJournal);
    await _p.setString('assistantName', s.assistantName);
    await _p.setStringList('favoriteRecipes', s.favoriteRecipes.toList());
  }
}
