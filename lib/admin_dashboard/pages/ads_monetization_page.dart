import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class AdsMonetizationPage extends StatelessWidget {
  const AdsMonetizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardBonusCtrl = TextEditingController(text: '2');
    final maxRewardsCtrl = TextEditingController(text: '5');
    bool showBannerHistory = true;
    bool showBannerReferral = true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _metric('Impressions Today', '98,234'),
              _metric('Impressions Yesterday', '105,420'),
              _metric('Earnings Today', '\$1,240'),
              _metric('Earnings This Month', '\$24,820'),
              _metric('Rewarded Ads Watched Today', '860'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('Ad performance chart')),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuration'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(value: showBannerHistory, onChanged: (_) {}),
                    const Text('Show banner ads on History screen'),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(value: showBannerReferral, onChanged: (_) {}),
                    const Text('Show banner ads on Referral screen'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rewardBonusCtrl,
                        decoration: const InputDecoration(
                          labelText:
                              'Reward bonus for watching ad (% of hourlyRate)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxRewardsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Max rewarded bonuses per day per user',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ads config saved')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top rewarded ad users'),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Username')),
                      DataColumn(label: Text('Times watched (7 days)')),
                    ],
                    rows: List.generate(10, (i) {
                      return DataRow(
                        cells: [
                          DataCell(Text('user_$i')),
                          DataCell(Text('${i * 3 + 1}')),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
