import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Your ETA Balance'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: const [
                Text('12,456'),
                SizedBox(height: 4),
                Text('Lifetime points'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'History'),
              Tab(text: 'Daily Summary'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_history(), _summary()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _history() {
    final items = List.generate(20, (i) {
      final type = ['streak', 'referral', 'mining', 'correction'][i % 4];
      final amount = i.isEven ? '+${(i + 1) * 1.2}' : '-${(i + 1) * 0.5}';
      return {
        'type': type,
        'title': 'Mining Session $amount ETA',
        'time': '2025-11-25 10:${i.toString().padLeft(2, '0')}',
        'amount': amount,
      };
    });
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Filter'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: filter,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'streak', child: Text('Streak')),
                  DropdownMenuItem(value: 'referral', child: Text('Referral')),
                  DropdownMenuItem(value: 'mining', child: Text('Mining')),
                  DropdownMenuItem(
                    value: 'correction',
                    child: Text('Correction'),
                  ),
                ],
                onChanged: (v) => setState(() => filter = v ?? 'All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final it = items[i];
                final positive = (it['amount'] as String).startsWith('+');
                return ListTile(
                  leading: Icon(
                    it['type'] == 'streak'
                        ? Icons.local_fire_department_rounded
                        : it['type'] == 'referral'
                        ? Icons.group_add_rounded
                        : it['type'] == 'mining'
                        ? Icons.bolt_rounded
                        : Icons.remove_circle_outline,
                    color: AppColors.secondaryAccent,
                  ),
                  title: Text(it['title'] as String),
                  subtitle: Text(it['time'] as String),
                  trailing: Text(
                    it['amount'] as String,
                    style: TextStyle(
                      color: positive
                          ? AppColors.primaryAccent
                          : AppColors.vipAccent,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _card('Earned Today', '+240')),
              const SizedBox(width: 8),
              Expanded(child: _card('Last 7 Days', '+1,820')),
              const SizedBox(width: 8),
              Expanded(child: _card('From Referrals', '+420')),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('Bar chart (7 days)')),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, String value) {
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
