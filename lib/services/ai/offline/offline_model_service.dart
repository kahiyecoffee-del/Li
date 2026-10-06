import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_mediapipe/flutter_edge_ai_mediapipe.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai_models.dart';

enum OfflineModelState { notInstalled, downloading, ready, error }

class OfflineModelStatus {
  const OfflineModelStatus(this.state, {this.progress = 0});

  final OfflineModelState state;

  /// Download progress 0–100.
  final int progress;

  bool get ready => state == OfflineModelState.ready;
}

/// On-device language model for offline assistant replies.
///
/// The model file (MediaPipe `.task`) is not bundled with the app: it is
/// downloaded on request — Lio Lite (Qwen2.5 0.5B, ~0.5 GB) by default, or
/// Lio Plus (Qwen2.5 1.5B, ~1.6 GB) — from the URLs in Remote Config. Only
/// one model is kept on the phone at a time. Replies are plain text only:
/// small models are not reliable enough to propose app actions.
abstract class OfflineModelService {
  OfflineModelStatus get current;
  Stream<OfflineModelStatus> get status;

  /// File name of the installed model, if any (tells Lite from Plus).
  String? get installedId;

  /// Checks whether a model is already installed.
  Future<void> refresh();
  Future<void> install(String url);
  Future<void> cancel();
  Future<void> remove();

  /// Generates a reply fully on device.
  Future<String> reply({required String system, required List<AiTurn> history, required String message});
}

class EdgeAiOfflineModelService implements OfflineModelService {
  EdgeAiOfflineModelService(this._prefs);

  final SharedPreferences _prefs;
  final _controller = StreamController<OfflineModelStatus>.broadcast();
  OfflineModelStatus _current = const OfflineModelStatus(OfflineModelState.notInstalled);
  InferenceModel? _model;
  CancelToken? _cancel;
  Future<void>? _init;
  static const _idKey = 'offline_model_id';

  /// Context window (prompt + history + reply) and reply cap. The default
  /// Qwen2.5 .task build has a 1280-token KV cache.
  static const maxTokens = 1280;
  static const maxOutputTokens = 320;

  @override
  OfflineModelStatus get current => _current;

  @override
  Stream<OfflineModelStatus> get status => _controller.stream;

  @override
  String? get installedId => _prefs.getString(_idKey);

  void _set(OfflineModelStatus s) {
    _current = s;
    _controller.add(s);
  }

  Future<void> _ensureInit() => _init ??= FlutterEdgeAi.initialize(inferenceEngines: const [MediaPipeEngine()]);

  /// Chat template family, inferred from the model file name.
  static ModelType modelTypeFor(String url) {
    final u = url.toLowerCase();
    if (u.contains('qwen')) return ModelType.qwen;
    if (u.contains('deepseek')) return ModelType.deepSeek;
    if (u.contains('gemma')) return ModelType.gemmaIt;
    return ModelType.general;
  }

  static String modelIdFor(String url) =>
      Uri.parse(url).pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => 'model.task');

  @override
  Future<void> refresh() async {
    final id = _prefs.getString(_idKey);
    if (id == null) return _set(const OfflineModelStatus(OfflineModelState.notInstalled));
    try {
      await _ensureInit();
      _set(
        OfflineModelStatus(
          await FlutterEdgeAi.isModelInstalled(id) ? OfflineModelState.ready : OfflineModelState.notInstalled,
        ),
      );
    } catch (e) {
      debugPrint('offline model refresh failed: $e');
      _set(const OfflineModelStatus(OfflineModelState.error));
    }
  }

  @override
  Future<void> install(String url) async {
    if (_current.state == OfflineModelState.downloading) return;
    // Keep one model only: switching Lite <-> Plus frees the old one first so
    // the phone never needs room for both.
    if (installedId != null && installedId != modelIdFor(url)) await remove();
    _set(const OfflineModelStatus(OfflineModelState.downloading));
    _cancel = CancelToken();
    try {
      await _ensureInit();
      await FlutterEdgeAi.installModel(modelType: modelTypeFor(url))
          // Large files use an Android foreground service (no 9-minute limit).
          .fromNetwork(url, foreground: true)
          .withProgress((p) => _set(OfflineModelStatus(OfflineModelState.downloading, progress: p)))
          .withCancelToken(_cancel!)
          .install();
      await _prefs.setString(_idKey, modelIdFor(url));
      _set(const OfflineModelStatus(OfflineModelState.ready));
    } catch (e) {
      debugPrint('offline model install failed: $e');
      _set(OfflineModelStatus(_cancel?.isCancelled == true ? OfflineModelState.notInstalled : OfflineModelState.error));
    } finally {
      _cancel = null;
    }
  }

  @override
  Future<void> cancel() async => _cancel?.cancel('user');

  @override
  Future<void> remove() async {
    await _model?.close();
    _model = null;
    final id = _prefs.getString(_idKey);
    if (id != null) {
      try {
        await _ensureInit();
        await FlutterEdgeAi.uninstallModel(id);
      } catch (e) {
        debugPrint('offline model uninstall failed: $e');
      }
      await _prefs.remove(_idKey);
    }
    _set(const OfflineModelStatus(OfflineModelState.notInstalled));
  }

  @override
  Future<String> reply({required String system, required List<AiTurn> history, required String message}) async {
    await _ensureInit();
    _model ??= await FlutterEdgeAi.getActiveModel(maxTokens: maxTokens);
    final chat = await _model!.createChat(
      temperature: 0.6,
      topK: 40,
      systemInstruction: system,
      maxOutputTokens: maxOutputTokens,
    );
    // Short history keeps the small context window for the answer.
    for (final t in history.length > 2 ? history.sublist(history.length - 2) : history) {
      await chat.addQueryChunk(Message.text(text: t.text, isUser: t.fromUser));
    }
    await chat.addQueryChunk(Message.text(text: message, isUser: true));
    final response = await chat.generateChatResponse();
    final text = response is TextResponse ? response.token.trim() : '';
    if (text.isEmpty) throw StateError('empty local reply');
    return text;
  }
}

/// Used where on-device inference is unsupported (tests, desktop dev).
class UnsupportedOfflineModelService implements OfflineModelService {
  @override
  OfflineModelStatus get current => const OfflineModelStatus(OfflineModelState.notInstalled);

  @override
  Stream<OfflineModelStatus> get status => const Stream.empty();

  @override
  String? get installedId => null;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> install(String url) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> remove() async {}

  @override
  Future<String> reply({required String system, required List<AiTurn> history, required String message}) =>
      throw UnsupportedError('offline model unsupported');
}
