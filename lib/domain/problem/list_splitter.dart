import '../engines/meal_engine.dart';

/// What kind of list the user is typing; each reads differently without
/// commas.
enum ListKind { ingredients, options, tasks }

/// Splits a typed list into items. Commas, new lines, "ve/and", ";" and
/// "sonra/then" always separate. Without them:
/// * ingredients: known ingredient names (also multi-word, e.g. "zeytin
///   yağı"), otherwise one item per word;
/// * options: one per word, keeping model numbers with their name
///   ("iPhone 15 Galaxy S24" → iPhone 15, Galaxy S24);
/// * tasks: Turkish tasks end with a verb ("rapor yaz spor market" → rapor
///   yaz, spor, market); English tasks start with one ("call mom buy
///   milk").
abstract final class ListSplitter {
  static final _separators = RegExp(
    r'\s*(?:[,;\n]|\s(?:ve|ile|and|sonra|then|ayrıca|also)\s|\s?\+\s?)\s*',
    caseSensitive: false,
  );

  static List<String> split(String text, ListKind kind) {
    final t = text.trim();
    if (t.isEmpty) return const [];
    final parts = t.split(_separators).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length > 1) {
      // A separated list; each part may still hold several ingredients.
      return kind == ListKind.ingredients ? [for (final p in parts) ..._ingredients(p)] : parts;
    }
    return switch (kind) {
      ListKind.ingredients => _ingredients(t),
      ListKind.options => _options(t),
      ListKind.tasks => _tasks(t),
    };
  }

  static String _lower(String s) => s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

  static List<String> _words(String s) => s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  static List<String> _ingredients(String s) {
    final known = knownIngredientNames;
    final words = _words(s);
    final out = <String>[];
    var i = 0;
    while (i < words.length) {
      var matched = false;
      for (var n = 3; n >= 2; n--) {
        if (i + n > words.length) continue;
        final phrase = words.sublist(i, i + n).join(' ');
        if (known.contains(_lower(phrase))) {
          out.add(phrase);
          i += n;
          matched = true;
          break;
        }
      }
      if (!matched) {
        out.add(words[i]);
        i++;
      }
    }
    return out;
  }

  static List<String> _options(String s) {
    final out = <String>[];
    for (final w in _words(s)) {
      // "15", "S24", "Pro", "Max", "Plus" belong to the name before them.
      final suffix = RegExp(r'^(\d[\w.]*|[A-Z]\d+\w*|pro|max|plus|mini|ultra|lite)$', caseSensitive: false).hasMatch(w);
      if (suffix && out.isNotEmpty) {
        out[out.length - 1] = '${out.last} $w';
      } else {
        out.add(w);
      }
    }
    return out;
  }

  static const _trVerbs = {
    'yaz',
    'ara',
    'yap',
    'git',
    'al',
    'öde',
    'gönder',
    'bitir',
    'oku',
    'çalış',
    'temizle',
    'hazırla',
    'izle',
    'pişir',
    'yıka',
    'topla',
    'düzenle',
    'ütüle',
    'getir',
    'götür',
    'bırak',
    'uğra',
    'yatır',
    'çek',
    'at',
    'ver',
    'koş',
    'yürü',
    'gez',
    'bak',
    'kontrol',
    'sor',
    'konuş',
    'tamamla',
    'başla',
    'planla',
    'teslim',
    'iade',
    'kur',
    'sil',
    'yükle',
    'indir',
    'boya',
    'onar',
    'tamir',
    'kes',
    'sula',
    'besle',
    'çıkar',
  };

  static const _enVerbs = {
    'write',
    'call',
    'buy',
    'pay',
    'send',
    'finish',
    'read',
    'clean',
    'cook',
    'go',
    'email',
    'study',
    'prepare',
    'do',
    'pick',
    'book',
    'meet',
    'fix',
    'walk',
    'run',
    'visit',
    'check',
    'review',
    'plan',
    'wash',
    'take',
    'return',
    'submit',
    'order',
    'water',
    'feed',
    'practice',
    'learn',
    'watch',
    'start',
    'make',
    'get',
    'drop',
  };

  static bool _isTrVerb(String w) {
    final l = _lower(w);
    if (_trVerbs.contains(l)) return true;
    // Imperative/infinitive endings: "yazacağım", "aramak", "gideceğim".
    return _trVerbs.any((v) => l.startsWith(v) && RegExp(r'(mak|mek|acağım|eceğim|ıcam|icem|cam|cem)$').hasMatch(l));
  }

  static List<String> _tasks(String s) {
    final words = _words(s);
    final en = words.any((w) => _enVerbs.contains(_lower(w)));
    final tr = words.any(_isTrVerb);
    if (en && !tr) {
      final out = <String>[];
      for (final w in words) {
        if (_enVerbs.contains(_lower(w)) || out.isEmpty) {
          out.add(w);
        } else {
          out[out.length - 1] = '${out.last} $w';
        }
      }
      return out;
    }
    // Turkish: a verb closes a task together with its object (the word
    // before it, or a possessive compound such as "market alışverişi").
    // Other words are tasks of their own ("spor", "spor salonu").
    final out = <String>[];
    var buffer = <String>[];
    bool possessive(String w) => w.length > 3 && RegExp(r'(sı|si|su|sü|ı|i|u|ü)$').hasMatch(_lower(w));
    void flushLoose(List<String> ws) {
      final loose = <String>[];
      for (final w in ws) {
        if (loose.isNotEmpty && possessive(w)) {
          loose[loose.length - 1] = '${loose.last} $w';
        } else {
          loose.add(w);
        }
      }
      out.addAll(loose);
    }

    for (final w in words) {
      if (!_isTrVerb(w)) {
        buffer.add(w);
        continue;
      }
      var start = buffer.length - 1;
      if (start >= 1 && possessive(buffer[start])) start--;
      if (start < 0) start = 0;
      flushLoose(buffer.sublist(0, start));
      out.add([...buffer.sublist(start), w].join(' '));
      buffer = [];
    }
    flushLoose(buffer);
    return out;
  }
}
