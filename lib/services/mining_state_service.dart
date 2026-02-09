import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../utils/firestore_helper.dart';
import '../shared/firestore_constants.dart';
import 'earnings_engine.dart';
import '../shared/device_id.dart';
import 'subscription_service.dart';
import 'notification_service.dart';
import 'config_service.dart';
import 'user_service.dart';
import 'coin_service.dart';
import 'sql_api_service.dart';
import 'background_service.dart';

class MiningStateService extends ChangeNotifier with WidgetsBindingObserver {
  static final MiningStateService _instance = MiningStateService._internal();
  factory MiningStateService() => _instance;
  MiningStateService._internal() {
    // Listen for auth changes to manage lifecycle automatically
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        init();
      } else {
        reset();
      }
    });
  }

  // Mining state
  double _totalPoints = 0.0;
  double _hourlyRate = 0.0;
  // Rate Components
  double _rateBase = 0.0;
  double _rateStreak = 0.0;
  double _rateRank = 0.0;
  double _rateReferral = 0.0;
  double _rateManager = 0.0;
  double _rateAds = 0.0;

  Timestamp? _lastStart;
  Timestamp? _lastEnd;
  bool _miningActive = false;
  double _sessionHours = 24.0;
  int _streakDays = 0;

  // Manager state
  bool _managerEnabled = false;
  bool _managerGlobalEnabled = false;
  bool _managerEtaAuto = false;
  bool _managerUserCoinAuto = false;
  int _managerMaxCommunity = 0;
  String? _activeManagerId;
  List<String> _managedCoinSelections = const [];
  Timestamp? _subscriptionExpiresAt;
  double _activeManagerMultiplier = 1.0;

  // Manager Cache
  Map<String, dynamic>? _cachedManagerData;
  String? _cachedManagerId;
  DateTime? _lastManagerFetch;

  // Referral Cache
  int? _activeReferralCount;
  DateTime? _lastReferralCountFetch;

  // Simulation state
  double _displayTotal = 0.0;
  double _simBase = 0.0;
  DateTime? _simAnchor;
  Timer? _simTimer;
  String? _deviceId;
  bool _initialized = false;
  bool _isInitializing = false;
  DateTime? _lastUiNotify;
  double _lastNotifiedDisplay = -1;
  static const Duration _minUiNotifyInterval = Duration(seconds: 1);
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _realtimeDocSub;
  Timer? _subExpiryTimer;
  Timer? _refreshDebounce;
  DateTime? _lastRecalcAttempt;

  // Getters
  double get totalPoints => _totalPoints;
  double get hourlyRate => _hourlyRate;
  double get rateBase => _rateBase;
  double get rateStreak => _rateStreak;
  double get rateRank => _rateRank;
  double get rateReferral => _rateReferral;
  double get rateManager => _rateManager;
  double get rateAds => _rateAds;
  bool get miningActive => _miningActive;
  double get displayTotal => _displayTotal;
  bool get managerEnabled => _managerEnabled;
  bool get managerGlobalEnabled => _managerGlobalEnabled;
  bool get managerEtaAuto => _managerEtaAuto;
  bool get managerUserCoinAuto => _managerUserCoinAuto;
  int get managerMaxCommunity => _managerMaxCommunity;
  String? get activeManagerId => _activeManagerId;
  List<String> get managedCoinSelections => _managedCoinSelections;
  double get sessionHours => _sessionHours;
  Timestamp? get lastEnd => _lastEnd;
  Timestamp? get lastStart => _lastStart;
  int get streakDays => _streakDays;
  Timestamp? get subscriptionExpiresAt => _subscriptionExpiresAt;

  Future<void> stopMining() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final end = _lastEnd?.toDate();
    if (end != null && now.isBefore(end)) {
      await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .set({
            FirestoreUserFields.lastMiningEnd: Timestamp.fromDate(now),
            FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
    final res = await EarningsEngine.syncEarnings();
    _totalPoints =
        (res[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
        _totalPoints;

    _simTimer?.cancel();
    _simTimer = null;
    _miningActive = false;
    _lastEnd = Timestamp.fromDate(now);
    _displayTotal = _totalPoints;
    _maybeNotify(force: true);
  }

  Future<void> stopAllCoinMining() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final coinsRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins);
    final snap = await coinsRef.get();
    final batch = FirestoreHelper.instance.batch();
    int updates = 0;
    for (final d in snap.docs) {
      final data = d.data();
      final end =
          data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
      if (end == null) continue;
      if (!now.isBefore(end.toDate())) continue;
      batch.set(d.reference, {
        FirestoreUserCoinMiningFields.lastMiningEnd: Timestamp.fromDate(now),
      }, SetOptions(merge: true));
      updates++;
    }
    if (updates > 0) {
      await batch.commit();
    }
  }

  Future<void> init() async {
    if (_initialized || _isInitializing) return;
    _isInitializing = true;
    try {
      WidgetsBinding.instance.addObserver(this);
      _deviceId = await DeviceId.get();

      // Initialize dependencies
      await SubscriptionService().init();

      // Initial refresh
      await _refresh();

      // Start listeners
      UserService().setLiveMode(true);
      _startUserDocListener();
      _startRealtimeDocListener();
      _startSimulationIfNeeded();

      _initialized = true;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> refresh() async {
    await _refresh();
    _startSimulationIfNeeded();
    notifyListeners();
  }

  Future<void> _refresh() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Sync earnings to ensure accuracy before loading
    // OPTIMIZATION: Capture result to avoid redundant reads
    // Pass cached manager data to avoid redundant manager doc read in syncEarnings
    final syncRes = await EarningsEngine.syncEarnings(
      cachedManagerData: _cachedManagerData,
      cachedManagerId: _cachedManagerId,
    );

    // Load App Config
    final g = await ConfigService().getGeneralConfig();
    _sessionHours =
        ((g[FirestoreAppConfigFields.sessionDurationHours] as num?)
            ?.toDouble() ??
        24.0);

    // Fetch Active Referral Count (Throttled 10m)
    // Used for recalculating rates without expensive queries every time
    if (_activeReferralCount == null ||
        _lastReferralCountFetch == null ||
        DateTime.now().difference(_lastReferralCountFetch!).inMinutes > 10) {
      try {
        final countQuery = await FirestoreHelper.instance
            .collection(FirestoreConstants.users)
            .where(FirestoreUserFields.invitedBy, isEqualTo: uid)
            .where(
              FirestoreUserFields.lastMiningEnd,
              isGreaterThan: Timestamp.fromDate(DateTime.now()),
            )
            .count()
            .get();
        _activeReferralCount = countQuery.count;
        _lastReferralCountFetch = DateTime.now();
      } catch (e) {
        debugPrint('Failed to fetch active referral count: $e');
      }
    }

    // Load User Data
    // OPTIMIZATION: Use data from syncRes if available to avoid UserService call
    Map<String, dynamic> d =
        (syncRes['userData'] as Map<String, dynamic>?) ?? {};
    if (d.isEmpty) {
      final snap = await UserService().getUser(uid);
      d = snap?.data() ?? {};
    }

    // Load Realtime Data
    // OPTIMIZATION: Use totalPoints from syncRes (which already merged realtime+user)
    // instead of fetching realtimeRef again.
    double? totalPoints = (syncRes[FirestoreUserFields.totalPoints] as num?)
        ?.toDouble();

    if (totalPoints == null) {
      // Fallback: Manually fetch if syncRes failed (unlikely)
      final userRef = FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid);
      final realtimeSnap = await userRef
          .collection(FirestoreUserSubCollections.earnings)
          .doc(FirestoreEarningsDocs.realtime)
          .get();
      final realtimeData = realtimeSnap.data() ?? {};
      final realtimePoints =
          (realtimeData[FirestoreUserFields.totalPoints] as num?)?.toDouble();
      final userDocPoints =
          (d[FirestoreUserFields.totalPoints] as num?)?.toDouble() ?? 0.0;
      totalPoints = realtimePoints ?? userDocPoints;
    }

    _totalPoints = totalPoints;

    _hourlyRate =
        (syncRes[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
        (d[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
        0.0;

    // Read Components
    _rateBase =
        (syncRes[FirestoreUserFields.rateBase] as num?)?.toDouble() ?? 0.0;
    _rateStreak =
        (syncRes[FirestoreUserFields.rateStreak] as num?)?.toDouble() ?? 0.0;
    _rateRank =
        (syncRes[FirestoreUserFields.rateRank] as num?)?.toDouble() ?? 0.0;
    _rateReferral =
        (syncRes[FirestoreUserFields.rateReferral] as num?)?.toDouble() ?? 0.0;
    _rateManager =
        (syncRes[FirestoreUserFields.rateManager] as num?)?.toDouble() ?? 0.0;
    _rateAds =
        (syncRes[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? 0.0;

    _lastStart = d[FirestoreUserFields.lastMiningStart] as Timestamp?;
    _lastEnd = d[FirestoreUserFields.lastMiningEnd] as Timestamp?;
    _streakDays = (d[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;

    final now = DateTime.now();
    _miningActive = _lastEnd != null && now.isBefore(_lastEnd!.toDate());

    // Migration Check: If mining is active but components are missing (e.g. rateBase is 0),
    // trigger recalculation to populate components and infer ads.
    // Throttle this to prevent infinite loops if recalculation fails or mining is actually ended.
    if (_miningActive &&
        _rateBase == 0.0 &&
        _hourlyRate > 0.0 &&
        (_lastRecalcAttempt == null ||
            DateTime.now().difference(_lastRecalcAttempt!).inSeconds > 60)) {
      _lastRecalcAttempt = DateTime.now();
      unawaited(
        EarningsEngine.recalculateRates(
          uid: uid,
          cachedManagerData: _cachedManagerData,
          cachedManagerId: _cachedManagerId,
          activeReferralCount: _activeReferralCount,
        ).then((rates) {
          // Update local state from returned rates
          if (rates.isNotEmpty) {
            _rateBase =
                (rates[FirestoreUserFields.rateBase] as num?)?.toDouble() ??
                _rateBase;
            _rateStreak =
                (rates[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
                _rateStreak;
            _rateRank =
                (rates[FirestoreUserFields.rateRank] as num?)?.toDouble() ??
                _rateRank;
            _rateReferral =
                (rates[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
                _rateReferral;
            _rateManager =
                (rates[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
                _rateManager;
            _rateAds =
                (rates[FirestoreUserFields.rateAds] as num?)?.toDouble() ??
                _rateAds;
            _hourlyRate =
                (rates[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
                _hourlyRate;
            notifyListeners();
          }
        }),
      );
    }

    // Initialize display total if not already simulating
    if (!_miningActive || _simTimer == null) {
      _displayTotal = _totalPoints;
    }

    // Manager Data
    final sub = d[FirestoreUserFields.subscription] as Map<String, dynamic>?;
    final subStatus = sub?[FirestoreUserSubscriptionFields.status] as String?;
    final subExpires =
        sub?[FirestoreUserSubscriptionFields.expiresAt] as Timestamp?;
    _subscriptionExpiresAt = subExpires;

    final bool subscriptionExpired =
        subExpires != null && now.isAfter(subExpires.toDate());

    bool isSubActive = subStatus == 'active';
    if (isSubActive && subExpires != null) {
      if (now.isAfter(subExpires.toDate())) {
        isSubActive = false;
        final existingRole = d[FirestoreUserFields.role] as String?;
        final roleToWrite = existingRole == FirestoreUserRoles.admin
            ? FirestoreUserRoles.admin
            : FirestoreUserRoles.free;
        await FirestoreHelper.instance
            .collection(FirestoreConstants.users)
            .doc(uid)
            .set({
              '${FirestoreUserFields.subscription}.${FirestoreUserSubscriptionFields.status}':
                  'expired',
              '${FirestoreUserFields.subscription}.${FirestoreUserSubscriptionFields.autoRenew}':
                  false,
              FirestoreUserFields.managerEnabled: false,
              FirestoreUserFields.role: roleToWrite,
              FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    }
    final managerEnabledFlag = d[FirestoreUserFields.managerEnabled] as bool?;
    _managerEnabled =
        !subscriptionExpired && (isSubActive || (managerEnabledFlag ?? false));

    _managedCoinSelections =
        ((syncRes[FirestoreUserFields.managedCoinSelections] as List?)
            ?.cast<String>()) ??
        ((d[FirestoreUserFields.managedCoinSelections] as List?)
            ?.cast<String>()) ??
        const [];
    _activeManagerId =
        (d[FirestoreUserFields.activeManagerId] as String?) ?? '';

    if (_activeManagerId != null && _activeManagerId!.isNotEmpty) {
      // OPTIMIZATION: Cache manager data for 10 minutes
      bool shouldUseCache = false;
      if (_cachedManagerData != null &&
          _cachedManagerId == _activeManagerId &&
          _lastManagerFetch != null) {
        if (DateTime.now().difference(_lastManagerFetch!).inMinutes < 10) {
          shouldUseCache = true;
        }
      }

      Map<String, dynamic> m;
      if (shouldUseCache) {
        m = _cachedManagerData!;
      } else {
        final mgr = await FirestoreHelper.instance
            .collection(FirestoreConstants.managers)
            .doc(_activeManagerId)
            .get();
        m = mgr.data() ?? {};
        _cachedManagerData = m;
        _cachedManagerId = _activeManagerId;
        _lastManagerFetch = DateTime.now();
      }

      _managerGlobalEnabled =
          (m[FirestoreManagerFields.globalCommunity] as bool?) ?? true;
      _managerEtaAuto =
          (m[FirestoreManagerFields.enableEtaAuto] as bool?) ?? true;
      _managerUserCoinAuto =
          (m[FirestoreManagerFields.enableUserCoinAuto] as bool?) ?? true;
      _managerMaxCommunity =
          (m[FirestoreManagerFields.maxCommunityCoinsManaged] as num?)
              ?.toInt() ??
          0;
      _activeManagerMultiplier =
          (m[FirestoreManagerFields.managerMultiplier] as num?)?.toDouble() ??
          2.0;

      // Update rates if manager status changed mid-session
      if (_miningActive) {
        await EarningsEngine.recalculateRates(
          uid: uid,
          cachedManagerData: _cachedManagerData,
          cachedManagerId: _cachedManagerId,
          activeReferralCount: _activeReferralCount,
        );
      }
    } else {
      _managerGlobalEnabled = false;
      _managerEtaAuto = false;
      _managerUserCoinAuto = false;
      _managerMaxCommunity = 0;
      _activeManagerMultiplier = 1.0;

      if (_miningActive) {
        await EarningsEngine.recalculateRates(
          uid: uid,
          cachedManagerData: _cachedManagerData,
          cachedManagerId: _cachedManagerId,
          activeReferralCount: _activeReferralCount,
        );
      }
    }

    // Auto-start mining if manager enabled
    if (_managerEnabled &&
        _managerGlobalEnabled &&
        _managerEtaAuto &&
        !_miningActive) {
      await startMining();
    }
  }

  // Removed _maybeApplyManagerMultiplier in favor of EarningsEngine.recalculateRates

  void _startUserDocListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Enable "Live Mode" in UserService so it trusts our pushed updates
    // instead of fetching redundantly.
    UserService().setLiveMode(true);

    _userDocSub?.cancel();
    _userDocSub = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .snapshots()
        .listen((snap) {
          // Push update to UserService cache
          if (snap.exists) {
            UserService().updateCache(snap);
          }

          final d = snap.data();
          if (d == null) return;
          final sub =
              d[FirestoreUserFields.subscription] as Map<String, dynamic>?;
          final subStatus =
              sub?[FirestoreUserSubscriptionFields.status] as String?;
          final subExpires =
              sub?[FirestoreUserSubscriptionFields.expiresAt] as Timestamp?;
          final now = DateTime.now();
          bool nextEnabled =
              (d[FirestoreUserFields.managerEnabled] as bool?) ?? false;
          final bool subEnabled = subStatus == 'active';
          if (!nextEnabled && subEnabled) {
            nextEnabled = true;
          }
          if (subEnabled &&
              subExpires != null &&
              now.isAfter(subExpires.toDate())) {
            nextEnabled =
                (d[FirestoreUserFields.managerEnabled] as bool?) ?? false;
          }

          final activeManagerId =
              (d[FirestoreUserFields.activeManagerId] as String?) ?? '';

          final bool shouldRefresh =
              nextEnabled != _managerEnabled ||
              subExpires?.millisecondsSinceEpoch !=
                  _subscriptionExpiresAt?.millisecondsSinceEpoch ||
              activeManagerId != (_activeManagerId ?? '');

          if (subExpires != null) {
            _scheduleExpiryRefresh(subExpires.toDate());
          } else {
            _subExpiryTimer?.cancel();
            _subExpiryTimer = null;
          }

          if (!shouldRefresh) return;
          _refreshDebounce?.cancel();
          _refreshDebounce = Timer(const Duration(milliseconds: 600), () {
            refresh();
          });
        });
  }

  void _startRealtimeDocListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _realtimeDocSub?.cancel();
    _realtimeDocSub = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.earnings)
        .doc(FirestoreEarningsDocs.realtime)
        .snapshots()
        .listen((snap) {
          if (snap.exists) {
            UserService().updateRealtimeCache(snap);
          }
          final d = snap.data();
          if (d == null) return;

          bool changed = false;

          // Update Total Points
          final newTotal = (d[FirestoreUserFields.totalPoints] as num?)
              ?.toDouble();
          if (newTotal != null && (newTotal - _totalPoints).abs() > 0.001) {
            _totalPoints = newTotal;
            changed = true;
          }

          // Update Hourly Rate and Components
          final newHourly = (d[FirestoreUserFields.hourlyRate] as num?)
              ?.toDouble();
          if (newHourly != null && (newHourly - _hourlyRate).abs() > 0.001) {
            _hourlyRate = newHourly;
            changed = true;
          }

          final newBase = (d[FirestoreUserFields.rateBase] as num?)?.toDouble();
          if (newBase != null) _rateBase = newBase;

          final newStreak = (d[FirestoreUserFields.rateStreak] as num?)
              ?.toDouble();
          if (newStreak != null) _rateStreak = newStreak;

          final newRank = (d[FirestoreUserFields.rateRank] as num?)?.toDouble();
          if (newRank != null) _rateRank = newRank;

          final newRef = (d[FirestoreUserFields.rateReferral] as num?)
              ?.toDouble();
          if (newRef != null) _rateReferral = newRef;

          final newMgr = (d[FirestoreUserFields.rateManager] as num?)
              ?.toDouble();
          if (newMgr != null) _rateManager = newMgr;

          final newAds = (d[FirestoreUserFields.rateAds] as num?)?.toDouble();
          if (newAds != null) _rateAds = newAds;

          if (changed) {
            if (_miningActive) {
              // If mining, update base so simulation continues from new total
              _simBase = _totalPoints;
              _simAnchor = DateTime.now();
            } else {
              _displayTotal = _totalPoints;
            }
            _maybeNotify(force: true);
          }
        });
  }

  void _scheduleExpiryRefresh(DateTime expiresAt) {
    _subExpiryTimer?.cancel();
    final now = DateTime.now();
    if (!expiresAt.isAfter(now)) return;
    final delay = expiresAt.difference(now);
    _subExpiryTimer = Timer(delay, () {
      refresh();
    });
  }

  Future<Map<String, dynamic>> startMining({DateTime? maxEnd}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }
    final devId = _deviceId ?? await DeviceId.get();
    try {
      final res = await EarningsEngine.startMining(
        uid: uid,
        deviceId: devId,
        maxEnd: maxEnd,
        cachedManagerData: _cachedManagerData,
        cachedManagerId: _cachedManagerId,
        activeReferralCount: _activeReferralCount,
      );

      _hourlyRate =
          (res[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          _hourlyRate;
      _rateBase =
          (res[FirestoreUserFields.rateBase] as num?)?.toDouble() ?? _rateBase;
      _rateStreak =
          (res[FirestoreUserFields.rateStreak] as num?)?.toDouble() ??
          _rateStreak;
      _rateRank =
          (res[FirestoreUserFields.rateRank] as num?)?.toDouble() ?? _rateRank;
      _rateReferral =
          (res[FirestoreUserFields.rateReferral] as num?)?.toDouble() ??
          _rateReferral;
      _rateManager =
          (res[FirestoreUserFields.rateManager] as num?)?.toDouble() ??
          _rateManager;
      _rateAds =
          (res[FirestoreUserFields.rateAds] as num?)?.toDouble() ?? _rateAds;

      _lastStart = res[FirestoreUserFields.lastMiningStart] as Timestamp?;
      _lastEnd = res[FirestoreUserFields.lastMiningEnd] as Timestamp?;
      _streakDays =
          (res[FirestoreUserFields.streakDays] as num?)?.toInt() ?? _streakDays;

      final now = DateTime.now();
      _miningActive = _lastEnd != null && now.isBefore(_lastEnd!.toDate());

      // Reset simulation base to current total when starting new session
      _totalPoints =
          (res[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
          _totalPoints;
      _displayTotal = _totalPoints;

      if ((_activeManagerId ?? '').isNotEmpty) {
        try {
          // OPTIMIZATION: Use cached manager data if valid
          Map<String, dynamic> m = {};
          if (_cachedManagerData != null &&
              _cachedManagerId == _activeManagerId &&
              _lastManagerFetch != null &&
              DateTime.now().difference(_lastManagerFetch!).inMinutes < 10) {
            m = _cachedManagerData!;
          } else {
            final mgr = await FirestoreHelper.instance
                .collection(FirestoreConstants.managers)
                .doc(_activeManagerId)
                .get();
            m = mgr.data() ?? {};
            // Update cache
            _cachedManagerData = m;
            _cachedManagerId = _activeManagerId;
            _lastManagerFetch = DateTime.now();
          }

          _activeManagerMultiplier =
              (m[FirestoreManagerFields.managerMultiplier] as num?)
                  ?.toDouble() ??
              _activeManagerMultiplier;

          // Re-calculate logic handled by EarningsEngine.recalculateRates via listener or explicit call if needed.
          // Note: startMining returns the rate it calculated, so we don't need to recalc here.
          // But if we want to ensure everything is consistent, we trust startMining result.
        } catch (_) {}
      }

      _startSimulationIfNeeded();

      // Schedule local notification as backup/primary
      if (_lastEnd != null) {
        unawaited(
          NotificationService().scheduleMiningFinished(_lastEnd!.toDate()),
        );
        // Also schedule background manager wakeup if enabled
        if (_managerEnabled) {
          unawaited(
            BackgroundService.scheduleManagerWakeup(_lastEnd!.toDate()),
          );
        }
      }

      _maybeNotify(force: true);
      return res;
    } catch (e) {
      debugPrint('Mining start failed: $e');
      rethrow;
    }
  }

  /// Boosts the ad rate by a calculated amount.
  /// Returns the amount of rate increase (boostAmount).
  /// Boosts the ad rate by a calculated amount.
  /// Returns the amount of rate increase (boostAmount).
  Future<double> boostAdRateNew({required double percent}) async {
    // Strictly use the admin-configured base rate (fetched from config/Firestore)
    // This ensures we calculate bonus based on the correct base, not total points or stale UI state.
    final baseRateToUse = _rateBase;

    if (baseRateToUse <= 0) return 0.0;
    if (percent <= 0) return 0.0;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0.0;

    if (!_miningActive) {
      return 0.0;
    }

    final frac = (percent / 100.0).clamp(0.0, 1e6);
    final boostAmount = baseRateToUse * frac;

    // Call new engine method
    await EarningsEngine.boostAdRate(uid: uid, boostAmount: boostAmount);

    // Update local state immediately for UI responsiveness
    _rateAds += boostAmount;
    _hourlyRate += boostAmount;

    // Notify UI
    notifyListeners();

    return boostAmount;
  }

  @Deprecated('Use boostAdRate instead')
  Future<double> claimAdReward({
    required double baseHourlyRate,
    required double percent,
  }) async {
    return boostAdRateNew(percent: percent);
  }

  @Deprecated('Use boostAdRate instead')
  Future<double> applyRewardedAdHourlyBoost({
    required double baseHourlyRate,
    required double percent,
    required int rewardedWatchIndex,
  }) async {
    // Forward to new logic
    await boostAdRateNew(percent: percent);
    return _hourlyRate;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _simTimer?.cancel();
      _simTimer = null;
      _refreshDebounce?.cancel(); // Cancel pending refresh
      _userDocSub?.cancel();
      _userDocSub = null;
      UserService().setLiveMode(false);
      _realtimeDocSub?.cancel();
      _realtimeDocSub = null;
      _subExpiryTimer?.cancel();
      _subExpiryTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _ensureTimerRunning();
      UserService().setLiveMode(true);
      _startUserDocListener();
      _startRealtimeDocListener();
      // Also refresh manually to ensure we catch anything the listener might miss during reconnection
      _refresh();
      // Re-schedule just in case something was missed or cleared
      if (_lastEnd != null && _managerEnabled) {
        BackgroundService.scheduleManagerWakeup(_lastEnd!.toDate());
      }
    }
  }

  void _startSimulationIfNeeded() {
    // If we're already simulating and parameters haven't changed drastically, let it run
    // But if we just refreshed and got new base points, we might need to adjust

    if (!_miningActive || _lastEnd == null) {
      _simTimer?.cancel();
      _simTimer = null;
      _displayTotal = _totalPoints;
      _maybeNotify(force: true);
      return;
    }

    // If timer is already running, we might just update the base if needed
    // But for simplicity and accuracy, we can restart it if the state changed significantly
    // or if it's not running.
    if (_simTimer != null) {
      // If simulation is running, we just ensure the parameters are up to date
      // But since we want continuity, we don't cancel unless necessary.
      // For now, let's only start if not running or if we need a hard reset.
      return;
    }

    _simBase = _totalPoints;
    _simAnchor = DateTime.now();
    _ensureTimerRunning();
  }

  void _ensureTimerRunning() {
    if (!_miningActive || _lastEnd == null) return;
    if (_simTimer != null) return;

    // Check lifecycle to avoid running in background
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;

    if (_simAnchor == null) {
      _simBase = _totalPoints;
      _simAnchor = DateTime.now();
    }

    final end = _lastEnd!.toDate();

    // Immediate update to ensure UI is fresh before first timer tick
    {
      final anchor = _simAnchor;
      if (anchor != null) {
        final now = DateTime.now();
        if (now.isBefore(end)) {
          final elapsedSec = now.difference(anchor).inMilliseconds / 1000.0;
          final remainingSec = end.difference(anchor).inSeconds.toDouble();
          final incPerSec = _hourlyRate > 0.0 ? (_hourlyRate / 3600.0) : 0.0;
          final inc = (elapsedSec * incPerSec).clamp(
            0.0,
            remainingSec * incPerSec,
          );
          _displayTotal = _simBase + inc;
          _maybeNotify(force: true);
        }
      }
    }

    _simTimer = Timer.periodic(const Duration(milliseconds: 5000), (_) {
      final anchor = _simAnchor;
      if (anchor == null) return;
      final now = DateTime.now();

      if (!now.isBefore(end)) {
        _simTimer?.cancel();
        _simTimer = null;
        _miningActive = false;
        // _displayTotal = _simBase; // Revert to base or fetch new?
        _maybeNotify(force: true);

        // Auto-refresh when session ends
        _refresh().then((_) => _maybeNotify(force: true));
        return;
      }

      final elapsedSec = now.difference(anchor).inMilliseconds / 1000.0;
      final remainingSec = end.difference(anchor).inSeconds.toDouble();
      final incPerSec = _hourlyRate > 0.0 ? (_hourlyRate / 3600.0) : 0.0;
      final inc = (elapsedSec * incPerSec).clamp(0.0, remainingSec * incPerSec);

      _displayTotal = _simBase + inc;
      _maybeNotify(force: false);
    });
  }

  // Method to update simulation base manually if needed (e.g. after sync)
  void updateSimulationBase(double newTotal) {
    _totalPoints = newTotal;
    if (_simTimer == null) {
      _displayTotal = newTotal;
    } else {
      // If simulating, we update the base and anchor to avoid jump?
      // Or we just let the next refresh handle it.
      // For smoothness, if we are in the middle of simulation,
      // we might want to just update the underlying total but keep the visual flow until next hard sync.
      // But to be accurate, we update base and anchor.
      _simBase = newTotal;
      _simAnchor = DateTime.now();
    }
    _maybeNotify(force: true);
  }

  void _maybeNotify({required bool force}) {
    final now = DateTime.now();
    final last = _lastUiNotify;
    final delta = (_displayTotal - _lastNotifiedDisplay).abs();
    final timeOk = last == null || now.difference(last) >= _minUiNotifyInterval;
    final valueOk = delta >= 0.01;
    if (force || valueOk || timeOk) {
      _lastUiNotify = now;
      _lastNotifiedDisplay = _displayTotal;
      notifyListeners();
    }
  }

  /// Resets the service state to default values.
  /// Call this when the user logs out.
  void reset() {
    WidgetsBinding.instance.removeObserver(this);
    _simTimer?.cancel();
    _simTimer = null;
    _userDocSub?.cancel();
    _userDocSub = null;
    _realtimeDocSub?.cancel();
    _realtimeDocSub = null;
    _subExpiryTimer?.cancel();
    _subExpiryTimer = null;
    _refreshDebounce?.cancel();
    _refreshDebounce = null;

    // Disable Live Mode as we are no longer pushing updates
    UserService().setLiveMode(false);

    _isInitializing = false;
    _initialized = false;
    _miningActive = false;

    _totalPoints = 0.0;
    _hourlyRate = 0.0;
    _lastStart = null;
    _lastEnd = null;
    _streakDays = 0;
    _displayTotal = 0.0;
    _simBase = 0.0;
    _simAnchor = null;

    _managerEnabled = false;
    _managerGlobalEnabled = false;
    _managerEtaAuto = false;
    _managerUserCoinAuto = false;
    _managerMaxCommunity = 0;
    _activeManagerId = null;
    _managedCoinSelections = const [];
    _subscriptionExpiresAt = null;
    _activeManagerMultiplier = 1.0;

    _cachedManagerData = null;
    _cachedManagerId = null;
    _lastManagerFetch = null;

    notifyListeners();
  }

  /// Runs the manager logic in the background (or foreground).
  /// Fetches fresh data to ensure accuracy.
  Future<void> runManagerLogic() async {
    debugPrint('[MiningStateService] runManagerLogic started');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('[MiningStateService] No user logged in');
      return;
    }

    // 1. Refresh state to get latest config/subscription
    // OPTIMIZATION: Check if user is pro and manager enabled BEFORE refreshing
    final userDoc = await UserService().getUser(uid);
    if (userDoc == null) {
      debugPrint('[MiningStateService] Failed to fetch user data');
      return;
    }
    final userData = userDoc.data() ?? {};
    final bool isPro =
        userData[FirestoreUserFields.role] == FirestoreUserRoles.pro;
    final bool managerEnabled =
        (userData[FirestoreUserFields.managerEnabled] as bool?) ?? false;

    if (!isPro || !managerEnabled) {
      debugPrint(
        '[MiningStateService] Access denied: not pro user or manager disabled',
      );
      return;
    }

    await _refresh();

    // If manager not enabled (double check after refresh), stop.
    if (!_managerEnabled || !_managerGlobalEnabled) {
      debugPrint('[MiningStateService] Manager disabled');
      return;
    }

    final devId = await DeviceId.get();
    final now = DateTime.now();

    // 2. Start OWN coin if needed
    if (_managerEtaAuto && !_miningActive) {
      debugPrint('[MiningStateService] Starting OWN coin mining...');
      try {
        await startMining();
      } catch (e) {
        debugPrint('[MiningStateService] Failed to start own mining: $e');
      }
    }

    // 3. Manage community coins
    // Need to fetch my coins first.
    // Use hybrid loading logic similar to HomePage
    List<Map<String, dynamic>> allCoins = [];

    // STRICT CHECK: Only run community coin logic if manager is actively enabled
    if (!_managerEnabled) {
      debugPrint(
        '[MiningStateService] Manager disabled, skipping community coins',
      );
      return;
    }

    try {
      final sqlCoins = await SqlApiService.getMyCoins(uid);
      if (sqlCoins != null) {
        allCoins = sqlCoins;
        // Inject into CoinService cache to avoid redundant reads in UI
        CoinService.updateMyCoinsCache(sqlCoins);
      }
    } catch (e) {
      debugPrint('[MiningStateService] SQL fetch failed: $e');
    }

    if (allCoins.isEmpty) {
      debugPrint('[MiningStateService] No coins found');
      return;
    }

    int activeManaged = 0;
    // First pass: count active
    for (final data in allCoins) {
      final ownerId =
          (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
      if (ownerId == uid) continue; // Skip own coin (handled by startMining)

      if (_managedCoinSelections.isNotEmpty &&
          !_managedCoinSelections.contains(ownerId)) {
        continue;
      }

      final dynamic rawEnd = data[FirestoreUserCoinMiningFields.lastMiningEnd];
      DateTime? end;
      if (rawEnd is Timestamp) {
        end = rawEnd.toDate();
      } else if (rawEnd is String) {
        end = DateTime.tryParse(rawEnd);
      }

      final isActive = end != null && now.isBefore(end);
      if (isActive) activeManaged++;
    }

    // Second pass: start mining if slots available
    for (final data in allCoins) {
      if (activeManaged >= _managerMaxCommunity) break;

      final ownerId =
          (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
      if (ownerId == uid) continue;

      if (_managedCoinSelections.isNotEmpty &&
          !_managedCoinSelections.contains(ownerId)) {
        continue;
      }

      final dynamic rawEnd = data[FirestoreUserCoinMiningFields.lastMiningEnd];
      DateTime? end;
      if (rawEnd is Timestamp) {
        end = rawEnd.toDate();
      } else if (rawEnd is String) {
        end = DateTime.tryParse(rawEnd);
      }

      final isActive = end != null && now.isBefore(end);
      if (!isActive) {
        debugPrint('[MiningStateService] Starting community coin: $ownerId');
        try {
          await CoinService.startCoinMining(
            ownerId,
            deviceId: devId,
            cachedCoinData: data,
          );
          activeManaged++;
        } catch (e) {
          debugPrint('[MiningStateService] Failed to start coin $ownerId: $e');
        }
      }
    }

    // 4. Schedule NEXT wakeup
    // We need to find the earliest end time among ALL active coins (own + community)
    // to ensure we wake up exactly when a session ends.
    DateTime? earliestEnd;

    // Check own coin
    if (_lastEnd != null) {
      final end = _lastEnd!.toDate();
      if (end.isAfter(now)) {
        earliestEnd = end;
      }
    }

    // Check community coins (re-fetch or use list if updated?
    // Ideally we should use updated list, but using existing list + assumptions is okay for now)
    // Actually, startCoinMining returns updated data, but we didn't update the list.
    // Let's just use the current known end times. If we just started one, it ends in 24h.
    // If we have an existing one ending in 1h, that's the one we want.

    for (final data in allCoins) {
      final ownerId =
          (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
      if (_managedCoinSelections.isNotEmpty &&
          !_managedCoinSelections.contains(ownerId)) {
        continue;
      }

      // Note: If we just started it, we don't have the new end time here unless we re-fetch.
      // But usually new session > existing session. So earliest is likely an existing one.
      // Unless all were inactive and we started all. Then next is 24h.

      final dynamic rawEnd = data[FirestoreUserCoinMiningFields.lastMiningEnd];
      DateTime? end;
      if (rawEnd is Timestamp) {
        end = rawEnd.toDate();
      } else if (rawEnd is String) {
        end = DateTime.tryParse(rawEnd);
      }

      if (end != null && end.isAfter(now)) {
        if (earliestEnd == null || end.isBefore(earliestEnd)) {
          earliestEnd = end;
        }
      }
    }

    if (earliestEnd != null) {
      debugPrint('[MiningStateService] Scheduling next wakeup at $earliestEnd');
      await BackgroundService.scheduleManagerWakeup(earliestEnd);
    }
  }

  @override
  // ignore: must_call_super
  void dispose() {
    // Singleton should not be disposed.
    // WidgetsBinding.instance.removeObserver(this);
    // super.dispose();
  }
}
