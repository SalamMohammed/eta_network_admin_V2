import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_helper.dart';
import '../shared/firestore_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/widgets.dart';
import '../shared/constants.dart';
import 'sql_api_service.dart';
import 'config_service.dart';

class CoinService with WidgetsBindingObserver {
  // MASTER SWITCH: Set to true to use SQL, false for Firestore
  static const bool useSqlBackend = false;

  // Singleton instance for lifecycle management
  static final CoinService _instance = CoinService._internal();
  factory CoinService() => _instance;
  CoinService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static bool _isPaused = false;
  static final List<Function> _resumeCallbacks = [];
  static final List<Function> _pauseCallbacks = [];
  static final List<VoidCallback> _refreshMyCoinsCallbacks = [];

  // Cache for device check to avoid repeated reads
  static final Map<String, String> _deviceCheckedCache = {};

  static void triggerMyCoinsRefresh() {
    for (final callback in _refreshMyCoinsCallbacks) {
      callback();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isPaused = true;
      for (final callback in _pauseCallbacks) {
        callback();
      }
    } else if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      // Trigger immediate updates
      for (final callback in _resumeCallbacks) {
        callback();
      }
    }
  }

  static void init() {
    // Just to ensure singleton is created and observer registered
    _instance;
  }

  static Future<Map<String, dynamic>?> getUserCoin(String uid) async {
    /* if (useSqlBackend) {
      return SqlApiService.getUserCoin(uid);
    } */
    final snap = await FirestoreHelper.instance
        .collection(FirestoreConstants.userCoins)
        .doc(uid)
        .get();
    return snap.data();
  }

  static Stream<Map<String, dynamic>?> watchUserCoin(String uid) {
    /* if (useSqlBackend) {
      // Re-implementing using StreamController for full control
      final controller = StreamController<Map<String, dynamic>?>();
      Timer? timer;

      void fetch() async {
        if (controller.isClosed) return;
        final data = await SqlApiService.getUserCoin(uid);
        if (!controller.isClosed) controller.add(data);
      }

      void startTimer() {
        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 15), (_) {
          if (_isPaused) return;
          fetch();
        });
      }

      void onPause() {
        timer?.cancel();
        timer = null;
      }

      void onResume() {
        if (!controller.isClosed) {
          fetch();
          startTimer();
        }
      }

      void forceFetch() {
        fetch();
      }

      controller.onListen = () {
        fetch();
        startTimer();
        _resumeCallbacks.add(onResume);
        _pauseCallbacks.add(onPause);
        _refreshMyCoinsCallbacks.add(forceFetch);
      };

      controller.onCancel = () {
        timer?.cancel();
        _resumeCallbacks.remove(onResume);
        _pauseCallbacks.remove(onPause);
        _refreshMyCoinsCallbacks.remove(forceFetch);
      };

      return controller.stream.asBroadcastStream();
    } */
    return FirestoreHelper.instance
        .collection(FirestoreConstants.userCoins)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  // Cache for SQL backend
  static List<Map<String, dynamic>>? _cachedMyCoins;
  static DateTime? _myCoinsFetchTime;
  static List<Map<String, dynamic>>? _cachedLiveCoins;
  static DateTime? _liveCoinsFetchTime;
  static String? _lastLiveSort;

  static Stream<List<Map<String, dynamic>>> watchMyCoins(String uid) {
    // Directly watch Firestore subcollection
    return FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Manually update the coins cache (e.g. from MiningStateService)
  static void updateMyCoinsCache(List<Map<String, dynamic>> coins) {
    _cachedMyCoins = coins;
    _myCoinsFetchTime = DateTime.now();
  }

  /// Get the list of coins, preferring cache/SQL
  static Future<List<Map<String, dynamic>>> getMyCoins(String uid) async {
    // Directly fetch from Firestore
    final qs = await FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .get();
    return qs.docs.map((d) => d.data()).toList();
  }

  static Stream<List<Map<String, dynamic>>> watchLiveCoins({
    String sort = 'popular',
  }) {
    // REVISED STRATEGY: Client-Side Sorting
    // To ensure Live Coins appear immediately without requiring the user to create
    // complex composite indexes (e.g., isActive + minersCount) in the Firebase Console,
    // we fetch ALL active coins and sort them in memory.
    //
    // This is robust against:
    // 1. Missing Firestore indexes (common cause of empty results).
    // 2. Data type inconsistencies (handled by whereIn and safe parsing).

    return FirestoreHelper.instance
        .collection(FirestoreConstants.userCoins)
        .where(FirestoreUserCoinFields.isActive, whereIn: [true, '1', 1])
        .snapshots()
        .map((snap) {
      final docs = snap.docs.map((d) => d.data()).toList();

      // Helper to parse minersCount safely
      int getMinersCount(Map<String, dynamic> d) {
        final v = d[FirestoreUserCoinFields.minersCount];
        if (v is int) return v;
        if (v is String) return int.tryParse(v) ?? 0;
        return 0;
      }

      // Helper to parse createdAt safely
      DateTime getCreatedAt(Map<String, dynamic> d) {
        final v = d[FirestoreUserCoinFields.createdAt];
        if (v is Timestamp) return v.toDate();
        if (v is String) return DateTime.tryParse(v) ?? DateTime(1970);
        return DateTime(1970);
      }

      // Helper to get name
      String getName(Map<String, dynamic> d) {
        return (d[FirestoreUserCoinFields.name] as String?)?.toLowerCase() ??
            '';
      }

      // Sort in memory
      switch (sort) {
        case 'popular':
          docs.sort((a, b) => getMinersCount(b).compareTo(getMinersCount(a)));
          break;
        case 'name_az':
          docs.sort((a, b) => getName(a).compareTo(getName(b)));
          break;
        case 'name_za':
          docs.sort((a, b) => getName(b).compareTo(getName(a)));
          break;
        case 'old_new':
          docs.sort((a, b) => getCreatedAt(a).compareTo(getCreatedAt(b)));
          break;
        case 'new_old':
        case 'newest':
          docs.sort((a, b) => getCreatedAt(b).compareTo(getCreatedAt(a)));
          break;
        default:
          docs.sort((a, b) => getMinersCount(b).compareTo(getMinersCount(a)));
      }

      // Return top 50 to match typical page size
      return docs.take(50).toList();
    });
  }

  static Future<Map<String, dynamic>> getUserCoinConfig() async {
    final snap = await FirestoreHelper.instance
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
    if (name != null && name.isNotEmpty) {
      final q = await FirestoreHelper.instance
          .collection(FirestoreConstants.userCoins)
          .where(FirestoreUserCoinFields.name, isEqualTo: name)
          .limit(1)
          .get();
      if (q.docs.any((d) => d.id != excludeUid)) {
        throw Exception('Coin name "$name" is already taken.');
      }
    }
    if (symbol != null && symbol.isNotEmpty) {
      final q = await FirestoreHelper.instance
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
    /* if (useSqlBackend) {
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
    } */

    final ref = FirestoreHelper.instance
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
    /* if (useSqlBackend) {
      try {
        await SqlApiService.addToMyCoins(coinOwnerId);
        triggerMyCoinsRefresh();
        return;
      } catch (e) {
        debugPrint('[CoinService] SQL add to my coins failed | error=$e');
        rethrow;
      }
    } */

    final coinSnap = await FirestoreHelper.instance
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

    final ref = FirestoreHelper.instance
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
      // Safely increment minersCount, handling potential String types from migration
      final coinRef = FirestoreHelper.instance
          .collection(FirestoreConstants.userCoins)
          .doc(coinOwnerId);

      FirestoreHelper.instance
          .runTransaction((transaction) async {
            final snapshot = await transaction.get(coinRef);
            if (!snapshot.exists) return;

            final data = snapshot.data() ?? {};
            dynamic currentCount = data[FirestoreUserCoinFields.minersCount];
            int count = 0;
            if (currentCount is int) {
              count = currentCount;
            } else if (currentCount is String) {
              count = int.tryParse(currentCount) ?? 0;
            }

            transaction.update(coinRef, {
              FirestoreUserCoinFields.minersCount: count + 1,
            });
          })
          .catchError((e) {
            debugPrint('[CoinService] Failed to increment minersCount: $e');
            // Fallback to simple increment if transaction fails (though unlikely)
            coinRef.update({
              FirestoreUserCoinFields.minersCount: FieldValue.increment(1),
            });
          });
    }
  }

  static Future<Map<String, dynamic>> startCoinMining(
    String coinOwnerId, {
    String? deviceId,
    DateTime? maxEnd,
    Map<String, dynamic>? cachedCoinData,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final g = await ConfigService().getGeneralConfig();

    if (!useSqlBackend) {
      final bool enforceSingleDevice =
          (g[FirestoreAppConfigFields.deviceSingleUserEnforced] as bool?) ??
          false;

      if (!kIsDev && enforceSingleDevice) {
        final String dev = deviceId ?? '';
        if (dev.isNotEmpty) {
          // Check cache first
          if (!_deviceCheckedCache.containsKey(dev) ||
              _deviceCheckedCache[dev] != uid) {
            final qs = await FirestoreHelper.instance
                .collection(FirestoreConstants.users)
                .where(FirestoreUserFields.deviceId, isEqualTo: dev)
                .limit(1)
                .get();
            if (qs.docs.isNotEmpty && qs.docs.first.id != uid) {
              throw Exception('Device already bound to another account');
            }
            // Update cache
            _deviceCheckedCache[dev] = uid;
          }
        }
      }
    } else {
      // SQL Backend handles device enforcement on server side
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

    /* if (useSqlBackend) {
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

      triggerMyCoinsRefresh();

      // Return the updated record in a format compatible with the app
      // Ensure fields match what the UI expects (mapped from PHP response)
      return updatedRecord;
    } */

    // Firestore Optimization: Use cached data if available to avoid reads
    Map<String, dynamic> coin = {};
    if (cachedCoinData != null &&
        cachedCoinData[FirestoreUserCoinMiningFields.name] != null) {
      // Use cached data for coin details
      coin = cachedCoinData;
    } else {
      final coinSnap = await FirestoreHelper.instance
          .collection(FirestoreConstants.userCoins)
          .doc(coinOwnerId)
          .get();
      coin = coinSnap.data() ?? {};
    }

    // Use hourlyRate from cached data if available, otherwise baseRatePerHour from global coin
    final double rate = (cachedCoinData != null)
        ? (cachedCoinData[FirestoreUserCoinMiningFields.hourlyRate] as num?)
                  ?.toDouble() ??
              0.0
        : (coin[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
              0.0;

    final name =
        (coin[FirestoreUserCoinFields.name] as String?) ??
        (coin[FirestoreUserCoinMiningFields.name] as String?) ??
        '';
    final symbol =
        (coin[FirestoreUserCoinFields.symbol] as String?) ??
        (coin[FirestoreUserCoinMiningFields.symbol] as String?) ??
        '';
    final imageUrl =
        (coin[FirestoreUserCoinFields.imageUrl] as String?) ??
        (coin[FirestoreUserCoinMiningFields.imageUrl] as String?) ??
        '';
    final description =
        (coin[FirestoreUserCoinFields.description] as String?) ??
        (coin[FirestoreUserCoinMiningFields.description] as String?) ??
        '';
    final links =
        (coin[FirestoreUserCoinFields.socialLinks] as List<dynamic>?) ??
        (coin[FirestoreUserCoinMiningFields.socialLinks] as List<dynamic>?) ??
        [];

    final ref = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .doc(coinOwnerId);

    Map<String, dynamic> data;
    if (cachedCoinData != null) {
      data = cachedCoinData;
    } else {
      final existing = await ref.get();
      data = existing.data() ?? {};
    }

    final lastEnd =
        data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
    if (lastEnd != null && DateTime.now().isBefore(lastEnd.toDate())) {
      return data;
    }

    // Calculate pending points from previous session if it finished
    double addedPoints = 0.0;
    if (lastEnd != null) {
      final lastSynced =
          data[FirestoreUserCoinMiningFields.lastSyncedAt] as Timestamp?;
      if (lastSynced != null) {
        final oldEnd = lastEnd.toDate();
        final oldSynced = lastSynced.toDate();
        // Check if we have un-synced time at the end
        if (oldSynced.isBefore(oldEnd)) {
          final durationSeconds = oldEnd.difference(oldSynced).inSeconds;
          if (durationSeconds > 0) {
            final oldRate =
                (data[FirestoreUserCoinMiningFields.hourlyRate] as num?)
                    ?.toDouble() ??
                0.0;
            addedPoints = (durationSeconds / 3600.0) * oldRate;
          }
        }
      }
    }

    final batch = FirestoreHelper.instance.batch();
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
      FirestoreUserCoinMiningFields.totalPoints: FieldValue.increment(
        addedPoints,
      ),
    }, SetOptions(merge: true));
    await batch.commit();

    // OPTIMIZATION: Merge local data instead of re-fetching
    final Map<String, dynamic> mergedData = Map<String, dynamic>.from(data);
    final currentTotal =
        (data[FirestoreUserCoinMiningFields.totalPoints] as num?)?.toDouble() ??
        0.0;

    mergedData.addAll({
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
      FirestoreUserCoinMiningFields.totalPoints: currentTotal + addedPoints,
    });

    return mergedData;
  }

  static Future<void> syncCoinEarnings({
    required String coinOwnerId,
    required double amount,
    required DateTime lastSyncedAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    /* if (useSqlBackend) {
      await SqlApiService.syncCoinEarnings(
        coinOwnerId: coinOwnerId,
        amount: amount,
        lastSyncedAt: lastSyncedAt,
      );
      return;
    } */

    final ref = FirestoreHelper.instance
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
