import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/firestore_constants.dart';

class RankEngine {
  static Future<void> updateUserRank(String uid) async {
    final users = FirebaseFirestore.instance.collection(
      FirestoreConstants.users,
    );
    final userRef = users.doc(uid);
    final userSnap = await userRef.get();
    if (!userSnap.exists) return;
    final data = userSnap.data() ?? {};
    final int streakDays =
        (data[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;

    final referralsQ = await FirebaseFirestore.instance
        .collection(FirestoreConstants.referrals)
        .where(FirestoreReferralFields.inviterId, isEqualTo: uid)
        .where(FirestoreReferralFields.isActive, isEqualTo: true)
        .count()
        .get();
    final int activeReferrals = referralsQ.count ?? 0;

    final cfgSnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.ranks)
        .get();
    final cfg = cfgSnap.data() ?? {};
    final Map<String, dynamic> rules =
        (cfg[FirestoreRankConfigFields.rankRules] as Map<String, dynamic>?) ??
        {};
    final Map<String, dynamic> mults =
        (cfg[FirestoreRankConfigFields.rankMultipliers]
            as Map<String, dynamic>?) ??
        {};

    String bestRank = (data[FirestoreUserFields.rank] as String?) ?? 'Explorer';
    double bestMult = (mults[bestRank] as num?)?.toDouble() ?? 1.0;

    final List<String> ranks = rules.keys.toList();
    ranks.sort((a, b) {
      final double ma = (mults[a] as num?)?.toDouble() ?? 1.0;
      final double mb = (mults[b] as num?)?.toDouble() ?? 1.0;
      return ma.compareTo(mb);
    });

    for (final r in ranks) {
      final Map<String, dynamic> rule =
          (rules[r] as Map<String, dynamic>?) ?? {};
      final int minRefs = (rule['minActiveReferrals'] as num?)?.toInt() ?? 0;
      final int minStreak = (rule['minStreakDays'] as num?)?.toInt() ?? 0;
      if (activeReferrals >= minRefs && streakDays >= minStreak) {
        final double m = (mults[r] as num?)?.toDouble() ?? 1.0;
        if (m >= bestMult) {
          bestRank = r;
          bestMult = m;
        }
      }
    }

    final String currentRank =
        (data[FirestoreUserFields.rank] as String?) ?? '';
    if (bestRank != currentRank) {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(userRef, {
        FirestoreUserFields.rank: bestRank,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      });
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
      await batch.commit();
    }
  }

  static Future<void> updateAllRanksPaged({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query q = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .orderBy(FirestoreUserFields.createdAt)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final qs = await q.get();
    for (final d in qs.docs) {
      await updateUserRank(d.id);
    }
  }
}
