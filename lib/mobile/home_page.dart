import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await EarningsEngine.syncEarnings();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
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
    });
  }

  double _computeProgress() {
    if (lastStart == null || lastEnd == null) return 0.0;
    final start = lastStart!.toDate();
    final end = lastEnd!.toDate();
    final now = DateTime.now();
    if (!now.isAfter(start)) return 0.0;
    final total = end.difference(start).inSeconds;
    final done = now.isBefore(end) ? now.difference(start).inSeconds : total;
    if (total <= 0) return 0.0;
    final p = done / total;
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
                    totalPoints.toStringAsFixed(0),
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
                            miningActive ? '12h 12m remaining' : 'Tap to start',
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
                            });
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _smallCard('Today\'s Earnings', '+240'),
                const SizedBox(width: 12),
                _smallCard('Your Rank', 'Explorer'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _smallCard('Streak Days', '$streakDays'),
                const SizedBox(width: 12),
                _smallCard('Session', '08:00 → 12:00'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
