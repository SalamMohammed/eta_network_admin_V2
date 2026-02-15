import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eta_network_admin/services/offline_mining_service.dart';

class _FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _users = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path != 'users') {
      throw UnimplementedError();
    }
    return _FakeCollection(_users);
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
    return Future.value(_FakeSnap(_id, data));
  }

  @override
  String get id => _id;
}

class _FakeSnap extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _data;

  _FakeSnap(this._id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => _id;
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
}
