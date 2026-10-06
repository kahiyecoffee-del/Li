import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/json.dart';
import '../../domain/ai/ai_action.dart';
import '../../domain/ai/ai_action_validator.dart';
import '../../domain/models/enums.dart';
import 'ai_models.dart';

/// Client-side entry point to the assistant.
///
/// The app never talks to an AI vendor directly and holds no API keys: all
/// requests go through authenticated, App Check–protected Cloud Functions
/// which choose the provider/model, enforce credits and validate output.
abstract class AiService {
  Future<AiChatResponse> chat(AiChatRequest request);
  Future<AiTaskResponse> task(AiTaskType type, Map<String, dynamic> input);
  Future<AiCredits> credits();

  /// Called after a rewarded ad completes; the server caps rewards per day.
  Future<AiCredits> grantAdReward(String placement);
}

/// Parses and validates backend responses (the "AIActionParser" +
/// "AIResponseValidator" on the client side; the server validates too).
class AiResponseParser {
  const AiResponseParser(this.validator);

  final AiActionValidator validator;

  static const maxReplyLength = 4000;

  AiChatResponse parseChat(Map<String, dynamic> j) {
    var reply = J.str(j, 'reply').trim();
    if (reply.length > maxReplyLength) reply = '${reply.substring(0, maxReplyLength)}…';
    final rawActions = j['actions'] is List ? j['actions'] as List<Object?> : const <Object?>[];
    final validRaw = <Map<String, dynamic>>[];
    final actions = <AiAction>[];
    for (final r in rawActions.take(5)) {
      final v = validator.validate(r);
      if (v.isValid) {
        actions.add(v.action!);
        validRaw.add((r! as Map).map((k, v) => MapEntry('$k', v)));
      }
    }
    final memories = J
        .mapList(j, 'memorySuggestions')
        .map((m) {
          final cat = MemoryCategory.values.where((c) => c.name == m['category']).firstOrNull;
          final content = J.str(m, 'content').trim();
          return cat == null || content.isEmpty || content.length > 200 ? null : AiMemorySuggestion(cat, content);
        })
        .whereType<AiMemorySuggestion>()
        .take(3)
        .toList();
    if (reply.isEmpty && actions.isEmpty) throw const AppFailure(FailureKind.unknown);
    return AiChatResponse(
      reply: reply,
      actions: actions,
      memorySuggestions: memories,
      credits: AiCredits.fromJson(J.map(j, 'credits')),
      rawActions: validRaw,
      summary: J.strOrNull(j, 'summary'),
      rejectedActions: rawActions.length - actions.length,
    );
  }
}

class CloudAiService implements AiService {
  CloudAiService(this._functions, {this.timeZone, AiActionValidator validator = const AiActionValidator()})
    : _parser = AiResponseParser(validator);

  final FirebaseFunctions _functions;
  final AiResponseParser _parser;

  /// IANA time zone so the server's "daily" credit reset follows the user's day.
  final Future<String?> Function()? timeZone;

  static const _chatTimeout = Duration(seconds: 45);
  static const _taskTimeout = Duration(seconds: 60);

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data, Duration timeout) async {
    final tz = await timeZone?.call();
    if (tz != null) data = {...data, 'timeZone': tz};
    try {
      final res = await _functions
          .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout, limitedUseAppCheckToken: false))
          .call<Object?>(data)
          .timeout(timeout + const Duration(seconds: 5));
      final d = res.data;
      if (d is! Map) throw const AppFailure(FailureKind.unknown);
      return d.map((k, v) => MapEntry('$k', v));
    } on FirebaseFunctionsException catch (e) {
      final details = e.details is Map ? (e.details as Map).map((k, v) => MapEntry('$k', v)) : <String, Object?>{};
      throw AppFailure(
        switch (e.code) {
          'resource-exhausted' =>
            details['reason'] == 'rate_limited' ? FailureKind.rateLimited : FailureKind.quotaExceeded,
          'unauthenticated' => FailureKind.unauthenticated,
          'permission-denied' => FailureKind.permissionDenied,
          'invalid-argument' => FailureKind.invalidInput,
          'deadline-exceeded' => FailureKind.timeout,
          'unavailable' => FailureKind.network,
          _ => FailureKind.unknown,
        },
        cause: e,
        details: details,
      );
    } on TimeoutException catch (e) {
      throw AppFailure(FailureKind.timeout, cause: e);
    }
  }

  @override
  Future<AiChatResponse> chat(AiChatRequest request) async =>
      _parser.parseChat(await _call('aiChat', request.toJson(), _chatTimeout));

  @override
  Future<AiTaskResponse> task(AiTaskType type, Map<String, dynamic> input) async {
    final j = await _call('aiTask', {'task': type.wire, 'input': input}, _taskTimeout);
    return AiTaskResponse(J.map(j, 'result'), AiCredits.fromJson(J.map(j, 'credits')));
  }

  @override
  Future<AiCredits> credits() async =>
      AiCredits.fromJson(J.map(await _call('getAiCredits', const {}, const Duration(seconds: 15)), 'credits'));

  @override
  Future<AiCredits> grantAdReward(String placement) async => AiCredits.fromJson(
    J.map(await _call('grantAdReward', {'placement': placement}, const Duration(seconds: 15)), 'credits'),
  );
}

/// Used when the backend is not configured (no Firebase). Every call fails
/// with [FailureKind.unavailable] so the UI can explain and fall back to the
/// on-device features.
class UnavailableAiService implements AiService {
  const UnavailableAiService();

  Never _fail() => throw const AppFailure(FailureKind.unavailable);

  @override
  Future<AiChatResponse> chat(AiChatRequest request) async => _fail();

  @override
  Future<AiTaskResponse> task(AiTaskType type, Map<String, dynamic> input) async => _fail();

  @override
  Future<AiCredits> credits() async => AiCredits.unknown;

  @override
  Future<AiCredits> grantAdReward(String placement) async => _fail();
}
