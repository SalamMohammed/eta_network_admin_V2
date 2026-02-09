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

  /// Fetch the user document.
  /// [freshness] defines how old the cache can be before refetching.
  /// Default is 5 seconds to deduplicate simultaneous startup calls.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUser(
    String uid, {
    bool forceRefresh = false,
    Duration freshness = const Duration(seconds: 5),
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

    debugPrint('UserService: Fetching realtime document from Firestore');
    _pendingRealtimeRequest = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime)
        .get();

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
}
