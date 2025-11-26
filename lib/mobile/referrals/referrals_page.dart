import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class ReferralsPage extends StatelessWidget {
  const ReferralsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final code = 'X7P9HQ';
    final users = List.generate(
      12,
      (i) => {
        'username': 'user_$i',
        'status': i % 2 == 0 ? 'Active' : 'Not Started',
        'joined': '2025-11-2${i % 10}',
      },
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Referrals'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Grow Your Team. Earn More.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Share Link'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Copy Code'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _metric('Total Invited', '24')),
                const SizedBox(width: 8),
                Expanded(child: _metric('Active Invited', '12')),
                const SizedBox(width: 8),
                Expanded(child: _metric('Team Power', '820')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (final u in users)
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.secondaryAccent,
                      ),
                      title: Text(u['username'] as String),
                      subtitle: Text(u['joined'] as String),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (u['status'] == 'Active')
                              ? AppColors.primaryAccent
                              : AppColors.vipAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          u['status'] as String,
                          style: const TextStyle(color: AppColors.deepLayer),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('How It Works'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Invite friends to grow your team. Each active invite boosts your rank and earning potential.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
