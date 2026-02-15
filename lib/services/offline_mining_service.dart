import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineMiningCache {
  static const _version = 1;
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String _key(String uid) => 'offline_mining_cache_v$_version\_$uid';

  static int _checksum(String json) {
    var sum = 0;
    for (final code in json.codeUnits) {
      sum = (sum + code) & 0x7fffffff;
    }
    return sum;
  }

  static Future<Map<String, dynamic>?> loadUserDoc(String uid) async {
    await init();
    final raw = _prefs!.getString(_key(uid));
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final storedChecksum = decoded['checksum'] as int?;
      final dataJson = decoded['user'] as String?;
      if (storedChecksum == null || dataJson == null) return null;
      if (_checksum(dataJson) != storedChecksum) return null;
      final userMap = json.decode(dataJson) as Map<String, dynamic>;
      return userMap;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUserDoc(
    String uid,
    Map<String, dynamic> userDoc,
  ) async {
    await init();
    final dataJson = json.encode(userDoc);
    final checksum = _checksum(dataJson);
    final envelope = <String, dynamic>{
      'version': _version,
      'checksum': checksum,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      'user': dataJson,
    };
    final raw = json.encode(envelope);
    final key = _key(uid);
    final ok = await _prefs!.setString(key, raw);
    if (!ok) {
      throw Exception('Failed to persist offline mining cache for $uid');
    }
  }

  static Future<void> clearUser(String uid) async {
    await init();
    await _prefs!.remove(_key(uid));
  }
}

class OfflineMiningSyncQueue {
  static const _queueKey = 'offline_mining_sync_queue_v1';
  static SharedPreferences? _prefs;
  static bool _processing = false;

  static Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Map<String, dynamic>>> _loadQueue() async {
    await _init();
    final raw = _prefs!.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    await _init();
    final encoded = json.encode(queue);
    await _prefs!.setString(_queueKey, encoded);
  }

  static Future<void> enqueueMiningDelta({
    required String uid,
    required double delta,
    required double localBefore,
    required double localAfter,
  }) async {
    if (delta == 0) return;
    final queue = await _loadQueue();
    final job = <String, dynamic>{
      'type': 'miningDelta',
      'uid': uid,
      'delta': delta,
      'localBefore': localBefore,
      'localAfter': localAfter,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
    };
    queue.add(job);
    await _saveQueue(queue);
  }

  static Future<void> processPendingJobs(FirebaseFirestore db) async {
    if (_processing) return;
    _processing = true;
    try {
      final queue = await _loadQueue();
      if (queue.isEmpty) return;
      final next = <Map<String, dynamic>>[];
      for (final job in queue) {
        final ok = await _processJob(db, job);
        if (!ok) {
          final attempts = (job['attempts'] as int?) ?? 0;
          job['attempts'] = attempts + 1;
          next.add(job);
        }
      }
      await _saveQueue(next);
    } finally {
      _processing = false;
    }
  }

  static Future<bool> _processJob(
    FirebaseFirestore db,
    Map<String, dynamic> job,
  ) async {
    final type = job['type'] as String?;
    if (type != 'miningDelta') return true;
    final uid = job['uid'] as String?;
    if (uid == null || uid.isEmpty) return true;
    final deltaRaw = job['delta'];
    final double delta = deltaRaw is num ? deltaRaw.toDouble() : 0.0;
    if (delta <= 0) return true;
    final userRef = db.collection('users').doc(uid);
    try {
      await db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final data = snap.data() ?? <String, dynamic>{};
        final remoteTotalRaw = data['totalPoints'];
        final double remoteTotal = remoteTotalRaw is num
            ? remoteTotalRaw.toDouble()
            : 0.0;
        final newTotal = remoteTotal + delta;
        final update = <String, dynamic>{
          'totalPoints': newTotal,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        tx.set(userRef, update, SetOptions(merge: true));
      });
      final cached = await OfflineMiningCache.loadUserDoc(uid);
      if (cached != null) {
        final totalRaw = cached['totalPoints'];
        final double localBase = totalRaw is num ? totalRaw.toDouble() : 0.0;
        final updated = Map<String, dynamic>.from(cached);
        updated['totalPoints'] = localBase + delta;
        await OfflineMiningCache.saveUserDoc(uid, updated);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

class OfflineMiningEngine {
  final FirebaseFirestore db;

  OfflineMiningEngine(this.db);

  Future<Map<String, dynamic>> ensureCachedUser(String uid) async {
    final cached = await OfflineMiningCache.loadUserDoc(uid);
    if (cached != null) return cached;
    return reloadFromRemote(uid);
  }

  Future<Map<String, dynamic>> reloadFromRemote(String uid) async {
    final snap = await db.collection('users').doc(uid).get();
    final data = snap.data() ?? <String, dynamic>{};
    await OfflineMiningCache.saveUserDoc(uid, data);
    return data;
  }

  Map<String, dynamic> simulateFromCache(
    Map<String, dynamic> cachedUser,
    DateTime now,
  ) {
    final cloned = Map<String, dynamic>.from(cachedUser);

    final lastStartRaw = cloned['lastMiningStart'];
    final lastEndRaw = cloned['lastMiningEnd'];
    final hourlyRateRaw = cloned['hourlyRate'];

    DateTime? lastStart;
    DateTime? lastEnd;
    double hourlyRate = 0.0;

    if (lastStartRaw is Timestamp) {
      lastStart = lastStartRaw.toDate();
    }
    if (lastEndRaw is Timestamp) {
      lastEnd = lastEndRaw.toDate();
    }
    if (hourlyRateRaw is num) {
      hourlyRate = hourlyRateRaw.toDouble();
    }

    final totalPointsRaw = cloned['totalPoints'];
    double baseTotal = 0.0;
    if (totalPointsRaw is num) {
      baseTotal = totalPointsRaw.toDouble();
    }

    if (lastStart != null && hourlyRate > 0) {
      final effectiveEnd = lastEnd != null && now.isAfter(lastEnd)
          ? lastEnd
          : now;
      if (effectiveEnd.isAfter(lastStart)) {
        final elapsedHours =
            effectiveEnd.difference(lastStart).inMilliseconds /
            (1000 * 60 * 60);
        final earned = elapsedHours * hourlyRate;
        cloned['totalPoints'] = baseTotal + earned;
      }
    }

    final wallet = cloned['wallet'];
    if (wallet is Map<String, dynamic>) {
      final coins = wallet['coins'];
      if (coins is Map<String, dynamic>) {
        coins.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _simulateCoin(value, now);
          }
        });
      }
    }

    return cloned;
  }

  void _simulateCoin(Map<String, dynamic> coin, DateTime now) {
    final startRaw = coin['lastMiningStart'];
    final endRaw = coin['lastMiningEnd'];
    final rateRaw = coin['hourlyRate'];
    final totalRaw = coin['totalPoints'];

    DateTime? start;
    DateTime? end;
    double rate = 0.0;
    double baseTotal = 0.0;

    if (startRaw is Timestamp) {
      start = startRaw.toDate();
    }
    if (endRaw is Timestamp) {
      end = endRaw.toDate();
    }
    if (rateRaw is num) {
      rate = rateRaw.toDouble();
    }
    if (totalRaw is num) {
      baseTotal = totalRaw.toDouble();
    }

    if (start != null && rate > 0) {
      final effectiveEnd = end != null && now.isAfter(end) ? end : now;
      if (effectiveEnd.isAfter(start)) {
        final elapsedHours =
            effectiveEnd.difference(start).inMilliseconds / (1000 * 60 * 60);
        final earned = elapsedHours * rate;
        coin['totalPoints'] = baseTotal + earned;
      }
    }
  }

  Future<void> persistSimulation(
    String uid,
    Map<String, dynamic> simulatedUser,
  ) {
    return OfflineMiningCache.saveUserDoc(uid, simulatedUser);
  }

  Future<void> finalizeSessionAndSync(String uid) async {
    final cached = await OfflineMiningCache.loadUserDoc(uid);
    if (cached == null) {
      return;
    }

    final simulated = simulateFromCache(cached, DateTime.now());

    final localBeforeRaw = cached['totalPoints'];
    final localAfterRaw = simulated['totalPoints'];

    final double localBefore = localBeforeRaw is num
        ? localBeforeRaw.toDouble()
        : 0.0;
    final double localAfter = localAfterRaw is num
        ? localAfterRaw.toDouble()
        : localBefore;

    final deltaSimulated = localAfter - localBefore;
    if (deltaSimulated < 0) {
      throw Exception('Negative simulated delta for $uid');
    }

    await OfflineMiningCache.saveUserDoc(uid, simulated);

    if (deltaSimulated == 0) {
      return;
    }

    await OfflineMiningSyncQueue.enqueueMiningDelta(
      uid: uid,
      delta: deltaSimulated,
      localBefore: localBefore,
      localAfter: localAfter,
    );

    await OfflineMiningSyncQueue.processPendingJobs(db);
  }
}
