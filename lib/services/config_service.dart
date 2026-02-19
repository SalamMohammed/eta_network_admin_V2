import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/firestore_helper.dart';
import '../shared/firestore_constants.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static const String _prefsKeyMaster = 'app_config_master_cache';
  static const String _prefsKeyMasterTs = 'app_config_master_ts';
  static const String _prefsKeyGeneral = 'app_config_general_cache';
  static const String _prefsKeyGeneralTs = 'app_config_general_ts';
  static const String _prefsKeyStreak = 'app_config_streak_cache';
  static const String _prefsKeyStreakTs = 'app_config_streak_ts';
  static const String _prefsKeyRanks = 'app_config_ranks_cache';
  static const String _prefsKeyRanksTs = 'app_config_ranks_ts';
  static const String _prefsKeyReferrals = 'app_config_referrals_cache';
  static const String _prefsKeyReferralsTs = 'app_config_referrals_ts';
  static const String _prefsKeyUserCoin = 'app_config_user_coin_cache';
  static const String _prefsKeyUserCoinTs = 'app_config_user_coin_ts';
  static const String _prefsKeyLegal = 'app_config_legal_cache';
  static const String _prefsKeyLegalTs = 'app_config_legal_ts';
  static const Duration _cacheDuration = Duration(hours: 24);

  final Map<String, Map<String, dynamic>> _memoryCache = {};
  Map<String, dynamic>? _masterCache;

  Future<Map<String, dynamic>> getGeneralConfig({
    bool forceRefresh = false,
  }) async {
    final master = await _getMasterConfig(forceRefresh: forceRefresh);
    if (master.containsKey(FirestoreAppConfigDocs.general)) {
      return Map<String, dynamic>.from(master[FirestoreAppConfigDocs.general]);
    }
    return _getConfig(
      FirestoreAppConfigDocs.general,
      _prefsKeyGeneral,
      _prefsKeyGeneralTs,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> getStreakConfig({
    bool forceRefresh = false,
  }) async {
    final master = await _getMasterConfig(forceRefresh: forceRefresh);
    if (master.containsKey(FirestoreAppConfigDocs.streak)) {
      return Map<String, dynamic>.from(master[FirestoreAppConfigDocs.streak]);
    }
    return _getConfig(
      FirestoreAppConfigDocs.streak,
      _prefsKeyStreak,
      _prefsKeyStreakTs,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> getRanksConfig({
    bool forceRefresh = false,
  }) async {
    final master = await _getMasterConfig(forceRefresh: forceRefresh);
    if (master.containsKey(FirestoreAppConfigDocs.ranks)) {
      return Map<String, dynamic>.from(master[FirestoreAppConfigDocs.ranks]);
    }
    return _getConfig(
      FirestoreAppConfigDocs.ranks,
      _prefsKeyRanks,
      _prefsKeyRanksTs,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> getReferralConfig({
    bool forceRefresh = false,
  }) async {
    final master = await _getMasterConfig(forceRefresh: forceRefresh);
    final section = master[FirestoreAppConfigDocs.referrals];
    if (section is Map<String, dynamic>) {
      return Map<String, dynamic>.from(section);
    }
    debugPrint(
      'ConfigService: referrals config missing in master; referral bonuses disabled',
    );
    return {};
  }

  Future<Map<String, dynamic>> getUserCoinConfig({
    bool forceRefresh = false,
  }) async {
    final master = await _getMasterConfig(forceRefresh: forceRefresh);
    final section = master[FirestoreAppConfigDocs.userCoin];
    if (section is Map<String, dynamic>) {
      return Map<String, dynamic>.from(section);
    }
    return _getConfig(
      FirestoreAppConfigDocs.userCoin,
      _prefsKeyUserCoin,
      _prefsKeyUserCoinTs,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> getLegalConfig({
    bool forceRefresh = false,
  }) async {
    final master = await _getMasterConfig(forceRefresh: forceRefresh);
    final section = master[FirestoreAppConfigDocs.legal];
    if (section is Map<String, dynamic>) {
      return Map<String, dynamic>.from(section);
    }
    return _getConfig(
      FirestoreAppConfigDocs.legal,
      _prefsKeyLegal,
      _prefsKeyLegalTs,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> getAdsConfig({bool forceRefresh = false}) async {
    final master = await _getMasterConfig(forceRefresh: forceRefresh);
    final section = master[FirestoreAppConfigDocs.ads];
    if (section is Map<String, dynamic>) {
      return Map<String, dynamic>.from(section);
    }
    debugPrint('ConfigService: ads config missing in master');
    return {};
  }

  Future<Map<String, dynamic>> _getMasterConfig({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _masterCache != null) {
      return _masterCache!;
    }

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      if (!forceRefresh) {
        final int? ts = prefs.getInt(_prefsKeyMasterTs);
        if (ts != null) {
          final cachedTime = DateTime.fromMillisecondsSinceEpoch(ts);
          if (DateTime.now().difference(cachedTime) < _cacheDuration) {
            final String? jsonStr = prefs.getString(_prefsKeyMaster);
            if (jsonStr != null) {
              _masterCache = jsonDecode(jsonStr);
              return _masterCache!;
            }
          }
        }
      }

      debugPrint('ConfigService: Fetching Master Config from Firestore');
      final doc = await FirestoreHelper.instance
          .collection(FirestoreConstants.appConfig)
          .doc(FirestoreAppConfigDocs.master)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        _masterCache = data;
        await prefs.setString(
          _prefsKeyMaster,
          jsonEncode(_dataToJsonSafe(data)),
        );
        await prefs.setInt(
          _prefsKeyMasterTs,
          DateTime.now().millisecondsSinceEpoch,
        );
        return data;
      }
    } catch (e) {
      debugPrint('ConfigService: Error fetching master config: $e');
      if (prefs == null) {
        try {
          prefs = await SharedPreferences.getInstance();
        } catch (_) {}
      }
    }

    if (prefs != null) {
      try {
        final String? jsonStr = prefs.getString(_prefsKeyMaster);
        if (jsonStr != null) {
          _masterCache = jsonDecode(jsonStr);
          return _masterCache!;
        }
      } catch (e) {
        debugPrint('ConfigService: Error reading cached master config: $e');
      }
    }
    return {};
  }

  Future<Map<String, dynamic>> _getConfig(
    String docId,
    String cacheKey,
    String tsKey, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _memoryCache.containsKey(docId)) {
      return _memoryCache[docId]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!forceRefresh) {
        final int? ts = prefs.getInt(tsKey);
        if (ts != null) {
          final cachedTime = DateTime.fromMillisecondsSinceEpoch(ts);
          if (DateTime.now().difference(cachedTime) < _cacheDuration) {
            final String? jsonStr = prefs.getString(cacheKey);
            if (jsonStr != null) {
              try {
                final Map<String, dynamic> data = jsonDecode(jsonStr);
                _memoryCache[docId] = data;
                debugPrint(
                  'ConfigService: Using cached $docId config (age: ${DateTime.now().difference(cachedTime).inMinutes} min)',
                );
                return data;
              } catch (e) {
                debugPrint('ConfigService: Error decoding cached $docId: $e');
              }
            }
          }
        }
      }

      debugPrint('ConfigService: Fetching $docId config from Firestore');
      final doc = await FirestoreHelper.instance
          .collection(FirestoreConstants.appConfig)
          .doc(docId)
          .get();

      final data = doc.data() ?? {};
      _memoryCache[docId] = data;
      await prefs.setString(cacheKey, jsonEncode(_dataToJsonSafe(data)));
      await prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
      return data;
    } catch (e) {
      debugPrint('ConfigService: Error fetching $docId: $e');
      return _memoryCache[docId] ?? {};
    }
  }

  /// Helper to ensure data is JSON encodable (handle Timestamps)
  Map<String, dynamic> _dataToJsonSafe(Map<String, dynamic> data) {
    final Map<String, dynamic> safeData = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        safeData[key] = value.millisecondsSinceEpoch; // Store as int
      } else if (value is Map) {
        safeData[key] = _dataToJsonSafe(Map<String, dynamic>.from(value));
      } else {
        safeData[key] = value;
      }
    });
    return safeData;
  }
}
