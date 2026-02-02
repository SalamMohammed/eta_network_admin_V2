import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/firestore_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/widgets.dart';
import '../shared/constants.dart';
import 'sql_api_service.dart'; // Add this import

class CoinService with WidgetsBindingObserver {
  // MASTER SWITCH: Set to true to use SQL, false for Firestore
  static const bool useSqlBackend = true;

  // Singleton instance for lifecycle management
  static final CoinService _instance = CoinService._internal();
  factory CoinService() => _instance;
  CoinService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static bool _isPaused = false;
  static final List<Function> _resumeCallbacks = [];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isPaused = true;
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
      // Smart Resumption: Pause when backgrounded, fetch immediately on resume
      Stream<Map<String, dynamic>?> stream() async* {
        // Initial fetch
        yield await SqlApiService.getUserCoin(uid);

        // We use a custom periodic logic to handle pausing/resumption
        // yield* Stream.periodic(...) doesn't easily support external pause/resume
        // so we just check _isPaused inside asyncMap, but that only skips, doesn't pause the timer.
        // However, asyncMap waits for the future. If we just return null or skip, the timer continues.
        // To truly save resources, we should skip network calls.

        // Better approach: Use a persistent generator loop
        while (true) {
          await Future.delayed(const Duration(seconds: 5));
          if (_isPaused) continue; // Skip if backgrounded

          // If just resumed, this loop might be in the middle of a wait.
          // The _resumeCallbacks can be used to interrupt/force fetch if we used a StreamController.
          // But since we are using async*, we rely on the loop.
          // "Smart Resumption" requires immediate fetch.
          // The loop above has a rigid 5s wait.
          // To support immediate fetch on resume, we can use a Signal/Event based approach or just accept up to 5s delay?
          // User requested "no catch-up lag" -> immediate update.

          // Implementation for Smart Resumption using this simple generator:
          // We can't easily break the `Future.delayed` from outside.
          // So let's stick to the periodic stream but add a "force refresh" signal?
          // Or just standard polling that skips when paused.
          // For "immediate" update on resume, the UI usually rebuilds or we can trigger a fetch.

          // Let's implement the `_resumeCallbacks` logic inside `watchUserCoin` using a StreamController.
        }
      }

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
        timer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (_isPaused) return; // Skip if backgrounded
          fetch();
        });
      }

      // Register resume callback
      void onResume() {
        if (!controller.isClosed) {
          fetch(); // Immediate fetch on resume
        }
      }

      controller.onListen = () {
        fetch(); // Initial fetch
        startTimer();
        _resumeCallbacks.add(onResume);
      };

      controller.onCancel = () {
        timer?.cancel();
        _resumeCallbacks.remove(onResume);
      };

      return controller.stream.asBroadcastStream();
    }
    return FirebaseFirestore.instance
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
    if (useSqlBackend) {
      // Poll every 30 seconds
      final controller = StreamController<List<Map<String, dynamic>>>();
      Timer? timer;

      void fetch() async {
        if (controller.isClosed) return;

        // Use cache if fresh and available
        if (_cachedMyCoins != null &&
            _myCoinsFetchTime != null &&
            DateTime.now().difference(_myCoinsFetchTime!) <
                const Duration(seconds: 30)) {
          if (!controller.isClosed) controller.add(_cachedMyCoins!);
          // If it's cached, we might still want to fetch fresh if this was a forced refresh?
          // But the logic below handles periodic.
        }

        final fresh = await SqlApiService.getMyCoins(uid);
        if (fresh != null) {
          _cachedMyCoins = fresh;
          _myCoinsFetchTime = DateTime.now();
          if (!controller.isClosed) controller.add(fresh);
        }
      }

      void startTimer() {
        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 30), (_) {
          if (_isPaused) return;
          fetch();
        });
      }

      void onResume() {
        if (!controller.isClosed) fetch();
      }

      controller.onListen = () {
        fetch();
        startTimer();
        _resumeCallbacks.add(onResume);
      };

      controller.onCancel = () {
        timer?.cancel();
        _resumeCallbacks.remove(onResume);
      };

      return controller.stream.asBroadcastStream();
    }
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  static Stream<List<Map<String, dynamic>>> watchLiveCoins({
    String sort = 'popular',
  }) {
    if (useSqlBackend) {
      // Poll every 60 seconds for market data
      final controller = StreamController<List<Map<String, dynamic>>>();
      Timer? timer;

      void fetch() async {
        if (controller.isClosed) return;

        // Yield cached data immediately if available, matches sort, and fresh (< 60s)
        if (_cachedLiveCoins != null &&
            _liveCoinsFetchTime != null &&
            _lastLiveSort == sort &&
            DateTime.now().difference(_liveCoinsFetchTime!) <
                const Duration(seconds: 60)) {
          if (!controller.isClosed) controller.add(_cachedLiveCoins!);
        }

        final fresh = await SqlApiService.getLiveCoins(sort: sort);
        if (fresh != null) {
          _cachedLiveCoins = fresh;
          _liveCoinsFetchTime = DateTime.now();
          _lastLiveSort = sort;
          if (!controller.isClosed) controller.add(fresh);
        }
      }

      void startTimer() {
        timer?.cancel();
        timer = Timer.periodic(const Duration(seconds: 60), (_) {
          if (_isPaused) return;
          fetch();
        });
      }

      void onResume() {
        if (!controller.isClosed) fetch();
      }

      controller.onListen = () {
        fetch();
        startTimer();
        _resumeCallbacks.add(onResume);
      };

      controller.onCancel = () {
        timer?.cancel();
        _resumeCallbacks.remove(onResume);
      };

      return controller.stream.asBroadcastStream();
    }
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.userCoins)
        .where(FirestoreUserCoinFields.isActive, isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
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
