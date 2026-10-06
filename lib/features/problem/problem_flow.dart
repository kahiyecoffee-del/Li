import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/utils/ids.dart';
import '../../domain/models/saved_item.dart';
import '../../domain/problem/problem_solver.dart';
import '../../services/analytics/analytics_service.dart';
import '../plan/task_editor.dart';

const problemSolver = ProblemSolver();

/// Sends a typed (or spoken, or photographed) problem to the right place:
/// an exact on-device answer, a tool, or Lio.
Future<void> openProblem(BuildContext context, WidgetRef ref, String text) async {
  final q = text.trim();
  if (q.isEmpty) return;
  final result = problemSolver.solve(q);
  final kind = switch (result) {
    final Solution s => s.kind,
    ToolRoute(:final tool) => tool.name,
    AskLio() => 'lio',
  };
  unawaited(ref.read(servicesProvider).analytics.log(AnalyticsEvent.problemCreated, {'kind': kind}));
  final enc = Uri.encodeQueryComponent(q);
  switch (result) {
    case Solution():
    case ToolRoute(tool: ProblemTool.recipe):
      await context.push('/solve?q=$enc');
    case ToolRoute(tool: ProblemTool.decide, :final options):
      final o = options.map(Uri.encodeQueryComponent).join('|');
      await context.push('/decide${o.isEmpty ? '' : '?o=$o'}');
    case ToolRoute(tool: ProblemTool.reminder):
      await showTaskEditor(context, title: _reminderTitle(q), day: DateTime.now());
    case ToolRoute(tool: ProblemTool.write):
      context.go('/ai?topic=write&n=${DateTime.now().microsecondsSinceEpoch}');
    case AskLio():
      context.go('/ai?q=$enc&n=${DateTime.now().microsecondsSinceEpoch}');
  }
}

/// "Yarın annemi aramayı hatırlat" → "Yarın annemi aramayı".
String _reminderTitle(String q) {
  final t = q
      .replaceAll(
        RegExp(
          r'\b(bana\s+)?(hatırlat(ır mısın)?|hatirlat|remind me( to)?|don.?t forget( to)?|unutma)\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return t.isEmpty ? q : '${t[0].toUpperCase()}${t.substring(1)}';
}

/// Keeps a solved problem in Saved.
Future<void> saveProblem(
  BuildContext context,
  WidgetRef ref, {
  required String kind,
  required String title,
  required String summary,
  Map<String, dynamic> payload = const {},
}) async {
  final now = DateTime.now();
  await ref
      .read(reposProvider)
      .saved
      .save(
        SavedItem(
          id: newId(),
          updatedAt: now,
          createdAt: now,
          kind: kind,
          title: title.length > 200 ? title.substring(0, 200) : title,
          summary: summary,
          payload: payload,
        ),
      );
  unawaited(ref.read(servicesProvider).analytics.log(AnalyticsEvent.itemSaved, {'kind': kind}));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.savedToast)));
  }
}
