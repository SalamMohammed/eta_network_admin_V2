import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = const [
      {'q': 'What are ETA points?', 'a': 'ETA points are loyalty points earned via daily mining activities.'},
      {'q': 'Is this crypto?', 'a': 'No. These are loyalty points, not a cryptocurrency yet.'},
      {'q': 'How mining works?', 'a': 'Tap to start a session and earn automatically at your hourly rate.'},
      {'q': 'How referrals work?', 'a': 'Share your code to invite friends and earn referral bonuses.'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final it = items[i];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: AppColors.primaryBackground, borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(title: Text(it['q']!), children: [Padding(padding: const EdgeInsets.all(12), child: Text(it['a']!))]),
          );
        },
      ),
    );
  }
}
