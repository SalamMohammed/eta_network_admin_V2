import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../shared/firestore_constants.dart';
import 'earnings_engine.dart';
import '../shared/device_id.dart';
import 'subscription_service.dart';
import 'notification_service.dart';

class MiningStateService extends ChangeNotifier with WidgetsBindingObserver {
  static final MiningStateService _instance = MiningStateService._internal();
  factory MiningStateService() => _instance;
  MiningStateService._internal();

  // Mining state
  double _totalPoints = 0.0;
  double _hourlyRate = 0.0;
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
  double _managerBonusPerHour = 0.0;
  double _activeManagerMultiplier = 1.0;
  double _baseRate = 0.2;

  // Simulation state
  double _displayTotal = 0.0;
  double _simBase = 0.0;
  DateTime? _simAnchor;
  Timer? _simTimer;
  String? _deviceId;
  bool _initialized = false;
  DateTime? _lastUiNotify;
  double _lastNotifiedDisplay = -1;
  static const Duration _minUiNotifyInterval = Duration(seconds: 1);
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  Timer? _subExpiryTimer;
  Timer? _refreshDebounce;

  // Getters
  double get totalPoints => _totalPoints;
  double get hourlyRate => _hourlyRate;
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
      await FirebaseFirestore.instance
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
    final coinsRef = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins);
    final snap = await coinsRef.get();
    final batch = FirebaseFirestore.instance.batch();
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
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    _deviceId = await DeviceId.get();
    await SubscriptionService().init();
    await _refresh();
    _startUserDocListener();
    _startSimulationIfNeeded();
    _initialized = true;
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
    await EarningsEngine.syncEarnings();

    // Load App Config
    final general = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.general)
        .get();
    final g = general.data() ?? {};
    final baseRate =
        (g[FirestoreAppConfigFields.baseRate] as num?)?.toDouble() ?? 0.2;
    _baseRate = baseRate;
    _sessionHours =
        ((g[FirestoreAppConfigFields.sessionDurationHours] as num?)
            ?.toDouble() ??
        24.0);

    // Load User Data
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .get();
    final d = snap.data() ?? {};

    _totalPoints =
        (d[FirestoreUserFields.totalPoints] as num?)?.toDouble() ?? 0.0;
    _hourlyRate =
        (d[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;
    _managerBonusPerHour =
        (d[FirestoreUserFields.managerBonusPerHour] as num?)?.toDouble() ?? 0.0;
    _lastStart = d[FirestoreUserFields.lastMiningStart] as Timestamp?;
    _lastEnd = d[FirestoreUserFields.lastMiningEnd] as Timestamp?;
    _streakDays = (d[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;

    final now = DateTime.now();
    _miningActive = _lastEnd != null && now.isBefore(_lastEnd!.toDate());

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
        await FirebaseFirestore.instance
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
        ((d[FirestoreUserFields.managedCoinSelections] as List?)
            ?.cast<String>()) ??
        const [];
    _activeManagerId =
        (d[FirestoreUserFields.activeManagerId] as String?) ?? '';

    if (_activeManagerId != null && _activeManagerId!.isNotEmpty) {
      final mgr = await FirebaseFirestore.instance
          .collection(FirestoreConstants.managers)
          .doc(_activeManagerId)
          .get();
      final m = mgr.data() ?? {};
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
      final mgrActive = (m[FirestoreManagerFields.isActive] as bool?) ?? true;
      await _maybeApplyManagerMultiplier(
        uid: uid,
        baseRate: baseRate,
        managerIsActive: mgrActive,
      );
    } else {
      _managerGlobalEnabled = false;
      _managerEtaAuto = false;
      _managerUserCoinAuto = false;
      _managerMaxCommunity = 0;
      _activeManagerMultiplier = 1.0;
      await _maybeApplyManagerMultiplier(
        uid: uid,
        baseRate: baseRate,
        managerIsActive: false,
      );
    }

    // Auto-start mining if manager enabled
    if (_managerEnabled &&
        _managerGlobalEnabled &&
        _managerEtaAuto &&
        !_miningActive) {
      await startMining();
    }
  }

  Future<void> _maybeApplyManagerMultiplier({
    required String uid,
    required double baseRate,
    required bool managerIsActive,
  }) async {
    final bool shouldApply =
        _managerEnabled &&
        managerIsActive &&
        (_activeManagerId ?? '').isNotEmpty &&
        _activeManagerMultiplier > 0.0 &&
        baseRate > 0;

    final double existingBonus = _managerBonusPerHour;
    final double baseWithoutManager = (_hourlyRate - existingBonus).clamp(
      0.0,
      1e18,
    );
    final double nextBonus = shouldApply
        ? (baseRate * _activeManagerMultiplier)
        : 0.0;
    final double nextHourlyRate = (baseWithoutManager + nextBonus).clamp(
      0.0,
      1e18,
    );

    final bool bonusChanged = (nextBonus - existingBonus).abs() > 1e-9;
    final bool rateChanged = (nextHourlyRate - _hourlyRate).abs() > 1e-9;
    if (!bonusChanged && !rateChanged) return;

    await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .set({
          FirestoreUserFields.hourlyRate: nextHourlyRate,
          FirestoreUserFields.managerBonusPerHour: nextBonus,
          FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    _hourlyRate = nextHourlyRate;
    _managerBonusPerHour = nextBonus;
    _simBase = _displayTotal;
    _simAnchor = DateTime.now();
    _maybeNotify(force: true);
  }

  void _startUserDocListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .snapshots()
        .listen((snap) {
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
    final devId = _deviceId ?? await DeviceId.get();
    try {
      final res = await EarningsEngine.startMining(
        deviceId: devId,
        maxEnd: maxEnd,
      );

      _hourlyRate =
          (res[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          _hourlyRate;
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

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && (_activeManagerId ?? '').isNotEmpty) {
        try {
          final mgr = await FirebaseFirestore.instance
              .collection(FirestoreConstants.managers)
              .doc(_activeManagerId)
              .get();
          final m = mgr.data() ?? {};
          final mgrActive =
              (m[FirestoreManagerFields.isActive] as bool?) ?? true;
          _activeManagerMultiplier =
              (m[FirestoreManagerFields.managerMultiplier] as num?)
                  ?.toDouble() ??
              _activeManagerMultiplier;
          await _maybeApplyManagerMultiplier(
            uid: uid,
            baseRate: _baseRate,
            managerIsActive: mgrActive,
          );
        } catch (_) {}
      }

      _startSimulationIfNeeded();

      // Schedule local notification as backup/primary
      if (_lastEnd != null) {
        unawaited(
          NotificationService().scheduleMiningFinished(_lastEnd!.toDate()),
        );
      }

      _maybeNotify(force: true);
      return res;
    } catch (e) {
      debugPrint('Mining start failed: $e');
      rethrow;
    }
  }

  Future<double> applyRewardedAdHourlyBoost({
    required double baseHourlyRate,
    required double percent,
    required int rewardedWatchIndex,
  }) async {
    if (rewardedWatchIndex < 2) return _hourlyRate;
    if (baseHourlyRate <= 0) return _hourlyRate;
    if (percent <= 0) return _hourlyRate;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _hourlyRate;
    if (!_miningActive || _lastStart == null || _lastEnd == null) {
      return _hourlyRate;
    }

    final syncRes = await EarningsEngine.syncEarnings();
    _totalPoints =
        (syncRes[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
        _totalPoints;
    _displayTotal = _totalPoints;
    _simBase = _totalPoints;
    _simAnchor = DateTime.now();

    final frac = (percent / 100.0).clamp(0.0, 1e6);
    final bonusPerAd = baseHourlyRate * frac;
    final targetHourlyRate =
        baseHourlyRate + (bonusPerAd * (rewardedWatchIndex - 1));
    if (targetHourlyRate <= 0) return _hourlyRate;

    await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .update({
          FirestoreUserFields.hourlyRate: targetHourlyRate,
          FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
        });

    _hourlyRate = targetHourlyRate;
    _maybeNotify(force: true);
    return targetHourlyRate;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _simTimer?.cancel();
      _simTimer = null;
      _userDocSub?.cancel();
      _userDocSub = null;
    } else if (state == AppLifecycleState.resumed) {
      _ensureTimerRunning();
      _startUserDocListener();
      // Also refresh manually to ensure we catch anything the listener might miss during reconnection
      _refresh();
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

    _simTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
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
    _subExpiryTimer?.cancel();
    _subExpiryTimer = null;
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    _totalPoints = 0.0;
    _hourlyRate = 0.0;
    _lastStart = null;
    _lastEnd = null;
    _miningActive = false;
    _streakDays = 0;
    _displayTotal = 0.0;
    _simBase = 0.0;
    _simAnchor = null;
    _initialized = false;
    _managerEnabled = false;
    _managerGlobalEnabled = false;
    _managerEtaAuto = false;
    _managerUserCoinAuto = false;
    _managerMaxCommunity = 0;
    _activeManagerId = null;
    _managedCoinSelections = const [];
    _subscriptionExpiresAt = null;
    _managerBonusPerHour = 0.0;
    _activeManagerMultiplier = 1.0;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _simTimer?.cancel();
    _userDocSub?.cancel();
    _subExpiryTimer?.cancel();
    _refreshDebounce?.cancel();
    super.dispose();
  }
}
