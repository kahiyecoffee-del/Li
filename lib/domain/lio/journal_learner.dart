/// Learns from the user's journal on the device: which themes come up most,
/// and which ones go with better or harder days (from the mood logged that
/// day). Plain counting, no model and nothing leaves the phone.
library;

class JournalNote {
  const JournalNote(this.date, this.text);
  final DateTime date;
  final String text;
}

class JournalTheme {
  const JournalTheme(this.word, this.days);

  /// The most common spelling of the theme in the user's own words.
  final String word;

  /// On how many different days it was mentioned.
  final int days;
}

class MoodLink {
  const MoodLink(this.word, this.withMood, this.otherMood, this.days);
  final String word;

  /// Average mood (1–5) on days mentioning [word], and on the other days.
  final double withMood, otherMood;
  final int days;
  double get delta => withMood - otherMood;
}

class JournalProfile {
  const JournalProfile({this.themes = const [], this.lifts = const [], this.drains = const []});
  final List<JournalTheme> themes;
  final List<MoodLink> lifts;
  final List<MoodLink> drains;
  bool get isEmpty => themes.isEmpty && lifts.isEmpty && drains.isEmpty;
}

class JournalLearner {
  const JournalLearner();

  /// Minimum different days a word must appear on to count as a theme.
  static const minDays = 3;

  /// Minimum mood difference (on a 1–5 scale) to call something a lift or
  /// a drain.
  static const minDelta = 0.6;

  static const _stop = {
    // Turkish
    'bugün', 'bugun', 'yarın', 'dün', 'şimdi', 'sonra', 'önce', 'çok', 'daha', 'gibi', 'için', 'ama', 'fakat',
    've', 'ile', 'bir', 'biraz', 'bana', 'beni', 'benim', 'seni', 'onun', 'bunu', 'şunu', 'olan', 'oldu',
    'olduk', 'oldum', 'olarak', 'kadar', 'neden', 'nasıl', 'hiç', 'hep', 'her', 'şey', 'şeyi', 'şeyler', 'gün',
    'günü', 'günüm', 'günde', 'akşam', 'sabah', 'gece', 'yine', 'tekrar', 'zaten', 'artık', 'bile', 'değil',
    'evet', 'hayır', 'diye', 'dedi', 'dedim', 'yaptım', 'yaptı', 'ettim', 'gitti', 'geldi', 'aldım', 'gerçekten',
    'sadece', 'belki', 'böyle', 'şöyle', 'öyle', 'bence', 'kendimi', 'kendi', 'iyiydi', 'kötüydü',
    // English
    'today', 'yesterday', 'tomorrow', 'really', 'about', 'after', 'again', 'because', 'been', 'being', 'could',
    'didn', 'does', 'doing', 'from', 'have', 'just', 'like', 'made', 'make', 'more', 'much', 'only', 'some',
    'still', 'than', 'that', 'their', 'them', 'then', 'there', 'these', 'they', 'thing', 'things', 'this',
    'very', 'want', 'went', 'were', 'what', 'when', 'which', 'while', 'with', 'would', 'your', 'feel', 'felt',
    'good', 'day', 'days', 'time', 'little', 'lot',
  };

  static String _lower(String s) => s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

  /// Groups inflected forms ("spora", "sporu", "spor") by their first five
  /// letters, which is good enough for Turkish and English themes.
  static String _stem(String w) => w.length <= 5 ? w : w.substring(0, 5);

  JournalProfile learn(List<JournalNote> notes, Map<String, int> moodByDay, String Function(DateTime) dayKey) {
    if (notes.isEmpty) return const JournalProfile();
    final daysByStem = <String, Set<String>>{};
    final spellings = <String, Map<String, int>>{};
    for (final n in notes) {
      final day = dayKey(n.date);
      for (final m in RegExp(r'[a-zA-ZçğıöşüÇĞİÖŞÜ]{4,}').allMatches(n.text)) {
        final w = _lower(m.group(0)!);
        if (_stop.contains(w)) continue;
        final st = _stem(w);
        (daysByStem[st] ??= {}).add(day);
        final sp = spellings[st] ??= {};
        sp[w] = (sp[w] ?? 0) + 1;
      }
    }
    String spelling(String st) {
      final sp = spellings[st]!;
      return sp.entries
          .reduce((a, b) => b.value > a.value || (b.value == a.value && b.key.length < a.key.length) ? b : a)
          .key;
    }

    final themes = [
      for (final e in daysByStem.entries)
        if (e.value.length >= minDays) JournalTheme(spelling(e.key), e.value.length),
    ]..sort((a, b) => b.days.compareTo(a.days));

    final mooded = {for (final n in notes) dayKey(n.date)}.where(moodByDay.containsKey).toSet();
    final lifts = <MoodLink>[], drains = <MoodLink>[];
    if (mooded.length >= 6) {
      for (final e in daysByStem.entries) {
        final withDays = e.value.intersection(mooded);
        final other = mooded.difference(e.value);
        if (withDays.length < minDays || other.length < minDays) continue;
        double avg(Set<String> ds) => ds.map((d) => moodByDay[d]!).reduce((a, b) => a + b) / ds.length;
        final link = MoodLink(spelling(e.key), avg(withDays), avg(other), withDays.length);
        if (link.delta >= minDelta) lifts.add(link);
        if (link.delta <= -minDelta) drains.add(link);
      }
      lifts.sort((a, b) => b.delta.compareTo(a.delta));
      drains.sort((a, b) => a.delta.compareTo(b.delta));
    }
    return JournalProfile(
      themes: themes.take(8).toList(),
      lifts: lifts.take(3).toList(),
      drains: drains.take(3).toList(),
    );
  }
}
