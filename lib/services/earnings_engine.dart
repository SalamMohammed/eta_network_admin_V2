import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/firestore_constants.dart';
import '../shared/constants.dart';
import 'rank_engine.dart';
import 'config_service.dart';
import 'user_service.dart';

class EarningsEngine {
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

    return FirebaseFirestore.instance.runTransaction((transaction) async {
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

      final double hourlyRate =
          (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

      // Prefer realtime doc for totalPoints, fallback to user doc
      double totalPoints =
          (realtimeData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
          (data[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
          0.0;

      if (startTs == null) {
        return {
          FirestoreUserFields.totalPoints: totalPoints,
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          'userData': data,
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
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          'userData': data,
        };
      }
      final elapsedHours =
          effectiveEnd.difference(from).inMilliseconds / (1000 * 60 * 60);
      final earned = elapsedHours * hourlyRate;

      // Throttle writes: only write if > 0.1 points or > 10 minutes elapsed
      // This reduces excessive Cloud Function invocations
      final diffMinutes = effectiveEnd.difference(from).inMinutes;
      if (earned <= 0 || (earned < 0.1 && diffMinutes < 10)) {
        return {
          FirestoreUserFields.totalPoints:
              totalPoints + earned, // Return calculated total for UI
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(
            from,
          ), // Keep old sync time
          'userData': data,
        };
      }

      // Write to realtime subcollection INSTEAD of main user doc
      transaction.set(realtimeRef, {
        FirestoreUserFields.totalPoints: FieldValue.increment(earned),
        FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(effectiveEnd),
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final newLogDoc = pointLogsRef.doc();
      transaction.set(newLogDoc, {
        FirestorePointLogFields.userId: uid,
        FirestorePointLogFields.type: FirestorePointLogTypes.tap,
        FirestorePointLogFields.amount: earned,
        FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
        FirestorePointLogFields.description: 'Session earnings',
      });

      return {
        FirestoreUserFields.totalPoints: (totalPoints + earned),
        FirestoreUserFields.hourlyRate: hourlyRate,
        FirestoreUserFields.lastMiningStart: startTs,
        FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(effectiveEnd),
        FirestoreUserFields.lastMiningEnd: endTs,
        'userData': data,
      };
    });
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
            (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0,
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
    final int newStreakDays = streakRes['streakDays'];
    final int? streakLastUpdatedDay = streakRes['streakLastUpdatedDay'];
    final bool streakIncremented = streakRes['incremented'];

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

    debugPrint(
      'EarningsEngine: rate calc → baseRate=${baseRate.toStringAsFixed(6)}, sessionHours=$sessionHours',
    );
    debugPrint(
      'EarningsEngine: streak → days=$newStreakDays, multiplier=${streakMultiplier.toStringAsFixed(6)}',
    );
    debugPrint(
      'EarningsEngine: rank → name=$bestRank, multiplier=${rankMultiplier.toStringAsFixed(6)}',
    );
    debugPrint('EarningsEngine: referrals → count=$referralCount');

    final double streakFrac = (streakMultiplier - 1.0).clamp(0.0, 1000.0);
    final double rankFrac = (rankMultiplier - 1.0).clamp(0.0, 1000.0);
    final double referralFrac = (referralMultiplier - 1.0).clamp(0.0, 1000.0);
    final double streakBonus = baseRate * streakFrac;
    final double rankBonus = baseRate * rankFrac;
    final double referralBonus = baseRate * referralFrac;
    final double hourlyRate =
        baseRate + streakBonus + rankBonus + referralBonus;

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
      FirestoreUserFields.hourlyRate: hourlyRate,
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

    batch.set(realtimeRef, {
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(start),
    }, SetOptions(merge: true));

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
      'debug': {
        'baseRate': baseRate,
        'streakBonus': streakBonus,
        'rankBonus': rankBonus,
        'referralBonus': referralBonus,
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

  static Future<void> migrateLegacyPoints({
    required String uid,
    required double legacyPoints,
  }) async {
    if (legacyPoints <= 0) return;
    final realtimeRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime);

    // Check if migration is needed (only if doc doesn't exist)
    final snap = await realtimeRef.get();
    if (snap.exists) return;

    await realtimeRef.set({
      FirestoreUserFields.totalPoints: legacyPoints,
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
    });
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
      'streakDays': updated,
      'streakLastUpdatedDay': incremented ? todayInt : lastUpdatedDay,
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
          ((FirestoreAppConfigFields.referralBonusStep != '')
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

  static Future<double> _referralMultiplier(int count) async {
    final cfgSnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.referrals)
        .get();
    final cfg = cfgSnap.data() ?? {};
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
      debugPrint(
        'EarningsEngine: referral tiers → count=$count, effective=$effective, threshold<$thresholdForLog, percentPerReferralRaw=${percentPerReferralRaw.toStringAsFixed(6)}',
      );
    } else {
      percentPerReferralRaw =
          (cfg[FirestoreReferralConfigFields.referrerPercentPerReferral]
                  as num?)
              ?.toDouble() ??
          ((FirestoreAppConfigFields.referralBonusStep != '')
              ? (cfg[FirestoreAppConfigFields.referralBonusStep] as num?)
                        ?.toDouble() ??
                    0.0
              : 0.0);
      debugPrint(
        'EarningsEngine: referral legacy config → percentPerReferralRaw=${percentPerReferralRaw.toStringAsFixed(6)}',
      );
    }

    final double percentPerReferral = (percentPerReferralRaw <= 0.0)
        ? 0.0
        : (percentPerReferralRaw / 100.0);
    final double totalPercent = percentPerReferral * effective;
    final double out = 1.0 + totalPercent;
    debugPrint(
      'EarningsEngine: referral config → effective=$effective, percentPerReferralRaw=${percentPerReferralRaw.toStringAsFixed(6)}, totalPercent=${totalPercent.toStringAsFixed(6)}, maxCount=$maxCount',
    );
    debugPrint(
      'EarningsEngine: referral calc → effectiveCount=$effective, multiplier=${out.toStringAsFixed(6)}',
    );
    return out;
  }
}
