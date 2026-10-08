/// A shopping list as a message anyone can read (WhatsApp, Messages…).
String shoppingShareText(List<String> names, {required String header, required String footer}) =>
    ['🛒 $header', for (final n in names) '☐ $n', '', footer].join('\n');

/// Items from a list someone sent: one per line (with or without boxes,
/// bullets or numbers) or comma-separated on one line. Our own header and
/// footer lines are skipped.
List<String> parseSharedList(String text, {String footer = ''}) {
  final lines = text.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  final raw = lines.length == 1 ? lines.single.split(RegExp(r'[,;]')) : lines;
  final out = <String>[];
  for (var l in raw) {
    l = l.trim();
    if (l.startsWith('🛒') || (footer.isNotEmpty && l == footer) || l.toLowerCase().contains('dayly')) continue;
    l = l.replaceFirst(RegExp(r'^(?:[☐☑✓✔✅•\-\*·]|\[[ xX]?\]|\d+[.)])\s*'), '').trim();
    if (l.isNotEmpty && l.length <= 80 && !out.contains(l)) out.add(l);
  }
  return out;
}
