import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../shared/firestore_constants.dart';
import '../utils/firestore_helper.dart';
import 'config_service.dart';

class ReferralEngine {
  static Future<void> processReferralOnSignup({
    required String uid,
    String? referralCode,
    String? inviteeEmail,
    String? inviteeUsername,
  }) async {
    debugPrint('DEBUG: Processing referral for $uid with code $referralCode');
    if (referralCode == null || referralCode.isEmpty) return;
    try {
      final users = FirestoreHelper.instance.collection(
        FirestoreConstants.users,
      );
      final qs = await users
          .where(FirestoreUserFields.referralCode, isEqualTo: referralCode)
          .limit(1)
          .get();
      if (qs.docs.isEmpty) return;
      final inviterUid = qs.docs.first.id;
      if (inviterUid == uid) return;
      final inviterRef = users.doc(inviterUid);

      final inviteeRef = users.doc(uid);
      final inviteeSnap = await inviteeRef.get();
      final inviteeData = inviteeSnap.data() ?? {};
      final bool locked =
          (inviteeData[FirestoreUserFields.referralLocked] as bool?) ?? false;
      final String? alreadyInvitedBy =
          inviteeData[FirestoreUserFields.invitedBy] as String?;
      if (locked || (alreadyInvitedBy != null && alreadyInvitedBy.isNotEmpty)) {
        return;
      }

      final cfg = await ConfigService().getReferralConfig();
      final double inviteeFixedBonus =
          (cfg[FirestoreReferralConfigFields.inviteeFixedBonusPoints] as num?)
              ?.toDouble() ??
          (cfg[FirestoreReferralConfigFields.inviteeBonus] as num?)
              ?.toDouble() ??
          0.0;

      final batch = FirestoreHelper.instance.batch();

      batch.update(inviteeRef, {
        '${FirestoreUserFields.stats}.${FirestoreUserFields.invitedBy}':
            inviterUid,
        '${FirestoreUserFields.stats}.${FirestoreUserFields.referralLocked}':
            true,
        // Fallback for legacy (optional, but good for Phase 2 compatibility)
        FirestoreUserFields.invitedBy: inviterUid,
        FirestoreUserFields.referralLocked: true,
      });

      // Update Inviter's consolidated referral stats
      final referralSummary = {
        'uid': uid,
        'username': inviteeUsername ?? 'Anonymous',
        'timestamp': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      batch.update(inviterRef, {
        '${FirestoreUserFields.referrals}.${FirestoreUserFields.totalReferrals}':
            FieldValue.increment(1),
        '${FirestoreUserFields.referrals}.${FirestoreUserFields.activeReferrals}':
            FieldValue.increment(1),
        '${FirestoreUserFields.referrals}.${FirestoreUserFields.recentReferrals}':
            FieldValue.arrayUnion([referralSummary]),
      });

      // Update points directly on unified user document
      batch.set(inviteeRef, {
        FirestoreUserFields.totalPoints: FieldValue.increment(
          inviteeFixedBonus,
        ),
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final referralMetaRef = inviteeRef
          .collection(FirestoreUserSubCollections.referralMeta)
          .doc(FirestoreUserReferralMetaDocs.invitedBy);
      batch.set(referralMetaRef, {
        FirestoreReferralFields.inviterId: inviterUid,
        'source': 'signup',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));

      await batch.commit();
      debugPrint('DEBUG: Referral batch committed successfully.');
    } catch (e) {
      debugPrint('DEBUG: Referral processing failed: $e');
      // Don't rethrow, as referral failure shouldn't block signup
    }
  }

  static Future<void> processReferralOnProfile({
    required String uid,
    required String referralCode,
  }) async {
    await processReferralOnSignup(uid: uid, referralCode: referralCode);
  }
}
