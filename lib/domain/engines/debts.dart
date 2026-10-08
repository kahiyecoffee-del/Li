import '../models/care.dart';

/// Shares of a bill split between [people] (including you when [includeMe]),
/// tip added first. Cents left over go to the first shares so the parts add
/// up exactly.
class BillSplit {
  const BillSplit({required this.totalMinor, required this.shares});
  final int totalMinor;
  final List<int> shares;
  int get perPersonMinor => shares.isEmpty ? 0 : shares.first;
}

BillSplit splitBill(int amountMinor, int people, {int tipPercent = 0}) {
  final n = people < 1 ? 1 : people;
  final total = amountMinor + (amountMinor * tipPercent / 100).round();
  final base = total ~/ n;
  final rest = total - base * n;
  return BillSplit(totalMinor: total, shares: [for (var i = 0; i < n; i++) base + (i < rest ? 1 : 0)]);
}

/// Net per person (positive: they owe you), open debts only, largest first.
List<(String, int)> debtBalances(List<Debt> debts) {
  final net = <String, int>{};
  final names = <String, String>{};
  for (final d in debts.where((d) => d.isOpen)) {
    final key = d.person.trim().toLowerCase();
    names.putIfAbsent(key, () => d.person.trim());
    net[key] = (net[key] ?? 0) + d.signedMinor;
  }
  final out = [
    for (final e in net.entries)
      if (e.value != 0) (names[e.key]!, e.value),
  ]..sort((a, b) => b.$2.abs().compareTo(a.$2.abs()));
  return out;
}

/// (owed to you, you owe) over open debts.
(int, int) debtTotals(List<Debt> debts) {
  var owed = 0;
  var owe = 0;
  for (final (_, v) in debtBalances(debts)) {
    if (v > 0) {
      owed += v;
    } else {
      owe -= v;
    }
  }
  return (owed, owe);
}
