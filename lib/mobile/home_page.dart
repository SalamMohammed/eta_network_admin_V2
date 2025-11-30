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
  String? _activeManagerId;
  List<String> _managedCoinSelections = const [];

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
    if (!mounted) return;
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
      _managedCoinSelections =
          ((d[FirestoreUserFields.managedCoinSelections] as List?)
              ?.cast<String>()) ??
          const [];
    });
    final activeId = (d[FirestoreUserFields.activeManagerId] as String?) ?? '';
    if (activeId.isNotEmpty) {
      final mgr = await FirebaseFirestore.instance
          .collection(FirestoreConstants.managers)
          .doc(activeId)
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
      _activeManagerId = activeId;
    } else {
      _managerGlobalEnabled = false;
      _managerEtaAuto = false;
      _managerUserCoinAuto = false;
      _managerMaxCommunity = 0;
      _activeManagerId = null;
    }
    if (_managerEnabled &&
        _managerGlobalEnabled &&
        _managerEtaAuto &&
        !miningActive) {
      final devId = _deviceId ?? await DeviceId.get();
      final res = await EarningsEngine.startMining(deviceId: devId);
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _displayTotal = totalPoints;
      });
      return;
    }
    _simBase = totalPoints;
    _simAnchor = DateTime.now();
    final end = lastEnd!.toDate();
    _simTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) {
        _simTimer?.cancel();
        return;
      }
      final anchor = _simAnchor!;
      final now = DateTime.now();
      if (!now.isBefore(end)) {
        _simTimer?.cancel();
        if (mounted) {
          setState(() {
            _displayTotal = _simBase;
            miningActive = false;
            progress = _computeProgress();
            _updateRemaining();
          });
        }
        EarningsEngine.syncEarnings().then((_) async {
          if (!mounted) return;
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
      if (!mounted) return;
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
    if (!_managerEnabled) return;

    // Ensure own coin is mining when enabled
    if (_managerUserCoinAuto) {
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
        await CoinService.startCoinMining(uid);
      }
    }

    // Manage community coins when enabled and allowed
    if (!(_managerUserCoinAuto &&
        _managerGlobalEnabled &&
        _managerMaxCommunity > 0))
      return;
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
      if (ownerId == uid) continue;
      if (_managedCoinSelections.isNotEmpty &&
          !_managedCoinSelections.contains(ownerId))
        continue;
      final end =
          data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
      final isActive = end != null && now.isBefore(end.toDate());
      if (isActive) activeManaged++;
    }
    for (final d in q.docs) {
      final data = d.data();
      final ownerId =
          (data[FirestoreUserCoinMiningFields.ownerId] as String?) ?? '';
      if (ownerId == uid) continue;
      if (_managedCoinSelections.isNotEmpty &&
          !_managedCoinSelections.contains(ownerId))
        continue;
      final end =
          data[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
      final isActive = end != null && now.isBefore(end.toDate());
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
        actions: [
          TextButton(onPressed: _openManagerSelector, child: const Text('VIP')),
          TextButton(onPressed: _openCoinSelector, child: const Text('Coins')),
        ],
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
                                          (res[FirestoreUserFields.hourlyRate]
                                                  as num?)
                                              ?.toDouble() ??
                                          hourlyRate;
                                      lastStart =
                                          res[FirestoreUserFields
                                                  .lastMiningStart]
                                              as Timestamp?;
                                      lastEnd =
                                          res[FirestoreUserFields.lastMiningEnd]
                                              as Timestamp?;
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

  Future<void> _openManagerSelector() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return _ManagerSelectDialog(
          currentId: _activeManagerId,
          onSelected: (id) async {
            await FirebaseFirestore.instance
                .collection(FirestoreConstants.users)
                .doc(uid)
                .set({
                  FirestoreUserFields.activeManagerId: id,
                  FirestoreUserFields.managerEnabled: (id != null),
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
          current: _managedCoinSelections,
          maxCount: _managerMaxCommunity,
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
  String? selectedId;

  @override
  void initState() {
    super.initState();
    selectedId = widget.currentId;
    _load();
  }

  Future<void> _load() async {
    final qs = await FirebaseFirestore.instance
        .collection(FirestoreConstants.managers)
        .where(FirestoreManagerFields.isActive, isEqualTo: true)
        .get();
    managers = qs.docs;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Manager',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (managers.isEmpty) const Text('No managers available'),
            for (final doc in managers)
              ListTile(
                leading: CircleAvatar(
                  child: const Icon(Icons.auto_mode_rounded),
                  backgroundImage:
                      (doc.data()[FirestoreManagerFields.thumbnailUrl]
                                  as String?)
                              ?.isNotEmpty ==
                          true
                      ? NetworkImage(
                          doc.data()[FirestoreManagerFields.thumbnailUrl]
                              as String,
                        )
                      : null,
                ),
                title: Text(
                  (doc.data()[FirestoreManagerFields.name] as String?) ?? '—',
                ),
                trailing: Radio<String>(
                  value: doc.id,
                  groupValue: selectedId,
                  onChanged: (v) => setState(() => selectedId = v),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await widget.onSelected(selectedId);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await widget.onSelected(null);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('None'),
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
                        if (!selectedIds.contains(ownerId))
                          selectedIds.add(ownerId);
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
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await widget.onSelected(const []);
                    if (mounted) Navigator.pop(context);
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
