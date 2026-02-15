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

    final userRef = db.collection('users').doc(uid);
    await db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final remote = snap.data() ?? <String, dynamic>{};

      final remoteTotalRaw = remote['totalPoints'];
      final localBeforeRaw = cached['totalPoints'];
      final localAfterRaw = simulated['totalPoints'];

      final double remoteTotal = remoteTotalRaw is num
          ? remoteTotalRaw.toDouble()
          : 0.0;
      final double localBefore = localBeforeRaw is num
          ? localBeforeRaw.toDouble()
          : 0.0;
      final double localAfter = localAfterRaw is num
          ? localAfterRaw.toDouble()
          : remoteTotal;

      final deltaSimulated = localAfter - localBefore;
      if (deltaSimulated < 0) {
        throw Exception('Negative simulated delta for $uid');
      }

      final expectedTotal = remoteTotal + deltaSimulated;

      final update = Map<String, dynamic>.from(simulated);
      update['totalPoints'] = expectedTotal;

      tx.set(userRef, update, SetOptions(merge: true));
    });

    await OfflineMiningCache.saveUserDoc(uid, simulated);
  }
}
