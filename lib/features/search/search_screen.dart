import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/search/search_text.dart';
import '../plan/task_editor.dart';
import '../problem/problem_flow.dart';

/// One box that finds anything in Dayly: screens, tasks, recipes, spending,
/// list items, saved answers and journal entries. Runs on the phone.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final lang = Localizations.localeOf(context).languageCode;
    final q = _q.text.trim();

    final tools = <(IconData, String, String)>[
      (Icons.event_available_rounded, l.navPlan, '/plan'),
      (Icons.account_balance_wallet_rounded, l.navMoney, '/money'),
      (Icons.restaurant_menu_rounded, l.lifeFood, '/food'),
      (Icons.shopping_cart_rounded, l.lifeShopping, '/shopping'),
      (Icons.repeat_rounded, l.lifeHabits, '/habits'),
      (Icons.menu_book_rounded, l.lifeJournal, '/journal'),
      (Icons.mood_rounded, l.lifeMood, '/mood'),
      (Icons.center_focus_strong_rounded, l.focusTitle, '/focus'),
      (Icons.today_rounded, l.todayInfoTitle, '/today-info'),
      (Icons.auto_mode_rounded, l.routinesTitle, '/routines'),
      (Icons.flag_rounded, l.goalsLife, '/goals'),
      (Icons.event_repeat_rounded, l.reviewTitle, '/review'),
      (Icons.balance_rounded, l.quickDecide, '/decide'),
      (Icons.calculate_rounded, l.calcTitle, '/calc'),
      (Icons.local_post_office_rounded, l.gardenCollection, '/postcards'),
      (Icons.settings_outlined, l.profileAndSettings, '/settings'),
    ];

    final sections = <(String, List<Widget>)>[];
    if (q.isNotEmpty) {
      final t = [
        for (final x in tools)
          if (searchMatches(x.$2, q)) x,
      ];
      if (t.isNotEmpty) {
        sections.add((
          l.searchGoTo,
          [
            for (final x in t.take(5))
              ListTile(
                leading: Icon(x.$1, color: context.colors.primary),
                title: Text(x.$2),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(x.$3),
              ),
          ],
        ));
      }
      final tasks = ref.watch(tasksProvider).list.where((x) => !x.deleted && searchMatches(x.title, q)).toList()
        ..sort((a, b) => (a.isCompleted ? 1 : 0).compareTo(b.isCompleted ? 1 : 0));
      if (tasks.isNotEmpty) {
        sections.add((
          l.searchTasks,
          [
            for (final x in tasks.take(6))
              ListTile(
                leading: Icon(
                  x.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: x.isCompleted ? context.semantic.positive : context.semantic.muted,
                ),
                title: Text(x.title),
                subtitle: x.anchorDate == null ? null : Text(fmt.weekdayDayMonth(x.anchorDate!)),
                onTap: () => showTaskEditor(context, task: x),
              ),
          ],
        ));
      }
      final recipes = RecipeLibrary.all(lang)
          .where((r) => searchMatches('${r.name} ${r.ingredients.join(' ')}', q))
          .toList();
      if (recipes.isNotEmpty) {
        sections.add((
          l.searchRecipes,
          [
            for (final r in recipes.take(5))
              ListTile(
                leading: Icon(Icons.restaurant_rounded, color: context.colors.primary),
                title: Text(r.name),
                subtitle: Text(l.minutesShort(r.prepMinutes)),
                onTap: () => context.push('/recipe/${r.id}'),
              ),
          ],
        ));
      }
      final spends =
          ref
              .watch(transactionsProvider)
              .list
              .where(
                (x) =>
                    !x.deleted &&
                    searchMatches('${x.description} ${x.merchant ?? ''} ${l.expenseCategory(x.category)}', q),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      if (spends.isNotEmpty) {
        sections.add((
          l.searchSpending,
          [
            for (final x in spends.take(5))
              ListTile(
                leading: Icon(Icons.receipt_long_rounded, color: context.colors.primary),
                title: Text(x.description.isEmpty ? l.expenseCategory(x.category) : x.description),
                subtitle: Text(fmt.weekdayDayMonth(x.date)),
                trailing: Text(
                  fmt.money(x.amountMinor),
                  style: context.text.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                onTap: () => context.push('/money?tab=activity'),
              ),
          ],
        ));
      }
      final items = ref.watch(shoppingProvider).list.where((x) => !x.deleted && searchMatches(x.name, q)).toList();
      if (items.isNotEmpty) {
        sections.add((
          l.searchShopping,
          [
            for (final x in items.take(5))
              ListTile(
                leading: Icon(
                  x.checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: context.semantic.muted,
                ),
                title: Text(x.name),
                onTap: () => context.push('/shopping'),
              ),
          ],
        ));
      }
      final saved = [...?ref.watch(savedProvider).value].where((x) => searchMatches('${x.title} ${x.summary}', q));
      if (saved.isNotEmpty) {
        sections.add((
          l.searchSaved,
          [
            for (final x in saved.take(5))
              ListTile(
                leading: Icon(Icons.bookmark_rounded, color: context.colors.primary),
                title: Text(x.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(x.summary, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => openSavedItem(context, ref, x),
              ),
          ],
        ));
      }
      final journal = ref.watch(journalProvider).list.where((x) => !x.deleted && searchMatches(x.text, q)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (journal.isNotEmpty) {
        sections.add((
          l.searchJournal,
          [
            for (final x in journal.take(5))
              ListTile(
                leading: Icon(Icons.menu_book_rounded, color: context.colors.primary),
                title: Text(x.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(fmt.weekdayDayMonth(x.createdAt)),
                onTap: () => context.push('/journal/${x.id}'),
              ),
          ],
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const Key('search-field'),
          controller: _q,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l.searchHint,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: q.isEmpty
                ? null
                : IconButton(
                    tooltip: l.close,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(_q.clear),
                  ),
          ),
        ),
      ),
      body: q.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(Space.page),
              child: Text(l.searchStart, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
            )
          : sections.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(Space.page),
              child: Text(l.searchEmpty(q), style: context.text.bodyMedium),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xxl),
              children: [
                for (final (title, rows) in sections) ...[SectionTitle(title), ...rows],
              ],
            ),
    );
  }
}
