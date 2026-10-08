import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/widgets/common.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/voice/voice_input_service.dart';

/// What Siri / Google Assistant / an app shortcut handed to the home
/// "write anything" box: text to save, or "start listening".
class CaptureRequest {
  const CaptureRequest.text(String this.text) : listen = false;
  const CaptureRequest.listen() : text = null, listen = true;
  final String? text;
  final bool listen;
}

class CaptureRequestNotifier extends Notifier<CaptureRequest?> {
  @override
  CaptureRequest? build() => null;

  void request(CaptureRequest r) => state = r;

  /// Hands the request over once.
  CaptureRequest? take() {
    final r = state;
    state = null;
    return r;
  }
}

final captureRequestProvider = NotifierProvider<CaptureRequestNotifier, CaptureRequest?>(CaptureRequestNotifier.new);

/// A mic that writes what you say into [controller] (live, as you speak).
/// Uses the phone's own recognizer in the app language; hidden where there
/// is none (web).
class VoiceMicButton extends ConsumerStatefulWidget {
  const VoiceMicButton({super.key, required this.controller, this.onDone});

  final TextEditingController controller;

  /// Called with the final text.
  final ValueChanged<String>? onDone;

  @override
  ConsumerState<VoiceMicButton> createState() => VoiceMicButtonState();
}

class VoiceMicButtonState extends ConsumerState<VoiceMicButton> {
  bool _listening = false;

  bool get listening => _listening;

  Future<void> start() async {
    if (_listening) return;
    final s = ref.read(servicesProvider);
    final l = context.l10n;
    final app = Localizations.localeOf(context);
    final device = View.of(context).platformDispatcher.locale;
    if (!s.voice.supported || !await s.voice.available) {
      if (mounted) showSnack(context, l.voiceUnavailable);
      return;
    }
    if (!mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(s.analytics.log(AnalyticsEvent.voiceInputUsed));
    setState(() => _listening = true);
    final before = widget.controller.text.trim();
    String join(String said) => before.isEmpty ? said : '$before $said';
    void put(String t) => widget.controller.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
    final said = await s.voice.listen(localeId: speechLocaleId(app, device), onPartial: (p) => put(join(p)));
    if (!mounted) return;
    setState(() => _listening = false);
    if (said == null) {
      put(before);
      return;
    }
    put(join(said));
    unawaited(HapticFeedback.lightImpact());
    widget.onDone?.call(widget.controller.text);
  }

  Future<void> stop() => ref.read(servicesProvider).voice.stop();

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(servicesProvider).voice.supported) return const SizedBox.shrink();
    final l = context.l10n;
    final c = Theme.of(context).colorScheme;
    return IconButton(
      key: const Key('voice-mic'),
      tooltip: _listening ? l.listening : l.voiceInput,
      onPressed: _listening ? stop : start,
      style: _listening ? IconButton.styleFrom(backgroundColor: c.errorContainer, foregroundColor: c.error) : null,
      icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_none_rounded),
    );
  }
}
