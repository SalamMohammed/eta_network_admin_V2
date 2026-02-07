import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/firestore_constants.dart';
import '../shared/constants.dart';
import 'rank_engine.dart';
import 'config_service.dart';
import 'user_service.dart';

class EarningsEngine {
  static final Map<String, DateTime> _lastLocalWrites = {};

  static void _pruneLocalWrites() {
    final now = DateTime.now();
    // Remove entries older than 20 minutes to prevent memory leaks
    _lastLocalWrites.removeWhere(
      (key, time) => now.difference(time).inMinutes > 20,
    );
  }

  static Future<Map<String, dynamic>> syncEarnings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final userRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    final realtimeRef = userRef
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime);
    final pointLogsRef = FirebaseFirestore.instance.collection(
      FirestoreConstants.pointLogs,
    );

    // Fetch user data via UserService to use cache (deduplication)
    final userSnap = await UserService().getUser(uid);
    if (userSnap == null || !userSnap.exists) return {};
    final data = userSnap.data() ?? {};

    // Check local cache BEFORE transaction to avoid unnecessary reads
    final lastWrite = _lastLocalWrites[uid];
    final bool recentlyWrittenLocally =
        lastWrite != null &&
        DateTime.now().difference(lastWrite).inMinutes < 10;

    final Timestamp? endTs =
        data[FirestoreUserFields.lastMiningEnd] as Timestamp?;
    final DateTime now = DateTime.now();
    final DateTime? end = endTs?.toDate();
    final bool isSessionComplete =
        end != null && !now.isBefore(end); // now >= end

    if (recentlyWrittenLocally && !isSessionComplete) {
      // Throttle: Perform READ-ONLY operation (no transaction)
      // Note: We still need to fetch realtime doc to get the components and latest sync time
      // But we can do a simple GET instead of a transaction.
      // Or better yet, just return what we have if we assume it hasn't changed much?
      // No, we need to calculate 'earned' points based on elapsed time since last sync.

      try {
        final realtimeSnap = await realtimeRef.get();
        final realtimeData = realtimeSnap.data() ?? {};

        final Timestamp? startTs =
            data[FirestoreUserFields.lastMiningStart] as Timestamp?;
        final Timestamp? syncedTs =
            (realtimeData[FirestoreUserFields.lastSyncedAt] as Timestamp?) ??
            (data[FirestoreUserFields.lastSyncedAt] as Timestamp?);

        final double hourlyRate =
            (realtimeData[FirestoreUserFields.hourlyRate] as num?)
                ?.toDouble() ??
            (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
            0.0;

        final double totalPoints =
            (realtimeData[FirestoreUserFields.totalPoints] as num?)
                ?.toDouble() ??
            (data[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            0.0;

        final double rateBase =
            (realtimeData[FirestoreUserFields.rateBase] as num?)?.toDouble() ??
            0.0;
        final double rateStreak =
            (realtimeData[FirestoreUserFields.rateStreak] as num?)
                ?.toDouble() ??
            0.0;
        final double rateRank =
            (realtimeData[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
            0.0;
        final double rateReferral =
            (realtimeData[FirestoreUserFields.rateReferral] as num?)
                ?.toDouble() ??
            0.0;
        final double rateManager =
            (realtimeData[FirestoreUserFields.rateManager] as num?)
                ?.toDouble() ??
            0.0;
        final double rateAds =
            (realtimeData[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
            0.0;
        final bool managerEnabled =
            (data[FirestoreUserFields.managerEnabled] as bool?) ?? false;

        final List<String> managedCoinSelections = managerEnabled
            ? ((realtimeData[FirestoreUserFields.managedCoinSelections]
                          as List?)
                      ?.cast<String>() ??
                  (data[FirestoreUserFields.managedCoinSelections] as List?)
                      ?.cast<String>() ??
                  [])
            : [];

        final double managerBonusPerHour =
            (realtimeData[FirestoreUserFields.managerBonusPerHour] as num?)
                ?.toDouble() ??
            (data[FirestoreUserFields.managerBonusPerHour] as num?)
                ?.toDouble() ??
            0.0;

        if (startTs == null) {
          return {
            FirestoreUserFields.totalPoints: totalPoints,
            FirestoreUserFields.hourlyRate: hourlyRate,
            FirestoreUserFields.managedCoinSelections: managedCoinSelections,
            FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
            FirestoreUserFields.lastMiningStart: startTs,
            FirestoreUserFields.lastMiningEnd: endTs,
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

        final sessionEnd = end ?? now;
        final effectiveEnd = now.isBefore(sessionEnd) ? now : sessionEnd;
        final from = (syncedTs ?? startTs).toDate();

        if (!effectiveEnd.isAfter(from)) {
          // Already synced up to this point
          return {
            FirestoreUserFields.totalPoints: totalPoints,
            FirestoreUserFields.hourlyRate: hourlyRate,
            FirestoreUserFields.managedCoinSelections: managedCoinSelections,
            FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
            FirestoreUserFields.lastMiningStart: startTs,
            FirestoreUserFields.lastMiningEnd: endTs,
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

        final elapsedHours =
            effectiveEnd.difference(from).inMilliseconds / (1000 * 60 * 60);
        final earned = elapsedHours * hourlyRate;

        debugPrint(
          '[EarningsEngine] Throttled locally: skipped write. Last write: $lastWrite, Now: $now',
        );

        return {
          FirestoreUserFields.totalPoints: totalPoints + earned,
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
          FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(from),
          'userData': data,
          FirestoreUserFields.rateBase: rateBase,
          FirestoreUserFields.rateStreak: rateStreak,
          FirestoreUserFields.rateRank: rateRank,
          FirestoreUserFields.rateReferral: rateReferral,
          FirestoreUserFields.rateManager: rateManager,
          FirestoreUserFields.rateAds: rateAds,
          '_didWrite': false,
        };
      } catch (e) {
        debugPrint(
          '[EarningsEngine] Local throttle read failed: $e. Falling back to transaction.',
        );
      }
    }

    final result = await FirebaseFirestore.instance.runTransaction((
      transaction,
    ) async {
      // NOTE: We do NOT read userRef inside transaction to save a read.
      // We rely on UserService cache (5s freshness).
      // This means we might calculate based on slightly stale hourlyRate,
      // but writes go to realtimeRef which is read inside transaction.

      final realtimeSnap = await transaction.get(realtimeRef);
      final realtimeData = realtimeSnap.data() ?? {};

      final Timestamp? startTs =
          data[FirestoreUserFields.lastMiningStart] as Timestamp?;
      final Timestamp? endTs =
          data[FirestoreUserFields.lastMiningEnd] as Timestamp?;

      // Prefer realtime doc for syncedAt, fallback to user doc
      final Timestamp? syncedTs =
          (realtimeData[FirestoreUserFields.lastSyncedAt] as Timestamp?) ??
          (data[FirestoreUserFields.lastSyncedAt] as Timestamp?);

      // Prefer realtime doc for hourlyRate, fallback to user doc
      final double hourlyRate =
          (realtimeData[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          0.0;

      // Prefer realtime doc for managedCoinSelections, fallback to user doc
      final List<String> managedCoinSelections =
          (realtimeData[FirestoreUserFields.managedCoinSelections] as List?)
              ?.cast<String>() ??
          (data[FirestoreUserFields.managedCoinSelections] as List?)
              ?.cast<String>() ??
          [];

      // Prefer realtime doc for managerBonusPerHour, fallback to user doc
      final double managerBonusPerHour =
          (realtimeData[FirestoreUserFields.managerBonusPerHour] as num?)
              ?.toDouble() ??
          (data[FirestoreUserFields.managerBonusPerHour] as num?)?.toDouble() ??
          0.0;

      // Read Rate Components (Realtime Only - New Logic)
      final double rateBase =
          (realtimeData[FirestoreUserFields.rateBase] as num?)?.toDouble() ??
          0.0;
      final double rateStreak =
          (realtimeData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
          0.0;
      final double rateRank =
          (realtimeData[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
          0.0;
      final double rateReferral =
          (realtimeData[FirestoreUserFields.rateReferral] as num?)
              ?.toDouble() ??
          0.0;
      final double rateManager =
          (realtimeData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
          0.0;
      final double rateAds =
          (realtimeData[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
          0.0;

      // Check if migration is needed
      final bool needsMigration =
          (!realtimeData.containsKey(FirestoreUserFields.hourlyRate) &&
              data.containsKey(FirestoreUserFields.hourlyRate)) ||
          (!realtimeData.containsKey(
                FirestoreUserFields.managedCoinSelections,
              ) &&
              data.containsKey(FirestoreUserFields.managedCoinSelections)) ||
          (!realtimeData.containsKey(FirestoreUserFields.managerBonusPerHour) &&
              data.containsKey(FirestoreUserFields.managerBonusPerHour));

      // Prefer realtime doc for totalPoints, fallback to user doc
      double totalPoints =
          (realtimeData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
          (data[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
          0.0;

      if (startTs == null) {
        return {
          FirestoreUserFields.totalPoints: totalPoints,
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
          FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          'userData': data,
          FirestoreUserFields.rateBase: rateBase,
          FirestoreUserFields.rateStreak: rateStreak,
          FirestoreUserFields.rateRank: rateRank,
          FirestoreUserFields.rateReferral: rateReferral,
          FirestoreUserFields.rateManager: rateManager,
          FirestoreUserFields.rateAds: rateAds,
        };
      }
      final now = DateTime.now();
      final end = endTs?.toDate();
      final sessionEnd = end ?? now;
      final effectiveEnd = now.isBefore(sessionEnd) ? now : sessionEnd;
      final from = (syncedTs ?? startTs).toDate();
      if (!effectiveEnd.isAfter(from)) {
        return {
          FirestoreUserFields.totalPoints: totalPoints,
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
          FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          'userData': data,
          FirestoreUserFields.rateBase: rateBase,
          FirestoreUserFields.rateStreak: rateStreak,
          FirestoreUserFields.rateRank: rateRank,
          FirestoreUserFields.rateReferral: rateReferral,
          FirestoreUserFields.rateManager: rateManager,
          FirestoreUserFields.rateAds: rateAds,
        };
      }
      final elapsedHours =
          effectiveEnd.difference(from).inMilliseconds / (1000 * 60 * 60);
      final earned = elapsedHours * hourlyRate;

      // Throttle writes: strict 10-minute rule to prevent frequent updates
      // UNLESS:
      // 1. Migration is needed
      // 2. Session is completing (effectiveEnd reached endTs)
      final diffMinutes = effectiveEnd.difference(from).inMinutes;
      final bool isSessionComplete =
          endTs != null && !effectiveEnd.isBefore(endTs.toDate());

      // Check local cache for strict throttle to prevent writes when toggling background/foreground
      final lastWrite = _lastLocalWrites[uid];
      final bool recentlyWrittenLocally =
          lastWrite != null &&
          DateTime.now().difference(lastWrite).inMinutes < 10;

      if (!needsMigration &&
          !isSessionComplete &&
          (diffMinutes < 10 || recentlyWrittenLocally)) {
        return {
          FirestoreUserFields.totalPoints:
              totalPoints + earned, // Return calculated total for UI
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
          FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(
            from,
          ), // Keep old sync time
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

      // Write to realtime subcollection INSTEAD of main user doc
      final Map<String, dynamic> writeData = {
        FirestoreUserFields.totalPoints: FieldValue.increment(earned),
        FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(effectiveEnd),
        FirestoreUserFields.hourlyRate: hourlyRate,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      };
      transaction.set(realtimeRef, writeData, SetOptions(merge: true));

      if (earned > 0) {
        final newLogDoc = pointLogsRef.doc();
        transaction.set(newLogDoc, {
          FirestorePointLogFields.userId: uid,
          FirestorePointLogFields.type: FirestorePointLogTypes.tap,
          FirestorePointLogFields.amount: earned,
          FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
          FirestorePointLogFields.description: 'Session earnings',
        });
      }

      return {
        FirestoreUserFields.totalPoints: (totalPoints + earned),
        FirestoreUserFields.hourlyRate: hourlyRate,
        FirestoreUserFields.managedCoinSelections: managedCoinSelections,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.lastMiningStart: startTs,
        FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(effectiveEnd),
        FirestoreUserFields.lastMiningEnd: endTs,
        'userData': data,
        FirestoreUserFields.rateBase: rateBase,
        FirestoreUserFields.rateStreak: rateStreak,
        FirestoreUserFields.rateRank: rateRank,
        FirestoreUserFields.rateReferral: rateReferral,
        FirestoreUserFields.rateManager: rateManager,
        FirestoreUserFields.rateAds: rateAds,
        '_didWrite': true,
      };
    });

    if (result['_didWrite'] == true) {
      _pruneLocalWrites();
      _lastLocalWrites[uid] = DateTime.now();
    }

    return result;
  }

  static Future<void> applyAdBoost({
    required String uid,
    required double boostAmount,
  }) async {
    final userRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    final realtimeRef = userRef
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final realtimeSnap = await transaction.get(realtimeRef);
      final data = realtimeSnap.data() ?? {};

      final double currentRate =
          (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;
      final double currentAds =
          (data[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;

      final double newAds = currentAds + boostAmount;
      final double newRate = currentRate + boostAmount;

      transaction.set(realtimeRef, {
        FirestoreUserFields.rateAds: newAds,
        FirestoreUserFields.hourlyRate: newRate,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static Future<bool> recalculateRates({required String uid}) async {
    final userRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    final realtimeRef = userRef
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime);

    // PRE-FETCH: Load Configs and Referral Count outside transaction to avoid blocking/timeouts
    final generalCfgFuture = ConfigService().getGeneralConfig();
    final streakCfgFuture = ConfigService().getStreakConfig();
    final ranksCfgFuture = ConfigService().getRanksConfig();
    final refCfgFuture = ConfigService().getReferralConfig();

    final DateTime activeThreshold = DateTime.now().subtract(
      const Duration(hours: 48),
    );
    final referralCountFuture = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .where(FirestoreUserFields.invitedBy, isEqualTo: uid)
        .where(
          FirestoreUserFields.lastMiningEnd,
          isGreaterThan: Timestamp.fromDate(activeThreshold),
        )
        .count()
        .get();

    final results = await Future.wait([
      generalCfgFuture,
      streakCfgFuture,
      ranksCfgFuture,
      refCfgFuture,
      referralCountFuture,
    ]);

    final generalCfg = results[0] as Map<String, dynamic>;
    final streakCfg = results[1] as Map<String, dynamic>;
    final ranksCfg = results[2] as Map<String, dynamic>;
    final refCfg = results[3] as Map<String, dynamic>;
    final referralCountAgg = results[4] as AggregateQuerySnapshot;
    final int referralCount = referralCountAgg.count ?? 0;

    final result = await FirebaseFirestore.instance.runTransaction((
      transaction,
    ) async {
      final realtimeSnap = await transaction.get(realtimeRef);
      final realtimeData = realtimeSnap.data() ?? {};

      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) return false;
      final userData = userSnap.data()!;

      // Check if mining is active
      final Timestamp? lastEndTs =
          userData[FirestoreUserFields.lastMiningEnd] as Timestamp?;
      final DateTime now = DateTime.now();
      if (lastEndTs == null || now.isAfter(lastEndTs.toDate())) {
        return false; // Not mining
      }

      // Recalculate Components
      final int streakDays =
          (userData[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;
      final double streakMultiplier = _streakMultiplier(streakDays, streakCfg);

      final String currentRank =
          (userData[FirestoreUserFields.rank] as String?) ?? 'Explorer';
      final double rankMultiplier = _rankMultiplierByName(
        currentRank,
        ranksCfg,
      );

      final double referralMultiplier = _calculateReferralMultiplier(
        referralCount,
        refCfg,
      );

      final double baseRate =
          (generalCfg[FirestoreAppConfigFields.baseRate] as num?)?.toDouble() ??
          0.2;

      // Manager
      double rateManager = 0.0;
      final String? activeManagerId =
          userData[FirestoreUserFields.activeManagerId] as String?;
      final bool managerEnabled =
          (userData[FirestoreUserFields.managerEnabled] as bool?) ?? false;

      if (managerEnabled &&
          activeManagerId != null &&
          activeManagerId.isNotEmpty) {
        final managerRef = FirebaseFirestore.instance
            .collection(FirestoreConstants.managers)
            .doc(activeManagerId);
        final managerDoc = await transaction.get(managerRef);

        if (managerDoc.exists) {
          final mData = managerDoc.data()!;
          final expiresAt =
              mData[FirestoreManagerFields.expiresAt] as Timestamp?;
          final bool isExpired =
              expiresAt != null && expiresAt.toDate().isBefore(now);
          if (!isExpired) {
            final double multiplier =
                (mData[FirestoreManagerFields.managerMultiplier] as num?)
                    ?.toDouble() ??
                0.0;
            rateManager = baseRate * multiplier;
          }
        }
      }

      // Calculate new components
      final double streakFrac = (streakMultiplier - 1.0).clamp(0.0, 1000.0);
      final double rankFrac = (rankMultiplier - 1.0).clamp(0.0, 1000.0);
      final double referralFrac = (referralMultiplier - 1.0).clamp(0.0, 1000.0);

      final double rateStreak = baseRate * streakFrac;
      final double rateRank = baseRate * rankFrac;
      final double rateReferral = baseRate * referralFrac;

      // Ads & Migration Logic
      double rateAds =
          (realtimeData[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
          0.0;

      final double currentHourlyRate =
          (realtimeData[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          0.0;

      // Detect if we need to migrate ads (active session, rate mismatch, no ads recorded)
      final double calculatedWithoutAds =
          baseRate + rateStreak + rateRank + rateReferral + rateManager;

      // If we have a significant discrepancy and ads are 0, assume the difference is ads
      if (rateAds == 0.0 && currentHourlyRate > calculatedWithoutAds + 0.001) {
        final double diff = currentHourlyRate - calculatedWithoutAds;
        if (diff > 0) {
          rateAds = diff;
          debugPrint('EarningsEngine: Migrated implicit ad bonus: $rateAds');
        }
      }

      final double newHourlyRate = calculatedWithoutAds + rateAds;

      // Dirty Check: Prevent writes if nothing changed
      final double currentBase =
          (realtimeData[FirestoreUserFields.rateBase] as num?)?.toDouble() ??
          0.0;
      final double currentStreak =
          (realtimeData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
          0.0;
      final double currentRateRank =
          (realtimeData[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
          0.0;
      final double currentReferral =
          (realtimeData[FirestoreUserFields.rateReferral] as num?)
              ?.toDouble() ??
          0.0;
      final double currentManager =
          (realtimeData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
          0.0;
      final double currentAds =
          (realtimeData[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
          0.0;

      final bool changed =
          (newHourlyRate - currentHourlyRate).abs() > 0.001 ||
          (baseRate - currentBase).abs() > 0.001 ||
          (rateStreak - currentStreak).abs() > 0.001 ||
          (rateRank - currentRateRank).abs() > 0.001 ||
          (rateReferral - currentReferral).abs() > 0.001 ||
          (rateManager - currentManager).abs() > 0.001 ||
          (rateAds - currentAds).abs() > 0.001;

      if (!changed) {
        return false;
      }

      final Map<String, dynamic> writeData = {
        FirestoreUserFields.hourlyRate: newHourlyRate,
        FirestoreUserFields.rateBase: baseRate,
        FirestoreUserFields.rateStreak: rateStreak,
        FirestoreUserFields.rateRank: rateRank,
        FirestoreUserFields.rateReferral: rateReferral,
        FirestoreUserFields.rateManager: rateManager,
        FirestoreUserFields.managerBonusPerHour: rateManager,
        FirestoreUserFields.rateAds: rateAds,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      };
      transaction.set(realtimeRef, writeData, SetOptions(merge: true));

      return true;
    });

    return result;
  }

  static Future<Map<String, dynamic>> startMining({
    String? deviceId,
    DateTime? maxEnd,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    // 1. Sync Earnings (1 READ from Realtime, 0 from User via Cache)
    final syncRes = await syncEarnings();

    // 2. Resolve User Data (Reuse syncRes or fetch from cache)
    Map<String, dynamic> data =
        (syncRes['userData'] as Map<String, dynamic>?) ?? {};
    if (data.isEmpty) {
      final snap = await UserService().getUser(uid);
      data = snap?.data() ?? {};
    }

    // 3. Resolve Realtime Data (Reuse syncRes)
    // syncRes contains totalPoints merged from realtime+user
    double totalPoints =
        (syncRes[FirestoreUserFields.totalPoints] as num?)?.toDouble() ?? 0.0;
    final double managerBonusPerHour =
        (syncRes[FirestoreUserFields.managerBonusPerHour] as num?)
            ?.toDouble() ??
        0.0;

    final bool isBanned = (data['isBanned'] as bool?) ?? false;
    if (isBanned) {
      throw Exception('User banned');
    }
    final Timestamp? lastEndTs =
        data[FirestoreUserFields.lastMiningEnd] as Timestamp?;
    final DateTime now = DateTime.now();

    // Active Check
    if (lastEndTs != null && now.isBefore(lastEndTs.toDate())) {
      return {
        FirestoreUserFields.hourlyRate:
            (syncRes[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
            (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
            0.0,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.lastMiningStart:
            data[FirestoreUserFields.lastMiningStart],
        FirestoreUserFields.lastMiningEnd: lastEndTs,
        FirestoreUserFields.totalPoints: totalPoints,
        FirestoreUserFields.streakDays:
            (data[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0,
      };
    }

    // 4. Load Configs (0 READS - cached)
    final generalCfg = await ConfigService().getGeneralConfig();
    final streakCfg = await ConfigService().getStreakConfig();
    final ranksCfg = await ConfigService().getRanksConfig();
    final refCfg = await ConfigService().getReferralConfig();

    // 5. Device Check
    final bool enforceSingleDevice =
        (generalCfg[FirestoreAppConfigFields.deviceSingleUserEnforced]
            as bool?) ??
        false;
    if (!kIsDev && enforceSingleDevice) {
      final String dev = deviceId ?? '';
      if (dev.isNotEmpty) {
        final qs = await FirebaseFirestore.instance
            .collection(FirestoreConstants.users)
            .where(FirestoreUserFields.deviceId, isEqualTo: dev)
            .limit(1)
            .get();
        if (qs.docs.isNotEmpty && qs.docs.first.id != uid) {
          throw Exception('Device already bound to another account');
        }
      }
    }

    // 6. Compute Streak (Memory)
    final streakRes = _calculateStreak(data, streakCfg);
    final int newStreakDays =
        streakRes[FirestoreUserFields.streakDays] as int? ?? 0;
    final int? streakLastUpdatedDay =
        streakRes[FirestoreUserFields.streakLastUpdatedDay] as int?;
    final bool streakIncremented = (streakRes['incremented'] as bool?) ?? false;

    // 7. Compute Rank (Memory)
    // 7a. Get Active Referrals (1 AGGREGATION QUERY)
    final DateTime activeThreshold = DateTime.now().subtract(
      const Duration(hours: 48),
    );
    final referralCountAgg = await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .where(FirestoreUserFields.invitedBy, isEqualTo: uid)
        .where(
          FirestoreUserFields.lastMiningEnd,
          isGreaterThan: Timestamp.fromDate(activeThreshold),
        )
        .count()
        .get();
    final int referralCount = referralCountAgg.count ?? 0;

    final String currentRank =
        (data[FirestoreUserFields.rank] as String?) ?? 'Explorer';
    final String bestRank = RankEngine.getBestRank(
      streakDays: newStreakDays,
      activeReferrals: referralCount,
      ranksCfg: ranksCfg,
      currentRank: currentRank,
    );

    // 8. Calculate Rates
    final double baseRate =
        (generalCfg[FirestoreAppConfigFields.baseRate] as num?)?.toDouble() ??
        0.2;
    final double sessionHours =
        (generalCfg[FirestoreAppConfigFields.sessionDurationHours] as num?)
            ?.toDouble() ??
        24.0;

    final double streakMultiplier = _streakMultiplier(newStreakDays, streakCfg);
    final double rankMultiplier = _rankMultiplierByName(bestRank, ranksCfg);
    final double referralMultiplier = _calculateReferralMultiplier(
      referralCount,
      refCfg,
    );

    // 8a. Calculate Manager Bonus
    double rateManager = 0.0;
    final String? activeManagerId =
        data[FirestoreUserFields.activeManagerId] as String?;
    final bool managerEnabled =
        (data[FirestoreUserFields.managerEnabled] as bool?) ?? false;

    if (managerEnabled &&
        activeManagerId != null &&
        activeManagerId.isNotEmpty) {
      final managerDoc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.managers)
          .doc(activeManagerId)
          .get();

      if (managerDoc.exists) {
        final mData = managerDoc.data()!;
        final expiresAt = mData[FirestoreManagerFields.expiresAt] as Timestamp?;
        final bool isExpired =
            expiresAt != null && expiresAt.toDate().isBefore(now);

        if (!isExpired) {
          final double multiplier =
              (mData[FirestoreManagerFields.managerMultiplier] as num?)
                  ?.toDouble() ??
              0.0;
          rateManager = baseRate * multiplier;
        }
      }
    }

    // 8b. Ads Bonus (Start with 0 for new session)
    final double rateAds = 0.0;

    final double streakFrac = (streakMultiplier - 1.0).clamp(0.0, 1000.0);
    final double rankFrac = (rankMultiplier - 1.0).clamp(0.0, 1000.0);
    final double referralFrac = (referralMultiplier - 1.0).clamp(0.0, 1000.0);

    final double rateStreak = baseRate * streakFrac;
    final double rateRank = baseRate * rankFrac;
    final double rateReferral = baseRate * referralFrac;

    // Total Hourly Rate Summation
    final double hourlyRate =
        baseRate + rateStreak + rateRank + rateReferral + rateManager + rateAds;

    debugPrint(
      'EarningsEngine: rate calc → baseRate=${baseRate.toStringAsFixed(6)}, sessionHours=$sessionHours',
    );
    debugPrint(
      'EarningsEngine: components → streak=$rateStreak, rank=$rateRank, ref=$rateReferral, manager=$rateManager, ads=$rateAds',
    );
    debugPrint(
      'EarningsEngine: final hourlyRate=${hourlyRate.toStringAsFixed(6)}',
    );

    final DateTime start = now;
    final int sessionSeconds = (sessionHours > 0.0
        ? (sessionHours * 3600.0).round()
        : 0);
    DateTime end = now.add(
      Duration(seconds: sessionSeconds > 0 ? sessionSeconds : 24 * 3600),
    );
    if (maxEnd != null && maxEnd.isAfter(start) && maxEnd.isBefore(end)) {
      end = maxEnd;
    }

    // 9. Update Firestore
    final userRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    final realtimeRef = userRef
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime);

    final batch = FirebaseFirestore.instance.batch();

    final Map<String, dynamic> userUpdates = {
      // MOVED to realtime: FirestoreUserFields.hourlyRate: hourlyRate,
      FirestoreUserFields.lastMiningStart: Timestamp.fromDate(start),
      FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(end),
      FirestoreUserFields.deviceId: deviceId,
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreUserFields.streakDays: newStreakDays,
      FirestoreUserFields.totalSessions: FieldValue.increment(1),
    };
    if (streakLastUpdatedDay != null) {
      userUpdates[FirestoreUserFields.streakLastUpdatedDay] =
          streakLastUpdatedDay;
    }
    if (bestRank != currentRank) {
      userUpdates[FirestoreUserFields.rank] = bestRank;
    }

    batch.update(userRef, userUpdates);

    final Map<String, dynamic> realtimeUpdates = {
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(start),
      FirestoreUserFields.hourlyRate: hourlyRate,
      // Save Components
      FirestoreUserFields.rateBase: baseRate,
      FirestoreUserFields.rateStreak: rateStreak,
      FirestoreUserFields.rateRank: rateRank,
      FirestoreUserFields.rateReferral: rateReferral,
      FirestoreUserFields.rateManager: rateManager,
      FirestoreUserFields.managerBonusPerHour: rateManager,
      FirestoreUserFields.rateAds: rateAds,
    };

    batch.set(realtimeRef, realtimeUpdates, SetOptions(merge: true));

    // Streak Log
    if (streakIncremented) {
      final logRef = FirebaseFirestore.instance
          .collection(FirestoreConstants.pointLogs)
          .doc();
      batch.set(logRef, {
        FirestorePointLogFields.userId: uid,
        FirestorePointLogFields.type: FirestorePointLogTypes.streak,
        FirestorePointLogFields.amount: 0,
        FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
        FirestorePointLogFields.description:
            'Streak updated to $newStreakDays days',
      });
    }
    // Rank Log
    if (bestRank != currentRank) {
      final logRef = FirebaseFirestore.instance
          .collection(FirestoreConstants.pointLogs)
          .doc();
      batch.set(logRef, {
        FirestorePointLogFields.userId: uid,
        FirestorePointLogFields.type: FirestorePointLogTypes.bonus,
        FirestorePointLogFields.amount: 0,
        FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
        FirestorePointLogFields.description: 'Rank updated to $bestRank',
      });
    }

    await batch.commit();

    // 10. Referral Activation (Rare)
    final bool activateOnFirstSession =
        (refCfg[FirestoreReferralConfigFields.activateOnFirstSession]
            as bool?) ??
        false;
    if (activateOnFirstSession) {
      await _activateReferralOnFirstSession(uid, refCfg);
    }

    return {
      FirestoreUserFields.hourlyRate: hourlyRate,
      FirestoreUserFields.lastMiningStart: Timestamp.fromDate(start),
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(start),
      FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(end),
      FirestoreUserFields.streakDays: newStreakDays,
      FirestoreUserFields.totalPoints: totalPoints,
      FirestoreUserFields.rateBase: baseRate,
      FirestoreUserFields.rateStreak: rateStreak,
      FirestoreUserFields.rateRank: rateRank,
      FirestoreUserFields.rateReferral: rateReferral,
      FirestoreUserFields.rateManager: rateManager,
      FirestoreUserFields.managerBonusPerHour: rateManager,
      FirestoreUserFields.rateAds: rateAds,
      'debug': {
        'baseRate': baseRate,
        'streakBonus': rateStreak,
        'rankBonus': rateRank,
        'referralBonus': rateReferral,
        'hourlyRate': hourlyRate,
      },
    };
  }

  static Future<void> _activateReferralOnFirstSession(
    String uid,
    Map<String, dynamic> refCfg,
  ) async {
    final pendingReferral = await FirebaseFirestore.instance
        .collection(FirestoreConstants.referrals)
        .where(FirestoreReferralFields.inviteeId, isEqualTo: uid)
        .where(FirestoreReferralFields.isActive, isEqualTo: false)
        .limit(1)
        .get();
    if (pendingReferral.docs.isNotEmpty) {
      final doc = pendingReferral.docs.first;
      final inviterUid = doc[FirestoreReferralFields.inviterId] as String?;
      if (inviterUid != null && inviterUid.isNotEmpty) {
        final double referrerBonus =
            (refCfg[FirestoreReferralConfigFields.referrerBonus] as num?)
                ?.toDouble() ??
            0.0;
        final double inviteeBonus =
            (refCfg[FirestoreReferralConfigFields.inviteeBonus] as num?)
                ?.toDouble() ??
            0.0;
        final batch = FirebaseFirestore.instance.batch();
        final referralsDocRef = FirebaseFirestore.instance
            .collection(FirestoreConstants.referrals)
            .doc(doc.id);
        final users = FirebaseFirestore.instance.collection(
          FirestoreConstants.users,
        );
        final inviterRef = users.doc(inviterUid);
        final inviterRealtimeRef = inviterRef
            .collection(FirestoreUserSubCollections.earnings)
            .doc(FirestoreEarningsDocs.realtime);
        final realtimeRef = users
            .doc(uid)
            .collection(FirestoreUserSubCollections.earnings)
            .doc(FirestoreEarningsDocs.realtime);

        final points = FirebaseFirestore.instance.collection(
          FirestoreConstants.pointLogs,
        );
        final inviterLog = points.doc();
        final inviteeLog = points.doc();
        batch.update(referralsDocRef, {FirestoreReferralFields.isActive: true});
        batch.set(inviterLog, {
          FirestorePointLogFields.userId: inviterUid,
          FirestorePointLogFields.type: FirestorePointLogTypes.referral,
          FirestorePointLogFields.amount: referrerBonus,
          FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
          FirestorePointLogFields.description:
              'Referral bonus activated on first session',
        });
        batch.set(inviteeLog, {
          FirestorePointLogFields.userId: uid,
          FirestorePointLogFields.type: FirestorePointLogTypes.referral,
          FirestorePointLogFields.amount: inviteeBonus,
          FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
          FirestorePointLogFields.description:
              'Referral bonus (invitee) activated on first session',
        });
        batch.set(inviterRealtimeRef, {
          FirestoreUserFields.totalPoints: FieldValue.increment(referrerBonus),
        }, SetOptions(merge: true));
        batch.set(realtimeRef, {
          FirestoreUserFields.totalPoints: FieldValue.increment(inviteeBonus),
        }, SetOptions(merge: true));

        await batch.commit();
        await RankEngine.updateUserRank(inviterUid);
        // We already updated user rank for current user in startMining, no need to do it again here
        // unless activation changes rank immediately? It might.
        // But let's save the read/write for now or do it if strictness is needed.
      }
    }
  }

  static Future<void> migrateLegacyData({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    final realtimeRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime);

    final realtimeSnap = await realtimeRef.get();
    final realtimeData = realtimeSnap.data() ?? {};

    final Map<String, dynamic> updates = {};

    // Check totalPoints
    if (!realtimeData.containsKey(FirestoreUserFields.totalPoints)) {
      final val = userData[FirestoreUserFields.totalPoints];
      if (val != null) updates[FirestoreUserFields.totalPoints] = val;
    }

    // Check hourlyRate
    if (!realtimeData.containsKey(FirestoreUserFields.hourlyRate)) {
      final val = userData[FirestoreUserFields.hourlyRate];
      if (val != null) updates[FirestoreUserFields.hourlyRate] = val;
    }

    // Check managedCoinSelections
    if (!realtimeData.containsKey(FirestoreUserFields.managedCoinSelections)) {
      final val = userData[FirestoreUserFields.managedCoinSelections];
      if (val != null) updates[FirestoreUserFields.managedCoinSelections] = val;
    }

    // Check managerBonusPerHour
    if (!realtimeData.containsKey(FirestoreUserFields.managerBonusPerHour)) {
      final val = userData[FirestoreUserFields.managerBonusPerHour];
      if (val != null) updates[FirestoreUserFields.managerBonusPerHour] = val;
    }

    if (updates.isNotEmpty) {
      updates[FirestoreUserFields.updatedAt] = FieldValue.serverTimestamp();
      await realtimeRef.set(updates, SetOptions(merge: true));
    }
  }

  static Map<String, dynamic> _calculateStreak(
    Map<String, dynamic> data,
    Map<String, dynamic> streakCfg,
  ) {
    final Timestamp? lastEndTs =
        data[FirestoreUserFields.lastMiningEnd] as Timestamp?;
    final DateTime nowUtc = DateTime.now().toUtc();
    final DateTime today = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final int current =
        (data[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;

    final int lastUpdatedDay =
        (data[FirestoreUserFields.streakLastUpdatedDay] as num?)?.toInt() ?? 0;
    int todayInt = nowUtc.year * 10000 + nowUtc.month * 100 + nowUtc.day;
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    int yesterdayInt =
        yesterday.year * 10000 + yesterday.month * 100 + yesterday.day;

    int updated = current;
    bool incremented = false;

    if (lastEndTs == null) {
      updated = 1;
    } else {
      final endUtc = lastEndTs.toDate().toUtc();
      final DateTime d = DateTime.utc(endUtc.year, endUtc.month, endUtc.day);
      final int dInt = d.year * 10000 + d.month * 100 + d.day;

      if (dInt == yesterdayInt) {
        updated = current + 1;
        incremented = true;
      } else if (dInt == todayInt) {
        if (lastUpdatedDay == todayInt) {
          updated = current; // Already updated today
        } else {
          updated = current + 1; // First session ending today?
          incremented = true;
        }
      } else {
        // Gap > 1 day or future
        updated = 1;
      }
    }

    final int maxDays =
        (streakCfg[FirestoreStreakConfigFields.maxStreakDays] as num?)
            ?.toInt() ??
        15;

    if (updated > maxDays) updated = maxDays;
    if (updated < 1) updated = 1;

    return {
      FirestoreUserFields.streakDays: updated,
      FirestoreUserFields.streakLastUpdatedDay: incremented
          ? todayInt
          : lastUpdatedDay,
      'incremented': incremented,
    };
  }

  static double _calculateReferralMultiplier(
    int count,
    Map<String, dynamic> cfg,
  ) {
    final Map<String, dynamic> tiersRaw =
        (cfg[FirestoreReferralConfigFields.referralBonusTiers]
            as Map<String, dynamic>?) ??
        {};
    final List<MapEntry<int, double>> tiers =
        tiersRaw.entries
            .map(
              (e) => MapEntry(
                int.tryParse(e.key) ?? 0,
                (e.value as num?)?.toDouble() ?? 0.0,
              ),
            )
            .where((e) => e.key > 0 && e.value > 0.0)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    int maxCount =
        (cfg[FirestoreReferralConfigFields.rewardedReferralMaxCount] as num?)
            ?.toInt() ??
        (cfg[FirestoreReferralConfigFields.referrerMaxCount] as num?)
            ?.toInt() ??
        100;
    if (maxCount <= 0) {
      maxCount = 0;
    }

    int effective = count;
    if (maxCount > 0) {
      effective = count.clamp(0, maxCount);
    } else {
      effective = count.clamp(0, 1000000);
    }

    double percentPerReferralRaw;
    if (tiers.isNotEmpty) {
      int thresholdForLog = 0;
      double selectedPercent = 0.0;
      for (final t in tiers) {
        if (effective <= t.key) {
          thresholdForLog = t.key;
          selectedPercent = t.value;
          break;
        }
      }
      if (thresholdForLog == 0) {
        final last = tiers.last;
        thresholdForLog = last.key;
        selectedPercent = last.value;
      }
      percentPerReferralRaw = selectedPercent;
    } else {
      percentPerReferralRaw =
          (cfg[FirestoreReferralConfigFields.referrerPercentPerReferral]
                  as num?)
              ?.toDouble() ??
          (cfg.containsKey(FirestoreAppConfigFields.referralBonusStep)
              ? (cfg[FirestoreAppConfigFields.referralBonusStep] as num?)
                        ?.toDouble() ??
                    0.0
              : 0.0);
    }

    final double percentPerReferral = (percentPerReferralRaw <= 0.0)
        ? 0.0
        : (percentPerReferralRaw / 100.0);
    final double totalPercent = percentPerReferral * effective;
    return 1.0 + totalPercent;
  }

  static double _streakMultiplier(
    int streakDays,
    Map<String, dynamic> streakCfg,
  ) {
    final table = streakCfg[FirestoreAppConfigFields.streakBonusTable];
    if (table is Map<String, dynamic>) {
      double m = 1.0;
      int bestThreshold = 0;
      table.forEach((k, v) {
        final int threshold = int.tryParse(k) ?? 0;
        final double mult = (v as num?)?.toDouble() ?? 1.0;
        if (streakDays >= threshold && mult > m) {
          m = mult;
          bestThreshold = threshold;
        }
      });
      debugPrint(
        'EarningsEngine: streak table → days=$streakDays, bestThreshold=$bestThreshold, multiplier=${m.toStringAsFixed(6)}',
      );
      return m;
    }
    final int maxDays =
        (streakCfg[FirestoreStreakConfigFields.maxStreakDays] as num?)
            ?.toInt() ??
        15;
    final double maxMult =
        (streakCfg[FirestoreStreakConfigFields.maxStreakMultiplier] as num?)
            ?.toDouble() ??
        2.0;
    if (streakDays <= 1) {
      debugPrint(
        'EarningsEngine: streak linear → days=$streakDays/$maxDays, maxMult=${maxMult.toStringAsFixed(6)}, multiplier=1.000000',
      );
      return 1.0;
    }
    final int d = streakDays.clamp(1, maxDays);
    final double t = maxDays > 1 ? (d - 1) / (maxDays - 1) : 0.0;
    final double res = 1.0 + t * (maxMult - 1.0);
    debugPrint(
      'EarningsEngine: streak linear → days=$streakDays/$maxDays, maxMult=${maxMult.toStringAsFixed(6)}, multiplier=${res.toStringAsFixed(6)}',
    );
    return res;
  }

  static double _rankMultiplierByName(
    String rank,
    Map<String, dynamic> ranksCfg,
  ) {
    final mults = ranksCfg[FirestoreRankConfigFields.rankMultipliers];
    double out = 1.0;
    if (mults is Map<String, dynamic>) {
      final v = mults[rank];
      out = (v as num?)?.toDouble() ?? 1.0;
    }
    debugPrint(
      'EarningsEngine: rank table → rank=$rank, multiplier=${out.toStringAsFixed(6)}',
    );
    return out;
  }
}
