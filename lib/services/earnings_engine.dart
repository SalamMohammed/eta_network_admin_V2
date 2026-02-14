import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eta_network_admin/utils/firestore_helper.dart';
import '../shared/firestore_constants.dart';
import 'rank_engine.dart';
import 'config_service.dart';
import 'user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarningsEngine {
  static final Map<String, DateTime> _lastLocalWrites = {};

  static void _pruneLocalWrites() {
    final now = DateTime.now();
    // Remove entries older than 20 minutes to prevent memory leaks
    _lastLocalWrites.removeWhere(
      (key, time) => now.difference(time).inMinutes > 20,
    );
  }

  static Future<bool> migrateRealtimeToUnifiedIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final localKey = 'unified_migration_done_$uid';
      final bool localDone = prefs.getBool(localKey) == true;
      final userRef = FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid);
      final realtimeRef = userRef
          .collection(FirestoreUserSubCollections.earnings)
          .doc(FirestoreEarningsDocs.realtime);
      final userSnap = await userRef.get();
      final userData = userSnap.data() ?? {};
      final bool hasFlag =
          (userData[FirestoreUserFields.migrationUnifiedEarnings] as bool?) ==
          true;
      // Pre-check realtime content to detect incomplete migrations
      final preRealtimeSnap = await realtimeRef.get();
      final preRealtime = preRealtimeSnap.data() ?? {};
      final bool userLooksEmpty =
          (userData[FirestoreUserFields.totalPoints] == null &&
          userData[FirestoreUserFields.hourlyRate] == null &&
          userData[FirestoreUserFields.lastSyncedAt] == null);
      final bool realtimeHasData =
          preRealtime.isNotEmpty &&
          (preRealtime[FirestoreUserFields.totalPoints] != null ||
              preRealtime[FirestoreUserFields.hourlyRate] != null ||
              preRealtime[FirestoreUserFields.lastSyncedAt] != null);
      if (hasFlag && !realtimeHasData && !userLooksEmpty) {
        // Appears fully migrated already
        if (!localDone) {
          await prefs.setBool(localKey, true);
        }
        debugPrint(
          '[EarningsEngine] migrateRealtimeToUnifiedIfNeeded: already migrated for $uid (verified user has data)',
        );
        return false;
      }
      // If flag is true but user doc lacks data while realtime has it, force migration
      final bool needsMigration =
          (!hasFlag && (realtimeHasData || userLooksEmpty)) ||
          (hasFlag && userLooksEmpty && realtimeHasData);
      if (!needsMigration) {
        if (!localDone) {
          await prefs.setBool(localKey, true);
        }
        debugPrint(
          '[EarningsEngine] migrateRealtimeToUnifiedIfNeeded: no migration needed for $uid (flag=$hasFlag, userEmpty=$userLooksEmpty, realtimeHas=$realtimeHasData)',
        );
        return false;
      }
      debugPrint(
        '[EarningsEngine] migrateRealtimeToUnifiedIfNeeded: starting transaction for $uid',
      );
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userTx = await tx.get(userRef);
        final live = userTx.data() ?? {};
        final realtimeTx = await tx.get(realtimeRef);
        final realtimeData = realtimeTx.data() ?? {};
        if (realtimeData.isEmpty) {
          // If no realtime data, only mark migrated if user already holds the necessary fields
          final bool userHasCore =
              live.containsKey(FirestoreUserFields.totalPoints) ||
              live.containsKey(FirestoreUserFields.hourlyRate) ||
              live.containsKey(FirestoreUserFields.lastSyncedAt);
          if (userHasCore) {
            tx.set(userRef, {
              FirestoreUserFields.migrationUnifiedEarnings: true,
              FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            // Delete empty legacy doc to tidy up
            tx.delete(realtimeRef);
          } else {
            // Leave flag false so future runs can retry when data appears
            debugPrint(
              '[EarningsEngine] Migration skipped inside tx: realtime empty and user lacks core fields for $uid',
            );
          }
          return;
        }
        final r = _buildMigrationPayloadAndMissing(
          realtimeData: realtimeData,
          liveData: live,
        );
        final Map<String, dynamic> payload =
            r['payload'] as Map<String, dynamic>;
        final List<String> missing = (r['missing'] as List).cast<String>();
        if (missing.isNotEmpty) {
          debugPrint(
            '[EarningsEngine] Migration: some fields missing in realtime/live; applying defaults for $uid: ${missing.join(', ')}',
          );
        }
        payload[FirestoreUserFields.migrationUnifiedEarnings] = true;
        payload[FirestoreUserFields.updatedAt] = FieldValue.serverTimestamp();
        tx.set(userRef, payload, SetOptions(merge: true));
        // Clean up legacy realtime document after successful write
        tx.delete(realtimeRef);
      });
      await prefs.setBool(localKey, true);
      debugPrint(
        '[EarningsEngine] migrateRealtimeToUnifiedIfNeeded: migration success for $uid',
      );
      // Post-commit verification: ensure fields present
      try {
        final verifySnap = await userRef.get();
        final v = verifySnap.data() ?? {};
        final keys = [
          FirestoreUserFields.lastSyncedAt,
          FirestoreUserFields.hourlyRate,
          FirestoreUserFields.rateBase,
          FirestoreUserFields.rateStreak,
          FirestoreUserFields.rateRank,
          FirestoreUserFields.rateReferral,
          FirestoreUserFields.rateManager,
          FirestoreUserFields.rateAds,
          FirestoreUserFields.managerBonusPerHour,
          FirestoreUserFields.updatedAt,
          FirestoreUserFields.totalPoints,
          FirestoreUserFields.managedCoinSelections,
        ];
        final missing = <String>[];
        for (final k in keys) {
          if (!v.containsKey(k) || v[k] == null) {
            missing.add(k);
          }
        }
        if (missing.isNotEmpty) {
          debugPrint(
            '[EarningsEngine] Migration verification failed for $uid. Missing after commit: ${missing.join(', ')}',
          );
          // Leave migrationUnifiedEarnings as true to avoid blocking, but log the failure
          // and rely on subsequent syncs to fill remaining fields from unified path.
        }
      } catch (e) {
        debugPrint('[EarningsEngine] Post-commit verification failed: $e');
      }
      return true;
    } catch (e) {
      debugPrint('[EarningsEngine] Migration failed: $e');
      return false;
    }
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

    // Ensure migration runs even if MiningStateService.init hasn't yet
    await migrateRealtimeToUnifiedIfNeeded();

    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    final pointLogsRef = FirestoreHelper.instance.collection(
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
      // Note: We still need to fetch unified user doc to get the components and latest sync time
      // But we can do a simple GET instead of a transaction.
      // Or better yet, just return what we have if we assume it hasn't changed much?
      // No, we need to calculate 'earned' points based on elapsed time since last sync.

      try {
        // OPTIMIZATION: Use UserService cache for unified user doc to avoid redundant reads
        final liveSnap = await UserService().getRealtimeDoc(uid);
        final liveData = liveSnap?.data() ?? {};

        final Timestamp? startTs =
            data[FirestoreUserFields.lastMiningStart] as Timestamp?;
        final Timestamp? syncedTs =
            (liveData[FirestoreUserFields.lastSyncedAt] as Timestamp?) ??
            (data[FirestoreUserFields.lastSyncedAt] as Timestamp?);

        final double hourlyRate =
            (liveData[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
            (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
            0.0;

        final double totalPoints =
            (liveData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            (data[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            0.0;

        final double rateBase =
            (liveData[FirestoreUserFields.rateBase] as num?)?.toDouble() ?? 0.0;
        final double rateStreak =
            (liveData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
            0.0;
        final double rateRank =
            (liveData[FirestoreUserFields.rateRank] as num?)?.toDouble() ?? 0.0;
        final double rateReferral =
            (liveData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
            0.0;
        final double rateManager =
            (liveData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
            0.0;
        final double rateAds =
            (liveData[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;
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

    final result = await FirestoreHelper.instance.runTransaction((
      transaction,
    ) async {
      // NOTE: We do NOT read userRef inside transaction to save a read.
      // We rely on UserService cache (5s freshness).
      // This means we might calculate based on slightly stale hourlyRate,
      // and we read the latest user doc inside the transaction.
      final userSnapTx = await transaction.get(userRef);
      final liveData = userSnapTx.data() ?? {};

      final Timestamp? startTs =
          data[FirestoreUserFields.lastMiningStart] as Timestamp?;
      final Timestamp? endTs =
          data[FirestoreUserFields.lastMiningEnd] as Timestamp?;

      // Prefer latest transaction read for syncedAt, fallback to pre-read user doc
      final Timestamp? syncedTs =
          (liveData[FirestoreUserFields.lastSyncedAt] as Timestamp?) ??
          (data[FirestoreUserFields.lastSyncedAt] as Timestamp?);

      // Prefer latest transaction read for hourlyRate, fallback to user doc
      final double hourlyRate =
          (liveData[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          0.0;

      // Prefer latest transaction read for managedCoinSelections, fallback to user doc
      final List<String> managedCoinSelections =
          (liveData[FirestoreUserFields.managedCoinSelections] as List?)
              ?.cast<String>() ??
          (data[FirestoreUserFields.managedCoinSelections] as List?)
              ?.cast<String>() ??
          [];

      // Prefer latest transaction read for managerBonusPerHour, fallback to user doc
      final double managerBonusPerHour =
          (liveData[FirestoreUserFields.managerBonusPerHour] as num?)
              ?.toDouble() ??
          (data[FirestoreUserFields.managerBonusPerHour] as num?)?.toDouble() ??
          0.0;

      // Read Rate Components from latest transaction doc
      final double rateBase =
          (liveData[FirestoreUserFields.rateBase] as num?)?.toDouble() ?? 0.0;
      final double rateStreak =
          (liveData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
      final double rateRank =
          (liveData[FirestoreUserFields.rateRank] as num?)?.toDouble() ?? 0.0;
      final double rateReferral =
          (liveData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
          0.0;
      final double rateManager =
          (liveData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
          0.0;
      final double rateAds =
          (liveData[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;

      // Check if migration is needed
      final bool needsMigration =
          (!liveData.containsKey(FirestoreUserFields.hourlyRate) &&
              data.containsKey(FirestoreUserFields.hourlyRate)) ||
          (!liveData.containsKey(FirestoreUserFields.managedCoinSelections) &&
              data.containsKey(FirestoreUserFields.managedCoinSelections)) ||
          (!liveData.containsKey(FirestoreUserFields.managerBonusPerHour) &&
              data.containsKey(FirestoreUserFields.managerBonusPerHour));

      // Prefer latest transaction read for totalPoints, fallback to pre-read user doc
      double totalPoints =
          (liveData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
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

      // Write directly to unified user document
      final Map<String, dynamic> writeData = {
        // Use explicit set instead of increment to ensure base is correct if migrating
        FirestoreUserFields.totalPoints: totalPoints + earned,
        FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(effectiveEnd),
        FirestoreUserFields.hourlyRate: hourlyRate,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.managedCoinSelections: managedCoinSelections,
        FirestoreUserFields.rateBase: rateBase,
        FirestoreUserFields.rateStreak: rateStreak,
        FirestoreUserFields.rateRank: rateRank,
        FirestoreUserFields.rateReferral: rateReferral,
        FirestoreUserFields.rateManager: rateManager,
        FirestoreUserFields.rateAds: rateAds,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      };
      transaction.set(userRef, writeData, SetOptions(merge: true));

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

  /// Boosts the hourly rate by a specific amount (Ad Reward).
  /// Updates rateAds and hourlyRate in Firestore.
  static Future<double> boostAdRate({
    required String uid,
    required double boostAmount,
  }) async {
    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    final logRef = FirestoreHelper.instance
        .collection(FirestoreConstants.pointLogs)
        .doc();

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

      transaction.set(logRef, {
        FirestorePointLogFields.userId: uid,
        FirestorePointLogFields.type:
            FirestorePointLogTypes.bonus, // Or create a new type if needed
        FirestorePointLogFields.amount:
            0, // Rate boost doesn't give immediate points
        FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
        FirestorePointLogFields.description: 'Ad Reward: Rate +$boostAmount/hr',
      });

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
    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);

    // Get App Config for Base Rate
    final appConfig = await ConfigService().getGeneralConfig();
    final double baseRate =
        (appConfig[FirestoreAppConfigFields.baseRate] as num?)?.toDouble() ??
        0.2;

    return FirestoreHelper.instance.runTransaction((transaction) async {
      // Fetch user data inside transaction to ensure consistency
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) return {};
      final userData = userSnap.data()!;

      // 1. Base Rate
      // baseRate is already fetched

      // 2. Rank Bonus (Builder=1.2x, Guardian=1.5x)
      final String rank =
          (userData[FirestoreUserFields.rank] as String?) ??
          FirestoreUserRanks.explorer;
      double rankMultiplier = 1.0;
      if (rank == FirestoreUserRanks.builder) rankMultiplier = 1.2;
      if (rank == FirestoreUserRanks.guardian) rankMultiplier = 1.5;

      // The "bonus" from rank is (Multiplier - 1.0) * BaseRate?
      // Or is it applied to the final?
      // Convention: Rate = Base + Streak + Referrals + Manager + Ads.
      // Rank usually multiplies Base.
      // Let's define: RateRank = Base * (Multiplier - 1).
      final double rateRank = baseRate * (rankMultiplier - 1.0);

      // 3. Streak Bonus
      // Fetch streak config
      // final streakConfig = await ConfigService().getStreakConfig();
      // final double maxStreakMult = ... (unused)

      // Linear interpolation? Or just based on days?
      // For now, let's assume simplistic: (days / 30) * Base.
      // TODO: Use actual streak logic if complex.
      // Existing logic used: Base * (1 + 0.1 * days)?
      // Let's look at legacy code or assume 0 for now if not defined.
      final int streakDays =
          (userData[FirestoreUserFields.streakDays] as int?) ?? 0;
      // Cap streak days?
      final double rateStreak = (streakDays > 0)
          ? (baseRate * 0.05 * streakDays)
          : 0.0;
      // Cap at maxStreakMult * Base (Total) => Bonus is (Max - 1) * Base
      // This is a placeholder for actual streak logic.

      // 4. Referral Bonus
      final refConfig = await ConfigService().getReferralConfig();
      double perRef =
          (refConfig[FirestoreReferralConfigFields.referrerPercentPerReferral]
                  as num?)
              ?.toDouble() ??
          0.25; // 25% of base

      // Normalize: If value is > 1.0 (e.g. 25), treat as percentage (0.25)
      // This handles Admin Dashboard inputs like "25" for 25%.
      if (perRef > 1.0) {
        perRef = perRef / 100.0;
      }

      // Strict Logic: Cap referral count
      final int maxRefs =
          (refConfig[FirestoreReferralConfigFields.referrerMaxCount] as num?)
              ?.toInt() ??
          0;

      // Strict Logic: Max total bonus rate (from General Config)
      final double maxBonusRate =
          (appConfig[FirestoreAppConfigFields.maxReferralBonusRate] as num?)
              ?.toDouble() ??
          0.0;

      double rateReferral = 0.0;
      if (activeReferralCount != null) {
        int effectiveCount = activeReferralCount;
        if (maxRefs > 0 && effectiveCount > maxRefs) {
          effectiveCount = maxRefs;
        }
        // Calculate based on normalized perRef
        rateReferral = effectiveCount * perRef * baseRate;
      } else {
        // Fallback: Use existing rate from unified user document
        rateReferral =
            (userData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
            0.0;
      }

      // Apply Global Cap if set
      if (maxBonusRate > 0.0 && rateReferral > maxBonusRate) {
        rateReferral = maxBonusRate;
      }

      // 5. Manager Bonus
      double rateManager = 0.0;
      double managerBonusPerHour = 0.0;
      List<String> managedCoinSelections = [];
      final bool managerEnabled =
          (userData[FirestoreUserFields.managerEnabled] as bool?) ?? false;
      final String? activeManagerId =
          userData[FirestoreUserFields.activeManagerId] as String?;

      if (managerEnabled && activeManagerId != null) {
        Map<String, dynamic> managerData = {};
        if (cachedManagerId == activeManagerId && cachedManagerData != null) {
          managerData = cachedManagerData;
        } else {
          final mgrSnap = await FirestoreHelper.instance
              .collection(FirestoreConstants.managers)
              .doc(activeManagerId)
              .get();
          managerData = mgrSnap.data() ?? {};
        }

        final double mgrMult =
            (managerData[FirestoreManagerFields.managerMultiplier] as num?)
                ?.toDouble() ??
            1.0;
        // Manager bonus is applied to (Base + Rank + Streak)?
        // Or just Base?
        // Let's assume it adds (Multiplier - 1) * Base.
        rateManager = baseRate * (mgrMult - 1.0);

        managerBonusPerHour =
            (managerData[FirestoreManagerFields.maxCommunityCoinsManaged]
                    as num?)
                ?.toDouble() ??
            0.0;

        // Auto-select coins if enabled
        final bool autoCoin =
            (managerData[FirestoreManagerFields.enableUserCoinAuto] as bool?) ??
            false;
        if (autoCoin) {
          // Logic to select coins?
          // Placeholder.
        }
      }

      // 6. Ad Bonus (Preserve existing)
      final double rateAds =
          (userData[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;

      // Total
      final double newHourlyRate =
          baseRate +
          rateRank +
          rateStreak +
          rateReferral +
          rateManager +
          rateAds;

      transaction.set(userRef, {
        FirestoreUserFields.rateBase: baseRate,
        FirestoreUserFields.rateRank: rateRank,
        FirestoreUserFields.rateStreak: rateStreak,
        FirestoreUserFields.rateReferral: rateReferral,
        FirestoreUserFields.rateManager: rateManager,
        FirestoreUserFields.rateAds: rateAds,
        FirestoreUserFields.hourlyRate: newHourlyRate,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        if (managedCoinSelections.isNotEmpty)
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update main user doc for redundancy/display?
      // Prefer keeping it in realtime to reduce writes.
      // But if we want 'hourlyRate' to be visible in admin panel on user doc:
      // OPTIMIZATION: Removed redundant write to userRef to save costs.
      // Admin panel should read from realtime subcollection or aggregate queries.
      /*
      transaction.update(userRef, {
        FirestoreUserFields.hourlyRate: newHourlyRate,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      });
      */

      return {
        FirestoreUserFields.rateBase: baseRate,
        FirestoreUserFields.rateRank: rateRank,
        FirestoreUserFields.rateStreak: rateStreak,
        FirestoreUserFields.rateReferral: rateReferral,
        FirestoreUserFields.rateManager: rateManager,
        FirestoreUserFields.rateAds: rateAds,
        FirestoreUserFields.hourlyRate: newHourlyRate,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.managedCoinSelections: managedCoinSelections,
      };
    });
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
