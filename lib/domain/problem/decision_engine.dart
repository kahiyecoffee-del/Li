import 'dart:math' as math;

/// Built-in criteria; users can also add their own by name.
enum CriterionKind { price, quality, fit, longTerm, risk, custom }

class Criterion {
  const Criterion({required this.kind, this.label = '', this.weight = 2});

  final CriterionKind kind;

  /// Display name for [CriterionKind.custom].
  final String label;

  /// 1 = nice to have, 2 = important, 3 = must.
  final int weight;

  Criterion copyWith({int? weight}) => Criterion(kind: kind, label: label, weight: weight ?? this.weight);

  Map<String, dynamic> toJson() => {'kind': kind.name, 'label': label, 'weight': weight};

  factory Criterion.fromJson(Map<String, dynamic> j) => Criterion(
    kind: CriterionKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => CriterionKind.custom),
    label: (j['label'] as String?) ?? '',
    weight: (j['weight'] as num?)?.toInt() ?? 2,
  );
}

enum Confidence { tooClose, slight, clear }

class CriterionEdge {
  const CriterionEdge(this.criterion, this.gap);
  final Criterion criterion;

  /// Weighted score difference winner − runner-up (negative: winner is worse).
  final double gap;
}

class DecisionOutcome {
  const DecisionOutcome({
    required this.totals,
    required this.winner,
    required this.runnerUp,
    required this.confidence,
    required this.strengths,
    required this.weaknesses,
  });

  /// 0–100 per option.
  final List<double> totals;
  final int winner, runnerUp;
  final Confidence confidence;

  /// Where the winner beats the runner-up most, then where it loses.
  final List<CriterionEdge> strengths, weaknesses;

  double get margin => totals[winner] - totals[runnerUp];
}

/// Weighted scoring. Ratings are 1–5 per option and criterion; when prices
/// are given, the price criterion is scored from them (cheapest = 5) so
/// the user does not have to guess.
class DecisionEngine {
  const DecisionEngine();

  DecisionOutcome decide({
    required int options,
    required List<Criterion> criteria,
    required List<List<double>> ratings, // [option][criterion], 1–5
    List<double?> prices = const [],
  }) {
    assert(options >= 2 && criteria.isNotEmpty);
    final r = [for (var o = 0; o < options; o++) List<double>.from(ratings[o])];
    final priceIdx = criteria.indexWhere((c) => c.kind == CriterionKind.price);
    final known = [
      for (var o = 0; o < options && o < prices.length; o++)
        if (prices[o] != null && prices[o]! > 0) o,
    ];
    if (priceIdx >= 0 && known.length >= 2) {
      final ps = known.map((o) => prices[o]!).toList();
      final lo = ps.reduce(math.min), hi = ps.reduce(math.max);
      for (final o in known) {
        r[o][priceIdx] = hi == lo ? 5 : 5 - 4 * (prices[o]! - lo) / (hi - lo);
      }
    }
    final wSum = criteria.fold<int>(0, (a, c) => a + c.weight);
    double total(int o) {
      var sum = 0.0;
      for (var c = 0; c < criteria.length; c++) {
        sum += criteria[c].weight * r[o][c];
      }
      return (sum / wSum - 1) / 4 * 100; // the 1–5 average mapped onto 0–100
    }

    final totals = [for (var o = 0; o < options; o++) total(o)];
    final order = List<int>.generate(options, (i) => i)..sort((a, b) => totals[b].compareTo(totals[a]));
    final w = order[0], ru = order[1];
    final margin = totals[w] - totals[ru];
    final edges = [
      for (var c = 0; c < criteria.length; c++) CriterionEdge(criteria[c], criteria[c].weight * (r[w][c] - r[ru][c])),
    ];
    final strengths = edges.where((e) => e.gap > 0).toList()..sort((a, b) => b.gap.compareTo(a.gap));
    final weaknesses = edges.where((e) => e.gap < 0).toList()..sort((a, b) => a.gap.compareTo(b.gap));
    return DecisionOutcome(
      totals: totals,
      winner: w,
      runnerUp: ru,
      confidence: margin < 5 ? Confidence.tooClose : (margin < 15 ? Confidence.slight : Confidence.clear),
      strengths: strengths.take(3).toList(),
      weaknesses: weaknesses.take(2).toList(),
    );
  }
}
