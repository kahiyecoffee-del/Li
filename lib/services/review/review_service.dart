import 'package:in_app_review/in_app_review.dart';

import '../../core/config/app_config.dart';

/// The store's own rating sheet (App Store / Google Play). The platform
/// decides whether it actually appears and limits how often.
abstract class ReviewService {
  Future<bool> request();

  /// The store page, for a manual "Rate Dayly" in Settings.
  Future<void> openStore();
}

class StoreReviewService implements ReviewService {
  final _review = InAppReview.instance;

  @override
  Future<bool> request() async {
    try {
      if (!await _review.isAvailable()) return false;
      await _review.requestReview();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openStore() =>
      _review.openStoreListing(appStoreId: AppConfig.appStoreId.isEmpty ? null : AppConfig.appStoreId);
}

class NoReviewService implements ReviewService {
  int requests = 0;

  @override
  Future<bool> request() async {
    requests++;
    return true;
  }

  @override
  Future<void> openStore() async {}
}

/// When to ask for a rating: only after people have lived with the app for
/// a while, at a moment that went well, rarely. Stores never want it on the
/// first launch, in set-up, after an error or in the middle of a task.
abstract final class ReviewPolicy {
  static const minDaysInstalled = 5, minActiveDays = 4, cooldownDays = 120, maxPerYear = 3;

  static bool shouldAsk({
    required DateTime now,
    required DateTime? installedAt,
    required int activeDays,
    required List<DateTime> asked,
  }) {
    if (installedAt == null || now.difference(installedAt).inDays < minDaysInstalled) return false;
    if (activeDays < minActiveDays) return false;
    final lastYear = asked.where((a) => now.difference(a).inDays < 365).toList()..sort();
    if (lastYear.length >= maxPerYear) return false;
    if (lastYear.isNotEmpty && now.difference(lastYear.last).inDays < cooldownDays) return false;
    return true;
  }
}
