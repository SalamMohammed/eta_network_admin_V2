import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../shared/firestore_constants.dart';
import '../utils/firestore_helper.dart';
import 'config_service.dart';
import 'user_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _initialized = false;
  bool _isInitializing = false;

  /// Initialize RevenueCat with API key from Firestore
  Future<void> init() async {
    if (_initialized || _isInitializing) return;
    _isInitializing = true;
    try {
      if (kIsWeb) {
        debugPrint('SubscriptionService: RevenueCat is not supported on web.');
        _initialized = true;
        return;
      }

      final data = await ConfigService().getGeneralConfig();
      final apiKey = data[FirestoreAppConfigFields.revenueCatApiKey] as String?;

      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('SubscriptionService: No RevenueCat API key found.');
        return;
      }

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      // Listen for updates
      Purchases.addCustomerInfoUpdateListener((info) {
        _handleCustomerInfoUpdate(info);
      });

      _initialized = true;

      // Login if user is already authenticated
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await logIn(uid);
      }
    } catch (e) {
      debugPrint('SubscriptionService init failed: $e');
    } finally {
      _isInitializing = false;
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

  Future<CustomerInfo?> refreshCustomerInfo() async {
    if (!_initialized) return null;
    try {
      final fresh = await Purchases.getCustomerInfo();
      await _handleCustomerInfoUpdate(fresh);
      return fresh;
    } catch (e) {
      debugPrint('SubscriptionService refreshCustomerInfo failed: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    if (!_initialized) return false;
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (!verified) return false;
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      await refreshCustomerInfo();
      return true;
    } catch (e) {
      debugPrint('SubscriptionService purchase failed: $e');
      final fresh = await refreshCustomerInfo();
      final productId = package.storeProduct.identifier;
      if (fresh != null && _isProductActive(fresh, productId)) {
        return true;
      }
      try {
        await Purchases.restorePurchases();
        final afterRestore = await refreshCustomerInfo();
        if (afterRestore != null && _isProductActive(afterRestore, productId)) {
          return true;
        }
      } catch (_) {}
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (!verified) return false;
    try {
      await Purchases.restorePurchases();
      await refreshCustomerInfo();
      return true;
    } catch (e) {
      debugPrint('SubscriptionService restore failed: $e');
      return false;
    }
  }

  bool _isProductActive(CustomerInfo info, String productId) {
    final now = DateTime.now();

    for (final ent in info.entitlements.active.values) {
      if (ent.productIdentifier != productId) continue;
      final exp = DateTime.tryParse(ent.expirationDate ?? '');
      return exp == null ? true : exp.isAfter(now);
    }

    if (info.activeSubscriptions.contains(productId)) {
      final expStr = info.allExpirationDates[productId];
      final exp = DateTime.tryParse(expStr ?? '');
      return exp == null ? true : exp.isAfter(now);
    }

    final latestExp = DateTime.tryParse(info.latestExpirationDate ?? '');
    if (latestExp == null || !latestExp.isAfter(now)) return false;
    if (info.allPurchasedProductIdentifiers.contains(productId)) {
      final expStr = info.allExpirationDates[productId];
      final exp = DateTime.tryParse(expStr ?? '');
      return exp == null ? true : exp.isAfter(now);
    }
    return false;
  }

  /// Sync RevenueCat status to Firestore
  Future<void> _handleCustomerInfoUpdate(CustomerInfo info) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String? planId;
    String? provider;
    DateTime? expiresAt;
    bool autoRenew = false;

    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);

    final now = DateTime.now();
    final activeEntitlements = info.entitlements.active.values.toList();
    final allEntitlements = info.entitlements.all.values.toList();

    bool isActive = false;

    if (activeEntitlements.isNotEmpty) {
      activeEntitlements.sort((a, b) {
        final da = DateTime.tryParse(a.expirationDate ?? '');
        final db = DateTime.tryParse(b.expirationDate ?? '');
        if (da == null && db == null) return 0;
        if (da == null) return -1;
        if (db == null) return 1;
        return db.compareTo(da);
      });
      final entitlement = activeEntitlements.first;
      planId = entitlement.productIdentifier;
      provider = entitlement.store.name;
      expiresAt = DateTime.tryParse(entitlement.expirationDate ?? '');
      autoRenew = entitlement.willRenew;
      isActive = expiresAt == null ? true : expiresAt.isAfter(now);
    }

    if (!isActive) {
      final activeSubs = info.activeSubscriptions.toList();
      DateTime? bestExp;
      String? bestPlanId;
      for (final subId in activeSubs) {
        final expStr = info.allExpirationDates[subId];
        final exp = DateTime.tryParse(expStr ?? '');
        if (exp == null) continue;
        if (!exp.isAfter(now)) continue;
        if (bestExp == null || exp.isAfter(bestExp)) {
          bestExp = exp;
          bestPlanId = subId;
        }
      }
      if (bestPlanId != null) {
        planId = bestPlanId;
        expiresAt = bestExp;
        isActive = true;
      }
    }

    if (!isActive) {
      final latestExpirationDate = DateTime.tryParse(
        info.latestExpirationDate ?? '',
      );
      if (latestExpirationDate != null && latestExpirationDate.isAfter(now)) {
        expiresAt = latestExpirationDate;
        isActive = true;
        final activeSubs = info.activeSubscriptions.toList();
        if (activeSubs.isNotEmpty) {
          planId = activeSubs.first;
        }
      }
    }

    if (provider == null && allEntitlements.isNotEmpty) {
      provider = allEntitlements.first.store.name;
    }
    if (!autoRenew && allEntitlements.isNotEmpty) {
      autoRenew = allEntitlements.first.willRenew;
    }

    final status = isActive ? 'active' : 'expired';

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

    final existingSnap = await UserService().getUser(uid);
    final existingData = existingSnap?.data() ?? {};
    final existingRole = existingData[FirestoreUserFields.role] as String?;
    final roleToWrite = existingRole == FirestoreUserRoles.admin
        ? FirestoreUserRoles.admin
        : (isActive ? FirestoreUserRoles.pro : FirestoreUserRoles.free);

    // Determine if manager needs update
    String? managerIdToWrite =
        existingData[FirestoreUserFields.activeManagerId] as String?;
    bool managerChanged = false;

    if (isActive && planId != null) {
      final existingPlanId =
          (existingData[FirestoreUserFields.subscription]
              as Map?)?[FirestoreUserSubscriptionFields.planId];
      // If plan changed OR managerId is missing, lookup manager
      if (existingPlanId != planId || managerIdToWrite == null) {
        managerIdToWrite = await _getManagerIdFromPlan(planId);
        if (managerIdToWrite !=
            existingData[FirestoreUserFields.activeManagerId]) {
          managerChanged = true;
        }
      }
    }

    // Check if data actually changed to avoid unnecessary writes
    bool dataChanged = false;

    // Check subscription fields
    final existingSub =
        existingData[FirestoreUserFields.subscription]
            as Map<String, dynamic>? ??
        {};
    if (existingSub[FirestoreUserSubscriptionFields.status] !=
        subData[FirestoreUserSubscriptionFields.status])
      dataChanged = true;
    if (existingSub[FirestoreUserSubscriptionFields.planId] !=
        subData[FirestoreUserSubscriptionFields.planId])
      dataChanged = true;
    if (existingSub[FirestoreUserSubscriptionFields.provider] !=
        subData[FirestoreUserSubscriptionFields.provider])
      dataChanged = true;
    if (existingSub[FirestoreUserSubscriptionFields.autoRenew] !=
        subData[FirestoreUserSubscriptionFields.autoRenew])
      dataChanged = true;

    // Check expiresAt (Timestamp comparison)
    final newExp =
        subData[FirestoreUserSubscriptionFields.expiresAt] as Timestamp?;
    final oldExp =
        existingSub[FirestoreUserSubscriptionFields.expiresAt] as Timestamp?;
    if (newExp?.seconds != oldExp?.seconds) dataChanged = true;

    // Check role
    if (existingRole != roleToWrite) dataChanged = true;

    // Check managerEnabled
    final existingManagerEnabled =
        existingData[FirestoreUserFields.managerEnabled] as bool? ?? false;
    if (existingManagerEnabled != isActive) dataChanged = true;

    if (managerChanged) dataChanged = true;

    // If data hasn't changed, check if we need a heartbeat (every 24h)
    if (!dataChanged) {
      final existingUpdatedAt =
          existingData[FirestoreUserFields.updatedAt] as Timestamp?;
      if (existingUpdatedAt != null) {
        final diff = now.difference(existingUpdatedAt.toDate());
        if (diff.inHours < 24) {
          // Skip update if less than 24h and no data changes
          return;
        }
      }
    }

    await userRef.set({
      FirestoreUserFields.subscription: subData,
      FirestoreUserFields.role: roleToWrite,
      FirestoreUserFields.managerEnabled: isActive,
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      if (managerIdToWrite != null)
        FirestoreUserFields.activeManagerId: managerIdToWrite,
    }, SetOptions(merge: true));
  }

  Future<String?> _getManagerIdFromPlan(String planId) async {
    final qs = await FirestoreHelper.instance
        .collection(FirestoreConstants.managers)
        .where(FirestoreManagerFields.storeProductId, isEqualTo: planId)
        .limit(1)
        .get();

    if (qs.docs.isNotEmpty) {
      return qs.docs.first.id;
    }
    return null;
  }
}
