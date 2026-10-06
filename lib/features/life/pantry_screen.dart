import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/models/user_profile.dart';
import 'food_screen.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final names = _input.text.split(RegExp('[,\n]'));
    _input.clear();
    await ref.read(actionsProvider).addPantryItems(names);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = ref.watch(pantryProvider).list;
    final prefs = ref.watch(profileProvider.select((p) => p.value?.food ?? const FoodPreferences()));
    const engine = MealEngine();
    final recipes = engine.eligible(RecipeLibrary.all(Localizations.localeOf(context).languageCode), prefs);
    final makeable = items.isEmpty
        ? const <PantryMatch>[]
        : engine.matchPantry(recipes, items.map((i) => i.name)).where((m) => m.makeable).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l.lifePantry)),
      body: PageList(
        children: [
          TextField(
            controller: _input,
            decoration: InputDecoration(
              hintText: l.pantryAddHint,
              suffixIcon: IconButton(tooltip: l.add, icon: const Icon(Icons.add), onPressed: _add),
            ),
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: Space.lg),
          if (items.isEmpty)
            EmptyState(icon: Icons.kitchen_outlined, message: l.pantryEmpty)
          else ...[
            AppCard(child: Text(l.pantryCanMake(makeable.length), style: context.text.titleMedium)),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: items
                  .map(
                    (i) => InputChip(
                      label: Text(i.name),
                      onDeleted: () => ref.read(actionsProvider).deletePantryItem(i.id),
                      deleteButtonTooltipMessage: l.delete,
                    ),
                  )
                  .toList(),
            ),
            if (makeable.isNotEmpty) ...[
              SectionTitle(l.foodWhatToEat),
              ...makeable.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: RecipeCard(recipe: m.recipe),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
