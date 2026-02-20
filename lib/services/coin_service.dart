import 'dart:async';
import 'dart:convert';
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
import 'offline_mining_service.dart';
import 'user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      if (!useSqlBackend) {
        unawaited(_CoinMiningSessionManager.onAppResumed());
      }
    }
  }

  static void init() {
    _instance;
    if (!useSqlBackend) {
      unawaited(_CoinMiningSessionManager.initForCurrentUser());
    }
  }

  static Future<Map<String, dynamic>?> getUserCoin(String uid) async {
    final snap = await FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .get();
    final data = snap.data() ?? {};
    final coins = _extractWalletCoins(data);
    final coin = coins[uid];
    if (coin is Map<String, dynamic>) {
      final m = Map<String, dynamic>.from(coin);

      m[FirestoreUserCoinMiningFields.ownerId] =
          m[FirestoreUserCoinMiningFields.ownerId] ?? uid;

      m[FirestoreUserCoinFields.ownerId] =
          m[FirestoreUserCoinFields.ownerId] ??
          m[FirestoreUserCoinMiningFields.ownerId];

      m[FirestoreUserCoinFields.name] =
          m[FirestoreUserCoinFields.name] ??
          m[FirestoreUserCoinMiningFields.name];
      m[FirestoreUserCoinFields.symbol] =
          m[FirestoreUserCoinFields.symbol] ??
          m[FirestoreUserCoinMiningFields.symbol];
      m[FirestoreUserCoinFields.imageUrl] =
          m[FirestoreUserCoinFields.imageUrl] ??
          m[FirestoreUserCoinMiningFields.imageUrl];
      m[FirestoreUserCoinFields.description] =
          m[FirestoreUserCoinFields.description] ??
          m[FirestoreUserCoinMiningFields.description];
      m[FirestoreUserCoinFields.socialLinks] =
          m[FirestoreUserCoinFields.socialLinks] ??
          m[FirestoreUserCoinMiningFields.socialLinks];

      m[FirestoreUserCoinFields.baseRatePerHour] =
          m[FirestoreUserCoinFields.baseRatePerHour] ??
          m[FirestoreUserCoinMiningFields.hourlyRate];

      return m;
    }
    return null;
  }

  static Stream<Map<String, dynamic>?> watchUserCoin(String uid) {
    return FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .snapshots()
        .map((doc) {
          final data = doc.data() ?? {};
          final coins = _extractWalletCoins(data);
          final coin = coins[uid];
          if (coin is Map<String, dynamic>) {
            final m = Map<String, dynamic>.from(coin);
            m[FirestoreUserCoinMiningFields.ownerId] =
                m[FirestoreUserCoinMiningFields.ownerId] ?? uid;

            m[FirestoreUserCoinFields.ownerId] =
                m[FirestoreUserCoinFields.ownerId] ??
                m[FirestoreUserCoinMiningFields.ownerId];

            m[FirestoreUserCoinFields.name] =
                m[FirestoreUserCoinFields.name] ??
                m[FirestoreUserCoinMiningFields.name];
            m[FirestoreUserCoinFields.symbol] =
                m[FirestoreUserCoinFields.symbol] ??
                m[FirestoreUserCoinMiningFields.symbol];
            m[FirestoreUserCoinFields.imageUrl] =
                m[FirestoreUserCoinFields.imageUrl] ??
                m[FirestoreUserCoinMiningFields.imageUrl];
            m[FirestoreUserCoinFields.description] =
                m[FirestoreUserCoinFields.description] ??
                m[FirestoreUserCoinMiningFields.description];
            m[FirestoreUserCoinFields.socialLinks] =
                m[FirestoreUserCoinFields.socialLinks] ??
                m[FirestoreUserCoinMiningFields.socialLinks];

            m[FirestoreUserCoinFields.baseRatePerHour] =
                m[FirestoreUserCoinFields.baseRatePerHour] ??
                m[FirestoreUserCoinMiningFields.hourlyRate];

            return m;
          }
          return null;
        });
  }

  // Cache for SQL backend
  static List<Map<String, dynamic>>? _cachedMyCoins;
  static DateTime? _myCoinsFetchTime;
  static List<Map<String, dynamic>>? _cachedLiveCoins;
  static DateTime? _liveCoinsFetchTime;
  static String? _lastLiveSort;

  static Map<String, dynamic> _extractWalletCoins(Map<String, dynamic> data) {
    final wallet =
        (data[FirestoreUserFields.wallet] as Map<String, dynamic>?) ?? {};
    final nestedCoins =
        (wallet['coins'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    if (nestedCoins.isNotEmpty) {
      return Map<String, dynamic>.from(nestedCoins);
    }

    final Map<String, dynamic> coins = {};
    final prefix = '${FirestoreUserFields.wallet}.coins.';
    data.forEach((key, value) {
      if (key.startsWith(prefix) && value is Map<String, dynamic>) {
        final ownerId = key.substring(prefix.length);
        if (ownerId.isNotEmpty) {
          coins[ownerId] = value;
        }
      }
    });
    return coins;
  }

  static Stream<List<Map<String, dynamic>>> watchMyCoins(String uid) {
    return FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .snapshots()
        .map((snap) {
          final data = snap.data() ?? {};
          final coins = _extractWalletCoins(data);
          return coins.entries.map((e) {
            final m = Map<String, dynamic>.from(e.value as Map);
            m[FirestoreUserCoinMiningFields.ownerId] = e.key;
            return m;
          }).toList();
        });
  }

  /// Manually update the coins cache (e.g. from MiningStateService)
  static void updateMyCoinsCache(List<Map<String, dynamic>> coins) {
    _cachedMyCoins = coins;
    _myCoinsFetchTime = DateTime.now();
  }

  /// Get the list of coins, preferring cache/SQL
  static Future<List<Map<String, dynamic>>> getMyCoins(String uid) async {
    final snap = await UserService().getUser(uid);
    final data = snap?.data() ?? {};
    final coins = _extractWalletCoins(data);
    return coins.entries.map((e) {
      final m = Map<String, dynamic>.from(e.value as Map);
      m[FirestoreUserCoinMiningFields.ownerId] = e.key;
      return m;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _loadLiveCoinsRaw() async {
    final now = DateTime.now();
    if (_cachedLiveCoins != null &&
        _liveCoinsFetchTime != null &&
        now.difference(_liveCoinsFetchTime!) < const Duration(hours: 1)) {
      return _cachedLiveCoins!;
    }

    final snap = await FirestoreHelper.instance
        .collection(FirestoreConstants.sharedCoinsPages)
        .get();

    final List<Map<String, dynamic>> docs = [];

    for (final doc in snap.docs) {
      final data = doc.data();
      final coins =
          (data['coins'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      coins.forEach((ownerId, value) {
        if (value is Map<String, dynamic>) {
          final m = Map<String, dynamic>.from(value);
          m[FirestoreUserCoinFields.ownerId] =
              m[FirestoreUserCoinFields.ownerId] ?? ownerId;
          docs.add(m);
        }
      });
    }

    docs.removeWhere((d) {
      final v = d[FirestoreUserCoinFields.isActive];
      if (v is bool) return !v;
      if (v is int) return v == 0;
      if (v is String) {
        final s = v.toLowerCase();
        return s == '0' || s == 'false';
      }
      return false;
    });

    _cachedLiveCoins = docs;
    _liveCoinsFetchTime = DateTime.now();

    return docs;
  }

  static Stream<List<Map<String, dynamic>>> watchLiveCoins({
    String sort = 'popular',
  }) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    () async {
      try {
        final raw = await _loadLiveCoinsRaw();
        final docs = raw.map((e) => Map<String, dynamic>.from(e)).toList();

        int getMinersCount(Map<String, dynamic> d) {
          final v = d[FirestoreUserCoinFields.minersCount];
          if (v is int) return v;
          if (v is String) return int.tryParse(v) ?? 0;
          return 0;
        }

        DateTime getCreatedAt(Map<String, dynamic> d) {
          final v = d[FirestoreUserCoinFields.createdAt];
          if (v is Timestamp) return v.toDate();
          if (v is String) return DateTime.tryParse(v) ?? DateTime(1970);
          return DateTime(1970);
        }

        String getName(Map<String, dynamic> d) {
          return (d[FirestoreUserCoinFields.name] as String?)?.toLowerCase() ??
              '';
        }

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

        controller.add(docs.take(50).toList());
      } catch (e, st) {
        controller.addError(e, st);
        // ignore: avoid_print
        print(e);
        // ignore: avoid_print
        print(st);
      } finally {
        await controller.close();
      }
    }();

    return controller.stream;
  }

  static Future<Map<String, dynamic>> getUserCoinConfig() async {
    return ConfigService().getUserCoinConfig();
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
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .doc(FirestoreUserSubCollections.coins);
    try {
      await ref.set(coin, SetOptions(merge: merge));
      debugPrint('[CoinService] Firestore set success | merge=$merge');
    } catch (e) {
      debugPrint('[CoinService] Firestore set failed | error=$e');
      rethrow;
    }

    final userRefForWallet = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    final userSnap = await UserService().getUser(uid);
    final userData = userSnap?.data() ?? {};
    final coins = _extractWalletCoins(userData);
    final existingCoin =
        (coins[uid] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final mergedCoin = Map<String, dynamic>.from(existingCoin);

    final double baseRate =
        (coin[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
        0.0;
    final name = (coin[FirestoreUserCoinFields.name] as String?) ?? '';
    final symbol = (coin[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final imageUrl = (coin[FirestoreUserCoinFields.imageUrl] as String?) ?? '';
    final description =
        (coin[FirestoreUserCoinFields.description] as String?) ?? '';
    final links =
        (coin[FirestoreUserCoinFields.socialLinks] as List<dynamic>?) ??
        const [];

    mergedCoin[FirestoreUserCoinMiningFields.ownerId] = uid;
    mergedCoin[FirestoreUserCoinMiningFields.name] = name;
    mergedCoin[FirestoreUserCoinMiningFields.symbol] = symbol;
    mergedCoin[FirestoreUserCoinMiningFields.imageUrl] = imageUrl;
    mergedCoin[FirestoreUserCoinMiningFields.description] = description;
    mergedCoin[FirestoreUserCoinMiningFields.socialLinks] = links;
    mergedCoin[FirestoreUserCoinMiningFields.hourlyRate] = baseRate;

    final isActive = (coin[FirestoreUserCoinFields.isActive] as bool?) ?? true;
    mergedCoin[FirestoreUserCoinFields.isActive] = isActive;

    if (mergedCoin[FirestoreUserCoinMiningFields.totalPoints] == null) {
      mergedCoin[FirestoreUserCoinMiningFields.totalPoints] = 0.0;
    }

    await userRefForWallet.set({
      '${FirestoreUserFields.wallet}.coins.$uid': mergedCoin,
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> addCoinForUser(
    String coinOwnerId, {
    Map<String, dynamic>? coinData,
  }) async {
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

    Map<String, dynamic> coin;
    if (coinData != null) {
      coin = Map<String, dynamic>.from(coinData);
    } else {
      final coinSnap = await FirestoreHelper.instance
          .collection(FirestoreConstants.userCoins)
          .doc(coinOwnerId)
          .get();
      coin = coinSnap.data() ?? <String, dynamic>{};
    }

    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    final userSnap = await UserService().getUser(uid);
    final userData = userSnap?.data() ?? {};
    final wallet =
        (userData[FirestoreUserFields.wallet] as Map<String, dynamic>?) ?? {};
    final coinsMap = (wallet['coins'] as Map<String, dynamic>?) ?? {};
    final existingCoin = (coinsMap[coinOwnerId] as Map<String, dynamic>?) ?? {};

    final mergedCoin = <String, dynamic>{};
    mergedCoin.addAll(coin);
    mergedCoin.addAll(existingCoin);

    mergedCoin[FirestoreUserCoinMiningFields.ownerId] = coinOwnerId;

    if (mergedCoin[FirestoreUserCoinMiningFields.name] == null) {
      mergedCoin[FirestoreUserCoinMiningFields.name] =
          mergedCoin[FirestoreUserCoinFields.name];
    }
    if (mergedCoin[FirestoreUserCoinMiningFields.symbol] == null) {
      mergedCoin[FirestoreUserCoinMiningFields.symbol] =
          mergedCoin[FirestoreUserCoinFields.symbol];
    }
    if (mergedCoin[FirestoreUserCoinMiningFields.imageUrl] == null) {
      mergedCoin[FirestoreUserCoinMiningFields.imageUrl] =
          mergedCoin[FirestoreUserCoinFields.imageUrl];
    }
    if (mergedCoin[FirestoreUserCoinMiningFields.description] == null) {
      mergedCoin[FirestoreUserCoinMiningFields.description] =
          mergedCoin[FirestoreUserCoinFields.description];
    }
    if (mergedCoin[FirestoreUserCoinMiningFields.socialLinks] == null) {
      mergedCoin[FirestoreUserCoinMiningFields.socialLinks] =
          mergedCoin[FirestoreUserCoinFields.socialLinks] ?? <dynamic>[];
    }

    if (mergedCoin[FirestoreUserCoinMiningFields.hourlyRate] == null) {
      final baseRate =
          (mergedCoin[FirestoreUserCoinFields.baseRatePerHour] as num?)
              ?.toDouble() ??
          0.0;
      mergedCoin[FirestoreUserCoinMiningFields.hourlyRate] = baseRate;
    }

    if (mergedCoin[FirestoreUserCoinMiningFields.totalPoints] == null) {
      mergedCoin[FirestoreUserCoinMiningFields.totalPoints] = 0.0;
    }

    await userRef.set({
      '${FirestoreUserFields.wallet}.coins.$coinOwnerId': mergedCoin,
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (existingCoin.isEmpty) {
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
    await OfflineMiningEngine(FirestoreHelper.instance).reloadFromRemote(uid);
  }

  static Future<Map<String, dynamic>> startCoinMining(
    String coinOwnerId, {
    String? deviceId,
    DateTime? maxEnd,
    Map<String, dynamic>? cachedCoinData,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    if (!useSqlBackend) {
      await _CoinMiningSessionManager.processNowForCurrentUser();
    }

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

    Map<String, dynamic> coin = {};
    if (cachedCoinData != null &&
        cachedCoinData[FirestoreUserCoinMiningFields.name] != null) {
      coin = cachedCoinData;
    } else {
      final coinSnap = await FirestoreHelper.instance
          .collection(FirestoreConstants.userCoins)
          .doc(coinOwnerId)
          .get();
      coin = coinSnap.data() ?? {};

      if (coin.isEmpty) {
        final creatorSnap = await FirestoreHelper.instance
            .collection(FirestoreConstants.users)
            .doc(coinOwnerId)
            .get();
        final creatorData = creatorSnap.data() ?? {};
        final creatorWallet =
            (creatorData[FirestoreUserFields.wallet]
                as Map<String, dynamic>?) ??
            {};
        final creatorCoins =
            (creatorWallet['coins'] as Map<String, dynamic>?) ?? {};
        final creatorCoin = creatorCoins[coinOwnerId];
        if (creatorCoin is Map<String, dynamic>) {
          coin = Map<String, dynamic>.from(creatorCoin);
        }
      }
    }

    final double rate = (cachedCoinData != null)
        ? (cachedCoinData[FirestoreUserCoinMiningFields.hourlyRate] as num?)
                  ?.toDouble() ??
              0.0
        : ((coin[FirestoreUserCoinFields.baseRatePerHour] as num?)
                  ?.toDouble() ??
              (coin[FirestoreUserCoinMiningFields.hourlyRate] as num?)
                  ?.toDouble() ??
              0.0);

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

    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);
    final userSnap = await UserService().getUser(uid);

    final uData = userSnap?.data() ?? {};
    final liveCoins = _extractWalletCoins(uData);
    Map<String, dynamic> data = {};
    if (liveCoins.containsKey(coinOwnerId)) {
      data = Map<String, dynamic>.from(
        liveCoins[coinOwnerId] as Map<String, dynamic>,
      );
    } else if (cachedCoinData != null) {
      data = Map<String, dynamic>.from(cachedCoinData);
    }

    final lastEnd =
        data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
    if (lastEnd != null && DateTime.now().isBefore(lastEnd.toDate())) {
      return data;
    }

    final Map<String, dynamic> newState = Map<String, dynamic>.from(data);
    newState[FirestoreUserCoinMiningFields.lastMiningStart] =
        Timestamp.fromDate(now);
    newState[FirestoreUserCoinMiningFields.lastMiningEnd] = end;
    newState[FirestoreUserCoinMiningFields.lastSyncedAt] = Timestamp.fromDate(
      now,
    );

    await userRef.set({
      '${FirestoreUserFields.wallet}.coins.$coinOwnerId': newState,
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // OPTIMIZATION: Merge local data instead of re-fetching
    await OfflineMiningEngine(FirestoreHelper.instance).reloadFromRemote(uid);
    if (!useSqlBackend) {
      unawaited(
        _CoinMiningSessionManager.registerFromState(uid, coinOwnerId, newState),
      );
    }
    return newState;
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

    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);

    await FirestoreHelper.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? {};
      final wallet =
          (data[FirestoreUserFields.wallet] as Map<String, dynamic>?) ?? {};
      final coins = (wallet['coins'] as Map<String, dynamic>?) ?? {};
      final existingCoin =
          (coins[coinOwnerId] as Map<String, dynamic>?) ?? <String, dynamic>{};

      final currentTotal =
          (existingCoin[FirestoreUserCoinMiningFields.totalPoints] as num?)
              ?.toDouble() ??
          0.0;

      existingCoin[FirestoreUserCoinMiningFields.totalPoints] =
          currentTotal + amount;
      existingCoin[FirestoreUserCoinMiningFields.lastSyncedAt] =
          Timestamp.fromDate(lastSyncedAt);

      coins[coinOwnerId] = existingCoin;

      transaction.set(userRef, {
        '${FirestoreUserFields.wallet}.coins.$coinOwnerId': existingCoin,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static Future<void> _syncAllCoinEarningsFromWallet() async {
    return;
  }
}

class _CoinMiningSession {
  final String coinOwnerId;
  final DateTime start;
  final DateTime end;
  final DateTime lastSyncedAt;
  final double hourlyRate;
  final double baseTotalPoints;

  _CoinMiningSession({
    required this.coinOwnerId,
    required this.start,
    required this.end,
    required this.lastSyncedAt,
    required this.hourlyRate,
    required this.baseTotalPoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'coinOwnerId': coinOwnerId,
      'startMs': start.millisecondsSinceEpoch,
      'endMs': end.millisecondsSinceEpoch,
      'lastSyncedMs': lastSyncedAt.millisecondsSinceEpoch,
      'hourlyRate': hourlyRate,
      'baseTotalPoints': baseTotalPoints,
    };
  }

  static _CoinMiningSession? fromJson(Map<String, dynamic> json) {
    final coinOwnerId = json['coinOwnerId'] as String?;
    final int? startMs = json['startMs'] as int?;
    final int? endMs = json['endMs'] as int?;
    final int? lastSyncedMs = json['lastSyncedMs'] as int?;
    final double hourlyRate = (json['hourlyRate'] as num?)?.toDouble() ?? 0.0;
    final double baseTotalPoints =
        (json['baseTotalPoints'] as num?)?.toDouble() ?? 0.0;
    if (coinOwnerId == null ||
        startMs == null ||
        endMs == null ||
        lastSyncedMs == null ||
        hourlyRate <= 0.0) {
      return null;
    }
    return _CoinMiningSession(
      coinOwnerId: coinOwnerId,
      start: DateTime.fromMillisecondsSinceEpoch(startMs),
      end: DateTime.fromMillisecondsSinceEpoch(endMs),
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(lastSyncedMs),
      hourlyRate: hourlyRate,
      baseTotalPoints: baseTotalPoints,
    );
  }
}

class _CoinMiningSessionManager {
  static const _keyPrefix = 'coin_mining_sessions_v1_';
  static SharedPreferences? _prefs;
  static Map<String, _CoinMiningSession> _sessions = {};
  static String? _loadedUid;
  static Timer? _timer;

  static Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> _load(String uid) async {
    if (_loadedUid == uid && _sessions.isNotEmpty) {
      return;
    }
    final prefs = await _ensurePrefs();
    final raw = prefs.getString('$_keyPrefix$uid');
    if (raw == null || raw.isEmpty) {
      _sessions = {};
      _loadedUid = uid;
      return;
    }
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final Map<String, _CoinMiningSession> map = {};
      decoded.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final session = _CoinMiningSession.fromJson(value);
          if (session != null) {
            map[key] = session;
          }
        }
      });
      _sessions = map;
    } catch (_) {
      _sessions = {};
    }
    _loadedUid = uid;
  }

  static Future<void> _save(String uid) async {
    final prefs = await _ensurePrefs();
    if (_sessions.isEmpty) {
      await prefs.remove('$_keyPrefix$uid');
      return;
    }
    final Map<String, dynamic> out = {};
    _sessions.forEach((key, value) {
      out[key] = value.toJson();
    });
    await prefs.setString('$_keyPrefix$uid', json.encode(out));
  }

  static Future<void> initForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _load(uid);
    await _processFinished(uid, DateTime.now());
    _scheduleNext(uid);
  }

  static Future<void> registerFromState(
    String uid,
    String coinOwnerId,
    Map<String, dynamic> state,
  ) async {
    final startTs =
        state[FirestoreUserCoinMiningFields.lastMiningStart] as Timestamp?;
    final endTs =
        state[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
    final syncedTs =
        state[FirestoreUserCoinMiningFields.lastSyncedAt] as Timestamp?;
    final double hourlyRate =
        (state[FirestoreUserCoinMiningFields.hourlyRate] as num?)?.toDouble() ??
        0.0;
    final double baseTotal =
        (state[FirestoreUserCoinMiningFields.totalPoints] as num?)
            ?.toDouble() ??
        0.0;
    if (startTs == null ||
        endTs == null ||
        syncedTs == null ||
        hourlyRate <= 0.0) {
      return;
    }
    await _load(uid);
    _sessions[coinOwnerId] = _CoinMiningSession(
      coinOwnerId: coinOwnerId,
      start: startTs.toDate(),
      end: endTs.toDate(),
      lastSyncedAt: syncedTs.toDate(),
      hourlyRate: hourlyRate,
      baseTotalPoints: baseTotal,
    );
    await _save(uid);
    _scheduleNext(uid);
  }

  static Future<void> onAppResumed() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _load(uid);
    await _processFinished(uid, DateTime.now());
    _scheduleNext(uid);
  }

  static Future<void> processNowForCurrentUser() async {
    await onAppResumed();
  }

  static void _scheduleNext(String uid) {
    _timer?.cancel();
    if (_sessions.isEmpty) {
      return;
    }
    final now = DateTime.now();
    DateTime? earliestEnd;
    for (final session in _sessions.values) {
      if (session.end.isAfter(now)) {
        if (earliestEnd == null || session.end.isBefore(earliestEnd)) {
          earliestEnd = session.end;
        }
      }
    }
    if (earliestEnd == null) {
      unawaited(_processFinished(uid, now));
      return;
    }
    final delay = earliestEnd.difference(now);
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () async {
      await _processFinished(uid, DateTime.now());
      _scheduleNext(uid);
    });
  }

  static Future<void> _processFinished(String uid, DateTime now) async {
    if (_sessions.isEmpty) return;
    final finished = <String, _CoinMiningSession>{};
    _sessions.forEach((key, value) {
      if (!now.isBefore(value.end)) {
        finished[key] = value;
      }
    });
    if (finished.isEmpty) return;

    final Map<String, double> deltas = {};
    finished.forEach((key, session) {
      final end = session.end;
      if (!end.isAfter(session.lastSyncedAt)) {
        return;
      }
      final durationSeconds = end
          .difference(session.lastSyncedAt)
          .inSeconds
          .toDouble();
      if (durationSeconds <= 0) {
        return;
      }
      final delta = (durationSeconds / 3600.0) * session.hourlyRate;
      if (delta <= 0.0) {
        return;
      }
      deltas[session.coinOwnerId] =
          (deltas[session.coinOwnerId] ?? 0.0) + delta;
    });

    if (deltas.isEmpty) {
      finished.keys.forEach(_sessions.remove);
      await _save(uid);
      return;
    }

    final userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid);

    await FirestoreHelper.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? {};
      final wallet =
          (data[FirestoreUserFields.wallet] as Map<String, dynamic>?) ?? {};
      final coins = (wallet['coins'] as Map<String, dynamic>?) ?? {};

      final Map<String, dynamic> updates = {};

      deltas.forEach((ownerId, delta) {
        final existingCoin =
            (coins[ownerId] as Map<String, dynamic>?) ?? <String, dynamic>{};
        double currentTotal =
            (existingCoin[FirestoreUserCoinMiningFields.totalPoints] as num?)
                ?.toDouble() ??
            0.0;
        final session = finished[ownerId];
        if (currentTotal == 0.0 &&
            session != null &&
            session.baseTotalPoints > 0.0) {
          currentTotal = session.baseTotalPoints;
        }
        final newTotal = currentTotal + delta;
        existingCoin[FirestoreUserCoinMiningFields.totalPoints] = newTotal;
        if (session != null) {
          existingCoin[FirestoreUserCoinMiningFields.lastSyncedAt] =
              Timestamp.fromDate(session.end);
        }

        updates['${FirestoreUserFields.wallet}.coins.$ownerId'] = existingCoin;
      });

      if (updates.isEmpty) {
        return;
      }

      updates[FirestoreUserFields.updatedAt] = FieldValue.serverTimestamp();

      transaction.set(userRef, updates, SetOptions(merge: true));
    });

    finished.keys.forEach(_sessions.remove);
    await _save(uid);
  }
}
