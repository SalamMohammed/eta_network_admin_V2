import 'package:flutter/material.dart';
import '../shared/theme/colors.dart';
import 'widgets/glowing_button.dart';
import 'widgets/progress_ring.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  bool miningActive = false;
  double progress = 0.4; // 40% of 24h
  double hourlyRate = 0.20;
  int streakDays = 6;

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
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 12456),
                    duration: const Duration(milliseconds: 800),
                    builder: (_, v, __) {
                      return Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
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
                  miningActive
                      ? const GlowingButton(label: 'Mining…', onPressed: null)
                      : GlowingButton(
                          label: 'START EARNING',
                          onPressed: () async {
                            await Future.delayed(
                              const Duration(milliseconds: 800),
                            );
                            setState(() {
                              miningActive = true;
                              progress = 0.01;
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
