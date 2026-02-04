import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../shared/firestore_constants.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  DocumentSnapshot<Map<String, dynamic>>? _cachedUserSnapshot;
  DateTime? _lastFetchTime;
  Future<DocumentSnapshot<Map<String, dynamic>>?>? _pendingRequest;

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
    _pendingRequest = FirebaseFirestore.instance
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
}
