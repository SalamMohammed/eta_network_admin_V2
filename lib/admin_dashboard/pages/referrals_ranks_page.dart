import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../widgets/chart_placeholder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/firestore_constants.dart';
import '../../services/rank_engine.dart';

class ReferralsRanksPage extends StatelessWidget {
  const ReferralsRanksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 16, runSpacing: 16, children: [
          _metric('Total referrals', '12,430'),
          _metric('Average referrals per active user', '1.8'),
          _metric('Builders', '2,340'),
          _metric('Guardians', '560'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryBackground, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Referrals'),
            const SizedBox(height: 8),
            Row(children: [
              ElevatedButton(
                onPressed: () async {
                  await _updateRanksBatch(limit: 50);
                },
                child: const Text('Update Ranks (50 users)'),
              ),
            ]),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(columns: const [
                DataColumn(label: Text('Inviter')),
                DataColumn(label: Text('Rank')),
                DataColumn(label: Text('Invited count')),
                DataColumn(label: Text('Active invited')),
                DataColumn(label: Text('Last referral date')),
              ], rows: List.generate(10, (i) {
                return const DataRow(cells: [
                  DataCell(Text('user_x')),
                  DataCell(Text('Builder')),
                  DataCell(Text('14')),
                  DataCell(Text('9')),
                  DataCell(Text('2025-11-23')),
                ]);
              })),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const ChartPlaceholder(title: 'Users per rank'),
      ]),
    );
  }

  Future<void> _updateRanksBatch({int limit = 50}) async {
    final qs = await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .orderBy(FirestoreUserFields.createdAt)
        .limit(limit)
        .get();
    for (final d in qs.docs) {
      await RankEngine.updateUserRank(d.id);
    }
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.primaryBackground, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
