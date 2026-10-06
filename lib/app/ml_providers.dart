import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/engines/expense_parser.dart';
import '../domain/engines/shopping_categorizer.dart';
import '../domain/ml/text_classifier.dart';

/// On-device classifiers bundled as assets (assets/models/). If loading
/// fails the app silently falls back to keyword matching.
class LocalModels {
  const LocalModels({this.expense, this.shopping});

  final TextClassifier? expense;
  final TextClassifier? shopping;

  ExpenseParser get expenseParser => ExpenseParser(model: expense);
  ShoppingCategorizer get shoppingCategorizer => ShoppingCategorizer(model: shopping);
}

Future<TextClassifier?> _load(AssetBundle bundle, String path) async {
  try {
    return TextClassifier.fromJson(await bundle.loadString(path));
  } catch (_) {
    return null;
  }
}

final assetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

final localModelsProvider = FutureProvider<LocalModels>((ref) async {
  final bundle = ref.watch(assetBundleProvider);
  final results = await Future.wait([
    _load(bundle, 'assets/models/expense_classifier.json'),
    _load(bundle, 'assets/models/shopping_classifier.json'),
  ]);
  return LocalModels(expense: results[0], shopping: results[1]);
});

/// Synchronous access; keyword-only until the models have loaded.
final localModelsNowProvider = Provider<LocalModels>(
  (ref) => ref.watch(localModelsProvider).value ?? const LocalModels(),
);
