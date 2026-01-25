import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/firestore_constants.dart';
import '../shared/device_id.dart';
import 'balance/my_coin_block.dart';
import '../services/coin_service.dart';
import '../services/sql_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/mining_state_service.dart';
import '../services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_verification_service.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage>
    with SingleTickerProviderStateMixin {
  final _miningService = MiningStateService();
  final _adsService = AdsService();
  late final TabController _tab = TabController(length: 2, vsync: this);
  String _minedSort = 'popular';
  String _liveSort = 'popular';
  DateTime? _lastUiUpdate;
  Timer? _debounceTimer;

  bool _rewardedLoading = false;
  static const String _prefsRewardedSessionStartMsKey =
      'ads_rewarded_session_start_ms';
  static const String _prefsRewardedSessionCountKey =
      'ads_rewarded_session_count';
  static const String _prefsRewardedSessionBaseHourlyRateKey =
      'ads_rewarded_session_base_hourly_rate';
  int _rewardedSessionStartMs = 0;
  int _rewardedWatchedThisSession = 0;
  double _rewardedSessionBaseHourlyRate = 0.0;

  @override
  void initState() {
    super.initState();
    _miningService.addListener(_handleServiceUpdate);
    _adsService.addListener(_handleAdsUpdate);
    _tab.addListener(() {
      if (!mounted) return;
      if (_tab.indexIsChanging) return;
      setState(() {});
    });
    unawaited(_adsService.init());
    unawaited(_loadRewardedSessionLimiter());
    _miningService.init().then((_) {
      if (mounted) _manageCommunityCoins();
      unawaited(_syncRewardedSessionWithMiningState());
    });
  }

  @override
  void dispose() {
    _miningService.removeListener(_handleServiceUpdate);
    _adsService.removeListener(_handleAdsUpdate);
    _tab.dispose();
    _debounceTimer?.cancel();
    super.dispose();
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
        _rewardedSessionBaseHourlyRate = _miningService.hourlyRate;
      });
      await _persistRewardedSessionLimiter();
      return;
    }

    if (_rewardedSessionBaseHourlyRate <= 0) {
      if (!mounted) return;
      setState(
        () => _rewardedSessionBaseHourlyRate = _miningService.hourlyRate,
      );
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
            if (next >= 2) {
              final before = _miningService.hourlyRate;
              final after = await _miningService.applyRewardedAdHourlyBoost(
                baseHourlyRate: _rewardedSessionBaseHourlyRate,
                percent: _adsService.config.rewardBonusPercent,
                rewardedWatchIndex: next,
              );
              if (!mounted) return;
              if (after > before) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Mining rate boosted: ${before.toStringAsFixed(2)} → ${after.toStringAsFixed(2)} ETA/hr',
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Rewarded bonus apply failed: $e');
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Ad bonus failed: $e')));
          }
        }());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reward: ${reward.amount} ${reward.type}')),
        );
      },
    );
    return true;
  }

  Future<void> _maybeAutoShowRewardedOnMiningStart() async {
    await _tryShowRewardedAd(silentUnavailable: true);
  }

  void _handleServiceUpdate() {
    if (!mounted) return;
    unawaited(_syncRewardedSessionWithMiningState());
    final now = DateTime.now();
    final last = _lastUiUpdate;
    if (last == null || now.difference(last) >= const Duration(seconds: 1)) {
      _lastUiUpdate = now;
      setState(() {});
      unawaited(_manageCommunityCoins());
      return;
    }
    _debounceTimer ??= Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _lastUiUpdate = DateTime.now();
      _debounceTimer = null;
      setState(() {});
      unawaited(_manageCommunityCoins());
    });
  }

  Future<void> _refresh() async {
    await _miningService.refresh();
    if (mounted) {
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
      final ownRef = FirebaseFirestore.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .collection(FirestoreUserSubCollections.coins)
          .doc(uid);
      final ownSnap = await ownRef.get();
      final ownData = ownSnap.data() ?? {};
      final ownEnd =
          ownData[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
      final ownActive =
          ownEnd != null && DateTime.now().isBefore(ownEnd.toDate());
      if (!ownActive) {
        try {
          await CoinService.startCoinMining(uid, deviceId: devId);
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
    final q = await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .get();
    final now = DateTime.now();
    int activeManaged = 0;
    for (final d in q.docs) {
      final data = d.data();
      final ownerId =
          (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
      if (ownerId == uid) {
        continue;
      }
      if (_miningService.managedCoinSelections.isNotEmpty &&
          !_miningService.managedCoinSelections.contains(ownerId)) {
        continue;
      }
      final end =
          data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
      final isActive = end != null && now.isBefore(end.toDate());
      if (isActive) activeManaged++;
    }
    for (final d in q.docs) {
      final data = d.data();
      final ownerId =
          (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
      if (ownerId == uid) {
        continue;
      }
      if (_miningService.managedCoinSelections.isNotEmpty &&
          !_miningService.managedCoinSelections.contains(ownerId)) {
        continue;
      }
      final end =
          data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
      final isActive = end != null && now.isBefore(end.toDate());
      if (!isActive && activeManaged < _miningService.managerMaxCommunity) {
        try {
          await CoinService.startCoinMining(ownerId, deviceId: devId);
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
            : rewardedMaxPerSession > 0
            ? 'Reward +${rewardedBonusPercent.toStringAsFixed(0)}% • $rewardedWatchedThisSession/$rewardedMaxPerSession'
            : 'Reward +${rewardedBonusPercent.toStringAsFixed(0)}%';

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
                              Text(
                                totalEta.toStringAsFixed(3),
                                style: TextStyle(
                                  fontSize: s(50),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
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
                      child: InkWell(
                        onTap: (rewardedLoading || rewardedLimitReached)
                            ? null
                            : onShowRewarded,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: s(12),
                            vertical: s(8),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white24),
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.ondemand_video_rounded,
                                size: s(16),
                                color: Colors.white70,
                              ),
                              SizedBox(width: s(8)),
                              Text(
                                rewardedLabel,
                                style: TextStyle(
                                  fontSize: s(13.5),
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Start failed: $e')));
                  }
                },
                showRewarded: _adsService.config.enableRewarded,
                rewardedLoading: _rewardedLoading,
                rewardedLimitReached: _rewardedLimitReached,
                rewardedWatchedThisSession: _rewardedWatchedThisSession,
                rewardedMaxPerSession:
                    _adsService.config.maxRewardedPerMiningSession,
                rewardedBonusPercent: _adsService.config.rewardBonusPercent,
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
      stream: CoinService.watchUserCoin(uid),
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
        (data[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
        0.0;

    const card = Color(0xFF17222C);
    const border = Color(0xFF24303B);
    return GestureDetector(
      onTap: () => _showCoinDetailsDialog(context, data),
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
            CoinMiningControls(coinOwnerId: ownerId),
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
            await FirebaseFirestore.instance
                .collection(FirestoreConstants.users)
                .doc(uid)
                .set({
                  FirestoreUserFields.activeManagerId: id,
                  FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
            if (id != null) {
              final mgr = await FirebaseFirestore.instance
                  .collection(FirestoreConstants.managers)
                  .doc(id)
                  .get();
              final m = mgr.data() ?? {};
              final max =
                  (m[FirestoreManagerFields.maxCommunityCoinsManaged] as num?)
                      ?.toInt() ??
                  0;
              final userRef = FirebaseFirestore.instance
                  .collection(FirestoreConstants.users)
                  .doc(uid);
              final userSnap = await userRef.get();
              final d = userSnap.data() ?? {};
              final sel =
                  ((d[FirestoreUserFields.managedCoinSelections] as List?)
                      ?.cast<String>()) ??
                  const [];
              if (max >= 0 && sel.length > max) {
                final trimmed = sel.take(max).toList();
                await userRef.set({
                  FirestoreUserFields.managedCoinSelections: trimmed,
                  FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
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
            await FirebaseFirestore.instance
                .collection(FirestoreConstants.users)
                .doc(uid)
                .set({
                  FirestoreUserFields.managedCoinSelections: ids,
                  FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
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
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(FirestoreConstants.users)
                .doc(uid)
                .collection(FirestoreUserSubCollections.coins)
                .snapshots(),
            builder: (context, snap) {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              var docs = snap.data?.docs ?? const [];
              if (uid != null) {
                docs = docs
                    .where(
                      (d) =>
                          (d.data()[FirestoreUserCoinMiningFields.ownerId]
                              as String?) !=
                          uid,
                    )
                    .toList();
              }
              docs = _sortMinedDocs(docs);
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('No coins yet. Add from Live Coins.'),
                  ),
                );
              }
              return Column(
                children: [for (final d in docs) _minedCoinCard(d.data())],
              );
            },
          ),
        ],
      ),
    );
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
                onSelected: (v) => setState(() => _liveSort = v),
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
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: CoinService.useSqlBackend
                ? null // No stream for SQL, we'll use FutureBuilder inside
                : FirebaseFirestore.instance
                      .collection(FirestoreConstants.userCoins)
                      .where(FirestoreUserCoinFields.isActive, isEqualTo: true)
                      .limit(20)
                      .snapshots(),
            builder: (context, snap) {
              if (CoinService.useSqlBackend) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: SqlApiService.getLiveCoins(sort: _liveSort),
                  builder: (context, sqlSnap) {
                    if (sqlSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    final coins = sqlSnap.data ?? [];
                    if (coins.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text('No live community coins (SQL)'),
                        ),
                      );
                    }
                    return Column(
                      children: [for (final coin in coins) _liveCoinCard(coin)],
                    );
                  },
                );
              }

              final uid = FirebaseAuth.instance.currentUser?.uid;
              var docs = (snap.data?.docs ?? const [])
                  .where(
                    (doc) =>
                        (doc.data()[FirestoreUserCoinFields.ownerId]
                            as String?) !=
                        uid,
                  )
                  .toList();
              docs = _sortLiveDocs(docs);
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No live community coins')),
                );
              }
              return Column(
                children: [for (final doc in docs) _liveCoinCard(doc.data())],
              );
            },
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortMinedDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final l = [...docs];
    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    switch (_minedSort) {
      case 'name_az':
        l.sort(
          (a, b) => cmp(
            (a.data()[FirestoreUserCoinMiningFields.name] as String?) ?? '',
            (b.data()[FirestoreUserCoinMiningFields.name] as String?) ?? '',
          ),
        );
        break;
      case 'name_za':
        l.sort(
          (a, b) => cmp(
            (b.data()[FirestoreUserCoinMiningFields.name] as String?) ?? '',
            (a.data()[FirestoreUserCoinMiningFields.name] as String?) ?? '',
          ),
        );
        break;
      case 'old_new':
        l.sort((a, b) {
          final ta =
              (a.data()[FirestoreUserCoinMiningFields.lastMiningStart]
                  as Timestamp?) ??
              (a.data()[FirestoreUserCoinMiningFields.lastSyncedAt]
                  as Timestamp?);
          final tb =
              (b.data()[FirestoreUserCoinMiningFields.lastMiningStart]
                  as Timestamp?) ??
              (b.data()[FirestoreUserCoinMiningFields.lastSyncedAt]
                  as Timestamp?);
          final va = ta?.millisecondsSinceEpoch ?? 0;
          final vb = tb?.millisecondsSinceEpoch ?? 0;
          return va.compareTo(vb);
        });
        break;
      case 'new_old':
        l.sort((a, b) {
          final ta =
              (a.data()[FirestoreUserCoinMiningFields.lastMiningStart]
                  as Timestamp?) ??
              (a.data()[FirestoreUserCoinMiningFields.lastSyncedAt]
                  as Timestamp?);
          final tb =
              (b.data()[FirestoreUserCoinMiningFields.lastMiningStart]
                  as Timestamp?) ??
              (b.data()[FirestoreUserCoinMiningFields.lastSyncedAt]
                  as Timestamp?);
          final va = ta?.millisecondsSinceEpoch ?? 0;
          final vb = tb?.millisecondsSinceEpoch ?? 0;
          return vb.compareTo(va);
        });
        break;
      case 'random':
        l.shuffle();
        break;
      case 'popular':
      default:
        l.sort((a, b) {
          final pa =
              (a.data()[FirestoreUserCoinMiningFields.totalPoints] as num?)
                  ?.toDouble() ??
              0.0;
          final pb =
              (b.data()[FirestoreUserCoinMiningFields.totalPoints] as num?)
                  ?.toDouble() ??
              0.0;
          return pb.compareTo(pa);
        });
    }
    return l;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortLiveDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final l = [...docs];
    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    switch (_liveSort) {
      case 'name_az':
        l.sort(
          (a, b) => cmp(
            (a.data()[FirestoreUserCoinFields.name] as String?) ?? '',
            (b.data()[FirestoreUserCoinFields.name] as String?) ?? '',
          ),
        );
        break;
      case 'name_za':
        l.sort(
          (a, b) => cmp(
            (b.data()[FirestoreUserCoinFields.name] as String?) ?? '',
            (a.data()[FirestoreUserCoinFields.name] as String?) ?? '',
          ),
        );
        break;
      case 'old_new':
        l.sort((a, b) {
          final ta =
              (a.data()[FirestoreUserCoinFields.createdAt] as Timestamp?) ??
              (a.data()[FirestoreUserCoinFields.updatedAt] as Timestamp?);
          final tb =
              (b.data()[FirestoreUserCoinFields.createdAt] as Timestamp?) ??
              (b.data()[FirestoreUserCoinFields.updatedAt] as Timestamp?);
          final va = ta?.millisecondsSinceEpoch ?? 0;
          final vb = tb?.millisecondsSinceEpoch ?? 0;
          return va.compareTo(vb);
        });
        break;
      case 'new_old':
        l.sort((a, b) {
          final ta =
              (a.data()[FirestoreUserCoinFields.createdAt] as Timestamp?) ??
              (a.data()[FirestoreUserCoinFields.updatedAt] as Timestamp?);
          final tb =
              (b.data()[FirestoreUserCoinFields.createdAt] as Timestamp?) ??
              (b.data()[FirestoreUserCoinFields.updatedAt] as Timestamp?);
          final va = ta?.millisecondsSinceEpoch ?? 0;
          final vb = tb?.millisecondsSinceEpoch ?? 0;
          return vb.compareTo(va);
        });
        break;
      case 'popular':
      default:
        l.sort((a, b) {
          final ma =
              (a.data()[FirestoreUserCoinFields.minersCount] as num?)
                  ?.toInt() ??
              0;
          final mb =
              (b.data()[FirestoreUserCoinFields.minersCount] as num?)
                  ?.toInt() ??
              0;
          if (mb != ma) return mb.compareTo(ma);
          final la =
              ((a.data()[FirestoreUserCoinFields.socialLinks] as List?) ?? [])
                  .length;
          final lb =
              ((b.data()[FirestoreUserCoinFields.socialLinks] as List?) ?? [])
                  .length;
          if (lb != la) return lb.compareTo(la);
          final ra =
              (a.data()[FirestoreUserCoinFields.baseRatePerHour] as num?)
                  ?.toDouble() ??
              0.0;
          final rb =
              (b.data()[FirestoreUserCoinFields.baseRatePerHour] as num?)
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
        (data[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
        0.0;
    const card = Color(0xFF17222C);
    const border = Color(0xFF24303B);
    return GestureDetector(
      onTap: () => _showCoinDetailsDialog(context, data),
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
                          await CoinService.addCoinForUser(ownerId);
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
    final ownerId =
        (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
    final name = (data[FirestoreUserCoinMiningFields.name] as String?) ?? '—';
    final symbol =
        (data[FirestoreUserCoinMiningFields.symbol] as String?) ?? '';
    final imageUrl =
        (data[FirestoreUserCoinMiningFields.imageUrl] as String?) ?? '';
    final rate =
        (data[FirestoreUserCoinMiningFields.hourlyRate] as num?)?.toDouble() ??
        0.0;
    const card = Color(0xFF17222C);
    const border = Color(0xFF24303B);
    return GestureDetector(
      onTap: () => _showCoinDetailsDialog(context, data),
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
            CoinMiningControls(coinOwnerId: ownerId, miningData: data),
          ],
        ),
      ),
    );
  }

  void _showCoinDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    final ownerId = (data['ownerId'] as String?) ?? '';
    final name = (data['name'] as String?) ?? '—';
    final symbol = (data['symbol'] as String?) ?? '';
    final imageUrl = (data['imageUrl'] as String?) ?? '';
    final description =
        (data['description'] as String?) ?? 'No description available.';
    final rate =
        (data[FirestoreUserCoinMiningFields.hourlyRate] as num?)?.toDouble() ??
        (data[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
        0.0;
    final total =
        (data[FirestoreUserCoinMiningFields.totalPoints] as num?)?.toDouble() ??
        0.0;
    final links = (data['socialLinks'] as List<dynamic>?) ?? const [];
    final holders =
        (data['holdersCount'] as num?)?.toDouble() ??
        (data['holders'] as num?)?.toDouble();
    final changePct =
        (data['rateChangePct'] as num?)?.toDouble() ??
        (data['changePct'] as num?)?.toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = uid != null && uid == ownerId;

    Future<double?> fetchTotalMinedAll() async {
      if (ownerId.isEmpty) return null;
      try {
        final qs = await FirebaseFirestore.instance
            .collectionGroup(FirestoreUserSubCollections.coins)
            .where(FirestoreUserCoinMiningFields.ownerId, isEqualTo: ownerId)
            .get();
        double sum = 0.0;
        for (final doc in qs.docs) {
          final v =
              (doc.data()[FirestoreUserCoinMiningFields.totalPoints] as num?)
                  ?.toDouble();
          if (v != null && v.isFinite) {
            sum += v;
          }
        }
        return sum;
      } catch (_) {
        return null;
      }
    }

    final totalMinedAllFuture = isCreator ? fetchTotalMinedAll() : null;

    showDialog(
      context: context,
      builder: (ctx) {
        const cardBg = Color(0xFF0F1A24);
        const cardBg2 = Color(0xFF0B121A);
        const surface = Color(0xFF17222C);
        const border = Color(0xFF24303B);
        const buttonBlue = Color(0xFF1677FF);
        const accentOrange = Color(0xFFFFB020);

        String compactNum(num? v) {
          if (v == null) {
            return '—';
          }
          final n = v.toDouble();
          if (!n.isFinite) {
            return '—';
          }
          final abs = n.abs();
          if (abs >= 1000000000) {
            return '${(n / 1000000000).toStringAsFixed(1)}B';
          }
          if (abs >= 1000000) {
            return '${(n / 1000000).toStringAsFixed(1)}M';
          }
          if (abs >= 1000) {
            return '${(n / 1000).toStringAsFixed(1)}k';
          }
          if (abs >= 100) {
            return n.toStringAsFixed(0);
          }
          if (abs >= 10) {
            return n.toStringAsFixed(1);
          }
          return n.toStringAsFixed(2);
        }

        String fmtRate(double v) {
          final s = v.toStringAsFixed(3);
          return s.replaceFirst(RegExp(r'\.?0+$'), '');
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 22,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxWidth / 420).clamp(0.82, 1.0);
              double s(double v) => v * scale;
              var expanded = false;

              Widget metricCard({
                required IconData icon,
                required Color iconBg,
                required String title,
                required String value,
                String? suffix,
                String? footnote,
                Color? footnoteColor,
              }) {
                return Container(
                  padding: EdgeInsets.all(s(14)),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(s(18)),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: s(34),
                            height: s(34),
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(s(12)),
                            ),
                            child: Icon(icon, size: s(18), color: Colors.white),
                          ),
                          SizedBox(width: s(10)),
                          Expanded(
                            child: Text(
                              title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: s(11.5),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: s(12)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: s(20),
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          if (suffix != null) ...[
                            SizedBox(width: s(6)),
                            Padding(
                              padding: EdgeInsets.only(bottom: s(2)),
                              child: Text(
                                suffix,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: s(12.5),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (footnote != null) ...[
                        SizedBox(height: s(6)),
                        Text(
                          footnote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: footnoteColor ?? Colors.white54,
                            fontSize: s(12.5),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(s(26)),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [cardBg, cardBg2],
                    ),
                    border: Border.all(color: Colors.white10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(s(26)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: s(10)),
                        Container(
                          width: s(54),
                          height: s(5),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        SizedBox(height: s(10)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: s(18)),
                          child: Row(
                            children: [
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                  size: s(22),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              s(18),
                              0,
                              s(18),
                              s(16),
                            ),
                            child: StatefulBuilder(
                              builder: (context, setLocal) {
                                void toggle() =>
                                    setLocal(() => expanded = !expanded);

                                final showReadMore = description.length > 140;
                                final aboutText = description;

                                return Column(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        SizedBox(
                                          width: s(112),
                                          height: s(112),
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: ClipOval(
                                                  child: imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          imageUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stack,
                                                              ) {
                                                                return Container(
                                                                  color: Colors
                                                                      .white10,
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: Icon(
                                                                    Icons
                                                                        .monetization_on_rounded,
                                                                    size: s(42),
                                                                    color: Colors
                                                                        .white54,
                                                                  ),
                                                                );
                                                              },
                                                        )
                                                      : Container(
                                                          color: Colors.white10,
                                                          alignment:
                                                              Alignment.center,
                                                          child: Icon(
                                                            Icons
                                                                .monetization_on_rounded,
                                                            size: s(42),
                                                            color:
                                                                Colors.white54,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: accentOrange,
                                                      width: s(2),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          right: s(4),
                                          bottom: s(6),
                                          child: Container(
                                            width: s(26),
                                            height: s(26),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: buttonBlue,
                                              border: Border.all(
                                                color: cardBg,
                                                width: s(2),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: s(16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(12)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: s(26),
                                              fontWeight: FontWeight.w900,
                                              height: 1.05,
                                            ),
                                          ),
                                        ),
                                        if (symbol.isNotEmpty) ...[
                                          SizedBox(width: s(8)),
                                          Text(
                                            '(\$$symbol)',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: s(16),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (ownerId.isNotEmpty) ...[
                                      SizedBox(height: s(8)),
                                      FutureBuilder<
                                        DocumentSnapshot<Map<String, dynamic>>
                                      >(
                                        future: FirebaseFirestore.instance
                                            .collection(
                                              FirestoreConstants.users,
                                            )
                                            .doc(ownerId)
                                            .get(),
                                        builder: (context, snapshot) {
                                          final u = snapshot.data?.data();
                                          final username =
                                              (u?[FirestoreUserFields.username]
                                                  as String?) ??
                                              'Unknown';
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: s(12),
                                              vertical: s(8),
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.06,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: s(10),
                                                  backgroundColor:
                                                      Colors.white12,
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    size: s(14),
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                SizedBox(width: s(8)),
                                                Text(
                                                  'Created by @$username',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: s(13.5),
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                SizedBox(width: s(8)),
                                                Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Colors.white54,
                                                  size: s(18),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    SizedBox(height: s(18)),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: metricCard(
                                            icon: Icons.bolt_rounded,
                                            iconBg: const Color(
                                              0xFF1B4BFF,
                                            ).withValues(alpha: 0.35),
                                            title: 'Mining rate',
                                            value: fmtRate(rate),
                                            suffix: 'ETA/hr',
                                            footnote: changePct == null
                                                ? null
                                                : '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                                            footnoteColor: changePct == null
                                                ? null
                                                : (changePct >= 0
                                                      ? const Color(0xFF2ECC71)
                                                      : const Color(
                                                          0xFFFF5A5F,
                                                        )),
                                          ),
                                        ),
                                        SizedBox(width: s(12)),
                                        Expanded(
                                          child: metricCard(
                                            icon: Icons.layers_rounded,
                                            iconBg: const Color(
                                              0xFF8B5CF6,
                                            ).withValues(alpha: 0.28),
                                            title: 'Total mined',
                                            value: compactNum(total),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(12)),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: metricCard(
                                            icon: Icons.groups_rounded,
                                            iconBg: const Color(
                                              0xFFFF4D9D,
                                            ).withValues(alpha: 0.22),
                                            title: 'Holders',
                                            value: compactNum(holders),
                                          ),
                                        ),
                                        SizedBox(width: s(12)),
                                        Expanded(
                                          child: isCreator
                                              ? FutureBuilder<double?>(
                                                  future: totalMinedAllFuture,
                                                  builder: (context, snap) {
                                                    final done =
                                                        snap.connectionState ==
                                                        ConnectionState.done;
                                                    final v = done
                                                        ? snap.data
                                                        : null;
                                                    return metricCard(
                                                      icon:
                                                          Icons.layers_rounded,
                                                      iconBg: const Color(
                                                        0xFF8B5CF6,
                                                      ).withValues(alpha: 0.28),
                                                      title: 'Total mined',
                                                      value: done
                                                          ? compactNum(v)
                                                          : '…',
                                                    );
                                                  },
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: s(18)),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'About $name',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: s(16),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: s(8)),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        aboutText,
                                        maxLines: showReadMore && !expanded
                                            ? 4
                                            : 999,
                                        overflow: showReadMore && !expanded
                                            ? TextOverflow.ellipsis
                                            : TextOverflow.visible,
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: s(13.5),
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    if (showReadMore) ...[
                                      SizedBox(height: s(8)),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: GestureDetector(
                                          onTap: toggle,
                                          child: Text(
                                            expanded
                                                ? 'Read Less'
                                                : 'Read More',
                                            style: TextStyle(
                                              color: buttonBlue,
                                              fontSize: s(13.5),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (links.isNotEmpty) ...[
                                      SizedBox(height: s(18)),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Project Links',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: s(14),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: s(10)),
                                      Wrap(
                                        spacing: s(8),
                                        runSpacing: s(8),
                                        children: [
                                          for (final l in links)
                                            _LinkButton(
                                              type:
                                                  (l['type'] as String?) ??
                                                  'other',
                                              url: (l['url'] as String?) ?? '',
                                            ),
                                        ],
                                      ),
                                    ],
                                    SizedBox(height: s(18)),
                                    SizedBox(
                                      width: double.infinity,
                                      height: s(52),
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: buttonBlue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'Close',
                                          style: TextStyle(
                                            fontSize: s(15),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
    final qs = await FirebaseFirestore.instance
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
  List<QueryDocumentSnapshot<Map<String, dynamic>>> coins = const [];
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
    final qs = await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .get();
    coins = qs.docs
        .where(
          (d) =>
              (d.data()[FirestoreUserCoinMiningFields.ownerId] as String?) !=
              uid,
        )
        .toList();
    setState(() {});
  }

  String _ownerId(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return (doc.data()[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
  }

  String _name(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return (doc.data()[FirestoreUserCoinMiningFields.name] as String?) ?? '—';
  }

  String _symbol(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return (doc.data()[FirestoreUserCoinMiningFields.symbol] as String?) ?? '';
  }

  String _imageUrl(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return (doc.data()[FirestoreUserCoinMiningFields.imageUrl] as String?) ??
        '';
  }

  double _rate(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return (doc.data()[FirestoreUserCoinMiningFields.hourlyRate] as num?)
            ?.toDouble() ??
        0.0;
  }

  bool _isActive(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required DateTime now,
  }) {
    final end =
        doc.data()[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
    if (end == null) return false;
    return now.isBefore(end.toDate());
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
    final byId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
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

          Widget coinRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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

class _LinkButton extends StatelessWidget {
  final String type;
  final String url;
  const _LinkButton({required this.type, required this.url});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color? color;
    switch (type.toLowerCase()) {
      case 'website':
        icon = Icons.language;
        break;
      case 'youtube':
        icon = Icons.play_circle_fill;
        color = Colors.red;
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = Colors.blue;
        break;
      case 'twitter':
      case 'x':
        icon = Icons.close;
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        color = Colors.purpleAccent;
        break;
      case 'telegram':
        icon = Icons.send;
        color = Colors.lightBlue;
        break;
      default:
        icon = Icons.link;
    }

    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon, color: color ?? Colors.white70),
        tooltip: type,
        onPressed: () async {
          if (url.isEmpty) return;
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}
