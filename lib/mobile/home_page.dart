import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/firestore_constants.dart';
import '../shared/device_id.dart';
import 'balance/my_coin_block.dart';
import '../services/coin_service.dart';
// import '../services/sql_api_service.dart';
import '../services/mining_state_service.dart';
import '../services/subscription_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_verification_service.dart';
import 'widgets/coin_details_dialog.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _miningService = MiningStateService();
  final _adsService = AdsService();
  late final TabController _tab = TabController(length: 2, vsync: this);
  String _minedSort = 'popular';
  String _liveSort = 'popular';
  DateTime? _lastUiUpdate;
  Timer? _debounceTimer;
  Timer? _adCooldownTimer;
  int _adCooldownSeconds = 0;
  static const int _adCooldownDuration = 20;

  // Use nullable to safely handle Hot Reload initialization
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  bool _rewardedLoading = false;
  Stream<Map<String, dynamic>?> _userCoinStream = const Stream.empty();
  Stream<List<Map<String, dynamic>>> _minedCoinsStream = const Stream.empty();
  Stream<List<Map<String, dynamic>>> _liveCoinsStream = const Stream.empty();
  StreamSubscription<List<Map<String, dynamic>>>? _managerCoinsSub;
  List<Map<String, dynamic>> _managerCachedCoins = [];
  static const String _prefsRewardedSessionStartMsKey =
      'ads_rewarded_session_start_ms';
  static const String _prefsRewardedSessionCountKey =
      'ads_rewarded_session_count';
  static const String _prefsRewardedSessionBaseHourlyRateKey =
      'ads_rewarded_session_base_hourly_rate';
  int _rewardedSessionStartMs = 0;
  int _rewardedWatchedThisSession = 0;
  double _rewardedSessionBaseHourlyRate = 0.0;
  bool _startMiningInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _miningService.addListener(_handleServiceUpdate);
    _adsService.addListener(_handleAdsUpdate);
    _tab.addListener(() {
      if (!mounted) return;
      if (_tab.indexIsChanging) return;

      // Refresh streams when switching tabs to show cached data instantly
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        if (_tab.index == 0) {
          _minedCoinsStream = CoinService.watchMyCoins(uid);
        } else if (_tab.index == 1) {
          _liveCoinsStream = CoinService.watchLiveCoins(sort: _liveSort);
        }
      }

      setState(() {});
    });
    unawaited(_adsService.init());
    unawaited(_loadRewardedSessionLimiter());

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userCoinStream = CoinService.watchUserCoin(uid);

      // Share the stream to avoid double polling
      final myCoinsStream = CoinService.watchMyCoins(uid);
      _minedCoinsStream = myCoinsStream;

      // Cache coins for Manager (Zero-Read Polling)
      _managerCoinsSub = myCoinsStream.listen((coins) {
        if (mounted) {
          _managerCachedCoins = coins;
          // Trigger check immediately when data updates
          unawaited(_manageCommunityCoins());
        }
      });
    }

    // Ensure notifications are permitted and token is synced
    unawaited(NotificationService().requestPermissions());

    // Check for Play Store updates (Android Force Update)
    unawaited(UpdateService.checkForUpdate());

    // MiningService is auto-initialized by Auth listener
    if (mounted) _manageCommunityCoins();
    unawaited(_syncRewardedSessionWithMiningState());
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safety check for Hot Reload: if fields are null, init them now
    if (_pulseController == null) {
      _initPulseAnimation();
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _adCooldownTimer?.cancel();
    _miningService.removeListener(_handleServiceUpdate);
    _adsService.removeListener(_handleAdsUpdate);
    _managerCoinsSub?.cancel();
    _tab.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(UpdateService.checkForUpdate());
      _manageCommunityCoins();
    }
  }

  void _handleAdsUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadRewardedSessionLimiter() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getInt(_prefsRewardedSessionStartMsKey) ?? 0;
    final count = prefs.getInt(_prefsRewardedSessionCountKey) ?? 0;
    final base = prefs.getDouble(_prefsRewardedSessionBaseHourlyRateKey) ?? 0.0;
    if (!mounted) return;
    setState(() {
      _rewardedSessionStartMs = start;
      _rewardedWatchedThisSession = count;
      _rewardedSessionBaseHourlyRate = base;
    });
  }

  Future<void> _persistRewardedSessionLimiter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefsRewardedSessionStartMsKey,
      _rewardedSessionStartMs,
    );
    await prefs.setInt(
      _prefsRewardedSessionCountKey,
      _rewardedWatchedThisSession,
    );
    await prefs.setDouble(
      _prefsRewardedSessionBaseHourlyRateKey,
      _rewardedSessionBaseHourlyRate,
    );
  }

  Future<void> _syncRewardedSessionWithMiningState() async {
    final miningActive = _miningService.miningActive;
    final sessionStartMs = miningActive
        ? (_miningService.lastStart?.millisecondsSinceEpoch ?? 0)
        : 0;

    if (!miningActive || sessionStartMs <= 0) {
      if (_rewardedSessionStartMs != 0 || _rewardedWatchedThisSession != 0) {
        if (!mounted) return;
        setState(() {
          _rewardedSessionStartMs = 0;
          _rewardedWatchedThisSession = 0;
          _rewardedSessionBaseHourlyRate = 0.0;
        });
        await _persistRewardedSessionLimiter();
      }
      return;
    }

    if (_rewardedSessionStartMs != sessionStartMs) {
      if (!mounted) return;
      setState(() {
        _rewardedSessionStartMs = sessionStartMs;
        _rewardedWatchedThisSession = 0;
        // Use rateBase (admin configured base rate) instead of hourlyRate (which includes boosts)
        _rewardedSessionBaseHourlyRate = _miningService.rateBase;
      });
      await _persistRewardedSessionLimiter();
      return;
    }

    if (_rewardedSessionBaseHourlyRate <= 0) {
      if (!mounted) return;
      setState(() => _rewardedSessionBaseHourlyRate = _miningService.rateBase);
      await _persistRewardedSessionLimiter();
    }
  }

  bool get _rewardedLimitReached {
    final max = _adsService.config.maxRewardedPerMiningSession;
    if (max <= 0) return true;
    return _rewardedWatchedThisSession >= max;
  }

  Future<bool> _tryShowRewardedAd({required bool silentUnavailable}) async {
    await _syncRewardedSessionWithMiningState();
    await _adsService.init();
    if (!_adsService.isSupportedPlatform) return false;
    if (!_adsService.config.enableRewarded) return false;
    if (!_miningService.miningActive) return false;
    if (_rewardedLimitReached) return false;
    if (_rewardedLoading) return false;

    if (mounted) setState(() => _rewardedLoading = true);
    final ad = await _adsService.loadRewardedAd();
    if (!mounted) return false;
    setState(() => _rewardedLoading = false);

    if (ad == null) {
      if (!silentUnavailable) {
        // final errorMsg = _adsService.lastLoadError ?? 'Rewarded ad not available';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rewarded ad not available')),
        );
      }
      return false;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        if (!mounted) return;
        unawaited(() async {
          try {
            await _syncRewardedSessionWithMiningState();
            if (!mounted) return;
            final next = _rewardedWatchedThisSession + 1;
            setState(() => _rewardedWatchedThisSession = next);
            await _persistRewardedSessionLimiter();
            _startAdCooldown();

            // Fixed: Claim reward for every ad watched (previously required 2+)
            // The engine now handles the bonus calculation internally based on stored config.
            final boostAmount = await _miningService.boostAdRateNew();
            if (!mounted) return;
            if (boostAmount > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Rate boosted: +${boostAmount.toStringAsFixed(4)} ETA/hr',
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint('Rewarded bonus apply failed: $e');
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Ad bonus failed: $e')));
          }
        }());
        // Hide generic AdMob reward message to avoid confusion
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Reward: ${reward.amount} ${reward.type}')),
        // );
      },
    );
    return true;
  }

  Future<void> _maybeAutoShowRewardedOnMiningStart() async {
    await _tryShowRewardedAd(silentUnavailable: true);
  }

  void _startAdCooldown() {
    if (!mounted) return;
    setState(() => _adCooldownSeconds = _adCooldownDuration);
    _adCooldownTimer?.cancel();
    _adCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_adCooldownSeconds > 0) {
          _adCooldownSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _handleServiceUpdate() {
    if (!mounted) return;
    unawaited(_syncRewardedSessionWithMiningState());
    final now = DateTime.now();
    final last = _lastUiUpdate;
    if (last == null || now.difference(last) >= const Duration(seconds: 1)) {
      _lastUiUpdate = now;
      setState(() {});
      // Only check community coins every 10 minutes to save reads
      if (_lastCommunityCoinCheck == null ||
          now.difference(_lastCommunityCoinCheck!) >=
              const Duration(minutes: 10)) {
        _lastCommunityCoinCheck = now;
        unawaited(_manageCommunityCoins());
      }
      return;
    }
    _debounceTimer ??= Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _lastUiUpdate = DateTime.now();
      _debounceTimer = null;
      setState(() {});
      if (_lastCommunityCoinCheck == null ||
          DateTime.now().difference(_lastCommunityCoinCheck!) >=
              const Duration(minutes: 10)) {
        _lastCommunityCoinCheck = DateTime.now();
        unawaited(_manageCommunityCoins());
      }
    });
  }

  DateTime? _lastCommunityCoinCheck;

  Future<void> _refresh() async {
    await _miningService.refresh();
    if (mounted) {
      _lastCommunityCoinCheck = DateTime.now();
      await _manageCommunityCoins();
    }
  }

  Future<void> _manageCommunityCoins() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!_miningService.managerEnabled) return;

    final devId = await DeviceId.get();

    // Ensure own coin is mining when enabled
    if (_miningService.managerUserCoinAuto) {
      final ownData = _managerCachedCoins.firstWhere(
        (c) => c[FirestoreUserCoinMiningFields.ownerId] == uid,
        orElse: () => {},
      );

      final dynamic rawEnd =
          ownData[FirestoreUserCoinMiningFields.lastMiningEnd];
      DateTime? ownEnd;
      if (rawEnd is Timestamp) {
        ownEnd = rawEnd.toDate();
      } else if (rawEnd is String) {
        ownEnd = DateTime.tryParse(rawEnd);
      }

      final ownActive = ownEnd != null && DateTime.now().isBefore(ownEnd);
      if (!ownActive && ownData.isNotEmpty) {
        try {
          await CoinService.startCoinMining(
            uid,
            deviceId: devId,
            cachedCoinData: ownData,
          );
        } catch (e) {
          debugPrint('Manager own coin start failed: $e');
        }
      }
    }

    // Manage community coins when enabled and allowed
    if (!(_miningService.managerUserCoinAuto &&
        _miningService.managerGlobalEnabled &&
        _miningService.managerMaxCommunity > 0)) {
      return;
    }

    final coins = _managerCachedCoins;
    final now = DateTime.now();
    int activeManaged = 0;

    // First pass: count active
    for (final data in coins) {
      final ownerId =
          (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
      if (ownerId == uid) continue;

      if (_miningService.managedCoinSelections.isNotEmpty &&
          !_miningService.managedCoinSelections.contains(ownerId)) {
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

    // Second pass: start mining
    for (final data in coins) {
      final ownerId =
          (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
      if (ownerId == uid) continue;

      if (_miningService.managedCoinSelections.isNotEmpty &&
          !_miningService.managedCoinSelections.contains(ownerId)) {
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
      if (!isActive && activeManaged < _miningService.managerMaxCommunity) {
        try {
          await CoinService.startCoinMining(
            ownerId,
            deviceId: devId,
            cachedCoinData: data,
          );
          activeManaged++;
        } catch (e) {
          debugPrint('Manager community coin start failed: $e');
        }
      }
    }
  }

  double _computeProgress() {
    if (_miningService.lastEnd == null) {
      return 0.0;
    }
    final end = _miningService.lastEnd!.toDate();
    final now = DateTime.now();
    final totalSec = (_miningService.sessionHours * 3600).toDouble();
    final remainingSec = end.difference(now).inSeconds.toDouble();
    final doneSec = (totalSec - remainingSec).clamp(0.0, totalSec);
    final p = totalSec > 0 ? (doneSec / totalSec) : 0.0;
    return p.clamp(0.0, 1.0);
  }

  String _formatHms(Duration d) {
    var sec = d.inSeconds;
    if (sec < 0) sec = 0;
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _miningSummaryCard({
    required double totalEta,
    required double hourlyRate,
    required bool miningActive,
    required int streakDays,
    required double progress,
    required Duration remaining,
    required VoidCallback onStart,
    required bool showRewarded,
    required bool rewardedLoading,
    required bool rewardedLimitReached,
    required int rewardedWatchedThisSession,
    required int rewardedMaxPerSession,
    required double rewardedBonusPercent,
    required int adCooldownSeconds,
    required VoidCallback onShowRewarded,
  }) {
    const cardBg = Color(0xFF1B2632);
    const cardBg2 = Color(0xFF141E28);
    const timeBlue = Color(0xFF2D8CFF);
    const buttonBlue = Color(0xFF1677FF);
    const pillBorder = Color(0xFF3C4A57);
    const pillText = Color(0xFFE6EDF5);
    const streakOrange = Color(0xFFFF8A00);

    final streakText = streakDays == 1
        ? '1 Day Streak'
        : '$streakDays Day Streak';

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 380).clamp(0.72, 1.0);
        double s(double v) => v * scale;

        final rewardedLabel = rewardedLoading
            ? 'Loading ad…'
            : adCooldownSeconds > 0
            ? 'Wait ${adCooldownSeconds}s'
            : rewardedMaxPerSession > 0
            ? 'Reward +${rewardedBonusPercent.toStringAsFixed(0)}%'
            : 'Reward +${rewardedBonusPercent.toStringAsFixed(0)}%';

        final canWatch =
            !rewardedLoading && !rewardedLimitReached && adCooldownSeconds <= 0;

        return Container(
          padding: EdgeInsets.all(s(14)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(s(26)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardBg, cardBg2],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: s(12),
                        vertical: s(7),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: pillBorder),
                        color: Colors.white.withValues(alpha: 0.02),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: streakOrange,
                            size: s(20),
                          ),
                          SizedBox(width: s(8)),
                          Text(
                            streakText,
                            style: TextStyle(
                              color: pillText,
                              fontWeight: FontWeight.w600,
                              fontSize: s(14.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: s(12)),
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      child: SizedBox(
                        height: s(56),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Builder(
                                builder: (context) {
                                  final text = totalEta.toStringAsFixed(3);
                                  double size = 50.0;
                                  if (text.length > 9) {
                                    size = 50.0 * (9.0 / text.length);
                                    if (size < 20.0) size = 20.0;
                                  }
                                  return Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: s(size),
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  );
                                }
                              ),
                              SizedBox(width: s(10)),
                              Padding(
                                padding: EdgeInsets.only(bottom: s(8)),
                                child: Text(
                                  'ETA',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: s(20),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: s(8)),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: s(10),
                            height: s(10),
                            decoration: BoxDecoration(
                              color: miningActive
                                  ? const Color(0xFF2ECC71)
                                  : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: s(10)),
                          Text(
                            '+${hourlyRate.toStringAsFixed(2)} ETA/hr',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: s(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: s(10)),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: s(17),
                            ),
                          ),
                          SizedBox(width: s(10)),
                          Text(
                            miningActive ? 'Mining Active' : 'Inactive',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: s(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: s(12)),
                  Row(
                    children: [
                      Text(
                        'Session ends in',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: s(14),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatHms(remaining),
                        style: TextStyle(
                          color: timeBlue,
                          fontSize: s(18),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(10)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: s(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          timeBlue,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: s(12)),
                  SizedBox(
                    height: s(56),
                    child: ElevatedButton.icon(
                      onPressed: miningActive ? null : onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBlue,
                        disabledBackgroundColor: buttonBlue.withValues(
                          alpha: 0.35,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(s(20)),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: s(24),
                      ),
                      label: Text(
                        'Start Earning',
                        style: TextStyle(
                          fontSize: s(19),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (showRewarded && miningActive) ...[
                    SizedBox(height: s(8)),
                    Center(
                      child: ScaleTransition(
                        scale: (canWatch && _pulseAnimation != null)
                            ? _pulseAnimation!
                            : const AlwaysStoppedAnimation(1.0),
                        child: InkWell(
                          onTap: canWatch ? onShowRewarded : null,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: s(16),
                              vertical: s(10),
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              // Golden Gradient for active state
                              gradient: canWatch
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700), // Gold
                                        Color(0xFFFFA000), // Amber
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: canWatch
                                  ? null
                                  : Colors.white.withValues(alpha: 0.04),
                              border: Border.all(
                                color: canWatch
                                    ? const Color(0xFFFFECB3)
                                    : Colors.white24,
                                width: canWatch ? 1.5 : 1.0,
                              ),
                              boxShadow: canWatch
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFD700,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  adCooldownSeconds > 0
                                      ? Icons.timer_outlined
                                      : Icons.ondemand_video_rounded,
                                  size: s(18),
                                  color: canWatch
                                      ? const Color(0xFF3E2723)
                                      : Colors.white70,
                                ),
                                SizedBox(width: s(8)),
                                Text(
                                  rewardedLabel,
                                  style: TextStyle(
                                    fontSize: s(14),
                                    color: canWatch
                                        ? const Color(0xFF3E2723)
                                        : Colors.white70,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Positioned(
                top: s(4),
                left: s(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openManagerSelector,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: s(30),
                          height: s(30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFD67A), Color(0xFFFF9E2D)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFB34D,
                                ).withValues(alpha: 0.55),
                                blurRadius: s(16),
                                spreadRadius: s(2),
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              size: s(18),
                              color: const Color(0xFF121820),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: s(8)),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openCoinSelector,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: s(28),
                          height: s(28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: s(12),
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.monetization_on_rounded,
                              size: s(17),
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _coinTabs() {
    const bg = Color(0xFF202A34);
    const active = Color(0xFF2A3642);
    const inactiveText = Colors.white54;
    const activeText = Colors.white;

    final selected = _tab.index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _tab.animateTo(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == 0 ? active : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Mined Coins',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected == 0 ? activeText : inactiveText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _tab.animateTo(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == 1 ? active : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Live Coins',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected == 1 ? activeText : inactiveText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = (size.width * 0.04).clamp(12.0, 16.0);
    final vPad = (size.width * 0.03).clamp(8.0, 12.0);
    final progress = _computeProgress();
    final miningActive = _miningService.miningActive;
    final hourlyRate = _miningService.hourlyRate;
    final displayTotal = _miningService.displayTotal;
    final streakDays = _miningService.streakDays;

    Duration remaining = Duration.zero;
    if (miningActive && _miningService.lastEnd != null) {
      final end = _miningService.lastEnd!.toDate();
      final now = DateTime.now();
      remaining = end.difference(now);
      if (remaining.isNegative) remaining = Duration.zero;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('ETA Network'),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: vPad),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
              child: _miningSummaryCard(
                totalEta: displayTotal,
                hourlyRate: hourlyRate,
                miningActive: miningActive,
                streakDays: streakDays,
                progress: progress,
                remaining: remaining,
                onStart: () async {
                  if (_startMiningInProgress) return;
                  _startMiningInProgress = true;
                  try {
                    final res = await _miningService.startMining();
                    if (!context.mounted) return;
                    final dbg = res['debug'] as Map<String, dynamic>?;
                    if (dbg != null) {
                      final base = (dbg['baseRate'] as num?)?.toDouble() ?? 0.0;
                      final streak =
                          (dbg['streakBonus'] as num?)?.toDouble() ?? 0.0;
                      final rank =
                          (dbg['rankBonus'] as num?)?.toDouble() ?? 0.0;
                      final ref =
                          (dbg['referralBonus'] as num?)?.toDouble() ?? 0.0;
                      final total =
                          (dbg['hourlyRate'] as num?)?.toDouble() ?? 0.0;
                      final msg =
                          'Rate breakdown: Base ${base.toStringAsFixed(2)}, Streak +${streak.toStringAsFixed(2)}, Rank +${rank.toStringAsFixed(2)}, Referrals +${ref.toStringAsFixed(2)} = ${total.toStringAsFixed(2)} ETA/hr';
                      debugPrint(msg);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(msg)));
                    }
                    await _syncRewardedSessionWithMiningState();
                    await _maybeAutoShowRewardedOnMiningStart();
                  } catch (e) {
                    if (!context.mounted) return;
                    debugPrint('Start failed: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to start mining. Please check your internet connection and try again.',
                        ),
                      ),
                    );
                  } finally {
                    _startMiningInProgress = false;
                  }
                },
                showRewarded: _adsService.config.enableRewarded,
                rewardedLoading: _rewardedLoading,
                rewardedLimitReached: _rewardedLimitReached,
                rewardedWatchedThisSession: _rewardedWatchedThisSession,
                rewardedMaxPerSession:
                    _adsService.config.maxRewardedPerMiningSession,
                rewardedBonusPercent: _adsService.config.rewardBonusPercent,
                adCooldownSeconds: _adCooldownSeconds,
                onShowRewarded: () {
                  unawaited(_tryShowRewardedAd(silentUnavailable: false));
                },
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _myCreatedCoinCard(),
            ),
            const SizedBox(height: 10),
            _coinTabs(),
            const SizedBox(height: 6),
            if (_tab.index == 0) _minedCoinsTab() else _liveCoinsTab(),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _myCreatedCoinCard() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _userCoinStream,
      builder: (context, snap) {
        final d = snap.data;
        final active =
            d != null && (d[FirestoreUserCoinFields.isActive] == true);
        if (!active) {
          return const MyCoinBlock(variant: MyCoinBlockVariant.home);
        }
        return _createdCoinCardAsMined(d);
      },
    );
  }

  Widget _createdCoinCardAsMined(Map<String, dynamic> data) {
    final ownerId = (data[FirestoreUserCoinFields.ownerId] as String?) ?? '';
    final name = (data[FirestoreUserCoinFields.name] as String?) ?? '—';
    final symbol = (data[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final imageUrl = (data[FirestoreUserCoinFields.imageUrl] as String?) ?? '';
    final rate =
        _safeDoubleNullable(data[FirestoreUserCoinFields.baseRatePerHour]) ??
        0.0;

    const card = Color(0xFF17222C);
    const border = Color(0xFF24303B);
    return GestureDetector(
      onTap: () => showCoinDetailsDialog(context, data),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white10,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        symbol.isNotEmpty ? symbol : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${rate.toStringAsFixed(3)}/h',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CoinMiningControls(
              coinOwnerId: ownerId,
              baseRate: rate,
              symbol: symbol,
              // miningData: data, // Removed to force fetching from users/{uid}/coins/{id}
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openManagerSelector() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return _ManagerSelectDialog(
          currentId: _miningService.activeManagerId,
          onSelected: (id) async {
            await FirestoreHelper.instance
                .collection(FirestoreConstants.users)
                .doc(uid)
                .set({
                  FirestoreUserFields.activeManagerId: id,
                  FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
            if (id != null) {
              final mgr = await FirestoreHelper.instance
                  .collection(FirestoreConstants.managers)
                  .doc(id)
                  .get();
              final m = mgr.data() ?? {};
              final max =
                  (m[FirestoreManagerFields.maxCommunityCoinsManaged] as num?)
                      ?.toInt() ??
                  0;
              final sel = _miningService.managedCoinSelections;
              if (max >= 0 && sel.length > max) {
                final trimmed = sel.take(max).toList();
                await FirestoreHelper.instance
                    .collection(FirestoreConstants.users)
                    .doc(uid)
                    .set({
                      FirestoreUserFields.managedCoinSelections: trimmed,
                    }, SetOptions(merge: true));
              }
            }
            await _refresh();
          },
        );
      },
    );
  }

  Future<void> _openCoinSelector() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return _CoinSelectDialog(
          current: _miningService.managedCoinSelections,
          maxCount: _miningService.managerMaxCommunity,
          onSelected: (ids) async {
            await FirestoreHelper.instance
                .collection(FirestoreConstants.users)
                .doc(uid)
                .set({
                  FirestoreUserFields.managedCoinSelections: ids,
                }, SetOptions(merge: true));
            await _refresh();
          },
        );
      },
    );
  }

  // _updateRemaining is removed as it is now inline in build

  Widget _minedCoinsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ASSET',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Text(
                'STATUS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => _minedSort = v),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'popular', child: Text('Popular')),
                  const PopupMenuItem(
                    value: 'name_az',
                    child: Text('Names A–Z'),
                  ),
                  const PopupMenuItem(
                    value: 'name_za',
                    child: Text('Names Z–A'),
                  ),
                  const PopupMenuItem(
                    value: 'old_new',
                    child: Text('Old → New'),
                  ),
                  const PopupMenuItem(
                    value: 'new_old',
                    child: Text('New → Old'),
                  ),
                ],
                child: const Icon(Icons.tune_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _minedCoinsStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              var coins = snap.data ?? [];
              final uid = FirebaseAuth.instance.currentUser?.uid;

              // Filter out own coins (already shown in home/balance)
              if (uid != null) {
                coins = coins
                    .where(
                      (c) =>
                          (c[FirestoreUserCoinMiningFields.ownerId]
                              as String?) !=
                          uid,
                    )
                    .toList();
              }

              if (coins.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('No coins yet. Add from Live Coins.'),
                  ),
                );
              }

              coins = _normalizeCoins(coins);

              final sorted = _sortMinedList(coins);

              return Column(
                children: [for (final c in sorted) _minedCoinCard(c)],
              );
            },
          ),
        ],
      ),
    );
  }

  double? _safeDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Widget _liveCoinsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ASSET',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Text(
                'RATE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() {
                  _liveSort = v;
                  _liveCoinsStream = CoinService.watchLiveCoins(sort: v);
                }),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'popular', child: Text('Popular')),
                  const PopupMenuItem(
                    value: 'name_az',
                    child: Text('Names A–Z'),
                  ),
                  const PopupMenuItem(
                    value: 'name_za',
                    child: Text('Names Z–A'),
                  ),
                  const PopupMenuItem(value: 'random', child: Text('Random')),
                  const PopupMenuItem(
                    value: 'old_new',
                    child: Text('Old → New'),
                  ),
                  const PopupMenuItem(
                    value: 'new_old',
                    child: Text('New → Old'),
                  ),
                ],
                child: const Icon(Icons.tune_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _liveCoinsStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              var coins = snap.data ?? [];
              final uid = FirebaseAuth.instance.currentUser?.uid;
              // Filter out own coins (already shown in home/balance)
              if (uid != null) {
                coins = coins
                    .where(
                      (c) =>
                          (c[FirestoreUserCoinFields.ownerId] as String?) !=
                          uid,
                    )
                    .toList();
              }

              coins = _normalizeCoins(coins);
              if (!CoinService.useSqlBackend) {
                coins = _sortLiveList(coins);
              }

              if (coins.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No live community coins')),
                );
              }
              return Column(
                children: [for (final coin in coins) _liveCoinCard(coin)],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _sortMinedList(List<Map<String, dynamic>> list) {
    final l = [...list];
    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    switch (_minedSort) {
      case 'name_az':
        l.sort(
          (a, b) =>
              cmp((a['name'] as String?) ?? '', (b['name'] as String?) ?? ''),
        );
        break;
      case 'name_za':
        l.sort(
          (a, b) =>
              cmp((b['name'] as String?) ?? '', (a['name'] as String?) ?? ''),
        );
        break;
      case 'old_new':
        l.sort((a, b) {
          final ta =
              (a['lastMiningStart'] as Timestamp?) ??
              (a['lastSyncedAt'] as Timestamp?);
          final tb =
              (b['lastMiningStart'] as Timestamp?) ??
              (b['lastSyncedAt'] as Timestamp?);
          return (ta?.millisecondsSinceEpoch ?? 0).compareTo(
            tb?.millisecondsSinceEpoch ?? 0,
          );
        });
        break;
      case 'new_old':
        l.sort((a, b) {
          final ta =
              (a['lastMiningStart'] as Timestamp?) ??
              (a['lastSyncedAt'] as Timestamp?);
          final tb =
              (b['lastMiningStart'] as Timestamp?) ??
              (b['lastSyncedAt'] as Timestamp?);
          return (tb?.millisecondsSinceEpoch ?? 0).compareTo(
            ta?.millisecondsSinceEpoch ?? 0,
          );
        });
        break;
      case 'random':
        l.shuffle();
        break;
      case 'popular':
      default:
        l.sort((a, b) {
          final pa = (a['totalPoints'] as num?)?.toDouble() ?? 0.0;
          final pb = (b['totalPoints'] as num?)?.toDouble() ?? 0.0;
          return pb.compareTo(pa);
        });
    }
    return l;
  }

  // Helper for normalization if needed in future
  List<Map<String, dynamic>> _normalizeCoins(List<Map<String, dynamic>> coins) {
    return coins;
  }

  List<Map<String, dynamic>> _sortLiveList(List<Map<String, dynamic>> list) {
    final l = [...list];
    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    switch (_liveSort) {
      case 'name_az':
        l.sort(
          (a, b) => cmp(
            (a[FirestoreUserCoinFields.name] as String?) ?? '',
            (b[FirestoreUserCoinFields.name] as String?) ?? '',
          ),
        );
        break;
      case 'name_za':
        l.sort(
          (a, b) => cmp(
            (b[FirestoreUserCoinFields.name] as String?) ?? '',
            (a[FirestoreUserCoinFields.name] as String?) ?? '',
          ),
        );
        break;
      case 'old_new':
        l.sort((a, b) {
          final ta =
              (a[FirestoreUserCoinFields.createdAt] as Timestamp?) ??
              (a[FirestoreUserCoinFields.updatedAt] as Timestamp?);
          final tb =
              (b[FirestoreUserCoinFields.createdAt] as Timestamp?) ??
              (b[FirestoreUserCoinFields.updatedAt] as Timestamp?);
          final va = ta?.millisecondsSinceEpoch ?? 0;
          final vb = tb?.millisecondsSinceEpoch ?? 0;
          return va.compareTo(vb);
        });
        break;
      case 'new_old':
        l.sort((a, b) {
          final ta =
              (a[FirestoreUserCoinFields.createdAt] as Timestamp?) ??
              (a[FirestoreUserCoinFields.updatedAt] as Timestamp?);
          final tb =
              (b[FirestoreUserCoinFields.createdAt] as Timestamp?) ??
              (b[FirestoreUserCoinFields.updatedAt] as Timestamp?);
          final va = ta?.millisecondsSinceEpoch ?? 0;
          final vb = tb?.millisecondsSinceEpoch ?? 0;
          return vb.compareTo(va);
        });
        break;
      case 'popular':
      default:
        l.sort((a, b) {
          final ma =
              (a[FirestoreUserCoinFields.minersCount] as num?)?.toInt() ?? 0;
          final mb =
              (b[FirestoreUserCoinFields.minersCount] as num?)?.toInt() ?? 0;
          if (mb != ma) return mb.compareTo(ma);
          final la =
              ((a[FirestoreUserCoinFields.socialLinks] as List?) ?? []).length;
          final lb =
              ((b[FirestoreUserCoinFields.socialLinks] as List?) ?? []).length;
          if (lb != la) return lb.compareTo(la);
          final ra =
              (a[FirestoreUserCoinFields.baseRatePerHour] as num?)
                  ?.toDouble() ??
              0.0;
          final rb =
              (b[FirestoreUserCoinFields.baseRatePerHour] as num?)
                  ?.toDouble() ??
              0.0;
          return rb.compareTo(ra);
        });
    }
    return l;
  }

  Widget _liveCoinCard(Map<String, dynamic> data) {
    final ownerId = (data[FirestoreUserCoinFields.ownerId] as String?) ?? '';
    final name = (data[FirestoreUserCoinFields.name] as String?) ?? '—';
    final symbol = (data[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final imageUrl = (data[FirestoreUserCoinFields.imageUrl] as String?) ?? '';
    final rate =
        _safeDoubleNullable(data[FirestoreUserCoinFields.baseRatePerHour]) ??
        0.0;
    const card = Color(0xFF17222C);
    const border = Color(0xFF24303B);
    return GestureDetector(
      onTap: () => showCoinDetailsDialog(context, data),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white10,
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    symbol.isNotEmpty ? symbol : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${rate.toStringAsFixed(3)}/h',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: ownerId.isEmpty
                      ? null
                      : () async {
                          try {
                            await CoinService.addCoinForUser(
                              ownerId,
                              coinData: data,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to Mined Coins'),
                                ),
                              );
                              setState(() {});
                              _refresh();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add: $e')),
                              );
                            }
                          }
                        },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.white24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _minedCoinCard(Map<String, dynamic> data) {
    const cardBg = Color(0xFF0F1A24);
    const cardBg2 = Color(0xFF0B121A);
    const border = Color(0xFF24303B);

    final ownerId =
        (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
    final name = (data[FirestoreUserCoinMiningFields.name] as String?) ?? '—';
    final symbol =
        (data[FirestoreUserCoinMiningFields.symbol] as String?) ?? '';
    final imageUrl =
        (data[FirestoreUserCoinMiningFields.imageUrl] as String?) ?? '';
    final rate =
        _safeDoubleNullable(data[FirestoreUserCoinMiningFields.hourlyRate]) ??
        0.0;

    final links = (data['socialLinks'] as List<dynamic>?) ?? const [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 380).clamp(0.78, 1.0);
        double s(double v) => v * scale;

        Future<void> openLink(String url) async {
          if (url.isEmpty) return;
          final uri = Uri.tryParse(url);
          if (uri == null) return;
          try {
            final ok = await canLaunchUrl(uri);
            if (!ok) return;
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {}
        }

        String firstLinkUrl(String type) {
          for (final l in links) {
            final t = (l['type'] as String?) ?? '';
            final u = (l['url'] as String?) ?? '';
            if (t.toLowerCase() == type.toLowerCase() && u.isNotEmpty) {
              return u;
            }
          }
          return '';
        }

        final websiteUrl = firstLinkUrl('website');
        final telegramUrl = firstLinkUrl('telegram');
        final twitterUrl = firstLinkUrl('twitter');
        final instagramUrl = firstLinkUrl('instagram');
        final youtubeUrl = firstLinkUrl('youtube');
        final facebookUrl = firstLinkUrl('facebook');

        Widget iconPill({
          required IconData icon,
          required VoidCallback? onPressed,
        }) {
          return Container(
            width: s(30),
            height: s(30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(s(10)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              icon: Icon(icon, size: s(16), color: Colors.white70),
            ),
          );
        }

        final iconWidgets = <Widget>[];
        if (websiteUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.language_rounded,
              onPressed: () => openLink(websiteUrl),
            ),
          );
        }
        if (telegramUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.send_rounded,
              onPressed: () => openLink(telegramUrl),
            ),
          );
        }
        if (twitterUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.close_rounded,
              onPressed: () => openLink(twitterUrl),
            ),
          );
        }
        if (instagramUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.camera_alt_rounded,
              onPressed: () => openLink(instagramUrl),
            ),
          );
        }
        if (youtubeUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.play_circle_fill_rounded,
              onPressed: () => openLink(youtubeUrl),
            ),
          );
        }
        if (facebookUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.facebook_rounded,
              onPressed: () => openLink(facebookUrl),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(s(22)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showCoinDetailsDialog(context, data),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cardBg, cardBg2],
                  ),
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(s(22)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(s(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: s(66),
                            height: s(66),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(s(18)),
                              color: Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                              image: imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl.isEmpty
                                ? Icon(
                                    Icons.token_rounded,
                                    color: Colors.white54,
                                    size: s(28),
                                  )
                                : null,
                          ),
                          SizedBox(width: s(14)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: s(20),
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: s(8)),
                                Row(
                                  children: [
                                    if (symbol.trim().isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: s(10),
                                          vertical: s(6),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            s(10),
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          symbol.trim(),
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w900,
                                            fontSize: s(12),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    if (iconWidgets.isNotEmpty &&
                                        symbol.trim().isNotEmpty) ...[
                                      SizedBox(width: s(12)),
                                      Container(
                                        width: 1,
                                        height: s(18),
                                        color: Colors.white24,
                                      ),
                                      SizedBox(width: s(12)),
                                    ],
                                    if (iconWidgets.isNotEmpty)
                                      Wrap(
                                        spacing: s(10),
                                        runSpacing: s(10),
                                        children: iconWidgets,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: s(14)),
                      Container(height: 1, color: Colors.white12),
                      SizedBox(height: s(14)),
                      CoinMiningControls(
                        coinOwnerId: ownerId,
                        miningData: data,
                        baseRate: rate,
                        symbol: symbol,
                        variant: CoinMiningControlsVariant.myCoinCard,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ManagerSelectDialog extends StatefulWidget {
  final String? currentId;
  final Future<void> Function(String? id) onSelected;
  const _ManagerSelectDialog({
    required this.currentId,
    required this.onSelected,
  });
  @override
  State<_ManagerSelectDialog> createState() => _ManagerSelectDialogState();
}

class _ManagerSelectDialogState extends State<_ManagerSelectDialog> {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> managers = const [];
  Offerings? offerings;
  String? currentPlanId;
  bool loading = true;
  String? processingManagerId;
  String? selectedManagerId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Load Managers
    final qs = await FirestoreHelper.instance
        .collection(FirestoreConstants.managers)
        .where(FirestoreManagerFields.isActive, isEqualTo: true)
        .get();

    // Load Offerings
    await SubscriptionService().init();
    final offs = await SubscriptionService().getOfferings();

    // Load Current Subscription
    String? planId;
    if (uid != null) {
      final info = await SubscriptionService().refreshCustomerInfo();
      if (info != null) {
        planId = _activePlanIdFromCustomerInfo(info);
      }
    }

    if (mounted) {
      setState(() {
        managers = qs.docs;
        offerings = offs;
        currentPlanId = planId;
        String? picked = selectedManagerId ?? widget.currentId;
        if (picked == null || picked.isEmpty) {
          for (final d in qs.docs) {
            final isBest =
                (d.data()[FirestoreManagerFields.bestValue] as bool?) ?? false;
            if (isBest) {
              picked = d.id;
              break;
            }
          }
        }
        picked = picked ?? (qs.docs.isNotEmpty ? qs.docs.first.id : null);
        if (picked != null && qs.docs.every((d) => d.id != picked)) {
          picked = qs.docs.isNotEmpty ? qs.docs.first.id : null;
        }
        selectedManagerId = picked;
        loading = false;
      });
    }
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _findDocById(String id) {
    for (final d in managers) {
      if (d.id == id) return d;
    }
    return null;
  }

  String? _activePlanIdFromCustomerInfo(CustomerInfo info) {
    final now = DateTime.now();
    final activeEntitlements = info.entitlements.active.values.toList();
    if (activeEntitlements.isNotEmpty) {
      activeEntitlements.sort((a, b) {
        final da = DateTime.tryParse(a.expirationDate ?? '');
        final db = DateTime.tryParse(b.expirationDate ?? '');
        if (da == null && db == null) return 0;
        if (da == null) return -1;
        if (db == null) return 1;
        return db.compareTo(da);
      });
      return activeEntitlements.first.productIdentifier;
    }

    DateTime? bestExp;
    String? bestId;
    for (final subId in info.activeSubscriptions) {
      final expStr = info.allExpirationDates[subId];
      final exp = DateTime.tryParse(expStr ?? '');
      if (exp == null) continue;
      if (!exp.isAfter(now)) continue;
      if (bestExp == null || exp.isAfter(bestExp)) {
        bestExp = exp;
        bestId = subId;
      }
    }
    return bestId;
  }

  @override
  Widget build(BuildContext context) {
    const bg1 = Color(0xFF0E1721);
    const bg2 = Color(0xFF0A121B);
    const surface = Color(0xFF17222C);
    const border = Color(0xFF24303B);
    const blue = Color(0xFF1677FF);

    final selectedId = selectedManagerId;
    final selectedDoc = selectedId == null ? null : _findDocById(selectedId);
    final selectedData = selectedDoc?.data();
    final selectedProductId =
        (selectedData?[FirestoreManagerFields.storeProductId] as String?) ?? '';
    final selectedPkg = selectedProductId.isEmpty
        ? null
        : _findPackageForProductId(selectedProductId);
    final selectedPrice = selectedPkg?.storeProduct.priceString ?? '—';
    final isProcessing = processingManagerId != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 420).clamp(0.82, 1.0);
          double s(double v) => v * scale;
          final subtitleFont =
              (constraints.maxWidth / 420).clamp(0.78, 1.10) * 13.5;

          return Container(
            padding: EdgeInsets.all(s(16)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg1, bg2],
              ),
              borderRadius: BorderRadius.circular(s(22)),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: loading
                ? SizedBox(
                    height: s(140),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Manager',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: s(20),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: s(6)),
                                FractionallySizedBox(
                                  widthFactor: 0.75,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Hire a Manager to automate your mining and boost ETA point generation.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: subtitleFont,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: s(10)),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: s(36),
                              height: s(36),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.close_rounded,
                                size: s(20),
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: s(14)),
                      if (managers.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: s(18)),
                          child: Text(
                            'No managers available',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: s(14),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (int i = 0; i < managers.length; i++)
                              Padding(
                                padding: EdgeInsets.only(bottom: s(12)),
                                child: _buildManagerRow(
                                  managers[i],
                                  index: i,
                                  scale: s,
                                  surface: surface,
                                  border: border,
                                  blue: blue,
                                ),
                              ),
                          ],
                        ),
                      SizedBox(height: s(4)),
                      Row(
                        children: [
                          Text(
                            'Selected Plan:',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: s(13),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            selectedPrice,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: s(18),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: s(6)),
                          Padding(
                            padding: EdgeInsets.only(top: s(4)),
                            child: Text(
                              '/mo',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: s(13),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: s(12)),
                      SizedBox(
                        width: double.infinity,
                        height: s(54),
                        child: ElevatedButton(
                          onPressed:
                              (selectedDoc == null ||
                                  isProcessing ||
                                  managers.isEmpty)
                              ? null
                              : () => _confirmSelected(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            disabledBackgroundColor: blue.withValues(
                              alpha: 0.35,
                            ),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white.withValues(
                              alpha: 0.7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s(16)),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isProcessing) ...[
                                SizedBox(
                                  width: s(18),
                                  height: s(18),
                                  child: CircularProgressIndicator(
                                    strokeWidth: s(2),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                ),
                                SizedBox(width: s(10)),
                              ],
                              Text(
                                'Subscribe & Boost Mining',
                                style: TextStyle(
                                  fontSize: s(15),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: s(10)),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: s(18),
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: s(10)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: s(14),
                            color: Colors.white38,
                          ),
                          SizedBox(width: s(6)),
                          Text(
                            'Secure payment via Google Play',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: s(12.5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSelected() async {
    final id = selectedManagerId;
    if (id == null || processingManagerId != null) return;
    final doc = _findDocById(id);
    if (doc == null) return;

    final u = FirebaseAuth.instance.currentUser;
    if (u != null && !(u.emailVerified)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Email verification required'),
            content: const Text('Please verify your email to continue.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () =>
                    AuthVerificationService.sendVerificationEmail(),
                child: const Text('Resend Email'),
              ),
              TextButton(
                onPressed: () async {
                  final ok =
                      await AuthVerificationService.refreshAndCheckVerified();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx, ok);
                },
                child: const Text('Refresh Status'),
              ),
            ],
          );
        },
      );
      if (proceed != true) return;
    }

    final data = doc.data();
    final storeProductId =
        (data[FirestoreManagerFields.storeProductId] as String?) ?? '';
    final bool isCurrent = widget.currentId == doc.id;
    final bool isSubscribed =
        currentPlanId != null && currentPlanId == storeProductId;

    if (isSubscribed) {
      if (!isCurrent) {
        setState(() => processingManagerId = doc.id);
        await widget.onSelected(doc.id);
      }
      if (mounted) Navigator.pop(context);
      return;
    }

    final pkg = storeProductId.isEmpty
        ? null
        : _findPackageForProductId(storeProductId);
    if (pkg != null) {
      setState(() => processingManagerId = doc.id);
      final success = await SubscriptionService().purchasePackage(pkg);
      if (success) {
        await _load();
        await widget.onSelected(doc.id);
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          setState(() => processingManagerId = null);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Purchase failed')));
        }
      }
      return;
    }

    setState(() => processingManagerId = null);
    await _openPlans(targetManagerId: doc.id, targetProductId: storeProductId);
  }

  Widget _buildManagerRow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required int index,
    required double Function(double v) scale,
    required Color surface,
    required Color border,
    required Color blue,
  }) {
    final data = doc.data();
    final name = (data[FirestoreManagerFields.name] as String?) ?? '—';
    final thumb = (data[FirestoreManagerFields.thumbnailUrl] as String?) ?? '';
    final storeProductId =
        (data[FirestoreManagerFields.storeProductId] as String?) ?? '';
    final multiplier =
        (data[FirestoreManagerFields.managerMultiplier] as num?)?.toDouble() ??
        1.0;
    final eta = (data[FirestoreManagerFields.enableEtaAuto] as bool?) ?? true;
    final coin =
        (data[FirestoreManagerFields.enableUserCoinAuto] as bool?) ?? true;
    final bestValue =
        (data[FirestoreManagerFields.bestValue] as bool?) ?? false;
    final maxCoins =
        (data[FirestoreManagerFields.maxCommunityCoinsManaged] as num?)
            ?.toInt() ??
        0;

    final pkg = storeProductId.isEmpty
        ? null
        : _findPackageForProductId(storeProductId);

    final selected = selectedManagerId == doc.id;
    final icon = multiplier >= 2.5
        ? Icons.diamond_rounded
        : (multiplier >= 1.75 ? Icons.groups_rounded : Icons.person_rounded);
    final iconBg = multiplier >= 2.5
        ? const Color(0xFFFFB020)
        : (multiplier >= 1.75
              ? const Color(0xFF8B5CF6)
              : const Color(0xFF1B4BFF));

    final pct = (((multiplier - 1.0) * 100).clamp(0.0, 9999.0));
    final pctText = '+${pct.toStringAsFixed(0)}% Speed';
    final price = pkg?.storeProduct.priceString ?? '—';

    return GestureDetector(
      onTap: () => setState(() => selectedManagerId = doc.id),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(scale(14)),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(scale(18)),
              border: Border.all(
                color: selected ? blue : border,
                width: selected ? scale(1.6) : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: scale(44),
                  height: scale(44),
                  decoration: BoxDecoration(
                    color: iconBg.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: thumb.isNotEmpty
                        ? Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) {
                              return Icon(icon, color: iconBg, size: scale(22));
                            },
                          )
                        : Icon(icon, color: iconBg, size: scale(22)),
                  ),
                ),
                SizedBox(width: scale(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: scale(15.5),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: scale(6)),
                      Row(
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            size: scale(16),
                            color: const Color(0xFF2ECC71),
                          ),
                          SizedBox(width: scale(6)),
                          Text(
                            pctText,
                            style: TextStyle(
                              color: const Color(0xFF2ECC71),
                              fontSize: scale(13),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (eta && coin) ...[
                        SizedBox(height: scale(6)),
                        Row(
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: scale(16),
                              color: Colors.white54,
                            ),
                            SizedBox(width: scale(6)),
                            Text(
                              'Auto-collect',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: scale(12.5),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: scale(4)),
                        Row(
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: scale(16),
                              color: Colors.white54,
                            ),
                            SizedBox(width: scale(6)),
                            Text(
                              'Auto mine $maxCoins ${maxCoins == 1 ? 'coin' : 'coins'}',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: scale(12.5),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: scale(10)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: scale(16),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: scale(2)),
                    Text(
                      '/mo',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: scale(12.5),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (selected) ...[
                  SizedBox(width: scale(10)),
                  Container(
                    width: scale(22),
                    height: scale(22),
                    decoration: BoxDecoration(
                      color: blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: scale(16),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (bestValue)
            Positioned(
              top: -scale(12),
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale(14),
                    vertical: scale(6),
                  ),
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scale(12),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Package? _findPackageForProductId(String productId) {
    final offs = offerings;
    if (offs == null) return null;
    final seen = <String>{};
    final pkgs = <Package>[];

    final current = offs.current;
    if (current != null) {
      for (final p in current.availablePackages) {
        if (seen.add(p.storeProduct.identifier)) {
          pkgs.add(p);
        }
      }
    }

    final all = offs.all;
    for (final o in all.values) {
      for (final p in o.availablePackages) {
        if (seen.add(p.storeProduct.identifier)) {
          pkgs.add(p);
        }
      }
    }

    for (final p in pkgs) {
      if (p.storeProduct.identifier == productId) return p;
    }
    return null;
  }

  Future<void> _openPlans({
    required String targetManagerId,
    required String targetProductId,
  }) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null && !(u.emailVerified)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Email verification required'),
            content: const Text('Please verify your email to view plans.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () =>
                    AuthVerificationService.sendVerificationEmail(),
                child: const Text('Resend Email'),
              ),
              TextButton(
                onPressed: () async {
                  final ok =
                      await AuthVerificationService.refreshAndCheckVerified();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx, ok);
                },
                child: const Text('Refresh Status'),
              ),
            ],
          );
        },
      );
      if (proceed != true) return;
    }

    final offs = offerings;
    if (offs == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscriptions are only available on Android/iOS.'),
        ),
      );
      return;
    }

    final seen = <String>{};
    final pkgs = <Package>[];

    final current = offs.current;
    if (current != null) {
      for (final p in current.availablePackages) {
        if (seen.add(p.storeProduct.identifier)) {
          pkgs.add(p);
        }
      }
    }

    for (final o in offs.all.values) {
      for (final p in o.availablePackages) {
        if (seen.add(p.storeProduct.identifier)) {
          pkgs.add(p);
        }
      }
    }

    if (pkgs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subscription plans available')),
      );
      return;
    }

    if (!mounted) return;
    final chosen = await showDialog<Package>(
      context: context,
      builder: (ctx) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Subscription Plans',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pkgs.length,
                    itemBuilder: (c, i) {
                      final p = pkgs[i];
                      final id = p.storeProduct.identifier;
                      final isTarget = id == targetProductId;
                      return ListTile(
                        title: Text(
                          '${p.storeProduct.title} (${p.storeProduct.priceString})',
                        ),
                        subtitle: Text(id),
                        trailing: isTarget
                            ? const Text(
                                'Recommended',
                                style: TextStyle(color: Colors.green),
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, p),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen == null) return;
    if (!mounted) return;

    setState(() => processingManagerId = targetManagerId);
    final success = await SubscriptionService().purchasePackage(chosen);
    if (success) {
      await _load();
      await widget.onSelected(targetManagerId);
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        setState(() => processingManagerId = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Purchase failed')));
      }
    }
  }
}

class _CoinSelectDialog extends StatefulWidget {
  final List<String> current;
  final int maxCount;
  final Future<void> Function(List<String> ids) onSelected;
  const _CoinSelectDialog({
    required this.current,
    required this.maxCount,
    required this.onSelected,
  });
  @override
  State<_CoinSelectDialog> createState() => _CoinSelectDialogState();
}

class _CoinSelectDialogState extends State<_CoinSelectDialog> {
  List<Map<String, dynamic>> coins = const [];
  late List<String> selectedIds = [...widget.current];
  final TextEditingController searchCtrl = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    List<Map<String, dynamic>> loaded = [];
    final qs = await FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .get();
    loaded = qs.docs.map((d) => d.data()).toList();

    coins = loaded
        .where(
          (d) => (d[FirestoreUserCoinMiningFields.ownerId] as String?) != uid,
        )
        .toList();
    setState(() {});
  }

  String _ownerId(Map<String, dynamic> data) {
    return (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
  }

  String _name(Map<String, dynamic> data) {
    return (data[FirestoreUserCoinMiningFields.name] as String?) ?? '—';
  }

  String _symbol(Map<String, dynamic> data) {
    return (data[FirestoreUserCoinMiningFields.symbol] as String?) ?? '';
  }

  String _imageUrl(Map<String, dynamic> data) {
    return (data[FirestoreUserCoinMiningFields.imageUrl] as String?) ?? '';
  }

  double _rate(Map<String, dynamic> data) {
    final v = data[FirestoreUserCoinMiningFields.hourlyRate];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  bool _isActive(Map<String, dynamic> data, {required DateTime now}) {
    final raw = data[FirestoreUserCoinMiningFields.lastMiningEnd];
    if (raw == null) return false;
    if (raw is Timestamp) return now.isBefore(raw.toDate());
    if (raw is String) {
      try {
        final d = DateTime.parse(raw);
        return now.isBefore(d);
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final int max = widget.maxCount;
    const bg1 = Color(0xFF0E1721);
    const bg2 = Color(0xFF0A121B);
    const surface = Color(0xFF17222C);
    const border = Color(0xFF24303B);
    const blue = Color(0xFF1677FF);

    final now = DateTime.now();
    final byId = <String, Map<String, dynamic>>{};
    for (final d in coins) {
      final id = _ownerId(d);
      if (id.isNotEmpty) byId[id] = d;
    }

    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? coins
        : coins.where((d) {
            final n = _name(d).toLowerCase();
            final s = _symbol(d).toLowerCase();
            return n.contains(q) || s.contains(q);
          }).toList();

    Future<void> confirm() async {
      await widget.onSelected(selectedIds);
      if (!context.mounted) return;
      Navigator.pop(context);
    }

    Future<void> clear() async {
      await widget.onSelected(const []);
      if (!context.mounted) return;
      Navigator.pop(context);
    }

    void toggleId(String ownerId) {
      if (ownerId.isEmpty) return;
      setState(() {
        if (selectedIds.contains(ownerId)) {
          selectedIds.remove(ownerId);
          return;
        }
        if (selectedIds.length < max) {
          selectedIds.add(ownerId);
        }
      });
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 420).clamp(0.82, 1.0);
          double s(double v) => v * scale;

          Widget pill(String text) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(6)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: blue,
                  fontSize: s(13),
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          }

          Widget selectedChip(String ownerId) {
            final doc = byId[ownerId];
            final name = doc == null ? '—' : _name(doc);
            final img = doc == null ? '' : _imageUrl(doc);
            final active = doc == null ? false : _isActive(doc, now: now);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: s(46),
                  padding: EdgeInsets.symmetric(horizontal: s(12)),
                  decoration: BoxDecoration(
                    color: active ? blue.withValues(alpha: 0.18) : surface,
                    borderRadius: BorderRadius.circular(s(14)),
                    border: Border.all(
                      color: active ? blue : border,
                      width: active ? s(1.2) : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: s(14),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        backgroundImage: img.isNotEmpty
                            ? NetworkImage(img)
                            : null,
                        child: img.isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w900,
                                  fontSize: s(12.5),
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: s(10)),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: s(14.5),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: s(10)),
                    ],
                  ),
                ),
                Positioned(
                  right: -s(6),
                  top: -s(6),
                  child: InkWell(
                    onTap: () => toggleId(ownerId),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: s(22),
                      height: s(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5A5F),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.20),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_rounded,
                        size: s(14),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          Widget placeholderChip() {
            final remaining = (max - selectedIds.length).clamp(0, max);
            return Container(
              height: s(46),
              padding: EdgeInsets.symmetric(horizontal: s(14)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(s(14)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              alignment: Alignment.center,
              child: Text(
                remaining <= 0 ? 'Limit reached' : 'Select $remaining more',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: s(13.5),
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          }

          Widget coinRow(Map<String, dynamic> doc) {
            final ownerId = _ownerId(doc);
            final selected = selectedIds.contains(ownerId);
            final name = _name(doc);
            final symbol = _symbol(doc);
            final img = _imageUrl(doc);
            final rate = _rate(doc);
            final active = _isActive(doc, now: now);
            final subtitle = active
                ? 'Active • ${rate.toStringAsFixed(1)}/hr'
                : (symbol.isNotEmpty ? symbol : 'Inactive');

            return GestureDetector(
              onTap: () => toggleId(ownerId),
              child: Container(
                padding: EdgeInsets.all(s(14)),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(s(18)),
                  border: Border.all(
                    color: selected ? blue : border,
                    width: selected ? s(1.4) : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: s(20),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      backgroundImage: img.isNotEmpty
                          ? NetworkImage(img)
                          : null,
                      child: img.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w900,
                                fontSize: s(14),
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: s(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: s(16),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: s(4)),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active ? blue : Colors.white54,
                              fontSize: s(13.5),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: s(12)),
                    Container(
                      width: s(30),
                      height: s(30),
                      decoration: BoxDecoration(
                        color: selected
                            ? blue
                            : Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? blue : Colors.white24,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_rounded,
                        size: s(18),
                        color: selected ? Colors.white : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            padding: EdgeInsets.all(s(16)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg1, bg2],
              ),
              borderRadius: BorderRadius.circular(s(22)),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: s(44),
                    height: s(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: s(14)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Manage Mining Portfolio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: s(20),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    pill('${selectedIds.length}/$max Selected'),
                  ],
                ),
                SizedBox(height: s(6)),
                Text(
                  'You can mine up to $max coins simultaneously.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: s(13.5),
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: s(14)),
                SizedBox(
                  height: s(54),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final id in selectedIds) ...[
                          selectedChip(id),
                          SizedBox(width: s(10)),
                        ],
                        if (selectedIds.length < max) placeholderChip(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: s(14)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: s(12)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(s(18)),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: s(20),
                        color: Colors.white38,
                      ),
                      SizedBox(width: s(8)),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (v) => setState(() => query = v),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: s(14.5),
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search coins',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: s(14.5),
                              fontWeight: FontWeight.w800,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: s(14)),
                if (coins.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: s(18)),
                    child: Text(
                      'No mined coins to select',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: s(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: s(12)),
                      itemBuilder: (context, i) => coinRow(filtered[i]),
                    ),
                  ),
                SizedBox(height: s(14)),
                SizedBox(
                  width: double.infinity,
                  height: s(54),
                  child: ElevatedButton(
                    onPressed: selectedIds.isEmpty ? null : confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      disabledBackgroundColor: blue.withValues(alpha: 0.35),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(s(16)),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: s(20)),
                        SizedBox(width: s(10)),
                        Text(
                          'Start Mining (${selectedIds.length})',
                          style: TextStyle(
                            fontSize: s(15),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: s(12)),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: s(48),
                        child: OutlinedButton(
                          onPressed: selectedIds.isEmpty ? null : clear,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s(16)),
                            ),
                          ),
                          child: Text(
                            'Clear Selection',
                            style: TextStyle(
                              fontSize: s(14),
                              fontWeight: FontWeight.w900,
                              color: selectedIds.isEmpty
                                  ? Colors.white38
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: s(12)),
                    Expanded(
                      child: SizedBox(
                        height: s(48),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s(16)),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: s(14),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
