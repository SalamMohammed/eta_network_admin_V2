import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/firestore_constants.dart';
import 'rank_engine.dart';
import 'config_service.dart';
import 'user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarningsEngine {
  static final Map<String, DateTime> _lastLocalWrites = {};
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static void _pruneLocalWrites() {
    final now = DateTime.now();
    // Remove entries older than 20 minutes to prevent memory leaks
    _lastLocalWrites.removeWhere(
      (key, time) => now.difference(time).inMinutes > 20,
    );
  }

  static void _log(
    String level,
    String op,
    String msg, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?> extra = const {},
  }) {
    final ts = DateTime.now().toIso8601String();
    final safeMsg = msg.replaceAll(
      RegExp('password|token|key|secret', caseSensitive: false),
      '***',
    );
    final extras = extra.isEmpty ? '' : ' | extra=${extra.toString()}';
    final err = error == null ? '' : ' | error=$error';
    final st = stack == null ? '' : ' | stack=${stack.toString()}';
    debugPrint('[$level][$ts][$op] $safeMsg$extras$err$st');
  }

  static Future<bool> migrateRealtimeToUnifiedIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      _log(
        'INFO',
        'migration',
        'begin migrateRealtimeToUnifiedIfNeeded',
        extra: {'uid': uid},
      );
      // IMPORTANT: Use the same core Firestore instance for all refs used in transactions
      final coreDb = _db;
      final userRef = coreDb.collection(FirestoreConstants.users).doc(uid);
      final realtimeRef = userRef
          .collection(FirestoreUserSubCollections.earnings)
          .doc(FirestoreEarningsDocs.realtime);
      _log(
        'DEBUG',
        'migration',
        'resolved refs',
        extra: {
          'userPath': userRef.path,
          'realtimePath':
              '${userRef.path}/earnings/${FirestoreEarningsDocs.realtime}',
          'coreDbHash': coreDb.hashCode,
          'userRefDbHash': userRef.firestore.hashCode,
          'realtimeRefDbHash': realtimeRef.firestore.hashCode,
          'coreApp': coreDb.app.name,
          'coreProjectId': coreDb.app.options.projectId,
          'userRefApp': userRef.firestore.app.name,
          'userRefProjectId': userRef.firestore.app.options.projectId,
          'realtimeRefApp': realtimeRef.firestore.app.name,
          'realtimeRefProjectId': realtimeRef.firestore.app.options.projectId,
        },
      );
      // Guard against cross-project or cross-app mismatches which would cause tx assertion failures
      final String? corePid = coreDb.app.options.projectId;
      final String? userPid = userRef.firestore.app.options.projectId;
      final String? rtPid = realtimeRef.firestore.app.options.projectId;
      if (corePid != userPid || corePid != rtPid) {
        _log(
          'ERROR',
          'migration',
          'project/app mismatch detected; aborting migration',
          extra: {
            'coreApp': coreDb.app.name,
            'coreProjectId': corePid,
            'userRefApp': userRef.firestore.app.name,
            'userRefProjectId': userPid,
            'realtimeRefApp': realtimeRef.firestore.app.name,
            'realtimeRefProjectId': rtPid,
          },
        );
        return false;
      }
      final userSnap = await userRef.get();
      final userData = userSnap.data() ?? {};
      final dynamic existingFlag =
          userData[FirestoreUserFields.uidMigrationCheckFinished];
      if (existingFlag != null && existingFlag is! bool) {
        _log(
          'WARN',
          'migration',
          'uidMigrationCheckFinished has non-bool type; will coerce to false',
          extra: {'type': existingFlag.runtimeType.toString(), 'uid': uid},
        );
      }
      if (existingFlag == null) {
        try {
          _log(
            'INFO',
            'migration',
            'creating uidMigrationCheckFinished=false',
            extra: {'uid': uid},
          );
          await userRef.set({
            FirestoreUserFields.uidMigrationCheckFinished: false,
            FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          _log(
            'INFO',
            'migration',
            'uidMigrationCheckFinished=false created',
            extra: {'uid': uid},
          );
        } on FirebaseException catch (fe, st) {
          _log(
            'ERROR',
            'migration',
            'failed to create uidMigrationCheckFinished',
            error:
                'code=${fe.code}, plugin=${fe.plugin}, message=${fe.message}',
            stack: st,
            extra: {'uid': uid},
          );
          rethrow;
        } catch (e, st) {
          _log(
            'ERROR',
            'migration',
            'unexpected error creating uidMigrationCheckFinished',
            error: e,
            stack: st,
            extra: {'uid': uid},
          );
          rethrow;
        }
      }
      final bool finishedFlag =
          (userData[FirestoreUserFields.uidMigrationCheckFinished] as bool?) ==
          true;
      final preRealtimeSnap = await realtimeRef.get();
      final preRealtime = _normalizeRealtime(preRealtimeSnap.data() ?? {});
      _log(
        'DEBUG',
        'migration',
        'loaded realtime doc keys',
        extra: {
          'realtimePath': realtimeRef.path,
          'keys': preRealtime.keys.join(','),
        },
      );
      // Add-once move for totalPoints: add realtime totalPoints into UID then delete from realtime.
      try {
        final dynamic rtTpVal = preRealtime[FirestoreUserFields.totalPoints];
        if (rtTpVal != null) {
          _log(
            'DEBUG',
            'migration',
            'attempt additive totalPoints move',
            extra: {'uid': uid, 'rtTotalPoints': '$rtTpVal'},
          );
          await coreDb.runTransaction((tx) async {
            final u = await tx.get(userRef);
            final r = await tx.get(realtimeRef);
            final liveData = u.data() ?? {};
            final rtData = _normalizeRealtime(r.data() ?? {});
            final double liveTP =
                (liveData[FirestoreUserFields.totalPoints] as num?)
                    ?.toDouble() ??
                0.0;
            final double rtTP =
                (rtData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
                0.0;
            if (rtTP != 0.0) {
              final double newTP = liveTP + rtTP;
              _log(
                'INFO',
                'migration',
                'additive totalPoints move start',
                extra: {
                  'uid': uid,
                  'liveTP': liveTP,
                  'rtTP': rtTP,
                  'newTP': newTP,
                },
              );
              final Map<String, dynamic> addPayload = {
                FirestoreUserFields.totalPoints: newTP,
                FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
              };
              tx.set(userRef, addPayload, SetOptions(merge: true));
              _log(
                'DEBUG',
                'migration',
                'tx.set user doc for additive move',
                extra: {'doc': userRef.path, 'keys': addPayload.keys.join(',')},
              );
            }
            tx.update(realtimeRef, {
              FirestoreUserFields.totalPoints: FieldValue.delete(),
              FirestoreLegacyAliases.totalpints: FieldValue.delete(),
              FirestoreLegacyAliases.totalPoints1: FieldValue.delete(),
              FirestoreLegacyAliases.total_points: FieldValue.delete(),
            });
            _log(
              'DEBUG',
              'migration',
              'tx.update realtime deletes for additive move',
              extra: {
                'doc': realtimeRef.path,
                'deleteFields':
                    '${FirestoreUserFields.totalPoints},${FirestoreLegacyAliases.totalpints},${FirestoreLegacyAliases.totalPoints1},${FirestoreLegacyAliases.total_points}',
              },
            );
          });
          _log(
            'INFO',
            'migration',
            'additive totalPoints move committed',
            extra: {'uid': uid},
          );
        }
      } on FirebaseException catch (fe, st) {
        _log(
          'ERROR',
          'migration',
          'additive totalPoints move failed',
          error: 'code=${fe.code}, plugin=${fe.plugin}, message=${fe.message}',
          stack: st,
          extra: {'uid': uid},
        );
      } catch (e, st) {
        _log(
          'ERROR',
          'migration',
          'additive totalPoints move unexpected error',
          error: e,
          stack: st,
          extra: {'uid': uid},
        );
      }
      final bool userLooksEmpty =
          (userData[FirestoreUserFields.totalPoints] == null &&
          userData[FirestoreUserFields.hourlyRate] == null &&
          userData[FirestoreUserFields.lastSyncedAt] == null);
      final bool realtimeHasData =
          preRealtime.isNotEmpty &&
          (preRealtime[FirestoreUserFields.totalPoints] != null ||
              preRealtime[FirestoreUserFields.hourlyRate] != null ||
              preRealtime[FirestoreUserFields.lastSyncedAt] != null);
      if (finishedFlag && !realtimeHasData && !userLooksEmpty) {
        _log(
          'INFO',
          'migration',
          'finished flag set and no realtime data; exiting',
          extra: {'uid': uid},
        );
        return false;
      }
      // Determine if realtime and user doc differ (even if user has some fields like zeros)
      bool realtimeMatchesUser = false;
      if (realtimeHasData) {
        final Map<String, dynamic> expected = Map.of(preRealtime);
        expected.remove(FirestoreUserFields.updatedAt);
        bool ok = true;
        for (final entry in expected.entries) {
          final k = entry.key;
          final ev = entry.value;
          if (!userData.containsKey(k)) {
            ok = false;
            break;
          }
          final uv = userData[k];
          if (!_deepEquals(ev, uv)) {
            ok = false;
            break;
          }
        }
        realtimeMatchesUser = ok;
      }
      // Decide migration strictly by finished flag and presence/mismatch
      final bool needsMigration =
          (!finishedFlag && (realtimeHasData || userLooksEmpty)) ||
          (finishedFlag && realtimeHasData && !realtimeMatchesUser) ||
          (finishedFlag && userLooksEmpty && realtimeHasData);
      if (!needsMigration) {
        // If no migration needed but we verified matching and the finished flag isn't set, set it now
        if (realtimeMatchesUser && !finishedFlag) {
          try {
            await userRef.set({
              FirestoreUserFields.uidMigrationCheckFinished: true,
              FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            _log(
              'INFO',
              'migration',
              'set finished flag true (no migration path)',
              extra: {'uid': uid},
            );
            try {
              await userRef.update({
                '${FirestoreUserFields.stats}.${FirestoreUserFields.totalPoints}':
                    FieldValue.delete(),
                '${FirestoreUserFields.stats}.${FirestoreUserFields.hourlyRate}':
                    FieldValue.delete(),
                FirestoreLegacyAliases.totalpints: FieldValue.delete(),
                FirestoreLegacyAliases.totalPoints1: FieldValue.delete(),
                FirestoreLegacyAliases.total_points: FieldValue.delete(),
                FirestoreLegacyAliases.hourly_rate: FieldValue.delete(),
                FirestoreLegacyAliases.hourlyRate1: FieldValue.delete(),
                FirestoreLegacyAliases.lastSynced: FieldValue.delete(),
              });
            } catch (e, st) {
              _log(
                'WARN',
                'migration',
                'legacy fields cleanup failed (non-fatal)',
                error: e,
                stack: st,
                extra: {'uid': uid},
              );
            }
          } on FirebaseException catch (fe, st) {
            _log(
              'ERROR',
              'migration',
              'failed to set finished flag true',
              error:
                  'code=${fe.code}, plugin=${fe.plugin}, message=${fe.message}',
              stack: st,
              extra: {'uid': uid},
            );
          }
        }
        _log(
          'INFO',
          'migration',
          'no migration needed',
          extra: {
            'uid': uid,
            'finished': finishedFlag,
            'userEmpty': userLooksEmpty,
            'realtimeHas': realtimeHasData,
            'matches': realtimeMatchesUser,
          },
        );
        return !finishedFlag && realtimeMatchesUser;
      }
      _log('INFO', 'migration', 'starting transaction', extra: {'uid': uid});
      await coreDb.runTransaction((tx) async {
        final userTx = await tx.get(userRef);
        final live = userTx.data() ?? {};
        final realtimeTx = await tx.get(realtimeRef);
        final realtimeData = _normalizeRealtime(realtimeTx.data() ?? {});
        if (realtimeData.isEmpty) {
          // If no realtime data, only mark migrated if user already holds the necessary fields
          final bool userHasCore =
              live.containsKey(FirestoreUserFields.totalPoints) ||
              live.containsKey(FirestoreUserFields.hourlyRate) ||
              live.containsKey(FirestoreUserFields.lastSyncedAt);
          if (userHasCore) {
            tx.set(userRef, {
              FirestoreUserFields.migrationUnifiedEarnings: true,
              FirestoreUserFields.uidMigrationCheckFinished: true,
              FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            // Delete empty legacy doc to tidy up
            tx.delete(realtimeRef);
            tx.update(userRef, {
              '${FirestoreUserFields.stats}.${FirestoreUserFields.totalPoints}':
                  FieldValue.delete(),
              '${FirestoreUserFields.stats}.${FirestoreUserFields.hourlyRate}':
                  FieldValue.delete(),
              FirestoreLegacyAliases.totalpints: FieldValue.delete(),
              FirestoreLegacyAliases.totalPoints1: FieldValue.delete(),
              FirestoreLegacyAliases.total_points: FieldValue.delete(),
              FirestoreLegacyAliases.hourly_rate: FieldValue.delete(),
              FirestoreLegacyAliases.hourlyRate1: FieldValue.delete(),
              FirestoreLegacyAliases.lastSynced: FieldValue.delete(),
              FirestoreLegacyAliases.rate_base: FieldValue.delete(),
              FirestoreLegacyAliases.rate_streak: FieldValue.delete(),
              FirestoreLegacyAliases.rate_rank: FieldValue.delete(),
              FirestoreLegacyAliases.rate_referral: FieldValue.delete(),
              FirestoreLegacyAliases.rate_manager: FieldValue.delete(),
              FirestoreLegacyAliases.rate_ads: FieldValue.delete(),
              FirestoreLegacyAliases.manager_bonus_per_hour:
                  FieldValue.delete(),
              FirestoreLegacyAliases.managed_coin_selections:
                  FieldValue.delete(),
            });
          } else {
            // Leave flag false so future runs can retry when data appears
            debugPrint(
              '[EarningsEngine] Migration skipped inside tx: realtime empty and user lacks core fields for $uid',
            );
          }
          return;
        }
        final r = _buildMigrationPayloadAndMissing(
          realtimeData: realtimeData,
          liveData: live,
        );
        final Map<String, dynamic> payload =
            r['payload'] as Map<String, dynamic>;
        final List<String> missing = (r['missing'] as List).cast<String>();
        if (missing.isNotEmpty) {
          debugPrint(
            '[EarningsEngine] Migration: some fields missing in realtime/live; applying defaults for $uid: ${missing.join(', ')}',
          );
        }
        payload.addAll(realtimeData);
        final double liveTP =
            (live[FirestoreUserFields.totalPoints] as num?)?.toDouble() ?? 0.0;
        final double rtTP =
            (realtimeData[FirestoreUserFields.totalPoints] as num?)
                ?.toDouble() ??
            0.0;
        payload[FirestoreUserFields.totalPoints] = liveTP + rtTP;
        payload[FirestoreUserFields.updatedAt] = FieldValue.serverTimestamp();
        tx.set(userRef, payload, SetOptions(merge: true));
        _log(
          'DEBUG',
          'migration',
          'tx.set user doc with payload',
          extra: {'doc': userRef.path, 'keys': payload.keys.join(',')},
        );
        // Clean up legacy totalPoints in realtime (move-once semantics)
        tx.update(realtimeRef, {
          FirestoreUserFields.totalPoints: FieldValue.delete(),
          FirestoreLegacyAliases.totalpints: FieldValue.delete(),
          FirestoreLegacyAliases.totalPoints1: FieldValue.delete(),
          FirestoreLegacyAliases.total_points: FieldValue.delete(),
        });
        tx.update(userRef, {
          '${FirestoreUserFields.stats}.${FirestoreUserFields.totalPoints}':
              FieldValue.delete(),
          '${FirestoreUserFields.stats}.${FirestoreUserFields.hourlyRate}':
              FieldValue.delete(),
          FirestoreLegacyAliases.totalpints: FieldValue.delete(),
          FirestoreLegacyAliases.totalPoints1: FieldValue.delete(),
          FirestoreLegacyAliases.total_points: FieldValue.delete(),
          FirestoreLegacyAliases.hourly_rate: FieldValue.delete(),
          FirestoreLegacyAliases.hourlyRate1: FieldValue.delete(),
          FirestoreLegacyAliases.lastSynced: FieldValue.delete(),
          FirestoreLegacyAliases.rate_base: FieldValue.delete(),
          FirestoreLegacyAliases.rate_streak: FieldValue.delete(),
          FirestoreLegacyAliases.rate_rank: FieldValue.delete(),
          FirestoreLegacyAliases.rate_referral: FieldValue.delete(),
          FirestoreLegacyAliases.rate_manager: FieldValue.delete(),
          FirestoreLegacyAliases.rate_ads: FieldValue.delete(),
          FirestoreLegacyAliases.manager_bonus_per_hour: FieldValue.delete(),
          FirestoreLegacyAliases.managed_coin_selections: FieldValue.delete(),
        });
        _log(
          'DEBUG',
          'migration',
          'tx.update deletes in main tx',
          extra: {
            'userDoc': userRef.path,
            'realtimeDoc': realtimeRef.path,
            'userDeleteFields':
                '${FirestoreUserFields.stats}.${FirestoreUserFields.totalPoints},${FirestoreLegacyAliases.totalpints},${FirestoreLegacyAliases.totalPoints1},${FirestoreLegacyAliases.total_points},${FirestoreLegacyAliases.hourly_rate},${FirestoreLegacyAliases.lastSynced}',
            'realtimeDeleteFields':
                '${FirestoreUserFields.totalPoints},${FirestoreLegacyAliases.totalpints},${FirestoreLegacyAliases.totalPoints1},${FirestoreLegacyAliases.total_points}',
          },
        );
      });
      _log('INFO', 'migration', 'transaction committed', extra: {'uid': uid});
      // Post-commit verification: ensure fields present and matching
      try {
        final verifySnap = await userRef.get();
        final v = verifySnap.data() ?? {};
        final Map<String, dynamic> expected = Map.of(preRealtime);
        // totalPoints was added to existing; skip strict equality on it
        expected.remove(FirestoreUserFields.totalPoints);
        expected.remove(FirestoreUserFields.updatedAt);
        bool ok = true;
        for (final entry in expected.entries) {
          final k = entry.key;
          final ev = entry.value;
          if (!v.containsKey(k)) {
            ok = false;
            break;
          }
          final uv = v[k];
          if (!_deepEquals(ev, uv)) {
            ok = false;
            break;
          }
        }
        if (ok) {
          await userRef.set({
            FirestoreUserFields.uidMigrationCheckFinished: true,
            FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          _log(
            'INFO',
            'migration',
            'post-verify success; finished flag set true',
            extra: {'uid': uid},
          );
        } else {
          _log(
            'WARN',
            'migration',
            'post-verify mismatch',
            extra: {'uid': uid},
          );
        }
      } on FirebaseException catch (fe, st) {
        _log(
          'ERROR',
          'migration',
          'post-commit verification failed',
          error: 'code=${fe.code}, plugin=${fe.plugin}, message=${fe.message}',
          stack: st,
          extra: {'uid': uid},
        );
      } catch (e, st) {
        _log(
          'ERROR',
          'migration',
          'post-commit verification unexpected error',
          error: e,
          stack: st,
          extra: {'uid': uid},
        );
      }
      return true;
    } on FirebaseException catch (fe, st) {
      _log(
        'ERROR',
        'migration',
        'migration failed',
        error: 'code=${fe.code}, plugin=${fe.plugin}, message=${fe.message}',
        stack: st,
        extra: {'uid': FirebaseAuth.instance.currentUser?.uid},
      );
      return false;
    } catch (e, st) {
      _log(
        'ERROR',
        'migration',
        'migration unexpected error',
        error: e,
        stack: st,
        extra: {'uid': FirebaseAuth.instance.currentUser?.uid},
      );
      return false;
    }
  }

  static bool _numEquals(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.toDouble() == b.toDouble();
    }
    return a == b;
  }

  static bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  static const String _kThrottleGraceUntilMs = 'earningsThrottleGraceUntilMs';
  static bool _graceInitDone = false;

  static Future<void> _initThrottleGraceIfNeeded() async {
    if (_graceInitDone) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final int? untilMs = prefs.getInt(_kThrottleGraceUntilMs);
    if (untilMs == null || now.millisecondsSinceEpoch > untilMs) {
      final until = now.add(const Duration(minutes: 1)).millisecondsSinceEpoch;
      await prefs.setInt(_kThrottleGraceUntilMs, until);
    }
    _graceInitDone = true;
  }

  static Future<bool> _isInThrottleGrace() async {
    final prefs = await SharedPreferences.getInstance();
    final int? untilMs = prefs.getInt(_kThrottleGraceUntilMs);
    if (untilMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch < untilMs;
  }

  static bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k)) return false;
      if (!_deepEquals(a[k], b[k])) return false;
    }
    return true;
  }

  static bool _deepEquals(dynamic a, dynamic b) {
    if (a is num && b is num) return _numEquals(a, b);
    if (a is Timestamp && b is Timestamp) {
      return a.millisecondsSinceEpoch == b.millisecondsSinceEpoch;
    }
    if (a is List && b is List) return _listEquals(a, b);
    if (a is Map && b is Map) return _mapEquals(a, b);
    return a == b;
  }

  static Map<String, dynamic> _normalizeRealtime(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    final aliases = <String, String>{
      FirestoreLegacyAliases.totalpints: FirestoreUserFields.totalPoints,
      FirestoreLegacyAliases.total_points: FirestoreUserFields.totalPoints,
      FirestoreLegacyAliases.totalPoints1: FirestoreUserFields.totalPoints,
      FirestoreLegacyAliases.hourly_rate: FirestoreUserFields.hourlyRate,
      FirestoreLegacyAliases.hourlyRate1: FirestoreUserFields.hourlyRate,
      FirestoreLegacyAliases.lastSynced: FirestoreUserFields.lastSyncedAt,
      FirestoreLegacyAliases.rate_base: FirestoreUserFields.rateBase,
      FirestoreLegacyAliases.rate_streak: FirestoreUserFields.rateStreak,
      FirestoreLegacyAliases.rate_rank: FirestoreUserFields.rateRank,
      FirestoreLegacyAliases.rate_referral: FirestoreUserFields.rateReferral,
      FirestoreLegacyAliases.rate_manager: FirestoreUserFields.rateManager,
      FirestoreLegacyAliases.rate_ads: FirestoreUserFields.rateAds,
      FirestoreLegacyAliases.manager_bonus_per_hour:
          FirestoreUserFields.managerBonusPerHour,
      FirestoreLegacyAliases.managed_coin_selections:
          FirestoreUserFields.managedCoinSelections,
    };
    for (final e in aliases.entries) {
      final alias = e.key;
      final canonical = e.value;
      if (out.containsKey(alias) && !out.containsKey(canonical)) {
        out[canonical] = out[alias];
      }
    }
    return out;
  }

  static Map<String, dynamic> _buildMigrationPayloadAndMissing({
    required Map<String, dynamic> realtimeData,
    required Map<String, dynamic> liveData,
  }) {
    num? hr = realtimeData[FirestoreUserFields.hourlyRate] as num?;
    hr ??= realtimeData['hourlyRate1'] as num?;
    hr ??= liveData[FirestoreUserFields.hourlyRate] as num?;
    final double hourlyRate = (hr)?.toDouble() ?? 0.0;

    final double totalPoints =
        ((realtimeData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            (liveData[FirestoreUserFields.totalPoints] as num?)?.toDouble()) ??
        0.0;

    Timestamp? lastSyncedAt =
        (realtimeData[FirestoreUserFields.lastSyncedAt] as Timestamp?) ??
        (liveData[FirestoreUserFields.lastSyncedAt] as Timestamp?);

    final double rateBase =
        (realtimeData[FirestoreUserFields.rateBase] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateBase] as num?)?.toDouble() ??
        0.0;
    final double rateStreak =
        (realtimeData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
        0.0;
    final double rateRank =
        (realtimeData[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
        0.0;
    final double rateReferral =
        (realtimeData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
        0.0;
    final double rateManager =
        (realtimeData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
        0.0;
    final double rateAds =
        (realtimeData[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
        (liveData[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
        0.0;
    final double managerBonusPerHour =
        (realtimeData[FirestoreUserFields.managerBonusPerHour] as num?)
            ?.toDouble() ??
        (liveData[FirestoreUserFields.managerBonusPerHour] as num?)
            ?.toDouble() ??
        0.0;
    final List<String> managedCoinSelections =
        (realtimeData[FirestoreUserFields.managedCoinSelections] as List?)
            ?.cast<String>() ??
        (liveData[FirestoreUserFields.managedCoinSelections] as List?)
            ?.cast<String>() ??
        const [];

    // Preserve updatedAt from realtime if present; otherwise keep live updatedAt if present
    Timestamp? updatedAt =
        (realtimeData[FirestoreUserFields.updatedAt] as Timestamp?) ??
        (liveData[FirestoreUserFields.updatedAt] as Timestamp?);

    final missing = <String>[];
    if (lastSyncedAt == null) {
      lastSyncedAt = updatedAt ?? Timestamp.now();
      missing.add(FirestoreUserFields.lastSyncedAt);
    }
    if (hourlyRate.isNaN) {
      missing.add(FirestoreUserFields.hourlyRate);
    }
    if (rateBase.isNaN) missing.add(FirestoreUserFields.rateBase);
    if (rateStreak.isNaN) missing.add(FirestoreUserFields.rateStreak);
    if (rateRank.isNaN) missing.add(FirestoreUserFields.rateRank);
    if (rateReferral.isNaN) missing.add(FirestoreUserFields.rateReferral);
    if (rateManager.isNaN) missing.add(FirestoreUserFields.rateManager);
    if (rateAds.isNaN) missing.add(FirestoreUserFields.rateAds);
    if (totalPoints.isNaN) {
      missing.add(FirestoreUserFields.totalPoints);
    }

    final payload = <String, dynamic>{
      FirestoreUserFields.totalPoints: totalPoints,
      FirestoreUserFields.lastSyncedAt: lastSyncedAt,
      FirestoreUserFields.hourlyRate: hourlyRate,
      FirestoreUserFields.rateBase: rateBase,
      FirestoreUserFields.rateStreak: rateStreak,
      FirestoreUserFields.rateRank: rateRank,
      FirestoreUserFields.rateReferral: rateReferral,
      FirestoreUserFields.rateManager: rateManager,
      FirestoreUserFields.rateAds: rateAds,
      FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
      FirestoreUserFields.managedCoinSelections: managedCoinSelections,
      if (updatedAt != null) FirestoreUserFields.updatedAt: updatedAt,
    };
    return {'payload': payload, 'missing': missing};
  }

  // duplicate removed

  static List<String> debugValidateMigration(
    Map<String, dynamic> realtimeData,
    Map<String, dynamic> liveData,
  ) {
    final r = _buildMigrationPayloadAndMissing(
      realtimeData: realtimeData,
      liveData: liveData,
    );
    return (r['missing'] as List).cast<String>();
  }

  static Future<void> setUserHourlyRate({
    required String uid,
    required double rate,
  }) async {
    final userRef = _db.collection(FirestoreConstants.users).doc(uid);
    try {
      await userRef.set({
        FirestoreUserFields.hourlyRate: rate,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[RateSync] setUserHourlyRate uid=$uid rate=$rate');
    } catch (e) {
      debugPrint('[RateSync] setUserHourlyRate error: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> decideInitialRate({
    required double? userRate,
    required bool miningActive,
    required double baseRate,
  }) {
    if (miningActive) {
      return {'rate': userRate ?? baseRate, 'write': userRate == null};
    }
    if (userRate == null) {
      return {'rate': baseRate, 'write': true};
    }
    return {'rate': userRate, 'write': false};
  }

  static Map<String, dynamic> debugBuildMigrationPayload(
    Map<String, dynamic> realtime,
    Map<String, dynamic> live,
  ) {
    final rtNorm = _normalizeRealtime(realtime);
    final r = _buildMigrationPayloadAndMissing(
      realtimeData: rtNorm,
      liveData: live,
    );
    final Map<String, dynamic> payload = r['payload'] as Map<String, dynamic>;
    payload.addAll(rtNorm);
    final double liveTP =
        (live[FirestoreUserFields.totalPoints] as num?)?.toDouble() ?? 0.0;
    final double rtTP =
        (rtNorm[FirestoreUserFields.totalPoints] as num?)?.toDouble() ?? 0.0;
    payload[FirestoreUserFields.totalPoints] = liveTP + rtTP;
    payload[FirestoreUserFields.hourlyRate] =
        (payload[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;
    payload[FirestoreUserFields.lastSyncedAt] =
        payload[FirestoreUserFields.lastSyncedAt] ?? Timestamp.now();
    payload[FirestoreUserFields.rateBase] =
        (payload[FirestoreUserFields.rateBase] as num?)?.toDouble() ?? 0.0;
    payload[FirestoreUserFields.rateStreak] =
        (payload[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
    payload[FirestoreUserFields.rateRank] =
        (payload[FirestoreUserFields.rateRank] as num?)?.toDouble() ?? 0.0;
    payload[FirestoreUserFields.rateReferral] =
        (payload[FirestoreUserFields.rateReferral] as num?)?.toDouble() ?? 0.0;
    payload[FirestoreUserFields.rateManager] =
        (payload[FirestoreUserFields.rateManager] as num?)?.toDouble() ?? 0.0;
    payload[FirestoreUserFields.rateAds] =
        (payload[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;
    payload[FirestoreUserFields.managedCoinSelections] =
        (payload[FirestoreUserFields.managedCoinSelections] as List?)?.cast() ??
        <String>[];
    return payload;
  }

  static Future<Map<String, dynamic>> syncEarnings({
    Map<String, dynamic>? cachedManagerData,
    String? cachedManagerId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    await _initThrottleGraceIfNeeded();
    final bool inGrace = await _isInThrottleGrace();

    // Ensure migration runs even if MiningStateService.init hasn't yet
    await migrateRealtimeToUnifiedIfNeeded();

    final userRef = _db.collection(FirestoreConstants.users).doc(uid);
    final pointLogsRef = _db.collection(FirestoreConstants.pointLogs);

    // Fetch user data via UserService to use cache (deduplication)
    final userSnap = await UserService().getUser(uid);
    if (userSnap == null || !userSnap.exists) return {};
    final data = userSnap.data() ?? {};

    // Check local cache BEFORE transaction to avoid unnecessary reads
    final lastWrite = _lastLocalWrites[uid];
    final bool recentlyWrittenLocally =
        lastWrite != null &&
        DateTime.now().difference(lastWrite).inMinutes < 10;

    final Timestamp? endTs =
        data[FirestoreUserFields.lastMiningEnd] as Timestamp?;
    final DateTime now = DateTime.now();
    final DateTime? end = endTs?.toDate();
    final bool isSessionComplete =
        end != null && !now.isBefore(end); // now >= end

    if (recentlyWrittenLocally && !isSessionComplete && !inGrace) {
      // Throttle: Perform READ-ONLY operation (no transaction)
      // Note: We still need to fetch unified user doc to get the components and latest sync time
      // But we can do a simple GET instead of a transaction.
      // Or better yet, just return what we have if we assume it hasn't changed much?
      // No, we need to calculate 'earned' points based on elapsed time since last sync.

      try {
        // OPTIMIZATION: Use UserService cache for unified user doc to avoid redundant reads
        final liveSnap = await UserService().getRealtimeDoc(uid);
        final liveData = liveSnap?.data() ?? {};

        final Timestamp? startTs =
            data[FirestoreUserFields.lastMiningStart] as Timestamp?;
        final Timestamp? syncedTs =
            (liveData[FirestoreUserFields.lastSyncedAt] as Timestamp?) ??
            (data[FirestoreUserFields.lastSyncedAt] as Timestamp?);

        final double hourlyRate =
            (liveData[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
            (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
            0.0;

        final double totalPoints =
            (liveData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            (data[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
            0.0;

        final double rateBase =
            (liveData[FirestoreUserFields.rateBase] as num?)?.toDouble() ?? 0.0;
        final double rateStreak =
            (liveData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
            0.0;
        final double rateRank =
            (liveData[FirestoreUserFields.rateRank] as num?)?.toDouble() ?? 0.0;
        final double rateReferral =
            (liveData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
            0.0;
        final double rateManager =
            (liveData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
            0.0;
        final double rateAds =
            (liveData[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;
        final bool managerEnabled =
            (data[FirestoreUserFields.managerEnabled] as bool?) ?? false;

        final List<String> managedCoinSelections = managerEnabled
            ? ((liveData[FirestoreUserFields.managedCoinSelections] as List?)
                      ?.cast<String>() ??
                  (data[FirestoreUserFields.managedCoinSelections] as List?)
                      ?.cast<String>() ??
                  [])
            : [];

        final double managerBonusPerHour =
            (liveData[FirestoreUserFields.managerBonusPerHour] as num?)
                ?.toDouble() ??
            (data[FirestoreUserFields.managerBonusPerHour] as num?)
                ?.toDouble() ??
            0.0;

        if (startTs == null) {
          return {
            FirestoreUserFields.totalPoints: totalPoints,
            FirestoreUserFields.hourlyRate: hourlyRate,
            FirestoreUserFields.managedCoinSelections: managedCoinSelections,
            FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
            FirestoreUserFields.lastMiningStart: startTs,
            FirestoreUserFields.lastMiningEnd: endTs,
            'userData': data,
            FirestoreUserFields.rateBase: rateBase,
            FirestoreUserFields.rateStreak: rateStreak,
            FirestoreUserFields.rateRank: rateRank,
            FirestoreUserFields.rateReferral: rateReferral,
            FirestoreUserFields.rateManager: rateManager,
            FirestoreUserFields.rateAds: rateAds,
            '_didWrite': false,
          };
        }

        final sessionEnd = end ?? now;
        final effectiveEnd = now.isBefore(sessionEnd) ? now : sessionEnd;
        final from = (syncedTs ?? startTs).toDate();

        if (!effectiveEnd.isAfter(from)) {
          // Already synced up to this point
          return {
            FirestoreUserFields.totalPoints: totalPoints,
            FirestoreUserFields.hourlyRate: hourlyRate,
            FirestoreUserFields.managedCoinSelections: managedCoinSelections,
            FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
            FirestoreUserFields.lastMiningStart: startTs,
            FirestoreUserFields.lastMiningEnd: endTs,
            'userData': data,
            FirestoreUserFields.rateBase: rateBase,
            FirestoreUserFields.rateStreak: rateStreak,
            FirestoreUserFields.rateRank: rateRank,
            FirestoreUserFields.rateReferral: rateReferral,
            FirestoreUserFields.rateManager: rateManager,
            FirestoreUserFields.rateAds: rateAds,
            '_didWrite': false,
          };
        }

        final elapsedHours =
            effectiveEnd.difference(from).inMilliseconds / (1000 * 60 * 60);
        final earned = elapsedHours * hourlyRate;

        debugPrint(
          '[EarningsEngine] Throttled locally: skipped write. Last write: $lastWrite, Now: $now',
        );

        return {
          FirestoreUserFields.totalPoints: totalPoints + earned,
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
          FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(from),
          'userData': data,
          FirestoreUserFields.rateBase: rateBase,
          FirestoreUserFields.rateStreak: rateStreak,
          FirestoreUserFields.rateRank: rateRank,
          FirestoreUserFields.rateReferral: rateReferral,
          FirestoreUserFields.rateManager: rateManager,
          FirestoreUserFields.rateAds: rateAds,
          '_didWrite': false,
        };
      } catch (e) {
        debugPrint(
          '[EarningsEngine] Local throttle read failed: $e. Falling back to transaction.',
        );
      }
    }

    final result = await _db.runTransaction((transaction) async {
      // NOTE: We do NOT read userRef inside transaction to save a read.
      // We rely on UserService cache (5s freshness).
      // This means we might calculate based on slightly stale hourlyRate,
      // and we read the latest user doc inside the transaction.
      final userSnapTx = await transaction.get(userRef);
      final liveData = userSnapTx.data() ?? {};

      final Timestamp? startTs =
          data[FirestoreUserFields.lastMiningStart] as Timestamp?;
      final Timestamp? endTs =
          data[FirestoreUserFields.lastMiningEnd] as Timestamp?;

      // Prefer latest transaction read for syncedAt, fallback to pre-read user doc
      final Timestamp? syncedTs =
          (liveData[FirestoreUserFields.lastSyncedAt] as Timestamp?) ??
          (data[FirestoreUserFields.lastSyncedAt] as Timestamp?);

      // Prefer latest transaction read for hourlyRate, fallback to user doc
      final double hourlyRate =
          (liveData[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          0.0;

      // Prefer latest transaction read for managedCoinSelections, fallback to user doc
      final List<String> managedCoinSelections =
          (liveData[FirestoreUserFields.managedCoinSelections] as List?)
              ?.cast<String>() ??
          (data[FirestoreUserFields.managedCoinSelections] as List?)
              ?.cast<String>() ??
          [];

      // Prefer latest transaction read for managerBonusPerHour, fallback to user doc
      final double managerBonusPerHour =
          (liveData[FirestoreUserFields.managerBonusPerHour] as num?)
              ?.toDouble() ??
          (data[FirestoreUserFields.managerBonusPerHour] as num?)?.toDouble() ??
          0.0;

      // Read Rate Components from latest transaction doc
      final double rateBase =
          (liveData[FirestoreUserFields.rateBase] as num?)?.toDouble() ?? 0.0;
      final double rateStreak =
          (liveData[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
      final double rateRank =
          (liveData[FirestoreUserFields.rateRank] as num?)?.toDouble() ?? 0.0;
      final double rateReferral =
          (liveData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
          0.0;
      final double rateManager =
          (liveData[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
          0.0;
      final double rateAds =
          (liveData[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;

      // Check if migration is needed
      final bool needsMigration =
          (!liveData.containsKey(FirestoreUserFields.hourlyRate) &&
              data.containsKey(FirestoreUserFields.hourlyRate)) ||
          (!liveData.containsKey(FirestoreUserFields.managedCoinSelections) &&
              data.containsKey(FirestoreUserFields.managedCoinSelections)) ||
          (!liveData.containsKey(FirestoreUserFields.managerBonusPerHour) &&
              data.containsKey(FirestoreUserFields.managerBonusPerHour));

      // Prefer latest transaction read for totalPoints, fallback to pre-read user doc
      double totalPoints =
          (liveData[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
          (data[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
          0.0;

      if (startTs == null) {
        return {
          FirestoreUserFields.totalPoints: totalPoints,
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
          FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          'userData': data,
          FirestoreUserFields.rateBase: rateBase,
          FirestoreUserFields.rateStreak: rateStreak,
          FirestoreUserFields.rateRank: rateRank,
          FirestoreUserFields.rateReferral: rateReferral,
          FirestoreUserFields.rateManager: rateManager,
          FirestoreUserFields.rateAds: rateAds,
        };
      }
      final now = DateTime.now();
      final end = endTs?.toDate();
      final sessionEnd = end ?? now;
      final effectiveEnd = now.isBefore(sessionEnd) ? now : sessionEnd;
      final from = (syncedTs ?? startTs).toDate();
      if (!effectiveEnd.isAfter(from)) {
        return {
          FirestoreUserFields.totalPoints: totalPoints,
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
          FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          'userData': data,
          FirestoreUserFields.rateBase: rateBase,
          FirestoreUserFields.rateStreak: rateStreak,
          FirestoreUserFields.rateRank: rateRank,
          FirestoreUserFields.rateReferral: rateReferral,
          FirestoreUserFields.rateManager: rateManager,
          FirestoreUserFields.rateAds: rateAds,
        };
      }
      final elapsedHours =
          effectiveEnd.difference(from).inMilliseconds / (1000 * 60 * 60);
      final earned = elapsedHours * hourlyRate;

      // Throttle writes: strict 10-minute rule to prevent frequent updates
      // UNLESS:
      // 1. Migration is needed
      // 2. Session is completing (effectiveEnd reached endTs)
      final diffMinutes = effectiveEnd.difference(from).inMinutes;
      final bool isSessionComplete =
          endTs != null && !effectiveEnd.isBefore(endTs.toDate());

      // Check local cache for strict throttle to prevent writes when toggling background/foreground
      final lastWrite = _lastLocalWrites[uid];
      final bool recentlyWrittenLocally =
          lastWrite != null &&
          DateTime.now().difference(lastWrite).inMinutes < 10;

      if (!needsMigration &&
          !isSessionComplete &&
          (diffMinutes < 10 || recentlyWrittenLocally) &&
          !inGrace) {
        return {
          FirestoreUserFields.totalPoints:
              totalPoints + earned, // Return calculated total for UI
          FirestoreUserFields.hourlyRate: hourlyRate,
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
          FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
          FirestoreUserFields.lastMiningStart: startTs,
          FirestoreUserFields.lastMiningEnd: endTs,
          FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(
            from,
          ), // Keep old sync time
          'userData': data,
          FirestoreUserFields.rateBase: rateBase,
          FirestoreUserFields.rateStreak: rateStreak,
          FirestoreUserFields.rateRank: rateRank,
          FirestoreUserFields.rateReferral: rateReferral,
          FirestoreUserFields.rateManager: rateManager,
          FirestoreUserFields.rateAds: rateAds,
          '_didWrite': false,
        };
      }

      // Write directly to unified user document
      final Map<String, dynamic> writeData = {
        // Use explicit set instead of increment to ensure base is correct if migrating
        FirestoreUserFields.totalPoints: totalPoints + earned,
        FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(effectiveEnd),
        FirestoreUserFields.hourlyRate: hourlyRate,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.managedCoinSelections: managedCoinSelections,
        FirestoreUserFields.rateBase: rateBase,
        FirestoreUserFields.rateStreak: rateStreak,
        FirestoreUserFields.rateRank: rateRank,
        FirestoreUserFields.rateReferral: rateReferral,
        FirestoreUserFields.rateManager: rateManager,
        FirestoreUserFields.rateAds: rateAds,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      };
      transaction.set(userRef, writeData, SetOptions(merge: true));

      if (earned > 0) {
        final newLogDoc = pointLogsRef.doc();
        transaction.set(newLogDoc, {
          FirestorePointLogFields.userId: uid,
          FirestorePointLogFields.type: FirestorePointLogTypes.tap,
          FirestorePointLogFields.amount: earned,
          FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
          FirestorePointLogFields.description: 'Session earnings',
        });
      }

      return {
        FirestoreUserFields.totalPoints: (totalPoints + earned),
        FirestoreUserFields.hourlyRate: hourlyRate,
        FirestoreUserFields.managedCoinSelections: managedCoinSelections,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.lastMiningStart: startTs,
        FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(effectiveEnd),
        FirestoreUserFields.lastMiningEnd: endTs,
        'userData': data,
        FirestoreUserFields.rateBase: rateBase,
        FirestoreUserFields.rateStreak: rateStreak,
        FirestoreUserFields.rateRank: rateRank,
        FirestoreUserFields.rateReferral: rateReferral,
        FirestoreUserFields.rateManager: rateManager,
        FirestoreUserFields.rateAds: rateAds,
        '_didWrite': true,
      };
    });

    if (result['_didWrite'] == true) {
      _pruneLocalWrites();
      _lastLocalWrites[uid] = DateTime.now();
    }

    return result;
  }

  /// Boosts the hourly rate by a specific amount (Ad Reward).
  /// Updates rateAds and hourlyRate in Firestore.
  static Future<double> boostAdRate({
    required String uid,
    required double boostAmount,
  }) async {
    final userRef = _db.collection(FirestoreConstants.users).doc(uid);
    final logRef = _db.collection(FirestoreConstants.pointLogs).doc();

    return _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final data = userSnap.exists ? (userSnap.data() ?? {}) : {};

      final double currentAds =
          (data[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;
      final double newAds = currentAds + boostAmount;

      final double currentHourlyRate =
          (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;

      // We add boostAmount to currentHourlyRate.
      // This assumes other components haven't changed since last sync.
      // This is a safe assumption for a quick boost action.
      final double newHourlyRate = currentHourlyRate + boostAmount;

      transaction.set(userRef, {
        FirestoreUserFields.rateAds: newAds,
        FirestoreUserFields.hourlyRate: newHourlyRate,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(logRef, {
        FirestorePointLogFields.userId: uid,
        FirestorePointLogFields.type:
            FirestorePointLogTypes.bonus, // Or create a new type if needed
        FirestorePointLogFields.amount:
            0, // Rate boost doesn't give immediate points
        FirestorePointLogFields.timestamp: FieldValue.serverTimestamp(),
        FirestorePointLogFields.description: 'Ad Reward: Rate +$boostAmount/hr',
      });

      return newAds;
    });
  }

  @Deprecated('Use boostAdRate instead')
  static Future<void> grantAdReward({
    required String uid,
    required double rewardAmount,
  }) async {
    // Legacy redirect or no-op if we want to force switch
    // For now, let's keep it but logging warning
    debugPrint('grantAdReward is deprecated. Use boostAdRate.');
  }

  @Deprecated('Use grantAdReward instead')
  static Future<void> applyAdBoost({
    required String uid,
    required double boostAmount,
  }) async {
    // Redirect to grantAdReward for backward compatibility during migration
    await grantAdReward(uid: uid, rewardAmount: boostAmount);
  }

  static Future<Map<String, dynamic>> recalculateRates({
    required String uid,
    Map<String, dynamic>? cachedManagerData,
    String? cachedManagerId,
    int? activeReferralCount,
  }) async {
    final userRef = _db.collection(FirestoreConstants.users).doc(uid);

    // Get App Config for Base Rate
    final appConfig = await ConfigService().getGeneralConfig();
    final double baseRate =
        (appConfig[FirestoreAppConfigFields.baseRate] as num?)?.toDouble() ??
        0.2;

    return _db.runTransaction((transaction) async {
      // Fetch user data inside transaction to ensure consistency
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) return {};
      final userData = userSnap.data()!;

      // 1. Base Rate
      // baseRate is already fetched

      // 2. Rank Bonus (Builder=1.2x, Guardian=1.5x)
      final String rank =
          (userData[FirestoreUserFields.rank] as String?) ??
          FirestoreUserRanks.explorer;
      double rankMultiplier = 1.0;
      if (rank == FirestoreUserRanks.builder) rankMultiplier = 1.2;
      if (rank == FirestoreUserRanks.guardian) rankMultiplier = 1.5;

      // The "bonus" from rank is (Multiplier - 1.0) * BaseRate?
      // Or is it applied to the final?
      // Convention: Rate = Base + Streak + Referrals + Manager + Ads.
      // Rank usually multiplies Base.
      // Let's define: RateRank = Base * (Multiplier - 1).
      final double rateRank = baseRate * (rankMultiplier - 1.0);

      // 3. Streak Bonus
      // Fetch streak config
      // final streakConfig = await ConfigService().getStreakConfig();
      // final double maxStreakMult = ... (unused)

      // Linear interpolation? Or just based on days?
      // For now, let's assume simplistic: (days / 30) * Base.
      // TODO: Use actual streak logic if complex.
      // Existing logic used: Base * (1 + 0.1 * days)?
      // Let's look at legacy code or assume 0 for now if not defined.
      final int streakDays =
          (userData[FirestoreUserFields.streakDays] as int?) ?? 0;
      // Cap streak days?
      final double rateStreak = (streakDays > 0)
          ? (baseRate * 0.05 * streakDays)
          : 0.0;
      // Cap at maxStreakMult * Base (Total) => Bonus is (Max - 1) * Base
      // This is a placeholder for actual streak logic.

      // 4. Referral Bonus
      final refConfig = await ConfigService().getReferralConfig();
      double perRef =
          (refConfig[FirestoreReferralConfigFields.referrerPercentPerReferral]
                  as num?)
              ?.toDouble() ??
          0.25; // 25% of base

      // Normalize: If value is > 1.0 (e.g. 25), treat as percentage (0.25)
      // This handles Admin Dashboard inputs like "25" for 25%.
      if (perRef > 1.0) {
        perRef = perRef / 100.0;
      }

      // Strict Logic: Cap referral count
      final int maxRefs =
          (refConfig[FirestoreReferralConfigFields.referrerMaxCount] as num?)
              ?.toInt() ??
          0;

      // Strict Logic: Max total bonus rate (from General Config)
      final double maxBonusRate =
          (appConfig[FirestoreAppConfigFields.maxReferralBonusRate] as num?)
              ?.toDouble() ??
          0.0;

      double rateReferral = 0.0;
      if (activeReferralCount != null) {
        int effectiveCount = activeReferralCount;
        if (maxRefs > 0 && effectiveCount > maxRefs) {
          effectiveCount = maxRefs;
        }
        // Calculate based on normalized perRef
        rateReferral = effectiveCount * perRef * baseRate;
      } else {
        // Fallback: Use existing rate from unified user document
        rateReferral =
            (userData[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
            0.0;
      }

      // Apply Global Cap if set
      if (maxBonusRate > 0.0 && rateReferral > maxBonusRate) {
        rateReferral = maxBonusRate;
      }

      // 5. Manager Bonus
      double rateManager = 0.0;
      double managerBonusPerHour = 0.0;
      List<String> managedCoinSelections = [];
      final bool managerEnabled =
          (userData[FirestoreUserFields.managerEnabled] as bool?) ?? false;
      final String? activeManagerId =
          userData[FirestoreUserFields.activeManagerId] as String?;

      if (managerEnabled && activeManagerId != null) {
        Map<String, dynamic> managerData = {};
        if (cachedManagerId == activeManagerId && cachedManagerData != null) {
          managerData = cachedManagerData;
        } else {
          final mgrSnap = await _db
              .collection(FirestoreConstants.managers)
              .doc(activeManagerId)
              .get();
          managerData = mgrSnap.data() ?? {};
        }

        final double mgrMult =
            (managerData[FirestoreManagerFields.managerMultiplier] as num?)
                ?.toDouble() ??
            1.0;
        // Manager bonus is applied to (Base + Rank + Streak)?
        // Or just Base?
        // Let's assume it adds (Multiplier - 1) * Base.
        rateManager = baseRate * (mgrMult - 1.0);

        managerBonusPerHour =
            (managerData[FirestoreManagerFields.maxCommunityCoinsManaged]
                    as num?)
                ?.toDouble() ??
            0.0;

        // Auto-select coins if enabled
        final bool autoCoin =
            (managerData[FirestoreManagerFields.enableUserCoinAuto] as bool?) ??
            false;
        if (autoCoin) {
          // Logic to select coins?
          // Placeholder.
        }
      }

      // 6. Ad Bonus (Preserve existing)
      final double rateAds =
          (userData[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;

      // Total
      final double newHourlyRate =
          baseRate +
          rateRank +
          rateStreak +
          rateReferral +
          rateManager +
          rateAds;

      transaction.set(userRef, {
        FirestoreUserFields.rateBase: baseRate,
        FirestoreUserFields.rateRank: rateRank,
        FirestoreUserFields.rateStreak: rateStreak,
        FirestoreUserFields.rateReferral: rateReferral,
        FirestoreUserFields.rateManager: rateManager,
        FirestoreUserFields.rateAds: rateAds,
        FirestoreUserFields.hourlyRate: newHourlyRate,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        if (managedCoinSelections.isNotEmpty)
          FirestoreUserFields.managedCoinSelections: managedCoinSelections,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update main user doc for redundancy/display?
      // Prefer keeping it in realtime to reduce writes.
      // But if we want 'hourlyRate' to be visible in admin panel on user doc:
      // OPTIMIZATION: Removed redundant write to userRef to save costs.
      // Admin panel should read from realtime subcollection or aggregate queries.
      /*
      transaction.update(userRef, {
        FirestoreUserFields.hourlyRate: newHourlyRate,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      });
      */

      return {
        FirestoreUserFields.rateBase: baseRate,
        FirestoreUserFields.rateRank: rateRank,
        FirestoreUserFields.rateStreak: rateStreak,
        FirestoreUserFields.rateReferral: rateReferral,
        FirestoreUserFields.rateManager: rateManager,
        FirestoreUserFields.rateAds: rateAds,
        FirestoreUserFields.hourlyRate: newHourlyRate,
        FirestoreUserFields.managerBonusPerHour: managerBonusPerHour,
        FirestoreUserFields.managedCoinSelections: managedCoinSelections,
      };
    });
  }

  static Future<Map<String, dynamic>> startMining({
    required String uid,
    String? deviceId,
    DateTime? maxEnd,
    Map<String, dynamic>? cachedManagerData,
    String? cachedManagerId,
    int? activeReferralCount,
  }) async {
    // 1. Recalculate Rates first (ensure they are up to date)
    final rates = await recalculateRates(
      uid: uid,
      cachedManagerData: cachedManagerData,
      cachedManagerId: cachedManagerId,
      activeReferralCount: activeReferralCount,
    );

    // 2. Set Start/End times
    final appConfig = await ConfigService().getGeneralConfig();
    final double durationHours =
        (appConfig[FirestoreAppConfigFields.sessionDurationHours] as num?)
            ?.toDouble() ??
        24.0;
    final now = DateTime.now();
    DateTime end = now.add(Duration(minutes: (durationHours * 60).toInt()));

    if (maxEnd != null && maxEnd.isBefore(end)) {
      end = maxEnd;
    }

    final userRef = _db.collection(FirestoreConstants.users).doc(uid);

    final batch = _db.batch();

    final userUpdate = {
      FirestoreUserFields.lastMiningStart: Timestamp.fromDate(now),
      FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(end),
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(now),
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
    };
    if (deviceId != null) {
      userUpdate[FirestoreUserFields.deviceId] = deviceId;
    }

    batch.set(userRef, userUpdate, SetOptions(merge: true));

    await batch.commit();

    // 3. Update Rank (Async)
    RankEngine.updateUserRank(uid);

    // 4. Return merged state
    return {
      ...rates,
      FirestoreUserFields.lastMiningStart: Timestamp.fromDate(now),
      FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(end),
      FirestoreUserFields.lastSyncedAt: Timestamp.fromDate(now),
      // We don't have totalPoints here, but MiningStateService preserves it if missing in result
      // or we can fetch it?
      // Better to let MiningStateService keep its current totalPoints if not returned.
      // But MiningStateService logic:
      // _totalPoints = (res[totalPoints] as num?)?.toDouble() ?? _totalPoints;
      // So if we omit it, it keeps existing. That's fine.
    };
  }
}
