import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/firestore_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinService {
  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserCoin(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.userCoins)
        .doc(uid)
        .get();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserCoin(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.userCoins)
        .doc(uid)
        .snapshots();
  }

  static Future<Map<String, dynamic>> getUserCoinConfig() async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.userCoin)
        .get();
    return snap.data() ?? {};
  }

  static Future<void> createOrUpdateUserCoin({
    required String uid,
    required Map<String, dynamic> coin,
    bool merge = false,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection(FirestoreConstants.userCoins)
        .doc(uid);
    await ref.set(coin, SetOptions(merge: merge));
  }

  static Future<void> addCoinForUser(String coinOwnerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || coinOwnerId.isEmpty) return;
    final coinSnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.userCoins)
        .doc(coinOwnerId)
        .get();
    final coin = coinSnap.data() ?? {};
    final double rate =
        (coin[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
        0.0;
    final name = (coin[FirestoreUserCoinFields.name] as String?) ?? '';
    final symbol = (coin[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final imageUrl = (coin[FirestoreUserCoinFields.imageUrl] as String?) ?? '';

    final ref = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .doc(coinOwnerId);
    final existing = await ref.get();
    final data = existing.data() ?? {};
    await ref.set({
      FirestoreUserCoinMiningFields.ownerId: coinOwnerId,
      FirestoreUserCoinMiningFields.name: name,
      FirestoreUserCoinMiningFields.symbol: symbol,
      FirestoreUserCoinMiningFields.imageUrl: imageUrl,
      FirestoreUserCoinMiningFields.hourlyRate: rate,
      FirestoreUserCoinMiningFields.totalPoints:
          (data[FirestoreUserCoinMiningFields.totalPoints] as num?)
              ?.toDouble() ??
          0.0,
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>> startCoinMining(
    String coinOwnerId,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final now = DateTime.now();
    final general = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.general)
        .get();
    final g = general.data() ?? {};
    final int hours =
        (g[FirestoreAppConfigFields.sessionDurationHours] as num?)?.toInt() ??
        24;
    final end = Timestamp.fromDate(now.add(Duration(hours: hours)));
    final coinSnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.userCoins)
        .doc(coinOwnerId)
        .get();
    final coin = coinSnap.data() ?? {};
    final double rate =
        (coin[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
        0.0;
    final name = (coin[FirestoreUserCoinFields.name] as String?) ?? '';
    final symbol = (coin[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final imageUrl = (coin[FirestoreUserCoinFields.imageUrl] as String?) ?? '';

    final ref = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .doc(coinOwnerId);
    final existing = await ref.get();
    final data = existing.data() ?? {};
    final lastEnd =
        data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
    if (lastEnd != null && DateTime.now().isBefore(lastEnd.toDate())) {
      return data;
    }
    final batch = FirebaseFirestore.instance.batch();
    batch.set(ref, {
      FirestoreUserCoinMiningFields.ownerId: coinOwnerId,
      FirestoreUserCoinMiningFields.name: name,
      FirestoreUserCoinMiningFields.symbol: symbol,
      FirestoreUserCoinMiningFields.imageUrl: imageUrl,
      FirestoreUserCoinMiningFields.hourlyRate: rate,
      FirestoreUserCoinMiningFields.lastMiningStart: Timestamp.fromDate(now),
      FirestoreUserCoinMiningFields.lastMiningEnd: end,
      FirestoreUserCoinMiningFields.lastSyncedAt: Timestamp.fromDate(now),
      FirestoreUserCoinMiningFields.totalPoints:
          (data[FirestoreUserCoinMiningFields.totalPoints] as num?)
              ?.toDouble() ??
          0.0,
    }, SetOptions(merge: true));
    await batch.commit();
    final updated = await ref.get();
    return updated.data() ?? {};
  }

  static Future<void> syncCoinEarnings(String coinOwnerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .doc(coinOwnerId);
    final snap = await ref.get();
    final d = snap.data() ?? {};
    final rate =
        (d[FirestoreUserCoinMiningFields.hourlyRate] as num?)?.toDouble() ??
        0.0;
    final start =
        d[FirestoreUserCoinMiningFields.lastMiningStart] as Timestamp?;
    final synced = d[FirestoreUserCoinMiningFields.lastSyncedAt] as Timestamp?;
    final end = d[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
    if (start == null || end == null) return;
    final now = DateTime.now();
    final s = (synced ?? start).toDate();
    final e = end.toDate();
    final until = now.isBefore(e) ? now : e;
    final elapsed = until.difference(s).inSeconds.toDouble();
    final inc = (elapsed / 3600.0) * rate;
    if (inc <= 0) return;
    await ref.update({
      FirestoreUserCoinMiningFields.totalPoints: FieldValue.increment(inc),
      FirestoreUserCoinMiningFields.lastSyncedAt: Timestamp.fromDate(until),
    });
  }
}
