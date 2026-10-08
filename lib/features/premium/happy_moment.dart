import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../services/review/review_service.dart';
import 'interstitial.dart';

/// Something went well (the day is closed, a focus session is done, the
/// week is planned): the right moment to ask for a rating, now and then.
/// Otherwise it is a natural break for an ad, within the usual caps. Never
/// both at once.
Future<void> happyMoment(WidgetRef ref) async {
  final s = ref.read(servicesProvider);
  final prefs = s.prefs;
  final now = DateTime.now();
  final asked = [
    for (final ms in prefs.getStringList('review_asked') ?? const <String>[])
      if (int.tryParse(ms) case final v?) DateTime.fromMillisecondsSinceEpoch(v),
  ];
  final ok = ReviewPolicy.shouldAsk(
    now: now,
    installedAt: ref.read(profileProvider).value?.installedAt,
    activeDays: ref.read(activeDaysProvider).length,
    asked: asked,
  );
  if (ok && await s.review.request()) {
    await prefs.setStringList('review_asked', [
      for (final a in asked) '${a.millisecondsSinceEpoch}',
      '${now.millisecondsSinceEpoch}',
    ]);
    return;
  }
  await maybeShowInterstitial(ref);
}
