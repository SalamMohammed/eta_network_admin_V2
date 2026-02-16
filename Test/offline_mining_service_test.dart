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

    test('totalInvited influences referral rate when activeReferralCount provided', () async {
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

      final lowInvitedStart = await MiningBatchCommitEngine.startSession(
        uid: 'u1',
        deviceId: 'dev1',
        activeReferralCount: 1,
      );

      final lowRate = lowInvitedStart[FirestoreUserFields.rateReferral] as double;
      expect(lowRate, greaterThan(0.0));

      fake._users['u1']![FirestoreUserFields.totalInvited] = 0;

      final noInvitedStart = await MiningBatchCommitEngine.startSession(
        uid: 'u1',
        deviceId: 'dev1',
        activeReferralCount: 1,
      );

      final noRate = noInvitedStart[FirestoreUserFields.rateReferral] as double;
      expect(noRate, greaterThan(0.0));
      expect(lowRate, greaterThan(noRate));
    });

    test('missing or non-numeric totalInvited treated as zero', () async {
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
        activeReferralCount: 1,
      );

      final rateMissing = startMissing[FirestoreUserFields.rateReferral] as double;

      fake._users['u1']![FirestoreUserFields.totalInvited] = 'not-a-number';

      final startInvalid = await MiningBatchCommitEngine.startSession(
        uid: 'u1',
        deviceId: 'dev1',
        activeReferralCount: 1,
      );

      final rateInvalid = startInvalid[FirestoreUserFields.rateReferral] as double;

      expect(rateMissing, greaterThan(0.0));
      expect(rateInvalid, closeTo(rateMissing, 0.0001));
    });
  });
}
