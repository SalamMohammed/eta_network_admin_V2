import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../shared/firestore_constants.dart';
import 'earnings_engine.dart';
import '../shared/device_id.dart';
import 'notification_service.dart';
import 'subscription_service.dart';

class MiningStateService extends ChangeNotifier {
  static final MiningStateService _instance = MiningStateService._internal();
  factory MiningStateService() => _instance;
  MiningStateService._internal();

  // Mining state
  double _totalPoints = 0.0;
  double _hourlyRate = 0.0;
  Timestamp? _lastStart;
  Timestamp? _lastEnd;
  bool _miningActive = false;
  int _sessionHours = 24;
  int _streakDays = 0;

  // Manager state
  bool _managerEnabled = false;
  bool _managerGlobalEnabled = false;
  bool _managerEtaAuto = false;
  bool _managerUserCoinAuto = false;
  int _managerMaxCommunity = 0;
  String? _activeManagerId;
  List<String> _managedCoinSelections = const [];

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
  int get sessionHours => _sessionHours;
  Timestamp? get lastEnd => _lastEnd;
  Timestamp? get lastStart => _lastStart;
  int get streakDays => _streakDays;

  Future<void> init() async {
    if (_initialized) return;
    _deviceId = await DeviceId.get();
    await SubscriptionService().init();
    await _refresh();
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
    _sessionHours =
        ((g[FirestoreAppConfigFields.sessionDurationHours] as num?)?.toInt() ??
        24);

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
    _lastStart = d[FirestoreUserFields.lastMiningStart] as Timestamp?;
    _lastEnd = d[FirestoreUserFields.lastMiningEnd] as Timestamp?;
    _streakDays = (d[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;

    final now = DateTime.now();
    _miningActive = _lastEnd != null && now.isBefore(_lastEnd!.toDate());

    if (_lastEnd != null) {
      final end = _lastEnd!.toDate();
      final ns = NotificationService();
      await ns.cancelAll();
      await ns.scheduleMiningFinished(end);
      await ns.scheduleStreakReminder(end);
    } else {
      final ns = NotificationService();
      await ns.cancelAll();
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

    bool isSubActive = subStatus == 'active';
    if (isSubActive && subExpires != null) {
      if (DateTime.now().isAfter(subExpires.toDate())) {
        isSubActive = false;
      }
    }
    _managerEnabled = isSubActive;

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
    } else {
      _managerGlobalEnabled = false;
      _managerEtaAuto = false;
      _managerUserCoinAuto = false;
      _managerMaxCommunity = 0;
    }

    // Auto-start mining if manager enabled
    if (_managerEnabled &&
        _managerGlobalEnabled &&
        _managerEtaAuto &&
        !_miningActive) {
      await startMining();
    }
  }

  Future<void> startMining() async {
    final devId = _deviceId ?? await DeviceId.get();
    try {
      final res = await EarningsEngine.startMining(deviceId: devId);

      _hourlyRate =
          (res[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
          _hourlyRate;
      _lastStart = res[FirestoreUserFields.lastMiningStart] as Timestamp?;
      _lastEnd = res[FirestoreUserFields.lastMiningEnd] as Timestamp?;
      _streakDays =
          (res[FirestoreUserFields.streakDays] as num?)?.toInt() ?? _streakDays;

      final now = DateTime.now();
      _miningActive = _lastEnd != null && now.isBefore(_lastEnd!.toDate());

      // Schedule notifications
      if (_lastEnd != null) {
        final end = _lastEnd!.toDate();
        final ns = NotificationService();
        // We assume NotificationService is initialized in main.dart
        ns.cancelAll().then((_) {
          ns.scheduleMiningFinished(end);
          ns.scheduleStreakReminder(end);
        });
      }

      // Reset simulation base to current total when starting new session
      _totalPoints =
          (res[FirestoreUserFields.totalPoints] as num?)?.toDouble() ??
          _totalPoints;
      _displayTotal = _totalPoints;

      _startSimulationIfNeeded();
      _maybeNotify(force: true);
    } catch (e) {
      debugPrint('Mining start failed: $e');
      rethrow;
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
    final end = _lastEnd!.toDate();

    _simTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      final anchor = _simAnchor!;
      final now = DateTime.now();

      if (!now.isBefore(end)) {
        _simTimer?.cancel();
        _simTimer = null;
        _miningActive = false;
        _displayTotal = _simBase; // Revert to base or fetch new?
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
    _simTimer?.cancel();
    _simTimer = null;
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
    notifyListeners();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }
}
