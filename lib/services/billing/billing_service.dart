import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/config/app_config.dart';

class PremiumProduct {
  const PremiumProduct({required this.id, required this.title, required this.price, required this.yearly, this.raw});

  final String id;
  final String title;

  /// Localized price string from Google Play (never hardcoded).
  final String price;
  final bool yearly;
  final ProductDetails? raw;
}

enum PurchaseResult { success, pending, cancelled, error, unavailable }

abstract class BillingService {
  Future<bool> isAvailable();
  Future<List<PremiumProduct>> products();
  Future<PurchaseResult> buy(PremiumProduct product);
  Future<void> restore();
  Stream<PurchaseResult> get results;
  void dispose();
}

/// Google Play Billing via `in_app_purchase`. Purchases are verified on the
/// server (`verifyPurchase` function → Play Developer API), which writes the
/// entitlement; the client never grants Premium to itself.
class PlayBillingService implements BillingService {
  PlayBillingService(this._iap, this._functions) {
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) => _results.add(PurchaseResult.error));
  }

  final InAppPurchase _iap;
  final FirebaseFunctions _functions;
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  final _results = StreamController<PurchaseResult>.broadcast();

  static Set<String> get productIds => {AppConfig.premiumMonthlyProductId, AppConfig.premiumYearlyProductId};

  @override
  Stream<PurchaseResult> get results => _results.stream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<PremiumProduct>> products() async {
    if (!await _iap.isAvailable()) return const [];
    final r = await _iap.queryProductDetails(productIds);
    return r.productDetails
        .map(
          (p) => PremiumProduct(
            id: p.id,
            title: p.title,
            price: p.price,
            yearly: p.id == AppConfig.premiumYearlyProductId,
            raw: p,
          ),
        )
        .toList()
      ..sort((a, b) => (a.yearly ? 0 : 1).compareTo(b.yearly ? 0 : 1));
  }

  @override
  Future<PurchaseResult> buy(PremiumProduct product) async {
    if (product.raw == null) return PurchaseResult.unavailable;
    final ok = await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product.raw!));
    return ok ? PurchaseResult.pending : PurchaseResult.error;
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _results.add(PurchaseResult.pending);
        case PurchaseStatus.canceled:
          _results.add(PurchaseResult.cancelled);
        case PurchaseStatus.error:
          _results.add(PurchaseResult.error);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified = await _verify(p);
          // Acknowledge only after server verification succeeded; Google
          // refunds unacknowledged purchases after 3 days, protecting users.
          if (verified && p.pendingCompletePurchase) await _iap.completePurchase(p);
          _results.add(verified ? PurchaseResult.success : PurchaseResult.error);
      }
    }
  }

  Future<bool> _verify(PurchaseDetails p) async {
    try {
      final res = await _functions.httpsCallable('verifyPurchase').call<Object?>({
        'productId': p.productID,
        'purchaseToken': p.verificationData.serverVerificationData,
        'source': p.verificationData.source,
      });
      final data = res.data;
      return data is Map && data['premium'] == true;
    } catch (e) {
      debugPrint('verifyPurchase failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    unawaited(_results.close());
  }
}

class UnavailableBillingService implements BillingService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<PremiumProduct>> products() async => const [];

  @override
  Future<PurchaseResult> buy(PremiumProduct product) async => PurchaseResult.unavailable;

  @override
  Future<void> restore() async {}

  @override
  Stream<PurchaseResult> get results => const Stream.empty();

  @override
  void dispose() {}
}
