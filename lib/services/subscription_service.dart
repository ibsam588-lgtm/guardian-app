import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// GuardIan subscription: $2.99/month after 7-day free trial
/// Product ID on App Store / Play Store: guardian_monthly_299
const kGuardianMonthlyProductId = 'guardian_monthly_299';
const kGuardianEntitlement = 'guardian_pro';

class SubscriptionService {
  final _db = FirebaseFirestore.instance;

  // ── Initialize RevenueCat ──────────────────────
  static Future<void> init({
    required String revenueCatApiKeyAndroid,
    required String revenueCatApiKeyIos,
  }) async {
    await Purchases.setLogLevel(LogLevel.debug);
    PurchasesConfiguration config;

    // Platform check handled at runtime in main.dart
    // Pass the correct key for each platform
    config = PurchasesConfiguration(revenueCatApiKeyAndroid);
    await Purchases.configure(config);
  }

  // ── Get current subscription status ───────────
  Future<SubscriptionInfo> getSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all[kGuardianEntitlement];
      final isActive = entitlement?.isActive ?? false;
      final expiryDate = entitlement?.expirationDate != null
          ? DateTime.tryParse(entitlement!.expirationDate!)
          : null;

      return SubscriptionInfo(
        isActive: isActive,
        expiryDate: expiryDate,
        willRenew: entitlement?.willRenew ?? false,
      );
    } catch (_) {
      // Fallback: check Firestore trial
      return _checkFirestoreTrial();
    }
  }

  Future<SubscriptionInfo> _checkFirestoreTrial() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return SubscriptionInfo(isActive: false);

    final doc = await _db.collection('parents').doc(uid).get();
    if (!doc.exists) return SubscriptionInfo(isActive: false);

    final data = doc.data()!;
    final trialEnds = (data['trialEndsAt'] as Timestamp?)?.toDate();
    final isInTrial = trialEnds != null && trialEnds.isAfter(DateTime.now());

    return SubscriptionInfo(
      isActive: isInTrial,
      expiryDate: trialEnds,
      isTrial: isInTrial,
      daysRemainingInTrial: isInTrial
          ? trialEnds!.difference(DateTime.now()).inDays
          : 0,
    );
  }

  // ── Load available offerings ───────────────────
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  // ── Purchase subscription ─────────────────────
  Future<PurchaseResult> purchaseMonthly() async {
    try {
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.monthly;
      if (monthly == null) {
        return PurchaseResult.error('Subscription not available.');
      }

      final customerInfo = await Purchases.purchasePackage(monthly);
      final isActive = customerInfo
          .entitlements.all[kGuardianEntitlement]?.isActive ?? false;

      if (isActive) {
        // Update Firestore status
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await _db.collection('parents').doc(uid).update({
            'subscription': 'active',
            'subscribedAt': FieldValue.serverTimestamp(),
          });
        }
        return PurchaseResult.success();
      } else {
        return PurchaseResult.error('Purchase not verified.');
      }
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled();
      }
      return PurchaseResult.error('Purchase failed. Please try again.');
    } catch (e) {
      return PurchaseResult.error(e.toString());
    }
  }

  // ── Restore purchases ─────────────────────────
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[kGuardianEntitlement]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }
}

class SubscriptionInfo {
  final bool isActive;
  final bool isTrial;
  final DateTime? expiryDate;
  final bool willRenew;
  final int daysRemainingInTrial;

  SubscriptionInfo({
    required this.isActive,
    this.isTrial = false,
    this.expiryDate,
    this.willRenew = false,
    this.daysRemainingInTrial = 0,
  });
}

class PurchaseResult {
  final bool success;
  final bool cancelled;
  final String? error;

  PurchaseResult.success() : success = true, cancelled = false, error = null;
  PurchaseResult.cancelled() : success = false, cancelled = true, error = null;
  PurchaseResult.error(this.error) : success = false, cancelled = false;
}
