import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eta_network_admin/utils/firestore_helper.dart';
import '../shared/firestore_constants.dart';
import 'rank_engine.dart';
import 'config_service.dart';
import 'user_service.dart';
import 'offline_mining_service.dart';

class EarningsEngine {
  static Future<bool> migrateRealtimeToUnifiedIfNeeded() async {
    debugPrint(
      '[EarningsEngine] migrateRealtimeToUnifiedIfNeeded is disabled; unified model assumed',
    );
    return false;
  }

  static Map<String, dynamic> _buildMigrationPayloadAndMissing({
    required Map<String, dynamic> realtimeData,
    required Map<String, dynamic> liveData,
  }) {
    num? hr = realtimeData[FirestoreUserFields.hourlyRate] as num?;
    hr ??= realtimeData['hourlyRate1'] as num?;
    hr ??= liveData[FirestoreUserFields.hourlyRate] as num?;
    final double hourlyRate = (hr)?.toDouble() ?? 0.0;

    final double totalPoints =
        ((realtimeData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            (liveData[FirestoreUserFields.totalPoints] as num?)?.toDouble()) ??
        0.0;

    Timestamp? lastSyncedAt =
        (realtimeData[FirestoreUserFields.lastSyncedAt] as Timestamp?) ??
        (liveData[FirestoreUserFields.lastSyncedAt] as Timestamp?);

    final double rateBase =
        (realtimeData[FirestoreUserFields.rateBase] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateBase] as num?)?.toDouble() ??
        0.0;
    final double rateStreak =
        (realtimeData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
        0.0;
    final double rateRank =
        (realtimeData[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
        0.0;
    final double rateReferral =
        (realtimeData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
        0.0;
    final double rateManager =
        (realtimeData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
        0.0;
    final double rateAds =
        (realtimeData[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
        0.0;
    final double managerBonusPerHour =
        (realtimeData[FirestoreUserFields.managerBonusPerHour] as num?)
            ?.toDouble() ??
        (liveData[FirestoreUserFields.managerBonusPerHour] as num?)
            ?.toDouble() ??
        0.0;
    final List<String> managedCoinSelections =
        (realtimeData[FirestoreUserFields.managedCoinSelections] as List?)
            ?.cast<String>() ??
        (liveData[FirestoreUserFields.managedCoinSelections] as List?)
            ?.cast<String>() ??
        const [];

    // Preserve updatedAt from realtime if present; otherwise keep live updatedAt if present
    Timestamp? updatedAt =
        (realtimeData[FirestoreUserFields.updatedAt] as Timestamp?) ??
        (liveData[FirestoreUserFields.updatedAt] as Timestamp?);

    final missing = <String>[];
    if (lastSyncedAt == null) {
      lastSyncedAt = updatedAt ?? Timestamp.now();
      missing.add(FirestoreUserFields.lastSyncedAt);
    }
    if (hourlyRate.isNaN) {
      missing.add(FirestoreUserFields.hourlyRate);
    }
    if (rateBase.isNaN) missing.add(FirestoreUserFields.rateBase);
    if (rateStreak.isNaN) missing.add(FirestoreUserFields.rateStreak);
    if (rateRank.isNaN) missing.add(FirestoreUserFields.rateRank);
    if (rateReferral.isNaN) missing.add(FirestoreUserFields.rateReferral);
    if (rateManager.isNaN) missing.add(FirestoreUserFields.rateManager);
    if (rateAds.isNaN) missing.add(FirestoreUserFields.rateAds);
    if (totalPoints.isNaN) {
      missing.add(FirestoreUserFields.totalPoints);
    }

    final payload = <String, dynamic>{
      FirestoreUserFields.totalPoints: totalPoints,
      FirestoreUserFields.lastSyncedAt: lastSyncedAt,
      FirestoreUserFields.hourlyRate: hourlyRate,
      FirestoreUserFields.rateBase: rateBase,
      FirestoreUserFields.rateStreak: rateStreak,
      FirestoreUserFields.rateRank: rateRank,
      FirestoreUserFields.rateReferral: rateReferral,
      FirestoreUserFields.rateManager: rateManager,
      FirestoreUserFields.rateAds: rateAds,
      FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
      FirestoreUserFields.managedCoinSelections: managedCoinSelections,
      if (updatedAt != null) FirestoreUserFields.updatedAt: updatedAt,
    };
    return {'payload': payload, 'missing': missing};
  }

  static Map<String, dynamic> debugBuildMigrationPayload(
    Map<String, dynamic> realtimeData,
    Map<String, dynamic> liveData,
  ) {
    final r = _buildMigrationPayloadAndMissing(
      realtimeData: realtimeData,
      liveData: liveData,
    );
    return r['payload'] as Map<String, dynamic>;
  }

  static List<String> debugValidateMigration(
    Map<String, dynamic> realtimeData,
    Map<String, dynamic> liveData,
  ) {
    final r = _buildMigrationPayloadAndMissing(
      realtimeData: realtimeData,
      liveData: liveData,
    );
    return (r['missing'] as List).cast<String>();
  }

  static Future<void> setUserHourlyRate({
    required String uid,
    required double rate,
  }) async {
    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    try {
      await userRef.set({
        FirestoreUserFields.hourlyRate: rate,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[RateSync] setUserHourlyRate uid=$uid rate=$rate');
    } catch (e) {
      debugPrint('[RateSync] setUserHourlyRate error: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> decideInitialRate({
    required double? userRate,
    required bool miningActive,
    required double baseRate,
  }) {
    if (miningActive) {
      return {'rate': userRate ?? baseRate, 'write': userRate == null};
    }
    if (userRate == null) {
      return {'rate': baseRate, 'write': true};
    }
    return {'rate': userRate, 'write': false};
  }

  static Future<Map<String, dynamic>> syncEarnings({
    Map<String, dynamic>? cachedManagerData,
    String? cachedManagerId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    await migrateRealtimeToUnifiedIfNeeded();

    final now = DateTime.now();

    final userSnap = await UserService().getUser(uid);
    if (userSnap == null || !userSnap.exists) return {};
    final data = userSnap.data() ?? {};

    final Timestamp? startTs =
        data[FirestoreUserFields.lastMiningStart] as Timestamp?;
    final Timestamp? endTs =
        data[FirestoreUserFields.lastMiningEnd] as Timestamp?;
    final Timestamp? syncedTs =
        data[FirestoreUserFields.lastSyncedAt] as Timestamp?;

    DateTime? lastMiningStart = startTs != null ? startTs.toDate() : null;
    DateTime? lastMiningEnd = endTs != null ? endTs.toDate() : null;
    DateTime? lastSyncedAt = syncedTs != null ? syncedTs.toDate() : null;

    if (lastMiningEnd != null && lastMiningStart != null) {
      if (lastSyncedAt == null || lastSyncedAt.isBefore(lastMiningStart)) {
        lastSyncedAt = lastMiningStart;
      }
    }

    final bool isSessionComplete =
        lastMiningEnd != null && !now.isBefore(lastMiningEnd);

    if (lastMiningStart != null && isSessionComplete) {
      final result = await MiningBatchCommitEngine.finishSession(
        uid: uid,
        forcedEnd: lastMiningEnd ?? now,
      );
      if (result.isNotEmpty) {
        return {...result, 'userData': data};
      }
    }

    final liveSnap = await UserService().getRealtimeDoc(uid);
    final liveData = liveSnap?.data() ?? {};

    double hourlyRate =
        (liveData[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
        (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
        0.0;
    if (hourlyRate <= 0) {
      hourlyRate =
          (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;
    }

    double totalPoints =
        (liveData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
        (data[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
        0.0;

    final double rateBase =
        (liveData[FirestoreUserFields.rateBase] as num?)?.toDouble() ?? 0.0;
    final double rateStreak =
        (liveData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
        (data[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
        0.0;
    final double rateRank =
        (liveData[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
        (data[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
        0.0;
    final double rateReferral =
        (liveData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
        (data[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
        0.0;
    final double rateManager =
        (liveData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
        (data[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
        0.0;
    final double rateAds =
        (liveData[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
        (data[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
        0.0;

    final bool managerEnabled =
        (data[FirestoreUserFields.managerEnabled] as bool?) ?? false;

    final List<String> managedCoinSelections = managerEnabled
        ? ((liveData[FirestoreUserFields.managedCoinSelections] as List?)
                  ?.cast<String>() ??
              (data[FirestoreUserFields.managedCoinSelections] as List?)
                  ?.cast<String>() ??
              [])
        : [];

    final double managerBonusPerHour =
        (liveData[FirestoreUserFields.managerBonusPerHour] as num?)
            ?.toDouble() ??
        (data[FirestoreUserFields.managerBonusPerHour] as num?)?.toDouble() ??
        0.0;

    final DateTime? startTime = lastMiningStart;
    final DateTime? endTime = lastMiningEnd;

    DateTime effectiveEnd = now;
    if (endTime != null && now.isAfter(endTime)) {
      effectiveEnd = endTime;
    }

    DateTime from = startTime ?? now;
    if (lastSyncedAt != null && lastSyncedAt.isAfter(from)) {
      from = lastSyncedAt;
    }

    if (effectiveEnd.isAfter(from) && startTime != null && hourlyRate > 0.0) {
      final elapsedHours =
          effectiveEnd.difference(from).inMilliseconds / (1000 * 60 * 60);
      final earned = elapsedHours * hourlyRate;
      totalPoints += earned;
    }

    return {
      FirestoreUserFields.totalPoints: totalPoints,
      FirestoreUserFields.hourlyRate: hourlyRate,
      FirestoreUserFields.managedCoinSelections: managedCoinSelections,
      FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
      FirestoreUserFields.lastMiningStart: startTs,
      FirestoreUserFields.lastMiningEnd: endTs,
      FirestoreUserFields.lastSyncedAt: syncedTs,
      'userData': data,
      FirestoreUserFields.rateBase: rateBase,
      FirestoreUserFields.rateStreak: rateStreak,
      FirestoreUserFields.rateRank: rateRank,
      FirestoreUserFields.rateReferral: rateReferral,
      FirestoreUserFields.rateManager: rateManager,
      FirestoreUserFields.rateAds: rateAds,
      '_didWrite': false,
    };
  }

  /// Boosts the hourly rate by a specific amount (Ad Reward).
  /// Updates rateAds and hourlyRate in Firestore.
  static Future<double> boostAdRate({
    required String uid,
    required double boostAmount,
  }) async {
    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);

    return FirestoreHelper.instance.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final data = userSnap.exists ? (userSnap.data() ?? {}) : {};

      final double currentAds =
          (data[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;
      final double newAds = currentAds + boostAmount;

      final double currentHourlyRate =
          (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

      // We add boostAmount to currentHourlyRate.
      // This assumes other components haven't changed since last sync.
      // This is a safe assumption for a quick boost action.
      final double newHourlyRate = currentHourlyRate + boostAmount;

      transaction.set(userRef, {
        FirestoreUserFields.rateAds: newAds,
        FirestoreUserFields.hourlyRate: newHourlyRate,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return newAds;
    });
  }

  @Deprecated('Use boostAdRate instead')
  static Future<void> grantAdReward({
    required String uid,
    required double rewardAmount,
  }) async {
    // Legacy redirect or no-op if we want to force switch
    // For now, let's keep it but logging warning
    debugPrint('grantAdReward is deprecated. Use boostAdRate.');
  }

  @Deprecated('Use grantAdReward instead')
  static Future<void> applyAdBoost({
    required String uid,
    required double boostAmount,
  }) async {
    // Redirect to grantAdReward for backward compatibility during migration
    await grantAdReward(uid: uid, rewardAmount: boostAmount);
  }

  static Future<Map<String, dynamic>> recalculateRates({
    required String uid,
    Map<String, dynamic>? cachedManagerData,
    String? cachedManagerId,
    int? activeReferralCount,
  }) async {
    debugPrint(
      'EarningsEngine.recalculateRates is disabled; relying on batch engine rates',
    );
    return {};
  }

  static Future<Map<String, dynamic>> startMining({
    required String uid,
    String? deviceId,
    DateTime? maxEnd,
    Map<String, dynamic>? cachedManagerData,
    String? cachedManagerId,
    int? activeReferralCount,
  }) async {
    // 1. Recalculate Rates first (ensure they are up to date)
    final rates = await recalculateRates(
      uid: uid,
      cachedManagerData: cachedManagerData,
      cachedManagerId: cachedManagerId,
      activeReferralCount: activeReferralCount,
    );

    // 2. Set Start/End times
    final appConfig = await ConfigService().getGeneralConfig();
    final double durationHours =
        (appConfig[FirestoreAppConfigFields.sessionDurationHours] as num?)
            ?.toDouble() ??
        24.0;
    final now = DateTime.now();
    DateTime end = now.add(Duration(minutes: (durationHours * 60).toInt()));

    if (maxEnd != null && maxEnd.isBefore(end)) {
      end = maxEnd;
    }

    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);

    final batch = FirestoreHelper.instance.batch();

    final userUpdate = {
      FirestoreUserFields.lastMiningStart: Timestamp.fromDate(now),
      FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(end),
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(now),
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
    };
    if (deviceId != null) {
      userUpdate[FirestoreUserFields.deviceId] = deviceId;
    }

    batch.set(userRef, userUpdate, SetOptions(merge: true));

    await batch.commit();

    // 3. Update Rank (Async)
    RankEngine.updateUserRank(uid);

    // 4. Return merged state
    return {
      ...rates,
      FirestoreUserFields.lastMiningStart: Timestamp.fromDate(now),
      FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(end),
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(now),
      // We don't have totalPoints here, but MiningStateService preserves it if missing in result
      // or we can fetch it?
      // Better to let MiningStateService keep its current totalPoints if not returned.
      // But MiningStateService logic:
      // _totalPoints = (res[totalPoints] as num?)?.toDouble() ?? _totalPoints;
      // So if we omit it, it keeps existing. That's fine.
    };
  }
}
