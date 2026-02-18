import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/firestore_constants.dart';

import '../utils/firestore_helper.dart';

class RankEngine {
  static Future<void> updateUserRank(String uid) async {
    return;
  }

  static Future<void> updateAllRanksPaged({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    return;
  }

  static String getBestRank({
    required int streakDays,
    required int activeReferrals,
    required Map<String, dynamic> ranksCfg,
    required String currentRank,
  }) {
    final Map<String, dynamic> rules =
        (ranksCfg[FirestoreRankConfigFields.rankRules]
            as Map<String, dynamic>?) ??
        {};
    final Map<String, dynamic> mults =
        (ranksCfg[FirestoreRankConfigFields.rankMultipliers]
            as Map<String, dynamic>?) ??
        {};

    String bestRank = currentRank;
    // If current rank is not in config (or empty), default to Explorer or lowest
    if (!mults.containsKey(bestRank) && mults.isNotEmpty) {
      bestRank = 'Explorer';
    }
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
    return bestRank;
  }
}
