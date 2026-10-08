import 'dart:ui';

import 'package:speech_to_text/speech_to_text.dart';

/// Turns speech into text with the phone's own recognizer (free, no
/// server). [listen] streams partial results and completes with the final
/// text, or null if speech is unavailable or nothing was heard.
abstract class VoiceInputService {
  /// Whether to show a mic at all (no permission prompt).
  bool get supported;

  /// Asks for the mic/speech permission the first time.
  Future<bool> get available;
  Future<String?> listen({required String localeId, void Function(String partial)? onPartial});
  Future<void> stop();
}

class DeviceVoiceInput implements VoiceInputService {
  final _stt = SpeechToText();
  bool? _ready;

  Future<bool> _init() async => _ready ??= await _stt.initialize();

  @override
  bool get supported => true;

  @override
  Future<bool> get available => _init();

  @override
  Future<String?> listen({required String localeId, void Function(String partial)? onPartial}) async {
    if (!await _init()) return null;
    String? last;
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: true,
      ),
      onResult: (r) {
        last = r.recognizedWords;
        onPartial?.call(last!);
      },
    );
    // Wait until the recognizer stops (silence, timeout or stop()).
    while (_stt.isListening) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    final text = last?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  Future<void> stop() => _stt.stop();
}

/// Web, tests and devices without a recognizer.
class NoVoiceInput implements VoiceInputService {
  const NoVoiceInput();

  @override
  bool get supported => false;

  @override
  Future<bool> get available async => false;

  @override
  Future<String?> listen({required String localeId, void Function(String partial)? onPartial}) async => null;

  @override
  Future<void> stop() async {}
}

/// The recognizer locale for the app language: the phone's own region when
/// it speaks the same language ("en_GB"), else a common one ("en_US").
String speechLocaleId(Locale app, Locale device) {
  final lang = app.languageCode;
  final region = device.languageCode == lang ? device.countryCode : null;
  if (region != null && region.isNotEmpty) return '${lang}_$region';
  const common = {
    'tr': 'TR', 'en': 'US', 'de': 'DE', 'fr': 'FR', 'es': 'ES', 'it': 'IT', 'pt': 'BR', 'nl': 'NL', //
    'ru': 'RU', 'ar': 'SA', 'ja': 'JP', 'ko': 'KR', 'zh': 'CN', 'hi': 'IN', 'id': 'ID', 'pl': 'PL',
  };
  final c = common[lang];
  return c == null ? lang : '${lang}_$c';
}
