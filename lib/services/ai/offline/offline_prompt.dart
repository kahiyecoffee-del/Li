import '../../../domain/lio/lio_brain.dart';

/// System prompt for Lio's on-device model. Kept short and line-based so a
/// small model can read it, and identical to the format Lio's fine-tuning
/// data uses (tool/lio_train/make_dataset.py) — change both together.
abstract final class OfflinePrompt {
  static const _languages = {
    'tr': 'Turkish',
    'en': 'English',
    'es': 'Spanish',
    'pt': 'Portuguese',
    'de': 'German',
    'fr': 'French',
    'it': 'Italian',
    'ar': 'Arabic',
    'ja': 'Japanese',
    'ko': 'Korean',
    'hi': 'Hindi',
  };

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String language(String locale) => _languages[locale.split(RegExp('[-_]')).first] ?? 'English';

  static String system({required String locale, required LioFacts facts, required DateTime now}) {
    String two(int v) => v.toString().padLeft(2, '0');
    final lines = <String>[
      if (facts.name.isNotEmpty) '- Name: ${facts.name}',
      '- Time: ${_weekdays[now.weekday - 1]} ${two(now.hour)}:${two(now.minute)}',
      if (facts.todayTasks.isNotEmpty)
        '- Tasks today: ${facts.todayTasks.take(6).map((t) => '${t.$2 == null ? '' : '${t.$2} '}${t.$1}${t.$3 ? ' (done)' : ''}').join('; ')}'
      else
        '- Tasks today: none',
      if (facts.overToday != null)
        '- Budget today: over by ${facts.overToday}'
      else if (facts.safeDaily != null)
        '- Budget today: safe ${facts.safeDaily}, left ${facts.leftToday ?? facts.safeDaily}'
      else
        '- Budget: not set',
      if (facts.score != null) '- Life score: ${facts.score}/100',
      '- Goals left today: ${facts.goalsLeft}',
      if (facts.streak > 1) '- Streak: ${facts.streak} days',
      if (facts.mealName != null) '- Meal idea: ${facts.mealName} (${facts.mealMinutes ?? 20} min)',
    ];
    return 'You are Lio, the friendly companion in the Dayly app, running offline on the user\'s phone.\n'
        'Reply in ${language(locale)}. Be warm, brief (under 80 words) and practical.\n'
        'Use the user data below when it helps; never invent data that is not there.\n'
        'You cannot change anything in the app; if asked to add or change something, say where to do it in the app.\n'
        'For general questions, answer briefly from what you know and say so if you are not sure; you have no internet for news, prices or scores.\n'
        'Never give medical, legal or investment diagnoses.\n'
        'User data:\n${lines.join('\n')}';
  }
}
