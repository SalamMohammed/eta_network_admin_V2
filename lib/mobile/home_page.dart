import 'package:flutter/material.dart';
import 'dart:async';
import '../shared/theme/colors.dart';
import 'widgets/glowing_button.dart';
import 'widgets/progress_ring.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/earnings_engine.dart';
import '../shared/firestore_constants.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
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

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
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
    });
    _updateRemaining();
    _startSimulationIfNeeded();
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
        EarningsEngine.syncEarnings().then((_) => _refresh());
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('ETA Network'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
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
                    height: 220,
                    child: ProgressRing(
                      progress: progress,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${hourlyRate.toStringAsFixed(2)} ETA/hr'),
                          const SizedBox(height: 6),
                          Text(miningActive ? 'Mining Active' : 'Inactive'),
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
                            final res = await EarningsEngine.startMining();
                            setState(() {
                              hourlyRate =
                                  (res['hourlyRate'] as num?)?.toDouble() ??
                                  hourlyRate;
                              lastStart = res['lastMiningStart'] as Timestamp?;
                              lastEnd = res['lastMiningEnd'] as Timestamp?;
                              miningActive =
                                  lastEnd != null &&
                                  DateTime.now().isBefore(lastEnd!.toDate());
                              progress = _computeProgress();
                              _displayTotal = totalPoints;
                            });
                            _startSimulationIfNeeded();
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
          ],
        ),
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
}
