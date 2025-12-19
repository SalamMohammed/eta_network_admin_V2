import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../shared/firestore_constants.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _initialized = false;

  /// Initialize RevenueCat with API key from Firestore
  Future<void> init() async {
    if (_initialized) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.appConfig)
          .doc(FirestoreAppConfigDocs.general)
          .get();

      final data = doc.data() ?? {};
      final apiKey = data[FirestoreAppConfigFields.revenueCatApiKey] as String?;

      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('SubscriptionService: No RevenueCat API key found.');
        return;
      }

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      _initialized = true;

      // Listen for updates
      Purchases.addCustomerInfoUpdateListener((info) {
        _handleCustomerInfoUpdate(info);
      });

      // Login if user is already authenticated
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await logIn(uid);
      }
    } catch (e) {
      debugPrint('SubscriptionService init failed: $e');
    }
  }

  /// Log in to RevenueCat with the Firebase UID
  Future<void> logIn(String uid) async {
    if (!_initialized) return;
    try {
      final result = await Purchases.logIn(uid);
      await _handleCustomerInfoUpdate(result.customerInfo);
    } catch (e) {
      debugPrint('SubscriptionService login failed: $e');
    }
  }

  /// Logout (on app logout)
  Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('SubscriptionService logout failed: $e');
    }
  }

  /// Fetch available offerings (products)
  Future<Offerings?> getOfferings() async {
    if (!_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('SubscriptionService getOfferings failed: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    if (!_initialized) return false;
    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      await _handleCustomerInfoUpdate(purchaseResult.customerInfo);
      return true;
    } catch (e) {
      debugPrint('SubscriptionService purchase failed: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      await _handleCustomerInfoUpdate(customerInfo);
      return true;
    } catch (e) {
      debugPrint('SubscriptionService restore failed: $e');
      return false;
    }
  }

  /// Sync RevenueCat status to Firestore
  Future<void> _handleCustomerInfoUpdate(CustomerInfo info) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Determine the "best" active entitlement or subscription
    // For now, we look for any active entitlement.
    // In a complex app, you might map specific entitlement IDs to specific plans.

    final entitlements = info.entitlements.active;
    String status = 'expired';
    String? planId;
    String? provider;
    DateTime? expiresAt;
    bool autoRenew = false;

    if (entitlements.isNotEmpty) {
      // Pick the first active entitlement
      final entitlement = entitlements.values.first;
      status = 'active';
      planId = entitlement.productIdentifier;
      provider = entitlement.store.name; // e.g. appStore, playStore
      if (entitlement.expirationDate != null) {
        expiresAt = DateTime.parse(entitlement.expirationDate!);
      }
      autoRenew = entitlement.willRenew;
    }

    // Update Firestore
    final userRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid);

    final subData = {
      FirestoreUserSubscriptionFields.status: status,
      if (planId != null) FirestoreUserSubscriptionFields.planId: planId,
      if (provider != null) FirestoreUserSubscriptionFields.provider: provider,
      if (expiresAt != null)
        FirestoreUserSubscriptionFields.expiresAt: Timestamp.fromDate(
          expiresAt,
        ),
      FirestoreUserSubscriptionFields.autoRenew: autoRenew,
    };

    // If active, we might also want to enable the manager associated with this plan.
    // This logic depends on how we map plans to managers.
    // If the planId corresponds to a Manager's storeProductId, we can activate that manager.

    await userRef.set({
      FirestoreUserFields.subscription: subData,
      // We don't necessarily toggle 'managerEnabled' here blindly,
      // but we could if the subscription is active.
      // For now, we leave the manager selection logic to the UI/MiningService
      // which will read this subscription status.
    }, SetOptions(merge: true));

    // Check if we need to enable/disable manager based on subscription
    if (status == 'active' && planId != null) {
      await _syncManagerFromPlan(uid, planId);
    } else {
      // If expired, maybe disable manager?
      // Or let the MiningService handle it by checking the date.
      // We'll let MiningService be the enforcer.
    }
  }

  Future<void> _syncManagerFromPlan(String uid, String planId) async {
    // Find the manager that has this storeProductId
    final qs = await FirebaseFirestore.instance
        .collection(FirestoreConstants.managers)
        .where(FirestoreManagerFields.storeProductId, isEqualTo: planId)
        .limit(1)
        .get();

    if (qs.docs.isNotEmpty) {
      final managerId = qs.docs.first.id;
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .set({
            FirestoreUserFields.activeManagerId: managerId,
            FirestoreUserFields.managerEnabled: true,
            FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }
}
