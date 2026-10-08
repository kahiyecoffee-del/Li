import '../../core/utils/dates.dart';
import '../engines/expense_parser.dart';
import '../plan/day_timeline.dart';
import '../problem/list_splitter.dart';

/// What a quick note turns into.
enum CaptureKind { task, expense, shopping, journal }

/// One line from the "write anything" box, understood.
class Capture {
  const Capture.task(this.task, this.day) : kind = CaptureKind.task, expense = null, items = const [], text = '';
  const Capture.expense(this.expense)
    : kind = CaptureKind.expense,
      task = null,
      day = null,
      items = const [],
      text = '';
  const Capture.shopping(this.items) : kind = CaptureKind.shopping, task = null, day = null, expense = null, text = '';
  const Capture.journal(this.text)
    : kind = CaptureKind.journal,
      task = null,
      day = null,
      expense = null,
      items = const [];

  final CaptureKind kind;
  final QuickTask? task;

  /// The day a task is for (today when no day word was written).
  final DateTime? day;
  final ParsedExpense? expense;
  final List<String> items;
  final String text;
}

/// A day word found in the text and the text without it.
class DayMatch {
  const DayMatch(this.day, this.rest);
  final DateTime day;
  final String rest;
}

const _weekdaysTr = ['pazartesi', 'salı', 'çarşamba', 'perşembe', 'cuma', 'cumartesi', 'pazar'];
const _weekdaysEn = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

String _fold(String s) => s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// "yarın", "bugün", "öbür gün", "cuma", "tomorrow", "friday"…
DayMatch? parseDay(String text, DateTime now) {
  final today = Dates.dateOnly(now);
  final lower = _fold(text);
  final words = <(String, int)>[
    ('yarından sonra', 2),
    ('öbür gün', 2),
    ('day after tomorrow', 2),
    ('yarın', 1),
    ('tomorrow', 1),
    ('bugün', 0),
    ('today', 0),
    ('tonight', 0),
    ('bu akşam', 0),
  ];
  for (final (w, add) in words) {
    final i = _wordIndex(lower, w);
    if (i >= 0) {
      // Keep "bu akşam" in the title context out; drop the day word only.
      return DayMatch(Dates.addDays(today, add), _cut(text, i, w.length));
    }
  }
  for (final names in [_weekdaysTr, _weekdaysEn]) {
    // Longest first so "cumartesi" is not read as "cuma".
    final order = [for (var i = 0; i < 7; i++) i]..sort((a, b) => names[b].length.compareTo(names[a].length));
    for (final d in order) {
      final m = RegExp('(?<![a-zçğıöşü])${names[d]}([a-zçğıöşü’\']*)').firstMatch(lower);
      if (m == null) continue;
      var add = (d + 1 - today.weekday) % 7; // weekday is 1..7
      if (add < 0) add += 7;
      return DayMatch(Dates.addDays(today, add), _cut(text, m.start, m.end - m.start));
    }
  }
  return null;
}

int _wordIndex(String lower, String w) {
  final m = RegExp('(?<![a-zçğıöşü])${RegExp.escape(w)}(?![a-zçğıöşü])').firstMatch(lower);
  return m?.start ?? -1;
}

String _cut(String s, int start, int len) =>
    '${s.substring(0, start)} ${s.substring(start + len)}'.replaceAll(RegExp(r'\s+'), ' ').trim();

final _time = RegExp(
  r"(?<![\d,])([01]?\d|2[0-3])[:.]([0-5]\d)(?!\d)|\b(saat|at)\s+\d|(?<!\d)\d{1,2}\s*(am|pm)\b|(?<!\d)\d{1,2}['’]?(te|ta|de|da)\b",
  caseSensitive: false,
);
final _money = RegExp(r'(₺|\$|€|£)|\d\s*(tl|lira|try|usd|eur|gbp|dolar|euro)\b', caseSensitive: false);
final _shop = RegExp(
  r'(^|\s)(al|alınacak|alınacaklar|alınsın|listeye ekle|alışverişe|buy|get some|shopping list)(\s|$|[.!])',
  caseSensitive: false,
);
final _feel = RegExp(
  r'hissed|yorgun|mutlu|üzgün|uzgun|stres|kaygı|endişe|sinirli|huzur|keyfim|moralim|bugün çok|bugun cok|'
  r'\bfeel|\bfelt|tired|happy|sad|anxious|stressed|grateful|exhausted',
  caseSensitive: false,
);

/// Decides what a quick note is. Order matters: a time or a day word means a
/// task even when there are numbers; money words mean an expense; "… al"
/// means shopping; feelings or long text go to the journal; anything else is
/// a task for today.
Capture classifyCapture(String input, DateTime now, {ExpenseParser expenses = const ExpenseParser()}) {
  final text = input.trim();
  final lower = _fold(text);
  final hasTime = _time.hasMatch(text);
  // "bugün çok yorgunum" is a feeling, not a task for today.
  if (!hasTime && _feel.hasMatch(lower)) return Capture.journal(text);
  final day = parseDay(text, now);
  if (day != null || hasTime) {
    final rest = day?.rest ?? text;
    return Capture.task(parseQuickTask(rest), day?.day ?? Dates.dateOnly(now));
  }
  final exp = expenses.parse(text);
  if (exp != null && (_money.hasMatch(text) || exp.confident)) return Capture.expense(exp);
  if (_shop.hasMatch(lower)) {
    final cleaned = text.replaceAll(_shop, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final items = ListSplitter.split(cleaned, ListKind.ingredients);
    if (items.isNotEmpty) return Capture.shopping(items);
  }
  if (_feel.hasMatch(lower) || text.split(RegExp(r'\s+')).length >= 14) return Capture.journal(text);
  return Capture.task(parseQuickTask(text), Dates.dateOnly(now));
}
