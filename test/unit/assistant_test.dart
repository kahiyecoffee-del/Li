import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/assistant/assistant_service.dart';
import 'package:lifeos/services/voice/voice_input_service.dart';

void main() {
  test('assistant commands from Siri / Google Assistant / shortcuts', () {
    final add = AssistantCommand.fromMap({'action': 'add', 'text': '  yarın 3te dişçi '})!;
    expect(add.kind, AssistantKind.add);
    expect(add.text, 'yarın 3te dişçi');
    // "Add" with nothing said opens the mic instead.
    expect(AssistantCommand.fromMap({'action': 'add', 'text': ''})!.kind, AssistantKind.voice);
    expect(AssistantCommand.fromMap({'action': 'voice'})!.kind, AssistantKind.voice);
    expect(AssistantCommand.fromMap({'action': 'open', 'route': '/plan'})!.route, '/plan');
    // Other apps can fire Android shortcuts: only known screens open.
    expect(AssistantCommand.fromMap({'action': 'open', 'route': '/settings/privacy'}), isNull);
    expect(AssistantCommand.fromMap({'action': 'delete'}), isNull);
    expect(AssistantCommand.fromMap({'action': 'add', 'text': 'x' * 900})!.text!.length, 500);
  });

  test('speech locale follows the app language and the phone region', () {
    expect(speechLocaleId(const Locale('en'), const Locale('en', 'GB')), 'en_GB');
    expect(speechLocaleId(const Locale('en'), const Locale('tr', 'TR')), 'en_US');
    expect(speechLocaleId(const Locale('tr'), const Locale('de', 'DE')), 'tr_TR');
    expect(speechLocaleId(const Locale('sw'), const Locale('en', 'US')), 'sw');
  });
}
