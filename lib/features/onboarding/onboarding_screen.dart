import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/mascot.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/user_profile.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/config/feature_flags.dart';
import '../settings/city_picker.dart';

enum _Step { name, focus, income, savings, routine, food, notifications, location, ready }

/// First-run setup, designed to take 60–90 seconds. Every step except the
/// name and focus areas is optional. The `onboarding` experiment's "short"
/// variant skips savings, routine and food (they can be set later).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  final _name = TextEditingController();
  final _income = TextEditingController();
  final _fixed = TextEditingController();
  final _savings = TextEditingController();
  final _allergies = TextEditingController();
  final _focus = <FocusArea>{};
  late String _currency;
  DayTime _wake = DayTime.hm(7, 0);
  DayTime _sleep = DayTime.hm(23, 0);
  String _diet = 'none';
  Place? _place;
  bool _notificationsAllowed = false;
  bool _saving = false;
  int _index = 0;
  late final List<_Step> _steps;
  late final String _variant;

  @override
  void initState() {
    super.initState();
    final services = ref.read(servicesProvider);
    _variant = Experiments(services.remote, (e, v) {
      unawaited(services.analytics.log(AnalyticsEvent.experimentExposure, {'experiment': e.key, 'variant': v}));
    }).variant(Experiment.onboarding);
    _steps = _Step.values
        .where((s) => _variant != 'short' || !{_Step.savings, _Step.routine, _Step.food}.contains(s))
        .toList();
    unawaited(services.analytics.log(AnalyticsEvent.onboardingStarted, {'variant': _variant}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currency = defaultCurrencyForLocale(Localizations.localeOf(context).toLanguageTag());
  }

  @override
  void dispose() {
    for (final c in [_pages, _name, _income, _fixed, _savings, _allergies]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canContinue => switch (_steps[_index]) {
    _Step.name => _name.text.trim().isNotEmpty,
    _Step.focus => _focus.isNotEmpty,
    _ => true,
  };

  Future<void> _next() async {
    unawaited(
      ref.read(servicesProvider).analytics.log(AnalyticsEvent.onboardingStepCompleted, {'step': _steps[_index].name}),
    );
    if (_index == _steps.length - 1) return _finish();
    FocusScope.of(context).unfocus();
    setState(() => _index++);
    await _pages.animateToPage(_index, duration: Motion.normal, curve: Motion.curve);
  }

  Future<void> _back() async {
    if (_index == 0) return;
    setState(() => _index--);
    await _pages.animateToPage(_index, duration: Motion.normal, curve: Motion.curve);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    final actions = ref.read(actionsProvider);
    final l = context.l10n;
    // Seed one starter habit per relevant focus area so day one has value.
    if (_focus.contains(FocusArea.health)) {
      await actions.saveHabit(
        Habit(
          id: newId(),
          updatedAt: now,
          name: l.habitWater,
          type: HabitType.water,
          targetPerDay: 8,
          unit: '🥛',
          createdAt: now,
        ),
        isNew: true,
      );
    }
    if (_focus.contains(FocusArea.habits)) {
      await actions.saveHabit(
        Habit(
          id: newId(),
          updatedAt: now,
          name: l.habitReading,
          type: HabitType.reading,
          unit: '10 min',
          createdAt: now,
        ),
        isNew: true,
      );
    }
    final allergies = _allergies.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    await actions.saveProfile(
      UserProfile(
        updatedAt: now,
        name: _name.text.trim(),
        focusAreas: _focus,
        currency: _currency,
        monthlyIncomeMinor: Money.parseMinor(_income.text),
        fixedExpensesMinor: Money.parseMinor(_fixed.text),
        savingsGoalMinor: Money.parseMinor(_savings.text),
        wakeTime: _wake,
        sleepTime: _sleep,
        food: FoodPreferences(diet: _diet, allergies: allergies),
        place: _place,
        onboardingCompleted: true,
        installedAt: now,
      ),
    );
    unawaited(
      ref.read(servicesProvider).analytics.log(AnalyticsEvent.onboardingCompleted, {
        'variant': _variant,
        'focus_count': _focus.length,
        'has_budget': _income.text.isNotEmpty ? 1 : 0,
      }),
    );
    // The router redirects to Home once the profile is saved.
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final step = _steps[_index];
    final isLast = step == _Step.ready;
    return Scaffold(
      appBar: AppBar(
        leading: _index > 0 && !isLast ? BackButton(onPressed: _back) : null,
        title: Text(l.stepOf(_index + 1, _steps.length), style: context.text.labelMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: LinearProgressIndicator(
              value: (_index + 1) / _steps.length,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        actions: [
          if (!isLast && step != _Step.name && step != _Step.focus) TextButton(onPressed: _next, child: Text(l.skip)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: _steps.map(_page).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.page),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canContinue && !_saving ? _next : null,
                  child: Text(isLast ? l.onbOpenHome : l.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scaffold({required String title, String? subtitle, required List<Widget> children}) => ListView(
    padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.xl),
    children: [
      Semantics(header: true, child: Text(title, style: context.text.headlineMedium)),
      if (subtitle != null) ...[
        const SizedBox(height: Space.sm),
        Text(subtitle, style: context.text.bodyLarge?.copyWith(color: context.semantic.muted)),
      ],
      const SizedBox(height: Space.xl),
      ...children,
    ],
  );

  Widget _moneyField(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
    decoration: InputDecoration(labelText: label, suffixText: _currency),
  );

  Future<DayTime?> _pickTime(DayTime initial) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    return t == null ? null : DayTime.hm(t.hour, t.minute);
  }

  Widget _page(_Step s) {
    final l = context.l10n;
    switch (s) {
      case _Step.name:
        return _scaffold(
          title: l.onbNameTitle,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(hintText: l.onbNameHint),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _canContinue ? _next() : null,
            ),
          ],
        );
      case _Step.focus:
        return _scaffold(
          title: l.onbFocusTitle,
          subtitle: l.onbFocusSubtitle,
          children: [
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: FocusArea.values
                  .map(
                    (f) => FilterChip(
                      label: Text(l.focusArea(f)),
                      selected: _focus.contains(f),
                      onSelected: (v) => setState(() => v ? _focus.add(f) : _focus.remove(f)),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      case _Step.income:
        return _scaffold(
          title: l.onbIncomeTitle,
          subtitle: l.onbIncomeSubtitle,
          children: [
            _moneyField(_income, l.moneyIncome),
            const SizedBox(height: Space.md),
            _moneyField(_fixed, l.onbFixedLabel),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(labelText: l.currency),
              items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _currency = v ?? _currency),
            ),
          ],
        );
      case _Step.savings:
        return _scaffold(
          title: l.onbSavingsTitle,
          subtitle: l.onbSavingsSubtitle,
          children: [_moneyField(_savings, l.moneySaved)],
        );
      case _Step.routine:
        return _scaffold(
          title: l.onbRoutineTitle,
          children: [
            ListTile(
              title: Text(l.onbWake),
              trailing: Text(_wake.toString(), style: context.text.titleMedium),
              onTap: () async {
                final t = await _pickTime(_wake);
                if (t != null) setState(() => _wake = t);
              },
            ),
            ListTile(
              title: Text(l.onbSleep),
              trailing: Text(_sleep.toString(), style: context.text.titleMedium),
              onTap: () async {
                final t = await _pickTime(_sleep);
                if (t != null) setState(() => _sleep = t);
              },
            ),
          ],
        );
      case _Step.food:
        return _scaffold(
          title: l.onbFoodTitle,
          children: [
            Text(l.onbDiet, style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: _diets
                  .map(
                    (d) => ChoiceChip(
                      label: Text(l.diet(d)),
                      selected: _diet == d,
                      onSelected: (_) => setState(() => _diet = d),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Space.xl),
            TextField(
              controller: _allergies,
              decoration: InputDecoration(labelText: l.onbAllergies, hintText: l.onbAllergiesHint),
            ),
          ],
        );
      case _Step.notifications:
        return _scaffold(
          title: l.onbNotifTitle,
          subtitle: l.onbNotifBody,
          children: [
            FilledButton.tonalIcon(
              onPressed: _notificationsAllowed
                  ? null
                  : () async {
                      final ok = await ref.read(servicesProvider).notifications.requestPermission();
                      setState(() => _notificationsAllowed = ok);
                      if (ok) await _next();
                    },
              icon: Icon(_notificationsAllowed ? Icons.check : Icons.notifications_active_outlined),
              label: Text(l.onbNotifAllow),
            ),
          ],
        );
      case _Step.location:
        return _scaffold(
          title: l.onbLocationTitle,
          subtitle: l.onbLocationBody,
          children: [
            FilledButton.tonalIcon(
              onPressed: () async {
                try {
                  final p = await ref.read(servicesProvider).location.currentPlace(l.myLocation);
                  if (p != null) setState(() => _place = p);
                } catch (_) {}
              },
              icon: const Icon(Icons.my_location),
              label: Text(l.onbUseLocation),
            ),
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: () async {
                final p = await pickCity(context);
                if (p != null) setState(() => _place = p);
              },
              icon: const Icon(Icons.search),
              label: Text(l.onbPickCity),
            ),
            if (_place != null) ...[
              const SizedBox(height: Space.lg),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(_place!.name),
              ),
            ],
          ],
        );
      case _Step.ready:
        return _scaffold(
          title: l.onbReadyTitle,
          subtitle: l.onbReadyBody,
          children: const [Center(child: Mascot(mood: MascotMood.heart, size: 180))],
        );
    }
  }
}

const _diets = ['none', 'vegetarian', 'vegan', 'pescatarian', 'keto', 'halal', 'glutenFree'];
const _currencies = [
  'TRY',
  'USD',
  'EUR',
  'GBP',
  'BRL',
  'MXN',
  'JPY',
  'KRW',
  'INR',
  'SAR',
  'AED',
  'EGP',
  'CAD',
  'AUD',
  'ARS',
  'CHF',
];
