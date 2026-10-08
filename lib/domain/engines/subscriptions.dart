import '../../core/utils/dates.dart';
import '../models/enums.dart';
import '../models/money_models.dart';

/// Well-known subscriptions worldwide (lowercase, matched as words).
const knownSubscriptions = [
  'netflix', 'spotify', 'youtube', 'disney', 'apple music', 'apple tv', 'apple one', 'icloud', //
  'amazon prime', 'prime video', 'hbo', 'hulu', 'paramount', 'peacock', 'crunchyroll', 'dazn',
  'exxen', 'blutv', 'mubi', 'deezer', 'tidal', 'audible', 'kindle', 'storytel',
  'xbox', 'game pass', 'playstation', 'ps plus', 'nintendo', 'ea play', 'steam',
  'chatgpt', 'openai', 'claude', 'gemini', 'copilot', 'midjourney', 'notion', 'canva', 'adobe',
  'microsoft 365', 'office 365', 'google one', 'dropbox', 'evernote', 'todoist', '1password', 'nordvpn',
  'duolingo', 'babbel', 'headspace', 'calm', 'strava', 'tinder', 'bumble', 'linkedin', 'patreon',
  'gym', 'fitness', 'spor salonu', 'abonelik', 'subscription', 'membership', 'üyelik',
];

String _norm(String s) => s.toLowerCase().replaceAll('İ', 'i').replaceAll('I', 'ı').trim();

bool _mentions(String text, String word) =>
    RegExp('(?<![a-z0-9çğıöşü])${RegExp.escape(word)}(?![a-z0-9çğıöşü])').hasMatch(_norm(text));

/// A subscription by its category or a well-known name.
bool isSubscription(RecurringBill b) =>
    !b.deleted && (b.category == ExpenseCategory.subscriptions || knownSubscriptions.any((w) => _mentions(b.name, w)));

List<RecurringBill> subscriptionsOf(List<RecurringBill> bills) =>
    bills.where(isSubscription).toList()..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

int subscriptionsMonthly(List<RecurringBill> bills) => subscriptionsOf(bills).fold(0, (s, b) => s + b.amountMinor);

/// A payment that repeats every month but is not saved as a bill yet.
class SubscriptionCandidate {
  const SubscriptionCandidate(this.name, this.amountMinor, this.months, this.dayOfMonth);
  final String name;
  final int amountMinor;
  final int months;
  final int dayOfMonth;
}

/// Expenses with the same description in at least two different months
/// (last four), at about the same amount (±15%). Known services count from
/// a single payment.
List<SubscriptionCandidate> findSubscriptionCandidates(
  List<MoneyTransaction> txs,
  List<RecurringBill> bills,
  DateTime now,
) {
  final since = DateTime(now.year, now.month - 3, 1);
  final saved = bills.where((b) => !b.deleted).map((b) => _norm(b.name)).toSet();
  final groups = <String, List<MoneyTransaction>>{};
  for (final t in txs) {
    if (t.deleted || t.type != TransactionType.expense || t.date.isBefore(since)) continue;
    final key = _norm(t.merchant ?? t.description).replaceAll(RegExp(r'[0-9.,₺$€£]+'), ' ').trim();
    if (key.length < 3) continue;
    groups.putIfAbsent(key.replaceAll(RegExp(r'\s+'), ' '), () => []).add(t);
  }
  final out = <SubscriptionCandidate>[];
  for (final MapEntry(key: name, value: list) in groups.entries) {
    if (saved.any((s) => s == name || s.contains(name) || name.contains(s))) continue;
    final months = list.map((t) => Dates.monthKey(t.date)).toSet();
    final known = knownSubscriptions.any((w) => _mentions(name, w));
    if (months.length < 2 && !known) continue;
    final amounts = list.map((t) => t.amountMinor).toList()..sort();
    final median = amounts[amounts.length ~/ 2];
    if (!known && amounts.any((a) => (a - median).abs() > median * 0.15)) continue;
    // More payments than months: not a monthly charge (coffee, groceries).
    if (!known && list.length > months.length) continue;
    list.sort((a, b) => b.date.compareTo(a.date));
    final first = list.first.description.trim().isEmpty ? name : list.first.description.trim();
    out.add(SubscriptionCandidate(first, median, months.length, list.first.date.day));
  }
  out.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
  return out;
}
