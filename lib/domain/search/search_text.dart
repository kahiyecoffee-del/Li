/// Lower-cases with Turkish rules and drops accents, so "cay" finds "Çay"
/// and "ISTANBUL" finds "İstanbul".
String foldForSearch(String s) {
  final lower = s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  const map = {'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u', 'â': 'a', 'î': 'i', 'û': 'u'};
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    b.write(map[ch] ?? ch);
  }
  return b.toString();
}

/// Every word of [query] appears somewhere in [text].
bool searchMatches(String text, String query) {
  final words = foldForSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return false;
  final hay = foldForSearch(text);
  return words.every(hay.contains);
}
