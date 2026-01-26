import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/firestore_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../shared/constants.dart';
import 'sql_api_service.dart'; // Add this import

class CoinService {
  // MASTER SWITCH: Set to true to use SQL, false for Firestore
  static const bool useSqlBackend = true;

  static Future<Map<String, dynamic>?> getUserCoin(String uid) async {
    if (useSqlBackend) {
      return SqlApiService.getUserCoin(uid);
    }
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.userCoins)
        .doc(uid)
        .get();
    return snap.data();
  }

  static Stream<Map<String, dynamic>?> watchUserCoin(String uid) {
    if (useSqlBackend) {
      // Poll every 5 seconds, but emit first value immediately
      Stream<Map<String, dynamic>?> stream() async* {
        // Initial fetch
        yield await SqlApiService.getUserCoin(uid);
        // Periodic polling
        yield* Stream.periodic(
          const Duration(seconds: 5),
        ).asyncMap((_) => SqlApiService.getUserCoin(uid));
      }

      return stream().asBroadcastStream();
    }
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.userCoins)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  static Future<Map<String, dynamic>> getUserCoinConfig() async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.userCoin)
        .get();
    return snap.data() ?? {};
  }

  static Future<void> checkCoinUniqueness({
    String? name,
    String? symbol,
    String? excludeUid,
  }) async {
    // Switch to SQL if enabled
    if (useSqlBackend) {
      return SqlApiService.checkCoinUniqueness(
        name: name,
        symbol: symbol,
        excludeUid: excludeUid ?? '',
      );
    }

    if (name != null && name.isNotEmpty) {
      final q = await FirebaseFirestore.instance
          .collection(FirestoreConstants.userCoins)
          .where(FirestoreUserCoinFields.name, isEqualTo: name)
          .limit(1)
          .get();
      if (q.docs.any((d) => d.id != excludeUid)) {
        throw Exception('Coin name "$name" is already taken.');
      }
    }
    if (symbol != null && symbol.isNotEmpty) {
      final q = await FirebaseFirestore.instance
          .collection(FirestoreConstants.userCoins)
          .where(FirestoreUserCoinFields.symbol, isEqualTo: symbol)
          .limit(1)
          .get();
      if (q.docs.any((d) => d.id != excludeUid)) {
        throw Exception('Coin symbol "$symbol" is already taken.');
      }
    }
  }

  static Future<void> createOrUpdateUserCoin({
    required String uid,
    required Map<String, dynamic> coin,
    bool merge = false,
    Uint8List? thumbnailBytes,
    String? thumbnailContentType,
  }) async {
    await checkCoinUniqueness(
      name: coin[FirestoreUserCoinFields.name] as String?,
      symbol: coin[FirestoreUserCoinFields.symbol] as String?,
      excludeUid: uid,
    );

    try {
      debugPrint(
        '[CoinService] Upload start | uid=$uid | bytes=${thumbnailBytes?.length ?? 0} | ct=$thumbnailContentType | web=$kIsWeb | apps=${Firebase.apps.length}',
      );
      if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
        final r = FirebaseStorage.instance.ref().child(
          'user_coins/$uid/thumbnail',
        );
        await r.putData(
          thumbnailBytes,
          SettableMetadata(contentType: thumbnailContentType ?? 'image/png'),
        );
        final u = await r.getDownloadURL();
        coin[FirestoreUserCoinFields.imageUrl] = u;
        debugPrint('[CoinService] Upload success | url=$u');
      } else {
        debugPrint(
          '[CoinService] No thumbnail bytes provided, skipping upload',
        );
      }
    } catch (e) {
      debugPrint('[CoinService] Upload failed | error=$e');
    }

    // Switch to SQL if enabled
    if (useSqlBackend) {
      try {
        // Create a copy for SQL to avoid modifying the original map
        final sqlCoin = Map<String, dynamic>.from(coin);

        // Ensure ownerId is set
        sqlCoin[FirestoreUserCoinFields.ownerId] = uid;

        // Remove FieldValue objects (like serverTimestamp) which cannot be JSON encoded
        // The PHP script handles createdAt/updatedAt using MySQL NOW()
        sqlCoin.remove(FirestoreUserCoinFields.createdAt);
        sqlCoin.remove(FirestoreUserCoinFields.updatedAt);
        sqlCoin.remove(
          FirestoreUserCoinFields.minersCount,
        ); // If present as FieldValue

        await SqlApiService.createOrUpdateCoin(sqlCoin);
        debugPrint('[CoinService] SQL create/update success');
        return;
      } catch (e) {
        debugPrint('[CoinService] SQL create/update failed | error=$e');
        rethrow;
      }
    }

    final ref = FirebaseFirestore.instance
        .collection(FirestoreConstants.userCoins)
        .doc(uid);
    try {
      await ref.set(coin, SetOptions(merge: merge));
      debugPrint('[CoinService] Firestore set success | merge=$merge');
    } catch (e) {
      debugPrint('[CoinService] Firestore set failed | error=$e');
      rethrow;
    }
  }

  static Future<void> addCoinForUser(String coinOwnerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || coinOwnerId.isEmpty) return;

    // Switch to SQL if enabled
    if (useSqlBackend) {
      try {
        await SqlApiService.addToMyCoins(coinOwnerId);
        return;
      } catch (e) {
        debugPrint('[CoinService] SQL add to my coins failed | error=$e');
        rethrow;
      }
    }

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
    final description =
        (coin[FirestoreUserCoinFields.description] as String?) ?? '';
    final links =
        (coin[FirestoreUserCoinFields.socialLinks] as List<dynamic>?) ?? [];

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
      FirestoreUserCoinMiningFields.description: description,
      FirestoreUserCoinMiningFields.socialLinks: links,
      FirestoreUserCoinMiningFields.hourlyRate: rate,
      FirestoreUserCoinMiningFields.totalPoints:
          (data[FirestoreUserCoinMiningFields.totalPoints] as num?)
              ?.toDouble() ??
          0.0,
    }, SetOptions(merge: true));
    if (!existing.exists) {
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.userCoins)
          .doc(coinOwnerId)
          .update({
            FirestoreUserCoinFields.minersCount: FieldValue.increment(1),
          })
          .catchError((_) async {
            await FirebaseFirestore.instance
                .collection(FirestoreConstants.userCoins)
                .doc(coinOwnerId)
                .set({
                  FirestoreUserCoinFields.minersCount: FieldValue.increment(1),
                }, SetOptions(merge: true));
          });
    }
  }

  static Future<Map<String, dynamic>> startCoinMining(
    String coinOwnerId, {
    String? deviceId,
    DateTime? maxEnd,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final general = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.general)
        .get();
    final g = general.data() ?? {};

    final bool enforceSingleDevice =
        (g[FirestoreAppConfigFields.deviceSingleUserEnforced] as bool?) ??
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

    final now = DateTime.now();
    final double sessionHours =
        (g[FirestoreAppConfigFields.sessionDurationHours] as num?)
            ?.toDouble() ??
        24.0;
    final int sessionSeconds = (sessionHours > 0.0
        ? (sessionHours * 3600.0).round()
        : 0);
    DateTime endDt = now.add(
      Duration(seconds: sessionSeconds > 0 ? sessionSeconds : 24 * 3600),
    );
    if (maxEnd != null && maxEnd.isAfter(now) && maxEnd.isBefore(endDt)) {
      endDt = maxEnd;
    }
    final end = Timestamp.fromDate(endDt);

    if (useSqlBackend) {
      // 1. Fetch coin details to get the rate
      final coinData = await SqlApiService.getUserCoin(coinOwnerId);
      if (coinData == null) {
        throw Exception('Coin not found');
      }
      final double rate =
          (coinData[FirestoreUserCoinFields.baseRatePerHour] as num?)
              ?.toDouble() ??
          0.0;

      // 2. Start mining session via SQL API
      final updatedRecord = await SqlApiService.startCoinMining(
        coinOwnerId: coinOwnerId,
        hourlyRate: rate,
        start: now,
        end: endDt,
        deviceId: deviceId,
      );

      // Return the updated record in a format compatible with the app
      // Ensure fields match what the UI expects (mapped from PHP response)
      return updatedRecord;
    }

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
    final description =
        (coin[FirestoreUserCoinFields.description] as String?) ?? '';
    final links =
        (coin[FirestoreUserCoinFields.socialLinks] as List<dynamic>?) ?? [];

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
      FirestoreUserCoinMiningFields.description: description,
      FirestoreUserCoinMiningFields.socialLinks: links,
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

  static Future<void> syncCoinEarnings({
    required String coinOwnerId,
    required double amount,
    required DateTime lastSyncedAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (useSqlBackend) {
      await SqlApiService.syncCoinEarnings(
        coinOwnerId: coinOwnerId,
        amount: amount,
        lastSyncedAt: lastSyncedAt,
      );
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .doc(coinOwnerId);

    // App-driven sync for Firestore too
    await ref.update({
      FirestoreUserCoinMiningFields.totalPoints: FieldValue.increment(amount),
      FirestoreUserCoinMiningFields.lastSyncedAt: Timestamp.fromDate(
        lastSyncedAt,
      ),
    });
  }
}
