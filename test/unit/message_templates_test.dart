import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/templates/message_templates.dart';

void main() {
  test('every template has Turkish and English for every tone, using only its own fields', () {
    for (final t in MessageTemplates.all) {
      for (final lang in ['tr', 'en']) {
        for (final tone in Tone.values) {
          final vs = t.variants(lang, tone);
          expect(vs, isNotEmpty, reason: '${t.id} $lang $tone');
          for (final v in vs) {
            for (final m in RegExp(r'\{(\w+)\}').allMatches(v)) {
              final f = TemplateField.values.byName(m.group(1)!);
              expect(t.fields, contains(f), reason: '${t.id} uses {${f.name}}');
            }
          }
        }
      }
    }
  });

  test('fill drops an empty optional name cleanly', () {
    expect(MessageTemplates.fill('Merhaba {name}, nasılsın?', {}), 'Merhaba, nasılsın?');
    expect(MessageTemplates.fill('İyi ki doğdun {name}! 🎉', {}), 'İyi ki doğdun! 🎉');
    expect(MessageTemplates.fill('{name}, kusura bakma.', {}), 'kusura bakma.');
    expect(
      MessageTemplates.fill('{what} için teşekkürler {name}!', {
        TemplateField.name: 'Ali',
        TemplateField.what: 'Yardımın',
      }),
      'Yardımın için teşekkürler Ali!',
    );
  });
}
