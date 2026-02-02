import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/firestore_constants.dart';
import '../shared/constants.dart';
import 'rank_engine.dart';

class EarningsEngine {
  static Future<Map<String, dynamic>> syncEarnings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final userRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    // Realtime earnings subcollection
    final realtimeRef = userRef
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime);

    final snap = await userRef.get();
    if (!snap.exists) return {};
    final data = snap.data() ?? {};

    final realtimeSnap = await realtimeRef.get();
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
      };
    }

    // Write to realtime subcollection INSTEAD of main user doc
    await realtimeRef.set({
      FirestoreUserFields.totalPoints: FieldValue.increment(earned),
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(effectiveEnd),
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection(FirestoreConstants.pointLogs)
        .add({
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
    };
  }

  static Future<Map<String, dynamic>> startMining({
    String? deviceId,
    DateTime? maxEnd,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    await syncEarnings();
    final userRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    // Realtime earnings subcollection
    final realtimeRef = userRef
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime);

    final snap = await userRef.get();
    final data = snap.data() ?? {};

    final realtimeSnap = await realtimeRef.get();
    final realtimeData = realtimeSnap.data() ?? {};

    final bool isBanned = (data['isBanned'] as bool?) ?? false;
    if (isBanned) {
      throw Exception('User banned');
    }
    final Timestamp? lastEndTs =
        data[FirestoreUserFields.lastMiningEnd] as Timestamp?;
    final DateTime now = DateTime.now();

    // Prefer realtime doc for totalPoints
    double totalPoints =
        (realtimeData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
        (data[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
        0.0;

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
    // Enforce single account per device if enabled
    final cfgRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.general);
    final cfgSnap = await cfgRef.get();
    final cfg = cfgSnap.data() ?? {};
    final bool enforceSingleDevice =
        (cfg[FirestoreAppConfigFields.deviceSingleUserEnforced] as bool?) ??
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

    // Update streak before calculating rate (only if no active session)
    final int newStreakDays = await _computeAndPersistStreak(userRef, data);

    // cfg already loaded above
    final streakCfgSnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.streak)
        .get();
    final streakCfg = streakCfgSnap.data() ?? {};
    final ranksCfgSnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.ranks)
        .get();
    final ranksCfg = ranksCfgSnap.data() ?? {};
    await RankEngine.updateUserRank(uid);
    final afterRankSnap = await userRef.get();
    final afterRankData = afterRankSnap.data() ?? {};
    final double baseRate =
        (cfg[FirestoreAppConfigFields.baseRate] as num?)?.toDouble() ?? 0.2;
    final double sessionHours =
        (cfg[FirestoreAppConfigFields.sessionDurationHours] as num?)
            ?.toDouble() ??
        24.0;
    final double streakMultiplier = _streakMultiplier(newStreakDays, streakCfg);
    final double rankMultiplier = _rankMultiplierByName(
      (afterRankData[FirestoreUserFields.rank] as String?) ?? '',
      ranksCfg,
    );
    debugPrint(
      'EarningsEngine: rate calc → baseRate=${baseRate.toStringAsFixed(6)}, sessionHours=$sessionHours',
    );
    debugPrint(
      'EarningsEngine: streak → days=$newStreakDays, multiplier=${streakMultiplier.toStringAsFixed(6)}',
    );
    debugPrint(
      'EarningsEngine: rank → name=${(afterRankData[FirestoreUserFields.rank] as String?) ?? ''}, multiplier=${rankMultiplier.toStringAsFixed(6)}',
    );
    final statsSnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.referralStats)
        .doc(uid)
        .get();
    final statsData = statsSnap.data() ?? {};
    final int referralCount =
        (statsData['active48hCount'] as num?)?.toInt() ?? 0;
    debugPrint('EarningsEngine: referrals → count=$referralCount');
    final double referralMultiplier = await _referralMultiplier(referralCount);
    final double streakFrac = (streakMultiplier - 1.0).clamp(0.0, 1000.0);
    final double rankFrac = (rankMultiplier - 1.0).clamp(0.0, 1000.0);
    final double referralFrac = (referralMultiplier - 1.0).clamp(0.0, 1000.0);
    final double streakBonus = baseRate * streakFrac;
    final double rankBonus = baseRate * rankFrac;
    final double referralBonus = baseRate * referralFrac;
    debugPrint(
      'EarningsEngine: referrals → multiplier=${referralMultiplier.toStringAsFixed(6)} (fraction ${(referralFrac * 100).toStringAsFixed(2)}%)',
    );
    debugPrint(
      'EarningsEngine: additive breakdown → baseRate=${baseRate.toStringAsFixed(6)}, streakBonus=${streakBonus.toStringAsFixed(6)} (+${(streakFrac * 100).toStringAsFixed(2)}%), rankBonus=${rankBonus.toStringAsFixed(6)} (+${(rankFrac * 100).toStringAsFixed(2)}%), referralBonus=${referralBonus.toStringAsFixed(6)} (+${(referralFrac * 100).toStringAsFixed(2)}%)',
    );
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

    // 1. Update User Doc (Triggers Cloud Function)
    await userRef.update({
      FirestoreUserFields.hourlyRate: hourlyRate,
      FirestoreUserFields.lastMiningStart: Timestamp.fromDate(start),
      FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(end),
      // FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(start), // MOVED to realtime
      FirestoreUserFields.deviceId: deviceId,
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreUserFields.streakDays: newStreakDays,
      FirestoreUserFields.totalSessions: FieldValue.increment(1),
    });

    // 2. Update Realtime Doc (No Trigger)
    await realtimeRef.set({
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(start),
    }, SetOptions(merge: true));

    // First-session referral activation: if configured, activate and award bonuses once.
    final refCfgSnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.referrals)
        .get();
    final refCfg = refCfgSnap.data() ?? {};
    final bool activateOnFirstSession =
        (refCfg[FirestoreReferralConfigFields.activateOnFirstSession]
            as bool?) ??
        false;
    if (activateOnFirstSession) {
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
          // Inviter Realtime Ref
          final inviterRealtimeRef = inviterRef
              .collection(FirestoreUserSubCollections.earnings)
              .doc(FirestoreEarningsDocs.realtime);

          final inviteeRef = users.doc(uid);
          // Invitee Realtime Ref (already have realtimeRef for current user)

          final points = FirebaseFirestore.instance.collection(
            FirestoreConstants.pointLogs,
          );
          final inviterLog = points.doc();
          final inviteeLog = points.doc();
          batch.update(referralsDocRef, {
            FirestoreReferralFields.isActive: true,
          });
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

          // Update Inviter Points in Realtime Doc
          batch.set(inviterRealtimeRef, {
            FirestoreUserFields.totalPoints: FieldValue.increment(
              referrerBonus,
            ),
          }, SetOptions(merge: true));

          // Update Invitee Points in Realtime Doc
          batch.set(realtimeRef, {
            FirestoreUserFields.totalPoints: FieldValue.increment(inviteeBonus),
          }, SetOptions(merge: true));

          await batch.commit();
          await RankEngine.updateUserRank(inviterUid);
          await RankEngine.updateUserRank(uid);
        }
      }
    }
    final refreshed = await userRef.get();
    final out = refreshed.data() ?? {};

    // Need refreshed realtime data too?
    // We just updated it (maybe).
    // Actually, we can just return what we know.

    // We updated realtimeRef with lastSyncedAt=start.
    // We might have added bonus to realtimeRef.
    // Let's just fetch it to be safe or calculate.
    final refreshedRealtime = await realtimeRef.get();
    final outRealtime = refreshedRealtime.data() ?? {};

    return {
      FirestoreUserFields.hourlyRate: hourlyRate,
      FirestoreUserFields.lastMiningStart: Timestamp.fromDate(start),
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(start),
      FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(end),
      FirestoreUserFields.streakDays:
          (out[FirestoreUserFields.streakDays] as num?)?.toInt() ??
          newStreakDays,
      FirestoreUserFields.totalPoints:
          (outRealtime[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
          totalPoints, // use previous value if read failed? or 0.0
      'debug': {
        'baseRate': baseRate,
        'streakBonus': streakBonus,
        'rankBonus': rankBonus,
        'referralBonus': referralBonus,
        'hourlyRate': hourlyRate,
      },
    };
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

  static Future<int> _computeAndPersistStreak(
    DocumentReference userRef,
    Map<String, dynamic> data,
  ) async {
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

    bool increment = false;
    if (lastEndTs != null) {
      final endUtc = lastEndTs.toDate().toUtc();
      final DateTime d = DateTime.utc(endUtc.year, endUtc.month, endUtc.day);
      final int dInt = d.year * 10000 + d.month * 100 + d.day;
      if (dInt == yesterdayInt) {
        increment = true; // ended yesterday, always increment today
      } else if (dInt == todayInt) {
        increment = (lastUpdatedDay != todayInt); // increment only once per day
      } else {
        increment = false; // missed yesterday → reset to 1 below
      }
    } else {
      increment = false;
    }

    final streakCfgSnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.streak)
        .get();
    final streakCfg = streakCfgSnap.data() ?? {};
    final int maxDays =
        (streakCfg[FirestoreStreakConfigFields.maxStreakDays] as num?)
            ?.toInt() ??
        15;

    int updated = increment ? current + 1 : 1;
    if (updated > maxDays) updated = maxDays;

    final batch = FirebaseFirestore.instance.batch();
    final Map<String, dynamic> updates = {
      FirestoreUserFields.streakDays: updated,
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
    };
    if (updated != current) {
      updates[FirestoreUserFields.streakLastUpdatedDay] = todayInt;
    }
    batch.update(userRef, updates);
    if (increment && updated != current) {
      final logRef = FirebaseFirestore.instance
          .collection(FirestoreConstants.pointLogs)
          .doc();
      batch.set(logRef, {
        FirestorePointLogFields.userId: userRef.id,
        FirestorePointLogFields.type: FirestorePointLogTypes.streak,
        FirestorePointLogFields.amount: 0,
        FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
        FirestorePointLogFields.description: 'Streak updated to $updated days',
      });
    }
    await batch.commit();
    return updated;
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
