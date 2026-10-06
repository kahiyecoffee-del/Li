/// Puts the user's own name for the assistant into a sentence written for
/// "Lio", fixing Turkish suffixes by vowel harmony ("Lio’nun" → "Maya’nın",
/// "Lio’ya" → "Can’a") and the English possessive.
String renameAssistant(String text, String name, {required bool turkish}) {
  if (name.trim().isEmpty || name == 'Lio' || !text.contains('Lio')) return text;
  final n = name.trim();
  var out = text.replaceAllMapped(RegExp('Lio([’\'])([a-zA-ZçğıöşüÇĞİÖŞÜ]+)'), (m) {
    final apostrophe = m[1]!;
    final suffix = m[2]!;
    if (!turkish) {
      return suffix == 's' ? (n.endsWith('s') ? '$n$apostrophe' : '$n${apostrophe}s') : '$n$apostrophe$suffix';
    }
    final kind = switch (suffix) {
      'nun' || 'nın' || 'nin' || 'nün' => _Case.genitive,
      'ya' || 'ye' => _Case.dative,
      'yu' || 'yı' || 'yi' || 'yü' => _Case.accusative,
      'yla' || 'yle' => _Case.instrumental,
      _ => null,
    };
    return kind == null ? '$n$apostrophe$suffix' : '$n$apostrophe${turkishSuffix(n, kind)}';
  });
  out = out.replaceAll('Lio', n);
  return out;
}

enum _Case { genitive, dative, accusative, instrumental }

const _vowels = 'aeıioöuüAEIİOÖUÜ';

/// Turkish case suffix for a proper name (written after an apostrophe).
String turkishSuffix(String name, Object kind) {
  final lower = name.toLowerCase();
  String? last;
  for (var i = lower.length - 1; i >= 0; i--) {
    if (_vowels.contains(lower[i])) {
      last = lower[i];
      break;
    }
  }
  last ??= 'e';
  final endsVowel = _vowels.contains(lower[lower.length - 1]);
  final back = 'aıou'.contains(last);
  final round = 'oöuü'.contains(last);
  final narrow = back ? (round ? 'u' : 'ı') : (round ? 'ü' : 'i');
  final wide = back ? 'a' : 'e';
  return switch (kind as _Case) {
    _Case.genitive =>
      endsVowel
          ? 'n${narrow}n'
          : '$narrow'
                'n',
    _Case.dative => endsVowel ? 'y$wide' : wide,
    _Case.accusative => endsVowel ? 'y$narrow' : narrow,
    _Case.instrumental => endsVowel ? 'yl$wide' : 'l$wide',
  };
}
