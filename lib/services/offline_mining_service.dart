import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/firestore_constants.dart';
import 'config_service.dart';
import 'rank_engine.dart';

class OfflineMiningUserLock {
  static final Map<String, Future<void>> _tails = {};

  static Future<T> runLocked<T>(String uid, Future<T> Function() action) {
    final previous = _tails[uid] ?? Future.value();
    final completer = Completer<void>();
    final current = previous.then((_) => completer.future);
    _tails[uid] = current;
    return previous.then((_) async {
      try {
        final result = await action();
        completer.complete();
        if (identical(_tails[uid], current)) {
          _tails.remove(uid);
        }
        return result;
      } catch (e, st) {
        completer.complete();
        if (identical(_tails[uid], current)) {
          _tails.remove(uid);
        }
        Error.throwWithStackTrace(e, st);
      }
    });
  }
}

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
    final dataJson = json.encode(_toJsonSafe(userDoc));
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

  static Map<String, dynamic> _toJsonSafe(Map<String, dynamic> data) {
    final Map<String, dynamic> out = {};
    data.forEach((key, value) {
      out[key] = _toJsonSafeValue(value);
    });
    return out;
  }

  static dynamic _toJsonSafeValue(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is Map) {
      return _toJsonSafe(Map<String, dynamic>.from(value as Map));
    }
    if (value is List) {
      return value.map(_toJsonSafeValue).toList();
    }
    return value;
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
      final list = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (list.isEmpty) {
        return [];
      }
      await _prefs!.remove(_queueKey);
      return [];
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
    await _init();
    final key = 'offline_unsynced_earned_$uid';
    final existing = _prefs!.getDouble(key) ?? 0.0;
    await _prefs!.setDouble(key, existing + delta);
  }

  static Future<void> processPendingJobs(FirebaseFirestore db) async {
    if (_processing) return;
    _processing = true;
    try {
      final queue = await _loadQueue();
      if (queue.isEmpty) return;
      final next = <Map<String, dynamic>>[];
      for (final job in queue) {
        final uid = job['uid'] as String?;
        if (uid == null || uid.isEmpty) {
          continue;
        }
        final ok = await OfflineMiningUserLock.runLocked<bool>(
          uid,
          () => _processJobUnlocked(db, job),
        );
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

  static Future<bool> _processJobUnlocked(
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
      final batch = db.batch();
      final update = <String, dynamic>{
        'totalPoints': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(userRef, update, SetOptions(merge: true));
      await batch.commit();
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

class MiningSessionState {
  final String uid;
  final DateTime startTime;
  final DateTime plannedEnd;
  final double startTotalPoints;
  final int totalInvited;
  final double rateBase;
  final double rateStreak;
  final double rateRank;
  final double rateReferral;
  final double rateManager;
  final double rateAds;
  final double hourlyRate;
  final int streakDays;
  bool finished;

  MiningSessionState({
    required this.uid,
    required this.startTime,
    required this.plannedEnd,
    required this.startTotalPoints,
    required this.totalInvited,
    required this.rateBase,
    required this.rateStreak,
    required this.rateRank,
    required this.rateReferral,
    required this.rateManager,
    required this.rateAds,
    required this.hourlyRate,
    required this.streakDays,
    this.finished = false,
  });
}

class _MiningConfig {
  final double baseRate;
  final double durationHours;
  final Map<String, dynamic> streakConfig;
  final Map<String, dynamic> ranksConfig;
  final Map<String, dynamic> referralConfig;
  final double maxReferralBonusRate;
  final int rewardedReferralMaxCount;

  _MiningConfig({
    required this.baseRate,
    required this.durationHours,
    required this.streakConfig,
    required this.ranksConfig,
    required this.referralConfig,
    required this.maxReferralBonusRate,
    required this.rewardedReferralMaxCount,
  });
}

class MiningBatchCommitEngine {
  static FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Map<String, MiningSessionState> _sessions = {};

  static void debugSetDbForTests(FirebaseFirestore db) {
    _db = db;
  }

  static MiningSessionState? getSession(String uid) {
    return _sessions[uid];
  }

  static void _logReferral(
    String opId,
    String uid,
    String message, {
    int indent = 0,
  }) {
    final ts = DateTime.now().toIso8601String();
    final prefix = ' ' * (indent * 2);
    debugPrint('[$ts][REF][$opId][$uid] $prefix$message');
  }

  static Future<_MiningConfig> _loadMiningConfig(
    String opId,
    String uid,
  ) async {
    final startedAt = DateTime.now();
    final cfg = ConfigService();
    _logReferral(opId, uid, 'BEGIN config load for mining session', indent: 0);
    final appConfig = await cfg.getGeneralConfig(forceRefresh: true);
    final streakConfig = await cfg.getStreakConfig(forceRefresh: true);
    final ranksConfig = await cfg.getRanksConfig(forceRefresh: true);
    final referralConfig = await cfg.getReferralConfig(forceRefresh: true);

    final double baseRate =
        (appConfig[FirestoreAppConfigFields.baseRate] as num?)?.toDouble() ??
        0.2;
    final double durationHours =
        (appConfig[FirestoreAppConfigFields.sessionDurationHours] as num?)
            ?.toDouble() ??
        24.0;
    final double maxBonusRate =
        (appConfig[FirestoreAppConfigFields.maxReferralBonusRate] as num?)
            ?.toDouble() ??
        0.0;
    final int rewardedMaxRefs =
        (referralConfig[FirestoreReferralConfigFields.rewardedReferralMaxCount]
                as num?)
            ?.toInt() ??
        0;

    if (referralConfig.isEmpty) {
      _logReferral(
        opId,
        uid,
        'referral config missing; referral bonus disabled for mining sessions',
        indent: 1,
      );
    }

    _logReferral(
      opId,
      uid,
      'config values: baseRate=$baseRate ETA/hr, durationHours=$durationHours h, maxReferralBonusRate=$maxBonusRate ETA/hr, rewardedReferralMaxCount=$rewardedMaxRefs, tiers=${referralConfig[FirestoreReferralConfigFields.referralBonusTiers]}',
      indent: 1,
    );

    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    _logReferral(
      opId,
      uid,
      'END config load (elapsed=${elapsedMs}ms)',
      indent: 0,
    );

    return _MiningConfig(
      baseRate: baseRate,
      durationHours: durationHours,
      streakConfig: streakConfig,
      ranksConfig: ranksConfig,
      referralConfig: referralConfig,
      maxReferralBonusRate: maxBonusRate,
      rewardedReferralMaxCount: rewardedMaxRefs,
    );
  }

  static double _computeReferralBonus({
    required int totalInvited,
    required Map<String, dynamic> referralConfig,
    required double baseRate,
    required double maxBonusRate,
    required int maxRefs,
    required String uid,
    required String opId,
  }) {
    final startedAt = DateTime.now();
    _logReferral(opId, uid, 'BEGIN referral calculation', indent: 0);
    _logReferral(
      opId,
      uid,
      'inputs: totalInvited=$totalInvited invites, baseRate=$baseRate ETA/hr, maxBonusRate=$maxBonusRate ETA/hr, rewardedReferralMaxCount=$maxRefs referrals',
      indent: 1,
    );

    if (totalInvited <= 0) {
      _logReferral(
        opId,
        uid,
        'branch: totalInvited <= 0 → skip referral bonus',
        indent: 1,
      );
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      _logReferral(
        opId,
        uid,
        'END referral calculation (rateReferral=0.0 ETA/hr, elapsed=${elapsedMs}ms)',
        indent: 0,
      );
      return 0.0;
    }

    int effectiveInvites = totalInvited;
    if (maxRefs > 0 && effectiveInvites > maxRefs) {
      effectiveInvites = maxRefs;
    }
    _logReferral(
      opId,
      uid,
      'effectiveInvites=$effectiveInvites referrals after maxRefs cap',
      indent: 1,
    );

    final tiersRaw =
        referralConfig[FirestoreReferralConfigFields.referralBonusTiers];
    if (tiersRaw is! Map<String, dynamic> || tiersRaw.isEmpty) {
      _logReferral(
        opId,
        uid,
        'no referralBonusTiers configured or empty',
        indent: 1,
      );
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      _logReferral(
        opId,
        uid,
        'END referral calculation (rateReferral=0.0 ETA/hr, elapsed=${elapsedMs}ms)',
        indent: 0,
      );
      return 0.0;
    }

    _logReferral(
      opId,
      uid,
      'evaluating referralBonusTiers=$tiersRaw',
      indent: 1,
    );

    int? selectedThreshold;
    double? selectedPercent;
    int? highestThreshold;
    double? highestPercent;

    tiersRaw.forEach((key, value) {
      final threshold = int.tryParse(key);
      if (threshold == null) {
        return;
      }
      final raw = (value as num?)?.toDouble();
      if (raw == null) {
        return;
      }
      double p = raw;
      if (p > 1.0) {
        p = p / 100.0;
      }
      if (p <= 0.0) {
        return;
      }
      _logReferral(
        opId,
        uid,
        'tier candidate: threshold=$threshold invites, normalizedPercent=$p',
        indent: 2,
      );
      if (highestThreshold == null || threshold > highestThreshold!) {
        highestThreshold = threshold;
        highestPercent = p;
      }
      if (effectiveInvites <= threshold) {
        if (selectedThreshold == null || threshold < selectedThreshold!) {
          selectedThreshold = threshold;
          selectedPercent = p;
        }
      }
    });

    double? tierPercent;
    int? tierThreshold;
    if (selectedThreshold != null && selectedPercent != null) {
      tierThreshold = selectedThreshold;
      tierPercent = selectedPercent;
    } else if (highestThreshold != null && highestPercent != null) {
      tierThreshold = highestThreshold;
      tierPercent = highestPercent;
    }

    if (tierPercent == null || tierThreshold == null) {
      _logReferral(
        opId,
        uid,
        'branch: no valid tier found → referral bonus = 0',
        indent: 1,
      );
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      _logReferral(
        opId,
        uid,
        'END referral calculation (rateReferral=0.0 ETA/hr, elapsed=${elapsedMs}ms)',
        indent: 0,
      );
      return 0.0;
    }

    _logReferral(
      opId,
      uid,
      'selected tier: threshold=$tierThreshold invites, multiplierPercent=$tierPercent',
      indent: 1,
    );

    double rateReferral = baseRate * tierPercent;
    _logReferral(
      opId,
      uid,
      'formula (tier): rateReferral = baseRate($baseRate ETA/hr) × tierPercent($tierPercent)',
      indent: 1,
    );

    if (maxBonusRate > 0.0 && rateReferral > maxBonusRate) {
      rateReferral = maxBonusRate;
      _logReferral(
        opId,
        uid,
        'cap applied: maxReferralBonusRate=$maxBonusRate ETA/hr, final rateReferral=$rateReferral ETA/hr',
        indent: 1,
      );
    } else {
      _logReferral(
        opId,
        uid,
        'no cap applied: maxReferralBonusRate=$maxBonusRate ETA/hr',
        indent: 1,
      );
    }

    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    _logReferral(
      opId,
      uid,
      'END referral calculation (rateReferral=$rateReferral ETA/hr, elapsed=${elapsedMs}ms)',
      indent: 0,
    );

    return rateReferral;
  }

  static void applyAdBoost({required String uid, required double boostAmount}) {
    if (boostAmount <= 0) {
      return;
    }
    final session = _sessions[uid];
    if (session == null || session.finished) {
      return;
    }
    final now = DateTime.now();
    DateTime newStartTime = session.startTime;
    double newStartTotalPoints = session.startTotalPoints;
    if (now.isAfter(session.startTime)) {
      final elapsedHours =
          now.difference(session.startTime).inMilliseconds / (1000 * 60 * 60);
      final earnedAtOldRate = elapsedHours * session.hourlyRate;
      if (earnedAtOldRate > 0) {
        newStartTotalPoints += earnedAtOldRate;
      }
      newStartTime = now;
    }
    final newRateAds = session.rateAds + boostAmount;
    final newHourlyRate =
        session.rateBase +
        session.rateRank +
        session.rateStreak +
        session.rateReferral +
        session.rateManager +
        newRateAds;
    _sessions[uid] = MiningSessionState(
      uid: session.uid,
      startTime: newStartTime,
      plannedEnd: session.plannedEnd,
      startTotalPoints: newStartTotalPoints,
      totalInvited: session.totalInvited,
      rateBase: session.rateBase,
      rateStreak: session.rateStreak,
      rateRank: session.rateRank,
      rateReferral: session.rateReferral,
      rateManager: session.rateManager,
      rateAds: newRateAds,
      hourlyRate: newHourlyRate,
      streakDays: session.streakDays,
      finished: session.finished,
    );
  }

  static double applyAdPercentBoost({
    required String uid,
    required double percent,
  }) {
    if (percent <= 0) {
      return 0.0;
    }
    final session = _sessions[uid];
    if (session == null || session.finished) {
      return 0.0;
    }
    final baseRate = session.rateBase;
    if (baseRate <= 0) {
      return 0.0;
    }
    final frac = (percent / 100.0).clamp(0.0, 1e6);
    final boostAmount = baseRate * frac;
    if (boostAmount <= 0) {
      return 0.0;
    }
    applyAdBoost(uid: uid, boostAmount: boostAmount);
    return boostAmount;
  }

  static Future<Map<String, dynamic>> startSession({
    required String uid,
    String? deviceId,
    DateTime? maxEnd,
    Map<String, dynamic>? cachedManagerData,
    String? cachedManagerId,
    int? activeReferralCount,
  }) async {
    final opId = 'start-$uid-${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('[MiningBatchCommitEngine] op=$opId startSession call uid=$uid');
    return OfflineMiningUserLock.runLocked(uid, () async {
      _logReferral(
        opId,
        uid,
        'START mining session: preparing config and user data',
        indent: 0,
      );
      final miningConfig = await _loadMiningConfig(opId, uid);
      final double baseRate = miningConfig.baseRate;
      final double durationHours = miningConfig.durationHours;
      final streakConfig = miningConfig.streakConfig;
      final ranksConfig = miningConfig.ranksConfig;
      final refConfig = miningConfig.referralConfig;
      final double maxBonusRate = miningConfig.maxReferralBonusRate;
      final int maxRefs = miningConfig.rewardedReferralMaxCount;

      final userRef = _db.collection(FirestoreConstants.users).doc(uid);
      final now = DateTime.now();
      DateTime plannedEnd = now.add(
        Duration(minutes: (durationHours * 60).toInt()),
      );
      if (maxEnd != null && maxEnd.isBefore(plannedEnd)) {
        plannedEnd = maxEnd;
      }

      final result = await _db.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          return <String, dynamic>{};
        }
        final userData = userSnap.data() ?? <String, dynamic>{};

        int totalInvited = 0;
        final totalInvitedRaw = userData[FirestoreUserFields.totalInvited];
        if (totalInvitedRaw is num) {
          totalInvited = totalInvitedRaw.toInt();
        } else if (totalInvitedRaw != null) {
          debugPrint(
            '[MiningBatchCommitEngine] non-numeric totalInvited for $uid: $totalInvitedRaw',
          );
        }
        _logReferral(
          opId,
          uid,
          'user data: totalInvitedRaw=$totalInvitedRaw, totalInvitedParsed=$totalInvited',
          indent: 1,
        );

        final int previousStreakDays =
            (userData[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;
        final String storedRank =
            (userData[FirestoreUserFields.rank] as String?) ??
            FirestoreUserRanks.explorer;
        final Map<String, dynamic> rankRules =
            (ranksConfig[FirestoreRankConfigFields.rankRules]
                as Map<String, dynamic>?) ??
            {};
        final Map<String, dynamic> rankMults =
            (ranksConfig[FirestoreRankConfigFields.rankMultipliers]
                as Map<String, dynamic>?) ??
            {};

        String effectiveRank = storedRank;
        if (activeReferralCount != null &&
            rankRules.isNotEmpty &&
            rankMults.isNotEmpty) {
          effectiveRank = RankEngine.getBestRank(
            streakDays: previousStreakDays,
            activeReferrals: activeReferralCount,
            ranksCfg: ranksConfig,
            currentRank: storedRank,
          );
        }

        double rankMultiplier =
            (rankMults[effectiveRank] as num?)?.toDouble() ?? 1.0;
        if (rankMultiplier <= 0.0) {
          rankMultiplier = 1.0;
        }
        final double rateRank = baseRate * (rankMultiplier - 1.0);

        final lastEndTs =
            userData[FirestoreUserFields.lastMiningEnd] as Timestamp?;
        final int msPerDay = 24 * 60 * 60 * 1000;
        int sessionStreakDays = 0;
        if (lastEndTs != null) {
          final diffMs = now.difference(lastEndTs.toDate()).inMilliseconds;
          if (diffMs >= 0 && diffMs < msPerDay) {
            sessionStreakDays = previousStreakDays + 1;
          }
        }

        double rateStreak = 0.0;
        if (sessionStreakDays > 0) {
          rateStreak = _computeStreakRate(
            streakConfig: streakConfig,
            sessionStreakDays: sessionStreakDays,
            baseRate: baseRate,
            uid: uid,
            opId: opId,
          );
        }

        final double rateReferral = _computeReferralBonus(
          totalInvited: totalInvited,
          referralConfig: refConfig,
          baseRate: baseRate,
          maxBonusRate: maxBonusRate,
          maxRefs: maxRefs,
          uid: uid,
          opId: opId,
        );

        double rateManager = 0.0;
        double managerBonusPerHour = 0.0;

        final bool managerEnabled =
            (userData[FirestoreUserFields.managerEnabled] as bool?) ?? false;
        final String? activeManagerId =
            userData[FirestoreUserFields.activeManagerId] as String?;

        if (!managerEnabled ||
            activeManagerId == null ||
            activeManagerId.isEmpty) {
          debugPrint(
            '[MiningBatchCommitEngine] op=$opId manager inactive uid=$uid enabled=$managerEnabled managerId=$activeManagerId',
          );
        } else {
          final managerRef = _db
              .collection(FirestoreConstants.managers)
              .doc(activeManagerId);
          final managerSnap = await transaction.get(managerRef);
          final managerData = managerSnap.data() ?? <String, dynamic>{};
          final double rawMultiplier =
              (managerData[FirestoreManagerFields.managerMultiplier] as num?)
                  ?.toDouble() ??
              0.0;
          if (rawMultiplier <= 0.0) {
            debugPrint(
              '[MiningBatchCommitEngine] op=$opId manager multiplier missing or zero uid=$uid managerId=$activeManagerId raw=$rawMultiplier',
            );
          } else {
            double clamped = rawMultiplier;
            if (clamped < 0.1) {
              clamped = 0.1;
            } else if (clamped > 10.0) {
              clamped = 10.0;
            }
            managerBonusPerHour = baseRate * (clamped - 1.0);
            rateManager = managerBonusPerHour;
            debugPrint(
              '[MiningBatchCommitEngine] op=$opId manager bonus uid=$uid managerId=$activeManagerId multiplier=$clamped baseRate=$baseRate bonusPerHour=$managerBonusPerHour',
            );
          }
        }

        final List<String> managedCoinSelections =
            (userData[FirestoreUserFields.managedCoinSelections] as List?)
                ?.cast<String>() ??
            <String>[];

        final double rateAds = 0.0;

        final double newHourlyRate =
            baseRate +
            rateRank +
            rateStreak +
            rateReferral +
            rateManager +
            rateAds;

        debugPrint(
          '[MiningBatchCommitEngine] op=$opId rate mix uid=$uid base=$baseRate streak=$rateStreak rank=$rateRank referral=$rateReferral manager=$rateManager ads=$rateAds hourly=$newHourlyRate',
        );

        final Map<String, dynamic> writeData = {
          FirestoreUserFields.totalInvited: totalInvited,
          FirestoreUserFields.rateBase: baseRate,
          FirestoreUserFields.rateRank: rateRank,
          FirestoreUserFields.rateStreak: rateStreak,
          FirestoreUserFields.rateReferral: rateReferral,
          FirestoreUserFields.rateManager: rateManager,
          FirestoreUserFields.rateAds: rateAds,
          FirestoreUserFields.hourlyRate: newHourlyRate,
          FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
          FirestoreUserFields.rank: effectiveRank,
          FirestoreUserFields.lastMiningStart: Timestamp.fromDate(now),
          FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(plannedEnd),
          FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(now),
          FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
        };
        if (managedCoinSelections.isNotEmpty) {
          writeData[FirestoreUserFields.managedCoinSelections] =
              managedCoinSelections;
        }
        if (deviceId != null) {
          writeData[FirestoreUserFields.deviceId] = deviceId;
        }

        transaction.set(userRef, writeData, SetOptions(merge: true));

        final double totalPoints =
            (userData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            0.0;

        final debug = <String, dynamic>{
          'baseRate': baseRate,
          'streakBonus': rateStreak,
          'rankBonus': rateRank,
          'referralBonus': rateReferral,
          'managerBonus': rateManager,
          'hourlyRate': newHourlyRate,
          'totalInvited': totalInvited,
          'sessionStreakDays': sessionStreakDays,
        };

        return {
          ...writeData,
          'debug': debug,
          FirestoreUserFields.totalPoints: totalPoints,
          FirestoreUserFields.streakDays: sessionStreakDays,
        };
      });

      if (result.isEmpty) {
        return result;
      }

      final session = MiningSessionState(
        uid: uid,
        startTime: now,
        plannedEnd: plannedEnd,
        startTotalPoints:
            (result[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            0.0,
        totalInvited:
            (result[FirestoreUserFields.totalInvited] as num?)?.toInt() ?? 0,
        rateBase:
            (result[FirestoreUserFields.rateBase] as num?)?.toDouble() ?? 0.0,
        rateStreak:
            (result[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0,
        rateRank:
            (result[FirestoreUserFields.rateRank] as num?)?.toDouble() ?? 0.0,
        rateReferral:
            (result[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
            0.0,
        rateManager:
            (result[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
            0.0,
        rateAds:
            (result[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0,
        hourlyRate:
            (result[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0,
        streakDays:
            (result[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0,
      );
      _sessions[uid] = session;

      debugPrint(
        '[MiningBatchCommitEngine] op=$opId startSession committed uid=$uid start=${now.toIso8601String()} end=${plannedEnd.toIso8601String()}',
      );

      return result;
    });
  }

  static double _computeStreakRate({
    required Map<String, dynamic> streakConfig,
    required int sessionStreakDays,
    required double baseRate,
    required String uid,
    required String opId,
  }) {
    if (sessionStreakDays <= 0) {
      return 0.0;
    }
    final Map<String, dynamic> streakTable =
        (streakConfig[FirestoreAppConfigFields.streakBonusTable]
            as Map<String, dynamic>?) ??
        {};
    final int maxStreakDays =
        (streakConfig[FirestoreStreakConfigFields.maxStreakDays] as num?)
            ?.toInt() ??
        0;
    final double maxStreakMult =
        (streakConfig[FirestoreStreakConfigFields.maxStreakMultiplier] as num?)
            ?.toDouble() ??
        1.0;

    double streakMultiplier = 1.0;

    if (streakTable.isNotEmpty) {
      if (maxStreakDays > 0 &&
          maxStreakMult > 1.0 &&
          sessionStreakDays > maxStreakDays) {
        streakMultiplier = maxStreakMult;
      } else {
        double? bestKey;
        for (final entry in streakTable.entries) {
          final k = int.tryParse(entry.key);
          if (k == null) continue;
          if (k <= sessionStreakDays) {
            final v = (entry.value as num?)?.toDouble() ?? 1.0;
            if (bestKey == null || k > bestKey) {
              bestKey = k.toDouble();
              streakMultiplier = v;
            }
          }
        }
      }
    } else if (maxStreakDays > 0 && maxStreakMult > 1.0) {
      if (sessionStreakDays >= maxStreakDays) {
        streakMultiplier = maxStreakMult;
      } else {
        final double fraction = sessionStreakDays / maxStreakDays;
        streakMultiplier = 1.0 + (maxStreakMult - 1.0) * fraction;
      }
    }

    if (streakMultiplier <= 1.0) {
      debugPrint(
        '[MiningBatchCommitEngine] op=$opId streak uid=$uid days=$sessionStreakDays multiplier=$streakMultiplier bonusPerHour=0.0',
      );
      return 0.0;
    }

    final double rateStreak = baseRate * (streakMultiplier - 1.0);
    debugPrint(
      '[MiningBatchCommitEngine] op=$opId streak uid=$uid days=$sessionStreakDays maxDays=$maxStreakDays multiplier=$streakMultiplier bonusPerHour=$rateStreak',
    );
    return rateStreak;
  }

  static Future<Map<String, dynamic>> finishSession({
    required String uid,
    DateTime? forcedEnd,
  }) async {
    final opId = 'finish-$uid-${DateTime.now().millisecondsSinceEpoch}';
    debugPrint(
      '[MiningBatchCommitEngine] op=$opId finishSession call uid=$uid',
    );
    return OfflineMiningUserLock.runLocked(uid, () async {
      final session = _sessions[uid];
      if (session == null || session.finished) {
        return {};
      }

      final now = forcedEnd ?? DateTime.now();
      final effectiveEnd = now.isBefore(session.plannedEnd)
          ? now
          : session.plannedEnd;

      if (!effectiveEnd.isAfter(session.startTime)) {
        session.finished = true;
        _sessions.remove(uid);
        return {};
      }

      final userRef = _db.collection(FirestoreConstants.users).doc(uid);

      final result = await _db.runTransaction((transaction) async {
        final snap = await transaction.get(userRef);
        final liveData = snap.data() ?? <String, dynamic>{};

        double totalPointsLive =
            (liveData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            session.startTotalPoints;

        double offlineUnsyncedEarned = 0.0;
        final prefs = await SharedPreferences.getInstance();
        final offlineKey = 'offline_unsynced_earned_$uid';
        final stored = prefs.getDouble(offlineKey);
        if (stored != null && stored > 0) {
          offlineUnsyncedEarned = stored;
          await prefs.remove(offlineKey);
        }

        final double hourlyRate = session.hourlyRate;
        final elapsedHours =
            effectiveEnd.difference(session.startTime).inMilliseconds /
            (1000 * 60 * 60);
        final double earned = elapsedHours * hourlyRate + offlineUnsyncedEarned;

        final wallet =
            (liveData[FirestoreUserFields.wallet] as Map<String, dynamic>?) ??
            {};
        final coins = (wallet['coins'] as Map<String, dynamic>?) ?? {};

        final Map<String, dynamic> coinUpdates = {};
        coins.forEach((ownerId, value) {
          final map = value as Map<String, dynamic>;
          final end =
              map[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
          if (end != null && effectiveEnd.isBefore(end.toDate())) {
            coinUpdates['${FirestoreUserFields.wallet}.coins.$ownerId.${FirestoreUserCoinMiningFields.lastMiningEnd}'] =
                Timestamp.fromDate(effectiveEnd);
          }
        });

        const int msPerDay = 24 * 60 * 60 * 1000;
        final endUtc = DateTime.utc(
          effectiveEnd.year,
          effectiveEnd.month,
          effectiveEnd.day,
        );
        final int todayIndex = endUtc.millisecondsSinceEpoch ~/ msPerDay;
        final int nextStreakDays = session.streakDays;
        final int nextDayIndex = todayIndex;

        final int currentTotalSessions =
            (liveData[FirestoreUserFields.totalSessions] as num?)?.toInt() ?? 0;
        final int nextTotalSessions = currentTotalSessions + 1;

        final Map<String, dynamic> writeData = {
          FirestoreUserFields.totalPoints: totalPointsLive + earned,
          FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(effectiveEnd),
          FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(effectiveEnd),
          FirestoreUserFields.hourlyRate: session.hourlyRate,
          FirestoreUserFields.rateBase: session.rateBase,
          FirestoreUserFields.rateStreak: session.rateStreak,
          FirestoreUserFields.rateRank: session.rateRank,
          FirestoreUserFields.rateReferral: session.rateReferral,
          FirestoreUserFields.rateManager: session.rateManager,
          FirestoreUserFields.rateAds: session.rateAds,
          FirestoreUserFields.streakDays: nextStreakDays,
          FirestoreUserFields.streakLastUpdatedDay: nextDayIndex,
          FirestoreUserFields.totalSessions: nextTotalSessions,
          FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          ...coinUpdates,
        };

        transaction.set(userRef, writeData, SetOptions(merge: true));

        return {
          ...writeData,
          FirestoreUserFields.totalPoints: totalPointsLive + earned,
          FirestoreUserFields.lastMiningStart: Timestamp.fromDate(
            session.startTime,
          ),
        };
      });

      session.finished = true;
      _sessions.remove(uid);

      debugPrint(
        '[MiningBatchCommitEngine] op=$opId finishSession committed uid=$uid totalPoints=${result[FirestoreUserFields.totalPoints]}',
      );

      return result;
    });
  }
}

class OfflineMiningEngine {
  final FirebaseFirestore db;

  OfflineMiningEngine(this.db);

  Future<Map<String, dynamic>> ensureCachedUser(String uid) async {
    return OfflineMiningUserLock.runLocked(uid, () async {
      final cached = await OfflineMiningCache.loadUserDoc(uid);
      if (cached != null) return cached;
      return _reloadFromRemoteInternal(uid);
    });
  }

  Future<Map<String, dynamic>> reloadFromRemote(String uid) async {
    return OfflineMiningUserLock.runLocked(uid, () async {
      return _reloadFromRemoteInternal(uid);
    });
  }

  Future<Map<String, dynamic>> _reloadFromRemoteInternal(String uid) async {
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
    } else if (lastStartRaw is int) {
      lastStart = DateTime.fromMillisecondsSinceEpoch(lastStartRaw);
    }
    if (lastEndRaw is Timestamp) {
      lastEnd = lastEndRaw.toDate();
    } else if (lastEndRaw is int) {
      lastEnd = DateTime.fromMillisecondsSinceEpoch(lastEndRaw);
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
    } else if (startRaw is int) {
      start = DateTime.fromMillisecondsSinceEpoch(startRaw);
    }
    if (endRaw is Timestamp) {
      end = endRaw.toDate();
    } else if (endRaw is int) {
      end = DateTime.fromMillisecondsSinceEpoch(endRaw);
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
    return OfflineMiningUserLock.runLocked(
      uid,
      () => OfflineMiningCache.saveUserDoc(uid, simulatedUser),
    );
  }

  Future<void> finalizeSessionAndSync(String uid) async {
    await OfflineMiningUserLock.runLocked(uid, () async {
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
    });
  }
}
