import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/firestore_constants.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static const String _prefsKeyGeneral = 'app_config_general_cache';
  static const String _prefsKeyGeneralTs = 'app_config_general_ts';
  static const String _prefsKeyStreak = 'app_config_streak_cache';
  static const String _prefsKeyStreakTs = 'app_config_streak_ts';
  static const String _prefsKeyRanks = 'app_config_ranks_cache';
  static const String _prefsKeyRanksTs = 'app_config_ranks_ts';
  static const String _prefsKeyReferrals = 'app_config_referrals_cache';
  static const String _prefsKeyReferralsTs = 'app_config_referrals_ts';
  static const Duration _cacheDuration = Duration(hours: 24);

  final Map<String, Map<String, dynamic>> _memoryCache = {};

  Future<Map<String, dynamic>> getGeneralConfig({bool forceRefresh = false}) {
    return _getConfig(
      FirestoreAppConfigDocs.general,
      _prefsKeyGeneral,
      _prefsKeyGeneralTs,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> getStreakConfig({bool forceRefresh = false}) {
    return _getConfig(
      FirestoreAppConfigDocs.streak,
      _prefsKeyStreak,
      _prefsKeyStreakTs,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> getRanksConfig({bool forceRefresh = false}) {
    return _getConfig(
      FirestoreAppConfigDocs.ranks,
      _prefsKeyRanks,
      _prefsKeyRanksTs,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>> getReferralConfig({bool forceRefresh = false}) {
    return _getConfig(
      FirestoreAppConfigDocs.referrals,
      _prefsKeyReferrals,
      _prefsKeyReferralsTs,
      forceRefresh: forceRefresh,
    );
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
      final doc = await FirebaseFirestore.instance
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
