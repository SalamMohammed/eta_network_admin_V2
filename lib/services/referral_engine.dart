import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/firestore_constants.dart';

class ReferralEngine {
  static Future<void> processReferralOnSignup({
    required String uid,
    String? referralCode,
    String? inviteeEmail,
    String? inviteeUsername,
  }) async {
    if (referralCode == null || referralCode.isEmpty) return;
    final users = FirebaseFirestore.instance.collection(
      FirestoreConstants.users,
    );
    final qs = await users
        .where(FirestoreUserFields.referralCode, isEqualTo: referralCode)
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return;
    final inviterUid = qs.docs.first.id;
    if (inviterUid == uid) return;

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

    final cfgRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.referrals);
    final cfgSnap = await cfgRef.get();
    final cfg = cfgSnap.data() ?? {};
    final double inviteeFixedBonus =
        (cfg[FirestoreReferralConfigFields.inviteeFixedBonusPoints] as num?)
            ?.toDouble() ??
        (cfg[FirestoreReferralConfigFields.inviteeBonus] as num?)?.toDouble() ??
        0.0;

    final batch = FirebaseFirestore.instance.batch();
    final referralsCol = FirebaseFirestore.instance.collection(
      FirestoreConstants.referrals,
    );
    final referralDoc = referralsCol.doc();

    batch.update(inviteeRef, {
      FirestoreUserFields.invitedBy: inviterUid,
      FirestoreUserFields.referralLocked: true,
    });
    batch.set(referralDoc, {
      FirestoreReferralFields.inviterId: inviterUid,
      FirestoreReferralFields.inviteeId: uid,
      FirestoreReferralFields.timestamp: FieldValue.serverTimestamp(),
      FirestoreReferralFields.isActive: true,
      if (inviteeUsername != null)
        FirestoreReferralFields.inviteeUsername: inviteeUsername,
    });

    final points = FirebaseFirestore.instance.collection(
      FirestoreConstants.pointLogs,
    );
    final inviteeLog = points.doc();
    batch.set(inviteeLog, {
      FirestorePointLogFields.userId: uid,
      FirestorePointLogFields.type: FirestorePointLogTypes.referral,
      FirestorePointLogFields.amount: inviteeFixedBonus,
      FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
      FirestorePointLogFields.description: 'Referral fixed bonus applied',
    });

    // Update points in realtime subcollection to avoid triggering user doc listeners
    final realtimeRef = inviteeRef
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime);
        
    batch.set(realtimeRef, {
      FirestoreUserFields.totalPoints: FieldValue.increment(inviteeFixedBonus),
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  static Future<void> processReferralOnProfile({
    required String uid,
    required String referralCode,
  }) async {
    await processReferralOnSignup(uid: uid, referralCode: referralCode);
  }
}
