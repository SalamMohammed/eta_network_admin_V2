import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/firestore_constants.dart';

class SqlApiService {
  // TODO: Replace with your actual domain when provided by user
  static const String _baseUrl = 'https://jawayiz.com/api';

  // Cache the token to minimize calls
  static String? _cachedToken;
  static DateTime? _tokenExpiry;

  /// Gets a valid Firebase ID Token.
  /// Refreshes only if expired or missing.
  static Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final now = DateTime.now();
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        now.isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    try {
      // forceRefresh: false is the key to "natural" authentication
      // It only fetches a new token if the old one is about to expire (1 hour)
      final token = await user.getIdToken(false);
      _cachedToken = token;
      // Tokens last 1 hour, so we cache it for 55 minutes to be safe
      _tokenExpiry = now.add(const Duration(minutes: 55));
      return token;
    } catch (e) {
      debugPrint('[SqlApiService] Token fetch failed: $e');
      return null;
    }
  }

  /// Generic GET request with Auth Header
  static Future<List<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      debugPrint('[SqlApiService] No auth token available');
      return [];
    }

    Uri uri = Uri.parse('$_baseUrl/$endpoint');
    if (params != null) {
      uri = uri.replace(queryParameters: params);
    }

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        debugPrint(
          '[SqlApiService] HTTP ${response.statusCode}: ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('[SqlApiService] Request failed: $e');
      return [];
    }
  }

  /// Generic GET request for a single object
  static Future<Map<String, dynamic>?> getSingle(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    final token = await _getAuthToken();
    if (token == null) return null;

    Uri uri = Uri.parse('$_baseUrl/$endpoint');
    if (params != null) {
      uri = uri.replace(queryParameters: params);
    }

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return null;
      }
      return null;
    } catch (e) {
      debugPrint('[SqlApiService] Request failed: $e');
      return null;
    }
  }

  /// Generic POST request with Auth Header
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await _getAuthToken();
    if (token == null) {
      debugPrint('[SqlApiService] No auth token available');
      throw Exception('Authentication failed');
    }

    final uri = Uri.parse('$_baseUrl/$endpoint');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {'success': true, 'data': decoded};
      } else {
        debugPrint(
          '[SqlApiService] POST HTTP ${response.statusCode}: ${response.body}',
        );
        String msg = 'Server error: ${response.statusCode}';
        try {
          final err = json.decode(response.body);
          if (err is Map && (err['error'] != null || err['message'] != null)) {
            msg = err['error'] ?? err['message'];
          }
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('[SqlApiService] POST Request failed: $e');
      rethrow;
    }
  }

  /// Start mining session
  static Future<Map<String, dynamic>> startCoinMining({
    required String coinOwnerId,
    required double hourlyRate,
    required DateTime start,
    required DateTime end,
    String? deviceId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    // Note: We do NOT explicitly sync earnings here anymore because
    // start_mining_session.php now automatically calculates and adds
    // the previous session's pending earnings before starting the new one.
    // This ensures "chunk" updates as requested.

    final response = await post('start_mining_session.php', {
      'uid': uid,
      'coinOwnerId': coinOwnerId,
      'hourlyRate': hourlyRate,
      'lastMiningStart': start.toIso8601String(),
      'lastMiningEnd': end.toIso8601String(),
      'lastSyncedAt': start.toIso8601String(),
      'deviceId': deviceId,
    });

    return response;
  }

  /// Sync mining earnings
  static Future<void> syncCoinEarnings({
    required String coinOwnerId,
    required double amount,
    required DateTime lastSyncedAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final res = await post('sync_mining_session.php', {
        'uid': uid,
        'coinOwnerId': coinOwnerId,
        'amount': amount,
        'lastSyncedAt': lastSyncedAt.toIso8601String(),
      });
      debugPrint('[SqlApiService] Sync response: $res');
    } catch (e) {
      debugPrint('[SqlApiService] Sync failed: $e');
    }
  }

  /// Check if coin name/symbol is unique
  static Future<void> checkCoinUniqueness({
    String? name,
    String? symbol,
    required String excludeUid,
  }) async {
    final result = await post('check_coin_uniqueness.php', {
      'name': name,
      'symbol': symbol,
      'excludeUid': excludeUid,
    });

    if (result['available'] != true) {
      throw Exception(
        result['message'] ?? 'Coin name or symbol already taken.',
      );
    }
  }

  /// Create or Update Coin
  static Future<void> createOrUpdateCoin(Map<String, dynamic> coinData) async {
    await post('create_update_coin.php', coinData);
  }

  /// Add coin to my mining list
  static Future<void> addToMyCoins(String coinOwnerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    await post('add_to_my_coins.php', {
      'coinOwnerId': coinOwnerId,
      'uid': uid, // Pass UID explicitly for simpler PHP
    });
  }

  /// Get my own coin (created by me)
  static Future<Map<String, dynamic>?> getUserCoin(
    String uid, {
    String? viewerId,
  }) async {
    final params = {'uid': uid};
    if (viewerId != null && viewerId.isNotEmpty) {
      params['viewerId'] = viewerId;
    }
    return await getSingle('get_user_coin.php', params: params);
  }

  /// Delete my coin
  static Future<void> deleteUserCoin(String uid) async {
    await post('delete_user_coin.php', {'uid': uid});
  }

  /// Fetch "My Mined Coins" from SQL
  static Future<List<Map<String, dynamic>>> getMyCoins(String uid) async {
    return await get('get_my_coins.php', params: {'uid': uid});
  }

  /// Fetch "Live Coins" (Market) from SQL
  static Future<List<Map<String, dynamic>>> getLiveCoins({
    String sort = 'popular',
  }) async {
    return await get('get_live_coins.php', params: {'sort': sort});
  }
}
