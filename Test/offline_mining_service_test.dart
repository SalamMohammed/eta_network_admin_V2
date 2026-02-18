import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eta_network_admin/services/offline_mining_service.dart';
import 'package:eta_network_admin/shared/firestore_constants.dart';

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _users = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path != 'users') {
      throw UnimplementedError();
    }
    return _FakeCollection(_users);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 5),
    int maxAttempts = 5,
  }) async {
    final tx = _FakeTransaction(_users);
    final result = await transactionHandler(tx);
    return result;
  }
}

class _FakeCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _store;

  _FakeCollection(this._store);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    if (path == null) {
      throw ArgumentError.notNull('path');
    }
    return _FakeDoc(_store, path);
  }
}

class _FakeDoc extends Fake implements DocumentReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _store;
  final String _id;

  _FakeDoc(this._store, this._id);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    final data = _store[_id];
    return Future.value(_FakeGenericSnap<Map<String, dynamic>>(_id, data));
  }

  @override
  String get id => _id;
}

class _FakeGenericSnap<T extends Object?> extends Fake
    implements DocumentSnapshot<T> {
  final String _id;
  final T? _data;

  _FakeGenericSnap(this._id, this._data);

  @override
  T? data() => _data;

  @override
  bool get exists => _data != null;

  @override
  String get id => _id;
}

class _FakeTransaction extends Fake implements Transaction {
  final Map<String, Map<String, dynamic>> _store;

  _FakeTransaction(this._store);

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) {
    final id = documentReference.id;
    final data = _store[id];
    return Future.value(_FakeGenericSnap<T>(id, data as T?));
  }

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    final id = documentReference.id;
    final existing = _store[id] ?? <String, dynamic>{};
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    if (options != null && options.merge == true) {
      final merged = Map<String, dynamic>.from(existing)..addAll(map);
      _store[id] = merged;
    } else {
      _store[id] = Map<String, dynamic>.from(map);
    }
    return this;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineMiningCache', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await OfflineMiningCache.init();
    });

    test('save and load user doc with checksum', () async {
      const uid = 'user1';
      final doc = {'totalPoints': 100.0, 'hourlyRate': 1.0};

      await OfflineMiningCache.saveUserDoc(uid, doc);
      final loaded = await OfflineMiningCache.loadUserDoc(uid);

      expect(loaded, isNotNull);
      expect(loaded!['totalPoints'], 100.0);
      expect(loaded['hourlyRate'], 1.0);
    });
  });

  group('OfflineMiningEngine', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await OfflineMiningCache.init();
    });

    test('simulateFromCache updates totalPoints based on time and rate', () {
      final engine = OfflineMiningEngine(_FakeFirestore());
      final now = DateTime(2025, 1, 1, 12);
      final start = DateTime(2025, 1, 1, 10);

      final cached = {
        'totalPoints': 0.0,
        'hourlyRate': 2.0,
        'lastMiningStart': Timestamp.fromDate(start),
        'lastMiningEnd': null,
      };

      final simulated = engine.simulateFromCache(cached, now);
      expect(simulated['totalPoints'], closeTo(4.0, 0.0001));
    });

    test('reloadFromRemote fetches user and writes to cache', () async {
      final fake = _FakeFirestore();
      fake._users['u1'] = {'totalPoints': 10.0, 'hourlyRate': 1.5};
      final engine = OfflineMiningEngine(fake);

      final loaded = await engine.reloadFromRemote('u1');
      expect(loaded['totalPoints'], 10.0);

      final cached = await OfflineMiningCache.loadUserDoc('u1');
      expect(cached, isNotNull);
      expect(cached!['hourlyRate'], 1.5);
    });
  });

  group('OfflineMiningSyncQueue', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await OfflineMiningCache.init();
    });

    test('enqueue stores unsynced earned locally', () async {
      await OfflineMiningSyncQueue.enqueueMiningDelta(
        uid: 'u1',
        delta: 5.0,
        localBefore: 0.0,
        localAfter: 5.0,
      );

      final prefs = await SharedPreferences.getInstance();
      final key = 'offline_unsynced_earned_u1';
      expect(prefs.getDouble(key), 5.0);
    });
  });

  group('MiningBatchCommitEngine', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await OfflineMiningCache.init();
      final prefs = await SharedPreferences.getInstance();
      final master = {
        FirestoreAppConfigDocs.general: {
          FirestoreAppConfigFields.baseRate: 1.0,
          FirestoreAppConfigFields.sessionDurationHours: 24.0,
        },
        FirestoreAppConfigDocs.referrals: {
          FirestoreReferralConfigFields.referrerPercentPerReferral: 0.5,
          FirestoreReferralConfigFields.referralBonusTiers: {
            '0': 0.0,
            '10': 0.5,
            '20': 0.4,
            '100': 0.2,
          },
          FirestoreReferralConfigFields.rewardedReferralMaxCount: 100,
        },
        FirestoreAppConfigDocs.streak: {
          FirestoreStreakConfigFields.maxStreakDays: 10,
          FirestoreStreakConfigFields.maxStreakMultiplier: 2.0,
          FirestoreAppConfigFields.streakBonusTable: {
            '1': 1.0,
            '3': 1.2,
            '4': 1.3,
            '5': 1.5,
            '6': 1.6,
            '10': 2.0,
          },
        },
        FirestoreAppConfigDocs.ranks: {},
      };
      await prefs.setString('app_config_master_cache', jsonEncode(master));
      await prefs.setInt(
        'app_config_master_ts',
        DateTime.now().millisecondsSinceEpoch,
      );
    });

    test('startSession and finishSession perform single writes', () async {
      final fake = _FakeFirestore();
      fake._users['u1'] = {
        FirestoreUserFields.totalPoints: 100.0,
        FirestoreUserFields.rateAds: 0.0,
        FirestoreUserFields.rateManager: 0.0,
        FirestoreUserFields.rateReferral: 0.0,
        FirestoreUserFields.rateRank: 0.0,
        FirestoreUserFields.rateStreak: 0.0,
        FirestoreUserFields.streakDays: 0,
        FirestoreUserFields.totalInvited: 0,
      };

      MiningBatchCommitEngine.debugSetDbForTests(fake);

      final startRes = await MiningBatchCommitEngine.startSession(
        uid: 'u1',
        deviceId: 'dev1',
        maxEnd: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(startRes[FirestoreUserFields.totalPoints], 100.0);

      final finishRes = await MiningBatchCommitEngine.finishSession(
        uid: 'u1',
        forcedEnd: DateTime.now().add(const Duration(hours: 1)),
      );

      final total = finishRes[FirestoreUserFields.totalPoints] as double;
      expect(total, greaterThan(100.0));
    });

    test(
      'finishSession updates streakDays and totalSessions atomically',
      () async {
        final fake = _FakeFirestore();
        final now = DateTime.now().toUtc();
        const int msPerDay = 24 * 60 * 60 * 1000;
        final int yesterdayIndex =
            now.subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/
            msPerDay;

        fake._users['u1'] = {
          FirestoreUserFields.totalPoints: 0.0,
          FirestoreUserFields.rateAds: 0.0,
          FirestoreUserFields.rateManager: 0.0,
          FirestoreUserFields.rateReferral: 0.0,
          FirestoreUserFields.rateRank: 0.0,
          FirestoreUserFields.rateStreak: 0.0,
          FirestoreUserFields.streakDays: 3,
          FirestoreUserFields.streakLastUpdatedDay: yesterdayIndex,
          FirestoreUserFields.totalSessions: 5,
          FirestoreUserFields.lastMiningEnd:
              Timestamp.fromMillisecondsSinceEpoch(
                now.subtract(const Duration(hours: 23)).millisecondsSinceEpoch,
              ),
        };

        MiningBatchCommitEngine.debugSetDbForTests(fake);

        await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
          maxEnd: now.add(const Duration(hours: 1)),
        );

        final finishRes = await MiningBatchCommitEngine.finishSession(
          uid: 'u1',
          forcedEnd: now.add(const Duration(minutes: 30)),
        );

        final streak = finishRes[FirestoreUserFields.streakDays] as int;
        final sessions = finishRes[FirestoreUserFields.totalSessions] as int;

        expect(streak, 4);
        expect(sessions, 6);
      },
    );

    test(
      'streak bonus applies multipliers from config for various days',
      () async {
        Future<Map<String, dynamic>> runWithStreak(int previousStreak) async {
          final fake = _FakeFirestore();
          fake._users['u1'] = {
            FirestoreUserFields.totalPoints: 0.0,
            FirestoreUserFields.rateAds: 0.0,
            FirestoreUserFields.rateManager: 0.0,
            FirestoreUserFields.rateReferral: 0.0,
            FirestoreUserFields.rateRank: 0.0,
            FirestoreUserFields.rateStreak: 0.0,
            FirestoreUserFields.streakDays: previousStreak,
            FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 1)),
            ),
          };

          MiningBatchCommitEngine.debugSetDbForTests(fake);

          final res = await MiningBatchCommitEngine.startSession(
            uid: 'u1',
            deviceId: 'dev1',
          );
          return res;
        }

        final s1 = await runWithStreak(0);
        final r1 =
            (s1[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
        final h1 =
            (s1[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

        final s3 = await runWithStreak(2);
        final r3 =
            (s3[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
        final h3 =
            (s3[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

        final s4 = await runWithStreak(3);
        final r4 =
            (s4[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
        final h4 =
            (s4[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

        final s5 = await runWithStreak(4);
        final r5 =
            (s5[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
        final h5 =
            (s5[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

        final s6 = await runWithStreak(5);
        final r6 =
            (s6[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
        final h6 =
            (s6[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

        final s11 = await runWithStreak(10);
        final r11 =
            (s11[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
        final h11 =
            (s11[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

        expect(r1, closeTo(0.0, 0.000001));
        expect(h1, closeTo(1.0, 0.000001));

        expect(r3, closeTo(0.2, 0.000001));
        expect(h3, closeTo(1.2, 0.000001));

        expect(r4, closeTo(0.3, 0.000001));
        expect(h4, closeTo(1.3, 0.000001));

        expect(r5, closeTo(0.5, 0.000001));
        expect(h5, closeTo(1.5, 0.000001));

        expect(r6, closeTo(0.6, 0.000001));
        expect(h6, closeTo(1.6, 0.000001));

        expect(r11, closeTo(1.0, 0.000001));
        expect(h11, closeTo(2.0, 0.000001));
      },
    );

    test(
      'referral rate depends only on totalInvited, not activeReferralCount',
      () async {
        final fake = _FakeFirestore();
        fake._users['u1'] = {
          FirestoreUserFields.totalPoints: 0.0,
          FirestoreUserFields.rateAds: 0.0,
          FirestoreUserFields.rateManager: 0.0,
          FirestoreUserFields.rateReferral: 0.0,
          FirestoreUserFields.rateRank: 0.0,
          FirestoreUserFields.rateStreak: 0.0,
          FirestoreUserFields.streakDays: 0,
          FirestoreUserFields.totalInvited: 100,
        };

        MiningBatchCommitEngine.debugSetDbForTests(fake);

        final firstStart = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
          activeReferralCount: 1,
        );

        final firstRate =
            firstStart[FirestoreUserFields.rateReferral] as double;
        expect(firstRate, greaterThan(0.0));

        fake._users['u1']![FirestoreUserFields.totalInvited] = 0;

        final secondStart = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
          activeReferralCount: 10,
        );

        final secondRate =
            secondStart[FirestoreUserFields.rateReferral] as double;
        expect(secondRate, equals(0.0));
      },
    );

    test(
      'missing or non-numeric totalInvited yields zero referral bonus',
      () async {
        final fake = _FakeFirestore();
        fake._users['u1'] = {
          FirestoreUserFields.totalPoints: 0.0,
          FirestoreUserFields.rateAds: 0.0,
          FirestoreUserFields.rateManager: 0.0,
          FirestoreUserFields.rateReferral: 0.0,
          FirestoreUserFields.rateRank: 0.0,
          FirestoreUserFields.rateStreak: 0.0,
          FirestoreUserFields.streakDays: 0,
        };

        MiningBatchCommitEngine.debugSetDbForTests(fake);

        final startMissing = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
        );

        final rateMissing =
            startMissing[FirestoreUserFields.rateReferral] as double;

        fake._users['u1']![FirestoreUserFields.totalInvited] = 'not-a-number';

        final startInvalid = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
        );

        final rateInvalid =
            startInvalid[FirestoreUserFields.rateReferral] as double;

        expect(rateMissing, equals(0.0));
        expect(rateInvalid, equals(0.0));
      },
    );

    test('referral tiers map totalInvited to deterministic bonus', () async {
      final fake = _FakeFirestore();
      fake._users['u1'] = {
        FirestoreUserFields.totalPoints: 0.0,
        FirestoreUserFields.rateAds: 0.0,
        FirestoreUserFields.rateManager: 0.0,
        FirestoreUserFields.rateReferral: 0.0,
        FirestoreUserFields.rateRank: 0.0,
        FirestoreUserFields.rateStreak: 0.0,
        FirestoreUserFields.streakDays: 0,
        FirestoreUserFields.totalInvited: 0,
      };

      MiningBatchCommitEngine.debugSetDbForTests(fake);

      final start0 = await MiningBatchCommitEngine.startSession(
        uid: 'u1',
        deviceId: 'dev1',
      );

      fake._users['u1']![FirestoreUserFields.totalInvited] = 10;

      final start10 = await MiningBatchCommitEngine.startSession(
        uid: 'u1',
        deviceId: 'dev1',
      );

      fake._users['u1']![FirestoreUserFields.totalInvited] = 100;

      final start100 = await MiningBatchCommitEngine.startSession(
        uid: 'u1',
        deviceId: 'dev1',
      );

      final r0 = start0[FirestoreUserFields.rateReferral] as double;
      final r10 = start10[FirestoreUserFields.rateReferral] as double;
      final r100 = start100[FirestoreUserFields.rateReferral] as double;

      expect(r0, closeTo(0.0, 0.000001));
      expect(r10, greaterThan(r0));
      expect(r100, greaterThan(r10));
    });

    test(
      'tier bonus uses config multiplier applied to base rate and hourlyRate',
      () async {
        final fake = _FakeFirestore();
        fake._users['u1'] = {
          FirestoreUserFields.totalPoints: 0.0,
          FirestoreUserFields.rateAds: 0.0,
          FirestoreUserFields.rateManager: 0.0,
          FirestoreUserFields.rateReferral: 0.0,
          FirestoreUserFields.rateRank: 0.0,
          FirestoreUserFields.rateStreak: 0.0,
          FirestoreUserFields.streakDays: 0,
          FirestoreUserFields.totalInvited: 0,
        };

        MiningBatchCommitEngine.debugSetDbForTests(fake);

        final start0 = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
        );

        fake._users['u1']![FirestoreUserFields.totalInvited] = 1;

        final start1 = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
        );

        fake._users['u1']![FirestoreUserFields.totalInvited] = 10;

        final start10 = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
        );

        fake._users['u1']![FirestoreUserFields.totalInvited] = 100;

        final start100 = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
        );

        double r(Map<String, dynamic> m) =>
            (m[FirestoreUserFields.rateReferral] as num?)?.toDouble() ?? 0.0;
        double h(Map<String, dynamic> m) =>
            (m[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

        final r0 = r(start0);
        final h0 = h(start0);
        final r1 = r(start1);
        final h1 = h(start1);
        final r10 = r(start10);
        final h10 = h(start10);
        final r100 = r(start100);
        final h100 = h(start100);

        expect(r0, closeTo(0.0, 0.000001));
        expect(h0, closeTo(1.0, 0.000001));

        expect(r1, closeTo(0.1, 0.000001));
        expect(h1, closeTo(1.1, 0.000001));

        expect(r10, closeTo(0.1, 0.000001));
        expect(h10, closeTo(1.1, 0.000001));

        expect(r100, closeTo(0.2, 0.000001));
        expect(h100, closeTo(1.2, 0.000001));
      },
    );

    test(
      'below first positive tier still receives tier-based referral bonus',
      () async {
        final fake = _FakeFirestore();
        fake._users['u1'] = {
          FirestoreUserFields.totalPoints: 0.0,
          FirestoreUserFields.rateAds: 0.0,
          FirestoreUserFields.rateManager: 0.0,
          FirestoreUserFields.rateReferral: 0.0,
          FirestoreUserFields.rateRank: 0.0,
          FirestoreUserFields.rateStreak: 0.0,
          FirestoreUserFields.streakDays: 0,
          FirestoreUserFields.totalInvited: 1,
        };

        MiningBatchCommitEngine.debugSetDbForTests(fake);

        final start1 = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
        );

        final r1 = start1[FirestoreUserFields.rateReferral] as double;

        expect(r1, greaterThan(0.0));
      },
    );

    test(
      'rewardedReferralMaxCount caps referral bonus at max referrals',
      () async {
        final fake = _FakeFirestore();
        fake._users['u1'] = {
          FirestoreUserFields.totalPoints: 0.0,
          FirestoreUserFields.rateAds: 0.0,
          FirestoreUserFields.rateManager: 0.0,
          FirestoreUserFields.rateReferral: 0.0,
          FirestoreUserFields.rateRank: 0.0,
          FirestoreUserFields.rateStreak: 0.0,
          FirestoreUserFields.streakDays: 0,
          FirestoreUserFields.totalInvited: 100,
        };

        MiningBatchCommitEngine.debugSetDbForTests(fake);

        final start100 = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
        );

        fake._users['u1']![FirestoreUserFields.totalInvited] = 150;

        final start150 = await MiningBatchCommitEngine.startSession(
          uid: 'u1',
          deviceId: 'dev1',
        );

        final r100 = start100[FirestoreUserFields.rateReferral] as double;
        final r150 = start150[FirestoreUserFields.rateReferral] as double;

        expect(r100, greaterThan(0.0));
        expect(r150, equals(r100));
      },
    );
  });
}
