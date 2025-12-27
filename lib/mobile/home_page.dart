import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/firestore_constants.dart';
import '../shared/device_id.dart';
import 'balance/my_coin_block.dart';
import '../services/coin_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/mining_state_service.dart';
import '../services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          child: Column(
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
                        '+${hourlyRate.toStringAsFixed(1)} ETA/hr',
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
                    style: TextStyle(color: Colors.white38, fontSize: s(14)),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(timeBlue),
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
                    disabledBackgroundColor: buttonBlue.withValues(alpha: 0.35),
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
        actions: [
          TextButton(onPressed: _openManagerSelector, child: const Text('VIP')),
          TextButton(onPressed: _openCoinSelector, child: const Text('Coins')),
        ],
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
                    await _miningService.startMining();
                    await _syncRewardedSessionWithMiningState();
                    await _maybeAutoShowRewardedOnMiningStart();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      this.context,
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
              child: MyCoinBlock(variant: MyCoinBlockVariant.home),
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
            stream: FirebaseFirestore.instance
                .collection(FirestoreConstants.userCoins)
                .where(FirestoreUserCoinFields.isActive, isEqualTo: true)
                .limit(20)
                .snapshots(),
            builder: (context, snap) {
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

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white10,
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? const Icon(
                        Icons.monetization_on,
                        size: 40,
                        color: Colors.white54,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                '$name ($symbol)',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (ownerId.isNotEmpty)
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection(FirestoreConstants.users)
                      .doc(ownerId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final u = snapshot.data!.data();
                    final username =
                        (u?[FirestoreUserFields.username] as String?) ??
                        'Unknown';
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Created by @$username',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              Text(
                '${rate.toStringAsFixed(3)}/h${total > 0 ? ' • Total: ${total.toStringAsFixed(3)}' : ''}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (links.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Links',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final l in links)
                      _LinkButton(
                        type: (l['type'] as String?) ?? 'other',
                        url: (l['url'] as String?) ?? '',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
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
        loading = false;
      });
    }
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
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select Manager Plan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (managers.isEmpty) const Text('No managers available'),
                  for (final doc in managers) _buildManagerRow(doc),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildManagerRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data[FirestoreManagerFields.name] as String?) ?? '—';
    final thumb = (data[FirestoreManagerFields.thumbnailUrl] as String?) ?? '';
    final storeProductId =
        (data[FirestoreManagerFields.storeProductId] as String?) ?? '';

    final bool isCurrent = widget.currentId == doc.id;
    final bool isSubscribed =
        currentPlanId != null && currentPlanId == storeProductId;

    // Find package
    final pkg = storeProductId.isEmpty
        ? null
        : _findPackageForProductId(storeProductId);
    final isProcessing = processingManagerId == doc.id;

    Future<void> handleTap() async {
      if (isProcessing) return;
      if (isSubscribed) {
        if (isCurrent) return;
        setState(() => processingManagerId = doc.id);
        await widget.onSelected(doc.id);
        if (mounted) Navigator.pop(context);
        return;
      }

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

      await _openPlans(
        targetManagerId: doc.id,
        targetProductId: storeProductId,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: handleTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: thumb.isNotEmpty ? NetworkImage(thumb) : null,
                child: thumb.isEmpty
                    ? const Icon(Icons.auto_mode_rounded)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isSubscribed)
                      const Text(
                        'Active',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      )
                    else if (pkg != null)
                      Text(
                        pkg.storeProduct.priceString,
                        style: const TextStyle(fontSize: 12),
                      )
                    else
                      const Text(
                        'Tap to view plans',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (isProcessing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isSubscribed)
                ElevatedButton(
                  onPressed: isCurrent ? null : handleTap,
                  child: isCurrent
                      ? const Icon(Icons.check)
                      : const Text('Select'),
                )
              else if (pkg != null)
                ElevatedButton(onPressed: handleTap, child: const Text('Buy'))
              else
                ElevatedButton(
                  onPressed: handleTap,
                  child: const Text('Plans'),
                ),
            ],
          ),
        ),
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

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    final int max = widget.maxCount;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Coins (${selectedIds.length}/$max)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (coins.isEmpty) const Text('No mined coins to select'),
            for (final doc in coins)
              CheckboxListTile(
                value: selectedIds.contains(
                  (doc.data()[FirestoreUserCoinMiningFields.ownerId]
                          as String?) ??
                      '',
                ),
                onChanged: (v) {
                  final ownerId =
                      (doc.data()[FirestoreUserCoinMiningFields.ownerId]
                          as String?) ??
                      '';
                  if (ownerId.isEmpty) return;
                  setState(() {
                    if (v == true) {
                      if (selectedIds.length < max) {
                        if (!selectedIds.contains(ownerId)) {
                          selectedIds.add(ownerId);
                        }
                      }
                    } else {
                      selectedIds.remove(ownerId);
                    }
                  });
                },
                title: Text(
                  (doc.data()[FirestoreUserCoinMiningFields.name] as String?) ??
                      '—',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await widget.onSelected(selectedIds);
                    if (!context.mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await widget.onSelected(const []);
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
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
