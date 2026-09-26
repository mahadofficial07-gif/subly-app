import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Handles the one-time "Subly Pro" unlock (a non-consumable purchase).
///
/// IMPORTANT: before this works, you must:
///   1. Upload at least one signed build to Play Console (internal
///      testing track is enough).
///   2. Create an in-app product in Play Console with the exact
///      product ID below.
///   3. Test using a licensed tester account — purchases can't be
///      tested in a plain emulator/debug build.
class PurchaseService {
  static const String proProductId = 'subly_pro_unlock';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool isPro = false;

  /// Called when a purchase (or restore) successfully unlocks Pro.
  void Function()? onProUnlocked;

  Future<bool> init() async {
    final available = await _iap.isAvailable();
    if (!available) return false;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
    );
    return true;
  }

  Future<ProductDetails?> loadProProduct() async {
    final response = await _iap.queryProductDetails({proProductId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return null; // product not configured in Play Console yet
    }
    return response.productDetails.first;
  }

  Future<void> buyPro(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != proProductId) continue;

      final unlocked = purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored;

      if (unlocked) {
        isPro = true;
        onProUnlocked?.call();
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
