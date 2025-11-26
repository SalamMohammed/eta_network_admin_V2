import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_placeholder.dart';
import '../widgets/data_table_card.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              StatCard(
                title: 'Total Users',
                value: '12,480',
                icon: Icons.people_alt_rounded,
                accent: AppColors.secondaryAccent,
              ),
              StatCard(
                title: 'Daily Active Miners',
                value: '3,210',
                icon: Icons.bolt_rounded,
                accent: AppColors.primaryAccent,
              ),
              StatCard(
                title: 'Total ETA Points Minted',
                value: '24,560,000',
                icon: Icons.token_rounded,
                accent: AppColors.vipAccent,
              ),
              StatCard(
                title: 'Points Minted in Last 24h',
                value: '152,400',
                icon: Icons.speed_rounded,
                accent: AppColors.secondaryAccent,
              ),
              StatCard(
                title: 'Ad Impressions Today',
                value: '98,234',
                icon: Icons.ads_click_rounded,
                accent: AppColors.primaryAccent,
              ),
              StatCard(
                title: 'Estimated Ad Revenue Today',
                value: '\$1,240',
                icon: Icons.attach_money_rounded,
                accent: AppColors.vipAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(
                child: ChartPlaceholder(
                  title: 'Daily Active Users (last 30 days)',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ChartPlaceholder(
                  title: 'Total Points Earned per Day (last 30 days)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const ChartPlaceholder(title: 'User Distribution by Rank'),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: DataTableCard(
                  title: 'Latest 10 Users',
                  columns: [
                    'Username',
                    'Total Points',
                    'Hourly Rate',
                    'Rank',
                    'Created',
                  ],
                  rows: [
                    ['alex', '120,340', '0.20', 'Explorer', '2025-11-21'],
                    ['mara', '98,020', '0.22', 'Builder', '2025-11-22'],
                    ['joel', '45,110', '0.18', 'Guardian', '2025-11-23'],
                    ['nina', '12,340', '0.15', 'Explorer', '2025-11-23'],
                    ['ryan', '9,210', '0.16', 'Explorer', '2025-11-24'],
                    ['leah', '8,050', '0.18', 'Builder', '2025-11-24'],
                    ['sam', '7,600', '0.20', 'Explorer', '2025-11-24'],
                    ['dina', '6,430', '0.19', 'Builder', '2025-11-24'],
                    ['amir', '6,000', '0.21', 'Guardian', '2025-11-24'],
                    ['tiko', '5,200', '0.20', 'Explorer', '2025-11-24'],
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DataTableCard(
                  title: 'Latest 10 Point Logs',
                  columns: ['Username', 'Type', 'Amount', 'Timestamp'],
                  rows: [
                    ['alex', 'tap', '+10', '10:20'],
                    ['mara', 'referral', '+100', '09:10'],
                    ['joel', 'bonus', '+20', '08:00'],
                    ['nina', 'streak', '+5', '07:45'],
                    ['ryan', 'correction', '-2', '07:30'],
                    ['leah', 'tap', '+10', '06:50'],
                    ['sam', 'tap', '+10', '06:30'],
                    ['dina', 'streak', '+5', '06:15'],
                    ['amir', 'bonus', '+30', '06:10'],
                    ['tiko', 'tap', '+10', '06:00'],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
