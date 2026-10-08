import 'dart:async';

import 'package:flutter/services.dart';

/// What Siri, Google Assistant or a home-screen shortcut asked for.
class AssistantCommand {
  const AssistantCommand.add(String this.text) : kind = AssistantKind.add, route = null;
  const AssistantCommand.voice() : kind = AssistantKind.voice, text = null, route = null;
  const AssistantCommand.open(String this.route) : kind = AssistantKind.open, text = null;

  final AssistantKind kind;
  final String? text;
  final String? route;

  /// Screens a shortcut may open. Android shortcuts are reachable by other
  /// apps, so anything else is ignored.
  static const openable = {'/home', '/plan', '/focus', '/money', '/today-info', '/search'};

  /// `{action: add, text: …}`, `{action: voice}` or `{action: open, route: /plan}`.
  static AssistantCommand? fromMap(Map<Object?, Object?> m) {
    final text = (m['text'] as String?)?.trim();
    final route = m['route'] as String?;
    return switch (m['action']) {
      'add' when text != null && text.isNotEmpty => AssistantCommand.add(
        text.length > 500 ? text.substring(0, 500) : text,
      ),
      'add' || 'voice' => const AssistantCommand.voice(),
      'open' when openable.contains(route) => AssistantCommand.open(route!),
      _ => null,
    };
  }

  @override
  String toString() => 'AssistantCommand($kind, $text, $route)';
}

enum AssistantKind { add, voice, open }

/// Siri / App Shortcuts (iOS) and Google Assistant / app shortcuts (Android).
abstract class AssistantService {
  Stream<AssistantCommand> get commands;
}

/// Native side (AppDelegate.swift, MainActivity.kt) queues commands and pings;
/// Dart takes the queue, so nothing is lost while the app is starting.
class DeviceAssistant implements AssistantService {
  static const _channel = MethodChannel('dayly/assistant');

  @override
  Stream<AssistantCommand> get commands {
    late final StreamController<AssistantCommand> out;
    Future<void> take() async {
      try {
        final list = await _channel.invokeListMethod<Object?>('take') ?? const [];
        for (final m in list.whereType<Map<Object?, Object?>>()) {
          final c = AssistantCommand.fromMap(m);
          if (c != null && !out.isClosed) out.add(c);
        }
      } catch (_) {
        // No native side (older build): nothing to take.
      }
    }

    out = StreamController<AssistantCommand>(
      onListen: () {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'ping') await take();
        });
        unawaited(take());
      },
      onCancel: () => _channel.setMethodCallHandler(null),
    );
    return out.stream;
  }
}

class NoAssistant implements AssistantService {
  const NoAssistant([this._commands = const Stream.empty()]);
  final Stream<AssistantCommand> _commands;

  @override
  Stream<AssistantCommand> get commands => _commands;
}
