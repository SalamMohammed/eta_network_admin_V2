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
  static const Duration _cacheDuration = Duration(hours: 24);

  Map<String, dynamic>? _memoryCache;

  /// Fetches the general app config.
  /// Uses local cache if available and not expired (< 24 hours).
  /// Otherwise fetches from Firestore and updates cache.
  Future<Map<String, dynamic>> getGeneralConfig({
    bool forceRefresh = false,
  }) async {
    // 1. Return memory cache if available and valid (for this session)
    if (!forceRefresh && _memoryCache != null) {
      return _memoryCache!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // 2. Check disk cache
      if (!forceRefresh) {
        final int? ts = prefs.getInt(_prefsKeyGeneralTs);
        if (ts != null) {
          final cachedTime = DateTime.fromMillisecondsSinceEpoch(ts);
          if (DateTime.now().difference(cachedTime) < _cacheDuration) {
            final String? jsonStr = prefs.getString(_prefsKeyGeneral);
            if (jsonStr != null) {
              try {
                final Map<String, dynamic> data = jsonDecode(jsonStr);
                _memoryCache = data;
                debugPrint(
                  'ConfigService: Using cached config (age: ${DateTime.now().difference(cachedTime).inMinutes} min)',
                );
                return data;
              } catch (e) {
                debugPrint('ConfigService: Error decoding cached config: $e');
              }
            }
          }
        }
      }

      // 3. Fetch from Firestore
      debugPrint('ConfigService: Fetching config from Firestore');
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.appConfig)
          .doc(FirestoreAppConfigDocs.general)
          .get();

      final data = doc.data() ?? {};

      // 4. Save to cache
      _memoryCache = data;
      await prefs.setString(
        _prefsKeyGeneral,
        jsonEncode(_dataToJsonSafe(data)),
      );
      await prefs.setInt(
        _prefsKeyGeneralTs,
        DateTime.now().millisecondsSinceEpoch,
      );

      return data;
    } catch (e) {
      debugPrint('ConfigService: Error fetching config: $e');
      return _memoryCache ?? {};
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
