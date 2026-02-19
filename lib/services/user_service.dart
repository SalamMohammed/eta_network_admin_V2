import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/firestore_helper.dart';
import '../shared/firestore_constants.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  DocumentSnapshot<Map<String, dynamic>>? _cachedUserSnapshot;
  DateTime? _lastFetchTime;
  Future<DocumentSnapshot<Map<String, dynamic>>?>? _pendingRequest;

  DocumentSnapshot<Map<String, dynamic>>? _cachedRealtimeSnapshot;
  DateTime? _lastRealtimeFetchTime;
  Future<DocumentSnapshot<Map<String, dynamic>>?>? _pendingRealtimeRequest;

  bool _isLive = false;

  /// Sets whether the service is receiving real-time updates.
  /// If true, [getUser] will return the cached snapshot regardless of freshness,
  /// assuming the cache is being kept up-to-date by an external listener.
  void setLiveMode(bool isLive) {
    _isLive = isLive;
    debugPrint('UserService: Live mode set to $isLive');
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUser(
    String uid, {
    bool forceRefresh = false,
    Duration freshness = const Duration(seconds: 60),
  }) async {
    if (forceRefresh) {
      _cachedUserSnapshot = null;
      _pendingRequest = null;
    }

    if (_cachedUserSnapshot != null && _pendingRequest == null) {
      // If in live mode, we trust the cache implicitly as it's updated by a listener
      if (_isLive) {
        // debugPrint('UserService: Returning cached user snapshot (Live Mode)');
        return _cachedUserSnapshot;
      }

      if (_lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < freshness) {
        debugPrint('UserService: Returning cached user snapshot');
        return _cachedUserSnapshot;
      }
    }

    if (_pendingRequest != null) {
      debugPrint('UserService: Returning pending user request');
      return _pendingRequest;
    }

    debugPrint('UserService: Fetching user document from Firestore');
    _pendingRequest = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .get();

    try {
      final snap = await _pendingRequest;
      _cachedUserSnapshot = snap;
      _lastFetchTime = DateTime.now();
      return snap;
    } catch (e) {
      debugPrint('UserService: Error fetching user: $e');
      return null;
    } finally {
      _pendingRequest = null;
    }
  }

  /// Manually update the cache if a fresh snapshot is obtained elsewhere
  void updateCache(DocumentSnapshot<Map<String, dynamic>> snap) {
    _cachedUserSnapshot = snap;
    _lastFetchTime = DateTime.now();
  }

  /// Fetch the realtime earnings document.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getRealtimeDoc(
    String uid, {
    bool forceRefresh = false,
    Duration freshness = const Duration(seconds: 5),
  }) async {
    // Before using cache, determine the correct source based on migration status
    // If user is not migrated, fetch users/{uid}/earnings/realtime; otherwise users/{uid}
    if (forceRefresh) {
      _cachedRealtimeSnapshot = null;
      _pendingRealtimeRequest = null;
    }

    if (_cachedRealtimeSnapshot != null && _pendingRealtimeRequest == null) {
      if (_isLive) {
        return _cachedRealtimeSnapshot;
      }
      if (_lastRealtimeFetchTime != null &&
          DateTime.now().difference(_lastRealtimeFetchTime!) < freshness) {
        debugPrint('UserService: Returning cached realtime snapshot');
        return _cachedRealtimeSnapshot;
      }
    }

    if (_pendingRealtimeRequest != null) {
      debugPrint('UserService: Returning pending realtime request');
      return _pendingRealtimeRequest;
    }

    // Determine migration status cheaply; prefer cached user if present
    bool migrated = false;
    if (_cachedUserSnapshot != null) {
      final d = _cachedUserSnapshot!.data() ?? {};
      migrated =
          (d[FirestoreUserFields.migrationUnifiedEarnings] as bool?) == true;
    } else {
      try {
        final userSnap = await FirestoreHelper.instance
            .collection(FirestoreConstants.users)
            .doc(uid)
            .get();
        _cachedUserSnapshot = userSnap;
        _lastFetchTime = DateTime.now();
        final d = userSnap.data() ?? {};
        migrated =
            (d[FirestoreUserFields.migrationUnifiedEarnings] as bool?) == true;
      } catch (e) {
        debugPrint('UserService: Error checking migration flag: $e');
      }
    }

    if (migrated) {
      debugPrint(
        'UserService: Fetching unified user document for realtime data (migrated)',
      );
      _pendingRealtimeRequest = FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .get();
    } else {
      debugPrint(
        'UserService: Fetching legacy realtime document (pre-migration)',
      );
      _pendingRealtimeRequest = FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .collection(FirestoreUserSubCollections.earnings)
          .doc(FirestoreEarningsDocs.realtime)
          .get();
    }

    try {
      final snap = await _pendingRealtimeRequest;
      _cachedRealtimeSnapshot = snap;
      _lastRealtimeFetchTime = DateTime.now();
      return snap;
    } catch (e) {
      debugPrint('UserService: Error fetching realtime doc: $e');
      return null;
    } finally {
      _pendingRealtimeRequest = null;
    }
  }

  /// Manually update the realtime cache
  void updateRealtimeCache(DocumentSnapshot<Map<String, dynamic>> snap) {
    _cachedRealtimeSnapshot = snap;
    _lastRealtimeFetchTime = DateTime.now();
  }

  /// Extracts a field value from a potentially consolidated user document,
  /// with fallback to the root document for backward compatibility.
  static dynamic getField(
    DocumentSnapshot<Map<String, dynamic>> snap,
    String field,
  ) {
    final data = snap.data();
    if (data == null) return null;

    // Check consolidated maps first
    if (data.containsKey(FirestoreUserFields.meta)) {
      final meta = data[FirestoreUserFields.meta] as Map<String, dynamic>?;
      if (meta != null && meta.containsKey(field)) return meta[field];
    }
    if (data.containsKey(FirestoreUserFields.stats)) {
      final stats = data[FirestoreUserFields.stats] as Map<String, dynamic>?;
      if (stats != null && stats.containsKey(field)) return stats[field];
    }
    if (data.containsKey(FirestoreUserFields.mining)) {
      final mining = data[FirestoreUserFields.mining] as Map<String, dynamic>?;
      if (mining != null && mining.containsKey(field)) return mining[field];
    }
    if (data.containsKey(FirestoreUserFields.manager)) {
      final manager =
          data[FirestoreUserFields.manager] as Map<String, dynamic>?;
      if (manager != null && manager.containsKey(field)) return manager[field];
    }
    if (data.containsKey(FirestoreUserFields.wallet)) {
      final wallet = data[FirestoreUserFields.wallet] as Map<String, dynamic>?;
      if (wallet != null && wallet.containsKey(field)) return wallet[field];
    }

    // Fallback to root document
    return data[field];
  }
}
