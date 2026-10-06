import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/l10n/assistant_name.dart';

void main() {
  String tr(String s, String n) => renameAssistant(s, n, turkish: true);
  String en(String s, String n) => renameAssistant(s, n, turkish: false);

  test('Turkish suffixes follow vowel harmony', () {
    expect(tr('Lio’nun önerileri', 'Maya'), 'Maya’nın önerileri');
    expect(tr('Bunu Lio’ya sor', 'Can'), 'Bunu Can’a sor');
    expect(tr('Lio’yu daha akıllı yap', 'Ece'), 'Ece’yi daha akıllı yap');
    expect(tr('Lio’nun önerileri', 'Ömür'), 'Ömür’ün önerileri');
    expect(tr('Bunu Lio’ya sor', 'Elif'), 'Bunu Elif’e sor');
    expect(tr('Lio ile konuş', 'Bulut'), 'Bulut ile konuş');
  });

  test('English possessive and plain mentions', () {
    expect(en('Lio’s suggestions', 'Max'), 'Max’s suggestions');
    expect(en('Lio’s suggestions', 'Chris'), 'Chris’ suggestions');
    expect(en('Talk to Lio', 'Nova'), 'Talk to Nova');
  });

  test('default name leaves text untouched', () {
    expect(tr('Lio’nun önerileri', 'Lio'), 'Lio’nun önerileri');
    expect(tr('Lio’nun önerileri', ''), 'Lio’nun önerileri');
  });
}
