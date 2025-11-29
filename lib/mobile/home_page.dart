import 'package:flutter/material.dart';
import 'dart:async';
import '../shared/theme/colors.dart';
import 'widgets/glowing_button.dart';
import 'widgets/progress_ring.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/earnings_engine.dart';
import '../shared/firestore_constants.dart';
import '../shared/device_id.dart';
import 'balance/my_coin_block.dart';
import '../services/coin_service.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage>
    with SingleTickerProviderStateMixin {
  bool miningActive = false;
  double progress = 0.0;
  double hourlyRate = 0.0;
  int streakDays = 0;
  double totalPoints = 0.0;
  Timestamp? lastStart;
  Timestamp? lastEnd;
  Timer? _simTimer;
  double _simBase = 0.0;
  DateTime? _simAnchor;
  double _displayTotal = 0.0;
  String _remaining = '';
  int _sessionHours = 24;
  String? _deviceId;
  late final TabController _tab = TabController(length: 2, vsync: this);
  bool _managerEnabled = false;
  bool _managerEtaAuto = true;
  bool _managerUserCoinAuto = true;
  int _managerMaxCommunity = 0;
  bool _managerGlobalEnabled = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _ensureDeviceId();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  Future<void> _ensureDeviceId() async {
    _deviceId = await DeviceId.get();
  }

  Future<void> _refresh() async {
    await EarningsEngine.syncEarnings();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final general = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.general)
        .get();
    final g = general.data() ?? {};
    _sessionHours =
        ((g[FirestoreAppConfigFields.sessionDurationHours] as num?)?.toInt() ??
        24);
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .get();
    final d = snap.data() ?? {};
    setState(() {
      totalPoints =
          (d[FirestoreUserFields.totalPoints] as num?)?.toDouble() ?? 0.0;
      hourlyRate =
          (d[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;
      streakDays = (d[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;
      lastStart = d[FirestoreUserFields.lastMiningStart] as Timestamp?;
      lastEnd = d[FirestoreUserFields.lastMiningEnd] as Timestamp?;
      miningActive =
          lastEnd != null && DateTime.now().isBefore(lastEnd!.toDate());
      progress = _computeProgress();
      _displayTotal = totalPoints;
      _managerEnabled =
          (d[FirestoreUserFields.managerEnabled] as bool?) ?? false;
    });
    final managerCfg = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.manager)
        .get();
    final m = managerCfg.data() ?? {};
    _managerGlobalEnabled =
        (m[FirestoreManagerConfigFields.enabledGlobally] as bool?) ?? true;
    _managerEtaAuto =
        (m[FirestoreManagerConfigFields.enableEtaAuto] as bool?) ?? true;
    _managerUserCoinAuto =
        (m[FirestoreManagerConfigFields.enableUserCoinAuto] as bool?) ?? true;
    _managerMaxCommunity =
        (m[FirestoreManagerConfigFields.maxCommunityCoinsManaged] as num?)
            ?.toInt() ??
        0;
    if (_managerEnabled &&
        _managerGlobalEnabled &&
        _managerEtaAuto &&
        !miningActive) {
      final devId = _deviceId ?? await DeviceId.get();
      final res = await EarningsEngine.startMining(deviceId: devId);
      setState(() {
        hourlyRate =
            (res[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ??
            hourlyRate;
        lastStart = res[FirestoreUserFields.lastMiningStart] as Timestamp?;
        lastEnd = res[FirestoreUserFields.lastMiningEnd] as Timestamp?;
        miningActive =
            lastEnd != null && DateTime.now().isBefore(lastEnd!.toDate());
        progress = _computeProgress();
        _displayTotal = totalPoints;
      });
    }
    _updateRemaining();
    _startSimulationIfNeeded();
    await _manageCommunityCoins();
  }

  void _startSimulationIfNeeded() {
    _simTimer?.cancel();
    if (!miningActive || lastEnd == null) {
      setState(() {
        _displayTotal = totalPoints;
      });
      return;
    }
    _simBase = totalPoints;
    _simAnchor = DateTime.now();
    final end = lastEnd!.toDate();
    _simTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final anchor = _simAnchor!;
      final now = DateTime.now();
      if (!now.isBefore(end)) {
        _simTimer?.cancel();
        setState(() {
          _displayTotal = _simBase;
          miningActive = false;
          progress = _computeProgress();
          _updateRemaining();
        });
        EarningsEngine.syncEarnings().then((_) async {
          if (_managerEnabled && _managerGlobalEnabled && _managerEtaAuto) {
            final devId = _deviceId ?? await DeviceId.get();
            await EarningsEngine.startMining(deviceId: devId);
          }
          await _refresh();
        });
        return;
      }
      final elapsedSec = now.difference(anchor).inMilliseconds / 1000.0;
      final remainingSec = end.difference(anchor).inSeconds.toDouble();
      final incPerSec = hourlyRate > 0.0 ? (hourlyRate / 3600.0) : 0.0;
      final inc = (elapsedSec * incPerSec).clamp(0.0, remainingSec * incPerSec);
      setState(() {
        _displayTotal = _simBase + inc;
        progress = _computeProgress();
        _updateRemaining();
      });
    });
  }

  Future<void> _manageCommunityCoins() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!(_managerEnabled && _managerGlobalEnabled)) return;
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
      final end =
          data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
      final isActive = end != null && now.isBefore(end.toDate());
      final isOwnCoin = ownerId == uid;
      if (!isOwnCoin && isActive) activeManaged++;
    }
    for (final d in q.docs) {
      final data = d.data();
      final ownerId =
          (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
      final end =
          data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
      final isActive = end != null && now.isBefore(end.toDate());
      final isOwnCoin = ownerId == uid;
      if (isOwnCoin) {
        if (_managerUserCoinAuto && !isActive) {
          await CoinService.startCoinMining(ownerId);
        }
        continue;
      }
      if (_managerMaxCommunity <= 0) continue;
      if (!isActive && activeManaged < _managerMaxCommunity) {
        await CoinService.startCoinMining(ownerId);
        activeManaged++;
      }
    }
  }

  double _computeProgress() {
    if (lastEnd == null) return 0.0;
    final end = lastEnd!.toDate();
    final now = DateTime.now();
    final totalSec = (_sessionHours * 3600).toDouble();
    final remainingSec = end.difference(now).inSeconds.toDouble();
    final doneSec = (totalSec - remainingSec).clamp(0.0, totalSec);
    final p = totalSec > 0 ? (doneSec / totalSec) : 0.0;
    return p.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double ringHeight = (size.height * 0.28).clamp(140.0, 220.0);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('ETA Network'),
      ),
      body: Column(
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            _displayTotal.toStringAsFixed(3),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Total ETA',
                            style: TextStyle(color: AppColors.secondaryAccent),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: ringHeight,
                            child: ProgressRing(
                              progress: progress,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${hourlyRate.toStringAsFixed(2)} ETA/hr',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    miningActive ? 'Mining Active' : 'Inactive',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _remaining.isNotEmpty
                                        ? _remaining
                                        : (miningActive ? '—' : 'Tap to start'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlowingButton(
                            label: miningActive ? 'Mining…' : 'START EARNING',
                            onPressed: miningActive
                                ? null
                                : () async {
                                    final devId =
                                        _deviceId ?? await DeviceId.get();
                                    final res =
                                        await EarningsEngine.startMining(
                                          deviceId: devId,
                                        );
                                    setState(() {
                                      hourlyRate =
                                          (res['hourlyRate'] as num?)
                                              ?.toDouble() ??
                                          hourlyRate;
                                      lastStart =
                                          res['lastMiningStart'] as Timestamp?;
                                      lastEnd =
                                          res['lastMiningEnd'] as Timestamp?;
                                      miningActive =
                                          lastEnd != null &&
                                          DateTime.now().isBefore(
                                            lastEnd!.toDate(),
                                          );
                                      progress = _computeProgress();
                                      _displayTotal = totalPoints;
                                    });
                                    _startSimulationIfNeeded();
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Streak Days: $streakDays',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: MyCoinBlock(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Mined Coins'),
              Tab(text: 'Live Coins'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_minedCoinsTab(), _liveCoinsTab()],
            ),
          ),
        ],
      ),
    );
  }

  void _updateRemaining() {
    if (!miningActive || lastEnd == null) {
      _remaining = '';
      return;
    }
    final end = lastEnd!.toDate();
    final now = DateTime.now();
    Duration rem = end.difference(now);
    if (rem.isNegative) rem = Duration.zero;
    final h = rem.inHours;
    final m = rem.inMinutes % 60;
    _remaining = '${h}h ${m}m remaining';
  }

  Widget _minedCoinsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mined Coins'),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No coins yet. Add from Live Coins.'),
                  );
                }
                return ListView(
                  children: [for (final d in docs) _minedCoinCard(d.data())],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveCoinsTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Coins'),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(FirestoreConstants.userCoins)
                  .where(FirestoreUserCoinFields.isActive, isEqualTo: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snap) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final docs = (snap.data?.docs ?? const [])
                    .where(
                      (doc) =>
                          (doc.data()[FirestoreUserCoinFields.ownerId]
                              as String?) !=
                          uid,
                    )
                    .toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('No live community coins'));
                }
                return ListView(
                  children: [for (final doc in docs) _liveCoinCard(doc.data())],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveCoinCard(Map<String, dynamic> data) {
    final ownerId = (data[FirestoreUserCoinFields.ownerId] as String?) ?? '';
    final name = (data[FirestoreUserCoinFields.name] as String?) ?? '—';
    final rate =
        (data[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
        0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name • ${rate.toStringAsFixed(3)}/h',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: ownerId.isEmpty
                ? null
                : () async {
                    await CoinService.addCoinForUser(ownerId);
                  },
            icon: const Icon(Icons.add),
            tooltip: 'Add coin',
          ),
        ],
      ),
    );
  }

  Widget _minedCoinCard(Map<String, dynamic> data) {
    final ownerId =
        (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
    final name = (data[FirestoreUserCoinMiningFields.name] as String?) ?? '—';
    final rate =
        (data[FirestoreUserCoinMiningFields.hourlyRate] as num?)?.toDouble() ??
        0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$name • ${rate.toStringAsFixed(3)}/h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CoinMiningControls(coinOwnerId: ownerId),
        ],
      ),
    );
  }
}
