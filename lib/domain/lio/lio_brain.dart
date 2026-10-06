import '../../core/widgets/mascot.dart';
import '../../l10n/gen/app_localizations.dart';

/// Snapshot of the user's day that Lio's built-in brain answers from.
class LioFacts {
  const LioFacts({
    this.name = '',
    this.todayTasks = const [],
    this.safeDaily,
    this.leftToday,
    this.overToday,
    this.score,
    this.goalsLeft = 0,
    this.streak = 0,
    this.mealName,
    this.mealMinutes,
    this.hour = 12,
  });

  final String name;

  /// (title, time label or null, done)
  final List<(String, String?, bool)> todayTasks;

  /// Formatted money strings; null when no budget is set.
  final String? safeDaily;
  final String? leftToday;
  final String? overToday;
  final int? score;
  final int goalsLeft;
  final int streak;
  final String? mealName;
  final int? mealMinutes;
  final int hour;
}

class LioReply {
  const LioReply(this.text, this.mood);

  final String text;
  final MascotMood mood;
}

enum LioIntent { greeting, thanks, plan, money, food, score, feelLow, sleep, habit, motivation, help, unknown }

/// Lio's always-available brain: understands the everyday questions people
/// ask most (Turkish and English) and answers from live app data. No model
/// download, no network, no cost — and it never makes things up.
abstract final class LioBrain {
  static const _keywords = <LioIntent, List<String>>{
    LioIntent.feelLow: [
      'uzgun', 'mutsuz', 'stres', 'yorgun', 'kotu hissed', 'bunald', 'kaygi', 'endise', 'yalniz', //
      'sad', 'stressed', 'tired', 'anxious', 'lonely', 'feel bad', 'depressed', 'overwhelmed',
    ],
    LioIntent.thanks: ['tesekkur', 'sagol', 'eyvallah', 'thank', 'thx'],
    LioIntent.plan: [
      'plan', 'gorev', 'yapacak', 'ajanda', 'ne yapmali', 'is listesi', 'program', //
      'task', 'todo', 'to-do', 'schedule', 'agenda', 'what should i do',
    ],
    LioIntent.money: [
      'para', 'harca', 'butce', 'tasarruf', 'birikim', 'lira', 'masraf', 'gider', 'maas', //
      'money', 'spend', 'budget', 'save', 'saving', 'expense', 'cost',
    ],
    LioIntent.food: [
      'yemek', 'pisir', 'tarif', 'kahvalti', 'ogle', 'aksam yeme', 'ac ', 'acik', 'ne yesem', 'mutfak', //
      'cook', 'meal', 'recipe', 'eat', 'dinner', 'lunch', 'breakfast', 'hungry', 'food',
    ],
    LioIntent.score: [
      'skor', 'puan', 'nasil gidiyor', 'durumum', 'ilerleme', 'hedef', //
      'score', 'how am i', 'progress', 'goal', 'doing',
    ],
    LioIntent.sleep: ['uyku', 'uyu', 'yatma', 'sleep', 'insomnia'],
    LioIntent.habit: ['aliskanlik', 'rutin', 'su ic', 'spor', 'habit', 'routine', 'water', 'workout'],
    LioIntent.motivation: ['motivasyon', 'ilham', 'gaz ver', 'cesaret', 'motivat', 'inspire', 'encourage'],
    LioIntent.help: ['ne yapabilir', 'yardim', 'neler bil', 'help', 'what can you'],
    LioIntent.greeting: ['merhaba', 'selam', 'gunaydin', 'iyi aksam', 'naber', 'hello', 'hi ', 'hey', 'good morning'],
  };

  /// Lower-case, Turkish letters folded to ASCII.
  static String normalize(String s) {
    const from = 'çğıİöşüÇĞÖŞÜâîû';
    const to = 'cgiiosucgosuaiu';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch.toLowerCase());
    }
    return ' ${b.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')} ';
  }

  static LioIntent intentOf(String message) {
    final m = normalize(message);
    // Order matters: feelings and thanks win over topic words.
    for (final e in _keywords.entries) {
      // Keywords match at the start of a word ("plan" ⊂ "planım");
      // a trailing space means the whole word ("ac " = "aç").
      if (e.value.any((k) => m.contains(' $k'))) return e.key;
    }
    return LioIntent.unknown;
  }

  static LioReply reply(String message, LioFacts f, AppLocalizations l, {required List<String> inspirations}) {
    final pick = inspirations.isEmpty ? '' : inspirations[message.length % inspirations.length];
    switch (intentOf(message)) {
      case LioIntent.greeting:
        return LioReply(f.name.isEmpty ? l.brainGreetingNoName : l.brainGreeting(f.name), MascotMood.happy);
      case LioIntent.thanks:
        return LioReply(l.brainThanks, MascotMood.loving);
      case LioIntent.plan:
        if (f.todayTasks.isEmpty) return LioReply(l.brainPlanNone, MascotMood.curious);
        final open = f.todayTasks.where((t) => !t.$3).toList();
        if (open.isEmpty) return LioReply(l.brainPlanAllDone, MascotMood.excited);
        final lines = open.take(5).map((t) => '• ${t.$2 == null ? '' : '${t.$2} '}${t.$1}').join('\n');
        return LioReply(
          '${l.brainPlanList(open.length)}\n$lines\n\n${l.brainPlanNext(open.first.$1)}',
          MascotMood.happy,
        );
      case LioIntent.money:
        if (f.safeDaily == null) return LioReply(l.brainMoneyNoBudget, MascotMood.curious);
        if (f.overToday != null) {
          return LioReply('${l.brainMoneyOver(f.overToday!)}\n\n${l.brainMoneyTip}', MascotMood.thoughtful);
        }
        return LioReply(
          '${l.brainMoneySafe(f.leftToday ?? f.safeDaily!, f.safeDaily!)}\n\n${l.brainMoneyTip}',
          MascotMood.happy,
        );
      case LioIntent.food:
        if (f.mealName == null) return LioReply(l.brainFoodNone, MascotMood.curious);
        return LioReply(l.brainFood(f.mealName!, f.mealMinutes ?? 20), MascotMood.happy);
      case LioIntent.score:
        final parts = [
          f.score == null ? l.brainScoreNone : l.brainScore(f.score!),
          if (f.goalsLeft > 0) l.lioGoalsLeft(f.goalsLeft) else if (f.score != null) l.lioAllDone,
          if (f.streak > 1) l.lioStreak(f.streak),
        ];
        return LioReply(parts.join(' '), (f.score ?? 0) >= 60 ? MascotMood.excited : MascotMood.happy);
      case LioIntent.feelLow:
        return LioReply('${l.brainFeelLow}\n\n$pick', MascotMood.loving);
      case LioIntent.sleep:
        return LioReply(l.brainSleep, MascotMood.sleepy);
      case LioIntent.habit:
        return LioReply(l.brainHabit, MascotMood.happy);
      case LioIntent.motivation:
        return LioReply(pick, MascotMood.excited);
      case LioIntent.help:
        return LioReply(l.brainHelp, MascotMood.happy);
      case LioIntent.unknown:
        return LioReply(l.brainFallback, MascotMood.thoughtful);
    }
  }
}
